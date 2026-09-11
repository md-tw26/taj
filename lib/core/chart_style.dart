import 'package:flutter/material.dart';

/// How trend charts across TAJ are drawn. Chosen by the admin in Settings and
/// applied live to the dashboard's sales chart (and its preview).
enum ChartStyle {
  area('مساحة', Icons.area_chart_outlined),
  line('خط', Icons.show_chart_rounded),
  bars('أعمدة', Icons.bar_chart_rounded);

  const ChartStyle(this.label, this.icon);

  final String label;
  final IconData icon;
}
