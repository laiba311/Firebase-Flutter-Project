import 'dart:convert';
import 'package:chewie/chewie.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/reels/createReel.dart';
import 'package:finalfashiontimefrontend/screens/reels/reel_comment.dart';
import 'package:finalfashiontimefrontend/screens/reels/reels.dart';
import 'package:finalfashiontimefrontend/screens/reels/report_reel.dart';
import 'package:finalfashiontimefrontend/screens/reels/user_like.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as https;
import '../../utils/constants.dart';

class ReelsInitializerScreen extends StatefulWidget {
  final String? videoLink;
  final String? name;
  final String? reelDescription;
  final int? likeCount;
  final int? reelId;
  final int? userId;
  final String? token;
  final int? myLikes;
  final VoidCallback? onLikeCreated;
  final VoidCallback? onDislikeCreated;
  final VoidCallback? refreshReel;
  final String userPic;
  final String friendId;
  final bool isCommentEnabled;
  final String reelCount;
  final Function navigateTo;
  final Function navigateToPageWithReelReportArguments;

  const ReelsInitializerScreen({
    super.key,
    this.videoLink,
    this.name,
    this.reelDescription,
    this.likeCount,
    this.reelId,
    this.userId,
    this.token,
    this.myLikes,
    this.onLikeCreated,
    this.onDislikeCreated,
    this.refreshReel,
    required this.userPic,
    required this.friendId,
    required this.isCommentEnabled,
    required this.reelCount,
    required this.navigateTo,
    required this.navigateToPageWithReelReportArguments,
  });

  @override
  State<ReelsInitializerScreen> createState() => _ReelsInitializerScreenState();
}

class _ReelsInitializerScreenState extends State<ReelsInitializerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool isPlaying = true;
  bool isLiked = false;
  bool heartIcon = false;
  Map<String, dynamic> data = {};
  bool loading = false;
  String id = "";
  String token = "";
  bool requestLoader1 = false;
  bool isMuted = true;

  getCachedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    getMyFriends(widget.friendId);
  }

  getMyFriends(id) {
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/user/api/allUsers/$id"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        print("Data ==> ${data.toString()}");
        setState(() {
          data = jsonDecode(value.body);
        });
        print("Friend data $data");
        print(jsonDecode(value.body).toString());
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

  @override
  void initState() {
    getCachedData();
    print("Friend id ==> ${widget.friendId}");
    if (widget.videoLink!.isNotEmpty) {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoLink!))
            ..addListener(() => setState(() {}))
            ..setLooping(true)
            ..initialize().then((_) {
              if (isPlaying) {
                _videoPlayerController!.play();
                _videoPlayerController!.setVolume(0.0);
              }
            });
    }
    super.initState();
  }

  @override
  void dispose() {
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  showToast(Color bg, String toastMsg) {
    Fluttertoast.showToast(
      msg: toastMsg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: bg,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _togglePlayPause() {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      setState(() {
        if (_videoPlayerController!.value.isPlaying) {
          _videoPlayerController!.pause();
          isPlaying = false;
        } else {
          _videoPlayerController!.play();
          isPlaying = true;
        }
      });
    }
  }

  Future<void> createLike() async {
    setState(() {
      heartIcon = true;
    });

    const String apiUrl = '$serverUrl/fashionReelLikes/';
    final Map<String, dynamic> postLike = {
      'likeEmoji': 1,
      'reel': widget.reelId,
      'user': widget.userId
    };
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };
    try {
      final response = await https.post(Uri.parse(apiUrl),
          headers: headers, body: jsonEncode(postLike));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          debugPrint("like posted");
          isLiked = true;
          heartIcon = false;
          if (widget.onLikeCreated != null) {
            widget.onLikeCreated!();
          }
        });
      }
      if (response.statusCode == 400) {
        setState(() {
          showToast(primary, "Reel already liked");
          heartIcon = false;
        });
      }
    } catch (e) {
      setState(() {
        heartIcon = false;
      });
      debugPrint("error posting like with exception ${e.toString()}");
    }
  }

  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
      _videoPlayerController!.setVolume(isMuted ? 0.0 : 1.0);
    });
  }

  createDislike() async {
    String apiUrl = '$serverUrl/fashionReelLikes/${widget.myLikes}/';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.token}',
    };
    try {
      await https.delete(
        Uri.parse(apiUrl),
        headers: headers,
      );
      debugPrint("reel disliked");
      showToast(primary, "Reel disliked");
      if (widget.onDislikeCreated != null) {
        widget.onDislikeCreated!();
      }
    } catch (e) {
      debugPrint("error disliking reel ${e.toString()}");
    }
  }

  addFan(from, to) {
    setState(() {
      requestLoader1 = true;
    });
    https
        .post(
      Uri.parse("$serverUrl/fansRequests/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({"from_user": from, "to_user": to}),
    )
        .then((value) {
      setState(() {
        requestLoader1 = false;
      });
      print(value.body.toString());
      getMyFriends(widget.friendId);
    }).catchError((value) {
      setState(() {
        requestLoader1 = false;
      });
      print(value);
    });
  }

  removeFan(fanId) {
    setState(() {
      requestLoader1 = true;
    });
    https.delete(
      Uri.parse("$serverUrl/fansfansRequests/$fanId/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).then((value) {
      setState(() {
        requestLoader1 = false;
      });
      print(value.body.toString());
      getMyFriends(widget.friendId);
    }).catchError((value) {
      setState(() {
        requestLoader1 = false;
      });
      print(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          _togglePlayPause();
        },
        onDoubleTap: () {
          createLike();
        },
        onLongPress: () {
          setState(() {
            _videoPlayerController!.setVolume(1.0);
          });
        },
        child: Stack(
          children: [
            // Video Player - Full Screen
            Container(
              width: double.infinity,
              height: double.infinity,
              child: _videoPlayerController != null &&
                      _videoPlayerController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController!),
                    )
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),

            // Top Gradient Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Gradient Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top Bar - Instagram Style
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reels Text
                    Text(
                      'Reels',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    // Camera Icon
                    GestureDetector(
                      onTap: () {
                        _videoPlayerController!.pause();
                        widget.navigateTo(38);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // View Count - Top Left
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.remove_red_eye,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      widget.reelCount,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Play/Pause Indicator
            if (_videoPlayerController != null &&
                _videoPlayerController!.value.isInitialized)
              Center(
                child: AnimatedOpacity(
                  opacity: isPlaying ? 0.0 : 1.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),

            // Double Tap Heart Animation
            Center(
              child: AnimatedOpacity(
                opacity: heartIcon ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: AnimatedScale(
                  scale: heartIcon ? 1.2 : 0.8,
                  duration: Duration(milliseconds: 300),
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 100,
                  ),
                ),
              ),
            ),

            // Bottom Content - Instagram Style Layout
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left Side - User Info & Description
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // User Info Row
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FriendProfileScreen(
                                        id: widget.friendId.toString(),
                                        username:
                                            Uri.decodeComponent(widget.name!),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundImage: widget.userPic.isNotEmpty
                                        ? NetworkImage(widget.userPic)
                                        : null,
                                    child: widget.userPic.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Colors.grey[600],
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FriendProfileScreen(
                                          id: widget.friendId.toString(),
                                          username:
                                              Uri.decodeComponent(widget.name!),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    Uri.decodeComponent(widget.name!),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (widget.friendId != id) ...[
                                SizedBox(width: 8),
                                loading
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: () {
                                          if (data["isFan"] == false) {
                                            addFan(id, widget.friendId);
                                          } else if (data["isFan"] == true) {
                                            removeFan(widget.friendId);
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: data["isFan"] == true
                                                ? Colors.transparent
                                                : Colors.white,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: requestLoader1
                                              ? SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      data["isFan"] == true
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                )
                                              : Text(
                                                  data["isFan"] == true
                                                      ? 'Following'
                                                      : 'Follow',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Poppins',
                                                    color: data["isFan"] == true
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                        ),
                                      ),
                              ],
                            ],
                          ),
                          SizedBox(height: 8),

                          // Description
                          if (widget.reelDescription != null &&
                              widget.reelDescription!.isNotEmpty)
                            Text(
                              widget.reelDescription!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    SizedBox(width: 16),

                    // Right Side - Action Buttons (Instagram Style)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Like Button
                        GestureDetector(
                          onTap: () {
                            widget.myLikes == null
                                ? createLike()
                                : createDislike();
                          },
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserLikeScreen(
                                  reelId: widget.reelId.toString(),
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                child: Icon(
                                  widget.myLikes == null
                                      ? Icons.favorite_border
                                      : Icons.favorite,
                                  color: widget.myLikes == null
                                      ? Colors.white
                                      : Colors.red,
                                  size: 28,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "${widget.likeCount}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Comment Button
                        if (widget.isCommentEnabled)
                          GestureDetector(
                            onTap: () {
                              _videoPlayerController!.pause();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReelCommentScreen(
                                    userPic: widget.userPic,
                                    reelId: widget.reelId!,
                                    commentId: null!,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),

                        if (widget.isCommentEnabled) SizedBox(height: 24),

                        // Share Button
                        GestureDetector(
                          onTap: () {
                            // Add share functionality
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // More Options Button
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.grey[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (context) => Container(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading:
                                          Icon(Icons.add, color: Colors.white),
                                      title: Text(
                                        'Add Flick',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      onTap: () {
                                        _videoPlayerController!.pause();
                                        Navigator.pop(context);
                                        widget.navigateTo(38);
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.report_outlined,
                                          color: Colors.white),
                                      title: Text(
                                        'Report Flick',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.navigateTo(39);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Mute/Unmute Button
                        GestureDetector(
                          onTap: _toggleMute,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// class ReelsInitializerScreen extends StatefulWidget {
//   final String? videoLink;
//   final String? name;
//   final String? reelDescription;
//   final int? likeCount;
//   final int? reelId;
//   final int? userId;
//   final String? token;
//   final int? myLikes;
//   final VoidCallback? onLikeCreated;
//   final VoidCallback? onDislikeCreated;
//   final VoidCallback? refreshReel;
//   final String userPic;
//   final String friendId;
//   final bool isCommentEnabled;
//   final String reelCount;
//   final Function navigateTo;
//   final Function navigateToPageWithReelReportArguments;

//   const ReelsInitializerScreen({
//     super.key,
//     this.videoLink,
//     this.name,
//     this.reelDescription,
//     this.likeCount,
//     this.reelId,
//     this.userId,
//     this.token,
//     this.myLikes,
//     this.onLikeCreated,
//     this.onDislikeCreated,
//     this.refreshReel,
//     required this.userPic,
//     required this.friendId,
//     required this.isCommentEnabled,
//     required this.reelCount,
//     required this.navigateTo,
//     required this.navigateToPageWithReelReportArguments,
//   });

//   @override
//   State<ReelsInitializerScreen> createState() => _ReelsInitializerScreenState();
// }

// class _ReelsInitializerScreenState extends State<ReelsInitializerScreen> {
//   VideoPlayerController? _videoPlayerController;
//   ChewieController? _chewieController;
//   bool isPlaying = true;
//   bool isLiked = false;
//   bool heartIcon = false;
//   Map<String, dynamic> data = {};
//   bool loading = false;
//   String id = "";
//   String token = "";
//   bool requestLoader1 = false;
//   bool isMuted = true;

//   getCachedData() async {
//     SharedPreferences preferences = await SharedPreferences.getInstance();
//     id = preferences.getString("id")!;
//     token = preferences.getString("token")!;
//     getMyFriends(widget.friendId);
//   }

//   getMyFriends(id) {
//     setState(() {
//       loading = true;
//     });
//     try {
//       https.get(Uri.parse("$serverUrl/user/api/allUsers/$id"), headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token"
//       }).then((value) {
//         print("Data ==> ${data.toString()}");
//         setState(() {
//           data = jsonDecode(value.body);
//         });
//         print("Friend data $data");
//         print(jsonDecode(value.body).toString());
//         setState(() {
//           loading = false;
//         });
//       });
//     } catch (e) {
//       setState(() {
//         loading = false;
//       });
//       print("Error --> $e");
//     }
//   }

//   @override
//   void initState() {
//     getCachedData();
//     print("Friend id ==> ${widget.friendId}");
//     if (widget.videoLink!.isNotEmpty) {
//       _videoPlayerController =
//           VideoPlayerController.networkUrl(Uri.parse(widget.videoLink!))
//             ..addListener(() => setState(() {}))
//             ..setLooping(true)
//             ..initialize().then((_) {
//               if (isPlaying) {
//                 _videoPlayerController!.play();
//                 _videoPlayerController!.setVolume(0.0);
//               }
//             });
//     }
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _videoPlayerController?.pause();
//     _videoPlayerController?.dispose();
//     _chewieController?.dispose();
//     super.dispose();
//   }

//   showToast(Color bg, String toastMsg) {
//     Fluttertoast.showToast(
//       msg: toastMsg,
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.BOTTOM,
//       timeInSecForIosWeb: 1,
//       backgroundColor: bg,
//       textColor: Colors.white,
//       fontSize: 16.0,
//     );
//   }

//   // FIXED: Corrected the play/pause toggle logic
//   void _togglePlayPause() {
//     if (_videoPlayerController != null &&
//         _videoPlayerController!.value.isInitialized) {
//       setState(() {
//         if (_videoPlayerController!.value.isPlaying) {
//           _videoPlayerController!.pause();
//           isPlaying = false;
//         } else {
//           _videoPlayerController!.play();
//           isPlaying = true;
//         }
//       });
//     }
//   }

//   Future<void> createLike() async {
//     heartIcon = true;
//     const String apiUrl = '$serverUrl/fashionReelLikes/';
//     final Map<String, dynamic> postLike = {
//       'likeEmoji': 1,
//       'reel': widget.reelId,
//       'user': widget.userId
//     };
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer ${widget.token}',
//     };
//     try {
//       final response = await https.post(Uri.parse(apiUrl),
//           headers: headers, body: jsonEncode(postLike));
//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         setState(() {
//           debugPrint("like posted");
//           isLiked = true;
//           heartIcon = false;
//           if (widget.onLikeCreated != null) {
//             widget.onLikeCreated!();
//           }
//         });
//       }
//       if (response.statusCode == 400) {
//         setState(() {
//           showToast(primary, "Reel already liked");
//         });
//       }
//     } catch (e) {
//       debugPrint("error posting like with exception ${e.toString()}");
//     }
//   }

//   void _toggleMute() {
//     setState(() {
//       isMuted = !isMuted;
//       _videoPlayerController!.setVolume(isMuted ? 0.0 : 1.0);
//     });
//   }

//   createDislike() async {
//     String apiUrl = '$serverUrl/fashionReelLikes/${widget.myLikes}/';
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer ${widget.token}',
//     };
//     try {
//       await https.delete(
//         Uri.parse(apiUrl),
//         headers: headers,
//       );
//       debugPrint("reel disliked");
//       showToast(primary, "Reel disliked");
//       if (widget.onDislikeCreated != null) {
//         widget.onDislikeCreated!();
//       }
//     } catch (e) {
//       debugPrint("error disliking reel ${e.toString()}");
//     }
//   }

//   addFan(from, to) {
//     setState(() {
//       requestLoader1 = true;
//     });
//     https
//         .post(
//       Uri.parse("$serverUrl/fansRequests/"),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token"
//       },
//       body: json.encode({"from_user": from, "to_user": to}),
//     )
//         .then((value) {
//       setState(() {
//         requestLoader1 = false;
//       });
//       print(value.body.toString());
//       getMyFriends(widget.friendId);
//     }).catchError((value) {
//       setState(() {
//         requestLoader1 = false;
//       });
//       print(value);
//     });
//   }

//   removeFan(fanId) {
//     setState(() {
//       requestLoader1 = true;
//     });
//     https.delete(
//       Uri.parse("$serverUrl/fansfansRequests/$fanId/"),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token"
//       },
//     ).then((value) {
//       setState(() {
//         requestLoader1 = false;
//       });
//       print(value.body.toString());
//       getMyFriends(widget.friendId);
//     }).catchError((value) {
//       setState(() {
//         requestLoader1 = false;
//       });
//       print(value);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         _togglePlayPause();
//       },
//       onDoubleTap: () {
//         createLike();
//       },
//       onLongPress: () {
//         setState(() {
//           _videoPlayerController!.setVolume(1.0);
//         });
//       },
//       child: Stack(children: [
//         ReelScreen(controller: _videoPlayerController),

//         // OPTIONAL: Add a visual indicator for play/pause state
//         if (_videoPlayerController != null &&
//             _videoPlayerController!.value.isInitialized)
//           Center(
//             child: AnimatedOpacity(
//               opacity: isPlaying ? 0.0 : 0.8,
//               duration: Duration(milliseconds: 300),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black54,
//                   borderRadius: BorderRadius.circular(50),
//                 ),
//                 child: Icon(
//                   isPlaying ? Icons.pause : Icons.play_arrow,
//                   color: Colors.white,
//                   size: 60,
//                 ),
//               ),
//             ),
//           ),

//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   PopupMenuButton(
//                     color: primary,
//                     itemBuilder: (context) {
//                       return [
//                         PopupMenuItem(
//                             child: GestureDetector(
//                                 onTap: () {
//                                   _videoPlayerController!.pause();
//                                   Navigator.pop(context);
//                                   widget.navigateTo(38);
//                                 },
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.add),
//                                     SizedBox(width: 10),
//                                     Text(
//                                       "Add Flick",
//                                       style: TextStyle(
//                                           fontFamily: Poppins,
//                                           fontSize: 14,
//                                           color: ascent),
//                                     )
//                                   ],
//                                 ))),
//                         PopupMenuItem(
//                             child: GestureDetector(
//                                 onTap: () {
//                                   Navigator.pop(context);
//                                   widget.navigateTo(39);
//                                 },
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.report_gmailerrorred),
//                                     SizedBox(width: 10),
//                                     Text(
//                                       "Report Flick",
//                                       style: TextStyle(
//                                           fontFamily: Poppins,
//                                           fontSize: 14,
//                                           color: ascent),
//                                     )
//                                   ],
//                                 )))
//                       ];
//                     },
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 70),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(left: 12.0, top: 12),
//           child: SizedBox(
//             width: 60,
//             child: Row(
//               children: [
//                 Text(
//                   widget.reelCount,
//                   style: const TextStyle(
//                     fontSize: 10,
//                     fontFamily: Poppins,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Icon(
//                   Icons.remove_red_eye,
//                   size: 20,
//                   color: primary,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const SizedBox(),
//               Center(
//                   child: Visibility(
//                       visible: heartIcon,
//                       child: Icon(
//                         Icons.star,
//                         size: 60,
//                         color: primary,
//                       ))),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     children: [
//                       const SizedBox(height: 50),
//                       Row(
//                         children: [
//                           const CircleAvatar(
//                             radius: 20,
//                             child: Icon(
//                               Icons.person,
//                               size: 26,
//                             ),
//                           ),
//                           const SizedBox(width: 6),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               GestureDetector(
//                                 onTap: () {
//                                   Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) =>
//                                             FriendProfileScreen(
//                                                 id: widget.friendId.toString(),
//                                                 username: Uri.decodeComponent(
//                                                     widget.name!)),
//                                       ));
//                                 },
//                                 child: Text(Uri.decodeComponent(widget.name!),
//                                     style: const TextStyle(
//                                         color: ascent,
//                                         fontFamily: Poppins,
//                                         fontSize: 16,
//                                         decoration: TextDecoration.none)),
//                               ),
//                               Text(
//                                 widget.reelDescription!,
//                                 style: const TextStyle(
//                                   color: ascent,
//                                   fontSize: 12,
//                                   fontFamily: Poppins,
//                                   decoration: TextDecoration.none,
//                                 ),
//                                 maxLines: 3,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       const SizedBox(width: 30),
//                       const SizedBox(height: 10)
//                     ],
//                   ),
//                   Column(
//                     children: [
//                       GestureDetector(
//                           onLongPress: () {
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => UserLikeScreen(
//                                       reelId: widget.reelId.toString()),
//                                 ));
//                           },
//                           onTap: () {
//                             widget.myLikes == null
//                                 ? createLike()
//                                 : createDislike();
//                           },
//                           child: widget.myLikes == null
//                               ? Icon(
//                                   Icons.star_border,
//                                   color: primary,
//                                   size: 30,
//                                 )
//                               : Icon(
//                                   Icons.star,
//                                   color: primary,
//                                   size: 30,
//                                 )),
//                       GestureDetector(
//                         onLongPress: () {},
//                         child: Text("${widget.likeCount}",
//                             style: const TextStyle(
//                                 color: ascent,
//                                 fontSize: 12,
//                                 fontFamily: Poppins,
//                                 decoration: TextDecoration.none)),
//                       ),
//                       widget.isCommentEnabled == true
//                           ? GestureDetector(
//                               onTap: () {
//                                 _videoPlayerController!.pause();
//                                 Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => ReelCommentScreen(
//                                         userPic: widget.userPic,
//                                         reelId: widget.reelId!,
//                                         commentId: null!,
//                                       ),
//                                     ));
//                               },
//                               child: Icon(
//                                 FontAwesomeIcons.comment,
//                                 color: primary,
//                                 size: 26,
//                               ),
//                             )
//                           : const SizedBox(),
//                       Icon(Icons.send),
//                       GestureDetector(
//                         onTap: _toggleMute,
//                         child: Padding(
//                           padding: const EdgeInsets.only(top: 8.0),
//                           child: Icon(
//                             isMuted ? Icons.volume_off : Icons.volume_up,
//                             color: primary,
//                             size: 26,
//                           ),
//                         ),
//                       ),
//                       if (widget.friendId != id)
//                         loading == true
//                             ? const SpinKitCircle(
//                                 color: ascent,
//                                 size: 20,
//                               )
//                             : GestureDetector(
//                                 onTap: () {
//                                   if (data["isFan"] == false) {
//                                     addFan(id, widget.friendId);
//                                   } else if (data["isFan"] == true) {
//                                     removeFan(widget.friendId);
//                                   }
//                                 },
//                                 child: Card(
//                                   shape: const RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.all(
//                                           Radius.circular(15))),
//                                   child: Container(
//                                     alignment: Alignment.center,
//                                     height: 30,
//                                     width:
//                                         MediaQuery.of(context).size.width * 0.2,
//                                     decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                             begin: Alignment.topLeft,
//                                             end: Alignment.topRight,
//                                             stops: const [0.0, 0.99],
//                                             tileMode: TileMode.clamp,
//                                             colors: data["isFan"] == true
//                                                 ? [Colors.grey, Colors.grey]
//                                                 : <Color>[
//                                                     secondary,
//                                                     primary,
//                                                   ]),
//                                         borderRadius: const BorderRadius.all(
//                                             Radius.circular(12))),
//                                     child: requestLoader1 == true
//                                         ? const SpinKitCircle(
//                                             color: ascent,
//                                             size: 20,
//                                           )
//                                         : Text(
//                                             data["isFan"] == true
//                                                 ? 'Unfan'
//                                                 : 'Fan',
//                                             style: const TextStyle(
//                                               fontSize: 10,
//                                               fontWeight: FontWeight.w700,
//                                               fontFamily: Poppins,
//                                             ),
//                                           ),
//                                   ),
//                                 ),
//                               ),
//                       const SizedBox(height: 20)
//                     ],
//                   )
//                 ],
//               ),
//             ],
//           ),
//         )
//       ]),
//     );
//   }
// }
