/// Which named breakpoint a screen is currently laid out for.
///
/// Kept as its own enum (rather than three loose booleans) so layout
/// decisions can be a `switch` instead of a chain of `if`/`else`, and so
/// it's shared by every screen instead of being redefined per-screen.
enum Breakpoint { mobile, tablet, desktop }

Breakpoint resolveBreakpoint({
  required bool mobile,
  required bool tablet,
  required bool desktop,
}) {
  if (desktop) return Breakpoint.desktop;
  if (tablet) return Breakpoint.tablet;
  return Breakpoint.mobile;
}