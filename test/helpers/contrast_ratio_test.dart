import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'contrast_ratio.dart';

void main() {
  group('contrastRatio', () {
    test('black on white returns 21:1', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      final ratio = contrastRatio(black, white);
      expect(ratio, closeTo(21.0, 0.1));
    });

    test('identical colors return 1:1', () {
      const color = Color(0xFF808080);
      final ratio = contrastRatio(color, color);
      expect(ratio, closeTo(1.0, 0.01));
    });

    test('is symmetric for fully opaque colors', () {
      const a = Color(0xFF333333);
      const b = Color(0xFFCCCCCC);
      expect(contrastRatio(a, b), equals(contrastRatio(b, a)));
    });

    test('white on white returns 1:1', () {
      const white = Color(0xFFFFFFFF);
      expect(contrastRatio(white, white), closeTo(1.0, 0.01));
    });

    test('dark gray on black returns low ratio', () {
      const black = Color(0xFF000000);
      const darkGray = Color(0xFF1A1A1A);
      final ratio = contrastRatio(black, darkGray);
      expect(ratio, lessThan(2.0));
    });

    test('WCAG AA pass: neutral950 on neutral100', () {
      // From KitColors: neutral950 = 0xFF0A0A0A, neutral100 = 0xFFF5F5F5
      const ink = Color(0xFF0A0A0A);
      const surface = Color(0xFFF5F5F5);
      final ratio = contrastRatio(ink, surface);
      expect(
        ratio,
        greaterThanOrEqualTo(wcagAANormalText),
        reason: 'neutral950 on neutral100 should pass WCAG AA',
      );
    });

    test('WCAG AA fail: light gray on white', () {
      const lightGray = Color(0xFFDDDDDD);
      const white = Color(0xFFFFFFFF);
      final ratio = contrastRatio(lightGray, white);
      expect(
        ratio,
        lessThan(wcagAANormalText),
        reason: 'light gray on white should fail WCAG AA',
      );
    });
  });

  group('alpha compositing', () {
    test('semi-transparent foreground is composited before contrast check', () {
      // Black at 50% alpha on white background composites to gray
      const semiBlack = Color(0x80000000);
      const white = Color(0xFFFFFFFF);

      final ratio = contrastRatio(semiBlack, white);
      // Composited color is ~#808080, ratio ~= 4.0 (not 21.0 as with raw RGB)
      expect(ratio, lessThan(5.0));
      expect(ratio, greaterThan(3.0));
    });

    test('fully opaque foreground is not affected by compositing', () {
      const opaque = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      final ratio = contrastRatio(opaque, white);
      expect(ratio, closeTo(21.0, 0.1));
    });

    test('very low alpha foreground has near 1:1 contrast', () {
      // White at 5% alpha on white background is still white -> 1:1
      const lowAlphaWhite = Color(0x0DFFFFFF);
      const white = Color(0xFFFFFFFF);
      final ratio = contrastRatio(lowAlphaWhite, white);
      expect(ratio, closeTo(1.0, 0.1));
    });

    test('is directional for semi-transparent colors', () {
      // Semi-transparent dark on light != semi-transparent light on dark
      const semiDark = Color(0x80000000);
      const light = Color(0xFFFFFFFF);
      const dark = Color(0xFF000000);

      final darkOnLight = contrastRatio(semiDark, light);
      final darkOnDark = contrastRatio(semiDark, dark);
      // Dark on light should have more contrast than dark on dark
      expect(darkOnLight, greaterThan(darkOnDark));
    });
  });

  group('compositedOver', () {
    test('returns foreground unchanged when fully opaque', () {
      const opaque = Color(0xFF123456);
      const bg = Color(0xFFFFFFFF);
      expect(compositedOver(opaque, bg), equals(opaque));
    });

    test('returns background when foreground is fully transparent', () {
      const transparent = Color(0x00000000);
      const bg = Color(0xFFABCDEF);
      final result = compositedOver(transparent, bg);
      // Alpha-blending fully transparent over bg should yield bg
      expect(result.r, closeTo(bg.r, 0.01));
      expect(result.g, closeTo(bg.g, 0.01));
      expect(result.b, closeTo(bg.b, 0.01));
    });
  });

  group('WCAG constants', () {
    test('wcagAANormalText is 4.5', () {
      expect(wcagAANormalText, equals(4.5));
    });

    test('wcagAALargeText is 3.0', () {
      expect(wcagAALargeText, equals(3.0));
    });
  });
}
