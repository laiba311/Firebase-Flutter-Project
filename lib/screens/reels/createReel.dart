import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
// import 'package:finalfashiontimefrontend/customize_pacages/trimmer/video_trimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../animations/bottom_animation.dart';
import '../../helpers/multipart_request.dart';
import '../../utils/constants.dart';
import 'package:http/http.dart' as https;


class CreateReelScreen extends StatefulWidget {
  //final VoidCallback? refreshReel;

  const CreateReelScreen({Key? key}) : super(key: key);

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final Shader linearGradient = LinearGradient(
    colors: <Color>[secondary, primary],
  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));
  TextEditingController caption = TextEditingController();
  File _video = File("");
  File _cameraVideo = File("");
  ImagePicker picker = ImagePicker();
  double progress = 0;
  String result = "";
  String id = "";
  String token = "";
  String videoLink = "";
  bool isReelUploaded = false;
  bool isLoading = false;
  File? fileVideo;
  bool value=true;
  Uint8List? thumbnailBytes;
  int? videoSize;
  var decoded;
  List<Map<String, String>> media = [];
  List<Map<String, String>> media1 = [];
  VideoPlayerController? controller1;
  // final Trimmer _trimmer = Trimmer();

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
        debugPrint("image-link is${jsonDecode(decoded)["document"]}");
        videoLink = jsonDecode(decoded)['document'];
        VideoThumbnail.thumbnailFile(
          video: imagePath,
          imageFormat: ImageFormat.JPEG,
          maxWidth:
              128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
          quality: 25,
        ).then((value) {
          setState(() {
            media.add(
                {"video": jsonDecode(decoded)["document"], "type": "video"});
            media1.add({"image": value.toString(), "type": "video"});
            debugPrint("the length of media is ${media.length}");
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
          //widget.refreshReel!();
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

  void _showVideoLengthError(context,pickedFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Video length exceeded", style: TextStyle(fontFamily: Poppins)),
          content: Text("Please select a video that is 15 min or shorter.", style: TextStyle(fontFamily: Poppins)),
          actions: [
            TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => VideoTrimmingScreen(videoPath: pickedFile,uploadVideoMedia: uploadVideoMedia,),
              //   ),
              // );
            },
            child: Text("Trim", style: TextStyle(fontFamily: Poppins,color: primary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK", style: TextStyle(fontFamily: Poppins,color: primary)),
            ),
          ],
        );
      },
    );
  }
  _pickVideo(context) async {
    XFile? pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    try {
      VideoPlayerController controller = VideoPlayerController.file(File(pickedFile!.path));
      await controller.initialize();
      final videoDuration = controller.value.duration.inSeconds;
      print("duration ${videoDuration}");
      if (videoDuration > 900) {
        print("Selected video exceeds 900 seconds");
        // Show a message to the user
        Navigator.pop(context);
        _showVideoLengthError(context,pickedFile.path);
      }
      else {
        print("else body");
        Navigator.pop(context);
        _video = File(pickedFile.path);
        uploadVideoMedia(pickedFile.path);
      }
      controller.dispose();
    } catch (error) {
      print("error compressing and uploading video received this error ${error.toString()}");
    }
  }

  _pickVideoFromCamera(context) async {
    XFile? pickedFile = await picker.pickVideo(source: ImageSource.camera);
    VideoPlayerController controller = VideoPlayerController.file(File(pickedFile!.path));
    await controller.initialize();
    final videoDuration = controller.value.duration.inSeconds;
    controller.dispose();

    if (videoDuration > 900) {
      print("Selected video exceeds 900 seconds");
      // Show a message to the user
      Navigator.pop(context);
      _showVideoLengthError(context,pickedFile.path);
    }else {
      print("Selected video");
      Navigator.pop(context);
      _cameraVideo = File(pickedFile.path);
      uploadVideoMedia(pickedFile.path);
    }
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
      // appBar: AppBar(
      //   centerTitle: true,
      //   backgroundColor: primary,
      //   flexibleSpace: Container(
      //     decoration: BoxDecoration(
      //         gradient: LinearGradient(
      //             begin: Alignment.topLeft,
      //             end: Alignment.topRight,
      //             stops: const [0.0, 0.99],
      //             tileMode: TileMode.clamp,
      //             colors: <Color>[
      //               secondary,
      //               primary,
      //             ])),
      //   ),
      //   title: const Text(
      //     "Create Flick",
      //     style: TextStyle(fontFamily: Poppins,),
      //   ),
      // ),
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
                            style: TextStyle(fontFamily: Poppins,),
                          ),
                          onTap: () {
                            _pickVideo(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.fiber_smart_record),
                          title: const Text(
                            'Record video',
                            style: TextStyle(fontFamily: Poppins,),
                          ),
                          onTap: () {
                            _pickVideoFromCamera(context);
                          },
                        ),
                      ],
                    );
                  });
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 25.0, right: 25),
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
          WidgetAnimator(
            Padding(
              padding: const EdgeInsets.only(
                  left: 18.0, right: 18.0, top: 25, bottom: 18),
              child: Row(
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Enter caption",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: Poppins,
                        foreground: Paint()..shader = linearGradient),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          WidgetAnimator(
            Padding(
              padding: const EdgeInsets.only(
                  left: 30.0, right: 30.0, top: 0.0, bottom: 8.0),
              child: TextField(
                  controller: caption,
                  maxLines: 5,
                  maxLength: 2500,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: primary, fontFamily: Poppins,),
                  decoration: InputDecoration(
                      hintStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        fontFamily: Poppins,),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 1, color: primary),
                      ),
                      focusColor: primary,
                      alignLabelWithHint: true,
                      hintText: "Enter Caption"),
                  cursorColor: primary,
                  onChanged: (text) {}),
            ),
          ),
          Row(
            children: [
              Checkbox(
                activeColor: primary,
                checkColor: ascent,
                value: value,
                onChanged: (bool? val) {
                  setState(() {
                    value = val!;
                  });
                },
              ),
              GestureDetector(
                  onTap: () {
                    //  FocusScope.of(context).unfocus();
                    setState(() {
                      value = !value;
                    });
                  },
                  child: const Text(
                    "Enable comments on flick?",
                    style: TextStyle(fontFamily: Poppins,),
                  ))
            ],
          ),

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
                            if(media1[index]["type"]! == "video") {
                              controller1 = VideoPlayerController
                                  .network(
                                  '${media[index]["video"]!}')
                                ..initialize().then((
                                    _) {});
                              controller1!.play();
                            }
                            showDialog(

                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: primary,
                                title: const Text(
                                  "Flick",
                                  style: TextStyle(color: ascent,fontFamily: Poppins,),
                                ),
                                content: SingleChildScrollView(
                                  child: SizedBox(
                                    height: 200,

                                    child: VideoPlayer(controller1!)

                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(8),
                                actions: [
                                  TextButton(
                                    child: const Text("Okay",
                                        style: TextStyle(
                                            color: ascent,
                                          fontFamily: Poppins,)),
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
                    child: ElevatedButton(
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
                                  fontFamily: Poppins,))),
                        onPressed: () {
                          media.clear();
                           videoLink!=""
                              ? postReel(videoLink)
                              : showToast(Colors.red, "Make sure the Flick is uploaded!");
                        },
                        child: isLoading
                            ? SpinKitCircle(
                                size: 14,
                              )
                            : const Text(
                                'Upload Flick',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: ascent,
                                    fontWeight: FontWeight.w700,
                                  fontFamily: Poppins,),
                              )),
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
