import 'package:flutter/material.dart';
import '../services/file_service.dart';



bool isAssetRef(String? ref) => ref != null && ref.startsWith('assets/');

String _normalizeRef(String? s) {
  final r = (s ?? '').trim();
  if (r.isEmpty) return r;
  const marker = '/static/assets/';
  final idx = r.indexOf(marker);
  if (idx != -1) {
    // handles both absolute URLs and plain '/static/assets/...'
    return 'assets/${r.substring(idx + marker.length)}';
  }
  return r;
}

ImageProvider<Object>? imageProviderFor(String? ref) {
    if (ref == null || ref.isEmpty) return null;
  return ref.startsWith('assets/') ? AssetImage(ref) : NetworkImage(ref);
}

String? resolveImageRef({String? url, String? name}) {
  String? u = _normalizeRef(url);
  String? n = _normalizeRef(name);

  // If either already points to an asset, use it directly
  if (u.startsWith('assets/')) return u;
  if (n.startsWith('assets/')) return n;

  // If either is already an absolute URL, use it
  if ((u.startsWith('http://') || u.startsWith('https://'))) return u;
  if ((n.startsWith('http://') || n.startsWith('https://'))) return n;

  // If we have a /static/ path, convert it to absolute URL
  if (u.startsWith('/static/')) {
    return FileService.absoluteUrl(u);
  }
  if (n.startsWith('/static/')) {
    return FileService.absoluteUrl(n);
  }

  // If we only have a bare filename, serve from /static
  if (n.isNotEmpty) return FileService.absoluteUrl('/static/$n');
  
  // If u is a bare filename (no path), serve from /static
  if (u.isNotEmpty && !u.startsWith('/') && !u.startsWith('http')) {
    return FileService.absoluteUrl('/static/$u');
  }

  return u; // could be null
}

ImageProvider<Object>? providerFromRef(String? ref) {
  ref = _normalizeRef(ref);
  if (ref.isEmpty) return null;
  return ref.startsWith('assets/') ? AssetImage(ref) : NetworkImage(ref);
}

Widget imageFromRef(String? ref, {double? height, double? width, BoxFit? fit}) {
  ref = _normalizeRef(ref);
  if (ref.isEmpty) {
    return Container(
      height: height, width: width, color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Colors.black26),
    );
  }
  if (ref.startsWith('assets/')) {
    return Image.asset(ref, height: height, width: width, fit: fit);
  }
  
  // Convert relative paths to absolute URLs
  String imageUrl;
  if (ref.startsWith('/')) {
    imageUrl = FileService.absoluteUrl(ref);
  } else if (ref.startsWith('http')) {
    imageUrl = ref;
  } else {
    // It's a bare filename, add /static/ prefix
    imageUrl = FileService.absoluteUrl('/static/$ref');
  }
  
  return Image.network(
    imageUrl, height: height, width: width, fit: fit,
    errorBuilder: (_, _, _) => Container(
      height: height, width: width, color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Colors.black26),
    ),
  );
}