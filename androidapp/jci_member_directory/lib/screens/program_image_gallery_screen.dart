import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:async';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/program_folder.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class ProgramImageGalleryScreen extends StatefulWidget {
  final ProgramFolder folder;

  const ProgramImageGalleryScreen({
    Key? key,
    required this.folder,
  }) : super(key: key);

  @override
  _ProgramImageGalleryScreenState createState() =>
      _ProgramImageGalleryScreenState();
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

class _ProgramImageGalleryScreenState extends State<ProgramImageGalleryScreen> {
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
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
    // Clear cache when screen is disposed
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
    // If images are already loaded, don't reload
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
            // Get the image path from the response
            final String imagePath = image['image'];
            // Construct the full URL by adding base URL if it's a relative path
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
          _imagesLoaded = true; // Set flag to true after successful load
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

      // Load images for the next page
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

  Future<String> _getImageSize(String imageUrl) async {
    if (ImageCacheManager.hasImage(imageUrl)) {
      return ImageCacheManager.getSize(imageUrl)!;
    }

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final size = _formatFileSize(response.bodyBytes.length);
        ImageCacheManager.cacheSize(imageUrl, size);
        return size;
      }
    } catch (e) {
      print('Error getting image size: $e');
    }
    return '0B';
  }

  Future<void> _uploadImages() async {
    try {
      print('Test1: Starting image upload process');
      final List<XFile> images = await _picker.pickMultiImage();
      print('Test2: Selected ${images.length} images');

      if (images.isEmpty) {
        print('Test3: No images selected');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Get auth token
      final token = await AuthService.getAccessToken();
      print('Test4: Got auth token');

      // Convert all images to base64 with size limit check
      final List<Map<String, String>> imageData = [];
      for (final image in images) {
        try {
          print('Test5: Processing image: ${image.name}');
          final File imageFile = File(image.path);
          final bytes = await imageFile.readAsBytes();
          print(
              'Test6: Image size: ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)}MB');

          // Check file size (limit to 10MB)
          if (bytes.length > 10 * 1024 * 1024) {
            print('Test7: Image too large: ${image.name}');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Image ${image.name} is too large. Maximum size is 10MB'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            continue;
          }

          final base64Image = base64Encode(bytes);
          imageData.add({
            'image': base64Image,
          });
          print('Test8: Successfully processed image: ${image.name}');
        } catch (e) {
          print('Test9: Error processing image ${image.name}: $e');
          continue;
        }
      }

      if (imageData.isEmpty) {
        print('Test10: No valid images to upload');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Test11: Total images to upload: ${imageData.length}');

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'images': imageData,
      };

      // If it's a new folder (ID contains timestamp), add programName and year
      if (widget.folder.id.length > 10) {
        print('Test12: Adding program details for new folder');
        requestBody['program_id'] = widget.folder.id;
        requestBody['programName'] = widget.folder.name;
        requestBody['year'] = DateTime.now().year.toString();
      } else {
        requestBody['program_id'] = widget.folder.id;
      }

      print('Test13: Sending upload request');
      // Send all images in a single request
      final response = await ApiService.post(
        endpoint: ApiConfig.uploadProgramImage,
        body: requestBody,
        token: token,
      );

      print('Test14: Upload response status: ${response['status']}');
      if (response['status'] == 200) {
        print('Test15: Upload successful');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Images uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset the loaded flag to force a refresh
        _imagesLoaded = false;
        await _loadImages(); // Reload images after upload
      } else {
        print('Test16: Upload failed: ${response['message']}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to upload images'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Test17: Error in upload process: $e');
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

      final token = await AuthService.getAccessToken();
      final response = await ApiService.delete(
        endpoint:
            '${ApiConfig.programImages}${widget.folder.id}/images/$imageId/',
        token: token,
      );

      if (response['status'] == 200) {
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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Image View',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  try {
                    final bytes = ImageCacheManager.getImage(imageUrl);
                    if (bytes != null) {
                      final directory =
                          await getApplicationDocumentsDirectory();
                      final fileName =
                          '${DateTime.now().millisecondsSinceEpoch}.jpg';
                      final file = File('${directory.path}/$fileName');
                      await file.writeAsBytes(bytes);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image downloaded successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
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
                },
              ),
            ],
          ),
          body: PhotoView(
            imageProvider: ImageCacheManager.hasImage(imageUrl)
                ? MemoryImage(ImageCacheManager.getImage(imageUrl)!)
                    as ImageProvider
                : CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: BoxDecoration(
              color: Colors.black,
            ),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSelectionMode() {
    print(
        'Selection1: Toggling selection mode from $_isSelectionMode to ${!_isSelectionMode}');
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        print(
            'Selection2: Clearing selected images, count: ${_selectedImages.length}');
        _selectedImages.clear();
      }
    });
  }

  void _toggleImageSelection(String imageId) {
    print('Selection3: Toggling image selection for ID: $imageId');
    setState(() {
      if (_selectedImages.contains(imageId)) {
        print('Selection4: Removing image from selection');
        _selectedImages.remove(imageId);
      } else {
        print('Selection5: Adding image to selection');
        _selectedImages.add(imageId);
      }
      print(
          'Selection6: Current selected images count: ${_selectedImages.length}');
    });
  }

  Future<void> _deleteSelectedImages() async {
    if (_selectedImages.isEmpty) {
      print('Delete1: No images selected for deletion');
      return;
    }

    print('Delete2: Starting deletion of ${_selectedImages.length} images');
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await AuthService.getAccessToken();
      print('Delete3: Got auth token');
      bool allSuccess = true;

      for (String imageId in _selectedImages) {
        print('Delete4: Deleting image ID: $imageId');
        final response = await ApiService.delete(
          endpoint:
              '${ApiConfig.programImages}${widget.folder.id}/images/$imageId/',
          token: token,
        );

        if (response['status'] != 200) {
          print(
              'Delete5: Failed to delete image $imageId: ${response['message']}');
          allSuccess = false;
          break;
        } else {
          print('Delete6: Successfully deleted image $imageId');
        }
      }

      if (allSuccess) {
        print('Delete7: All images deleted successfully');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected images deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _selectedImages.clear();
        _isSelectionMode = false;
        _imagesLoaded = false;
        await _loadImages();
      } else {
        print('Delete8: Some images failed to delete');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete some images'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Delete9: Error in deletion process: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting images: ${e.toString()}'),
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

  Future<void> _downloadSelectedImages() async {
    print('\n=== DOWNLOAD PROCESS STARTED ===');
    if (_selectedImages.isEmpty) {
      print('Line 1: No images selected for download');
      return;
    }

    print('Line 2: Number of images selected: ${_selectedImages.length}');
    print('\nLine 3: Selected Image Details:');
    for (String imageId in _selectedImages) {
      final image = widget.folder.images.firstWhere((img) => img.id == imageId);
      print('Line 3.1: Image ID: $imageId');
      print('Line 3.2: Image URL: ${image.url}');
    }

    try {
      print('\nLine 4: Setting loading state to true');
      setState(() {
        _isLoading = true;
      });

      print('Line 5: Getting external storage directory');
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        print('Line 5.1: Failed to get external storage directory');
        throw Exception('External storage not available');
      }

      // Create app-specific directory in Pictures folder
      final picturesDir =
          Directory('/storage/emulated/0/Pictures/JCI_Member_Directory');
      if (!await picturesDir.exists()) {
        print('Line 5.2: Creating app directory in Pictures');
        await picturesDir.create(recursive: true);
      }

      // Create folder for current program
      final programDir = Directory('${picturesDir.path}/${widget.folder.name}');
      if (!await programDir.exists()) {
        print('Line 5.3: Creating program directory: ${widget.folder.name}');
        await programDir.create(recursive: true);
      }

      print('Line 6: Download directory path: ${programDir.path}');

      int successCount = 0;
      print('\nLine 7: Starting image download loop');

      for (String imageId in _selectedImages) {
        print('\nLine 8: Processing image ID: $imageId');
        final image =
            widget.folder.images.firstWhere((img) => img.id == imageId);
        try {
          print('Line 9: Downloading image from URL: ${image.url}');
          final response = await http.get(Uri.parse(image.url));

          if (response.statusCode == 200) {
            print('Line 10: Image downloaded successfully');
            final bytes = response.bodyBytes;

            // Create filename with timestamp and original extension
            final extension = image.url.split('.').last;
            final fileName =
                '${DateTime.now().millisecondsSinceEpoch}_$imageId.$extension';
            final file = File('${programDir.path}/$fileName');

            print('Line 11: Creating file at: ${file.path}');
            await file.writeAsBytes(bytes);
            successCount++;
            print('Line 12: Successfully saved image: $fileName');

            // Notify media scanner to make the image visible in gallery
            print('Line 13: Notifying media scanner');
            await _notifyMediaScanner(file.path);
          } else {
            print(
                'Line 14: Failed to download image. Status code: ${response.statusCode}');
          }
        } catch (e) {
          print('Line 15: Error downloading image $imageId: $e');
        }
      }

      print('\nLine 16: Download process completed');
      print('Line 17: Successfully downloaded: $successCount images');
      print('Line 18: Total images attempted: ${_selectedImages.length}');

      if (!mounted) {
        print('Line 19: Widget not mounted, skipping UI update');
        return;
      }

      print('Line 20: Showing download result snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully downloaded $successCount of ${_selectedImages.length} images to gallery'),
          backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print('\nLine 21: Error in download process: $e');
      if (!mounted) {
        print('Line 22: Widget not mounted, skipping error UI update');
        return;
      }
      print('Line 23: Showing error snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        print('Line 24: Setting loading state to false');
        setState(() {
          _isLoading = false;
        });
      }
      print('=== DOWNLOAD PROCESS COMPLETED ===\n');
    }
  }

  Future<void> _notifyMediaScanner(String filePath) async {
    try {
      const platform = MethodChannel('com.example.jci_member_directory/media');
      await platform.invokeMethod('scanFile', {'path': filePath});
      print('Media scanner notified for: $filePath');
    } catch (e) {
      print('Error notifying media scanner: $e');
    }
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
            IconButton(
              icon: const Icon(Icons.download),
              onPressed:
                  _selectedImages.isEmpty ? null : _downloadSelectedImages,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedImages.isEmpty ? null : _deleteSelectedImages,
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
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _uploadImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Images'),
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
                          // Image size overlay
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
                          // Delete button (only show when not in selection mode)
                          if (!_isSelectionMode)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteImage(image.id),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _uploadImages,
              child: const Icon(Icons.add_photo_alternate),
            ),
    );
  }
}
