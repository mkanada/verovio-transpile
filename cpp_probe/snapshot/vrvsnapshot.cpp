/////////////////////////////////////////////////////////////////////////////
// Name:        vrvsnapshot.cpp
// Purpose:     State-snapshot runtime (see vrvsnapshot.h).
// NOT part of Verovio 6.2.0. Compiled with -fno-access-control (set by
// cpp_probe/patches/snapshot.patch) so the dump reads protected/private
// members directly instead of going through getters that compute.
/////////////////////////////////////////////////////////////////////////////
//
// Environment (cpp_probe/snapshot.sh sets these from its command line):
//   VRV_SNAPSHOT_OUT      output file; unset = disabled
//   VRV_SNAPSHOT_MODE     seq | digest | full                  (default digest)
//   VRV_SNAPSHOT_GROUPS   comma list of bb,pos,link,layout,cache, or all
//                                                              (default bb,pos)
//   VRV_SNAPSHOT_AT       ECMAScript regex, full match against "Name#k" or
//                         "@seq": the checkpoints dumped (default: all)
//   VRV_SNAPSHOT_PATH     substring the entity key must contain
//   VRV_SNAPSHOT_CLASS    comma list of entity class labels
//   VRV_SNAPSHOT_EXCLUDE  comma list left out of rows and digest: `field` (every
//                         class), `class.field` (one class label), `key:<text>`
//                         (every entity whose key contains <text>)
//   VRV_SNAPSHOT_SOURCE   the input file, echoed into the header line
//
// Output (JSON Lines): a `_meta` header, then one line per checkpoint
//   {"cp":<seq>,"fn":"<label>","k":<occurrence>,"on":"<class>","root":"<class>"
//    [,"rows":<n>,"digest":"<fnv64 hex>"]}
// and, in full mode, one line per entity after its checkpoint
//   {"cp":<seq>,"key":"<key>","class":"<label>","<field>":<value>,...}
//
// Every rule below — checkpoint labels, the key scheme, the canonical form the
// digest hashes — is mirrored line by line in
// verovio_dart/tool/snapshot/recorder.dart. Change both or neither.

#include "vrvsnapshot.h"

//----------------------------------------------------------------------------

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cxxabi.h>
#include <map>
#include <regex>
#include <set>
#include <string>
#include <typeindex>
#include <typeinfo>
#include <unordered_map>
#include <vector>

//----------------------------------------------------------------------------

#include "accid.h"
#include "artic.h"
#include "barline.h"
#include "beam.h"
#include "clef.h"
#include "devicecontext.h"
#include "doc.h"
#include "drawinginterface.h"
#include "elementpart.h"
#include "ending.h"
#include "floatingobject.h"
#include "fraction.h"
#include "functor.h"
#include "horizontalaligner.h"
#include "keysig.h"
#include "layer.h"
#include "layerelement.h"
#include "measure.h"
#include "mensur.h"
#include "metersig.h"
#include "metersiggrp.h"
#include "note.h"
#include "page.h"
#include "positioninterface.h"
#include "proport.h"
#include "scoredef.h"
#include "slur.h"
#include "staff.h"
#include "staffdef.h"
#include "stem.h"
#include "syl.h"
#include "system.h"
#include "timeinterface.h"
#include "tuplet.h"
#include "verticalaligner.h"

namespace vrv {
namespace snapshot {

enum { G_BB = 1, G_POS = 2, G_LINK = 4, G_LAYOUT = 8, G_CACHE = 16 };

//----------------------------------------------------------------------------
// Text helpers
//----------------------------------------------------------------------------

static std::string Json(const std::string &str)
{
    std::string out;
    out.reserve(str.size() + 2);
    for (const char chr : str) {
        switch (chr) {
            case '"': out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            default:
                if (static_cast<unsigned char>(chr) < 0x20) {
                    char buffer[8];
                    std::snprintf(buffer, sizeof(buffer), "\\u%04x", static_cast<unsigned char>(chr));
                    out += buffer;
                }
                else {
                    out += chr;
                }
        }
    }
    return out;
}

static std::vector<std::string> SplitComma(const char *text)
{
    std::vector<std::string> out;
    if (!text) return out;
    std::string current;
    for (const char *p = text;; ++p) {
        if (*p == ',' || *p == '\0') {
            if (!current.empty()) out.push_back(current);
            current.clear();
            if (*p == '\0') break;
        }
        else if (*p != ' ') {
            current += *p;
        }
    }
    return out;
}

static std::string Hex64(uint64_t value)
{
    char buffer[24];
    std::snprintf(buffer, sizeof(buffer), "%016llx", static_cast<unsigned long long>(value));
    return buffer;
}

/** FNV-1a, 64 bits. */
static uint64_t Fnv64(const std::string &bytes)
{
    uint64_t hash = 0xcbf29ce484222325ULL;
    for (const unsigned char c : bytes) {
        hash ^= c;
        hash *= 0x100000001b3ULL;
    }
    return hash;
}

//----------------------------------------------------------------------------
// Configuration
//----------------------------------------------------------------------------

struct Config {
    bool enabled = false;
    FILE *out = NULL;
    std::string mode = "digest";
    unsigned groups = G_BB | G_POS;
    bool hasAt = false;
    std::regex at;
    std::string path;
    std::set<std::string> classes;
    std::set<std::string> exclude;
    std::vector<std::string> excludeKeys;
};

static std::string JoinSet(const std::set<std::string> &items)
{
    std::string out;
    for (const std::string &item : items) out += (out.empty() ? "" : ",") + item;
    return out;
}

static Config &Cfg()
{
    static Config s_config;
    static bool s_loaded = false;
    if (s_loaded) return s_config;
    s_loaded = true;

    const char *outPath = std::getenv("VRV_SNAPSHOT_OUT");
    if (!outPath || !*outPath) return s_config;
    s_config.out = std::fopen(outPath, "w");
    if (!s_config.out) {
        std::fprintf(stderr, "vrvsnapshot: cannot open %s\n", outPath);
        return s_config;
    }
    s_config.enabled = true;

    const char *mode = std::getenv("VRV_SNAPSHOT_MODE");
    if (mode && *mode) s_config.mode = mode;
    const char *groups = std::getenv("VRV_SNAPSHOT_GROUPS");
    if (groups && *groups) {
        s_config.groups = 0;
        for (const std::string &g : SplitComma(groups)) {
            if (g == "all") s_config.groups |= G_BB | G_POS | G_LINK | G_LAYOUT | G_CACHE;
            else if (g == "bb") s_config.groups |= G_BB;
            else if (g == "pos") s_config.groups |= G_POS;
            else if (g == "link") s_config.groups |= G_LINK;
            else if (g == "layout") s_config.groups |= G_LAYOUT;
            else if (g == "cache") s_config.groups |= G_CACHE;
            else std::fprintf(stderr, "vrvsnapshot: unknown group '%s'\n", g.c_str());
        }
    }
    const char *at = std::getenv("VRV_SNAPSHOT_AT");
    if (at && *at) {
        s_config.hasAt = true;
        s_config.at = std::regex(at, std::regex::ECMAScript);
    }
    const char *path = std::getenv("VRV_SNAPSHOT_PATH");
    if (path) s_config.path = path;
    for (const std::string &c : SplitComma(std::getenv("VRV_SNAPSHOT_CLASS"))) s_config.classes.insert(c);
    for (const std::string &f : SplitComma(std::getenv("VRV_SNAPSHOT_EXCLUDE"))) {
        if (f.rfind("key:", 0) == 0) s_config.excludeKeys.push_back(f.substr(4));
        s_config.exclude.insert(f);
    }

    const char *source = std::getenv("VRV_SNAPSHOT_SOURCE");
    std::string meta = "{\"_meta\":{\"side\":\"cpp\",\"source\":\"" + Json(source ? source : "") + "\",\"mode\":\""
        + Json(s_config.mode) + "\",\"groups\":" + std::to_string(s_config.groups) + ",\"at\":\""
        + Json(at ? at : "") + "\",\"path\":\"" + Json(s_config.path) + "\",\"class\":\""
        + Json(JoinSet(s_config.classes)) + "\",\"exclude\":\"" + Json(JoinSet(s_config.exclude)) + "\"}}\n";
    std::fputs(meta.c_str(), s_config.out);
    std::fflush(s_config.out);
    return s_config;
}

bool Enabled()
{
    return Cfg().enabled;
}

//----------------------------------------------------------------------------
// Walker — collects every entity of a tree with its key
//----------------------------------------------------------------------------

struct Entity {
    const BoundingBox *bb;
    std::string key;
    std::string cls;
};

static std::string ClassLabel(const Object *object)
{
    if (object->Is(DOC)) return "doc";
    return object->GetClassName();
}

/** `<class>[<@n or index>]` — the probe::Path segment, computed top-down. */
static std::string Segment(const Object *object, int index)
{
    std::string key;
    if (object->Is(MEASURE)) {
        const Measure *measure = dynamic_cast<const Measure *>(object);
        if (measure && measure->HasN()) key = measure->GetN();
    }
    else if (object->Is(STAFF)) {
        const Staff *staff = dynamic_cast<const Staff *>(object);
        if (staff && staff->HasN()) key = std::to_string(staff->GetN());
    }
    else if (object->Is(LAYER)) {
        const Layer *layer = dynamic_cast<const Layer *>(object);
        if (layer && layer->HasN()) key = std::to_string(layer->GetN());
    }
    if (key.empty()) key = std::to_string(index);
    return ClassLabel(object) + "[" + key + "]";
}

static std::string AlignmentSegment(const Alignment *alignment)
{
    return "alignment[" + std::to_string(alignment->m_time.GetNumerator()) + "/"
        + std::to_string(alignment->m_time.GetDenominator()) + ":" + std::to_string((int)alignment->m_type) + "]";
}

/** The key of a pointer that no longer points at an object of its type (see Valid). */
static const BoundingBox *StaleMarker()
{
    static const char s_marker = 0;
    return reinterpret_cast<const BoundingBox *>(&s_marker);
}

class Walker {
public:
    std::vector<Entity> m_entities;

    /**
     * Verovio keeps pointers to objects it has deleted (LayerElement::m_alignment after the
     * aligners are rebuilt, …) and never reads them again. The allocator may place a new
     * object at the same address, so a stale pointer can "resolve" to an unrelated live
     * entity — non-deterministically. [target] is accepted only when the live entity at its
     * address really is a T (the dynamic_cast is safe: that object is alive); anything else
     * is StaleMarker(), dumped as "~" like a pointer outside the walked tree.
     */
    template <typename T> const BoundingBox *Valid(const T *target) const
    {
        if (!target) return NULL;
        const BoundingBox *bb = target; // static upcast: no dereference
        auto it = m_index.find(bb);
        if (it == m_index.end()) return StaleMarker();
        if (dynamic_cast<const T *>(m_entities[it->second].bb) != target) return StaleMarker();
        return bb;
    }

    void Walk(const Object *root)
    {
        this->VisitObject(root, root->Is(DOC) ? "doc" : Segment(root, 1));
        // Aligners last: positioner keys are built from the keys of their objects.
        for (const auto &entry : m_measures) this->VisitMeasureAligner(entry.first, entry.second);
        for (const auto &entry : m_systems) this->VisitSystemAligner(entry.first, entry.second);
    }

    std::string KeyOf(const BoundingBox *bb) const
    {
        if (!bb) return "null";
        if (bb == StaleMarker()) return "~";
        auto it = m_index.find(bb);
        if (it != m_index.end()) return m_entities[it->second].key;
        // Not in the walked tree. Never dereference it: Verovio legitimately keeps
        // dangling pointers it no longer reads (Staff::m_staffAlignment right after
        // Doc::CastOffDocBase deletes the uncast-off page, …).
        return "~";
    }

private:
    std::unordered_map<const BoundingBox *, size_t> m_index;
    std::unordered_map<std::string, int> m_keyCount;
    std::vector<std::pair<const Measure *, std::string>> m_measures;
    std::vector<std::pair<const System *, std::string>> m_systems;

    bool Seen(const BoundingBox *bb) const { return m_index.count(bb) != 0; }

    /** Registers an entity; a repeated key gets "#2", "#3"… in walk order. */
    std::string Add(const BoundingBox *bb, std::string key, const std::string &cls)
    {
        const int count = ++m_keyCount[key];
        if (count > 1) key += "#" + std::to_string(count);
        m_index[bb] = m_entities.size();
        m_entities.push_back({ bb, key, cls });
        return key;
    }

    void VisitObject(const Object *object, const std::string &proposedKey)
    {
        if (this->Seen(object)) return;
        const std::string key = this->Add(object, proposedKey, ClassLabel(object));
        // Children of the doc are keyed like probe::Path (no "doc/" prefix);
        // measures restart the key (probe::Path is rooted at the measure).
        const std::string prefix = object->Is(DOC) ? "" : key;
        std::map<std::string, int> counts;
        for (const Object *child : object->GetChildren()) {
            const int index = ++counts[ClassLabel(child)];
            const std::string segment = Segment(child, index);
            this->VisitObject(child, (child->Is(MEASURE) || prefix.empty()) ? segment : prefix + "/" + segment);
        }
        this->VisitMembers(object, key);
    }

    void VisitMember(const Object *member, const std::string &parentKey, const std::string &role)
    {
        if (!member) return;
        this->VisitObject(member, parentKey + "/" + ClassLabel(member) + "[" + role + "]");
    }

    /** Objects owned by a member of their parent rather than by its children list. */
    void VisitMembers(const Object *object, const std::string &key)
    {
        if (const Measure *measure = dynamic_cast<const Measure *>(object)) {
            this->VisitMember(&measure->m_leftBarLine, key, "left");
            this->VisitMember(&measure->m_rightBarLine, key, "right");
            this->VisitMember(measure->m_drawingScoreDef, key, "drawing");
            m_measures.push_back({ measure, key });
        }
        if (const Layer *layer = dynamic_cast<const Layer *>(object)) {
            this->VisitMember(layer->m_staffDefClef, key, "staffDef");
            this->VisitMember(layer->m_staffDefKeySig, key, "staffDef");
            this->VisitMember(layer->m_staffDefMensur, key, "staffDef");
            this->VisitMember(layer->m_staffDefMeterSig, key, "staffDef");
            this->VisitMember(layer->m_staffDefMeterSigGrp, key, "staffDef");
            this->VisitMember(layer->m_cautionStaffDefClef, key, "caution");
            this->VisitMember(layer->m_cautionStaffDefKeySig, key, "caution");
            this->VisitMember(layer->m_cautionStaffDefMensur, key, "caution");
            this->VisitMember(layer->m_cautionStaffDefMeterSig, key, "caution");
        }
        if (const System *system = dynamic_cast<const System *>(object)) {
            this->VisitMember(system->m_drawingScoreDef, key, "drawing");
            m_systems.push_back({ system, key });
        }
        if (const Page *page = dynamic_cast<const Page *>(object)) {
            this->VisitMember(&page->m_drawingScoreDef, key, "drawing");
        }
        if (const StaffDefDrawingInterface *interface = dynamic_cast<const StaffDefDrawingInterface *>(object)) {
            this->VisitMember(&interface->m_currentClef, key, "current");
            this->VisitMember(&interface->m_currentKeySig, key, "current");
            this->VisitMember(&interface->m_currentMensur, key, "current");
            this->VisitMember(&interface->m_currentMeterSig, key, "current");
            this->VisitMember(&interface->m_currentMeterSigGrp, key, "current");
            this->VisitMember(&interface->m_currentProport, key, "current");
        }
    }

    void VisitMeasureAligner(const Measure *measure, const std::string &measureKey)
    {
        const MeasureAligner *aligner = &measure->m_measureAligner;
        if (this->Seen(aligner)) return;
        this->Add(aligner, measureKey + "/measureAligner", "measureAligner");
        for (const Object *child : aligner->GetChildren()) {
            const Alignment *alignment = dynamic_cast<const Alignment *>(child);
            if (alignment) this->VisitAlignment(alignment, measureKey + "/" + AlignmentSegment(alignment));
        }
    }

    void VisitAlignment(const Alignment *alignment, const std::string &proposedKey)
    {
        if (this->Seen(alignment)) return;
        const std::string key = this->Add(alignment, proposedKey, "alignment");
        for (const Object *child : alignment->GetChildren()) {
            const AlignmentReference *reference = dynamic_cast<const AlignmentReference *>(child);
            if (!reference || this->Seen(reference)) continue;
            // References only: the layer elements below are owned by their layer.
            this->Add(reference,
                key + "/ref[" + (reference->HasN() ? std::to_string(reference->GetN()) : std::string("?")) + "]",
                "alignmentReference");
        }
        for (const auto &entry : alignment->m_graceAligners) {
            const GraceAligner *graceAligner = entry.second;
            if (!graceAligner || this->Seen(graceAligner)) continue;
            const std::string graceKey
                = this->Add(graceAligner, key + "/graceAligner[" + std::to_string(entry.first) + "]", "graceAligner");
            for (const Object *child : graceAligner->GetChildren()) {
                const Alignment *graceAlignment = dynamic_cast<const Alignment *>(child);
                if (graceAlignment) this->VisitAlignment(graceAlignment, graceKey + "/" + AlignmentSegment(graceAlignment));
            }
        }
    }

    void VisitSystemAligner(const System *system, const std::string &systemKey)
    {
        const SystemAligner *aligner = &system->m_systemAligner;
        if (this->Seen(aligner)) return;
        this->Add(aligner, systemKey + "/systemAligner", "systemAligner");
        for (const Object *child : aligner->GetChildren()) {
            const StaffAlignment *staffAlignment = dynamic_cast<const StaffAlignment *>(child);
            if (!staffAlignment || this->Seen(staffAlignment)) continue;
            const std::string n
                = staffAlignment->m_staff ? std::to_string(staffAlignment->m_staff->GetN()) : std::string("none");
            const std::string staffKey
                = this->Add(staffAlignment, systemKey + "/staffAlignment[" + n + "]", "staffAlignment");
            for (const FloatingPositioner *positioner : staffAlignment->m_floatingPositioners) {
                if (!positioner || this->Seen(positioner)) continue;
                const std::string cls = dynamic_cast<const FloatingCurvePositioner *>(positioner)
                    ? "floatingCurvePositioner"
                    : "floatingPositioner";
                this->Add(positioner, staffKey + "/" + cls + "[" + this->KeyOf(this->Valid(positioner->m_object)) + "]",
                    cls);
            }
        }
    }
};

//----------------------------------------------------------------------------
// Row — one entity's fields, as JSON and as the canonical text the digest hashes
//----------------------------------------------------------------------------

class Row {
public:
    Row(const Entity &entity, const Config &config, const Walker &walker)
        : m_config(config), m_walker(walker), m_key(entity.key), m_cls(entity.cls)
    {
        m_canonical = entity.key + '\x1f' + entity.cls;
    }

    bool Wants(unsigned group) const { return (m_config.groups & group) != 0; }

    void Int(const char *name, long long value) { this->Add(name, std::to_string(value), std::to_string(value)); }

    void Bool(const char *name, bool value) { this->Add(name, value ? "1" : "0", value ? "true" : "false"); }

    void Double(const char *name, double value)
    {
        std::string canonical;
        std::string json;
        if (std::isnan(value)) {
            canonical = "dnan";
            json = "\"nan\"";
        }
        else {
            const double normalized = (value == 0.0) ? 0.0 : value; // -0.0 == 0.0
            uint64_t bits;
            std::memcpy(&bits, &normalized, sizeof(bits));
            canonical = "d" + Hex64(bits);
            if (std::isinf(value)) {
                json = (value > 0) ? "\"inf\"" : "\"-inf\"";
            }
            else {
                char buffer[40];
                std::snprintf(buffer, sizeof(buffer), "%.17g", normalized);
                json = buffer;
            }
        }
        this->Add(name, canonical, json);
    }

    template <typename T> void Ref(const char *name, const T *target)
    {
        const std::string key = m_walker.KeyOf(m_walker.Valid(target));
        this->Add(name, key, target ? "\"" + Json(key) + "\"" : "null");
    }

    /** A refs element, type-checked like Ref (see Walker::Valid). */
    template <typename T> const BoundingBox *Valid(const T *target) const { return m_walker.Valid(target); }

    void Refs(const char *name, const std::vector<const BoundingBox *> &targets)
    {
        std::string canonical = "[";
        std::string json = "[";
        for (size_t i = 0; i < targets.size(); ++i) {
            if (i) {
                canonical += ",";
                json += ",";
            }
            const std::string key = m_walker.KeyOf(targets[i]);
            canonical += key;
            json += targets[i] ? "\"" + Json(key) + "\"" : "null";
        }
        this->Add(name, canonical + "]", json + "]");
    }

    void Frac(const char *name, const Fraction &fraction)
    {
        const std::string n = std::to_string(fraction.GetNumerator());
        const std::string d = std::to_string(fraction.GetDenominator());
        this->Add(name, n + "/" + d, "[" + n + "," + d + "]");
    }

    void Ints(const char *name, const std::vector<long long> &values)
    {
        std::string text = "[";
        for (size_t i = 0; i < values.size(); ++i) {
            if (i) text += ",";
            text += std::to_string(values[i]);
        }
        text += "]";
        this->Add(name, text, text);
    }

    uint64_t Hash() const { return Fnv64(m_canonical); }

    std::string JsonLine(int cp) const
    {
        return "{\"cp\":" + std::to_string(cp) + ",\"key\":\"" + Json(m_key) + "\",\"class\":\"" + Json(m_cls) + "\""
            + m_json + "}\n";
    }

private:
    void Add(const char *name, const std::string &canonical, const std::string &json)
    {
        if (m_config.exclude.count(name) || m_config.exclude.count(m_cls + "." + name)) return;
        m_canonical += '\x1e';
        m_canonical += name;
        m_canonical += '=';
        m_canonical += canonical;
        m_json += ",\"";
        m_json += name;
        m_json += "\":";
        m_json += json;
    }

    const Config &m_config;
    const Walker &m_walker;
    std::string m_key;
    std::string m_cls;
    std::string m_canonical;
    std::string m_json;
};

//----------------------------------------------------------------------------
// Helpers named by the manifest
//----------------------------------------------------------------------------

/** Dots::m_dotLocsByStaff, deterministic: per staff (sorted by @n) n, count, locs… */
static std::vector<long long> DotLocs(const Dots *dots)
{
    std::vector<std::pair<int, std::vector<long long>>> perStaff;
    for (const auto &entry : dots->m_dotLocsByStaff) {
        std::vector<long long> locs(entry.second.begin(), entry.second.end());
        perStaff.push_back({ entry.first ? entry.first->GetN() : -1, locs });
    }
    std::sort(perStaff.begin(), perStaff.end());
    std::vector<long long> out;
    for (const auto &staff : perStaff) {
        out.push_back(staff.first);
        out.push_back((long long)staff.second.size());
        out.insert(out.end(), staff.second.begin(), staff.second.end());
    }
    return out;
}

#include "vrvsnapshot_fields.inc"

//----------------------------------------------------------------------------
// Checkpoints
//----------------------------------------------------------------------------

static void Checkpoint(const std::string &label, const Object *object)
{
    Config &config = Cfg();
    if (!config.enabled || !object) return;
    static const std::regex s_skip(kSkipFunctors, std::regex::ECMAScript);
    if (std::regex_match(label, s_skip)) return;

    static int s_seq = 0;
    static std::map<std::string, int> s_occurrences;
    const int seq = ++s_seq;
    const int occurrence = ++s_occurrences[label];

    const Object *root = object;
    while (root->GetParent()) root = root->GetParent();

    std::string line = "{\"cp\":" + std::to_string(seq) + ",\"fn\":\"" + Json(label)
        + "\",\"k\":" + std::to_string(occurrence) + ",\"on\":\"" + Json(ClassLabel(object)) + "\",\"root\":\""
        + Json(ClassLabel(root)) + "\"";

    bool selected = (config.mode != "seq");
    if (selected && config.hasAt) {
        selected = std::regex_match(label + "#" + std::to_string(occurrence), config.at)
            || std::regex_match("@" + std::to_string(seq), config.at);
    }
    if (!selected) {
        line += "}\n";
        std::fputs(line.c_str(), config.out);
        std::fflush(config.out);
        return;
    }

    Walker walker;
    walker.Walk(root);

    uint64_t digest = 0;
    int count = 0;
    std::string rows;
    for (const Entity &entity : walker.m_entities) {
        if (!config.classes.empty() && !config.classes.count(entity.cls)) continue;
        if (!config.path.empty() && entity.key.find(config.path) == std::string::npos) continue;
        bool excluded = false;
        for (const std::string &text : config.excludeKeys) {
            if (entity.key.find(text) != std::string::npos) excluded = true;
        }
        if (excluded) continue;
        Row row(entity, config, walker);
        EmitFields(entity.bb, row);
        digest += row.Hash();
        ++count;
        if (config.mode == "full") rows += row.JsonLine(seq);
    }
    line += ",\"rows\":" + std::to_string(count) + ",\"digest\":\"" + Hex64(digest) + "\"}\n";
    std::fputs(line.c_str(), config.out);
    std::fputs(rows.c_str(), config.out);
    std::fflush(config.out);
}

static std::string FunctorName(const Functor &functor)
{
    static std::unordered_map<std::type_index, std::string> s_names;
    const std::type_index type(typeid(functor));
    auto it = s_names.find(type);
    if (it != s_names.end()) return it->second;
    int status = 0;
    char *demangled = abi::__cxa_demangle(typeid(functor).name(), NULL, NULL, &status);
    std::string name = (status == 0 && demangled) ? demangled : typeid(functor).name();
    std::free(demangled);
    if (name.rfind("vrv::", 0) == 0) name = name.substr(5);
    s_names[type] = name;
    return name;
}

void FunctorCheckpoint(const Functor &functor, const Object *object)
{
    Checkpoint(FunctorName(functor), object);
}

void DrawCheckpoint(const DeviceContext *dc, const Object *page)
{
    Checkpoint(dc->Is(BBOX_DEVICE_CONTEXT) ? "View::DrawCurrentPage[bbox]" : "View::DrawCurrentPage[svg]", page);
}

} // namespace snapshot
} // namespace vrv
