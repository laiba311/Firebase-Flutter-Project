import 'dart:convert';
import 'package:chewie/chewie.dart';
import 'package:finalfashiontimefrontend/screens/reels/reels.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as https;
import '../../../utils/constants.dart';
class PostStoryScreen extends StatefulWidget {
  final String media;
  final bool isImage;
  const PostStoryScreen(
      {super.key, required this.media, required this.isImage});

  @override
  State<PostStoryScreen> createState() => _PostStoryScreenState();
}

class _PostStoryScreenState extends State<PostStoryScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool isPlaying = true;
  bool isLiked = false;
  bool heartIcon = false;
  String id = '';
  String token = '';

  @override
  void initState() {
    getCashedData();
    debugPrint("media===========>${widget.media}");
    // TODO: implement initState
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.media.toString()))
          ..addListener(() => setState(() {}))
          ..setLooping(true)
          ..initialize().then((_) {
            if (isPlaying) {
              _videoPlayerController!.play();
            }
          });

    super.initState();
    //initializePlayer();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    debugPrint(preferences.getString("fcm_token"));
    debugPrint("user id is----->>>${preferences.getString("id")}");
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

  postStory() {
    String url = '$serverUrl/apiStory/';
    var body = widget.isImage
        ? {
            "upload": {
              "media": [
                {'type': 'image', "image": widget.media.toString()}
              ]
            },
            "user": int.parse(id)
          }
        : {
            "upload": {
              "media": [
                {'type': 'video', "video": widget.media.toString()}
              ]
            },
            "user": int.parse(id)
          };

    try {
      https
          .post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      )
          .then((value) {
        if (value.statusCode == 201) {
          Fluttertoast.showToast(
              msg: "Story uploaded", backgroundColor: primary);
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          debugPrint(
              "error received while uploading story===========>${value.statusCode}");
          Fluttertoast.showToast(
              msg: "Error!Please try again.", backgroundColor: Colors.red);
        }
      });
    } catch (e) {
      debugPrint("error received========>${e.toString()}");
    }
  }
  postStoryCloseFriend() {
    String url = '$serverUrl/apiStory/';
    var body = widget.isImage
        ? {
      "upload": {
        "media": [
          {'type': 'image', "image": widget.media.toString()}
        ]
      },
      "user": int.parse(id),
      "is_close_friend":true,
    }
        : {
      "upload": {
        "media": [
          {'type': 'video', "video": widget.media.toString()}
        ]
      },
      "user": int.parse(id),
      "is_close_friend":true,
    };

    try {
      https
          .post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      )
          .then((value) {
        if (value.statusCode == 201) {
          Fluttertoast.showToast(
              msg: "Story uploaded", backgroundColor: primary);
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          debugPrint(
              "error received while uploading story===========>${value.statusCode}");
          Fluttertoast.showToast(
              msg: "Error!Please try again.", backgroundColor: Colors.red);
        }
      });
    } catch (e) {
      debugPrint("error received========>${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: widget.isImage
            ?
        SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width, // Full width
                  height: MediaQuery.of(context).size.height * 0.8, // Full height
                  child: Image.network(
                    widget.media.toString(),
                    fit: BoxFit.cover, // Cover the entire area
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ButtonStyle(
                            elevation: MaterialStateProperty.all(10.0),
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            backgroundColor: MaterialStateProperty.all(Colors.pinkAccent),
                            padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                              vertical: 13,
                              horizontal: MediaQuery.of(context).size.width * 0.1,
                            )),
                            textStyle: MaterialStateProperty.all(
                              const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontFamily: Poppins,
                              ),
                            ),
                          ),
                          onPressed: () {
                            postStory();
                          },
                          child: const Text(
                            'Upload Story',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: Poppins,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Add some spacing between the buttons
                        ElevatedButton(
                          style: ButtonStyle(
                            elevation: MaterialStateProperty.all(10.0),
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            backgroundColor: MaterialStateProperty.all(Colors.lightGreenAccent),
                            padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                              vertical: 13,
                              horizontal: MediaQuery.of(context).size.width * 0.1,
                            )),
                            textStyle: MaterialStateProperty.all(
                              const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontFamily: Poppins,
                              ),
                            ),
                          ),
                          onPressed: () {
                            postStoryCloseFriend();
                          },
                          child: const Text(
                            'Close friends',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: Poppins,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Add some bottom padding if needed
                  ],
                ),
              ],
            ),
          ),
        )

            : Stack(children: [
                ReelScreen(controller: _videoPlayerController),
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Story ",
                              style: TextStyle(
                                  color: primary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: Poppins,
                                  decoration: TextDecoration.none)),

                        ],
                      ),
                      Align(alignment: Alignment.topRight, child: Container()),
                     const Spacer(),
                      _videoPlayerController!.value.isPlaying ||
                          widget.isImage == true
                          ?
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  style: ButtonStyle(
                                    elevation: MaterialStateProperty.all(10.0),
                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    backgroundColor: MaterialStateProperty.all(Colors.pinkAccent),
                                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                                      vertical: 13,
                                      horizontal: MediaQuery.of(context).size.width * 0.1,
                                    )),
                                    textStyle: MaterialStateProperty.all(
                                      const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontFamily: Poppins,
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    postStory();
                                  },
                                  child: const Text(
                                    'Upload Story',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: Poppins,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10), // Add some spacing between the buttons
                                ElevatedButton(
                                  style: ButtonStyle(
                                    elevation: MaterialStateProperty.all(10.0),
                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    backgroundColor: MaterialStateProperty.all(Colors.lightGreenAccent),
                                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                                      vertical: 13,
                                      horizontal: MediaQuery.of(context).size.width * 0.1,
                                    )),
                                    textStyle: MaterialStateProperty.all(
                                      const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontFamily: Poppins,
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                  postStoryCloseFriend();
                                  },
                                  child: const Text(
                                    'Close friends',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: Poppins,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20), // Add some bottom padding if needed
                          ],
                        ),
                      )
                      // GestureDetector(
                      //         onTap: () {
                      //           postStory();
                      //         },
                      //         child: Padding(
                      //           padding: const EdgeInsets.all(5.0),
                      //           child: Icon(
                      //             Icons.check,
                      //             color: primary,
                      //             size: 40,
                      //           ),
                      //         ),
                      //       )
                          : const SizedBox(),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                height: 50,
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 6,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("",
                                          style: TextStyle(
                                              color: ascent,
                                              fontFamily: Poppins,
                                              fontSize: 16,
                                              decoration: TextDecoration.none)),
                                      Text(
                                        "",
                                        style: TextStyle(
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
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ]));
  }
}
