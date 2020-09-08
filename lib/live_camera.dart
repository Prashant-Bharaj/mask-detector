import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:test_app/boundary.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;

class FaceDetectionFromLiveCamera extends StatefulWidget {
  @override
  _FaceDetectionFromLiveCameraState createState() =>
      _FaceDetectionFromLiveCameraState();
}

class _FaceDetectionFromLiveCameraState
    extends State<FaceDetectionFromLiveCamera> {
  List<CameraDescription> _availableCameras;
  CameraController cameraController;
  bool isDetecting = false;
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  bool front = true;
  InterstitialAd interstitialAd;

  @override
  void initState() {
    super.initState();
    FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-2118277683611450~3876414727');
    interstitialAd = myInterstitial()..load();
    loadModel();
    _getAvailableCameras();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    cameraController?.dispose();
    interstitialAd.dispose();
    super.dispose();

  }

  void setRecognitions(List recognitions, int height, int width) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = height;
      _imageWidth = width;
    });
  }

  Future<void> _initializeCamera(CameraDescription description) async {
    cameraController = CameraController(description, ResolutionPreset.high);
    try {
      await cameraController.initialize().then((_) {
        if (!mounted) {
          print('error in mounted');
          return;
        }
        cameraController.startImageStream((CameraImage img) {
          if (!isDetecting) {
            isDetecting = true;
            Tflite.runModelOnFrame(
              bytesList: img.planes.map(
                (plane) {
                  return plane.bytes;
                },
              ).toList(),
              threshold: 0.5,
              rotation: 0,
              imageHeight: img.height,
              imageWidth: img.width,
              numResults: 1,
            ).then((recognitions) {
              setRecognitions(recognitions, img.height, img.width);
              isDetecting = false;
            });
          }
        });
      });
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  //Targeting info per the native AdMob API.
  static MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
      keywords: <String>['apps', 'games', 'news'], testDevices: <String>[]);

  InterstitialAd myInterstitial() {
    return InterstitialAd(
        adUnitId: 'ca-app-pub-2118277683611450/3239132230',
        targetingInfo: targetingInfo,

        /// The [listener] will be notified when the ad has finished loading or fails
        /// to do so. An ad that fails to load will not be shown.
        ///
        /// Applications can wait until an ad is [MobileAdEvent.loaded] before showing
        ///it, to ensure that the ad is displayed promptly.
        listener: (MobileAdEvent event) {
          // here we passing the variable of MobileAdEvent
          if (event == MobileAdEvent.failedToLoad) {
            interstitialAd..load();
          } else if (event == MobileAdEvent.closed) {
            interstitialAd = myInterstitial()..load();
          }
        });
  }

  Future<void> _getAvailableCameras() async {
    WidgetsFlutterBinding.ensureInitialized();
    _availableCameras = await availableCameras();
    _initializeCamera(_availableCameras[1]);
  }

  void loadModel() async {
    await Tflite.loadModel(
        model: 'assets/model_unquant.tflite', labels: 'assets/labels.txt');
  }

  void _toggleCammeraLens(){
    //get current lens direction (front/ rear)
    final lensDirection = cameraController.description.lensDirection;
    CameraDescription newDescription;
    if(lensDirection == CameraLensDirection.front){
      newDescription = _availableCameras.firstWhere((element) => element.lensDirection == CameraLensDirection.back);
    }else{
      newDescription = _availableCameras.firstWhere((element) => element.lensDirection == CameraLensDirection.front);
    }
    if(newDescription != null){
      _initializeCamera(newDescription);
    }else{
      print('camera not availabel');
    }
  }


  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Container(
        constraints: const BoxConstraints.expand(),
        child: cameraController == null
            ? Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              )
            : Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: (){
              front==true?front=false:front=true;
              _toggleCammeraLens();
            },
            child: Icon(front==true?Icons.camera_rear:Icons.camera_front),
          ),
          appBar: AppBar(title: Text('Mask detector'),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: cameraController.value.aspectRatio,
                  child: CameraPreview(cameraController),
                ),
              ),
              BoundaryBox(
                _recognitions == null? [] : _recognitions,
                math.max(_imageHeight, _imageWidth),
                math.min(_imageHeight, _imageWidth),
                screen.height,
                screen.width,
              ),
            ],
          ),
        ),);
  }
}
