import 'dart:convert';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import "package:http/http.dart"as https;
import 'package:shared_preferences/shared_preferences.dart';
class TextStoryScreen extends StatefulWidget {
  const TextStoryScreen({super.key});

  @override
  State<TextStoryScreen> createState() => _TextStoryScreenState();

}
String id = '';
String token = '';
TextEditingController storyText=TextEditingController();
class _TextStoryScreenState extends State<TextStoryScreen> {

  postStory() {
    String url = '$serverUrl/apiStory/';
    try {
      https.post(Uri.parse(url), headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      }, body: jsonEncode({
        "text":storyText.text.toString(),
        "user": int.parse(id)
      }),).then((value) {
        if (value.statusCode == 201) {
          Fluttertoast.showToast(msg: "Story uploaded",backgroundColor: primary);
          Navigator.pop(context);
        } else {
          debugPrint(
              "error received while uploading story===========>${value.statusCode}");
          Fluttertoast.showToast(msg: "Error!Please try again.",backgroundColor: Colors.red);
        }
      });
    } catch (e) {
      debugPrint("error received========>${e.toString()}");
    }
  }
  postStoryCloseFriend() {
    String url = '$serverUrl/apiStory/';
    try {
      https.post(Uri.parse(url), headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      }, body: jsonEncode({
        "text":storyText.text.toString(),
        "user": int.parse(id),
        "is_close_friend":true,
      }),).then((value) {
        if (value.statusCode == 201) {
          Fluttertoast.showToast(msg: "Story uploaded",backgroundColor: primary);
          Navigator.pop(context);
        } else {
          debugPrint(
              "error received while uploading story===========>${value.statusCode}");
          Fluttertoast.showToast(msg: "Error!Please try again.",backgroundColor: Colors.red);
        }
      });
    } catch (e) {
      debugPrint("error received========>${e.toString()}");
    }
  }
  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    debugPrint(preferences.getString("fcm_token"));
    debugPrint("user id is----->>>${preferences.getString("id")}");
  }

  @override
  void initState() {
    getCashedData();
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Align(
            //       alignment: Alignment.topRight,
            //       child: GestureDetector(
            //           onTap: () {
            //             debugPrint("button pressed");
            //             postStory();
            //           },
            //           child: Icon(
            //             Icons.check,
            //             color: primary,
            //             size: 40,
            //           ))),
            // ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.26,
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  focusColor: primary,
                  hoverColor: primary,
                  hintText: "What's on your mind?"
                ),
                cursorColor: primary,
                controller: storyText,

                style: TextStyle(
                  fontSize: 30,
                  fontFamily: Poppins,
                  color: primary,
                  decorationColor: primary,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton(
                      style: ButtonStyle(
                          elevation: MaterialStateProperty.all(10.0),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              )
                          ),
                          backgroundColor: MaterialStateProperty.all(Colors.pinkAccent),
                          padding: MaterialStateProperty.all(EdgeInsets.only(
                              top: 13,bottom: 13,
                              left:MediaQuery.of(context).size.width * 0.1,right: MediaQuery.of(context).size.width * 0.1)),
                          textStyle: MaterialStateProperty.all(
                              const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins))),
                      onPressed: () {
                        postStory();
                      },
                      child: const Text('Upload Story',style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: Poppins
                      ),)),
                  ElevatedButton(
                      style: ButtonStyle(
                          elevation: MaterialStateProperty.all(10.0),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              )
                          ),
                          backgroundColor: MaterialStateProperty.all(Colors.lightGreenAccent),
                          padding: MaterialStateProperty.all(EdgeInsets.only(
                              top: 13,bottom: 13,
                              left:MediaQuery.of(context).size.width * 0.1,right: MediaQuery.of(context).size.width * 0.1)),
                          textStyle: MaterialStateProperty.all(
                              const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins))),
                      onPressed: () {
                        postStoryCloseFriend();
                      },
                      child: const Text('Close friends',style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: Poppins
                      ),)),
                ],
              ),
            )
          ],
        ),
      ),
      backgroundColor: secondary,
    );
  }
}
