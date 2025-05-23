import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/models/story_model.dart';
import 'package:finalfashiontimefrontend/models/userHistory.dart';
import 'package:finalfashiontimefrontend/models/user_model.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/stories/view_story.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;

import '../../../animations/bottom_animation.dart';

class UserSearchHistory extends StatefulWidget {
  const UserSearchHistory({super.key});

  @override
  State<UserSearchHistory> createState() => _UserSearchHistoryState();
}

class _UserSearchHistoryState extends State<UserSearchHistory> {
  String id = "";
  String token = "";
  bool loading = false;
  List<UserHistory> userHistory = [];

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(token);
    getUserHistory();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  getUserHistory(){
    userHistory.clear();
    https.get(
      Uri.parse("$serverUrl/apiSearchedHistory/my_search_history/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).then((value){
      print(value.body.toString());
      var responseData = jsonDecode(value.body);
      responseData.forEach((e){
        setState(() {
          userHistory.add(UserHistory(
              e["id"].toString(),
              e["userId"],
              e["name"],
              e["username"],
              e["image"],
              e["recent_stories"].length > 0 ? List<Story>.from(e["recent_stories"].map((e1){
                return Story(
                    duration: e1["time_since_created"],
                    url: e1["content"],
                    type: e1["type"],
                    user: User(name:e1["user"]["name"],username: e1['user']['username'],profileImageUrl:e1["user"]["pic"] == null ?"https://www.w3schools.com/w3images/avatar2.png":e1["user"]["pic"], id:e1["user"]["id"].toString()),
                    storyId: e1["id"],
                    viewed_users: e1["viewers"],
                    created: e1["created_at"],
                    close_friends_only: e1['close_friends_only'],
                    isPrivate: e1["is_user_private"],
                    fanList: e1["fansList"]
                );
              })) :[],
              e["close_friends_ids"],
              e["searched_user"]["fansList"],
              e["searched_user"]["followList"],
              e["searched_user"]["show_stories_to_non_friends"]
          ));
        });
      });
    });
  }

  removeUserHistory(String id,index){
    print(id);
    https.delete(
        Uri.parse("$serverUrl/apiSearchedHistory/$id/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      //print("History added");
      setState(() {
        userHistory.removeAt(index);
      });
      getUserHistory();
    });
  }
  removeAllHistory(String id){
    print(id);
    https.delete(
        Uri.parse("$serverUrl/apiSearchedHistory/$id/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      //print("History added");
      setState(() {
      });
    });
  }
  clearAll(){
    userHistory.forEach((element) {
      removeAllHistory(element.historyID);
    });
    getUserHistory();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar:  AppBar(
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
      //   title: const Text("All Searches",style: TextStyle(fontFamily: Poppins),),
      // ),
      body: loading == true ? SpinKitCircle(color: primary, size: 20,) :Column(
        children: [
          SizedBox(height: 20,),
          Padding(
            padding: const EdgeInsets.only(left:30.0, right: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("All Searches",style: TextStyle(fontFamily: Poppins,),),
                GestureDetector(
                    onTap: (){
                      clearAll();
                    },
                    child: const Text("Clear All",style: TextStyle(color: Colors.blue,fontFamily: Poppins,),))
              ],
            ),
          ),
          SizedBox(height: 20,),
          userHistory.isEmpty ? const Center(child: Text("No Searches",style: TextStyle(fontFamily: Poppins),)) : Expanded(
            child: ListView.builder(
              itemCount: userHistory.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FriendProfileScreen(
                          id: userHistory[index].id,
                          username: userHistory[index].username,
                        ),
                      ),
                    ).then((value){
                      getUserHistory();
                    });
                  },
                  child: WidgetAnimator(
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FriendProfileScreen(
                              id: userHistory[index].id,
                              username: userHistory[index].username,
                            ),
                          ),
                        ).then((value){
                          getUserHistory();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 20,),
                                userHistory[index].show_stories_to_non_friends == true ? GestureDetector(
                                  onTap:(userHistory[index].most_recent_story.length <= 0) ? (){
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FriendProfileScreen(
                                          id: userHistory[index].id,
                                          username: userHistory[index].username,
                                        ),
                                      ),
                                    ).then((value){
                                      getUserHistory();
                                    });
                                  }: (){
                                    print(index);
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                      storyList: userHistory[index].most_recent_story,
                                    ))).then((value){
                                      getUserHistory();
                                      //getMyFriends();
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                        // border: Border.all(
                                        //     width: 2.8,
                                        //     color:
                                        //     Colors.transparent),
                                        gradient: (userHistory[index].most_recent_story.length <= 0) ? null: (userHistory[index].most_recent_story.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.7],
                                            tileMode: TileMode.clamp,
                                            colors: <Color>[
                                              Colors.grey,
                                              Colors.grey,
                                            ]) :
                                        (userHistory[index].close_friends.contains(int.parse(id)) == true ?
                                        (userHistory[index].most_recent_story.any((story) => story.close_friends_only == true) ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.7],
                                            tileMode: TileMode.clamp,
                                            colors: <Color>[
                                              Colors.deepPurple,
                                              Colors.purpleAccent,
                                            ]) : LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.7],
                                            tileMode: TileMode.clamp,
                                            colors: <Color>[
                                              secondary,
                                              primary,
                                            ]))
                                            :LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.7],
                                            tileMode: TileMode.clamp,
                                            colors: <Color>[
                                              secondary,
                                              primary,
                                            ]
                                        ))
                                        )
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: Container(
                                        height: 48,
                                        width: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: const BorderRadius.all(Radius.circular(120)),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.all(Radius.circular(120)),
                                            child: CachedNetworkImage(
                                              imageUrl: userHistory[index].image,
                                              imageBuilder: (context, imageProvider) => Container(
                                                height: 48,
                                                width: 48,
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
                                                  width: 48,
                                                  height: 48,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ):(
                                    (userHistory[index].fanList.contains(int.parse(id)) == true || userHistory[index].followList.contains(int.parse(id)) == true)?
                                    GestureDetector(
                                      onTap:(userHistory[index].most_recent_story.length <= 0) ? (){
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FriendProfileScreen(
                                              id: userHistory[index].id,
                                              username: userHistory[index].username,
                                            ),
                                          ),
                                        ).then((value){
                                          getUserHistory();
                                        });
                                      }: (){
                                        print(index);
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                          storyList: userHistory[index].most_recent_story,
                                        ))).then((value){
                                          getUserHistory();
                                          //getMyFriends();
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.all(Radius.circular(120)),
                                            // border: Border.all(
                                            //     width: 2.8,
                                            //     color:
                                            //     Colors.transparent),
                                            gradient: (userHistory[index].most_recent_story.length <= 0) ? null: (userHistory[index].most_recent_story.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.topRight,
                                                stops: const [0.0, 0.7],
                                                tileMode: TileMode.clamp,
                                                colors: <Color>[
                                                  Colors.grey,
                                                  Colors.grey,
                                                ]) :
                                            (userHistory[index].close_friends.contains(int.parse(id)) == true ?
                                            (userHistory[index].most_recent_story.any((story) => story.close_friends_only == true) ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.topRight,
                                                stops: const [0.0, 0.7],
                                                tileMode: TileMode.clamp,
                                                colors: <Color>[
                                                  Colors.deepPurple,
                                                  Colors.purpleAccent,
                                                ]) : LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.topRight,
                                                stops: const [0.0, 0.7],
                                                tileMode: TileMode.clamp,
                                                colors: <Color>[
                                                  secondary,
                                                  primary,
                                                ]))
                                                :LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.topRight,
                                                stops: const [0.0, 0.7],
                                                tileMode: TileMode.clamp,
                                                colors: <Color>[
                                                  secondary,
                                                  primary,
                                                ]
                                            ))
                                            )
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: Container(
                                            height: 48,
                                            width: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: const BorderRadius.all(Radius.circular(120)),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3.0),
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                child: CachedNetworkImage(
                                                  imageUrl: userHistory[index].image,
                                                  imageBuilder: (context, imageProvider) => Container(
                                                    height: 48,
                                                    width: 48,
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
                                                      width: 48,
                                                      height: 48,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ):
                                    GestureDetector(
                                      onTap:(userHistory[index].most_recent_story.length <= 0) ? (){
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FriendProfileScreen(
                                              id: userHistory[index].id,
                                              username: userHistory[index].username,
                                            ),
                                          ),
                                        ).then((value){
                                          getUserHistory();
                                        });
                                      }: (){
                                        print(index);
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                          storyList: userHistory[index].most_recent_story,
                                        ))).then((value){
                                          getUserHistory();
                                          //getMyFriends();
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(Radius.circular(120)),
                                          // border: Border.all(
                                          //     width: 2.8,
                                          //     color:
                                          //     Colors.transparent),
                                          // gradient: (userHistory[index].most_recent_story.length <= 0) ? null: (userHistory[index].most_recent_story.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                          //     begin: Alignment.topLeft,
                                          //     end: Alignment.topRight,
                                          //     stops: const [0.0, 0.7],
                                          //     tileMode: TileMode.clamp,
                                          //     colors: <Color>[
                                          //       Colors.grey,
                                          //       Colors.grey,
                                          //     ]) :
                                          // (userHistory[index].close_friends.contains(int.parse(id)) == true ?
                                          // (userHistory[index].most_recent_story.any((story) => story.close_friends_only == true) ? LinearGradient(
                                          //     begin: Alignment.topLeft,
                                          //     end: Alignment.topRight,
                                          //     stops: const [0.0, 0.7],
                                          //     tileMode: TileMode.clamp,
                                          //     colors: <Color>[
                                          //       Colors.deepPurple,
                                          //       Colors.purpleAccent,
                                          //     ]) : LinearGradient(
                                          //     begin: Alignment.topLeft,
                                          //     end: Alignment.topRight,
                                          //     stops: const [0.0, 0.7],
                                          //     tileMode: TileMode.clamp,
                                          //     colors: <Color>[
                                          //       secondary,
                                          //       primary,
                                          //     ]))
                                          //     :LinearGradient(
                                          //     begin: Alignment.topLeft,
                                          //     end: Alignment.topRight,
                                          //     stops: const [0.0, 0.7],
                                          //     tileMode: TileMode.clamp,
                                          //     colors: <Color>[
                                          //       secondary,
                                          //       primary,
                                          //     ]
                                          // ))
                                          // )
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: Container(
                                            height: 48,
                                            width: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              borderRadius: const BorderRadius.all(Radius.circular(120)),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3.0),
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                child: CachedNetworkImage(
                                                  imageUrl: userHistory[index].image,
                                                  imageBuilder: (context, imageProvider) => Container(
                                                    height: 48,
                                                    width: 48,
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
                                                      width: 48,
                                                      height: 48,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                ),
                                const SizedBox(width: 20,),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              userHistory[index].username ?? "",
                                              style: TextStyle(
                                                color: primary,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: Poppins,
                                              ),
                                              textAlign: TextAlign.start,
                                            ),
                                          ),
                                        ],
                                      ),
                                      userHistory[index].name == "" ? SizedBox() :Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              Uri.decodeComponent(userHistory[index].name),
                                              style: const TextStyle(fontFamily: Poppins,),
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: (){
                                    removeUserHistory(userHistory[index].historyID,index);
                                  },
                                )
                                // friends[index].badge["id"] == 0
                                //     ? const SizedBox()
                                //     : Expanded(
                                //   child: ClipRRect(
                                //     borderRadius: const BorderRadius.all(Radius.circular(120)),
                                //     child: CachedNetworkImage(
                                //       imageUrl: friends[index].badge['document'],
                                //       imageBuilder: (context, imageProvider) => Container(
                                //         height: 45,
                                //         width: 45,
                                //         decoration: BoxDecoration(
                                //           borderRadius: const BorderRadius.all(Radius.circular(120)),
                                //           image: DecorationImage(
                                //             image: imageProvider,
                                //             fit: BoxFit.contain,
                                //           ),
                                //         ),
                                //       ),
                                //       placeholder: (context, url) => SpinKitCircle(color: primary, size: 20,),
                                //       errorWidget: (context, url, error) => ClipRRect(
                                //         borderRadius: const BorderRadius.all(Radius.circular(50)),
                                //         child: Image.network(
                                //           friends[index].badge['document'],
                                //           width: 45,
                                //           height: 45,
                                //           fit: BoxFit.contain,
                                //         ),
                                //       ),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}



