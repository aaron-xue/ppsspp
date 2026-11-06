@echo off
setlocal enabledelayedexpansion

set NDK=%LOCALAPPDATA%\Android\Sdk\ndk\29.0.14206865
set NDK_BUILD=%NDK%\ndk-build.cmd

echo ========================================
echo  PPSSPP Libretro Android Build (ndk-build)
echo ========================================
echo   NDK        : %NDK%
echo ----------------------------------------

if not exist "%NDK_BUILD%" (
    echo ERROR: ndk-build.cmd not found at %NDK_BUILD%
    pause
    exit /b 1
)

echo [1/4] Pre-generating git-version.cpp (Windows-safe)...
for /f "tokens=*" %%i in ('git -C %CD% describe --always 2^>nul') do set GIT_VER=%%i
if "%GIT_VER%"=="" set GIT_VER=v-1.unknown
echo const char *PPSSPP_GIT_VERSION = "%GIT_VER%"; > git-version.cpp
echo #define PPSSPP_GIT_VERSION_NO_UPDATE 0 >> git-version.cpp
echo   Version: %GIT_VER%
echo.
echo [2/4] ndk-build clean...
cd /d D:\workspace\ppsspp
call "%NDK_BUILD%" NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=libretro/jni/Android.mk APP_ABI=arm64-v8a APP_PLATFORM=android-21 APP_STL=c++_static APP_SUPPORT_FLEXIBLE_PAGE_SIZES=true clean -j %NUMBER_OF_PROCESSORS%

echo [3/4] Cleaning old output directories...
if exist libs (
    rmdir /s /q libs
    echo   Cleaned libs/ directory.
)
if exist obj (
    rmdir /s /q obj
    echo   Cleaned obj/ directory.
)

echo [4/4] Building...
cd /d D:\workspace\ppsspp
call "%NDK_BUILD%" NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=libretro/jni/Android.mk APP_ABI=arm64-v8a APP_PLATFORM=android-21 APP_STL=c++_static APP_SUPPORT_FLEXIBLE_PAGE_SIZES=true -j %NUMBER_OF_PROCESSORS%

if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: ndk-build failed.
    pause
    exit /b 1
)

set OUTPUT_SO=libs\arm64-v8a\libretro.so
set TARGET_SO=ppsspp_libretro_android.so

if exist %OUTPUT_SO% (
    echo.
    echo ========================================
    echo  BUILD SUCCESS
    echo ========================================
    for %%A in (%OUTPUT_SO%) do echo   Size   : %%~zA bytes
    echo   Output : %CD%\%OUTPUT_SO%
    echo.
    echo   Renaming to %TARGET_SO%...
    copy /Y %OUTPUT_SO% %TARGET_SO%
    echo   Ready  : %CD%\%TARGET_SO%
    echo ----------------------------------------
) else (
    echo.
    echo WARNING: Output .so not found, searching...
    dir /s /b *.so 2>nul
)

pause