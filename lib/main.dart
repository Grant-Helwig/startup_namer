// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

//main colors used for the app, pulled from the Evosus logo
const Color EvosusOrange = Color.fromRGBO(252, 148, 68, 1);
const Color EvosusGrey = Color.fromRGBO(72, 68, 68, 1);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',

      //Apply Evosus Colors to UI and Text
      theme: ThemeData(
        primaryColor: EvosusOrange,
        scaffoldBackgroundColor: Colors.white,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: EvosusGrey,
              displayColor: EvosusGrey,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: EvosusOrange,
          foregroundColor: EvosusGrey,
        ),
      ),
      home: const RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> with TickerProviderStateMixin {
  //wordpair objects for list display
  final _suggestions = <WordPair>[];

  //wordpair objects that are selected as favorites
  final _favorites = <WordPair>[];

  //TextStyle used for all list fonts
  final _biggerFont = const TextStyle(fontSize: 18);

  //Future List used for Words taken from the API call
  late Future<List<String>> _futureSuggestions;

  //Animation controller is needed for loading indicator
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    //API is only called once in the initState
    _futureSuggestions = fetchWords(http.Client());

    //Initialize the controller with a 2 second duration
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
      setState(() {});
    });
    controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  //Function that navigates to and constructs the Favorites page
  void _pushFavorites() {
    Navigator.of(context).push(

      //MaterialPageRoute is needed to transition the entire page
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Favorites'),
            ),

            //ListView build is needed in order to identify items in the favorites list
            body: ListView.builder(
              padding: const EdgeInsets.all(5.0),
              itemCount: _favorites.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ListTile(
                    title: Text(
                      _favorites[i].asPascalCase,
                      style: _biggerFont,
                    ),

                    //Added a full border instead of dividing the tiles
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(color: EvosusOrange, width: 1),
                        borderRadius: BorderRadius.circular(5)
                    ),

                    //Added a trailing icon to the list that signifies Copy Functionality
                    trailing: const Icon(
                      Icons.content_copy,
                      color: EvosusGrey,
                      semanticLabel: 'Copy to Clipboard',
                    ),
                    onTap: () {
                      setState(() {

                        //Copies the name to your clipboard
                        Clipboard.setData(
                            ClipboardData(text: _favorites[i].asPascalCase));

                        //Displays a confirmation message at the bottom of the app
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Copied to Clipboard"))
                        );
                      });
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _pushFavorites,
            tooltip: 'My Favorites',
          ),
        ],
      ),

      //FutureBuilder is needed to account for asynchronous objects
      body: FutureBuilder<List<String>>(

        //Suggestions list is added as 'future' and accessed through suggestionsSnapshot
        future: _futureSuggestions,
        builder: (context, suggestionsSnapshot) {

          //Only display the list if the Future list has data to display
          if (suggestionsSnapshot.hasData) {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) {

                //Every other item in the list is a horizontal line
                if (i.isOdd) return const Divider();

                //This skips the divider lines and gets the actual wordpairs
                final index = i ~/ 2;

                //Add 10 items to the list when the bottom is reached
                if (index >= _suggestions.length) {
                  _suggestions
                      .addAll(getRandomWords(suggestionsSnapshot.data!, 10));
                }

                //boolean check for the favorite functionality
                final alreadySaved = _favorites.contains(_suggestions[index]);

                return ListTile(
                  title: Text(
                    _suggestions[index].asPascalCase,
                    style: _biggerFont,
                  ),

                  //Update the trailing icon if it is selected
                  trailing: Icon(
                    alreadySaved
                        ? Icons.fireplace
                        : Icons.check_box_outline_blank_sharp,
                    color: alreadySaved ? EvosusOrange : EvosusGrey,
                    semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
                  ),

                  //Add the name to the favorites list if it selected
                  onTap: () {
                    setState(() {
                      if (alreadySaved) {
                        _favorites.remove(_suggestions[index]);
                      } else {
                        _favorites.add(_suggestions[index]);
                      }
                    });
                  },
                );
              },
            );
          }

          //otherwise return the animated progress indicator
          else {
            return Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: controller.value,
                color: EvosusOrange,
                semanticsLabel: 'Linear progress indicator',
              ),
            );
          }
        },
      ),
    );
  }
}

//API call for word list that logs failures
Future<List<String>> fetchWords(http.Client http) async {

  final response =
    await http.get(Uri.parse('https://random-word-api.herokuapp.com/word?number=100'));

  if (response.statusCode == 200) {
    log(response.statusCode.toString());
    log(response.body);
    List<dynamic> json = jsonDecode(response.body);
    return List<String>.from(json);

  } else {
    log(response.statusCode.toString());
    return ["Failed to generate names"];
  }
}

//Returns a list of random wordpairs of length n
List<WordPair> getRandomWords(List<String> allWords, int n) {
  List<WordPair> allWordPairs = <WordPair>[];
  math.Random random = math.Random();
  if(allWords.isEmpty){
    return allWordPairs;
  }
  for (int i = 0; i < n; i++) {
    allWordPairs.add(WordPair(allWords[random.nextInt(allWords.length)],
        allWords[random.nextInt(allWords.length)]));
    log(allWordPairs[i].asPascalCase);
  }
  return allWordPairs;
}
