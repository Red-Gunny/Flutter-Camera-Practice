import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// [개념 정리]
///  위젯 : 화면을 구성하는 컴포넌트
///

/// [비동기 처리]
/// (1) await 키워드
///  - 메소드 앞에 위치.
///  - 해당 메소드가 값을 반환할 때까지 기다리게 한다.
///  - 반환값을 기다리는 동안 앱이 멈추지 않음.
///  - 반환받았으면 밑에 코드 계속 진행.


Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(                    /// runApp에 MaterialApp을 전달하는 것임.
                                    ///  ㄴ title
                                    ///  ㄴ theme
                                    ///  ㄴ home (표시할 위젯 전달)
      theme: ThemeData.dark(),          /// 테마를 지정한다.
      home: TakePictureScreen(          ///   여기에 작성하는 위젯이 실제 이 앱이 표시하는 위젯이 된다.
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,            /// 이름있는 인수. 이건 클래스의 프로퍼티에 값을 할당하는 것임.
      ),
    ),
  );
}

/// 이제 home으로 위젯 넘겼던 게 여기서 정의
/// 데이터를 전달할 때는 생성자를 활용한다.
/// "상태"를 가질 수 있는데
// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({                       // 이건 생성자
    Key? key,
    required this.camera,
  }) : super(key: key);                           // 부모에도 전달함

  final CameraDescription camera;

  @override   // 상위 클래스에 있던걸 재정의
  TakePictureScreenState createState() => TakePictureScreenState(); // 인스턴스를 반환하는건데
}

/// [상태 클래스]
/// 1. 상태를 저장할 변수 관련
/// 2. 상태 저장 변수를 조작할 때
/// 상태를 여기서 정의
class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  ///
  /// 실제로 여기다가 그려지는 부분 정의
  @override
  Widget build(BuildContext context) {
    /// Scaffold는 머터리얼 디자인 앱을 만들 때 뼈대가 되는 위젯
    ///   ㄴ (1) AppBar
    ///   ㄴ (2) body
    ///   ㄴ (3) floatingActionButton
    return Scaffold(

      /// (1) AppBar
      appBar: AppBar(title: const Text('Take a picture')),      /// AppBar클래스의 인스턴스를 전달.
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.

      /// (2) body
      body: FutureBuilder<void>(                                ///
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),

      /// (3) floatingActionButton
      floatingActionButton: FloatingActionButton(               ///
        // Provide an onPressed callback.

        /// 버튼이 눌러지면 실행되는 부분. 여기에 동작시킬 코드를 함수 형태로 작성
        /// 함수를 인수로 전달하는 방법. onPressed: () { return 함수이름(); }   이런 식으로 하면 이름있는 인수에 전달하게 되는거임.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();



            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}