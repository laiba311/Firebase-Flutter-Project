import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/videos-pages/video_file.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import '../../utils/constants.dart';

class SwapDetail extends StatefulWidget {
  final String userid;
  final List<dynamic> image;
  final String description;
  final String createdBy;
  final String style;
  final String profile;
  final String likes;
  final String dislikes;
  final String mylike;
  final bool isPrivate;
  final String id;
  final List<dynamic> fansList; 
  final List<dynamic> followList;
  final String username;
  final String token;
  bool? addMeInFashionWeek;

   SwapDetail({Key? key, required this.image, required this.description, required this.createdBy, required this.style, required this.profile, required this.likes, required this.dislikes, required this.userid, required this.mylike,   this.addMeInFashionWeek, required this.isPrivate, required this.fansList, required this.id, required this.followList, required this.username, required this.token}) : super(key: key);

  @override
  State<SwapDetail> createState() => _SwapDetailState();
}

class _SwapDetailState extends State<SwapDetail> {
  bool like = false;
  bool dislike = false;
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _current=0;
  bool isGetRequest = false;
  bool requestLoader = false;
  bool isfan1 = false;
  bool requestLoader2 = false;
  bool isfan = false;
  bool requestLoader1 = false;
  bool loading = false;
  String fanRequestID = "";
  String fansId = "";

  getRequests() {
    try {
      https.get(Uri.parse("$serverUrl/Request/personrequests/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.token}"
      }).then((value) {
        print("requests ==> ${value.body.toString()}");
        jsonDecode(value.body).forEach((e){
          if(e["from_user"]["id"].toString() == widget.id && e["to_user"]["id"].toString() == widget.userid){
            setState(() {
              isfan1 = true;
            });
            fanRequestID = e["id"].toString();
            print("Fan Request ID ${fanRequestID}");
          }
          print("item => ${e}");
        });
        setState(() {
          loading = false;
        });
        //print("favourite list => ${myList}");
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  sendFanRequest(from,to){
    setState(() {
      requestLoader2 = true;
    });
    https.post(
      Uri.parse("$serverUrl/Request/personrequests/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.token}"
      },
      body: json.encode({
        "from_user": from,
        "to_user": to,
        "to_token": widget.token
      }),
    ).then((value){
      setState(() {
        requestLoader2 = false;
      });
      print("Fans Request Response ==> ${value.body.toString()}");
      setState(() {
        loading = true;
      });
      getRequests();
    }).catchError((value){
      setState(() {
        requestLoader2 = false;
      });
      print(value);
    });
  }
  cancelFanRequest(fanId){
    setState(() {
      requestLoader2 = true;
    });
    https.delete(
      Uri.parse("$serverUrl/Request/personrequests/$fanId/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.token}"
      },
    ).then((value){
      setState(() {
        requestLoader2 = false;
        isfan1 = false;
      });
      print(value.body.toString());
      setState(() {
        loading = true;
      });
      getRequests();
    }).catchError((value){
      setState(() {
        requestLoader2 = false;
      });
      print(value);
    });
  }
  getFan(from,to){
    https.get(
      Uri.parse("$serverUrl/fansRequests/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.token}"
      },
    ).then((value){
      json.decode(value.body).forEach((e){
        if(widget.id == e["from_user"].toString() && widget.userid == e["to_user"].toString()){
          print("found fan");
          setState(() {
            isfan = true;
            fansId = e["id"].toString();
          });
        }else {
          print("Not found fan");
        }
      });
    }).catchError((value){
      setState(() {
        requestLoader1 = false;
      });
      print(value);
    });
  }
  addFan(from,to){
    setState(() {
      requestLoader1 = true;
      loading = true;
    });
    https.post(
      Uri.parse("$serverUrl/fansRequests/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.token}"
      },
      body: json.encode({
        "from_user": from,
        "to_user": to
      }),
    ).then((value){
      setState(() {
        requestLoader1 = false;
      });
      print("Fans Response ==> ${value.body.toString()}");
      getFan(widget.id,widget.userid);
    }).catchError((value){
      setState(() {
        requestLoader1 = false;
      });
      print(value);
    });
  }
  removeFan(fanId){
    setState(() {
      requestLoader1 = true;
      loading = true;
    });
    https.delete(
      Uri.parse("$serverUrl/fansfansRequests/$fanId/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${widget.token}"
      },
    ).then((value){
      setState(() {
        requestLoader1 = false;
        isfan = false;
      });
      print(value.body.toString());
      getFan(widget.id,widget.userid);
    }).catchError((value){
      setState(() {
        requestLoader1 = false;
      });
      print(value);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getRequests();
    getFan(widget.id,widget.userid);
    //print(widget.image[2]);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      //   title: const Text("Posts",style: TextStyle(fontFamily: Poppins),),
      // ),
      body: ListView(
        children: [
          WidgetAnimator(
            Container(
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
              // color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.only(top:10.0,bottom: 10),
                child: GestureDetector(
                  onTap: (){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                      id: widget.userid,
                      username: widget.createdBy,
                    )));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Row(
                              children: [
                                CircleAvatar(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                                      child: widget.profile == null ?Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,):CachedNetworkImage(
                                        imageUrl: widget.profile,
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
                                Text(Uri.decodeComponent(widget.createdBy),style: const TextStyle(color: ascent,fontSize: 15,fontWeight: FontWeight.bold,fontFamily: Poppins),),
                              ],
                            ),
                             if(widget.isPrivate == true && (widget.fansList ?? []).contains(int.parse(widget.id)) == false && ((widget.followList ?? []).contains(int.parse(widget.id)) == false)) if(widget.userid != widget.id) SizedBox(width: MediaQuery.of(context).size.width * 0.3),
                             if(widget.isPrivate == false || (widget.fansList ?? []).contains(int.parse(widget.id)) == true || ((widget.followList ?? []).contains(int.parse(widget.id)) == true)) if(widget.id != widget.userid) SizedBox(width: MediaQuery.of(context).size.width * 0.3),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.end,
                               children: [
                                 if(widget.isPrivate == true && (widget.fansList ?? []).contains(int.parse(widget.id)) == false && ((widget.followList ?? []).contains(int.parse(widget.id)) == false)) if(widget.userid != widget.id) GestureDetector(
                                   onTap: () {
                                     if(isfan1 == false){
                                       showDialog(
                                         context: context,
                                         builder: (context) => AlertDialog(
                                           backgroundColor: primary,
                                           title: Text("Fan request ${widget.username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                           content: Text("Are you sure you want to send fan request to ${widget.username}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                           actions: [
                                             TextButton(
                                               child: Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                               onPressed:  () {
                                                 setState(() {
                                                   Navigator.pop(context);
                                                 });
                                               },
                                             ),
                                             TextButton(
                                               child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                               onPressed:  () {
                                                 //print(data["id"].toString());
                                                 Navigator.pop(context);
                                                 sendFanRequest(widget.id,widget.userid);
                                               },
                                             ),
                                           ],
                                         ),
                                       );
                                     }else if(isfan1 == true) {
                                       //commentedPost.clear();
                                       showDialog(
                                         context: context,
                                         builder: (context) => AlertDialog(
                                           backgroundColor: primary,
                                           title: Text("Cancel request ${widget.username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                           content: Text("Are you sure you want to cancel fan request to ${widget.username}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                           actions: [
                                             TextButton(
                                               child: Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                               onPressed:  () {
                                                 setState(() {
                                                   Navigator.pop(context);
                                                 });
                                               },
                                             ),
                                             TextButton(
                                               child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                               onPressed:  () {
                                                 //print(data["id"].toString());
                                                 Navigator.pop(context);
                                                 cancelFanRequest(fanRequestID);
                                               },
                                             ),
                                           ],
                                         ),
                                       );
                                       //removeFan(widget.id);
                                     }
                                     //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                                   },
                                   child: Card(
                                     shape: const RoundedRectangleBorder(
                                         borderRadius: BorderRadius.all(Radius.circular(15))
                                     ),
                                     child: Container(
                                       alignment: Alignment.center,
                                       height: 35,
                                       width: MediaQuery.of(context).size.width * 0.3,
                                       decoration: BoxDecoration(
                                           gradient: LinearGradient(
                                               begin: Alignment.topLeft,
                                               end: Alignment.topRight,
                                               stops: const [0.0, 0.99],
                                               tileMode: TileMode.clamp,
                                               colors: isfan1 == true ? [
                                                 Colors.grey,
                                                 Colors.grey
                                               ] : <Color>[
                                                 secondary,
                                                 primary,
                                               ]),
                                           borderRadius: const BorderRadius.all(Radius.circular(12))
                                       ),
                                       child: requestLoader2 == true ? const SpinKitCircle(color: ascent, size: 20,) : Text(isfan1 == true ? 'Requested' :'Fan Request',style: const TextStyle(
                                           fontSize: 15,
                                           fontWeight: FontWeight.w700,
                                           fontFamily: Poppins
                                       ),),
                                     ),
                                   ),
                                 ),
                                 if(widget.isPrivate == false || (widget.fansList ?? []).contains(int.parse(widget.id)) == true || ((widget.followList ?? []).contains(int.parse(widget.id)) == true)) if(widget.id != widget.userid) GestureDetector(
                                   onTap: () {
                                     if(isfan == false){
                                       //commentedPost.clear();
                                       addFan(widget.id,widget.userid);
                                     }else if(isfan == true) {
                                       //commentedPost.clear();
                                       removeFan(widget.userid);
                                     }
                                     //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                                   },
                                   child: Card(
                                     shape: const RoundedRectangleBorder(
                                         borderRadius: BorderRadius.all(Radius.circular(15))
                                     ),
                                     child: Container(
                                       alignment: Alignment.center,
                                       height: 35,
                                       width: MediaQuery.of(context).size.width * 0.3,
                                       decoration: BoxDecoration(
                                           gradient: LinearGradient(
                                               begin: Alignment.topLeft,
                                               end: Alignment.topRight,
                                               stops: const [0.0, 0.99],
                                               tileMode: TileMode.clamp,
                                               colors: isfan == true ? [
                                                 Colors.grey,
                                                 Colors.grey
                                               ] : <Color>[
                                                 secondary,
                                                 primary,
                                               ]),
                                           borderRadius: const BorderRadius.all(Radius.circular(12))
                                       ),
                                       child: requestLoader1 == true ? const SpinKitCircle(color: ascent, size: 20,) : Text(isfan == true ? 'Unfan' :'Fan',style: const TextStyle(
                                           fontSize: 15,
                                           fontWeight: FontWeight.w700,
                                           fontFamily: Poppins
                                       ),),
                                     ),
                                   ),
                                 ),
                               ],
                             )
                           ],
                         ),
                      ],
                  ),
                ),
              ),
            )
          ),
          WidgetAnimator(
            Row(
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 1,
                  maxScale: 3,
                  child: Container(
                    color: dark1,
                    height: 400,
                    width: MediaQuery.of(context).size.width,
                    child: CarouselSlider(
                      carouselController: _carouselController,
                      options: CarouselOptions(
                        height: 400.0,
                        autoPlay: false,
                        enlargeCenterPage: true,
                        viewportFraction: 0.99,
                        aspectRatio: 2.0,
                        initialPage: 0,
                        enableInfiniteScroll:  widget.image.length>1,
                          onPageChanged: (ind,reason){
                            setState(() {
                              _current = ind;
                            });
                          }

                       ),
                      items: widget.image.map((i) {
                        print(i);
                        return i["type"] == "video" ?
                        Container(
                          color: Colors.black,
                          child:Text("Video"),)
                        // UsingVideoControllerExample(
                        //   path: i["video"],
                        // )
                            : Builder(
                          builder: (BuildContext context) {
                            return InteractiveViewer(
                              panEnabled: true,
                              minScale: 1,
                              maxScale: 3,
                              child: CachedNetworkImage(
                                imageUrl: i["image"],
                                imageBuilder: (context, imageProvider) => Container(
                                  height:MediaQuery.of(context).size.height ,
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) => SpinKitCircle(color: primary,size: 60,),
                                errorWidget: (context, url, error) => Container(
                                  height:MediaQuery.of(context).size.height * 0.84,
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
                                        fit: BoxFit.fill
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          widget.image.length == 1 ?
          const SizedBox() : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.image.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _carouselController.animateToPage(entry.key),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black.withOpacity(_current == entry.key ? 0.9 : 0.4))
                  ),
                ),
              );
            }).toList(),
          ),
          // const SizedBox(height: 10,),
          WidgetAnimator(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: (){
                      setState(() {
                        like = true;
                        dislike = false;
                      });
                    },
                    child: Card(
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                widget.likes=="0"?
                                const SizedBox():
                                Text(widget.likes,style: TextStyle(fontFamily: Poppins,color: primary),),
                              ],
                            ),
                            const SizedBox(width: 10,),
                            Row(
                              children: [
                                widget.addMeInFashionWeek==true?
                                Icon(widget.mylike == "like" ? Icons.favorite_border : Icons.favorite ,color: Colors.red,):
                                Icon(widget.mylike == "like" ? Icons.star_border : Icons.star ,color: Colors.orange,)
                              ],
                            ),
                            const SizedBox(width: 5,),
                            // Row(
                            //   children: [
                            //     Text("Likes",style: TextStyle(
                            //         color: primary,
                            //         fontFamily: Poppins
                            //     ),)
                            //   ],
                            // )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          WidgetAnimator(
              Row(
                children: [
                  const SizedBox(width: 15),
                  Container(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 20.0,
                        maxWidth: 365.0,
                        minHeight: 20.0,
                        maxHeight: 300.0,
                      ),
                      child: AutoSizeText(
                        widget.description,
                         style: const TextStyle(fontSize: 10.0,fontFamily: Poppins),
                      ),
                    ),
                  ),
                ],
              )
          ),
          const SizedBox(height: 50,),
        ],
      ),
    );
  }
}

// class PlayVideoFromNetwork extends StatefulWidget {
//   final String path;
//   const PlayVideoFromNetwork({Key? key, required this.path}) : super(key: key);
//
//   @override
//   State<PlayVideoFromNetwork> createState() => _PlayVideoFromNetworkState();
// }
//
// class _PlayVideoFromNetworkState extends State<PlayVideoFromNetwork> {
//   late final PodPlayerController controller;
//
//   @override
//   void initState() {
//     controller = PodPlayerController(
//       playVideoFrom: PlayVideoFrom.network(
//         widget.path,
//       ),
//     )..initialise().then((value){
//       setState(() {
//         controller.pause();
//         controller.mute();
//       });
//     });
//     super.initState();
//   }
//
//
//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PodVideoPlayer(
//         controller: controller);
//   }
// }
//


