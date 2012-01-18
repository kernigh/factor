#include "master.hpp"

int main(int argc, char **argv)
{
#if defined(__OpenBSD__)
	factor::pass_argv0(argv[0]);
#endif
	factor::init_globals();
	factor::start_standalone_factor(argc,argv);
	return 0;
}
