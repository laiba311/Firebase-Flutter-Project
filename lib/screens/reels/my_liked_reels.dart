
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class MyLikedReelScreen extends StatefulWidget {
  final VideoPlayerController? controller;
  const MyLikedReelScreen({Key? key, required this.controller}) : super(key: key);

  @override
  State<MyLikedReelScreen> createState() => _MyLikedReelScreenState();
}

class _MyLikedReelScreenState extends State<MyLikedReelScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller!;
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Container(
      alignment: Alignment.topCenter,
      child: VideoPlayer(_controller),
    )
        : Shimmer.fromColors(
        baseColor: primary,
        highlightColor: ascent,
        child: Stack(children: [
          Center(
            child: Text(
              "FashionTime",
              style: TextStyle(
                  decoration: TextDecoration.none, fontFamily: Poppins),
            ),
          )
        ]));

  }
}
