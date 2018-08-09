
@echo on
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat" x64
@echo on
set errorlevel=

SET DESTDIR=C:\bebo-gst
rd /s /q %DESTDIR%
set errorlevel=
mkdir %DESTDIR%

py -3 -c "import urllib.request, sys; urllib.request.urlretrieve(*sys.argv[1:])" "https://s3-us-west-1.amazonaws.com/bebo-app/repo/python/python-3.6.6-amd64-orig.zip" python.zip
py -3 -m zipfile -e python.zip %DESTDIR%
@if errorlevel 1 (
  exit /b %errorlevel%
)

assoc .py=Python.File
ftype Python.File=%DESTDIR%\python.exe "%1" %*

set PATH=%DESTDIR%;%DESTDIR%\Scripts;%DESTDIR%\bin;%CD%\pkg-config-lite-0.28-1\bin;%CD%\win_flex_bison;%PATH%
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

mkdir build
meson build

@if errorlevel 1 (
  exit /b %errorlevel%
)

meson configure build -D gstreamer:introspection=enabled
meson configure build -D gst-plugins-base:introspection=enabled
meson configure build -Dgst-plugins-bad:gl=enabled
meson configure build -D gst-plugins-good:jpeg=enabled

ninja -C build
@if errorlevel 1 (
  exit /b %errorlevel%
)
ninja -C build install
@if errorlevel 1 (
  exit /b %errorlevel%
)
