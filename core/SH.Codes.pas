{******************************************************************************}
{* Project : "StackHouse" virtual stack-machine                               *}
{* Unit    : Constants                                                        *}
{* Change  : 03.10.2019 (205 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2019 DelphiRunner                                            *}
{******************************************************************************}

unit SH.Codes;

 interface

 const

  Delim   : Char = ' '; // tokens divider
  Quote   : Char = '"'; // quote char for strings
  Escap   : Char = '\'; // escape char
  Comment : Char = ';'; // comment mark
  NewLine : Char = 'n'; // new line char
  _SYS    : Char = '%'; // prefix - system or external function name
  _IDX    : Char = '.'; // prefix - index of function, local or global data
  _LOC    : Char = 'L'; // prefix - index of local data
  _GLO    : Char = 'G'; // prefix - index of global data
  _FUN    : Char = 'F'; // prefix - index of user function
  _MAC    : Char = '_'; // prefix - macro name
  _LAB    : Char = ':'; // prefix - label name
  _INT    : Char = '0'; // prefix - integer literal
  _HEX    : Char = 'X'; // prefix - hexadecimal number
  _BIN    : Char = 'B'; // prefix - binary stream (via hexadecimal)

  DS : set of Char = ['0'..'9','-'];
  HS : set of Char = ['0'..'9','A'..'F'];
  HV : array ['0'..'F'] of UInt8 = (0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,10,11,12,13,14,15);

  // CID - command(operation) identifier

  CID_NOPE  =  0; // empty command (only IP increment)

  // integer arithmetic
  CID_INC   = 59; // increment by 1
  CID_DEC   = 58; // decrement by 1
  CID_INCL  =  5; // increment .Lx by N
  CID_DECL  =  4; // decrement .Lx by N
  CID_MOD   = 57; // modulo
  CID_IADD  = 56; // addition
  CID_ISUB  = 55; // substraction
  CID_IMUL  = 54; // multiplication
  CID_IDIV  = 53; // division
  CID_IABS  = 52; // absolute value of an integer
  CID_INEG  = 3;  // negation

  // real arithmetic
  CID_FADD  = 25; // addition
  CID_FSUB  = 24; // substraction
  CID_FMUL  = 23; // multiplication
  CID_FDIV  = 22; // division
  CID_POW   = 21; // power
  CID_LOG   = 20; // logarithm
  CID_SIN   = 19; // sine (rad)
  CID_COS   = 18; // cosine (rad)
  CID_ASIN  = 17; // arcsine (rad)
  CID_ACOS  = 16; // arccosine (rad)
  CID_SEED  = 15; // initialization of random number generator
  CID_RAND  = 14; // random float within a [0..1) range
  CID_FABS  = 13; // absolute value of a float
  CID_INT   = 12; // integer part of a float
  CID_FRAC  = 11; // fractional part of a float
  CID_FNEG  = 2;  // negation

  // bitwise operations
  CID_NOT   = 39; // bits inversion
  CID_AND   = 38; //
  CID_OR    = 37; //
  CID_XOR   = 36; //
  CID_SHL   = 35; // left logical shift (replace with 0)
  CID_SHR   = 34; // right logical shift (replace with 0)
  CID_ROTL  = 33; // left curcular shift
  CID_ROTR  = 32; // right curcular shift
  CID_REV   = 31; // bits reverse
  CID_MASK  = 30; // extract integer value by bitmask
  CID_BTEST = 29; // test bit
  CID_BTOG  = 28; // toggle bit
  CID_BON   = 27; // set bit to 1
  CID_BOFF  = 26; // set bit to 0

  // int/float convertions
  CID_ITOF  = 51; // convert integer to float
  CID_FTOI  = 50; // convert float to integer (like "round" function)

  // control
  CID_JZ    = 71; // jump if  0 on top of stack
  CID_JNZ   = 70; // jump if !0 on top of stack
  CID_JLZ   = 69; // jump if <0 on top of stack
  CID_JGZ   = 68; // jump if >0 on top of stack
  CID_CMP   = 67; // compare values from stack & push logic value to stack (0 or 1)
  CID_JN    = 66; // compare values from stack & jump if the condition is NOT met
  CID_JUMPI = 65; // unconditional jump (take jump index from command argument "JUMP")
  CID_JUMPS = 64; // unconditional jump (take jump index from stack)
  CID_CALL  = 63; // call function synchronously (user or system function)
  CID_RET   = 61; // return control to the caller / exit thread
  CID_HALT  = 60; // stop program execution

  // async operations
  CID_ASYNC = 10; // function call asynchronously (run function in new thread)
  CID_WAIT  =  9; // wait for async function execution
  CID_SLEEP =  8; // skip CPU-ticks
  CID_ENTER =  7; // enter critical section
  CID_LEAVE =  6; // leave critical section

  // stack, local & global variables operations
  // C - constant;
  // G - global var;
  // L - local var;
  // S - stack; (+) inc stack; (-) dec stack; ( ) don't change stack;
  CID_PUSH_C  = 99; // C    >>    S(+)
  CID_PUSH_L  = 98; // G    >>    S(+)
  CID_PUSH_G  = 97; // L    >>    S(+)
  CID_PUSH_CC = 96; // C C  >>    S(++)
  CID_PUSH_LC = 95; // G C  >>    S(++)
  CID_PUSH_GC = 94; // L C  >>    S(++)
  CID_PUSH_CL = 93; // C L  >>    S(++)
  CID_PUSH_LL = 92; // G L  >>    S(++)
  CID_PUSH_GL = 91; // L L  >>    S(++)
  CID_PUSH_CG = 90; // C G  >>    S(++)
  CID_PUSH_LG = 89; // G G  >>    S(++)
  CID_PUSH_GG = 88; // L G  >>    S(++)
  CID_POP_G   = 87; // S(-) >>    G
  CID_POP_L   = 86; // S(-) >>    L
  CID_STORE_G = 85; // S( ) >>    G
  CID_STORE_L = 84; // S( ) >>    L
  CID_MOV_CG  = 83; // C    >>    G
  CID_MOV_CL  = 82; // C    >>    L
  CID_MOV_GG  = 81; // G    >>    G
  CID_MOV_LL  = 80; // L    >>    L
  CID_MOV_GL  = 79; // G    >>    L
  CID_MOV_LG  = 78; // L    >>    G
  CID_TAKE    = 77; // caller.S(-) >> func.S(+)
  CID_PASS    = 76; // func.S(-)   >> caller.S(+)
  CID_DUP     = 75; // duplication top of stack
  CID_SWAP    = 74; // swap top of stack
  CID_PUSH    = 73; // null >>    S(+)
  CID_POP     = 72; // S(-) >>    null

  // heap operations (based on use local vars as pointers holders)
  CID_ADDR    = 49; // ARR_TO = ARR_FROM + offset; S(-offset)
  CID_SIZE    = 48; // S(+ size of ARR_FROM))
  CID_GET1    = 47; // S(+1 byte ARR_FROM)
  CID_GET8    = 46; // S(+8 byte ARR_FROM)
  CID_SET1    = 45; // ARR_TO = 1byte value; S(-value)
  CID_SET8    = 44; // ARR_TO = 8byte value; S(-value)
  CID_COPY    = 43; // copy ARR_FROM to ARR_TO N-bytes S(-N)
  CID_ALLOC   = 42; // alloc(ARR_FROM) S(-size)
  CID_REALLOC = 41; // realloc(ARR_FROM) S(-size)
  CID_FREE    = 40; // free(ARR_FROM) S()

  // condition type (aligned with data type - int float char)
  COND_E  =  0; // ==
  COND_NE =  3; // !=
  COND_G  =  6; //  >
  COND_L  =  9; //  <
  COND_GE = 12; // >=
  COND_LE = 15; // <=

  // data type
  DATA_INT         = 0;
  DATA_FLOAT       = 1;
  DATA_CHAR        = 2;
  DATA_ARRAY_INT   = 3;
  DATA_ARRAY_FLOAT = 4;
  DATA_ARRAY_CHAR  = 5;

  // function type
  FUNC_SYSTEM = 0; // system function - call by index from FUN_IDX
  FUNC_USER_A = 1; // user function   - call by index from FUN_IDX
  FUNC_USER_B = 2; // user function   - call by index from stack

  // token type                            |  EXAMPLE :
  TOK_UNDEF  =  0; // undefined            |
  TOK_INT    =  1; // integer value        | 255 0xFF null true false int64_min int64_max
  TOK_FLOAT  =  2; // real value           | -3.1415  .08 not_a_number pos_infinity neg_infinity
  TOK_STRING =  3; // string value         | "test\n" "slash is \"\\"\\n"
  TOK_IDENT  =  4; // identifier           | mov
  TOK_GNAME  =  5; // global name          | %print %math:pi
  TOK_LIDX   =  6; // local storage index  | .L5
  TOK_GIDX   =  7; // global storage index | .G2
  TOK_FIDX   =  8; // function index       | .F23
  TOK_BINARY =  9; // binary stream        | 0bFF50A005478CD0
  TOK_MACRO  = 10; // macro name           | _high
  TOK_LABEL  = 11; // label name           | :if_end

  // EID - error identifier

  EID_UNKNOWN             = -2; //
  EID_RET                 = -1; // controlled exit with no error
  EID_HALT                =  0; // controlled exit with forced program stop
  EID_InstanceAlreadyUsed =  1;
  EID_FunctionNotFound    =  2;
  EID_FileNotFound        =  3;
  EID_InvalidConfig       =  4;
  EID_BuildFailed         =  5;

 implementation

end.
