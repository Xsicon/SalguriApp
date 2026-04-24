import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/chat_message.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String name;
  final String? avatarUrl;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.name,
    this.avatarUrl,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  RealtimeChannel? _realtimeChannel;

  String get _currentUserId => SupabaseService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    // Mark messages as read when opening the conversation
    ApiService.markMessagesAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_realtimeChannel != null) {
      SupabaseService.unsubscribeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ApiService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    _realtimeChannel = SupabaseService.subscribeToMessages(
      widget.conversationId,
      (message) {
        if (mounted) {
          setState(() => _messages.add(message));
          _scrollToBottom();
          // Mark as read if it's not our message
          if (!message.isMine(_currentUserId)) {
            ApiService.markMessagesAsRead(widget.conversationId);
          }
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      await ApiService.sendMessage(
        conversationId: widget.conversationId,
        content: text,
      );
      // The realtime subscription will add the message to the list
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.tr('failedToSendMessage'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  String? _dateDividerLabel(int index) {
    final msg = _messages[index];
    final msgDate = msg.createdAt.toLocal();
    final today = DateTime.now();

    if (index == 0) {
      return _dateLabel(msgDate, today);
    }

    final prevDate = _messages[index - 1].createdAt.toLocal();
    if (msgDate.year != prevDate.year ||
        msgDate.month != prevDate.month ||
        msgDate.day != prevDate.day) {
      return _dateLabel(msgDate, today);
    }
    return null;
  }

  String _dateLabel(DateTime date, DateTime today) {
    final l = AppLocalizations.of(context);
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return l.tr('todayLabel');
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return l.tr('yesterdayLabel');
    }
    return DateFormat('MMM d, yyyy').format(date).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(cs),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildMessageList(cs, l),
            ),
            _buildInputBar(cs, l),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back, color: cs.onSurface),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 20,
            backgroundImage:
                widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
            backgroundColor: cs.surfaceContainerHighest,
            child: widget.avatarUrl == null
                ? Icon(Icons.person, color: cs.outline, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ColorScheme cs, AppLocalizations l) {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          l.tr('noMessagesYet'),
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final dividerLabel = _dateDividerLabel(index);

        return Column(
          children: [
            if (dividerLabel != null) ...[
              if (index > 0) const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dividerLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: cs.outline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: msg.isMine(_currentUserId)
                  ? _buildSentBubble(msg, cs)
                  : _buildReceivedBubble(msg, cs),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceivedBubble(ChatMessage msg, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage:
              widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
          backgroundColor: cs.surfaceContainerHighest,
          child: widget.avatarUrl == null
              ? Icon(Icons.person, color: cs.outline, size: 16)
              : null,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.4),
                ),
              ),
              if (msg.imageUrl != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    msg.imageUrl!,
                    width: 192,
                    height: 128,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 192,
                      height: 128,
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.image, color: cs.outline, size: 32),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _formatTime(msg.createdAt),
                  style: TextStyle(fontSize: 10, color: cs.outline),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSentBubble(ChatMessage msg, ColorScheme cs) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: Text(
            msg.content,
            style: const TextStyle(fontSize: 14, color: AppColors.white, height: 1.4),
          ),
        ),
        if (msg.imageUrl != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  msg.imageUrl!,
                  width: 192,
                  height: 128,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 192,
                    height: 128,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.image, color: cs.outline, size: 32),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(fontSize: 10, color: cs.outline),
            ),
            if (msg.isRead) ...[
              const SizedBox(width: 4),
              const Icon(Icons.done_all, size: 14, color: AppColors.primary),
            ],
          ],
        ),
      ],
    ),
    );
  }

  Widget _buildInputBar(ColorScheme cs, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.05)),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.add_circle_outline, color: cs.outline),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: l.tr('typeMessage'),
                  hintStyle: TextStyle(color: cs.outline, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
              ),
            ),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isSending ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: AppColors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
