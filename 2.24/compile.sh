#! /bin/bash --
# by pts@fazekas.hu at Sun Feb 12 11:24:27 CET 2017
#
# How to run:
#
#   $ git clone https://github.com/pts/pts-binutils-static
#   $ cd pts-binutils-static
#   $ 2.24/compile.sh
#   $ ls -ld *-2.24*.7z
#    

if true; then  # Make it easier to edit the script while it is running.

set -ex

unset CC CXX AR

# Install xstatic.
# sudo apt-get install bison gcc g++ make build-essential
type -p xstatic
type -p gcc
type -p ld
type -p ranlib
type -p ar
type -p make
type -p g++  # Needed for gold.
type -p bison  # Needed for gold.
type -p strip  # Needed for gold.
type -p 7z

OFLAGS="${OFLAGS:--Os}"

if false; then
  wget -O binutils-2.24.tar.bz2 http://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2
  wget -O binutils_2.24-5ubuntu14.1.diff.gz http://archive.ubuntu.com/ubuntu/pool/main/b/binutils/binutils_2.24-5ubuntu14.1.diff.gz
fi

function build() {
  local OFLAGS="${1:--Os}"

  if true; then
    test -f binutils-2.24.tar.bz2
    test -f binutils_2.24-5ubuntu14.1.diff.gz
    rm -rf binutils-2.24
    rm -rf pts-binutils-static-bin-*-2.24
    tar xjf binutils-2.24.tar.bz2
    gzip -cd binutils_2.24-5ubuntu14.1.diff.gz | patch -p0
    (cd binutils-2.24 && while read F; do test "${F#\#}" = "$F" || continue; test "$F" || continue; patch -p1 <debian/patches/"$F" || exit "$?"; done <debian/patches/series)
    #echo 'info all: ;' >binutils-2.24/bfd/doc/Makefile.in
  fi

  if true; then
    (cd binutils-2.24 && mkdir builddir-static)
    # If you make --enable-targets= empty, then all ELF targets will be enabled
    #   for gold, but only some for ld.
    (cd binutils-2.24/builddir-static &&
        env AR="ar" CC="xstatic gcc" CXX="xstatic g++" CFLAGS="-g0 $OFLAGS -s" \
        ../configure \
            --build=i386-linux-gnu \
            --host=i386-linux-gnu \
            --with-pkgversion="GNU Binutils $OFLAGS for xtiny" \
            --disable-nls \
            --disable-shared \
            --disable-plugins \
            --enable-gold \
            --enable-targets=i386-linux-gnu,x86_64-linux-gnu,x86_64-linux-gnux32,x86_64-pep \
    )
    (make -C binutils-2.24/builddir-static configure-bfd)
    (make -C binutils-2.24/builddir-static configure-ld)
    (make -C binutils-2.24/builddir-static/libiberty CCLD='$(CC) -all-static')
    (make -C binutils-2.24/builddir-static/bfd CCLD='$(CC) -all-static' SUBDIRS=)
    (make -C binutils-2.24/builddir-static/ld CCLD='$(CC) -all-static' INFO_DEPS=)
    ls -ld binutils-2.24/builddir-static/ld/ld-new

    (make -C binutils-2.24/builddir-static configure-gold)
    (make -C binutils-2.24/builddir-static/gold CCLD='$(CC) -all-static')
    strip  binutils-2.24/builddir-static/gold/dwp
    strip  binutils-2.24/builddir-static/gold/ld-new
    ls -ld binutils-2.24/builddir-static/gold/ld-new

    (make -C binutils-2.24/builddir-static configure-opcodes)
    (make -C binutils-2.24/builddir-static/opcodes CCLD='$(CC) -all-static')
    (make -C binutils-2.24/builddir-static configure-binutils)  # E.g. objcopy.
    (make -C binutils-2.24/builddir-static/binutils CCLD='$(CC) -all-static' SUBDIRS=)
    ls -ld binutils-2.24/builddir-static/{addr2line,ar,elfedit,objcopy,objdump,ranlib,readelf,size,strings}

    (make -C binutils-2.24/builddir-static configure-gas)
    (make -C binutils-2.24/builddir-static/gas CCLD='$(CC) -all-static')

    (make -C binutils-2.24/builddir-static configure-gprof)
    (make -C binutils-2.24/builddir-static/gprof CCLD='$(CC) -all-static' INFO_DEPS=)
  fi

  if true; then
    rm -rf binutils-2.24/output
    mkdir  binutils-2.24/output
    function strip_and_copy() {
      cp -a builddir-static/"$1" output/"$2"
      strip --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id -s output/"$2"
      chmod 755 output/"$2"
    }
    (cd binutils-2.24 && strip_and_copy ld/ld-new ld.bfd)
    ln -s ld.bfd  binutils-2.24/output/ld
    (cd binutils-2.24 && strip_and_copy gold/ld-new ld.gold)
    ln -s ld.gold binutils-2.24/output/gold
    (cd binutils-2.24 && strip_and_copy gold/dwp dwp)
    (cd binutils-2.24 && strip_and_copy binutils/addr2line addr2line)
    (cd binutils-2.24 && strip_and_copy binutils/ar ar)
    (cd binutils-2.24 && strip_and_copy binutils/elfedit elfedit)
    (cd binutils-2.24 && strip_and_copy binutils/objcopy objcopy)
    ln -s objcopy binutils-2.24/output/strip  # Decides by argv[0] whether strip or objcopy.
    (cd binutils-2.24 && strip_and_copy binutils/objdump objdump)
    (cd binutils-2.24 && strip_and_copy binutils/ranlib ranlib)
    (cd binutils-2.24 && strip_and_copy binutils/readelf readelf)
    (cd binutils-2.24 && strip_and_copy binutils/size size)
    (cd binutils-2.24 && strip_and_copy binutils/strings strings)
    (cd binutils-2.24 && strip_and_copy binutils/nm-new nm)
    (cd binutils-2.24 && strip_and_copy binutils/cxxfilt c++filt)
    (cd binutils-2.24 && strip_and_copy gas/as-new as)
    (cd binutils-2.24 && strip_and_copy gprof/gprof gprof)
    ls -l binutils-2.24/output
  fi
}

test "${0%/*}" = "$0" || cd "${0%/*}"
test -f binutils-2.24.tar.bz2  # We are in the right directory.
for OFLAGS in -Os -O2; do
  OSUFFIX="${OFLAGS#-}"
  OSUFFIX="$(echo "$OSUFFIX" | tr A-Z a-z)"
  test "$OSUFFIX"
  if ! test -d ../pts-binutils-static-bin-"$OSUFFIX"-2.24; then
    build "$OFLAGS" || exit "$?"
    mv binutils-2.24/output pts-binutils-static-bin-"$OSUFFIX"-2.24
    #rm -rf binutils-2.24
    rm -f pts-binutils-static-bin-"$OSUFFIX"-2.24.sfx.7z
    time 7z a -sfx../../../../../../../../../../../../../../../../../../../../../../../../"$PWD"/../tiny7zx \
        -t7z -mx=7 -ms=32m -ms=on \
        ../pts-binutils-static-bin-"$OSUFFIX"-2.24.sfx.7z pts-binutils-static-bin-"$OSUFFIX"-2.24
    chmod 755 ../pts-binutils-static-bin-"$OSUFFIX"-2.24.sfx.7z
    ls -ld    ../pts-binutils-static-bin-"$OSUFFIX"-2.24.sfx.7z
    mv pts-binutils-static-bin-"$OSUFFIX"-2.24 ../
  fi
done
rm -rf binutils-2.24

: compile.sh OK.

fi; exit
