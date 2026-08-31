import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

/// Floating zoom control shown over the PDF in the signing screen — the
/// document is otherwise fit-to-screen with no way to read small print or
/// tap a field precisely. Pinch-to-zoom is handled separately (raw pointer
/// tracking in the screen itself); this bar is the explicit alternative.
class ZoomBar extends StatelessWidget {
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const ZoomBar({
    super.key,
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: zoom > minZoom ? onZoomOut : null,
            icon: const Icon(Icons.remove),
            iconSize: 18.r,
            visualDensity: VisualDensity.compact,
            tooltip: 'Zoom out',
          ),
          SizedBox(
            width: 44.w,
            child: GestureDetector(
              onTap: onReset,
              child: Text(
                '${(zoom * 100).round()}%',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ),
          IconButton(
            onPressed: zoom < maxZoom ? onZoomIn : null,
            icon: const Icon(Icons.add),
            iconSize: 18.r,
            visualDensity: VisualDensity.compact,
            tooltip: 'Zoom in',
          ),
        ],
      ),
    );
  }
}
