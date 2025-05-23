import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/event_posts.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import '../../animations/bottom_animation.dart';
import '../../models/chats_model.dart';
import '../../utils/constants.dart';

class FollowerScreen extends StatefulWidget {
  final List<dynamic> followers;
  final Function navigateTo;
  final int myIndex;
  const FollowerScreen({Key? key, required this.followers, required this.navigateTo, required this.myIndex}) : super(key: key);

  @override
  State<FollowerScreen> createState() => _FollowerScreenState();
}

class _FollowerScreenState extends State<FollowerScreen> {
  String id = "";
  String token = "";
  bool loading = false;
  List<ChatModel> friends = [];
  List<ChatModel> filteredFriends = [];
  List<int> idolIdList = [];

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(token);
    getMyIdols();
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


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("foollow ==> ${widget.followers}");
    getCashedData();
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
  getMyFriends(){
    friends.clear();
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
                data["fcmToken"],
                badge: data["topBadge"]
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
      setState(() {
        loading= false;
        getMyIdols();
      });
      print(value.body.toString());

    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
  }
  unfriendRequest(userid){
    setState(() {
      loading = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_remove/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      setState(() {
        loading = false;
      });
      print("Unfriend response ==> ${value.body.toString()}");
      Navigator.pop(context);
      getMyIdols();
      setState(() {
        loading = false;
      });
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
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
        //   title: const Text("Friends",style: TextStyle(fontFamily: Poppins),),
        // ),
        body:loading == true ? SpinKitCircle(size: 50,color: primary,) : (friends.isEmpty ? const Center(child: Text("No Friends",style: TextStyle(fontFamily: Poppins,),)) :
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
            //     padding: const EdgeInsets.only(left: 16,right: 16),
            //     child: TextField(
            //       onChanged: (value) {
            //         filterFriends(value);
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
              child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context,index) => GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                        id: friends[index].id,
                        username: friends[index].username,
                      ))).then((value){
                        getMyIdols();
                      });
                    },
                    child: WidgetAnimator(
                      InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                            id: friends[index].id,
                            username: friends[index].username,
                          ))).then((value){
                            getMyIdols();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 17.0,right: 17.0,bottom: 10,top: 10),
                          child: Row(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(120))
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                  child: CachedNetworkImage(
                                    imageUrl: friends[index].pic.toString().replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/https%3A/", "https://"),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(friends[index].username ?? "",style: TextStyle(color: primary,fontSize: 14,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(Uri.decodeComponent(friends[index].name),style: const TextStyle(fontFamily: Poppins,), textAlign: TextAlign.center,),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10,),
                              if(friends[index].badge != null) GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => EventPosts(
                                    userid: friends[index].id.toString(),
                                  )));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top:6.0),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(120)),
                                    child: CachedNetworkImage(
                                      imageUrl: friends[index].badge!["document"],
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
                                                friends[index].badge!["document"]["document"],
                                                width: 30,
                                                height: 30,
                                                fit: BoxFit.contain,
                                              )),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end, // Align the button to the right
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    widget.followers.contains(int.parse(friends[index].id)) == true
                                        ? ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                      ),
                                      onPressed: () {
                                        //removeFan(friends[index].id);
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              backgroundColor: primary,
                                              title: Text("Unfriend ${friends[index].username}",style: TextStyle(fontFamily: Poppins,fontSize: 18,color: ascent,fontWeight: FontWeight.bold),),
                                              content: Text("Are you sure you want to delete ${friends[index].username} from your friends list?",style: TextStyle(fontFamily: Poppins,color: ascent),),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text("Cancel",style: TextStyle(fontFamily: Poppins,color: ascent),),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    unfriendRequest(friends[index].id);
                                                  },
                                                  child: Text("Unfriend",style: TextStyle(fontFamily: Poppins,color: ascent),),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: const Text(
                                        "Unfriend",
                                        style: TextStyle(color: Colors.white, fontFamily: Poppins),
                                      ),
                                    )
                                        : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                      ),
                                      onPressed: () {
                                        //addFan(id, friends[index].id);
                                      },
                                      child: const Text(
                                        "Friend",
                                        style: TextStyle(color: Colors.white, fontFamily: Poppins),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ),
                  )
              ),
            ):
            Expanded(
              child: ListView.builder(
                  itemCount: filteredFriends.length,
                  itemBuilder: (context,index) => GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                        id: filteredFriends[index].id,
                        username: filteredFriends[index].username,
                      ))).then((value){
                        getMyIdols();
                      });
                    },
                    child: WidgetAnimator(
                        InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                              id: filteredFriends[index].id,
                              username: filteredFriends[index].username,
                            ))).then((value){
                              getMyIdols();
                            });
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
                                      imageUrl: filteredFriends[index].pic.toString().replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/https%3A/", "https://"),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(filteredFriends[index].username ?? "",style: TextStyle(color: primary,fontSize: 14,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(Uri.decodeComponent(filteredFriends[index].name),style: const TextStyle(fontFamily: Poppins,), textAlign: TextAlign.center,),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10,),
                                if(filteredFriends[index].badge != null) GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => EventPosts(
                                      userid: filteredFriends[index].id.toString(),
                                    )));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top:6.0),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(120)),
                                      child: CachedNetworkImage(
                                        imageUrl: filteredFriends[index].badge!["document"],
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
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end, // Align the button to the right
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      widget.followers.contains(int.parse(filteredFriends[index].id)) == true
                                          ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                        ),
                                        onPressed: () {
                                         // removeFan(filteredFriends[index].id);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: primary,
                                                title: Text("Unfriend ${filteredFriends[index].username}",style: TextStyle(fontFamily: Poppins,fontSize: 18,color: ascent,fontWeight: FontWeight.bold),),
                                                content: Text("Are you sure you want to delete ${filteredFriends[index].username} from your friends list?",style: TextStyle(fontFamily: Poppins,color: ascent),),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: Text("CANCEL",style: TextStyle(fontFamily: Poppins,color: ascent),),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      unfriendRequest(filteredFriends[index].id);
                                                    },
                                                    child: Text("CONFIRM",style: TextStyle(fontFamily: Poppins,color: ascent),),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: const Text(
                                          "Unfriend",
                                          style: TextStyle(color: Colors.white, fontFamily: Poppins),
                                        ),
                                      )
                                          : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                        ),
                                        onPressed: () {
                                          // addFan(id, filteredFriends[index].id);
                                        },
                                        child: const Text(
                                          "Friend",
                                          style: TextStyle(color: Colors.white, fontFamily: Poppins),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                    ),
                  )
              ),
            )
          ],
        )),
      ),
    );
  }
}
