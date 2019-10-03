{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : "Set" wrapper over TDictionary                                   *}
{* Change  : 12.12.2012 (122 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2012 Raznosilin V.V.                                    *}
{******************************************************************************}

 unit lib32.Util.SetDictionary;

 interface

 uses

  // system
  System.SysUtils, System.Generics.Defaults, System.Generics.Collections,
  // library
  lib32.Common;

 type

  SetDictionary<T> = class(TObject)

   private

    FSet : TDictionary<T,foo>;

    function GetCount:Int32;
    function GetItems:TArray<T>;

   public

    constructor Create;
    destructor  Destroy; override;

    procedure Clear;
    procedure TrimExcess;
    function Insert(const Item:T):Boolean;
    function Remove(const Item:T):Boolean;
    function Contain(const Item:T):Boolean;

    property Count:Int32 read GetCount;
    property Items:TArray<T> read GetItems;

  end;

 implementation

 // ************************************************************************* //
 //  SetDictionary<T>                                                         //
 // ************************************************************************* //

 // ***************************************************************************
 function SetDictionary<T>.GetCount:Int32;
  begin
   Result := FSet.Count;
  end;

 // ***************************************************************************
 function SetDictionary<T>.GetItems:TArray<T>;
  var a : TArray<TPair<T,foo>>;
      i : Int32;
  begin
   Result := Nil;
   a := FSet.ToArray;
   if a=Nil then Exit;
   SetLength(Result,Length(a));
   for i:=0 to High(a) do Result[i] := a[i].Key;
  end;

 // ***************************************************************************
 constructor SetDictionary<T>.Create;
  begin
   inherited Create;
   FSet := TDictionary<T,foo>.Create;
  end;

 // ***************************************************************************
 destructor SetDictionary<T>.Destroy;
  begin
   FreeAndNil(FSet);
   inherited Destroy;
  end;

 // ***************************************************************************
 procedure SetDictionary<T>.Clear;
  begin
   FSet.Clear;
  end;

 // ***************************************************************************
 procedure SetDictionary<T>.TrimExcess;
  begin
   FSet.TrimExcess;
  end;

 // ***************************************************************************
 function SetDictionary<T>.Insert(const Item:T):Boolean;
  begin
   Result := False;
   if FSet.ContainsKey(Item) then Exit;
   FSet.Add(Item,0);
   Result := True;
  end;

 // ***************************************************************************
 function SetDictionary<T>.Remove(const Item:T):Boolean;
  begin
   Result := False;
   if not FSet.ContainsKey(Item) then Exit;
   FSet.Remove(Item);
   Result := True;
  end;

 // ***************************************************************************
 function SetDictionary<T>.Contain(const Item:T):Boolean;
  begin
   Result := FSet.ContainsKey(Item);
  end;

end.
