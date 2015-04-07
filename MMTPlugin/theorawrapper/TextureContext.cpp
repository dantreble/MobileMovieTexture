//
//  TextureContext.cpp
//  theorawrapper
//
//  Created by Daniel Treble on 27/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#include "GfxDevice.h"

#include "TextureOpenGL.h"

#include "TextureContext.h"

#include "../theora/lib/decint.h"

TextureContext::TextureContext(int yStride, int yHeight, int uvStride, int uvHeight)
: m_yStride(yStride)
, m_yHeight(yHeight)
, m_uvStride(uvStride)
, m_uvHeight(uvHeight)
{
    m_planes[0].Allocate(m_yStride,m_yHeight);
    m_planes[0].Fill(m_yStride,m_yHeight,0);
    
    m_planes[1].Allocate(m_uvStride,m_uvHeight);
    m_planes[1].Fill(m_uvStride,m_uvHeight,127);
    
    m_planes[2].Allocate(m_uvStride,m_uvHeight);
    m_planes[2].Fill(m_uvStride,m_uvHeight,127);
}

TextureContext::~TextureContext()
{
    
    for(int i = 0; i < 3 ; ++i)
    {
        m_planes[i].Release();
    }
}

bool TextureContext::UploadTextures(th_dec_ctx *thDecCtx)
{
    bool sucessfullyUploaded = true;
    
    th_ycbcr_buffer yCbCrBuffer;
    
    th_decode_ycbcr_out(thDecCtx,yCbCrBuffer);
    
    sucessfullyUploaded &= m_planes[0].UploadPlane(m_yStride,m_yHeight, yCbCrBuffer, 0);
    
    sucessfullyUploaded &= m_planes[1].UploadPlane(m_uvStride,m_uvHeight, yCbCrBuffer, 1);
    sucessfullyUploaded &= m_planes[2].UploadPlane(m_uvStride,m_uvHeight, yCbCrBuffer, 2);
    
    return sucessfullyUploaded;
    
}