from __future__ import annotations

import os
import random
from typing import List, Optional, Tuple

import numpy as np
import pandas as pd
import tensorflow as tf
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

from training_data import X

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FOOD_XLSX = os.path.join(BASE_DIR, "food_final.xlsx")

DEFAULT_IMAGE = "assets/images/Chicken_breast.png"
IMAGE_RULES = [
    ("닭", "assets/images/Chicken_breast.png"), ("치킨", "assets/images/Chicken_breast.png"),
    ("연어", "assets/images/Grilled_salmon.png"), ("고등어", "assets/images/Mackerel.png"),
    ("두부", "assets/images/Tofu.png"), ("계란", "assets/images/boiled_egg.png"), ("달걀", "assets/images/boiled_egg.png"),
    ("요거트", "assets/images/Greek_yogurt.png"), ("샐러드", "assets/images/Chicken_breast_salad.png"),
    ("바나나", "assets/images/banana.png"), ("사과", "assets/images/apple.png"), ("아보카도", "assets/images/avocado.png"),
    ("호두", "assets/images/roasted_walnuts.png"), ("아몬드", "assets/images/fried_almonds.png"),
    ("브로콜리", "assets/images/Broccoli.png"), ("오징어", "assets/images/Squid.png"), ("문어", "assets/images/Octopus.png"),
    ("새우", "assets/images/Grilled_shrimp.png"), ("쌀밥", "assets/images/white_rice.png"), ("현미", "assets/images/multigrain_rice.png"),
    ("감자", "assets/images/Steamed_potatoes.png"), ("고구마", "assets/images/Steamed_sweet_potatoes.png"),
]

WORKOUT_OPTIONS = {
    "무산소": {
        "가슴": ["벤치 프레스", "인클라인 덤벨 프레스", "케이블 크로스오버", "푸쉬업", "딥스", "팩덱 플라이"],
        "등": ["랫풀다운", "바벨 로우", "암풀다운", "풀업", "시티드 로우", "원암 덤벨 로우"],
        "하체": ["스쿼트", "레그 익스텐션", "레그 프레스", "레그 컬", "불가리안 스플릿 스쿼트", "데드리프트"],
        "어깨": ["밀리터리 프레스", "숄더 프레스", "사이드 레터럴 레이즈", "업라이트 로우", "페이스 풀", "벤트 오버 레이즈"],
        "팔": ["바벨 컬", "덤벨 컬", "해머 컬", "케이블 푸쉬다운", "트라이셉스 익스텐션", "클로즈 그립 벤치프레스"],
    },
    "유산소": ["러닝 30분", "사이클링 40분", "스텝밀 25분", "버피 5세트", "점핑잭 10분", "러닝 20분 + 사이클 20분"],
    "혼합": ["전신 서킷 30분", "근력 40분 + 유산소 20분", "하체 근력 + 사이클", "상체 근력 + 러닝", "인터벌 트레이닝"],
}

WORKOUT_LABELS = ["유산소", "무산소", "혼합"]
DIET_LABELS = ["감량식", "벌크업식", "고단백식", "균형식"]
INTENSITY_LABELS = ["낮음", "보통", "높음"]
FREQUENCY_LABELS = ["주 3회", "주 4회", "주 5회"]
CHAT_INTENT_LABELS = ["음식 변경", "운동 추가", "식단 유형 변경", "운동 강도 변경", "영양소 조건", "일반 질문"]


class PlanRequest(BaseModel):
    height: float = Field(..., gt=0)
    weight: float = Field(..., gt=0)
    goal: float


class ModifyRequest(BaseModel):
    currentMeals: List[str] = []
    request: str = ""
    height: Optional[float] = None
    weight: Optional[float] = None
    goal: Optional[float] = None


class AIServer:
    """
    AI 활용 확장 버전.

    1) TensorFlow 신체 분석 모델
       - 입력: 키, 몸무게, 목표 증감량, BMI, 목표 방향
       - 출력: 운동 유형, 식단 유형, 운동 강도, 운동 빈도

    2) TensorFlow 채팅 의도 분류 모델
       - 입력: 사용자의 자연어 문장
       - 출력: 음식 변경/운동 추가/식단 유형 변경/운동 강도 변경/영양 조건/일반 질문

    3) TensorFlow 음식 추천 점수 모델
       - 입력: 음식 영양성분 + 사용자 BMI/목표/식단 유형
       - 출력: AI 추천 점수

    4) 칼로리/탄단지는 안전한 공식으로 계산
       - 숫자 폭주를 막기 위해 영양 목표 자체는 공식 기반으로 계산합니다.
       - AI는 어떤 유형과 어떤 음식이 더 적합한지 판단하는 쪽에 사용합니다.
    """

    def __init__(self) -> None:
        np.random.seed(42)
        tf.random.set_seed(42)
        random.seed(42)

        self.food_data = self._load_food_data()
        self.scaler = StandardScaler()
        self.fitness_model = None
        self.food_scaler = StandardScaler()
        self.food_score_model = None
        self.chat_model = None
        self.chat_vectorizer = None
        self.evaluation = {}

        self._train_fitness_model()
        self._train_chat_intent_model()
        self._train_food_score_model()

    @staticmethod
    def _bmi(height: float, weight: float) -> float:
        h_m = height / 100.0
        return weight / (h_m * h_m) if h_m > 0 else 0.0

    @staticmethod
    def _goal_dir(goal: float) -> float:
        if goal > 1:
            return 1.0
        if goal < -1:
            return -1.0
        return 0.0

    def _make_features(self, rows: np.ndarray) -> np.ndarray:
        features = []
        for height, weight, goal in rows:
            bmi = self._bmi(float(height), float(weight))
            features.append([height, weight, goal, bmi, self._goal_dir(float(goal))])
        return np.array(features, dtype=float)

    def _rule_labels(self, row: np.ndarray) -> Tuple[int, int, int, int]:
        height, weight, goal = [float(v) for v in row]
        bmi = self._bmi(height, weight)

        # 운동 유형: 0 유산소, 1 무산소, 2 혼합
        if goal <= -4 or bmi >= 27:
            workout = 0
        elif goal >= 4 or bmi < 20:
            workout = 1
        else:
            workout = 2

        # 식단 유형: 0 감량식, 1 벌크업식, 2 고단백식, 3 균형식
        if goal <= -3 or bmi >= 26:
            diet = 0
        elif goal >= 4 or bmi < 20:
            diet = 1
        elif abs(goal) >= 2:
            diet = 2
        else:
            diet = 3

        # 운동 강도: 0 낮음, 1 보통, 2 높음
        if bmi >= 30 or weight < 45 or abs(goal) >= 13:
            intensity = 0
        elif (goal >= 6 and bmi < 25) or (goal <= -6 and bmi < 28):
            intensity = 2
        else:
            intensity = 1

        # 운동 빈도: 0 주 3회, 1 주 4회, 2 주 5회
        frequency = 0 if intensity == 0 else (2 if intensity == 2 else 1)
        return workout, diet, intensity, frequency

    def _train_fitness_model(self) -> None:
        x_features = self._make_features(X)
        labels = np.array([self._rule_labels(row) for row in X], dtype=int)
        y_workout = tf.keras.utils.to_categorical(labels[:, 0], num_classes=3)
        y_diet = tf.keras.utils.to_categorical(labels[:, 1], num_classes=4)
        y_intensity = tf.keras.utils.to_categorical(labels[:, 2], num_classes=3)
        y_frequency = tf.keras.utils.to_categorical(labels[:, 3], num_classes=3)

        x_scaled = self.scaler.fit_transform(x_features)
        split = train_test_split(
            x_scaled, y_workout, y_diet, y_intensity, y_frequency,
            test_size=0.2, random_state=42,
        )
        x_train, x_test = split[0], split[1]
        yw_train, yw_test = split[2], split[3]
        yd_train, yd_test = split[4], split[5]
        yi_train, yi_test = split[6], split[7]
        yf_train, yf_test = split[8], split[9]

        inp = tf.keras.layers.Input(shape=(5,), name="body_input")
        x = tf.keras.layers.Dense(96, activation="relu")(inp)
        x = tf.keras.layers.Dropout(0.10)(x)
        x = tf.keras.layers.Dense(64, activation="relu")(x)
        x = tf.keras.layers.Dense(32, activation="relu")(x)
        workout_out = tf.keras.layers.Dense(3, activation="softmax", name="workout_type")(x)
        diet_out = tf.keras.layers.Dense(4, activation="softmax", name="diet_type")(x)
        intensity_out = tf.keras.layers.Dense(3, activation="softmax", name="intensity")(x)
        frequency_out = tf.keras.layers.Dense(3, activation="softmax", name="frequency")(x)
        model = tf.keras.Model(inp, [workout_out, diet_out, intensity_out, frequency_out])
        model.compile(
            optimizer="adam",
            loss={
                "workout_type": "categorical_crossentropy",
                "diet_type": "categorical_crossentropy",
                "intensity": "categorical_crossentropy",
                "frequency": "categorical_crossentropy",
            },
            metrics={
                "workout_type": ["accuracy"],
                "diet_type": ["accuracy"],
                "intensity": ["accuracy"],
                "frequency": ["accuracy"],
            },
        )
        epochs = int(os.environ.get("EPOCHS", "90"))
        model.fit(
            x_train,
            {"workout_type": yw_train, "diet_type": yd_train, "intensity": yi_train, "frequency": yf_train},
            epochs=epochs,
            batch_size=8,
            validation_split=0.2,
            verbose=1,
        )
        results = model.evaluate(
            x_test,
            {"workout_type": yw_test, "diet_type": yd_test, "intensity": yi_test, "frequency": yf_test},
            verbose=0,
        )
        self.fitness_model = model
        self.evaluation["fitnessModel"] = {name: float(value) for name, value in zip(model.metrics_names, results)}

    def _train_chat_intent_model(self) -> None:
        samples = [
            ("다른 음식 추천해줘", 0), ("닭가슴살 말고 다른 거", 0), ("식단 바꿔줘", 0), ("음식 교체", 0),
            ("운동 더 추천해줘", 1), ("운동 추가해줘", 1), ("하체 운동 알려줘", 1), ("운동 뭐 하지", 1),
            ("저탄수 식단으로 바꿔줘", 2), ("고단백 식단 추천", 2), ("벌크업 식단", 2), ("감량식으로", 2),
            ("운동 강도 낮춰줘", 3), ("강도를 올려줘", 3), ("너무 힘들어", 3), ("더 빡세게", 3),
            ("단백질 많은 음식", 4), ("탄수화물 적은 음식", 4), ("지방 낮은 식단", 4), ("칼로리 낮게", 4),
            ("안녕", 5), ("고마워", 5), ("설명해줘", 5), ("왜 이렇게 추천했어", 5),
        ]
        # 작은 데이터라서 문장을 몇 번 반복해 안정화합니다.
        texts = [s[0] for s in samples] * 5
        labels = np.array([s[1] for s in samples] * 5, dtype=int)
        y = tf.keras.utils.to_categorical(labels, num_classes=len(CHAT_INTENT_LABELS))

        vectorizer = tf.keras.layers.TextVectorization(max_tokens=800, output_sequence_length=16)
        vectorizer.adapt(tf.constant(texts, dtype=tf.string))
        model = tf.keras.Sequential([
            tf.keras.Input(shape=(1,), dtype=tf.string),
            vectorizer,
            tf.keras.layers.Embedding(800, 16),
            tf.keras.layers.GlobalAveragePooling1D(),
            tf.keras.layers.Dense(24, activation="relu"),
            tf.keras.layers.Dense(len(CHAT_INTENT_LABELS), activation="softmax"),
        ])
        model.compile(optimizer="adam", loss="categorical_crossentropy", metrics=["accuracy"])
        model.fit(tf.constant(texts, dtype=tf.string), y, epochs=55, batch_size=8, verbose=0)
        self.chat_model = model
        self.chat_vectorizer = vectorizer

    @staticmethod
    def _load_food_data() -> pd.DataFrame:
        df = pd.read_excel(FOOD_XLSX)
        need = ["식품명", "에너지(kcal)", "탄수화물(g)", "단백질(g)", "지방(g)"]
        df = df[need].dropna().copy()
        for col in need[1:]:
            df[col] = pd.to_numeric(df[col], errors="coerce")
        return df.dropna().reset_index(drop=True)

    @staticmethod
    def _clamp(value: float, low: float, high: float) -> float:
        return max(low, min(high, value))

    def calculate_diet_targets(self, height: float, weight: float, goal: float, diet_type: str) -> dict:
        h_m = height / 100.0
        bmi = weight / (h_m * h_m) if h_m > 0 else 0.0
        maintenance_kcal = weight * 33.0

        if diet_type == "벌크업식":
            target_kcal = maintenance_kcal + 350.0
            protein_per_kg = 1.8
            fat_ratio = 0.25
        elif diet_type == "감량식":
            target_kcal = maintenance_kcal - 450.0
            protein_per_kg = 2.0
            fat_ratio = 0.24
        elif diet_type == "고단백식":
            target_kcal = maintenance_kcal + (150.0 if goal > 0 else -250.0 if goal < 0 else 0.0)
            protein_per_kg = 2.1
            fat_ratio = 0.23
        else:
            target_kcal = maintenance_kcal + (250.0 if goal > 1 else -300.0 if goal < -1 else 0.0)
            protein_per_kg = 1.7
            fat_ratio = 0.25

        min_kcal = max(1200.0, weight * 22.0)
        max_kcal = min(4200.0, weight * 45.0)
        target_kcal = self._clamp(target_kcal, min_kcal, max_kcal)
        protein_g = self._clamp(weight * protein_per_kg, 50.0, 230.0)
        fat_g = self._clamp((target_kcal * fat_ratio) / 9.0, 35.0, 120.0)
        carb_g = (target_kcal - protein_g * 4.0 - fat_g * 9.0) / 4.0
        carb_g = self._clamp(carb_g, 80.0, 650.0)
        calculated_kcal = carb_g * 4.0 + protein_g * 4.0 + fat_g * 9.0

        goal_type = "벌크업/증량" if goal > 1 else "다이어트/감량" if goal < -1 else "유지"
        return {
            "calories": int(round(calculated_kcal)),
            "carbs": int(round(carb_g)),
            "protein": int(round(protein_g)),
            "fat": int(round(fat_g)),
            "bmi": round(float(bmi), 1),
            "goalType": goal_type,
            "dietType": diet_type,
            "method": "AI 식단 유형 + 공식 영양 계산",
        }

    def predict_ai_profile(self, height: float, weight: float, goal: float) -> dict:
        bmi = self._bmi(height, weight)
        features = np.array([[height, weight, goal, bmi, self._goal_dir(goal)]], dtype=float)
        x_scaled = self.scaler.transform(features)
        workout_p, diet_p, intensity_p, frequency_p = self.fitness_model.predict(x_scaled, verbose=0)
        wi, di, ii, fi = int(np.argmax(workout_p[0])), int(np.argmax(diet_p[0])), int(np.argmax(intensity_p[0])), int(np.argmax(frequency_p[0]))
        return {
            "workoutType": WORKOUT_LABELS[wi],
            "workoutConfidence": round(float(workout_p[0][wi]), 3),
            "dietType": DIET_LABELS[di],
            "dietConfidence": round(float(diet_p[0][di]), 3),
            "intensity": INTENSITY_LABELS[ii],
            "intensityConfidence": round(float(intensity_p[0][ii]), 3),
            "frequency": FREQUENCY_LABELS[fi],
            "frequencyConfidence": round(float(frequency_p[0][fi]), 3),
            "bmi": round(float(bmi), 1),
            "modelInputs": ["height", "weight", "goal", "bmi", "goalDirection"],
        }

    def _train_food_score_model(self) -> None:
        rows = []
        targets = []
        if self.food_data.empty:
            return
        sample_users = [
            (170, 80, -6, "감량식"), (175, 72, 0, "균형식"), (180, 62, 8, "벌크업식"),
            (168, 68, -3, "고단백식"), (185, 85, 5, "벌크업식"), (160, 58, -5, "감량식"),
        ]
        diet_index = {v: i for i, v in enumerate(DIET_LABELS)}
        for h, w, g, diet_type in sample_users:
            diet = self.calculate_diet_targets(h, w, g, diet_type)
            bmi = diet["bmi"]
            meal_carb = diet["carbs"] / 3.0
            meal_protein = diet["protein"] / 3.0
            meal_fat = diet["fat"] / 3.0
            meal_kcal = diet["calories"] / 3.0
            for _, r in self.food_data.iterrows():
                kcal = float(r["에너지(kcal)"])
                carb = float(r["탄수화물(g)"])
                protein = float(r["단백질(g)"])
                fat = float(r["지방(g)"])
                diff = abs(kcal - meal_kcal) / 8.0 + abs(carb - meal_carb) + abs(protein - meal_protein) * 1.2 + abs(fat - meal_fat) * 1.1
                score = 100.0 - diff
                if diet_type in ["감량식", "고단백식"]:
                    score += protein * 0.4 - fat * 0.2
                if diet_type == "벌크업식":
                    score += kcal * 0.03 + protein * 0.25
                if diet_type == "균형식":
                    score -= abs((carb + protein + fat) - (meal_carb + meal_protein + meal_fat)) * 0.2
                score = self._clamp(score, 0.0, 100.0)
                rows.append([kcal, carb, protein, fat, bmi, g, diet_index[diet_type]])
                targets.append(score / 100.0)
        x = np.array(rows, dtype=float)
        y = np.array(targets, dtype=float)
        self.food_scaler.fit(x)
        xs = self.food_scaler.transform(x)
        model = tf.keras.Sequential([
            tf.keras.Input(shape=(7,)),
            tf.keras.layers.Dense(48, activation="relu"),
            tf.keras.layers.Dense(24, activation="relu"),
            tf.keras.layers.Dense(1, activation="sigmoid"),
        ])
        model.compile(optimizer="adam", loss="mse", metrics=["mae"])
        model.fit(xs, y, epochs=30, batch_size=32, verbose=0)
        self.food_score_model = model

    def _rule_chat_intent(self, text: str) -> Optional[dict]:
        """
        짧은 한국어 입력은 학습 데이터가 적은 딥러닝 모델만 쓰면 오분류가 잦습니다.
        그래서 실제 앱에서는 키워드 기반 안전장치를 먼저 적용하고,
        애매한 문장만 TensorFlow 채팅 의도 모델로 보냅니다.
        """
        t = text.strip().lower().replace(" ", "")
        if not t:
            return {"label": "일반 질문", "confidence": 1.0, "method": "rule"}

        general_words = ["안녕", "고마워", "감사", "뭐야", "설명", "왜", "이유", "도움", "사용법", "추천이유"]
        if any(w in t for w in general_words):
            return {"label": "일반 질문", "confidence": 0.98, "method": "rule"}

        intensity_down = ["강도낮", "낮춰", "줄여", "쉬운", "쉬게", "힘들", "무리", "가볍"]
        intensity_up = ["강도올", "올려", "높여", "빡세", "빡센", "강하게", "힘들게"]
        if any(w in t for w in intensity_down + intensity_up):
            return {"label": "운동 강도 변경", "confidence": 0.96, "method": "rule"}

        diet_words = ["저탄", "고단백", "벌크", "증량식", "감량식", "다이어트식", "균형식", "식단유형", "식단타입"]
        if any(w in t for w in diet_words):
            return {"label": "식단 유형 변경", "confidence": 0.95, "method": "rule"}

        nutrient_words = ["단백질많", "단백질높", "탄수화물적", "탄수적", "지방낮", "저지방", "칼로리낮", "저칼로리", "영양"]
        if any(w in t for w in nutrient_words):
            return {"label": "영양소 조건", "confidence": 0.94, "method": "rule"}

        workout_words = ["운동", "유산소", "무산소", "근력", "헬스", "하체", "가슴", "등", "어깨", "팔", "러닝", "스쿼트"]
        if any(w in t for w in workout_words):
            return {"label": "운동 추가", "confidence": 0.93, "method": "rule"}

        food_change_words = ["다른음식", "다른거", "다른것", "말고", "빼줘", "제외", "교체", "바꿔", "음식변경", "식단바꿔", "추천음식"]
        food_words = ["음식", "식단", "메뉴", "밥", "닭", "고기", "두부", "연어", "샐러드"]
        if any(w in t for w in food_change_words) or ("추천" in t and any(w in t for w in food_words)):
            return {"label": "음식 변경", "confidence": 0.93, "method": "rule"}

        return None

    def predict_chat_intent(self, text: str) -> dict:
        rule = self._rule_chat_intent(text)
        if rule is not None:
            return rule
        if not text.strip():
            return {"label": "일반 질문", "confidence": 1.0, "method": "rule"}
        probs = self.chat_model.predict(tf.constant([text], dtype=tf.string), verbose=0)[0]
        idx = int(np.argmax(probs))
        confidence = float(probs[idx])
        # 신뢰도가 낮으면 추천을 함부로 바꾸지 않고 일반 질문으로 처리합니다.
        if confidence < 0.62:
            return {"label": "일반 질문", "confidence": round(confidence, 3), "method": "model-low-confidence"}
        return {"label": CHAT_INTENT_LABELS[idx], "confidence": round(confidence, 3), "method": "model"}

    @staticmethod
    def _coach_response(intent_label: str, ai_profile: dict, diet_result: dict) -> str:
        if intent_label == "음식 변경":
            return "요청을 반영해서 현재 식단과 겹치지 않는 다른 추천 음식으로 다시 골랐습니다."
        if intent_label == "영양소 조건":
            return "영양소 조건을 반영해 단백질·탄수화물·지방 목표에 더 맞는 음식 위주로 다시 추천했습니다."
        if intent_label == "식단 유형 변경":
            return f"식단 유형을 {ai_profile.get('dietType', '균형식')} 기준으로 조정했습니다."
        if intent_label == "운동 강도 변경":
            return f"운동 강도를 {ai_profile.get('intensity', '보통')}으로 조정하고 빈도는 {ai_profile.get('frequency', '주 4회')}로 맞췄습니다."
        if intent_label == "운동 추가":
            return f"{ai_profile.get('workoutType', '혼합')} 중심으로 운동 추천을 다시 구성했습니다."
        return (
            f"현재 입력값 기준 BMI는 {diet_result.get('bmi')}이고, "
            f"AI는 {ai_profile.get('dietType', '균형식')}과 {ai_profile.get('workoutType', '혼합')} 운동을 추천했습니다. "
            "음식을 바꾸려면 '다른 음식 추천', 운동을 바꾸려면 '운동 추가', 강도를 바꾸려면 '강도 낮춰줘'처럼 입력하세요."
        )

    def predict(self, height: float, weight: float, goal: float) -> dict:
        ai_profile = self.predict_ai_profile(height, weight, goal)
        diet_result = self.calculate_diet_targets(height, weight, goal, ai_profile["dietType"])
        foods = self.recommend_foods(diet_result, exclude=[], ai_profile=ai_profile)
        return {
            "workoutType": ai_profile["workoutType"],
            "diet": diet_result,
            "meals": foods,
            "workouts": self.recommend_workouts(ai_profile),
            "aiAnalysis": ai_profile,
            "modelEvaluation": self.evaluation,
        }

    def recommend_foods(self, diet_result: dict, exclude: List[str], ai_profile: Optional[dict] = None, offset: int = 0, count: int = 3) -> List[dict]:
        df = self.food_data.copy()
        if exclude:
            df = df[~df["식품명"].isin(exclude)].copy()
        if df.empty:
            return []
        diet_index = {v: i for i, v in enumerate(DIET_LABELS)}
        diet_type = diet_result.get("dietType", "균형식")
        goal_value = 1.0 if diet_result.get("goalType") == "벌크업/증량" else -1.0 if diet_result.get("goalType") == "다이어트/감량" else 0.0
        bmi = float(diet_result.get("bmi", 22.0))
        x = np.column_stack([
            df["에너지(kcal)"].astype(float).to_numpy(),
            df["탄수화물(g)"].astype(float).to_numpy(),
            df["단백질(g)"].astype(float).to_numpy(),
            df["지방(g)"].astype(float).to_numpy(),
            np.full(len(df), bmi),
            np.full(len(df), goal_value),
            np.full(len(df), diet_index.get(diet_type, 3)),
        ])
        ai_scores = self.food_score_model.predict(self.food_scaler.transform(x), verbose=0).reshape(-1) * 100.0

        # 안전장치: AI 점수만 쓰면 영양 목표에서 멀어질 수 있으므로 탄단지 차이도 함께 반영합니다.
        carb_target = diet_result["carbs"] / 3
        protein_target = diet_result["protein"] / 3
        fat_target = diet_result["fat"] / 3
        kcal_target = diet_result["calories"] / 3
        diff = (
            ((df["에너지(kcal)"] - kcal_target).abs() / 10.0)
            + (df["탄수화물(g)"] - carb_target).abs()
            + (df["단백질(g)"] - protein_target).abs()
            + (df["지방(g)"] - fat_target).abs()
        )
        df = df.copy()
        df["AI추천점수"] = ai_scores
        df["최종점수"] = df["AI추천점수"] - diff * 0.35
        df = df.sort_values("최종점수", ascending=False).iloc[offset: offset + count]
        return [self._row_to_meal(row) for _, row in df.iterrows()]

    def recommend_workouts(self, ai_profile: dict) -> List[str]:
        workout_type = ai_profile.get("workoutType", "혼합")
        intensity = ai_profile.get("intensity", "보통")
        frequency = ai_profile.get("frequency", "주 4회")
        result = [f"운동 빈도: {frequency}", f"운동 강도: {intensity}"]
        if workout_type == "유산소":
            result += random.sample(WORKOUT_OPTIONS["유산소"], k=3)
        elif workout_type == "무산소":
            parts = ["가슴", "등", "하체", "어깨", "팔"]
            for part in random.sample(parts, k=3):
                result.append(f"{part}: {random.choice(WORKOUT_OPTIONS['무산소'][part])}")
        else:
            result += random.sample(WORKOUT_OPTIONS["혼합"], k=3)
        return result

    @staticmethod
    def _image_for_food(name: str) -> str:
        for keyword, image in IMAGE_RULES:
            if keyword in name:
                return image
        return DEFAULT_IMAGE

    def _row_to_meal(self, row: pd.Series) -> dict:
        name = str(row["식품명"])
        kcal = int(round(float(row["에너지(kcal)"])))
        carb = float(row["탄수화물(g)"])
        protein = float(row["단백질(g)"])
        fat = float(row["지방(g)"])
        score = float(row.get("AI추천점수", 0.0))
        return {
            "name": name,
            "kcal": f"{kcal} kcal / 100g",
            "info": f"탄: {carb:.1f}g | 단: {protein:.1f}g | 지: {fat:.1f}g | AI점수: {score:.0f}점",
            "imagePath": self._image_for_food(name),
            "aiScore": round(score, 1),
        }


ai = AIServer()
app = FastAPI(title="Health AI Local Server - Enhanced")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/health")
def health() -> dict:
    return {"status": "ok", "message": "Enhanced AI server is running", "aiUsage": ["fitness multi-output model", "chat intent model", "food score model"]}


@app.post("/api/plan")
def plan(req: PlanRequest) -> dict:
    return ai.predict(req.height, req.weight, req.goal)


@app.post("/api/modify_plan")
def modify_plan(req: ModifyRequest) -> dict:
    height = req.height or 170.0
    weight = req.weight or 65.0
    goal = req.goal if req.goal is not None else 0.0
    ai_profile = ai.predict_ai_profile(height, weight, goal)
    chat_intent = ai.predict_chat_intent(req.request)

    # 채팅 의도에 따라 AI 분석 결과를 일부 조정합니다.
    # TODO: 프로토타입 단계의 데이터 부족 보완을 위한 임시 규칙 기반 필터링. 
    # 추후 Transformer 기반의 NER(개체명 인식) 및 자연어 슬롯 필링(Slot-filling) 모델로 대체 예정.
    text = req.request.lower()
    if chat_intent["label"] == "식단 유형 변경":
        if "저탄" in text or "감량" in text or "다이어트" in text:
            ai_profile["dietType"] = "감량식"
        elif "벌크" in text or "증량" in text:
            ai_profile["dietType"] = "벌크업식"
        elif "고단백" in text or "단백질" in text:
            ai_profile["dietType"] = "고단백식"
        else:
            ai_profile["dietType"] = "균형식"
    if chat_intent["label"] == "운동 강도 변경":
        if "낮" in text or "힘들" in text or "쉬" in text:
            ai_profile["intensity"] = "낮음"
            ai_profile["frequency"] = "주 3회"
        elif "올" in text or "빡" in text or "강" in text:
            ai_profile["intensity"] = "높음"
            ai_profile["frequency"] = "주 5회"
    if chat_intent["label"] == "운동 추가":
        if "유산소" in text:
            ai_profile["workoutType"] = "유산소"
        elif "무산소" in text or "근력" in text:
            ai_profile["workoutType"] = "무산소"
        else:
            ai_profile["workoutType"] = "혼합"

    diet_result = ai.calculate_diet_targets(height, weight, goal, ai_profile["dietType"])

    should_change_foods = chat_intent["label"] in ["음식 변경", "영양소 조건", "식단 유형 변경"]
    should_change_workouts = chat_intent["label"] in ["운동 추가", "운동 강도 변경"]

    # 일반 질문일 때는 현재 식단을 억지로 제외하지 않습니다.
    # 기존 버전은 모든 채팅 요청에 currentMeals를 exclude해서 "안녕", "왜?" 같은 말에도 식단이 바뀌는 문제가 있었습니다.
    exclude = req.currentMeals if should_change_foods else []
    offset = 3 if should_change_foods else 0
    meals = ai.recommend_foods(diet_result, exclude=exclude, ai_profile=ai_profile, offset=offset, count=3)
    ai_profile["chatIntent"] = chat_intent
    coach_response = ai._coach_response(chat_intent["label"], ai_profile, diet_result)
    return {
        "meals": meals,
        "diet": diet_result,
        "workoutType": ai_profile["workoutType"],
        "workouts": ai.recommend_workouts(ai_profile) if should_change_workouts else ai.recommend_workouts(ai_profile),
        "aiAnalysis": ai_profile,
        "coachResponse": coach_response,
        "modelEvaluation": ai.evaluation,
    }
