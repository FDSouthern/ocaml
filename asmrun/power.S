/***********************************************************************/
/*                                                                     */
/*                                OCaml                                */
/*                                                                     */
/*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         */
/*                                                                     */
/*  Copyright 1996 Institut National de Recherche en Informatique et   */
/*  en Automatique.  All rights reserved.  This file is distributed    */
/*  under the terms of the GNU Library General Public License, with    */
/*  the special exception on linking described in file ../LICENSE.     */
/*                                                                     */
/***********************************************************************/

#if defined(MODEL_ppc64le)
        .abiversion 2
#endif

#if defined(MODEL_ppc64) || defined(MODEL_ppc64le)
#define EITHER(a,b) b
#else
#define EITHER(a,b) a
#endif

#define WORD EITHER(4,8)
#define lg EITHER(lwz,ld)
#define lgu EITHER(lwzu,ldu)
#define stg EITHER(stw,std)
#define stgu EITHER(stwu,stdu)
#define datag EITHER(.long,.quad)
#define wordalign EITHER(2,3)

/* Stack layout */
#if defined(MODEL_ppc)
#define RESERVED_STACK 16
#define PARAM_SAVE_AREA 0
#define LR_SAVE 4
#define TRAP_SIZE 16
#define TRAP_HANDLER_OFFSET 0
#define TRAP_PREVIOUS_OFFSET 4
#define CALLBACK_LINK_SIZE 16
#define CALLBACK_LINK_OFFSET 0
#endif
#if defined(MODEL_ppc64)
#define RESERVED_STACK 48
#define PARAM_SAVE_AREA (8*8)
#define LR_SAVE 16
#define TOC_SAVE 40
#define TOC_SAVE_PARENT 8
#define TRAP_SIZE 32
#define TRAP_HANDLER_OFFSET 56
#define TRAP_PREVIOUS_OFFSET 64
#define CALLBACK_LINK_SIZE 32
#define CALLBACK_LINK_OFFSET 48
#endif
#if defined(MODEL_ppc64le)
#define RESERVED_STACK 32
#define PARAM_SAVE_AREA 0
#define LR_SAVE 16
#define TOC_SAVE_PARENT 8
#define TOC_SAVE 24
#define TRAP_SIZE 32
#define TRAP_HANDLER_OFFSET 40
#define TRAP_PREVIOUS_OFFSET 48
#define CALLBACK_LINK_SIZE 32
#define CALLBACK_LINK_OFFSET 32
#endif

/* Function definitions */

#if defined(MODEL_ppc)
#define FUNCTION(name) \
  .section ".text"; \
  .globl name; \
  .type name, @function; \
  .align 2; \
  name:

#define ENDFUNCTION(name) \
  .size name, . - name

#endif

#if defined(MODEL_ppc64)
#define FUNCTION(name) \
  .section ".opd","aw"; \
  .align 3; \
  .globl name; \
  .type name, @function; \
  name: .quad .L.name,.TOC.@tocbase; \
  .text; \
  .align 2; \
  .L.name:

#define ENDFUNCTION(name) \
  .size name, . - .L.name

#endif

#if defined(MODEL_ppc64le)
#define FUNCTION(name) \
  .section ".text"; \
  .globl name; \
  .type name, @function; \
  .align 2; \
  name: ; \
  0: addis 2, 12, (.TOC. - 0b)@ha; \
  addi 2, 2, (.TOC. - 0b)@l; \
  .localentry name, . - 0b

#define ENDFUNCTION(name) \
  .size name, . - name

#endif

/* Accessing global variables.  */

#if defined(MODEL_ppc)

#define Addrglobal(reg,glob) \
        addis   reg, 0, glob@ha; \
        addi    reg, reg, glob@l
#define Loadglobal(reg,glob,tmp) \
        addis   tmp, 0, glob@ha; \
        lg      reg, glob@l(tmp)
#define Storeglobal(reg,glob,tmp) \
        addis   tmp, 0, glob@ha; \
        stg     reg, glob@l(tmp)
#define Loadglobal32(reg,glob,tmp) \
        addis   tmp, 0, glob@ha; \
        lwz     reg, glob@l(tmp)
#define Storeglobal32(reg,glob,tmp) \
        addis   tmp, 0, glob@ha; \
        stw     reg, glob@l(tmp)

#endif

#if defined(MODEL_ppc64) || defined(MODEL_ppc64le)

#define LSYMB(glob) .L##glob

#define Addrglobal(reg,glob) \
        ld      reg, LSYMB(glob)@toc(2)
#define Loadglobal(reg,glob,tmp) \
        Addrglobal(tmp,glob); \
        lg      reg, 0(tmp)
#define Storeglobal(reg,glob,tmp) \
        Addrglobal(tmp,glob); \
        stg     reg, 0(tmp)
#define Loadglobal32(reg,glob,tmp) \
        Addrglobal(tmp,glob); \
        lwz     reg, 0(tmp)
#define Storeglobal32(reg,glob,tmp) \
        Addrglobal(tmp,glob); \
        stw     reg, 0(tmp)

#endif

#if defined(MODEL_ppc64)
        .section ".opd","aw"
#else
        .section ".text"
#endif
        .globl  caml_system__code_begin
caml_system__code_begin:

/* Invoke the garbage collector. */

FUNCTION(caml_call_gc)
#define STACKSIZE (WORD*32 + 8*32 + PARAM_SAVE_AREA + RESERVED_STACK)
    /* 32 integer registers + 32 float registers + space for C call */
    /* Set up stack frame */
        stwu    1, -STACKSIZE(1)
    /* Record return address into OCaml code */
        mflr    0
        Storeglobal(0, caml_last_return_address, 11)
    /* Record lowest stack address */
        addi    0, 1, STACKSIZE
        Storeglobal(0, caml_bottom_of_stack, 11)
    /* Record pointer to register array */
        addi    0, 1, 8*32 + PARAM_SAVE_AREA + RESERVED_STACK
        Storeglobal(0, caml_gc_regs, 11)
    /* Save current allocation pointer for debugging purposes */
        Storeglobal(31, caml_young_ptr, 11)
    /* Save exception pointer (if e.g. a sighandler raises) */
        Storeglobal(29, caml_exception_pointer, 11)
    /* Save all registers used by the code generator */
        addi    11, 1, 8*32 + PARAM_SAVE_AREA + RESERVED_STACK - WORD
        stgu    3, WORD(11)
        stgu    4, WORD(11)
        stgu    5, WORD(11)
        stgu    6, WORD(11)
        stgu    7, WORD(11)
        stgu    8, WORD(11)
        stgu    9, WORD(11)
        stgu    10, WORD(11)
        stgu    14, WORD(11)
        stgu    15, WORD(11)
        stgu    16, WORD(11)
        stgu    17, WORD(11)
        stgu    18, WORD(11)
        stgu    19, WORD(11)
        stgu    20, WORD(11)
        stgu    21, WORD(11)
        stgu    22, WORD(11)
        stgu    23, WORD(11)
        stgu    24, WORD(11)
        stgu    25, WORD(11)
        stgu    26, WORD(11)
        stgu    27, WORD(11)
        stgu    28, WORD(11)
        addi    11, 1, PARAM_SAVE_AREA + RESERVED_STACK - 8
        stfdu   1, 8(11)
        stfdu   2, 8(11)
        stfdu   3, 8(11)
        stfdu   4, 8(11)
        stfdu   5, 8(11)
        stfdu   6, 8(11)
        stfdu   7, 8(11)
        stfdu   8, 8(11)
        stfdu   9, 8(11)
        stfdu   10, 8(11)
        stfdu   11, 8(11)
        stfdu   12, 8(11)
        stfdu   13, 8(11)
        stfdu   14, 8(11)
        stfdu   15, 8(11)
        stfdu   16, 8(11)
        stfdu   17, 8(11)
        stfdu   18, 8(11)
        stfdu   19, 8(11)
        stfdu   20, 8(11)
        stfdu   21, 8(11)
        stfdu   22, 8(11)
        stfdu   23, 8(11)
        stfdu   24, 8(11)
        stfdu   25, 8(11)
        stfdu   26, 8(11)
        stfdu   27, 8(11)
        stfdu   28, 8(11)
        stfdu   29, 8(11)
        stfdu   30, 8(11)
        stfdu   31, 8(11)
    /* Call the GC */
        bl      caml_garbage_collection
#if defined(MODEL_ppc64) || defined(MODEL_ppc64le)
        nop
#endif
    /* Reload new allocation pointer and allocation limit */
        Loadglobal(31, caml_young_ptr, 11)
        Loadglobal(30, caml_young_limit, 11)
    /* Restore all regs used by the code generator */
        addi    11, 1, 8*32 + PARAM_SAVE_AREA + RESERVED_STACK - WORD
        lgu     3, WORD(11)
        lgu     4, WORD(11)
        lgu     5, WORD(11)
        lgu     6, WORD(11)
        lgu     7, WORD(11)
        lgu     8, WORD(11)
        lgu     9, WORD(11)
        lgu     10, WORD(11)
        lgu     14, WORD(11)
        lgu     15, WORD(11)
        lgu     16, WORD(11)
        lgu     17, WORD(11)
        lgu     18, WORD(11)
        lgu     19, WORD(11)
        lgu     20, WORD(11)
        lgu     21, WORD(11)
        lgu     22, WORD(11)
        lgu     23, WORD(11)
        lgu     24, WORD(11)
        lgu     25, WORD(11)
        lgu     26, WORD(11)
        lgu     27, WORD(11)
        lgu     28, WORD(11)
        addi    11, 1, PARAM_SAVE_AREA + RESERVED_STACK - 8
        lfdu    1, 8(11)
        lfdu    2, 8(11)
        lfdu    3, 8(11)
        lfdu    4, 8(11)
        lfdu    5, 8(11)
        lfdu    6, 8(11)
        lfdu    7, 8(11)
        lfdu    8, 8(11)
        lfdu    9, 8(11)
        lfdu    10, 8(11)
        lfdu    11, 8(11)
        lfdu    12, 8(11)
        lfdu    13, 8(11)
        lfdu    14, 8(11)
        lfdu    15, 8(11)
        lfdu    16, 8(11)
        lfdu    17, 8(11)
        lfdu    18, 8(11)
        lfdu    19, 8(11)
        lfdu    20, 8(11)
        lfdu    21, 8(11)
        lfdu    22, 8(11)
        lfdu    23, 8(11)
        lfdu    24, 8(11)
        lfdu    25, 8(11)
        lfdu    26, 8(11)
        lfdu    27, 8(11)
        lfdu    28, 8(11)
        lfdu    29, 8(11)
        lfdu    30, 8(11)
        lfdu    31, 8(11)
    /* Return to caller, restarting the allocation */
        Loadglobal(11, caml_last_return_address, 11)
        addi    11, 11, -16     /* Restart the allocation (4 instructions) */
        mtlr    11
    /* For PPC64: restore the TOC that the caller saved at the usual place */
#ifdef TOC_SAVE
        ld      2, (STACKSIZE + TOC_SAVE)(1)
#endif
    /* Deallocate stack frame */
        addi    1, 1, STACKSIZE
        blr
#undef STACKSIZE
ENDFUNCTION(caml_call_gc)

/* Call a C function from OCaml */

FUNCTION(caml_c_call)
        .cfi_startproc
    /* Save return address in a callee-save register */
        mflr    27
        .cfi_register 65, 27
    /* Record lowest stack address and return address */
        Storeglobal(1, caml_bottom_of_stack, 11)
        Storeglobal(27, caml_last_return_address, 11)
    /* Make the exception handler and alloc ptr available to the C code */
        Storeglobal(31, caml_young_ptr, 11)
        Storeglobal(29, caml_exception_pointer, 11)
    /* Call C function (address in r28) */
#if defined(MODEL_ppc)
        mtctr   28
        bctrl
#elif defined(MODEL_ppc64)
        ld      0, 0(28)
        mr      26, 2   /* save current TOC in a callee-save register */
        mtctr   0
        ld      2, 8(28)
        bctrl
        mr      2, 26   /* restore current TOC */
#elif defined(MODEL_ppc64le)
        mtctr   28
        mr      12, 28
        mr      26, 2   /* save current TOC in a callee-save register */
        bctrl
        mr      2, 26   /* restore current TOC */
#else
#error "wrong MODEL"
#endif
    /* Restore return address (in 27, preserved by the C function) */
        mtlr    27
    /* Reload allocation pointer and allocation limit*/
        Loadglobal(31, caml_young_ptr, 11)
        Loadglobal(30, caml_young_limit, 11)
    /* Return to caller */
        blr
        .cfi_endproc
ENDFUNCTION(caml_c_call)

/* Raise an exception from OCaml */

FUNCTION(caml_raise_exn)
        Loadglobal32(0, caml_backtrace_active, 11)
        cmpwi   0, 0
        bne     .L111
.L110:
    /* Pop trap frame */
        lg      0, TRAP_HANDLER_OFFSET(29)
        mr      1, 29
        mtctr   0
        lg      29, TRAP_PREVIOUS_OFFSET(1)
        addi    1, 1, TRAP_SIZE
    /* Branch to handler */
        bctr
.L111:
        li      0, 0
        Storeglobal32(0, caml_backtrace_pos, 11)
.L112:
        mr      28, 3           /* preserve exn bucket in callee-save reg */
                                /* arg1: exception bucket, already in r3 */
        mflr    4               /* arg2: PC of raise */
        mr      5, 1            /* arg3: SP of raise */
        mr      6, 29           /* arg4: SP of handler */
        addi    1, 1, -(PARAM_SAVE_AREA + RESERVED_STACK)
                                /* reserve stack space for C call */
        bl      caml_stash_backtrace
#if defined(MODEL_ppc64) || defined(MODEL_ppc64le)
        nop
#endif
        mr      3, 28           /* restore exn bucket */
        b       .L110           /* raise the exn */
ENDFUNCTION(caml_raise_exn)

FUNCTION(caml_reraise_exn)
        Loadglobal32(0, caml_backtrace_active, 11)
        cmpwi   0, 0
        bne-    .L112
    /* Pop trap frame */
        lg      0, TRAP_HANDLER_OFFSET(29)
        mr      1, 29
        mtctr   0
        lg      29, TRAP_PREVIOUS_OFFSET(1)
        addi    1, 1, TRAP_SIZE
    /* Branch to handler */
        bctr
ENDFUNCTION(caml_reraise_exn)

/* Raise an exception from C */

FUNCTION(caml_raise_exception)
        Loadglobal32(0, caml_backtrace_active, 11)
        cmpwi   0, 0
        bne     .L121
.L120:
    /* Reload OCaml global registers */
        Loadglobal(1, caml_exception_pointer, 11)
        Loadglobal(31, caml_young_ptr, 11)
        Loadglobal(30, caml_young_limit, 11)
    /* Pop trap frame */
        lg      0, TRAP_HANDLER_OFFSET(1)
        mtctr   0
        lg      29, TRAP_PREVIOUS_OFFSET(1)
        addi    1, 1, TRAP_SIZE
    /* Branch to handler */
        bctr
.L121:
        li      0, 0
        Storeglobal32(0, caml_backtrace_pos, 11)
        mr      28, 3           /* preserve exn bucket in callee-save reg */
                                /* arg1: exception bucket, already in r3 */
        Loadglobal(4, caml_last_return_address, 11) /* arg2: PC of raise */
        Loadglobal(5, caml_bottom_of_stack, 11)     /* arg3: SP of raise */
        Loadglobal(6, caml_exception_pointer, 11)   /* arg4: SP of handler */
        addi    1, 1, -(PARAM_SAVE_AREA + RESERVED_STACK)
                                         /* reserve stack space for C call */
        bl      caml_stash_backtrace
#if defined(MODEL_ppc64) || defined(MODEL_ppc64le)
        nop
#endif
        mr      3, 28           /* restore exn bucket */
        b       .L120           /* raise the exn */
ENDFUNCTION(caml_raise_exception)

/* Start the OCaml program */

FUNCTION(caml_start_program)
        .cfi_startproc
#define STACKSIZE (WORD*18 + 8*18 + CALLBACK_LINK_SIZE + RESERVED_STACK)
  /* 18 callee-save GPR14...GPR31 + 18 callee-save FPR14...FPR31 */
        Addrglobal(12, caml_program)
/* Code shared between caml_start_program and caml_callback */
.L102:
    /* Allocate and link stack frame */
        stgu    1, -STACKSIZE(1)
        .cfi_adjust_cfa_offset STACKSIZE
    /* Save return address */
        mflr    0
        stg     0, (STACKSIZE + LR_SAVE)(1)
        .cfi_offset 65, LR_SAVE
    /* Save TOC pointer if applicable */
#ifdef TOC_SAVE_PARENT
        std     2, (STACKSIZE + TOC_SAVE_PARENT)(1)
#endif
    /* Save all callee-save registers */
        addi    11, 1, CALLBACK_LINK_SIZE + RESERVED_STACK - WORD
        stgu    14, WORD(11)
        stgu    15, WORD(11)
        stgu    16, WORD(11)
        stgu    17, WORD(11)
        stgu    18, WORD(11)
        stgu    19, WORD(11)
        stgu    20, WORD(11)
        stgu    21, WORD(11)
        stgu    22, WORD(11)
        stgu    23, WORD(11)
        stgu    24, WORD(11)
        stgu    25, WORD(11)
        stgu    26, WORD(11)
        stgu    27, WORD(11)
        stgu    28, WORD(11)
        stgu    29, WORD(11)
        stgu    30, WORD(11)
        stgu    31, WORD(11)
        stfdu   14, 8(11)
        stfdu   15, 8(11)
        stfdu   16, 8(11)
        stfdu   17, 8(11)
        stfdu   18, 8(11)
        stfdu   19, 8(11)
        stfdu   20, 8(11)
        stfdu   21, 8(11)
        stfdu   22, 8(11)
        stfdu   23, 8(11)
        stfdu   24, 8(11)
        stfdu   25, 8(11)
        stfdu   26, 8(11)
        stfdu   27, 8(11)
        stfdu   28, 8(11)
        stfdu   29, 8(11)
        stfdu   30, 8(11)
        stfdu   31, 8(11)
    /* Set up a callback link */
        Loadglobal(11, caml_bottom_of_stack, 11)
        stg     11, CALLBACK_LINK_OFFSET(1)
        Loadglobal(11, caml_last_return_address, 11)
        stg     11, (CALLBACK_LINK_OFFSET + WORD)(1)
        Loadglobal(11, caml_gc_regs, 11)
        stg     11, (CALLBACK_LINK_OFFSET + 2 * WORD)(1)
    /* Build an exception handler to catch exceptions escaping out of OCaml */
        bl      .L103
        b       .L104
.L103:
        addi    1, 1, -TRAP_SIZE
        .cfi_adjust_cfa_offset TRAP_SIZE
        mflr    0
        stg     0, TRAP_HANDLER_OFFSET(1)
        Loadglobal(11, caml_exception_pointer, 11)
        stg     11, TRAP_PREVIOUS_OFFSET(1)
        mr      29, 1
    /* Reload allocation pointers */
        Loadglobal(31, caml_young_ptr, 11)
        Loadglobal(30, caml_young_limit, 11)
    /* Call the OCaml code (address in r12) */
#if defined(MODEL_ppc)
        mtctr   12
.L105:  bctrl
#elif defined(MODEL_ppc64)
        ld      0, 0(12)
        mtctr   0
        std     2, TOC_SAVE(1)
        ld      2, 8(12)
.L105:  bctrl
        ld      2, TOC_SAVE(1)
#elif defined(MODEL_ppc64le)
        mtctr   12
        std     2, TOC_SAVE(1)
.L105:  bctrl
        ld      2, TOC_SAVE(1)
#else
#error "wrong MODEL"
#endif
    /* Pop the trap frame, restoring caml_exception_pointer */
        lg      0, TRAP_PREVIOUS_OFFSET(1)
        Storeglobal(0, caml_exception_pointer, 11)
        addi    1, 1, TRAP_SIZE
        .cfi_adjust_cfa_offset -TRAP_SIZE
    /* Pop the callback link, restoring the global variables */
.L106:
        lg      0, CALLBACK_LINK_OFFSET(1)
        Storeglobal(0, caml_bottom_of_stack, 11)
        lg      0, (CALLBACK_LINK_OFFSET + WORD)(1)
        Storeglobal(0, caml_last_return_address, 11)
        lg      0, (CALLBACK_LINK_OFFSET + 2 * WORD)(1)
        Storeglobal(0, caml_gc_regs, 11)
    /* Update allocation pointer */
        Storeglobal(31, caml_young_ptr, 11)
    /* Restore callee-save registers */
        addi    11, 1, CALLBACK_LINK_SIZE + RESERVED_STACK - WORD
        lgu     14, WORD(11)
        lgu     15, WORD(11)
        lgu     16, WORD(11)
        lgu     17, WORD(11)
        lgu     18, WORD(11)
        lgu     19, WORD(11)
        lgu     20, WORD(11)
        lgu     21, WORD(11)
        lgu     22, WORD(11)
        lgu     23, WORD(11)
        lgu     24, WORD(11)
        lgu     25, WORD(11)
        lgu     26, WORD(11)
        lgu     27, WORD(11)
        lgu     28, WORD(11)
        lgu     29, WORD(11)
        lgu     30, WORD(11)
        lgu     31, WORD(11)
        lfdu    14, 8(11)
        lfdu    15, 8(11)
        lfdu    16, 8(11)
        lfdu    17, 8(11)
        lfdu    18, 8(11)
        lfdu    19, 8(11)
        lfdu    20, 8(11)
        lfdu    21, 8(11)
        lfdu    22, 8(11)
        lfdu    23, 8(11)
        lfdu    24, 8(11)
        lfdu    25, 8(11)
        lfdu    26, 8(11)
        lfdu    27, 8(11)
        lfdu    28, 8(11)
        lfdu    29, 8(11)
        lfdu    30, 8(11)
        lfdu    31, 8(11)
    /* Reload return address */
        lg      0, (STACKSIZE + LR_SAVE)(1)
        mtlr    0
    /* Return */
        addi    1, 1, STACKSIZE
        blr

    /* The trap handler: */
.L104:
    /* Restore TOC pointer */
#ifdef TOC_SAVE_PARENT
        ld      2, (STACKSIZE + TOC_SAVE_PARENT)(1)
#endif
    /* Update caml_exception_pointer */
        Storeglobal(29, caml_exception_pointer, 11)
    /* Encode exception bucket as an exception result and return it */
        ori     3, 3, 2
        b       .L106
#undef STACKSIZE
        .cfi_endproc
ENDFUNCTION(caml_start_program)

/* Callback from C to OCaml */

FUNCTION(caml_callback_exn)
    /* Initial shuffling of arguments */
        mr      0, 3            /* Closure */
        mr      3, 4            /* Argument */
        mr      4, 0
        lg      12, 0(4)        /* Code pointer */
        b       .L102
ENDFUNCTION(caml_callback_exn)

FUNCTION(caml_callback2_exn)
        mr      0, 3            /* Closure */
        mr      3, 4            /* First argument */
        mr      4, 5            /* Second argument */
        mr      5, 0
        Addrglobal(12, caml_apply2)
        b       .L102
ENDFUNCTION(caml_callback2_exn)

FUNCTION(caml_callback3_exn)
        mr      0, 3            /* Closure */
        mr      3, 4            /* First argument */
        mr      4, 5            /* Second argument */
        mr      5, 6            /* Third argument */
        mr      6, 0
        Addrglobal(12, caml_apply3)
        b       .L102
ENDFUNCTION(caml_callback3_exn)

#if defined(MODEL_ppc64)
        .section ".opd","aw"
#else
        .section ".text"
#endif

        .globl  caml_system__code_end
caml_system__code_end:

/* Frame table */

        .section ".data"
        .globl  caml_system__frametable
        .type   caml_system__frametable, @object
caml_system__frametable:
        datag   1               /* one descriptor */
        datag   .L105 + 4       /* return address into callback */
        .short  -1              /* negative size count => use callback link */
        .short  0               /* no roots here */

/* TOC entries */

#if defined(MODEL_ppc64) || defined(MODEL_ppc64le)

        .section ".toc", "aw"

#define TOCENTRY(glob) LSYMB(glob): .quad glob

TOCENTRY(caml_apply2)
TOCENTRY(caml_apply3)
TOCENTRY(caml_backtrace_active)
TOCENTRY(caml_backtrace_pos)
TOCENTRY(caml_bottom_of_stack)
TOCENTRY(caml_exception_pointer)
TOCENTRY(caml_gc_regs)
TOCENTRY(caml_last_return_address)
TOCENTRY(caml_program)
TOCENTRY(caml_young_limit)
TOCENTRY(caml_young_ptr)

#endif

/* Mark stack as non-executable */
        .section .note.GNU-stack,"",%progbits
