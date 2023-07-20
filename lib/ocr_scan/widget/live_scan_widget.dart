import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_scan_text/ocr_scan/widget/scan_widget.dart';

/// Widget permetant le Scan en "live" a l'aide de la camera
class LiveScanWidget extends ScanWidget {
  /// On respecte le ratio de la camera pour l'affichage de la preview
  final bool respectRatio;
  const LiveScanWidget({
    super.key,
    required super.scanModules,
    required super.matchedResult,
    this.respectRatio = false,
  });

  @override
  LiveScanWidgetState createState() => LiveScanWidgetState();
}

class LiveScanWidgetState extends ScanWidgetState<LiveScanWidget> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  /// On affiche le widget de la camera des que celui-ci est pret
  @override
  Widget build(BuildContext context) {
    return _controller == null || _controller?.value == null || _controller?.value.isInitialized == false
        ? Container()
        : _cameraWidget();
  }

  /// Widget de la camera affichant la preview
  Widget _cameraWidget() {
    final CameraController? cameraController = _controller;
    cameraController?.lockCaptureOrientation(DeviceOrientation.portraitUp);

    final size = MediaQuery.of(context).size;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container(
        width: size.width,
        height: size.height,
        color: Colors.black,
      );
    } else {
      CustomPaint? customPaint = this.customPaint;

      /// Preview de la camera
      CameraPreview preview = CameraPreview(
        cameraController,
        child: customPaint == null
            ? null
            : LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return customPaint;
                },
              ),
      );

      return widget.respectRatio
          ? preview
          : Stack(
              children: [
                SizedBox(
                  width: size.width,
                  height: size.height,
                  child: AspectRatio(
                    aspectRatio: cameraController.value.aspectRatio,
                    child: preview,
                  ),
                ),
              ],
            );
    }
  }

  /// Lance l'analyse de l'image
  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize;

    imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final camera = _cameras[0];
    final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (inputImageFormat == null) return;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImageMetadata(
          bytesPerRow: plane.bytesPerRow,
          size: Size(
            plane.width?.toDouble() ?? 0,
            plane.height?.toDouble() ?? 0,
          ),
          rotation: imageRotation,
          format: inputImageFormat,
        );
      },
    ).toList();

    final inputImageData = InputImageMetadata(
      size: imageSize,
      format: inputImageFormat,
      bytesPerRow: planeData.first.bytesPerRow,
      rotation: InputImageRotation.rotation90deg,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );

    processImage(
      inputImage,
      imageSize,
    );
  }

  /// Demarrage de la camera
  Future _startCamera() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.max);
    final camera = _cameras[0];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            break;
          default:
            break;
        }
      }
    });
  }

  /// Arret de la camera
  Future _stopCamera() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
