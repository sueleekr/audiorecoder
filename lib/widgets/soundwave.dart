import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class SoundWave extends StatefulWidget {
  final bool activate;
  final double decibel;
  final Color color;
  final double height;
  final double width;

  const SoundWave({
    Key? key,
    required this.decibel,
    this.activate = false,
    this.color = Colors.white,
    this.height = 150,
    this.width = 150
  }) : super(key: key);

  @override
  _SoundWaveState createState() => _SoundWaveState();
}

class _SoundWaveState extends State<SoundWave> with SingleTickerProviderStateMixin {

  static const double cAnimationSpeed = 250;
  static const double cMinHeight = 10;
  static const double cMinHeightMultiplier = 0.5;   // start animation rate
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.activate?cAnimationSpeed.toInt():0)
    );

    widget.activate ?
      _animationController.repeat() :
      _animationController.stop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double randomGenerator(double random, bool activate) {
    double returnValue;

    if(activate) {
      returnValue = lerpDouble(-0.5,0.5, random)??0;
      returnValue = double.parse(returnValue.toStringAsFixed(2));
    } else{
      returnValue = 0.0;
    }

    return returnValue;
  }

  double calculateHeight(double value) {
    return value * (1 - randomGenerator(Random().nextDouble(),widget.activate));
  }

  @override
  Widget build(BuildContext context) {
    double decibelRate = (widget.decibel + 100) / 200;//  decibel [-100, 100] -> [0,1]
    double startHeight = widget.height * decibelRate * cMinHeightMultiplier;
    double endHeight   = widget.height * decibelRate;

    late Color _color;
    if(widget.activate) {
      startHeight = (startHeight < cMinHeight) ? cMinHeight : startHeight;
      endHeight =  (endHeight < cMinHeight) ? cMinHeight : endHeight;
      _color = widget.color;
    } else {
      _color = Colors.grey;
    }

    // FIXME Is this valid?
    // FIXME This doesn't belong here, maybe initState
    _animationController.duration = Duration(
      milliseconds: widget.activate ? cAnimationSpeed.toInt() : 0
    );

    // FIXME Move this somewhere else like the initState
    widget.activate ? _animationController.repeat() : _animationController.stop();

    return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child){     //random value for the height
          double currentHeight = widget.height;
          if(widget.activate) {
            currentHeight = lerpDouble(startHeight, endHeight, _animationController.value) ?? cMinHeight;
          }

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
                  height: calculateHeight(currentHeight*0.25),
                ),
                Container(
                  color: _color,
                  width: 5,
                  height: calculateHeight(currentHeight*0.5),
                ),
                Container(
                  color: _color,
                  width: 5,
                  height: calculateHeight(currentHeight*0.75),
                ),
                Container(
                  color: _color,
                  width: 5,
                  height:currentHeight,
                ),
                Container(
                  color: _color,
                  width: 5,
                  height: calculateHeight(currentHeight*0.75),
                ),
                Container(
                  color: _color,
                  width: 5,
                  height: calculateHeight(currentHeight*0.5),
                ),
                Container(
                  color: _color,
                  width: 5,
                  height: calculateHeight(currentHeight*0.25),
                ),
              ],
            ),
          );
        }
    );
  }
}
