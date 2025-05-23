import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart'as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../animations/bottom_animation.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
class SharePost extends StatefulWidget {
  final String postId;
  const SharePost({super.key, required this.postId});

  @override
  State<SharePost> createState() => _SharePostState();
}
String id = "";
String token = "";
bool like = false;
bool dislike = false;
bool loading=false;
List<PostModel> posts = [];
final CarouselSliderController _carouselController = CarouselSliderController();
int _current=0;
class _SharePostState extends State<SharePost> {
  getPosts() {
    posts.clear();
    setState(() {
      loading = true;
    });

    try {
      https.get(Uri.parse("$serverUrl/fashionUpload/${widget.postId}/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {

        setState(() {
          loading = false;
        });

        Map<String, dynamic> response = jsonDecode(value.body);
        // Access properties directly from the response
        var upload = response["upload"];
        var results = upload != null ? upload["media"] : [];

        results.forEach((result) {
          posts.add(PostModel(
              response["id"].toString(),
              response["description"],
              result != null ? [result] : [],
              response["user"]["name"],
              response["user"]["pic"] ?? "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
              false,
              response["likesCount"].toString(),
              response["disLikesCount"].toString(),
              response["commentsCount"].toString(),
              response["created"],
              "",
              response["user"]["id"].toString(),
              response["myLike"] == null ? "like" : response["myLike"].toString(),
              {},
              {},
              addMeInFashionWeek: response["addMeInWeekFashion"],
              isCommentEnabled: response["isCommentOff"]));

          debugPrint(
              "value of add me in next fashion week is ${response["addMeInWeekFashion"]}");
          debugPrint("value of isCommentEnabled is ${response["isCommentOff"]}");
        });
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print("user token====>$token");
    getPosts();

  }

  @override
  void initState() {
    getCashedData();
    // TODO: implement initState
    super.initState();
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
        title: const Text("Posts",style: TextStyle(fontFamily: Poppins),),
      ),
      body:
      posts.isEmpty?
      SpinKitCircle(color: primary,):
      ListView(
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
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: (){
                      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                      //   id: widget.userid,
                      //   username: widget.createdBy,
                      // )));
                    },
                    child: Row(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                                  child: posts[0].userPic == null ?Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,):CachedNetworkImage(
                                    imageUrl: posts[0].userPic,
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
                            Text(posts[0].userName,style: const TextStyle(color: ascent,fontSize: 15,fontWeight: FontWeight.bold,fontFamily: Poppins),)
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
                // InteractiveViewer(
                //   panEnabled: true,
                //   minScale: 1,
                //   maxScale: 3,
                //   child: Container(
                //     color: dark1,
                //     height: 320,
                //     width: MediaQuery.of(context).size.width,
                //     child: CarouselSlider(
                //       carouselController: _carouselController,
                //       options: CarouselOptions(
                //           height: 320.0,
                //           autoPlay: false,
                //           enlargeCenterPage: true,
                //           viewportFraction: 0.99,
                //           aspectRatio: 2.0,
                //           initialPage: 0,
                //           enableInfiniteScroll:  posts[0].images.length>1,
                //           onPageChanged: (ind,reason){
                //             setState(() {
                //               _current = ind;
                //             });
                //           }
                //
                //       ),
                //       items:  posts[0].images.map((i) {
                //         print(i);
                //         return i["type"] == "video" ? UsingVideoControllerExample(
                //           path: i["video"],
                //         ) : Builder(
                //           builder: (BuildContext context) {
                //             return InteractiveViewer(
                //               panEnabled: true,
                //               minScale: 1,
                //               maxScale: 3,
                //               child: CachedNetworkImage(
                //                 imageUrl: i["image"],
                //                 imageBuilder: (context, imageProvider) => Container(
                //                   height:MediaQuery.of(context).size.height ,
                //                   width: MediaQuery.of(context).size.width,
                //                   decoration: BoxDecoration(
                //                     image: DecorationImage(
                //                       image: imageProvider,
                //                       fit: BoxFit.cover,
                //                     ),
                //                   ),
                //                 ),
                //                 placeholder: (context, url) => SpinKitCircle(color: primary,size: 60,),
                //                 errorWidget: (context, url, error) => Container(
                //                   height:MediaQuery.of(context).size.height * 0.84,
                //                   width: MediaQuery.of(context).size.width,
                //                   decoration: BoxDecoration(
                //                     image: DecorationImage(
                //                         image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png").image,
                //                         fit: BoxFit.fill
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             );
                //           },
                //         );
                //       }).toList(),
                //     ),
                //   ),
                // ),
              ],
            ),



          ),
          posts[0].images.length == 1 ?
          const SizedBox() : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: posts[0].images.asMap().entries.map((entry) {
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
                                posts[0].likeCount=="0"?
                                const SizedBox():
                                Text(posts[0].likeCount,style: TextStyle(fontFamily: Poppins,color: primary),),
                              ],
                            ),
                            const SizedBox(width: 10,),
                            Row(
                              children: [
                               posts[0].addMeInFashionWeek==true?
                                Icon(posts[0].mylike== "like" ? Icons.favorite_border : Icons.favorite ,color: Colors.red,):
                                Icon(posts[0].mylike== "like" ? Icons.star_border : Icons.star ,color: Colors.orange,)
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
                        posts[0].description,
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

