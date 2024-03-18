import 'package:flutter/material.dart';
import '../../components/colors.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signalling.service.dart';

class CallScreenDriver extends StatefulWidget {
  final String callerId, calleeId;
  final dynamic offer;
  const CallScreenDriver({
    super.key,
    this.offer,
    required this.callerId,
    required this.calleeId,
  });

  @override
  State<CallScreenDriver> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreenDriver> {
  // variables and functions from call_screen

  // socket instance
  final socket = SignallingService.instance.socket;

  // videoRenderer for localPeer
  final _localRTCVideoRenderer = RTCVideoRenderer();

  // videoRenderer for remotePeer
  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  // mediaStream for localPeer
  MediaStream? _localStream;

  // RTC peer connection
  RTCPeerConnection? _rtcPeerConnection;

  // list of rtcCandidates to be sent over signalling
  List<RTCIceCandidate> rtcIceCadidates = [];

  // media status
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;

  @override
  void initState() {
    // initializing renderers
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();

    // setup Peer Connection
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
    // create peer connection
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });

    // listen for remotePeer mediaTrack event
    _rtcPeerConnection!.onTrack = (event) {
      _remoteRTCVideoRenderer.srcObject = event.streams[0];
      setState(() {});
    };

    // get localStream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });

    // add mediaTrack to peerConnection
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    // set source for local video renderer
    _localRTCVideoRenderer.srcObject = _localStream;
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

  _toggleCamera() {
    // change status
    isVideoOn = !isVideoOn;

    // enable or disable video track
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });
    setState(() {});
  }

  _switchCamera() {
    // change status
    isFrontCameraSelected = !isFrontCameraSelected;

    // switch camera
    _localStream?.getVideoTracks().forEach((track) {
      // ignore: deprecated_member_use
      track.switchCamera();
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: size.height * 0.1,
          ),
          Text(
            "CallerID",
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                color: ColorList.deliveryDetailsDailyTitleColor),
          ),
          SizedBox(
            height: size.height * 0.04,
          ),
          Text(
            "03:12",
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                color: ColorList.deliveryDetailsDailyTitleColor),
          ),
          SizedBox(
            height: size.height * 0.04,
          ),
          Image.asset('assets/images/call.png'),
          SizedBox(
            height: size.height * 0.04,
          ),
          Text(
            "Connected",
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                color: ColorList.deliveryDetailsDailyTitleColor),
          ),
          SizedBox(
            height: size.height * 0.04,
          ),
          Text(
            "CalleID",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20 * MediaQuery.of(context).textScaleFactor,
                color: ColorList.deliveryDetailsDailyTitleColor),
          ),
          SizedBox(
            height: size.height * 0.10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  ///TODO: need to implement onTap
                },
                child: Container(
                  width: size.width * 0.19,
                  height: size.height * 0.18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorList.darkGrey,
                  ),
                  child: Center(
                    child: Image.asset('assets/images/call_sound.png'),
                  ),
                ),
              ),
              SizedBox(
                width: size.width * 0.08,
              ),
              GestureDetector(
                onTap: () {
                  ///TODO: need to implement onTap
                },
                child: Container(
                  width: size.width * 0.19,
                  height: size.height * 0.18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorList.darkGrey,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mic_off,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              ///TODO: need to implement onTap
              Navigator.of(context).pop();
            },
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
              )),
            ),
          ),
        ],
      ),
    );
  }
}
