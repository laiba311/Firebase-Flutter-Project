import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalfashiontimefrontend/screens/groups/add_new_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../helpers/multipart_request.dart';
import '../../../utils/constants.dart';
import  'package:http/http.dart'as https;
class GroupDetails extends StatefulWidget {
  final String chatRoomId;
  final String name;
  final String pic;
  final String memberCount;
  final List<dynamic> members;

  const GroupDetails({Key? key, required this.chatRoomId, required this.name, required this.pic, required this.memberCount, required this.members}) : super(key: key);

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}
TextEditingController groupName=TextEditingController();
File _image = File("");
ImagePicker picker = ImagePicker();
String imageLink='';
class _GroupDetailsState extends State<GroupDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        centerTitle: true,
        title: const Text("Group Info",style: TextStyle(fontFamily: Poppins),),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: "ABC",
                child: GestureDetector(
                  onTap: () {
                    uploadImage();
                  },
                  child:
                  imageLink!=""?
                  CircleAvatar(
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
                          imageUrl:
                          widget.pic,

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
                  ),
                  // child: Container(
                  //   decoration: const BoxDecoration(
                  //       color: Colors.black54,
                  //       borderRadius: BorderRadius.all(Radius.circular(120))
                  //   ),
                  //   child: ClipRRect(
                  //     borderRadius: const BorderRadius.all(Radius.circular(120)),
                  //     child: CachedNetworkImage(
                  //       imageUrl: widget.pic,
                  //       imageBuilder: (context, imageProvider) => Container(
                  //         height:150,
                  //         width: 150,
                  //         decoration: BoxDecoration(
                  //           borderRadius: const BorderRadius.all(Radius.circular(120)),
                  //           image: DecorationImage(
                  //             image: imageProvider,
                  //             fit: BoxFit.cover,
                  //           ),
                  //         ),
                  //       ),
                  //       placeholder: (context, url) => SpinKitCircle(color: primary,size: 20,),
                  //       errorWidget: (context, url, error) => ClipRRect(
                  //           borderRadius: const BorderRadius.all(Radius.circular(50)),
                  //           child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,)
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ),
              ),

            ],
          ),
          const SizedBox(height: 10,width: 2,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(widget.name,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold
                      ),),
                  ),
                ),
              ),
              IconButton(onPressed: (){
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: primary,
                      title: const Text('Edit group name',style: TextStyle(fontFamily: Poppins),),
                      content: TextField(
                        controller: groupName,
                        style: const TextStyle(fontFamily: Poppins),
                      ),
                      actions: <Widget>[
                        TextButton(child: const Text("Ok",style: TextStyle(fontFamily: Poppins),), onPressed: () {
                          updateGroup(roomID: widget.chatRoomId,groupName: groupName.text);
                          Navigator.of(context).pop();
                          groupName.text='';

                        },),
                      ],
                    );
                  },
                );
              }, icon:const Icon(Icons.edit) )
            ],
          ),
          const SizedBox(height: 5,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Group • ${widget.memberCount} participants")
            ],
          ),
          const SizedBox(height: 20,),
          GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddNewMember(
                groupID: widget.chatRoomId,
                previousGroup: widget.members,
              )));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.add),
                Text(" Add New"),
                SizedBox(width: 30,)
              ],
            ),
          ),
          const SizedBox(height: 10,),
          widget.members.isEmpty ? const Expanded(child: Center(child: Text("No Members",style: TextStyle(fontFamily: Poppins),),)) : Expanded(
            child: ListView.builder(
                itemCount: widget.members.length,
                itemBuilder: (context,index){
                  return Padding(
                    padding: const EdgeInsets.only(left:20.0,right: 20.0,bottom: 15),
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.all(Radius.circular(120))
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(120)),
                            child: CachedNetworkImage(
                              imageUrl: widget.members[index]["pic"],
                              imageBuilder: (context, imageProvider) => Container(
                                height:40,
                                width: 40,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) => SpinKitCircle(color: primary,size: 20,),
                              errorWidget: (context, url, error) => ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                                  child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,)
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20,),
                        Expanded(
                          child: Column(
                            mainAxisAlignment:MainAxisAlignment.start,
                            crossAxisAlignment:CrossAxisAlignment.start,
                            children: [
                              Text(widget.members[index]["name"],style: const TextStyle(fontWeight:FontWeight.bold,fontSize: 18),),
                              const SizedBox(height: 5,),
                              Text("@${widget.members[index]["username"]}",style: const TextStyle(fontSize: 16),),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: (){
                            showModalBottomSheet(
                                context: context,
                                builder: (builder){
                                  return SizedBox(
                                    height: 120.0,
                                    child: Container(
                                        decoration: const BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10.0),
                                                topRight: Radius.circular(10.0))),
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(left:8.0),
                                              child: ListTile(
                                                leading: Icon(Icons.person_remove),
                                                title: Text("Remove"),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: (){
                                                Navigator.pop(context);
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.only(left:8.0),
                                                child: ListTile(
                                                  leading: Icon(Icons.close),
                                                  title: Text("Close"),
                                                ),
                                              ),
                                            )
                                          ],
                                        )
                                    ),
                                  );
                                }
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_ios),
                        ),
                      ],
                    ),
                  );
                }
            ),
          )
        ],
      ),
    );
  }
  void updateGroup(
      {
        required String roomID,
        String? pic, // Group picture URL
        String? groupName, // Group name
        String? description,
      }
      ) {
    setState(() {
    });
    Map<String, dynamic> dataToUpdate = {};
    if (pic != null) dataToUpdate["pic"] = pic;
    if (groupName != null) dataToUpdate["group_name"] = groupName;
    if (description != null) dataToUpdate["description"] = description;

    FirebaseFirestore.instance.collection("groupChat")
        .doc(roomID)
        .update(dataToUpdate)
        .then((value) {
      print("Group updated");
      setState(() {
        //Navigator.pop(context);
        Fluttertoast.showToast(msg: "Updated successfully!",backgroundColor: primary);
        Navigator.pop(context);
        Navigator.pop(context);

      });
    })
        .catchError((e) {
      setState(() {

      });
      print(e.toString());
    });
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
          updateGroup(roomID: widget.chatRoomId,pic: imageLink);
        });
      });
    });
  }
}