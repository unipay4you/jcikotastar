import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'new_greeting_edit_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:typed_data';

class GreetingCardsScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const GreetingCardsScreen({
    Key? key,
    required this.profileData,
  }) : super(key: key);

  @override
  State<GreetingCardsScreen> createState() => _GreetingCardsScreenState();
}

class _GreetingCardsScreenState extends State<GreetingCardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _birthdayCards = [];
  List<Map<String, dynamic>> _anniversaryCards = [];
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  bool _isUploading = false;

  // Default local greeting cards
  final List<Map<String, dynamic>> _defaultBirthdayCards = [
    {
      'id': '1',
      'title': 'Happy Birthday',
      'image': 'assets/media/Greetings/birthday.png',
      'background_image': 'assets/media/Greetings/pink.png',
      'category': 'birthday',
    },
  ];

  final List<Map<String, dynamic>> _defaultAnniversaryCards = [
    {
      'id': '2',
      'title': 'Happy Anniversary',
      'image': 'assets/media/Greetings/anniversary.png',
      'background_image': 'assets/media/Greetings/pink.png',
      'category': 'anniversary',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGreetingCards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGreetingCards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.get(
        endpoint: 'jks/api/user/greeting-cards/',
        token: token,
      );

      if (response['status'] == 200) {
        final List<dynamic> cards = response['payload'] ?? [];

        // Initialize with default cards
        List<Map<String, dynamic>> birthdayCards = _defaultBirthdayCards;
        List<Map<String, dynamic>> anniversaryCards = _defaultAnniversaryCards;

        if (cards.isNotEmpty) {
          // Filter and map birthday cards
          final apiBirthdayCards = cards
              .where((card) =>
                  card['greeting_image_type'] != null &&
                  card['greeting_image_type'].toString().toLowerCase() ==
                      'birthday')
              .map((card) => {
                    'id': card['id']?.toString(),
                    'title': card['title'] ?? 'Birthday Card',
                    'image': card['greeting_image'] != null &&
                            card['greeting_image'].toString().startsWith('http')
                        ? card['greeting_image']
                        : '${ApiConfig.baseUrl}${card['greeting_image'] ?? ''}',
                    'category': 'birthday',
                    'background_image': card['background_image'] != null &&
                            card['background_image']
                                .toString()
                                .startsWith('http')
                        ? card['background_image']
                        : '${ApiConfig.baseUrl}${card['background_image'] ?? ''}',
                  })
              .toList();

          // Filter and map anniversary cards
          final apiAnniversaryCards = cards
              .where((card) =>
                  card['greeting_image_type'] != null &&
                  card['greeting_image_type'].toString().toLowerCase() ==
                      'anniversary')
              .map((card) => {
                    'id': card['id']?.toString(),
                    'title': card['title'] ?? 'Anniversary Card',
                    'image': card['greeting_image'] != null &&
                            card['greeting_image'].toString().startsWith('http')
                        ? card['greeting_image']
                        : '${ApiConfig.baseUrl}${card['greeting_image'] ?? ''}',
                    'category': 'anniversary',
                    'background_image': card['background_image'] != null &&
                            card['background_image']
                                .toString()
                                .startsWith('http')
                        ? card['background_image']
                        : '${ApiConfig.baseUrl}${card['background_image'] ?? ''}',
                  })
              .toList();

          // Use API cards if available, otherwise keep default cards
          if (apiBirthdayCards.isNotEmpty) {
            birthdayCards = apiBirthdayCards;
          }
          if (apiAnniversaryCards.isNotEmpty) {
            anniversaryCards = apiAnniversaryCards;
          }
        }

        setState(() {
          _birthdayCards = birthdayCards;
          _anniversaryCards = anniversaryCards;
        });

        // Show message if using default cards for any category
        if (mounted) {
          if (birthdayCards == _defaultBirthdayCards) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Using default birthday cards'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          if (anniversaryCards == _defaultAnniversaryCards) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Using default anniversary cards'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to load greeting cards');
      }
    } catch (e) {
      print('Error loading greeting cards: $e');
      // Use default cards on error
      setState(() {
        _birthdayCards = _defaultBirthdayCards;
        _anniversaryCards = _defaultAnniversaryCards;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default greeting cards: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showChangeCardOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change Card',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.poppins(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        // Show preview of selected image
        _showSelectedImagePreview();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadGreetingCard() async {
    if (_selectedImagePath == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }

      // Read image file and convert to base64
      final file = File(_selectedImagePath!);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare request body
      final requestBody = {
        'image': base64Image,
        'greeting_image_type':
            _tabController.index == 0 ? 'Birthday' : 'Anniversary',
      };

      // Print request details
      print('\n=== Greeting Card Upload Request ===');
      print('URL: ${ApiConfig.baseUrl}jks/api/user/greeting-cards/add/');
      print('Method: POST');
      print('Headers: {Authorization: Bearer $token}');
      print('Image Size: ${bytes.length} bytes');
      print('Base64 Length: ${base64Image.length} characters');
      print('Greeting Type: ${requestBody['greeting_image_type']}');
      print('===================================\n');

      // Send the request
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}jks/api/user/greeting-cards/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Print response details
      print('\n=== Greeting Card Upload Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('====================================\n');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Greeting card added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the greeting cards list
          await _loadGreetingCards();
        }
      } else {
        throw Exception('Failed to upload greeting card: ${response.body}');
      }
    } catch (e) {
      print('\n=== Greeting Card Upload Error ===');
      print('Error: $e');
      print('===============================\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading greeting card: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _selectedImagePath = null;
        });
      }
    }
  }

  void _showSelectedImagePreview() {
    if (_selectedImagePath == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 300,
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: FutureBuilder<File>(
                      future: Future.value(File(_selectedImagePath!)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Error loading image',
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 2.0,
                          child: Image.file(
                            snapshot.data!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedImagePath = null;
                        });
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isUploading
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await _uploadGreetingCard();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isUploading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Use This Image',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGreetingCardPreview(Map<String, dynamic> card) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 300,
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: card['image'].toString().startsWith('http')
                          ? NetworkImage(card['image'])
                          : AssetImage(card['image']) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showChangeCardOptions();
                        },
                        child: Text(
                          'Change Card',
                          style: GoogleFonts.poppins(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewGreetingEditScreen(
                                profileData: widget.profileData,
                                cardData: {
                                  'id': card['id'],
                                  'title': card['title'],
                                  'greeting_image': card['image'],
                                  'background_image': card['background_image'],
                                  'greeting_image_type': card['category'],
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Edit Card',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Greeting Cards',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGreetingCards,
            tooltip: 'Refresh Greeting Cards',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              child: Text(
                'Birthday',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Tab(
              child: Text(
                'Anniversary',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Birthday Cards Tab
                _buildCardGrid(_birthdayCards),
                // Anniversary Cards Tab
                _buildCardGrid(_anniversaryCards),
              ],
            ),
    );
  }

  Widget _buildCardGrid(List<Map<String, dynamic>> cards) {
    if (cards.isEmpty) {
      return Center(
        child: Text(
          'No cards available',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return GestureDetector(
          onTap: () => _showGreetingCardPreview(card),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: card['image'].toString().startsWith('http')
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                card['image'],
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        : Image.asset(
                            card['image'],
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    card['title'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
