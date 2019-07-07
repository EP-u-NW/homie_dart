import 'package:meta/meta.dart';

import 'model.dart';
import 'homie_datatype.dart';
import 'utils.dart';
import 'constants.dart';
import 'colors.dart';
import 'unit.dart';

///A property to represent the homie String datatype.
class StringProperty extends Property<String, StringProperty> {
  ///Creates a new property with this unique, valie [propertyId]. See [isValidId].
  ///
  ///The optional [name] should be human readable.
  ///
  ///If this is a [settable] property, an [EventListener] may be registered for it,
  ///and the property is able to receive commands. If not given, settable defaults to [false].
  ///
  ///If unit is [null], [Unit.none] will be used.
  StringProperty(
      {@required String propertyId, String name, Unit unit, bool settable})
      : super(
            propertyId: propertyId,
            name: name,
            unit: unit,
            settable: settable,
            dataType: HomieDatatype.typeString);

  ///Converts [s], as recieved from the message broker, to an value object.
  ///Converting from the String representation of the value (whis is also a String) is trivial.
  @override
  String stringRepresentationToValue(String s) {
    return s;
  }
}

///A retained version of [StringProperty].
///See [RetainedMixin] and [StringProperty] for more information.
class StringPropertyRetained extends StringProperty
    with RetainedMixin<String, StringProperty> {
  StringPropertyRetained(
      {@required String propertyId,
      String name,
      Unit unit,
      bool settable,
      @required String initialValue})
      : assert(initialValue != null),
        super(
            propertyId: propertyId,
            name: name,
            unit: unit,
            settable: settable) {
    withInitialValue(initialValue);
  }
}

///A property to represent the homie Bool datatype.
class BooleanProperty extends Property<bool, BooleanProperty> {
  ///Creates a new property with this unique, valie [propertyId]. See [isValidId].
  ///
  ///The optional [name] should be human readable.
  ///
  ///If this is a [settable] property, an [EventListener] may be registered for it,
  ///and the property is able to receive commands. If not given, settable defaults to [false].
  BooleanProperty({@required String propertyId, String name, bool settable})
      : super(
            propertyId: propertyId,
            name: name,
            unit: null,
            settable: settable,
            dataType: HomieDatatype.typeBoolean);

  ///Converts [s], as recieved from the message broker, to an value object.
  ///The String representation has to be either "true" of "false". This is case sensitive!
  @override
  bool stringRepresentationToValue(String s) {
    assert(s == 'true' || s == 'false',
        'The String representation has to be either "true" of "false". This is case sensitive!');
    return s == 'true';
  }
}

///A retained version of [BooleanProperty].
///See [RetainedMixin] and [BooleanProperty] for more information.
class BooleanPropertyRetained extends BooleanProperty
    with RetainedMixin<bool, BooleanProperty> {
  BooleanPropertyRetained(
      {@required String propertyId,
      String name,
      bool settable,
      @required bool initialValue})
      : assert(initialValue != null),
        super(propertyId: propertyId, name: name, settable: settable) {
    withInitialValue(initialValue);
  }
}

///A property to represent the homie Integer datatype.
class IntegerProperty extends Property<int, IntegerProperty> {
  ///Creates a new property with this unique, valie [propertyId]. See [isValidId].
  ///
  ///The optional [name] should be human readable.
  ///
  ///If this is a [settable] property, an [EventListener] may be registered for it,
  ///and the property is able to receive commands. If not given, settable defaults to [false].
  ///
  ///Using [minValue] and [maxValue] the value range can be specified.
  ///The following has to be true: [homieIntMin] <= [minValue] <= [maxValue] <= [homieIntMax].
  ///If [minValue] is not [null] but [maxValue] is, [homieIntMax] is used instead.
  ///If [maxValue] is not [null] but [minValue] is, [homieIntMin] is used instead.
  ///
  ///If unit is [null], [Unit.none] will be used.
  IntegerProperty(
      {@required String propertyId,
      String name,
      Unit unit,
      int minValue,
      int maxValue,
      bool settable})
      : super(
            propertyId: propertyId,
            name: name,
            unit: unit,
            settable: settable,
            dataType: HomieDatatype.typeInteger,
            format: _format(minValue, maxValue));

  static String _format(int min, int max) {
    if (min == null && max == null) {
      return null;
    } else if (min != null && max != null) {
      assert(inOrder(<int>[homieIntMin, min, max, homieIntMax]),
          'The follwing does not hold: homieIntMin <= minValue <= maxValue <= homieIntMax. That is not allowed!');
      return '$min:$max';
    } else {
      return _format(min ?? homieIntMin, max ?? homieIntMax);
    }
  }

  static bool _validInt(int value) {
    return inOrder(<int>[homieIntMin, value, homieIntMax]);
  }

  @override
  Future<Null> publishValue(int value) {
    assert(_validInt(value),
        'The value "$value" is not an valid integer according to the homie convention!');
    return super.publishValue(value);
  }

  ///Converts [s], as recieved from the message broker, to an value object.
  ///The String representation has to be a valid integer in range from [homieIntMin] to [homieIntMax].
  @override
  int stringRepresentationToValue(String s) {
    int i = int.parse(s);
    assert(_validInt(i),
        'The value "$s" is not an valid integer according to the homie convention!');
    return i;
  }
}

///A retained version of [IntegerProperty].
///See [RetainedMixin] and [IntegerProperty] for more information.
class IntegerPropertyRetained extends IntegerProperty
    with RetainedMixin<int, IntegerProperty> {
  IntegerPropertyRetained(
      {@required String propertyId,
      String name,
      Unit unit,
      int minValue,
      int maxValue,
      bool settable,
      @required int initialValue})
      : assert(initialValue != null),
        assert(IntegerProperty._validInt(initialValue)),
        super(
            propertyId: propertyId,
            name: name,
            unit: unit,
            settable: settable,
            minValue: minValue,
            maxValue: maxValue) {
    withInitialValue(initialValue);
  }
}

///A property to represent the homie Float datatype.
class FloatProperty extends Property<double, FloatProperty> {
  ///Creates a new property with this unique, valie [propertyId]. See [isValidId].
  ///
  ///The optional [name] should be human readable.
  ///
  ///If this is a [settable] property, an [EventListener] may be registered for it,
  ///and the property is able to receive commands. If not given, settable defaults to [false].
  ///
  ///Using [minValue] and [maxValue] the value range can be specified.
  ///The following has to be true: [homieFloatMin] <= [minValue] <= [maxValue] <= [homieFloatMax].
  ///If [minValue] is not [null] but [maxValue] is, [homieFloatMax] is used instead.
  ///If [maxValue] is not [null] but [minValue] is, [homieFloatMin] is used instead.
  ///
  ///If unit is [null], [Unit.none] will be used.
  FloatProperty(
      {@required String propertyId,
      String name,
      Unit unit,
      double minValue,
      double maxValue,
      bool settable})
      : super(
            propertyId: propertyId,
            name: name,
            unit: unit,
            settable: settable,
            dataType: HomieDatatype.typeFloat,
            format: _format(minValue, maxValue));

  static String _format(double min, double max) {
    if (min == null && max == null) {
      return null;
    } else if (min != null && max != null) {
      assert(inOrder(<double>[homieFloatMin, min, max, homieFloatMax]),
          'The follwing does not hold: homieFloatMin <= minValue <= maxValue <= homieFloatMax. That is not allowed!');
      return '$min:$max';
    } else {
      return _format(min ?? homieFloatMin, max ?? homieFloatMax);
    }
  }

  static bool _validFloat(double value) {
    return inOrder(<double>[homieFloatMin, value, homieFloatMax]);
  }

  @override
  Future<Null> publishValue(double value) {
    assert(_validFloat(value),
        'The value "$value" is not an valid float according to the homie convention!');
    return super.publishValue(value);
  }

  ///Converts [s], as recieved from the message broker, to an value object.
  ///The String representation has to be a valid float in range from [homieFloatMin] to [homieFloatMax].
  @override
  double stringRepresentationToValue(String s) {
    double d = double.parse(s);
    assert(_validFloat(d),
        'The value "$s" is not an valid float according to the homie convention!');
    return d;
  }
}

///A retained version of [FloatProperty].
///See [RetainedMixin] and [FloatProperty] for more information.
class FloatPropertyRetained extends FloatProperty
    with RetainedMixin<double, FloatProperty> {
  FloatPropertyRetained(
      {@required String propertyId,
      String name,
      Unit unit,
      double minValue,
      double maxValue,
      bool settable,
      @required double initialValue})
      : assert(initialValue != null),
        assert(FloatProperty._validFloat(initialValue)),
        super(
            propertyId: propertyId,
            name: name,
            unit: unit,
            settable: settable,
            minValue: minValue,
            maxValue: maxValue) {
    withInitialValue(initialValue);
  }
}

///A property to represent the homie Color datatype inf hsv format.
class HsvColorProperty extends Property<HsvColor, HsvColorProperty> {
  ///Creates a new property with this unique, valie [propertyId]. See [isValidId].
  ///
  ///The optional [name] should be human readable.
  ///
  ///If this is a [settable] property, an [EventListener] may be registered for it,
  ///and the property is able to receive commands. If not given, settable defaults to [false].
  HsvColorProperty({@required String propertyId, String name, bool settable})
      : super(
            propertyId: propertyId,
            name: name,
            unit: null,
            settable: settable,
            dataType: HomieDatatype.typeColor,
            format: 'hsv');

  @override
  HsvColor stringRepresentationToValue(String s) {
    return new HsvColor.parse(s);
  }
}

///A retained version of [HsvColorProperty].
///See [RetainedMixin] and [HsvColorProperty] for more information.
class HsvColorPropertyRetained extends HsvColorProperty
    with RetainedMixin<HsvColor, HsvColorProperty> {
  HsvColorPropertyRetained(
      {@required String propertyId,
      String name,
      bool settable,
      @required HsvColor initialValue})
      : assert(initialValue != null),
        super(propertyId: propertyId, name: name, settable: settable) {
    withInitialValue(initialValue);
  }
}

///A property to represent the homie Color datatype inf rgb format.
class RgbColorProperty extends Property<RgbColor, RgbColorProperty> {
  ///Creates a new property with this unique, valie [propertyId]. See [isValidId].
  ///
  ///The optional [name] should be human readable.
  ///
  ///If this is a [settable] property, an [EventListener] may be registered for it,
  ///and the property is able to receive commands. If not given, settable defaults to [false].
  RgbColorProperty({@required String propertyId, String name, bool settable})
      : super(
            propertyId: propertyId,
            name: name,
            unit: null,
            settable: settable,
            dataType: HomieDatatype.typeColor,
            format: 'rgb');
  @override
  RgbColor stringRepresentationToValue(String s) {
    return new RgbColor.parse(s);
  }
}

///A retained version of [RgbColorProperty].
///See [RetainedMixin] and [RgbColorProperty] for more information.
class RgbColorPropertyRetained extends RgbColorProperty
    with RetainedMixin<RgbColor, RgbColorProperty> {
  RgbColorPropertyRetained(
      {@required String propertyId,
      String name,
      bool settable,
      @required RgbColor initialValue})
      : assert(initialValue != null),
        super(propertyId: propertyId, name: name, settable: settable) {
    withInitialValue(initialValue);
  }
}

///A property to represent the homie Enum datatype,
///based on a list of possible String values.
///If you want use a real dart enum as base for this property,
///and not a [List<String>] take a look at [MappedEnumProperty].
class EnumProperty extends Property<String, EnumProperty> {
  ///Creates a new property with this unique, valie [propertyId]. See [isValidId].
  ///
  ///The optional [name] should be human readable.
  ///
  ///If this is a [settable] property, an [EventListener] may be registered for it,
  ///and the property is able to receive commands. If not given, settable defaults to [false].
  ///
  ///The list [values] contains all values that belong to the enum,
  ///and are the only valid values this property can represent.
  ///
  ///If unit is [null], [Unit.none] will be used.
  EnumProperty(
      {@required String propertyId,
      String name,
      Unit unit,
      @required List<String> values,
      bool settable})
      : assert(enumValuesValid(values)),
        super(
            propertyId: propertyId,
            name: name,
            unit: unit,
            settable: settable,
            dataType: HomieDatatype.typeEnum,
            format: asEnumString(values));

  bool _enumContains(String value) {
    return format.split(',').contains(value);
  }

  @override
  Future<Null> publishValue(String value) {
    assert(
        _enumContains(value), 'The value "$value" is not part of this enum!');
    return super.publishValue(value);
  }

  ///Converts [s], as recieved from the message broker, to an value object.
  ///Converting from the String representation of the value is trivial since enum values are represented as Strings,
  ///but [s] has to be part of this enum.
  @override
  String stringRepresentationToValue(String s) {
    assert(_enumContains(s), 'The value "$s" is not part of this enum!');
    return s;
  }
}

///A retained version of [EnumProperty].
///See [RetainedMixin] and [EnumProperty] for more information.
class EnumPropertyRetained extends EnumProperty
    with RetainedMixin<String, EnumProperty> {
  EnumPropertyRetained(
      {@required String propertyId,
      String name,
      @required List<String> values,
      bool settable,
      @required String initialValue})
      : assert(initialValue != null),
        assert(values.contains(initialValue)),
        super(
            propertyId: propertyId,
            name: name,
            values: values,
            settable: settable) {
    withInitialValue(initialValue);
  }
}
