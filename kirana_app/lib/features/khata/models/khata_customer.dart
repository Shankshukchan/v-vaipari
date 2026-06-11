class KhataCustomer {
  final String id;
  final String name;
  final String phoneNumber;
  final double totalDue;

  KhataCustomer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.totalDue,
  });

  // Converts backend JSON response to a Flutter object
  factory KhataCustomer.fromJson(Map<String, dynamic> json) {
    return KhataCustomer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      totalDue: (json['totalDue'] ?? 0.0).toDouble(),
    );
  }

  // Converts Flutter object data back to JSON to send to the backend
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'totalDue': totalDue,
    };
  }
}