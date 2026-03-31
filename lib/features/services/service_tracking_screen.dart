import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/service_request.dart';
import '../../services/api_service.dart';

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

  Timer? _etaTimer;
  late int _remainingMinutes;
  int _currentStep = 1; // 0-based: 0=confirmed, 1=assigned, 2=on the way, 3=arrived, 4=completed

  // Simulated provider info
  final _providerName = 'Ahmed Hassan';
  final _providerRating = 4.9;
  final _providerJobs = 142;

  @override
  void initState() {
    super.initState();
    _remainingMinutes = widget.request.etaMinutes ?? 25;

    // Determine initial step from status
    switch (widget.request.status) {
      case 'pending':
        _currentStep = 0;
      case 'in_progress':
        _currentStep = 2;
      case 'completed':
        _currentStep = 4;
      default:
        _currentStep = 1;
    }

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

    // Simulate live updates
    _startSimulation();
  }

  void _startSimulation() {
    _etaTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingMinutes > 1) _remainingMinutes--;
        if (_currentStep < 4) {
          // Advance step occasionally
          if (_remainingMinutes % 5 == 0 && _currentStep < 3) {
            _currentStep++;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  List<_TrackingStep> get _steps {
    final now = DateTime.now();
    final fmt = _formatTimeOfDay;
    return [
      _TrackingStep(
        title: 'Request Confirmed',
        subtitle: 'Your service request has been received',
        icon: Icons.check_circle_outline,
        isCompleted: _currentStep > 0,
        isActive: _currentStep == 0,
        time: fmt(TimeOfDay.fromDateTime(widget.request.createdAt.toLocal())),
      ),
      _TrackingStep(
        title: 'Provider Assigned',
        subtitle: '$_providerName is handling your request',
        icon: Icons.person_pin_outlined,
        isCompleted: _currentStep > 1,
        isActive: _currentStep == 1,
        time: _currentStep >= 1
            ? fmt(TimeOfDay.fromDateTime(
                widget.request.createdAt.add(const Duration(minutes: 3)).toLocal()))
            : null,
      ),
      _TrackingStep(
        title: 'On the Way',
        subtitle: 'Provider is heading to your location',
        icon: Icons.directions_car_outlined,
        isCompleted: _currentStep > 2,
        isActive: _currentStep == 2,
        time: _currentStep >= 2
            ? fmt(TimeOfDay.fromDateTime(
                now.subtract(Duration(minutes: _remainingMinutes))))
            : null,
      ),
      _TrackingStep(
        title: 'Arrived',
        subtitle: 'Provider has arrived at your property',
        icon: Icons.location_on_outlined,
        isCompleted: _currentStep > 3,
        isActive: _currentStep == 3,
        time: _currentStep >= 3 ? fmt(TimeOfDay.fromDateTime(now)) : null,
      ),
      _TrackingStep(
        title: 'Service Completed',
        subtitle: 'The job has been finished successfully',
        icon: Icons.verified_outlined,
        isCompleted: _currentStep > 4,
        isActive: _currentStep == 4,
        time: null,
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

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Track Service'),
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _buildStatusHeader(cs),
                const SizedBox(height: 20),
                _buildEtaCard(cs),
                const SizedBox(height: 20),
                _buildProviderCard(cs),
                const SizedBox(height: 24),
                _buildTrackingTimeline(cs),
                const SizedBox(height: 24),
                _buildRequestDetails(cs),
              ],
            ),
          ),
          _buildBottomActions(cs),
        ],
      ),
    );
  }

  // ---------- Status Header ----------

  Widget _buildStatusHeader(ColorScheme cs) {
    final step = _steps[_currentStep.clamp(0, _steps.length - 1)];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Pulsing indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: _pulseAnimation.value * 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(step.icon, color: Colors.white, size: 20),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
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

  Widget _buildEtaCard(ColorScheme cs) {
    final progress = _currentStep / (_steps.length - 1);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.access_time_rounded,
                      color: AppColors.primary, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Arrival',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentStep >= 3
                          ? 'Provider has arrived'
                          : '$_remainingMinutes min remaining',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              // Live badge
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success
                        .withValues(alpha: 0.08 + _pulseAnimation.value * 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
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
                      const SizedBox(width: 5),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
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
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: TextStyle(color: cs.outline, fontSize: 12),
              ),
              Text(
                '${(progress * 100).toInt()}% complete',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Provider Card ----------

  Widget _buildProviderCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
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
            'YOUR PROVIDER',
            style: TextStyle(
              color: cs.outline,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
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
                    _providerName.split(' ').map((n) => n[0]).join(),
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _providerName,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 3),
                        Text(
                          '$_providerRating',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_providerJobs jobs completed',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: cs.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _buildTrackingTimeline(ColorScheme cs) {
    final steps = _steps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRACKING TIMELINE',
          style: TextStyle(
            color: cs.outline,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
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
          width: 32,
          child: Column(
            children: [
              // Dot
              if (isActive)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) => Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: _pulseAnimation.value * 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
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
                  width: 28,
                  height: 28,
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
                      size: 16,
                    ),
                  ),
                ),
              // Line
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isCompleted
                      ? AppColors.primary
                      : cs.surfaceContainerHighest,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
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
                          fontSize: 14,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    color: isFuture
                        ? cs.outline.withValues(alpha: 0.6)
                        : cs.onSurfaceVariant,
                    fontSize: 12,
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

  Widget _buildRequestDetails(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REQUEST DETAILS',
          style: TextStyle(
            color: cs.outline,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
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
              _buildDetailRow('Request ID', widget.request.shortNumber, cs),
              Divider(color: cs.outlineVariant, height: 24),
              _buildDetailRow('Category', widget.request.displayCategory, cs),
              if (widget.request.description != null &&
                  widget.request.description!.isNotEmpty) ...[
                Divider(color: cs.outlineVariant, height: 24),
                _buildDetailRow(
                    'Description', widget.request.description!, cs),
              ],
              Divider(color: cs.outlineVariant, height: 24),
              _buildDetailRow('Status',
                  widget.request.status.replaceAll('_', ' ').toUpperCase(), cs,
                  valueColor: AppColors.primary),
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
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: cs.outline,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Bottom Actions ----------

  Widget _buildBottomActions(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: const Text('BACK'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _showCancelDialog(cs);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: const Text('CANCEL REQUEST'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(ColorScheme cs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Service Request?',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this service request? '
          'A cancellation fee may apply if the provider is already on the way.',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Keep Request',
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
                  widget.request.id,
                  'cancelled',
                  statusMessage: 'Cancelled by user',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service request cancelled'),
                    backgroundColor: AppColors.primary,
                  ),
                );
                Navigator.of(context).pop(true);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel: $e'),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: const Text(
              'Cancel Request',
              style: TextStyle(
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
