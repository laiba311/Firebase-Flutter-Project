import 'package:finalfashiontimefrontend/helpers/database_methods.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class DestroyChat extends StatefulWidget {
  final String? Channelname;
  const DestroyChat({
    this.Channelname,
    super.key});

  @override
  State<DestroyChat> createState() => _DestroyChatState();
}

class _DestroyChatState extends State<DestroyChat> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                stops: const [0.0, 0.99],
                tileMode: TileMode.clamp,
                colors: <Color>[
                  secondary,
                  primary,
                ]),
          ),
        ),
        backgroundColor: primary,
        title: const Text("Video Call ", style: TextStyle(fontFamily: Poppins)),
      ),
      body: Center(
        child:
        AlertDialog(
          backgroundColor: primary,
          title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
          content: const Text("Video Call has been disconnected or the User is not answering the call.",style: TextStyle(color: ascent,fontFamily: Poppins),),
          actions: [
            TextButton(
              child: const Text("Yes",style: TextStyle(color: ascent,fontFamily: Poppins),),
              onPressed:  () async {
                DatabaseMethods().endCallRoom(widget.Channelname.toString());
                Navigator.pop(context);

                }
              ,)
          ],
        ),
        // child: Container(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     crossAxisAlignment: CrossAxisAlignment.center,
        //     children: [
        //       Text("Video Call has been disconnected or User is not answering.",style: TextStyle(fontFamily: Poppins),),
        //       SizedBox(height: 20,),
        //       ElevatedButton(
        //         onPressed: () => DatabaseMethods().endCallRoom(widget.Channelname.toString()),
        //         child: Text("OK"),
        //         style: ElevatedButton.styleFrom(
        //           backgroundColor: primary, // Set the background color to match your app's primary color
        //           textStyle: TextStyle(
        //             fontFamily: Poppins, // Set the font family
        //           ),
        //         ),
        //       )
        //     ],
        //   )
        // ),
      )
    );
  }
}
