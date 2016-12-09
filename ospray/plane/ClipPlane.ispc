#include "ClipPlane.ih"


void ClipPlane_Constructor(ClipPlane *uniform cpln, void *uniform cppEquivalent)
{
  Plane_Constructor(&cpln->super, cppEquivalent);
}

export void *uniform ClipPlane_createInstance(void *uniform cppEquivalent)
{
  ClipPlane *uniform plane = uniform new uniform ClipPlane;
  ClipPlane_Constructor(plane, cppEquivalent);

  return plane;
}

export void ClipPlane_set(void *uniform _pln,
                          const uniform float _dist,
                          const uniform vec3f& _normal,
						  const uniform vec4f& _color)
{
  uniform ClipPlane *uniform self = (uniform ClipPlane *uniform)_pln;

  self->super.dist = _dist;
  self->super.normal = _normal;
  self->super.color = _color;
}
