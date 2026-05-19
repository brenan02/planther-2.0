import 'package:flutter/material.dart';
import '../auth/main_shell.dart';
import 'package:flutter_application_1/services/survey_service.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  bool _isSubmitting = false;
  final _surveyService = SurveyService();
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final Map<int, String> _answers = {};

  final List<_SurveyQuestion> _questions = [
    _SurveyQuestion(
      number: 'I',
      title: 'Experience Level',
      subtitle: 'What is your level of experience with plants?',
      options: ['Beginner', 'Intermediate', 'Advanced'],
    ),
    _SurveyQuestion(
      number: 'II',
      title: 'Living Environment',
      subtitle: 'Where do you plan to keep your plant?',
      options: ['Indoor', 'Outdoor', 'A mix of both'],
    ),
    _SurveyQuestion(
      number: 'III',
      title: 'Lighting Condition',
      subtitle:
          'How bright is the location where you will place your plant?',
      options: ['Low', 'Medium', 'Bright'],
    ),
    _SurveyQuestion(
      number: 'IV',
      title: 'Maintenance Level',
      subtitle: 'How much time and effort can you give to plant care?',
      options: ['Low', 'Medium', 'High'],
    ),
    _SurveyQuestion(
      number: 'V',
      title: 'Available Space',
      subtitle: 'How much space do you have for your plant?',
      options: [
        'Small (desk/table)',
        'Medium (room/corner)',
        'Large (garden/outdoor area)',
      ],
    ),
    _SurveyQuestion(
      number: 'VI',
      title: 'Plant Purpose',
      subtitle: 'What type of plant are you looking for?',
      options: [
        'Decorative',
        'Edible (herbs/vegetables)',
        'Air-purifying',
        'Climbing / wall plant',
      ],
    ),
    _SurveyQuestion(
      number: 'VII',
      title: 'Pet Safety',
      subtitle: 'Do you need a pet-safe plant?',
      options: ['Yes', 'No'],
    ),
  ];

  void _nextPage() {
    if (_answers[_currentPage] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an answer to continue'),
          backgroundColor: const Color(0xFF2D6A4F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submitSurvey();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitSurvey() async {
    setState(() => _isSubmitting = true);

    try {
      final Map<String, String> surveyAnswers = {
        'experience': _answers[0] ?? '',
        'environment': _answers[1] ?? '',
        'lighting': _answers[2] ?? '',
        'maintenance': _answers[3] ?? '',
        'space': _answers[4] ?? '',
        'purpose': _answers[5] ?? '',
        'petSafe': _answers[6] ?? '',
      };

      final recommendations =
          await _surveyService.submitSurvey(surveyAnswers);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShell(
            surveyAnswers: surveyAnswers,
            recommendations: recommendations,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFDDD8D0),
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Text(
                        '${_currentPage + 1} of ${_questions.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A8578),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE8E4DC),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2D6A4F),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D6A4F)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Question ${q.number}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D6A4F),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          q.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          q.subtitle,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8A8578),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ...q.options.map((option) {
                          final isSelected = _answers[index] == option;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _answers[index] = option);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2D6A4F)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2D6A4F)
                                      : const Color(0xFFDDD8D0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5F0),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _prevPage,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          side: const BorderSide(
                            color: Color(0xFFDDD8D0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          foregroundColor: const Color(0xFF1A1A1A),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _nextPage,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentPage == _questions.length - 1
                                  ? 'Get my plants 🌱'
                                  : 'Next',
                            ),
                    ),
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

class _SurveyQuestion {
  final String number;
  final String title;
  final String subtitle;
  final List<String> options;

  const _SurveyQuestion({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.options,
  });
}