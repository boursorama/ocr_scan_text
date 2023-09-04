import 'dart:math';
import 'dart:ui';

class MathHelper {
  /// Return true if two segments intersect
  static bool doSegmentsIntersect(Offset p1, Offset p2, Offset q1, Offset q2) {
    double dx1 = p2.dx - p1.dx;
    double dy1 = p2.dy - p1.dy;
    double dx2 = q2.dx - q1.dx;
    double dy2 = q2.dy - q1.dy;

    /// crossProduct is the cross product of the vectors formed by the segments.
    double crossProduct = dx1 * dy2 - dy1 * dx2;
    if (crossProduct == 0) {
      // The segments are parallel, they do not intersect
      return false;
    }

    /// t represents the position along the segment p1-p2 where the segments intersect.
    /// If t is between 0 and 1, this means that the point of intersection is located on the segment p1-p2.
    double t1 = ((q1.dx - p1.dx) * dy2 - (q1.dy - p1.dy) * dx2) / crossProduct;

    /// u represents the position along segment q1-q2 where the segments intersect.
    /// If u is between 0 and 1, it means that the point of intersection is located on the segment q1-q2.
    double u1 = ((q1.dx - p1.dx) * dy1 - (q1.dy - p1.dy) * dx1) / crossProduct;

    /// The points p1 and q1 are inverted, this makes it possible to check whether the segment q1-q2 is
    /// in the opposite direction with respect to the segment p1-p2. This inversion makes it possible to correct
    /// the signs of the values of u and to avoid incorrect results in certain specific cases.
    double t2 = ((q1.dx - p1.dx) * dy2 - (q1.dy - p1.dy) * dx2) / crossProduct;
    double u2 = ((p1.dx - q1.dx) * dy1 - (p1.dy - q1.dy) * dx1) / crossProduct;

    if (t1 >= 0 && t1 <= 1 && u1 >= 0 && u1 <= 1 ||
        t2 >= 0 && t2 <= 1 && u2 >= 0 && u2 <= 1) {
      // Segments intersect at a point
      return true;
    }

    // Segments do not intersect
    return false;
  }

  /// Return an angle between 2 points
  static double retrieveAngle(Offset a, Offset b) {
    double blockAngle = atan2(
      b.dy - a.dy,
      b.dx - a.dx,
    );

    return blockAngle;
  }

  /// Return true if a value is between 2 other values
  static bool isBetween(num value, num from, num to) {
    return from < value && value < to;
  }
}
