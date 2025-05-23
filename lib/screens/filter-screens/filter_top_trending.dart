import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import '../../animations/bottom_animation.dart';
import '../../utils/constants.dart';

class TopTrendingFilterScreen extends StatefulWidget {
  const TopTrendingFilterScreen({super.key});

  @override
  State<TopTrendingFilterScreen> createState() =>
      _TopTrendingFilterScreenState();
}

List<dynamic> responseData = [];
List<String> items = [];
List<String> eventYear = [];
String? selectedEvent;
String? selectedYear;
bool loading = false;

class _TopTrendingFilterScreenState extends State<TopTrendingFilterScreen> {
  getCachedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    selectedYear = preferences.getString('selectedYear');
    selectedEvent = preferences.getString('selectedEvent');
    debugPrint(
        "saved event and year was===========> $selectedEvent $selectedYear");
    getAllEvents();
  }

  getAllEvents() async {
    try {
      loading = true;
      final response = await https.get(Uri.parse("$serverUrl/fashionEvents/"));
      if (response.statusCode == 200) {
        responseData = jsonDecode(response.body);
        if (responseData.isNotEmpty) {
          debugPrint("get all events data $responseData");
          setState(() {
            loading = false;
            items =
                responseData.map<String>((event) => event["title"]).toList();
            eventYear =
                responseData.map<String>((event) => event['created']).toList();
            debugPrint("total events====>${items.length}");
            debugPrint("events created time ====>$eventYear");
          });
        }
      } else {
        debugPrint("Error in all event api:${response.statusCode}");
        loading = false;
      }
    } catch (e) {
      loading = false;
      debugPrint(" all events api didn't hit $e");
    }
  }

  void saveYear(String label) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedYear', label);
  }

  void saveEvent(String label) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedEvent', label);
  }

  void clearFilterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('selectedYear');
    prefs.remove('selectedEvent');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCachedData();
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
            "Filter on trending styles",
            style: TextStyle(color: Colors.white, fontFamily: Poppins),
          ),
        ),
        body: loading
            ? SpinKitCircle(
                color: primary,
              )
            : Center(
                child: ListView(children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.08,
                ),
                WidgetAnimator(
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 18.0, right: 18.0, top: 5, bottom: 15),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Select event year",
                          style: TextStyle(
                              color: primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: Poppins),
                        )
                      ],
                    ),
                  ),
                ),
                WidgetAnimator(
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: SizedBox(
                      height: 60,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primary, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primary, width: 1),
                          ),
                        ),
                        isExpanded: true,
                        value: eventYear.isNotEmpty ? eventYear[0] : null,
                        items: eventYear
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              DateTime.parse(value).year.toString(),
                              style: TextStyle(
                                  fontSize: 15, color: primary, fontFamily: Poppins),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedYear = newValue!;
                            debugPrint("selected year is=========>$selectedYear");
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.01,
                ),
                WidgetAnimator(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 15,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                WidgetAnimator(
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 18.0, right: 18.0, top: 25, bottom: 18),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Select fashion event",
                          style: TextStyle(
                              color: primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: Poppins),
                        )
                      ],
                    ),
                  ),
                ),
                  WidgetAnimator(
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      child: SizedBox(
                        height: 60,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primary, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primary, width: 1),
                            ),
                          ),
                          isExpanded: true,
                          value: selectedEvent,
                          items: items
                              .toSet()
                              .toList() // Use toSet() to remove duplicates
                              .asMap()
                              .entries
                              .map<DropdownMenuItem<String>>((entry) {
                            int index = entry.key;
                            String value = entry.value;
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Text(
                                    'Week ${index + 1}: ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: primary,
                                      fontFamily: Poppins,
                                    ),
                                  ),
                                  Text(
                                    value,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: primary,
                                      fontFamily: Poppins,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                              .toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedEvent = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.27,
                ),
                TextButton(
                    onPressed: () {
                      clearFilterData();
                      debugPrint(
                          "selected data is ==========>$selectedEvent $selectedYear");
                    },
                    child: Text(
                      "Remove Filter",
                      style: TextStyle(
                          color: primary,
                          fontFamily: Poppins,
                          fontSize: 16,
                          decoration: TextDecoration.underline),
                    )),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.03,
                ),
                GestureDetector(
                  onTap: () {
                    saveEvent(selectedEvent!);
                    saveYear(selectedYear!);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      child: Container(
                        alignment: Alignment.center,
                        height: 35,
                        width: MediaQuery.of(context).size.width * 0.7,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.topRight,
                                stops: const [0.0, 0.99],
                                tileMode: TileMode.clamp,
                                colors: <Color>[
                                  secondary,
                                  primary,
                                ]),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(12))),
                        child: const Text(
                          'Apply Filter',
                          style: TextStyle(
                              color: ascent,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: Poppins),
                        ),
                      ),
                    ),
                  ),
                ),
              ])));
  }
}
