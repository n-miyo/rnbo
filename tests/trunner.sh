#!/bin/sh
#
# Copyright (c) 2011 MIYOKAWA, Nobuyoshi.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

DATADIR='data'
ICAL='.ical'
RESULT='.res'
CMD='.cmd'
TMPFILE=`mktemp -t "$0.XXXXXX"`

success=0
fail=0

err()
{
    echo $1 2>&1
    exit
}

texec()
{
    local _b=$1
    local _cmd="perl ../rnbo.pl -s - -w - --icalfile=${DATADIR}/${_b}${ICAL}"

    [ -e ${DATADIR}/${_b}${CMD} ] && read _cmd < ${DATADIR}/${_b}${CMD}
    eval ${_cmd} > ${TMPFILE} 2>/dev/null

    [ ! -e ${DATADIR}/${_b}${RESULT} ] && err "no resutlt: ${_b}"
    if cmp ${TMPFILE} ${DATADIR}/${_b}${RESULT}; then
	/bin/echo -n '.'
	success=$((success+1))
    else
	/bin/echo -n 'F'
	fail=$((fail+1))
    fi

    rm -f ${TMPFILE}
}

main()
{
    local _i _b
    for _i in ${DATADIR}/*${RESULT}; do
	_b=`basename $_i ${RESULT}`
	texec ${_b}
    done
    echo "\nResult: ${success} / $((success+fail))"
}

main

# EOF
