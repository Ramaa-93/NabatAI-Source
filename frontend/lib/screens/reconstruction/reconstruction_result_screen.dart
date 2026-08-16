import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReconstructionResultScreen
    extends StatelessWidget {
  final XFile currentImage;

  const ReconstructionResultScreen({
    super.key,
    required this.currentImage,
  });

  Widget _buildCurrentImage() {
    return FutureBuilder<Uint8List>(
      future: currentImage.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SizedBox(
            height: 260,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Text(
              'Could not display the selected image.',
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(8),
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoricalImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          'assets/images/heritage/roman_theater_historical.jpg',
          fit: BoxFit.contain,
          errorBuilder:
              (context, error, stackTrace) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: const Text(
                'Historical image could not be loaded.',
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historical Reconstruction',
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
              const Text(
                'Roman Theater Reconstruction',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Compare the current view with a historical reconstruction.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Current View',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _buildCurrentImage(),

              const SizedBox(height: 28),

              const Row(
                children: [
                  Icon(Icons.auto_awesome),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Historical Reconstruction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _buildHistoricalImage(),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Text(
                  'This visualization shows how the Roman Theater '
                  'may have looked in the past before deterioration '
                  'over time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Try Another Image',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}