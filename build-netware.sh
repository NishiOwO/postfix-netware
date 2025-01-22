#!/bin/sh
LITE=""
export NOVELLNDK=/usr/novell/libc
export CC=owcc
export CFLAGS="-bnetware_libc$LITE -I$NOVELLNDK/include -I. -I`pwd`/include -I`pwd`/netware-include -D_POSIX_SOURCE=1 -DEXPERIMENTAL"
export LDFLAGS="-bnetware_libc$LITE"
gmake CC="$CC" CFLAGS="$CFLAGS -DNETWARE"
