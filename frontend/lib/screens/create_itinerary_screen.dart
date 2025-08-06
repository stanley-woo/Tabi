import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import 'package:image_picker/image_picker.dart';
import '../screens/map_picker_screen.dart';
import '../services/file_service.dart';
import '../services/itinerary_service.dart';
import '../services/day_group_service.dart';

enum BlockType { text, image, map }

class ItineraryBlockEditorModel {
  BlockType type;
  String content;
  late final TextEditingController controller;

  ItineraryBlockEditorModel({required this.type, this.content = ''}) {
    controller = TextEditingController(text: content);
    controller.addListener(() {
      content = controller.text;
    });
  }
}

class DayGroupEditorModel {
  DateTime date;
  List<ItineraryBlockEditorModel> blocks;

  DayGroupEditorModel({
    required this.date,
    this.blocks = const [],
  });
}

class CreateItineraryScreen extends StatefulWidget {
  const CreateItineraryScreen({Key? key}) : super(key: key);

  @override
  State<CreateItineraryScreen> createState() =>
      _CreateItineraryScreenState();
}

class _CreateItineraryScreenState extends State<CreateItineraryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagInputController = TextEditingController();

  bool _isPublic = true;
  final List<String> _tags = [];

  // For simplicity: this holds the blocks for *the currently selected day*
  final List<ItineraryBlockEditorModel> _blocks = [];

  // Support multiple days UI but we only save blocks for the selected one today
  // List<DateTime> _dayDates = [DateTime.now()];
  final List<DayGroupEditorModel> _days = [DayGroupEditorModel(date: DateTime.now(), blocks: [])];
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  // Helpers to convert "lat,lng" strings to plugin LatLngs
  gmaps.LatLng _toGMapLatLng(String s) {
    final parts = s.split(',');
    return gmaps.LatLng(
      double.parse(parts[0]),
      double.parse(parts[1]),
    );
  }

  amaps.LatLng _toAMapLatLng(String s) {
    final parts = s.split(',');
    return amaps.LatLng(
      double.parse(parts[0]),
      double.parse(parts[1]),
    );
  }

  Future<void> _pickImage(int idx) async {
    final day = _days[_selectedDay];
    final block = day.blocks[idx];

    final result = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() {
        block.content = result.path;
      });
    }
  }

  Future<void> _pickLocation(int idx) async {
    final day = _days[_selectedDay];
    final block = day.blocks[idx];

    final result = await Navigator.push<LatLng>(context, MaterialPageRoute(builder: (_) => const MapPickerScreen()));
    if (result != null) {
      setState(() {
        block.content = '${result.latitude},${result.longitude}';
      });
    }
  }

  void _addTag() {
    final text = _tagInputController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagInputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 16, bottom: 16),
              title: Text('Customize',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 20)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://picsum.photos/600/400',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
        body: Stack(
          children: [
            // White “sheet”
            Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Edit'),
                      Tab(text: 'Preview'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_editPane(), _previewPane()],
                    ),
                  ),
                ],
              ),
            ),

            // Create Trip button
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(32)),
                ),
                onPressed: () {
                  if (_formKey.currentState?.validate() ??
                      false) {
                    _saveTrip();
                  }
                },
                child: Text(
                  'Create Trip',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


    /// Block editor card for a single block
  Widget _blockEditor(
      int idx, ItineraryBlockEditorModel block) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // selector + delete
            Row(
              children: [
                DropdownButton<BlockType>(
                  value: block.type,
                  items: BlockType.values.map((bt) {
                    final lbl = bt == BlockType.text
                        ? 'Text'
                        : bt == BlockType.image
                            ? 'Image'
                            : 'Map';
                    return DropdownMenuItem(
                        value: bt, child: Text(lbl));
                  }).toList(),
                  onChanged: (bt) =>
                      setState(() => block.type = bt!),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Colors.redAccent),
                  onPressed: () => setState(() =>
                      _blocks.removeAt(idx)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // EDIT CONTENT
            if (block.type == BlockType.text) ...[
              TextFormField(
                controller: block.controller,
                decoration: InputDecoration(
                  hintText: 'Enter text',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: null,
              ),
            ] else if (block.type == BlockType.image) ...[
              if (block.content.isNotEmpty)
                Image.file(
                  File(block.content),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Center(child: Text('No photo')),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick Photo'),
                onPressed: () => _pickImage(idx),
              ),
            ] else if (block.type == BlockType.map) ...[
              if (block.content.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: Platform.isIOS
                      ? amaps.AppleMap(
                          initialCameraPosition:
                              amaps.CameraPosition(
                            target: _toAMapLatLng(
                                block.content),
                            zoom: 14,
                          ),
                          annotations: {
                            amaps.Annotation(
                              annotationId:
                                  amaps.AnnotationId('$idx'),
                              position:
                                  _toAMapLatLng(block.content),
                            )
                          },
                          onTap: (_) => _pickLocation(idx),
                        )
                      : gmaps.GoogleMap(
                          initialCameraPosition:
                              gmaps.CameraPosition(
                            target: _toGMapLatLng(
                                block.content),
                            zoom: 14,
                          ),
                          markers: {
                            gmaps.Marker(
                              markerId:
                                  gmaps.MarkerId('$idx'),
                              position:
                                  _toGMapLatLng(block.content),
                            )
                          },
                          onTap: (_) => _pickLocation(idx),
                        ),
                )
              else
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Center(child: Text('No location')),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Pick Location'),
                onPressed: () => _pickLocation(idx),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// === EDIT PANE ===
  Widget _editPane() {
    // Pull out the current day group & its blocks
    final todayGroup = _days[_selectedDay];
    final todayBlocks = todayGroup.blocks;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Trip Metadata ─────────────────────────────
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: 'Name your trip',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagInputController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: 'Add tag',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add_circle,
                      color: Theme.of(context).primaryColor),
                  onPressed: _addTag,
                ),
              ),
              onSubmitted: (_) => _addTag(),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              title: Text('Public', style: GoogleFonts.poppins()),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            // ─── Day Tabs ────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < _days.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Day ${i + 1}'),
                        selected: _selectedDay == i,
                        onSelected: (_) => setState(() => _selectedDay = i),
                      ),
                    ),

                  // + new day
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() {
                      final prevDate = _days.isNotEmpty ? _days.last.date : DateTime.now();

                      final newDate = prevDate.add(const Duration(days: 1));
                      _days.add(DayGroupEditorModel(
                        date: newDate,
                        blocks: [],
                      ));
                      _selectedDay = _days.length - 1;
                    }),
                  ),

                  // – remove day
                  if (_days.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() {
                        _days.removeAt(_selectedDay);
                        _selectedDay =
                            (_selectedDay - 1).clamp(0, _days.length - 1);
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Date Picker ──────────────────────────────
            TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                todayGroup.date.toIso8601String().substring(0, 10),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: todayGroup.date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => todayGroup.date = picked);
                }
              },
            ),
            const SizedBox(height: 24),

            // ─── Blocks for this day ──────────────────────
            Text('Blocks', style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(height: 8),
            ...todayBlocks
                .asMap()
                .entries
                .map((e) => _blockEditor(e.key, e.value))
                .toList(),

            // ─── Add-Block Buttons ─────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Text Block'),
                    onPressed: () => setState(() =>
                        todayGroup.blocks
                            .add(ItineraryBlockEditorModel(type: BlockType.text))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Image Block'),
                    onPressed: () => setState(() =>
                        todayGroup.blocks
                            .add(ItineraryBlockEditorModel(type: BlockType.image))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Map Block'),
                    onPressed: () => setState(() =>
                        todayGroup.blocks
                            .add(ItineraryBlockEditorModel(type: BlockType.map))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// === PREVIEW PANE ===
  Widget _previewPane() {
    final todayGroup = _days[_selectedDay];
    final todayDate = todayGroup.date;
    final todayBlocks = todayGroup.blocks;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Trip metadata —
          Text(
            _titleController.text.isEmpty
                ? 'Title'
                : _titleController.text,
            style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isEmpty
                ? 'Description'
                : _descriptionController.text,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: _tags.map((t) => Chip(label: Text(t))).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // — Day tabs for preview —
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _days.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('Day ${i + 1}'),
                      selected: _selectedDay == i,
                      onSelected: (_) => setState(() => _selectedDay = i),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 8),

          // — Day’s date —
          TextButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              todayDate.toIso8601String().substring(0, 10),
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: todayDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => todayGroup.date = picked);
              }
            },
          ),
          const SizedBox(height: 16),

          // — Blocks for this day —
          for (var b in todayBlocks) ...[
            if (b.type == BlockType.text)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  b.content.isEmpty ? '<text>' : b.content,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              )
            else if (b.type == BlockType.image)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: b.content.startsWith('http')
                        ? Image.network(b.content)
                        : (b.content.isNotEmpty && File(b.content).existsSync())
                            ? Image.file(File(b.content))
                          : Container(
                              height: 150,
                              color: Colors.grey.shade200,
                              child: const Center(child: Text('No photo selected')),
                        ),
              )
            else if (b.type == BlockType.map) ...[
              if (b.content.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(child: Text('No location selected')),
                  ),
                )
              else ...[
                // parse coords
                () {
                  final parts = b.content.split(',');
                  final lat = double.tryParse(parts[0]);
                  final lng = parts.length > 1 ? double.tryParse(parts[1]) : null;
                  if (lat == null || lng == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Invalid location: ${b.content}',
                          style: GoogleFonts.poppins(color: Colors.red)),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 150,
                      child: Platform.isIOS
                          ? amaps.AppleMap(
                              initialCameraPosition: amaps.CameraPosition(
                                target: amaps.LatLng(lat, lng),
                                zoom: 14,
                              ),
                              annotations: {
                                amaps.Annotation(
                                  annotationId: amaps.AnnotationId('${b.hashCode}'),
                                  position: amaps.LatLng(lat, lng),
                                )
                              },
                            )
                          : gmaps.GoogleMap(
                              initialCameraPosition: gmaps.CameraPosition(
                                target: gmaps.LatLng(lat, lng),
                                zoom: 14,
                              ),
                              markers: {
                                gmaps.Marker(
                                  markerId: gmaps.MarkerId('${b.hashCode}'),
                                  position: gmaps.LatLng(lat, lng),
                                )
                              },
                            ),
                    ),
                  );
                }()
              ]
            ]
          ],
        ],
      ),
    );
  }

  /// === SAVE TRIP TO BACKEND ===
  Future<void> _saveTrip() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      // 1) Create the itinerary (auto‐seeds Day 1 on the server)
      final itinId = await ItineraryService.createItinerary(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        tags: _tags,
        creatorId: 1,
      );
      // print('CREATE ITINERARY → id=$itinId');
      // 2.) For each day in the local model, call the day-group API:
      final List<int> createdDayIds = [];
      for(var i = 0; i < _days.length; i++) {
        final day = _days[i];
        final created = await DayGroupService.createDayGroup(itineraryId: itinId, date: day.date, title: null, order: i+ 1);
        // print('CREATE DAY $i → id=${created.id}, date=${day.date}');
        createdDayIds.add(created.id);
      }

      // 3.) Now loop again to post each block under its newly created day:
      for(var dayIndex = 0; dayIndex < _days.length; dayIndex++) {
        final day = _days[dayIndex]; // From the locally saved model
        // Example below to walkthrough the logic:
        // createdDayIds = [ 17, 18, 19 ]
        // _days         = [ Day 1 , Day 2 , Day 3 ]
        final dayGroupId = createdDayIds[dayIndex]; // The DB's ID for that day -> _days[0] = Day 1 -> createdDayIDs[0] = 17
        final blocks = day.blocks; // list of blocks for that day

        for (var i = 0; i < blocks.length; i++) {
          var content = blocks[i].content;

          if(blocks[i].type == BlockType.image && File(content).existsSync()) {
            content = await FileService.uploadImage(File(content));
          }

          // Finally send each block to:
          // POST /itineraries/{itinId}/days/{dayGroupId}/blocks
          await ItineraryService.createBlock(
            itineraryId: itinId,
            dayGroupId: dayGroupId, // Used here on line 764
            order: i + 1,
            type: blocks[i].type == BlockType.text
              ? 'text'
              : blocks[i].type == BlockType.image
                ? 'image'
                : 'map',
            content: content
          );
        //   print(
        //   'CREATE BLOCK → dayGroupId=$dayGroupId, '
        //   'order=${i+1}, type=${blocks[i].type}, '
        //   'content=$content'
        // );
        }
      }

      // 4,) Navigate to detail (or fetch detail and then navigate)
      Navigator.pushReplacementNamed(context, '/detail', arguments: itinId);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }
}