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
RNBO_PL_FILEPATH='/sbin/'${RNBO_PL}
POWEROFF_FILEPATH='/etc/cron.d/poweroff'
POWERON_TIMER_FILEPATH='/etc/frontview/poweron_timer'
BACKUPEXT='.rnbo'
CRONFILE='/etc/cron.d/rnbo'
DEBUG=0

run()
{
    local _s=$@; shift
    set -f
    echo ${_s}
    [ ${DEBUG} -ne 0 ] || eval ${_s}
    set +f
}

installrnbo()
{
    local _f _s

    _s=`date +'%M'`
    _f=${POWEROFF_FILEPATH}${BACKUPEXT}
    [ -e ${_f} ] && err 1 "poweroff backup file already exists: ${_f}"
    _f=${POWERON_TIMER_FILEPATH}${BACKUPEXT}
    [ -e ${_f} ] && err 1 "poweron backup file already exists: ${_f}"
    _f=${RNBO_PL_FILEPATH}
    [ -e ${_f} ] && err 1 "script file already exists: ${_f}"
    _f=${RNBO_PL}
    [ ! -e ${_f} ] && err 1 "script file does not exist: ${_f}"
    _f=${CRONFILE}
    [ -e ${_f} ] && err 1 "cron file already exists: ${_f}"

    run "[ -e ${POWEROFF_FILEPATH} ] && mv ${POWEROFF_FILEPATH} ${POWEROFF_FILEPATH}${BACKUPEXT}"
    run "touch ${POWEROFF_FILEPATH}"
    run "chown admin:admin ${POWEROFF_FILEPATH}"
    run "[ -e ${POWERON_TIMER_FILEPATH} ] && mv ${POWERON_TIMER_FILEPATH} ${POWERON_TIMER_FILEPATH}${BACKUPEXT}"
    run "touch ${POWERON_TIMER_FILEPATH}"
    run "chown admin:admin ${POWERON_TIMER_FILEPATH}"
    run "install -o admin -g admin ${RNBO_PL} ${RNBO_PL_FILEPATH}"
    run "echo \"${_s} 5,8,11,14,17 * * * root ${RNBO_PL_FILEPATH} -a ${MAILADDR} ${GROUP} &> /dev/null\" > ${CRONFILE}"
    run "chown admin:admin ${CRONFILE}"
    run "nohup ${RNBO_PL_FILEPATH} ${GROUP} &> /dev/null &"
}

uninstallrnbo()
{
    local _f

    _f=${CRONFILE}
    if [ -e ${_f} ]; then
	run "rm ${_f}"
    else
	warn "cron file does not exist: ${_f}"
    fi

    _f=${RNBO_PL_FILEPATH}
    if [ -e ${_f} ]; then
	run "rm ${_f}"
    else
	warn "script file does not exist: ${_f}"
    fi

    _f=${POWEROFF_FILEPATH}${BACKUPEXT}
    if [ -e ${_f} ]; then
	run "mv ${POWEROFF_FILEPATH}${BACKUPEXT} ${POWEROFF_FILEPATH}"
    else
	warn "poweroff backup file does not exist: ${_f}"
    fi

    _f=${POWERON_TIMER_FILEPATH}${BACKUPEXT}
    if [ -e ${_f} ]; then
	run "mv ${POWERON_TIMER_FILEPATH}${BACKUPEXT} ${POWERON_TIMER_FILEPATH}"
    else
	warn "poweron backup file does not exist: ${_f}"
    fi
}

warn()
{
    echo "warning: $@" 1>&2
}

err()
{
    local _status=$1; shift
    echo "error: $@" 1>&2
    exit ${_status}
}

main()
{
    if [ ${COMMAND}x = 'install'x ]; then
	[ ${GROUP}x = ''x ] && err 1 'should set "GROUP" variable.'
	[ ${MAILADDR}x = ''x ] && err 1 'should set "MAILADDR" variable.'
	installrnbo
    elif [ ${COMMAND}x = 'uninstall'x ]; then
	uninstallrnbo
    else
	err 1 'should set "install" or "uninstall" to "COMMAND" variable'
    fi
}

main "$@"

# EOF
