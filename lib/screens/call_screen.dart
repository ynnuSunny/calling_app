import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../services/signalling.service.dart';

class CallScreen extends StatefulWidget {
  final String callerId, calleeId;
  final dynamic offer;
  const CallScreen({
    super.key,
    required this.callerId,
    required this.calleeId,
    required this.offer,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // socket instance
  final socket = SignallingService.instance.socket;

  String caller = "";
  String callee= "";

  @override
  void initState() {
    _setupPeerConnection();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  _setupPeerConnection() async {
    // for Incoming call
    if (widget.offer == true) {
      // send SDP answer to remote peer over signalling
      socket!.emit("answerCall", {
        "callerId": widget.callerId,
        "sdpAnswer": false,
      });
      caller = widget.calleeId;
      callee = widget.callerId;
    }
    // for Outgoing Call
    else {
      // make a call to remote peer over signalling
      socket!.emit('makeCall', {
        "calleeId": widget.calleeId,
        "sdpOffer": true,
      });

      caller = widget.callerId;
      callee = widget.calleeId;


    }
  }



  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID:
      1607082361, // Fill in the appID that you get from ZEGOCLOUD Admin Console.
      appSign:
      'e99c58c1857a0a48f573dffd8c691df72e83a8dd8534917d783042447ebab7a6', // Fill in the appSign that you get from ZEGOCLOUD Admin Console.
      userID: caller,
      userName: caller,
      callID: callee,
      // You can also use groupVideo/groupVoice/oneOnOneVoice to make more types of calls.
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
    );
  }
}
