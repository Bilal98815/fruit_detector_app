import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fruit_detector_app/main.dart';
import 'package:tflite/tflite.dart';

class FruitDetectionScreen extends StatefulWidget {
  const FruitDetectionScreen({super.key});

  @override
  State<FruitDetectionScreen> createState() => _FruitDetectionScreenState();
}

class _FruitDetectionScreenState extends State<FruitDetectionScreen> {
  bool isWorking = false;
  String result = '';
  CameraController? controller;
  CameraImage? img;

  void initCamera() {
    controller = CameraController(cameras![0], ResolutionPreset.medium);
    controller!.initialize().then((value) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (controller!.value.isInitialized) {
          debugPrint(
              'controller is initialized --------------------->>>>>>>>>> ');
          controller!.startImageStream((image) {
            if (!isWorking) {
              isWorking = true;
              img = image;
              runModelOnStreamFrames();
            }
          });
        }
      });
    }).catchError((e) {
      debugPrint('Error --------------------->>>>>>>>>> $e');
    });
  }

  void loadModel() async {
    debugPrint('In Load model method --------------------->>>>>>>>>> ');
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/labels.txt',
    );
  }

  @override
  void initState() {
    debugPrint('In initState --------------------->>>>>>>>>> ');
    super.initState();
    loadModel();
  }

  @override
  void dispose() async {
    debugPrint('In dispose--------------------->>>>>>>>>> ');
    super.dispose();
    await Tflite.close();
    controller?.dispose();
    debugPrint('Out of dispose --------------------->>>>>>>>>> ');
  }

  void runModelOnStreamFrames() async {
    debugPrint('In run model method --------------------->>>>>>>>>> ');
    final recognitions = await Tflite.runModelOnFrame(
      bytesList: img!.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: img!.height,
      imageWidth: img!.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 2,
      threshold: 0.1,
      asynch: true,
    );
    debugPrint('In half of run model method --------------------->>>>>>>>>> ');
    result = '';
    for (final response in recognitions!) {
      final labelWithoutDigits = removeDigitsFromString(response['label']);
      result +=
          '$labelWithoutDigits   ${(response['confidence'] as double).toStringAsFixed(2)}\n\n';
    }

    setState(() {
      result;
    });

    isWorking = false;
  }

  String removeDigitsFromString(String input) {
    return input.replaceAll(RegExp(r'\d'), ''); // RegExp to match digits
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Fruit Detector'),
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              Center(
                child: TextButton(
                  onPressed: () {
                    initCamera();
                  },
                  child: SizedBox(
                    width: 360,
                    height: 450,
                    child: img == null
                        ? const SizedBox(
                            width: 360,
                            height: 450,
                            child: Icon(Icons.camera_alt_outlined),
                          )
                        : AspectRatio(
                            aspectRatio: controller!.value.aspectRatio,
                            child: CameraPreview(controller!),
                          ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 55),
                padding: const EdgeInsets.all(20),
                child: Text(
                  result,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    backgroundColor: Colors.black,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
