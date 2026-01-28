import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/providers/locale_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
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
      
      // Preload rewarded ad for potential bonus scan
      ref.read(adServiceProvider).loadRewardedAd();
      
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

  // Store the captured image for retry after watching ad
  String? _pendingImageBase64;

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analyzing handwriting with AI...'), duration: Duration(seconds: 2)),
        );
      }
      
      // Read image as base64
      final bytes = await File(imageFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      _pendingImageBase64 = base64Image;
      
      // Clean up the image file
      try {
        await File(imageFile.path).delete();
      } catch (_) {
        // Ignore cleanup errors
      }
      
      // Try to scan
      await _performScan(base64Image);
    } catch (e, stackTrace) {
      debugPrint('Capture Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _performScan(String base64Image) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final extractedText = await apiService.scanImage(base64Image);
      
      if (mounted) {
        if (extractedText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No text detected. Make sure the handwriting is visible.'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Text recognized successfully!'),
              duration: Duration(seconds: 1),
            ),
          );
          // Navigate to editor with OCR result
          context.go('/diaries/new', extra: {
            'scannedText': extractedText,
            'inputType': 'scan',
          });
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // Parse the error response to check if it's a scan limit error
        await _handleScanLimitError(e.response?.data);
      } else {
        _showError('Failed to process image: ${e.message}');
      }
    } catch (e) {
      _showError('Failed to process image: $e');
    }
  }

  Future<void> _handleScanLimitError(dynamic responseData) async {
    if (!mounted) return;
    final s = ref.read(stringsProvider);

    Map<String, dynamic>? errorData;
    try {
      if (responseData is String) {
        errorData = json.decode(responseData);
      } else if (responseData is Map) {
        errorData = Map<String, dynamic>.from(responseData);
      }
      // Handle nested error structure: { error: "..." } contains JSON string
      if (errorData != null && errorData['error'] is String) {
        try {
          final nestedData = json.decode(errorData['error']);
          if (nestedData is Map) {
            errorData = Map<String, dynamic>.from(nestedData);
          }
        } catch (_) {
          // error is just a plain string, not JSON
        }
      }
    } catch (_) {
      // Not a JSON response
    }

    debugPrint('Scan limit error data: $errorData');
    final canWatchAd = errorData?['canWatchAd'] == true;
    final bonusCount = errorData?['bonusCount'] ?? 0;
    final maxBonus = errorData?['maxBonus'] ?? 2;

    if (canWatchAd) {
      // Show dialog offering to watch ad for bonus scan
      final watchAd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.dailyScanLimitReached),
          content: Text(s.usedFreeScanWatchAd(maxBonus - bonusCount)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.watchAd),
            ),
          ],
        ),
      );

      if (watchAd == true && mounted) {
        await _watchAdForBonusScan();
      }
    } else {
      // Max bonus already reached
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.dailyScanLimitReached),
          content: Text(s.usedAllScansToday),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.ok),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _watchAdForBonusScan() async {
    final adService = ref.read(adServiceProvider);
    final s = ref.read(stringsProvider);
    
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.loadingAd), duration: const Duration(seconds: 5)),
      );
    }

    // If ad not ready, load it and wait
    if (!adService.isRewardedAdReady) {
      adService.loadRewardedAd();
      
      // Wait for ad to load (up to 10 seconds)
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (adService.isRewardedAdReady) break;
      }
    }

    // Check if ad is ready now
    if (!adService.isRewardedAdReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.adNotAvailable)),
        );
      }
      // Reload for next attempt
      adService.loadRewardedAd();
      return;
    }

    // Show rewarded ad
    final rewardEarned = await adService.showRewardedAd();

    if (rewardEarned && mounted) {
      try {
        // Grant bonus scan via API
        final apiService = ref.read(apiServiceProvider);
        await apiService.grantBonusScan();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.bonusScanGrantedRetrying),
            backgroundColor: Colors.green,
          ),
        );

        // Retry the scan with the pending image
        if (_pendingImageBase64 != null) {
          await _performScan(_pendingImageBase64!);
        }
      } catch (e) {
        _showError('Failed to grant bonus: $e');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.pleaseWatchCompleteAd)),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.go('/diaries'),
        ),
        title: Text(
          s.scanHandwriting,
          style: const TextStyle(color: Colors.white),
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
                Flexible(
                  child: Text(
                    s.ensureGoodLighting,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
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
