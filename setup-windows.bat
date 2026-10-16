@echo off
setlocal
cd /d "%~dp0"

REM ============================================================
REM  setup-windows.bat
REM  Однократная подготовка зависимостей (SFML 2.5.1) под Windows.
REM  Скачивает исходники SFML и собирает статические библиотеки
REM  текущим компилятором (MinGW-w64). Повторный запуск ничего
REM  не перекачивает и не пересобирает, если установка готова.
REM
REM  Требуется: cmake, g++ (MinGW-w64) в PATH.
REM ============================================================

set "VERSION=2.5.1"
set "DEPS_DIR=build\deps"
set "SRC_DIR=%DEPS_DIR%\SFML-%VERSION%"
set "BUILD_DIR=%DEPS_DIR%\SFML-%VERSION%-build"
set "INSTALL_DIR=%DEPS_DIR%\SFML-%VERSION%-install"
set "ARCHIVE=%DEPS_DIR%\SFML-%VERSION%-sources.zip"
set "URL=https://www.sfml-dev.org/files/SFML-%VERSION%-sources.zip"

where cmake >nul 2>nul
if errorlevel 1 (
    echo [ERROR] cmake not found. Install CMake 3.16 or later and add it to PATH.
    exit /b 1
)

where g++ >nul 2>nul
if errorlevel 1 (
    echo [ERROR] g++ not found. Install MinGW-w64 and add it to PATH.
    exit /b 1
)

for /f "tokens=1 delims=." %%v in ('g++ -dumpversion') do set "GXX_MAJOR=%%v"
if not defined GXX_MAJOR (
    echo [ERROR] cannot detect g++ version.
    exit /b 1
)
if %GXX_MAJOR% LSS 12 (
    echo [ERROR] g++ 12 or later is required, found version %GXX_MAJOR%.
    exit /b 1
)

if exist "%INSTALL_DIR%\lib\cmake\SFML\SFMLConfig.cmake" (
    echo [OK] SFML %VERSION% is already built: %INSTALL_DIR%
    exit /b 0
)

if not exist "%SRC_DIR%\CMakeLists.txt" (
    echo [..] Downloading SFML %VERSION% sources...
    if not exist "%DEPS_DIR%" mkdir "%DEPS_DIR%"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing -Uri '%URL%' -OutFile '%ARCHIVE%'"
    if errorlevel 1 (
        echo [ERROR] Failed to download %URL%
        exit /b 1
    )
    echo [..] Extracting SFML %VERSION% sources...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ARCHIVE%' -DestinationPath '%DEPS_DIR%' -Force"
    if errorlevel 1 (
        echo [ERROR] Failed to extract %ARCHIVE%
        exit /b 1
    )
    del /q "%ARCHIVE%"
)

echo [..] Configuring static SFML %VERSION% build...
cmake -S "%SRC_DIR%" -B "%BUILD_DIR%" -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=OFF -DSFML_BUILD_AUDIO=OFF -DSFML_BUILD_NETWORK=OFF -DSFML_BUILD_EXAMPLES=OFF -DSFML_BUILD_DOC=OFF -DSFML_BUILD_FRAMEWORKS=OFF -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%"
if errorlevel 1 (
    echo [ERROR] SFML configure failed.
    exit /b 1
)

echo [..] Building static SFML %VERSION% (first run only, it may take a while)...
cmake --build "%BUILD_DIR%" --config Release --target install -j
if errorlevel 1 (
    echo [ERROR] SFML build failed.
    exit /b 1
)

echo [OK] SFML %VERSION% is ready: %INSTALL_DIR%
if exist "%ARCHIVE%" del /q "%ARCHIVE%"
echo      Now run compile-windows.bat to build the solver.
exit /b 0