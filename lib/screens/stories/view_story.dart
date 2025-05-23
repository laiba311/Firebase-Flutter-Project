import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:fashiontimefinal/screens/pages/friend_profile.dart';
// import 'package:fashiontimefinal/screens/pages/myProfile.dart';
//import 'package:fashiontimefinal/screens/pages/settings_pages/report_screen.dart';
import 'package:finalfashiontimefrontend/models/story_model.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import 'package:video_player/video_player.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> storyList;

  StoryViewScreen({required this.storyList});

  @override
  _StoryViewScreenState createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  int _currentStoryIndex = 0;
  late PageController _pageController;
  Timer? _storyTimer;
  double _progress = 0.0;
  final Duration storyDuration = Duration(seconds: 5); // Story duration
  bool _isPaused = false; // To track whether the timer is paused or not
  String token = '';
  String id = '';
  Map<int, VideoPlayerController> _videoControllers = {};
  bool isPlay = true;
  bool? isTimer;
  bool loading1 = false;

  Future<void> _requestPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  // Function to save image to gallery
  Future<void> _saveImage(String imageUrl) async {
    await _requestPermission(); // Ensure permission is granted
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
    await _requestPermission(); // Ensure permission is granted
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
      if (widget.storyList[i].type == 'video') {
        _preloadVideo(i);
      }
    }
    _pageController = PageController(initialPage: _currentStoryIndex);
    //_startStoryTimer(); // Start the timer
    getCashedData();
  }

  void _preloadVideo(int index) {
    final story = widget.storyList[index];
    if (story.type == 'video') {
      // Declare videoController before referencing it
      final VideoPlayerController videoController = VideoPlayerController.network(story.url);

      videoController.initialize().then((_) {
        // Check if the widget is still mounted before calling setState
        if (mounted) {
          videoController.setLooping(true);
          videoController.play();
          setState(() {
            _videoControllers[index] = videoController;
          });
        }
      });
    }
  }


  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      id = preferences.getString("id")!;
    });
    token = preferences.getString("token")!;
    print("user id "+id);
    // print("story user id "+widget.storyList[0].user.id);
    viewStory(widget.storyList[0].storyId);
    print("timer ==> ${preferences.getBool("timer")}");
    isTimer = preferences.getBool("timer") ?? false;
    if(preferences.getBool("timer") == false){
      print("No Timer");
    }else {
      _startStoryTimer();
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
  deleteStory(int storyId) {
    var url = "$serverUrl/story/stories/${storyId}/";
    try {
      https.delete(Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          })
          .then((value) {
        if (value.statusCode == 204) {
          debugPrint("story deleted by user");
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          debugPrint(" ===========> ${value.statusCode}");
        }
      });
    } catch (e) {
      debugPrint("Error received===========>${e.toString()}");
    }
  }

  hideStory(id){
    var url = "$serverUrl/apiuser-favorites/";
    try {
      https.post(Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
         body: json.encode({
           "favorite_user_id": id
         })
      )
          .then((value) {
       // if (value.statusCode == 200) {
          debugPrint("story viewed by user");
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        //} else {
        // debugPrint(" ===========> ${value.statusCode}");
       // }
      });
    } catch (e) {
      debugPrint("Error received===========>${e.toString()}");
    }
  }

  void _startStoryTimer() {
    // Reset progress for the new story
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
        _startStoryTimer(); // Restart the timer for the next story
      // Restart the timer for the new story
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
    //print("${widget.storyList[index].storyId}");
    viewStory(widget.storyList[index].storyId);
    if(widget.storyList[index].type == "video"){
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
              itemCount: (widget.storyList..sort((a, b) => DateTime.parse(b.created).compareTo(DateTime.parse(a.created)))).length,
              onPageChanged: _onStoryChange,
              itemBuilder: (context, index) {
                final story = widget.storyList[index];
                print("${story.url}");
                return Stack(
                  children: [
                    // if(story.type == 'image') Center(
                    //   child: ClipRRect(
                    //     borderRadius: BorderRadius.circular(10),
                    //     child: Container(
                    //       height: MediaQuery.of(context).size.height,
                    //       width: MediaQuery.of(context).size.width,
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.all(Radius.circular(10)),
                    //         image: DecorationImage(
                    //           filterQuality: FilterQuality.high,
                    //           image: NetworkImage(
                    //               story.url
                    //           ),
                    //           fit: BoxFit.cover
                    //         )
                    //       ),
                    //       child: Text(""),
                    //     ),
                    //   ),
                    // ),
                    if(story.type == 'image') Padding(
                      padding: EdgeInsets.only(
                          top: 120,
                          bottom: 70,
                         right: 0,
                        left: 0
                      ),
                      child: CachedNetworkImage(
                        imageUrl: story.url == null ? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w" : story.url,
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(color: primary,), // Show a loading spinner while the image is loading
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error), // Show an error icon if the image fails to load
                      )
                    ),
                    if(story.type == 'text') Center(
                      child: Text(
                        story.url,
                        style:
                        TextStyle(fontSize: 24, color: Colors.white,fontFamily: Poppins),
                      ),
                    ),
                    if (story.type == 'video' && _videoControllers[index] != null && _videoControllers[index]!.value.isInitialized)
                      Center(
                        child: Container(
                          padding: EdgeInsets.only(
                              top: 110,
                            bottom: 70,
                          ),  // Add padding around the video player
                          decoration: BoxDecoration(// Set the border radius
                            color: Colors.black,  // Optional: background color for contrast
                          ),
                          child: SizedBox(
                            height:MediaQuery.of(context).size.height * 0.9,
                            child: AspectRatio(
                              aspectRatio: _videoControllers[index]!.value.aspectRatio,
                              child: VideoPlayer(_videoControllers[index]!),
                            ),
                          ),
                        ),
                      ),
                    if (story.type == 'video' &&
                        _videoControllers[index] != null &&
                        !_videoControllers[index]!.value.isInitialized)
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    Positioned(
                      top: 50,
                      left: 20,
                      child: Container(
                        height:70,
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Row(
                          mainAxisAlignment:MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap:(){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                  id: story.user.id.toString(),
                                  username: story.user.username,
                                )));
                              },
                              child: Row(
                                crossAxisAlignment:CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            width: 1.5,
                                            color:
                                            Colors.transparent),
                                        gradient: story.close_friends_only == true ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.7],
                                            tileMode: TileMode.clamp,
                                            colors: <Color>[
                                              Colors.deepPurple,
                                              Colors.purpleAccent,
                                            ]):LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.7],
                                            tileMode: TileMode.clamp,
                                            colors: <Color>[
                                              secondary,
                                              primary,
                                            ])
                                    ),
                                    child: CircleAvatar(
                                      minRadius: 15,
                                      maxRadius: 15,
                                      backgroundImage: NetworkImage(story.user.profileImageUrl),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        story.user.username,
                                        style: TextStyle(fontSize: 12, color: Colors.white,fontFamily: Poppins),
                                      ),
                                      SizedBox(width: 7),
                                      Text(
                                        "${story.duration}",
                                        style: TextStyle(fontSize: 12, color: Colors.grey,fontFamily: Poppins),
                                      ),
                                      if(story.close_friends_only == true) Text(
                                        " (Stylemate story)",
                                        style: TextStyle(fontSize: 12, color: Colors.deepPurple,fontFamily: Poppins),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              child: Row(
                                children: [
                                  if(story.user.id.toString() != id.toString()) if(story.type != 'text') GestureDetector(
                                      onTap:(){
                                        if(story.type == 'image'){
                                          _saveImage(story.url,);
                                        }else if(story.type == 'video'){
                                          _saveVideo(story.url);
                                        }
                                      },
                                      child: Icon(Icons.download,color: ascent,)),
                                  if(story.user.id == id) SizedBox(width: 4),
                                  if(story.user.id == id) GestureDetector(
                                      onTap:(){
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              AlertDialog(
                                                backgroundColor: primary,
                                                title: Text("FashionTime", style: TextStyle(color: ascent,
                                                    fontFamily: Poppins,
                                                    fontWeight: FontWeight.bold),),
                                                content: Text("Do you want to remove story?", style: TextStyle(
                                                    color: ascent, fontFamily: Poppins),),
                                                actions: [
                                                  TextButton(
                                                    child: Text("Yes", style: TextStyle(
                                                        color: ascent, fontFamily: Poppins)),
                                                    onPressed: () {
                                                      deleteStory(story.storyId);
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text("No", style: TextStyle(
                                                        color: ascent, fontFamily: Poppins)),
                                                    onPressed: () {
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
                        ),
                      ),
                    ),
                    // Progress bar for each story
                    if(isTimer == true) Positioned(
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
                        mainAxisAlignment:story.user.id == id ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                        children: [
                          if(story.user.id == id) GestureDetector(
                            onTap: (){
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
                                        if (details.primaryDelta! > 0) {
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
                                                  itemCount: story.viewed_users.length,
                                                  itemBuilder: (context,index) =>
                                                      Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: InkWell(
                                                          onTap:() {
                                                            Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                              id: story.viewed_users[index]["id"].toString(),
                                                              username: story.viewed_users[index]["username"],
                                                            )));
                                                          },
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
                                                                        child: story.viewed_users[index]["pic"] ==
                                                                            null
                                                                            ? Image.network(
                                                                          "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                          width: 40,
                                                                          height: 40,
                                                                        )
                                                                            : CachedNetworkImage(
                                                                          imageUrl: story.viewed_users[index]["pic"] == null ? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":story.viewed_users[index]["pic"],
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
                                                                          story.viewed_users[index]["username"],
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
                                  }).then((value){
                                  _resumeStory();
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 5),
                                Icon(Icons.remove_red_eye,color: Colors.white,),
                                SizedBox(width: 5),
                                Text(
                                  story.viewed_users.length.toString(),
                                  style: TextStyle(fontSize: 18, color: Colors.white,fontFamily: Poppins,),
                                ),
                              ],
                            ),
                          ),
                          if(isTimer == true) Text("( 1/${_progress.toStringAsFixed(1)} sec )"),
                          if(story.user.id != id) SizedBox(width: 10,),
                          if(story.user.id != id) GestureDetector(
                              onTap: () {
                                _pauseStory();
                                showModalBottomSheet(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                  ),
                                  isScrollControlled: true,
                                  isDismissible: true, // Allows closing by tapping outside
                                  enableDrag: true, // Allows closing by dragging
                                  context: context,
                                  builder: (ctx) {
                                    return WillPopScope(
                                      onWillPop: () async {
                                        // Call the function you want when closing
                                        _resumeStory();
                                        return true; // Return true to close the bottom sheet
                                      },
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque, // Ensure taps outside are detected
                                        child: SizedBox(
                                          height: MediaQuery.of(context).size.height * 0.35,
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 15),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Text(
                                                    "Settings",
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: Poppins,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 30),
                                              GestureDetector(
                                                onTap: (){
                                                  // Navigator.push(
                                                  //     context,
                                                  //     MaterialPageRoute(
                                                  //         builder: (context) =>
                                                  //             ReportScreen(
                                                  //                 reportedID: id)));
                                                },
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: const [
                                                    Text(
                                                      "Report Story",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 20,
                                                        fontFamily: Poppins,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              GestureDetector(
                                                onTap: (){
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      backgroundColor: primary,
                                                      title: const Text("Hide Story",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                                      content: const Text("Are you sure you no longer want to see this user's story",style: TextStyle(color: ascent,fontFamily: Poppins,),),
                                                      actions: [
                                                        TextButton(
                                                          child: const Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                                          onPressed:  () {
                                                            Navigator.pop(context);
                                                          },
                                                        ),
                                                        loading1 == true ? SpinKitCircle(color: ascent,) : TextButton(
                                                          child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                                                          onPressed:  () {
                                                            //unBlockUser(filteredItems[index].id);
                                                            setState(() {
                                                              loading1 = true;
                                                            });
                                                            hideStory(story.user.id);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: const [
                                                    Text(
                                                      "Turn Off Story",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 20,
                                                        fontFamily: Poppins,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _resumeStory(); // Call the function when tapping 'Cancel'
                                                },
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: const [
                                                    Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 20,
                                                        fontFamily: Poppins,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: const Icon(Icons.more_horiz,
                                  color: Colors.white)),
                          if(story.user.id != id) SizedBox(width: 10,),
                          GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Icon(Icons.close,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    // Positioned(
                    //     right:20,
                    //     bottom:MediaQuery.of(context).size.height * 0.48,
                    //     child: GestureDetector(
                    //         onTap:(){
                    //           _moveToNextStory();
                    //         },
                    //         child: Icon(Icons.skip_next,color: ascent,))),
                    // Positioned(
                    //     left:20,
                    //     bottom:MediaQuery.of(context).size.height * 0.48,
                    //     child: GestureDetector(
                    //         onTap:(){
                    //           _moveToPreviousStory();
                    //         },
                    //         child: Icon(Icons.skip_previous,color: ascent,))),
                    // if(isTimer == true) Positioned(
                    //     left: 50,
                    //     right: 50,
                    //     bottom:20,
                    //     child: InkWell(
                    //         onTap: isPlay == true ? (){
                    //           setState(() {
                    //             isPlay = false;
                    //           });
                    //           _pauseStory();
                    //         }: (){
                    //           setState(() {
                    //             isPlay = true;
                    //           });
                    //           _resumeStory();
                    //         },
                    //         child: Row(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: [
                    //             Padding(
                    //               padding: const EdgeInsets.all(18.0),
                    //               child: Icon(isPlay == true ? Icons.pause : Icons.play_arrow,color: ascent,),
                    //             ),
                    //           ],
                    //         )))
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
