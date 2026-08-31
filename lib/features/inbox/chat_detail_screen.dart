import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/chat_message.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../../services/unread_badge_controller.dart';

class ChatDetailScreen extends StatefulWidget {
  /// Null when opening a brand-new chat that has no conversation yet — the
  /// row is only created (via [pendingOtherUserId]) once the first message
  /// is actually sent, so backing out beforehand leaves nothing behind.
  final String? conversationId;
  final String name;
  final String? avatarUrl;

  /// Required when [conversationId] is null — identifies who the first
  /// message should be sent to once the user actually sends one.
  final String? pendingOtherUserId;
  final String? pendingOtherRole;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.name,
    this.avatarUrl,
    this.pendingOtherUserId,
    this.pendingOtherRole,
  }) : assert(
          conversationId != null || pendingOtherUserId != null,
          'Either conversationId or pendingOtherUserId must be provided',
        );

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

  /// The real conversation id once one exists — either passed in, or filled
  /// in the moment the first message is sent.
  String? _conversationId;

  String get _currentUserId => SupabaseService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    final id = _conversationId;
    if (id != null) {
      _loadMessages(id);
      _subscribeToMessages(id);
      _markRead(id);
    } else {
      // Nothing to load yet — this is a pending, not-yet-created chat.
      _isLoading = false;
    }
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

  Future<void> _loadMessages(String conversationId) async {
    try {
      final msgs = await ApiService.getMessages(conversationId);
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

  void _subscribeToMessages(String conversationId) {
    _realtimeChannel = SupabaseService.subscribeToMessages(
      conversationId,
      (message) {
        if (mounted) {
          setState(() => _messages.add(message));
          _scrollToBottom();
          // Mark as read if it's not our message
          if (!message.isMine(_currentUserId)) {
            _markRead(conversationId);
          }
        }
      },
    );
  }

  /// Marking read doesn't touch the `conversations` table, so the inbox
  /// badge's realtime subscription (which only watches that table) would
  /// never learn about it — refresh it directly instead.
  Future<void> _markRead(String conversationId) async {
    await ApiService.markMessagesAsRead(conversationId);
    unawaited(UnreadBadgeController.instance.refresh());
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
      var id = _conversationId;
      if (id == null) {
        // First message in a brand-new chat — create the conversation now,
        // not before. If the user had backed out before this point, nothing
        // would ever have been created.
        final conv = await ApiService.getOrCreateConversation(
          otherUserId: widget.pendingOtherUserId!,
          otherDisplayName: widget.name,
          otherAvatarUrl: widget.avatarUrl,
          otherRole: widget.pendingOtherRole ?? 'user',
        );
        id = conv.id;
        _conversationId = id;
        _subscribeToMessages(id);
      }
      await ApiService.sendMessage(
        conversationId: id,
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
          SizedBox(width: 10.w),
          CircleAvatar(
            radius: 20.r,
            backgroundImage:
                widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
            backgroundColor: cs.surfaceContainerHighest,
            child: widget.avatarUrl == null
                ? Icon(Icons.person, color: cs.outline, size: 20.r)
                : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              widget.name,
              style: TextStyle(
                fontSize: 16.sp,
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
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15.sp),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.r),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final dividerLabel = _dateDividerLabel(index);

        return Column(
          children: [
            if (dividerLabel != null) ...[
              if (index > 0) SizedBox(height: 16.h),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    dividerLabel,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: cs.outline,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
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
          radius: 16.r,
          backgroundImage:
              widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
          backgroundColor: cs.surfaceContainerHighest,
          child: widget.avatarUrl == null
              ? Icon(Icons.person, color: cs.outline, size: 16.r)
              : null,
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: TextStyle(fontSize: 14.sp, color: cs.onSurface, height: 1.4),
                ),
              ),
              if (msg.imageUrl != null) ...[
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.network(
                    msg.imageUrl!,
                    width: 192.w,
                    height: 128.h,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 192.w,
                      height: 128.h,
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.image, color: cs.outline, size: 32.r),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.only(left: 4.w),
                child: Text(
                  _formatTime(msg.createdAt),
                  style: TextStyle(fontSize: 10.sp, color: cs.outline),
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
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(16.r),
            ),
          ),
          child: Text(
            msg.content,
            style: TextStyle(fontSize: 14.sp, color: AppColors.white, height: 1.4),
          ),
        ),
        if (msg.imageUrl != null) ...[
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.network(
                  msg.imageUrl!,
                  width: 192.w,
                  height: 128.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 192.w,
                    height: 128.h,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.image, color: cs.outline, size: 32.r),
                  ),
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: 4.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(fontSize: 10.sp, color: cs.outline),
            ),
            if (msg.isRead) ...[
              SizedBox(width: 4.w),
              Icon(Icons.done_all, size: 14.r, color: AppColors.primary),
            ],
          ],
        ),
      ],
    ),
    );
  }

  Widget _buildInputBar(ColorScheme cs, AppLocalizations l) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.05)),
        ),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 4.h),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24.r),
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
                  hintStyle: TextStyle(color: cs.outline, fontSize: 14.sp),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                  isDense: true,
                ),
                style: TextStyle(color: cs.onSurface, fontSize: 14.sp),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
              ),
            ),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: _isSending ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: _isSending
                    ? Padding(
                        padding: EdgeInsets.all(10.r),
                        child: const CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.send, color: AppColors.white, size: 20.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
