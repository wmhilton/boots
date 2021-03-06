# /usr/bin/env bash
set -e
NAME=myos
GITBASH="'/c/Program\ Files/Git/bin/bash'"
WINBASH='/c/Windows/System32/bash'
# Do a full clean and rebuild each time,
# avoiding the trouble that incremental Makefile
# builds that aren't aware of all dependencies can cause.
# @see Jonathan Blow's awesome compiler

# Clean
rm -f $NAME.iso $NAME.img $NAME.bin trace-*

# Compile c_programs
(cd c_programs;
 gcc -S -masm=intel -m16 answer.c;
# Strip out the gnu assembler directives
# since fasm errors out when it encounters them
 sed -i '/^\s*\./d' answer.s;
)

# Assemble
fasm $NAME.asm $NAME.bin
