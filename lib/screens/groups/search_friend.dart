import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/screens/groups/add_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;

import '../../../animations/bottom_animation.dart';
import '../../../models/groupChatModel.dart';
import '../../../utils/constants.dart';

class SearchFriend extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  const SearchFriend({Key? key, required this.myIndex, required this.navigateTo}) : super(key: key);

  @override
  State<SearchFriend> createState() => _SearchFriendState();
}

class _SearchFriendState extends State<SearchFriend> {
  String search = "";
  String id = "";
  String token = "";
  bool loading = false;
  List<GroupChatModel> friends = [];
  List<GroupChatModel> filteredItems = [];
  List<Map<String,dynamic>> members = [];
  List<String> users = [];

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
      }).then((value){
        setState(() {
          loading = false;
        });
      });
    }catch(e){
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
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
    return WillPopScope(
      onWillPop: (){
        widget.navigateTo(widget.myIndex);
        return Future.value(false);
      },
      child: Scaffold(
        // appBar:  AppBar(
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
        //             ])
        //     ),),
        //   title: const Text("Select Friends",style: TextStyle(fontFamily: Poppins),),
        // ),
        body: friends.isEmpty?const Center(child: Text("No Friends",style: TextStyle(fontFamily: Poppins),),):
        Column(
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
            loading == true ? SpinKitCircle(color: primary,size: 50,) :(friends.isEmpty ? const Center(
                child: Text("No People.",style: TextStyle(fontFamily: Poppins),)) : Expanded(
              child: ListView.builder(
                  itemCount: friends.length,
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
                                    imageUrl: friends[index].pic,
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
                              const SizedBox(width: 10,),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(friends[index].name ?? "",style: TextStyle(color: primary,fontSize: 20,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(friends[index].username,style: const TextStyle(fontFamily: Poppins),),
                                    ],
                                  )
                                ],
                              ),
                              const Expanded(child: SizedBox(width: 20,)),
                              friends[index].flag == true ?GestureDetector(
                                  onTap: (){
                                    if(friends[index].flag == true){
                                      final int foundIndex = members.indexWhere((book) => book["email"] == friends[index].email);
                                      final int foundIndex1 = users.indexWhere((book) => book == friends[index].email);
                                      // Display result
                                      if (foundIndex != -1 && foundIndex1 != -1) {
                                        setState(() {
                                          members.removeAt(foundIndex);
                                          users.removeAt(foundIndex1);
                                          friends[index].flag = false;
                                        });
                                        print('Index: $foundIndex');
                                      }
                                    }
                                  },
                                  child: Icon(Icons.remove,color: primary,)) : GestureDetector(onTap: (){
                                if(friends[index].flag == false){
                                  setState(() {
                                    members.add({
                                      "id": friends[index].id,
                                      "name": friends[index].name,
                                      "pic": friends[index].pic,
                                      "email": friends[index].email,
                                      "username": friends[index].username,
                                      "token": friends[index].fcmToken,
                                    });
                                    users.add(friends[index].email);
                                    friends[index].flag = true;
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
                                    height:30,
                                    width: 30,
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
                                    height:30,
                                    width: 30,
                                    child: SpinKitCircle(color: primary,size: 20,)),
                                errorWidget: (context, url, error) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    height:30,
                                    width: 30,
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
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AddGroup(
                    members: members,
                    users: users
                  )));
                },
                child: Container(
                  child: Icon(Icons.arrow_circle_right,color: primary,size: 50,),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
