import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/service_request.dart';
import '../../services/api_service.dart';
import '../inbox/chat_detail_screen.dart';

// ---------------------------------------------------------------------------
// Tracking step model
// ---------------------------------------------------------------------------

class _TrackingStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final String? time;

  const _TrackingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isCompleted = false,
    this.isActive = false,
    this.time,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ServiceTrackingScreen extends StatefulWidget {
  final ServiceRequest request;

  const ServiceTrackingScreen({super.key, required this.request});

  @override
  State<ServiceTrackingScreen> createState() => _ServiceTrackingScreenState();
}

class _ServiceTrackingScreenState extends State<ServiceTrackingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _progressController;

  Timer? _pollTimer;
  late ServiceRequest _request;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _request = widget.request;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Start polling the backend for real status updates
    _startPolling();
  }

  int get _currentStep {
    switch (_request.status) {
      case 'pending':
        return 0;
      case 'assigned':
        return 1;
      case 'in_progress':
        return 2;
      case 'arrived':
        return 3;
      case 'completed':
        return 4;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }

  void _startPolling() {
    // Poll every 10 seconds for status updates
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchLatestStatus();
    });
  }

  Future<void> _fetchLatestStatus() async {
    if (_isPolling || !mounted) return;
    _isPolling = true;
    try {
      final updated = await ApiService.getServiceRequestById(_request.id);
      if (!mounted) return;
      if (updated.status != _request.status ||
          updated.etaMinutes != _request.etaMinutes ||
          updated.statusMessage != _request.statusMessage) {
        setState(() {
          _request = updated;
        });
      }
      // Stop polling if terminal state
      if (updated.status == 'completed' || updated.status == 'cancelled') {
        _pollTimer?.cancel();
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    } finally {
      _isPolling = false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  List<_TrackingStep> _steps(AppLocalizations l) {
    final fmt = _formatTimeOfDay;
    return [
      _TrackingStep(
        title: l.tr('requestConfirmed'),
        subtitle: l.tr('requestReceived'),
        icon: Icons.check_circle_outline,
        isCompleted: _currentStep > 0,
        isActive: _currentStep == 0,
        time: fmt(TimeOfDay.fromDateTime(_request.createdAt.toLocal())),
      ),
      _TrackingStep(
        title: l.tr('providerAssigned'),
        subtitle: _request.hasAssignedAgent
            ? '${_request.assignedAgentName} ${l.tr('handlingRequest')}'
            : l.tr('handlingRequest'),
        icon: Icons.person_pin_outlined,
        isCompleted: _currentStep > 1,
        isActive: _currentStep == 1,
      ),
      _TrackingStep(
        title: l.tr('onTheWay'),
        subtitle: l.tr('headingToLocation'),
        icon: Icons.directions_car_outlined,
        isCompleted: _currentStep > 2,
        isActive: _currentStep == 2,
      ),
      _TrackingStep(
        title: l.tr('arrived'),
        subtitle: l.tr('arrivedAtProperty'),
        icon: Icons.location_on_outlined,
        isCompleted: _currentStep > 3,
        isActive: _currentStep == 3,
      ),
      _TrackingStep(
        title: l.tr('serviceCompleted'),
        subtitle: l.tr('jobFinished'),
        icon: Icons.verified_outlined,
        isCompleted: _currentStep > 4,
        isActive: _currentStep == 4,
      ),
    ];
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l.tr('trackService')),
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchLatestStatus,
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                children: [
                  _buildStatusHeader(cs, l),
                  SizedBox(height: 20.h),
                  _buildEtaCard(cs, l),
                  if (_request.hasAssignedAgent) ...[
                    SizedBox(height: 20.h),
                    _buildProviderCard(cs, l),
                  ],
                  SizedBox(height: 24.h),
                  _buildTrackingTimeline(cs, l),
                  SizedBox(height: 24.h),
                  _buildRequestDetails(cs, l),
                ],
              ),
            ),
          ),
          _buildBottomActions(cs, l),
        ],
      ),
    );
  }

  // ---------- Status Header ----------

  Widget _buildStatusHeader(ColorScheme cs, AppLocalizations l) {
    final steps = _steps(l);
    final stepIndex = _currentStep.clamp(0, steps.length - 1);
    final step = _request.status == 'cancelled'
        ? _TrackingStep(
            title: l.tr('cancelled'),
            subtitle: _request.statusMessage.isNotEmpty
                ? _request.statusMessage
                : 'Request cancelled',
            icon: Icons.cancel_outlined,
          )
        : steps[stepIndex];

    final isCancelled = _request.status == 'cancelled';

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCancelled
              ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          // Pulsing indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: _pulseAnimation.value * 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(step.icon, color: Colors.white, size: 20.r),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- ETA Card ----------

  Widget _buildEtaCard(ColorScheme cs, AppLocalizations l) {
    final steps = _steps(l);
    final progress = _currentStep < 0 ? 0.0 : _currentStep / (steps.length - 1);
    final eta = _request.etaMinutes;
    final isTerminal =
        _request.status == 'completed' || _request.status == 'cancelled';

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Icon(Icons.access_time_rounded,
                      color: AppColors.primary, size: 22.r),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.tr('estimatedArrival'),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _request.status == 'completed'
                          ? l.tr('serviceCompleted')
                          : _request.status == 'cancelled'
                              ? l.tr('cancelled')
                              : _request.status == 'arrived'
                                  ? l.tr('providerArrived')
                                  : eta != null
                                      ? '$eta ${l.tr('minRemaining')}'
                                      : l.tr('calculatingEta'),
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              // Live badge (only when actively tracking)
              if (!isTerminal)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) => Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.success
                          .withValues(alpha: 0.08 + _pulseAnimation.value * 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7.w,
                          height: 7.h,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success
                                    .withValues(alpha: _pulseAnimation.value * 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          l.tr('live'),
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l.tr('step')} ${(_currentStep + 1).clamp(1, steps.length)} ${l.tr('of')} ${steps.length}',
                style: TextStyle(color: cs.outline, fontSize: 12.sp),
              ),
              Text(
                '${(progress * 100).toInt()}${l.tr('percentComplete')}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Provider Actions ----------

  Future<void> _openChat() async {
    final agentUserId = _request.assignedAgentUserId;
    final agentName = _request.assignedAgentName;
    if (agentUserId == null || agentName == null) return;

    try {
      final conversation = await ApiService.getOrCreateConversation(
        otherUserId: agentUserId,
        otherDisplayName: agentName,
        otherAvatarUrl: _request.assignedAgentAvatarUrl,
        otherRole: 'agent',
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: conversation.id,
            name: agentName,
            avatarUrl: _request.assignedAgentAvatarUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _makeCall() async {
    final phone = _request.assignedAgentPhone;
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ---------- Provider Card ----------

  Widget _buildProviderCard(ColorScheme cs, AppLocalizations l) {
    final name = _request.assignedAgentName ?? '';
    final rating = _request.assignedAgentRating ?? 0.0;
    final deals = _request.assignedAgentDeals ?? 0;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.tr('yourProvider'),
            style: TextStyle(
              color: cs.outline,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              // Avatar
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _request.agentInitials,
                    style: TextStyle(
                      color: const Color(0xFFF59E0B),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: const Color(0xFFF59E0B), size: 16.r),
                        SizedBox(width: 3.w),
                        Text(
                          '$rating',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          width: 4.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: cs.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '$deals ${l.tr('jobsCompleted')}',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _request.assignedAgentUserId != null
                      ? () => _openChat()
                      : null,
                  icon: Icon(Icons.chat_outlined, size: 18.r),
                  label: Text(l.tr('message')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: cs.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    textStyle: TextStyle(
                        fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _request.assignedAgentPhone != null
                      ? () => _makeCall()
                      : null,
                  icon: Icon(Icons.phone_outlined, size: 18.r),
                  label: Text(l.tr('call')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    textStyle: TextStyle(
                        fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Tracking Timeline ----------

  Widget _buildTrackingTimeline(ColorScheme cs, AppLocalizations l) {
    final steps = _steps(l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.tr('trackingTimeline'),
          style: TextStyle(
            color: cs.outline,
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                _buildTimelineStep(steps[i], i, cs,
                    isLast: i == steps.length - 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
      _TrackingStep step, int index, ColorScheme cs,
      {required bool isLast}) {
    final isCompleted = step.isCompleted;
    final isActive = step.isActive;
    final isFuture = !isCompleted && !isActive;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        SizedBox(
          width: 32.w,
          child: Column(
            children: [
              // Dot
              if (isActive)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) => Container(
                    width: 28.w,
                    height: 28.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: _pulseAnimation.value * 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 16.w,
                        height: 16.h,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 28.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted ? Icons.check_rounded : step.icon,
                      color: isCompleted ? Colors.white : cs.outline,
                      size: 16.r,
                    ),
                  ),
                ),
              // Line
              if (!isLast)
                Container(
                  width: 2,
                  height: 40.h,
                  margin: EdgeInsets.symmetric(vertical: 4.h),
                  color: isCompleted
                      ? AppColors.primary
                      : cs.surfaceContainerHighest,
                ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: TextStyle(
                          color: isFuture ? cs.outline : cs.onSurface,
                          fontSize: 14.sp,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (step.time != null)
                      Text(
                        step.time!,
                        style: TextStyle(
                          color: cs.outline,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    color: isFuture
                        ? cs.outline.withValues(alpha: 0.6)
                        : cs.onSurfaceVariant,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Request Details ----------

  Widget _buildRequestDetails(ColorScheme cs, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.tr('requestDetails'),
          style: TextStyle(
            color: cs.outline,
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDetailRow(l.tr('requestId'), _request.shortNumber, cs),
              Divider(color: cs.outlineVariant, height: 24.h),
              _buildDetailRow(l.tr('category'), _request.displayCategory, cs),
              if (_request.description != null &&
                  _request.description!.isNotEmpty) ...[
                Divider(color: cs.outlineVariant, height: 24.h),
                _buildDetailRow(
                    l.tr('description'), _request.description!, cs),
              ],
              if (_request.scheduledTime != null &&
                  _request.scheduledTime!.isNotEmpty) ...[
                Divider(color: cs.outlineVariant, height: 24.h),
                _buildDetailRow(
                    l.tr('scheduleTime'), _request.scheduledTime!, cs),
              ],
              Divider(color: cs.outlineVariant, height: 24.h),
              _buildDetailRow(l.tr('status'),
                  _request.status.replaceAll('_', ' ').toUpperCase(), cs,
                  valueColor: AppColors.primary),
              if (_request.etaMinutes != null) ...[
                Divider(color: cs.outlineVariant, height: 24.h),
                _buildDetailRow(l.tr('estimatedArrival'),
                    '${_request.etaMinutes} min', cs),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme cs,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: TextStyle(
              color: cs.outline,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? cs.onSurface,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Bottom Actions ----------

  Widget _buildBottomActions(ColorScheme cs, AppLocalizations l) {
    final isTerminal =
        _request.status == 'completed' || _request.status == 'cancelled';

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                side: BorderSide(color: cs.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 15.h),
                textStyle: TextStyle(
                    fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
              child: Text(l.tr('back')),
            ),
          ),
          if (!isTerminal) ...[
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showCancelDialog(cs, l);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  textStyle: TextStyle(
                      fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                child: Text(l.tr('cancelRequest')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelDialog(ColorScheme cs, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          l.tr('cancelServiceRequest'),
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17.sp,
          ),
        ),
        content: Text(
          l.tr('cancelServiceConfirm'),
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14.sp,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l.tr('keepRequest'),
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ApiService.updateServiceRequestStatus(
                  _request.id,
                  'cancelled',
                  statusMessage: 'Cancelled by user',
                );
                if (!mounted) return;
                setState(() {
                  _request = ServiceRequest(
                    id: _request.id,
                    userId: _request.userId,
                    requestNumber: _request.requestNumber,
                    category: _request.category,
                    categoryName: _request.categoryName,
                    status: 'cancelled',
                    statusMessage: 'Cancelled by user',
                    etaMinutes: _request.etaMinutes,
                    description: _request.description,
                    scheduledTime: _request.scheduledTime,
                    createdAt: _request.createdAt,
                  );
                });
                _pollTimer?.cancel();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.tr('serviceRequestCancelled')),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l.tr('failedToCancel')} $e'),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: Text(
              l.tr('cancelRequestAction'),
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
