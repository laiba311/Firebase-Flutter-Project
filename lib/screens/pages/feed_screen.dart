import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/models/story_model.dart';
import 'package:finalfashiontimefrontend/models/swap_model.dart';
import 'package:finalfashiontimefrontend/models/user_model.dart';
import 'package:finalfashiontimefrontend/screens/fashionComments/comment_screen.dart';
import 'package:finalfashiontimefrontend/screens/filter-screens/filter_screen.dart';
import 'package:finalfashiontimefrontend/screens/filter-screens/filter_top_trending.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/swap_detail.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/profiles/myProfile.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/report_screen.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../customize_pacages/mentions/src/mention_text_field.dart';
import '../../models/post_model.dart';
import '../../models/searched_style.dart';
import '../../utils/constants.dart';
class FeedScreen extends StatefulWidget {
  final Function onNavigate;
  final Function navigatePostToScrollArguments;
  final Function navigateSwapArguments;
  final Function onNavigateBack;
  final Function onNavigateBackOn;
  const FeedScreen({Key? key, required this.onNavigate, required this.navigatePostToScrollArguments, required this.navigateSwapArguments, required this.onNavigateBack, required this.onNavigateBackOn}) : super(key: key);
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  Timer? countdownTimer;
  Duration myDuration = const Duration(days: 7);
  String search = "";
  String id = "";
  String token = "";
  String gender = "";
  String option = "";
  String date = "";
  String name = '';
  String selectedEvent = '';
  String selectedYear = '';
  late Timer _timer;
  late Duration _timeRemaining;
  int selectedFashionId = 0;
  List<PostModel> posts = [];
  List<PostModel> posts1 = [];
  List<PostModel> filteredTrendingPosts = [];
  List<PostModel> trendingItems = [];
  List<PostModel> trendingItems2 = [];
  List<PostModel> filteredPosts = [];
  List<PostModel> filteredItems = [];
  List<PostModel> filteredItems2 = [];
  List<SearchedStyle> searchedStyle = [];
  bool loading = false;
  late TabController tabController;
  bool top10 = true;
  bool styles = false;
  bool isExpanded = false;
  bool updateBool = false;
  int _current = 0;
  double? _previousExtent;

  final CarouselSliderController _controller = CarouselSliderController();
  TextEditingController description = TextEditingController();
  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    name = preferences.getString("name")!;

    debugPrint("post plus token$token");
    getCachedData();
    getPosts();
  }

  getCachedData() async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      gender = preferences.getString('selectedGender')!;
      debugPrint("selected gender was =========?$gender");
    } catch (e) {
      debugPrint("Error retrieving cached data: $e");
    }
  }

  getCachedDataForTrendingPost() async {
    debugPrint("===============>filter function invoked");
    SharedPreferences preferences = await SharedPreferences.getInstance();
    selectedEvent = preferences.getString('selectedEvent')!;
    selectedYear = preferences.getString('selectedYear')!;
    debugPrint("all filter data===========> $selectedYear $selectedEvent");
    getFilteredTrendingPosts();
  }

  getFilteredTrendingPosts() {
    try {
      loading = true;
      posts1.clear();
      https.get(Uri.parse("$serverUrl/fashionUpload/top-trending/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        debugPrint(
            "Timer for filtered trending post  ==> ${jsonDecode(value.body)}");
        setState(() {
          //myDuration = Duration(seconds: int.parse(jsonDecode(value.body)["result"]["time_remaining"].));
          loading = false;
        });
        jsonDecode(value.body)["result"].forEach((value) {
          if (value["upload"]["media"][0]["type"] == "video" && value['addMeInWeekFashion'] == true && value['event']['title'].toString() == selectedEvent && value["user"]["isPrivate"] == false) {
            //debugPrint("condition met==========>1");
            VideoThumbnail.thumbnailFile(
              video: value["upload"]["media"][0]["video"],
              imageFormat: ImageFormat.JPEG,
              maxWidth: 128,
              // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
              quality: 25,
            ).then((value1) {
              setState(() {
                filteredTrendingPosts.add(PostModel(
                    value["id"].toString(),
                    value["description"],
                    value["upload"]["media"],
                    value["user"]["username"],
                    value["user"]["pic"] ??
                        "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
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
            });
          } else if (value['addMeInWeekFashion'] == true && value['event']['title'].toString() == selectedEvent && value["user"]["isPrivate"] == false) {
            //debugPrint("condition met==========>2");
            setState(() {
              filteredTrendingPosts.add(PostModel(
                  value["id"].toString(),
                  value["description"],
                  value["upload"]["media"],
                  value["user"]["username"],
                  value["user"]["pic"] ??
                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
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
            //debugPrint("${filteredTrendingPosts.length}");
          } else {
            //debugPrint("nothing found");
            setState(() {
            });
            getPosts1();
          }
        });
      });
    } catch (e) {
      debugPrint("Error received while bringing filter trending post");
    }
  }

  getPosts() {
    posts.clear();
    filteredPosts.clear();
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/fashionUpload/top-trending/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        //debugPrint("Timer ==> ${jsonDecode(value.body)}");
        setState(() {
          //myDuration = Duration(seconds: int.parse(jsonDecode(value.body)["result"]["time_remaining"].));
          loading = false;
        });
        jsonDecode(value.body)["result"].forEach((value) {
          if (value["upload"]["media"][0]["type"] == "video" && value['addMeInWeekFashion'] == true) {
            VideoThumbnail.thumbnailFile(
              video: value["upload"]["media"][0]["video"],
              imageFormat: ImageFormat.JPEG,
              maxWidth: 128,
              quality: 25,
            ).then((value1) {
              setState(() {
                posts1.add(PostModel(
                    value["id"].toString(),
                    value["description"],
                    value["upload"]["media"],
                    value["user"]["username"],
                    value["user"]["pic"] ??
                        "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
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
                    close_friends: value["close_friends"],
                    isPrivate: value["user"]["isPrivate"]
                ));
              });
            });
          } else if (value['addMeInWeekFashion'] == true) {
            setState(() {
              posts1.add(PostModel(
                  value["id"].toString(),
                  value["description"],
                  value["upload"]["media"],
                  value["user"]["username"],
                  value["user"]["pic"] ??
                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
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
                  close_friends: value["close_friends"],
                  isPrivate: value["user"]["isPrivate"]
                )
              );
            });
          }
        });
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
    getStyleHistory();
    getPosts1();
  }

  getPosts1() {
    posts.clear();
    setState(() {
      loading = true;
    });

    try {
      https.get(Uri.parse("$serverUrl/fashionUpload/"), headers: {
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
          if(result["user"]["isPrivate"] == false) {
            if (result['hashtags'] != []) {
              posts.add(PostModel(
                  result["id"].toString(),
                  result["description"],
                  media ?? [],
                  result["user"]["username"],
                  result["user"]["pic"] ??
                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                  false,
                  result["likesCount"].toString(),
                  result["disLikesCount"].toString(),
                  result["commentsCount"].toString(),
                  result["created"],
                  result["gender"],
                  result["user"]["id"].toString(),
                  result["myLike"] == null ? "like" : result["myLike"]
                      .toString(),
                  result["eventData"],
                  result["topBadge"] ?? {"badge": null},
                  addMeInFashionWeek: result["addMeInWeekFashion"],
                  isCommentEnabled: result["isCommentOff"],
                  isLikeEnabled: result["isLikeOff"],
                  hashtags: result['hashtags'],
                  recent_stories: result['recent_stories'].length > 0 ? List<
                      Story>.from(result['recent_stories'].map((e1) {
                    return Story(
                        duration: e1["time_since_created"],
                        url: e1["content"],
                        type: e1["type"],
                        user: User(name: e1["user"]["name"],
                            username: e1['user']['username'],
                            profileImageUrl: e1["user"]["pic"] == null
                                ? "https://www.w3schools.com/w3images/avatar2.png"
                                : e1["user"]["pic"],
                            id: e1["user"]["id"].toString()),
                        storyId: e1["id"],
                        viewed_users: e1["viewers"],
                        created: e1["created_at"],
                        close_friends_only: e1['close_friends_only'],
                        isPrivate: e1["is_user_private"],
                        fanList: e1["fansList"]
                    );
                  })) : [],
                  show_stories_to_non_friends: result['user']['show_stories_to_non_friends'],
                  fanList: result["fansList"],
                  followList: result["user"]["followList"],
                  close_friends: result["close_friends"],
                  isPrivate: result["user"]["isPrivate"]
              ));
              debugPrint(
                  "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
              debugPrint(
                  "value of isCommentEnabled is ${result["isCommentOff"]} ${posts
                      .length}");
            }
            else {
              posts.add(PostModel(
                  result["id"].toString(),
                  result["description"],
                  media ?? [],
                  result["user"]["username"],
                  result["user"]["pic"] ??
                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                  false,
                  result["likesCount"].toString(),
                  result["disLikesCount"].toString(),
                  result["commentsCount"].toString(),
                  result["created"],
                  result["gender"],
                  result["user"]["id"].toString(),
                  result["myLike"] == null ? "like" : result["myLike"]
                      .toString(),
                  result["eventData"],
                  result["topBadge"] ?? {"badge": null},
                  addMeInFashionWeek: result["addMeInWeekFashion"],
                  isCommentEnabled: result["isCommentOff"],
                  isLikeEnabled: result["isLikeOff"],
                  hashtags: result['hashtags'],
                  recent_stories: result['recent_stories'].length > 0 ? List<
                      Story>.from(result['recent_stories'].map((e1) {
                    return Story(
                        duration: e1["time_since_created"],
                        url: e1["content"],
                        type: e1["type"],
                        user: User(name: e1["user"]["name"],
                            username: e1['user']['username'],
                            profileImageUrl: e1["user"]["pic"] == null
                                ? "https://www.w3schools.com/w3images/avatar2.png"
                                : e1["user"]["pic"],
                            id: e1["user"]["id"].toString()),
                        storyId: e1["id"],
                        viewed_users: e1["viewers"],
                        created: e1["created_at"],
                        close_friends_only: e1['close_friends_only'],
                        isPrivate: e1["is_user_private"],
                        fanList: e1["fansList"]
                    );
                  })) : [],
                  show_stories_to_non_friends: result['user']['show_stories_to_non_friends'],
                  fanList: result["fansList"],
                  followList: result["user"]["followList"],
                  close_friends: result["close_friends"],
                  isPrivate: result["user"]["isPrivate"]
              ));
              //print("Posts ==> ${posts.length} ${result}");
              debugPrint(
                  "value of add me in next fashion week is ${result["addMeInWeekFashion"]}");
              debugPrint(
                  "value of isCommentEnabled is ${result["isCommentOff"]} ${posts
                      .length}");
            }
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

  getPostsFiltered() async {
    getCachedData();

    setState(() {
      loading = true;
    });
    try {
      final response = await https.get(Uri.parse("$serverUrl/fashionUpload/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });

      final responseData = jsonDecode(response.body);
      final List<dynamic> results = responseData['results'];

      setState(() {
        loading = false;
      });

      for (var value in results) {
        if (value['addMeInWeekFashion'] == false) {
          if (gender == value['gender']) {
            if (value["upload"]["media"][0]["type"] == "video") {
              VideoThumbnail.thumbnailFile(
                video: value["upload"]["media"][0]["video"],
                imageFormat: ImageFormat.JPEG,
                maxWidth: 128,
                quality: 25,
              ).then((value1) {
                setState(() {
                  filteredPosts.add(PostModel(
                    value["id"].toString(),
                    value["description"],
                    value["upload"]["media"],
                    value["user"]["username"],
                    value["user"]["pic"] ??
                        "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
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
                      close_friends: value["close_friends"],
                      isPrivate: value["user"]["isPrivate"]
                  ));
                });
              });
            } else {
              setState(() {
                filteredPosts.add(PostModel(
                  value["id"].toString(),
                  value["description"],
                  value["upload"]["media"],
                  value["user"]["username"],
                  value["user"]["pic"] ??
                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
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
                    close_friends: value["close_friends"],
                    isPrivate: value["user"]["isPrivate"]
                ));
              });
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }

  SearchUser(String query) {
    setState(
      () {
        search = query;
        filteredItems = posts
            .where(
              (item) => item.userName.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      },
    );
  }

  searchTrendingViaUser(String query) {
    setState(
      () {
        search = query;
        trendingItems2 = filteredTrendingPosts
            .where(
              (item) => item.userName.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      },
    );
  }

  searchTrendingViaDescription(String query) {
    setState(
      () {
        search = query;
        trendingItems2 = filteredTrendingPosts
            .where(
              (item) => item.description.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      },
    );
  }

  searchViaDescription(String query) {
    setState(() {
      search = query;
      filteredItems = posts
          .where((element) =>
              element.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  searchViaDescriptionForFiltered(String query) {
    setState(() {
      search = query;
      filteredItems2 = filteredPosts
          .where((element) =>
              element.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  searchAllTrendingViaDescription(String query) {
    setState(() {
      search = query;
      trendingItems = posts1
          .where((element) =>
              element.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  searchAllTrendingViaUser(String query) {
    setState(() {
      search = query;
      trendingItems = posts1
          .where((element) =>
              element.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  SearchFilteredUser(String query) {
    setState(
      () {
        search = query;
        filteredItems2 = filteredTrendingPosts
            .where(
              (item) => item.userName.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      },
    );
  }

  addStyleHistory(PostModel data,index,List<PostModel> posts){
    https.post(
        Uri.parse("$serverUrl/apiSearchedStyle/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({
          "styleId": data.id,
          "data": {
            "userid": data.userid,
            "images": data.images,
            "description": data.description,
            "userName": data.userName,
            "userPic": data.userPic,
            "likeCount": data.likeCount,
            "dislikeCount": data.dislikeCount,
            "mylike": data.mylike,
            "addMeInFashionWeek": data.addMeInFashionWeek,
            "isPrivate": data.isPrivate!,
            "fansList": data.fanList!,
            "followList": data.followList!,
          }
        })
    ).then((value){
      //print("History added");
      // afnan
      // Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder:
      //             (context) =>
      //             SwapDetail(
      //               userid: data.userid,
      //               image: data.images,
      //               description: data.description,
      //               style: "Fashion Style 2",
      //               createdBy: data.userName,
      //               profile: data.userPic,
      //               likes: data.likeCount,
      //               dislikes: data.dislikeCount,
      //               mylike: data.mylike,
      //               addMeInFashionWeek: data.addMeInFashionWeek,
      //               isPrivate: data.isPrivate!,
      //               fansList: data.fanList!,
      //               id: id,
      //               followList: data.followList!,
      //               username: data.userName,
      //               token: token,
      //             ))).then((value){
      //               getStyleHistory();
      //             });
      widget.navigatePostToScrollArguments(33,"All Styles",posts,index);
    });
  }

  getStyleHistory(){
    searchedStyle.clear();
    https.get(
      Uri.parse("$serverUrl/apiSearchedStyle/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).then((value){
      print(value.body.toString());
      var responseData = jsonDecode(value.body);
      responseData.forEach((e){
        setState(() {
          searchedStyle.add(SearchedStyle(
              e["id"].toString(),
              e["data"]
          ));
        });
      });
    });
  }

  removeUserHistory(String id,index){
    print(id);
    https.delete(
        Uri.parse("$serverUrl/apiSearchedStyle/$id/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      //print("History added");
      setState(() {
        searchedStyle.removeAt(index);
      });
      getStyleHistory();
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getCashedData();
    _initializeTimer();
    tabController = TabController(length: 2, vsync: this);
    // startTimer();
  }

  void _initializeTimer() {
    DateTime now = DateTime.now();

    DateTime nextSunday = now.add(Duration(
        days: DateTime.sunday - now.weekday,
        hours: 12 - now.hour,
        minutes: -now.minute,
        seconds: -now.second));


    _timeRemaining = nextSunday.difference(now);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining = _timeRemaining - const Duration(seconds: 1);

        // Check if it's Sunday 12 pm to reset the timer
        if (_timeRemaining.inSeconds <= 0) {
          _resetTimer();
        }
      });
    });
  }

  void _resetTimer() {
    _timer.cancel();

    _initializeTimer();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    // stopTimer();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    return WillPopScope(
      onWillPop: (){
        widget.onNavigateBack(0);
        return Future.value(false);
      },
      child: Scaffold(
        body: Column(
          children: [
            SizedBox(
              height: 50,
              child: TabBar(
                indicatorColor: primary,
                labelColor: primary,
                unselectedLabelColor: ascent,
                controller: tabController,
                tabs: const [
                  Tab(
                    child: Text(
                      "All Styles",
                      style: TextStyle(
                          fontFamily: Poppins, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Tab(
                    child: Text(
                      "Event Styles",
                      style: TextStyle(
                          // color:_getTabIconColor(context) ,
                          fontFamily: Poppins,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: <Widget>[
                  RefreshIndicator(
                    color: primary,
                    onRefresh: () {
                      return Future<void>.value(getPosts());
                    },
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              alignment: Alignment.bottomCenter,
                              width: MediaQuery.of(context).size.width * 0.88,
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
                                              if (posts.isNotEmpty) {
                                                SearchUser(value);
                                                searchViaDescription(value);
                                              } else {
                                                SearchFilteredUser(value);
                                                searchViaDescriptionForFiltered(value);
                                              }
                                            },
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
                            GestureDetector(
                              onTap: () {
                                filteredPosts.clear();
                                //widget.onNavigate(26);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            FilterScreen(
                                              myIndex: 4,
                                              navigateTo: widget.onNavigateBack,
                                            ))).then((value) {
                                  posts.clear();
                                  posts1.clear();
                                  print("list cleared ${filteredPosts.length}");
                                  loading == false;
                                  if(gender==''){
                                    debugPrint("gender not selected");
                                    getPosts();
                                  }
                                  else{
                                    getPostsFiltered();
                                  }

                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: Icon(
                                  Icons.tune,
                                  size: 30,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left:20.0, right: 30.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Recent Searches",style: TextStyle(fontFamily: Poppins),),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20,),
                        SizedBox(
                          height: 40,
                          child: searchedStyle.isEmpty ? const Center(child: Text("No Searched Styles",style: TextStyle(fontFamily: Poppins),),) : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: searchedStyle.length,
                              itemBuilder: (context,index){
                                return Padding(
                                  padding: const EdgeInsets.only(left:20.0),
                                  child: GestureDetector(
                                    onTap: (){
                                      widget.navigateSwapArguments(35,SwapModel(
                                          searchedStyle[index].data["userid"],
                                          searchedStyle[index].data["images"],
                                          searchedStyle[index].data["description"],
                                          searchedStyle[index].data["userName"],
                                          "Fashion Style 2",
                                          searchedStyle[index].data["userPic"],
                                          searchedStyle[index].data["likeCount"],
                                          searchedStyle[index].data["dislikeCount"],
                                          searchedStyle[index].data["mylike"],
                                          searchedStyle[index].data["isPrivate"],
                                          id,
                                          searchedStyle[index].data["fansList"],
                                          searchedStyle[index].data["followList"],
                                          searchedStyle[index].data["userName"],
                                          token,
                                          searchedStyle[index].data["addMeInFashionWeek"]
                                      ));

                                      // Navigator.push(
                                      //     context,
                                      //     MaterialPageRoute(
                                      //         builder:
                                      //             (context) =>
                                      //             SwapDetail(
                                      //               userid: searchedStyle[index].data["userid"],
                                      //               image: searchedStyle[index].data["images"],
                                      //               description: searchedStyle[index].data["description"],
                                      //               style: "Fashion Style 2",
                                      //               createdBy: searchedStyle[index].data["userName"],
                                      //               profile: searchedStyle[index].data["userPic"],
                                      //               likes: searchedStyle[index].data["likeCount"],
                                      //               dislikes: searchedStyle[index].data["dislikeCount"],
                                      //               mylike: searchedStyle[index].data["mylike"],
                                      //               addMeInFashionWeek: searchedStyle[index].data["addMeInFashionWeek"],
                                      //               isPrivate: searchedStyle[index].data["isPrivate"],
                                      //               fansList: searchedStyle[index].data["fansList"],
                                      //               id: id,
                                      //               followList: searchedStyle[index].data["followList"],
                                      //               username: searchedStyle[index].data["userName"],
                                      //               token: token,
                                      //             )));
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
                                          SizedBox(
                                            width: 100,
                                            child: Text(
                                              searchedStyle[index].data["description"],
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Colors.white,fontFamily: Poppins),),
                                          ),
                                          IconButton(onPressed: (){
                                            removeUserHistory(searchedStyle[index].id,index);
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
                          child: loading == true
                              ? SpinKitCircle(
                                  size: 50,
                                  color: primary,
                                )
                              : (posts.isEmpty
                                  ? (filteredPosts.length >= 0
                                      ? filteredItems2.isNotEmpty ||
                                              search.isNotEmpty
                                          ? (filteredItems2.isEmpty
                                              ? const Text("No Results Found",style: TextStyle(fontFamily: Poppins),)
                                              : GridView.builder(
                                                  padding: EdgeInsets.zero,
                                                  itemCount:
                                                      filteredItems2.length,
                                                  gridDelegate:
                                                      const  SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 3,
                                                          mainAxisSpacing: 1,
                                                          crossAxisSpacing: 1
                                                      ),
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    return WidgetAnimator(
                                                      GestureDetector(
                                                        onTap: () {
                                                          addStyleHistory(filteredItems2[index],index,filteredItems2);
                                                        },
                                                        child: Card(
                                                          // shape: const RoundedRectangleBorder(
                                                          //     borderRadius: BorderRadius
                                                          //         .all(Radius
                                                          //             .circular(
                                                          //                 10))
                                                          // ),
                                                          child: Container(
                                                            decoration:
                                                                const BoxDecoration(
                                                              // borderRadius: BorderRadius
                                                              //     .all(Radius
                                                              //         .circular(
                                                              //             10)),
                                                            ),
                                                            child: filteredItems2[index]
                                                                            .images[0]
                                                                        [
                                                                        "type"] ==
                                                                    "video"
                                                                ? Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      image: DecorationImage(
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          image:
                                                                              FileImage(File(filteredItems2[index].thumbnail))),
                                                                      borderRadius: const BorderRadius
                                                                              .all(
                                                                          Radius.circular(
                                                                              10)),
                                                                    ),
                                                                  )
                                                                : ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    child:
                                                                        CachedNetworkImage(
                                                                      imageUrl:
                                                                          filteredItems2[index].images[0]
                                                                              [
                                                                              "image"],
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      placeholder:
                                                                          (context, url) =>
                                                                              Center(
                                                                        child:
                                                                            SizedBox(
                                                                          width:
                                                                              20.0,
                                                                          height:
                                                                              20.0,
                                                                          child:
                                                                              SpinKitCircle(
                                                                            color:
                                                                                primary,
                                                                            size:
                                                                                20,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      errorWidget: (context,
                                                                              url,
                                                                              error) =>
                                                                          const Icon(
                                                                              Icons.error),
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ))
                                          : filteredPosts.isEmpty
                                              ? const Center(
                                                  child: Text(
                                                  "No Posts",
                                                  style: TextStyle(
                                                      fontFamily: Poppins),
                                                ))
                                              : GridView.builder(
                                                  padding: EdgeInsets.zero,
                                                  itemCount:
                                                      filteredPosts.length,
                                                  gridDelegate:
                                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 3,
                                                          mainAxisSpacing: 1,
                                                          crossAxisSpacing: 1
                                                      ),
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    return WidgetAnimator(
                                                      GestureDetector(
                                                        onTap: () {
                                                          addStyleHistory(filteredPosts[index],index,filteredPosts);
                                                        },
                                                        child: Card(
                                                          // shape: const RoundedRectangleBorder(
                                                          //     borderRadius: BorderRadius
                                                          //         .all(Radius
                                                          //             .circular(
                                                          //                 10))),
                                                          child: Container(
                                                            decoration:
                                                                const BoxDecoration(
                                                              // borderRadius: BorderRadius
                                                              //     .all(Radius
                                                              //         .circular(
                                                              //             10)),
                                                            ),
                                                            child: filteredPosts[index]
                                                                            .images[0]
                                                                        [
                                                                        "type"] ==
                                                                    "video"
                                                                ? Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      image: DecorationImage(
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          image:
                                                                              FileImage(File(filteredPosts[index].thumbnail))),
                                                                      // borderRadius: const BorderRadius
                                                                      //         .all(
                                                                      //     Radius.circular(
                                                                      //         10)),
                                                                    ),
                                                                  )
                                                                : ClipRRect(
                                                                    // borderRadius:
                                                                    //     BorderRadius.circular(
                                                                    //         10),
                                                                    child:
                                                                        CachedNetworkImage(
                                                                      imageUrl:
                                                                          filteredPosts[index].images[0]
                                                                              ["image"],
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      placeholder:
                                                                          (context, url) =>
                                                                              Center(
                                                                        child:
                                                                            SizedBox(
                                                                          width:
                                                                              20.0,
                                                                          height:
                                                                              20.0,
                                                                          child:
                                                                              SpinKitCircle(
                                                                            color:
                                                                                primary,
                                                                            size:
                                                                                20,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      errorWidget: (context,
                                                                              url,
                                                                              error) =>
                                                                          Container(
                                                                        height: MediaQuery.of(context).size.height *
                                                                            0.84,
                                                                        width: MediaQuery.of(context)
                                                                            .size
                                                                            .width,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          image: DecorationImage(
                                                                              image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
                                                                              fit: BoxFit.fill),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                      : const Text("No Results Found",style: TextStyle(fontFamily: Poppins),))
                                  : (filteredItems.isNotEmpty ||
                                          search.isNotEmpty
                                      ? (filteredItems.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No Results Found',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontFamily: Poppins),
                                              ),
                                            )
                                          : GridView.builder(
                                              itemCount: filteredItems.length,
                                              padding: EdgeInsets.zero,
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 3,
                                                      mainAxisSpacing: 1,
                                                      crossAxisSpacing: 1
                                                  ),
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                return WidgetAnimator(
                                                  GestureDetector(
                                                    onTap: () {
                                                      addStyleHistory(filteredItems[index],index,filteredItems);
                                                    },
                                                    child: Card(
                                                      // shape: const RoundedRectangleBorder(
                                                      //     borderRadius:
                                                      //         BorderRadius.all(
                                                      //             Radius
                                                      //                 .circular(
                                                      //                     10))),
                                                      child: Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          // borderRadius:
                                                          //     BorderRadius.all(
                                                          //         Radius
                                                          //             .circular(
                                                          //                 10)),
                                                        ),
                                                        child: filteredItems[
                                                                            index]
                                                                        .images[
                                                                    0]["type"] ==
                                                                "video"
                                                            ? Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  image: DecorationImage(
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      image: FileImage(File(
                                                                          filteredItems[index]
                                                                              .thumbnail))),
                                                                  // borderRadius: const BorderRadius
                                                                  //         .all(
                                                                  //     Radius.circular(
                                                                  //         10)),
                                                                ),
                                                              )
                                                            : ClipRRect(
                                                                // borderRadius:
                                                                //     BorderRadius
                                                                //         .circular(
                                                                //             10),
                                                                child:
                                                                    CachedNetworkImage(
                                                                  imageUrl: filteredItems[
                                                                              index]
                                                                          .images[0]
                                                                      ["image"],
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  placeholder:
                                                                      (context,
                                                                              url) =>
                                                                          Center(
                                                                    child:
                                                                        SizedBox(
                                                                      width:
                                                                          20.0,
                                                                      height:
                                                                          20.0,
                                                                      child:
                                                                          SpinKitCircle(
                                                                        color:
                                                                            primary,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  errorWidget: (context,
                                                                          url,
                                                                          error) =>
                                                                      const Icon(Icons
                                                                          .error),
                                                                ),
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ))
                                      : posts.isEmpty
                                          ? const Center(
                                              child: Text(
                                                "No posts",
                                                style: TextStyle(
                                                    fontFamily: Poppins),
                                              ),
                                            )
                                          : GridView.builder(
                                              itemCount: posts.length,
                                              padding: EdgeInsets.zero,
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 3,
                                                      mainAxisSpacing: 1,
                                                      crossAxisSpacing: 1
                                                  ),
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                return WidgetAnimator(
                                                  GestureDetector(
                                                    onTap: () {
                                                      addStyleHistory(posts[index],index,posts);
                                                    },
                                                    child: Card(
                                                      //shape: const RoundedRectangleBorder(
                                                          // borderRadius:
                                                          //     BorderRadius.all(
                                                          //         Radius
                                                          //             .circular(
                                                          //                 10))),
                                                      child: Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          // borderRadius:
                                                          //     BorderRadius.all(
                                                          //         Radius
                                                          //             .circular(
                                                          //                 10)),
                                                        ),
                                                        child: posts[index]
                                                                        .images[
                                                                    0]["type"] ==
                                                                "video"
                                                            ? Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  image: DecorationImage(
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      image: FileImage(File(
                                                                          posts[index]
                                                                              .thumbnail))),
                                                                  // borderRadius: const BorderRadius
                                                                  //         .all(
                                                                  //     Radius.circular(
                                                                  //         10)),
                                                                ),
                                                              )
                                                            : ClipRRect(
                                                                // borderRadius:
                                                                //     BorderRadius
                                                                //         .circular(
                                                                //             10),
                                                                child:
                                                                    CachedNetworkImage(
                                                                  imageUrl: posts[
                                                                              index]
                                                                          .images[0]
                                                                      ["image"],
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  placeholder:
                                                                      (context,
                                                                              url) =>
                                                                          Center(
                                                                    child:
                                                                        SizedBox(
                                                                      width:
                                                                          20.0,
                                                                      height:
                                                                          20.0,
                                                                      child:
                                                                          SpinKitCircle(
                                                                        color:
                                                                            primary,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  errorWidget: (context,
                                                                          url,
                                                                          error) =>
                                                                      Container(
                                                                    height: MediaQuery.of(context)
                                                                            .size
                                                                            .height *
                                                                        0.84,
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
                                                    ),
                                                  ),
                                                );
                                              },
                                            ))),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Next top 10 styles in:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: Poppins),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.hourglass_top,
                            size: 15,
                            color: Colors.red,
                          ),
                          Text(
                            ' ${_timeRemaining.inDays} days ${_timeRemaining.inHours.remainder(24)} hours ${_timeRemaining.inMinutes.remainder(60)} minutes ${_timeRemaining.inSeconds.remainder(60)} seconds',
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontFamily: Poppins),
                          ),

                        ],
                      ),

                      //search bar
                      Row(
                        children: [
                          Container(
                            alignment: Alignment.bottomCenter,
                            width: MediaQuery.of(context).size.width * 0.85,
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
                                            if (posts1.isNotEmpty) {
                                              SearchUser(value);
                                              searchViaDescription(value);
                                            } else {
                                              SearchFilteredUser(value);
                                              searchViaDescriptionForFiltered(value);
                                            }
                                          },
                                          style: const TextStyle(color: ascent,fontFamily: Poppins,),
                                          cursorColor: ascent,
                                          //style: simpleTextStyle(),
                                          decoration: const InputDecoration(
                                              fillColor: ascent,
                                              hintText: "Search for trending styles",
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
                          // Expanded(
                          //   child: Container(
                          //     height: 40,
                          //     padding: const EdgeInsets.only(left: 8,right:4 ),
                          //     child: TextField(
                          //       onChanged: (value) {
                          //         if (posts1.isNotEmpty) {
                          //           SearchUser(value);
                          //           searchViaDescription(value);
                          //         } else {
                          //           SearchFilteredUser(value);
                          //           searchViaDescriptionForFiltered(value);
                          //         }
                          //       },
                          //       decoration: InputDecoration(
                          //         prefixIcon: const Icon(Icons.search),
                          //         contentPadding: const EdgeInsets.only(top: 10),
                          //         hintText: 'Search for trending styles.',
                          //         hintStyle: const TextStyle(
                          //           fontSize: 15,
                          //           fontFamily: Poppins,
                          //         ),
                          //         border: const OutlineInputBorder(),
                          //         focusColor: primary,
                          //         focusedBorder: OutlineInputBorder(
                          //           borderSide: BorderSide(width: 1, color: primary),
                          //         ),
                          //       ),
                          //       cursorColor: primary,
                          //       style: TextStyle(
                          //         color: primary,
                          //         fontSize: 13,
                          //         fontFamily: Poppins,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          IconButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const TopTrendingFilterScreen(),
                                    )).then((value) {
                                  setState(() {
                                    getCachedDataForTrendingPost();
                                  });
                                });
                              },
                              icon: const Icon(
                                size: 30,
                                Icons.tune,
                                color: ascent,
                              ))
                        ],
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: loading == true
                              ? SpinKitCircle(
                                  size: 50,
                                  color: primary,
                                )
                              : (posts1.isEmpty&&filteredTrendingPosts.isEmpty
                                  ? const Center(
                                      child: Text(
                                      "No Posts",
                                      style: TextStyle(fontFamily: Poppins),
                                    ))
                                  : (filteredItems.isNotEmpty || search.isNotEmpty
                                      ? (filteredItems.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No Results Found',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontFamily: Poppins),
                                              ),
                                            )
                                          : ListView.builder(
                                              itemCount: filteredItems.length,
                                              itemBuilder: (context, index) {
                                                return Card(
                                                  elevation: 10,
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        decoration: BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                                    begin: Alignment
                                                                        .topLeft,
                                                                    end: Alignment
                                                                        .topRight,
                                                                    stops: const [
                                                                      0.0,
                                                                      0.99
                                                                    ],
                                                                    tileMode:
                                                                        TileMode
                                                                            .clamp,
                                                                    colors: <
                                                                        Color>[
                                                                      secondary,
                                                                      primary,
                                                                    ])),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 10.0,
                                                                  right: 10,
                                                                  top: 5,
                                                                  bottom: 5),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              GestureDetector(
                                                                onTap: () {
                                                                  debugPrint("filter profile clicked");
                                                                  filteredItems[index]
                                                                              .userName ==
                                                                          name
                                                                      ? Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => MyProfileScreen(
                                                                                    id: filteredItems[index].userid,
                                                                                    username: filteredItems[index].userName,
                                                                                  )))
                                                                      : Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => FriendProfileScreen(
                                                                                    id: filteredItems[index].userid,
                                                                                    username: filteredItems[index].userName,
                                                                                  )));
                                                                },
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          4.0),
                                                                  child:
                                                                      SizedBox(
                                                                    width: 180,
                                                                    child: Row(
                                                                      children: [
                                                                        const SizedBox(
                                                                          width:
                                                                              10,
                                                                        ),
                                                                        CircleAvatar(
                                                                            backgroundColor:
                                                                                dark1,
                                                                            child:
                                                                                ClipRRect(
                                                                              borderRadius:
                                                                                  const BorderRadius.all(Radius.circular(50)),
                                                                              child: filteredItems[index].userPic == null
                                                                                  ? Image.network(
                                                                                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                      width: 35,
                                                                                      height: 40,
                                                                                    )
                                                                                  : CachedNetworkImage(
                                                                                      imageUrl: filteredItems[index].userPic,
                                                                                      imageBuilder: (context, imageProvider) => Container(
                                                                                        height: MediaQuery.of(context).size.height * 0.7,
                                                                                        width: MediaQuery.of(context).size.width,
                                                                                        decoration: BoxDecoration(
                                                                                          image: DecorationImage(
                                                                                            image: imageProvider,
                                                                                            fit: BoxFit.cover,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      placeholder: (context, url) => Center(
                                                                                          child: SpinKitCircle(
                                                                                        color: primary,
                                                                                        size: 10,
                                                                                      )),
                                                                                      errorWidget: (context, url, error) => ClipRRect(
                                                                                          borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                                                          child: Image.network(
                                                                                            "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                            width: 35,
                                                                                            height: 35,
                                                                                          )),
                                                                                    ),
                                                                            )),
                                                                        const SizedBox(
                                                                          width:
                                                                              5,
                                                                        ),
                                                                        Text(
                                                                          filteredItems[index]
                                                                              .userName,
                                                                          style: const TextStyle(
                                                                              fontFamily: Poppins,
                                                                              color:
                                                                                  ascent,
                                                                              fontWeight:
                                                                                  FontWeight.bold),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              PopupMenuButton(
                                                                  icon:
                                                                      const Icon(
                                                                    Icons
                                                                        .more_horiz,
                                                                    color: ascent,
                                                                  ),
                                                                  onSelected:
                                                                      (value) {
                                                                    if (value ==
                                                                        0) {
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) =>
                                                                                  ReportScreen(reportedID: filteredItems[index].userid)));
                                                                    }
                                                                    if (value ==
                                                                        2) {}
                                                                    debugPrint(value
                                                                        .toString());
                                                                    //Navigator.pushNamed(context, value.toString());
                                                                  },
                                                                  itemBuilder:
                                                                      (BuildContext
                                                                          bc) {
                                                                    return [
                                                                      PopupMenuItem(
                                                                        value: 0,
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Icon(Icons
                                                                                .report),
                                                                            SizedBox(
                                                                              width:
                                                                                  10,
                                                                            ),
                                                                            Text(
                                                                              "Report",
                                                                              style:
                                                                                  TextStyle(fontFamily: Poppins),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      if (filteredItems[index]
                                                                              .userid !=
                                                                          id)
                                                                        PopupMenuItem(
                                                                          value:
                                                                              2,
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              Icon(Icons.save),
                                                                              SizedBox(
                                                                                width: 10,
                                                                              ),
                                                                              Text(
                                                                                "Save Post",
                                                                                style: TextStyle(fontFamily: Poppins),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                    ];
                                                                  })
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () {},
                                                            child: SizedBox(
                                                              height: 320,
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.87,
                                                              child:
                                                                  CarouselSlider(
                                                                carouselController:
                                                                    _controller,
                                                                options:
                                                                    CarouselOptions(
                                                                        enableInfiniteScroll:
                                                                            false,
                                                                        height:
                                                                            320.0,
                                                                        autoPlay:
                                                                            false,
                                                                        enlargeCenterPage:
                                                                            true,
                                                                        viewportFraction:
                                                                            0.99,
                                                                        aspectRatio:
                                                                            2.0,
                                                                        initialPage:
                                                                            0,
                                                                        onPageChanged:
                                                                            (ind,
                                                                                reason) {
                                                                          setState(
                                                                              () {
                                                                            _current =
                                                                                ind;
                                                                          });
                                                                        }),
                                                                items:
                                                                    filteredItems[
                                                                            index]
                                                                        .images
                                                                        .map((i) {
                                                                  return i["type"] ==
                                                                          "video"
                                                                      ? Container(
                                                                          color: Colors.black,
                                                                          child: Text("Video")
                                                                         )
                                                                          // child: UsingVideoControllerExample(
                                                                          //   path: i["video"],
                                                                          // ))
                                                                      : Builder(
                                                                          builder:
                                                                              (BuildContext
                                                                                  context) {
                                                                            return CachedNetworkImage(
                                                                              imageUrl:
                                                                                  i["image"],
                                                                              imageBuilder: (context, imageProvider) =>
                                                                                  Container(
                                                                                height: MediaQuery.of(context).size.height,
                                                                                width: MediaQuery.of(context).size.width,
                                                                                decoration: BoxDecoration(
                                                                                  image: DecorationImage(
                                                                                    image: imageProvider,
                                                                                    fit: BoxFit.cover,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              placeholder: (context, url) =>
                                                                                  SpinKitCircle(
                                                                                color: primary,
                                                                                size: 60,
                                                                              ),
                                                                              errorWidget: (context, url, error) =>
                                                                                  Container(
                                                                                height: MediaQuery.of(context).size.height * 0.84,
                                                                                width: MediaQuery.of(context).size.width,
                                                                                decoration: BoxDecoration(
                                                                                  image: DecorationImage(image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image, fit: BoxFit.fill),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                        );
                                                                }).toList(),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                8.0),
                                                        child: Text(
                                                            filteredItems[index]
                                                                .images
                                                                .length
                                                                .toString()),
                                                      ),
                                                      filteredItems[index]
                                                                  .images
                                                                  .length ==
                                                              1
                                                          ? const SizedBox()
                                                          : Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children:
                                                                  filteredItems[
                                                                          index]
                                                                      .images
                                                                      .asMap()
                                                                      .entries
                                                                      .map(
                                                                          (entry) {
                                                                return GestureDetector(
                                                                  onTap: () => _controller
                                                                      .animateToPage(
                                                                          entry
                                                                              .key),
                                                                  child:
                                                                      Container(
                                                                    width: 12.0,
                                                                    height: 12.0,
                                                                    margin: const EdgeInsets
                                                                            .symmetric(
                                                                        vertical:
                                                                            8.0,
                                                                        horizontal:
                                                                            4.0),
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(_current ==
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
                                                      const Divider(
                                                        height: 2,
                                                        thickness: 2,
                                                      ),
                                                      Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 0.0,
                                                                  right: 0.0),
                                                          child: filteredItems[
                                                                          index]
                                                                      .userid ==
                                                                  id
                                                              ? Row(
                                                                  children: [
                                                                    filteredItems[index].addMeInFashionWeek ==
                                                                            true
                                                                        ? filteredItems[index].mylike !=
                                                                                "like"
                                                                            ? IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  Icons.favorite,
                                                                                  size: 20,
                                                                                ))
                                                                            : IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  FontAwesomeIcons.heart,
                                                                                  size: 20,
                                                                                ))
                                                                        : filteredItems[index].mylike != "like"
                                                                            ? IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  Icons.star,
                                                                                  color: Colors.orange,
                                                                                  size: 24,
                                                                                ))
                                                                            : GestureDetector(
                                                                                onDoubleTap: () {},
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.all(8.0),
                                                                                  child: Icon(Icons.star_border_outlined, size: 24, color: Colors.orange),
                                                                                ),
                                                                              ),
                                                                    filteredItems[index]
                                                                                .likeCount ==
                                                                            "0"
                                                                        ? const SizedBox()
                                                                        : Text(filteredItems[
                                                                                index]
                                                                            .likeCount,style: TextStyle(fontFamily: Poppins),),
                                                                    filteredItems[index]
                                                                                .isCommentEnabled ==
                                                                            true
                                                                        ? IconButton(
                                                                            onPressed:
                                                                                () {
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
                                                                                                    postid: filteredItems[index].id,
                                                                                                    pic: filteredItems[index].userPic,
                                                                                                    scrollController: scrollController,
                                                                                                    isEventPost: filteredItems[index].addMeInFashionWeek!,
                                                                                                      userID: filteredItems[index].userid

                                                                                                  );
                                                                                                }
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      });
                                                                            },
                                                                            icon:
                                                                                const Icon(
                                                                              FontAwesomeIcons.comment,
                                                                              size:
                                                                                  20,
                                                                            ))
                                                                        : const SizedBox(),
                                                                    Padding(
                                                                        padding: EdgeInsets.only(
                                                                            left: filteredItems[index].isCommentEnabled == true
                                                                                ? MediaQuery.of(context).size.width * 0.35
                                                                                : MediaQuery.of(context).size.width * 0.4),
                                                                        child: Text(
                                                                          DateFormat.yMMMEd()
                                                                              .format(DateTime.parse(filteredItems[index].date)),
                                                                          style: const TextStyle(
                                                                              fontFamily: Poppins,
                                                                              fontSize:
                                                                                  12),
                                                                        )),
                                                                  ],
                                                                )
                                                              : Row(
                                                                  children: [
                                                                    filteredItems[index]
                                                                                .addMeInFashionWeek ==
                                                                            true
                                                                        ? filteredItems[index].mylike !=
                                                                                "like"
                                                                            ? IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  Icons.favorite,
                                                                                  size: 20,
                                                                                ))
                                                                            : IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  FontAwesomeIcons.heart,
                                                                                  size: 20,
                                                                                ))
                                                                        : filteredItems[index].mylike != "like"
                                                                            ? IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  Icons.star,
                                                                                  color: Colors.orange,
                                                                                  size: 24,
                                                                                ))
                                                                            : GestureDetector(
                                                                                onDoubleTap: () {},
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.all(8.0),
                                                                                  child: Icon(
                                                                                    Icons.star_border_outlined,
                                                                                    color: Colors.orange,
                                                                                    size: 24,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                    filteredItems[index]
                                                                                .likeCount ==
                                                                            "0"
                                                                        ? const SizedBox()
                                                                        : Text(filteredItems[
                                                                                index]
                                                                            .likeCount,style: TextStyle(fontFamily: Poppins),),
                                                                    filteredItems[index]
                                                                                .isCommentEnabled ==
                                                                            true
                                                                        ? IconButton(
                                                                            onPressed:
                                                                                () {
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
                                                                                                    postid: filteredItems[index].id,
                                                                                                    pic: filteredItems[index].userPic,
                                                                                                    scrollController: scrollController,
                                                                                                    isEventPost: filteredItems[index].addMeInFashionWeek!,
                                                                                                      userID: filteredItems[index].userid
                                                                                                  );
                                                                                                }
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      });
                                                                                },
                                                                            icon:
                                                                                const Icon(
                                                                              FontAwesomeIcons.comment,
                                                                              size:
                                                                                  20,
                                                                            ))
                                                                        : const SizedBox(),
                                                                    Padding(
                                                                        padding: EdgeInsets.only(
                                                                            left: MediaQuery.of(context).size.width *
                                                                                0.3),
                                                                        child:
                                                                            Text(
                                                                          DateFormat.yMMMEd()
                                                                              .format(DateTime.parse(filteredItems[index].date)),
                                                                          style: const TextStyle(
                                                                              fontFamily: Poppins,
                                                                              fontSize:
                                                                                  12),
                                                                        )),
                                                                  ],
                                                                )),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          filteredItems[index]
                                                                      .description
                                                                      .toString()
                                                                      .length >
                                                                  50
                                                              ? Expanded(
                                                                  child: Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              8.0),
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment
                                                                                .start,
                                                                        children: [
                                                                          isExpanded
                                                                              ? Row(
                                                                                  children: [
                                                                                    Text(
                                                                                      filteredItems[index].userName,
                                                                                      style: const TextStyle(fontFamily: Poppins, fontSize: 12, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                    const SizedBox(
                                                                                      width: 5,
                                                                                    ),
                                                                                    Text(
                                                                                      "${filteredItems[index].description.substring(0, 7)}...",
                                                                                      style: const TextStyle(
                                                                                        fontFamily: Poppins,
                                                                                        fontSize: 12,
                                                                                      ),
                                                                                      textAlign: TextAlign.start,
                                                                                    )
                                                                                  ],
                                                                                )
                                                                              : Text(filteredItems[index].userName + filteredItems[index].description,
                                                                                  style: const TextStyle(fontFamily: Poppins, fontSize: 12)),
                                                                          TextButton(
                                                                              onPressed:
                                                                                  () {
                                                                                setState(() {
                                                                                  isExpanded = !isExpanded;
                                                                                });
                                                                              },
                                                                              child:
                                                                                  Text(isExpanded ? "Show More" : "Show Less", style: TextStyle(color: Theme.of(context).primaryColor,fontFamily: Poppins)))
                                                                        ],
                                                                      )),
                                                                )
                                                              : Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          8.0),
                                                                  child: Column(
                                                                    children: [
                                                                      Row(
                                                                        children: [
                                                                          Text(
                                                                            filteredItems[index]
                                                                                .userName,
                                                                            style: const TextStyle(
                                                                                fontFamily: Poppins,
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.bold),
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                5,
                                                                          ),
                                                                          Text(
                                                                            filteredItems[index]
                                                                                .description,
                                                                            style: const TextStyle(
                                                                                fontFamily: Poppins,
                                                                                fontSize: 12),
                                                                          ),
                                                                        ],
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
                                              },
                                            ))
                                      : trendingItems.isNotEmpty
                                          ? ListView.builder(
                                              itemCount: trendingItems.length,
                                              itemBuilder: (context, index) {
                                                return Card(
                                                  elevation: 10,
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        decoration: BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                                    begin: Alignment
                                                                        .topLeft,
                                                                    end: Alignment
                                                                        .topRight,
                                                                    stops: const [
                                                                      0.0,
                                                                      0.99
                                                                    ],
                                                                    tileMode:
                                                                        TileMode
                                                                            .clamp,
                                                                    colors: <
                                                                        Color>[
                                                                      secondary,
                                                                      primary,
                                                                    ])),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 10.0,
                                                                  right: 10,
                                                                  top: 5,
                                                                  bottom: 5),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              GestureDetector(
                                                                onTap: () {

                                                                  trendingItems[index]
                                                                              .userName ==
                                                                          name
                                                                      ? Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => MyProfileScreen(
                                                                                    id: trendingItems[index].userid,
                                                                                    username: trendingItems[index].userName,
                                                                                  )))
                                                                      : Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => FriendProfileScreen(
                                                                                    id: trendingItems[index].userid,
                                                                                    username: trendingItems[index].userName,
                                                                                  )));
                                                                },
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          4.0),
                                                                  child:
                                                                      SizedBox(
                                                                    width: 180,
                                                                    child: Row(
                                                                      children: [
                                                                        const SizedBox(
                                                                          width:
                                                                              10,
                                                                        ),
                                                                        CircleAvatar(
                                                                            backgroundColor:
                                                                                dark1,
                                                                            child:
                                                                                ClipRRect(
                                                                              borderRadius:
                                                                                  const BorderRadius.all(Radius.circular(50)),
                                                                              child: trendingItems[index].userPic == null
                                                                                  ? Image.network(
                                                                                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                      width: 35,
                                                                                      height: 40,
                                                                                    )
                                                                                  : CachedNetworkImage(
                                                                                      imageUrl: trendingItems[index].userPic,
                                                                                      imageBuilder: (context, imageProvider) => Container(
                                                                                        height: MediaQuery.of(context).size.height * 0.7,
                                                                                        width: MediaQuery.of(context).size.width,
                                                                                        decoration: BoxDecoration(
                                                                                          image: DecorationImage(
                                                                                            image: imageProvider,
                                                                                            fit: BoxFit.cover,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      placeholder: (context, url) => Center(
                                                                                          child: SpinKitCircle(
                                                                                        color: primary,
                                                                                        size: 10,
                                                                                      )),
                                                                                      errorWidget: (context, url, error) => ClipRRect(
                                                                                          borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                                                          child: Image.network(
                                                                                            "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                            width: 35,
                                                                                            height: 35,
                                                                                          )),
                                                                                    ),
                                                                            )),
                                                                        const SizedBox(
                                                                          width:
                                                                              5,
                                                                        ),
                                                                        Text(
                                                                          trendingItems[index]
                                                                              .userName,
                                                                          style: const TextStyle(
                                                                              fontFamily: Poppins,
                                                                              color:
                                                                                  ascent,
                                                                              fontWeight:
                                                                                  FontWeight.bold),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              PopupMenuButton(
                                                                  icon:
                                                                      const Icon(
                                                                    Icons
                                                                        .more_horiz,
                                                                    color: ascent,
                                                                  ),
                                                                  onSelected:
                                                                      (value) {
                                                                    if (value ==
                                                                        0) {
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) =>
                                                                                  ReportScreen(reportedID: trendingItems[index].userid)));
                                                                    }
                                                                    if (value ==
                                                                        2) {}
                                                                    debugPrint(value
                                                                        .toString());
                                                                    //Navigator.pushNamed(context, value.toString());
                                                                  },
                                                                  itemBuilder:
                                                                      (BuildContext
                                                                          bc) {
                                                                    return [
                                                                      PopupMenuItem(
                                                                        value: 0,
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Icon(Icons
                                                                                .report),
                                                                            SizedBox(
                                                                              width:
                                                                                  10,
                                                                            ),
                                                                            Text(
                                                                              "Report",
                                                                              style:
                                                                                  TextStyle(fontFamily: Poppins),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      if (trendingItems[index]
                                                                              .userid !=
                                                                          id)
                                                                        PopupMenuItem(
                                                                          value:
                                                                              2,
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              Icon(Icons.save),
                                                                              SizedBox(
                                                                                width: 10,
                                                                              ),
                                                                              Text(
                                                                                "Save Post",
                                                                                style: TextStyle(fontFamily: Poppins),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                    ];
                                                                  })
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () {},
                                                            child: SizedBox(
                                                              height: 320,
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.87,
                                                              child:
                                                                  CarouselSlider(
                                                                carouselController:
                                                                    _controller,
                                                                options:
                                                                    CarouselOptions(
                                                                        enableInfiniteScroll:
                                                                            false,
                                                                        height:
                                                                            320.0,
                                                                        autoPlay:
                                                                            false,
                                                                        enlargeCenterPage:
                                                                            true,
                                                                        viewportFraction:
                                                                            0.99,
                                                                        aspectRatio:
                                                                            2.0,
                                                                        initialPage:
                                                                            0,
                                                                        onPageChanged:
                                                                            (ind,
                                                                                reason) {
                                                                          setState(
                                                                              () {
                                                                            _current =
                                                                                ind;
                                                                          });
                                                                        }),
                                                                items:
                                                                    trendingItems[
                                                                            index]
                                                                        .images
                                                                        .map((i) {
                                                                  return i["type"] ==
                                                                          "video"
                                                                      ? Container(
                                                                          color: Colors.black,
                                                                          child: Text("Video")
                                                                       )
                                                                          // child: UsingVideoControllerExample(
                                                                          //   path: i["video"],
                                                                          // ))
                                                                      : Builder(
                                                                          builder:
                                                                              (BuildContext
                                                                                  context) {
                                                                            return CachedNetworkImage(
                                                                              imageUrl:
                                                                                  i["image"],
                                                                              imageBuilder: (context, imageProvider) =>
                                                                                  Container(
                                                                                height: MediaQuery.of(context).size.height,
                                                                                width: MediaQuery.of(context).size.width,
                                                                                decoration: BoxDecoration(
                                                                                  image: DecorationImage(
                                                                                    image: imageProvider,
                                                                                    fit: BoxFit.cover,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              placeholder: (context, url) =>
                                                                                  SpinKitCircle(
                                                                                color: primary,
                                                                                size: 60,
                                                                              ),
                                                                              errorWidget: (context, url, error) =>
                                                                                  Container(
                                                                                height: MediaQuery.of(context).size.height * 0.84,
                                                                                width: MediaQuery.of(context).size.width,
                                                                                decoration: BoxDecoration(
                                                                                  image: DecorationImage(image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image, fit: BoxFit.fill),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                        );
                                                                }).toList(),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                8.0),
                                                        child: Text(
                                                            trendingItems[index]
                                                                .images
                                                                .length
                                                                .toString()),
                                                      ),
                                                      trendingItems[index]
                                                                  .images
                                                                  .length ==
                                                              1
                                                          ? const SizedBox()
                                                          : Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children:
                                                                  trendingItems[
                                                                          index]
                                                                      .images
                                                                      .asMap()
                                                                      .entries
                                                                      .map(
                                                                          (entry) {
                                                                return GestureDetector(
                                                                  onTap: () => _controller
                                                                      .animateToPage(
                                                                          entry
                                                                              .key),
                                                                  child:
                                                                      Container(
                                                                    width: 12.0,
                                                                    height: 12.0,
                                                                    margin: const EdgeInsets
                                                                            .symmetric(
                                                                        vertical:
                                                                            8.0,
                                                                        horizontal:
                                                                            4.0),
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(_current ==
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
                                                      const Divider(
                                                        height: 2,
                                                        thickness: 2,
                                                      ),
                                                      Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 0.0,
                                                                  right: 0.0),
                                                          child: trendingItems[
                                                                          index]
                                                                      .userid ==
                                                                  id
                                                              ? Row(
                                                                  children: [
                                                                    trendingItems[index]
                                                                                .addMeInFashionWeek ==
                                                                            true
                                                                        ? trendingItems[index].mylike !=
                                                                                "like"
                                                                            ? IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  Icons.favorite,
                                                                                  size: 20,
                                                                                ))
                                                                            : IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  FontAwesomeIcons.heart,
                                                                                  size: 20,
                                                                                ))
                                                                        : trendingItems[index].mylike != "like"
                                                                            ? IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  Icons.star,
                                                                                  color: Colors.orange,
                                                                                  size: 24,
                                                                                ))
                                                                            : GestureDetector(
                                                                                onDoubleTap: () {},
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.all(8.0),
                                                                                  child: Icon(Icons.star_border_outlined, size: 24, color: Colors.orange),
                                                                                ),
                                                                              ),
                                                                    trendingItems[index]
                                                                                .likeCount ==
                                                                            "0"
                                                                        ? const SizedBox()
                                                                        : Text(trendingItems[
                                                                                index]
                                                                            .likeCount,style: TextStyle(fontFamily: Poppins),),
                                                                    trendingItems[index]
                                                                                .isCommentEnabled ==
                                                                            true
                                                                        ? IconButton(
                                                                            onPressed:
                                                                                () {
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
                                                                                          child:NotificationListener<DraggableScrollableNotification>(
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
                                                                                                    postid: trendingItems[index].id,
                                                                                                    pic: trendingItems[index].userPic,
                                                                                                    scrollController: scrollController,
                                                                                                      isEventPost: trendingItems[index].addMeInFashionWeek!,
                                                                                                      userID: trendingItems[index].userid
                                                                                                  );
                                                                                                }
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      });
                                                                                 },
                                                                            icon:
                                                                                const Icon(
                                                                              FontAwesomeIcons.comment,
                                                                              size:
                                                                                  20,
                                                                            ))
                                                                        : const SizedBox(),
                                                                    Padding(
                                                                        padding: EdgeInsets.only(
                                                                            left: trendingItems[index].isCommentEnabled == true
                                                                                ? MediaQuery.of(context).size.width * 0.35
                                                                                : MediaQuery.of(context).size.width * 0.4),
                                                                        child: Text(
                                                                          DateFormat.yMMMEd()
                                                                              .format(DateTime.parse(trendingItems[index].date)),
                                                                          style: const TextStyle(
                                                                              fontFamily: Poppins,
                                                                              fontSize:
                                                                                  12),
                                                                        )),
                                                                  ],
                                                                )
                                                              : Row(
                                                                  children: [
                                                                    trendingItems[index]
                                                                                .addMeInFashionWeek ==
                                                                            true
                                                                        ? trendingItems[index].mylike !=
                                                                                "like"
                                                                            ? IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  Icons.favorite,
                                                                                  size: 20,
                                                                                ))
                                                                            : IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  FontAwesomeIcons.heart,
                                                                                  size: 20,
                                                                                ))
                                                                        : trendingItems[index].mylike != "like"
                                                                            ? IconButton(
                                                                                onPressed: () {},
                                                                                icon: const Icon(
                                                                                  Icons.star,
                                                                                  color: Colors.orange,
                                                                                  size: 24,
                                                                                ))
                                                                            : GestureDetector(
                                                                                onDoubleTap: () {},
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.all(8.0),
                                                                                  child: Icon(
                                                                                    Icons.star_border_outlined,
                                                                                    color: Colors.orange,
                                                                                    size: 24,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                    trendingItems[index]
                                                                                .likeCount ==
                                                                            "0"
                                                                        ? const SizedBox()
                                                                        : Text(trendingItems[
                                                                                index]
                                                                            .likeCount,style: TextStyle(fontFamily: Poppins),),
                                                                    trendingItems[index]
                                                                                .isCommentEnabled ==
                                                                            true
                                                                        ? IconButton(
                                                                            onPressed:
                                                                                () {
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
                                                                                          child : NotificationListener<DraggableScrollableNotification>(
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
                                                                                                    postid: trendingItems[index].id,
                                                                                                    pic: trendingItems[index].userPic,
                                                                                                    scrollController: scrollController,
                                                                                                      isEventPost: trendingItems[index].addMeInFashionWeek!,
                                                                                                      userID: trendingItems[index].userid
                                                                                                  );
                                                                                                }
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      });
                                                                               },
                                                                            icon:
                                                                                const Icon(
                                                                              FontAwesomeIcons.comment,
                                                                              size:
                                                                                  20,
                                                                            ))
                                                                        : const SizedBox(),
                                                                    Padding(
                                                                        padding: EdgeInsets.only(
                                                                            left: MediaQuery.of(context).size.width *
                                                                                0.3),
                                                                        child:
                                                                            Text(
                                                                          DateFormat.yMMMEd()
                                                                              .format(DateTime.parse(trendingItems[index].date)),
                                                                          style: const TextStyle(
                                                                              fontFamily: Poppins,
                                                                              fontSize:
                                                                                  12),
                                                                        )),
                                                                  ],
                                                                )),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          trendingItems[index]
                                                                      .description
                                                                      .toString()
                                                                      .length >
                                                                  50
                                                              ? Expanded(
                                                                  child: Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              8.0),
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment
                                                                                .start,
                                                                        children: [
                                                                          isExpanded
                                                                              ? Row(
                                                                                  children: [
                                                                                    Text(
                                                                                      trendingItems[index].userName,
                                                                                      style: const TextStyle(fontFamily: Poppins, fontSize: 12, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                    const SizedBox(
                                                                                      width: 5,
                                                                                    ),
                                                                                    Text(
                                                                                      "${trendingItems[index].description.substring(0, 7)}...",
                                                                                      style: const TextStyle(
                                                                                        fontFamily: Poppins,
                                                                                        fontSize: 12,
                                                                                      ),
                                                                                      textAlign: TextAlign.start,
                                                                                    )
                                                                                  ],
                                                                                )
                                                                              : Text(trendingItems[index].userName + trendingItems[index].description,
                                                                                  style: const TextStyle(fontFamily: Poppins, fontSize: 12)),
                                                                          TextButton(
                                                                              onPressed:
                                                                                  () {
                                                                                setState(() {
                                                                                  isExpanded = !isExpanded;
                                                                                });
                                                                              },
                                                                              child:
                                                                                  Text(isExpanded ? "Show More" : "Show Less", style: TextStyle(color: Theme.of(context).primaryColor,fontFamily: Poppins)))
                                                                        ],
                                                                      )),
                                                                )
                                                              : Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          8.0),
                                                                  child: Column(
                                                                    children: [
                                                                      Row(
                                                                        children: [
                                                                          Text(
                                                                            trendingItems[index]
                                                                                .userName,
                                                                            style: const TextStyle(
                                                                                fontFamily: Poppins,
                                                                                fontSize: 12,
                                                                                fontWeight: FontWeight.bold),
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                5,
                                                                          ),
                                                                          Text(
                                                                            trendingItems[index]
                                                                                .description,
                                                                            style: const TextStyle(
                                                                                fontFamily: Poppins,
                                                                                fontSize: 12),
                                                                          ),
                                                                        ],
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
                                              },
                                            )
                                          : trendingItems2.isNotEmpty
                                              ? ListView.builder(
                                                  itemCount:
                                                      trendingItems2.length,
                                                  itemBuilder: (context, index) {
                                                    return Card(
                                                      elevation: 10,
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
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      left: 10.0,
                                                                      right: 10,
                                                                      top: 5,
                                                                      bottom: 5),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      trendingItems2[index].userName ==
                                                                              name
                                                                          ? Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                  builder: (context) => MyProfileScreen(
                                                                                        id: trendingItems2[index].userid,
                                                                                        username: trendingItems2[index].userName,
                                                                                      )))
                                                                          : Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                  builder: (context) => FriendProfileScreen(
                                                                                        id: trendingItems2[index].userid,
                                                                                        username: trendingItems2[index].userName,
                                                                                      )));
                                                                    },
                                                                    child:
                                                                        Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              4.0),
                                                                      child:
                                                                          SizedBox(
                                                                        width:
                                                                            180,
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            const SizedBox(
                                                                              width:
                                                                                  10,
                                                                            ),
                                                                            CircleAvatar(
                                                                                backgroundColor: dark1,
                                                                                child: ClipRRect(
                                                                                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                                                  child: trendingItems2[index].userPic == null
                                                                                      ? Image.network(
                                                                                          "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                          width: 35,
                                                                                          height: 40,
                                                                                        )
                                                                                      : CachedNetworkImage(
                                                                                          imageUrl: trendingItems2[index].userPic,
                                                                                          imageBuilder: (context, imageProvider) => Container(
                                                                                            height: MediaQuery.of(context).size.height * 0.7,
                                                                                            width: MediaQuery.of(context).size.width,
                                                                                            decoration: BoxDecoration(
                                                                                              image: DecorationImage(
                                                                                                image: imageProvider,
                                                                                                fit: BoxFit.cover,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          placeholder: (context, url) => Center(
                                                                                              child: SpinKitCircle(
                                                                                            color: primary,
                                                                                            size: 10,
                                                                                          )),
                                                                                          errorWidget: (context, url, error) => ClipRRect(
                                                                                              borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                                                              child: Image.network(
                                                                                                "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                                width: 35,
                                                                                                height: 35,
                                                                                              )),
                                                                                        ),
                                                                                )),
                                                                            const SizedBox(
                                                                              width:
                                                                                  5,
                                                                            ),
                                                                            Text(
                                                                              trendingItems2[index].userName,
                                                                              style: const TextStyle(
                                                                                  fontFamily: Poppins,
                                                                                  color: ascent,
                                                                                  fontWeight: FontWeight.bold),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  PopupMenuButton(
                                                                      icon:
                                                                          const Icon(
                                                                        Icons
                                                                            .more_horiz,
                                                                        color:
                                                                            ascent,
                                                                      ),
                                                                      onSelected:
                                                                          (value) {
                                                                        if (value ==
                                                                            0) {
                                                                          Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(builder: (context) => ReportScreen(reportedID: trendingItems2[index].userid)));
                                                                        }
                                                                        if (value ==
                                                                            2) {}
                                                                        debugPrint(
                                                                            value
                                                                                .toString());
                                                                        //Navigator.pushNamed(context, value.toString());
                                                                      },
                                                                      itemBuilder:
                                                                          (BuildContext
                                                                              bc) {
                                                                        return [
                                                                          PopupMenuItem(
                                                                            value:
                                                                                0,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Icon(Icons.report),
                                                                                SizedBox(
                                                                                  width: 10,
                                                                                ),
                                                                                Text(
                                                                                  "Report",
                                                                                  style: TextStyle(fontFamily: Poppins),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          if (trendingItems2[index].userid !=
                                                                              id)
                                                                             PopupMenuItem(
                                                                              value:
                                                                                  2,
                                                                              child:
                                                                                  Row(
                                                                                children: [
                                                                                  Icon(Icons.save),
                                                                                  SizedBox(
                                                                                    width: 10,
                                                                                  ),
                                                                                  Text(
                                                                                    "Save Post",
                                                                                    style: TextStyle(fontFamily: Poppins),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                        ];
                                                                      })
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              GestureDetector(
                                                                onTap: () {},
                                                                child: SizedBox(
                                                                  height: 320,
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.87,
                                                                  child:
                                                                      CarouselSlider(
                                                                    carouselController:
                                                                        _controller,
                                                                    options: CarouselOptions(
                                                                        enableInfiniteScroll: false,
                                                                        height: 320.0,
                                                                        autoPlay: false,
                                                                        enlargeCenterPage: true,
                                                                        viewportFraction: 0.99,
                                                                        aspectRatio: 2.0,
                                                                        initialPage: 0,
                                                                        onPageChanged: (ind, reason) {
                                                                          setState(
                                                                              () {
                                                                            _current =
                                                                                ind;
                                                                          });
                                                                        }),
                                                                    items: trendingItems2[
                                                                            index]
                                                                        .images
                                                                        .map((i) {
                                                                      return i["type"] ==
                                                                              "video"
                                                                          ? Container(
                                                                              color: Colors.black,
                                                                              child: Text("Video")
                                                                           )
                                                                              // child: UsingVideoControllerExample(
                                                                              //   path: i["video"],
                                                                              // ))
                                                                          : Builder(
                                                                              builder:
                                                                                  (BuildContext context) {
                                                                                return CachedNetworkImage(
                                                                                  imageUrl: i["image"],
                                                                                  imageBuilder: (context, imageProvider) => Container(
                                                                                    height: MediaQuery.of(context).size.height,
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    decoration: BoxDecoration(
                                                                                      image: DecorationImage(
                                                                                        image: imageProvider,
                                                                                        fit: BoxFit.cover,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  placeholder: (context, url) => SpinKitCircle(
                                                                                    color: primary,
                                                                                    size: 60,
                                                                                  ),
                                                                                  errorWidget: (context, url, error) => Container(
                                                                                    height: MediaQuery.of(context).size.height * 0.84,
                                                                                    width: MediaQuery.of(context).size.width,
                                                                                    decoration: BoxDecoration(
                                                                                      image: DecorationImage(image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image, fit: BoxFit.fill),
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              },
                                                                            );
                                                                    }).toList(),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Text(
                                                                trendingItems2[
                                                                        index]
                                                                    .images
                                                                    .length
                                                                    .toString()),
                                                          ),
                                                          trendingItems2[index]
                                                                      .images
                                                                      .length ==
                                                                  1
                                                              ? const SizedBox()
                                                              : Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: filteredTrendingPosts[
                                                                          index]
                                                                      .images
                                                                      .asMap()
                                                                      .entries
                                                                      .map(
                                                                          (entry) {
                                                                    return GestureDetector(
                                                                      onTap: () =>
                                                                          _controller
                                                                              .animateToPage(entry.key),
                                                                      child:
                                                                          Container(
                                                                        width:
                                                                            12.0,
                                                                        height:
                                                                            12.0,
                                                                        margin: const EdgeInsets
                                                                                .symmetric(
                                                                            vertical:
                                                                                8.0,
                                                                            horizontal:
                                                                                4.0),
                                                                        decoration: BoxDecoration(
                                                                            shape: BoxShape
                                                                                .circle,
                                                                            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(_current == entry.key
                                                                                ? 0.9
                                                                                : 0.4)),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          const Divider(
                                                            height: 2,
                                                            thickness: 2,
                                                          ),
                                                          Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      left: 0.0,
                                                                      right: 0.0),
                                                              child: trendingItems2[
                                                                              index]
                                                                          .userid ==
                                                                      id
                                                                  ? Row(
                                                                      children: [
                                                                        trendingItems2[index].addMeInFashionWeek ==
                                                                                true
                                                                            ? trendingItems2[index].mylike != "like"
                                                                                ? IconButton(
                                                                                    onPressed: () {},
                                                                                    icon: const Icon(
                                                                                      Icons.favorite,
                                                                                      size: 20,
                                                                                    ))
                                                                                : IconButton(
                                                                                    onPressed: () {},
                                                                                    icon: const Icon(
                                                                                      FontAwesomeIcons.heart,
                                                                                      size: 20,
                                                                                    ))
                                                                            : trendingItems2[index].mylike != "like"
                                                                                ? IconButton(
                                                                                    onPressed: () {},
                                                                                    icon: const Icon(
                                                                                      Icons.star,
                                                                                      color: Colors.orange,
                                                                                      size: 24,
                                                                                    ))
                                                                                : GestureDetector(
                                                                                    onDoubleTap: () {},
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.all(8.0),
                                                                                      child: Icon(Icons.star_border_outlined, size: 24, color: Colors.orange),
                                                                                    ),
                                                                                  ),
                                                                        trendingItems2[index].likeCount ==
                                                                                "0"
                                                                            ? const SizedBox()
                                                                            : Text(
                                                                                trendingItems2[index].likeCount,style: TextStyle(fontFamily: Poppins),),
                                                                        trendingItems2[index].isCommentEnabled ==
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
                                                                                                    postid: trendingItems2[index].id,
                                                                                                    pic: trendingItems2[index].userPic,
                                                                                                    scrollController: scrollController,
                                                                                                      isEventPost: trendingItems2[index].addMeInFashionWeek!,
                                                                                                      userID: trendingItems2[index].userid
                                                                                                  );
                                                                                                }
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      });
                                                                                     },
                                                                                icon: const Icon(
                                                                                  FontAwesomeIcons.comment,
                                                                                  size: 20,
                                                                                ))
                                                                            : const SizedBox(),
                                                                        Padding(
                                                                            padding:
                                                                                EdgeInsets.only(left: trendingItems2[index].isCommentEnabled == true ? MediaQuery.of(context).size.width * 0.35 : MediaQuery.of(context).size.width * 0.4),
                                                                            child: Text(
                                                                              DateFormat.yMMMEd().format(DateTime.parse(trendingItems2[index].date)),
                                                                              style:
                                                                                  const TextStyle(fontFamily: Poppins, fontSize: 12),
                                                                            )),
                                                                      ],
                                                                    )
                                                                  : Row(
                                                                      children: [
                                                                        trendingItems2[index].addMeInFashionWeek ==
                                                                                true
                                                                            ? trendingItems2[index].mylike != "like"
                                                                                ? IconButton(
                                                                                    onPressed: () {},
                                                                                    icon: const Icon(
                                                                                      Icons.favorite,
                                                                                      size: 20,
                                                                                    ))
                                                                                : IconButton(
                                                                                    onPressed: () {},
                                                                                    icon: const Icon(
                                                                                      FontAwesomeIcons.heart,
                                                                                      size: 20,
                                                                                    ))
                                                                            : trendingItems2[index].mylike != "like"
                                                                                ? IconButton(
                                                                                    onPressed: () {},
                                                                                    icon: const Icon(
                                                                                      Icons.star,
                                                                                      color: Colors.orange,
                                                                                      size: 24,
                                                                                    ))
                                                                                : GestureDetector(
                                                                                    onDoubleTap: () {},
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.all(8.0),
                                                                                      child: Icon(
                                                                                        Icons.star_border_outlined,
                                                                                        color: Colors.orange,
                                                                                        size: 24,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                        trendingItems2[index].likeCount ==
                                                                                "0"
                                                                            ? const SizedBox()
                                                                            : Text(
                                                                                trendingItems2[index].likeCount,style: TextStyle(fontFamily: Poppins),),
                                                                        trendingItems2[index].isCommentEnabled ==
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
                                                                                                    postid: trendingItems2[index].id,
                                                                                                    pic: trendingItems2[index].userPic,
                                                                                                    scrollController: scrollController,
                                                                                                      isEventPost: trendingItems2[index].addMeInFashionWeek!,
                                                                                                      userID: trendingItems2[index].userid
                                                                                                  );
                                                                                                }
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                      });
                                                                                  },
                                                                                icon: const Icon(
                                                                                  FontAwesomeIcons.comment,
                                                                                  size: 20,
                                                                                ))
                                                                            : const SizedBox(),
                                                                        Padding(
                                                                            padding: EdgeInsets.only(
                                                                                left: MediaQuery.of(context).size.width *
                                                                                    0.3),
                                                                            child:
                                                                                Text(
                                                                              DateFormat.yMMMEd().format(DateTime.parse(trendingItems2[index].date)),
                                                                              style:
                                                                                  const TextStyle(fontFamily: Poppins, fontSize: 12),
                                                                            )),
                                                                      ],
                                                                    )),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              trendingItems2[index]
                                                                          .description
                                                                          .toString()
                                                                          .length >
                                                                      50
                                                                  ? Expanded(
                                                                      child: Padding(
                                                                          padding: const EdgeInsets.all(8.0),
                                                                          child: Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              isExpanded
                                                                                  ? Row(
                                                                                      children: [
                                                                                        Text(
                                                                                          trendingItems2[index].userName,
                                                                                          style: const TextStyle(fontFamily: Poppins, fontSize: 12, fontWeight: FontWeight.bold),
                                                                                        ),
                                                                                        const SizedBox(
                                                                                          width: 5,
                                                                                        ),
                                                                                        Text(
                                                                                          "${trendingItems2[index].description.substring(0, 7)}...",
                                                                                          style: const TextStyle(
                                                                                            fontFamily: Poppins,
                                                                                            fontSize: 12,
                                                                                          ),
                                                                                          textAlign: TextAlign.start,
                                                                                        )
                                                                                      ],
                                                                                    )
                                                                                  : Text(trendingItems2[index].userName + trendingItems2[index].description, style: const TextStyle(fontFamily: Poppins, fontSize: 12)),
                                                                              TextButton(
                                                                                  onPressed: () {
                                                                                    setState(() {
                                                                                      isExpanded = !isExpanded;
                                                                                    });
                                                                                  },
                                                                                  child: Text(isExpanded ? "Show More" : "Show Less", style: TextStyle(color: Theme.of(context).primaryColor,fontFamily: Poppins)))
                                                                            ],
                                                                          )),
                                                                    )
                                                                  : Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              8.0),
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              Text(
                                                                                trendingItems2[index].userName,
                                                                                style: const TextStyle(fontFamily: Poppins, fontSize: 12, fontWeight: FontWeight.bold),
                                                                              ),
                                                                              const SizedBox(
                                                                                width: 5,
                                                                              ),
                                                                              Text(
                                                                                trendingItems2[index].description,
                                                                                style: const TextStyle(fontFamily: Poppins, fontSize: 12),
                                                                              ),
                                                                            ],
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
                                                  },
                                                )
                                              : filteredTrendingPosts.isNotEmpty
                                                  ? ListView.builder(
                                                      itemCount:
                                                          filteredTrendingPosts
                                                              .length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return Card(
                                                          elevation: 10,
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
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              10.0,
                                                                          right:
                                                                              10,
                                                                          top: 5,
                                                                          bottom:
                                                                              5),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          filteredTrendingPosts[index].userName ==
                                                                                  name
                                                                              ? Navigator.push(
                                                                                  context,
                                                                                  MaterialPageRoute(
                                                                                      builder: (context) => MyProfileScreen(
                                                                                            id: filteredTrendingPosts[index].userid,
                                                                                            username: filteredTrendingPosts[index].userName,
                                                                                          )))
                                                                              : Navigator.push(
                                                                                  context,
                                                                                  MaterialPageRoute(
                                                                                      builder: (context) => FriendProfileScreen(
                                                                                            id: filteredTrendingPosts[index].userid,
                                                                                            username: filteredTrendingPosts[index].userName,
                                                                                          )));
                                                                        },
                                                                        child:
                                                                            Padding(
                                                                          padding:
                                                                              const EdgeInsets.all(4.0),
                                                                          child:
                                                                              SizedBox(
                                                                            width:
                                                                                180,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                const SizedBox(
                                                                                  width: 10,
                                                                                ),
                                                                                CircleAvatar(
                                                                                    backgroundColor: dark1,
                                                                                    child: ClipRRect(
                                                                                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                                                      child: filteredTrendingPosts[index].userPic == null
                                                                                          ? Image.network(
                                                                                              "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                              width: 35,
                                                                                              height: 40,
                                                                                            )
                                                                                          : CachedNetworkImage(
                                                                                              imageUrl: filteredTrendingPosts[index].userPic,
                                                                                              imageBuilder: (context, imageProvider) => Container(
                                                                                                height: MediaQuery.of(context).size.height * 0.7,
                                                                                                width: MediaQuery.of(context).size.width,
                                                                                                decoration: BoxDecoration(
                                                                                                  image: DecorationImage(
                                                                                                    image: imageProvider,
                                                                                                    fit: BoxFit.cover,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              placeholder: (context, url) => Center(
                                                                                                  child: SpinKitCircle(
                                                                                                color: primary,
                                                                                                size: 10,
                                                                                              )),
                                                                                              errorWidget: (context, url, error) => ClipRRect(
                                                                                                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                                                                  child: Image.network(
                                                                                                    "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                                    width: 35,
                                                                                                    height: 35,
                                                                                                  )),
                                                                                            ),
                                                                                    )),
                                                                                const SizedBox(
                                                                                  width: 5,
                                                                                ),
                                                                                Text(
                                                                                  filteredTrendingPosts[index].userName,
                                                                                  style: const TextStyle(fontFamily: Poppins, color: ascent, fontWeight: FontWeight.bold),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      PopupMenuButton(
                                                                          icon:
                                                                              const Icon(
                                                                            Icons
                                                                                .more_horiz,
                                                                            color:
                                                                                ascent,
                                                                          ),
                                                                          onSelected:
                                                                              (value) {
                                                                            if (value ==
                                                                                0) {
                                                                              Navigator.push(context,
                                                                                  MaterialPageRoute(builder: (context) => ReportScreen(reportedID: filteredTrendingPosts[index].userid)));
                                                                            }
                                                                            if (value ==
                                                                                2) {}
                                                                            debugPrint(
                                                                                value.toString());
                                                                            //Navigator.pushNamed(context, value.toString());
                                                                          },
                                                                          itemBuilder:
                                                                              (BuildContext
                                                                                  bc) {
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
                                                                                      style: TextStyle(fontFamily: Poppins),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              if (filteredTrendingPosts[index].userid !=
                                                                                  id)
                                                                                 PopupMenuItem(
                                                                                  value: 2,
                                                                                  child: Row(
                                                                                    children: [
                                                                                      Icon(Icons.save),
                                                                                      SizedBox(
                                                                                        width: 10,
                                                                                      ),
                                                                                      Text(
                                                                                        "Save Post",
                                                                                        style: TextStyle(fontFamily: Poppins),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                            ];
                                                                          })
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  GestureDetector(
                                                                    onTap: () {},
                                                                    child:
                                                                        SizedBox(
                                                                      height: 320,
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.87,
                                                                      child:
                                                                          CarouselSlider(
                                                                        carouselController:
                                                                            _controller,
                                                                        options: CarouselOptions(
                                                                            enableInfiniteScroll: false,
                                                                            height: 320.0,
                                                                            autoPlay: false,
                                                                            enlargeCenterPage: true,
                                                                            viewportFraction: 0.99,
                                                                            aspectRatio: 2.0,
                                                                            initialPage: 0,
                                                                            onPageChanged: (ind, reason) {
                                                                              setState(() {
                                                                                _current = ind;
                                                                              });
                                                                            }),
                                                                        items: filteredTrendingPosts[
                                                                                index]
                                                                            .images
                                                                            .map(
                                                                                (i) {
                                                                          return i["type"] ==
                                                                                  "video"
                                                                              ? Container(
                                                                                  color: Colors.black,
                                                                                  child: Text("Video")
                                                                                )
                                                                                  // child: UsingVideoControllerExample(
                                                                                  //   path: i["video"],
                                                                                  // ))
                                                                              : Builder(
                                                                                  builder: (BuildContext context) {
                                                                                    return CachedNetworkImage(
                                                                                      imageUrl: i["image"],
                                                                                      imageBuilder: (context, imageProvider) => Container(
                                                                                        height: MediaQuery.of(context).size.height,
                                                                                        width: MediaQuery.of(context).size.width,
                                                                                        decoration: BoxDecoration(
                                                                                          image: DecorationImage(
                                                                                            image: imageProvider,
                                                                                            fit: BoxFit.cover,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      placeholder: (context, url) => SpinKitCircle(
                                                                                        color: primary,
                                                                                        size: 60,
                                                                                      ),
                                                                                      errorWidget: (context, url, error) => Container(
                                                                                        height: MediaQuery.of(context).size.height * 0.84,
                                                                                        width: MediaQuery.of(context).size.width,
                                                                                        decoration: BoxDecoration(
                                                                                          image: DecorationImage(image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image, fit: BoxFit.fill),
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                );
                                                                        }).toList(),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(8.0),
                                                                child: Text(
                                                                    filteredTrendingPosts[
                                                                            index]
                                                                        .images
                                                                        .length
                                                                        .toString()),
                                                              ),
                                                              filteredTrendingPosts[
                                                                              index]
                                                                          .images
                                                                          .length ==
                                                                      1
                                                                  ? const SizedBox()
                                                                  : Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: filteredTrendingPosts[
                                                                              index]
                                                                          .images
                                                                          .asMap()
                                                                          .entries
                                                                          .map(
                                                                              (entry) {
                                                                        return GestureDetector(
                                                                          onTap: () =>
                                                                              _controller.animateToPage(entry.key),
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                12.0,
                                                                            height:
                                                                                12.0,
                                                                            margin: const EdgeInsets.symmetric(
                                                                                vertical: 8.0,
                                                                                horizontal: 4.0),
                                                                            decoration: BoxDecoration(
                                                                                shape: BoxShape.circle,
                                                                                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(_current == entry.key ? 0.9 : 0.4)),
                                                                          ),
                                                                        );
                                                                      }).toList(),
                                                                    ),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              const Divider(
                                                                height: 2,
                                                                thickness: 2,
                                                              ),
                                                              Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              0.0,
                                                                          right:
                                                                              0.0),
                                                                  child: filteredTrendingPosts[index]
                                                                              .userid ==
                                                                          id
                                                                      ? Row(
                                                                          children: [
                                                                            filteredTrendingPosts[index].addMeInFashionWeek == true
                                                                                ? filteredTrendingPosts[index].mylike != "like"
                                                                                    ? IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          Icons.favorite,
                                                                                          size: 20,
                                                                                        ))
                                                                                    : IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          FontAwesomeIcons.heart,
                                                                                          size: 20,
                                                                                        ))
                                                                                : filteredTrendingPosts[index].mylike != "like"
                                                                                    ? IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          Icons.star,
                                                                                          color: Colors.orange,
                                                                                          size: 24,
                                                                                        ))
                                                                                    : GestureDetector(
                                                                                        onDoubleTap: () {},
                                                                                        child: Padding(
                                                                                          padding: EdgeInsets.all(8.0),
                                                                                          child: Icon(Icons.star_border_outlined, size: 24, color: Colors.orange),
                                                                                        ),
                                                                                      ),
                                                                            filteredTrendingPosts[index].likeCount == "0"
                                                                                ? const SizedBox()
                                                                                : Text(filteredTrendingPosts[index].likeCount,style: TextStyle(fontFamily: Poppins),),
                                                                            filteredTrendingPosts[index].isCommentEnabled == true
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
                                                                                                        postid: filteredTrendingPosts[index].id,
                                                                                                        pic: filteredTrendingPosts[index].userPic,
                                                                                                        scrollController: scrollController,
                                                                                                          isEventPost: filteredTrendingPosts[index].addMeInFashionWeek!,
                                                                                                          userID: filteredTrendingPosts[index].userid
                                                                                                      );
                                                                                                    }
                                                                                                ),
                                                                                              ),
                                                                                            );
                                                                                          });
                                                                                      },
                                                                                    icon: const Icon(
                                                                                      FontAwesomeIcons.comment,
                                                                                      size: 20,
                                                                                    ))
                                                                                : const SizedBox(),
                                                                            Padding(
                                                                                padding: EdgeInsets.only(left: filteredTrendingPosts[index].isCommentEnabled == true ? MediaQuery.of(context).size.width * 0.35 : MediaQuery.of(context).size.width * 0.4),
                                                                                child: Text(
                                                                                  DateFormat.yMMMEd().format(DateTime.parse(filteredTrendingPosts[index].date)),
                                                                                  style: const TextStyle(fontFamily: Poppins, fontSize: 12),
                                                                                )),
                                                                          ],
                                                                        )
                                                                      : Row(
                                                                          children: [
                                                                            filteredTrendingPosts[index].addMeInFashionWeek == true
                                                                                ? filteredTrendingPosts[index].mylike != "like"
                                                                                    ? IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          Icons.favorite,
                                                                                          size: 20,
                                                                                        ))
                                                                                    : IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          FontAwesomeIcons.heart,
                                                                                          size: 20,
                                                                                        ))
                                                                                : filteredTrendingPosts[index].mylike != "like"
                                                                                    ? IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          Icons.star,
                                                                                          color: Colors.orange,
                                                                                          size: 24,
                                                                                        ))
                                                                                    : GestureDetector(
                                                                                        onDoubleTap: () {},
                                                                                        child: Padding(
                                                                                          padding: EdgeInsets.all(8.0),
                                                                                          child: Icon(
                                                                                            Icons.star_border_outlined,
                                                                                            color: Colors.orange,
                                                                                            size: 24,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                            filteredTrendingPosts[index].likeCount == "0"
                                                                                ? const SizedBox()
                                                                                : Text(filteredTrendingPosts[index].likeCount,style: TextStyle(fontFamily: Poppins),),
                                                                            filteredTrendingPosts[index].isCommentEnabled == true
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
                                                                                                        postid: filteredTrendingPosts[index].id,
                                                                                                        pic: filteredTrendingPosts[index].userPic,
                                                                                                        scrollController: scrollController,
                                                                                                          isEventPost: filteredTrendingPosts[index].addMeInFashionWeek!,
                                                                                                          userID: filteredTrendingPosts[index].userid
                                                                                                      );
                                                                                                    }
                                                                                                ),
                                                                                              ),
                                                                                            );
                                                                                          });
                                                                                      },
                                                                                    icon: const Icon(
                                                                                      FontAwesomeIcons.comment,
                                                                                      size: 20,
                                                                                    ))
                                                                                : const SizedBox(),
                                                                            Padding(
                                                                                padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.3),
                                                                                child: Text(
                                                                                  DateFormat.yMMMEd().format(DateTime.parse(filteredTrendingPosts[index].date)),
                                                                                  style: const TextStyle(fontFamily: Poppins, fontSize: 12),
                                                                                )),
                                                                          ],
                                                                        )),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  filteredTrendingPosts[index]
                                                                              .description
                                                                              .toString()
                                                                              .length >
                                                                          50
                                                                      ? Expanded(
                                                                          child: Padding(
                                                                              padding: const EdgeInsets.all(8.0),
                                                                              child: Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  isExpanded
                                                                                      ? Row(
                                                                                          children: [
                                                                                            Text(
                                                                                              filteredTrendingPosts[index].userName,
                                                                                              style: const TextStyle(fontFamily: Poppins, fontSize: 12, fontWeight: FontWeight.bold),
                                                                                            ),
                                                                                            const SizedBox(
                                                                                              width: 5,
                                                                                            ),
                                                                                            Text(
                                                                                              "${filteredTrendingPosts[index].description.substring(0, 7)}...",
                                                                                              style: const TextStyle(
                                                                                                fontFamily: Poppins,
                                                                                                fontSize: 12,
                                                                                              ),
                                                                                              textAlign: TextAlign.start,
                                                                                            )
                                                                                          ],
                                                                                        )
                                                                                      : Text(filteredTrendingPosts[index].userName + filteredTrendingPosts[index].description, style: const TextStyle(fontFamily: Poppins, fontSize: 12)),
                                                                                  TextButton(
                                                                                      onPressed: () {
                                                                                        setState(() {
                                                                                          isExpanded = !isExpanded;
                                                                                        });
                                                                                      },
                                                                                      child: Text(isExpanded ? "Show More" : "Show Less", style: TextStyle(color: Theme.of(context).primaryColor,fontFamily: Poppins)))
                                                                                ],
                                                                              )),
                                                                        )
                                                                      : Padding(
                                                                          padding:
                                                                              const EdgeInsets.all(
                                                                                  8.0),
                                                                          child:
                                                                              Column(
                                                                            children: [
                                                                              Row(
                                                                                children: [
                                                                                  Text(
                                                                                    filteredTrendingPosts[index].userName,
                                                                                    style: const TextStyle(fontFamily: Poppins, fontSize: 12, fontWeight: FontWeight.bold),
                                                                                  ),
                                                                                  const SizedBox(
                                                                                    width: 5,
                                                                                  ),
                                                                                  Text(
                                                                                    filteredTrendingPosts[index].description,
                                                                                    style: const TextStyle(fontFamily: Poppins, fontSize: 12),
                                                                                  ),
                                                                                ],
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
                                                      },
                                                    )
                                                  : ListView.builder(
                                                      itemCount: posts1.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        return Card(
                                                          elevation: 10,
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
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              10.0,
                                                                          right:
                                                                              10,
                                                                          top: 5,
                                                                          bottom:
                                                                              5),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          posts1[index].userName ==
                                                                                  name
                                                                              ? Navigator.push(
                                                                                  context,
                                                                                  MaterialPageRoute(
                                                                                      builder: (context) => MyProfileScreen(
                                                                                            id: posts1[index].userid,
                                                                                            username: posts1[index].userName,
                                                                                          )))
                                                                              : Navigator.push(
                                                                                  context,
                                                                                  MaterialPageRoute(
                                                                                      builder: (context) => FriendProfileScreen(
                                                                                            id: posts1[index].userid,
                                                                                            username: posts1[index].userName,
                                                                                          )));
                                                                        },
                                                                        child:
                                                                            Padding(
                                                                          padding:
                                                                              const EdgeInsets.all(4.0),
                                                                          child:
                                                                              SizedBox(
                                                                            width:
                                                                                180,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                const SizedBox(
                                                                                  width: 10,
                                                                                ),
                                                                                CircleAvatar(
                                                                                    backgroundColor: dark1,
                                                                                    child: ClipRRect(
                                                                                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                                                      child: posts1[index].userPic == null
                                                                                          ? Image.network(
                                                                                              "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                              width: 35,
                                                                                              height: 40,
                                                                                            )
                                                                                          : CachedNetworkImage(
                                                                                              imageUrl: posts1[index].userPic,
                                                                                              imageBuilder: (context, imageProvider) => Container(
                                                                                                height: MediaQuery.of(context).size.height * 0.7,
                                                                                                width: MediaQuery.of(context).size.width,
                                                                                                decoration: BoxDecoration(
                                                                                                  image: DecorationImage(
                                                                                                    image: imageProvider,
                                                                                                    fit: BoxFit.cover,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              placeholder: (context, url) => Center(
                                                                                                  child: SpinKitCircle(
                                                                                                color: primary,
                                                                                                size: 10,
                                                                                              )),
                                                                                              errorWidget: (context, url, error) => ClipRRect(
                                                                                                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                                                                  child: Image.network(
                                                                                                    "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                                    width: 35,
                                                                                                    height: 35,
                                                                                                  )),
                                                                                            ),
                                                                                    )),
                                                                                const SizedBox(
                                                                                  width: 5,
                                                                                ),
                                                                                Text(
                                                                                  posts1[index].userName,
                                                                                  style: const TextStyle(fontFamily: Poppins, color: ascent, fontWeight: FontWeight.bold),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      PopupMenuButton(
                                                                          icon:
                                                                              const Icon(
                                                                            Icons
                                                                                .more_horiz,
                                                                            color:
                                                                                ascent,
                                                                          ),
                                                                          onSelected:
                                                                              (value) {
                                                                            if (value ==
                                                                                0) {
                                                                              Navigator.push(context,
                                                                                  MaterialPageRoute(builder: (context) => ReportScreen(reportedID: posts1[index].userid)));
                                                                            }
                                                                            if (value ==
                                                                                2) {}
                                                                            print(
                                                                                value);
                                                                            //Navigator.pushNamed(context, value.toString());
                                                                          },
                                                                          itemBuilder:
                                                                              (BuildContext
                                                                                  bc) {
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
                                                                                      style: TextStyle(fontFamily: Poppins),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              if (posts1[index].userid !=
                                                                                  id)
                                                                                PopupMenuItem(
                                                                                  value: 2,
                                                                                  child: Row(
                                                                                    children: [
                                                                                      Icon(Icons.save),
                                                                                      SizedBox(
                                                                                        width: 10,
                                                                                      ),
                                                                                      Text(
                                                                                        "Save Post",
                                                                                        style: TextStyle(fontFamily: Poppins),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                            ];
                                                                          })
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  GestureDetector(
                                                                    onTap: () {},
                                                                    child:
                                                                        SizedBox(
                                                                      height: 320,
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.87,
                                                                      child:
                                                                          CarouselSlider(
                                                                        carouselController:
                                                                            _controller,
                                                                        options: CarouselOptions(
                                                                            enableInfiniteScroll: false,
                                                                            height: 320.0,
                                                                            autoPlay: false,
                                                                            enlargeCenterPage: true,
                                                                            viewportFraction: 0.99,
                                                                            aspectRatio: 2.0,
                                                                            initialPage: 0,
                                                                            onPageChanged: (ind, reason) {
                                                                              setState(() {
                                                                                _current = ind;
                                                                              });
                                                                            }),
                                                                        items: posts1[
                                                                                index]
                                                                            .images
                                                                            .map(
                                                                                (i) {
                                                                          return i["type"] ==
                                                                                  "video"
                                                                              ? Container(
                                                                                  color: Colors.black,
                                                                                    child: Text("Video"),
                                                                                  )
                                                                                  // child: UsingVideoControllerExample(
                                                                                  //   path: i["video"],
                                                                                  // ))
                                                                              : Builder(
                                                                                  builder: (BuildContext context) {
                                                                                    return CachedNetworkImage(
                                                                                      imageUrl: i["image"],
                                                                                      imageBuilder: (context, imageProvider) => Container(
                                                                                        height: MediaQuery.of(context).size.height,
                                                                                        width: MediaQuery.of(context).size.width,
                                                                                        decoration: BoxDecoration(
                                                                                          image: DecorationImage(
                                                                                            image: imageProvider,
                                                                                            fit: BoxFit.cover,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      placeholder: (context, url) => SpinKitCircle(
                                                                                        color: primary,
                                                                                        size: 60,
                                                                                      ),
                                                                                      errorWidget: (context, url, error) => Container(
                                                                                        height: MediaQuery.of(context).size.height * 0.84,
                                                                                        width: MediaQuery.of(context).size.width,
                                                                                        decoration: BoxDecoration(
                                                                                          image: DecorationImage(image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image, fit: BoxFit.fill),
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                );
                                                                        }).toList(),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(8.0),
                                                                child: Text(posts1[
                                                                        index]
                                                                    .images
                                                                    .length
                                                                    .toString()),
                                                              ),
                                                              posts1[index]
                                                                          .images
                                                                          .length ==
                                                                      1
                                                                  ? const SizedBox()
                                                                  : Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: posts1[
                                                                              index]
                                                                          .images
                                                                          .asMap()
                                                                          .entries
                                                                          .map(
                                                                              (entry) {
                                                                        return GestureDetector(
                                                                          onTap: () =>
                                                                              _controller.animateToPage(entry.key),
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                12.0,
                                                                            height:
                                                                                12.0,
                                                                            margin: const EdgeInsets.symmetric(
                                                                                vertical: 8.0,
                                                                                horizontal: 4.0),
                                                                            decoration: BoxDecoration(
                                                                                shape: BoxShape.circle,
                                                                                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(_current == entry.key ? 0.9 : 0.4)),
                                                                          ),
                                                                        );
                                                                      }).toList(),
                                                                    ),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              const Divider(
                                                                height: 2,
                                                                thickness: 2,
                                                              ),
                                                              Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              0.0,
                                                                          right:
                                                                              0.0),
                                                                  child: posts1[index]
                                                                              .userid ==
                                                                          id
                                                                      ? Row(
                                                                          children: [
                                                                            posts1[index].addMeInFashionWeek == true
                                                                                ? posts1[index].mylike != "like"
                                                                                    ? IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          Icons.favorite,
                                                                                          size: 20,
                                                                                        ))
                                                                                    : IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          FontAwesomeIcons.heart,
                                                                                          size: 20,
                                                                                        ))
                                                                                : posts1[index].mylike != "like"
                                                                                    ? IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          Icons.star,
                                                                                          color: Colors.orange,
                                                                                          size: 24,
                                                                                        ))
                                                                                    : GestureDetector(
                                                                                        onDoubleTap: () {},
                                                                                        child: Padding(
                                                                                          padding: EdgeInsets.all(8.0),
                                                                                          child: Icon(Icons.star_border_outlined, size: 24, color: Colors.orange),
                                                                                        ),
                                                                                      ),
                                                                            posts1[index].likeCount == "0"
                                                                                ? const SizedBox()
                                                                                : Text(posts1[index].likeCount),
                                                                            posts1[index].isCommentEnabled == true
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
                                                                                                        postid: posts1[index].id,
                                                                                                        pic: posts1[index].userPic,
                                                                                                        scrollController: scrollController,
                                                                                                          isEventPost: posts1[index].addMeInFashionWeek!,
                                                                                                          userID: posts1[index].userid
                                                                                                      );
                                                                                                    }
                                                                                                ),
                                                                                              ),
                                                                                            );
                                                                                          });
                                                                                        },
                                                                                    icon: const Icon(
                                                                                      FontAwesomeIcons.comment,
                                                                                      size: 20,
                                                                                    ))
                                                                                : const SizedBox(),
                                                                            Padding(
                                                                                padding: EdgeInsets.only(left: posts1[index].isCommentEnabled == true ? MediaQuery.of(context).size.width * 0.35 : MediaQuery.of(context).size.width * 0.4),
                                                                                child: Text(
                                                                                  DateFormat.yMMMEd().format(DateTime.parse(posts1[index].date)),
                                                                                  style: const TextStyle(fontFamily: Poppins, fontSize: 12),
                                                                                )),
                                                                          ],
                                                                        )
                                                                      : Row(
                                                                          children: [
                                                                            posts1[index].addMeInFashionWeek == true
                                                                                ? posts1[index].mylike != "like"
                                                                                    ? IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          Icons.favorite,
                                                                                          size: 20,
                                                                                        ))
                                                                                    : IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          FontAwesomeIcons.heart,
                                                                                          size: 20,
                                                                                        ))
                                                                                : posts1[index].mylike != "like"
                                                                                    ? IconButton(
                                                                                        onPressed: () {},
                                                                                        icon: const Icon(
                                                                                          Icons.star,
                                                                                          color: Colors.orange,
                                                                                          size: 24,
                                                                                        ))
                                                                                    : GestureDetector(
                                                                                        onDoubleTap: () {},
                                                                                        child: Padding(
                                                                                          padding: EdgeInsets.all(8.0),
                                                                                          child: Icon(
                                                                                            Icons.star_border_outlined,
                                                                                            color: Colors.orange,
                                                                                            size: 24,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                            posts1[index].likeCount == "0"
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
                                                                                : Text(posts1[index].likeCount,style: TextStyle(fontFamily: Poppins),),
                                                                            posts1[index].isCommentEnabled == true
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
                                                                                                        postid: posts1[index].id,
                                                                                                        pic: posts1[index].userPic,
                                                                                                        scrollController: scrollController,
                                                                                                          isEventPost: posts1[index].addMeInFashionWeek!,
                                                                                                          userID: posts1[index].userid
                                                                                                      );
                                                                                                    }
                                                                                                ),
                                                                                              ),
                                                                                            );
                                                                                          });
                                                                                      },
                                                                                    icon: const Icon(
                                                                                      FontAwesomeIcons.comment,
                                                                                      size: 20,
                                                                                    ))
                                                                                : const SizedBox(),
                                                                            Padding(
                                                                                padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.3),
                                                                                child: Text(
                                                                                  DateFormat.yMMMEd().format(DateTime.parse(posts1[index].date)),
                                                                                  style: const TextStyle(fontFamily: Poppins, fontSize: 12),
                                                                                )),
                                                                          ],
                                                                        )),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  posts1[index]
                                                                              .description
                                                                              .toString()
                                                                              .length >
                                                                          50
                                                                      ? Expanded(
                                                                          child: Padding(
                                                                              padding: const EdgeInsets.all(8.0),
                                                                              child: Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  isExpanded
                                                                                      ? Row(
                                                                                          children: [
                                                                                            Text(
                                                                                              posts1[index].userName,
                                                                                              style: const TextStyle(fontFamily: Poppins, fontSize: 12, fontWeight: FontWeight.bold),
                                                                                            ),
                                                                                            const SizedBox(
                                                                                              width: 5,
                                                                                            ),
                                                                                            Text(
                                                                                              "${posts1[index].description.substring(0, 7)}...",
                                                                                              style: const TextStyle(
                                                                                                fontFamily: Poppins,
                                                                                                fontSize: 12,
                                                                                              ),
                                                                                              textAlign: TextAlign.start,
                                                                                            )
                                                                                          ],
                                                                                        )
                                                                                      : Text(posts1[index].userName + posts1[index].description, style: const TextStyle(fontFamily: Poppins, fontSize: 12)),
                                                                                  TextButton(
                                                                                      onPressed: () {
                                                                                        setState(() {
                                                                                          isExpanded = !isExpanded;
                                                                                        });
                                                                                      },
                                                                                      child: Text(isExpanded ? "Show More" : "Show Less", style: TextStyle(color: Theme.of(context).primaryColor,fontFamily: Poppins)))
                                                                                ],
                                                                              )),
                                                                        )
                                                                      : Padding(
                                                                          padding:
                                                                              const EdgeInsets.all(
                                                                                  8.0),
                                                                          child:
                                                                              Column(
                                                                            children: [
                                                                              Row(
                                                                                children: [
                                                                                  Text(
                                                                                    posts1[index].userName,
                                                                                    style: const TextStyle(fontFamily: Poppins, fontSize: 12, fontWeight: FontWeight.bold),
                                                                                  ),
                                                                                  const SizedBox(
                                                                                    width: 5,
                                                                                  ),
                                                                                  Text(
                                                                                    posts1[index].description,
                                                                                    style: const TextStyle(fontFamily: Poppins, fontSize: 12),
                                                                                  ),
                                                                                ],
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
                                                      },
                                                    )
                                  // GridView.builder(
                                  //   itemCount: posts1.length,
                                  //   gridDelegate:
                                  //   const SliverGridDelegateWithFixedCrossAxisCount(
                                  //       crossAxisCount: 3,
                                  //       mainAxisSpacing: 1.0,
                                  //       crossAxisSpacing: 1.0),
                                  //   itemBuilder:
                                  //       (BuildContext context, int index) {
                                  //     return WidgetAnimator(
                                  //       GestureDetector(
                                  //         onTap: () {
                                  //           Navigator.push(
                                  //               context,
                                  //               MaterialPageRoute(
                                  //                   builder: (context) =>
                                  //                       SwapDetail(
                                  //                         userid:
                                  //                         posts1[index]
                                  //                             .userid,
                                  //                         image: posts1[index]
                                  //                             .images,
                                  //                         description: posts1[
                                  //                         index]
                                  //                             .description,
                                  //                         style:
                                  //                         "Fashion Style 2",
                                  //                         createdBy:
                                  //                         posts1[index]
                                  //                             .userName,
                                  //                         profile:
                                  //                         posts1[index]
                                  //                             .userPic,
                                  //                         likes: posts1[index]
                                  //                             .likeCount,
                                  //                         dislikes: posts1[
                                  //                         index]
                                  //                             .dislikeCount,
                                  //                         mylike:
                                  //                         posts1[index]
                                  //                             .mylike,
                                  //                         addMeInFashionWeek: posts1[index].addMeInFashionWeek,
                                  //                       )));
                                  //         },
                                  //         child: Card(
                                  //           shape: const RoundedRectangleBorder(
                                  //               borderRadius:
                                  //               BorderRadius.all(
                                  //                   Radius.circular(10))),
                                  //           child: Container(
                                  //             decoration: const BoxDecoration(
                                  //               borderRadius:
                                  //               BorderRadius.all(
                                  //                   Radius.circular(10)),
                                  //             ),
                                  //             child: posts1[index].images[0]
                                  //             ["type"] ==
                                  //                 "video"
                                  //                 ? Container(
                                  //               decoration:
                                  //               BoxDecoration(
                                  //                 image: DecorationImage(
                                  //                     fit: BoxFit.cover,
                                  //                     image: FileImage(
                                  //                         File(posts1[
                                  //                         index]
                                  //                             .thumbnail))),
                                  //                 borderRadius:
                                  //                 const BorderRadius.all(
                                  //                     Radius
                                  //                         .circular(
                                  //                         10)),
                                  //               ),
                                  //             )
                                  //                 : ClipRRect(
                                  //               borderRadius:
                                  //               BorderRadius
                                  //                   .circular(10),
                                  //               child:
                                  //               CachedNetworkImage(
                                  //                 imageUrl:
                                  //                 posts1[index]
                                  //                     .images[0]
                                  //                 ["image"],
                                  //                 fit: BoxFit.cover,
                                  //                 placeholder:
                                  //                     (context, url) =>
                                  //                     Center(
                                  //                       child: SizedBox(
                                  //                         width: 20.0,
                                  //                         height: 20.0,
                                  //                         child:
                                  //                         SpinKitCircle(
                                  //                           color: primary,
                                  //                           size: 20,
                                  //                         ),
                                  //                       ),
                                  //                     ),
                                  //                 errorWidget: (context,
                                  //                     url, error) =>
                                  //                     Container(
                                  //                       height: MediaQuery.of(
                                  //                           context)
                                  //                           .size
                                  //                           .height *
                                  //                           0.84,
                                  //                       width:
                                  //                       MediaQuery.of(
                                  //                           context)
                                  //                           .size
                                  //                           .width,
                                  //                       decoration:
                                  //                       BoxDecoration(
                                  //                         image: DecorationImage(
                                  //                             image: Image.network(
                                  //                                 "https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                                  //                                 .image,
                                  //                             fit: BoxFit
                                  //                                 .fill),
                                  //                       ),
                                  //                     ),
                                  //               ),
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       ),
                                  //     );
                                  //   },
                                  // )
                                  )),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String? getThumbnail(imagePath) {
    VideoThumbnail.thumbnailFile(
      video: imagePath,
      imageFormat: ImageFormat.JPEG,
      maxWidth:
          128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: 25,
    ).then((value) {
      return value;
    });
    return null;
  }
}
