{******************************************************************************}
{* Project : "StackHouse" virtual stack-machine                               *}
{* Unit    : Types                                                            *}
{* Change  : 03.10.2019 (128  lines)                                          *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2019 DelphiRunner                                            *}
{******************************************************************************}

unit SH.Types;

 interface

 type

  // data holder
  PData = ^TData;
  TData = record

   procedure Clear; inline;

   case integer of
    0  : ( Ptr    : Pointer;   Size   : UInt32 );
    1  : ( _Ptr   : UInt32;    _Size  : UInt32 );
    2  : ( StrPtr : PAnsiChar; StrLen : UInt32 );
    3  : ( Data   : PData                      );
    4  : ( r4     : Single                     );
    5  : ( r8     : Double                     );
    6  : ( Ch     : AnsiChar                   );
    7  : ( PCh    : ^AnsiChar                  );
    8  : ( Bl     : Boolean                    );
    9  : ( i8     : Int64                      );
    10 : ( u8     : UInt64                     );
    11 : ( i4     : array [0..1] of Int32      );
    12 : ( u4     : array [0..1] of UInt32     );
    13 : ( i2     : array [0..3] of Int16      );
    14 : ( u2     : array [0..3] of UInt16     );
    15 : ( i1     : array [0..7] of Int8       );
    16 : ( u1     : array [0..7] of UInt8      );

  end;

  TStorage = TArray<TData>;

  // 1GB memory space as array of
  TMemory   = array [0..($40000000-1)] of AnsiChar; // 8  bit ANSI characters
  TMemory8  = array [0..($40000000-1)] of UInt8;    // 8  bit unsigned integers
  TMemory16 = array [0..($20000000-1)] of UInt16;   // 16 bit unsigned integers
  TMemory32 = array [0..($10000000-1)] of UInt32;   // 32 bit unsigned integers
  TMemory64 = array [0..($8000000 -1)] of UInt64;   // 64 bit unsigned integers
  TMemData  = array [0..($8000000 -1)] of TData;    // 64 bit TData
  PMemory   = ^TMemory;
  PMemory8  = ^TMemory8;
  PMemory16 = ^TMemory16;
  PMemory32 = ^TMemory32;
  PMemory64 = ^TMemory64;
  PMemData  = ^TMemData;

  // command descriptor
  PCommand = ^TCommand;
  TCommand = record

   procedure Clear; inline;

   case ID : UInt16 of // command type

    // flow control ............................................................
    0 :
     (
      JUMP : UInt16; // jump index
      DATA : UInt16; // data type (reserved!)
      COND : UInt16; // condition type + data type
     );

    // push ....................................................................
    1 :
     (
      ARG  : Int64; // posible constant value or index .L | .G
      ARG2 : Int64; // posible constant value or index .L | .G
     );

    // move ....................................................................
    2 :
     (
      MOV_VAL  : Int64;  // posible constant value
      MOV_FROM : UInt16; // posible index .L | .G
      MOV_TO   : UInt16; // posible index .L | .G
     );

    // heap ....................................................................
    3 :
     (
      ARR_FROM : UInt16; // source address as index .L
      ARR_TO   : UInt16; // destination address as index .L
     );

    // call ....................................................................
    4 :
     (
      FUN_IDX : UInt16; // function index
      FUN_TYP : UInt16; // function type
     );

  end;

  TCode = TArray<TCommand>;

 implementation

// ************************************************************************** //
//  TData                                                                     //
// ************************************************************************** //

 procedure TData.Clear;
  begin
   i8 := 0;
  end;

// ************************************************************************** //
//  TCommand                                                                  //
// ************************************************************************** //

 procedure TCommand.Clear;
  begin
   FillChar(self,SizeOf(TCommand),0);
  end;

end.
