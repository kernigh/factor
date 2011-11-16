# Copyright (C) 2011 George Koehler.
# See http://factorcode.org/license.txt for BSD license.

# Usage:
#  1. Delete generated lines from openbsd.factor
#  2. Run command
#      perl probe.pl >> openbsd.factor

use strict;
use warnings;

use Errno;
use Fcntl ();
use Socket ();

print "! AUTOMATICALLY GENERATED: Starting from this line,\n";
print "! Perl script probe.pl generated these constants.\n";

print "\n\n! fcntl constants\n";
foreach my $name (
	'O_RDONLY', 'O_WRONLY', 'O_RDWR', 'O_CREAT', 'O_EXCL',
	'O_NOCTTY', 'O_TRUNC', 'O_APPEND', 'O_NONBLOCK',
	# Would add here O_SYNC, O_SHLOCK, ...
) {
	my $glob = $Fcntl::{$name};
	if ($glob) {
		printf "CONSTANT: %-10s HEX: %04x\n", $name, $$glob;
	}
}
print "\nALIAS: O_NDELAY O_NONBLOCK\n\n";
foreach my $name (
	'F_SETFD', 'FD_CLOEXEC', 0, 'F_SETFL', 0,
	'SEEK_SET', 'SEEK_CUR', 'SEEK_END'
) {
	unless ($name) { print "\n"; next; }

	my $glob = $Fcntl::{$name};
	if ($glob) {
		print "CONSTANT: $name $$glob\n";
	}
}

# XXX Perl does not expose FD_SETSIZE. Assume 1024.
print "\n\n! for select()\nCONSTANT: FD_SETSIZE 1024\n";

print "\n\n! socket constants\n";
foreach my $name (
	'SOL_SOCKET', 0,
	'SO_REUSEADDR', 'SO_OOBINLINE', 'SO_SNDTIMEO', 'SO_RCVTIMEO', 0,
	'SOCK_STREAM', 'SOCK_DGRAM', 'SOCK_RAW', 0,
	'AF_UNSPEC', 'AF_UNIX', 'AF_INET', 'AF_INET6', 0,
	'PF_UNSPEC', 'PF_UNIX', 'PF_INET', 'PF_INET6', 0,
	'IPPROTO_TCP', 'IPPROTO_UDP',
) {
	unless ($name) { print "\n"; next; }

	if ($name =~ /^PF_/) {
		# PF_FROG is always an alias of AF_FROG.
		my $af = $name;
		$af =~ s/^PF_/AF_/;
		if($Socket::{$af}) { print "ALIAS: $name $af\n"; }
	}
	else {
		my $glob = $Socket::{$name};
		if ($glob) {
			print "CONSTANT: $name ";
			if ($$glob < 16 || $name =~ /^(AF|IPPROTO)_/) {
				print "$$glob\n";
			}
			else { printf "HEX: %x\n", $$glob; }
		}
	}
}

# XXX Perl does not expose AI_PASSIVE. Assume 1.
print "\n\nCONSTANT: AI_PASSIVE 1\n";

print "\n\n! errno constants\n";
my %errhash;
foreach my $name (keys %!) {
	# If $name is "EINTR", then call subroutine Errno::EINTR.
	my $number = &{$Errno::{$name}};
	push @{$errhash{$number}}, $name;
}
foreach my $number (sort {$a <=> $b} keys %errhash) {
	# Sort other names before EWOULDBLOCK, ELAST.
	my @names = sort {
		if ($b =~ /^(EWOULDBLOCK|ELAST)$/) { -1 }
		elsif ($a =~ /^(EWOULDBLOCK|ELAST)$/) { 1 }
		else { $a cmp $b }
	} @{$errhash{$number}};
	my $n1 = shift @names;
	printf "CONSTANT: $n1 $number\n";
	foreach my $n2 (@names) { print "ALIAS: $n2 $n1\n"; }
}
