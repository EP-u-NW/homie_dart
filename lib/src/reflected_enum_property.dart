import 'dart:mirrors';

import 'package:meta/meta.dart';

import 'mapped_enum_property.dart';
import 'model.dart';
import 'unit.dart';

///A subclass of [MappedEnumProperty] that generates the [values] map automatically using reflection ([dart:mirrors]).
class ReflectedEnumProperty<K> extends MappedEnumProperty<K> {
  static bool _seemsValidEnum<V>() {
    try {
      _namesMap<V>();
      return true;
    } catch (e) {
      return false;
    }
  }

  static List<V> _values<V>() {
    return new List<V>.from(
        reflectClass(V).getField(new Symbol('values')).reflectee);
  }

  static Map<String, V> _namesMap<V>() {
    Map<String, V> names = new Map<String, V>();
    String typeName = reflectType(V).simpleName.toString();
    typeName = typeName.substring('Symbol("'.length);
    typeName = typeName.substring(0, typeName.length - '")'.length);
    String prefix = '$typeName.';
    for (V v in _values<V>()) {
      String name = v.toString();
      if (name.startsWith(prefix)) {
        names[name.substring(prefix.length)] = v;
      } else {
        throw new Exception('Type does not seem to be an enum!');
      }
    }
    return names;
  }

  ReflectedEnumProperty(
      {@required String propertyId, String name, bool settable, Unit unit})
      : assert(_seemsValidEnum<K>()),
        super(
            unit: unit,
            propertyId: propertyId,
            name: name,
            settable: settable,
            values: _namesMap<K>());
}

///A retained version of [ReflectedEnumProperty].
///See [RetainedMixin] and [ReflectedEnumProperty] for more information.
class ReflectedEnumPropertyRetained<K> extends ReflectedEnumProperty<K>
    with RetainedMixin<K, MappedEnumProperty<K>> {
  ReflectedEnumPropertyRetained(
      {@required String propertyId,
      String name,
      bool settable,
      Unit unit,
      @required K initialValue})
      : assert(initialValue != null),
        assert(
            ReflectedEnumProperty._namesMap<K>().values.contains(initialValue)),
        super(
          propertyId: propertyId,
          name: name,
          unit: unit,
          settable: settable,
        ) {
    withInitialValue(initialValue);
  }
}
