@echo off
echo Killing all Java processes...
taskkill /F /IM java.exe 2>nul
taskkill /F /IM javaw.exe 2>nul

echo.
echo Deleting Gradle caches...
rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
rmdir /s /q "%USERPROFILE%\.gradle\daemon" 2>nul
rmdir /s /q "%USERPROFILE%\.gradle\wrapper" 2>nul

echo.
echo Deleting project Gradle files...
rmdir /s /q "android\.gradle" 2>nul
rmdir /s /q "android\app\.externalNativeBuild" 2>nul
rmdir /s /q "android\app\.cxx" 2>nul
rmdir /s /q "android\app\build" 2>nul
rmdir /s /q "build" 2>nul

echo.
echo Clean complete! You can now run: flutter run
pause
