import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String iconName;
  final Color bgColor;
  final Color iconColor;
  final int providerCount;
  final bool isPopular;
  final int sortOrder;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.bgColor,
    required this.iconColor,
    this.providerCount = 0,
    this.isPopular = false,
    this.sortOrder = 0,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String? ?? 'build_outlined',
      bgColor: Color(json['bg_color'] as int? ?? 0xFFFFFFFF),
      iconColor: Color(json['icon_color'] as int? ?? 0xFF000000),
      providerCount: json['provider_count'] as int? ?? 0,
      isPopular: json['is_popular'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  IconData get icon {
    const map = <String, IconData>{
      'electrical_services': Icons.electrical_services,
      'plumbing': Icons.plumbing,
      'ac_unit': Icons.ac_unit,
      'build_outlined': Icons.build_outlined,
      'format_paint_outlined': Icons.format_paint_outlined,
      'lock_outlined': Icons.lock_outlined,
      'window_outlined': Icons.window_outlined,
      'cleaning_services_outlined': Icons.cleaning_services_outlined,
      'search_outlined': Icons.search_outlined,
      'kitchen_outlined': Icons.kitchen_outlined,
      'local_shipping_outlined': Icons.local_shipping_outlined,
      'yard_outlined': Icons.yard_outlined,
      'bug_report_outlined': Icons.bug_report_outlined,
      'carpenter_outlined': Icons.carpenter_outlined,
    };
    return map[iconName] ?? Icons.build_outlined;
  }
}
