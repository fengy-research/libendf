VALAPKGS = --pkg libendf-1.0
VALAFLAGS = --vapidir ../src
noinst_PROGRAMS = test-mf7mt2 test-mf7mt4 elastic

AM_CPPFLAGS = $(GLIB_CFLAGS) $(GSL_CFLAGS) -I$(top_srcdir)/src
AM_LDFLAGS = -L$(top_builddir)/src
LDADD = $(GLIB_LIBS) -lendf $(GSL_LIBS)

SUFFIXES = .vala .c
.vala.c :
	$(VALAC) $(VALAFLAGS) -C $^ $(VALAPKGS)
	touch $@

BUILT_SOURCES = $(noinst_PROGRAMS:=.c)
EXTRA_DIST = $(noinst_PROGRAMS:=.vala)

check-local:
	for i in $(noinst_PROGRAMS); do \
		./$$i; \
    done;

