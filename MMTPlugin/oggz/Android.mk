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

SOURCES := \
	src/liboggz/dirac.c \
	src/liboggz/metric_internal.c \
	src/liboggz/oggz.c \
	src/liboggz/oggz_auto.c \
	src/liboggz/oggz_comments.c \
	src/liboggz/oggz_dlist.c \
	src/liboggz/oggz_io.c \
	src/liboggz/oggz_read.c \
	src/liboggz/oggz_seek.c \
	src/liboggz/oggz_stream.c \
	src/liboggz/oggz_table.c \
	src/liboggz/oggz_vector.c \
	src/liboggz/oggz_write.c \
	
LOCAL_MODULE    := liboggz
LOCAL_SRC_FILES := $(SOURCES)
LOCAL_CFLAGS := -fvisibility=hidden
LOCAL_ARM_MODE := arm
LOCAL_C_INCLUDES := $(LOCAL_PATH)/include $(LOCAL_PATH)/../ogg/include $(LOCAL_PATH)/android

include $(BUILD_STATIC_LIBRARY)

