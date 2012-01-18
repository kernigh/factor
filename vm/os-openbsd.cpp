#include "master.hpp"

namespace factor
{

char *vm_saved_path;

void pass_argv0(char *argv0)
{
	vm_saved_path = realpath(argv0, NULL);
}

/* Use argv[0] to find the executable path. */
const char *vm_executable_path()
{
	/* Caller will free(), so we must allocate. */
	if (vm_saved_path)
		return safe_strdup(vm_saved_path);
	else
		return NULL;
}

}
