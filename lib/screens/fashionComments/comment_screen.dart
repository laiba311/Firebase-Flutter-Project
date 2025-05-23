import 'dart:convert';
import 'dart:ui';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/customize_pacages/mentions/src/mention_text_field.dart';
import 'package:finalfashiontimefrontend/models/story_model.dart';
import 'package:finalfashiontimefrontend/models/user_model.dart';
import 'package:finalfashiontimefrontend/screens/chats-screens/message_screen.dart';
import 'package:finalfashiontimefrontend/screens/fashionComments/report_coment.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/event_posts.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/stories/view_story.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/giphy_picker.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../animations/bottom_animation.dart';
import '../../../helpers/database_methods.dart';
import '../../../utils/constants.dart';
import '../../customize_pacages/mentions/src/mention_member_model.dart';
import '../../customize_pacages/mentions/src/mention_text_field_controller.dart';

class KeyboardAwareBackHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback onBackWhenKeyboardClosed;

  const KeyboardAwareBackHandler({
    super.key,
    required this.child,
    required this.onBackWhenKeyboardClosed,
  });

  @override
  State<KeyboardAwareBackHandler> createState() => _KeyboardAwareBackHandlerState();
}

class _KeyboardAwareBackHandlerState extends State<KeyboardAwareBackHandler> with WidgetsBindingObserver {
  bool _keyboardVisible = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final newKeyboardState = MediaQuery.of(context).viewInsets.bottom > 0;
    if (newKeyboardState != _keyboardVisible) {
      setState(() {
        _keyboardVisible = newKeyboardState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        if (_keyboardVisible) {
          // Close keyboard first
          FocusScope.of(context).unfocus();
        } else {
          // Keyboard already closed - trigger custom function
          widget.onBackWhenKeyboardClosed();
        }
      },
      child: widget.child,
    );
  }
}

class KeyboardListener extends StatefulWidget {
  final VoidCallback onKeyboardClosed;
  final VoidCallback? onKeyboardOpened;
  final VoidCallback? onKeyboardAlreadyClosed;
  final Widget child;

  const KeyboardListener({
    super.key,
    required this.onKeyboardClosed,
    this.onKeyboardOpened,
    this.onKeyboardAlreadyClosed,
    required this.child,
  });

  @override
  State<KeyboardListener> createState() => _KeyboardListenerState();
}

class _KeyboardListenerState extends State<KeyboardListener> with WidgetsBindingObserver {
  bool _wasKeyboardOpen = false;
  bool _initialCheckComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Don't check MediaQuery here
    _initialCheckComplete = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialCheckComplete) {
      _wasKeyboardOpen = _isKeyboardOpen();
      _checkInitialState();
      _initialCheckComplete = true;
    }
  }

  void _checkInitialState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_wasKeyboardOpen) {
        widget.onKeyboardAlreadyClosed?.call();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final isKeyboardOpen = _isKeyboardOpen();

    if (_wasKeyboardOpen && !isKeyboardOpen) {
      widget.onKeyboardClosed();
    }
    else if (!_wasKeyboardOpen && isKeyboardOpen) {
      widget.onKeyboardOpened?.call();
    }

    _wasKeyboardOpen = isKeyboardOpen;
  }

  bool _isKeyboardOpen() {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.viewInsets.bottom > 100;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isKeyboardOpen()) {
        widget.onKeyboardAlreadyClosed?.call();
      }
    });

    return widget.child;
  }
}

bool keyBoardOpen = false;
FocusNode focusNode1 = FocusNode();

class CommentScreen extends StatefulWidget {
  final String postid;
  final String pic;
  final ScrollController scrollController;
  final BuildContext? context1;
  final bool isEventPost;
  final String userID;
  final DraggableScrollableController? draggableController;
  final FocusNode? textFieldFocusNode;
  const CommentScreen({Key? key, required this.postid, required this.pic,required this.scrollController, this.context1, required this.isEventPost, required this.userID, this.draggableController, this.textFieldFocusNode})
      : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> with WidgetsBindingObserver {
  String id = "";
  String token = "";
  String username = '';
  String pic = "";
  List<dynamic> comments = [];
  List<dynamic> filterComments = [];
  List<dynamic> comments1 = [];
  List<dynamic> myComments = [];
  bool loading = false;
  bool loading1 = false;
  bool isFilterOn = false;
  bool show = false;
  TextEditingController comment = TextEditingController();
  TextEditingController replyController = TextEditingController();
  TextEditingController editController=TextEditingController();
  GiphyGif? _gif;
  List<bool> moreReply = [];
  bool isReply = false;
  int commentID = 0;
  List<int> repliesShownCount = [];
  final int incrementBy = 3;
  String filter = "";
  final Map<int, GlobalKey> _commentKeys = {};
  bool mostRecentBool = true;
  bool recommendedBool = false;
  bool myCommentsBool = false;
  bool mostLikedBool = false;
  bool medalBool = false;
  List<bool> blockStatus = [];
  List<int> blockList = [];
  String name = "";
  bool isLoadBlock = false;
  List<int> myfans = [];
  List<int> myList = [];
  bool isGetRequest = false;
  String isGetRequestStatus = "";
  String touser = "";
  String fromuser = "";
  List<Map<String,dynamic>> users = [];
  List<Map<String,dynamic>> _searchResults = [];
  List<String> mentions = [];
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  TextEditingController searchCommentText = TextEditingController();
  bool isSearch = false;
  String? warningMessage;
  late MentionTextFieldController controller = MentionTextFieldController(myName:"", memberList: []);
  List<MentionMemberModel> mentionMember = [];
  List<MentionMemberModel> mentionMember2 = [];
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final FocusNode focusNode = FocusNode();
  String replyName = "";
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  bool _suggestionsOpen = false;
  late final ModalRoute _modalRoute;

  void validateComment() {
    String text = comment.text;
    bool containsLink = RegExp(r'\b(?:https?|http|www)\S*', caseSensitive: false).hasMatch(text);

    setState(() {
      warningMessage = containsLink ? "Links are not allowed!" : null;
    });
  }

  void filterFriends(String query) {
    List<dynamic> tempList = [];

    if (query.isEmpty) {
      setState(() {
        filterComments = List.from(comments);
      });
    } else {
      for (var friend in comments) {
        final username = friend["user"]["username"]?.toLowerCase() ?? '';
        final commentText = friend["comment"]?.toString() ?? '';

        final isMediaLink = commentText.startsWith("https://media");
        final matchesUsername = username.contains(query.toLowerCase());
        final matchesComment = !isMediaLink && commentText.toLowerCase().contains(query.toLowerCase());

        if (matchesUsername || matchesComment) {
          tempList.add(friend);
        }
      }

      setState(() {
        filterComments = tempList;
      });

      print("Query: $query");
      print("Matched Count: ${filterComments.length}");
    }
  }

  matchFriendReques(userid,user,user1,user2,index,List<int> fans,id1){
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
            });
            print(isGetRequest.toString());
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
        blockUser(user, user1, user2, index, fans, id1);
        setState(() {
          loading = false;
        });
        print(jsonDecode(value.body).toString());
      });
    }catch(e){
      setState(() {
        loading = false;
      });
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
        // setState(() {
        //   loading = false;
        // });
        print("favourite ==> ${value.body.toString()}");
        jsonDecode(value.body).forEach((e){
          print("item => ${e}");
          myList.add(e);
        });
        print("favourite list => ${myList}");
      });
      getFan();
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }

  getUsers() {
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/user/api/allUsers/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        jsonDecode(value.body)["results"].forEach((e){
          mentionMember2.add(MentionMemberModel(
              id: e["id"].toString(),
              uid: e["name"] == null ? "NoName" : Uri.decodeComponent(e["name"].toString()),
              name: e["username"],
              badge: e["badge"] == null ? {
                "id": 0,
                "document": "",
                "ranking_order": 0
              }: e["badge"],
              picture: e["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w"));
          print("item private => ${e["isPrivate"]}");
          if(e["isPrivate"] == true) {
            if(e["followList"].contains(int.parse(id)) == true || e["fansList"].contains(int.parse(id)) == true){
              setState(() {
                mentionMember.add(MentionMemberModel(
                    id: e["id"].toString(),
                    uid: e["name"] == null ? "NoName" : Uri.decodeComponent(e["name"].toString()),
                    name: e["username"],
                    badge: e["badge"] == null ? {
                      "id": 0,
                      "document": "",
                      "ranking_order": 0
                    }: e["badge"],
                    picture: e["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w"));
              });
            }
          }else {
            setState(() {
              mentionMember.add(MentionMemberModel(
                  id: e["id"].toString(),
                  uid: e["name"] == null ? "NoName" : Uri.decodeComponent(e["name"].toString()),
                  name: e["username"],
                  badge: e["badge"] != null ? e["badge"] : {
                    "id": 0,
                    "document": "",
                    "ranking_order": 0
                  },
                  picture: e["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w"));
            });
          }
        });
        print("users list => ${mentionMember}");
        controller = MentionTextFieldController(myName: username, memberList: mentionMember, mentionColor: secondary,myNameColor: secondary);
      });
      getFavourites();
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }

  bool _isScrollingDown = false;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  final ScrollController _scrollController = ScrollController();

  void scrollToComment(int index) {
    if (_commentKeys[index]?.currentContext != null) {
      final RenderBox commentBox =
      _commentKeys[index]!.currentContext!.findRenderObject() as RenderBox;
      final position = commentBox.localToGlobal(Offset.zero, ancestor: null);

      // Calculate the offset relative to the scrollable ListView
      final scrollOffset = _scrollController.offset + position.dy - 10;
      //_scrollController.jumpTo(scrollOffset);
      _scrollController.animateTo(
        scrollOffset,  // Scroll to the calculated offset
        duration: Duration(milliseconds: 300),  // Animation duration
        curve: Curves.easeInOut,  // Animation curve
      );
    }
  }

  getCashedData() async {
    print("post id ${widget.postid}");
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    username = preferences.getString('username')!;
    name = preferences.getString('name')!;
    pic = preferences.getString('pic')!;
    print(name);
    print(token);
    getUsers();
    //getComments(widget.postid);
    //repliesShownCount = List.filled(comments.length, 5);
    // getMyComments(widget.id);
  }
  void closeReplyAndScrollToComment(int commentIndex) {
    setState(() {
      // Logic to close the reply goes here
      // For example, if you are removing a reply from the list or collapsing it
    });

    // After the UI updates, scroll to the actual comment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToComment(commentIndex);
    });
  }
  getComments(id) {
    //moreReply.clear();
    //repliesShownCount.clear();
    //blockStatus.clear();
    setState(() {
      loading = true;
      comments.clear();
      filterComments.clear();
    });
    https.get(Uri.parse("$serverUrl/fashionComments/$id"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      setState(() {
        loading = false;
      });
      final body = utf8.decode(value.bodyBytes);
      final jsonData = jsonDecode(body);
      print("all comments ${value.body}");
      jsonData["results"].forEach((data) {
        setState(() {
          comments1.add(data);
          comments.add(data);
          filterComments.add(data);
          moreReply.add(false);
          blockStatus.add(false);
        });
      });
      repliesShownCount = List.filled(comments.length, 5);
    }).catchError((error) {
     // if (!mounted) return;
      setState(() {
        loading = false;
      });
      print("Comment Error ==> "+error.toString());
    });
  }
  getMyComments(id) {
    //moreReply.clear();
    myComments.clear();
    //blockStatus.clear();
    //repliesShownCount.clear();
    setState(() {
      loading = true;
      comments.clear();
    });
    https.get(Uri.parse("$serverUrl/fashionComments/$id"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      setState(() {
        loading = false;
      });
      print(value.body.toString());
      final body = utf8.decode(value.bodyBytes);
      final jsonData = jsonDecode(body);
      jsonData["results"].forEach((data) {
        if (data["user"]["username"] == username) {
          setState(() {
            myComments.add(data);
            filterComments.add(data);
            moreReply.add(false);
            blockStatus.add(false);
            print("my comments ${myComments.toString()}");
            print("my comments length is ${myComments.length}");
          });
          repliesShownCount = List.filled(myComments.length, 5);
        } else {
          print("no comments");
        }
      });
    }).catchError((error) {
      setState(() {
        loading = false;
      });
      print(error.toString());
    });
  }
  getRecentComments(id) {
    //moreReply.clear();
    //repliesShownCount.clear();
   //blockStatus.clear();
    setState(() {
      loading = true;
      comments.clear();
      filterComments.clear();
    });
    https.get(Uri.parse("$serverUrl/fashionComments/${id}/recent-comments/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      setState(() {
        loading = false;
      });
      print(value.body.toString());
      final body = utf8.decode(value.bodyBytes);
      final jsonData = jsonDecode(body);
      jsonData["results"].forEach((data) {
        setState(() {
          comments.add(data);
          filterComments.add(data);
          moreReply.add(false);
          blockStatus.add(false);
        });
      });
      repliesShownCount = List.filled(comments.length, 5);
      setState(() {
        comments = comments.reversed.toList();
      });
    }).catchError((error) {
      setState(() {
        loading = false;
      });
      print(error.toString());
    });
  }
  getMostLikedComments(id) {
    //moreReply.clear();
    //repliesShownCount.clear();
    //blockStatus.clear();
    setState(() {
      loading = true;
      comments.clear();
      filterComments.clear();
    });

    https.get(
        Uri.parse("$serverUrl/fashionComments/${id}/most-liked-comments/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value) {
      var responseBody = json.decode(value.body);
      final body = utf8.decode(value.bodyBytes);
      final jsonData = jsonDecode(body);

      if (jsonData != null && jsonData.containsKey("results")) {
        List<dynamic> fetchedComments = jsonData["results"];

        // Debug: Print likeCommentsCount before sorting
        print("Fetched Comments Before Sorting:");
        fetchedComments.forEach((data) {
          print("Comment ID: ${data['id']}, likeCommentsCount: ${data['likeCommentsCount']}");
        });

        // Sort the fetched comments by likeCommentsCount
        setState(() {
          fetchedComments.sort((a, b) => b['likeCommentsCount'].compareTo(a['likeCommentsCount']));
        });

        // Debug: Print likeCommentsCount after sorting
        print("Comments After Sorting:");
        fetchedComments.forEach((data) {
          print("Comment ID: ${data['id']}, likeCommentsCount: ${data['likeCommentsCount']}");
        });

        setState(() {
          loading = false;
          comments.addAll(fetchedComments);
          filterComments.addAll(fetchedComments);
          moreReply.addAll(List.generate(fetchedComments.length, (_) => false));
          blockStatus.addAll(List.generate(fetchedComments.length, (_) => false));
        });
        repliesShownCount = List.filled(comments.length, 5);
      } else {
        print("Error: Invalid response structure");
      }
    }).catchError((error) {
      setState(() {
        loading = false;
      });
      print("Error fetching comments: $error");
    });
  }
  createComment() async {
    setState(() {
      loading1 = true;
    });
    try {
      if (comment.text == ""&& _gif==null) {
        setState(() {
          loading1 = false;
        });
        // showDialog(
        //   context: context,
        //   builder: (context) => AlertDialog(
        //     title: const Text(
        //       "FashionTime",
        //       style: TextStyle(
        //           color: ascent,
        //           fontFamily: Poppins,
        //           fontWeight: FontWeight.bold),
        //     ),
        //     content: const Text(
        //       "Please fill all the fields",
        //       style: TextStyle(color: ascent, fontFamily: Poppins),
        //     ),
        //     actions: [
        //       TextButton(
        //         child: const Text("Okay",
        //             style: TextStyle(color: ascent, fontFamily: Poppins)),
        //         onPressed: () {
        //           setState(() {
        //             Navigator.pop(context);
        //           });
        //         },
        //       ),
        //     ],
        //   ),
        // );
      }
      else if(_gif!=null) {
        setState(() {
          loading1 = true;
        });
        Map<String, dynamic> body = {
          "comment": _gif?.images.original?.url.toString(),
          "fashion": widget.postid,
          "user": id,
          "mentions": mentions
        };
        https.post(Uri.parse("$serverUrl/fashionComments/"),
            body: json.encode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            }).then((value) {
          print("Response ==> ${value.body}");
          setState(() {
            loading1 = false;
            comment.clear();
            mentions.clear();
          });
          getComments(widget.postid);
        }).catchError((error) {
          setState(() {
            loading1 = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                error.toString(),
                style: const TextStyle(color: ascent, fontFamily: Poppins),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                          TextStyle(color: ascent, fontFamily: Poppins)),
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
      }
      else{
        setState(() {
          loading1 = true;
        });
        Map<String, dynamic> body = {
          "comment": controller.text,
          "fashion": widget.postid,
          "user": id,
          "mentions": mentions
        };
        https.post(Uri.parse("$serverUrl/fashionComments/"),
            body: json.encode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            }).then((value) {
          print("Response ==> ${value.body}");
          setState(() {
            loading1 = false;
            comment.clear();
            mentions.clear();
            controller.text = "";
          });
          getComments(widget.postid);
        }).catchError((error) {
          setState(() {
            loading1 = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                error.toString(),
                style: const TextStyle(color: ascent, fontFamily: Poppins),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins)),
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
      }
    } catch (e) {
      setState(() {
        loading1 = false;
      });
      print(e);
    }
  }
  bool isCommentEdited(String created, String updated) {
    DateTime createdDateTime = DateTime.parse(created);
    DateTime updatedDateTime = DateTime.parse(updated);

    // Truncate the microseconds and nanoseconds
    DateTime createdWithoutMicroseconds = DateTime(
      createdDateTime.year,
      createdDateTime.month,
      createdDateTime.day,
      createdDateTime.hour,
      createdDateTime.minute,
      createdDateTime.second,
    );

    DateTime updatedWithoutMicroseconds = DateTime(
      updatedDateTime.year,
      updatedDateTime.month,
      updatedDateTime.day,
      updatedDateTime.hour,
      updatedDateTime.minute,
      updatedDateTime.second,
    );

    // Compare the truncated DateTime objects
    return createdWithoutMicroseconds != updatedWithoutMicroseconds;
  }
  editMyComment(fashionCommentId,fashionId) async {
    setState(() {
      loading1 = true;
    });
    try {
      if (editController.text == ""&& _gif==null) {
        setState(() {
          loading1 = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              "FashionTime",
              style: TextStyle(
                  color: ascent,
                  fontFamily: Poppins,
                  fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Please fill all the fields",
              style: TextStyle(color: ascent, fontFamily: Poppins),
            ),
            actions: [
              TextButton(
                child: const Text("Okay",
                    style: TextStyle(color: ascent, fontFamily: Poppins)),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      } else if(_gif!=null) {
        setState(() {
          loading1 = true;
        });
        Map<String, dynamic> body = {
          "comment": _gif?.images.original?.url.toString(),
          "fashion": int.parse(fashionCommentId),
          "user": id
        };
        https.patch(Uri.parse("$serverUrl/fashionComments/$fashionCommentId/"),
            body: json.encode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            }).then((value) {
          print("Response ==> ${value.body}");
          setState(() {
            loading1 = false;
            myComments.clear();
          });
          getMyComments(widget.postid);
        }).catchError((error) {
          setState(() {
            loading1 = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                error.toString(),
                style: const TextStyle(color: ascent, fontFamily: Poppins),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins)),
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
      }
      else{
        setState(() {
          loading1 = true;
        });
        Map<String, dynamic> body = {
          "comment": editController.text,
          "fashion": fashionId,
          "user": id
        };
        https.patch(Uri.parse("$serverUrl/fashionComments/$fashionCommentId/"),
            body: json.encode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            }).then((value) {
          print("Response ==> ${value.body}");
          setState(() {
            loading1 = false;
            myComments.clear();
          });
          getMyComments(widget.postid);
        }).catchError((error) {
          setState(() {
            loading1 = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                error.toString(),
                style: const TextStyle(color: ascent, fontFamily: Poppins),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins)),
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
      }
    } catch (e) {
      setState(() {
        loading1 = false;
      });
      print(e);
    }
  }
  editComment(fashionCommentId,fashionId) async {
    setState(() {
      loading1 = true;
    });
    // try {
      if (editController.text == ""&& _gif==null) {
        setState(() {
          loading1 = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              "FashionTime",
              style: TextStyle(
                  color: ascent,
                  fontFamily: Poppins,
                  fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Please fill all the fields",
              style: TextStyle(color: ascent, fontFamily: Poppins),
            ),
            actions: [
              TextButton(
                child: const Text("Okay",
                    style: TextStyle(color: ascent, fontFamily: Poppins)),
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
      else if(_gif!=null) {
        setState(() {
          loading1 = true;
        });
        Map<String, dynamic> body = {
          "comment": _gif?.images.original?.url.toString(),
          "fashion": fashionId,
          "user": id
        };
        https.patch(Uri.parse("$serverUrl/fashionComments/$fashionCommentId/"),
            body: json.encode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            }).then((value) {
          print("Response ==> ${value.body}");
          setState(() {
            loading1 = false;
            myComments.clear();
          });
          getComments(widget.postid);
        }).catchError((error) {
          setState(() {
            loading1 = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                error.toString(),
                style: const TextStyle(color: ascent, fontFamily: Poppins),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins)),
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
      }
      else{
        setState(() {
          loading1 = true;
        });
        Map<String, dynamic> body = {
          "comment": editController.text,
          "fashion": fashionId,
          "user": id
        };
        https.patch(Uri.parse("$serverUrl/fashionComments/$fashionCommentId/"),
            body: json.encode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            }).then((value) {
          print("Response ==> ${value.body}");
          setState(() {
            loading1 = false;
            comments.clear();
          });
          getComments(widget.postid);
        }).catchError((error) {
          setState(() {
            loading1 = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                error.toString(),
                style: const TextStyle(color: ascent, fontFamily: Poppins),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins)),
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
      }
    // } catch (e) {
    //   setState(() {
    //     loading1 = false;
    //   });
    //   print("Error Gif ==> ${e.toString()}");
    // }
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
    getComments(widget.postid);
  }
  String formatTimeDifference(String dateString) {
    DateTime createdAt = DateTime.parse(dateString);
    DateTime now = DateTime.now();

    Duration difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      int weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else if (difference.inDays < 365) {
      int months = (difference.inDays / 30).floor();
      return '${months}m';
    } else {
      int years = (difference.inDays / 365).floor();
      return '${years}y';
    }
  }
  deleteComment(commentId)async{
    print("entered");
    try{
      https.delete(Uri.parse("$serverUrl/fashionComments/$commentId/"),headers: {
        "Content-Type": "application/json",
        // "Authorization": "Bearer $token"
      }).then((value) {
        debugPrint("response====>${value.statusCode}");
        debugPrint("comment id is==========>$commentId");
        if(value.statusCode==204){
          debugPrint("comment id is==========>$commentId");
          Fluttertoast.showToast(msg: "comment deleted",backgroundColor: primary);
          Navigator.pop(context);
          myComments.clear();
          getMyComments(widget.postid);
          comments.clear();
          getComments(widget.postid);
        }
      });
    }catch(e){
      Fluttertoast.showToast(msg: "error received",backgroundColor: Colors.red);
    }
  }
  createCommentReply(int commentId,String reply) async {
    if (comment.text == ""&& _gif==null) {
      setState(() {
        loading1 = false;
      });
      // showDialog(
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: const Text(
      //       "FashionTime",
      //       style: TextStyle(
      //           color: ascent,
      //           fontFamily: Poppins,
      //           fontWeight: FontWeight.bold),
      //     ),
      //     content: const Text(
      //       "Please fill all the fields",
      //       style: TextStyle(color: ascent, fontFamily: Poppins),
      //     ),
      //     actions: [
      //       TextButton(
      //         child: const Text("Okay",
      //             style: TextStyle(color: ascent, fontFamily: Poppins)),
      //         onPressed: () {
      //           setState(() {
      //             Navigator.pop(context);
      //           });
      //         },
      //       ),
      //     ],
      //   ),
      // );
    }
    else if(_gif!=null){
      Map<String, dynamic> body = {
        "comment": _gif?.images.original?.url.toString(),
        "comment_id": commentId,
        "user": id
      };
      https.post(Uri.parse("$serverUrl/fashionReplyComments/"),
          body: json.encode(body),
          headers: {"Content-Type": "application/json"}).then((value) {
        debugPrint("reply posted with ${value.body}");
        setState(() {
          isReply = false;
        });
        comment.clear();
        getComments(widget.postid);
      }).catchError((e) {
        print("Reply Error ${e.toString()}");
      });
    }
    else {
      Map<String, dynamic> body = {
        "comment": reply,
        "comment_id": commentId,
        "user": id
      };
      https.post(Uri.parse("$serverUrl/fashionReplyComments/"),
          body: json.encode(body),
          headers: {"Content-Type": "application/json"}).then((value) {
        debugPrint("reply posted with ${value.body}");
        setState(() {
          isReply = false;
          controller.text = "";
        });
        comment.clear();
        getComments(widget.postid);
      }).catchError((e) {
        print("Reply Error ${e.toString()}");
      });
    }
  }
  String utf8convert(String text) {
    List<int> bytes = text.toString().codeUnits;
    return utf8.decode(bytes);
  }
  likeComment(int commentId){
    String url='$serverUrl/fashionLikeComments/';
    Map<String,dynamic> requestBody={
      "likeEmoji":"heart",
      "fashionComment":commentId,
      "user":int.parse(id)
    };
    try{
      https.post(Uri.parse(url),headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },body: jsonEncode(requestBody)).then((value){
        if(value.statusCode==201){
          print("liked");
          // getComments(widget.postid),
          // Fluttertoast.showToast(msg: "Comment liked",backgroundColor: primary)
        }
        else{
          debugPrint("error received when posting like in comments ${value.body}${value.statusCode}");
        }
      });
    }
    catch(e){
        debugPrint("Exception caught while liking comment ${e.toString()}");
    }
  }
  unlikeComment(int commentId){
    String url='$serverUrl/fashionComments/${commentId}/unlike/';
    Map<String,dynamic> requestBody={
    "comment": "string",
    "isEdited": "string",
    "fashion": int.parse(widget.postid),
    "user":int.parse(id)
    };
    try{
      https.post(Uri.parse(url),headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },body: jsonEncode(requestBody)).then((value){
        if(value.statusCode==204){
          print("liked");
          // getComments(widget.postid),
          // Fluttertoast.showToast(msg: "Comment unliked",backgroundColor: primary)
        }
        else{
          debugPrint("error received when posting like in comments ${value.body}${value.statusCode}");
        }
      });
    }
    catch(e){
      debugPrint("Exception caught while liking comment ${e.toString()}");
    }
  }
  likeCommentReply(int commentId){
    print("like reply function called");
    String url='${serverUrl}/fashionReplyComments/${commentId}/like/';
    Map<String,dynamic> requestBody={
      "comment": "string",
      "isEdited": "string",
      "comment_id": commentId,
      "user": int.parse(id)
    };
    try{
      https.post(Uri.parse(url),headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }, body: jsonEncode(requestBody)).then((value){
        if(value.statusCode==201){
          print("liked");
          // getComments(widget.postid),
          // Fluttertoast.showToast(msg: "Comment liked",backgroundColor: primary)
        }
        else{
          debugPrint("error received when posting like in comments ${value.body}${value.statusCode}");
        }
      });
    }
    catch(e){
      debugPrint("Exception caught while liking comment ${e.toString()}");
    }
  }
  unlikeCommentReply(int commentId){
    String url='$serverUrl/fashionReplyComments/${commentId}/unlike/';
    Map<String,dynamic> requestBody={
      "comment": "string",
      "isEdited": "string",
      "comment_id": commentId,
      "user": int.parse(id)
    };
    try{
      https.post(Uri.parse(url),headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },body: jsonEncode(requestBody)).then((value){
        if(value.statusCode==204){
          print("liked");
          // getComments(widget.postid),
          // Fluttertoast.showToast(msg: "Comment unliked",backgroundColor: primary)
        }
        else{
          debugPrint("error received when posting like in comments ${value.body}${value.statusCode}");
        }
      });
    }
    catch(e){
      debugPrint("Exception caught while liking comment ${e.toString()}");
    }
  }
  editCommentReply(replyId,commentId) async {
    setState(() {
      loading1 = true;
    });
    try {
      if (editController.text == ""&& _gif==null) {
        setState(() {
          loading1 = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              "FashionTime",
              style: TextStyle(
                  color: ascent,
                  fontFamily: Poppins,
                  fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Please fill all the fields",
              style: TextStyle(color: ascent, fontFamily: Poppins),
            ),
            actions: [
              TextButton(
                child: const Text("Okay",
                    style: TextStyle(color: ascent, fontFamily: Poppins)),
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
      else if(_gif!=null) {
        setState(() {
          loading1 = true;
        });
        Map<String, dynamic> body = {
          "comment": _gif?.images.original?.url.toString(),
          "isEdited": "string",
          "comment_id": commentId,
          "user": id
        };
        https.patch(Uri.parse("$serverUrl/fashionReplyComments/$replyId/"),
            body: json.encode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            }).then((value) {
          print("Response ==> ${value.body}");
          setState(() {
            loading1 = false;
            myComments.clear();
          });
          getComments(widget.postid);
        }).catchError((error) {
          setState(() {
            loading1 = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                error.toString(),
                style: const TextStyle(color: ascent, fontFamily: Poppins),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins)),
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
      }
      else{
        setState(() {
          loading1 = true;
        });
        Map<String, dynamic> body = {
          "comment": editController.text,
          "isEdited": "string",
          "comment_id": commentId,
          "user": id
        };
        https.patch(Uri.parse("$serverUrl/fashionReplyComments/$replyId/"),
            body: json.encode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            }).then((value) {
          print("Response ==> ${value.body}");
          setState(() {
            loading1 = false;
            comments.clear();
          });
          getComments(widget.postid);
        }).catchError((error) {
          setState(() {
            loading1 = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                error.toString(),
                style: const TextStyle(color: ascent, fontFamily: Poppins),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins)),
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
      }
    } catch (e) {
      setState(() {
        loading1 = false;
      });
      print(e);
    }
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
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
  }
  unfriendRequest(userid){
    setState(() {
      loading = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_remove/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      setState(() {
        loading = false;
      });
      print("Unfriend response ==> ${value.body.toString()}");
      setState(() {
        isGetRequest = false;
      });
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
  }
  getFan(){
    setState(() {
      loading = true;
    });
    myfans.clear();
    https.get(
      Uri.parse("$serverUrl/fansRequests/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).then((value){
      json.decode(value.body).forEach((e){
        if(e["from_user"].toString() == id) {
          myfans.add(e["to_user"]);
        }
      });
      getBlockList();
    }).catchError((value){
      print(value);
    });
  }
  blockUser(user,user1,user2,index,List<int> fans,friendID){
    // print("fans => ${myfans} => ${user}");
    // if(myfans.contains(int.parse(user.toString()))){
    //   removeFan(user);
    // }
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
      //DatabaseMethods().blockChat(user1, user2);
      if(myfans.contains(int.parse(user.toString()))){
        removeFan(user);
      }
      if(
      (isGetRequest == true && isGetRequestStatus == "Accepted" && fromuser == id) ||
          (isGetRequest == true && isGetRequestStatus == "Pending" && fromuser != id)
      ){
        unfriendRequest(friendID);
      }
      setState(() {
        isLoadBlock = false;
      });
      Navigator.pop(context);
      Navigator.pop(context);
      getBlockList();
      // Navigator.push(context, MaterialPageRoute(builder: (context) => FollowerScreen(),));
    }).catchError((e){
      print(e);
      setState(() {
        isLoadBlock = false;
      });
      Navigator.pop(context);
      Navigator.pop(context);
    });
  }
  unBlockUser(user,user1,user2){
    https.delete(
        Uri.parse("$serverUrl/user/api/BlockUser/$user/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      print(value.body.toString());
      //DatabaseMethods().unBlockChat(user1, user2);
      setState(() {
        isLoadBlock = false;
      });
      Navigator.pop(context);
      Navigator.pop(context);
      getBlockList();
    }).catchError((){
      setState(() {
        isLoadBlock = false;
      });
      Navigator.pop(context);
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the controller when not in use
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return loading == true ? Center(child: Text("Loading")) : Scaffold(
      key: scaffoldMessengerKey,
      resizeToAvoidBottomInset: true,
      body:  GestureDetector(
        onTap: (){
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
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
                    SizedBox(width: 10,),
                    Text("Comments",style: TextStyle(color: ascent,fontSize: 13,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                    Row(
                      children: [
                        IconButton(onPressed: (){
                          setState(() {
                            isSearch = !isSearch;
                          });
                          searchCommentText.clear();
                        }, icon: Icon(Icons.search,color: ascent,)),
                        PopupMenuButton(
                            icon: const Icon(Icons.tune,color: ascent,),
                            onSelected: (value) {
                              if (value == 0) {
                                print("recent clicked");
                                setState(() {
                                  mostRecentBool = true;
                                  myCommentsBool = false;
                                  recommendedBool = false;
                                  mostLikedBool = false;
                                  medalBool = false;
                                });
                                getRecentComments(widget.postid);
                              }
                              if (value == 1) {
                                print("filter clicked");
                                setState(() {
                                  mostRecentBool = false;
                                  myCommentsBool = true;
                                  recommendedBool = false;
                                  mostLikedBool = false;
                                  medalBool = false;
                                });
                                getMyComments(widget.postid);
                              }
                              if(value == 2){
                                print("recent clicked");
                                setState(() {
                                  mostRecentBool = false;
                                  myCommentsBool = false;
                                  recommendedBool = true;
                                  mostLikedBool = false;
                                  medalBool = false;
                                });
                                getComments(widget.postid);
                              }
                              if(value == 3){
                                print("most like clicked");
                                setState(() {
                                  mostRecentBool = false;
                                  myCommentsBool = false;
                                  recommendedBool = false;
                                  mostLikedBool = true;
                                  medalBool = false;
                                });
                                getMostLikedComments(widget.postid);
                              }
                              if(value == 4){
                                setState(() {
                                  mostRecentBool = false;
                                  myCommentsBool = false;
                                  recommendedBool = false;
                                  mostLikedBool = false;
                                  medalBool = true;
                                });
                                setState(() {
                                  comments = List.from(comments1.where((item) => item["topBadge"] != null));
                                  filterComments = List.from(comments1.where((item) => item["topBadge"] != null));
                                });
                              }
                              setState(() {});
                              print(value);
                            },
                            itemBuilder: (BuildContext bc) {
                              return [
                                PopupMenuItem(
                                  value: 0,
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "Most Recent",
                                        style: mostRecentBool == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 1,
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "My comments",
                                        style: myCommentsBool == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 2,
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "Recommended",
                                        style: recommendedBool == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 3,
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "Most Liked",
                                        style: mostLikedBool == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 4,
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "Medals",
                                        style: medalBool == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            }),
                      ],
                    )
                  ],
                ),
                if(isSearch == true) WidgetAnimator(
                  Container(
                    alignment: Alignment.bottomCenter,
                    width: MediaQuery.of(context).size.width,
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
                                  controller: searchCommentText,
                                  style: const TextStyle(color: ascent,fontFamily: Poppins,),
                                  cursorColor: ascent,
                                  onChanged: (value) {
                                    filterFriends(value);
                                  },
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
                Divider(color: Colors.grey,),
                loading == true
                    ? Expanded(
                  child: Column(
                    children: [
                      SizedBox(height: 100,),
                      SpinKitCircle(
                        color: primary,
                        size: 50,
                      ),
                    ],
                  ),
                )
                    : comments.isEmpty
                    ?
                (CommentSection(myComments.reversed.toList(),widget.scrollController)) : (filterComments.isEmpty ? (searchCommentText.text.isEmpty ? CommentSection(comments.reversed.toList(),widget.scrollController): Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 140,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("No Results",
                          style: TextStyle(
                            fontFamily: Poppins,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ))) : CommentSection(filterComments.reversed.toList(),widget.scrollController)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
         bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            height: isReply == true  ? 170 : (_searchResults.isNotEmpty ? 420 : 120),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WidgetAnimator(
                  Container(
                    alignment: Alignment.bottomCenter,
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          if(isReply == true) SizedBox(height: 10,),
                          isReply == true ? ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade900,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(" Replying to ${replyName}",style: TextStyle(fontFamily: Poppins,fontSize: 12)),
                                    GestureDetector(
                                        onTap: (){
                                          setState(() {
                                            isReply = false;
                                          });
                                        },
                                        child: Icon(Icons.close,size: 20,))
                                  ],
                                ),
                              ),
                            ),
                          ): SizedBox(),
                          if(isReply == true) SizedBox(height: 10,),
                          if(isReply == false) SizedBox(height: 10,),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.87,
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                      onTap: (){
                                        setState(() {
                                          comment.text = "${comment.text} ❤️";
                                          controller.text = "${controller.text} ❤️";
                                        });
                                      },
                                      child: const Text("❤️",style: TextStyle(fontSize: 20),)),
                                  //const SizedBox(width: 10,),
                                  GestureDetector(
                                      onTap: (){
                                        setState(() {
                                          comment.text = "${comment.text} 🙌";
                                          controller.text = "${controller.text} 🙌";
                                        });
                                      },
                                      child: const Text("🙌",style: TextStyle(fontSize: 20),)),
                                  // const SizedBox(width: 10,),
                                  GestureDetector(
                                      onTap: (){
                                        setState(() {
                                          comment.text = "${comment.text} 🔥";
                                          controller.text = "${controller.text} 🔥";
                                        });
                                      },
                                      child: const Text("🔥",style: TextStyle(fontSize: 20),)),
                                  // const SizedBox(width: 10,),
                                  GestureDetector(
                                      onTap: (){
                                        setState(() {
                                          comment.text = "${comment.text} 👏";
                                          controller.text = "${controller.text} 👏";
                                        });
                                      },
                                      child: const Text("👏",style: TextStyle(fontSize: 20),)),
                                  //  const SizedBox(width: 10,),
                                  GestureDetector(
                                      onTap: (){
                                        setState(() {
                                          comment.text = "${comment.text} 😢";
                                          controller.text = "${controller.text} 😢";
                                        });
                                      },
                                      child: const Text("😢",style: TextStyle(fontSize: 20),)),
                                  //const SizedBox(width: 10,),
                                  GestureDetector(
                                      onTap: (){
                                        setState(() {
                                          comment.text = "${comment.text} 😍";
                                          controller.text = "${controller.text} 😍";
                                        });
                                      },
                                      child: const Text("😍",style: TextStyle(fontSize: 20),)),
                                  //const SizedBox(width: 10,),
                                  GestureDetector(
                                      onTap: (){
                                        setState(() {
                                          comment.text = "${comment.text} 😮";
                                          controller.text = "${controller.text} 😮";
                                        });
                                      },
                                      child: const Text("😮",style: TextStyle(fontSize: 20),)),
                                  // const SizedBox(width: 10,),
                                  GestureDetector(
                                      onTap: (){
                                        setState(() {
                                          comment.text = "${comment.text} 😭";
                                          controller.text = "${controller.text} 😭";
                                        });
                                      },
                                      child: const Text("😭",style: TextStyle(fontSize: 20),)),
                                ]
                            ),
                          ),
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              const SizedBox(width: 10,),
                              CircleAvatar(
                                  backgroundColor: ascent,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                                    child: pic == null
                                        ? Image.network(
                                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                      width: 30,
                                      height: 30,
                                    )
                                        : CachedNetworkImage(
                                      imageUrl: pic,
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.black,
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
                                      errorWidget: (context, url, error) =>
                                      const Icon(Icons.person),
                                    ),
                                  )),
                              const SizedBox(width: 5,),
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.all(Radius.circular(25))
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child: KeyboardListener(
                                              onKeyboardOpened: () {
                                                print('Keyboard just opened');
                                                keyBoardOpen = true;
                                                // Adjust UI for keyboard
                                              },
                                              onKeyboardClosed: () {
                                                keyBoardOpen = false;
                                                print('Keyboard just closed');
                                                // Handle keyboard dismissal
                                              },
                                              onKeyboardAlreadyClosed: () {
                                                //_closeSuggestions();
                                                print('Keyboard is already closed when checked');
                                                // Perform actions when you know keyboard isn't visible
                                              },
                                              child: MentionTextField(
                                                focusNode: focusNode1,
                                                //focusNode: widget.textFieldFocusNode,
                                                forceCloseSuggestions: show,
                                                onSuggestionListToggle: () {
                                                  print("Suggestion list was toggled");
                                                },
                                                onSubmitted: comment.text.isNotEmpty == true ? (value) {
                                                  if(isReply == true) {
                                                    createCommentReply(commentID,controller.text);
                                                  }else {
                                                    createComment();
                                                  }
                                                } : null,
                                                textAlignVertical: TextAlignVertical.center,
                                                keyboardType: TextInputType.text,
                                                textCapitalization: TextCapitalization.sentences,
                                                textInputAction: TextInputAction.done,
                                                inputFormatters: <TextInputFormatter>[
                                                  UpperCaseTextFormatter(),
                                                  //NoLinksFormatter()
                                                ],
                                                maxLines: 1,
                                                minLines: 1,
                                                onChanged: (value){
                                                    setState(() {
                                                      comment.text = value;
                                                    });
                                                },
                                                style: const TextStyle(color: ascent,fontFamily: Poppins,fontSize: 12),
                                                cursorColor: ascent,
                                                controller: controller,
                                                decoration: const InputDecoration(
                                                    contentPadding:EdgeInsets.only(bottom: 15),
                                                    fillColor: ascent,
                                                    hintText: "Add a comment.",
                                                    hintStyle: TextStyle(
                                                      color: Colors.grey,
                                                      fontFamily: Poppins,
                                                      fontSize: 12,
                                                    ),
                                                    border: InputBorder.none
                                                ),
                                              ),
                                            )
                                        ),
                                        const SizedBox(width: 10,),
                                        if(comment.text.isNotEmpty == false) isReply == true ? GestureDetector(
                                            onTap: () async {
                                              final gif = await GiphyPicker.pickGif(
                                                draggableController: _draggableController,
                                                context: context,
                                                apiKey: giphyKey,
                                                  showPreviewPage: false,
                                                  previewType: GiphyPreviewType.originalStill,
                                              );
                                              if (gif != null) {
                                                setState(() {
                                                  _gif = gif;
                                                  debugPrint("gif link==========>${_gif?.images.original?.url}");
                                                });
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text('GIF Selected',style: TextStyle(fontFamily: Poppins)),
                                                      content: _gif?.images.original?.url != null
                                                          ? Image(image: NetworkImage(_gif!.images.original!.url!))
                                                          : const Text('No GIF URL available',style: TextStyle(fontFamily: Poppins)),
                                                      actions: <Widget>[
                                                        IconButton(icon: const Icon(Icons.send), onPressed: () {
                                                          createCommentReply(commentID,comment.text);
                                                          Navigator.of(context).pop();
                                                        },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                            child: Image.asset("assets/gifpic.png",height: 20,width: 20,)) :
                                        GestureDetector(
                                            onTap: () async {
                                              final gif = await GiphyPicker.pickGif(
                                                draggableController: _draggableController,
                                                context: context,
                                                apiKey: giphyKey,
                                                showPreviewPage: false,
                                                  previewType: GiphyPreviewType.originalStill,
                                              );
                                              if (gif != null) {
                                                setState(() {
                                                  _gif = gif;
                                                  debugPrint("gif link==========>${_gif?.images.original?.url}");
                                                });
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text('GIF Selected',style: TextStyle(fontFamily: Poppins),),
                                                      content: _gif?.images.original?.url != null
                                                          ? Image(image: NetworkImage(_gif!.images.original!.url!))
                                                          : const Text('No GIF URL available',style: TextStyle(fontFamily: Poppins),),
                                                      actions: <Widget>[
                                                        IconButton(icon: const Icon(Icons.send), onPressed: () {
                                                          createComment();
                                                          Navigator.of(context).pop();
                                                        },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                            child: Image.asset("assets/gifpic.png",height: 20,width: 20,)),
                                        if(comment.text.isNotEmpty == true) Padding(
                                          padding: const EdgeInsets.only(right:8.0),
                                          child: GestureDetector(
                                            onTap: controller.text.isNotEmpty == true ? () {
                                              if(isReply == true) {
                                                createCommentReply(commentID,controller.text);
                                              }else {
                                                createComment();
                                              }
                                            }:null,
                                            child: Container(
                                                height: 30,
                                                width: 30,
                                                decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                        colors: comment.text.isNotEmpty == true ? [
                                                          primary,
                                                          primary,
                                                        ]: [
                                                          Colors.grey,
                                                          Colors.grey
                                                        ],
                                                        begin: FractionalOffset.topLeft,
                                                        end: FractionalOffset.bottomRight
                                                    ),
                                                    borderRadius: BorderRadius.circular(40)
                                                ),
                                                padding: const EdgeInsets.only(left:4),
                                                child: Center(child: Icon(Icons.send,color: ascent,))
                                            ),
                                          ),
                                        ),
                                        if(comment.text.isNotEmpty == false) SizedBox(width: 10,),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10,),
                            ],
                          ),
                          if (_searchResults.isNotEmpty) Container(
                            height: 150,
                            child: ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: Container(
                                    height: 30,
                                    width: 30,
                                    decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.all(Radius.circular(50)),
                                        image: DecorationImage(
                                            image: NetworkImage(
                                                _searchResults[index]["pic"]
                                            ),
                                            fit: BoxFit.cover
                                        )
                                    ),
                                    child: Text(""),
                                  ),
                                  title: Text(_searchResults[index]["username"]),
                                  onTap: () {
                                    final text = comment.text;
                                    final mentionText = _searchResults[index]["username"];
                                    final newText = text.replaceRange(
                                      text.lastIndexOf('@'),
                                      text.length,
                                      '@$mentionText ',
                                    );
                                    comment.text = newText;
                                    comment.selection = TextSelection.fromPosition(
                                      TextPosition(offset: comment.text.length),
                                    );
                                    mentions.add(_searchResults[index]["id"]);
                                    setState(() => _searchResults.clear());
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget highlightSearchText(String text, String query, bool isEdited, BuildContext context) {
    if (query.isEmpty) {
      return RichText(
        text: TextSpan(
          children: buildTextSpans(text, query, context),
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white, // Default text color
            fontSize: 12,
          ),
        ),
      );
    }

    List<TextSpan> spans = buildHighlightedText(text, query, context);

    // Append "(edited)" if needed
    if (isEdited) {
      spans.add(TextSpan(
        text: " (edited)",
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.grey,
          fontSize: 14,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

// Detects @mentions and makes them clickable
  List<TextSpan> buildTextSpans(String text, String query, BuildContext context) {
    List<TextSpan> spans = [];
    RegExp mentionExp = RegExp(r"@\w+"); // Matches "@username"
    int lastIndex = 0;

    Iterable<Match> matches = mentionExp.allMatches(text);

    for (Match match in matches) {
      String mentionText = match.group(0)!; // Extract "@username"

      // Add normal text before the mention
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white, // Normal text color
            fontSize: 14,
          ),
        ));
      }

      // Add colored @mention with click functionality
      spans.add(TextSpan(
        text: mentionText,
        style: TextStyle(
          fontFamily: 'Poppins',
          color: secondary, // Mention color
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            // var id = mentionMember.firstWhere((map) => map.name == mentionText.split("@")[1]).id;
            MentionMemberModel? match;
            String id;
            try {
              match = mentionMember2.firstWhere((map) => map.name == mentionText.split("@")[1]);
            } catch (e) {
              match = null;
            }

            if (match != null) {
              id = match.id;
              // Use the id
            } else {
              id = "";
              // Handle not found
            }
            //print("Mentioned => ${mentionMember.firstWhere((map) => map.name == mentionText.split("@")[1]).id}");
            print("Mentioned id => ${id}");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FriendProfileScreen(id: id, username: mentionText.split("@")[1]),
              ),
            );
          },
      ));

      lastIndex = match.end;
    }

    // Add remaining text after last mention
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 14,
        ),
      ));
    }

    return spans;
  }

// Handles highlighting query text within the main text
  List<TextSpan> buildHighlightedText(String text, String query, BuildContext context) {
    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    int startIndex = 0;

    while (true) {
      int matchIndex = lowerText.indexOf(lowerQuery, startIndex);
      if (matchIndex == -1) {
        spans.addAll(buildTextSpans(text.substring(startIndex), query, context));
        break;
      }

      // Add normal text before the match
      spans.addAll(buildTextSpans(text.substring(startIndex, matchIndex), query, context));

      // Add highlighted text
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + query.length),
        style: TextStyle(
          fontFamily: 'Poppins',
          color: secondary, // Highlight color for search text
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ));

      startIndex = matchIndex + query.length;
    }

    return spans;
  }


  Expanded CommentSection(comments,scrollCont) {
    return  comments.isEmpty == true ? Expanded(child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 170,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("No Comments",
              style: TextStyle(
                fontFamily: Poppins,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    )) : Expanded(
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is UserScrollNotification) {
              if (scrollNotification.direction == ScrollDirection.forward) {
                print("Scrolling up");
                focusNode.unfocus();
                FocusScope.of(context).unfocus();
              } else if (scrollNotification.direction == ScrollDirection.reverse) {
                print("Scrolling down");
                focusNode.unfocus();
                FocusScope.of(context).unfocus();
              }
            }
            return false;
          },
          child: ListView.builder(
              controller:scrollCont,
            shrinkWrap: true,
              itemCount: comments.length,
              itemBuilder: (context, index) {
                //var reversedComments = comments.reversed.toList();
                bool isEdited = isCommentEdited(comments[index]['created'], comments[index]['updated']);
                String commentText = comments[index]['comment'] + (isEdited ? " (edited)" : "");
                return GestureDetector(
                  onTap: (){
                    FocusScope.of(context).unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left:10.0,top: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onLongPress: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(left:MediaQuery.of(context).size.width * 0.05,right:MediaQuery.of(context).size.width * 0.05),
                                      child: AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(10))
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: (){
                                                Clipboard.setData(ClipboardData(text: comments[index]['comment']));
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("Comment copied to clipboard!")),
                                                );
                                              },
                                              child: Container(
                                                height: 30,
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text("Copy Comment",style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w200,
                                                        color: ascent,
                                                        fontFamily: Poppins
                                                    ),),
                                                    Icon(Icons.copy,size: 25,color: ascent,)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 10,),
                                            // if(comments[index]['user']['id'].toString() == id) InkWell(
                                            //   onTap: (){
                                            //     Navigator.pop(context);
                                            //     showDialog(
                                            //         context: context,
                                            //         builder: (context) {
                                            //           return AlertDialog(
                                            //             title: Row(
                                            //               children: [
                                            //                 CircleAvatar(
                                            //                     backgroundColor: Colors.black,
                                            //                     child: ClipRRect(
                                            //                       borderRadius: const BorderRadius.all(
                                            //                           Radius.circular(50)),
                                            //                       child: comments[index]["user"]
                                            //                       ["pic"] ==
                                            //                           null
                                            //                           ? Image.network(
                                            //                         "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                            //                         width: 40,
                                            //                         height: 40,
                                            //                       )
                                            //                           : CachedNetworkImage(
                                            //                         imageUrl:
                                            //                         comments[index]
                                            //                         ["user"]["pic"],
                                            //                         imageBuilder: (context,
                                            //                             imageProvider) =>
                                            //                             Container(
                                            //                               height: 100,
                                            //                               width: 100,
                                            //                               decoration:
                                            //                               BoxDecoration(
                                            //                                 image:
                                            //                                 DecorationImage(
                                            //                                   image:
                                            //                                   imageProvider,
                                            //                                   fit: BoxFit.cover,
                                            //                                 ),
                                            //                               ),
                                            //                             ),
                                            //                         placeholder: (context,
                                            //                             url) =>
                                            //                             Center(
                                            //                                 child:
                                            //                                 SpinKitCircle(
                                            //                                   color: primary,
                                            //                                   size: 10,
                                            //                                 )),
                                            //                         errorWidget: (context,
                                            //                             url, error) =>
                                            //                             ClipRRect(
                                            //                               borderRadius:
                                            //                               const BorderRadius.all(
                                            //                                   Radius
                                            //                                       .circular(
                                            //                                       50)),
                                            //                               child: Image.network(
                                            //                                 "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                            //                                 width: 40,
                                            //                                 height: 40,
                                            //                               ),
                                            //                             ),
                                            //                       ),
                                            //                     )),
                                            //                 const SizedBox(width: 4,),
                                            //                 const Text(
                                            //                     'Edit comment.', style: TextStyle(
                                            //                     fontFamily: Poppins)),
                                            //               ],
                                            //             ),
                                            //             content:
                                            //             AutoSizeTextField(
                                            //               onChanged:
                                            //                   (value) {
                                            //                 setState(() {});
                                            //               },
                                            //               controller:
                                            //               editController,
                                            //               decoration:
                                            //               const InputDecoration(
                                            //                   hintStyle: TextStyle(fontFamily: Poppins),
                                            //                   hintText:
                                            //                   "Write comment here.",labelStyle: TextStyle(fontFamily: Poppins)),
                                            //               cursorColor: primary,
                                            //               maxLength: 2500,
                                            //             ),
                                            //             actions: <Widget>[
                                            //               MaterialButton(
                                            //                 shape: RoundedRectangleBorder(
                                            //                   borderRadius: BorderRadius.circular(30), // Adjust the radius as needed
                                            //                 ),
                                            //                 color: ascent,
                                            //                 textColor:
                                            //                 ascent,
                                            //
                                            //                 child:  Icon(
                                            //                     Icons.send,
                                            //
                                            //                     color:
                                            //                     primary),
                                            //                 onPressed: () {
                                            //                   setState(() {
                                            //                     print(
                                            //                         "comment content${replyController.text}");
                                            //                     Navigator.pop(
                                            //                         context);
                                            //                     editComment(
                                            //                         comments[index]
                                            //                         [
                                            //                         'id'],comments[index]['fashion']);
                                            //                     editController
                                            //                         .clear();
                                            //                   });
                                            //                 },
                                            //               ),
                                            //             ],
                                            //           );
                                            //         });
                                            //   },
                                            //   child: Container(
                                            //     height: 30,
                                            //     child: Row(
                                            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            //       crossAxisAlignment: CrossAxisAlignment.start,
                                            //       children: [
                                            //         Text("Edit Comment",style: TextStyle(
                                            //             fontSize: 16,
                                            //             fontWeight: FontWeight.w200,
                                            //             color: ascent,
                                            //             fontFamily: Poppins
                                            //         ),),
                                            //         Icon(Icons.edit,size: 25,color: ascent,),
                                            //       ],
                                            //     ),
                                            //   ),
                                            // ),
                                            if(comments[index]['user']['id'].toString() == id) SizedBox(height: 10,),
                                            if(widget.userID.toString() == id || comments[index]['user']['id'].toString() == id) InkWell(
                                              onTap: (){
                                                Navigator.pop(context);
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    backgroundColor: primary,
                                                    title: const Text(
                                                      "Delete Comment",
                                                      style: TextStyle(
                                                          color: ascent,
                                                          fontFamily: Poppins,
                                                          fontWeight: FontWeight.bold),
                                                    ),
                                                    content: Text(
                                                      comments[index]['user']['id'].toString() == id ? "Are you sure you want to delete your comment?" :"Are you sure you want to delete the comment by ${comments[index]['user']["username"]}?",
                                                      style: TextStyle(color: ascent, fontFamily: Poppins),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        child: const Text("Cancel",
                                                            style: TextStyle(color: ascent, fontFamily: Poppins)),
                                                        onPressed: () {
                                                          setState(() {
                                                            Navigator.pop(context);
                                                          });
                                                        },
                                                      ),
                                                      TextButton(
                                                        child: const Text("Delete",
                                                            style: TextStyle(color: ascent, fontFamily: Poppins)),
                                                        onPressed: () {
                                                          //print("comment id -> "+comments[index]['id'].toString());
                                                          setState(() {
                                                            moreReply[index] = false;
                                                          });
                                                          deleteComment(comments[index]['id']);
                                                        },
                                                      )
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                height: 30,
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text("Delete Comment",style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w200,
                                                        color: Colors.red,
                                                        fontFamily: Poppins
                                                    ),),
                                                    Icon(Icons.delete,size: 25,color: Colors.red)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if(widget.userID.toString() == id || comments[index]['user']['id'].toString() == id) SizedBox(height: 10,),
                                            if(comments[index]['user']['id'].toString() != id) InkWell(
                                              onTap: (){
                                                Navigator.pop(context);
                                                Navigator.push(context,MaterialPageRoute(builder: (context) =>  ReportCommentScreen(commentId: comments[index]['id']),));
                                              },
                                              child: Container(
                                                height: 30,
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text("Report Comment",style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w200,
                                                        color: Colors.red,
                                                        fontFamily: Poppins
                                                    ),),
                                                    Icon(Icons.report_gmailerrorred,size: 25,color: Colors.red,)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if(comments[index]['user']['id'].toString() != id) SizedBox(height: 10,),
                                            if(comments[index]['user']['id'].toString() != id) InkWell(
                                              onTap: blockList.contains(comments[index]['user']['id']) == true ? (){
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => StatefulBuilder(
                                                      builder: (context,setState) {
                                                        return AlertDialog(
                                                          backgroundColor: primary,
                                                          title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                                          content: const Text("Do you want to unblock this user?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                                          actions: [
                                                            TextButton(
                                                              child: isLoadBlock == true ? SpinKitCircle(color: ascent,) : const Text("Yes",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                                              onPressed:  () {
                                                                //print(data["id"].toString());
                                                                setState(() {
                                                                  isLoadBlock = true;
                                                                });
                                                                unBlockUser(comments[index]['user']['id'], name, comments[index]['user']['name']);
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
                                                        );
                                                      }
                                                  ),
                                                );
                                              }:(){
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => StatefulBuilder(
                                                      builder: (context,setState) {
                                                        return AlertDialog(
                                                          backgroundColor: primary,
                                                          title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                                          content: const Text("Do you want to block this user?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                                          actions: [
                                                            TextButton(
                                                              child: isLoadBlock == true ? SpinKitCircle(color: ascent,) : const Text("Yes",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                                              onPressed:  () {
                                                                //print(data["id"].toString());
                                                                setState(() {
                                                                  isLoadBlock = true;
                                                                });
                                                                matchFriendReques(
                                                                    comments[index]['user']['id'],
                                                                    comments[index]['user']['id'],
                                                                    name,
                                                                    comments[index]['user']['name'],
                                                                    index,
                                                                    List<int>.from(comments[index]["fansList"]),
                                                                    comments[index]['user']['id']
                                                                );
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
                                                        );
                                                      }
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                height: 30,
                                                child: blockList.contains(comments[index]['user']['id']) == true ? Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text("Unblock User",style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w200,
                                                        color: ascent,
                                                        fontFamily: Poppins
                                                    ),),
                                                    Icon(Icons.block,size: 25,color: Colors.grey,)
                                                  ],
                                                ) : Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text("Block User",style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w200,
                                                        color: Colors.red,
                                                        fontFamily: Poppins
                                                    ),),
                                                    Icon(Icons.block,size: 25,color: Colors.red,)
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if(comments[index]["topBadge"] != null) InkWell(
                                      onTap:(){
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => EventPosts(
                                          userid: comments[index]["user"]["id"].toString(),
                                        )));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(top:6.0),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(120)),
                                          child: CachedNetworkImage(
                                            imageUrl: comments[index]["topBadge"]["document"],
                                            //imageUrl: lowestRankingOrderDocument,
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                Container(
                                                  height: 30,
                                                  width: 30,
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
                                                Padding(
                                                  padding: const EdgeInsets.only(top:6.0),
                                                  child: SpinKitCircle(
                                                    color: primary,
                                                    size: 20,
                                                  ),
                                                ),
                                            errorWidget: (context, url,
                                                error) =>
                                                ClipRRect(
                                                    borderRadius:
                                                    const BorderRadius.all(
                                                        Radius.circular(50)),
                                                    child: Image.network(
                                                      comments[index]["topBadge"]["document"],
                                                      width: 30,
                                                      height: 30,
                                                      fit: BoxFit.contain,
                                                    )),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5,),
                                    if(myList.contains(int.parse(comments[index]["user"]["id"].toString())) == false) comments[index]["user"]["show_stories_to_non_friends"] == true ? GestureDetector(
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                          id: comments[index]['user']['id'].toString(),
                                          username: comments[index]["user"]["username"],
                                        )));
                                      },
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap:(comments[index]["recent_stories"].length <= 0) ? (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                id: comments[index]["user"]["id"].toString(),
                                                username: comments[index]["user"]["username"],
                                              )));
                                            }: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                storyList: List<Story>.from(comments[index]["recent_stories"].map((e){
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
                                                getComments(widget.postid);
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: comments[index]["recent_stories"].length > 0 ?
                                                (comments[index]["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.topRight,
                                                    stops: const [0.0, 0.7],
                                                    tileMode: TileMode.clamp,
                                                    colors: <Color>[
                                                      Colors.grey,
                                                      Colors.grey,
                                                    ]) :
                                                (comments[index]["recent_stories"].any((story) => story["close_friends_only"] == true) ? LinearGradient(
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
                                                      Colors.transparent,
                                                      Colors.transparent,
                                                    ]),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(3.0),
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        color: Color(0xFF121212),
                                                        borderRadius: const BorderRadius.all(Radius.circular(120))
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(3.0),
                                                      child: ClipRRect(
                                                        borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                        child: comments[index]["user"]
                                                        ["pic"] ==
                                                            null
                                                            ? Image.network(
                                                          "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                          width: 40,
                                                          height: 40,
                                                        )
                                                            : CachedNetworkImage(
                                                          imageUrl:
                                                          comments[index]
                                                          ["user"]["pic"],
                                                          imageBuilder: (context,
                                                              imageProvider) =>
                                                              Container(
                                                                height: 40,
                                                                width: 40,
                                                                decoration:
                                                                BoxDecoration(
                                                                  image:
                                                                  DecorationImage(
                                                                    image:
                                                                    imageProvider,
                                                                    fit: BoxFit.cover,
                                                                  ),
                                                                ),
                                                              ),
                                                          placeholder: (context,
                                                              url) =>
                                                              Center(
                                                                  child:
                                                                  SpinKitCircle(
                                                                    color: primary,
                                                                    size: 10,
                                                                  )),
                                                          errorWidget: (context,
                                                              url, error) =>
                                                              ClipRRect(
                                                                borderRadius:
                                                                const BorderRadius.all(
                                                                    Radius
                                                                        .circular(
                                                                        50)),
                                                                child: Image.network(
                                                                  "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                  width: 40,
                                                                  height: 40,
                                                                ),
                                                              ),
                                                        ),
                                                      ),
                                                    )),
                                              ),
                                            ),
                                          ),
                                          comments[index]['comment'].toString().startsWith("https://media")?SizedBox(height: 150,):SizedBox(height: 20,)
                                        ],
                                      ),
                                    ):(
                                        (comments[index]["user"]["followList"].contains(int.parse(id)) == true || comments[index]["fansList"].contains(int.parse(id)) == true) ?
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                              id: comments[index]['user']['id'].toString(),
                                              username: comments[index]["user"]["username"],
                                            )));
                                          },
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              GestureDetector(
                                                onTap:(comments[index]["recent_stories"].length <= 0) ? (){
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                    id: comments[index]["user"]["id"].toString(),
                                                    username: comments[index]["user"]["username"],
                                                  )));
                                                }: (){
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                                    storyList: List<Story>.from(comments[index]["recent_stories"].map((e){
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
                                                    getComments(widget.postid);
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: comments[index]["recent_stories"].length > 0 ?
                                                    (comments[index]["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.topRight,
                                                        stops: const [0.0, 0.7],
                                                        tileMode: TileMode.clamp,
                                                        colors: <Color>[
                                                          Colors.grey,
                                                          Colors.grey,
                                                        ]) :
                                                    (comments[index]["recent_stories"].any((story) => story["close_friends_only"] == true) ? LinearGradient(
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
                                                          Colors.transparent,
                                                          Colors.transparent,
                                                        ]),
                                                  ),
                                                  child: CircleAvatar(
                                                      backgroundColor: Color(0xFF121212),
                                                      child: ClipRRect(
                                                        borderRadius: const BorderRadius.all(
                                                            Radius.circular(50)),
                                                        child: comments[index]["user"]
                                                        ["pic"] ==
                                                            null
                                                            ? Image.network(
                                                          "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                          width: 40,
                                                          height: 40,
                                                        )
                                                            : CachedNetworkImage(
                                                          imageUrl:
                                                          comments[index]
                                                          ["user"]["pic"],
                                                          imageBuilder: (context,
                                                              imageProvider) =>
                                                              Container(
                                                                height: 40,
                                                                width: 40,
                                                                decoration:
                                                                BoxDecoration(
                                                                  image:
                                                                  DecorationImage(
                                                                    image:
                                                                    imageProvider,
                                                                    fit: BoxFit.cover,
                                                                  ),
                                                                ),
                                                              ),
                                                          placeholder: (context,
                                                              url) =>
                                                              Center(
                                                                  child:
                                                                  SpinKitCircle(
                                                                    color: primary,
                                                                    size: 10,
                                                                  )),
                                                          errorWidget: (context,
                                                              url, error) =>
                                                              ClipRRect(
                                                                borderRadius:
                                                                const BorderRadius.all(
                                                                    Radius
                                                                        .circular(
                                                                        50)),
                                                                child: Image.network(
                                                                  "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                  width: 40,
                                                                  height: 40,
                                                                ),
                                                              ),
                                                        ),
                                                      )),
                                                ),
                                              ),
                                              comments[index]['comment'].toString().startsWith("https://media")?SizedBox(height: 150,):SizedBox(height: 20,)
                                            ],
                                          ),
                                        ):
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                              id: comments[index]['user']['id'].toString(),
                                              username: comments[index]["user"]["username"],
                                            )));
                                          },
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              GestureDetector(
                                                onTap:(){
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                    id: comments[index]["user"]["id"].toString(),
                                                    username: comments[index]["user"]["username"],
                                                  )));
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: const BorderRadius.all(
                                                        Radius.circular(50)),
                                                  ),
                                                  child: CircleAvatar(
                                                      backgroundColor: Color(0xFF121212),
                                                      child: ClipRRect(
                                                        borderRadius: const BorderRadius.all(
                                                            Radius.circular(50)),
                                                        child: comments[index]["user"]
                                                        ["pic"] ==
                                                            null
                                                            ? Image.network(
                                                          "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                          width: 40,
                                                          height: 40,
                                                        )
                                                            : CachedNetworkImage(
                                                          imageUrl:
                                                          comments[index]
                                                          ["user"]["pic"],
                                                          imageBuilder: (context,
                                                              imageProvider) =>
                                                              Container(
                                                                height: 40,
                                                                width: 40,
                                                                decoration:
                                                                BoxDecoration(
                                                                  image:
                                                                  DecorationImage(
                                                                    image:
                                                                    imageProvider,
                                                                    fit: BoxFit.cover,
                                                                  ),
                                                                ),
                                                              ),
                                                          placeholder: (context,
                                                              url) =>
                                                              Center(
                                                                  child:
                                                                  SpinKitCircle(
                                                                    color: primary,
                                                                    size: 10,
                                                                  )),
                                                          errorWidget: (context,
                                                              url, error) =>
                                                              ClipRRect(
                                                                borderRadius:
                                                                const BorderRadius.all(
                                                                    Radius
                                                                        .circular(
                                                                        50)),
                                                                child: Image.network(
                                                                  "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                  width: 40,
                                                                  height: 40,
                                                                ),
                                                              ),
                                                        ),
                                                      )),
                                                ),
                                              ),
                                              comments[index]['comment'].toString().startsWith("https://media")?SizedBox(height: 150,):SizedBox(height: 20,)
                                            ],
                                          ),
                                        )
                                    ),
                                    if(myList.contains(int.parse(comments[index]["user"]["id"].toString())) == true)
                                      GestureDetector(
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                          id: comments[index]['user']['id'].toString(),
                                          username: comments[index]["user"]["username"],
                                        )));
                                      },
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap:(){
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                id: comments[index]["user"]["id"].toString(),
                                                username: comments[index]["user"]["username"],
                                              )));
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: const BorderRadius.all(
                                                    Radius.circular(50)),
                                                // border: Border.all(
                                                //     width: 1.5,
                                                //     color:
                                                //     Colors.transparent),
                                                // gradient: (comments[index]["recent_stories"].length <= 0) ? null :(comments[index]["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                                //     begin: Alignment.topLeft,
                                                //     end: Alignment.topRight,
                                                //     stops: const [0.0, 0.7],
                                                //     tileMode: TileMode.clamp,
                                                //     colors: <Color>[
                                                //       Colors.grey,
                                                //       Colors.grey,
                                                //     ]) :
                                                // (comments[index]["close_friends"].contains(int.parse(id)) == true ? (comments[index]["recent_stories"].any((story) => story["close_friends_only"] == true) ?LinearGradient(
                                                //     begin: Alignment.topLeft,
                                                //     end: Alignment.topRight,
                                                //     stops: const [0.0, 0.7],
                                                //     tileMode: TileMode.clamp,
                                                //     colors: <Color>[
                                                //       Colors.deepPurple,
                                                //       Colors.purpleAccent,
                                                //     ]):
                                                // LinearGradient(
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
                                                  backgroundColor: Color(0xFF121212),
                                                  child: ClipRRect(
                                                    borderRadius: const BorderRadius.all(
                                                        Radius.circular(50)),
                                                    child: comments[index]["user"]
                                                    ["pic"] ==
                                                        null
                                                        ? Image.network(
                                                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                      width: 40,
                                                      height: 40,
                                                    )
                                                        : CachedNetworkImage(
                                                      imageUrl:
                                                      comments[index]
                                                      ["user"]["pic"],
                                                      imageBuilder: (context,
                                                          imageProvider) =>
                                                          Container(
                                                            height: 40,
                                                            width: 40,
                                                            decoration:
                                                            BoxDecoration(
                                                              image:
                                                              DecorationImage(
                                                                image:
                                                                imageProvider,
                                                                fit: BoxFit.cover,
                                                              ),
                                                            ),
                                                          ),
                                                      placeholder: (context,
                                                          url) =>
                                                          Center(
                                                              child:
                                                              SpinKitCircle(
                                                                color: primary,
                                                                size: 10,
                                                              )),
                                                      errorWidget: (context,
                                                          url, error) =>
                                                          ClipRRect(
                                                            borderRadius:
                                                            const BorderRadius.all(
                                                                Radius
                                                                    .circular(
                                                                    50)),
                                                            child: Image.network(
                                                              "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                              width: 40,
                                                              height: 40,
                                                            ),
                                                          ),
                                                    ),
                                                  )),
                                            ),
                                          ),
                                          comments[index]['comment'].toString().startsWith("https://media")?SizedBox(height: 150,):SizedBox(height: 20,)
                                        ],
                                      ),
                                    ),
                                      SizedBox(width: 5,),
                                    GestureDetector(
                                      onTap: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                          id: comments[index]["user"]["id"].toString(),
                                          username: comments[index]["user"]["username"],
                                        )));
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                  comments[index]["user"]["username"],
                                                  style: const TextStyle(
                                                      fontFamily: Poppins,
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 16
                                                  )),
                                              SizedBox(width: 5,),
                                              Text(formatTimeDifference(comments[index]['created']),style: const TextStyle(
                                                  fontFamily: Poppins,
                                                  fontSize: 12,
                                                  color: Colors.grey
                                              ),),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              GestureDetector(
                                                  child: comments[index]['comment'].toString().startsWith("https://media")?
                                                  buildGifWidget(context, comments[index]['comment'].toString())
                                                      :
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: MediaQuery.of(context).size.width * 0.6,
                                                        child: highlightSearchText(comments[index]["comment"], searchCommentText.text, isEdited,context),
                                                      ),
                                                    ],
                                                  ),
                                              ),
                                              const SizedBox(
                                                height: 4,
                                              ),
                                              Row(
                                                children: [
                                                  InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          isReply = true;
                                                        });
                                                        commentID = comments[index]["id"];
                                                        replyName = comments[index]['user']['username'];
                                                        controller.text = "@${comments[index]['user']['username']} ";
                                                        comment.text = "@${comments[index]['user']['username']} ";
                                                        print("Comment ID -> ${commentID}");
                                                      },
                                                      child: Text(
                                                        "reply",
                                                        style: TextStyle(
                                                          fontFamily: Poppins,
                                                          fontWeight:
                                                          FontWeight.w400,
                                                          color: primary,
                                                        ),
                                                      )),
                                                  const SizedBox(width: 5,),
                                                  const SizedBox(width: 4,),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: comments[index]["hasLiked"] == true ? (){
                                setState(() {
                                  comments[index]["hasLiked"] = false;
                                  comments[index]["likeCommentsCount"]--;
                                });
                                unlikeComment(comments[index]['id']);
                              } :(){
                                setState(() {
                                  comments[index]["hasLiked"] = true;
                                  comments[index]["likeCommentsCount"]++;
                                });
                                likeComment(comments[index]['id']);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10.0,right: 15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 20,),
                                    comments[index]["hasLiked"] == true ?
                                    Column(
                                      children: [
                                        widget.isEventPost == true ? Icon(
                                          Icons.favorite,color: Colors.red,size: 20,
                                        ): Icon(
                                          Icons.star,color: Colors.orange,size: 20,
                                        ),
                                        SizedBox(height: 5,),
                                        Text("${comments[index]["likeCommentsCount"]}",style: TextStyle(color: Colors.grey,fontSize: 10,fontFamily: Poppins,),),
                                      ],
                                    ):
                                    Column(
                                      children: [
                                        widget.isEventPost == true ? Icon(
                                          Icons.favorite_border,color: Colors.grey,size: 20,
                                        ): Icon(
                                          Icons.star_border,color: Colors.grey,size: 20,
                                        ),
                                        SizedBox(height: 5,),
                                        Text("${comments[index]["likeCommentsCount"]}",style: TextStyle(color: Colors.grey,fontSize: 10,fontFamily: Poppins,),),
                                      ],
                                    ),
                                    SizedBox(height: 20,),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        moreReply[index] == true ? Column(
                          children: [
                            Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                child: replySection(comments[index]["replies"].reversed.toList(), comments[index]["id"], index)),
                            // Check if there are more replies to show
                            repliesShownCount[index] < comments[index]["replies"].length
                                ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  repliesShownCount[index] += 3; // Increment by 3
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("View ${comments[index]["replies"].length - repliesShownCount[index]} more ${(comments[index]["replies"].length - repliesShownCount[index]) == 1 ? "reply" : "replies"}",
                                    style: TextStyle(
                                      fontFamily: Poppins,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : GestureDetector(
                              onTap: () {
                                setState(() {
                                  moreReply[index] = false; // Collapse the replies
                                  repliesShownCount[index] = 5;
                                  closeReplyAndScrollToComment(index); // Reset to initial
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Close all replies",
                                    style: TextStyle(
                                      fontFamily: Poppins,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ) :
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              moreReply[index] = true; // Show replies
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              comments[index]["replyCommentsCount"] <= 0
                                  ? const SizedBox()
                                  : Text(comments[index]["replyCommentsCount"] == 1
                                  ? "View ${comments[index]["replyCommentsCount"]} reply"
                                  : "View ${comments[index]["replyCommentsCount"]} replies",
                                style: TextStyle(
                                  fontFamily: Poppins,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10,)
                    ],
                    ),
                  ),
                );

              }),
        ),
      );
  }
  ListView replySection(comments,comment_id,int replyIndex) {
    return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: comments.length < repliesShownCount[replyIndex]
            ? comments.length
            : repliesShownCount[replyIndex],
        itemBuilder: (context, index) {
          bool isEdited = isCommentEdited(comments[index]['created'], comments[index]['updated']);
          String commentText = comments[index]['comment'] +
              (isEdited ? " (edited)" : "");
          return Padding(
            padding: const EdgeInsets.only(top: 10.0,bottom: 10,left: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(left:MediaQuery.of(context).size.width * 0.05,right:MediaQuery.of(context).size.width * 0.05),
                          child: AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: (){
                                    Clipboard.setData(ClipboardData(text: comments[index]['comment']));
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Comment copied to clipboard!")),
                                    );
                                  },
                                  child: Container(
                                    height: 30,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Copy Comment",style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w200,
                                            color: ascent,
                                            fontFamily: Poppins
                                        ),),
                                        Icon(Icons.copy,size: 25,color: ascent,)
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10,),
                                if(comments[index]['user']['id'].toString() == id) SizedBox(height: 10,),
                                if(widget.userID.toString() == id || comments[index]['user']['id'].toString() == id) InkWell(
                                  onTap: (){
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: primary,
                                        title: const Text(
                                          "Delete Reply",
                                          style: TextStyle(
                                              color: ascent,
                                              fontFamily: Poppins,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        content: Text(
                                          comments[index]['user']['id'].toString() == id ? "Are you sure you want to delete your reply?" :"Are you sure you want to delete the reply by ${comments[index]['user']["username"]}?",
                                          style: TextStyle(color: ascent, fontFamily: Poppins),
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text("Cancel",
                                                style: TextStyle(color: ascent, fontFamily: Poppins)),
                                            onPressed: () {
                                              setState(() {
                                                Navigator.pop(context);
                                              });
                                            },
                                          ),
                                          TextButton(
                                            child: const Text("Delete",
                                                style: TextStyle(color: ascent, fontFamily: Poppins)),
                                            onPressed: () {
                                              //print("comment id -> "+comments[index]['id'].toString());
                                              setState(() {
                                                moreReply[index] = false;
                                              });
                                              deleteComment(comments[index]['id']);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 30,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Delete Reply",style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w200,
                                            color: Colors.red,
                                            fontFamily: Poppins
                                        ),),
                                        Icon(Icons.delete,size: 25,color: Colors.red)
                                      ],
                                    ),
                                  ),
                                ),
                                if(widget.userID.toString() == id || comments[index]['user']['id'].toString() == id) SizedBox(height: 10,),
                                if(comments[index]['user']['id'].toString() != id)InkWell(
                                  onTap: (){
                                    Navigator.pop(context);
                                    Navigator.push(context,MaterialPageRoute(builder: (context) =>  ReportCommentScreen(commentId: comments[index]['id']),));
                                  },
                                  child: Container(
                                    height: 30,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Report Reply",style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w200,
                                            color: Colors.red,
                                            fontFamily: Poppins
                                        ),),
                                        Icon(Icons.report_gmailerrorred,size: 25,color: Colors.red,)
                                      ],
                                    ),
                                  ),
                                ),
                                if(comments[index]['user']['id'].toString() != id)SizedBox(height: 10,),
                                if(comments[index]['user']['id'].toString() != id) InkWell(
                                  onTap: blockList.contains(comments[index]['user']['id']) == true ? (){
                                    showDialog(
                                      context: context,
                                      builder: (context) => StatefulBuilder(
                                          builder: (context,setState) {
                                            return AlertDialog(
                                              backgroundColor: primary,
                                              title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                              content: const Text("Do you want to unblock this user?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                              actions: [
                                                TextButton(
                                                  child: isLoadBlock == true ? SpinKitCircle(color: ascent,) : const Text("Yes",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                                  onPressed:  () {
                                                    //print(data["id"].toString());
                                                    setState(() {
                                                      isLoadBlock = true;
                                                    });
                                                    unBlockUser(comments[index]['user']['id'], name, comments[index]['user']['name']);
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
                                            );
                                          }
                                      ),
                                    );
                                  }:(){
                                    showDialog(
                                      context: context,
                                      builder: (context) => StatefulBuilder(
                                          builder: (context,setState) {
                                            return AlertDialog(
                                              backgroundColor: primary,
                                              title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                              content: const Text("Do you want to block this user?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                              actions: [
                                                TextButton(
                                                  child: isLoadBlock == true ? SpinKitCircle(color: ascent,) : const Text("Yes",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                                  onPressed:  () {
                                                    //print(data["id"].toString());
                                                    setState(() {
                                                      isLoadBlock = true;
                                                    });
                                                    matchFriendReques(
                                                        comments[index]['user']['id'],
                                                        comments[index]['user']['id'],
                                                        name,
                                                        comments[index]['user']['name'],
                                                        index,
                                                        List<int>.from(comments[index]["fansList"]),
                                                        comments[index]['user']['id']
                                                    );
                                                    //blockUser(comments[index]['user']['id'], name, comments[index]['user']['name'], index,List<int>.from(comments[index]["fansList"]));
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
                                            );
                                          }
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 30,
                                    child: blockList.contains(comments[index]['user']['id']) == true ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Unblock User",style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w200,
                                            color: ascent,
                                            fontFamily: Poppins
                                        ),),
                                        Icon(Icons.block,size: 25,color: Colors.grey,)
                                      ],
                                    ) : Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Block User",style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w200,
                                            color: Colors.red,
                                            fontFamily: Poppins
                                        ),),
                                        Icon(Icons.block,size: 25,color: Colors.red,)
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(comments[index]["topBadge"] != null) GestureDetector(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EventPosts(
                              userid: comments[index]["user"]["id"].toString(),
                            )));
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top:6.0),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(120)),
                              child: CachedNetworkImage(
                                imageUrl: comments[index]["topBadge"]["document"],
                                //imageUrl: lowestRankingOrderDocument,
                                imageBuilder:
                                    (context, imageProvider) =>
                                    Container(
                                      height: 30,
                                      width: 30,
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
                                    Padding(
                                      padding: const EdgeInsets.only(top:6.0),
                                      child: SpinKitCircle(
                                        color: primary,
                                        size: 20,
                                      ),
                                    ),
                                errorWidget: (context, url,
                                    error) =>
                                    ClipRRect(
                                        borderRadius:
                                        const BorderRadius.all(
                                            Radius.circular(50)),
                                        child: Image.network(
                                          comments[index]["topBadge"]["document"],
                                          width: 30,
                                          height: 30,
                                          fit: BoxFit.contain,
                                        )),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 5,),
                        if(myList.contains(int.parse(comments[index]["user"]["id"].toString())) == false) comments[index]["user"]["show_stories_to_non_friends"] == true ? Padding(
                          padding: const EdgeInsets.only(top:6.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                id: comments[index]['user']['id'].toString(),
                                username: comments[index]["user"]["username"],
                              )));
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap:(comments[index]["recent_stories"].length <= 0) ? (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                      id: comments[index]["user"]["id"].toString(),
                                      username: comments[index]["user"]["username"],
                                    )));
                                  }: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                      storyList: List<Story>.from(comments[index]["recent_stories"].map((e){
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
                                      getComments(widget.postid);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(50)),
                                      border: Border.all(
                                          width: 1,
                                          color:
                                          Colors.transparent),
                                      gradient: (comments[index]["recent_stories"].length <= 0) ? null :(comments[index]["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.topRight,
                                          stops: const [0.0, 0.7],
                                          tileMode: TileMode.clamp,
                                          colors: <Color>[
                                            Colors.grey,
                                            Colors.grey,
                                          ]):
                                      (comments[index]["close_friends"].contains(int.parse(id)) == true ? (comments[index]["recent_stories"].any((story) => story["close_friends_only"] == true) ?LinearGradient(
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
                                          ])): LinearGradient(
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
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(50)),
                                      child: comments[index]["user"]
                                      ["pic"] ==
                                          null
                                          ? Image.network(
                                        "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                        width: 30,
                                        height: 30,
                                      )
                                          : CachedNetworkImage(
                                        imageUrl:
                                        comments[index]
                                        ["user"]["pic"],
                                        imageBuilder: (context,
                                            imageProvider) =>
                                            Container(
                                              height: 30,
                                              width: 30,
                                              decoration:
                                              BoxDecoration(
                                                image:
                                                DecorationImage(
                                                  image:
                                                  imageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                        placeholder: (context,
                                            url) =>
                                            Center(
                                                child:
                                                SpinKitCircle(
                                                  color: primary,
                                                  size: 10,
                                                )),
                                        errorWidget: (context,
                                            url, error) =>
                                            ClipRRect(
                                              borderRadius:
                                              const BorderRadius.all(
                                                  Radius
                                                      .circular(
                                                      50)),
                                              child: Image.network(
                                                "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                width: 30,
                                                height: 30,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                comments[index]['comment'].toString().startsWith("https://media")?SizedBox(height: 150,):SizedBox(height: 20,)
                              ],
                            ),
                          ),
                        ):(
                            (comments[index]["user"]["followList"].contains(int.parse(id)) == true || comments[index]["fansList"].contains(int.parse(id)) == true)?
                            Padding(
                              padding: const EdgeInsets.only(top:6.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                    id: comments[index]['user']['id'].toString(),
                                    username: comments[index]["user"]["username"],
                                  )));
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap:(comments[index]["recent_stories"].length <= 0) ? (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                          id: comments[index]["user"]["id"].toString(),
                                          username: comments[index]["user"]["username"],
                                        )));
                                      }: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewScreen(
                                          storyList: List<Story>.from(comments[index]["recent_stories"].map((e){
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
                                          getComments(widget.postid);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(50)),
                                          border: Border.all(
                                              width: 1,
                                              color:
                                              Colors.transparent),
                                          gradient: (comments[index]["recent_stories"].length <= 0) ? null :(comments[index]["recent_stories"].every((story) => (story["viewers"] as List).any((viewer) => viewer['id'].toString() == id)) == true ? LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.topRight,
                                              stops: const [0.0, 0.7],
                                              tileMode: TileMode.clamp,
                                              colors: <Color>[
                                                Colors.grey,
                                                Colors.grey,
                                              ]):
                                          (comments[index]["close_friends"].contains(int.parse(id)) == true ? (comments[index]["recent_stories"].any((story) => story["close_friends_only"] == true) ?LinearGradient(
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
                                              ])): LinearGradient(
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
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(50)),
                                          child: comments[index]["user"]
                                          ["pic"] ==
                                              null
                                              ? Image.network(
                                            "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                            width: 30,
                                            height: 30,
                                          )
                                              : CachedNetworkImage(
                                            imageUrl:
                                            comments[index]
                                            ["user"]["pic"],
                                            imageBuilder: (context,
                                                imageProvider) =>
                                                Container(
                                                  height: 30,
                                                  width: 30,
                                                  decoration:
                                                  BoxDecoration(
                                                    image:
                                                    DecorationImage(
                                                      image:
                                                      imageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                            placeholder: (context,
                                                url) =>
                                                Center(
                                                    child:
                                                    SpinKitCircle(
                                                      color: primary,
                                                      size: 10,
                                                    )),
                                            errorWidget: (context,
                                                url, error) =>
                                                ClipRRect(
                                                  borderRadius:
                                                  const BorderRadius.all(
                                                      Radius
                                                          .circular(
                                                          50)),
                                                  child: Image.network(
                                                    "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                    width: 30,
                                                    height: 30,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    comments[index]['comment'].toString().startsWith("https://media")?SizedBox(height: 150,):SizedBox(height: 20,)
                                  ],
                                ),
                              ),
                            ):
                            Padding(
                              padding: const EdgeInsets.only(top:6.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                    id: comments[index]['user']['id'].toString(),
                                    username: comments[index]["user"]["username"],
                                  )));
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap:(){
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                          id: comments[index]["user"]["id"].toString(),
                                          username: comments[index]["user"]["username"],
                                        )));
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(50)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(50)),
                                          child: comments[index]["user"]
                                          ["pic"] ==
                                              null
                                              ? Image.network(
                                            "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                            width: 30,
                                            height: 30,
                                          )
                                              : CachedNetworkImage(
                                            imageUrl:
                                            comments[index]
                                            ["user"]["pic"],
                                            imageBuilder: (context,
                                                imageProvider) =>
                                                Container(
                                                  height: 30,
                                                  width: 30,
                                                  decoration:
                                                  BoxDecoration(
                                                    image:
                                                    DecorationImage(
                                                      image:
                                                      imageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                            placeholder: (context,
                                                url) =>
                                                Center(
                                                    child:
                                                    SpinKitCircle(
                                                      color: primary,
                                                      size: 10,
                                                    )),
                                            errorWidget: (context,
                                                url, error) =>
                                                ClipRRect(
                                                  borderRadius:
                                                  const BorderRadius.all(
                                                      Radius
                                                          .circular(
                                                          50)),
                                                  child: Image.network(
                                                    "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                    width: 30,
                                                    height: 30,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    comments[index]['comment'].toString().startsWith("https://media")?SizedBox(height: 150,):SizedBox(height: 20,)
                                  ],
                                ),
                              ),
                            )
                        ),
                        if(myList.contains(int.parse(comments[index]["user"]["id"].toString())) == true) Padding(
                          padding: const EdgeInsets.only(top:6.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                id: comments[index]['user']['id'].toString(),
                                username: comments[index]["user"]["username"],
                              )));
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap:(){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                      id: comments[index]["user"]["id"].toString(),
                                      username: comments[index]["user"]["username"],
                                    )));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(50)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(50)),
                                      child: comments[index]["user"]
                                      ["pic"] ==
                                          null
                                          ? Image.network(
                                        "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                        width: 30,
                                        height: 30,
                                      )
                                          : CachedNetworkImage(
                                        imageUrl:
                                        comments[index]
                                        ["user"]["pic"],
                                        imageBuilder: (context,
                                            imageProvider) =>
                                            Container(
                                              height: 30,
                                              width: 30,
                                              decoration:
                                              BoxDecoration(
                                                image:
                                                DecorationImage(
                                                  image:
                                                  imageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                        placeholder: (context,
                                            url) =>
                                            Center(
                                                child:
                                                SpinKitCircle(
                                                  color: primary,
                                                  size: 10,
                                                )),
                                        errorWidget: (context,
                                            url, error) =>
                                            ClipRRect(
                                              borderRadius:
                                              const BorderRadius.all(
                                                  Radius
                                                      .circular(
                                                      50)),
                                              child: Image.network(
                                                "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                width: 30,
                                                height: 30,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                comments[index]['comment'].toString().startsWith("https://media")?SizedBox(height: 150,):SizedBox(height: 20,)
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 5,),
                        GestureDetector(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                              id: comments[index]["user"]["id"].toString(),
                              username: comments[index]["user"]["username"],
                            )));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                      comments[index]["user"]
                                      ["username"],
                                      style: const TextStyle(
                                          fontFamily: Poppins,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12
                                      )),
                                  SizedBox(width: 5,),
                                  Text(formatTimeDifference(comments[index]['created']),style: const TextStyle(
                                      fontFamily: Poppins,
                                      fontSize: 12,
                                      color: Colors.grey
                                  ),),
                                ],
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                      child: comments[index]['comment'].toString().startsWith("https://media")?
                                      buildGifWidget(context, comments[index]['comment'].toString())
                                          :
                                      Row(
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context).size.width * 0.4,
                                            child: highlightSearchText(comments[index]["comment"], searchCommentText.text, isEdited,context),
                                          ),
                                        ],
                                      ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                          onTap: () {
                                            setState(() {
                                              isReply = true;
                                            });
                                            commentID = comment_id;
                                            replyName = comments[index]['user']['username'];
                                            controller.text = "@${comments[index]['user']['username']} ";
                                            comment.text = "@${comments[index]['user']['username']} ";
                                            print("Comment ID -> ${comment_id}");
                                          },
                                          child: Text(
                                            "reply",
                                            style: TextStyle(
                                              fontFamily: Poppins,
                                              fontWeight:
                                              FontWeight.w400,
                                              color: primary,
                                            ),
                                          )),
                                      const SizedBox(width: 5,),
                                      const SizedBox(width: 4,),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: comments[index]["isLiked"] == true ?(){
                    print("like heart pressed");
                    setState(() {
                      comments[index]["isLiked"] = false;
                      comments[index]["like_count"]--;
                    });
                    unlikeCommentReply(comments[index]['id']);
                  }:(){
                    setState(() {
                      comments[index]["isLiked"] = true;
                      comments[index]["like_count"]++;
                    });
                    likeCommentReply(comments[index]['id']);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0,right: 10,top: 10,bottom: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20,),
                        comments[index]["isLiked"] == true ? Column(
                          children: [
                            widget.isEventPost == true ? Icon(
                              Icons.favorite,color: Colors.red,size: 20,
                            ): Icon(
                              Icons.star,color: Colors.orange,size: 20,
                            ),
                            // SizedBox(height: 5,),
                            // Text("${comments[index]["likeCommentsCount"]}",style: TextStyle(color: Colors.grey,fontSize: 10,fontFamily: Poppins,),),
                          ],
                        ):
                        Column(
                          children: [
                            widget.isEventPost == true ? Icon(
                              Icons.favorite_border,color: Colors.grey,size: 20,
                            ): Icon(
                              Icons.star_border,color: Colors.grey,size: 20,
                            ),
                            // SizedBox(height: 5,),
                            // Text("${comments[index]["likeCommentsCount"]}",style: TextStyle(color: Colors.grey,fontSize: 10,fontFamily: Poppins,),),
                          ],
                        ),
                        SizedBox(height: 5,),
                        Text("${comments[index]["like_count"]}",style: TextStyle(color: Colors.grey,fontSize: 10,fontFamily: Poppins,),),
                        SizedBox(height: 20,),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}

class MentionInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Identifying words starting with '@'
    final regex = RegExp(r'(@\w+)');
    newText = newText.replaceAllMapped(regex, (match) {
      return match.group(0) ?? '';
    });

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class FormattedTextDisplay extends StatelessWidget {
  final String text;
  const FormattedTextDisplay({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Split the input text based on the '@' symbol
    List<TextSpan> spans = [];
    final regex = RegExp(r'(@\w+)');
    final matches = regex.allMatches(text);

    int lastIndex = 0;
    for (var match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(color: primary), // Color red for mentions
      ));
      lastIndex = match.end;
    }

    // Add remaining text after the last match
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
      ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 18), // Default text style
        children: spans,
      ),
    );
  }
}

Widget buildGifWidget(BuildContext context,String gifUrl) {
  debugPrint("gif link after sending msg========>$gifUrl");
  return Stack(
    alignment: Alignment.center,
    children: [
      Container(
          height: 150,
          width: 150,
          color: Colors.black54,
          child: Image.network(gifUrl, height: 150,width: 150,)),
      FutureBuilder(
        future: precacheImage(NetworkImage(gifUrl), context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primary));
          } else {
            return const SizedBox.shrink(); // Empty container when image is loaded
          }
        },
      ),
    ],
  );
}




