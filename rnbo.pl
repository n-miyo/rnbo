#!/usr/bin/env perl
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

use strict;
use warnings;
use HTTP::Date;
use Getopt::Long;

my $VERSION = '1.0.0';

my $DEFAULT_COMMAND = '/frontview/bin/autopoweroff &> /dev/null';
my $DEFAULT_DIFF = (60 * 5);
my $DEFAULT_SHUTDOWN_LIST = '/etc/cron.d/poweroff';
my $DEFAULT_TIMEOUT = 30;
my $DEFAULT_WAKEUP_LIST = '/etc/frontview/poweron_timer';

my $ONEWEEK = (60 * 60 * 24 * 7);
my $MAXTRYCOUNT = 3;
my $FETCHERRORSLEEP = 30;
my $ICALLIST_PREFIX = 'http://www.google.com/calendar/ical/';
my @ICALLIST = (
    'dummy',
    'creco.net_j54hnj1scpsa0oasqma0v0n4h0%40group',
    'creco.net_r95i3r66pe00a0al0ebcgiovno%40group',
    'creco.net_q9gq2bnptmpaq30f9brd90stms%40group',
    'creco.net_eigugc9emgdjj3vaphue418d74%40group',
    'creco.net_h5elta8oltnk8gev750mubpbok%40group',
    );
my $ICALLIST_SUFFIX = '.calendar.google.com/public/basic.ics';

my @bolist = ();
my $progname = `basename $0`; chop($progname);
my $icaltmpfile = '';
my %conf = (
    'adminaddr' => '',
    'command' => $DEFAULT_COMMAND,
    'diff' => $DEFAULT_DIFF,
    'shutdown' => $DEFAULT_SHUTDOWN_LIST,
    'timeout' => $DEFAULT_TIMEOUT,
    'wakeup' => $DEFAULT_WAKEUP_LIST,
    #
    'group' => 0,
    'subgroup' => '',
    #
    'version' => 0,
    'help' => 0,
    'debug' => 0,
    'keep' => 0,
    'icalfile' => '',
    'now' => time(),
);

sub prepare() {
    my $r;

    Getopt::Long::Configure('ignorecase_always');
    $r = GetOptions(
        \%conf,
        'adminaddr|a=s',         # admin mail address.
        'command=s',             # command when shutdown time arrves.
        'diff|d=i',              # diff from shutdown/wakeup time.
        'shutdown|poweroff|s=s', # poweroff config filename.
        'timeout|t=i',           # timeout for fetching ICAL file.
        'wakeup|poweron|w=s',    # poweron config filname.
        'help|h',                # help.
        'version|v',             # version.
        'debug',                 # ...
        'keep',                  # keep fetched ICAL file.
        'icalfile=s',            # specify ICAL file just for debug.
        'now=i',                 # pseudo 'now'.
        );

    if ($conf{'version'} == 1) {
	print STDERR "version: ${VERSION}\n";
	usage();
	exit 1;
    }

    if (!$r || @ARGV != 1 || $conf{'help'} == 1) {
        debug();
        usage();
        exit 1;
    }

    ($conf{'group'}, $conf{'subgroup'}) = split(//, $ARGV[0]);
    $conf{'subgroup'} = lc($conf{'subgroup'});
    if (($conf{'group'} < 1 || $conf{'group'} > 5)
	|| ($conf{'subgroup'} ne '' && $conf{'subgroup'} !~ /[a-e]/)) {
	print STDERR "error: invalid group/subgroup.\n";
        usage();
        exit 1;
    }
    if ($conf{'icalfile'}) {
	$icaltmpfile = $conf{'icalfile'};
	$conf{'keep'} = 1;
    } else {
	$icaltmpfile = `mktemp -t "$progname.XXXXXX"`;
	chop($icaltmpfile);
    }
}

sub fetch_icalfile() {
    my $icalurl =
        "${ICALLIST_PREFIX}${ICALLIST[$conf{'group'}]}${ICALLIST_SUFFIX}";

    for (my $i = 0; $i < $MAXTRYCOUNT; $i++) {
	if ($conf{'icalfile'} eq '') {
	    `wget -T${conf{'timeout'}} -O${icaltmpfile} ${icalurl} 2> /dev/null`;
	}
	last if (! -z ${icaltmpfile});
	sleep($FETCHERRORSLEEP);
    }
    if (-z ${icaltmpfile}) {
	report_error("could not fetch icalfile: ${icalurl}.");
    }
}

sub store_schedule() {
    my $lastl = '';
    my $s = '';
    my $e = '';
    my $subg = 'abcde';
    my $cancel = 0;
    my $icalh;

    if (!open($icalh, $icaltmpfile)) {
        report_error("could not open icalfile: ${icaltmpfile}.");
    }
    if (<$icalh> !~ /^BEGIN:VCALENDAR/) {
        report_error('invalid ICAL file format.');
    }

    while (<$icalh>) {
        $lastl = $_;
        if (/BEGIN:VEVENT/../END:VEVENT/) {
            $cancel = 1 if /^SUMMARY:.*(CANCELED|OCCASIONAL)/;
            $subg = lc($1)
                if /^SUMMARY:\x{ef}\x{bc}\x{88}([A-E]+).*\x{ef}\x{bc}\x{89}/;
            $s = parse_date($1) if /DTSTART:([0-9TZ]+)/;
            $e = parse_date($1) if /DTEND:([0-9TZ]+)/;
            if (/END:VEVENT/) {
                if (!$cancel
                    && ($conf{'subgroup'} eq ''
                        || index($subg, $conf{'subgroup'}) >= 0)
                    && defined($s) && defined($e)
                    && $conf{'now'} <= $s
                    && $s < $conf{'now'} + $ONEWEEK) {
                    store_boitem($s, $e);
                    print STDERR 'STORED: ' if $conf{'debug'};
                } else {
                    print STDERR 'IGNORE: ' if $conf{'debug'};
                }
                print STDERR
                    HTTP::Date::time2iso($s) .
                    ' -> ' .
                    HTTP::Date::time2iso($e) .
                    " : cancel: $cancel : $conf{group}/$subg\n"
                    if $conf{'debug'};
                $s = $e = $subg = 'abcde';
                $cancel = 0;
            }
        }
    }
    close($icalh);
    if ($lastl !~ /^END:VCALENDAR/) {
        report_error('invalid ICAL file format.');
    }
}

sub parse_date {
    my $esec = HTTP::Date::str2time($_[0]);
#    print 'PARSE_DATE: $_[0] -> ' . HTTP::Date::time2iso($esec) . "\n"
#       if $conf{'debug'};
    return $esec;
}

sub store_boitem {
    my $s = $_[0] - $conf{'diff'};
    my $e = $_[1] + $conf{'diff'};
    my $wday = (localtime($s))[6];

    if ($wday != (localtime($e))[6]) {
        report_error('error: BEGIN/END date is invalid.');
    }

    $bolist[$wday] ||= {'start' => $s, 'end' => $e};
    $bolist[$wday]{'start'} = $s if $s < $bolist[$wday]{'start'};
    $bolist[$wday]{'end'} = $e if $e > $bolist[$wday]{'end'};
}

sub output {
    output_poff();
    output_pon();
}

sub output_poff {
    my $ofileh = *STDOUT;
    if ($conf{'shutdown'} ne '-') {
        if (!open($ofileh, '>', $conf{'shutdown'})) {
            report_error("could not open shutdown file: $conf{'shutdown'}.");
        }
    }
    for (my $i = 0; $i < $#bolist+1; $i++) {
        my $x = $bolist[$i];
        next unless defined($x);
        my ($min, $hour, $mday, $mon) = (localtime($x->{'start'}))[1..4];
        printf $ofileh ("%02d %02d %02d %02d %2d root  $conf{'command'}\n",
                        $min, $hour, $mday, $mon+1, $i);
    }
    close($ofileh) if $conf{'shutdown'} ne '-';
}

sub output_pon {
    my @wstr = ('sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat');
    my $ofileh = *STDOUT;
    if ($conf{'wakeup'} ne '-') {
        if (!open($ofileh, '>', $conf{'wakeup'})) {
            report_error("could not open wakeup file: $conf{wakeup}.");
        }
    }
    for (my $i = 0; $i < $#bolist+1; $i++) {
        my $x = $bolist[$i];
        next unless defined($x);
        my ($min, $hour) = (localtime($x->{'end'}))[1..2];
        printf $ofileh ("%s %02d:%02d\n", $wstr[$i], $hour, $min);
    }
    close($ofileh) if $conf{'wakeup'} ne '-';
}

sub wrapup {
    if ($conf{'keep'}) {
        print STDERR "undelted ICAL file: ${icaltmpfile}\n";
    } else {
        unlink $icaltmpfile;
    }
}

sub debug {
    if (!$conf{'debug'}) {
        return;
    }
    print <<"EOM";
DEBUG:
  ADMINADDR: [$conf{'adminaddr'}]
  COMMAND:   [$conf{'command'}]
  DIFF:      [$conf{'diff'}]
  SHUTDOWN:  [$conf{'shutdown'}]
  TIMEOUT:   [$conf{'timeout'}]
  WAKEUP:    [$conf{'wakeup'}]
  GROUP:     [$conf{'group'}]
  SUBGROUP:  [$conf{'subgroup'}]
  DEBUG:     [$conf{'debug'}]
  KEEP:      [$conf{'keep'}]
  ICALFILE:  [$conf{'icalfile'}]
  ICALTMP:   $icaltmpfile
  NOW:       [$conf{'now'}]
EOM
}

sub usage {
    print STDERR <<"EOM";
usage: $0 [OPTION] group
  -a <ADMINADDR>    mailaddress for administrator.
  -c <COMMAND>      command when shutdown time arrives.
  -d <DIFF>         differentiate second from shutdown/wakeup time.
  -s <SHUTDOWNFILE> filename for shutdown(cron format).
  -t <TIMEOUT>      timeout second for fetchiing ICAL file.
  -w <WAKEUPFILE>   filename for wakeup(ReadyNAS original format).
EOM
};

sub report_error {
    my $body = $_[0];
    if ($conf{'adminaddr'}) {
        my $sub = "${progname}: Error report";
        `echo $body | mail -s \"$sub\" $conf{'adminaddr'}`;
    } else {
        print STDERR $body, "\n";
    }
    exit 1;                     # XXX
}

sub main() {
    prepare();
    debug();
    fetch_icalfile();
    store_schedule();
    output();
    wrapup();
};

main();

# EOF
