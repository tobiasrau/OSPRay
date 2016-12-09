#pragma once

#include "common/Managed.h"

namespace ospray {

    /*! \brief implements the basic abstraction for anything that is a 'clipplane'.

     */
    struct OSPRAY_SDK_INTERFACE Plane : public ManagedObject {
        //! \brief common function to help printf-debugging
        /*! Every derived class should overrride this! */
        virtual std::string toString() const { return "ospray::Plane (base class)"; }

        //! \brief commit the planes's parameters
        virtual void commit() {};

        /*! \brief creates an abstract plane class */
        static Plane *createPlane(const char *identifier);

        //! Destructor
        virtual ~Plane();

    public:
        // ------------------------------------------------------------------
        // parameters that each plane has, 'parsed' from params
        // ------------------------------------------------------------------
        float dist;     // one point in the plane
        vec3f normal;    // normal vector of the plane
        vec4f color;
    };


    /*! \brief registers a internal ospray::'ClassName' clipplane under
    the externally accessible name "external_name"

    \internal This currently works by defining a extern "C" function
    with a given predefined name that creates a new instance of this
    plane. By having this symbol in the shared lib ospray can
    lateron always get a handle to this fct and create an instance
    of this plane.
    */
#define OSP_REGISTER_PLANE(InternalClass, external_name) \
  OSP_REGISTER_OBJECT(Plane, plane, InternalClass, external_name)

} // ::ospray
