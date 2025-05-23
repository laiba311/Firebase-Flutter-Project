import 'dart:convert';
import 'package:finalfashiontimefrontend/screens/stories/captured_screen.dart';
import 'package:finalfashiontimefrontend/screens/stories/captured_video_screen.dart';
import 'package:finalfashiontimefrontend/screens/stories/video_editor.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/giphy_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'add_text_story.dart';
import 'package:image/image.dart' as img;


class UploadStoryScreen extends StatefulWidget {
  @override
  _UploadStoryScreenState createState() => _UploadStoryScreenState();
}

class _UploadStoryScreenState extends State<UploadStoryScreen> {
  List<AssetEntity> _mediaList = [];
  ImagePicker picker = ImagePicker();
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();
  List<File> _capturedImages = [];

  Future<void> captureImages() async {
    bool continueCapturing = true;

    while (continueCapturing) {
      final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (capturedImage != null) {
        setState(() {
          _capturedImages.add(File(capturedImage.path));
        });
      }

      // Show a dialog asking if the user wants to capture another image
      continueCapturing = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Capture Another Image?",style: TextStyle(fontFamily: Poppins),),
            content: Text("Do you want to take another picture?",style: TextStyle(fontFamily: Poppins),),
            actions: [
              TextButton(
                child: Text("No",style: TextStyle(color: primary,fontFamily: Poppins),),
                onPressed: (){
                  Navigator.of(context).pop(false);
                  Navigator.of(context).pop(false);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CapturedScreen(capturedImages: _capturedImages)));
                },
              ),
              TextButton(
                child: Text("Yes",style: TextStyle(color: primary,fontFamily: Poppins),),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      ) ??
          false; // default to `false` if dialog is dismissed
    }
  }
  Future<void> captureVideos() async {
    bool continueCapturing = true;

    while (continueCapturing) {
      final XFile? capturedImage = await _picker.pickVideo(
        source: ImageSource.camera,
      );

      if (capturedImage != null) {
        setState(() {
          _capturedImages.add(File(capturedImage.path));
        });
      }

      // Show a dialog asking if the user wants to capture another image
      continueCapturing = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Capture Another Video?",style: TextStyle(fontFamily: Poppins),),
            content: Text("Do you want to take another video?",style: TextStyle(fontFamily: Poppins),),
            actions: [
              TextButton(
                child: Text("No",style: TextStyle(color: primary,fontFamily: Poppins),),
                onPressed: (){
                  Navigator.of(context).pop(false);
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => CapturedVideoScreen(capturedVideos: _capturedImages)));
                },
              ),
              TextButton(
                child: Text("Yes",style: TextStyle(color: primary,fontFamily: Poppins),),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      ) ??
          false; // default to `false` if dialog is dismissed
    }
  }

  @override
  void initState() {
    super.initState();
    //captureImages();
  }

  // Build grid of images

  // Open editor for selected image
  void _openImageEditor(AssetEntity asset) async {
    final file = await asset.file;
    if (file != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StoryEditor(selectedFile: file)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   leading: GestureDetector(
      //       onTap: (){
      //         Navigator.of(context).pop();
      //       },
      //       child: Icon(Icons.close)),
      //   centerTitle: true,
      //   title: Text('Upload Story',style: TextStyle(
      //     fontSize: 16,
      //       fontFamily: Poppins
      //   ),),
      //   backgroundColor: Colors.black,
      // ),
      body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () async {
                      XFile? pickedFile = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 100,
                      );

                      File image = File(pickedFile!.path);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StoryEditor(selectedFile: File(pickedFile.path))),
                      );
                    },
                    child: Center(
                      child: ListTile(
                        leading: const Icon(Icons.camera_alt,size: 60,color: ascent),
                        title: const Text(
                          'Capture Image',
                          style: TextStyle(fontFamily: Poppins,color: ascent),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Expanded(
              //   child: Card(
              //     child: InkWell(
              //       onTap: () {
              //         captureImages();
              //       },
              //       child: Padding(
              //         padding: const EdgeInsets.all(10.0),
              //         child: Center(
              //           child: ListTile(
              //             leading: const Icon(Icons.photo_library_outlined,size: 60,),
              //             title: const Text(
              //               'Capture multiple images',
              //               style: TextStyle(fontFamily: Poppins),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () async {
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => VideoEditorScreen()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Center(
                        child: ListTile(
                          leading: const Icon(Icons.video_call,size: 60,color: ascent),
                          title: const Text(
                            'Record Video',
                            style: TextStyle(fontFamily: Poppins,color: ascent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddTextStory()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Center(
                        child: ListTile(
                          leading: const Icon(Icons.text_fields,size: 60,color: ascent),
                          title: const Text(
                            'Write Text',
                            style: TextStyle(fontFamily: Poppins,color: ascent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Expanded(
              //   child: Card(
              //     child: InkWell(
              //       onTap: () {
              //         captureVideos();
              //         //Navigator.push(context, MaterialPageRoute(builder: (context) => VideoEditorScreen()));
              //       },
              //       child: Padding(
              //         padding: const EdgeInsets.all(10.0),
              //         child: Center(
              //           child: ListTile(
              //             leading: const Icon(Icons.video_collection_outlined,size: 60,),
              //             title: const Text(
              //               'Capture multiple video',
              //               style: TextStyle(fontFamily: Poppins),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ) // Show the grid of images
    );
  }
}

class StoryEditor extends StatefulWidget {
  final File selectedFile;

  StoryEditor({required this.selectedFile});

  @override
  _StoryEditorState createState() => _StoryEditorState();
}

class _StoryEditorState extends State<StoryEditor> {
  List<Widget> _editWidgets = [];
  TextEditingController _textController = TextEditingController();
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  File? _croppedImage;
  String id = '';
  String token = '';
  GlobalKey _storyEditorKey = GlobalKey();
  bool isUploading = false;
  bool open = false;
  List<Offset?> _points = []; // Stores the points for drawing
  bool _isDrawingMode = false;
  String? stickerUrl;
  Future<void> _openGiphyPicker() async {
    final gif = await GiphyPicker.pickGif(
        draggableController: _draggableController,
        context: context,
        apiKey: giphyKey,
        showPreviewPage: false,
        previewType: GiphyPreviewType.originalStill
    );

    if (gif != null) {
      setState(() {
        stickerUrl = gif.images.original!.url!; // Save the selected sticker URL
      });
    }
  }


  @override
  void initState() {
    super.initState();
    getCashedData();
  }

  Future<XFile> compressImage(File imageFile) async {
    final compressedImage = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      "${imageFile.path}_compressed.jpg",
      quality: 100, // Set quality to 100 for max preservation
    );
    return compressedImage!;
  }

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    debugPrint(preferences.getString("fcm_token"));
    debugPrint("user id is----->>>${preferences.getString("id")}");
  }

  // Function to crop the image
  Future<void> _cropImage() async {
    final croppedImage = await ImageCropper().cropImage(
      sourcePath: widget.selectedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
        WebUiSettings(
          context: context,
        )
      ],
    );

    if (croppedImage != null) {
      setState(() {
        _croppedImage = File(croppedImage.path);
      });
    }
  }

  // Future<void> saveImageToGallery() async {
  //   if (_croppedImage != null) {
  //     // Request permission to access the gallery
  //     var status = await Permission.storage.request();
  //
  //     if (status.isGranted) {
  //       try {
  //         // Convert the image to Uint8List format for saving
  //         final bytes = await _croppedImage!.readAsBytes();
  //         final result = await ImageGallerySaver.saveImage(Uint8List.fromList(bytes));
  //
  //         // Check if the image was successfully saved
  //         if (result['isSuccess']) {
  //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image saved to gallery!')));
  //         } else {
  //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save image.')));
  //         }
  //       } catch (e) {
  //         print('Error saving image: $e');
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permission denied!')));
  //     }
  //   }
  //   else {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please crop image first')));
  //   }
  // }

  Future<void> saveImageToGallery(BuildContext context) async {
    final imageToSave = _croppedImage ?? widget.selectedFile;
    var status = await (Platform.isAndroid && await Permission.manageExternalStorage.isDenied)
        ? await Permission.manageExternalStorage.request()
        : await Permission.storage.request();

    try {
      // Save the image to the gallery
      bool? success = await GallerySaver.saveImage(imageToSave.path);

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to gallery!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image.')),
        );
      }
    } catch (e) {
      print('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image.')),
      );
    }
    // if (imageToSave != null) {
    //   bool isPermissionGranted = false;
    //
    //   if (Platform.isAndroid) {
    //     if (await Permission.photos.isGranted) {
    //       isPermissionGranted = true;
    //     } else {
    //       var status = await Permission.photos.request();
    //       if (status.isGranted) {
    //         isPermissionGranted = true;
    //       }
    //     }
    //   } else {
    //     isPermissionGranted = true; // iOS does not require extra permissions
    //   }
    //
    //   if (isPermissionGranted) {
    //     try {
    //       // Save the image to the gallery
    //       bool? success = await GallerySaver.saveImage(imageToSave.path);
    //
    //       if (success == true) {
    //         ScaffoldMessenger.of(context).showSnackBar(
    //           SnackBar(content: Text('Image saved to gallery!')),
    //         );
    //       } else {
    //         ScaffoldMessenger.of(context).showSnackBar(
    //           SnackBar(content: Text('Failed to save image.')),
    //         );
    //       }
    //     } catch (e) {
    //       print('Error saving image: $e');
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(content: Text('Error saving image.')),
    //       );
    //     }
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Permission denied!')),
    //     );
    //   }
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('No image to save')),
    //   );
    // }
  }


  // Future<void> saveImageToGallery(BuildContext context) async {
  //   // Determine which image to save: cropped or original
  //   final imageToSave = _croppedImage ?? widget.selectedFile;
  //
  //   if (imageToSave != null) {
  //     // Request appropriate storage permissions
  //     bool isPermissionGranted = false;
  //
  //     if (Platform.isAndroid) {
  //       if (await Permission.storage.isGranted) {
  //         isPermissionGranted = true;
  //       } else if (Platform.isAndroid && await Permission.manageExternalStorage.isGranted) {
  //         isPermissionGranted = true;
  //       } else {
  //         // Request permissions based on Android version
  //         var status = await Permission.storage.request();
  //         if (status.isGranted) {
  //           isPermissionGranted = true;
  //         } else if (Platform.isAndroid && await Permission.manageExternalStorage.request().isGranted) {
  //           isPermissionGranted = true;
  //         }
  //       }
  //     } else {
  //       // For iOS, no special handling is required
  //       isPermissionGranted = true;
  //     }
  //
  //     if (isPermissionGranted) {
  //       try {
  //         // Get device screen dimensions
  //         final screenSize = MediaQuery.of(context).size;
  //         final screenWidth = screenSize.width.toInt();
  //         final screenHeight = screenSize.height.toInt();
  //
  //         // Read and resize the image to screen dimensions
  //         final bytes = await imageToSave.readAsBytes();
  //         final decodedImage = img.decodeImage(bytes);
  //         final resizedImage = img.copyResize(decodedImage!, width: screenWidth, height: screenHeight);
  //
  //         // Convert the resized image to Uint8List
  //         final resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage));
  //
  //         GallerySaver.saveImage(imageToSave.path).then((path) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(content: Text('Image saved to gallery!')),
  //                 );
  //         }).catchError((e){
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text('Failed to save image.')),
  //           );
  //         });
  //
  //       } catch (e) {
  //         print('Error saving image: $e');
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Error saving image.')),
  //         );
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Permission denied!')),
  //       );
  //     }
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('No image to save')),
  //     );
  //   }
  // }

  // Add draggable text
  void _addText(String text) {
    setState(() {
      _editWidgets.add(
        DraggableItem(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
                fontFamily: Poppins,
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
          ),
          initialPosition: Offset(50, 100), // Initial position for text
        ),
      );
    });
  }


  // Function to capture the image from the RepaintBoundary
  Future<void> _captureAndSaveImage() async {
    setState(() {
      isUploading = true;
    });
    try {
      RenderRepaintBoundary boundary =
      _storyEditorKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      double pixelRatio = 6.0; // Setting a high pixel ratio to maximize quality

      // Capture the image
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      // Convert the image to PNG bytes
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save the image to a temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/story_image.png').create();
      await file.writeAsBytes(pngBytes);

      uploadImage(file);
      print('Image saved: ${file.path}');
    } catch (e) {
      print('Error capturing image: $e');
    }
  }


  uploadImage(File imageFile) async {
    setState(() {
      isUploading = true;
    });
    String url = '$serverUrl/fileUploader/';

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data"
      });

      // Add the image file as multipart
      var mimeType = lookupMimeType(imageFile.path);  // Get mime type of the file
      request.files.add(await http.MultipartFile.fromPath(
        'document', // The field name for the image in form data
        imageFile.path,
        contentType: MediaType.parse(mimeType!), // Set the correct mime type
      ));

      // Send the request
      var response = await request.send();

      // Handle the response
      if (response.statusCode == 201) {
        var responseData = await http.Response.fromStream(response);
        print("Story Image Uploaded Successfully --> ${responseData.body}");
        var decotedData = json.decode(responseData.body);
        print(decotedData["document"]);
        if(mystory == true){
          postStory(decotedData["document"]);
        }else if (stylemates == true){
          postStoryForStyleMates(decotedData["document"]);
        }
      } else {
        setState(() {
          isUploading = false;
        });
        print("Failed to upload image. Status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      debugPrint("Error uploading image: ${e.toString()}");
    }
  }

  bool mystory = true;
  bool stylemates = false;

  postStory(String image) {
    String url = '$serverUrl/story/stories/';
    var body = {
        "content": image,
        "type": "image"
    };

    try {
      http
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
          //Navigator.pop(context);
        } else {
          debugPrint(
              "error received while uploading story===========>${value.statusCode}");
        }
      });
    } catch (e) {
      debugPrint("error received========>${e.toString()}");
    }
  }
  postStoryForStyleMates(String image) {
    String url = '$serverUrl/story/create-close-friends-story/';
    var body = {
      "content": image,
      "type": "image"
    };

    try {
      http
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
              msg: "Story uploaded for stylemates", backgroundColor: primary);
          Navigator.pop(context);
          //Navigator.pop(context);
        } else {
          debugPrint(
              "error received while uploading story===========>${value.statusCode}");
        }
      });
    } catch (e) {
      debugPrint("error received========>${e.toString()}");
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:isUploading == true ? () async {
        // Return `false` to disable back navigation
        return false;
      }: () async {
      // Return `false` to disable back navigation
      return true;
    },
      child: Scaffold(
        // appBar: AppBar(
        //   centerTitle: true,
        //   title: Text(
        //     'Edit Story',
        //     style: TextStyle(fontSize: 16,fontFamily: Poppins),
        //   ),
        //   leading: GestureDetector(
        //       onTap:isUploading == true ? (){}: (){
        //         Navigator.of(context).pop();
        //       },
        //       child: Icon(Icons.close)),
        //   backgroundColor: Colors.black,
        // ),
        body: Stack(
          children: [
            // Full-screen image preview wrapped in RepaintBoundary
            RepaintBoundary(
              key: _storyEditorKey, // Key for capturing image
              child: GestureDetector(
                onPanStart: _isDrawingMode ? _startDrawing : null,
                onPanUpdate: _isDrawingMode ? _updateDrawing : null,
                onPanEnd: _isDrawingMode ? _endDrawing : null,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        _croppedImage ?? widget.selectedFile,
                        fit: BoxFit.cover,
                      ),
                    ),
                    CustomPaint(
                      painter: DrawingPainter(_points),
                      child: Container(color: Colors.transparent),
                    ),
                    if (stickerUrl != null)
                      DraggableZoomableItem(
                        imageUrl: stickerUrl!, // Replace with your image URL
                      ),
                      // DraggableItem(
                      //   initialPosition: Offset(50, 100),
                      //   child: InteractiveViewer(
                      //     boundaryMargin: EdgeInsets.all(20),
                      //     minScale: 0.5, // Minimum zoom scale
                      //     maxScale: 3.0, // Maximum zoom scale
                      //     child: Image.network(
                      //       stickerUrl!,
                      //       width: 150,
                      //       height: 150,
                      //       fit: BoxFit.contain,
                      //     ),
                      //   ),
                      // ),
                    ..._editWidgets,
                  ],
                ),
              ),
            ),
            // Save or upload button
            Positioned(
              bottom: 20,
              left: 20,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: (){
                      setState(() {
                        mystory = true;
                        stylemates = false;
                      });
                    },
                    child: Card(
                      color: mystory == true ? primary : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text("Your Story",style: TextStyle(fontFamily: Poppins,color: ascent,fontSize: 12),),
                      ),
                    ),
                  ),
                  SizedBox(width: 5,),
                  GestureDetector(
                    onTap: (){
                      setState(() {
                        mystory = false;
                        stylemates = true;
                      });
                    },
                    child: Card(
                      color: stylemates == true ? primary : Colors.grey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text("Stylemates",style: TextStyle(fontFamily: Poppins,color: ascent,fontSize: 12)),
                      ),
                    ),
                  ),
                  SizedBox(width: 5,),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: isUploading == true ?(){}:(){
                      _captureAndSaveImage();
                    },
                    child: isUploading == true ? SpinKitCircle(color: Colors.white,) : Text('Upload story',style: TextStyle(fontFamily: Poppins,color: ascent,fontSize: 12),),
                  ),
                ],
              ),
            ),
            // Editing options
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 100,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap:(){
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                        child: Center( // Centers the Icon within the Container
                          child: Padding(
                            padding: const EdgeInsets.only(left:8.0),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: ascent,
                              size: 20, // Icon size set to fit inside the container
                            ),
                          ),
                        ),
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap:(){
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Add Text',style: TextStyle(fontFamily: Poppins),),
                            content: TextField(
                              style: TextStyle(fontFamily: Poppins),
                              controller: _textController,
                              decoration: InputDecoration(
                                hintStyle: TextStyle(fontFamily: Poppins),
                                border: InputBorder.none,
                                hintText: 'Enter your text',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  _addText(_textController.text);
                                  Navigator.pop(context);
                                },
                                child: Text('Add',style: TextStyle(
                                    color: primary,
                                    fontFamily: Poppins
                                ),),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                        child: Center( // Centers the Icon within the Container
                          child: Padding(
                            padding: const EdgeInsets.only(right:3.0),
                            child: Icon(
                              Icons.text_fields,
                              color: ascent,
                              size: 20, // Icon size set to fit inside the container
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10,),
                    GestureDetector(
                      onTap:_cropImage,
                      child: Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                        child: Center( // Centers the Icon within the Container
                          child: Padding(
                            padding: const EdgeInsets.only(right:3.0),
                            child: Icon(
                              Icons.crop,
                              color: ascent,
                              size: 20, // Icon size set to fit inside the container
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10,),
                    // GestureDetector(
                    //   onTap:(){
                    //     saveImageToGallery(context);
                    //   },
                    //   child: Container(
                    //     height: 35,
                    //     width: 35,
                    //     decoration: BoxDecoration(
                    //       color: Colors.black54,
                    //       borderRadius: BorderRadius.all(Radius.circular(50)),
                    //     ),
                    //     child: Center( // Centers the Icon within the Container
                    //       child: Padding(
                    //         padding: const EdgeInsets.only(right:3.0),
                    //         child: Icon(
                    //           Icons.download,
                    //           color: ascent,
                    //           size: 20, // Icon size set to fit inside the container
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(width: 10,),
                    GestureDetector(
                      onTap:(){
                        setState(() {
                          open = !open;
                        });
                      },
                      child: Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                        child: Center( // Centers the Icon within the Container
                          child: Padding(
                            padding: const EdgeInsets.only(right:3.0),
                            child: Icon(
                              Icons.more_horiz,
                              color: ascent,
                              size: 20, // Icon size set to fit inside the container
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if(open == true) Positioned(
              top: 90,
              right: 20,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if(_isDrawingMode == false) ListTile(
                      onTap: (){
                        setState(() {
                          _isDrawingMode = !_isDrawingMode;
                          open = false;
                        });
                      },
                      leading: Icon(Icons.draw_sharp,color: ascent,),
                      title: Text("Draw",style: TextStyle(fontFamily: Poppins,fontSize: 14,color: ascent),),
                    ),
                    if(_isDrawingMode == true) ListTile(
                      onTap: (){
                        setState(() {
                          _isDrawingMode = !_isDrawingMode;
                          _points.clear();
                          open = false;
                        });
                      },
                      leading: Icon(Icons.draw_sharp,color: ascent,),
                      title: Text("Clear lines",style: TextStyle(fontFamily: Poppins,fontSize: 14,color: ascent),),
                    ),
                    ListTile(
                      onTap: (){
                        _openGiphyPicker();
                        setState(() {
                          open = false;
                        });
                      },
                      leading: Icon(Icons.sticky_note_2_outlined,color: ascent,),
                      title: Text("Stikers",style: TextStyle(fontFamily: Poppins,fontSize: 14,color: ascent),),
                    ),
                    ListTile(
                      onTap: (){
                        saveImageToGallery(context);
                        setState(() {
                          open = false;
                        });
                      },
                      leading: Icon(Icons.download,color: ascent,),
                      title: Text("Download",style: TextStyle(fontFamily: Poppins,fontSize: 14,color: ascent),),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  void _startDrawing(DragStartDetails details) {
    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _updateDrawing(DragUpdateDetails details) {
    setState(() {
      _points.add(details.localPosition);
    });
  }

  void _endDrawing(DragEndDetails details) {
    _points.add(null); // Add a null value to indicate the end of a stroke
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// The draggable widget with persistent position
class DraggableItem extends StatefulWidget {
  final Widget child;
  final Offset initialPosition;

  DraggableItem({required this.child, required this.initialPosition});

  @override
  _DraggableItemState createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem> {
  Offset position = Offset(0, 0);

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition; // Set initial position
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        child: widget.child,
        feedback: Material(
          color: Colors.transparent,
          child: widget.child,
        ),
        childWhenDragging: Container(), // Hide the child while dragging
        onDragEnd: (details) {
          setState(() {
            // Update the position after dragging
            position = details.offset;
          });
        },
      ),
    );
  }
}

class DraggableZoomableItem extends StatefulWidget {
  final String imageUrl;

  const DraggableZoomableItem({Key? key, required this.imageUrl}) : super(key: key);

  @override
  _DraggableZoomableItemState createState() => _DraggableZoomableItemState();
}

class _DraggableZoomableItemState extends State<DraggableZoomableItem> {
  Offset _position = Offset(50, 100); // Initial position of the draggable item
  double _scale = 1.0; // Current scale of the item
  double _previousScale = 1.0; // Scale before the current gesture
  Offset _previousOffset = Offset.zero; // Previous position during a drag
  bool _isDragging = false; // Whether the item is being dragged

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onScaleStart: (details) {
              _previousScale = _scale;
              _previousOffset = details.focalPoint;
              _isDragging = true;
            },
            onScaleUpdate: (details) {
              setState(() {
                // Update scale
                _scale = _previousScale * details.scale;

                // Update position only if dragging
                if (_isDragging) {
                  final Offset delta = details.focalPoint - _previousOffset;
                  _position += delta;
                  _previousOffset = details.focalPoint;
                }
              });
            },
            onScaleEnd: (details) {
              _previousScale = _scale;
              _isDragging = false;
            },
            child: Transform(
              transform: Matrix4.identity()
                ..translate(0.0, 0.0)
                ..scale(_scale),
              alignment: Alignment.center,
              child: Image.network(
                widget.imageUrl,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
