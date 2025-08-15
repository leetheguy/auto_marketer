import 'package:flutter/material.dart';

// This is now a "dumb" StatelessWidget.
class ImageEditor extends StatelessWidget {
  const ImageEditor({
    super.key,
    this.sourceUrl,
    required this.onUpload,
  });

  final String? sourceUrl;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (sourceUrl != null && sourceUrl!.isNotEmpty)
            Expanded(
              child: Image.network(
                sourceUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Text('Could not load image.'));
                },
              ),
            )
          else
            const Expanded(
              child: Center(child: Text('No image uploaded yet.')),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload New Image'),
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}
