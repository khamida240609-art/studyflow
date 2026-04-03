import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/teacher_provider.dart';
import '../utils/theme.dart';
import '../widgets/section_header.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacher = context.watch<TeacherProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Teacher Dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Track student consistency and engagement.',
                style: TextStyle(color: AppTheme.secondary(context), fontSize: 13)),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Students', subtitle: 'Weekly activity'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: teacher.students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final s = teacher.students[i];
                  return _StudentCard(
                    name: s.name,
                    total: s.totalSessions,
                    avg: s.avgDuration,
                    weekly: s.weeklyActivity,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String name;
  final int total;
  final double avg;
  final List<int> weekly;

  const _StudentCard({
    required this.name,
    required this.total,
    required this.avg,
    required this.weekly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Total sessions: $total · Avg: ${avg.toStringAsFixed(1)} min',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                barGroups: List.generate(weekly.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weekly[i].toDouble(),
                        color: AppTheme.accent2,
                        width: 8,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
