import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'dart:async';
import 'dart:convert';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Repo Explorer",
      theme: new ThemeData(primaryColor: Colors.blueGrey.shade600),
      home: new RepoScreen(),
    );
  }
}

class RepoScreen extends StatefulWidget {
  @override
  _RepoScreenState createState() => new _RepoScreenState();
}

class _RepoScreenState extends State<RepoScreen> {
  var _repos = <Repository>[];
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  _loadData(String searchTerm) async {
    setState(() {
      _isLoading = true;
    });
    final fetcher = new GitHubFetcher.dartRepos();
    final result = await fetcher.searchFor(searchTerm);
    setState(() {
      _repos = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Repo Explorer"),
        ),
        body: new Container(
          child: new Column(
            children: <Widget>[
              new TextField(
                decoration: new InputDecoration(
                    contentPadding: const EdgeInsets.all(16.0),
                    hintText: "Search Dart repositories..."),
                onSubmitted: (text) {
                  _loadData(text);
                },
              ),
              new Expanded(
                child: _isLoading
                ? new Center(child: new CircularProgressIndicator()) 
                : new ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _repos.length * 2,
                  itemBuilder: (BuildContext context, int position) {
                    if (position.isOdd) return new Divider();

                    final index = position ~/ 2;

                    return new RepositoryListItem(_repos[index]);
                  },
                ),
              ),
            ],
          ),
        ));
  }
}

class Repository {
  final String name;
  final String url;
  final String description;

  final String authorName;
  final String authorAvatarUrl;
  final int stars;

  Repository.fromJSON(Map jsonData)
      : name = jsonData['name'],
        url = jsonData['html_url'],
        description = jsonData['description'],
        authorName = jsonData['owner']['login'],
        authorAvatarUrl = jsonData['owner']['avatar_url'],
        stars = jsonData['stargazers_count'];
}

class GitHubFetcher {
  final String apiUrl;
  final String language;

  GitHubFetcher.dartRepos()
      : apiUrl = 'https://api.github.com/search/repositories',
        language = 'dart';

  Future<List<Repository>> searchFor(String searchTerm) async {
    if (searchTerm == null || searchTerm == "") {
      return new List();
    }

    final url = '$apiUrl?q=$searchTerm+language:$language&sort=stars';
    http.Response response = await http.get(url);
    Map data = JSON.decode(response.body);

    List<Repository> repositories = new List();
    final items = data['items'];
    if (items != null) {
      for (var jsonRepo in items) {
        final parsed = new Repository.fromJSON(jsonRepo);
        repositories.add(parsed);
      }
    }
    return repositories;
  }
}

class RepositoryListItem extends StatelessWidget {
  final Repository repository;
  RepositoryListItem(this.repository);

  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  Widget build(BuildContext context) {
    return new ListTile(
      title: new Text(
        "${repository.name}",
        style: _biggerFont,
      ),
      subtitle: new Text("${repository.authorName}"),
      leading: new CircleAvatar(
        backgroundImage: new NetworkImage(repository.authorAvatarUrl),
      ),
      trailing: new Row(
        children: <Widget>[
          new Icon(Icons.star, color: Colors.yellow.shade700),
          new Text(
            "${repository.stars}",
          )
        ],
      ),
      onTap: () {
        Navigator.push(
            context,
            new MaterialPageRoute(
              builder: (context) => new RepositoryDetailScreen(repository),
            ));
      },
    );
  }
}

class RepositoryDetailScreen extends StatelessWidget {
  final Repository repository;
  RepositoryDetailScreen(this.repository);

  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Repository Details"),
      ),
      body: new Container(
        child: new Padding(
          padding: const EdgeInsets.all(32.0),
          child: new Column(
            children: <Widget>[
              new Text(
                "${repository.name}",
                style: _biggerFont,
              ),
              new Container(height: 16.0),
              new Text("${repository.description}"),
              new Container(height: 16.0),
              new RaisedButton(
                child: new Text("Open"),
                onPressed: () {_openUrl(repository.url);},
              )
            ],
          ),
        )
      ),
    );
  }

  _openUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
