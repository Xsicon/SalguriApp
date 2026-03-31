import 'package:flutter/material.dart';
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
    setState(() => _isSending = true);
    try {
      final conversation = await ApiService.getOrCreateConversation(
        otherUserId: p.agent?.userId ?? p.id,
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
            fontSize: 16,
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
                  const SizedBox(height: 24),
                  _buildSendButton(),
                  const SizedBox(height: 24),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Text('No agent assigned', style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  agent.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.name,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agent.role.isNotEmpty ? agent.role : 'Salguri Properties',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 3),
                      Text(
                        agent.rating.toString(),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${agent.deals} deals)',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (agent.phone != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, color: cs.onSurfaceVariant, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          agent.phone!,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone, color: AppColors.white, size: 20),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MANAGED PROPERTIES',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: managedProperties.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
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
      width: 220,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
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
            height: 100,
            width: double.infinity,
            child: Image.network(
              property.images.isNotEmpty ? property.images.first : '',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: cs.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.home_outlined, color: cs.outline, size: 32),
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
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.location,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  property.price,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View Listing',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Message',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Write your message here...',
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.all(14),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK QUESTIONS',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Text(
                    question,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSending ? null : _onSendMessage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
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
        0,
        10,
        0,
        MediaQuery.of(context).padding.bottom + 8,
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
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  items[index].label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : cs.onSurfaceVariant,
                    fontSize: 11,
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
