///The Quality of Service the library uses. The homie convention recommends 1.
int qos = 1;

///The homie convention version this library implements.
const String defaultConventionVersion = "4.0";
///The default mqtt topic root as recommended by the homie convention.
const String defaultRoot = "homie/";

///The smalles value an int can represend according to the homie convention.
const int homieIntMin = -9223372036854775808;
///The biggest value an int can represend according to the homie convention.
const int homieIntMax = 9223372036854775807;


///The smalles value a float can represend according to the homie convention.
const double homieFloatMin = -homieFloatMax;
///The biggest value a float can represend according to the homie convention.
const double homieFloatMax = 3.4028234663852885981170418348451692544e+38;

///An empty string which will translate to an empty payload for sending through the mqtt broker.
const String emptyPayload='';

