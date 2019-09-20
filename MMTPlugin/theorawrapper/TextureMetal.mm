//
//  TextureMetal.m
//  theorawrapper
//
//  Created by Daniel Treble on 4/01/2015.
//  Copyright (c) 2015 Defiant Development PTY Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TextureMetal.h"

#if defined(SUPPORT_METAL)

#import <Metal/Metal.h>


@interface TextureMetal : NSObject

+ (id<MTLTexture>)aClassMethod:(int)width height:(int)height;
+ (void)setMetalDevice:(id<MTLDevice>) device;

@end

@implementation TextureMetal

static id<MTLDevice> s_metalDevice;

extern "C" NSBundle*			UnityGetMetalBundle();

static inline Class MTLTextureDescriptorClass()
{
    static Class _MTLTextureDescriptorClass = nil;
    if(_MTLTextureDescriptorClass == nil)
        _MTLTextureDescriptorClass = [UnityGetMetalBundle() classNamed:@"MTLTextureDescriptor"];
    return _MTLTextureDescriptorClass;
}

+ (id<MTLTexture>)aClassMethod:(int)width height:(int)height
{
    MTLTextureDescriptor* txDesc = [MTLTextureDescriptorClass() new];
    txDesc.textureType = MTLTextureType2D;
    txDesc.width = width;
    txDesc.height = height;
    txDesc.depth = 1;
    txDesc.pixelFormat = MTLPixelFormatA8Unorm;
    txDesc.arrayLength = 1;
    txDesc.mipmapLevelCount = 1;

    return [s_metalDevice newTextureWithDescriptor:txDesc];
}

+ (void)setMetalDevice:(id<MTLDevice>) device
{
    s_metalDevice = device;
}

@end

extern "C"
{
    void SetMetalDevice(void * mtlDevice)
    {
        [TextureMetal setMetalDevice:(id<MTLDevice>)mtlDevice];
    }
    
    void *AllocateTextureMTL(int stride, int height)
    {
        return (void*)[TextureMetal aClassMethod:stride height:height];
        //return 0;
    }
    
    void ReleaseTextureMTL(void *mtlTexture)
    {
        [(id<MTLTexture>)mtlTexture release ];
        mtlTexture = NULL;
    }
    
    bool UploadPlaneMTL( void *mtlTexture, int stride, int height, unsigned char *planeData)
    {
        if (mtlTexture == NULL)
        {
            return false;
        }
        
        [(id<MTLTexture>)mtlTexture replaceRegion: MTLRegionMake2D ( 0, 0, stride, height ) mipmapLevel:0 withBytes:planeData bytesPerRow:stride ];
        
        return true;
        
    }
    
    void FillByteMTL( void *mtlTexture, int x, int y , int val)
    {
        unsigned char *buffer = (unsigned char *)malloc(x*y);
        
        memset(buffer,val,x*y);
        
        UploadPlaneMTL( mtlTexture, x, y, buffer );
        
        free(buffer);
    }

    
}

#endif
