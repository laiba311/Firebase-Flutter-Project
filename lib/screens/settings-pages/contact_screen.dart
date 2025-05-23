import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../animations/bottom_animation.dart';
import '../../../utils/constants.dart';

class ContactScreen extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  const ContactScreen({Key? key, required this.myIndex, required this.navigateTo}) : super(key: key);

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.navigateTo(widget.myIndex);
        return Future.value(false);
      },
      child: Scaffold(
        // appBar: AppBar(
        //   centerTitle: true,
        //   flexibleSpace: Container(
        //     decoration: BoxDecoration(
        //         gradient: LinearGradient(
        //             begin: Alignment.topLeft,
        //             end: Alignment.topRight,
        //             stops: const [0.0, 0.99],
        //             tileMode: TileMode.clamp,
        //             colors: <Color>[
        //               secondary,
        //               primary,
        //             ])
        //     ),),
        //   backgroundColor: primary,
        //   title: const Text("Contact",style: TextStyle(fontFamily: Poppins,),),
        // ),
        body: ListView(
          children: [
            const SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Get in touch with us via",style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: Poppins,
                  ),)
                ],
              ),
            ),
            WidgetAnimator(
              GestureDetector(
                onTap: (){
                  sendMail();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left:10.0,right: 15.0,top: 8,bottom: 8),
                  child: Card(
                    elevation: 5,
                    child: ListTile(
                      leading: Icon(Icons.email,color: primary,),
                      title: Text("productionshomey@gmail.com",style: TextStyle(
                          color: primary,
                          fontFamily: Poppins,
                        fontSize: 14
                      ),),
                    ),
                  ),
                ),
              ),
            ),
            // WidgetAnimator(
            //   GestureDetector(
            //     onTap: (){
            //       sendCall();
            //     },
            //     child: Padding(
            //       padding: const EdgeInsets.only(left:15.0,right: 15.0,top: 8,bottom: 8),
            //       child: Card(
            //         elevation: 5,
            //         child: ListTile(
            //           leading: Icon(Icons.phone,color: primary),
            //           title: Text("+923432338765",style: TextStyle(
            //               color: primary,
            //               fontFamily: Poppins
            //           ),),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
  sendMail() async {
    // Android and iOS
    const uri =
        'mailto:productionshomey@gmail.com?subject=Applying for complain&body=Write your message';
    // if (await canLaunch(uri)) {
    //   await launch(uri);
    // } else {
    //   throw 'Could not launch $uri';
    // }
    launch(uri);
  }
  sendCall() async {
    // Android and iOS
    const uri =
        'tel://+923432338765';
    if (await canLaunch(uri)) {
      await launch(uri);
    } else {
      throw 'Could not launch $uri';
    }
  }
}
