import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../animations/bottom_animation.dart';
import '../../../utils/constants.dart';

class ReportScreen extends StatefulWidget {
  final String reportedID;
  const ReportScreen({Key? key, required this.reportedID}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  TextEditingController message = TextEditingController();
  bool loading1 = false;
  String id = "";
  String token = "";


  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(token);
  }

  sendReport(){
    setState(() {
      loading1 = true;
    });
    Map<String, dynamic> body = {
      "reason": "1",
      "something_else": message.text,
      "reporter": id,
      "reported_user": widget.reportedID
    };
    https.post(
        Uri.parse("$serverUrl/user/api/ReporUser/"),
        body: json.encode(body),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      print(value.body.toString());
      setState(() {
        loading1 = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: primary,
          title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
          content: const Text("Report send successfully",style: TextStyle(color: ascent,fontFamily: Poppins,),),
          actions: [
            TextButton(
              child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins,)),
              onPressed:  () {
                setState(() {
                  Navigator.pop(context);
                  Navigator.pop(context);
                });
              },
            ),
          ],
        ),
      );
    }).catchError((){
      setState(() {
        loading1 = false;
      });
      Navigator.pop(context);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("Report Id => ${widget.reportedID}");
    getCashedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
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
                  ])
          ),),
        backgroundColor: primary,
        title: const Text("Report",style: TextStyle(fontFamily: Poppins,),),
      ),
      body: ListView(
        children: [
          WidgetAnimator(
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: TextField(
                  controller: message,
                  style: const TextStyle(
                      color: Colors.pink,
                    fontFamily: Poppins,
                  ),
                  maxLines: 6,
                  decoration: const InputDecoration(
                      hintStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        fontFamily: Poppins,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.pink),
                      ),
                      //enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      //disabledBorder: InputBorder.none,
                      alignLabelWithHint: true,
                      hintText: "Enter Reason."
                  ),
                  cursorColor: Colors.pink,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:SizedBox(
        height: 70,
        child: Column(
          children: [
            // WidgetAnimator(
            //     Row(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       crossAxisAlignment: CrossAxisAlignment.center,
            //       children: [
            //         loading1 == true ? SpinKitCircle(color: primary,size: 70,) :Padding(
            //           padding: EdgeInsets.all(8.0),
            //           child: ElevatedButton(
            //               style:
            //               ButtonStyle(
            //                   shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            //                       RoundedRectangleBorder(
            //                         borderRadius: BorderRadius.circular(12.0),
            //                       )
            //                   ),
            //                     backgroundColor: MaterialStateProperty.all(primary),
            //                   padding: MaterialStateProperty.all(EdgeInsets.only(
            //                       top: 8,bottom: 8,
            //                       left:MediaQuery.of(context).size.width * 0.26,right: MediaQuery.of(context).size.width * 0.26)),
            //                   textStyle: MaterialStateProperty.all(
            //                       const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins))),
            //               onPressed: () {
            //                 if (message.text.isEmpty) {
            //                   print('report is not sent');
            //
            //                   showDialog(
            //                     context: context,
            //                     builder: (BuildContext context) {
            //                       return AlertDialog(
            //                         backgroundColor: primary,
            //                         title: Text(
            //                           "FashionTime",
            //                           style: TextStyle(color: ascent, fontFamily: Poppins, fontWeight: FontWeight.bold),
            //                         ),
            //                         content: Text(
            //                           "Report cannot be empty!",
            //                           style: TextStyle(color: ascent, fontFamily: Poppins),
            //                         ),
            //                         actions: [
            //                           TextButton(
            //                             child: Text("Okay", style: TextStyle(color: ascent, fontFamily: Poppins)),
            //                             onPressed: () {
            //                               Navigator.pop(context);
            //                             },
            //                           ),
            //                         ],
            //                       );
            //                     },
            //                   );
            //                 }
            //                 else{
            //                    sendReport();
            //
            //                 }
            //
            //               },
            //               child: const Text('Send Report',style: TextStyle(
            //                   fontSize: 20,
            //                   fontWeight: FontWeight.w700,
            //                   fontFamily: Poppins
            //               ),)),
            //         ),
            //       ],
            //     )
            // ),
            WidgetAnimator(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (message.text.isEmpty) {
                      print('report is not sent');

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: primary,
                            title: const Text(
                              "FashionTime",
                              style: TextStyle(color: ascent, fontFamily: Poppins, fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              "Report cannot be empty!",
                              style: TextStyle(color: ascent, fontFamily: Poppins,),
                            ),
                            actions: [
                              TextButton(
                                child: const Text("Okay", style: TextStyle(color: ascent, fontFamily: Poppins,)),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                    else{
                      sendReport();

                    }
                  },
                  child: Card(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Container(
                      alignment: Alignment.center,
                      height: 35,
                      width: MediaQuery.of(context).size.width * 0.8,
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
                          borderRadius: const BorderRadius.all(Radius.circular(12))),
                      child: const Text(
                        'Send Report',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          fontFamily: Poppins,),
                      ),
                    ),
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
