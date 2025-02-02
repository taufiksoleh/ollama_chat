import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../domain/entities/message.dart';
import '../../data/repositories/chat_repository_impl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repository = ChatRepositoryImpl();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = Uuid();
  bool _isGenerating = false;
  bool _useWebSearch = true;
  String _currentResponse = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ollama Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Row(
            children: [
              const Text('Web Search'),
              Switch(
                value: _useWebSearch,
                onChanged: (value) {
                  setState(() {
                    _useWebSearch = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _repository.getMessages().length,
              itemBuilder: (context, index) {
                final message = _repository.getMessages()[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _MessageBubble(message: message),
                );
              },
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
            ),
          ),
          if (_isGenerating && _currentResponse.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: _MessageBubble(
                message: Message(
                  id: 'temp',
                  content: _currentResponse,
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    onSubmitted: _isGenerating ? null : (_) => _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isGenerating ? null : _sendMessage,
                  icon:
                      Icon(_isGenerating ? Icons.hourglass_empty : Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final prompt = _textController.text.trim();
    if (prompt.isEmpty) return;

    final userMessage = Message(
      id: _uuid.v4(),
      content: prompt,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _textController.clear();
      _isGenerating = true;
      _currentResponse = '';
    });

    await _repository.saveMessage(userMessage);

    try {
      await for (final chunk in _repository.generateResponse(prompt,
          useWebSearch: _useWebSearch)) {
        setState(() {
          _currentResponse += chunk;
        });
        
        // Scroll to bottom after each chunk
        await Future.delayed(const Duration(milliseconds: 50));
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }

      final assistantMessage = Message(
        id: _uuid.v4(),
        content: _currentResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      await _repository.saveMessage(assistantMessage);
    } finally {
      setState(() {
        _isGenerating = false;
        _currentResponse = '';
      });
    }
  }
}

class _MessageBubble extends StatefulWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  String _processThinkTags(String content) {
    final thinkRegex = RegExp(r'<think>(.*?)</think>', dotAll: true);
    return content.replaceAllMapped(thinkRegex, (match) {
      return '> 💭 **Thinking Process**\n${match.group(1)!.trim()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = widget.message.isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
    final textColor =
        widget.message.isUser || isDarkMode ? Colors.white : Colors.black;

    final processedContent = _processThinkTags(widget.message.content);

    return Align(
      alignment:
          widget.message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          minWidth: 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              child: MarkdownBody(
                data: processedContent,
                softLineBreak: true,
                fitContent: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: textColor),
                  code: TextStyle(
                    color: textColor,
                    backgroundColor: Colors.black12,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  codeblockPadding: const EdgeInsets.all(8),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  h1: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  h2: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  h3: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  blockquote: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontStyle: FontStyle.italic),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: textColor.withOpacity(0.5), width: 4),
                    ),
                  ),
                  blockquotePadding:
                      const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  listBullet: TextStyle(color: textColor),
                  tableHead:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  tableBody: TextStyle(color: textColor),
                  tableBorder:
                      TableBorder.all(color: textColor.withOpacity(0.3)),
                  tableCellsPadding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
