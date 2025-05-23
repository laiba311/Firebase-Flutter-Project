import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/post_detail.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/constants.dart';

class NotificationScreen extends StatefulWidget {
  final Function onNavigateUser;
  final Function onNavigateBack;
  const NotificationScreen({Key? key, required this.onNavigateUser, required this.onNavigateBack}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String id = "";
  String token = "";
  String userName = '';
  Map<String,dynamic> data = {};
  bool loading = false;
  List<Map<String, dynamic>> notifications = [];
  String requestID = "";
  bool requestLoader = false;
  bool isGetRequest = false;
  bool isRejected=false;
  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    userName = preferences.getString('username')!;
    print(token);
    debugPrint("the user name of user is ============>$userName");
    getNotifications();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }
  matchFriendReques(id1,notificationId){
    print("Match Friend id");
    try{
      https.get(
          Uri.parse("$serverUrl/followRequests/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        print(id);
        jsonDecode(value.body).forEach((request){
          // print("${request["from_user"].toString()} == ${id1} && ${request["to_user"]} == ${id}");
          if(request["from_user"].toString() == id1.toString() && request["to_user"].toString() == id.toString()){
            setState(() {
              loading = false;
              isGetRequest = true;
              requestID = request["id"].toString();
              isRejected?rejectRequest(requestID):acceptRequest(requestID);
              deleteNotification(notificationId);
            });
            print(isGetRequest.toString());
            print(requestID.toString());
          }
          else if(request["from_user"].toString() == id.toString() && request["to_user"].toString() == id1.toString()){
            setState(() {
              loading = false;
            });
            requestID = request["id"].toString();
            isRejected?rejectRequest(requestID):acceptRequest(requestID);
            deleteNotification(notificationId);
          }
          else{
            setState(() {
              loading = false;
              deleteNotification(notificationId);
            });
            print(isGetRequest.toString());
          }
        });
        setState(() {
          loading = false;
        });
        print(jsonDecode(value.body).toString());

      });
    }catch(e){
      setState(() {
        loading = false;
      });
      debugPrint("Error --> $e");
    }
  }
  acceptRequest(userid){
    setState(() {
      requestLoader = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_accept_request/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      setState(() {
        requestLoader = false;
      });
      debugPrint("request status======>${value.body}");
      // getMyFriends(widget.id);
    }).catchError((value){
      setState(() {
        requestLoader = false;
      });
      debugPrint(value);
    });
  }
  rejectRequest(userid){
    setState(() {
      requestLoader = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_reject_request/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      setState(() {
        requestLoader = false;
      });
      print(value.body.toString());
    }).catchError((value){
      setState(() {
        requestLoader = false;
      });
      print(value);
    });
  }
  getNotifications() {
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/notificationsApi/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        debugPrint("Notification --> ${jsonDecode(value.body)}");
        notifications.clear();
        jsonDecode(value.body).forEach((data) {
          setState(() {
            notifications.add({
              "title": data["title"].toString(),
              "body": data["body"].toString(),
              "action": data["action"].toString(),
              "time": data["updated"].toString(),
              "type": data["action"].toString(),
              "sender": data["sender"]
            });
          });
        });
        readNotification();

      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error --> $e");
    }
  }
  deleteNotification(id){
    String url="$serverUrl/notificationsApi/$id/";
    https.delete(Uri.parse(url),headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      debugPrint("deleted notification======>${value.statusCode}");
      setState(() {
        getNotifications();
      });
    }).onError((error, stackTrace) {
      debugPrint("error received while removing this notifications");
    });
  }

  readNotification() {
    https.post(
        Uri.parse("$serverUrl/notificationsmark-all-notifications-as-read/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }).then((value) {
      debugPrint(value.body.toString());
      setState(() {
        loading = false;
      });
    }).catchError(() {
      debugPrint("Error");
      setState(() {
        loading = false;
      });
    });
  }
  String formatTimeDifference(String dateString) {
    DateTime createdAt = DateTime.parse(dateString);
    DateTime now = DateTime.now();

    Duration difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      int weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else if (difference.inDays < 365) {
      int months = (difference.inDays / 30).floor();
      return '${months}m';
    } else {
      int years = (difference.inDays / 365).floor();
      return '${years}y';
    }
  }

  Future<void> _refreshData() async {
    // Simulate a network request or data update
    await Future.delayed(Duration(seconds: 2));
    getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () {
      //       Navigator.pop(context);
      //     },
      //   ),
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
      //             ])),
      //   ),
      //   backgroundColor: primary,
      //   title: const Text(
      //     "Notifications",
      //     style: TextStyle(fontFamily: Poppins,),
      //   ),
      // ),
      body: loading == true
          ? SpinKitCircle(
              color: primary,
              size: 50,
            )
          : (notifications.isEmpty
              ? const Center(
                  child: Text("No Notifications",style: TextStyle(fontFamily: Poppins,),),
                )
              : RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return notifications[index]['title'] ==
                                  "Dislike on fashion" ||
                              (notifications[index]['action'] ==
                                      "comment_fashion" &&
                                  notifications[index]['user']?['username'] ==
                                      userName)
                          ? null
                          : WidgetAnimator(
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 10.0, top: 8, bottom: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    if (notifications[index]["type"] == "send_follow_request") {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FriendProfileScreen(
                                                    id: notifications[index]
                                                            ["sender"]["id"]
                                                        .toString(),
                                                    username: notifications[index]
                                                        ["sender"]["username"],
                                                  )));
                                    }
                                    else if (notifications[index]["type"] == "fashion_created") {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => PostDetail(
                                                    postId: notifications[index]
                                                            ["body"]
                                                        .toString()
                                                        .split("(Post ID: ")[1],
                                                  )));
                                    } else if (notifications[index]["type"] ==
                                        "like_fashion") {
                                      // Navigator.push(context,MaterialPageRoute(builder: (context) => PostDetail(
                                      //   postId: notifications[index]["body"].toString().split("(Post ID: ")[1],
                                      // )));
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FriendProfileScreen(
                                                    id: notifications[index]
                                                            ["sender"]["id"]
                                                        .toString(),
                                                    username: notifications[index]
                                                        ["sender"]["username"],
                                                  )));
                                    } else if (notifications[index]["type"] ==
                                        "dislike_fashion") {
                                      // Navigator.push(context,MaterialPageRoute(builder: (context) => PostDetail(
                                      //   postId: notifications[index]["body"].toString().split("(Post ID: ")[1],
                                      // )));
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FriendProfileScreen(
                                                    id: notifications[index]
                                                            ["sender"]["id"]
                                                        .toString(),
                                                    username: notifications[index]
                                                        ["sender"]["username"],
                                                  )));
                                    } else if (notifications[index]["type"] ==
                                        "comment_fashion") {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => PostDetail(
                                                    postId: notifications[index]
                                                            ["body"]
                                                        .toString()
                                                        .split("(Post ID: ")[1],
                                                  )));
                                    } else if (notifications[index]["type"] ==
                                        "accept_follow_request") {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FriendProfileScreen(
                                                    id: notifications[index]
                                                            ["sender"]["id"]
                                                        .toString(),
                                                    username: notifications[index]
                                                        ["sender"]["username"],
                                                  )));
                                    }
                                    //readNotification(notifications[index]["id"]);
                                  },
                                  child: Card(
                                    elevation: 5,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20))),
                                    child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: primary,
                                          child: notifications[index]['title'] ==
                                                      "New like on fashion" ||
                                                  notifications[index]['title'] ==
                                                      "Dislike on fashion"
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      borderRadius:
                                                          const BorderRadius.all(
                                                              Radius.circular(
                                                                  120))),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                            Radius.circular(120)),
                                                    child: CachedNetworkImage(
                                                      imageUrl: notifications[index]
                                                              ["sender"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*rglk9r*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzMuNjAuMC4w",
                                                      imageBuilder: (context,
                                                              imageProvider) =>
                                                          Container(
                                                        // height:MediaQuery.of(context).size.height * 0.7,
                                                        // width: MediaQuery.of(context).size.width,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black,
                                                          image: DecorationImage(
                                                            image: imageProvider,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                      placeholder:
                                                          (context, url) =>
                                                              SpinKitCircle(
                                                        color: primary,
                                                        size: 60,
                                                      ),
                                                      errorWidget: (context, url,
                                                              error) =>
                                                          ClipRRect(
                                                              borderRadius:
                                                                  const BorderRadius
                                                                          .all(
                                                                      Radius
                                                                          .circular(
                                                                              50)),
                                                              child:
                                                                  Image.network(
                                                                "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.9,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height *
                                                                    0.9,
                                                              )),
                                                    ),
                                                  ),
                                                )
                                              : Icon(
                                                  notifications[index]["type"] == "mention" ? Icons.alternate_email : Icons.notifications_active,
                                                  color: ascent,
                                                ),
                                        ),
                                        subtitle: notifications[index]["type"] == "mention" ?
                                        RichText(text: TextSpan(
                                          text: "${notifications[index]["body"].toString().split(" ")[0]}",
                                          style: TextStyle(fontSize: 16, color: secondary),
                                          recognizer: TapGestureRecognizer()..onTap = () {
                                            widget.onNavigateUser(30,notifications[index]["sender"]["id"].toString(),notifications[index]["sender"]["username"]);
                                            // print("id ${notifications[index]["sender"]["id"]}");
                                            // print("Username ${notifications[index]["sender"]["username"]}");
                                          },
                                          children: <TextSpan>[
                                            TextSpan(
                                                text: " ${notifications[index]["body"].toString().split("(")[0].toString().split(" on ")[0].split(" ").skip(1).join(" ")}.",
                                                style: TextStyle(
                                                    color: primary,
                                                    fontSize: 14,
                                                    fontFamily: Poppins
                                                )
                                            ),
                                          ],
                                        ))
                                            : Text(
                                          (
                                                  notifications[index]["type"] == "fashion_created" ||
                                                  notifications[index]["type"] == "like_fashion" ||
                                                  notifications[index]["type"] == "comment_fashion" ||
                                                  notifications[index]['type'] == "like_fashion_reel"
                                          )
                                                      ? (notifications[index]["type"] == "like_fashion" ? "${notifications[index]["body"].split(" ")[0]} has liked your fashion style!" : notifications[index]["body"].toString().split("(")[0])
                                                      : notifications[index]['title'] == "Dislike on fashion"
                                                      ? null
                                                      : notifications[index]["body"],
                                          style: TextStyle(
                                              color: primary,
                                              fontSize: 13,
                                            fontFamily: Poppins,),
                                        ),
                                        trailing:
                                            //Text(DateFormat('hh:mm a').format(DateTime.parse(notifications[index]["time"]).toLocal()),style: TextStyle(fontFamily: Poppins),),
                                            notifications[index]['title'] ==
                                                    "Dislike on fashion" ||  notifications[index]['title'] ==
                                                'New Follow Request'
                                                ? null
                                                : Text(
                                                formatTimeDifference( notifications[index]
                                                ["time"])
                                                    ,
                                                    style: const TextStyle(
                                                        fontFamily: Poppins,
                                                      fontSize: 12,
                                                    ))),
                                  ),
                                ),
                              ),
                            );
                    }),
              )),
    );
  }

  String formatNotificationTime(String rawTime) {
    DateTime notificationTime = DateTime.parse(rawTime).toLocal();
    DateTime now = DateTime.now();

    // Calculate the difference in days
    int differenceInDays = now.difference(notificationTime).inDays;

    // Format the time using RelativeDateFormat if it's less than a week
    if (differenceInDays == 0) {
      return DateFormat('MM/dd/yyyy ').format(notificationTime);
    } else if (differenceInDays == 1) {
      return 'Yesterday.';
    }
    else {
      return DateFormat('MM/dd/yyyy ').format(notificationTime);
    }
  }
}
