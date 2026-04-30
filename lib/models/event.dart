class Event {
  final DateTime date;
  final String text;
  final String squad;
  final String time;
  final bool isLocal;

  Event({
    required this.date,
    required this.text,
    required this.squad,
    required this.time,
    this.isLocal = false,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'text': text,
    'squad': squad,
    'time': time,
    'isLocal': isLocal,
  };

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      date: DateTime.parse(json['date']),
      text: json['text'],
      squad: json['squad'],
      time: json['time'],
      isLocal: json['isLocal'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          text == other.text &&
          squad == other.squad &&
          time == other.time &&
          isLocal == other.isLocal;

  @override
  int get hashCode =>
      date.hashCode ^ text.hashCode ^ squad.hashCode ^ time.hashCode ^ isLocal.hashCode;
}