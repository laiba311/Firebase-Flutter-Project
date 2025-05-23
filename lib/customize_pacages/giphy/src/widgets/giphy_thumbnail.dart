import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/model/giphy_repository.dart';

/// Loads and renders a gif thumbnail image using a GiphyRepostory and an index.
class GiphyThumbnail extends StatefulWidget {
  final GiphyRepository repo;
  final int index;
  final Widget? placeholder;

  /// Creates a thumbnail for given index in the repository.
  const GiphyThumbnail(
      {super.key, required this.repo, required this.index, this.placeholder});

  @override
  State<GiphyThumbnail> createState() => _GiphyThumbnailState();
}

class _GiphyThumbnailState extends State<GiphyThumbnail> {
  late Future<Uint8List?> _loadPreview;

  @override
  void initState() {
    _loadPreview = widget.repo.getPreview(widget.index);
    super.initState();
  }

  @override
  void dispose() {
    widget.repo.cancelGetPreview(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _loadPreview,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (!snapshot.hasData) {
          return widget.placeholder ?? Container(
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          ),
        );
      });
}
