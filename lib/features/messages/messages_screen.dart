// ============================================================
// messages_screen.dart
// Ito ang pangunahing screen para sa messages/conversations.
// Dito makikita ng user ang lahat ng kanyang mga chat,
// pwede ring mag-search ng conversation, at mag-compose
// ng bagong mensahe sa ibang user.
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/models/message_model.dart';
import 'package:formulandsocialapp/core/services/message_service.dart';
import 'package:formulandsocialapp/features/messages/chat_screen.dart';
import 'package:formulandsocialapp/features/messages/new_conversation_screen.dart';

// ── StatefulWidget na ngayon kasi kailangan nating i-track ang search query
//    na nita-type ng user sa search bar para ma-filter ang listahan ng convos
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Controller para sa search text field sa loob ng screen
  final _searchCtrl = TextEditingController();

  // Ang kasalukuyang search query na nita-type ng user (lowercase)
  // — ginagamit para i-filter ang listahan ng conversations
  String _query = '';

  // ── dispose: linisin ang controller kapag nawala na ang screen
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── build: ang pangunahing layout ng MessagesScreen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row: title sa kaliwa, compose button sa kanan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title section — "PITLANE" label at "Messages" heading
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("PITLANE", style: AppStyles.label),
                          const SizedBox(height: 4),
                          Text("Messages", style: AppStyles.headingXL),
                        ],
                      ),

                      // ── Compose button (pencil icon, top-right) ─────────
                      // Kapag na-tap, bubuksan ang NewConversationScreen
                      // para mahanap ang bagong kausap
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NewConversationScreen(),
                          ),
                        ),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppStyles.accentRed, Color(0xFFAA0400)],
                            ),
                            borderRadius: BorderRadius.circular(13),
                            // Maliit na shadow para magmukhang naka-float
                            boxShadow: [
                              BoxShadow(
                                color: AppStyles.accentRed.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search bar para i-filter ang existing conversations
                  _buildSearchBar(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Ang pangunahing listahan ng mga conversations — naka-Expanded
            // para mapuno ang natirang espasyo ng screen
            Expanded(child: _buildConversationsList()),
          ],
        ),
      ),
    );
  }

  // ── _buildSearchBar: functional na search bar
  //    Kapag nag-type ang user, nafi-filter agad ang listahan
  //    ng conversations sa ibaba — real-time, walang button na pindutin
  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppStyles.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyles.borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: AppStyles.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppStyles.textMain, fontSize: 14),
              // I-update ang _query tuwing nagbabago ang text
              // — dahil setState() ay tinatawag, mag-rere-render ang listahan
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: "Search conversations...",
                hintStyle: TextStyle(color: AppStyles.textMuted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          // X button — ipapakita lang kapag may laman ang search bar
          // Para madaling i-clear ng user ang kanyang search
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _query = ''); // I-reset ang filter
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.close_rounded,
                    color: AppStyles.textMuted, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  // ── _buildConversationsList: nag-li-listen sa real-time stream ng conversations
  //    Gumagamit ng StreamBuilder para awtomatikong mag-update ang UI
  //    kapag may bagong mensahe o bagong conversation ang dumating
  Widget _buildConversationsList() {
    return StreamBuilder<List<ConversationModel>>(
      // Ang stream na ito ay galing sa Firestore sa pamamagitan ng MessageService
      // — real-time ito, kaya kapag may nagpadala ng mensahe, mag-a-update agad
      stream: MessageService.instance.getConversations(),
      builder: (context, snapshot) {
        // Habang nag-aantay ng unang data mula sa Firestore, ipakita ang spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppStyles.accentRed,
              strokeWidth: 2,
            ),
          );
        }

        // Kunin ang lahat ng conversations (o empty list kung wala pa)
        final all = snapshot.data ?? [];

        // I-apply ang search filter:
        // Kung walang query, ipakita lahat; kung may query,
        // i-filter ang conversations na naglalaman ng pangalan,
        // handle, o last message na katulad ng na-type ng user
        final convos = _query.isEmpty
            ? all
            : all.where((c) {
          return c.otherUserName.toLowerCase().contains(_query) ||
              c.otherUserHandle.toLowerCase().contains(_query) ||
              c.lastMessage.toLowerCase().contains(_query);
        }).toList();

        // ── Empty state: Wala pang kahit isang conversation ang user
        //    Ipakita ang call-to-action para magsimula ng bagong chat
        if (all.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon placeholder
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppStyles.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppStyles.borderColor),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppStyles.textMuted,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "No conversations yet.",
                  style: TextStyle(
                    color: AppStyles.textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Tap the compose button to\nfind a fan and say hello.",
                  style: AppStyles.bodyText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Shortcut button para pumunta agad sa NewConversationScreen
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewConversationScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppStyles.accentRed, Color(0xFFAA0400)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      "Find a Fan",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ── No search match: May conversations pero walang tumugma sa filter
        if (convos.isEmpty && _query.isNotEmpty) {
          return Center(
            child: Text(
              'No matches for "$_query"',
              style: AppStyles.bodyText,
            ),
          );
        }

        // ── Normal state: ipakita ang listahan ng conversations
        //    Bawat item ay isang _ConvoTile widget
        return ListView.builder(
          // Bottom padding para hindi matakpan ng nav bar ang huling item
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          itemCount: convos.length,
          itemBuilder: (context, i) => _ConvoTile(convo: convos[i]),
        );
      },
    );
  }
}

// ── _ConvoTile ────────────────────────────────────────────────────────────────
// Ipinapakita ang isang conversation sa listahan.
// Naglalaman ng avatar ng kausap, pangalan, last message, at oras.
// May unread indicator (pulang dot + border) kapag hindi pa nababasa ang mensahe.

class _ConvoTile extends StatelessWidget {
  final ConversationModel convo;
  const _ConvoTile({required this.convo});

  // ── _timeLabel: ginagawa ang human-readable na label para sa oras
  //    ng pinakabagong mensahe sa conversation
  //    Halimbawa: "Now", "5m", "14:32", "Yesterday", "23/3"
  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';           // Halos ngayon lang
    if (diff.inHours < 1) return '${diff.inMinutes}m'; // Ilang minuto na ang nakaraan
    if (diff.inHours < 24) {
      // Ngayon pa lang, ipakita ang exact na oras (HH:MM)
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Yesterday';       // Kahapon
    return '${dt.day}/${dt.month}';                 // Mas matagal na — ipakita ang petsa
  }

  // ── _hasUnread: true kapag ang pinakabagong mensahe ay hindi galing
  //    sa current user (ibig sabihin, may bagong mensahe pa siyang hindi nabasa)
  bool get _hasUnread {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Hindi tayo ang nagpadala ng last message + may laman ang mensahe
    return convo.lastSenderId != uid && convo.lastMessage.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _hasUnread;
    // Fallback sa "Fan" kapag hindi pa na-load ang pangalan ng kausap
    final name = convo.otherUserName.isNotEmpty ? convo.otherUserName : 'Fan';
    // Unang letra ng pangalan — para sa initials avatar
    final initial = name[0].toUpperCase();

    return GestureDetector(
      // Kapag na-tap ang tile, pumunta sa ChatScreen ng conversation na ito
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convo.id,
            otherUserName: name,
            otherUserHandle: convo.otherUserHandle,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          // Kapag may unread, bigyan ng background highlight ang tile
          color: hasUnread ? AppStyles.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              // ── Avatar + unread dot ─────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Circular avatar na may initials
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyles.softGrey,
                      // Kapag may unread, maglagay ng pulang border sa avatar
                      border: hasUnread
                          ? Border.all(color: AppStyles.accentRed, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppStyles.textMain,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  // Pulang dot sa kanang sulok ng avatar — unread indicator
                  // Ipinapakita lang kapag may bagong mensahe
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppStyles.accentRed,
                          shape: BoxShape.circle,
                          // Border para magmukhang nakapatong sa avatar
                          border: Border.all(
                              color: AppStyles.background, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // ── Pangalan at preview ng last message ─────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        // Bold kapag may unread para mas halata
                        fontWeight:
                        hasUnread ? FontWeight.w800 : FontWeight.w600,
                        color: AppStyles.textMain,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      // Kapag walang laman ang last message, ipakita ang placeholder
                      convo.lastMessage.isEmpty
                          ? 'Start the conversation...'
                          : convo.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // ... kapag masyadong mahaba
                      style: TextStyle(
                        // Mas maliwanag ang kulay kapag may unread
                        color: hasUnread ? AppStyles.textSub : AppStyles.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── Timestamp (kanan ng tile) ───────────────────────────
              // Pulang kulay at bold kapag may unread — mas halata
              Text(
                _timeLabel(convo.lastMessageAt),
                style: TextStyle(
                  fontSize: 11,
                  color: hasUnread ? AppStyles.accentRed : AppStyles.textMuted,
                  fontWeight:
                  hasUnread ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}