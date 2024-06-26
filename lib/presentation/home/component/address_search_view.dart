import 'package:google_map_demo/presentation/home/component/place_provider.dart';
import 'package:google_map_demo/presentation/home/model/address_detail_model.dart';
import 'package:flutter/material.dart';

class AddressSearch extends SearchDelegate<Suggestion> {
  AddressSearch(this.sessionToken) {
    apiClient = PlaceApiProvider(sessionToken);
  }

  final String sessionToken;
  PlaceApiProvider? apiClient;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Clear',
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: query == ""
          ? null
          : apiClient?.fetchSuggestions(
              query, Localizations.localeOf(context).languageCode),
      builder: (context, snapshot) => query == ''
          ? Container(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'Enter address',
                style: TextStyle(),
              ),
            )
          : snapshot.hasData
              ? ListView.builder(
                  itemBuilder: (context, index) => ListTile(
                    title: Text(
                      (snapshot.data?[index] as Suggestion).description,
                      style: const TextStyle(),
                    ),
                    onTap: () {
                      close(context, snapshot.data?[index] as Suggestion);
                    },
                  ),
                  itemCount: snapshot.data?.length,
                )
              : const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
    );
  }
}

