import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import 'broker_connection.dart';
import 'constants.dart';
import 'utils.dart';
import 'unit.dart';
import 'homie_datatype.dart';

///Baseclass for [Device], [Node] and [Property]
abstract class HomieTopic<E extends Extension> {
  String get fullId;
  List<E> get extensions;
  Future<Null> _publish(String topic, String content,
      [bool retained = true, int qos]);

  V getExtension<V extends E>() {
    return extensions.firstWhere((E e) => e.runtimeType == V);
  }
}

abstract class Extension {
  const Extension();

  Future<Null> publish(HomieTopic base, String topic, String content,
      [bool retained = true, int qos]) {
    return base._publish(topic, content, retained, qos);
  }
}

abstract class DeviceExtension extends Extension {
  String get version;
  String get extensionId;
  List<String> get homieVersions;
  String get extensionsEntry =>
      '$extensionId:$version:[${homieVersions.join(';')}]';

  const DeviceExtension();

  Future<Null> onStateChange(Device device, DeviceState state);
}

abstract class NodeExtension extends Extension {
  const NodeExtension();
  Type get deviceExtension;
  Future<Null> onPublishNode(Node n);
  Future<Null> onUnpublishNode(Node n);
}

abstract class PropertyExtension extends Extension {
  const PropertyExtension();
  Type get deviceExtension;
  Future<Null> onPublishProperty(Property p);
  Future<Null> onUnpublishProperty(Property p);
}

///Subclass this class to create a new homie device.
abstract class Device extends HomieTopic<DeviceExtension> {
  BrokerConnection _broker;
  DeviceState _deviceState;

  ///The full qualified topic Id of this device including the [root].
  String get fullId => '${root ?? ''}$deviceId';

  ///The root of this devices topics. The homie convention proposes 'homie', which is the default value.
  final String root;

  ///The unique Id of this device, which must be an valid homie Id. See [isValidId].
  final String deviceId;

  ///The human readable name of the device.
  final String name;

  ///The version of the homie convention this device impelements. Defaults to 3.0.1.
  final String conventionVersion;

  ///The implementation name of this device. For more information see the [Device] constructor documentation.
  final String implementation;

  ///This List contains all [Node]s that are part of this device. It is not allowed to modify this list!
  final List<Node> nodes;

  final List<DeviceExtension> extensions;

  ///Returns the state of this device.
  DeviceState get deviceState => _deviceState;

  ///Creates a new device.
  ///The topic structure will follow the homie convention.
  ///
  ///A [deviceId] that follows the id guidlines is needed, see [isValidId] for more details.
  ///
  ///Every device needs a human readable [name].
  ///
  ///The [implementation] is an arbitrary String, prererably camelCase, which denotes something about your implementation of the device.
  ///Since you are using the dart library, it is recommended to sufix it with "Dart".
  ///For example, the [implementation] of the "Color+" light bulb from the vendor "EPNW" with this library might be "epnwColorPlusDart".
  ///
  ///The homie convention demands, that the stats about a device are peroidically published. With this library, this happens automatically.
  ///As long as the [deviceState] is [DeviceState.ready] the stats will be published every [statsIntervall] seconds.
  ///This value must not be [null] and greater than 0.
  ///
  ///The [nodes] of this device may be empty but not [null].
  ///All nodes that the device got need to be part of this iterable.
  ///It is not possible to add or remove nodes later.
  ///
  ///Its recommended to don't set the [root] property, then the [defaultRoot] topic will be used.
  ///
  ///[conventionVersion] gives the version of the homie convention this device follows.
  ///It is recommended to pass [null] for this field, then the [defaultConventionVersion] is used.
  ///When using this library, the homie convention version is 3.0.1, so it is unreasonable to give any other value here.
  ///
  ///It is recommended to pass [null] to the [localIp] and [mac] properties
  ///and set the [defaultIp] and [defaultMac] top-level properties to the appropriate values instead.
  ///This way, all devices running in the same instance will have the same value.
  ///
  ///It is allso recommended to pass [null] to the [firmwareName] and [firmwareVersion],
  ///then the [defaultFirmwareName] and [defaultFirmwareVersion] are used.
  ///These values then indicate, that this device implementation was made using this library.
  ///
  ///The [stats] give information about the device. You can preconfigure the [stats] with custom initial values and pass them here.
  ///If the [stats] are [null], a new [DeviceStats] object will be created.
  ///In this case, the uptime of this [Device] will be counted since creation of the object.
  Device(
      {String root,
      @required deviceId,
      @required String name,
      String conventionVersion,
      @required String implementation,
      @required Iterable<Node> nodes,
      Iterable<DeviceExtension> extensions})
      : assert(isValidId(deviceId)),
        assert(validString(name)),
        assert(validString(implementation)),
        assert(nodes != null),
        this.root = root ?? defaultRoot,
        this.implementation = implementation,
        this.deviceId = deviceId,
        this.name = name,
        this.conventionVersion = conventionVersion ?? defaultConventionVersion,
        this.nodes = new List<Node>.unmodifiable(nodes),
        this.extensions = new List<DeviceExtension>.unmodifiable(
            extensions ?? <DeviceExtension>[]) {
    nodes.forEach((Node n) => n._setDevice(this));
    nodes.forEach((Node n) => n._assertExtensions());
  }

  ///returns the [Node] with this nodeId, or [null] if no node with this nodeId is part of this device.
  Node getNode(String nodeId) {
    return nodes.firstWhere((Node n) => n.nodeId == nodeId);
  }

  ///Inits the device, etablishes a connection to the mqtt broker and sets appropriate last will topics.
  ///The initalisation ends with an automatic call to [ready].
  ///It is invalid to call this method if the [deviceState] has any value other than [null].
  ///This means, even a disconnected device can not be connected again by calling [init].
  ///
  ///The [broker] musst be unique and might not be used in the [init] call of an other device.
  ///Create a new [BrokerConnection] for each device!
  Future<Null> init(BrokerConnection broker) async {
    assert(deviceState == null, 'State must be null to init a device!');
    _broker = broker;
    await _broker.connect('$fullId/\$state', payload('lost'), true, qos);
    _deviceState = DeviceState.init;
    await _publish('$fullId/\$state', 'init');
    await _publish(
        '$fullId/\$extensions',
        extensions
            .map<String>(
                (DeviceExtension extension) => extension.extensionsEntry)
            .join(','));
    await _publish('$fullId/\$homie', conventionVersion);
    await _publish('$fullId/\$name', name);
    await _publish('$fullId/\$implementation', implementation);
    String nodesIds = nodes.map((Node n) => n.nodeId).join(',');
    await _publish('$fullId/\$nodes', nodesIds);
    for (Node n in nodes) {
      await n._sendNode();
    }
    for (DeviceExtension e in extensions) {
      await e.onStateChange(this, DeviceState.init);
    }
    await ready();
  }

  Future<Null> _forgetDevice() async {
    await _publish('$fullId/\$extensions', emptyPayload);
    await _publish('$fullId/\$homie', emptyPayload);
    await _publish('$fullId/\$name', emptyPayload);
    await _publish('$fullId/\$implementation', emptyPayload);
    await _publish('$fullId/\$nodes', emptyPayload);
    for (Node n in nodes) {
      await n._forgetNode();
    }
  }

  ///After the future returned by this devices is done your device will be in the ready state and good to operate.
  ///Only call manually when [deviceState] is sleeping or alert, any other case will throw an assertion.
  ///While the device is ready, that stats will automatically be published according to [statsIntervall].
  Future<Null> ready() async {
    assert(
        deviceState == DeviceState.alert ||
            deviceState == DeviceState.init ||
            deviceState == DeviceState.sleeping,
        'Can only go into the ready state from the alert, init or sleeping state.');
    await _publish('$fullId/\$state', 'ready');
    for (DeviceExtension e in extensions) {
      await e.onStateChange(this, DeviceState.ready);
    }
    _deviceState = DeviceState.ready;
  }

  ///Puts the device into sleep state. While sleeping, sending status is paused.
  Future<Null> sleep() async {
    assert(
        (const <DeviceState>[
          DeviceState.alert,
          DeviceState.ready,
          DeviceState.sleeping
        ])
            .contains(deviceState),
        'Can only go into the sleeping state from the alert, ready or sleeping state.');
    await _publish('$fullId/\$state', 'sleeping');
    for (DeviceExtension e in extensions) {
      await e.onStateChange(this, DeviceState.sleeping);
    }
    _deviceState = DeviceState.sleeping;
  }

  ///You can put the device in alert state to denote an error which requires an user action.
  ///Entering this state will suspend the status updates.
  Future<Null> alert() async {
    assert(
        (const <DeviceState>[
          DeviceState.alert,
          DeviceState.ready,
          DeviceState.sleeping
        ])
            .contains(deviceState),
        'Can only go into the alert state from the alert, ready or sleeping state.');
    await _publish('$fullId/\$state', 'alert');
    for (DeviceExtension e in extensions) {
      await e.onStateChange(this, DeviceState.alert);
    }
    _deviceState = DeviceState.alert;
  }

  ///Disconnects the device and the [BrokerConnection].
  ///You can never use this object instance again!
  ///See the remarks in [init].
  Future<Null> disconnect() async {
    assert(
        (const <DeviceState>[
          DeviceState.alert,
          DeviceState.ready,
          DeviceState.sleeping
        ])
            .contains(deviceState),
        'Can only go into the disconnected state from the alert, ready or sleeping state.');
    await _publish('$fullId/\$state', 'disconnected');
    await _forgetDevice();
    for (DeviceExtension e in extensions) {
      await e.onStateChange(this, DeviceState.disconnected);
    }
    await _broker.disconnect();
    _deviceState = DeviceState.disconnected;
  }

  Future<Null> _publish(String topic, String content,
      [bool retained = true, int _qos]) {
    assert(
        (const <DeviceState>[
          DeviceState.alert,
          DeviceState.init,
          DeviceState.ready,
          DeviceState.sleeping
        ])
            .contains(deviceState),
        'This device can not publish values since it is not in a valid state for publishing! Allowed states are alert, init, ready or sleeping.');
    return _broker.publish(topic, payload(content), retained, _qos ?? qos);
  }
}

///A enum for all device states defined by the homie convention.
enum DeviceState { init, ready, disconnected, sleeping, lost, alert }

///This class represents a homie node. Nodes are added to devices.
///Each node object must only be part of one device!
class Node extends HomieTopic<NodeExtension> {
  Device _device;

  void _setDevice(Device d) {
    assert(_device == null, 'This node is already part of another device!');
    _device = d;
  }

  void _assertExtensions() {
    Iterable<Type> supportedTypes =
        _device.extensions.map<Type>((DeviceExtension e) => runtimeType);
    for (NodeExtension e in extensions) {
      assert(e.deviceExtension != null,
          'The deviceExtension property of a NodeExtension must not be null! See the documentation!');
      assert(supportedTypes.contains(e.deviceExtension),
          'The extension $e must only be added to devices which provide an extension of type ${e.deviceExtension}');
    }
    properties.forEach((Property p) => p._assertExtensions());
  }

  ///The device this node belongs to.
  Device get device => _device;

  ///The unique Id of this node, which must be an valid homie Id. See [isValidId].
  final String nodeId;

  final List<NodeExtension> extensions;

  ///The full qualified topic Id of this node. It is only valid to call this on a node which is part of a device!
  String get fullId {
    assert(_device != null, 'This node is not part of a device');
    return '${_device.fullId}/$nodeId';
  }

  ///The human readable name of this node.
  final String name;

  ///The type of this node.
  final String type;

  ///This List contains all [Property]s that are part of this node. It is not allowed to modify this list!
  final List<Property> properties;
  Node(
      {@required String nodeId,
      @required String name,
      @required String type,
      @required Iterable<Property> properties,
      Iterable<NodeExtension> extensions})
      : assert(validString(nodeId)),
        assert(validString(name)),
        assert(validString(type)),
        assert(properties != null),
        this.nodeId = nodeId,
        this.name = name,
        this.type = type,
        this.properties = new List<Property>.unmodifiable(properties),
        this.extensions = new List<NodeExtension>.unmodifiable(
            extensions ?? <NodeExtension>[]) {
    properties.forEach((Property p) => p._setNode(this));
  }

  ///returns the [Property] with this propertyId, or [null] if no property with this propertyId is part of this node.
  Property getProperty(String propertyId) {
    return properties.firstWhere((Property p) => p.propertyId == propertyId);
  }

  Future<Null> _forgetNode() async {
    await _publish('$fullId/\$name', emptyPayload);
    await _publish('$fullId/\$type', emptyPayload);
    await _publish('$fullId/\$properties', emptyPayload);
    for (NodeExtension e in extensions) {
      await e.onUnpublishNode(this);
    }
    for (Property p in properties) {
      await p._forgetProperty();
    }
  }

  Future<Null> _sendNode() async {
    await _publish('$fullId/\$name', name);
    await _publish('$fullId/\$type', type);
    String propertyIds = properties.map((Property p) => p.propertyId).join(',');
    await _publish('$fullId/\$properties', propertyIds);
    for (NodeExtension e in extensions) {
      await e.onPublishNode(this);
    }
    for (Property p in properties) {
      await p._sendProperty();
    }
  }

  Future<Null> _publish(String topic, String content,
      [bool retained = true, int qos]) {
    assert(device != null,
        'This node can not publish values as it is not part of a device!');
    return _device._publish(topic, content, retained, qos);
  }
}

///Triggered when an settable [property] receives a set [command].
///If the property is retained, the [publishValue] method should be executed with the new value of this property,
///to let the homie controller know, that the set command was processed.
typedef Future<Null> EventListener<T, V extends Property<T, V>>(
    V property, T command);

///Mixin this to make a [Property] retained.
///In the constructor of your property you have to call the [withInitialValue()] method with a initial value for the property.
///A retained property stores the current value of the property.
///The stored value is updated by a call to [publishValue].
mixin RetainedMixin<T, V extends Property<T, V>> on Property<T, V> {
  T _value;
  T get value => _value;

  ///Sets the initial value of this retained property. Must be called in the constructor of a retained property,
  ///and then must not be called again.
  void withInitialValue(T initialValue) {
    _value = initialValue;
  }
}

///Represents a homie property.
///Properties can be added to [Node]s which then are added to devices.
///Each property must only be part of one node!
///There are implementations properties with all datatypes as defined in the homie convention, in a non-retained and in a retained variant.
///The typeargument [T] denotes the representation of the value of the property.
///For most datatypes, homie uses Strings, so the property class is responsible to translate its value to a String and vice versa.
///The typeargument [V] is needed so that an [EventListener] knows, of what type the property is.
abstract class Property<T, V extends Property<T, V>> extends HomieTopic<PropertyExtension> {
  EventListener<T, V> _listener;

  Node _node;

  void _setNode(Node n) {
    assert(_node == null, 'This property is already part of another node');
    _node = n;
  }

  void _assertExtensions() {
    Iterable<Type> supportedTypes =
        _node._device.extensions.map<Type>((DeviceExtension e) => runtimeType);
    for (PropertyExtension e in extensions) {
      assert(e.deviceExtension != null,
          'The deviceExtension property of a PropertyExtension must not be null! See the documentation!');
      assert(supportedTypes.contains(e.deviceExtension),
          'The extension $e must only be added to devices which provide an extension of type ${e.deviceExtension}');
    }
  }

  ///The node this property belongs to.
  Node get node => _node;

  ///The full qualified topic Id of this property. It is only valid to call this on a property which is part of a node!
  String get fullId {
    assert(_node != null, 'This property is not part of a node');
    return '${_node.fullId}/$propertyId';
  }

  ///The dataType of this property according to the homie convention.
  final HomieDatatype dataType;

  ///The unique Id of this property, which must be an valid homie Id. See [isValidId].
  final String propertyId;

  ///The human readable name of this property.
  final String name;

  ///If this property is settable.
  final bool settable;

  ///The unit of measurement of this property.
  final Unit unit;

  ///The format of this property. For more information see the homie convention.
  final String format;

  ///If this property is retained. See [RetainedMixin].
  bool get retained => this is RetainedMixin<T, V>;

  final List<PropertyExtension> extensions;

  EventListener<T, V> get listener => _listener;

  ///Sets the [EventListener] of this property.
  ///A property may only have an [EventListener] if it is [settable].
  ///The [EventListener] is called if the settable property receives a command.
  void set listener(EventListener<T, V> listener) {
    assert(settable, 'Property not settable!');
    _listener = listener;
  }

  void _informListener(dynamic d) {
    if (listener != null) {
      listener(this as V, d as T);
    }
  }

  ///Publishes a new [value] for this property.
  ///If this property is [retained], the value of the [RetainedMixin] is also updated.
  ///
  ///Awaiting the returned future guarantees the publishing of the message to the broker with respect to the quality of service [qos].
  Future<Null> publishValue(T value) {
    assert(node?.device?.deviceState == DeviceState.ready,
        'This property cannot publish values since it is not part of of device which state is ready.');
    if (this is RetainedMixin<T, V>) {
      (this as RetainedMixin<T, V>)._value = value;
    }
    return _publish(fullId, valueToStringRepresentation(value), retained);
  }

  ///Converts an value of type [T] to its String representation, which is then send to the message broker.
  ///The base implementation of this is [ofType.toString], but subclasses may override this.
  String valueToStringRepresentation(T ofType) => ofType.toString();

  ///Converts [s], as recieved from the message broker, to an value object.
  T stringRepresentationToValue(String s);

  ///Creates a new property with this unique, valie [propertyId]. See [isValidId].
  ///
  ///The homie [dataType] must not be [null].
  ///
  ///The optional [name] should be human readable.
  ///
  ///If this is a [settable] property, an [EventListener] may be registered for it,
  ///and the property is able to receive commands. If not given, settable defaults to [false].
  ///
  ///Depending on the [dataType], [format] may be optional.
  ///
  ///If unit is [null], [Unit.none] will be used.
  Property(
      {@required String propertyId,
      String name,
      Unit unit,
      @required HomieDatatype dataType,
      bool settable,
      String format,
      Iterable<PropertyExtension> extensions})
      : this.extensions = new List<PropertyExtension>.unmodifiable(
            extensions ?? <PropertyExtension>[]),
        assert(isValidId(propertyId)),
        assert(dataType != null),
        this.name = name ?? '',
        this.settable = settable ?? false,
        this.propertyId = propertyId,
        this.unit = unit ?? Unit.none,
        this.dataType = dataType,
        this.format = format;

  Future<Null> _forgetProperty() async {
    await _publish('$fullId/\$name', emptyPayload);
    await _publish('$fullId/\$settable', emptyPayload);
    await _publish('$fullId/\$retained', emptyPayload);
    await _publish('$fullId/\$unit', emptyPayload);
    await _publish('$fullId/\$datatype', emptyPayload);
    if (format != null) {
      await _publish('$fullId/\$format', emptyPayload);
    }
    if (retained) {
      await _publish(fullId, emptyPayload);
    }
    for (PropertyExtension e in extensions) {
      await e.onUnpublishProperty(this);
    }
  }

  Future<Null> _sendProperty() async {
    await _publish('$fullId/\$name', name);
    await _publish('$fullId/\$settable', settable.toString());
    await _publish('$fullId/\$retained', retained.toString());
    await _publish('$fullId/\$unit', unit.toString());
    await _publish('$fullId/\$datatype', typeName[dataType]);
    if (format != null) {
      await _publish('$fullId/\$format', format);
    }
    if (settable) {
      Stream<List<int>> events =
          await _node._device._broker.subscribe('$fullId/set', qos);
      new Utf8Decoder()
          .bind(events)
          .map((String value) => stringRepresentationToValue(value))
          .forEach(_informListener);
    }
    if (retained) {
      String value =
          valueToStringRepresentation((this as RetainedMixin)._value);
      await _publish(fullId, value);
    }
    for (PropertyExtension e in extensions) {
      await e.onPublishProperty(this);
    }
  }

  Future<Null> _publish(String topic, String content,
      [bool retained = true, int qos]) {
    assert(node != null,
        'This property can not publish values as it is not part of a node');
    return _node._publish(topic, content, retained, qos);
  } 
}
