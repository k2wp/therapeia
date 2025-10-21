// Contains shared models for doctor's schedule functionality

class ScheduleEntry {
  final String day;
  final List<TimeSlot> timeSlots;

  ScheduleEntry({required this.day, required this.timeSlots});

  // Create a copy of this entry with new time slots
  ScheduleEntry copyWith({List<TimeSlot>? timeSlots}) {
    return ScheduleEntry(
      day: day,
      timeSlots: timeSlots ?? List.from(this.timeSlots),
    );
  }
}

class TimeSlot {
  String time; // Mutable to allow editing
  String location;

  TimeSlot({required this.time, required this.location});

  // Create a copy of this time slot with optional new values
  TimeSlot copyWith({String? time, String? location}) {
    return TimeSlot(
      time: time ?? this.time,
      location: location ?? this.location,
    );
  }
}
