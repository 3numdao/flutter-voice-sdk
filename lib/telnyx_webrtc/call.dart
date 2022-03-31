import 'dart:convert';

import 'package:telnyx_flutter_webrtc/telnyx_webrtc/model/verto/send/bye_message_body.dart';
import 'package:telnyx_flutter_webrtc/telnyx_webrtc/model/verto/send/info_dtmf_message_body.dart';
import 'package:telnyx_flutter_webrtc/telnyx_webrtc/model/verto/send/invite_answer_message_body.dart';
import 'package:telnyx_flutter_webrtc/telnyx_webrtc/model/verto/send/modify_message_body.dart';
import 'package:telnyx_flutter_webrtc/telnyx_webrtc/peer/peer.dart';
import 'package:telnyx_flutter_webrtc/telnyx_webrtc/telnyx_client.dart';
import 'package:telnyx_flutter_webrtc/telnyx_webrtc/tx_socket.dart'
    if (dart.library.js) 'package:telnyx_flutter_webrtc/telnyx_webrtc/tx_socket_web.dart';
import 'package:uuid/uuid.dart';
import 'model/verto/receive/incoming_invitation_body.dart';

class Call {
  Call(this._txSocket, this._telnyxClient, this._sessionId);

  final TxSocket _txSocket;
  final TelnyxClient _telnyxClient;
  final String _sessionId;
  late String? callId;
  Peer? peerConnection;

  bool onHold = false;
  String sessionCallerName = "";
  String sessionCallerNumber = "";
  String sessionDestinationNumber = "";
  String sessionClientState = "";

  void newInvite(String callerName, String callerNumber,
      String destinationNumber, String clientState) {
    sessionCallerName = callerName;
    sessionCallerNumber = callerNumber;
    sessionDestinationNumber = destinationNumber;
    sessionClientState = clientState;

    var inviteCallId = const Uuid().toString();
    callId = inviteCallId;

    var base64State = base64.encode(utf8.encode(clientState));

    peerConnection = Peer(_txSocket);

    //Todo check if call id is null, and log that call ID is missing from invitation.
    peerConnection?.invite("0", "audio", callerName, callerNumber,
        destinationNumber, base64State, callId!, _sessionId);
  }

  void acceptCall(IncomingInvitation invite, String callerName,
      String callerNumber, String clientState) {
    callId = invite.params?.callID;
    var destinationNum = invite.params?.calleeIdNumber;

    peerConnection = Peer(_txSocket);
    peerConnection?.accept("0", "audio", callerName, callerNumber,
        destinationNum!, clientState, callId!, invite);
  }

  void endCall(String? callID) {
    var uuid = const Uuid();
    var byeDialogParams = ByeDialogParams(callId: callID);

    var byeParams = ByeParams(
        cause: CauseCode.USER_BUSY.name,
        causeCode: CauseCode.USER_BUSY.index + 1,
        dialogParams: byeDialogParams,
        sessionId: _sessionId);

    var byeMessage = ByeMessage(
        id: uuid.toString(),
        jsonrpc: "2.0",
        method: "telnyx_rtc.bye",
        params: byeParams);

    String jsonByeMessage = jsonEncode(byeMessage);
    _txSocket.send(jsonByeMessage);
    if (peerConnection != null) {
      peerConnection?.closeSession(_sessionId);
    }
  }

  void dtmf(String? callID, String tone) {
    var uuid = const Uuid();
    var dialogParams = DialogParams(
        attach: false,
        audio: true,
        callID: callId,
        callerIdName: sessionCallerName,
        callerIdNumber: sessionCallerNumber,
        clientState: sessionClientState,
        destinationNumber: sessionDestinationNumber,
        remoteCallerIdName: "",
        screenShare: false,
        useStereo: false,
        userVariables: [],
        video: false);

    var infoParams = InfoParams(
        dialogParams: dialogParams, dtmf: tone, sessionId: _sessionId);

    var dtmfMessageBody = DtmfInfoMessage(
        id: uuid.toString(),
        jsonrpc: "2.0",
        method: "telnyx_rtc.info",
        params: infoParams);

    String jsonDtmfMessage = jsonEncode(dtmfMessageBody);
    _txSocket.send(jsonDtmfMessage);
  }

  void onMuteUnmutePressed() {
    peerConnection?.muteUnmuteMic();
  }

  void onHoldUnholdPressed() {
    if (onHold) {
      _sendHoldModifier("unhold");
      onHold = false;
    } else {
      _sendHoldModifier("hold");
      onHold = true;
    }
  }

  void _sendHoldModifier(String action) {
    var uuid = const Uuid();
    var dialogParams = DialogParams(
        attach: false,
        audio: true,
        callID: callId,
        callerIdName: sessionCallerName,
        callerIdNumber: sessionCallerNumber,
        clientState: sessionClientState,
        destinationNumber: sessionDestinationNumber,
        remoteCallerIdName: "",
        screenShare: false,
        useStereo: false,
        userVariables: [],
        video: false);

    var modifyParams = ModifyParams(
        action: action, dialogParams: dialogParams, sessionId: _sessionId);

    var modifyMessage = ModifyMessage(
        id: uuid.toString(),
        method: "telnyx_rtc.modify",
        params: modifyParams,
        jsonrpc: "2.0");

    String jsonModifyMessage = jsonEncode(modifyMessage);
    _txSocket.send(jsonModifyMessage);
  }
}
