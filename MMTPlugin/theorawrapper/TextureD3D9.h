//
//  TextureD3D9.h
//  theorawrapper
//
//  Created by Daniel Treble on 27/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#ifndef __theorawrapper__TextureD3D9__
#define __theorawrapper__TextureD3D9__

#ifdef SUPPORT_D3D9
#include <d3d9.h>

#include "Unity/IUnityGraphics.h"

extern IDirect3DDevice9 *g_DeviceD3D9;

void DoEventGraphicsDeviceD3D9(UnityGfxDeviceEventType eventType);
void AllocateTextureD3D(int stride, int height, IDirect3DTexture9** d3dtex);
void ReleaseTextureD3D( IDirect3DTexture9 **handle );
bool UploadPlaneD3D( IDirect3DTexture9* d3dtex, int stride, int height, unsigned char *planeData);
void FillByteD3D( IDirect3DTexture9* d3dtex , int val);

#endif

#endif /* defined(__theorawrapper__TextureD3D9__) */
