import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

import 'package:homie_dart/homie_dart.dart';

class PrintBrokerConnection implements BrokerConnection {
  @override
  Future<Null> connect(String lastWillTopic, Uint8List lastWillData,
      bool lastWillRetained, int lastWillQos) async {
    await new Future.delayed(new Duration(seconds: 1));
    print('Connected');
  }

  @override
  Future<Null> disconnect() async {
    await new Future.delayed(new Duration(seconds: 1));
    print('Disconnected');
  }

  @override
  Future<Null> publish(
      String topic, Uint8List data, bool retained, int qos) async {
    print('$topic ${utf8.decode(data)}');
  }

  @override
  Future<Stream<Uint8List>> subscribe(String topic, int qos) async {
    return new StreamController<Uint8List>().stream;
  }
}
