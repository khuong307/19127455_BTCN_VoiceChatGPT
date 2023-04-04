class ChatMessage {
  ChatMessage({required this.text, required this.type, required this.time});
  String? text;
  int type;
  String? time;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'time': time,
      'content': text,
      'type': type,
    };
    return map;
  }
}
