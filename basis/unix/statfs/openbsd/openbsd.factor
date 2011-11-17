! Copyright (C) 2008 Doug Coleman.
! Copyright (C) 2011 George Koehler.
! See http://factorcode.org/license.txt for BSD license.
USING: alien.c-types alien.syntax unix.types classes.struct
unix.stat ;
IN: unix.statfs.openbsd

CONSTANT: MFSNAMELEN 16
CONSTANT: MNAMELEN 90

STRUCT: statfs
    { f_flags u_int32_t }
    { f_bsize u_int32_t }
    { f_iosize u_int32_t }
    { f_blocks u_int64_t }
    { f_bfree u_int64_t }
    { f_bavail int64_t }
    { f_files u_int64_t }
    { f_ffree u_int64_t }
    { f_favail int64_t }
    { f_syncwrites u_int64_t }
    { f_syncreads u_int64_t }
    { f_asyncwrites u_int64_t }
    { f_asyncreads u_int64_t }
    { f_fsid fsid_t }
    { f_namemax u_int32_t }
    { f_owner uid_t }
    { f_ctime u_int32_t }
    { f_spare u_int32_t[3] }
    { f_fstypename { char MFSNAMELEN } }
    { f_mntonname { char MNAMELEN } }
    { f_mntfromname { char MNAMELEN } }
    { mount_info char[160] } ;

FUNCTION: int statfs ( c-string path, statfs* buf ) ;

! Flags from <sys/mount.h> for getfsstat(2) and getmntinfo(3).
! The header also defines MNT_LAZY, but getfsstat(2) manual
! omits it. (Perhaps MNT_LAZY is internal to kernel?)
CONSTANT: MNT_WAIT    1   ! synchronously wait for I/O to complete
CONSTANT: MNT_NOWAIT  2   ! start all I/O, but do not wait for it

FUNCTION: int getfsstat ( statfs* buf, int bufsize, int flags ) ;
FUNCTION: int getmntinfo ( statfs **mntbufp, int flags ) ;
