import 'dart:io';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'live_camera.dart';

void main() => runApp(CoronaVirusTracker());

class CoronaVirusTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        dividerTheme: DividerThemeData(color: Colors.black54),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey.shade900,
        dividerTheme: DividerThemeData(color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      home: MyHomePage(),
    );
  }
}

//ca-app-pub-2118277683611450~3876414727
//ca-app-pub-2118277683611450/3239132230
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // declaring a variables
  bool _loading;
  List _outputs;
  //for accessing the location of a image file
  File _image;
  // for showing adds
  int count = 0;
  // declaring  a variable of type InterstitialAd class
  InterstitialAd interstitialAd;

  @override
  void initState() {
    super.initState();
    FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-2118277683611450~3876414727');
    interstitialAd = myInterstitial()..load();
    _loading = true;
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  //Targeting info per the native AdMob API.
  static MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
      keywords: <String>['apps', 'games', 'news'], testDevices: <String>["F72F63845135912CF76C7742C1A37509"]);

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



  Future<void> share() async {
    await FlutterShare.share(
        title: 'Hey, I find awesome app!',
        text: 'Use this app to detect mask in photos/selfies.',
        linkUrl:
            'https://play.google.com/store/apps/details?id=com.psb.applications.maskdetector',
        chooserTitle: 'Must give it a try');
  }

  // Making a method for loading a model
  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/labels.txt',
    );
  }

  Future pickImage() async {
    count++;
    print(count); // this counting is for showing ads
    //here we create instance of ImagePicker() and then on it calling the getImage method because getImage is an instance Method
    //You first need to create an instance () to call an instance method.
    var image = await ImagePicker().getImage(source: ImageSource.gallery);
    if (image == null) return null;

    setState(() {
      _loading = true;
      _image = File(image.path);
      print("---------$image");
      print("----------${image.path}");
      print('===========${_image.path}_image');
    });
    classifyImage(File(image.path));

  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 1,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      //Declare List _outputs in the class which will be used to show the classified classs name and confidence
      _outputs = output;

      if(count.isOdd)
      { print('hey');
      interstitialAd
        ..load()
        ..show();
      }
    });
  }

  @override
  void dispose() {
    interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
//          color: Colors.grey.shade900,
          child: ListView(
            padding: EdgeInsets.only(top: 20),
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/mask.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Mask detector',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  'Share with your friends and family and have fun :)',
                  style: TextStyle(
//                    fontSize: 14,
                  ),
                ),
                leading: Icon(
                  Icons.share,
//                  size: 40,
                ),
                onTap: () {
                  share();
                },
              ),
              Divider(
                height: 3,
//                color: Colors.black,
              ),
              ListTile(
                title: Text('Rate the app'),
                leading: Icon(Icons.star),
                onTap: () {
                  launch(
                    'https://play.google.com/store/apps/details?id=com.psb.applications.maskdetector',
                  );
                },
              ),
              Divider(
                height: 3,
              ),
              ListTile(
                title: Text('About the developer',),
                leading: Icon(Icons.developer_mode, ),
                onTap: (){
                  launch('https://github.com/prashant-bharaj');
                },
              )
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text("Mak detector"),
        centerTitle: true,
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            heroTag: null,
            onPressed:()=> pickImage(),
            child: Icon(Icons.image,),
          ),
          FloatingActionButton(
            heroTag: null,
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (buildContext){
                return FaceDetectionFromLiveCamera();
              }));
            },
            child: Icon(Icons.camera),
          ),
        ],
      ),

        body: _loading
            ? Container(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
        )
            : Container(
//          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image == null ? Container() : Image.file(_image,fit: BoxFit.cover,height:MediaQuery.of(context).size.height*0.6),
              SizedBox(
                height: 10,
              ),
              _outputs != null
                  ? Column(
                children: <Widget>[
                  Text(
                    _outputs[0]["label"]=='0 with_mask'?"Mask detected":"Mask not detected",
                    style: TextStyle(
                      color: _outputs[0]["label"]=='0 with_mask'?Colors.green:Colors.red,
                      fontSize: 25.0,
                    ),
                  ),
                  Text("${(_outputs[0]["confidence"]*100).toStringAsFixed(0)}%",style: TextStyle(color:Colors.purpleAccent,fontSize:20),)
                ],
              )
                  : Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Choose a photo from gallery or use the live camera feed to detect face mask",style: TextStyle(fontSize:20,fontWeight:FontWeight.w500,color: Colors.white),textAlign: TextAlign.center,),
                    ),
                    Container(
                        child:SvgPicture.asset(
                          'assets/mask-woman.svg',
                          semanticsLabel: 'Mask woman',
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height*0.5,
                        )
                    ),
                    SizedBox(height:20),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text("Note:the input photo must have a CLOSE face & the model is not 100% correct",style:TextStyle(color: Colors.red,fontSize: 20),textAlign: TextAlign.center,),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
