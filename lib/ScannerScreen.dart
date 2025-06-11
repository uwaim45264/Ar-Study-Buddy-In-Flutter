import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:async';
import 'NoteDatabase.dart';

class ScannerScreen extends StatefulWidget {
  final CameraDescription camera;
  const ScannerScreen({required this.camera, super.key});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  CameraController? _controller;
  List<String> scannedTextList = [];
  bool isScanning = false;
  String errorMessage = '';
  bool isFocused = false;
  double _zoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut);
    _fadeController!.forward();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      print('ScannerScreen: Camera initialized successfully'); // Debug log
      _maxZoomLevel = await _controller!.getMaxZoomLevel();
      await _controller!.setZoomLevel(_zoomLevel);
      await _controller!.setFocusMode(FocusMode.auto);
      setState(() => isFocused = true);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('ScannerScreen: Camera initialization failed: $e'); // Debug log
      setState(() => errorMessage = 'Camera initialization failed: $e');
    }
  }

  void _onZoomChanged(double scale) {
    setState(() {
      _zoomLevel = (_zoomLevel * scale).clamp(1.0, _maxZoomLevel);
      _controller!.setZoomLevel(_zoomLevel);
    });
  }

  Future<void> _showContinueDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF3E5F5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Continue Scanning?',
            style: TextStyle(
              color: Color(0xFF6200EA),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Do you want to continue scanning more text?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'No',
                style: TextStyle(color: Color(0xFF6200EA)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _saveAndExit();
              },
            ),
            TextButton(
              child: const Text(
                'Yes',
                style: TextStyle(color: Color(0xFF6200EA)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => isScanning = false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAndExit() async {
    if (scannedTextList.isNotEmpty) {
      final combinedText = scannedTextList.join('\n\n');
      await NoteDatabase.saveNote(combinedText);
      print('ScannerScreen: Saved accumulated text, length: ${combinedText.length}'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All scanned text saved!'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
    }
    Navigator.pop(context); // Return to HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Scan Notes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6200EA), Color(0xFF8B00E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 4,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF3E5F5), Color(0xFFE8EAF6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          errorMessage.isEmpty ? 'Initializing camera...' : errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please grant camera permission in settings'),
                                    backgroundColor: Color(0xFF00C853),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12.0), // Reduced padding
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00C853), Color(0xFF00E676)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.settings_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 6), // Reduced spacing
                                      Text(
                                        'Check Permissions',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Notes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6200EA), Color(0xFF8B00E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFE8EAF6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GestureDetector(
          onScaleUpdate: (details) {
            _onZoomChanged(details.scale);
          },
          child: Stack(
            children: [
              CameraPreview(_controller!),
              FadeTransition(
                opacity: _fadeAnimation!,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: isFocused ? Colors.green : Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Align text within the frame\nPinch to zoom',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          backgroundColor: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isScanning || !isFocused ? null : _scanAndSaveText,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isScanning || !isFocused
                                    ? [Colors.grey.shade300, Colors.grey.shade400]
                                    : [Colors.blue.shade400, Colors.blue.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isScanning ? 'Scanning...' : 'Scan Notes',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: scannedTextList.isEmpty ? null : _saveAndExit,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: scannedTextList.isEmpty
                                    ? [Colors.grey.shade300, Colors.grey.shade400]
                                    : [Color(0xFF00C853), Color(0xFF00E676)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.save_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Complete',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (scannedTextList.isNotEmpty)
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          'Scanned:\n${scannedTextList.join('\n\n')}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (errorMessage.isNotEmpty)
                Positioned(
                  top: 80,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 4,
                    color: Colors.red.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 80,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Zoom: ${_zoomLevel.toStringAsFixed(1)}x | ${isFocused ? 'Camera focused' : 'Waiting for focus...'}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanAndSaveText() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      setState(() => errorMessage = 'Camera not initialized');
      return;
    }
    setState(() {
      isScanning = true;
      errorMessage = '';
    });
    try {
      await _controller!.setFocusMode(FocusMode.auto);
      final image = await _controller!.takePicture();
      print('ScannerScreen: Image captured: ${image.path}'); // Debug log
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await textRecognizer.processImage(inputImage);
      final text = recognizedText.text.trim();
      print('ScannerScreen: Recognized text length: ${text.length}, content: $text'); // Debug log
      if (text.isNotEmpty) {
        setState(() {
          scannedTextList.add(text);
        });
        print('ScannerScreen: Added to list, total segments: ${scannedTextList.length}'); // Debug log
      } else {
        setState(() => errorMessage = 'No text detected. Try a clearer, well-lit text.');
        print('ScannerScreen: No text detected'); // Debug log
      }
    } catch (e) {
      print('ScannerScreen: Error during text recognition: $e'); // Debug log
      setState(() => errorMessage = 'Error scanning text: $e');
    } finally {
      await _showContinueDialog();
    }
  }

  @override
  void dispose() {
    print('ScannerScreen: Cleaning up'); // Debug log
    _controller?.dispose();
    _fadeController!.dispose();
    textRecognizer.close();
    super.dispose();
  }
}