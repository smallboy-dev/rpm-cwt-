import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawingPoint {
  final Offset? offset;
  final double? strokeWidth;
  final Color? color;

  DrawingPoint({this.offset, this.strokeWidth, this.color});

  Map<String, dynamic> toJson() => {
    'dx': offset?.dx,
    'dy': offset?.dy,
    'width': strokeWidth,
    'color': color?.value,
  };

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    if (json['dx'] == null) return DrawingPoint();
    return DrawingPoint(
      offset: Offset(json['dx'], json['dy']),
      strokeWidth: json['width'],
      color: Color(json['color']),
    );
  }

  Paint get paint => Paint()
    ..color = color ?? Colors.blue
    ..strokeCap = StrokeCap.round
    ..strokeWidth = strokeWidth ?? 5.0;
}

class CollaborationService extends GetxService {
  SupabaseClient get _supabase => Supabase.instance.client;
  RealtimeChannel? _channel;

  // Whiteboard State
  var whiteboardPoints = <DrawingPoint>[].obs;
  var currentColor = Colors.blue.obs;
  var strokeWidth = 5.0.obs;

  // Shared Code State
  var sharedCode = 'void main() => print("Live Code!");'.obs;

  void initProject(String projectId) {
    _channel?.unsubscribe();
    _channel = _supabase.channel('project_collab_$projectId');

    _channel
        ?.onBroadcast(
          event: 'drawing',
          callback: (payload) {
            final point = DrawingPoint.fromJson(payload);
            whiteboardPoints.add(point);
          },
        )
        .onBroadcast(
          event: 'code',
          callback: (payload) {
            sharedCode.value = payload['content'];
          },
        )
        .onBroadcast(
          event: 'clear',
          callback: (_) {
            whiteboardPoints.clear();
          },
        )
        .subscribe();
  }

  void addPoint(Offset offset, {bool broadcast = true}) {
    final point = DrawingPoint(
      offset: offset,
      strokeWidth: strokeWidth.value,
      color: currentColor.value,
    );
    whiteboardPoints.add(point);
    if (broadcast) {
      // ignore: undefined_method
      _channel?.sendBroadcastMessage(event: 'drawing', payload: point.toJson());
    }
  }

  void endLine({bool broadcast = true}) {
    whiteboardPoints.add(DrawingPoint());
    if (broadcast) {
      // ignore: undefined_method
      _channel?.sendBroadcastMessage(event: 'drawing', payload: {'dx': null});
    }
  }

  void clearWhiteboard() {
    whiteboardPoints.clear();
    // ignore: undefined_method
    _channel?.sendBroadcastMessage(event: 'clear', payload: {});
  }

  void updateCode(String newCode) {
    sharedCode.value = newCode;
    // ignore: undefined_method
    _channel?.sendBroadcastMessage(
      event: 'code',
      payload: {'content': newCode},
    );
  }
}
