
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class ReelScreen extends StatefulWidget {
  final VideoPlayerController? controller;
  const ReelScreen({Key? key, required this.controller}) : super(key: key);

  @override
  State<ReelScreen> createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen> {
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
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.49999,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        : Shimmer.fromColors(
            baseColor: primary,
            highlightColor: ascent,
            child: Stack(children: [
              Center(
                child: Text(
                  "FashionTime",
                  style: TextStyle(
                      decoration: TextDecoration.none, fontFamily: Poppins,),
                ),
              )
            ]));
    //     : const SizedBox(
    //   height: 200,
    //   child: Center(
    //     child: CircularProgressIndicator(),
    //   ),
    // );
  }
}
