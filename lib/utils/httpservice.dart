import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HttpService {
  static const String baseUrl = 'http://165.227.117.48';
  static dynamic accessToken = '';

  Future<Map<String, dynamic>> registerUser(
      String username, String password, BuildContext context) async {
    try {
      final response = await registerUserCall(username, password);
      return response;
    } catch (e) {
      showAlertDialog(context, 'Registration failed',
          'An error occurred. Please try again later.');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerUserCall(
      String username, String password) async {
    final url = Uri.parse('$baseUrl/register');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'username': username, 'password': password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      return {
        'statusCode': response.statusCode,
        'message': response.body,
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': "An error occurred. Please try again later."
      };
    }
  }

  Future<int> loginUser(String username, String password, context) async {
    try {
      final response = await http.post(
        Uri.parse('http://165.227.117.48/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        accessToken = data['access_token'];

        // Store the token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        showAlertDialog(context, 'Login Succesful', 'You are now logged in');
      } else {
        showAlertDialog(
            context, 'Login Failed', 'Incorrect username or password.');
      }
      return response.statusCode;
    } catch (e) {
      showAlertDialog(context, 'Login Failed',
          'An error occurred. Please try again later.');
      return 500;
    }
  }

  void showAlertDialog(context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<http.Response> getAuthenticatedData(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    return http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<List<Map<String, dynamic>>> getAllGames() async {
    final endpoint = '/games'; // Replace with the actual endpoint
    print(accessToken);
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<Map<String, dynamic>> games =
      List<Map<String, dynamic>>.from(responseData['games']);
      print(games.length);
      return games;
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception(
          'Failed to load games. Status code: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> putGame(
      List<String> shipPositions, String selectedAI) async {
    final endpoint = '/games'; // Replace with the actual endpoint
    print(shipPositions);
    final response;
    if (selectedAI != '') {
      response = await http.post(Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({"ships": shipPositions, "ai": selectedAI}));
    } else {
      response = await http.post(Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({"ships": shipPositions}));
    }
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON
      final Map<String, dynamic> responseData = json.decode(response.body);

      return responseData;
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception(
          'Failed to load games. Status code: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchGameDataFromApi(int id) async {
    final endpoint = '/games/$id'; // Replace with the actual endpoint
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON
      final Map<String, dynamic> responseData = json.decode(response.body);
      //final List<Map<String, dynamic>> games =
      //List<Map<String, dynamic>>.from(responseData['games']);
      return responseData;
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception(
          'Failed to load games. Status code: ${response.statusCode}');
    }
  }

  Future<List<bool>> playShot(int gameId, List<String> position) async {
    final endpoint = '/games/$gameId'; // Replace with the actual endpoint
    bool ship_sunk = false;
    bool won = false;
    print(endpoint + "  " + position[position.length - 1]);

    final response = await http.put(Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({"shot": position[position.length - 1]}));
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData.containsKey('ship_sunk')) {
        ship_sunk = responseData['ship_sunk'];
      }
      if (responseData.containsKey('won')) {
        won = responseData['won'];
      }
      return [ship_sunk, won];
    } else {
      throw Exception(
          'Failed to load games. Status code: ${response.statusCode}');
    }
  }

  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
        .remove('access_token'); // Assuming 'access_token' is your stored token
  }

  Future<void> deleteGame(int gameId) async {
    final endpoint = '/games/$gameId'; // Replace with the actual endpoint
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      // Game deleted successfully
      print('Game deleted successfully');
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception(
          'Failed to delete game. Status code: ${response.statusCode}');
    }
  }
}
