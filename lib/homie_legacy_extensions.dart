///Provides the [LegacyFirmware] and [LegacyStats] extension.
///Some attributes that were part of the homie 3.0.1 convention and older versions got removed in version 4.0.
///These two extensions can be used to add them to devices again. When using both extensions a device can be made backwards compatible.
///For more information see the classes and the extension specifications found in the extensions section on the homie website. 
library homie_legacy_extensions;

export 'src/legacy/legacy_firmware.dart';
export 'src/legacy/legacy_stats.dart';