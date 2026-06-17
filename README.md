# AI Health Recommendation System

Flutter와 FastAPI, TensorFlow를 활용한 **하이브리드 AI 건강 추천 시스템**입니다.

사용자의 키, 몸무게, 목표 체중 변화량을 입력받아 AI 기반으로 운동 유형, 식단 유형, 운동 강도, 운동 빈도를 예측하고, 공식 기반 영양 계산과 음식 데이터셋을 결합하여 개인화된 식단 및 운동 정보를 추천합니다.

> 본 프로젝트는 학습 및 포트폴리오 목적의 프로토타입이며, 실제 의료·영양 처방 목적으로 사용할 수 없습니다.

---

## 1. Overview

본 프로젝트는 사용자의 신체 정보와 목표값을 기반으로 식단 및 운동 계획을 추천하는 AI 기반 건강 관리 애플리케이션입니다.

Flutter 앱은 사용자 입력과 결과 화면을 담당하고, Python FastAPI 서버는 TensorFlow 모델 학습 및 추천 결과 생성을 담당합니다.

본 시스템은 단순 규칙 기반 추천이 아니라 다음 세 가지 AI 모델을 함께 사용합니다.

- **신체 분석 모델**: 운동 유형, 식단 유형, 운동 강도, 운동 빈도 예측
- **채팅 의도 분석 모델**: 사용자 자연어 요청 분류
- **음식 추천 점수 모델**: 음식별 AI 추천 점수 계산

영양 목표값은 AI가 직접 예측하지 않고 공식 기반으로 계산합니다. 이는 데이터 부족으로 인해 탄수화물, 단백질, 지방 수치가 비현실적으로 예측되는 문제를 방지하기 위한 설계입니다.

---

## 2. Motivation

건강 관리 앱은 사용자의 신체 정보와 목표에 따라 다른 운동 및 식단을 제공해야 합니다. 그러나 단순 고정 추천 방식은 개인의 체중, 목표 변화량, 운동 목적을 충분히 반영하기 어렵습니다.

본 프로젝트에서는 다음 문제를 해결하고자 했습니다.

- 사용자 신체 정보 기반 개인화 추천
- 목표 체중 변화량에 따른 운동/식단 유형 예측
- 음식 영양성분 데이터를 활용한 식단 추천
- 자연어 요청을 분석하여 추천 결과를 수정하는 AI 코치 기능 구현
- AI 수치 예측의 불안정성을 공식 기반 계산으로 보완

---

## 3. System Architecture

```text
Flutter App
  ↓ HTTP POST
FastAPI AI Server
  ↓
TensorFlow Models
  ├─ Body Analysis Model
  ├─ Chat Intent Classification Model
  └─ Food Recommendation Score Model
  ↓
Nutrition Calculation + Food Dataset
  ↓
Recommendation Result
  ↓
Flutter UI
```

---

## 4. Main Features

### 4.1 User Input

사용자는 앱 첫 화면에서 다음 정보를 입력합니다.

- Height
- Weight
- Target weight change

예를 들어 현재 몸무게가 80kg이고 목표가 95kg이라면 목표값은 `+15`로 입력합니다. 현재 몸무게가 80kg이고 70kg까지 감량하고 싶다면 목표값은 `-10`으로 입력합니다.

### 4.2 AI Body Analysis

입력된 신체 정보는 서버에서 다음 feature로 변환됩니다.

```text
height
weight
goal
BMI
goal direction
```

TensorFlow 모델은 이 feature를 기반으로 다음 항목을 예측합니다.

- Workout type: cardio / anaerobic / mixed
- Diet type: weight-loss / bulking / high-protein / balanced
- Exercise intensity: low / medium / high
- Weekly frequency: 3 / 4 / 5 times per week

### 4.3 Nutrition Target Calculation

초기 모델에서는 AI가 탄수화물, 단백질, 지방 수치를 직접 예측하도록 구성했으나, 데이터 부족으로 인해 비현실적인 수치가 발생할 수 있었습니다.

최종 버전에서는 영양 목표값을 공식 기반으로 계산합니다.

```text
maintenance kcal = weight × 33
protein = weight × protein ratio
fat = target kcal × fat ratio / 9
carbohydrate = remaining kcal / 4
```

이 방식은 AI 예측값의 불안정성을 줄이고, 더 현실적인 식단 추천 결과를 제공합니다.

### 4.4 Food Recommendation

`food.xlsx`에 저장된 음식 영양성분 데이터를 기반으로 추천 음식을 선정합니다.

사용되는 주요 데이터는 다음과 같습니다.

- Food name
- Energy
- Carbohydrate
- Protein
- Fat

음식 추천에는 다음 요소가 반영됩니다.

1. 목표 영양값과의 차이
2. AI 음식 추천 점수
3. AI가 예측한 식단 유형

### 4.5 AI Coach Chat

사용자는 AI 코치 입력창에 자연어로 요청할 수 있습니다.

예시:

```text
다른 음식 추천해줘
닭가슴살 말고 다른 거 추천해줘
고단백 식단으로 바꿔줘
운동 강도 낮춰줘
하체 운동 더 추천해줘
왜 이렇게 추천했어?
```

채팅 의도 분석 모델은 사용자의 문장을 다음 클래스로 분류합니다.

- Food change
- Add workout
- Change diet type
- Change exercise intensity
- Nutrition condition
- General question

분류 결과에 따라 서버는 식단 또는 운동 추천을 다시 계산하여 Flutter 앱에 반환합니다.

---

## 5. AI Learning Method

본 프로젝트의 AI 학습 방식은 **강화학습이 아니라 지도학습**입니다.

지도학습은 입력 데이터와 정답 라벨을 함께 제공하여 모델이 입력과 출력 사이의 패턴을 학습하는 방식입니다.

### 5.1 Body Analysis Model

신체 분석 모델은 다중 출력 지도학습 모델입니다.

입력값:

```text
height, weight, goal, BMI, goal direction
```

출력값:

```text
workout type
diet type
exercise intensity
weekly frequency
```

모델 구조:

```text
Input Layer
  ↓
Dense Layer
  ↓
Dropout
  ↓
Dense Layer
  ↓
Dense Layer
  ↓
Multiple Output Layers
```

각 출력층은 softmax를 사용하여 여러 클래스 중 가장 적절한 값을 예측합니다.

기본 학습 횟수는 **90 epoch**입니다.

### 5.2 Chat Intent Classification Model

채팅 의도 분석 모델은 사용자의 자연어 문장을 입력받아 요청 의도를 분류합니다.

모델 구조:

```text
Text Input
  ↓
TextVectorization
  ↓
Embedding
  ↓
GlobalAveragePooling1D
  ↓
Dense Layer
  ↓
Softmax Output
```

이 모델은 사용자의 문장을 음식 변경, 운동 추가, 식단 변경, 강도 변경 등의 클래스로 분류합니다.

기본 학습 횟수는 **55 epoch**입니다.

### 5.3 Food Recommendation Score Model

음식 추천 점수 모델은 음식의 영양성분과 사용자 상태를 입력으로 받아 AI 추천 점수를 계산하는 회귀 모델입니다.

입력값:

```text
food kcal
carbohydrate
protein
fat
BMI
goal
diet type
```

출력값:

```text
AI recommendation score
```

기본 학습 횟수는 **30 epoch**입니다.

---

## 6. Technology Stack

### Frontend

- Flutter
- Dart
- Material UI
- `http`
- `url_launcher`

### Backend

- Python
- FastAPI
- Uvicorn
- Pandas
- NumPy
- Scikit-learn
- TensorFlow
- OpenPyXL

### AI / ML

- Supervised Learning
- Multi-output Classification
- Text Classification
- Regression
- Feature Scaling
- One-hot Encoding
- TextVectorization
- Embedding

---

## 7. API Endpoints

### Health Check

```http
GET /api/health
```

서버 실행 상태를 확인합니다.

응답 예시:

```json
{
  "status": "ok",
  "message": "Enhanced AI server is running",
  "aiUsage": [
    "fitness multi-output model",
    "chat intent model",
    "food score model"
  ]
}
```

### Plan Recommendation

```http
POST /api/plan
```

Request:

```json
{
  "height": 177,
  "weight": 80,
  "goal": 15
}
```

Response 주요 필드:

```json
{
  "workoutType": "무산소",
  "diet": {
    "calories": 2990,
    "carbs": 380,
    "protein": 144,
    "fat": 83,
    "bmi": 25.5,
    "dietType": "벌크업식"
  },
  "meals": [
    {
      "name": "음식명",
      "kcal": "350 kcal / 100g",
      "info": "탄: 20.0g | 단: 35.0g | 지: 8.0g | AI점수: 92점",
      "imagePath": "assets/images/Chicken_breast.png",
      "aiScore": 92.0
    }
  ],
  "workouts": [
    "운동 빈도: 주 4회",
    "운동 강도: 보통"
  ],
  "aiAnalysis": {
    "workoutType": "무산소",
    "dietType": "벌크업식",
    "intensity": "보통",
    "frequency": "주 4회",
    "bmi": 25.5
  }
}
```

### Modify Recommendation

```http
POST /api/modify_plan
```

사용자의 AI 코치 입력을 분석하여 식단 또는 운동 추천을 수정합니다.

---

## 8. How to Run

### 8.1 Run AI Server

```bash
cd ai_server
python -m venv .venv
.venv\Scripts\activate.bat
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8000
```

서버가 정상 실행되면 다음 주소에서 확인할 수 있습니다.

```text
http://localhost:8000/api/health
```

macOS/Linux의 경우 가상환경 활성화 명령어는 다음과 같습니다.

```bash
source .venv/bin/activate
```

### 8.2 Run Flutter App

새 터미널을 열고 다음 명령어를 실행합니다.

```bash
cd flutter_app
flutter pub get
flutter run -d chrome
```

Windows 데스크톱 앱으로 실행하려면 다음 명령어를 사용할 수 있습니다.

```bash
flutter run -d windows
```

Android 에뮬레이터에서는 Flutter 앱이 `http://10.0.2.2:8000`에 접속하고, Chrome/Windows/macOS/Linux 데스크톱 실행에서는 `http://localhost:8000`에 접속합니다.

---

## 9. Project Structure

```text
AI-Health-Recommendation-System/
├─ README.md
├─ .gitignore
├─ docs/
├─ ai_server/
│  ├─ server.py
│  ├─ training_data.py
│  ├─ food.xlsx
│  ├─ requirements.txt
│  ├─ run_server.bat
│  └─ run_server.sh
└─ flutter_app/
   ├─ lib/
   ├─ assets/
   ├─ android/
   ├─ ios/
   ├─ web/
   ├─ windows/
   └─ pubspec.yaml
```

---

## 10. Design Improvement

초기 모델에서는 영양 목표값을 AI가 직접 예측하도록 설계했으나, 데이터 부족으로 인해 비현실적인 수치가 발생할 수 있었습니다. 이를 개선하기 위해 영양 목표값은 공식 기반 계산으로 안정화하고, AI는 운동 유형, 식단 유형, 운동 강도, 채팅 의도 분류, 음식 추천 점수 계산에 활용하는 하이브리드 구조로 재설계했습니다.

이 과정에서 단순 모델 구현을 넘어 다음 과정을 수행했습니다.

- 문제 현상 파악
- 원인 분석
- 모델 역할 재설계
- 공식 기반 계산과 AI 모델의 역할 분리
- 사용자 입력 기반 추천 구조 개선

---

## 11. Limitations

본 프로젝트는 대학원 진학용 포트폴리오 및 학습 목적의 프로토타입입니다. 실제 의료 또는 영양 처방 목적으로 사용할 수 없습니다.

현재 한계점은 다음과 같습니다.

- 학습 데이터 수가 많지 않음
- 실제 사용자 장기 피드백 데이터가 없음
- 식단 추천은 음식 데이터셋의 품질에 영향을 받음
- 채팅 의도 분류 모델은 생성형 AI가 아니므로 복잡한 자유 대화에는 한계가 있음
- 운동 추천은 전문 트레이너의 실제 처방을 대체할 수 없음

---

## 12. Future Work

향후 개선 방향은 다음과 같습니다.

- 실제 사용자 운동 기록 및 체중 변화 데이터 수집
- 추천 결과에 대한 사용자 만족도 피드백 반영
- 개인별 장기 추천 최적화
- 더 큰 음식 영양성분 데이터셋 적용
- Transformer 기반 자연어 처리 모델 적용
- 모델 성능 평가 지표 시각화
- 추천 결과 설명 가능성 강화
- 모바일 앱 배포 및 사용자 데이터 저장 기능 추가

---

## 13. Research Relevance

본 프로젝트는 AI 기반 개인화 추천 시스템, 헬스케어 데이터 분석, 사용자 의도 분류, 하이브리드 추천 알고리즘과 관련이 있습니다.

대학원 진학 이후에는 본 프로젝트를 확장하여 사용자 행동 데이터 기반 개인화 추천, 장기 건강 목표 최적화, 설명 가능한 AI 추천 시스템, 헬스케어 AI 서비스 연구로 발전시킬 수 있습니다.
