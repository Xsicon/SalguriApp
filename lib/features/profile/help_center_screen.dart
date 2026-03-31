import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _faqCategories = [
    _FaqCategory(
      icon: Icons.home_work_outlined,
      title: 'Getting Started',
      faqs: [
        _FaqItem(
          question: 'How do I create an account?',
          answer:
              'To create an account, tap "Sign Up" on the login screen. You can register '
              'using your email address. Fill in your details, verify your email, and '
              'you\'re ready to explore properties on Salguri.',
        ),
        _FaqItem(
          question: 'How do I search for properties?',
          answer:
              'Use the search bar on the Home tab to find properties by location, type, '
              'or price range. You can also browse featured listings and use filters '
              'to narrow down results by bedrooms, bathrooms, and property type.',
        ),
        _FaqItem(
          question: 'Is Salguri free to use?',
          answer:
              'Salguri is free to download and browse listings. Property owners can list '
              'properties with a standard plan, and PRO members get access to premium '
              'features including priority listing and advanced analytics.',
        ),
      ],
    ),
    _FaqCategory(
      icon: Icons.apartment_outlined,
      title: 'Renting & Leasing',
      faqs: [
        _FaqItem(
          question: 'How do I pay rent through the app?',
          answer:
              'Navigate to the Rental tab, select your active lease, and tap "Pay Rent." '
              'You can pay using mobile money (EVC Plus, Zaad, Sahal) or bank transfer. '
              'You\'ll receive a confirmation once your payment is processed.',
        ),
        _FaqItem(
          question: 'How do I submit a maintenance request?',
          answer:
              'Go to your active rental, tap "Maintenance Request," describe the issue, '
              'attach photos if needed, and submit. Your landlord will be notified '
              'immediately and you can track the status in real time.',
        ),
        _FaqItem(
          question: 'Can I renew my lease through the app?',
          answer:
              'Yes. When your lease is approaching its end date, you\'ll receive a '
              'notification with renewal options. You can review and accept new terms '
              'directly within the app.',
        ),
      ],
    ),
    _FaqCategory(
      icon: Icons.real_estate_agent_outlined,
      title: 'Listing a Property',
      faqs: [
        _FaqItem(
          question: 'How do I list my property?',
          answer:
              'Tap the "+" button on the Home tab, fill in your property details '
              'including photos, location, pricing, and amenities. Review your listing '
              'and publish it. Your property will be visible to all Salguri users.',
        ),
        _FaqItem(
          question: 'How long does it take for my listing to go live?',
          answer:
              'Most listings are published instantly. In some cases, our team may '
              'review listings to ensure quality and accuracy, which can take up '
              'to 24 hours.',
        ),
        _FaqItem(
          question: 'Can I edit my listing after publishing?',
          answer:
              'Yes. Go to "My Properties" in your profile, select the listing you '
              'want to modify, and tap "Edit." Changes are saved immediately.',
        ),
      ],
    ),
    _FaqCategory(
      icon: Icons.payment_outlined,
      title: 'Payments & Billing',
      faqs: [
        _FaqItem(
          question: 'What payment methods are accepted?',
          answer:
              'Salguri supports EVC Plus, Zaad, Sahal (mobile money), and bank '
              'transfers. We are working on adding more payment options to serve '
              'you better.',
        ),
        _FaqItem(
          question: 'How do I get a receipt for my payment?',
          answer:
              'After each successful payment, a receipt is automatically generated '
              'and available in your transaction history. You can also download or '
              'share receipts directly from the app.',
        ),
      ],
    ),
    _FaqCategory(
      icon: Icons.security_outlined,
      title: 'Account & Security',
      faqs: [
        _FaqItem(
          question: 'How do I reset my password?',
          answer:
              'On the login screen, tap "Forgot Password" and enter your registered '
              'email. You\'ll receive a password reset link. Follow the instructions '
              'to create a new password.',
        ),
        _FaqItem(
          question: 'How do I delete my account?',
          answer:
              'Go to Profile > Personal Information > Delete Account. Please note '
              'that this action is permanent and all your data, listings, and '
              'transaction history will be removed.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _faqCategories;
    final q = _searchQuery.toLowerCase();
    final result = <_FaqCategory>[];
    for (final cat in _faqCategories) {
      final matched = cat.faqs
          .where((f) =>
              f.question.toLowerCase().contains(q) ||
              f.answer.toLowerCase().contains(q))
          .toList();
      if (matched.isNotEmpty) {
        result.add(_FaqCategory(
          icon: cat.icon,
          title: cat.title,
          faqs: matched,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredCategories;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Help Center'),
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search for help...',
                hintStyle: TextStyle(color: cs.outline, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: cs.outline, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: cs.outline, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(cs)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _buildCategorySection(filtered[i], cs),
                  ),
          ),

          // Contact support
          _buildContactSupport(cs),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 56, color: cs.outline),
          const SizedBox(height: 12),
          Text(
            'No results found',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search term',
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(_FaqCategory category, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(category.icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  category.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // FAQ items
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < category.faqs.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      color: cs.surfaceContainerHighest,
                    ),
                  _FaqTile(faq: category.faqs[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupport(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Still need help?',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Our support team is here to assist you',
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Email Us'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primarySoft),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('Live Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- FAQ Expandable Tile ----------

class _FaqTile extends StatefulWidget {
  final _FaqItem faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.faq.question,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _iconRotation,
                  child: Icon(
                    Icons.expand_more,
                    color: cs.outline,
                    size: 22,
                  ),
                ),
              ],
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  widget.faq.answer,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Data Models ----------

class _FaqCategory {
  final IconData icon;
  final String title;
  final List<_FaqItem> faqs;

  const _FaqCategory({
    required this.icon,
    required this.title,
    required this.faqs,
  });
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
