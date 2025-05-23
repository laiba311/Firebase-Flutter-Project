import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/constants.dart';
import 'liked_reel_initializer.dart';

class MyLikedReelsInterfaceScreen extends StatefulWidget {
  const MyLikedReelsInterfaceScreen({super.key});

  @override
  State<MyLikedReelsInterfaceScreen> createState() => _MyLikedReelsInterfaceScreenState();
}
List<Map<String, dynamic>> reels = [];
String id="";
String token="";
bool isLastReel = false;
int pageNumber=1;

class _MyLikedReelsInterfaceScreenState extends State<MyLikedReelsInterfaceScreen> {
  getCachedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    getAllReels();

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

  Future<void> getAllReels() async {
    String apiUrl = '$serverUrl/fashionapi/hundred-liked/';

    try {
      final response = await https.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        if (responseData != null && responseData is Map<String, dynamic>) {

          final List<dynamic> results = responseData['results']['fashion_reels'] ?? [];

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
    String apiUrl = '$serverUrl/fashionReel/my-reels/?page=2';

    try {
      final response = await https.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        if (responseData != null && responseData is Map<String, dynamic>) {

          final List<dynamic> results = responseData['results']['fashion_reels'] ?? [];

          setState(() {
            reels.addAll(List<Map<String, dynamic>>.from(results));
            debugPrint("all reel data ${reels.toString()}");
            debugPrint("reel data length ${reels.length}");
          });

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

  refreshReels()async{
    getAllReels();
  }


  @override
  void initState() {
    getCachedData();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child:
      reels.isEmpty?
       Scaffold(
        body: Center(
          child: FutureBuilder(
            future: Future.delayed(const Duration(seconds: 2)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SpinKitCircle(color: primary,); // or any loading widget
              } else {
                return const Text("No flicks",style: TextStyle(fontFamily: Poppins),);
              }
            },
          ),
        ),
      )
          :
      Material(
        child: Stack(
          children: [
            Swiper(
              itemBuilder: (BuildContext context, int index) {

                return
                  MyLikedReelsInitializerScreen(
                    videoLink:
                    reels[index]['upload']['media'][0]['video'],name: reels[index]['user']['name'],reelDescription: reels[index]['description'],likeCount: reels[index]["likesCount"],userId: int.parse(id),token: token,reelId: reels[index]['id'],myLikes: reels[index]['myLike'],onLikeCreated: () {
                    getAllReels();
                  },onDislikeCreated: () {
                    getAllReels();
                  },refreshReel: () {
                    refreshReels();
                  },userPic: reels[index]['user']['pic'] ?? "",
                    friendId: reels[index]['user']['id'].toString(),isCommentEnabled: reels[index]["isCommentOff"],);
              },
              itemCount: reels.length,
              scrollDirection: Axis.vertical,
              loop: false,
              onIndexChanged: (value) {

                setState(() {
                  isLastReel = value == reels.length - 1;
                });

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
                      getMoreReels();
                    });
                  },
                ),
              ),

          ],
        ),
      ),

    );
  }
}
