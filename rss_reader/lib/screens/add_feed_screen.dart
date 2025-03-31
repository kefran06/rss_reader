import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/feed_provider.dart';
import '../models/feed_model.dart';

class AddFeedScreen extends StatefulWidget {
  const AddFeedScreen({super.key});

  @override
  State<AddFeedScreen> createState() => _AddFeedScreenState();
}

class _AddFeedScreenState extends State<AddFeedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? _buildMaterialAddFeedScreen()
        : _buildCupertinoAddFeedScreen();
  }

  Widget _buildMaterialAddFeedScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add RSS Feed'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Feed Title',
                  hintText: 'Enter a name for this feed',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Feed URL',
                  hintText: 'https://example.com/rss',
                  border: OutlineInputBorder(),
                  helperText: 'Enter a valid RSS or Atom feed URL',
                ),
                keyboardType: TextInputType.url,
                validator: _validateUrl,
                onChanged: _clearErrorOnChange,
              ),
              const SizedBox(height: 24),
              _buildErrorMessage(),
              ElevatedButton(
                onPressed: _isLoading ? null : _addFeed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Add Feed'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(height: 16),
              _buildExampleFeedsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoAddFeedScreen() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add RSS Feed'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                CupertinoFormSection(
                  header: const Text('Feed Information'),
                  children: [
                    CupertinoTextFormFieldRow(
                      controller: _titleController,
                      prefix: const Text('Title'),
                      placeholder: 'Enter a name for this feed',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    CupertinoTextFormFieldRow(
                      controller: _urlController,
                      prefix: const Text('URL'),
                      placeholder: 'https://example.com/rss',
                      keyboardType: TextInputType.url,
                      validator: _validateUrl,
                      onChanged: _clearErrorOnChange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildErrorMessage(),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: CupertinoColors.systemBlue,
                  onPressed: _isLoading ? null : _addFeed,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('Add Feed'),
                ),
                const SizedBox(height: 16),
                _buildExampleFeedsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a URL';
    }
    
    // Remove @ prefix if it exists
    String cleanValue = value;
    if (cleanValue.startsWith('@')) {
      cleanValue = cleanValue.substring(1);
    }
    
    // Add protocol if missing
    if (!cleanValue.startsWith('http://') && !cleanValue.startsWith('https://')) {
      cleanValue = 'https://$cleanValue';
    }
    
    try {
      final uri = Uri.parse(cleanValue);
      if (!uri.isAbsolute) {
        return 'Please enter a valid URL';
      }
    } catch (e) {
      return 'Invalid URL format';
    }
    
    return null;
  }

  void _clearErrorOnChange(String value) {
    // Clear error message when user types
    if (_errorMessage.isNotEmpty) {
      setState(() {
        _errorMessage = '';
      });
    }
  }

  Widget _buildErrorMessage() {
    if (_errorMessage.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        _errorMessage,
        style: TextStyle(
          color: kIsWeb ? Colors.red : CupertinoColors.systemRed,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildExampleFeedsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Example RSS Feeds:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: kIsWeb ? Colors.black87 : CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        _buildExampleFeedCard(
          title: 'NASA Breaking News',
          url: 'https://www.nasa.gov/feed/rss/breaking-news',
        ),
        _buildExampleFeedCard(
          title: 'CSS Tricks',
          url: 'https://css-tricks.com/feed/',
        ),
        _buildExampleFeedCard(
          title: 'The Verge',
          url: 'https://www.theverge.com/rss/index.xml',
        ),
        _buildExampleFeedCard(
          title: 'Hacker News',
          url: 'https://news.ycombinator.com/rss',
        ),
        _buildExampleFeedCard(
          title: 'TechCrunch',
          url: 'https://techcrunch.com/feed/',
        ),
        _buildExampleFeedCard(
          title: 'Wired',
          url: 'https://www.wired.com/feed/rss',
        ),
      ],
    );
  }

  Widget _buildExampleFeedCard({
    required String title,
    required String url,
  }) {
    if (kIsWeb) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(title),
          subtitle: Text(url),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _isLoading
                ? null
                : () {
                    _titleController.text = title;
                    _urlController.text = url;
                  },
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: CupertinoListTile(
          title: Text(title),
          subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.add_circled),
            onPressed: _isLoading
                ? null
                : () {
                    _titleController.text = title;
                    _urlController.text = url;
                  },
          ),
        ),
      );
    }
  }

  Future<void> _addFeed() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final provider = Provider.of<FeedProvider>(context, listen: false);
        
        await provider.addFeed(Feed(
          title: _titleController.text.trim(),
          url: _urlController.text.trim(),
        ));
        
        if (provider.error.isNotEmpty) {
          setState(() {
            _errorMessage = provider.error;
            _isLoading = false;
          });
          return;
        }
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to add feed: $e';
          _isLoading = false;
        });
      }
    }
  }
} 