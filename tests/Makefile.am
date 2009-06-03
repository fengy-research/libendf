VALAPKGS = --pkg libendf
VALAFLAGS = --vapidir ../src
noinst_PROGRAMS = test-parser

test_parser_CPPFLAGS = $(GLIB_CFLAGS) $(GSL_CFLAGS) -I$(top_srcdir)/src
test_parser_LDFLAGS = -L$(top_builddir)/src
test_parser_LDADD = $(GLIB_LIBS) -lendf $(GSL_LIBS)

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

