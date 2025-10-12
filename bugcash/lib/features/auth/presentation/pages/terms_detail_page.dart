import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 약관 상세보기 페이지
class TermsDetailPage extends StatelessWidget {
  final String title;
  final String content;

  const TermsDetailPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Markdown(
          data: content,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            h1: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.5,
            ),
            h2: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.4,
            ),
            h3: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.3,
            ),
            p: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
            listBullet: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            strong: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            blockSpacing: 12,
            listIndent: 24,
          ),
          padding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
