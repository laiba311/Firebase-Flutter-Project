import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/models/post_model.dart';
import 'package:finalfashiontimefrontend/screens/highlights/create_highlights.dart';
import 'package:finalfashiontimefrontend/screens/highlights/highlight_detail.dart';
import 'package:finalfashiontimefrontend/screens/post_scroll_to_next/PostScrollToNext.dart';
import 'package:finalfashiontimefrontend/screens/post_scroll_to_next/PostToMedals.dart';
import 'package:finalfashiontimefrontend/screens/post_scroll_to_next/PostToStar.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/my_posts.dart';
import 'package:finalfashiontimefrontend/screens/profiles/edit_profile.dart';
import 'package:finalfashiontimefrontend/screens/reels/my_reel_interface.dart';
import 'package:finalfashiontimefrontend/screens/stories/view_story.dart';
import 'package:finalfashiontimefrontend/screens/users-screen/fans.dart';
import 'package:finalfashiontimefrontend/screens/users-screen/followers_screen.dart';
import 'package:finalfashiontimefrontend/screens/users-screen/my_idols.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../customize_pacages/file_downloader/src/flutter_file_downloader.dart';
import '../../models/saved_post_model.dart';
import '../../models/story_model.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final bool type;
  final Function onNavigate;
  final Function onNavigateWithArgs;
  final Function onNavigateWithArgsForHighlights;
  final Function navigatePostToScrollArguments;
  final Function navigateSavedPostToScrollArguments;
  final Function onNavigateBack;
  const ProfileScreen({Key? key, required this.type, required this.onNavigate, required this.onNavigateWithArgs, required this.onNavigateWithArgsForHighlights, required this.navigatePostToScrollArguments, required this.navigateSavedPostToScrollArguments, required this.onNavigateBack}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool grid = true;
  bool profile = false;
  bool styles = false;
  String id = "";
  String token = "";
  bool loading = false;
  bool loading1 = false;
  bool loading2 = false;
  bool loading3 = false;
  bool loading4=false;
  List<Story>storyList=[];
  Map<String, dynamic> data = {};
  List<SavedPostModel> myPosts = [];
  List<PostModel> commentedPost = [];
  List<PostModel> likedPost = [];
  List<PostModel> eventsPost = [];
  late List<dynamic> BadgeList = [];
  List<Map<String, dynamic>> myBadges = [];
  late List<int> rankingOrders = [];
  List<PostModel> medalPostsModel = [];
  List<String> medalsPosts = [];
  late String lowestRankingOrderDocument = "";
  List<String> mediaLink = [];
  List<String> videoUrls = [];
  int index = 0;
  List<Story> groupedStoriesList = [];
  TextEditingController _highlightNameController = TextEditingController();
  List<int> selectedStories = [];
  late TabController tabController;
  bool isPostHighlight = false;
  List<Map<String,dynamic>> highlights = [];
  bool isLoading = false;
  Map<String, File?> thumbnailCache = {};
  bool showDeleteIcons = false;
  int? _draggedIndex;

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(preferences.getString("fcm_token"));
    print("user id is----->>>${preferences.getString("id")}");
    getBadges();
    getHighlights();
    getProfile();
    getMyPosts();
    getAllStories();
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

  getProfile() {
    https.get(Uri.parse("$serverUrl/user/api/profile/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      print("Profile data ==> ${value.body.toString()}");
      final body = utf8.decode(value.bodyBytes);
      final jsonData = jsonDecode(body);
      setState(() {
        data = jsonData;
        myPosts.clear();
      });
      print("recenct close friend ==> ${data["recent_stories"].any((story) => story["close_friends_only"] == true)}");
    });
  }

  getBadges() {
    https.get(Uri.parse("$serverUrl/user/api/badgehistory/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      print("badge response ==> ${value.body}");
      json.decode(value.body).forEach((e){
        print("badge ==> ${e}");
        setState(() {
          myBadges.add(e);
        });
      });
      print("badge list ==> ${myBadges}");
    });
    // getMyPosts();
  }

  updateProfile(badgeID) {
    https.patch(
      Uri.parse("$serverUrl/user/api/profile/"),
      headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
      },
      body: json.encode({
        "badge": badgeID
      })
    ).then((value) {
       print("Updated");
       Navigator.pop(context);
       getProfile();
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
  unSaveFashion(fashionSaveID) {
    String url = "$serverUrl/fashionSaved/$fashionSaveID/";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: primary,
          content: const Text("Unsave Fashion?",
              style: TextStyle(color: ascent, fontFamily: Poppins)),
          title: const Text("FashionTime",
              style: TextStyle(
                  color: ascent,
                  fontFamily: Poppins,
                  fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
                onPressed: () {
                  try {
                    https.delete(Uri.parse(url), headers: {
                      "Content-Type": "application/json",
                      "Authorization": "Bearer $token"
                    });
                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint(
                        "error received while unsaving fashion ==========>${e.toString()}");
                  }
                },
                icon: const Text("Yes",
                    style: TextStyle(color: ascent, fontFamily: Poppins))),
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Text("No",
                    style: TextStyle(color: ascent, fontFamily: Poppins)))
          ],
        );
      },
    );
  }
  getHighlights(){
    highlights.clear();
    setState(() {
      isLoading = true;
    });
    String url='$serverUrl/highlights/highlights/';
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
  deleteStory(String storyId) {
    var url = "$serverUrl/highlights/highlights/${storyId}/";
    try {
      https.delete(Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          })
          .then((value) {
        if (value.statusCode == 204) {
          debugPrint("highlight deleted by user");
          Navigator.pop(context);
          Fluttertoast.showToast(
              msg: "Highlight deleted", backgroundColor: primary);
          getHighlights();
        } else {
          debugPrint(" ===========> ${value.statusCode}");
        }
      });
    } catch (e) {
      debugPrint("Error received===========>${e.toString()}");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    getCashedData();
  }

  getAllStories() {
    const apiUrl = "$serverUrl/story/my-stories/";
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

          jsonData.forEach((element) {
            final User user = User(
              name: element['user']['name'],
              username: element['user']['username'],
              profileImageUrl: element['user']['pic'] ?? '',
              id: element['user']['id'].toString(),
            );

            // Create a story object for each element
            Story story = Story(
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
            );
            if (mounted) {
              setState(() {
                groupedStoriesList.add(story);
              });
            }
          });
        } else {
          print("Error received while getting all stories =========> ${value.body.toString()}");
        }
      });
    } catch (e) {
      print("Error Story -> ${e.toString()}");
    }
  }
  addHighlight(String title,int id, List<int> stories) {
    const apiUrl = "$serverUrl/highlights/highlights/";
    try {
      https.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "title": title,
          "user_id": id,
          "story_ids": stories
        })
      ).then((value) {
        if (value.statusCode == 201) {
          setState(() {
            isPostHighlight = false;
          });
          Navigator.pop(context);
          Fluttertoast.showToast(
              msg: "Highlight Added", backgroundColor: primary);
        } else {
          setState(() {
            isPostHighlight = false;
          });
          Navigator.pop(context);
          Fluttertoast.showToast(
              msg: "Something went wrong", backgroundColor: primary);
          print("Error received while posting data =========> ${value.body.toString()}");
        }
      });
    } catch (e) {
      setState(() {
        isPostHighlight = false;
      });
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: "Something went wrong", backgroundColor: primary);
      print("Error Story -> ${e.toString()}");
    }
  }
  getMyPosts() {
    myPosts.clear();
    setState(() {
      loading1 = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/fashionSaved/my-saved-fashions/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }).then((value) {
        print("Saved posts => ${jsonDecode(value.body)}");
        if (jsonDecode(value.body).length <= 0) {
          setState(() {
            loading1 = false;
          });
          print("No data");
        } else {
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
                  myPosts.add(SavedPostModel(
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
                      value["myLike"] == null
                          ? "like"
                          : value["myLike"].toString(),
                      value['mySaved']));
                  debugPrint("fashion save id is${value['mySaved']}");
                });
              });
            } else {
              setState(() {
                myPosts.add(SavedPostModel(
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
                    value["myLike"] == null
                        ? "like"
                        : value["myLike"].toString(),
                    value['mySaved']));
                debugPrint("fashion save id is${value['mySaved']}");
              });
            }
          });
        }
      });
      getCommentedPosts();
      //getBadges();
      getBadgesHistory();
      getEventLikedPosts();
      getAllReels();
    } catch (e) {
      setState(() {
        loading1 = false;
      });
      print("Error --> $e");
    }
  }
  Future<void> getAllReels() async {
    String apiUrl = '$serverUrl/fashionReel/my-reels/?id=$id';
    loading4=false;
    try {
      final response = await https.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        reels.clear();
        final dynamic responseData = jsonDecode(response.body);
        if (responseData != null && responseData is Map<String, dynamic>) {
          final List<dynamic> results = responseData['results'] ?? [];

          setState(() {
            reels = List<Map<String, dynamic>>.from(results);
            debugPrint("all reel data ${reels.toString()}");
            debugPrint("reel data length ${reels.length}");
            setState(() {
              loading4=false;
            });
          });
          for (var result in results) {
            var upload = result['upload'];
            var media = upload != null ? (upload['media'] as List<dynamic>) : null;
            if (media != null && media.isNotEmpty) {
              var videoUrl = media.first['video'];
              String? videoThumbnail = await VideoThumbnail.thumbnailFile(
                video: videoUrl,
                imageFormat: ImageFormat.JPEG,
                maxWidth: 128,
                quality: 25,
              );
              if (videoUrl != null && videoUrl is String) {
                videoUrls.add(videoThumbnail!);
                debugPrint("Video URLs: $videoUrls");
              }
            }
          }
          debugPrint("Video URLs: length ${videoUrls.length}");
          setState(() {

          });

          final dynamic nextUrl = responseData['next'];
          if (nextUrl != null) {
            pageNumber++;
          }
          else{
          }
        } else {
          debugPrint("Unexpected data format or null value: $responseData");
        }
      } else {
        debugPrint('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error loading data: $error');
    }
  }
  getPostsWithMedal() {
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/fashionUpload/top-trending/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        mediaLink.clear();
        medalsPosts.clear();
        print("Timer ==> ${jsonDecode(value.body)}");
        setState(() {
          //myDuration = Duration(seconds: int.parse(jsonDecode(value.body)["result"]["time_remaining"].));
          loading = false;
        });

        jsonDecode(value.body)["result"].forEach((value) {
          if (value['user']['id'].toString() == id.toString()) {
            print("condition is true");
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
                     {},
                    {}
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
                    {},
                  {}
                ));
              });
              mediaLink.add(value['upload']['media'][0]['image'].toString());
              print("imageslinks is ${mediaLink.toString()}");
              print("current user data is ${medalPostsModel.toString()}");
            }
          } else {
            print("id mismatch");
          }
        });
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  getCommentedPosts() {
    commentedPost.clear();
    setState(() {
      loading2 = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/fashionComments/my-commented-fashions/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }).then((value) {
        print("Commented post ==> ${jsonDecode(value.body).length}");
        setState(() {
          loading2 = false;
        });
        jsonDecode(value.body).forEach((value) {
          if (value["upload"]["media"][0]["type"] == "video") {
            VideoThumbnail.thumbnailFile(
              video: value["upload"]["media"][0]["video"],
              imageFormat: ImageFormat.JPEG,
              maxWidth:
                  128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
              quality: 25,
            ).then((value1) {
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
                    value["created"],
                    value1!,
                    value["user"]["id"].toString(),
                    value["myLike"] == null
                        ? "like"
                        : value["myLike"].toString(),
                    {},
                  {}
                ));
              });
            });
          } else {
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
                  value["created"],
                  "",
                  value["user"]["id"].toString(),
                  value["myLike"] == null
                      ? "like"
                      : value["myLike"].toString(),
                  {},
                {}
              ));
            });
          }
        });
      });
      getLikedPosts();
    } catch (e) {
      setState(() {
        loading2 = false;
      });
      print("Error --> $e");
    }
  }
  getLikedPosts() {
    likedPost.clear();
    setState(() {
      loading3 = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/fashionLikes/my-liked-fashions/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }).then((value) {
        print("Star Post ==> ${jsonDecode(value.body)}");
        setState(() {
          loading3 = false;
        });
        jsonDecode(value.body).forEach((value) {
          if (value["upload"]["media"][0]["type"] == "video") {
            VideoThumbnail.thumbnailFile(
              video: value["upload"]["media"][0]["video"],
              imageFormat: ImageFormat.JPEG,
              maxWidth:
                  128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
              quality: 25,
            ).then((value1) {
              if(value["addMeInWeekFashion"] == false) {
                setState(() {
                  likedPost.add(PostModel(
                      value["id"].toString(),
                      value["description"],
                      value["upload"]["media"],
                      value["user"]["name"],
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
                      {},
                      {}
                  ));
                });
              }
            });
          } else {
            if(value["addMeInWeekFashion"] == false) {
              setState(() {
                likedPost.add(PostModel(
                    value["id"].toString(),
                    value["description"],
                    value["upload"]["media"],
                    value["user"]["name"],
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
                    {},
                    {}
                ));
              });
            }
          }
        });
      });
    } catch (e) {
      setState(() {
        loading3 = false;
      });
      print("Error --> $e");
    }
  }
  getEventLikedPosts() {
    eventsPost.clear();
    setState(() {
      loading3 = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/fashionLikes/my-liked-fashions/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }).then((value) {
        print("Star Post ==> ${jsonDecode(value.body)}");
        setState(() {
          loading3 = false;
        });
        jsonDecode(value.body).forEach((value) {
          if (value["upload"]["media"][0]["type"] == "video") {
            VideoThumbnail.thumbnailFile(
              video: value["upload"]["media"][0]["video"],
              imageFormat: ImageFormat.JPEG,
              maxWidth:
              128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
              quality: 25,
            ).then((value1) {
              if(value["addMeInWeekFashion"] == true) {
                setState(() {
                  eventsPost.add(PostModel(
                      value["id"].toString(),
                      value["description"],
                      value["upload"]["media"],
                      value["user"]["name"],
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
                      {},
                      {}
                  ));
                });
              }
            });
          } else {
            if(value["addMeInWeekFashion"] == true) {
              setState(() {
                eventsPost.add(PostModel(
                    value["id"].toString(),
                    value["description"],
                    value["upload"]["media"],
                    value["user"]["name"],
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
                    {},
                    {}
                ));
              });
            }
          }
        });
      });
    } catch (e) {
      setState(() {
        loading3 = false;
      });
      print("Error --> $e");
    }
  }
  getBadgesHistory() async {
    final response = await https.get(headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }, Uri.parse("$serverUrl/user/api/badgehistory/"));
    if (response.statusCode == 200) {
      List<Map<String, dynamic>> jsonResponse =
          (json.decode(response.body) as List).cast<Map<String, dynamic>>();
      rankingOrders = jsonResponse
          .map<int>((item) => item['badge']['ranking_order'] as int)
          .toList();
      List<Map<String, dynamic>> rankingAndDocuments =
          jsonResponse.map<Map<String, dynamic>>((item) {
        return {
          'ranking_order': item['badge']['ranking_order'] as int,
          'document': item['badge']['document'] as String,
        };
      }).toList();

      // Find the item with the lowest ranking order
      Map<String, dynamic>? lowestRankingOrderItem = rankingAndDocuments.reduce(
          (min, current) =>
              min['ranking_order'] < current['ranking_order'] ? min : current);

      // Access the document field associated with the lowest ranking order
      lowestRankingOrderDocument =
          lowestRankingOrderItem['document'] as String;

      print('Lowest ranking order document: $lowestRankingOrderDocument');
          print('Ranking Orders: $rankingOrders');
    } else {
      print('Error in badge history: ${response.statusCode}');
    }
  }
  String convertLikes(int likes) {
    if (likes > 999) {
      if (likes < 1000000) {
        return '${(likes / 1000).toStringAsFixed(0)}k';
      } else {
        return '${(likes / 1000000).toStringAsFixed(0)} million';
      }
    } else {
      return likes.toString();
    }
  }
  Future<void> generateAndCacheThumbnail(String videoUrl, String id) async {
    final thumbnail = await VideoThumbnail.thumbnailFile(video: videoUrl);  // Assuming this generates thumbnail
    if (!mounted) return;
    setState(() {
      thumbnailCache[id] = File(thumbnail!);
    });
  }
  void updateHighlightOrder(List highlight) async {
    final List<Map<String, dynamic>> highlightsData = highlight
        .asMap()
        .entries
        .map((entry) => {'id': entry.value["id"], 'order': entry.key})
        .toList();
    print("highlight Data ==> ${highlightsData}");

    final response = await https.post(
      Uri.parse('$serverUrl/highlights/update-highlight-order/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'highlights': highlightsData}),
    );

    if (response.statusCode == 200) {
      print('Order updated successfully');
    } else {
      print('Failed to update order');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        // print("swapping pop");
        widget.onNavigateBack(0);
        return Future.value(false);
      },
      child: Scaffold(
          appBar: widget.type == true
              ? AppBar(
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
                            ])),
                  ),
                  title: const Text(
                    "Profile",
                    style: TextStyle(fontFamily: Poppins),
                  ),
                  actions: const [
                    //IconButton(onPressed: (){}, icon: Icon(Icons.settings))
                  ],
                )
              : null,
          body: data.keys.isEmpty
              ? SpinKitCircle(
                  size: 50,
                  color: primary,
                )
              : RefreshIndicator(
            color: primary,
                onRefresh: () {
                  return getCashedData();
                },
                child: SingleChildScrollView(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 1.5,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          WidgetAnimator(
                            Stack(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    data['badge'] == null
                                        ? GestureDetector(
                                            onTap:(data["recent_stories"].length <= 0) ? (){
                                              print("Pressed profile");
                                            }: (){
                                              print("Stories => ${data["recent_stories"]}");
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                storyList: List<Story>.from(data["recent_stories"].map((e){
                                                  return Story(
                                                      duration: e["time_since_created"],
                                                      url: e["content"],
                                                      type: e["type"],
                                                      user: User(name:e["user"]["name"],username: e['user']['username'],profileImageUrl:e["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*rglk9r*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzMuNjAuMC4w" , id:e["user"]["id"].toString()),
                                                      storyId: e["id"],
                                                      viewed_users: e["viewers"],
                                                      created: e["created_at"],
                                                    close_friends_only: e['close_friends_only'],
                                                      isPrivate: e["is_user_private"],
                                                      fanList: e["fansList"]
                                                  );
                                                })),
                                              ))).then((value){
                                                getBadges();
                                                getHighlights();
                                                getProfile();
                                                getMyPosts();
                                                getAllStories();
                                              });
                                            },
                                            child: CircleAvatar(
                                              backgroundColor: Color(0xFF121212),
                                              radius: 100,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    gradient: (data["recent_stories"].length <= 0) ? LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.topRight,
                                                        stops: const [0.0, 0.7],
                                                        tileMode: TileMode.clamp,
                                                        colors: <Color>[
                                                          Colors.transparent,
                                                          Colors.transparent,
                                                        ]) :(data["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true? LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.topRight,
                                                        stops: const [0.0, 0.7],
                                                        tileMode: TileMode.clamp,
                                                        colors: <Color>[
                                                          Colors.grey,
                                                          Colors.grey,
                                                        ]) :
                                                    (data["recent_stories"].any((story) => story["close_friends_only"] == true) ? LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.topRight,
                                                        stops: const [0.0, 0.7],
                                                        tileMode: TileMode.clamp,
                                                        colors: <Color>[
                                                          Colors.deepPurple,
                                                          Colors.purpleAccent,
                                                        ]):
                                                    LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.topRight,
                                                        stops: const [0.0, 0.7],
                                                        tileMode: TileMode.clamp,
                                                        colors: <Color>[
                                                          secondary,
                                                          primary,
                                                        ]))),
                                                    borderRadius: const BorderRadius.all(Radius.circular(120))),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(4),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        color: Color(0xFF121212),
                                                        borderRadius: const BorderRadius.all(Radius.circular(120))
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(3.0),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius.all(Radius.circular(120)),
                                                        child: CachedNetworkImage(
                                                          imageUrl: data["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*rglk9r*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzMuNjAuMC4w",
                                                          imageBuilder:
                                                              (context, imageProvider) =>
                                                                  Container(
                                                            height: MediaQuery.of(context)
                                                                    .size
                                                                    .height *
                                                                0.7,
                                                            width: MediaQuery.of(context)
                                                                .size
                                                                .width,
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
                                                          errorWidget: (context, url,
                                                                  error) =>
                                                              ClipRRect(
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                              .all(
                                                                          Radius.circular(
                                                                              50)),
                                                                  child: Image.network(
                                                                    "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                    width: MediaQuery.of(
                                                                                context)
                                                                            .size
                                                                            .width *
                                                                        0.9,
                                                                    height: MediaQuery.of(
                                                                                context)
                                                                            .size
                                                                            .height *
                                                                        0.9,
                                                                  )),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        )
                                        : GestureDetector(
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
                                                ))).then((value){
                                                  getBadges();
                                                  getHighlights();
                                                  getProfile();
                                                  getMyPosts();
                                                  getAllStories();
                                                });
                                              },
                                            child: CircleAvatar(
                                              backgroundColor: Color(0xFF121212),
                                              radius: 100,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    gradient: data["recent_stories"].length > 0 ?
                                                    (data["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ?LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.topRight,
                                                        stops: const [0.0, 0.7],
                                                        tileMode: TileMode.clamp,
                                                        colors: <Color>[
                                                          Colors.grey,
                                                          Colors.grey,
                                                        ]):
                                                    (data["recent_stories"].any((story) => story["close_friends_only"] == true) ? LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.topRight,
                                                        stops: const [0.0, 0.7],
                                                        tileMode: TileMode.clamp,
                                                        colors: <Color>[
                                                          Colors.deepPurple,
                                                          Colors.purpleAccent,
                                                        ]):
                                                    LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.topRight,
                                                        stops: const [0.0, 0.7],
                                                        tileMode: TileMode.clamp,
                                                        colors: <Color>[
                                                          secondary,
                                                          primary,
                                                        ]))
                                                    )
                                                        :LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.topRight,
                                                        stops: const [0.0, 0.7],
                                                        tileMode: TileMode.clamp,
                                                        colors: <Color>[
                                                          Colors.transparent,
                                                          Colors.transparent,
                                                        ]),
                                                    border: Border.all(
                                                        width:data["recent_stories"].length <= 0 ? 0.5 : 3.5,
                                                        color: (
                                                                data["badge"]
                                                                            ["id"] ==
                                                                        13 ||
                                                                    data["badge"]
                                                                            ["id"] ==
                                                                        14 ||
                                                                    data["badge"]
                                                                            ["id"] ==
                                                                        15 ||
                                                                    data["badge"]
                                                                            ["id"] ==
                                                                        16 ||
                                                                    data["badge"]
                                                                            ["id"] ==
                                                                        17 ||
                                                                    data["badge"]
                                                                            ["id"] ==
                                                                        18 ||
                                                                    data["badge"]
                                                                            ["id"] ==
                                                                        19
                                                            //  rankingOrders.contains(1)==true
                                                            )
                                                            ? Colors.grey
                                                            : data["badge"]["id"] ==
                                                                    12
                                                                ? Colors.orange
                                                                : data['badge']['id'] ==
                                                                        10
                                                                    ? gold
                                                                    : data['badge']['id'] ==
                                                                            11
                                                                        ? silver
                                                                        : Color(0xFF121212)),
                                                    color: Color(0xFF121212),
                                                    borderRadius: const BorderRadius.all(
                                                        Radius.circular(120))),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(4),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        color: Color(0xFF121212),
                                                        borderRadius: const BorderRadius.all(Radius.circular(120))
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(3.0),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius.all(
                                                                Radius.circular(120)),
                                                        child: CachedNetworkImage(
                                                          imageUrl: data["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*rglk9r*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzMuNjAuMC4w",
                                                          imageBuilder:
                                                              (context, imageProvider) =>
                                                                  Container(
                                                            height: MediaQuery.of(context)
                                                                    .size
                                                                    .height *
                                                                0.7,
                                                            width: MediaQuery.of(context)
                                                                .size
                                                                .width,
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
                                                          errorWidget: (context, url,
                                                                  error) =>
                                                              ClipRRect(
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                              .all(
                                                                          Radius.circular(
                                                                              50)),
                                                                  child: Image.network(
                                                                    "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                    width: MediaQuery.of(
                                                                                context)
                                                                            .size
                                                                            .width *
                                                                        0.9,
                                                                    height: MediaQuery.of(
                                                                                context)
                                                                            .size
                                                                            .height *
                                                                        0.9,
                                                                  )),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ),
                                  ],
                                ),
                                data["badge"] == null
                                    ? const SizedBox()
                                    : Positioned(
                                        bottom: 1,
                                        right: 80,
                                        child: GestureDetector(
                                            onTap: () {
                                              print("Select Badges");
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                                  ),
                                                  builder: (context) => Container(
                                                    height: MediaQuery.of(context).size.height * 0.97,
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        SizedBox(height: 10),
                                                        Text("Medals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,fontFamily: Poppins)),
                                                        SizedBox(height: 10),
                                                        Expanded(
                                                          child: GridView.builder(
                                                            physics: NeverScrollableScrollPhysics(),
                                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                              crossAxisCount: 3,
                                                              crossAxisSpacing: 10,
                                                              mainAxisSpacing: 10,
                                                              childAspectRatio: 1,
                                                            ),
                                                            itemCount: myBadges.length,
                                                            itemBuilder: (context, index) {
                                                              //return Text(myBadges[index]["badge"]["document"]);
                                                              return GestureDetector(
                                                                onTap: (){
                                                                  updateProfile(myBadges[index]["badge"]["id"]);
                                                                },
                                                                child: CachedNetworkImage(
                                                                  imageUrl: myBadges[index]["badge"]["document"],
                                                                  //imageUrl: lowestRankingOrderDocument,
                                                                  imageBuilder:
                                                                      (context, imageProvider) =>
                                                                      Container(
                                                                        height: 50,
                                                                        width: 50,
                                                                        decoration: BoxDecoration(
                                                                          image: DecorationImage(
                                                                            image: imageProvider,
                                                                            fit: BoxFit.contain,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                  placeholder: (context, url) =>
                                                                      SpinKitCircle(
                                                                        color: primary,
                                                                        size: 20,
                                                                      ),
                                                                  errorWidget: (context, url,
                                                                      error) =>
                                                                      ClipRRect(
                                                                          child: Image.network(
                                                                            myBadges[index]["badge"]["document"],
                                                                            width: 50,
                                                                            height: 50,
                                                                            fit: BoxFit.contain,
                                                                          )),
                                                                ),
                                                              );
                                                              return Image.network(myBadges[index]["badge"]["document"],height: 50,width: 50,);
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            child:
                                                ClipRRect(
                                              borderRadius: const BorderRadius.all(
                                                  Radius.circular(120)),
                                              child: CachedNetworkImage(
                                                imageUrl: data["badge"]["document"].split("https://fashion-time-backend-e7faf6462502.herokuapp.com")[1],
                                                //imageUrl: lowestRankingOrderDocument,
                                                imageBuilder:
                                                    (context, imageProvider) =>
                                                        Container(
                                                  height: 80,
                                                  width: 80,
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
                                                    SpinKitCircle(
                                                  color: primary,
                                                  size: 20,
                                                ),
                                                errorWidget: (context, url,
                                                        error) =>
                                                    ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius.all(
                                                                Radius.circular(
                                                                    50)),
                                                        child: Image.network(
                                                          data["badge"]["document"],
                                                          width: 80,
                                                          height: 80,
                                                          fit: BoxFit.contain,
                                                        )),
                                              ),
                                            )
                                        )
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          WidgetAnimator(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    //Navigator.push(context, MaterialPageRoute(builder: (context) => StylesScreen()));
                                    // widget.onNavigate(20);
                                    // Navigator.push(
                                    //     context,
                                    //     MaterialPageRoute(
                                    //         builder: (context) =>
                                    //             const MyPostScreen()));
                                  },
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            data["stylesCount"].toString(),
                                            style: const TextStyle(
                                                fontFamily: Poppins),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "Styles",
                                            style: TextStyle(
                                                color: primary,
                                                fontFamily: Poppins),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    widget.onNavigate(21);
                                    // Navigator.push(
                                    //     context,
                                    //     MaterialPageRoute(
                                    //         builder: (context) =>
                                    //             const FanScreen())).then((value){
                                    //    getProfile();
                                    // });
                                  },
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            data['fansCount'].toString(),
                                            style: const TextStyle(
                                                fontFamily: Poppins),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "Fans",
                                            style: TextStyle(
                                                color: primary,
                                                fontFamily: Poppins),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    //Navigator.push(context, MaterialPageRoute(builder: (context) => StylesScreen()));
                                    widget.onNavigate(22);
                                     // Navigator.push(context, MaterialPageRoute(builder: (context) => const MyIdols())).then((value){
                                     //   getProfile();
                                     // });
                                  },
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            data["idolsCount"].toString(),
                                            style:
                                                const TextStyle(fontFamily: Poppins),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "Idols",
                                            style: TextStyle(
                                                color: primary,
                                                fontFamily: Poppins),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    widget.onNavigateWithArgs(26,data["followList"]);
                                    // Navigator.push(
                                    //     context,
                                    //     MaterialPageRoute(
                                    //         builder: (context) =>
                                    //             FollowerScreen(
                                    //               followers: data["followList"],
                                    //             ))).then((value){
                                    //   getProfile();
                                    // });
                                  },
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            data["friendsCount"].toString(),
                                            style: const TextStyle(
                                                fontFamily: Poppins),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "Friends",
                                            style: TextStyle(
                                                color: primary,
                                                fontFamily: Poppins),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                // GestureDetector(
                                //   onTap: () {
                                //     Navigator.push(
                                //         context,
                                //         MaterialPageRoute(
                                //             builder: (context) =>
                                //             const MyHundredLikedPost()));
                                //   },
                                //   child:
                                //   Icon(Icons.history,color: primary,)
                                // ),
                                // GestureDetector(
                                //   onTap: (){
                                //
                                //   },
                                //   child: InkWell(
                                //     onTap: () {
                                //       Navigator.push(context, MaterialPageRoute(builder: (context) => const ReelsInterfaceScreen(),));
                                //     },
                                //       child: Icon(Icons.video_collection_rounded,color: primary,size: 28,)),
                                //   ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),
                          WidgetAnimator(SizedBox(
                            height: 80,
                            child: WidgetAnimator(Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    widget.onNavigate(19);
                                    // Navigator.push(
                                    //     context,
                                    //     MaterialPageRoute(
                                    //         builder: (context) =>
                                    //             const EditProfile())).then((value) {
                                    //   commentedPost.clear();
                                    //   getProfile();
                                    // });
                                  },
                                  child: Card(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.all(Radius.circular(15))),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 35,
                                      width:
                                          MediaQuery.of(context).size.width * 0.87,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.99],
                                              tileMode: TileMode.clamp,
                                              colors: <Color>[
                                                secondary,
                                                primary,
                                              ]),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(12))),
                                      child: const Text(
                                        'Edit Profile',
                                        style: TextStyle(
                                            color: ascent,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: Poppins),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                          )),
                          const SizedBox(
                            height: 5,
                          ),
                          WidgetAnimator(Container(
                            width: MediaQuery.of(context).size.width * 0.86,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${Uri.decodeComponent(data["name"] ?? "No name")}",
                                  style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: Poppins,
                                      fontSize: 16
                                  ),
                                )
                              ],
                            ),
                          )),
                          const SizedBox(
                            height: 5,
                          ),
                          // WidgetAnimator(
                          //     Row(
                          //       children: [
                          //         SizedBox(width: 25),
                          //         Text("@${data["username"]}", style: TextStyle(
                          //             color: primary,
                          //             fontWeight: FontWeight.bold,
                          //             fontFamily: Poppins
                          //         ),)
                          //       ],
                          //     )
                          // ),
                          data["description"] == null || data["description"] == ""
                              ? const SizedBox()
                              : WidgetAnimator(
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.86,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: MediaQuery.of(context).size.width * 0.86,
                                          child: Text(
                                            Uri.decodeComponent(data["description"]) ?? "No description",
                                            style: const TextStyle(
                                                fontFamily: 'Arial',
                                              fontSize: 16
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          const SizedBox(
                            height: 25,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.86,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text("Highlights",style: TextStyle(fontFamily: Poppins),),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          highlights.length > 0 ? Container(
                            height: 100,
                          //  width: MediaQuery.of(context).size.width,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(width:MediaQuery.of(context).size.width * 0.07),
                                    GestureDetector(
                                      onTap: (){
                                        widget.onNavigateWithArgsForHighlights(27,groupedStoriesList);
                                        // Navigator.push(context, MaterialPageRoute(builder: (context) => CreateHightlights(
                                        //   groupedStoriesList: groupedStoriesList,
                                        //   id: id,
                                        //   token: token,
                                        // ))).then((value){
                                        //   getHighlights();
                                        // });
                                      },
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(80)),
                                                color: Colors.black12,
                                                border: Border.all(
                                                    color: Colors.grey
                                                )
                                            ),
                                            child: Icon(Icons.add,color: Colors.grey,),
                                          ),
                                          SizedBox(height: 5,),
                                          Row(
                                            children: [
                                              Text("New",style: TextStyle(color: Colors.white,fontSize: 12,fontFamily: Poppins),)
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 15,),
                                    isLoading == true
                                        ? SpinKitCircle(color: primary, size: 20,)
                                        : Container(
                                          height: 100,
                                          //width: MediaQuery.of(context).size.width,
                                          child: ReorderableListView(
                                            shrinkWrap: true,
                                            physics: NeverScrollableScrollPhysics(),
                                            scrollDirection: Axis.horizontal,
                                            proxyDecorator: (Widget child, int index, Animation<double> animation) {
                                              // You can return the original child widget without any additional styling
                                              return child; // This removes the default card-like behavior.
                                            },
                                      onReorder: (int oldIndex, int newIndex) {
                                          if (newIndex > oldIndex) newIndex -= 1;
                                          setState(() {
                                            final item = highlights.removeAt(oldIndex);
                                            highlights.insert(newIndex, item);
                                          });
                                          updateHighlightOrder(highlights);
                                      },
                                      children: highlights.map((e) {
                                          // int index = entry.key;
                                          // var e = entry.value;
                                          int index = highlights.indexOf(e);
                                          final isDragging = _draggedIndex == index;


                                          if (e["stories"][0]["type"] == "video" && thumbnailCache[e["id"]] == null) {
                                            generateAndCacheThumbnail(e["stories"][0]["content"], e["id"].toString());
                                          }

                                          return Padding(
                                            key: ValueKey(e["id"]),
                                            padding: const EdgeInsets.only(right: 15.0),
                                            child: GestureDetector(
                                              onTap: e["stories"].isEmpty
                                                  ? () {}
                                                  : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => HighlightViewScreen(
                                                      storyList: e["stories"],
                                                      highlightId: e["id"].toString(),
                                                      highlightname: e["title"],
                                                      time: e["time_since_created"],
                                                    ),
                                                  ),
                                                ).then((value) {
                                                  getHighlights();
                                                });
                                              },
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Stack(
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                      e["stories"][0]["type"] == "video"
                                                          ? Container(
                                                        height: 60,
                                                        width: 60,
                                                        decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.all(Radius.circular(80)),
                                                            border: Border.all(color: primary, width: 2),
                                                            gradient: LinearGradient(
                                                                begin: Alignment.topLeft,
                                                                end: Alignment.topRight,
                                                                stops: const [0.0, 0.7],
                                                                tileMode: TileMode.clamp,
                                                                colors: <Color>[
                                                                  secondary,
                                                                  primary,
                                                                ])),
                                                        child: thumbnailCache[e["id"]] == null
                                                            ? Text("")
                                                            : Container(
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.all(Radius.circular(80)),
                                                            color: Colors.black54,
                                                            image: DecorationImage(
                                                                image: FileImage(thumbnailCache[e["id"]]!),
                                                                fit: BoxFit.cover),
                                                          ),
                                                          width: 40,
                                                          child: Text(""),
                                                        ),
                                                      )
                                                          : Container(
                                                        height: 60,
                                                        width: 60,
                                                        decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.all(Radius.circular(80)),
                                                            border: Border.all(color: primary, width: 2),
                                                            gradient: LinearGradient(
                                                                begin: Alignment.topLeft,
                                                                end: Alignment.topRight,
                                                                stops: const [0.0, 0.7],
                                                                tileMode: TileMode.clamp,
                                                                colors: <Color>[
                                                                  secondary,
                                                                  primary,
                                                                ])),
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.all(Radius.circular(80)),
                                                            color: Colors.black54,
                                                            image: e["stories"][0]["type"] == "image"
                                                                ? DecorationImage(
                                                                image: NetworkImage(e["stories"][0]["content"]),
                                                                fit: BoxFit.cover)
                                                                : null,
                                                          ),
                                                          width: 40,
                                                          child: e["stories"][0]["type"] == "image"
                                                              ? Text("")
                                                              : Center(
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(8.0),
                                                              child: Text(
                                                                e["stories"][0]["content"],
                                                                textAlign: TextAlign.center,
                                                                style: TextStyle(fontSize: 8, fontFamily: Poppins),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        bottom: -15,
                                                        right: -15,
                                                        child: Material(
                                                          color: Colors.transparent,
                                                          child: IconButton(
                                                            icon: Icon(Icons.delete, color: Colors.red,size: 20,),
                                                            onPressed: () {
                                                              showDialog(
                                                                context: context,
                                                                builder: (context) => AlertDialog(
                                                                  backgroundColor: primary,
                                                                  title: Text(
                                                                    "FashionTime",
                                                                    style: TextStyle(
                                                                        color: ascent,
                                                                        fontFamily: Poppins,
                                                                        fontWeight: FontWeight.bold),
                                                                  ),
                                                                  content: Text(
                                                                    "Do you want to remove highlight",
                                                                    style: TextStyle(color: ascent, fontFamily: Poppins),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      child: Text("Yes",
                                                                          style: TextStyle(
                                                                              color: ascent, fontFamily: Poppins)),
                                                                      onPressed: () {
                                                                        deleteStory(e["id"].toString());
                                                                      },
                                                                    ),
                                                                    TextButton(
                                                                      child: Text("No",
                                                                          style: TextStyle(
                                                                              color: ascent, fontFamily: Poppins)),
                                                                      onPressed: () {
                                                                        Navigator.pop(context);
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 5,),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text("${e["title"]}", style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: Poppins),)
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                      }).toList(),
                                    ),
                                        ),
                                  ],
                                ),
                              ],
                            ),
                          ):Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width:MediaQuery.of(context).size.width * 0.07),
                              GestureDetector(
                                onTap: (){
                                  widget.onNavigateWithArgsForHighlights(27,groupedStoriesList);
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => CreateHightlights(
                                  //     groupedStoriesList: groupedStoriesList,
                                  //     id: id,
                                  //     token: token,
                                  // ))).then((value){
                                  //   getHighlights();
                                  // });
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(80)),
                                          color: Colors.black12,
                                          border: Border.all(
                                              color: Colors.grey
                                          )
                                      ),
                                      child: Icon(Icons.add,color: Colors.grey,),
                                    ),
                                    SizedBox(height: 5,),
                                    Row(
                                      children: [
                                        Text("New",style: TextStyle(color: Colors.white,fontSize: 12,fontFamily: Poppins),)
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 25,),
                          SizedBox(
                            height: 50,
                            child: TabBar(
                              labelColor: ascent,
                              indicatorColor: primary,
                              controller: tabController,
                              tabs: [
                                Tab(
                                    icon: Icon(Icons.star_border_purple500_outlined,
                                        color: _getTabIconColor(context))),
                                Tab(
                                  icon: ColorFiltered(
                                    colorFilter: _getImageColorFilter(context),
                                    child:
                                        Image.asset('assets/bagde.png', height: 28),
                                  ),
                                ),
                                Tab(
                                  icon: ColorFiltered(
                                    colorFilter: _getImageColorFilter(context),
                                    child:
                                    Image.asset('assets/flicksProfileIcon.png', height: 28),
                                  ),
                                ),
                                Tab(
                                  icon: ColorFiltered(
                                    colorFilter: _getImageColorFilter(context),
                                    child:
                                    Image.asset('assets/Frame1.png', height: 28),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                              child: GridTab(
                            tabController: tabController,
                            loading1: loading1,
                            myPosts: myPosts,
                            loading2: loading2,
                            commentedPost: commentedPost,
                            loading3: loading3,
                            likedPost: likedPost,
                            badges: mediaLink,
                            unsaveFashion: unSaveFashion,
                                loading4: loading4,
                                flicks:videoUrls,
                                  getMyPosts:getMyPosts,
                                medalsPosts: eventsPost,
                                getMedalsPosts: getEventLikedPosts,
                                getLikePosts: getLikedPosts,
                                  navigatePostToScrollArguments: widget.navigatePostToScrollArguments,
                                  navigateSavedPostToScrollArguments: widget.navigateSavedPostToScrollArguments,

                          )),
                        ],
                      ),
                    ),
                  ),
              )),
    );
  }
}

class StoryCard extends StatelessWidget {
  final Story story;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  StoryCard({
    required this.story,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: Stack(
        children: [
          // Story display based on type
          Card(
            elevation: 5,
            child: _getStoryContent(story),
          ),
          // Checkbox overlay
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Checkbox(
                activeColor: primary,
                checkColor: ascent,
                value: isSelected,
                onChanged: (value) => onSelected(value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get appropriate story content widget based on the story type
  Widget _getStoryContent(Story story) {
    switch (story.type) {
      case 'text':
        return _buildTextStory(story);
      case 'image':
        return _buildImageStory(story);
      case 'video':
        return _buildVideoStory(story);
      default:
        return Center(child: Text('Unsupported story type',style: TextStyle(fontFamily: Poppins),));
    }
  }

  // Widget for text stories
  Widget _buildTextStory(Story story) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                story.url,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,fontFamily: Poppins),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for image stories
  Widget _buildImageStory(Story story) {
    return Column(
      children: [
        Expanded(
          child: Image.network(
            story.url,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  // Widget for video stories
  Widget _buildVideoStory(Story story) {
    return VideoStoryCard(story: story);
  }
}

// Separate Video Story widget
class VideoStoryCard extends StatefulWidget {
  final Story story;

  VideoStoryCard({required this.story});

  @override
  _VideoStoryCardState createState() => _VideoStoryCardState();
}

class _VideoStoryCardState extends State<VideoStoryCard> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.story.url)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : Center(child: CircularProgressIndicator()),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

class GridTab extends StatelessWidget {
  const GridTab(
      {super.key,
      required this.tabController,
      required this.loading1,
      required this.myPosts,
      required this.loading2,
      required this.commentedPost,
      required this.loading3,
      required this.likedPost,
      required this.badges,
      required this.unsaveFashion, required this.loading4, required this.flicks,
      required this.getMyPosts, required this.medalsPosts, required this.getMedalsPosts, required this.getLikePosts,
      required this.navigatePostToScrollArguments, required this.navigateSavedPostToScrollArguments
      });

  final TabController tabController;
  final bool loading1;
  final List<SavedPostModel> myPosts;
  final bool loading2;
  final List<PostModel> commentedPost;
  final bool loading3;
  final List<PostModel> likedPost;
  final List<String> badges;
  final Function unsaveFashion;
  final bool loading4;
  final List<String> flicks;
  final List<PostModel> medalsPosts;
  final Function getMedalsPosts;
  final Function getMyPosts;
  final Function getLikePosts;
  final Function navigatePostToScrollArguments;
  final Function navigateSavedPostToScrollArguments;

  @override
  Widget build(BuildContext context) {
    Color getTabIconColor(BuildContext context) {
      bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

      return isDarkMode ? Colors.white : primary;
    }

    return TabBarView(
      controller: tabController,
      children: <Widget>[
        loading1 == true
            ? SpinKitCircle(
                color: primary,
                size: 50,
              )
            : (likedPost.isEmpty
                ? Column(
                    children: [
                      SizedBox(
                        height: 40,
                      ),
                      Text(
                        "No Starposts",
                        style: TextStyle(fontFamily: Poppins),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: likedPost.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        // mainAxisSpacing: 10
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        return WidgetAnimator(
                          GestureDetector(
                          onLongPress: () {
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
                                  "Do you want to download this media?",
                                  style: TextStyle(color: ascent, fontFamily: Poppins),
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text("Yes",
                                        style: TextStyle(
                                            color: ascent, fontFamily: Poppins)),
                                    onPressed: () {
                                      FileDownloader.downloadFile(
                                        url: likedPost[index].toString(),
                                        name: likedPost[index].toString(),
                                        onDownloadCompleted: (String path) {
                                          debugPrint('IMAGE DOWNLOADED TO PATH: $path');
                                          Fluttertoast.showToast(msg: "File downloaded at $path",backgroundColor: primary);
                                        },
                                        onDownloadError: (String error) {
                                          debugPrint('DOWNLOAD ERROR: $error');
                                          Fluttertoast.showToast(msg: "Error while downloading file",backgroundColor:Colors.red);
                                        },
                                      );
                                      Navigator.pop(context);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text("No",
                                        style: TextStyle(
                                            color: ascent, fontFamily: Poppins)),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );

                          },
                            onTap: () {
                              // likedPost.insert(0,likedPost[index]);
                              // likedPost.removeAt(index);
                              // navigatePostToScrollArguments(33,"Star Posts",likedPost,index);
                              // myPosts.indexOf((e) => e.userid == myPosts[index].userid)
                              // var list = myPosts.insert(0, myPosts[myPosts.indexOf((e) => e.userid == myPosts[index].userid)]);
                              // debugPrint("style clicked");
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => PostScrollToStar(
                              //     title: "Starposts",
                              //     posts: likedPost,
                              //     index: index
                              // ),)).then((value){
                              //   getLikePosts();
                              // });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Stack(
                                children: [
                                  Container(
                                    child: likedPost[index].images[0]
                                                ["type"] ==
                                            "video"
                                        ? Container(
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  fit: BoxFit.cover,
                                                  image: FileImage(File(
                                                      likedPost[index]
                                                          .thumbnail))),
                                              //borderRadius: BorderRadius.all(Radius.circular(10)),
                                            ),
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: likedPost[index]
                                                .images[0]["image"],
                                            height: 820,
                                            width: 200,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Center(
                                              child: SizedBox(
                                                width: 20.0,
                                                height: 20.0,
                                                child: SpinKitCircle(
                                                  color: primary,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.84,
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image: Image.network(
                                                            "https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                                                        .image,
                                                    fit: BoxFit.cover),
                                              ),
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                      right: 10,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: likedPost[index].images[0]
                                                    ["type"] ==
                                                "video"
                                            ? const Icon(
                                                Icons.video_camera_back)
                                            : const Icon(Icons.image),
                                      ))
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )),
        loading3 == true
            ? SpinKitCircle(
                color: primary,
                size: 50,
              )
            : (badges.isEmpty
                ? Column(
                    children: [
                      SizedBox(
                        height: 40,
                      ),
                      Text(
                        "No Eventposts",
                        style: TextStyle(fontFamily: Poppins),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: badges.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        // mainAxisSpacing: 10
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        return WidgetAnimator(
                          GestureDetector(
                            onLongPress: () {
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
                                    "Do you want to download this media?",
                                    style: TextStyle(color: ascent, fontFamily: Poppins),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text("Yes",
                                          style: TextStyle(
                                              color: ascent, fontFamily: Poppins)),
                                      onPressed: () {
                                        FileDownloader.downloadFile(
                                          url: badges[index].toString(),
                                          name: badges[index].toString(),
                                          onDownloadCompleted: (String path) {
                                            debugPrint('IMAGE DOWNLOADED TO PATH: $path');
                                            Fluttertoast.showToast(msg: "File downloaded at $path",backgroundColor: primary);
                                          },
                                          onDownloadError: (String error) {
                                            debugPrint('DOWNLOAD ERROR: $error');
                                            Fluttertoast.showToast(msg: "Error while downloading file",backgroundColor:Colors.red);
                                          },
                                        );
                                        Navigator.pop(context);
                                      },
                                    ),
                                    TextButton(
                                      child: const Text("No",
                                          style: TextStyle(
                                              color: ascent, fontFamily: Poppins)),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                            onTap: () {
                              // medalsPosts.insert(0,medalsPosts[index]);
                              // medalsPosts.removeAt(index);
                              // navigatePostToScrollArguments(32,"Medals Posts",medalsPosts,index);
                              // myPosts.indexOf((e) => e.userid == myPosts[index].userid)
                              // var list = myPosts.insert(0, myPosts[myPosts.indexOf((e) => e.userid == myPosts[index].userid)]);
                              // debugPrint("style clicked");
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => PostScrollToMedals(
                              //     title: "Medals Posts",
                              //     posts: medalsPosts,
                              //     index: index
                              // ),)).then((value){
                              //   getMedalsPosts();
                              // });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                        // borderRadius: BorderRadius.all(Radius.circular(10)),
                                        ),
                                    child: badges.isNotEmpty
                                        ? Container(
                                            height: 120,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                fit: BoxFit.fill,
                                                image:
                                                    NetworkImage(badges[index]),
                                              ),
                                              //borderRadius: BorderRadius.all(Radius.circular(10)),
                                            ),
                                          )
                                        : CachedNetworkImage(
                                            imageUrl:
                                                'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png',
                                            fit: BoxFit.cover,
                                            height: 820,
                                            width: 200,
                                            placeholder: (context, url) =>
                                                Center(
                                              child: SizedBox(
                                                width: 20.0,
                                                height: 20.0,
                                                child: SpinKitCircle(
                                                  color: primary,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.84,
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image: Image.network(
                                                            "https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                                                        .image,
                                                    fit: BoxFit.cover),
                                              ),
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                      right: 10,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Image.asset(
                                          'assets/bagde.png',
                                          height: 28,
                                          color: getTabIconColor(context),
                                        ),
                                      ))
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
            ),
        loading4 == true
            ? SpinKitCircle(color: primary)
            : flicks.isEmpty
            ? Column(
          children: [
            SizedBox(
              height: 40,
            ),
            Text(
              "No Flicks",
              style: TextStyle(fontFamily: Poppins),
              textAlign: TextAlign.center,
            ),
          ],
        )
            : SingleChildScrollView(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: flicks.length,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              // mainAxisSpacing: 10
            ),
            itemBuilder: (BuildContext context, int index) {
              return WidgetAnimator(
                GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const MyReelsInterfaceScreen()));
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              // borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child:  Container(
                              height: 120,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image:
                                  // NetworkImage( flicks[index]),
                                  FileImage(File(flicks[index]))
                                ),
                              ),
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        loading2 == true
            ? Column(
              children: [
                const SizedBox(
                  height: 40,
                ),
                SpinKitCircle(
          color: primary,
          size: 50,
        ),
              ],
            )
            : (myPosts.isEmpty
            ?  Column(
          children: [
            SizedBox(
              height: 40,
            ),
            Text(
              "No Styles",
              style: TextStyle(fontFamily: Poppins),
              textAlign: TextAlign.center,
            ),
          ],
        )
            : SingleChildScrollView(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: myPosts.length,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              //mainAxisSpacing: 10
            ),
            itemBuilder: (BuildContext context, int index) {
              return WidgetAnimator(
                GestureDetector(
                  onTap: () {
                    // myPosts.insert(0,myPosts[index]);
                    // myPosts.removeAt(index);
                    // navigateSavedPostToScrollArguments(34,"Saved Styles",myPosts,index);
                    // myPosts.indexOf((e) => e.userid == myPosts[index].userid)
                    // var list = myPosts.insert(0, myPosts[myPosts.indexOf((e) => e.userid == myPosts[index].userid)]);
                    // debugPrint("style clicked");
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => PostScrollToNext(
                    //   title: "Saved Styles",
                    //   posts: myPosts,
                    //   index: index
                    // ),)).then((value){
                    //   getMyPosts();
                    // });
                  },
                  onLongPress: () {
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
                          "Do you want to download this media?",
                          style: TextStyle(color: ascent, fontFamily: Poppins),
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Yes",
                                style: TextStyle(
                                    color: ascent, fontFamily: Poppins)),
                            onPressed: () {
                              FileDownloader.downloadFile(
                                url: myPosts[index].toString(),
                                name: myPosts[index].toString(),
                                onDownloadCompleted: (String path) {
                                  debugPrint('IMAGE DOWNLOADED TO PATH: $path');
                                  Fluttertoast.showToast(msg: "File downloaded at $path",backgroundColor: primary);
                                },
                                onDownloadError: (String error) {
                                  debugPrint('DOWNLOAD ERROR: $error');
                                  Fluttertoast.showToast(msg: "Error while downloading file",backgroundColor:Colors.red);
                                },
                              );
                              Navigator.pop(context);
                            },
                          ),
                          TextButton(
                            child: const Text("No",
                                style: TextStyle(
                                    color: ascent, fontFamily: Poppins)),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  onDoubleTap: () {
                    unsaveFashion(myPosts[index].saveId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Stack(
                      children: [
                        Container(
                          child: myPosts[index].images[0]["type"] ==
                              "video"
                              ? Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: FileImage(File(
                                      myPosts[index]
                                          .thumbnail))),
                              // borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          )
                              : CachedNetworkImage(
                            imageUrl: myPosts[index].images[0]
                            ["image"],
                            height: 820,
                            width: 200,
                            fit: BoxFit.fill,
                            placeholder: (context, url) =>
                                Center(
                                  child: SizedBox(
                                    width: 20.0,
                                    height: 20.0,
                                    child: SpinKitCircle(
                                      color: primary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                Container(
                                  height: MediaQuery.of(context)
                                      .size
                                      .height *
                                      0.84,
                                  width: MediaQuery.of(context)
                                      .size
                                      .width,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: Image.network(
                                            "https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                                            .image,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                          ),
                        ),
                        Positioned(
                            right: 10,
                            child: Padding(
                              padding:
                              const EdgeInsets.only(top: 8.0),
                              child: myPosts[index].images[0]
                              ["type"] ==
                                  "video"
                                  ? const Icon(
                                  Icons.video_camera_back)
                                  : const Icon(Icons.image),
                            ))
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        )),
      ],
    );
  }
}
