import 'dart:io';
import 'package:logger/logger.dart';
import 'package:telnyx_flutter_webrtc/telnyx_webrtc/config/telnyx_config.dart';
import 'package:telnyx_flutter_webrtc/telnyx_webrtc/tx_socket.dart';
import 'package:uuid/uuid.dart';

class TelnyxClient {
  TxSocket txSocket = TxSocket("wss://rtc.telnyx.com:443");
  bool _closed = false;
  bool _connected = false;
  final logger = Logger();

  bool isConnected() {
    return _connected;
  }

  void connect(String providedHostAddress) {
    logger.i('connect()');
    if (isConnected()) {
      logger.i('WebSocket $providedHostAddress is already connected');
      return;
    }
    logger.i('connecting to WebSocket $providedHostAddress');
    try {
      txSocket.onOpen = () {
        _closed = false;
        _connected = true;
        logger.i('Web Socket is now connected');
        _onOpen();
      };

      txSocket.onMessage = (dynamic data) {
        _onMessage(data);
      };

      txSocket.onClose = (int closeCode, String closeReason) {
        logger.i('Closed [$closeCode, $closeReason]!');
        _connected = false;
        _onClose(true, closeCode, closeReason);
      };

      txSocket.connect(providedHostAddress);
    } catch (e, s) {
      logger.e(e.toString(), null, s);
      _connected = false;
      logger.e('WebSocket $providedHostAddress error: $e');
    }
  }

  void credentialLogin(CredentialConfig config) {
    var uuid = const Uuid();
    var user = config.sipUser;
    var password = config.sipPassword;
    var fcmToken = config.fcmToken;
  }

  void disconnect() {
    logger.i('disconnect()');
    if (_closed) return;
    // Don't wait for the WebSocket 'close' event, do it now.
    _closed = true;
    _connected = false;
    _onClose(true, 0, 'Client send disconnect');
    try {
      txSocket.close();
    } catch (error) {
      logger.e('close() | error closing the WebSocket: ' + error.toString());
    }
  }

  /// WebSocket Event Handlers
  void _onOpen() {
    logger.i('WebSocket connected');
  }

  void _onClose(bool wasClean, int code, String reason) {
    logger.i('WebSocket closed');
    if (wasClean == false) {
      logger.i('WebSocket abrupt disconnection');
    }
  }

  void _onMessage(dynamic data) {
    logger.i('Received WebSocket message');
    if (data != null) {
      if (data.toString().trim().isNotEmpty) {
      } else {
        logger.i('Received and ignored empty packet');
      }
    }
  }
}
