import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalfashiontimefrontend/screens/groups/group_details.dart';
import 'package:finalfashiontimefrontend/screens/groups/group_message_screen.dart';
import 'package:finalfashiontimefrontend/screens/groups/search_friend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../animations/bottom_animation.dart';
import '../../../utils/constants.dart';

class AllGroups extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  const AllGroups({Key? key, required this.myIndex, required this.navigateTo}) : super(key: key);

  @override
  State<AllGroups> createState() => _AllGroupsState();
}

class _AllGroupsState extends State<AllGroups> {
  bool progress1 = false;
  String ownerName = "";
  String ownerId = "";
  String ownerToken = "";
  String ownerEmail = "";
  String ownerPic = "";
  List<Map<String,dynamic>> members = [];
  bool loading = false;

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    ownerId = preferences.getString("id")!;
    ownerToken = preferences.getString("fcm_token")!;
    ownerName = preferences.getString("name")!;
    ownerEmail = preferences.getString("email")!;
    ownerPic = preferences.getString("pic")!;
    print(ownerToken);
    getGroups();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  getGroups(){
    setState(() {
      loading = true;
    });
    FirebaseFirestore.instance.collection("groupChat").where('users', arrayContains: ownerEmail).get().then((value){
      for (var element in value.docs) {
        setState(() {
          members.add(element.data());
        });
        print("Members ==> ${members.length}");
      }
    }).then((value1){
      FirebaseFirestore.instance.collection("groupChat").get().then((value2){
        for (var element1 in value2.docs) {
          if(element1.data()["owner"]["ownerEmail"] == ownerEmail){
            setState(() {
              members.add(element1.data());
            });
          }
        }
      }).catchError((e){
        setState(() {
          loading = false;
        });
        print(e.toString());
      });
      setState(() {
        loading = false;
      });
    }).catchError((e){
      setState(() {
        loading = false;
      });
      print(e.toString());
    });
    print(members.length);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
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
        //             ])
        //     ),),
        //   backgroundColor: primary,
        //   title: const Text("Groups",style: TextStyle(fontFamily: Poppins),),
        //   actions: [
        //     IconButton(icon: const Icon(Icons.add),onPressed: (){
        //       Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchFriend()));
        //     },)
        //   ],
        // ),
        body: loading == true ? SpinKitCircle(size: 50,color: primary,) : (members.isEmpty ? const Center(child: Text("No Groups",style: TextStyle(fontFamily: Poppins),)) :ListView.builder(
            itemCount: members.length,
            itemBuilder: (context,index) => WidgetAnimator(
                GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => GroupMessageScreen(
                        name: members[index]["group_name"] ?? "",
                        pic: "https://cdn.raceroster.com/assets/images/team-placeholder.png",
                        memberCount: members[index]["members"].length.toString(),
                        chatRoomId: members[index]["roomID"],
                        members: members[index]["members"])));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 20,),
                        GestureDetector(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => GroupDetails(
                                name: members[index]["group_name"] ?? "",
                                pic: members[index]['pic']!=""? members[index]['pic']:"https://cdn.raceroster.com/assets/images/team-placeholder.png",
                                memberCount: members[index]["members"].length.toString(),
                                chatRoomId: members[index]["roomID"],
                                members: members[index]["members"],
                            )));
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(120))
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(120)),
                              child: CachedNetworkImage(
                                imageUrl:members[index]['pic']!=""? members[index]['pic']:"https://cdn.raceroster.com/assets/images/team-placeholder.png",
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
                        ),
                        const SizedBox(width: 20,),
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(members[index]["group_name"] ?? "No Name",style: TextStyle(color: primary,fontSize: 20,fontWeight: FontWeight.bold,fontFamily: Poppins),textAlign: TextAlign.start),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text("${members[index]["members"].length} members",style: const TextStyle(fontFamily: Poppins),),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )
            )
        )),
      ),
    );
  }
}
