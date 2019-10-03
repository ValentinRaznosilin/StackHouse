{******************************************************************************}
{* Project : "StackHouse" virtual stack-machine                               *}
{* Unit    : Lexical stuff                                                    *}
{* Change  : 03.10.2019 (1251 lines)                                          *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2019 DelphiRunner                                            *}
{******************************************************************************}

unit SH.Parser.Base;

 interface

 uses
  // system
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.Math,
  // project
  SH.Codes,
  SH.Types,
  SH.Utils;

 const

  MaxTokenInLine = 12; // see TSourceLine items

  {$region ' commands names in source code '}
  CMD_NOPE    = 'NOPE';
  CMD_PUSH    = 'PUSH';
  CMD_POP     = 'POP';
  CMD_STORE   = 'STORE';
  CMD_MOV     = 'MOV';
  CMD_TAKE    = 'TAKE';
  CMD_PASS    = 'PASS';
  CMD_DUP     = 'DUP';
  CMD_SWAP    = 'SWAP';
  CMD_ADDR    = 'ADDR';
  CMD_SIZE    = 'SIZE';
  CMD_GET1    = 'GETCHAR';
  CMD_GET8    = 'GETDATA';
  CMD_SET1    = 'SETCHAR';
  CMD_SET8    = 'SETDATA';
  CMD_COPY    = 'COPY';
  CMD_ALLOC   = 'ALLOC';
  CMD_REALLOC = 'REALLOC';
  CMD_FREE    = 'FREE';
  CMD_JZ      = 'JZ';
  CMD_JNZ     = 'JNZ';
  CMD_JLZ     = 'JLZ';
  CMD_JGZ     = 'JGZ';
  CMD_JUMP    = 'JUMP';
  CMD_COMPARE = 'CMP';
  CMD_JN      = 'JN';
  CMD_CALL    = 'CALL';
  CMD_RET     = 'RET';
  CMD_HALT    = 'HALT';
  CMD_INC     = 'INC';
  CMD_DEC     = 'DEC';
  CMD_MOD     = 'MOD';
  CMD_INEG    = 'INEG';
  CMD_IADD    = 'IADD';
  CMD_ISUB    = 'ISUB';
  CMD_IMUL    = 'IMUL';
  CMD_IDIV    = 'IDIV';
  CMD_IABS    = 'IABS';
  CMD_FNEG    = 'FNEG';
  CMD_FADD    = 'FADD';
  CMD_FSUB    = 'FSUB';
  CMD_FMUL    = 'FMUL';
  CMD_FDIV    = 'FDIV';
  CMD_FABS    = 'FABS';
  CMD_POW     = 'POW';
  CMD_LOG     = 'LOG';
  CMD_SIN     = 'SIN';
  CMD_COS     = 'COS';
  CMD_ASIN    = 'ASIN';
  CMD_ACOS    = 'ACOS';
  CMD_SEED    = 'SEED';
  CMD_RAND    = 'RAND';
  CMD_INT     = 'INT';
  CMD_FRAC    = 'FRAC';
  CMD_NOT     = 'NOT';
  CMD_AND     = 'AND';
  CMD_OR      = 'OR';
  CMD_XOR     = 'XOR';
  CMD_SHL     = 'SHL';
  CMD_SHR     = 'SHR';
  CMD_ROTL    = 'ROTL';
  CMD_ROTR    = 'ROTR';
  CMD_REV     = 'REV';
  CMD_MASK    = 'BIT_#';
  CMD_BITEST  = 'BIT_?';
  CMD_BITOGL  = 'BIT_!';
  CMD_BITON   = 'BIT_1';
  CMD_BITOFF  = 'BIT_0';
  CMD_ITOF    = 'ITOF';
  CMD_FTOI    = 'FTOI';
  CMD_ASYNC   = 'ASYNC';
  CMD_WAIT    = 'WAIT';
  CMD_SLEEP   = 'SLEEP';
  CMD_ENTER   = 'ENTER';
  CMD_LEAVE   = 'LEAVE';
  {$endregion}

 type

  // single token (lexeme) ****************************************************
  PToken = ^Token;
  Token = record

   STR : string; // original uppercased text (from source line)
   TYP : UInt8;  // token type (see TOK_... constants)
   VAL : TData;  // optional integer/float representation

   procedure Clear;
   procedure Print(const idx:Int32 = -1);
   function  Identify(out Error:string):Boolean;

  end;

  // array of tokens **********************************************************
  Tokens = record

   private

   function GetTokenByIndex(Index:Int32):Token;

   public

   Items : array [0..MaxTokenInLine-1] of Token;
   Count : UInt8;

   procedure Clear;
   procedure Print;
   function  Append(const T:Token):Boolean;
   function  ToString:string;

   property I[Index:Int32]:Token read GetTokenByIndex; default;

  end;

  // single source line (original text, line number, tokens) ******************
  PSourceLine = ^TSourceLine;
  TSourceLine = record

   public

    ID    : UInt32;      // position in original source code
    Text  : string;      // source line
    Toks  : Tokens;      // tokens
    Next  : PSourceLine; // auxiliary field for organizing a linked list

    procedure Clear;
    procedure Print;
    procedure ResetText;
    function  Parse(const S:string; out Error:string; const RawQt:Boolean):Boolean;
    function  Encode(out C:TCommand; out Error:string):Boolean;

  end;

  SourceLinePredicat = reference to function (const P:PSourceLine):Boolean;

  // single file of source code ***********************************************
  TSourceLines = record

   Head : PSourceLine;
   Tail : PSourceLine;

   function  Load(const SRC:TStringList; out Error:string):UInt32; overload;
   function  Load(const FN:string; out Error:string):UInt32; overload;
   procedure ShiftGlobals(const Shift:Int32);
   procedure Add(const L:TSourceLine); overload; inline;
   procedure Add(const P:PSourceLine); overload; inline;
   function  Count(const FromP:PSourceLine=Nil):UInt32;
   function  Empty:Boolean; inline;
   function  Prev(const P:PSourceLine):PSourceLine;
   function  Look(const FromP:PSourceLine; const Found:SourceLinePredicat):PSourceLine;
   function  LookByTokName(const FromP:PSourceLine; const Idx:Uint8; const Name:string):PSourceLine;
   function  LookByTokType(const FromP:PSourceLine; const Idx:Uint8; const Typ:Uint8):PSourceLine;
   function  CheckRange(const FromP,ToP:PSourceLine):Boolean;
   procedure Extract(const P:PSourceLine); overload;
   function  Extract(const Found:SourceLinePredicat):TSourceLines; overload;
   function  Extract(const FromP,ToP:PSourceLine):TSourceLines; overload;
   procedure Replace(const P:PSourceLine; var SL:TSourceLines);
   function  ToList(const Ident:Int32; const LineNumbers:Boolean):TStringList;
   procedure Print;
   procedure Clear;
   procedure Free;

  end;

 implementation

 uses SH.Runtime, SH.System;

 function Valid_HeapAddress(const P:TSourceLine; const ArgCnt:Int32; var C:TCommand; var E:string):Boolean;
  begin
   Result := false;
   if ArgCnt=2 then
    begin
     if P.Toks.Count<2          then E :='1st address is missing' else
     if P.Toks.Count<3          then E :='2nd address is missing' else
     if P.Toks[1].TYP<>TOK_LIDX then E :='1st address is invalid' else
     if P.Toks[2].TYP<>TOK_LIDX then E :='2st address is invalid' else
      begin
       C.ARR_FROM := P.Toks[1].VAL.i8;
       C.ARR_TO   := P.Toks[2].VAL.i8;
       Exit(true);
      end;
    end
   else
    begin
     if P.Toks.Count<2          then E :='Address is missing' else
     if P.Toks[1].TYP<>TOK_LIDX then E :='Address is invalid' else
      begin
       C.ARR_FROM := P.Toks[1].VAL.i8;
       Exit(true);
      end;
    end;
  end;

 // return :
 // -1 - unknown or error
 //  0 - constant
 //  1 - local index
 //  2 - global index
 function Valid_PushArgument(const T:Token; var Arg:Int64; var E:string):Int32;
  begin
   case T.TYP of
    TOK_INT :
     begin
      Arg := T.VAL.i8;
      Exit(0);
     end;
    TOK_FLOAT :
     begin
      TData(Arg) := TData(T.VAL.r8);
      Exit(0);
     end;
    TOK_STRING :
     if not Alloc_String(PrepareString(T.STR),TData(Arg)) then
      begin
       E := 'Can not allocate string';
       Exit(-1);
      end
     else Exit(0);
    TOK_BINARY :
     if not Alloc_Stream(T.STR,TData(Arg)) then
      begin
       E := 'Can not allocate binary stream';
       Exit(-1);
      end
     else Exit(0);
    TOK_LIDX :
     begin
      Arg := T.VAL.i8;
      Exit(1);
     end;
    TOK_GIDX :
     begin
      Arg := T.VAL.i8;
      Exit(2);
     end;
    TOK_GNAME :
     if not GloNames.TryGetValue(T.STR,Arg) then
      begin
       E := Format('Global variable "%s" not found',[T.STR]);
       Exit(-1);
      end
     else Exit(2);
    else
     E := 'Push argument is invalid';
     Exit(-1);
   end;
  end;

 function Valid_Push1(const P:TSourceLine; var C:TCommand; var E:string):Boolean;
  begin
   case Valid_PushArgument(P.Toks[1],C.ARG,E) of
    -1 : Exit(false);
     0 : C.ID := CID_PUSH_C;
     1 : C.ID := CID_PUSH_L;
     2 : C.ID := CID_PUSH_G;
   end;
   Exit(true);
  end;

 function Valid_Push2(const P:TSourceLine; var C:TCommand; var E:string):Boolean;
  begin
   case Valid_PushArgument(P.Toks[1],C.ARG,E) of
    -1 : Exit(false);
     0 : case Valid_PushArgument(P.Toks[2],C.ARG2,E) of
          -1 : Exit(false);
           0 : C.ID := CID_PUSH_CC;
           1 : C.ID := CID_PUSH_CL;
           2 : C.ID := CID_PUSH_CG;
         end;
     1 : case Valid_PushArgument(P.Toks[2],C.ARG2,E) of
          -1 : Exit(false);
           0 : C.ID := CID_PUSH_LC;
           1 : C.ID := CID_PUSH_LL;
           2 : C.ID := CID_PUSH_LG;
         end;
     2 : case Valid_PushArgument(P.Toks[2],C.ARG2,E) of
          -1 : Exit(false);
           0 : C.ID := CID_PUSH_GC;
           1 : C.ID := CID_PUSH_GL;
           2 : C.ID := CID_PUSH_GG;
         end;
   end;
   Result := true;
  end;

 function Valid_Pop(const P:TSourceLine; var C:TCommand; var E:string):Boolean;
  begin
   Result := false;
   if P.Toks.Count<2 then E := 'Pop argument is missing' else
   case P.Toks[1].TYP of
    TOK_LIDX :
     begin
      C.ID := CID_POP_L;
      TData(C.ARG) := TData(P.Toks[1].VAL.i8);
      Exit(true);
     end;
    TOK_GIDX :
     begin
      C.ID := CID_POP_G;
      TData(C.ARG) := TData(P.Toks[1].VAL.i8);
      Exit(true);
     end;
    else E := 'Pop argument is invalid';
   end;
  end;

 function Valid_Store(const P:TSourceLine; var C:TCommand; var E:string):Boolean;
  begin
   Result := false;
   if P.Toks.Count<2 then E := 'Store argument is missing' else
   case P.Toks[1].TYP of
    TOK_LIDX :
     begin
      C.ID := CID_STORE_L;
      TData(C.ARG) := TData(P.Toks[1].VAL.i8);
      Exit(true);
     end;
    TOK_GIDX :
     begin
      C.ID := CID_STORE_G;
      TData(C.ARG) := TData(P.Toks[1].VAL.i8);
      Exit(true);
     end;
    else E := 'Store argument is invalid';
   end;
  end;

 function Valid_Mov(const P:TSourceLine; var C:TCommand; var E:string):Boolean;

   function MOV_TO(const I:Uint8):Boolean;
    var L : Boolean;
    begin
     case P.Toks.Items[2].TYP of
      TOK_LIDX : C.MOV_TO := P.Toks[2].VAL.i8;
      TOK_GIDX : C.MOV_TO := P.Toks[2].VAL.i8;
      else
       begin
        E := 'Move "TO" argument is invalid';
        Exit(false);
       end;
     end;
     //
     L := P.Toks.Items[2].TYP = TOK_LIDX;
     case I of
      0 : if L then C.ID := CID_MOV_CL else C.ID := CID_MOV_CG;
      1 : if L then C.ID := CID_MOV_LL else C.ID := CID_MOV_LG;
      2 : if L then C.ID := CID_MOV_GL else C.ID := CID_MOV_GG;
     end;
     Exit(true);
    end;

  begin
   Result := false;
   if P.Toks.Count<3 then E := 'Move argument is missing' else
   case P.Toks[1].TYP of
    TOK_INT :
     begin
      C.MOV_VAL := P.Toks[1].VAL.i8;
      Result := MOV_TO(0);
     end;
    TOK_FLOAT :
     begin
      TData(C.MOV_VAL) := TData(P.Toks[1].VAL.r8);
      Result := MOV_TO(0);
     end;
    TOK_STRING :
     begin
      if Alloc_String(PrepareString(P.Toks[1].STR),TData(C.MOV_VAL))
       then Result := MOV_TO(0)
       else E := 'Move "FROM" argument is invalid';
     end;
    TOK_BINARY :
     begin
      if Alloc_Stream(P.Toks[1].STR,TData(C.MOV_VAL))
       then Result := MOV_TO(0)
       else E := 'Move "FROM" argument is invalid';
     end;
    TOK_LIDX :
     begin
      C.MOV_FROM := P.Toks[1].VAL.i8;
      Result := MOV_TO(1);
     end;
    TOK_GIDX :
     begin
      C.MOV_FROM := P.Toks[1].VAL.i8;
      Result := MOV_TO(2);
     end;
    else E := 'Move "FROM" argument is invalid';
   end;
  end;

 function Valid_JumpIndex(const P:TSourceLine; const I:Int32; var C:TCommand; var E:string):Boolean;
  begin
   Result := false;
   if I>P.Toks.Count         then E :='Jump index is missing' else
   if P.Toks[I].TYP<>TOK_INT then E :='Jump index is invalid' else
    begin
     C.JUMP := P.Toks[I].VAL.i8;
     Result := true;
    end;
  end;

 function Valid_DataType(const P:TSourceLine; const I:Int32; var C:TCommand; var E:string):Boolean;
  begin
   Result := false;
   if I>P.Toks.Count then E := 'Data type is missing' else
   if (P.Toks[I].TYP<>TOK_IDENT) or
      (not StrInList(P.Toks[I].STR,['INT','FLOAT','CHAR']))
    then E := 'Data type is invalid' else
    begin
     if P.Toks[I].STR='INT'   then C.COND := C.COND + DATA_INT   else
     if P.Toks[I].STR='FLOAT' then C.COND := C.COND + DATA_FLOAT else
     if P.Toks[I].STR='CHAR'  then C.COND := C.COND + DATA_CHAR;
     Result := true;
    end;
  end;

 function Valid_CondType(const P:TSourceLine; const I:Int32; var C:TCommand; var E:string):Boolean;
  begin
   Result := false;
   if I>P.Toks.Count then E := 'Condition type is missing' else
   if (P.Toks[I].TYP<>TOK_IDENT) or
      (not StrInList(P.Toks[I].STR,['==','!=','>','<','>=','<=']))
    then E := 'Condition type is invalid' else
    begin
     if P.Toks[I].STR='==' then C.COND := C.COND + COND_E  else
     if P.Toks[I].STR='!=' then C.COND := C.COND + COND_NE else
     if P.Toks[I].STR= '>' then C.COND := C.COND + COND_G  else
     if P.Toks[I].STR= '<' then C.COND := C.COND + COND_L  else
     if P.Toks[I].STR='>=' then C.COND := C.COND + COND_GE else
     if P.Toks[I].STR='<=' then C.COND := C.COND + COND_LE;
     Result := true;
    end;
  end;

 function Valid_Call(const P:TSourceLine; var C:TCommand; var E:string):Boolean;
  var i : Int64;
  begin
   Result := false;
   if P.Toks.Count<2 then E := 'Call index is missing' else
   if (P.Toks[1].TYP<>TOK_FIDX) and (P.Toks[1].TYP<>TOK_GNAME) then E := 'Call index/name is invalid' else
   if P.Toks[1].TYP=TOK_FIDX then
    begin
     C.FUN_TYP := FUNC_USER_A;
     C.FUN_IDX := P.Toks[1].VAL.i8;
     Exit(true);
    end else
   if P.Toks[1].TYP=TOK_GNAME then
    begin
     C.FUN_TYP := FUNC_SYSTEM;
     if SysNames.TryGetValue(P.Toks[1].STR,i) then
      begin
       C.FUN_IDX := i;
       Exit(true);
      end
     else E := Format('System function "%s" not found',[P.Toks[1].STR]);
    end;
  end;

 function Valid_LxNx(const P:TSourceLine; var C:TCommand; var E:string):Boolean;
  begin
   Result := false;
   //
   if P.Toks[1].TYP<>TOK_LIDX then
    begin
     E := 'Invalid local index';
     Exit;
    end;
   C.ARG := P.Toks[1].VAL.i8;
   //
   if P.Toks[2].TYP<>TOK_INT then
    begin
     E := 'Invalid offset';
     Exit;
    end;
   C.ARG2 := P.Toks[2].VAL.i8;
   Result := true;
  end;

// ************************************************************************** //
//  Token                                                                     //
// ************************************************************************** //

 procedure Token.Clear;
  begin
   STR    := '';
   TYP    := TOK_UNDEF;
   VAL.i8 := 0;
  end;

 procedure Token.Print(const idx:Int32);
  var s : string;
  begin
   case TYP of
    TOK_UNDEF  : s := 'UNDEF';
    TOK_INT    : s := 'INT';
    TOK_FLOAT  : s := 'FLOAT';
    TOK_STRING : s := 'STRING';
    TOK_IDENT  : s := 'IDENT';
    TOK_GNAME  : s := 'GNAME';
    TOK_LIDX   : s := 'LIDX';
    TOK_GIDX   : s := 'GIDX';
    TOK_FIDX   : s := 'FIDX';
    TOK_BINARY : s := 'BINARY';
    TOK_MACRO  : s := 'MACRO';
    TOK_LABEL  : s := 'LABEL';
   end;
   if idx < 0
    then WriteLn(Format('%8s %s',[s,STR]))
    else WriteLn(Format('%4d%8s %s',[idx,s,STR]));
  end;

 // const values:
 // "NOT_A_NUMBER" "POS_INFINITY" "NEG_INFINITY" : double;
 // "INT64_MAX" "INT64_MIN" : Int64
 function Token.Identify(out Error:string):Boolean;
  var
   L : Int32;
   i : Integer;
   c : Char;
  begin
   Error := '';
   // if token already recognized then don't touch it ..........................
   if TYP<>TOK_UNDEF then Exit(true);
   // is empty source ? ........................................................
   L := Length(STR);
   if L=0 then
    begin
     Error := 'Empty token';
     Exit(false);
    end;
   // is integer in hexadecimal representation ? ...............................
   if (L>2) and (STR[1]=_INT) and (STR[2]=_HEX) then
    begin
     if L>18 then
      begin
       Error := 'Too much digits in hex value';
       Exit(false);
      end;
     // convert hex string to integer
     if not TryHexToInt64(STR,VAL.i8) then
      begin
       Error := 'Invalid hexadecimal value';
       Exit(false);
      end;
     //
     TYP := TOK_INT;
     STR := _INT + _HEX + HexComplementTo16(STR);
    end else
   // is integer in decimal representation ? ..................................
   if TryStrToInt64(STR,VAL.i8) then TYP := TOK_INT else
   // is integer constant ? ......................................................
   if (STR='INT64_MAX') or (STR='INT64_MIN') or (STR='NULL') or (STR='TRUE') or (STR='FALSE') then
    begin
     TYP := TOK_INT;
     if STR='INT64_MAX' then VAL.i8 := VAL.i8.MaxValue else
     if STR='INT64_MIN' then VAL.i8 := VAL.i8.MinValue else
     if STR='TRUE'      then VAL.i8 := 1
      else VAL.i8 := 0
    end else
   // is real ? ...............................................................
   if TryStrToFloat(STR,VAL.r8) then TYP := TOK_FLOAT else
   // is real constant ? ......................................................
   if (STR='NOT_A_NUMBER') or (STR='POS_INFINITY') or (STR='NEG_INFINITY') then
    begin
     TYP := TOK_FLOAT;
     if STR='NOT_A_NUMBER' then VAL.r8 := System.Math.NaN else
     if STR='POS_INFINITY' then VAL.r8 := System.Math.Infinity else VAL.r8 := System.Math.NegInfinity;
    end else
   // is global name ? ........................................................
   if STR[1]=_SYS then TYP := TOK_GNAME else
   // is index ? ..............................................................
   if (L>2) and (STR[1]=_IDX) and (STR[2] in [_LOC,_GLO,_FUN]) then
    begin
     if TryStrToInt(RightStr(STR,Length(STR)-2),i) then
      begin
       if i<0 then
        begin
         Error := 'Index value must be >= 0';
         Exit(false);
        end;
       VAL.i8 := i;
      end
     else
      begin
       Error := 'Invalid index value';
       Exit(false);
      end;
     if STR[2]=_LOC then TYP := TOK_LIDX else
     if STR[2]=_GLO then TYP := TOK_GIDX else
     if STR[2]=_FUN then TYP := TOK_FIDX else
      begin
       Error := 'Invalid index type';
       Exit(false);
      end;
    end else
   // is binary stream ? ......................................................
   if (L>2) and (STR[1]=_INT) and (STR[2]=_BIN) then
    begin
     TYP := TOK_BINARY;
     STR := _INT + _BIN + BinComplementTo16(STR);
    end else
   // is macro name ? .........................................................
   if (L>1) and (STR[1]=_MAC) then TYP := TOK_MACRO else
   // is label name ? .........................................................
   if (L>1) and (STR[1]=_LAB) then TYP := TOK_LABEL else
   // consider this to be an identifier .......................................
   TYP := TOK_IDENT;
   Exit(true);
  end;

// ************************************************************************** //
//  Tokens                                                                    //
// ************************************************************************** //

 procedure Tokens.Clear;
  var i : Int32;
  begin
   for i:=0 to High(Items) do Items[i].Clear();
   Count := 0;
  end;

 procedure Tokens.Print;
  var i : Int32;
  begin
   for i:=0 to Count-1 do Items[i].Print(i);
  end;

 function Tokens.Append(const T:Token):Boolean;
  begin
   if Count >= MaxTokenInLine then Exit(false);
   Items[Count] := T;
   Inc(Count);
   Exit(true);
  end;

 function Tokens.ToString:string;
  var i : Int32;
  begin
   Result := '';
   for i:=0 to Count-1 do Result := Result + Items[i].STR + ' ';
  end;

 function Tokens.GetTokenByIndex(Index:Int32):Token;
  begin
   Result := Items[Index];
  end;

// ************************************************************************** //
//  TSourceLine                                                               //
// ************************************************************************** //

 procedure TSourceLine.Clear;
  begin
   ID   := 0;
   Text := '';
   Next := Nil;
   Toks.Clear();
  end;

 procedure TSourceLine.Print;
  begin
   WriteLn(Format('[%d] "%s"',[ID,Text]));
   Toks.Print();
  end;

 procedure TSourceLine.ResetText;
  begin
   Text := Toks.ToString();
  end;

 // RawQt = true  - copy quoted string as is
 // RawQt = false - cut quotes & replace escape characters for quoted string
 function TSourceLine.Parse(const S:string; out Error:string; const RawQt:Boolean):Boolean;
  var
   cf    : Int32;   // copy-from
   ct    : Int32;   // copy-to
   L     : Int32;   // length(S)
   f_in  : Boolean; // inside parameter ?
   f_qs  : Boolean; // inside quoted string like "xxx" ?
   T     : Token;   // current token
   C     : Char;    // current char

  function FinishCurrentToken:Boolean;
   begin
    f_in   := false;
    T.STR  := Copy(S,cf,ct-cf);
    T.STR  := UpperCase(T.STR);
    T.TYP  := TOK_UNDEF;
    if not T.Identify(Error) then
     begin
      Error := Format('Token "%s" is not identified: %s',[T.STR,Error]);
      Exit(false);
     end;
    if not Toks.Append(T) then
     begin
      Error := 'Too much tokens in single line';
      Exit(false);
     end;
    Exit(true);
   end;

  begin
   Clear;
   Error := '';
   if S='' then Exit(true);  // no tokens - no problems !
   f_in := false;
   f_qs := false;
   cf   := 1;
   ct   := 1;
   L    := Length(S);
   while ct <= L do
    begin
     C := S[ct];
     // is comment mark outside quote ? ........................................
     if (not f_qs) and (C = Comment) then break else
     // is quote ? .............................................................
     if C = Quote then
      begin
       if f_qs then
        begin
         if RawQt then T.STR := Copy(S,cf,ct-cf+1) else
          begin
           T.STR := Copy(S,cf+1,ct-cf-1);      // copy without quotes: "xx..x" -> xx..x
           T.STR := ReplaceEscapeChars(T.STR); // force replace escape characters
          end;
         T.TYP := TOK_STRING;
         if not Toks.Append(T) then
          begin
           Error := 'Too much tokens in single line';
           Exit(false);
          end;
        end
       else if f_in and (not FinishCurrentToken) then Exit(false);
       f_qs := not f_qs; // any quote (except after escape character) inverse f_qs
       cf   := ct;
      end else
     // is delimiter outside the "xxx" and we inside parameter? ................
     if C = Delim then
      begin
       if (not f_qs) and f_in and (not FinishCurrentToken) then Exit(false);
      end else
     // is not quote nor delimiter .............................................
      begin
       // extra advance for escape character inside "xxx"
       if f_qs and (C = Escap) then Inc(ct);
       if not (f_in or f_qs) then
        begin
         f_in := true; // set flag "inside parameter"
         cf   := ct;   // init copy_from index
        end;
      end;
     // advance to next char ...................................................
     Inc(ct);
    end;
   // is we still inside unprocessed token ?
   if f_qs then
    begin
     Error := 'Unfinished quoted string';
     Exit(false);
    end;
   if f_in and (not FinishCurrentToken) then Exit(false);
   // final
   ResetText();
   Exit(true);
  end;

 function TSourceLine.Encode(out C:TCommand; out Error:string):Boolean;
  var cmd : string;
  begin
   C.Clear();
   Result := false;
   Error  := 'Command not identified';
   if (Toks.Count = 0) or (Toks[0].TYP <> TOK_IDENT) then Exit;
   //
   cmd := Toks.Items[0].STR;
   {$region ' NOPE '}
   if cmd=CMD_NOPE then C.ID := CID_NOPE else
   {$endregion}
   {$region ' MEMORY '}
   if (cmd=CMD_PUSH)  and (Toks.Count =1) then C.ID := CID_PUSH else
   if (cmd=CMD_PUSH)  and (Toks.Count =2) and Valid_Push1(self,C,Error) then { already done } else
   if (cmd=CMD_PUSH)  and (Toks.Count>=3) and Valid_Push2(self,C,Error) then { already done } else
   if (cmd=CMD_POP)   and (Toks.Count=1) then C.ID := CID_POP else
   if (cmd=CMD_POP)   and Valid_Pop  (self,C,Error) then { already done } else
   if (cmd=CMD_STORE) and Valid_Store(self,C,Error) then { already done } else
   if (cmd=CMD_MOV)   and Valid_Mov  (self,C,Error) then { already done } else
   if cmd=CMD_TAKE then C.ID := CID_TAKE else
   if cmd=CMD_PASS then C.ID := CID_PASS else
   if cmd=CMD_DUP  then C.ID := CID_DUP  else
   if cmd=CMD_SWAP then C.ID := CID_SWAP else
   {$endregion}
   {$region ' CONTROL '}
   if cmd=CMD_JZ then
    if Valid_JumpIndex(self,1,C,Error) then C.ID := CID_JZ else Exit else
   if cmd=CMD_JNZ then
    if Valid_JumpIndex(self,1,C,Error) then C.ID := CID_JNZ else Exit else
   if cmd=CMD_JLZ then
    if Valid_JumpIndex(self,1,C,Error) then C.ID := CID_JLZ else Exit else
   if cmd=CMD_JGZ then
    if Valid_JumpIndex(self,1,C,Error) then C.ID := CID_JGZ else Exit else
   if cmd=CMD_JUMP then
    if Valid_JumpIndex(self,1,C,Error) then C.ID := CID_JUMPI else C.ID := CID_JUMPS else
   if cmd=CMD_COMPARE then
    if Valid_DataType(self,1,C,Error) and
       Valid_CondType(self,2,C,Error) then C.ID := CID_CMP else Exit else
   if cmd=CMD_JN then
    if Valid_DataType(self,1,C,Error) and
       Valid_CondType(self,2,C,Error) and
       Valid_JumpIndex(self,3,C,Error) then C.ID := CID_JN else Exit else
   if (cmd=CMD_CALL) and (Toks.Count=1) then
    begin
     C.ID      := CID_CALL;
     C.FUN_TYP := FUNC_USER_B;
    end else
   if (cmd=CMD_CALL) and (Toks.Count>1) then
    if Valid_Call(self,C,Error) then C.ID := CID_CALL  else Exit else
   if cmd=CMD_RET  then C.ID := CID_RET else
   if cmd=CMD_HALT then C.ID := CID_HALT else
   {$endregion}
   {$region ' INTEGER/REAL convertions '}
   if cmd=CMD_ITOF then C.ID := CID_ITOF else
   if cmd=CMD_FTOI then C.ID := CID_FTOI else
   {$endregion}
   {$region ' INTEGER arithmetic '}
   if (cmd=CMD_INC) and (Toks.Count=1) then C.ID := CID_INC  else
   if (cmd=CMD_INC) and (Toks.Count>=3) and Valid_LxNx(self,C,Error) then C.ID := CID_INCL  else
   if (cmd=CMD_DEC) and (Toks.Count=1) then C.ID := CID_DEC  else
   if (cmd=CMD_DEC) and (Toks.Count>=3) and Valid_LxNx(self,C,Error) then C.ID := CID_DECL  else
   if cmd=CMD_MOD  then C.ID := CID_MOD  else
   if cmd=CMD_IADD then C.ID := CID_IADD else
   if cmd=CMD_ISUB then C.ID := CID_ISUB else
   if cmd=CMD_IMUL then C.ID := CID_IMUL else
   if cmd=CMD_IDIV then C.ID := CID_IDIV else
   if cmd=CMD_IABS then C.ID := CID_IABS else
   if cmd=CMD_INEG then C.ID := CID_INEG else
   {$endregion}
   {$region ' REAL arithmetic '}
   if cmd=CMD_FADD then C.ID := CID_FADD else
   if cmd=CMD_FSUB then C.ID := CID_FSUB else
   if cmd=CMD_FMUL then C.ID := CID_FMUL else
   if cmd=CMD_FDIV then C.ID := CID_FDIV else
   if cmd=CMD_FABS then C.ID := CID_FABS else
   if cmd=CMD_FNEG then C.ID := CID_FNEG else
   if cmd=CMD_POW  then C.ID := CID_POW  else
   if cmd=CMD_LOG  then C.ID := CID_LOG  else
   if cmd=CMD_SIN  then C.ID := CID_SIN  else
   if cmd=CMD_COS  then C.ID := CID_COS  else
   if cmd=CMD_ASIN then C.ID := CID_ASIN else
   if cmd=CMD_ACOS then C.ID := CID_ACOS else
   if cmd=CMD_SEED then C.ID := CID_SEED else
   if cmd=CMD_RAND then C.ID := CID_RAND else
   if cmd=CMD_INT  then C.ID := CID_INT  else
   if cmd=CMD_FRAC then C.ID := CID_FRAC else
   {$endregion}
   {$region ' BITWISE operations '}
   if cmd=CMD_NOT    then C.ID := CID_NOT   else
   if cmd=CMD_AND    then C.ID := CID_AND   else
   if cmd=CMD_OR     then C.ID := CID_OR    else
   if cmd=CMD_XOR    then C.ID := CID_XOR   else
   if cmd=CMD_SHL    then C.ID := CID_SHL   else
   if cmd=CMD_SHR    then C.ID := CID_SHR   else
   if cmd=CMD_ROTL   then C.ID := CID_ROTL  else
   if cmd=CMD_ROTR   then C.ID := CID_ROTR  else
   if cmd=CMD_REV    then C.ID := CID_REV   else
   if cmd=CMD_MASK   then C.ID := CID_MASK  else
   if cmd=CMD_BITEST then C.ID := CID_BTEST else
   if cmd=CMD_BITOGL then C.ID := CID_BTOG  else
   if cmd=CMD_BITON  then C.ID := CID_BON   else
   if cmd=CMD_BITOFF then C.ID := CID_BOFF  else
   {$endregion}
   {$region ' HEAP '}
   if (cmd=CMD_ADDR)    and Valid_HeapAddress(self,2,C,Error) then C.ID := CID_ADDR    else
   if (cmd=CMD_SIZE)    and Valid_HeapAddress(self,1,C,Error) then C.ID := CID_SIZE    else
   if (cmd=CMD_GET1)    and Valid_HeapAddress(self,1,C,Error) then C.ID := CID_GET1    else
   if (cmd=CMD_GET8)    and Valid_HeapAddress(self,1,C,Error) then C.ID := CID_GET8    else
   if (cmd=CMD_SET1)    and Valid_HeapAddress(self,1,C,Error) then C.ID := CID_SET1    else
   if (cmd=CMD_SET8)    and Valid_HeapAddress(self,1,C,Error) then C.ID := CID_SET8    else
   if (cmd=CMD_COPY)    and Valid_HeapAddress(self,2,C,Error) then C.ID := CID_COPY    else
   if (cmd=CMD_ALLOC)   and Valid_HeapAddress(self,1,C,Error) then C.ID := CID_ALLOC   else
   if (cmd=CMD_REALLOC) and Valid_HeapAddress(self,1,C,Error) then C.ID := CID_REALLOC else
   if (cmd=CMD_FREE)    and Valid_HeapAddress(self,1,C,Error) then C.ID := CID_FREE    else
   {$endregion}
   Exit; // cmd not recognized
   //
   Result := true;
   Error  := '';
  end;

// ************************************************************************** //
//  TSourceLines                                                              //
// ************************************************************************** //

 function TSourceLines.Load(const SRC:TStringList; out Error:string):UInt32;
  var
   i    : Int32;
   item : PSourceLine;
  begin
   Clear;
   Result := 0;
   Error  := '';
   if (SRC=Nil) or (SRC.Count=0) then
    begin
     Error := 'Empty source lines';
     Exit;
    end;
   //
   for i:=0 to SRC.Count-1 do
    begin
     New(item);
     if not item.Parse(SRC[i],Error,true) then
      begin
       Free;
       Dispose(item);
       Error := Format('Line %d: %s',[i,Error]);
       Exit(0);
      end;
     if item.Toks.Count = 0 then Dispose(item) else
      begin
       item.ID := i;
       Add(item);
       Inc(Result);
      end;
    end;
  end;

 function TSourceLines.Load(const FN:string; out Error:string):UInt32;
  var src : TStringList;
  begin
   Result := 0;
   if not FileExists(FN) then
    begin
     Error := Format('File "%s" not found',[FN]);
     Exit;
    end;
   //
   try
    src := TStringList.Create;
    src.LoadFromFile(FN);
    Result := Load(src,Error);
   finally
    if src<>Nil then FreeAndNil(src);
   end;
  end;

 procedure TSourceLines.ShiftGlobals(const Shift:Int32);
  var
   i    : Int32;
   item : PSourceLine;
  begin
   if (Head=Nil) or (Shift=0) then Exit;
   item := Head;
   repeat
    for i:=0 to item.Toks.Count-1 do
     if item.Toks[i].TYP = TOK_GIDX then
      begin
       item.Toks.Items[i].VAL.i8 := item.Toks[i].VAL.i8 + Shift;
       item.Toks.Items[i].STR    := Format('.G%d',[item.Toks[i].VAL.i8]);
       item.ResetText();
      end;
    item := item.Next;
   until item=Nil;
  end;

 procedure TSourceLines.Add(const P:PSourceLine);
  begin
   if P=Nil then Exit;
   P.Next := Nil;
   if Head=Nil then
    begin
     Head := P;
     Tail := P;
    end
   else
    begin
     Tail.Next := P;
     Tail      := P;
    end;
  end;

 procedure TSourceLines.Add(const L:TSourceLine);
  var item : PSourceLine;
  begin
   New(item);
   item^ := L;
   Add(item);
  end;

 // items count start from P (from Head if P=Nil)
 function TSourceLines.Count(const FromP:PSourceLine):UInt32;
  var item : PSourceLine;
  begin
   Result := 0;
   if FromP=Nil then item := Head else item := FromP;
   if item = Nil then Exit;
   repeat
    Inc(Result);
    item := item.Next;
   until item=Nil;
  end;

 function TSourceLines.Empty:Boolean;
  begin
   Result := Head = Nil;
  end;

 function TSourceLines.Prev(const P:PSourceLine):PSourceLine;
  var item : PSourceLine;
  begin
   Result := Nil;
   if (P=Nil) or (Head=Nil) or (P=Head) then Exit;
   item := Head;
   repeat
    if item.Next = P then Exit(item);
    item := item.Next;
   until item=Nil;
  end;

 // if FromP=Nil then look start from Head
 function TSourceLines.Look(const FromP:PSourceLine; const Found:SourceLinePredicat):PSourceLine;
  var item : PSourceLine;
  begin
   Result := Nil;
   if Head=Nil then Exit;
   if FromP=Nil then item := Head else item := FromP;
   repeat
    if Found(item) then Exit(item);
    item := item.Next;
   until item=Nil;
  end;

 function TSourceLines.LookByTokName(const FromP:PSourceLine; const Idx:Uint8; const Name:string):PSourceLine;
  begin
   Result := Look(FromP,
    function (const P:PSourceLine):Boolean
     begin
      Exit((Idx<P.Toks.Count) and (P.Toks.Items[Idx].STR=Name));
     end);
  end;

 function TSourceLines.LookByTokType(const FromP:PSourceLine; const Idx:Uint8; const Typ:Uint8):PSourceLine;
  begin
   Result := Look(FromP,
    function (const P:PSourceLine):Boolean
     begin
      Exit((Idx<P.Toks.Count) and (P.Toks.Items[Idx].TYP=Typ));
     end);
  end;

 function TSourceLines.CheckRange(const FromP,ToP:PSourceLine):Boolean;
  var item : PSourceLine;
  begin
   Result := false;
   if (Head=Nil) or (FromP=Nil) or (ToP=Nil) or (FromP=ToP) then Exit;
   item := FromP;
   repeat
    if item=ToP then Exit(true);
    item := item.Next;
   until item=Nil;
  end;

 procedure TSourceLines.Extract(const P:PSourceLine);
  var PP : PSourceLine;
  begin
   // empty list or invalid argument
   if (Head=Nil) or (P=Nil) then Exit;
   // extract last item from list
   if (Head=Tail) and (P=Head) then
     begin
      Clear;
      Exit;
     end;
   // extract head
   if P=Head then Head := Head.Next else
   // try extract middle or tail item
    begin
     PP := Prev(P);
     if PP=Nil then Exit; // P is not member of list !
     if P=Tail then Tail := PP
               else PP.Next := P.Next;
    end;
   // final
   P.Next    := Nil;
   Tail.Next := Nil;
  end;

 function TSourceLines.Extract(const Found:SourceLinePredicat):TSourceLines;
  var item,t : PSourceLine;
  begin
   Result.Clear;
   if Head=Nil then Exit;
   item := Head;
   repeat
    if Found(item) then
     begin
      t := item.Next;
      Extract(item);
      Result.Add(item);
      item := t;
     end
    else item := item.Next;
   until item=Nil;
  end;

 function TSourceLines.Extract(const FromP,ToP:PSourceLine):TSourceLines;
  var PP : PSourceLine;
  begin
   Result.Clear;
   if not CheckRange(FromP,ToP) then Exit;
   // extract full list to other list
   if (FromP=Head) and (ToP=Tail) then
    begin
     Result := self;
     Clear;
     Exit;
    end;
   if (FromP=Head) and (ToP<>Tail) then Head := ToP.Next else
    begin
     PP := Prev(FromP);
     if ToP=Tail
      then Tail := PP
      else PP.Next := ToP.Next;
    end;
   // final
   Tail.Next        := Nil;
   Result.Head      := FromP;
   Result.Tail      := ToP;
   Result.Tail.Next := Nil;
  end;

 procedure TSourceLines.Replace(const P:PSourceLine; var SL:TSourceLines);
  var PP : PSourceLine;
  begin
   if (Head=Nil) or (P=Nil) or (SL.Head=Nil) then Exit;
   if (Head=Tail) and (P=Head) then
    begin
     Head := SL.Head;
     Tail := SL.Tail;
     SL.Clear;
     P.Next := Nil;
     Exit;
    end;
   if P=Head then
    begin
     SL.Tail.Next := Head.Next;
     Head         := SL.Head;
    end
   else
    begin
     PP := Prev(P);
     if PP=Nil then Exit;
     if P=Tail then
      begin
       PP.Next := SL.Head;
       Tail    := SL.Tail;
      end
     else
      begin
       PP.Next      := SL.Head;
       SL.Tail.Next := P.Next;
      end;
    end;
   SL.Clear;
   P.Next := Nil;
  end;

 function TSourceLines.ToList(const Ident:Int32; const LineNumbers:Boolean):TStringList;
  var
   i     : Int32;
   item  : PSourceLine;
   idstr : string;
  begin
   Result := TStringList.Create;
   if Head=Nil then Exit;
   item  := Head;
   i     := 0;
   idstr := System.StringOfChar(' ',Ident);
   repeat
    if LineNumbers
     then Result.Add(Format(idstr + '%4d| %s',[i,item.Text]))
     else Result.Add(idstr + item.Text);
    item := item.Next;
    Inc(i);
   until item=Nil;
  end;

 procedure TSourceLines.Print;
  var
   i : Int32;
   s : TStringList;
  begin
   try
    s := ToList(0,true);
    for i:=0 to s.Count-1 do WriteLn(s[i]);
   finally
    s.Free;
   end;
  end;

 procedure TSourceLines.Clear;
  begin
   Head := Nil;
   Tail := Nil;
  end;

 procedure TSourceLines.Free;
  var item,next : PSourceLine;
  begin
   if Head=Nil then Exit;
   item := Head;
   repeat
    next := item.Next;
    item.Clear();
    Dispose(item);
    item := next;
   until item=Nil;
   Head := Nil;
   Tail := Nil;
  end;

end.
