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

set -x

unset CC CXX AR

# Install xstatic.
# sudo apt-get install bison gcc g++ make build-essential
type -p xstatic || exit "$?"
type -p gcc || exit "$?"
type -p ld || exit "$?"
type -p ranlib || exit "$?"
type -p ar || exit "$?"
type -p make || exit "$?"
type -p g++ || exit "$?"  # Needed for gold.
type -p bison || exit "$?"  # Needed for gold.
type -p strip || exit "$?"  # Needed for gold.
type -p 7z || exit "$?"
type -p perl || exit "$?"

OFLAGS="${OFLAGS:--Os}"

if false; then
  wget -O binutils-2.24.tar.bz2 http://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2 || exit "$?"
  wget -O binutils_2.24-5ubuntu14.1.diff.gz http://archive.ubuntu.com/ubuntu/pool/main/b/binutils/binutils_2.24-5ubuntu14.1.diff.gz || exit "$?"
fi

function build() {
  local OFLAGS="${1:--Os}"

  if true; then
    test -f binutils-2.24.tar.bz2 || exit "$?"
    test -f binutils_2.24-5ubuntu14.1.diff.gz || exit "$?"
    rm -rf binutils-2.24 || exit "$?"
    rm -rf pts-binutils-static-bin-*-2.24 || exit "$?"
    tar xjf binutils-2.24.tar.bz2 || exit "$?"
    gzip -cd binutils_2.24-5ubuntu14.1.diff.gz | patch -p0 || exit "$?"
    (cd binutils-2.24 && while read F; do test "${F#\#}" = "$F" || continue; test "$F" || continue; patch -p1 <debian/patches/"$F" || exit "$?"; done <debian/patches/series) || exit "$?"
    # `echo $(HOST_CONFIGARGS)' removes the single quotes, which makes
    # gold/configure fail if --with-pkgversion contains a dash. We fix that
    # by removing the echo.
    test -f binutils-2.24/Makefile.in || exit "$?"  # perl doesn't fail in this case.
    perl -pi~ -e's@\$\$\(echo \$\(HOST_CONFIGARGS\).*?\)@\$\(HOST_CONFIGARGS\)@g' binutils-2.24/Makefile.in || exit "$?"
  fi

  if true; then
    (cd binutils-2.24 && mkdir builddir-static) || exit "$?"
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
            --with-sysroot \
            --enable-gold \
            --enable-targets=i386-linux-gnu,x86_64-linux-gnu,x86_64-linux-gnux32,x86_64-pep \
    ) || exit "$?"
    (make -C binutils-2.24/builddir-static configure-bfd) || exit "$?"
    (make -C binutils-2.24/builddir-static configure-ld) || exit "$?"
    (make -C binutils-2.24/builddir-static/libiberty CCLD='$(CC) -all-static') || exit "$?"
    (make -C binutils-2.24/builddir-static/bfd CCLD='$(CC) -all-static' SUBDIRS=) || exit "$?"
    (make -C binutils-2.24/builddir-static/ld CCLD='$(CC) -all-static' INFO_DEPS=) || exit "$?"
    ls -ld binutils-2.24/builddir-static/ld/ld-new || exit "$?"

    (make -C binutils-2.24/builddir-static configure-gold) || exit "$?"
    (make -C binutils-2.24/builddir-static/gold CCLD='$(CC) -all-static') || exit "$?"
    strip  binutils-2.24/builddir-static/gold/dwp || exit "$?"
    strip  binutils-2.24/builddir-static/gold/ld-new || exit "$?"
    ls -ld binutils-2.24/builddir-static/gold/ld-new || exit "$?"

    (make -C binutils-2.24/builddir-static configure-opcodes) || exit "$?"
    (make -C binutils-2.24/builddir-static/opcodes CCLD='$(CC) -all-static') || exit "$?"
    (make -C binutils-2.24/builddir-static configure-binutils)  # E.g. objcopy.
    (make -C binutils-2.24/builddir-static/binutils CCLD='$(CC) -all-static' SUBDIRS=) || exit "$?"
    ls -ld binutils-2.24/builddir-static/binutils/{addr2line,ar,elfedit,objcopy,objdump,ranlib,readelf,size,strings} || exit "$?"

    (make -C binutils-2.24/builddir-static configure-gas) || exit "$?"
    (make -C binutils-2.24/builddir-static/gas CCLD='$(CC) -all-static') || exit "$?"

    (make -C binutils-2.24/builddir-static configure-gprof) || exit "$?"
    (make -C binutils-2.24/builddir-static/gprof CCLD='$(CC) -all-static' INFO_DEPS=) || exit "$?"
  fi

  if true; then
    rm -rf binutils-2.24/output || exit "$?"
    mkdir  binutils-2.24/output || exit "$?"
    function strip_and_copy() {
      cp -a builddir-static/"$1" output/"$2" || exit "$?"
      strip --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id -s output/"$2" || exit "$?"
      chmod 755 output/"$2" || exit "$?"
    }
    (cd binutils-2.24 && strip_and_copy ld/ld-new ld.bfd) || exit "$?"
    ln -s ld.bfd  binutils-2.24/output/ld || exit "$?"
    (cd binutils-2.24 && strip_and_copy gold/ld-new ld.gold) || exit "$?"
    ln -s ld.gold binutils-2.24/output/gold || exit "$?"
    (cd binutils-2.24 && strip_and_copy gold/dwp dwp) || exit "$?"
    (cd binutils-2.24 && strip_and_copy binutils/addr2line addr2line) || exit "$?"
    (cd binutils-2.24 && strip_and_copy binutils/ar ar) || exit "$?"
    (cd binutils-2.24 && strip_and_copy binutils/elfedit elfedit) || exit "$?"
    (cd binutils-2.24 && strip_and_copy binutils/objcopy objcopy) || exit "$?"
    ln -s objcopy binutils-2.24/output/strip || exit "$?"  # Decides by argv[0] whether strip or objcopy.
    (cd binutils-2.24 && strip_and_copy binutils/objdump objdump) || exit "$?"
    (cd binutils-2.24 && strip_and_copy binutils/ranlib ranlib) || exit "$?"
    (cd binutils-2.24 && strip_and_copy binutils/readelf readelf) || exit "$?"
    (cd binutils-2.24 && strip_and_copy binutils/size size) || exit "$?"
    (cd binutils-2.24 && strip_and_copy binutils/strings strings) || exit "$?"
    (cd binutils-2.24 && strip_and_copy binutils/nm-new nm) || exit "$?"
    (cd binutils-2.24 && strip_and_copy binutils/cxxfilt c++filt) || exit "$?"
    (cd binutils-2.24 && strip_and_copy gas/as-new as) || exit "$?"
    (cd binutils-2.24 && strip_and_copy gprof/gprof gprof) || exit "$?"
    ls -l binutils-2.24/output || exit "$?"
  fi
}

test "${0%/*}" = "$0" || cd "${0%/*}" || exit "$?"
test -f binutils-2.24.tar.bz2 || exit "$?"  # We are in the right directory.
for OFLAGS in -Os -O2; do
  OSUFFIX="${OFLAGS#-}"
  OSUFFIX="$(echo "$OSUFFIX" | tr A-Z a-z)"
  test "$OSUFFIX" || exit "$?"
  if ! test -d ../pts-binutils-static-bin-"$OSUFFIX"-2.24; then
    mkdir -p binutils-2.24 || exit "$?"
    build "$OFLAGS" || exit "$?"
    mv binutils-2.24/output pts-binutils-static-bin-"$OSUFFIX"-2.24 || exit "$?"
    rm -f pts-binutils-static-bin-"$OSUFFIX"-2.24.sfx.7z || exit "$?"
    time 7z a -sfx../../../../../../../../../../../../../../../../../../../../../../../../"$PWD"/../tiny7zx \
        -t7z -mx=7 -ms=32m -ms=on \
        ../pts-binutils-static-bin-"$OSUFFIX"-2.24.sfx.7z pts-binutils-static-bin-"$OSUFFIX"-2.24 || exit "$?"
    chmod 755 ../pts-binutils-static-bin-"$OSUFFIX"-2.24.sfx.7z || exit "$?"
    ls -ld    ../pts-binutils-static-bin-"$OSUFFIX"-2.24.sfx.7z || exit "$?"
    mv pts-binutils-static-bin-"$OSUFFIX"-2.24 ../ || exit "$?"
  fi
done
rm -rf binutils-2.24 || exit "$?"

: compile.sh OK.

fi; exit
