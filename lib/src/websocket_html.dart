// Copyright 2019 dartssh developers
// Use of this source code is governed by a MIT-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:dartssh2/src/socket.dart';
import 'package:dartssh2/src/transport.dart';

/// dart:html [WebSocket] based implementation of [SocketInterface].
class WebSocketImpl extends SocketInterface {
  static const String type = 'html';

  html.WebSocket? socket;
  Uint8ListCallback? messageHandler;
  StringCallback? errorHandler, doneHandler;
  late VoidCallback connectCallback;
  StreamSubscription? connectErrorSubscription,
      messageSubscription,
      errorSubscription,
      doneSubscription;

  @override
  bool get connected => socket != null && !connecting;

  @override
  bool get connecting => connectErrorSubscription != null;

  @override
  void close() {
    messageHandler = null;
    errorHandler = null;
    doneHandler = null;
    if (errorSubscription != null) {
      errorSubscription!.cancel();
      errorSubscription = null;
    }
    if (doneSubscription != null) {
      doneSubscription!.cancel();
      doneSubscription = null;
    }
    if (messageSubscription != null) {
      messageSubscription!.cancel();
      messageSubscription = null;
    }
    if (socket != null) {
      socket!.close();
      socket == null;
    }
  }

  @override
  void connect(Uri uri, VoidCallback onConnected, StringCallback onError,
      {int timeoutSeconds = 15, bool ignoreBadCert = false}) {
    assert(!connecting);

    /// No way to allow self-signed certificates.
    assert(!ignoreBadCert);
    try {
      connectCallback = onConnected;
      socket = html.WebSocket('$uri');
      socket!.onOpen.listen(connectSucceeded);
      connectErrorSubscription =
          socket!.onError.listen((error) => onError('$error'));
    } catch (error) {
      onError('$error');
    }
  }

  void connectSucceeded(dynamic x) {
    connectErrorSubscription!.cancel();
    connectErrorSubscription = null;
    connectCallback();
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void handleError(StringCallback newErrorHandler) =>
      errorHandler = newErrorHandler;

  @override
  // ignore: avoid_renaming_method_parameters
  void handleDone(StringCallback newDoneHandler) =>
      doneHandler = newDoneHandler;

  @override
  // ignore: avoid_renaming_method_parameters
  void listen(Uint8ListCallback newMessageHandler) {
    messageHandler = newMessageHandler;

    // ignore: prefer_conditional_assignment
    if (errorSubscription == null) {
      errorSubscription = socket!.onError.listen((error) {
        if (errorHandler != null) {
          errorHandler!('$error');
        }
      });
    }

    // ignore: prefer_conditional_assignment
    if (doneSubscription == null) {
      doneSubscription = socket!.onClose.listen((closeEvent) {
        if (doneHandler != null) {
          doneHandler!('$closeEvent');
        }
      });
    }

    // ignore: prefer_conditional_assignment
    if (messageSubscription == null) {
      messageSubscription = socket!.onMessage.listen((e) {
        if (messageHandler != null) {
          messageHandler!(e.data);
        }
      });
    }
  }

  @override
  void send(String text) => socket!.sendString(text);

  @override
  void sendRaw(Uint8List raw) => socket!.send(raw);
}
