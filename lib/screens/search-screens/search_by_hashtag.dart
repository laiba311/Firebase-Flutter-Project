import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:finalfashiontimefrontend/models/hashtagHistory.dart';
import 'package:finalfashiontimefrontend/screens/chats-screens/message_screen.dart';
import 'package:finalfashiontimefrontend/screens/fashionComments/comment_screen.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/post_like_user.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/profiles/myProfile.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/report_screen.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart'as https;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../customize_pacages/mentions/src/mention_text_field.dart';
import '../../helpers/database_methods.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
class SearchByHashtagScreen extends StatefulWidget {
  final Function navigateToReport;
  final Function navigateToUserLike;
  const SearchByHashtagScreen({super.key, required this.navigateToReport, required this.navigateToUserLike});

  @override
  State<SearchByHashtagScreen> createState() => _SearchByHashtagScreenState();
}

class _SearchByHashtagScreenState extends State<SearchByHashtagScreen> {
  bool like = false;
  bool dislike = false;
  bool vote = false;
  String id = "";
  String token = "";
  String name = "";
  List<PostModel> posts = [];
  bool loading = false;
  bool isExpanded = true;
  bool isRefresh = true;
  TextEditingController hashtags=TextEditingController();
  TextEditingController description = TextEditingController();
  bool updateBool = false;
  int _current = 0;
  Stream? chatRooms;
  final CarouselSliderController _controller = CarouselSliderController();
  List<HashtagHistory> searchedHashtags = [];
  VideoPlayerController? controller;
  double? _previousExtent;
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
  String formatHashtags(var hashtags) {
    List<dynamic> formattedHashtags = hashtags.map((tag) => "#${tag['name']}").toList();
    return formattedHashtags.join(' '); // Use ', ' if you prefer commas
  }
  createLike(fashionId) async {

    try {

      Map<String, dynamic> body = {
        "likeEmoji": "1",
        "fashion": fashionId,
        "user": id
      };
      https.post(Uri.parse("$serverUrl/fashionLikes/"),
          body: json.encode(body),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }).then((value) {
        print("Response ==> ${value.body}");
        setState(() {
          Fluttertoast.showToast(msg: "Post liked.", backgroundColor: primary);
        });
      }).catchError((error) {
        setState(() {});
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text(
              "Fashion Time",
              style: TextStyle(
                  color: ascent,
                  fontFamily: Poppins,
                  fontWeight: FontWeight.bold),
            ),
            content: Text(
              error.toString(),
              style: const TextStyle(color: ascent, fontFamily: Poppins,),
            ),
            actions: [
              TextButton(
                child: const Text("Okay",
                    style: TextStyle(color: ascent, fontFamily: Poppins,)),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      });
    } catch (e) {
      setState(() {});
      print(e);
    }
  }
  updatePost(postId) {
    setState(() {
      updateBool = true;
    });
    https
        .patch(Uri.parse("$serverUrl/fashionUpload/$postId/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({"description": description.text}))
        .then((value) {
      print(value.body.toString());
      setState(() {
        updateBool = false;
      });
      Navigator.pop(context);
      getPosts(null);
    });
  }
  getUserInfogetChats() async {
    DatabaseMethods().getUserChats(name).then((snapshots) {
      setState(() {
        chatRooms = snapshots;
        print(
            "we got the data + ${chatRooms.toString()} this is name  $name");
      });
    });


    // get Calls
  }
  saveStyle(fashionId) async {
    setState(() {
      loading = true;
    });
    try {
      setState(() {
        loading = true;
      });
      Map<String, dynamic> body = {
        "fashion": fashionId,
        "user": id,
      };
      https.post(Uri.parse("$serverUrl/fashionSaved/"),
          body: json.encode(body),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }).then((value) {
        print("Response ==> ${value.body}");
        print("Response ==> ${value.statusCode}");
        setState(() {
          loading = false;
        });
        if (value.statusCode == 400) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: primary,
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: const Text(
                "You have already saved this fashion.Do you wish to unsave it?",
                style: TextStyle(color: ascent, fontFamily: Poppins,),
              ),
              actions: [
                TextButton(
                  child: const Text("Yes",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins,)),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                ),
                TextButton(
                  child: const Text("No",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins,)),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                )
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: primary,
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: const Text(
                "Style Saved Successfully.",
                style: TextStyle(color: ascent, fontFamily: Poppins,),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins,)),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            ),
          );
        }

        //controller.swipeTop();
      }).catchError((error) {
        setState(() {
          loading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text(
              "FashionTime",
              style: TextStyle(
                  color: ascent,
                  fontFamily: Poppins,
                  fontWeight: FontWeight.bold),
            ),
            content: Text(
              error.toString(),
              style: const TextStyle(color: ascent, fontFamily: Poppins,),
            ),
            actions: [
              TextButton(
                child: const Text("Okay",
                    style: TextStyle(color: ascent, fontFamily: Poppins,)),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print(e);
    }
  }
  String handleEmojis(String text) {
    List<int> bytes = text.toString().codeUnits;
    return utf8.decode(bytes);
  }
  void _showFriendsList(imageLink,postId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StreamBuilder(
          stream: chatRooms,
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(), // Use your loading indicator
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}",style: TextStyle(fontFamily: Poppins,),), // Handle error
              );
            }
            else if (snapshot.data == null) { // Add null check here
              return const Center(
                child: Text("No data available",style: TextStyle(fontFamily: Poppins,),), // Or display an appropriate message
              );
            }
            else {
              final chatData = snapshot.data.docs;

              return  ListView.builder(
                itemCount: ( chatData.length).toInt(),
                itemBuilder: (context, index) {

                  // Render individual chat tile
                  final individualChatIndex = index ;
                  final chat = chatData[individualChatIndex].data();
                  return ChatRoomsTile(
                    name: name,
                    chatRoomId: chat["chatRoomId"],
                    userData: chat["userData"],
                    friendData: chat["friendData"],
                    isBlocked: chat["isBlock"],
                    postId: postId,
                    share: imageLink,
                  );
                }
                ,
              ) ;
            }
          },
        );
      },
    );
  }
  getPosts(String? hashTag) {
    if(hashTag==null){
      String params="null";
      posts.clear();
      setState(() {
        loading = true;
      });

      try {
        https.get(Uri.parse("$serverUrl/fashionUpload/?hashtag=$params"), headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }).then((value) {
          setState(() {
            loading = false;
          });

          Map<String, dynamic> response = jsonDecode(value.body);
          List<dynamic> results = response["results"];

          for (var result in results) {
            var upload = result["upload"];


            var media = upload != null ? upload["media"] : null;
            if(result['hashtags']!=[]){

              posts.add(PostModel(
                  result["id"].toString(),
                  result["description"],
                  media ?? [],
                  result["user"]["name"],
                  result["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                  false,
                  result["likesCount"].toString(),
                  result["disLikesCount"].toString(),
                  result["commentsCount"].toString(),
                  result["created"],
                  "",
                  result["user"]["id"].toString(),
                  result["myLike"] == null ? "like" : result["myLike"].toString(),
                  {},
                  {},
                  addMeInFashionWeek: result["addMeInWeekFashion"],
                  isCommentEnabled: result["isCommentOff"],
                  hashtags: result['hashtags']));

              debugPrint(
                  "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
              debugPrint("value of isCommentEnabled is ${result["isCommentOff"]} ${posts.length}");
            }
            else{
              posts.add(PostModel(
                  result["id"].toString(),
                  result["description"],
                  media ?? [],
                  result["user"]["name"],
                  result["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                  false,
                  result["likesCount"].toString(),
                  result["disLikesCount"].toString(),
                  result["commentsCount"].toString(),
                  result["created"],
                  "",
                  result["user"]["id"].toString(),
                  result["myLike"] == null ? "like" : result["myLike"].toString(),
                  {},
                  {},
                  addMeInFashionWeek: result["addMeInWeekFashion"],
                  isCommentEnabled: result["isCommentOff"],
                  hashtags: result['hashtags']));

              debugPrint(
                  "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
              debugPrint("value of isCommentEnabled is ${result["isCommentOff"]} ${posts.length}");
            }



          }
        });
      } catch (e) {
        setState(() {
          loading = false;
        });
        print("Error --> $e");
      }
    }
    else{
      String params=hashTag;
      posts.clear();
      setState(() {
        loading = true;
      });

      try {
        https.get(Uri.parse("$serverUrl/fashionUpload/?hashtag=$params"), headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }).then((value) {
          setState(() {
            loading = false;
          });

          Map<String, dynamic> response = jsonDecode(value.body);
          List<dynamic> results = response["results"];
          for (var result in results) {
            var upload = result["upload"];

            var media = upload != null ? upload["media"] : null;
            if(result['hashtags']!=[]){

              posts.add(PostModel(
                  result["id"].toString(),
                  result["description"],
                  media ?? [],
                  result["user"]["name"],
                  result["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                  false,
                  result["likesCount"].toString(),
                  result["disLikesCount"].toString(),
                  result["commentsCount"].toString(),
                  result["created"],
                  "",
                  result["user"]["id"].toString(),
                  result["myLike"] == null ? "like" : result["myLike"].toString(),
                  {},
                  {},
                  addMeInFashionWeek: result["addMeInWeekFashion"],
                  isCommentEnabled: result["isCommentOff"],
                  hashtags: result['hashtags']));

              debugPrint(
                  "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
              debugPrint("value of isCommentEnabled is ${result["isCommentOff"]} ${posts.length}");
            }
            else{
              posts.add(PostModel(
                  result["id"].toString(),
                  result["description"],
                  media ?? [],
                  result["user"]["name"],
                  result["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                  false,
                  result["likesCount"].toString(),
                  result["disLikesCount"].toString(),
                  result["commentsCount"].toString(),
                  result["created"],
                  "",
                  result["user"]["id"].toString(),
                  result["myLike"] == null ? "like" : result["myLike"].toString(),
                  {},
                  {},
                  addMeInFashionWeek: result["addMeInWeekFashion"],
                  isCommentEnabled: result["isCommentOff"],
                  hashtags: result['hashtags']));

              debugPrint(
                  "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
              debugPrint("value of isCommentEnabled is ${result["isCommentOff"]} ${posts.length}");
            }



          }
        });
      } catch (e) {
        setState(() {
          loading = false;
        });
        print("Error --> $e");
      }
    }
    getHashtagHistory();
  }
  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    name = preferences.getString("name")!;
    print(name);
    debugPrint("token in home feed is========>$token");
    getPosts(null);

  }
  getHashtagHistory(){
    searchedHashtags.clear();
    https.get(
      Uri.parse("$serverUrl/apiSearchedHashtags/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).then((value){
      print(value.body.toString());
      var responseData = jsonDecode(value.body);
      responseData.forEach((e){
        setState(() {
          searchedHashtags.add(HashtagHistory(
              e["id"].toString(),
              e["hashtag"],
          ));
        });
      });
    });
  }

  addHashtagHistory(String id,String hashtag){
    print(id);
    https.post(
        Uri.parse("$serverUrl/apiSearchedHashtags/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({
          "hashtagID": id.toString(),
          "hashtag": hashtag,
        })
    ).then((value){
      print("History added");
    });
  }

  removeUserHistory(String id,index){
    print(id);
    https.delete(
        Uri.parse("$serverUrl/apiSearchedHashtags/$id/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      //print("History added");
      setState(() {
        searchedHashtags.removeAt(index);
      });
      getHashtagHistory();
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
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
      //             ])),
      //   ),
      //   title: const Text(
      //     "Search by hashtags",
      //     style: TextStyle(fontFamily: Poppins,),
      //   ),
      // ),
      body: loading?Center(child: SpinKitCircle(color: primary) ,):
          posts.isEmpty||posts.isNotEmpty?
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height*0.02,
                  ),
                  SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        Container(
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width * 0.86,
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
                                        controller: hashtags,
                                        style: const TextStyle(color: ascent,fontFamily: Poppins,),
                                        cursorColor: ascent,
                                        //style: simpleTextStyle(),
                                        decoration: const InputDecoration(
                                            fillColor: ascent,
                                            hintText: "Search for styles",
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
                        IconButton(onPressed: () {
                          addHashtagHistory("xx",hashtags.text);
                          getPosts(hashtags.text);
                        }, icon: const Icon(Icons.search),color: primary,)
                      ],
                    ),
                  ),
                  const SizedBox(height: 20,),
                  Padding(
                    padding: EdgeInsets.only(left:20.0, right: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Recent Hashtags",style: TextStyle(fontFamily: Poppins,),),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10,),
                  SizedBox(
                    height: 40,
                    child: searchedHashtags.isEmpty ? const Center(child: Text("No Searched Hashtags",style: TextStyle(fontFamily: Poppins,),),) : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: searchedHashtags.length,
                        itemBuilder: (context,index){
                          return Padding(
                            padding: const EdgeInsets.only(left:8.0),
                            child: GestureDetector(
                              onTap: (){
                                getPosts(searchedHashtags[index].hashtag);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                                  color: primary,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 20,),
                                    Text(searchedHashtags[index].hashtag,style: const TextStyle(color: Colors.white,fontFamily: Poppins,),),
                                    IconButton(onPressed: (){
                                      removeUserHistory(searchedHashtags[index].id,index);
                                    }, icon: const Icon(Icons.close,color: Colors.white,size: 16,))
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                    ),
                  ),
                  const SizedBox(height: 20,),
                  Expanded(
                    child: ListView.separated(
                        separatorBuilder: (context, index) {
                          if (index % 5 == 0) {

                          }
                          return const SizedBox();
                        },
                        itemCount: posts.length,
                        itemBuilder: (context, index) {

                          return Card(
                            elevation: 10,
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                Container(
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
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10.0,
                                        right: 10,
                                        top: 5,
                                        bottom: 5),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            posts[index].userName == name
                                                ? Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        MyProfileScreen(
                                                          id: posts[
                                                          index]
                                                              .userid,
                                                          username: posts[
                                                          index]
                                                              .userName,
                                                        )))
                                                : Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        FriendProfileScreen(
                                                          id: posts[
                                                          index]
                                                              .userid,
                                                          username: posts[
                                                          index]
                                                              .userName,
                                                        )));
                                          },
                                          child: Padding(
                                            padding:
                                            const EdgeInsets.all(4.0),
                                            child: SizedBox(
                                              width: 150,
                                              child: Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  CircleAvatar(
                                                      backgroundColor:
                                                      dark1,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                        const BorderRadius
                                                            .all(
                                                            Radius
                                                                .circular(
                                                                50)),
                                                        child: posts[index]
                                                            .userPic ==
                                                            null
                                                            ? Image.network(
                                                          "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                          width: 40,
                                                          height: 40,
                                                        )
                                                            : CachedNetworkImage(
                                                          imageUrl: posts[
                                                          index]
                                                              .userPic,
                                                          imageBuilder:
                                                              (context,
                                                              imageProvider) =>
                                                              Container(
                                                                height: MediaQuery.of(context)
                                                                    .size
                                                                    .height *
                                                                    0.7,
                                                                width: MediaQuery.of(
                                                                    context)
                                                                    .size
                                                                    .width,
                                                                decoration:
                                                                BoxDecoration(
                                                                  image:
                                                                  DecorationImage(
                                                                    image:
                                                                    imageProvider,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                                ),
                                                              ),
                                                          placeholder: (context,
                                                              url) =>
                                                              Center(
                                                                  child:
                                                                  SpinKitCircle(
                                                                    color:
                                                                    primary,
                                                                    size: 10,
                                                                  )),
                                                          errorWidget: (context,
                                                              url,
                                                              error) =>
                                                              ClipRRect(
                                                                  borderRadius:
                                                                  const BorderRadius.all(Radius.circular(50)),
                                                                  child: Image.network(
                                                                    "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                    width: 40,
                                                                    height: 40,
                                                                  )),
                                                        ),
                                                      )),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    posts[index].userName,
                                                    style: const TextStyle(
                                                        fontFamily: Poppins,
                                                        color: ascent,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton(
                                            icon: const Icon(
                                              Icons.more_horiz,
                                              color: ascent,
                                            ),
                                            onSelected: (value) {
                                              if (value == 0) {
                                                widget.navigateToReport(28,posts[index].userid);
                                                // Navigator.push(
                                                //     context,
                                                //     MaterialPageRoute(
                                                //         builder: (context) =>
                                                //             ReportScreen(
                                                //                 reportedID:
                                                //                 posts[index]
                                                //                     .userid)));
                                              }
                                              if (value == 1) {
                                                description.text =
                                                    posts[index]
                                                        .description;
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      StatefulBuilder(
                                                          builder: (context,
                                                              setState) {
                                                            updateBool = false;
                                                            return AlertDialog(
                                                              backgroundColor:
                                                              primary,
                                                              title: const Text(
                                                                "Edit Description",
                                                                style: TextStyle(
                                                                    color: ascent,
                                                                    fontFamily: Poppins,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                              ),
                                                              content: SizedBox(
                                                                width:
                                                                MediaQuery.of(
                                                                    context)
                                                                    .size
                                                                    .width,
                                                                child: TextField(
                                                                  maxLines: 5,
                                                                  controller:
                                                                  description,
                                                                  style: const TextStyle(
                                                                      color: ascent,
                                                                    fontFamily: Poppins,),
                                                                  decoration:
                                                                  const InputDecoration(
                                                                      hintStyle: TextStyle(
                                                                          color:
                                                                          ascent,
                                                                          fontSize:
                                                                          17,
                                                                          fontWeight: FontWeight
                                                                              .w400,
                                                                        fontFamily: Poppins,),
                                                                      enabledBorder:
                                                                      UnderlineInputBorder(
                                                                        borderSide:
                                                                        BorderSide(color: ascent),
                                                                      ),
                                                                      focusedBorder:
                                                                      UnderlineInputBorder(
                                                                        borderSide:
                                                                        BorderSide(color: ascent),
                                                                      ),
                                                                      //enabledBorder: InputBorder.none,
                                                                      errorBorder:
                                                                      InputBorder
                                                                          .none,
                                                                      //disabledBorder: InputBorder.none,
                                                                      alignLabelWithHint:
                                                                      true,
                                                                      hintText:
                                                                      "Description "),
                                                                  cursorColor:
                                                                  Colors.pink,
                                                                ),
                                                              ),
                                                              actions: [
                                                                updateBool == true
                                                                    ? const SpinKitCircle(
                                                                  color:
                                                                  ascent,
                                                                  size: 20,
                                                                )
                                                                    : TextButton(
                                                                  child: const Text(
                                                                      "Save",
                                                                      style: TextStyle(
                                                                          color:
                                                                          ascent,
                                                                        fontFamily: Poppins,)),
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                            () {
                                                                          updateBool =
                                                                          true;
                                                                        });
                                                                    updatePost(
                                                                        posts[index]
                                                                            .id);
                                                                  },
                                                                ),
                                                              ],
                                                            );
                                                          }),
                                                );
                                              }
                                              if (value == 2) {
                                                saveStyle(posts[index].id);
                                              }
                                              print(value);
                                              //Navigator.pushNamed(context, value.toString());
                                            },
                                            itemBuilder: (BuildContext bc) {
                                              return [
                                                PopupMenuItem(
                                                  value: 0,
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.report),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        "Report",
                                                        style: TextStyle(
                                                          fontFamily: Poppins,),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (posts[index].userid ==
                                                    id)
                                                  PopupMenuItem(
                                                    value: 1,
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit),
                                                        SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          "Edit Description",
                                                          style: TextStyle(
                                                            fontFamily: Poppins,),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                // if (posts[index].userid !=
                                                //     id)
                                                //   PopupMenuItem(
                                                //     value: 2,
                                                //     child: Row(
                                                //       children: const [
                                                //         Icon(Icons.save),
                                                //         SizedBox(
                                                //           width: 10,
                                                //         ),
                                                //         Text(
                                                //           "Save Post",
                                                //           style: TextStyle(
                                                //               fontFamily:
                                                //                   Poppins),
                                                //         ),
                                                //       ],
                                                //     ),
                                                //   ),
                                              ];
                                            })
                                      ],
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                      },
                                      child: InteractiveViewer(
                                        panEnabled: true,
                                        minScale: 1,
                                        maxScale: 3,
                                        child: SizedBox(
                                          height: 450,
                                          width: MediaQuery.of(context)
                                              .size
                                              .width *
                                              0.97,
                                          child: CarouselSlider(
                                            carouselController: _controller,
                                            options: CarouselOptions(
                                                enableInfiniteScroll: false,
                                                height: 450.0,
                                                autoPlay: false,
                                                enlargeCenterPage: true,
                                                viewportFraction: 0.99,
                                                aspectRatio: 2.0,
                                                initialPage: 0,
                                                onPageChanged:
                                                    (ind, reason) {
                                                  setState(() {
                                                    _current = ind;
                                                  });
                                                }),
                                            items: posts[index]
                                                .images
                                                .map((i) {
                                                 if(i["type"] == "video") {
                                                   controller = VideoPlayerController
                                                       .network(
                                                       '${i["video"]}')
                                                     ..initialize().then((
                                                         _) {});
                                                   controller!.play();
                                                 }
                                              return i["type"] == "video"
                                                  ? Container(
                                                  color: Colors.black,
                                                  child:
                                                  VideoPlayer(controller!)
                                                 )
                                                  : InteractiveViewer(
                                                panEnabled: true,
                                                minScale: 1,
                                                maxScale: 3,
                                                child: Builder(
                                                  builder:
                                                      (BuildContext
                                                  context) {
                                                    return CachedNetworkImage(
                                                      imageUrl:
                                                      i["image"],
                                                      imageBuilder:
                                                          (context,
                                                          imageProvider) =>
                                                          Container(
                                                            height: MediaQuery.of(
                                                                context)
                                                                .size
                                                                .height,
                                                            width: MediaQuery.of(
                                                                context)
                                                                .size
                                                                .width,
                                                            decoration:
                                                            BoxDecoration(
                                                              image:
                                                              DecorationImage(
                                                                image:
                                                                imageProvider,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                          ),
                                                      placeholder: (context,
                                                          url) =>
                                                          SpinKitCircle(
                                                            color:
                                                            primary,
                                                            size: 60,
                                                          ),
                                                      errorWidget: (context,
                                                          url,
                                                          error) =>
                                                          Container(
                                                            height: MediaQuery.of(
                                                                context)
                                                                .size
                                                                .height *
                                                                0.9,
                                                            width: MediaQuery.of(
                                                                context)
                                                                .size
                                                                .width,
                                                            decoration:
                                                            BoxDecoration(
                                                              image: DecorationImage(
                                                                  image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                                                                      .image,
                                                                  fit: BoxFit
                                                                      .fill),
                                                            ),
                                                          ),
                                                    );
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                posts[index].images.length == 1
                                    ? const SizedBox()
                                    : Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: posts[index]
                                      .images
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    return GestureDetector(
                                      onTap: () => _controller
                                          .animateToPage(entry.key),
                                      child: Container(
                                        width: 12.0,
                                        height: 12.0,
                                        margin: const EdgeInsets
                                            .symmetric(
                                            vertical: 8.0,
                                            horizontal: 4.0),
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: (Theme.of(context)
                                                .brightness ==
                                                Brightness
                                                    .dark
                                                ? Colors.white
                                                : Colors.black)
                                                .withOpacity(
                                                _current ==
                                                    entry.key
                                                    ? 0.9
                                                    : 0.4)),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                // const Divider(
                                //   height: 2,
                                //   thickness: 2,
                                // ),
                                Padding(
                                    padding: const EdgeInsets.only(
                                        left: 0.0, right: 0.0),
                                    child: posts[index].userid == id
                                        ? Row(
                                      children: [
                                        posts[index].addMeInFashionWeek ==
                                            true
                                            ? posts[index].mylike !=
                                            "like"
                                            ? IconButton(
                                            onPressed: () {},
                                            icon: const Icon(
                                              Icons.favorite,
                                              size: 20,

                                            ))
                                            : IconButton(
                                            onPressed: () {
                                              widget.navigateToUserLike(29,posts[index].id);
                                              // Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //       builder:
                                              //           (context) =>
                                              //           PostLikeUserScreen(fashionId: posts[index].id),
                                              //     ));
                                            },
                                            icon: const Icon(
                                              FontAwesomeIcons
                                                  .heart,
                                              color: Colors.red,
                                              size: 20,
                                            ))
                                            : posts[index].mylike !=
                                            "like"
                                            ? GestureDetector(
                                            onTap: () {
                                              widget.navigateToUserLike(29,posts[index].id);
                                              // Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //       builder:
                                              //           (context) =>
                                              //           PostLikeUserScreen(fashionId: posts[index].id),
                                              //     ));
                                            },
                                            child: const Icon(
                                              Icons.star,
                                              color: Colors
                                                  .orange,
                                              size: 24,
                                            ))
                                            : GestureDetector(
                                          onDoubleTap:
                                              () {},
                                          onTap: () {
                                            widget.navigateToUserLike(29,posts[index].id);
                                            // Navigator.push(
                                            //     context,
                                            //     MaterialPageRoute(
                                            //       builder:
                                            //           (context) =>
                                            //           PostLikeUserScreen(fashionId: posts[index].id),
                                            //     ));
                                          },
                                          child:
                                          Padding(
                                            padding:
                                            EdgeInsets
                                                .all(
                                                8.0),
                                            child: Icon(
                                                Icons
                                                    .star_border_outlined,
                                                size: 24,
                                                color: Colors
                                                    .orange),
                                          ),
                                        )
                                        // IconButton(
                                        //             onPressed: () {
                                        //             },
                                        //
                                        //             icon: const Icon(
                                        //               Icons
                                        //                   .star_border_outlined,
                                        //               color: Colors.orange,
                                        //               size: 24,
                                        //             ))
                                        ,
                                        posts[index].likeCount == "0"
                                            ?
                                        // Text(
                                        //         "N/A",
                                        //         style: TextStyle(
                                        //             fontFamily:
                                        //                 Poppins,
                                        //             fontSize: 12,
                                        //             color: primary),
                                        //       )
                                        const SizedBox()
                                            : Text(posts[index]
                                            .likeCount,style: TextStyle(fontFamily: Poppins,),),
                                        posts[index].isCommentEnabled ==
                                            true
                                            ? IconButton(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.only(
                                                          topLeft: Radius.circular(10),
                                                          topRight: Radius.circular(10)
                                                      )
                                                  ),
                                                  isScrollControlled: true,
                                                  context: context,
                                                  builder: (ctx) {
                                                    return WillPopScope(
                                                      onWillPop: () async {
                                                        print("Closed 3");
                                                        if(overlayEntry != null) {
                                                          showSuggestions = ValueNotifier(false);
                                                          overlayEntry!.remove();
                                                          overlayEntry = null;
                                                        }else{
                                                          Navigator.pop(ctx);
                                                        }
                                                        return false; // Prevents the default back button behavior
                                                      },
                                                      child: NotificationListener<DraggableScrollableNotification>(
                                                        onNotification: (notification) {
                                                          print("listener called");
                                                          // Detect ANY movement (no threshold)
                                                          if (_previousExtent != notification.extent && keyBoardOpen == true) {
                                                            print("Sheet is being dragged (${notification.extent})");
                                                            print("bool => ${keyBoardOpen}");
                                                            focusNode1.unfocus();
                                                            //Navigator.pop(ctx);
                                                            _previousExtent = notification.extent;
                                                          }
                                                          return false;
                                                        },
                                                        child: DraggableScrollableSheet(
                                                            expand: false, // Ensures it doesn't expand fully by default
                                                            initialChildSize: 0.7, // Half screen by default
                                                            minChildSize: 0.3, // Minimum height
                                                            maxChildSize: 1.0,
                                                            builder: (BuildContext context, ScrollController scrollController) {
                                                              return CommentScreen(
                                                                postid: posts[index].id,
                                                                pic: posts[index].userPic,
                                                                scrollController: scrollController,
                                                                  isEventPost: posts[index].addMeInFashionWeek!,
                                                                  userID: posts[index].userid
                                                              );
                                                            }
                                                        ),
                                                      ),
                                                    );
                                                  });
                                            },
                                            icon: const Icon(
                                              FontAwesomeIcons
                                                  .comment,
                                              size: 20,
                                            ))
                                            : const SizedBox(),
                                        IconButton(
                                            onPressed: () async {

                                              showModalBottomSheet(
                                                  context: context,
                                                  builder: (BuildContext bc) {
                                                    return Wrap(
                                                      children: <Widget>[
                                                        ListTile(
                                                          leading:  SizedBox(
                                                              width: 28,
                                                              height:28 ,
                                                              child: Image.asset("assets/shareIcon.png",)),
                                                          title: const Text(
                                                            'Share with friends',
                                                            style: TextStyle(fontFamily: Poppins,),
                                                          ),
                                                          onTap: () {
                                                            String imageUrl = posts[index].images[0]['image']==null?posts[index].images[0]['video'].toString():posts[index].images[0]['image'].toString();
                                                            Navigator.pop(context);
                                                            _showFriendsList(imageUrl,posts[index].id);

                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: const Icon(Icons.share),
                                                          title: const Text(
                                                            'Others',
                                                            style: TextStyle(fontFamily: Poppins,),
                                                          ),
                                                          onTap: () async{
                                                            String imageUrl = posts[index].images[0]['image']==null?posts[index].images[0]['video'].toString():posts[index].images[0]['image'].toString();
                                                            debugPrint("image link to share: $imageUrl");
                                                            await Share.share("${posts[index].description.toString()}\n\n https://fashiontime-28e3a.web.app/details/${posts[index].id}"
                                                            );
                                                          },
                                                        ),

                                                      ],
                                                    );
                                                  });
                                            },
                                            icon: const Icon(
                                              FontAwesomeIcons.share,
                                              size: 20,
                                            )
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                            onTap: () {
                                              saveStyle(posts[index].id);
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.only(right: 2),
                                              child: Icon(Icons.save),
                                            ))


                                        // Padding(
                                        //     padding:  EdgeInsets.only(
                                        //         left:
                                        //         posts[index].isCommentEnabled==true?
                                        //         MediaQuery.of(context).size.width*0.35: MediaQuery.of(context).size.width*0.5),
                                        //     child: Text(
                                        //       // DateFormat.yMMMEd().format(
                                        //       //     DateTime.parse(
                                        //       //         posts[index].date)),
                                        //       formatTimeDifference(posts[index].date),
                                        //       style: const TextStyle(
                                        //           fontFamily: Poppins,
                                        //           fontSize: 12),
                                        //     )),
                                      ],
                                    )
                                        : Row(
                                      children: [
                                        posts[index].addMeInFashionWeek ==
                                            true
                                            ? posts[index].mylike !=
                                            "like"
                                            ? IconButton(
                                            onPressed: () {
                                              widget.navigateToUserLike(29,posts[index].id);
                                              // Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //       builder:
                                              //           (context) =>
                                              //           PostLikeUserScreen(fashionId: posts[index].id),
                                              //     ));
                                            },
                                            icon: const Icon(
                                              Icons.favorite,
                                              size: 20,
                                              color: Colors.red,
                                            ))
                                            : IconButton(
                                            onPressed: () {
                                              widget.navigateToUserLike(29,posts[index].id);
                                              // Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //       builder:
                                              //           (context) =>
                                              //           PostLikeUserScreen(fashionId: posts[index].id),
                                              //     ));
                                            },
                                            icon: const Icon(
                                              FontAwesomeIcons
                                                  .heart,
                                              size: 20,
                                              color: Colors.red,
                                            ))
                                            : posts[index].mylike !=
                                            "like"
                                            ? GestureDetector(
                                            onTap: () {
                                              widget.navigateToUserLike(29,posts[index].id);
                                              // Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //       builder:
                                              //           (context) =>
                                              //           PostLikeUserScreen(fashionId: posts[index].id),
                                              //     ));
                                            },
                                            child:
                                            Padding(
                                              padding: EdgeInsets
                                                  .only(
                                                  left:
                                                  4),
                                              child: Icon(
                                                Icons.star,
                                                color: Colors
                                                    .orange,
                                                size: 24,
                                              ),
                                            ))
                                            : GestureDetector(
                                          onDoubleTap: () {
                                            createLike(
                                                posts[index]
                                                    .id);
                                          },
                                          onTap: () {
                                            debugPrint(
                                                "pressed");
                                            widget.navigateToUserLike(29,posts[index].id);
                                            // Navigator.push(
                                            //     context,
                                            //     MaterialPageRoute(
                                            //       builder:
                                            //           (context) =>
                                            //           PostLikeUserScreen(fashionId: posts[index].id),
                                            //     ));
                                          },
                                          child:
                                          Padding(
                                            padding:
                                            EdgeInsets
                                                .all(
                                                8.0),
                                            child: Icon(
                                              Icons
                                                  .star_border_outlined,
                                              color: Colors
                                                  .orange,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        posts[index].likeCount == "0"
                                            ?
                                        // Text(
                                        //   "N/A",
                                        //   style: TextStyle(
                                        //       fontFamily:
                                        //       Poppins,
                                        //       fontSize: 12,
                                        //       color: primary),
                                        // )
                                        const SizedBox()
                                            :
                                        Text(posts[index]
                                            .likeCount,style: TextStyle(fontFamily: Poppins,),),
                                        posts[index].isCommentEnabled ==
                                            true
                                            ? IconButton(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.only(
                                                          topLeft: Radius.circular(10),
                                                          topRight: Radius.circular(10)
                                                      )
                                                  ),
                                                  isScrollControlled: true,
                                                  context: context,
                                                  builder: (ctx) {
                                                    return WillPopScope(
                                                      onWillPop: () async {
                                                        print("Closed 3");
                                                        if(overlayEntry != null) {
                                                          showSuggestions = ValueNotifier(false);
                                                          overlayEntry!.remove();
                                                          overlayEntry = null;
                                                        }else{
                                                          Navigator.pop(ctx);
                                                        }
                                                        return false; // Prevents the default back button behavior
                                                      },
                                                      child: NotificationListener<DraggableScrollableNotification>(
                                                        onNotification: (notification) {
                                                          print("listener called");
                                                          // Detect ANY movement (no threshold)
                                                          if (_previousExtent != notification.extent && keyBoardOpen == true) {
                                                            print("Sheet is being dragged (${notification.extent})");
                                                            print("bool => ${keyBoardOpen}");
                                                            focusNode1.unfocus();
                                                            //Navigator.pop(ctx);
                                                            _previousExtent = notification.extent;
                                                          }
                                                          return false;
                                                        },
                                                        child: DraggableScrollableSheet(
                                                            expand: false, // Ensures it doesn't expand fully by default
                                                            initialChildSize: 0.7, // Half screen by default
                                                            minChildSize: 0.3, // Minimum height
                                                            maxChildSize: 1.0,
                                                            builder: (BuildContext context, ScrollController scrollController) {
                                                              return CommentScreen(
                                                                postid: posts[index].id,
                                                                pic: posts[index].userPic,
                                                                scrollController: scrollController,
                                                                  isEventPost: posts[index].addMeInFashionWeek!,
                                                                  userID: posts[index].userid
                                                              );
                                                            }
                                                        ),
                                                      ),
                                                    );
                                                  });
                                            },
                                            icon: const Icon(
                                              FontAwesomeIcons
                                                  .comment,
                                              size: 20,
                                            ))
                                            : const SizedBox(),
                                        IconButton(
                                            onPressed: () async {

                                              showModalBottomSheet(
                                                  context: context,
                                                  builder: (BuildContext bc) {
                                                    return Wrap(
                                                      children: <Widget>[
                                                        ListTile(
                                                          leading: SizedBox(
                                                              width: 28,
                                                              height:28 ,
                                                              child: Image.asset("assets/shareIcon.png",)),
                                                          title: const Text(
                                                            'Share with friends',
                                                            style: TextStyle(fontFamily: Poppins,),
                                                          ),
                                                          onTap: () {
                                                            String imageUrl = posts[index].images[0]['image']==null?posts[index].images[0]['video'].toString():posts[index].images[0]['image'].toString();
                                                            Navigator.pop(context);
                                                            _showFriendsList(imageUrl,posts[index].id);

                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: const Icon(Icons.share),
                                                          title: const Text(
                                                            'Others',
                                                            style: TextStyle(fontFamily: Poppins,),
                                                          ),
                                                          onTap: () async{
                                                            String imageUrl = posts[index].images[0]['image']==null?posts[index].images[0]['video'].toString():posts[index].images[0]['image'].toString();
                                                            debugPrint("image link to share: $imageUrl");
                                                            await Share.share("${posts[index].description.toString()}\n\n https://fashiontime-28e3a.web.app/details/${posts[index].id}"
                                                            );
                                                          },
                                                        ),

                                                      ],
                                                    );
                                                  });
                                            },
                                            icon: const Icon(
                                              FontAwesomeIcons.share,
                                              size: 20,
                                            )
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                            onTap: () {
                                              saveStyle(posts[index].id);
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.only(right: 2),
                                              child: Icon(Icons.save),
                                            ))
                                        // Padding(
                                        //     padding:  EdgeInsets.only(
                                        //         left: MediaQuery.of(context).size.width*0.3),
                                        //     child: Text(
                                        //       // DateFormat.yMMMEd().format(
                                        //       //     DateTime.parse(
                                        //       //         posts[index].date)),
                                        //       formatTimeDifference(posts[index].date),
                                        //       style: const TextStyle(
                                        //           fontFamily: Poppins,
                                        //           fontSize: 12),
                                        //     )),
                                      ],
                                    )
                                ),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    posts[index]
                                        .description
                                        .toString()
                                        .length +formatHashtags(posts[index].hashtags).length>
                                        40
                                        ? Expanded(
                                      child: Padding(
                                          padding:
                                          const EdgeInsets.all(
                                              8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            children: [
                                              isExpanded
                                                  ? Row(
                                                children: [
                                                  Text(
                                                    posts[index]
                                                        .userName,
                                                    style: const TextStyle(
                                                        fontFamily: Poppins,
                                                        fontSize:
                                                        12,
                                                        fontWeight:
                                                        FontWeight.bold),
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Text(
                                                    "${handleEmojis(posts[index].description.substring(0, 7))}...",
                                                    style:
                                                    const TextStyle(
                                                      fontFamily: Poppins,
                                                      fontSize:
                                                      12,
                                                    ),
                                                    textAlign:
                                                    TextAlign
                                                        .start,
                                                  )
                                                ],
                                              )
                                                  : Text(
                                                  "${posts[index]
                                                      .userName}${handleEmojis( posts[index]
                                                      .description)} ${formatHashtags(posts[index].hashtags)}",
                                                  style: const TextStyle(
                                                      fontFamily: Poppins,
                                                      fontSize:
                                                      12)),
                                              TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      isExpanded =
                                                      !isExpanded;
                                                    });
                                                  },
                                                  child: Text(
                                                      isExpanded
                                                          ? "Show More"
                                                          : "Show Less",
                                                      style: TextStyle(
                                                          color: Theme.of(
                                                              context)
                                                              .primaryColor,fontFamily: Poppins,),)),
                                            ],
                                          )),
                                    )
                                        : Padding(
                                        padding:
                                        const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  posts[index].userName,
                                                  style: const TextStyle(
                                                      fontFamily: Poppins,
                                                      fontSize: 12,
                                                      fontWeight:
                                                      FontWeight
                                                          .bold),
                                                ),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                Text(
                                                  "${handleEmojis( posts[index]
                                                      .description)} ${formatHashtags(posts[index].hashtags)}",//hashtagwork
                                                  style: const TextStyle(
                                                      fontFamily: Poppins,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height:
                                              MediaQuery.of(context)
                                                  .size
                                                  .height *
                                                  0.01,
                                            ),
                                            Align(
                                              alignment:
                                              Alignment.topLeft,
                                              child: Text(
                                                // DateFormat.yMMMEd().format(
                                                //     DateTime.parse(
                                                //         posts[index].date)),
                                                formatTimeDifference(
                                                    posts[index].date),
                                                style: const TextStyle(
                                                    fontFamily: Poppins,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        )),
                                    const SizedBox(
                                      width: 10,
                                    )
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                  ),
                ],
              )
    :const SizedBox());

  }

}
class ChatRoomsTile extends StatelessWidget {
  final String? name;
  final String? chatRoomId;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> friendData;
  final bool isBlocked;
  final String share;
  final String postId;

  const ChatRoomsTile({super.key, 
    this.name,
    this.chatRoomId,
    required this.userData,
    required this.friendData,
    required this.isBlocked, required this.share, required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MessageScreen(
                  friendId: friendData["id"],
                  chatRoomId: chatRoomId!,
                  email: (chatRoomId!.split("_")[0] == name)
                      ? friendData["username"]
                      : (chatRoomId!.split("_")[1] == name
                      ? userData["username"]
                      : ""),
                  name: (chatRoomId!.split("_")[0] == name)
                      ? friendData["name"]
                      : (chatRoomId!.split("_")[1] == name
                      ? userData["name"]
                      : ""),
                  pic: (chatRoomId!.split("_")[0] == name)
                      ? friendData["pic"]
                      : (chatRoomId!.split("_")[1] == name
                      ? userData["pic"]
                      : ""),
                  fcm: (chatRoomId!.split("_")[0] == name)
                      ? friendData["token"]
                      : (chatRoomId!.split("_")[1] == name
                      ? userData["token"]
                      : ""),
                  isBlocked: isBlocked,
                  share: share,
                  postId: postId,)));
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Card(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15))),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          // Navigator.push(context,MaterialPageRoute(builder: (context) => FriendProfileScreen(
                          //   id: posts[index].userid,
                          //   username: friendData["username"],
                          // )));
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                              borderRadius:
                              BorderRadius.all(Radius.circular(120))),
                          child: ClipRRect(
                            borderRadius:
                            const BorderRadius.all(Radius.circular(120)),
                            child: CachedNetworkImage(
                              imageUrl: (chatRoomId!.split("_")[0] == name)
                                  ? friendData["pic"]
                                  : (chatRoomId!.split("_")[1] == name
                                  ? userData["pic"]
                                  : ""),
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(120)),
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              placeholder: (context, url) => SpinKitCircle(
                                color: primary,
                                size: 20,
                              ),
                              errorWidget: (context, url, error) => ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(50)),
                                  child: Image.network(
                                    "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                    width: 50,
                                    height: 50,
                                  )),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                (chatRoomId!.split("_")[0] == name)
                                    ? friendData["name"]
                                    : (chatRoomId!.split("_")[1] == name
                                    ? userData["name"]
                                    : ""),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold,fontFamily: Poppins,),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Text(
                                (chatRoomId!.split("_")[0] == name)
                                    ? friendData["username"]
                                    : (chatRoomId!.split("_")[1] == name
                                    ? userData["username"]
                                    : ""),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500,fontFamily: Poppins,),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}