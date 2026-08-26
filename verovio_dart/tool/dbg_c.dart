import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';

void main() {
  final score = Score();
  final section = Section();
  final m2 = Measure();
  score.addChild(section);
  section.addChild(m2);
  print('m2.parent=${m2.parent?.className} classId=${m2.parent?.classId}');
  print('score.classId=${score.classId}');
  final fa = m2.getFirstAncestor(ClassId.score);
  print('fa=${fa?.className}');
}
