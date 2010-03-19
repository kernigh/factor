#include "master.hpp"

namespace factor
{

context::context(cell datastack_size, cell retainstack_size, cell callstack_size) :
	callstack_top(NULL),
	callstack_bottom(NULL),
	datastack(0),
	retainstack(0),
	datastack_region(new segment(datastack_size,false)),
	retainstack_region(new segment(retainstack_size,false)),
	callstack_region(new segment(callstack_size,false)),
	next(NULL)
{
	reset_datastack();
	reset_retainstack();
	reset_context_objects();
}

context::~context()
{
	delete datastack_region;
	delete retainstack_region;
	delete callstack_region;
}

void context::reset_datastack()
{
	datastack = datastack_region->start - sizeof(cell);
}

void context::reset_retainstack()
{
	retainstack = retainstack_region->start - sizeof(cell);
}

void context::reset_callstack()
{
	
}

void context::reset_context_objects()
{
	memset_cell(context_objects,false_object,context_object_count * sizeof(cell));
}

/* called on startup */
void factor_vm::init_contexts(cell datastack_size_, cell retainstack_size_, cell callstack_size_)
{
	datastack_size = datastack_size_;
	retainstack_size = retainstack_size_;
	callstack_size = callstack_size_;
	ctx = NULL;
	unused_contexts = NULL;
}

void factor_vm::delete_contexts()
{
	assert(!ctx);
	while(unused_contexts)
	{
		context *next = unused_contexts->next;
		delete unused_contexts;
		unused_contexts = next;
	}
}

context *factor_vm::alloc_context()
{
	context *new_context;

	if(unused_contexts)
	{
		new_context = unused_contexts;
		unused_contexts = unused_contexts->next;
	}
	else
	{
		new_context = new context(datastack_size,
			retainstack_size,
			callstack_size);
	}

	new_context->callstack_bottom = (stack_frame *)-1;
	new_context->callstack_top = (stack_frame *)-1;

	new_context->reset_datastack();
	new_context->reset_retainstack();
	new_context->reset_callstack();
	new_context->reset_context_objects();

	return new_context;
}

void factor_vm::dealloc_context(context *old_context)
{
	old_context->next = unused_contexts;
	unused_contexts = old_context;
}

void factor_vm::nest_context()
{
	context *new_ctx = alloc_context();
	new_ctx->next = ctx;
	ctx = new_ctx;
	callback_ids.push_back(callback_id++);
}

void nest_context(factor_vm *parent)
{
	return parent->nest_context();
}

void factor_vm::unnest_context()
{
	callback_ids.pop_back();
	context *old_ctx = ctx;
	ctx = old_ctx->next;
	dealloc_context(old_ctx);
}

void unnest_context(factor_vm *parent)
{
	return parent->unnest_context();
}

void factor_vm::primitive_current_callback()
{
	ctx->push(tag_fixnum(callback_ids.back()));
}

void factor_vm::primitive_context_object()
{
	fixnum n = untag_fixnum(ctx->peek());
	ctx->replace(ctx->context_objects[n]);
}

void factor_vm::primitive_set_context_object()
{
	fixnum n = untag_fixnum(ctx->pop());
	cell value = ctx->pop();
	ctx->context_objects[n] = value;
}

bool factor_vm::stack_to_array(cell bottom, cell top)
{
	fixnum depth = (fixnum)(top - bottom + sizeof(cell));

	if(depth < 0)
		return false;
	else
	{
		array *a = allot_uninitialized_array<array>(depth / sizeof(cell));
		memcpy(a + 1,(void*)bottom,depth);
		ctx->push(tag<array>(a));
		return true;
	}
}

void factor_vm::primitive_datastack()
{
	if(!stack_to_array(ctx->datastack_region->start,ctx->datastack))
		general_error(ERROR_DS_UNDERFLOW,false_object,false_object,NULL);
}

void factor_vm::primitive_retainstack()
{
	if(!stack_to_array(ctx->retainstack_region->start,ctx->retainstack))
		general_error(ERROR_RS_UNDERFLOW,false_object,false_object,NULL);
}

/* returns pointer to top of stack */
cell factor_vm::array_to_stack(array *array, cell bottom)
{
	cell depth = array_capacity(array) * sizeof(cell);
	memcpy((void*)bottom,array + 1,depth);
	return bottom + depth - sizeof(cell);
}

void factor_vm::primitive_set_datastack()
{
	ctx->datastack = array_to_stack(untag_check<array>(ctx->pop()),ctx->datastack_region->start);
}

void factor_vm::primitive_set_retainstack()
{
	ctx->retainstack = array_to_stack(untag_check<array>(ctx->pop()),ctx->retainstack_region->start);
}

/* Used to implement call( */
void factor_vm::primitive_check_datastack()
{
	fixnum out = to_fixnum(ctx->pop());
	fixnum in = to_fixnum(ctx->pop());
	fixnum height = out - in;
	array *saved_datastack = untag_check<array>(ctx->pop());
	fixnum saved_height = array_capacity(saved_datastack);
	fixnum current_height = (ctx->datastack - ctx->datastack_region->start + sizeof(cell)) / sizeof(cell);
	if(current_height - height != saved_height)
		ctx->push(false_object);
	else
	{
		cell *ds_bot = (cell *)ctx->datastack_region->start;
		for(fixnum i = 0; i < saved_height - in; i++)
		{
			if(ds_bot[i] != array_nth(saved_datastack,i))
			{
				ctx->push(false_object);
				return;
			}
		}
		ctx->push(true_object);
	}
}

void factor_vm::primitive_load_locals()
{
	fixnum count = untag_fixnum(ctx->pop());
	memcpy((cell *)(ctx->retainstack + sizeof(cell)),
		(cell *)(ctx->datastack - sizeof(cell) * (count - 1)),
		sizeof(cell) * count);
	ctx->datastack -= sizeof(cell) * count;
	ctx->retainstack += sizeof(cell) * count;
}

}
