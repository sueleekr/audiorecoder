import 'dart:async';

import 'package:flutter/material.dart';

class TimerView extends StatefulWidget {
  TimerView({Key? key, required this.recording, this.timeviewController}) : super(key: key);
  final bool recording;
  final TimerViewController? timeviewController;
  
  set recording(bool value){
    this.recording = value;
  }

  @override
  _TimerViewState createState() => _TimerViewState(timeviewController);
}

class _TimerViewState extends State<TimerView> {

  final TimerViewController? _timeviewController;
  _TimerViewState(this._timeviewController){
    if(_timeviewController != null)
      _timeviewController!._addState(this);
  }



  String _second = '00';
  String _minute = '00';

  Timer? timer;
  Duration duration = Duration();
  String twoDigits(int n) => n.toString().padLeft(2,'0');

  
  void reset(){

  }

  void stop(){
/*     if (widget.recording){
      reset();
    } */
    setState(() => timer?.cancel());
    duration = Duration();
  }

  void startTimer(){
    
    timer = Timer.periodic(Duration(seconds: 1),(_) => addTimer());

  }

  void addTimer(){
    final addSeconds = 1;
    setState(() {
      final seconds = duration.inSeconds + addSeconds;
      if (seconds < 0){
        timer?.cancel();
      } else{
        duration = Duration(seconds: seconds);
      }

      _second = twoDigits(duration.inSeconds.remainder(60));
      _minute = twoDigits(duration.inMinutes.remainder(60));
    });
  }

  @override
  void dispose() {
    super.dispose();
    if(timer!= null)
      timer!.cancel();
  }

  @override
  void initState() {
    super.initState();

    if (widget.recording)
      startTimer();
    else
      reset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SizedBox(
        height: 50,
        width: 100,
        child: Center(
          child: Text('$_minute : $_second',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30
            ),
          ),
        ),
      ),
    );
  }
}


class TimerViewController{
  _TimerViewState? _customWidgetState;

  void _addState(_TimerViewState customWidgetState){
    this._customWidgetState = customWidgetState;
  }

  /// Determine if the CustomWidgetController is attached to an instance
  /// of the CustomWidget (this property must return true before any other
  /// functions can be used)
  bool get isAttached => _customWidgetState != null;

  /// Here is the method you are exposing
  void statrtTimer() {
    assert(isAttached, "CustomWidgetController must be attached to a CustomWidget");
    _customWidgetState!.startTimer();
  }

  void stopTimer(){
      assert(isAttached, "CustomWidgetController must be attached to a CustomWidget");
      _customWidgetState!.stop();
  }
}