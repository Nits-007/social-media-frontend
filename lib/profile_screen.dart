import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:socialmedia/post_card.dart';
import '../auth_provider.dart';
import '../api_service.dart';
import '../models.dart';
import 'home_screen.dart'; // To use PostCard

class ProfileScreen extends StatefulWidget {
  final int? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  User? _profileUser;
  bool _isOwnProfile = false;
  List<Post> _profilePosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final me = await _api.getCurrentUser();
      User targetUser;

      if (widget.userId == null || widget.userId == me.id) {
        targetUser = me;
        _isOwnProfile = true;
      } else {
        targetUser = await _api.getUserById(widget.userId!);
        _isOwnProfile = false;
      }

      final allPosts = await _api.getPosts();
      // Filter posts for this user
      final userPosts =
          allPosts.where((p) => p.owner.id == targetUser.id).toList();

      if (mounted) {
        setState(() {
          _profileUser = targetUser;
          _profilePosts = userPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        await _api.uploadProfileImage(image);
        await _loadData(); // Reload to show new image
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _deletePost(int postId) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Delete Post"),
              content: const Text("Are you sure? This cannot be undone."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Delete",
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _api.deletePost(postId);
        await _loadData();
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Failed to delete")));
      }
    }
  }

  // --- CORRECTED EDIT DIALOG WITH IMAGE SUPPORT ---
  void _showEditDialog(Post post) {
    final titleCtrl = TextEditingController(text: post.title);
    final contentCtrl = TextEditingController(text: post.content);
    XFile? newImageFile; // State for the new image inside dialog

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          // StatefulBuilder is CRITICAL here to update the dialog UI when image is picked
          builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Edit Post"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: "Title")),
              TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: "Content"),
                  maxLines: 3),
              const SizedBox(height: 10),

              // Image Picker Button
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? img =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (img != null) {
                        setDialogState(() {
                          newImageFile = img;
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: Text(newImageFile == null
                        ? "Change Image"
                        : "Image Selected"),
                  ),
                  if (newImageFile != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.check_circle, color: Colors.green),
                    )
                ],
              )
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  // HERE IS THE FIX: Pass 'newImageFile' (which might be null or a file)
                  await _api.updatePost(
                      post.id, titleCtrl.text, contentCtrl.text, newImageFile);
                  _loadData();
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Update failed")));
                }
              },
              child: const Text("Save"),
            )
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _handleLogout,
              tooltip: "Logout",
            )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Profile Info Card
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: (_profileUser?.profileImage != null)
                            ? CachedNetworkImageProvider(
                                _profileUser!.profileImage!)
                            : null,
                        child: _profileUser?.profileImage == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                      // Update Profile Image Button
                      if (_isOwnProfile)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickAndUploadImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _profileUser?.email ?? "User",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            "My Posts",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // 2. Posts List
          _profilePosts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("No posts created yet.")),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _profilePosts.length,
                  itemBuilder: (context, index) {
                    final post = _profilePosts[index];
                    return PostCard(
                      post: post,
                      onVote: (id, dir) {}, // Voting disabled on profile
                      showOwnerControls:
                          _isOwnProfile, // Enable edit/delete controls
                      onDelete: () => _deletePost(post.id),
                      onEdit: () => _showEditDialog(post),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
