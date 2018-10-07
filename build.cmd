@ECHO OFF

:: The build.cmd script implements the build process for Microsoft Visual C++
:: on Microsoft Windows platforms.

:: Ensure that setenv.cmd has been called.
IF [%ROOTDIR%] EQU [] (
    CALL setenv.cmd
)
IF [%ROOTDIR%] EQU [] (
    ECHO ERROR: No ROOTDIR defined. Did setenv.cmd fail? Skipping build.
    EXIT /B 1
)

:: Everything past this point is done in a local environment to allow switching
:: between debug and release build configurations.
SETLOCAL

:: Process command line arguments passed to the script
:Process_Argument
IF [%1] EQU [] GOTO Default_Arguments
IF /I "%1" == "debug" SET BUILD_CONFIGURATION=debug
IF /I "%1" == "release" SET BUILD_CONFIGURATION=release
SHIFT
GOTO Process_Argument

:Default_Arguments
IF [%BUILD_CONFIGURATION%] EQU [] SET BUILD_CONFIGURATION=release

:: Specify the location of SDL2 files, since they aren't 'installed' like they are on Linux.
SET SDL2_INCLUDES=C:\Development
SET SDL2_LIBRARIES=C:\Development\SDL2\Dev\lib\x64
SET SDL2_BINARIES=C:\Development\SDL2\Dev\lib\x64

IF [%SDL2_INCLUDES%] EQU [] (
    ECHO WARNING: No SDL2_INCLUDES path defined. This may result in build errors.
) ELSE (
    IF NOT EXIST "%SDL2_INCLUDES%" (
        ECHO WARNING: SDL2_INCLUDES is set, but the path does not exist. This may result in build errors.
    )
)
IF [%SDL2_LIBRARIES%] EQU [] (
    ECHO WARNING: No SDL2_LIBRARIES path defined. This may result in build errors.
) ELSE (
    IF NOT EXIST "%SDL2_LIBRARIES%" (
        ECHO WARNING: SDL2_LIBRARIES is set, but the path does not exist. This may result in build errors.
    )
)
IF [%SDL2_BINARIES%] EQU [] (
    ECHO WARNING: No SDL2_BINARIES path defined. This may result in runtime errors.
) ELSE (
    IF NOT EXIST "%SDL2_BINARIES%" (
        ECHO WARNING: SDL2_BINARIES is set, but the path does not exist. This may result in runtime errors.
    )
)

:: Ensure that a Vulkan SDK is installed.
IF [%VULKAN_SDK%] EQU [] (
    ECHO ERROR: No VULKAN_SDK environment variable defined.
    EXIT /b 1
)

:: Specify the source files for the GEODE library.
SET COMMON_SOURCES="%SOURCESDIR%\*.cc"
SET PLATFORM_SOURCES="%SOURCESDIR%\win32\*.cc"

:: Specify the libraries the test drivers should link with.
SET LIBRARIES=User32.lib Gdi32.lib Shell32.lib Advapi32.lib winmm.lib SDL2.lib SDL2main.lib

:: Specify cl.exe and link.exe settings.
SET DEFINES_COMMON=/D WINVER=%WINVER% /D _WIN32_WINNT=%WINVER% /D UNICODE /D _UNICODE /D _STDC_FORMAT_MACROS /D _CRT_SECURE_NO_WARNINGS
SET DEFINES_COMMON_DEBUG=%DEFINES_COMMON% /D DEBUG /D _DEBUG
SET DEFINES_COMMON_RELEASE=%DEFINES_COMMON% /D NDEBUG /D _NDEBUG
SET INCLUDES_COMMON=-I"%INCLUDESDIR%" -I"%SDL2_INCLUDES%" -I"%RESOURCEDIR%" -I"%SOURCESDIR%" -I"%MAINDIR%"
SET CPPFLAGS_COMMON=%INCLUDES_COMMON% /FC /nologo /W4 /WX /wd4505 /wd4205 /wd4204 /Zi /EHsc
SET CPPFLAGS_DEBUG=%CPPFLAGS_COMMON% /Od
SET CPPFLAGS_RELEASE=%CPPFLAGS_COMMON% /Ob2it

:: Specify build-configuration settings.
IF /I "%BUILD_CONFIGURATION%" == "release" (
    SET DEFINES=%DEFINES_COMMON_RELEASE%
    SET CPPFLAGS=%CPPFLAGS_RELEASE%
    SET LNKFLAGS=%LIBRARIES% /MT
) ELSE (
    SET DEFINES=%DEFINES_COMMON_DEBUG%
    SET CPPFLAGS=%CPPFLAGS_DEBUG%
    SET LNKFLAGS=%LIBRARIES% /MTd
)

ECHO Build output will be placed in "%OUTPUTDIR%".
ECHO SDL2_INCLUDES is "%SDL2_INCLUDES%".
ECHO SDL2_LIBRARIES is "%SDL2_LIBRARIES%".
ECHO SDL2_BINARIES is "%SDL2_BINARIES%".
ECHO VULKAN_SDK is "%VULKAN_SDK%".
ECHO.

:: Ensure that the output directory exists.
IF NOT EXIST "%OUTPUTDIR%" MKDIR "%OUTPUTDIR%"
IF NOT EXIST "%OUTPUTDIR%\SDL2.dll" XCOPY "%SDL2_BINARIES%\*.dll" "%OUTPUTDIR%" /Y /Q
IF NOT EXIST "%OUTPUTDIR%\vulkan-1.dll" XCOPY "%VULKAN_SDK%\Source\lib\vulkan-1.dll" "%OUTPUTDIR%" /Y /Q

:: Initialize the build result state.
SET BUILD_FAILED=

:: Build the primary artifact, GEODE.dll.
PUSHD "%OUTPUTDIR%"
cl.exe %CPPFLAGS% %COMMON_SOURCES% %PLATFORM_SOURCES% %DEFINES% %LNKFLAGS% /FAs /FeGEODE.dll /link /DLL /LIBPATH:"%LIBSDIR%" /LIBPATH:"%SDL2_LIBRARIES%"
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: Build failed for GEODE.dll.
    SET BUILD_FAILED=1
    GOTO Check_Build
)
POPD

:: Build all of the test module entry points.
PUSHD "%OUTPUTDIR%"
FOR %%x IN ("%MAINDIR%"\*.c*) DO (
    cl.exe %CPPFLAGS% %COMMON_SOURCES% %PLATFORM_SOURCES% "%%x" %DEFINES% %LNKFLAGS% /FAs /Fe%%~nx.exe /link /SUBSYSTEM:console /LIBPATH:"%LIBSDIR%" /LIBPATH:"%SDL2_LIBRARIES%"
    IF %ERRORLEVEL% NEQ 0 (
        ECHO ERROR: Build failed for %%~nx.exe.
        SET BUILD_FAILED=1
    )
)
POPD

:Check_Build
IF [%BUILD_FAILED%] NEQ [] (
    GOTO Build_Failed
) ELSE (
    GOTO Build_Succeeded
)

:Build_Failed
ECHO BUILD FAILED.
ENDLOCAL
EXIT /B 1

:Build_Succeeded
ECHO BUILD SUCCEEDED.
ENDLOCAL
EXIT /B 0

:SetEnv_Failed
EXIT /b 1

