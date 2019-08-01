import 'package:homie_dart/homie_legacy_extensions.dart';
import 'package:meta/meta.dart';
import 'package:homie_dart/homie_dart.dart';

class SuperCar extends Device {
  FloatPropertyRetained get _engineTemperature =>
      getNode('engine').getProperty('temperature') as FloatPropertyRetained;

  void set engineTemperature(double newTemperature) =>
      _engineTemperature.publishValue(newTemperature);

  double get engineTemperature => _engineTemperature.value;

  HsvColorPropertyRetained get _color =>
      getNode('engine').getProperty('color') as HsvColorPropertyRetained;

  void set color(HsvColor newColor) => _color.publishValue(newColor);

  HsvColor get color => _color.value;

  SuperCar({@required String deviceId, bool useLegacyExtensions = false})
      : super(
            name: 'Super Car',
            implementation: 'superCarDart',
            extensions: useLegacyExtensions
                ? <DeviceExtension>[
                    new LegacyFirmware(
                        firmwareName: 'homie-dart',
                        firmwareVersion: '1.0.0',
                        localIp: '192.168.178.147',
                        mac: '04:D3:B0:98:32:2B'),
                    new LegacyStats(statsIntervall: 15)
                  ]
                : null,
            deviceId: deviceId,
            nodes: <Node>[
              new Node(
                  nodeId: 'engine',
                  name: 'Car engine',
                  type: 'V8',
                  properties: <Property>[
                    new HsvColorPropertyRetained(
                        initialValue: new HsvColor(255, 0, 0),
                        propertyId: 'color',
                        name: 'Color',
                        settable: true),
                    new FloatPropertyRetained(
                        propertyId: 'temperature',
                        name: 'Engine temperature',
                        unit: Unit.degreeCelsius,
                        settable: true,
                        minValue: -20.0,
                        maxValue: 120.0,
                        initialValue: 21.5)
                  ])
            ]) {
    _engineTemperature.listener = (FloatProperty property, double value) async {
      engineTemperature = value;
    };
    _color.listener = (HsvColorProperty property, HsvColor value) async {
      color = value;
    };
  }
}
