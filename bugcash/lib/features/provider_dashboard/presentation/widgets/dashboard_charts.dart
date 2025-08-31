import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/models/provider_model.dart';

class DashboardCharts extends StatelessWidget {
  final DashboardStats stats;

  const DashboardCharts({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMissionStatusChart(context),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildBugReportPriorityChart(context),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _buildPerformanceChart(context),
      ],
    );
  }

  Widget _buildMissionStatusChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '미션 상태별 분포',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 200.h,
              child: CustomPaint(
                painter: _PieChartPainter(stats),
              ),
            ),
            SizedBox(height: 16.h),
            _buildChartLegend(
              context,
              [
                {'label': '활성', 'color': Colors.blue, 'value': stats.activeMissions},
                {'label': '완료', 'color': Colors.green, 'value': stats.completedMissions},
                {'label': '대기', 'color': Colors.orange, 'value': stats.missionsByStatus['pending'] ?? 0},
                {'label': '취소', 'color': Colors.red, 'value': stats.missionsByStatus['cancelled'] ?? 0},
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBugReportPriorityChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '버그 리포트 우선순위',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 200.h,
              child: CustomPaint(
                painter: _BarChartPainter(stats),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('높음', style: Theme.of(context).textTheme.bodySmall),
                Text('보통', style: Theme.of(context).textTheme.bodySmall),
                Text('낮음', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '성과 지표 트렌드',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 250.h,
              child: CustomPaint(
                painter: _LineChartPainter(stats),
              ),
            ),
            SizedBox(height: 16.h),
            _buildChartLegend(
              context,
              [
                {'label': '미션 완료율', 'color': Colors.blue},
                {'label': '버그 해결율', 'color': Colors.green},
                {'label': '사용자 만족도', 'color': Colors.orange},
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(BuildContext context, List<Map<String, dynamic>> items) {
    return Wrap(
      spacing: 16.w,
      runSpacing: 8.h,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: item['color'],
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              item.containsKey('value') 
                  ? '${item['label']} (${item['value']})'
                  : item['label'],
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

}

class _PieChartPainter extends CustomPainter {
  final DashboardStats stats;

  _PieChartPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final total = stats.totalMissions;
    
    if (total == 0) return;
    
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    final values = [
      stats.activeMissions,
      stats.completedMissions,
      stats.missionsByStatus['pending'] ?? 0,
      stats.missionsByStatus['cancelled'] ?? 0,
    ];
    
    double startAngle = -pi / 2;
    
    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * pi;
      paint.color = colors[i];
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartPainter extends CustomPainter {
  final DashboardStats stats;

  _BarChartPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final barWidth = size.width / 6;
    final maxValue = _getMaxBugReportValue();
    
    final values = [
      stats.bugReportsByPriority['high'] ?? 0,
      stats.bugReportsByPriority['medium'] ?? 0,
      stats.bugReportsByPriority['low'] ?? 0,
    ];
    
    final colors = [Colors.red, Colors.orange, Colors.green];
    
    for (int i = 0; i < values.length; i++) {
      final barHeight = (values[i] / maxValue) * size.height * 0.8;
      final x = (i + 1) * size.width / 4 - barWidth / 2;
      final y = size.height - barHeight;
      
      paint.color = colors[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }
  
  int _getMaxBugReportValue() {
    final values = stats.bugReportsByPriority.values;
    return values.isEmpty ? 10 : (values.reduce((a, b) => a > b ? a : b) + 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LineChartPainter extends CustomPainter {
  final DashboardStats stats;

  _LineChartPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // 샘플 데이터
    final data = [
      [65, 70, 68, 75, 80, 85],
      [72, 75, 78, 76, 82, 88],
      [68, 72, 74, 73, 78, 82],
    ];
    
    final colors = [Colors.blue, Colors.green, Colors.orange];
    
    for (int lineIndex = 0; lineIndex < data.length; lineIndex++) {
      paint.color = colors[lineIndex];
      final points = <Offset>[];
      
      for (int i = 0; i < data[lineIndex].length; i++) {
        final x = (i / (data[lineIndex].length - 1)) * size.width;
        final y = size.height - (data[lineIndex][i] / 100) * size.height;
        points.add(Offset(x, y));
      }
      
      // 선 그리기
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
      
      // 점 그리기
      paint.style = PaintingStyle.fill;
      for (final point in points) {
        canvas.drawCircle(point, 3, paint);
      }
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}