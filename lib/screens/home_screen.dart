import 'dart:convert';
import 'dart:io';
import 'package:finalfashiontimefrontend/models/post_model.dart';
import 'package:finalfashiontimefrontend/models/saved_post_model.dart';
import 'package:finalfashiontimefrontend/models/story_model.dart';
import 'package:finalfashiontimefrontend/models/swap_model.dart';
import 'package:finalfashiontimefrontend/screens/appbar-pages/New_calender_screen.dart';
import 'package:finalfashiontimefrontend/screens/appbar-pages/hundred_posts.dart';
import 'package:finalfashiontimefrontend/screens/appbar-pages/searches/search_user.dart';
import 'package:finalfashiontimefrontend/screens/appbar-pages/searches/userSearchHistory.dart';
import 'package:finalfashiontimefrontend/screens/appbar-pages/warning_page.dart';
import 'package:finalfashiontimefrontend/screens/authentication/login_screen.dart';
import 'package:finalfashiontimefrontend/screens/call-screens/start_call.dart';
import 'package:finalfashiontimefrontend/screens/filter-screens/filter_screen.dart';
import 'package:finalfashiontimefrontend/screens/filter-screens/filter_top_trending.dart';
import 'package:finalfashiontimefrontend/screens/groups/add_group.dart';
import 'package:finalfashiontimefrontend/screens/groups/all_groups.dart';
import 'package:finalfashiontimefrontend/screens/groups/search_friend.dart';
import 'package:finalfashiontimefrontend/screens/highlights/create_highlights.dart';
import 'package:finalfashiontimefrontend/screens/pages/camera_screen.dart';
import 'package:finalfashiontimefrontend/screens/pages/chat_screen.dart';
import 'package:finalfashiontimefrontend/screens/pages/feed_screen.dart';
import 'package:finalfashiontimefrontend/screens/pages/home_feed.dart';
import 'package:finalfashiontimefrontend/screens/pages/profile_screen.dart';
import 'package:finalfashiontimefrontend/screens/pages/reelsInterface.dart';
import 'package:finalfashiontimefrontend/screens/pages/swapping_screen.dart';
import 'package:finalfashiontimefrontend/screens/post_scroll_to_next/PostScrollToNext.dart';
import 'package:finalfashiontimefrontend/screens/post_scroll_to_next/PostToMedals.dart';
import 'package:finalfashiontimefrontend/screens/post_scroll_to_next/PostToStar.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/my_posts.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/post_like_user.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/swap_detail.dart';
import 'package:finalfashiontimefrontend/screens/profiles/edit_profile.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/reels/createReel.dart';
import 'package:finalfashiontimefrontend/screens/reels/report_reel.dart';
import 'package:finalfashiontimefrontend/screens/search-screens/search_by_hashtag.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/add_chat_screen.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/contact_screen.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/friend_request.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/notification.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/personal_setting.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/privacy_screen.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/report_screen.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/securit_tab.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/story_settings.dart';
import 'package:finalfashiontimefrontend/screens/stories/create_story.dart';
import 'package:finalfashiontimefrontend/screens/stories/hidden_stories.dart';
import 'package:finalfashiontimefrontend/screens/users-screen/fans.dart';
import 'package:finalfashiontimefrontend/screens/users-screen/followers_screen.dart';
import 'package:finalfashiontimefrontend/screens/users-screen/my_idols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import 'package:showcaseview/showcaseview.dart';
import '../utils/constants.dart';
import 'appbar-pages/new_calander_screen2.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;
  List<dynamic> followUserList = [];
  List<Story> groupUsersList = [];
  String reportedID = "";
  String postId = "";
  String friendID = "";
  String friendUsername = "";
  String userid = "";
  List<dynamic> image = [];
  String description = "";
  String createdBy = "";
  String style = "";
  String profile = "";
  String likes = "";
  String dislikes = "";
  String mylike = "";
  bool isPrivate = false;
  List<dynamic> fansList = [];
  List<dynamic> followList = [];
  String swapUsername = "";
  bool? addMeInFashionWeek;
  String reelReportId = "";
  String reelUserId = "";
  List<Map<String,dynamic>> members = [];
  List<String> users = [];

  Color _getTabIconColor(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return isDarkMode ? Colors.white : primary;
  }

  int _selectedIndex = 0;
  int selectedIndex = 0;
  void _onItemTapped(int index) {
    print("_onItemTapped");
    setState(() {
      _selectedIndex = index;
      selectedIndex = index;
      _pageController.jumpToPage(index);
    });
    print("_selectedIndex ${_selectedIndex}");
    print("selectedIndex ${selectedIndex}");
    print("index ${index}");
  }

  void _onItemTapped1(int index) {
    print("_onItemTapped1");
    setState(() {
      _selectedIndex = index;
      selectedIndex = index;
      _pageController.jumpToPage(index);
      print("_selectedIndex ${_selectedIndex}");
      print("selectedIndex ${selectedIndex}");
      print("index ${index}");
    });
  }

  void navigateToPage(int pageIndex) {
    print("navigateToPage");
    setState(() {
       selectedIndex = pageIndex;
      _pageController.jumpToPage(pageIndex);
    });
    print("_selectedIndex ${_selectedIndex}");
    print("selectedIndex ${selectedIndex}");
    print("index ${pageIndex}");
  }

  void navigateToGroup(int pageIndex,List<Map<String,dynamic>> membersData,List<String> usersData) {
    setState(() {
      selectedIndex = pageIndex;
      members = membersData;
      users = usersData;
      _pageController.jumpToPage(pageIndex);
    });
  }

  void navigateToBack(int pageIndex) {
    setState(() {
      _selectedIndex = pageIndex;
      selectedIndex = pageIndex;
      _pageController.jumpToPage(pageIndex);
    });
  }

  void navigateToPageWithArguments(int pageIndex,List<dynamic> followList) {
    if (!mounted) return;
    setState(() {
      followUserList = followList;
      selectedIndex = pageIndex;
      _pageController.jumpToPage(pageIndex);
    });
  }

  void navigateToPageWithArgumentsForHighlights(int pageIndex,List<Story> groupList) {
    setState(() {
      groupUsersList = groupList;
      selectedIndex = pageIndex;
      _pageController.jumpToPage(pageIndex);
    });
  }

  void navigateToPageWithReportArguments(int pageIndex,String args) {
    if (!mounted) return;
    setState(() {
      reportedID = args;
      selectedIndex = pageIndex;
      _pageController.jumpToPage(pageIndex);
    });
  }

  void navigateToPageWithPostArguments(int pageIndex,String args) {
    if (!mounted) return;
    setState(() {
      postId = args;
      selectedIndex = pageIndex;
      _pageController.jumpToPage(pageIndex);
    });
  }

  void navigateToPageWithFriendArguments(int pageIndex,String args,String args1) {
    if (!mounted) return;
    print("friend id => ${friendID}");
    print("friend username => ${friendUsername}");
    setState(() {
      friendID = args;
      friendUsername = args1;
      selectedIndex = pageIndex;
      _pageController.jumpToPage(pageIndex);
    });
  }

  void navigatePostToScrollArguments(int pageIndex,String title,List<PostModel> post,int myIndex) {
    if (!mounted) return;
    setState(() {
      titleStyle = title;
      postsStyle = post;
      indexStyle = myIndex;
      selectedIndex = pageIndex;
      _pageController.jumpToPage(pageIndex);
    });
  }

  void navigateSavedPostToScrollArguments(int pageIndex,String title,List<SavedPostModel> post,int myIndex) {
    if (!mounted) return;
    setState(() {
      titleStyle1 = title;
      postsStyle1 = post;
      indexStyle1 = myIndex;
      selectedIndex = pageIndex;
      _pageController.jumpToPage(pageIndex);
    });
  }

  void navigateSwapArguments(int pageIndex, SwapModel SwapData) {
    if (!mounted) return;
    setState(() {
      userid = SwapData.userid;
      image = SwapData.image;
      description = SwapData.description;
      createdBy = SwapData.createdBy;
      style = SwapData.style;
      profile = SwapData.profile;
      likes = SwapData.likes;
      dislikes = SwapData.dislikes;
      mylike = SwapData.mylike;
      isPrivate = SwapData.isPrivate;
      fansList = SwapData.fansList;
      followList = SwapData.followList;
      swapUsername = SwapData.username;
      addMeInFashionWeek = SwapData.addMeInFashionWeek;
      selectedIndex = pageIndex;
      // _selectedIndex = 35;
      _pageController.jumpToPage(35);
    });
    print("Fashion swap bool ${addMeInFashionWeek!}");
    print("Fashion swap userid ${userid}");
  }

  void navigateToPageWithReelReportArguments(int pageIndex,String args,String args1) {
    if (!mounted) return;
    setState(() {
      reelReportId = args;
      reelUserId = args1;
      selectedIndex = pageIndex;
      _pageController.jumpToPage(pageIndex);
    });
  }


  String id = "";
  String token = "";
  String name = "";
  String username = "";
  bool loading = false;
  String appbarText = "";
  String nextWeekText = "";
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> notifications1 = [];
  List<Map<String, dynamic>> friendRequests = [];
  List<Map<String, dynamic>> fanRequests = [];
  List<Map<String, dynamic>> fanRequestsMessage = [];
  String titleStyle = "";
  List<PostModel>? postsStyle = [];
  int indexStyle = 0;

  String titleStyle1 = "";
  List<SavedPostModel>? postsStyle1 = [];
  int indexStyle1 = 0;
  final PageController _pageController = PageController();
  final Map<int, Widget> _screens = {};
  SwapModel? swaps;

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    name = preferences.getString('name')!;
    username = preferences.getString('username')!;
    print("FCM Token ${preferences.getString("fcm_token")!}");
    print("username of user is $username");
    getNotifications();
    getFriendRequest();
    getFanRequest();
    getFanRequestMessages();
    getAppBarText();
    getNextEvent();
  }

  getAppBarText() async {
    try {
      final response =
      await https.get(Uri.parse("$serverUrl/fashionEvent-week/"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey("current_week_events") &&
            responseData["current_week_events"].isNotEmpty) {
          print("app bar api data ${responseData.toString()}");
          final event = responseData["current_week_events"][0];
          setState(() {
            appbarText = event['title'];
          });
        }
      } else {
        print("Error in app bar api:${response.statusCode}");
      }
    } catch (e) {
      print("api didn't hit $e");
    }
  }

  Future<void> getNextEvent() async {
    try {
      final response = await https.get(Uri.parse(
          "$serverUrl/fashionEvents/")); // Replace with your actual API endpoint
      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> events =
        List<Map<String, dynamic>>.from(jsonDecode(response.body));

        // Get the events for the next week
        DateTime nextWeek = DateTime.now().add(const Duration(days: 7));
        List<Map<String, dynamic>> nextWeekEvents = events
            .where((event) =>
        DateTime.parse(event['eventStartDate'])
            .isAfter(DateTime.now()) &&
            DateTime.parse(event['eventStartDate']).isBefore(nextWeek))
            .toList();

        if (nextWeekEvents.isNotEmpty) {
          final event = nextWeekEvents[0];
          print("Next Event api data ${event.toString()}");
          setState(() {
            nextWeekText = event['title'];
          });
        } else {
          print("No events for the next week");
        }
      } else {
        print("Error in event  api: ${response.statusCode}");
      }
    } catch (e) {
      print("Event API didn't hit $e");
    }
  }

  String formatNotificationCount(int count) {
    if (count > 999) {
      return '1k+';
    } else if (count > 9) {
      return '9+';
    } else {
      return count.toString();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  Widget getScreen(int index) {
    if (!_screens.containsKey(index)) {
      switch (index) {
        case 0:
          _screens[index] = HomeFeedScreen(
            onNavigate: navigateToPageWithReportArguments,
            navigateToPageWithPostArguments: navigateToPageWithPostArguments,
            navigateToPageWithFriendArguments: navigateToPageWithFriendArguments,
            navigate: navigateToPage,
          );
          break;
        case 1:
          _screens[index] = ShowCaseWidget(builder: (context) => SwappingScreen(navigateTo: navigateToBack,myIndex: _selectedIndex,onNavigateBack: _onItemTapped1,));
          break;
        case 2:
          _screens[index] = WillPopScope(
              onWillPop: (){
                print("Chat home list pop");
                _onItemTapped(1);
                return Future.value(false);
              },
              child: ChatScreen(onNavigate: navigateToPage,navigateToGroup:navigateToGroup,onNavigateBack: _onItemTapped1,));
          break;
        case 3:
          _screens[index] = CameraScreen(onNavigateBack: _onItemTapped1);
          break;
        case 4:
          _screens[index] = FeedScreen(onNavigate: navigateToPage,navigatePostToScrollArguments: navigatePostToScrollArguments,navigateSwapArguments:navigateSwapArguments,onNavigateBack: navigateToBack,onNavigateBackOn: _onItemTapped1);
          break;
        case 5:
          _screens[index] = WillPopScope(
            onWillPop: (){
              print("profile home list pop");
              _onItemTapped(4);
              return Future.value(false);
            },
            child: ProfileScreen(
              type: false,
              onNavigate: navigateToPage,
              onNavigateWithArgs: navigateToPageWithArguments,
              onNavigateWithArgsForHighlights: navigateToPageWithArgumentsForHighlights,
              navigatePostToScrollArguments: navigatePostToScrollArguments,
              navigateSavedPostToScrollArguments: navigateSavedPostToScrollArguments,
                onNavigateBack: _onItemTapped1
            ),
          );
          break;
        case 6:
          _screens[index] = ReelsInterfaceScreen(navigateTo: navigateToPage,navigateToPageWithReelReportArguments:navigateToPageWithReelReportArguments,onNavigateBack: _onItemTapped1);
          break;
        case 7:
          _screens[index] = FriendRequest();
          break;
        case 8:
          _screens[index] = HistorySearchScreen(onNavigate: navigateToPage,);
          break;
        case 9:
          _screens[index] = SearchByHashtagScreen(navigateToReport:navigateToPageWithReportArguments,navigateToUserLike: navigateToPageWithPostArguments,);
          break;
        case 10:
          _screens[index] = WarningPage();
          break;
        case 11:
          _screens[index] = NotificationScreen(onNavigateUser: navigateToPageWithFriendArguments,onNavigateBack: navigateToBack,);
          break;
        case 12:
          _screens[index] = AllFashionWeeks(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 13:
          _screens[index] = PrivacyScreen(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 14:
          _screens[index] = ContactScreen(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 15:
          _screens[index] = PersonalSettingScreen(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 16:
          _screens[index] = MyHundredLikedPost(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 17:
          _screens[index] = StorySettings(onNavigate: navigateToPage,navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 18:
          _screens[index] = HiddenStories();
          break;
        case 19:
          _screens[index] = EditProfile(navigateTo: navigateToBack,myIndex: _selectedIndex,);
          break;
        case 20:
          _screens[index] = MyPostScreen(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 21:
          _screens[index] = FanScreen(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 22:
          _screens[index] = MyIdols(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 23:
          _screens[index] = AllGroups(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 24:
          _screens[index] = AddChatScreen(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 25:
          _screens[index] = AddCallScreen(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 26:
          _screens[index] = FollowerScreen(followers: followUserList,navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 27:
          _screens[index] = CreateHightlights(id: id, token: token,navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 28:
          _screens[index] = ReportScreen(reportedID: reportedID);
          break;
        case 29:
          _screens[index] = PostLikeUserScreen(fashionId: postId);
          break;
        case 30:
          //_screens[index] = FriendProfileScreen(id: friendID, username: friendUsername, navigateToPageWithReportArguments: navigateToPageWithReportArguments);
          return FriendProfileScreen(
            id: friendID,
            username: friendUsername,
            navigateToPageWithReportArguments: navigateToPageWithReportArguments,
          );
          // break;
        case 31:
          _screens[index] = UploadStoryScreen();
          break;
        case 32:
          _screens[index] = PostScrollToMedals(title: titleStyle, posts: postsStyle, index: indexStyle,navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 33:
          _screens[index] = PostScrollToStar(title: titleStyle, posts: postsStyle, index: indexStyle,navigateToReportScreen: navigateToPageWithReportArguments,navigateToPageWithPostArguments:navigateToPageWithPostArguments,navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 34:
          _screens[index] = PostScrollToNext(title: titleStyle1, posts: postsStyle1, index: indexStyle1,navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 35:
          _screens[index] = SwapDetail(
            userid: userid,
            image: image,
            description: description,
            style: "Fashion Style 2",
            createdBy: swapUsername,
            profile: profile,
            likes: likes,
            dislikes: dislikes,
            mylike: mylike,
            addMeInFashionWeek: addMeInFashionWeek,
            isPrivate: isPrivate,
            fansList: fansList,
            id: id,
            followList: followList,
            username: swapUsername,
            token: token,
          );
          break;
        case 36:
          _screens[index] = UserSearchHistory();
          break;
        case 37:
          _screens[index] = AddCallScreen(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 38:
          _screens[index] = CreateReelScreen();
          break;
        case 39:
          _screens[index] = ReelReportScreen(reelId: reelReportId,userId: reelUserId,);
          break;
        case 40:
          _screens[index] = AllFashionWeeks1(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 41:
          _screens[index] = SearchFriend(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        case 42:
          _screens[index] = SecurityTab(navigateTo: navigateToBack,myIndex: _selectedIndex);
          break;
        default:
          _screens[index] = const Center(child: Text("Screen Not Found"));
      }
    }
    return _screens[index]!;
  }

  getNotifications() {
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/notificationsApi/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        //print(jsonDecode(value.body).toString());
        jsonDecode(value.body).forEach((data) {
          if (data["is_read"] == false) {
            setState(() {
              notifications.add({
                "title": data["title"].toString(),
                "body": data["body"].toString(),
                "action": data["action"].toString() ?? "",
                "time": data["updated"].toString(),
              });
              notifications1.add({
                "title": data["title"].toString(),
                "body": data["body"].toString(),
                "action": data["action"].toString() ?? "",
                "time": data["updated"].toString(),
              });
            });
          }
        });
        setState(() {
          loading = false;
        });
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  getFriendRequest() {
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/friendrequestnotiApi/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        jsonDecode(value.body).forEach((data) {
          if (data["is_read"] == false &&
              data['title'] == 'New Follow Request') {
            setState(() {
              friendRequests.add({
                "title": data["title"].toString(),
                "body": data["body"].toString(),
                "action": data["action"].toString() ?? "",
                "time": data["updated"].toString(),
              });
            });
          }
        });
        debugPrint("total request =====> ${friendRequests.length}");
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error received========>${e.toString()}");
    }
  }
  initBannerAd() {
    _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: "ca-app-pub-5248449076034001/6687962197",
        listener: BannerAdListener(onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        }, onAdFailedToLoad: (ad, error) {
          //print("${ad.adUnitId} Error ==> ${error.message}");
        }),
        request: const AdRequest());
    _bannerAd.load();
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
          if (data["is_read"] == false) {
            setState(() {
              loading = false;
              fanRequests.add(data);
            });
          }
          print("Requests length => ${fanRequests.length.toString()}");
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
  getFanRequestMessages() {
    fanRequestsMessage.clear();
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/RequestMessage/api/personrequestsmessage/filter/${id}/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {

        jsonDecode(value.body).forEach((data) {
          if (data["is_read"] == false) {
            setState(() {
              loading = false;
              fanRequestsMessage.add(data);
            });
          }
          print("Requests length => ${fanRequestsMessage.length.toString()}");
        });
        setState(() {
          loading=false;
        });
        debugPrint("total request=====>${fanRequestsMessage.length}");
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error received========>${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_pageController.page?.toInt() == 2) {
          // print("");
          // If NOT on the default page, go back to previous page
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0); // Navigate to the desired page
          return Future.value(false);
        }
        else if (_pageController.page?.toInt() == 1) {
          // print("");
          // If NOT on the default page, go back to previous page
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0); // Navigate to the desired page
          return Future.value(false);
        }
        else if (_pageController.page?.toInt() == 6) {
          // print("");
          // If NOT on the default page, go back to previous page
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0); // Navigate to the desired page
          return Future.value(false);
        }
        else if (_pageController.page?.toInt() == 4) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0); // Navigate to the desired page
          return Future.value(false);
        }
        else if (_pageController.page?.toInt() == 3) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0); // Navigate to the desired page
          return Future.value(false);
        }
        else if (_pageController.page?.toInt() == 5) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0); // Navigate to the desired page
          return Future.value(false);
        }
        else if (_pageController.page?.toInt() == 35) {
          // If NOT on the default page, go back to previous page
          setState(() {
            _selectedIndex = 4;
          });
          _pageController.jumpToPage(4); // Navigate to the desired page
          return false; // Prevent app from exiting
        }
        else if (_pageController.page?.toInt() == 40) {
          // If NOT on the default page, go back to previous page
          setState(() {
            _selectedIndex = 1;
          });
          _pageController.jumpToPage(1); // Navigate to the desired page
          return false; // Prevent app from exiting
        }
        else if (_pageController.page?.toInt() == 12) {
          // If NOT on the default page, go back to previous page
          setState(() {
            _selectedIndex = 4;
          });
          _pageController.jumpToPage(4); // Navigate to the desired page
          return false; // Prevent app from exiting
        }
        else if (_pageController.page?.toInt() == 7) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
          return false;
        }
        else if (_pageController.page?.toInt() == 8) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
          return false;
        }
        else if (_pageController.page?.toInt() == 9) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
          return false;
        }
        else if (_pageController.page?.toInt() == 10) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
          return false;
        }
        else if (_pageController.page?.toInt() == 11) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
          return false;
        }
        else if (_pageController.page?.toInt() == 30) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
          return false;
        }
        else if (_pageController.page?.toInt() == 31) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
          return false;
        }
        else if (_pageController.page?.toInt() == 29) {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
          return false;
        }
        else if (_pageController.page?.toInt() == 0){
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: primary,
              title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
              content: const Text("Time for a fashion break?",style: TextStyle(color: ascent,fontFamily: Poppins),),
              actions: [
                GestureDetector(
                    onTap: (){
                      SystemNavigator.pop();
                    },
                    child: Text("Take a break",style: TextStyle(color: ascent,fontFamily: Poppins,fontSize: 12),),
                ),
                SizedBox(width: 5,),
                GestureDetector(
                  onTap: (){
                    Navigator.pop(context);
                  },
                  child: Text("Keep styling",style: TextStyle(color: ascent,fontFamily: Poppins,fontSize: 12),),
                ),
              ],
            ),
          );
          return false;
        }
        else {
          setState(() {
            _selectedIndex = 0;
            selectedIndex = 0;
          });
          _pageController.jumpToPage(0);
          return false;
        }
      },
      // onWillPop: () async {
      //   print('The user tries to pop()');
      //   if (selectedIndex == 0) {
      //     await showDialog(
      //       context: context,
      //       builder: (context) => AlertDialog(
      //         backgroundColor: primary,
      //         title: const Text(
      //           "FashionTime",
      //           style: TextStyle(
      //               color: ascent,
      //               fontFamily: Poppins,
      //               fontWeight: FontWeight.bold),
      //         ),
      //         content: const Text(
      //           "Do you want to close this application?",
      //           style: TextStyle(color: ascent, fontFamily: Poppins,),
      //         ),
      //         actions: [
      //           TextButton(
      //             child: const Text("Yes",
      //                 style: TextStyle(
      //                   color: ascent, fontFamily: Poppins,)),
      //             onPressed: () {
      //               SystemNavigator.pop();
      //             },
      //           ),
      //           TextButton(
      //             child: const Text("No",
      //                 style: TextStyle(
      //                   color: ascent, fontFamily: Poppins,)),
      //             onPressed: () {
      //               Navigator.pop(context);
      //             },
      //           ),
      //         ],
      //       ),
      //     );
      //     return Future.value(false);
      //   }
      //   else if (_selectedIndex == 5){
      //
      //     return true;
      //   }
      //   else {
      //     Navigator.pushReplacement(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => const HomeScreen(),
      //       ),
      //     );
      //     return true;
      //   }
      // },
      child: Scaffold(
        appBar: selectedIndex == 30 ? null : AppBar(
          leading: const SizedBox(),
          centerTitle: true,
          flexibleSpace: Container(
            height: 80 ,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    stops: const [0.0, 0.7],
                    tileMode: TileMode.clamp,
                    colors: <Color>[
                      secondary,
                      primary,
                    ])),
          ),
          actions: [
            if (selectedIndex == 0)
                  (fanRequests.isEmpty && friendRequests.isEmpty && fanRequestsMessage.isEmpty == true )
                  ? IconButton(
                  onPressed: () {
                    _onItemTapped(7);
                  },
                  icon: const Icon(Icons.face_retouching_natural,color: ascent,))
                  : Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: CustomBadge(
                  label: formatNotificationCount(friendRequests.length + fanRequests.length + fanRequestsMessage.length),
                  isVisible: true,
                  child: GestureDetector(
                      onTap: (){
                        _onItemTapped(7);
                      },
                      child: Icon(Icons.face_retouching_natural,color: ascent)),
                ),
              ),
            if (selectedIndex == 0)
              IconButton(
                onPressed: () {
                  _onItemTapped(8);
                  //Navigator.push(context,MaterialPageRoute(builder: (context) => HistorySearchScreen()));
                },
                icon: const Icon(Icons.person_search,color: ascent),
              ),
            if(selectedIndex==0)
              IconButton(
                onPressed: () {
                  _onItemTapped(9);
                  //Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchByHashtagScreen()));
                },
                icon: const Icon(FontAwesomeIcons.hashtag,color: ascent),
              ),

            if(selectedIndex == 0)
              IconButton(
              onPressed: () {
                _onItemTapped(10);
                //Navigator.push(context, MaterialPageRoute(builder: (context) => const WarningPage()));
              },
              icon: const Icon(Icons.warning,color: ascent),
            ),

            if (selectedIndex == 0)
              notifications.isEmpty
                  ? IconButton(
                onPressed: () {
                  _onItemTapped(11);
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) =>
                  //         const NotificationScreen()))
                  //     .then((value) => setState(() {
                  //   notifications.clear();
                  // }));
                },
                icon: const Icon(Icons.notifications,color: ascent),
              )
                  : Padding(
                padding: const EdgeInsets.only(left:13.0,right:10),
                child: CustomBadge(
                  label: formatNotificationCount(notifications.length),
                  isVisible: true,
                  child: GestureDetector(
                      onTap: (){
                        _onItemTapped(11);
                        // Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //         builder: (context) =>
                        //         const NotificationScreen()))
                        //     .then((value) => setState(() {
                        //   notifications.clear();
                        // }));
                      },
                      child: Icon(Icons.notifications,color: ascent)),
                ),
              ),
            if (_selectedIndex == 1)
              IconButton(
                onPressed: () {
                  navigateToPage(40);
                },
                icon: const Icon(Icons.calendar_month_rounded,color: ascent),
              ),
            if (_selectedIndex == 4)
              IconButton(
                onPressed: () {
                  navigateToPage(12);
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) =>
                  //         //  CalenderScreen()));
                  //         const AllFashionWeeks()));
                },
                icon: const Icon(Icons.calendar_month_rounded,color: ascent),
              ),
            // if (_selectedIndex == 5)
            //   IconButton(onPressed: () {
            //     Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) =>
            //             const MyHundredLikedPost()));
            //   }, icon: const Icon(Icons.history,color: ascent,)),
            if (_selectedIndex == 5)
              PopupMenuButton(
                  icon: const Icon(Icons.settings,color: ascent),
                  onSelected: (value) {
                    if (value == 2) {
                      navigateToPage(13);
                      //_onItemTapped(13);
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => const PrivacyScreen()));
                    }
                    if (value == 3) {
                      navigateToPage(14);
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => const ContactScreen()));
                    }
                    if (value == 4) {
                      navigateToPage(15);
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => const PersonalSettingScreen()));
                    }
                    if (value == 5) {
                      navigateToPage(16);
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => const MyHundredLikedPost()));
                    }
                    if (value == 6) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: primary,
                          title: const Text(
                            "End Session?",
                            style: TextStyle(
                                color: ascent,
                                fontFamily: Poppins,
                                fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            "You’re about to end your stylish session. Don’t worry, your looks are safe 💖.",
                            style: TextStyle(
                                color: ascent, fontFamily: Poppins),
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Stay stylish",
                                  style: TextStyle(
                                      color: ascent, fontFamily: Poppins)),
                              onPressed: () {
                                setState(() {
                                  Navigator.pop(context);
                                });
                              },
                            ),
                            TextButton(
                              child: const Text(
                                "End session",
                                style: TextStyle(
                                    color: ascent, fontFamily: Poppins),
                              ),
                              onPressed: () async {
                                SharedPreferences preferences =
                                await SharedPreferences.getInstance();
                                preferences.clear().then((value) {
                                  Navigator.pop(context);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const Login()));
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    if (value == 8) {
                      navigateToPage(17);
                      //Navigator.push(context, MaterialPageRoute(builder: (context) => StorySettings()));
                    }
                    if (value == 9) {
                      navigateToPage(42);
                    }
                    setState(() {});
                    print(value);
                    //Navigator.pushNamed(context, value.toString());
                  },
                  itemBuilder: (BuildContext bc) {
                    return [
                      PopupMenuItem(
                        value: 2,
                        child: Row(
                          children: [
                            Icon(
                              Icons.privacy_tip,
                              color: primary,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "Privacy",
                              style: TextStyle(fontFamily: Poppins),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 3,
                        child: Row(
                          children: [
                            Icon(Icons.info, color: primary),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "Contact",
                              style: TextStyle(fontFamily: Poppins),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 4,
                        child: Row(
                          children: [
                            Icon(Icons.person, color: primary),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "Personal info",
                              style: TextStyle(fontFamily: Poppins),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 5,
                        child: Row(
                          children: [
                            Icon(Icons.history, color: primary),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "100 Liked posts",
                              style: TextStyle(fontFamily: Poppins),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 8,
                        child: Row(
                          children: [
                            Icon(Icons.menu_book, color: primary),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "Story Settings",
                              style: TextStyle(fontFamily: Poppins),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 9,
                        child: Row(
                          children: [
                            Icon(Icons.security, color: primary),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "Security",
                              style: TextStyle(fontFamily: Poppins),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 6,
                        child: Row(
                          children: [
                            Icon(
                              Icons.exit_to_app,
                              color: primary,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "End session",
                              style: TextStyle(fontFamily: Poppins),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 7,
                        child: Consumer<ThemeNotifier>(
                          builder: (context, notifier, child) => SwitchListTile(
                            dense: true,
                            activeColor:
                            notifier.darkTheme ? primary : Colors.white,
                            title: const Text(
                              "Dark Mode",
                              style: TextStyle(fontFamily: Poppins),
                            ),
                            onChanged: (val) {
                              notifier.toggleTheme();
                              print(notifier.darkTheme);
                            },
                            value: notifier.darkTheme,
                          ),
                        ),
                      )
                    ];
                  })
          ],
          title: selectedIndex == 3
              ? Text(
            "Next Event: $nextWeekText",
            style:
            const TextStyle(fontFamily: Poppins, fontSize: 15,color: ascent),
          )
              : selectedIndex == 1
              ? Text(
            "Current Event: $appbarText",
            style: const TextStyle(
                fontFamily: Poppins, fontSize: 15,color: ascent),
          )
              : selectedIndex == 5
              ? Text(username,
              style: const TextStyle(fontFamily: Poppins,color: ascent))
              : selectedIndex == 6
              ? const Text("Flicks",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 7 ? const Text("Fans & Friends Activity",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 8 ? const Text("Search for users",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 9 ? const Text("Search by hashtags",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 10 ? const Text("Warnings",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 11 ? const Text("Notifications",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 12 ? const Text("Events",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 13 ? const Text("Privacy",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 14 ? const Text("Contact",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 15 ? const Text("Personal Settings",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 16 ? const Text("100 Liked Posts",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 17 ? const Text("Story Settings",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 18 ? const Text("Hidden Stories",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 19 ? const Text("Edit Profile",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 20 ? const Text("My Posts",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 21 ? const Text("Fans",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 22 ? const Text("Idols",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 23 ? const Text("Add Group",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 24 ? const Text("Add Chat",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 25 ? const Text("Start Call",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 26 ? const Text("Friends",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 27 ? const Text("Create Highlight",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 29 ? const Text("Users who liked the post",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 31 ? const Text("Upload Story",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 32 ? const Text("Medal Posts",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 33 ? const Text("Star Posts",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 34 ? const Text("Saved Styles",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 35 ? const Text("Style Detail",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 36 ? const Text("All Searches",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 37 ? const Text("Add Call",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 38 ? const Text("Create Flick",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 39 ? const Text("Report Flick",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 2 ? const Text("Chats",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 40 ? const Text("Events",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 41 ? const Text("Select Friend",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : selectedIndex == 42 ? const Text("Security",
              style: TextStyle(
                  fontFamily: Poppins, fontSize: 20,color: ascent))
              : null
        ),
        body: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 43, // Number of screens
          itemBuilder: (context, index) => getScreen(index),
        ),
        bottomNavigationBar: SizedBox(
          child: Container(
            height: Platform.isIOS ? 90 : 66,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [secondary, primary],
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                stops: const [0.0, 0.99],
                tileMode: TileMode.clamp,
              ),
            ),
            child: Column(
              children: [
                BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Colors.yellow.shade600,
                  unselectedItemColor: Colors.white,
                  items: <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: GestureDetector(
                        onDoubleTap: () {
                          if (_pageController.page == 0) {
                            _pageController.jumpToPage(1); // Temporarily switch to another page
                            Future.delayed(Duration(milliseconds: 100), () {
                              _pageController.jumpToPage(0); // Then switch back to Home
                            });
                          } else {
                            _pageController.jumpToPage(0);
                          }
                        },
                        child: Column(
                          children: [
                            SizedBox(height: 2,),
                            Image.asset(
                              "assets/4-white.png",
                              height: 30,
                              width: 30,
                            ),
                            if(friendRequests.isNotEmpty == true || notifications.isNotEmpty  == true || fanRequests.isNotEmpty == true || fanRequestsMessage.isNotEmpty == true) SizedBox(height: 2,),
                            if(friendRequests.isNotEmpty == true || notifications.isNotEmpty  == true || fanRequests.isNotEmpty == true || fanRequestsMessage.isNotEmpty == true) Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(20)),
                                    color: Colors.red,
                                  ),
                                  height: 5,
                                  width: 5,
                                  child: Text("."),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      activeIcon: GestureDetector(
                        onTap: () {
                          if (_pageController.page == 0) {
                            setState(() {
                              _selectedIndex = 0;
                              selectedIndex = 0;
                              friendRequests.clear();
                              fanRequests.clear();
                              notifications1.clear();
                              fanRequestsMessage.clear();
                            });
                            _pageController.jumpToPage(1); // Temporarily switch to another page
                            Future.delayed(Duration(milliseconds: 100), () {
                              _pageController.jumpToPage(0); // Then switch back to Home
                            });
                          } else {
                            setState(() {
                              _selectedIndex = 0;
                              selectedIndex = 0;
                              friendRequests.clear();
                              fanRequests.clear();
                              notifications1.clear();
                              fanRequestsMessage.clear();
                            });
                            _pageController.jumpToPage(0);
                          }
                        },
                        child: Column(
                          children: [
                            SizedBox(height: 5,),
                            Image.asset(
                              "assets/Frame4.png",
                              height: 30,
                              width: 30,
                            ),
                            if(friendRequests.isNotEmpty == true || notifications1.isNotEmpty  == true || fanRequests.isNotEmpty == true || fanRequestsMessage.isNotEmpty == true) SizedBox(height: 2,),
                            if(friendRequests.isNotEmpty == true || notifications1.isNotEmpty  == true || fanRequests.isNotEmpty == true || fanRequestsMessage.isNotEmpty == true) Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(20)),
                                    color: Colors.red,
                                  ),
                                  height: 5,
                                  width: 5,
                                  child: Text("."),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: Image.asset(
                        "assets/5-white.png",
                        height: 30,
                        width: 30,
                      ),
                      activeIcon: Image.asset(
                        "assets/Frame5.png",
                        height: 30,
                        width: 30,
                      ),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: Image.asset(
                        "assets/6-white.png",
                        height: 30,
                        width: 30,
                      ),
                      activeIcon: Image.asset(
                        "assets/Frame6.png",
                        height: 30,
                        width: 30,
                      ),
                      label: "Chat",
                    ),
                    BottomNavigationBarItem(
                      icon: Image.asset(
                        "assets/3-white.png",
                        height: 30,
                        width: 30,
                      ),
                      activeIcon: Image.asset(
                        "assets/Frame3.png",
                        height: 30,
                        width: 30,
                      ),
                      label: "Upload",
                    ),
                    BottomNavigationBarItem(
                      icon: Image.asset(
                        "assets/1-white.png",
                        height: 30,
                        width: 30,
                      ),
                      activeIcon: Image.asset(
                        "assets/Frame1.png",
                        height: 30,
                        width: 30,
                      ),
                      label: "Feed",
                    ),
                    BottomNavigationBarItem(
                      icon: Image.asset(
                        "assets/2-white.png",
                        height: 30,
                        width: 30,
                      ),
                      activeIcon: Image.asset(
                        "assets/Frame2.png",
                        height: 30,
                        width: 30,
                      ),
                      label: "Profile",
                    ),
                    BottomNavigationBarItem(
                      icon: Image.asset(
                        "assets/FlickIcon.png",
                        height: 30,
                        width: 30,
                      ),
                      activeIcon: GestureDetector(
                        onTap: (){
                          if (_pageController.page == 6) {
                            _pageController.jumpToPage(5); // Temporarily switch to another page
                            Future.delayed(Duration(milliseconds: 100), () {
                              _pageController.jumpToPage(6); // Then switch back to Home
                            });
                          } else {
                            _pageController.jumpToPage(6);
                          }
                        },
                        child: Image.asset(
                          "assets/flinkWhite.png",
                          height: 30,
                          width: 35,
                        ),
                      ),
                      label: "Flicks",
                    ),
                  ],
                  type: BottomNavigationBarType.fixed,
                  currentIndex: (_selectedIndex < 7) ? _selectedIndex : 0,
                  onTap: _onItemTapped,
                  selectedFontSize: 10,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class CustomBadge extends StatefulWidget {
  final String? label;
  final Widget child;
  final bool isVisible;

  const CustomBadge({super.key, this.label, required this.child, required this.isVisible});

  @override
  State<CustomBadge> createState() => _CustomBadgeState();
}

class _CustomBadgeState extends State<CustomBadge> {
  @override
  Widget build(BuildContext context) {
    return Column(
      //alignment: Alignment.topRight,
      //mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: 5,),
        widget.child,
        Visibility(
          visible: widget.isVisible,
          child: Container(
            height: 5,
            width: 5,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Colors.red,
            ),
            child: Center(
              child: Text(
                "",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 2,
                  fontFamily: Poppins,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
