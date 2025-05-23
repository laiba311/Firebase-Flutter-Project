import 'dart:convert';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTextStory extends StatefulWidget {
  const AddTextStory({super.key});

  @override
  State<AddTextStory> createState() => _AddTextStoryState();
}

class _AddTextStoryState extends State<AddTextStory> {
  TextEditingController somethingElse=TextEditingController();
  String id='';
  String token = "";
  bool loading = false;
  bool mystory = true;
  bool stylemates = false;


  getCachedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCachedData();
  }

  postStory(String text) {
    setState(() {
      loading = true;
    });
    String url = '$serverUrl/story/stories/';
    var body = {
      "content": text,
      "type": "text"
    };

    try {
      http
          .post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      )
          .then((value) {
        if (value.statusCode == 201) {
          Fluttertoast.showToast(
              msg: "Story uploaded", backgroundColor: primary);
          setState(() {
            loading = false;
          });
          Navigator.pop(context);
        } else {
          setState(() {
            loading = false;
          });
          debugPrint(
              "error received while uploading story===========>${value.statusCode}");
        }
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("error received========>${e.toString()}");
    }
  }
  postStoryForStyleMates(String image) {
    String url = '$serverUrl/story/create-close-friends-story/';
    var body = {
      "content": image,
      "type": "text"
    };

    try {
      http
          .post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      )
          .then((value) {
        if (value.statusCode == 201) {
          Fluttertoast.showToast(
              msg: "Story uploaded for stylemates", backgroundColor: primary);
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          debugPrint(
              "error received while uploading story===========>${value.statusCode}");
        }
      });
    } catch (e) {
      debugPrint("error received========>${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
            onTap: (){
              Navigator.of(context).pop();
            },
            child: Icon(Icons.close)),
        centerTitle: true,
        title: Text('Text Story',style: TextStyle(
            fontSize: 16
        ),),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: (){
                  setState(() {
                    mystory = true;
                    stylemates = false;
                  });
                },
                child: Card(
                  color: mystory == true ? Colors.black54 : Colors.grey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text("Your Story"),
                  ),
                ),
              ),
              SizedBox(width: 5,),
              GestureDetector(
                onTap: (){
                  setState(() {
                    mystory = false;
                    stylemates = true;
                  });
                },
                child: Card(
                  color: stylemates == true ? Colors.black54 : Colors.grey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text("Stylemates"),
                  ),
                ),
              ),
            ],
          ),
          WidgetAnimator(
            Padding(
              padding: const EdgeInsets.only(
                  left: 30.0, right: 30.0, top: 10.0, bottom: 8.0),
              child: TextField(
                  controller: somethingElse,
                  maxLines: 10,
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
                      hintText: "Whats in your mind?"),
                  cursorColor: primary,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              loading == true ? SpinKitCircle(color: primary,) : Padding(
                padding:  EdgeInsets.only(top: MediaQuery.of(context).size.height*0.03),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.22),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.topRight,
                              stops: const [0.0, 0.99],
                              tileMode: TileMode.clamp,
                              colors:
                              <Color>[
                                Colors.black54,
                                Colors.black54,
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
                          onPressed: somethingElse.text.isEmpty == true ? null : () {
                            if(mystory == true) {
                              postStory(somethingElse.text);
                            } else if (stylemates == true){
                              postStoryForStyleMates(somethingElse.text);
                            }
                          },
                          child: Text(
                            'Upload Story',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: Poppins,
                                color: ascent
                            ),
                          )),
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
