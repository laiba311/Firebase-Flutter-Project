library giphy_picker;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/model/giphy_client.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/model/giphy_preview_types.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/widgets/giphy_context.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/widgets/giphy_search_page.dart';

export 'package:finalfashiontimefrontend/customize_pacages/giphy/src/model/giphy_client.dart';
export 'package:finalfashiontimefrontend/customize_pacages/giphy/src/widgets/giphy_image.dart';
export 'package:finalfashiontimefrontend/customize_pacages/giphy/src/model/giphy_preview_types.dart';

typedef ErrorListener = void Function(GiphyError error);
//final DraggableScrollableController _draggableController = DraggableScrollableController();
/// Provides Giphy picker functionality.
class GiphyPicker {
  /// Renders a full screen modal dialog for searching, and selecting a Giphy image.
  static Future<GiphyGif?> pickGif({
    required BuildContext context,
    required String apiKey,
    String rating = GiphyRating.g,
    String lang = GiphyLanguage.english,
    bool sticker = false,
    Widget? title,
    ErrorListener? onError,
    bool showPreviewPage = true,
    bool showGiphyAttribution = true,
    bool fullScreenDialog = true,
    String searchHintText = 'Search GIPHY',
    GiphyPreviewType previewType = GiphyPreviewType.previewWebp,
    SearchTextBuilder? searchTextBuilder,
    AppBarBuilder? appBarBuilder,
    WidgetBuilder? loadingBuilder,
    ResultsBuilder? resultsBuilder,
    WidgetBuilder? noResultsBuilder,
    SearchErrorBuilder? errorBuilder,
    required DraggableScrollableController draggableController
  }) async {
    GiphyGif? result;
    await showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius
                .only(
                topLeft: Radius
                    .circular(
                    10),
                topRight: Radius
                    .circular(
                    10)
            )
        ),
        isScrollControlled: true,
        context: context,
        builder: (ctx) {
          return WillPopScope(
            onWillPop: () async {
              Navigator.pop(
                  ctx);
              return false; // Prevents the default back button behavior
            },
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                // Dismiss the keyboard when the user drags the bottom sheet
                print("simple enter");
                if (details.delta.dy < 0 || details.delta.dy > 0) {
                  print("enter comment if");
                  FocusScope.of(context).unfocus();
                }
              },
              child: DraggableScrollableSheet(
                  controller: draggableController,
                  expand: false,
                  // Ensures it doesn't expand fully by default
                  initialChildSize: 0.7,
                  // Half screen by default
                  minChildSize: 0.3,
                  // Minimum height
                  maxChildSize: 1.0,
                  builder: (BuildContext context1, ScrollController scrollController) {
                    return GestureDetector(
                      onVerticalDragUpdate: (details) {
                        // Dismiss the keyboard when the user drags the bottom sheet
                        print("simple enter");
                        if (details.delta.dy < 0 || details.delta.dy > 0) {
                          print("enter comment if");
                          FocusScope.of(context).unfocus();
                        }
                      },
                      child: GiphyContext(
                        previewType: previewType,
                        apiKey: apiKey,
                        rating: rating,
                        language: lang,
                        sticker: sticker,
                        onError: onError ?? (error) => _showErrorDialog(context, error),
                        onSelected: (gif) {
                          result = gif;
                          // pop preview page if necessary
                          if (showPreviewPage) {
                            Navigator.pop(context);
                          }
                          // pop giphy_picker
                          Navigator.pop(context);
                        },
                        showPreviewPage: showPreviewPage,
                        showGiphyAttribution: showGiphyAttribution,
                        searchHintText: searchHintText,
                        searchTextBuilder: searchTextBuilder,
                        appBarBuilder: appBarBuilder,
                        loadingBuilder: loadingBuilder,
                        resultsBuilder: resultsBuilder,
                        noResultsBuilder: noResultsBuilder,
                        errorBuilder: errorBuilder,
                        child: GiphySearchPage(
                          title: title,
                          scrollController: scrollController,
                        ),
                      )
                    );
                  }
              ),
            ),
          );
        });
    // await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (BuildContext context) => GiphyContext(
    //       previewType: previewType,
    //       apiKey: apiKey,
    //       rating: rating,
    //       language: lang,
    //       sticker: sticker,
    //       onError: onError ?? (error) => _showErrorDialog(context, error),
    //       onSelected: (gif) {
    //         result = gif;
    //         // pop preview page if necessary
    //         if (showPreviewPage) {
    //           Navigator.pop(context);
    //         }
    //         // pop giphy_picker
    //         Navigator.pop(context);
    //       },
    //       showPreviewPage: showPreviewPage,
    //       showGiphyAttribution: showGiphyAttribution,
    //       searchHintText: searchHintText,
    //       searchTextBuilder: searchTextBuilder,
    //       appBarBuilder: appBarBuilder,
    //       loadingBuilder: loadingBuilder,
    //       resultsBuilder: resultsBuilder,
    //       noResultsBuilder: noResultsBuilder,
    //       errorBuilder: errorBuilder,
    //       child: GiphySearchPage(
    //         title: title,
    //       ),
    //     ),
    //     fullscreenDialog: fullScreenDialog,
    //   ),
    // );

    return result;
  }

  static void _showErrorDialog(BuildContext context, GiphyError error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Giphy error'),
          content: Text(error.toString()),
          actions: <Widget>[
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
