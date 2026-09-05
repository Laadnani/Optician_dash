import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Fire-and-listen trigger for [HeartbeatHighlight] — call [pulse] any time
/// you want the wrapped card to glow + heartbeat again, even if it never
/// stopped being the "active" one (e.g. tapping the same summary/KPI card
/// twice in a row should replay the animation, not no-op the second time).
///
/// Optional: most call sites don't need this — flipping [HeartbeatHighlight
/// .active] from false to true already plays the animation once. Reach for
/// a controller when the *same* card might need to re-glow while it's
/// already the active one (see [HeartbeatHighlight]'s doc for both modes).
class HeartbeatHighlightController extends ChangeNotifier {
  void pulse() => notifyListeners();
}

/// Wraps [child] in a colored glow shadow plus a gentle "heartbeat" scale
/// bounce — the visual used across the app to draw the eye to one specific
/// card after the user taps a related summary/KPI tile.
///
/// Concrete example this was built for: Frame Inventory's "Out of stock"
/// KPI card, tapped, scrolls to and heartbeats the matching frame card
/// (e.g. "Tom Ford FT5401") in red so it's unmistakable which item the KPI
/// was talking about. The same wiring is reused by every other inventory
/// screen's low-stock/out-of-stock KPIs (Lens Catalog, Contact Lenses,
/// Accessories, Suppliers).
///
/// Two ways to trigger it — pick whichever fits the call site:
///  - Flip [active] from `false` to `true` — simplest option, good for "this
///    card is now the selected/focused one" where re-selecting the same
///    card is a no-op (nothing to replay).
///  - Pass a [controller] and call `controller.pulse()` — replays the
///    animation every time, even if the card was already active a moment
///    ago (what you want for "tap the KPI again to re-locate the item").
///
/// Purely a visual overlay: the glow is painted as a `BoxShadow` (no
/// animated border — a static card keeps its own normal border/edges, only
/// the shadow pulses) and the "float" is a bounded `Transform.scale`, both
/// wrapped *around* [child] rather than altering its own layout — so
/// dropping this around an existing card changes nothing on screen until
/// it's actually triggered.
class HeartbeatHighlight extends StatefulWidget {
  final Widget child;

  /// Optional replay trigger — see the class doc for when to use this vs.
  /// [active].
  final HeartbeatHighlightController? controller;

  /// One-shot trigger: flipping this from `false` to `true` plays the
  /// animation once. Flipping it back to `false` does nothing visually on
  /// its own (the animation always finishes and settles back to normal by
  /// itself) — it just re-arms the false→true trigger for next time.
  final bool active;

  /// Glow color — red for "needs attention" (out of stock, overdue, etc.),
  /// but any [Color] works for other kinds of focus callouts.
  final Color color;

  /// Corner radius of the glow shadow — match the wrapped card's own
  /// radius so the glow reads as coming from the card, not a mismatched
  /// rectangle behind it.
  final BorderRadius borderRadius;

  /// How many heartbeats to play before settling. Each beat is a quick
  /// "lub-dub" double-pulse, matching an actual heartbeat's waveform
  /// rather than a plain sine pulse.
  final int pulseCount;

  /// Duration of a single beat — total animation length is
  /// `pulseDuration * pulseCount`.
  final Duration pulseDuration;

  final double maxGlowBlur;
  final double maxGlowSpread;

  /// Peak scale-up at the strongest point of a beat, e.g. `0.035` = the
  /// card grows to 103.5% before settling back — the "float" effect.
  final double scaleAmount;

  const HeartbeatHighlight({
    super.key,
    required this.child,
    this.controller,
    this.active = false,
    this.color = Colors.red,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.pulseCount = 3,
    this.pulseDuration = const Duration(milliseconds: 700),
    this.maxGlowBlur = 24,
    this.maxGlowSpread = 3,
    this.scaleAmount = 0.035,
  });

  @override
  State<HeartbeatHighlight> createState() => _HeartbeatHighlightState();
}

class _HeartbeatHighlightState extends State<HeartbeatHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pulseDuration * widget.pulseCount,
    );
    widget.controller?.addListener(_handlePulse);
    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(covariant HeartbeatHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handlePulse);
      widget.controller?.addListener(_handlePulse);
    }
    if (!oldWidget.active && widget.active) _play();
    if (oldWidget.pulseDuration != widget.pulseDuration ||
        oldWidget.pulseCount != widget.pulseCount) {
      _controller.duration = widget.pulseDuration * widget.pulseCount;
    }
  }

  void _handlePulse() => _play();

  void _play() {
    _controller
      ..stop()
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handlePulse);
    _controller.dispose();
    super.dispose();
  }

  // A single "beat" as a bounded bump centered at [start] with width
  // [width] (both in the same 0..1 per-cycle position space), shaped as a
  // half-sine so it eases in and out instead of snapping.
  double _beat(double cyclePos, double start, double width) {
    final local = (cyclePos - start) / width;
    if (local < 0 || local > 1) return 0;
    return math.sin(local * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0..1 across the whole run
        final cyclePos = (t * widget.pulseCount) % 1.0;

        // "Lub-dub": a strong beat right at the start of each cycle, then
        // a smaller echo just after — an actual heartbeat has two pulses
        // per cycle, not one, and it reads as far more "alive" than a
        // single symmetric pulse would.
        final lub = _beat(cyclePos, 0.0, 0.18);
        final dub = _beat(cyclePos, 0.28, 0.14) * 0.6;
        final beat = (lub + dub).clamp(0.0, 1.0);

        // Each successive cycle is visibly softer than the last, so the
        // card reads as "settling down" rather than stopping abruptly.
        final envelope = 1.0 - (t * 0.55);
        final intensity = (beat * envelope).clamp(0.0, 1.0);

        final scale = 1.0 + widget.scaleAmount * intensity;
        // Stronger opacity ceiling than before (was split across both
        // border + shadow) since the shadow alone now carries the whole
        // "glowing" read.
        final glowColor = widget.color.withOpacity(0.65 * intensity);

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: intensity > 0.01
                  ? [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: widget.maxGlowBlur * intensity,
                        spreadRadius: widget.maxGlowSpread * intensity,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
