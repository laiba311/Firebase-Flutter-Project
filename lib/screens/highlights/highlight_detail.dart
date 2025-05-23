import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/models/story_model.dart';
import 'package:finalfashiontimefrontend/models/user_model.dart';
import 'package:finalfashiontimefrontend/screens/highlights/edit_highlights.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import 'package:video_player/video_player.dart';

class HighlightViewScreen extends StatefulWidget {
  final List<dynamic> storyList;
  final String highlightId;
  final String highlightname;
  final String time;

  HighlightViewScreen({required this.storyList, required this.highlightId, required this.highlightname,required this.time});

  @override
  _HighlightViewScreenState createState() => _HighlightViewScreenState();
}

class _HighlightViewScreenState extends State<HighlightViewScreen> {
  int _currentStoryIndex = 0;
  late PageController _pageController;
  Timer? _storyTimer;
  double _progress = 0.0;
  final Duration storyDuration = Duration(seconds: 5); // Story duration
  bool _isPaused = false; // To track whether the timer is paused or not
  String token = '';
  String id = '';
  Map<int, VideoPlayerController> _videoControllers = {};
  TextEditingController _highlightNameController = TextEditingController();
  List<int> selectedStories = [];
  List<Story> groupedStoriesList = [];
  bool isPostHighlight = false;
  bool isPlay = true;
  bool? isTimer;

  Future<void> _requestPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  // Function to save image to gallery
  Future<void> _saveImage(String imageUrl) async {
    // await _requestPermission(); // Ensure permission is granted
    // GallerySaver.saveImage(imageUrl).then((bool? success) {
    //   if (success == true) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Image saved to gallery!')),
    //     );
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Failed to save image.')),
    //     );
    //   }
    // });
  }

  // Function to save video to gallery
  Future<void> _saveVideo(String videoUrl) async {
    // await _requestPermission(); // Ensure permission is granted
    // GallerySaver.saveVideo(videoUrl).then((bool? success) {
    //   if (success == true) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Video saved to gallery!')),
    //     );
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Failed to save video.')),
    //     );
    //   }
    // });
  }


  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.storyList.length; i++) {
      if (widget.storyList[i]["type"] == 'video') {
        _preloadVideo(i);
      }
    }
    _pageController = PageController(initialPage: _currentStoryIndex);
   // _startStoryTimer(); // Start the timer
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
          final List<dynamic> response = jsonDecode(value.body);
          print("The all story list is =======> ${response.toString()}");

          response.forEach((element) {
            final User user = User(
              name: element['user']['name'],
              username: element['user']['username'],
              profileImageUrl: element['user']['pic'] ?? '',
              id: element['user']['id'].toString(),
            );

            // Create a story object for each element
            Story story = Story(
              duration: "",
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
            setState(() {
              groupedStoriesList.add(story);
            });
          });
        } else {
          print("Error received while getting all stories =========> ${value.body.toString()}");
        }
      });
    } catch (e) {
      print("Error Story -> ${e.toString()}");
    }
  }
  void _preloadVideo(int index) {
    final story = widget.storyList[index];
    if (story["type"] == 'video') {
      // Declare videoController before referencing it
      final VideoPlayerController videoController = VideoPlayerController.network(story["content"]);

      videoController.initialize().then((_) {
        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            _videoControllers[index] = videoController;
          });
        }
      });
    }
  }

  fillStories(){
    selectedStories.clear();
    widget.storyList.forEach((element) {
      selectedStories.add(element["id"]);
    });
  }


  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print("timer ==> ${preferences.getBool("timer")}");
    isTimer = preferences.getBool("timer") ?? false;
    if(preferences.getBool("timer") == false){
      print("No Timer");
    }else {
      _startStoryTimer();
    }
    getAllStories();
    fillStories();
  }

  updateHighlight(String title,String id, List<int> stories,String user_id) {
    print("stories ${stories}");
    var apiUrl = "$serverUrl/highlights/highlights/${id}/";
    try {
      https.patch(
          Uri.parse(apiUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: json.encode({
            "title": title,
            "user_id": user_id,
            "story_ids": stories
          })
      ).then((value) {
        if (value.statusCode == 200) {
          setState(() {
            isPostHighlight = false;
          });
          Navigator.pop(context);
          Navigator.pop(context);
          Fluttertoast.showToast(
              msg: "Highlight Updated", backgroundColor: primary);
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

  viewStory(int storyId) {
    var url = "$serverUrl/story/seen-stories/${storyId}/";
    try {
      https.put(Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          })
          .then((value) {
        if (value.statusCode == 200) {
          debugPrint("story viewed by user");
        } else {
          debugPrint(" ===========> ${value.statusCode}");
        }
      });
    } catch (e) {
      debugPrint("Error received===========>${e.toString()}");
    }
  }
  deleteStory(String storyId) {
    var url = "$serverUrl/story/stories/${storyId}/";
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
          Navigator.pop(context);
          Fluttertoast.showToast(
              msg: "Highlight deleted", backgroundColor: primary);
        } else {
          debugPrint(" ===========> ${value.statusCode}");
        }
      });
    } catch (e) {
      debugPrint("Error received===========>${e.toString()}");
    }
  }
  deleteHighlight(String storyId) {
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
          Navigator.pop(context);
        } else {
          debugPrint(" ===========> ${value.statusCode}");
        }
      });
    } catch (e) {
      debugPrint("Error received===========>${e.toString()}");
    }
  }

  void _startStoryTimer() {
    // Reset progress for th  e new story
    if(isTimer == false){
      print("No Timer");
    }
    else {
      _progress = 0.0;
      _storyTimer?.cancel();

      _storyTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!_isPaused) {
          setState(() {
            _progress += 0.01;
            if (_progress >= 1) {
              _progress = 1;
              _moveToNextStory(); // Move to the next story when the current one is done
            }
          });
        }
      });
    }
  }

  void _moveToNextStory() {
    if (_currentStoryIndex < widget.storyList.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _pageController.animateToPage(
        _currentStoryIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer(); // Restart the timer for the next story
    } else {
      _storyTimer?.cancel();
      Navigator.pop(context); // Close the screen after all stories
    }
  }

  void _moveToPreviousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _pageController.animateToPage(
        _currentStoryIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _startStoryTimer(); // Restart the timer for the new story
    }
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
  }

  void _onStoryChange(int index) {
    setState(() {
      _currentStoryIndex = index;
    });
    if(widget.storyList[index]["type"] == "video"){
      _videoControllers[index]!.play();
    }
    _startStoryTimer(); // Restart timer when story changes manually
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _pageController.dispose();
    _videoControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          // Get the screen width and height
          var screenWidth = MediaQuery.of(context).size.width;
          var screenHeight = MediaQuery.of(context).size.height;

          // Get the tap position
          var tapPositionX = details.globalPosition.dx;
          var tapPositionY = details.globalPosition.dy;

          // Define the top and bottom exclusion heights as 20% of the screen height
          var exclusionHeight = screenHeight * 0.2;

          // Ensure the tap is in the middle area (not in the top or bottom exclusion zones)
          if (tapPositionY > exclusionHeight && tapPositionY < screenHeight - exclusionHeight) {
            // Split the screen into left (0% - 50%) and right (50% - 100%)
            if (tapPositionX < screenWidth / 2) {
              // Left tap (0% - 50% of the screen width)
              _moveToPreviousStory();
            } else {
              // Right tap (50% - 100% of the screen width)
              _moveToNextStory();
            }
          }
        },
        child: Stack(
          children: [
            // Story content display
            PageView.builder(
              controller: _pageController,
              itemCount: widget.storyList.length,
              onPageChanged: _onStoryChange,
              itemBuilder: (context, index) {
                final story = widget.storyList[index];
                return Stack(
                  children: [
                    if(story["type"] == 'image') Padding(
                      padding: EdgeInsets.only(
                          top: 110,
                          bottom: 70
                      ),
                      child: Image.network(
                        story["content"],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height,
                      ),
                    ),
                    if(story["type"] == 'text') Center(
                      child: Text(
                        story["content"],
                        style:
                        TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    if (story["type"] == 'video' && _videoControllers[index] != null && _videoControllers[index]!.value.isInitialized)
                      Center(
                        child: AspectRatio(
                          aspectRatio: _videoControllers[index]!.value.aspectRatio,
                          child: VideoPlayer(_videoControllers[index]!),
                        ),
                      ),
                    if (story["type"] == 'video' &&
                        _videoControllers[index] != null &&
                        !_videoControllers[index]!.value.isInitialized)
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    Positioned(
                      top: 50,
                      left: 20,
                      child: Container(
                        height: 70,
                        width: MediaQuery.of(context).size.width *0.8,
                        child: Row(
                          mainAxisAlignment:MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap:(){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                  id: story["user"]["id"].toString(),
                                  username: story["user"]["username"],
                                )));
                              },
                              child: Row(
                                mainAxisSize:MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    backgroundImage:
                                    NetworkImage(story["user"]["pic"]),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    story["user"]["username"],
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    "${widget.time}",
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(width: 4),
                                      GestureDetector(
                                          onTap:(){
                                            _pauseStory();
                                            _highlightNameController.text = widget.highlightname;
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => EditHightlights(groupedStoriesList: groupedStoriesList, id: widget.highlightId, token: token, selectedStories: selectedStories, title: widget.highlightname, userID: id)));
                                          },
                                          child: Icon(Icons.edit,color: ascent,))
                                    ],
                                  ),
                                ),
                                SizedBox(width: 5),
                                GestureDetector(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(width: 4),
                                      GestureDetector(
                                          onTap:(){
                                            _pauseStory();
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  AlertDialog(
                                                    backgroundColor: primary,
                                                    title: Text("FashionTime", style: TextStyle(color: ascent,
                                                        fontFamily: Poppins,
                                                        fontWeight: FontWeight.bold),),
                                                    content: Text("Do you want to remove highlight story", style: TextStyle(
                                                        color: ascent, fontFamily: Poppins),),
                                                    actions: [
                                                      TextButton(
                                                        child: Text("Yes", style: TextStyle(
                                                            color: ascent, fontFamily: Poppins)),
                                                        onPressed: () {
                                                          if(widget.storyList.length == 1){
                                                            deleteHighlight(widget.highlightId);
                                                          }else {
                                                            deleteStory(story["id"]
                                                                .toString());
                                                          }
                                                        },
                                                      ),
                                                      TextButton(
                                                        child: Text("No", style: TextStyle(
                                                            color: ascent, fontFamily: Poppins)),
                                                        onPressed: () {
                                                          _resumeStory();
                                                          setState(() {
                                                            Navigator.pop(context);
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                            );
                                          },
                                          child: Icon(Icons.delete_sweep,color: ascent,))
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    // Progress bar for each story
                    Positioned(
                      top: 60,
                      left: 10,
                      right: 10,
                      child: Row(
                        children: List.generate(
                          widget.storyList.length,
                              (storyIndex) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: LinearProgressIndicator(
                                value: storyIndex == _currentStoryIndex
                                    ? _progress // Progress of the current story
                                    : storyIndex < _currentStoryIndex
                                    ? 1.0 // Completed stories
                                    : 0.0, // Future stories
                                backgroundColor: Colors.grey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      left: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap:story["viewers"].length >0 ? (){
                              _pauseStory();
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
                                    return GestureDetector(
                                      onVerticalDragUpdate: (details) {
                                        if (details.primaryDelta! < 0) {
                                          // User is dragging upwards, expand to full screen
                                          Navigator.pop(context);
                                          showModalBottomSheet(
                                              isScrollControlled: true,
                                              context: context,
                                              builder: (ctx) {
                                                return GestureDetector(
                                                  child: SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.96,
                                                    child: Column(
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
                                                            Text("Views",style: TextStyle(color: ascent,fontSize: 13,fontWeight: FontWeight.bold,fontFamily: Poppins),),
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
                                                        Expanded(
                                                          child: ListView.builder(
                                                            itemCount: story.viewed_users.length,
                                                            itemBuilder: (context,index) =>
                                                                InkWell(
                                                                  onTap:id == story["viewers"][index]["id"].toString() ?(){
                                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                                      id: story["viewers"][index]["id"].toString(),
                                                                      username: story["viewers"][index]["username"],
                                                                    )));
                                                                  }: () {
                                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                                      id: story["viewers"][index]["id"].toString(),
                                                                      username: story["viewers"][index]["username"],
                                                                    )));
                                                                  },
                                                                  child: Padding(
                                                                    padding: const EdgeInsets.all(8.0),
                                                                    child: Row(
                                                                      children: [
                                                                        Column(
                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                          children: [
                                                                            CircleAvatar(
                                                                                backgroundColor: Colors.black,
                                                                                child: ClipRRect(
                                                                                  borderRadius: const BorderRadius.all(
                                                                                      Radius.circular(50)),
                                                                                  child: story["viewers"][index]["pic"] ==
                                                                                      null
                                                                                      ? Image.network(
                                                                                    "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                                    width: 40,
                                                                                    height: 40,
                                                                                  )
                                                                                      : CachedNetworkImage(
                                                                                    imageUrl: story["viewers"][index]["pic"],
                                                                                    imageBuilder: (context, imageProvider) =>
                                                                                        Container(
                                                                                          height: 100,
                                                                                          width: 100,
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
                                                                          ],
                                                                        ),
                                                                        SizedBox(width: 20,),
                                                                        Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          children: [
                                                                            Row(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                Text(
                                                                                    story["viewers"][index]["username"],
                                                                                    style: const TextStyle(
                                                                                        fontFamily: Poppins,
                                                                                        fontWeight: FontWeight.w500,
                                                                                        fontSize: 16
                                                                                    )),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              });
                                        }
                                        else if (details.primaryDelta! > 0) {
                                          Navigator.pop(context);
                                          _resumeStory();
                                        }
                                      },
                                      child: SizedBox(
                                          height: MediaQuery.of(context).size.height * 0.8,
                                          child: Column(
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
                                                  Text("Views",style: TextStyle(color: ascent,fontSize: 13,fontWeight: FontWeight.bold,fontFamily: Poppins),),
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
                                              Expanded(
                                                child: ListView.builder(
                                                  itemCount: story["viewers"].length,
                                                  itemBuilder: (context,index) =>
                                                      InkWell(
                                                        onTap:id == story["viewers"][index]["id"].toString() ?(){
                                                          Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                            id: story["viewers"][index]["id"].toString(),
                                                            username: story["viewers"][index]["username"],
                                                          )));
                                                        }: () {
                                                          Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                            id: story["viewers"][index]["id"].toString(),
                                                            username: story["viewers"][index]["username"],
                                                          )));
                                                        },
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Row(
                                                            children: [
                                                              Column(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                children: [
                                                                  CircleAvatar(
                                                                      backgroundColor: Colors.black,
                                                                      child: ClipRRect(
                                                                        borderRadius: const BorderRadius.all(
                                                                            Radius.circular(50)),
                                                                        child: story["viewers"][index]["pic"] ==
                                                                            null
                                                                            ? Image.network(
                                                                          "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                          width: 40,
                                                                          height: 40,
                                                                        )
                                                                            : CachedNetworkImage(
                                                                          imageUrl: story["viewers"][index]["pic"],
                                                                          imageBuilder: (context, imageProvider) =>
                                                                              Container(
                                                                                height: 100,
                                                                                width: 100,
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
                                                                ],
                                                              ),
                                                              SizedBox(width: 20,),
                                                              Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Text(
                                                                          story["viewers"][index]["username"],
                                                                          style: const TextStyle(
                                                                              fontFamily: Poppins,
                                                                              fontWeight: FontWeight.w500,
                                                                              fontSize: 16
                                                                          )),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ],
                                          )
                                      ),
                                    );
                                  });
                            }:(){},
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  story["viewers"].length >0 ? story["viewers"].length.toString():"0",
                                  style: TextStyle(fontSize: 18, color: Colors.white,fontFamily: Poppins),
                                ),
                                SizedBox(width: 5),
                                Icon(Icons.remove_red_eye,color: Colors.white,),
                              ],
                            ),
                          ),
                          if(isTimer == true) Text("( 1/${_progress.toStringAsFixed(1)} sec )"),
                          GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Icon(Icons.close,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    if(isTimer == true) Positioned(
                        left: 50,
                        right: 50,
                        bottom:20,
                        child: InkWell(
                            onTap: isPlay == true ? (){
                              setState(() {
                                isPlay = false;
                              });
                              _pauseStory();
                            }: (){
                              setState(() {
                                isPlay = true;
                              });
                              _resumeStory();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Icon(isPlay == true ? Icons.pause : Icons.play_arrow,color: ascent,),
                                ),
                              ],
                            )))
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
        return Center(child: Text('Unsupported story type'));
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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

