import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  String? _errorMessage;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      _initializeCamera();
    } else if (status.isDenied) {
      setState(() {
        _errorMessage = 'Camera permission is required to scan your diary.';
        _permissionDenied = true;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _errorMessage = 'Camera permission is permanently denied.\nPlease enable it in Settings.';
        _permissionDenied = true;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } on CameraException catch (e) {
      setState(() {
        if (e.code == 'CameraAccessDenied') {
          _errorMessage = 'Camera permission denied.\nPlease enable camera access in Settings.';
          _permissionDenied = true;
        } else {
          _errorMessage = 'Camera error: ${e.description}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();
      
      // Run OCR using Google ML Kit
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      // Clean up the image file
      await File(imageFile.path).delete();

      final extractedText = recognizedText.text;
      
      if (mounted) {
        if (extractedText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text detected. Please try again.')),
          );
        } else {
          // Navigate to editor with OCR result
          context.go('/diaries/new', extra: {'scannedText': extractedText});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.go('/diaries'),
        ),
        title: const Text(
          'Scan Handwriting',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildCameraPreview(),
            ),
          ),
          
          // Capture button
          Padding(
            padding: const EdgeInsets.all(32),
            child: GestureDetector(
              onTap: (_isProcessing || !_isCameraInitialized) ? null : _captureAndProcess,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_isProcessing || !_isCameraInitialized) ? Colors.grey : Colors.white,
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          
          // Tips
          Padding(
            padding: const EdgeInsets.only(bottom: 32, left: 32, right: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.yellow[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ensure good lighting for best results',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _permissionDenied ? Icons.no_photography : Icons.camera_alt_outlined,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              if (_permissionDenied) ...[
                ElevatedButton(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _permissionDenied = false;
                    });
                    _requestCameraPermission();
                  },
                  child: const Text('Try Again', style: TextStyle(color: Colors.white70)),
                ),
              ] else
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                    _initializeCamera();
                  },
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }
}
