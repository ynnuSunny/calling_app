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
      148227994, // Fill in the appID that you get from ZEGOCLOUD Admin Console.
      appSign:
      '3f0929b2883c17e55776fbe1b5366a0b990b0e63b956c95cb6a3c45bb595934a', // Fill in the appSign that you get from ZEGOCLOUD Admin Console.
      userID: caller,
      userName: caller,
      callID: callee,
      // You can also use groupVideo/groupVoice/oneOnOneVoice to make more types of calls.
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
    );
  }
}
