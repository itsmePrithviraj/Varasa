import 'package:flutter/material.dart';
import '../../core/widgets/common.dart';
import '../heritage/cultural_data.dart';
import '../heritage/heritage_page.dart';
import 'game_gateway.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});
  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final _gateway = ChallasAathGateway();
  final _controller = PageController(viewportFraction: .84);
  late final _availability = _gateway.availability();
  bool _launching = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _story() {
    final item =
        (categories.firstWhere((c) => c['title'] == 'Games')['items'] as List)
                .first
            as Map<String, dynamic>;
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => HeritageDetailPage(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) => ContentWidth(
    maxWidth: 640,
    child: LayoutBuilder(
      builder: (context, size) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final cardHeight =
            (size.maxWidth * .84 * 602 / 329).clamp(450.0, 620.0) +
            (scale > 1 ? (scale - 1) * 140 : 0);
        return ListView(
          padding: const EdgeInsets.only(top: 20, bottom: 24),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'FORGOTTEN\nGEMS',
                style: TextStyle(
                  fontFamily: 'CinzelDecorative',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: Color(0xFF201711),
                ),
              ),
            ),
            SizedBox(
              height: cardHeight,
              child: PageView(
                controller: _controller,
                padEnds: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/challasbg.png',
                          fit: BoxFit.fill,
                          excludeFromSemantics: true,
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Challas Aath',
                                style: TextStyle(
                                  fontFamily: 'CormorantGaramond',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'A traditional Indian board game of dice and strategy.',
                                style: TextStyle(
                                  fontFamily: 'Itim',
                                  fontSize: 16,
                                  height: 1.25,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              FutureBuilder<GameAvailability>(
                                future: _availability,
                                builder: (context, s) => Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFFEEDB,
                                          ),
                                          foregroundColor: const Color(
                                            0xFF622A0F,
                                          ),
                                          disabledBackgroundColor: const Color(
                                            0xFFF6E3C2,
                                          ),
                                          disabledForegroundColor: const Color(
                                            0xFF725342,
                                          ),
                                        ),
                                        onPressed:
                                            s.data?.available == true &&
                                                !_launching
                                            ? () async {
                                                setState(
                                                  () => _launching = true,
                                                );
                                                try {
                                                  await _gateway.launch();
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    showError(context, e);
                                                  }
                                                } finally {
                                                  if (mounted) {
                                                    setState(
                                                      () => _launching = false,
                                                    );
                                                  }
                                                }
                                              }
                                            : null,
                                        child: Text(
                                          _launching
                                              ? 'Opening…'
                                              : s.data?.available == true
                                              ? 'Play'
                                              : 'Coming soon',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton.filled(
                                      tooltip: 'About Challas Aath',
                                      onPressed: _story,
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFFEEDB,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF622A0F,
                                        ),
                                      ),
                                      icon: const Icon(Icons.help_outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/gamebg1.png',
                          fit: BoxFit.fill,
                          excludeFromSemantics: true,
                        ),
                        const Positioned(
                          left: 20,
                          right: 20,
                          bottom: 40,
                          child: Column(
                            children: [
                              Text(
                                'More to rediscover',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'CormorantGaramond',
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'More folk games are planned for the collection.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Itim',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Previous game',
                    onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const Flexible(
                    child: Text(
                      'Swipe to discover',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next game',
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'The original Unity game is not included in this preview.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    ),
  );
}
