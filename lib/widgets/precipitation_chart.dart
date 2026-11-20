import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/territorial_models.dart';
import '../theme/app_theme.dart';

/// Gráfico vetorial leve de precipitação horária (mm) com linha de tendência.
class PrecipitationChart extends StatelessWidget {
  const PrecipitationChart({
    super.key,
    required this.data,
    this.highContrast = false,
  });

  final List<HourlyHydroData> data;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Sem dados pluviométricos para exibir.',
            style: TextStyle(color: AppColors.inkMuted),
          ),
        ),
      );
    }

    // Amostra até 8 pontos distribuídos para manter leitura limpa em telas mobile
    final step = math.max(1, (data.length / 8).ceil());
    final sampled = <HourlyHydroData>[];
    for (var i = 0; i < data.length; i += step) {
      sampled.add(data[i]);
    }

    return Semantics(
      label:
          'Gráfico de barras e tendência de precipitação nas próximas 24 horas.',
      child: Column(
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: _PrecipitationChartPainter(
                points: sampled,
                highContrast: highContrast,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: sampled
                .map(
                  (p) => Expanded(
                    child: Text(
                      p.hourLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PrecipitationChartPainter extends CustomPainter {
  _PrecipitationChartPainter({
    required this.points,
    required this.highContrast,
  });

  final List<HourlyHydroData> points;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final maxRain = points.fold<double>(
      10.0,
      (prev, item) => math.max(prev, item.precipitationMm),
    );

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0;

    // Linhas guia horizontais
    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final barWidth = (size.width / points.length) * 0.42;
    final stepX = size.width / points.length;

    final trendPath = Path();

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final ratio = (p.precipitationMm / maxRain).clamp(0.05, 1.0);
      final barHeight = ratio * (size.height - 20);
      final cx = (i * stepX) + (stepX / 2);
      final topY = size.height - barHeight;

      final barColor = p.precipitationMm >= 10
          ? AppColors.critical
          : (p.precipitationMm >= 5 ? AppColors.primary : AppColors.accent);

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - (barWidth / 2), topY, barWidth, barHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      final barPaint = Paint()
        ..color = highContrast
            ? barColor
            : barColor.withValues(alpha: 0.78);
      canvas.drawRRect(rect, barPaint);

      // Valor numérico discreto acima de cada barra
      final tp = TextPainter(
        text: TextSpan(
          text: p.precipitationMm.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: highContrast ? Colors.black : AppColors.inkMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, math.max(0, topY - tp.height - 6)),
      );

      if (i == 0) {
        trendPath.moveTo(cx, topY - 4);
      } else {
        final prevCx = ((i - 1) * stepX) + (stepX / 2);
        final prevRatio =
            (points[i - 1].precipitationMm / maxRain).clamp(0.05, 1.0);
        final prevTopY = size.height - (prevRatio * (size.height - 20)) - 4;
        trendPath.cubicTo(
          (prevCx + cx) / 2,
          prevTopY,
          (prevCx + cx) / 2,
          topY - 4,
          cx,
          topY - 4,
        );
      }
    }

    final trendPaint = Paint()
      ..color = highContrast ? Colors.black : AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(trendPath, trendPaint);
  }

  @override
  bool shouldRepaint(covariant _PrecipitationChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.highContrast != highContrast;
}
