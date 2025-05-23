import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/helpers/database_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;

import '../../../animations/bottom_animation.dart';
import '../../../models/groupChatModel.dart';
import '../../../utils/constants.dart';

class AddNewMember extends StatefulWidget {
  final String groupID;
  final List<dynamic> previousGroup;
  const AddNewMember({Key? key, required this.groupID, required this.previousGroup}) : super(key: key);

  @override
  State<AddNewMember> createState() => _AddNewMemberState();
}

class _AddNewMemberState extends State<AddNewMember> {
  String search = "";
  String id = "";
  String token = "";
  bool loading = false;
  List<GroupChatModel> friends = [];
  List<GroupChatModel> filteredItems = [];
  List<Map<String,dynamic>> members = [];
  List<String> users = [];
  List<GroupChatModel> matchList = [];
  bool startAdd = false;

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(token);
    getMyFriends();
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  getMyFriends(){
    setState(() {
      loading = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/follow_get_friends/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        print("Friends ${jsonDecode(value.body)}");
        jsonDecode(value.body).forEach((data){
          if(data["id"].toString() != id.toString()){
            setState(() {
              friends.add(GroupChatModel(
                  data["id"].toString(),
                  data["name"],
                  data["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                  data["email"],
                  data["username"],
                  data["fcmToken"] ?? "",
                  false
              ));
            });
          }
        });
        matchListData();
      });
    }catch(e){
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }

  matchListData(){
    matchList = friends.where((e)=> widget.previousGroup.where((ee) => e.email == ee['email']).toList().isEmpty).toList();
    setState(() {
      loading = false;
    });
  }

  SearchUser(String query) {
    setState(
          () {
        search = query;
        filteredItems = friends
            .where(
              (item) => item.username.toLowerCase().contains(
            query.toLowerCase(),
          ),
        ).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
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
                  ])
          ),),
        title: const Text("Select People",style: TextStyle(fontFamily: Poppins),),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10,),
          // WidgetAnimator(
          //   Container(
          //     alignment: Alignment.bottomCenter,
          //     width: MediaQuery
          //         .of(context)
          //         .size
          //         .width,
          //     child: Card(
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.all(Radius.circular(40)),
          //       ),
          //       child: Container(
          //         padding: EdgeInsets.symmetric(horizontal: 24, vertical: 1),
          //         decoration: BoxDecoration(
          //           borderRadius: BorderRadius.all(Radius.circular(40)),
          //           gradient: LinearGradient(
          //               begin: Alignment.bottomLeft,
          //               end: Alignment.bottomRight,
          //               colors: <Color>[primary, primary]),
          //         ),
          //         child: Row(
          //           children: [
          //             SizedBox(width: 16,),
          //             // Expanded(
          //             //     child: TextField(
          //             //       onChanged: (value){
          //             //         SearchUser(value);
          //             //       },
          //             //       style: TextStyle(color: ascent,fontFamily: Poppins),
          //             //       cursorColor: ascent,
          //             //       //style: simpleTextStyle(),
          //             //       decoration: InputDecoration(
          //             //           fillColor: ascent,
          //             //           hintText: "Search People ...",
          //             //           hintStyle: TextStyle(
          //             //             color: ascent,
          //             //             fontFamily: Poppins,
          //             //             fontSize: 16,
          //             //           ),
          //             //           border: InputBorder.none
          //             //       ),
          //             //     )),
          //             SizedBox(width: 16,),
          //             GestureDetector(
          //               onTap: () {
          //                 FocusScope.of(context).unfocus();
          //               },
          //               child: Container(
          //                   height: 40,
          //                   width: 40,
          //                   decoration: BoxDecoration(
          //                       gradient: LinearGradient(
          //                           colors: [
          //                             ascent,
          //                             ascent
          //                           ],
          //                           begin: FractionalOffset.topLeft,
          //                           end: FractionalOffset.bottomRight
          //                       ),
          //                       borderRadius: BorderRadius.circular(40)
          //                   ),
          //                   padding: EdgeInsets.all(10),
          //                   child: Icon(Icons.search,color: primary,)
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          const SizedBox(height: 10,),
          loading == true ? SpinKitCircle(color: primary,size: 50,) :(matchList.isEmpty ? const Expanded(child: Center(child: Text("No People",style: TextStyle(fontFamily: Poppins),))) : Expanded(
            child: ListView.builder(
                itemCount: matchList.length,
                itemBuilder: (context,index) => WidgetAnimator(
                    GestureDetector(
                      onTap: (){
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            const SizedBox(width: 20,),
                            Container(
                              height:50,
                              width: 50,
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: const BorderRadius.all(Radius.circular(120))
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(120)),
                                child: CachedNetworkImage(
                                  imageUrl: matchList[index].pic,
                                  imageBuilder: (context, imageProvider) => Container(
                                    height:50,
                                    width: 50,
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
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(matchList[index].name ?? "",style: TextStyle(color: primary,fontSize: 20,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(matchList[index].username,style: const TextStyle(fontFamily: Poppins),),
                                  ],
                                )
                              ],
                            ),
                            const Expanded(child: SizedBox(width: 20,)),
                            matchList[index].flag == true ?GestureDetector(
                                onTap: (){
                                  if(matchList[index].flag == true){
                                    final int foundIndex = members.indexWhere((book) => book["email"] == matchList[index].email);
                                    final int foundIndex1 = users.indexWhere((book) => book == matchList[index].email);
                                    // Display result
                                    if (foundIndex != -1 && foundIndex1 != -1) {
                                      setState(() {
                                        members.removeAt(foundIndex);
                                        users.removeAt(foundIndex1);
                                        matchList[index].flag = false;
                                      });
                                      print('Index: $foundIndex');
                                    }
                                  }
                                },
                                child: Icon(Icons.remove,color: primary,)) : GestureDetector(onTap: (){
                              if(matchList[index].flag == false){
                                setState(() {
                                  members.add({
                                    "id": matchList[index].id,
                                    "name": matchList[index].name,
                                    "pic": matchList[index].pic,
                                    "email": matchList[index].email,
                                    "username": matchList[index].username,
                                    "token": matchList[index].fcmToken,
                                  });
                                  users.add(matchList[index].email);
                                  matchList[index].flag = true;
                                });
                              }
                            }, child: Icon(Icons.add,color: primary,)),
                            const SizedBox(width: 20,),
                          ],
                        ),
                      ),
                    )
                )
            ),))
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Row(
          children: [
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: members.length,
                itemBuilder: (context,index) => Container(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: members[index]["pic"],
                            imageBuilder: (context, imageProvider) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height:50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(120)),
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            placeholder: (context, url) => SizedBox(
                                height:40,
                                width: 40,
                                child: SpinKitCircle(color: primary,size: 20,)),
                            errorWidget: (context, url, error) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height:50,
                                width: 50,
                                decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(120)),
                                    image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: NetworkImage("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w")
                                    )
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(members[index]["name"],style: const TextStyle(fontSize: 12),)
                    ],
                  ),
                ),
              ),
            ),
            members.isEmpty ? const SizedBox() : GestureDetector(
              onTap: () {
                setState(() {
                  startAdd = true;
                });
                print(widget.groupID);
                DatabaseMethods().addGroupMember(widget.groupID, members, users).then((value){
                  print(value);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                });
              },
              child: Container(
                child: startAdd == true ? const SpinKitCircle(color: ascent,): Icon(Icons.arrow_circle_right,color: primary,size: 50,),
              ),
            )
          ],
        ),
      ),
    );
  }
}
