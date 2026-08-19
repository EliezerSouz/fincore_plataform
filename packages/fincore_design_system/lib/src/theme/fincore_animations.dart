import 'package:flutter/material.dart';

/// Biblioteca de animações reutilizáveis do FINCORE Platform.
///
/// Todas as animações seguem as guidelines de motion:
/// - **Entrada**: 300ms com `easeOutCubic`
/// - **Saída**: 200ms com `easeInCubic`
/// - **Micro-interações**: 150ms com `easeInOut`
class FincoreAnimations {
  FincoreAnimations._();

  // ── Durações padrão ────────────────────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration countUpDuration = Duration(milliseconds: 800);

  // ── Curvas padrão ──────────────────────────────────────────────────────────
  static const Curve entryEase = Curves.easeOutCubic;
  static const Curve exitEase = Curves.easeInCubic;
  static const Curve microEase = Curves.easeInOut;

  /// Widget que aplica fade + slide de baixo para cima na entrada.
  static Widget fadeSlideIn({
    required Widget child,
    required Animation<double> animation,
    double offsetY = 20,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: entryEase),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, offsetY / 100),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: entryEase)),
        child: child,
      ),
    );
  }

  /// Widget que aplica scale + fade na entrada.
  static Widget scaleIn({
    required Widget child,
    required Animation<double> animation,
    double beginScale = 0.92,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: entryEase),
      child: ScaleTransition(
        scale: Tween<double>(begin: beginScale, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: entryEase)),
        child: child,
      ),
    );
  }
}

/// Widget de entrada animada — aplica fade + slide ao child no initState.
class FincoreAnimatedEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const FincoreAnimatedEntry({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.offsetY = 24,
  });

  @override
  State<FincoreAnimatedEntry> createState() => _FincoreAnimatedEntryState();
}

class _FincoreAnimatedEntryState extends State<FincoreAnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: FincoreAnimations.entryEase,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: FincoreAnimations.entryEase,
    ));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Widget de lista com animação staggered — cada item entra com delay crescente.
class FincoreStaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final double offsetY;

  const FincoreStaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 60),
    this.itemDuration = const Duration(milliseconds: 400),
    this.offsetY = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(children.length, (index) {
        return FincoreAnimatedEntry(
          delay: Duration(milliseconds: itemDelay.inMilliseconds * index),
          duration: itemDuration,
          offsetY: offsetY,
          child: children[index],
        );
      }),
    );
  }
}

/// Contador animado que interpola de 0 ao valor alvo.
class FincoreCountUp extends StatefulWidget {
  final int targetValue;
  final Duration duration;
  final TextStyle? style;
  final String Function(int value)? formatter;

  const FincoreCountUp({
    super.key,
    required this.targetValue,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.formatter,
  });

  @override
  State<FincoreCountUp> createState() => _FincoreCountUpState();
}

class _FincoreCountUpState extends State<FincoreCountUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = IntTween(begin: 0, end: widget.targetValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant FincoreCountUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _animation = IntTween(begin: 0, end: widget.targetValue).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final displayValue = widget.formatter != null
            ? widget.formatter!(_animation.value)
            : _animation.value.toString();
        return Text(displayValue, style: widget.style);
      },
    );
  }
}
