import 'dart:convert';

import 'package:finalfashiontimefrontend/animations/bottom_animation.dart';
import 'package:finalfashiontimefrontend/models/fashion_week_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart'as https;
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
class AllFashionWeeks extends StatefulWidget {
  final int myIndex;
  final Function navigateTo;
  const AllFashionWeeks({super.key, required this.myIndex, required this.navigateTo});

  @override
  State<AllFashionWeeks> createState() => _AllFashionWeeksState();
}
List<FashionEvent> events = [];
bool loading =false;

class _AllFashionWeeksState extends State<AllFashionWeeks> {
  getAllEvents(){
    const String url='$serverUrl/fashionEvents/';
    try{
      loading=true;
      https.get(Uri.parse(url) ).then((value) {
        debugPrint("the body of response is=========> ${value.body}");
        setState(() {
          loading=false;
        });
        List<dynamic> eventData = json.decode(value.body);
        List<FashionEvent> eventsList = eventData.map((event) {
          return FashionEvent(
            id: event['id'],
            title: event['title'],
            eventStartDate: event['eventStartDate'],
            eventEndDate: event['eventEndDate'],
          );
        }).toList();
        events=eventsList;
        debugPrint("events length is ${events.length}");

      });


    }
    catch(e){
      debugPrint("error received while getting events");
      setState(() {
        loading=false;
      });
    }
  }
  String formatDateWithOrdinal(String inputDate) {
    DateTime dateTime = DateTime.parse(inputDate);
    String formattedDate = DateFormat('MMMM d\'\'\'\' yyyy').format(dateTime);
    return formattedDate;
  }
  bool isCurrentDateInRange(String startDate, String endDate) {
    DateTime currentDate = DateTime.now();
    DateTime startDateTime = DateTime.parse(startDate);
    DateTime endDateTime = DateTime.parse(endDate);

    return currentDate.isAfter(startDateTime) && currentDate.isBefore(endDateTime);
  }
  bool isNextWeekEvent(String startDate) {
    DateTime currentDate = DateTime.now();
    DateTime startDateTime = DateTime.parse(startDate);
    DateTime nextWeekStart = DateTime(currentDate.year, currentDate.month, currentDate.day + (DateTime.sunday - currentDate.weekday) + 1);
    DateTime nextWeekEnd = nextWeekStart.add(const Duration(days: 7));
    return startDateTime.isAfter(nextWeekStart) && startDateTime.isBefore(nextWeekEnd);
  }
  @override
  void initState() {

    super.initState();
    getAllEvents();
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        print("Swapping pop");
        widget.navigateTo(widget.myIndex);
        return Future.value(false);
      },
      child: Scaffold(
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
        //             ])
        //     ),),
        //   title: const Text('Events',style: TextStyle(
        //     fontFamily: Poppins,
        //   ),),
        // ),
        body:
            loading?
               Center(child:SpinKitCircle(
                 color: primary,
                 size: 50,
               )):
        ListView.builder(
          itemCount: events.length,
          reverse: false,
          itemBuilder:(context, index){
            return WidgetAnimator(Card(
              color:
              isCurrentDateInRange(events[index].eventStartDate,events[index].eventEndDate)?Colors.blue:
              primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)
              ),
              child: ListTile(

                title:
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("Week ${index+1}: ",style:const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: Poppins,
                                color: ascent
                            )),
                        Flexible(
                          child: Text(events[index].title,style:const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: Poppins,
                              color: ascent
                          )),
                        )
                      ],
                    ),
                    isCurrentDateInRange(events[index].eventStartDate,events[index].eventEndDate)?
                    const Text("(Current Event) ",style:TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: Poppins,
                        color: ascent
                    ))
                        :
                    isNextWeekEvent(events[index].eventStartDate)?const Text("(Next Event) ",style:TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: Poppins,
                        color: ascent
                        )):const SizedBox()
                  ],
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    Text(formatDateWithOrdinal(events[index].eventStartDate),style:const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: Poppins,
                        color: ascent
                    )),
                  ],
                ),
              ),
            ));
        },),
      ),
    );
  }
}
