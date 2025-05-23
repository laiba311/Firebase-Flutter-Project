import 'dart:convert';
import 'package:finalfashiontimefrontend/screens/profiles/friend_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart'as https;
import '../../../utils/constants.dart';
class FriendRequest extends StatefulWidget {
  const FriendRequest({super.key});

  @override
  State<FriendRequest> createState() => _FriendRequestState();
}

class _FriendRequestState extends State<FriendRequest> with SingleTickerProviderStateMixin {
  String token='';
  String id='';
  String userName='';
  String requestId='';
  bool isGetRequest=false;
  List<Map<String, dynamic>> friendRequests = [];
  List<Map<String, dynamic>> friendRequests1 = [];
  List<Map<String, dynamic>> fanRequests = [];
  List<Map<String, dynamic>> fanRequests1 = [];
  List<Map<String, dynamic>> filteredFriends = [];
  List<Map<String, dynamic>> filteredFans = [];
  List<Map<String, dynamic>> fanRequestsForIds = [];
  bool loading =false;
  bool isRejected=false;
  bool requestLoader = false;
  late TabController tabController;
  bool requestLoader2 = false;
  bool isPrivate = false;
  TextEditingController fanController = TextEditingController();
  TextEditingController friendController = TextEditingController();
  bool fanAll = true;
  bool notifications = false;
  bool requests = false;

  bool fanAll1 = true;
  bool notifications1 = false;
  bool requests1 = false;

  final PageController _pageController = PageController();
  int _currentPage = 0;


  String formatTimeDifference(String dateString) {
    DateTime createdAt = DateTime.parse(dateString);
    DateTime now = DateTime.now();

    Duration difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      int weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else if (difference.inDays < 365) {
      int months = (difference.inDays / 30).floor();
      return '${months}m';
    } else {
      int years = (difference.inDays / 365).floor();
      return '${years}y';
    }
  }
  deleteNotification(id){
    String url="$serverUrl/friendrequestnotiApi/$id/";
    https.delete(Uri.parse(url),headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      // debugPrint("deleted notification======>${value.statusCode}");
      // setState(() {
        getFriendRequest();
      // });
    }).onError((error, stackTrace) {
      debugPrint("error received while removing this notifications");
    });
  }
  matchFriendRequest(id1,notificationId){
    //debugPrint("Match Friend id");
    try{
      https.get(
          Uri.parse("$serverUrl/followRequests/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        debugPrint("id is =======>$id");
        jsonDecode(value.body).forEach((request){
          if(request["from_user"].toString() == id1.toString() && request["to_user"].toString() == id.toString()){
            setState(() {
              loading = false;
              isGetRequest = true;
              requestId = request["id"].toString();
              isRejected? rejectRequest(requestId) : acceptRequest(requestId,id1,notificationId);
            });
            deleteNotification(notificationId);
            // debugPrint(isGetRequest.toString());
            // debugPrint(requestId.toString());
          }
          else if(request["from_user"].toString() == id.toString() && request["to_user"].toString() == id1.toString()){
            setState(() {
              loading = false;
            });
            requestId = request["id"].toString();
            isRejected ? rejectRequest(requestId) : acceptRequest(requestId,id1,notificationId);
            deleteNotification(notificationId);
          }
          else{
            setState(() {
              loading = false;
            });
            deleteNotification(notificationId);
            // debugPrint(isGetRequest.toString());
          }
        });
        setState(() {
          loading = false;
        });
        //debugPrint(jsonDecode(value.body).toString());

      });
    }catch(e){
      setState(() {
        loading = false;
      });
      // debugPrint("Error --> $e");
    }
  }
  matchFriendRequest1(id1,notificationId,fanReqId){
    //debugPrint("Match Friend id");
    try{
      https.get(
          Uri.parse("$serverUrl/followRequests/"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          }
      ).then((value){
        debugPrint("id is =======>$id");
        jsonDecode(value.body).forEach((request){
          if(request["from_user"].toString() == id1.toString() && request["to_user"].toString() == id.toString()){
            print("Matched 1");
            setState(() {
              loading = false;
              isGetRequest = true;
              requestId = request["id"].toString();
              isRejected? rejectRequest(requestId) : acceptRequest(requestId,id1,fanReqId);
            });
            deleteNotification(notificationId);
          }
          else if(request["from_user"].toString() == id.toString() && request["to_user"].toString() == id1.toString()){
            print("Matched 2");
            setState(() {
              loading = false;
            });
            requestId = request["id"].toString();
            isRejected ? rejectRequest(requestId) : acceptRequest(requestId,id1,fanReqId);
            deleteNotification(notificationId);
          }
          else{
            print("Not Matched 3");
            setState(() {
              loading = false;
            });
            deleteNotification(notificationId);
          }
        });
        setState(() {
          loading = false;
        });
      });
    }catch(e){
      print("Error");
      setState(() {
        loading = false;
      });
      // debugPrint("Error --> $e");
    }
  }
  acceptRequest(userid,id1,notiId){
    print("Accept person id => ${notiId}");
    setState(() {
      requestLoader = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_accept_request/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      setState(() {
        requestLoader = false;
      });
      print("request status ======>${value.body}");
      addFan(id1,id,notiId);
      // getMyFriends(widget.id);
    }).catchError((value){
      setState(() {
        requestLoader = false;
      });
      print(value);
    });
  }
  rejectRequest(userid){
    setState(() {
      requestLoader = true;
    });
    https.post(
        Uri.parse("$serverUrl/follow_reject_request/$userid/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }
    ).then((value){
      setState(() {
        requestLoader = false;
      });
      debugPrint(value.body.toString());
    }).catchError((value){
      setState(() {
        requestLoader = false;
      });
      debugPrint(value.toString());
    });
  }
  getFriendRequest() {
    friendRequests.clear();
    fanRequests.clear();
    setState(() {
      loading = true;
    });
    try {
      https.get(Uri.parse("$serverUrl/friendrequestnotiApi/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {

        jsonDecode(value.body).forEach((data) {
          if(data['title'] == 'New Follow Request' || data['title'] == 'Follow Request Accepted') {
            setState(() {
             // loading=false;
              friendRequests.add({
                "title": data["title"].toString(),
                "body": data["body"].toString(),
                "action": data["action"].toString() ,
                "updated": data["updated"].toString(),
                'sender':data['sender']['id'].toString(),
                "id":data['id'].toString(),
                'data':data['sender'],
              });
              friendRequests1.add({
                "title": data["title"].toString(),
                "body": data["body"].toString(),
                "action": data["action"].toString() ,
                "updated": data["updated"].toString(),
                'sender':data['sender']['id'].toString(),
                "id":data['id'].toString(),
                'data':data['sender'],
              });
            });
            print("Requests => ${friendRequests.toString()}");
          }
        });
        setState(() {
          loading=false;
        });
        debugPrint("total request=====>${friendRequests.length}");
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error received========>${e.toString()}");
    }
    getFanRequest();
  }
  getFanRequest() {
    // fanRequests.clear();
    // setState(() {
    //   loading = true;
    // });
    try {
      https.get(Uri.parse("$serverUrl/Request/api/personrequests/filter/${id}/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {

        jsonDecode(value.body).forEach((data) {
            setState(() {
              //loading=false;
              fanRequests.add(data);
              fanRequests1.add(data);
              fanRequestsForIds.add(data);
            });
            print("Requests => ${fanRequests.toString()}");
        });
        setState(() {
          //loading=false;
        });
        debugPrint("total request=====>${fanRequests.length}");
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error received========>${e.toString()}");
    }
    getFanRequestMessages();
  }
  getFanRequestMessages() {
    // fanRequests.clear();
    // setState(() {
    //   loading = true;
    // });
    try {
      https.get(Uri.parse("$serverUrl/RequestMessage/api/personrequestsmessage/filter/${id}/"), headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }).then((value) {
        print("Datat => ${value.body}");
        jsonDecode(value.body).forEach((data) {
          setState(() {
            fanRequests.add(data);
            fanRequests1.add(data);
          });
          print("Requests => ${fanRequests.toString()}");
        });
        setState(() {
          loading=false;
        });
        debugPrint("total request=====>${fanRequests.length}");
      });
      readFriendRequest1();
      readFriendRequest();
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error received========>${e.toString()}");
    }
  }
  getCashedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id")!;
    token = preferences.getString("token")!;
    userName = preferences.getString('username')!;
    getFriendRequest();
  }
  cancelFanRequest(fanId){
    print("My personal request ==> ${fanId}");
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
        loading = true;
      });
      print("Request done ${value.body.toString()}");
      getFriendRequest();
    }).catchError((value){
      setState(() {
        requestLoader2 = false;
      });
      print(value);
    });
  }
  addFan(from,to,fanReqId){
    print("Add fan person id => ${fanReqId}");
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
      print("Fans Response ==> ${value.body.toString()}");
      sendFanMessage(to,from,fanReqId);
    }).catchError((value){
      print("Fans Response ==> ${value.body.toString()}");
      setState(() {
        loading = false;
      });
      print(value);
    });
  }
  sendFanMessage(from,to,fanReqId){
    print("Fan Message ==> ${fanReqId}");
    https.post(
      Uri.parse("$serverUrl/RequestMessage/personrequestsmessages/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        "from_user": from,
        "to_user": to,
        "to_token": token,
        "is_message": true,
        "message": "has accepted your fan request!"
      }),
    ).then((value){
      cancelFanRequest(fanReqId);
    }).catchError((value){
      setState(() {
        loading = false;
      });
      print(value);
    });
  }
  readFriendRequest() {
    https.post(
        Uri.parse("$serverUrl/friendrequestnotimark-all-friendrequestnotifications-as-read/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }).then((value) {
      debugPrint(value.body.toString());
      readFanRequest();
      setState(() {
        loading = false;
      });
    }).catchError(() {
      debugPrint("Error");
      setState(() {
        loading = false;
      });
    });
  }
  readFriendRequest1() {
    https.post(
        Uri.parse("$serverUrl/friendrequestnotimark-all-friendrequestnotifications-as-read/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }).then((value) {
      debugPrint(value.body.toString());
      readFanRequestMessage();
      setState(() {
        loading = false;
      });
    }).catchError(() {
      debugPrint("Error");
      setState(() {
        loading = false;
      });
    });
  }
  readFanRequest() {
    https.post(
        Uri.parse("$serverUrl/Request/mark-all-fanrequest-as-read/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }).then((value) {
      debugPrint(value.body.toString());
      setState(() {
        loading = false;
      });
    }).catchError(() {
      debugPrint("Error");
      setState(() {
        loading = false;
      });
    });
  }
  readFanRequestMessage() {
    https.post(
        Uri.parse("$serverUrl/RequestMessage/mark-all-fanrequest-message-as-read/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        }).then((value) {
      debugPrint(value.body.toString());
      setState(() {
        loading = false;
      });
    }).catchError(() {
      debugPrint("Error");
      setState(() {
        loading = false;
      });
    });
  }
  getProfile() {
    https.get(Uri.parse("$serverUrl/user/api/profile/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).then((value) {
      print("Profile data ==> ${value.body.toString()}");
      final body = utf8.decode(value.bodyBytes);
      final jsonData = jsonDecode(body);
      print("Private Acc ==> ${jsonData["isPrivate"]}");
      isPrivate = jsonData["isPrivate"];
      if(jsonData["isPrivate"] == true){
        getFriendRequest();
      }else {

      }
    });
  }

  Future<void> _refreshData() async {
    // Simulate a network request or data update
    await Future.delayed(Duration(seconds: 2));
    getFriendRequest();
  }

  @override
  void initState() {
    // TODO: implement initState
    tabController = TabController(length: 2, vsync: this);
    getCashedData();
    super.initState();
  }

  void filterFriends(String query) {
    List<Map<String,dynamic>> filtered = [];

    if (query.isEmpty) {
      filtered = List.from(friendRequests);
    } else {
      for (var friend in friendRequests) {
        if (friend['data']["name"].toLowerCase().contains(query.toLowerCase()) || friend['data']["username"].toString().split(" ")[0].toLowerCase().contains(query.toLowerCase())) {
          setState(() {
            filteredFriends.add(friend);
          });
        }
      }
      filtered = friendRequests.where((friend) {
        final name = friend['data']["name"].toLowerCase();
        final username = friend["data"]["username"].toLowerCase();
        return name.contains(query.toLowerCase()) || username.contains(query.toLowerCase());
      }).toList();
    }
    setState(() {
      filteredFriends = filtered;
    });
    // filteredFriends.clear();
    // if (query.isEmpty) {
    //   setState(() {
    //     filteredFriends.addAll(friendRequests);
    //   });
    // } else {
    //
    //   for (var friend in friendRequests) {
    //     if (friend['data']["name"].toLowerCase().contains(query.toLowerCase()) || friend['data']["username"].toString().split(" ")[0].toLowerCase().contains(query.toLowerCase())) {
    //       setState(() {
    //         filteredFriends.add(friend);
    //       });
    //     }
    //   }
    // }
  }
  void filterFan(String query) {
    List<Map<String,dynamic>> filtered = [];

    if (query.isEmpty) {
      filtered = List.from(fanRequests);
    } else {
      filtered = fanRequests.where((friend) {
        final name = friend["from_user"]["name"].toLowerCase();
        final username = friend["from_user"]["username"].toLowerCase();
        return name.contains(query.toLowerCase()) || username.contains(query.toLowerCase());
      }).toList();
    }

    setState(() {
      filteredFans = filtered;
    });
  }
  chechFanRequest(friendId,reqId){
    print("called");
    var request = fanRequestsForIds.firstWhere(
          (req) => req["from_user"]["id"].toString() == friendId  && req["to_user"]["id"].toString() == id,
      orElse: () => {},
    );
    print("Request => ${request}");
    print("Request => ${request["id"]}");
    //
    if (request.isNotEmpty) {
      print("matching request found.");
      print("request ==> ${request["id"]}");
      print("request id ==> ${reqId}");
      matchFriendRequest1(friendId,reqId,request["id"].toString());
      // print("Matching request ID: ${request["id"]}");
    } else {
      matchFriendRequest(friendId,reqId);
      print("No matching request found.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: TabBar(
              labelColor: ascent,
              indicatorColor: primary,
              labelStyle: TextStyle(fontFamily: Poppins,fontSize: 20),
              controller: tabController,
              tabs:  [
                //Tab(icon: Icon(Icons.favorite, color: _getTabIconColor(context))),
                Tab(text: "Fans",),
                Tab(text: "Friends",),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _refreshData,
                  child: Column(
                    children: [
                      SizedBox(height: 10,),
                      Container(
                        alignment: Alignment.bottomCenter,
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: Card(
                          elevation: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.topRight,
                                  stops: const [0.0, 0.99],
                                  tileMode: TileMode.clamp,
                                  colors:  <Color>[Colors.black12, Colors.black12] ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                  },
                                  child: Container(
                                      height: 40,
                                      width: 20,
                                      child: Icon(Icons.search,color: ascent,)
                                  ),
                                ),
                                const SizedBox(width: 16,),
                                Expanded(
                                    child: TextField(
                                      controller: fanController,
                                      // onChanged: (value) {
                                      //   filterFan(value);
                                      // },
                                      onChanged: filterFan,
                                      style: const TextStyle(color: ascent,fontFamily: Poppins,),
                                      cursorColor: ascent,
                                      //style: simpleTextStyle(),
                                      decoration: const InputDecoration(
                                          fillColor: ascent,
                                          hintText: "Search",
                                          hintStyle: TextStyle(
                                            color: ascent,
                                            fontFamily: Poppins,
                                            fontSize: 16,
                                          ),
                                          border: InputBorder.none
                                      ),
                                    )),
                                const SizedBox(width: 16,),
                                PopupMenuButton(
                                    icon: const Icon(Icons.tune,color: ascent,),
                                    onSelected: (value) {
                                      if (value == 0) {
                                        print("all clicked");
                                        setState(() {
                                          fanAll = true;
                                          notifications = false;
                                          requests = false;
                                        });
                                        getFanRequest();
                                        //getRecentComments(widget.postid);
                                      }
                                      if (value == 1) {
                                        print("notification clicked");
                                        setState(() {
                                          fanAll = false;
                                          notifications = true;
                                          requests = false;
                                        });
                                        setState(() {
                                          fanRequests = List.from(fanRequests1.where((item) => item["is_message"] == true));
                                          filteredFans = List.from(fanRequests1.where((item) => item["is_message"] == true));
                                        });
                                        //getRecentComments(widget.postid);
                                      }
                                      if(value == 2){
                                        print("all clicked");
                                        setState(() {
                                          fanAll = false;
                                          notifications = false;
                                          requests = true;
                                        });
                                        setState(() {
                                          fanRequests = List.from(fanRequests1.where((item) => item["is_message"] == false));
                                          filteredFans = List.from(fanRequests1.where((item) => item["is_message"] == false));
                                        });
                                        //getRecentComments(widget.postid);
                                      }
                                      setState(() {});
                                      print(value);
                                    },
                                    itemBuilder: (BuildContext bc) {
                                      return [
                                        PopupMenuItem(
                                          value: 0,
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                "All",
                                                style: fanAll == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 1,
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                "Notifications",
                                                style: notifications == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 2,
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                "Requests",
                                                style: requests == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ];
                                    }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,),
                      loading ? SpinKitCircle(color: primary,):
                      fanRequests.isEmpty ? Expanded(
                          child:ListView(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                  Text("No Fan Activities",style: TextStyle(fontFamily: Poppins,fontSize: 20),),
                                ],
                              )
                            ],
                          )) : fanController.text.isEmpty
                          ? Expanded(
                        child: ListView.builder(
                          itemCount: fanRequests.length,
                          itemBuilder: (context, index) {
                            return fanRequests[index]["is_message"] == true ? InkWell(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                  id: fanRequests[index]["from_user"]["id"].toString(),
                                  username: fanRequests[index]["from_user"]["username"],
                                ))).then((value){
                                  getProfile();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0,left: 10,right: 10),
                                child: Card(
                                  child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height:50,
                                                width: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius:BorderRadius.all(Radius.circular(30)),
                                                  image: DecorationImage(
                                                      image: NetworkImage(
                                                        fanRequests[index]["from_user"]["pic"] == null ?"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":fanRequests[index]["from_user"]["pic"],
                                                      ),
                                                      fit: BoxFit.cover
                                                  ),
                                                ),
                                                child: Text(""),
                                              ),
                                              SizedBox(width: 10,),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(height: 5,),
                                                  Container(
                                                    width: MediaQuery.of(context).size.width * 0.6,
                                                    child: RichText(
                                                      text: TextSpan(
                                                        text: "${fanRequests[index]["from_user"]["username"]}",
                                                        style: TextStyle(fontFamily: Poppins,color: primary,fontSize: 16,fontWeight: FontWeight.bold),
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                            text: " ${fanRequests[index]["message"]}",
                                                            style: TextStyle(fontFamily: Poppins,color: ascent,fontSize: 16),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Container(
                                                      child: Text(
                                                        "${formatTimeDifference(fanRequests[index]["created"])}",
                                                        style: TextStyle(color: ascent, fontFamily: Poppins,fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                  ),
                                ),
                              ),
                            ) :
                            InkWell(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                  id: fanRequests[index]["from_user"]["id"].toString(),
                                  username: fanRequests[index]["from_user"]["username"],
                                ))).then((value){
                                  getFriendRequest();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0,left: 10,right: 10),
                                child: Card(
                                  child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height:50,
                                                width: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius:BorderRadius.all(Radius.circular(30)),
                                                  image: DecorationImage(
                                                      image: NetworkImage(
                                                        fanRequests[index]["from_user"]["pic"] == null ?"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":fanRequests[index]["from_user"]["pic"],
                                                      ),
                                                      fit: BoxFit.cover
                                                  ),
                                                ),
                                                child: Text(""),
                                              ),
                                              // CircleAvatar(
                                              //   radius: 25,
                                              //   backgroundColor:primary,
                                              //   child: Icon(Icons.face_retouching_natural,color: ascent,),
                                              // ),
                                              SizedBox(width: 10,),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(height: 5,),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "${fanRequests[index]["from_user"]["username"]}",
                                                        style: TextStyle(fontFamily: Poppins,color: primary,fontSize: 16,fontWeight: FontWeight.bold),
                                                      ),
                                                      SizedBox(width: 10,),
                                                      Container(
                                                        child: Text(
                                                          "${formatTimeDifference(fanRequests[index]["created"])}",
                                                          style: TextStyle(color: ascent, fontFamily: Poppins,fontSize: 12),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  //SizedBox(height: 2,),
                                                  Text(
                                                    Uri.decodeComponent(fanRequests[index]["from_user"]["name"]),
                                                    style: const TextStyle(fontFamily: Poppins,fontSize: 16),
                                                  ),
                                                  SizedBox(height: 5,),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  addFan(fanRequests[index]["from_user"]["id"],id,fanRequests[index]["id"]);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                        backgroundColor: primary,
                                                        content: Text("You have accepted the fan request of ${fanRequests[index]["from_user"]["username"]}.",style: TextStyle(color: ascent,fontFamily: Poppins),)),
                                                  );
                                                },
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.all(Radius.circular(30))
                                                  ),
                                                  color: secondary,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 8.0,bottom: 8.0),
                                                    child: Icon(Icons.check,color: ascent,),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: (){
                                                  //print("fansID ==> ${fanRequests[index]["id"]}");
                                                  cancelFanRequest(fanRequests[index]["id"]);
                                                },
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.all(Radius.circular(30))
                                                  ),
                                                  color: primary,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 8.0,bottom: 8.0),
                                                    child: Icon(Icons.close,color: ascent,),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                          : (
                          filteredFans.isNotEmpty
                              ? Expanded(
                            child: ListView.builder(
                              itemCount: filteredFans.length,
                              itemBuilder: (context, index) {
                                return filteredFans[index]["is_message"] == true ? InkWell(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                      id: filteredFans[index]["from_user"]["id"].toString(),
                                      username: filteredFans[index]["from_user"]["username"],
                                    ))).then((value){
                                      getProfile();
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 1.0,left: 10,right: 10),
                                    child: Card(
                                      child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          margin: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    height:50,
                                                    width: 50,
                                                    decoration: BoxDecoration(
                                                      borderRadius:BorderRadius.all(Radius.circular(30)),
                                                      image: DecorationImage(
                                                          image: NetworkImage(
                                                            filteredFans[index]["from_user"]["pic"] == null ?"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":fanRequests[index]["from_user"]["pic"],
                                                          ),
                                                          fit: BoxFit.cover
                                                      ),
                                                    ),
                                                    child: Text(""),
                                                  ),
                                                  SizedBox(width: 10,),
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SizedBox(height: 5,),
                                                      Container(
                                                        width: MediaQuery.of(context).size.width * 0.65,
                                                        child: RichText(
                                                          text: TextSpan(
                                                            text: "${filteredFans[index]["from_user"]["username"]}",
                                                            style: TextStyle(fontFamily: Poppins,color: primary,fontSize: 16,fontWeight: FontWeight.bold),
                                                            children: <TextSpan>[
                                                              TextSpan(
                                                                text: " ${filteredFans[index]["message"]}",
                                                                style: TextStyle(fontFamily: Poppins,color: ascent,fontSize: 16),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 4.0),
                                                        child: Container(
                                                          child: Text(
                                                            "${formatTimeDifference(filteredFans[index]["created"])}",
                                                            style: TextStyle(color: ascent, fontFamily: Poppins,fontSize: 12),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                      ),
                                    ),
                                  ),
                                ) :
                                InkWell(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                      id: filteredFans[index]["from_user"]["id"].toString(),
                                      username: filteredFans[index]["from_user"]["username"],
                                    ))).then((value){
                                      getFriendRequest();
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 1.0,left: 10,right: 10),
                                    child: Card(
                                      child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          margin: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    height:50,
                                                    width: 50,
                                                    decoration: BoxDecoration(
                                                      borderRadius:BorderRadius.all(Radius.circular(30)),
                                                      image: DecorationImage(
                                                          image: NetworkImage(
                                                            filteredFans[index]["from_user"]["pic"] == null ?"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":fanRequests[index]["from_user"]["pic"],
                                                          ),
                                                          fit: BoxFit.cover
                                                      ),
                                                    ),
                                                    child: Text(""),
                                                  ),
                                                  SizedBox(width: 10,),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SizedBox(height: 5,),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "${filteredFans[index]["from_user"]["username"]}",
                                                            style: TextStyle(fontFamily: Poppins,color: primary,fontSize: 16,fontWeight: FontWeight.bold),
                                                          ),
                                                          SizedBox(width: 10,),
                                                          Container(
                                                            child: Text(
                                                              "${formatTimeDifference(filteredFans[index]["created"])}",
                                                              style: TextStyle(color: ascent, fontFamily: Poppins,fontSize: 12),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      //SizedBox(height: 2,),
                                                      Text(
                                                        Uri.decodeComponent(filteredFans[index]["from_user"]["name"]),
                                                        style: const TextStyle(fontFamily: Poppins,fontSize: 16),
                                                      ),
                                                      SizedBox(height: 5,),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      addFan(filteredFans[index]["from_user"]["id"],id,filteredFans[index]["id"]);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                            backgroundColor: primary,
                                                            content: Text("You have accepted the fan request of ${filteredFans[index]["from_user"]["username"]}.",style: TextStyle(color: ascent,fontFamily: Poppins))),
                                                      );
                                                    },
                                                    child: Card(
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(30))
                                                      ),
                                                      color: secondary,
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 8.0,bottom: 8.0),
                                                        child: Icon(Icons.check,color: ascent,),
                                                      ),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: (){
                                                      cancelFanRequest(filteredFans[index]["id"]);
                                                    },
                                                    child: Card(
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(30))
                                                      ),
                                                      color: primary,
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 8.0,bottom: 8.0),
                                                        child: Icon(Icons.close,color: ascent,),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                              : Expanded(
                              child:ListView(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                      Text("No Friend Activities",style: TextStyle(fontFamily: Poppins,fontSize: 20),),
                                    ],
                                  )
                                ],
                              ))
                      )
                    ],
                  ),
                ),
                RefreshIndicator(
                  onRefresh: _refreshData,
                  child: Column(
                    children: [
                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            alignment: Alignment.bottomCenter,
                            width: MediaQuery.of(context).size.width * 0.95,
                            child: Card(
                              elevation: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.topRight,
                                      stops: const [0.0, 0.99],
                                      tileMode: TileMode.clamp,
                                      colors:  <Color>[Colors.black12, Colors.black12] ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                      },
                                      child: Container(
                                          height: 40,
                                          width: 20,
                                          child: Icon(Icons.search,color: ascent,)
                                      ),
                                    ),
                                    const SizedBox(width: 16,),
                                    Expanded(
                                        child: TextField(
                                          controller: friendController,
                                          onChanged: (value) {
                                            filterFriends(value);
                                          },
                                          style: const TextStyle(color: ascent,fontFamily: Poppins,),
                                          cursorColor: ascent,
                                          //style: simpleTextStyle(),
                                          decoration: const InputDecoration(
                                              fillColor: ascent,
                                              hintText: "Search",
                                              hintStyle: TextStyle(
                                                color: ascent,
                                                fontFamily: Poppins,
                                                fontSize: 16,
                                              ),
                                              border: InputBorder.none
                                          ),
                                        )),
                                    const SizedBox(width: 16,),
                                    PopupMenuButton(
                                        icon: const Icon(Icons.tune,color: ascent,),
                                        onSelected: (value) {
                                          if (value == 0) {
                                            print("all clicked");
                                            setState(() {
                                              fanAll1 = true;
                                              notifications1 = false;
                                              requests1 = false;
                                            });
                                            getFriendRequest();
                                            //getRecentComments(widget.postid);
                                          }
                                          if (value == 1) {
                                            print("notification clicked");
                                            setState(() {
                                              fanAll1 = false;
                                              notifications1 = true;
                                              requests1 = false;
                                            });
                                            setState(() {
                                              friendRequests = List.from(friendRequests1.where((item) => item["title"] != "New Follow Request"));
                                              filteredFriends = List.from(friendRequests1.where((item) => item["title"] != "New Follow Request"));
                                            });
                                            //getRecentComments(widget.postid);
                                          }
                                          if(value == 2){
                                            print("all clicked");
                                            setState(() {
                                              fanAll1 = false;
                                              notifications1 = false;
                                              requests1 = true;
                                            });
                                            setState(() {
                                              friendRequests = List.from(friendRequests1.where((item) => item["title"] == "New Follow Request"));
                                              filteredFriends = List.from(friendRequests1.where((item) => item["title"] == "New Follow Request"));
                                            });
                                            //getRecentComments(widget.postid);
                                          }
                                          setState(() {});
                                          print(value);
                                        },
                                        itemBuilder: (BuildContext bc) {
                                          return [
                                            PopupMenuItem(
                                              value: 0,
                                              child: Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    "All",
                                                    style: fanAll1 == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 1,
                                              child: Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    "Notifications",
                                                    style: notifications1 == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 2,
                                              child: Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    "Requests",
                                                    style: requests1 == true ? TextStyle(fontFamily: Poppins,color: primary) : TextStyle(fontFamily: Poppins),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ];
                                        }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5,),
                      loading ? SpinKitCircle(color: primary,) :
                      friendRequests.isEmpty ? Expanded(
                          child:ListView(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                  Text("No Friend Activities",style: TextStyle(fontFamily: Poppins,fontSize: 20),),
                                ],
                              )
                            ],
                          )) : friendController.text.isEmpty
                          ? Expanded(
                        child: ListView.builder(
                          itemCount: friendRequests.length,
                          itemBuilder: (context, index) {
                            return friendRequests[index]["title"] == "Follow Request Accepted" ? InkWell(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                  id: friendRequests[index]["sender"].toString(),
                                  username: friendRequests[index]["body"].toString().split(" ")[0],
                                ))).then((value){
                                  getProfile();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0,left: 10,right: 10),
                                child: Card(
                                  child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height:50,
                                                width: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius:BorderRadius.all(Radius.circular(30)),
                                                  image: DecorationImage(
                                                      image: NetworkImage(
                                                        friendRequests[index]['data']["pic"] == null ?"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":friendRequests[index]['data']["pic"],
                                                      ),
                                                      fit: BoxFit.cover
                                                  ),
                                                ),
                                                child: Text(""),
                                              ),
                                              SizedBox(width: 10,),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(height: 5,),
                                                  Container(
                                                    width: MediaQuery.of(context).size.width * 0.65,
                                                    child: RichText(
                                                      text: TextSpan(
                                                        text: "${friendRequests[index]["body"].toString().split(" ")[0]}",
                                                        style: TextStyle(fontFamily: Poppins,color: primary,fontSize: 16,fontWeight: FontWeight.bold),
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                            text: " has accepted your friend request.",
                                                            style: TextStyle(fontFamily: Poppins,color: ascent,fontSize: 16),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Container(
                                                      child: Text(
                                                        "${formatTimeDifference(friendRequests[index]["updated"])}",
                                                        style: TextStyle(color: ascent, fontFamily: Poppins,fontSize: 12),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                  ),
                                ),
                              ),
                            ) :
                            InkWell(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                  id: friendRequests[index]["sender"].toString(),
                                  username: friendRequests[index]["body"].toString().split(" ")[0],
                                ))).then((value){
                                  getProfile();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0,left: 10,right: 10),
                                child: Card(
                                  child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height:50,
                                                width: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius:BorderRadius.all(Radius.circular(30)),
                                                  image: DecorationImage(
                                                      image: NetworkImage(
                                                        friendRequests[index]['data']["pic"] == null ?"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":friendRequests[index]['data']["pic"],
                                                      ),
                                                      fit: BoxFit.cover
                                                  ),
                                                ),
                                                child: Text(""),
                                              ),
                                              SizedBox(width: 10,),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(height: 5,),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "${friendRequests[index]['data']["username"].toString().split(" ")[0]}",
                                                        style: TextStyle(fontFamily: Poppins,color: primary,fontSize: 20,fontWeight: FontWeight.bold),
                                                      ),
                                                      SizedBox(width: 10,),
                                                      Container(
                                                        child: Text(
                                                          "${formatTimeDifference(friendRequests[index]["updated"])}",
                                                          style: TextStyle(color: ascent, fontFamily: Poppins,fontSize: 12),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 2,),
                                                  Text(
                                                    Uri.decodeComponent(friendRequests[index]['data']["name"]),
                                                    style: const TextStyle(fontFamily: Poppins,),
                                                  ),
                                                  SizedBox(height: 5,),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  chechFanRequest(friendRequests[index]["sender"].toString(),friendRequests[index]['id']);
                                                  //matchFriendRequest(friendRequests[index]['sender'],friendRequests[index]['id']);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                        backgroundColor: primary,
                                                        content: Text("You have accepted the friend request of ${friendRequests[index]['data']["username"].toString().split(" ")[0]}.",style: TextStyle(color: ascent,fontFamily: Poppins))),
                                                  );
                                                },
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.all(Radius.circular(30))
                                                  ),
                                                  color: secondary,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 8.0,bottom: 8.0),
                                                    child: Icon(Icons.check,color: ascent,),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: (){
                                                  isRejected=true;
                                                  matchFriendRequest(friendRequests[index]['sender'],friendRequests[index]['id']);
                                                },
                                                child: Card(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.all(Radius.circular(30))
                                                  ),
                                                  color: primary,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 8.0,bottom: 8.0),
                                                    child: Icon(Icons.close,color: ascent,),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                          :(
                          filteredFriends.isNotEmpty
                              ? Expanded(
                            child: ListView.builder(
                              itemCount: filteredFriends.length,
                              itemBuilder: (context, index) {
                                return filteredFriends[index]["title"] == "Follow Request Accepted" ? InkWell(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                      id: filteredFriends[index]["sender"].toString(),
                                      username: filteredFriends[index]["body"].toString().split(" ")[0],
                                    ))).then((value){
                                      getProfile();
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 1.0,left: 10,right: 10),
                                    child: Card(
                                      child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          margin: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    height:50,
                                                    width: 50,
                                                    decoration: BoxDecoration(
                                                      borderRadius:BorderRadius.all(Radius.circular(30)),
                                                      image: DecorationImage(
                                                          image: NetworkImage(
                                                            filteredFriends[index]['data']["pic"] == null ?"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":friendRequests[index]['data']["pic"],
                                                          ),
                                                          fit: BoxFit.cover
                                                      ),
                                                    ),
                                                    child: Text(""),
                                                  ),
                                                  SizedBox(width: 10,),
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SizedBox(height: 5,),
                                                      Container(
                                                        width: MediaQuery.of(context).size.width * 0.65,
                                                        child: RichText(
                                                          text: TextSpan(
                                                            text: "${filteredFriends[index]["body"].toString().split(" ")[0]}",
                                                            style: TextStyle(fontFamily: Poppins,color: primary,fontSize: 16,fontWeight: FontWeight.bold),
                                                            children: <TextSpan>[
                                                              TextSpan(
                                                                text: " has accepted your friend request.",
                                                                style: TextStyle(fontFamily: Poppins,color: ascent,fontSize: 16),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 4.0),
                                                        child: Container(
                                                          child: Text(
                                                            "${formatTimeDifference(filteredFriends[index]["updated"])}",
                                                            style: TextStyle(color: ascent, fontFamily: Poppins,fontSize: 12),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                      ),
                                    ),
                                  ),
                                ) :
                                InkWell(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(
                                      id: filteredFriends[index]["sender"].toString(),
                                      username: filteredFriends[index]["body"].toString().split(" ")[0],
                                    ))).then((value){
                                      getProfile();
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 1.0,left: 10,right: 10),
                                    child: Card(
                                      child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          margin: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    height:50,
                                                    width: 50,
                                                    decoration: BoxDecoration(
                                                      borderRadius:BorderRadius.all(Radius.circular(30)),
                                                      image: DecorationImage(
                                                          image: NetworkImage(
                                                            filteredFriends[index]['data']["pic"] == null ?"https://firebasestorage.googleapis.com/v0/b/fashiontime-28e3a.appspot.com/o/WhatsApp_Image_2023-11-08_at_4.48.19_PM-removebg-preview.png?alt=media&token=215bdc12-d53a-4772-bca1-efbbdf6ee955&_gl=1*nea8nk*_ga*NDIyMTUzOTQ2LjE2OTkyODU3MDg.*_ga_CW55HF8NVT*MTY5OTQ0NDE2NS4zMy4xLjE2OTk0NDUxNzcuNTYuMC4w":filteredFriends[index]['data']["pic"],
                                                          ),
                                                          fit: BoxFit.cover
                                                      ),
                                                    ),
                                                    child: Text(""),
                                                  ),
                                                  SizedBox(width: 10,),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SizedBox(height: 5,),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "${filteredFriends[index]['data']["username"].toString().split(" ")[0]}",
                                                            style: TextStyle(fontFamily: Poppins,color: primary,fontSize: 20,fontWeight: FontWeight.bold),
                                                          ),
                                                          SizedBox(width: 10,),
                                                          Container(
                                                            child: Text(
                                                              "${formatTimeDifference(filteredFriends[index]["updated"])}",
                                                              style: TextStyle(color: ascent, fontFamily: Poppins,fontSize: 12),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 2,),
                                                      Text(
                                                        Uri.decodeComponent(filteredFriends[index]['data']["name"]),
                                                        style: const TextStyle(fontFamily: Poppins,),
                                                      ),
                                                      SizedBox(height: 5,),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      matchFriendRequest(filteredFriends[index]['sender'],filteredFriends[index]['id']);
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                            backgroundColor: primary,
                                                            content: Text("You have accepted the friend request of ${filteredFriends[index]['data']["username"].toString().split(" ")[0]}.",style: TextStyle(color: ascent,fontFamily: Poppins))),
                                                      );
                                                    },
                                                    child: Card(
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(30))
                                                      ),
                                                      color: secondary,
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 8.0,bottom: 8.0),
                                                        child: Icon(Icons.check,color: ascent,),
                                                      ),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: (){
                                                      isRejected=true;
                                                      matchFriendRequest(filteredFriends[index]['sender'],filteredFriends[index]['id']);
                                                    },
                                                    child: Card(
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(30))
                                                      ),
                                                      color: primary,
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 8.0,bottom: 8.0),
                                                        child: Icon(Icons.close,color: ascent,),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                              : Expanded(child:ListView(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                  Text("No Friend Activities",style: TextStyle(fontFamily: Poppins,fontSize: 20),),
                                ],
                              )
                            ],
                          ))
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
