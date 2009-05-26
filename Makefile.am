lib_LTLIBRARIES = libendf.la 
libendf_la_CPPFLAGS = -DG_LOG_DOMAIN=\"ENDF\" $(GLIB_CFLAGS) $(GSL_CFLAGS)

BUILT_SOURCES = vala-ccode

VALAFLAGS= --library=libendf -H libendf.h
VALADOCFLAGS = -o Documentation --package-name=libendf
VALAPKGS = --pkg gsl

libendf= \
	$(VALASOURCES:.vala=.c)\
	libendf.h

VALASOURCES = \
	libendf.vala

vala-ccode: $(VALASOURCES)
	$(VALAC) $(VALAFLAGS) -C $^ $(VALAPKGS) 
	echo gmodule-2.0 > libendf.deps
	echo gsl >> libendf.deps
	touch vala-ccode

vapi_DATA = libendf.vapi
vapidir=$(datadir)/vala/vapi
libendfinclude_HEADERS = libendf.h
libendfincludedir = $(includedir)/libendf

if ENABLE_VALADOC
@VALA_DOC_RULES@
else
vala-doc:
	touch vala-doc;
endif
BUILT_SOURCES+=vala-doc
EXTRA_DIST = $(VALASOURCES) vala-ccode libendf.vapi libendf.gir libendf.deps vala-doc

$(DIST_SOURCES) : vala-ccode vala-doc

MAINTAINERCLEANFILES = $(VALASOURCES:.vala=.c) libendf.h \
                       libendf.vapi libendf.deps libendf.gir \
                       Documentation
