import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Event {
  final String title;

  Event({required this.title});
}

class Calendar extends StatefulWidget {
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late Map<DateTime, List<Event>> selectedEvents;
  CalendarFormat format = CalendarFormat.month;
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  TextEditingController _eventController = TextEditingController();
  TextEditingController _editEventController = TextEditingController();

  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
  }

  Future<void> initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    loadEvents();
  }

  void loadEvents() {
    setState(() {
      selectedEvents = Map<DateTime, List<Event>>.from(
        (json.decode(_prefs.getString('events') ?? '{}') as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            DateTime.parse(key),
            (value as List<dynamic>).map((e) => Event(title: e['title'])).toList(),
          ),
        ),
      );
    });
  }

  void saveEvents() {
    _prefs.setString('events', json.encode(selectedEvents.map((key, value) {
      return MapEntry(
        key.toIso8601String(),
        value.map((e) => {'title': e.title}).toList(),
      );
    })));
  }

  void _editEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Event"),
        content: TextFormField(
          controller: _editEventController..text = event.title,
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Ok"),
            onPressed: () {
              if (_editEventController.text.isNotEmpty) {
                setState(() {
                  final List<Event>? events = selectedEvents[selectedDay];
                  if (events != null) {
                    final index = events.indexOf(event);
                    if (index != -1) {
                      events[index] = Event(title: _editEventController.text);
                      selectedEvents[selectedDay] = events;
                    }
                  }
                });
                saveEvents();
              }
              Navigator.pop(context);
              _editEventController.clear();
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _getEventsfromDay(DateTime date) {
    final events = selectedEvents[date];
    final List<Widget> widgets = [];

    if (events != null) {
      widgets.addAll(
        events.map((Event event) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2.0),
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.green.withOpacity(0.1),
            ),
            child: ListTile(
              title: Text(event.title),
              tileColor: Colors.transparent,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _editEvent(event),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        selectedEvents[selectedDay]?.remove(event);
                      });
                      saveEvents();
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: selectedDay,
            firstDay: DateTime(1990),
            lastDay: DateTime(2050),
            calendarFormat: format,
            onFormatChanged: (CalendarFormat _format) {
              setState(() {
                format = _format;
              });
            },
            startingDayOfWeek: StartingDayOfWeek.sunday,
            daysOfWeekVisible: true,
            onDaySelected: (DateTime selectDay, DateTime focusDay) {
              setState(() {
                selectedDay = selectDay;
                focusedDay = focusDay;
              });
            },
            selectedDayPredicate: (DateTime date) {
              return isSameDay(selectedDay, date);
            },
            eventLoader: _getEventsfromDay,
            calendarStyle: CalendarStyle(
              isTodayHighlighted: true,
              selectedDecoration: BoxDecoration(
                color: Color.fromARGB(255, 0, 205, 31),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0),
              ),
              selectedTextStyle: TextStyle(color: Colors.white),
              todayDecoration: BoxDecoration(
                color: Colors.purpleAccent,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0),
              ),
              defaultDecoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0),
                color: Colors.white, // เพิ่มสีพื้นหลังของทุกวัน
              ),
              weekendDecoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5.0),
                color: Colors.grey[300], // เพิ่มสีพื้นหลังของวันเสาร์-อาทิตย์
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(5.0),
              ),

            ),
          ),
          ..._getEventsfromDay(selectedDay),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Add Event"),
              content: TextFormField(
                controller: _eventController,
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text("Ok"),
                  onPressed: () {
                    if (_eventController.text.isNotEmpty) {
                      setState(() {
                        selectedEvents[selectedDay] = [
                          ...(selectedEvents[selectedDay] ?? []),
                          Event(title: _eventController.text),
                        ];
                      });
                      saveEvents();
                    }
                    Navigator.pop(context);
                    _eventController.clear();
                  },
                ),
              ],
            ),
          );
        },
        label: Text("Add Event"),
        icon: Icon(Icons.add),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Calendar(),
  ));
}
