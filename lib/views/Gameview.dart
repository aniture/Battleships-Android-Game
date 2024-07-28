import 'package:battleships/utils/httpservice.dart';
import 'package:battleships/views/GameList.dart';
import 'package:flutter/material.dart';

class GameSetupPage extends StatefulWidget {
  String selectedAI = '';
  GameSetupPage({super.key, required this.selectedAI});
  @override
  _GameSetupPageState createState() => _GameSetupPageState();
}

class _GameSetupPageState extends State<GameSetupPage> {
  List<String> selectedPositions = [];
  HttpService httpService = HttpService();

  void togglePosition(String position) {
    setState(() {
      if (selectedPositions.contains(position)) {
        selectedPositions.remove(position);
      } else if (selectedPositions.length < 5) {
        selectedPositions.add(position);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Place Your Ships'),
        backgroundColor:Colors.deepOrangeAccent,),
      body: Column(
        children: [
          Expanded(
            child: buildGrid(),
          ),
          ElevatedButton(
            onPressed: selectedPositions.length == 5
                ? () => submitShips(widget.selectedAI)
                : null,
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget buildGrid() {
    // Set the size of the grid
    double gridWidth = 700.0; // Width of the grid
    double gridHeight = 700.0; // Height of the grid

    // Add padding on the left
    double leftPadding = 20.0; // Amount of space to leave on the left

    return Container(
      width: gridWidth + leftPadding, // Include the padding in the total width
      height: gridHeight,
      padding: EdgeInsets.only(left: leftPadding), // Apply padding only to the left
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1, // Maintain the aspect ratio of the grid cells
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 25, // 5x5 grid
        itemBuilder: (context, index) {
          String position = getPositionFromIndex(index);
          bool isSelected = selectedPositions.contains(position);

          return InkWell(
            onTap: () => togglePosition(position),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: isSelected ? Colors.deepOrangeAccent : Colors.white,
              ),
              child: Center(child: Text(position)),
            ),
          );
        },
      ),
    );
  }


  String getPositionFromIndex(int index) {
    String row = String.fromCharCode('A'.codeUnitAt(0) + (index / 5).floor());
    String column = (1 + index % 5).toString();
    return '$row$column';
  }

  void submitShips(String selectedAI) async {
    // Implement submission logic, possibly involving an API call
    Map<String, dynamic> response =
    await httpService.putGame(selectedPositions, widget.selectedAI);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameListPage()),
    );
  }
}
