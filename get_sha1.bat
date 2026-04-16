@echo off
echo Getting SHA-1 certificate...
echo.

REM Try keytool from common locations
set KEYTOOL_PATHS=^
"C:\Program Files\Java\jdk-17\bin\keytool.exe" ^
"C:\Program Files\Java\jdk-11\bin\keytool.exe" ^
"C:\Program Files\Java\jdk1.8.0_*\bin\keytool.exe" ^
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" ^
"%JAVA_HOME%\bin\keytool.exe"

for %%K in (%KEYTOOL_PATHS%) do (
    if exist %%K (
        echo Found keytool at: %%K
        echo.
        %%K -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr "SHA1"
        goto :end
    )
)

echo Keytool not found. Please install Java JDK.
echo.
echo Alternative: Run this command in Android Studio Terminal:
echo ./gradlew signingReport
echo.

:end
pause
