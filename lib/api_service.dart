import 'dart:convert';

import 'package:http/http.dart' as http;

String api_key = "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";

class ApiService {
  static String url = "https://api.openai.com/v1/chat/completions";
  static Map<String, String> header = {
    "Content-Type": 'application/json; charset=utf-8',
    "Authorization": "Bearer $api_key",
  };

  static sendMessage(String? message) async {
    var res = await http.post(Uri.parse(url),
        headers: header,
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "user", "content": '$message'}
          ],
          "temperature": 0,
          "max_tokens": 100,
        }));

    if (res.statusCode == 200) {
      var data = jsonDecode(utf8.decode(res.bodyBytes));
      var msg = data['choices'][0]["message"]["content"];
      return msg.trim().replaceAll(RegExp(r'(\n){3,}'), "\n\n");
    } else {
      return "API Error!";
    }
  }
}
