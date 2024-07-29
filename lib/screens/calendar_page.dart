import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/workout.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Box<Workout> workoutBox;
  late List<Workout> completedWorkouts;
  late List<Appointment> appointments;

  @override
  void initState() {
    super.initState();
    workoutBox = Hive.box<Workout>('workoutBox');
    _loadCompletedWorkouts();
  }

  void _loadCompletedWorkouts() {
    completedWorkouts = workoutBox.values.where((workout) => workout.completed).toList().cast<Workout>();
    _generateAppointments();
  }

  void _generateAppointments() {
    appointments = completedWorkouts.map((workout) {
      final DateTime date = DateTime.fromMillisecondsSinceEpoch(workout.lastTrained!).toLocal();
      return Appointment(
        startTime: date,
        endTime: date.add(const Duration(hours: 1)),
        subject: workout.title,
        color: Colors.blue,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Workouts Calendar'),
      ),
      body: SfCalendar(
        view: CalendarView.month,
        dataSource: WorkoutDataSource(appointments),
        monthViewSettings: const MonthViewSettings(
          showAgenda: true,
          agendaViewHeight: 200,
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        ),
      ),
    );
  }
}

class WorkoutDataSource extends CalendarDataSource {
  WorkoutDataSource(List<Appointment> source) {
    appointments = source;
  }
}
