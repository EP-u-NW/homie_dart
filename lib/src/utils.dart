import 'dart:typed_data';
import 'constants.dart';
import 'dart:convert';

Uint8List _emptyPayload = new Uint8List(0);

Uint8List payload(String s){
  return s==emptyPayload?_emptyPayload:utf8.encode(s);
}

bool inOrder(List<num> values) {
  if (values.length < 2) {
    return true;
  } else {
    for (int i = 1; i < values.length; i++) {
      if (values[i] < values[i - 1]) {
        return false;
      }
    }
    return true;
  }
}

///Checks if the given String is a valid Id according to the homie convention.
///A valid id may only contain of lowercase letters from a to z and numbers from 0 to 9.
///In addition, hyphens (-) are allowed, but not as first or last character in the Id.
///An id must not be empty.
bool isValidId(String id) {
  if (!validString(id)) {
    return false;
  } else if (id.startsWith('-') || id.endsWith('-')) {
    return false;
  } else {
    RegExp exp = new RegExp("^([a-z]|[0-9]|-)+\$");
    return exp.hasMatch(id);
  }
}

bool validString(String string) {
  return string != null && string.isNotEmpty;
}

bool enumValuesValid(Iterable<String> values) {
  if (values != null && values.isNotEmpty) {
    return values.firstWhere((String value) => !validString(value)) == null;
  } else {
    return false;
  }
}

String asEnumString(Iterable<String> values) {
  return values.join(',');
}
