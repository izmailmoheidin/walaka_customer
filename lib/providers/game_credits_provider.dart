import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_credit.dart';

class GameCreditsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<GameCredit> _gameCredits = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedGameType = '';

  // Game types
  final List<Map<String, String>> gameTypes = [
    {'id': 'pubg_global', 'name': 'PUBG Mobile Global'},
    {'id': 'pubg_kr', 'name': 'PUBG Mobile Korean'},
    {'id': 'free_fire', 'name': 'Free Fire'},
  ];

  // Getters
  List<GameCredit> get gameCredits => _gameCredits;
  List<GameCredit> get filteredGameCredits => _filterGameCredits();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedGameType => _selectedGameType;

  // Filter game credits based on search query and game type
  List<GameCredit> _filterGameCredits() {
    return _gameCredits.where((credit) {
      final matchesSearch = credit.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          credit.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGameType = _selectedGameType.isEmpty || credit.gameType == _selectedGameType;
      return matchesSearch && matchesGameType;
    }).toList();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set selected game type
  void setSelectedGameType(String gameType) {
    _selectedGameType = gameType;
    notifyListeners();
  }

  // Fetch game credits from Firestore
  Future<void> fetchGameCredits() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final QuerySnapshot snapshot = await _firestore.collectionGroup('credits').get();
      
      _gameCredits = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GameCredit.fromMap(doc.id, data);
      }).toList();
      
      // Sort by game type and price
      _gameCredits.sort((a, b) {
        int gameTypeComparison = a.gameType.compareTo(b.gameType);
        if (gameTypeComparison != 0) return gameTypeComparison;
        return a.price.compareTo(b.price);
      });
      
    } catch (e) {
      _error = 'Failed to fetch game credits: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new game credit
  Future<bool> addGameCredit(GameCredit gameCredit) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('games')
          .doc(gameCredit.gameType)
          .collection('credits')
          .add(gameCredit.toMap());
      
      await fetchGameCredits(); // Refresh the list
      return true;
    } catch (e) {
      _error = 'Failed to add game credit: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update existing game credit
  Future<bool> updateGameCredit(GameCredit gameCredit) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('games')
          .doc(gameCredit.gameType)
          .collection('credits')
          .doc(gameCredit.id)
          .update(gameCredit.toMap());
      
      await fetchGameCredits(); // Refresh the list
      return true;
    } catch (e) {
      _error = 'Failed to update game credit: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete game credit
  Future<bool> deleteGameCredit(GameCredit gameCredit) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('games')
          .doc(gameCredit.gameType)
          .collection('credits')
          .doc(gameCredit.id)
          .delete();
      
      await fetchGameCredits(); // Refresh the list
      return true;
    } catch (e) {
      _error = 'Failed to delete game credit: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get game type name by ID
  String getGameTypeName(String gameTypeId) {
    final gameType = gameTypes.firstWhere(
      (type) => type['id'] == gameTypeId,
      orElse: () => {'id': gameTypeId, 'name': gameTypeId},
    );
    return gameType['name'] ?? gameTypeId;
  }
}
