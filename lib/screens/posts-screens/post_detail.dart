import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
//import 'package:fashiontimefinal/screens/pages/fashionComments/comment_screen.dart';
import 'package:finalfashiontimefrontend/models/post_model.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import '../../animations/bottom_animation.dart';
import '../../utils/constants.dart';

class PostDetail extends StatefulWidget {
  final String postId;
  const PostDetail({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  String id = "";
  String token = "";
  bool loading = false;
  PostModel post = PostModel("", "", [], "", "", false, "", "", "", "", "", "", "",{},{});

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
    print(token);
    getPosts();
  }

  getPosts(){
    setState(() {
      loading = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/fashionUpload/${widget.postId}/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        setState(() {
          loading = false;
        });
        print(jsonDecode(value.body).toString());
          setState(() {
            post = PostModel(
                jsonDecode(value.body)["id"].toString(),
                jsonDecode(value.body)["description"] ?? "",
                jsonDecode(value.body)["upload"]["media"],
                jsonDecode(value.body)["user"]["name"],
                jsonDecode(value.body)["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                false,
                jsonDecode(value.body)["likesCount"].toString(),
                jsonDecode(value.body)["disLikesCount"].toString(),
                jsonDecode(value.body)["commentsCount"].toString(),
                jsonDecode(value.body)["created"],
                "",
                jsonDecode(value.body)["user"]["id"].toString(),
                jsonDecode(value.body)["myLike"] == null ? "like" : jsonDecode(value.body)["myLike"].toString(),
              {},
              {}
            );
          });
      });
    }catch(e){
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        centerTitle: true,
        title: const Text("Post Details",style: TextStyle(
            color: Colors.white,
            fontFamily: Poppins
        ),),
      ),
      body: loading == true ? SpinKitCircle(size: 50,color: primary,) : ListView(
        children: [
          WidgetAnimator(
              Container(
                color: Colors.deepPurple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: (){
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                        id: post.userid,
                        username: post.userName,
                      )));
                    },
                    child: Row(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                                  child: post.userPic == null ?Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,):CachedNetworkImage(
                                    imageUrl: post.userPic,
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
                            Text(post.userName,style: TextStyle(color: primary,fontSize: 15,fontWeight: FontWeight.bold,fontFamily: Poppins),)
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
                // Container(
                //   color: dark1,
                //   height: 320,
                //   width: MediaQuery.of(context).size.width,
                //   child: CarouselSlider(
                //     options: CarouselOptions(
                //       height: 320.0,
                //       autoPlay: false,
                //       enlargeCenterPage: true,
                //       viewportFraction: 0.99,
                //       aspectRatio: 2.0,
                //       initialPage: 0,
                //     ),
                //     items: post.images.map((i) {
                //       print(i);
                //       return i["type"] == "video" ? UsingVideoControllerExample(
                //         path: i["video"],
                //       ) : Builder(
                //         builder: (BuildContext context) {
                //           return CachedNetworkImage(
                //             imageUrl: i["image"],
                //             imageBuilder: (context, imageProvider) => Container(
                //               height:MediaQuery.of(context).size.height * 0.7,
                //               width: MediaQuery.of(context).size.width,
                //               decoration: BoxDecoration(
                //                 image: DecorationImage(
                //                   image: imageProvider,
                //                   fit: BoxFit.cover,
                //                 ),
                //               ),
                //             ),
                //             placeholder: (context, url) => SpinKitCircle(color: primary,size: 60,),
                //             errorWidget: (context, url, error) => Container(
                //               height:MediaQuery.of(context).size.height * 0.84,
                //               width: MediaQuery.of(context).size.width,
                //               decoration: BoxDecoration(
                //                 image: DecorationImage(
                //                     image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
                //                     fit: BoxFit.fill
                //                 ),
                //               ),
                //             ),
                //           );
                //         },
                //       );
                //     }).toList(),
                //   ),
                // )
              ],
            ),
          ),
          const SizedBox(height: 10,),
          WidgetAnimator(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: (){
                      setState(() {

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
                                Text(post.likeCount,style: const TextStyle(fontFamily: Poppins),),
                              ],
                            ),
                            const SizedBox(width: 10,),
                            Row(
                              children: [
                                Icon(post.mylike == "like" ? Icons.favorite_border : Icons.favorite ,color: Colors.red,)
                              ],
                            ),
                            const SizedBox(width: 5,),
                            Row(
                              children: [
                                Text("Likes",style: TextStyle(
                                    color: primary,
                                    fontFamily: Poppins
                                ),)
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: (){
                      // showModalBottomSheet(
                      //     shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.only(
                      //             topLeft: Radius.circular(10),
                      //             topRight: Radius.circular(10)
                      //         )
                      //     ),
                      //     isScrollControlled: true,
                      //     context: context,
                      //     builder: (ctx) {
                      //       return DraggableScrollableSheet(
                      //           expand: false, // Ensures it doesn't expand fully by default
                      //           initialChildSize: 0.7, // Half screen by default
                      //           minChildSize: 0.3, // Minimum height
                      //           maxChildSize: 1.0,
                      //           builder: (BuildContext context, ScrollController scrollController) {
                      //             return CommentScreen(
                      //               postid: post.id,
                      //               pic: post.userPic,
                      //               scrollController: scrollController,
                      //             );
                      //           }
                      //       );
                      //     });
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
                                Icon(Icons.comment)
                              ],
                            ),
                            const SizedBox(width: 10,),
                            Row(
                              children: [
                                Text("Comments",style: TextStyle(
                                    color: primary,
                                    fontFamily: Poppins
                                ),)
                              ],
                            )
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
                        post.description,
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



