import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../../utils/constants.dart';

class PickupCall extends StatefulWidget {
  const PickupCall({Key? key}) : super(key: key);

  @override
  State<PickupCall> createState() => _PickupCallState();
}

class _PickupCallState extends State<PickupCall> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: const Text("Pickup Call",style: TextStyle(fontFamily: Poppins),),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 100,),
            //show miss call notification
            ElevatedButton(onPressed: ()async{
              CallKitParams params=const CallKitParams(
                  id: "12",
                  nameCaller: "Coding Is Life",
                  handle: "1234567890",
                  type: 1,
                  // textMissedCall: "Missed call",
                  // textCallback: "Call Back",
                  extra: {"userId":"1234fg"}
              );
              await FlutterCallkitIncoming.showMissCallNotification(params);
            }, child: const Text("Missed call",style: TextStyle(fontFamily: Poppins))),
            const SizedBox(height: 20,),
            //outgoing call

            ElevatedButton(onPressed: ()async{
              try{
                CallKitParams params= const CallKitParams(
                  id: "12dgv",
                  nameCaller: "Coding Is Life",
                  handle: "1234567890",
                  type: 1,
                  ios: IOSParams(handleType: 'generic'),
                  extra: {"userId":"1234fg"},
                );
                await FlutterCallkitIncoming.startCall(params);
              }catch(e){
                print("EXCE=====$e");
              }
            }, child: const Text("OutGoing",style: TextStyle(fontFamily: Poppins))),
            //we will check it latter
            const SizedBox(height: 20,),
            //incoming call
            ElevatedButton(onPressed: ()async{
              CallKitParams params=const CallKitParams(
                  id: "21232dgfgbcbgb",
                  nameCaller: "Coding Is Life",
                  appName: "Demo",
                  avatar: "https://i.pravata.cc/100",
                  handle: "123456",
                  type: 0,
                  textAccept: "Accept",
                  textDecline: "Decline",
                  // textMissedCall: "Missed call",
                  // textCallback: "Call back",
                  duration: 30000,
                  extra: {'userId':"sdhsjjfhuwhf"},
                  android: AndroidParams(
                      isCustomNotification: true,
                      isShowLogo: false,
                      // isShowCallback: false,
                      // isShowMissedCallNotification: true,
                      ringtonePath: 'system_ringtone_default',
                      backgroundColor: "#0955fa",
                      backgroundUrl: "https://i.pravata.cc/500",
                      actionColor: "#4CAF50",
                      incomingCallNotificationChannelName: "Incoming call",
                      missedCallNotificationChannelName: "Missed call"
                  ),
                  ios: IOSParams(
                      iconName: "Call Demo",
                      handleType: 'generic',
                      supportsVideo: true,
                      maximumCallGroups: 2,
                      maximumCallsPerCallGroup: 1,
                      audioSessionMode: 'default',
                      audioSessionActive: true,
                      audioSessionPreferredSampleRate: 44100.0,
                      audioSessionPreferredIOBufferDuration: 0.005,
                      supportsDTMF: true,
                      supportsHolding: true,
                      supportsGrouping: false,
                      ringtonePath: 'system_ringtone_default'
                  )
              );
              await FlutterCallkitIncoming.showCallkitIncoming(params);
            }, child: const Text("Incoming",style: TextStyle(fontFamily: Poppins)))
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
