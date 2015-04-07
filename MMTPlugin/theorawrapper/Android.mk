# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.crg/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

WRAPPER_SOURCES := \
	theorawrapper.cpp \
	TextureContext.cpp \
	GfxDevice.cpp \
	TextureOpenGL.cpp \
	TextureHandle.cpp 
	

LOCAL_MODULE    := libtheorawrapper 
LOCAL_SRC_FILES := $(WRAPPER_SOURCES)
LOCAL_CFLAGS :=  -DTHEORAWRAPPER_EXPORTS -DSUPPORT_OPENGL -fvisibility=hidden
LOCAL_STATIC_LIBRARIES := libtheora liboggz libogg 
LOCAL_LDLIBS := -llog  -lGLESv2
LOCAL_ARM_MODE := arm
LOCAL_C_INCLUDES := $(LOCAL_PATH)/../ogg/include $(LOCAL_PATH)/../theora/include $(LOCAL_PATH)/../oggz/include

ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
    LOCAL_ARM_NEON  := true
    LOCAL_CFLAGS    += -DOC_ARM_ASM -DOC_ARM_ASM_NEON 
endif

ifeq ($(TARGET_ARCH_ABI),x86)
	LOCAL_CFLAGS += -DOC_X86_ASM 
    LOCAL_CFLAGS    += -mssse3
    LOCAL_CPPFLAGS  += -mssse3
    LOCAL_CXXFLAGS  += -mssse3
endif


include $(BUILD_SHARED_LIBRARY)