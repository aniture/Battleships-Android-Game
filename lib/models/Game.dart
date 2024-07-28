class Game {
  final String gameId;
  final String playerOne;
  final String playerTwo;
  final String status;

  Game({
    required this.gameId,
    required this.playerOne,
    required this.playerTwo,
    required this.status,
  });

  // Factory constructor to create a Game from JSON data
  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      gameId: json['gameId'] as String,
      playerOne: json['playerOne'] as String,
      playerTwo: json['playerTwo'] as String,
      status: json['status'] as String,
    );
  }

  // Method to convert Game instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'playerOne': playerOne,
      'playerTwo': playerTwo,
      'status': status,
    };
  }
}
