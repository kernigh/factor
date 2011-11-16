#include "master.hpp"

namespace factor
{

const char *vm_executable_path()
{
	/*
	 * kvm_getprocs(3) can determine the executable filename, but
	 * not the directory that it was in.
	 *
	 * SBCL bsd-os.c checks if /proc/curproc/file exists, but most
	 * OpenBSD systems never mount /proc.
	 */
	return NULL;
}

}
