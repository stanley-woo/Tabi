import 'package:frontend/screens/create_itinerary_screen.dart';

class DayGroupEditorModel {
  DateTime date;
  List<ItineraryBlockEditorModel> blocks;

  DayGroupEditorModel({
    required this.date,
    this.blocks = const []
  });
}