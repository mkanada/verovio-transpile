/// Tests for 05-28 — TextLayoutElement 9-cell grid, heights and RunningElement.
library;

import 'package:test/test.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/text_elements.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';

// Helper to create a Rend with a given content height/width and place it into
// a TextLayoutElement cell. The content box is set via updateContentBBox*
// so that HasContentBB() is true and GetContentY2-Y1 / X2-X1 return the
// desired sizes.
Rend _makeRend(
    {required int height,
    required int width,
    Horizontalalignment? halign,
    Verticalalignment? valign}) {
  final rend = Rend();
  if (halign != null) rend.halign = halign;
  if (valign != null) rend.valign = valign;
  // X range 0..width, Y range 0..height (offsets from drawing pos)
  rend.updateContentBBoxX(0, width);
  rend.updateContentBBoxY(0, height);
  return rend;
}

void main() {
  group('05-28 TextLayoutElement — grade 9 células e geometria', () {
    test('1 — 9 células halign x valign com GetAlignmentPos incluindo defaults',
        () {
      // Pos = h + v where h: left=0 center=1 right=2 default left=0
      // and v: top=0 middle=3 bottom=6 default middle=3
      // Grid index = row*3+col following C++ i*3+j order (horiz + vert).
      final tle = TextLayoutElement();

      // 9 combinações
      expect(
          tle.getAlignmentPos(Horizontalalignment.left, Verticalalignment.top),
          0,
          reason: 'left(0)+top(0)=0');
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.center, Verticalalignment.top),
          1,
          reason: 'center(1)+top(0)=1');
      expect(
          tle.getAlignmentPos(Horizontalalignment.right, Verticalalignment.top),
          2,
          reason: 'right(2)+top(0)=2');
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.left, Verticalalignment.middle),
          3,
          reason: 'left(0)+middle(3)=3');
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.center, Verticalalignment.middle),
          4,
          reason: 'center(1)+middle(3)=4');
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.right, Verticalalignment.middle),
          5,
          reason: 'right(2)+middle(3)=5');
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.left, Verticalalignment.bottom),
          6,
          reason: 'left(0)+bottom(6)=6');
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.center, Verticalalignment.bottom),
          7,
          reason: 'center(1)+bottom(6)=7');
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.right, Verticalalignment.bottom),
          8,
          reason: 'right(2)+bottom(6)=8');

      // Defaults assimétricos: horizontal default = LEFT (0), vertical default = MIDDLE (3)
      // No C++ o primeiro switch default cai em POSITION_LEFT e o segundo em POSITION_MIDDLE.
      // Horizontal "desconhecido" (justify) -> LEFT, vertical "desconhecido" (baseline) -> MIDDLE
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.justify, Verticalalignment.top),
          0,
          reason: 'justify default LEFT(0)+top(0)=0');
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.left, Verticalalignment.baseline),
          3,
          reason: 'left(0)+baseline default MIDDLE(3)=3');
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.justify, Verticalalignment.baseline),
          3,
          reason: 'justify default LEFT(0)+baseline default MIDDLE(3)=3');
      expect(
          tle.getAlignmentPos(Horizontalalignment.none, Verticalalignment.none),
          3,
          reason: 'none horiz LEFT(0)+none vert MIDDLE(3)=3');
      // none vertical com center horiz => 1+3=4
      expect(
          tle.getAlignmentPos(
              Horizontalalignment.center, Verticalalignment.none),
          4,
          reason: 'center(1)+none vert MIDDLE(3)=4');
    });

    test(
        '2 — alturas: getCellHeight / RowHeight / ColHeight / ContentHeight com números calculados à mão',
        () {
      // Grade conhecida, uma Rend por célula (exceto célula 3 com duas Rends para testar soma)
      // Alturas por célula (height = Y2-Y1):
      // cell0=10, cell1=20, cell2=15,
      // cell3=5+7=12 (duas Rends 5 e 7 somadas), cell4=30, cell5=25,
      // cell6=12, cell7=8, cell8=18
      // Larguras por célula (width = X2-X1):
      // cell0=5, cell1=10, cell2=7, cell3=6, cell4=12, cell5=9, cell6=4, cell7=11, cell8=8
      final pgHead = PgHead();
      pgHead.resetCells();
      pgHead.resetDrawingScaling();

      // Helper to attach rend to pgHead both as child (for getList) and to cell directly.
      // Para este teste de alturas, colocamos direto nas células via appendTextToCell
      // para controlar exatamente a grade sem depender do functor de preparação.
      final heights = [10, 20, 15, 12, 30, 25, 12, 8, 18];
      final widths = [5, 10, 7, 6, 12, 9, 4, 11, 8];
      // cell3 terá duas Rends: 5 e 7 -> total 12 (substituir o único 12 por duas partes)
      // Então criamos células com alturas/larguras acima, exceto cell3 que será dividido.
      for (int cell = 0; cell < 9; cell++) {
        if (cell == 3) {
          final r1 = _makeRend(height: 5, width: 6);
          final r2 = _makeRend(height: 7, width: 6);
          pgHead.appendTextToCell(cell, r1);
          pgHead.appendTextToCell(cell, r2);
        } else {
          final rend = _makeRend(height: heights[cell], width: widths[cell]);
          pgHead.appendTextToCell(cell, rend);
        }
      }

      // GetCellHeight: soma por célula
      // cell3 =5+7=12 (conta: 5+7=12)
      expect(pgHead.getCellHeight(0), 10);
      expect(pgHead.getCellHeight(1), 20);
      expect(pgHead.getCellHeight(2), 15);
      expect(pgHead.getCellHeight(3), 12, reason: '5+7=12');
      expect(pgHead.getCellHeight(4), 30);
      expect(pgHead.getCellHeight(5), 25);
      expect(pgHead.getCellHeight(6), 12);
      expect(pgHead.getCellHeight(7), 8);
      expect(pgHead.getCellHeight(8), 18);

      // GetRowHeight: max por linha
      // row0: max(10,20,15)=20
      // row1: max(12,30,25)=30
      // row2: max(12,8,18)=18
      expect(pgHead.getRowHeight(0), 20, reason: 'max 10,20,15 =20');
      expect(pgHead.getRowHeight(1), 30, reason: 'max 12,30,25 =30');
      expect(pgHead.getRowHeight(2), 18, reason: 'max 12,8,18 =18');

      // GetColHeight: soma por coluna
      // col0: 10+12+12=34
      // col1: 20+30+8=58
      // col2: 15+25+18=58
      expect(pgHead.getColHeight(0), 34, reason: '10+12+12=34');
      expect(pgHead.getColHeight(1), 58, reason: '20+30+8=58');
      expect(pgHead.getColHeight(2), 58, reason: '15+25+18=58');

      // GetContentHeight: soma das linhas =20+30+18=68
      expect(pgHead.getContentHeight(), 68, reason: '20+30+18=68');

      // GetCellWidth: max por célula (cada célula tem 1 ou 2 com mesmo width, max igual)
      expect(pgHead.getCellWidth(0), 5);
      expect(pgHead.getCellWidth(1), 10);
      expect(pgHead.getCellWidth(2), 7);
      expect(pgHead.getCellWidth(3), 6);
      expect(pgHead.getCellWidth(4), 12);

      // GetRowWidth: lógica especial
      // row0: col0=1 col1=1 col2=1 => middle && (left||right) => width*3, max=10 =>30
      // row1: max=12 =>36
      // row2: max=11 =>33
      expect(pgHead.getRowWidth(0), 30,
          reason: 'max 10 *3 =30 (middle com left/right)');
      expect(pgHead.getRowWidth(1), 36, reason: 'max 12 *3 =36');
      expect(pgHead.getRowWidth(2), 33, reason: 'max 11 *3 =33');

      // GetColWidth: max por coluna
      // col0: max 5,6,4=6
      // col1: max 10,12,11=12
      // col2: max 7,9,8=9
      expect(pgHead.getColWidth(0), 6);
      expect(pgHead.getColWidth(1), 12);
      expect(pgHead.getColWidth(2), 9);

      // GetContentWidth: max RowWidth =36
      expect(pgHead.getContentWidth(), 36);

      // Também testar caso sem middle: row com só left (ou só right)
      final solo = PgHead();
      solo.resetCells();
      solo.resetDrawingScaling();
      solo.appendTextToCell(0, _makeRend(height: 10, width: 7)); // só col0
      // row0 max=7, col0=1 col1=0 col2=0 => 7*(1)=7
      expect(solo.getRowWidth(0), 7, reason: 'só left => width*1');
      solo.resetCells();
      solo.appendTextToCell(1, _makeRend(height: 10, width: 9)); // só middle
      // max=9, col1=1 col0=0 col2=0 => middle sem lados => 9*1=9
      expect(solo.getRowWidth(0), 9, reason: 'só middle => width*1');
    });

    test(
        '3 — adjustRunningElementYPos com drawingYRel nas 3 linhas, divisão ímpar',
        () {
      // Grade para testar YPos:
      // heights: cell0=20 cell1=20 cell2=20 => row0=20
      // cell3=15 cell4=20 cell5=10 => row1=20 (max 20, middle)
      // cell6=12 cell7=12 cell8=12 => row2=12
      // Isso exercita:
      // - topo (i=0): colYShift=0, YRel = -height + rowYRel
      // - meio (i=1): colYShift = (20 - cellHeight)/2 com truncamento (15->2, 20->0, 10->5)
      //   e divisão ímpar: 20-15=5 ~/2=2 (trunca), não 2.5
      // - base (i=2): colYShift = 12 - cellHeight => 0 para todas (bottom-aligned)
      final pgHead = PgHead();
      pgHead.resetCells();
      pgHead.resetDrawingScaling();

      final r0 = _makeRend(height: 20, width: 5);
      final r1 = _makeRend(height: 20, width: 5);
      final r2 = _makeRend(height: 20, width: 5);
      final r3 = _makeRend(height: 15, width: 5);
      final r4 = _makeRend(height: 20, width: 5);
      final r5 = _makeRend(height: 10, width: 5);
      final r6 = _makeRend(height: 12, width: 5);
      final r7 = _makeRend(height: 12, width: 5);
      final r8 = _makeRend(height: 12, width: 5);

      pgHead.appendTextToCell(0, r0);
      pgHead.appendTextToCell(1, r1);
      pgHead.appendTextToCell(2, r2);
      pgHead.appendTextToCell(3, r3);
      pgHead.appendTextToCell(4, r4);
      pgHead.appendTextToCell(5, r5);
      pgHead.appendTextToCell(6, r6);
      pgHead.appendTextToCell(7, r7);
      pgHead.appendTextToCell(8, r8);

      // Antes do ajuste, todos com YRel 0; depois da primeira fase (intra-cell)
      // cada um fica -height (cumulatedYRel - yShift com yShift=height, cum=0).
      // Segunda fase adiciona rowYRel - colYShift:
      // row0: rowYRel=0, h=20, shift 0 => -20+0= -20 para r0,r1,r2
      // rowYRel = -20
      // row1: h=20, rowYRel=-20
      //   r3: -15 + (-20) -2 = -37  (5~/2=2)
      //   r4: -20 + (-20) -0 = -40
      //   r5: -10 + (-20) -5 = -35  (10~/2=5)
      // rowYRel = -40
      // row2: h=12, rowYRel=-40, shift 0
      //   r6: -12 + (-40) -0 = -52
      //   r7: -12 + (-40) -0 = -52
      //   r8: -12 + (-40) -0 = -52

      pgHead.adjustRunningElementYPos();

      expect(r0.getDrawingYRel(), -20, reason: 'top row -20');
      expect(r1.getDrawingYRel(), -20);
      expect(r2.getDrawingYRel(), -20);

      expect(r3.getDrawingYRel(), -37,
          reason: '-15 -20 -2 = -37 (5~/2=2 ímpar)');
      expect(r4.getDrawingYRel(), -40, reason: '-20 -20 -0 = -40');
      expect(r5.getDrawingYRel(), -35, reason: '-10 -20 -5 = -35 (10~/2=5)');

      expect(r6.getDrawingYRel(), -52, reason: '-12 -40 bottom');
      expect(r7.getDrawingYRel(), -52);
      expect(r8.getDrawingYRel(), -52);

      // Teste extra de divisão ímpar isolada: row com height 21, cell  10 diff 11 ~/2=5
      final pgHead2 = PgHead();
      pgHead2.resetCells();
      pgHead2.resetDrawingScaling();
      final ra = _makeRend(height: 10, width: 5);
      final rb = _makeRend(height: 21, width: 5);
      // cell3 (row1 col0) height10, cell4 (row1 col1) height21 => rowHeight=21
      pgHead2.appendTextToCell(3, ra);
      pgHead2.appendTextToCell(4, rb);
      // Outras células vazias => row1 =21
      pgHead2.adjustRunningElementYPos();
      // Primeira fase: ra -10, rb -21
      // Segunda fase row1 shift: ra (21-10)/2=5, rb 0
      // rowYRel para row1 = -0? Row0=0 então rowYRel antes row1 =0? Mas row0 height 0 => rowYRel 0
      // Então ra => -10 +0 -5 = -15, rb => -21+0-0=-21
      expect(ra.getDrawingYRel(), -15, reason: '11~/2=5 truncado para zero');
      expect(rb.getDrawingYRel(), -21);
    });

    test('4 — getTotalHeight com altura zero não soma margem', () {
      final doc = Doc();
      // Forçar unit conhecida: default 90 (9*10). Margem 2.0 => 180
      final unit = doc.getDrawingUnit(100);
      expect(unit, 90, reason: 'unit 9*10=90');

      final emptyHead = PgHead();
      emptyHead.resetCells();
      emptyHead.resetDrawingScaling();
      // Sem conteúdo: GetContentHeight=0 => GetTotalHeight deve ser 0, não 180
      expect(emptyHead.getContentHeight(), 0);
      expect(emptyHead.getTotalHeight(doc), 0,
          reason: 'altura zero não soma margem (if height>0)');

      final emptyFoot = PgFoot();
      emptyFoot.resetCells();
      emptyFoot.resetDrawingScaling();
      expect(emptyFoot.getContentHeight(), 0);
      expect(emptyFoot.getTotalHeight(doc), 0);

      // Com conteúdo: height 20 => total =20+180=200
      final pgHead = PgHead();
      pgHead.resetCells();
      pgHead.resetDrawingScaling();
      pgHead.appendTextToCell(0, _makeRend(height: 20, width: 5));
      expect(pgHead.getContentHeight(), 20);
      final expectedHead =
          20 + (doc.getOptions().bottomMarginPgHead.value * unit).toInt();
      expect(pgHead.getTotalHeight(doc), expectedHead, reason: '20+180=200');

      final pgFoot = PgFoot();
      pgFoot.resetCells();
      pgFoot.resetDrawingScaling();
      pgFoot.appendTextToCell(0, _makeRend(height: 20, width: 5));
      final expectedFoot =
          20 + (doc.getOptions().topMarginPgFooter.value * unit).toInt();
      expect(pgFoot.getTotalHeight(doc), expectedFoot);

      // Div: GetTotalHeight nunca soma margem mesmo com conteúdo
      final div = Div();
      div.resetCells();
      div.resetDrawingScaling();
      expect(div.getTotalHeight(doc), 0, reason: 'div vazio 0');
      div.appendTextToCell(0, _makeRend(height: 20, width: 5));
      expect(div.getContentHeight(), 20);
      expect(div.getTotalHeight(doc), 20,
          reason: 'div com conteúdo = contentHeight sem margem');

      // Div GetTotalWidth: quando não inline, largura = pageContentWidth; quando inline, contentWidth
      final doc2 = Doc();
      doc2.drawingPageContentWidth = 1000;
      final div2 = Div();
      div2.resetCells();
      div2.resetDrawingScaling();
      div2.appendTextToCell(0, _makeRend(height: 10, width: 30));
      div2.appendTextToCell(
          1,
          _makeRend(
              height: 10,
              width: 40)); // row0 max 40 => contentWidth com middle+ lados?
      // Com row0 células 0 e1 preenchidas: rowWidth = max(40)*? col0=1 col1=1 => *3 =>120 ??? Vamos apenas garantir conteúdo vs page
      expect(div2.getTotalWidth(doc2), 1000,
          reason: 'div não inline => pageContentWidth');
      div2.setDrawingInline(inline: true);
      // contentWidth = max rowWidth; row0 agora tem 0:30 e1:40 => max40*3=120
      expect(div2.getTotalWidth(doc2), div2.getContentWidth());
    });

    test('extra — adjustDrawingScaling e resetDrawingScaling', () {
      final tle = PgHead();
      tle.resetCells();
      tle.resetDrawingScaling();
      // Row0: 3 colunas 400 cada => rowWidth 1200 > width 1000 => scaling 83 (1000*100~/1200)
      tle.appendTextToCell(0, _makeRend(height: 10, width: 400));
      tle.appendTextToCell(1, _makeRend(height: 10, width: 400));
      tle.appendTextToCell(2, _makeRend(height: 10, width: 400));
      expect(tle.adjustDrawingScaling(1000), isTrue);
      expect(tle.getDrawingScalingPercent(0), 83, reason: '1000*100~/1200=83');
      expect(tle.getDrawingScalingPercent(1), 100);
      expect(tle.getDrawingScalingPercent(2), 100);
      tle.resetDrawingScaling();
      expect(tle.getDrawingScalingPercent(0), 100);
      expect(tle.adjustDrawingScaling(2000), isFalse,
          reason: 'largura suficiente não escala');
    });
  });
}
