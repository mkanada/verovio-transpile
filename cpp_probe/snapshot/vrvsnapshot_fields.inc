// GENERATED FILE — do not edit.
// Source: cpp_probe/snapshot/fields.manifest
// Regenerate: (cd verovio_dart && dart run tool/gen_snapshot_fields.dart)
//
// Included by cpp_probe/snapshot/vrvsnapshot.cpp inside namespace vrv::snapshot.
// The Dart twin is verovio_dart/tool/snapshot/fields.g.dart.

static const char *const kSkipFunctors = "^(Find.*|AddToFlatListFunctor|_?GetAlignmentLeftRightFunctor|CountFunctor)$";

static void EmitFields(const BoundingBox *bb, Row &row)
{
    {
        const BoundingBox *o = bb;
        if (row.Wants(G_BB)) row.Int("sx1", (long long)(o->GetSelfX1()));
        if (row.Wants(G_BB)) row.Int("sy1", (long long)(o->GetSelfY1()));
        if (row.Wants(G_BB)) row.Int("sx2", (long long)(o->GetSelfX2()));
        if (row.Wants(G_BB)) row.Int("sy2", (long long)(o->GetSelfY2()));
        if (row.Wants(G_BB)) row.Int("cx1", (long long)(o->GetContentX1()));
        if (row.Wants(G_BB)) row.Int("cy1", (long long)(o->GetContentY1()));
        if (row.Wants(G_BB)) row.Int("cx2", (long long)(o->GetContentX2()));
        if (row.Wants(G_BB)) row.Int("cy2", (long long)(o->GetContentY2()));
        if (row.Wants(G_CACHE)) row.Int("cdx", (long long)(o->m_cachedDrawingX));
        if (row.Wants(G_CACHE)) row.Int("cdy", (long long)(o->m_cachedDrawingY));
    }
    if (const Doc *o = dynamic_cast<const Doc *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("dPageW", (long long)(o->m_drawingPageWidth));
        if (row.Wants(G_LAYOUT)) row.Int("dPageH", (long long)(o->m_drawingPageHeight));
        if (row.Wants(G_LAYOUT)) row.Int("dContentW", (long long)(o->m_drawingPageContentWidth));
        if (row.Wants(G_LAYOUT)) row.Int("dContentH", (long long)(o->m_drawingPageContentHeight));
        if (row.Wants(G_LAYOUT)) row.Int("dMarginB", (long long)(o->m_drawingPageMarginBottom));
        if (row.Wants(G_LAYOUT)) row.Int("dMarginL", (long long)(o->m_drawingPageMarginLeft));
        if (row.Wants(G_LAYOUT)) row.Int("dMarginR", (long long)(o->m_drawingPageMarginRight));
        if (row.Wants(G_LAYOUT)) row.Int("dMarginT", (long long)(o->m_drawingPageMarginTop));
        if (row.Wants(G_LAYOUT) && (o->m_drawingPageWidth != -1)) row.Double("dBeamMaxSlope", (double)(o->m_drawingBeamMaxSlope));
        if (row.Wants(G_LAYOUT) && (o->m_drawingPageWidth != -1)) row.Int("dBeamW", (long long)(o->m_drawingBeamWidth));
        if (row.Wants(G_LAYOUT) && (o->m_drawingPageWidth != -1)) row.Int("dBeamWhiteW", (long long)(o->m_drawingBeamWhiteWidth));
        if (row.Wants(G_LAYOUT)) row.Int("dSmuflSize", (long long)(o->m_drawingSmuflFontSize));
        if (row.Wants(G_LAYOUT)) row.Int("dLyricSize", (long long)(o->m_drawingLyricFontSize));
        if (row.Wants(G_LAYOUT)) row.Bool("dCastOff", (bool)(o->m_isCastOff));
    }
    if (const Page *o = dynamic_cast<const Page *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("pW", (long long)(o->m_pageWidth));
        if (row.Wants(G_LAYOUT)) row.Int("pH", (long long)(o->m_pageHeight));
        if (row.Wants(G_LAYOUT)) row.Int("pMarginB", (long long)(o->m_pageMarginBottom));
        if (row.Wants(G_LAYOUT)) row.Int("pMarginL", (long long)(o->m_pageMarginLeft));
        if (row.Wants(G_LAYOUT)) row.Int("pMarginR", (long long)(o->m_pageMarginRight));
        if (row.Wants(G_LAYOUT)) row.Int("pMarginT", (long long)(o->m_pageMarginTop));
        if (row.Wants(G_LAYOUT)) row.Double("pPPU", (double)(o->m_PPUFactor));
        if (row.Wants(G_LAYOUT)) row.Int("pJustH", (long long)(o->m_drawingJustifiableHeight));
        if (row.Wants(G_LAYOUT)) row.Double("pJustSum", (double)(o->m_justificationSum));
        if (row.Wants(G_LAYOUT)) row.Bool("pLayoutDone", (bool)(o->m_layoutDone));
    }
    if (const System *o = dynamic_cast<const System *>(bb)) {
        if (row.Wants(G_POS)) row.Int("sysXRel", (long long)(o->m_drawingXRel));
        if (row.Wants(G_POS)) row.Int("sysYRel", (long long)(o->m_drawingYRel));
        if (row.Wants(G_LAYOUT)) row.Int("sysLeftMar", (long long)(o->m_systemLeftMar));
        if (row.Wants(G_LAYOUT)) row.Int("sysRightMar", (long long)(o->m_systemRightMar));
        if (row.Wants(G_LAYOUT)) row.Int("sysAbbrLabelsW", (long long)(o->m_drawingAbbrLabelsWidth));
        if (row.Wants(G_LAYOUT)) row.Int("sysTotalW", (long long)(o->m_drawingTotalWidth));
        if (row.Wants(G_LAYOUT)) row.Int("sysJustW", (long long)(o->m_drawingJustifiableWidth));
        if (row.Wants(G_LAYOUT)) row.Int("sysCastOffTotalW", (long long)(o->m_castOffTotalWidth));
        if (row.Wants(G_LAYOUT)) row.Int("sysCastOffJustW", (long long)(o->m_castOffJustifiableWidth));
        if (row.Wants(G_LAYOUT)) row.Bool("sysOptimized", (bool)(o->m_drawingIsOptimized));
    }
    if (const Measure *o = dynamic_cast<const Measure *>(bb)) {
        if (row.Wants(G_POS)) row.Int("mXRel", (long long)(o->m_drawingXRel));
        if (row.Wants(G_LAYOUT)) row.Int("mType", (long long)(o->m_measureType));
        if (row.Wants(G_LAYOUT)) row.Int("mIndex", (long long)(o->m_index));
        if (row.Wants(G_LINK)) row.Ref("mScoreDef", o->m_drawingScoreDef);
        if (row.Wants(G_LINK)) row.Ref("mEnding", o->m_drawingEnding);
        if (row.Wants(G_CACHE)) row.Int("mCachedXRel", (long long)(o->m_cachedXRel));
        if (row.Wants(G_CACHE)) row.Int("mCachedWidth", (long long)(o->m_cachedWidth));
        if (row.Wants(G_CACHE)) row.Int("mCachedOverflow", (long long)(o->m_cachedOverflow));
    }
    if (const MeasureAligner *o = dynamic_cast<const MeasureAligner *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("maNonJustLeft", (long long)(o->m_nonJustifiableLeftMargin));
    }
    if (const Alignment *o = dynamic_cast<const Alignment *>(bb)) {
        if (row.Wants(G_POS)) row.Int("alXRel", (long long)(o->m_xRel));
        if (row.Wants(G_LAYOUT)) row.Frac("alTime", o->m_time);
        if (row.Wants(G_LAYOUT)) row.Int("alType", (long long)(o->m_type));
    }
    if (const AlignmentReference *o = dynamic_cast<const AlignmentReference *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("refLayerCount", (long long)(o->m_layerCount));
        if (row.Wants(G_LINK)) {
            std::vector<const BoundingBox *> v;
            for (const auto &c : (o->GetChildren())) {
                v.push_back(row.Valid(c));
            }
            row.Refs("refElements", v);
        }
    }
    if (const GraceAligner *o = dynamic_cast<const GraceAligner *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("gaWidth", (long long)(o->m_totalWidth));
    }
    if (const SystemAligner *o = dynamic_cast<const SystemAligner *>(bb)) {
        if (row.Wants(G_LINK)) row.Ref("saBottom", o->m_bottomAlignment);
    }
    if (const StaffAlignment *o = dynamic_cast<const StaffAlignment *>(bb)) {
        if (row.Wants(G_POS)) row.Int("stYRel", (long long)(o->m_yRel));
        if (row.Wants(G_LAYOUT)) row.Int("stOverflowAbove", (long long)(o->m_overflowAbove));
        if (row.Wants(G_LAYOUT)) row.Int("stOverflowBelow", (long long)(o->m_overflowBelow));
        if (row.Wants(G_LAYOUT)) row.Int("stOverlap", (long long)(o->m_overlap));
        if (row.Wants(G_LAYOUT)) row.Int("stReqAbove", (long long)(o->m_requestedSpaceAbove));
        if (row.Wants(G_LAYOUT)) row.Int("stReqBelow", (long long)(o->m_requestedSpaceBelow));
        if (row.Wants(G_LAYOUT)) row.Int("stReqSpacing", (long long)(o->m_requestedSpacing));
        if (row.Wants(G_LAYOUT)) row.Int("stStaffHeight", (long long)(o->m_staffHeight));
        if (row.Wants(G_LAYOUT)) row.Int("stClefOverflowAbove", (long long)(o->m_scoreDefClefOverflowAbove));
        if (row.Wants(G_LAYOUT)) row.Int("stClefOverflowBelow", (long long)(o->m_scoreDefClefOverflowBelow));
        if (row.Wants(G_LAYOUT)) row.Int("stSpacingType", (long long)(o->m_spacingType));
        if (row.Wants(G_LAYOUT)) {
            std::vector<long long> v;
            for (const auto &_e : (o->m_verseAboveNs)) v.push_back((long long)(_e));
            std::sort(v.begin(), v.end());
            row.Ints("stVersesAbove", v);
        }
        if (row.Wants(G_LAYOUT)) {
            std::vector<long long> v;
            for (const auto &_e : (o->m_verseBelowNs)) v.push_back((long long)(_e));
            std::sort(v.begin(), v.end());
            row.Ints("stVersesBelow", v);
        }
        if (row.Wants(G_LINK)) row.Ref("stStaff", o->m_staff);
        if (row.Wants(G_CACHE)) {
            std::vector<const BoundingBox *> v;
            for (const auto &b : (o->m_overflowAboveBBoxes)) {
                v.push_back(row.Valid(b));
            }
            row.Refs("stOverflowAboveBBs", v);
        }
        if (row.Wants(G_CACHE)) {
            std::vector<const BoundingBox *> v;
            for (const auto &b : (o->m_overflowBelowBBoxes)) {
                v.push_back(row.Valid(b));
            }
            row.Refs("stOverflowBelowBBs", v);
        }
    }
    if (const FloatingObject *o = dynamic_cast<const FloatingObject *>(bb)) {
        if (row.Wants(G_LINK)) row.Ref("foCurrentPositioner", o->m_currentPositioner);
        if (row.Wants(G_LAYOUT)) row.Int("foGrpId", (long long)(o->m_drawingGrpId));
        if (row.Wants(G_LAYOUT)) row.Int("foMaxYRel", (long long)(o->m_maxDrawingYRel));
    }
    if (const FloatingPositioner *o = dynamic_cast<const FloatingPositioner *>(bb)) {
        if (row.Wants(G_POS)) row.Int("fpXRel", (long long)(o->m_drawingXRel));
        if (row.Wants(G_POS)) row.Int("fpYRel", (long long)(o->m_drawingYRel));
        if (row.Wants(G_LAYOUT)) row.Int("fpExtenderW", (long long)(o->m_drawingExtenderWidth));
        if (row.Wants(G_LAYOUT)) row.Int("fpPlace", (long long)(o->m_place));
        if (row.Wants(G_LAYOUT)) row.Int("fpSpanningType", (long long)(o->m_spanningType));
        if (row.Wants(G_LINK)) row.Ref("fpObject", o->m_object);
        if (row.Wants(G_LINK)) row.Ref("fpObjectX", o->m_objectX);
        if (row.Wants(G_LINK)) row.Ref("fpObjectY", o->m_objectY);
        if (row.Wants(G_LINK)) row.Ref("fpAlignment", o->m_alignment);
    }
    if (const FloatingCurvePositioner *o = dynamic_cast<const FloatingCurvePositioner *>(bb)) {
        if (row.Wants(G_LAYOUT)) {
            std::vector<long long> v;
            for (const auto &p : (o->m_points)) {
                v.push_back((long long)(p.x));
                v.push_back((long long)(p.y));
            }
            row.Ints("cvPoints", v);
        }
        if (row.Wants(G_LAYOUT)) row.Int("cvThickness", (long long)(o->m_thickness));
        if (row.Wants(G_LAYOUT)) row.Int("cvDir", (long long)(o->m_dir));
        if (row.Wants(G_LAYOUT)) row.Int("cvReqStaffSpace", (long long)(o->m_requestedStaffSpace));
        if (row.Wants(G_LAYOUT)) {
            std::vector<long long> v;
            for (const auto &s : (o->m_spannedElements)) {
                v.push_back((long long)(s->m_discarded));
            }
            row.Ints("cvDiscarded", v);
        }
        if (row.Wants(G_LINK)) row.Ref("cvCrossStaff", o->m_crossStaff);
        if (row.Wants(G_LINK)) {
            std::vector<const BoundingBox *> v;
            for (const auto &s : (o->m_spannedElements)) {
                v.push_back(row.Valid(s->m_boundingBox));
            }
            row.Refs("cvSpanned", v);
        }
        if (row.Wants(G_CACHE)) row.Int("cvCachedMinMaxY", (long long)(o->m_cachedMinMaxY));
        if (row.Wants(G_CACHE)) {
            std::vector<long long> v;
            for (const auto &_e : (std::vector<int>{o->m_cachedX12.first, o->m_cachedX12.second})) v.push_back((long long)(_e));
            row.Ints("cvCachedX12", v);
        }
    }
    if (const Staff *o = dynamic_cast<const Staff *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("staffLines", (long long)(o->m_drawingLines));
        if (row.Wants(G_LAYOUT)) row.Int("staffNotationType", (long long)(o->m_drawingNotationType));
        if (row.Wants(G_LAYOUT)) row.Int("staffSize", (long long)(o->m_drawingStaffSize));
        if (row.Wants(G_LAYOUT)) row.Double("staffRotation", (double)(o->m_drawingRotation));
        if (row.Wants(G_LAYOUT)) row.Bool("staffIsOssia", (bool)(o->m_isOssia));
        if (row.Wants(G_LAYOUT)) {
            std::vector<long long> v;
            for (const auto &l : (o->m_ledgerLinesAbove)) {
                v.push_back((long long)((int)l.m_dashes.size()));
                for (const auto &d : (l.m_dashes)) {
                    v.push_back((long long)(d.m_x1));
                    v.push_back((long long)(d.m_x2));
                }
            }
            row.Ints("ledgerAbove", v);
        }
        if (row.Wants(G_LAYOUT)) {
            std::vector<long long> v;
            for (const auto &l : (o->m_ledgerLinesBelow)) {
                v.push_back((long long)((int)l.m_dashes.size()));
                for (const auto &d : (l.m_dashes)) {
                    v.push_back((long long)(d.m_x1));
                    v.push_back((long long)(d.m_x2));
                }
            }
            row.Ints("ledgerBelow", v);
        }
        if (row.Wants(G_LAYOUT)) {
            std::vector<long long> v;
            for (const auto &l : (o->m_ledgerLinesAboveCue)) {
                v.push_back((long long)((int)l.m_dashes.size()));
                for (const auto &d : (l.m_dashes)) {
                    v.push_back((long long)(d.m_x1));
                    v.push_back((long long)(d.m_x2));
                }
            }
            row.Ints("ledgerAboveCue", v);
        }
        if (row.Wants(G_LAYOUT)) {
            std::vector<long long> v;
            for (const auto &l : (o->m_ledgerLinesBelowCue)) {
                v.push_back((long long)((int)l.m_dashes.size()));
                for (const auto &d : (l.m_dashes)) {
                    v.push_back((long long)(d.m_x1));
                    v.push_back((long long)(d.m_x2));
                }
            }
            row.Ints("ledgerBelowCue", v);
        }
        if (row.Wants(G_LINK)) row.Ref("staffAlignment", o->m_staffAlignment);
        if (row.Wants(G_LINK)) row.Ref("staffDrawingStaffDef", o->m_drawingStaffDef);
    }
    if (const Layer *o = dynamic_cast<const Layer *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("layerStemDir", (long long)(o->m_drawingStemDir));
        if (row.Wants(G_LAYOUT)) row.Bool("layerCrossFromAbove", (bool)(o->m_crossStaffFromAbove));
        if (row.Wants(G_LAYOUT)) row.Bool("layerCrossFromBelow", (bool)(o->m_crossStaffFromBelow));
    }
    if (const StaffDefDrawingInterface *o = dynamic_cast<const StaffDefDrawingInterface *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Bool("sdDrawClef", (bool)(o->m_drawClef));
        if (row.Wants(G_LAYOUT)) row.Bool("sdDrawKeySig", (bool)(o->m_drawKeySig));
        if (row.Wants(G_LAYOUT)) row.Bool("sdDrawMensur", (bool)(o->m_drawMensur));
        if (row.Wants(G_LAYOUT)) row.Bool("sdDrawMeterSig", (bool)(o->m_drawMeterSig));
        if (row.Wants(G_LAYOUT)) row.Bool("sdDrawMeterSigGrp", (bool)(o->m_drawMeterSigGrp));
    }
    if (const LayerElement *o = dynamic_cast<const LayerElement *>(bb)) {
        if (row.Wants(G_POS)) row.Int("xRel", (long long)(o->m_drawingXRel));
        if (row.Wants(G_POS)) row.Int("yRel", (long long)(o->m_drawingYRel));
        if (row.Wants(G_LINK)) row.Ref("alignment", o->m_alignment);
        if (row.Wants(G_LINK)) row.Ref("graceAlignment", o->m_graceAlignment);
        if (row.Wants(G_LINK)) row.Int("alignmentLayerN", (long long)(o->m_alignmentLayerN));
        if (row.Wants(G_LINK)) row.Ref("crossStaff", o->m_crossStaff);
        if (row.Wants(G_LINK)) row.Ref("crossLayer", o->m_crossLayer);
        if (row.Wants(G_LAYOUT)) row.Bool("cueSize", (bool)(o->m_drawingCueSize));
        if (row.Wants(G_LAYOUT)) row.Int("scoreDefRole", (long long)(o->m_scoreDefRole));
        if (row.Wants(G_LAYOUT)) row.Bool("inBeamSpan", (bool)(o->m_isInBeamspan));
        if (row.Wants(G_LAYOUT)) row.Int("facsX", (long long)(o->m_drawingFacsX));
        if (row.Wants(G_LAYOUT)) row.Int("facsY", (long long)(o->m_drawingFacsY));
        if (row.Wants(G_CACHE)) row.Int("cachedXRel", (long long)(o->m_cachedXRel));
        if (row.Wants(G_CACHE)) row.Int("cachedYRel", (long long)(o->m_cachedYRel));
    }
    if (const PositionInterface *o = dynamic_cast<const PositionInterface *>(bb)) {
        if (row.Wants(G_POS)) row.Int("loc", (long long)(o->m_drawingLoc));
    }
    if (const StemmedDrawingInterface *o = dynamic_cast<const StemmedDrawingInterface *>(bb)) {
        if (row.Wants(G_LINK)) row.Ref("stem", o->m_drawingStem);
    }
    if (const TimePointInterface *o = dynamic_cast<const TimePointInterface *>(bb)) {
        if (row.Wants(G_LINK)) row.Ref("tStart", o->m_start);
    }
    if (const TimeSpanningInterface *o = dynamic_cast<const TimeSpanningInterface *>(bb)) {
        if (row.Wants(G_LINK)) row.Ref("tEnd", o->m_end);
    }
    if (const Stem *o = dynamic_cast<const Stem *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("stemDir", (long long)(o->m_drawingStemDir));
        if (row.Wants(G_LAYOUT)) row.Int("stemLen", (long long)(o->m_drawingStemLen));
        if (row.Wants(G_LAYOUT)) row.Int("stemMod", (long long)(o->m_drawingStemMod));
        if (row.Wants(G_LAYOUT)) row.Int("stemModRelY", (long long)(o->m_stemModRelY));
        if (row.Wants(G_LAYOUT)) row.Int("stemAdjust", (long long)(o->m_drawingStemAdjust));
        if (row.Wants(G_LAYOUT)) row.Bool("stemVirtual", (bool)(o->m_isVirtual));
    }
    if (const Note *o = dynamic_cast<const Note *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Bool("noteFlipped", (bool)(o->m_flippedNotehead));
        if (row.Wants(G_LAYOUT)) row.Int("noteGroupPos", (long long)(o->m_noteGroupPosition));
        if (row.Wants(G_LAYOUT)) row.Int("noteSameasRole", (long long)(o->m_stemSameasRole));
    }
    if (const Accid *o = dynamic_cast<const Accid *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Bool("accidSameLayer", (bool)(o->m_alignedWithSameLayer));
        if (row.Wants(G_LINK)) row.Ref("accidUnison", o->m_drawingUnison);
    }
    if (const Dots *o = dynamic_cast<const Dots *>(bb)) {
        if (row.Wants(G_LAYOUT)) {
            std::vector<long long> v;
            for (const auto &_e : (DotLocs(o))) v.push_back((long long)(_e));
            row.Ints("dotLocs", v);
        }
        if (row.Wants(G_LAYOUT)) row.Bool("dotsAdjusted", (bool)(o->m_isAdjusted));
        if (row.Wants(G_LAYOUT)) row.Int("dotsFlagShift", (long long)(o->m_flagShift));
    }
    if (const Flag *o = dynamic_cast<const Flag *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("flagCount", (long long)(o->m_drawingNbFlags));
    }
    if (const TupletBracket *o = dynamic_cast<const TupletBracket *>(bb)) {
        if (row.Wants(G_POS)) row.Int("tbXRelLeft", (long long)(o->m_drawingXRelLeft));
        if (row.Wants(G_POS)) row.Int("tbXRelRight", (long long)(o->m_drawingXRelRight));
        if (row.Wants(G_POS)) row.Int("tbYRelLeft", (long long)(o->m_drawingYRelLeft));
        if (row.Wants(G_POS)) row.Int("tbYRelRight", (long long)(o->m_drawingYRelRight));
    }
    if (const Tuplet *o = dynamic_cast<const Tuplet *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("tupletBracketPos", (long long)(o->m_drawingBracketPos));
        if (row.Wants(G_LINK)) row.Ref("tupletLeft", o->m_drawingLeft);
        if (row.Wants(G_LINK)) row.Ref("tupletRight", o->m_drawingRight);
        if (row.Wants(G_LINK)) row.Ref("tupletBracketBeam", o->m_bracketAlignedBeam);
        if (row.Wants(G_LINK)) row.Ref("tupletNumBeam", o->m_numAlignedBeam);
    }
    if (const Artic *o = dynamic_cast<const Artic *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("articPlace", (long long)(o->m_drawingPlace));
    }
    if (const Syl *o = dynamic_cast<const Syl *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("sylVerseN", (long long)(o->m_drawingVerseN));
        if (row.Wants(G_LAYOUT)) row.Int("sylVersePlace", (long long)(o->m_drawingVersePlace));
    }
    if (const KeySig *o = dynamic_cast<const KeySig *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Bool("ksSkipCancel", (bool)(o->m_skipCancellation));
        if (row.Wants(G_LAYOUT)) row.Int("ksCancelType", (long long)(o->m_drawingCancelAccidType));
        if (row.Wants(G_LAYOUT)) row.Int("ksCancelCount", (long long)(o->m_drawingCancelAccidCount));
    }
    if (const BarLine *o = dynamic_cast<const BarLine *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("barLinePosition", (long long)(o->m_position));
    }
    if (const Slur *o = dynamic_cast<const Slur *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("slurCurveDir", (long long)(o->m_drawingCurveDir));
    }
    if (const BeamDrawingInterface *o = dynamic_cast<const BeamDrawingInterface *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Int("bdPlace", (long long)(o->m_drawingPlace));
        if (row.Wants(G_LAYOUT)) row.Int("bdWidth", (long long)(o->m_beamWidth));
        if (row.Wants(G_LAYOUT)) row.Int("bdWidthBlack", (long long)(o->m_beamWidthBlack));
        if (row.Wants(G_LAYOUT)) row.Int("bdWidthWhite", (long long)(o->m_beamWidthWhite));
        if (row.Wants(G_LAYOUT)) row.Int("bdFractionSize", (long long)(o->m_fractionSize));
        if (row.Wants(G_LAYOUT)) row.Bool("bdChangingDur", (bool)(o->m_changingDur));
        if (row.Wants(G_LAYOUT)) row.Bool("bdHasChord", (bool)(o->m_beamHasChord));
        if (row.Wants(G_LAYOUT)) row.Bool("bdMultipleStemDir", (bool)(o->m_hasMultipleStemDir));
        if (row.Wants(G_LAYOUT)) row.Bool("bdCueSize", (bool)(o->m_cueSize));
        if (row.Wants(G_LAYOUT)) row.Bool("bdSpanning", (bool)(o->m_isSpanningElement));
        if (row.Wants(G_LAYOUT)) row.Int("bdShortestDur", (long long)(o->m_shortestDur));
        if (row.Wants(G_LAYOUT)) row.Int("bdNotesStemDir", (long long)(o->m_notesStemDir));
        if (row.Wants(G_LAYOUT)) row.Int("bdCrossStaffRel", (long long)(o->m_crossStaffRel));
        if (row.Wants(G_LAYOUT)) {
            std::vector<long long> v;
            for (const auto &c : (o->m_beamElementCoords)) {
                v.push_back((long long)(c->m_dur));
                v.push_back((long long)(c->m_breaksec));
                v.push_back((long long)(c->m_overlapMargin));
                v.push_back((long long)(c->m_beamRelativePlace));
                v.push_back((long long)(c->m_partialFlagPlace));
            }
            row.Ints("bdCoordMisc", v);
        }
        if (row.Wants(G_LINK)) {
            std::vector<const BoundingBox *> v;
            for (const auto &c : (o->m_beamElementCoords)) {
                v.push_back(row.Valid(c->m_element));
            }
            row.Refs("bdCoordElements", v);
        }
        if (row.Wants(G_LINK)) row.Ref("bdCrossStaffContent", o->m_crossStaffContent);
        if (row.Wants(G_LINK)) row.Ref("bdBeamStaff", o->m_beamStaff);
    }
    if (const Beam *o = dynamic_cast<const Beam *>(bb)) {
        if (row.Wants(G_LAYOUT)) row.Double("bsSlope", (double)(o->m_beamSegment.m_beamSlope));
        if (row.Wants(G_LAYOUT)) row.Int("bsVerticalCenter", (long long)(o->m_beamSegment.m_verticalCenter));
        if (row.Wants(G_LAYOUT)) row.Int("bsLedgerAbove", (long long)(o->m_beamSegment.m_ledgerLinesAbove));
        if (row.Wants(G_LAYOUT)) row.Int("bsLedgerBelow", (long long)(o->m_beamSegment.m_ledgerLinesBelow));
        if (row.Wants(G_LAYOUT)) row.Int("bsUniformStemLen", (long long)(o->m_beamSegment.m_uniformStemLength));
        if (row.Wants(G_LAYOUT)) row.Int("bsWeightedPlace", (long long)(o->m_beamSegment.m_weightedPlace));
        if (row.Wants(G_LAYOUT)) row.Int("bsSameasRole", (long long)(o->m_beamSegment.m_stemSameasRole));
        if (row.Wants(G_LAYOUT) && (o->m_beamSegment.m_firstNoteOrChord != NULL)) {
            std::vector<long long> v;
            for (const auto &c : (o->m_beamSegment.m_beamElementCoordRefs)) {
                v.push_back((long long)(c->m_x));
            }
            row.Ints("bsCoordX", v);
        }
        if (row.Wants(G_LAYOUT) && (o->m_beamSegment.m_firstNoteOrChord != NULL)) {
            std::vector<long long> v;
            for (const auto &c : (o->m_beamSegment.m_beamElementCoordRefs)) {
                v.push_back((long long)(c->m_yBeam));
            }
            row.Ints("bsCoordYBeam", v);
        }
        if (row.Wants(G_LINK)) row.Ref("beamStemSameas", o->m_stemSameas);
    }
}
