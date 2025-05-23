import 'package:flutter/material.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/widgets/giphy_context.dart';
import 'package:finalfashiontimefrontend/customize_pacages/giphy/src/widgets/giphy_search_view.dart';

/// The giphy search page.
class GiphySearchPage extends StatefulWidget {
  final Widget? title;
  final ScrollController scrollController;

  const GiphySearchPage({super.key, this.title, required this.scrollController});

  @override
  State<GiphySearchPage> createState() => _GiphySearchPageState();
}

class _GiphySearchPageState extends State<GiphySearchPage> {
  @override
  Widget build(BuildContext context) {
    final giphy = GiphyContext.of(context);
    return Scaffold(
      //appBar: giphy.appBarBuilder(context, title: widget.title),
      body: SafeArea(
        bottom: giphy.showGiphyAttribution,
        child: GiphySearchView(myScrollController: widget.scrollController,),
      ),
    );
  }
}
