import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/conversation.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import 'chat_detail_screen.dart';

class InboxScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const InboxScreen({super.key, this.onBack});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  List<Conversation> _conversations = [];
  bool _isLoading = true;
  RealtimeChannel? _realtimeChannel;

  String get _currentUserId => SupabaseService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_realtimeChannel != null) {
      SupabaseService.unsubscribeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  String? _errorMessage;

  Future<void> _loadConversations() async {
    try {
      debugPrint('Loading conversations... userId=${SupabaseService.currentUser?.id}');
      final convs = await ApiService.getConversations();
      debugPrint('Loaded ${convs.length} conversations');
      if (mounted) {
        setState(() {
          _conversations = convs;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading conversations: $e\n$stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _subscribeToUpdates() {
    _realtimeChannel = SupabaseService.subscribeToConversations(() {
      _loadConversations();
    });
  }

  Future<void> _openNewChat() async {
    final users = await ApiService.getUsers();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserPickerSheet(
        users: users,
        onUserSelected: (user) async {
          Navigator.of(context).pop();
          // No conversation is created here — only when a message is
          // actually sent from the chat screen. Backing out before that
          // leaves nothing behind for either side.
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                conversationId: null,
                name: user['full_name'] as String? ?? 'User',
                avatarUrl: user['avatar_url'] as String?,
                pendingOtherUserId: user['id'] as String,
                pendingOtherRole: user['role'] as String? ?? 'user',
              ),
            ),
          );
          _loadConversations();
        },
      ),
    );
  }

  List<Conversation> get _filteredConversations {
    var list = _conversations;

    // Filter by role
    if (_selectedFilter != 'All') {
      final roleKey = _selectedFilter.toLowerCase();
      // 'Agents' -> 'agent', 'Landlords' -> 'landlord', 'Providers' -> 'provider'
      final role = roleKey.substring(0, roleKey.length - 1);
      list = list.where((c) {
        final other = c.otherParticipant(_currentUserId);
        return other?.role == role;
      }).toList();
    }

    // Filter by search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) {
        final other = c.otherParticipant(_currentUserId);
        final name = other?.displayName.toLowerCase() ?? '';
        final lastMsg = c.lastMessageText?.toLowerCase() ?? '';
        return name.contains(query) || lastMsg.contains(query);
      }).toList();
    }

    return list;
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    final l = AppLocalizations.of(context);

    if (diff.inMinutes < 1) return l.tr('justNow');
    if (diff.inMinutes < 60) return '${diff.inMinutes}${l.tr('mAgo')}';
    if (diff.inHours < 24) return '${diff.inHours}${l.tr('hAgo')}';
    if (diff.inDays == 1) return l.tr('yesterday');
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}/${dt.year}';
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
            _buildHeader(cs, l),
            _buildSearchBar(cs, l),
            _buildFilterChips(cs, l),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildConversationList(cs, l),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewChat,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit_square, color: AppColors.white),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Row(
        children: [
          if (widget.onBack != null)
            GestureDetector(
              onTap: widget.onBack,
              child: Icon(Icons.arrow_back, color: cs.onSurface),
            ),
          Expanded(
            child: Text(
              l.tr('messages'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
            ),
          ),
          Icon(Icons.more_vert, color: cs.onSurface),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs, AppLocalizations l) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: l.tr('searchConversations'),
          hintStyle: TextStyle(color: cs.outline, fontSize: 15.sp),
          prefixIcon: Icon(Icons.search, color: cs.outline, size: 22.r),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: cs.outline, size: 20.r),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(color: cs.onSurface, fontSize: 15.sp),
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme cs, AppLocalizations l) {
    final filters = [l.tr('all'), l.tr('agents'), l.tr('landlords'), l.tr('providers')];
    final filterKeys = ['All', 'Agents', 'Landlords', 'Providers'];
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final isSelected = filterKeys[index] == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filterKeys[index]),
            child: Container(
              height: 36.h,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20.r),
              ),
              alignment: Alignment.center,
              child: Text(
                filters[index],
                style: TextStyle(
                  color: isSelected ? AppColors.white : cs.onSurfaceVariant,
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationList(ColorScheme cs, AppLocalizations l) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.r, color: cs.error),
              SizedBox(height: 12.h),
              Text(l.tr('errorLoadingConversations'), style: TextStyle(color: cs.error, fontSize: 16.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Text(_errorMessage!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.sp), textAlign: TextAlign.center),
              SizedBox(height: 16.h),
              ElevatedButton(onPressed: () { setState(() => _isLoading = true); _loadConversations(); }, child: Text(l.tr('retry'))),
            ],
          ),
        ),
      );
    }
    final conversations = _filteredConversations;
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48.r, color: cs.outline),
            SizedBox(height: 12.h),
            Text(
              l.tr('noConversationsYet'),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              'User: ${SupabaseService.currentUser?.id ?? l.tr('notLoggedIn')}',
              style: TextStyle(color: cs.outline, fontSize: 11.sp),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 12.h),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          return _buildConversationTile(conversations[index], cs);
        },
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'agent':
        return Icons.real_estate_agent;
      case 'landlord':
        return Icons.home_work;
      case 'provider':
        return Icons.build;
      default:
        return Icons.person;
    }
  }

  Widget _buildConversationTile(Conversation conv, ColorScheme cs) {
    final other = conv.otherParticipant(_currentUserId);
    final hasUnread = conv.unreadCount > 0;

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: conv.id,
              name: other?.displayName ?? 'Unknown',
              avatarUrl: other?.avatarUrl,
            ),
          ),
        );
        // Refresh to update unread counts after returning
        _loadConversations();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: hasUnread
              ? const Border(left: BorderSide(color: AppColors.primary, width: 4))
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                if (other?.avatarUrl != null)
                  CircleAvatar(
                    radius: 28.r,
                    backgroundImage: NetworkImage(other!.avatarUrl!),
                    backgroundColor: cs.surfaceContainerHighest,
                  )
                else
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: cs.surfaceContainerHighest,
                    child: Icon(
                      _roleIcon(other?.role ?? 'user'),
                      color: cs.outline,
                      size: 24.r,
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          other?.displayName ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _formatTime(conv.lastMessageAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                          color: hasUnread ? AppColors.primary : cs.outline,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    conv.lastMessageText ?? '',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                      color: hasUnread ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // Badge or chevron
            if (hasUnread)
              Container(
                height: 22.h,
                constraints: BoxConstraints(minWidth: 22.w),
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${conv.unreadCount}',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right, color: cs.outlineVariant, size: 20.r),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User Picker Bottom Sheet
// ---------------------------------------------------------------------------

class _UserPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final void Function(Map<String, dynamic> user) onUserSelected;

  const _UserPickerSheet({
    required this.users,
    required this.onUserSelected,
  });

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return widget.users;
    return widget.users.where((user) {
      final name = (user['full_name'] as String? ?? '').toLowerCase();
      final role = (user['role'] as String? ?? '').toLowerCase();
      return name.contains(_query) || role.contains(_query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final visible = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            l.tr('newMessage'),
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          if (widget.users.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search people…',
                  prefixIcon: Icon(Icons.search, size: 20.r),
                  isDense: true,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          SizedBox(height: 12.h),
          Divider(height: 1.h, color: cs.outlineVariant),
          if (widget.users.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  l.tr('noOtherUsersFound'),
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else if (visible.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No matches for your search',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: visible.length,
                itemBuilder: (_, index) {
                  final user = visible[index];
                  final name = user['full_name'] as String? ?? 'User';
                  final role = user['role'] as String? ?? 'user';
                  final avatarUrl = user['avatar_url'] as String?;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24.r,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      backgroundColor: cs.surfaceContainerHighest,
                      child: avatarUrl == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      role.isEmpty
                          ? role
                          : role[0].toUpperCase() + role.substring(1),
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.sp),
                    ),
                    onTap: () => widget.onUserSelected(user),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
