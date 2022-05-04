import 'dart:convert';
import 'dart:developer';
import 'package:flutter_test/flutter_test.dart';
import 'package:startup_namer/main.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

void main() {
  //Group for test organization
  group('NameGeneratorAPI', () {
    test('returns list of only strings when http response is successful',
            () async {

          // Mock the API call to return a json response with http status 200 Ok
          final mockHTTPClient = MockClient((request) async {

            // Create sample response of the HTTP call
            final response = [
              "Name",
              "Generator",
              "Test",
              "Strings",
              "ONLY",
              "@!#%^&*",
              "1234567890"
            ];
            return Response(jsonEncode(response), 200);
          });

          //Iterate through the list and verify all items are strings
          final allStrings = await fetchWords(mockHTTPClient);
          bool areAllStrings = true;
          allStrings.forEach((item) {
            if(item is! String){
              log(item);
              areAllStrings = false;
            }
          });

          expect(areAllStrings, true);
        });

    test('return error message when http response is unsuccessful', () async {

      // Mock the API call to return an empty json response with http status 404
      final mockHTTPClient = MockClient((request) async {
        final response = ["Failed to generate names"];
        return Response(jsonEncode(response), 404);
      });

      //Verify the expected response is returned
      expect((await fetchWords(mockHTTPClient))[0],
          "Failed to generate names");
    });
  });
}