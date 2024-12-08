import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'game_details_screen.dart';

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  _GameListScreenState createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  List<dynamic> games = [];
  List<dynamic> favoritedGames = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  String apiKey = 'b4d316ada7dd4b51a4ec09d8e9ab3b48';
  String nextPageUrl = '';
  Map<String, dynamic>? currentFilters;
  bool showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames({Map<String, dynamic>? filters, String? searchQuery}) async {
    setState(() {
      isLoading = true;
      currentFilters = filters;
    });

    try {
      String url = 'https://api.rawg.io/api/games?key=$apiKey';

      if (searchQuery != null && searchQuery.isNotEmpty) {
        url += '&search=$searchQuery';
      } else if (filters != null) {
        if (filters['genre'] != null) {
          url += '&genres=${filters['genre'].toLowerCase()}';
        }
        if (filters['platform'] != null) {
          final platformMapping = {
            'PC': '4',
            'PlayStation': '18',
            'Xbox': '1',
            'Nintendo Switch': '7',
            'Mobile': '3',
          };
          url += '&platforms=${platformMapping[filters['platform']]}';
        }
        if (filters['minMetacritic'] != null) {
          url += '&metacritic=${filters['minMetacritic'].toInt()}';
        }
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          games = data['results'];
          nextPageUrl = data['next'] ?? '';
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load games');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch games.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchMoreGames() async {
    if (isFetchingMore || nextPageUrl.isEmpty) return;

    setState(() {
      isFetchingMore = true;
    });

    try {
      final response = await http.get(Uri.parse(nextPageUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          games.addAll(data['results']);
          nextPageUrl = data['next'] ?? '';
          isFetchingMore = false;
        });
      } else {
        throw Exception('Failed to load more games');
      }
    } catch (e) {
      setState(() {
        isFetchingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch more games.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void toggleFavorite(dynamic game) {
    setState(() {
      if (favoritedGames.contains(game)) {
        favoritedGames.remove(game);
      } else {
        favoritedGames.add(game);
      }
    });
  }

  void openFilterDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return FilterDialog(
          onApplyFilters: (filters) {
            fetchGames(filters: filters);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedGames = showFavoritesOnly ? favoritedGames : games;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RAWG Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: openFilterDialog,
          ),
          IconButton(
            icon: Icon(showFavoritesOnly ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search games...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (query) {
                fetchGames(searchQuery: query);
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification.metrics.pixels ==
              scrollNotification.metrics.maxScrollExtent &&
              !isFetchingMore) {
            fetchMoreGames();
          }
          return false;
        },
        child: ListView.builder(
          itemCount: displayedGames.length + (isFetchingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == displayedGames.length) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final game = displayedGames[index];
            final isFavorited = favoritedGames.contains(game);

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: game['background_image'] != null
                    ? Image.network(
                  game['background_image'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                    : const SizedBox(
                    width: 50, height: 50, child: Placeholder()),
                title: Text(game['name'] ?? 'Unknown Game'),
                subtitle: Text('Rating: ${game['rating'] ?? 'N/A'}'),
                trailing: IconButton(
                  icon: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited ? Colors.red : null,
                  ),
                  onPressed: () => toggleFavorite(game),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GameDetailsScreen(gameId: game['id']),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class FilterDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterDialog({Key? key, required this.onApplyFilters})
      : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? selectedGenre;
  String? selectedPlatform;
  double minMetacritic = 0;

  final List<String> genres = [
    'Action',
    'Adventure',
    'RPG',
    'Shooter',
    'Strategy',
    'Sports',
  ];

  final List<String> platforms = [
    'PC',
    'PlayStation',
    'Xbox',
    'Nintendo Switch',
    'Mobile',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filters'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Genre'),
            DropdownButton<String>(
              value: selectedGenre,
              onChanged: (value) {
                setState(() {
                  selectedGenre = value;
                });
              },
              items: genres.map((genre) {
                return DropdownMenuItem(
                  value: genre,
                  child: Text(genre),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Platform'),
            DropdownButton<String>(
              value: selectedPlatform,
              onChanged: (value) {
                setState(() {
                  selectedPlatform = value;
                });
              },
              items: platforms.map((platform) {
                return DropdownMenuItem(
                  value: platform,
                  child: Text(platform),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Minimum Metacritic Score'),
            Slider(
              value: minMetacritic,
              min: 0,
              max: 100,
              divisions: 20,
              label: minMetacritic.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  minMetacritic = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApplyFilters({
              'genre': selectedGenre,
              'platform': selectedPlatform,
              'minMetacritic': minMetacritic,
            });
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
