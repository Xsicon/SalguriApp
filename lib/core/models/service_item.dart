import 'package:flutter/material.dart';

class ServiceItem {
  final String id;
  final String categoryId;
  final String name;
  final double price;
  final String iconName;
  final int sortOrder;

  const ServiceItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.iconName,
    this.sortOrder = 0,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      iconName: json['icon_name'] as String? ?? 'build_outlined',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  IconData get icon {
    const map = <String, IconData>{
      'power_outlined': Icons.power_outlined,
      'lightbulb_outline': Icons.lightbulb_outline,
      'cable_outlined': Icons.cable_outlined,
      'toys_outlined': Icons.toys_outlined,
      'electrical_services': Icons.electrical_services,
      'plumbing': Icons.plumbing,
      'water_drop_outlined': Icons.water_drop_outlined,
      'water_outlined': Icons.water_outlined,
      'wc_outlined': Icons.wc_outlined,
      'local_fire_department_outlined': Icons.local_fire_department_outlined,
      'ac_unit': Icons.ac_unit,
      'build_outlined': Icons.build_outlined,
      'air_outlined': Icons.air_outlined,
      'thermostat_outlined': Icons.thermostat_outlined,
      'filter_alt_outlined': Icons.filter_alt_outlined,
      'cleaning_services_outlined': Icons.cleaning_services_outlined,
      'auto_awesome_outlined': Icons.auto_awesome_outlined,
      'home_outlined': Icons.home_outlined,
      'window_outlined': Icons.window_outlined,
      'chair_outlined': Icons.chair_outlined,
      'format_paint_outlined': Icons.format_paint_outlined,
      'house_outlined': Icons.house_outlined,
      'brush_outlined': Icons.brush_outlined,
      'villa_outlined': Icons.villa_outlined,
      'kitchen_outlined': Icons.kitchen_outlined,
    };
    return map[iconName] ?? Icons.build_outlined;
  }
}
