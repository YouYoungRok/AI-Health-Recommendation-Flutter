import 'package:flutter/material.dart';           // Flutter 기본 위젯 라이브러리
import 'package:google_fonts/google_fonts.dart';  // 구글 폰트 사용
import 'page1.dart';                              // Page1 화면으로 이동하기 위해 import

void main() {
  runApp(const MyApp());                         // 앱 실행 진입점: MyApp 위젯을 루트로 띄움
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);      // StatelessWidget 생성자

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BackgroundWithDinosaur(),             // 첫 화면으로 BackgroundWithDinosaur 사용
    );
  }
}

/// 원래 StatelessWidget이던 부분을 StatefulWidget으로 바꿔서
/// 입력값 컨트롤러와 로직을 넣을 수 있게 변경했습니다.
class BackgroundWithDinosaur extends StatefulWidget {
  const BackgroundWithDinosaur({Key? key}) : super(key: key);

  @override
  _BackgroundWithDinosaurState createState() => _BackgroundWithDinosaurState();
}

class _BackgroundWithDinosaurState extends State<BackgroundWithDinosaur> {
  // ─────────────────────────────────────────────────────────────
  // 1) 사용자 입력을 받을 TextEditingController 3개 선언
  // ─────────────────────────────────────────────────────────────
  final TextEditingController heightController = TextEditingController(); // 키 입력용
  final TextEditingController weightController = TextEditingController(); // 몸무게 입력용
  final TextEditingController goalController   = TextEditingController(); // 목표값 입력용

  // ─────────────────────────────────────────────────────────────
  // 2) TextField의 문자열을 파싱해 저장할 double 타입 변수
  // ─────────────────────────────────────────────────────────────
  late double height;  // 나중에 키(cm) 값이 들어감
  late double weight;  // 나중에 몸무게(kg) 값이 들어감
  late double goal;    // 나중에 목표(±kg) 값이 들어감

  // ─────────────────────────────────────────────────────────────
  // 3) “다음” 버튼 눌렀을 때 로딩 인디케이터 제어용 플래그
  // ─────────────────────────────────────────────────────────────
  bool _isLoading = false;

  @override
  void dispose() {
    // 사용이 끝난 컨트롤러는 dispose() 해 주어야 메모리 누수 방지
    heightController.dispose();
    weightController.dispose();
    goalController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // 4) “다음” 버튼의 onPressed에 연결된 메서드
  //    - TextField 입력값을 파싱해 변수에 저장
  //    - (TODO) 서버/클라우드 AI로 이 값을 전송
  //    - Page1 화면으로 전달하며 네비게이트
  // ─────────────────────────────────────────────────────────────
  Future<void> _saveAndSendMetrics() async {
    setState(() {
      _isLoading = true;  // 4-A) 로딩 시작 (버튼 비활성화 및 스피너 표시)
    });

    // 4-B) 사용자가 입력한 문자열을 double로 변환, 실패 시 0.0
    height = double.tryParse(heightController.text) ?? 0.0;
    weight = double.tryParse(weightController.text) ?? 0.0;
    goal   = double.tryParse(goalController.text)   ?? 0.0;

    // 4-C) TODO: 실제 서버 전송 로직 위치
    //     final payload = { 'height': height, 'weight': weight, 'goal': goal };
    //     await http.post(uri, headers: ..., body: json.encode(payload));

    // 4-D) Page1 생성자 파라미터로 사용자 입력값(문자열)을 그대로 넘기며 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Page1(
          height:     heightController.text,
          weight:     weightController.text,
          goal:       goalController.text,
          goalWeight: '',          // 나중에 서버 응답으로 받은 목표체중이 있다면 여기에
        ),
      ),
    );

    setState(() {
      _isLoading = false; // 4-E) 네비게이트 후 로딩 종료
    });
  }

  @override
  Widget build(BuildContext context) {
    // ─────────────────────────────────────────────────────────────
    // 전체 UI: 배경 이미지 + 공룡 이미지 + 입력폼 + 버튼
    // 전부 기존 디자인 그대로, 주석만 덧붙임
    // ─────────────────────────────────────────────────────────────
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'), // 배경화면
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // ─────────────────────────────────────────────────────────
            // A) 공룡 이미지: 화면 하단 우측에 배치
            // ─────────────────────────────────────────────────────────
            const Align(
              alignment: Alignment(0.07, 0.7),
              child: Image(
                image: AssetImage('assets/images/dragon.png'),
                width: 500,
                height: 500,
                fit: BoxFit.contain,
              ),
            ),
            // ─────────────────────────────────────────────────────────
            // B) 입력폼과 버튼: 화면 중앙(위쪽)에 세로 정렬
            // ─────────────────────────────────────────────────────────
            Align(
              alignment: const Alignment(0, -0.2),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 자식 크기만큼 세로로 축소
                children: [
                  // ────────────────────────────────────────────────
                  // B-1) 키 입력 TextField
                  // ────────────────────────────────────────────────
                  SizedBox(
                    width: 150, // 가로 150 고정
                    child: TextField(
                      controller: heightController,       // 컨트롤러 연결
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),  // 숫자/소수/음수 입력
                      textAlign: TextAlign.center,         // 가운데 정렬
                      maxLength: 5,                        // 최대 5글자
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        counterText: "", // 글자수 카운터 숨김
                        border: const OutlineInputBorder(),
                        labelText: '키 (cm)',
                        labelStyle: const TextStyle(color: Colors.white),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ────────────────────────────────────────────────
                  // B-2) 몸무게 입력 TextField
                  // ────────────────────────────────────────────────
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      textAlign: TextAlign.center,
                      maxLength: 5,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        counterText: "",
                        border: const OutlineInputBorder(),
                        labelText: '몸무게 (kg)',
                        labelStyle: const TextStyle(color: Colors.white),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ────────────────────────────────────────────────
                  // B-3) 목표값 입력 TextField
                  // ────────────────────────────────────────────────
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: goalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      textAlign: TextAlign.center,
                      maxLength: 5,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        counterText: "",
                        border: const OutlineInputBorder(),
                        labelText: '목표값',
                        labelStyle: const TextStyle(color: Colors.white),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ────────────────────────────────────────────────
                  // B-4) “다음” 버튼: 누르면 _saveAndSendMetrics 호출
                  // ────────────────────────────────────────────────
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndSendMetrics, // 로딩 중이면 비활성
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white) // 로딩 스피너
                        : const Text('다음', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
