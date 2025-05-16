import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class NewGreetingEditScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final Map<String, dynamic>? cardData;

  const NewGreetingEditScreen({
    Key? key,
    required this.profileData,
    this.cardData,
  }) : super(key: key);

  @override
  State<NewGreetingEditScreen> createState() => _NewGreetingEditScreenState();
}

class _NewGreetingEditScreenState extends State<NewGreetingEditScreen> {
  // Card dimensions
  static const double cardWidth = 1240.0;
  static const double cardHeight = 1748.0;
  late double _scaledCardWidth;
  late double _scaledCardHeight;

  // Element positions
  final Map<String, Offset> _elementPositions = {
    'Member Image': const Offset(520, 400), // Center position
    'Member Name': const Offset(236, 948),
    'User Name': const Offset(236, 100),
    'Mobile': const Offset(236, 40),
  };

  // Element scales
  final Map<String, double> _elementScales = {
    'Member Image': 1.0,
    'Member Name': 1.0,
    'User Name': 1.0,
    'Mobile': 1.0,
  };

  // Remove checkbox state and keep only dropdown state
  String? _selectedDropdownElement;
  final List<String> _elements = [
    'Member Image',
    'Member Name',
    'User Name',
    'Mobile',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateCardDimensions();
  }

  void _calculateCardDimensions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate scale based on both width and height constraints
    final widthScale = screenWidth / cardWidth;
    final heightScale = screenHeight / cardHeight;
    final scale = min(widthScale, heightScale) *
        0.95; // 95% of the screen to ensure some padding

    _scaledCardWidth = cardWidth * scale;
    _scaledCardHeight = cardHeight * scale;
  }

  String? _getProfileImageUrl() {
    if (widget.profileData == null) return null;

    String? imagePath = widget.profileData!['user_profile_image']?.toString();
    if (imagePath == null || imagePath.isEmpty || imagePath == 'null')
      return null;

    if (imagePath.startsWith('http')) return imagePath;

    // Clean up the path
    if (imagePath.startsWith('file:///')) {
      imagePath = imagePath.replaceFirst('file:///', '');
    }
    if (imagePath.startsWith('/')) {
      imagePath = imagePath.substring(1);
    }

    // Return the full URL
    return 'http://192.168.1.2:8000/$imagePath';
  }

  String? _getMemberName() {
    if (widget.profileData == null) return null;
    return widget.profileData!['user_name']?.toString();
  }

  Widget _buildImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty || imagePath == 'null') {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 48),
        ),
      );
    }

    try {
      String cleanPath = imagePath;
      if (!cleanPath.startsWith('http')) {
        if (cleanPath.startsWith('file:///')) {
          cleanPath = cleanPath.replaceFirst('file:///', '');
        }
        if (cleanPath.startsWith('/')) {
          cleanPath = cleanPath.substring(1);
        }
        cleanPath = 'http://192.168.1.2:8000/$cleanPath';
      }

      return Image.network(
        cleanPath,
        width: _scaledCardWidth,
        height: _scaledCardHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.white,
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 48),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 48),
        ),
      );
    }
  }

  Widget _buildCardSizeDisplay() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.aspect_ratio,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '${cardWidth.toInt()} × ${cardHeight.toInt()} px',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedDropdownElement,
            hint: Text(
              'Select Element',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
            items: _elements.map((element) {
              return DropdownMenuItem<String>(
                value: element,
                child: Row(
                  children: [
                    Icon(
                      _getIconForElement(element),
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      element,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedDropdownElement = value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildElementBar() {
    if (_selectedDropdownElement == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Element name
          Text(
            _selectedDropdownElement!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          // X Position
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.arrow_right_alt, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'X: ${_elementPositions[_selectedDropdownElement]!.dx.toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Y Position
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.arrow_downward, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Y: ${_elementPositions[_selectedDropdownElement]!.dy.toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Scale
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.zoom_in, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Scale: ${_elementScales[_selectedDropdownElement]!.toStringAsFixed(1)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberImage() {
    final position = _elementPositions['Member Image']!;
    final scale = _elementScales['Member Image']!;
    final imageUrl = _getProfileImageUrl();

    return Positioned(
      top: position.dy,
      left: position.dx,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          size: 75,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.person,
                      size: 75,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberName() {
    final position = _elementPositions['Member Name']!;
    final scale = _elementScales['Member Name']!;
    final memberName = _getMemberName();

    return Positioned(
      top: position.dy,
      left: position.dx,
      child: Transform.scale(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            memberName ?? 'Member Name',
            style: GoogleFonts.tangerine(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserName() {
    final position = _elementPositions['User Name']!;
    final scale = _elementScales['User Name']!;
    final userName = _getMemberName();

    return Positioned(
      top: position.dy,
      left: position.dx,
      child: Transform.scale(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            userName ?? 'User Name',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobile() {
    final position = _elementPositions['Mobile']!;
    final scale = _elementScales['Mobile']!;
    final mobile = widget.profileData?['phone_number']?.toString();

    return Positioned(
      top: position.dy,
      left: position.dx,
      child: Transform.scale(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            mobile ?? 'Mobile Number',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForElement(String element) {
    switch (element) {
      case 'Member Image':
        return Icons.image;
      case 'Member Name':
        return Icons.person;
      case 'User Name':
        return Icons.account_circle;
      case 'Mobile':
        return Icons.phone;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void initState() {
    super.initState();
    // Print profile data for debugging
    print('Profile Data: ${widget.profileData}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Greeting Card',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Element controls (dropdown only)
            _buildElementControls(),
            // Element bar (position and scale info)
            _buildElementBar(),
            // Card
            Expanded(
              child: Center(
                child: Container(
                  width: _scaledCardWidth,
                  height: _scaledCardHeight,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child:
                            _buildImage(widget.cardData?['background_image']),
                      ),
                      // Greeting image
                      if (widget.cardData?['greeting_image'] != null)
                        Positioned.fill(
                          child:
                              _buildImage(widget.cardData!['greeting_image']),
                        ),
                      // Member Image
                      _buildMemberImage(),
                      // Member Name
                      _buildMemberName(),
                      // User Name
                      _buildUserName(),
                      // Mobile
                      _buildMobile(),
                      // Card size display
                      _buildCardSizeDisplay(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
