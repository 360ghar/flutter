class StaticPageModel {
  final String title;
  final String content;

  StaticPageModel({required this.title, required this.content});

  factory StaticPageModel.fromDynamic(Map<String, dynamic> json, {String fallbackTitle = ''}) {
    final Map<String, dynamic> root = Map<String, dynamic>.from(json);
    final Map<String, dynamic> doc = root['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(root['data'])
        : root;

    final String title = (doc['title'] ?? doc['name'] ?? doc['page_title'] ?? fallbackTitle).toString();
    final dynamic rawContent = doc['content'] ?? doc['html'] ?? doc['body'] ?? doc['description'] ?? doc['text'] ?? '';
    final String content = rawContent?.toString() ?? '';

    return StaticPageModel(title: title, content: content);
  }
}

