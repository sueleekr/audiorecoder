
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:audiorecoder/widgets/soundwave.dart';
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

enum Status { 
   none,          //before recording
   running,       //recording
   stopped,       //recording stopped
}

class AudioRecorder extends StatefulWidget {
  const AudioRecorder({Key? key}) : super(key: key);

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  Status audioStatus = Status.none;
  String _headerLeftMenuTitle = 'Back';
  String _headerRightMenuTitle = '';
  String _recorderTxt = '00:00';
  //bool _on = false;   //only if using timer widget
  double _decibel = 0.0;
  TimerViewController timerController = TimerViewController();
  FlutterSoundRecorder? _myRecorder;
  StreamSubscription? _recorderSubscription;

  late String filePath;
  late VideoPlayerController _controller;
  ChewieAudioController? _chewieController;

  @override
  void initState() {
    super.initState();

    filePath = '/sdcard/Download/temp1.wav';
    _myRecorder = FlutterSoundRecorder();

    init().then((value) {
      _myRecorder!.openAudioSession().then((value) {

      });
    });
  }

  Future<void> init() async {

    PermissionStatus micStatus =  await Permission.microphone.request();
    if(micStatus != PermissionStatus.granted) {
      throw RecordingPermissionException("Microphone permission not granted");
    }
 
    PermissionStatus storageStatus =  await Permission.storage.request();
    if(storageStatus != PermissionStatus.granted) {
      throw RecordingPermissionException("Storage permission not granted");
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: 
        Padding(padding: EdgeInsets.all(30),
          child: Center(
            child: Column(
              children: [
                //TimerView(recording: _on,timeviewController: timerController,),
                SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: (){
                          // previous page
                        }, 
                        child: AudioText(txt: _headerLeftMenuTitle,)
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: (){//Save
                            }, 
                            child: AudioText(txt: _headerRightMenuTitle)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: AudioText(txt: _recorderTxt,fontsize: 50)
                ),
                 AudioText(txt: _decibel.toString(),fontsize: 20),
                Center(
                  child: Container(
                    color: Colors.transparent,
                    height: 500,
                    child: 
                      Center(
                        child: _chewieController != null ? 
                          ChewieAudio(controller: _chewieController!) 
                          : 
                          (audioStatus != Status.running)?
                            SoundWave(activate: false, decibel: 1,)
                            :
                            SoundWave(activate:true, decibel: _decibel,),
                      ),
                  ),
                ),//,ChewieAudio(controller: _chewieController!),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: RecordingButton(
                    onTap:(val)=> onRecordTap(val)
                  ),
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

    await _myRecorder!.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
    );

    await _myRecorder!.setSubscriptionDuration(const Duration(milliseconds: 500));

    initializeDateFormatting();

    _recorderSubscription = _myRecorder!.onProgress!.listen((e) {
      
      var date = DateTime.fromMillisecondsSinceEpoch(e.duration.inMilliseconds, isUtc: true);

      var txt = DateFormat('mm:ss', 'en_GB').format(date);
      

      setState(() {
        //print('decibel => $_decibel');
        _recorderTxt = txt.substring(0, 5);
        _decibel = e.decibels??0;
      });
    });
  }  

  Future<String?> stopRecording() async {

    String? anURL = await _myRecorder!.stopRecorder();

    if (_recorderSubscription != null)
    {
      _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }

    _controller = VideoPlayerController.file(File(filePath));
    
    return anURL;
  }

  Future<void> onRecordTap(bool val) async {

      if(audioStatus == Status.none || audioStatus == Status.stopped){
        await startRecording();
      }
      else if(audioStatus == Status.running) {
        await stopRecording();
      }

    setState(() {
//      _on = val;

      if(audioStatus == Status.none || audioStatus == Status.stopped){
        statusChange(Status.running);
      }
      else if(audioStatus == Status.running) {
        statusChange(Status.stopped);
      }
    });
  }

  void statusChange(Status status){
    switch (status) {
      case Status.none: 
        // before recording || reset
        audioStatus = Status.none;
        _headerLeftMenuTitle = 'Back';
        _headerRightMenuTitle = '';
        _recorderTxt = '00:00';
        _decibel = 0.0;

        if(_chewieController != null){
          _chewieController!.dispose();
          _chewieController = null;
        }
        // back to previous page

        break;
      case Status.running:
        // on recording
        audioStatus = Status.running;
        _headerLeftMenuTitle = '';
        _headerRightMenuTitle = '';

        if(_chewieController != null){
          _chewieController!.dispose();
          _chewieController = null;
        }

        break;
      case Status.stopped:
        // After recordint
        audioStatus = Status.stopped;
        _headerLeftMenuTitle = 'Cancel';
        _headerRightMenuTitle = 'Save';

        _chewieController = ChewieAudioController(
          videoPlayerController: _controller,
          autoInitialize: true,
          autoPlay: false,
          looping: false,
        );

        break;
      default:
        null;
    }
  }
}

class AudioText extends StatefulWidget {
  AudioText({Key? key, required this.txt, this.fontsize = 15, this.color = Colors.white, this.fontweight = FontWeight.bold, }) : super(key: key);

  final String txt;
  final Color color;
  final double fontsize;
  final FontWeight fontweight;
  
  @override
  _AudioTextState createState() => _AudioTextState();
}

class _AudioTextState extends State<AudioText> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.txt,
      style: TextStyle(
        color: widget.color,
        fontSize: widget.fontsize,
        fontWeight: widget.fontweight
      ),
    );
  }
}

