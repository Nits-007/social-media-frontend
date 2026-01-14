import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api_service.dart';
import '../models.dart';
import '../profile_screen.dart'; // Needed for navigation to profile

class PostCard extends StatelessWidget {
  final Post post;
  final Function(int, int) onVote;
  final bool showOwnerControls;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PostCard({
    super.key, 
    required this.post, 
    required this.onVote,
    this.showOwnerControls = false,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: post.owner.id))),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: (post.owner.profileImage?.isNotEmpty ?? false)
                        ? CachedNetworkImageProvider(post.owner.profileImage!)
                        : null,
                    child: (post.owner.profileImage?.isEmpty ?? true)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.owner.email.split('@')[0],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (showOwnerControls) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                    onPressed: onEdit,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ]
              ],
            ),
          ),

          // 2. Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.title.isNotEmpty)
                  Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Text(
                  post.content,
                  style: TextStyle(fontSize: 15, height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                ),
              ],
            ),
          ),
          
          // 3. Image
          const SizedBox(height: 10),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: post.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(height: 200, color: Colors.grey.withOpacity(0.1)),
              errorWidget: (context, url, error) => const SizedBox(),
            ),

          // 4. Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.blue),
                  onPressed: () => onVote(post.id, 1),
                ),
                Text("${post.votes}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.thumb_down_alt_outlined, color: Colors.red),
                  onPressed: () => onVote(post.id, 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}