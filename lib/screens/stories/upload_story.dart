import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:finalfashiontimefrontend/screens/stories/post_story.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../animations/bottom_animation.dart';
import '../../../helpers/multipart_request.dart';
import '../../../utils/constants.dart';
import 'package:http/http.dart' as https;

class CreateStoryScreen extends StatefulWidget {


  const CreateStoryScreen({Key? key}) : super(key: key);

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final Shader linearGradient = LinearGradient(
    colors: <Color>[secondary, primary],
  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));
  TextEditingController caption = TextEditingController();
  File _video = File("");
  File _cameraVideo = File("");
  File _image = File("");
  final File _cameraImage = File("");
  ImagePicker picker = ImagePicker();
  double progress = 0;
  String result = "";
  String id = "";
  String token = "";
  String videoLink = "";
  String imageLink='';
  String editedImageLink="";
  bool isReelUploaded = false;
  bool isLoading = false;
  bool isImageEdited=false;
  File? fileVideo;
  bool value=true;
  Uint8List? thumbnailBytes;
  int? videoSize;
  var decoded;
  List<Map<String, String>> media = [];
  List<Map<String, String>> media1 = [];
  uploadVideoMedia(imagePath) async {
    // Navigator.pop(context);

    final request = MultipartRequest(
      'POST',
      Uri.parse("$serverUrl/fileUploader/"),
      onProgress: (int bytes, int total) {
        setState(() {
          progress = bytes / total;
          result = 'progress: $progress ($bytes/$total)';
        });
        debugPrint('progress: $progress ($bytes/$total)');
      },
    );

    request.files.add(await https.MultipartFile.fromPath(
      'document',
      imagePath,
      //contentType: MediaType('mp4','avi'),
    ));

    request.send().then((value) {
      setState(() {
        result = "";
      });
      debugPrint(value.stream.toString());
      value.stream.forEach((element) {
        decoded = utf8.decode(element);
        debugPrint("video-link is${jsonDecode(decoded)["document"]}");
        videoLink = jsonDecode(decoded)['document'];
        VideoThumbnail.thumbnailFile(
          video: imagePath,
          imageFormat: ImageFormat.JPEG,
          maxWidth:
          128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
          quality: 25,
        ).then((value) {
          setState(() {
            media.clear();
            media1.clear();
            media.add(
                {"video": jsonDecode(decoded)["document"], "type": "video"});
            media1.add({"image": value.toString(), "type": "video"});
            debugPrint("the length of media is ${media.length}");
          //  Fluttertoast.showToast(msg: "Done! Proceed to continue",backgroundColor: primary,);
          });
        });
      });
    });
  }

  getCachedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
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

  Future<void> postReel(imagePath) async {
    isLoading = true;
    const String apiUrl = '$serverUrl/fashionReel/';
    final Map<String, dynamic> postData = {
      "upload": {
        "media": [
          {"type": "video", "video": imagePath}
        ]
      },
      "description": caption.text,
      "user": id
    };
    final Map<String, dynamic> postData2 = {
      "upload": {
        "media": [
          {"type": "video", "video": imagePath}
        ]
      },
      "description": caption.text,
      "user": id,
      "isCommentOff":value
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    if(value==false){
      try {
        final response = await https.post(
          Uri.parse(apiUrl),
          headers: headers,
          body: jsonEncode(postData2),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          isLoading = false;
          media.clear();
          setState(() {});
          showToast(Colors.green, "Flick uploaded successfully");
          debugPrint("Post created successfully!");
          debugPrint("Response: ${response.body}");
          // widget.refreshReel!();
        } else {
          showToast(Colors.red, "Something went wrong!");
          debugPrint("Failed to create post.");
          debugPrint("Status Code: ${response.statusCode}");
          debugPrint("Response: ${response.body}");
        }
      } catch (e) {
        isLoading = false;
        setState(() {});
        debugPrint("An error occurred: $e");
      }
    }
    else{
      try {
        final response = await https.post(
          Uri.parse(apiUrl),
          headers: headers,
          body: jsonEncode(postData),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          isLoading = false;
          media.clear();
          setState(() {});
          showToast(Colors.green, "Flick uploaded successfully");
          debugPrint("Post created successfully!");
          debugPrint("Response: ${response.body}");
         // widget.refreshReel!();
        } else {
          showToast(Colors.red, "Something went wrong!");
          debugPrint("Failed to create post.");
          debugPrint("Status Code: ${response.statusCode}");
          debugPrint("Response: ${response.body}");
        }
      } catch (e) {
        isLoading = false;
        setState(() {});
        debugPrint("An error occurred: $e");
      }
    }


  }


  _pickVideo() async {
    XFile? pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    try {
      // MediaInfo? compressedVideoInfo = await VideoCompress.compressVideo(
      //   pickedFile!.path,
      //   quality: VideoQuality.Res640x480Quality, // Adjust quality as needed
      //   deleteOrigin:
      //   false, // Set to true if you want to delete the original video
      //   includeAudio: true, // Set to false to exclude audio
      // );
      //
      // if (compressedVideoInfo != null && compressedVideoInfo.path != null) {
      //   _video = File(compressedVideoInfo.path!);
      //   uploadVideoMedia(compressedVideoInfo.path!);
      // } else {
      //   debugPrint("bad compressing");
      // }
    } catch (error) {
      debugPrint(
          "error compressing and uploading video received this error ${error.toString()}");
    }
  }

  _pickVideoFromCamera() async {
    XFile? pickedFile = await picker.pickVideo(source: ImageSource.camera);

    _cameraVideo = File(pickedFile!.path);
    uploadVideoMedia(pickedFile.path);
  }
  // _pickImageFromGallery() async {
  //   PickedFile? pickedFile = await picker.getImage(source: ImageSource.gallery,);
  //
  //   File image = File(pickedFile!.path);
  //
  //   setState(() {
  //     _image = image;
  //   });
  //   uploadMedia(File(pickedFile!.path).path);
  // }
  Future<void> _pickImageFromGallery() async {
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File image = File(pickedFile.path);

      setState(() {
        _image = image;
      });

      Uint8List imageBytes = await image.readAsBytes(); // Convert image to Uint8List
      await uploadMedia(image.path, imageBytes);
    }
  }
  // uploadMedia(imagePath) async {
  //   Navigator.pop(context);
  //   var decoded;
  //   final request = MultipartRequest(
  //     'POST',
  //     Uri.parse("$serverUrl/fileUploader/"),
  //     onProgress: (int bytes, int total) {
  //       setState(() {
  //         progress = bytes / total;
  //         result = 'progress: $progress ($bytes/$total)';
  //       });
  //       print('progress: $progress ($bytes/$total)');
  //     },
  //   );
  //
  //   request.files.add(await https.MultipartFile.fromPath(
  //     'document',
  //     imagePath,
  //     contentType: MediaType('image', 'jpeg'),
  //   ));
  //
  //   request.send().then((value) {
  //     setState(() {
  //       result = "";
  //     });
  //     print(value.stream.toString());
  //     value.stream.forEach((element) {
  //       decoded = utf8.decode(element);
  //       print(jsonDecode(decoded)["document"]);
  //       imageLink=jsonDecode(decoded)["document"];
  //       setState(() {
  //         media
  //             .add({"image": jsonDecode(decoded)["document"], "type": "image"});
  //         media1.add({"image": imagePath, "type": "image"});
  //         Fluttertoast.showToast(msg: "Done! Proceed to continue",backgroundColor: primary);
  //       });
  //     });
  //   });
  // }
  Future<void> uploadMedia(String imagePath, Uint8List imageBytes) async {
    Navigator.pop(context);
    final request = https.MultipartRequest(
      'POST',
      Uri.parse("$serverUrl/fileUploader/"),
    );

    request.files.add(await https.MultipartFile.fromPath(
      'document',
      imagePath,
      contentType: MediaType('image', 'jpeg'),
    ));

    try {
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = utf8.decode(responseData);
      var decoded = jsonDecode(responseString);
      debugPrint(decoded["document"].toString());
      imageLink = decoded["document"];

      setState(() {
        media.add({"image": decoded["document"], "type": "image"});
        media1.add({"image": imagePath, "type": "image"});
      });

    //  Fluttertoast.showToast(msg: "Done! Proceed to continue", backgroundColor: primary);


      // ignore: use_build_context_synchronously
      var editedImage=await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(
            image: imageBytes,
          ),
        ),
      );
      if(editedImage!=null){
        imageBytes=editedImage;
        uploadImageAndGetLink(imageBytes);
      }
    } catch (error) {
      debugPrint("Error: $error");
      Fluttertoast.showToast(msg: "Failed to upload image", backgroundColor: Colors.red);
    }
  }
  Future<String?> uploadImageAndGetLink(Uint8List imageBytes) async {
    final request = https.MultipartRequest(
      'POST',
      Uri.parse("$serverUrl/fileUploader/"),
    );

    request.files.add(
      https.MultipartFile.fromBytes(
        'document',
        imageBytes,
        filename: 'upload.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = utf8.decode(responseData);
      var decoded = jsonDecode(responseString);
      editedImageLink=decoded['document'];
      // ignore: prefer_interpolation_to_compose_strings
      debugPrint("edited image link ===============>>"+decoded["document"]);
      setState(() {
        isImageEdited=true;
      });
      return decoded["document"];
    } catch (error) {
      debugPrint("Error: $error");
      return null;
    }
  }
  _pickImageFromCamera() async {
    XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

    File image = File(pickedFile!.path);
    Uint8List imageBytes = await image.readAsBytes();
    uploadMedia(File(pickedFile.path).path,imageBytes);
  }

  @override
  void initState() {
    // TODO: implement initState
    getCachedData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primary,
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                  stops: const [0.0, 0.99],
                  tileMode: TileMode.clamp,
                  colors: <Color>[
                    secondary,
                    primary,
                  ])),
        ),
        title: const Text(
          "Upload Story",
          style: TextStyle(fontFamily: Poppins),
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(
            height: 10,
          ),
          WidgetAnimator(GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                // loading = true;
              });
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext bc) {
                    return Wrap(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.videocam),
                          title: const Text(
                            'Video from gallery',
                            style: TextStyle(fontFamily: Poppins),
                          ),
                          onTap: () {
                            _pickVideo();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.fiber_smart_record),
                          title: const Text(
                            'Record video',
                            style: TextStyle(fontFamily: Poppins),
                          ),
                          onTap: () {
                            _pickVideoFromCamera();
                          },
                        ),
                        ListTile(
                            leading: const Icon(Icons.image),
                            title: const Text(
                              'Image from Gallery',
                              style:
                              TextStyle(fontFamily: Poppins),
                            ),
                            onTap: () {
                              _pickImageFromGallery();
                            }),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text(
                            'Capture image',
                            style: TextStyle(fontFamily: Poppins),
                          ),
                          onTap: () {
                            _pickImageFromCamera();
                          },
                        ),
                      ],
                    );
                  });
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 25.0, right: 25,top: 150),
              child: Row(
                children: [
                  Expanded(
                      child: Card(
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20))),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: result != ""
                              ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  LinearProgressIndicator(
                                    backgroundColor: Colors.grey,
                                    valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Colors.pink),
                                    value: progress,
                                  ),
                                  Text('${(progress * 100).round()}%'),
                                ],
                              ))
                              : ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (Rect bounds) => LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.topRight,
                                  stops: const [0.4, 0.6],
                                  tileMode: TileMode.clamp,
                                  colors: <Color>[
                                    secondary,
                                    primary,
                                  ]).createShader(bounds),
                              child: Icon(
                                Icons.cloud_upload_rounded,
                                size: 100,
                                color: primary,
                              )),
                        ),
                      ))
                ],
              ),
            ),
          )),
          // WidgetAnimator(
          //   Padding(
          //     padding: const EdgeInsets.only(
          //         left: 18.0, right: 18.0, top: 25, bottom: 18),
          //     child: Row(
          //       children: [
          //         const SizedBox(
          //           width: 10,
          //         ),
          //         Text(
          //           "Enter caption",
          //           style: TextStyle(
          //               fontSize: 20,
          //               fontWeight: FontWeight.w900,
          //               fontFamily: Poppins,
          //               foreground: Paint()..shader = linearGradient),
          //         )
          //       ],
          //     ),
          //   ),
          // ),
          // const SizedBox(
          //   height: 10,
          // ),
          // WidgetAnimator(
          //   Padding(
          //     padding: const EdgeInsets.only(
          //         left: 30.0, right: 30.0, top: 0.0, bottom: 8.0),
          //     child: TextField(
          //         controller: caption,
          //         maxLines: 5,
          //         maxLength: 2500,
          //         textCapitalization: TextCapitalization.sentences,
          //         style: TextStyle(color: primary, fontFamily: Poppins),
          //         decoration: InputDecoration(
          //             hintStyle: const TextStyle(
          //                 fontSize: 17,
          //                 fontWeight: FontWeight.w400,
          //                 fontFamily: Poppins),
          //             focusedBorder: OutlineInputBorder(
          //               borderSide: BorderSide(width: 1, color: primary),
          //             ),
          //             focusColor: primary,
          //             alignLabelWithHint: true,
          //             hintText: "Enter Caption"),
          //         cursorColor: primary,
          //         onChanged: (text) {}),
          //   ),
          // ),
          // Row(
          //   children: [
          //     Checkbox(
          //       activeColor: primary,
          //       checkColor: ascent,
          //       value: value,
          //       onChanged: (bool? val) {
          //         setState(() {
          //           value = val!;
          //         });
          //       },
          //     ),
          //     GestureDetector(
          //         onTap: () {
          //           //  FocusScope.of(context).unfocus();
          //           setState(() {
          //             value = !value;
          //           });
          //         },
          //         child: const Text(
          //           "Enable comments on flick?",
          //           style: TextStyle(fontFamily: Poppins),
          //         ))
          //   ],
          // ),

          media1.isNotEmpty?
          Column(
            children: [
              const SizedBox(height: 4,),
              Padding(
                padding:  EdgeInsets.only(right: Platform.isIOS? 300.0:270),
                child: InkWell(
                  child: const Icon(Icons.close,color: Colors.red,),
                  onTap: () {
                    media.clear();
                    media1.clear();
                    videoLink="";
                    setState(() {

                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 30.0, right: 30.0, top: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: media1.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      childAspectRatio: 11 / 8),
                  itemBuilder: (BuildContext context, int index) {
                    return WidgetAnimator(
                      GestureDetector(
                        onTap: () {
                          if (media1[index]["type"]! == "video") {
                            showDialog(

                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: primary,
                                title: const Text(
                                  "Flick",
                                  style: TextStyle(color: ascent),
                                ),
                                content: SingleChildScrollView(
                                  child: SizedBox(
                                    height: 200,
                                    child: Text("Video"),
                                    // child: UsingVideoControllerExample(
                                    //   path: media[index]["video"]!,
                                    // ),

                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(8),
                                actions: [
                                  TextButton(
                                    child: const Text("Okay",
                                        style: TextStyle(
                                            color: ascent,
                                            fontFamily: Poppins)),
                                    onPressed: () {
                                      setState(() {
                                        Navigator.pop(context);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: Card(
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: FileImage(
                                      File(media1[index]["image"]!))),
                              borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ):const SizedBox()
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 70,
        child: Column(
          children: [
            WidgetAnimator(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 37,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.0),
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.topRight,
                            stops: const [0.0, 0.99],
                            tileMode: TileMode.clamp,
                            colors: <Color>[
                              secondary,
                              primary,
                            ])),
                    child:
                        isImageEdited||videoLink!=""?
                    ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            )),
                            backgroundColor:
                            MaterialStateProperty.all(Colors.transparent),
                            shadowColor:
                            MaterialStateProperty.all(Colors.transparent),
                            padding: MaterialStateProperty.all(EdgeInsets.only(
                                top: 8,
                                bottom: 8,
                                left: MediaQuery.of(context).size.width * 0.26,
                                right:
                                MediaQuery.of(context).size.width * 0.26)),
                            textStyle: MaterialStateProperty.all(
                                const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontFamily: Poppins))),
                        onPressed: () {
                         setState(() {
                           media.clear();
                           media1.clear();
                         });
                          videoLink!=""||editedImageLink!=""
                              ? 
                          //postReel(videoLink)
                          editedImageLink==""?
                          Navigator.push(context, MaterialPageRoute(builder: (context) =>  PostStoryScreen(media: videoLink,isImage: false),)):
                          Navigator.push(context, MaterialPageRoute(builder: (context) =>  PostStoryScreen(media: editedImageLink,isImage: true),))
                              : showToast(Colors.red, "Make sure the media is uploaded!");
                        },
                        child: isLoading
                            ? SpinKitCircle(
                          size: 14,
                        )
                            : const Text(
                          'Upload Story',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFamily: Poppins),
                        )):const SizedBox(),
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
