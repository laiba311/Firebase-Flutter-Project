import 'dart:convert';

import 'package:finalfashiontimefrontend/screens/reels/createReel.dart';
import 'package:finalfashiontimefrontend/screens/reels/reelsInitializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class ReelsInterfaceScreen extends StatefulWidget {
  final Function navigateTo;
  final Function navigateToPageWithReelReportArguments;
  final Function onNavigateBack;
  const ReelsInterfaceScreen({super.key, required this.navigateTo, required this.navigateToPageWithReelReportArguments, required this.onNavigateBack});

  @override
  State<ReelsInterfaceScreen> createState() => _ReelsInterfaceScreenState();
}
List<Map<String, dynamic>> reels = [];
String id="";
String token="";
bool isLastReel = false;
int pageNumber=1;

class _ReelsInterfaceScreenState extends State<ReelsInterfaceScreen> {
  getCachedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    getAllReels(1);
  }
  showToast(Color bg, String toastMsg) {
    Fluttertoast.showToast(
      msg: toastMsg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: bg,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
  // Future<void> getAllReels() async {
  //   const String apiUrl = '$serverUrl/fashionReel/';
  //   // Replace with your actual API endpoint
  //   final response = await https.get(Uri.parse(apiUrl),headers: {
  //     'Authorization': 'Bearer $token',
  //   },);
  //
  //   if (response.statusCode ==200) {
  //     final List<dynamic> data = jsonDecode(response.body);
  //     setState(() {
  //        reels= List<Map<String, dynamic>>.from(data);
  //        debugPrint("all reel data ${reels.toString()}");
  //        debugPrint(" reel data length ${reels.length}");
  //     });
  //   } else {
  //     debugPrint('Failed to load data. Status code: ${response.statusCode}');
  //   }
  // }
  Future<void> getAllReels(int pagination) async {
     String apiUrl = '$serverUrl/fashionReel/?page=$pagination';

    try {
      final response = await https.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        if (responseData != null && responseData is Map<String, dynamic>) {

          final List<dynamic> results = responseData['results'] ?? [];

          setState(() {
            reels = List<Map<String, dynamic>>.from(results);
            debugPrint("all reel data ${reels.toString()}");
            debugPrint("reel data length ${reels.length}");
          });

          final dynamic nextUrl = responseData['next'];
          if (nextUrl != null) {
              pageNumber++;

          }
          else{
            //showToast(Colors.green, "You are up to date");
          }
        } else {
          debugPrint("Unexpected data format or null value: $responseData");
        }
      } else {
        debugPrint('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error loading data: $error');
    }
  }
  Future<void> getMoreReels() async {
     String apiUrl = '$serverUrl/fashionReel/?page=2';

    try {
      final response = await https.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        if (responseData != null && responseData is Map<String, dynamic>) {

          final List<dynamic> results = responseData['results'] ?? [];

          setState(() {
            reels.addAll(List<Map<String, dynamic>>.from(results));
            debugPrint("all reel data ${reels.toString()}");
            debugPrint("reel data length ${reels.length}");
          });

          // If you need to handle pagination, you can check the "next" field.
          final dynamic nextUrl = responseData['next'];
          if (nextUrl != null) {
            pageNumber++;
          }
          else{

          }

        } else {
          debugPrint("Unexpected data format or null value: $responseData");
        }
      } else {
        debugPrint('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error loading data: $error');
    }
  }
  Future<void> addViewToReels(id) async {
    String apiUrl = '$serverUrl/fashionReel/$id';

    try {
      final response = await https.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        print("Viewed ==> ${responseData.toString()}");
        getAllReels(1);
      } else {
        debugPrint('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error loading data: $error');
    }
  }

  refreshReels()async{
    getAllReels(1);
  }


  @override
  void initState() {
    getCachedData();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        widget.onNavigateBack(0);
        return Future.value(false);
      },
      child: SafeArea(
        child:
        reels.isEmpty ? GestureDetector(
          onTap: (){
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateReelScreen(
                    // refreshReel: () {
                    //   //widget.refreshReel!();
                    // },
                  ),
                ));
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add)
                ],
              ),
              SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Create Flick",style: TextStyle(
                   fontSize: 14,
                    fontFamily: Poppins,
                  ),)
                ],
              )
            ],
          ),
        ) : Stack(
          children: [
            Swiper(
              itemBuilder: (BuildContext context, int index) {
                return
                  ReelsInitializerScreen(
                    navigateTo: widget.navigateTo,
                    navigateToPageWithReelReportArguments: widget.navigateToPageWithReelReportArguments,
                    videoLink: reels[index]['upload']['media'][0]['video'],name: reels[index]['user']['name'],reelDescription: reels[index]['description'],likeCount: reels[index]["likesCount"],userId: int.parse(id),token: token,reelId: reels[index]['id'],myLikes: reels[index]['myLike'],onLikeCreated: () {
                      getAllReels(1);
                    },onDislikeCreated: () {
                      getAllReels(1);
                    },refreshReel: () {
                    refreshReels();
                    },userPic: reels[index]['user']['pic'] ?? "",
                    reelCount:reels[index]['viewsCount'].toString(),
                  friendId: reels[index]['user']['id'].toString(),isCommentEnabled: reels[index]["isCommentOff"],);
              },
              itemCount: reels.length,
              scrollDirection: Axis.vertical,
              loop: true,
              onIndexChanged: (value) {
                  setState(() {
                    isLastReel = value == reels.length - 1;
                  });
                  print("On Scroll ==> $value");
                  addViewToReels(reels[value]['id']);
              },
            ),
            if (isLastReel)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    color: Colors.transparent, // Set the background color as needed
                    child:  Icon(Icons.change_circle_outlined,size: 30,color: primary),
                  ),
                  onTap: () {
                    setState(() {
                      pageNumber++;
                      getAllReels(pageNumber);
                    });
                  },
                ),
              ),

            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Text("Reels",
            //           style: TextStyle(
            //               color: primary,
            //               fontSize: 30,
            //               fontFamily: Poppins,
            //               decoration: TextDecoration.none)),
            //       GestureDetector(
            //         onTap: () {
            //           Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateReelScreen(),));
            //         },
            //           child: const Icon(Icons.camera_alt)),
            //     ],
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(12),
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       const SizedBox(),
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           Column(
            //             children: [
            //               const SizedBox(
            //                 height: 100,
            //               ),
            //               Row(
            //                 children: const [
            //                   CircleAvatar(
            //                     radius: 20,
            //                     child: Icon(
            //                       Icons.person,
            //                       size: 26,
            //                     ),
            //                   ),
            //                   SizedBox(
            //                     width: 6,
            //                   ),
            //                   Text("Username",
            //                       style: TextStyle(
            //                           color: ascent,
            //                           fontFamily: Poppins,
            //                           fontSize: 16,
            //                           decoration: TextDecoration.none)),
            //                 ],
            //               ),
            //               const SizedBox(
            //                 width: 30,
            //               ),
            //               const Text("Reel Description",
            //                   style: TextStyle(
            //                       color: ascent,
            //                       fontSize: 12,
            //                       fontFamily: Poppins,
            //                       decoration: TextDecoration.none)),
            //               const SizedBox(
            //                 height: 10,
            //               )
            //             ],
            //           ),
            //           Column(
            //             children: const [
            //               SizedBox(
            //                 height: 70,
            //               ),
            //               Icon(Icons.favorite_border_outlined),
            //               Text("100k",
            //                   style: TextStyle(
            //                       color: ascent,
            //                       fontSize: 12,
            //                       fontFamily: Poppins,
            //                   decoration: TextDecoration.none)),
            //             ],
            //           )
            //         ],
            //       ),
            //     ],
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}
