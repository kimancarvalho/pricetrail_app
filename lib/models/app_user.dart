class AppUser {
  final String email;
  final String name;
  final String location;
  final String transport;
  final String? photoUrl;
  final double lifetimeSavings;
  final double monthlySavings;

  AppUser({
    required this.email,
    required this.name,
    required this.location,
    required this.transport,
    this.photoUrl,
    required this.lifetimeSavings,
    required this.monthlySavings,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      email: data['email'] ?? '',
      name: data['name'] ?? 'User',
      location: data['location'] ?? '',
      transport: data['transport'] ?? '',
      photoUrl: data['photoUrl'],
      lifetimeSavings: (data['lifetimeSavings'] ?? 0).toDouble(),
      monthlySavings: (data['monthlySavings'] ?? 0).toDouble(),
    );
  }
}
