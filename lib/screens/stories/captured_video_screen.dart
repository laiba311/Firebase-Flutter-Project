// import 'dart:io';
// // import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// // import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
// // import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
// // import 'package:ffmpeg_kit_flutter/return_code.dart';
// // import 'package:ffmpeg_kit_flutter/statistics.dart';
// import 'package:finalfashiontimefrontend/utils/constants.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:fraction/fraction.dart';
// // import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// // import 'package:video_editor/video_editor.dart'; // For video editing functionality
// import 'package:path_provider/path_provider.dart';
//
// class CapturedVideoScreen extends StatefulWidget {
//   final List<File> capturedVideos;
//   const CapturedVideoScreen({super.key, required this.capturedVideos});
//
//   @override
//   State<CapturedVideoScreen> createState() => _CapturedVideoScreenState();
// }
//
// class _CapturedVideoScreenState extends State<CapturedVideoScreen> {
//   Future<String> _getVideoThumbnail(String videoPath) async {
//     final thumbnailPath = await VideoThumbnail.thumbnailFile(
//       video: videoPath,
//       imageFormat: ImageFormat.PNG,
//       quality: 100,
//     );
//     return thumbnailPath!;
//   }
//
//   Future<void> _editVideo(int index) async {
//     File originalVideo = widget.capturedVideos[index];
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => VideoEditor(
//           file: originalVideo,
//           videoList: widget.capturedVideos,
//           index: index,
//         ),
//       ),
//     ).then((value){
//       setState(() {
//
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: GestureDetector(
//           onTap: () => Navigator.of(context).pop(),
//           child: Icon(Icons.close),
//         ),
//         centerTitle: true,
//         title: Text(
//           'Captured Videos',
//           style: TextStyle(
//             fontSize: 16,
//             fontFamily: Poppins,
//           ),
//         ),
//         backgroundColor: Colors.black,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: GridView.builder(
//               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 3,
//                 childAspectRatio: 0.6,
//               ),
//               itemCount: widget.capturedVideos.length,
//               itemBuilder: (context, index) {
//                 return FutureBuilder<String>(
//                   future: _getVideoThumbnail(widget.capturedVideos[index].path),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return Center(child: CircularProgressIndicator());
//                     }
//
//                     return Stack(
//                       children: [
//                         GestureDetector(
//                           onTap: () => _editVideo(index), // Open editor on tap
//                           child: Container(
//                             decoration: BoxDecoration(
//                               image: DecorationImage(
//                                 image: FileImage(File(snapshot.data!)),
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           top: 5,
//                           right: 10,
//                           child: GestureDetector(
//                             onTap: () {
//                               setState(() {
//                                 widget.capturedVideos.removeAt(index);
//                               });
//                             },
//                             child: Chip(
//                               label: Icon(
//                                 Icons.close,
//                                 color: Colors.red,
//                                 size: 20,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // VideoEditorScreen
// class VideoEditor extends StatefulWidget {
//   VideoEditor({super.key, required this.file, required this.videoList, required this.index});
//   final File file;
//   final List<File> videoList;
//   final int index;
//
//   @override
//   State<VideoEditor> createState() => _VideoEditorState();
// }
//
// class _VideoEditorState extends State<VideoEditor> {
//   final _exportingProgress = ValueNotifier<double>(0.0);
//   final _isExporting = ValueNotifier<bool>(false);
//   final double height = 50;
//
//   late VideoEditorController _controller = VideoEditorController.file(
//     widget.file,
//     minDuration: const Duration(seconds: 1),
//     maxDuration: const Duration(seconds: 60),
//   );
//
//   @override
//   void initState() {
//     super.initState();
//     _controller
//         .initialize(aspectRatio: 0.8)
//         .then((_) => setState(() {}))
//         .catchError((error) {
//       // handle minumum duration bigger than video duration error
//       Navigator.pop(context);
//     }, test: (e) => e is VideoMinDurationError);
//   }
//
//   @override
//   void didUpdateWidget(covariant VideoEditor oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Check if the new video file path is different from the previous one
//     if (oldWidget.file.path != widget.file.path) {
//       // Dispose the old controller and create a new one with the new file
//       _controller.dispose();
//       _controller = VideoEditorController.file(
//         widget.file,
//         minDuration: const Duration(seconds: 1),
//         maxDuration: const Duration(seconds: 10),
//       );
//       _controller
//           .initialize(aspectRatio: 0.8)
//           .then((_) => setState(() {}))
//           .catchError((error) {
//         Navigator.pop(context);
//       }, test: (e) => e is VideoMinDurationError);
//     }
//   }
//
//
//
//   @override
//   void dispose() async {
//     _exportingProgress.dispose();
//     _isExporting.dispose();
//     _controller.dispose();
//     ExportService.dispose();
//     super.dispose();
//   }
//
//   void _showErrorSnackBar(String message) =>
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           duration: const Duration(seconds: 1),
//         ),
//       );
//
//   // void _exportVideo() async {
//   //   _exportingProgress.value = 0;
//   //   _isExporting.value = true;
//   //
//   //   final config = VideoFFmpegVideoEditorConfig(
//   //     _controller,
//   //     commandBuilder: (config, videoPath, outputPath) {
//   //       final List<String> filters = config.getExportFilters();
//   //       filters.add('scale=1280:720');  // Scale video to 1280x720 resolution
//   //
//   //       // Build the FFmpeg command (removed -preset)
//   //       final String command = '-i $videoPath ${config.filtersCmd(filters)} '
//   //           '-b:v 4M -vf scale=1280:720 '
//   //           '-c:a copy -loglevel error $outputPath';  // Copy audio stream
//   //
//   //       // Log the command for debugging purposes
//   //       print("FFmpeg Command: $command");
//   //
//   //       return command;
//   //     },
//   //   );
//   //
//   //   // Execute the FFmpeg command
//   //   await ExportService.runFFmpegCommand(
//   //     await config.getExecuteConfig(),
//   //     onProgress: (stats) {
//   //       _exportingProgress.value = config.getFFmpegProgress(stats.getTime());
//   //     },
//   //     onError: (e, s) {
//   //       // Log and display error message
//   //       print("FFmpeg error: $e\nStacktrace: $s");
//   //       _showErrorSnackBar("Error on export video :( $e");
//   //     },
//   //     onCompleted: (file) {
//   //       _isExporting.value = false;
//   //       if (!mounted) return;
//   //       // Save exported video to gallery
//   //       saveImageToGallery(file);
//   //     },
//   //   );
//   // }
//
//
//   void _exportVideo(BuildContext context) async {
//     // Get screen dimensions
//     final screenWidth = MediaQuery.of(context).size.width.toInt();
//     final screenHeight = MediaQuery.of(context).size.height.toInt();
//
//     _exportingProgress.value = 0;
//     _isExporting.value = true;
//
//     final config = VideoFFmpegVideoEditorConfig(
//       _controller,
//       commandBuilder: (config, videoPath, outputPath) {
//         final List<String> filters = config.getExportFilters();
//         // Set video scale to device's width and height
//         filters.add('scale=$screenWidth:$screenHeight');
//
//         // Build the FFmpeg command
//         final String command = '-i $videoPath ${config.filtersCmd(filters)} '
//             '-b:v 4M -vf scale=$screenWidth:$screenHeight '
//             '-c:a copy -loglevel error $outputPath'; // Copy audio stream
//
//         // Log the command for debugging purposes
//         print("FFmpeg Command: $command");
//
//         return command;
//       },
//     );
//
//     // Execute the FFmpeg command
//     await ExportService.runFFmpegCommand(
//       await config.getExecuteConfig(),
//       onProgress: (stats) {
//         _exportingProgress.value = config.getFFmpegProgress(stats.getTime() as int);
//       },
//       onError: (e, s) {
//         // Log and display error message
//         print("FFmpeg error: $e\nStacktrace: $s");
//         _showErrorSnackBar("Error on export video :( $e");
//       },
//       onCompleted: (file) {
//         _isExporting.value = false;
//         if (!mounted) return;
//         // Save exported video to gallery
//         saveImageToGallery(file);
//       },
//     );
//   }
//
//
//   void _exportVideoForUpload() async {
//     print("Enter");
//     _exportingProgress.value = 0;
//     _isExporting.value = true;
//
//     final config = VideoFFmpegVideoEditorConfig(
//       _controller,
//       commandBuilder: (config, videoPath, outputPath) {
//         final List<String> filters = config.getExportFilters();
//         filters.add('scale=1280:720');  // Scale video to 1280x720 resolution
//
//         // Build the FFmpeg command (removed -preset)
//         final String command = '-i $videoPath ${config.filtersCmd(filters)} '
//             '-b:v 4M -vf scale=1280:720 '
//             '-c:a copy -loglevel error $outputPath';  // Copy audio stream
//
//         // Log the command for debugging purposes
//         print("FFmpeg Command: $command");
//
//         return command;
//       },
//     );
//
//     // Execute the FFmpeg command
//     await ExportService.runFFmpegCommand(
//       await config.getExecuteConfig(),
//       onProgress: (stats) {
//         _exportingProgress.value = config.getFFmpegProgress(stats.getTime() as int);
//       },
//       onError: (e, s) {
//         // Log and display error message
//         print("FFmpeg error: $e\nStacktrace: $s");
//         _showErrorSnackBar("Error on export video :( $e");
//       },
//       onCompleted: (file) {
//         _isExporting.value = false;
//         if (!mounted) return;
//         // upload story.
//        setState(() {
//          widget.videoList[widget.index] = file;
//        });
//         Navigator.pop(context);
//
//       },
//     );
//   }
//   Future<void> saveImageToGallery(File file) async {
//     if (file != null) {
//       // Request permission to access the gallery
//       var status = await (Platform.isAndroid && await Permission.manageExternalStorage.isDenied)
//           ? await Permission.manageExternalStorage.request()
//           : await Permission.storage.request();
//
//       if (status.isGranted) {
//         try {
//           // Save the file using ImageGallerySaver
//           // final result = await ImageGallerySaver.saveFile(file.path);
//           //
//           // // Check if the file was successfully saved
//           // if (result['isSuccess'] ?? false) {
//           //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video saved to gallery!')));
//           // } else {
//           //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save video.')));
//           // }
//         } catch (e) {
//           print('Error saving video: $e');
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permission denied!')));
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please crop image first')));
//     }
//   }
//
//   void _exportCover() async {
//     final config = CoverFFmpegVideoEditorConfig(_controller);
//     final execute = await config.getExecuteConfig();
//     if (execute == null) {
//       _showErrorSnackBar("Error on cover exportation initialization.");
//       return;
//     }
//
//     await ExportService.runFFmpegCommand(
//       execute,
//       onError: (e, s) => _showErrorSnackBar("Error on cover exportation :("),
//       onCompleted: (cover) {
//         if (!mounted) return;
//
//         showDialog(
//           context: context,
//           builder: (_) => CoverResultPopup(cover: cover),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async => false,
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         appBar: AppBar(
//           leading: GestureDetector(
//               onTap: (){
//                 Navigator.of(context).pop();
//               },
//               child: Icon(Icons.close)),
//           centerTitle: true,
//           title: Text('Upload Video',style: TextStyle(fontFamily: Poppins),),
//         ),
//         body: _controller.initialized
//             ? SafeArea(
//           child: Stack(
//             children: [
//               Column(
//                 children: [
//                   _topNavBar(),
//                   Expanded(
//                     child: DefaultTabController(
//                       length: 1,
//                       child: Column(
//                         children: [
//                           Expanded(
//                             child: TabBarView(
//                               viewportFraction: 1,
//                               physics: const NeverScrollableScrollPhysics(),
//                               children: [
//                                 Stack(
//                                   alignment: Alignment.center,
//                                   children: [
//                                     CropGridViewer.preview(
//                                         controller: _controller),
//                                     AnimatedBuilder(
//                                       animation: _controller.video,
//                                       builder: (_, __) => AnimatedOpacity(
//                                         opacity:
//                                         _controller.isPlaying ? 0 : 1,
//                                         duration: kThemeAnimationDuration,
//                                         child: GestureDetector(
//                                           onTap: _controller.video.play,
//                                           child: Container(
//                                             width: 40,
//                                             height: 40,
//                                             decoration:
//                                             const BoxDecoration(
//                                               color: Colors.white,
//                                               shape: BoxShape.circle,
//                                             ),
//                                             child: const Icon(
//                                               Icons.play_arrow,
//                                               color: Colors.black,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 //CoverViewer(controller: _controller)
//                               ],
//                             ),
//                           ),
//                           Container(
//                             height: 160,
//                             margin: const EdgeInsets.only(top: 10),
//                             child: Column(
//                               children: [
//                                 TabBar(
//                                   indicatorColor: primary,
//                                   tabs: [
//                                     Row(
//                                         mainAxisAlignment:
//                                         MainAxisAlignment.center,
//                                         children: const [
//                                           Padding(
//                                               padding: EdgeInsets.all(5),
//                                               child: Icon(
//                                                 Icons.content_cut,color: ascent,)),
//                                           Text('Trim',style: TextStyle(color: ascent),)
//                                         ]),
//                                     // Row(
//                                     //   mainAxisAlignment:
//                                     //   MainAxisAlignment.center,
//                                     //   children: const [
//                                     //     Padding(
//                                     //         padding: EdgeInsets.all(5),
//                                     //         child:
//                                     //         Icon(Icons.video_label,color: ascent,)),
//                                     //     Text('Cover',style: TextStyle(color: ascent))
//                                     //   ],
//                                     // ),
//                                   ],
//                                 ),
//                                 Expanded(
//                                   child: TabBarView(
//                                     physics:
//                                     const NeverScrollableScrollPhysics(),
//                                     children: [
//                                       Column(
//                                         mainAxisAlignment:
//                                         MainAxisAlignment.center,
//                                         children: _trimSlider(),
//                                       ),
//                                       //_coverSelection(),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           ValueListenableBuilder(
//                             valueListenable: _isExporting,
//                             builder: (_, bool export, Widget? child) =>
//                                 AnimatedSize(
//                                   duration: kThemeAnimationDuration,
//                                   child: export ? child : null,
//                                 ),
//                             child: AlertDialog(
//                               title: ValueListenableBuilder(
//                                 valueListenable: _exportingProgress,
//                                 builder: (_, double value, __) => Text(
//                                   "Exporting video ${(value * 100).ceil()}%",
//                                   style: const TextStyle(fontSize: 12),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               // Row(
//                               //   mainAxisAlignment: MainAxisAlignment.center,
//                               //   children: [
//                               //     GestureDetector(
//                               //       onTap: (){
//                               //         setState(() {
//                               //           mystory = true;
//                               //           stylemates = false;
//                               //         });
//                               //       },
//                               //       child: Card(
//                               //         color: mystory == true ? primary : Colors.grey,
//                               //         shape: RoundedRectangleBorder(
//                               //             borderRadius: BorderRadius.circular(20)
//                               //         ),
//                               //         child: Padding(
//                               //           padding: const EdgeInsets.all(10.0),
//                               //           child: Text("Your Story",style: TextStyle(fontFamily: Poppins),),
//                               //         ),
//                               //       ),
//                               //     ),
//                               //     SizedBox(width: 5,),
//                               //     GestureDetector(
//                               //       onTap: (){
//                               //         setState(() {
//                               //           mystory = false;
//                               //           stylemates = true;
//                               //         });
//                               //       },
//                               //       child: Card(
//                               //         color: stylemates == true ? primary : Colors.grey,
//                               //         shape: RoundedRectangleBorder(
//                               //             borderRadius: BorderRadius.circular(20)
//                               //         ),
//                               //         child: Padding(
//                               //           padding: const EdgeInsets.all(10.0),
//                               //           child: Text("Stylemates",style: TextStyle(fontFamily: Poppins),),
//                               //         ),
//                               //       ),
//                               //     ),
//                               //   ],
//                               // ),
//                               ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.black54,
//                                 ),
//                                 onPressed: (){
//                                   _exportVideoForUpload();
//                                 },
//                                 child: Text('Done',style: TextStyle(fontFamily: Poppins),),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//             ],
//           ),
//         )
//             : const Center(child: CircularProgressIndicator()),
//       ),
//     );
//   }
//
//   Widget _topNavBar() {
//     return SafeArea(
//       child: SizedBox(
//         height: height,
//         child: Row(
//           children: [
//             Expanded(
//               child: IconButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 icon: const Icon(Icons.exit_to_app),
//                 tooltip: 'Leave editor',
//               ),
//             ),
//             const VerticalDivider(endIndent: 22, indent: 22),
//             Expanded(
//               child: IconButton(
//                 onPressed: () =>
//                     _controller.rotate90Degrees(RotateDirection.left),
//                 icon: const Icon(Icons.rotate_left),
//                 tooltip: 'Rotate unclockwise',
//               ),
//             ),
//             Expanded(
//               child: IconButton(
//                 onPressed: () =>
//                     _controller.rotate90Degrees(RotateDirection.right),
//                 icon: const Icon(Icons.rotate_right),
//                 tooltip: 'Rotate clockwise',
//               ),
//             ),
//             Expanded(
//               child: IconButton(
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute<void>(
//                     builder: (context) => CropPage(controller: _controller),
//                   ),
//                 ),
//                 icon: const Icon(Icons.crop),
//                 tooltip: 'Open crop screen',
//               ),
//             ),
//             const VerticalDivider(endIndent: 22, indent: 22),
//             Expanded(
//               child: PopupMenuButton(
//                 tooltip: 'Open export menu',
//                 icon: const Icon(Icons.download),
//                 itemBuilder: (context) => [
//                   PopupMenuItem(
//                     onTap: (){
//                       _exportVideo(context);
//                     },
//                     child: const Text('Save to gallery'),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String formatter(Duration duration) => [
//     duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
//     duration.inSeconds.remainder(60).toString().padLeft(2, '0')
//   ].join(":");
//
//   List<Widget> _trimSlider() {
//     return [
//       AnimatedBuilder(
//         animation: Listenable.merge([
//           _controller,
//           _controller.video,
//         ]),
//         builder: (_, __) {
//           final int duration = _controller.videoDuration.inSeconds;
//           final double pos = _controller.trimPosition * duration;
//
//           return Padding(
//             padding: EdgeInsets.symmetric(horizontal: height / 4),
//             child: Row(children: [
//               Text(formatter(Duration(seconds: pos.toInt()))),
//               const Expanded(child: SizedBox()),
//               AnimatedOpacity(
//                 opacity: _controller.isTrimming ? 1 : 0,
//                 duration: kThemeAnimationDuration,
//                 child: Row(mainAxisSize: MainAxisSize.min, children: [
//                   Text(formatter(_controller.startTrim)),
//                   const SizedBox(width: 10),
//                   Text(formatter(_controller.endTrim)),
//                 ]),
//               ),
//             ]),
//           );
//         },
//       ),
//       Container(
//         width: MediaQuery.of(context).size.width,
//         margin: EdgeInsets.symmetric(vertical: height / 4),
//         child: TrimSlider(
//           controller: _controller,
//           height: height,
//           horizontalMargin: height / 4,
//           child: TrimTimeline(
//             controller: _controller,
//             padding: const EdgeInsets.only(top: 10),
//           ),
//         ),
//       )
//     ];
//   }
//
//   Widget _coverSelection() {
//     return SingleChildScrollView(
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(15),
//           child: CoverSelection(
//             controller: _controller,
//             size: height + 10,
//             quantity: 8,
//             selectedCoverBuilder: (cover, size) {
//               return Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   cover,
//                   Icon(
//                     Icons.check_circle,
//                     color: const CoverSelectionStyle().selectedBorderColor,
//                   )
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class CropPage extends StatelessWidget {
//   const CropPage({super.key, required this.controller});
//
//   final VideoEditorController controller;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 30),
//           child: Column(children: [
//             Row(children: [
//               Expanded(
//                 child: IconButton(
//                   onPressed: () =>
//                       controller.rotate90Degrees(RotateDirection.left),
//                   icon: const Icon(Icons.rotate_left),
//                 ),
//               ),
//               Expanded(
//                 child: IconButton(
//                   onPressed: () =>
//                       controller.rotate90Degrees(RotateDirection.right),
//                   icon: const Icon(Icons.rotate_right),
//                 ),
//               )
//             ]),
//             const SizedBox(height: 15),
//             Expanded(
//               child: CropGridViewer.edit(
//                 controller: controller,
//                 rotateCropArea: false,
//                 margin: const EdgeInsets.symmetric(horizontal: 20),
//               ),
//             ),
//             const SizedBox(height: 15),
//             Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
//               Expanded(
//                 flex: 2,
//                 child: IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Center(
//                     child: Text(
//                       "cancel",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 flex: 4,
//                 child: AnimatedBuilder(
//                   animation: controller,
//                   builder: (_, __) => Column(
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           IconButton(
//                             onPressed: () =>
//                             controller.preferredCropAspectRatio = controller
//                                 .preferredCropAspectRatio
//                                 ?.toFraction()
//                                 .inverse()
//                                 .toDouble(),
//                             icon: controller.preferredCropAspectRatio != null &&
//                                 controller.preferredCropAspectRatio! < 1
//                                 ? const Icon(
//                                 Icons.panorama_vertical_select_rounded)
//                                 : const Icon(Icons.panorama_vertical_rounded),
//                           ),
//                           IconButton(
//                             onPressed: () =>
//                             controller.preferredCropAspectRatio = controller
//                                 .preferredCropAspectRatio
//                                 ?.toFraction()
//                                 .inverse()
//                                 .toDouble(),
//                             icon: controller.preferredCropAspectRatio != null &&
//                                 controller.preferredCropAspectRatio! > 1
//                                 ? const Icon(
//                                 Icons.panorama_horizontal_select_rounded)
//                                 : const Icon(Icons.panorama_horizontal_rounded),
//                           ),
//                         ],
//                       ),
//                       Row(
//                         children: [
//                           _buildCropButton(context, null),
//                           _buildCropButton(context, 1.toFraction()),
//                           _buildCropButton(
//                               context, Fraction.fromString("9/16")),
//                           _buildCropButton(context, Fraction.fromString("3/4")),
//                         ],
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//               Expanded(
//                 flex: 2,
//                 child: IconButton(
//                   onPressed: () {
//                     // WAY 1: validate crop parameters set in the crop view
//                     controller.applyCacheCrop();
//                     // WAY 2: update manually with Offset values
//                     // controller.updateCrop(const Offset(0.2, 0.2), const Offset(0.8, 0.8));
//                     Navigator.pop(context);
//                   },
//                   icon: Center(
//                     child: Text(
//                       "done",
//                       style: TextStyle(
//                         color: const CropGridStyle().selectedBoundariesColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ]),
//           ]),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCropButton(BuildContext context, Fraction? f) {
//     if (controller.preferredCropAspectRatio != null &&
//         controller.preferredCropAspectRatio! > 1) f = f?.inverse();
//
//     return Flexible(
//       child: TextButton(
//         style: ElevatedButton.styleFrom(
//           elevation: 0,
//           backgroundColor: controller.preferredCropAspectRatio == f?.toDouble()
//               ? Colors.grey.shade800
//               : null,
//           foregroundColor: controller.preferredCropAspectRatio == f?.toDouble()
//               ? Colors.white
//               : null,
//           textStyle: Theme.of(context).textTheme.bodySmall,
//         ),
//         onPressed: () => controller.preferredCropAspectRatio = f?.toDouble(),
//         child: Text(f == null ? 'free' : '${f.numerator}:${f.denominator}'),
//       ),
//     );
//   }
// }
//
// class ExportService {
//   static Future<void> dispose() async {
//     final executions = await FFmpegKit.listSessions();
//     if (executions.isNotEmpty) await FFmpegKit.cancel();
//   }
//
//   static Future<FFmpegSession> runFFmpegCommand(
//       FFmpegVideoEditorExecute execute, {
//         required void Function(File file) onCompleted,
//         void Function(Object, StackTrace)? onError,
//         void Function(Statistics)? onProgress,
//       }) {
//     //log('FFmpeg start process with command = ${execute.command}');
//     return FFmpegKit.executeAsync(
//       execute.command,
//           (session) async {
//         final state =
//         FFmpegKitConfig.sessionStateToString(await session.getState());
//         final code = await session.getReturnCode();
//
//         if (ReturnCode.isSuccess(code)) {
//           onCompleted(File(execute.outputPath));
//         } else {
//           if (onError != null) {
//             onError(
//               Exception(
//                   'FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}'),
//               StackTrace.current,
//             );
//           }
//           return;
//         }
//       },
//       null,
//       onProgress,
//     );
//   }
// }
//
// Future<void> _getImageDimension(File file,
//     {required Function(Size) onResult}) async {
//   var decodedImage = await decodeImageFromList(file.readAsBytesSync());
//   onResult(Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()));
// }
//
// String _fileMBSize(File file) =>
//     ' ${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB';
//
// class CoverResultPopup extends StatefulWidget {
//   const CoverResultPopup({super.key, required this.cover});
//
//   final File cover;
//
//   @override
//   State<CoverResultPopup> createState() => _CoverResultPopupState();
// }
//
// class _CoverResultPopupState extends State<CoverResultPopup> {
//   late final Uint8List _imagebytes = widget.cover.readAsBytesSync();
//   Size? _fileDimension;
//   late String _fileMbSize;
//
//   @override
//   void initState() {
//     super.initState();
//     _getImageDimension(
//       widget.cover,
//       onResult: (d) => setState(() => _fileDimension = d),
//     );
//     _fileMbSize = _fileMBSize(widget.cover);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(30),
//       child: Center(
//         child: Stack(
//           children: [
//             Image.memory(_imagebytes),
//             Positioned(
//               bottom: 0,
//               child: FileDescription(
//                 description: {
//                   'Cover path': widget.cover.path,
//                   'Cover ratio':
//                   Fraction.fromDouble(_fileDimension?.aspectRatio ?? 0)
//                       .reduce()
//                       .toString(),
//                   'Cover dimension': _fileDimension.toString(),
//                   'Cover size': _fileMbSize,
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class FileDescription extends StatelessWidget {
//   const FileDescription({super.key, required this.description});
//
//   final Map<String, String> description;
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTextStyle(
//       style: const TextStyle(fontSize: 11),
//       child: Container(
//         width: MediaQuery.of(context).size.width - 60,
//         padding: const EdgeInsets.all(10),
//         color: Colors.black.withOpacity(0.5),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: description.entries
//               .map(
//                 (entry) => Text.rich(
//               TextSpan(
//                 children: [
//                   TextSpan(
//                     text: '${entry.key}: ',
//                     style: const TextStyle(fontSize: 11),
//                   ),
//                   TextSpan(
//                     text: entry.value,
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: Colors.white.withOpacity(0.8),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           )
//               .toList(),
//         ),
//       ),
//     );
//   }
// }