import 'dart:convert';
import 'dart:core';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalfashiontimefrontend/helpers/database_methods.dart';
import 'package:finalfashiontimefrontend/screens/call-screens/CallJoin.dart';
import 'package:finalfashiontimefrontend/screens/call-screens/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;

import '../../../animations/bottom_animation.dart';
import '../../../models/chats_model.dart';
import '../../../utils/constants.dart';

class AddCallScreen extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  const AddCallScreen({Key? key, required this.myIndex, required this.navigateTo}) : super(key: key);

  @override
  State<AddCallScreen> createState() => _AddCallScreenState();
}

class _AddCallScreenState extends State<AddCallScreen> {
  final  int uid=0 ;
  String friendName='';
  String id = "";
  String token = "";
  bool loading = false;
  List<ChatModel> friends = [];
  String name = "";
  String username = "";
  String pic = "";
  String fcm = "";

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    name = preferences.getString("name")!;
    username = preferences.getString("username")!;
    pic = preferences.getString("pic")!;
    fcm = preferences.getString("fcm_token")!;
    print("FCM $fcm");
    getMyFriends();
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  getMyFriends(){
    setState(() {
      loading = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/follow_get_friends/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        setState(() {
          loading = false;
        });
        print(jsonDecode(value.body).toString());
        jsonDecode(value.body).forEach((data){
          setState(() {

            friends.add(ChatModel(
                data["id"].toString(),
                data["name"],
                data["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",

               // friendPic = data["pic"] == null?"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":data["pic"],
                data["email"],
                data["username"],
                data["fcmToken"]
            ));
          });
        });
      });
    }catch(e){
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }

  startCall(friendId,friendPic,friendUserName,friendName, friendToken){
    https.get(
        Uri.parse("$serverUrl/video-callget-token/?${(name+friendName)}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        // body: json.encode({
        //   "user_id": id,
        //   "channel_name": "${name}_${friendName}"
        // })
    ).then((value){
      print("Agora Token ${value.body}");
      print(json.decode(value.body)["token"]);
      List<String> users = [name,friendName];

      String chatRoomId = "${name}_$friendName";

      Map<String, dynamic> userData = {
        "id": id,
        "name": name,
        "username" : username,
        "pic": pic,
        "token": fcm
      };

      Map<String, dynamic> friendData = {
        "friend_id":friendId,
        "name": friendName,
        "username" : friendUserName,
        "pic": friendPic,
        "token": friendToken
      };

      Map<String, dynamic> chatRoom = {
        "friend_id":friendId,
        "users": users,
        "chatRoomId" : chatRoomId,
        "sendersData": userData,
        "receiversData": friendData,
        "agoraToken": json.decode(value.body)["token"]
      };


      DatabaseMethods().addCallRoom(chatRoom, chatRoomId);

      Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(
        token: json.decode(value.body)["token"],
        channelId: chatRoomId,
      )));
      //sendNotification(friendName,friendToken);
      // Navigator.push(context, MaterialPageRoute(
      //     builder: (context) => CallerScreen(
      //       callRoomId: chatRoomId,
      //       name: friendName,
      //       pic: friendPic,
      //       email: friendUserName,
      //     )
      // ));
    });
  }

  getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "${b}_$a";
    } else {
      return "${a}_$b";
    }
  }

  sendNotification(String name,String token) async {
    print("Entered");
    print("1- $name");
    //print("2- "+widget.person_name!.toString());
    var body = jsonEncode(<String, dynamic>{
      "to": token,
      "notification": {
        "title": "Calling",
        "body": "You have received a call from $name",
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


  @override
  Widget build(BuildContext context) {


    return WillPopScope(
      onWillPop: (){
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
        //   title: const Text("Start call",style: TextStyle(fontFamily: Poppins),),
        // ),
        body:loading == true ? SpinKitCircle(size: 50,color: primary,) : (friends.isEmpty ? const Center(child: Text("No Friends",style: TextStyle(fontFamily: Poppins),)) :ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context,index) => WidgetAnimator(
                GestureDetector(
                  onTap: (){
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                    //   id: friends[index].id,
                    // )));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 20,),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                              borderRadius: BorderRadius.all(Radius.circular(120))
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(120)),
                            child: CachedNetworkImage(
                              imageUrl: friends[index].pic,
                              imageBuilder: (context, imageProvider) => Container(
                                height:50,
                                width: 50,
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
                                  child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 50,height: 50,)
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20,),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text("${friends[index].username}",style: TextStyle(color: primary,fontSize: 20,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(Uri.decodeComponent(friends[index].name),style: const TextStyle(fontFamily: Poppins),),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(onPressed: (){
                       // callnotify(int.parse(friends[index].id.toString()), name, int.parse(id.toString()),name+"_"+friends[index].name);

                            //getCalls();
                           //startCall(friends[index].id,friends[index].pic,friends[index].username,friends[index].name,friends[index].fcmToken);
                         // checkIncomingCall(friends[index].id,friends[index].pic,friends[index].username,friends[index].name,friends[index].fcmToken,name+"_"+friends[index].name);
                          Navigator.push(context,MaterialPageRoute(builder: (context) => CallJoin(token: friends[index].fcmToken,ChatId:"${name}_${friends[index].name}" ,Friendid: friends[index].id,Name: friends[index].name,Pic: friends[index].pic,Username: friends[index].username),));
                         // fetchAgoraToken(friends[index].id, friends[index].pic,friends[index].username , friends[index].name,friends[index].fcmToken , name+"_"+friends[index].name);
                          setState(() {

                          });
                           // Navigator.pop(context);
                           // Navigator.push(context, MaterialPageRoute(builder: (context) => CallerScreen()));
                        }, icon: const Icon(Icons.call))
                      ],
                    ),
                  ),
                )
            )
        )),
      ),
    );
  }

  joinCall(){
    FirebaseFirestore.instance.collection("callRoom").where("users",arrayContains: name).get().then((value){
      for (var element in value.docs) {
        print(element.id.toString());
        if(element.id.split("_")[1] == name){
          //setCallListener(element["agoraToken"],element["chatRoomId"]);
          https.post(
              Uri.parse("$serverUrl/video-callget-token/"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token"
              },
              body: json.encode({
                "user_id": element["friend_id"],
                "channel_name": element["chatRoomId"]
              })
          ).then((value){
            Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(
              token: json.decode(value.body)["token"],
              channelId: element["chatRoomId"],
            )));
          });
        }
      }
    });
  }

  checkIncomingCall(friendId,friendPic,friendUserName,friendName, friendToken,channelName){
    FirebaseFirestore.instance.collection("callRoom").where("users",arrayContainsAny: [name,friendName]).get().then((value){
      if(value.docs.isEmpty){
        fetchAgoraToken(friendId,friendPic,friendUserName,friendName, friendToken,channelName);
        Navigator.push(context,MaterialPageRoute(builder: (context) => const CallJoin(),));
      }else {
        // popup
        showDialog(context: context, builder: (BuildContext context){
          return AlertDialog(
            title: const Text("Engaged"),
            content: Text(friendName+"is already in the call"),
            actions: <Widget>[TextButton(onPressed: (){
              DatabaseMethods().endCallRoom(channelName);
              Navigator.of(context).pop();
              Navigator.pop(context);
            }, child: const Text("ok"))],
          );
        });
      }
    });
  }

  Future<void> fetchAgoraToken(friendId,friendPic,friendUserName,friendName, friendToken,channelName) async {
    // Define the API endpoint URL
    final apiUrl = Uri.parse(
        '$serverUrl/video-callget-token/?channelName=$channelName'
    );
    await https.get(apiUrl,headers: {
      'Authorization':'Bearer $token',
    }).then((value){
      print("Agora Token ${value.body}");
      print(json.decode(value.body)["token"]);
       final jsonResponse=json.decode(value.body);
       final agoraToken=jsonResponse['token'];
       final luid= jsonResponse['uid'];
      List<String> users = [name,friendName];

      String chatRoomId = "${name}_$friendName";

      Map<String, dynamic> userData = {
        "id": id,
        "name": name,
        "username" : username,
        "pic": pic,
        "token": fcm
      };

      Map<String, dynamic> friendData = {
        "friend_id":friendId,
        "name": friendName,
        "username" : friendUserName,
        "pic": friendPic,
        "token": friendToken
      };

      Map<String, dynamic> chatRoom = {
        "agoraId": luid,
        "friend_id":friendId,
        "users": users,
        "chatRoomId" : chatRoomId,
        "sendersData": userData,
        "receiversData": friendData,
        "agoraToken": json.decode(value.body)["token"]
      };


      DatabaseMethods().addCallRoom(chatRoom, chatRoomId);

      //Navigator.push(context, MaterialPageRoute(builder: (context) => VideoScreen(Channelname: chatRoomId,CallerName: userData[name],)));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CallJoin(Name: name,ChatId: chatRoomId,),));

    });

    // try {
    //   // Send the GET request with the Bearer token in the headers
    //   final response = await https.get(
    //     apiUrl,
    //     headers: {
    //       'Authorization': 'Bearer $token',
    //     },
    //   );
    //
    //   if (response.statusCode == 200) {
    //     // Parse the JSON response
    //     // final jsonResponse = json.decode(response.body);
    //     // final uid = jsonResponse['uid'];
    //     // final saqtoken = jsonResponse['token'];
    //     //
    //     // navigateToAnotherScreen (context,saqtoken,uid,"afnan_abdullah",friendData);
    //     // print('UID: $uid');
    //     // print('Token: $saqtoken');
    //     // You can now use uid and token to join the Agora call
    //   } else {
    //     // Handle API error
    //     print('API Error: ${response.statusCode} - ${response.body}');
    //   }
    // } catch (error) {
    //   // Handle network or request errors
    //   print('API Request Error: $error');
    // }
  }
}
