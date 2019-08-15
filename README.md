# homie_dart

An impelementation of the [homie convention 4.0](https://homieiot.github.io/specification/spec-core-v4_0_0/) for dart.
This package can be used to create devices with nodes and properties in the homie format.

Version 2 of this package includes the core [homie_dart](https://pub.dev/documentation/homie_dart/latest/homie_dart/homie_dart-library.html) library, as well as the [homie_legacy_extensions](https://pub.dev/documentation/homie_dart/latest/homie_legacy_extensions/homie_legacy_extensions-library.html) library,
which can be used to add device attributes that where removed in homie version 4.0. This is usefull for backwards compatibility.
More specific, the [Legacy Stats](https://github.com/homieiot/convention/blob/develop/extensions/documents/homie_legacy_stats_extension.md) and [Legacy Firmware](https://github.com/homieiot/convention/blob/develop/extensions/documents/homie_legacy_firmware_extension.md) extensions are implemented.

Also included in this package, in the [epnw_meta_extension](https://pub.dev/documentation/homie_dart/latest/epnw_meta_extension/epnw_meta_extension-library.html) library, is the EPNW [Meta](https://github.com/homieiot/convention/blob/develop/extensions/documents/homie_meta_extension.md) extension which
can be used to add tags and (nested) key-value pairs to devices, nodes and properties.

To create devices according to the homie convention 3.0.1, use version 1.1.0 of this package instead! 

## BrokerConnection and MQTT connection

This package does not contain any MQTT logic!
Instead it defines an abstract class [BrokerConnection](https://pub.dev/documentation/homie_dart/latest/homie_dart/BrokerConnection-class.html).
You can either implement it yourselfe or use the package [homie_dart_on_mqtt_client](https://pub.dev/packages/homie_dart_on_mqtt_client), which handles all the mqtt logic.

## Missing Features

- Broadcast channel is not implemented

## Example

An example, how to create a device can be found [here](https://github.com/EPNW/homie_dart/blob/master/example/supercar.dart), and [this file](https://github.com/EPNW/homie_dart/blob/master/example/example.dart) shows, how to run it.
