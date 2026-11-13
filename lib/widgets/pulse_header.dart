import 'package:flutter/material.dart';

/// App logo: a heart with an ECG line behind it ("a doctor for your car"),
/// drawn in code so no image assets are needed.
class PulseHeader extends StatelessWidget {
  const PulseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        SizedBox(
          height: 120,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: PulseLinePainter(primary.withAlpha(150)),
                ),
              ),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: primary, width: 3),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.favorite, size: 48, color: primary),
                    const Icon(Icons.build, size: 22, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w300),
            children: [
              const TextSpan(text: 'Auto'),
              TextSpan(
                text: 'Aid',
                style: TextStyle(fontWeight: FontWeight.w800, color: primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PulseLinePainter extends CustomPainter {
  PulseLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    final path = Path()
      ..moveTo(0, mid)
      ..lineTo(w * 0.28, mid)
      ..lineTo(w * 0.33, mid - h * 0.12)
      ..lineTo(w * 0.38, mid + h * 0.10)
      ..lineTo(w * 0.43, mid)
      ..lineTo(w * 0.57, mid)
      ..lineTo(w * 0.62, mid - h * 0.40)
      ..lineTo(w * 0.68, mid + h * 0.36)
      ..lineTo(w * 0.73, mid)
      ..lineTo(w, mid);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(PulseLinePainter old) => old.color != color;
}
