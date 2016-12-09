#pragma once

#include "Plane.h"

namespace ospray {

    struct ClipPlane : public Plane {

        std::string toString() const override;
        void commit() override;

        ClipPlane();
        //~ClipPlane();

    };

    //! \brief common function to help printf-debugging
    inline std::string ClipPlane::toString() const { return "ospray::ClipPlane"; }

} // ::ospray