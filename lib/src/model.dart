import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import 'broker_connection.dart';
import 'constants.dart';
import 'utils.dart';
import 'unit.dart';
import 'homie_datatype.dart';

///Subclass this class to create a new homie device.
abstract class Device {
  BrokerConnection _broker;
  Timer _statSender;
  DeviceState _deviceState;
  final DeviceStats _deviceStats;

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
        this.nodes = new List<Node>.unmodifiable(nodes);

  ///returns the [Node] with this nodeId, or [null] if no node with this nodeId is part of this device.
  Node getNode(String nodeId) {
    return nodes.firstWhere((Node n) => n.nodeId == nodeId);
  }

  ///Inits the device, etablishes a connection to the mqtt broker and sets appropriate last will topics.
  ///During the initalisation process each [Property] will be bound to the device.
  ///The initalisation ends with an automatic call to [ready].
  ///It is invalid to call this method if the [deviceState] has any value other than [null].
  ///This means, even a disconnected device can not be connected again by calling [init].
  ///
  ///The [broker] musst be unique and might not be used in the [init] call of an other device.
  ///Create a new [BrokerConnection] for each device!
  Future<Null> init(BrokerConnection broker) async {
    assert(deviceState == null);
    String myTopic = '$root/$deviceId';
    _broker = broker;
    await _broker.connect('$myTopic/\$state', utf8.encode('lost'), true, qos);
    _deviceState = DeviceState.init;
    await _broker.publish('$myTopic/\$state', utf8.encode('init'), true, qos);
    await _broker.publish(
        '$myTopic/\$homie', utf8.encode(conventionVersion), true, qos);
    await _broker.publish('$myTopic/\$name', utf8.encode(name), true, qos);
    await _broker.publish(
        '$myTopic/\$localip', utf8.encode(localIp), true, qos);
    await _broker.publish('$myTopic/\$mac', utf8.encode(mac), true, qos);
    await _broker.publish(
        '$myTopic/\$fw/name', utf8.encode(firmwareName), true, qos);
    await _broker.publish(
        '$myTopic/\$fw/version', utf8.encode(firmwareVersion), true, qos);
    await _broker.publish(
        '$myTopic/\$implementation', utf8.encode(implementation), true, qos);
    await _broker.publish('$myTopic/\$stats/intervall',
        utf8.encode(statsIntervall.toString()), true, qos);
    String nodesIds = nodes.map((Node n) => n.nodeId).join(',');
    await _broker.publish('$myTopic/\$nodes', utf8.encode(nodesIds), true, qos);
    for (Node n in nodes) {
      await _sendNode(n);
    }
    await ready();
  }

  Future<Null> _sendNode(Node n) async {
    String nodeTopic = '$root/$deviceId/${n.nodeId}';
    await _broker.publish('$nodeTopic/\$name', utf8.encode(n.name), true, qos);
    await _broker.publish('$nodeTopic/\$type', utf8.encode(n.type), true, qos);
    String propertyIds =
        n.properties.map((Property p) => p.propertyId).join(',');
    await _broker.publish(
        '$nodeTopic/\$properties', utf8.encode(propertyIds), true, qos);
    for (Property p in n.properties) {
      await _sendProperty(nodeTopic, p);
    }
  }

  Future<Null> _sendProperty(String nodeTopic, Property p) async {
    String propertyTopic = '$nodeTopic/${p.propertyId}';
    await _broker.publish(
        '$propertyTopic/\$name', utf8.encode(p.name), true, qos);
    await _broker.publish('$propertyTopic/\$settable',
        utf8.encode(p.settable.toString()), true, qos);
    await _broker.publish('$propertyTopic/\$retained',
        utf8.encode(p.retained.toString()), true, qos);
    await _broker.publish(
        '$propertyTopic/\$unit', utf8.encode(p.unit.toString()), true, qos);
    await _broker.publish('$propertyTopic/\$datatype',
        utf8.encode(typeName[p.dataType]), true, qos);
    if (p.format != null) {
      await _broker.publish(
          '$propertyTopic/\$format', utf8.encode(p.format), true, qos);
    }
    if (p.settable) {
      Stream<List<int>> events =
          await _broker.subscribe('$propertyTopic/set', qos);
      new Utf8Decoder()
          .bind(events)
          .map((String value) => p.stringRepresentationToValue(value))
          .forEach(p._informListener);
    }
    assert(
        !p.isBound(), 'The property $p is already bound to an other device!');
    bool retained = p is RetainedMixin;
    p._publisher =
        (String value) => _publish(propertyTopic, retained, value, true);
    if (retained) {
      String value = p.valueToStringRepresentation((p as RetainedMixin)._value);
      _publish(propertyTopic, true, value, false);
    }
  }

  Future<Null> _publish(
      String topic, bool retained, String value, bool assertReady) async {
    if (assertReady) {
      assert(deviceState == DeviceState.ready);
    }
    return _broker.publish(topic, utf8.encode(value), retained, qos);
  }

  Future<Null> _sendStats() async {
    String statsTopic = '$root/$deviceId/\$stats';
    await _broker.publish('$statsTopic/uptime',
        utf8.encode(deviceStats.uptime.toString()), true, qos);
    if (deviceStats.signalStrength != null) {
      await _broker.publish('$statsTopic/signal',
          utf8.encode(deviceStats.signalStrength.toString()), true, qos);
    }
    if (deviceStats.cpuTemperature != null) {
      await _broker.publish('$statsTopic/cputemp',
          utf8.encode(deviceStats.cpuTemperature.toString()), true, qos);
    }
    if (deviceStats.cpuLoad != null) {
      await _broker.publish('$statsTopic/cpuload',
          utf8.encode(deviceStats.cpuLoad.toString()), true, qos);
    }
    if (deviceStats.batterLevel != null) {
      await _broker.publish('$statsTopic/battery',
          utf8.encode(deviceStats.batterLevel.toString()), true, qos);
    }
    if (deviceStats.freeHeap != null) {
      await _broker.publish('$statsTopic/freeheap',
          utf8.encode(deviceStats.freeHeap.toString()), true, qos);
    }
    if (deviceStats.powerSupply != null) {
      await _broker.publish('$statsTopic/supply',
          utf8.encode(deviceStats.powerSupply.toString()), true, qos);
    }
  }

  ///After the future returned by this devices is done your device will be in the ready state and good to operate.
  ///Only call manually when [deviceState] is sleeping or alert, any other case will throw an assertion.
  ///While the device is ready, that stats will automatically be published according to [statsIntervall].
  Future<Null> ready() async {
    assert(deviceState == DeviceState.alert ||
        deviceState == DeviceState.init ||
        deviceState == DeviceState.sleeping);
    await _sendStats();
    await _broker.publish(
        '$root/$deviceId/\$state', utf8.encode('ready'), true, qos);
    _statSender =
        new Timer.periodic(new Duration(seconds: statsIntervall), (Timer t) {
      if (t.isActive) {
        try {
          _sendStats();
        } on DisconnectingException {}
      }
    });
    _deviceState = DeviceState.ready;
  }

  ///Puts the device into sleep state. While sleeping, sending status is paused.
  Future<Null> sleep() async {
    _statSender.cancel();
    await _broker.publish(
        '$root/$deviceId/\$state', utf8.encode('sleeping'), true, qos);
    _deviceState = DeviceState.sleeping;
  }

  ///You can put the device in alert state to denote an error which requires an user action.
  ///Entering this state will suspend the status updates.
  Future<Null> alert() async {
    _statSender.cancel();
    await _broker.publish(
        '$root/$deviceId/\$state', utf8.encode('alert'), true, qos);
    _deviceState = DeviceState.alert;
  }

  ///Disconnects the device and the [BrokerConnection].
  ///You can never use this object instance again!
  ///See the remarks in [init].
  Future<Null> disconnect() async {
    _statSender.cancel();
    await _broker.publish(
        '$root/$deviceId/\$state', utf8.encode('disconnected'), true, qos);
    await _broker.disconnect();
    _deviceState = DeviceState.disconnected;
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
class Node {
  ///The unique Id of this node, which must be an valid homie Id. See [isValidId].
  final String nodeId;

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
        this.properties = new List<Property>.unmodifiable(properties);

  ///returns the [Property] with this propertyId, or [null] if no property with this propertyId is part of this node.
  Property getProperty(String propertyId) {
    return properties.firstWhere((Property p) => p.propertyId == propertyId);
  }
}

///Triggered when an settable [property] receives a set [command].
///If the property is retained, the [publishValue] method should be executed with the new value of this property,
///to let the homie controller know, that the set command was processed.
typedef Future<Null> EventListener<T, V extends Property<T, V>>(
    V property, T command);

typedef Future<Null> _Publisher(String value);

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
abstract class Property<T, V extends Property<T, V>> {
  _Publisher _publisher;
  EventListener<T, V> _listener;

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

  ///A property may only be part of one [Node], which itself may only be part of one [Device].
  ///During the [Device.init] method of the device the property is bound to that device.
  bool isBound() => _publisher != null;

  ///Publishes a new [value] for this property.
  ///If this property is [retained], the value of the [RetainedMixin] is also updated.
  ///
  ///Awaiting the returned future guarantees the publishing of the message to the broker with respect to the quality of service [qos].
  Future<Null> publishValue(T value) {
    assert(isBound(),
        'This property cannot publish values since it is not part of of device which state is ready.');
    if (this is RetainedMixin<T, V>) {
      (this as RetainedMixin<T, V>)._value = value;
    }
    return _publisher(valueToStringRepresentation(value));
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
}
