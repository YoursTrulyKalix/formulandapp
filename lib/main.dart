import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/features/auth/login_screen.dart';
import 'package:formulandsocialapp/features/feed/feed_screen.dart';
import 'package:formulandsocialapp/features/creations/creations_screen.dart';
import 'package:formulandsocialapp/features/messages/messages_screen.dart';
import 'package:formulandsocialapp/features/profile/profile_screen.dart';
import 'package:formulandsocialapp/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0A),
  ));
  runApp(const F1App());
}

class F1App extends StatelessWidget {
  const F1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppStyles.background,
        colorScheme: const ColorScheme.dark(
          primary: AppStyles.accentRed,
          surface: AppStyles.surface,
          background: AppStyles.background,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppStyles.textMain),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Listens to FirebaseAuth state. Routes to MainNavigation or LoginScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigation();
        }
        return const LoginScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppStyles.accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppStyles.accentRed.withOpacity(0.3)),
              ),
              child: const Icon(Icons.speed_rounded, color: AppStyles.accentRed, size: 32),
            ),
            const SizedBox(height: 20),
            Text("FORMULAND", style: AppStyles.label.copyWith(fontSize: 13)),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppStyles.accentRed.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main Navigation ──────────────────────────────────────────────────────────

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 0;
  final _screens = [
    const FeedScreen(),
    const CreationsScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      extendBody: true,
      body: _screens[_idx],
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 68,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppStyles.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: AppStyles.borderColor, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) {
                final icons = [
                  Icons.auto_awesome_mosaic_rounded,
                  Icons.grid_view_rounded,
                  Icons.chat_bubble_rounded,
                  Icons.person_rounded,
                ];
                final isSelected = _idx == i;
                return GestureDetector(
                  onTap: () => setState(() => _idx = i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 64,
                    height: 68,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppStyles.accentRed.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            icons[i],
                            color: isSelected ? AppStyles.accentRed : AppStyles.textMuted,
                            size: 22,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: const BoxDecoration(
                              color: AppStyles.accentRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}