//
//  TextureD3D9.cpp
//  theorawrapper
//
//  Created by Daniel Treble on 27/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#include "TextureD3D9.h"

#ifdef SUPPORT_D3D9

IDirect3DDevice9 *g_DeviceD3D9 = NULL;

void AllocateTextureD3D(int stride, int height, IDirect3DTexture9** d3dtex)
{
    g_DeviceD3D9->CreateTexture(stride,height,1,D3DUSAGE_DYNAMIC,D3DFMT_A8,D3DPOOL_DEFAULT,d3dtex,NULL);
}

void ReleaseTextureD3D( IDirect3DTexture9 **handle )
{
    if (handle && *handle)
    {
        (*handle)->Release();
        handle = NULL;
    }
}

bool UploadPlaneD3D( IDirect3DTexture9* d3dtex, int stride, int height, unsigned char *planeData)
{
    if (d3dtex == NULL)
    {
        return false;
    }
    
    g_DeviceD3D9->SetRenderState (D3DRS_CULLMODE, D3DCULL_NONE);
    g_DeviceD3D9->SetRenderState (D3DRS_LIGHTING, FALSE);
    g_DeviceD3D9->SetRenderState (D3DRS_ALPHABLENDENABLE, FALSE);
    g_DeviceD3D9->SetRenderState (D3DRS_ALPHATESTENABLE, FALSE);
    g_DeviceD3D9->SetRenderState (D3DRS_ZFUNC, D3DCMP_LESSEQUAL);
    g_DeviceD3D9->SetRenderState (D3DRS_ZWRITEENABLE, FALSE);
    
    
    D3DSURFACE_DESC desc;
    d3dtex->GetLevelDesc (0, &desc);
    D3DLOCKED_RECT lr;
    d3dtex->LockRect (0, &lr, NULL, 0);
    
    unsigned char *buffer = (unsigned char*)lr.pBits;
    
    for (int y = 0; y < height; ++y)
    {
        memcpy(buffer,planeData,stride);
        
        planeData+=stride;
        buffer+=lr.Pitch;
    }
    
    d3dtex->UnlockRect (0);

	return true;
}

void FillByteD3D( IDirect3DTexture9* d3dtex , int val)
{
    D3DSURFACE_DESC desc;
    d3dtex->GetLevelDesc (0, &desc);
    //d3d9device->ColorFill(desc,NULL,0);
    
    D3DLOCKED_RECT lr;
    d3dtex->LockRect (0, &lr, NULL, 0);
    
    //unsigned char*buffer = (unsigned char*)lr.pBits;
    
    memset(lr.pBits,val, desc.Height * lr.Pitch);
    
    d3dtex->UnlockRect (0);
}

#endif
