import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis/photoslibrary/v1.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GooglePhotosScreen extends StatefulWidget {
  const GooglePhotosScreen({Key? key}) : super(key: key);

  @override
  _GooglePhotosScreenState createState() => _GooglePhotosScreenState();
}

class _GooglePhotosScreenState extends State<GooglePhotosScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/photoslibrary.readonly',
    ],
  );

  bool _isLoading = false;
  List<MediaItem> _photos = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      final String credentials =
          await rootBundle.loadString('assets/credentials/client_secret.json');
      final Map<String, dynamic> credentialsMap = json.decode(credentials);
      // Store credentials for later use
      _initializeGoogleSignIn(credentialsMap);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load credentials: $e';
      });
    }
  }

  void _initializeGoogleSignIn(Map<String, dynamic> credentials) {
    _googleSignIn.signInSilently().then((account) {
      if (account != null) {
        _loadPhotos();
      } else {
        _signIn();
      }
    });
  }

  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        await _loadPhotos();
      } else {
        setState(() {
          _errorMessage = 'Sign in failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error signing in: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPhotos() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) {
        throw Exception('Not signed in');
      }

      final authHeaders = await account.authHeaders;
      final client = http.Client();
      final photosApi = PhotosLibraryApi(client,
          rootUrl: 'https://photoslibrary.googleapis.com/');

      final response = await photosApi.mediaItems.list();
      setState(() {
        _photos = response.mediaItems ?? [];
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading photos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadPhotos,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signIn,
              child: Text(
                'Sign In',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      );
    }

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No photos found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signIn,
              child: Text(
                'Sign In',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
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
        return GestureDetector(
          onTap: () {
            // TODO: Implement photo preview
          },
          child: CachedNetworkImage(
            imageUrl: photo.baseUrl ?? '',
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
