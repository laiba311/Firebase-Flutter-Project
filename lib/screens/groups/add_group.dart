import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalfashiontimefrontend/screens/groups/all_groups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart'as https;
import '../../../animations/bottom_animation.dart';
import '../../../helpers/multipart_request.dart';
import '../../../utils/constants.dart';

class AddGroup extends StatefulWidget {
  final List<Map<String,dynamic>> members;
  final List<String> users;
  const AddGroup({Key? key, required this.members, required this.users}) : super(key: key);

  @override
  State<AddGroup> createState() => _AddGroupState();
}

class _AddGroupState extends State<AddGroup> {
  TextEditingController name = TextEditingController();
  TextEditingController description = TextEditingController();
  bool progress1 = false;
  String ownerName = "";
  String ownerId = "";
  String ownerToken = "";
  String ownerEmail = "";
  String ownerPic = "";
  File _image = File("");
  ImagePicker picker = ImagePicker();
  String imageLink='';

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    ownerId = preferences.getString("id")!;
    ownerToken = preferences.getString("fcm_token")!;
    ownerName = preferences.getString("name")!;
    ownerEmail = preferences.getString("email")!;
    ownerPic = preferences.getString("pic")!;
    print(ownerToken);
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
        centerTitle: true,
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
                  ])
          ),),
        backgroundColor: primary,
        title: const Text("Add Group",style: TextStyle(fontFamily: Poppins),),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10,),
          _image.path != ""
              ? CircleAvatar(
            radius: 50,
            child: ClipRRect(
                borderRadius: const BorderRadius.all(
                    Radius.circular(100)),
                child: Container(
                  height:
                  100,
                  width: 100,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          fit: BoxFit.cover,
                          image: FileImage(_image))),
                )),
          )
              : CircleAvatar(
            radius: 50,
            child: Container(
              decoration: const BoxDecoration(
                  borderRadius:
                  BorderRadius.all(Radius.circular(120))),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                    Radius.circular(120)),
                child: CachedNetworkImage(
                  imageUrl:
                       "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",

                  imageBuilder: (context, imageProvider) =>
                      Container(
                        height:
                       100,
                        width: 100,
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
          ),
          const SizedBox(height: 10,),
          GestureDetector(
            onTap: () {
              uploadImage();
            },
            child: Center(
              child: Text(
                "Select your group image",
                style:
                TextStyle(color: primary, fontFamily: Poppins),
              ),
            ),
          ),
          WidgetAnimator(
            Padding(
              padding: const EdgeInsets.only(left:30.0,right: 30.0,top: 8.0,bottom: 8.0),
              child: Container(
                child: TextField(
                  controller: name,
                  style: TextStyle(
                      color: primary,
                      fontFamily: Poppins
                  ),
                  decoration: InputDecoration(
                      hintStyle: const TextStyle(
                        //color: Colors.black54,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          fontFamily: Poppins
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 1, color: primary),
                      ),
                      focusColor: primary,
                      alignLabelWithHint: true,
                      hintText: "Enter group name"
                  ),
                  cursorColor: primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10,),
          WidgetAnimator(
            Padding(
              padding: const EdgeInsets.only(left:30.0,right: 30.0,top: 8.0,bottom: 8.0),
              child: Container(
                child: TextField(
                  controller: description,
                  maxLines: 5,
                  style: TextStyle(
                      color: primary,
                      fontFamily: Poppins
                  ),
                  decoration: InputDecoration(
                      hintStyle: const TextStyle(
                        //color: Colors.black54,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          fontFamily: Poppins
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(width: 1, color: primary),
                      ),
                      focusColor: primary,
                      alignLabelWithHint: true,
                      hintText: "Enter group description"
                  ),
                  cursorColor: primary,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:SizedBox(
        height: 85,
        child: Column(
          children: [
            WidgetAnimator(
                Padding(
                  padding: const EdgeInsets.only(left: 20,right: 20),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.0),
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.topRight,
                            stops: const [0.0, 0.99],
                            tileMode: TileMode.clamp,
                            colors:
                                 <Color>[
                              secondary,
                              primary,
                            ])),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        progress1 == true ? SpinKitCircle(color: primary,size: 50,) : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                              style: ButtonStyle(
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12.0),
                                      )),
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                  shadowColor: MaterialStateProperty.all(
                                      Colors.transparent),
                                  // padding: MaterialStateProperty.all(EdgeInsets.only(
                                  //
                                  //
                                  //     left: MediaQuery.of(context).size.width *
                                  //         0.26,
                                  //     right:
                                  //     MediaQuery.of(context).size.width *
                                  //         0.26)),
                                  textStyle: MaterialStateProperty.all(
                                      const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontFamily: Poppins))),
                              onPressed: () {
                                if(name.text.isNotEmpty){
                                  String uuid = const Uuid().v4();
                                  print("uuid $uuid");
                                  createGroup(
                                      {
                                        "roomID":uuid,
                                        "pic":imageLink,
                                        "group_name": name.text,
                                        "description": description.text,
                                        "members": widget.members,
                                        "users": widget.users,
                                        "owner": {
                                          "ownerId": ownerId,
                                          "ownerToken": ownerToken,
                                          "ownerName": ownerName,
                                          "ownerEmail": ownerEmail,
                                          "ownerPic": ownerPic
                                        }
                                      },
                                      uuid
                                  );
                                }
                                else{
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: primary,
                                      title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                      content: const Text("Group name can not be empty",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                      actions: [
                                        TextButton(
                                          child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                          onPressed:  () {
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
                              child: const Text('Create Group',style: TextStyle(
                                  fontSize: 12,
                                  color: ascent,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: Poppins
                              ),)),
                        ),
                      ],
                    ),
                  ),
                )
            ),
          ],
        ),
      ),
    );
  }
  uploadImage() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text(
                      'Image from Gallery',
                      style: TextStyle(fontFamily: Poppins),
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
            ),
          );
        });
  }
  _pickImageFromGallery() async {
    Navigator.pop(context);
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    File image = File(pickedFile!.path);
    uploadMedia(File(pickedFile.path).path);
    setState(() {
      _image = image;
    });
  }
  _pickImageFromCamera() async {
    Navigator.pop(context);
    XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

    File image = File(pickedFile!.path);
    uploadMedia(File(pickedFile.path).path);
    setState(() {
      _image = image;
    });
  }
  createGroup(chatMessageData,docID){
    setState(() {
      progress1 = true;
    });
    FirebaseFirestore.instance.collection("groupChat")
        .doc(docID)
        .set(chatMessageData)
        .then((value){
          print("Created");
        setState(() {
          progress1 = false;
        });
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pop(context);
        // Navigator.push(context,MaterialPageRoute(builder: (context) => const AllGroups()));
    })
        .catchError((e){
      setState(() {
        progress1 = false;
      });
         print(e.toString());
    });
  }
  uploadMedia(imagePath) async {
   // Navigator.pop(context);
    String decoded;
    final request = MultipartRequest(
      'POST',
      Uri.parse("$serverUrl/fileUploader/"),
      onProgress: (int bytes, int total) {
        setState(() {
          // progress = bytes / total;
          // result = 'progress: $progress ($bytes/$total)';
        });
       // print('progress: $progress ($bytes/$total)');
      },
    );

    request.files.add(await https.MultipartFile.fromPath(
      'document',
      imagePath,
      contentType: MediaType('image', 'jpeg'),
    ));

    request.send().then((value) {
      setState(() {
        //result = "";
      });
      print(value.stream.toString());
      value.stream.forEach((element) {
        decoded = utf8.decode(element);
        print(jsonDecode(decoded)["document"]);
        imageLink=jsonDecode(decoded)["document"];
        setState(() {
          // media
          //     .add({"image": jsonDecode(decoded)["document"], "type": "image"});
          // media1.add({"image": imagePath, "type": "image"});
          // showDialog(
          //   context: context,
          //   builder: (BuildContext context) {
          //     return AlertDialog(
          //       backgroundColor: primary,
          //       title: const Text('Image Selected'),
          //       content:Image(image: NetworkImage("${jsonDecode(decoded)["document"]}"),),
          //       actions: <Widget>[
          //         IconButton(icon: const Icon(Icons.send), onPressed: () { addMessage();
          //         Navigator.of(context).pop();},),
          //       ],
          //     );
          //   },
          // );
          Fluttertoast.showToast(msg: "Done! Proceed to continue",backgroundColor: primary);
        });
      });
    });
  }
}

