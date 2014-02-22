#!/bin/sh
#
# $Id: autogen.sh,v 1.1 2007-11-26 17:19:08 jack Exp $
#
# Run this to generate all the initial makefiles, etc.
#
# Cases which are known to work:
# 2002-07-14: Debian GNU/Linux unstable with:
#   autoconf 2.54
#   automake 1.4-p6
#   libtool  1.4.2a

export SED=sed

DIE=0
srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.
test "$srcdir" = "." && srcdir=`pwd`

PROJECT=msvideostitcher

# failure subroutine.
# syntax: do-something || fail
fail() {
    status=$?
    echo "Last command failed with status $status in directory $(pwd)."
    echo "Aborting."
    exit $status
}

(autoconf${AUTOCONF_SUFFIX} --version) < /dev/null > /dev/null 2>&1 || {
    echo
    echo "You must have autoconf installed to compile $PROJECT from CVS."
    echo "Download the appropriate package for your distribution,"
    echo "or get the source tarball at ftp://ftp.gnu.org/gnu/autoconf/"
    DIE=1
}

(libtool --version) < /dev/null > /dev/null 2>&1 || {
    echo
    echo "You must have libtool installed to compile $PROJECT from CVS."
    echo "Download the appropriate package for your distribution,"
    echo "or get the source tarball at ftp://ftp.gnu.org/gnu/libtool/"
    DIE=1
}

(automake${AUTOMAKE_SUFFIX} --version) < /dev/null > /dev/null 2>&1 || {
    echo
    echo "You must have automake installed to compile $PROJECT from CVS."
    echo "Download the appropriate package for your distribution,"
    echo "or get the source tarball at ftp://ftp.gnu.org/gnu/automake/"
    DIE=1
}

if test "$DIE" -eq 1; then
    exit 1
fi

case "$CC" in
*xlc | *xlc\ * | *lcc | *lcc\ *) am_opt=--include-deps;;
esac

ACLOCAL_FLAGS="-I . ${ACLOCAL_FLAGS}"

(
echo "Cleaning stuff generated by libtoolize"
rm -f ltmain.sh config.guess config.sub

echo "Cleaning stuff generated by aclocal"
rm -f aclocal.m4

myosname=`uname`
if test "$myosname" = "OpenBSD"; then
# leave this empty
  echo "Os is $myosname"
else
  libtool=`set \`type libtool\` ; echo $3`
  libtool_prefix=`echo $libtool | sed 's|/bin/libtool||g'`
fi

echo "Running libtoolize --copy"
libtoolize --copy || fail

if test "$myosname" = "OpenBSD"; then
  echo "Running aclocal${AUTOMAKE_SUFFIX} $ACLOCAL_FLAGS"
  aclocal${AUTOMAKE_SUFFIX} $ACLOCAL_FLAGS || fail
else
  echo "Running aclocal${AUTOMAKE_SUFFIX} -I ${libtool_prefix}/share/aclocal $ACLOCAL_FLAGS"
  aclocal${AUTOMAKE_SUFFIX} -I ${libtool_prefix}/share/aclocal $ACLOCAL_FLAGS || fail
fi

#echo "Cleaning stuff generated by autoheader"
#rm -f config.h.in
#
#echo "Running autoheader${AUTOCONF_SUFFIX}"
#autoheader${AUTOCONF_SUFFIX} || fail

echo "Cleaning stuff generated by automake"
find . -name '*.am' -print | 
	while read file
	do # remove all .in files with a corresponding .am file
	    sed 's/\.am$/.in/g' | xargs rm -f
	done
rm -f depcomp install-sh missing mkinstalldirs
rm -f stamp-h*

echo "Running automake${AUTOMAKE_SUFFIX} --add-missing --gnu $am_opt"
automake${AUTOMAKE_SUFFIX} --add-missing --gnu $am_opt || fail

echo "Cleaning stuff generated by autoconf"
rm -f configure
rm -rf autom4te-*.cache/

echo "Running autoconf${AUTOCONF_SUFFIX}"
    autoconf${AUTOCONF_SUFFIX} || fail

echo "Finished"
) || fail

echo 
echo "$PROJECT is now ready for configuration."
