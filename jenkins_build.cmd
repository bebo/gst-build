
@echo on
set PATH=C:\Windows\system32;C:\Windows;C:\Users\build\bin
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat" x64
@echo on
echo %PATH%
ninja --version

set errorlevel=

SET DESTDIR=C:\bebo-gst
set FILENAME=gst-bebo_%TAG%.zip

rd /s /q %DESTDIR%
del /q %FILENAME%
rd /s /q build
rd /s /q bootstrap\build

set errorlevel=
mkdir %DESTDIR%


py -3 -c "import urllib.request, sys; urllib.request.urlretrieve(*sys.argv[1:])" "https://s3-us-west-1.amazonaws.com/bebo-app/repo/python/python-3.6.6-amd64-orig.zip" python.zip
py -3 -m zipfile -e python.zip %DESTDIR%
@if errorlevel 1 (
  exit /b %errorlevel%
)

SET RUN_MESON=%DESTDIR%\python.exe %DESTDIR%\Scripts\meson.py

SET PATH=%DESTDIR%;%DESTDIR%\Scripts;%DESTDIR%\bin;%CD%\pkg-config-lite-0.28-1\bin;%CD%\win_flex_bison;%PATH%
SET PKG_CONFIG_PATH=%DESTDIR%\lib\pkgconfig

py -3 -c "import urllib.request, sys; urllib.request.urlretrieve(*sys.argv[1:])" "https://github.com/lexxmark/winflexbison/releases/download/v2.5.14/win_flex_bison-2.5.14.zip" win_flex_bison.zip
py -3 -m zipfile -e win_flex_bison.zip win_flex_bison

py -3 -c "import urllib.request, sys; urllib.request.urlretrieve(*sys.argv[1:])" "https://sourceforge.net/projects/pkgconfiglite/files/0.28-1/pkg-config-lite-0.28-1_bin-win32.zip/download" pkg-config-lite-0.28-1.zip
py -3 -m zipfile -e pkg-config-lite-0.28-1.zip .

@if errorlevel 1 (
  exit /b %errorlevel%
)

python -m pip install meson

@if errorlevel 1 (
  exit /b %errorlevel%
)

REM bootstrap 

cd bootstrap
dir
%RUN_MESON% build
%RUN_MESON% configure build -D gi=enabled
%RUN_MESON% configure build -D pygobject=disabled

@if errorlevel 1 (
  exit /b %errorlevel%
)

@REM for some reason on jenkins it doesn't dete changes?
ninja -C build reconfigure
@if errorlevel 1 (
  exit /b %errorlevel%
)

ninja -C build
@if errorlevel 1 (
  exit /b %errorlevel%
)

ninja -C build install
@if errorlevel 1 (
  exit /b %errorlevel%
)
REM FIXME:
move %DESTDIR%\lib\gobject-introspection\giscanner %DESTDIR%\lib\site-packages\

%RUN_MESON% configure build -Dgi=disabled
%RUN_MESON% configure build -Dpygobject=enabled
ninja -C build reconfigure
%RUN_MESON% configure build -D pygobject-3.0:pycairo=false
%RUN_MESON% configure build

ninja -C build reconfigure
@if errorlevel 1 (
  exit /b %errorlevel%
)

ninja -C build
@if errorlevel 1 (
  exit /b %errorlevel%
)

ninja -C build install
@if errorlevel 1 (
  exit /b %errorlevel%
)

cd ..

REM main bulid

mkdir build
%RUN_MESON% build

@if errorlevel 1 (
  exit /b %errorlevel%
)

%RUN_MESON% configure build -D rtsp_server=disabled 
%RUN_MESON% configure build -D gstreamer:introspection=enabled
%RUN_MESON% configure build -D gst-plugins-base:introspection=enabled
%RUN_MESON% configure build -D gst-plugins-bad:gl=enabled
%RUN_MESON% configure build -D gst-plugins-good:jpeg=enabled
%RUN_MESON% configure build -D python=enabled
%RUN_MESON% configure build -D gst-python:pygi-overrides-dir=\Lib\site-packages\gi\overrides

ninja -C build
@if errorlevel 1 (
  exit /b %errorlevel%
)

ninja -C build install
@if errorlevel 1 (
  exit /b %errorlevel%
)

XCOPY /S %DESTDIR%\lib\python3.6\site-packages %DESTDIR%\lib\site-packages\
rd /s /q %DESTDIR%\lib\python3.6\site-packages

set FILEPATH=%CD%\%FILENAME%

pushd
cd %DESTDIR%
py -3 -m zipfile -c %FILEPATH% .

@if errorlevel 1 (
  exit /b %errorlevel%
)
popd

"C:\Program Files\Amazon\AWSCLI\aws.exe" s3api put-object --bucket bebo-app --key repo/gst-bebo/%FILENAME% --body %FILENAME%

@if errorlevel 1 (
  exit /b %errorlevel%
)
@echo uploaded "gst-bebo/%FILENAME%"
