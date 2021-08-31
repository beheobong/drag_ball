part of 'drag_ball.dart';

class DragballPosition {
  final double top;
  final bool isRight;
  final bool isHide;

  const DragballPosition(
      {this.top = 100, this.isRight = true, this.isHide = false});

  DragballPosition copyWith({
    double? top,
    bool? isRight,
    bool? isHide,
  }) =>
      DragballPosition(
        top: top ?? this.top,
        isRight: isRight ?? this.isRight,
        isHide: isHide ?? this.isHide,
      );

  factory DragballPosition.fromJSON(Map<String, dynamic> json) =>
      DragballPosition(
        top: json['top'] ?? 100,
        isRight: json['isRight'] ?? false,
        isHide: json['isHide'] ?? false,
      );

  @override
  String toString() {
    return '{"top": $top, "isRight": $isRight, "isHide": $isHide}';
  }
}
