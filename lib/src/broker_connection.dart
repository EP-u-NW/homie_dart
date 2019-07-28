import 'dart:typed_data';

///Used for connection to a mqtt broker.
///The [homie_dart] package does not contain an implementation of this abstract class!
///Implement the mqtt logic yourselfe or use the [homie_dart_on_mqtt] package instead (recommended)!
abstract class BrokerConnection {
  ///Connects to the mqtt broker. The connection must respect the last will parameters.
  ///The connect method of each instance may only be called once.
  ///If it is called a second time on the same instance a [StateError] must be thrown.
  Future<Null> connect(String lastWillTopic, Uint8List lastWillData,
      bool lastWillRetained, int lastWillQos);

  ///Disconnects from the mqtt broker and cancels all subscriptions.
  Future<Null> disconnect();

  ///Subscribes to [topic].
  ///Awaiting the returned future gives a [Stream] whichs events are incoming messages on the topic.
  ///If this is called while disconnecting, a [DisconnectingError] should be thrown.
  Future<Stream<Uint8List>> subscribe(String topic, int qos);

  ///Publishes [data] to [topic] with respect to [retained].
  ///Awaiting the returned future should guarantee the publishing of the message to the broker with respect to the quality of service [qos].
  ///A [qos] of 0 does not guarentee anything and might return immediately.
  ///If this is called while disconnecting, a [DisconnectingError] should be thrown
  Future<Null> publish(String topic, Uint8List data, bool retained, int qos);
}

///Thrown by the [BrokerConnection] when trying to publish or to subscribe to a topic while currently disconnecting. 
class DisconnectingError implements Exception {}
