//
// import 'package:flutter/material.dart';
// import 'package:video_box/video_box.dart';
// class UsingVideoControllerExample extends StatefulWidget {
//   const UsingVideoControllerExample({Key? key, required this.path}) : super(key: key);
//   final String path;
//
//   @override
//   State<UsingVideoControllerExample> createState() => _UsingVideoControllerExampleState();
// }
//
// class _UsingVideoControllerExampleState extends State<UsingVideoControllerExample> {
//   late VideoController vc;
//   ScrollController controller = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }
//
//   void _init() async {
//     vc = VideoController(
//       source: VideoPlayerController.network(widget.path),
//       autoplay: false,
//     )
//       ..initialize().then((e) {
//         print(e);
//       })
//       ..addListener(() {
//         if (vc.videoCtrl.value.isBuffering) {
//           // ignore: avoid_print
//           print('==============================');
//           // ignore: avoid_print
//           print('isBuffering');
//           // ignore: avoid_print
//           print('==============================');
//         }
//       });
//   }
//
//   @override
//   void dispose() {
//     vc.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ListView(
//         controller: controller,
//         children: <Widget>[
//           AspectRatio(
//             aspectRatio: 12 / 9,
//             child: VideoBox(
//
//               controller: vc,
//               children: const <Widget>[
//                 // VideoBar(vc: vc),
//                 // Align(
//                 //   alignment: const Alignment(0.5, 0),
//                 //   child: IconButton(
//                 //     iconSize: VideoBox.centerIconSize,
//                 //     disabledColor: Colors.white60,
//                 //     icon: const Icon(Icons.skip_next),
//                 //     onPressed: () {},
//                 //   ),
//                 // ),
//               ],
//             ),
//           ),
//           // Wrap(
//           //   alignment: WrapAlignment.spaceBetween,
//           //   children: <Widget>[
//           //     ElevatedButton(
//           //       child: const Text('play'),
//           //       onPressed: () {
//           //         vc.play();
//           //       },
//           //     ),
//           //     ElevatedButton(
//           //       child: const Text('pause'),
//           //       onPressed: () {
//           //         vc.pause();
//           //       },
//           //     ),
//           //     ElevatedButton(
//           //       child: const Text('full screen'),
//           //       onPressed: () => vc.onFullScreenSwitch(context),
//           //     ),
//           //     ElevatedButton(
//           //       child: const Text('print'),
//           //       onPressed: () {
//           //         // ignore: avoid_print
//           //         print(vc);
//           //         // ignore: avoid_print
//           //         print(vc.value);
//           //       },
//           //     ),
//           //   ],
//           // ),
//         ],
//       ),
//     );
//   }
// }
//
// class VideoBar extends StatelessWidget {
//   final VideoController vc;
//   final List<double> speeds;
//
//   const VideoBar({
//     Key? key,
//     required this.vc,
//     this.speeds = const [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
//   }) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       left: 0,
//       top: 0,
//       right: 0,
//       child: AppBar(
//         backgroundColor: Colors.transparent,
//         title: const Text('test'),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.more_vert),
//             onPressed: () {
//               showModalBottomSheet(
//                 context: context,
//                 builder: (context) {
//                   return Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       ListTile(
//                         leading: const Icon(Icons.slow_motion_video),
//                         title: const Text('play speed'),
//                         onTap: () {
//                           showModalBottomSheet<double>(
//                             context: context,
//                             builder: (context) {
//                               return ListView(
//                                 children: speeds
//                                     .map((e) => ListTile(
//                                   title: Text(e.toString()),
//                                   onTap: () =>
//                                       Navigator.of(context).pop(e),
//                                 ))
//                                     .toList(),
//                               );
//                             },
//                           ).then((value) {
//                             if (value != null) vc.setPlaybackSpeed(value);
//                             Navigator.of(context).pop();
//                           });
//                         },
//                       ),
//                     ],
//                   );
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // import 'package:native_video_view/native_video_view.dart';
// // class UsingVideoControllerExample extends StatefulWidget {
// //   final String path;
// //   UsingVideoControllerExample({Key? key, required this.path}) : super(key: key);
// //
// //   @override
// //   _UsingVideoControllerExampleState createState() =>  _UsingVideoControllerExampleState();
// // }
// //
// // class _UsingVideoControllerExampleState extends State<UsingVideoControllerExample> {
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       alignment: Alignment.center,
// //       child: NativeVideoView(
// //         keepAspectRatio: true,
// //         showMediaController: true,
// //         enableVolumeControl: true,
// //         onCreated: (controller) {
// //           controller.setVideoSource(
// //             widget.path,
// //             sourceType: VideoSourceType.network,
// //             requestAudioFocus: true,
// //           );
// //         },
// //         onPrepared: (controller, info) {
// //           debugPrint('NativeVideoView: Video prepared');
// //           controller.play();
// //         },
// //         onError: (controller, what, extra, message) {
// //           debugPrint(
// //               'NativeVideoView: Player Error ($what | $extra | $message)');
// //         },
// //         onCompletion: (controller) {
// //           debugPrint('NativeVideoView: Video completed');
// //         },
// //       ),
// //     );
// //     // return Text("");
// //   }
// // }
