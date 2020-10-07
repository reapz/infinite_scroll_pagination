import 'package:breaking_bapp/character_summary.dart';
import 'package:breaking_bapp/presentation/common/character_list_item.dart';
import 'package:breaking_bapp/presentation/common/character_search_input_sliver.dart';
import 'package:breaking_bapp/remote_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class CharacterSliverList extends StatefulWidget {
  @override
  _CharacterSliverListState createState() => _CharacterSliverListState();
}

class _CharacterSliverListState extends State<CharacterSliverList> {
  static const _pageSize = 17;

  final PagingController<int, CharacterSummary> _pagingController =
      PagingController(firstPageKey: 0);

  String _searchTerm;

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    _pagingController.addStatusListener((status) {
      if (status == PagingStatus.subsequentPageError) {
        Scaffold.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Something went wrong while fetching a new page.',
            ),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _pagingController.retryLastRequest(),
            ),
          ),
        );
      }
    });

    super.initState();
  }

  void _fetchPage(pageKey) {
    RemoteApi.getCharacterList(pageKey, _pageSize, searchTerm: _searchTerm)
        .then((newItems) {
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    }).catchError((error) {
      _pagingController.error = error;
    });
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: <Widget>[
          CharacterSearchInputSliver(
            onChanged: (searchTerm) => _updateSearchTerm(searchTerm),
          ),
          PagedSliverList<int, CharacterSummary>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<CharacterSummary>(
              itemBuilder: (context, item, index) => CharacterListItem(
                character: item,
              ),
            ),
          ),
        ],
      );

  void _updateSearchTerm(String searchTerm) {
    _searchTerm = searchTerm;
    _pagingController.refresh();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
