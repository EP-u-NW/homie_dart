import 'package:homie_dart/homie_dart.dart';
import 'package:meta/meta.dart';

///The EPNW Meta extension can be used to add tags and key-value pairs to devices, nodes and properties.
///See the extension speficiation on the homie convention extensions page for more information.
///This class can be used as an [DeviceExtension] as well as an [NodeExtension] and [PropertyExtension]. 
class MetaExtension extends DeviceExtension
    implements NodeExtension, PropertyExtension {
  String get version => '1.1.0';
  String get extensionId => 'eu.epnw.meta';
  List<String> get homieVersions => const <String>['3.0.1', '4.x'];

  Type get deviceExtension => MetaExtension;

  ///An iterable containing all tags. It is not allowed to change this iterable or its content!
  final Iterable<String> tags;
  ///An iterable containing all [MainKey]s which then may contain [SubKey]s.
  ///It is not allowed to change this iterable or its content!
  final Iterable<MainKey> mainkeys;

  ///Creates a new instance of this extension which might be added to devices, nodes and properties.
  ///The iterables [tags] and [mainkeys] will be used (and not copied) for the corresponding fields of this instance.
  ///It is not allowed to change the content of this iterables!
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
    String topic = '${t.fullTopic}/\$meta';
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
        assert(isValidId(key.id)); //Do this check here and not in any constructor to allow them to be const
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
    String topic = '${t.fullTopic}/\$meta';
    await publish(t, '$topic/tags', emptyPayload);
    await _forgetKeys(t, mainkeys, topic, true);
  }
}

abstract class _Key {
  ///The id of this key. Must be an valid id, see [isValidId].
  final String id;
  ///The name of this key. Might be arbitrary and does not need to be an valid id.
  final String keyName;
  ///The value of this key.
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
  ///An iterable containing all [SubKey]s.
  ///It is not allowed to change this iterable or its content!
  final Iterable<SubKey> subkeys;

  ///Creates an new MainKey.
  ///
  ///The [id] must be an valid id, see [isValidId].
  ///
  ///The [keyName] and [value] can be choosen freely, but do must not be [null].
  ///
  ///The [subkeys] iterable contains all subkeys associated with this mainkey.
  ///It is not allowed to change this iterable or its content after creation!
  const MainKey(
      {@required String id,
      @required String keyName,
      @required String value,
      Iterable<SubKey> subkeys})
      : this.subkeys = subkeys,
        super(id: id, keyName: keyName, value: value);
}

class SubKey extends _Key {
  ///Creates an new MainKey.
  ///
  ///The [id] must be an valid id, see [isValidId].
  ///
  ///The [keyName] and [value] can be choosen freely, but do must not be [null].
  const SubKey(
      {@required String id, @required String keyName, @required String value})
      : super(id: id, keyName: keyName, value: value);
}
