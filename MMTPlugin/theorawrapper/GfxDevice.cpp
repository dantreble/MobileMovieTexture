//
//  GfxDevice.cpp
//  theorawrapper
//
//  Created by Daniel Treble on 27/12/2014.
//  Copyright (c) 2014 Defiant Development PTY Ltd. All rights reserved.
//

#include "GfxDevice.h"

#include "Unity/IUnityInterface.h"

#include <cstddef>

IUnityInterfaces* s_UnityInterfaces = NULL;
IUnityGraphics* s_Graphics = NULL;
UnityGfxRenderer g_DeviceType = kUnityGfxRendererNull;