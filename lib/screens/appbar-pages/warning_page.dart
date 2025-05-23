import 'dart:convert';
import 'package:finalfashiontimefrontend/models/Warning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as https;
import '../../../utils/constants.dart';

class WarningPage extends StatefulWidget {
  const WarningPage({super.key});

  @override
  State<WarningPage> createState() => _WarningPageState();
}

class _WarningPageState extends State<WarningPage> {

  String id = "";
  String token = "";
  bool loading = false;
  List<Warning> warnings = [];

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
    getWarnings();
  }

  getWarnings(){
    setState(() {
      loading = true;
    });
    warnings.clear();
    https.get(
      Uri.parse("$serverUrl/apiwarnings/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).then((value){
      print(value.body.toString());
      var responseData = jsonDecode(value.body);
      responseData.forEach((e){
        setState(() {
          warnings.add(Warning(
              e["id"].toString(),
              e["title"],
              e["message"],
              e["created_at"]
          ));
        });
      });
      setState(() {
        loading = false;
      });
    }).catchError((e){
      setState(() {
        loading = false;
      });
    });
  }

  String formatNotificationTime(String rawTime) {
    DateTime notificationTime = DateTime.parse(rawTime).toLocal();
    DateTime now = DateTime.now();

    // Calculate the difference in days
    int differenceInDays = now.difference(notificationTime).inDays;

    // Format the time using RelativeDateFormat if it's less than a week
    if (differenceInDays == 0) {
      return DateFormat('MM/dd/yyyy ').format(notificationTime);
    } else if (differenceInDays == 1) {
      return 'Yesterday.';
    }
    else {
      return DateFormat('MM/dd/yyyy ').format(notificationTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      //   backgroundColor: primary,
      //   title: const Text(
      //     "Warnings",
      //     style: TextStyle(fontFamily: Poppins,),
      //   ),
      // ),
      body: loading == true
          ? SpinKitCircle(
        color: primary,
        size: 50,
      )
          : (warnings.isEmpty
          ? const Center(
        child: Text("No Warnings",style: TextStyle(fontFamily: Poppins,),),
      )
          : ListView.builder(
          itemCount: warnings.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(
                  left: 10.0, right: 10.0, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: () {
                },
                child: Card(
                  elevation: 5,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                          Radius.circular(20))),
                  child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary,
                        child: Container(
                          decoration: const BoxDecoration(
                              borderRadius:
                              BorderRadius.all(
                                  Radius.circular(
                                      120))),
                          child: const ClipRRect(
                            borderRadius:
                            BorderRadius.all(
                                Radius.circular(120)),
                            child: Icon(Icons.warning,color: Colors.white,),
                          ),
                        )
                      ),
                      title: Text(
                        warnings[index].title,
                        style: TextStyle(
                            color: primary,
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                          fontFamily: Poppins,),
                      ),
                      subtitle: Text(
                        warnings[index].message,
                        style: TextStyle(
                            color: primary,
                            fontSize: 13,
                          fontFamily: Poppins,),
                      ),
                      trailing: Text(
                          formatNotificationTime(warnings[index].time),
                          style: const TextStyle(
                            fontFamily: Poppins,))),
                ),
              ),
            );
          })),
    );
  }
}
