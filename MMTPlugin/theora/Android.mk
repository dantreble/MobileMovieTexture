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


#color conversion lib
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

DECODER_SOURCES := \
	lib/apiwrapper.c \
	lib/bitpack.c \
	lib/decinfo.c \
	lib/decapiwrapper.c \
	lib/decode.c \
	lib/dequant.c \
	lib/fragment.c \
	lib/huffdec.c \
	lib/idct.c \
	lib/info.c \
	lib/internal.c \
	lib/quant.c \
	lib/state.c \
	lib/arm/armcpu.c \
	lib/arm/armstate.c 
	
DECODER_SOURCES_ARM := \
	lib/arm/armbits-gnu.S.neon \
	lib/arm/armfrag-gnu.S.neon \
	lib/arm/armidct-gnu.S.neon \
	lib/arm/armloop-gnu.S.neon 	


DECODER_SOURCES_X86 := \
	lib/x86/mmxfrag.c \
	lib/x86/mmxidct.c \
	lib/x86/mmxstate.c \
	lib/x86/sse2idct.c \
	lib/x86/x86cpu.c \
	lib/x86/x86enc.c \
	lib/x86/x86enquant.c \
	lib/x86/x86state.c

	
LOCAL_MODULE    := libtheora
LOCAL_SRC_FILES := $(DECODER_SOURCES)
LOCAL_CFLAGS := -fvisibility=hidden
LOCAL_STATIC_LIBRARIES := cpufeatures
LOCAL_ARM_MODE := arm
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include $(LOCAL_PATH)/../ogg/include

ifeq ($(TARGET_ARCH_ABI),x86)
	LOCAL_SRC_FILES += $(DECODER_SOURCES_X86)
	LOCAL_CFLAGS += -DOC_X86_ASM 
    LOCAL_CFLAGS    += -mssse3
    LOCAL_CPPFLAGS  += -mssse3
    LOCAL_CXXFLAGS  += -mssse3
endif
 
ifeq ($(TARGET_ARCH_ABI),arm64-v8a)
#    LOCAL_CFLAGS    += -DHAVE_NEON64_or_Some_Other_flag =1
#    LOCAL_CPPFLAGS  += -DHAVE_NEON64_or_Some_Other_flag=1
#    LOCAL_CXXFLAGS  += -DHAVE_NEON64_or_Some_Other_flag=1
endif
 
ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
    LOCAL_ARM_NEON  := true
    LOCAL_SRC_FILES += $(DECODER_SOURCES_ARM)
    LOCAL_CFLAGS    += -DOC_ARM_ASM -DOC_ARM_ASM_NEON 
endif
 
#ifeq ($(TARGET_ARCH_ABI),armeabi)
#    LOCAL_CFLAGS    += -DOC_ARM_ASM 
#endif 

include $(BUILD_STATIC_LIBRARY)

$(call import-module,android/cpufeatures)



