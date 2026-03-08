import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/models/message_model.dart';
import 'package:formulandsocialapp/core/services/message_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserHandle;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserHandle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await MessageService.instance.sendMessage(widget.conversationId, text);
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(child: _buildMessagesList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppStyles.borderColor)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppStyles.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppStyles.borderColor),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppStyles.textSub, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppStyles.softGrey),
            child: Center(
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w800, fontSize: 14)),
                Text(widget.otherUserHandle, style: const TextStyle(color: AppStyles.textSub, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.more_horiz, color: AppStyles.textSub),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<MessageModel>>(
      stream: MessageService.instance.getMessages(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppStyles.accentRed, strokeWidth: 2));
        }
        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: AppStyles.textMuted, size: 36),
                const SizedBox(height: 12),
                Text("Say something to ${widget.otherUserName}", style: AppStyles.bodyText),
              ],
            ),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, i) => _MessageBubble(
            message: messages[i],
            isMe: messages[i].senderId == _uid,
            showTime: i == messages.length - 1 ||
                messages[i + 1].senderId != messages[i].senderId,
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppStyles.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppStyles.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppStyles.borderColor),
              ),
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(color: AppStyles.textMain, fontSize: 14),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: "Message...",
                  hintStyle: TextStyle(color: AppStyles.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppStyles.accentRed, Color(0xFFAA0400)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppStyles.accentRed.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: _sending
                  ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showTime;

  const _MessageBubble({required this.message, required this.isMe, required this.showTime});

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppStyles.accentRed : AppStyles.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe ? null : Border.all(color: AppStyles.borderColor),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : AppStyles.textMain,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                _formatTime(message.createdAt),
                style: const TextStyle(color: AppStyles.textMuted, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}