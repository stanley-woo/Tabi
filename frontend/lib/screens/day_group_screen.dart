// lib/screens/day_group_screen.dart

import 'package:flutter/material.dart';
import '../services/day_group_service.dart';
import '../models/day_group.dart';

/// A screen that displays and manages DayGroups for a given itinerary.
class DayGroupScreen extends StatefulWidget {
  final int itineraryId;
  DayGroupScreen({ required this.itineraryId });

  @override
  _DayGroupScreenState createState() => _DayGroupScreenState();
}

class _DayGroupScreenState extends State<DayGroupScreen> {
  late Future<List<DayGroup>> _dayGroupsFuture;

  @override
  void initState() {
    super.initState();
    _loadDayGroups();
  }

  void _loadDayGroups() {
    _dayGroupsFuture = DayGroupService.fetchDayGroups(widget.itineraryId);
  }

  Future<void> _onAddDay() async {
    // TODO: show date picker/form for date + title
    final pickedDate = DateTime.now();
    final newDay = await DayGroupService.createDayGroup(
      itineraryId: widget.itineraryId,
      date: pickedDate,
      title: 'New Day',
    );
    _loadDayGroups();
    setState(() {});
  }

  Future<void> _onDeleteDay(int dayId) async {
    await DayGroupService.deleteDayGroup(widget.itineraryId, dayId);
    _loadDayGroups();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Days for Itinerary ${widget.itineraryId}'),
        actions: [ IconButton(icon: Icon(Icons.add), onPressed: _onAddDay) ],
      ),
      body: FutureBuilder<List<DayGroup>>(
        future: _dayGroupsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final days = snap.data!;
          if (days.isEmpty) {
            return Center(child: Text('No days yet. Tap + to add one.'));
          }
          return ReorderableListView(
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              final ids = days.map((d) => d.id).toList();
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              await DayGroupService.reorderDayGroups(widget.itineraryId, ids);
              _loadDayGroups();
              setState(() {});
            },
            children: [
              for (final day in days)
                ListTile(
                  key: ValueKey(day.id),
                  title: Text(day.title ?? 'Day ${day.order}'),
                  subtitle: Text(day.date.toIso8601String().substring(0,10)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _onDeleteDay(day.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}