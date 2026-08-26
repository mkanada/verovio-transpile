#!/usr/bin/env python3
"""One-shot migration helper: generates the remaining Verovio element
classes (leaves) for the Dart port from the C++ headers/sources.

Outputs:
  lib/src/model/control_elements_gen.dart
  lib/src/model/layer_elements_gen.dart
  lib/src/model/misc_elements_gen.dart   (text, running, scoredef, page/system)
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INC = os.path.join(ROOT, '..', 'origin', 'src', 'include', 'vrv')
SRC = os.path.join(ROOT, '..', 'origin', 'src', 'src')
OUT = os.path.join(ROOT, 'lib', 'src', 'model')
ROOT_REL = 'lib'

# ---------------------------------------------------------------------------
# Load available generated Att mixins
# ---------------------------------------------------------------------------
att_mixins = set()
att_module = {}
for f in os.listdir(os.path.join(OUT, 'atts')):
    if f.startswith('atts_') and f.endswith('.dart'):
        mod = f[:-5]
        for m in re.finditer(r'^mixin (Att\w+)', open(os.path.join(OUT,'atts',f)).read(), re.M):
            att_mixins.add(m.group(1))
            att_module[m.group(1)] = f  # full file name

# ClassId enum names from vrvdef.dart (cpp name -> dart name)
vrvdef = open(os.path.join(ROOT, 'lib', 'src', 'core', 'vrvdef.dart')).read()
classid_names = {}
for m in re.finditer(r'^\s{2}(\w+),\s*$', vrvdef, re.M):
    dart = m.group(1)
    classid_names[dart.lower()] = dart
# special spellings
classid_names['barline'] = 'barLine'
classid_names['divline'] = 'divLine'
classid_names['keysig'] = 'keysig'
classid_names['keyaccid'] = 'keyAccid'
classid_names['mensur'] = 'mensur'

classid_names['metersig'] = 'meterSig'
classid_names['metersiggrp'] = 'meterSigGrp'
classid_names['mrest'] = 'mRest'
classid_names['mrpt'] = 'mRpt'
classid_names['mrpt2'] = 'mRpt2'
classid_names['mspace'] = 'mSpace'
classid_names['ftrem'] = 'fTrem'
classid_names['btrem'] = 'bTrem'
classid_names['tabdurSym'.lower()] = 'tabDurSym'
classid_names['pgfoot'] = 'pgFoot'
classid_names['pghead'] = 'pgHead'
classid_names['pghead2'] = 'pgHead2'
classid_names['pgfoot2'] = 'pgFoot2'

# ---------------------------------------------------------------------------
# Interface metadata: cpp name -> (import file, on-constraints, interfaceId)
# ---------------------------------------------------------------------------
INTERFACES = {
    'TimeSpanningInterface': ('time_interface.dart', ['TimePointInterface','AttStartEndId','AttTimestamp2Log'], 'timeSpanning', ['TimePointInterface']),
    'TimePointInterface': ('time_interface.dart', ['AttPartIdent','AttStaffIdent','AttStartId','AttTimestampLog'], 'timePoint', []),
    'DurationInterface': ('duration_interface.dart', ['AttAugmentDots','AttBeamSecondary','AttDurationGes','AttDurationLog','AttDurationQuality','AttDurationRatio','AttFermataPresent','AttStaffIdent'], 'duration', []),
    'PitchInterface': ('pitch_interface.dart', ['AttNoteGes','AttOctave','AttPitch','AttPitchGes'], 'pitch', []),
    'PositionInterface': ('position_interface.dart', ['AttStaffLoc','AttStaffLocPitched'], 'position', []),
    'OffsetSpanningInterface': ('simple_interfaces.dart', ['AttVisualOffset2Ho','AttVisualOffset2Vo'], 'offsetSpanning', []),
    'OffsetInterface': ('simple_interfaces.dart', ['AttVisualOffsetHo','AttVisualOffsetVo'], 'offset', []),
    'AltSymInterface': ('simple_interfaces.dart', ['AttAltSym'], 'altSym', []),
    'AreaPosInterface': ('simple_interfaces.dart', ['AttHorizontalAlign','AttVerticalAlign'], 'areaPos', []),
    'PlistInterface': ('plist_interface.dart', ['AttPlist'], 'plist', []),
    'LinkingInterface': ('linking_interface.dart', ['AttLinking'], 'linking', []),
    'FacsimileInterface': ('facsimile_interface.dart', ['AttFacsimile'], 'facsimile', []),
    'TextDirInterface': ('simple_interfaces.dart', ['AttPlacementRelStaff'], 'textDir', []),
    'ScoreDefInterface': ('simple_interfaces.dart', [], 'scoreDef', []),
}

LOCAL_MIXINS = {
    'TextListInterface': ('object.dart', None),
    'DrawingListInterface': ('object.dart', None),
    'BeamDrawingInterface': ('drawing_interfaces.dart', None),
    'StemmedDrawingInterface': ('drawing_interfaces.dart', None),
    'VisibilityDrawingInterface': ('drawing_interfaces.dart', None),
    'SystemMilestoneInterface': ('drawing_interfaces.dart', None),
    'PageMilestoneInterface': ('drawing_interfaces.dart', None),
    'ObjectListInterface': ('object.dart', None),
}

BASE_CLASSES = {'LayerElement':'layer_element.dart','ControlElement':'control_element.dart',
                'FloatingObject':'floating_object.dart','EditorialElement':'editorial_element.dart',
                'SystemElement':'system_page_elements.dart','PageElement':'system_page_elements.dart',
                'TextLayoutElement':'text_elements.dart','TextElement':'text_elements.dart',
                'RunningElement':'text_elements.dart','Object':None}

# classes to generate: name -> (base override or None)
WANTED = []
for f in sorted(os.listdir(INC)):
    if not f.endswith('.h'): continue
    src = open(os.path.join(INC,f)).read()
    flat = re.sub(r'\s+', ' ', src)
    for m in re.finditer(r'class (\w+)\s*:\s*public ([\w:, ]+?) \{', flat):
        WANTED.append((m.group(1), [b.strip().replace('public ','') for b in m.group(2).split(',')], f))

ALREADY = {'Object','BoundingBox','Doc','Pages','Page','System','DocObject','Mensur',
           'ScoreDef','StaffDef','StaffGrp','LayerDef','Ossia','Measure','Staff','Layer',
           'Section','Score','Mdiv','Note','Rest','Clef','BarLine','Zone','PgHead2','PgFoot2',
           'EditorialElement','Abbr','Add','Annot','App','Choice','Corr','Damage','Del',
           'Expan','Lem','Orig','Rdg','Ref','Reg','Restore','Sic','Subst','Supplied',
           'Unclear','SystemMilestoneEnd','PageMilestoneEnd','FloatingPositioner',
           'FloatingCurvePositioner','ArcPerformer','ScoreDefElement','SystemAligner',
           'Alignment','StaffAlignment','TimestampAligner','MeasureAligner','GraceAligner',
           'Fb','DocObject'}

def get_classname(cppname):
    # inline in the header first
    for f in os.listdir(INC):
        if not f.endswith('.h'): continue
        hh = open(os.path.join(INC,f)).read()
        m = re.search(r'std::string GetClassName\(\) const override \{ return "([^"]+)";', hh)
        if m and re.search(r'class '+cppname+r'\s*[:{]', hh):
            return m.group(1)
        m = re.search(r'std::string '+cppname+r'::GetClassName\(\) const override \{ return "([^"]+)";', hh)
        if m: return m.group(1)
    p = os.path.join(SRC, cppname[0].lower()+cppname[1:]+'.cpp')
    if os.path.exists(p):
        m = re.search(r'std::string '+cppname+r'::GetClassName\(\)(?: const)?\s*\{\s*return "([^"]+)"', open(p).read())
        if m: return m.group(1)
    return None

def parse_supported(cppname):
    p = os.path.join(SRC, cppname[0].lower()+cppname[1:]+'.cpp')
    if not os.path.exists(p): return None, []
    body_m = re.search(r'bool '+cppname+r'::IsSupportedChild\(ClassId classId\)\s*\{(.*?)\n\}', open(p).read(), re.S)
    if not body_m: return None, []
    body = body_m.group(1)
    ids = []
    sm = re.search(r'supported\{([^}]*)\}', body)
    if sm:
        for tok in sm.group(1).split(','):
            tok=tok.strip()
            if tok and tok in classid_names:
                ids.append(classid_names[tok])
            elif tok.startswith('FACTORY'):
                pass
    checks=[]
    for cn in ['Control','Editorial','Layer','Page','Running','ScoreDef','System','Text']:
        if f'Is{cn}Element(classId)' in body:
            checks.append(f'Object.is{cn}ElementId(classId)')
    return ids, checks

used_imports=set()
used_att_files=set()
warnings=[]
class_imports = {}   # class name -> set of ('atts'|'model'|'interfaces', path)
current_class = None

_last = None

def gen_class(name, bases):
    global _last, current_class
    current_class = name
    class_imports[name] = set()
    base = next((b for b in bases if b in BASE_CLASSES), None)
    if base is None:
        return None
    interfaces = [b for b in bases if b in INTERFACES]
    if 'TimeSpanningInterface' in interfaces and 'TimePointInterface' not in interfaces:
        interfaces.insert(interfaces.index('TimeSpanningInterface'), 'TimePointInterface')
    localmix = [b for b in bases if b in LOCAL_MIXINS]
    atts = [b for b in bases if b.startswith('Att') and b in att_mixins]
    unknown_atts = [b for b in bases if b.startswith('Att') and b not in att_mixins]
    for u in unknown_atts:
        warnings.append(f'{name}: missing generated att {u}')
    other = [b for b in bases if b not in BASE_CLASSES and b not in INTERFACES
             and b not in LOCAL_MIXINS and not b.startswith('Att')]
    if other:
        warnings.append(f'{name}: unhandled bases {other}')
        return None

    classname = get_classname(name)
    if classname is None:
        warnings.append(f'{name}: no GetClassName found')
        classname = name.lower()

    cid = classid_names.get(name.lower())
    if cid is None:
        warnings.append(f'{name}: no ClassId mapping')
        return None
    last = (cid, classname)

    imports = set()
    with_list = []

    if BASE_CLASSES.get(base):
        used_imports.add(('model', BASE_CLASSES[base]))
        class_imports[name].add(('model', BASE_CLASSES[base]))

    # constraints first (atts of interfaces), then remaining atts, then interfaces
    constraint_atts = []
    for i in interfaces:
        info = INTERFACES[i]
        for c in info[1]:
            if c.startswith('Att'):
                if c not in att_mixins:
                    warnings.append(f'{name}: interface {i} needs missing att {c}')
                    return None
                if c not in atts and c not in constraint_atts:
                    constraint_atts.append(c)
    plain_atts = [a for a in atts if a not in constraint_atts]

    for a in constraint_atts + plain_atts:
        afn = att_module.get(a)
        used_att_files.add(afn)
        if afn:
            class_imports[name].add(('file', 'package:verovio_dart/src/model/atts/' + afn))

    for a in constraint_atts + plain_atts:
        with_list.append(a)
    for _tl in ('TextListInterface', 'DrawingListInterface'):
        if _tl in localmix and 'ObjectListInterface' not in localmix:
            localmix.insert(localmix.index(_tl), 'ObjectListInterface')
    for l in localmix:
        imp = LOCAL_MIXINS[l][0]
        used_imports.add(('model', imp))
        class_imports[name].add(('model', imp))
        with_list.append(l)
    for i in interfaces:
        info = INTERFACES[i]
        used_imports.add(('interfaces', info[0]))
        class_imports[name].add(('interfaces', info[0]))
        with_list.append(i)

    # interface id registrations
    reg_ids = [INTERFACES[i][2] for i in interfaces]

    supported_ids, checks = parse_supported(name)

    L = []
    L.append(f'/// Mirrors `vrv::{name}`.')
    L.append(f'class {name} extends {base}')
    if with_list:
        L.append('    with')
        L.append('        ' + ',\n        '.join(with_list) + ' {')
    else:
        L.append(' {')
    L.append(f'  {name}() : super(ClassId.{cid}) {{')
    if reg_ids:
        L.append('    registerInterfaces([')
        for rid in reg_ids:
            L.append(f'      InterfaceId.{rid},')
        L.append('    ]);')
    L.append('    reset();')
    L.append('  }')
    L.append('')
    L.append('  @override')
    L.append(f'  String get className => \'{classname}\';')
    L.append('')
    L.append('  @override')
    L.append(f'  Object clone() {{')
    L.append(f'    final copy = {name}();')
    L.append('    copy.copyFrom(this);')
    L.append('    return copy;')
    L.append('  }')
    L.append('')
    # copyFrom: interfaces + own atts
    calls = []
    for i in interfaces:
        short_i = i[:-len('Interface')]
        calls.append(f'copy{short_i}From(other);')
    for a in plain_atts + constraint_atts:
        short = a[3:]
        calls.append(f'copyAtt{short}(other);')
    if calls:
        L.append('  @override')
        L.append(f'  void copyFrom(covariant {name} other) {{')
        if base != 'Object':
            L.append('    super.copyFrom(other);')
        for c in calls:
            L.append(f'    {c}')
        L.append('  }')
        L.append('')
    # isSupportedChild
    if supported_ids is not None:
        L.append('  @override')
        L.append('  bool isSupportedChild(ClassId classId) {')
        if supported_ids:
            L.append('    const supported = {')
            for sid in dict.fromkeys(supported_ids):
                L.append(f'      ClassId.{sid},')
            L.append('    };')
            L.append('    if (supported.contains(classId)) return true;')
        for chk in checks:
            L.append(f'    if ({chk}) return true;')
        L.append('    return false;')
        L.append('  }')
        L.append('')
    L.append('}')
    return '\n'.join(L), cid, classname

GROUPS = {
    'control': lambda bases: 'ControlElement' in bases,
    'layer': lambda bases: 'LayerElement' in bases,
}
def group_of(bases):
    if 'ControlElement' in bases: return 'control'
    if 'LayerElement' in bases: return 'layer'
    return 'misc'

outputs = {'control':[], 'layer':[], 'misc':[]}
factory_lines = []
count=0
for name, bases, _file in WANTED:
    if name in ALREADY or name in BASE_CLASSES: continue
    result = gen_class(name, bases)
    if result is None: continue
    code, cid, classname = result
    outputs[group_of(bases)].append(code)
    factory_lines.append(f"  f.register('{classname}', ClassId.{cid}, {name}.new);")
    count+=1

HEADER = '''// GENERATED FILE - one-shot migration from origin/src/include/vrv.
// Element leaf classes; regenerate via tool/gen_elements.py when the C++
// source changes. Do not hand-edit lightly.

'''
IMPORT_ORDER = [
    'package:verovio_dart/src/core/vrvdef.dart',
]
def write_group(key, filename):
    body = outputs[key]
    if not body: return
    out = HEADER
    seen = set()

    import re as _re
    union = set()
    for c in body:
        mm = _re.search(r'class (\w+) extends', c)
        if mm:
            union |= class_imports.get(mm.group(1), set())

    def emit_full(full):
        if full not in seen:
            seen.add(full)
            return f"import '{full}';\n"
        return ''

    for ip in sorted(union):
        if ip[0] == 'file':
            full = ip[1]
        elif ip[0] == 'interfaces':
            full = f'package:verovio_dart/src/model/interfaces/{ip[1]}'
        else:
            full = f'package:verovio_dart/src/model/{ip[1]}'
        out += emit_full(full)
    for imp in IMPORT_ORDER:
        out += emit_full(imp)
    import sys as _sys
    out += '\n' + '\n\n'.join(body) + '\n'

    # drop imports whose file declares none of the symbols used in body
    body_text = '\n'.join(body)
    kept = []
    for line in out.split('\n'):
        m = re.match(r"import '([^']+)';", line)
        if m and m.group(1).startswith('package:verovio_dart/'):
            rel = m.group(1).replace('package:verovio_dart/', ROOT_REL + '/')
            try:
                decl = open(rel).read()
                syms = re.findall(r'^(?:class|mixin) (\w+)', decl, re.M)
                if syms and not any(sym in body_text for sym in syms):
                    continue
            except FileNotFoundError:
                pass
        kept.append(line)
    out = '\n'.join(kept)

    open(os.path.join(OUT, filename), 'w').write(out)
    print(filename, len(body), 'classes')

open(os.path.join(OUT,'factory_registry_gen.dart'),'w').write(
'''// GENERATED FILE - one-shot migration from origin/src/include/vrv.

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';

/// Registers all classes generated by tool/gen_elements.py.
void registerGeneratedClasses(ObjectFactory f) {
''' + '\n'.join(factory_lines) + '\n}\n')
print('factory lines', len(factory_lines))
write_group('control','control_elements_gen.dart')
write_group('layer','layer_elements_gen.dart')
write_group('misc','misc_elements_gen.dart')
print('total generated:', count)
print()
for w in warnings[:40]:
    print('WARN', w)
