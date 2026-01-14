import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Import Dio for error handling
import 'package:provider/provider.dart';
import '../api_service.dart';
import '../models.dart';
import '../theme_provider.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();

  // 1. Change: Use a List instead of a Future
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // 2. Load posts initially
  Future<void> _loadPosts() async {
    try {
      final posts = await _api.getPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Updated Vote Logic: Updates local list ONLY (No scroll jump)
  void _vote(int postId, int direction) async {
    try {
      await _api.votePost(postId, direction);

      // SUCCESS: Update the specific post in the local list
      setState(() {
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final oldPost = _posts[index];

          // Calculate new vote count (Like adds 1, Dislike removes 1)
          final int newVotes = oldPost.votes + (direction == 1 ? 1 : -1);

          // Create a new Post object with updated votes
          _posts[index] = Post(
            id: oldPost.id,
            title: oldPost.title,
            content: oldPost.content,
            votes: newVotes, // <--- The update
            owner: oldPost.owner,
            imageUrl: oldPost.imageUrl,
          );
        }
      });
    } on DioException catch (e) {
      // ERROR HANDLING (As we did before)
      if (mounted) {
        String message = "Action failed";
        if (e.response?.statusCode == 409 || e.response?.statusCode == 400) {
          message = (direction == 1) ? "Already liked" : "Already disliked";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message), duration: const Duration(seconds: 1)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not connect to server")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          "SocialFeed",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () =>
                themeProvider.toggleTheme(!themeProvider.isDarkMode),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreatePostScreen()));
          _loadPosts(); // Only refresh full list after creating a post
        },
        child: const Icon(Icons.add),
      ),
      // 4. Change: Use regular ListView instead of FutureBuilder
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              // Allow pull-to-refresh if user WANTS to reload
              onRefresh: _loadPosts,
              child: _posts.isEmpty
                  ? const Center(child: Text("No posts found."))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        return PostCard(
                          post: _posts[index],
                          onVote: _vote,
                          showOwnerControls: false,
                        );
                      },
                    ),
            ),
    );
  }
}
