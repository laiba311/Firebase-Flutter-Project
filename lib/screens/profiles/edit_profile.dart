import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../animations/bottom_animation.dart';
import '../../utils/constants.dart';

class EditProfile extends StatefulWidget {
  final Function navigateTo;
  final int myIndex;
  const EditProfile({
    Key? key, required this.navigateTo, required this.myIndex,
  }) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

enum AppState {
  free,
  picked,
  cropped,
}


class _EditProfileState extends State<EditProfile> {
  File _image = File("");
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController username = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController pic = TextEditingController();
  TextEditingController description = TextEditingController();
  ImagePicker picker = ImagePicker();
  bool progress1 = false;
  bool progress2 = false;
  String id = "";
  String token = "";
  Map<String, dynamic> data = {};
  bool progress = false;
  late AppState state;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print("the token of user is=========>$token");
    getProfile();
  }

  String decodeIfNeeded(String text) {
    try {
      // Attempt to decode; if it's not encoded, this should return the same text
      String decodedText = Uri.decodeComponent(text);
      return decodedText;
    } catch (e) {
      // If decoding fails, return the original text
      return text;
    }
  }

  getProfile() {
    setState(() {
      progress = true;
    });
    https.get(Uri.parse("$serverUrl/user/api/profile/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      data = json.decode(value.body);
      String decodedText = Uri.decodeComponent(data["description"] ?? "");
      String decodedText1 = Uri.decodeComponent(data["name"] ?? "");
      setState(() {
        name.text = decodedText1;
        username.text = data["username"];
        email.text = data["email"];
        pic.text = data["pic"] ?? '';
        description.text = decodedText;
        phone.text = data["phone_number"] ?? "";
      });
      setState(() {
        progress = false;
      });
    // }).catchError((e){
    //   setState(() {
    //     progress = false;
    //   });
    //   print(e.toString());
    });
  }

  uploadImage() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text(
                    'Image from Gallery',
                    style: TextStyle(fontFamily: Poppins,),
                  ),
                  onTap: () {
                    _pickImageFromGallery();
                  }),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text(
                  'Capture image',
                  style: TextStyle(fontFamily: Poppins,),
                ),
                onTap: () {
                  _pickImageFromCamera();
                },
              ),
            ],
          );
        });
  }

  _pickImageFromGallery() async {
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    File image = File(pickedFile!.path);

    setState(() {
      _image = image;
    });
    Navigator.pop(context);
    //_cropImage(_image.path);
  }

  _pickImageFromCamera() async {
    XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

    File image = File(pickedFile!.path);

    setState(() {
      _image = image;
    });
    Navigator.pop(context);
    //_cropImage(_image.path);
  }

  _cropImage(imageFile) async {
    ImageCropper().cropImage(
        sourcePath: imageFile,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: false,
              activeControlsWidgetColor: primary
          ),
          IOSUiSettings(
            title: 'Cropper',
          ),
        ],
       ).then((croppedFile){
         try {
           if (croppedFile != null) {
             _image = File(croppedFile.path);
             setState(() {});
           } else {
             print("No image was cropped");
           }
         }catch(e){
           print("Crash Error => ${e.toString()}");
         };
          //Navigator.pop(context);
       }).catchError((e){
      print("Crash Error 1 => ${e.toString()}");
       });
  }


  SaveData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      progress1 = true;
    });

    try {
      final extension = File.fromUri(_image.uri).path.split('.').last; // Get the file extension
      var postUri = Uri.parse("$serverUrl/user/api/profile/");
      var request = https.MultipartRequest("PATCH", postUri); // Use http.MultipartRequest instead of https.MultipartRequest
      request.fields['name'] = Uri.encodeComponent(name.text);
      // request.fields['email'] = email.text;
      // request.fields['username'] = username.text;
      String datades = Uri.encodeComponent(description.text);
      request.fields['description'] = datades;
      // request.fields['phone_number'] = phone.text;

      if (File.fromUri(_image.uri).path.isNotEmpty) {
        request.files.add(await https.MultipartFile.fromPath( // Use http.MultipartFile instead of https.MultipartFile
            'pic', File.fromUri(_image.uri).path, filename: "${DateTime.now().microsecondsSinceEpoch.toString()}.${extension}"));
      }

      Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      request.headers.addAll(headers);

      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();

        // Now decode JSON if expected
        final jsonData = jsonDecode(respStr);
        debugPrint("status ===============>${jsonData["pic"]}");
        setState(() {
          progress1 = false;
        });

        preferences.setString("name", name.text.toString());
        preferences.setString("pic", jsonData["pic"]);
        getProfile(); // Assuming this function updates the UI with the new profile data
      } else {
        setState(() {
          progress1 = false;
        });
        final respStr = await response.stream.bytesToString();
        print("Failed to update profile: ${respStr}");
      }
    } catch (e) {
      setState(() {
        progress1 = false;
      });
      print("Error updating profile: $e");
    }
  }
  DeleteImage() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      progress2 = true;
    });
    var bytes = (await rootBundle.load('assets/profilepic.png')).buffer.asUint8List();
    try {
      var postUri = Uri.parse("$serverUrl/user/api/profile/");
      var request = https.MultipartRequest("PATCH", postUri); // Use http.MultipartRequest instead of https.MultipartRequest
      request.fields['name'] = Uri.encodeComponent(name.text);
      // request.fields['email'] = email.text;
      // request.fields['username'] = username.text;
      request.fields['description'] = Uri.encodeComponent(description.text);
      //if (File.fromUri(_image.uri).path.isNotEmpty) {
        request.files.add(https.MultipartFile.fromBytes( // Use http.MultipartFile instead of https.MultipartFile
            'pic',bytes, filename: "profilepic.png"));
      //}
      // request.fields['phone_number'] = phone.text;
      //request.fields['pic'] =  "";
      // if (File.fromUri(_image.uri).path.isNotEmpty) {
      //   request.files.add(await https.MultipartFile.fromPath( // Use http.MultipartFile instead of https.MultipartFile
      //       'pic', "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w"));
      // }

      Map<String, String> headers = {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

      request.headers.addAll(headers);

      var response = await request.send();

      if (response.statusCode == 200) {
        debugPrint("status ===============>${response.statusCode}");
        setState(() {
          progress2 = false;
        });
        preferences.setString("pic", "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/profilepic.png?alt=media&token=a2830e22-3dec-4901-a2cb-ae5089d6966f");
        getProfile(); // Assuming this function updates the UI with the new profile data
      } else {
        setState(() {
          progress2 = false;
        });
        print("Failed to update profile: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        progress2 = false;
      });
      print("Error updating profile: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.navigateTo(widget.myIndex);
        return Future.value(false);
      },
      child: Scaffold(
        // appBar: AppBar(
        //   centerTitle: true,
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
        //   backgroundColor: ascent,
        //   // actions: [
        //   //   Padding(
        //   //     padding: const EdgeInsets.all(8.0),
        //   //     child: IconButton(
        //   //       icon: const Icon(
        //   //         Icons.person,
        //   //         size: 32,
        //   //       ),
        //   //       onPressed: () {
        //   //         Navigator.push(
        //   //             context,
        //   //             MaterialPageRoute(
        //   //               builder: (context) => const PersonalSettingScreen(),
        //   //             ));
        //   //       },
        //   //     ),
        //   //   )
        //   // ],
        //   title: const Text(
        //     "Edit Profile",
        //     style: TextStyle(fontFamily: Poppins,),
        //   ),
        // ),
        body: progress == true
            ? SpinKitCircle(
                color: primary,
                size: 50,
              )
            : ListView(
                children: [
                  const SizedBox(
                    height: 10,
                  ),

                  WidgetAnimator(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _image.path != ""
                            ? CircleAvatar(
                                radius: 100,
                                child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(100)),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: FileImage(_image))),
                                    )),
                              )
                            : CircleAvatar(
                                radius: 100,
                                child: Container(
                                  decoration: const BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(120))),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(120)),
                                    child: CachedNetworkImage(
                                      imageUrl: pic.text == ""
                                          ? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w"
                                          : pic.text,
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.7,
                                        width: MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      placeholder: (context, url) =>
                                          SpinKitCircle(
                                        color: primary,
                                        size: 60,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  WidgetAnimator(Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          uploadImage();
                        },
                        child: Text(
                          "Change your profile image",
                          style:
                              TextStyle(color: primary, fontFamily: Poppins,),
                        ),
                      )
                    ],
                  )),
                  const SizedBox(
                    height: 20,
                  ),
                  WidgetAnimator(
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 25.0, right: 25.0, top: 8.0, bottom: 8.0),
                      child: Container(
                        child: TextField(
                          // inputFormatters: <TextInputFormatter>[
                          //   FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z.-_]")),
                          // ],
                          controller: name,
                          style:
                              TextStyle(color: primary, fontFamily: Poppins,),
                          decoration: InputDecoration(
                              hintStyle: const TextStyle(
                                  //color: Colors.black54,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                fontFamily: Poppins,),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 1, color: primary),
                              ),
                              focusColor: primary,
                              alignLabelWithHint: true,
                              hintText: "Enter Your name"),
                          cursorColor: primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  // WidgetAnimator(
                  //   Padding(
                  //     padding: const EdgeInsets.only(left:25.0,right: 25.0,top: 8.0,bottom: 8.0),
                  //     child: Container(
                  //       child: TextField(
                  //         inputFormatters: [ FilteringTextInputFormatter.allow(RegExp("[a-z]")), ],
                  //         controller: username,
                  //         style: TextStyle(
                  //             color: primary,
                  //             fontFamily: Poppins
                  //         ),
                  //         decoration: InputDecoration(
                  //             hintStyle: const TextStyle(
                  //                 //color: Colors.black54,
                  //                 fontSize: 17,
                  //                 fontWeight: FontWeight.w400,
                  //                 fontFamily: Poppins
                  //             ),
                  //             focusedBorder: OutlineInputBorder(
                  //               borderSide: BorderSide(width: 1, color: primary),
                  //             ),
                  //             focusColor: primary,
                  //             alignLabelWithHint: true,
                  //             hintText: "Enter Your Username"
                  //         ),
                  //         cursorColor: primary,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: 10,),
                  // WidgetAnimator(
                  //   Padding(
                  //     padding: const EdgeInsets.only(left:25.0,right: 25.0,top: 8.0,bottom: 8.0),
                  //     child: Container(
                  //       child: TextField(
                  //         controller: email,
                  //         style: TextStyle(
                  //             color: primary,
                  //             fontFamily: Poppins
                  //         ),
                  //         decoration: InputDecoration(
                  //             hintStyle: TextStyle(
                  //                 //color: Colors.black54,
                  //                 fontSize: 17,
                  //                 fontWeight: FontWeight.w400,
                  //                 fontFamily: Poppins
                  //             ),
                  //             focusedBorder: OutlineInputBorder(
                  //               borderSide: BorderSide(width: 1, color: primary),
                  //             ),
                  //             focusColor: primary,
                  //             alignLabelWithHint: true,
                  //             hintText: "Enter Your Email"
                  //         ),
                  //         cursorColor: primary,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(
                    height: 10,
                  ),
                  // WidgetAnimator(
                  //   Padding(
                  //     padding: const EdgeInsets.only(left:25.0,right: 25.0,top: 8.0,bottom: 8.0),
                  //     child: Container(
                  //       child: TextField(
                  //         controller: phone,
                  //         keyboardType: TextInputType.phone,
                  //         style: TextStyle(
                  //             color: primary,
                  //             fontFamily: Poppins
                  //         ),
                  //         decoration: InputDecoration(
                  //             hintStyle: TextStyle(
                  //                 //color: Colors.black54,
                  //                 fontSize: 17,
                  //                 fontWeight: FontWeight.w400,
                  //                 fontFamily: Poppins
                  //             ),
                  //             focusedBorder: OutlineInputBorder(
                  //               borderSide: BorderSide(width: 1, color: primary),
                  //             ),
                  //             focusColor: primary,
                  //             alignLabelWithHint: true,
                  //             hintText: "Enter Your Phone"
                  //         ),
                  //         cursorColor: primary,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: 10,),
                  WidgetAnimator(
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 25.0, right: 25.0, top: 8.0, bottom: 8.0),
                      child: Container(
                        child: TextField(
                          controller: description,
                          maxLength: 250,
                          maxLines: 5,
                          style:
                              TextStyle(color: primary, fontFamily: Poppins,),
                          decoration: InputDecoration(
                              hintStyle: const TextStyle(
                                  //color: Colors.black54,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                fontFamily: Poppins,),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(width: 1, color: primary),
                              ),
                              focusColor: primary,
                              alignLabelWithHint: true,
                              hintText: "Enter Description"),
                          cursorColor: primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
        bottomNavigationBar: SizedBox(
          height: 120,
          child: Column(
            children: [
              WidgetAnimator(Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  progress1 == true
                      ? SpinKitCircle(
                          color: primary,
                          size: 50,
                        )
                      : GestureDetector(
                          onTap: () {
                            SaveData();
                            //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                          },
                          child: Card(
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                            child: Container(
                              alignment: Alignment.center,
                              height: 35,
                              width: MediaQuery.of(context).size.width * 0.8,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.topRight,
                                      stops: const [0.0, 0.99],
                                      tileMode: TileMode.clamp,
                                      colors: <Color>[
                                        secondary,
                                        primary,
                                      ]),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(12))),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: ascent,
                                    fontWeight: FontWeight.w700,
                                  fontFamily: Poppins,),
                              ),
                            ),
                          ),
                        ),
                ],
              )),
              const SizedBox(height: 10,),
              WidgetAnimator(Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  progress2 == true
                      ? SpinKitCircle(
                    color: primary,
                    size: 50,
                  )
                      : GestureDetector(
                    onTap: () {
                      DeleteImage();
                      //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                    },
                    child: Card(
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(12))),
                      child: Container(
                        alignment: Alignment.center,
                        height: 35,
                        width: MediaQuery.of(context).size.width * 0.8,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.topRight,
                                stops: const [0.0, 0.99],
                                tileMode: TileMode.clamp,
                                colors: <Color>[
                                  secondary,
                                  primary,
                                ]),
                            borderRadius: const BorderRadius.all(
                                Radius.circular(12))),
                        child: const Text(
                          'Delete Profile Image',
                          style: TextStyle(
                              fontSize: 18,
                              color: ascent,
                              fontWeight: FontWeight.w700,
                            fontFamily: Poppins,),
                        ),
                      ),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 10,),
            ],
          ),
        ),
      ),
    );
  }
}
