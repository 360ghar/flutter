import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ghar360/core/data/models/property_image_model.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/repositories/properties_repository.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_compress/video_compress.dart';

class MediaUploadResult {
  final String url;
  final String storagePath;
  final int? bytes;
  final Duration? duration;
  final String? mimeType;

  const MediaUploadResult({
    required this.url,
    required this.storagePath,
    this.bytes,
    this.duration,
    this.mimeType,
  });
}

class MediaUploadService {
  MediaUploadService({String? bucket})
    : _bucket = bucket ?? dotenv.env['SUPABASE_MEDIA_BUCKET'] ?? 'property-media';

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _client = Supabase.instance.client;
  final String _bucket;

  Future<MediaUploadResult?> pickAndUploadImage({
    required int propertyId,
    bool markAsMain = false,
    String category = 'gallery',
  }) async {
    if (kIsWeb) {
      DebugLogger.warning('Image picking not supported on web sandbox');
      return null;
    }
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final ext = _fileExtension(file.path, fallback: 'jpg');
    final path = _buildPath(propertyId, ext, category: category);

    final upload = await _uploadBytes(bytes, path: path, contentType: 'image/$ext');
    if (upload == null) return null;

    return MediaUploadResult(
      url: upload,
      storagePath: path,
      bytes: bytes.lengthInBytes,
      mimeType: 'image/$ext',
    );
  }

  Future<MediaUploadResult?> pickAndUploadVideo({
    required int propertyId,
    bool compress = true,
  }) async {
    if (kIsWeb) {
      DebugLogger.warning('Video picking not supported on web sandbox');
      return null;
    }
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (file == null) return null;

    XFile uploadFile = file;
    Duration? duration;
    try {
      if (compress) {
        final info = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          includeAudio: true,
        );
        if (info?.file != null) {
          uploadFile = XFile(info!.file!.path);
          duration = info.duration != null ? Duration(milliseconds: info.duration!.toInt()) : null;
        }
      }
    } catch (e) {
      DebugLogger.warning('Video compression failed, uploading original file', e);
    }

    final bytes = await uploadFile.readAsBytes();
    final ext = _fileExtension(uploadFile.path, fallback: 'mp4');
    final path = _buildPath(propertyId, ext, category: 'videos');

    final upload = await _uploadBytes(bytes, path: path, contentType: 'video/$ext');
    if (upload == null) return null;

    return MediaUploadResult(
      url: upload,
      storagePath: path,
      bytes: bytes.lengthInBytes,
      duration: duration,
      mimeType: 'video/$ext',
    );
  }

  Future<PropertyModel?> uploadImageAndAttach({
    required int propertyId,
    required PropertiesRepository repository,
    bool markAsMain = false,
    String category = 'gallery',
  }) async {
    final result = await pickAndUploadImage(
      propertyId: propertyId,
      markAsMain: markAsMain,
      category: category,
    );
    if (result == null) return null;

    final image = PropertyImageModel(
      id: -1,
      propertyId: propertyId,
      imageUrl: result.url,
      displayOrder: 0,
      isMainImage: markAsMain,
      isMain: markAsMain,
      category: category,
    );

    return repository.updatePropertyMedia(
      propertyId: propertyId,
      mainImageUrl: markAsMain ? result.url : null,
      images: [image],
    );
  }

  Future<PropertyModel?> uploadVideoAndAttach({
    required int propertyId,
    required PropertiesRepository repository,
    bool compress = true,
  }) async {
    final result = await pickAndUploadVideo(propertyId: propertyId, compress: compress);
    if (result == null) return null;

    return repository.updatePropertyMedia(
      propertyId: propertyId,
      videoTourUrl: result.url,
      videoUrls: [result.url],
    );
  }

  Future<String?> _uploadBytes(
    Uint8List data, {
    required String path,
    required String contentType,
  }) async {
    if (_bucket.isEmpty) {
      DebugLogger.warning('Supabase bucket not configured, skipping upload');
      return null;
    }
    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            data,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
      DebugLogger.success('Uploaded media to $publicUrl');
      return publicUrl;
    } catch (e, st) {
      DebugLogger.error('Failed to upload media to Supabase', e, st);
      return null;
    }
  }

  String _buildPath(int propertyId, String extension, {required String category}) {
    final safeExt = extension.replaceAll('.', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return 'properties/$propertyId/$category/$timestamp-$random.$safeExt';
  }

  String _fileExtension(String path, {required String fallback}) {
    final parts = path.split('.');
    if (parts.length > 1) {
      final ext = parts.last.trim();
      if (ext.isNotEmpty) return ext.toLowerCase();
    }
    return fallback;
  }
}
