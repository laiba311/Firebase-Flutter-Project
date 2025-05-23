import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalfashiontimefrontend/helpers/database_methods.dart';
import 'package:finalfashiontimefrontend/models/chats_model.dart';
import 'package:finalfashiontimefrontend/screens/call-screens/localView.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;

class CallJoin extends StatefulWidget {
  final String? Name;
  final String? ChatId;
  final String? Pic;
  final String? Friendid;
  final String? Username;
  final String? token;

  const CallJoin({
    Key? key,
    this.Name,
    this.Pic,
    this.ChatId,
    this.Friendid,
    this.Username,
    this.token,
  }) : super(key: key);

  @override
  State<CallJoin> createState() => _CallJoinState();
}

class _CallJoinState extends State<CallJoin> {
  bool loading = true;
  String id = "";
  String token = "";
  List<ChatModel> friends = [];
  String name = "";
  String username = "";
  String pic = "";
  String fcm = "";

  @override
  void initState() {
    super.initState();
    getCashedData();
    // fetchAgoraToken(
    //   widget.id.toString(),
    //   widget.Pic.toString(),
    //   widget.Username.toString(),
    //   widget.Name,
    //   widget.token.toString(),
    //   widget.ChatId.toString(),
    // );
    checkIncomingCall(
        widget.Friendid.toString(),
        widget.Pic.toString(),
        widget.Username.toString(),
        widget.Name.toString(),
        widget.token.toString(),
        widget.ChatId.toString());

  }

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    name = preferences.getString("name")!;
    username = preferences.getString("username")!;
    pic = preferences.getString("pic")!;
    fcm = preferences.getString("fcm_token")!;
    print("FCM $fcm");
    print("the id of logged in user is $id");
    print("the id of the friend is ${widget.Friendid}");
    getMyFriends();
    sendCall(name,id,widget.Friendid.toString());
    getCall( id, id.toString());
  }

  getMyFriends() {
    try {
      https.get(
        Uri.parse("$serverUrl/follow_get_friends/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).then((value) {
        print(jsonDecode(value.body).toString());
        jsonDecode(value.body).forEach((data) {
          setState(() {
            friends.add(ChatModel(
              data["id"].toString(),
              data["name"],
              data["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
              data["email"],
              data["username"],
              data["fcmToken"],
            ));
          });
        });
      });
    } catch (e) {
      setState(() {
        loading = true;
      });
      print("Error --> $e");
    }
  }

  Future<void> fetchAgoraToken(
    friendId,
    friendPic,
    friendUserName,
    friendName,
    friendToken,
    channelName,
  ) async {
    // Define the API endpoint URL
    final apiUrl =
        Uri.parse('$serverUrl/video-callget-token/?channelName=$channelName');
    await https.get(apiUrl, headers: {
      'Authorization': 'Bearer $token',
    }).then((value) {
      print("Agora Token ${value.body}");
      print(json.decode(value.body)["token"]);
      final jsonResponse = json.decode(value.body);
      final agoraToken = jsonResponse['token'];
      final luid = jsonResponse['uid'];
      List<String> users = [name, friendName];

      String chatRoomId = "${name}_$friendName";

      Map<String, dynamic> userData = {
        "id": id,
        "name": name,
        "username": username,
        "pic": pic,
        "token": fcm,
      };

      Map<String, dynamic> friendData = {
        "friend_id": friendId,
        "name": friendName,
        "username": friendUserName,
        "pic": friendPic,
        "token": friendToken,
      };

      Map<String, dynamic> chatRoom = {
        "agoraId": luid,
        "friend_id": friendId,
        "users": users,
        "chatRoomId": chatRoomId,
        "sendersData": userData,
        "receiversData": friendData,
        "agoraToken": json.decode(value.body)["token"],
      };

      DatabaseMethods().addCallRoom(chatRoom, chatRoomId);
      loading = false;

      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => VideoScreen(
      //       Channelname: chatRoomId,
      //       CallerName: userData['name'],
      //       friendName: friendData['name'],
      //       //token: chatRoom["agoraToken"],
      //     ),
      //   ),
      // );
    });
  }

  checkIncomingCall(friendId, friendPic, friendUserName, friendName,
      friendToken, channelName) {
    FirebaseFirestore.instance
        .collection("callRoom")
        .where("users", arrayContainsAny: [name, friendName])
        .get()
        .then((value) {
          if (value.docs.isEmpty) {
            sendNotification("Call", "$name is calling you", friendToken);
            fetchAgoraToken(friendId, friendPic, friendUserName, friendName,
                friendToken, channelName);
          } else {

            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Engaged"),
                    content: Text(friendName + "is already in the call"),
                    actions: <Widget>[
                      TextButton(
                          onPressed: () {
                            DatabaseMethods().endCallRoom(channelName);
                            Navigator.of(context).pop();
                            Navigator.pop(context);
                          },
                          child: const Text("ok"))
                    ],
                  );
                });
            // fetchAgoraToken(friendId, friendPic, friendUserName, friendName,
            //     friendToken, channelName);
          }
        });
  }
  sendNotification(String name,String message,String token) async {
    print("Entered");
    print("1- $name");
    //print("2- "+widget.person_name!.toString());
    var body = jsonEncode(<String, dynamic>{
      "to": token,
      "notification": {
        "title": name,
        "body": message,
        "mutable_content": true,
        "sound": "Tri-tone"
      },
      "data": {
        "url": "https://www.w3schools.com/w3images/avatar2.png",
        "dl": "<deeplink action on tap of notification>"
      }
    });

    https.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=AAAAIgQSOH0:APA91bGZExBIg_hZuaqTYeCMB2ulE_iiRXY8kTYH6MqEpimm6WIshqH6GAhoor1MGnGl2dDbvJqWNRzEGBm_17Kd6-vS-BHZD31HZu_EFCKs5cOQh8EJzpKP2ayJicozOU4csM528EBy',
      },
      body: body,
    ).then((value1){
      print(value1.body.toString());
    });
  }
  sendCall(String callerName,String fromUser,String toUser)async{
    var callBody=jsonEncode(<String,dynamic>{
      "title":"$callerName Called you",
      "from_user":int.parse(fromUser),
      "to_user":int.parse(toUser)
    });
    https.post(Uri.parse("$serverUrl/video-callMissedCall/"),
    headers: <String,String>{
      'Content-Type':'application/json',
      'Authorization':'Bearer $token'
    },
    body: callBody).then((value){
      print("miss call data ${value.body.toString()}");
    });

  }
  getCall(String fromUser,String toUser)async{
    var callBody=jsonEncode(<String,dynamic>{
      "title":"You called.",
      "from_user":int.parse(fromUser),
      "to_user":int.parse(toUser)
    });
    https.post(Uri.parse("$serverUrl/video-callMissedCall/"),
        headers: <String,String>{
          'Content-Type':'application/json',
          'Authorization':'Bearer $token'
        },
        body: callBody).then((value){
      print("miss call data ${value.body.toString()}");
    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (loading)
            Scaffold(
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
                          ])),
                ),
                backgroundColor: primary,
                title: Text(
                  "Calling ${widget.Name.toString()}",
                  style: const TextStyle(fontFamily: Poppins),
                ),
              ),
              body: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(120))
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(120)),
                    child: CachedNetworkImage(
                      imageUrl: widget.Pic.toString(),
                      imageBuilder: (context, imageProvider) => Container(
                        height:200,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(120)),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => SpinKitCircle(color: primary,size: 20,),
                      errorWidget: (context, url, error) => ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(50)),
                          child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 200,height: 200,)
                      ),
                    ),
                  )
                ),
              ),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.all(12.0),
                child: BottomAppBar(

                   // color: primary,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.topRight,
                          stops: const [0.0, 0.99],
                          tileMode: TileMode.clamp,
                          colors: <Color>[
                            secondary,
                            primary,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // IconButton(
                          //   icon: Icon(Icons.call_end,
                          //       color: Colors
                          //           .red), // You can replace this with your desired icon
                          //   onPressed: () {
                          //     DatabaseMethods()
                          //         .endCallRoom(widget.ChatId.toString());
                          //     Navigator.pop(context);
                          //   },
                          // ),
                          InkWell(
                            onTap: () {
                              DatabaseMethods()
                                  .endCallRoom(widget.ChatId.toString());
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 60, // Adjust the width to make it round
                              height: 60, // Adjust the height to make it round
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red, // Change the color to green
                              ),
                              child: const Center(
                                child: Icon(Icons.call_end, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ),
            ),
          if (!loading) const Scaffold(),
        ],
      ),
    );
  }
}
