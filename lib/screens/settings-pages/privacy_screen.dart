import 'dart:convert';
// import 'package:fashiontimefinal/screens/pages/settings_pages/close_friends.dart';
// import 'package:fashiontimefinal/screens/pages/turnOffStory/allhiddenstories.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/authentication/login_screen.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/block_list.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/close_friends.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import '../../../utils/constants.dart';

class PrivacyScreen extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  const PrivacyScreen({Key? key, required this.myIndex, required this.navigateTo}) : super(key: key);

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool loading1 = false;
  String id = "";
  String token = "";
  //String index = "0";
  bool isSwitchedOn=true;
  TextEditingController password=TextEditingController();
  bool show_stories_to_non_friends = false;
  bool private_account = false;
  bool style_visibility = false;
  bool loading = false;
  bool loading2 = false;

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    setState(() {
      //index = preferences.getString("toggle")!;
      isSwitchedOn = preferences.getBool("notify") == null ? true : false;
    });
    print(token);
    getProfile();
  }

  getProfile() {
    setState(() {
      loading = true;
    });
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
         private_account = jsonData["isPrivate"];
         style_visibility = jsonData["isStyleVisibility"];
         loading = false;
      });
    });
    // getMyPosts();
  }
  toggleShowStory(bool boolValue) {
    // myPosts.clear();
    // commentedPost.clear();
    // likedPost.clear();
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
      });
      getProfile();
    });
    // getMyPosts();
  }
  deleteAccount() async {

    setState(() {

    });
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: AlertDialog(
            title: const Text("FashionTime",style: TextStyle(fontFamily: Poppins,)),
            backgroundColor: primary,
            content: const Text('Enter your password',style: TextStyle(fontFamily: Poppins,)),

            actions:  [ Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller:password ,
              ),
            ),
            TextButton(child: const Text("Ok",style: TextStyle(fontFamily: Poppins,)),onPressed: () {
            deleteAccountAfterVerification();
            },)],
            actionsPadding: const EdgeInsets.only(bottom: 40),


          ),
        );
      },

    );


  }
  deleteAccountAfterVerification()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    https.delete(
        Uri.parse("$serverUrl/api/delete-account/"),body: {
          'password':password.text.toString()
    },
        headers: {
          
          "Authorization": "Bearer $token"
        }
    ).then((value){
      print(value.body.toString());
      setState(() {
        loading1 = false;
      });
      preferences.clear().then((value){
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
      });
    // ignore: argument_type_not_assignable_to_error_handler
    }).catchError((error) {
      setState(() {
        loading1 = false;
      });
      Navigator.pop(context);
      // Handle the error or log it
      print("Error occurred during account deletion: $error");
    });
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  saveNotification(index) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString("toggle",index.toString());
  }
  saveNotif(bool notify)async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setBool("notify", notify);

  }

  togglePrivate() async {
    setState(() {
      loading = true;
    });
    try {
      https.patch(
          Uri.parse("$serverUrl/user/api/profile/"),
          headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
         },
         body: json.encode({
           "isPrivate": !private_account
         })
      ).then((value) {
        setState(() {
          private_account = !private_account;
          loading = false;
        });
        style_visibility = false;
        toggleStyleVisibility(style_visibility);
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error updating profile: $e");
    }
  }
  toggleStyleVisibility(style) async {
    setState(() {
      loading2 = true;
    });
    try {
      https.patch(
          Uri.parse("$serverUrl/user/api/profile/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: json.encode({
            "isStyleVisibility": style
          })
      ).then((value) {
        setState(() {
          style_visibility = style;
          loading2 = false;
        });
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        loading2 = false;
      });
      print("Error updating profile: $e");
    }
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
        //   title: const Text("Privacy",style: TextStyle(fontFamily: Poppins,),),
        // ),
        body: ListView(
          children: [
            WidgetAnimator(
              GestureDetector(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) =>  const BlockList()));
                },
                child: Padding(
                  padding: const EdgeInsets.only(left:10.0,right: 10.0,top: 8,bottom: 8),
                  child: Card(
                    elevation: 5,
                    child: ListTile(
                      leading: const Icon(Icons.block,color: Colors.red,),
                      title: Text("Blocked Users",style: TextStyle(
                          color: primary,
                        fontFamily: Poppins,
                      ),),
                    ),
                  ),
                ),
              ),
            ),
            WidgetAnimator(
              Padding(
                padding: const EdgeInsets.only(left:10.0,right: 10.0,top: 8,bottom: 8),
                child: Card(
                  elevation: 5,
                  child: ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.green),
                    title: Row(
                      children: [
                        Text(
                          "Notifications",
                          style: TextStyle(color: primary, fontFamily: Poppins,),
                        ),
                        SizedBox(width: 5,),
                        GestureDetector(
                            onTap: (){
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: primary,
                                  title: const Text("Notifications",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                  content: const Text("When this toggle is enabled, all notifications will be turned on, including push notifications, emails, and in-app messages. If you disable this toggle, you will no longer receive any notifications, including push notifications, emails, and in-app messages. In the future, notifications will be categorized, allowing you to manage them more specifically.",style: TextStyle(color: ascent,fontFamily: Poppins,),),
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
                      value: isSwitchedOn,
                      activeColor: primary,// Assuming 0 means 'On' and 1 means 'Off'
                      onChanged: (value) {
                        setState(() {
                          isSwitchedOn = value;
                        });
                        saveNotif(value);
                        saveNotification(value ? '0' : '1');
                        print('switched to: ${value ? "On" : "Off"}');
                      },
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
                      leading: const Icon(Icons.privacy_tip, color: Colors.grey),
                      title: Row(
                        children: [
                          Text(
                            "Private Account",
                            style: TextStyle(color: primary, fontFamily: Poppins,),
                          ),
                          SizedBox(width: 5,),
                          GestureDetector(
                              onTap: (){
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: primary,
                                    title: const Text("Private Account",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                    content: const Text("When the toggle is on, other users will not be able to see your styles. However, if you are participating in an event, your eventpost will still be visible for likes. Any other eventposts you have will also remain visible to other users. You will not appear randomly in the feed.",style: TextStyle(color: ascent,fontFamily: Poppins,),),
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
                      trailing: loading == true ? SizedBox(
                        width: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SpinKitCircle(color: primary,size: 20,),
                          ],
                        ),
                      ) : SizedBox(
                        width: 50,
                        child: Switch(
                          value: private_account,
                          activeColor: primary,// Assuming 0 means 'On' and 1 means 'Off'
                          onChanged: (value) {
                            if(private_account == false){
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: primary,
                                  title: const Text("Private Account",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                  content: const Text("Are you sure you want to make your account private? When the toggle is on, other users will not be able to see your styles. However, if you are participating in an event, your eventpost will still be visible for likes. Any other eventposts you have will also remain visible to other users. You will not appear randomly in the feed.",style: TextStyle(color: ascent,fontFamily: Poppins,),),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                      onPressed:  () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                    TextButton(
                                      child: const Text("Confirm",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                      onPressed:  () {
                                        togglePrivate();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                            if(private_account == true){
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: primary,
                                  title: const Text("Private Account",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                  content: const Text("Are you sure you want to make your account public? All your styles will be visible to other users. Any fan requests you have will be deleted and cannot be undone.",style: TextStyle(color: ascent,fontFamily: Poppins,),),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                      onPressed:  () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                    TextButton(
                                      child: const Text("Confirm",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                      onPressed:  () {
                                        togglePrivate();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
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
                    color: private_account == true ? Colors.grey.shade800 : null,
                    elevation: 5,
                    child: ListTile(
                      leading: Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              "assets/Frame1.png"
                            )
                          )
                        ),
                        child: Center(child: Icon(Icons.close,color: Colors.red,)),
                      ),
                      title: Row(
                        children: [
                          Text(
                            "Style Visibility",
                            style: TextStyle(color: primary, fontFamily: Poppins,),
                          ),
                          SizedBox(width: 5,),
                          GestureDetector(
                              onTap: (){
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: primary,
                                    title: const Text("Style Visibility",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                    content: const Text("When the toggle is on, your styles will be visible to other users in the feed. This helps you get more exposure and engage with the community. If you have a private account, this setting will automatically be turned off. Please note that your eventposts will always be visible to other users.",style: TextStyle(color: ascent,fontFamily: Poppins,),),
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
                      trailing: loading2 == true ? SizedBox(
                        width: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SpinKitCircle(color: primary,size: 20,),
                          ],
                        ),
                      ) : (private_account == true ? SizedBox(
                        width: 50,
                        child: Switch(
                          value: style_visibility,
                          activeColor: primary,// Assuming 0 means 'On' and 1 means 'Off'
                          onChanged: (val){},
                        ),
                      ) : SizedBox(
                        width: 50,
                        child: Switch(
                          value: style_visibility,
                          activeColor: primary,// Assuming 0 means 'On' and 1 means 'Off'
                          onChanged: (value) {
                              if(style_visibility == false){
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: primary,
                                    title: const Text("Style Visibility",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                    content: const Text("Are you sure you want to turn on this toggle? Your styles will become visible to other users in the feed.",style: TextStyle(color: ascent,fontFamily: Poppins,),),
                                    actions: [
                                      TextButton(
                                        child: const Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                        onPressed:  () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      TextButton(
                                        child: const Text("Confirm",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                        onPressed:  () {
                                          style_visibility = true;
                                          toggleStyleVisibility(style_visibility);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                              if(style_visibility == true){
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: primary,
                                    title: const Text("Style Visibility",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                    content: const Text("Are you sure you want to turn off this toggle? Your styles will no longer be visible to other users in the feed. Only your eventposts will remain visible to them.",style: TextStyle(color: ascent,fontFamily: Poppins,),),
                                    actions: [
                                      TextButton(
                                        child: const Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                        onPressed:  () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      TextButton(
                                        child: const Text("Confirm",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                        onPressed:  () {
                                          style_visibility = false;
                                          toggleStyleVisibility(style_visibility);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                          },
                        ),
                      )),
                    ),
                  )
              ),
            ),
            WidgetAnimator(
              loading1 == true ? SpinKitCircle(color: primary,size: 50,) : Padding(
                padding: const EdgeInsets.only(left:8.0,right: 8.0,top: 8,bottom: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Padding(
                    //   padding: const EdgeInsets.all(8.0),
                    //   child: ElevatedButton(
                    //       style: ButtonStyle(
                    //           elevation: MaterialStateProperty.all(10.0),
                    //           shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    //               RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(8.0),
                    //               )
                    //           ),
                    //           backgroundColor: MaterialStateProperty.all(primary),
                    //           padding: MaterialStateProperty.all(EdgeInsets.only(
                    //               top: 13,bottom: 13,
                    //               left:MediaQuery.of(context).size.width * 0.1,right: MediaQuery.of(context).size.width * 0.1)),
                    //           textStyle: MaterialStateProperty.all(
                    //               const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins,))),
                    //       onPressed: () {
                    //         deleteAccount();
                    //         //Navigator.pop(context);
                    //         //Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Register()));
                    //       },
                    //       child: const Text('Delete My Account',style: TextStyle(
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.w700,
                    //         color: ascent,
                    //         fontFamily: Poppins,
                    //       ),)),
                    // ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          style: ButtonStyle(
                              elevation: MaterialStateProperty.all(10.0),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  )
                              ),
                              backgroundColor: MaterialStateProperty.all(secondary),
                              padding: MaterialStateProperty.all(EdgeInsets.only(
                                  top: 13,bottom: 13,
                                  left:MediaQuery.of(context).size.width * 0.16,right: MediaQuery.of(context).size.width * 0.16)),
                              textStyle: MaterialStateProperty.all(
                                  const TextStyle(fontSize: 14, color: Colors.white,fontFamily: Poppins,))),
                          onPressed: () {
                            Navigator.push(context,MaterialPageRoute(builder: (context) => const CloseFriends()));

                          },
                          child: const Text('Stylemates',style: TextStyle(
                              fontSize: 16,
                              color: ascent,
                              fontWeight: FontWeight.w700,
                            fontFamily: Poppins,
                          ),)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}