import 'dart:ui';

import 'package:flutter/material.dart';

class RecordingButton extends StatefulWidget {
  RecordingButton({Key? key, this.onTap}) : super(key: key);
  
  final ValueChanged<bool>? onTap;


  @override
  _RecordingButtonState createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>  with SingleTickerProviderStateMixin {
  

  late AnimationController animationController;


  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 150),
      vsync: this
    );
  }

  toggleAnimation() {
    if(animationController.isCompleted) {
      animationController.reverse();
      if(widget.onTap!=null) widget.onTap!(false);
    } else {
      animationController.forward();
      if(widget.onTap!=null) widget.onTap!(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 4.0),
            borderRadius: BorderRadius.circular(80.0)
          ),
          height: 80.0,
          width: 80.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: animationController,
                builder: (BuildContext context, Widget? child) {
                  double size = lerpDouble(65.0, 40.0, animationController.value) ?? 80.0;
                  double radius = lerpDouble(80.0, 8.0, animationController.value) ?? 80.0;
                  Color iconColor = ColorTween(begin: Colors.white, end: Colors.red).lerp(animationController.value) ?? Colors.white;

                  return GestureDetector(
                    onTap: toggleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        color: Colors.red,
                      ),
                      height: size,
                      width: size,
                      child: Center(
                        child: Icon(Icons.mic, size: 36, color: iconColor),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}