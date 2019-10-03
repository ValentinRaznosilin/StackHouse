{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    :                                                                  *}
{* Change  : 13.01.2013 (125 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2012 Raznosilin V.V.                                    *}
{******************************************************************************}

unit lib32.Types;

                                   interface

 uses

  // system
  System.SysUtils, Winapi.Windows, System.TypInfo, System.RTTI,
  System.Generics.Defaults, System.Generics.Collections,
  // library
  lib32.Common, {lib32.Util.BiDictionary,} lib32.Func.Core;

 type

//  types = class sealed (TObject)
//
//   strict private
//
//    class var MapBy_Info : TDictionary<Pointer,TObject>;
//    class var MapBy_Name : TDictionary<string ,TObject>;
//
//    class constructor Create;
//    class destructor  Destroy;
//
//   private
//
//   public
//
//  end;

  type_<t> = class(TObject)

   strict private

    class var FInst : type_<t>;

    class constructor Create;
    class destructor  Destroy;

   private

    FShortName    : string;
    FQualifedName : string;
    FSize         : Int32;
    FInfo         : PTypeInfo;
    FData         : PTypeData;
    FRtti         : TRTTIType;
    FFunc         : func_<t>;

   public

    type Ref = ^t;

    class function NewInstance:TObject; override;

    constructor Create;
    destructor  Destroy; override;

    class property Inst : type_<t> read FInst;

    property Name : string         read FShortName;
    property QualifedName : string read FQualifedName;
    property Size : Int32          read FSize;
    property Info : PTypeInfo      read FInfo;
    property Data : PTypeData      read FData;
    property Rtti : TRTTIType      read FRtti;
    property Func : func_<t>       read FFunc;

  end;

                                 implementation

 // ************************************************************************* //
 //  type_<t>                                                                 //
 // ************************************************************************* //

 // ***************************************************************************
 class constructor type_<t>.Create;
  begin
   FInst := type_<t>.Create;
  end;

 // ***************************************************************************
 class destructor type_<t>.Destroy;
  begin
   FreeAndNil(FInst);
  end;

 // ***************************************************************************
 class function type_<t>.NewInstance:TObject;
  begin
   if FInst=Nil then FInst := type_<t>(inherited NewInstance);
   Result := FInst;
  end;

 // ***************************************************************************
 constructor type_<t>.Create;
  begin
   inherited Create;
   FInfo         := TypeInfo(t);
   FData         := GetTypeData(FInfo);
   FRtti         := Context.GetType(FInfo);
   FFunc         := func_<t>.Inst;
   FShortName    := FRtti.Name;
   FQualifedName := FRtti.QualifiedName;
   FSize         := FRtti.TypeSize;
  end;

 // ***************************************************************************
 destructor type_<t>.Destroy;
  begin
   FreeAndNil(FRtti);
   inherited Destroy;
  end;

end.
