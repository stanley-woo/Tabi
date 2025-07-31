import 'dart:ui';                // for ImageFilter
import 'dart:io';                // for File & Platform
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import 'package:image_picker/image_picker.dart';

import '../screens/map_picker_screen.dart';
import '../services/file_service.dart';
import '../services/itinerary_service.dart';
import 'day_group_screen.dart';

enum BlockType { text, image, map }

class ItineraryBlockEditorModel {
  BlockType type;
  String content;
  ItineraryBlockEditorModel({required this.type, this.content = ''});
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
  final List<ItineraryBlockEditorModel> _blocks = [];

  List<DateTime> _dayDates = [DateTime.now()];
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

  // helpers to convert our “lat,lng” string to map‐plugin LatLngs
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
    final result =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() {
        _blocks[idx].content = result.path;
      });
    }
  }

  Future<void> _pickLocation(int idx) async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _blocks[idx].content =
            '${result.latitude},${result.longitude}';
      });
    }
  }

  void _addTag() {
    final text = _tagInputController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() => _tags.add(text));
      _tagInputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
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
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
        body: Stack(
          children: [
            // white “sheet” container
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

  // /// === EDIT PANE ===
  // Widget _editPane() {
  //   return Form(
  //     key: _formKey,
  //     child: SingleChildScrollView(
  //       padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // title
  //           TextFormField(
  //             controller: _titleController,
  //             decoration: InputDecoration(
  //               filled: true,
  //               fillColor: Colors.grey[200],
  //               hintText: 'Name your trip',
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(16),
  //                 borderSide: BorderSide.none,
  //               ),
  //             ),
  //             validator: (v) =>
  //                 (v == null || v.isEmpty) ? 'Enter name' : null,
  //           ),
  //           const SizedBox(height: 16),

  //           // description
  //           TextFormField(
  //             controller: _descriptionController,
  //             decoration: InputDecoration(
  //               filled: true,
  //               fillColor: Colors.grey[200],
  //               hintText: 'Description',
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(16),
  //                 borderSide: BorderSide.none,
  //               ),
  //             ),
  //             maxLines: 3,
  //           ),
  //           const SizedBox(height: 16),

  //           // Blocks label + existing editors
  //           Text('Blocks',
  //               style: GoogleFonts.poppins(fontSize: 16)),
  //           const SizedBox(height: 8),
  //           ..._blocks
  //               .asMap()
  //               .entries
  //               .map((e) => _blockEditor(e.key, e.value)),

  //           // add‐block buttons
  //           SingleChildScrollView(
  //             scrollDirection: Axis.horizontal,
  //             padding: const EdgeInsets.symmetric(vertical: 8),
  //             child: Row(
  //               children: [
  //                 ElevatedButton.icon(
  //                   icon: const Icon(Icons.text_fields),
  //                   label: const Text('Text Block'),
  //                   onPressed: () => setState(() => _blocks.add(
  //                       ItineraryBlockEditorModel(
  //                           type: BlockType.text))),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 ElevatedButton.icon(
  //                   icon: const Icon(Icons.image),
  //                   label: const Text('Image Block'),
  //                   onPressed: () => setState(() => _blocks.add(
  //                       ItineraryBlockEditorModel(
  //                           type: BlockType.image))),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 ElevatedButton.icon(
  //                   icon: const Icon(Icons.map),
  //                   label: const Text('Map Block'),
  //                   onPressed: () => setState(() => _blocks.add(
  //                       ItineraryBlockEditorModel(
  //                           type: BlockType.map))),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(height: 16),

  //           // Tags
  //           Text('Tags',
  //               style: GoogleFonts.poppins(fontSize: 16)),
  //           const SizedBox(height: 8),
  //           Wrap(
  //             spacing: 8,
  //             runSpacing: 4,
  //             children: _tags
  //                 .map((tag) => Chip(
  //                       label: Text(tag),
  //                       backgroundColor: Colors.grey[200],
  //                       onDeleted: () =>
  //                           setState(() => _tags.remove(tag)),
  //                     ))
  //                 .toList(),
  //           ),
  //           const SizedBox(height: 8),
  //           TextField(
  //             controller: _tagInputController,
  //             decoration: InputDecoration(
  //               filled: true,
  //               fillColor: Colors.grey[200],
  //               hintText: 'Add tag',
  //               border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(16),
  //                   borderSide: BorderSide.none),
  //               contentPadding:
  //                   const EdgeInsets.symmetric(horizontal: 16),
  //               suffixIcon: IconButton(
  //                 icon: Icon(Icons.add_circle,
  //                     color: Theme.of(context).primaryColor),
  //                 onPressed: _addTag,
  //               ),
  //             ),
  //             onSubmitted: (_) => _addTag(),
  //           ),
  //           const SizedBox(height: 16),

  //           // Visibility
  //           SwitchListTile.adaptive(
  //             title: Text('Public',
  //                 style: GoogleFonts.poppins()),
  //             value: _isPublic,
  //             onChanged: (v) => setState(() => _isPublic = v),
  //             contentPadding: EdgeInsets.zero,
  //             activeColor:
  //                 Theme.of(context).colorScheme.secondary,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  /// === EDIT PANE ===
  Widget _editPane() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Day Tabs ───────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Render one chip per day
                  for (var i = 0; i < _dayDates.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Day ${i+1}'),
                        selected: _selectedDay == i,
                        onSelected: (_) => setState(() => _selectedDay = i),
                      ),
                    ),

                  // + button
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() {
                        _dayDates.add(DateTime.now());
                        _selectedDay = _dayDates.length - 1;
                      });
                    },
                  ),

                  // – button (only if more than one day)
                  if (_dayDates.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          _dayDates.removeAt(_selectedDay);
                          _selectedDay = (_selectedDay - 1).clamp(0, _dayDates.length - 1);
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Day Date Picker ────────────────────────
            TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _dayDates[_selectedDay]
                    .toLocal()
                    .toIso8601String()
                    .substring(0, 10),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dayDates[_selectedDay],
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _dayDates[_selectedDay] = picked);
                }
              },
            ),
            const SizedBox(height: 24),

            // ─── Trip Title & Description ───────────────
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
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter name' : null,
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

            // ─── Blocks Label & Editors ─────────────────
            Text('Blocks', style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(height: 8),
            ..._blocks
                .asMap()
                .entries
                .map((e) => _blockEditor(e.key, e.value))
                .toList(),

            // ─── Add-Block Buttons ───────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Text Block'),
                    onPressed: () => setState(() =>
                        _blocks.add(ItineraryBlockEditorModel(type: BlockType.text))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Image Block'),
                    onPressed: () => setState(() =>
                        _blocks.add(ItineraryBlockEditorModel(type: BlockType.image))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Map Block'),
                    onPressed: () => setState(() =>
                        _blocks.add(ItineraryBlockEditorModel(type: BlockType.map))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Tags ────────────────────────────────────
            Text('Tags', style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.grey[200],
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add_circle,
                      color: Theme.of(context).primaryColor),
                  onPressed: _addTag,
                ),
              ),
              onSubmitted: (_) => _addTag(),
            ),
            const SizedBox(height: 16),

            // ─── Visibility ──────────────────────────────
            SwitchListTile.adaptive(
              title: Text('Public', style: GoogleFonts.poppins()),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              contentPadding: EdgeInsets.zero,
              activeColor: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  /// === PREVIEW PANE ===
  Widget _previewPane() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Text(
            _titleController.text.isEmpty
                ? 'Title'
                : _titleController.text,
            style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // description
          Text(
            _descriptionController.text.isEmpty
                ? 'Description'
                : _descriptionController.text,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          const SizedBox(height: 16),

          // tags
          if (_tags.isNotEmpty) ...[
            Wrap(
                spacing: 8,
                children:
                    _tags.map((t) => Chip(label: Text(t))).toList()),
            const SizedBox(height: 16),
          ],

          // blocks
          ..._blocks.map((b) {
            switch (b.type) {
              case BlockType.text:
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    b.content.isEmpty ? '<text>' : b.content,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                );

              case BlockType.image:
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: b.content.startsWith('http')
                      ? Image.network(b.content)
                      : Image.file(File(b.content)),
                );

              case BlockType.map:
                if (b.content.isEmpty) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(
                          child:
                              Text('No location selected')),
                    ),
                  );
                }
                final parts = b.content.split(',');
                final lat = double.tryParse(parts[0]);
                final lng =
                    parts.length > 1 ? double.tryParse(parts[1]) : null;
                if (lat == null || lng == null) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                        'Invalid location: ${b.content}'),
                  );
                }
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 150,
                    child: Platform.isIOS
                        ? amaps.AppleMap(
                            initialCameraPosition:
                                amaps.CameraPosition(
                              target: amaps.LatLng(lat, lng),
                              zoom: 14,
                            ),
                            annotations: {
                              amaps.Annotation(
                                annotationId: amaps.AnnotationId(
                                    '${b.hashCode}'),
                                position:
                                    amaps.LatLng(lat, lng),
                              )
                            },
                          )
                        : gmaps.GoogleMap(
                            initialCameraPosition:
                                gmaps.CameraPosition(
                              target:
                                  gmaps.LatLng(lat, lng),
                              zoom: 14,
                            ),
                            markers: {
                              gmaps.Marker(
                                markerId:
                                    gmaps.MarkerId('${b.hashCode}'),
                                position:
                                    gmaps.LatLng(lat, lng),
                              )
                            },
                          ),
                  ),
                );

              default:
                return const SizedBox.shrink();
            }
          }).toList(),
        ],
      ),
    );
  }

  /// === BLOCK EDITOR ===
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
                  onPressed: () =>
                      setState(() => _blocks.removeAt(idx)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // TEXT
            if (block.type == BlockType.text) ...[
              TextFormField(
                initialValue: block.content,
                decoration: InputDecoration(
                  hintText: 'Enter text',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => block.content = v,
              ),

            // IMAGE
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
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: const Center(
                      child: Text('No photo selected')),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick Photo'),
                onPressed: () => _pickImage(idx),
              ),

            // MAP
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
                              position: _toAMapLatLng(
                                  block.content),
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
                              position: _toGMapLatLng(
                                  block.content),
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
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: const Center(
                      child:
                          Text('No location selected')),
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

  Future<void> _saveTrip() async {
    if (!(_formKey.currentState?.validate() ?? false))
      return;

    try {
      final itinId = await ItineraryService
          .createItinerary(
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim(),
        isPublic: _isPublic,
        tags: _tags,
        creatorId: 1,
      );

      for (var i = 0; i < _blocks.length; i++) {
        final block = _blocks[i];
        var content = block.content;

        if (block.type == BlockType.image &&
            File(content).existsSync()) {
          content = await FileService.uploadImage(
              File(content));
        }

        await ItineraryService.createBlock(
          itineraryId: itinId,
          order: i + 1,
          type: block.type == BlockType.text
              ? 'text'
              : block.type == BlockType.image
                  ? 'image'
                  : 'map',
          content: content,
        );
      }

      Navigator.pushReplacementNamed(
        context,
        '/detail',
        arguments: itinId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }
}