// lib/screens/day_group_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/day_group.dart';
import '../services/day_group_service.dart';

class DayGroupScreen extends StatefulWidget {
  final int itineraryId;
  const DayGroupScreen({super.key, required this.itineraryId});

  @override
  State<DayGroupScreen> createState() => _DayGroupScreenState();
}

class _DayGroupScreenState extends State<DayGroupScreen> {
  late Future<List<DayGroup>> _futureDays;

  @override
  void initState() {
    super.initState();
    _futureDays = DayGroupService.fetchDayGroups(widget.itineraryId);
  }

  void _loadDayGroups() {
    setState(() {
      _futureDays = DayGroupService.fetchDayGroups(widget.itineraryId);
    });
  }

  Future<void> _onCreateDay() async {
    // default to today; you might pop up a date picker instead
    final today = DateTime.now();
    final currentDays = await DayGroupService.fetchDayGroups(widget.itineraryId);
    final nextOrder = currentDays.length + 1;
    await DayGroupService.createDayGroup(
      itineraryId: widget.itineraryId,
      date: today,
      title: 'Day ${DateTime.now().day}',
      order: nextOrder
    );
    _loadDayGroups();
  }

  Future<void> _onDeleteDay(int dayId) async {
    await DayGroupService.deleteDayGroup(
      itineraryId: widget.itineraryId,
      dayGroupId: dayId,
    );
    _loadDayGroups();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DayGroup>>(
      future: _futureDays,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text('Error: ${snap.error}', style: GoogleFonts.poppins(color: Colors.red)),
          );
        }
        final days = snap.data!;
        return ReorderableListView.builder(
          onReorder: (oldIndex, newIndex) async {
            if (newIndex > oldIndex) newIndex--;
            final ids = days.map((d) => d.id).toList();
            final movedId = ids.removeAt(oldIndex);
            ids.insert(newIndex, movedId);
            await DayGroupService.reorderDayGroups(
              itineraryId: widget.itineraryId,
              orderedIds: ids,
            );
            _loadDayGroups();
          },
          itemCount: days.length + 1,
          itemBuilder: (ctx, i) {
            if (i == days.length) {
              // the “+” at the end
              return ListTile(
                key: ValueKey('add_${days.length}'),
                leading: const Icon(Icons.add_circle_outline),
                title: Text('Add Day', style: GoogleFonts.poppins()),
                onTap: _onCreateDay,
              );
            }
            final day = days[i];
            return ListTile(
              key: ValueKey(day.id),
              title: Text(
                '${day.title} (${day.date.toIso8601String().substring(0, 10)})',
                style: GoogleFonts.poppins(),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _onDeleteDay(day.id),
              ),
            );
          },
        );
      },
    );
  }
}