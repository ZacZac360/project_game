import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GameDetailsScreen extends StatelessWidget {
  final int gameId;

  const GameDetailsScreen({required this.gameId});

  Future<Map<String, dynamic>> fetchGameDetails() async {
    const String apiKey = 'b4d316ada7dd4b51a4ec09d8e9ab3b48';
    final Uri url = Uri.parse('https://api.rawg.io/api/games/$gameId?key=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch game details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchGameDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final game = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  game['background_image'] != null
                      ? Image.network(game['background_image'], fit: BoxFit.cover)
                      : const SizedBox(height: 200, child: Placeholder()),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(game['name'], style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Released: ${game['released']}'),
                        const SizedBox(height: 8),
                        Text('Rating: ${game['rating']}'),
                        const SizedBox(height: 8),
                        Text('Metacritic: ${game['metacritic']}'),
                        const SizedBox(height: 8),
                        Text('Genres: ${game['genres'].map((g) => g['name']).join(', ')}'),
                        const SizedBox(height: 8),
                        Text('Developers: ${game['developers'].map((d) => d['name']).join(', ')}'),
                        const SizedBox(height: 8),
                        Text(game['description_raw'] ?? 'No description available'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}