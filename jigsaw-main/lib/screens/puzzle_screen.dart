import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

import '../models/puzzle_piece.dart';
import '../services/game_audio_service.dart';
import '../services/image_splitter.dart';
import '../widgets/confetti_layer.dart';
import '../widgets/draggable_piece.dart';
import '../widgets/game_hud.dart';
import '../widgets/jigsaw_piece_view.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/victory_overlay.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with TickerProviderStateMixin {
  int _gridSize = 3;
  Uint8List _fullImageBytes = Uint8List(0);
  int _decodedWidth = 600;
  int _decodedHeight = 600;
  List<PuzzlePiece> board = [];
  List<PuzzlePiece> shuffledPieces = [];
  List<double> pieceRotations = [];
  List<JigsawEdgeProfile> edgeProfiles = [];
  List<bool> hidden = [];
  List<Offset> trayOffsets = [];
  final Random _random = Random();
  final GlobalKey _trayKey = GlobalKey();
  final GameAudioService _audioService = GameAudioService();
  late final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(milliseconds: 1900),
  );
  late final AnimationController _timerController = AnimationController(
    vsync: this,
    duration: const Duration(days: 1),
  )..addListener(_onTick);
  late final AnimationController _mergeOutlineController =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => showVictoryOverlay = true);
        }
      });
  Duration _elapsed = Duration.zero;
  bool solved = false;
  bool paused = false;
  int? hintIndex;
  int? hintedPieceDataIndex;
  int? wrongFlashIndex;
  bool showVictoryOverlay = false;
  bool loading = true;
  int _stars = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDifficultyPopup());
  }

  @override
  void dispose() {
    _timerController
      ..removeListener(_onTick)
      ..dispose();
    _confettiController.dispose();
    _mergeOutlineController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!mounted || paused || solved) return;
    setState(
      () => _elapsed = _timerController.lastElapsedDuration ?? Duration.zero,
    );
  }

  double _pieceSizeForWidth(double width) {
    final gridPiece = ((width - 32) / _gridSize) - 10;
    final byDifficulty = switch (_gridSize) {
      5 => 58.0,
      4 => 70.0,
      _ => 82.0,
    };
    return min(byDifficulty, gridPiece.clamp(46, 92));
  }

  int get _currentStars {
    final secondsPerStar = switch (_gridSize) {
      4 => 45,
      5 => 60,
      _ => 30,
    };
    final decayed = 3 - (_elapsed.inSeconds ~/ secondsPerStar);
    return decayed.clamp(1, 3);
  }

  Future<void> _showDifficultyPopup() async {
    final selected = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF10151F),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white24),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 26),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Difficulty',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select puzzle size before starting',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                _difficultyButton(context, 'Easy 3x3', 3),
                _difficultyButton(context, 'Medium 4x4', 4),
                _difficultyButton(context, 'Hard 5x5', 5),
              ],
            ),
          ),
        );
      },
    );
    _gridSize = selected ?? 3;
    await loadPuzzle();
  }

  Widget _difficultyButton(BuildContext context, String label, int size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: 180,
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(size),
          child: Text(label),
        ),
      ),
    );
  }

  void _generateTrayScatter(double trayWidth, double pieceSize) {
    const padding = 8.0;
    final trayHeight = _trayHeightFor(pieceSize);
    final count = shuffledPieces.length;
    final maxX = max(padding, trayWidth - pieceSize - padding);
    final maxY = max(padding, trayHeight - pieceSize - padding);
    trayOffsets = List.generate(count, (index) {
      final dx = padding + (_random.nextDouble() * (maxX - padding));
      final dy = padding + (_random.nextDouble() * (maxY - padding));
      return Offset(dx, dy);
    });
  }

  double _trayHeightFor(double pieceSize) {
    final preferred = pieceSize * 2.25;
    return preferred.clamp(150.0, 220.0);
  }

  void _generateEdgeProfiles() {
    final rightSigns = List.generate(
      _gridSize,
      (_) => List.generate(_gridSize - 1, (_) => _random.nextBool() ? 1 : -1),
    );
    final bottomSigns = List.generate(
      _gridSize - 1,
      (_) => List.generate(_gridSize, (_) => _random.nextBool() ? 1 : -1),
    );
    edgeProfiles = List.generate(_gridSize * _gridSize, (index) {
      final row = index ~/ _gridSize;
      final col = index % _gridSize;
      final top = row == 0 ? 0 : -bottomSigns[row - 1][col];
      final right = col == _gridSize - 1 ? 0 : rightSigns[row][col];
      final bottom = row == _gridSize - 1 ? 0 : bottomSigns[row][col];
      final left = col == 0 ? 0 : -rightSigns[row][col - 1];
      return JigsawEdgeProfile(
        top: top,
        right: right,
        bottom: bottom,
        left: left,
      );
    });
  }

  Future<void> loadPuzzle() async {
    setState(() {
      loading = true;
      solved = false;
      paused = false;
      _elapsed = Duration.zero;
      showVictoryOverlay = false;
      _mergeOutlineController.reset();
      hintIndex = null;
      hintedPieceDataIndex = null;
      wrongFlashIndex = null;
      hidden = [];
      trayOffsets = [];
    });
    final split = await ImageSplitter.split(gridSize: _gridSize);
    _fullImageBytes = split.fullImageBytes;
    _decodedWidth = split.decodedWidth;
    _decodedHeight = split.decodedHeight;
    board = split.pieces;
    await _audioService.preload();
    for (final p in board) {
      p.isPlaced = false;
    }
    shuffledPieces = List.from(board);
    shuffledPieces.shuffle();
    _generateEdgeProfiles();
    pieceRotations = List.generate(
      shuffledPieces.length,
      (index) => ((index * 37) % 100) / 1000 - 0.05,
    );
    if (!mounted) return;
    final trayWidth = max(180.0, MediaQuery.sizeOf(context).width - 32);
    final pieceSize = _pieceSizeForWidth(MediaQuery.sizeOf(context).width);
    _generateTrayScatter(trayWidth, pieceSize);
    setState(() => loading = false);
    _timerController
      ..stop()
      ..reset()
      ..forward();
  }

  Future<void> _handlePickup() async {
    HapticFeedback.lightImpact();
    await _audioService.play(GameSfx.pickup, volume: 0.72);
  }

  bool _onWillAccept(int index, int data) {
    if (solved || paused) return false;
    return !board[index].isPlaced;
  }

  Future<void> _onAccept(int index, int data) async {
    final piece = shuffledPieces[data];
    if (piece.correctIndex == index) {
      setState(() {
        board[index].isPlaced = true;
        if (hintedPieceDataIndex == data) {
          hintedPieceDataIndex = null;
          hintIndex = null;
        }
      });
      HapticFeedback.mediumImpact();
      await _audioService.play(GameSfx.correct);
      checkWin();
    } else {
      setState(() {
        wrongFlashIndex = index;
      });
      HapticFeedback.vibrate();
      await _audioService.play(GameSfx.wrong);
      Future.delayed(const Duration(milliseconds: 260), () {
        if (mounted) setState(() => wrongFlashIndex = null);
      });
    }
  }

  void _onMove(int index, int? data) {}

  void checkWin() {
    final win = board.every((e) => e.isPlaced);
    if (!win || solved) return;
    solved = true;
    _timerController.stop();
    _stars = _currentStars;
    _confettiController.play();
    HapticFeedback.heavyImpact();
    _audioService.play(GameSfx.complete);
    for (var i = 0; i < _stars; i++) {
      Future<void>.delayed(Duration(milliseconds: i * 45), () {
        if (mounted) _audioService.play(GameSfx.star, volume: 0.86);
      });
    }
    _mergeOutlineController.forward(from: 0);
    setState(() {});
  }

  void _togglePause() {
    if (solved) return;
    setState(() => paused = !paused);
    if (paused) {
      _timerController.stop();
    } else {
      _timerController.forward();
    }
  }

  void _showHint() {
    if (solved || paused) return;
    final emptySlots = <int>[];
    for (var i = 0; i < board.length; i++) {
      if (!board[i].isPlaced) emptySlots.add(i);
    }
    if (emptySlots.isEmpty) return;
    final candidate = emptySlots[_random.nextInt(emptySlots.length)];
    final pieceDataIndex = shuffledPieces.indexWhere(
      (piece) => piece.correctIndex == candidate && !piece.isPlaced,
    );
    if (pieceDataIndex == -1) return;
    setState(() {
      hintIndex = candidate;
      hintedPieceDataIndex = pieceDataIndex;
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() {
          hintIndex = null;
          hintedPieceDataIndex = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final pieceSize = _pieceSizeForWidth(screenWidth);
    final trayHeight = _trayHeightFor(pieceSize);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  title: const Text("Puzzle Game", style: TextStyle(color: Colors.white),),
),
      body: loading
          ? const Center(child: CircularProgressIndicator())
                .animate()
                .fade(duration: const Duration(milliseconds: 350))
                .scale(curve: Curves.easeOutBack)
          : Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF17243F), Color(0xFF111827)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boardSize = min(
                          constraints.maxWidth - 16,
                          constraints.maxHeight * 0.52,
                        );
                        return Column(
                          children: [
                            GameHud(
                              elapsed: _elapsed,
                              currentStars: _currentStars,
                              onRestart: _showDifficultyPopup,
                              onPauseToggle: _togglePause,
                              onHint: _showHint,
                              onShuffleAgain: () {
                                if (paused || solved) return;
                                setState(() {
                                  hidden = List.generate(
                                    _gridSize * _gridSize,
                                    (_) => false,
                                  );
                                  shuffledPieces.shuffle();
                                  _generateTrayScatter(
                                    constraints.maxWidth - 32,
                                    pieceSize,
                                  );
                                });
                              },
                              paused: paused,
                            ),
                            Expanded(
                              child: Center(
                                child: solved
                                    ? AnimatedBuilder(
                                        animation: _mergeOutlineController,
                                        builder: (context, child) {
                                          final t = Curves.easeOutCubic
                                              .transform(
                                                _mergeOutlineController.value,
                                              );
                                          final outlineOpacity = 1.0 - t;
                                          final scale = 1.0 + 0.02 * t;
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            child: Transform.scale(
                                              scale: scale,
                                              child: SizedBox(
                                                width: boardSize,
                                                height: boardSize,
                                                child: PuzzleBoard(
                                                  key: const ValueKey(
                                                    'board_merge',
                                                  ),
                                                  fullImageBytes: _fullImageBytes,
                                                  decodedWidth: _decodedWidth,
                                                  decodedHeight: _decodedHeight,
                                                  gridSize: _gridSize,
                                                  boardPieces: board,
                                                  profiles: edgeProfiles,
                                                  hintIndex: null,
                                                  wrongFlashIndex: null,
                                                  hintColor: Colors.amber,
                                                  outlineOpacity:
                                                      outlineOpacity,
                                                  onWillAccept: _onWillAccept,
                                                  onAccept: _onAccept,
                                                  onMove: _onMove,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : SizedBox(
                                        width: boardSize,
                                        height: boardSize,
                                        child: PuzzleBoard(
                                          key: const ValueKey('board'),
                                          fullImageBytes: _fullImageBytes,
                                          decodedWidth: _decodedWidth,
                                          decodedHeight: _decodedHeight,
                                          gridSize: _gridSize,
                                          boardPieces: board,
                                          profiles: edgeProfiles,
                                          hintIndex: hintIndex,
                                          wrongFlashIndex: wrongFlashIndex,
                                          hintColor: Colors.amber,
                                          outlineOpacity: 1,
                                          onWillAccept: _onWillAccept,
                                          onAccept: _onAccept,
                                          onMove: _onMove,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(
                              height: trayHeight,
                              child: Container(
                                key: _trayKey,
                                width: constraints.maxWidth - 8,
                                margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: List.generate(
                                    shuffledPieces.length,
                                    (index) {
                                      final piece = shuffledPieces[index];
                                      if (piece.isPlaced) {
                                        return const SizedBox.shrink();
                                      }
                                      final offset = trayOffsets.isNotEmpty
                                          ? trayOffsets[index]
                                          : Offset(
                                              8 + (index * 8),
                                              8 + ((index % 3) * 8),
                                            );
                                      var acceptedByBoard = false;
                                      return Positioned(
                                        left: offset.dx,
                                        top: offset.dy,
                                        child: DraggablePiece(
                                          fullImageBytes: _fullImageBytes,
                                          decodedWidth: _decodedWidth,
                                          decodedHeight: _decodedHeight,
                                          gridSize: _gridSize,
                                          piece: piece,
                                          size: pieceSize,
                                          rotation: pieceRotations[index],
                                          profile:
                                              edgeProfiles[piece.correctIndex],
                                          data: index,
                                          isHinted:
                                              hintedPieceDataIndex == index,
                                          onDragStarted: () async {
                                            await _handlePickup();
                                          },
                                          onDragCompleted: () =>
                                              acceptedByBoard = true,
                                          onDragEnd: (details) {
                                            if (!mounted ||
                                                piece.isPlaced ||
                                                acceptedByBoard) {
                                              return;
                                            }
                                            final box =
                                                _trayKey.currentContext
                                                        ?.findRenderObject()
                                                    as RenderBox?;
                                            if (box == null) return;
                                            final local = box.globalToLocal(
                                              details.offset,
                                            );
                                            final clamped = Offset(
                                              local.dx.clamp(
                                                8.0,
                                                box.size.width -
                                                    pieceSize -
                                                    8.0,
                                              ),
                                              local.dy.clamp(
                                                8.0,
                                                box.size.height -
                                                    pieceSize -
                                                    8.0,
                                              ),
                                            );
                                            setState(
                                              () =>
                                                  trayOffsets[index] = clamped,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (paused && !solved)
                  Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    alignment: Alignment.center,
                    child: FilledButton.icon(
                      onPressed: _togglePause,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Resume Game'),
                    ),
                  ),
                ConfettiLayer(controller: _confettiController),
                if (showVictoryOverlay)
                  VictoryOverlay(
                    stars: _stars,
                    elapsed: _elapsed,
                    onContinue: () =>
                        setState(() => showVictoryOverlay = false),
                  ),
              ],
            ),
    );
  }
}
