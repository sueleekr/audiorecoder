
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat; 
import 'package:path/path.dart' as path;

import 'package:audiorecoder/widgets/recordingbutton.dart';
import 'package:audiorecoder/widgets/timerview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:chewie_audio/chewie_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class AudioRecorder extends StatefulWidget {
  const AudioRecorder({Key? key}) : super(key: key);

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  bool _on = false;
  double _decibel = 0.0;
  TimerViewController timerController = TimerViewController();

  FlutterSoundRecorder? _myRecorder;
  late String filePath;
  //bool _play = false;
  String _recorderTxt = '00:00';
  StreamSubscription? _recorderSubscription;

  late VideoPlayerController _controller;
  ChewieAudioController? _chewieController;


  @override
  void initState() {
    super.initState();

    filePath = '/sdcard/Download/temp.wav';
    _myRecorder = FlutterSoundRecorder();

    init().then((value) {
      setState(() {
        //_play = true;
      });
    });
  }



  Future<void> init() async {

/*     _controller = VideoPlayerController.file(File(filePath));
    
    await _controller.initialize();

    setState(() {
      _chewieController = ChewieAudioController(
        videoPlayerController: _controller,
        autoInitialize: true,
        autoPlay: false,
        looping: false,
        
      );
    }); */

    PermissionStatus status =  await Permission.microphone.request();
    if(status != PermissionStatus.granted) {
      throw RecordingPermissionException("Microphone permission not granted");
    }

  }

  @override
  void dispose() {
    super.dispose();

    if(_myRecorder != null) {
      _myRecorder!.closeAudioSession();
    }

    if(_recorderSubscription != null) {
      _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }
    _controller.dispose();
    _chewieController?.dispose();
  }


  @override
  Widget build(BuildContext context) {
    //Timer timer = Timer(Duration(seconds: 1), callback);

    return Scaffold(
      backgroundColor: Colors.black,
      body: 
        Padding(padding: EdgeInsets.all(30),
          child: Center(
            child: Column(
              children: [
                //TimerView(recording: _on,timeviewController: timerController,),
                Center(
                  child: Text(
                    _recorderTxt,
                    style: const TextStyle(fontSize: 50, color: Colors.white),
                  ),
                ),
                const Text('60 seconds Max',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15
                  ),
                
                ),
                Text(_decibel.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30
                  ),
                
                ),
                _chewieController != null ? ChewieAudio(controller: _chewieController!) 
                    : Center(child: Text('waiting...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30
                            ),
                                )),//,ChewieAudio(controller: _chewieController!),
                RecordingButton(
                  onTap:((value)=> {
                      setState(() {
                        _on = value;
                        if(_on){
                          //timerController.statrtTimer();
                          startRecording();
                        }
                        else{
                          //timerController.stopTimer();
                          stopRecording();
                        }
                      })
                  })
                )
              ],
            ),
          ),

        )
    
      
      ,
    );
  }


  Future<void> startRecording() async {
    Directory dir = Directory(path.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync();
    }
    _myRecorder!.openAudioSession(
        focus: AudioFocus.requestFocusAndStopOthers,
        category: SessionCategory.playAndRecord,
        mode: SessionMode.modeDefault,
        device: AudioDevice.speaker 
    );

    await _myRecorder!.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
    );
    await _myRecorder!.setSubscriptionDuration(const Duration(milliseconds: 50));

    initializeDateFormatting();

    _recorderSubscription = _myRecorder!.onProgress!.listen((e) {
      
      var date = DateTime.fromMillisecondsSinceEpoch(e.duration.inMilliseconds, isUtc: true);

      var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
      _decibel = e.decibels!;

      setState(() {

        print('decibel => $_decibel');
        _recorderTxt = txt.substring(3, 8);
      });
    });
    


    //_recorderSubscription.cancel();
  }  

  Future<String?> stopRecording() async {
    _myRecorder!.closeAudioSession();
    //_recorderSubscription!.cancel();


    String? anURL = await _myRecorder!.stopRecorder();
    if (_recorderSubscription != null)
    {
      _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }

    _controller = VideoPlayerController.network(
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4');// VideoPlayerController.file(File(filePath));
    
    await _controller.initialize();

    setState(() {
      _chewieController = ChewieAudioController(
        videoPlayerController: _controller,
        autoInitialize: true,
        autoPlay: false,
        looping: false,
        
      );
    });


    _chewieController!.addListener(() { 
      print('chewie listener');  
    });


    return anURL;//await _myRecorder!.stopRecorder();

  }

  
}



