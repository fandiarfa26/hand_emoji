import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hand_emoji/main.dart';
import 'package:tflite/tflite.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? controller;
  CameraImage? cameraImage;
  Map<String, dynamic> convertEmoji = {
    "0 zero": "✊",
    "1 two": "✌️",
    "2 Class 3": "🖐",
  };
  String output = '';

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadModel();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  loadCamera() async {
    controller = CameraController(cameras![1], ResolutionPreset.medium);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        controller!.startImageStream((image) {
          cameraImage = image;
          runModel();
        });
      });
    });
  }

  runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
          bytesList: cameraImage!.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: cameraImage!.height,
          imageWidth: cameraImage!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);
      predictions!.forEach((element) {
        setState(() {
          output = convertEmoji[element['label']];
        });
      });
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/data/model_unquant.tflite",
      labels: "assets/data/labels.txt",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: const Text("Hand Emoji Recognition"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 0.7 * MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: !controller!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
                    child: CameraPreview(controller!),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              output,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 48),
            ),
          ),
        ],
      ),
    );
  }
}
