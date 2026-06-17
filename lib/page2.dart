import 'dart:ui';           // BackdropFilter blur
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // 유튜브 링크 열기

class Page2 extends StatefulWidget {
  final int goalValue;     // MainPage에서 넘겨준 goal (정수)

  const Page2({Key? key, required this.goalValue}) : super(key: key);

  @override
  State<Page2> createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  // ─────────────────────────────────────────────────────────────
  // 1) AI 채팅 입력용 컨트롤러
  // ─────────────────────────────────────────────────────────────
  final TextEditingController _chatController = TextEditingController();

  // ─────────────────────────────────────────────────────────────
  // 2) 선택 가능한 운동 부위 목록 (가슴, 등, 하체, 어깨, 팔, 유산소)
  // ─────────────────────────────────────────────────────────────
  final List<String> bodyParts = ['가슴', '등', '하체', '어깨', '팔', '유산소'];

  // ─────────────────────────────────────────────────────────────
  // 3) 현재 선택된 부위 저장 (FilterChip 토글)
  // ─────────────────────────────────────────────────────────────
  final Set<String> selectedParts = {};

  // ─────────────────────────────────────────────────────────────
  // 4) 각 부위별 추천 리스트: 이름·설명·이미지·유튜브 링크
  // ─────────────────────────────────────────────────────────────
  /// 6개 운동 + 유튭브 링크
  final Map<String, List<Map<String, String>>> recommendations = {
    '가슴': [
      {
        'name': '벤치 프레스',
        'desc': '대흉근(가슴), 전면 삼각근(어깨 앞쪽), 상완 삼두근(팔 뒤쪽) 강화',
        'image': 'assets/images/bench_press.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '인클라인 덤벨 프레스',
        'desc': '가슴 상부(쇄골 부위)를 집중적으로 자극하는 복합 운동',
        'image': 'assets/images/incline_dumbbell_press.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '케이블 크로스오버',
        'desc': '대흉근(가슴 전체) 특히 내측·하부 섬유',
        'image': 'assets/images/cable_crossover.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '푸쉬업',
        'desc': '별도의 기구 없이 체중만으로 상체 근력을 강화할 수 있는 복합 운동',
        'image': 'assets/images/push_up.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '딥스',
        'desc': '체중을 이용해 가슴과 삼두근, 어깨 근육을 강화하는 복합 운동',
        'image': 'assets/images/dips.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '팩덱 플라이',
        'desc': ' 대흉근 외측·내측 섬유',
        'image': 'assets/images/pec_deck_fly.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
    ],
    '등': [
      {
        'name': '랫풀다운',
        'desc': '광배근(등 넓은근), 승모근 하부, 상완 이두근',
        'image': 'assets/images/lat_pulldown.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '바벨 로우',
        'desc': '광배근(등 넓은근), 승모근(등 중간·상부), 능형근(견갑 주변), 후면 삼각근, 상완 이두근',
        'image': 'assets/images/barbell_row.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '암풀다운',
        'desc': '광배근(등 넓은근) 외측·하부, 승모근 하부, 코어 안정성',
        'image': 'assets/images/armpulldown.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '풀업',
        'desc': '광배근(등 넓은근), 상완 이두근, 승모근 상부, 후면 삼각근, 코어 근육',
        'image': 'assets/images/pull_up.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '시티드 로우',
        'desc': '중간·하부 승모근, 능형근, 광배근(등 중앙), 상완 이두근',
        'image': 'assets/images/seated_row.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '원암 덤벨 로우',
        'desc': '광배근(등 넓은근), 능형근(견갑 주변), 하부 승모근, 상완 이두근, 코어 근육',
        'image': 'assets/images/one_arm_row.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
    ],
    '하체': [
      {
        'name': '스쿼트',
        'desc': ' 대퇴사두근(허벅지 앞), 햄스트링(허벅지 뒤), 둔근(엉덩이), 내전근(골반 안쪽), 코어 근육',
        'image': 'assets/images/squat.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '레그 익스텐션',
        'desc': '대퇴사두근(허벅지 앞쪽)',
        'image': 'assets/images/leg_extension.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '레그프레스',
        'desc': '대퇴사두근(허벅지 앞), 둔근(엉덩이), 햄스트링(허벅지 뒤), 비복근(종아리)',
        'image': 'assets/images/leg_press.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '레그컬',
        'desc': '햄스트링(허벅지 뒤쪽)',
        'image': 'assets/images/leg_curl.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '불가리안 스플릿 스쿼트',
        'desc': '대퇴사두근(허벅지 앞), 둔근(엉덩이), 햄스트링(허벅지 뒤), 내전근(골반 안쪽), 코어 근육',
        'image': 'assets/images/Bulgarian_Split_Squat.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '데드리프트',
        'desc': '햄스트링(허벅지 뒤), 둔근(엉덩이), 척추기립근(허리), 승모근·광배근(등 상부), 전완근(그립)',
        'image': 'assets/images/deadlift.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
    ],
    '어깨': [
      {
        'name': '숄더 프레스',
        'desc': '삼각근(전·측·후면), 상완 삼두근, 승모근 상부',
        'image': 'assets/images/shoulder_press.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '사이드 레터럴 레이즈',
        'desc': '삼각근 측면(중간 삼각근)',
        'image': 'assets/images/side_lateral_raise.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '벤트오버 레이즈',
        'desc': '후면 어깨 자극',
        'image': 'assets/images/bent_over_raise.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '밀리터리 프레스',
        'desc': ' 삼각근 전면·측면, 상완 삼두근, 승모근 상부, 코어 근육',
        'image': 'assets/images/Military_Press.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '페이스 풀',
        'desc': '후면 삼각근(어깨 뒤쪽), 상부 승모근, 능형근(견갑골 주변 안정근)',
        'image': 'assets/images/Face_Pull.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '업라이트 로우',
        'desc': '상부 승모근, 삼각근 측면, 상완 이두근(보조)',
        'image': 'assets/images/Upright_Row.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
    ],
    '팔': [
      {
        'name': '바벨 컬',
        'desc': ' 상완 이두근(팔 앞쪽)',
        'image': 'assets/images/barbell_curl.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '케이블 푸쉬다운',
        'desc': '상완 삼두근(장두·측두·외측두건)',
        'image': 'assets/images/cable_pushdown.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '덤벨 컬',
        'desc': '상완 이두근(팔 앞쪽)',
        'image': 'assets/images/Dumbbell_Curl.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '트라이셉 익스텐션',
        'desc': ' 상완 삼두근(장두·측두·외측두건)',
        'image': 'assets/images/tricep_extension.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '해머 컬',
        'desc': '상완 이두근(이두근 장두·단두), 상완 요측근(팔꿈치 측면), 전완근(손목 굽힘 보조)',
        'image': 'assets/images/hammer_curl.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '클로즈 그립 벤치프레스',
        'desc': '상완 삼두근(팔 뒤쪽), 대흉근(가슴 내부), 전면 삼각근(어깨 앞쪽)',
        'image': 'assets/images/Close-Grip_Bench_Press.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
    ],
    '유산소': [
      {
        'name': '러닝',
        'desc': '대퇴사두근(허벅지 앞), 햄스트링(허벅지 뒤), 둔근(엉덩이), 비복근·가자미근(종아리), 코어 근육',
        'image': 'assets/images/running.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '사이클링',
        'desc': '대퇴사두근(허벅지 앞), 햄스트링(허벅지 뒤), 둔근(엉덩이), 비복근·가자미근(종아리), 심폐 시스템',
        'image': 'assets/images/cycling.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '스텝밀',
        'desc': '대퇴사두근(허벅지 앞), 둔근(엉덩이), 햄스트링(허벅지 뒤), 비복근·가자미근(종아리), 코어 근육',
        'image': 'assets/images/Climbing_Machine.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '점프스쿼트',
        'desc': '하체(사두·햄스트링·둔근), 코어',
        'image': 'assets/images/Squat_Jump.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '버피',
        'desc': '대퇴사두근, 둔근, 햄스트링, 코어 근육, 가슴(대흉근), 삼두근, 어깨(전·측면 삼각근)',
        'image': 'assets/images/burpee.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
      {
        'name': '점핑 잭',
        'desc': '대퇴사두근(허벅지 앞), 둔근(엉덩이), 종아리(비복근·가자미근), 어깨(전·측면 삼각근), 코어 근육',
        'image': 'assets/images/jumping_jack.png',
        'video': 'https://www.youtube.com/watch?v=bJkhBZ1ZcuY'
      },
    ],
  };

  // ─────────────────────────────────────────────────────────────
  // 5) 각 부위별 화면에 표시할 개수 (최초 2개, “더 추천” 시 +2)
  // ─────────────────────────────────────────────────────────────
  final Map<String, int> displayCount = {};

  @override
  void initState() {
    super.initState();
    // F) 초기엔 모든 부위에 2개씩 표시하도록 세팅
    for (var part in bodyParts) {
      displayCount[part] = 2;
    }
  }

  /// ─────────────────────────────────────────────────────────────
  /// 6) AI 채팅(“더 추천”, “추가”) 요청 처리
  ///    - 메시지에 특정 부위명이 있으면 그 부위만 +2
  ///    - 없으면 모든 선택된 부위 +2
  /// ─────────────────────────────────────────────────────────────
  void handleChatInput(String message) {
    final msg = message.toLowerCase();
    setState(() {
      if (msg.contains('더 추천') || msg.contains('추가')) {
        // a) 메시지에 언급된 부위 목록
        final targets = <String>[];
        for (var part in selectedParts) {
          if (msg.contains(part.toLowerCase())) {
            targets.add(part);
          }
        }
        // b) 언급된 게 없으면 모두
        if (targets.isEmpty) targets.addAll(selectedParts);
        // c) 각 대상 부위별 표시 개수 +2 (최대 6)
        for (var part in targets) {
          final cur = displayCount[part]!;
          displayCount[part] = (cur + 2).clamp(0, recommendations[part]!.length);
        }
      }
    });
    _chatController.clear(); // 입력 필드 초기화
  }

  /// ─────────────────────────────────────────────────────────────
  /// 7) 운동 영상 링크 확인 후 유튜브 열기
  /// ─────────────────────────────────────────────────────────────
  Future<void> _confirmAndLaunch(String url) async {
    // a) 팝업으로 “유튜브로 이동하시겠습니까?” 확인
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('유튜브로 이동', style: GoogleFonts.notoSans()),
        content: Text('유튜브로 이동하시겠습니까?', style: GoogleFonts.notoSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('예', style: GoogleFonts.notoSans())),
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('아니요', style: GoogleFonts.notoSans())),
        ],
      ),
    );
    if (ok == true) {
      // b) 실제 브라우저/앱 내에서 유튜브 URL 열기
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('유튜브를 열 수 없습니다.', style: GoogleFonts.notoSans())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ─────────────────────────────────────────────────────────────
    // a) 벌크업/다이어트에 따른 무산소 vs 유산소 비율 계산
    // ─────────────────────────────────────────────────────────────
    final isBulk = widget.goalValue >= 0;
    final anaPercent = isBulk ? 70 : 30; // 무산소 %
    final aeroPercent = 100 - anaPercent; // 유산소 %

    return Scaffold(
      backgroundColor: const Color(0xFF0E0F1A),
      appBar: AppBar( // 상단 앱바
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('운동 추천',
            style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ──────────────────────────────────────────
                // a-1) 운동 비중 막대 차트
                // ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('운동 비중',
                          style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: anaPercent, // 무산소 비율만큼 flex
                            child: Container(height: 8, decoration: BoxDecoration(color: Colors.redAccent, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)))),
                          ),
                          Expanded(
                            flex: aeroPercent, // 유산소 비율만큼 flex
                            child: Container(height: 8, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('무산소 $anaPercent%', style: GoogleFonts.notoSans(fontSize: 12, color: Colors.white70)),
                        Text('유산소 $aeroPercent%', style: GoogleFonts.notoSans(fontSize: 12, color: Colors.white70)),
                      ]),
                    ],
                  ),
                ),

                // ──────────────────────────────────────────
                // b-1) 운동 부위 선택 필터칩
                // ──────────────────────────────────────────
                Text("운동 부위를 선택하세요 (최대 6개)", style: GoogleFonts.notoSans(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: bodyParts.map((part) {
                    final sel = selectedParts.contains(part);
                    return FilterChip(
                      label: Text(part, style: TextStyle(color: sel ? Colors.white : Colors.black)),
                      selected: sel,
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blueAccent,
                      onSelected: (b) {
                        setState(() {
                          if (b && selectedParts.length < 6) selectedParts.add(part);
                          else selectedParts.remove(part);
                        });
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ──────────────────────────────────────────
                // c) 선택된 부위별 추천 운동 리스트
                // ──────────────────────────────────────────
                if (selectedParts.isNotEmpty)
                  ...selectedParts.expand((part) {
                    final count = displayCount[part]!;
                    return [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text('$part 운동 추천', style: GoogleFonts.notoSans(fontSize: 18, color: Colors.white)),
                      ),
                      ...recommendations[part]!.take(count).map((ex) => InkWell(
                        onTap: () => _confirmAndLaunch(ex['video']!),
                        child: GlassCard(
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(ex['image']!, width: 80, height: 80, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ex['name']!, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(ex['desc']!, style: GoogleFonts.notoSans(color: Colors.white60, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ];
                  }),
              ],
            ),
          ),

          // ──────────────────────────────────────────
          // d) AI 코치와 대화 입력창
          // ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("💬 AI 코치와 대화하기", style: GoogleFonts.notoSans(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _chatController,
                    onSubmitted: handleChatInput, // “더 추천” 요청 처리
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '"특정부위"운동 더 추천해줘',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ──────────────────────────────────────────
      // e) 하단 “다음” 버튼: Page2 이동
      // ──────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        label: Text('다음', style: GoogleFonts.notoSans(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Page2(goalValue: widget.goalValue)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// 음식 카드 UI: 이미지를 왼쪽에, 텍스트 정보를 오른쪽에 표시
class MealItem extends StatelessWidget {
  final String name, kcal, info, imagePath;
  const MealItem({Key? key, required this.name, required this.kcal, required this.info, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(imagePath, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(kcal,
                    style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 13)),
                Text(info,
                    style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 반투명 블러 카드: 배경을 흐리게 한 뒤 콘텐츠를 올리기 위해 사용
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
