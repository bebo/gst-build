project('GObject Introspection and PyGObject for Gstreamer', 'c',
  version : '1.15.0.1',
  meson_version : '>= 0.47.0',
  default_options : ['buildtype=debugoptimized'])

gst_version = '>= @0@'.format(meson.project_version())

glib_req = '>= 2.40.0'

build_system = build_machine.system()
cc = meson.get_compiler('c')

# Make it possible to use msys2 built zlib which fails
# when not using the mingw toolchain as it uses unistd.h
if not meson.is_subproject() and cc.get_id() == 'msvc'
  uname = find_program('uname', required: false)
  if uname.found()
    ret = run_command(uname, '-o')
    if ret.returncode() == 0 and ret.stdout().to_lower() == 'msys'
      ret = run_command(uname, '-r')
      # The kernel version returned by uname is actually the msys version
      if ret.returncode() == 0 and ret.stdout().startswith('2')
        # If a system zlib is found, disable UNIX features in zlib.h and zconf.h
        if cc.find_library('z').found()
          add_global_arguments('-DZ_SOLO', language: 'c')
        endif
      endif
    endif
  endif
endif

subprojects = {
    'gobject-introspection' : { 'option': get_option('gi') },
    'pygobject-3.0': { 'option': get_option('pygobject') },
}

python3 = import('python3').find_python()
symlink = '''
import os

os.symlink(os.path.join('@1@', 'subprojects', '@0@'),
  os.path.join('@1@', '@0@'))
'''

subprojects_names = []
foreach project_name, build_infos: subprojects
    build = true
    if build_infos.has_key('option')
      build = not build_infos.get('option').disabled()
      if build
        foreach dep: build_infos.get('dependencies', [])
          if dep.found() == false
            warning('@0@ dependency @1@ not found - NOT BUILDING'.format(project_name, dep))
            build = false
          endif
        endforeach
      endif
    endif

    if build
      subprojects_names += [project_name]
      subproject(project_name, version: gst_version)
      cmdres = run_command(python3, '-c', symlink.format(project_name, meson.current_source_dir()))
      if cmdres.returncode() == 0
        message('Created symlink to ' + project_name)
      endif
    endif
endforeach

message('Building subprojects: ' + ', '.join(subprojects_names))
