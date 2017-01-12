// ======================================================================== //
// Copyright 2009-2016 Intel Corporation                                    //
//                                                                          //
// Licensed under the Apache License, Version 2.0 (the "License");          //
// you may not use this file except in compliance with the License.         //
// You may obtain a copy of the License at                                  //
//                                                                          //
//     http://www.apache.org/licenses/LICENSE-2.0                           //
//                                                                          //
// Unless required by applicable law or agreed to in writing, software      //
// distributed under the License is distributed on an "AS IS" BASIS,        //
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. //
// See the License for the specific language governing permissions and      //
// limitations under the License.                                           //
// ======================================================================== //

// ospray
#include "math/vec.ih"
#include "math/box.ih"
#include "common/Ray.ih"
#include "common/Model.ih"
#include "geometry/Geometry.ih"
#include "plane/Plane.ih"
// embree
#include "embree2/rtcore.isph"
#include "embree2/rtcore_scene.isph"
#include "embree2/rtcore_geometry_user.isph"

struct Spheres {
  uniform Geometry super; //!< inherited geometry fields

  uniform uint8 *uniform data;
  uniform Material *uniform *materialList;

  float radius;
  int   materialID;
  int   offset_center;
  int   offset_radius;
  int   offset_materialID;
  int   offset_colorID;

  uint8 *color_data;
  int    color_stride;
  int    color_offset;
  
  int32 numSpheres;
  int32 bytesPerSphere;

  uniform Plane *uniform clipplane;
};

typedef uniform float uniform_float;

static void Spheres_postIntersect(uniform Geometry *uniform geometry,
                                  uniform Model *uniform model,
                                  varying DifferentialGeometry &dg,
                                  const varying Ray &ray,
                                  uniform int64 flags)
{
  uniform Spheres *uniform self = (uniform Spheres *uniform)geometry;

  dg.Ng = dg.Ns = ray.Ng;

  if ((flags & DG_COLOR) && self->color_data) {
    uint32 colorID = 0;
    if (self->offset_colorID >= 0) {
      uniform uint8 *varying spherePtr =
          self->data + self->bytesPerSphere*ray.primID;
      colorID = *((uniform uint32 *varying)(spherePtr+self->offset_colorID));
    } else {
      colorID = ray.primID;
    }
	if (ray.primID == -42) {
	dg.color = self->clipplane->color;
	} else {
    uint32 colorAddr = self->color_offset+colorID*self->color_stride;
    dg.color = *((vec4f *)(self->color_data+colorAddr));
	}
  }

  if (flags & DG_MATERIALID) {
    if (self->offset_materialID >= 0) {
      const uniform int32 primsPerPage = (1024*1024*64);
      if (any(ray.primID >= primsPerPage )) {
        const int primPageID  = ray.primID / primsPerPage;
        const int localPrimID = ray.primID % primsPerPage;
        foreach_unique(primPage in primPageID) {
          uniform uint8 *uniform pagePtr   = self->data
                                             + (((int64)primPage)
                                                * primsPerPage
                                                * self->bytesPerSphere);
          uniform uint8 *varying spherePtr = pagePtr
                                             + self->bytesPerSphere*localPrimID;
          dg.materialID =
              *((uniform uint32 *varying)(spherePtr+self->offset_materialID));
          if (self->materialList) {
            dg.material = self->materialList[dg.materialID];
          }
        }
      } else {
        uniform uint8 *varying spherePtr = self->data
                                           + self->bytesPerSphere*ray.primID;
        dg.materialID =
            *((uniform uint32 *varying)(spherePtr+self->offset_materialID));
        if (self->materialList) {
          dg.material = self->materialList[dg.materialID];
        }
      }
    } else {
      dg.materialID = self->materialID;
      if (self->materialList) {
        dg.material = self->materialList[dg.materialID];
      }
    }
  }
}

unmasked void Spheres_bounds(uniform Spheres *uniform self,
    uniform size_t primID,
    uniform box3fa &bbox)
{
  uniform uint8 *uniform spherePtr = self->data
      + self->bytesPerSphere*((uniform int64)primID);
  uniform bool offr = self->offset_radius >= 0;
  uniform float radius =
      offr ? *((uniform float *uniform)(spherePtr+self->offset_radius)) :
             self->radius;
  uniform vec3f center =
      *((uniform vec3f*uniform)(spherePtr+self->offset_center));
  bbox = make_box3fa(center-make_vec3f(radius),center+make_vec3f(radius));
}

void Spheres_intersect(uniform Spheres *uniform self,
                       varying Ray &ray,
                       uniform size_t primID)
{
  uniform uint8 *uniform spherePtr =
      self->data + self->bytesPerSphere*((uniform int64)primID);
  uniform float radius = self->radius;
  if (self->offset_radius >= 0) {
    radius = *((uniform float *uniform)(spherePtr+self->offset_radius));
  }
  uniform vec3f center =
      *((uniform vec3f*uniform)(spherePtr+self->offset_center));
  const vec3f A = center - ray.org;
  
  const float a = dot(ray.dir,ray.dir);
  const float b = 2.f*dot(ray.dir,A);
  const float c = dot(A,A)-radius*radius;
  
  const float radical = b*b-4.f*a*c;
  if (radical < 0.f) return;

  const float srad = sqrt(radical);

  const float t_in = (b - srad) *rcpf(2.f*a);
  const float t_out= (b + srad) *rcpf(2.f*a);


  bool hit = false;
  float t = 0.f;
  if (t_in > ray.t0 && t_in < ray.t) {
    hit = true;
    t = t_in;
  } else if (t_out > ray.t0 && t_out < ray.t) {
    hit = true;
    t = t_out;
  }
  vec3f Ng = ray.org + t*ray.dir - center;



  
  // clip data
  if (self->clipplane != NULL && hit) {
    vec3f sph_intersect = t * ray.dir + ray.org;
    vec3f sph_intersect_in = t_in * ray.dir + ray.org;
    vec3f sph_intersect_out = t_out * ray.dir + ray.org;
    
	const vec3f normal_hat = normalize(self->clipplane->normal);
	
	const float t_pln = (self->clipplane->dist - dot(ray.org,normal_hat)) / dot(ray.dir,normal_hat);
	vec3f pln_intersect = ray.org + t_pln * ray.dir;
	const float pln_in_n_dir = dot(pln_intersect,normal_hat);
	const float sph_in_n_dir = dot(sph_intersect,normal_hat);

	//vec3f cpb = normal_hat * self->clipplane->dist;
	//const float dist_plane = dot (cpb, normal_hat);
	//const float dist_sph_pln = dot(normal_hat, center - cpb);
	
	if (pln_in_n_dir > dot(sph_intersect_in,normal_hat) && pln_in_n_dir < dot(sph_intersect_out,normal_hat)) {
	  t = t_pln;
	  Ng = normal_hat;
	  ray.primID = -42; // <- Dirty Hack :)
	} else if (pln_in_n_dir > sph_in_n_dir) {
	  return;
	} 
  }


  if (hit) {
    ray.t = t;
	if (ray.primID != -42) ray.primID = primID;
    ray.geomID = self->super.geomID;
    ray.instID = -1;
    // cannot easily be moved to postIntersect
    // we need hit in object space, in postIntersect it is in world-space
	ray.Ng = Ng;
  }
}


export void *uniform Spheres_create(void *uniform cppEquivalent)
{
  uniform Spheres *uniform self = uniform new uniform Spheres;
  Geometry_Constructor(&self->super,cppEquivalent,
                       Spheres_postIntersect,
                       NULL,0,NULL);
  return self;
}

export void SpheresGeometry_set(void  *uniform _self,
                                void  *uniform _model,
                                void  *uniform data,
                                void  *uniform materialList,
                                uint8 *uniform color_data,
                                int    uniform color_offset,
                                int    uniform color_stride,
                                int    uniform numSpheres,
                                int    uniform bytesPerSphere,
                                float  uniform radius,
                                int    uniform materialID,
                                int    uniform offset_center,
                                int    uniform offset_radius,
                                int    uniform offset_materialID,
                                int    uniform offset_colorID,
								void  *uniform _clipplane)
{
  uniform Spheres *uniform self = (uniform Spheres *uniform)_self;
  uniform Model *uniform model = (uniform Model *uniform)_model;
  uniform Plane *uniform clipplane = (uniform Plane *uniform)_clipplane;

  uniform uint32 geomID = rtcNewUserGeometry(model->embreeSceneHandle,numSpheres);
  
  self->super.model = model;
  self->super.geomID = geomID;
  self->materialList = (Material **)materialList;
  self->color_data = color_data;
  self->color_stride = color_stride;
  self->color_offset = color_offset;
  self->numSpheres = numSpheres;
  self->radius = radius;
  self->data = (uniform uint8 *uniform)data;
  self->materialID = materialID;
  self->bytesPerSphere = bytesPerSphere;

  self->offset_center     = offset_center;
  self->offset_radius     = offset_radius;
  self->offset_materialID = offset_materialID;
  self->offset_colorID    = offset_colorID;

  self->clipplane         = clipplane;

  rtcSetUserData(model->embreeSceneHandle,geomID,self);
  rtcSetBoundsFunction(model->embreeSceneHandle,geomID,
                       (uniform RTCBoundsFunc)&Spheres_bounds);
  rtcSetIntersectFunction(model->embreeSceneHandle,geomID,
                          (uniform RTCIntersectFuncVarying)&Spheres_intersect);
  rtcSetOccludedFunction(model->embreeSceneHandle,geomID,
                          (uniform RTCOccludedFuncVarying)&Spheres_intersect);
}
