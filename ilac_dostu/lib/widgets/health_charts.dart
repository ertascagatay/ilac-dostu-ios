import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/measurement_model.dart';

class HealthChartsWidget extends StatelessWidget {
  final List<MeasurementModel> measurements;

  const HealthChartsWidget({
    super.key,
    required this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    final bpData = measurements
        .where((m) => m.type == MeasurementType.bloodPressure)
        .toList();
    final sugarData = measurements
        .where((m) => m.type == MeasurementType.bloodSugar)
        .toList();
    final weightData =
        measurements.where((m) => m.type == MeasurementType.weight).toList();
    final pulseData =
        measurements.where((m) => m.type == MeasurementType.pulse).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bpData.isNotEmpty) _buildBPChart(bpData),
          if (sugarData.isNotEmpty) _buildSugarChart(sugarData),
          if (weightData.isNotEmpty) _buildWeightChart(weightData),
          if (pulseData.isNotEmpty) _buildPulseChart(pulseData),
          if (measurements.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.show_chart, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz sağlık verisi yok',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBPChart(List<MeasurementModel> data) {
    final last7Days = data.take(7).toList().reversed.toList();

    return _buildChartCard(
      title: 'Tansiyon (mmHg)',
      icon: Icons.favorite,
      color: const Color(0xFFFF6B6B),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < last7Days.length) {
                      final date = last7Days[value.toInt()].timestamp;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd/MM').format(date),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 40,
            maxY: 180,
            lineBarsData: [
              // Systolic
              LineChartBarData(
                spots: last7Days.asMap().entries.map((entry) {
                  final systolic =
                      double.tryParse(entry.value.value.split('/')[0]) ?? 0;
                  return FlSpot(entry.key.toDouble(), systolic);
                }).toList(),
                isCurved: true,
                color: const Color(0xFFFF6B6B),
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                ),
              ),
              // Diastolic
              LineChartBarData(
                spots: last7Days.asMap().entries.map((entry) {
                  final diastolic =
                      double.tryParse(entry.value.value.split('/')[1]) ?? 0;
                  return FlSpot(entry.key.toDouble(), diastolic);
                }).toList(),
                isCurved: true,
                color: const Color(0xFFFF6B6B).withOpacity(0.5),
                barWidth: 3,
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSugarChart(List<MeasurementModel> data) {
    final last7Days = data.take(7).toList().reversed.toList();

    return _buildChartCard(
      title: 'Kan Şekeri (mg/dL)',
      icon: Icons.water_drop,
      color: const Color(0xFF6C63FF),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 50,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < last7Days.length) {
                      final date = last7Days[value.toInt()].timestamp;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd/MM').format(date),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 50,
            maxY: 250,
            lineBarsData: [
              LineChartBarData(
                spots: last7Days.asMap().entries.map((entry) {
                  final value = double.tryParse(entry.value.value) ?? 0;
                  return FlSpot(entry.key.toDouble(), value);
                }).toList(),
                isCurved: true,
                color: const Color(0xFF6C63FF),
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightChart(List<MeasurementModel> data) {
    final last7Days = data.take(7).toList().reversed.toList();

    return _buildChartCard(
      title: 'Kilo (kg)',
      icon: Icons.monitor_weight,
      color: const Color(0xFF4CAF50),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < last7Days.length) {
                      final date = last7Days[value.toInt()].timestamp;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd/MM').format(date),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: last7Days.asMap().entries.map((entry) {
                  final value = double.tryParse(entry.value.value) ?? 0;
                  return FlSpot(entry.key.toDouble(), value);
                }).toList(),
                isCurved: true,
                color: const Color(0xFF4CAF50),
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseChart(List<MeasurementModel> data) {
    final last7Days = data.take(7).toList().reversed.toList();

    return _buildChartCard(
      title: 'Nabız (bpm)',
      icon: Icons.favorite_border,
      color: const Color(0xFFFF9800),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < last7Days.length) {
                      final date = last7Days[value.toInt()].timestamp;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd/MM').format(date),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 40,
            maxY: 120,
            lineBarsData: [
              LineChartBarData(
                spots: last7Days.asMap().entries.map((entry) {
                  final value = double.tryParse(entry.value.value) ?? 0;
                  return FlSpot(entry.key.toDouble(), value);
                }).toList(),
                isCurved: true,
                color: const Color(0xFFFF9800),
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
