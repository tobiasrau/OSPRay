// ======================================================================== //
// Copyright 2009-2015 Intel Corporation                                    //
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

#pragma once

// ospray
#include "ospray/fb/Tile.h"
#include "ospray/common/Managed.h"

namespace ospray {

  struct FrameBuffer;

  /*! \brief base abstraction for a a "Pixel Op" to be performed for
      every pixel that gets written into a frame buffer.

      A PixelOp is basically a "hook" that allows to inject arbitrary
      code, such as postprocessing, filtering, blending, tone mapping,
      sending tiles to a display wall, etc. PixelOps are intentionally
      'stateless' in that it they should be pure functors that can be
      applied to different frame buffers, potentially at the same
      time. 

      To allow a pixelop to maintain some sort of state for a frame,
      the 'beginframe', a pixelop is supposed to create and return a
      state every time it gets "attached" to a frame buffer, and this
      state then gets passed every time a frame buffer gets started, 
  */
  struct PixelOp : public ManagedObject {
    struct State {
      FrameBuffer *fb;
      /*! gets called every time the frame buffer got 'commit'ted */
      virtual void  commitNotify() {};
      /*! gets called once at the beginning of the frame */
      virtual void beginFrame() {};
      /*! gets called once at the end of the frame */
      virtual void endFrame() {};
      
      /*! called whenever a new tile comes in from a renderer, but
          _before_ the tile gets written/accumulated into the frame
          buffer. this way we can, for example, fill in missing
          samples; however, the tile will _not_ yet contain the
          previous frame's contributions from the accum buffer
          etcpp. In distriubuted mode, it is undefined if this op gets
          executed on the node that _produces_ the tile, or on the
          node that _owns_ the tile (and its accum buffer data)  */
      virtual void preWrite(Tile &tile) {};

      /*! called right after the tile got accumulated; i.e., the
          tile's RGBA values already contain the accu-buffer blended
          values (assuming an accubuffer exists), and this function
          defines how these pixels are being processed before written
          into the color buffer */
      virtual void postAccum() {};
    };
    virtual State *createInstance(FrameBuffer *fb) { return NULL; };
  };

}
