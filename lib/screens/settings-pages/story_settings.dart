import 'dart:convert';
//import 'package:fashiontimefinal/screens/pages/turnOffStory/allhiddenstories.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;

class StorySettings extends StatefulWidget {
  final Function onNavigate;
  final int myIndex;
  final Function navigateTo;
  const StorySettings({super.key, required this.onNavigate, required this.myIndex, required this.navigateTo});

  @override
  State<StorySettings> createState() => _StorySettingsState();
}

class _StorySettingsState extends State<StorySettings> {
  String id = "";
  String token = "";
  String index = "0";
  bool isSwitchedOn=true;
  TextEditingController password=TextEditingController();
  bool show_stories_to_non_friends = false;
  bool loading = false;
  bool storyTimer = false;

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(token);
    getProfile();
  }

  getProfile() {
    // myPosts.clear();
    // commentedPost.clear();
    // likedPost.clear();
    https.get(Uri.parse("$serverUrl/user/api/profile/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      print("Profile data ==> ${value.body.toString()}");
      final body = utf8.decode(value.bodyBytes);
      final jsonData = jsonDecode(body);
      print("show_stories_to_non_friends ==> ${jsonData["show_stories_to_non_friends"]}");
      setState(() {
        show_stories_to_non_friends = jsonData["show_stories_to_non_friends"];
      });
    });
    // getMyPosts();
  }
  toggleShowStory(bool boolValue) {
    // myPosts.clear();
    // commentedPost.clear();
    // likedPost.clear();
    setState(() {
      loading = true;
    });
    https.patch(Uri.parse("$serverUrl/user/api/allUsers/${id}/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    },
        body: json.encode({
          "show_stories_to_non_friends": boolValue
        })
    ).then((value) {
      print("Profile data ==> ${value.body.toString()}");
      final jsonData = json.decode(value.body);
      print("show_stories_to_non_friends ==> ${jsonData["show_stories_to_non_friends"]}");
      setState(() {
        show_stories_to_non_friends = boolValue;
        loading = false;
      });
      getProfile();
    });
    // getMyPosts();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
    getBoolFromPrefs("timer");
  }

  getBoolFromPrefs(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    storyTimer = prefs.getBool(key)!; // Returns null if the value doesn't exist
  }

  saveBoolToPrefs(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

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
        //   backgroundColor: primary,
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
        //   title: const Text("Story Settings",style: TextStyle(fontFamily: Poppins,),),
        // ),
        body: ListView(
          children: [
            WidgetAnimator(
              Padding(
                  padding: const EdgeInsets.only(left:10.0,right: 10.0,top: 8,bottom: 8),
                  child: Card(
                    elevation: 5,
                    child: ListTile(
                      leading: Icon(Icons.visibility_off, color: secondary),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Story Visibility",
                            style: TextStyle(color: primary, fontFamily: Poppins,),
                          ),
                          SizedBox(width: 7,),
                          GestureDetector(
                              onTap: (){
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: primary,
                                    title: const Text("Story Visibility",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                    content: const Text("When the toggle is on, only your friends and fans will be able to see your stories. When the toggle is off, everybody will be able to see your stories.",style: TextStyle(color: ascent,fontFamily: Poppins,),),
                                    actions: [
                                      TextButton(
                                        child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                        onPressed:  () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.all(Radius.circular(20))
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: Icon(Icons.question_mark,size: 15,),
                                  )))
                        ],
                      ),
                      trailing: Container(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: show_stories_to_non_friends,
                              activeColor: primary,// Assuming 0 means 'On' and 1 means 'Off'
                              onChanged: loading == true ? (value){} : (value) {
                                  setState(() {
                                    show_stories_to_non_friends = value;
                                  });
                                  toggleShowStory(value);
                              },
                            ),
                            if(loading == true) SizedBox(width: 5,),
                            if(loading == true) SpinKitCircle(color: primary,size: 10,)
                          ],
                        ),
                      ),
                    ),
                  )
              ),
            ),
            WidgetAnimator(
              Padding(
                  padding: const EdgeInsets.only(left:10.0,right: 10.0,top: 8,bottom: 8),
                  child: Card(
                    elevation: 5,
                    child: ListTile(
                      leading: Icon(Icons.timer, color: secondary),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Timer Visibility",
                            style: TextStyle(color: primary, fontFamily: Poppins,),
                          ),
                          SizedBox(width: 7,),
                          GestureDetector(
                              onTap: (){
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: primary,
                                    title: const Text("Timer Visibility",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                    content: const Text("When the toggle is on, the timer for the stories will run. When the toggle is off, the timer will not run for the stories.",style: TextStyle(color: ascent,fontFamily: Poppins,),),
                                    actions: [
                                      TextButton(
                                        child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                        onPressed:  () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.all(Radius.circular(20))
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: Icon(Icons.question_mark,size: 15,),
                                  )))
                        ],
                      ),
                      trailing: Switch(
                        value: storyTimer,
                        activeColor: primary,// Assuming 0 means 'On' and 1 means 'Off'
                        onChanged: (value) {
                          setState(() {
                            storyTimer = value;
                          });
                          saveBoolToPrefs("timer",storyTimer);
                        },
                      ),
                    ),
                  )
              ),
            ),
            WidgetAnimator(
              GestureDetector(
                onTap: (){
                  widget.onNavigate(18);
                  //Navigator.push(context, MaterialPageRoute(builder: (context) =>  AllHiddenStories()));
                },
                child: Padding(
                  padding: const EdgeInsets.only(left:10.0,right: 10.0,top: 8,bottom: 8),
                  child: Card(
                    elevation: 5,
                    child: ListTile(
                      leading: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade700, // Background color
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(Icons.close,color: Colors.red,size: 17,)),
                          )),
                      title: Text("Hidden Stories",style: TextStyle(
                        color: primary,
                        fontFamily: Poppins,
                      ),),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
