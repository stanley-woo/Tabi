import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_store.dart';
import '../services/profile_service.dart';
import '../services/image_upload_service.dart';
import '../widgets/image_ref.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _loading = false;
  String? _error;
  
  // Image state
  String? _currentAvatarUrl;
  String? _currentHeaderUrl;
  String? _newAvatarUrl;
  String? _newHeaderUrl;
  bool _uploadingAvatar = false;
  bool _uploadingHeader = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final auth = context.read<AuthStore>();
    if (auth.username == null) return;

    try {
      final profile = await ProfileService.fetchProfile(auth.username!);
      setState(() {
        _displayNameController.text = profile['display_name'] as String? ?? '';
        _bioController.text = profile['bio'] as String? ?? '';
        _currentAvatarUrl = profile['avatar_url'] as String?;
        _currentHeaderUrl = profile['header_url'] as String?;
      });
    } catch (e) {
      setState(() => _error = 'Failed to load profile');
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final source = await ImageUploadService.showImageSourceDialog(context);
      if (source == null) return;

      setState(() => _uploadingAvatar = true);

      final imageUrl = await ImageUploadService.pickAndUploadImage(source: source);
      if (imageUrl != null) {
        setState(() => _newAvatarUrl = imageUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _pickAndUploadHeader() async {
    try {
      final source = await ImageUploadService.showImageSourceDialog(context);
      if (source == null) return;

      setState(() => _uploadingHeader = true);

      final imageUrl = await ImageUploadService.pickAndUploadImage(source: source);
      if (imageUrl != null) {
        setState(() => _newHeaderUrl = imageUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload header: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingHeader = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthStore>();
      if (auth.username == null) {
        throw Exception('Not logged in');
      }


      await ProfileService.updateProfile(
        auth.username!,
        displayName: _displayNameController.text.trim().isEmpty 
            ? null 
            : _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty 
            ? null 
            : _bioController.text.trim(),
        avatarName: _newAvatarUrl,
        headerUrl: _newHeaderUrl,
      );

      if (mounted) {
        // Update current URLs with the new values
        setState(() {
          if (_newAvatarUrl != null) {
            _currentAvatarUrl = _newAvatarUrl;
            _newAvatarUrl = null;
          }
          if (_newHeaderUrl != null) {
            _currentHeaderUrl = _newHeaderUrl;
            _newHeaderUrl = null;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = 'Failed to update profile: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveProfile,
            child: _loading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],

              // Header Image Section
              _buildImageSection(
                title: 'Header Image',
                currentUrl: _currentHeaderUrl,
                newUrl: _newHeaderUrl,
                isUploading: _uploadingHeader,
                onTap: _pickAndUploadHeader,
                aspectRatio: 16 / 9,
              ),

              const SizedBox(height: 24),

              // Avatar Image Section
              _buildImageSection(
                title: 'Profile Picture',
                currentUrl: _currentAvatarUrl,
                newUrl: _newAvatarUrl,
                isUploading: _uploadingAvatar,
                onTap: _pickAndUploadAvatar,
                aspectRatio: 1,
                isCircular: true,
              ),

              const SizedBox(height: 24),

              // Display Name
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your display name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.trim().length > 50) {
                    return 'Display name must be 50 characters or less';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about yourself',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 200,
                validator: (value) {
                  if (value != null && value.trim().length > 200) {
                    return 'Bio must be 200 characters or less';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required String? currentUrl,
    required String? newUrl,
    required bool isUploading,
    required VoidCallback onTap,
    required double aspectRatio,
    bool isCircular = false,
  }) {
    final displayUrl = newUrl ?? currentUrl;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isUploading ? null : onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: isCircular 
                  ? BorderRadius.circular(60) 
                  : BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: ClipRRect(
              borderRadius: isCircular 
                  ? BorderRadius.circular(60) 
                  : BorderRadius.circular(10),
              child: displayUrl != null
                  ? imageFromRef(
                      displayUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCircular ? Icons.person : Icons.image,
                          size: 32,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isUploading ? 'Uploading...' : 'Tap to add $title',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (isUploading) ...[
          const SizedBox(height: 8),
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
        if (newUrl != null) ...[
          const SizedBox(height: 8),
          Text(
            'New $title selected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}
