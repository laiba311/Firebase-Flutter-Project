import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/helpers/database_methods.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;

import '../../../animations/bottom_animation.dart';
import '../../../models/chats_model.dart';
import '../../../utils/constants.dart';

class AddChatScreen extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  const AddChatScreen({Key? key, required this.myIndex, required this.navigateTo}) : super(key: key);

  @override
  State<AddChatScreen> createState() => _AddChatScreenState();
}

class _AddChatScreenState extends State<AddChatScreen> {
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
    print(token);
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

  startMessaging(friendPic,friendUserName,friendName, friendToken,friendID){
    List<Object> users = [name,friendName];

    String chatRoomId = "${name}_$friendName";

    Map<String, dynamic> userData = {
      "name": name,
      "username" : username,
      "pic": pic,
      "token": fcm,
      'isMute':false
    };

    Map<String, dynamic> friendData = {
      "id": friendID,
      "name": friendName,
      "username" : friendUserName,
      "pic": friendPic,
      "token": friendToken
    };

    Map<String, dynamic> chatRoom = {
      "users": users,
      "chatRoomId" : chatRoomId,
      "userData": userData,
      "friendData": friendData,
      "isBlock": false,
    };

    DatabaseMethods().addChatRoom(chatRoom, chatRoomId);

    // Navigator.pushReplacement(context, MaterialPageRoute(
    //     builder: (context) => MessageScreen(
    //       friendId: friendID,
    //       chatRoomId: chatRoomId,
    //       name: friendName,
    //       pic: friendPic,
    //       email: friendUserName,
    //       fcm: friendToken,
    //       isBlocked: false,
    //     )
    // ));
  }
  getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "${b}_$a";
    } else {
      return "${a}_$b";
    }
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
        //   title: const Text("Start chat",style: TextStyle(fontFamily: Poppins,),),
        // ),
        body:loading == true ? SpinKitCircle(size: 50,color: primary,) : (friends.isEmpty ? const Center(child: Text("No Friends",style: TextStyle(fontFamily: Poppins,),)) :ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context,index) => WidgetAnimator(
                GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                      id: friends[index].id,
                      username: friends[index].username,
                    )));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 20,),
                        Container(
                          decoration: const BoxDecoration(
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
                                  child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,)
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
                                  Text(friends[index].username ?? "",style: TextStyle(color: primary,fontSize: 20,fontWeight: FontWeight.bold,fontFamily: Poppins,),),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(Uri.decodeComponent(friends[index].name),style: const TextStyle(fontFamily: Poppins,),),
                                ],
                              )
                            ],
                          ),
                        ),
                        IconButton(onPressed: (){
                            startMessaging(friends[index].pic,friends[index].username,friends[index].name,friends[index].fcmToken,friends[index].id);
                        }, icon: const Icon(Icons.chat))
                      ],
                    ),
                  ),
                )
            )
        )),
      ),
    );
  }
}
