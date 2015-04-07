//
//  TextureMetal.h
//  theorawrapper
//
//  Created by Daniel Treble on 5/01/2015.
//  Copyright (c) 2015 Defiant Development PTY Ltd. All rights reserved.
//

#ifndef theorawrapper_TextureMetal_h
#define theorawrapper_TextureMetal_h

extern "C"
{
    void SetMetalDevice(void * mtlDevice);
    void *AllocateTextureMTL(int stride, int height);
    void ReleaseTextureMTL(void *mtlTexture);
    bool UploadPlaneMTL( void *mtlTexture, int stride, int height, unsigned char *planeData);
    void FillByteMTL( void *mtlTexture, int x, int y , int val);
}

#endif
