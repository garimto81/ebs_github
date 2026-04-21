import 'package:flutter/material.dart';

import '../../../models/models.dart';

/// Day tabs for flight-based navigation (Day 1, Day 2, ...).
///
/// Each tab corresponds to one [EventFlight]. Shows flight display name and
/// summary stats (player count, table count). Callback payload is
/// `eventFlightId` (backend PK); day ordering is derived from the passed
/// flight list ordering (caller responsibility).
class DayTabs extends StatelessWidget {
  final List<EventFlight> flights;
  final int selectedFlightId;
  final ValueChanged<int> onFlightSelected;

  const DayTabs({
    super.key,
    required this.flights,
    required this.selectedFlightId,
    required this.onFlightSelected,
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
            onFlightSelected(flights[index].eventFlightId);
          }
        },
        tabs: [
          for (final flight in flights)
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    flight.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${flight.playerCount ?? 0} players · ${flight.tableCount} tables',
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
    final idx = flights.indexWhere((f) => f.eventFlightId == selectedFlightId);
    return idx >= 0 ? idx : 0;
  }
}
