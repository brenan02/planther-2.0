import 'package:flutter/material.dart';
import 'package:planther/services/auth_service.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _passwordTouched = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // ── password rules ─────────────────────────────────────────────────────
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase =>
      _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase =>
      _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber =>
      _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _passwordController.text.contains(RegExp(r'[!@#&]'));
  bool get _passwordValid =>
      _hasMinLength && _hasUppercase && _hasLowercase &&
      _hasNumber && _hasSpecial;

  // ── email validation ───────────────────────────────────────────────────
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email.trim());
  }

  // ── username validation ────────────────────────────────────────────────
  bool _isValidUsername(String username) {
    // 3-20 chars, letters/numbers/underscores only
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username.trim());
  }

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

    _passwordController.addListener(() {
      setState(() {
        if (_passwordController.text.isNotEmpty) {
          _passwordTouched = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleSignUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Empty check
    if (firstName.isEmpty || lastName.isEmpty || username.isEmpty ||
        email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    // Email format check
    if (!_isValidEmail(email)) {
      _showMessage(
          'Please enter a valid email address (e.g. name@example.com)');
      return;
    }

    // Username format check
    if (!_isValidUsername(username)) {
      _showMessage(
          'Username must be 3–20 characters, letters, numbers, or underscores only');
      return;
    }

    // Password check
    if (!_passwordValid) {
      setState(() => _passwordTouched = true);
      _showMessage('Password does not meet the requirements');
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.signUp(
      email: email,
      password: password,
      username: username,
      firstName: firstName,
      lastName: lastName,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (error != null) {
      _showMessage(error);
    } else {
      _showMessage(
        'Account created! Please check your email to verify, then log in.',
        isError: false,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
          email: email,
          ),
        ),
      );
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
                            color: const Color(0xFFDDD8D0), width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: Color(0xFF1A1A1A)),
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join Planther and find your perfect plants',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8A8578),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // First name + Last name side by side
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                          ),
                          textInputAction: TextInputAction.next,
                          textCapitalization:
                              TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last name',
                          ),
                          textInputAction: TextInputAction.next,
                          textCapitalization:
                              TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Username
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.alternate_email,
                          color: Color(0xFF8A8578), size: 20),
                      helperText:
                          '3–20 characters, letters, numbers, underscores',
                    ),
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 14),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: Color(0xFF8A8578), size: 20),
                    ),
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 14),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: Color(0xFF8A8578), size: 20),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() =>
                            _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF8A8578),
                          size: 20,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleSignUp(),
                  ),

                  // Password rules
                  if (_passwordTouched) ...[
                    const SizedBox(height: 14),
                    _buildRulesCard(),
                  ],

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                  ),

                  const SizedBox(height: 40),

                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8A8578),
                        ),
                        children: [
                          const TextSpan(text: 'Already a user? '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const LoginScreen()),
                                );
                              },
                              child: const Text(
                                'Login',
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
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD8D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password must contain:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          _buildRule('At least 8 characters', _hasMinLength),
          _buildRule('1 uppercase letter (A–Z)', _hasUppercase),
          _buildRule('1 lowercase letter (a–z)', _hasLowercase),
          _buildRule('1 number (0–9)', _hasNumber),
          _buildRule('1 special character (!, @, #, &)', _hasSpecial),
        ],
      ),
    );
  }

  Widget _buildRule(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isMet ? Icons.check_circle : Icons.cancel,
              key: ValueKey(isMet),
              size: 16,
              color: isMet
                  ? const Color(0xFF2D6A4F)
                  : const Color(0xFFE57373),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isMet
                  ? const Color(0xFF2D6A4F)
                  : const Color(0xFF8A8578),
              fontWeight:
                  isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}