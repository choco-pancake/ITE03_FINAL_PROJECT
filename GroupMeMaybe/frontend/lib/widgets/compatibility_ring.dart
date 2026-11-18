import 'dart:math';
import 'package:flutter/material.dart';

class CompatibilityRing extends StatelessWidget {
  final double score; // 0 to 100
  final double size;
  final double strokeWidth;
  final double? skillCoverage;
  final double? interestMatch;
  final double? availabilityOverlap;
  final bool showDetails;

  const CompatibilityRing({
    super.key,
    required this.score,
    this.size = 72,
    this.strokeWidth = 7,
    this.skillCoverage,
    this.interestMatch,
    this.availabilityOverlap,
    this.showDetails = false,
  });

  Color get scoreColor {
    if (score >= 85) return const Color(0xFF10B981); // Emerald Green
    if (score >= 70) return const Color(0xFF3B82F6); // Blue
    if (score >= 50) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    final ringWidget = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: (score / 100.0).clamp(0.0, 1.0),
          color: scoreColor,
          backgroundColor: scoreColor.withValues(alpha: 0.15),
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toInt()}%',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              if (size >= 64)
                Text(
                  'MATCH',
                  style: TextStyle(
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!showDetails || skillCoverage == null) {
      return Tooltip(
        message: 'Overall: ${score.toStringAsFixed(1)}%\nSkills: ${skillCoverage?.toStringAsFixed(1) ?? 'N/A'}% (40%)\nInterests: ${interestMatch?.toStringAsFixed(1) ?? 'N/A'}% (30%)\nAvailability: ${availabilityOverlap?.toStringAsFixed(1) ?? 'N/A'}% (30%)',
        child: ringWidget,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ringWidget,
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMetricBar('Skills Coverage (40%)', skillCoverage ?? 0, const Color(0xFF6366F1)),
            const SizedBox(height: 4),
            _buildMetricBar('Interests Match (30%)', interestMatch ?? 0, const Color(0xFF0EA5E9)),
            const SizedBox(height: 4),
            _buildMetricBar('Availability (30%)', availabilityOverlap ?? 0, const Color(0xFF10B981)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricBar(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              '${val.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 120,
          height: 4,
          child: LinearProgressIndicator(
            value: (val / 100.0).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at 12 o'clock
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
