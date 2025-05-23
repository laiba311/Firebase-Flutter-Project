// import 'dart:io';
//
// import 'package:finalfashiontimefrontend/utils/constants.dart';
// import 'package:flutter/material.dart';
// import 'package:video_trimmer/video_trimmer.dart';
//
// class VideoTrimmingScreen extends StatefulWidget {
//   final String videoPath;
//   final Function uploadVideoMedia;
//   const VideoTrimmingScreen({Key? key, required this.videoPath, required this.uploadVideoMedia}) : super(key: key);
//
//   @override
//   _VideoTrimmingScreenState createState() => _VideoTrimmingScreenState();
// }
//
// class _VideoTrimmingScreenState extends State<VideoTrimmingScreen> {
//   final Trimmer _trimmer = Trimmer();
//   double _startValue = 0.0;
//   double _endValue = 900.0; // Default trim to 900 seconds
//   bool _isSaving = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _trimmer.loadVideo(videoFile: File(widget.videoPath));
//   }
//
//   _saveTrimmedVideo() async {
//     setState(() {
//       _isSaving = true;
//     });
//
//     await _trimmer.saveTrimmedVideo(
//       startValue: _startValue,
//       endValue: _endValue,
//       onSave: (outputPath) {
//         if (outputPath != null) {
//           debugPrint("Trimmed video saved at: $outputPath");
//           widget.uploadVideoMedia(outputPath);
//           Navigator.pop(context); // Go back after trimming
//         } else {
//           debugPrint("Error trimming video");
//         }
//
//         setState(() {
//           _isSaving = false;
//         });
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//           centerTitle: true,
//           title: Text(
//               "Trim Video",
//              style: TextStyle(fontFamily: Poppins),
//           )
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: VideoViewer(trimmer: _trimmer),
//           ),
//           TrimViewer(
//             trimmer: _trimmer,
//             viewerHeight: 50.0,
//             viewerWidth: MediaQuery.of(context).size.width,
//             maxVideoLength: const Duration(seconds: 900),
//             onChangeStart: (value) => _startValue = value,
//             onChangeEnd: (value) => _endValue = value,
//           ),
//           TextButton(
//             onPressed: _isSaving ? null : _saveTrimmedVideo,
//             child: _isSaving ? const CircularProgressIndicator() : Container(
//               height: 40,
//                 width: 200,
//                 decoration: BoxDecoration(
//                   color: primary,
//                   borderRadius: BorderRadius.all(Radius.circular(6))
//                 ),
//                 child: Center(child: Text("Save Trimmed Video",style: TextStyle(color: ascent,fontFamily: Poppins),))),
//           ),
//         ],
//       ),
//     );
//   }
// }
