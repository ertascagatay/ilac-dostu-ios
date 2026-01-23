import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ilac_dostu/services/history_service.dart';
import 'package:ilac_dostu/main.dart';

class HistoryScreen extends StatelessWidget {
  final String userId;
  
  const HistoryScreen({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Geçmiş & İstatistikler',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compliance Stats Card
            FutureBuilder<ComplianceStats>(
              future: HistoryService.getComplianceStats(userId: userId, days: 7),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData) {
                  return const SizedBox();
                }
                
                final stats = snapshot.data!;
                
                return Column(
                  children: [
                    _StatsCard(
                      icon: Icons.show_chart,
                      title: 'Son 7 Gün Uyum',
                      value: '${stats.complianceRate.toStringAsFixed(0)}%',
                      subtitle: '${stats.totalTaken}/${stats.totalExpected} ilaç alındı',
                      color: stats.complianceRate >= 80 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _StatsCard(
                      icon: Icons.local_fire_department,
                      title: 'Seri',
                      value: '${stats.streak} gün',
                      subtitle: 'Düzenli alma serisi',
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(height: 24),
                    
                    // Weekly Chart
                    Text(
                      'Haftalık Grafik',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _WeeklyChart(dailyStats: stats.dailyStats),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // History List
            Text(
              'Geçmiş',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<List<MedicationHistory>>(
              stream: HistoryService.getMedicationHistory(userId: userId, days: 30),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Henüz geçmiş yok',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }
                
                final history = snapshot.data!;
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return ListTile(
                      leading: Icon(
                        item.timeOfDay == 'morning' 
                            ? Icons.wb_sunny_rounded 
                            : Icons.nightlight_round,
                        color: item.timeOfDay == 'morning' 
                            ? Colors.orange 
                            : Colors.indigo,
                      ),
                      title: Text(
                        item.medicationName,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        DateFormat('d MMMM yyyy, HH:mm', 'tr').format(item.takenAt),
                        style: GoogleFonts.inter(),
                      ),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  
  const _StatsCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final Map<String, int> dailyStats;
  
  const _WeeklyChart({required this.dailyStats});
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    
    final barGroups = last7Days.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final count = dailyStats[dateKey] ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 5,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < last7Days.length) {
                        final date = last7Days[value.toInt()];
                        return Text(
                          DateFormat('EEE', 'tr').format(date).substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }
}
