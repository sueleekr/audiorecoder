
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audiorecoder/widgets/recordingbutton.dart';
import 'package:audiorecoder/widgets/soundwave.dart';
import 'package:chewie_audio/chewie_audio.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

enum Status {
  none,          //before recording
  running,       //recording
  stopped,       //recording stopped
}

class AudioRecorder extends StatefulWidget {
  final String filePath;

  const AudioRecorder({
    Key? key,
    required this.filePath
  }) : super(key: key);

  @override
  _AudioRecorderState createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioRecorder> {
  late VideoPlayerController _controller;
  ChewieAudioController? _chewieController;
  FlutterSoundRecorder? _myRecorder;
  StreamSubscription? _recorderSubscription;
  Status _audioStatus = Status.none;
  String _headerLeftMenuTitle = 'Back';
  String _headerRightMenuTitle = '';
  String _recorderTxt = '00:00';
  double _decibel = 0.0;
  Map<String,dynamic>? error;

  // Getters
  String get filePath => widget.filePath;

  @override
  void initState() {
    super.initState();

    _myRecorder = FlutterSoundRecorder();

   try {
    init().then((value) {
      _myRecorder!.openAudioSession();
    });
   } catch(e) {
     setState(() {
       error = {
         'type': 'permission',
         'message': (e is RecordingPermissionException || e is RecordingPermissionException) ?
            e.message :
            'Something went wrong'
       };
     });
   }
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
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Column(
            children: [
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
                child: AudioText(txt: _recorderTxt, fontsize: 50)
              ),
              Center(
                child: Container(
                  color: Colors.transparent,
                  height: 500,
                  child:
                    Center(
                      child: _chewieController != null ?
                        ChewieAudio(controller: _chewieController!)
                        :
                        (_audioStatus != Status.running)?
                          const SoundWave(activate: false, decibel: 1,width: 150,height: 150,)
                          :
                          SoundWave(activate:true, decibel: _decibel,),
                    ),
                ),
              ),
              if(error != null)
              Text(error!['message'] as String, style: const TextStyle(color: Colors.white)),
              Align(
                alignment: Alignment.bottomCenter,
                child: RecordingButton(
                  onTap:(val) => onRecordTap(val)
                ),
              )
            ],
          ),
        ),
      )
    );
  }

  Future<void> startRecording() async {
    Directory dir = Directory(path.dirname(filePath));

    if (!dir.existsSync()) {
      dir.createSync();
    }

    await _myRecorder!.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS,
    );

    await _myRecorder!.setSubscriptionDuration(const Duration(milliseconds: 200));

    // recorder listener
    _recorderSubscription = _myRecorder!.onProgress!.listen((e) {
      var date = DateTime.fromMillisecondsSinceEpoch(e.duration.inMilliseconds, isUtc: true);
      var txt = DateFormat('mm:ss', 'en_GB').format(date);

      setState(() {
        _recorderTxt = txt.substring(0, 5);
        _decibel = e.decibels??0;
      });
    });
  }

  Future<String?> stopRecording() async {
    String? anURL = await _myRecorder!.stopRecorder();

    if (_recorderSubscription != null) {
      _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }
    _controller = VideoPlayerController.file(File(filePath));

    return anURL;
  }

  Future<void> onRecordTap(bool val) async {
    if(_audioStatus == Status.none || _audioStatus == Status.stopped) {
      await startRecording();
    }
    else if(_audioStatus == Status.running) {
      await stopRecording();
    }

    setState(() {
      if(_audioStatus == Status.none || _audioStatus == Status.stopped) {
        statusChange(Status.running);
      }
      else if(_audioStatus == Status.running) {
        statusChange(Status.stopped);
      }
    });
  }

  void statusChange(Status status){
    switch (status) {
      case Status.none:
        // before recording || reset
        _audioStatus = Status.none;
        _headerLeftMenuTitle = 'Back';
        _headerRightMenuTitle = '';
        _recorderTxt = '00:00';
        _decibel = 0.0;

        if(_chewieController != null) {
          _chewieController!.dispose();
          _chewieController = null;
        }
        break;
      case Status.running:
        // on recording
        _audioStatus = Status.running;
        _headerLeftMenuTitle = '';
        _headerRightMenuTitle = '';

        if(_chewieController != null) {
          _chewieController!.dispose();
          _chewieController = null;
        }
        break;
      case Status.stopped:
        // After recordint
        _audioStatus = Status.stopped;
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
  const AudioText({
    Key? key,
    required this.txt,
    this.fontsize = 15,
    this.color = Colors.white,
    this.fontweight = FontWeight.bold
  }) : super(key: key);

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

