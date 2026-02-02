enum CallStatus { dialing, active, ended, missed, rejected }

enum CallType { voice, video }

class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String receiverId;
  final String receiverName;
  final CallType type;
  final CallStatus status;
  final DateTime timestamp;
  final Duration? duration;

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
    required this.type,
    this.status = CallStatus.dialing,
    required this.timestamp,
    this.duration,
  });

  CallModel copyWith({CallStatus? status, Duration? duration}) {
    return CallModel(
      id: id,
      callerId: callerId,
      callerName: callerName,
      receiverId: receiverId,
      receiverName: receiverName,
      type: type,
      status: status ?? this.status,
      timestamp: timestamp,
      duration: duration ?? this.duration,
    );
  }
}
