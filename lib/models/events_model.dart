import 'dart:ui';

class EventsModel {
  EventsModel(
      {this.eventName,
        this.from,
        this.to,
        this.background,
        this.allDay = false});

  String? eventName;
  DateTime? from;
  DateTime? to;
  Color? background;
  bool? allDay;
}