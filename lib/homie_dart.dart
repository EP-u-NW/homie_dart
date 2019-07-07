///An implementation of the homie convention version 3.0.1 in dart.
///This library does not support homie property arrays or broadcast channel. 
///To implement a device extend the [Device] class and add some [Node] with [Property].
///
///The version 3.0.1 of the homie convention requires an ip and a mac address to be liked to a device.
///These values can be set using the top-level properties [defaultIp] and [defaultMac].
///The top-level property [qos] denots the quality of service for mqtt protocoll and can be adjusted.
///
///To connect the device, call its [Device.init] method.
///This requries an object of type [BrokerConnection], which handels the underlying mqtt connection.
///This package only declares the abstract class [BrokerConnection] and does not come with a concret implementation of it.
///Either implement it yourselfe or use the package [homie_dart_on_mqtt_client]
///which exports functionality of this package, and provides an implementation of [BrokerConnection]. 
library homie_dart;

export 'src/broker_connection.dart';
export 'src/colors.dart';
export 'src/utils.dart'
    hide inOrder, validString, asEnumString, enumValuesValid;
export 'src/constants.dart';
export 'src/homie_datatype.dart' hide typeName;
export 'src/model.dart';
export 'src/extended_properties.dart';
export 'src/unit.dart';
export 'src/mapped_enum_property.dart';