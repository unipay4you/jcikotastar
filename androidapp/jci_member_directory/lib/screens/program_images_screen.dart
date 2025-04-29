import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/program_folder.dart';
import '../services/auth_service.dart';
import 'program_image_gallery_screen.dart';

class ProgramImagesScreen extends StatefulWidget {
  const ProgramImagesScreen({Key? key}) : super(key: key);

  @override
  _ProgramImagesScreenState createState() => _ProgramImagesScreenState();
}

class _ProgramImagesScreenState extends State<ProgramImagesScreen> {
  bool _isLoading = false;
  List<ProgramFolder> _folders = [];
  ProgramFolder? _selectedFolder;
  final ImagePicker _picker = ImagePicker();
  int _selectedYear = DateTime.now().year;
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    _years = List.generate(
      DateTime.now().year - 2019,
      (index) => 2020 + index,
    ).reversed.toList();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getAccessToken();
      final response = await ApiService.post(
        endpoint: ApiConfig.programImages,
        body: {'year': _selectedYear},
        token: token,
      );

      if (response['status'] == 200) {
        // Group images by program name
        final Map<String, List<Map<String, dynamic>>> programGroups = {};

        for (var item in response['payload']) {
          final programName = item['ProgramName']['programName'];
          if (!programGroups.containsKey(programName)) {
            programGroups[programName] = [];
          }
          programGroups[programName]!.add(item);
        }

        setState(() {
          _folders = programGroups.entries.map((entry) {
            return ProgramFolder(
              id: entry.value[0]['ProgramName']['id'].toString(),
              name: entry.key,
              images: entry.value.map((image) {
                return ProgramImage(
                  id: image['id'].toString(),
                  url: image['image'],
                  programId: image['ProgramName']['id'].toString(),
                  createdAt:
                      DateTime.now(), // Since createdAt is not in response
                );
              }).toList(),
            );
          }).toList();
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load folders'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading folders: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewFolder() async {
    final TextEditingController nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create New Program Folder',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Program Name',
            hintText: 'Enter program name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _folders.add(
          ProgramFolder(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: result,
            images: [],
          ),
        );
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedFolder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a program folder first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return;

      setState(() {
        _isLoading = true;
      });

      for (final image in images) {
        final File imageFile = File(image.path);
        final response = await ApiService.uploadImage(
          endpoint: '${ApiConfig.uploadProgramImage}/${_selectedFolder!.id}',
          imageFile: imageFile,
        );

        if (response['status'] != 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to upload image'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        }
      }

      await _loadFolders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Images uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteImage(String imageId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await ApiService.delete(
        endpoint: '${ApiConfig.programImages}/image/$imageId',
      );

      if (response['status'] == 200) {
        await _loadFolders();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to delete image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Program Images',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _createNewFolder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        items: _years.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedYear = value;
                            });
                            _loadFolders();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _folders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No program folders found',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _createNewFolder,
                                icon: const Icon(Icons.create_new_folder),
                                label: const Text('Create New Program'),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _folders.length,
                          itemBuilder: (context, index) {
                            final folder = _folders[index];
                            return GestureDetector(
                              onTap: () async {
                                // Check if it's a new folder (timestamp-based ID)
                                if (folder.id.length > 10) {
                                  // For new folders, navigate directly
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProgramImageGalleryScreen(
                                        folder: folder,
                                      ),
                                    ),
                                  );
                                } else {
                                  // For existing folders, navigate to gallery screen
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProgramImageGalleryScreen(
                                        folder: folder,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedFolder?.id == folder.id
                                      ? Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedFolder?.id == folder.id
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder,
                                      size: 48,
                                      color: _selectedFolder?.id == folder.id
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      folder.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedFolder?.id == folder.id
                                            ? Theme.of(context).primaryColor
                                            : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${folder.images.length} images',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _selectedFolder != null
          ? FloatingActionButton(
              onPressed: _uploadImages,
              child: const Icon(Icons.add_photo_alternate),
            )
          : null,
    );
  }
}
