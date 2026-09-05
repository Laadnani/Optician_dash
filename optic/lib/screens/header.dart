import 'package:optic/responsive.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/localization/app_strings.dart';

class Header extends StatelessWidget {
  final ThemeData theme;
  const Header({super.key, required this.theme});

  Widget _titleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.headerGreeting,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ).semiBold(),
        const SizedBox(height: 4),
        Text(
          AppStrings.headerSubtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ).muted(),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      placeholder: Text(AppStrings.headerSearchPlaceholder),
      features: [
        // Leading icon only visible when the text is empty
        InputFeature.leading(
          StatedWidget.builder(
            builder: (context, states) {
              // Use a muted icon normally, switch to the full icon on hover
              if (states.hovered) {
                return const Icon(Icons.search);
              } else {
                return const Icon(Icons.search).iconMutedForeground();
              }
            },
          ),
          visibility: InputFeatureVisibility.textEmpty,
        ),
        // Clear button visible when there is text and the field is focused,
        // or whenever the field is hovered
        InputFeature.clear(
          visibility:
              (InputFeatureVisibility.textNotEmpty &
                  InputFeatureVisibility.focused) |
              InputFeatureVisibility.hovered,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // On mobile, a Row would hand the search field an unbounded width
    // constraint (it isn't wrapped in Expanded), and asking for
    // width: double.infinity in that context is exactly what triggers
    // the "RenderBox was not laid out" assertion in box.dart. So on
    // mobile we stack title/search vertically instead of forcing them
    // into a Row.
    if (Responsive.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _titleBlock(),
          const SizedBox(height: 12),
          _searchField(),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Expanded (rather than a bare Column) so the title/subtitle text
        // has a bounded, shrinkable width to wrap/ellipsize into instead of
        // pushing the Row wider than its parent and overflowing.
        Expanded(child: _titleBlock()),
        const SizedBox(width: 16),
        SizedBox(width: 260, child: _searchField()),
      ],
    );
  }
}
