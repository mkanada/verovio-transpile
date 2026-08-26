/// Port of `Point` and related small geometry types from
/// `include/vrv/devicecontextbase.h`.
library;

class Point {
  int x;
  int y;

  Point([this.x = 0, this.y = 0]);

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  Point operator +(Point p) => Point(x + p.x, y + p.y);
  Point operator -(Point p) => Point(x - p.x, y - p.y);

  void add(Point p) {
    x += p.x;
    y += p.y;
  }

  Point operator -() => Point(-x, -y);

  static Point min(Point p1, Point p2) =>
      Point(p1.x < p2.x ? p1.x : p2.x, p1.y < p2.y ? p1.y : p2.y);

  static Point max(Point p1, Point p2) =>
      Point(p1.x > p2.x ? p1.x : p2.x, p1.y > p2.y ? p1.y : p2.y);

  @override
  String toString() => 'Point($x, $y)';
}
