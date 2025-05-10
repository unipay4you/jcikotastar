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
import 'dart:convert';

class ProgramImagesScreen extends StatefulWidget {
  const ProgramImagesScreen({Key? key}) : super(key: key);

  @override
  _ProgramImagesScreenState createState() => _ProgramImagesScreenState();
}

class _ProgramImagesScreenState extends State<ProgramImagesScreen> {
  bool _isLoading = false;
  List<ProgramFolder> _folders = [];
  int _selectedYear = DateTime.now().year;
  late List<int> _years;
  final _formKey = GlobalKey<FormState>();
  final _programNameController = TextEditingController();
  final _programDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _years = List.generate(
      DateTime.now().year - 2019,
      (index) => 2020 + index,
    ).reversed.toList();
    _loadFolders();
  }

  @override
  void dispose() {
    _programNameController.dispose();
    _programDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _showNewFolderDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Create New Program Folder',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _programNameController,
                    decoration: InputDecoration(
                      labelText: 'Program Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter program name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _programDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Program Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter program description';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  await _createNewFolder();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Create',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewFolder() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await AuthService.getAccessToken();
      final response = await ApiService.post(
        endpoint: 'api/admin/programs/create/',
        body: {
          'programName': _programNameController.text,
          'programDescription': _programDescriptionController.text,
          'year': _selectedYear,
        },
        token: token,
      );

      if (response['status'] == 200) {
        // Clear the form
        _programNameController.clear();
        _programDescriptionController.clear();

        // Reload folders
        await _loadFolders();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Program folder created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response['message'] ?? 'Failed to create program folder'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating program folder: ${e.toString()}'),
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

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== Loading Program Folders for Year $_selectedYear ===');
      final token = await AuthService.getAccessToken();
      final response = await ApiService.post(
        endpoint: ApiConfig.programImages,
        body: {'year': _selectedYear},
        token: token,
      );

      print('API Response Status: ${response['status']}');
      print('Raw Response: ${json.encode(response)}');

      if (response['status'] == 200) {
        print('\nProcessing API Response:');

        // Get programs from the root level
        final List<dynamic> programs = response['programs'] ?? [];
        print('Total programs: ${programs.length}');

        // Get all images from payload
        final List<dynamic> allImages = response['payload'] ?? [];
        print('Total images: ${allImages.length}');

        // Create a map to store program images using both name and ID as key
        final Map<String, List<Map<String, dynamic>>> programImages = {};

        // First, initialize the map with all programs
        for (var program in programs) {
          final programName = program['programName'];
          final programId = program['id'].toString();
          // Create a unique key combining name and ID
          final uniqueKey = '$programName-$programId';
          programImages[uniqueKey] = [];
          print('Initialized program: $programName (ID: $programId)');
        }

        // Then, assign images to their respective programs
        for (var image in allImages) {
          final programName = image['ProgramName']['programName'];
          final programId = image['ProgramName']['id'].toString();
          // Use the same unique key format
          final uniqueKey = '$programName-$programId';
          if (programImages.containsKey(uniqueKey)) {
            programImages[uniqueKey]!.add(image);
          }
        }

        print('\nProgram Images Distribution:');
        programImages.forEach((key, images) {
          final parts = key.split('-');
          final name = parts[0];
          final id = parts[1];
          print('Program: $name (ID: $id)');
          print('Number of images: ${images.length}');
        });

        // Sort programs by expiry date in descending order
        programs.sort((a, b) {
          final DateTime? endDateA = a['prog_expire_date'] != null
              ? DateTime.parse(a['prog_expire_date'])
              : null;
          final DateTime? endDateB = b['prog_expire_date'] != null
              ? DateTime.parse(b['prog_expire_date'])
              : null;

          // Handle null dates by putting them at the end
          if (endDateA == null && endDateB == null) return 0;
          if (endDateA == null) return 1;
          if (endDateB == null) return -1;

          // Reverse the comparison for descending order
          return endDateB.compareTo(endDateA);
        });

        setState(() {
          _folders = programs.map((program) {
            final programName = program['programName'];
            final programId = program['id'].toString();
            final programImage = program['prog_image'];
            final uniqueKey = '$programName-$programId';
            final images = programImages[uniqueKey] ?? [];
            final endDate = program['prog_expire_date'] != null
                ? DateTime.parse(program['prog_expire_date'])
                : null;

            print('\nCreating folder for: $programName (ID: $programId)');
            print('Program Image: $programImage');
            print(
                'Expiry Date: ${endDate?.toIso8601String() ?? 'No expiry date'}');
            print('Number of images: ${images.length}');

            return ProgramFolder(
              id: programId,
              name: programName,
              programImage: programImage,
              images: images.map((image) {
                return ProgramImage(
                  id: image['id'].toString(),
                  url: image['image'],
                  programId: programId,
                  createdAt: DateTime.now(),
                );
              }).toList(),
            );
          }).toList();
        });

        print('\nFinal Folders List (Sorted by End Date):');
        print('Total folders created: ${_folders.length}');
        _folders.forEach((folder) {
          print('\nFolder: ${folder.name} (ID: ${folder.id})');
          print('Program Image: ${folder.programImage}');
          print('Number of images: ${folder.images.length}');
        });
      } else {
        print('\nError Response:');
        print('Message: ${response['message']}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load folders'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('\nException occurred:');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
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
      print('\n=== Program Folders Loading Completed ===\n');
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
            icon: const Icon(Icons.add),
            tooltip: 'Create New Program',
            onPressed: _showNewFolderDialog,
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
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _folders.length,
                          itemBuilder: (context, index) {
                            final folder = _folders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProgramImageGalleryScreen(
                                        folder: folder,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Program Image
                                      Container(
                                        width: 160,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: folder.programImage != null &&
                                                  folder
                                                      .programImage!.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: folder.programImage!
                                                          .startsWith('http')
                                                      ? folder.programImage!
                                                      : '${ApiConfig.baseUrl}${folder.programImage!.startsWith('/') ? folder.programImage!.substring(1) : folder.programImage!}',
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Theme.of(context)
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) {
                                                    print(
                                                        'Error loading program image: $error');
                                                    print(
                                                        'Program Image URL: ${folder.programImage}');
                                                    return _buildPlaceholderImage();
                                                  },
                                                )
                                              : _buildPlaceholderImage(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Program Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              folder.name,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.photo_library,
                                                    size: 16,
                                                    color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${folder.images.length} images',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
