{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : Common Stuff                                                     *}
{* Change  : 28.02.2017 (163 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2017 DelphiRunner                                       *}
{******************************************************************************}

unit lib32.Common;

 interface

 uses

  // system
  System.SysUtils, Winapi.Windows, System.TypInfo, System.RTTI,
  System.Generics.Defaults, System.Generics.Collections,
  // default json parser for lib32
  SuperObject;

 type

  foo = UInt8; // some type ...

  (* integer types specification:

   ALIAS   TYPE     FORMAT            RANGE

   Int8   ShortInt  Signed   8-bit   -128        .. 127
   Int16  SmallInt  Signed   16-bit  -32768      .. 32767
   Int32  Integer   Signed   32-bit  -2147483648 .. 2147483647
   Int64            Signed   64-bit  -2^63       .. 2^63-1

   UInt8  Byte      Unsigned 8-bit    0          .. 255
   UInt16 Word      Unsigned 16-bit   0          .. 65535
   UInt32 Cardinal  Unsigned 32-bit   0          .. 4294967295
   UInt64           Unsigned 64-bit   0          .. 2^64-1 *)

  (* 1 dimension array from "System.pas"
  TArray<T> = array of T; *)

  // 2 dimension array
  TArray2<T> = array of TArray<T>;

  // typed pointer to any type
  // example :
  // classic way         : PMyRec = ^TMyRec;
  // from "lib32.Common" : Pointer_<TMyRec>.Ref (if need only pointer)
  // from "lib32.Types"  : type_<TMyRec>.Ref    (if need rtti support)
  Pointer_<T> = class type Ref = ^T; end;

 // ************************************************************************* //
 //  Singletone over object type                                              //
 // ************************************************************************* //

  Singletone<T:class,constructor> = class(TObject)

   strict private

    class var FInst : T;

    class constructor Create;
    class destructor  Destroy;

   private

    class function GetInstance:T; static;

   public

    class function NewInstance:TObject; override;

    class property Inst:T read GetInstance;

  end;

 // ************************************************************************* //
 //  lib32 entity with index                                                  //
 // ************************************************************************* //

  TItemIndex = UInt64;

  TIndexedItem = class(TObject)

   private

    function GetIsEmptyItem:Boolean; virtual;

   protected

    FIndex : TItemIndex; // empty (uninitialized) item index is 0

   public

    // json save/load
    function Load(const J:ISuperObject):Boolean; overload; virtual; abstract;
    function Load(const J:AnsiString):Boolean; overload; virtual;
    function Save(const ObjName:AnsiString=''):AnsiString; virtual; abstract;

    property ID:TItemIndex read FIndex write FIndex;
    property IsEmpty:Boolean read GetIsEmptyItem;

  end;

  TIndexedItems<ItemType:TIndexedItem> = class(TDictionary<TItemIndex,ItemType>) end;

 var

  Context : TRTTIContext;
  AppDir  : string = '';

 implementation

 // ************************************************************************* //
 //  Singletone<T>                                                            //
 // ************************************************************************* //

 // ***************************************************************************
 class constructor Singletone<T>.Create;
  begin
   if FInst=Nil then FInst := T.Create;
  end;

 // ***************************************************************************
 class destructor Singletone<T>.Destroy;
  begin
   FreeAndNil(FInst);
  end;

 // ***************************************************************************
 class function Singletone<T>.GetInstance:T;
  begin
   if FInst=Nil then FInst := T.Create;
   Result := FInst;
  end;

 // ***************************************************************************
 class function Singletone<T>.NewInstance:TObject;
  begin
   if FInst=Nil then FInst := T(inherited NewInstance);
   Result := FInst;
  end;

 // ************************************************************************* //
 //  TIndexedItem                                                             //
 // ************************************************************************* //

 // ***************************************************************************
 function TIndexedItem.GetIsEmptyItem:Boolean;
  begin
   Result := ID=0;
  end;

 // ***************************************************************************
 function TIndexedItem.Load(const J:AnsiString):Boolean;
  begin
   Result := Load(SO(J));
  end;

 initialization

  Context := TRTTIContext.Create;
  AppDir  := ExtractFilePath(ParamStr(0));

 finalization

  Context.Free;

end.
