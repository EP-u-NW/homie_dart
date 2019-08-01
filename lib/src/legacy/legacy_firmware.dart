import 'package:homie_dart/homie_dart.dart';

class LegacyFirmware extends DeviceExtension {
  String get version => '0.1.1';
  String get extensionId => 'org.homie.legacy-firmware';
  List<String> get homieVersions => const <String>['4.x'];

  ///The ip of this device. For more information see the [Device] constructor documentation.
  final String localIp;

  ///The mac of this device. For more information see the [Device] constructor documentation.
  final String mac;

  ///The firmware name of this device. For more information see the [Device] constructor documentation.
  final String firmwareName;

  ///The firmware version of this device. For more information see the [Device] constructor documentation.
  final String firmwareVersion;

  const LegacyFirmware(
      {String localIp, String mac, String firmwareName, String firmwareVersion})
      : assert(localIp != null),
        assert(mac != null),
        assert(firmwareName != null),
        assert(firmwareVersion != null),
        this.localIp = localIp,
        this.mac = mac,
        this.firmwareName = firmwareName,
        this.firmwareVersion = firmwareVersion;

  Future<Null> onStateChange(Device device, DeviceState state) async {
    String fullId = device.fullId;
    if (state == DeviceState.init) {
      await publish(device, '$fullId/\$localip', localIp);
      await publish(device, '$fullId/\$mac', mac);
      await publish(device, '$fullId/\$fw/name', firmwareName);
      await publish(device, '$fullId/\$fw/version', firmwareVersion);
    } else if (state == DeviceState.disconnected) {
      await publish(device, '$fullId/\$localip', emptyPayload);
      await publish(device, '$fullId/\$mac', emptyPayload);
      await publish(device, '$fullId/\$fw/name', emptyPayload);
      await publish(device, '$fullId/\$fw/version', emptyPayload);
    }
  }
}
