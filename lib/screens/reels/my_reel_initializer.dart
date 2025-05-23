
import 'package:chewie/chewie.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/post_like_user.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/reels/createReel.dart';
import 'package:finalfashiontimefrontend/screens/reels/my_reels.dart';
import 'package:finalfashiontimefrontend/screens/reels/reel_comment.dart';
import 'package:finalfashiontimefrontend/screens/reels/reel_comment.dart';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as https;
import '../../../utils/constants.dart';

class MyReelsInitializerScreen extends StatefulWidget {
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
  // final String pic;
  const MyReelsInitializerScreen({
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
  });

  @override
  State<MyReelsInitializerScreen> createState() =>
      _MyReelsInitializerScreenState();
}

class _MyReelsInitializerScreenState extends State<MyReelsInitializerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool isPlaying = true;
  bool isLiked = false;
  bool heartIcon = false;

  @override
  void initState() {
    // TODO: implement initState
    if (widget.videoLink!.isNotEmpty) {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoLink!))
            ..addListener(() => setState(() {}))
            ..setLooping(true)
            ..initialize().then((_) {
              if (isPlaying) {
                _videoPlayerController!.play();
              }
            });
    }

    super.initState();
    //initializePlayer();
  }
  deleteReel(reelId)async {
    String url="$serverUrl/fashionReel/$reelId/";

    showDialog(context: context, builder: (context) {
      return  AlertDialog(
        backgroundColor: primary,
        content: const Text("Delete flick?",style: TextStyle(color: ascent,fontFamily: Poppins)),title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold)),actions: [
        IconButton(onPressed: () async{
          try{
            final response=await https.delete(Uri.parse(url),headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer ${widget.token}"
            });
            if(response.statusCode==204){
              debugPrint("flick deleted successfully ");
              Navigator.pop(context);
            }
            else{
              debugPrint("error=============>${response.statusCode}");
            }
            // https.delete(Uri.parse(url),headers: {
            //   "Content-Type": "application/json",
            //   "Authorization": "Bearer $token"
            // });

          }
          catch(e){
            debugPrint("error received while unsaving fashion ==========>${e.toString()}");
          }
        }, icon: const Text("Yes",style: TextStyle(color: ascent,fontFamily: Poppins))),
        IconButton(onPressed: () {
          Navigator.pop(context);
        }, icon: const Text("No",style: TextStyle(color: ascent,fontFamily: Poppins)))
      ],);
    },);

  }
  @override
  void dispose() {
    // TODO: implement dispose
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _togglePlayPause();
      },
      child: Stack(children: [
        MyReelScreen(controller: _videoPlayerController),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Flicks",
                      style: TextStyle(
                          color: primary,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontFamily: Poppins,
                          decoration: TextDecoration.none)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        _videoPlayerController!.pause();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateReelScreen(
                              ),
                            ));
                      },
                      child: Icon(
                        Icons.add,
                        color: primary,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  GestureDetector(
                    onTap: () {
                      debugPrint("the id of reel is ========>${widget.reelId}");
                      deleteReel(widget.reelId);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: Icon(Icons.delete,color: primary,),
                    ),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const SizedBox(
                        height: 70,
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
                                                username: widget.name!),
                                      ));
                                },
                                child: Text(widget.name!,
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
                      Icon(
                        Icons.favorite,
                        color: primary,
                        size: 30,
                      ),
                      GestureDetector(
                        onLongPress: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                     PostLikeUserScreen(),
                              ));
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
                                // Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (context) => ReelCommentScreen(
                                //           userPic: widget.userPic,
                                //           reelId: widget.reelId!),
                                //     ));
                              },
                              child: Icon(
                                FontAwesomeIcons.comment,
                                color: primary,
                                size: 26,
                              ),
                            )
                          : const SizedBox()
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
