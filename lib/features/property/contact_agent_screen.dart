import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/property.dart';
import '../../services/api_service.dart';

class ContactAgentScreen extends StatefulWidget {
  final Property property;

  const ContactAgentScreen({super.key, required this.property});

  @override
  State<ContactAgentScreen> createState() => _ContactAgentScreenState();
}

class _ContactAgentScreenState extends State<ContactAgentScreen> {
  final TextEditingController _messageController = TextEditingController();
  int _selectedNavIndex = 3;
  bool _isSending = false;
  List<Property> _managedProperties = [];
  bool _isLoadingProperties = true;

  Property get p => widget.property;

  final List<String> _quickQuestions = const [
    'Is this still available?',
    'What are the monthly costs?',
    'Can I schedule a viewing?',
    'Are utilities included?',
    'Is parking available?',
  ];

  @override
  void initState() {
    super.initState();
    _loadManagedProperties();
  }

  Future<void> _loadManagedProperties() async {
    try {
      final all = await ApiService.getAllProperties();
      if (!mounted) return;
      setState(() {
        _managedProperties = p.agent != null
            ? all.where((prop) => prop.agent?.id == p.agent!.id).take(3).toList()
            : [p];
        if (_managedProperties.isEmpty) _managedProperties = [p];
        _isLoadingProperties = false;
      });
    } catch (e) {
      debugPrint('Error loading managed properties: $e');
      if (!mounted) return;
      setState(() {
        _managedProperties = [p];
        _isLoadingProperties = false;
      });
    }
  }

  Future<void> _onSendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final agentUserId = p.agent?.userId;
    if (agentUserId == null) {
      // No linked account to message — sending would silently create a
      // conversation with the property's id instead of a real recipient,
      // and nobody would ever see it. Fail loudly instead.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This listing has no messageable agent yet.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      final conversation = await ApiService.getOrCreateConversation(
        otherUserId: agentUserId,
        otherDisplayName: p.agent?.name ?? 'Agent',
        otherRole: 'agent',
      );
      await ApiService.sendMessage(
        conversationId: conversation.id,
        content: _messageController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully!')),
      );
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'CONTACT AGENT',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAgentCard(),
                  _buildManagedProperties(),
                  _buildMessageInput(),
                  _buildQuickQuestions(),
                  SizedBox(height: 24.h),
                  _buildSendButton(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  // ---------- Agent Card ----------

  Widget _buildAgentCard() {
    final cs = Theme.of(context).colorScheme;
    final agent = p.agent;
    if (agent == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0.h),
        child: Text('No agent assigned', style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0.h),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  agent.initials,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.name,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    agent.role.isNotEmpty ? agent.role : 'Salguri Properties',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.star, color: const Color(0xFFF59E0B), size: 14.r),
                      SizedBox(width: 3.w),
                      Text(
                        agent.rating.toString(),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '(${agent.deals} deals)',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  if (agent.phone != null) ...[
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, color: cs.onSurfaceVariant, size: 14.r),
                        SizedBox(width: 4.w),
                        Text(
                          agent.phone!,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Call button
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 42.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.phone, color: AppColors.white, size: 20.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Managed Properties ----------

  Widget _buildManagedProperties() {
    final cs = Theme.of(context).colorScheme;

    final managedProperties = _isLoadingProperties ? <Property>[p] : _managedProperties;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MANAGED PROPERTIES',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 180.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: managedProperties.length,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                return _buildPropertyCard(managedProperties[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 220.w,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image
          SizedBox(
            height: 100.h,
            width: double.infinity,
            child: Image.network(
              property.images.isNotEmpty ? property.images.first : '',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: cs.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.home_outlined, color: cs.outline, size: 32.r),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: cs.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
            ),
          ),
          // Property info
          Padding(
            padding: EdgeInsets.all(10.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.location,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  property.price,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'View Listing',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Message Input ----------

  Widget _buildMessageInput() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Message',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14.sp,
              ),
              decoration: InputDecoration(
                hintText: 'Write your message here...',
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 14.sp,
                ),
                contentPadding: EdgeInsets.all(14.r),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Quick Questions ----------

  Widget _buildQuickQuestions() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK QUESTIONS',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _quickQuestions.map((question) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_messageController.text.isNotEmpty) {
                      _messageController.text += '\n$question';
                    } else {
                      _messageController.text = question;
                    }
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _messageController.text.length),
                    );
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Text(
                    question,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------- Send Button ----------

  Widget _buildSendButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSending ? null : _onSendMessage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 16.h),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            textStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          child: _isSending
              ? SizedBox(
                  width: 22.w, height: 22.h,
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Text('SEND MESSAGE'),
        ),
      ),
    );
  }

  // ---------- Bottom Navigation Bar ----------

  Widget _buildBottomNavBar() {
    final cs = Theme.of(context).colorScheme;
    final items = <_NavItem>[
      _NavItem(icon: Icons.search, label: 'Search'),
      _NavItem(icon: Icons.favorite_border, label: 'Favorites'),
      _NavItem(icon: Icons.calendar_today_outlined, label: 'Calendar'),
      _NavItem(icon: Icons.chat_bubble_outline, label: 'Chat'),
      _NavItem(icon: Icons.more_horiz, label: 'More'),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        0.w,
        10.h,
        0.w,
        MediaQuery.of(context).padding.bottom + 8.h,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = index == _selectedNavIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedNavIndex = index);
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  items[index].icon,
                  color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
                  size: 24.r,
                ),
                SizedBox(height: 4.h),
                Text(
                  items[index].label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
                    fontSize: 11.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
