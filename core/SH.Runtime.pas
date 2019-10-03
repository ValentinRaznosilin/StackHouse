{******************************************************************************}
{* Project : "StackHouse" virtual stack-machine                               *}
{* Unit    : Run-time objects                                                 *}
{* Change  : 03.10.2019 (839 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2019 DelphiRunner                                            *}
{******************************************************************************}

unit SH.Runtime;

 interface

 uses

  // system
  System.Types,
  System.SysUtils,
  System.Math,
  System.StrUtils,
  System.Classes,
  WinAPI.Windows,
  System.Generics.Defaults,
  System.Generics.Collections,
  // project
  SH.Codes,
  SH.Types,
  SH.Utils;

 {$DEFINE STATIC_FRAME_DATA}

 const

  MaxFrameData = 24;

 type

  TProgram = class;

  // user function ************************************************************
  PFrame = ^TFrame;
  TFrame = record

   {$POINTERMATH ON}
   CMD : PCommand;  // instruction pointer
   SP0 : PData;     // stack pointer (top)
   SP1 : PData;     // stack pointer (top-1 or top+1)
   {$POINTERMATH OFF}

   // local vars + stack in single array
   {$IFDEF STATIC_FRAME_DATA}
   Data : array [0..MaxFrameData-1] of TData;
   {$ELSE}
   Data : TStorage;
   {$ENDIF}

   ID   : UInt16;   // function identifier
   LCNT : UInt8;    // local data count
   SCNT : UInt8;    // stack data count
   USED : Boolean;  // true - function is running
   PROG : TProgram; // link to program
   CODE : TCode;    // link to commands

   procedure Free; inline;
   function  Copy:TFrame; inline;
   function  Alloc:PFrame; inline;
   function  Execute(const _caller_ : PFrame=Nil):Int32;

  end;
  TFrames = TArray<TFrame>;

  // program ******************************************************************
  TProgram = class(TObject)

   ID : TData;                         // program context
   F  : TFrames;                       // user functions (it is root frames that actually own the code)
   FN : TDictionary<AnsiString,Int64>; // dictionary for user functions names

   constructor Create;
   destructor  Destroy; override;

   function Execute(const FIDX:Int64; const Args:TArray<AnsiString>):Int32; overload;
   function Execute(const FNAME:AnsiString; const Args:TArray<AnsiString>):Int32; overload;

  end;

  TSystemFunction = function(const F:PFrame):Int32;

 implementation

 uses SH.System;

// ************************************************************************** //
//  TFrame                                                                    //
// ************************************************************************** //

 procedure TFrame.Free;
  begin
   {$IFNDEF STATIC_FRAME_DATA}
   Data := nil;
   {$ENDIF}
  end;

 function TFrame.Copy:TFrame;
  begin
   Result.ID   := ID;    // copy function identifier
   Result.CODE := CODE;  // copy link to code
   Result.LCNT := LCNT;  // copy local storage size
   Result.SCNT := SCNT;  // copy stack size
   Result.PROG := PROG;  // copy link to program
   Result.USED := false; // new instance not used by default
   {$IFNDEF STATIC_FRAME_DATA}
   // init local data & stack (values is not copyed!)
   SetLength(Result.Data,LCNT+SCNT);
   {$ENDIF}
  end;

 function TFrame.Alloc:PFrame;
  begin
   GetMem(Result,SizeOf(TFrame));
   Result.ID   := ID;    // copy function identifier
   Result.CODE := CODE;  // copy link to code
   Result.LCNT := LCNT;  // copy local storage size
   Result.SCNT := SCNT;  // copy stack size
   Result.PROG := PROG;  // copy link to program
   Result.USED := false; // new instance not used by default
   {$IFNDEF STATIC_FRAME_DATA}
   // init local data & stack (values is not copyed!)
   SetLength(Result.Data,LCNT+SCNT);
   {$ENDIF}
  end;

 function TFrame.Execute(const _caller_:PFrame):Int32;
  var
   FUN : PFrame;
   TMP : TData;
  label CommandLoop;
  begin
   // check USED flag .........................................................
   if USED then Exit(EID_InstanceAlreadyUsed); // Houston, we got a problem!
   // initialization ..........................................................
   USED := true;          // this instance now in use !
   CMD  := @CODE[0];      // init instruction pointer
   SP0  := @Data[LCNT-1]; // init stack pointer
   // command loop ............................................................
   CommandLoop:
   SP1 := SP0;
   case CMD.ID of
    {$region ' PUSH '}
    CID_PUSH :
     begin
      Inc(SP0);
      Inc(CMD);
     end;
    CID_PUSH_C :
     begin
      Inc(SP0);
      SP0.i8 :=  CMD.ARG;
      Inc(CMD);
     end;
    CID_PUSH_L :
     begin
      Inc(SP0);
      SP0.i8 := Data[CMD.ARG].i8;
      Inc(CMD);
     end;
    CID_PUSH_G :
     begin
      Inc(SP0);
      SP0.i8 := Globals[CMD.ARG].i8;
      Inc(CMD);
     end;
    CID_PUSH_CC :
     begin
      Inc(SP0); SP0.i8 := CMD.ARG;
      Inc(SP0); SP0.i8 := CMD.ARG2;
      Inc(CMD);
     end;
    CID_PUSH_LC :
     begin
      Inc(SP0); SP0.i8 := Data[CMD.ARG].i8;
      Inc(SP0); SP0.i8 := CMD.ARG2;
      Inc(CMD);
     end;
    CID_PUSH_GC :
     begin
      Inc(SP0); SP0.i8 := Globals[CMD.ARG].i8;
      Inc(SP0); SP0.i8 := CMD.ARG2;
      Inc(CMD);
     end;
    CID_PUSH_CL :
     begin
      Inc(SP0); SP0.i8 := CMD.ARG;
      Inc(SP0); SP0.i8 := Data[CMD.ARG2].i8;
      Inc(CMD);
     end;
    CID_PUSH_LL :
     begin
      Inc(SP0); SP0.i8 := Data[CMD.ARG ].i8;
      Inc(SP0); SP0.i8 := Data[CMD.ARG2].i8;
      Inc(CMD);
     end;
    CID_PUSH_GL :
     begin
      Inc(SP0); SP0.i8 := Globals[CMD.ARG ].i8;
      Inc(SP0); SP0.i8 := Data[CMD.ARG2].i8;
      Inc(CMD);
     end;
    CID_PUSH_CG :
     begin
      Inc(SP0); SP0.i8 := CMD.ARG;
      Inc(SP0); SP0.i8 := Globals[CMD.ARG2].i8;
      Inc(CMD);
     end;
    CID_PUSH_LG :
     begin
      Inc(SP0); SP0.i8 := Data[CMD.ARG ].i8;
      Inc(SP0); SP0.i8 := Globals[CMD.ARG2].i8;
      Inc(CMD);
     end;
    CID_PUSH_GG :
     begin
      Inc(SP0); SP0.i8 := Globals[CMD.ARG ].i8;
      Inc(SP0); SP0.i8 := Globals[CMD.ARG2].i8;
      Inc(CMD);
     end;
    {$endregion}
    {$region ' POP STORE MOV TAKE PASS DUP SWAP '}
    CID_POP :
     begin
      Dec(SP0);
      Inc(CMD);
     end;
    CID_POP_G :
     begin
      Globals[CMD.ARG].i8 := SP0.i8;
      Dec(SP0);
      Inc(CMD);
     end;
    CID_POP_L :
     begin
      Data[CMD.ARG].i8 := SP0.i8;
      Dec(SP0);
      Inc(CMD);
     end;
    CID_STORE_G :
     begin
      Globals[CMD.ARG].i8 := SP0.i8;
      Inc(CMD);
     end;
    CID_STORE_L :
     begin
      Data[CMD.ARG].i8 := SP0.i8;
      Inc(CMD);
     end;
    CID_MOV_CG :
     begin
      Globals[CMD.MOV_TO].i8 := CMD.MOV_VAL;
      Inc(CMD);
     end;
    CID_MOV_CL :
     begin
      Data[CMD.MOV_TO].i8 := CMD.MOV_VAL;
      Inc(CMD);
     end;
    CID_MOV_GG :
     begin
      Globals[CMD.MOV_TO].i8 := Globals[CMD.MOV_FROM].i8;
      Inc(CMD);
     end;
    CID_MOV_LL :
     begin
      Data[CMD.MOV_TO].i8 := Data[CMD.MOV_FROM].i8;
      Inc(CMD);
     end;
    CID_MOV_GL :
     begin
      Data[CMD.MOV_TO].i8 := Globals[CMD.MOV_FROM].i8;
      Inc(CMD);
     end;
    CID_MOV_LG :
     begin
      Globals[CMD.MOV_TO].i8 := Data[CMD.MOV_FROM].i8;
      Inc(CMD);
     end;
    CID_TAKE :
     begin
      Inc(SP0);
      SP0.i8 := _caller_.SP0.i8;
      Dec(_caller_.SP0);
      Inc(CMD);
     end;
    CID_PASS :
     begin
      Inc(_caller_.SP0);
      _caller_.SP0.i8 := SP0.i8;
      Dec(SP0);
      Inc(CMD);
     end;
    CID_DUP :
     begin
      Inc(SP1);
      SP1.i8 := SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_SWAP :
     begin
      Dec(SP1);
      TMP.i8 := SP1.i8;
      SP1.i8 := SP0.i8;
      SP0.i8 := TMP.i8;
      Inc(CMD);
     end;
    {$endregion}
    {$region ' HEAP operations '}
    CID_ADDR :
     begin
      Data[CMD.ARR_TO]._Ptr := Data[CMD.ARR_FROM]._Ptr + SP0.i8;
      Dec(SP0);
      Inc(CMD);
     end;
    CID_SIZE :
     begin
      Inc(SP0);
      SP0.i8 := Data[CMD.ARR_FROM].Size;
      Inc(CMD);
     end;
    CID_GET1 :
     begin
      Inc(SP0);
      //SP0.Int8 := 0;
      SP0.Ch := Data[CMD.ARR_FROM].Data^.Ch;
      Inc(CMD);
     end;
    CID_GET8 :
     begin
      Inc(SP0);
      SP0.i8 := Data[CMD.ARR_FROM].Data^.i8;
      Inc(CMD);
     end;
    CID_SET1 :
     begin
      Data[CMD.ARR_FROM].Data^.Ch := SP0.Ch;
      Dec(SP0);
      Inc(CMD);
     end;
    CID_SET8 :
     begin
      Data[CMD.ARR_FROM].Data^.i8 := SP0.i8;
      Dec(SP0);
      Inc(CMD);
     end;
    CID_COPY :
     begin
      System.Move(Data[CMD.ARR_FROM].Data^,Data[CMD.ARR_TO].Data^,SP0.i8);
      Dec(SP0);
      Inc(CMD);
     end;
    CID_ALLOC :
     begin
      // System.AllocMem(L[CMD.LIDX_FROM].Ptr,SP0.Int8);
      System.GetMem(Data[CMD.ARR_FROM].Ptr,SP0.i8);
      Data[CMD.ARR_FROM].Size := SP0.i8;
      Dec(SP0);
      Inc(CMD);
     end;
    CID_REALLOC :
     begin
      System.ReallocMem(Data[CMD.ARR_FROM].Ptr,SP0.i8);
      Data[CMD.ARR_FROM].Size := SP0.i8;
      Dec(SP0);
      Inc(CMD);
     end;
    CID_FREE :
     begin
      System.FreeMem(Data[CMD.ARR_FROM].Ptr);
      Data[CMD.ARR_FROM].Ptr  := Nil;
      Data[CMD.ARR_FROM].Size := 0;
      Inc(CMD);
     end;
    {$endregion}
    {$region ' JN '}
    CID_JN :
     begin
      Dec(SP1);
      case CMD.COND of
       DATA_INT   + COND_E  : if SP1.i8  =  SP0.i8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_INT   + COND_NE : if SP1.i8  <> SP0.i8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_INT   + COND_G  : if SP1.i8  >  SP0.i8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_INT   + COND_L  : if SP1.i8  <  SP0.i8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_INT   + COND_GE : if SP1.i8  >= SP0.i8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_INT   + COND_LE : if SP1.i8  <= SP0.i8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_FLOAT + COND_E  : if SP1.r8  =  SP0.r8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_FLOAT + COND_NE : if SP1.r8  <> SP0.r8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_FLOAT + COND_G  : if SP1.r8  >  SP0.r8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_FLOAT + COND_L  : if SP1.r8  <  SP0.r8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_FLOAT + COND_GE : if SP1.r8  >= SP0.r8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_FLOAT + COND_LE : if SP1.r8  <= SP0.r8 then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_CHAR  + COND_E  : if SP1.Ch  =  SP0.Ch then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_CHAR  + COND_NE : if SP1.Ch  <> SP0.Ch then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_CHAR  + COND_G  : if SP1.Ch  >  SP0.Ch then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_CHAR  + COND_L  : if SP1.Ch  <  SP0.Ch then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_CHAR  + COND_GE : if SP1.Ch  >= SP0.Ch then Inc(CMD) else CMD := @CODE[CMD.JUMP];
       DATA_CHAR  + COND_LE : if SP1.Ch  <= SP0.Ch then Inc(CMD) else CMD := @CODE[CMD.JUMP];
      end;
      Dec(SP0,2);
     end;
    {$endregion}
    {$region ' CMP '}
    CID_CMP :
     begin
      Dec(SP1);
      case CMD.COND of
       DATA_INT   + COND_E  : SP1.i8 := Int64(SP1.i8 =  SP0.i8);
       DATA_INT   + COND_NE : SP1.i8 := Int64(SP1.i8 <> SP0.i8);
       DATA_INT   + COND_G  : SP1.i8 := Int64(SP1.i8 >  SP0.i8);
       DATA_INT   + COND_L  : SP1.i8 := Int64(SP1.i8 <  SP0.i8);
       DATA_INT   + COND_GE : SP1.i8 := Int64(SP1.i8 >= SP0.i8);
       DATA_INT   + COND_LE : SP1.i8 := Int64(SP1.i8 <= SP0.i8);
       DATA_FLOAT + COND_E  : SP1.i8 := Int64(SP1.r8 =  SP0.r8);
       DATA_FLOAT + COND_NE : SP1.i8 := Int64(SP1.r8 <> SP0.r8);
       DATA_FLOAT + COND_G  : SP1.i8 := Int64(SP1.r8 >  SP0.r8);
       DATA_FLOAT + COND_L  : SP1.i8 := Int64(SP1.r8 <  SP0.r8);
       DATA_FLOAT + COND_GE : SP1.i8 := Int64(SP1.r8 >= SP0.r8);
       DATA_FLOAT + COND_LE : SP1.i8 := Int64(SP1.r8 <= SP0.r8);
       DATA_CHAR  + COND_E  : SP1.i8 := Int64(SP1.Ch =  SP0.Ch);
       DATA_CHAR  + COND_NE : SP1.i8 := Int64(SP1.Ch <> SP0.Ch);
       DATA_CHAR  + COND_G  : SP1.i8 := Int64(SP1.Ch >  SP0.Ch);
       DATA_CHAR  + COND_L  : SP1.i8 := Int64(SP1.Ch <  SP0.Ch);
       DATA_CHAR  + COND_GE : SP1.i8 := Int64(SP1.Ch >= SP0.Ch);
       DATA_CHAR  + COND_LE : SP1.i8 := Int64(SP1.Ch <= SP0.Ch);
      end;
      Dec(SP0);
      Inc(CMD);
     end;
    {$endregion}
    {$region ' JZ JNZ JLZ JGZ JUMPI JUMPS '}
    CID_JZ :
     begin
      if SP0.i8=0 then CMD := @CODE[CMD.JUMP] else Inc(CMD);
      Dec(SP0);
     end;
    CID_JNZ :
     begin
      if SP0.i8<>0 then CMD := @CODE[CMD.JUMP] else Inc(CMD);
      Dec(SP0);
     end;
    CID_JLZ :
     begin
      if SP0.i8<0 then CMD := @CODE[CMD.JUMP] else Inc(CMD);
      Dec(SP0);
     end;
    CID_JGZ :
     begin
      if SP0.i8>0 then CMD := @CODE[CMD.JUMP] else Inc(CMD);
      Dec(SP0);
     end;
    CID_JUMPS :
     begin
      CMD := @CODE[SP0.i8];
      Dec(SP0);
     end;
    CID_JUMPI : CMD := @CODE[CMD.JUMP];
    {$endregion}
    {$region ' CALL '}
    CID_CALL :
     begin
      // call function ........................................................
      if CMD.FUN_TYP = FUNC_SYSTEM then Result := SysFuncs[CMD.FUN_IDX](@self) else
       begin
        // get function frame
        if CMD.FUN_TYP=FUNC_USER_A
         then FUN := @PROG.F[CMD.FUN_IDX]
         else begin FUN := @PROG.F[SP0.i8]; Dec(SP0); end;
        // try to execute
        if FUN.USED then
         begin
          GetMem(FUN,SizeOf(TFrame));                             // allocate memory
          FUN.ID            := PROG.F[CMD.FUN_IDX].ID;            // copy function identifier
          Pointer(FUN.CODE) := Pointer(PROG.F[CMD.FUN_IDX].CODE); // copy link to code (suppress ARC!!!)
          FUN.LCNT          := PROG.F[CMD.FUN_IDX].LCNT;          // copy local storage size
          FUN.SCNT          := PROG.F[CMD.FUN_IDX].SCNT;          // copy stack size
          FUN.PROG          := PROG;                              // copy link to program
          FUN.USED          := false;                             // new instance not used by default
          Result            := FUN.Execute(@self);                // execute
          FreeMem(FUN);
         end
        else Result := FUN.Execute(@Self);
       end;
      // check result
      if Result=EID_RET then Inc(CMD) else
       begin
        { TODO : implement error handling }
        Exit(Result);
       end;
     end;
    {$endregion}
    {$region ' RET '}
    CID_RET :
     begin
      USED := false;
      Exit(EID_RET);
     end;
    {$endregion}
    {$region ' HALT '}
    CID_HALT :
     begin
      USED := false;
      Exit(EID_HALT);
     end;
    {$endregion}
    {$region ' INTEGER arithmetic '}
    CID_IADD :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 + SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_ISUB :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 - SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_IMUL :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 * SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_IDIV :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 div SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_MOD :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 mod SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_INC :
     begin
      Inc(SP0.i8);
      Inc(CMD);
     end;
    CID_DEC :
     begin
      Dec(SP0.i8);
      Inc(CMD);
     end;
    CID_INCL :
     begin
      Inc(Data[CMD.ARG].i8,CMD.ARG2);
      Inc(CMD);
     end;
    CID_DECL :
     begin
      Dec(Data[CMD.ARG].i8,CMD.ARG2);
      Inc(CMD);
     end;
    CID_IABS :
     begin
      SP0.i8 := Abs(SP0.i8);
      Inc(CMD);
     end;
    CID_INEG :
     begin
      SP0.i8 := -SP0.i8;
      Inc(CMD);
     end;
    {$endregion}
    {$region ' BITWISE operations '}
    CID_NOT :
     begin
      SP0.i8 := not SP0.i8;
      Inc(CMD);
     end;
    CID_AND :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 and SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_OR :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 or SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_XOR :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 xor SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_SHL :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 shl SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_SHR :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 shr SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_ROTL  : Inc(CMD);
    CID_ROTR  : Inc(CMD);
    CID_REV   : Inc(CMD);
    CID_MASK : // stack order : SP-2 = shift; SP-1 = mask; SP0 = base;
     begin
      Dec(SP1);
      SP0.i8 := SP0.i8 and SP1.i8;
      Dec(SP1);
      SP1.i8 := SP0.i8 shr SP1.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_BTEST :
     begin
      Dec(SP1);
      SP1.i8 := (SP1.i8 and (1 shl SP0.i8)) shr SP0.i8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_BTOG :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 xor (1 shl SP0.i8);
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_BON :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 or (1 shl SP0.i8);
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_BOFF :
     begin
      Dec(SP1);
      SP1.i8 := SP1.i8 and ((1 shl SP0.i8) xor $FFFFFFFFFFFFFFFF);
      SP0 := SP1;
      Inc(CMD);
     end;
    {$endregion}
    {$region ' REAL arithmetic '}
    CID_FADD :
     begin
      Dec(SP1);
      SP1.r8 := SP1.r8 + SP0.r8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_FSUB :
     begin
      Dec(SP1);
      SP1.r8 := SP1.r8 - SP0.r8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_FMUL :
     begin
      Dec(SP1);
      SP1.r8 := SP1.r8 * SP0.r8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_FDIV :
     begin
      Dec(SP1);
      SP1.r8 := SP1.r8 / SP0.r8;
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_POW :
     begin
      Dec(SP1);
      SP1.r8 := System.Math.Power(SP1.r8,SP0.r8);
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_LOG :
     begin
      Dec(SP1);
      SP1.r8 := System.Math.LogN(SP1.r8,SP0.r8);
      SP0 := SP1;
      Inc(CMD);
     end;
    CID_SIN :
     begin
      SP0.r8 := Sin(SP0.r8);
      Inc(CMD);
     end;
    CID_COS :
     begin
      SP0.r8 := Cos(SP0.r8);
      Inc(CMD);
     end;
    CID_ASIN :
     begin
      SP0.r8 := System.Math.Arcsin(SP0.r8);
      Inc(CMD);
     end;
    CID_ACOS :
     begin
      SP0.r8 := System.Math.Arccos(SP0.r8);
      Inc(CMD);
     end;
    CID_SEED :
     begin
      Randomize;
      Inc(CMD);
     end;
    CID_RAND :
     begin
      Inc(SP0);
      SP0.r8 := Random;
      Inc(CMD);
     end;
    CID_FABS :
     begin
      SP0.r8 := Abs(SP0.r8);
      Inc(CMD);
     end;
    CID_FNEG :
     begin
      SP0.r8 := -SP0.r8;
      Inc(CMD);
     end;
    CID_INT :
     begin
      SP0.r8 := Int(SP0.r8);
      Inc(CMD);
     end;
    CID_FRAC :
     begin
      SP0.r8 := Frac(SP0.r8);
      Inc(CMD);
     end;
    {$endregion}
    {$region ' INT/REAL convertions '}
    CID_ITOF :
     begin
      SP0.r8 := SP0.i8;
      Inc(CMD);
     end;
    CID_FTOI :
     begin
      SP0.i8 := Round(SP0.r8);
      Inc(CMD);
     end;
    {$endregion}
    {$region ' ASYNC operations '}
    { TODO : implement async stuff }
    CID_ASYNC : Inc(CMD);
    CID_WAIT  : Inc(CMD);
    CID_SLEEP : Inc(CMD);
    CID_ENTER : Inc(CMD);
    CID_LEAVE : Inc(CMD);
    {$endregion}
    {$region ' NOPE '}
    CID_NOPE : Inc(CMD);
    {$endregion}
   end;
   goto CommandLoop;
  end;

// ************************************************************************** //
//  TRuntime                                                                  //
// ************************************************************************** //

 constructor TProgram.Create;
  begin
   inherited Create;
   ID.Clear();
   F  := Nil;
   FN := TDictionary<AnsiString,Int64>.Create;
  end;

 destructor TProgram.Destroy;
  var i : Int32;
  begin
   for i:=0 to High(F) do
    begin
     F[i].CODE := Nil;
     F[i].Free;
    end;
   F := Nil;
   FreeAndNil(FN);
   inherited Destroy;
  end;

 function TProgram.Execute(const FIDX:Int64; const Args:TArray<AnsiString>):Int32;
  var
   a : TStorage;
   i : Int32;
  begin
   if (FIDX<0) or (FIDX>High(F)) then Exit(EID_FunctionNotFound);
   if Args<>Nil then
    begin
     SetLength(a,Length(Args));
     for i:=0 to High(a) do
      begin
       //Alloc_String(Args[i],a[i]);
       a[i].StrPtr := @Args[i][1];
       a[i].StrLen := Length(Args[i])+1;
      end;
     F[FIDX].Data[F[FIDX].LCNT].Data := @a[0];
     F[FIDX].Data[F[FIDX].LCNT].Size := Length(a) * SizeOf(TData);
    end
   else F[FIDX].Data[F[FIDX].LCNT].Clear();
   Result := F[FIDX].Execute(Nil);
  end;

 function TProgram.Execute(const FNAME:AnsiString; const Args:TArray<AnsiString>):Int32;
  var IDX : Int64;
  begin
   if FN.TryGetValue(AnsiUpperCase(FNAME),IDX)
    then Result := Execute(IDX,Args)
    else Result := EID_FunctionNotFound;
  end;

end.
