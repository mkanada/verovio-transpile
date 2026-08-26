import 'package:test/test.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart'
    show AttLinking;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/interfaces/linking_interface.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/object.dart';

void main() {
  group('Doc / Pages / Page', () {
    test('builds a pages-based document tree', () {
      final doc = Doc();
      final pages = Pages();
      final page1 = Page();
      final page2 = Page();

      expect(doc.addChild(pages), isTrue);
      expect(pages.addChild(page1), isTrue);
      expect(pages.addChild(page2), isTrue);

      expect(doc.getPages(), same(pages));
      expect(doc.getPageCount(), 2);
      expect(doc.hasPage(0), isTrue);
      expect(doc.hasPage(1), isTrue);
      expect(doc.hasPage(2), isFalse);
      expect(page1.getPageIdx(), 0);
      expect(page2.getPageIdx(), 1);
    });

    test('doc accepts mdiv or pages children only', () {
      final doc = Doc();
      expect(doc.addChild(Mdiv()), isTrue);
      expect(doc.addChild(Note()), isFalse);
      expect(doc.childCount, 1);
    });

    test('page accepts systems and page elements', () {
      final page = Page();
      expect(page.isSupportedChild(ClassId.system), isTrue);
      expect(page.isSupportedChild(ClassId.score), isTrue,
          reason: 'score is within the page element range');
      expect(page.isSupportedChild(ClassId.pb), isFalse,
          reason: 'pb is a system element, not a page element');
      expect(page.isSupportedChild(ClassId.measure), isFalse);
      expect(page.isSupportedChild(ClassId.staff), isFalse);
    });

    test('doc type accessors and reset', () {
      final doc = Doc();
      expect(doc.isRaw(), isTrue);

      doc.setType(DocType.rendering);
      expect(doc.isRendering(), isTrue);
      expect(doc.isRaw(), isFalse);
      expect(doc.isFacs(), isFalse);
      expect(doc.isTranscription(), isFalse);

      doc.setMensuralMusicOnly(true);
      doc.setNeumeLines(true);
      doc.setMarkup(markupAnalyticalTie);
      expect(doc.isMensuralMusicOnly(), isTrue);
      expect(doc.isNeumeLines(), isTrue);
      expect(doc.markup & markupAnalyticalTie, markupAnalyticalTie);

      doc.resetToSerialization();
      expect(doc.getType(), DocType.raw);
      expect(doc.childCount, 0);
      expect(doc.isCastOff(), isTrue);
    });
  });

  group('copyFrom completeness', () {
    test('copies drawing state of layer elements', () {
      final note = Note();
      note.drawingXRel = 42;
      note.drawingYRel = -7;
      note.drawingCueSize = true;
      note.crossStaff = Object();
      note.crossLayer = Object();

      final copy = Note();
      copy.copyFrom(note);

      expect(copy.drawingXRel, 42);
      expect(copy.drawingYRel, -7);
      expect(copy.drawingCueSize, isTrue);
      expect(copy.crossStaff, same(note.crossStaff));
      expect(copy.crossLayer, same(note.crossLayer));
    });

    test('copies floating object drawing state', () {
      final dir = _FakeFloating();
      dir.drawingGrpId = 5;
      dir.maxDrawingYRel = 100;
      dir.drawingXRel = 11;
      dir.drawingYRel = 22;

      final copy = _FakeFloating();
      copy.copyFrom(dir);

      expect(copy.drawingGrpId, 5);
      expect(copy.maxDrawingYRel, 100);
      expect(copy.drawingXRel, 11);
      expect(copy.drawingYRel, 22);
    });

    test('clone adds a corresp back-link for linking interfaces', () {
      final source = _LinkingProbe()..id = 'orig';
      final clone = source.clone();
      expect(clone.hasInterface(InterfaceId.linking), isTrue);
      expect((clone as AttLinking).corresp, '#orig');

      // A full copyFrom of a parent clones children with back-links.
      final parentSource = _ContainerProbe();
      final childSource = _LinkingProbe()..id = 'child';
      parentSource.addChild(childSource);

      final parentClone = _ContainerProbe();
      parentClone.copyFrom(parentSource);
      expect(parentClone.childCount, 1);
      final clonedChild = parentClone.getChild(0)!;
      expect(clonedChild.id, isNot('child'));
      expect((clonedChild as AttLinking).corresp, '#child');
    });
  });
}

class _FakeFloating extends FloatingObject {}

class _LinkingProbe extends LayerElement with AttLinking, LinkingInterface {
  _LinkingProbe() : super(ClassId.note) {
    registerInterfaces([InterfaceId.linking]);
  }

  @override
  ClassId get classId => ClassId.note;

  @override
  String get className => 'linkingProbe';

  @override
  Object clone() {
    final copy = _LinkingProbe();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) => false;
}

class _ContainerProbe extends Object {
  @override
  ClassId get classId => ClassId.measure;

  @override
  String get className => 'containerProbe';

  @override
  bool isSupportedChild(ClassId classId) => true;

  @override
  Object clone() {
    final copy = _ContainerProbe();
    copy.copyFrom(this);
    return copy;
  }
}
