import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/features/patient/patient_providers.dart';
import 'package:mitracare_app/services/localization_service.dart';

class GamePlayScreen extends ConsumerStatefulWidget {
  final String activityId;
  final String title;
  final String difficulty;

  const GamePlayScreen({
    super.key,
    required this.activityId,
    required this.title,
    required this.difficulty,
  });

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
  String? _sessionId;
  bool _isLoading = true;
  bool _isFinished = false;
  int _score = 0;
  String _gameState = "PLAYING"; // "PLAYING", "SUCCESS", "FAILED"

  // Game 1: Find the Match (Card Matching)
  List<String> _cardSymbols = [];
  List<bool> _cardFlipped = [];
  List<bool> _cardMatched = [];
  int _firstSelectedIndex = -1;
  bool _canFlip = true;

  // Game 2: Remember Pictures
  int _timerSeconds = 5;
  Timer? _countdownTimer;
  bool _showQuestion = false;
  int _selectedAnswerIndex = -1;
  final List<String> _rememberEmojis = ["🍎", "🪑", "🌸", "🚗", "🏐", "☂️", "🌲", "☕", "⏰"];
  final List<int> _rememberSelectedIndices = [];
  final List<int> _rememberTargetIndices = [0, 2, 4]; // E.g., Apple, Flower, Beach Ball

  // Game 3: Spot the Difference
  int _differentItemIndex = -1;
  final List<String> _patternSymbols = [];

  // Game 4: Bihu Drum Rhythm (Simon Says sequence match)
  List<int> _drumSequence = [];
  List<int> _playerSequence = [];
  int _sequenceHighlight = -1;
  bool _showingSequence = true;

  // Game 5: Sort the Harvest
  List<Map<String, dynamic>> _harvestItems = [];
  int _currentHarvestIndex = 0;

  // Game 6: Word Search / Unscramble
  List<Map<String, dynamic>> _scrambledWords = [];
  int _currentWordIndex = 0;
  int _selectedWordOption = -1;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSession() async {
    try {
      final repo = ref.read(activityRepositoryProvider);
      final session = await repo.startSession(widget.activityId, difficulty: widget.difficulty);
      setState(() {
        _sessionId = session['id'];
        _isLoading = false;
      });
      _initGame();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error starting game session: $e")),
        );
        Navigator.pop(context);
      }
    }
  }

  void _initGame() {
    final cleanTitle = widget.title.trim();
    if (cleanTitle.contains("Match") || cleanTitle.contains("milan") || cleanTitle.contains("মিল")) {
      // Find the Match Game
      final baseSymbols = ["🦏", "🍵", "👒", "🎋"]; // Rhino, Assam Tea, Japi, Bamboo
      _cardSymbols = [...baseSymbols, ...baseSymbols]..shuffle();
      _cardFlipped = List.generate(8, (_) => false);
      _cardMatched = List.generate(8, (_) => false);
    } else if (cleanTitle.contains("Remember") || cleanTitle.contains("yad") || cleanTitle.contains("ছবি")) {
      // Remember Pictures Game
      _timerSeconds = 5;
      _showQuestion = false;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_timerSeconds > 1) {
              _timerSeconds--;
            } else {
              _countdownTimer?.cancel();
              _showQuestion = true;
            }
          });
        }
      });
    } else if (cleanTitle.contains("Rhythm") || cleanTitle.contains("Drum") || cleanTitle.contains("তাল")) {
      // Bihu Drum Rhythm
      _drumSequence = [0, 2, 1, 0]; // 0: Dhol, 1: Gogona, 2: Tal/Bell
      _playerSequence = [];
      _showingSequence = true;
      _playSequenceDemo();
    } else if (cleanTitle.contains("Harvest") || cleanTitle.contains("ফচল") || cleanTitle.contains("फसल")) {
      // Sort the Harvest
      _harvestItems = [
        {"name": "Assam Tea Leaves 🌿", "category": "TEA"},
        {"name": "Naga King Chilli 🌶️", "category": "SPICE"},
        {"name": "Organic Ginger 🫚", "category": "SPICE"},
        {"name": "Bhut Jolokia Chilli 🌶️", "category": "SPICE"},
        {"name": "Bamboo Shoots 🎋", "category": "TEA"},
      ];
      _currentHarvestIndex = 0;
    } else if (cleanTitle.contains("Word") || cleanTitle.contains("Unscramble") || cleanTitle.contains("शब्द")) {
      // Northeast Word Search
      _scrambledWords = [
        {
          "scrambled": "I N H R O",
          "hint": "One-horned animal of Assam (অসমৰ এশিঙীয়া গঁড়)",
          "options": ["RHINO", "HORIN", "ROHIN"],
          "correct": 0
        },
        {
          "scrambled": "J A L I M U",
          "hint": "Largest river island in Brahmaputra (মাজুলী)",
          "options": ["JALIMU", "MAJULI", "LIJUMA"],
          "correct": 1
        },
        {
          "scrambled": "G T N A W A",
          "hint": "Beautiful monastery town (তৱাং)",
          "options": ["TAWANG", "TANWAG", "WANGTA"],
          "correct": 0
        }
      ];
      _currentWordIndex = 0;
      _selectedWordOption = -1;
    } else {
      // Spot the Difference (Grid pattern attention game)
      final normalSymbol = "💮"; // traditional weaving motif
      final diffSymbol = "🏵️"; // slightly different motif
      _differentItemIndex = (List.generate(9, (index) => index)..shuffle()).first;
      for (int i = 0; i < 9; i++) {
        _patternSymbols.add(i == _differentItemIndex ? diffSymbol : normalSymbol);
      }
    }
  }

  // --- Rhythm Sequence Demo Player ---
  void _playSequenceDemo() async {
    for (int i = 0; i < _drumSequence.length; i++) {
      await Future.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      setState(() {
        _sequenceHighlight = _drumSequence[i];
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _sequenceHighlight = -1;
      });
    }
    if (mounted) {
      setState(() {
        _showingSequence = false;
      });
    }
  }

  // --- Actions ---

  void _handleCardTap(int index) {
    if (!_canFlip || _cardFlipped[index] || _cardMatched[index]) return;

    setState(() {
      _cardFlipped[index] = true;
    });

    if (_firstSelectedIndex == -1) {
      _firstSelectedIndex = index;
    } else {
      final prevIndex = _firstSelectedIndex;
      _firstSelectedIndex = -1;
      _canFlip = false;

      if (_cardSymbols[prevIndex] == _cardSymbols[index]) {
        // Match!
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _cardMatched[prevIndex] = true;
              _cardMatched[index] = true;
              _canFlip = true;
              
              if (_cardMatched.every((m) => m)) {
                _completeGame(100);
              }
            });
          }
        });
      } else {
        // No match
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _cardFlipped[prevIndex] = false;
              _cardFlipped[index] = false;
              _canFlip = true;
            });
          }
        });
      }
    }
  }

  void _handleAnswerSelect(int index) {
    setState(() {
      _selectedAnswerIndex = index;
    });
    if (index == 0) {
      _completeGame(100);
    } else {
      _completeGame(40);
    }
  }

  void _handleSpotTap(int index) {
    if (index == _differentItemIndex) {
      _completeGame(100);
    } else {
      setState(() {
        _gameState = "FAILED";
      });
      _completeGame(30);
    }
  }

  void _handleDrumTap(int drumIndex) {
    if (_showingSequence) return;
    setState(() {
      _sequenceHighlight = drumIndex;
      _playerSequence.add(drumIndex);
    });

    int step = _playerSequence.length - 1;
    if (_playerSequence[step] != _drumSequence[step]) {
      // Wrong sequence -> replay demo
      setState(() {
        _sequenceHighlight = -1;
        _playerSequence = [];
        _showingSequence = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wrong rhythm! Let's watch the pattern again."), duration: Duration(seconds: 1)),
      );
      _playSequenceDemo();
      return;
    }

    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _sequenceHighlight = -1;
        });
        if (_playerSequence.length == _drumSequence.length) {
          _completeGame(100);
        }
      }
    });
  }

  void _handleHarvestSort(String category) {
    final correctCategory = _harvestItems[_currentHarvestIndex]['category'];
    if (category == correctCategory) {
      if (_currentHarvestIndex < _harvestItems.length - 1) {
        setState(() {
          _currentHarvestIndex++;
        });
      } else {
        _completeGame(100);
      }
    } else {
      if (_currentHarvestIndex < _harvestItems.length - 1) {
        setState(() {
          _currentHarvestIndex++;
        });
      } else {
        _completeGame(70);
      }
    }
  }

  void _handleWordOptionSelect(int index) {
    setState(() {
      _selectedWordOption = index;
    });
    final correctIndex = _scrambledWords[_currentWordIndex]['correct'];
    Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        if (index == correctIndex) {
          if (_currentWordIndex < _scrambledWords.length - 1) {
            setState(() {
              _currentWordIndex++;
              _selectedWordOption = -1;
            });
          } else {
            _completeGame(100);
          }
        } else {
          if (_currentWordIndex < _scrambledWords.length - 1) {
            setState(() {
              _currentWordIndex++;
              _selectedWordOption = -1;
            });
          } else {
            _completeGame(60);
          }
        }
      }
    });
  }

  Future<void> _completeGame(int finalScore) async {
    setState(() {
      _score = finalScore;
      _isFinished = true;
      _gameState = finalScore >= 60 ? "SUCCESS" : "FAILED";
    });

    if (_sessionId != null) {
      try {
        final repo = ref.read(activityRepositoryProvider);
        await repo.submitResult(
          sessionId: _sessionId!,
          score: finalScore,
          accuracy: finalScore / 100.0,
          responseTime: 8000,
          mistakes: finalScore == 100 ? 0 : 1,
          hintsUsed: 0,
          metadata: '{"completed_game": "${widget.title}"}',
        );
        ref.invalidate(activityHistoryProvider);
      } catch (e) {
        debugPrint("Error submitting score: $e");
      }
    }
  }

  // --- Rendering UI ---

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(
          LocalizationService.translateDynamic(widget.title, lang),
          style: TextStyle(color: DesignSystem.textDark, fontWeight: FontWeight.bold, fontSize: 20 * textScale),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: DesignSystem.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryGreen))
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Expanded(
                      child: _isFinished ? _buildResultView(lang) : _buildGamePlayView(lang),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildGamePlayView(String lang) {
    final cleanTitle = widget.title.trim();
    if (cleanTitle.contains("Match") || cleanTitle.contains("milan") || cleanTitle.contains("মিল")) {
      return _buildMatchGame(lang);
    } else if (cleanTitle.contains("Remember") || cleanTitle.contains("yad") || cleanTitle.contains("ছবি")) {
      return _buildRememberGame(lang);
    } else if (cleanTitle.contains("Rhythm") || cleanTitle.contains("Drum") || cleanTitle.contains("তাল")) {
      return _buildRhythmGame(lang);
    } else if (cleanTitle.contains("Harvest") || cleanTitle.contains("ফচল") || cleanTitle.contains("फसल")) {
      return _buildHarvestSortGame(lang);
    } else if (cleanTitle.contains("Word") || cleanTitle.contains("Unscramble") || cleanTitle.contains("शब्द")) {
      return _buildWordUnscrambleGame(lang);
    } else {
      return _buildSpotGame(lang);
    }
  }

  // Game 1 UI: Matching cards
  Widget _buildMatchGame(String lang) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          lang == 'hi' ? "समान पारंपरिक वस्तुओं का मिलान करें" : "Match the pairs of traditional items!",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            final isFlipped = _cardFlipped[index] || _cardMatched[index];
            return GestureDetector(
              onTap: () => _handleCardTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isFlipped ? Colors.white : DesignSystem.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFlipped ? DesignSystem.primaryGreen : Colors.green.shade700,
                    width: 2.5,
                  ),
                  boxShadow: DesignSystem.softShadow,
                ),
                child: Center(
                  child: Text(
                    isFlipped ? _cardSymbols[index] : " Mitra ",
                    style: TextStyle(
                      fontSize: isFlipped ? 40 : 14,
                      fontWeight: FontWeight.bold,
                      color: isFlipped ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Game 2 UI: Memorize landscape photo and answer question
  Widget _buildRememberGame(String lang) {
    final double textScale = MediaQuery.of(context).textScaleFactor;

    if (!_showQuestion) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            lang == 'hi' 
                ? "चित्रों को 5 सेकंड के लिए ध्यान से देखें।" 
                : "Look at the pictures carefully for 5 seconds.",
            style: TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // 3x3 Grid of Emojis
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 2),
            ),
            child: SizedBox(
              height: 260,
              width: 260,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _rememberEmojis[index],
                      style: const TextStyle(fontSize: 36),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Circular progress countdown
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.shade600, width: 3.5),
            ),
            alignment: Alignment.center,
            child: Text(
              "$_timerSeconds",
              style: TextStyle(fontSize: 26 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            lang == 'hi' ? "तैयार हो जाओ..." : "Get ready...",
            style: TextStyle(fontSize: 16 * textScale, color: DesignSystem.textSubtle, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          lang == 'hi' 
              ? "आपने क्या देखा? चित्रों पर टैप करें।" 
              : "What did you see? Tap on the pictures.",
          style: TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        // Interactive 3x3 grid
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200, width: 2),
          ),
          child: SizedBox(
            height: 260,
            width: 260,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final isSelected = _rememberSelectedIndices.contains(index);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _rememberSelectedIndices.remove(index);
                      } else if (_rememberSelectedIndices.length < 3) {
                        _rememberSelectedIndices.add(index);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? DesignSystem.primaryGreen.withOpacity(0.08) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? DesignSystem.primaryGreen : Colors.grey.shade200,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _rememberEmojis[index],
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 3 empty selections boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final hasItem = i < _rememberSelectedIndices.length;
            final emoji = hasItem ? _rememberEmojis[_rememberSelectedIndices[i]] : "";
            return Container(
              width: 54,
              height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            );
          }),
        ),
        
        const SizedBox(height: 28),
        
        // Submit button
        ElevatedButton(
          onPressed: _rememberSelectedIndices.length == 3
              ? () {
                  int score = 0;
                  for (var idx in _rememberSelectedIndices) {
                    if (_rememberTargetIndices.contains(idx)) {
                      score += 33;
                    }
                  }
                  if (score > 90) score = 100;
                  _completeGame(score);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.primaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            lang == 'hi' ? "जमा करें" : "Submit",
            style: TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Say again button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.volume_up, color: DesignSystem.primaryGreen),
          label: Text(
            lang == 'hi' ? "फिर से कहें" : "Say again",
            style: TextStyle(fontSize: 16 * textScale, color: DesignSystem.primaryGreen, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  // Game 3 UI: Spot the different motif
  Widget _buildSpotGame(String lang) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          lang == 'hi' ? "विशिष्ट पैटर्न को पहचानें" : "Spot the different motif pattern!",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _handleSpotTap(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  boxShadow: DesignSystem.softShadow,
                ),
                child: Center(
                  child: Text(
                    _patternSymbols[index],
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Game 4 UI: Bihu Drum Rhythm sequence match (Simon says)
  Widget _buildRhythmGame(String lang) {
    final drumLabels = ["🥁 Dhol", "🪘 Gogona", "🔔 Tal"];
    final drumColors = [Colors.red.shade400, Colors.orange.shade400, Colors.amber.shade600];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _showingSequence 
            ? (lang == 'hi' ? "ताल पैटर्न को ध्यान से देखें..." : "Watch the drum sequence pattern...")
            : (lang == 'hi' ? "उसी क्रम में ढोल बजाएं!" : "Now match the rhythm sequence!"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final isHighlighted = _sequenceHighlight == index;
            return GestureDetector(
              onTap: () => _handleDrumTap(index),
              child: AnimatedScale(
                scale: isHighlighted ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 90,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isHighlighted ? drumColors[index] : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isHighlighted ? Colors.white : drumColors[index],
                      width: 3.5,
                    ),
                    boxShadow: DesignSystem.softShadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        index == 0 ? "🥁" : index == 1 ? "🪘" : "🔔",
                        style: const TextStyle(fontSize: 36),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        drumLabels[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isHighlighted ? Colors.white : DesignSystem.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Game 5 UI: Sort the Harvest
  Widget _buildHarvestSortGame(String lang) {
    final currentItem = _harvestItems[_currentHarvestIndex];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          lang == 'hi' ? "मद को सही टोकरी में रखें:" : "Sort this item into the correct basket:",
          style: const TextStyle(fontSize: 16, color: DesignSystem.textSubtle),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 2,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Text(
              currentItem['name'],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleHarvestSort("TEA"),
                icon: const Icon(Icons.eco, size: 24),
                label: const Text("Garden 🌿"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleHarvestSort("SPICE"),
                icon: const Icon(Icons.local_fire_department, size: 24),
                label: const Text("Spices 🌶️"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade500,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Game 6 UI: Word Search / Unscramble
  Widget _buildWordUnscrambleGame(String lang) {
    final currentWord = _scrambledWords[_currentWordIndex];
    final options = currentWord['options'] as List<String>;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          lang == 'hi' ? "इन अक्षरों को सुलझाएं:" : "Unscramble these letters:",
          style: const TextStyle(fontSize: 15, color: DesignSystem.textSubtle),
        ),
        const SizedBox(height: 8),
        Text(
          currentWord['scrambled'],
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 6, color: DesignSystem.primaryGreen),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
          child: Text(
            currentWord['hint'],
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue.shade800),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 28),
        ...List.generate(options.length, (index) {
          final isSelected = _selectedWordOption == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ElevatedButton(
              onPressed: () => _handleWordOptionSelect(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? DesignSystem.primaryGreen : Colors.white,
                foregroundColor: isSelected ? Colors.white : DesignSystem.textDark,
                elevation: 1,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? DesignSystem.primaryGreen : Colors.grey.shade200,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                options[index],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Result UI
  Widget _buildResultView(String lang) {
    final isSuccess = _gameState == "SUCCESS";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSuccess ? Icons.check_circle : Icons.warning_rounded,
          color: isSuccess ? DesignSystem.primaryGreen : Colors.orange,
          size: 96,
        ),
        const SizedBox(height: 16),
        Text(
          isSuccess 
            ? (lang == 'hi' ? "शानदार प्रयास! 🎉" : "Excellent Job! 🎉")
            : (lang == 'hi' ? "समाप्त!" : "Finished!"),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
        ),
        const SizedBox(height: 8),
        Text(
          "${LocalizationService.translate('score', lang)}: $_score",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DesignSystem.primaryGreen),
        ),
        const SizedBox(height: 36),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.primaryGreen,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            LocalizationService.translate('close_btn', lang),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
