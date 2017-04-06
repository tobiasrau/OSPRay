
// ospray
#include "Plane.h"
#include "common/Library.h"
// ispc-side stuff
#include "Plane_ispc.h"
// stl
#include <map>

namespace ospray {

    //! Destructor
    Plane::~Plane() {}

    /*! \brief creates an abstract clipplane class */
    Plane *Plane::createPlane(const char *type) {

        // Function pointer type for creating a concrete instance of a subtype of
        // this class.
        typedef Plane *(*creatorFct)();

        // Function pointers corresponding to each subtype.
        std::map<std::string, creatorFct> planeRegistry;

        // Find the creation function for the subtype if not already known.
        std::map<std::string, Plane *(*)()>::iterator it = planeRegistry.find(type);
        if (it != planeRegistry.end())
            return it->second ? (it->second)() : NULL;

        if (ospray::logLevel() >= 2)
            std::cout << "#ospray: trying to look up plane type '"
            << type << "' for the first time..." << std::endl;

        // Construct the name of the creation function to look for.
        std::string creatorName = "ospray_create_plane__" + std::string(type);
        
        // Look for the named function.
        creatorFct creator = (creatorFct)getSymbol(creatorName);
        planeRegistry[type] = creator;

        // The named function may not be found if the requested subtype is not
        // known.
        if (creator == NULL) {
            if (ospray::logLevel() >= 1)
                std::cout << "#ospray: could not find plane type '" << type << "'" << std::endl;
            return NULL;
        }

        // Create a concrete instance of the requested subtype.
        Plane *plane= (*creator)();

        // Denote the subclass type in the ManagedObject base class.
        plane->managedObjectType = OSP_PLANE;

        return plane;
    }

} // ::ospray
