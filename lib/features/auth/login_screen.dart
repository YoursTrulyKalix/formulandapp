import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/services/auth_service.dart';
import 'package:formulandsocialapp/features/auth/register_screen.dart';
import 'package:formulandsocialapp/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.instance.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.instance.signInWithGoogle();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with that email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'invalid-email': return 'Please enter a valid email.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default: return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: Stack(
        children: [
          // Background stripes
          CustomPaint(size: Size.infinite, painter: _LoginBgPainter()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    _buildBadge(),
                    const SizedBox(height: 32),
                    _buildHeading(),
                    const SizedBox(height: 48),
                    _buildForm(),
                    const SizedBox(height: 16),
                    if (_error != null) _buildError(),
                    const SizedBox(height: 24),
                    _buildLoginButton(),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildGoogleButton(),
                    const SizedBox(height: 36),
                    _buildRegisterLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppStyles.accentRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppStyles.accentRed.withOpacity(0.3)),
      ),
      child: Text("FORMULAND", style: AppStyles.label),
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Welcome\nBack.", style: AppStyles.headingXL.copyWith(fontSize: 44, height: 1.1)),
        const SizedBox(height: 12),
        const Text("Sign in to your pit lane.", style: AppStyles.bodyText),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
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
          obscure: _obscure,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppStyles.textMuted,
              size: 18,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "Forgot password?",
            style: TextStyle(
              fontSize: 13,
              color: AppStyles.accentRed.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _loading ? null : _login,
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
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  "Enter the Paddock",
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppStyles.borderColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("or", style: TextStyle(color: AppStyles.textMuted, fontSize: 13)),
        ),
        Expanded(child: Divider(color: AppStyles.borderColor, thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _loading ? null : _googleLogin,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyles.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: const Center(
                child: Text("G", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Continue with Google",
              style: TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("New to Formuland? ", style: TextStyle(color: AppStyles.textSub, fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: const Text(
            "Join the Grid",
            style: TextStyle(
              color: AppStyles.accentRed,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE10600).withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 100
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final path = Path()
      ..moveTo(0, size.height * 0.08)
      ..quadraticBezierTo(size.width * 0.6, -20, size.width, size.height * 0.2);
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