//
//  GfxDevice.h
//  theorawrapper
//
//  Created by Daniel Treble on 27/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#ifndef theorawrapper_GfxDevice_h
#define theorawrapper_GfxDevice_h

#include "Unity/IUnityGraphics.h"

typedef struct IUnityInterfaces IUnityInterfaces;


extern IUnityInterfaces* s_UnityInterfaces;
extern IUnityGraphics* s_Graphics;
extern UnityGfxRenderer g_DeviceType;

#endif
