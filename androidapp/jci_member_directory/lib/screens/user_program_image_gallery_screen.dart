import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/program_folder.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class UserProgramImageGalleryScreen extends StatefulWidget {
  final ProgramFolder folder;

  const UserProgramImageGalleryScreen({
    Key? key,
    required this.folder,
  }) : super(key: key);

  @override
  _UserProgramImageGalleryScreenState createState() =>
      _UserProgramImageGalleryScreenState();
}

// Static cache to maintain data across screen lifecycle
class ImageCacheManager {
  static final Map<String, Uint8List> _imageCache = {};
  static final Map<String, String> _sizeCache = {};

  static void cacheImage(String url, Uint8List bytes) {
    _imageCache[url] = bytes;
  }

  static void cacheSize(String url, String size) {
    _sizeCache[url] = size;
  }

  static Uint8List? getImage(String url) {
    return _imageCache[url];
  }

  static String? getSize(String url) {
    return _sizeCache[url];
  }

  static bool hasImage(String url) {
    return _imageCache.containsKey(url);
  }

  static void clearCache() {
    _imageCache.clear();
    _sizeCache.clear();
  }
}

class _UserProgramImageGalleryScreenState
    extends State<UserProgramImageGalleryScreen> {
  bool _isLoading = false;
  bool _imagesLoaded = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  static const int _pageSize = 9; // Number of images per page
  bool _isSelectionMode = false;
  Set<String> _selectedImages = {};

  @override
  void initState() {
    super.initState();
    print('Opening folder: ${widget.folder.name} with ID: ${widget.folder.id}');
    if (!_imagesLoaded) {
      _loadImages();
    }
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    ImageCacheManager.clearCache();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadNextPage();
    }
  }

  Future<void> _loadImages() async {
    if (_imagesLoaded) {
      print('Images already loaded, skipping reload');
      return;
    }

    print('Loading images for folder: ${widget.folder.name}');
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getAccessToken();
      print(
          'Calling API: api/program-images/program-id/ with program_id: ${widget.folder.id}');
      final response = await ApiService.post(
        endpoint: 'api/program-images/program-id/',
        body: {'program_id': widget.folder.id},
        token: token,
      );

      print('API Response status: ${response['status']}');
      if (response['status'] == 200) {
        print(
            'Successfully loaded ${(response['payload'] as List).length} images');
        setState(() {
          widget.folder.images = (response['payload'] as List).map((image) {
            final String imagePath = image['image'];
            final String fullUrl = imagePath.startsWith('http')
                ? imagePath
                : '${ApiConfig.baseUrl}${imagePath.startsWith('/') ? imagePath.substring(1) : imagePath}';

            print('Image URL: $fullUrl');

            return ProgramImage(
              id: image['id'].toString(),
              url: fullUrl,
              programId: widget.folder.id,
              createdAt: DateTime.now(),
            );
          }).toList();
          _imagesLoaded = true;
        });
      } else {
        print('Failed to load images: ${response['message']}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load images'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error loading images: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading images: ${e.toString()}'),
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

  Future<void> _loadNextPage() async {
    if (_isLoading) return;

    final startIndex = _currentPage * _pageSize;
    if (startIndex >= widget.folder.images.length) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final endIndex = (startIndex + _pageSize) > widget.folder.images.length
          ? widget.folder.images.length
          : startIndex + _pageSize;

      for (int i = startIndex; i < endIndex; i++) {
        final image = widget.folder.images[i];
        if (!ImageCacheManager.hasImage(image.url)) {
          await _preloadImage(image.url);
        }
      }

      setState(() {
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading next page: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _preloadImage(String imageUrl) async {
    if (ImageCacheManager.hasImage(imageUrl)) return;

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        ImageCacheManager.cacheImage(imageUrl, response.bodyBytes);
        ImageCacheManager.cacheSize(
            imageUrl, _formatFileSize(response.bodyBytes.length));
      }
    } catch (e) {
      print('Error preloading image: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedImages.clear();
      }
    });
  }

  void _toggleImageSelection(String imageId) {
    setState(() {
      if (_selectedImages.contains(imageId)) {
        _selectedImages.remove(imageId);
      } else {
        _selectedImages.add(imageId);
      }
    });
  }

  Future<void> _downloadSelectedImages() async {
    if (_selectedImages.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Create JCIKotaStar directory in Pictures folder
      final picturesDir = Directory('/storage/emulated/0/Pictures/JCIKotaStar');
      if (!await picturesDir.exists()) {
        await picturesDir.create(recursive: true);
      }

      int successCount = 0;

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  'Downloading Images',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: successCount / _selectedImages.length,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Downloaded $successCount out of ${_selectedImages.length} images',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      for (String imageId in _selectedImages) {
        final image =
            widget.folder.images.firstWhere((img) => img.id == imageId);
        try {
          final response = await http.get(Uri.parse(image.url));

          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final extension = image.url.split('.').last;
            final fileName =
                'JCI_${DateTime.now().millisecondsSinceEpoch}_$imageId.$extension';
            final file = File('${picturesDir.path}/$fileName');

            await file.writeAsBytes(bytes);
            successCount++;

            // Update progress dialog
            if (mounted) {
              Navigator.of(context).pop(); // Remove old dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: Text(
                          'Downloading Images',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LinearProgressIndicator(
                              value: successCount / _selectedImages.length,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Downloaded $successCount out of ${_selectedImages.length} images',
                              style: GoogleFonts.poppins(),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }

            await _notifyMediaScanner(file.path);
          }
        } catch (e) {
          print('Error downloading image $imageId: $e');
        }
      }

      // Close the progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully downloaded $successCount of ${_selectedImages.length} images to JCIKotaStar folder'),
          backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

      setState(() {
        _selectedImages.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog if open
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading images: ${e.toString()}'),
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

  Future<void> _notifyMediaScanner(String filePath) async {
    try {
      const platform = MethodChannel('com.example.jci_member_directory/media');
      await platform.invokeMethod('scanFile', {'path': filePath});
      await Future.delayed(const Duration(milliseconds: 500));
      await platform.invokeMethod('refreshGallery');
    } catch (e) {
      print('Error notifying media scanner: $e');
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    final initialIndex =
        widget.folder.images.indexWhere((img) => img.url == imageUrl);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: widget.folder.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.folder.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isSelectionMode) ...[
            // Select All button
            IconButton(
              icon: Icon(
                _selectedImages.length == widget.folder.images.length
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _selectedImages.length == widget.folder.images.length
                    ? Colors.blue
                    : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  if (_selectedImages.length == widget.folder.images.length) {
                    // If all are selected, deselect all
                    _selectedImages.clear();
                  } else {
                    // If not all are selected, select all
                    _selectedImages =
                        Set.from(widget.folder.images.map((image) => image.id));
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed:
                  _selectedImages.isEmpty ? null : _downloadSelectedImages,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
            ),
          ],
        ],
      ),
      body: _isLoading && _currentPage == 0
          ? const Center(child: CircularProgressIndicator())
          : widget.folder.images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No images in this program',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: widget.folder.images.length,
                  itemBuilder: (context, index) {
                    final image = widget.folder.images[index];
                    return GestureDetector(
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleImageSelection(image.id);
                        } else {
                          _showFullScreenImage(context, image.url);
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          _toggleSelectionMode();
                          _toggleImageSelection(image.id);
                        }
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ImageCacheManager.hasImage(image.url)
                                ? Image.memory(
                                    ImageCacheManager.getImage(image.url)!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: image.url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      print('Error loading image: $error');
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.error),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          if (_isSelectionMode)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _selectedImages.contains(image.id)
                                      ? Colors.blue
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                child: _selectedImages.contains(image.id)
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ImageCacheManager.getSize(image.url) ??
                                    'Loading...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<ProgramImage> images;
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late int currentIndex;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> _notifyMediaScanner(String filePath) async {
    try {
      const platform = MethodChannel('com.example.jci_member_directory/media');
      await platform.invokeMethod('scanFile', {'path': filePath});
      await Future.delayed(const Duration(milliseconds: 500));
      await platform.invokeMethod('refreshGallery');
    } catch (e) {
      print('Error notifying media scanner: $e');
    }
  }

  Future<void> _downloadImage() async {
    try {
      final currentImage = widget.images[currentIndex];
      final bytes = ImageCacheManager.getImage(currentImage.url);

      if (bytes != null) {
        // Create JCIKotaStar directory in Pictures folder
        final picturesDir =
            Directory('/storage/emulated/0/Pictures/JCIKotaStar');
        if (!await picturesDir.exists()) {
          await picturesDir.create(recursive: true);
        }

        final extension = currentImage.url.split('.').last;
        final fileName =
            'JCI_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final file = File('${picturesDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        await _notifyMediaScanner(file.path);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // If image is not cached, download it first
        final response = await http.get(Uri.parse(currentImage.url));
        if (response.statusCode == 200) {
          // Create JCIKotaStar directory in Pictures folder
          final picturesDir =
              Directory('/storage/emulated/0/Pictures/JCIKotaStar');
          if (!await picturesDir.exists()) {
            await picturesDir.create(recursive: true);
          }

          final extension = currentImage.url.split('.').last;
          final fileName =
              'JCI_${DateTime.now().millisecondsSinceEpoch}.$extension';
          final file = File('${picturesDir.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);

          await _notifyMediaScanner(file.path);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          '${currentIndex + 1}/${widget.images.length}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _downloadImage,
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final currentImage = widget.images[index];
              return PhotoView(
                imageProvider: ImageCacheManager.hasImage(currentImage.url)
                    ? MemoryImage(ImageCacheManager.getImage(currentImage.url)!)
                        as ImageProvider
                    : CachedNetworkImageProvider(currentImage.url),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
                loadingBuilder: (context, event) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.share, color: Colors.white, size: 28),
                    onPressed: () async {
                      try {
                        final currentImage = widget.images[currentIndex];
                        final bytes =
                            ImageCacheManager.getImage(currentImage.url);

                        if (bytes != null) {
                          // Create a temporary file to share
                          final tempDir = await getTemporaryDirectory();
                          final extension = currentImage.url.split('.').last;
                          final fileName =
                              'JCI_${DateTime.now().millisecondsSinceEpoch}.$extension';
                          final file = File('${tempDir.path}/$fileName');
                          await file.writeAsBytes(bytes);

                          // Share the image
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text: 'Check out this image from JCI Kota Star!',
                            subject: 'JCI Kota Star Image',
                          );
                        } else {
                          // If image is not cached, download it first
                          final response =
                              await http.get(Uri.parse(currentImage.url));
                          if (response.statusCode == 200) {
                            final tempDir = await getTemporaryDirectory();
                            final extension = currentImage.url.split('.').last;
                            final fileName =
                                'JCI_${DateTime.now().millisecondsSinceEpoch}.$extension';
                            final file = File('${tempDir.path}/$fileName');
                            await file.writeAsBytes(response.bodyBytes);

                            // Share the image
                            await Share.shareXFiles(
                              [XFile(file.path)],
                              text: 'Check out this image from JCI Kota Star!',
                              subject: 'JCI Kota Star Image',
                            );
                          }
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error sharing image: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      // TODO: Implement favorite functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Favorite functionality coming soon'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      // TODO: Implement delete functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delete functionality coming soon'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
