// ======================================================================== //
// Copyright 2009-2017 Intel Corporation                                    //
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

#include "Camera.ih"


export void Camera_set(void *uniform _self,
                       const uniform float nearClip,
                       const uniform vec2f &imageStart,
                       const uniform vec2f &imageEnd)
{
  uniform Camera *uniform self = (uniform Camera *uniform)_self;
  self->nearClip = nearClip;
  self->subImage.lower = imageStart;
  self->subImage.upper = imageEnd;
}
