import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:logger/logger.dart';
import '../models/link_preview_model.dart';

/// Service for generating link previews
class LinkPreviewService {
  static final LinkPreviewService _instance = LinkPreviewService._internal();
  factory LinkPreviewService() => _instance;
  LinkPreviewService._internal();

  final Logger _logger = Logger();
  final Map<String, LinkPreviewModel> _cache = {};
  
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxCacheSize = 100;

  /// Generate link preview for URL
  Future<LinkPreviewModel?> generatePreview(String url) async {
    try {
      // Check cache first
      if (_cache.containsKey(url)) {
        _logger.d('Link preview found in cache: $url');
        return _cache[url];
      }

      // Validate URL
      if (!_isValidUrl(url)) {
        _logger.w('Invalid URL: $url');
        return null;
      }

      // Fetch webpage content
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'P2P Chat App/1.0 (Link Preview Bot)',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        _logger.w('Failed to fetch URL: $url, Status: ${response.statusCode}');
        return null;
      }

      // Parse HTML content
      final document = html_parser.parse(response.body);
      
      // Extract metadata
      final preview = _extractMetadata(url, document);
      
      // Cache the result
      _addToCache(url, preview);
      
      _logger.d('Link preview generated for: $url');
      return preview;
    } catch (e) {
      _logger.e('Failed to generate link preview for $url: $e');
      return null;
    }
  }

  /// Extract metadata from HTML document
  LinkPreviewModel _extractMetadata(String url, dynamic document) {
    // Extract title
    String? title = _extractTitle(document);
    
    // Extract description
    String? description = _extractDescription(document);
    
    // Extract image
    String? imageUrl = _extractImage(document, url);
    
    // Extract site name
    String? siteName = _extractSiteName(document, url);
    
    // Extract favicon
    String? faviconUrl = _extractFavicon(document, url);

    return LinkPreviewModel(
      url: url,
      title: title,
      description: description,
      imageUrl: imageUrl,
      siteName: siteName,
      faviconUrl: faviconUrl,
      timestamp: DateTime.now(),
    );
  }

  /// Extract title from document
  String? _extractTitle(dynamic document) {
    // Try Open Graph title first
    var titleElement = document.querySelector('meta[property="og:title"]');
    if (titleElement != null) {
      return titleElement.attributes['content']?.trim();
    }

    // Try Twitter title
    titleElement = document.querySelector('meta[name="twitter:title"]');
    if (titleElement != null) {
      return titleElement.attributes['content']?.trim();
    }

    // Try regular title tag
    titleElement = document.querySelector('title');
    if (titleElement != null) {
      return titleElement.text?.trim();
    }

    return null;
  }

  /// Extract description from document
  String? _extractDescription(dynamic document) {
    // Try Open Graph description first
    var descElement = document.querySelector('meta[property="og:description"]');
    if (descElement != null) {
      return descElement.attributes['content']?.trim();
    }

    // Try Twitter description
    descElement = document.querySelector('meta[name="twitter:description"]');
    if (descElement != null) {
      return descElement.attributes['content']?.trim();
    }

    // Try meta description
    descElement = document.querySelector('meta[name="description"]');
    if (descElement != null) {
      return descElement.attributes['content']?.trim();
    }

    return null;
  }

  /// Extract image from document
  String? _extractImage(dynamic document, String baseUrl) {
    // Try Open Graph image first
    var imageElement = document.querySelector('meta[property="og:image"]');
    if (imageElement != null) {
      final imageUrl = imageElement.attributes['content'];
      return _resolveUrl(imageUrl, baseUrl);
    }

    // Try Twitter image
    imageElement = document.querySelector('meta[name="twitter:image"]');
    if (imageElement != null) {
      final imageUrl = imageElement.attributes['content'];
      return _resolveUrl(imageUrl, baseUrl);
    }

    // Try to find first image in content
    imageElement = document.querySelector('img');
    if (imageElement != null) {
      final imageUrl = imageElement.attributes['src'];
      return _resolveUrl(imageUrl, baseUrl);
    }

    return null;
  }

  /// Extract site name from document
  String? _extractSiteName(dynamic document, String url) {
    // Try Open Graph site name first
    var siteElement = document.querySelector('meta[property="og:site_name"]');
    if (siteElement != null) {
      return siteElement.attributes['content']?.trim();
    }

    // Try to extract from URL
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Extract favicon from document
  String? _extractFavicon(dynamic document, String baseUrl) {
    // Try various favicon selectors
    final selectors = [
      'link[rel="icon"]',
      'link[rel="shortcut icon"]',
      'link[rel="apple-touch-icon"]',
      'link[rel="apple-touch-icon-precomposed"]',
    ];

    for (final selector in selectors) {
      final faviconElement = document.querySelector(selector);
      if (faviconElement != null) {
        final faviconUrl = faviconElement.attributes['href'];
        return _resolveUrl(faviconUrl, baseUrl);
      }
    }

    // Default favicon location
    try {
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.host}/favicon.ico';
    } catch (e) {
      return null;
    }
  }

  /// Resolve relative URL to absolute URL
  String? _resolveUrl(String? url, String baseUrl) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      if (uri.isAbsolute) {
        return url;
      }

      final baseUri = Uri.parse(baseUrl);
      return baseUri.resolve(url).toString();
    } catch (e) {
      return null;
    }
  }

  /// Validate if string is a valid URL
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Add preview to cache
  void _addToCache(String url, LinkPreviewModel preview) {
    // Remove oldest entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[url] = preview;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _logger.d('Link preview cache cleared');
  }

  /// Get cache size
  int get cacheSize => _cache.length;

  /// Check if URL is in cache
  bool isInCache(String url) => _cache.containsKey(url);

  /// Extract URLs from text
  List<String> extractUrls(String text) {
    final urlRegex = RegExp(
      r'https?://(?:[-\w.])+(?:\:[0-9]+)?(?:/(?:[\w/_.])*(?:\?(?:[\w&=%.])*)?(?:\#(?:[\w.])*)?)?',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  /// Generate previews for all URLs in text
  Future<List<LinkPreviewModel>> generatePreviewsForText(String text) async {
    final urls = extractUrls(text);
    final previews = <LinkPreviewModel>[];

    for (final url in urls) {
      final preview = await generatePreview(url);
      if (preview != null) {
        previews.add(preview);
      }
    }

    return previews;
  }

  /// Check if text contains URLs
  bool containsUrls(String text) {
    return extractUrls(text).isNotEmpty;
  }
}
