import 'package:flutter/material.dart';

class HelpOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const HelpOverlay({super.key, required this.onDismiss});

  @override
  State<HelpOverlay> createState() => _HelpOverlayState();
}

class _HelpOverlayState extends State<HelpOverlay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _HelpPage(
      title: 'CARD VALUES',
      icon: Icons.style,
      items: [
        '2-10 are worth face value',
        'Jack, Queen, King are worth 10',
        'Ace is worth 11 or 1 (whichever is better)',
        'Goal: get as close to 21 without going over',
      ],
    ),
    _HelpPage(
      title: 'ACTIONS',
      icon: Icons.touch_app,
      items: [
        'HIT — Draw another card',
        'STAND — Keep your current hand',
        'DOUBLE — Double your bet, receive one card',
        'SPLIT — Split matching cards into two hands',
        'INSURANCE — Side bet when dealer shows an Ace',
      ],
    ),
    _HelpPage(
      title: 'TABLE RULES',
      icon: Icons.gavel,
      items: [
        'Dealer must hit on soft 17',
        'Blackjack pays 3 to 2',
        'Insurance pays 2 to 1',
        'Split aces receive one card each',
        'No blackjack on split hands',
      ],
    ),
    _HelpPage(
      title: 'BASIC STRATEGY',
      icon: Icons.lightbulb,
      items: [
        'Always stand on 17 or higher',
        'Always hit on 11 or lower',
        'Double down on 10 or 11 vs dealer low card',
        'Split Aces and 8s, never split 10s or 5s',
        'Take insurance sparingly (house edge is high)',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: GestureDetector(
          onTap: () {},
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Container(
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
                              Icon(page.icon, color: Colors.amber, size: 36),
                              const SizedBox(height: 12),
                              Text(
                                page.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ...page.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '  \u2022  ',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white.withValues(alpha: 0.85),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == i
                            ? Colors.amber
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'GOT IT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpPage {
  final String title;
  final IconData icon;
  final List<String> items;

  const _HelpPage({
    required this.title,
    required this.icon,
    required this.items,
  });
}
