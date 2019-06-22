# distutils: language = c++
# cython: language_level=3

from cpython.version cimport PY_MAJOR_VERSION

cdef unicode to_unicode(s):
	if type(s) is unicode:
		# Fast path for most common case(s).
		return <unicode>s
		
	elif PY_MAJOR_VERSION < 3 and isinstance(s, bytes):
		# Only accept byte strings as text input in Python 2.x, not in Py3.
		return (<bytes>s).decode('ascii')
		
	elif isinstance(s, unicode):
		# We know from the fast path above that 's' can only be a subtype here.
		# An evil cast to <unicode> might still work in some(!) cases,
		# depending on what the further processing does.  To be safe,
		# we can always create a copy instead.
		return unicode(s)
		
	else:
		raise TypeError("Could not convert to unicode.")

cdef string as_string(s):
	return PyBytes_AS_STRING(to_unicode(s).encode('UTF-8'))
