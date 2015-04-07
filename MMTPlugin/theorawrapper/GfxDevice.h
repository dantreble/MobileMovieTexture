//
//  GfxDevice.h
//  theorawrapper
//
//  Created by Daniel Treble on 27/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#ifndef theorawrapper_GfxDevice_h
#define theorawrapper_GfxDevice_h

// Graphics device identifiers in Unity
enum GfxDeviceRenderer
{
    kGfxRendererOpenGL = 0,			// OpenGL
    kGfxRendererD3D9,				// Direct3D 9
    kGfxRendererD3D11,				// Direct3D 11
    kGfxRendererGCM,				// Sony PlayStation 3 GCM
    kGfxRendererNull,				// "null" device (used in batch mode)
    kGfxRendererHollywood,			// Nintendo Wii
    kGfxRendererXenon,				// Xbox 360
    kGfxRendererOpenGLES_Obsolete,
    kGfxRendererOpenGLES20Mobile,	// OpenGL ES 2.0
    kGfxRendererMolehill_Obsolete,
    kGfxRendererOpenGLES20Desktop_Obsolete,
    kGfxRendererOpenGLES30,			// OpenGL ES 3.0
    kGfxRendererVita,
    kGfxRendererPS4,
    kGfxRendererXB1,
    kGfxRendererPSM,
    kGfxRendererMetal,
    kGfxRendererCount
};


// Event types for UnitySetGraphicsDevice
enum GfxDeviceEventType {
    kGfxDeviceEventInitialize = 0,
    kGfxDeviceEventShutdown,
    kGfxDeviceEventBeforeReset,
    kGfxDeviceEventAfterReset,
};

extern GfxDeviceRenderer g_DeviceType;

#endif
