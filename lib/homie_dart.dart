///An implementation of the homie convention version 4.0 in dart.
///This library does not support the homie broadcast channel. 
///To implement a device extend the [Device] class and add some [Node] with [Property].
///
///Extensions can be created and added do devices, nodes, or properties.
///See the subclasses of [Extension] for more information. 
///Version 4.0 of the convention removes some device attributes, such as stats and mac address.
///If you want to keep these attributes you can use the LegacyStats and LegacyFirmware extensions
/// found in the [homie_legacy_extensions] library, which is also part of this package.
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
    hide inOrder, validString, asEnumString, enumValuesValid, payload;
export 'src/constants.dart';
export 'src/homie_datatype.dart' hide typeName;
export 'src/model.dart';
export 'src/extended_properties.dart';
export 'src/unit.dart';
export 'src/mapped_enum_property.dart';