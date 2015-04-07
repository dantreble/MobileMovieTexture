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

SOURCES := \
	src/bitwise.c \
	src/framing.c 
	
LOCAL_MODULE    := libogg
LOCAL_SRC_FILES := $(SOURCES)
LOCAL_CFLAGS := -fvisibility=hidden
LOCAL_ARM_MODE := arm
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include

include $(BUILD_STATIC_LIBRARY)

