pts-binutils-static: binutils for Linux i386, statically linked

pts-binutils-static is a set of tools for compiling GNU Binutils 2.24
(including ld, gold, as, strip, objdump and other) and some other versions
for Linux i386, statically linked. The tools run on a Linux i386 or amd64
system. The target architectures supported by the tools are i386 and amd64
ELF.

See */compile.sh for instructions how to run.

See https://github.com/pts/pts-binutils-static/releases for binary outputs.

Binary output files are named like:
pts-binutils-static-bin-${OFLAGS}-${VERSION}.sfx.7z

OFLAGS indicates compiler optimization flags: o2 means -O2 and os means -Os.

VERSION indicates the Binutils version.

To install, run thee binary output file on a Linux i386 or amd64 system.
It's a self-extracting archive: it creates a subdirectory and extracts tools
there.

__END__
