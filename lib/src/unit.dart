///Used for unit representation.
///The constantss in this class are units recommended by the the homie convention.
///Custom units are valid, too.
class Unit {
  static const Unit none = const Unit('');
  static const Unit degreeCelsius = const Unit('°C');
  static const Unit degreeFahrenheit = const Unit('°F');
  static const Unit degree = const Unit('°');
  static const Unit liter = const Unit('L');
  static const Unit galon = const Unit('gal');
  static const Unit volts = const Unit('V');
  static const Unit watt = const Unit('W');
  static const Unit ampere = const Unit('A');
  static const Unit percent = const Unit('%');
  static const Unit meter = const Unit('m');
  static const Unit feet = const Unit('ft');
  static const Unit pascal = const Unit('Pa');
  static const Unit psi = const Unit('psi');
  static const Unit count = const Unit('#');

  final String _unit;
  const Unit(String unit)
      : assert(unit != null),
        this._unit = unit;

  @override
  String toString() {
    return _unit;
  }
}
