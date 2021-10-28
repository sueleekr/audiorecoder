import 'dart:ui';

import 'package:flutter/material.dart';

class SoundWave extends StatefulWidget {
  SoundWave( {Key? key, required this.decibel, this.activate = false, this.color = Colors.white, this.height = 150, this.width = 150,}) : super(key: key);
  
  final bool activate;
  final double decibel;
  final Color color;
  final double height;
  final double width;

  @override
  _SoundWaveState createState() => _SoundWaveState();
}

class _SoundWaveState extends State<SoundWave> with SingleTickerProviderStateMixin {

  static const double ANIMATION_SPEED = 500;
  static const double MIN_HEIGHT = 10;

  double end_length = 0;              // animation end


  late final _animationController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.activate?ANIMATION_SPEED.toInt():0)
  );

  @override
  void initState() {
    super.initState();

    widget.activate?_animationController.repeat():_animationController.stop();
  }


  @override
  void dispose() {

    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double  MIN_HEIGHT_MULTIPLIER = 0.5;   // start animation rate 
    double decibelRate = (widget.decibel + 100)/200;//  decibel [-100, 100] -> [0,1]
    double startHeight = widget.height*decibelRate*MIN_HEIGHT_MULTIPLIER;
    double endHeight = widget.height*decibelRate;
    late Color _color;

    if(widget.activate){
        startHeight = (startHeight < MIN_HEIGHT)?MIN_HEIGHT:startHeight;
        endHeight =  (endHeight < MIN_HEIGHT)?MIN_HEIGHT:endHeight;
        _color = widget.color;
    }
    else{
        _color = Colors.grey;
    }

    _animationController.duration =  Duration(milliseconds: widget.activate?ANIMATION_SPEED.toInt():0);
  widget.activate?_animationController.repeat():_animationController.stop();


    return AnimatedBuilder(
        animation: _animationController, 
        
        builder: (context, child){
          double currentHeight = widget.height;
          if(widget.activate)
            currentHeight = lerpDouble(startHeight, endHeight, _animationController.value)??MIN_HEIGHT;
          print('animation controller value -> ${_animationController.value}');
          return Container(
            height: widget.height,
            width: widget.width,
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment:MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  color: _color,
                  width: 5, 
                  height: currentHeight*0.25,
                ),
                Container(
                  color: _color,
                  width: 5, 
                  height: currentHeight*0.5,
                ),
                Container(
                  color: _color,
                  width: 5, 
                  height: currentHeight*0.75,
                ),
                Container(
                  color: _color,
                  width: 5, 
                  height:currentHeight,
                ),
                Container(
                  color: _color,
                  width: 5, 
                  height: currentHeight*0.75,
                ),
                Container(
                  color: _color,
                  width: 5, 
                  height: currentHeight*0.5,
                ),
                Container(
                  color: _color,
                  width: 5, 
                  height: currentHeight*0.25,
                ),
              ],
            ),
          );

        }
    );
  }
}

/* 
class DecibelBar extends StatefulWidget {
  DecibelBar({Key? key, required this.height, required this.color, required this.activate}) : super(key: key);

  final int height;
  final Color color;
  final bool activate;

  @override
  _DecibelBarState createState() => _DecibelBarState();
}

class _DecibelBarState extends State<DecibelBar> {
  @override
  Widget build(BuildContext context) {
    return 
      Container(
        color: widget.activate?widget.color : Colors.grey,
        width: 5, 
        height: 40,
      );
  }
} */