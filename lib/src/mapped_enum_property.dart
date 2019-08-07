import 'package:homie_dart/src/utils.dart';
import 'package:meta/meta.dart';

import 'model.dart';
import 'homie_datatype.dart';
import 'unit.dart';

///An implementation of the homie enum datatype property that requires to be linked to a dart enum.
///If you don not want to use a dart enum for the property but rather a [List<String>]
///as underyling representaion, take a look at the [EnumProperty] class.
///The type argument of this class should be an enum.
class MappedEnumProperty<K> extends Property<K, MappedEnumProperty<K>> {
  final Map<String, K> _names;

  ///Creates a new property with this unique, valie [propertyId]. See [isValidId].
  ///
  ///The optional [name] should be human readable.
  ///
  ///If this is a [settable] property, an [EventLister] may be registered for it,
  ///and the property is able to receive commands. If not given, settable defaults to [false].
  ///
  ///[values] maps a name (String representation) to the enum value.
  ///The name can be choosen arbitrary and does not have to be
  ///equal to what the toString() method of the enum value would return.
  ///The members of this map are the only valid values this proeprty can be.
  ///This means, other values of the underlying dart enum, which are not part of this map,
  ///are not valid values for this property!
  ///
  ///If unit is [null], [Unit.none] will be used.
  ///
  ///The [extensions] can extend this property, see the [PropertyExtension] class.
  ///It is not allowed to modify the [extensions] after this point!
  MappedEnumProperty(
      {@required String propertyId,
      Iterable<PropertyExtension> extensions,
      String name,
      bool settable,
      Unit unit,
      @required Map<String, K> values})
      : assert(values != null),
        this._names = values,
        super(
            extensions: extensions,
            propertyId: propertyId,
            name: name,
            unit: unit,
            settable: settable,
            dataType: HomieDatatype.typeEnum,
            format: asEnumString(values.keys));

  ///Converts [s], as recieved from the message broker, to an value object.
  ///Converting works by looking up the name of the value in the [names] map given in the constructor.
  ///Therefor, it is an error if [s] is not part of the map!
  @override
  K stringRepresentationToValue(String s) {
    assert(_names.containsKey(s), 'The value "$s" is not part of this enum!');
    return _names[s];
  }

  ///Converts an value of type [K] to its String representation, which is then send to the message broker.
  ///This works by looking up the name for the [value] in the [names] map given in the constructor.#
  ///Therefor, it is an error if [value] is not part of the map!
  @override
  String valueToStringRepresentation(K value) {
    for (MapEntry<String, K> entry in _names.entries) {
      if (value == entry.value) {
        return entry.key;
      }
    }
    throw new Exception('Value $value does not seem to be an enum member!');
  }
}

///A retained version of [MappedEnumProperty].
///See [RetainedMixin] and [MappedEnumProperty] for more information.
class MappedEnumPropertyRetained<K> extends MappedEnumProperty<K>
    with RetainedMixin<K, MappedEnumProperty<K>> {
  MappedEnumPropertyRetained(
      {@required String propertyId,
      Iterable<PropertyExtension> extensions,
      String name,
      bool settable,
      Unit unit,
      @required Map<String, K> values,
      @required K initialValue})
      : assert(initialValue != null),
        assert(values != null),
        assert(values.values.contains(initialValue)),
        super(
            extensions: extensions,
            unit: unit,
            propertyId: propertyId,
            name: name,
            settable: settable,
            values: values) {
    withInitialValue(initialValue);
  }
}
