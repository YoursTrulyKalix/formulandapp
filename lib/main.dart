import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Kinukuha ang bilang ng unread conversations para sa badge sa Messages tab.
  // Gumagamit ng StreamBuilder para real-time — awtomatikong mag-a-update
  // kapag may bagong mensahe na dumating kahit nasa ibang tab ka.
  Stream<int> get _unreadCountStream {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .map((snap) {
      // Bilangin kung ilan ang conversations na:
      // 1. Hindi ikaw ang nagpadala ng last message
      // 2. May laman ang last message (hindi empty)
      return snap.docs.where((doc) {
        final data = doc.data();
        final lastSenderId = data['lastSenderId'] ?? '';
        final lastMessage = data['lastMessage'] ?? '';
        return lastSenderId != uid && lastMessage.isNotEmpty;
      }).length;
    });
  }

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
            // StreamBuilder para ma-listen sa unread count in real-time
            // — kapag may bagong mensahe, mag-a-update agad ang badge
            child: StreamBuilder<int>(
              stream: _unreadCountStream,
              builder: (context, snapshot) {
                // Ang bilang ng unread — 0 kung walang data pa
                final unreadCount = snapshot.data ?? 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (i) {
                    final icons = [
                      Icons.auto_awesome_mosaic_rounded,
                      Icons.grid_view_rounded,
                      Icons.chat_bubble_rounded,
                      Icons.person_rounded,
                    ];
                    final isSelected = _idx == i;

                    // Ang Messages tab ay index 2 — doon lang natin
                    // ilalagay ang unread badge
                    final isMessagesTab = i == 2;
                    final showBadge = isMessagesTab && unreadCount > 0;

                    return GestureDetector(
                      onTap: () => setState(() => _idx = i),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 64,
                        height: 68,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Stack para malagyan ng badge ang icon
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppStyles.accentRed.withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    icons[i],
                                    color: isSelected
                                        ? AppStyles.accentRed
                                        : AppStyles.textMuted,
                                    size: 22,
                                  ),
                                ),
                                // Red badge na nagpapakita ng bilang ng unread messages
                                // Ipinapakita lang kapag may unread at nasa Messages tab
                                if (showBadge)
                                  Positioned(
                                    top: 2,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppStyles.accentRed,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppStyles.surface,
                                          width: 1.2,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 14,
                                      ),
                                      child: Text(
                                        // Kapag higit sa 9, ipakita "9+" para hindi masyadong malaki
                                        unreadCount > 9
                                            ? '9+'
                                            : '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // Dot indicator sa ibaba kapag selected ang tab
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}