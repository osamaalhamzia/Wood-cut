import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'packing.dart';
import 'theme.dart';
import 'utils.dart';

/// رسم مخطط اللوح (البعد الأطول أفقياً دائماً لسهولة القراءة).
class BoardViz extends StatelessWidget {
  const BoardViz({super.key, required this.plan, this.maxHeight = 420});

  final BoardPlan plan;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final swap = plan.height > plan.width;
    final vw = swap ? plan.height : plan.width;
    final vh = swap ? plan.width : plan.height;
    final ratio = (vw > 0 && vh > 0) ? vw / vh : 1.0;

    return Semantics(
      label: 'مخطط اللوح رقم ${plan.index}',
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: AspectRatio(
            aspectRatio: ratio,
            child: CustomPaint(painter: _BoardPainter(plan, swap)),
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.plan, this.swap);

  final BoardPlan plan;
  final bool swap;

  TextPainter _tp(String text, double fs, Color color) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fs, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final vw = swap ? plan.height : plan.width;
    if (vw <= 0) return;
    final s = size.width / vw;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, Paint()..color = AppColors.inset);

    for (final p in plan.placed) {
      final x = swap ? p.y : p.x;
      final y = swap ? p.x : p.y;
      final w = swap ? p.height : p.width;
      final h = swap ? p.width : p.height;

      final rect = Rect.fromLTWH(
        (x + 0.3) * s,
        (y + 0.3) * s,
        math.max(w - 0.6, 0.4) * s,
        math.max(h - 0.6, 0.4) * s,
      );

      final solid = Color(0xFF000000 | p.color);
      canvas.drawRect(rect, Paint()..color = Color((0x47 << 24) | p.color));
      canvas.drawRect(
        rect,
        Paint()
          ..color = solid
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.5 * s, 1.0),
      );

      final labelCm = math.min(w, h) * 0.28;
      if (labelCm > 3.2 && w > 14) {
        final text = '${fmtNum(p.width)}×${fmtNum(p.height)}';
        var fs = labelCm * s;
        var tp = _tp(text, fs, solid);
        final maxW = rect.width - 4;
        if (maxW > 0 && tp.width > maxW) {
          fs = fs * maxW / tp.width;
          tp = _tp(text, fs, solid);
        }
        if (maxW > 0 && fs >= 6) {
          tp.paint(
            canvas,
            Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
          );
        }
      }
    }

    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      old.plan != plan || old.swap != swap;
}

/// شعار التطبيق
class LogoIcon extends StatelessWidget {
  const LogoIcon({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 36;
    final stroke = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2 * k, 2 * k, 32 * k, 32 * k),
        Radius.circular(4 * k),
      ),
      stroke,
    );
    canvas.drawLine(Offset(2 * k, 20 * k), Offset(22 * k, 20 * k), stroke);
    final faint = Paint()
      ..color = const Color(0x8025E4D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k;
    canvas.drawLine(Offset(22 * k, 2 * k), Offset(22 * k, 34 * k), faint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
