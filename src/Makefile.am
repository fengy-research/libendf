lib_LTLIBRARIES = libendf.la 
libendf_la_CPPFLAGS = -DG_LOG_DOMAIN=\"ENDF\" $(GLIB_CFLAGS) $(GSL_CFLAGS)

BUILT_SOURCES = vala-ccode

VALAFLAGS= --library=libendf-1.0 -H libendf-1.0.h
VALADOCFLAGS = -o Documentation --package-name=libendf-1.0
VALAPKGS = --pkg gsl

libendf_la_SOURCES= \
	$(VALASOURCES:.vala=.c)\
	libendf-1.0.h

VALASOURCES = \
	enum.vala \
	number.vala \
	mat-type.vala \
	mf-type.vala \
	mt-type.vala \
	int-type.vala \
	interpolation.vala \
	event.vala \
	section.vala \
	mf7mt2.vala \
	parser.vala

vala-ccode: $(VALASOURCES)
	$(VALAC) $(VALAFLAGS) -C $^ $(VALAPKGS) 
	echo gmodule-2.0 > libendf-1.0.deps
	echo gsl >> libendf-1.0.deps
	touch vala-ccode

vapi_DATA = libendf-1.0.vapi
vapidir=$(datadir)/vala/vapi
include_HEADERS = libendf-1.0.h

if ENABLE_VALADOC
@VALA_DOC_RULES@
else
vala-doc:
	touch vala-doc;
endif
BUILT_SOURCES+=vala-doc
EXTRA_DIST = $(VALASOURCES) vala-ccode libendf-1.0.vapi libendf-1.0.gir libendf-1.0.deps vala-doc


$(DIST_SOURCES) : vala-ccode vala-doc

MAINTAINERCLEANFILES = $(VALASOURCES:.vala=.c) libendf-1.0.h \
                       libendf-1.0.vapi libendf-1.0.deps libendf-1.0.gir \
                       Documentation
