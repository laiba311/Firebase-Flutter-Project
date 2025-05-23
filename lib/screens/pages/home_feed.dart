import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart' as carousel_controller;
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/models/post_model.dart';
import 'package:finalfashiontimefrontend/screens/chats-screens/message_screen.dart';
import 'package:finalfashiontimefrontend/screens/fashionComments/comment_screen.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/post_like_user.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/profiles/myProfile.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/report_screen.dart';
import 'package:finalfashiontimefrontend/screens/stories/create_story.dart';
import 'package:finalfashiontimefrontend/screens/stories/story_media_selection.dart';
import 'package:finalfashiontimefrontend/screens/stories/view_story.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import '../../customize_pacages/mentions/src/mention_text_field.dart';
import '../../helpers/database_methods.dart';
import '../../models/story_model.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';

class HomeFeedScreen extends StatefulWidget {
  final Function navigate;
  final Function onNavigate;
  final Function navigateToPageWithPostArguments;
  final Function navigateToPageWithFriendArguments;
  const HomeFeedScreen({Key? key, required this.onNavigate, required this.navigateToPageWithPostArguments, required this.navigateToPageWithFriendArguments, required this.navigate}) : super(key: key);
  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  bool like = false;
  bool dislike = false;
  bool vote = false;
  String id = "";
  String token = "";
  String name = "";
  String pic = "";
  List<PostModel> posts = [];
  List<Story> storyList = [];
  List<Story> myTodayStories = [];
  String nextPageUrl = "";
  bool loading = false;
  bool isExpanded = true;
  bool isRefresh = true;
  Stream? chatRooms;
  int paginationPost=1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<LiquidPullToRefreshState> _refreshIndicatorKey =
      GlobalKey<LiquidPullToRefreshState>();
  TextEditingController description = TextEditingController();
  bool updateBool = false;
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();
 // late BannerAd _bannerAd;
  bool _isAdLoaded = false;
  Set<int> storyIdSet = {};
  Set<String> storyImgSet = {};
  final bool _isPinching = false;
  List<List<Story>> groupedStoriesList = [];
  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController = ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final ScrollOffsetListener scrollOffsetListener = ScrollOffsetListener.create();
  List<String> genders = ['Male', 'Female','Unisex', 'Other'];
  String gender = "";
  int genderIndex = 0;
  List<int> myList = [];
  bool style_visibility = false;
  List<int> idolIdList = [];
  List<PostModel> publicPosts = [];
  List<Story> publicStoryList = [];
  List<int> myList1 = [];
  List<List<Story>> groupedStoriesList1 = [];
  List<Map<String,dynamic>> requestList = [];
  bool requestLoader2 = false;
  String fanRequestID = "";
  List<Map<String,dynamic>> users = [];
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  bool isExpendedComment = false;
  final FocusNode _textFieldFocusNode = FocusNode();
  double? _previousExtent;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    focusNode1.addListener(() {
      setState(() {
        isExpendedComment = true;
        //isExpendedComment = focusNode1.hasFocus;
      });
    });
    getCashedData();
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
      });
      getRequests();
      getMyIdols();
      getProfile();
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
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

  getProfile() {
    setState(() {
      loading = true;
    });
    https.get(Uri.parse("$serverUrl/user/api/profile/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      print("Profile data ==> ${value.body.toString()}");
      final body = utf8.decode(value.bodyBytes);
      final jsonData = jsonDecode(body);
      print("show_stories_to_non_friends ==> ${jsonData["show_stories_to_non_friends"]}");
      setState(() {
        style_visibility = jsonData["isStyleVisibility"];
      });
      print("style visibilty => ${style_visibility}");
    });
    // getMyPosts();
  }
  getUserInfogetChats() async {
    DatabaseMethods().getUserChats(name).then((snapshots) {
      setState(() {
        chatRooms = snapshots;
        print(
            "we got the data + ${chatRooms.toString()} this is name  $name");
      });
    });
  }
  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    name = preferences.getString("name")!;
    pic = preferences.getString("pic")!;
    print(name);
    print("pic => "+pic);
    debugPrint("token in home feed is========>$token");
    getRequests();
    getMyIdols();
    getProfile();
    getFavourites();
    getPosts(1);
    getUserInfogetChats();
    getMyTodayStories();
    getAllPublicStories();
    getPublicPosts();
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

  Future<void> getAllStories() async {
    const apiUrl = "$serverUrl/story/stories/";
    try {
      https.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).then((value) {
        if (value.statusCode == 200) {
          print("Entered Story 200 response");
          final body = utf8.decode(value.bodyBytes);
          final jsonData = jsonDecode(body);

          // List to hold lists of stories grouped by user
          // Temporary map to group stories by user ID
          Map<String, List<Story>> tempStoryMap = {};

          jsonData.forEach((element) {
            print("time -> ${element["time_since_created"]}");
            final User user = User(
              name: element['user']['name'],
              username: element['user']['username'],
              profileImageUrl: element['user']['pic'] ?? '',
              id: element['user']['id'].toString(),
            );

            // Check if the user's ID exists in myList
            if (myList.contains(int.tryParse(user.id))) {
              print("Skipping stories for user ID: ${user.id}");
              return; // Skip this story
            }

            // Create a story object for each element
            Story story = Story(
              duration: element["time_since_created"].toString(),
              url: element["content"],
              type: element["type"],
              user: user,
              storyId: element["id"],
              viewed_users: element["viewers"],
              created: element["created_at"],
              close_friends_only: element['close_friends_only'],
              isPrivate: element["is_user_private"],
              fanList: element["fansList"]
            );

            // Group stories by user in the temporary map
            if (tempStoryMap.containsKey(user.id)) {
              tempStoryMap[user.id]?.add(story);
            } else {
              tempStoryMap[user.id] = [story];
            }
          });

          // Convert the map values to a list of lists
          groupedStoriesList = tempStoryMap.values.toList();

          setState(() {
            // Now groupedStoriesList contains lists of stories grouped by user
          });
        } else {
          print("Error received while getting all stories =========> ${value.body.toString()}");
        }
      });
    } catch (e) {
      print("Error Story -> ${e.toString()}");
    }
  }

  Future<void> getAllPublicStories() async {
    const apiUrl = "$serverUrl/user/api/allUsers/";
    try {
      https.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).then((value) {
        if (value.statusCode == 200) {
          print("Entered Story 200 response");
          final body = utf8.decode(value.bodyBytes);
          final jsonData = jsonDecode(body);
          print("public users => ${jsonData}");
          jsonData["results"].forEach((element) {
            print("USer => ${element}");
            if(element["id"].toString() == id){
              print("else");
            }else {
              setState(() {
                users.add(element);
              });
            }
          });
          users.shuffle(Random());
        } else {
          print("Error received while getting all stories =========> ${value.body.toString()}");
        }
      });
    } catch (e) {
      print("Error Story -> ${e.toString()}");
    }
  }

  Future<void> getMyTodayStories() async {
    myTodayStories.clear();
    const apiUrl="$serverUrl/story/my-today-stories/";
    try{
      https.get(
          Uri.parse(apiUrl), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }
      ).then((value) {
        if(value.statusCode==200){
          print("Entered Story 200 response");
          final body = utf8.decode(value.bodyBytes);
          final jsonData = jsonDecode(body);
          jsonData.forEach((element) {
            print("time -> ${element["time_since_created"]}");
            final User user = User(
                name: element['user']['name'],
                username: element['user']['username'],
                profileImageUrl: element['user']['pic'] ?? '',
                id: element['user']['id'].toString()
            );
            setState(() {
              myTodayStories.add(Story(
                  duration: element["time_since_created"].toString(),
                  url: element["content"],
                  type:element["type"],
                  user: user,
                  storyId: element["id"],
                  viewed_users: element["viewers"],
                  created: element["created_at"],
                  close_friends_only: element['close_friends_only'],
                  isPrivate: element["is_user_private"],
                  fanList: element["fansList"]
              ));
            });
          });
          print("the my today all story list is =======>${myTodayStories.toString()}");
        }
        else{
          print("error getting my today all stories =========>${value.body.toString()}");
        }
      });
    }
    catch(e){
      print("Error my today Story -> ${e.toString()}");
    }
  }
  getPublicPosts() {
    publicPosts.clear();
    setState(() {
      loading = true;
    });

    try {
      https.get(Uri.parse("$serverUrl/fashionapi/public-fashion-styles/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        setState(() {
          loading = false;
        });

        Map<String, dynamic> response = jsonDecode(value.body);
        List<dynamic> results = response["results"];
        for (var result in results) {

          if (style_visibility == false && result["user"]["id"].toString() == id) {
            continue; // Skip this iteration
          }

          var upload = result["upload"];
          // if(response["next"]==null){
          //   paginationPost=0;
          // }

          var media = upload != null ? upload["media"] : null;
          if(result['hashtags']!=[]){

            publicPosts.add(PostModel(
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
                      fanList: e1["fansList"],
                  );
                })) :[],
                show_stories_to_non_friends: result['user']['show_stories_to_non_friends'],
                fanList: result["fansList"],
                followList: result["user"]["followList"],
                close_friends: result["close_friends"],
                isPrivate: result["user"]["isPrivate"]
            ));
            //print("Posts ==> ${posts.length} ${result[]}");

            debugPrint(
                "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
            debugPrint("value of isCommentEnabled is ${result["isCommentOff"]} ${posts.length}");
          }
          else{
            publicPosts.add(PostModel(
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
                close_friends: result["close_friends"],
                isPrivate: result["user"]["isPrivate"]
            ));
            //print("Posts ==> ${posts.length} ${result}");
            debugPrint(
                "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
            debugPrint("value of isCommentEnabled is ${result["isCommentOff"]} ${publicPosts.length}");
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

  String formatHashtags(var hashtags) {
    List<dynamic> formattedHashtags = hashtags.map((tag) => "#${tag['name']}").toList();
    return formattedHashtags.join(' '); // Use ', ' if you prefer commas
  }
  getPosts(int pagination) {
    posts.clear();
    setState(() {
      loading = true;
    });

    try {
      https.get(Uri.parse("$serverUrl/fashionUpload/idols-fashions/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        setState(() {
          loading = false;
        });

        Map<String, dynamic> response = jsonDecode(value.body);
        List<dynamic> results = response["results"];
        if(pagination>1){
          print("pagination api response========>${value.body.toString()}");
        }
        for (var result in results) {

          // if (style_visibility == false && result["user"]["id"].toString() == id) {
          //   continue; // Skip this iteration
          // }

          var upload = result["upload"];
          // if(response["next"]==null){
          //   paginationPost=0;
          // }
          print("Image of profile ==> ${result["user"]["pic"].toString().replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/", "https://")}");
          var media = upload != null ? upload["media"] : null;
          print("Image ==>  ${upload}");
          if(result['hashtags']!=[]){

            posts.add(PostModel(
                result["id"].toString(),
                result["description"],
                media ?? [],
                result["user"]["username"],
                result["user"]["pic"] != null ? result["user"]["pic"].toString().replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/", "https://") : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
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
                result["user"]["pic"] != null ? result["user"]["pic"].toString().replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/", "https://") : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
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
  getPostsToScroll(int pagination,int index) {
    posts.clear();
    setState(() {
      loading = true;
    });

    try {
      https.get(Uri.parse("$serverUrl/fashionUpload/idols-fashions/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        setState(() {
          loading = false;
        });

        Map<String, dynamic> response = jsonDecode(value.body);
        List<dynamic> results = response["results"];
        if(pagination>1){
          print("pagination api response========>${value.body.toString()}");
        }
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
                result["eventData"],
                result["topBadge"] ?? {"badge":null},
                addMeInFashionWeek: result["addMeInWeekFashion"],
                isCommentEnabled: result["isCommentOff"],
                hashtags: result['hashtags']));
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
                result["eventData"],
                result["topBadge"] ?? {"badge":null},
                addMeInFashionWeek: result["addMeInWeekFashion"],
                isCommentEnabled: result["isCommentOff"],
                hashtags: result['hashtags']));
            //print("Posts ==> ${posts.length} ${result}");
            debugPrint(
                "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
            debugPrint("value of isCommentEnabled is ${result["isCommentOff"]} ${posts.length}");
          }
          //print("Posts ==> ${posts.length} ${posts}");
        }
      });
      itemScrollController.scrollTo(
          index: index,
          duration: Duration(seconds: 2),
          curve: Curves.easeInOutCubic);
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

  Future<void> _refreshData() async {
    // Simulate a network request or data update
    await Future.delayed(Duration(seconds: 2));
    getRequests();
    getMyIdols();
    getMyTodayStories();
    getAllStories();
    getPosts(2);
  }

  Future<void> _refreshData1() async {
    // Simulate a network request or data update
    await Future.delayed(Duration(seconds: 2));
    getRequests();
    getMyIdols();
    getMyTodayStories();
    getAllPublicStories();
    getPublicPosts();
    getProfile();
    getPosts(1);
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
        setState(() {
          loading = false;
        });
        debugPrint("fansidols response==========>${jsonDecode(value.body)}");
        jsonDecode(value.body).forEach((data){
          setState(() {
            idolIdList.add(data["idols"]["id"]);
          });
        });
        print("Idols => ${idolIdList}");
      });
    }catch(e){
      debugPrint("Error --> $e");
    }
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
    getAllStories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading == true
          ? SpinKitCircle(
              color: primary,
              size: 50,
            )
          : (posts.isEmpty
          ? RefreshIndicator(
                  color: primary,
                  onRefresh: _refreshData1,
                child: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10,),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(width: 5,),
                            Container(
                              height: 110,
                              child: GestureDetector(
                                onTap: myTodayStories.length > 0 ? (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                    storyList: myTodayStories,
                                  ))).then((value){
                                    getFavourites();
                                    getMyTodayStories();
                                    getAllStories();
                                  });
                                }: (){},
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: myTodayStories.length > 0 ?
                                        (myTodayStories.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.7],
                                            tileMode: TileMode.clamp,
                                            colors: <Color>[
                                              Colors.grey,
                                              Colors.grey,
                                            ]) :
                                        (myTodayStories.any((story) => story.close_friends_only == true) ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.7],
                                            tileMode: TileMode.clamp,
                                            colors: <Color>[
                                              Colors.deepPurple,
                                              Colors.purpleAccent,
                                            ]): LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.7],
                                            tileMode: TileMode.clamp,
                                            colors: <Color>[
                                              secondary,
                                              primary,
                                            ]))
                                        ): LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.7],
                                            tileMode: TileMode.clamp,
                                            colors: <Color>[
                                              // Colors.black,
                                              // Colors.black,
                                              Colors.transparent,
                                              Colors.transparent
                                            ]),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              //color: Colors.black,
                                              color: Colors.transparent,
                                              borderRadius: const BorderRadius.all(Radius.circular(120))
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(3.0),
                                            child: CachedNetworkImage(
                                              imageUrl: pic.isNotEmpty  ? pic : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f",
                                              imageBuilder: (context,
                                                  imageProvider) => CircleAvatar(
                                                  backgroundColor: Colors.grey,
                                                  maxRadius: 36,
                                                  backgroundImage: NetworkImage(pic),
                                                  child: Align(
                                                    alignment: Alignment
                                                        .bottomRight,
                                                    child: SizedBox(
                                                      height: 22,
                                                      width: 22,
                                                      child: FloatingActionButton(
                                                        heroTag: null,
                                                        onPressed:
                                                            () {
                                                              widget.navigate(31);
                                                          //Navigator.push(context, MaterialPageRoute(builder: (context) => UploadStoryScreen(),)).then((value){
                                                          //   getMyTodayStories();
                                                          //   getAllStories();
                                                          // });
                                                        },
                                                        backgroundColor: Colors.blue.shade300,
                                                        mini: true,
                                                        child: const Icon(Icons.add,size: 16,color: ascent,),
                                                      ),
                                                    ),
                                                  )
                                              ),
                                              placeholder: (context, url) => CircleAvatar(
                                                  backgroundColor: Colors.grey,
                                                  maxRadius: 36,
                                                  child: SpinKitCircle(color: primary,size: 5,)
                                                // Placeholder color
                                              ),
                                              errorWidget: (context, url,
                                                  error) => CircleAvatar(
                                                  maxRadius: 36,
                                                  backgroundImage:
                                                  NetworkImage(
                                                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f"),
                                                  child:  Align(
                                                    alignment: Alignment
                                                        .bottomRight,
                                                    child: SizedBox(
                                                      height: 18,
                                                      width: 18,
                                                      child:
                                                      FloatingActionButton(
                                                        heroTag: null,
                                                        onPressed:
                                                            () {
                                                              widget.navigate(31);
                                                          //Navigator.push(context, MaterialPageRoute(builder: (context) => const StoryMediaScreen(),));
                                                        },
                                                        backgroundColor:
                                                        primary,
                                                        foregroundColor: ascent,
                                                        mini: true,
                                                        child:  const Icon(Icons.add,size: 14),
                                                      ),
                                                    ),
                                                  )
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 1,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("Your Story",style: TextStyle(
                                            fontFamily: Poppins,
                                            color: ascent,
                                            fontSize: 10
                                        ),)
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 15,),
                            Container(
                              height: 110,
                              child: ListView.builder(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: users.length,
                                  itemBuilder: (context,index){
                                    return GestureDetector(
                                      onTap: (){
                                        widget.navigateToPageWithFriendArguments(30,users[index]["id"].toString(),users[index]["username"]);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 15.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(height: 3,),
                                            Container(
                                              child: CachedNetworkImage(
                                                imageUrl: users[index]["pic"] == null ? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w" :users[index]["pic"],
                                                imageBuilder: (context,
                                                    imageProvider) => CircleAvatar(
                                                    maxRadius: 36,
                                                    backgroundImage: NetworkImage(users[index]["pic"] == null ?"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":users[index]["pic"]),
                                                    child: Align(
                                                      alignment: Alignment
                                                          .bottomRight,
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          if(users[index]["isPrivate"] == false || (users[index]["fansList"] ?? []).contains(int.parse(id)) == true) idolIdList.contains(int.parse(users[index]["id"].toString())) == true
                                                              ? SizedBox(
                                                            height: 25,
                                                            width: 25,
                                                            child: FloatingActionButton(
                                                              heroTag: null,
                                                              onPressed: () {
                                                                removeFan(users[index]["id"].toString());
                                                              },
                                                              backgroundColor: Colors.grey,
                                                              mini: true,
                                                              child: const Icon(Icons.person_remove,size: 15,color: ascent,),
                                                            ),
                                                          )
                                                              : SizedBox(
                                                            height: 25,
                                                            width: 25,
                                                            child: FloatingActionButton(
                                                              heroTag: null,
                                                              onPressed: () {
                                                                addFan(id, users[index]["id"].toString());
                                                              },
                                                              backgroundColor: primary,
                                                              mini: true,
                                                              child: const Icon(Icons.person_add_alt,size: 15,color: ascent,),
                                                            ),
                                                          ),
                                                          if(users[index]["isPrivate"] == true && (users[index]["fansList"] ?? []).contains(int.parse(id)) == false)
                                                            SizedBox(
                                                              height: 25,
                                                              width: 25,
                                                              child: FloatingActionButton(
                                                                heroTag: null,
                                                                onPressed: () {
                                                                  if(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == users[index]["id"].toString()) == false){
                                                                    print("fan");
                                                                    sendFanRequest(id,users[index]["id"].toString());
                                                                    // showDialog(
                                                                    //   context: context,
                                                                    //   builder: (context) => AlertDialog(
                                                                    //     backgroundColor: primary,
                                                                    //     title: Text("Fan request ${users[index]["username"]}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                                                    //     content: Text("Are you sure you want to send a fan request to ${users[index]["username"]}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
                                                                    //           sendFanRequest(id,users[index]["id"].toString());
                                                                    //         },
                                                                    //       ),
                                                                    //     ],
                                                                    //   ),
                                                                    // );
                                                                  }
                                                                  else if(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == users[index]["id"].toString()) == true) {
                                                                    print("unfan");
                                                                    getRequestsForCancel(users[index]["id"].toString());
                                                                    // showDialog(
                                                                    //   context: context,
                                                                    //   builder: (context) => AlertDialog(
                                                                    //     backgroundColor: primary,
                                                                    //     title: Text("Cancel request ${users[index]["username"]}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                                                    //     content: Text("Are you sure you want to cancel fan request to ${users[index]["username"]}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
                                                                    //           getRequestsForCancel(users[index]["id"].toString());
                                                                    //         },
                                                                    //       ),
                                                                    //     ],
                                                                    //   ),
                                                                    // );
                                                                    //removeFan(widget.id);
                                                                  }
                                                                },
                                                                backgroundColor: requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == users[index]["id"].toString()) == true ? Colors.grey : primary,
                                                                mini: true,
                                                                child: requestLoader2 == true ? const SpinKitCircle(color: ascent, size: 10,) : const Icon(Icons.person_add_alt,size: 15,color: ascent,),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    )
                                                ),
                                                placeholder: (context, url) => CircleAvatar(
                                                    maxRadius: 36,
                                                    backgroundColor: primary,
                                                    child: SpinKitCircle(color: primary,size: 10,)
                                                  // Placeholder color
                                                ),
                                                errorWidget: (context, url,
                                                    error) => CircleAvatar(
                                                  maxRadius: 36,
                                                  backgroundImage:
                                                  NetworkImage(
                                                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w"),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 10,),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                //Text("${groupedStoriesList[index].any((story) => story.viewed_users.any((viewer) => viewer['id'] == id))}"),
                                                Text("${users[index]["username"].length > 8 ? users[index]["username"].toString().substring(0,6)+"..." : users[index]["username"]}",style: TextStyle(
                                                    fontFamily: Poppins,
                                                    color: ascent,
                                                    fontSize: 10
                                                ),)
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
                      ScrollablePositionedList.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) {
                          if (index % 5 == 0) {
                            // Create a new BannerAd instance for each separator
                            //MobileAds.instance.initialize();
                            BannerAd bannerAd = BannerAd(
                              size: AdSize.banner,
                              adUnitId: "ca-app-pub-5248449076034001/6687962197",
                             // adUnitId: "ca-app-pub-3940256099942544/6300978111",
                              listener: BannerAdListener(
                                onAdLoaded: (ad) {
                                  setState(() {
                                    // Optionally handle the ad load state
                                  });
                                },
                                onAdFailedToLoad: (ad, error) {
                                  print("add error => ${error}");
                                  ad.dispose(); // Clean up if the ad fails to load
                                },
                              ),
                              request: const AdRequest(),
                            );

                            // Load the ad before displaying it
                            bannerAd.load();

                            return SizedBox(
                              height: bannerAd.size.height.toDouble(),
                              width: bannerAd.size.width.toDouble(),
                              child: AdWidget(
                                ad: bannerAd,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        itemCount: publicPosts.length,
                        itemBuilder: (context, index) {
                          if (index == publicPosts.length - 1) {
                            // If we reach the last item, fetch next page of posts
                            return isRefresh
                                ? InkWell(
                                onTap: () {
                                  //paginationPost++;
                                  getPosts(1);
                                },
                                child: Icon(
                                  Icons.refresh,
                                  color: primary,
                                ))
                                : const SizedBox();
                          }
                          return Card(
                            elevation: 10,
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    // border: posts[index].addMeInFashionWeek ==
                                    //     true ? Border.all(color: Colors.yellowAccent,width: 4): null,
                                    gradient: publicPosts[index].addMeInFashionWeek == true ? LinearGradient(
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
                                          Colors.orange,
                                          Colors.orange
                                        ]),),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: publicPosts[index].userName == name ? () {
                                            widget.navigateToPageWithFriendArguments(30,publicPosts[index].userid,publicPosts[index].userName);
                                          } : (){
                                            widget.navigateToPageWithFriendArguments(30,publicPosts[index].userid,publicPosts[index].userName);
                                          },
                                          child: Padding(
                                            padding:
                                            const EdgeInsets.all(4.0),
                                            child: Row(
                                              children: [
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                if(publicPosts[index].userid == id) GestureDetector(
                                                  onTap:(publicPosts[index].recent_stories!.length <= 0) ? (){
                                                    widget.navigateToPageWithFriendArguments(30,publicPosts[index].userid,publicPosts[index].userName);
                                                  }: (){
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                      storyList: publicPosts[index].recent_stories!,
                                                    ))).then((value){
                                                      getFavourites();
                                                      getPublicPosts();
                                                      getMyTodayStories();
                                                      getAllPublicStories();
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                        // border: Border.all(
                                                        //     width: 1.5,
                                                        //     color:
                                                        //     Colors.transparent),
                                                        gradient: (publicPosts[index].recent_stories!.length <= 0) ? null : (publicPosts[index].recent_stories!.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.topRight,
                                                            stops: const [0.0, 0.7],
                                                            tileMode: TileMode.clamp,
                                                            colors: <Color>[
                                                              Colors.grey,
                                                              Colors.grey,
                                                            ]) :
                                                        (publicPosts[index].close_friends!.contains(int.parse(id)) == true ?
                                                        (publicPosts[index].recent_stories!.any((story) => story.close_friends_only == true) ? LinearGradient(
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
                                                      padding: const EdgeInsets.all(2.0),
                                                      child: Container(
                                                        height: 40,
                                                        width: 40,
                                                        decoration: BoxDecoration(
                                                            color: Colors.transparent,
                                                            borderRadius: const BorderRadius.all(Radius.circular(120))
                                                        ),
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(2.0),
                                                          child: ClipRRect(
                                                            borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                            child: CachedNetworkImage(
                                                              imageUrl: publicPosts[index].userPic,
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
                                                  ),
                                                ),
                                                if(publicPosts[index].userid != id && myList1.contains(int.parse(publicPosts[index].userid)) == false) publicPosts[index].show_stories_to_non_friends == true ? GestureDetector(
                                                  onTap:(publicPosts[index].recent_stories!.length <= 0) ? (){
                                                    widget.navigateToPageWithFriendArguments(30,publicPosts[index].userid,publicPosts[index].userName);
                                                  }: (){
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                      storyList: publicPosts[index].recent_stories!,
                                                    ))).then((value){
                                                      getFavourites();
                                                      getPosts(1);
                                                      getMyTodayStories();
                                                      getAllStories();
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                        // border: Border.all(
                                                        //     width: 1.5,
                                                        //     color:
                                                        //     Colors.transparent),
                                                        gradient: (publicPosts[index].recent_stories!.length <= 0) ? null : (publicPosts[index].recent_stories!.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.topRight,
                                                            stops: const [0.0, 0.7],
                                                            tileMode: TileMode.clamp,
                                                            colors: <Color>[
                                                              Colors.grey,
                                                              Colors.grey,
                                                            ]) :
                                                        (publicPosts[index].close_friends!.contains(int.parse(id)) == true ?
                                                        (publicPosts[index].recent_stories!.any((story) => story.close_friends_only == true) ? LinearGradient(
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
                                                      padding: const EdgeInsets.all(2.0),
                                                      child: Container(
                                                        height: 40,
                                                        width: 40,
                                                        decoration: BoxDecoration(
                                                            color: Colors.transparent,
                                                            borderRadius: const BorderRadius.all(Radius.circular(120))
                                                        ),
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(2.0),
                                                          child: ClipRRect(
                                                            borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                            child: CachedNetworkImage(
                                                              imageUrl: publicPosts[index].userPic,
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
                                                  ),
                                                ) : (
                                                    (publicPosts[index].fanList!.contains(int.parse(id)) == true || publicPosts[index].followList!.contains(int.parse(id)) == true) ?
                                                    GestureDetector(
                                                      onTap:(publicPosts[index].recent_stories!.length <= 0) ? (){
                                                        widget.navigateToPageWithFriendArguments(30,publicPosts[index].userid,publicPosts[index].userName);
                                                      }: (){
                                                        Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                          storyList: publicPosts[index].recent_stories!,
                                                        ))).then((value){
                                                          getFavourites();
                                                          getPublicPosts();
                                                          getMyTodayStories();
                                                          getAllPublicStories();
                                                        });
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                            // border: Border.all(
                                                            //     width: 1.5,
                                                            //     color:
                                                            //     Colors.transparent),
                                                            gradient: (publicPosts[index].recent_stories!.length <= 0) ? null : (publicPosts[index].recent_stories!.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                                begin: Alignment.topLeft,
                                                                end: Alignment.topRight,
                                                                stops: const [0.0, 0.7],
                                                                tileMode: TileMode.clamp,
                                                                colors: <Color>[
                                                                  Colors.grey,
                                                                  Colors.grey,
                                                                ]) :
                                                            (publicPosts[index].close_friends!.contains(int.parse(id)) == true ?
                                                            (publicPosts[index].recent_stories!.any((story) => story.close_friends_only == true) ? LinearGradient(
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
                                                          padding: const EdgeInsets.all(2.0),
                                                          child: Container(
                                                            height: 40,
                                                            width: 40,
                                                            decoration: BoxDecoration(
                                                                color: Colors.transparent,
                                                                borderRadius: const BorderRadius.all(Radius.circular(120))
                                                            ),
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(2.0),
                                                              child: ClipRRect(
                                                                borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                                child: CachedNetworkImage(
                                                                  imageUrl: publicPosts[index].userPic,
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
                                                      ),
                                                    ):
                                                    GestureDetector(
                                                      onTap: (){
                                                        widget.navigateToPageWithFriendArguments(30,publicPosts[index].userid,publicPosts[index].userName);
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                              width: 1.5,
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
                                                              imageUrl: publicPosts[index].userPic,
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
                                                if(myList1.contains(int.parse(publicPosts[index].userid)) == true) GestureDetector(
                                                  onTap:(){
                                                    widget.navigateToPageWithFriendArguments(30,publicPosts[index].userid,publicPosts[index].userName);
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                        border: Border.all(
                                                            width: 1.5,
                                                            color:
                                                            Colors.transparent),
                                                        gradient: LinearGradient(
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.topRight,
                                                            stops: const [0.0, 0.7],
                                                            tileMode: TileMode.clamp,
                                                            colors: <Color>[
                                                              Colors.grey,
                                                              Colors.grey,
                                                            ])
                                                    ),
                                                    child: Container(
                                                      height: 40,
                                                      width: 40,
                                                      child: ClipRRect(
                                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                        child: CachedNetworkImage(
                                                          imageUrl: publicPosts[index].userPic,
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
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Text(
                                                  publicPosts[index].userName,
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
                                      if(publicPosts[index].isPrivate == false || (publicPosts[index].fanList ?? []).contains(int.parse(id)) == true) idolIdList.contains(int.parse(publicPosts[index].userid)) == true
                                          ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent, // Makes the background transparent
                                          shadowColor: Colors.transparent,    // Removes the shadow
                                          side: BorderSide(
                                            color: ascent,               // Sets the border color
                                            width: 2,                         // Sets the border width
                                          ),
                                        ),
                                        onPressed: () {
                                          removeFan(publicPosts[index].userid);
                                        },
                                        child: const Text(
                                          "Unfan",
                                          style: TextStyle(color: ascent, fontFamily: Poppins),
                                        ),
                                      )
                                          : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent, // Makes the background transparent
                                          shadowColor: Colors.transparent,    // Removes the shadow
                                          side: BorderSide(
                                            color: ascent,               // Sets the border color
                                            width: 2,                         // Sets the border width
                                          ),
                                        ),
                                        onPressed: () {
                                          addFan(id, publicPosts[index].userid);
                                        },
                                        child: const Text(
                                          "Fan",
                                          style: TextStyle(color: ascent, fontFamily: Poppins),
                                        ),
                                      ),
                                      if(publicPosts[index].isPrivate == true && (publicPosts[index].fanList ?? []).contains(int.parse(id)) == false) WidgetAnimator(SizedBox(
                                        height: 47,
                                        child: WidgetAnimator(
                                            GestureDetector(
                                              onTap: () {
                                                if(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == publicPosts[index].id) == false){
                                                  print("fan");
                                                  sendFanRequest(id,publicPosts[index].id);
                                                  // showDialog(
                                                  //   context: context,
                                                  //   builder: (context) => AlertDialog(
                                                  //     backgroundColor: primary,
                                                  //     title: Text("Fan request ${publicPosts[index].userName}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                                  //     content: Text("Are you sure you want to send a fan request to ${publicPosts[index].userName}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
                                                  //           sendFanRequest(id,publicPosts[index].id);
                                                  //         },
                                                  //       ),
                                                  //     ],
                                                  //   ),
                                                  // );
                                                }else if(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == publicPosts[index].id) == true) {
                                                  print("unfan");
                                                  getRequestsForCancel(publicPosts[index].id);
                                                  // showDialog(
                                                  //   context: context,
                                                  //   builder: (context) => AlertDialog(
                                                  //     backgroundColor: primary,
                                                  //     title: Text("Cancel request ${publicPosts[index].userName}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                                  //     content: Text("Are you sure you want to cancel fan request to ${publicPosts[index].userName}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
                                                  //           getRequestsForCancel(publicPosts[index].id);
                                                  //         },
                                                  //       ),
                                                  //     ],
                                                  //   ),
                                                  // );
                                                  //removeFan(widget.id);
                                                }
                                                //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                                              },
                                              child: Card(
                                                shape: const RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(5))
                                                ),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  height: 40,
                                                  width: MediaQuery.of(context).size.width * 0.16,
                                                  decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.topRight,
                                                          stops: const [0.0, 0.99],
                                                          tileMode: TileMode.clamp,
                                                          colors: requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == publicPosts[index].id) == true ? [
                                                            Colors.grey,
                                                            Colors.grey
                                                          ] : <Color>[
                                                            secondary,
                                                            primary,
                                                          ]),
                                                      borderRadius: const BorderRadius.all(Radius.circular(5))
                                                  ),
                                                  child: requestLoader2 == true ? const SpinKitCircle(color: ascent, size: 20,) : Text(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == publicPosts[index].id) == true ? 'Pending' :'Fan Request',style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      fontFamily: Poppins
                                                  ),),
                                                ),
                                              ),
                                            )
                                        ),
                                      )),
                                      PopupMenuButton(
                                          icon: const Icon(
                                            Icons.more_horiz,
                                            color: ascent,
                                          ),
                                          onSelected: (value) {
                                            if (value == 0) {
                                              //widget.onNavigate(28,publicPosts[index].userid);
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          ReportScreen(
                                                              reportedID:
                                                              publicPosts[index]
                                                                  .userid)));
                                            }
                                            if (value == 1) {
                                              description.text =
                                                  publicPosts[index]
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
                                                                      publicPosts[index]
                                                                          .id,index);
                                                                },
                                                              ),
                                                            ],
                                                          );
                                                        }),
                                              );
                                            }
                                            if (value == 2) {
                                              updateComments(publicPosts[index].id,index,publicPosts[index].isCommentEnabled!);
                                            }
                                            if (value == 3) {
                                              updateLikes(publicPosts[index].id,index,publicPosts[index].isLikeEnabled!);
                                            }
                                            if (value == 4) {
                                              if(publicPosts[index].thumbnail == "Male"){
                                                genderIndex = 0;
                                                gender = "Male";
                                              }
                                              else if(publicPosts[index].thumbnail == "Female"){
                                                genderIndex = 1;
                                                gender = "Female";
                                              }
                                              else if(publicPosts[index].thumbnail == "Unisex"){
                                                genderIndex = 2;
                                                gender = "Unisex";
                                              }
                                              else if(publicPosts[index].thumbnail == "Other"){
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
                                                                SizedBox(height: 10,),
                                                                Row(
                                                                  children: [
                                                                    SizedBox(width: 20,),
                                                                    Text("Update the gender of your style for\nbetter visibility in the feed.",style: TextStyle(fontSize: 14,fontFamily: Poppins),)
                                                                  ],
                                                                ),
                                                                SizedBox(height: 10,),
                                                                // GridView Section
                                                                Container(
                                                                  padding: EdgeInsets.all(16),
                                                                  height: 160, // Adjust height as per content
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
                                                                          height: 40,
                                                                          decoration: BoxDecoration(
                                                                              color: genderIndex == index1 ? primary : Colors.transparent,
                                                                              borderRadius: BorderRadius.circular(8),
                                                                              border: Border.all(
                                                                                color: genderIndex == index1 ? Colors.transparent : primary,
                                                                              )
                                                                          ),
                                                                          child: Center(
                                                                            child: Text(
                                                                              '${genders[index1]}',
                                                                              style: TextStyle(color: genderIndex == index1 ? ascent : primary,fontFamily: Poppins,fontSize: 16),
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
                                                                        updateGender(publicPosts[index].id, index);
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
                                                    Icon(Icons.report,size: 30,),
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
                                              if (publicPosts[index].userid == id) PopupMenuItem(
                                                value: 1,
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit,size: 30),
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
                                              if (publicPosts[index].userid == id) updateBool == true ? PopupMenuItem(child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  SpinKitCircle(color: primary,size: 20,),
                                                ],
                                              )) :
                                              PopupMenuItem(
                                                value: 2,
                                                child: Row(
                                                  children: [
                                                    publicPosts[index].isCommentEnabled == false ? Icon(FontAwesomeIcons
                                                        .comment,size: 24):Icon(FontAwesomeIcons.commentSlash,size: 23),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Text(
                                                      publicPosts[index].isCommentEnabled == false ? " Enable comments" : " Disable comments",
                                                      style: TextStyle(
                                                        fontFamily: Poppins,),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (publicPosts[index].userid == id) updateBool == true ? PopupMenuItem(child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  SpinKitCircle(color: primary,size: 20,),
                                                ],
                                              )) :
                                              PopupMenuItem(
                                                value: 3,
                                                child: Row(
                                                  children: [
                                                    publicPosts[index].addMeInFashionWeek == true ?
                                                    (publicPosts[index].isLikeEnabled == false ? Icon(Icons.favorite):Stack(
                                                      children: [
                                                        Icon(Icons.favorite_border,size: 30,),
                                                        Positioned(
                                                          top: 2,
                                                          left: 1,
                                                          child: Icon(FontAwesomeIcons.slash,size: 22,),
                                                        ),
                                                      ],
                                                    )):
                                                    (publicPosts[index].isLikeEnabled == false ? Icon(FontAwesomeIcons.star,size: 28,):
                                                    Image.asset(
                                                      "assets/fcut.png",
                                                      height:31,
                                                      width: 31,
                                                    )),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Text(
                                                      publicPosts[index].isLikeEnabled == false ? "Show like count" : "Hide like count",
                                                      style: TextStyle(
                                                        fontFamily: Poppins,),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if(publicPosts[index].userid == id) PopupMenuItem(
                                                value: 4,
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.person,size: 30),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Text(
                                                      "Update style gender",
                                                      style: TextStyle(
                                                        fontFamily: Poppins,),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ];
                                          }
                                          )
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 550,
                                  width: double.infinity,
                                  child: CarouselSlider(
                                    carouselController: _controller,
                                    options: CarouselOptions(
                                        viewportFraction: 1,
                                        enableInfiniteScroll: false,
                                        height: 550.0,
                                        autoPlay: false,
                                        enlargeCenterPage: true,
                                        aspectRatio: 2.0,
                                        initialPage: 0,
                                        onPageChanged:
                                            (ind, reason) {
                                          setState(() {
                                            _current = ind;
                                          });
                                        }),
                                    items: publicPosts[index]
                                        .images
                                        .map((i) {
                                      return i["type"] == "video"
                                          ? Container(
                                          color: Colors.black,
                                          child:Text("Video"),)
                                          // child: UsingVideoControllerExample(
                                          //   path: i["video"],
                                          // ))
                                          : GestureDetector(
                                        onTap: (){
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return Dialog(
                                                backgroundColor: Colors.black54,
                                                insetPadding: EdgeInsets.all(0), // Remove all padding
                                                child: Container(
                                                  color: Colors.black54,
                                                  width: MediaQuery.of(context).size.width,  // 100% of screen width
                                                  height: MediaQuery.of(context).size.height * 0.8,  // 90% of screen height
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8.0),  // Optional: add rounded corners
                                                      child: InteractiveViewer(
                                                          boundaryMargin: EdgeInsets.all(0),  // No margins around the boundary
                                                          minScale: 0.1,  // Minimum zoom out scale
                                                          maxScale: 4.0,
                                                          child:CachedNetworkImage(
                                                            imageUrl: i["image"],
                                                            imageBuilder: (context, imageProvider) =>
                                                                Container(
                                                                  height: MediaQuery.of(context).size.height * 0.9,
                                                                  width: MediaQuery.of(context).size.width,
                                                                  decoration:
                                                                  BoxDecoration(
                                                                    image: DecorationImage(
                                                                      image: imageProvider,
                                                                      fit: BoxFit
                                                                          .contain,
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
                                                                  height: MediaQuery.of(context).size.height * 0.9,
                                                                  width: MediaQuery.of(context).size.width,
                                                                  decoration:
                                                                  BoxDecoration(
                                                                    image: DecorationImage(
                                                                        image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                                                                            .image,
                                                                        fit: BoxFit
                                                                            .fill),
                                                                  ),
                                                                ),
                                                          )
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );

                                        },
                                        child: CachedNetworkImage(
                                          imageUrl: i["image"],
                                          imageBuilder: (context, imageProvider) =>
                                              Container(
                                                height: MediaQuery.of(context).size.height,
                                                width: MediaQuery.of(context).size.width,
                                                decoration:
                                                BoxDecoration(
                                                  image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit
                                                        .fill,
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
                                                height: MediaQuery.of(context).size.height * 0.9,
                                                width: MediaQuery.of(context).size.width,
                                                decoration:
                                                BoxDecoration(
                                                  image: DecorationImage(
                                                      image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                                                          .image,
                                                      fit: BoxFit
                                                          .fill),
                                                ),
                                              ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                publicPosts[index].images.length == 1
                                    ? const SizedBox()
                                    : Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: publicPosts[index]
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
                                    child: publicPosts[index].userid == id
                                        ? Row(
                                      children: [
                                        SizedBox(width: 10,),
                                        publicPosts[index].addMeInFashionWeek == true
                                            ? publicPosts[index].mylike != "like" ? IconButton(
                                            onPressed: () {},
                                            icon: publicPosts[index].isLikeEnabled == true ? Icon(
                                              Icons.favorite,
                                              size: 26,
                                              color: publicPosts[index].isLikeEnabled == true ? Colors.red : Colors.grey,
                                            ):Stack(
                                              children: [
                                                Icon(Icons.favorite,size: 30,color: publicPosts[index].isLikeEnabled == true ? Colors.red : Colors.grey,),
                                                Positioned(
                                                  top: 2,
                                                  left: 1,
                                                  child: Icon(FontAwesomeIcons.slash,size: 22,color: publicPosts[index].isLikeEnabled == true ? Colors.red : Colors.grey,),
                                                ),
                                              ],
                                            ))
                                            : GestureDetector(
                                          onTap:(){
                                            widget.navigateToPageWithPostArguments(29,publicPosts[index].id);
                                          },
                                          child: publicPosts[index].isLikeEnabled == true ? Icon(
                                            FontAwesomeIcons
                                                .heart,
                                            color: publicPosts[index].isLikeEnabled == true ? Colors.red : Colors.grey,
                                            size: 26,
                                          ):Stack(
                                            children: [
                                              Icon(Icons.favorite_border,size: 30,color: publicPosts[index].isLikeEnabled == true ? Colors.red : Colors.grey,),
                                              Positioned(
                                                top: 2,
                                                left: 1,
                                                child: Icon(FontAwesomeIcons.slash,size: 22,color: publicPosts[index].isLikeEnabled == true ? Colors.red : Colors.grey,),
                                              ),
                                            ],
                                          ),
                                        )
                                            : publicPosts[index].mylike !=
                                            "like"
                                            ? GestureDetector(
                                            onTap:(){
                                              widget.navigateToPageWithPostArguments(29,publicPosts[index].id);
                                              // if(posts[index].isLikeEnabled == true) {
                                              //   widget.navigateToPageWithPostArguments(29,posts[index].id);
                                              //   // Navigator.push(
                                              //   //     context,
                                              //   //     MaterialPageRoute(
                                              //   //       builder:
                                              //   //           (
                                              //   //           context) =>
                                              //   //           PostLikeUserScreen(
                                              //   //               fashionId: posts[index]
                                              //   //                   .id),
                                              //   //     ));
                                              // }else {
                                              //   showModalBottomSheet(
                                              //       shape: RoundedRectangleBorder(
                                              //           borderRadius: BorderRadius
                                              //               .only(
                                              //               topLeft: Radius
                                              //                   .circular(
                                              //                   10),
                                              //               topRight: Radius
                                              //                   .circular(
                                              //                   10)
                                              //           )
                                              //       ),
                                              //       isScrollControlled: true,
                                              //       context: context,
                                              //       builder: (ctx) {
                                              //         return WillPopScope(
                                              //           onWillPop: () async {
                                              //             Navigator.pop(
                                              //                 ctx);
                                              //             return false; // Prevents the default back button behavior
                                              //           },
                                              //           child: DraggableScrollableSheet(
                                              //               expand: false,
                                              //               // Ensures it doesn't expand fully by default
                                              //               initialChildSize: 0.7,
                                              //               // Half screen by default
                                              //               minChildSize: 0.3,
                                              //               // Minimum height
                                              //               maxChildSize: 1.0,
                                              //               builder: (
                                              //                   BuildContext context1,
                                              //                   ScrollController scrollController) {
                                              //                 return Column(
                                              //                   children: [
                                              //                     const SizedBox(
                                              //                       height: 15,
                                              //                     ),
                                              //                     Row(
                                              //                       mainAxisAlignment: MainAxisAlignment.center,
                                              //                       children: [
                                              //                         Container(
                                              //                           height: 3,
                                              //                           width: 40,
                                              //                           decoration: BoxDecoration(
                                              //                               color: Colors.grey,
                                              //                               borderRadius: BorderRadius.all(Radius.circular(20))
                                              //                           ),
                                              //                           child: Text(""),
                                              //                         )
                                              //                       ],
                                              //                     ),
                                              //                     Row(
                                              //                       mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              //                       children: [
                                              //                         PopupMenuButton(
                                              //                             icon: const Icon(Icons.tune,color: Colors.transparent,),
                                              //                             onSelected: null,
                                              //                             itemBuilder: (BuildContext bc) {
                                              //                               return [
                                              //                               ];
                                              //                             }),
                                              //                         Text("Likes",style: TextStyle(color: ascent,fontSize: 13,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                              //                         PopupMenuButton(
                                              //                             icon: const Icon(Icons.tune,color: Colors.transparent,),
                                              //                             onSelected: null,
                                              //                             itemBuilder: (BuildContext bc) {
                                              //                               return [
                                              //                               ];
                                              //                             }),
                                              //                       ],
                                              //                     ),
                                              //                     Divider(color: Colors.grey,),
                                              //                     Column(
                                              //                       mainAxisAlignment: MainAxisAlignment.center,
                                              //                       crossAxisAlignment: CrossAxisAlignment.center,
                                              //                       children: [
                                              //                         SizedBox(height: MediaQuery.of(context).size.height * 0.17,),
                                              //                         Icon(Icons.heart_broken,color: ascent,size: 50,),
                                              //                         SizedBox(height: 10,),
                                              //                         Container(
                                              //                           width:MediaQuery.of(context).size.width * 0.5,
                                              //                           child: Center(
                                              //                             child: Text("The user has chosen to disable likes on this post.",style: TextStyle(
                                              //                                 fontFamily: Poppins,
                                              //                                 fontSize: 12
                                              //                             ),),
                                              //                           ),
                                              //                         )
                                              //                       ],
                                              //                     )
                                              //                   ],
                                              //                 );
                                              //               }
                                              //           ),
                                              //         );
                                              //       }).then((value) {
                                              //     getAllStories();
                                              //     getMyTodayStories();
                                              //   });
                                              // }
                                            },
                                            child: publicPosts[index].isLikeEnabled == true ? Icon(
                                              FontAwesomeIcons.star,
                                              size: 26,
                                              color: publicPosts[index].isLikeEnabled == true ? Colors.orange : Colors.grey,
                                              // size: 50,
                                            ):Image.asset(
                                              "assets/fcut1.png",
                                              height:30,
                                              width: 30,
                                            ))
                                            : GestureDetector(
                                          onDoubleTap: () {},
                                          onTap:(){
                                            widget.navigateToPageWithPostArguments(29,publicPosts[index].id);
                                            // if(posts[index].isLikeEnabled == true) {
                                            //
                                            //   // Navigator.push(
                                            //   //     context,
                                            //   //     MaterialPageRoute(
                                            //   //       builder:
                                            //   //           (
                                            //   //           context) =>
                                            //   //           PostLikeUserScreen(
                                            //   //               fashionId: posts[index]
                                            //   //                   .id),
                                            //   //     ));
                                            // }else {
                                            //   showModalBottomSheet(
                                            //       shape: RoundedRectangleBorder(
                                            //           borderRadius: BorderRadius
                                            //               .only(
                                            //               topLeft: Radius
                                            //                   .circular(
                                            //                   10),
                                            //               topRight: Radius
                                            //                   .circular(
                                            //                   10)
                                            //           )
                                            //       ),
                                            //       isScrollControlled: true,
                                            //       context: context,
                                            //       builder: (ctx) {
                                            //         return WillPopScope(
                                            //           onWillPop: () async {
                                            //             Navigator.pop(
                                            //                 ctx);
                                            //             return false; // Prevents the default back button behavior
                                            //           },
                                            //           child: DraggableScrollableSheet(
                                            //               expand: false,
                                            //               // Ensures it doesn't expand fully by default
                                            //               initialChildSize: 0.7,
                                            //               // Half screen by default
                                            //               minChildSize: 0.3,
                                            //               // Minimum height
                                            //               maxChildSize: 1.0,
                                            //               builder: (
                                            //                   BuildContext context1,
                                            //                   ScrollController scrollController) {
                                            //                 return Column(
                                            //                   children: [
                                            //                     const SizedBox(
                                            //                       height: 15,
                                            //                     ),
                                            //                     Row(
                                            //                       mainAxisAlignment: MainAxisAlignment.center,
                                            //                       children: [
                                            //                         Container(
                                            //                           height: 3,
                                            //                           width: 40,
                                            //                           decoration: BoxDecoration(
                                            //                               color: Colors.grey,
                                            //                               borderRadius: BorderRadius.all(Radius.circular(20))
                                            //                           ),
                                            //                           child: Text(""),
                                            //                         )
                                            //                       ],
                                            //                     ),
                                            //                     Row(
                                            //                       mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            //                       children: [
                                            //                         PopupMenuButton(
                                            //                             icon: const Icon(Icons.tune,color: Colors.transparent,),
                                            //                             onSelected: null,
                                            //                             itemBuilder: (BuildContext bc) {
                                            //                               return [
                                            //                               ];
                                            //                             }),
                                            //                         Text("Likes",style: TextStyle(color: ascent,fontSize: 13,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                            //                         PopupMenuButton(
                                            //                             icon: const Icon(Icons.tune,color: Colors.transparent,),
                                            //                             onSelected: null,
                                            //                             itemBuilder: (BuildContext bc) {
                                            //                               return [
                                            //                               ];
                                            //                             }),
                                            //                       ],
                                            //                     ),
                                            //                     Divider(color: Colors.grey,),
                                            //                     Column(
                                            //                       mainAxisAlignment: MainAxisAlignment.center,
                                            //                       crossAxisAlignment: CrossAxisAlignment.center,
                                            //                       children: [
                                            //                         SizedBox(height: MediaQuery.of(context).size.height * 0.17,),
                                            //                         Icon(Icons.heart_broken,color: ascent,size: 50,),
                                            //                         SizedBox(height: 10,),
                                            //                         Container(
                                            //                           width:MediaQuery.of(context).size.width * 0.5,
                                            //                           child: Center(
                                            //                             child: Text("The user has chosen to disable likes on this post.",style: TextStyle(
                                            //                                 fontFamily: Poppins,
                                            //                                 fontSize: 12
                                            //                             ),),
                                            //                           ),
                                            //                         )
                                            //                       ],
                                            //                     )
                                            //                   ],
                                            //                 );
                                            //               }
                                            //           ),
                                            //         );
                                            //       }).then((value) {
                                            //     getAllStories();
                                            //     getMyTodayStories();
                                            //   });
                                            // }
                                          },
                                          child: publicPosts[index].isLikeEnabled == true ? Icon(
                                            FontAwesomeIcons.star,
                                            size: 26,
                                            color: publicPosts[index].isLikeEnabled == true ? Colors.orange : Colors.grey,
                                          ): Image.asset(
                                            "assets/fcut.png",
                                            height:30,
                                            width: 30,
                                          )),
                                        if(id == publicPosts[index].userid) publicPosts[index].likeCount == "0"
                                            ?
                                        const SizedBox()
                                            : Text(" ${publicPosts[index].likeCount}",style: TextStyle(fontFamily: Poppins,),),
                                        SizedBox(width: 10,),
                                        GestureDetector(
                                          onVerticalDragUpdate: (details) {
                                            // Dismiss the keyboard when the user drags the bottom sheet
                                            print("simple enter");
                                            if (details.delta.dy < 0 || details.delta.dy > 0) {
                                              print("enter comment if");
                                              FocusScope.of(context).unfocus();
                                            }
                                          },
                                          onTap:(){
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
                                                      print("Closed 1");
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
                                                      child: GestureDetector(
                                                        onVerticalDragUpdate: (details) {
                                                          // Dismiss the keyboard when the user drags the bottom sheet
                                                          print("simple enter");
                                                          if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                            print("enter comment if");
                                                            FocusScope.of(context).unfocus();
                                                          }
                                                        },
                                                        child: DraggableScrollableSheet(
                                                            controller: _draggableController,
                                                            expand: false,
                                                            // Ensures it doesn't expand fully by default
                                                            initialChildSize: isExpendedComment ? 1.0 : 0.7,
                                                            // Half screen by default
                                                            minChildSize: 0.3,
                                                            // Minimum height
                                                            maxChildSize: 1.0,
                                                            builder: (BuildContext context1, ScrollController scrollController) {
                                                              return GestureDetector(
                                                                onVerticalDragUpdate: (details) {
                                                                  // Dismiss the keyboard when the user drags the bottom sheet
                                                                  print("simple enter");
                                                                  if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                                    print("enter comment if");
                                                                    FocusScope.of(context).unfocus();
                                                                  }
                                                                },
                                                                child: CommentScreen(
                                                                    postid: publicPosts[index]
                                                                        .id,
                                                                    pic: publicPosts[index]
                                                                        .userPic,
                                                                    scrollController: scrollController,
                                                                    context1: context1,
                                                                    isEventPost: publicPosts[index].addMeInFashionWeek!,
                                                                    userID: publicPosts[index].userid,
                                                                    draggableController: _draggableController,
                                                                  textFieldFocusNode: _textFieldFocusNode,
                                                                ),
                                                              );
                                                            }
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).then((value) {
                                              getAllStories();
                                              getMyTodayStories();
                                              isExpendedComment = false;
                                            });
                                          },
                                          child:publicPosts[index].isCommentEnabled == true ? Icon(
                                            FontAwesomeIcons.comment,
                                            size: 26,
                                            color: publicPosts[index].isCommentEnabled == true ? Colors.white : Colors.grey,
                                          ): Icon(
                                            FontAwesomeIcons.commentSlash,
                                            size: 26,
                                            color: publicPosts[index].isCommentEnabled == true ? Colors.white : Colors.grey,
                                          ),
                                        ),
                                        if(id == publicPosts[index].userid) publicPosts[index].commentCount == "0" ? Text("") : Text(" ${publicPosts[index].commentCount}",style: TextStyle(fontFamily: Poppins,),),
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
                                                            String imageUrl = publicPosts[index].images[0]['image']==null?publicPosts[index].images[0]['video'].toString():publicPosts[index].images[0]['image'].toString();
                                                            Navigator.pop(context);
                                                            _showFriendsList(imageUrl,publicPosts[index].id);

                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: const Icon(Icons.share),
                                                          title: const Text(
                                                            'Others',
                                                            style: TextStyle(fontFamily: Poppins,),
                                                          ),
                                                          onTap: () async{
                                                            String imageUrl = publicPosts[index].images[0]['image']==null?publicPosts[index].images[0]['video'].toString():publicPosts[index].images[0]['image'].toString();
                                                            debugPrint("image link to share: $imageUrl");
                                                            await Share.share("${publicPosts[index].description.toString()}\n\n https://fashiontime-28e3a.web.app/details/${publicPosts[index].id}"
                                                            );
                                                          },
                                                        ),

                                                      ],
                                                    );
                                                  }).then((value){
                                                getAllStories();
                                                getMyTodayStories();
                                              });
                                            },
                                            icon: const Icon(
                                              FontAwesomeIcons.share,
                                              size: 26,
                                            )
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                            onTap: () {
                                              saveStyle(publicPosts[index].id);
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
                                        publicPosts[index].addMeInFashionWeek == true
                                            ? publicPosts[index].mylike != "like" ? Icon(
                                              Icons.favorite,
                                              color: publicPosts[index].isLikeEnabled == true ? Colors.red: Colors.grey,
                                              size: 26,
                                            )
                                            : GestureDetector(
                                          onTap:(){
                                            if(publicPosts[index].isLikeEnabled == true) {
                                              widget.navigateToPageWithPostArguments(29,publicPosts[index].id);
                                              // Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //       builder:
                                              //           (
                                              //           context) =>
                                              //           PostLikeUserScreen(
                                              //               fashionId: posts[index]
                                              //                   .id),
                                              //     ));
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
                                                                    SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                                                                    Stack(
                                                                      children: [
                                                                        Icon(publicPosts[index].addMeInFashionWeek == true ? Icons.favorite_border : Icons.star_border,size: 90,),
                                                                        Positioned(
                                                                          top: 7,
                                                                          left: 2,
                                                                          child: Icon(FontAwesomeIcons.slash,size: 60,),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    //Image.asset(publicPosts[index].addMeInFashionWeek == true ? "assets/smile.png" : "assets/starbackT.png",height: 200,width: 200),
                                                                    SizedBox(height: 10,),
                                                                    Container(
                                                                      width:MediaQuery.of(context).size.width * 0.5,
                                                                      child: Center(
                                                                        child: Text("The user has chosen to hide the likes on this post.",style: TextStyle(
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
                                                getAllPublicStories();
                                                getMyTodayStories();
                                                getPublicPosts();
                                              });
                                            }
                                          },
                                          child: Icon(
                                            FontAwesomeIcons
                                                .heart,
                                            color: publicPosts[index].isLikeEnabled == true ? Colors.red : Colors.grey,
                                            size: 26,
                                          ),
                                        )
                                            : publicPosts[index].mylike !=
                                            "like"
                                            ? GestureDetector(
                                            onTap:(){
                                              if(publicPosts[index].isLikeEnabled == true) {
                                                widget.navigateToPageWithPostArguments(29,publicPosts[index].id);
                                                // Navigator.push(
                                                //     context,
                                                //     MaterialPageRoute(
                                                //       builder:
                                                //           (
                                                //           context) =>
                                                //           PostLikeUserScreen(
                                                //               fashionId: posts[index]
                                                //                   .id),
                                                //     ));
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
                                                                      SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                                                                      Stack(
                                                                        children: [
                                                                          Icon(publicPosts[index].addMeInFashionWeek == true ? Icons.favorite_border : Icons.star_border,size: 90,),
                                                                          Positioned(
                                                                            top: 7,
                                                                            left: 2,
                                                                            child: Icon(FontAwesomeIcons.slash,size: 60,),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      //Image.asset(publicPosts[index].addMeInFashionWeek == true ? "assets/smile.png" : "assets/starbackT.png",height: 200,width: 200),
                                                                      SizedBox(height: 10,),
                                                                      Container(
                                                                        width:MediaQuery.of(context).size.width * 0.5,
                                                                        child: Center(
                                                                          child: Text("The user has chosen to hide the likes on this post.",style: TextStyle(
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
                                                  getAllPublicStories();
                                                  getMyTodayStories();
                                                  getPublicPosts();
                                                });
                                              }
                                            },
                                            child: Icon(
                                              FontAwesomeIcons.star,
                                              size: 26,
                                              color: publicPosts[index].isLikeEnabled == true ? Colors.orange : Colors.grey,
                                            ))
                                            : GestureDetector(
                                          onDoubleTap: () {},
                                          onTap:(){
                                            if(publicPosts[index].isLikeEnabled == true) {
                                              widget.navigateToPageWithPostArguments(29,publicPosts[index].id);
                                              // Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //       builder:
                                              //           (
                                              //           context) =>
                                              //           PostLikeUserScreen(
                                              //               fashionId: posts[index]
                                              //                   .id),
                                              //     ));
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
                                                                    SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                                                                    Stack(
                                                                      children: [
                                                                        Icon(publicPosts[index].addMeInFashionWeek == true ? Icons.favorite_border : Icons.star_border,size: 90,),
                                                                        Positioned(
                                                                          top: 7,
                                                                          left: 2,
                                                                          child: Icon(FontAwesomeIcons.slash,size: 60,),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    //Image.asset(publicPosts[index].addMeInFashionWeek == true ? "assets/smile.png" : "assets/starbackT.png",height: 200,width: 200),
                                                                    SizedBox(height: 10,),
                                                                    Container(
                                                                      width:MediaQuery.of(context).size.width * 0.5,
                                                                      child: Center(
                                                                        child: Text("The user has chosen to hide the likes on this post.",style: TextStyle(
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
                                                getAllPublicStories();
                                                getMyTodayStories();
                                                getPublicPosts();
                                              });
                                            }
                                          },
                                          child:
                                          Icon(
                                              FontAwesomeIcons.star,
                                              size: 26,
                                              color: publicPosts[index].isLikeEnabled == true ? Colors.orange : Colors.grey),
                                        ),
                                        if(id == publicPosts[index].userid || publicPosts[index].isLikeEnabled == true) publicPosts[index].likeCount == "0"
                                            ?
                                        const SizedBox()
                                            : (publicPosts[index].isLikeEnabled == false ?
                                        Text("",style: TextStyle(fontFamily: Poppins,color: ascent),): Text(" ${publicPosts[index].likeCount}",style: TextStyle(fontFamily: Poppins,),)),
                                        SizedBox(width: 10,),
                                        GestureDetector(
                                          onVerticalDragUpdate: (details) {
                                            // Dismiss the keyboard when the user drags the bottom sheet
                                            print("simple enter");
                                            if (details.delta.dy < 0 || details.delta.dy > 0) {
                                              print("enter comment if");
                                              FocusScope.of(context).unfocus();
                                            }
                                          },
                                          onTap:(){
                                            if(publicPosts[index].isCommentEnabled == true) {
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
                                                        print("Closed 2");
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
                                                        child: GestureDetector(
                                                          onVerticalDragUpdate: (details) {
                                                            // Dismiss the keyboard when the user drags the bottom sheet
                                                            print("simple enter");
                                                            if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                              print("enter comment if");
                                                              FocusScope.of(context).unfocus();
                                                            }
                                                          },
                                                          child: DraggableScrollableSheet(
                                                              controller: _draggableController,
                                                              expand: false,
                                                              // Ensures it doesn't expand fully by default
                                                              initialChildSize: isExpendedComment ? 1.0 : 0.7,
                                                              // Half screen by default
                                                              minChildSize: 0.3,
                                                              // Minimum height
                                                              maxChildSize: 1.0,
                                                              builder: (
                                                                  BuildContext context1,
                                                                  ScrollController scrollController) {
                                                                return GestureDetector(
                                                                  onVerticalDragUpdate: (details) {
                                                                    // Dismiss the keyboard when the user drags the bottom sheet
                                                                    print("simple enter");
                                                                    if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                                      print("enter comment if");
                                                                      FocusScope.of(context).unfocus();
                                                                    }
                                                                  },
                                                                  child: CommentScreen(
                                                                      postid: publicPosts[index]
                                                                          .id,
                                                                      pic: publicPosts[index]
                                                                          .userPic,
                                                                      scrollController: scrollController,
                                                                      context1: context1,
                                                                      isEventPost: publicPosts[index].addMeInFashionWeek!,
                                                                      userID: publicPosts[index].userid,
                                                                      draggableController: _draggableController,
                                                                    textFieldFocusNode: _textFieldFocusNode,
                                                                  ),
                                                                );
                                                              }
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }).then((value) {
                                                getAllPublicStories();
                                                getMyTodayStories();
                                                getPublicPosts();
                                                isExpendedComment = false;
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
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      children: [
                                                                        IconTheme(
                                                                          data: IconThemeData(color: ascent,size: 80),
                                                                          child: Icon(FontAwesomeIcons.commentSlash),
                                                                        ),
                                                                        SizedBox(width: 20,)
                                                                      ],
                                                                    ),
                                                                    SizedBox(height: 15,),
                                                                    Container(
                                                                      width:MediaQuery.of(context).size.width * 0.72,
                                                                      child: Row(
                                                                        mainAxisAlignment:MainAxisAlignment.center,
                                                                        children: [
                                                                          Text("The user has chosen to disable comments\non this post.",style: TextStyle(
                                                                              fontFamily: Poppins,
                                                                              fontSize: 12
                                                                          ),),
                                                                        ],
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
                                                getAllPublicStories();
                                                getMyTodayStories();
                                                getPublicPosts();
                                              });
                                            }
                                          },
                                          child: Icon(
                                            FontAwesomeIcons
                                                .comment,
                                            color: publicPosts[index].isCommentEnabled == true ? ascent : Colors.grey,
                                            size: 28,
                                          ),
                                        ),
                                        if(id == publicPosts[index].userid || publicPosts[index].isCommentEnabled == true) publicPosts[index].isCommentEnabled == false ?
                                        const Text("",style: TextStyle(fontFamily: Poppins,color: ascent),)
                                            :
                                        (publicPosts[index].commentCount == "0" ? Text("") : Text(" ${publicPosts[index].commentCount}",style: TextStyle(fontFamily: Poppins,),)),
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
                                                getAllStories();
                                                getMyTodayStories();
                                              });
                                            },
                                            icon: const Icon(
                                              FontAwesomeIcons.share,
                                              size: 26,
                                            )
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                            onTap: () {
                                              saveStyle(publicPosts[index].id);
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 2),
                                              child: Image.asset('assets/Frame1.png', height: 25),
                                            )),
                                        SizedBox(width: 10,)
                                      ],
                                    )
                                ),
                                publicPosts[index].description.toString().length +formatHashtags(publicPosts[index].hashtags).length >
                                    150
                                    ? Padding(
                                    padding:
                                    const EdgeInsets.all(
                                        8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        isExpanded
                                            ? GestureDetector(
                                          onTap:(){
                                            setState(() {
                                              isExpanded = !isExpanded;
                                            });
                                          },
                                          child: Container(
                                            width:MediaQuery.of(context).size.width * 0.9,
                                            child: Column(
                                              crossAxisAlignment:CrossAxisAlignment.start,
                                              children: [
                                                Text.rich(
                                                    TextSpan(
                                                        text: '${Uri.decodeComponent(publicPosts[index].userName,)} ',
                                                        style: TextStyle(
                                                            fontFamily: Poppins,
                                                            fontSize: 13,
                                                            color: primary,
                                                            fontWeight: FontWeight.bold),
                                                        children: <InlineSpan>[
                                                          TextSpan(
                                                              text: "${handleEmojis(publicPosts[index].description.substring(0, 130))}...",
                                                              style: const TextStyle(
                                                                  fontFamily: Poppins,
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.normal,
                                                                  color: ascent
                                                              )
                                                          )
                                                        ]
                                                    )
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                            : GestureDetector(
                                          onTap:(){
                                            setState(() {
                                              isExpanded = !isExpanded;
                                            });
                                          },
                                          child: Column(
                                            crossAxisAlignment:CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width:MediaQuery.of(context).size.width * 0.9,
                                                child: Text.rich(
                                                    TextSpan(
                                                        text: '${Uri.decodeComponent(publicPosts[index].userName,)} ',
                                                        style: TextStyle(
                                                            fontFamily: Poppins,
                                                            fontSize: 13,
                                                            color: primary,
                                                            fontWeight: FontWeight.bold),
                                                        children: <InlineSpan>[
                                                          TextSpan(
                                                              text: "${handleEmojis( publicPosts[index].description)} ${formatHashtags(publicPosts[index].hashtags)}",
                                                              style: const TextStyle(
                                                                  fontFamily: Poppins,
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.normal,
                                                                  color: ascent
                                                              )
                                                          )
                                                        ]
                                                    )
                                                ),
                                              ),
                                            ],
                                          ),
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
                                    ))
                                    : Padding(
                                    padding:
                                    const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width:MediaQuery.of(context).size.width * 0.9,
                                              child: Text.rich(
                                                  TextSpan(
                                                      text: '${Uri.decodeComponent(publicPosts[index].userName,)} ',
                                                      style: TextStyle(
                                                          fontFamily: Poppins,
                                                          fontSize: 13,
                                                          color: primary,
                                                          fontWeight: FontWeight.bold),
                                                      children: <InlineSpan>[
                                                        TextSpan(
                                                            text: "${handleEmojis( publicPosts[index]
                                                                .description)} ${formatHashtags(publicPosts[index].hashtags)}",
                                                            style: const TextStyle(
                                                                fontFamily: Poppins,
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.normal,
                                                                color: ascent
                                                            )
                                                        )
                                                      ]
                                                  )
                                              ),
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
                                                publicPosts[index].date),
                                            style: const TextStyle(
                                                fontFamily: Poppins,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    )),
                                const SizedBox(
                                  width: 10,
                                ),
                                publicPosts[index].addMeInFashionWeek ==
                                    true ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text("Event - ${publicPosts[index].event["title"]}",style: TextStyle(fontFamily: Poppins,),)
                                  ],
                                ): const SizedBox(),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    if(id == publicPosts[index].userid) publicPosts[index].commentCount == "0"
                                        ?
                                    const SizedBox()
                                        : GestureDetector(
                                        onVerticalDragUpdate: (details) {
                                          // Dismiss the keyboard when the user drags the bottom sheet
                                          print("simple enter");
                                          if (details.delta.dy < 0 || details.delta.dy > 0) {
                                            print("enter comment if");
                                            FocusScope.of(context).unfocus();
                                          }
                                        },
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
                                                    child: GestureDetector(
                                                      onVerticalDragUpdate: (details) {
                                                        // Dismiss the keyboard when the user drags the bottom sheet
                                                        print("simple enter");
                                                        if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                          print("enter comment if");
                                                          FocusScope.of(context).unfocus();
                                                        }
                                                      },

                                                      child: DraggableScrollableSheet(
                                                          controller: _draggableController,
                                                          expand: false, // Ensures it doesn't expand fully by default
                                                          initialChildSize: isExpendedComment ? 1.0 : 0.7, // Half screen by default
                                                          minChildSize: 0.3, // Minimum height
                                                          maxChildSize: 1.0,
                                                          builder: (BuildContext context1, ScrollController scrollController) {
                                                            return GestureDetector(
                                                              onVerticalDragUpdate: (details) {
                                                                // Dismiss the keyboard when the user drags the bottom sheet
                                                                print("simple enter");
                                                                if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                                  print("enter comment if");
                                                                  FocusScope.of(context).unfocus();
                                                                }
                                                              },
                                                              child: CommentScreen(
                                                                postid: publicPosts[index]
                                                                    .id,
                                                                pic: publicPosts[index]
                                                                    .userPic,
                                                                scrollController: scrollController,
                                                                context1: context1,
                                                                  isEventPost: publicPosts[index].addMeInFashionWeek!,
                                                                  userID: publicPosts[index].userid,
                                                                draggableController: _draggableController,
                                                                textFieldFocusNode: _textFieldFocusNode,
                                                              ),
                                                            );
                                                          }
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).then((value){
                                            getAllPublicStories();
                                            getMyTodayStories();
                                            getPublicPosts();
                                            isExpendedComment = false;
                                          });
                                        },
                                        child: Text(publicPosts[index].commentCount == "1" ? "View ${publicPosts[index].commentCount} comment" : "View all ${publicPosts[index].commentCount} comments",style: TextStyle(fontFamily: Poppins,),)),
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
              )
          : RefreshIndicator(
            color: primary,
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 5,),
                      Container(
                        height: 110,
                        child: GestureDetector(
                          onTap: myTodayStories.length > 0 ? (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                              storyList: myTodayStories,
                            ))).then((value){
                              getFavourites();
                              getMyTodayStories();
                              getAllStories();
                            });
                          }: (){},
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: myTodayStories.length > 0 ?
                                  (myTodayStories.every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.topRight,
                                      stops: const [0.0, 0.7],
                                      tileMode: TileMode.clamp,
                                      colors: <Color>[
                                        Colors.grey,
                                        Colors.grey,
                                      ]) :
                                  (myTodayStories.any((story) => story.close_friends_only == true) ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.topRight,
                                      stops: const [0.0, 0.7],
                                      tileMode: TileMode.clamp,
                                      colors: <Color>[
                                        Colors.deepPurple,
                                        Colors.purpleAccent,
                                      ]): LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.topRight,
                                      stops: const [0.0, 0.7],
                                      tileMode: TileMode.clamp,
                                      colors: <Color>[
                                        secondary,
                                        primary,
                                      ]))
                                  ): LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.topRight,
                                      stops: const [0.0, 0.7],
                                      tileMode: TileMode.clamp,
                                      colors: <Color>[
                                        // Colors.black,
                                        // Colors.black,
                                        Colors.transparent,
                                        Colors.transparent
                                      ]),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        //color: Colors.black,
                                        color: Colors.transparent,
                                        borderRadius: const BorderRadius.all(Radius.circular(120))
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: CachedNetworkImage(
                                        imageUrl: pic.isNotEmpty  ? pic : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f",
                                        imageBuilder: (context,
                                            imageProvider) => CircleAvatar(
                                            backgroundColor: Colors.grey,
                                            maxRadius: 36,
                                            backgroundImage: NetworkImage(pic),
                                            child: Align(
                                              alignment: Alignment
                                                  .bottomRight,
                                              child: SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: FloatingActionButton(
                                                  heroTag: null,
                                                  onPressed:
                                                      () {
                                                    widget.navigate(31);
                                                    //Navigator.push(context, MaterialPageRoute(builder: (context) => UploadStoryScreen(),)).then((value){
                                                    //   getMyTodayStories();
                                                    //   getAllStories();
                                                    // });
                                                  },
                                                  backgroundColor: Colors.blue.shade300,
                                                  mini: true,
                                                  child: const Icon(Icons.add,size: 16,color: ascent,),
                                                ),
                                              ),
                                            )
                                        ),
                                        placeholder: (context, url) => CircleAvatar(
                                            backgroundColor: Colors.grey,
                                            maxRadius: 36,
                                            child: SpinKitCircle(color: primary,size: 5,)
                                          // Placeholder color
                                        ),
                                        errorWidget: (context, url,
                                            error) => CircleAvatar(
                                            maxRadius: 36,
                                            backgroundImage:
                                            NetworkImage(
                                                "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f"),
                                            child:  Align(
                                              alignment: Alignment
                                                  .bottomRight,
                                              child: SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                FloatingActionButton(
                                                  heroTag: null,
                                                  onPressed:
                                                      () {
                                                        widget.navigate(31);
                                                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const StoryMediaScreen(),));
                                                  },
                                                  backgroundColor:
                                                  primary,
                                                  foregroundColor: ascent,
                                                  mini: true,
                                                  child:  const Icon(Icons.add,size: 14),
                                                ),
                                              ),
                                            )
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 1,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Your Story",style: TextStyle(
                                      fontFamily: Poppins,
                                      color: ascent,
                                      fontSize: 10
                                  ),)
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 15,),
                      Container(
                        height: 110,
                        child: ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: groupedStoriesList.length,
                            itemBuilder: (context,index){
                              return GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                    storyList: groupedStoriesList[index],
                                  ))).then((value){
                                    getFavourites();
                                    getAllStories();
                                    getAllStories();
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 15.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 1,),
                                      Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: groupedStoriesList[index].every((story) => story.viewed_users.any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.topRight,
                                                stops: const [0.0, 0.7],
                                                tileMode: TileMode.clamp,
                                                colors: <Color>[
                                                  Colors.grey,
                                                  Colors.grey,
                                                ]):
                                            (groupedStoriesList[index].any((story) => story.close_friends_only == true) ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.topRight,
                                                stops: const [0.0, 0.7],
                                                tileMode: TileMode.clamp,
                                                colors: <Color>[
                                                  Colors.deepPurple,
                                                  Colors.purpleAccent,
                                                ]) :LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.topRight,
                                                stops: const [0.0, 0.7],
                                                tileMode: TileMode.clamp,
                                                colors: <Color>[
                                                  secondary,
                                                  primary,
                                                ]))
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: const BorderRadius.all(Radius.circular(120))
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3.0),
                                              child: CachedNetworkImage(
                                                imageUrl: groupedStoriesList[index][0].user.profileImageUrl.isNotEmpty ? groupedStoriesList[index][0].user.profileImageUrl :"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f",
                                                imageBuilder: (context, imageProvider) => CircleAvatar(
                                                    maxRadius: 36,
                                                    backgroundImage: NetworkImage(groupedStoriesList[index][0].user.profileImageUrl.isNotEmpty ? groupedStoriesList[index][0].user.profileImageUrl :"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f"),
                                                    child: Align(
                                                      alignment: Alignment
                                                          .bottomRight,
                                                      child: SizedBox(
                                                        height: 22,
                                                        width: 22,
                                                        child: Visibility(
                                                          visible: false,
                                                          child: FloatingActionButton(
                                                            heroTag: null,
                                                            onPressed:
                                                                () {

                                                            },
                                                            backgroundColor: Colors.transparent.withOpacity(0.0),
                                                            mini: true,
                                                            child: Icon(Icons.add,size: 16,color: Colors.transparent.withOpacity(0.0),),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                ),
                                                placeholder: (context, url) => CircleAvatar(
                                                    maxRadius: 36,
                                                    backgroundColor: primary,
                                                    child: SpinKitCircle(color: primary,size: 10,)
                                                  // Placeholder color
                                                ),
                                                errorWidget: (context, url,
                                                    error) => CircleAvatar(
                                                    maxRadius: 36,
                                                    backgroundImage:
                                                    NetworkImage(
                                                        "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w"),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 1,),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          //Text("${groupedStoriesList[index].any((story) => story.viewed_users.any((viewer) => viewer['id'] == id))}"),
                                          Text("${groupedStoriesList[index][0].user.username}",style: TextStyle(
                                              fontFamily: Poppins,
                                              color: ascent,
                                              fontSize: 10
                                          ),)
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }),
                      )
                    ],
                  ),
                  SizedBox(height: 10,),
                  ScrollablePositionedList.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) {
                          if (index % 5 == 0) {
                            // Create a new BannerAd instance for each separator
                            BannerAd bannerAd = BannerAd(
                              size: AdSize.banner,
                              adUnitId: "ca-app-pub-5248449076034001/6687962197",
                              listener: BannerAdListener(
                                onAdLoaded: (ad) {
                                  setState(() {
                                    // Optionally handle the ad load state
                                  });
                                },
                                onAdFailedToLoad: (ad, error) {
                                  print("add error => ${error}");
                                  ad.dispose(); // Clean up if the ad fails to load
                                },
                              ),
                              request: const AdRequest(),
                            );

                            // Load the ad before displaying it
                            bannerAd.load();

                            return SizedBox(
                              height: bannerAd.size.height.toDouble(),
                              width: bannerAd.size.width.toDouble(),
                              child: AdWidget(
                                ad: bannerAd,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                        if (index == posts.length - 1) {
                          // If we reach the last item, fetch next page of posts
                          return isRefresh
                              ? InkWell(
                                  onTap: () {
                                    //paginationPost++;
                                    getPosts(1);
                                  },
                                  child: Icon(
                                    Icons.refresh,
                                    color: primary,
                                  ))
                              : const SizedBox();
                        }
                        return Card(
                          elevation: 10,
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
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
                                          Colors.orange,
                                          Colors.orange
                                        ]),),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          widget.navigateToPageWithFriendArguments(30,posts[index].userid,posts[index].userName);
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
                                                  widget.navigateToPageWithFriendArguments(30,posts[index].userid,posts[index].userName);
                                                }: (){
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                    storyList: posts[index].recent_stories!,
                                                  ))).then((value){
                                                    getFavourites();
                                                    getPosts(1);
                                                    getMyTodayStories();
                                                    getAllStories();
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius: const BorderRadius.all(Radius.circular(120)),
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
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(2.0),
                                                    child: Container(
                                                      height: 40,
                                                      width: 40,
                                                      decoration: BoxDecoration(
                                                          color: Colors.transparent,
                                                          borderRadius: const BorderRadius.all(Radius.circular(120))
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(2.0),
                                                        child: ClipRRect(
                                                          borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                          child: CachedNetworkImage(
                                                            imageUrl: posts[index].userPic.isNotEmpty ? posts[index].userPic :"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f",
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
                                                ),
                                              ),
                                              if(posts[index].userid != id && myList.contains(int.parse(posts[index].userid)) == false) posts[index].show_stories_to_non_friends == true ? GestureDetector(
                                                onTap:(posts[index].recent_stories!.length <= 0) ? (){
                                                  widget.navigateToPageWithFriendArguments(30,posts[index].userid,posts[index].userName);
                                                }: (){
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                    storyList: posts[index].recent_stories!,
                                                  ))).then((value){
                                                    getFavourites();
                                                    getPosts(1);
                                                    getMyTodayStories();
                                                    getAllStories();
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius: const BorderRadius.all(Radius.circular(120)),
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
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(2.0),
                                                    child: Container(
                                                      height: 40,
                                                      width: 40,
                                                      decoration: BoxDecoration(
                                                          color: Colors.transparent,
                                                          borderRadius: const BorderRadius.all(Radius.circular(120))
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(2.0),
                                                        child: ClipRRect(
                                                          borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                          child: CachedNetworkImage(
                                                            imageUrl: posts[index].userPic.isNotEmpty ? posts[index].userPic :"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f",
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
                                                ),
                                              ) : (
                                                  (posts[index].fanList!.contains(int.parse(id)) == true || posts[index].followList!.contains(int.parse(id)) == true) ?
                                                  GestureDetector(
                                                    onTap:(posts[index].recent_stories!.length <= 0) ? (){
                                                      widget.navigateToPageWithFriendArguments(30,posts[index].userid,posts[index].userName);
                                                    }: (){
                                                      Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                        storyList: posts[index].recent_stories!,
                                                      ))).then((value){
                                                        getFavourites();
                                                        getPosts(1);
                                                        getMyTodayStories();
                                                        getAllStories();
                                                      });
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          borderRadius: const BorderRadius.all(Radius.circular(120)),
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
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(2.0),
                                                        child: Container(
                                                          height: 40,
                                                          width: 40,
                                                          decoration: BoxDecoration(
                                                              color: Colors.transparent,
                                                              borderRadius: const BorderRadius.all(Radius.circular(120))
                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(2.0),
                                                            child: ClipRRect(
                                                              borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                              child: CachedNetworkImage(
                                                                imageUrl: posts[index].userPic.isNotEmpty ? posts[index].userPic :"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f",
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
                                                    ),
                                                  ):
                                                  GestureDetector(
                                                    onTap: (){
                                                      widget.navigateToPageWithFriendArguments(30,posts[index].userid,posts[index].userName);
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                      ),
                                                      child: Container(
                                                        height: 40,
                                                        width: 40,
                                                        child: ClipRRect(
                                                          borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                          child: CachedNetworkImage(
                                                            imageUrl: posts[index].userPic.isNotEmpty ? posts[index].userPic :"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f",
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
                                              if(myList.contains(int.parse(posts[index].userid)) == true) GestureDetector(
                                                onTap:(){
                                                  widget.navigateToPageWithFriendArguments(30,posts[index].userid,posts[index].userName);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                      border: Border.all(
                                                          width: 1.5,
                                                          color:
                                                          Colors.transparent),
                                                      gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.topRight,
                                                          stops: const [0.0, 0.7],
                                                          tileMode: TileMode.clamp,
                                                          colors: <Color>[
                                                            Colors.grey,
                                                            Colors.grey,
                                                          ])
                                                  ),
                                                  child: Container(
                                                    height: 40,
                                                    width: 40,
                                                    child: ClipRRect(
                                                      borderRadius: const BorderRadius.all(Radius.circular(120)),
                                                      child: CachedNetworkImage(
                                                        imageUrl: posts[index].userPic.isNotEmpty?posts[index].userPic:"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f",
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
                                            //widget.onNavigate(28,publicPosts[index].userid);
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
                                                            SizedBox(height: 10,),
                                                            Row(
                                                              children: [
                                                                SizedBox(width: 20,),
                                                                Text("Update the gender of your style for\nbetter visibility in the feed.",style: TextStyle(fontSize: 14,fontFamily: Poppins),)
                                                              ],
                                                            ),
                                                            SizedBox(height: 10,),
                                                            // GridView Section
                                                            Container(
                                                              padding: EdgeInsets.all(16),
                                                              height: 160, // Adjust height as per content
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
                                                                      height: 40,
                                                                      decoration: BoxDecoration(
                                                                        color: genderIndex == index1 ? primary : Colors.transparent,
                                                                        borderRadius: BorderRadius.circular(8),
                                                                        border: Border.all(
                                                                          color: genderIndex == index1 ? Colors.transparent : primary,
                                                                        )
                                                                      ),
                                                                      child: Center(
                                                                        child: Text(
                                                                          '${genders[index1]}',
                                                                          style: TextStyle(color: genderIndex == index1 ? ascent : primary,fontFamily: Poppins,fontSize: 16),
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
                                                            SizedBox(height: 10,),
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
                                                  Icon(Icons.report,size: 30,),
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
                                                    Icon(Icons.edit,size: 30),
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
                                            )) :
                                            PopupMenuItem(
                                              value: 2,
                                              child: Row(
                                                children: [
                                                  posts[index].isCommentEnabled == false ? Icon(FontAwesomeIcons
                                                      .comment,size: 24):Icon(FontAwesomeIcons.commentSlash,size: 23),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    posts[index].isCommentEnabled == false ? " Enable comments" : " Disable comments",
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
                                            )) :
                                            PopupMenuItem(
                                              value: 3,
                                              child: Row(
                                                children: [
                                                  posts[index].addMeInFashionWeek == true ?
                                                  (posts[index].isLikeEnabled == false ? Icon(Icons.favorite):Stack(
                                                    children: [
                                                      Icon(Icons.favorite_border,size: 30,),
                                                      Positioned(
                                                        top: 2,
                                                        left: 1,
                                                        child: Icon(FontAwesomeIcons.slash,size: 22,),
                                                      ),
                                                    ],
                                                  )):
                                                  (posts[index].isLikeEnabled == false ? Icon(FontAwesomeIcons.star,size: 24,):
                                                  Image.asset(
                                                    "assets/fcut.png",
                                                    height:31,
                                                    width: 31,
                                                  )),
                                                  SizedBox(
                                                    width: 15,
                                                  ),
                                                  Text(
                                                    posts[index].isLikeEnabled == false ? "Show like count" : "Hide like count",
                                                    style: TextStyle(
                                                      fontFamily: Poppins,),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if(posts[index].userid == id) PopupMenuItem(
                                              value: 4,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.person,size: 30),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    "Update style gender",
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
                              SizedBox(
                                height: 550,
                                width: double.infinity,
                                child: CarouselSlider(
                                  carouselController: _controller,
                                  options: CarouselOptions(
                                      viewportFraction: 1,
                                      enableInfiniteScroll: false,
                                      height: 550.0,
                                      autoPlay: false,
                                      enlargeCenterPage: true,
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
                                    return i["type"] == "video"
                                        ? Container(
                                        color: Colors.black,
                                        child: Text("Video"),
                                        // child: UsingVideoControllerExample(
                                        //   path: i["video"],
                                        // )
                                        )
                                        : GestureDetector(
                                           onTap: (){
                                             showDialog(
                                               context: context,
                                               builder: (context) {
                                                 return Dialog(
                                                   backgroundColor: Colors.black54,
                                                   insetPadding: EdgeInsets.all(0), // Remove all padding
                                                   child: Container(
                                                     color: Colors.black54,
                                                     width: MediaQuery.of(context).size.width,  // 100% of screen width
                                                     height: MediaQuery.of(context).size.height * 0.8,  // 90% of screen height
                                                     child: Padding(
                                                       padding: const EdgeInsets.all(8.0),
                                                       child: ClipRRect(
                                                         borderRadius: BorderRadius.circular(8.0),  // Optional: add rounded corners
                                                         child: InteractiveViewer(
                                                           boundaryMargin: EdgeInsets.all(0),  // No margins around the boundary
                                                           minScale: 0.1,  // Minimum zoom out scale
                                                           maxScale: 4.0,
                                                           child:CachedNetworkImage(
                                                             imageUrl: i["image"],
                                                             imageBuilder: (context, imageProvider) =>
                                                                 Container(
                                                                   height: MediaQuery.of(context).size.height * 0.9,
                                                                   width: MediaQuery.of(context).size.width,
                                                                   decoration:
                                                                   BoxDecoration(
                                                                     image: DecorationImage(
                                                                       image: imageProvider,
                                                                       fit: BoxFit
                                                                           .contain,
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
                                                                   height: MediaQuery.of(context).size.height * 0.9,
                                                                   width: MediaQuery.of(context).size.width,
                                                                   decoration:
                                                                   BoxDecoration(
                                                                     image: DecorationImage(
                                                                         image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                                                                             .image,
                                                                         fit: BoxFit
                                                                             .fill),
                                                                   ),
                                                                 ),
                                                           )
                                                         ),
                                                       ),
                                                     ),
                                                   ),
                                                 );
                                               },
                                             );

                                           },
                                           child: CachedNetworkImage(
                                            imageUrl: i["image"],
                                            imageBuilder: (context, imageProvider) =>
                                                Container(
                                                  height: MediaQuery.of(context).size.height,
                                                  width: MediaQuery.of(context).size.width,
                                                  decoration:
                                                  BoxDecoration(
                                                    image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit
                                                          .fill,
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
                                                  height: MediaQuery.of(context).size.height * 0.9,
                                                  width: MediaQuery.of(context).size.width,
                                                  decoration:
                                                  BoxDecoration(
                                                    image: DecorationImage(
                                                        image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                                                            .image,
                                                        fit: BoxFit
                                                            .fill),
                                                  ),
                                                ),
                                          ),
                                        );
                                  }).toList(),
                                ),
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
                              Padding(
                                  padding: const EdgeInsets.only(left: 0.0, right: 0.0),
                                  child: posts[index].userid == id
                                      ? Row(
                                          children: [
                                            SizedBox(width: 10,),
                                            posts[index].addMeInFashionWeek == true
                                                ? posts[index].mylike != "like" ? IconButton(
                                                        onPressed: () {
                                                          widget.navigateToPageWithPostArguments(29,posts[index].id);
                                                        },
                                                        icon: posts[index].isLikeEnabled == true ? Icon(
                                                          Icons.favorite,
                                                          size: 30,
                                                          color: Colors.red,
                                                        ):Stack(
                                                          children: [
                                                            Icon(Icons.favorite,size: 30,color: posts[index].isLikeEnabled == true ? Colors.red : Colors.grey,),
                                                            Positioned(
                                                              top: 2,
                                                              left: 1,
                                                              child: Icon(FontAwesomeIcons.slash,size: 22,color: posts[index].isLikeEnabled == true ? Colors.red : Colors.grey,),
                                                            ),
                                                          ],
                                                        ))
                                                    : GestureDetector(
                                                        onTap:(){
                                                          widget.navigateToPageWithPostArguments(29,posts[index].id);
                                                        },
                                                        child: posts[index].isLikeEnabled == true ? Icon(
                                                          FontAwesomeIcons
                                                              .heart,
                                                          color: Colors.red,
                                                          size: 30,
                                                        ):Stack(
                                                          children: [
                                                            Icon(Icons.favorite_border,size: 30,color: posts[index].isLikeEnabled == true ? Colors.red : Colors.grey,),
                                                            Positioned(
                                                              top: 2,
                                                              left: 1,
                                                              child: Icon(FontAwesomeIcons.slash,size: 22,color: posts[index].isLikeEnabled == true ? Colors.red : Colors.grey,),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                : posts[index].mylike !=
                                                        "like"
                                                    ? GestureDetector(
                                                        onTap:(){
                                                          widget.navigateToPageWithPostArguments(29,posts[index].id);
                                                        },
                                                        child: posts[index].isLikeEnabled == true ? Icon(
                                                          FontAwesomeIcons.star,
                                                          size: 26,
                                                          color: posts[index].isLikeEnabled == true ? Colors.orange : Colors.grey,
                                                          // size: 50,
                                                        ):Image.asset(
                                                          "assets/fcut1.png",
                                                          height:30,
                                                          width: 30,
                                                        ))
                                                    : GestureDetector(
                                                        onDoubleTap: () {},
                                                        onTap:(){
                                                          widget.navigateToPageWithPostArguments(29,posts[index].id);
                                                        },
                                                        child: posts[index].isLikeEnabled == true ? Icon(
                                                               FontAwesomeIcons.star,
                                                                size: 26,
                                                                color: posts[index].isLikeEnabled == true ? Colors.orange : Colors.grey,
                                                            ): Image.asset(
                                                              "assets/fcut1.png",
                                                              height:30,
                                                              width: 30,
                                                             )
                                                      ),
                                            if(id == posts[index].userid) posts[index].likeCount == "0"
                                                ?
                                                const SizedBox()
                                                : Text(" ${posts[index].likeCount}",style: TextStyle(fontFamily: Poppins,),),
                                            SizedBox(width: 10,),
                                            GestureDetector(
                                                    onVerticalDragUpdate: (details) {
                                                // Dismiss the keyboard when the user drags the bottom sheet
                                                print("simple enter");
                                                if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                  print("enter comment if");
                                                  FocusScope.of(context).unfocus();
                                                }
                                              },
                                                    onTap:(){
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
                                                                print("Closed 4");
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
                                                                child: GestureDetector(
                                                                  onVerticalDragUpdate: (details) {
                                                                    // Dismiss the keyboard when the user drags the bottom sheet
                                                                    print("simple enter");
                                                                    if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                                      print("enter comment if");
                                                                      FocusScope.of(context).unfocus();
                                                                    }
                                                                  },

                                                                  child: DraggableScrollableSheet(
                                                                      controller: _draggableController,
                                                                      expand: false,
                                                                      // Ensures it doesn't expand fully by default
                                                                      initialChildSize: isExpendedComment ? 1.0 : 0.7,
                                                                      // Half screen by default
                                                                      minChildSize: 0.3,
                                                                      // Minimum height
                                                                      maxChildSize: 1.0,
                                                                      builder: (
                                                                          BuildContext context1,
                                                                          ScrollController scrollController) {
                                                                        return GestureDetector(
                                                                          onVerticalDragUpdate: (details) {
                                                                            // Dismiss the keyboard when the user drags the bottom sheet
                                                                            print("simple enter");
                                                                            if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                                              print("enter comment if");
                                                                              FocusScope.of(context).unfocus();
                                                                            }
                                                                          },
                                                                          child: CommentScreen(
                                                                              postid: posts[index]
                                                                                  .id,
                                                                              pic: posts[index]
                                                                                  .userPic,
                                                                              scrollController: scrollController,
                                                                              context1: context1,
                                                                              isEventPost: posts[index].addMeInFashionWeek!,
                                                                              userID: posts[index].userid,
                                                                              draggableController: _draggableController,
                                                                            textFieldFocusNode: _textFieldFocusNode,
                                                                          ),
                                                                        );
                                                                      }
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }).then((value) {
                                                        getAllStories();
                                                        getMyTodayStories();
                                                        isExpendedComment = false;
                                                      });
                                                    },
                                                    child:posts[index].isCommentEnabled == true ? Icon(
                                                      FontAwesomeIcons.comment,
                                                      size: 26,
                                                      color: posts[index].isCommentEnabled == true ? Colors.white : Colors.grey,
                                                    ): Icon(
                                                      FontAwesomeIcons.commentSlash,
                                                      size: 24,
                                                      color: posts[index].isCommentEnabled == true ? Colors.white : Colors.grey,
                                                    ),
                                                  ),
                                            if(id == posts[index].userid) posts[index].commentCount == "0" ? Text("") : Text(" ${posts[index].commentCount}",style: TextStyle(fontFamily: Poppins,),),
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
                                                            height: 28 ,
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
                                                    getAllStories();
                                                    getMyTodayStories();
                                                  });
                                                },
                                                icon: const Icon(
                                                  FontAwesomeIcons.share,
                                                  size: 26,
                                                    color: Colors.white
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
                                      posts[index].addMeInFashionWeek == true
                                          ? posts[index].mylike != "like" ? GestureDetector(
                                            onTap:(){
                                              widget.navigateToPageWithPostArguments(29,posts[index].id);
                                            },
                                            child: Icon(
                                              Icons.favorite_border,
                                              color: Colors.red,
                                              size: 30,
                                            ),
                                          )
                                          : GestureDetector(
                                        onTap:(){
                                          if(posts[index].isLikeEnabled == true) {
                                            widget.navigateToPageWithPostArguments(29,posts[index].id);
                                            // Navigator.push(
                                            //     context,
                                            //     MaterialPageRoute(
                                            //       builder:
                                            //           (
                                            //           context) =>
                                            //           PostLikeUserScreen(
                                            //               fashionId: posts[index]
                                            //                   .id),
                                            //     ));
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
                                                                  SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                                                                  // Stack(
                                                                  //   children: [
                                                                  //     Icon(posts[index].addMeInFashionWeek == true ? Icons.favorite_border : Icons.star_border,size: 90,),
                                                                  //     Positioned(
                                                                  //       top: 7,
                                                                  //       left: 2,
                                                                  //       child: Icon(FontAwesomeIcons.slash,size: 60,),
                                                                  //     ),
                                                                  //   ],
                                                                  // ),
                                                                  Image.asset(posts[index].addMeInFashionWeek == true ? "assets/smile.png" : "assets/starbackT.png",height: 200,width: 200),
                                                                  SizedBox(height: 10,),
                                                                  Container(
                                                                    width:MediaQuery.of(context).size.width * 0.5,
                                                                    child: Center(
                                                                      child: Text("The user has chosen to hide the likes on this post.",style: TextStyle(
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
                                              getAllStories();
                                              getMyTodayStories();
                                            });
                                          }
                                        },
                                        child: Icon(
                                          FontAwesomeIcons
                                              .heart,
                                          color: Colors.red,
                                          size: 26,
                                        ),
                                      )
                                          : posts[index].mylike !=
                                          "like"
                                          ? GestureDetector(
                                          onTap:(){
                                            if(posts[index].isLikeEnabled == true) {
                                              widget.navigateToPageWithPostArguments(29,posts[index].id);
                                              // Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //       builder:
                                              //           (
                                              //           context) =>
                                              //           PostLikeUserScreen(
                                              //               fashionId: posts[index]
                                              //                   .id),
                                              //     ));
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
                                                                    SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                                                                    // Stack(
                                                                    //   children: [
                                                                    //     Icon(posts[index].addMeInFashionWeek == true ? Icons.favorite_border : Icons.star_border,size: 90,),
                                                                    //     Positioned(
                                                                    //       top: 7,
                                                                    //       left: 2,
                                                                    //       child: Icon(FontAwesomeIcons.slash,size: 60,),
                                                                    //     ),
                                                                    //   ],
                                                                    // ),
                                                                    Image.asset(posts[index].addMeInFashionWeek == true ? "assets/smile.png" : "assets/starbackT.png",height: 200,width: 200),
                                                                    SizedBox(height: 10,),
                                                                    Container(
                                                                      width:MediaQuery.of(context).size.width * 0.5,
                                                                      child: Center(
                                                                        child: Text("The user has chosen to hide the likes on this post.",style: TextStyle(
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
                                                getAllStories();
                                                getMyTodayStories();
                                              });
                                            }
                                          },
                                          child: Icon(
                                            FontAwesomeIcons.star,
                                            size: 26,
                                            color: posts[index].isLikeEnabled == true ? Colors.orange : Colors.grey,
                                          ))
                                          : GestureDetector(
                                        onDoubleTap: () {},
                                        onTap:(){
                                          if(posts[index].isLikeEnabled == true) {
                                            widget.navigateToPageWithPostArguments(29,posts[index].id);
                                            // Navigator.push(
                                            //     context,
                                            //     MaterialPageRoute(
                                            //       builder:
                                            //           (
                                            //           context) =>
                                            //           PostLikeUserScreen(
                                            //               fashionId: posts[index]
                                            //                   .id),
                                            //     ));
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
                                                                  SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                                                                  Stack(
                                                                    children: [
                                                                      Icon(posts[index].addMeInFashionWeek == true ? Icons.favorite_border : Icons.star_border,size: 90,),
                                                                      Positioned(
                                                                        top: 7,
                                                                        left: 2,
                                                                        child: Icon(FontAwesomeIcons.slash,size: 60,),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  //Image.asset(posts[index].addMeInFashionWeek == true ? "assets/smile.png" : "assets/starbackT.png",height: 200,width: 200),
                                                                  SizedBox(height: 10,),
                                                                  Container(
                                                                    width:MediaQuery.of(context).size.width * 0.5,
                                                                    child: Center(
                                                                      child: Text("The user has chosen to hide the likes on this post.",style: TextStyle(
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
                                              getAllStories();
                                              getMyTodayStories();
                                            });
                                          }
                                        },
                                        child: Icon(
                                            FontAwesomeIcons.star,
                                            size: 26,
                                            color: posts[index].isLikeEnabled == true ? Colors.orange : Colors.grey),
                                      ),
                                      if(id == posts[index].userid || posts[index].isLikeEnabled == true) posts[index].likeCount == "0"
                                          ?
                                      const SizedBox()
                                          : (posts[index].isLikeEnabled == false ?
                                      Text("",style: TextStyle(fontFamily: Poppins,color: ascent),): Text(" ${posts[index].likeCount}",style: TextStyle(fontFamily: Poppins,),)),
                                      SizedBox(width: 10,),
                                      GestureDetector(
                                        onVerticalDragUpdate: (details) {
                                          // Dismiss the keyboard when the user drags the bottom sheet
                                          print("simple enter");
                                          if (details.delta.dy < 0 || details.delta.dy > 0) {
                                            print("enter comment if");
                                            FocusScope.of(context).unfocus();
                                          }
                                        },
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
                                                      print("Closed 5");
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
                                                      child: GestureDetector(
                                                        onVerticalDragUpdate: (details) {
                                                          // Dismiss the keyboard when the user drags the bottom sheet
                                                          print("simple enter");
                                                          if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                            print("enter comment if");
                                                            FocusScope.of(context).unfocus();
                                                          }
                                                        },

                                                        child: DraggableScrollableSheet(
                                                            controller: _draggableController,
                                                            expand: false,
                                                            // Ensures it doesn't expand fully by default
                                                            initialChildSize: isExpendedComment ? 1.0 : 0.7,
                                                            // Half screen by default
                                                            minChildSize: 0.3,
                                                            // Minimum height
                                                            maxChildSize: 1.0,
                                                            builder: (
                                                                BuildContext context1,
                                                                ScrollController scrollController) {
                                                              return GestureDetector(
                                                                onVerticalDragUpdate: (details) {
                                                                  // Dismiss the keyboard when the user drags the bottom sheet
                                                                  print("simple enter");
                                                                  if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                                    print("enter comment if");
                                                                    FocusScope.of(context).unfocus();
                                                                  }
                                                                },
                                                                child: CommentScreen(
                                                                    postid: posts[index]
                                                                        .id,
                                                                    pic: posts[index]
                                                                        .userPic,
                                                                    scrollController: scrollController,
                                                                    context1: context1,
                                                                    isEventPost: posts[index].addMeInFashionWeek!,
                                                                    userID: posts[index].userid,
                                                                    draggableController: _draggableController,
                                                                  textFieldFocusNode: _textFieldFocusNode,
                                                                ),
                                                              );
                                                            }
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).then((value) {
                                              getAllStories();
                                              getMyTodayStories();
                                              isExpendedComment = false;
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
                                                                  Row(
                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                    children: [
                                                                      IconTheme(
                                                                        data: IconThemeData(color: ascent,size: 80),
                                                                        child: Icon(FontAwesomeIcons.commentSlash),
                                                                      ),
                                                                      SizedBox(width: 20,)
                                                                    ],
                                                                  ),
                                                                  SizedBox(height: 15,),
                                                                  Container(
                                                                    width:MediaQuery.of(context).size.width * 0.72,
                                                                    child: Row(
                                                                      mainAxisAlignment:MainAxisAlignment.center,
                                                                      children: [
                                                                        Text("The user has chosen to disable comments\non this post.",style: TextStyle(
                                                                            fontFamily: Poppins,
                                                                            fontSize: 12
                                                                        ),),
                                                                      ],
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
                                              getAllStories();
                                              getMyTodayStories();
                                            });
                                          }
                                        },
                                        child: Icon(
                                          FontAwesomeIcons.comment,
                                          color: posts[index].isCommentEnabled == true ? ascent : Colors.grey,
                                          size: 28,
                                        ),
                                      ),
                                      if(id == posts[index].userid || posts[index].isCommentEnabled == true) posts[index].isCommentEnabled == false ?
                                      const Text("",style: TextStyle(fontFamily: Poppins,color: ascent),)
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
                                              getAllStories();
                                              getMyTodayStories();
                                            });
                                          },
                                          icon: const Icon(
                                            FontAwesomeIcons.share,
                                            size: 26,
                                              color: Colors.white
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
                              posts[index].description.toString().length +formatHashtags(posts[index].hashtags).length >
                                      150
                                  ? Padding(
                                      padding:
                                          const EdgeInsets.all(
                                              8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          isExpanded
                                              ? GestureDetector(
                                                 onTap:(){
                                                   setState(() {
                                                     isExpanded = !isExpanded;
                                                   });
                                                 },
                                                child: Container(
                                                  width:MediaQuery.of(context).size.width * 0.9,
                                                  child: Column(
                                                    crossAxisAlignment:CrossAxisAlignment.start,
                                                      children: [
                                                        Text.rich(
                                                            TextSpan(
                                                                text: '${Uri.decodeComponent(posts[index].userName,)} ',
                                                                style: TextStyle(
                                                                    fontFamily: Poppins,
                                                                    fontSize: 13,
                                                                    color: primary,
                                                                    fontWeight: FontWeight.bold),
                                                                children: <InlineSpan>[
                                                                  TextSpan(
                                                                      text: "${handleEmojis(posts[index].description.substring(0, 130))}...",
                                                                      style: const TextStyle(
                                                                          fontFamily: Poppins,
                                                                          fontSize: 13,
                                                                          fontWeight: FontWeight.normal,
                                                                          color: ascent
                                                                      )
                                                                  )
                                                                ]
                                                            )
                                                        ),
                                                      ],
                                                    ),
                                                ),
                                              )
                                              : GestureDetector(
                                                  onTap:(){
                                                    setState(() {
                                                      isExpanded = !isExpanded;
                                                    });
                                                  },
                                                child: Column(
                                                  crossAxisAlignment:CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width:MediaQuery.of(context).size.width * 0.9,
                                                      child: Text.rich(
                                                          TextSpan(
                                                              text: '${Uri.decodeComponent(posts[index].userName,)} ',
                                                              style: TextStyle(
                                                                  fontFamily: Poppins,
                                                                  fontSize: 13,
                                                                  color: primary,
                                                                  fontWeight: FontWeight.bold),
                                                              children: <InlineSpan>[
                                                                TextSpan(
                                                                  text: "${handleEmojis( posts[index].description)} ${formatHashtags(posts[index].hashtags)}",
                                                                    style: const TextStyle(
                                                                        fontFamily: Poppins,
                                                                        fontSize: 13,
                                                                        fontWeight: FontWeight.normal,
                                                                      color: ascent
                                                                    )
                                                                )
                                                              ]
                                                          )
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                                      ))
                                  : Padding(
                                      padding:
                                          const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width:MediaQuery.of(context).size.width * 0.9,
                                                child: Text.rich(
                                                    TextSpan(
                                                        text: '${Uri.decodeComponent(posts[index].userName,)} ',
                                                        style: TextStyle(
                                                            fontFamily: Poppins,
                                                            fontSize: 13,
                                                            color: primary,
                                                            fontWeight: FontWeight.bold),
                                                        children: <InlineSpan>[
                                                          TextSpan(
                                                              text: "${handleEmojis( posts[index]
                                                                  .description)} ${formatHashtags(posts[index].hashtags)}",
                                                              style: const TextStyle(
                                                                  fontFamily: Poppins,
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.normal,
                                                                  color: ascent
                                                              )
                                                          )
                                                        ]
                                                    )
                                                ),
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
                                  if(id == posts[index].userid) posts[index].commentCount == "0"
                                      ?
                                  const SizedBox()
                                      : GestureDetector(
                                      onVerticalDragUpdate: (details) {
                                        // Dismiss the keyboard when the user drags the bottom sheet
                                        print("simple enter");
                                        if (details.delta.dy < 0 || details.delta.dy > 0) {
                                          print("enter comment if");
                                          FocusScope.of(context).unfocus();
                                        }
                                      },
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
                                                   print("Closed 6");
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
                                                   child: GestureDetector(
                                                     onVerticalDragUpdate: (details) {
                                                       // Dismiss the keyboard when the user drags the bottom sheet
                                                       print("simple enter");
                                                       if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                         print("enter comment if");
                                                         FocusScope.of(context).unfocus();
                                                       }
                                                     },

                                                     child: DraggableScrollableSheet(
                                                         controller: _draggableController,
                                                         expand: false, // Ensures it doesn't expand fully by default
                                                         initialChildSize: isExpendedComment ? 1.0 : 0.7, // Half screen by default
                                                         minChildSize: 0.3, // Minimum height
                                                         maxChildSize: 1.0,
                                                         builder: (BuildContext context1, ScrollController scrollController) {
                                                             return GestureDetector(
                                                               onVerticalDragUpdate: (details) {
                                                                 // Dismiss the keyboard when the user drags the bottom sheet
                                                                 print("simple enter");
                                                                 if (details.delta.dy < 0 || details.delta.dy > 0) {
                                                                   print("enter comment if");
                                                                   FocusScope.of(context).unfocus();
                                                                 }
                                                               },
                                                               child: CommentScreen(
                                                                 postid: posts[index]
                                                                     .id,
                                                                 pic: posts[index]
                                                                     .userPic,
                                                                scrollController: scrollController,
                                                               context1: context1,
                                                                 isEventPost: posts[index].addMeInFashionWeek!,
                                                                 userID: posts[index].userid,
                                                               draggableController: _draggableController,
                                                               textFieldFocusNode: _textFieldFocusNode,),
                                                             );
                                                         }
                                                     ),
                                                   ),
                                                 ),
                                               );
                                             }).then((value){
                                           getAllStories();
                                           getMyTodayStories();
                                           isExpendedComment = false;
                                         });
                                       },
                                      child: Text(posts[index].commentCount == "1" ? "View ${posts[index].commentCount} comment" : "View all ${posts[index].commentCount} comments",style: TextStyle(fontFamily: Poppins,),)),
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
          )
      ),
    );
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
                                    ? friendData["username"]
                                    : (chatRoomId!.split("_")[1] == name
                                    ? userData["username"]
                                    : ""),
                                style: TextStyle(
                                    color: primary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: Poppins),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Text(
                                (chatRoomId!.split("_")[0] == name)
                                    ? friendData["name"]
                                    : (chatRoomId!.split("_")[1] == name
                                    ? userData["name"]
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

class ZoomableImage extends StatefulWidget {
  final String imageUrl;

  const ZoomableImage({super.key, required this.imageUrl});

  @override
  _ZoomableImageState createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  double _scale = 1.0;
  double _previousScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        setState(() {
          _previousScale = _scale;
        });
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = _previousScale * details.scale;
        });
      },
      onScaleEnd: (details) {
        setState(() {
          _previousScale = _scale;
        });
      },
      child: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20.0),
        minScale: 1.0,
        maxScale: 4.0,
        scaleEnabled: true,
        child: Transform.scale(
          scale: _scale,
          child:CachedNetworkImage(
            fit: BoxFit.contain,
            imageUrl:
            widget.imageUrl,
            imageBuilder:
                (context,
                imageProvider) =>
                Container(
                  height: MediaQuery.of(
                      context)
                      .size
                      .height*0.8,
                  width: MediaQuery.of(
                      context)
                      .size
                      .width * 5,
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
          ),
        ),
      ),
    );
  }
}