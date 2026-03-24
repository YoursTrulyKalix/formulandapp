// ============================================================
// new_conversation_screen.dart
// Ito ang screen na ginagamit para maghanap ng ibang users
// at magsimula ng bagong conversation / chat sa kanila.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/models/user_model.dart';
import 'package:formulandsocialapp/core/services/message_service.dart';
import 'package:formulandsocialapp/features/messages/chat_screen.dart';

// ── StatefulWidget kasi may state tayo na nagbabago:
//    search results, loading state, at kung sino ang nino-open na chat
class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  // Controller para sa search text field — siya ang nag-aalalay ng
  // text na nita-type ng user sa search bar
  final _searchCtrl = TextEditingController();

  // Instance ng Firestore — dito tayo mag-query ng users
  final _db = FirebaseFirestore.instance;

  // Kunin agad ang UID ng kasalukuyang naka-login na user
  // para hindi niya makita ang sarili niya sa search results
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // Listahan ng mga users na lumabas sa search
  List<UserModel> _results = [];

  // True kapag nag-aantay tayo ng Firestore response
  bool _loading = false;

  // True kapag nag-search na ang user kahit wala pang results
  // — ginagamit para ipakita ang "walang result" na message
  bool _hasSearched = false;

  // Sinisimbolo nito kung sinong user ang kasalukuyang nino-open ng chat.
  // Ginagamit para ipakita ang loading spinner sa tamang tile
  // habang nag-aantay ng conversation ID mula sa Firestore.
  String? _openingConvoFor;

  // ── dispose: linisin ang controller kapag nawala na ang screen
  //    para hindi mag-leak ng memory
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── _search: ang pangunahing function na nag-hahanap ng users sa Firestore
  //    Tinatawag ito tuwing nagbabago ang text sa search bar (onChanged)
  Future<void> _search(String query) async {
    // I-trim at i-lowercase para consistent ang paghahanap
    final q = query.trim().toLowerCase();

    // Kapag walang laman ang search, i-clear ang results at huwag magpakita ng "no results"
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    // Ipakita ang loading spinner at i-mark na nag-search na tayo
    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      // ── Query #1: Hanapin ang users gamit ang "usernameLower" field
      //    Gumagamit tayo ng prefix range query sa Firestore:
      //    isGreaterThanOrEqualTo: q  → lahat ng nagsisimula sa q
      //    isLessThan: q + 'z'        → hanggang sa katulad na prefix lang
      //    Kailangan ng Firestore index para dito — auto-created kapag na-deploy
      final byName = await _db
          .collection('users')
          .where('usernameLower', isGreaterThanOrEqualTo: q)
          .where('usernameLower', isLessThan: '${q}z')
          .limit(10)
          .get();

      // ── Query #2: Hanapin rin gamit ang handle (e.g. "@alexhamilton")
      //    Kung hindi nag-type ng "@", idagdag natin para tumugma sa handle format
      final handleQ = q.startsWith('@') ? q : '@$q';
      final byHandle = await _db
          .collection('users')
          .where('handle', isGreaterThanOrEqualTo: handleQ)
          .where('handle', isLessThan: '${handleQ}z')
          .limit(10)
          .get();

      // ── I-merge ang dalawang results at alisin ang mga duplicate
      //    at ang sariling account ng current user
      final seen = <String>{}; // Set para mabilis na malaman kung nakita na
      final merged = <UserModel>[];

      for (final doc in [...byName.docs, ...byHandle.docs]) {
        // Laktawan kung: nakita na natin ito (duplicate) o sarili nating account
        if (seen.contains(doc.id) || doc.id == _uid) continue;
        seen.add(doc.id);
        merged.add(UserModel.fromFirestore(doc));
      }

      // ── Fallback: kapag walang lumabas (baka wala pang Firestore index),
      //    i-load ang first 50 users at i-filter na sa client-side
      //    Hindi ito ideal sa malaking app pero okay para sa development
      if (merged.isEmpty) {
        final all = await _db.collection('users').limit(50).get();
        for (final doc in all.docs) {
          if (doc.id == _uid) continue; // Huwag isali ang sarili
          final u = UserModel.fromFirestore(doc);
          // I-check kung naglalaman ang username o handle ng search query
          if (u.username.toLowerCase().contains(q) ||
              u.handle.toLowerCase().contains(q)) {
            merged.add(u);
          }
        }
      }

      // I-update ang UI gamit ang mga nahanap na users
      // Suriin muna kung mounted — baka nawala na ang screen habang nag-await
      if (mounted) setState(() => _results = merged);
    } catch (e) {
      // Kapag may error sa Firestore query, ipakita ang snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: AppStyles.accentRed,
          ),
        );
      }
    } finally {
      // Palaging i-off ang loading spinner, kahit may error man o wala
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── _openChat: kapag nag-tap ang user sa isang result tile,
  //    kukunin (o lilikha) ng conversation sa Firestore at pupunta sa ChatScreen
  Future<void> _openChat(UserModel user) async {
    // Itago ang UID ng user na nino-open para makita ng tile
    // na kailangan nitong magpakita ng loading spinner
    setState(() => _openingConvoFor = user.uid);

    try {
      // Tanungin ang MessageService: mayroon na bang conversation
      // ng current user at itong user? Kung wala, lilikha ng bago.
      final convoId =
      await MessageService.instance.getOrCreateConversation(user.uid);

      // Bago mag-navigate, suriin kung mounted pa rin ang widget
      if (!mounted) return;

      // Palitan ang current screen ng ChatScreen (hindi na babalik dito
      // gamit ang back button — mas natural ang flow)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convoId,
            otherUserName: user.username,
            otherUserHandle: user.handle,
          ),
        ),
      );
    } catch (e) {
      // Kung may nangyaring mali (e.g. walang internet), ipakita ang error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open conversation. Try again.'),
            backgroundColor: AppStyles.accentRed,
          ),
        );
      }
    } finally {
      // I-clear ang loading state ng tile kahit anong mangyari
      if (mounted) setState(() => _openingConvoFor = null);
    }
  }

  // ── build: ang pangunahing layout ng screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: SafeArea(
        // SafeArea para hindi matakpan ng notch o status bar ang content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context), // Back button + title
            _buildSearchBar(), // Text field para sa paghahanap
            const SizedBox(height: 8),
            Expanded(child: _buildBody()), // Results / empty state / loader
          ],
        ),
      ),
    );
  }

  // ── _buildHeader: ang itaas na bahagi ng screen
  //    Naglalaman ng back button at ng title na "Find a fan"
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
      child: Row(
        children: [
          // Back button — kapag na-tap, babalik sa MessagesScreen
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppStyles.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppStyles.borderColor),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppStyles.textSub,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Label at heading
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("NEW MESSAGE", style: AppStyles.label),
              const SizedBox(height: 2),
              Text(
                "Find a fan",
                style: AppStyles.headingXL.copyWith(fontSize: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── _buildSearchBar: ang text field na ginagamit para mag-type ng pangalan
  //    o handle ng gusto nilang kausapin
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyles.borderColor),
        ),
        child: TextField(
          controller: _searchCtrl,
          autofocus: true, // Awtomatikong magbubukas ng keyboard pagpasok
          style: const TextStyle(color: AppStyles.textMain, fontSize: 14),
          // Tawagan ang _search() tuwing nagbabago ang text
          onChanged: (v) => _search(v),
          decoration: InputDecoration(
            hintText: "Search by name or @handle...",
            hintStyle:
            const TextStyle(color: AppStyles.textMuted, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search,
              color: AppStyles.textMuted,
              size: 18,
            ),
            // Ipakita ang X button para i-clear ang search — kapag may laman ang field
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                _search(''); // I-trigger ang search ng empty string para ma-reset
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppStyles.textMuted,
                size: 16,
              ),
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── _buildBody: nagde-decide kung anong ipapakita sa gitna ng screen
  //    batay sa current state (loading, walang search pa, walang result, may result)
  Widget _buildBody() {
    // State 1: Nag-aantay ng Firestore response — ipakita ang spinner
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppStyles.accentRed,
          strokeWidth: 2,
        ),
      );
    }

    // State 2: Hindi pa nag-search ang user — ipakita ang placeholder icon
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppStyles.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppStyles.borderColor),
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: AppStyles.textMuted,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Search for fans to\nstart a conversation",
              style: AppStyles.bodyText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // State 3: Nag-search na pero walang nahanap
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: AppStyles.textMuted,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              // Ipakita ang exact na na-search para mas helpful ang message
              'No fans found for "${_searchCtrl.text.trim()}"',
              style: AppStyles.bodyText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // State 4: May results — ipakita ang listahan ng mga user cards
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _results.length,
      itemBuilder: (context, i) => _UserTile(
        user: _results[i],
        // Suriin kung ito ang user na kasalukuyang nino-open ng chat
        // para malaman kung saan ilalagay ang loading spinner
        isOpening: _openingConvoFor == _results[i].uid,
        onTap: () => _openChat(_results[i]),
      ),
    );
  }
}

// ── _UserTile ──────────────────────────────────────────────────────────────────
// Isang card para sa bawat user na lumabas sa search results.
// Ipinapakita ang avatar, pangalan, handle, at paboritong team.
// Kapag na-tap, magbubukas ng chat sa user na iyon.

class _UserTile extends StatelessWidget {
  final UserModel user;
  final bool isOpening; // True kung naka-loading state ang tile na ito
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.isOpening,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Kuhanin ang unang letra ng username para sa initials avatar
    // Fallback sa '?' kapag walang username
    final initial =
    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';

    return GestureDetector(
      // Huwag payagan ang tap habang may ongoing na pagbubukas ng conversation
      onTap: isOpening ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppStyles.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyles.borderColor),
        ),
        child: Row(
          children: [
            // ── Avatar section ──────────────────────────────────────────
            // Ipakita ang profile picture kung mayroon; kung wala, initials lang
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppStyles.softGrey,
              ),
              child: user.avatarUrl.isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  user.avatarUrl,
                  fit: BoxFit.cover,
                  // Kapag hindi ma-load ang image (e.g. broken URL),
                  // ibalik sa initials avatar
                  errorBuilder: (_, __, ___) => _Initials(initial),
                ),
              )
                  : _Initials(initial), // Walang avatar URL — initials na lang
            ),
            const SizedBox(width: 14),

            // ── User info section ───────────────────────────────────────
            // Pangalan, handle, at paboritong F1 team ng user
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display name ng user
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: AppStyles.textMain,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Handle (e.g. "@strategy_fan_44")
                  Text(
                    user.handle,
                    style: const TextStyle(
                      color: AppStyles.textSub,
                      fontSize: 12,
                    ),
                  ),
                  // Ipakita ang paboritong team kung may nakasave
                  if (user.favouriteTeam.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          color: AppStyles.accentRed,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.favouriteTeam,
                          style: const TextStyle(
                            color: AppStyles.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Action section (kanan) ──────────────────────────────────
            // Kapag nag-oopen ng chat: spinner
            // Kapag hindi: send button
            if (isOpening)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppStyles.accentRed,
                  strokeWidth: 2,
                ),
              )
            else
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppStyles.accentRed, Color(0xFFAA0400)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── _Initials ─────────────────────────────────────────────────────────────────
// Simpleng widget na nagpapakita ng unang letra ng username
// bilang placeholder kapag walang profile picture ang user.

class _Initials extends StatelessWidget {
  final String initial; // Ang unang letra na ipapakita
  const _Initials(this.initial);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: AppStyles.textMain,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
    );
  }
}