//
//  TextureD3D11.cpp
//  theorawrapper
//
//  Created by Daniel Treble on 20/01/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#include "TextureD3D11.h"

#ifdef SUPPORT_D3D11

ID3D11Device *g_DeviceD3D11 = NULL;

void AllocateTextureD3D11(int stride, int height, ID3D11Texture2D **d3dtex)
{
	D3D11_TEXTURE2D_DESC textureDescriptor;

	textureDescriptor.Width = stride;
	textureDescriptor.Height = height;
	textureDescriptor.MipLevels = 1;
	textureDescriptor.ArraySize = 1;
	textureDescriptor.Format = DXGI_FORMAT_A8_UNORM;
	textureDescriptor.SampleDesc.Count = 1;
	textureDescriptor.SampleDesc.Quality = 0;
	textureDescriptor.Usage = D3D11_USAGE_DYNAMIC;
	textureDescriptor.BindFlags = D3D11_BIND_SHADER_RESOURCE;
	textureDescriptor.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
	textureDescriptor.MiscFlags = 0;

	g_DeviceD3D11->CreateTexture2D(&textureDescriptor,NULL, d3dtex);
}

void ReleaseTextureD3D11( ID3D11Texture2D **handle )
{
    if (handle && *handle)
    {
        (*handle)->Release();
        handle = NULL;
    }
}

bool UploadPlaneD3D11( ID3D11Texture2D* d3dtex, int stride, int height, unsigned char *planeData)
{
	
    if (d3dtex == NULL)
    {
        return false;
    }

	ID3D11DeviceContext* ctx = NULL;
	g_DeviceD3D11->GetImmediateContext (&ctx);

	D3D11_MAPPED_SUBRESOURCE mappedResource;
	ctx->Map(d3dtex,0, D3D11_MAP_WRITE_DISCARD,0, &mappedResource);

	BYTE* buffer = reinterpret_cast<BYTE*>(mappedResource.pData);

	for (int y = 0; y < height; ++y)
	{
		memcpy(buffer,planeData,stride);

		planeData+=stride;
		buffer+=mappedResource.RowPitch;
	}

	ctx->Unmap(d3dtex,0);

	return true;
}

void FillByteD3D11( ID3D11Texture2D* d3dtex , int val)
{
	if (d3dtex == NULL)
	{
		return;
	}

	ID3D11DeviceContext* ctx = NULL;
	g_DeviceD3D11->GetImmediateContext (&ctx);

	D3D11_MAPPED_SUBRESOURCE mappedResource;
	ctx->Map(d3dtex,0, D3D11_MAP_WRITE_DISCARD,0, &mappedResource);

	BYTE* buffer = reinterpret_cast<BYTE*>(mappedResource.pData);

	D3D11_TEXTURE2D_DESC textureDescriptor;

	d3dtex->GetDesc(&textureDescriptor);

    memset(buffer ,val, textureDescriptor.Height * mappedResource.RowPitch);
    
    ctx->Unmap(d3dtex,0);
}

#endif
