import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/game_stats.dart';
import '../models/playing_card.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/animated_card_entry.dart';
import '../widgets/casino_chip.dart';
import '../widgets/table_felt.dart';
import '../widgets/result_effects.dart';
import '../widgets/help_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState _game;
  late GameStats _stats;
  final AudioService _audio = AudioService();

  bool _isDealing = false;
  bool _dealerPlaying = false;
  bool _showHelp = false;
  bool _showStats = false;
  bool _loaded = false;

  List<int> _shownCardsPerHand = [0];
  int _shownDealerCards = 0;
  int _dealKey = 0;

  late List<AiPlayer> _aiPlayers;
  Map<int, int> _shownAiCards = {};

  int _effectKey = 0;

  @override
  void initState() {
    super.initState();
    _game = GameState();
    _stats = GameStats();
    _aiPlayers = [
      AiPlayer(name: 'Alex'),
      AiPlayer(name: 'Sam'),
    ];
    _loadData();
  }

  Future<void> _loadData() async {
    final balance = await StorageService.loadBalance();
    final stats = await StorageService.loadStats();
    final helpSeen = await StorageService.hasSeenHelp();
    if (!mounted) return;
    setState(() {
      _game.balance = balance;
      _stats = stats;
      _loaded = true;
      if (!helpSeen) _showHelp = true;
    });
  }

  Future<void> _saveData() async {
    await StorageService.saveBalance(_game.balance);
    await StorageService.saveStats(_stats);
  }

  // -- Game actions --

  void _onPlaceBet(int amount) async {
    if (_game.phase == GamePhase.roundOver) {
      _game.resetForNewRound();
      for (final ai in _aiPlayers) {
        ai.reset();
      }
    }
    if (!_game.placeBet(amount)) return;
    _audio.playChipClick();

    _dealKey++;
    _shownCardsPerHand = [0];
    _shownDealerCards = 0;
    _shownAiCards = {};

    for (final ai in _aiPlayers) {
      ai.placeBet();
    }

    setState(() {});

    _game.startNewRound();

    for (final ai in _aiPlayers) {
      if (ai.bet > 0) {
        ai.receiveCards([_game.deck.deal(), _game.deck.deal()]);
      }
    }

    await _animateInitialDeal();

    if (!mounted) return;

    if (_game.phase == GamePhase.insurance) {
      setState(() {});
      return;
    }

    if (_game.checkForBlackjack()) {
      _onRoundOver();
      setState(() {});
    }
  }

  Future<void> _animateInitialDeal() async {
    _isDealing = true;
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _audio.playDeal();
    setState(() {
      _shownCardsPerHand = [1];
      for (int i = 0; i < _aiPlayers.length; i++) {
        if (_aiPlayers[i].bet > 0) _shownAiCards[i] = 1;
      }
    });

    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    _audio.playDeal();
    setState(() => _shownDealerCards = 1);

    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    _audio.playDeal();
    setState(() {
      _shownCardsPerHand = [2];
      for (int i = 0; i < _aiPlayers.length; i++) {
        if (_aiPlayers[i].bet > 0) _shownAiCards[i] = 2;
      }
    });

    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    _audio.playDeal();
    setState(() {
      _shownDealerCards = 2;
      _isDealing = false;
    });
  }

  void _onAcceptInsurance() {
    _game.acceptInsurance();
    setState(() {});
    if (_game.checkForBlackjack()) {
      _onRoundOver();
      setState(() {});
    }
  }

  void _onDeclineInsurance() {
    _game.declineInsurance();
    setState(() {});
    if (_game.checkForBlackjack()) {
      _onRoundOver();
      setState(() {});
    }
  }

  void _onHit() async {
    if (_isDealing || _dealerPlaying) return;
    final prevIdx = _game.activeHandIndex;

    _game.hit();
    _audio.playDeal();
    setState(() {
      _shownCardsPerHand[prevIdx] = _game.hands[prevIdx].cards.length;
    });

    if (_game.phase == GamePhase.roundOver) {
      await _animateDealerReveal();
      _onRoundOver();
    }
  }

  void _onStand() async {
    if (_isDealing || _dealerPlaying) return;

    _game.stand();

    if (_game.phase == GamePhase.playerTurn) {
      setState(() {});
      return;
    }

    await _animateDealerReveal();
    _onRoundOver();
  }

  void _onDoubleDown() async {
    if (_isDealing || _dealerPlaying) return;
    final prevIdx = _game.activeHandIndex;

    _game.doubleDown();
    _audio.playDeal();
    setState(() {
      _shownCardsPerHand[prevIdx] = _game.hands[prevIdx].cards.length;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (_game.phase == GamePhase.playerTurn) {
      setState(() {});
      return;
    }

    await _animateDealerReveal();
    _onRoundOver();
  }

  void _onSplit() async {
    if (_isDealing || _dealerPlaying) return;
    _isDealing = true;

    _game.split();
    _dealKey++;

    setState(() => _shownCardsPerHand = [1, 0]);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _audio.playDeal();

    setState(() => _shownCardsPerHand = [1, 1]);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _audio.playDeal();

    setState(() => _shownCardsPerHand = [2, 1]);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _audio.playDeal();

    setState(() {
      _shownCardsPerHand = [2, 2];
      _isDealing = false;
    });

    if (_game.phase != GamePhase.playerTurn) {
      await _animateDealerReveal();
      _onRoundOver();
    }
  }

  Future<void> _animateDealerReveal() async {
    for (final ai in _aiPlayers) {
      if (ai.bet > 0 && ai.hand != null) {
        ai.play(_game.deck);
      }
    }

    setState(() => _dealerPlaying = true);
    _audio.playFlip();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    for (int i = _shownDealerCards; i < _game.dealerHand.length; i++) {
      _audio.playDeal();
      setState(() => _shownDealerCards = i + 1);
      await Future.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
    }

    for (final ai in _aiPlayers) {
      if (ai.bet > 0 && ai.hand != null) {
        ai.settle(_game.dealerHandValue);
        final idx = _aiPlayers.indexOf(ai);
        setState(() => _shownAiCards[idx] = ai.hand!.cards.length);
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
      }
    }

    setState(() => _dealerPlaying = false);
  }

  void _onRoundOver() {
    _effectKey++;

    for (final hand in _game.hands) {
      switch (hand.result) {
        case RoundResult.playerBlackjack:
          _stats.recordBlackjack(hand.payout - hand.bet);
          _audio.playBlackjack();
          break;
        case RoundResult.playerWins:
        case RoundResult.dealerBust:
          _stats.recordWin(hand.payout - hand.bet);
          _audio.playWin();
          break;
        case RoundResult.tie:
          _stats.recordPush();
          break;
        case RoundResult.dealerWins:
        case RoundResult.playerBust:
          _stats.recordLoss(hand.bet);
          _audio.playLoss();
          break;
        default:
          break;
      }
    }

    _stats.updatePeakBalance(_game.balance);
    _saveData();
    setState(() {});
  }

  void _onReturnHome() {
    Navigator.of(context).pop();
  }

  void _onBuyIn() {
    setState(() => _game = GameState());
    for (final ai in _aiPlayers) {
      ai.balance = 1000;
      ai.reset();
    }
    _saveData();
  }

  bool get _showBettingChips =>
      _game.phase == GamePhase.betting || _game.phase == GamePhase.roundOver;

  bool get _isPlayerTurn =>
      _game.phase == GamePhase.playerTurn && !_isDealing && !_dealerPlaying;

  // -- Build --

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B5E20),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final scale = (w / 400).clamp(0.75, 1.2);
          final compact = h < 700;

          return Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: TableFeltPainter(),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: h - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              _buildTopBar(scale),
                              _buildBalanceBar(scale),
                              SizedBox(height: compact ? 4 : 8),
                              _buildAiPlayersRow(scale),
                              _buildDealerSection(scale),
                              const Spacer(),
                              _buildTableRules(scale),
                              if (_game.phase == GamePhase.roundOver) ...[
                                SizedBox(height: compact ? 4 : 8),
                                _buildResultBanner(scale),
                              ],
                              const Spacer(),
                              _buildPlayerSection(scale),
                              SizedBox(height: compact ? 3 : 6),
                              _buildBottomArea(scale),
                              SizedBox(height: compact ? 6 : 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_game.phase == GamePhase.roundOver) ...[
                if (_game.isNetWin)
                  Positioned.fill(child: WinShimmer(key: ValueKey('win_$_effectKey'))),
                if (_game.isNetLoss)
                  Positioned.fill(child: LossFlash(key: ValueKey('loss_$_effectKey'))),
                if (_game.hands.any((h) => h.result == RoundResult.playerBlackjack))
                  Positioned.fill(child: ConfettiOverlay(key: ValueKey('confetti_$_effectKey'))),
              ],
              if (_showHelp)
                Positioned.fill(
                  child: HelpOverlay(onDismiss: () {
                    setState(() => _showHelp = false);
                    StorageService.markHelpSeen();
                  }),
                ),
              if (_showStats) _buildStatsOverlay(),
            ],
          );
        },
      ),
    );
  }

  // -- Top bar with home + help + stats + mute --

  Widget _buildTopBar(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 6 * scale),
      child: Row(
        children: [
          _iconButton(Icons.home, _onReturnHome, scale),
          const SizedBox(width: 8),
          _iconButton(Icons.help_outline, () => setState(() => _showHelp = true), scale),
          const Spacer(),
          Text(
            'BLACKJACK',
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          _iconButton(Icons.bar_chart, () => setState(() => _showStats = true), scale),
          const SizedBox(width: 8),
          _iconButton(
            _audio.muted ? Icons.volume_off : Icons.volume_up,
            () => setState(() => _audio.toggleMute()),
            scale,
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap, double scale) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(6 * scale),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8 * scale),
        ),
        child: Icon(icon, color: Colors.white, size: 20 * scale),
      ),
    );
  }

  // -- Balance bar --

  Widget _buildBalanceBar(double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24 * scale),
      padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _balanceItem('BALANCE', '\$${_game.balance}', Colors.white, scale),
          Container(width: 1, height: 24 * scale, color: Colors.white24),
          _balanceItem(
            'BET',
            '\$${_game.hands.isEmpty ? _game.currentBet : _game.totalBetAmount}',
            Colors.amber,
            scale,
          ),
        ],
      ),
    );
  }

  Widget _balanceItem(String label, String value, Color valueColor, double scale) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10 * scale,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // -- AI Players Row --

  Widget _buildAiPlayersRow(double scale) {
    final activePlayers = _aiPlayers.where((ai) => ai.bet > 0 && ai.hand != null).toList();
    if (activePlayers.isEmpty && _game.phase == GamePhase.betting) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8 * scale),
      height: 80 * scale,
      child: Row(
        children: [
          for (int i = 0; i < _aiPlayers.length; i++) ...[
            if (i > 0) SizedBox(width: 6 * scale),
            Expanded(child: _buildAiSeat(i, scale)),
          ],
        ],
      ),
    );
  }

  Widget _buildAiSeat(int index, double scale) {
    final ai = _aiPlayers[index];
    final hasCards = ai.hand != null && ai.bet > 0;
    final isRoundOver = _game.phase == GamePhase.roundOver;
    final shownCount = _shownAiCards[index] ?? 0;

    Color nameColor = Colors.white.withValues(alpha: 0.6);
    String resultText = '';
    if (isRoundOver && hasCards && ai.hand!.result != null) {
      final r = ai.hand!.result!;
      final isWin = r == RoundResult.playerWins || r == RoundResult.dealerBust || r == RoundResult.playerBlackjack;
      final isTie = r == RoundResult.tie;
      nameColor = isWin ? Colors.amber : isTie ? Colors.blueGrey.shade300 : Colors.red.shade300;
      resultText = _game.resultMessageForHand(ai.hand!);
    }

    return Container(
      padding: EdgeInsets.all(4 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Column(
        children: [
          Text(
            hasCards ? '${ai.name} (${ai.hand!.handValue})' : ai.name,
            style: TextStyle(
              fontSize: 10 * scale,
              fontWeight: FontWeight.w700,
              color: nameColor,
            ),
          ),
          if (hasCards)
            Expanded(
              child: _buildHandCards(
                ai.hand!.cards,
                shownCount,
                'ai$index',
                cardWidth: 36 * scale,
                overlap: 18 * scale,
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  ai.balance <= 0 ? 'OUT' : '\$${ai.balance}',
                  style: TextStyle(
                    fontSize: 9 * scale,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          if (resultText.isNotEmpty)
            Text(
              resultText,
              style: TextStyle(
                fontSize: 8 * scale,
                fontWeight: FontWeight.w700,
                color: nameColor,
              ),
            ),
        ],
      ),
    );
  }

  // -- Dealer section --

  Widget _buildDealerSection(double scale) {
    final showFull = _game.phase == GamePhase.roundOver ||
        _game.phase == GamePhase.dealerTurn;
    final displayValue =
        showFull ? _game.dealerHandValue : _game.dealerVisibleValue;
    final hasCards =
        _game.dealerHand.isNotEmpty && _game.phase != GamePhase.betting;

    return Column(
      children: [
        Text(
          hasCards ? 'DEALER ($displayValue)' : 'DEALER',
          style: TextStyle(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 6 * scale),
        _buildHandCards(_game.dealerHand, _shownDealerCards, 'd',
            cardWidth: 80 * scale, overlap: 24 * scale),
      ],
    );
  }

  // -- Table rules text --

  Widget _buildTableRules(double scale) {
    return Column(
      children: [
        Text(
          'DEALER MUST HIT SOFT 17',
          style: TextStyle(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF4CAF50).withValues(alpha: 0.45),
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(0, 1),
                blurRadius: 0,
              ),
              Shadow(
                color: const Color(0xFF81C784).withValues(alpha: 0.15),
                offset: const Offset(0, -1),
                blurRadius: 0,
              ),
            ],
          ),
        ),
        SizedBox(height: 6 * scale),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 4 * scale),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color(0xFFD4A843).withValues(alpha: 0.25),
                width: 1,
              ),
              bottom: BorderSide(
                color: const Color(0xFFD4A843).withValues(alpha: 0.25),
                width: 1,
              ),
            ),
          ),
          child: Text(
            'BLACKJACK PAYS 3 TO 2',
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFD4A843).withValues(alpha: 0.4),
              letterSpacing: 3,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 1),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -- Player section --

  Widget _buildPlayerSection(double scale) {
    if (_game.isSplit) {
      return _buildSplitPlayerSection(scale);
    }
    return _buildSinglePlayerSection(scale);
  }

  Widget _buildSinglePlayerSection(double scale) {
    final hasCards =
        _game.hands.isNotEmpty && _game.phase != GamePhase.betting;
    final shownCount =
        _shownCardsPerHand.isNotEmpty ? _shownCardsPerHand[0] : 0;

    return Column(
      children: [
        _buildHandCards(
          hasCards ? _game.hands[0].cards : [],
          shownCount,
          'p0',
          cardWidth: 80 * scale,
          overlap: 24 * scale,
        ),
        SizedBox(height: 4 * scale),
        Text(
          hasCards ? 'YOUR HAND (${_game.hands[0].handValue})' : 'YOUR HAND',
          style: TextStyle(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 4 * scale),
        if (hasCards) _buildBetChipStack(_game.hands[0].bet, scale: scale),
        if (!hasCards) SizedBox(height: 24 * scale),
      ],
    );
  }

  Widget _buildSplitPlayerSection(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildSplitHandColumn(0, scale)),
          SizedBox(width: 6 * scale),
          Expanded(child: _buildSplitHandColumn(1, scale)),
        ],
      ),
    );
  }

  Widget _buildSplitHandColumn(int index, double scale) {
    final hand = _game.hands[index];
    final isActive = _game.activeHandIndex == index && _isPlayerTurn;
    final isRoundOver = _game.phase == GamePhase.roundOver;
    final shownCount =
        index < _shownCardsPerHand.length ? _shownCardsPerHand[index] : 0;

    Color? resultColor;
    if (isRoundOver && hand.result != null) {
      final isWin = hand.result == RoundResult.playerWins ||
          hand.result == RoundResult.dealerBust;
      final isTie = hand.result == RoundResult.tie;
      resultColor = isWin
          ? Colors.amber
          : isTie
              ? Colors.blueGrey.shade300
              : Colors.red.shade300;
    }

    return Container(
      padding: EdgeInsets.all(6 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10 * scale),
        border: isActive
            ? Border.all(color: Colors.amber.withValues(alpha: 0.8), width: 2)
            : Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        color: isActive
            ? Colors.amber.withValues(alpha: 0.08)
            : Colors.transparent,
      ),
      child: Column(
        children: [
          _buildHandCards(hand.cards, shownCount, 'p$index',
              cardWidth: 65 * scale, overlap: 32 * scale),
          SizedBox(height: 4 * scale),
          Text(
            '${hand.handValue}',
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (isRoundOver && hand.result != null)
            Padding(
              padding: EdgeInsets.only(top: 2 * scale),
              child: Text(
                _game.resultMessageForHand(hand),
                style: TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w700,
                  color: resultColor,
                ),
              ),
            ),
          SizedBox(height: 4 * scale),
          _buildBetChipStack(hand.bet, small: true, scale: scale),
        ],
      ),
    );
  }

  // -- Card rendering --

  Widget _buildHandCards(
    List<PlayingCard> cards,
    int shownCount,
    String keyPrefix, {
    double cardWidth = 80,
    double overlap = 24,
  }) {
    final cardHeight = cardWidth * 1.5;
    final visibleCount = shownCount.clamp(0, cards.length);

    if (visibleCount == 0) return SizedBox(height: cardHeight);

    final totalWidth =
        cardWidth + (visibleCount - 1) * (cardWidth - overlap);

    return SizedBox(
      height: cardHeight,
      child: Center(
        child: SizedBox(
          width: totalWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(visibleCount, (index) {
              return Positioned(
                left: index * (cardWidth - overlap),
                child: AnimatedCardEntry(
                  key: ValueKey('${keyPrefix}_${_dealKey}_$index'),
                  child: PlayingCardWidget(
                    card: cards[index],
                    width: cardWidth,
                    height: cardHeight,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // -- Bet chip stack display --

  Widget _buildBetChipStack(int bet, {bool small = false, double scale = 1.0}) {
    if (bet <= 0) return SizedBox(height: (small ? 22 : 30) * scale);

    final chips = _decomposeChips(bet);
    final chipSize = (small ? 18.0 : 24.0) * scale;
    final stackOffset = 3.0 * scale;
    final totalHeight = chipSize + (chips.length - 1) * stackOffset;
    final fontSize = (small ? 11.0 : 13.0) * scale;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: chipSize,
          height: totalHeight + 2 * scale,
          child: Stack(
            children: List.generate(chips.length, (i) {
              return Positioned(
                bottom: i * stackOffset,
                child: CasinoChip(
                  size: chipSize,
                  chipColor: _chipColor(chips[i]),
                  label: '',
                ),
              );
            }),
          ),
        ),
        SizedBox(width: 5 * scale),
        Text(
          '\$$bet',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  List<int> _decomposeChips(int amount) {
    final denoms = [100, 50, 25, 10];
    final chips = <int>[];
    var remaining = amount;
    for (final d in denoms) {
      while (remaining >= d && chips.length < 8) {
        chips.add(d);
        remaining -= d;
      }
    }
    if (remaining > 0 && chips.length < 8) chips.add(remaining);
    return chips;
  }

  // -- Result banner --

  Widget _buildResultBanner(double scale) {
    final isWin = _game.isNetWin;
    final isLoss = _game.isNetLoss;

    Color bannerColor;
    if (isWin) {
      bannerColor = Colors.amber;
    } else if (isLoss) {
      bannerColor = Colors.red.shade400;
    } else {
      bannerColor = Colors.blueGrey.shade300;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 32 * scale),
      padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 10 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: bannerColor, width: 2),
      ),
      child: Column(
        children: [
          if (!_game.isSplit) ...[
            Text(
              _game.resultMessageForHand(_game.hands[0]),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w800,
                color: bannerColor,
              ),
            ),
            SizedBox(height: 2 * scale),
            Text(
              'Player: ${_game.hands[0].handValue}  |  Dealer: ${_game.dealerHandValue}',
              style: TextStyle(
                fontSize: 12 * scale,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          SizedBox(height: 4 * scale),
          Text(
            _game.payoutMessage,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w800,
              color: isWin
                  ? Colors.green.shade300
                  : isLoss
                      ? Colors.red.shade300
                      : Colors.blueGrey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  // -- Bottom area (buttons or betting) --

  Widget _buildBottomArea(double scale) {
    if (_showBettingChips) return _buildBettingSection(scale);
    if (_game.phase == GamePhase.insurance) return _buildInsurancePrompt(scale);
    if (_isPlayerTurn) return _buildActionButtons(scale);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: _disabledButton('DEALING...', scale),
    );
  }

  Widget _buildInsurancePrompt(double scale) {
    final cost = _game.insuranceCost;
    final canAfford = _game.canInsure;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20 * scale),
      padding: EdgeInsets.symmetric(vertical: 14 * scale, horizontal: 16 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'INSURANCE?',
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w800,
              color: Colors.amber,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            'Dealer shows an Ace. Insure for \$$cost?',
            style: TextStyle(
              fontSize: 13 * scale,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 12 * scale),
          Row(
            children: [
              Expanded(
                child: _styledButton(
                  'YES (\$$cost)',
                  const [Color(0xFF43A047), Color(0xFF2E7D32)],
                  Icons.shield,
                  canAfford ? _onAcceptInsurance : null,
                  scale,
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: _styledButton(
                  'NO',
                  const [Color(0xFFE53935), Color(0xFFC62828)],
                  Icons.close,
                  _onDeclineInsurance,
                  scale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double scale) {
    final showDouble = _game.canDoubleDown;
    final showSplit = _game.canSplit;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _styledButton(
                  'HIT',
                  const [Color(0xFF43A047), Color(0xFF2E7D32)],
                  Icons.add_circle_outline,
                  _onHit,
                  scale,
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: _styledButton(
                  'STAND',
                  const [Color(0xFFE53935), Color(0xFFC62828)],
                  Icons.front_hand,
                  _onStand,
                  scale,
                ),
              ),
            ],
          ),
          if (showDouble || showSplit) ...[
            SizedBox(height: 8 * scale),
            Row(
              children: [
                if (showDouble)
                  Expanded(
                    child: _styledButton(
                      'DOUBLE',
                      const [Color(0xFFFFA000), Color(0xFFE65100)],
                      Icons.looks_two,
                      _onDoubleDown,
                      scale,
                    ),
                  ),
                if (showDouble && showSplit) SizedBox(width: 10 * scale),
                if (showSplit)
                  Expanded(
                    child: _styledButton(
                      'SPLIT',
                      const [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
                      Icons.call_split,
                      _onSplit,
                      scale,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBettingSection(double scale) {
    if (_game.isBroke) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 32 * scale),
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(color: Colors.red.shade400, width: 2),
        ),
        child: Column(
          children: [
            Text(
              'OUT OF CHIPS',
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.w800,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8 * scale),
            GestureDetector(
              onTap: _onBuyIn,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 8 * scale),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                child: Text(
                  'BUY IN (\$1000)',
                  style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bool isRoundOver = _game.phase == GamePhase.roundOver;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20 * scale),
      padding: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 10 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        children: [
          Text(
            isRoundOver ? 'NEXT BET' : 'PLACE YOUR BET',
            style: TextStyle(
              fontSize: 13 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.75),
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 8 * scale),
          Wrap(
            spacing: 8 * scale,
            runSpacing: 6 * scale,
            alignment: WrapAlignment.center,
            children: [
              _chipButton(10, scale),
              _chipButton(25, scale),
              _chipButton(50, scale),
              _chipButton(100, scale),
              if (_game.balance >= 250) _chipButton(250, scale),
              if (_game.balance >= 500) _chipButton(500, scale),
              _chipButton(_game.balance, scale, label: 'ALL\nIN'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipButton(int amount, double scale, {String? label}) {
    final canAfford = amount <= _game.balance && amount > 0;

    return GestureDetector(
      onTap: canAfford ? () => _onPlaceBet(amount) : null,
      child: CasinoChip(
        size: 56 * scale,
        chipColor: _chipColor(amount),
        label: label ?? '\$$amount',
        enabled: canAfford,
      ),
    );
  }

  Color _chipColor(int amount) {
    if (amount >= 500) return const Color(0xFF7B1FA2);
    if (amount >= 250) return const Color(0xFFE65100);
    if (amount >= 100) return const Color(0xFF263238);
    if (amount >= 50) return const Color(0xFF1565C0);
    if (amount >= 25) return const Color(0xFF2E7D32);
    return const Color(0xFFC62828);
  }

  Widget _styledButton(
    String label,
    List<Color> gradient,
    IconData icon,
    VoidCallback? onTap,
    double scale,
  ) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 11 * scale),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: gradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: enabled ? null : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(14 * scale),
          border: Border.all(
            color: enabled
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.shade700,
            width: 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: gradient.last.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            if (enabled)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 16 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(13 * scale),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: enabled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  size: 18 * scale,
                ),
                SizedBox(width: 6 * scale),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w800,
                    color: enabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _disabledButton(String label, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 11 * scale),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // -- Stats Overlay --

  Widget _buildStatsOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showStats = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.8),
          child: GestureDetector(
            onTap: () {},
            child: SafeArea(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3D1E).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart, color: Colors.amber, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'STATISTICS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _statRow('Hands Played', '${_stats.handsPlayed}'),
                      _statRow('Wins', '${_stats.handsWon}'),
                      _statRow('Losses', '${_stats.handsLost}'),
                      _statRow('Pushes', '${_stats.handsPushed}'),
                      _statRow('Blackjacks', '${_stats.blackjacks}'),
                      _statRow(
                        'Win Rate',
                        _stats.handsPlayed > 0
                            ? '${(_stats.winRate * 100).toStringAsFixed(1)}%'
                            : '--',
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      _statRow('Current Streak', '${_stats.currentStreak}'),
                      _statRow('Best Streak', '${_stats.bestStreak}'),
                      _statRow('Biggest Win', '\$${_stats.biggestWin}'),
                      _statRow('Biggest Loss', '\$${_stats.biggestLoss}'),
                      _statRow('Peak Balance', '\$${_stats.peakBalance}'),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => setState(() => _showStats = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'CLOSE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}
