import 'package:flutter/material.dart';

import '../../../models/models.dart';

/// Day tabs for flight-based navigation (Day 1, Day 2, ...).
///
/// Each tab corresponds to one [EventFlight]. Shows flight name and
/// summary stats (player count, table count).
class DayTabs extends StatelessWidget {
  final List<EventFlight> flights;
  final int selectedDayIndex;
  final ValueChanged<int> onDaySelected;

  const DayTabs({
    super.key,
    required this.flights,
    required this.selectedDayIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (flights.isEmpty) return const SizedBox.shrink();

    return DefaultTabController(
      length: flights.length,
      initialIndex: _initialIndex,
      child: TabBar(
        isScrollable: true,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey.shade600,
        onTap: (index) {
          if (index < flights.length) {
            onDaySelected(flights[index].dayIndex);
          }
        },
        tabs: [
          for (final flight in flights)
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    flight.flightName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${flight.playerCount ?? 0} players \u00b7 ${flight.tableCount} tables',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int get _initialIndex {
    final idx = flights.indexWhere((f) => f.dayIndex == selectedDayIndex);
    return idx >= 0 ? idx : 0;
  }
}
