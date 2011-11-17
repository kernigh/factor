! Copyright (C) 2008 Doug Coleman.
! Copyright (C) 2011 George Koehler.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien.c-types alien.data alien.strings arrays
calendar.unix classes.struct combinators grouping
io.encodings.utf8 io.files io.files.info io.files.info.unix
io.files.unix kernel math sequences specialized-arrays
system unix unix.statfs.openbsd ;
SPECIALIZED-ARRAY: uint
SPECIALIZED-ARRAY: statfs
IN: io.files.info.unix.openbsd

! This file began as a copy of macosx.factor, but changes
! its tuples to match the OpenBSD structures.

! No slot for birth-time: OpenBSD struct stat has a field named
! __st_birthtimespec, but it seems unused. Manual for stat(2)
! omits that field.
TUPLE: openbsd-file-info < unix-file-info flags gen ;

M: openbsd new-file-info ( -- class ) openbsd-file-info new ;

M: openbsd stat>file-info ( stat -- file-info )
    [ call-next-method ] keep
    {
        [ st_flags>> >>flags ]
        [ st_gen>> >>gen ]
    } cleave ;

TUPLE: openbsd-file-system-info < unix-file-system-info
sync-writes sync-reads async-writes async-reads owner
mount-time ;

M: openbsd file-systems ( -- array )
    f void* <ref> dup MNT_WAIT getmntinfo dup io-error
    [ void* deref ] dip \ statfs <c-direct-array>
    [ f_mntonname>> utf8 alien>string file-system-info ] { } map-as ;

M: openbsd new-file-system-info openbsd-file-system-info new ;

! OpenBSD statvfs(3) takes all info from statfs(2): therefore
! we forget statvfs(3) and only call statfs(2).

M: openbsd file-system-statfs ( normalized-path -- statfs )
    \ statfs <struct> [ statfs io-error ] keep ;

M: openbsd statfs>file-system-info ( file-system-info byte-array -- file-system-info' )
    {
        [ f_flags>> >>flags ]
        #! FIXME Why use fragment size as preferred-block-size?
        #! This matches Linux and Mac OS X, but seems wrong.
        [ f_bsize>> >>preferred-block-size ]    ! fragment size
        [ f_iosize>> >>block-size ]        ! optimal block size
        [ f_blocks>> >>blocks ]
        [ f_bfree>> >>blocks-free ]
        [ f_bavail>> >>blocks-available ]
        [ f_files>> >>files ]
        [ f_ffree>> >>files-free ]
        [ f_favail>> >>files-available ]
        [ f_fsid>> >>id ]
        [ f_namemax>> >>name-max ]
        [ f_owner>> >>owner ]
        [ f_ctime>> >>mount-time ]
        [ f_fstypename>> utf8 alien>string >>type ]
        [ f_mntonname>> utf8 alien>string >>mount-point ]
        [ f_mntfromname>> utf8 alien>string >>device-name ]
    } cleave ;
