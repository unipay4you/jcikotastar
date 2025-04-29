import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({Key? key}) : super(key: key);

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  bool _isLoading = false;
  final List<Map<String, String>> _photos = [
    {
      'name': 'Shop Pic 1',
      'url':
          'https://drive.google.com/uc?export=view&id=1sfuSDd695ikrvxD-Iw01Mu4kNWEwsnWX',
    },
    {
      'name': 'Shop Pic 2',
      'url':
          'https://drive.google.com/uc?export=view&id=1sfuSDd695ikrvxD-Iw01Mu4kNWEwsnWX',
    },
    {
      'name': 'Shop Pic 3',
      'url':
          'https://drive.google.com/uc?export=view&id=1sfuSDd695ikrvxD-Iw01Mu4kNWEwsnWX',
    },
    {
      'name': 'Shop Pic 4',
      'url':
          'https://drive.google.com/uc?export=view&id=1sfuSDd695ikrvxD-Iw01Mu4kNWEwsnWX',
    },
    {
      'name': 'Shop Pic 5',
      'url':
          'https://drive.google.com/uc?export=view&id=1sfuSDd695ikrvxD-Iw01Mu4kNWEwsnWX',
    },
    {
      'name': 'Shop Pic 6',
      'url':
          'https://drive.google.com/uc?export=view&id=1sfuSDd695ikrvxD-Iw01Mu4kNWEwsnWX',
    },
  ];

  void _showPhotoPreview(BuildContext context, int index) {
    print('Opening photo preview for image: ${_photos[index]['url']}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              _photos[index]['name'] ?? 'Photo',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: PhotoViewGallery.builder(
            itemCount: _photos.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(
                  _photos[index]['url'] ?? '',
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            pageController: PageController(initialPage: index),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Photo Gallery',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_photos.isEmpty) {
      return Center(
        child: Text(
          'No photos found',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        print('Loading image in grid: ${photo['url']}');
        return GestureDetector(
          onTap: () => _showPhotoPreview(context, index),
          child: CachedNetworkImage(
            imageUrl: photo['url'] ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }
}
