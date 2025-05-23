import 'dart:convert';
import 'package:finalfashiontimefrontend/models/search_model.dart';
import 'package:finalfashiontimefrontend/models/story_model.dart';
import 'package:finalfashiontimefrontend/models/userHistory.dart';
import 'package:finalfashiontimefrontend/models/user_model.dart';
// import 'package:fashiontimefinal/screens/pages/friend_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/stories/view_story.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;

class HistorySearchScreen extends StatefulWidget {
  final Function onNavigate;
  const HistorySearchScreen({Key? key, required this.onNavigate}) : super(key: key);
  @override
  State<HistorySearchScreen> createState() => _HistorySearchScreenState();
}

class _HistorySearchScreenState extends State<HistorySearchScreen> {
  String search = "";
  String id = "";
  String token = "";
  bool loading = false;
  List<SearchModel> friends = [];
  List<SearchModel> filteredItems = [];
  int pagination=1;
  String lastSearchQuery = "";
  List<UserHistory> userHistory = [];
  final TextEditingController _searchController = TextEditingController();
  List<SearchModel> filteredFriends = [];
  List<int> myList = [];

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(token);
    getFavourites();
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
    _searchController.addListener(_filterFriends);
  }

  void getMyFriends() async {
    try {
      var response = await https.get(
        Uri.parse("$serverUrl/user/api/allUsers/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      setState(() {
        friends.clear();
        filteredFriends.clear();
        loading = false;
      });

      final body = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(body);
      var results = jsonData['results'];

      results.forEach((data) {
        if (data["id"].toString() != id.toString() && data["isBlocked"] == false) {
          var friend = SearchModel(
            data["id"].toString(),
            data["name"] ?? "",
            data["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
            data["email"],
            data["username"],
            data["fcmToken"] ?? "",
            data["badge"] ?? {"id": 0},
            data["recent_stories"].length > 0 ? List<Story>.from(data["recent_stories"].map((e) {
              return Story(
                  duration: e["time_since_created"],
                  url: e["content"],
                  type: e["type"],
                  user: User(
                    name: e["user"]["name"],
                    username: e['user']['username'],
                    profileImageUrl: e["user"]["pic"] ?? "https://www.w3schools.com/w3images/avatar2.png",
                    id: e["user"]["id"].toString(),
                  ),
                  storyId: e["id"],
                  viewed_users: e["viewers"],
                  created: e["created_at"],
                  close_friends_only: e['close_friends_only'],
                  isPrivate: e["is_user_private"],
                  fanList: e["fansList"]
              );
            })) : [],
            data["close_friends_ids"],
            data["show_stories_to_non_friends"],
            data["fansList"],
            data["followList"],
          );

          setState(() {
            friends.add(friend);
            filteredFriends.add(friend); // Populate the filtered list initially
          });
        }
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
    getUserHistory();
  }


  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredFriends = friends
          .where((friend) => friend.name.toLowerCase().contains(query) || friend.username.toLowerCase().contains(query))
          .toList()..sort((a, b) => b.fanList.length.compareTo(a.fanList.length));
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFriends);
    _searchController.dispose();
    super.dispose();
  }

  getFavourites() {
    setState(() {
      loading = true;
    });
    myList.clear();

    try {
      https.get(Uri.parse("$serverUrl/apiuser-favorites/favorite-ids/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        setState(() {
          loading = false;
        });
        print("favourite ==> ${value.body.toString()}");
        jsonDecode(value.body).forEach((e){
          print("item => ${e}");
          myList.add(e);
        });
        print("favourite list => ${myList}");
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
    getMyFriends();
  }

  addUserHistory(String id,String name, String username, String image){
    print(id);
    https.post(
        Uri.parse("$serverUrl/apiSearchedHistory/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({
          "userId": id.toString(),
          "name": name,
          "username": username,
          "image": image
        })
    ).then((value){
      //print("History added");
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FriendProfileScreen(
            id: id,
            username: username,
          ),
        ),
      ).then((value){
        getUserHistory();
      });
    });
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
              e["searched_user"] != null ? e["searched_user"]["fansList"] : 0,
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

  String formatTimeDifference(String dateString) {
    DateTime createdAt = DateTime.parse(dateString);
    DateTime now = DateTime.now();

    Duration difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      if (difference.inDays == 1) {
        return '1 day ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } else if (difference.inDays < 30) {
      int weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      int months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      int years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
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
        //   title: const Text("Search for users",style: TextStyle(fontFamily: Poppins,),),
        // ),
        body: Column(
            children: [
              const SizedBox(height: 10,),
              WidgetAnimator(
                Container(
                  alignment: Alignment.bottomCenter,
                  width: MediaQuery.of(context).size.width * 0.9,
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
                                controller: _searchController,
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
              ),
              if(_searchController.text.isNotEmpty) Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left:10.0, right: 10.0),
                  child:  ListView.builder(
                    itemCount: filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = filteredFriends[index];
                      return ListTile(
                        onTap: (){
                          addUserHistory(filteredFriends[index].id,filteredFriends[index].name,filteredFriends[index].username,filteredFriends[index].pic);
                        },
                        leading: myList.contains(int.parse(friend.id)) == false ? (friend.show_stories_to_non_friends == true ? GestureDetector(
                          onTap:(friend.most_recent_story.length <= 0) ? (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FriendProfileScreen(
                                  id: friend.id,
                                  username: friend.username,
                                ),
                              ),
                            ).then((value){
                              getMyFriends();
                              getUserHistory();
                            });
                          }: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                              storyList: friend.most_recent_story,
                            ))).then((value){
                              getFavourites();
                              // getMyFriends();
                              // getUserHistory();
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(Radius.circular(120)),
                                // border: Border.all(
                                //     width: 2.8,
                                //     color:
                                //     Colors.transparent),
                                gradient: (friend.most_recent_story.length <= 0) ? null : (friend.most_recent_story.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.topRight,
                                    stops: const [0.0, 0.7],
                                    tileMode: TileMode.clamp,
                                    colors: <Color>[
                                      Colors.grey,
                                      Colors.grey,
                                    ]) :
                                (friend.close_friends.contains(int.parse(id)) == true ?
                                (friend.most_recent_story.any((story) => story.close_friends_only == true) ? LinearGradient(
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
                                )))
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
                                      imageUrl: friend.pic,
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
                        ) : (
                            (friend.fanList.contains(int.parse(id)) == true || friend.friendList.contains(int.parse(id)) == true) ?
                            GestureDetector(
                              onTap:(friend.most_recent_story.length <= 0) ? (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FriendProfileScreen(
                                      id: friend.id,
                                      username: friend.username,
                                    ),
                                  ),
                                ).then((value){
                                  getFavourites();
                                });
                              }: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                  storyList: friend.most_recent_story,
                                ))).then((value){
                                  getFavourites();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(120)),
                                    // border: Border.all(
                                    //     width: 2.8,
                                    //     color:
                                    //     Colors.transparent),
                                    gradient: (friend.most_recent_story.length <= 0) ? null : (friend.most_recent_story.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.topRight,
                                        stops: const [0.0, 0.7],
                                        tileMode: TileMode.clamp,
                                        colors: <Color>[
                                          Colors.grey,
                                          Colors.grey,
                                        ]) :
                                    (friend.close_friends.contains(int.parse(id)) == true ?
                                    (friend.most_recent_story.any((story) => story.close_friends_only == true) ? LinearGradient(
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
                                    )))
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
                                          imageUrl: friend.pic,
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
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FriendProfileScreen(
                                      id: friend.id,
                                      username: friend.username,
                                    ),
                                  ),
                                ).then((value){
                                  getFavourites();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                  // border: Border.all(
                                  //     width: 2.8,
                                  //     color:
                                  //     Colors.transparent),
                                  // gradient: (friends[index].most_recent_story.length <= 0) ? null : (friends[index].most_recent_story.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                  //     begin: Alignment.topLeft,
                                  //     end: Alignment.topRight,
                                  //     stops: const [0.0, 0.7],
                                  //     tileMode: TileMode.clamp,
                                  //     colors: <Color>[
                                  //       Colors.grey,
                                  //       Colors.grey,
                                  //     ]) :
                                  // (friends[index].close_friends.contains(int.parse(id)) == true ?
                                  // (friends[index].most_recent_story.any((story) => story.close_friends_only == true) ? LinearGradient(
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
                                  // )))
                                ),
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.transparent,
                                    ),
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: const BorderRadius.all(Radius.circular(120)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(120)),
                                    child: CachedNetworkImage(
                                      imageUrl: friend.pic,
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
                                          width: 50,
                                          height: 50,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                        )):GestureDetector(
                          onTap:(){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FriendProfileScreen(
                                  id: friend.id,
                                  username: friend.username,
                                ),
                              ),
                            ).then((value){
                              getFavourites();
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
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: const BorderRadius.all(Radius.circular(120)),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(120)),
                                child: CachedNetworkImage(
                                  imageUrl: friend.pic,
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
                                      width: 50,
                                      height: 50,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        title: Text(friend.username,style: TextStyle(
                          color: primary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontFamily: Poppins,
                        ),),
                        subtitle: friend.name == "" ? null : Text(Uri.decodeComponent(friend.name),style: const TextStyle(fontFamily: Poppins,),),
                      );
                    },
                  ),
                ),
              ),
              if(_searchController.text.isEmpty) const SizedBox(height: 20,),
              if(_searchController.text.isEmpty)  Padding(
                padding: const EdgeInsets.only(left:30.0, right: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Recent Searches",style: TextStyle(fontFamily: Poppins,),),
                    GestureDetector(
                        onTap: (){
                          widget.onNavigate(36);
                          // Navigator.push(context,MaterialPageRoute(builder: (context) => const UserSearchHistory())).then((value){
                          //   getUserHistory();
                          // });
                        },
                        child: const Text("View All",style: TextStyle(color: Colors.blue,fontFamily: Poppins,),))
                  ],
                ),
              ),
              if(_searchController.text.isEmpty)  userHistory.isEmpty ? const Center(child: Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Text("No Searches",style: TextStyle(fontFamily: Poppins,),),
              )) :
              Expanded(
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
                          getFavourites();
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
                              getFavourites();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 20,),
                                    if(myList.contains(int.parse(userHistory[index].id)) == false) userHistory[index].show_stories_to_non_friends == true ? GestureDetector(
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
                                          getFavourites();
                                        });
                                      }: (){
                                        print(index);
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                          storyList: userHistory[index].most_recent_story,
                                        ))).then((value){
                                          getFavourites();
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
                                              getFavourites();
                                            });
                                          }: (){
                                            print(index);
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                              storyList: userHistory[index].most_recent_story,
                                            ))).then((value){
                                              getFavourites();
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
                                              getFavourites();
                                            });
                                          }: (){
                                            print(index);
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                              storyList: userHistory[index].most_recent_story,
                                            ))).then((value){
                                              getFavourites();
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
                                        )
                                    ),
                                    if(myList.contains(int.parse(userHistory[index].id)) == true) GestureDetector(
                                      onTap:(){
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FriendProfileScreen(
                                              id: userHistory[index].id,
                                              username: userHistory[index].username,
                                            ),
                                          ),
                                        ).then((value){
                                          getFavourites();
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
              ),
              if(_searchController.text.isEmpty)  const SizedBox(height: 20,),
              // Padding(
              //   padding: EdgeInsets.only(left:30.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.start,
              //     children: [
              //       Text("All users",style: TextStyle(fontFamily: Poppins,),),
              //     ],
              //   ),
              // ),
              // loading == true ? SpinKitCircle(color: primary,size: 50,) :(friends.isEmpty ? const SizedBox() :
              // Expanded(
              //   child: ListView.builder(
              //     itemCount: friends.length + 1,
              //     itemBuilder: (context, index) {
              //       if (index == friends.length) {
              //         return IconButton(
              //           onPressed: () {
              //             // Refresh logic here
              //             pagination++;
              //             setState(() {
              //               getMyFriends(pagination);
              //             });
              //
              //           },
              //           icon:   const Icon(Icons.refresh),color: primary,
              //         );
              //       }
              //
              //       return InkWell(
              //         onTap: () {
              //           addUserHistory(friends[index].id,friends[index].name,friends[index].username,friends[index].pic);
              //         },
              //         child: WidgetAnimator(
              //           GestureDetector(
              //             onTap: () {
              //               addUserHistory(friends[index].id,friends[index].name,friends[index].username,friends[index].pic);
              //             },
              //             child: Padding(
              //               padding: const EdgeInsets.all(10.0),
              //               child: Column(
              //                 children: [
              //                   Row(
              //                     children: [
              //                       const SizedBox(width: 20,),
              //                       friends[index].show_stories_to_non_friends == true ? GestureDetector(
              //                         onTap:(friends[index].most_recent_story.length <= 0) ? (){
              //                           Navigator.push(
              //                             context,
              //                             MaterialPageRoute(
              //                               builder: (context) => FriendProfileScreen(
              //                                 id: friends[index].id,
              //                                 username: friends[index].username,
              //                               ),
              //                             ),
              //                           ).then((value){
              //                             getMyFriends(1);
              //                             getUserHistory();
              //                           });
              //                         }: (){
              //                           Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
              //                             storyList: friends[index].most_recent_story,
              //                           ))).then((value){
              //                             getMyFriends(1);
              //                             getUserHistory();
              //                           });
              //                         },
              //                         child: Container(
              //                           decoration: BoxDecoration(
              //                               borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                               border: Border.all(
              //                                   width: 2.8,
              //                                   color:
              //                                   Colors.transparent),
              //                               gradient: (friends[index].most_recent_story.length <= 0) ? null : (friends[index].most_recent_story.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
              //                                   begin: Alignment.topLeft,
              //                                   end: Alignment.topRight,
              //                                   stops: const [0.0, 0.7],
              //                                   tileMode: TileMode.clamp,
              //                                   colors: <Color>[
              //                                     Colors.grey,
              //                                     Colors.grey,
              //                                   ]) :
              //                               (friends[index].close_friends.contains(int.parse(id)) == true ?
              //                               (friends[index].most_recent_story.any((story) => story.close_friends_only == true) ? LinearGradient(
              //                                   begin: Alignment.topLeft,
              //                                   end: Alignment.topRight,
              //                                   stops: const [0.0, 0.7],
              //                                   tileMode: TileMode.clamp,
              //                                   colors: <Color>[
              //                                     Colors.deepPurple,
              //                                     Colors.purpleAccent,
              //                                   ]) : LinearGradient(
              //                                   begin: Alignment.topLeft,
              //                                   end: Alignment.topRight,
              //                                   stops: const [0.0, 0.7],
              //                                   tileMode: TileMode.clamp,
              //                                   colors: <Color>[
              //                                     secondary,
              //                                     primary,
              //                                   ]))
              //                                   :LinearGradient(
              //                                   begin: Alignment.topLeft,
              //                                   end: Alignment.topRight,
              //                                   stops: const [0.0, 0.7],
              //                                   tileMode: TileMode.clamp,
              //                                   colors: <Color>[
              //                                     secondary,
              //                                     primary,
              //                                   ]
              //                               )))
              //                           ),
              //                           child: Container(
              //                             height: 50,
              //                             width: 50,
              //                             decoration: BoxDecoration(
              //                               border: Border.all(
              //                                 color: (friends[index].badge["id"] == 1 ||
              //                                     friends[index].badge["id"] == 2 ||
              //                                     friends[index].badge["id"] == 3 ||
              //                                     friends[index].badge["id"] == 4 ||
              //                                     friends[index].badge["id"] == 5 ||
              //                                     friends[index].badge["id"] == 6 ||
              //                                     friends[index].badge["id"] == 7 ||
              //                                     friends[index].badge["id"] == 8 ||
              //                                     friends[index].badge["id"] == 9
              //                                 ) ? Colors.orange : Colors.transparent,
              //                               ),
              //                               color: Colors.black.withOpacity(0.6),
              //                               borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                             ),
              //                             child: ClipRRect(
              //                               borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                               child: CachedNetworkImage(
              //                                 imageUrl: friends[index].pic,
              //                                 imageBuilder: (context, imageProvider) => Container(
              //                                   height: 50,
              //                                   width: 50,
              //                                   decoration: BoxDecoration(
              //                                     borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                                     image: DecorationImage(
              //                                       image: imageProvider,
              //                                       fit: BoxFit.cover,
              //                                     ),
              //                                   ),
              //                                 ),
              //                                 placeholder: (context, url) => SpinKitCircle(color: primary, size: 20,),
              //                                 errorWidget: (context, url, error) => ClipRRect(
              //                                   borderRadius: const BorderRadius.all(Radius.circular(50)),
              //                                   child: Image.network(
              //                                     "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
              //                                     width: 50,
              //                                     height: 50,
              //                                   ),
              //                                 ),
              //                               ),
              //                             ),
              //                           ),
              //                         ),
              //                       ) : (
              //                           (friends[index].fanList.contains(int.parse(id)) == true || friends[index].friendList.contains(int.parse(id)) == true) ?
              //                           GestureDetector(
              //                             onTap:(friends[index].most_recent_story.length <= 0) ? (){
              //                               Navigator.push(
              //                                 context,
              //                                 MaterialPageRoute(
              //                                   builder: (context) => FriendProfileScreen(
              //                                     id: friends[index].id,
              //                                     username: friends[index].username,
              //                                   ),
              //                                 ),
              //                               ).then((value){
              //                                 getMyFriends(1);
              //                                 getUserHistory();
              //                               });
              //                             }: (){
              //                               Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
              //                                 storyList: friends[index].most_recent_story,
              //                               ))).then((value){
              //                                 getMyFriends(1);
              //                                 getUserHistory();
              //                               });
              //                             },
              //                             child: Container(
              //                               decoration: BoxDecoration(
              //                                   borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                                   border: Border.all(
              //                                       width: 2.8,
              //                                       color:
              //                                       Colors.transparent),
              //                                   gradient: (friends[index].most_recent_story.length <= 0) ? null : (friends[index].most_recent_story.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
              //                                       begin: Alignment.topLeft,
              //                                       end: Alignment.topRight,
              //                                       stops: const [0.0, 0.7],
              //                                       tileMode: TileMode.clamp,
              //                                       colors: <Color>[
              //                                         Colors.grey,
              //                                         Colors.grey,
              //                                       ]) :
              //                                   (friends[index].close_friends.contains(int.parse(id)) == true ?
              //                                   (friends[index].most_recent_story.any((story) => story.close_friends_only == true) ? LinearGradient(
              //                                       begin: Alignment.topLeft,
              //                                       end: Alignment.topRight,
              //                                       stops: const [0.0, 0.7],
              //                                       tileMode: TileMode.clamp,
              //                                       colors: <Color>[
              //                                         Colors.deepPurple,
              //                                         Colors.purpleAccent,
              //                                       ]) : LinearGradient(
              //                                       begin: Alignment.topLeft,
              //                                       end: Alignment.topRight,
              //                                       stops: const [0.0, 0.7],
              //                                       tileMode: TileMode.clamp,
              //                                       colors: <Color>[
              //                                         secondary,
              //                                         primary,
              //                                       ]))
              //                                       :LinearGradient(
              //                                       begin: Alignment.topLeft,
              //                                       end: Alignment.topRight,
              //                                       stops: const [0.0, 0.7],
              //                                       tileMode: TileMode.clamp,
              //                                       colors: <Color>[
              //                                         secondary,
              //                                         primary,
              //                                       ]
              //                                   )))
              //                               ),
              //                               child: Container(
              //                                 height: 50,
              //                                 width: 50,
              //                                 decoration: BoxDecoration(
              //                                   border: Border.all(
              //                                     color: (friends[index].badge["id"] == 1 ||
              //                                         friends[index].badge["id"] == 2 ||
              //                                         friends[index].badge["id"] == 3 ||
              //                                         friends[index].badge["id"] == 4 ||
              //                                         friends[index].badge["id"] == 5 ||
              //                                         friends[index].badge["id"] == 6 ||
              //                                         friends[index].badge["id"] == 7 ||
              //                                         friends[index].badge["id"] == 8 ||
              //                                         friends[index].badge["id"] == 9
              //                                     ) ? Colors.orange : Colors.transparent,
              //                                   ),
              //                                   color: Colors.black.withOpacity(0.6),
              //                                   borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                                 ),
              //                                 child: ClipRRect(
              //                                   borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                                   child: CachedNetworkImage(
              //                                     imageUrl: friends[index].pic,
              //                                     imageBuilder: (context, imageProvider) => Container(
              //                                       height: 50,
              //                                       width: 50,
              //                                       decoration: BoxDecoration(
              //                                         borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                                         image: DecorationImage(
              //                                           image: imageProvider,
              //                                           fit: BoxFit.cover,
              //                                         ),
              //                                       ),
              //                                     ),
              //                                     placeholder: (context, url) => SpinKitCircle(color: primary, size: 20,),
              //                                     errorWidget: (context, url, error) => ClipRRect(
              //                                       borderRadius: const BorderRadius.all(Radius.circular(50)),
              //                                       child: Image.network(
              //                                         "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
              //                                         width: 50,
              //                                         height: 50,
              //                                       ),
              //                                     ),
              //                                   ),
              //                                 ),
              //                               ),
              //                             ),
              //                           ):
              //                           GestureDetector(
              //                             onTap: (){
              //                               Navigator.push(
              //                                 context,
              //                                 MaterialPageRoute(
              //                                   builder: (context) => FriendProfileScreen(
              //                                     id: friends[index].id,
              //                                     username: friends[index].username,
              //                                   ),
              //                                 ),
              //                               ).then((value){
              //                                 getMyFriends(1);
              //                                 getUserHistory();
              //                               });
              //                             },
              //                             child: Container(
              //                               decoration: BoxDecoration(
              //                                 borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                                 // border: Border.all(
              //                                 //     width: 2.8,
              //                                 //     color:
              //                                 //     Colors.transparent),
              //                                 // gradient: (friends[index].most_recent_story.length <= 0) ? null : (friends[index].most_recent_story.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
              //                                 //     begin: Alignment.topLeft,
              //                                 //     end: Alignment.topRight,
              //                                 //     stops: const [0.0, 0.7],
              //                                 //     tileMode: TileMode.clamp,
              //                                 //     colors: <Color>[
              //                                 //       Colors.grey,
              //                                 //       Colors.grey,
              //                                 //     ]) :
              //                                 // (friends[index].close_friends.contains(int.parse(id)) == true ?
              //                                 // (friends[index].most_recent_story.any((story) => story.close_friends_only == true) ? LinearGradient(
              //                                 //     begin: Alignment.topLeft,
              //                                 //     end: Alignment.topRight,
              //                                 //     stops: const [0.0, 0.7],
              //                                 //     tileMode: TileMode.clamp,
              //                                 //     colors: <Color>[
              //                                 //       Colors.deepPurple,
              //                                 //       Colors.purpleAccent,
              //                                 //     ]) : LinearGradient(
              //                                 //     begin: Alignment.topLeft,
              //                                 //     end: Alignment.topRight,
              //                                 //     stops: const [0.0, 0.7],
              //                                 //     tileMode: TileMode.clamp,
              //                                 //     colors: <Color>[
              //                                 //       secondary,
              //                                 //       primary,
              //                                 //     ]))
              //                                 //     :LinearGradient(
              //                                 //     begin: Alignment.topLeft,
              //                                 //     end: Alignment.topRight,
              //                                 //     stops: const [0.0, 0.7],
              //                                 //     tileMode: TileMode.clamp,
              //                                 //     colors: <Color>[
              //                                 //       secondary,
              //                                 //       primary,
              //                                 //     ]
              //                                 // )))
              //                               ),
              //                               child: Container(
              //                                 height: 50,
              //                                 width: 50,
              //                                 decoration: BoxDecoration(
              //                                   border: Border.all(
              //                                     color: (friends[index].badge["id"] == 1 ||
              //                                         friends[index].badge["id"] == 2 ||
              //                                         friends[index].badge["id"] == 3 ||
              //                                         friends[index].badge["id"] == 4 ||
              //                                         friends[index].badge["id"] == 5 ||
              //                                         friends[index].badge["id"] == 6 ||
              //                                         friends[index].badge["id"] == 7 ||
              //                                         friends[index].badge["id"] == 8 ||
              //                                         friends[index].badge["id"] == 9
              //                                     ) ? Colors.orange : Colors.transparent,
              //                                   ),
              //                                   color: Colors.black.withOpacity(0.6),
              //                                   borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                                 ),
              //                                 child: ClipRRect(
              //                                   borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                                   child: CachedNetworkImage(
              //                                     imageUrl: friends[index].pic,
              //                                     imageBuilder: (context, imageProvider) => Container(
              //                                       height: 50,
              //                                       width: 50,
              //                                       decoration: BoxDecoration(
              //                                         borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                                         image: DecorationImage(
              //                                           image: imageProvider,
              //                                           fit: BoxFit.cover,
              //                                         ),
              //                                       ),
              //                                     ),
              //                                     placeholder: (context, url) => SpinKitCircle(color: primary, size: 20,),
              //                                     errorWidget: (context, url, error) => ClipRRect(
              //                                       borderRadius: const BorderRadius.all(Radius.circular(50)),
              //                                       child: Image.network(
              //                                         "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
              //                                         width: 50,
              //                                         height: 50,
              //                                       ),
              //                                     ),
              //                                   ),
              //                                 ),
              //                               ),
              //                             ),
              //                           )
              //                       ),
              //                       const SizedBox(width: 20,),
              //                       Expanded(
              //                         child: Column(
              //                           children: [
              //                             Row(
              //                               mainAxisAlignment: MainAxisAlignment.start,
              //                               children: [
              //                                 Flexible(
              //                                   child: Text(
              //                                     friends[index].username ?? "",
              //                                     style: TextStyle(
              //                                       color: primary,
              //                                       fontSize: 17,
              //                                       fontWeight: FontWeight.bold,
              //                                       fontFamily: Poppins,
              //                                     ),
              //                                     textAlign: TextAlign.start,
              //                                   ),
              //                                 ),
              //                               ],
              //                             ),
              //                             Row(
              //                               mainAxisAlignment: MainAxisAlignment.start,
              //                               children: [
              //                                 Flexible(
              //                                   child: Text(
              //                                     Uri.decodeComponent(friends[index].name),
              //                                     style: const TextStyle(fontFamily: Poppins,),
              //                                   ),
              //                                 )
              //                               ],
              //                             ),
              //                           ],
              //                         ),
              //                       ),
              //                       friends[index].badge["id"] == 0
              //                           ? const SizedBox()
              //                           : Expanded(
              //                         child: ClipRRect(
              //                           borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                           child: CachedNetworkImage(
              //                             imageUrl: friends[index].badge['document'],
              //                             imageBuilder: (context, imageProvider) => Container(
              //                               height: 45,
              //                               width: 45,
              //                               decoration: BoxDecoration(
              //                                 borderRadius: const BorderRadius.all(Radius.circular(120)),
              //                                 image: DecorationImage(
              //                                   image: imageProvider,
              //                                   fit: BoxFit.contain,
              //                                 ),
              //                               ),
              //                             ),
              //                             placeholder: (context, url) => SpinKitCircle(color: primary, size: 20,),
              //                             errorWidget: (context, url, error) => ClipRRect(
              //                               borderRadius: const BorderRadius.all(Radius.circular(50)),
              //                               child: Image.network(
              //                                 friends[index].badge['document'],
              //                                 width: 45,
              //                                 height: 45,
              //                                 fit: BoxFit.contain,
              //                               ),
              //                             ),
              //                           ),
              //                         ),
              //                       ),
              //                     ],
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ),
              //         ),
              //       );
              //     },
              //   ),
              // )),

            ])
    );

  }
}
