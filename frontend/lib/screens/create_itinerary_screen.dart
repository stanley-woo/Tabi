import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/file_service.dart';
import '../services/itinerary_service.dart';


enum BlockType { text, image }

class ItineraryBlockEditorModel {
  BlockType type;
  String content;
  ItineraryBlockEditorModel({required this.type, this.content = ''});
}


/// A create-itinerary UI with a glassy header, tabs, and live preview.
class CreateItineraryScreen extends StatefulWidget {
  const CreateItineraryScreen({Key? key}) : super(key: key);
  @override
  State<CreateItineraryScreen> createState() => _CreateItineraryScreenState();
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

  Future<void> _pickImage(int index) async {
  final result = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (result != null) {
    setState(() {
      _blocks[index].content = result.path; 
      // temporarily hold local file path
    });
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
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text('Customize', style: TextStyle(color: Colors.white)),
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
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
        body: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [Tab(text: 'Edit'), Tab(text: 'Preview')],
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
            Positioned(
              left: 16, right: 16, bottom: 24,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _saveTrip();
                  }
                },
                child: const Text('Create Trip', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editPane() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: 'Name your trip',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none,
                ),
              ),
              validator: (v) => (v==null||v.isEmpty)?'Enter name':null,
            ),
            const SizedBox(height: 16),
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none,
                ),
              ), maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Blocks editor
            Text('Blocks', style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(height: 8),
            ..._blocks.asMap().entries.map((e) => _blockEditor(e.key,e.value)),
            Row(children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.text_fields), label: const Text('Text Block'),
                onPressed: ()=>setState(()=>_blocks.add(ItineraryBlockEditorModel(type: BlockType.text))),
              ),
              const SizedBox(width:8),
              ElevatedButton.icon(
                icon: const Icon(Icons.image), label: const Text('Image Block'),
                onPressed: ()=>setState(()=>_blocks.add(ItineraryBlockEditorModel(type: BlockType.image))),
              ),
            ]),
            const SizedBox(height:16),
            // Tags as glass chips
            Text('Tags', style: GoogleFonts.poppins(fontSize: 16)),
            const SizedBox(height:8),
            Wrap(
              spacing:8,
              children: _tags.map((tag) =>
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX:10,sigmaY:10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal:12,vertical:6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tag, style: const TextStyle(color:Colors.white)),
                          const SizedBox(width:4),
                          GestureDetector(
                            onTap:()=>setState(()=>_tags.remove(tag)),
                            child: const Icon(Icons.close,size:16,color:Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                )).toList()
            ),
            Row(
              children:[
                Expanded(
                  child: TextField(
                    controller:_tagInputController,
                    decoration: const InputDecoration(hintText:'Add tag'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed:(){
                    final t=_tagInputController.text.trim();
                    if(t.isNotEmpty) setState((){_tags.add(t);_tagInputController.clear();});
                  },
                ),
              ]
            ),
            const SizedBox(height:16),
            // Public toggle moved here
            SwitchListTile(
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
              title: const Text('Public'),
              value:_isPublic,
              onChanged:(v)=>setState(()=>_isPublic=v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewPane() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleController.text.isEmpty?'Title':_titleController.text,
            style: GoogleFonts.poppins(fontSize:24,fontWeight: FontWeight.bold),
          ),
          const SizedBox(height:8),
          Text(
            _descriptionController.text.isEmpty?'Description':_descriptionController.text,
            style:GoogleFonts.poppins(fontSize:16),
          ),
          const SizedBox(height:16),
          Wrap(spacing:8,children:_tags.map((t)=>Chip(label:Text(t))).toList()),
          const SizedBox(height:16),
          ..._blocks.map((b)=>Padding(
            padding: const EdgeInsets.symmetric(vertical:8),
            child: b.type==BlockType.text
              ?Text(b.content.isEmpty?'<text>':b.content,style:GoogleFonts.poppins(fontSize:14))
              :b.content.isEmpty
                ?Container(height:150,color:Colors.grey[300],child:const Center(child:Text('Image URL')))
                :Image.network(b.content),
          )),
        ],
      ),
    );
  }

  Widget _blockEditor(int idx, ItineraryBlockEditorModel block) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DropdownButton<BlockType>(
                  value: block.type,
                  items: BlockType.values.map((bt) {
                    return DropdownMenuItem(
                      value: bt,
                      child: Text(bt == BlockType.text ? 'Text' : 'Image'),
                    );
                  }).toList(),
                  onChanged: (bt) => setState(() => block.type = bt!),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => setState(() => _blocks.removeAt(idx)),
                ),
              ],
            ),

            // If it's a text block, show the text field
            if (block.type == BlockType.text) ...[
              TextFormField(
                initialValue: block.content,
                decoration: const InputDecoration(
                  hintText: 'Enter text',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => block.content = v,
              ),
            ] else ...[
              // Image block: show preview if we have one
              if (block.content.isNotEmpty) 
                Image.file(
                  File(block.content),
                  height: 150, width: double.infinity, fit: BoxFit.cover,
                )
              else
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('No photo selected')),
                ),

              const SizedBox(height: 8),
              // Button to pick/replace photo
              TextButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick Photo'),
                onPressed: () => _pickImage(idx),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveTrip() async {
    if(!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final itinId = await ItineraryService.createItinerary(
        title: _titleController.text.trim(), 
        description: _descriptionController.text.trim(), 
        isPublic: _isPublic, 
        tags: _tags, 
        creatorId: 1
      );

      for(var i = 0; i < _blocks.length; i++) {
        final block = _blocks[i];
        String content = block.content;

        if(block.type == BlockType.image && File(content).existsSync()) {
          content = await FileService.uploadImage(File(content));
        }

        await ItineraryService.createBlock(
          itineraryId: itinId, 
          order: i + 1, 
          type: block.type == BlockType.text ? 'text' : 'image', 
          content: content
        );
      }

      Navigator.pushReplacementNamed(context, '/detail', arguments: itinId);
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved failed: $e'))
      );
    }
  }
}
