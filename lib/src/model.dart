import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import 'broker_connection.dart';
import 'constants.dart';
import 'utils.dart';
import 'unit.dart';
import 'homie_datatype.dart';

///Baseclass for [Device], [Node] and [Property]
abstract class HomieTopic {
  Future<Null> _publish(String topic, String content,
      [bool retained = true, int qos]);
}

abstract class Extension {
  Future<Null> publish(HomieTopic base, String topic, String content,
      [bool retained = true, int qos]) {
    return base._publish(topic, content, retained, qos);
  }
}

abstract class DeviceExtension extends Extension {
    final String version;
    final String extensionId;
    final List<String> homieVersions;
    String get extensionsEntry =>
        '$extensionId:$version:[${homieVersions.join(';')}]';

  void onStateChange(Device device, DeviceState state);
}

abstract class NodeExtension extends Extension {
  void onPublishNode(Node n);
  void onUnpublishNode(Node n);
}

abstract class PropertyExtension extends Extension {
  void onPublishProperty(Property p);
  void onUnpublishProperty(Property p);
}

///Subclass this class to create a new homie device.
abstract class Device extends HomieTopic {
  BrokerConnection _broker;
  Timer _statSender;
  DeviceState _deviceState;
  final DeviceStats _deviceStats;

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

  ///The ip of this device. For more information see the [Device] constructor documentation.
  final String localIp;

  ///The mac of this device. For more information see the [Device] constructor documentation.
  final String mac;

  ///The firmware name of this device. For more information see the [Device] constructor documentation.
  final String firmwareName;

  ///The firmware version of this device. For more information see the [Device] constructor documentation.
  final String firmwareVersion;

  ///The implementation name of this device. For more information see the [Device] constructor documentation.
  final String implementation;

  ///The intervall in seconds the [deviceStats] are published, as long as the [deviceState] is [DeviceState.ready].
  final int statsIntervall;

  ///This List contains all [Node]s that are part of this device. It is not allowed to modify this list!
  final List<Node> nodes;

  ///Returns the state of this device.
  DeviceState get deviceState => _deviceState;

  ///The stats of this device are periodically published to the mqtt broker.
  ///The stats can be accessed and modified.
  DeviceStats get deviceStats => _deviceStats;

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
      String localIp,
      String mac,
      String firmwareName,
      String firmwareVersion,
      @required String implementation,
      @required int statsIntervall,
      DeviceStats stats,
      @required Iterable<Node> nodes})
      : assert(isValidId(deviceId)),
        assert(validString(name)),
        assert(validString(implementation)),
        assert(statsIntervall != null),
        assert(statsIntervall > 0),
        assert(nodes != null),
        assert((mac ?? defaultMac) != null),
        assert((localIp ?? defaultIp) != null),
        this.root = root ?? defaultRoot,
        this.deviceId = deviceId,
        this.name = name,
        this.conventionVersion = conventionVersion ?? defaultConventionVersion,
        this.localIp = localIp ?? defaultIp,
        this.mac = mac ?? defaultMac,
        this.firmwareName = firmwareName ?? defaultFirmwareName,
        this.firmwareVersion = firmwareVersion ?? defaultFirmwareVersion,
        this.implementation = implementation,
        this.statsIntervall = statsIntervall,
        this._deviceStats = stats ?? new DeviceStats.sinceNow(),
        this.nodes = new List<Node>.unmodifiable(nodes) {
    for (Node n in nodes) {
      assert(n._device == null, 'This node is already part of another device!');
      n._device = this;
    }
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

    await _publish('$fullId/\$homie', conventionVersion);
    await _publish('$fullId/\$name', name);
    await _publish('$fullId/\$implementation', implementation);
    String nodesIds = nodes.map((Node n) => n.nodeId).join(',');
    await _publish('$fullId/\$nodes', nodesIds);
    for (Node n in nodes) {
      await n._sendNode();
    }

    //TODO Remove firmware stuff
    await _publish('$fullId/\$localip', localIp);
    await _publish('$fullId/\$mac', mac);
    await _publish('$fullId/\$fw/name', firmwareName);
    await _publish('$fullId/\$fw/version', firmwareVersion);

    //TODO Remove stats stuff
    await _publish('$fullId/\$stats/intervall', toString());

    await ready();
  }

  Future<Null> _forgetDevice() async {
    await _publish('$fullId/\$homie', emptyPayload);
    await _publish('$fullId/\$name', emptyPayload);
    await _publish('$fullId/\$localip', emptyPayload);
    await _publish('$fullId/\$mac', emptyPayload);
    await _publish('$fullId/\$fw/name', emptyPayload);
    await _publish('$fullId/\$fw/version', emptyPayload);
    await _publish('$fullId/\$implementation', emptyPayload);
    await _publish('$fullId/\$stats/intervall', emptyPayload);
    await _publish('$fullId/\$nodes', emptyPayload);
    for (Node n in nodes) {
      await n._forgetNode();
    }
    //TODO Remove stats stuff
    await _forgetStats();
  }

  //TODO Remove stats stuff
  Future<Null> _forgetStats() async {
    String statsTopic = '$fullId/\$stats';
    await _publish('$statsTopic/uptime', emptyPayload);
    await _publish('$statsTopic/signal', emptyPayload);
    await _publish('$statsTopic/cputemp', emptyPayload);
    await _publish('$statsTopic/cpuload', emptyPayload);
    await _publish('$statsTopic/battery', emptyPayload);
    await _publish('$statsTopic/freeheap', emptyPayload);
    await _publish('$statsTopic/supply', emptyPayload);
  }

  //TODO Remove stats stuff
  Future<Null> _sendStats() async {
    await _publish('$fullId/\$stats/uptime', deviceStats.uptime.toString());
    if (deviceStats.signalStrength != null) {
      await _publish(
          '$fullId/\$stats/signal', deviceStats.signalStrength.toString());
    }
    if (deviceStats.cpuTemperature != null) {
      await _publish(
          '$fullId/\$stats/cputemp', deviceStats.cpuTemperature.toString());
    }
    if (deviceStats.cpuLoad != null) {
      await _publish('$fullId/\$stats/cpuload', deviceStats.cpuLoad.toString());
    }
    if (deviceStats.batterLevel != null) {
      await _publish(
          '$fullId/\$stats/battery', deviceStats.batterLevel.toString());
    }
    if (deviceStats.freeHeap != null) {
      await _publish(
          '$fullId/\$stats/freeheap', deviceStats.freeHeap.toString());
    }
    if (deviceStats.powerSupply != null) {
      await _publish(
          '$fullId/\$stats/supply', deviceStats.powerSupply.toString());
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
    await _sendStats();
    await _publish('$fullId/\$state', 'ready');
    _deviceState = DeviceState.ready;

//TODO Remove stats stuff
    _statSender =
        new Timer.periodic(new Duration(seconds: statsIntervall), (Timer t) {
      if (t.isActive) {
        try {
          _sendStats();
        } on DisconnectingError {}
      }
    });
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
    _statSender.cancel();
    await _publish('$fullId/\$state', 'sleeping');
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
    _statSender.cancel();
    await _publish('$fullId/\$state', 'alert');
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
    _statSender.cancel();
    await _publish('$fullId/\$state', 'disconnected');
    await _forgetDevice();
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

///Used to represend the stats of a device.
class DeviceStats {
  final DateTime _bootTime;

  ///Signal strength in %. Wired devices might have a strengh of 100. This property is optional and might be null.
  int signalStrength;

  ///The cpu temperature in °C. This property is optional and might be null.
  int cpuTemperature;

  ///The cpu load in %. This property is optional and might be null.
  int cpuLoad;

  ///The battery level in %. This property is optional and might be null.
  int batterLevel;

  ///Free heap in bytes. This property is optional and might be null.
  int freeHeap;

  ///The power supply voltage in Volt. This property is optional and might be null.
  double powerSupply;

  ///The uptime is the time that passed since the [bootTime] given in the constructor in seconds.
  int get uptime => new DateTime.now().difference(_bootTime).inSeconds;

  ///Creates a new [DeviceStats] object with [new DateTime.now()] as [bootTime].
  ///See [new DeviceStats()] for an explanation of the other properties.
  DeviceStats.sinceNow(
      {int signalStrength,
      int cpuTemperature,
      int cpuLoad,
      int batteryLevel,
      int freeHeap,
      double powerSupply})
      : this(
            bootTime: new DateTime.now(),
            signalStrength: signalStrength,
            cpuTemperature: cpuTemperature,
            cpuLoad: cpuLoad,
            batteryLevel: batteryLevel,
            freeHeap: freeHeap,
            powerSupply: powerSupply);

  ///Creates a new state object.
  ///
  ///The only required property is the [bootTime], it must not be null.
  ///Using the [bootTime] the [uptime] of the device is calculated.
  ///All not requried properties are optional and might be [null]. In this case, they are not published.
  ///
  ///[singalStrengh]: Signal strength in %. Wired devices might have a strengh of 100.
  ///
  ///[cpuTemperature]: The cpu temperature in °C. This property is optional and might be null.
  ///
  ///[cpuLoad]: The cpu load in %. This property is optional and might be null.
  ///
  ///[batteryLevel]: The battery level in %. This property is optional and might be null.
  ///
  ///[freeHeap]: Free heap in bytes. This property is optional and might be null.
  ///
  ///[powerSupply]: The power supply voltage in Volt. This property is optional and might be null.
  DeviceStats(
      {@required DateTime bootTime,
      int signalStrength,
      int cpuTemperature,
      int cpuLoad,
      int batteryLevel,
      int freeHeap,
      double powerSupply})
      : assert(bootTime != null),
        this._bootTime = bootTime,
        this.signalStrength = signalStrength,
        this.cpuTemperature = cpuTemperature,
        this.cpuLoad = cpuLoad,
        this.batterLevel = batteryLevel,
        this.freeHeap = freeHeap,
        this.powerSupply = powerSupply;
}

///A enum for all device states defined by the homie convention.
enum DeviceState { init, ready, disconnected, sleeping, lost, alert }

///This class represents a homie node. Nodes are added to devices.
///Each node object must only be part of one device!
class Node extends HomieTopic {
  //The device this node belongs to.
  Device _device;
  Device get device => _device;

  ///The unique Id of this node, which must be an valid homie Id. See [isValidId].
  final String nodeId;

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
      @required Iterable<Property> properties})
      : assert(validString(nodeId)),
        assert(validString(name)),
        assert(validString(type)),
        assert(properties != null),
        this.nodeId = nodeId,
        this.name = name,
        this.type = type,
        this.properties = new List<Property>.unmodifiable(properties) {
    for (Property p in properties) {
      assert(p._node == null, 'This property is already part of another node');
      p._node = this;
    }
  }

  ///returns the [Property] with this propertyId, or [null] if no property with this propertyId is part of this node.
  Property getProperty(String propertyId) {
    return properties.firstWhere((Property p) => p.propertyId == propertyId);
  }

  Future<Null> _forgetNode() async {
    await _publish('$fullId/\$name', emptyPayload);
    await _publish('$fullId/\$type', emptyPayload);
    await _publish('$fullId/\$properties', emptyPayload);
    for (Property p in properties) {
      await p._forgetProperty();
    }
  }

  Future<Null> _sendNode() async {
    await _publish('$fullId/\$name', name);
    await _publish('$fullId/\$type', type);
    String propertyIds = properties.map((Property p) => p.propertyId).join(',');
    await _publish('$fullId/\$properties', propertyIds);
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
abstract class Property<T, V extends Property<T, V>> extends HomieTopic {
  EventListener<T, V> _listener;

  Node _node;

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
      String format})
      : assert(isValidId(propertyId)),
        assert(dataType != null),
        this.name = name ?? '',
        this.settable = settable ?? false,
        this.propertyId = propertyId,
        this.unit = unit ?? Unit.none,
        this.dataType = dataType,
        this.format = format;

  //FIXME Add property related code
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
  }

  Future<Null> _publish(String topic, String content,
      [bool retained = true, int qos]) {
    assert(node != null,
        'This property can not publish values as it is not part of a node');
    return _node._publish(topic, content, retained, qos);
  }
}
