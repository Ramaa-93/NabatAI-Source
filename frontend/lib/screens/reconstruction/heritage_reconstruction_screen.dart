import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'reconstruction_result_screen.dart';

class HeritageReconstructionScreen extends StatefulWidget {
  const HeritageReconstructionScreen({super.key});

  @override
  State<HeritageReconstructionScreen> createState() =>
      _HeritageReconstructionScreenState();
}

class _HeritageReconstructionScreenState
    extends State<HeritageReconstructionScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;
  bool _isGenerating = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedImage == null) return;

      setState(() {
        _selectedImage = pickedImage;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Could not select the image. Please try again.';
      });
    }
  }

  Future<void> _generateReconstruction() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image first.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReconstructionResultScreen(
            currentImage: _selectedImage!,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Reconstruction failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _errorMessage = null;
    });
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                  ),
                  title: const Text('Take Photo'),
                  subtitle: const Text(
                    'Use your device camera',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                  ),
                  title: const Text(
                    'Choose from Gallery',
                  ),
                  subtitle: const Text(
                    'Select an existing image',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedImage() {
    if (_selectedImage == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _showImageSourceOptions,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 72,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Select a Roman Theater image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Camera or gallery',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(8),
            child: FutureBuilder<Uint8List>(
              future: _selectedImage!.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData) {
                  return const Center(
                    child: Text(
                      'Could not display the image.',
                    ),
                  );
                }

                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                );
              },
            ),
          ),

          Positioned(
            top: 12,
            right: 12,
            child: IconButton.filled(
              onPressed:
                  _isGenerating ? null : _removeImage,
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Heritage Reconstruction',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 72,
              ),

              const SizedBox(height: 16),

              const Text(
                'Reconstruct History with AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Take or upload a photo of the Roman Theater '
                'and discover how it may have looked in the past.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              Container(
                height: 330,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: _buildSelectedImage(),
              ),

              const SizedBox(height: 18),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
              ],

              OutlinedButton.icon(
                onPressed: _isGenerating
                    ? null
                    : _showImageSourceOptions,
                icon: const Icon(
                  Icons.image_search_outlined,
                ),
                label: Text(
                  _selectedImage == null
                      ? 'Select Image'
                      : 'Choose Another Image',
                ),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed:
                    _selectedImage == null ||
                            _isGenerating
                        ? null
                        : _generateReconstruction,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome,
                      ),
                label: Text(
                  _isGenerating
                      ? 'Generating Reconstruction...'
                      : 'Generate Reconstruction',
                ),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'For the demo, upload or capture a clear photo '
                'of the Roman Theater to view its historical reconstruction.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}