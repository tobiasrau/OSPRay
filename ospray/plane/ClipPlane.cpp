#include "ClipPlane.h"
#include "ClipPlane_ispc.h"
#include "common/Data.h"

namespace ospray {

    ClipPlane::ClipPlane() {
        ispcEquivalent = ispc::ClipPlane_createInstance(this);
    }

    void ClipPlane::commit() 
    {
        dist = getParam1f("dist", 0.f);
        normal = getParam3f("normal", vec3f(1.f, 0.f, 0.f));
        color = getParam4f("color", vec4f(0.8f, 0.8f, 0.8f, 1.0f));

        ispc::ClipPlane_set(ispcEquivalent,
            dist,
            (ispc::vec3f&)normal,
            (ispc::vec4f&)color);
    }

    OSP_REGISTER_PLANE(ClipPlane, clipPlane);

} // ::ospray