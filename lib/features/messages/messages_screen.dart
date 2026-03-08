import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/models/message_model.dart';
import 'package:formulandsocialapp/core/services/message_service.dart';
import 'package:formulandsocialapp/features/messages/chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

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
                  Text("PITLANE", style: AppStyles.label),
                  const SizedBox(height: 4),
                  Text("Messages", style: AppStyles.headingXL),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildConversationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppStyles.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyles.borderColor),
      ),
      child: const Row(
        children: [
          SizedBox(width: 14),
          Icon(Icons.search, color: AppStyles.textMuted, size: 18),
          SizedBox(width: 10),
          Text("Search conversations...", style: TextStyle(color: AppStyles.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return StreamBuilder<List<ConversationModel>>(
      stream: MessageService.instance.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppStyles.accentRed, strokeWidth: 2));
        }

        final convos = snapshot.data ?? [];

        if (convos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: AppStyles.textMuted, size: 40),
                const SizedBox(height: 12),
                const Text("No conversations yet.\nFind a fan to connect with.", style: AppStyles.bodyText, textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          itemCount: convos.length,
          itemBuilder: (context, i) => _ConvoTile(convo: convos[i]),
        );
      },
    );
  }
}

// ── Conversation Tile ─────────────────────────────────────────────────────────

class _ConvoTile extends StatelessWidget {
  final ConversationModel convo;
  const _ConvoTile({required this.convo});

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }

  bool get _hasUnread {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return convo.lastSenderId != uid && convo.lastMessage.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _hasUnread;
    final name = convo.otherUserName.isNotEmpty ? convo.otherUserName : 'Fan';
    final initial = name[0].toUpperCase();

    return GestureDetector(
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
          color: hasUnread ? AppStyles.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyles.softGrey,
                      border: hasUnread ? Border.all(color: AppStyles.accentRed, width: 1.5) : null,
                    ),
                    child: Center(
                      child: Text(initial, style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: AppStyles.accentRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppStyles.background, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600, color: AppStyles.textMain, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      convo.lastMessage.isEmpty ? 'Start the conversation...' : convo.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: hasUnread ? AppStyles.textSub : AppStyles.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _timeLabel(convo.lastMessageAt),
                style: TextStyle(fontSize: 11, color: hasUnread ? AppStyles.accentRed : AppStyles.textMuted, fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}