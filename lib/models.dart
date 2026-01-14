class User {
  final int id;
  final String email;
  final String? profileImage;

  User({required this.id, required this.email, this.profileImage});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      profileImage: json['profile_image'],
    );
  }
}

class Post {
  final int id;
  final String title;
  final String content;
  final int votes;
  final User owner;
  final String? imageUrl;

  Post(
      {required this.id,
      required this.title,
      required this.content,
      required this.votes,
      required this.owner,
      this.imageUrl,});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['post']['id'],
      title: json['post']['title'],
      content: json['post']['content'],
      owner: User.fromJson(json['post']['owner']),
      votes: json['votes'],
      imageUrl: json['post']['image_url'],
    );
  }
}
