import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:voice_chatgpt/api_service.dart';
import 'package:voice_chatgpt/chat_modal.dart';
import 'package:voice_chatgpt/colors.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:voice_chatgpt/animation_row.dart';
import 'dart:developer';
import 'package:voice_chatgpt/sqlLite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_circle_flags_svg/flutter_circle_flags_svg.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  SpeechToText speechToText = SpeechToText();
  var text = '';
  final TextEditingController _controller = TextEditingController();
  var isListening = false;
  List<ChatMessage> messages = [];
  FlutterTts flutterTts = FlutterTts();

  String? selectedLanguage = "vi";
  bool isAuto = true;
  _speak(String text) async {
    await flutterTts.setLanguage(selectedLanguage.toString());
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  late DBHelper dbHelper;
  @override
  void initState() {
    super.initState();
    dbHelper = DBHelper();
    fetchData();
  }

  Future<void> fetchData() async {
    await dbHelper.getChatMessage().then((value) async {
      for (int i = 0; i < value.length; i++) {
        ChatMessage previousChat = ChatMessage(
          text: value[i]["content"],
          time: value[i]["time"],
          type: value[i]["type"],
        );
        setState(() {
          print(previousChat);
          messages.add(previousChat);
        });
      }
    });
  }

  var scrollController = ScrollController();
  void _showAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert!',
              style: TextStyle(
                fontFamily: 'MotirawBlack',
                decoration: TextDecoration.underline,
              )),
          content: Text('Start typing or talking ...',
              style: TextStyle(
                fontFamily: 'WorkSans',
              )),
          actions: [
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(fontFamily: 'MotirawBlack', color: bgColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showMiddleModal(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: chatbgColor.withOpacity(0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    bgColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontFamily: 'WorkSans', fontSize: 20),
                )
              ],
            )),
          ),
        );
      },
    );
  }

  scrollMethod() {
    scrollController.animateTo(scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 2000), curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
        floatingActionButton: AvatarGlow(
          glowColor: bgColor,
          endRadius: 90.0,
          duration: Duration(milliseconds: 2000),
          repeat: true,
          showTwoGlows: true,
          animate: isListening,
          repeatPauseDuration: Duration(milliseconds: 100),
          child: Material(
            // Replace this child with your own
            elevation: 8.0,
            shape: CircleBorder(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: GestureDetector(
                onTapDown: (details) async {
                  if (!isListening) {
                    var available = await speechToText.initialize();
                    if (available) {
                      setState(() {
                        isListening = true;
                        speechToText.listen(onResult: (result) {
                          setState(() {
                            text = result.recognizedWords;
                            _controller.text = text;
                          });
                        });
                      });
                    }
                  }
                },
                onTapUp: (details) async {
                  _showMiddleModal(context, "Responding ...");
                  setState(() {
                    isListening = false;
                    speechToText.stop();
                  });

                  if (text != "") {
                    ChatMessage userText = ChatMessage(
                        text: text,
                        type: 1,
                        time: DateFormat('dd/MM/yyyy HH:mm:ss')
                            .format(DateTime.now()));
                    messages.add(userText);

                    await dbHelper.save(userText);

                    var msg = await ApiService.sendMessage(text);

                    ChatMessage serverText = ChatMessage(
                        text: msg,
                        type: 2,
                        time: DateFormat('dd/MM/yyyy HH:mm:ss')
                            .format(DateTime.now()));
                    setState(() {
                      messages.add(serverText);
                    });

                    if (isAuto == true) {
                      _speak(msg);
                    }
                    Navigator.pop(context);
                    await dbHelper.save(serverText).then((value) {
                      scrollMethod();
                    });
                  }
                },
                child: CircleAvatar(
                  backgroundColor: bgColor,
                  radius: 20,
                  child: Icon(isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white),
                ),
              ), // circleAvatar
            ), // ClipRRect
          ), // Material
        ),
        appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      'https://i.pinimg.com/736x/11/f9/a5/11f9a5a6964e12ab91ef242773fc8377.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            centerTitle: true,
            backgroundColor: bgColor,
            elevation: 0.0,
            title: const Text(
              "D.O. Learning",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MotirawBlack',
                  color: textColor),
            )),
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      'https://i.pinimg.com/564x/37/ce/e5/37cee5788ae8f376938cfe18d7f9a615.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(children: [
                Container(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.restart_alt, color: Colors.white),
                          TextButton(
                            child: Text('Clear Conversation',
                                style: TextStyle(
                                    fontFamily: 'WorkSans', fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              setState(() {
                                messages.clear();
                              });
                              await dbHelper.clearTable();
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        color: Color(0xfff5df90),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: DropdownButton<String>(
                          value: selectedLanguage,
                          dropdownColor: Colors.white,
                          items: [
                            DropdownMenuItem(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'English  ',
                                    style: TextStyle(
                                        fontFamily: 'WorkSans', fontSize: 12),
                                  ),
                                  ClipOval(
                                    child: Image.network(
                                      "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/383px-Flag_of_the_United_States.svg.png",
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                              value: 'en-US',
                            ),
                            DropdownMenuItem(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Vietnamese  ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'WorkSans',
                                    ),
                                  ),
                                  ClipOval(
                                    child: Image.network(
                                      "https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/Flag_of_Vietnam.svg/2000px-Flag_of_Vietnam.svg.png",
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                              value: 'vi',
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedLanguage = value;
                            });
                          }),
                    ),
                    Switch(
                      // This bool value toggles the switch.
                      value: isAuto,
                      activeColor: bgColor,
                      onChanged: (bool value) {
                        // This is called when the user toggles the switch.
                        setState(() {
                          isAuto = value;
                        });
                      },
                    )
                  ],
                )),
                const SizedBox(height: 15),
                Container(
                    height: 400,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: chatbgColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      controller: scrollController,
                      shrinkWrap: true,
                      itemCount: messages.length,
                      itemBuilder: (BuildContext context, int index) {
                        var current_mess = messages[index];
                        return ChatBubble(
                            chattext: current_mess.text,
                            type: current_mess.type,
                            time: current_mess.time);
                      },
                    )),
                Container(
                    margin: EdgeInsets.only(top: 10),
                    padding: EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: TextStyle(
                                fontFamily: 'WorkSans',
                                color: Colors.black,
                                fontSize: 15),
                            decoration: InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0),
                                    width: 2.0),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: bgColor.withOpacity(0), width: 2.0),
                              ),
                              hintText: 'Start typing or talking',
                            ),
                          ),
                        ),
                        IconButton(
                          iconSize: 20,
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            if (_controller.text == "") {
                              _showAlert(context);
                            } else {
                              _showMiddleModal(context, "Responding ...");
                              ChatMessage userText = ChatMessage(
                                  text: _controller.text,
                                  type: 1,
                                  time: DateFormat('dd/MM/yyyy HH:mm:ss')
                                      .format(DateTime.now()));

                              await dbHelper.save(userText);
                              setState(() {
                                messages.add(userText);
                              });

                              var msg = await ApiService.sendMessage(
                                  _controller.text);

                              ChatMessage serverText = ChatMessage(
                                  text: msg,
                                  type: 2,
                                  time: DateFormat('dd/MM/yyyy HH:mm:ss')
                                      .format(DateTime.now()));

                              await dbHelper.save(serverText).then((value) {
                                scrollMethod();
                              });

                              setState(() {
                                messages.add(serverText);
                              });
                              if (isAuto == true) {
                                _speak(msg);
                              }
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    )),
              ])),
        ));
  }

  Widget ChatBubble({required chattext, required int type, required time}) {
    if (type == 1) {
      return Row(
        children: [
          ClipOval(
            child: Image.network(
              "https://z-p4-instagram.fsgn5-8.fna.fbcdn.net/v/t51.2885-19/278753174_724182805623321_3394183371636473540_n.jpg?stp=dst-jpg_s320x320&_nc_ht=z-p4-instagram.fsgn5-8.fna.fbcdn.net&_nc_cat=109&_nc_ohc=-fIprTNvlMAAX_1e79Z&edm=AOQ1c0wBAAAA&ccb=7-5&oh=00_AfC8tqtAyBGDpvNY55LJT1qXdDcE7AlaJx52kxPdbmlXig&oe=64322D90&_nc_sid=8fd12b",
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 5),
                  child: Text(
                    "$time",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontFamily: 'WorkSans',
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                      color: type == 2 ? bgColor : Colors.white,
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12))),
                  child: Text(
                    "$chattext",
                    style: TextStyle(
                        fontFamily: 'WorkSans',
                        color: type == 2 ? textColor : chatbgColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w400),
                  ),
                )
              ],
            ),
          )
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 5),
                child: Text(
                  "$time",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontFamily: 'WorkSans',
                      color: type == 2 ? textColor : chatbgColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w400),
                ),
              ),
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: type == 2 ? bgColor : Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12))),
                child: Text(
                  "$chattext",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontFamily: 'WorkSans',
                      color: type == 2 ? textColor : chatbgColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w400),
                ),
              )
            ],
          )),
          SizedBox(width: 12),
          Column(
            children: [
              ClipOval(
                child: Image.network(
                  "https://i.pinimg.com/564x/f7/96/30/f79630a2e1cdd796b5bb72bdb7fbfdc1.jpg",
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              // IconButton(
              //   iconSize: 20,
              //   color: Colors.white,
              //   onPressed: () {
              //     _speak(chattext);
              //   },
              //   icon: const Icon(Icons.volume_up_rounded),
              // )
            ],
          )
        ],
      );
    }
  }
}
