@echo off
setlocal
cd /d "%~dp0"

REM ============================================================
REM  compile-windows.bat
REM  Сборка solver (Windows) готовым сборочным каталогом.
REM  Библиотеки SFML должны быть подготовлены заранее:
REM      setup-windows.bat
REM  Результат: build\solver.exe (+ шрифты и runtime MinGW рядом).
REM ============================================================

where cmake >nul 2>nul
if errorlevel 1 (
    echo [ERROR] cmake not found. Install CMake 3.16 or later and add it to PATH.
    exit /b 1
)

set "SFML_DIR=build\deps\SFML-2.5.1-install\lib\cmake\SFML"
if not exist "%SFML_DIR%\SFMLConfig.cmake" (
    echo [ERROR] SFML is not built yet. Run setup-windows.bat first.
    exit /b 1
)

REM Удаляем устаревшие каталоги сборки от прежних экспериментов.
for %%d in (build-static build-262-static build-local build-win) do (
    if exist "%%d" (
        echo [..] Removing stale build dir %%d
        rd /s /q "%%d"
    )
)

cmake -S . -B build -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DSFML_DIR="%CD%\%SFML_DIR%" -DSFML_STATIC_LIBRARIES=TRUE
if errorlevel 1 (
    echo [ERROR] CMake configure failed. Run setup-windows.bat if SFML is missing.
    exit /b 1
)

cmake --build build -j
if errorlevel 1 (
    echo [ERROR] Build failed.
    exit /b 1
)

REM Статически слинкованный solver.exe требует runtime-библиотек MinGW-w64.
REM Копируем их из каталога компилятора (если они есть) рядом с exe.
where g++ >nul 2>nul
if not errorlevel 1 (
    set "GXX_DIR="
    for /f "delims=" %%p in ('where g++') do if not defined GXX_DIR set "GXX_DIR=%%~dp"
    for %%f in (libstdc++-6.dll libgcc_s_seh-1.dll libwinpthread-1.dll) do (
        if exist "%GXX_DIR%%%f" copy /y "%GXX_DIR%%%f" build\ >nul
    )
)

echo [OK] Built: %CD%\build\solver.exe
exit /b 0