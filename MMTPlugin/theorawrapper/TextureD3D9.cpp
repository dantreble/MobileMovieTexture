//
//  TextureD3D9.cpp
//  theorawrapper
//
//  Created by Daniel Treble on 27/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#include "TextureD3D9.h"

#ifdef SUPPORT_D3D9

#include "GfxDevice.h"

#include "Unity\IUnityGraphicsD3D9.h"

IDirect3DDevice9 *g_DeviceD3D9 = NULL;

void DoEventGraphicsDeviceD3D9(UnityGfxDeviceEventType eventType)
{
    // Create or release a small dynamic vertex buffer depending on the event type.
    switch (eventType)
    {
        case kUnityGfxDeviceEventInitialize:
        {
            IUnityGraphicsD3D9* d3d9 = s_UnityInterfaces->Get<IUnityGraphicsD3D9>();
            g_DeviceD3D9 = d3d9->GetDevice();
        }
            break;
        case kUnityGfxDeviceEventAfterReset:
            // After device is initialized or was just reset, create the VB.
            //if (!g_D3D9DynamicVB)
            //    g_D3D9Device->CreateVertexBuffer (1024, D3DUSAGE_WRITEONLY | D3DUSAGE_DYNAMIC, 0, D3DPOOL_DEFAULT, &g_D3D9DynamicVB, NULL);
            break;
        case kUnityGfxDeviceEventBeforeReset:
        case kUnityGfxDeviceEventShutdown:
            // Before device is reset or being shut down, release the VB.
            //SAFE_RELEASE(g_D3D9DynamicVB);
            break;
    }
}

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
