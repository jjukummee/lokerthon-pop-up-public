import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/lang.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'brand_mark.dart';
import 'kiosk_button.dart';
import 'kiosk_modal.dart';

/// 팝업 장소에서 행궁다과까지의 짧은 도보 경로를 앱 안에서 보여 주는 안내 시트.
/// 행궁로를 중심으로 그린 약도에 도보 경로를 표시한다.
class StoreDirectionsSheet extends StatefulWidget {
  const StoreDirectionsSheet({
    super.key,
    required this.onClose,
    this.onActivity,
  });

  /// 지도 배경을 미리 디코드한다. 앱 시작 때 한 번 부른다.
  static Future<void> precache(BuildContext context) =>
      _MapGeo.precache(context);

  final VoidCallback onClose;
  final VoidCallback? onActivity;

  @override
  State<StoreDirectionsSheet> createState() => _StoreDirectionsSheetState();
}

class _StoreDirectionsSheetState extends State<StoreDirectionsSheet>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
    reverseDuration: Motion.base,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.emphasized,
    reverseCurve: Curves.easeInCubic,
  );

  /// 경로가 그려지고 도착지가 한 번 반짝인 뒤 다시 시작한다.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _loop
        ..stop()
        ..value = _RouteOverlayPainter.drawEnd;
    } else if (_controller.isDismissed && !_closing) {
      // 시트가 다 올라온 뒤에 경로를 그리기 시작한다. 올라오는 동안에는
      // 경로 레이어를 다시 그리지 않아 첫 프레임들이 가볍다.
      _controller.forward().whenComplete(() {
        if (mounted && !_closing) _loop.repeat();
      });
    }
  }

  Future<void> _close() async {
    if (_closing) return;
    widget.onActivity?.call();
    _closing = true;
    _loop.stop();
    if (!MediaQuery.disableAnimationsOf(context)) {
      try {
        await _controller.reverse().orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (mounted) widget.onClose();
  }

  @override
  void dispose() {
    _loop.dispose();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    namesRoute: true,
    label: tr('행궁다과 길 안내', 'Directions to Haenggung Dagwa', '行宮茶菓への道案内'),
    child: KioskModal(
      opacity: _curve,
      onDismiss: _close,
      dismissLabel: tr('닫기', 'Close', '閉じる'),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_curve),
          // 크기 변화 없이 위치만 옮겨야 캐시된 레이어를 그대로 쓴다.
          // 지도와 안내를 또렷하게 읽어야 하는 시트라 반투명 유리 대신
          // 불투명한 면을 쓴다. 뒤 흐림도 필요 없어 움직임이 가볍다.
          child: RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(Radii.sheet),
                  border: Border.all(color: AppColors.mist),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentDeep.withValues(alpha: 0.16),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: SizedBox(
                  key: const ValueKey('directions-sheet'),
                  width: 1188,
                  height: 824,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(44, 18, 44, 34),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 54,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.lineStrong.withValues(
                                alpha: 0.42,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 로고와 닫기 버튼의 폭이 달라 Spacer로는 가운데가 맞지
                        // 않는다. 문구는 줄 전체의 가운데에 따로 놓는다.
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              children: [
                                const BrandMark(compact: true),
                                const Spacer(),
                                Semantics(
                                  button: true,
                                  label: tr('닫기', 'Close', '閉じる'),
                                  child: IconButton.filledTonal(
                                    onPressed: _close,
                                    icon: const Icon(Icons.close_rounded),
                                    iconSize: 26,
                                    style: IconButton.styleFrom(
                                      fixedSize: const Size(50, 50),
                                      backgroundColor: AppColors.accentSoft,
                                      foregroundColor: AppColors.accentDeep,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // 자간이 마지막 글자 뒤에도 붙어 글자가 그만큼
                            // 왼쪽으로 보인다. 같은 폭을 앞에 더해 맞춘다.
                            Padding(
                              padding: const EdgeInsets.only(left: 2.8),
                              child: Text(
                                'A SHORT WALK',
                                key: const ValueKey('directions-eyebrow'),
                                style: Type.eyebrow(
                                  AppColors.accent,
                                  tracking: 2.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _RouteIllustration(loop: _loop),
                              ),
                              const SizedBox(width: 34),
                              Expanded(
                                flex: 4,
                                child: _RouteDetails(
                                  key: const ValueKey(
                                    'store-directions-details',
                                  ),
                                  onClose: _close,
                                ),
                              ),
                            ],
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
      ),
    ),
  );
}

/// 공개용 약도의 좌표.
abstract final class _MapGeo {
  static const asset = 'assets/map/route_map.png';

  /// 시트를 처음 열 때 디코드하느라 프레임이 밀리지 않도록 앱 시작 때
  /// 미리 올려 둔다.
  static Future<void> precache(BuildContext context) =>
      precacheImage(const AssetImage(asset), context);
  static const crop = Rect.fromLTWH(0, 0, 1120, 1194);

  /// 가회당 입구 → 행궁로 → 행궁다과 입구.
  static const route = [
    Offset(615, 906),
    Offset(560, 906),
    Offset(560, 190),
    Offset(615, 190),
  ];
  static const start = Offset(650, 868);
  static const destination = Offset(650, 196);

  /// 도보 배지는 경로 왼쪽에 둔다.
  static const walkBadge = Offset(510, 505);

  /// [size] 영역을 BoxFit.cover로 채운 배경에서 [point]가 놓이는 위치.
  static Offset place(Offset point, Size size) {
    final scale = math.max(size.width / crop.width, size.height / crop.height);
    final dx = (size.width - crop.width * scale) / 2;
    final dy = (size.height - crop.height * scale) / 2;
    return Offset(
      dx + (point.dx - crop.left) * scale,
      dy + (point.dy - crop.top) * scale,
    );
  }
}

class _RouteIllustration extends StatelessWidget {
  const _RouteIllustration({required this.loop});

  final Animation<double> loop;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: tr(
      '가회당에서 행궁로를 따라 행궁다과 2층까지 이동하는 길 안내 지도',
      'Map of the route from Gahoedang along Haenggung-ro to Haenggung Dagwa on the second floor',
      'カフェダンから行宮路を通り、行宮茶菓2階までの案内地図',
    ),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.ground,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.mist),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            Offset at(Offset p) => _MapGeo.place(p, size);
            // 움직이지 않는 지도·이름은 한 레이어로 캐시하고, 반복해서
            // 다시 그리는 경로만 따로 둔다.
            return Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: Image(
                            image: AssetImage(_MapGeo.asset),
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            gaplessPlayback: true,
                          ),
                        ),
                        ..._roadLabels(
                          at,
                          size,
                          MediaQuery.textScalerOf(context),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _RouteOverlayPainter(loop, [
                        for (final p in _MapGeo.route) at(p),
                      ], at(_MapGeo.destination)),
                    ),
                  ),
                ),
                _anchored(
                  at(_MapGeo.walkBadge),
                  const Alignment(1, 0),
                  _WalkBadge(tr('1분', '1 min', '1分')),
                ),
                _anchored(
                  at(_MapGeo.start),
                  Alignment.bottomCenter,
                  const _MapPin(
                    color: AppColors.celadon,
                    icon: Icons.storefront_rounded,
                  ),
                ),
                _anchored(
                  at(_MapGeo.destination),
                  Alignment.bottomCenter,
                  const _MapPin(
                    color: AppColors.accent,
                    icon: Icons.local_cafe_rounded,
                  ),
                ),
                _besidePin(
                  at(_MapGeo.destination),
                  _PlaceLabel(
                    eyebrow: tr('도착', 'ARRIVE', '到着'),
                    title: tr('행궁다과 · 2층', 'Haenggung Dagwa · 2F', '行宮茶菓・2階'),
                    detail: tr('행궁로 25', '25 Haenggung-ro', '行宮路25'),
                    color: AppColors.accent,
                  ),
                ),
                _besidePin(
                  at(_MapGeo.start),
                  _PlaceLabel(
                    eyebrow: tr('출발 · 현재 위치', 'START · YOU ARE HERE', '出発・現在地'),
                    title: tr('가회당 · 팝업', 'Gahoedang · Pop-up', 'カフェダン・ポップアップ'),
                    detail: tr('행궁로 33', '33 Haenggung-ro', '行宮路33'),
                    color: AppColors.celadon,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  /// 핀 머리 오른쪽에 이름표를 붙인다. 지도 밖으로 넘치지 않게 폭을 줄이고,
  /// 글자를 키워 이름표가 길어지면 세로로도 지도 안에 밀어 넣는다.
  static Widget _besidePin(Offset tip, _PlaceLabel label) => Positioned.fill(
    child: CustomSingleChildLayout(
      delegate: _BesidePinLayout(tip),
      child: label,
    ),
  );

  /// [point]에 자식의 [anchor] 지점이 오도록 놓는다.
  static Widget _anchored(Offset point, Alignment anchor, Widget child) =>
      Positioned(
        left: point.dx,
        top: point.dy,
        child: FractionalTranslation(
          translation: Offset(-(anchor.x + 1) / 2, -(anchor.y + 1) / 2),
          child: child,
        ),
      );

  static List<Widget> _roadLabels(
    Offset Function(Offset) at,
    Size size,
    TextScaler scaler,
  ) {
    // 기울어진 글자는 높이의 절반만큼 모서리가 더 튀어나온다.
    final halfHeight = scaler.scale(_RoadLabel.fontSize) * 0.75;
    Widget road(Offset point, double angle, String text) {
      final p = at(point);
      return _anchored(
        p,
        Alignment.center,
        _RoadLabel(
          text,
          angle: angle,
          maxLength: _roadRoom(p, angle, size, halfHeight),
        ),
      );
    }

    return [
      road(const Offset(560, 1040), 1.57, tr('행궁로', 'Haenggung-ro', '行宮路')),
    ];
  }

  /// [p]를 가운데로 [angle]만큼 기운 이름이 지도 밖으로 나가지 않는 최대 길이.
  /// 기운 글자의 모서리(높이의 절반)와 둥근 테두리 여백까지 감안한다.
  static double _roadRoom(
    Offset p,
    double angle,
    Size size,
    double halfHeight,
  ) {
    const edge = 8.0;
    final cos = math.cos(angle).abs();
    final sin = math.sin(angle).abs();
    final roomX = math.min(p.dx, size.width - p.dx) - edge - halfHeight * sin;
    final roomY = math.min(p.dy, size.height - p.dy) - edge - halfHeight * cos;
    final alongX = cos < 1e-6 ? double.infinity : roomX / cos;
    final alongY = sin < 1e-6 ? double.infinity : roomY / sin;
    return 2 * math.max(0.0, math.min(alongX, alongY));
  }
}

class _BesidePinLayout extends SingleChildLayoutDelegate {
  const _BesidePinLayout(this.tip);

  final Offset tip;

  static const _gap = 26.0;
  static const _edge = 12.0;

  /// 핀 끝에서 핀 머리 가운데까지의 높이.
  static const _head = 32.0;

  double get _left => tip.dx + _gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.max(120, constraints.maxWidth - _left - _edge),
        maxHeight: math.max(0, constraints.maxHeight - _edge * 2),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final centered = tip.dy - _head - childSize.height / 2;
    final top = centered.clamp(
      _edge,
      math.max(_edge, size.height - _edge - childSize.height),
    );
    return Offset(_left, top.toDouble());
  }

  @override
  bool shouldRelayout(_BesidePinLayout oldDelegate) => oldDelegate.tip != tip;
}

class _RoadLabel extends StatelessWidget {
  const _RoadLabel(this.text, {required this.angle, required this.maxLength});

  final String text;
  final double angle;

  /// 지도 안에 들어가는 최대 길이. 글자를 키워 이보다 길어지면 이 길이에 맞춘다.
  final double maxLength;

  static const fontSize = 12.0;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxLength),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: Type.caption.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: AppColors.faint,
          ),
        ),
      ),
    ),
  );
}

class _WalkBadge extends StatelessWidget {
  const _WalkBadge(this.label);

  /// 번역 문구는 밖에서 받는다. const 위젯 안에서 tr()을 부르면 언어가
  /// 바뀌어도 다시 그려지지 않을 수 있다.
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.directions_walk_rounded,
          size: 20,
          color: Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Type.caption.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

/// 물방울 모양 지도 핀. 아래 꼭짓점이 좌표에 닿는다.
class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 54,
    child: CustomPaint(
      painter: _PinPainter(color),
      child: Align(
        alignment: const Alignment(0, -0.42),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    ),
  );
}

class _PinPainter extends CustomPainter {
  const _PinPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final tip = Offset(r, size.height);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(r - 6, size.height - 10, 0, r + 12, 0, r)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..cubicTo(size.width, r + 12, r + 6, size.height - 10, tip.dx, tip.dy)
      ..close();
    canvas
      ..drawShadow(path, AppColors.accentDeep, 4, false)
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white,
      );
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) => oldDelegate.color != color;
}

class _PlaceLabel extends StatelessWidget {
  const _PlaceLabel({
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.color,
  });

  final String eyebrow;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 230),
    padding: const EdgeInsets.fromLTRB(14, 10, 16, 11),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border(left: BorderSide(color: color, width: 4)),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentDeep.withValues(alpha: 0.1),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Type.eyebrow(color, latin: isEn, size: 11, tracking: 1.2),
        ),
        const SizedBox(height: 3),
        // 핀 옆 폭이 좁으면 잘리지 않고 두 줄로 흐른다.
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Type.section.copyWith(fontSize: 17, height: 1.25),
        ),
        Text(detail, style: Type.caption.copyWith(fontSize: 13)),
      ],
    ),
  );
}

class _RouteDetails extends StatelessWidget {
  const _RouteDetails({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: SingleChildScrollView(
          primary: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(
                  '행궁다과까지\n걸어서 1분이에요',
                  'Haenggung Dagwa is\njust a 1-minute walk',
                  '行宮茶菓まで\n歩いて約1分です',
                ),
                style: Type.question.copyWith(fontSize: 38, height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  '팝업을 나와 행궁로를 따라 98m만 걸어오세요.',
                  'Leave the pop-up and follow Haenggung-ro for 98 m.',
                  'ポップアップを出て、行宮路を98mほどお進みください。',
                ),
                style: Type.bodyMuted.copyWith(fontSize: 18, height: 1.48),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _RouteMetric(
                    icon: Icons.directions_walk_rounded,
                    value: tr('약 1분', '1 min', '約1分'),
                  ),
                  const SizedBox(width: 10),
                  _RouteMetric(icon: Icons.route_rounded, value: '98 m'),
                ],
              ),
              const SizedBox(height: 20),
              _RouteStep(
                number: '1',
                title: tr('팝업에서 출발', 'Leave the pop-up', 'ポップアップを出発'),
                body: tr(
                  '가회당에서 나와 행궁로를 따라 걸어주세요.',
                  'Exit Gahoedang and follow Haenggung-ro.',
                  'カフェダンを出て、行宮路に沿ってお進みください。',
                ),
              ),
              const SizedBox(height: 10),
              _RouteStep(
                number: '2',
                title: tr('건물 2층에 도착', 'Head up to the 2nd floor', '建物の2階へ'),
                body: tr(
                  '행궁로 25 건물 2층에서 기다리고 있어요.',
                  'We’re waiting on the 2nd floor at 25 Haenggung-ro.',
                  '行宮路25の建物2階でお待ちしています。',
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      KioskButton(
        label: tr('확인했어요', 'Got it', '確認しました'),
        fullWidth: true,
        icon: Icons.check_rounded,
        onPressed: onClose,
      ),
    ],
  );
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.celadonSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.celadon),
          const SizedBox(width: 8),
          Text(value, style: Type.section.copyWith(fontSize: 17)),
        ],
      ),
    ),
  );
}

class _RouteStep extends StatelessWidget {
  const _RouteStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.ground,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.all(4),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: Type.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Type.section.copyWith(fontSize: 18)),
              const SizedBox(height: 3),
              Text(
                body,
                style: Type.caption.copyWith(fontSize: 14, height: 1.42),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 경로 한 바퀴: 옅은 전체 경로 위로 진한 선이 출발지에서 도착지까지
/// 이어지고, 도착지에서 물결이 한 번 퍼진 뒤 사라졌다가 다시 시작한다.
class _RouteOverlayPainter extends CustomPainter {
  _RouteOverlayPainter(this.loop, this.points, this.destination)
    : super(repaint: loop);

  /// 한 바퀴 중 선이 다 그려지는 시점.
  static const drawEnd = 0.55;
  static const _fadeStart = 0.86;

  final Animation<double> loop;
  final List<Offset> points;
  final Offset destination;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final metric = path.computeMetrics().first;
    final t = loop.value;

    // 전체 경로 (옅게)
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white,
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.accent.withValues(alpha: 0.22),
      );

    final draw = Curves.easeInOutCubic.transform((t / drawEnd).clamp(0.0, 1.0));
    final fade = t < _fadeStart
        ? 1.0
        : 1 - Curves.easeIn.transform((t - _fadeStart) / (1 - _fadeStart));
    if (draw > 0 && fade > 0) {
      final shown = metric.extractPath(0, metric.length * draw);
      canvas.drawPath(
        shown,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.accent.withValues(alpha: fade),
      );

      // 진행 방향 화살표
      final arrow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.9 * fade);
      for (var d = 26.0; d < metric.length * draw - 10; d += 24) {
        final tan = metric.getTangentForOffset(d)!;
        final dir = tan.vector;
        final normal = Offset(-dir.dy, dir.dx);
        final c = tan.position;
        canvas.drawPath(
          Path()
            ..moveTo(
              (c - dir * 2.5 + normal * 2.6).dx,
              (c - dir * 2.5 + normal * 2.6).dy,
            )
            ..lineTo((c + dir * 1.5).dx, (c + dir * 1.5).dy)
            ..lineTo(
              (c - dir * 2.5 - normal * 2.6).dx,
              (c - dir * 2.5 - normal * 2.6).dy,
            ),
          arrow,
        );
      }

      // 걷는 사람 위치
      if (draw < 1) {
        final head = metric.getTangentForOffset(metric.length * draw)!.position;
        canvas
          ..drawCircle(
            head,
            14,
            Paint()..color = AppColors.accent.withValues(alpha: 0.18),
          )
          ..drawCircle(head, 7.5, Paint()..color = Colors.white)
          ..drawCircle(head, 5, Paint()..color = AppColors.accent);
      }
    }

    // 도착 물결
    if (t >= drawEnd && t < _fadeStart + 0.1) {
      final p = ((t - drawEnd) / (_fadeStart + 0.1 - drawEnd)).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(p);
      canvas.drawCircle(
        destination,
        10 + 34 * eased,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.accent.withValues(alpha: 0.45 * (1 - p)),
      );
    }

    // 출발점
    canvas
      ..drawCircle(points.first, 7, Paint()..color = Colors.white)
      ..drawCircle(points.first, 4.5, Paint()..color = AppColors.celadon);
  }

  @override
  bool shouldRepaint(_RouteOverlayPainter oldDelegate) =>
      oldDelegate.destination != destination ||
      !_samePoints(oldDelegate.points, points);

  static bool _samePoints(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
