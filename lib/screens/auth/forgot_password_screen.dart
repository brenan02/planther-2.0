import 'package:flutter/material.dart';
import 'package:planther/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.redAccent : const Color(0xFF2D6A4F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleSendReset() async {
    if (_emailController.text.trim().isEmpty) {
      _showMessage('Please enter your email address');
      return;
    }

    // Basic email format check
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showMessage('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    final error =
        await _authService.resetPassword(_emailController.text.trim());

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      _showMessage(error);
    } else {
      // Show success state instead of navigating away
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFDDD8D0),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Show different content based on whether email was sent
                  if (!_emailSent) ...[
                    _buildInputState(),
                  ] else ...[
                    _buildSuccessState(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── before sending ────────────────────────────────────────────────────────
  Widget _buildInputState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.lock_reset_rounded,
              color: Color(0xFF2D6A4F),
              size: 28,
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Forgot password?',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'No worries — enter your email and we\'ll send you a reset link.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF8A8578),
            height: 1.5,
          ),
        ),

        const SizedBox(height: 40),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: Color(0xFF8A8578),
              size: 20,
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSendReset(),
        ),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: _isLoading ? null : _handleSendReset,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Send Reset Link'),
        ),
      ],
    );
  }

  // ── after sending ─────────────────────────────────────────────────────────
  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Success icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.mark_email_read_outlined,
                color: Color(0xFF2D6A4F),
                size: 38,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        const Center(
          child: Text(
            'Check your email',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Center(
          child: Text(
            'We sent a password reset link to\n${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF8A8578),
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: Text(
            'Check your spam folder if you don\'t see it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Resend option
        ElevatedButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _emailController.clear();
            });
          },
          child: const Text('Try a different email'),
        ),

        const SizedBox(height: 16),

        // Back to login
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF2D6A4F),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF2D6A4F),
              ),
            ),
          ),
        ),
      ],
    );
  }
}