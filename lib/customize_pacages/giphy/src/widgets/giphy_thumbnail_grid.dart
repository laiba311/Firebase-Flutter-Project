import 'package:flutter/material.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/model/giphy_repository.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/widgets/giphy_context.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/widgets/giphy_preview_page.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/widgets/giphy_thumbnail.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// A selectable grid view of gif thumbnails.
class GiphyThumbnailGrid extends StatefulWidget {
  final GiphyRepository repo;
  final ScrollController? scrollController;

  /// Creates a grid for given repository.
  const GiphyThumbnailGrid(
      {super.key, required this.repo, this.scrollController});

  @override
  State<GiphyThumbnailGrid> createState() => _GiphyThumbnailGridState();
}

class _GiphyThumbnailGridState extends State<GiphyThumbnailGrid> {
  @override
  Widget build(BuildContext context) {
    final giphy = GiphyContext.of(context);
    return MasonryGridView.count(
        padding: EdgeInsets.fromLTRB(
          10,
          10,
          10,
          // bottom padding takes attribution into account
          giphy.showGiphyAttribution ? 34 : 10,
        ),
        controller: widget.scrollController,
        itemCount: widget.repo.totalCount,
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemBuilder: (BuildContext context, int index) => GestureDetector(
            child: GiphyThumbnail(
                key: Key('$index'), repo: widget.repo, index: index),
            onTap: () async {
              // display preview page
              final giphy = GiphyContext.of(context);
              final gif = await widget.repo.get(index);
              if (gif != null) {
                if (context.mounted && giphy.showPreviewPage) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => GiphyPreviewPage(
                        gif: gif,
                        showGiphyAttribution: giphy.showGiphyAttribution,
                        onSelected: giphy.onSelected,
                        appBarBuilder: giphy.appBarBuilder,
                        title: gif.title?.isNotEmpty == true
                            ? Text(gif.title!)
                            : null,
                      ),
                    ),
                  );
                } else {
                  giphy.onSelected?.call(gif);
                }
              }
            }),

    );
  }
}
