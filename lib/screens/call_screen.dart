import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../components/colors.dart';
import '../services/signalling.service.dart';

class CallScreen extends StatefulWidget {
  final String callerId, calleeId;
  final dynamic offer;
  const CallScreen({
    super.key,
    this.offer,
    required this.callerId,
    required this.calleeId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // socket instance
  final socket = SignallingService.instance.socket;

  // videoRenderer for localPeer
  final _localRTCRenderer = RTCVideoRenderer();

  // videoRenderer for remotePeer
  final _remoteRTCRenderer = RTCVideoRenderer();

  // mediaStream for localPeer
  MediaStream? _localStream;

  // RTC peer connection
  RTCPeerConnection? _rtcPeerConnection;

  // list of rtcCandidates to be sent over signalling
  List<RTCIceCandidate> rtcIceCadidates = [];

  // media status
  bool isAudioOn = true;
  bool isOtherInCall = true;

  @override
  void initState() {
    // initializing renderers
    _initializeRenderers();

    // setup Peer Connection
    _setupPeerConnection();
    super.initState();
  }

  void _initializeRenderers() async {
    await _localRTCRenderer.initialize();
    await _remoteRTCRenderer.initialize();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  _setupPeerConnection() async {
    // create peer connection
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': 'turn:relay1.expressturn.com:3478',
          'credential': 'IVjI7zDT70q8ELRr',
          'username': 'ef5UQOZRG5ZSIS9PJB',
        },
        {
          'urls': [
            // 'stun1.voiceeclipse.net:3478'
            // 'stun:global.stun.twilio.com:3478',
            // 'stun:stun4.l.google.com:19302'
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });

    // listen for remotePeer mediaTrack event
    _rtcPeerConnection!.onTrack = (event) {
      _remoteRTCRenderer.srcObject = event.streams[0];
      setState(() {});
    };

    // get localStream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
    });

    // add mediaTrack to peerConnection
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    // set source for local video renderer
    _localRTCRenderer.srcObject = _localStream;
    setState(() {});

    // for Incoming call
    if (widget.offer != null) {
      // listen for Remote IceCandidate
      socket!.on("IceCandidate", (data) {
        String candidate = data["iceCandidate"]["candidate"];
        String sdpMid = data["iceCandidate"]["id"];
        int sdpMLineIndex = data["iceCandidate"]["label"];

        // add iceCandidate
        _rtcPeerConnection!.addCandidate(RTCIceCandidate(
          candidate,
          sdpMid,
          sdpMLineIndex,
        ));
      });

      // set SDP offer as remoteDescription for peerConnection
      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(widget.offer["sdp"], widget.offer["type"]),
      );

      // create SDP answer
      RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();

      // set SDP answer as localDescription for peerConnection
      _rtcPeerConnection!.setLocalDescription(answer);

      // send SDP answer to remote peer over signalling
      socket!.emit("answerCall", {
        "callerId": widget.callerId,
        "sdpAnswer": answer.toMap(),
      });
    }
    // for Outgoing Call
    else {
      // listen for local iceCandidate and add it to the list of IceCandidate
      _rtcPeerConnection!.onIceCandidate =
          (RTCIceCandidate candidate) => rtcIceCadidates.add(candidate);

      // when call is accepted by remote peer
      socket!.on("callAnswered", (data) async {
        // set SDP answer as remoteDescription for peerConnection
        await _rtcPeerConnection!.setRemoteDescription(
          RTCSessionDescription(
            data["sdpAnswer"]["sdp"],
            data["sdpAnswer"]["type"],
          ),
        );

        // send iceCandidate generated to remote peer over signalling
        for (RTCIceCandidate candidate in rtcIceCadidates) {
          socket!.emit("IceCandidate", {
            "calleeId": widget.calleeId,
            "iceCandidate": {
              "id": candidate.sdpMid,
              "label": candidate.sdpMLineIndex,
              "candidate": candidate.candidate
            }
          });
        }
      });

      // create SDP Offer
      RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();

      // set SDP offer as localDescription for peerConnection
      await _rtcPeerConnection!.setLocalDescription(offer);

      // make a call to remote peer over signalling
      socket!.emit('makeCall', {
        "calleeId": widget.calleeId,
        "sdpOffer": offer.toMap(),
      });
    }
  }

  _leaveCall() {
    Navigator.pop(context);
  }

  _toggleMic() {
    // change status
    isAudioOn = !isAudioOn;
    // enable or disable audio track
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("P2P Call App"),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: size.height * 0.1,
            ),
            Text(
              widget.calleeId,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                color: ColorList.deliveryDetailsDailyTitleColor,
              ),
            ),
            SizedBox(
              height: size.height * 0.04,
            ),
            Text(
              "03:12",
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                color: ColorList.deliveryDetailsDailyTitleColor,
              ),
            ),
            SizedBox(
              height: size.height * 0.04,
            ),
            Image.asset('assets/images/call.png'),
            SizedBox(
              height: size.height * 0.08,
            ),
            // Text(
            //   "Connected",
            //   style: TextStyle(
            //     fontWeight: FontWeight.w400,
            //     fontSize: 14 * MediaQuery.of(context).textScaleFactor,
            //     color: ColorList.deliveryDetailsDailyTitleColor,
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.04,
            // ),
            // Text(
            //   "CalleID",
            //   style: TextStyle(
            //     fontWeight: FontWeight.w700,
            //     fontSize: 20 * MediaQuery.of(context).textScaleFactor,
            //     color: ColorList.deliveryDetailsDailyTitleColor,
            //   ),
            // ),
            // SizedBox(
            //   height: size.height * 0.10,
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // GestureDetector(
                //   onTap: _toggleMic,
                //   child: Container(
                //     width: size.width * 0.19,
                //     height: size.height * 0.18,
                //     decoration: const BoxDecoration(
                //       shape:  BoxShape.circle,
                //       color: ColorList.darkGrey,
                //     ),
                //     child: Center(
                //       child: Image.asset('assets/images/call_sound.png'),
                //     ),
                //   ),
                // ),

                GestureDetector(
                  onTap: _toggleMic,
                  child: Container(
                    width: size.width * 0.19,
                    height: size.height * 0.18,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorList.darkGrey,
                    ),
                    child: Center(
                      child: Icon(
                        isAudioOn ? Icons.mic : Icons.mic_off,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: size.width * 0.08,
                ),
                GestureDetector(
                  onTap: _leaveCall,
                  child: Container(
                    width: size.width * 0.19,
                    height: size.height * 0.16,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorList.lightRed,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                        size: 33,
                      ),
                    ),
                  ),
                ),
              ],
            ),


          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _localRTCRenderer.dispose();
    _remoteRTCRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    // Dispose of socket listeners if necessary
    super.dispose();
  }
}