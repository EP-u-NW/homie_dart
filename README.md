# homie_dart

An impelementation of the [homie convention 3.0.1](https://homieiot.github.io/specification/spec-core-v3_0_1/) for dart.
This libary can be used to create devices in the homie format.

## Reflection

This branch uses the dart:mirrors api to add a reflected version of the enum property.
For more information on what that means, take a look at the ReflectedEnumProperty class.
Since dart:mirrors is not supported by every dart impelementation (vm, web or flutter), this version is not intended for pub.

## BrokerConnection and MQTT connection

This package does not contain any MQTT logic!
Instead it defines an abstract class [BrokerConnection](https://pub.dev/documentation/homie_dart/latest/homie_dart/BrokerConnection-class.html).
You can either implement it yourselfe or use the package [homie_dart_on_mqtt_client](https://pub.dev/packages/homie_dart_on_mqtt_client), which handles all the mqtt logic.

## Missing Features

- Homie arrays are not supported
- Broadcast channel is not implemented

## Example

An example, how to create a device can be found [here](https://github.com/EPNW/homie_dart/blob/master/example/supercar.dart), and [this file](https://github.com/EPNW/homie_dart/blob/master/example/example.dart) shows, how to run it.
