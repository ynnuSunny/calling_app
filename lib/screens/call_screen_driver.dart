import 'package:flutter/material.dart';
import '../../components/colors.dart';

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
