import 'package:flutter/material.dart';
import 'package:planther/services/care_guide_service.dart';

class PlantCareScreen extends StatefulWidget {
  const PlantCareScreen({super.key});

  @override
  State<PlantCareScreen> createState() => _PlantCareScreenState();
}

class _PlantCareScreenState extends State<PlantCareScreen> {
  final _service = CareGuideService();
  List<CareGuide> _guides = [];
  bool _isLoading = true;
  bool _hasSurvey = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final hasSurvey = await _service.hasSurveyAnswers();
      final guides = await _service.getPersonalizedGuides();
      if (mounted) {
        setState(() {
          _guides = guides;
          _hasSurvey = hasSurvey;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load guides. Tap to retry.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plant Care',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Guides personalized for you',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: _isLoading ? null : _load,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFFDDD8D0)),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          size: 20, color: Color(0xFF4b986c)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Body ────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : _buildGuideList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF4b986c)),
          const SizedBox(height: 16),
          Text(
            'Generating your personalized guides...',
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: GestureDetector(
        onTap: _load,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Survey notice if no survey taken
          if (!_hasSurvey) _buildSurveyNotice(),

          const Text(
            'Recommended Guides for You',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 4),
          Text(
            _hasSurvey
                ? 'Based on your survey answers'
                : 'Take the survey for more personalized guides',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 16),

          ..._guides.map((guide) => _buildGuideCard(guide)),
        ],
      ),
    );
  }

  Widget _buildSurveyNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4b986c).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF4b986c).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Take the plant survey to get guides tailored specifically to your setup and experience.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4b986c),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(CareGuide guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEAE2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(18, 0, 18, 18),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4b986c).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(guide.icon,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          title: Text(
            guide.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              guide.summary,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8A8578),
                height: 1.4,
              ),
            ),
          ),
          children: [
            const Divider(color: Color(0xFFEEEAE2)),
            const SizedBox(height: 10),
            ...guide.tips.map((tip) => _buildTip(tip)),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4b986c),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF3A3A3A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}