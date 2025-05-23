import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:finalfashiontimefrontend/models/saved_post_model.dart';
import 'package:finalfashiontimefrontend/screens/fashionComments/comment_screen.dart';
import 'package:finalfashiontimefrontend/screens/posts-screens/post_like_user.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:finalfashiontimefrontend/screens/profiles/myProfile.dart';
import 'package:finalfashiontimefrontend/screens/search-screens/search_by_hashtag.dart';
import 'package:finalfashiontimefrontend/screens/settings-pages/report_screen.dart';
import 'package:finalfashiontimefrontend/utils/constants.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;

import '../../customize_pacages/mentions/src/mention_text_field.dart';

class PostScrollToNext extends StatefulWidget {
  final String title;
  late List<SavedPostModel>? posts;
  final int index;
  final int myIndex;
  final Function navigateTo;
  PostScrollToNext({super.key, required this.title,this.posts, required this.index, required this.myIndex, required this.navigateTo});

  @override
  State<PostScrollToNext> createState() => _PostScrollToNextState();
}

class _PostScrollToNextState extends State<PostScrollToNext> {
  String id = "";
  String name = "";
  String token = "";
  TextEditingController description = TextEditingController();
  bool updateBool = false;
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();
  Stream? chatRooms;
  bool isExpanded = true;
  double? _previousExtent;

  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    name = preferences.getString("name")!;
    print(id);
    // setState(() {
    //   widget.posts = widget.posts!.where((e) => e.userid == widget.posts![widget.index].userid).toList();
    // });
  }

  updatePost(postId) {
    setState(() {
      updateBool = true;
    });
    https
        .patch(Uri.parse("$serverUrl/fashionUpload/$postId/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({"description": description.text}))
        .then((value) {
      print(value.body.toString());
      setState(() {
        updateBool = false;
      });
      Navigator.pop(context);
      // getPosts(paginationPost);
    });
  }
  void _showFriendsList(imageLink,postId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StreamBuilder(
          stream: chatRooms,
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(), // Use your loading indicator
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"), // Handle error
              );
            }
            else if (snapshot.data == null) { // Add null check here
              return const Center(
                child: Text("No data available",style: TextStyle(fontFamily: Poppins),), // Or display an appropriate message
              );
            }
            else {
              final chatData = snapshot.data.docs;

              return  ListView.builder(
                itemCount: ( chatData.length).toInt(),
                itemBuilder: (context, index) {

                  // Render individual chat tile
                  final individualChatIndex = index ;
                  final chat = chatData[individualChatIndex].data();
                  return ChatRoomsTile(
                    name: name,
                    chatRoomId: chat["chatRoomId"],
                    userData: chat["userData"],
                    friendData: chat["friendData"],
                    isBlocked: chat["isBlock"],
                    postId: postId,
                    share: imageLink,
                  );
                }
                ,
              ) ;
            }
          },
        );
      },
    );
  }
  String handleEmojis(String text) {
    List<int> bytes = text.toString().codeUnits;
    return utf8.decode(bytes);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
        //             ])),
        //   ),
        //   backgroundColor: ascent,
        //   title: Text(
        //     widget.title,
        //     style: const TextStyle(fontFamily: Poppins),
        //   ),
        // ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                  itemCount: widget.posts!.length,
                  itemBuilder: (context,index){
                    return Card(
                      elevation: 10,
                      color: Colors.transparent,
                      child: Column(
                        children: [
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
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 10.0,
                                  right: 10,
                                  top: 5,
                                  bottom: 5),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      widget.posts![index].userName == name
                                          ? Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  MyProfileScreen(
                                                    id: widget.posts![
                                                    index]
                                                        .userid,
                                                    username: widget.posts![
                                                    index]
                                                        .userName,
                                                  )))
                                          : Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FriendProfileScreen(
                                                    id: widget.posts![
                                                    index]
                                                        .userid,
                                                    username: widget.posts![
                                                    index]
                                                        .userName,
                                                  )));
                                    },
                                    child: Padding(
                                      padding:
                                      const EdgeInsets.all(4.0),
                                      child: SizedBox(
                                        width: 150,
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            CircleAvatar(
                                                backgroundColor:
                                                dark1,
                                                child: ClipRRect(
                                                  borderRadius:
                                                  const BorderRadius
                                                      .all(
                                                      Radius
                                                          .circular(
                                                          50)),
                                                  child: widget.posts![index]
                                                      .userPic ==
                                                      null
                                                      ? Image.network(
                                                    "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                    width: 40,
                                                    height: 40,
                                                  )
                                                      : CachedNetworkImage(
                                                    imageUrl: widget.posts![
                                                    index]
                                                        .userPic,
                                                    imageBuilder:
                                                        (context,
                                                        imageProvider) =>
                                                        Container(
                                                          height: MediaQuery.of(context)
                                                              .size
                                                              .height *
                                                              0.7,
                                                          width: MediaQuery.of(
                                                              context)
                                                              .size
                                                              .width,
                                                          decoration:
                                                          BoxDecoration(
                                                            image:
                                                            DecorationImage(
                                                              image:
                                                              imageProvider,
                                                              fit: BoxFit
                                                                  .cover,
                                                            ),
                                                          ),
                                                        ),
                                                    placeholder: (context,
                                                        url) =>
                                                        Center(
                                                            child:
                                                            SpinKitCircle(
                                                              color:
                                                              primary,
                                                              size: 10,
                                                            )),
                                                    errorWidget: (context,
                                                        url,
                                                        error) =>
                                                        ClipRRect(
                                                            borderRadius:
                                                            const BorderRadius.all(Radius.circular(50)),
                                                            child: Image.network(
                                                              "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                              width: 40,
                                                              height: 40,
                                                            )),
                                                  ),
                                                )),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              widget.posts![index].userName,
                                              style: const TextStyle(
                                                  fontFamily:
                                                  Poppins,
                                                  color: ascent,
                                                  fontWeight:
                                                  FontWeight
                                                      .bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton(
                                      icon: const Icon(
                                        Icons.more_horiz,
                                        color: ascent,
                                      ),
                                      onSelected: (value) {
                                        if (value == 0) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ReportScreen(
                                                          reportedID:
                                                          widget.posts![index]
                                                              .userid)));
                                        }
                                        if (value == 1) {
                                          description.text =
                                              widget.posts![index]
                                                  .description;
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                StatefulBuilder(
                                                    builder: (context,
                                                        setState) {
                                                      updateBool = false;
                                                      return AlertDialog(
                                                        backgroundColor:
                                                        primary,
                                                        title: const Text(
                                                          "Edit Description",
                                                          style: TextStyle(
                                                              color: ascent,
                                                              fontFamily:
                                                              Poppins,
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold),
                                                        ),
                                                        content: SizedBox(
                                                          width:
                                                          MediaQuery.of(
                                                              context)
                                                              .size
                                                              .width,
                                                          child: TextField(
                                                            maxLines: 5,
                                                            controller:
                                                            description,
                                                            style: const TextStyle(
                                                                color: ascent,
                                                                fontFamily:
                                                                Poppins),
                                                            decoration:
                                                            const InputDecoration(
                                                                hintStyle: TextStyle(
                                                                    color:
                                                                    ascent,
                                                                    fontSize:
                                                                    17,
                                                                    fontWeight: FontWeight
                                                                        .w400,
                                                                    fontFamily:
                                                                    Poppins),
                                                                enabledBorder:
                                                                UnderlineInputBorder(
                                                                  borderSide:
                                                                  BorderSide(color: ascent),
                                                                ),
                                                                focusedBorder:
                                                                UnderlineInputBorder(
                                                                  borderSide:
                                                                  BorderSide(color: ascent),
                                                                ),
                                                                //enabledBorder: InputBorder.none,
                                                                errorBorder:
                                                                InputBorder
                                                                    .none,
                                                                //disabledBorder: InputBorder.none,
                                                                alignLabelWithHint:
                                                                true,
                                                                hintText:
                                                                "Description "),
                                                            cursorColor:
                                                            Colors.pink,
                                                          ),
                                                        ),
                                                        actions: [
                                                          updateBool == true
                                                              ? const SpinKitCircle(
                                                            color:
                                                            ascent,
                                                            size: 20,
                                                          )
                                                              : TextButton(
                                                            child: const Text(
                                                                "Save",
                                                                style: TextStyle(
                                                                    color:
                                                                    ascent,
                                                                    fontFamily:
                                                                    Poppins)),
                                                            onPressed:
                                                                () {
                                                              setState(
                                                                      () {
                                                                    updateBool =
                                                                    true;
                                                                  });
                                                              updatePost(
                                                                  widget.posts![index]
                                                                      .id);
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    }),
                                          );
                                        }
                                        // if (value == 2) {
                                        //   saveStyle(widget.posts![index].id);
                                        // }
                                        print(value);
                                        //Navigator.pushNamed(context, value.toString());
                                      },
                                      itemBuilder: (BuildContext bc) {
                                        return [
                                          PopupMenuItem(
                                            value: 0,
                                            child: Row(
                                              children: [
                                                Icon(Icons.report),
                                                SizedBox(
                                                  width: 10,
                                                ),
                                                Text(
                                                  "Report",
                                                  style: TextStyle(
                                                      fontFamily:
                                                      Poppins),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (widget.posts![index].userid ==
                                              id)
                                            PopupMenuItem(
                                              value: 1,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    "Edit Description",
                                                    style: TextStyle(
                                                        fontFamily:
                                                        Poppins),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          // if (posts[index].userid !=
                                          //     id)
                                          //   PopupMenuItem(
                                          //     value: 2,
                                          //     child: Row(
                                          //       children: const [
                                          //         Icon(Icons.save),
                                          //         SizedBox(
                                          //           width: 10,
                                          //         ),
                                          //         Text(
                                          //           "Save Post",
                                          //           style: TextStyle(
                                          //               fontFamily:
                                          //                   Poppins),
                                          //         ),
                                          //       ],
                                          //     ),
                                          //   ),
                                        ];
                                      })
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
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
                                },
                                child: InteractiveViewer(
                                  panEnabled: true,
                                  minScale: 1,
                                  maxScale: 3,
                                  child: SizedBox(
                                    height: 450,
                                    width: MediaQuery.of(context)
                                        .size
                                        .width *
                                        0.97,
                                    child: CarouselSlider(
                                      carouselController: _controller,
                                      options: CarouselOptions(
                                          enableInfiniteScroll: false,
                                          height: 450.0,
                                          autoPlay: false,
                                          enlargeCenterPage: true,
                                          viewportFraction: 0.99,
                                          aspectRatio: 2.0,
                                          initialPage: 0,
                                          onPageChanged:
                                              (ind, reason) {
                                            setState(() {
                                              _current = ind;
                                            });
                                          }),
                                      items: widget.posts![index]
                                          .images
                                          .map((i) {
                                        return i["type"] == "video"
                                            ? Container(
                                            color: Colors.black,
                                            child:Text("Video"))
                                            // UsingVideoControllerExample(
                                            //   path: i["video"],
                                            // ))
                                            : InteractiveViewer(
                                          panEnabled: true,
                                          minScale: 1,
                                          maxScale: 3,
                                          child: Builder(
                                            builder:
                                                (BuildContext
                                            context) {
                                              return CachedNetworkImage(
                                                imageUrl:
                                                i["image"],
                                                imageBuilder:
                                                    (context,
                                                    imageProvider) =>
                                                    Container(
                                                      height: MediaQuery.of(
                                                          context)
                                                          .size
                                                          .height,
                                                      width: MediaQuery.of(
                                                          context)
                                                          .size
                                                          .width,
                                                      decoration:
                                                      BoxDecoration(
                                                        image:
                                                        DecorationImage(
                                                          image:
                                                          imageProvider,
                                                          fit: BoxFit
                                                              .cover,
                                                        ),
                                                      ),
                                                    ),
                                                placeholder: (context,
                                                    url) =>
                                                    SpinKitCircle(
                                                      color:
                                                      primary,
                                                      size: 60,
                                                    ),
                                                errorWidget: (context,
                                                    url,
                                                    error) =>
                                                    Container(
                                                      height: MediaQuery.of(
                                                          context)
                                                          .size
                                                          .height *
                                                          0.9,
                                                      width: MediaQuery.of(
                                                          context)
                                                          .size
                                                          .width,
                                                      decoration:
                                                      BoxDecoration(
                                                        image: DecorationImage(
                                                            image: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png")
                                                                .image,
                                                            fit: BoxFit
                                                                .fill),
                                                      ),
                                                    ),
                                              );
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          widget.posts![index].images.length == 1
                              ? const SizedBox()
                              : Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: widget.posts![index]
                                .images
                                .asMap()
                                .entries
                                .map((entry) {
                              return GestureDetector(
                                onTap: () => _controller
                                    .animateToPage(entry.key),
                                child: Container(
                                  width: 12.0,
                                  height: 12.0,
                                  margin: const EdgeInsets
                                      .symmetric(
                                      vertical: 8.0,
                                      horizontal: 4.0),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (Theme.of(context)
                                          .brightness ==
                                          Brightness
                                              .dark
                                          ? Colors.white
                                          : Colors.black)
                                          .withOpacity(
                                          _current ==
                                              entry.key
                                              ? 0.9
                                              : 0.4)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                              padding: const EdgeInsets.only(
                                  left: 0.0, right: 0.0),
                              child: widget.posts![index].userid == id
                                  ? Row(
                                children: [
                                  widget.posts![index].addMeInFashionWeek ==
                                      true
                                      ? widget.posts![index].mylike !=
                                      "like"
                                      ? IconButton(
                                      onPressed: () {},
                                      icon: const Icon(
                                        Icons.favorite,
                                        size: 20,

                                      ))
                                      : IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                  PostLikeUserScreen(fashionId: widget.posts![index].id),
                                            ));
                                      },
                                      icon: const Icon(
                                        FontAwesomeIcons
                                            .heart,
                                        color: Colors.red,
                                        size: 20,
                                      ))
                                      : widget.posts![index].mylike !=
                                      "like"
                                      ? GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                  PostLikeUserScreen(fashionId: widget.posts![index].id),
                                            ));
                                      },
                                      child: const Icon(
                                        Icons.star,
                                        color: Colors
                                            .orange,
                                        size: 24,
                                      ))
                                      : GestureDetector(
                                    onDoubleTap:
                                        () {},
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                PostLikeUserScreen(fashionId: widget.posts![index].id),
                                          ));
                                    },
                                    child:
                                    Padding(
                                      padding:
                                      EdgeInsets
                                          .all(
                                          8.0),
                                      child: Icon(
                                          Icons
                                              .star_border_outlined,
                                          size: 24,
                                          color: Colors
                                              .orange),
                                    ),
                                  )
                                  ,
                                  widget.posts![index].likeCount == "0"
                                      ?
                                  const SizedBox()
                                      : Text(widget.posts![index]
                                      .likeCount),
                                  IconButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.only(
                                                    topLeft: Radius.circular(10),
                                                    topRight: Radius.circular(10)
                                                )
                                            ),
                                            isScrollControlled: true,
                                            context: context,
                                            builder: (ctx) {
                                              return WillPopScope(
                                                onWillPop: () async {
                                                  print("Closed 3");
                                                  if(overlayEntry != null) {
                                                    showSuggestions = ValueNotifier(false);
                                                    overlayEntry!.remove();
                                                    overlayEntry = null;
                                                  }else{
                                                    Navigator.pop(ctx);
                                                  }
                                                  return false; // Prevents the default back button behavior
                                                },
                                                child: NotificationListener<DraggableScrollableNotification>(
                                                  onNotification: (notification) {
                                                    print("listener called");
                                                    // Detect ANY movement (no threshold)
                                                    if (_previousExtent != notification.extent && keyBoardOpen == true) {
                                                      print("Sheet is being dragged (${notification.extent})");
                                                      print("bool => ${keyBoardOpen}");
                                                      focusNode1.unfocus();
                                                      //Navigator.pop(ctx);
                                                      _previousExtent = notification.extent;
                                                    }
                                                    return false;
                                                  },
                                                  child: DraggableScrollableSheet(
                                                      expand: false, // Ensures it doesn't expand fully by default
                                                      initialChildSize: 0.7, // Half screen by default
                                                      minChildSize: 0.3, // Minimum height
                                                      maxChildSize: 1.0,
                                                      builder: (BuildContext context, ScrollController scrollController) {
                                                        return CommentScreen(
                                                          postid: widget.posts![index].id,
                                                          pic: widget.posts![index].userPic,
                                                          scrollController: scrollController,
                                                            isEventPost: widget.posts![index].addMeInFashionWeek!,
                                                            userID: widget.posts![index].userid
                                                        );
                                                      }
                                                  ),
                                                ),
                                              );
                                            });
                                        // Navigator.push(
                                        //     context,
                                        //     MaterialPageRoute(
                                        //         builder: (context) => CommentScreen(
                                        //             id: posts[index]
                                        //                 .id,
                                        //             pic: posts[index]
                                        //                 .userPic)));
                                      },
                                      icon: const Icon(
                                        FontAwesomeIcons
                                            .comment,
                                        size: 20,
                                      )),
                                  IconButton(
                                      onPressed: () async {

                                        showModalBottomSheet(
                                            context: context,
                                            builder: (BuildContext bc) {
                                              return Wrap(
                                                children: <Widget>[
                                                  ListTile(
                                                    leading:  SizedBox(
                                                        width: 28,
                                                        height:28 ,
                                                        child: Image.asset("assets/shareIcon.png",)),
                                                    title: const Text(
                                                      'Share with friends',
                                                      style: TextStyle(fontFamily: Poppins),
                                                    ),
                                                    onTap: () {
                                                      String imageUrl = widget.posts![index].images[0]['image']==null?widget.posts![index].images[0]['video'].toString():widget.posts![index].images[0]['image'].toString();
                                                      Navigator.pop(context);
                                                      _showFriendsList(imageUrl,widget.posts![index].id);

                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(Icons.share),
                                                    title: const Text(
                                                      'Others',
                                                      style: TextStyle(fontFamily: Poppins),
                                                    ),
                                                    onTap: () async{
                                                      String imageUrl = widget.posts![index].images[0]['image']==null?widget.posts![index].images[0]['video'].toString():widget.posts![index].images[0]['image'].toString();
                                                      debugPrint("image link to share: $imageUrl");
                                                      await Share.share("${widget.posts![index].description.toString()}\n\n https://fashiontime-28e3a.web.app/details/${widget.posts![index].id}"
                                                      );
                                                    },
                                                  ),

                                                ],
                                              );
                                            });
                                      },
                                      icon: const Icon(
                                        FontAwesomeIcons.share,
                                        size: 20,
                                      )
                                  ),
                                  const Spacer(),
                                ],
                              )
                                  : Row(
                                children: [
                                  widget.posts![index].addMeInFashionWeek ==
                                      true
                                      ? widget.posts![index].mylike !=
                                      "like"
                                      ? IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                  PostLikeUserScreen(fashionId: widget.posts![index].id),
                                            ));
                                      },
                                      icon: const Icon(
                                        Icons.favorite,
                                        size: 20,
                                        color: Colors.red,
                                      ))
                                      : IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                  PostLikeUserScreen(fashionId: widget.posts![index].id),
                                            ));
                                      },
                                      icon: const Icon(
                                        FontAwesomeIcons
                                            .heart,
                                        size: 20,
                                        color: Colors.red,
                                      ))
                                      : widget.posts![index].mylike !=
                                      "like"
                                      ? GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                  PostLikeUserScreen(fashionId: widget.posts![index].id),
                                            ));
                                      },
                                      child:
                                      Padding(
                                        padding: EdgeInsets
                                            .only(
                                            left:
                                            4),
                                        child: Icon(
                                          Icons.star,
                                          color: Colors
                                              .orange,
                                          size: 24,
                                        ),
                                      ))
                                      : GestureDetector(
                                    onDoubleTap: () {
                                      // createLike(
                                      //     widget.posts![index]
                                      //         .id);
                                    },
                                    onTap: () {
                                      debugPrint(
                                          "pressed");
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                PostLikeUserScreen(fashionId: widget.posts![index].id),
                                          ));
                                    },
                                    child:
                                    Padding(
                                      padding:
                                      EdgeInsets
                                          .all(
                                          8.0),
                                      child: Icon(
                                        Icons
                                            .star_border_outlined,
                                        color: Colors
                                            .orange,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  widget.posts![index].likeCount == "0"
                                      ?
                                  const SizedBox()
                                      :
                                  Text(widget.posts![index]
                                      .likeCount),
                                  IconButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.only(
                                                    topLeft: Radius.circular(10),
                                                    topRight: Radius.circular(10)
                                                )
                                            ),
                                            isScrollControlled: true,
                                            context: context,
                                            builder: (ctx) {
                                              return WillPopScope(
                                                onWillPop: () async {
                                                  print("Closed 3");
                                                  if(overlayEntry != null) {
                                                    showSuggestions = ValueNotifier(false);
                                                    overlayEntry!.remove();
                                                    overlayEntry = null;
                                                  }else{
                                                    Navigator.pop(ctx);
                                                  }
                                                  return false; // Prevents the default back button behavior
                                                },
                                                child: NotificationListener<DraggableScrollableNotification>(
                                                  onNotification: (notification) {
                                                    print("listener called");
                                                    // Detect ANY movement (no threshold)
                                                    if (_previousExtent != notification.extent && keyBoardOpen == true) {
                                                      print("Sheet is being dragged (${notification.extent})");
                                                      print("bool => ${keyBoardOpen}");
                                                      focusNode1.unfocus();
                                                      //Navigator.pop(ctx);
                                                      _previousExtent = notification.extent;
                                                    }
                                                    return false;
                                                  },
                                                  child: DraggableScrollableSheet(
                                                      expand: false, // Ensures it doesn't expand fully by default
                                                      initialChildSize: 0.7, // Half screen by default
                                                      minChildSize: 0.3, // Minimum height
                                                      maxChildSize: 1.0,
                                                      builder: (BuildContext context, ScrollController scrollController) {
                                                        return CommentScreen(
                                                          postid: widget.posts![index].id,
                                                          pic: widget.posts![index].userPic,
                                                          scrollController: scrollController,
                                                            isEventPost: widget.posts![index].addMeInFashionWeek!,
                                                            userID: widget.posts![index].userid
                                                        );
                                                      }
                                                  ),
                                                ),
                                              );
                                            });
                                      },
                                      icon: const Icon(
                                        FontAwesomeIcons
                                            .comment,
                                        size: 20,
                                      )),
                                  IconButton(
                                      onPressed: () async {
                                        showModalBottomSheet(
                                            context: context,
                                            builder: (BuildContext bc) {
                                              return Wrap(
                                                children: <Widget>[
                                                  ListTile(
                                                    leading: SizedBox(
                                                        width: 28,
                                                        height:28 ,
                                                        child: Image.asset("assets/shareIcon.png",)),
                                                    title: const Text(
                                                      'Share with friends',
                                                      style: TextStyle(fontFamily: Poppins),
                                                    ),
                                                    onTap: () {
                                                      String imageUrl = widget.posts![index].images[0]['image']==null?widget.posts![index].images[0]['video'].toString():widget.posts![index].images[0]['image'].toString();
                                                      Navigator.pop(context);
                                                      _showFriendsList(imageUrl,widget.posts![index].id);

                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(Icons.share),
                                                    title: const Text(
                                                      'Others',
                                                      style: TextStyle(fontFamily: Poppins),
                                                    ),
                                                    onTap: () async{
                                                      String imageUrl = widget.posts![index].images[0]['image']==null?widget.posts![index].images[0]['video'].toString():widget.posts![index].images[0]['image'].toString();
                                                      debugPrint("image link to share: $imageUrl");
                                                      await Share.share("${widget.posts![index].description.toString()}\n\n https://fashiontime-28e3a.web.app/details/${widget.posts![index].id}"
                                                      );
                                                    },
                                                  ),

                                                ],
                                              );
                                            });
                                      },
                                      icon: const Icon(
                                        FontAwesomeIcons.share,
                                        size: 20,
                                      )
                                  ),
                                  const Spacer(),
                                ],
                              )
                          ),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.start,
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                            Expanded(
                                child: Padding(
                                    padding:
                                    const EdgeInsets.all(
                                        8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        isExpanded
                                            ? Row(
                                          children: [
                                            Text(
                                              widget.posts![index]
                                                  .userName,
                                              style: const TextStyle(
                                                  fontFamily:
                                                  Poppins,
                                                  fontSize:
                                                  12,
                                                  fontWeight:
                                                  FontWeight.bold),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              "${handleEmojis(widget.posts![index].description.substring(0, 2))}...",
                                              style:
                                              const TextStyle(
                                                fontFamily:
                                                Poppins,
                                                fontSize:
                                                12,
                                              ),
                                              textAlign:
                                              TextAlign
                                                  .start,
                                            )
                                          ],
                                        )
                                            : Text(
                                            "${widget.posts![index]
                                                .userName}${handleEmojis( widget.posts![index]
                                                .description)}",
                                            style: const TextStyle(
                                                fontFamily:
                                                Poppins,
                                                fontSize:
                                                12)),
                                        TextButton(
                                            onPressed: () {
                                              setState(() {
                                                isExpanded =
                                                !isExpanded;
                                              });
                                            },
                                            child: Text(
                                                isExpanded
                                                    ? "Show More"
                                                    : "Show Less",
                                                style: TextStyle(
                                                    color: Theme.of(
                                                        context)
                                                        .primaryColor))),
                                      ],
                                    )),
                              ),
                              const SizedBox(
                                width: 10,
                              )
                            ],
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 10),
                              widget.posts![index].commentCount == "0"
                                  ?
                              const SizedBox()
                                  : GestureDetector(
                                  onTap:(){
                                    showModalBottomSheet(
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                topRight: Radius.circular(10)
                                            )
                                        ),
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (ctx) {
                                          return WillPopScope(
                                            onWillPop: () async {
                                              print("Closed 3");
                                              if(overlayEntry != null) {
                                                showSuggestions = ValueNotifier(false);
                                                overlayEntry!.remove();
                                                overlayEntry = null;
                                              }else{
                                                Navigator.pop(ctx);
                                              }
                                              return false; // Prevents the default back button behavior
                                            },
                                            child: NotificationListener<DraggableScrollableNotification>(
                                              onNotification: (notification) {
                                                print("listener called");
                                                // Detect ANY movement (no threshold)
                                                if (_previousExtent != notification.extent && keyBoardOpen == true) {
                                                  print("Sheet is being dragged (${notification.extent})");
                                                  print("bool => ${keyBoardOpen}");
                                                  focusNode1.unfocus();
                                                  //Navigator.pop(ctx);
                                                  _previousExtent = notification.extent;
                                                }
                                                return false;
                                              },
                                              child: DraggableScrollableSheet(
                                                  expand: false, // Ensures it doesn't expand fully by default
                                                  initialChildSize: 0.7, // Half screen by default
                                                  minChildSize: 0.3, // Minimum height
                                                  maxChildSize: 1.0,
                                                  builder: (BuildContext context, ScrollController scrollController) {
                                                    return CommentScreen(
                                                      postid: widget.posts![index].id,
                                                      pic: widget.posts![index].userPic,
                                                      scrollController: scrollController,
                                                        isEventPost: widget.posts![index].addMeInFashionWeek!,
                                                        userID: widget.posts![index].userid
                                                    );
                                                  }
                                              ),
                                            ),
                                          );
                                        });
                                  },
                                  child: Text("View all ${widget.posts![index].commentCount} comments")),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  }
              ),
            )
          ],
        ),
      ),
    );
  }
}
