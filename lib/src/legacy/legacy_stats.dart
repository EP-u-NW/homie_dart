import 'dart:async';

import 'package:meta/meta.dart';
import 'package:homie_dart/homie_dart.dart';

class LegacyStats extends DeviceExtension {
  String get version => '0.1.1';
  String get extensionId => 'org.homie.legacy-stats';
  List<String> get homieVersions => const <String>['4.x'];

  final Map<Device, Timer> _statsSender;

  final DeviceStats _deviceStats;

  ///The stats of this device are periodically published to the mqtt broker.
  ///The stats can be accessed and modified.
  DeviceStats get deviceStats => _deviceStats;

  ///The intervall in seconds the [deviceStats] are published, as long as the [deviceState] is [DeviceState.ready].
  final int statsIntervall;

  LegacyStats({@required int statsIntervall, DeviceStats stats})
      : assert(statsIntervall != null),
        assert(statsIntervall > 0),
        this.statsIntervall = statsIntervall,
        this._deviceStats = stats ?? new DeviceStats.sinceNow(),
        this._statsSender = new Map<Device, Timer>();

  Future<Null> onStateChange(Device device, DeviceState state) async {
    if (state == DeviceState.init) {
      await publish(
          device, '${device.fullId}/\$stats/intervall', statsIntervall.toString());
      await _sendStats(device);
    } else if (state == DeviceState.ready) {
      _statsSender[device] =
          new Timer.periodic(new Duration(seconds: statsIntervall), (Timer t) async {
        if (t.isActive) {
          try {
           await _sendStats(device);
          } on DisconnectingError {}
        }
      });
    } else if (state == DeviceState.alert || state == DeviceState.sleeping) {
      _statsSender[device].cancel();
      _statsSender[device]==null;
    } else if (state == DeviceState.disconnected) {
      _statsSender[device].cancel();
      _statsSender[device]==null;
      await publish(device, '${device.fullId}/\$stats/intervall', emptyPayload);
      await _forgetStats(device);
    }
  }

  Future<Null> _forgetStats(Device device) async {
    String statsTopic = '${device.fullId}/\$stats';
    await publish(device,'$statsTopic/uptime', emptyPayload);
    await publish(device,'$statsTopic/signal', emptyPayload);
    await publish(device,'$statsTopic/cputemp', emptyPayload);
    await publish(device,'$statsTopic/cpuload', emptyPayload);
    await publish(device,'$statsTopic/battery', emptyPayload);
    await publish(device,'$statsTopic/freeheap', emptyPayload);
    await publish(device,'$statsTopic/supply', emptyPayload);
  }

  Future<Null> _sendStats(Device device) async {
     String statsTopic = '${device.fullId}/\$stats';
    await publish(device,'$statsTopic/uptime', deviceStats.uptime.toString());
    if (deviceStats.signalStrength != null) {
      await publish(device,
          '$statsTopic/signal', deviceStats.signalStrength.toString());
    }
    if (deviceStats.cpuTemperature != null) {
      await publish(device,
          '$statsTopic/cputemp', deviceStats.cpuTemperature.toString());
    }
    if (deviceStats.cpuLoad != null) {
      await publish(device,'$statsTopic/cpuload', deviceStats.cpuLoad.toString());
    }
    if (deviceStats.batterLevel != null) {
      await publish(device,
          '$statsTopic/battery', deviceStats.batterLevel.toString());
    }
    if (deviceStats.freeHeap != null) {
      await publish(device,
          '$statsTopic/freeheap', deviceStats.freeHeap.toString());
    }
    if (deviceStats.powerSupply != null) {
      await publish(device,
          '$statsTopic/supply', deviceStats.powerSupply.toString());
    }
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
