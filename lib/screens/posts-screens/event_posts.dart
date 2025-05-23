import 'dart:convert';
import 'package:carousel_slider/carousel_controller.dart' as carousel_controller;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:finalfashiontimefrontend/customize_pacages/mentions/src/mention_text_field.dart';
import 'package:finalfashiontimefrontend/models/post_model.dart';
import 'package:finalfashiontimefrontend/models/user_model.dart';
import 'package:finalfashiontimefrontend/screens/fashionComments/comment_screen.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/post_like_user.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/profiles/myProfile.dart';
import 'package:finalfashiontimefrontend/screens/search-screens/search_by_hashtag.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/report_screen.dart';
import 'package:finalfashiontimefrontend/screens/stories/view_story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import '../../../models/story_model.dart';
import '../../../utils/constants.dart';

class EventPosts extends StatefulWidget {
  final String userid;
  const EventPosts({super.key, required this.userid});

  @override
  State<EventPosts> createState() => _EventPostsState();
}

class _EventPostsState extends State<EventPosts> {
  String id = "";
  String token = "";
  String name = "";
  String pic = "";
  List<PostModel> posts = [];
  bool loading = false;
  TextEditingController description = TextEditingController();
  bool updateBool = false;
  List<String> genders = ['Male', 'Female','Unisex', 'Other'];
  String gender = "";
  int genderIndex = 0;
  Stream? chatRooms;
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();
  bool isExpanded = true;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController = ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final ScrollOffsetListener scrollOffsetListener = ScrollOffsetListener.create();
  double? _previousExtent;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    name = preferences.getString("name")!;
    pic = preferences.getString("pic")!;
    print(name);
    getPosts();
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
    } else if (difference.inDays <= 6) {
      if (difference.inDays == 1) {
        return '1 day ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } else {
      // Format the date
      String day = createdAt.day.toString();
      String month = _getMonthName(createdAt.month);
      if (createdAt.year != now.year) {
        return '$day $month ${createdAt.year}';
      } else {
        return '$day $month';
      }
    }
  }

// Helper function to get the month name
  String _getMonthName(int month) {
    const List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
  getPosts() {
    posts.clear();
    setState(() {
      loading = true;
    });

    try {
      https.get(Uri.parse("$serverUrl/fashionUpload/my-fashions/?id=${widget.userid}"), headers: {
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
          // if(response["next"]==null){
          //   paginationPost=0;
          // }

          var media = upload != null ? upload["media"] : null;
          if(result['hashtags']!=[]){

            posts.add(PostModel(
                result["id"].toString(),
                result["description"],
                media ?? [],
                result["user"]["username"],
                result["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                false,
                result["likesCount"].toString(),
                result["disLikesCount"].toString(),
                result["commentsCount"].toString(),
                result["created"],
                result["gender"],
                result["user"]["id"].toString(),
                result["myLike"] == null ? "like" : result["myLike"].toString(),
                result["eventData"],
                result["topBadge"] ?? {"badge":null},
                addMeInFashionWeek: result["addMeInWeekFashion"],
                isCommentEnabled: result["isCommentOff"],
                isLikeEnabled: result["isLikeOff"],
                hashtags: result['hashtags'],
                recent_stories: result['recent_stories'].length > 0 ? List<Story>.from(result['recent_stories'].map((e1){
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
                show_stories_to_non_friends: result['user']['show_stories_to_non_friends'],
                fanList: result["fansList"],
                followList: result["user"]["followList"],
                close_friends: result["close_friends"]
            ));
            //print("Posts ==> ${posts.length} ${result[]}");

            debugPrint(
                "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
            debugPrint("value of isCommentEnabled is ${result["isCommentOff"]} ${posts.length}");
          }
          else{
            posts.add(PostModel(
                result["id"].toString(),
                result["description"],
                media ?? [],
                result["user"]["username"],
                result["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                false,
                result["likesCount"].toString(),
                result["disLikesCount"].toString(),
                result["commentsCount"].toString(),
                result["created"],
                result["gender"],
                result["user"]["id"].toString(),
                result["myLike"] == null ? "like" : result["myLike"].toString(),
                result["eventData"],
                result["topBadge"] ?? {"badge":null},
                addMeInFashionWeek: result["addMeInWeekFashion"],
                isCommentEnabled: result["isCommentOff"],
                isLikeEnabled: result["isLikeOff"],
                hashtags: result['hashtags'],
                recent_stories: result['recent_stories'].length > 0 ? List<Story>.from(result['recent_stories'].map((e1){
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
                show_stories_to_non_friends: result['user']['show_stories_to_non_friends'],
                fanList: result["fansList"],
                followList: result["user"]["followList"],
                close_friends: result["close_friends"]
            ));
            //print("Posts ==> ${posts.length} ${result}");
            debugPrint(
                "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
            debugPrint("value of isCommentEnabled is ${result["isCommentOff"]} ${posts.length}");
          }
          //print("Posts ==> ${posts.length} ${posts}");
        }
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
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
          Fluttertoast.showToast(msg: "Post liked.", backgroundColor: primary,);
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
  updatePost(postId,index) {
    print("enrer discription ${postId}");
    https
        .patch(Uri.parse("$serverUrl/fashionUpload/$postId/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({"description": description.text}))
        .then((value) {
      print("Description update ==> ${json.decode(value.body)["error"].toString()}");
      //Fluttertoast.showToast(msg: "Description update ==> ${value.body.toString()}", backgroundColor: primary);
      setState(() {
        updateBool = false;
      });

      if(value.statusCode.toString() == "400") {
        showDialog(context: context, builder: (context) => AlertDialog(
          title: Text("Alert"),
          content: Text("${json.decode(value.body)["error"].toString()}"),
        ));
      }
      else{
        setState(() {
          posts[index].description = description.text;
        });
        Navigator.pop(context);
        //getPostsToScroll(1,index);
        // getPosts(paginationPost);
        // itemScrollController.scrollTo(
        //     index: index,
        //     duration: Duration(seconds: 2),
        //     curve: Curves.easeInOutCubic);
      }
    }).catchError((e){
      setState(() {
        updateBool = false;
      });
      showDialog(context: context, builder: (context) => AlertDialog(
        title: Text("enrer discription ${e}"),
      ));
      print("enrer discription ${e}");
    });
  }
  updateGender(postId,index) {
    //print("error gender ${postId}");
    https
        .patch(Uri.parse("$serverUrl/fashionUpload/$postId/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({"gender": genders[genderIndex]}))
        .then((value) {
      print("gender update ==> ${json.decode(value.body).toString()}");
      if(value.statusCode.toString() == "400") {
        showDialog(context: context, builder: (context) => AlertDialog(
          title: Text("Alert"),
          content: Text("${json.decode(value.body)["error"].toString()}"),
        ));
      }
      else{
        setState(() {
          updateBool = false;
          posts[index].thumbnail = genders[genderIndex];
        });
        Navigator.pop(context);
      }
    }).catchError((e){
      setState(() {
        updateBool = false;
      });
      showDialog(context: context, builder: (context) => AlertDialog(
        title: Text("errer gender ${e}"),
      ));
      print("enrer gender ${e}");
    });
  }
  updateComments(postId,index,bool commentBool) {
    print("called");
    setState(() {
      updateBool = true;
    });
    print("enrer comment disabled  ${postId}");
    https
        .patch(Uri.parse("$serverUrl/fashionUpload/$postId/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({"isCommentOff": !commentBool}))
        .then((value) {
      //print("comment status update ==> ${json.decode(value.body)["error"].toString()}");
      //Fluttertoast.showToast(msg: "Description update ==> ${value.body.toString()}", backgroundColor: primary);

      if(value.statusCode.toString() == "400") {
        setState(() {
          updateBool = false;
        });
        showDialog(context: context, builder: (context) => AlertDialog(
          title: Text("Alert"),
          content: Text("${json.decode(value.body)["error"].toString()}"),
        ));
      }
      else{
        setState(() {
          posts[index].isCommentEnabled = !commentBool;
          updateBool = false;
        });
        showDialog(context: context, builder: (context) => AlertDialog(
          title: Text("Alert"),
          content: commentBool == false ? Text("Comments enabled"): Text("Comments disabled") ,
        ));
      }
    }).catchError((e){
      setState(() {
        updateBool = false;
      });
    });
  }
  updateLikes(postId,index,bool commentBool) {
    print("called");
    setState(() {
      updateBool = true;
    });
    print("enter like disabled  ${postId}");
    https
        .patch(Uri.parse("$serverUrl/fashionUpload/$postId/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({"isLikeOff": !commentBool}))
        .then((value) {
      //print("comment status update ==> ${json.decode(value.body)["error"].toString()}");
      //Fluttertoast.showToast(msg: "Description update ==> ${value.body.toString()}", backgroundColor: primary);

      if(value.statusCode.toString() == "400") {
        setState(() {
          updateBool = false;
        });
        showDialog(context: context, builder: (context) => AlertDialog(
          title: Text("Alert"),
          content: Text("${json.decode(value.body)["error"].toString()}"),
        ));
      }
      else{
        setState(() {
          posts[index].isLikeEnabled = !commentBool;
          updateBool = false;
        });
        showDialog(context: context, builder: (context) => AlertDialog(
          title: Text("Alert"),
          content: commentBool == false ? Text("Likes enabled"): Text("Likes disabled") ,
        ));
      }
    }).catchError((e){
      setState(() {
        updateBool = false;
      });
    });
  }
  void _showFriendsList(imageLink,postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Ensure it can be dragged
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false, // Ensures it doesn't expand fully by default
          initialChildSize: 0.5, // Half screen by default
          minChildSize: 0.3, // Minimum height
          maxChildSize: 1.0, // Full screen when dragged up
          builder: (BuildContext context, ScrollController scrollController) {
            return StreamBuilder(
              stream: chatRooms,
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(), // Use your loading indicator
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}",
                        style: TextStyle(fontFamily: Poppins)),
                  );
                } else if (snapshot.data == null) {
                  return const Center(
                    child: Text("No data available",
                        style: TextStyle(fontFamily: Poppins)),
                  );
                } else {
                  final chatData = snapshot.data.docs;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          PopupMenuButton(
                              icon: const Icon(Icons.tune,color: Colors.transparent,),
                              onSelected: null,
                              itemBuilder: (BuildContext bc) {
                                return [
                                ];
                              }),
                          Text("Friends List",style: TextStyle(color: ascent,fontSize: 13,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                          PopupMenuButton(
                              icon: const Icon(Icons.tune,color: Colors.transparent,),
                              onSelected: null,
                              itemBuilder: (BuildContext bc) {
                                return [
                                ];
                              }),
                        ],
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController, // Provide scroll controller here
                          itemCount: chatData.length,
                          itemBuilder: (context, index) {
                            final individualChatIndex = index;
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
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            );
          },
        );
      },
    );
    // showModalBottomSheet(
    //   context: context,
    //   builder: (BuildContext bc) {
    //     return StreamBuilder(
    //       stream: chatRooms,
    //       builder: (context, AsyncSnapshot snapshot) {
    //         if (snapshot.connectionState == ConnectionState.waiting) {
    //           return const Center(
    //             child: CircularProgressIndicator(), // Use your loading indicator
    //           );
    //         } else if (snapshot.hasError) {
    //           return Center(
    //             child: Text("Error: ${snapshot.error}",style: TextStyle(fontFamily: Poppins,),), // Handle error
    //           );
    //         }
    //         else if (snapshot.data == null) { // Add null check here
    //           return const Center(
    //             child: Text("No data available",style: TextStyle(fontFamily: Poppins,),), // Or display an appropriate message
    //           );
    //         }
    //         else {
    //           final chatData = snapshot.data.docs;
    //
    //           return  ListView.builder(
    //             itemCount: ( chatData.length).toInt(),
    //             itemBuilder: (context, index) {
    //
    //                 // Render individual chat tile
    //                 final individualChatIndex = index ;
    //                 final chat = chatData[individualChatIndex].data();
    //                 return ChatRoomsTile(
    //                   name: name,
    //                   chatRoomId: chat["chatRoomId"],
    //                   userData: chat["userData"],
    //                   friendData: chat["friendData"],
    //                   isBlocked: chat["isBlock"],
    //                   postId: postId,
    //                   share: imageLink,
    //                 );
    //               }
    //             ,
    //           ) ;
    //         }
    //       },
    //     );
    //   },
    // );
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
  String formatHashtags(var hashtags) {
    List<dynamic> formattedHashtags = hashtags.map((tag) => "#${tag['name']}").toList();
    return formattedHashtags.join(' '); // Use ', ' if you prefer commas
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
        title: const Text("Eventposts",style: TextStyle(fontFamily: Poppins),),
      ),
      body: posts.isEmpty
          ? Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 300),
            child: Center(
              child: Text(
                "No Event Posts",
                style: TextStyle(fontFamily: Poppins,),
              ),
            ),
          ),
        ],
      )
          : SingleChildScrollView(
            child: Column(
              children: [
                ScrollablePositionedList.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 10,
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              // border: posts[index].addMeInFashionWeek ==
                              //     true ? Border.all(color: Colors.yellowAccent,width: 4): null,
                              gradient: posts[index].addMeInFashionWeek == true ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.topRight,
                                  stops: const [0.0, 0.99],
                                  tileMode: TileMode.clamp,
                                  colors: <Color>[
                                    secondary,
                                    primary,
                                  ]):LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.topRight,
                                  stops: const [0.0, 0.99],
                                  tileMode: TileMode.clamp,
                                  colors: <Color>[
                                    Colors.grey,
                                    Colors.grey
                                  ]),),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: InkWell(
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
                                                  ))).then((value){
                                        getPosts();
                                      })
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
                                                  ))).then((value){
                                        getPosts();
                                      });
                                    },
                                    child: Padding(
                                      padding:
                                      const EdgeInsets.all(4.0),
                                      child: Row(
                                        children: [
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          if(posts[index].userid == id) GestureDetector(
                                            onTap:(posts[index].recent_stories!.length <= 0) ? (){
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
                                                          ))).then((value){
                                                getPosts();
                                              })
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
                                                          ))).then((value){
                                                getPosts();
                                              });
                                            }: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                storyList: posts[index].recent_stories!,
                                              ))).then((value){
                                                getPosts();
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                  border: Border.all(
                                                      width: 1.6,
                                                      color:
                                                      Colors.transparent),
                                                  gradient: (posts[index].recent_stories!.length <= 0) ? null : (posts[index].recent_stories!.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.topRight,
                                                      stops: const [0.0, 0.7],
                                                      tileMode: TileMode.clamp,
                                                      colors: <Color>[
                                                        Colors.grey,
                                                        Colors.grey,
                                                      ]) :
                                                  (posts[index].close_friends!.contains(int.parse(id)) == true ?
                                                  (posts[index].recent_stories!.any((story) => story.close_friends_only == true) ? LinearGradient(
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
                                              child: Container(
                                                height: 40,
                                                width: 40,
                                                child: ClipRRect(
                                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                  child: CachedNetworkImage(
                                                    imageUrl: posts[index].userPic,
                                                    imageBuilder: (context, imageProvider) => Container(
                                                      height: 40,
                                                      width: 40,
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
                                            ),
                                          ),
                                          if(posts[index].userid != id) posts[index].show_stories_to_non_friends == true ? GestureDetector(
                                            onTap:(posts[index].recent_stories!.length <= 0) ? (){
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
                                                          ))).then((value){
                                                getPosts();
                                              })
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
                                                          ))).then((value){
                                                getPosts();
                                              });
                                            }: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                storyList: posts[index].recent_stories!,
                                              ))).then((value){
                                                getPosts();
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                  border: Border.all(
                                                      width: 1.6,
                                                      color:
                                                      Colors.transparent),
                                                  gradient: (posts[index].recent_stories!.length <= 0) ? null : (posts[index].recent_stories!.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.topRight,
                                                      stops: const [0.0, 0.7],
                                                      tileMode: TileMode.clamp,
                                                      colors: <Color>[
                                                        Colors.grey,
                                                        Colors.grey,
                                                      ]) :
                                                  (posts[index].close_friends!.contains(int.parse(id)) == true ?
                                                  (posts[index].recent_stories!.any((story) => story.close_friends_only == true) ? LinearGradient(
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
                                              child: Container(
                                                height: 40,
                                                width: 40,
                                                child: ClipRRect(
                                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                  child: CachedNetworkImage(
                                                    imageUrl: posts[index].userPic,
                                                    imageBuilder: (context, imageProvider) => Container(
                                                      height: 40,
                                                      width: 40,
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
                                            ),
                                          ) : (
                                              (posts[index].fanList!.contains(int.parse(id)) == true || posts[index].followList!.contains(int.parse(id)) == true) ?
                                              GestureDetector(
                                                onTap:(posts[index].recent_stories!.length <= 0) ? (){
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
                                                              ))).then((value){
                                                    getPosts();
                                                  })
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
                                                              ))).then((value){
                                                    getPosts();
                                                  });
                                                }: (){
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                    storyList: posts[index].recent_stories!,
                                                  ))).then((value){
                                                    getPosts();
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                      border: Border.all(
                                                          width: 1.6,
                                                          color:
                                                          Colors.transparent),
                                                      gradient: (posts[index].recent_stories!.length <= 0) ? null : (posts[index].recent_stories!.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.topRight,
                                                          stops: const [0.0, 0.7],
                                                          tileMode: TileMode.clamp,
                                                          colors: <Color>[
                                                            Colors.grey,
                                                            Colors.grey,
                                                          ]) :
                                                      (posts[index].close_friends!.contains(int.parse(id)) == true ?
                                                      (posts[index].recent_stories!.any((story) => story.close_friends_only == true) ? LinearGradient(
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
                                                  child: Container(
                                                    height: 40,
                                                    width: 40,
                                                    child: ClipRRect(
                                                      borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                      child: CachedNetworkImage(
                                                        imageUrl: posts[index].userPic,
                                                        imageBuilder: (context, imageProvider) => Container(
                                                          height: 40,
                                                          width: 40,
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
                                                ),
                                              ):
                                              GestureDetector(
                                                onTap: (){
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
                                                              ))).then((value){
                                                    getPosts();
                                                  })
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
                                                              ))).then((value){
                                                    getPosts();
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        width: 1.6,
                                                        color:
                                                        Colors.transparent),
                                                    borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                  ),
                                                  child: Container(
                                                    height: 40,
                                                    width: 40,
                                                    child: ClipRRect(
                                                      borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                      child: CachedNetworkImage(
                                                        imageUrl: posts[index].userPic,
                                                        imageBuilder: (context, imageProvider) => Container(
                                                          height: 40,
                                                          width: 40,
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
                                                ),
                                              )
                                          ),
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
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ReportScreen(
                                                        reportedID:
                                                        posts[index]
                                                            .userid)));
                                      }
                                      if (value == 1) {
                                        description.text =
                                            posts[index]
                                                .description;
                                        updateBool = false;
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              StatefulBuilder(
                                                  builder: (context,
                                                      setState) {
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
                                                            fontFamily: Poppins,
                                                          ),
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
                                                                color: ascent,
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
                                                                    .id,index);
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                        );
                                      }
                                      if (value == 2) {
                                        updateComments(posts[index].id,index,posts[index].isCommentEnabled!);
                                      }
                                      if (value == 3) {
                                        updateLikes(posts[index].id,index,posts[index].isLikeEnabled!);
                                      }
                                      if (value == 4) {
                                        if(posts[index].thumbnail == "Male"){
                                          genderIndex = 0;
                                          gender = "Male";
                                        }
                                        else if(posts[index].thumbnail == "Female"){
                                          genderIndex = 1;
                                          gender = "Female";
                                        }
                                        else if(posts[index].thumbnail == "Unisex"){
                                          genderIndex = 2;
                                          gender = "Unisex";
                                        }
                                        else if(posts[index].thumbnail == "Other"){
                                          genderIndex = 3;
                                          gender = "Other";
                                        }
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return StatefulBuilder(
                                                builder: (context,setState) {
                                                  return Dialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          SizedBox(height: 40,),
                                                          Row(
                                                            children: [
                                                              SizedBox(width: 20,),
                                                              Text("Select gender for this post",style: TextStyle(fontSize: 14,fontFamily: Poppins),)
                                                            ],
                                                          ),
                                                          SizedBox(height: 20,),
                                                          // GridView Section
                                                          Container(
                                                            padding: EdgeInsets.all(16),
                                                            height: 180, // Adjust height as per content
                                                            child: GridView.builder(
                                                              physics: NeverScrollableScrollPhysics(),
                                                              itemCount: genders.length, // Example count
                                                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                                crossAxisCount: 2, // Number of items per row
                                                                crossAxisSpacing: 10,
                                                                mainAxisSpacing: 10,
                                                                childAspectRatio: 2.5, // Adjust for aspect ratio
                                                              ),
                                                              itemBuilder: (context, index1) {
                                                                return GestureDetector(
                                                                  onTap: (){
                                                                    setState((){
                                                                      genderIndex = index1;
                                                                      gender = genders[index1];
                                                                    });
                                                                  },
                                                                  child: Container(
                                                                    decoration: BoxDecoration(
                                                                      color: genderIndex == index1 ? primary : Colors.grey,
                                                                      borderRadius: BorderRadius.circular(8),
                                                                    ),
                                                                    child: Center(
                                                                      child: Text(
                                                                        '${genders[index1]}',
                                                                        style: TextStyle(color: genderIndex == index1 ? ascent : primary),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          // Buttons Section
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                            children: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                },
                                                                child: Text('Cancel',style: TextStyle(color: primary,fontSize: 14,fontFamily: Poppins)),
                                                              ),
                                                              TextButton(
                                                                onPressed: () {
                                                                  setState((){
                                                                    updateBool = true;
                                                                  });
                                                                  updateGender(posts[index].id, index);
                                                                },
                                                                child: updateBool == true ? SpinKitCircle(color: primary,size: 14,) : Text('Update',style: TextStyle(color: primary,fontSize: 14,fontFamily: Poppins)),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }
                                            );
                                          },
                                        );
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
                                        if (posts[index].userid == id) PopupMenuItem(
                                          value: 1,
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                "Edit description",
                                                style: TextStyle(
                                                  fontFamily: Poppins,),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (posts[index].userid == id) updateBool == true ? PopupMenuItem(child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            SpinKitCircle(color: primary,size: 20,),
                                          ],
                                        )) : PopupMenuItem(
                                          value: 2,
                                          child: Row(
                                            children: [
                                              posts[index].isCommentEnabled == false ? Icon(Icons.comment):Icon(Icons.comments_disabled),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                posts[index].isCommentEnabled == false ? "Enable comments" : "Disable comments",
                                                style: TextStyle(
                                                  fontFamily: Poppins,),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (posts[index].userid == id) updateBool == true ? PopupMenuItem(child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            SpinKitCircle(color: primary,size: 20,),
                                          ],
                                        )) : PopupMenuItem(
                                          value: 3,
                                          child: Row(
                                            children: [
                                              posts[index].isLikeEnabled == false ? Icon(Icons.favorite):Icon(Icons.heart_broken),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                posts[index].isLikeEnabled == false ? "Enable likes" : "Disable likes",
                                                style: TextStyle(
                                                  fontFamily: Poppins,),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (posts[index].userid == id) PopupMenuItem(
                                          value: 4,
                                          child: Row(
                                            children: [
                                              Icon(Icons.person),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                "Change gender",
                                                style: TextStyle(
                                                  fontFamily: Poppins,),
                                              ),
                                            ],
                                          ),
                                        )
                                      ];
                                    })
                              ],
                            ),
                          ),
                          // SizedBox(
                          //   height: 550,
                          //   width: double.infinity,
                          //   child: CarouselSlider(
                          //     carouselController: _controller,
                          //     options: CarouselOptions(
                          //         viewportFraction: 1,
                          //         enableInfiniteScroll: false,
                          //         height: 550.0,
                          //         autoPlay: false,
                          //         enlargeCenterPage: true,
                          //         aspectRatio: 2.0,
                          //         initialPage: 0,
                          //         onPageChanged:
                          //             (ind, reason) {
                          //           setState(() {
                          //             _current = ind;
                          //           });
                          //         }),
                          //     items: posts[index]
                          //         .images
                          //         .map((i) {
                          //       return i["type"] == "video"
                          //           ? Container(
                          //           color: Colors.black,
                          //           child:
                          //           UsingVideoControllerExample(
                          //             path: i["video"],
                          //           ))
                          //           : GestureDetector(
                          //         onTap: (){
                          //           showDialog(
                          //             context: context,
                          //             builder: (context) {
                          //               return Dialog(
                          //                 backgroundColor: Colors.black54,
                          //                 insetPadding: EdgeInsets.all(0), // Remove all padding
                          //                 child: Container(
                          //                   color: Colors.black54,
                          //                   width: MediaQuery.of(context).size.width,  // 100% of screen width
                          //                   height: MediaQuery.of(context).size.height * 0.8,  // 90% of screen height
                          //                   child: Padding(
                          //                     padding: const EdgeInsets.all(8.0),
                          //                     child: ClipRRect(
                          //                       borderRadius: BorderRadius.circular(8.0),  // Optional: add rounded corners
                          //                       child: InteractiveViewer(
                          //                           boundaryMargin: EdgeInsets.all(0),  // No margins around the boundary
                          //                           minScale: 0.1,  // Minimum zoom out scale
                          //                           maxScale: 4.0,
                          //                           child:CachedNetworkImage(
                          //                             imageUrl: i["image"],
                          //                             imageBuilder: (context, imageProvider) =>
                          //                                 Container(
                          //                                   height: MediaQuery.of(context).size.height * 0.9,
                          //                                   width: MediaQuery.of(context).size.width,
                          //                                   decoration:
                          //                                   BoxDecoration(
                          //                                     image: DecorationImage(
                          //                                       image: imageProvider,
                          //                                       fit: BoxFit
                          //                                           .contain,
                          //                                     ),
                          //                                   ),
                          //                                 ),
                          //                             placeholder: (context,
                          //                                 url) =>
                          //                                 SpinKitCircle(
                          //                                   color:
                          //                                   primary,
                          //                                   size: 60,
                          //                                 ),
                          //                             errorWidget: (context,
                          //                                 url,
                          //                                 error) =>
                          //                                 Container(
                          //                                   height: MediaQuery.of(context).size.height * 0.9,
                          //                                   width: MediaQuery.of(context).size.width,
                          //                                   decoration:
                          //                                   BoxDecoration(
                          //                                     image: DecorationImage(
                          //                                         image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                          //                                             .image,
                          //                                         fit: BoxFit
                          //                                             .fill),
                          //                                   ),
                          //                                 ),
                          //                           )
                          //                       ),
                          //                     ),
                          //                   ),
                          //                 ),
                          //               );
                          //             },
                          //           );
                          //
                          //         },
                          //         child: CachedNetworkImage(
                          //           imageUrl: i["image"],
                          //           imageBuilder: (context, imageProvider) =>
                          //               Container(
                          //                 height: MediaQuery.of(context).size.height,
                          //                 width: MediaQuery.of(context).size.width,
                          //                 decoration:
                          //                 BoxDecoration(
                          //                   image: DecorationImage(
                          //                     image: imageProvider,
                          //                     fit: BoxFit
                          //                         .fill,
                          //                   ),
                          //                 ),
                          //               ),
                          //           placeholder: (context,
                          //               url) =>
                          //               SpinKitCircle(
                          //                 color:
                          //                 primary,
                          //                 size: 60,
                          //               ),
                          //           errorWidget: (context,
                          //               url,
                          //               error) =>
                          //               Container(
                          //                 height: MediaQuery.of(context).size.height * 0.9,
                          //                 width: MediaQuery.of(context).size.width,
                          //                 decoration:
                          //                 BoxDecoration(
                          //                   image: DecorationImage(
                          //                       image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                          //                           .image,
                          //                       fit: BoxFit
                          //                           .fill),
                          //                 ),
                          //               ),
                          //         ),
                          //       );
                          //     }).toList(),
                          //   ),
                          // ),
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
                          Padding(
                              padding: const EdgeInsets.only(left: 0.0, right: 0.0),
                              child: posts[index].userid == id
                                  ? Row(
                                children: [
                                  SizedBox(width: 10,),
                                  posts[index].addMeInFashionWeek == true
                                      ? posts[index].mylike != "like" ? IconButton(
                                      onPressed: () {},
                                      icon: const Icon(
                                        Icons.favorite,
                                        size: 25,
                                      ))
                                      : GestureDetector(
                                    onTap:(){
                                      if(posts[index].isLikeEnabled == true) {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (
                                                  context) =>
                                                  PostLikeUserScreen(
                                                      fashionId: posts[index]
                                                          .id),
                                            ));
                                      }else {
                                        showModalBottomSheet(
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .only(
                                                    topLeft: Radius
                                                        .circular(
                                                        10),
                                                    topRight: Radius
                                                        .circular(
                                                        10)
                                                )
                                            ),
                                            isScrollControlled: true,
                                            context: context,
                                            builder: (ctx) {
                                              return WillPopScope(
                                                onWillPop: () async {
                                                  Navigator.pop(
                                                      ctx);
                                                  return false; // Prevents the default back button behavior
                                                },
                                                child: DraggableScrollableSheet(
                                                    expand: false,
                                                    // Ensures it doesn't expand fully by default
                                                    initialChildSize: 0.7,
                                                    // Half screen by default
                                                    minChildSize: 0.3,
                                                    // Minimum height
                                                    maxChildSize: 1.0,
                                                    builder: (
                                                        BuildContext context1,
                                                        ScrollController scrollController) {
                                                      return Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 15,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Container(
                                                                height: 3,
                                                                width: 40,
                                                                decoration: BoxDecoration(
                                                                    color: Colors.grey,
                                                                    borderRadius: BorderRadius.all(Radius.circular(20))
                                                                ),
                                                                child: Text(""),
                                                              )
                                                            ],
                                                          ),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                            children: [
                                                              PopupMenuButton(
                                                                  icon: const Icon(Icons.tune,color: Colors.transparent,),
                                                                  onSelected: null,
                                                                  itemBuilder: (BuildContext bc) {
                                                                    return [
                                                                    ];
                                                                  }),
                                                              Text("Likes",style: TextStyle(color: ascent,fontSize: 13,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                                              PopupMenuButton(
                                                                  icon: const Icon(Icons.tune,color: Colors.transparent,),
                                                                  onSelected: null,
                                                                  itemBuilder: (BuildContext bc) {
                                                                    return [
                                                                    ];
                                                                  }),
                                                            ],
                                                          ),
                                                          Divider(color: Colors.grey,),
                                                          Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: [
                                                              SizedBox(height: MediaQuery.of(context).size.height * 0.17,),
                                                              Icon(Icons.heart_broken,color: ascent,size: 50,),
                                                              SizedBox(height: 10,),
                                                              Container(
                                                                width:MediaQuery.of(context).size.width * 0.5,
                                                                child: Center(
                                                                  child: Text("The user has chosen to disable likes on this post.",style: TextStyle(
                                                                      fontFamily: Poppins,
                                                                      fontSize: 12
                                                                  ),),
                                                                ),
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      );
                                                    }
                                                ),
                                              );
                                            }).then((value) {
                                        });
                                      }
                                    },
                                    child: const Icon(
                                      FontAwesomeIcons
                                          .heart,
                                      color: Colors.red,
                                      size: 25,
                                    ),
                                  )
                                      : posts[index].mylike !=
                                      "like"
                                      ? GestureDetector(
                                      onTap:(){
                                        if(posts[index].isLikeEnabled == true) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                    context) =>
                                                    PostLikeUserScreen(
                                                        fashionId: posts[index]
                                                            .id),
                                              ));
                                        }else {
                                          showModalBottomSheet(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .only(
                                                      topLeft: Radius
                                                          .circular(
                                                          10),
                                                      topRight: Radius
                                                          .circular(
                                                          10)
                                                  )
                                              ),
                                              isScrollControlled: true,
                                              context: context,
                                              builder: (ctx) {
                                                return WillPopScope(
                                                  onWillPop: () async {
                                                    Navigator.pop(
                                                        ctx);
                                                    return false; // Prevents the default back button behavior
                                                  },
                                                  child: DraggableScrollableSheet(
                                                      expand: false,
                                                      // Ensures it doesn't expand fully by default
                                                      initialChildSize: 0.7,
                                                      // Half screen by default
                                                      minChildSize: 0.3,
                                                      // Minimum height
                                                      maxChildSize: 1.0,
                                                      builder: (
                                                          BuildContext context1,
                                                          ScrollController scrollController) {
                                                        return Column(
                                                          children: [
                                                            const SizedBox(
                                                              height: 15,
                                                            ),
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Container(
                                                                  height: 3,
                                                                  width: 40,
                                                                  decoration: BoxDecoration(
                                                                      color: Colors.grey,
                                                                      borderRadius: BorderRadius.all(Radius.circular(20))
                                                                  ),
                                                                  child: Text(""),
                                                                )
                                                              ],
                                                            ),
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                              children: [
                                                                PopupMenuButton(
                                                                    icon: const Icon(Icons.tune,color: Colors.transparent,),
                                                                    onSelected: null,
                                                                    itemBuilder: (BuildContext bc) {
                                                                      return [
                                                                      ];
                                                                    }),
                                                                Text("Likes",style: TextStyle(color: ascent,fontSize: 13,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                                                PopupMenuButton(
                                                                    icon: const Icon(Icons.tune,color: Colors.transparent,),
                                                                    onSelected: null,
                                                                    itemBuilder: (BuildContext bc) {
                                                                      return [
                                                                      ];
                                                                    }),
                                                              ],
                                                            ),
                                                            Divider(color: Colors.grey,),
                                                            Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                SizedBox(height: MediaQuery.of(context).size.height * 0.17,),
                                                                Icon(Icons.heart_broken,color: ascent,size: 50,),
                                                                SizedBox(height: 10,),
                                                                Container(
                                                                  width:MediaQuery.of(context).size.width * 0.5,
                                                                  child: Center(
                                                                    child: Text("The user has chosen to disable likes on this post.",style: TextStyle(
                                                                        fontFamily: Poppins,
                                                                        fontSize: 12
                                                                    ),),
                                                                  ),
                                                                )
                                                              ],
                                                            )
                                                          ],
                                                        );
                                                      }
                                                  ),
                                                );
                                              }).then((value) {
                                          });
                                        }
                                      },
                                      child: const Icon(
                                        Icons.star,
                                        color: Colors
                                            .orange,
                                        size: 25,
                                      ))
                                      : GestureDetector(
                                    onDoubleTap: () {},
                                    onTap:(){
                                      if(posts[index].isLikeEnabled == true) {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (
                                                  context) =>
                                                  PostLikeUserScreen(
                                                      fashionId: posts[index]
                                                          .id),
                                            ));
                                      }else {
                                        showModalBottomSheet(
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .only(
                                                    topLeft: Radius
                                                        .circular(
                                                        10),
                                                    topRight: Radius
                                                        .circular(
                                                        10)
                                                )
                                            ),
                                            isScrollControlled: true,
                                            context: context,
                                            builder: (ctx) {
                                              return WillPopScope(
                                                onWillPop: () async {
                                                  Navigator.pop(
                                                      ctx);
                                                  return false; // Prevents the default back button behavior
                                                },
                                                child: DraggableScrollableSheet(
                                                    expand: false,
                                                    // Ensures it doesn't expand fully by default
                                                    initialChildSize: 0.7,
                                                    // Half screen by default
                                                    minChildSize: 0.3,
                                                    // Minimum height
                                                    maxChildSize: 1.0,
                                                    builder: (
                                                        BuildContext context1,
                                                        ScrollController scrollController) {
                                                      return Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 15,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Container(
                                                                height: 3,
                                                                width: 40,
                                                                decoration: BoxDecoration(
                                                                    color: Colors.grey,
                                                                    borderRadius: BorderRadius.all(Radius.circular(20))
                                                                ),
                                                                child: Text(""),
                                                              )
                                                            ],
                                                          ),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                            children: [
                                                              PopupMenuButton(
                                                                  icon: const Icon(Icons.tune,color: Colors.transparent,),
                                                                  onSelected: null,
                                                                  itemBuilder: (BuildContext bc) {
                                                                    return [
                                                                    ];
                                                                  }),
                                                              Text("Likes",style: TextStyle(color: ascent,fontSize: 13,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                                              PopupMenuButton(
                                                                  icon: const Icon(Icons.tune,color: Colors.transparent,),
                                                                  onSelected: null,
                                                                  itemBuilder: (BuildContext bc) {
                                                                    return [
                                                                    ];
                                                                  }),
                                                            ],
                                                          ),
                                                          Divider(color: Colors.grey,),
                                                          Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: [
                                                              SizedBox(height: MediaQuery.of(context).size.height * 0.17,),
                                                              Icon(Icons.heart_broken,color: ascent,size: 50,),
                                                              SizedBox(height: 10,),
                                                              Container(
                                                                width:MediaQuery.of(context).size.width * 0.5,
                                                                child: Center(
                                                                  child: Text("The user has chosen to disable likes on this post.",style: TextStyle(
                                                                      fontFamily: Poppins,
                                                                      fontSize: 12
                                                                  ),),
                                                                ),
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      );
                                                    }
                                                ),
                                              );
                                            }).then((value) {
                                        });
                                      }
                                    },
                                    child:
                                    Icon(
                                        Icons
                                            .star_border_outlined,
                                        size: 25,
                                        color: Colors
                                            .orange),
                                  ),
                                  posts[index].likeCount == "0"
                                      ?
                                  const SizedBox()
                                      : (posts[index].isLikeEnabled == false ?
                                  Text(" ?",style: TextStyle(fontFamily: Poppins,color: ascent),): Text(" ${posts[index].likeCount}",style: TextStyle(fontFamily: Poppins,),)),
                                  SizedBox(width: 10,),
                                  GestureDetector(
                                    onTap:(){
                                      if(posts[index].isCommentEnabled == true) {
                                        showModalBottomSheet(
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .only(
                                                    topLeft: Radius
                                                        .circular(
                                                        10),
                                                    topRight: Radius
                                                        .circular(
                                                        10)
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
                                                      expand: false,
                                                      // Ensures it doesn't expand fully by default
                                                      initialChildSize: 0.7,
                                                      // Half screen by default
                                                      minChildSize: 0.3,
                                                      // Minimum height
                                                      maxChildSize: 1.0,
                                                      builder: (
                                                          BuildContext context1,
                                                          ScrollController scrollController) {
                                                        return CommentScreen(
                                                          postid: posts[index]
                                                              .id,
                                                          pic: posts[index]
                                                              .userPic,
                                                          scrollController: scrollController,
                                                          context1: context1,
                                                            isEventPost: posts[index].addMeInFashionWeek!,
                                                            userID: posts[index].userid
                                                        );
                                                      }
                                                  ),
                                                ),
                                              );
                                            }).then((value) {
                                        });
                                      }else {
                                        showModalBottomSheet(
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .only(
                                                    topLeft: Radius
                                                        .circular(
                                                        10),
                                                    topRight: Radius
                                                        .circular(
                                                        10)
                                                )
                                            ),
                                            isScrollControlled: true,
                                            context: context,
                                            builder: (ctx) {
                                              return WillPopScope(
                                                onWillPop: () async {
                                                  Navigator.pop(
                                                      ctx);
                                                  return false; // Prevents the default back button behavior
                                                },
                                                child: DraggableScrollableSheet(
                                                    expand: false,
                                                    // Ensures it doesn't expand fully by default
                                                    initialChildSize: 0.7,
                                                    // Half screen by default
                                                    minChildSize: 0.3,
                                                    // Minimum height
                                                    maxChildSize: 1.0,
                                                    builder: (
                                                        BuildContext context1,
                                                        ScrollController scrollController) {
                                                      return Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 15,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Container(
                                                                height: 3,
                                                                width: 40,
                                                                decoration: BoxDecoration(
                                                                    color: Colors.grey,
                                                                    borderRadius: BorderRadius.all(Radius.circular(20))
                                                                ),
                                                                child: Text(""),
                                                              )
                                                            ],
                                                          ),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                            children: [
                                                              PopupMenuButton(
                                                                  icon: const Icon(Icons.tune,color: Colors.transparent,),
                                                                  onSelected: null,
                                                                  itemBuilder: (BuildContext bc) {
                                                                    return [
                                                                    ];
                                                                  }),
                                                              Text("Comments",style: TextStyle(color: ascent,fontSize: 13,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                                              PopupMenuButton(
                                                                  icon: const Icon(Icons.tune,color: Colors.transparent,),
                                                                  onSelected: null,
                                                                  itemBuilder: (BuildContext bc) {
                                                                    return [
                                                                    ];
                                                                  }),
                                                            ],
                                                          ),
                                                          Divider(color: Colors.grey,),
                                                          Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: [
                                                              SizedBox(height: MediaQuery.of(context).size.height * 0.17,),
                                                              Icon(Icons.comments_disabled,color: ascent,size: 50,),
                                                              SizedBox(height: 10,),
                                                              Container(
                                                                width:MediaQuery.of(context).size.width * 0.5,
                                                                child: Center(
                                                                  child: Text("The user has chosen to disable comments on this post.",style: TextStyle(
                                                                      fontFamily: Poppins,
                                                                      fontSize: 12
                                                                  ),),
                                                                ),
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      );
                                                    }
                                                ),
                                              );
                                            }).then((value) {
                                        });
                                      }
                                    },
                                    child: const Icon(
                                      FontAwesomeIcons
                                          .comment,
                                      size: 25,
                                    ),
                                  ),
                                  posts[index].isCommentEnabled == false ?
                                  const Text(" ?",style: TextStyle(fontFamily: Poppins,color: ascent),)
                                      :
                                  (posts[index].commentCount == "0" ? Text("") : Text(" ${posts[index].commentCount}",style: TextStyle(fontFamily: Poppins,),)),
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
                                            }).then((value){
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
                                        padding: const EdgeInsets.only(right: 2),
                                        child: Image.asset('assets/Frame1.png', height: 25),
                                      )),
                                  SizedBox(width: 10,)
                                ],
                              )
                                  : Row(
                                children: [
                                  SizedBox(width: 10,),
                                  posts[index].addMeInFashionWeek ==
                                      true
                                      ? posts[index].mylike !=
                                      "like"
                                      ? GestureDetector(
                                    onTap:(){
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                PostLikeUserScreen(fashionId: posts[index].id),
                                          ));
                                    },
                                    child: const Icon(
                                      Icons.favorite,
                                      size: 25,
                                      color: Colors.red,
                                    ),
                                  )
                                      : GestureDetector(
                                    onTap:(){
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                PostLikeUserScreen(fashionId: posts[index].id),
                                          ));
                                    },
                                    child: const Icon(
                                      FontAwesomeIcons
                                          .heart,
                                      size: 25,
                                      color: Colors.red,
                                    ),
                                  )
                                      : posts[index].mylike !=
                                      "like"
                                      ? GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                  PostLikeUserScreen(fashionId: posts[index].id),
                                            ));
                                      },
                                      child:
                                      Icon(
                                        Icons.star,
                                        color: Colors
                                            .orange,
                                        size: 25,
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
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                PostLikeUserScreen(fashionId: posts[index].id),
                                          ));
                                    },
                                    child:
                                    Icon(
                                      Icons
                                          .star_border_outlined,
                                      color: Colors
                                          .orange,
                                      size: 25,
                                    ),
                                  ),
                                  posts[index].likeCount == "0"
                                      ?
                                  const SizedBox()
                                      :
                                  Text(" ${posts[index].likeCount}",style: TextStyle(fontFamily: Poppins,),),
                                  SizedBox(width: 10,),
                                  posts[index].isCommentEnabled ==
                                      true
                                      ? GestureDetector(
                                    onTap:(){
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
                                                    builder: (BuildContext context1, ScrollController scrollController) {
                                                      return CommentScreen(
                                                        postid: posts[index]
                                                            .id,
                                                        pic: posts[index]
                                                            .userPic,
                                                        scrollController: scrollController,
                                                        context1: context1,
                                                          isEventPost: posts![index].addMeInFashionWeek!,
                                                          userID: posts[index].userid
                                                      );
                                                    }
                                                ),
                                              ),
                                            );
                                          }).then((value){
                                      });
                                    },
                                    child: const Icon(
                                      FontAwesomeIcons
                                          .comment,
                                      size: 25,
                                    ),
                                  )
                                      : const SizedBox(),
                                  if(posts[index].isCommentEnabled == true) posts[index].commentCount == "0"
                                      ?
                                  const SizedBox()
                                      :
                                  Text(" ${posts[index].commentCount}",style: TextStyle(fontFamily: Poppins,),),
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
                                            }).then((value){
                                        });
                                      },
                                      icon: const Icon(
                                        FontAwesomeIcons.share,
                                        size: 25,
                                      )
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                      onTap: () {
                                        saveStyle(posts[index].id);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 2),
                                        child: Image.asset('assets/Frame1.png', height: 25),
                                      )),
                                  SizedBox(width: 10,)
                                ],
                              )
                          ),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.start,
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              posts[index].description.toString().length +formatHashtags(posts[index].hashtags).length >
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
                                            ? GestureDetector(
                                          onTap:(){
                                            setState(() {
                                              isExpanded = !isExpanded;
                                            });
                                          },
                                              child: Row(
                                          children: [
                                              Text(
                                                Uri.decodeComponent(posts[index].userName,),
                                                style: TextStyle(
                                                    fontFamily: Poppins,
                                                    fontSize: 13,
                                                    color: primary,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Text(
                                                "${handleEmojis(posts[index].description.substring(0, 7))}...",
                                                style:
                                                const TextStyle(
                                                  fontFamily: Poppins,
                                                  fontSize: 13,
                                                ),
                                                textAlign:
                                                TextAlign
                                                    .start,
                                              )
                                          ],
                                        ),
                                            )
                                            : Column(
                                          crossAxisAlignment:CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              Uri.decodeComponent(posts[index].userName,),
                                              style: TextStyle(
                                                  fontFamily: Poppins,
                                                  fontSize: 13,
                                                  color: primary,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(
                                              height: 5,
                                            ),
                                            Container(
                                              width: MediaQuery.of(context).size.width * 0.8,
                                              child: Text(
                                                  "${handleEmojis( posts[index].description)} ${formatHashtags(posts[index].hashtags)}",
                                                  style: const TextStyle(
                                                      fontFamily: Poppins,
                                                      fontSize:
                                                      13)),
                                            ),
                                          ],
                                        ),
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
                                                    fontFamily: Poppins,
                                                    color: Theme.of(
                                                        context)
                                                        .primaryColor))),
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
                                            Uri.decodeComponent(posts[index].userName),
                                            style: TextStyle(
                                                fontFamily: Poppins,
                                                fontSize: 13,
                                                color: primary,
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
                                                fontSize: 13),
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
                          posts[index].addMeInFashionWeek ==
                              true ? Row(
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              Text("Event - ${posts[index].event["title"]}",style: TextStyle(fontFamily: Poppins,),)
                            ],
                          ): const SizedBox(),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 10),
                              posts[index].commentCount == "0"
                                  ?
                              const SizedBox()
                                  : GestureDetector(
                                  onTap:(){
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
                                                  builder: (BuildContext context1, ScrollController scrollController) {
                                                    return CommentScreen(
                                                      postid: posts[index]
                                                          .id,
                                                      pic: posts[index]
                                                          .userPic,
                                                      scrollController: scrollController,
                                                      context1: context1,
                                                        isEventPost: posts[index].addMeInFashionWeek!,
                                                        userID: posts[index].userid
                                                    );
                                                  }
                                              ),
                                            ),
                                          );
                                        }).then((value){
                                    });
                                  },
                                  child: Text("View all ${posts[index].commentCount} comments",style: TextStyle(fontFamily: Poppins,),)),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                  itemScrollController: itemScrollController,
                  scrollOffsetController: scrollOffsetController,
                  itemPositionsListener: itemPositionsListener,
                  scrollOffsetListener: scrollOffsetListener,
                ),
              ],
            ),
          ),
    );
  }
}
