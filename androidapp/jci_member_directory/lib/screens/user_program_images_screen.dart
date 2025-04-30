import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/program_folder.dart';
import '../services/auth_service.dart';
import 'user_program_image_gallery_screen.dart';

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
                  createdAt: DateTime.now(),
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
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
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
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      folder.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
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
    );
  }
}
