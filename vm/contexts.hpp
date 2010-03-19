namespace factor
{

static const cell context_object_count = 10;

enum context_object {
	OBJ_NAMESTACK,
	OBJ_CATCHSTACK,
};

struct context {

	// First 4 fields accessed directly by compiler. See basis/vm/vm.factor

	/* C stack pointer on entry */
	stack_frame *callstack_top;
	stack_frame *callstack_bottom;

	/* current datastack top pointer */
	cell datastack;

	/* current retain stack top pointer */
	cell retainstack;

	/* context-specific special objects, accessed by context-object and
	set-context-object primitives */
	cell context_objects[context_object_count];

	segment *datastack_region;
	segment *retainstack_region;
	segment *callstack_region;

	context *next;

	context(cell datastack_size, cell retainstack_size, cell callstack_size);
	~context();

	void reset_datastack();
	void reset_retainstack();
	void reset_callstack();
	void reset_context_objects();

	cell peek()
	{
		return *(cell *)datastack;
	}

	void replace(cell tagged)
	{
		*(cell *)datastack = tagged;
	}

	cell pop()
	{
		cell value = peek();
		datastack -= sizeof(cell);
		return value;
	}

	void push(cell tagged)
	{
		datastack += sizeof(cell);
		replace(tagged);
	}

	static const cell stack_reserved = (64 * sizeof(cell));

	void fix_stacks()
	{
		if(datastack + sizeof(cell) < datastack_region->start
			|| datastack + stack_reserved >= datastack_region->end)
			reset_datastack();

		if(retainstack + sizeof(cell) < retainstack_region->start
			|| retainstack + stack_reserved >= retainstack_region->end)
			reset_retainstack();
	}
};

VM_C_API void nest_context(factor_vm *vm);
VM_C_API void unnest_context(factor_vm *vm);

}
