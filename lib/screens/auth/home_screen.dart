import 'package:flutter/material.dart';
import '../survey/survey_screen.dart';
import 'package:planther/services/ai_service.dart';
import 'package:planther/services/survey_service.dart';
import '../recommendations/plant_card_view.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, String>? surveyAnswers;
  final List<PlantRecommendation>? recommendations;

  const HomeScreen({
    super.key,
    this.surveyAnswers,
    this.recommendations,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isTableView = false;
  List<PlantRecommendation> _plants = [];
  bool _isLoadingRecommendations = false;
  bool _isRefreshing = false;

  bool get _hasSurveyResults =>
      widget.surveyAnswers != null || _plants.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.recommendations != null) {
      _plants = widget.recommendations!;
    } else {
      _loadSavedRecommendations();
    }
  }

  void _loadSavedRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final saved = await SurveyService().loadRecommendations();
      if (mounted) setState(() => _plants = saved);
    } catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  // ── Refresh without retaking survey ────────────────────────────────────────
  void _refreshRecommendations() async {
    setState(() => _isRefreshing = true);
    try {
      final fresh = await SurveyService().refreshRecommendations();
      if (mounted) setState(() => _plants = fresh);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('No survey')
                ? 'Please take the survey first'
                : 'Could not refresh. Try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👋Aloe po!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome to Planther! Have a blooming day🌷',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoadingRecommendations
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D6A4F),
                      ),
                    )
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSurveyCard(),
                          if (_hasSurveyResults) ...[
                            const SizedBox(height: 32),
                            _buildResultsSection(),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SurveyScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2D6A4F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasSurveyResults
                        ? 'Retake the survey'
                        : 'Find your perfect plant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _hasSurveyResults
                        ? 'Update your preferences anytime'
                        : 'Answer 7 quick questions to get personalized recommendations',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recommended for you',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDD8D0)),
              ),
              child: Row(
                children: [
                  _buildToggleButton(
                    icon: Icons.view_agenda_outlined,
                    isActive: !_isTableView,
                    onTap: () => setState(() => _isTableView = false),
                  ),
                  _buildToggleButton(
                    icon: Icons.table_rows_outlined,
                    isActive: _isTableView,
                    onTap: () => setState(() => _isTableView = true),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAnswerSummary(),
        const SizedBox(height: 20),
        _isTableView ? _buildTableView() : _buildScrollView(),

        // ── Refresh button ────────────────────────────────────────────
        const SizedBox(height: 20),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: _isRefreshing ? null : _refreshRecommendations,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4b986c).withOpacity(0.4)),
        ),
        child: _isRefreshing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4b986c),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Getting new suggestions...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4b986c),
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded,
                      color: Color(0xFF4b986c), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Suggest different plants',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4b986c),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2D6A4F)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : const Color(0xFF8A8578),
        ),
      ),
    );
  }

  Widget _buildAnswerSummary() {
    if (widget.surveyAnswers == null) return const SizedBox();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: widget.surveyAnswers!.entries.map((entry) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2D6A4F).withOpacity(0.2),
            ),
          ),
          child: Text(
            entry.value,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF2D6A4F),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScrollView() {
    if (_plants.isEmpty) {
      return Center(
        child: Text(
          'No recommendations yet.\nTake the survey to get started!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade400,
            height: 1.5,
          ),
        ),
      );
    }
    return PlantCardView(plants: _plants);
  }

  Widget _buildTableView() {
    if (_plants.isEmpty) {
      return Center(
        child: Text(
          'No recommendations yet.',
          style:
              TextStyle(fontSize: 14, color: Colors.grey.shade400),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEAE2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2.5),
            2: FlexColumnWidth(1.6),
          },
          children: [
            TableRow(
              decoration:
                  const BoxDecoration(color: Color(0xFF2D6A4F)),
              children: [
                _tableHeader('Plant'),
                _tableHeader('Why it suits you'),
                _tableHeader('Care'),
              ],
            ),
            ..._plants.asMap().entries.map((entry) {
              final i = entry.key;
              final plant = entry.value;
              return TableRow(
                decoration: BoxDecoration(
                  color: i % 2 == 0
                      ? Colors.white
                      : const Color(0xFFF8F5F0),
                ),
                children: [
                  _tableCell(plant.plantName, bold: true),
                  _tableCell(plant.reason),
                  _tableCell(plant.careLevel),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _tableCell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF1A1A1A),
              fontWeight:
                  bold ? FontWeight.w600 : FontWeight.normal,
              height: 1.4)),
    );
  }
}