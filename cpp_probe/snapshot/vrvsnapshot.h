/////////////////////////////////////////////////////////////////////////////
// Name:        vrvsnapshot.h
// Purpose:     State-snapshot instrumentation for the Dart port (cpp_probe).
// NOT part of Verovio 6.2.0 — compiled into build-probe/ by
// cpp_probe/patches/snapshot.patch; the runtime lives in cpp_probe/snapshot/.
/////////////////////////////////////////////////////////////////////////////
//
// After every top-level functor run (an Object::Process call that returns
// with no other Process call on the stack) and after every View page draw
// started outside a functor, the tool dumps the state of the object tree —
// at the depth chosen on the command line — to the file named by the
// environment variable VRV_SNAPSHOT_OUT. When the variable is unset nothing
// is walked and nothing is written: the cost is one counter per Process call.
//
// READ-ONLY BY CONSTRUCTION: the dump reads members, never calls a getter
// that computes or fills a cache (see cpp_probe/snapshot/fields.manifest).
// cpp_probe/snapshot.sh re-verifies that the SVG is byte-identical to the
// golden for every file it dumps.
//
// The Dart twin is verovio_dart/tool/snapshot/recorder.dart; the two must
// produce the same checkpoint labels, the same keys and the same rows.

#ifndef __VRV_SNAPSHOT_H__
#define __VRV_SNAPSHOT_H__

namespace vrv {

class DeviceContext;
class Functor;
class Object;

namespace snapshot {

/** Depth of the (non-const) Object::Process calls currently on the stack. */
inline int &ProcessDepth()
{
    static int s_depth = 0;
    return s_depth;
}

/** True when VRV_SNAPSHOT_OUT names an output file (read once). */
bool Enabled();

/** A top-level functor run returned: checkpoint named after the functor class. */
void FunctorCheckpoint(const Functor &functor, const Object *object);

/** View::DrawCurrentPage returned outside any functor: "View::DrawCurrentPage[bbox|svg]". */
void DrawCheckpoint(const DeviceContext *dc, const Object *page);

/**
 * RAII guard, the first statement of Object::Process(Functor &, ...): counts
 * the depth and, when the outermost call returns, takes the checkpoint. The
 * const overload (ConstFunctor) is deliberately not hooked — a const functor
 * cannot change the state being dumped.
 */
class ProcessScope {
public:
    ProcessScope(const Functor &functor, const Object *object) : m_functor(functor), m_object(object)
    {
        ++ProcessDepth();
    }
    ~ProcessScope()
    {
        if (--ProcessDepth() == 0 && Enabled()) FunctorCheckpoint(m_functor, m_object);
    }

private:
    const Functor &m_functor;
    const Object *m_object;
};

} // namespace snapshot
} // namespace vrv

#endif // __VRV_SNAPSHOT_H__
