USING: alien.syntax alien.c-types ;
IN: unix.types

! OpenBSD: Most types are from <sys/_types.h> and <sys/types.h>.
! Types from <machine/_types.h> can differ between platforms,
! but they rarely do so.

TYPEDEF: __int32_t dev_t
TYPEDEF: __uint32_t gid_t
TYPEDEF: __uint32_t mode_t
TYPEDEF: __uint32_t ino_t
TYPEDEF: __uint32_t nlink_t
TYPEDEF: longlong off_t         ! from <machine/_types.h>
TYPEDEF: __int32_t pid_t
TYPEDEF: long ssize_t           ! from <machine/_types.h>
TYPEDEF: int time_t             ! from <machine/_types.h>
TYPEDEF: __uint32_t uid_t
