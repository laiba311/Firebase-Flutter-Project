import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
//import 'package:fashiontimefinal/screens/pages/post_screens/event_posts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart'as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../animations/bottom_animation.dart';
import '../../../models/chats_model.dart';
import '../../../utils/constants.dart';
class FriendsFans extends StatefulWidget {
  final String friendId;
  const FriendsFans({super.key, required this.friendId});

  @override
  State<FriendsFans> createState() => _FriendsFansState();
}
bool loading=false;
String token="";
String id="";
class _FriendsFansState extends State<FriendsFans> {
  List<ChatModel> friends = [];
  List<ChatModel> filteredFriends = [];
  List<int> idolIdList = [];
  List<Map<String,dynamic>> requestList = [];
  bool requestLoader2 = false;
  String fanRequestID = "";
  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    debugPrint(token);
    getRequests();
  }
  getMyFriends(){
    friends.clear();
    setState(() {
      loading = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/fansfriends/${widget.friendId}/fans/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        setState(() {
          loading = false;
        });
        debugPrint("fansidols response==========>${jsonDecode(value.body)}");
        jsonDecode(value.body).forEach((data){
          print("badge => ${data["fans"]["pic"]}");
          setState(() {
            friends.add(ChatModel(
                data["fans"]["id"].toString(),
                data["fans"]["name"],
                data["fans"]["pic"] != null ? data["fans"]["pic"].replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/", "https://") : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                data["fans"]["email"],
                data["fans"]["username"],
                data["fans"]["fcmToken"],
                isfan: data["fans"]["isFan"],
                badge: data["topBadge"],
                isPrivate: data["fans"]["isPrivate"],
                fanList: data["fansList"],
                followList: data["fans"]["followList"]
            ));
          });
        });
      });
    }catch(e){
      setState(() {
        loading = false;
      });
      debugPrint("Error --> $e");
    }
  }
  void filterFriends(String query) {
    filteredFriends.clear();
    if (query.isEmpty) {
      setState(() {
        filteredFriends.addAll(friends);
      });
    } else {

      for (var friend in friends) {
        if (friend.name.toLowerCase().contains(query.toLowerCase()) || friend.username.toLowerCase().contains(query.toLowerCase())) {
          setState(() {
            filteredFriends.add(friend);
          });
        }
      }
    }
  }
  getMyIdols(){
    idolIdList.clear();
    setState(() {
      loading = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/fansidols/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        debugPrint("fansidols response==========>${jsonDecode(value.body)}");
        jsonDecode(value.body).forEach((data){
          setState(() {
            idolIdList.add(data["idols"]["id"]);
          });
        });
        print("Idols => ${idolIdList}");
      });
      getMyFriends();
    }catch(e){
      debugPrint("Error --> $e");
    }
  }

  removeFan(fanId){
    setState(() {
      loading = true;
    });
    https.delete(
      Uri.parse("$serverUrl/fansfansRequests/$fanId/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).then((value){
      setState(() {
        loading = false;
      });
      print(value.body.toString());
      getMyIdols();
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
  }
  addFan(from,to){
    setState(() {
      loading = true;
    });
    https.post(
      Uri.parse("$serverUrl/fansRequests/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        "from_user": from,
        "to_user": to
      }),
    ).then((value){
      sendFanMessage(from,to);
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
  }
  sendFanMessage(from,to){
    https.post(
      Uri.parse("$serverUrl/RequestMessage/personrequestsmessages/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        "from_user": from,
        "to_user": to,
        "to_token": token,
        "is_message": true,
        "message": "joined your fan club!"
      }),
    ).then((value){
      setState(() {
        loading = false;
        getMyIdols();
      });
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
  }

  getRequests() {
    requestList.clear();
    try {
      https.get(Uri.parse("$serverUrl/Request/personrequests/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        print("requests ==> ${value.body.toString()}");
        jsonDecode(value.body).forEach((e){
          setState(() {
            requestList.add(e);
          });
          print("item => ${e}");
        });
        setState(() {
          loading = false;
        });
        print("request list => ${requestList}");
      });
      getMyIdols();
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  getRequestsForCancel(friendID) {
    try {
      https.get(Uri.parse("$serverUrl/Request/personrequests/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        print("requests ==> ${value.body.toString()}");
        jsonDecode(value.body).forEach((e){
          if(e["from_user"]["id"].toString() == id && e["to_user"]["id"].toString() == friendID){
            fanRequestID = e["id"].toString();
            cancelFanRequest(fanRequestID);
            print("Fan Request ID ${fanRequestID}");
          }
          print("item => ${e}");
        });
        setState(() {
          loading = false;
        });
        //print("favourite list => ${myList}");
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  sendFanRequest(from,to){
    setState(() {
      requestLoader2 = true;
    });
    https.post(
      Uri.parse("$serverUrl/Request/personrequests/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        "from_user": from,
        "to_user": to,
        "to_token": token
      }),
    ).then((value){
      setState(() {
        requestLoader2 = false;
      });
      print("Fans Request Response ==> ${value.body.toString()}");
      setState(() {
        loading = true;
      });
      getRequests();
    }).catchError((value){
      setState(() {
        requestLoader2 = false;
      });
      print(value);
    });
  }
  cancelFanRequest(fanId){
    setState(() {
      requestLoader2 = true;
    });
    https.delete(
      Uri.parse("$serverUrl/Request/personrequests/$fanId/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).then((value){
      setState(() {
        requestLoader2 = false;
      });
      print(value.body.toString());
      setState(() {
        loading = true;
      });
      getRequests();
    }).catchError((value){
      setState(() {
        requestLoader2 = false;
      });
      print(value);
    });
  }

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
        title: const Text("Fans",style: TextStyle(fontFamily: Poppins),),
      ),
      body:loading == true ? SpinKitCircle(size: 50,color: primary,) : (friends.isEmpty ? const Center(child: Text("No Fans",style: TextStyle(fontFamily: Poppins,),)) :

      Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height*0.02,),
          Container(
            alignment: Alignment.bottomCenter,
            width: MediaQuery.of(context).size.width * 0.95,
            child: Card(
              elevation: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.topRight,
                      stops: const [0.0, 0.99],
                      tileMode: TileMode.clamp,
                      colors:  <Color>[Colors.black12, Colors.black12] ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                      },
                      child: Container(
                          height: 40,
                          width: 20,
                          child: Icon(Icons.search,color: ascent,)
                      ),
                    ),
                    const SizedBox(width: 16,),
                    Expanded(
                        child: TextField(
                          onChanged: (value) {
                            filterFriends(value);
                          },
                          style: const TextStyle(color: ascent,fontFamily: Poppins,),
                          cursorColor: ascent,
                          //style: simpleTextStyle(),
                          decoration: const InputDecoration(
                              fillColor: ascent,
                              hintText: "Search",
                              hintStyle: TextStyle(
                                color: ascent,
                                fontFamily: Poppins,
                                fontSize: 16,
                              ),
                              border: InputBorder.none
                          ),
                        )),
                    const SizedBox(width: 16,),
                  ],
                ),
              ),
            ),
          ),
          // SizedBox(
          //   height: 40,
          //   child: Padding(
          //     padding: const EdgeInsets.only(left: 16,right: 15),
          //     child: TextField(
          //       onChanged: (value) {
          //         filterFriends(value);
          //         // if (posts.isNotEmpty) {
          //         //   SearchUser(value);
          //         //   searchViaDescription(value);
          //         // } else {
          //         //   SearchFilteredUser(value);
          //         //   searchViaDescriptionForFiltered(value);
          //         // }
          //       },
          //       decoration: InputDecoration(
          //         prefixIcon: const Icon(Icons.search),
          //         // hintTextDirection: TextDirection.ltr,
          //         contentPadding:
          //         const EdgeInsets.only(top: 10),
          //         hintText: 'Search',
          //         hintStyle: const TextStyle(
          //           fontSize: 15,
          //           fontFamily: Poppins,
          //         ),
          //         border: const OutlineInputBorder(),
          //         focusColor: primary,
          //         focusedBorder: OutlineInputBorder(
          //           borderSide:
          //           BorderSide(width: 1, color: primary),
          //         ),
          //       ),
          //       cursorColor: primary,
          //       style: TextStyle(
          //           color: primary,
          //           fontSize: 13,
          //           fontFamily: Poppins),
          //     ),
          //   ),
          // ),
          filteredFriends.isEmpty?
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16,right: 5),
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) => WidgetAnimator(
                  InkWell(
                    onTap: friends[index].id != id ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendProfileScreen(
                            id: friends[index].id,
                            username: friends[index].username,
                          ),
                        ),
                      ).then((value){
                        getRequests();
                      });
                    }: (){},
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0,bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //const SizedBox(width: 20),
                          Row(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(120)),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                  child: CachedNetworkImage(
                                    imageUrl: friends[index].pic,
                                    imageBuilder: (context, imageProvider) => Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    placeholder: (context, url) => SpinKitCircle(color: primary, size: 20,),
                                    errorWidget: (context, url, error) => ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                                      child: Image.network(
                                        "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                        width: 40,
                                        height: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10,),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friends[index].username ?? "",
                                    style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: Poppins),
                                  ),
                                  Text(
                                    Uri.decodeComponent(friends[index].name),
                                    style: const TextStyle(fontFamily: Poppins),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10,),
                              if(friends[index].badge != null) GestureDetector(
                                onTap: (){
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => EventPosts(
                                  //   userid: friends[index].id.toString(),
                                  // )));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top:6.0),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(120)),
                                    child: CachedNetworkImage(
                                      imageUrl: friends[index].badge!["document"].toString().replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/","https://"),
                                      //imageUrl: lowestRankingOrderDocument,
                                      imageBuilder:
                                          (context, imageProvider) =>
                                          Container(
                                            height: 30,
                                            width: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              const BorderRadius.all(
                                                  Radius.circular(120)),
                                              image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                      placeholder: (context, url) =>
                                          Padding(
                                            padding: const EdgeInsets.only(top:6.0),
                                            child: SpinKitCircle(
                                              color: primary,
                                              size: 20,
                                            ),
                                          ),
                                      errorWidget: (context, url,
                                          error) =>
                                          ClipRRect(
                                              borderRadius:
                                              const BorderRadius.all(
                                                  Radius.circular(50)),
                                              child: Image.network(
                                                friends[index].badge!["document"],
                                                width: 30,
                                                height: 30,
                                                fit: BoxFit.contain,
                                              )),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          //const SizedBox(width: 20),
                          if(friends[index].id != id) Row(
                            mainAxisAlignment: MainAxisAlignment.end, // Align the button to the right
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if(friends[index].isPrivate == false) if((friends[index].fanList ?? []).contains(int.parse(id)) == true || (friends[index].followList ?? []).contains(int.parse(id)) == true) idolIdList.contains(int.parse(friends[index].id)) == true
                                  ? Container(
                                    width: 90,
                                    child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                ),
                                onPressed: () {
                                    removeFan(friends[index].id);
                                },
                                child: const Text(
                                    "Unfan",
                                    style: TextStyle(color: Colors.white, fontFamily: Poppins,fontSize: 12,fontWeight: FontWeight.w700,),
                                ),
                              ),
                                  )
                                  : Container(
                                    width: 90,
                                    child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                ),
                                onPressed: () {
                                    addFan(id, friends[index].id);
                                },
                                child: const Text(
                                    "Fan",
                                    style: TextStyle(color: Colors.white, fontFamily: Poppins,fontSize: 12,fontWeight: FontWeight.w700,),
                                ),
                              ),
                                  ),
                              if(friends[index].isPrivate == true) ((friends[index].fanList ?? []).contains(int.parse(id)) == true || (friends[index].followList ?? []).contains(int.parse(id)) == true)
                                  ? Container(
                                  width: 90,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: primary,
                                          title: Text("Unfan ${friends[index].username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                          content: Text("Are you sure you want to unfan ${friends[index].username}? If you change your mind, you'll need to send a fan request again?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                          actions: [
                                            TextButton(
                                              child: Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                              onPressed:  () {
                                                setState(() {
                                                  Navigator.pop(context);
                                                });
                                              },
                                            ),
                                            TextButton(
                                              child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                              onPressed:  () {
                                                Navigator.pop(context);
                                                removeFan(friends[index].id);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Unfan",
                                      style: TextStyle(color: Colors.white, fontFamily: Poppins,fontSize: 12,
                                        fontWeight: FontWeight.w700,),
                                    ),
                                  ),
                              )
                                  : Container(
                                width: 90,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == friends[index].id) == true ? Colors.grey : primary,
                                  ),
                                  onPressed: () {
                                    if(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == friends[index].id) == false){
                                      print("fan");
                                      sendFanRequest(id,friends[index].id);
                                      // showDialog(
                                      //   context: context,
                                      //   builder: (context) => AlertDialog(
                                      //     backgroundColor: primary,
                                      //     title: Text("Fan request ${friends[index].username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                      //     content: Text("Are you sure you want to send a fan request to ${friends[index].username}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                      //     actions: [
                                      //       TextButton(
                                      //         child: Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                      //         onPressed:  () {
                                      //           setState(() {
                                      //             Navigator.pop(context);
                                      //           });
                                      //         },
                                      //       ),
                                      //       TextButton(
                                      //         child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                      //         onPressed:  () {
                                      //           Navigator.pop(context);
                                      //           sendFanRequest(id,friends[index].id);
                                      //         },
                                      //       ),
                                      //     ],
                                      //   ),
                                      // );
                                    }else if(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == friends[index].id) == true) {
                                      print("unfan");
                                      getRequestsForCancel(friends[index].id);
                                      // showDialog(
                                      //   context: context,
                                      //   builder: (context) => AlertDialog(
                                      //     backgroundColor: primary,
                                      //     title: Text("Cancel request ${friends[index].username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                      //     content: Text("Are you sure you want to cancel fan request to ${friends[index].username}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                      //     actions: [
                                      //       TextButton(
                                      //         child: Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                      //         onPressed:  () {
                                      //           setState(() {
                                      //             Navigator.pop(context);
                                      //           });
                                      //         },
                                      //       ),
                                      //       TextButton(
                                      //         child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                      //         onPressed:  () {
                                      //           Navigator.pop(context);
                                      //           getRequestsForCancel(friends[index].id);
                                      //         },
                                      //       ),
                                      //     ],
                                      //   ),
                                      // );
                                      //removeFan(widget.id);
                                    }
                                    //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                                  },
                                  child: requestLoader2 == true ? const SpinKitCircle(color: ascent, size: 20,) : Text(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == friends[index].id) == true ? 'Req...' :'Fan Req...',style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: Poppins
                                  ),),
                                ),
                              ),
                              SizedBox(width: 12,),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
              :
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16,right: 5),
              child: ListView.builder(
                itemCount: filteredFriends.length,
                itemBuilder: (context, index) => WidgetAnimator(
                  GestureDetector(
                    onTap: filteredFriends[index].id != id ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendProfileScreen(
                            id: filteredFriends[index].id,
                            username: filteredFriends[index].username,
                          ),
                        ),
                      ).then((value){
                        getRequests();
                      });
                    }:(){},
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0,bottom: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(120)),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                  child: CachedNetworkImage(
                                    imageUrl: filteredFriends[index].pic,
                                    imageBuilder: (context, imageProvider) => Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    placeholder: (context, url) => SpinKitCircle(color: primary, size: 20,),
                                    errorWidget: (context, url, error) => ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                                      child: Image.network(
                                        "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                        width: 40,
                                        height: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    filteredFriends[index].username ?? "",
                                    style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: Poppins),
                                  ),
                                  Text(
                                    Uri.decodeComponent(filteredFriends[index].name),
                                    style: const TextStyle(fontFamily: Poppins),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10,),
                              if(filteredFriends[index].badge != null) GestureDetector(
                                onTap: (){
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => EventPosts(
                                  //   userid: filteredFriends[index].id.toString(),
                                  // )));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top:6.0),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(120)),
                                    child: CachedNetworkImage(
                                      imageUrl: filteredFriends[index].badge!["document"].toString().replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/","https://"),
                                      //imageUrl: lowestRankingOrderDocument,
                                      imageBuilder:
                                          (context, imageProvider) =>
                                          Container(
                                            height: 30,
                                            width: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              const BorderRadius.all(
                                                  Radius.circular(120)),
                                              image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                      placeholder: (context, url) =>
                                          Padding(
                                            padding: const EdgeInsets.only(top:6.0),
                                            child: SpinKitCircle(
                                              color: primary,
                                              size: 20,
                                            ),
                                          ),
                                      errorWidget: (context, url,
                                          error) =>
                                          ClipRRect(
                                              borderRadius:
                                              const BorderRadius.all(
                                                  Radius.circular(50)),
                                              child: Image.network(
                                                filteredFriends[index].badge!["document"]["document"],
                                                width: 30,
                                                height: 30,
                                                fit: BoxFit.contain,
                                              )),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if(filteredFriends[index].id != id) Row(
                            mainAxisAlignment: MainAxisAlignment.end, // Align the button to the right
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if(filteredFriends[index].isPrivate == false) if((filteredFriends[index].fanList ?? []).contains(int.parse(id)) == true || (filteredFriends[index].followList ?? []).contains(int.parse(id)) == true) idolIdList.contains(int.parse(filteredFriends[index].id)) == true
                                  ? Container(
                                    width: 90,
                                    child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                ),
                                onPressed: () {
                                    removeFan(filteredFriends[index].id);
                                },
                                child: const Text(
                                    "Unfan",
                                    style: TextStyle(color: Colors.white, fontFamily: Poppins,fontSize: 12,fontWeight: FontWeight.w700),
                                ),
                              ),
                                  )
                                  : Container(
                                width: 90,
                                    child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                ),
                                onPressed: () {
                                    addFan(id, filteredFriends[index].id);
                                },
                                child: const Text(
                                    "Fan",
                                    style: TextStyle(color: Colors.white, fontFamily: Poppins,fontSize: 12,fontWeight: FontWeight.w700),
                                ),
                              ),
                                  ),
                              if(filteredFriends[index].isPrivate == true) ((filteredFriends[index].fanList ?? []).contains(int.parse(id)) == true || (filteredFriends[index].followList ?? []).contains(int.parse(id)) == true)
                                  ? Container(
                                width: 90,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: primary,
                                        title: Text("Unfan ${filteredFriends[index].username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                        content: Text("Are you sure you want to unfan ${filteredFriends[index].username}? If you change your mind, you'll need to send a fan request again?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                        actions: [
                                          TextButton(
                                            child: Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                            onPressed:  () {
                                              setState(() {
                                                Navigator.pop(context);
                                              });
                                            },
                                          ),
                                          TextButton(
                                            child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                            onPressed:  () {
                                              Navigator.pop(context);
                                              removeFan(filteredFriends[index].id);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Unfan",
                                    style: TextStyle(color: Colors.white, fontFamily: Poppins,fontSize: 12,
                                      fontWeight: FontWeight.w700,),
                                  ),
                                ),
                              )
                                  : Container(
                                width: 90,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == filteredFriends[index].id) == true ? Colors.grey : primary,
                                  ),
                                  onPressed: () {
                                    if(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == filteredFriends[index].id) == false){
                                      print("fan");
                                      sendFanRequest(id,filteredFriends[index].id);
                                      // showDialog(
                                      //   context: context,
                                      //   builder: (context) => AlertDialog(
                                      //     backgroundColor: primary,
                                      //     title: Text("Fan request ${filteredFriends[index].username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                      //     content: Text("Are you sure you want to send fan request to ${filteredFriends[index].username}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                      //     actions: [
                                      //       TextButton(
                                      //         child: Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                      //         onPressed:  () {
                                      //           setState(() {
                                      //             Navigator.pop(context);
                                      //           });
                                      //         },
                                      //       ),
                                      //       TextButton(
                                      //         child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                      //         onPressed:  () {
                                      //           Navigator.pop(context);
                                      //           sendFanRequest(id,filteredFriends[index].id);
                                      //         },
                                      //       ),
                                      //     ],
                                      //   ),
                                      // );
                                    }else if(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == filteredFriends[index].id) == true) {
                                      print("unfan");
                                      getRequestsForCancel(filteredFriends[index].id);
                                      // showDialog(
                                      //   context: context,
                                      //   builder: (context) => AlertDialog(
                                      //     backgroundColor: primary,
                                      //     title: Text("Cancel request ${filteredFriends[index].username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                      //     content: Text("Are you sure you want to cancel fan request to ${filteredFriends[index].username}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                      //     actions: [
                                      //       TextButton(
                                      //         child: Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                      //         onPressed:  () {
                                      //           setState(() {
                                      //             Navigator.pop(context);
                                      //           });
                                      //         },
                                      //       ),
                                      //       TextButton(
                                      //         child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                      //         onPressed:  () {
                                      //           Navigator.pop(context);
                                      //           getRequestsForCancel(filteredFriends[index].id);
                                      //         },
                                      //       ),
                                      //     ],
                                      //   ),
                                      // );
                                      //removeFan(widget.id);
                                    }
                                    //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                                  },
                                  child: requestLoader2 == true ? const SpinKitCircle(color: ascent, size: 20,) : Text(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == filteredFriends[index].id) == true ? 'Req...' :'Fan Req...',style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: Poppins
                                  ),),
                                ),
                              ),
                              SizedBox(width: 12,),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      )),
    );
  }
}
