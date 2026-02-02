import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/glass_card.dart';
import '../../core/theme/app_colors.dart';

class ClientAnalyticsScreen extends StatelessWidget {
  const ClientAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analyticsRepo = Get.find<AnalyticsRepository>();
    final userId = Get.find<AuthRepository>().currentUser.value?.id ?? '';
    final spendingData = analyticsRepo.getSpendingByCategory(userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSpendingPieChart(spendingData),
            const SizedBox(height: 32),
            const Text(
              'Project Velocity (Days/Milestone)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildVelocityChart(),
            const SizedBox(height: 32),
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingPieChart(Map<String, double> data) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    int colorIndex = 0;

    return AspectRatio(
      aspectRatio: 1.3,
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: data.entries.map((e) {
                    final color = colors[colorIndex % colors.length];
                    colorIndex++;
                    return PieChartSectionData(
                      value: e.value,
                      title: '${(e.value / 2750 * 100).toStringAsFixed(0)}%',
                      color: color,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries.map((e) {
                // Reset color index for legend matching
                final color =
                    colors[data.keys.toList().indexOf(e.key) % colors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(e.key, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVelocityChart() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      'P${value.toInt()}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(1, 10),
                    FlSpot(2, 7),
                    FlSpot(3, 8),
                    FlSpot(4, 5),
                    FlSpot(5, 4),
                  ],
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      children: [
        GlassCard(
          child: ListTile(
            leading: const Icon(Icons.speed, color: Colors.green),
            title: const Text('Avg. Completion Time'),
            trailing: const Text(
              '6.2 Days',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.blue),
            title: const Text('Platform Fees Paid'),
            trailing: const Text(
              '₦145.00',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
