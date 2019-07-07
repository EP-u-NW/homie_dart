class HsvColor {
  ///Parses a color String (as defined by the homie convention) into a [HsvColor].
  ///Might throw a [FormatException] if the String is not in convetion format.
  factory HsvColor.parse(String s) {
    List<String> values = s.split(',');
    if (values.length == 3) {
      return new HsvColor(
          int.parse(values[0]), int.parse(values[1]), int.parse(values[2]));
    } else {
      throw new FormatException();
    }
  }

  ///Creates a new [HsvColor] based on a [RgbColor]
  ///During computation there might be nummeric erros, therefor if r is a [RgbColor] the expression
  ///[r == new RgbColor.fromHsvColor(new HsvColor.fromRgbColor(r))] might not hold true.
  factory HsvColor.fromRgbColor(RgbColor c) {
    int r = c.r;
    int g = c.g;
    int b = c.b;
    int max = r < g ? (g < b ? b : g) : (r < b ? b : r);
    int min = r > g ? (g > b ? b : g) : (r > b ? b : r);
    double d = (max - min).toDouble();
    double h;
    double s = (max == 0 ? 0.0 : d / max);
    double v = max / 255.0;
    if (max == min) {
      h = 0;
    } else if (max == r) {
      h = (g - b) + d * (g < b ? 6 : 0);
      h /= 6 * d;
    } else if (max == g) {
      h = (b - r) + d * 2;
      h /= 6 * d;
    } else if (max == b) {
      h = (r - g) + d * 4;
      h /= 6 * d;
    }
    return new HsvColor(
        (h * 360).floor(), (s * 100).floor(), (v * 100).floor());
  }

  ///The hue of the color. Ranges from 0 to 360.
  final int h;

  ///The saturation of the color. Ranges from 0 to 100.
  final int s;

  ///The value of the color. Ranges from 0 to 100.
  final int v;

  ///Creates a new [HsvColor].
  ///Hue [h] is a value from 0 to 360, saturation [s] and value [v] are between 0 and 100.
  HsvColor(int h, int s, int v)
      : assert(0 <= h && h <= 360),
        assert(0 <= s && s <= 100),
        assert(0 <= v && v <= 100),
        this.h = h,
        this.s = s,
        this.v = v;

  ///Retruns a color string based on the hue, saturation and value according to the homie convention as String.
  @override
  String toString() {
    return '$h,$s,$v';
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(dynamic other) {
    if (other is HsvColor) {
      return h == other.h && s == other.s && v == other.v;
    } else {
      return false;
    }
  }
}

class RgbColor {
  ///Parses a color String (as defined by the homie convention) into a [RgbColor].
  ///Might throw a [FormatException] if the String is not in convetion format.
  factory RgbColor.parse(String s) {
    List<String> values = s.split(',');
    if (values.length == 3) {
      return new RgbColor(
          int.parse(values[0]), int.parse(values[1]), int.parse(values[2]));
    } else {
      throw new FormatException();
    }
  }

  ///Creates a new [RgbColor] based on a [HsvColor]
  ///During computation there might be nummeric erros, therefor if r is a [RgbColor] the expression
  ///[r == new RgbColor.fromHsvColor(new HsvColor.fromRgbColor(r))] might not hold true.
  factory RgbColor.fromHsvColor(HsvColor c) {
    double h = c.h / 360.0;
    double s = c.s / 100.0;
    double v = c.v / 100.0;
    double r, g, b, f, p, q, t;
    int i = (h * 6).floor();
    f = h * 6 - i.toDouble();
    p = v * (1 - s);
    q = v * (1 - f * s);
    t = v * (1 - (1 - f) * s);
    switch (i % 6) {
      case 0:
        r = v;
        g = t;
        b = p;
        break;
      case 1:
        r = q;
        g = v;
        b = p;
        break;
      case 2:
        r = p;
        g = v;
        b = t;
        break;
      case 3:
        r = p;
        g = q;
        b = v;
        break;
      case 4:
        r = t;
        g = p;
        b = v;
        break;
      case 5:
        r = v;
        g = p;
        b = q;
        break;
    }
    return new RgbColor(
        (r * 255).round(), (g * 255).round(), (b * 255).round());
  }

  ///The red value of the color. Ranges from 0 to 255.
  final int r;

  ///The green value of the color. Ranges from 0 to 255.
  final int g;

  ///The blue value of the color. Ranges from 0 to 255.
  final int b;

  ///Creates a new [RgbColor].
  ///Red [r], green [b] and blue [b] are values from 0 to 255.
  RgbColor(int r, int g, int b)
      : assert(0 <= r && r <= 255),
        assert(0 <= g && g <= 255),
        assert(0 <= b && b <= 255),
        this.r = r,
        this.g = g,
        this.b = b;

  ///Retruns a color string based on red, green and blue value according to the homie convention as String.
  @override
  String toString() {
    return '$r,$g,$b';
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(dynamic other) {
    if (other is RgbColor) {
      return r == other.r && g == other.g && b == other.b;
    } else {
      return false;
    }
  }
}
