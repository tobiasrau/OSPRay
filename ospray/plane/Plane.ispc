#include "Plane.ih"

void Plane_Constructor(uniform Plane* uniform self,
                       void *uniform cppEquivalent
					   )
{
  self->cppEquivalent = cppEquivalent;
  self->dist = 0.f;
  self->normal = make_vec3f(0.f);
  self->color = make_vec4f(0.f);
}
