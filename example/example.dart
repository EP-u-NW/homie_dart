import 'package:homie_dart/homie_dart.dart';
import 'package:homie_dart/homie_legacy_extensions.dart';

import 'supercar.dart';
import 'printbroker.dart';

Future<Null> main(List<String> args) async {
  BrokerConnection con = new PrintBrokerConnection();
  await test(con);
}

Future<Null> test(BrokerConnection con) async {
  qos = 1;

  bool useLegacyExtensions = true;
  SuperCar superCar =
      new SuperCar(deviceId: 'super-car', useLegacyExtensions: useLegacyExtensions);
  if (useLegacyExtensions) {
    DeviceStats deviceStats=superCar.getExtension<LegacyStats>().deviceStats;
    deviceStats.cpuTemperature = 48;
    deviceStats.signalStrength = 24;
    deviceStats.batterLevel = 80;
  }

  print('Init...');
  await superCar.init(con);
  print('Updating engine temperature...');
  superCar.engineTemperature = 32.5;
  print('Engine temperature: ${superCar.engineTemperature}');

  await new Future.delayed(const Duration(seconds: 30));

  print('Disconnecting...');
  await superCar.disconnect();
  print('Disconnected');
}
