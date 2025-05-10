import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/program_folder.dart';
import '../services/auth_service.dart';
import 'user_program_image_gallery_screen.dart';
import 'dart:convert';

class UserProgramImagesScreen extends StatefulWidget {
  const UserProgramImagesScreen({Key? key}) : super(key: key);

  @override
  _UserProgramImagesScreenState createState() =>
      _UserProgramImagesScreenState();
}

class _UserProgramImagesScreenState extends State<UserProgramImagesScreen> {
  bool _isLoading = false;
  List<ProgramFolder> _folders = [];
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
        print('Total items in payload: ${response['payload'].length}');

        // Group images by program name
        final Map<String, List<Map<String, dynamic>>> programGroups = {};

        // First, let's print all unique program names
        print('\nAll Program Names in Response:');
        final allProgramNames = response['payload']
            .map((item) => item['ProgramName']['programName'])
            .toSet()
            .toList();
        print('Total unique programs: ${allProgramNames.length}');
        allProgramNames.forEach((name) => print('- $name'));

        for (var item in response['payload']) {
          final programName = item['ProgramName']['programName'];
          if (!programGroups.containsKey(programName)) {
            programGroups[programName] = [];
          }
          programGroups[programName]!.add(item);
        }

        print('\nGrouped Programs Details:');
        programGroups.forEach((name, items) {
          print('\nProgram: $name');
          print('Number of images: ${items.length}');
          print('Program ID: ${items[0]['ProgramName']['id']}');
          print('Program Image: ${items[0]['ProgramName']['prog_image']}');
        });

        setState(() {
          _folders = programGroups.entries.map((entry) {
            final programData = entry.value[0]['ProgramName'];
            return ProgramFolder(
              id: programData['id'].toString(),
              name: entry.key,
              programImage: programData['prog_image'],
              images: entry.value.map((image) {
                return ProgramImage(
                  id: image['id'].toString(),
                  url: image['image'],
                  programId: programData['id'].toString(),
                  createdAt: DateTime.now(),
                );
              }).toList(),
            );
          }).toList();
        });

        print('\nFinal Folders List:');
        print('Total folders created: ${_folders.length}');
        _folders.forEach((folder) {
          print('\nFolder: ${folder.name}');
          print('ID: ${folder.id}');
          print('Program Image: ${folder.programImage}');
          print('Number of images: ${folder.images.length}');
        });

        // Verify if any folders were filtered out
        if (_folders.length != programGroups.length) {
          print('\nWARNING: Some folders may have been filtered out!');
          print('Program groups count: ${programGroups.length}');
          print('Final folders count: ${_folders.length}');
        }
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
          'Program Gallery',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: null,
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
                            print(
                                'Building folder item: ${folder.name} at index $index');
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
                                          UserProgramImageGalleryScreen(
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
