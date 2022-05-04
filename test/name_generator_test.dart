import 'package:english_words/english_words.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startup_namer/main.dart';

void main() {

  //Group for test organization
  group('RandomWordpairList', () {
    test('returns a list of wordpairs with the length of n',
            ()  {
          List<String> wordList= [
            "Lorem",
            "ipsum",
            "dolor",
          ];
          List<WordPair> wordPairList = getRandomWords(wordList, 20);

          //when the list input has length > 0, the output should equal n
          expect(wordPairList.length, 20);
        });

    test('returns proper results when given an empty string list', () {

      List<String> wordList= [];
      List<WordPair> wordPairList = getRandomWords(wordList, 20);

      //when the list input has length = 0, the output should equal 0
      expect(wordPairList.length, 0);
    });
  });
}