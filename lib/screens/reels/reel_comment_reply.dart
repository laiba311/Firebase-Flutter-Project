import 'dart:convert';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/screens/chats-screens/message_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:http/http.dart' as https;
import 'package:intl/intl.dart';
import '../../../animations/bottom_animation.dart';
import '../../../utils/constants.dart';


class ReelCommentReplyScreen extends StatefulWidget {
  final int commentId;
  final int userId;
  final String userPic;
  final String commentName;
  const ReelCommentReplyScreen({Key? key, required this.commentId,required this.userId,required this.userPic, required this.commentName})
      : super(key: key);

  @override
  State<ReelCommentReplyScreen> createState() => _ReelCommentReplyScreenState();
}

class _ReelCommentReplyScreenState extends State<ReelCommentReplyScreen> {
  List<dynamic> replyComments = [];
  List<dynamic> myReplyComments = [];
  bool loading = false;
  bool isFilterOn=false;
  bool loading1=false;
  TextEditingController comment=TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    debugPrint("comment id of fashion is ${widget.commentId}");
    getCommentsReply();
  }
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  getCommentsReply() async {
    setState(() {
      loading = true;
      replyComments.clear();
    });
    https.get(Uri.parse("$serverUrl/fashionReplyReelComments/${widget.commentId}/"),
        headers: {"Content-Type": "application/json"}).then((value) {
      setState(() {
        loading = false;
      });
      debugPrint("all reply data is ${value.body}");
      json.decode(value.body)["results"].forEach((data) {
        setState(() {
          replyComments.add(data);
        });
      });
    }).catchError((error) {
      setState(() {
        loading = false;
      });
      debugPrint("error in reply api ${error.toString()}");
    });
  }
  getMyCommentsReply(int id) async {
    setState(() {
      loading = true;
      replyComments.clear();
    });
    try {
      var response = await https.get(
        Uri.parse("$serverUrl/fashionReplyReelComments/${widget.commentId}/"),
        headers: {"Content-Type": "application/json"},
      );
      setState(() {
        loading = false;
      });
      debugPrint("all reply data is ${response.body}");
      List<dynamic> results = json.decode(response.body)["results"];
      // Filter only the items where the user id is equal to the specified userId
      List<dynamic> filteredComments = results
          .where((data) => data["user"]["id"] ==id)
          .toList();
      setState(() {
        myReplyComments.addAll(filteredComments);
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      debugPrint("error in reply api ${error.toString()}");
    }
  }
  String formatTimeDifference(String dateString) {
    DateTime createdAt = DateTime.parse(dateString);
    DateTime now = DateTime.now();

    Duration difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      int weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      int months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      int years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
  createCommentReply(int commentId,int userId) async {
    setState(() {
      loading1=true;
    });
    Map<String, dynamic> body = {
      "comment": comment.text,
      "comment_id": commentId,
      "user": userId
    };
    https.post(Uri.parse("$serverUrl/fashionReplyComments/"),
        body: json.encode(body),
        headers: {"Content-Type": "application/json"}).then((value) {
      setState(() {
        loading1=false;
        getCommentsReply();
        comment.clear();
      });
      debugPrint("reply posted with ${value.body}");
    });
  }
  String handleEmojis(String text) {
    List<int> bytes = text.toString().codeUnits;
    return utf8.decode(bytes);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                  ])),
        ),
        title: const Text(
          "Replies",
          style: TextStyle(fontFamily: Poppins,),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:  [
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
                label: const Text("Filter my comments",
                    style: TextStyle(fontFamily: Poppins,)),
                onSelected: (value) {
                  debugPrint("filter clicked");
                  myReplyComments.clear();
                  isFilterOn = !isFilterOn;
                  replyComments.clear();
                  getMyCommentsReply(widget.userId);
                  if (isFilterOn == false) {
                    replyComments.clear();
                    getCommentsReply();
                  }
                },
                backgroundColor: primary),
          ),
          loading==true?
          Expanded(
              child: SpinKitCircle(
                color: primary,
                size: 50,
              )):
          replyComments.isEmpty?
          myReplyComments.isNotEmpty?
          (Expanded(
            child: AnimationLimiter(
              child: ListView.builder(

                  itemCount: myReplyComments.length,
                  itemBuilder: (context,index) {
                    return AnimationConfiguration.staggeredList(position: index,duration: const Duration(milliseconds: 600),delay: const Duration(milliseconds: 300), child:SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child:
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: ListTile(
                            onTap: () {
                            },
                            shape:  RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            leading:  CircleAvatar(
                                backgroundColor: Colors.black,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                                  child: myReplyComments[index]["user"]["pic"] == null ?Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,):CachedNetworkImage(
                                    imageUrl: myReplyComments[index]["user"]["pic"],
                                    imageBuilder: (context, imageProvider) => Container(
                                      height:100,
                                      width: 100,
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
                                      child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,),
                                    ),
                                  ),
                                )),
                            title: Text(myReplyComments[index]["user"]["username"],style: const TextStyle(fontFamily: Poppins,fontWeight: FontWeight.w900)),
                            subtitle: Flexible(child: Text(handleEmojis(myReplyComments[index]["comment"]),style: const TextStyle(fontFamily: Poppins,),)),
                            trailing: Text(DateFormat.jm().format(DateTime.parse(myReplyComments[index]["created"]).toLocal()),style: TextStyle(fontFamily: Poppins,),),
                          ),
                        ) ,
                      ),
                    ) );
                  }
              ),
            ),
          )):
          const Center(child: Text("No Comments.",style: TextStyle(fontFamily: Poppins,fontWeight: FontWeight.w400) ,)):
          (Expanded(
            child: AnimationLimiter(
              child: ListView.builder(

                  itemCount: replyComments.length,
                  itemBuilder: (context,index) {
                    return AnimationConfiguration.staggeredList(position: index,duration: const Duration(milliseconds: 600),delay: const Duration(milliseconds: 300), child:SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child:

                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: ListTile(
                            onTap: () {
                            },
                            shape:  RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            leading:  CircleAvatar(
                                backgroundColor: Colors.black,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                                  child: replyComments[index]["user"]["pic"] == null ?Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,):CachedNetworkImage(
                                    imageUrl: replyComments[index]["user"]["pic"],
                                    imageBuilder: (context, imageProvider) => Container(
                                      height:100,
                                      width: 100,
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
                                      child: Image.network("https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",width: 40,height: 40,),
                                    ),
                                  ),
                                )),
                            title: Text(replyComments[index]["user"]["username"],style: const TextStyle(fontFamily: Poppins,fontWeight: FontWeight.w400)),
                            subtitle: Row(
                              children: [
                                Text(handleEmojis(widget.commentName),style:  TextStyle(fontFamily: Poppins,fontWeight: FontWeight.bold,color: primary),),
                                const SizedBox(width: 2,),
                                Flexible(child: Text(handleEmojis(replyComments[index]["comment"]),style: const TextStyle(fontFamily: Poppins,),)),
                              ],
                            ),
                            trailing: Text(DateFormat.jm().format(DateTime.parse(replyComments[index]["created"]).toLocal()),style: TextStyle(fontFamily: Poppins,),),
                          ),
                        ) ,
                      ),
                    ) );
                  }
              ),
            ),
          )),
          Row(
            children: [
              // WidgetAnimator(
              //   Container(
              //     alignment: Alignment.bottomCenter,
              //     width: MediaQuery
              //         .of(context)
              //         .size
              //         .width,
              //     child: Card(
              //       shape: const RoundedRectangleBorder(
              //         borderRadius: BorderRadius.all(Radius.circular(40)),
              //       ),
              //       child: Container(
              //         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 1),
              //         decoration: BoxDecoration(
              //           borderRadius: const BorderRadius.all(Radius.circular(40)),
              //           gradient: LinearGradient(
              //               begin: Alignment.bottomLeft,
              //               end: Alignment.bottomRight,
              //               colors: <Color>[primary, primary]),
              //         ),
              //         child: Row(
              //           children: [
              //             // const SizedBox(width: 16,),
              //
              //             SizedBox(width: 14,),
              //             Expanded(
              //                 child: AutoSizeTextField(
              //                   textCapitalization: TextCapitalization.sentences,
              //                   inputFormatters: <TextInputFormatter>[
              //                     UpperCaseTextFormatter()
              //                   ],
              //                   maxLines: null,
              //                   onTap: (){
              //                     //_controller.jumpTo(_controller.position.maxScrollExtent);
              //                   },
              //                   style: const TextStyle(color: ascent,fontFamily: Poppins),
              //                   cursorColor: ascent,
              //                   controller: comment,
              //                   //style: simpleTextStyle(),
              //                   decoration: const InputDecoration(
              //                       fillColor: ascent,
              //                       hintText: "Comment ...",
              //                       hintStyle: TextStyle(
              //                         color: ascent,
              //                         fontFamily: Poppins,
              //                         fontSize: 16,
              //                       ),
              //                       border: InputBorder.none
              //                   ),
              //                 )),
              //             const SizedBox(width: 16,),
              //             GestureDetector(
              //               onTap: () {
              //                 createCommentReply(widget.commentId,widget.userId);
              //               },
              //               child: Container(
              //                   height: 40,
              //                   width: 40,
              //                   decoration: BoxDecoration(
              //                       gradient: const LinearGradient(
              //                           colors: [
              //                             ascent,
              //                             ascent
              //                           ],
              //                           begin: FractionalOffset.topLeft,
              //                           end: FractionalOffset.bottomRight
              //                       ),
              //                       borderRadius: BorderRadius.circular(40)
              //                   ),
              //                   padding: const EdgeInsets.only(left:4),
              //                   child: Center(child: Icon(Icons.send,color: primary,))
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              // CircleAvatar(
              //     backgroundColor: ascent,
              //     child: ClipRRect(
              //       borderRadius: const BorderRadius.all(Radius.circular(50)),
              //       // ignore: unnecessary_null_comparison
              //       child: widget.userPic == null
              //           ? Image.network(
              //         "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
              //         width: 40,
              //         height: 40,
              //       )
              //           : CachedNetworkImage(
              //         imageUrl: widget.userPic,
              //         imageBuilder: (context, imageProvider) =>
              //             Container(
              //               height: 100,
              //               width: 100,
              //               decoration: BoxDecoration(
              //                 color: Colors.black,
              //                 image: DecorationImage(
              //                   image: imageProvider,
              //                   fit: BoxFit.cover,
              //                 ),
              //               ),
              //             ),
              //         placeholder: (context, url) => Center(
              //             child: SpinKitCircle(
              //               color: primary,
              //               size: 10,
              //             )),
              //         errorWidget: (context, url, error) =>
              //             const Icon(Icons.error),
              //       ),
              //     )),
              // const SizedBox(
              //   width: 16,
              // ),
              // Expanded(
              //     child: TextField(
              //       style: const TextStyle(color: ascent, fontFamily: Poppins),
              //       cursorColor: ascent,
              //       controller: comment,
              //       //style: simpleTextStyle(),
              //       decoration: const InputDecoration(
              //           fillColor: ascent,
              //           hintText: "Add reply here...",
              //           hintStyle: TextStyle(
              //             color: ascent,
              //             fontFamily: Poppins,
              //             fontSize: 16,
              //           ),
              //           border: InputBorder.none),
              //     )),
              // const SizedBox(
              //   width: 16,
              // ),
              // GestureDetector(
              //   onTap: loading1 == false
              //       ? () {
              //     FocusScope.of(context).unfocus();
              //     createCommentReply(widget.commentId,widget.userId);
              //   }
              //       : () {
              //     debugPrint("Empty Text field");
              //   },
              //   child: loading1 == true
              //       ? const SpinKitCircle(
              //     color: ascent,
              //     size: 20,
              //   )
              //       : Container(
              //       height: 40,
              //       width: 40,
              //       decoration: BoxDecoration(
              //           gradient: const LinearGradient(
              //               colors: [ascent, ascent],
              //               begin: FractionalOffset.topLeft,
              //               end: FractionalOffset.bottomRight),
              //           borderRadius: BorderRadius.circular(40)),
              //       padding: const EdgeInsets.all(10),
              //       child: Icon(
              //         Icons.send,
              //         color: primary,
              //       )),
              // ),
              WidgetAnimator(
                Container(
                  alignment: Alignment.bottomCenter,
                  width: MediaQuery
                      .of(context)
                      .size
                      .width,
                  child: Card(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 1),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(40)),
                        gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[primary, primary]),
                      ),
                      child: Row(
                        children: [
                          // const SizedBox(width: 16,),
                          // CircleAvatar(
                          //     backgroundColor: ascent,
                          //     child: ClipRRect(
                          //       borderRadius: BorderRadius.all(Radius.circular(50)),
                          //       child: widget.pic == null
                          //           ? Image.network(
                          //         "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                          //         width: 40,
                          //         height: 40,
                          //       )
                          //           : CachedNetworkImage(
                          //         imageUrl: widget.pic,
                          //         imageBuilder: (context, imageProvider) =>
                          //             Container(
                          //               height: 100,
                          //               width: 100,
                          //               decoration: BoxDecoration(
                          //                 color: Colors.black,
                          //                 image: DecorationImage(
                          //                   image: imageProvider,
                          //                   fit: BoxFit.cover,
                          //                 ),
                          //               ),
                          //             ),
                          //         placeholder: (context, url) => Center(
                          //             child: SpinKitCircle(
                          //               color: primary,
                          //               size: 10,
                          //             )),
                          //         errorWidget: (context, url, error) =>
                          //             Icon(Icons.error),
                          //       ),
                          //     )),
                          const SizedBox(width: 14,),
                          Expanded(
                              child: AutoSizeTextField(
                                textCapitalization: TextCapitalization.sentences,
                                inputFormatters: <TextInputFormatter>[
                                  UpperCaseTextFormatter()
                                ],
                                maxLines: null,
                                onTap: (){
                                  //_controller.jumpTo(_controller.position.maxScrollExtent);
                                },
                                style: const TextStyle(color: ascent,fontFamily: Poppins,),
                                cursorColor: ascent,
                                controller: comment,
                                //style: simpleTextStyle(),
                                decoration: const InputDecoration(
                                    fillColor: ascent,
                                    hintText: "Add Reply here ...",
                                    hintStyle: TextStyle(
                                      color: ascent,
                                      fontFamily: Poppins,
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none
                                ),
                              )),
                          const SizedBox(width: 16,),
                          GestureDetector(
                            onTap: () {
                              createCommentReply(widget.commentId,widget.userId);
                            },
                            child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [
                                          ascent,
                                          ascent
                                        ],
                                        begin: FractionalOffset.topLeft,
                                        end: FractionalOffset.bottomRight
                                    ),
                                    borderRadius: BorderRadius.circular(40)
                                ),
                                padding: const EdgeInsets.only(left:4),
                                child: Center(child: Icon(Icons.send,color: primary,))
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
