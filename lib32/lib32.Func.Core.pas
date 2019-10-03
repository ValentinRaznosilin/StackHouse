{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : Functions over Item:T (Storage/Grouping by Type)                 *}
{* Change  : 03.03.2016 (420 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2016 Raznosilin V.V.                                    *}
{******************************************************************************}

 unit lib32.Func.Core;

 interface

 uses

  // system
  System.SysUtils, System.Classes, System.Generics.Defaults, System.Generics.Collections,
  System.TypInfo, System.RTTI,
  // library
  lib32.Common;

 type

  (* functional type convention :

   func_<name> = function ()
   proc_<name> = procedure ()

   fref_<name> = reference to function ()
   pref_<name> = reference to procedure ()

   fobj_<name> = function () of object
   pobj_<name> = procedure () of object *)

  // unary functions **********************************************************

  func_Unary <OpType,ResType> =              function  (const O:OpType):ResType;
  fref_Unary <OpType,ResType> = reference to function  (const O:OpType):ResType;
  proc_Unary <OpType        > =              procedure (var   O:OpType);
  pref_Unary <OpType        > = reference to procedure (var   O:OpType);

  // binary functions *********************************************************

  func_Binary <OpTypeA,OpTypeB,ResType> =              function  (const A:OpTypeA; const B:OpTypeB):ResType;
  fref_Binary <OpTypeA,OpTypeB,ResType> = reference to function  (const A:OpTypeA; const B:OpTypeB):ResType;
  proc_Binary <OpTypeA,OpTypeB,ResType> =              procedure (var   A:OpTypeA; var   B:OpTypeB; out Res:ResType);
  pref_Binary <OpTypeA,OpTypeB,ResType> = reference to procedure (var   A:OpTypeA; var   B:OpTypeB; out Res:ResType);

  // action over collection item **********************************************
  // Item:T      - item value
  // Index:Int32 - item index

  pref_VarItemAction   <T        > = reference to procedure (var   Item:T; const Index:Int32=-1);
  pref_ConstItemAction <T        > = reference to procedure (const Item:T; const Index:Int32=-1);
  fref_VarItemAction   <T,ResType> = reference to function  (var   Item:T; const Index:Int32=-1):ResType;
  fref_ConstItemAction <T,ResType> = reference to function  (const Item:T; const Index:Int32=-1):ResType;

  // comparator ***************************************************************

  TOrderOfItems =
   (ordUnknown,    // 0 unknown order (must be recalculated)
    ordASC,        // 1 min .. max
    ordDSC,        // 2 max .. min
    ordConst,      // 3 const value over entire array
    ordUnordered); // 4 unordered

  // L < R : Result = -1
  // L = R : Result =  0
  // L > R : Result =  1
  func_Compare<T> = function (const L,R:T):Int32;
  fref_Compare<T> = reference to function (const L,R:T):Int32;

  // single value to text conversion ******************************************

  func_Format<T> = function (const Value:T; const Fmt:AnsiString=''):String;
  fref_Format<T> = reference to function(const Value:T; const Fmt:AnsiString=''):String;

  func_Value<T> = function (const Str:String):T;
  fref_Value<T> = reference to function (const Str:String):T;

  // **************************************************************************

  TFuncData = record

   Name : AnsiString; // function name
   Ptr  : Pointer;    // pointer to function implementation
   Rtti : TRTTIType;  // argument typeinfo

  end;

  func_<t> = class;

  funcs = class(TObject)

   strict private

    class var FNames : TList<AnsiString>; // list of all declared function names
    class var FTypes : TList<func_<foo>>; // list of all types that have at least one declared function

   private

    class procedure Init;
    class procedure Clear;

    class function GetFuncCount:Int32; static;
    class function GetFuncList:TArray<TFuncData>; static;
    class function GetTypeCount:Int32; static;
    class function GetTypeList:TArray<func_<foo>>; static;
    class function GetNameCount:Int32; static;
    class function GetNameList:TArray<AnsiString>; static;

   public

    class function  IsValidName(const Name:AnsiString):Boolean;
    class function  LinkCount(const Name:AnsiString):Int32;
    class function  RegName(const Name:AnsiString):Boolean;
    class function  UnRegName(const Name:AnsiString):Boolean;
    class function  ResetName(const OldName,NewName:AnsiString):Boolean;
    class procedure UpdateFunc(const F:func_<foo>);

    class property NameCount : Int32              read GetNameCount;
    class property NameList  : TArray<AnsiString> read GetNameList;
    class property TypeCount : Int32              read GetTypeCount;
    class property TypeList  : TArray<func_<foo>> read GetTypeList;
    class property FuncCount : Int32              read GetFuncCount;
    class property FuncList  : TArray<TFuncData>  read GetFuncList;

  end;

  // singleton for each t *****************************************************
  func_<t> = class(TObject)

   strict private

    class var FInst : func_<t>;

    class constructor Create;
    class destructor  Destroy;

   private

    FList : TDictionary<AnsiString,Pointer>;
    FRtti : TRTTIType;

    function GetCount:Int32;
    function GetFunctionByName(Name:AnsiString):Pointer;
    function GetFunctionList:TArray<TFuncData>;

    class function GetInstance:func_<t>; static;

   public

    class function NewInstance:TObject; override;

    constructor Create;
    destructor  Destroy; override;

    function Reg(const Name:AnsiString; const Ptr:Pointer):Boolean;
    function UnReg(const Name:AnsiString):Boolean;
    function ResetPointer(const Name:AnsiString; const NewPtr:Pointer):Boolean;
    function IsValidName(const Name:AnsiString):Boolean;

    class property Inst : func_<t> read GetInstance;

    property Rtti:TRTTIType                   read FRtti;
    property Count:Int32                      read GetCount;
    property FuncPtr[Name:AnsiString]:Pointer read GetFunctionByName; default;
    property Items:TArray<TFuncData>          read GetFunctionList;

  end;

 procedure Initialize;
 procedure Finalize;

                                 implementation

 // unit initialization *******************************************************
 procedure Initialize;
  begin
   funcs.Init;
  end;

 // unit finalization *********************************************************
 procedure Finalize;
  begin
   funcs.Clear;
  end;

 // ************************************************************************* //
 //  funcs                                                                    //
 // ************************************************************************* //

 // ***************************************************************************
 class procedure funcs.Init;
  begin
   FNames := TList<AnsiString>.Create;
   FTypes := TList<func_<foo>>.Create;
  end;

 // ***************************************************************************
 class procedure funcs.Clear;
  begin
   FreeAndNil(FNames);
   FreeAndNil(FTypes);
  end;

 // ***************************************************************************
 class function funcs.GetFuncCount:Int32;
  var i : Int32;
  begin
   Result := 0;
   for i:=0 to FTypes.Count-1 do Result := Result + FTypes[i].Count;
  end;

 // ***************************************************************************
 class function funcs.GetFuncList:TArray<TFuncData>;
  var i,j,k : Int32;
  begin
   SetLength(Result,FuncCount);
   if Result=Nil then Exit;
   k := 0;
   for i:=0 to FTypes.Count-1 do
    for j:=0 to FTypes[i].Count-1 do
     begin
      Result[k] := FTypes[i].Items[j];
      Inc(k);
     end;
  end;

 // ***************************************************************************
 class function funcs.GetTypeCount:Int32;
  begin
   Result := FTypes.Count;
  end;

 // ***************************************************************************
 class function funcs.GetTypeList:TArray<func_<foo>>;
  begin
   Result := FTypes.ToArray;
  end;

 // ***************************************************************************
 class function funcs.GetNameCount:Int32;
  begin
   Result := FNames.Count;
  end;

 // ***************************************************************************
 class function funcs.GetNameList:TArray<AnsiString>;
  begin
   Result := FNames.ToArray;
  end;

 // ***************************************************************************
 class function funcs.IsValidName(const Name:AnsiString):Boolean;
  begin
   Result := FNames.Contains(Name);
  end;

 // ***************************************************************************
 class function funcs.LinkCount(const Name:AnsiString):Int32;
  var i : Int32;
  begin
   Result := 0;
   for i:=0 to FTypes.Count-1 do
    if FTypes[i].IsValidName(Name) then Inc(Result);
  end;

 // ***************************************************************************
 class function funcs.RegName(const Name:AnsiString):Boolean;
  begin
   if not FNames.Contains(Name) then FNames.Add(Name);
   Result := true;
  end;

 // ***************************************************************************
 class function funcs.UnRegName(const Name:AnsiString):Boolean;
  begin
   if IsValidName(Name) and (LinkCount(Name)=0) then FNames.Remove(Name);
   Result := true;
  end;

 // ***************************************************************************
 class function funcs.ResetName(const OldName,NewName:AnsiString):Boolean;
  var Ptr : Pointer;
      i   : Int32;
  begin
   Result := false;
   if (not FNames.Contains(OldName)) or FNames.Contains(NewName) or (NewName='') then Exit;
   for i:=0 to FTypes.Count-1 do
    if FTypes[i].IsValidName(OldName) then
     begin
      Ptr := FTypes[i];
      FTypes[i].FList.Remove(OldName);
      FTypes[i].FList.Add(NewName,Ptr);
     end;
   FNames.Remove(OldName);
   FNames.Add(NewName);
   Result := true;
  end;

 // ***************************************************************************
 class procedure funcs.UpdateFunc(const F:func_<foo>);
  begin
   if F.Count=0 then FTypes.Remove(F) else
   if not FTypes.Contains(F) then FTypes.Add(F);
  end;

 // ************************************************************************* //
 //  func_<t>                                                                 //
 // ************************************************************************* //

 // ***************************************************************************
 class constructor func_<t>.Create;
  begin
   FInst := func_<t>.Create;
  end;

 // ***************************************************************************
 class destructor func_<t>.Destroy;
  begin
   FreeAndNil(FInst);
  end;

 // ***************************************************************************
 class function func_<t>.NewInstance:TObject;
  begin
   if FInst=Nil then FInst := func_<t>(inherited NewInstance);
   Result := FInst;
  end;

 // ***************************************************************************
 constructor func_<t>.Create;
  begin
   inherited Create;
   FList := TDictionary<AnsiString,Pointer>.Create;
   FRtti := Context.GetType(TypeInfo(t));
  end;

 // ***************************************************************************
 destructor func_<t>.Destroy;
  begin
   FreeAndNil(FList);
   inherited Destroy;
  end;

 // ***************************************************************************
 function func_<t>.GetCount:Int32;
  begin
   Result := FList.Count;
  end;

 // ***************************************************************************
 function func_<t>.GetFunctionByName(Name:AnsiString):Pointer;
  begin
   Result := Nil;
   FList.TryGetValue(Name,Result);
  end;

 // ***************************************************************************
 function func_<t>.GetFunctionList:TArray<TFuncData>;
  var i : Int32;
      a : TArray<TPair<AnsiString,Pointer>>;
  begin
   Result := Nil;
   a := FList.ToArray;
   if a=Nil then Exit;
   SetLength(Result,Length(a));
   for i:=0 to High(a) do
    begin
     Result[i].Name := a[i].Key;
     Result[i].Ptr  := a[i].Value;
     Result[i].Rtti := FRtti;
    end;
  end;

 // ***************************************************************************
 class function func_<t>.GetInstance:func_<t>;
  begin
   if FInst=Nil then FInst := func_<t>.Create;
   Result := FInst;
  end;

 // ***************************************************************************
 function func_<t>.Reg(const Name:AnsiString; const Ptr:Pointer):Boolean;
  begin
   Result := false;
   if (Name='') or (Ptr=Nil) or FList.ContainsKey(Name) then Exit;
   //
   FList.Add(Name,Ptr);                // add pair {function name -> pointer to function}
   funcs.RegName(Name);                // register function name in global space
   funcs.UpdateFunc(func_<foo>(Self)); // update type info in global space
   Result := true;
  end;

 // ***************************************************************************
 function func_<t>.UnReg(const Name:AnsiString):Boolean;
  begin
   Result := false;
   if FList.ContainsKey(Name) then
    begin
     FList.Remove(Name);                 // remove pair {function name -> pointer to function}
     funcs.UnRegName(Name);              // unregister function name in global space
     funcs.UpdateFunc(func_<foo>(Self)); // update type info in global space
     Result := true;
    end;
  end;

 // ***************************************************************************
 function func_<t>.ResetPointer(const Name:AnsiString; const NewPtr:Pointer):Boolean;
  begin
   Result := false;
   if (not FList.ContainsKey(Name)) or (NewPtr=Nil) then Exit;
   //
   FList.AddOrSetValue(Name,NewPtr);
   Result := true;
  end;

 // ***************************************************************************
 function func_<t>.IsValidName(const Name:AnsiString):Boolean;
  begin
   Result := FList.ContainsKey(Name);
  end;

end.
