AC_PREREQ(2.59)
AC_INIT([libendf], [0.1], [rainwoodman@gmail.com])
AC_CONFIG_MACRO_DIR([autotools])
AC_CONFIG_AUX_DIR([autotools])
AC_SUBST(ACLOCAL_AMFLAGS, "-I autotools")
AC_CONFIG_HEADERS([config.h])
AM_INIT_AUTOMAKE([tar-ustar foreign subdir-objects])

AM_MAINTAINER_MODE
AC_PROG_LIBTOOL
DOLT

AC_PROG_CC
AM_PROG_CC_C_O
CFLAGS="$CFLAGS -std=c99"
VALA_PROG_VALAC([0.7.2])
VALA_PROG_VALADOC

PKG_PROG_PKG_CONFIG([0.21])

VALA_VAPI_DIRS(['$(top_srcdir)/vapi'])
PKG_CHECK_MODULES(GLIB, [glib-2.0 >= 2.10 gobject-2.0 >= 2.10])
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

PKG_CHECK_MODULES(GSL, [gsl])
AC_SUBST(GSL_CFLAGS)
AC_SUBST(GSL_LIBS)


AC_CONFIG_FILES([
libendf-1.0.pc
Makefile 
src/Makefile
tests/Makefile
tools/Makefile
])
AC_OUTPUT
