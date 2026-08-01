class DeveloperMessage {
  final String version;
  final String date;
  final String title;
  final String body;

  const DeveloperMessage({
    required this.version,
    required this.date,
    required this.title,
    required this.body,
  });

  factory DeveloperMessage.fromJson(Map<String, dynamic> json) {
    return DeveloperMessage(
      version: json['version'] as String,
      date: json['date'] as String,
      title: json['title'] as String,
      body: (json['body'] as List).cast<String>().join('\n'),
    );
  }
}
