import 'package:battleships/views/GamePage.dart';
import 'package:battleships/views/Gameview.dart';
import 'package:battleships/views/Login.dart';
import 'package:flutter/material.dart';
import 'package:battleships/utils/httpservice.dart';

enum AIOption { perfect, random, oneShot }

class GameListPage extends StatefulWidget {
  final String? username;

  GameListPage({Key? key, this.username}) : super(key: key);

  @override
  _GameListPageState createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  HttpService httpService = HttpService();

  bool _showCompletedGames = false;
  List<Map<String, dynamic>> games = [];
  List<Map<String, dynamic>> allGames = [];

  void initState() {
    super.initState();
    _fetchGames();
  }

  void _fetchGames() async {
    try {
      var fetchedGames = await httpService.getAllGames();
      setState(() {
        allGames = fetchedGames as List<Map<String, dynamic>>;
        games = allGames; // Initially display all games
        _showCompletedGames = false;
      });
    } catch (e) {
      print(e);
    }
  }

  void _toggleShowCompleted() {
    setState(() {
      _showCompletedGames = !_showCompletedGames;

      if (_showCompletedGames) {
        // Filter to show only completed games
        games = allGames
            .where((game) => game['status'] == 1 || game['status'] == 2)
            .toList();
      } else {
        // Show all games
        games = allGames;
      }
    });
  }

  void _startGame({bool withAI = false}) async {
    String selection = '';
    AIOption? selectedAI = AIOption.random;
    if (withAI == true) {
      selectedAI = await showDialog<AIOption>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Which AI do you want to play against?'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, AIOption.random);
                },
                child: const Text('Random AI'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, AIOption.perfect);
                },
                child: const Text('Perfect AI'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, AIOption.oneShot);
                },
                child: const Text('One Ship AI'),
              ),
            ],
          );
        },
      );
      if (selectedAI == AIOption.random) {
        selection = 'random';
      } else if (selectedAI == AIOption.perfect) {
        selection = 'perfect';
      } else if (selectedAI == AIOption.oneShot) {
        selection = 'oneship';
      }
    }
    // Logic for starting a game with a human opponent
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GameSetupPage(selectedAI: selection)),
    );
  }

  String _determineTurnStatus(Map<String, dynamic> game) {
    if (game["status"] == 3) {
      // If the game is actively being played
      return (game["position"] == game["turn"])
          ? "Your Turn"
          : "Opponent's Turn";
    }
    return _getStatusText(game["status"]);
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Matchmaking';
      case 1:
        return 'Player 1 Won';
      case 2:
        return 'Player 2 Won';
      case 3:
        return 'Game Active';
      default:
        return 'Unknown Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game List'),
        backgroundColor:Colors.deepOrangeAccent,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchGames, // Call the fetch games method
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              child:
              Text('Game Options', style: TextStyle(color: Colors.white)),
              decoration: BoxDecoration(color: Colors.deepOrangeAccent),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Logged in as ${widget.username}",
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            const Divider(
              color: Colors.black,
              height: 20,
              thickness: 1,
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text('Start Game with Human'),
              onTap: () => _startGame(withAI: false),
            ),
            ListTile(
              leading: const Icon(Icons.games_rounded),
              title: Text('Start Game with AI'),
              onTap: () => _startGame(withAI: true),
            ),
            SwitchListTile(
              title: Text('Show Completed Games'),
              value: _showCompletedGames,
              onChanged: (bool value) {
                _toggleShowCompleted();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: Text('Log Out'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          String status = '';
          status = _determineTurnStatus(game);
          return Dismissible(
            key: Key(game['id'].toString()),
            onDismissed: (direction) async {
              await httpService.deleteGame(game['id']);
              _fetchGames(); // Refresh the list of games after deletion
            },
            background: Container(color: Colors.red), // Customize as needed
            child: ListTile(
              title: Text('Game ID: ${game["id"]}'),
              subtitle: Text(
                  '${game["player1"] ?? "Unknown"}${game["player2"] != null ? ' vs ${game["player2"]}' : ''}'),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[Text(status)],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GameViewPage(gameId: game['id']),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () =>
            _startGame(withAI: false), // Start a game with a human opponent
      ),
    );
  }
}
