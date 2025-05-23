import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/models/post_model.dart';
import 'package:finalfashiontimefrontend/models/showcase_model.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import 'package:showcaseview/showcaseview.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../utils/constants.dart';

class SwappingScreen extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  final Function onNavigateBack;
  const SwappingScreen({super.key, required this.myIndex, required this.navigateTo, required this.onNavigateBack});


  @override
  State<SwappingScreen> createState() => _SwappingScreenState();
}

class _SwappingScreenState extends State<SwappingScreen> {
  int ind = 0;
  final CardSwiperController controller = CardSwiperController();
  String id = "";
  String token = "";
  String appbarText="";
  List<PostModel> posts = [];
  bool loading = false;
  bool loading1 = false;
  bool loading2 = false;
  bool loading3 = false;
  bool loading4 = false;
  final GlobalKey globalKeyOne = GlobalKey();
  final GlobalKey globalKeyTwo =GlobalKey();
  final GlobalKey globalKeyThree = GlobalKey();
  final GlobalKey globalKeyFour = GlobalKey();

  @override
  void initState() {
    // TODO: implement initState
    // WidgetsBinding.instance.addPostFrameCallback((_)=>ShowCaseWidget.of(context).startShowCase([globalKeyOne,globalKeyTwo,globalKeyThree,globalKeyFour]));
    super.initState();
    getCashedData();
  }

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print(token);
    getPosts();
  }

  getPosts(){
    setState(() {
      loading = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/fashionUpload/frend-fashions/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        setState(() {
          loading = false;
          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              loading = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ShowCaseWidget.of(context).startShowCase([
                  globalKeyOne,
                  globalKeyTwo,
                  globalKeyThree,
                  globalKeyFour,
                ]);
              });
            });
          });
        });
        print(jsonDecode(value.body));
        jsonDecode(value.body).forEach((value){
          if(value["upload"]["media"][0]["type"] == "video"){
            VideoThumbnail.thumbnailFile(
              video: value["upload"]["media"][0]["video"],
              imageFormat: ImageFormat.JPEG,
              maxWidth: 128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
              quality: 25,
            ).then((value1){
              setState(() {
                posts.add(PostModel(
                    value["id"].toString(),
                    value["description"],
                    value["upload"]["media"],
                    value["user"]["name"],
                    value["user"]["pic"] != null ? value["user"]["pic"].toString().replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/", "https://") : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                    false,
                    value["likesCount"].toString(),
                    value["disLikesCount"].toString(),
                    value["commentsCount"].toString(),
                    value["created"],value1!,
                    value["user"]["id"].toString(),
                    value["myLike"] == null ? "like" : value["myLike"].toString(),
                    {},
                    {}
                ));
                print("pic => ${value["user"]["pic"]}");
              });
            });
          }
          else{
            setState(() {
              posts.add(PostModel(
                  value["id"].toString(),
                  value["description"],
                  value["upload"]["media"],
                  value["user"]["name"],
                  value["user"]["pic"] != null ? value["user"]["pic"].toString().replaceAll("https://fashion-time-backend-e7faf6462502.herokuapp.com/", "").replaceAll("https%3A/", "https://") : "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                  false,
                  value["likesCount"].toString(),
                  value["disLikesCount"].toString(),
                  value["commentsCount"].toString(),
                  value["created"],"",
                  value["user"]["id"].toString(),
                  value["myLike"] == null ? "like" : value["myLike"].toString(),
                  {},
                  {}
              ));
            });
            print("pic => ${value["user"]["pic"]}");
          }
        });
      });
      // call get event function
      getAppBarText();
    }catch(e){
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  getAppBarText()async{
    try{
      final response=await https.get(Uri.parse("$serverUrl/fashionEvent-week/"));
      if(response.statusCode==200){
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if(responseData.containsKey("current_week_events")&& responseData["current_week_events"].isNotEmpty){
          print("app bar api data ${responseData.toString()}");
          final event =responseData["current_week_events"][0];
          setState(() {
            appbarText=event['title'];
          });
        }

      }
      else{
        print("Error in app bar api:${response.statusCode}");
      }
    }
    catch(e){
      print("api didn't hit $e");
    }
  }

  createLike(fashionId) async {
    setState(() {
      loading1 = true;
    });
    try {
      setState(() {
        loading1 = true;
      });
      Map<String, dynamic> body = {
        "likeEmoji": "1",
        "fashion": fashionId,
        "user": id
      };
      https.post(
          Uri.parse("$serverUrl/fashionLikes/"),
          body: json.encode(body),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value) {
        print("Response ==> ${value.body}");
        setState(() {
          loading1 = false;
        });
        controller.swipe(CardSwiperDirection.right);
      }).catchError((error){
        setState(() {
          loading1 = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text("Fashion Time",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
            content: Text(error.toString(),style: const TextStyle(color: ascent,fontFamily: Poppins,),),
            actions: [
              TextButton(
                child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                onPressed:  () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      });
    } catch(e){
      setState(() {
        loading1 = false;
      });
      print(e);
    }
  }
  createLike1(fashionId) async {
    setState(() {
      loading = true;
    });
    try {
      setState(() {
        loading = true;
      });
      Map<String, dynamic> body = {
        "likeEmoji": "1",
        "fashion": fashionId,
        "user": id
      };
      https.post(
          Uri.parse("$serverUrl/fashionLikes/"),
          body: json.encode(body),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value) {
        print("Response ==> ${value.body}");
        setState(() {
          loading = false;
        });
      }).catchError((error){
        setState(() {
          loading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
            content: Text(error.toString(),style: const TextStyle(color: ascent,fontFamily: Poppins,),),
            actions: [
              TextButton(
                child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                onPressed:  () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      });
    } catch(e){
      setState(() {
        loading = false;
      });
      print(e);
    }
  }
  createDisLike(fashionId) async {
    setState(() {
      loading4 = true;
    });
    try {
      setState(() {
        loading4 = true;
      });
      Map<String, dynamic> body = {
        "fashion": fashionId,
        "user": id
      };
      https.post(
          Uri.parse("$serverUrl/fashionDisLikes/"),
          body: json.encode(body),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value) {
        print("Response ==> ${value.body}");
        setState(() {
          loading4 = false;
        });
        controller.swipe(CardSwiperDirection.left);
      }).catchError((error){
        setState(() {
          loading4 = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
            content: Text(error.toString(),style: const TextStyle(color: ascent,fontFamily: Poppins,),),
            actions: [
              TextButton(
                child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                onPressed:  () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      });
    } catch(e){
      setState(() {
        loading4 = false;
      });
      print(e);
    }
  }
  createDisLike1(fashionId) async {
    setState(() {
      loading = true;
    });
    try {
      setState(() {
        loading = true;
      });
      Map<String, dynamic> body = {
        "fashion": fashionId,
        "user": id
      };
      https.post(
          Uri.parse("$serverUrl/fashionDisLikes/"),
          body: json.encode(body),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value) {
        print("Response ==> ${value.body}");
        setState(() {
          loading = false;
        });
      }).catchError((error){
        setState(() {
          loading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
            content: Text(error.toString(),style: const TextStyle(color: ascent,fontFamily: Poppins,),),
            actions: [
              TextButton(
                child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                onPressed:  () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      });
    } catch(e){
      setState(() {
        loading = false;
      });
      print(e);
    }
  }

  saveStyle(fashionId) async {
    setState(() {
      loading3 = true;
    });
    try {
      setState(() {
        loading3 = true;
      });
      Map<String, dynamic> body = {
        "fashion": fashionId,
        "user": id,
      };
      https.post(
          Uri.parse("$serverUrl/fashionSaved/"),
          body: json.encode(body),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value) {
        print("Response ==> ${value.body}");
        setState(() {
          loading3 = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text(
              "FashionTime",
              style: TextStyle(color: ascent, fontFamily: Poppins, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Style Saved Successfully.",
              style: TextStyle(color: ascent, fontFamily: Poppins,),
            ),
          ),
        );

// Automatically close the dialog after 2 seconds
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
        //controller.swipeTop();
      }).catchError((error){
        setState(() {
          loading3 = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text("FashionTime",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
            content: Text(error.toString(),style: const TextStyle(color: ascent,fontFamily: Poppins,),),
            actions: [
              TextButton(
                child: const Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                onPressed:  () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      });
    } catch(e){
      setState(() {
        loading3 = false;
      });
      print(e);
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        widget.onNavigateBack(0);
        return Future.value(false);
      },
      child: Scaffold(
        // appBar: AppBar(centerTitle: true,
        //   automaticallyImplyLeading: false,
        //   flexibleSpace: Container(
        //     decoration: BoxDecoration(
        //         gradient: LinearGradient(
        //             begin: Alignment.topLeft,
        //             end: Alignment.topRight,
        //             stops: [0.0, 0.99],
        //             tileMode: TileMode.clamp,
        //             colors: <Color>[
        //               secondary,
        //               primary,
        //             ])),
        //   ),
        //   backgroundColor: primary,
        //   title: Text(
        //     "This week's Fashion Event: $appbarText",
        //     style: TextStyle(fontFamily: Poppins),
        //   ),),
        body:
        loading == true ? SpinKitCircle(color: primary,size: 50,) : (posts.isEmpty ? const Center(child: Text("No Eventposts",style: TextStyle(fontFamily: Poppins,),),) :

        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: ShowCaseView(
              title:" ",
              globalKey: globalKeyOne,
              description: "Swipe Right and left to like and dislike style",
              shapeBorder:const Border(),
              child: CardSwiper(
                numberOfCardsDisplayed: 1,
                controller: controller,
                padding: const EdgeInsets.all(0),
                cardsCount: posts.length,
                onSwipe: (int previousIndex, int? currentIndex, CardSwiperDirection direction){
                  print(previousIndex);
                  if(direction.name == "right"){
                    createLike1(posts[previousIndex].id);
                    print(direction.name);
                  }else if (direction.name == "left"){
                    createDisLike1(posts[previousIndex].id);
                    print(direction.name);
                  }
                  setState(() {
                    posts.removeAt(previousIndex);
                  });
                  print("Entered");
                  return true;
                },
                cardBuilder: (context, index, percentThresholdX, percentThresholdY){
                  return GestureDetector(
                    onTap: (){
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => SwapDetail(
                      //   userid:posts[index].userid,
                      //   image: posts[index].images,
                      //   description:  posts[index].description,
                      //   style: "Fashion Style 2",
                      //   createdBy: posts[index].userName,
                      //   profile: posts[index].userPic,
                      //   likes: posts[index].likeCount,
                      //   dislikes: posts[index].dislikeCount,
                      //   mylike: posts[index].mylike,
                      // )));
                      // setState(() {
                      //   posts.removeAt(index);
                      // });
                    },
                    child: CachedNetworkImage(
                      imageUrl: posts[index].images[0]["type"] == "video" ? posts[index].thumbnail : posts[index].images[0]["image"],
                      imageBuilder: (context, imageProvider) => ListView(
                        children: [
                          Container(
                            height:MediaQuery.of(context).size.height * 0.6,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.fill
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left:25.0,right:25,top: 20,bottom: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap:(){
                                          Navigator.push(context,MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                            id: posts[index].userid,
                                            username: posts[index].userName,
                                          )));
                                        },
                                        child: Card(
                                          elevation: 20,
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(30))
                                          ),
                                          color: Colors.black.withOpacity(0.6),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: SizedBox(
                                              width: 200,
                                              child: Row(
                                                children: [
                                                  const SizedBox(width: 10,),
                                                  CircleAvatar(
                                                      child: ClipRRect(
                                                        borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                        child: posts[index].userPic == null ?Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,):CachedNetworkImage(
                                                          imageUrl: posts[index].userPic,
                                                          imageBuilder: (context, imageProvider) => Container(
                                                            height:MediaQuery.of(context).size.height * 0.7,
                                                            width: MediaQuery.of(context).size.width,
                                                            decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                image: imageProvider,
                                                                fit: BoxFit.cover,
                                                              ),
                                                            ),
                                                          ),
                                                          placeholder: (context, url) => Center(child: SpinKitCircle(color: primary,size: 10,)),
                                                          errorWidget: (context, url, error) => const Icon(Icons.error),
                                                        ),
                                                      )),
                                                  const SizedBox(width: 10,),
                                                  Flexible(child: Text(Uri.decodeComponent(posts[index].userName),style: const TextStyle(fontFamily: Poppins,color: ascent,fontWeight: FontWeight.bold),))
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      ShowCaseView(
                                        title: "View/Report",
                                        description: "View and Report user here.",
                                        shapeBorder: const CircleBorder(),
                                        globalKey: globalKeyTwo,
                                        child: Card(
                                          elevation: 20,
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(30))
                                          ),
                                          //  color: Colors.black.withOpacity(0.6),
                                          color: Colors.black38,
                                          child: PopupMenuButton(
                                              icon:const Icon(Icons.more_horiz,color: ascent,),
                                              onSelected: (value) {
                                                if (value == 0) {
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                    id: posts[index].userid,
                                                    username: posts[index].userName,
                                                  )));
                                                }
                                                print(value);
                                                //Navigator.pushNamed(context, value.toString());
                                              }, itemBuilder: (BuildContext bc) {
                                            return [
                                              PopupMenuItem(
                                                value: 0,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                        Icons.person
                                                    ),
                                                    SizedBox(width: 10,),
                                                    Text("View Profile",style: TextStyle(fontFamily: Poppins,),),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 1,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                        Icons.report
                                                    ),
                                                    SizedBox(width: 10,),
                                                    Text("Report",style: TextStyle(fontFamily: Poppins,),),
                                                  ],
                                                ),
                                              ),
                                            ];
                                          }),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //   children: [
                                //     Padding(
                                //       padding: const EdgeInsets.only(left:28.0),
                                //       child: Card(
                                //         elevation:20,
                                //         color: Colors.black.withOpacity(0.4),
                                //         shape: RoundedRectangleBorder(
                                //             borderRadius: BorderRadius.all(Radius.circular(60))
                                //         ),
                                //         child: IconButton(
                                //             onPressed: (){
                                //               setState(() {
                                //                 if(ind <= 0){
                                //                   ind = 0;
                                //                 }else {
                                //                   if(ind > welcomeImages[index]["images"].length - 1){
                                //                     ind = ind - 1;
                                //                   }else{
                                //                     ind = 0;
                                //                   }
                                //                 }
                                //               });
                                //               //_matchEngine!.currentItem!.nope();
                                //             }, icon: Icon(Icons.keyboard_arrow_left,color: ascent,)),
                                //       ),
                                //     ),
                                //     Padding(
                                //       padding: const EdgeInsets.only(right: 20.0),
                                //       child: Card(
                                //         elevation:20,
                                //         color: Colors.black.withOpacity(0.4),
                                //         shape: RoundedRectangleBorder(
                                //             borderRadius: BorderRadius.all(Radius.circular(60))
                                //         ),
                                //         child: IconButton(onPressed: (){
                                //           setState(() {
                                //             if(ind >= welcomeImages[index]["images"].length){
                                //               ind = 0;
                                //             }else {
                                //               if(ind < welcomeImages[index]["images"].length - 1){
                                //                 ind = ind + 1;
                                //               }else{
                                //                 ind = 0;
                                //               }
                                //             }
                                //           });
                                //         }, icon: Icon(Icons.keyboard_arrow_right,color: ascent,)),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                // Padding(
                                //   padding: const EdgeInsets.only(bottom: 20.0),
                                //   child: SizedBox(
                                //     height: 80,
                                //     width: MediaQuery.of(context).size.width,
                                //     child: Row(
                                //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                //       children: [
                                //         // SizedBox(
                                //         //   height: 70,
                                //         //   width: 70,
                                //         //   child: Card(
                                //         //     elevation:20,
                                //         //     color: Colors.black.withOpacity(0.6),
                                //         //     shape: const RoundedRectangleBorder(
                                //         //         borderRadius: BorderRadius.all(Radius.circular(60))
                                //         //     ),
                                //         //     child:loading4 == true ? const SpinKitCircle(color: Colors.red,size: 20,) : IconButton(
                                //         //         onPressed: (){
                                //         //           createDisLike(posts[index].id);
                                //         //           setState(() {
                                //         //             posts.removeAt(index);
                                //         //           });
                                //         //
                                //         //         }, icon: Icon(Icons.remove,color: Colors.yellow.shade900,size: 35,)),
                                //         //   ),
                                //         // ),
                                //         SizedBox(
                                //           height: 70,
                                //           width: 70,
                                //           child: Card(
                                //               elevation:20,
                                //               color: Colors.black.withOpacity(0.6),
                                //               shape: const RoundedRectangleBorder(
                                //                   borderRadius: BorderRadius.all(Radius.circular(60))
                                //               ),
                                //               child: IconButton(onPressed: (){
                                //                 saveStyle(posts[index].id);
                                //               }, icon:loading3 == true ? SpinKitCircle(size: 20,color: primary,) :Image.asset("assets/logo.png",height: 100,))
                                //           ),
                                //         ),
                                //         // SizedBox(
                                //         //   height: 70,
                                //         //   width: 70,
                                //         //   child: Card(
                                //         //     elevation:20,
                                //         //     color: Colors.black.withOpacity(0.6),
                                //         //     shape: const RoundedRectangleBorder(
                                //         //         borderRadius: BorderRadius.all(Radius.circular(80))
                                //         //     ),
                                //         //     child:loading1 == true ? const SpinKitCircle(color: Colors.red,size: 20,) : IconButton(onPressed: (){
                                //         //       createLike(posts[index].id);
                                //         //
                                //         //       //controller.swipeRight();
                                //         //       setState(() {
                                //         //         posts.removeAt(index);
                                //         //       });
                                //         //     }, icon: const Icon(Icons.favorite,color: Colors.red,size: 35,)),
                                //         //   ),
                                //         // ),
                                //       ],
                                //     ),
                                //   ),
                                // ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    //  Padding(
                                    //    padding: const EdgeInsets.all(8.0),
                                    //    child: Align(alignment: Alignment.topLeft,child: Text("About my style:", style: TextStyle(fontSize: 16.0,fontFamily: Poppins,color: primary,fontWeight: FontWeight.bold))),
                                    //  ),
                                    // const SizedBox(height: 4,),
                                    // Padding(
                                    //   padding: const EdgeInsets.all(8.0),
                                    //   child: AutoSizeText(
                                    //     posts[index].description,
                                    //     style:  TextStyle(fontSize: 14.0,fontFamily: Poppins,color: primary),
                                    //   ),
                                    // ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(
                                          height: 70,
                                          width: 70,
                                          child: Card(
                                              elevation:20,
                                              color: Colors.black.withOpacity(0.6),
                                              shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(60))
                                              ),
                                              child: IconButton(onPressed: (){
                                                saveStyle(posts[index].id);
                                              }, icon:loading3 == true ? SpinKitCircle(size: 20,color: primary,) :Image.asset("assets/logo.png",height: 100,))
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Align(alignment: Alignment.topLeft,child: Text("About my style:", style: TextStyle(fontSize: 16.0,fontFamily: Poppins,color: primary,fontWeight: FontWeight.bold))),
                              ),
                              const SizedBox(height: 1,),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  width:MediaQuery.of(context).size.width * 0.8,
                                  child: Text(
                                    posts[index].description,
                                    style:  TextStyle(fontSize: 14.0,fontFamily: Poppins,color: primary,fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10,),
                        ],
                      ),
                      placeholder: (context, url) => SpinKitCircle(color: primary,size: 60,),
                      errorWidget: (context, url, error) => ListView(
                        children: [
                          Container(
                            height:MediaQuery.of(context).size.height * 0.84,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
                                  fit: BoxFit.fill
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left:25.0,right:25,top: 20,bottom: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap:(){
                                          Navigator.push(context,MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                            id: posts[index].userid,
                                            username: posts[index].userName,
                                          )));
                                        },
                                        child: Card(
                                          elevation: 20,
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(30))
                                          ),
                                          color: Colors.black.withOpacity(0.6),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: SizedBox(
                                              width: 150,
                                              child: Row(
                                                children: [
                                                  const SizedBox(width: 10,),
                                                  CircleAvatar(
                                                      child: ClipRRect(
                                                        borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                        child: posts[index].userPic == null ?Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,):CachedNetworkImage(
                                                          imageUrl: posts[index].userPic,
                                                          imageBuilder: (context, imageProvider) => Container(
                                                            height:MediaQuery.of(context).size.height * 0.7,
                                                            width: MediaQuery.of(context).size.width,
                                                            decoration: BoxDecoration(
                                                              image: DecorationImage(
                                                                image: imageProvider,
                                                                fit: BoxFit.cover,
                                                              ),
                                                            ),
                                                          ),
                                                          placeholder: (context, url) => Center(child: SpinKitCircle(color: primary,size: 10,)),
                                                          errorWidget: (context, url, error) => ClipRRect(
                                                              borderRadius: const BorderRadius.all(Radius.circular(50)),
                                                              child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,)
                                                          ),
                                                        ),
                                                      )),
                                                  const SizedBox(width: 10,),
                                                  Text(posts[index].userName,style: const TextStyle(fontFamily: Poppins,color: ascent,fontWeight: FontWeight.bold),)
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Card(
                                        elevation: 20,
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(30))
                                        ),
                                        color: Colors.black.withOpacity(0.6),
                                        child: PopupMenuButton(
                                            icon:const Icon(Icons.more_horiz,color: ascent,),
                                            onSelected: (value) {
                                              if (value == 0) {
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                                  id: posts[index].userid,
                                                  username: posts[index].userName,
                                                )));
                                              }
                                              print(value);
                                              //Navigator.pushNamed(context, value.toString());
                                            }, itemBuilder: (BuildContext bc) {
                                          return [
                                            PopupMenuItem(
                                              value: 0,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons.person
                                                  ),
                                                  SizedBox(width: 10,),
                                                  Text("View Profile",style: TextStyle(fontFamily: Poppins,),),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 1,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons.report
                                                  ),
                                                  SizedBox(width: 10,),
                                                  Text("Report",style: TextStyle(fontFamily: Poppins,),),
                                                ],
                                              ),
                                            ),
                                          ];
                                        }),
                                      )
                                    ],
                                  ),
                                ),
                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //   children: [
                                //     Padding(
                                //       padding: const EdgeInsets.only(left:28.0),
                                //       child: Card(
                                //         elevation:20,
                                //         color: Colors.black.withOpacity(0.4),
                                //         shape: RoundedRectangleBorder(
                                //             borderRadius: BorderRadius.all(Radius.circular(60))
                                //         ),
                                //         child: IconButton(
                                //             onPressed: (){
                                //               setState(() {
                                //                 if(ind <= 0){
                                //                   ind = 0;
                                //                 }else {
                                //                   if(ind > welcomeImages[index]["images"].length - 1){
                                //                     ind = ind - 1;
                                //                   }else{
                                //                     ind = 0;
                                //                   }
                                //                 }
                                //               });
                                //               //_matchEngine!.currentItem!.nope();
                                //             }, icon: Icon(Icons.keyboard_arrow_left,color: ascent,)),
                                //       ),
                                //     ),
                                //     Padding(
                                //       padding: const EdgeInsets.only(right: 20.0),
                                //       child: Card(
                                //         elevation:20,
                                //         color: Colors.black.withOpacity(0.4),
                                //         shape: RoundedRectangleBorder(
                                //             borderRadius: BorderRadius.all(Radius.circular(60))
                                //         ),
                                //         child: IconButton(onPressed: (){
                                //           setState(() {
                                //             if(ind >= welcomeImages[index]["images"].length){
                                //               ind = 0;
                                //             }else {
                                //               if(ind < welcomeImages[index]["images"].length - 1){
                                //                 ind = ind + 1;
                                //               }else{
                                //                 ind = 0;
                                //               }
                                //             }
                                //           });
                                //         }, icon: Icon(Icons.keyboard_arrow_right,color: ascent,)),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20.0),
                                  child: SizedBox(
                                    height: 80,
                                    width: MediaQuery.of(context).size.width,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            SizedBox(
                                              height: 70,
                                              width: 70,
                                              child: Card(
                                                elevation:20,
                                                color: Colors.black.withOpacity(0.6),
                                                shape: const RoundedRectangleBorder(
                                                  side: BorderSide(
                                                    color: Colors.orange,
                                                  ),
                                                  borderRadius: BorderRadius.all(Radius.circular(60)),
                                                ),
                                                child:loading4 == true ? const SpinKitCircle(color: Colors.red,size: 20,) : IconButton(
                                                    onPressed: (){
                                                      createDisLike(posts[index].id);
                                                    }, icon: Icon(Icons.remove,color: Colors.yellow.shade900,size: 35,)),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 70,
                                              width: 70,
                                              child: Card(
                                                  elevation:20,
                                                  color: Colors.black.withOpacity(0.6),
                                                  shape: const RoundedRectangleBorder(
                                                      side: BorderSide(
                                                        color: Colors.pink,
                                                      ),
                                                      borderRadius: BorderRadius.all(Radius.circular(60))
                                                  ),
                                                  child: IconButton(onPressed: (){
                                                    saveStyle(posts[index].id);
                                                  }, icon:loading3 == true ? const SpinKitCircle(size: 20,color: ascent,) :Image.asset("assets/logo.png",height: 80,width: 30,))
                                              ),
                                            ),
                                            SizedBox(
                                              height: 70,
                                              width: 70,
                                              child: Card(
                                                elevation:20,
                                                color: Colors.black.withOpacity(0.6),
                                                shape: const RoundedRectangleBorder(
                                                    side: BorderSide(
                                                      color: Colors.red,
                                                    ),
                                                    borderRadius: BorderRadius.all(Radius.circular(80))
                                                ),
                                                child:loading1 == true ? const SpinKitCircle(color: Colors.red,size: 20,) : IconButton(onPressed: (){
                                                  createLike(posts[index].id);
                                                  //controller.swipeRight();
                                                }, icon: const Icon(Icons.favorite,color: Colors.red,size: 30,)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        AutoSizeText(
                                          posts[index].description,
                                          style: const TextStyle(fontSize: 20.0,fontFamily: Poppins,color: dark1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            color:Colors.transparent,
                            child: Padding(
                              padding:const EdgeInsets.all(20),
                              child: Container(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 300.0,
                                    maxWidth: 300.0,
                                    minHeight: 30.0,
                                    maxHeight: 300.0,
                                  ),
                                  child: AutoSizeText(
                                    posts[index].description,
                                    style: const TextStyle(fontSize: 20.0,fontFamily: Poppins,color: dark1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10,),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        )),
      ),
    );
  }
}