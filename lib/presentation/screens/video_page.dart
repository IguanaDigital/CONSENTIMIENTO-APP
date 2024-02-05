import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class VideoPage extends StatefulWidget {
  final String filePath;
  const VideoPage({super.key, required this.filePath});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future<void> _initVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.filePath));
    await _videoPlayerController.initialize();
    await _videoPlayerController.setLooping(true);
    await _videoPlayerController.play();
  }

  Future<void> _saveToGallery() async {
    final status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final fileName = widget.filePath.split('/').last;
      final galleryPath =
          appDocDir.path.replaceAll('app_flutter', 'DCIM/Camera');

      // Asegurarse de que el directorio de la galería exista
      final galleryDirectory = Directory(galleryPath);
      if (!await galleryDirectory.exists()) {
        await galleryDirectory.create(recursive: true);
      }

      try {
        final galleryFile =
            await File(widget.filePath).copy('$galleryPath/$fileName');
        // Actualiza la galería para que el video sea visible
        await GallerySaver.saveVideo(galleryFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video guardado en la galería')),
        );
      } on PlatformException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el video: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Se requieren permisos para guardar el video en la galería'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        elevation: 0,
        backgroundColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _saveToGallery();
              Navigator.pop(context);
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder(
        future: _initVideoPlayer(),
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return VideoPlayer(_videoPlayerController);
          }
        },
      ),
    );
  }
}
