import sys

# import Test()
SConscript(['scons/SConsTest'])
Import('enable_test')

my_cppdefines = {}

# Check endianness
if sys.byteorder == "big":
	print "Host is big endian"
	my_cppdefines['WORDS_BIGENDIAN'] = 1
else:
	print "Host is little endian"

opts = Options()
opts.Add(BoolOption('enable_read', 'Set to 0 to disable reading support', 1))
my_cppdefines['OGGZ_CONFIG_READ'] = '${enable_read}'

opts.Add(BoolOption('enable_write', 'Set to 0 to disable writing support', 1))
my_cppdefines['OGGZ_CONFIG_WRITE'] = '${enable_write}'

libenv = Environment(options = opts,
                     CPPPATH = '#/scons',
                     CPPDEFINES = my_cppdefines)
Export('libenv')

progenv = libenv.Copy()
progenv.Append(LIBS = ['oggz', 'ogg'])
progenv.Append(LIBPATH = '../liboggz')
progenv.Dictionary('ENV')['LD_LIBRARY_PATH'] = './src/liboggz/'
enable_test (progenv)
Export('progenv')

dict = libenv.Dictionary()

enable_read = dict['enable_read']
Export('enable_read')
enable_write = dict['enable_write']
Export('enable_write')

SConscript(['src/SConscript'])
