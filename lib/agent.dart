// Copyright 2019 dartssh developers
// Use of this source code is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:dartssh/protocol.dart';
import 'package:dartssh/serializable.dart';

abstract class AgentMessage extends Serializable {
  int id;
  AgentMessage(this.id);

  Uint8List toRaw() {
    Uint8List buffer = Uint8List(5 + serializedSize);
    SerializableOutput output = SerializableOutput(buffer);
    output.addUint32(buffer.length - 4);
    output.addUint8(id);
    serialize(output);
    assert(output.done);
    return buffer;
  }
}

class AGENT_FAILURE extends AgentMessage {
  static const int ID = 5;
  AGENT_FAILURE() : super(ID);

  @override
  int get serializedHeaderSize => 0;

  @override
  int get serializedSize => serializedHeaderSize;

  @override
  void deserialize(SerializableInput input) {}

  @override
  void serialize(SerializableOutput output) {}
}

class AGENTC_REQUEST_IDENTITIES {
  static const int ID = 11;
}

class AGENT_IDENTITIES_ANSWER extends AgentMessage {
  static const int ID = 12;
  List<MapEntry<String, String>> keys;
  AGENT_IDENTITIES_ANSWER() : super(ID);

  @override
  int get serializedHeaderSize => 4;

  @override
  int get serializedSize => keys.fold(
      serializedHeaderSize, (v, e) => v + 8 + e.key.length + e.value.length);

  @override
  void deserialize(SerializableInput input) {}

  @override
  void serialize(SerializableOutput output) {
    output.addUint32(keys.length);
    for (MapEntry<String, String> key in keys) {
      serializeString(output, key.key);
      serializeString(output, key.value);
    }
  }
}

class AGENTC_SIGN_REQUEST extends AgentMessage {
  static const int ID = 13;
  String key, data;
  int flags;
  AGENTC_SIGN_REQUEST() : super(ID);

  @override
  int get serializedHeaderSize => 4 * 3;

  @override
  int get serializedSize => serializedHeaderSize + key.length + data.length;

  @override
  void deserialize(SerializableInput input) {
    key = deserializeString(input);
    data = deserializeString(input);
    flags = input.getUint32();
  }

  @override
  void serialize(SerializableOutput output) {}
}

class AGENT_SIGN_RESPONSE extends AgentMessage {
  static const int ID = 14;
  String sig;
  AGENT_SIGN_RESPONSE(this.sig) : super(ID);

  @override
  int get serializedHeaderSize => 4;

  @override
  int get serializedSize => serializedHeaderSize + sig.length;

  @override
  void deserialize(SerializableInput input) => sig = deserializeString(input);

  @override
  void serialize(SerializableOutput output) => serializeString(output, sig);
}
