#include "master.hpp"

namespace factor {

typedef unsigned char UBYTE;

const UBYTE UNW_FLAG_EHANDLER = 0x1;

struct UNWIND_INFO {
	UBYTE Version:3;
	UBYTE Flags:4;
	UBYTE SizeOfProlog;
	UBYTE CountOfCodes;
	UBYTE FrameRegister:4;
	UBYTE FrameOffset:4;
	ULONG ExceptionHandler;
	ULONG ExceptionData[1];
};

typedef struct seh_data {
	UNWIND_INFO unwind_info;
	RUNTIME_FUNCTION func;
	char[32] handler;
};

void factor_vm::c_to_factor_toplevel(cell quot)
{
	seh_data seh_area = (seh_data *)code->seh_area;
	cell base = code->seg->start;

	seh_data->handler[0] = 233;
	seh_data->handler[1] = 251;
	seh_data->handler[2] = 255;
	seh_data->handler[3] = 255;
	seh_data->handler[4] = 255;

	UNWIND_INFO *unwind_info = &seh_area->unwind_info;
	unwind_info->Version = 1;
	unwind_info->Flags = UNW_FLAG_EHANDLER;
	unwind_info->SizeOfProlog = 0;
	unwind_info->CountOfCodes = 0;
	unwind_info->FrameRegister = 0;
	unwind_info->FrameOffset = 0;
	unwind_info->ExceptionHandler = (DWORD)((cell)&seh_data.handler[0] - base);
	unwind_info->ExceptionData[0] = 0;

	RUNTIME_FUNCTION *func = &seh_area->func;
	func.BeginAddress = 0;
	func.EndAddress = code->seg->end - base;
	func.UnwindData = (DWORD)((cell)&unwind_info - base);

	if(!RtlAddFunctionTable(func,1,base))
		fatal_error("RtlAddFunctionTable() failed",0);

	c_to_factor(quot);

	if(!RtlDeleteFunctionTable(func))
		fatal_error("RtlDeleteFunctionTable() failed",0);
}

}
