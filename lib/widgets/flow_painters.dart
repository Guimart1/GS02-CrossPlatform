import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/territorial_models.dart';
import '../theme/app_theme.dart';

/// Fundo branco com "riscos" vetoriais animados simulando movimento hídrico,
/// relevo topográfico e integração contínua entre sensores.
class FlowLinesBackground extends StatefulWidget {
  const FlowLinesBackground({
    super.key,
    required this.child,
    this.highContrast = false,
  });

  final Widget child;
  final bool highContrast;

  @override
  State<FlowLinesBackground> createState() => _FlowLinesBackgroundState();
}

class _FlowLinesBackgroundState extends State<FlowLinesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _FlowBackgroundPainter(
                    progress: _controller.value,
                    highContrast: widget.highContrast,
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _FlowBackgroundPainter extends CustomPainter {
  _FlowBackgroundPainter({
    required this.progress,
    required this.highContrast,
  });

  final double progress;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final alphaFactor = highContrast ? 0.06 : 0.14;

    final primaryStreak = Paint()
      ..color = AppColors.primary.withValues(alpha: alphaFactor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final accentStreak = Paint()
      ..color = AppColors.accent.withValues(alpha: alphaFactor * 1.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: highContrast ? 0.2 : 0.35)
      ..style = PaintingStyle.fill;

    // Traços diagonais fluidos no topo e lateral direita
    for (var i = 0; i < 5; i++) {
      final offset = i * 26.0;
      final shift = math.sin((progress * 2 * math.pi) + i * 0.8) * 10;
      final path = Path()
        ..moveTo(size.width * 0.38 + offset, -20)
        ..cubicTo(
          size.width * 0.58 + offset + shift,
          size.height * 0.12,
          size.width * 0.72 + offset - shift,
          size.height * 0.24,
          size.width + 30,
          size.height * 0.30 + offset * 0.6,
        );
      canvas.drawPath(path, i.isEven ? primaryStreak : accentStreak);

      if (i == 1 || i == 3) {
        final t = (progress + (i * 0.25)) % 1.0;
        final nx = size.width * (0.45 + 0.5 * t) + offset * 0.4;
        final ny = size.height * (0.04 + 0.22 * t) + offset * 0.25;
        canvas.drawCircle(Offset(nx, ny), 3.0, nodePaint);
      }
    }

    // Riscos sutis de integração na parte inferior esquerda
    for (var j = 0; j < 3; j++) {
      final yBase = size.height * (0.76 + j * 0.045);
      final path = Path()
        ..moveTo(-20, yBase)
        ..quadraticBezierTo(
          size.width * 0.22,
          yBase - 24 + math.cos(progress * 2 * math.pi + j) * 6,
          size.width * 0.46,
          yBase + 12,
        );
      canvas.drawPath(path, accentStreak);
    }
  }

  @override
  bool shouldRepaint(covariant _FlowBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.highContrast != highContrast;
}

/// Card branco reutilizável com sombra suave e "riscos" discretos no canto,
/// reforçando a identidade visual de fluxo e integração territorial.
class FlowStreakCard extends StatelessWidget {
  const FlowStreakCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.highContrast = false,
    this.accentColor = AppColors.primary,
    this.semanticLabel,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highContrast;
  final Color accentColor;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highContrast ? Colors.black : AppColors.border,
          width: highContrast ? 1.8 : 1.0,
        ),
        boxShadow: AppTheme.softShadow(highContrast: highContrast),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CardStreakPainter(
                    color: accentColor,
                    highContrast: highContrast,
                  ),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    final wrapped = onTap != null
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: card,
            ),
          )
        : card;

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: wrapped,
      );
    }
    return wrapped;
  }
}

class _CardStreakPainter extends CustomPainter {
  _CardStreakPainter({required this.color, required this.highContrast});

  final Color color;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: highContrast ? 0.08 : 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final delta = i * 11.0;
      final path = Path()
        ..moveTo(size.width - 75 + delta, -6)
        ..quadraticBezierTo(
          size.width - 32 + delta * 0.5,
          24,
          size.width + 8,
          38 + delta,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardStreakPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.highContrast != highContrast;
}

class RiskPill extends StatelessWidget {
  const RiskPill({super.key, required this.level});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: level.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            level.label,
            style: TextStyle(
              color: level.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ConfidenceMeter extends StatelessWidget {
  const ConfidenceMeter({
    super.key,
    required this.percent,
    required this.label,
  });

  final int percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80
        ? AppColors.primary
        : (percent >= 60 ? AppColors.moderate : AppColors.inkMuted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nível de confiança do alerta',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
            Text(
              '$percent% ($label)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
