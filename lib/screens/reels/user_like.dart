import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class UserLikeScreen extends StatefulWidget {
  final String reelId;
  const UserLikeScreen({super.key, required this.reelId});

  @override
  State<UserLikeScreen> createState() => _UserLikeScreenState();
}

String token = '';
String id = '';
int pageNumber = 1;
String username = '';
List<Map<String, dynamic>> users = [];
bool loading = true;

class _UserLikeScreenState extends State<UserLikeScreen> {
  getCachedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    username = preferences.getString('username')!;
    getUsers();
  }

  getUsers() async {
    String url = '$serverUrl/fashionReelLikes/${widget.reelId}/';
    loading = true;
    try {
      final response = await https.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        log("response=========>${response.body}");
        final dynamic responseData = jsonDecode(response.body);
        if (responseData != null && responseData is Map<String, dynamic>) {
          final List<dynamic> results = responseData['results'] ?? [];

          setState(() {
            loading = false;
            users = List<Map<String, dynamic>>.from(results);
            debugPrint("all reel data ${users.toString()}");
            debugPrint("reel data length ${users.length}");
          });

          final dynamic nextUrl = responseData['next'];
          if (nextUrl != null) {
            pageNumber++;
          } else {}
        }
      } else {
        log("error in api ==========>${response.statusCode}");
        loading = false;
      }
    } catch (e) {
      log("Exception occurred ${e.toString()}");
      loading = false;
    }
  }
  addFan(from,to){
    setState(() {
     loading = true;
    });
    https.post(
      Uri.parse("$serverUrl/fansRequests/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        "from_user": from,
        "to_user": to
      }),
    ).then((value){
      setState(() {
         loading= false;
         users.clear();
         getUsers();
      });
      print(value.body.toString());

    }).catchError((value){
      setState(() {
    loading = false;
      });
      print(value);
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    getCachedData();
    super.initState();
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
                  ])),
        ),
        centerTitle: true,
        title: const Text(
          "People who liked your flick",
          style: TextStyle(color: Colors.white, fontFamily: Poppins),
        ),
      ),
      body: loading == true
          ? Center(
              child: SpinKitCircle(
                color: primary,
                size: 50,
              ),
            )
          : users.isEmpty
              ? Center(
                  child: Text("No Likes",
                      style:
                          TextStyle(color: primary, fontFamily: Poppins)))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {},
                        child: Container(
                          decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(120)),
                              color: Colors.black),
                          child: Container(
                              decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(120)),
                                  color: Colors.black),
                              child: const CircleAvatar()),
                          // ClipRRect(
                          //   borderRadius: const BorderRadius.all(Radius.circular(120)),
                          //   child: CachedNetworkImage(
                          //     imageUrl: users[index]['user']['pic']??"",
                          //     imageBuilder: (context, imageProvider) => Container(
                          //       height: 50,
                          //       width: 50,
                          //       decoration: BoxDecoration(
                          //         borderRadius:
                          //             const BorderRadius.all(Radius.circular(120)),
                          //         image: DecorationImage(
                          //           image: imageProvider,
                          //           fit: BoxFit.cover,
                          //         ),
                          //       ),
                          //     ),
                          //     placeholder: (context, url) => SpinKitCircle(
                          //       color: primary,
                          //       size: 20,
                          //     ),
                          //     errorWidget: (context, url, error) => ClipRRect(
                          //         borderRadius:
                          //             const BorderRadius.all(Radius.circular(50)),
                          //         child: Image.network(
                          //           "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                          //           width: 50,
                          //           height: 50,
                          //         )),
                          //   ),
                          // ),
                        ),
                      ),
                      title: Text(users[index]['user']['username'] ?? "",
                          style: const TextStyle(
                              color: Colors.white, fontFamily: Poppins)),
                      subtitle: Text(users[index]['user']['username'] ?? "",
                          style: const TextStyle(
                              color: Colors.white, fontFamily: Poppins)),
                      trailing: users[index]['user']['username'] != username
                          ? users[index]['user']['isFan']
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey),
                                  onPressed: () {},
                                  child: const Text("Fan",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: Poppins)))
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: primary),
                                  onPressed: () {
                                    addFan(id, users[index]['user']['id']);
                                  },
                                  child: const Text("Fan",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: Poppins)))
                          : const SizedBox(),
                    );
                  },
                ),
    );
  }
}
