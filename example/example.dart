import 'package:homie_dart/homie_dart.dart';

import 'supercar.dart';
import 'printbroker.dart';

Future<Null> main(List<String> args) async {
  BrokerConnection con = new PrintBrokerConnection();
	await test(con);
}
	
Future<Null> test(BrokerConnection con) async{	
  qos=1;
  defaultIp = '192.168.178.171';
  defaultMac = '04:D3:B0:98:32:2B';

  SuperCar superCar = new SuperCar(deviceId: 'super-car');
  superCar.deviceStats.cpuTemperature = 48;
  superCar.deviceStats.signalStrength = 24;
  superCar.deviceStats.batterLevel = 80;

  print('Init...');
  await superCar.init(con);
  print('Updating engine temperature...');
  superCar.engineTemperature=32.5;
  print('Engine temperature: ${superCar.engineTemperature}');
}