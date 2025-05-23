import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class PostLikeUserScreen extends StatefulWidget {
  var fashionId;
  PostLikeUserScreen({super.key, this.fashionId});

  @override
  State<PostLikeUserScreen> createState() => _PostLikeUserScreenState();
}

class _PostLikeUserScreenState extends State<PostLikeUserScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> fanList = [];
  List<int> idolIdList = [];
  List<bool> fanBools = [];
  List<Map<String,dynamic>> requestList = [];
  bool requestLoader2 = false;
  String fanRequestID = "";
  String id = '';
  String token = '';
  bool loading = true;
  bool fanLoader = false;


  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    debugPrint("Post id => ${widget.fashionId}");
    debugPrint("User id => ${id}");
    getRequests();
  }

  getRequests() {
    requestList.clear();
    try {
      https.get(Uri.parse("$serverUrl/Request/personrequests/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        print("requests ==> ${value.body.toString()}");
        jsonDecode(value.body).forEach((e){
          setState(() {
            requestList.add(e);
          });
          print("item => ${e}");
        });
        setState(() {
          loading = false;
        });
        print("request list => ${requestList}");
      });
      getMyIdols();
    } catch (e) {
      setState(() {
        loading = false;
      });
      print("Error --> $e");
    }
  }
  getUsers() async {
    users.clear();
    setState(() {
      loading = true;
    });
    String url = "$serverUrl/fashionLikes/${widget.fashionId}/";
    try {
      final response = await https.get(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        if (responseData != null && responseData is Map<String, dynamic>) {
          final List<dynamic> results = responseData['results'] ?? [];

          List<Map<String, dynamic>> newUsers = [];

          // Create a list of futures to wait for all fan checks to complete
          List<Future<void>> fanCheckFutures = [];

          // Iterate through results and fetch fan status for each user
          for (var element in results) {
            Map<String, dynamic> user = Map<String, dynamic>.from(element);
            newUsers.add(user);
            fanBools.add(false);
            // Add a future to the list to check fan status
            // fanCheckFutures.add(
            //   getFan(id, user["userData"]["id"]).then((isFan) {
            //     user["isFan"] = isFan;
            //   }),
            // );
          }

          // Wait for all fan status checks to complete
         // await Future.wait(fanCheckFutures);

          // Once all futures are done, update the state with the complete user list
          setState(() {
            users.addAll(newUsers);
            loading = false;
          });

          print("Users => ${users}");
        }
      } else {
        debugPrint("Error received: Status Code ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("Network or parsing error: ${error.toString()}");
    }
  }
  getMyIdols(){
    idolIdList.clear();
    setState(() {
      loading = true;
    });
    try{
      https.get(
          Uri.parse("$serverUrl/fansidols/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        debugPrint("fansidols response==========>${jsonDecode(value.body)}");
        jsonDecode(value.body).forEach((data){
          setState(() {
            idolIdList.add(data["idols"]["id"]);
          });
        });
        print("Idols => ${idolIdList}");
      });
      getUsers();
    }catch(e){
      debugPrint("Error --> $e");
    }
  }
  Future<bool> getFan(from, to) async {
    try {
      final response = await https.get(
        Uri.parse("$serverUrl/fansRequests/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final fansData = json.decode(response.body);
        bool isFan = false;

        for (var e in fansData) {
          if (from == e["from_user"].toString() && to == e["to_user"].toString()) {
            isFan = true;
            break;
          }
        }

        return isFan;
      } else {
        print("Error fetching fans: Status Code ${response.statusCode}");
        return false;
      }
    } catch (error) {
      print("Error fetching fans: $error");
      return false;
    }
  }

  removeFan(fanId){
    setState(() {
      loading = true;
    });
    https.delete(
      Uri.parse("$serverUrl/fansfansRequests/$fanId/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).then((value){
      setState(() {
        loading = false;
      });
      print(value.body.toString());
      getMyIdols();
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
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
        getMyIdols();
      });
      print(value.body.toString());

    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
  }
  getRequestsForCancel(friendID) {
    try {
      https.get(Uri.parse("$serverUrl/Request/personrequests/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        print("requests ==> ${value.body.toString()}");
        jsonDecode(value.body).forEach((e){
          if(e["from_user"]["id"].toString() == id && e["to_user"]["id"].toString() == friendID){
            fanRequestID = e["id"].toString();
            cancelFanRequest(fanRequestID);
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
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        "from_user": from,
        "to_user": to,
        "to_token": token
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
        "Authorization": "Bearer $token"
      },
    ).then((value){
      setState(() {
        requestLoader2 = false;
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCashedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   centerTitle: true,
      //   backgroundColor: primary,
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
      //   title: const Text(
      //     "Users who liked the post",
      //     style: TextStyle(fontFamily: Poppins),
      //   ),
      // ),
      body: loading == true
          ? SpinKitCircle(
              color: primary,
            )
          : (users.isEmpty == true ? const Center(
                  child: Text(
                  "No likes",
                  style: TextStyle(fontFamily: Poppins),
                )) : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                id: users[index]['user']['id'].toString(),
                                username: users[index]["user"]["username"],
                              ))).then((value){
                                getUsers();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left:20,right: 20,top: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          child: Container(
                                            decoration: const BoxDecoration(
                                                borderRadius:
                                                BorderRadius.all(Radius.circular(120)),
                                                color: Colors.black),
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.all(Radius.circular(120)),
                                              child: CachedNetworkImage(
                                                imageUrl: users[index]['user']['pic'],
                                                imageBuilder: (context, imageProvider) => Container(
                                                  height: 50,
                                                  width: 50,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                    const BorderRadius.all(Radius.circular(120)),
                                                    image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                placeholder: (context, url) => SpinKitCircle(
                                                  color: primary,
                                                  size: 20,
                                                ),
                                                errorWidget: (context, url, error) => ClipRRect(
                                                    borderRadius:
                                                    const BorderRadius.all(Radius.circular(50)),
                                                    child: Image.network(
                                                      "https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w",
                                                      width: 50,
                                                      height: 50,
                                                    )),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Column(
                                          crossAxisAlignment:CrossAxisAlignment.start,
                                          children: [
                                            Text(users[index]['user']['username'].toString(),
                                                style: TextStyle(
                                                    color: primary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: Poppins)),
                                            Text(Uri.decodeComponent(users[index]['user']['name'].toString()),
                                                style: const TextStyle(
                                                    color: Colors.white, fontFamily: Poppins))
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if(users[index]['user']['id'].toString() != id) Row(
                                    mainAxisAlignment: MainAxisAlignment.end, // Align the button to the right
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if(users[index]["userData"]["isPrivate"] == false)
                                        (users[index]["userData"]["fansList"] ?? []).contains(int.parse(id)) == true
                                          ? Container(
                                        width: 90,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey,
                                          ),
                                          onPressed: () {
                                            removeFan(users[index]["user"]["id"].toString());
                                          },
                                          child: const Text(
                                            "Unfan",
                                            style: TextStyle(color: Colors.white, fontFamily: Poppins,fontSize: 12,
                                              fontWeight: FontWeight.w700,),
                                          ),
                                        ),
                                      )
                                          : Container(
                                        width: 90,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primary,
                                          ),
                                          onPressed: () {
                                            addFan(id, users[index]["user"]["id"].toString());
                                          },
                                          child: const Text(
                                            "Fan",
                                            style: TextStyle(color: Colors.white, fontFamily: Poppins,fontSize: 12,
                                              fontWeight: FontWeight.w700,),
                                          ),
                                        ),
                                      ),
                                      if(users[index]["userData"]["isPrivate"] == true) (users[index]["userData"]["fansList"] ?? []).contains(int.parse(id)) == false
                                          ? Container(
                                        width: 90,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == users[index]["user"]["id"].toString()) == true ? Colors.grey : primary,
                                          ),
                                          onPressed: () {
                                            if(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == users[index]["user"]["id"].toString()) == false){
                                              print("fan");
                                              sendFanRequest(id,users[index]["user"]["id"].toString());
                                              // showDialog(
                                              //   context: context,
                                              //   builder: (context) => AlertDialog(
                                              //     backgroundColor: primary,
                                              //     title: Text("Fan request ${friends[index].username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                              //     content: Text("Are you sure you want to send fan request to ${friends[index].username}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                              //     actions: [
                                              //       TextButton(
                                              //         child: Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                              //         onPressed:  () {
                                              //           setState(() {
                                              //             Navigator.pop(context);
                                              //           });
                                              //         },
                                              //       ),
                                              //       TextButton(
                                              //         child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                              //         onPressed:  () {
                                              //           Navigator.pop(context);
                                              //           sendFanRequest(id,friends[index].id);
                                              //         },
                                              //       ),
                                              //     ],
                                              //   ),
                                              // );
                                            }else if(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == users[index]["user"]["id"].toString()) == true) {
                                              print("unfan");
                                              getRequestsForCancel(users[index]["user"]["id"].toString());
                                              // showDialog(
                                              //   context: context,
                                              //   builder: (context) => AlertDialog(
                                              //     backgroundColor: primary,
                                              //     title: Text("Cancel request ${friends[index].username}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                              //     content: Text("Are you sure you want to cancel fan request to ${friends[index].username}?",style: TextStyle(color: ascent,fontFamily: Poppins),),
                                              //     actions: [
                                              //       TextButton(
                                              //         child: Text("Cancel",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                              //         onPressed:  () {
                                              //           setState(() {
                                              //             Navigator.pop(context);
                                              //           });
                                              //         },
                                              //       ),
                                              //       TextButton(
                                              //         child: Text("Okay",style: TextStyle(color: ascent,fontFamily: Poppins)),
                                              //         onPressed:  () {
                                              //           Navigator.pop(context);
                                              //           getRequestsForCancel(friends[index].id);
                                              //         },
                                              //       ),
                                              //     ],
                                              //   ),
                                              // );
                                              //removeFan(widget.id);
                                            }
                                            //Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfile()));
                                          },
                                          child: requestLoader2 == true ? const SpinKitCircle(color: ascent, size: 20,) : Text(requestList.any((element) => element["from_user"]["id"].toString() == id && element["to_user"]["id"].toString() == users[index]["user"]["id"].toString()) == true ? 'Req...' :'Fan Req...',style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: Poppins,
                                              color: ascent
                                          ),),
                                        ),
                                      )
                                          : Container(
                                        width: 90,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor: primary,
                                                title: Text("Unfan ${users[index]["user"]["username"]}",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                                                content: Text("Are you sure you want to unfan ${users[index]["user"]["username"]}? If you change your mind, you'll need to send a fan request again?",style: TextStyle(color: ascent,fontFamily: Poppins),),
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
                                                      Navigator.pop(context);
                                                      removeFan(users[index]["user"]["id"].toString());
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            "Unfan",
                                            style: TextStyle(color: Colors.white, fontFamily: Poppins,fontSize: 12,
                                              fontWeight: FontWeight.w700,),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12,),
                                    ],
                                  ),
                                  // if(id != users[index]["user"]["id"].toString()) fanBools[index] == true ?Container(
                                  //     height: 20,
                                  //     width: 20,
                                  //     child: CircularProgressIndicator(color: primary,strokeWidth: 1,)):
                                  // ElevatedButton(
                                  //     style: ElevatedButton.styleFrom(
                                  //         padding: EdgeInsets.symmetric(vertical: 10),
                                  //         backgroundColor: users[index]["userData"]["fansList"].contains(int.parse(id)) == true ? Colors.grey : primary),
                                  //     onPressed: users[index]["userData"]["fansList"].contains(int.parse(id)) == true ? (){
                                  //       print("Unfan user");
                                  //       removeFan(users[index]['user']['id'],index);
                                  //     } : () {
                                  //       print("fan user");
                                  //       addFan(id,users[index]['user']['id'],index);
                                  //     },
                                  //     child:
                                  //     Text(users[index]["userData"]["fansList"].contains(int.parse(id)) == true ? "Unfan" : "Fan",
                                  //         style: TextStyle(
                                  //             color: Colors.white,
                                  //             fontFamily: Poppins))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ))
    );
  }
}
