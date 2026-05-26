class LinkedDoctorInfo {
  const LinkedDoctorInfo({
    required this.doctorId,
    required this.doctorName,
  });

  final String doctorId;
  final String doctorName;
}

class PatientChatSubscription {
  const PatientChatSubscription({
    required this.status,
    this.currentPeriodEnd,
  });

  final String status;
  final DateTime? currentPeriodEnd;

  bool get isActive {
    if (status != 'active') return false;
    final end = currentPeriodEnd;
    if (end == null) return true;
    return end.isAfter(DateTime.now().toUtc());
  }
}

class ChatThread {
  const ChatThread({
    required this.id,
    required this.doctorId,
    required this.patientId,
  });

  final String id;
  final String doctorId;
  final String patientId;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.imageStoragePath,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final String? imageStoragePath;

  bool get hasImage =>
      imageStoragePath != null && imageStoragePath!.trim().isNotEmpty;

  bool get hasText => body.trim().isNotEmpty;
}
