import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:http/http.dart' as https;

import '../../animations/bottom_animation.dart';
import '../../utils/constants.dart';
class ReportReelCommentScreen extends StatefulWidget {
  final int commentId;
  const ReportReelCommentScreen({super.key, required this.commentId});

  @override
  State<ReportReelCommentScreen> createState() => _ReportReelCommentScreenState();
}
String id='';
String token = "";
bool nudity = false;
bool spam = false;
bool terrorism = false;
bool hateSpeech = false;
bool falseInformation = false;
bool harassment = false;
bool violence = false;
TextEditingController somethingElse=TextEditingController();
final Shader linearGradient = LinearGradient(
  colors: <Color>[secondary, primary],
).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

getCashedData() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  id = preferences.getString("id")!;
  token = preferences.getString("token")!;
  // username = preferences.getString('username')!;

  print(token);
}
postReport(String commentId) async {
  String url = '$serverUrl/fashionReportBothComments/';
  Map<String, dynamic> requestBody = {
    "user": int.parse(id),
    "reelComment":int.parse(commentId) ,
  };

  if (nudity == true) {
    requestBody['reportReason'] = 'nudity';
  } else if (spam == true) {
    requestBody['reportReason'] = 'spam';
  } else if (somethingElse.text.isNotEmpty) {
    requestBody['reportReason'] = 'something-else';
    requestBody['somethingElse'] = somethingElse.text;
  } else if (terrorism == true) {
    requestBody['reportReason'] = 'terrorism';
  } else if (hateSpeech == true) {
    requestBody['reportReason'] = 'hate-speech';
  } else if (falseInformation == true) {
    requestBody['reportReason'] = 'false-information';
  } else if (harassment == true) {
    requestBody['reportReason'] = 'harassment';
  } else if (violence == true) {
    requestBody['reportReason'] = 'voilence';
  }

  try {
    // Now you can send the request with the requestBody
    // Example using http package
    var response = await https.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    // Handle the response here
    if (response.statusCode == 201) {
      // Request successful
      somethingElse.clear();
      debugPrint('Report submitted successfully');
      Fluttertoast.showToast(msg: "Report Sent",backgroundColor: primary);
    } else {
      // Handle other status codes or errors
      debugPrint('Failed to submit report. Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
    }
  } catch (error) {
    // Handle exceptions
    debugPrint('Error while submitting report: $error');
  }
}


class _ReportReelCommentScreenState extends State<ReportReelCommentScreen> {

  @override
  void initState() {
    // TODO: implement initState
    getCashedData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: primary,
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
                    ])),
          ),
          title: const Text(
            "Report Comment",
            style: TextStyle(fontFamily: Poppins),
          ),
        ),
        body: ListView(children: [
          const SizedBox(
            height: 20,
          ),
          Text(
            "Why are you reporting this comment?",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: Poppins,
                foreground: Paint()..shader = linearGradient),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Checkbox(
                activeColor: primary,
                checkColor: ascent,
                value: nudity,
                onChanged: (bool? val) {
                  setState(() {
                    nudity = val!;
                    spam = false;
                    terrorism = false;
                    hateSpeech = false;
                    falseInformation = false;
                    harassment = false;
                    violence = false;
                  });
                },
              ),
              Text("Nudity",
                  style: TextStyle(
                      color: primary,
                      fontFamily: Poppins,
                      fontWeight: FontWeight.bold)),
              const SizedBox(
                width: 10,
              ),
              Checkbox(
                activeColor: primary,
                checkColor: ascent,
                value: spam,
                onChanged: (bool? val) {
                  setState(() {
                    spam = val!;
                    nudity = false;
                    terrorism = false;
                    hateSpeech = false;
                    falseInformation = false;
                    harassment = false;
                    violence = false;
                  });
                },
              ),
              Text("Spam",
                  style: TextStyle(
                      color: primary,
                      fontFamily: Poppins,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Checkbox(
                activeColor: primary,
                checkColor: ascent,
                value: terrorism,
                onChanged: (bool? val) {
                  setState(() {
                    terrorism = val!;
                    nudity = false;
                    spam = false;
                    hateSpeech = false;
                    falseInformation = false;
                    harassment = false;
                    violence = false;
                  });
                },
              ),
              Text("Terrorism",
                  style: TextStyle(
                      color: primary,
                      fontFamily: Poppins,
                      fontWeight: FontWeight.bold)),
              Checkbox(
                activeColor: primary,
                checkColor: ascent,
                value: falseInformation,
                onChanged: (bool? val) {
                  setState(() {
                    falseInformation = val!;
                    nudity = false;
                    spam = false;
                    terrorism = false;
                    hateSpeech = false;
                    harassment = false;
                    violence = false;
                  });
                },
              ),
              Text("False Information",
                  style: TextStyle(
                      color: primary,
                      fontFamily: Poppins,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Checkbox(
                activeColor: primary,
                checkColor: ascent,
                value: harassment,
                onChanged: (bool? val) {
                  setState(() {
                    harassment = val!;
                    nudity = false;
                    spam = false;
                    terrorism = false;
                    hateSpeech = false;
                    falseInformation = false;
                    violence = false;
                  });
                },
              ),
              Text("Harassment",
                  style: TextStyle(
                      color: primary,
                      fontFamily: Poppins,
                      fontWeight: FontWeight.bold)),
              Checkbox(
                activeColor: primary,
                checkColor: ascent,
                value: violence,
                onChanged: (bool? val) {
                  setState(() {
                    violence = val!;
                    nudity = false;
                    spam = false;
                    terrorism = false;
                    hateSpeech = false;
                    falseInformation = false;
                    harassment = false;
                  });
                },
              ),
              Text("Violence",
                  style: TextStyle(
                      color: primary,
                      fontFamily: Poppins,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 80,),
          WidgetAnimator(
            Padding(
              padding: const EdgeInsets.only(
                  left: 30.0, right: 30.0, top: 0.0, bottom: 8.0),
              child: TextField(
                  controller: somethingElse,
                  maxLines: 5,
                  maxLength: 2500,
                  // focusNode: _descriptionFocusNode,
                  textCapitalization: TextCapitalization.sentences,
                  style:
                  TextStyle(color: primary, fontFamily: Poppins),
                  decoration: InputDecoration(
                    // errorText: _submitted == true ? "Description not filled." : null,
                      hintStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          fontFamily: Poppins),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 1, color: primary),
                      ),
                      focusColor: primary,
                      alignLabelWithHint: true,
                      hintText: "Something else,"),
                  cursorColor: primary,
                  onChanged: (text) {

                  }
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding:  EdgeInsets.only(top: MediaQuery.of(context).size.height*0.03),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.22),
                    child: Container(
                      height: 37,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.topRight,
                              stops: const [0.0, 0.99],
                              tileMode: TileMode.clamp,
                              colors:
                              // loading2 == true
                              //     ? [Colors.grey, Colors.grey]
                              //     :
                              <Color>[
                                secondary,
                                primary,
                              ])),
                      child: ElevatedButton(
                          style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              )),
                              backgroundColor:
                              MaterialStateProperty.all(Colors.transparent),
                              shadowColor:
                              MaterialStateProperty.all(Colors.transparent),
                              padding: MaterialStateProperty.all(EdgeInsets.only(
                                  top: 8,
                                  bottom: 8,
                                  left: MediaQuery.of(context).size.width * 0.26,
                                  right:
                                  MediaQuery.of(context).size.width * 0.26)),
                              textStyle: MaterialStateProperty.all(
                                  const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontFamily: Poppins))),
                          onPressed: () {
                            setState(() {
                              if(somethingElse.text.isNotEmpty){
                                nudity = false;
                                spam = false;
                                terrorism = false;
                                hateSpeech = false;
                                falseInformation = false;
                                harassment = false;
                                violence = false;

                              }
                            });
                            postReport(widget.commentId.toString());
                          },
                          child: const Text(
                            'Send Report',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                fontFamily: Poppins),
                          )),
                    ),
                  ),
                ),
              )
            ],
          ),
        ]));
  }
}
