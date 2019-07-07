///Unless specified otherwise, devices will use this value for the $stats/localIp attribute.
///This attribute is required by the convention, so either set this property
///or pass a value to the [localIp] field in the [Device] constructor.
String defaultIp;
///Unless specified otherwise, devices will use this value for the $stats/mac attribute.
///This attribute is required by the convention, so either set this property
///or pass a value to the [mac] field in the [Device] constructor.
String defaultMac;
///The Quality of Service the library uses. The homie convention recommends 1.
int qos = 1;

///The homie convention version this library implements.
const String defaultConventionVersion = "3.0.1";
///The default mqtt topic root as recommended by the homie convention.
const String defaultRoot = "homie";
///Unless specified otherwise, devices created using this library will use this firmware name.
const String defaultFirmwareName = "homie-dart";
///Unless specified otherwise, devices created using this library will use this firmware version.
const String defaultFirmwareVersion = "1.0.0";

///The smalles value an int can represend according to the homie convention.
const int homieIntMin = -9223372036854775808;
///The biggest value an int can represend according to the homie convention.
const int homieIntMax = 9223372036854775807;


///The smalles value a float can represend according to the homie convention.
const double homieFloatMin = -homieFloatMax;
///The biggest value a float can represend according to the homie convention.
const double homieFloatMax = 3.4028234663852885981170418348451692544e+38;

