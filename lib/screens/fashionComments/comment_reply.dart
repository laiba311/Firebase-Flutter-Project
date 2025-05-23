import 'dart:convert';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/screens/chats-screens/message_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/giphy_picker.dart';
import 'package:http/http.dart' as https;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../animations/bottom_animation.dart';
import '../../../utils/constants.dart';

class CommentReplyScreen extends StatefulWidget {
  final String commentId;
  final String userId;
  final String userPic;
  final String commentName;
  final String fashionId;
  const CommentReplyScreen({Key? key, required this.commentId,required this.userId,required this.userPic, required this.commentName, required this.fashionId})
      : super(key: key);

  @override
  State<CommentReplyScreen> createState() => _CommentReplyScreenState();
}

class _CommentReplyScreenState extends State<CommentReplyScreen> {
  List<dynamic> replyComments = [];
  List<dynamic> myReplyComments = [];
  bool loading = false;
  bool isFilterOn=false;
  bool loading1=false;
  GiphyGif? _gif;
  String id='';
  String token="";
  TextEditingController editController=TextEditingController();
  TextEditingController comment=TextEditingController();
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    debugPrint("comment id of fashion is ${widget.commentId}");
    getCashedData();
  }
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }
  getCashedData() async {
    print("post id ${widget.fashionId}");
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    print("token=========>$token");
    getCommentsReply();
  }
  getCommentsReply() async {
    setState(() {
      loading = true;
      replyComments.clear();
    });
    https.get(Uri.parse("$serverUrl/fashionReplyComments/${widget.commentId}/"),
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
  editComment(fashionCommentId,fashionId) async {
    setState(() {
      loading1 = true;
    });
    try {
      if (editController.text == ""&& _gif==null) {
        setState(() {
          loading1 = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text(
              "FashionTime",
              style: TextStyle(
                  color: ascent,
                  fontFamily: Poppins,
                  fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Please fill all the fields",
              style: TextStyle(color: ascent, fontFamily: Poppins),
            ),
            actions: [
              TextButton(
                child: const Text("Okay",
                    style: TextStyle(color: ascent, fontFamily: Poppins)),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      } else if(_gif!=null) {
        setState(() {
          loading1 = true;
        });
        Map<String, dynamic> body = {
          "comment": _gif?.images.original?.url.toString(),
          "fashion": int.parse(fashionCommentId),
          "user": id
        };
        https.patch(Uri.parse("$serverUrl/fashionComments/$fashionCommentId/"),
            body: json.encode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            }).then((value) {
          print("Response ==> ${value.body}");
          setState(() {
            loading1 = false;
            replyComments.clear();
          });
          getCommentsReply();
        }).catchError((error) {
          setState(() {
            loading1 = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: primary,
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                error.toString(),
                style: const TextStyle(color: ascent, fontFamily: Poppins),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins)),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            ),
          );
        });
      }
      else{
        setState(() {
          loading1 = true;
        });
        Map<String, dynamic> body = {
          "comment": editController.text,
          "fashion": fashionId,
          "user": id
        };
        https.patch(Uri.parse("$serverUrl/fashionReplyComments/$fashionCommentId/"),
            body: json.encode(body),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            }).then((value) {
          print("Response ==> ${value.body}");
          setState(() {
            loading1 = false;
            myReplyComments.clear();
            replyComments.clear();
          });
          getMyCommentsReply(widget.userId);
          getCommentsReply();
        }).catchError((error) {
          setState(() {
            loading1 = false;
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: primary,
              title: const Text(
                "FashionTime",
                style: TextStyle(
                    color: ascent,
                    fontFamily: Poppins,
                    fontWeight: FontWeight.bold),
              ),
              content: Text(
                error.toString(),
                style: const TextStyle(color: ascent, fontFamily: Poppins),
              ),
              actions: [
                TextButton(
                  child: const Text("Okay",
                      style:
                      TextStyle(color: ascent, fontFamily: Poppins)),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        loading1 = false;
      });
      print(e);
    }
  }
  deleteComment(commentId)async{
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primary,
        title: const Text(
          "FashionTime",
          style: TextStyle(
              color: ascent,
              fontFamily: Poppins,
              fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete your comment?",
          style: TextStyle(color: ascent, fontFamily: Poppins),
        ),
        actions: [
          TextButton(
            child: const Text("yes",
                style: TextStyle(color: ascent, fontFamily: Poppins)),
            onPressed: () {
              setState(() {
                try{
                  https.delete(Uri.parse("$serverUrl/fashionComments/$commentId/")
                  ).then((value) {
                    debugPrint("response====>${value.statusCode}");
                    debugPrint("comment id is==========>$commentId");
                    if(value.statusCode==204){
                      debugPrint("comment id is==========>$commentId");
                      Fluttertoast.showToast(msg: "comment deleted",backgroundColor: primary);
                      Navigator.pop(context);
                      replyComments.clear();
                      getCommentsReply();
                      myReplyComments.clear();
                      getMyCommentsReply(widget.userId);

                    }
                  });
                }catch(e){
                  Fluttertoast.showToast(msg: "error received",backgroundColor: Colors.red);
                }

              });
            },
          ), TextButton(
            child: const Text("no",
                style: TextStyle(color: ascent, fontFamily: Poppins)),
            onPressed: () {
              setState(() {
                Navigator.pop(context);
              });
            },
          ),
        ],
      ),
    );
  }
  getMyCommentsReply(id) async {
    setState(() {
      loading = true;
      replyComments.clear();
    });
    try {
      var response = await https.get(
        Uri.parse("$serverUrl/fashionReplyComments/${widget.commentId}/"),
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
  createCommentReply(commentId,userId) async {
    try{
      if (comment.text == ""&& _gif==null) {
        setState(() {
          loading1 = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: primary,
            title: const Text(
              "FashionTime",
              style: TextStyle(
                  color: ascent,
                  fontFamily: Poppins,
                  fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Please fill all the fields",
              style: TextStyle(color: ascent, fontFamily: Poppins),
            ),
            actions: [
              TextButton(
                child: const Text("Okay",
                    style: TextStyle(color: ascent, fontFamily: Poppins)),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      }
      else if(_gif!=null){
        setState(() {
          loading1=true;
        });
        Map<String, dynamic> body = {
          "comment": _gif?.images.original?.url.toString(),
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
      else{
        setState(() {
          loading1=true;
        });
        Map<String, dynamic> body = {
          "comment": comment.text.toString(),
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

    }
    catch(e){
      debugPrint("");
    }
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
          style: TextStyle(fontFamily: Poppins),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:  [
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
                label: const Text("Filter my comments",
                    style: TextStyle(fontFamily: Poppins)),
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
          const SizedBox(
            height: 20,
          ),
          loading==true?
          SpinKitCircle(
            color: primary,
            size: 50,
          ):
              replyComments.isEmpty?
                  myReplyComments.isNotEmpty?
                  Expanded(
                    child: (AnimationLimiter(
                      child: ListView.builder(
                          itemCount: myReplyComments.length,
                          itemBuilder: (context,index) {
                            return AnimationConfiguration.staggeredList(position: index,duration: const Duration(milliseconds: 600),delay: const Duration(milliseconds: 300), child:SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child:
                                GestureDetector(
                                  onLongPress: () {
                                    deleteComment(myReplyComments[index]['id']);

                                  },
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
                                    title: Text(myReplyComments[index]["user"]["username"],style: const TextStyle(fontFamily: Poppins,fontWeight: FontWeight.w400)),
                                    subtitle: myReplyComments[index]['comment'].toString().startsWith('https://media')?Flexible(child: buildGifWidget(context, replyComments[index]['comment'].toString())):Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    backgroundColor: primary,
                                                    title: Row(
                                                      children: [
                                                        Flexible(
                                                          child: CircleAvatar(
                                                              backgroundColor: Colors.black,
                                                              child: ClipRRect(
                                                                borderRadius: const BorderRadius.all(
                                                                    Radius.circular(50)),
                                                                child: myReplyComments[index]["user"]
                                                                ["pic"] ==
                                                                    null
                                                                    ? Image.network(
                                                                  "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                  width: 40,
                                                                  height: 40,
                                                                )
                                                                    : CachedNetworkImage(
                                                                  imageUrl:
                                                                  myReplyComments[index]
                                                                  ["user"]["pic"],
                                                                  imageBuilder: (context,
                                                                      imageProvider) =>
                                                                      Container(
                                                                        height: 100,
                                                                        width: 100,
                                                                        decoration:
                                                                        BoxDecoration(
                                                                          image:
                                                                          DecorationImage(
                                                                            image:
                                                                            imageProvider,
                                                                            fit: BoxFit.cover,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                  placeholder: (context,
                                                                      url) =>
                                                                      Center(
                                                                          child:
                                                                          SpinKitCircle(
                                                                            color: primary,
                                                                            size: 10,
                                                                          )),
                                                                  errorWidget: (context,
                                                                      url, error) =>
                                                                      ClipRRect(
                                                                        borderRadius:
                                                                        const BorderRadius.all(
                                                                            Radius
                                                                                .circular(
                                                                                50)),
                                                                        child: Image.network(
                                                                          "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                          width: 40,
                                                                          height: 40,
                                                                        ),
                                                                      ),
                                                                ),
                                                              )),
                                                        ),
                                                        const SizedBox(width: 4,),
                                                        const Flexible(
                                                          child: Text(
                                                              'Edit to this comment.', style: TextStyle(
                                                              fontFamily: Poppins)),
                                                        ),
                                                      ],
                                                    ),
                                                    content:
                                                    AutoSizeTextField(
                                                      onChanged:
                                                          (value) {
                                                        setState(() {});
                                                      },
                                                      controller:
                                                      editController,
                                                      decoration:
                                                      const InputDecoration(
                                                          hintText:
                                                          "Write comment here.",labelStyle: TextStyle(fontFamily:  Poppins)),
                                                      cursorColor: primary,
                                                      maxLength: 2500,
                                                    ),
                                                    actions: <Widget>[
                                                      MaterialButton(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(30), // Adjust the radius as needed
                                                        ),
                                                        color: ascent,
                                                        textColor:
                                                        ascent,

                                                        child:  Icon(
                                                            Icons.send,

                                                            color:
                                                            primary),
                                                        onPressed: () {
                                                          setState(() {
                                                            print(
                                                                "comment content${ myReplyComments[index]
                                                                [
                                                                'comment_id']['id']}${widget.fashionId}");
                                                            Navigator.pop(
                                                                context);
                                                            editComment(
                                                                myReplyComments[index]
                                                                [
                                                                'id'],widget.fashionId);
                                                            editController
                                                                .clear();
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                });
                                          },
                                          child: Text(
                                            "edit",
                                            style: TextStyle(
                                                fontFamily:
                                                Poppins,
                                                fontWeight:
                                                FontWeight.w400,
                                                color: primary,
                                                decoration:
                                                TextDecoration
                                                    .underline),
                                          ),
                                        ),
                                        myReplyComments[index]['created']!=myReplyComments[index]['updated']?
                                        Flexible(child: Text(handleEmojis(myReplyComments[index]["comment"]+"(edited)"),style: const TextStyle(fontFamily: Poppins),)):
                                        Flexible(child: Text(handleEmojis(myReplyComments[index]["comment"]),style: const TextStyle(fontFamily: Poppins),)),
                                      ],
                                    ),
                                    trailing: Text(DateFormat.jm().format(DateTime.parse(myReplyComments[index]["created"]).toLocal())),
                                  ),
                                ) ,
                              ),
                            ) );
                          }
                      ),
                    )),
                  ):
                  Text("No Comments.",style: TextStyle(fontFamily: Poppins,fontWeight: FontWeight.w400) ,):
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
                              child: GestureDetector(
                                onLongPress: () {
                                  // editComment(replyComments[index]['id'],widget.fashionId );
                                  deleteComment(replyComments[index]['id']);

                                },
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
                                  subtitle: SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2,),
                                        replyComments[index]['comment'].toString().startsWith('https://media')?Flexible(child: buildGifWidget(context, replyComments[index]['comment'].toString())):
                                        const SizedBox(height: 2,),
                                        replyComments[index]['created']!=replyComments[index]['updated']?
                                        Flexible(child: Text(handleEmojis(replyComments[index]["comment"]+" (edited)"),style: const TextStyle(fontFamily: Poppins),)):
                                        Flexible(child: Text(handleEmojis(replyComments[index]["comment"]),style: const TextStyle(fontFamily: Poppins),)),
                                        const SizedBox(height: 2,),
                                        Row(
                                          children: [
                                            Text(handleEmojis(widget.commentName),style:  TextStyle(fontFamily: Poppins,fontWeight: FontWeight.w900,color: primary),),
                                            const SizedBox(width: 2,),
                                            GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        backgroundColor: primary,
                                                        title: Row(
                                                          children: [
                                                            Flexible(
                                                              child: CircleAvatar(
                                                                  backgroundColor: Colors.black,
                                                                  child: ClipRRect(
                                                                    borderRadius: const BorderRadius.all(
                                                                        Radius.circular(50)),
                                                                    child: replyComments[index]["user"]
                                                                    ["pic"] ==
                                                                        null
                                                                        ? Image.network(
                                                                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                      width: 40,
                                                                      height: 40,
                                                                    )
                                                                        : CachedNetworkImage(
                                                                      imageUrl:
                                                                      replyComments[index]
                                                                      ["user"]["pic"],
                                                                      imageBuilder: (context,
                                                                          imageProvider) =>
                                                                          Container(
                                                                            height: 100,
                                                                            width: 100,
                                                                            decoration:
                                                                            BoxDecoration(
                                                                              image:
                                                                              DecorationImage(
                                                                                image:
                                                                                imageProvider,
                                                                                fit: BoxFit.cover,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                      placeholder: (context,
                                                                          url) =>
                                                                          Center(
                                                                              child:
                                                                              SpinKitCircle(
                                                                                color: primary,
                                                                                size: 10,
                                                                              )),
                                                                      errorWidget: (context,
                                                                          url, error) =>
                                                                          ClipRRect(
                                                                            borderRadius:
                                                                            const BorderRadius.all(
                                                                                Radius
                                                                                    .circular(
                                                                                    50)),
                                                                            child: Image.network(
                                                                              "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                                              width: 40,
                                                                              height: 40,
                                                                            ),
                                                                          ),
                                                                    ),
                                                                  )),
                                                            ),
                                                            const SizedBox(width: 4,),
                                                            const Flexible(
                                                              child: Text(
                                                                  'Edit to this comment.', style: TextStyle(
                                                                  fontFamily: Poppins)),
                                                            ),
                                                          ],
                                                        ),
                                                        content:
                                                        AutoSizeTextField(
                                                          onChanged:
                                                              (value) {
                                                            setState(() {});
                                                          },
                                                          controller:
                                                          editController,
                                                          decoration:
                                                          const InputDecoration(
                                                              hintText:
                                                              "Write comment here.",labelStyle: TextStyle(fontFamily:  Poppins)),
                                                          cursorColor: primary,
                                                          maxLength: 2500,
                                                        ),
                                                        actions: <Widget>[
                                                          MaterialButton(
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(30), // Adjust the radius as needed
                                                            ),
                                                            color: ascent,
                                                            textColor:
                                                            ascent,

                                                            child:  Icon(
                                                                Icons.send,

                                                                color:
                                                                primary),
                                                            onPressed: () {
                                                              setState(() {
                                                                print(
                                                                    "comment content${ replyComments[index]
                                                                    [
                                                                    'comment_id']['id']}${widget.fashionId}");
                                                                Navigator.pop(
                                                                    context);
                                                                editComment(
                                                                    replyComments[index]
                                                                    [
                                                                    'id'],widget.fashionId);
                                                                editController
                                                                    .clear();
                                                              });
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    });
                                              },
                                              child: Text(
                                                "edit",
                                                style: TextStyle(
                                                    fontFamily:
                                                    Poppins,
                                                    fontWeight:
                                                    FontWeight.w400,
                                                    color: primary,
                                                    decoration:
                                                    TextDecoration
                                                        .underline),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                //  trailing: Text(DateFormat.jm().format(DateTime.parse(replyComments[index]["created"]).toLocal())),
                                ),
                              ),
                            ) ,
                          ),
                         ) );
                        }
                  ),
                ),
              )),
        ],
      ),
      bottomNavigationBar: WidgetAnimator(
        Container(
          height: 200,
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
                        style: const TextStyle(color: ascent,fontFamily: Poppins),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12,right: 16),
                    child: IconButton(
                      icon: const Icon(Icons.gif,size: 40),
                      onPressed: ()async {
                        final gif = await GiphyPicker.pickGif(
                          draggableController: _draggableController,
                          context: context,
                          apiKey: giphyKey,
                        );
                        if (gif != null) {
                          setState(() {
                            _gif = gif;
                            debugPrint("gif link==========>${_gif?.images.original?.url}");

                          });
                          // ignore: use_build_context_synchronously
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: primary,
                                title: const Text('GIF Selected'),
                                content: _gif?.images.original?.url != null
                                    ? Image(image: NetworkImage(_gif!.images.original!.url!))
                                    : const Text('No GIF URL available'),
                                actions: <Widget>[
                                  IconButton(icon: const Icon(Icons.send), onPressed: () {  createCommentReply(widget.commentId,widget.userId);
                                  Navigator.of(context).pop();},),
                                ],
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
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
                  )
                  ,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
Widget buildGifWidget(BuildContext context,String gifUrl) {
  debugPrint("gif link after sending msg========>$gifUrl");
  return Stack(
    alignment: Alignment.center,
    children: [
      Image.network(gifUrl),
      FutureBuilder(
        future: precacheImage(NetworkImage(gifUrl), context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(color: primary);
          } else {
            return const SizedBox.shrink(); // Empty container when image is loaded
          }
        },
      ),
    ],
  );
}
