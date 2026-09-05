import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/empty_state.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/helpers/add_record_dialog.dart';
import 'package:optic/helpers/heartbeat_highlight.dart';
import 'package:optic/helpers/stat_card.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/models/frame.dart';
import 'package:optic/widgets/frame_card.dart';

/// Module 4 — Frame Management / Frame Inventory. Store-wide catalog (not
/// per-client) — every frame variant on the shelf, with the KPIs an
/// optician actually watches: how many models are carried, what the stock
/// is worth at cost, and how many variants are running low or completely
/// out.
class FrameInventoryScreen extends StatelessWidget {
  const FrameInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navItems: (context) =>
          buildAppNavItems(context, NavRoute.frameInventory),
      bodyBuilder: (context, breakpoint) =>
          _FrameInventoryBody(breakpoint: breakpoint),
    );
  }
}

class _FrameInventoryBody extends StatefulWidget {
  final Breakpoint breakpoint;
  const _FrameInventoryBody({required this.breakpoint});

  @override
  State<_FrameInventoryBody> createState() => _FrameInventoryBodyState();
}

class _FrameInventoryBodyState extends State<_FrameInventoryBody> {
  final _searchController = material.TextEditingController();

  // Which frame card (if any) should be glowing right now, and a bump
  // counter so tapping "Out of stock" again re-triggers the heartbeat even
  // if the same card is already the highlighted one — see
  // `_focusOutOfStock` and the `key:` on the `HeartbeatHighlight` below.
  String? _highlightedFrameId;
  int _highlightToken = 0;

  // One GlobalKey per currently-rendered frame card, keyed by frame id —
  // this is what lets `_focusOutOfStock` find a specific card's
  // BuildContext (from this State, outside that card's own subtree) and
  // hand it to `Scrollable.ensureVisible`.
  final Map<String, GlobalKey> _frameKeys = {};

  GlobalKey _keyFor(String frameId) =>
      _frameKeys.putIfAbsent(frameId, () => GlobalKey());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Jumps to and heartbeats the first out-of-stock frame — wired to the
  // "Out of stock" KPI card's onTap. Clears any active search first so the
  // target frame is guaranteed to actually be in the rendered list (a
  // stale search could otherwise filter it out and leave nothing to scroll
  // to); does nothing if there's currently no out-of-stock frame at all.
  void _focusOutOfStock(List<Frame> frames) {
    Frame? target;
    for (final f in frames) {
      if (f.stockAvailable == 0) {
        target = f;
        break;
      }
    }
    if (target == null) return;
    final id = target.id;

    setState(() {
      _searchController.clear();
      _highlightedFrameId = id;
      _highlightToken++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _frameKeys[id]?.currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    });
  }

  String _newId() => 'FR${DateTime.now().millisecondsSinceEpoch}';

  void _addFrame(DataProvider dataProvider) {
    showAddRecordDialog(
      context: context,
      title: AppStrings.addDialogFrameTitle,
      fields:  [
        RecordField(key: 'sku', label: AppStrings.recordFieldSku),
        RecordField(key: 'brand', label: AppStrings.recordFieldBrand),
        RecordField(key: 'model', label: AppStrings.recordFieldModel),
        RecordField(key: 'color', label: AppStrings.recordFieldColor),
        RecordField(
          key: 'size',
          label: AppStrings.recordFieldSize,
          hint: '52-18-140',
        ),
        RecordField(
          key: 'price',
          label: AppStrings.cardFramePrice,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(
          key: 'cost',
          label: AppStrings.recordFieldCost,
          required: false,
          keyboardType: material.TextInputType.number,
        ),
        RecordField(key: 'supplier', label: AppStrings.cardFrameSupplier, required: false),
        RecordField(
          key: 'stockAvailable',
          label: AppStrings.cardFrameStock,
          initialValue: '0',
          keyboardType: material.TextInputType.number,
        ),
      ],
      onSubmit: (v) => dataProvider.addFrame(
        Frame(
          id: _newId(),
          sku: v['sku']!,
          brand: v['brand']!,
          model: v['model']!,
          color: v['color']!,
          size: v['size']!,
          price: double.tryParse(v['price']!) ?? 0,
          cost: double.tryParse(v['cost']!) ?? 0,
          supplier: v['supplier']!,
          stockAvailable: int.tryParse(v['stockAvailable']!) ?? 0,
        ),
      ),
    );
  }

  List<Frame> _filtered(List<Frame> frames) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return frames;
    return frames.where((f) {
      final haystack = '${f.brand} ${f.model} ${f.sku} ${f.color}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final frames = [...dataProvider.frames]
      ..sort((a, b) => a.brand.compareTo(b.brand));

    final stockValue = frames.fold<double>(
      0,
      (sum, f) => sum + f.cost * f.stockAvailable,
    );
    final lowStock = frames
        .where(
          (f) =>
              f.stockAvailable > 0 &&
              f.stockAvailable <= FrameCard.lowStockThreshold,
        )
        .length;
    final outOfStock = frames.where((f) => f.stockAvailable == 0).length;

    final int crossAxisCount = widget.breakpoint == Breakpoint.mobile ? 1 : 4;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(AppStrings.navFrameInventory).large().bold()),
              PrimaryButton(
                onPressed: () => _addFrame(dataProvider),
                leading: const Icon(Icons.add, size: 16),
                child: Text(AppStrings.frameInventoryAddButton),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
            children: [
              DashboardStatCard(
                label: AppStrings.frameInventoryKpiTotal,
                value: '${frames.length}',
                icon: Icons.inventory_2_outlined,
                accent: colorScheme.primary,
              ),
              DashboardStatCard(
                label: AppStrings.frameInventoryKpiStockValue,
                value: '${stockValue.toStringAsFixed(0)} MAD',
                icon: Icons.payments_outlined,
                accent: colorScheme.chart2,
              ),
              DashboardStatCard(
                label: AppStrings.frameInventoryKpiLowStock,
                value: '$lowStock',
                icon: Icons.warning_amber_outlined,
                accent: Colors.orange.shade700,
              ),
              DashboardStatCard(
                label: AppStrings.frameInventoryKpiOutOfStock,
                value: '$outOfStock',
                icon: Icons.remove_shopping_cart_outlined,
                accent: colorScheme.destructive,
                onTap: outOfStock == 0 ? null : () => _focusOutOfStock(frames),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            placeholder: Text(AppStrings.frameInventorySearchPlaceholder),
            onChanged: (_) => setState(() {}),
            features: const [
              InputFeature.leading(
                Icon(Icons.search),
                visibility: InputFeatureVisibility.textEmpty,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final filtered = _filtered(frames);
              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: AppStrings.emptyRecordsGeneric,
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final f in filtered)
                    SizedBox(
                      key: _keyFor(f.id),
                      width: widget.breakpoint == Breakpoint.mobile
                          ? double.infinity
                          : 300,
                      // Only the currently-targeted card gets a token-
                      // suffixed key (forcing a fresh `HeartbeatHighlight`
                      // element, which replays its animation from
                      // `initState`) — every other card keeps a stable
                      // key so re-tapping the KPI doesn't churn the whole
                      // list, just the one card that's actually glowing.
                      child: HeartbeatHighlight(
                        key: f.id == _highlightedFrameId
                            ? ValueKey('hb-${f.id}-$_highlightToken')
                            : ValueKey('hb-${f.id}'),
                        active: f.id == _highlightedFrameId,
                        color: colorScheme.destructive,
                        child: FrameCard(frame: f),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
