import 'package:flutter/material.dart';
import 'package:planther/services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    try {
      final profile = await AuthService().getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Mask name: keep first and last letter, replace middle with *
  String _maskName(String name) {
    if (name.isEmpty) return '';
    if (name.length == 1) return name;
    if (name.length == 2) return '${name[0]}*';
    final first = name[0];
    final last = name[name.length - 1];
    final stars = '*' * (name.length - 2);
    return '$first$stars$last';
  }

  void _showInfoDialog({
  required String title,
  required String content,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF5C5850),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(
              color: Color(0xFF4b986c),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final username = _profile?['username'] ?? '';
    final firstName = _profile?['first_name'] ?? '';
    final lastName = _profile?['last_name'] ?? '';


    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4b986c),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Avatar + info card ─────────────────────────────
                    Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 16,
  ),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: const Color(0xFFEEEAE2),
    ),
  ),
  child: Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFFE8F3EC),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_outline,
          color: Color(0xFF4b986c),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username.isNotEmpty ? '@$username' : '@username',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (firstName.isNotEmpty || lastName.isNotEmpty)
                  ? '${_maskName(firstName)} ${_maskName(lastName)}'
                  : '•••••• ••••••',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8A8578),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),

                    //const SizedBox(height: 32),

                    //_sectionLabel('Account'),
                    //const SizedBox(height: 12),
              
                    
            
                    const SizedBox(height: 32),

                    _sectionLabel('About'),
                    const SizedBox(height: 12),
                    _buildTile(
  icon: Icons.info_outline,
  label: 'About Planther',
  onTap: () {
    _showInfoDialog(
      title: 'About Planther',
      content: '''
Planther is a mobile application designed to help users discover and care for plants through personalized recommendations and educational resources.

Key Features

• Personalized plant recommendations based on user preferences

• Digital garden management

• AI-assisted plant suggestions

• Personalized care guides

• Plant information database

Planther aims to make plant care more accessible for beginners while still providing useful information for experienced plant enthusiasts.

This is placeholder text. Replace it with your final About Planther content before deployment.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
''',
    );
  },
),


                    _buildTile(
  icon: Icons.privacy_tip_outlined,
  label: 'Privacy Policy',
  onTap: () {
    _showInfoDialog(
      title: 'Privacy Policy',
      content: '''
Privacy Policy

Planther respects your privacy and is committed to protecting your personal information.

Information We Collect

• Username

• First name

• Last name

• Email address

• Plant collection information

How We Use Information

• To provide plant recommendations

• To save your account data

• To maintain your digital garden

• To improve application functionality

Data Storage

Your information is stored securely using cloud services and authentication systems.

Data Sharing

Planther does not sell personal information to third parties.

User Rights

Users may modify or remove their information according to the application's available account features.

This is placeholder text and should be replaced with your official privacy policy before publication.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
''',
    );
  },
),

                    const SizedBox(height: 32),

                    // ── Log out button ─────────────────────────────────
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Log out',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to log out?',
                              style: TextStyle(
                                color: Color(0xFF8A8578),
                                fontSize: 14,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                      color: Color(0xFF8A8578)),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(true),
                                child: const Text(
                                  'Log out',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await AuthService().signOut();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.logout_rounded,
                                color: Colors.redAccent, size: 20),
                            SizedBox(width: 14),
                            Text(
                              'Log out',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        'Planther v2.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8A8578),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEAE2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF5C5850)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 13, color: Color(0xFF8A8578)),
          ],
        ),
      ),
    );
  }
}