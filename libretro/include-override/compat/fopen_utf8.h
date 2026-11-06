/* Copyright  (C) 2010-2020 The RetroArch team
 *
 * Override of libretro-common's fopen_utf8.h for PPSSPP libretro on Android.
 * Uses open()+fdopen() instead of fopen() to bypass adrenotools' fopen hook.
 */

#ifndef __LIBRETRO_SDK_COMPAT_FOPEN_UTF8_H
#define __LIBRETRO_SDK_COMPAT_FOPEN_UTF8_H

#ifdef _WIN32
void *fopen_utf8(const char * filename, const char * mode);
#else
#include <stdio.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>

static inline FILE *fopen_utf8(const char *filename, const char *mode)
{
   int flags = 0;
   int fd;

   if (!filename || !mode)
      return NULL;

   if (strchr(mode, '+'))
      flags = O_RDWR;
   else if (strchr(mode, 'r'))
      flags = O_RDONLY;
   else if (strchr(mode, 'w'))
      flags = O_WRONLY;
   else if (strchr(mode, 'a'))
      flags = O_WRONLY;

   if (strchr(mode, 'w'))
      flags |= O_CREAT | O_TRUNC;
   if (strchr(mode, 'a'))
      flags |= O_CREAT | O_APPEND;

   fd = open(filename, flags, 0666);
   if (fd < 0)
      return NULL;

   return fdopen(fd, mode);
}
#endif
#endif
