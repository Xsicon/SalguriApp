import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/property.dart';
import '../../services/api_service.dart';

class ScheduleShowingScreen extends StatefulWidget {
  final Property property;

  const ScheduleShowingScreen({super.key, required this.property});

  @override
  State<ScheduleShowingScreen> createState() => _ScheduleShowingScreenState();
}

class _ScheduleShowingScreenState extends State<ScheduleShowingScreen> {
  DateTime _focusedMonth = DateTime(2024, 5);
  DateTime? _selectedDate;
  String? _selectedTime;
  int _numberOfPeople = 2;
  final TextEditingController _notesController = TextEditingController();
  final Set<String> _confirmBy = {'Phone'};

  Property get p => widget.property;

  static const List<String> _timeSlots = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
  ];

  static const List<String> _confirmOptions = ['Phone', 'Email', 'SMS'];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SCHEDULE SHOWING',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPropertyCard(cs),
                  SizedBox(height: 24.h),
                  _buildCalendarSection(cs),
                  SizedBox(height: 24.h),
                  _buildTimeSection(cs),
                  SizedBox(height: 24.h),
                  _buildPeopleSection(cs),
                  SizedBox(height: 24.h),
                  _buildNotesSection(cs),
                  SizedBox(height: 24.h),
                  _buildConfirmBySection(cs),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
          _buildBottomButton(cs),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Property Info Card
  // ---------------------------------------------------------------------------

  Widget _buildPropertyCard(ColorScheme cs) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          // Property image thumbnail
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: p.images.isNotEmpty
                ? Image.network(
                    p.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(Icons.home_outlined, color: cs.outline, size: 28.r),
                    ),
                  )
                : Center(
                    child: Icon(Icons.home_outlined, color: cs.outline, size: 28.r),
                  ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.location,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  p.price,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Agent avatar
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                p.agent?.initials ?? '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Calendar Section
  // ---------------------------------------------------------------------------

  Widget _buildCalendarSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT DATE',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: [
              _buildCalendarHeader(cs),
              SizedBox(height: 16.h),
              _buildCalendarWeekDays(cs),
              SizedBox(height: 8.h),
              _buildCalendarDays(cs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader(ColorScheme cs) {
    final monthLabel = DateFormat('MMMM yyyy').format(_focusedMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
            });
          },
          child: Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.chevron_left, color: cs.onSurfaceVariant, size: 20.r),
          ),
        ),
        Text(
          monthLabel,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
            });
          },
          child: Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20.r),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarWeekDays(ColorScheme cs) {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Row(
      children: days
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarDays(ColorScheme cs) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday = 1, Sunday = 7 in DateTime.weekday
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon ... 7=Sun
    final offset = firstWeekday - 1; // number of blank cells before day 1

    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Row(
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              final day = index - offset + 1;

              if (day < 1 || day > daysInMonth) {
                return Expanded(child: SizedBox(height: 40.h));
              }

              final date = DateTime(year, month, day);
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;
              final isToday = DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    height: 40.h,
                    margin: EdgeInsets.all(2.r),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : cs.onSurface,
                          fontSize: 14.sp,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Time Selection
  // ---------------------------------------------------------------------------

  Widget _buildTimeSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT TIME',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: _timeSlots.map((time) {
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () => setState(() => _selectedTime = time),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : cs.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : cs.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: isSelected ? Colors.white : cs.onSurface,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Number of People
  // ---------------------------------------------------------------------------

  Widget _buildPeopleSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NUMBER OF PEOPLE',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_numberOfPeople ${_numberOfPeople == 1 ? 'person' : 'people'}',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _buildCounterButton(
                    icon: Icons.remove,
                    onTap: _numberOfPeople > 1
                        ? () => setState(() => _numberOfPeople--)
                        : null,
                    cs: cs,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      '$_numberOfPeople',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildCounterButton(
                    icon: Icons.add,
                    onTap: _numberOfPeople < 10
                        ? () => setState(() => _numberOfPeople++)
                        : null,
                    cs: cs,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onTap,
    required ColorScheme cs,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppColors.primary : cs.onSurfaceVariant,
          size: 20.r,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Additional Notes
  // ---------------------------------------------------------------------------

  Widget _buildNotesSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADDITIONAL NOTES',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            style: TextStyle(color: cs.onSurface, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Tell us if you have any special requirements...',
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp),
              contentPadding: EdgeInsets.all(16.r),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Confirm By
  // ---------------------------------------------------------------------------

  Widget _buildConfirmBySection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONFIRM BY',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: _confirmOptions.map((option) {
            final isSelected = _confirmBy.contains(option);
            return Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected && _confirmBy.length > 1) {
                      _confirmBy.remove(option);
                    } else {
                      _confirmBy.add(option);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : cs.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : cs.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(Icons.check, color: AppColors.primary, size: 16.r),
                        SizedBox(width: 6.w),
                      ],
                      Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : cs.onSurface,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Button
  // ---------------------------------------------------------------------------

  Widget _buildBottomButton(ColorScheme cs) {
    final isValid = _selectedDate != null && _selectedTime != null;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        16.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 16.h,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isValid
              ? () => _submitShowing()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: cs.surfaceContainerHighest,
            foregroundColor: Colors.white,
            disabledForegroundColor: cs.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 16.h),
            elevation: 0,
            textStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          child: const Text('REQUEST SHOWING'),
        ),
      ),
    );
  }

  Future<void> _submitShowing() async {
    final cs = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!);

    try {
      await ApiService.createShowing(
        propertyId: p.id,
        requestedDate: _selectedDate!,
        requestedTime: _selectedTime!,
        numberOfPeople: _numberOfPeople,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        confirmBy: _confirmBy.first.toLowerCase(),
      );
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          title: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 24.r),
              ),
              SizedBox(width: 12.w),
              Text(
                'Request Sent!',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Your showing request for $dateLabel at $_selectedTime '
            'has been sent to ${p.agent?.name ?? 'the agent'}. '
            'You will be notified via ${_confirmBy.join(', ')}.',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
