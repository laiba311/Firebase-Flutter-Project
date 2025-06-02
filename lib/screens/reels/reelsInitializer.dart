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
  // final String pic;
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
    // TODO: implement initState
    // if(widget.videoLink.isNotEmpty){
    //   _videoPlayerController=VideoPlayerController.networkUrl(Uri.parse(widget.videoLink))..addListener(()=>setState(() {
    //
    //   }))..setLooping(true)..initialize().then((_)=>_videoPlayerController!.play());
    // }
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
    //initializePlayer();
  }

  // Future initializePlayer() async {
  //   _videoPlayerController =
  //       VideoPlayerController.networkUrl(Uri.parse(widget.videoLink),);
  //   await Future.wait([_videoPlayerController!.initialize()]);
  //   _chewieController = ChewieController(
  //       videoPlayerController: _videoPlayerController!, autoPlay: true,
  //
  //   looping: true,
  //   showControls: false,);
  //   setState(() {
  //
  //   });
  // }

  @override
  void dispose() {
    // TODO: implement dispose
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
    if (_videoPlayerController!.value.isPlaying) {
      _videoPlayerController!.pause();
    } else {
      _videoPlayerController!.play();
    }
    setState(() {
      isPlaying = !_videoPlayerController!.value.isPlaying;
    });
  }

  Future<void> createLike() async {
    heartIcon = true;
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
          // showToast(primary, "Reel liked");
          if (widget.onLikeCreated != null) {
            widget.onLikeCreated!();
          }
        });
      }
      if (response.statusCode == 400) {
        setState(() {
          showToast(primary, "Reel already liked");
        });
      }
    } catch (e) {
      debugPrint("error posting like with exception ${e.toString()}");
    }
  }

// Add this method to toggle mute/unmute
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
    return GestureDetector(
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
      child: Stack(children: [
        ReelScreen(controller: _videoPlayerController),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton(
                    color: primary,
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                            child: GestureDetector(
                                onTap: () {
                                  _videoPlayerController!.pause();
                                  Navigator.pop(context);
                                  widget.navigateTo(38);
                                  // Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //       builder: (context) => CreateReelScreen(
                                  //       ),
                                  //     ));
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "Add Flick",
                                      style: TextStyle(
                                          fontFamily: Poppins,
                                          fontSize: 14,
                                          color: ascent),
                                    )
                                  ],
                                ))),
                        PopupMenuItem(
                            child: GestureDetector(
                                onTap: () {
                                  {
                                    Navigator.pop(context);
                                    widget.navigateTo(39);
                                    // Navigator.push(
                                    //     context,
                                    //     MaterialPageRoute(
                                    //         builder: (context) =>
                                    //             ReelReportScreen(
                                    //                 reelId: widget.reelId!.toString(),
                                    //                 userId: widget.userId!.toString())));
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.report_gmailerrorred,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      "Report Flick",
                                      style: TextStyle(
                                          fontFamily: Poppins,
                                          fontSize: 14,
                                          color: ascent),
                                    )
                                  ],
                                )))
                      ];
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 70,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 12),
          child: SizedBox(
            width: 60,
            child: Row(
              children: [
                Text(
                  widget.reelCount,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: Poppins,
                  ),
                ),
                const SizedBox(
                  width: 4,
                ),
                Icon(
                  Icons.remove_red_eye,
                  size: 20,
                  color: primary,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Center(
                  child: Visibility(
                      visible: heartIcon,
                      child: Icon(
                        Icons.star,
                        size: 60,
                        color: primary,
                      ))),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(
                        height: 50,
                      ),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            child:
                                //     widget.pic!=null?
                                // Image.network(widget.pic,):
                                Icon(
                              Icons.person,
                              size: 26,
                            ),
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FriendProfileScreen(
                                                id: widget.friendId.toString(),
                                                username: Uri.decodeComponent(
                                                    widget.name!)),
                                      ));
                                },
                                child: Text(Uri.decodeComponent(widget.name!),
                                    style: const TextStyle(
                                        color: ascent,
                                        fontFamily: Poppins,
                                        fontSize: 16,
                                        decoration: TextDecoration.none)),
                              ),
                              Text(
                                widget.reelDescription!,
                                style: const TextStyle(
                                  color: ascent,
                                  fontSize: 12,
                                  fontFamily: Poppins,
                                  decoration: TextDecoration.none,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      const SizedBox(
                        height: 10,
                      )
                    ],
                  ),
                  Column(
                    children: [
                      GestureDetector(
                          onLongPress: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserLikeScreen(
                                      reelId: widget.reelId.toString()),
                                ));
                          },
                          onTap: () {
                            widget.myLikes == null
                                ? createLike()
                                : createDislike();
                          },
                          child: widget.myLikes == null
                              ? Icon(
                                  Icons.star_border,
                                  color: primary,
                                  size: 30,
                                )
                              : Icon(
                                  Icons.star,
                                  color: primary,
                                  size: 30,
                                )),
                      GestureDetector(
                        onLongPress: () {
//Navigator.push(context,MaterialPageRoute(builder: (context) => const LikedUserReelScreen(),));
                        },
                        child: Text("${widget.likeCount}",
                            style: const TextStyle(
                                color: ascent,
                                fontSize: 12,
                                fontFamily: Poppins,
                                decoration: TextDecoration.none)),
                      ),
                      widget.isCommentEnabled == true
                          ? GestureDetector(
                              onTap: () {
                                _videoPlayerController!.pause();
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReelCommentScreen(
                                          userPic: widget.userPic,
                                          reelId: widget.reelId!),
                                    ));
                              },
                              child: Icon(
                                FontAwesomeIcons.comment,
                                color: primary,
                                size: 26,
                              ),
                            )
                          : const SizedBox(),
                      GestureDetector(
                        onTap: _toggleMute,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Icon(
                            isMuted ? Icons.volume_off : Icons.volume_up,
                            color: primary,
                            size: 26,
                          ),
                        ),
                      ),
                      if (widget.friendId != id)
                        loading == true
                            ? const SpinKitCircle(
                                color: ascent,
                                size: 20,
                              )
                            : GestureDetector(
                                onTap: () {
                                  if (data["isFan"] == false) {
                                    addFan(id, widget.friendId);
                                  } else if (data["isFan"] == true) {
                                    removeFan(widget.friendId);
                                  }
                                  //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                                },
                                child: Card(
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(15))),
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 30,
                                    width:
                                        MediaQuery.of(context).size.width * 0.2,
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            stops: const [0.0, 0.99],
                                            tileMode: TileMode.clamp,
                                            colors: data["isFan"] == true
                                                ? [Colors.grey, Colors.grey]
                                                : <Color>[
                                                    secondary,
                                                    primary,
                                                  ]),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(12))),
                                    child: requestLoader1 == true
                                        ? const SpinKitCircle(
                                            color: ascent,
                                            size: 20,
                                          )
                                        : Text(
                                            data["isFan"] == true
                                                ? 'Unfan'
                                                : 'Fan',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: Poppins,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                      const SizedBox(
                        height: 20,
                      )
                    ],
                  )
                ],
              ),
            ],
          ),
        )
      ]),
    );
  }
}
