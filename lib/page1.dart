import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:health_project/page2.dart';

class Page1 extends StatefulWidget {
  final String height;
  final String weight;
  final String goal;
  final String goalWeight;

  const Page1({
    Key? key,
    required this.height,
    required this.weight,
    required this.goal,
    required this.goalWeight,
  }) : super(key: key);

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  List<MealItem> _meals = [];
  List<String> _workouts = [];
  Map<String, dynamic>? _diet;
  Map<String, dynamic>? _aiAnalysis;
  String _workoutType = '-';
  String? _coachResponse;
  String? _errorMessage;

  bool _isLoading = true;
  bool _isUpdating = false;

  final TextEditingController _chatController = TextEditingController();

  String get _baseUrl {
    // Chrome/Windows/macOS/Linux 데스크톱 실행: http://localhost:8000
    // Android 에뮬레이터 실행: http://10.0.2.2:8000
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  double get _height => double.tryParse(widget.height) ?? 0.0;
  double get _weight => double.tryParse(widget.weight) ?? 0.0;
  double get _goal => double.tryParse(widget.goal) ?? 0.0;

  @override
  void initState() {
    super.initState();
    _fetchMealPlanFromAI();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _fetchMealPlanFromAI() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = {
      'height': _height,
      'weight': _weight,
      'goal': _goal,
    };

    try {
      final uri = Uri.parse('$_baseUrl/api/plan');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        _applyAIResponse(data);
      } else {
        _setError('AI 서버 오류: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      _setError('AI 서버에 연결할 수 없습니다.\n로컬 서버 실행 후 다시 시도하세요.\n$_baseUrl/api/health\n\n상세 오류: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _modifyMealPlanOnUserRequest(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    final payload = {
      'currentMeals': _meals.map((m) => m.name).toList(),
      'request': userMessage,
      'height': _height,
      'weight': _weight,
      'goal': _goal,
    };

    try {
      final uri = Uri.parse('$_baseUrl/api/modify_plan');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        _applyAIResponse(data);
      } else {
        _setError('AI 서버 오류: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      _setError('식단 변경 요청 실패: $e');
    } finally {
      _chatController.clear();
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _applyAIResponse(Map<String, dynamic> data) {
    final mealList = (data['meals'] as List<dynamic>? ?? [])
        .map((item) => MealItem.fromJson(item as Map<String, dynamic>))
        .toList();

    setState(() {
      _meals = mealList;
      _diet = data['diet'] as Map<String, dynamic>?;
      _aiAnalysis = data['aiAnalysis'] as Map<String, dynamic>?;
      _workoutType = data['workoutType']?.toString() ?? '-';
      _coachResponse = data['coachResponse']?.toString();
      _workouts = (data['workouts'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    });
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  int get _goalAsInt => int.tryParse(widget.goal) ?? double.tryParse(widget.goal)?.round() ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AI 식단 추천',
          style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'AI 서버 다시 요청',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _fetchMealPlanFromAI,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      _summaryCard(),
                      if (_errorMessage != null) _errorCard(_errorMessage!),
                      const SizedBox(height: 12),
                      Text(
                        '추천 식단',
                        style: GoogleFonts.notoSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_meals.isEmpty)
                        Text('추천 식단이 없습니다.', style: GoogleFonts.notoSans(color: Colors.white70))
                      else
                        ..._meals.map((meal) => meal),
                      const SizedBox(height: 16),
                      if (_workouts.isNotEmpty) _workoutCard(),
                    ],
                  ),
          ),
          _chatBox(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('운동 추천 보기', style: GoogleFonts.notoSans(color: Colors.white)),
        icon: const Icon(Icons.fitness_center, color: Colors.white),
        backgroundColor: Colors.blueAccent,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Page2(goalValue: _goalAsInt)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _summaryCard() {
    final carbs = _diet?['carbs'] ?? '-';
    final protein = _diet?['protein'] ?? '-';
    final fat = _diet?['fat'] ?? '-';
    final calories = _diet?['calories'] ?? '-';
    final bmi = _diet?['bmi'] ?? _aiAnalysis?['bmi'] ?? '-';
    final dietType = _aiAnalysis?['dietType'] ?? _diet?['dietType'] ?? '-';
    final dietConf = _aiAnalysis?['dietConfidence'];
    final workoutConf = _aiAnalysis?['workoutConfidence'];
    final intensity = _aiAnalysis?['intensity'] ?? '-';
    final intensityConf = _aiAnalysis?['intensityConfidence'];
    final frequency = _aiAnalysis?['frequency'] ?? '-';
    final chatIntent = _aiAnalysis?['chatIntent'];

    String pct(dynamic v) {
      if (v == null) return '-';
      final d = double.tryParse(v.toString());
      if (d == null) return v.toString();
      return '${(d * 100).round()}%';
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('확장 AI 분석 결과', style: GoogleFonts.notoSans(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('입력값: 키 ${widget.height}cm / 몸무게 ${widget.weight}kg / 목표 ${widget.goal}kg / BMI $bmi',
              style: GoogleFonts.notoSans(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('AI 운동 유형: $_workoutType  ·  신뢰도 ${pct(workoutConf)}',
              style: GoogleFonts.notoSans(color: Colors.lightBlueAccent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('AI 식단 유형: $dietType  ·  신뢰도 ${pct(dietConf)}',
              style: GoogleFonts.notoSans(color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('AI 운동 강도/빈도: $intensity ${pct(intensityConf)} · $frequency',
              style: GoogleFonts.notoSans(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('영양 목표: ${calories}kcal / 탄수화물 ${carbs}g / 단백질 ${protein}g / 지방 ${fat}g',
              style: GoogleFonts.notoSans(color: Colors.white70)),
          if (chatIntent is Map) ...[
            const SizedBox(height: 8),
            Text('채팅 의도 AI 분석: ${chatIntent['label']} · 신뢰도 ${pct(chatIntent['confidence'])}',
                style: GoogleFonts.notoSans(color: Colors.purpleAccent, fontWeight: FontWeight.w600)),
          ],
          if (_coachResponse != null && _coachResponse!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('AI 코치 답변: $_coachResponse',
                style: GoogleFonts.notoSans(color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 8),
          Text('AI 사용: 운동/식단유형/강도/빈도 예측 + 채팅 의도 분류 + 음식 AI점수 산정',
              style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _workoutCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI 추천 운동', style: GoogleFonts.notoSans(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._workouts.map((w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('• $w', style: GoogleFonts.notoSans(color: Colors.white70)),
              )),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return GlassCard(
      child: Text(message, style: GoogleFonts.notoSans(color: Colors.redAccent)),
    );
  }

  Widget _chatBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('💬 AI 코치와 대화하기', style: GoogleFonts.notoSans(color: Colors.white70))),
                if (_isUpdating) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _chatController,
              onSubmitted: _isUpdating ? null : _modifyMealPlanOnUserRequest,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '예: 다른 음식 추천 / 강도 낮춰줘 / 왜 이렇게 추천했어',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white70),
                  onPressed: _isUpdating ? null : () => _modifyMealPlanOnUserRequest(_chatController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MealItem extends StatelessWidget {
  final String name;
  final String kcal;
  final String info;
  final String imagePath;

  const MealItem({
    Key? key,
    required this.name,
    required this.kcal,
    required this.info,
    required this.imagePath,
  }) : super(key: key);

  factory MealItem.fromJson(Map<String, dynamic> json) {
    final rawInfo = json['info']?.toString() ?? '';
    final fullInfo = rawInfo
        .replaceAll(RegExp(r'탄:'), '탄수화물:')
        .replaceAll(RegExp(r'단:'), '단백질:')
        .replaceAll(RegExp(r'지:'), '지방:');

    return MealItem(
      name: json['name']?.toString() ?? '추천 음식',
      kcal: json['kcal']?.toString() ?? '',
      info: fullInfo,
      imagePath: json['imagePath']?.toString() ?? 'assets/images/Chicken_breast.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/Chicken_breast.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(kcal, style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 3),
                Text(info, style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
