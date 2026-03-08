import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/services/auth_service.dart';
import 'package:formulandsocialapp/main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _handleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _teams = [
    'Red Bull Racing', 'Ferrari', 'Mercedes', 'McLaren',
    'Aston Martin', 'Alpine', 'Williams', 'RB', 'Haas', 'Kick Sauber',
  ];
  String? _selectedTeam;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _handleCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Basic validation
    if (_usernameCtrl.text.trim().isEmpty ||
        _handleCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await AuthService.instance.signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        handle: _handleCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'This email is already registered.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'weak-password': return 'Password is too weak. Use at least 6 characters.';
      default: return 'Registration failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: _RegisterBgPainter()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildBackButton(context),
                    const SizedBox(height: 32),
                    _buildHeading(),
                    const SizedBox(height: 36),
                    _buildSection("YOUR IDENTITY", [
                      _inputField(
                        controller: _usernameCtrl,
                        hint: "Full name",
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                      _inputField(
                        controller: _handleCtrl,
                        hint: "Handle  (e.g. strategy_fan_44)",
                        icon: Icons.alternate_email_rounded,
                        prefix: "@",
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection("YOUR TEAM", [_buildTeamSelector()]),
                    const SizedBox(height: 24),
                    _buildSection("ACCOUNT", [
                      _inputField(
                        controller: _emailCtrl,
                        hint: "Email address",
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _inputField(
                        controller: _passCtrl,
                        hint: "Password",
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePass,
                        suffixIcon: _toggleVisBtn(
                          _obscurePass,
                          () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _inputField(
                        controller: _confirmPassCtrl,
                        hint: "Confirm password",
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscureConfirm,
                        suffixIcon: _toggleVisBtn(
                          _obscureConfirm,
                          () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    if (_error != null) _buildError(),
                    const SizedBox(height: 28),
                    _buildRegisterButton(),
                    const SizedBox(height: 24),
                    _buildLoginLink(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppStyles.borderColor),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: AppStyles.textSub, size: 18),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Join the\nGrid.", style: AppStyles.headingXL.copyWith(fontSize: 44, height: 1.1)),
        const SizedBox(height: 12),
        const Text("Create your Formuland account.", style: AppStyles.bodyText),
      ],
    );
  }

  Widget _buildSection(String label, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.label),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.borderColor),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppStyles.textMain, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppStyles.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppStyles.textMuted, size: 18),
          prefixText: prefix,
          prefixStyle: const TextStyle(color: AppStyles.accentRed, fontWeight: FontWeight.w700, fontSize: 14),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _toggleVisBtn(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppStyles.textMuted,
        size: 18,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildTeamSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppStyles.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTeam,
          hint: const Text("Select your favourite team", style: TextStyle(color: AppStyles.textMuted, fontSize: 14)),
          dropdownColor: AppStyles.surfaceElevated,
          iconEnabledColor: AppStyles.textMuted,
          isExpanded: true,
          items: _teams.map((team) => DropdownMenuItem(
            value: team,
            child: Text(team, style: const TextStyle(color: AppStyles.textMain, fontSize: 14)),
          )).toList(),
          onChanged: (val) => setState(() => _selectedTeam = val),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppStyles.accentRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.accentRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppStyles.accentRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!, style: const TextStyle(color: AppStyles.accentRed, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _loading ? null : _register,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppStyles.accentRed, Color(0xFFAA0400)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppStyles.accentRed.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  "Start Your Season",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already on the grid? ", style: TextStyle(color: AppStyles.textSub, fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            "Sign In",
            style: TextStyle(color: AppStyles.accentRed, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _RegisterBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE10600).withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 120
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    final path = Path()
      ..moveTo(size.width, size.height * 0.05)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.15, 0, size.height * 0.35);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 28) {
      for (double y = 0; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}