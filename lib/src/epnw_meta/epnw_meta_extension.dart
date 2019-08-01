import 'package:homie_dart/homie_dart.dart';
import 'package:meta/meta.dart';

class MetaExtension extends DeviceExtension
    implements NodeExtension, PropertyExtension {
  String get version => '1.1.0';
  String get extensionId => 'eu.epnw.meta';
  List<String> get homieVersions => const <String>['3.0.1', '4.x'];

  Type get deviceExtension => MetaExtension;

  final Iterable<String> tags;
  final Iterable<MainKey> mainkeys;

  const MetaExtension({Iterable<String> tags, Iterable<MainKey> mainkeys})
      : this.tags = tags,
        this.mainkeys = mainkeys;

  Future<Null> onStateChange(Device device, DeviceState state) async {
    switch (state) {
      case DeviceState.init:
        await _send(device);
        break;
      case DeviceState.disconnected:
        await _forget(device);
        break;
      default:
        break;
    }
  }

  Future<Null> onPublishNode(Node n) => _send(n);
  Future<Null> onUnpublishNode(Node n) => _forget(n);
  Future<Null> onPublishProperty(Property p) => _send(p);
  Future<Null> onUnpublishProperty(Property p) => _forget(p);

  Future<Null> _send(HomieTopic t) async {
    String topic = '${t.fullId}/\$meta';
    if (tags != null && tags.isNotEmpty) {
      await publish(t, '$topic/tags', tags.join(','));
    }
    await _sendKeys(t, mainkeys, topic, true);
  }

  Future<Null> _sendKeys(
      HomieTopic t, Iterable<_Key> keys, String topic, bool mainKeys) async {
    if (keys != null && keys.isNotEmpty) {
      await publish(t, '$topic/\$' + (mainKeys ? 'main' : 'sub') + 'key-ids',
          keys.map<String>((_Key k) => k.id).join(','));
      for (_Key key in keys) {
        String keyTopic = '$topic/${key.id}';
        await publish(t, '$keyTopic/\$name', key.keyName);
        await publish(t, '$keyTopic/\$value', key.value);
        if (mainKeys) {
          await _sendKeys(t, (key as MainKey).subkeys, keyTopic, false);
        }
      }
    }
  }

  Future<Null> _forgetKeys(
      HomieTopic t, Iterable<_Key> keys, String topic, bool mainKeys) async {
    if (keys != null && keys.isNotEmpty) {
      await publish(t, '$topic/\$' + (mainKeys ? 'main' : 'sub') + 'key-ids',
          emptyPayload);
      for (_Key key in keys) {
        String keyTopic = '$topic/${key.id}';
        await publish(t, '$keyTopic/\$key', emptyPayload);
        await publish(t, '$keyTopic/\$value', emptyPayload);
        if (mainKeys) {
          await _forgetKeys(t, (key as MainKey).subkeys, keyTopic, false);
        }
      }
    }
  }

  Future<Null> _forget(HomieTopic t) async {
    String topic = '${t.fullId}/\$meta';
    await publish(t, '$topic/tags', emptyPayload);
    await _forgetKeys(t, mainkeys, topic, true);
  }
}

abstract class _Key {
  final String id;
  final String keyName;
  final String value;
  const _Key(
      {@required String id, @required String keyName, @required String value})
      : assert(id != null),
        assert(keyName != null),
        assert(value != null),
        this.id = id,
        this.keyName = keyName,
        this.value = value;
}

class MainKey extends _Key {
  final Iterable<SubKey> subkeys;
  const MainKey(
      {@required String id,
      @required String keyName,
      @required String value,
      Iterable<SubKey> subkeys})
      : this.subkeys = subkeys,
        super(id: id, keyName: keyName, value: value);
}

class SubKey extends _Key {
  const SubKey(
      {@required String id, @required String keyName, @required String value})
      : super(id: id, keyName: keyName, value: value);
}
