//
//  TextureHandle.h
//  theorawrapper
//
//  Created by Daniel Treble on 28/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#ifndef __theorawrapper__TextureHandle__
#define __theorawrapper__TextureHandle__

#ifdef SUPPORT_D3D9
#include <d3d9.h>
#endif

#ifdef SUPPORT_D3D11
#include <d3d11.h>
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

#if defined(WIN32)
#include <windows.h>
#include <GL/gl.h>
#endif
#endif

#if SUPPORT_METAL
typedef struct objc_object*		MTLTextureRef;
#endif

#include "GfxDevice.h"

#include "theora/codec.h"

struct TextureHandle
{
    union Handle
    {
        long raw;
        
#ifdef SUPPORT_D3D9
        IDirect3DTexture9 *D3D9;
#endif

#ifdef SUPPORT_D3D11
		ID3D11Texture2D *D3D11;
#endif
  
#ifdef SUPPORT_OPENGL
        GLuint OPENGL;
#endif
        
#if SUPPORT_METAL
        MTLTextureRef MTL;
#endif
        
    } m_handle;
    
    TextureHandle();
    
    void Allocate(int stride, int height);
    void Fill(int stride, int height, unsigned char byte);
    void Release();
    bool UploadPlane( int stride, int height, th_ycbcr_buffer yCrCbBuffer, int planeIndex );
    void *GetNativeHandle();
    
};

#endif /* defined(__theorawrapper__TextureHandle__) */
