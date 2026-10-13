class SecuritySession {
  const SecuritySession({
    required this.device,
    required this.location,
    required this.date,
    required this.lastActive,
    required this.status,
  });

  final String device;
  final String location;
  final String date;
  final String lastActive;
  final String status;
}
