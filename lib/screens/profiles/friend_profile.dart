import 'dart:convert';
import 'dart:io';

import 'package:finalfashiontimefrontend/models/story_model.dart';
import 'package:finalfashiontimefrontend/models/user_model.dart';
import 'package:finalfashiontimefrontend/screens/highlights/highlight_detail.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/swap_detail.dart';
import 'package:finalfashiontimefrontend/screens/users-screen/friend_fan.dart';
import 'package:finalfashiontimefrontend/screens/users-screen/friend_idol.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/report_screen.dart';
import 'package:finalfashiontimefrontend/screens/stories/view_story.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../helpers/database_methods.dart';
import '../../models/post_model.dart';

class FriendProfileScreen extends StatefulWidget {
  final String id;
  final String username;
  Function? navigateToPageWithReportArguments;
  FriendProfileScreen({Key? key, required this.id, required this.username, this.navigateToPageWithReportArguments}) : super(key: key);

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> with SingleTickerProviderStateMixin {
  String id = "";
  String token = "";
  bool loading = false;
  Map<String,dynamic> data = {};
  bool requestLoader = false;
  bool requestLoader1 = false;
  bool requestLoader2 = false;
  bool isGetRequest = false;
  String isGetRequestStatus = "";
  String touser = "";
  String fromuser = "";
  String requestID = "";
  String fanId = "";
  bool loading1 = false;
  bool loading2 = false;
  bool loading3 = false;
  bool blockStatus=false;
  List<PostModel> myPosts = [];
  List<PostModel> commentedPost = [];
  List<PostModel> likedPost = [];
  List<String> BadgeList = [];
  late List<int>rankingOrders=[];
   String lowestRankingOrderDocument="";
  List<String>mediaLink=[];
  List<PostModel> medalPostsModel = [];
  String name = "";
  String fcm='';
  String UserFcm="";
  List<Map<String,dynamic>> highlights = [];
  bool isLoading = false;
  Map<String, File?> thumbnailCache = {};
  late TabController tabController;
  bool isfan = false;
  bool isfan1 = false;
  String fansId = "";
  List<int> blockList = [];
  List<int> myList = [];
  String fanRequestID = "";
  String fanRequestID1 = "";
  List<Map<String, dynamic>> fanRequests = [];

  Future<void> generateAndCacheThumbnail(String videoUrl, String id) async {
    final thumbnail = await VideoThumbnail.thumbnailFile(video: videoUrl);  // Assuming this generates thumbnail
    setState(() {
      thumbnailCache[id] = File(thumbnail!);
    });
  }

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    name = preferences.getString("name")!;
    fcm=preferences.getString("fcm_token")!;
    print("cached data with fcm is {$id}");
    getRequests();
    getFriendRequests();
    getMyFriends(widget.id);
    getFavourites();
    getBlockList();
    getFan(id,widget.id);
    getHighlights(widget.id);
    ClickedUserData(widget.id);
    print("my id is ${widget.id}");
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
  }
  getRequests() {
    try {
      https.get(Uri.parse("$serverUrl/Request/personrequests/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        print("requests ==> ${value.body.toString()}");
        jsonDecode(value.body).forEach((e){
          if(e["from_user"]["id"].toString() == id && e["to_user"]["id"].toString() == widget.id){
            setState(() {
              isfan1 = true;
             });
            fanRequestID = e["id"].toString();
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

  getFriendRequests() {
    try {
      https.get(Uri.parse("$serverUrl/Request/personrequests/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        print("requests ==> ${value.body.toString()}");
        jsonDecode(value.body).forEach((e){
          if(e["from_user"]["id"].toString() == widget.id && e["to_user"]["id"].toString() == id){
            setState(() {
              isfan1 = true;
            });
            fanRequestID1 = e["id"].toString();
            print("Fan Request ID ${fanRequestID1}");
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


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    print("id Screen ${widget.id}");
    getCashedData();
  }
  Color _getTabIconColor(BuildContext context) {

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;


    return isDarkMode ? Colors.white : primary;
  }
  ColorFilter _getImageColorFilter(BuildContext context) {
    // Check the current theme's brightness
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Return the appropriate color filter based on the theme
    return isDarkMode
        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
        : ColorFilter.mode(primary, BlendMode.srcIn);
  }

  getMyFriends(id){
    print("The user id => ${id}");
    setState(() {
      loading = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/user/api/allUsers/$id/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        //print("Data ==> ${data.toString()}");
        print("Data ==> ${value.body}");
        final body = utf8.decode(value.bodyBytes);
        final jsonData = jsonDecode(body);
        setState(() {
          data = jsonData;
        });
        print("Friend data $data");
        print("fan list ${data["fansList"]}");
        print("Friend data private toggle ${data["isPrivate"]}");
        print(jsonDecode(value.body).toString());
        // commentedPost.clear();
        matchFriendReques(widget.id);
      });
    }catch(e){
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  ClickedUserData(id){
    setState(() {
      loading = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/user/api/allUsers/$id/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        print("Data ==> ${data.toString()}");
        setState(() {
          data = jsonDecode(value.body);
          UserFcm=data["fcmToken"];
        });
        print("Clicked user data$data");
        print("Clicked user fcm $UserFcm");
        print(jsonDecode(value.body).toString());
      });
    }catch(e){
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  matchFriendReques(id1){
    print("Match Friend id");
    try{
      https.get(
          Uri.parse("$serverUrl/followRequests/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        print(id);
        jsonDecode(value.body).forEach((request){
          // print("${request["from_user"].toString()} == ${id1} && ${request["to_user"]} == ${id}");
          if(request["from_user"].toString() == id1.toString() && request["to_user"].toString() == id.toString()){
            print("Accepted");
            setState(() {
              loading = false;
              isGetRequest = true;
              isGetRequestStatus = request["status"];
              touser = request["to_user"].toString();
              fromuser = request["from_user"].toString();
              requestID = request["id"].toString();
            });
            print(isGetRequest.toString());
            print(requestID.toString());
          }
          else if(request["from_user"].toString() == id.toString() && request["to_user"].toString() == id1.toString()){
            print("Not Accepted");
            setState(() {
              loading = false;
            });
            isGetRequest = true;
            isGetRequestStatus = request["status"];
            touser = request["to_user"].toString();
            fromuser = request["from_user"].toString();
            requestID = request["id"].toString();
          }
          // else{
          //   print("Not Accepted else");
          //   setState(() {
          //     loading = false;
          //   });
          //   // isGetRequestStatus = request["status"];
          //   // to_user = request["to_user"];
          //   // from_user = request["from_user"];
          //   print(isGetRequest.toString());
          // }
        });
        setState(() {
          loading = false;
        });
        print(jsonDecode(value.body).toString());
        getMyPosts();
      });
    }catch(e){
      setState(() {
        loading = false;
      });
      debugPrint("Error --> $e");
    }
  }

  bool grid = true;
  bool profile = false;
  bool styles = false;

  getMyPosts(){
    setState(() {
      loading1 = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/fashionuser/savedFashion/${widget.id}/saved-posts/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        print(jsonDecode(value.body).toString());
        if(jsonDecode(value.body).length <= 0){
          setState(() {
            loading1 = false;
          });
          print("No data");
        }
        else {
          setState(() {
            loading1 = false;
          });
          jsonDecode(value.body).forEach((value) {
            if (value["upload"]["media"][0]["type"] == "video") {
              VideoThumbnail.thumbnailFile(
                video: value["upload"]["media"][0]["video"],
                imageFormat: ImageFormat.JPEG,
                maxWidth: 128,
                // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
                quality: 25,
              ).then((value1) {
                setState(() {
                  myPosts.add(PostModel(
                      value["id"].toString(),
                      value["description"],
                      value["upload"]["media"],
                      value["user"]["name"],
                      value["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                      false,
                      value["likesCount"].toString(),
                      value["disLikesCount"].toString(),
                      value["commentsCount"].toString(),
                      value["created"],
                      value1!,
                      value["user"]["id"].toString(),
                      value["myLike"] == null ? "like" : value["myLike"].toString(),
                      value["eventData"],
                      value["topBadge"] ?? {"badge":null},
                      addMeInFashionWeek: value["addMeInWeekFashion"],
                      isCommentEnabled: value["isCommentOff"],
                      isLikeEnabled: value["isLikeOff"],
                      hashtags: value['hashtags'],
                      recent_stories: value['recent_stories'].length > 0 ? List<Story>.from(value['recent_stories'].map((e1){
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
                      show_stories_to_non_friends: value['user']['show_stories_to_non_friends'],
                      fanList: value["fansList"],
                      followList: value["user"]["followList"],
                      close_friends: value["close_friends"]
                  ));
                });
              });
            }
            else {
              setState(() {
                myPosts.add(PostModel(
                    value["id"].toString(),
                    value["description"],
                    value["upload"]["media"],
                    value["user"]["name"],
                    value["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                    false,
                    value["likesCount"].toString(),
                    value["disLikesCount"].toString(),
                    value["commentsCount"].toString(),
                    value["created"],
                    "",
                    value["user"]["id"].toString(),
                    value["myLike"] == null ? "like" : value["myLike"].toString(),
                  value["eventData"],
                    value["topBadge"] ?? {"badge":null},
                    addMeInFashionWeek: value["addMeInWeekFashion"],
                    isCommentEnabled: value["isCommentOff"],
                    isLikeEnabled: value["isLikeOff"],
                    hashtags: value['hashtags'],
                    recent_stories: value['recent_stories'].length > 0 ? List<Story>.from(value['recent_stories'].map((e1){
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
                    show_stories_to_non_friends: value['user']['show_stories_to_non_friends'],
                    fanList: value["fansList"],
                    followList: value["user"]["followList"],
                    close_friends: value["close_friends"]
                ));
              });
            }
          });
        }
      });
      getCommentedPosts();
      getBadges();
      getBadgesHistory();
     // getPostsWithMedal();
    }catch(e){
      setState(() {
        loading1 = false;
      });
      print("Error --> $e");
    }
  }
  getCommentedPosts(){
    setState(() {
      loading2 = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/fashionuser/commentedFashion/${widget.id}/commented-posts/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        print(jsonDecode(value.body));
        setState(() {
          loading2 = false;
        });
        jsonDecode(value.body).forEach((value){
          if(value["upload"]["media"][0]["type"] == "video"){
            VideoThumbnail.thumbnailFile(
              video: value["upload"]["media"][0]["video"],
              imageFormat: ImageFormat.JPEG,
              maxWidth: 128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
              quality: 25,
            ).then((value1){
              setState(() {
                commentedPost.add(PostModel(
                    value["id"].toString(),
                    value["description"],
                    value["upload"]["media"],
                    value["user"]["username"],
                    value["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                    false,
                    value["likesCount"].toString(),
                    value["disLikesCount"].toString(),
                    value["commentsCount"].toString(),
                    value["created"],value1!,
                    value["user"]["id"].toString(),
                    value["myLike"] == null ? "like" : value["myLike"].toString(),
                    value["eventData"],
                    value["topBadge"] ?? {"badge":null},
                    addMeInFashionWeek: value["addMeInWeekFashion"],
                    isCommentEnabled: value["isCommentOff"],
                    isLikeEnabled: value["isLikeOff"],
                    hashtags: value['hashtags'],
                    recent_stories: value['recent_stories'].length > 0 ? List<Story>.from(value['recent_stories'].map((e1){
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
                    show_stories_to_non_friends: value['user']['show_stories_to_non_friends'],
                    fanList: value["fansList"],
                    followList: value["user"]["followList"],
                    close_friends: value["close_friends"]
                ));
              });
            });
          }
          else{
            setState(() {
              commentedPost.add(PostModel(
                  value["id"].toString(),
                  value["description"],
                  value["upload"]["media"],
                  value["user"]["username"],
                  value["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                  false,
                  value["likesCount"].toString(),
                  value["disLikesCount"].toString(),
                  value["commentsCount"].toString(),
                  value["created"],"",
                  value["user"]["id"].toString(),
                  value["myLike"] == null ? "like" : value["myLike"].toString(),
                  value["eventData"],
                  value["topBadge"] ?? {"badge":null},
                  addMeInFashionWeek: value["addMeInWeekFashion"],
                  isCommentEnabled: value["isCommentOff"],
                  isLikeEnabled: value["isLikeOff"],
                  hashtags: value['hashtags'],
                  recent_stories: value['recent_stories'].length > 0 ? List<Story>.from(value['recent_stories'].map((e1){
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
                  show_stories_to_non_friends: value['user']['show_stories_to_non_friends'],
                  fanList: value["fansList"],
                  followList: value["user"]["followList"],
                  close_friends: value["close_friends"]
              ));
            });
          }
        });
      });
      getLikedPosts();
    }catch(e){
      setState(() {
        loading2 = false;
      });
      print("Error --> $e");
    }
  }
  getLikedPosts(){
    setState(() {
      loading3 = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/fashionuser/likedFashion/${widget.id}/liked-posts/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        print(jsonDecode(value.body));
        setState(() {
          loading3 = false;
        });
        jsonDecode(value.body).forEach((value){
          if(value["upload"]["media"][0]["type"] == "video"){
            VideoThumbnail.thumbnailFile(
              video: value["upload"]["media"][0]["video"],
              imageFormat: ImageFormat.JPEG,
              maxWidth: 128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
              quality: 25,
            ).then((value1){
              setState(() {
                likedPost.add(PostModel(
                    value["id"].toString(),
                    value["description"],
                    value["upload"]["media"],
                    value["user"]["name"],
                    value["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                    false,
                    value["likesCount"].toString(),
                    value["disLikesCount"].toString(),
                    value["commentsCount"].toString(),
                    value["created"],value1!,
                    value["user"]["id"].toString(),
                    value["myLike"] == null ? "like" : value["myLike"].toString(),
                    value["eventData"],
                    value["topBadge"] ?? {"badge":null},
                    addMeInFashionWeek: value["addMeInWeekFashion"],
                    isCommentEnabled: value["isCommentOff"],
                    isLikeEnabled: value["isLikeOff"],
                    hashtags: value['hashtags'],
                    recent_stories: value['recent_stories'].length > 0 ? List<Story>.from(value['recent_stories'].map((e1){
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
                    show_stories_to_non_friends: value['user']['show_stories_to_non_friends'],
                    fanList: value["fansList"],
                    followList: value["user"]["followList"],
                    close_friends: value["close_friends"]
                ));
              });
            });
          }
          else{
            setState(() {
              likedPost.add(PostModel(
                  value["id"].toString(),
                  value["description"],
                  value["upload"]["media"],
                  value["user"]["name"],
                  value["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                  false,
                  value["likesCount"].toString(),
                  value["disLikesCount"].toString(),
                  value["commentsCount"].toString(),
                  value["created"],"",
                  value["user"]["id"].toString(),
                  value["myLike"] == null ? "like" : value["myLike"].toString(),
                  value["eventData"],
                  value["topBadge"] ?? {"badge":null},
                  addMeInFashionWeek: value["addMeInWeekFashion"],
                  isCommentEnabled: value["isCommentOff"],
                  isLikeEnabled: value["isLikeOff"],
                  hashtags: value['hashtags'],
                  recent_stories: value['recent_stories'].length > 0 ? List<Story>.from(value['recent_stories'].map((e1){
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
                  show_stories_to_non_friends: value['user']['show_stories_to_non_friends'],
                  fanList: value["fansList"],
                  followList: value["user"]["followList"],
                  close_friends: value["close_friends"]
              ));
            });
          }
        });
      });
    }catch(e){
      setState(() {
        loading3 = false;
      });
      print("Error --> $e");
    }
  }

  sendRequest(userid){
    setState(() {
      requestLoader = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_send_request/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      setState(() {
        requestLoader = false;
      });
      print(value.body.toString());
      //createFriendRequestNotification(widget.username,widget.id,data);
      getMyFriends(userid);
      //sendNotification(widget.username,"You have received a friend request",UserFcm);
    }).catchError((value){
      setState(() {
        requestLoader = false;
      });
      print(value);
    });
  }
  acceptRequest(userid){
    setState(() {
      requestLoader = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_accept_request/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      print("fanrequest => "+value.body.toString());
      print("RequestIDFan ==> ${fanRequestID}");
      if(fanRequestID1 != "") {
        print("fan 1");
        addFanRequest(widget.id, id, fanRequestID1);
        //getMyFriends(widget.id);
      }else {
        setState(() {
          requestLoader = false;
        });
        print("fan 2");
        getMyFriends(widget.id);
      }
    }).catchError((value){
      setState(() {
        requestLoader = false;
      });
      print(value);
    });
  }
  rejectRequest(userid){
    setState(() {
      requestLoader = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_reject_request/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      setState(() {
        requestLoader = false;
      });
      print(value.body.toString());
      getMyFriends(widget.id);
      setState(() {
        isGetRequest = false;
      });
    }).catchError((value){
      setState(() {
        requestLoader = false;
      });
      print(value);
    });
  }
  unfriendRequest(userid){
    setState(() {
      requestLoader = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_remove/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      setState(() {
        requestLoader = false;
      });
      print("Unfriend response ==> ${value.body.toString()}");
      getMyFriends(widget.id);
      setState(() {
        isGetRequest = false;
      });
    }).catchError((value){
      setState(() {
        requestLoader = false;
      });
      print(value);
    });
  }
  cancelRequest(userid){
    setState(() {
      requestLoader = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_request_remove/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      setState(() {
        requestLoader = false;
      });
      print("Request remove response ==> ${value.body.toString()}");
      getMyFriends(widget.id);
      setState(() {
        isGetRequest = false;
      });
    }).catchError((value){
      setState(() {
        requestLoader = false;
      });
      print(value);
    });
  }
  createFriendRequestNotification(friendName,friendId,friend){
    https.post(Uri.parse("$serverUrl/friendrequestnotiApi/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    },
    body: json.encode({
      "title": "${friendName}",
      "body": "${friendName} has send you a friend request",
      "action": "send_follow_request" ,
      'sender': friendId,
      "id":id,
      'data':friend,
    })).then((value) {
      print("Notification created");
    });
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
      getMyFriends(widget.id);
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
        isfan1 = false;
      });
      print(value.body.toString());
      setState(() {
        loading = true;
        requestLoader = false;
      });
      getMyFriends(widget.id);
      getRequests();
    }).catchError((value){
      setState(() {
        requestLoader2 = false;
      });
      print(value);
    });
  }

  addFan(from,to){
    setState(() {
      requestLoader1 = true;
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
      // setState(() {
      //   requestLoader1 = false;
      // });
      // print("Fans Response ==> ${value.body.toString()}");
      // getFan(id,widget.id);
      sendFanMessage(from,to);
    }).catchError((value){
      setState(() {
        requestLoader1 = false;
      });
      print(value);
    });
  }
  removeFan(fanId){
    setState(() {
      requestLoader1 = true;
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
        requestLoader1 = false;
        isfan = false;
      });
      print(value.body.toString());
      getFan(id,widget.id);
    }).catchError((value){
      setState(() {
        requestLoader1 = false;
      });
      print(value);
    });
  }
  getFan(from,to){
    https.get(
      Uri.parse("$serverUrl/fansRequests/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).then((value){
      json.decode(value.body).forEach((e){
        if(id == e["from_user"].toString() && widget.id == e["to_user"].toString()){
         print("found fan");
         setState(() {
           isfan = true;
           fansId = e["id"].toString();
         });
        }else {
          print("Not found fan");
        }
      });
      getMyFriends(widget.id);
    }).catchError((value){
      setState(() {
        requestLoader1 = false;
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
        requestLoader1 = false;
      });
      print("Fans Response ==> ${value.body.toString()}");
      getFan(id,widget.id);
    }).catchError((value){
      setState(() {
        requestLoader1 = false;
      });
      print(value);
    });
  }

  blockUser(user,user1,user2){
    https.post(
      Uri.parse("$serverUrl/user/api/BlockUser/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        "user": id,
        "blocked_by": user
      }),
    ).then((value){
      print(value.body.toString());
      DatabaseMethods().blockChat(user1, user2);
      if(isfan == true){
        removeFan(widget.id);
      }
      if(
                 (isGetRequest == true && isGetRequestStatus == "Accepted" && fromuser == id) ||
                 (isGetRequest == true && isGetRequestStatus == "Pending" && fromuser != id)
      ){
          unfriendRequest(widget.id);
      }
      Navigator.pop(context);
      Navigator.pop(context);
      getBlockList();
     // Navigator.push(context, MaterialPageRoute(builder: (context) => FollowerScreen(),));
    }).catchError((e){
      print(e);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    });
  }
  getBadges()async{
    final response = await https.get(Uri.parse('${serverUrl}/user/api/Badge/'));

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> jsonResponse = (json.decode(response.body) as List).cast<Map<String, dynamic>>();

      BadgeList = jsonResponse.map((entry) => entry['document']as String).toList();

      // Print the result
      print("all badges$BadgeList");
    } else {
      // Handle the error if the request was not successful
      print('Error: ${response.statusCode}');
    }
  }
  getBadgesHistory()async{
    final response=await https.get(
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        Uri.parse("$serverUrl/user/api/badgehistory/"));
    if(response.statusCode==200){
      List<Map<String,dynamic>> jsonResponse=(json.decode(response.body)as List).cast<Map<String,dynamic>>();
      rankingOrders = jsonResponse.map<int>((item) => item['badge']['ranking_order'] as int).toList();
      List<Map<String, dynamic>> rankingAndDocuments = jsonResponse.map<Map<String, dynamic>>((item) {
        return {
          'ranking_order': item['badge']['ranking_order'] as int,
          'document': item['badge']['document'] as String,
        };
      }).toList();

      // Find the item with the lowest ranking order
      Map<String, dynamic>? lowestRankingOrderItem = rankingAndDocuments.reduce((min, current) =>
      min['ranking_order'] < current['ranking_order'] ? min : current);

      // Access the document field associated with the lowest ranking order
      lowestRankingOrderDocument = lowestRankingOrderItem['document'] as String;

      print('Lowest ranking order document: $lowestRankingOrderDocument');
          print('Ranking Orders: $rankingOrders');
    }
    else{
      print('Error in badge history: ${response.statusCode}');
    }
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
      print("notification data${value1.body.toString()}");
    });
  }
  unBlockUser(user,user1,user2){
    setState(() {
      loading1 = true;
    });

    https.delete(
        Uri.parse("$serverUrl/user/api/BlockUser/$user/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      print(value.body.toString());
      setState(() {
        loading1 = false;
      });
      DatabaseMethods().unBlockChat(user1, user2);
      Navigator.pop(context);
      //getBlockList();
    }).catchError((){
      setState(() {
        loading1 = false;
      });
      Navigator.pop(context);
    });
  }
  getHighlights(id){
    highlights.clear();
    setState(() {
      isLoading = true;
    });
    String url='$serverUrl/highlights/highlights/by-user/${id}/';
    try{
      https.get(Uri.parse(url),headers:
      {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        if(value.statusCode==200){
          jsonDecode(value.body).forEach((e){
            setState(() {
              highlights.add(e);
            });
          });
          setState(() {
            isLoading = false;
          });
        }
        else{
          setState(() {
            isLoading = false;
          });
          debugPrint("error received with status code and body=======>${value.statusCode} && ${value.body.toString()}");
        }
      });
    }
    catch(e){
      setState(() {
        isLoading = false;
      });
      debugPrint("error received=========>${e.toString()}");
    }
  }
  getBlockList() {
    blockList.clear();
    setState(() {
      loading = true;
    });
    https.get(Uri.parse("$serverUrl/user/api/BlockUser/block_list/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      final body = utf8.decode(value.bodyBytes);
      final jsonData = jsonDecode(body);
      print("all blocks ${value.body}");
      jsonData.forEach((data) {
        setState(() {
          blockList.add(data["blocked_user_info"]["id"]);
        });
      });
      print("final list -> ${blockList}");
    }).catchError((error) {
      print(error.toString());
    });
  }
  getFanRequest() {
    fanRequests.clear();
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/Request/api/personrequests/filter/${id}/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        jsonDecode(value.body).forEach((data) {
          setState(() {
            loading=false;
            fanRequests.add(data);
          });
          print("Requests => ${fanRequests.toString()}");
        });
        setState(() {
          loading=false;
        });
        debugPrint("total request=====>${fanRequests.length}");
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error received========>${e.toString()}");
    }
  }
  addFanRequest(from,to,myrequestID){
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
      print("Fans Response ==> ${value.body.toString()}");
      cancelFanRequest(myrequestID);
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
  }
  deleteFanRequest(fanId){
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
      getFanRequest();
    }).catchError((value){
      setState(() {
        requestLoader2 = false;
      });
      print(value);
    });
  }
  acceptFriendRequest(from,to,myrequestID){
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
      print("Fans Response ==> ${value.body.toString()}");
      deleteFanRequest(myrequestID);
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
  }

  @override
  Widget build(BuildContext context) {

    return widget.id == "" ? Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primary,
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
        title: Text("No User",style: const TextStyle(fontFamily: Poppins,color: ascent),),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/nosearch.png",height: 110,width: 110,),
            ],
          ),
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("User Not Found",style: const TextStyle(fontFamily: Poppins,color: ascent),)
            ],
          )
        ],
      ),
    ) : Scaffold(
      appBar:  AppBar(
        centerTitle: true,
        backgroundColor: primary,
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
        title: Text(widget.username,style: const TextStyle(fontFamily: Poppins),),
        actions: [
          if(widget.id != id) PopupMenuButton(
              icon:const Icon(Icons.more_horiz,color: ascent,),
              onSelected: (value) {
                if (value == 0 && blockList.contains(int.parse(widget.id)) == false) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: primary,
                      title: Text("Block ${widget.username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                      content: const Text("Do you want to block this user?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                      actions: [
                        TextButton(
                          child: const Text("No",style: TextStyle(color: ascent,fontFamily: Poppins)),
                          onPressed:  () {
                            setState(() {
                              Navigator.pop(context);
                            });
                          },
                        ),
                        TextButton(
                          child: const Text("Yes",style: TextStyle(color: ascent,fontFamily: Poppins)),
                          onPressed:  () {
                            //print(data["id"].toString());
                            blockUser(data["id"].toString(),name,data["name"]);
                          },
                        ),
                      ],
                    ),
                  );
                }
                if (value == 0 && blockList.contains(int.parse(widget.id)) == true) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: primary,
                      title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                      content: const Text("Do you want to unblock this user?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                      actions: [
                        TextButton(
                          child: const Text("Yes",style: TextStyle(color: ascent,fontFamily: Poppins)),
                          onPressed:  () {
                            //print(data["id"].toString());
                           // blockUser(data["id"].toString(),name,data["name"]);
                            unBlockUser(data["id"].toString(),name,data["name"]);
                          },
                        ),
                        TextButton(
                          child: const Text("No",style: TextStyle(color: ascent,fontFamily: Poppins)),
                          onPressed:  () {
                            setState(() {
                              Navigator.pop(context);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }
                if (value == 1){
                  //widget.navigateToPageWithReportArguments!(28,id);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ReportScreen(reportedID: id)));
                }
                // setState(() {
                // });
                // print(value);
                //Navigator.pushNamed(context, value.toString());
              }, itemBuilder: (BuildContext bc) {
            return [
              PopupMenuItem(
                value: 0,
                child: Row(
                  children:  [
                    const Icon(Icons.block,color:ascent),
                    const SizedBox(width: 10,),
                    blockList.contains(int.parse(widget.id)) == true ? const Text("Unblock",style: TextStyle(fontFamily: Poppins),):
                    const Text("Block",style: TextStyle(fontFamily: Poppins),),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.report,color:ascent),
                    SizedBox(width: 10,),
                    Text("Report",style: TextStyle(fontFamily: Poppins),),
                  ],
                ),
              ),
            ];
          })
        ],
      ),
      body: (loading == true && data.isEmpty == true) ? SpinKitCircle(color: primary,size: 50,) : SingleChildScrollView(
        child: Consumer<ThemeNotifier>(
          builder: (context, notifier, child) {
            return Container(
              height: MediaQuery.of(context).size.height * 1.55,
              child: Column(
                children: [
                  const SizedBox(height: 20,),
                  WidgetAnimator(
                    Stack(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Column(
                            //   children: [
                            //     Padding(
                            //       padding: EdgeInsets.only(right: 20),
                            //       child: Icon(Icons.favorite_outlined,
                            //           color: Colors.red, size: 30),
                            //     ),
                            //     SizedBox(height: MediaQuery.of(context).size.height*0.008,),
                            //     Padding(
                            //         padding:const EdgeInsets.only(right: 20),
                            //         child: Text((data.isEmpty == true ? "0" :data['likesCount']['likes_week_fashion'].toString()),
                            //         ))
                            //   ],
                            // ),
                            if(myList.contains(data["id"]) == false) data["show_stories_to_non_friends"] == true ? GestureDetector(
                              onTap:(data.isEmpty == true ? true : (data["recent_stories"].length <= 0)) ? (){
                              }: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                  storyList: List<Story>.from(data["recent_stories"].map((e){
                                    return Story(
                                        duration: e["time_since_created"],
                                        url: e["content"],
                                        type: e["type"],
                                        user: User(name:e["user"]["name"],username: e['user']['username'],profileImageUrl:e["user"]["pic"], id:e["user"]["id"].toString()),
                                        storyId: e["id"],
                                        viewed_users: e["viewers"],
                                        created: e["created_at"],
                                      close_friends_only: e['close_friends_only'],
                                        isPrivate: e["is_user_private"],
                                        fanList: e["fansList"]
                                    );
                                  })),
                                )));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(120)),
                                  // border: Border.all(
                                  //     width: 3.5,
                                  //     color:
                                  //     Colors.transparent),
                                  gradient: ((data.isEmpty == true ? true : data["recent_stories"].length <= 0)) ? null :(data["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ?LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.topRight,
                                      stops: const [0.0, 0.7],
                                      tileMode: TileMode.clamp,
                                      colors: <Color>[
                                        Colors.grey,
                                        Colors.grey,
                                      ]):
                                  (data["close_friends_ids"].contains(int.parse(id)) == true ? (data["recent_stories"].any((story) => story["close_friends_only"] == true) == true ? LinearGradient(
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
                                      ])):LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.topRight,
                                      stops: const [0.0, 0.7],
                                      tileMode: TileMode.clamp,
                                      colors: <Color>[
                                        secondary,
                                        primary,
                                      ]))
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black,
                                    radius: 100,
                                    child: Container(
                                      decoration: data["badge"] == null ? const BoxDecoration() : BoxDecoration(
                                          border: Border.all(
                                              width: 1,
                                              color:(
                                                  // data["badge"]["id"] == 10
                                                  //     || data["badge"]["id"] == 11
                                                  // data["badge"]["id"] == 12
                                                      data["badge"]["id"] == 13
                                                      || data["badge"]["id"] == 14
                                                      || data["badge"]["id"] == 15
                                                      || data["badge"]["id"] == 16
                                                      || data["badge"]["id"] == 17
                                                      || data["badge"]["id"] == 18
                                                      || data["badge"]["id"] == 19
                                                  //  rankingOrders.contains(1)==true
                                              ) ?primary :
                                              data["badge"]["id"] == 12?Colors.orange:
                                              data['badge']['id']==10? gold:
                                              data['badge']['id']==11?silver: Colors.black),
                                          color: Colors.black,
                                          borderRadius: const BorderRadius.all(Radius.circular(120))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(120)),
                                          child: CachedNetworkImage(
                                            imageUrl: data["pic"] != null ? data["pic"].replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/", "https://") : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                            imageBuilder: (context, imageProvider) => Container(
                                              height:MediaQuery.of(context).size.height * 0.7,
                                              width: MediaQuery.of(context).size.width,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            placeholder: (context, url) => SpinKitCircle(color: primary,size: 60,),
                                            errorWidget: (context, url, error) => ClipRRect(
                                                borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: MediaQuery.of(context).size.width * 0.9,height: MediaQuery.of(context).size.height * 0.9,)
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ): (
                                ((data["fansList"]??[]).contains(int.parse(id == "" ? "0" : id)) == true || (data["followList"]??[]).contains(int.parse(id == "" ? "0" : id)) == true) ?
                                GestureDetector(
                                  onTap:(data.isEmpty == true ? true : (data["recent_stories"].length <= 0)) ? (){
                                  }: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                      storyList: List<Story>.from(data["recent_stories"].map((e){
                                        return Story(
                                            duration: e["time_since_created"],
                                            url: e["content"],
                                            type: e["type"],
                                            user: User(name:e["user"]["name"],username: e['user']['username'],profileImageUrl:e["user"]["pic"], id:e["user"]["id"].toString()),
                                            storyId: e["id"],
                                            viewed_users: e["viewers"],
                                            created: e["created_at"],
                                            close_friends_only: e['close_friends_only'],
                                            isPrivate: e["is_user_private"],
                                            fanList: e["fansList"]
                                        );
                                      })),
                                    )));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(120)),
                                      // border: Border.all(
                                      //     width: 3.5,
                                      //     color:
                                      //     Colors.transparent),
                                      gradient: ((data.isEmpty == true ? true : data["recent_stories"].length <= 0)) ? null :(data["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ?LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.topRight,
                                          stops: const [0.0, 0.7],
                                          tileMode: TileMode.clamp,
                                          colors: <Color>[
                                            Colors.grey,
                                            Colors.grey,
                                          ]):
                                      (data["close_friends_ids"].contains(int.parse(id)) == true ? (data["recent_stories"].any((story) => story["close_friends_only"] == true) == true ? LinearGradient(
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
                                          ])):LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.topRight,
                                          stops: const [0.0, 0.7],
                                          tileMode: TileMode.clamp,
                                          colors: <Color>[
                                            secondary,
                                            primary,
                                          ]))
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: CircleAvatar(
                                         backgroundColor: Colors.black,
                                        radius: 100,
                                        child: Container(
                                          decoration: data["badge"] == null ? const BoxDecoration() : BoxDecoration(
                                              border: Border.all(
                                                  width: 1,
                                                  color:(
                                                      // data["badge"]["id"] == 10
                                                      //     || data["badge"]["id"] == 11
                                                      // data["badge"]["id"] == 12
                                                      data["badge"]["id"] == 13
                                                          || data["badge"]["id"] == 14
                                                          || data["badge"]["id"] == 15
                                                          || data["badge"]["id"] == 16
                                                          || data["badge"]["id"] == 17
                                                          || data["badge"]["id"] == 18
                                                          || data["badge"]["id"] == 19
                                                      //  rankingOrders.contains(1)==true
                                                  ) ?primary :
                                                  data["badge"]["id"] == 12?Colors.orange:
                                                  data['badge']['id']==10? gold:
                                                  data['badge']['id']==11?silver: Colors.black),
                                              color: Colors.black,
                                              borderRadius: const BorderRadius.all(Radius.circular(120))
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(3.0),
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.all(Radius.circular(120)),
                                              child: CachedNetworkImage(
                                                imageUrl: data["pic"] != null ? data["pic"].replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/", "https://") : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                imageBuilder: (context, imageProvider) => Container(
                                                  height:MediaQuery.of(context).size.height * 0.7,
                                                  width: MediaQuery.of(context).size.width,
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                placeholder: (context, url) => SpinKitCircle(color: primary,size: 60,),
                                                errorWidget: (context, url, error) => ClipRRect(
                                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                    child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: MediaQuery.of(context).size.width * 0.9,height: MediaQuery.of(context).size.height * 0.9,)
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
                                  // onTap:(data.isEmpty == true ? true : (data["recent_stories"].length <= 0)) ? (){
                                  // }: (){
                                  //   Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                  //     storyList: List<Story>.from(data["recent_stories"].map((e){
                                  //       return Story(
                                  //           duration: e["time_since_created"],
                                  //           url: e["content"],
                                  //           type: e["type"],
                                  //           user: User(name:e["user"]["name"],username: e['user']['username'],profileImageUrl:e["user"]["pic"], id:e["user"]["id"].toString()),
                                  //           storyId: e["id"],
                                  //           viewed_users: e["viewers"],
                                  //           created: e["created_at"],
                                  //           close_friends_only: e['close_friends_only']
                                  //       );
                                  //     })),
                                  //   )));
                                  // },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(120)),
                                      // border: Border.all(
                                      //     width: 3.5,
                                      //     color:
                                      //     Colors.transparent),
                                      // gradient: ((data.isEmpty == true ? true : data["recent_stories"].length <= 0)) ? null :(data["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ?LinearGradient(
                                      //     begin: Alignment.topLeft,
                                      //     end: Alignment.topRight,
                                      //     stops: const [0.0, 0.7],
                                      //     tileMode: TileMode.clamp,
                                      //     colors: <Color>[
                                      //       Colors.grey,
                                      //       Colors.grey,
                                      //     ]):
                                      // (data["close_friends_ids"].contains(int.parse(id)) == true ? (data["recent_stories"].any((story) => story["close_friends_only"] == true) == true ? LinearGradient(
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
                                      //     ])):LinearGradient(
                                      //     begin: Alignment.topLeft,
                                      //     end: Alignment.topRight,
                                      //     stops: const [0.0, 0.7],
                                      //     tileMode: TileMode.clamp,
                                      //     colors: <Color>[
                                      //       secondary,
                                      //       primary,
                                      //     ]))
                                      // ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 100,
                                      child: Container(
                                        decoration: data["badge"] == null ? const BoxDecoration() : BoxDecoration(
                                            border: Border.all(
                                                width: 1,
                                                color:(
                                                    // data["badge"]["id"] == 10
                                                    //     || data["badge"]["id"] == 11
                                                    // data["badge"]["id"] == 12
                                                    data["badge"]["id"] == 13
                                                        || data["badge"]["id"] == 14
                                                        || data["badge"]["id"] == 15
                                                        || data["badge"]["id"] == 16
                                                        || data["badge"]["id"] == 17
                                                        || data["badge"]["id"] == 18
                                                        || data["badge"]["id"] == 19
                                                    //  rankingOrders.contains(1)==true
                                                ) ?primary :
                                                data["badge"]["id"] == 12?Colors.orange:
                                                data['badge']['id']==10? gold:
                                                data['badge']['id']==11?silver: Colors.transparent),
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: const BorderRadius.all(Radius.circular(120))
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(120)),
                                          child: CachedNetworkImage(
                                            imageUrl: data["pic"] != null ? data["pic"].replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/", "https://") : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                            imageBuilder: (context, imageProvider) => Container(
                                              height:MediaQuery.of(context).size.height * 0.7,
                                              width: MediaQuery.of(context).size.width,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            placeholder: (context, url) => SpinKitCircle(color: primary,size: 60,),
                                            errorWidget: (context, url, error) => ClipRRect(
                                                borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: MediaQuery.of(context).size.width * 0.9,height: MediaQuery.of(context).size.height * 0.9,)
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                            ),
                            if(myList.contains(data["id"]) == true) GestureDetector(
                              // onTap:(data.isEmpty == true ? true : (data["recent_stories"].length <= 0)) ? (){
                              // }: (){
                              //   Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                              //     storyList: List<Story>.from(data["recent_stories"].map((e){
                              //       return Story(
                              //           duration: e["time_since_created"],
                              //           url: e["content"],
                              //           type: e["type"],
                              //           user: User(name:e["user"]["name"],username: e['user']['username'],profileImageUrl:e["user"]["pic"], id:e["user"]["id"].toString()),
                              //           storyId: e["id"],
                              //           viewed_users: e["viewers"],
                              //           created: e["created_at"],
                              //           close_friends_only: e['close_friends_only']
                              //       );
                              //     })),
                              //   )));
                              // },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(120)),
                                  // border: Border.all(
                                  //     width: 3.5,
                                  //     color:
                                  //     Colors.transparent),
                                  // gradient: ((data.isEmpty == true ? true : data["recent_stories"].length <= 0)) ? null :(data["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ?LinearGradient(
                                  //     begin: Alignment.topLeft,
                                  //     end: Alignment.topRight,
                                  //     stops: const [0.0, 0.7],
                                  //     tileMode: TileMode.clamp,
                                  //     colors: <Color>[
                                  //       Colors.grey,
                                  //       Colors.grey,
                                  //     ]):
                                  // (data["close_friends_ids"].contains(int.parse(id)) == true ? (data["recent_stories"].any((story) => story["close_friends_only"] == true) == true ? LinearGradient(
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
                                  //     ])):LinearGradient(
                                  //     begin: Alignment.topLeft,
                                  //     end: Alignment.topRight,
                                  //     stops: const [0.0, 0.7],
                                  //     tileMode: TileMode.clamp,
                                  //     colors: <Color>[
                                  //       secondary,
                                  //       primary,
                                  //     ]))
                                  // ),
                                ),
                                child: CircleAvatar(
                                  radius: 100,
                                  child: Container(
                                    decoration: data["badge"] == null ? const BoxDecoration() : BoxDecoration(
                                        border: Border.all(
                                            width: 1,
                                            color:(
                                                // data["badge"]["id"] == 10
                                                //     || data["badge"]["id"] == 11
                                                // data["badge"]["id"] == 12
                                                data["badge"]["id"] == 13
                                                    || data["badge"]["id"] == 14
                                                    || data["badge"]["id"] == 15
                                                    || data["badge"]["id"] == 16
                                                    || data["badge"]["id"] == 17
                                                    || data["badge"]["id"] == 18
                                                    || data["badge"]["id"] == 19
                                                //  rankingOrders.contains(1)==true
                                            ) ?primary :
                                            data["badge"]["id"] == 12?Colors.orange:
                                            data['badge']['id']==10? gold:
                                            data['badge']['id']==11?silver: Colors.transparent),
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: const BorderRadius.all(Radius.circular(120))
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(120)),
                                      child: CachedNetworkImage(
                                        imageUrl: data["pic"] != null ? data["pic"].replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/", "https://") : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                        imageBuilder: (context, imageProvider) => Container(
                                          height:MediaQuery.of(context).size.height * 0.7,
                                          width: MediaQuery.of(context).size.width,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        placeholder: (context, url) => SpinKitCircle(color: primary,size: 60,),
                                        errorWidget: (context, url, error) => ClipRRect(
                                            borderRadius: const BorderRadius.all(Radius.circular(50)),
                                            child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: MediaQuery.of(context).size.width * 0.9,height: MediaQuery.of(context).size.height * 0.9,)
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Column(
                            //   children: [
                            //     Padding(
                            //       padding: EdgeInsets.only(left: 20),
                            //       child: Icon(
                            //         Icons.star,
                            //         color: Colors.orange,
                            //         size: 30,
                            //       ),
                            //     ),
                            //     SizedBox(height: MediaQuery.of(context).size.height*0.008,),
                            //     Padding(
                            //       padding:const EdgeInsets.only(left: 21),
                            //       child: Text(data.isEmpty == true ? "0" : data['likesCount']['likes_non_week_fashion'].toString()),
                            //     )
                            //   ],
                            // ),
                          ],
                        ),

                        data["badge"] == null ? const SizedBox() : Positioned(
                            bottom: 1,
                            right: 80,
                            child: GestureDetector(
                                onTap: (){
                                  //Navigator.push(context, MaterialPageRoute(builder: (context) => ResultScreen()));
                                },
                                child:
                                // Image.network(data["badge"]["document"],height: 80,width: 80,errorBuilder: (context, error, stackTrace) {
                                //   return SizedBox();
                                // }
                                // )
                                ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                  child: CachedNetworkImage(
                                    imageUrl: data['badge']['document'],
                                    imageBuilder: (context, imageProvider) => Container(
                                      height:80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(Radius.circular(120)),
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    placeholder: (context, url) => SpinKitCircle(color: primary,size: 20,),
                                    errorWidget: (context, url, error) => ClipRRect(
                                        borderRadius: const BorderRadius.all(Radius.circular(50)),
                                        child: Image.network(lowestRankingOrderDocument,width: 80,height: 80,fit: BoxFit.contain,)
                                    ),
                                  ),
                                )
                            )),

                      ],
                    ),
                  ),
                  const SizedBox(height: 20,),
                  WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // GestureDetector(
                        //   onTap: (){
                        //     //Navigator.push(context, MaterialPageRoute(builder: (context) => LikesScreen()));
                        //   },
                        //   child: Column(
                        //     children: [
                        //       Row(
                        //         children: [
                        //           Text(data["likesCount"].toString(),style: const TextStyle(fontFamily: Poppins),),
                        //         ],
                        //       ),
                        //       Row(
                        //         children: [
                        //           Text("Likes",style: TextStyle(
                        //               color: primary,
                        //               fontFamily: Poppins
                        //           ),)
                        //         ],
                        //       )
                        //     ],
                        //   ),
                        // ),
                        GestureDetector(
                          onTap: (){
                            //Navigator.push(context, MaterialPageRoute(builder: (context) => StylesScreen()));
                          },
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(data["stylesCount"].toString(),style: const TextStyle(fontFamily: Poppins),),
                                ],
                              ),
                              Row(
                                children: [
                                  Text("Styles",style: TextStyle(
                                      color: primary,
                                      fontFamily: Poppins
                                  ),)
                                ],
                              )
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: (){
                            if(data["isPrivate"] == true ){
                              if((data["followList"] ?? []).contains(int.parse(id)) == true || (data["fansList"] ?? []).contains(int.parse(id)) == true){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => FriendsFans(friendId: widget.id)));
                              } else {
                                print("private");
                              }
                            }
                            if(widget.id == id || data["isPrivate"] == false){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => FriendsFans(friendId: widget.id)));
                            }
                          },
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(data["fansCount"].toString(),style: const TextStyle(fontFamily: Poppins),),
                                ],
                              ),
                              Row(
                                children: [
                                  Text("Fans",style: TextStyle(
                                      color: primary,
                                      fontFamily: Poppins
                                  ),)
                                ],
                              )
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: (){
                            //Navigator.push(context, MaterialPageRoute(builder: (context) => StylesScreen()));
                            if(data["isPrivate"] == true ){
                              if((data["followList"] ?? []).contains(int.parse(id)) == true || (data["fansList"] ?? []).contains(int.parse(id)) == true){
                                Navigator.push(context, MaterialPageRoute(builder: (context) =>  FriendsIdols(friendId: widget.id.toString())));
                              }else {
                                print("private");
                              }
                            }
                            if(widget.id == id || data["isPrivate"] == false){
                              Navigator.push(context, MaterialPageRoute(builder: (context) =>  FriendsIdols(friendId: widget.id.toString())));
                            }
                          },
                          child: Column(
                            children: [
                              Row(
                                children:  [
                                  Text(data["idolsCount"].toString(),style: const TextStyle(fontFamily: Poppins),),
                                ],
                              ),
                              Row(
                                children: [
                                  Text("Idols",style: TextStyle(
                                      color: primary,
                                      fontFamily: Poppins
                                  ),)
                                ],
                              )
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: (){
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => FollowerScreen()));
                          },
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(data["friendsCount"].toString(),style: const TextStyle(fontFamily: Poppins),),
                                ],
                              ),
                              Row(
                                children: [
                                  Text("Friends",style: TextStyle(
                                      color: primary,
                                      fontFamily: Poppins
                                  ),)
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10,),
                  if(data["isPrivate"] == true) if(widget.id != id) Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      WidgetAnimator(SizedBox(
                        height: 80,
                        child: WidgetAnimator(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if(isGetRequest == false) GestureDetector(
                                  onTap: (){
                                    // commentedPost.clear();
                                    sendRequest(widget.id);
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: [
                                                primary,
                                                secondary
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader == true
                                          ? const SpinKitCircle(color: ascent,size: 30,)
                                          : Text('Add Friend',style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                                if(isGetRequest == true && isGetRequestStatus == "Accepted" && fromuser == id) GestureDetector(
                                  onTap: (){
                                    unfriendDialog(context);
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: [
                                                Colors.grey,
                                                Colors.grey
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader == true
                                          ? const SpinKitCircle(color: ascent,size: 30,)
                                          : Text('Unfriend',style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                                if(isGetRequest == true && isGetRequestStatus == "Pending" && fromuser == id) GestureDetector(
                                  onTap: (){
                                    setState(() {
                                      requestLoader = false;
                                    });
                                    cancelRequestModal(context);
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: [
                                                Colors.grey,
                                                Colors.grey
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader == true
                                          ? const SpinKitCircle(color: ascent,size: 30,)
                                          : Text('Pending',style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                                if(isGetRequest == true && isGetRequestStatus == "Accepted" && fromuser != id) GestureDetector(
                                  onTap: (){
                                    unfriendDialog(context);
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: [
                                                Colors.grey,
                                                Colors.grey
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader == true
                                          ? const SpinKitCircle(color: ascent,size: 30,)
                                          : Text('Unfriend',style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                                if(isGetRequest == true && isGetRequestStatus == "Pending" && fromuser != id) GestureDetector(
                                  onTap: (){
                                    print("open popup");
                                    acceptRejectModal(context);
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: [
                                                secondary,
                                                primary
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader == true
                                          ? const SpinKitCircle(color: ascent,size: 30,)
                                          : Text('Accept / Reject',style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10,),
                                (data["fansList"] ?? []).contains(int.parse(id)) == false
                                    ? GestureDetector(
                                  onTap: () {
                                    if(isfan1 == false){
                                      //commentedPost.clear();
                                      sendFanRequest(id,widget.id);
                                      // showDialog(
                                      //   context: context,
                                      //   builder: (context) => AlertDialog(
                                      //     backgroundColor: primary,
                                      //     title: Text("Fan request ${data["username"]}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                      //     content: Text("Are you sure you want to send fan request to ${data["username"]}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
                                      //           print(data["id"].toString());
                                      //           Navigator.pop(context);
                                      //           sendFanRequest(id,widget.id);
                                      //         },
                                      //       ),
                                      //     ],
                                      //   ),
                                      // );
                                    }else if(isfan1 == true) {
                                      //commentedPost.clear();
                                      cancelFanRequest(fanRequestID);
                                      // showDialog(
                                      //   context: context,
                                      //   builder: (context) => AlertDialog(
                                      //     backgroundColor: primary,
                                      //     title: Text("Cancel request ${data["username"]}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                      //     content: Text("Are you sure you want to cancel fan request to ${data["username"]}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
                                      //           print(data["id"].toString());
                                      //           Navigator.pop(context);
                                      //           cancelFanRequest(fanRequestID);
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
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: isfan1 == true ? [
                                                Colors.grey,
                                                Colors.grey
                                              ] : <Color>[
                                                secondary,
                                                primary,
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader2 == true ? const SpinKitCircle(color: ascent, size: 20,) : Text(isfan1 == true ? 'Requested' :'Fan Request',style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: Poppins
                                      ),),
                                    ),
                                  ),
                                )
                                        : GestureDetector(
                                            onTap: () {
                                              if(isfan == false){
                                                // commentedPost.clear();
                                                addFan(id,widget.id);
                                              }else if(isfan == true) {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    backgroundColor: primary,
                                                    title: Text("Unfan ${data["username"]}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                                    content: Text("Are you sure you want to unfan ${data["username"]}? If you change your mind, you'll need to send a fan request again?",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
                                                          // commentedPost.clear();
                                                          Navigator.pop(context);
                                                          removeFan(widget.id);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                                            },
                                            child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: isfan == true ? [
                                                Colors.grey,
                                                Colors.grey
                                              ] : <Color>[
                                                secondary,
                                                primary,
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader1 == true ? const SpinKitCircle(color: ascent, size: 20,) : Text(isfan == true ? 'Unfan' :'Fan',style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: Poppins
                                      ),),
                                    ),
                                  ),
                                        ),
                              ],
                            )
                        ),
                      )),
                    ],
                  ),
                  if(data["isPrivate"] == false) if(widget.id != id) Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      WidgetAnimator(SizedBox(
                        height: 80,
                        child: WidgetAnimator(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if(isGetRequest == false) GestureDetector(
                                  onTap: (){
                                    // commentedPost.clear();
                                    sendRequest(widget.id);
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: [
                                                primary,
                                                secondary
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader == true
                                          ? const SpinKitCircle(color: ascent,size: 30,)
                                          : Text('Add Friend',style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                                if(isGetRequest == true && isGetRequestStatus == "Accepted" && fromuser == id) GestureDetector(
                                  onTap: (){
                                    unfriendDialog(context);
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: [
                                                Colors.grey,
                                                Colors.grey
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                        child: requestLoader == true
                                            ? const SpinKitCircle(color: ascent,size: 30,)
                                            : Text('Unfriend',style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                                if(isGetRequest == true && isGetRequestStatus == "Pending" && fromuser == id) GestureDetector(
                                  onTap: (){
                                    setState(() {
                                      requestLoader = false;
                                    });
                                    cancelRequestModal(context);
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: [
                                                Colors.grey,
                                                Colors.grey
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader == true
                                          ? const SpinKitCircle(color: ascent,size: 30,)
                                          : Text('Pending',style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                                if(isGetRequest == true && isGetRequestStatus == "Accepted" && fromuser != id) GestureDetector(
                                  onTap: (){
                                    unfriendDialog(context);
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: [
                                                Colors.grey,
                                                Colors.grey
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader == true
                                          ? const SpinKitCircle(color: ascent,size: 30,)
                                          : Text('Unfriend',style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                                if(isGetRequest == true && isGetRequestStatus == "Pending" && fromuser != id) GestureDetector(
                                  onTap: (){
                                    print("open popup");
                                    acceptRejectModal(context);
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: [
                                                secondary,
                                                primary
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader == true
                                          ? const SpinKitCircle(color: ascent,size: 30,)
                                          : Text('Accept / Reject',style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10,),
                                GestureDetector(
                                  onTap: () {
                                    if(isfan == false){
                                      // commentedPost.clear();
                                      addFan(id,widget.id);
                                    }else if(isfan == true) {
                                      //
                                      removeFan(widget.id);
                                    }
                                    //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width: MediaQuery.of(context).size.width * 0.4,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: isfan == true ? [
                                                Colors.grey,
                                                Colors.grey
                                              ] : <Color>[
                                                secondary,
                                                primary,
                                              ]),
                                          borderRadius: const BorderRadius.all(Radius.circular(12))
                                      ),
                                      child: requestLoader1 == true ? const SpinKitCircle(color: ascent, size: 20,) : Text(isfan == true ? 'Unfan' :'Fan',style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: Poppins
                                      ),),
                                    ),
                                  ),
                                ),
                              ],
                            )
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 10,),
                  WidgetAnimator(
                      Padding(
                        padding: const EdgeInsets.only(left:30.0,right:30.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(Uri.decodeComponent(data["name"].toString()), style: TextStyle(
                                color:primary,
                                fontWeight: FontWeight.bold,
                                fontFamily: Poppins
                            ),),
                            // GestureDetector(
                            //     onTap: (){
                            //       showDialog(
                            //         context: context,
                            //         builder: (context) => AlertDialog(
                            //           backgroundColor: primary,
                            //           title: Text("Fashion Time",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                            //           content: Text("Do you want to block this user.",style: TextStyle(color: ascent,fontFamily: Poppins),),
                            //           actions: [
                            //             TextButton(
                            //               child: Text("Yes",style: TextStyle(color: ascent,fontFamily: Poppins)),
                            //               onPressed:  () {
                            //                 print(data["id"].toString());
                            //                 blockUser(data["id"].toString());
                            //               },
                            //             ),
                            //             TextButton(
                            //               child: Text("No",style: TextStyle(color: ascent,fontFamily: Poppins)),
                            //               onPressed:  () {
                            //                 setState(() {
                            //                   Navigator.pop(context);
                            //                 });
                            //               },
                            //             ),
                            //           ],
                            //         ),
                            //       );
                            //     },
                            //     child: Icon(Icons.block,color: Colors.red,)),
                          ],
                        ),
                      )
                  ),
                  const SizedBox(height: 5,),
                  const SizedBox(height: 5,),
                  data["description"] == null ||  data["description"] == "" ? const SizedBox() : WidgetAnimator(
                      Row(
                        children: [
                          const SizedBox(width: 25),
                          Container(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 300.0,
                                maxWidth: 300.0,
                                minHeight: 10.0,
                                maxHeight: 50.0,
                              ),
                              child: AutoSizeText(
                                Uri.decodeComponent(data["description"]),
                                style: const TextStyle(fontFamily: Poppins),
                              ),
                            ),
                          ),
                        ],
                      )
                  ),
                  if(widget.id != id) if(data["isPrivate"] == false || (data["fansList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true || (data["followList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true) if(highlights.length > 0) const SizedBox(height: 20,),
                  if(widget.id != id) if(data["isPrivate"] == false || (data["fansList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true || (data["followList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true) if(highlights.length > 0) Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 30),
                      Text("Highlights",style: TextStyle(fontFamily: Poppins,),),
                    ],
                  ),
                  if(widget.id != id) if(data["isPrivate"] == false || (data["fansList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true || (data["followList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true) if(highlights.length > 0) const SizedBox(
                    height: 10,
                  ),
                  if(widget.id != id) if(data["isPrivate"] == false || (data["fansList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true || (data["followList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true) if(highlights.length > 0) Padding(
                    padding: const EdgeInsets.only(left:20.0),
                    child: Container(
                      height: 100,
                      width: MediaQuery.of(context).size.width,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 10,),
                              isLoading == true ? SpinKitCircle(color: primary,size: 20,) :Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: highlights.map((e){
                                  if (e["stories"][0]["type"] == "video" && thumbnailCache[id] == null) {
                                    generateAndCacheThumbnail(e["stories"][0]["content"], id);
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: GestureDetector(
                                      onTap:(e["stories"].length < 0) ? (){}: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => HighlightViewScreen(
                                          storyList: e["stories"],
                                          highlightId: e["id"].toString(),
                                          highlightname: e["title"],
                                          time: e["time_since_created"],
                                        ))).then((value){
                                          getHighlights(widget.id);
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          e["stories"][0]["type"] == "video" ? Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(80)),
                                                border: Border.all(
                                                    color: primary,
                                                    width: 2
                                                ),
                                                gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.topRight,
                                                    stops: const [0.0, 0.7],
                                                    tileMode: TileMode.clamp,
                                                    colors: <Color>[
                                                      secondary,
                                                      primary,
                                                    ])
                                            ),
                                            child: thumbnailCache[id] == null ? Text("") : Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.all(Radius.circular(80)),
                                                  color: Colors.black54,
                                                  image: DecorationImage(
                                                      image: FileImage(
                                                          thumbnailCache[id]!
                                                      ),
                                                      fit: BoxFit.cover
                                                  ),
                                                ),
                                                width: 40,
                                                child:Text("")
                                            ),
                                          ) : Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(80)),
                                                border: Border.all(
                                                    color: primary,
                                                    width: 2
                                                ),
                                                gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.topRight,
                                                    stops: const [0.0, 0.7],
                                                    tileMode: TileMode.clamp,
                                                    colors: <Color>[
                                                      secondary,
                                                      primary,
                                                    ])
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(80)),
                                                color: Colors.black54,
                                                image: e["stories"][0]["type"] == "image" ? DecorationImage(
                                                    image: NetworkImage(
                                                        e["stories"][0]["content"]
                                                    ),
                                                    fit: BoxFit.cover
                                                ): null,
                                              ),
                                              width: 40,
                                              child: e["stories"][0]["type"] == "image" ? Text("") : Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text(e["stories"][0]["content"],textAlign: TextAlign.center,style: TextStyle(
                                                    fontSize: 8,
                                                      fontFamily: Poppins
                                                  ),),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5,),
                                          Row(
                                            children: [
                                              Text("${e["title"]}",style: TextStyle(color: Colors.white,fontSize: 12,fontFamily: Poppins),)
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if(widget.id == id) if(highlights.length > 0) const SizedBox(height: 20,),
                  if(widget.id == id) if(highlights.length > 0) Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 30),
                      Text("Highlights",style: TextStyle(fontFamily: Poppins,),),
                    ],
                  ),
                  if(widget.id == id) if(highlights.length > 0) const SizedBox(
                    height: 10,
                  ),
                  if(widget.id == id) if(highlights.length > 0) Padding(
                    padding: const EdgeInsets.only(left:20.0),
                    child: Container(
                      height: 100,
                      width: MediaQuery.of(context).size.width,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 10,),
                              isLoading == true ? SpinKitCircle(color: primary,size: 20,) :Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: highlights.map((e){
                                  if (e["stories"][0]["type"] == "video" && thumbnailCache[id] == null) {
                                    generateAndCacheThumbnail(e["stories"][0]["content"], id);
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: GestureDetector(
                                      onTap:(e["stories"].length < 0) ? (){}: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => HighlightViewScreen(
                                          storyList: e["stories"],
                                          highlightId: e["id"].toString(),
                                          highlightname: e["title"],
                                          time: e["time_since_created"],
                                        ))).then((value){
                                          getHighlights(widget.id);
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          e["stories"][0]["type"] == "video" ? Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(80)),
                                                border: Border.all(
                                                    color: primary,
                                                    width: 2
                                                ),
                                                gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.topRight,
                                                    stops: const [0.0, 0.7],
                                                    tileMode: TileMode.clamp,
                                                    colors: <Color>[
                                                      secondary,
                                                      primary,
                                                    ])
                                            ),
                                            child: thumbnailCache[id] == null ? Text("") : Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.all(Radius.circular(80)),
                                                  color: Colors.black54,
                                                  image: DecorationImage(
                                                      image: FileImage(
                                                          thumbnailCache[id]!
                                                      ),
                                                      fit: BoxFit.cover
                                                  ),
                                                ),
                                                width: 40,
                                                child:Text("")
                                            ),
                                          ) : Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(80)),
                                                border: Border.all(
                                                    color: primary,
                                                    width: 2
                                                ),
                                                gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.topRight,
                                                    stops: const [0.0, 0.7],
                                                    tileMode: TileMode.clamp,
                                                    colors: <Color>[
                                                      secondary,
                                                      primary,
                                                    ])
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(80)),
                                                color: Colors.black54,
                                                image: e["stories"][0]["type"] == "image" ? DecorationImage(
                                                    image: NetworkImage(
                                                        e["stories"][0]["content"]
                                                    ),
                                                    fit: BoxFit.cover
                                                ): null,
                                              ),
                                              width: 40,
                                              child: e["stories"][0]["type"] == "image" ? Text("") : Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text(e["stories"][0]["content"],textAlign: TextAlign.center,style: TextStyle(
                                                    fontSize: 8,
                                                      fontFamily: Poppins
                                                  ),),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5,),
                                          Row(
                                            children: [
                                              Text("${e["title"]}",style: TextStyle(color: Colors.white,fontSize: 12,fontFamily: Poppins),)
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10,),
                  SizedBox(
                    height: 50,
                    child: TabBar(
                      labelColor: ascent,
                      indicatorColor: primary,
                      controller: tabController,
                      tabs:  [
                        //Tab(icon: Icon(Icons.favorite, color: _getTabIconColor(context))),
                        Tab(icon: Icon(Icons.grid_on, color: _getTabIconColor(context))),
                        Tab(
                          icon: ColorFiltered(
                            colorFilter: _getImageColorFilter(context),
                            child: Image.asset('assets/bagde.png', height: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if(widget.id != id) data.isNotEmpty == true ?((data["followList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true
                      ? Expanded(child: GridTab(tabController: tabController, loading1: loading1, myPosts: myPosts, loading2: loading2, commentedPost: commentedPost, loading3: loading3, likedPost: likedPost,badges: mediaLink,id:id,token: token,))
                      : ((data["isPrivate"] == false || (data["fansList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true) ||
                          ((data["followList"] ?? []).contains(int.parse(id == "" ? "0" : id)) == true) ?
                  Expanded(child: GridTab(tabController: tabController, loading1: loading1, myPosts: myPosts, loading2: loading2, commentedPost: commentedPost, loading3: loading3, likedPost: likedPost,badges: mediaLink,id:id,token: token,)):
                  Expanded(child: TabBarView(
                    controller: tabController,
                    children: <Widget>[
                       Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           SizedBox(height: 40,),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Container(
                                   height: 180,
                                   width: 300,
                                   decoration: BoxDecoration(
                                     image: DecorationImage(
                                         image: AssetImage(
                                             //"assets/shirtLock.png",
                                             notifier.darkTheme == true ? "assets/whiteshirt.png":"assets/shirtLock.png"
                                         )
                                     )
                                   ),
                                 child: Padding(
                                   padding: const EdgeInsets.only(top:50.0),
                                   child: Icon(Icons.lock,size: 60,color: Colors.transparent,),
                                 )
                               )
                             ],
                           ),
                           SizedBox(height: 20,),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Text("This Account is Private",
                                 style: TextStyle(
                                     fontFamily: Poppins,
                                   fontSize: 20,
                                   color: notifier.darkTheme == true ? Colors.white: Colors.black,
                                   fontWeight: FontWeight.bold
                                 ),
                               )
                             ],
                           ),
                           SizedBox(height: 10,),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Text("To view this user's Styles and Medals,",
                                 style: TextStyle(
                                     fontFamily: Poppins,
                                     fontSize: 14,
                                   color:  notifier.darkTheme == true ? Colors.white: Colors.black,
                                 ),
                               )
                             ],
                           ),
                           SizedBox(height: 5,),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Text("you need to be their fan or friend.",
                                 style: TextStyle(
                                   fontFamily: Poppins,
                                   fontSize: 14,
                                   color:  notifier.darkTheme == true ? Colors.white: Colors.black,
                                 ),
                               )
                             ],
                           ),
                         ],
                       ),
                       Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 40,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  height: 180,
                                  width: 300,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(
                                              notifier.darkTheme == true ? "assets/whiteshirt.png":"assets/shirtLock.png"
                                          )
                                      )
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top:50.0),
                                    child: Icon(Icons.lock,size: 60,color: Colors.transparent,),
                                  )
                              )
                            ],
                          ),
                          SizedBox(height: 20,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("This Account is Private",
                                style: TextStyle(
                                    fontFamily: Poppins,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  color:  notifier.darkTheme == true ? Colors.white: Colors.black,
                                ),
                              )
                            ],
                          ),
                          SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("To view this user's Styles and Medals,",
                                style: TextStyle(
                                  fontFamily: Poppins,
                                  fontSize: 14,
                                  color:  notifier.darkTheme == true ? Colors.white: Colors.black,
                                ),
                              )
                            ],
                          ),
                          SizedBox(height: 5,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("you need to be their fan or friend.",
                                style: TextStyle(
                                  fontFamily: Poppins,
                                  fontSize: 14,
                                  color:  notifier.darkTheme == true ? Colors.white: Colors.black,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ],
                  )))): Padding(
                    padding: const EdgeInsets.only(top:10.0),
                    child: Text("Loading"),
                  ),
                  // for my profile
                  if(widget.id == id) Expanded(child: GridTab(tabController: tabController, loading1: loading1, myPosts: myPosts, loading2: loading2, commentedPost: commentedPost, loading3: loading3, likedPost: likedPost,badges: mediaLink,id:id,token: token))
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Future<dynamic> unfriendDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primary,
        title: Text("Unfriend ${data["username"]}",style: TextStyle(color: ascent,fontFamily: Poppins,fontSize: 18,fontWeight: FontWeight.bold),),
        content: Text("Are you sure you want to remove ${data["username"]} as your friend?",style: TextStyle(color: ascent,fontFamily: Poppins),),
        actions: [
          TextButton(
            child: const Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
            onPressed:  () {
              setState(() {
                Navigator.pop(context);
              });
            },
          ),
          TextButton(
            child: const Text("Unfriend",style: TextStyle(color: ascent,fontFamily: Poppins)),
            onPressed:  () {
              setState(() {
                Navigator.pop(context);
                unfriendRequest(widget.id);
              });
            },
          ),
        ],
      ),
    );
  }

  Future<dynamic> acceptRejectModal(BuildContext context) {
    return showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext bc){
                                      return Container(
                                        child: Wrap(
                                          children: <Widget>[
                                            ListTile(
                                                leading: const Icon(Icons.check,color: Colors.green,),
                                                title: const Text('Accept',style: TextStyle(fontFamily: Poppins,color:Colors.green),),
                                                onTap: (){
                                                  Navigator.pop(context);
                                                  acceptRequest(requestID);
                                                }
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.close,color: Colors.red,),
                                              title: const Text('Reject',style: TextStyle(fontFamily: Poppins,color: Colors.red),),
                                              onTap: (){
                                                Navigator.pop(context);
                                                rejectRequest(requestID);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                );
  }

  Future<dynamic> cancelRequestModal(BuildContext context) {
    return showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext bc){
                                      return Container(
                                        child: Wrap(
                                          children: <Widget>[
                                            ListTile(
                                              leading: const Icon(Icons.close,color: Colors.red,),
                                              title: const Text('Cancel Friend Request',style: TextStyle(fontFamily: Poppins,color: Colors.red),),
                                              onTap: (){
                                                print("Request Id ==> $requestID");
                                                Navigator.pop(context);
                                                cancelRequest(widget.id);
                                                //rejectRequest(requestID);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                );
  }
}

class GridTab extends StatelessWidget {
  const GridTab({
    super.key,
    required this.tabController,
    required this.loading1,
    required this.myPosts,
    required this.loading2,
    required this.commentedPost,
    required this.loading3,
    required this.likedPost,
    required this.badges, required this.id, required this.token
  });

  final TabController tabController;
  final bool loading1;
  final List<PostModel> myPosts;
  final bool loading2;
  final List<PostModel> commentedPost;
  final bool loading3;
  final List<PostModel> likedPost;
  final List<String> badges;
  final String id;
  final String token;

  @override
  Widget build(BuildContext context) {
    Color getTabIconColor(BuildContext context) {

      bool isDarkMode = Theme.of(context).brightness == Brightness.dark;


      return isDarkMode ? Colors.white : primary;
    }
    return TabBarView(
      controller: tabController,
      children: <Widget>[
        loading2 == true ? SpinKitCircle(color: primary,size: 50,) : (commentedPost.length <= 0 ? Column(
          children: [
            SizedBox(height: 40,),
            Text("No Posts",textAlign: TextAlign.center,style: TextStyle(fontFamily: Poppins)),
          ],
        ) :
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: commentedPost.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            // mainAxisSpacing: 10
          ),
          itemBuilder: (BuildContext context, int index){
            return WidgetAnimator(
              GestureDetector(
                onTap: (){
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => SwapDetail(
                  //   userid:commentedPost[index].userid,
                  //   image: commentedPost[index].images,
                  //   description:  commentedPost[index].description,
                  //   style: "Fashion Style 2",
                  //   createdBy: commentedPost[index].userName,
                  //   profile: commentedPost[index].userPic,
                  //   likes: commentedPost[index].likeCount,
                  //   dislikes: commentedPost[index].dislikeCount,
                  //   mylike: commentedPost[index].mylike,
                  //   addMeInFashionWeek: commentedPost[index].addMeInFashionWeek,
                  //   isPrivate: commentedPost[index].isPrivate ?? false,
                  //   fansList: commentedPost[index].fanList!,
                  //   id: id,
                  //   followList: commentedPost[index].followList!,
                  //   username: commentedPost[index].userName,
                  //   token: token,
                  // )));
                },
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Stack(
                    children: [
                      Container(
                        child: commentedPost[index].images[0]["type"] == "video"? Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                fit: BoxFit.cover,
                                image: FileImage(File(commentedPost[index].thumbnail))
                            ),
                            //borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ) :CachedNetworkImage(
                          imageUrl: commentedPost[index].images[0]["image"],
                          fit: BoxFit.fill,
                          height: 820,
                          width: 200,
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: SpinKitCircle(color: primary,size: 20,),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height:MediaQuery.of(context).size.height * 0.84,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
                                  fit: BoxFit.cover
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                          right:10,
                          child: Padding(
                            padding: const EdgeInsets.only(top:8.0),
                            child:commentedPost[index].images[0]["type"] == "video" ?const Icon(Icons.video_camera_back) : const Icon(Icons.image),
                          ))
                    ],
                  ),
                ),
              ),
            );
          },
        )),
        loading3 == true ? SpinKitCircle(color: primary,size: 50,) : (badges.isEmpty ? Column(
          children: [
            SizedBox(height: 40,),
            Text("No Posts",style: TextStyle(fontFamily: Poppins)),
          ],
        ) :
        SingleChildScrollView(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              // mainAxisSpacing: 10
            ),
            itemBuilder: (BuildContext context, int index){
              return WidgetAnimator(
                GestureDetector(
                  // onTap: (){
                  //   Navigator.push(context, MaterialPageRoute(builder: (context) => SwapDetail(
                  //     userid:likedPost[index].userid,
                  //     image: likedPost[index].images,
                  //     description:  likedPost[index].description,
                  //     style: "Fashion Style 2",
                  //     createdBy: likedPost[index].userName,
                  //     profile: likedPost[index].userPic,
                  //     likes: likedPost[index].likeCount,
                  //     dislikes: likedPost[index].dislikeCount,
                  //     mylike: likedPost[index].mylike,
                  //   )));
                  // },
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Stack(
                      children: [
                        Container(

                          decoration: const BoxDecoration(
                            // borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: badges.isNotEmpty? Container(
                            height: 120,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(badges[index]),


                              ),
                              //borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ) :CachedNetworkImage(
                            imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png',
                            fit: BoxFit.cover,
                            height: 820,
                            width: 200,
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 20.0,
                                height: 20.0,
                                child: SpinKitCircle(color: primary,size: 20,),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height:MediaQuery.of(context).size.height * 0.84,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
                                    fit: BoxFit.cover
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                            right:10,
                            child: Padding(
                              padding: const EdgeInsets.only(top:8.0),
                              child:Image.asset('assets/bagde.png',height: 28,color:getTabIconColor(context) ),
                            ))
                        // Positioned(
                        //     right:10,
                        //     child: Padding(
                        //       padding: const EdgeInsets.only(top:8.0),
                        //       child:likedPost[index].images[0]["type"] == "video" ?Icon(Icons.video_camera_back) : Icon(Icons.image),
                        //     ))
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        )
            // GridView.builder(
            //   physics: NeverScrollableScrollPhysics(),
            //   shrinkWrap: true,
            //   itemCount: likedPost.length,
            //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            //     crossAxisCount: 3,
            //     // mainAxisSpacing: 10
            //   ),
            //   itemBuilder: (BuildContext context, int index){
            //     return WidgetAnimator(
            //       GestureDetector(
            //         onTap: (){
            //           Navigator.push(context, MaterialPageRoute(builder: (context) => SwapDetail(
            //             userid:likedPost[index].userid,
            //             image: likedPost[index].images,
            //             description:  likedPost[index].description,
            //             style: "Fashion Style 2",
            //             createdBy: likedPost[index].userName,
            //             profile: likedPost[index].userPic,
            //             likes: likedPost[index].likeCount,
            //             dislikes: likedPost[index].dislikeCount,
            //             mylike: likedPost[index].mylike,
            //           )));
            //         },
            //         child: Padding(
            //           padding: const EdgeInsets.all(1.0),
            //           child: Stack(
            //             children: [
            //               Container(
            //                 decoration: BoxDecoration(
            //                   // borderRadius: BorderRadius.all(Radius.circular(10)),
            //                 ),
            //                 child: likedPost[index].images[0]["type"] == "video"? Container(
            //                   decoration: BoxDecoration(
            //                     image: DecorationImage(
            //                         fit: BoxFit.cover,
            //                         image: FileImage(File(likedPost[index].thumbnail))
            //                     ),
            //                     //borderRadius: BorderRadius.all(Radius.circular(10)),
            //                   ),
            //                 ) :ClipRRect(
            //                   // borderRadius: BorderRadius.circular(10),
            //                   child: CachedNetworkImage(
            //                     imageUrl: likedPost[index].images[0]["image"],
            //                     fit: BoxFit.fill,
            //                     height: 820,
            //                     width: 200,
            //                     placeholder: (context, url) => Center(
            //                       child: SizedBox(
            //                         width: 20.0,
            //                         height: 20.0,
            //                         child: SpinKitCircle(color: primary,size: 20,),
            //                       ),
            //                     ),
            //                     errorWidget: (context, url, error) => Container(
            //                       height:MediaQuery.of(context).size.height * 0.84,
            //                       width: MediaQuery.of(context).size.width,
            //                       decoration: BoxDecoration(
            //                         image: DecorationImage(
            //                             image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
            //                             fit: BoxFit.cover
            //                         ),
            //                       ),
            //                     ),
            //                   ),
            //                 ),
            //               ),
            //               // Positioned(
            //               //     right:10,
            //               //     child: Padding(
            //               //       padding: const EdgeInsets.only(top:8.0),
            //               //       child:likedPost[index].images[0]["type"] == "video" ?Icon(Icons.video_camera_back) : Icon(Icons.image),
            //               //     ))
            //             ],
            //           ),
            //         ),
            //       ),
            //     );
            //   },
            // )
        ),
      ],
    );
  }
}