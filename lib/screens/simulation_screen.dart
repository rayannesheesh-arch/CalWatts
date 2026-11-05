import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:calwatt/models/appliance.dart';
import 'package:calwatt/models/simulation_day.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/theme/app_theme.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});
  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  SimDay? _clipboard;

  // ── helpers ────────────────────────────────────────────────────────────────

  double _dayKwh(SimDay day, List<Appliance> appliances) {
    double total = 0;
    for (final u in day.usages) {
      final a = _findAppliance(u.applianceId, appliances);
      if (a == null) continue;
      total += (a.wattage * u.quantity * u.hours) / 1000.0;
    }
    return total;
  }

  Appliance? _findAppliance(String id, List<Appliance> appliances) {
    try {
      return appliances.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── actions ────────────────────────────────────────────────────────────────

  void _copyDay(SimDay day) {
    setState(() => _clipboard = day);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Day ${day.day} copied'), duration: const Duration(seconds: 2)),
    );
  }

  void _pasteDay(int targetDay) {
    if (_clipboard == null) return;
    final pasted = _clipboard!.copyWith(day: targetDay);
    context.read<AppState>().setSimDay(pasted);
  }

  void _deleteDay(int dayNumber) {
    context.read<AppState>().deleteSimDay(dayNumber);
  }

  void _editDay(BuildContext context, int dayNumber, List<Appliance> appliances) {
    final appState = context.read<AppState>();
    final existing = appState.getSimDay(dayNumber);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DayEditorSheet(
        dayNumber: dayNumber,
        appliances: appliances,
        existing: existing,
        onSave: (day) => appState.setSimDay(day),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final appliances = appState.appliances;
        final simDays = appState.simulationDays;
        final rate = appState.electricityRate;
        final primary = AppTheme.primaryColor(context);

        // Compute monthly totals
        double totalKwh = 0;
        double maxDayKwh = 0;
        double minDayKwh = double.infinity;
        int maxDay = 0, minDay = 0;
        final Map<String, double> applianceHours = {};
        final Map<String, double> applianceKwh = {};

        for (final day in simDays) {
          final kwh = _dayKwh(day, appliances);
          totalKwh += kwh;
          if (kwh > maxDayKwh) { maxDayKwh = kwh; maxDay = day.day; }
          if (kwh < minDayKwh) { minDayKwh = kwh; minDay = day.day; }
          for (final u in day.usages) {
            final a = _findAppliance(u.applianceId, appliances);
            if (a == null) continue;
            applianceHours[a.name] = (applianceHours[a.name] ?? 0) + u.hours * u.quantity;
            applianceKwh[a.name] = (applianceKwh[a.name] ?? 0) +
                (a.wattage * u.quantity * u.hours) / 1000.0;
          }
        }
        if (simDays.isEmpty) minDayKwh = 0;
        final totalCost = totalKwh * (rate > 0 ? rate : 0);
        final avgDayKwh = simDays.isEmpty ? 0.0 : totalKwh / simDays.length;
        final avgDayCost = avgDayKwh * (rate > 0 ? rate : 0);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Monthly Simulation'),
            actions: [
              IconButton(
                icon: Icon(appState.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round),
                onPressed: () => context.read<AppState>().toggleDarkMode(),
              ),
              if (simDays.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Clear all days',
                  onPressed: () => _confirmClear(context),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                _InfoBanner(hasDays: simDays.isNotEmpty),
                const SizedBox(height: 14),

                // Summary cards
                if (simDays.isNotEmpty) ...[
                  _SummaryGrid(
                    totalKwh: totalKwh,
                    totalCost: totalCost,
                    avgDayKwh: avgDayKwh,
                    avgDayCost: avgDayCost,
                    maxDay: maxDay,
                    maxDayKwh: maxDayKwh,
                    minDay: minDay,
                    minDayKwh: minDayKwh,
                    primary: primary,
                  ),
                  const SizedBox(height: 14),

                  // Bar chart
                  _SimBarChart(simDays: simDays, appliances: appliances, primary: primary),
                  const SizedBox(height: 14),

                  // Appliance breakdown
                  if (applianceKwh.isNotEmpty)
                    _ApplianceBreakdown(
                      applianceKwh: applianceKwh,
                      applianceHours: applianceHours,
                      totalKwh: totalKwh,
                      rate: rate,
                      primary: primary,
                    ),
                  const SizedBox(height: 14),
                ],

                // Day calendar grid
                Text('Day Configuration', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Tap a day to configure it. Max 31 days.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                _DayGrid(
                  simDays: simDays,
                  appliances: appliances,
                  clipboard: _clipboard,
                  primary: primary,
                  onEdit: (day) => _editDay(context, day, appliances),
                  onCopy: (day) {
                    final sd = appState.getSimDay(day);
                    if (sd != null) _copyDay(sd);
                  },
                  onPaste: (day) => _pasteDay(day),
                  onDelete: (day) => _deleteDay(day),
                  dayKwh: (day) {
                    final sd = appState.getSimDay(day);
                    return sd != null ? _dayKwh(sd, appliances) : 0.0;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Simulation'),
        content: const Text('Remove all configured days?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().clearSimulation();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Info Banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final bool hasDays;
  const _InfoBanner({required this.hasDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor(context).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryColor(context), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasDays
                  ? 'Configure up to 31 days. Tap a day cell to add or edit usage.'
                  : 'Tap any day cell below to start configuring your monthly simulation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Grid ─────────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final double totalKwh, totalCost, avgDayKwh, avgDayCost, maxDayKwh, minDayKwh;
  final int maxDay, minDay;
  final Color primary;

  const _SummaryGrid({
    required this.totalKwh,
    required this.totalCost,
    required this.avgDayKwh,
    required this.avgDayCost,
    required this.maxDay,
    required this.maxDayKwh,
    required this.minDay,
    required this.minDayKwh,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SumCard(label: 'Total kWh', value: totalKwh.toStringAsFixed(2), unit: 'kWh', primary: primary)),
            const SizedBox(width: 10),
            Expanded(child: _SumCard(label: 'Total Cost', value: totalCost.toStringAsFixed(2), unit: '₱', primary: primary)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _SumCard(label: 'Avg Daily', value: avgDayKwh.toStringAsFixed(3), unit: 'kWh', primary: primary)),
            const SizedBox(width: 10),
            Expanded(child: _SumCard(label: 'Avg Daily Cost', value: avgDayCost.toStringAsFixed(2), unit: '₱', primary: primary)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SumCard(
                label: 'Highest Day',
                value: maxDay > 0 ? 'Day $maxDay' : '—',
                unit: maxDay > 0 ? '${maxDayKwh.toStringAsFixed(2)} kWh' : '',
                primary: primary,
                icon: Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SumCard(
                label: 'Lowest Day',
                value: minDay > 0 ? 'Day $minDay' : '—',
                unit: minDay > 0 ? '${minDayKwh.toStringAsFixed(2)} kWh' : '',
                primary: primary,
                icon: Icons.arrow_downward,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label, value, unit;
  final Color primary;
  final IconData? icon;

  const _SumCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: primary),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(color: primary),
              overflow: TextOverflow.ellipsis,
            ),
            if (unit.isNotEmpty)
              Text(unit, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _SimBarChart extends StatelessWidget {
  final List<SimDay> simDays;
  final List<Appliance> appliances;
  final Color primary;

  const _SimBarChart({required this.simDays, required this.appliances, required this.primary});

  double _dayKwh(SimDay day) {
    double total = 0;
    for (final u in day.usages) {
      try {
        final a = appliances.firstWhere((ap) => ap.id == u.applianceId);
        total += (a.wattage * u.quantity * u.hours) / 1000.0;
      } catch (_) {}
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...simDays]..sort((a, b) => a.day.compareTo(b.day));
    final maxY = sorted.isEmpty
        ? 10.0
        : sorted.map(_dayKwh).reduce((a, b) => a > b ? a : b) * 1.25;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Consumption', style: Theme.of(context).textTheme.titleMedium),
            Text('kWh per configured day', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barGroups: sorted.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: _dayKwh(e.value),
                          color: primary,
                          width: sorted.length > 15 ? 6 : 10,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < sorted.length) {
                            return Text(
                              'D${sorted[idx].day}',
                              style: const TextStyle(fontSize: 8),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  alignment: BarChartAlignment.spaceAround,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appliance Breakdown ───────────────────────────────────────────────────────

class _ApplianceBreakdown extends StatelessWidget {
  final Map<String, double> applianceKwh;
  final Map<String, double> applianceHours;
  final double totalKwh, rate;
  final Color primary;

  const _ApplianceBreakdown({
    required this.applianceKwh,
    required this.applianceHours,
    required this.totalKwh,
    required this.rate,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = applianceKwh.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appliance Breakdown', style: theme.textTheme.titleMedium),
            Text('Monthly contribution', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            ...sorted.map((entry) {
              final pct = totalKwh > 0 ? entry.value / totalKwh : 0.0;
              final cost = entry.value * (rate > 0 ? rate : 0);
              final hrs = applianceHours[entry.key] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: theme.textTheme.labelLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(2)} kWh',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: primary.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${(pct * 100).toStringAsFixed(1)}% • ${hrs.toStringAsFixed(1)} hrs total',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '₱${cost.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: primary),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Day Grid ──────────────────────────────────────────────────────────────────

class _DayGrid extends StatelessWidget {
  final List<SimDay> simDays;
  final List<Appliance> appliances;
  final SimDay? clipboard;
  final Color primary;
  final void Function(int day) onEdit;
  final void Function(int day) onCopy;
  final void Function(int day) onPaste;
  final void Function(int day) onDelete;
  final double Function(int day) dayKwh;

  const _DayGrid({
    required this.simDays,
    required this.appliances,
    required this.clipboard,
    required this.primary,
    required this.onEdit,
    required this.onCopy,
    required this.onPaste,
    required this.onDelete,
    required this.dayKwh,
  });

  bool _hasDay(int day) => simDays.any((d) => d.day == day);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 0.75,
      ),
      itemCount: 31,
      itemBuilder: (context, index) {
        final day = index + 1;
        final configured = _hasDay(day);
        final kwh = dayKwh(day);
        return _DayCell(
          day: day,
          configured: configured,
          kwh: kwh,
          primary: primary,
          hasClipboard: clipboard != null,
          onTap: () => onEdit(day),
          onCopy: configured ? () => onCopy(day) : null,
          onPaste: clipboard != null ? () => onPaste(day) : null,
          onDelete: configured ? () => onDelete(day) : null,
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool configured;
  final double kwh;
  final Color primary;
  final bool hasClipboard;
  final VoidCallback onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onDelete;

  const _DayCell({
    required this.day,
    required this.configured,
    required this.kwh,
    required this.primary,
    required this.hasClipboard,
    required this.onTap,
    this.onCopy,
    this.onPaste,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color textColor;
    if (configured) {
      bg = primary.withValues(alpha: 0.15);
      textColor = primary;
    } else {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
      textColor = isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: (configured || hasClipboard)
          ? () => _showContextMenu(context)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: configured ? primary.withValues(alpha: 0.4) : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            if (configured) ...[
              const SizedBox(height: 2),
              Text(
                kwh.toStringAsFixed(1),
                style: TextStyle(fontSize: 8, color: primary),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'kWh',
                style: TextStyle(fontSize: 7, color: primary.withValues(alpha: 0.7)),
              ),
            ] else
              Icon(Icons.add, size: 12, color: textColor),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('Day $day', style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () { Navigator.pop(ctx); onTap(); },
            ),
            if (onCopy != null)
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy'),
                onTap: () { Navigator.pop(ctx); onCopy!(); },
              ),
            if (onPaste != null)
              ListTile(
                leading: const Icon(Icons.paste_outlined),
                title: const Text('Paste'),
                onTap: () { Navigator.pop(ctx); onPaste!(); },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(ctx); onDelete!(); },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Day Editor Sheet ──────────────────────────────────────────────────────────

class _DayEditorSheet extends StatefulWidget {
  final int dayNumber;
  final List<Appliance> appliances;
  final SimDay? existing;
  final void Function(SimDay) onSave;

  const _DayEditorSheet({
    required this.dayNumber,
    required this.appliances,
    required this.existing,
    required this.onSave,
  });

  @override
  State<_DayEditorSheet> createState() => _DayEditorSheetState();
}

class _DayEditorSheetState extends State<_DayEditorSheet> {
  late List<_UsageEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.existing?.usages.map((u) {
          final a = _findAppliance(u.applianceId);
          if (a == null) return null;
          return _UsageEntry(
            appliance: a,
            hoursCtrl: TextEditingController(text: u.hours.toStringAsFixed(1)),
            quantity: u.quantity,
          );
        }).whereType<_UsageEntry>().toList() ??
        [];
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.hoursCtrl.dispose();
    }
    super.dispose();
  }

  Appliance? _findAppliance(String id) {
    try {
      return widget.appliances.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void _addAppliance(Appliance a) {
    if (_entries.any((e) => e.appliance.id == a.id)) return;
    setState(() {
      _entries.add(_UsageEntry(
        appliance: a,
        hoursCtrl: TextEditingController(text: '1.0'),
        quantity: 1,
      ));
    });
  }

  void _removeEntry(int index) {
    _entries[index].hoursCtrl.dispose();
    setState(() => _entries.removeAt(index));
  }

  void _save() {
    final usages = _entries.map((e) {
      final hours = double.tryParse(e.hoursCtrl.text) ?? 0;
      return SimApplianceUsage(
        applianceId: e.appliance.id,
        hours: hours.clamp(0, 24),
        quantity: e.quantity,
      );
    }).where((u) => u.hours > 0).toList();

    widget.onSave(SimDay(day: widget.dayNumber, usages: usages));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text('Day ${widget.dayNumber}', style: theme.textTheme.headlineSmall),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              children: [
                // Configured appliances
                if (_entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No appliances added yet.\nTap an appliance below to add it.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else ...[
                  Text('Active Appliances', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ..._entries.asMap().entries.map((e) {
                    final idx = e.key;
                    final entry = e.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(entry.appliance.category.icon, color: primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.appliance.name,
                                    style: theme.textTheme.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => _removeEntry(idx),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: entry.hoursCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Hours',
                                      suffixText: 'hrs',
                                      isDense: true,
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Quantity
                                Row(
                                  children: [
                                    const Text('Qty:'),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: entry.quantity > 1
                                          ? () => setState(() => _entries[idx] = entry.copyWith(quantity: entry.quantity - 1))
                                          : null,
                                      child: Icon(Icons.remove_circle_outline, size: 20, color: entry.quantity > 1 ? primary : Colors.grey),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text('${entry.quantity}', style: theme.textTheme.titleSmall),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => _entries[idx] = entry.copyWith(quantity: entry.quantity + 1)),
                                      child: Icon(Icons.add_circle_outline, size: 20, color: primary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 12),
                Text('Add Appliance', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                ...widget.appliances.map((a) {
                  final alreadyAdded = _entries.any((e) => e.appliance.id == a.id);
                  return ListTile(
                    dense: true,
                    leading: Icon(a.category.icon, color: alreadyAdded ? Colors.grey : primary, size: 18),
                    title: Text(
                      a.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: alreadyAdded ? Colors.grey : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('${a.wattage.toStringAsFixed(0)} W', style: theme.textTheme.bodySmall),
                    trailing: alreadyAdded
                        ? const Icon(Icons.check, color: Colors.green, size: 18)
                        : Icon(Icons.add_circle_outline, color: primary, size: 18),
                    onTap: alreadyAdded ? null : () => _addAppliance(a),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageEntry {
  final Appliance appliance;
  final TextEditingController hoursCtrl;
  final int quantity;

  _UsageEntry({required this.appliance, required this.hoursCtrl, required this.quantity});

  _UsageEntry copyWith({int? quantity}) => _UsageEntry(
        appliance: appliance,
        hoursCtrl: hoursCtrl,
        quantity: quantity ?? this.quantity,
      );
}
