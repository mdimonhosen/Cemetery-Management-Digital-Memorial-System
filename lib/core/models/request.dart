class Request {
  final String id;
  final String userId;
  final String plotId;
  final String status;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  Request({
    required this.id,
    required this.userId,
    required this.plotId,
    required this.status,
    this.details,
    required this.createdAt,
  });

  factory Request.fromMap(Map<String, dynamic> map) {
    return Request(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      plotId: map['plot_id'] ?? '',
      status: map['status'] ?? 'pending',
      details: map['details'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
