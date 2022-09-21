import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

class CustomCamera extends StatefulWidget {
  // final List<CameraDescription>? cameras;
  final Color? color;
  final Color? iconColor;
  Function(XFile)? onImageCaptured;
  Function(XFile)? onVideoRecorded;
  final Duration? animationDuration;

  CustomCamera(
      {Key? key,
      this.onImageCaptured,
      this.animationDuration = const Duration(seconds: 1),
      this.onVideoRecorded,
      this.iconColor = Colors.white70,
      required this.color})
      : super(key: key);

  @override
  _CustomCameraState createState() => _CustomCameraState();
}

class _CustomCameraState extends State<CustomCamera>
    with WidgetInspectorService {
  List<CameraDescription>? cameras;

  CameraController? controller;

  final StopWatchTimer _stopWatchTimer = StopWatchTimer();

  @override
  void initState() {
    // Hide the status bar in Android
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    super.initState();
    initCamera().then((_) {
      setCamera(0);
    });
  }

  Future initCamera() async {
    cameras = await availableCameras();
    setState(() {});
  }

  void setCamera(int index) {
    controller = CameraController(cameras![index], ResolutionPreset.max);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  ///Switch
  bool _cameraView = true;

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: AnimatedSwitcher(
        duration: widget.animationDuration!,
        child: _cameraView == true ? cameraView() : videoView(),
      ),
    );
  }

  void captureImage() {
    controller!.takePicture().then((value) {
      Navigator.pop(context);
      widget.onImageCaptured!(value);
    });
  }

  void setVideo() {
    controller!.startVideoRecording();
  }

  ///Camera View Layout
  Widget cameraView() {
    return Stack(
      // Stack là một bộ chứa cho phép đặt các widget con của nó chồng lên nhau
      key: const ValueKey(0),
      children: [
        //Camera preview
        Positioned(
          top: 90,
          bottom: 90,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: RotatedBox(
              quarterTurns: 1 - controller!.description.sensorOrientation ~/ 90,
              child: CameraPreview(
                controller!,
              ),
            ),
          ),
        ),

        //appbar
        Positioned(
          top: 0,
          height: 90,
          width: MediaQuery.of(context).size.width,
          child: Container(
            alignment: Alignment.bottomCenter,
            color: Colors.black,
            child: const Text(
              "Capturing...",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
        ),

        ///Side controls
        Positioned(
            top: 60,
            right: 20,
            child: Column(
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.clear,
                      color: widget.iconColor,
                      size: 30,
                    )),
                cameraSwitcherWidget(),
                flashToggleWidget()
              ],
            )),

        ///Bottom Controls
        Positioned(
          bottom: 0,
          height: 90,
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Stack(
                  children: [
                    const Icon(
                      Icons.circle,
                      color: Colors.white38,
                      size: 60,
                    ),
                    IconButton(
                      onPressed: () {
                        captureImage();
                      },
                      icon: const Icon(
                        Icons.circle,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _cameraView = false;
                    });
                  },
                  icon: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  bool _isRecording = false;
  bool _isPaused = false;

  ///Video View
  Widget videoView() {
    return Stack(
      key: const ValueKey(1),
      children: [
        Positioned(
          top: 90,
          bottom: 90,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: RotatedBox(
              quarterTurns: 1 - controller!.description.sensorOrientation ~/ 90,
              child: CameraPreview(
                controller!,
              ),
            ),
          ),
        ),

        ///top controlls
        Positioned(
            top: 0,
            height: 90,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(20),
              width: MediaQuery.of(context).size.width,
              height: 90,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ///Front Camera toggle
                  cameraSwitcherWidget(),
                  Expanded(
                    child: _isRecording == false
                        ? const Text(
                            'Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Colors.red,
                                  size: 15,
                                ),
                                StreamBuilder<int>(
                                    stream: _stopWatchTimer.rawTime,
                                    initialData: _stopWatchTimer.rawTime.value,
                                    builder: (context, snapshot) {
                                      final value = snapshot.data;
                                      final displayTime =
                                          StopWatchTimer.getDisplayTime(value!,
                                              hours: false, milliSecond: false);
                                      return Text(
                                        displayTime,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      );
                                    }),
                              ],
                            ),
                          ),
                  ),

                  ///Flash toggle
                  flashToggleWidget()
                ],
              ),
            )),

        ///Bottom Controls
        Positioned(
          bottom: 0,
          height: 90,
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      ///Show camera view
                      _cameraView = true;
                    });
                  },
                  icon: Icon(
                    Icons.camera_alt,
                    color: widget.iconColor,
                    size: 35,
                  ),
                ),
                Stack(
                  children: [
                    const Icon(
                      Icons.circle,
                      color: Colors.white,
                      size: 60,
                    ),
                    IconButton(
                      onPressed: () async {
                        //Start and stop video
                        if (_isRecording == false) {
                          ///Start
                          await controller!.startVideoRecording();

                          _isRecording = true;
                          _stopWatchTimer.onStartTimer();
                        } else {
                          ///Stop video recording
                          controller!.stopVideoRecording().then((value) {
                            Navigator.pop(context);
                            widget.onVideoRecorded!(value);
                          });
                          _isRecording = false;
                          _stopWatchTimer.onResetTimer();
                        }
                        setState(() {});
                      },
                      icon: Icon(
                        _isRecording == false
                            ? Icons.circle
                            : Icons.stop_circle,
                        color: Colors.red,
                        size: 44,
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    const Icon(
                      Icons.circle,
                      color: Colors.black38,
                      size: 60,
                    ),
                    IconButton(
                      onPressed: () async {
                        //pause and resume video
                        if (_isRecording == true) {
                          //pause
                          if (_isPaused == true) {
                            ///resume
                            await controller!.resumeVideoRecording();
                            _stopWatchTimer.onStartTimer();
                            _isPaused = false;
                          } else {
                            ///resume
                            controller!.pauseVideoRecording();
                            _isPaused = true;
                            _stopWatchTimer.onStopTimer();
                          }
                        }
                        setState(() {});
                      },
                      icon: Icon(
                        _isPaused == false ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  bool _isTouchOn = false;

  Widget flashToggleWidget() {
    return IconButton(
      onPressed: () {
        if (_isTouchOn == false) {
          controller!.setFlashMode(FlashMode.torch);
          _isTouchOn = true;
        } else {
          controller!.setFlashMode(FlashMode.off);
          _isTouchOn = false;
        }
        setState(() {});
      },
      icon: Icon(_isTouchOn == false ? Icons.flash_on : Icons.flash_off,
          color: widget.iconColor, size: 30),
    );
  }

  bool _isFrontCamera = false;

  Widget cameraSwitcherWidget() {
    return IconButton(
      onPressed: () {
        if (_isFrontCamera == true) {
          setCamera(0);
          _isFrontCamera = false;
        } else {
          setCamera(1);
          _isFrontCamera = true;
        }
        setState(() {});
      },
      icon: Icon(
        _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
