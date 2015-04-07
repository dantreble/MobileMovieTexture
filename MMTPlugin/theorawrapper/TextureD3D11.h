//
//  TextureD3D11.h
//  theorawrapper
//
//  Created by Daniel Treble on 20/01/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#ifndef __theorawrapper__TextureD3D11__
#define __theorawrapper__TextureD3D11__

#ifdef SUPPORT_D3D11
#include <d3d11.h>


extern ID3D11Device *g_DeviceD3D11;

void AllocateTextureD3D11(int stride, int height, ID3D11Texture2D** d3dtex);
void ReleaseTextureD3D11( ID3D11Texture2D **handle );
bool UploadPlaneD3D11( ID3D11Texture2D* d3dtex, int stride, int height, unsigned char *planeData);
void FillByteD3D11( ID3D11Texture2D* d3dtex , int val);

#endif

#endif /* defined(__theorawrapper__TextureD3D11__) */
