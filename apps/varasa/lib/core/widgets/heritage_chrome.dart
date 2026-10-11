import 'package:flutter/material.dart';
import '../theme/varasa_theme.dart';
import 'common.dart';

/// Original authored silhouette assets, kept intact instead of rectangular crops.
class HeritageHeader extends StatelessWidget {
  const HeritageHeader({
    super.key,
    this.home = false,
    this.actions = const [],
    this.back = false,
  });
  final bool home, back;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: home ? 150 : 88,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          home ? 'assets/appbarbg.png' : 'assets/gemsappbarbg.png',
          fit: BoxFit.fill,
          excludeFromSemantics: true,
        ),
        Align(
          alignment: home
              ? const Alignment(0, -.18)
              : const Alignment(-1, -.08),
          child: Padding(
            padding: EdgeInsets.only(
              left: home
                  ? 0
                  : back
                  ? 60
                  : 16,
            ),
            child: Semantics(
              label: 'Varasa',
              image: true,
              child: Image.asset(
                'assets/varasa_logo.png',
                height: home ? 32 : 28,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        if (back)
          Positioned(
            left: 4,
            top: 16,
            child: BackButton(color: VarasaTheme.ink),
          ),
        Positioned(
          right: 4,
          top: 12,
          child: Row(mainAxisSize: MainAxisSize.min, children: actions),
        ),
      ],
    ),
  );
}

class HeritageNavigation extends StatelessWidget {
  const HeritageNavigation({
    super.key,
    required this.index,
    required this.onChanged,
    this.avatar = '',
  });
  final int index;
  final ValueChanged<int> onChanged;
  final String avatar;
  static const labels = [
    'Community',
    'Games',
    'Contribute',
    'Heritage',
    'Profile',
  ];
  static const assets = [
    'assets/home.png',
    'assets/dice.png',
    'assets/plus.png',
    'assets/nav_scroll.png',
    'assets/nav_avatar.png',
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SizedBox(
      height: 82,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/navbar_bg.png',
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: List.generate(
                5,
                (i) => Expanded(
                  child: Semantics(
                    selected: index == i,
                    child: Tooltip(
                      message: labels[i],
                      child: IconButton(
                        key: ValueKey('nav-$i'),
                        tooltip: labels[i],
                        onPressed: () => onChanged(i),
                        padding: const EdgeInsets.all(5),
                        icon: i == 2
                            ? Container(
                                width: 50,
                                height: 50,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: index == i
                                      ? VarasaTheme.ink
                                      : const Color(0xFFD1A487),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  assets[i],
                                  color: Colors.white,
                                  excludeFromSemantics: true,
                                ),
                              )
                            : i == 4
                            ? Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 2,
                                    color: index == i
                                        ? VarasaTheme.ink
                                        : Colors.transparent,
                                  ),
                                ),
                                child: ProfileAvatar(
                                  source: avatar.isEmpty ? assets[i] : avatar,
                                  radius: 21,
                                ),
                              )
                            : Image.asset(
                                assets[i],
                                width: 30,
                                height: 30,
                                color: index == i
                                    ? VarasaTheme.ink
                                    : const Color(0xFFD1A487),
                                excludeFromSemantics: true,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
