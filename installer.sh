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

RNBO_PL='rnbo.pl'
RHP_SH='rhp.sh'

PROGNAME=`basename $0`

err()
{
    local _status=$1; shift
    echo "error: $@" 1>&2
    exit ${_status}
}

usage()
{
    echo "usage: ${PROGNAME} hostname {install group mailaddr|uninstall}"
    exit 1
}

main()
{
    local _host _group _command
    [ ! -e ${RNBO_PL} ] && err 1 'error: ${RNBO_PL} does not exist.'
    [ ! -e ${RHP_SH} ] && err 1 'error: ${RHP_SH} does not exist.'

    _host=$1
    _command=$2
    _group=$3
    _mailaddr=$4
    if [ ${_command}x = 'install'x ]; then
	[ $# -ne 4 ] && usage
	[ ${_group}x = ''x ] && usage
	[ ${_mailaddr}x = ''x ] && usage
	scp ${RNBO_PL} ${RHP_SH} root@${_host}:/ramfs/ &&
	  ssh root@${_host} \
	      "cd /ramfs && COMMAND=${_command} MAILADDR=${_mailaddr} GROUP=${_group} sh ./${RHP_SH} && rm ${RNBO_PL} ${RHP_SH}"
    elif [ ${_command}x = 'uninstall'x ]; then
	[ $# -ne 2 ] && usage
	scp ${RHP_SH} root@${_host}:/ramfs/ &&
	  ssh root@${_host} \
	      "cd /ramfs && COMMAND=${_command} MAILADDR=${_mailaddr} sh ./${RHP_SH} && rm ${RHP_SH}"
    else
	usage
    fi
}

main "$@"

# EOF
