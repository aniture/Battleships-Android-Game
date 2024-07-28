import 'package:battleships/models/GameData.dart';
import 'package:battleships/utils/httpservice.dart';
import 'package:battleships/views/GameList.dart';
import 'package:flutter/material.dart';

class GameViewPage extends StatefulWidget {
  final int gameId;

  GameViewPage({required this.gameId});

  @override
  _GameViewPageState createState() => _GameViewPageState();
}

class _GameViewPageState extends State<GameViewPage> {
  GameData? gameData;
  HttpService httpService = HttpService();
  List<String> selectedPositions = [];

  @override
  void initState() {
    super.initState();
    fetchGameData();
  }

  void checkGameOver() {
    if (gameData!.ships.length == 0 || gameData!.sunk.length == 5) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Game Over'),
            content: Text(
                'All ships of ${gameData!.ships.length == 0 ? gameData!.player1 : gameData!.player2} are sunk!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog first
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => GameListPage()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void fetchGameData() async {
    print("In fetch game data");
    Map<String, dynamic> fetchedData =
    await httpService.fetchGameDataFromApi(widget.gameId);
    setState(() {
      gameData = GameData.fromJson(fetchedData);
      checkGameOver();
    });
  }

  void playShot(String position) {
    if (gameData!.shots.contains(position)) {
      // If the shot has already been made at this position, show a Snackbar message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid shot! Position already targeted.'),
            duration: Duration(seconds: 2),
          )
      );
    } else {
      setState(() {
        selectedPositions.add(position); // Add the position to selectedPositions only if it hasn't been shot before
      });
    }
  }

  void submitShots() async {
    List<bool> response =
    await httpService.playShot(widget.gameId, selectedPositions);

    // Update the gameData based on the response
    setState(() {
      if (response[0] == true) {
        gameData!.sunk.add(selectedPositions[selectedPositions.length - 1]);
        fetchGameData();
      } else {
        gameData!.shots.add(selectedPositions[selectedPositions.length - 1]);
        fetchGameData();
      }
      checkGameOver();

      selectedPositions.clear(); // Clear the selected positions
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game ${widget.gameId}'),  backgroundColor:Colors.deepOrangeAccent),
      body: gameData == null ? CircularProgressIndicator() : buildGameGrid(),
      floatingActionButton: selectedPositions.isEmpty
          ? null
          : FloatingActionButton(
        onPressed: submitShots,
        child: Icon(Icons.check),
      ),
    );
  }

  Widget getGridIcon(String position) {
    List<Widget> texts = [];

    if (gameData!.sunk.contains(position)) {
      texts.add(Text(
        '💥',
        style: TextStyle(
          fontSize: 30, // Adjust the font size as needed
          color: Color.fromARGB(255, 255, 17, 0), // Adjust the color as needed
        ),
      ));
    }

    if (gameData!.ships.contains(position)) {
      texts.add(Text(
        '🚢',
        style: TextStyle(
            fontSize: 30, // Adjust the font size as needed
            color: Color.fromARGB(255, 0, 47, 255) // Adjust the color as needed
        ),
      ));
    }

    // Check if the position has been shot at.
    if (gameData!.shots.contains(position) && !gameData!.sunk.contains(position)) {
      texts.add(Text(
        '💣',
        style: TextStyle(
          fontSize: 30,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ));
    }

    if (gameData!.wrecks.contains(position)) {
      texts.add(Text(
        '🫧',
        style: TextStyle(
            fontSize: 30, // Adjust the font size as needed
            color: Color.fromARGB(255, 0, 47, 255) // Adjust the color as needed
        ),
      ));
    }

    if (texts.isEmpty) {
      return SizedBox();
    }

    if (texts.length == 1) {
      return texts.first;
    }

    return texts.isEmpty
        ? SizedBox()
        : Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: texts,
    );
  }

  Widget buildGameGrid() {
    return Container(
      width: 700,
      height: 700,
      child: Padding(
        padding: EdgeInsets.only(left: 20),  // Adds space in the left corner
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1, // Ensures square cells
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 25, // 5x5 grid
          itemBuilder: (context, index) {
            String position = getPositionFromIndex(index);
            bool isSelected = selectedPositions.contains(position);
            return GestureDetector(
              onTap: isSelected ? null : () => playShot(position),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  // color: getCellColor(position),
                ),
                child: Center(child: getGridIcon(position)),
              ),
            );
          },
        ),
      ),
    );
  }

  String getPositionFromIndex(int index) {
    int row = index ~/ 5; // Integer division to get row index
    int col = index % 5; // Remainder to get column index
    String rowLabel =
    String.fromCharCode('A'.codeUnitAt(0) + row); // Converts 0-4 to A-E
    String colLabel = (col + 1).toString(); // Converts 0-4 to 1-5
    return '$rowLabel$colLabel';
  }

  Color getCellColor(String position) {
    if (gameData!.ships.contains(position)) {
      return const Color.fromRGBO(76, 175, 80, 1); // Color for ship position
    } else if (gameData!.wrecks.contains(position)) {
      return Colors.red; // Color for wreck position
    } else if (gameData!.shots.contains(position)) {
      return Colors.yellow; // Color for shot position
    } else if (gameData!.sunk.contains(position)) {
      return Colors.deepOrangeAccent; // Color for sunk position
    }
    return Colors.white; // Default color for empty cell
  }

}