{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : "BiDictionary" wrapper over TDictionary                          *}
{* Change  : 12.10.2012 (191 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2012 Raznosilin V.V.                                    *}
{******************************************************************************}

 unit lib32.Util.BiDictionary;

 interface

 uses

  // system
  System.SysUtils, System.Generics.Defaults, System.Generics.Collections;

 type

  BiDictionary<A,B> = class(TObject)

   private

    Fab : TDictionary<A,B>;
    Fba : TDictionary<B,A>;

    function GetCount:Int32;
    function GetItems:TArray<TPair<A,B>>;

   public

    constructor Create;
    destructor  Destroy; override;

    procedure Clear;
    procedure TrimExcess;
    function Add(const _a_:A; const _b_:B):Boolean;
    function RemA(const _a_:A):Boolean;
    function RemB(const _b_:B):Boolean;
    function SetA(const _b_:B; const _newa_:A):Boolean;
    function SetB(const _a_:A; const _newb_:B):Boolean;
    function GetA(const _b_:B; out _a_:A):Boolean;
    function GetB(const _a_:A; out _b_:B):Boolean;
    function ContainA(const _a_:A):Boolean; overload;
    function ContainB(const _b_:B):Boolean; overload;

    property Count:Int32 read GetCount;
    property Items:TArray<TPair<A,B>> read GetItems;

  end;

 implementation

 // ************************************************************************* //
 //  BiDictionary<A,B>                                                        //
 // ************************************************************************* //

 // ***************************************************************************
 function BiDictionary<A,B>.GetCount:Int32;
  begin
   Result := Fab.Count;
  end;

 // ***************************************************************************
 function BiDictionary<A,B>.GetItems:TArray<TPair<A,B>>;
  begin
   Result := Fab.ToArray;
  end;

 // ***************************************************************************
 constructor BiDictionary<A,B>.Create;
  begin
   inherited Create;
   Fab := TDictionary<A,B>.Create;
   Fba := TDictionary<B,A>.Create;
  end;

 // ***************************************************************************
 destructor BiDictionary<A,B>.Destroy;
  begin
   FreeAndNil(Fab);
   FreeAndNil(Fba);
   inherited Destroy;
  end;

 // ***************************************************************************
 procedure BiDictionary<A,B>.Clear;
  begin
   Fab.Clear;
   Fba.Clear;
  end;

 // ***************************************************************************
 procedure BiDictionary<A,B>.TrimExcess;
  begin
   Fab.TrimExcess;
   Fba.TrimExcess;
  end;

 // ***************************************************************************
 function BiDictionary<A,B>.Add(const _a_:A; const _b_:B):Boolean;
  begin
   try
    Fab.Add(_a_,_b_);
    Fba.Add(_b_,_a_);
    Result := True;
   except
    Result := False;
   end;
  end;

 // ***************************************************************************
 function BiDictionary<A,B>.RemA(const _a_:A):Boolean;
  var _b_ : B;
  begin
   Result := False;
   if Fab.TryGetValue(_a_,_b_) then
    begin
     Fab.Remove(_a_);
     Fba.Remove(_b_);
     Result := True;
    end;
  end;

 // ***************************************************************************
 function BiDictionary<A,B>.RemB(const _b_:B):Boolean;
  var _a_ : A;
  begin
   Result := False;
   if Fba.TryGetValue(_b_,_a_) then
    begin
     Fab.Remove(_a_);
     Fba.Remove(_b_);
     Result := True;
    end;
  end;

 // ***************************************************************************
 function BiDictionary<A,B>.SetA(const _b_:B; const _newa_:A):Boolean;
  var _olda_ : A;
  begin
   Result := False;
   if Fba.TryGetValue(_b_,_olda_) and (not Fab.ContainsKey(_newa_)) then
    begin
     Fba.AddOrSetValue(_b_,_newa_);
     Fab.Remove(_olda_);
     Fab.Add(_newa_,_b_);
     Result := True;
    end;
  end;

 // ***************************************************************************
 function BiDictionary<A,B>.SetB(const _a_:A; const _newb_:B):Boolean;
  var _oldb_ : B;
  begin
   Result := False;
   if Fab.TryGetValue(_a_,_oldb_) and (not Fba.ContainsKey(_newb_)) then
    begin
     Fab.AddOrSetValue(_a_,_newb_);
     Fba.Remove(_oldb_);
     Fba.Add(_newb_,_a_);
     Result := True;
    end;
  end;

 // ***************************************************************************
 function BiDictionary<A,B>.GetA(const _b_:B; out _a_:A):Boolean;
  begin
   Result := Fba.TryGetValue(_b_,_a_);
  end;

 // ***************************************************************************
 function BiDictionary<A,B>.GetB(const _a_:A; out _b_:B):Boolean;
  begin
   Result := Fab.TryGetValue(_a_,_b_);
  end;

 // ***************************************************************************
 function BiDictionary<A,B>.ContainA(const _a_:A):Boolean;
  begin
   Result := Fab.ContainsKey(_a_);
  end;

 // ***************************************************************************
 function BiDictionary<A,B>.ContainB(const _b_:B):Boolean;
  begin
   Result := Fba.ContainsKey(_b_);
  end;

end.
