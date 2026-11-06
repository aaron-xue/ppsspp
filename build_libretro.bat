@echo off
setlocal enabledelayedexpansion

set NDK=%LOCALAPPDATA%\Android\Sdk\ndk\29.0.14206865
set BUILD_DIR=build_libretro

echo ========================================
echo  PPSSPP Libretro Android Build
echo ========================================
echo   NDK        : %NDK%
echo   Build Dir  : %BUILD_DIR%
echo   Jobs       : %NUMBER_OF_PROCESSORS%
echo ----------------------------------------

if not exist "%NDK%\build\cmake\android.toolchain.cmake" (
    echo ERROR: NDK not found at %NDK%
    pause
    exit /b 1
)

set SIZE_FLAGS=-O2
set LTO_FLAGS=
set LINK_FLAGS=-Wl,-s

echo ========================================
echo  Size Optimization Flags:
echo    SIZE_FLAGS : %SIZE_FLAGS%
echo    LTO_FLAGS  : %LTO_FLAGS%
echo    LINK_FLAGS : %LINK_FLAGS%
echo ----------------------------------------

echo [0/3] Cleaning previous build...
if exist "%BUILD_DIR%" (
    rmdir /s /q "%BUILD_DIR%"
    echo   Build directory cleaned.
)


echo [1/3] Configuring CMake...
cmake -G Ninja -B %BUILD_DIR% ^
    -DCMAKE_TOOLCHAIN_FILE="%NDK%/build/cmake/android.toolchain.cmake" ^
    -DANDROID_ABI=arm64-v8a ^
    -DANDROID_PLATFORM=android-21 ^
    -DLIBRETRO=ON ^
    -DCMAKE_BUILD_TYPE=Release ^
    -S .

if !ERRORLEVEL! neq 0 (
    echo ERROR: CMake configure failed.
    pause
    exit /b 1
)

echo [2/3] Building ppsspp_libretro...
cmake --build %BUILD_DIR% --target ppsspp_libretro -j %NUMBER_OF_PROCESSORS%
if !ERRORLEVEL! neq 0 (
    echo ERROR: Build failed.
    pause
    exit /b 1
)

if exist "%BUILD_DIR%\ppsspp_libretro_android.so" (
    echo ========================================
    echo  BUILD SUCCESS
    echo ========================================
    echo   Output: %CD%\%BUILD_DIR%\ppsspp_libretro_android.so
    for %%A in ("%BUILD_DIR%\ppsspp_libretro_android.so") do echo   Size   : %%~zA bytes
    echo ----------------------------------------
) else (
    echo WARNING: Output not found, searching...
    dir /s /b %BUILD_DIR%\*.so
)

pause