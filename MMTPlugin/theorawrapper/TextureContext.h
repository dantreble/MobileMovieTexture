//
//  TextureContext.h
//  theorawrapper
//
//  Created by Daniel Treble on 27/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#ifndef theorawrapper_TextureContext_h
#define theorawrapper_TextureContext_h

#ifdef SUPPORT_D3D9
#include <d3d9.h>
#endif

#if SUPPORT_OPENGL
    #if defined(ANDROID)
    #include <GLES/gl.h>
    #endif

    #if  defined (iOS)
    #include <OpenGLES/ES1/gl.h>
    #include <OpenGLES/ES2/glext.h>
    #endif

    #if  defined (OSX)
    #include <OpenGL/gl.h>
    #endif
#endif

#include "GfxDevice.h"

#include "TextureHandle.h"

struct th_dec_ctx;

struct TextureContext
{
    int m_yStride;
    int m_yHeight;
    int m_uvStride;
    int m_uvHeight;
    
    TextureHandle m_planes[3];
        
    TextureContext(int yStride, int yHeight, int uvStride, int uvHeight);
    
    ~TextureContext();
    
    bool UploadTextures(th_dec_ctx *thDecCtx);
    
};

#endif
