import 'dart:convert';
import 'dart:io';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';

class CapturedScreen extends StatefulWidget {
  final List<File> capturedImages;
  const CapturedScreen({super.key, required this.capturedImages});

  @override
  State<CapturedScreen> createState() => _CapturedScreenState();
}

class _CapturedScreenState extends State<CapturedScreen> {
  bool isUploading = false;
  bool finalLoad = false;
  String id = "";
  String token = "";
  bool mystory = true;
  bool stylemates = false;
  Future<void> _cropImage(int index) async {
    // Crop the selected image
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: widget.capturedImages[index].path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
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

    // If the user successfully cropped the image, update the list
    if (croppedFile != null) {
      setState(() {
        widget.capturedImages[index] = File(croppedFile.path);
      });
    }
  }

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    debugPrint(preferences.getString("fcm_token"));
    debugPrint("user id is----->>>${preferences.getString("id")}");
  }

  Future<void> uploadAllImages(BuildContext context, List<File> capturedImages) async {
    setState(() {
      isUploading = true;
    });

    String url = '$serverUrl/fileUploader/';
    List<Future<void>> uploadFutures = [];

    try {
      for (var imageFile in capturedImages) {
        uploadFutures.add(uploadImage(imageFile, url));
      }

      // Wait for all uploads to finish
      await Future.wait(uploadFutures);

      setState(() {
        isUploading = false;
      });

      Navigator.pop(context); // Close the screen only after all uploads are done
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      debugPrint("Error uploading images: ${e.toString()}");
    }
  }

  Future<void> uploadImage(File imageFile, String url) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      });

      // Add the image file as multipart
      var mimeType = lookupMimeType(imageFile.path); // Get mime type of the file
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
        var decodedData = json.decode(responseData.body);
        print("Uploaded Image Successfully: ${decodedData['document']}");

        // Post story or stylemates
        if (mystory == true) {
          postStory(decodedData["document"]);
        } else if (stylemates == true) {
          postStoryForStyleMates(decodedData["document"]);
        }
      } else {
        debugPrint("Failed to upload image. Status code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error uploading image: ${e.toString()}");
    }
  }
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
          // Fluttertoast.showToast(
          //     msg: "Story uploaded", backgroundColor: primary);
          // Navigator.pop(context);
          // Navigator.pop(context);
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
          // Fluttertoast.showToast(
          //     msg: "Story uploaded for stylemates", backgroundColor: primary);
          // Navigator.pop(context);
          // Navigator.pop(context);
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
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
            onTap: (){
              Navigator.of(context).pop();
            },
            child: Icon(Icons.close)),
        centerTitle: true,
        title: Text('Captured Images',style: TextStyle(
            fontSize: 16,
            fontFamily: Poppins
        ),),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Row(
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
                    child: Text("Your Story",style: TextStyle(fontFamily: Poppins),),
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
                    child: Text("Stylemates",style: TextStyle(fontFamily: Poppins),),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.6
              ),
              itemCount: widget.capturedImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: (){
                    _cropImage(index);
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(
                                widget.capturedImages[index]
                            )
                          )
                        ),
                      ),
                      Positioned(
                        top: 5, // Adjust the distance from the top
                        right: 10, // Adjust the distance from the left
                        child: GestureDetector(
                          onTap:(){
                            setState(() {
                              widget.capturedImages.removeAt(index);
                            });
                          },
                          child: Chip(
                            label: Icon(Icons.close,color: Colors.red,size: 20,),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              finalLoad == true ? SpinKitCircle(color: primary,) : Expanded(
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      finalLoad = true;
                    });
                    await uploadAllImages(context, widget.capturedImages);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: primary,
                        borderRadius: BorderRadius.all(Radius.circular(6))
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text("Upload Story",style: TextStyle(
                              fontSize: 16,
                              fontFamily: Poppins,
                              color: ascent
                          ),),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
