import 'dart:convert';

import 'package:http/http.dart' as http;

import 'gpt_conversation.dart';

String api_key = "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";

class ApiService {
  static String url = "https://api.openai.com/v1/chat/completions";
  static Map<String, String> header = {
    "Content-Type": 'application/json; charset=utf-8',
    "Authorization": "Bearer $api_key",
    "OpenAI-Organization": "org-UzPcqcOqAfSdQKCTL9XXwCDK"
  };

  static sendMessage(
      String? message, List<Map<String, dynamic>> gpt_conver) async {
    Map<String, dynamic> user = {'role': 'user', 'content': message};
    gpt_conver.add(user);
    var res = await http.post(Uri.parse(url),
        headers: header,
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": gpt_conver,
          "temperature": 0,
          "max_tokens": 100,
        }));

    if (res.statusCode == 200) {
      var data = jsonDecode(utf8.decode(res.bodyBytes));
      var msg = data['choices'][0]["message"]["content"];
      Map<String, dynamic> server = {'role': 'assistant', 'content': msg};
      gpt_conver.add(server);
      return msg;
      // return msg.trim().replaceAll(RegExp(r'(\n){3,}'), "\n\n");
    } else {
      return "API Error!";
    }
  }
}
