import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ElevationChart extends StatelessWidget {
  final List<double> elevations; // meters
  final bool showGrid;
  final bool showLabels;

  const ElevationChart({
    super.key, 
    required this.elevations,
    this.showGrid = true,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    if (elevations.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.terrain, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Geen hoogteprofiel beschikbaar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final minEl = elevations.reduce((a, b) => a < b ? a : b);
    final maxEl = elevations.reduce((a, b) => a > b ? a : b);
    final range = maxEl - minEl;

    return Column(
      children: [
        if (showLabels) ..._buildStats(minEl, maxEl, range),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _ElevationPainter(
              elevations,
              showGrid: showGrid,
              showLabels: showLabels,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStats(double minEl, double maxEl, double range) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statText('Min', '${minEl.round()}m', AppColors.elevationLoss),
          _statText('Max', '${maxEl.round()}m', AppColors.elevationGain),
          _statText('Bereik', '${range.round()}m', AppColors.pathBlue),
        ],
      ),
    ];
  }

  Widget _statText(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _ElevationPainter extends CustomPainter {
  final List<double> elevations;
  final bool showGrid;
  final bool showLabels;
  
  _ElevationPainter(
    this.elevations, {
    this.showGrid = true,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.pathBlueSurface;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      bg,
    );

    if (elevations.isEmpty) return;

    final minEl = elevations.reduce((a, b) => a < b ? a : b);
    final maxEl = elevations.reduce((a, b) => a > b ? a : b);
    final range = (maxEl - minEl).clamp(1.0, double.infinity);

    // Draw grid lines
    if (showGrid) {
      _drawGrid(canvas, size, minEl, maxEl, range);
    }

    // Draw elevation path
    final path = Path();
    final smoothedPath = Path();
    
    for (int i = 0; i < elevations.length; i++) {
      final x = i / (elevations.length - 1) * size.width;
      final y = size.height - ((elevations[i] - minEl) / range) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
        smoothedPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        
        // Create smoother curve for better visual appeal
        if (i > 1 && i < elevations.length - 1) {
          final prevX = (i - 1) / (elevations.length - 1) * size.width;
          final prevY = size.height - ((elevations[i - 1] - minEl) / range) * size.height;
          final nextX = (i + 1) / (elevations.length - 1) * size.width;
          final nextY = size.height - ((elevations[i + 1] - minEl) / range) * size.height;
          
          final cp1X = prevX + (x - prevX) * 0.5;
          final cp2X = x - (nextX - x) * 0.5;
          
          if (i == 2) {
            smoothedPath.quadraticBezierTo(cp1X, prevY, x, y);
          } else {
            smoothedPath.cubicTo(cp1X, prevY, cp2X, y, x, y);
          }
        }
      }
    }

    // Draw main elevation line with gradient stroke
    final strokeGradient = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.elevationGain, AppColors.pathBlue, AppColors.elevationLoss],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(elevations.length > 20 ? smoothedPath : path, strokeGradient);

    // Fill under curve with gradient
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.pathBlue.withOpacity(0.3),
          AppColors.pathBlue.withOpacity(0.1),
          AppColors.pathBlue.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(fillPath, fill);

    // Highlight max and min points
    _drawExtremePoints(canvas, size, minEl, maxEl, range);
  }

  void _drawGrid(Canvas canvas, Size size, double minEl, double maxEl, double range) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    // Horizontal grid lines (elevation)
    for (int i = 1; i <= 4; i++) {
      final y = size.height - (i / 5.0 * size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines (distance)
    for (int i = 1; i <= 3; i++) {
      final x = i / 4.0 * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  void _drawExtremePoints(Canvas canvas, Size size, double minEl, double maxEl, double range) {
    final maxIdx = elevations.indexOf(maxEl);
    final minIdx = elevations.indexOf(minEl);
    
    final maxX = maxIdx / (elevations.length - 1) * size.width;
    final maxY = size.height - ((maxEl - minEl) / range) * size.height;
    
    final minX = minIdx / (elevations.length - 1) * size.width;
    final minY = size.height - ((minEl - minEl) / range) * size.height;
    
    // Draw max point
    final maxPaint = Paint()
      ..color = AppColors.elevationGain
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(maxX, maxY), 4, maxPaint);
    
    // Draw min point
    final minPaint = Paint()
      ..color = AppColors.elevationLoss
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(minX, minY), 4, minPaint);
  }

  @override
  bool shouldRepaint(covariant _ElevationPainter oldDelegate) {
    return oldDelegate.elevations != elevations ||
           oldDelegate.showGrid != showGrid ||
           oldDelegate.showLabels != showLabels;
  }
}

