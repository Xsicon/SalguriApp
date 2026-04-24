import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<_FaqCategory> _faqCategories(AppLocalizations l) => [
        _FaqCategory(
          icon: Icons.home_work_outlined,
          title: l.tr('gettingStarted'),
          faqs: [
            _FaqItem(
              question: l.tr('howCreateAccount'),
              answer: l.tr('ansCreateAccount'),
            ),
            _FaqItem(
              question: l.tr('howSearchProperties'),
              answer: l.tr('ansSearchProperties'),
            ),
            _FaqItem(
              question: l.tr('isSalguriFree'),
              answer: l.tr('ansSalguriFree'),
            ),
          ],
        ),
        _FaqCategory(
          icon: Icons.apartment_outlined,
          title: l.tr('rentingLeasing'),
          faqs: [
            _FaqItem(
              question: l.tr('howPayRent'),
              answer: l.tr('ansPayRent'),
            ),
            _FaqItem(
              question: l.tr('howSubmitMaintenance'),
              answer: l.tr('ansSubmitMaintenance'),
            ),
            _FaqItem(
              question: l.tr('canRenewLease'),
              answer: l.tr('ansRenewLease'),
            ),
          ],
        ),
        _FaqCategory(
          icon: Icons.real_estate_agent_outlined,
          title: l.tr('listingProperty'),
          faqs: [
            _FaqItem(
              question: l.tr('howListProperty'),
              answer: l.tr('ansListProperty'),
            ),
            _FaqItem(
              question: l.tr('howLongToGoLive'),
              answer: l.tr('ansHowLongToGoLive'),
            ),
            _FaqItem(
              question: l.tr('canEditListing'),
              answer: l.tr('ansCanEditListing'),
            ),
          ],
        ),
        _FaqCategory(
          icon: Icons.payment_outlined,
          title: l.tr('paymentsBilling'),
          faqs: [
            _FaqItem(
              question: l.tr('whatPaymentMethods'),
              answer: l.tr('ansPaymentMethods'),
            ),
            _FaqItem(
              question: l.tr('howGetReceipt'),
              answer: l.tr('ansGetReceipt'),
            ),
          ],
        ),
        _FaqCategory(
          icon: Icons.security_outlined,
          title: l.tr('accountSecurity'),
          faqs: [
            _FaqItem(
              question: l.tr('howResetPassword'),
              answer: l.tr('ansResetPassword'),
            ),
            _FaqItem(
              question: l.tr('howDeleteAccount'),
              answer: l.tr('ansDeleteAccount'),
            ),
          ],
        ),
      ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqCategory> _filteredCategories(AppLocalizations l) {
    final categories = _faqCategories(l);
    if (_searchQuery.isEmpty) return categories;
    final q = _searchQuery.toLowerCase();
    final result = <_FaqCategory>[];
    for (final cat in categories) {
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
    final l = AppLocalizations.of(context);
    final filtered = _filteredCategories(l);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l.tr('helpCenter')),
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
                hintText: l.tr('searchForHelp'),
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
                ? _buildEmptyState(cs, l)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _buildCategorySection(filtered[i], cs),
                  ),
          ),

          // Contact support
          _buildContactSupport(cs, l),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 56, color: cs.outline),
          const SizedBox(height: 12),
          Text(
            l.tr('noResultsFound'),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.tr('tryDifferentSearch'),
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

  Widget _buildContactSupport(ColorScheme cs, AppLocalizations l) {
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
            l.tr('stillNeedHelp'),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.tr('supportTeamHere'),
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: Text(l.tr('emailUs')),
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
                  label: Text(l.tr('liveChat')),
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
