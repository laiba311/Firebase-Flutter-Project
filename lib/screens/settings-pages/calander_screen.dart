import 'dart:convert';
import 'dart:math';
import 'package:finalfashiontimefrontend/models/events_model.dart';
import 'package:http/http.dart' as https;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../utils/constants.dart';

class CalenderScreen extends StatefulWidget {
  const CalenderScreen({Key? key}) : super(key: key);

  @override
  State<CalenderScreen> createState() => _CalenderScreenState();
}

class _CalenderScreenState extends State<CalenderScreen> {
  final List<Color> _colorCollection=<Color>[
    const Color(0xFF0F8644),
    const Color(0xFF8B1FA9),
    const Color(0xFFD20100),
    const Color(0xFFFC571D),
    const Color(0xFF36B37B),
    const Color(0xFF01A1EF),
    const Color(0xFF3D4FB5),
    const Color(0xFFE47C73),
    const Color(0xFF636363),
    const Color(0xFF0A8043)
  ];
  final List<EventsModel> appointmentData = [
  ];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDataFromWeb1();
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
                  ])
          ),),
        title: const Text('Events',style: TextStyle(
          fontFamily: Poppins,
        ),),
      ),
      body: Container(
          child: appointmentData != null ?SafeArea(
            child: Container(
                child: SfCalendar(
                  timeSlotViewSettings: const TimeSlotViewSettings(allDayPanelColor: Colors.pink),
                  todayHighlightColor: primary,
                  view: CalendarView.week,
                  initialDisplayDate: DateTime.now(),
                  appointmentTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                  allowAppointmentResize: true,
                  dataSource: MeetingDataSource(appointmentData),
                  onTap:
                      (details){
                    details.appointments!.isEmpty?
                    showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: primary,
                      title: const Text("Fashion Event",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                      content: const Text("Please Select date with Events!",style: TextStyle(color: ascent,fontFamily: Poppins,),),
                      actions: [
                        TextButton(
                          child: const Text("OK",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                          onPressed:  () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    ):

                    // print("details data");
                    // print(details.appointments);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: primary,
                        title: const Text("Fashion Event",style: TextStyle(color: ascent,fontFamily: Poppins,fontWeight: FontWeight.bold),),
                        content: Text(details.appointments!.first.eventName,style: const TextStyle(color: ascent,fontFamily: Poppins,),),
                        actions: [
                          TextButton(
                            child: const Text("OK",style: TextStyle(color: ascent,fontFamily: Poppins,)),
                            onPressed:  () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                )),
          ):Container(
            child: Center(
              child: SizedBox(
                  height: 80,
                  child: SpinKitRipple(color: primary,size: 80,)),
            ),
          )
      ),
    );
  }

  Future<List<EventsModel>> getDataFromWeb() async {
    var json = await https.get(
        Uri.parse("$serverUrl/fashionEvents/")
    );
    print(json);
    var jsonData = jsonDecode(json.body);
    final List<EventsModel> appointmentData = [];
    final Random random = Random();
    for (var data in jsonData) {
      EventsModel meetingData = EventsModel(
          eventName: data['title'],
          from: _convertDateFromString(
            data['eventStartDate'],
          ),
          to: _convertDateFromString(data['eventEndDate']),
          background: primary,
         // allDay: data['allDay']
      );
      appointmentData.add(meetingData);
    }
    print(appointmentData);
    return appointmentData;
  }

  getDataFromWeb1() async {
    var json = await https.get(
        Uri.parse("$serverUrl/fashionEvents/")
    );
    print(json);
    var jsonData = jsonDecode(json.body);
    for (var data in jsonData) {
      EventsModel meetingData = EventsModel(
          eventName: data['title'],
          from: _convertDateFromString(
            data['eventStartDate'],
          ),
          to: _convertDateFromString(data['eventEndDate']),
          background: primary,
          allDay: true);
      setState(() {
        appointmentData.add(meetingData);
      });
    }
    print(appointmentData);
  }


  DateTime _convertDateFromString(String date) {
    return DateTime.parse(date);
  }

  void _initializeEventColor() {
    _colorCollection.add(const Color(0xFF0F8644));
    _colorCollection.add(const Color(0xFF8B1FA9));
    _colorCollection.add(const Color(0xFFD20100));
    _colorCollection.add(const Color(0xFFFC571D));
    _colorCollection.add(const Color(0xFF36B37B));
    _colorCollection.add(const Color(0xFF01A1EF));
    _colorCollection.add(const Color(0xFF3D4FB5));
    _colorCollection.add(const Color(0xFFE47C73));
    _colorCollection.add(const Color(0xFF636363));
    _colorCollection.add(const Color(0xFF0A8043));
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<EventsModel> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].allDay;
  }
}

