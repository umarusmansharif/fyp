@echo off
echo Cleaning Windows build files...

REM Delete Windows build directory
if exist "build\windows" (
    rmdir /s /q "build\windows"
    echo Deleted build\windows
)

REM Delete Windows Flutter intermediates
if exist "windows\flutter\ephemeral" (
    rmdir /s /q "windows\flutter\ephemeral"
    echo Deleted windows\flutter\ephemeral
)

REM Clean Flutter
flutter clean

REM Get dependencies
flutter pub get

echo.
echo Windows build cleaned successfully!
echo You can now run: flutter run -d windows
pause
