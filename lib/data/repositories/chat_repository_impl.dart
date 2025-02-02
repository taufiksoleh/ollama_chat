import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../config/api_config.dart';

class SearchResult {
  final String title;
  final String snippet;
  final String url;

  SearchResult({required this.title, required this.snippet, required this.url});
}

class ChatRepositoryImpl implements ChatRepository {
  final String baseUrl = 'http://localhost:11434';
  final List<Message> _messages = [];
  final _uuid = Uuid();

  Future<String?> _fetchWebContent(String url) async {
    try {
      // Use a proxy service to bypass CORS
      final proxyUrl =
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'Accept': '*/*',
        },
      );
      if (response.statusCode == 200 &&
          !response.body.contains("Sorry, you have been blocked")) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('text/html') ||
            contentType.contains('text/plain')) {
          return response.body;
        }
      }
    } catch (e) {
      print('Failed to fetch content from $url: $e');
    }
    return null;
  }

  String _summarizeContent(String content) {
    // Remove script tags and their content
    content =
        content.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>'), '');
    // Remove style tags and their content
    content = content.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>'), '');
    // Remove all HTML comments
    content = content.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
    // Extract content from body tag if present
    final bodyMatch =
        RegExp(r'<body[^>]*>([\s\S]*?)<\/body>').firstMatch(content);
    if (bodyMatch != null) {
      content = bodyMatch.group(1) ?? content;
    }
    // Remove remaining HTML tags
    content = content.replaceAll(RegExp(r'<[^>]+>'), '');
    // Convert HTML entities
    content = content
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#39;'), "'");
    // Remove extra whitespace and normalize
    content = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return content;
  }

  @override
  Future<List<SearchResult>> _searchWeb(String query) async {
    final url = 'https://www.googleapis.com/customsearch/v1';
    final params = {
      'key': ApiConfig.googleApiKey,
      'cx': ApiConfig.googleSearchEngineId,
      'q': query,
      'num': '3',
    };

    final uri = Uri.parse(url).replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to search: ${response.statusCode}');
    }

    final jsonResponse = jsonDecode(response.body);
    final results = <SearchResult>[];

    if (jsonResponse['items'] != null) {
      for (var item in jsonResponse['items']) {
        final url = item['link'] ?? '';
        final snippet = item['snippet'] ?? '';

        results.add(SearchResult(
          title: item['title'] ?? '',
          snippet: snippet,
          url: url,
        ));
      }
    }

    return results;
  }

  Stream<String> generateResponse(String prompt,
      {bool useWebSearch = true}) async* {
    List<SearchResult> searchResults = [];
    if (useWebSearch) {
      try {
        searchResults = await _searchWeb(prompt);
      } catch (e) {
        print('Search failed: $e');
      }
    }

    final enhancedPrompt = useWebSearch && searchResults.isNotEmpty
        ? '''
$prompt

Relevant search results:
${searchResults.map((r) => '${r.title}\n${r.snippet}\n${r.url}\n').join('\n')}

Please provide a response based on the above information.
'''
        : prompt;

    print("enhancedPrompt : ${enhancedPrompt}");

    final request = http.Request('POST', Uri.parse('$baseUrl/api/generate'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'prompt': enhancedPrompt,
      'stream': true,
      'model': 'deepseek-r1:1.5b'
    });

    final response = await http.Client().send(request);

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      if (chunk.trim().isNotEmpty) {
        try {
          final jsonResponse = jsonDecode(chunk);
          if (jsonResponse['response'] != null) {
            yield jsonResponse['response'];
          }
        } catch (e) {
          // Skip invalid JSON chunks
          continue;
        }
      }
    }
  }

  @override
  Future<void> saveMessage(Message message) async {
    _messages.add(message);
  }

  @override
  List<Message> getMessages() {
    return List.unmodifiable(_messages);
  }
}
