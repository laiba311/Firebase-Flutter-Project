import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/models/story_model.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/swap_detail.dart';
import 'package:finalfashiontimefrontend/screens/stories/view_story.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';

class MyProfileScreen extends StatefulWidget {
  final String id;
  final String username;
  const MyProfileScreen({Key? key, required this.id, required this.username}) : super(key: key);

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> with SingleTickerProviderStateMixin {
  String id = "";
  String token = "";
  bool loading = false;
  Map<String,dynamic> data = {};
  bool requestLoader = false;
  bool requestLoader1 = false;
  bool isGetRequest = false;
  String requestID = "";
  String fanId = "";
  bool loading1 = false;
  bool loading2 = false;
  bool loading3 = false;
  List<PostModel> myPosts = [];
  List<PostModel> commentedPost = [];
  List<PostModel> likedPost = [];
  late TabController tabController;
  List<String> BadgeList = [];
  late List<int>rankingOrders=[];
   String lowestRankingOrderDocument="";
  List<String>mediaLink=[];
  List<PostModel> medalPostsModel = [];

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(token);
    getMyFriends(widget.id);
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


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    getCashedData();
  }
  getPostsWithMedal() {
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/fashionUpload/top-trending/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }).then((value) {
        mediaLink.clear();
       // print("Timer ==> ${jsonDecode(value.body)}");
        setState(() {
          //myDuration = Duration(seconds: int.parse(jsonDecode(value.body)["result"]["time_remaining"].));
          loading = false;
        });
        jsonDecode(value.body)["result"].forEach((value) {
          if(value['user']['id'].toString()==id.toString()){
            if (value["upload"]["media"][0]["type"] == "video") {
              VideoThumbnail.thumbnailFile(
                video: value["upload"]["media"][0]["video"],
                imageFormat: ImageFormat.JPEG,
                maxWidth:
                128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
                quality: 25,
              ).then((value1) {
                setState(() {
                  medalPostsModel.add(PostModel(
                      value["id"].toString(),
                      value["description"],
                      value["upload"]["media"],
                      value["user"]["username"],
                      value["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                      false,
                      value["likesCount"].toString(),
                      value["disLikesCount"].toString(),
                      value["commentsCount"].toString(),
                      value["created"],
                      value1!,
                      value["user"]["id"].toString(),
                      value["myLike"] == null
                          ? "like"
                          : value["myLike"].toString(),
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
                mediaLink.add(value['upload']['media'][0]['video'].toString());
                print("imageslinks is ${mediaLink.toString()}");
                print("current user data is ${medalPostsModel.toString()}");
              });
            } else {
              setState(() {
                medalPostsModel.add(PostModel(
                    value["id"].toString(),
                    value["description"],
                    value["upload"]["media"],
                    value["user"]["username"],
                    value["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                    false,
                    value["likesCount"].toString(),
                    value["disLikesCount"].toString(),
                    value["commentsCount"].toString(),
                    value["created"],
                    "",
                    value["user"]["id"].toString(),
                    value["myLike"] == null
                        ? "like"
                        : value["myLike"].toString(),
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
              mediaLink.add(value['upload']['media'][0]['image'].toString());
              print("imageslinks is ${mediaLink.toString()}");
              print("current user data is ${medalPostsModel.toString()}");
            }
          }});
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }

  getMyFriends(id){
    setState(() {
      loading = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/user/api/allUsers/$id"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        final body = utf8.decode(value.bodyBytes);
        final jsonData = jsonDecode(body);
        setState(() {
          data = jsonData;
        });
        print("Friend data $data");
        print(jsonDecode(value.body).toString());
        matchFriendReques(widget.id);
      });
    }catch(e){
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  matchFriendReques(id1){
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
            setState(() {
              loading = false;
              isGetRequest = true;
              requestID = request["id"].toString();
            });
            print(isGetRequest.toString());
            print(requestID.toString());
          }else{
            setState(() {
              loading = false;
            });
            print(isGetRequest.toString());
          }
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
      print("Error --> $e");
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
      getPostsWithMedal();
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
              commentedPost.add(PostModel(
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
      getMyFriends(userid);
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
      setState(() {
        requestLoader = false;
      });
      print(value.body.toString());
      getMyFriends(widget.id);
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
      print(value.body.toString());
      getMyFriends(widget.id);
    }).catchError((value){
      setState(() {
        requestLoader = false;
      });
      print(value);
    });
  }

  addFan(from,to){
    setState(() {
      requestLoader1 = true;
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
        requestLoader1 = false;
      });
      print(value.body.toString());
      getMyFriends(widget.id);
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
      });
      print(value.body.toString());
      getMyFriends(widget.id);
    }).catchError((value){
      setState(() {
        requestLoader1 = false;
      });
      print(value);
    });
  }

  blockUser(user){
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
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
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
        title:data['username']==null?const Text(""):
        Text(data['username'].toString(),style: const TextStyle(fontFamily: Poppins),),
        actions: const [
          // PopupMenuButton(
          //     icon:Icon(Icons.more_horiz),
          //     onSelected: (value) {
          //       if (value == 0) {
          //         showDialog(
          //           context: context,
          //           builder: (context) => AlertDialog(
          //             backgroundColor: primary,
          //             title: Text("Fashion Time",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
          //             content: Text("Do you want to block this user.",style: TextStyle(color: ascent,fontFamily: Poppins),),
          //             actions: [
          //               TextButton(
          //                 child: Text("Yes",style: TextStyle(color: ascent,fontFamily: Poppins)),
          //                 onPressed:  () {
          //                   print(data["id"].toString());
          //                   blockUser(data["id"].toString());
          //                 },
          //               ),
          //               TextButton(
          //                 child: Text("No",style: TextStyle(color: ascent,fontFamily: Poppins)),
          //                 onPressed:  () {
          //                   setState(() {
          //                     Navigator.pop(context);
          //                   });
          //                 },
          //               ),
          //             ],
          //           ),
          //         );
          //       }
          //       setState(() {
          //       });
          //       print(value);
          //       //Navigator.pushNamed(context, value.toString());
          //     }, itemBuilder: (BuildContext bc) {
          //   return [
          //     PopupMenuItem(
          //       value: 0,
          //       child: Text("Block",style: TextStyle(fontFamily: Poppins),),
          //     ),
          //   ];
          // })
        ],
      ),
      body: loading == true ? SpinKitCircle(color: primary,size: 50,) : SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 1.5,
          child: Column(
            children: [
              const SizedBox(height: 20,),
              WidgetAnimator(
                Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap:(data["recent_stories"].length <= 0) ? (){}: (){
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
                                border: Border.all(
                                    width: 3.5,
                                    color:
                                    Colors.transparent),
                                gradient: data["recent_stories"].length > 0 ? (data["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ?LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.topRight,
                                    stops: const [0.0, 0.7],
                                    tileMode: TileMode.clamp,
                                    colors: <Color>[
                                      Colors.grey,
                                      Colors.grey,
                                    ]):LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.topRight,
                                    stops: const [0.0, 0.7],
                                    tileMode: TileMode.clamp,
                                    colors: <Color>[
                                      secondary,
                                      primary,
                                    ])):null,
                                borderRadius:
                                const BorderRadius.all(
                                    Radius.circular(120))),
                            child: CircleAvatar(
                              radius: 100,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: const BorderRadius.all(Radius.circular(120))
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                  child: CachedNetworkImage(
                                    imageUrl: data["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
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
                                imageUrl: lowestRankingOrderDocument,
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
                                    child: Image.network(data["badge"]["document"],width: 80,height: 80,fit: BoxFit.contain,)
                                ),
                              ),
                            )
                        )),

                  ],
                ),
              ),
              const SizedBox(height: 20,),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     WidgetAnimator(Container(
              //       height: 80,
              //       child: WidgetAnimator(
              //           Row(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             crossAxisAlignment: CrossAxisAlignment.center,
              //             children: [
              //               GestureDetector(
              //                 onTap: data["isFollow"] == true ? (){
              //                   print("unfried request");
              //                   unfriendRequest(widget.id);
              //                 }:(){
              //                   if(isGetRequest == true){
              //                     print("open popup");
              //                     showModalBottomSheet(
              //                         context: context,
              //                         builder: (BuildContext bc){
              //                           return Container(
              //                             child: new Wrap(
              //                               children: <Widget>[
              //                                 new ListTile(
              //                                     leading: new Icon(Icons.check,color: Colors.green,),
              //                                     title: new Text('Accept',style: TextStyle(fontFamily: Poppins,color:Colors.green),),
              //                                     onTap: (){
              //                                       Navigator.pop(context);
              //                                       acceptRequest(requestID);
              //                                     }
              //                                 ),
              //                                 new ListTile(
              //                                   leading: new Icon(Icons.close,color: Colors.red,),
              //                                   title: new Text('Reject',style: TextStyle(fontFamily: Poppins,color: Colors.red),),
              //                                   onTap: (){
              //                                     Navigator.pop(context);
              //                                     rejectRequest(requestID);
              //                                   },
              //                                 ),
              //                               ],
              //                             ),
              //                           );
              //                         }
              //                     );
              //                   }
              //                   else if(isGetRequest == false){
              //                     print("unfried request");
              //                     sendRequest(widget.id);
              //                   }
              //                   else if(data["follow_status"] == null){
              //                     sendRequest(widget.id);
              //                   }else {
              //                     print("send request");
              //                   }
              //                 },
              //                 child: Card(
              //                   shape: RoundedRectangleBorder(
              //                       borderRadius: BorderRadius.all(Radius.circular(15))
              //                   ),
              //                   child: Container(
              //                     alignment: Alignment.center,
              //                     height: 50,
              //                     width: MediaQuery.of(context).size.width * 0.4,
              //                     decoration: BoxDecoration(
              //                         gradient: LinearGradient(
              //                             begin: Alignment.topLeft,
              //                             end: Alignment.topRight,
              //                             stops: [0.0, 0.99],
              //                             tileMode: TileMode.clamp,
              //                             colors: <Color>[
              //                               secondary,
              //                               primary,
              //                             ]),
              //                         borderRadius: BorderRadius.all(Radius.circular(15))
              //                     ),
              //                     child:requestLoader == true ? SpinKitCircle(color: ascent,size: 30,) : (data["isFollow"] == true ? Text('Unfriend',style: TextStyle(
              //                         fontSize: 15,
              //                         fontWeight: FontWeight.w700,
              //                         fontFamily: Poppins
              //                     ),) : Text(data["follow_status"] == null ? 'Friend':'Pending',style: TextStyle(
              //                         fontSize: 15,
              //                         fontWeight: FontWeight.w700,
              //                         fontFamily: Poppins
              //                     ),)),
              //                   ),
              //                 ),
              //               ),
              //               SizedBox(width: 10,),
              //               GestureDetector(
              //                 onTap: () {
              //                   if(data["isFan"] == false){
              //                     addFan(id,widget.id);
              //                   }else if(data["isFan"] == true) {
              //                     removeFan(widget.id);
              //                   }
              //                   //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
              //                 },
              //                 child: Card(
              //                   shape: RoundedRectangleBorder(
              //                       borderRadius: BorderRadius.all(Radius.circular(15))
              //                   ),
              //                   child: Container(
              //                     alignment: Alignment.center,
              //                     height: 50,
              //                     width: MediaQuery.of(context).size.width * 0.4,
              //                     decoration: BoxDecoration(
              //                         gradient: LinearGradient(
              //                             begin: Alignment.topLeft,
              //                             end: Alignment.topRight,
              //                             stops: [0.0, 0.99],
              //                             tileMode: TileMode.clamp,
              //                             colors: <Color>[
              //                               secondary,
              //                               primary,
              //                             ]),
              //                         borderRadius: BorderRadius.all(Radius.circular(15))
              //                     ),
              //                     child: requestLoader1 == true ? SpinKitCircle(color: ascent, size: 20,) : Text(data["isFan"] == true ? 'Unfan' :'Fan',style: TextStyle(
              //                         fontSize: 15,
              //                         fontWeight: FontWeight.w700,
              //                         fontFamily: Poppins
              //                     ),),
              //                   ),
              //                 ),
              //               ),
              //             ],
              //           )
              //       ),
              //     )),
              //   ],
              // ),
              const SizedBox(height: 15,),
              WidgetAnimator(
                  Padding(
                    padding: const EdgeInsets.only(left:30.0,right:30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Uri.decodeComponent(data["name"].toString()), style: TextStyle(
                          color: primary,
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
              const SizedBox(height: 10,),
              // WidgetAnimator(
              //     Row(
              //       children: [
              //         SizedBox(width: 25),
              //         Text("@${data["username"].toString()}", style: TextStyle(
              //             color: primary,
              //             fontWeight: FontWeight.bold,
              //             fontFamily: Poppins
              //         ),)
              //       ],
              //     )
              // ),
              // SizedBox(height: 5,),
              data["description"] == null || data["description"] == "" ? const SizedBox() : WidgetAnimator(
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
                            Uri.decodeComponent(data["description"]) ?? "",
                            style: const TextStyle(fontSize: 20.0,fontFamily: Poppins),
                          ),
                        ),
                      ),
                    ],
                  )
              ),
              const SizedBox(height: 5,),
              SizedBox(
                height: 50,
                child: TabBar(
                  controller: tabController,
                  tabs: [

                    Tab(icon: Icon(Icons.grid_on,color: _getTabIconColor(context),)),
                    Tab(icon: Icon(Icons.favorite,color: _getTabIconColor(context),)),
                    Tab(icon: ColorFiltered(
                      colorFilter: _getImageColorFilter(context),
                        child: Image.asset('assets/bagde.png',height: 28)),
                    ),

                  ],
                ),
              ),
              Expanded(child: GridTab(tabController: tabController, loading1: loading1, myPosts: myPosts, loading2: loading2, commentedPost: commentedPost, loading3: loading3, likedPost: likedPost,badges: mediaLink,id: id,token: token,)),
            ],
          ),
        ),
      ),
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
        loading1 == true ? SpinKitCircle(color: primary,size: 50,) :
        (commentedPost.isEmpty ? Column(
          children: [
            SizedBox(height: 40,),
            Text("No Posts",textAlign: TextAlign.center,style: TextStyle(fontFamily: Poppins)),
          ],
        ) : GridView.builder(
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
                  //   isPrivate: commentedPost[index].isPrivate!,
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
        // (myPosts.length <= 0 ? Center(child: Container(child: Text("No Posts"))) : GridView.builder(
        //   physics: NeverScrollableScrollPhysics(),
        //   shrinkWrap: true,
        //   itemCount: myPosts.length,
        //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        //     crossAxisCount: 3,
        //     //mainAxisSpacing: 10
        //   ),
        //   itemBuilder: (BuildContext context, int index){
        //     return WidgetAnimator(
        //       GestureDetector(
        //         onTap: (){
        //           Navigator.push(context, MaterialPageRoute(builder: (context) => SwapDetail(
        //             userid:myPosts[index].userid,
        //             image: myPosts[index].images,
        //             description:  myPosts[index].description,
        //             style: "Fashion Style 2",
        //             createdBy: myPosts[index].userName,
        //             profile: myPosts[index].userPic,
        //             likes: myPosts[index].likeCount,
        //             dislikes: myPosts[index].dislikeCount,
        //             mylike: myPosts[index].mylike,
        //           )));
        //         },
        //         child: Padding(
        //           padding: const EdgeInsets.all(1.0),
        //           child: Stack(
        //             children: [
        //               Container(
        //                 child: myPosts[index].images[0]["type"] == "video"? Container(
        //                   decoration: BoxDecoration(
        //                     image: DecorationImage(
        //                         fit: BoxFit.cover,
        //                         image: FileImage(File(myPosts[index].thumbnail))
        //                     ),
        //                     // borderRadius: BorderRadius.all(Radius.circular(10)),
        //                   ),
        //                 ) :CachedNetworkImage(
        //                   imageUrl: myPosts[index].images[0]["image"],
        //                   fit: BoxFit.fill,
        //                   height: 820,
        //                   width: 200,
        //                   placeholder: (context, url) => Center(
        //                     child: SizedBox(
        //                       width: 20.0,
        //                       height: 20.0,
        //                       child: SpinKitCircle(color: primary,size: 20,),
        //                     ),
        //                   ),
        //                   errorWidget: (context, url, error) => Container(
        //                     height:MediaQuery.of(context).size.height * 0.84,
        //                     width: MediaQuery.of(context).size.width,
        //                     decoration: BoxDecoration(
        //                       image: DecorationImage(
        //                           image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
        //                           fit: BoxFit.cover
        //                       ),
        //                     ),
        //                   ),
        //                 ),
        //               ),
        //               Positioned(
        //                   right:10,
        //                   child: Padding(
        //                     padding: const EdgeInsets.only(top:8.0),
        //                     child:myPosts[index].images[0]["type"] == "video" ?Icon(Icons.video_camera_back) : Icon(Icons.image),
        //                   ))
        //             ],
        //           ),
        //         ),
        //       ),
        //     );
        //   },
        // )),
        loading2 == true ? SpinKitCircle(color: primary,size: 50,) :
        (myPosts.isEmpty ?Column(
          children: [
            SizedBox(height: 40,),
            Text("No Posts",textAlign: TextAlign.center,style: TextStyle(fontFamily: Poppins)),
          ],
        ) : GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: myPosts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            //mainAxisSpacing: 10
          ),
          itemBuilder: (BuildContext context, int index){
            return WidgetAnimator(
              GestureDetector(
                onTap: (){
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => SwapDetail(
                  //   userid:myPosts[index].userid,
                  //   image: myPosts[index].images,
                  //   description:  myPosts[index].description,
                  //   style: "Fashion Style 2",
                  //   createdBy: myPosts[index].userName,
                  //   profile: myPosts[index].userPic,
                  //   likes: myPosts[index].likeCount,
                  //   dislikes: myPosts[index].dislikeCount,
                  //   mylike: myPosts[index].mylike,
                  //   addMeInFashionWeek: myPosts[index].addMeInFashionWeek,
                  //   isPrivate: myPosts[index].isPrivate!,
                  //   fansList: myPosts[index].fanList!,
                  //   id: id,
                  //   followList: myPosts[index].followList!,
                  //   username: myPosts[index].userName,
                  //   token: token,
                  // )));
                },
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Stack(
                    children: [
                      Container(
                        child: myPosts[index].images[0]["type"] == "video"? Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                                fit: BoxFit.cover,
                                image: FileImage(File(myPosts[index].thumbnail))
                            ),
                            // borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ) :CachedNetworkImage(
                          imageUrl: myPosts[index].images[0]["image"],
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
                            child:myPosts[index].images[0]["type"] == "video" ?const Icon(Icons.video_camera_back) : const Icon(Icons.image),
                          ))
                    ],
                  ),
                ),
              ),
            );
          },
        )),
        // (commentedPost.length <= 0 ? Center(child: Container(child: Text("No Posts"))) : GridView.builder(
        //   physics: NeverScrollableScrollPhysics(),
        //   shrinkWrap: true,
        //   itemCount: commentedPost.length,
        //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        //     crossAxisCount: 3,
        //     // mainAxisSpacing: 10
        //   ),
        //   itemBuilder: (BuildContext context, int index){
        //     return WidgetAnimator(
        //       GestureDetector(
        //         onTap: (){
        //           Navigator.push(context, MaterialPageRoute(builder: (context) => SwapDetail(
        //             userid:commentedPost[index].userid,
        //             image: commentedPost[index].images,
        //             description:  commentedPost[index].description,
        //             style: "Fashion Style 2",
        //             createdBy: commentedPost[index].userName,
        //             profile: commentedPost[index].userPic,
        //             likes: commentedPost[index].likeCount,
        //             dislikes: commentedPost[index].dislikeCount,
        //             mylike: commentedPost[index].mylike,
        //           )));
        //         },
        //         child: Padding(
        //           padding: const EdgeInsets.all(1.0),
        //           child: Stack(
        //             children: [
        //               Container(
        //                 child: commentedPost[index].images[0]["type"] == "video"? Container(
        //                   decoration: BoxDecoration(
        //                     image: DecorationImage(
        //                         fit: BoxFit.cover,
        //                         image: FileImage(File(commentedPost[index].thumbnail))
        //                     ),
        //                     //borderRadius: BorderRadius.all(Radius.circular(10)),
        //                   ),
        //                 ) :CachedNetworkImage(
        //                   imageUrl: commentedPost[index].images[0]["image"],
        //                   fit: BoxFit.fill,
        //                   height: 820,
        //                   width: 200,
        //                   placeholder: (context, url) => Center(
        //                     child: SizedBox(
        //                       width: 20.0,
        //                       height: 20.0,
        //                       child: SpinKitCircle(color: primary,size: 20,),
        //                     ),
        //                   ),
        //                   errorWidget: (context, url, error) => Container(
        //                     height:MediaQuery.of(context).size.height * 0.84,
        //                     width: MediaQuery.of(context).size.width,
        //                     decoration: BoxDecoration(
        //                       image: DecorationImage(
        //                           image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
        //                           fit: BoxFit.cover
        //                       ),
        //                     ),
        //                   ),
        //                 ),
        //               ),
        //               Positioned(
        //                   right:10,
        //                   child: Padding(
        //                     padding: const EdgeInsets.only(top:8.0),
        //                     child:commentedPost[index].images[0]["type"] == "video" ?Icon(Icons.video_camera_back) : Icon(Icons.image),
        //                   ))
        //             ],
        //           ),
        //         ),
        //       ),
        //     );
        //   },
        // ))

        loading3 == true ? SpinKitCircle(color: primary,size: 50,) : (badges.isEmpty ?Column(
          children: [
            SizedBox(height: 40,),
            Text("No Posts",textAlign: TextAlign.center,style: TextStyle(fontFamily: Poppins)),
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
                        // Positioned(
                        //     right:10,
                        //     child: Padding(
                        //       padding: const EdgeInsets.only(top:8.0),
                        //       child:likedPost[index].images[0]["type"] == "video" ?Icon(Icons.video_camera_back) : Icon(Icons.image),
                        //     ))
                        Positioned(
                            right:10,
                            child: Padding(
                              padding: const EdgeInsets.only(top:8.0),
                              child:Image.asset('assets/bagde.png',height: 28,color: getTabIconColor(context),),
                            ))
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
        //                 ) :CachedNetworkImage(
        //                   imageUrl: likedPost[index].images[0]["image"],
        //                   fit: BoxFit.fill,
        //                   height: 820,
        //                   width: 200,
        //                   placeholder: (context, url) => Center(
        //                     child: SizedBox(
        //                       width: 20.0,
        //                       height: 20.0,
        //                       child: SpinKitCircle(color: primary,size: 20,),
        //                     ),
        //                   ),
        //                   errorWidget: (context, url, error) => Container(
        //                     height:MediaQuery.of(context).size.height * 0.84,
        //                     width: MediaQuery.of(context).size.width,
        //                     decoration: BoxDecoration(
        //                       image: DecorationImage(
        //                           image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
        //                           fit: BoxFit.cover
        //                       ),
        //                     ),
        //                   ),
        //                 ),
        //               ),
        //               Positioned(
        //                   right:10,
        //                   child: Padding(
        //                     padding: const EdgeInsets.only(top:8.0),
        //                     child:likedPost[index].images[0]["type"] == "video" ?Icon(Icons.video_camera_back) : Icon(Icons.image),
        //                   ))
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