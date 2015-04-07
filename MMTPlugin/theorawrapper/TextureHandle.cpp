//
//  TextureHandle.cpp
//  theorawrapper
//
//  Created by Daniel Treble on 28/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#include <stdio.h>

#include "TextureHandle.h"

#ifdef SUPPORT_OPENGL
#include "TextureOpenGL.h"
#endif

#ifdef SUPPORT_D3D9
#include "TextureD3D9.h"
#endif

#ifdef SUPPORT_D3D11
#include "TextureD3D11.h"
#endif

#ifdef SUPPORT_METAL
#include "TextureMetal.h"
#endif

TextureHandle::TextureHandle()
{
    m_handle.raw = 0;
    
    switch( g_DeviceType )
    {
#ifdef SUPPORT_OPENGL
        case kGfxRendererOpenGL:			// OpenGL
        case kGfxRendererOpenGLES20Mobile:	// OpenGL ES 2.0
        case kGfxRendererOpenGLES30:		// OpenGL ES 3.0
            m_handle.OPENGL = GL_INVALID_VALUE;
            break;
#endif
            
#ifdef SUPPORT_D3D9
        case kGfxRendererD3D9:				// Direct3D 9
            m_handle.D3D9 = NULL;
            break;
#endif

#ifdef SUPPORT_D3D9
		case kGfxRendererD3D11:				// Direct3D 11
			m_handle.D3D11 = NULL;
			break;
#endif

            
#ifdef SUPPORT_METAL
        case kGfxRendererMetal:
            m_handle.MTL = NULL;
            break;
#endif
            
        default:
            break;
    }
}

void TextureHandle::Allocate(int stride, int height)
{
    switch( g_DeviceType )
    {
#ifdef SUPPORT_OPENGL
        case kGfxRendererOpenGL:			// OpenGL
        case kGfxRendererOpenGLES20Mobile:	// OpenGL ES 2.0
        case kGfxRendererOpenGLES30:		// OpenGL ES 3.0
            m_handle.OPENGL = AllocateTextureOpenGL( stride, height);
            break;
#endif
            
#ifdef SUPPORT_D3D9
        case kGfxRendererD3D9:				// Direct3D 9
            AllocateTextureD3D(stride,height, &m_handle.D3D9);
            break;
#endif

#ifdef SUPPORT_D3D11
		case kGfxRendererD3D11:				// Direct3D 11
			AllocateTextureD3D11(stride,height, &m_handle.D3D11 );
			break;
#endif
            
#ifdef SUPPORT_METAL
        case kGfxRendererMetal:
            m_handle.MTL = (objc_object*)AllocateTextureMTL(stride, height);
            
            printf ("Allocated texture %08X", m_handle.MTL);
            
            break;
#endif
            
        default:
            break;
    }
}

void TextureHandle::Fill(int stride, int height, unsigned char byte)
{
    switch( g_DeviceType )
    {
#ifdef SUPPORT_OPENGL
        case kGfxRendererOpenGL:			// OpenGL
        case kGfxRendererOpenGLES20Mobile:	// OpenGL ES 2.0
        case kGfxRendererOpenGLES30:		// OpenGL ES 3.0
            FillByteOpenGL(m_handle.OPENGL, stride, height, byte);
            break;
#endif
            
#ifdef SUPPORT_D3D9
        case kGfxRendererD3D9:				// Direct3D 9
            FillByteD3D( m_handle.D3D9 , byte);
            break;
#endif

#ifdef SUPPORT_D3D11
		case kGfxRendererD3D11:				// Direct3D 11
			FillByteD3D11(m_handle.D3D11,byte );
			break;
#endif
            
#ifdef SUPPORT_METAL
        case kGfxRendererMetal:
            FillByteMTL(m_handle.MTL, stride, height, byte);
            break;
#endif
            
        default:
            break;
    }

}

void TextureHandle::Release()
{
    switch( g_DeviceType )
    {
#ifdef SUPPORT_OPENGL
        case kGfxRendererOpenGL:			// OpenGL
        case kGfxRendererOpenGLES20Mobile:	// OpenGL ES 2.0
        case kGfxRendererOpenGLES30:		// OpenGL ES 3.0
            m_handle.OPENGL = ReleaseTextureOpenGL( m_handle.OPENGL );
            break;
#endif
            
#ifdef SUPPORT_D3D9
        case kGfxRendererD3D9:				// Direct3D 9
            ReleaseTextureD3D(&m_handle.D3D9);
            break;
#endif

#ifdef SUPPORT_D3D11
		case kGfxRendererD3D11:				// Direct3D 11
			ReleaseTextureD3D11(&m_handle.D3D11 );
			break;
#endif
            
#ifdef SUPPORT_METAL
        case kGfxRendererMetal:
            ReleaseTextureMTL(m_handle.MTL);
            break;
#endif
            
        default:
            break;
    }
}

bool TextureHandle::UploadPlane( int stride, int height, th_ycbcr_buffer yCrCbBuffer, int planeIndex )
{
    const th_img_plane &plane = yCrCbBuffer[planeIndex];
    unsigned char *planeData = plane.data;
    
    switch( g_DeviceType )
    {
#ifdef SUPPORT_OPENGL
        case kGfxRendererOpenGL:			// OpenGL
        case kGfxRendererOpenGLES20Mobile:	// OpenGL ES 2.0
        case kGfxRendererOpenGLES30:		// OpenGL ES 3.0
            return UploadPlaneOpenGL( m_handle.OPENGL, stride, height, planeData );
            break;
#endif
            
#ifdef SUPPORT_D3D9
        case kGfxRendererD3D9:				// Direct3D 9
            return UploadPlaneD3D( m_handle.D3D9, stride, height, planeData );
            break;
#endif

#ifdef SUPPORT_D3D11
		case kGfxRendererD3D11:				// Direct3D 11
			 return UploadPlaneD3D11( m_handle.D3D11, stride, height, planeData );
			break;
#endif
            
#ifdef SUPPORT_METAL
        case kGfxRendererMetal:
            return UploadPlaneMTL((void*)m_handle.MTL, stride, height, planeData );
            break;
#endif
            
        default:
            return false;
            break;
    }
}

void *TextureHandle::GetNativeHandle()
{
    switch(g_DeviceType)
    {
#ifdef SUPPORT_D3D9
        case kGfxRendererD3D9:
            return (void *)m_handle.D3D9;
            break;
#endif

#ifdef SUPPORT_D3D11
		case kGfxRendererD3D11:				// Direct3D 11
			{
				ID3D11ShaderResourceView *resourceView;

				g_DeviceD3D11->CreateShaderResourceView(m_handle.D3D11,
					NULL,
					&resourceView
					);
				return (void *)resourceView;
			}
			break;
#endif
            
#ifdef SUPPORT_OPENGL
        case kGfxRendererOpenGL:			// OpenGL
        case kGfxRendererOpenGLES20Mobile:	// OpenGL ES 2.0
        case kGfxRendererOpenGLES30:		// OpenGL ES 3.0
            return (void*)m_handle.OPENGL;
            break;
#endif
            
#ifdef SUPPORT_METAL
        case kGfxRendererMetal:
            return (void*)m_handle.MTL;
            break;
#endif
            
        default:
            return NULL;
    }
}
