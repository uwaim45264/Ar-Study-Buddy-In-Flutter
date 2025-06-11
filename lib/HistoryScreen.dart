import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:io';
import 'NoteDatabase.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> notes = [];
  bool isSharing = false;
  final FlutterTts _tts = FlutterTts();
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _configureTts();
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    print('HistoryScreen: TTS configured');
  }

  Future<void> _loadNotes() async {
    final loadedNotes = await NoteDatabase.getNotes();
    setState(() => notes = loadedNotes);
    print('HistoryScreen: Loaded ${notes.length} notes');
  }

  Future<void> _readAloud(String note) async {
    if (isSpeaking) {
      await _tts.stop();
      setState(() => isSpeaking = false);
      print('HistoryScreen: Stopped TTS');
      return;
    }
    setState(() => isSpeaking = true);
    try {
      String textToRead = note;
      if (note.startsWith('Captured Images:')) {
        textToRead = 'This note contains captured images.';
      }
      print('HistoryScreen: Reading note, length: ${textToRead.length}');
      await _tts.speak(textToRead);
      await _tts.awaitSpeakCompletion(true);
      print('HistoryScreen: Finished reading note');
    } catch (e) {
      print('HistoryScreen: Error reading aloud: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading aloud: $e')),
      );
    } finally {
      setState(() => isSpeaking = false);
    }
  }

  Future<void> _shareAsPdf(String note) async {
    if (isSharing) return;
    setState(() => isSharing = true);
    try {
      print('HistoryScreen: Sharing note, length: ${note.length}, content: ${note.substring(0, min(100, note.length))}...');
      final pdf = pw.Document();
      final isImageNote = note.startsWith('Captured Images:');
      final List<pw.Widget> content = [
        pw.Text('Study Buddy Note', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
      ];

      if (isImageNote) {
        final imagePaths = note.split('\n').skip(1).toList();
        for (int i = 0; i < imagePaths.length; i++) {
          final path = imagePaths[i];
          if (await File(path).exists()) {
            final imageBytes = await File(path).readAsBytes();
            final image = pw.MemoryImage(imageBytes);
            content.addAll([
              pw.Text('Image ${i + 1}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Image(image, width: 500, height: 600, fit: pw.BoxFit.cover),
              pw.SizedBox(height: 20),
            ]);
          } else {
            content.add(pw.Text('Image ${i + 1} not found', style: pw.TextStyle(fontSize: 14, ))); // Fixed: Used pw.PdfColor.fromInt
            print('HistoryScreen: Image not found at $path');
          }
        }
      } else {
        final lines = note.split('\n');
        content.addAll(lines.map((line) => pw.Text(line, style: const pw.TextStyle(fontSize: 14))).toList());
      }

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) => content,
        ),
      );

      final directory = await getTemporaryDirectory();
      print('HistoryScreen: Temporary directory path: ${directory.path}');
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filePath = '${directory.path}/note_$timestamp.pdf';
      final file = File(filePath);
      final testFile = File('${directory.path}/test.txt');
      await testFile.writeAsString('Test');
      await testFile.delete();
      print('HistoryScreen: Directory is writable');
      final pdfBytes = await pdf.save();
      print('HistoryScreen: Generated PDF, size: ${pdfBytes.length} bytes');
      await file.writeAsBytes(pdfBytes);
      print('HistoryScreen: Saved PDF at $filePath');
      final fileExists = await file.exists();
      final fileSize = await file.length();
      print('HistoryScreen: File exists: $fileExists, size: $fileSize bytes');
      await Share.shareXFiles([XFile(filePath)], text: 'Study Buddy Note');
      print('HistoryScreen: Shared PDF successfully');
    } catch (e, stackTrace) {
      print('HistoryScreen: Error sharing PDF: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing PDF: $e')),
      );
    } finally {
      setState(() => isSharing = false);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    print('HistoryScreen: Cleaning up TTS');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Saved Notes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6200EA), Color(0xFFBB86FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          notes.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 80,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notes saved yet',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final isImageNote = note.startsWith('Captured Images:');
              final imagePaths = isImageNote ? note.split('\n').skip(1).toList() : [];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  elevation: 4,
                  child: ExpansionTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.purple[300]!, Colors.blue[300]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      isImageNote
                          ? 'Captured Images (${imagePaths.length})'
                          : note.substring(0, min(50, note.length)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Note ${index + 1}${isImageNote ? ' (Images)' : ''}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isSpeaking ? Icons.stop_circle : Icons.volume_up_rounded,
                            color: Colors.white70,
                            size: 28,
                          ),
                          onPressed: () => _readAloud(note),
                          splashRadius: 24,
                          tooltip: isSpeaking ? 'Stop' : 'Read Aloud',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.share_rounded,
                            color: Colors.white70,
                            size: 28,
                          ),
                          onPressed: () => _shareAsPdf(note),
                          splashRadius: 24,
                          tooltip: 'Share as PDF',
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                          border: Border.all(
                            color: Colors.grey[800]!,
                            width: 0.5,
                          ),
                        ),
                        child: isImageNote
                            ? Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: imagePaths.map((path) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[600]!, width: 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.red,
                                        size: 50,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        )
                            : SingleChildScrollView(
                          child: Text(
                            note,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                    collapsedBackgroundColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    iconColor: Colors.white70,
                    collapsedIconColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            },
          ),
          if (isSharing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6200EA)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Preparing PDF...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}