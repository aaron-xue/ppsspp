LOCAL_PATH := $(call my-dir)

GIT_VERSION := " $(shell git rev-parse --short HEAD || echo unknown)"
ifneq ($(GIT_VERSION)," unknown")
	COREFLAGS += -DGIT_VERSION=\"$(GIT_VERSION)\"
endif

COREFLAGS  := -DSTACK_LINE_READER_BUFFER_SIZE=1024 -DHAVE_DLFCN_H
CORE_DIR   := D:/workspace/ppsspp
FFMPEGDIR  := $(CORE_DIR)/ext/ffmpeg
WITH_DYNAREC := 1

ifeq ($(TARGET_ARCH),arm64)
  COREFLAGS += -D_ARCH_64
  HAVE_NEON := 1
endif

ifeq ($(TARGET_ARCH),arm)
  COREFLAGS += -D__arm__ -DARM_ASM -D_ARCH_32 -mfpu=neon
  HAVE_NEON := 1
endif

ifeq ($(TARGET_ARCH),x86)
  COREFLAGS += -D_ARCH_32 -D_M_IX86 -fomit-frame-pointer -mtune=atom -mfpmath=sse -mssse3 -mstackrealign
endif

ifeq ($(TARGET_ARCH),x86_64)
  COREFLAGS += -D_ARCH_64 -D_M_X64 -fomit-frame-pointer -mtune=atom -mfpmath=sse -mssse3 -mstackrealign
endif

# FFmpeg, from the sources in ext/ffmpeg. See its README.md.
include $(CLEAR_VARS)
include $(CORE_DIR)/ext/ffmpeg-build/sources.mk
LOCAL_MODULE := libffmpeg
LOCAL_SRC_FILES := $(addprefix $(FFMPEGDIR)/,$(FFMPEG_SOURCES))
LOCAL_CFLAGS := -O2 -Wa,--noexecstack -I$(CORE_DIR)/ext/ffmpeg-build -I$(FFMPEGDIR) -DHAVE_AV_CONFIG_H -D_ISOC99_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -w -Werror=implicit-function-declaration
LOCAL_ASFLAGS := -Wa,--noexecstack
include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)

PLATFORM_EXT   := android
platform := android
GLES = 1

LOCAL_SHORT_COMMANDS := true
LOCAL_MODULE := retro

# Override fopen_utf8.h from libretro-common submodule (uses open+fdopen to bypass adrenotools hook)
INCFLAGS += -I$(LOCAL_PATH)/../include-override

include $(CORE_DIR)/libretro/Makefile.common

COREFLAGS += -DINLINE="inline" -DPPSSPP -DUSE_FFMPEG -DWITH_UPNP -DMOBILE_DEVICE -DBAKE_IN_GIT -DDYNAREC -D__LIBRETRO__ -DUSING_GLES2 -D__STDC_CONSTANT_MACROS -DGLEW_NO_GLU -DMINIUPNP_STATICLIB $(INCFLAGS)
LOCAL_SRC_FILES = $(SOURCES_CXX) $(SOURCES_C) $(ASMFILES)
# ARM64 libpng NEON 支持
ifeq ($(TARGET_ARCH),arm64)
LOCAL_SRC_FILES += $(CORE_DIR)/ext/libpng17/arm/arm_init.c
LOCAL_SRC_FILES += $(CORE_DIR)/ext/libpng17/arm/filter_neon_intrinsics.c
endif

LOCAL_CPPFLAGS := -frtti -fexceptions -Wall -std=c++17 $(COREFLAGS) -DSPIRV_CROSS_EXCEPTIONS_TO_ASSERTIONS $(DEFINES)
LOCAL_CFLAGS := -O2 -Wa,--noexecstack -DANDROID $(COREFLAGS) $(DEFINES)
LOCAL_ASFLAGS := -Wa,--noexecstack
LOCAL_LDFLAGS := -Wl,--no-gc-sections -Wl,-z,max-page-size=16384 -Wl,-z,noexecstack
LOCAL_LDLIBS += -lz -landroid -lGLESv2 -lOpenSLES -lEGL -ldl -llog -latomic
LOCAL_STATIC_LIBRARIES += libffmpeg

include $(BUILD_SHARED_LIBRARY)
