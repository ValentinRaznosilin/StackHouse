{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : Low-level wrapper over TArray<T>                                 *}
{* Change  : 15.09.2016 (1366 lines)                                          *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2016 Raznosilin V.V.                                    *}
{******************************************************************************}

 unit lib32.Structures.DynamicArray;

 interface

 uses

  // system
  System.RTLConsts, System.SysUtils,
  // library
  lib32.Common, lib32.Func.Core;

 type

  TShellTab = array [0..31] of Int64;

  // comment this to avoid check index of single item
  {$DEFINE CheckIndex}

  // comment this to avoid check indexes of multiple items
  {$DEFINE CheckIndexes}

  // comment this to avoid check work subrange [A..B]
  {$DEFINE CheckParam}

  // comment this to pure QuickSort
  // uncomment to prevent recursive calls for subarray < QS_DEPTH_LIMIT
  {$DEFINE SmartQuickSort}

  ArrayOf<T> = record

   strict private

    class constructor Create;

   public

    type

     ItemPointer   = ^T;
     ItemCompare   = func_Compare<T>;
     ItemFormat    = func_Format<T>;
     ItemPredicate = fref_ConstItemAction <T,Boolean>;
     ItemAction    = pref_VarItemAction<T>;

    class var CMP : ItemCompare;
    class var FMT : ItemFormat;

   private

    function  GetItem(Index:Int32):T;
    procedure SetItem(Index:Int32; const Value:T);
    function  GetLast:Int32;
    function  GetCount:Int32;

   public

    Items : TArray<T>;

    // Items : TArray<T>   - Length(Items) >= 1;
    // A,B   : Integer     - work subrange [A..B]; A >= 0; B < Length(Items); A <= B;
    // CMP   : ItemCompare - pointer to comparator must be assigned;
    function ValidParams(const A,B:Int32; const CMP:ItemCompare):Boolean; overload;
    function ValidParams(const A,B:Int32):Boolean; overload;
    // all indexes must be in range [0..High(Items)]
    function ValidIndexes(const Indexes:array of Int32):Boolean;
    function AmendIndexes(const Indexes:array of Int32):TArray<Int32>;

    // constructor & destructor
    procedure   Clear;
    constructor Create(const ItemCount:Int32); overload;
    constructor Create(const Source:array of T); overload;
    procedure   Destroy(const DestroyItem:ItemAction);
    // modify
    procedure SetValue(const Value:T); overload;
    procedure SetValue(const A,B:Int32; const Value:T); overload;
    procedure Shake(const Count:Int32); overload;
    procedure Shake(const A,B,Count:Int32); overload;
    procedure Reverse; overload;
    procedure Reverse(const A,B:Int32); overload;
    procedure Shift(const ShiftCount:Int32); overload;
    procedure Shift(const A,B,ShiftCount:Int32); overload;
    function  Copy:ArrayOf<T>;
    function  Select(const A,B:Int32):ArrayOf<T>; overload;
    function  Select(const Indexes:array of Int32):ArrayOf<T>; overload;
    function  Select(const Condition:ItemPredicate):ArrayOf<T>; overload;
    function  Extract(const Index:Int32):T; overload;
    function  Extract(const A,B:Int32):ArrayOf<T>; overload;
    function  Extract(const Indexes:array of Int32):ArrayOf<T>; overload;
    function  Extract(const Condition:ItemPredicate):ArrayOf<T>; overload;
    procedure Append(const Arr:array of T); overload;
    procedure Append(const Arr:ArrayOf<T>); overload;
    function  Insert(const Index:Int32; const Arr:array of T):Int32; overload;
    function  Insert(const Index:Int32; const Arr:ArrayOf<T>):Int32; overload;
    function  Remove(const Index:Int32):Int32; overload;
    function  Remove(const A,B:Int32):Int32; overload;
    function  Remove(const Indexes:array of Int32):Int32; overload;
    function  Remove(const Condition:ItemPredicate):Int32; overload;
    function  RemoveCopies:Int32; overload;
    function  RemoveCopies(const A,B:Int32):Int32; overload;
    // format
    function  ToString(const FmtParam:AnsiString=''):String; overload;
    function  ToString(const A,B:Int32; const FmtParam:AnsiString=''):String; overload;
    // order
    function IsOrder:Boolean; overload;
    function IsOrder(const A,B:Int32; out OrderSign:Int32):Boolean; overload;
    function OrderOf:TOrderOfItems; overload;
    function OrderOf(const A,B:Int32):TOrderOfItems; overload;
    function SwingOf:TArray<Int32>; overload;
    function SwingOf(const A,B:Int32):TArray<Int32>; overload;
    // linear search
    function IndexOf(const Item:T):Int32; overload;
    function IndexOf(const Item:T; const A,B:Int32):Int32; overload;
    function CountOf(const Item:T):Int32; overload;
    function CountOf(const Item:T; const A,B:Int32):Int32; overload;
    function FindAll(const Item:T):TArray<Int32>; overload;
    function FindAll(const Item:T; const A,B:Int32):TArray<Int32>; overload;
    function Indexes(const Arr:array of T):TArray<Int32>; overload;
    function Indexes(const Arr:array of T; const A,B:Int32):TArray<Int32>; overload;
    function Indexes(const Condition:ItemPredicate):TArray<Int32>; overload;
    // binary search
    function BinIndex(const Item:T):Int32; overload;
    function BinIndex(const Item:T; const A,B:Int32):Int32; overload;
    function BinIndexes(const Arr:array of T):TArray<Int32>; overload;
    function BinIndexes(const Arr:array of T; const A,B:Int32):TArray<Int32>; overload;
    function BinPos(const Item:T):Int32; overload;
    function BinPos(const Item:T; const A,B:Int32):Int32; overload;
    // max & min
    function Max:Int32; overload;
    function Max(const A,B:Int32):Int32; overload;
    function Min:Int32; overload;
    function Min(const A,B:Int32):Int32; overload;
    // sort
    function ShellSort:Boolean; overload;
    function ShellSort(const A,B:Int32):Boolean; overload;
    function QuickSort:Boolean; overload;
    function QuickSort(const A,B:Int32):Boolean; overload;
    function ShakeSort:Boolean; overload;
    function ShakeSort(const A,B:Int32):Boolean; overload;
    function InsertionSort:Boolean; overload;
    function InsertionSort(const A,B:Int32):Boolean; overload;

    class operator Implicit(const Value:ArrayOf<T>):TArray<T>;
    class operator Explicit(const Value:ArrayOf<T>):TArray<T>;

    property Last:Int32 read GetLast;
    property Count:Int32 read GetCount;
    property Item[Index:Int32]:T read GetItem write SetItem; default;

  end;

 const

  {$region 'Table of Increments for Shell Sort'}
  ShellIncTab : TShellTab =
   (1,               // 0
    5,               // 1
    19,              // 2
    41,              // 3
    109,             // 4
    209,             // 5
    505,             // 6
    929,             // 7
    2161,            // 8
    3905,            // 9
    8929,            // 10
    16001,           // 11
    36289,           // 12
    64769,           // 13
    146305,          // 14
    260609,          // 15
    587521,          // 16
    1045505,         // 17
    2354689,         // 18
    4188161,         // 19
    9427969,         // 20
    16764929,        // 21
    37730305,        // 22
    67084289,        // 23
    150958081,       // 24
    268386305,       // 25
    603906049,       // 26
    1073643521,      // 27
    2415771649,      // 28
    4294770689,      // 29
    9663381505,      // 30
    17179475969);    // 31
  {$endregion}

  Arr_LBracket   = '[';
  Arr_RBracket   = ']';
  Arr_Delim      = ';';
  Arr_Empty      = Arr_LBracket + Arr_RBracket;
  QS_DEPTH_LIMIT = 32;

 function  GetShellCount(const L:Int64):Integer;
 procedure GetShellIncrement(const L:Int64; out A:TShellTab);
 function  LinksCount(const P:Pointer):UInt32;

 implementation

 // calculation of the number of increments used to Shell sort ****************
 function GetShellCount(const L:Int64):Integer;
  var i : Int32;
  begin
   if L=0 then Exit(-1);
   Result := 0;
   for i:=0 to 31 do if 3*ShellIncTab[i]>L then Break;
   if i>0 then Result := i-1;
  end;

 // calculation table of increments for Shell sort (formula of Sedgewick) *****
 procedure GetShellIncrement(const L:Int64; out A:TShellTab);
  var p1,p2,p3 : Int64;
      s        : Int32;
  begin
   p1 :=  1;
   p2 :=  1;
   p3 :=  1;
   s  := -1;
   repeat
    Inc(s);
    if (s mod 2)=1 then A[s] := 8*p1 - 6*p2 + 1 else
     begin
      A[s] := 9*(p1 - p3) + 1;
      p2   := p2 shl 1;
      p3   := p3 shl 1;
     end;
    p1 := p1 shl 1;
   until 3*A[s]>L;
  end;

 // ***************************************************************************
 // use only for :
 // string        - P as @<identifier>[1]
 // dynamic array - P as @<identifier>[0]
 function LinksCount(const P:Pointer):UInt32;
  var i : ^UInt32;
  begin
   if P=Nil then Exit(0);
   i := Pointer(UInt64(P)-8);
   Result := i^;
  end;

 // ************************************************************************* //
 //  ArrayOf<T>                                                               //
 // ************************************************************************* //

 // ***************************************************************************
 class constructor ArrayOf<T>.Create;
  begin
   // setup default comparer & formatter for type T
   CMP := func_<T>.Inst['cmp'];
   FMT := func_<T>.Inst['fmt'];
  end;

 // ***************************************************************************
 function ArrayOf<T>.GetItem(Index:Int32):T;
  begin
   {$IFDEF CheckIndex}
   if (Index<0) or (Index>High(Items)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   Result := Items[Index];
  end;

 // ***************************************************************************
 procedure ArrayOf<T>.SetItem(Index:Int32; const Value:T);
  begin
   {$IFDEF CheckIndex}
   if (Index<0) or (Index>High(Items)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   Items[Index] := Value;
  end;

 // ***************************************************************************
 function ArrayOf<T>.GetLast:Int32;
  begin
   Result := High(Items);
  end;

 // ***************************************************************************
 function ArrayOf<T>.GetCount:Int32;
  begin
   Result := Length(Items);
  end;

 // ***************************************************************************
 function ArrayOf<T>.ValidParams(const A,B:Int32; const CMP:ItemCompare):Boolean;
  var L : Int32;
  begin
   L := Length(Items);
   Result :=
    (L>=1) and              // array must contain at least 1 item
    (A<=B) and              // A must be less or equal B
    (A>=0) and (B<=L-1) and // work subarray must be in [0..L-1]
    Assigned(CMP);          // compare function must be assigned
  end;

 // ***************************************************************************
 function ArrayOf<T>.ValidParams(const A,B:Int32):Boolean;
  var L : Int32;
  begin
   L := Length(Items);
   Result :=
    (L>=1) and              // array must contain at least 1 item
    (A<=B) and              // A must be less or equal B
    (A>=0) and (B<=L-1);    // work subarray must be in [0..L-1]
  end;

 // ***************************************************************************
 function ArrayOf<T>.ValidIndexes(const Indexes:array of Int32):Boolean;
  var i,L,C : Int32;
  begin
   Result := false;
   C      := Length(Items);
   L      := Length(Indexes);
   if (C=0) or (L=0) then Exit;
   for i:=0 to L-1 do if (Indexes[i]<0) or (Indexes[i]>=C) then Exit;
   Result := true;
  end;

 // ***************************************************************************
 function ArrayOf<T>.AmendIndexes(const Indexes:array of Int32):TArray<Int32>;
  var i,L,C,N : Int32;
  begin
   Result := Nil;
   C      := Length(Items);
   L      := Length(Indexes);
   if (C=0) or (L=0) then Exit;
   N := 0;
   SetLength(Result,Length(Indexes));
   for i:=0 to L-1 do
    begin
     if (Indexes[i]<0) or (Indexes[i]>=C) then Continue;
     Result[N] := Indexes[i];
     Inc(N);
    end;
   SetLength(Result,N);
  end;

 // ***************************************************************************
 procedure ArrayOf<T>.Clear;
  begin
   Items := Nil;
  end;

 // ***************************************************************************
 constructor ArrayOf<T>.Create(const ItemCount:Int32);
  begin
   SetLength(Items,ItemCount);
  end;

 // ***************************************************************************
 constructor ArrayOf<T>.Create(const Source:array of T);
  var i : Int32;
  begin
   Items := Nil;
   if Length(Source)=0 then Exit;
   SetLength(Items,Length(Source));
   for i:=0 to High(Source) do Items[i] := Source[i];
  end;

 // ***************************************************************************
 procedure ArrayOf<T>.Destroy(const DestroyItem:ItemAction);
  var i : int32;
  begin
   if Assigned(DestroyItem) then
    for i:=0 to High(Items) do DestroyItem(Items[i],i);
   Items := Nil;
  end;

 // ***************************************************************************
 class operator ArrayOf<T>.Explicit(const Value:ArrayOf<T>):TArray<T>;
  begin
   Result := Value.Items;
  end;

 // ***************************************************************************
 class operator ArrayOf<T>.Implicit(const Value:ArrayOf<T>):TArray<T>;
  begin
   Result := Value.Items;
  end;

 // ***************************************************************************
 procedure ArrayOf<T>.SetValue(const Value:T);
  var i : Int32;
  begin
   for i:=0 to High(Items) do Items[i] := Value;
  end;

 // ***************************************************************************
 procedure ArrayOf<T>.SetValue(const A,B:Integer; const Value:T);
  var i : Int32;
  begin
   {$IFDEF CheckParam}
   if not ValidParams(A,B) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   for i:=A to B do Items[i] := Value;
  end;

 // syntactic sugar ***********************************************************
 procedure ArrayOf<T>.Shake(const Count:Int32);
  begin
   Shake(0,High(Items),Count);
  end;

 // ***************************************************************************
 procedure ArrayOf<T>.Shake(const A,B,Count:Int32);
  var i,n,a_,b_ : Int32;
      tmp       : T;
  begin
   {$IFDEF CheckParam}
   if not ValidParams(A,B) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   if A=B then Exit;
   n := B - A + 1;
   Randomize;
   for i:=1 to Count do
    begin
     a_        := A + Random(n);
     b_        := A + Random(n);
     tmp       := Items[a_];
     Items[a_] := Items[b_];
     Items[b_] := tmp;
    end;
  end;

 // syntactic sugar ***********************************************************
 procedure ArrayOf<T>.Reverse;
  begin
   Reverse(0,High(Items));
  end;

 // ***************************************************************************
 procedure ArrayOf<T>.Reverse(const A,B:Int32);
  var i1,i2 : Int32;
      tmp   : T;
  begin
   {$IFDEF CheckParam}
   if not ValidParams(A,B) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   if A=B then Exit;
   i2 := B;
   for i1:=A to A+((B-A+1) div 2)-1 do
    begin
     tmp       := Items[i1];
     Items[i1] := Items[i2];
     Items[i2] := tmp;
     Dec(i2);
    end;
  end;

 // syntactic sugar ***********************************************************
 procedure ArrayOf<T>.Shift(const ShiftCount:Int32);
  begin
   Shift(0,High(Items),ShiftCount);
  end;

 // ***************************************************************************
 procedure ArrayOf<T>.Shift(const A,B,ShiftCount:Int32);
  var i,k,C : Int32;
      arr   : TArray<T>;
  begin
   {$IFDEF CheckParam}
   if not ValidParams(A,B) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   C := B - A + 1;
   k := Abs(ShiftCount);
   if k>C then k := k mod C;
   if (C=1) or (k=0) then Exit;
   if ShiftCount<0 then
    begin
     arr := System.Copy(Items,A,k);
     for i:=0 to k-1 do Items[A+i] := Default(T);
     System.Move(Items[A+k],Items[A],(C-k)*SizeOf(T));
     Fillchar(Items[B-k+1],k*SizeOf(T),0);
     System.Move(arr[0],Items[B-k+1],k*SizeOf(T));
     Fillchar(arr[0],k*SizeOf(T),0);
    end
   else
    begin
     arr := System.Copy(Items,B-k+1,k);
     for i:=0 to k-1 do Items[B-i] := Default(T);
     System.Move(Items[A],Items[A+k],(C-k)*SizeOf(T));
     Fillchar(Items[A],k*SizeOf(T),0);
     System.Move(arr[0],Items[A],k*SizeOf(T));
     Fillchar(arr[0],k*SizeOf(T),0);
    end
  end;

 // ***************************************************************************
 function ArrayOf<T>.Copy:ArrayOf<T>;
  begin
   Result.Items := System.Copy(Items,0,Length(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.Select(const A,B:Int32):ArrayOf<T>;
  begin
   {$IFDEF CheckParam}
   if not ValidParams(A,B) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   Result.Items := System.Copy(Items,A,B-A+1);
  end;

 // ***************************************************************************
 function ArrayOf<T>.Select(const Indexes:array of Int32):ArrayOf<T>;
  var i,L,C : Int32;
  begin
   Result.Clear;
   C := Length(Items);
   L := Length(Indexes);
   if (C=0) or (L=0) then Exit;
   {$IFDEF CheckIndexes}
   if not ValidIndexes(Indexes) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   //
   SetLength(Result.Items,L);
   for i:=0 to L-1 do Result.Items[i] := Items[Indexes[i]];
  end;

 // ***************************************************************************
 function ArrayOf<T>.Select(const Condition:ItemPredicate):ArrayOf<T>;
  var i,N : Int32;
  begin
   Result.Clear;
   if (not Assigned(Condition)) or (Items=Nil) then Exit;
   //
   SetLength(Result.Items,Length(Items));
   N := 0;
   for i:=0 to High(Items) do
    if Condition(Items[i],i) then
     begin
      Result.Items[N] := Items[i];
      Inc(N);
     end;
   SetLength(Result.Items,N);
  end;

 // ***************************************************************************
 function ArrayOf<T>.Extract(const Index:Int32):T;
  begin
   {$IFDEF CheckIndex}
   if (Index<0) or (Index>=Length(Items)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   Result := Items[Index];
   Remove(Index);
  end;

 // ***************************************************************************
 function ArrayOf<T>.Extract(const A,B:Int32):ArrayOf<T>;
  begin
   Result := Select(A,B);
   if Result.Items<>Nil then Remove(A,B);
  end;

 // ***************************************************************************
 function ArrayOf<T>.Extract(const Indexes:array of Int32):ArrayOf<T>;
  begin
   Result := Select(Indexes);
   if Result.Items<>Nil then Remove(Indexes);
  end;

 // ***************************************************************************
 function ArrayOf<T>.Extract(const Condition:ItemPredicate):ArrayOf<T>;
  begin
   Result := Select(Condition);
   if Result.Items<>Nil then Remove(Condition);
  end;

 // ***************************************************************************
 procedure ArrayOf<T>.Append(const Arr:array of T);
  var L1,L2,i,j : Int32;
  begin
   L1 := Length(Items);
   L2 := Length(Arr);
   if L2=0 then Exit else
    begin
     j := L1;
     SetLength(Items,L1+L2);
     for i:=0 to L2-1 do
      begin
       Items[j] := Arr[i];
       Inc(j);
      end;
    end;
  end;

 // ***************************************************************************
 procedure ArrayOf<T>.Append(const Arr:ArrayOf<T>);
  begin
   Append(Arr.Items);
  end;

 // ***************************************************************************
 function ArrayOf<T>.Insert(const Index:Int32; const Arr:array of T):Int32;
  var i,L,C : Integer;
  begin
   Result := 0;
   C := Length(Items);
   L := Length(Arr);
   if L=0 then Exit;
   {$IFDEF CheckIndex}
   // Index = C is allowed ! (in this case its similar to Append)
   if (Index<0) or (Index>C) then Exit;
   {$ENDIF}
   SetLength(Items,C+L);
   if Index<>C then
    begin
     System.Move(Items[Index],Items[Index+L],(C-Index)*SizeOf(T));
     FillChar(Items[Index],L*SizeOf(T),0); // avoid links count decrease !
    end;
   for i:=0 to L-1 do Items[Index+i] := Arr[i];
   Result := L;
  end;

 // ***************************************************************************
 function ArrayOf<T>.Insert(const Index:Int32; const Arr:ArrayOf<T>):Int32;
  begin
   Result := Insert(Index,Arr.Items);
  end;

 // ***************************************************************************
 function ArrayOf<T>.Remove(const Index:Int32):Int32;
  var C : Int32;
  begin
   Result := 0;
   C := Length(Items);
   if C=0 then Exit;
   {$IFDEF CheckIndex}
   if (Index<0) or (Index>=C) then Exit;
   {$ENDIF}
   Items[Index] := Default(T); // force links count decrease !
   Dec(C);
   if Index<>C then
    begin
     System.Move(Items[Index+1],Items[Index],(C-Index)*SizeOf(T));
     FillChar(Items[C],SizeOf(T),0); // avoid links count decrease !
    end;
   SetLength(Items,C);
   Result := 1;
  end;

 // ***************************************************************************
 function ArrayOf<T>.Remove(const A,B:Int32):Int32;
  var i,C : Int32;
  begin
   Result := 0;
   C := Length(Items);
   if C=0 then Exit;
   {$IFDEF CheckIndex}
   if (A<0) or (B>=C) or (A>B) then Exit;
   {$ENDIF}
   // .........................................................................
   if A=B then Exit(Remove(A));
   // .........................................................................
   for i:=A to B do Items[i] := Default(T); // force links count decrease !
   Dec(C);
   if B<>C then
    begin
     System.Move(Items[B+1],Items[A],(C-B)*SizeOf(T));
     FillChar(Items[A+C-B],(B-A+1)*SizeOf(T),0); // avoid links count decrease !
    end;
   Dec(C,B-A);
   SetLength(Items,C);
   Result := B - A + 1;
  end;

 // ***************************************************************************
 // requires N memory !
 function ArrayOf<T>.Remove(const Indexes:array of Int32):Int32;
  var i,L,C,n1,n2,i1,i2 : Integer;
      b : TArray<UInt8>;
  begin
   Result := 0;
   L := Length(Indexes);
   C := Length(Items);
   if (L=0) or (C=0) then Exit;
   {$IFDEF CheckIndexes}
   if not ValidIndexes(Indexes) then Exit;
   {$ENDIF}
   // .........................................................................
   if L=1 then Exit(Remove(Indexes[0]));
   // .........................................................................
   SetLength(b,C);
   FillChar(b[0],C,0);
   for i:=0 to L-1 do
    begin
     Items[Indexes[i]] := Default(T); // force links count decrease !
     b[Indexes[i]]     := 1;          // mark removed item as "1"
    end;
   //
   n1 := -1;
   for i:=0 to C-1 do if b[i]=1 then begin n1 := i; Break; end;
   if n1=-1 then Exit;
   n2 := n1 + 1;
   while True do
    begin
     // look for next segment
     i1 := 0;
     i2 := 0;
     for i:=n2 to C-1 do if b[i]=0 then begin i1 := i; Break; end;
     if i1=0 then Break;
     for i:=i1 to C-1 do if b[i]=1 then begin i2 := i-1; Break; end;
     if i2=0 then i2 := C - 1;
     // move segment
     i := i2-i1+1;
     if i<>0 then System.Move(Items[i1],Items[n1],i*SizeOf(T));
     Inc(n1,i);
     n2 := i2+1;
    end;
   Result := C - n1;
   if Result<>0 then FillChar(Items[n1],Result*SizeOf(T),0);
   SetLength(Items,n1);
  end;

 // ***************************************************************************
 function ArrayOf<T>.Remove(const Condition:ItemPredicate):Int32;
  begin
   Result := Remove(Indexes(Condition));
  end;

 // ***************************************************************************
 function ArrayOf<T>.RemoveCopies:Int32;
  begin
   Result := RemoveCopies(0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.RemoveCopies(const A,B:Int32):Int32;
  var i,C,N : Int32;
      arr   : ArrayOf<T>;
      uniq  : Boolean;
  begin
   Result := 0;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then Exit;
   {$ENDIF}
   C := B - A + 1;
   if (C=0) or (A=B) then Exit;
   // sort array forcibly if need
   if not IsOrder then QuickSort;
   // do pass over Items
   arr.Create(C);
   arr.Items[A] := Items[A];
   N := 1;
   for i:=A+1 to B-1 do
    begin
     uniq := (CMP(Items[i],Items[i-1])<>0) and (CMP(Items[i],Items[i+1])<>0);
     if uniq or (arr.BinIndex(Items[i],0,N-1)=-1) then
      begin
       arr.Items[N] := Items[i];
       Inc(N);
      end;
    end;
   uniq := CMP(Items[B-1],Items[B])<>0;
   if uniq or (arr.BinIndex(Items[B],0,N-1)=-1) then
    begin
     arr.Items[N] := Items[B];
     Inc(N);
    end;
   //
   Result := C - N;
   Items  := System.Copy(arr.Items,0,N);
  end;

 // ***************************************************************************
 function ArrayOf<T>.ToString(const FmtParam:AnsiString=''):String;
  begin
   Result := ToString(0,High(Items),FmtParam);
  end;

 // ***************************************************************************
 function ArrayOf<T>.ToString(const A,B:Int32; const FmtParam:AnsiString=''):String;
  var i : Int32;
      s : String;
  begin
   Result := '';
   if not Assigned(FMT) then Exit;
   {$IFDEF CheckParam}
   if not ValidParams(A,B) then Exit;
   {$ENDIF}
   for i:=A to B-1 do Result := Result + FMT(Items[i],FmtParam) + Arr_Delim + ' ';
   Result := Result + FMT(Items[B],FmtParam);
  end;

 // ***************************************************************************
 function ArrayOf<T>.IsOrder:Boolean;
  var i : Int32;
  begin
   Result := IsOrder(0,High(Items),i);
  end;

 // ***************************************************************************
 // -1 : ASC
 // +1 : DSC
 //  0 : Const
 function ArrayOf<T>.IsOrder(const A,B:Int32; out OrderSign:Int32):Boolean;
  var i,R    : Integer;
      _neg_  : Integer;
      _pos_  : Integer;
      _zero_ : Integer;
  begin
   Result    := False;
   OrderSign := 0;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   if A=B then Exit(True);
   _neg_  := 0;
   _pos_  := 0;
   _zero_ := 0;
   for i:=A to B-1 do
    begin
     R := CMP(Items[i],Items[i+1]);
     if R<0 then Inc(_neg_) else
     if R>0 then Inc(_pos_) else Inc(_zero_);
     if (_neg_<>0) and (_pos_<>0) then Exit;
    end;
   if _neg_<>0 then OrderSign := -1 else
   if _pos_<>0 then OrderSign := 1;
   Result := True;
  end;

 // ***************************************************************************
 function ArrayOf<T>.OrderOf:TOrderOfItems;
  begin
   Result := OrderOf(0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.OrderOf(const A,B:Int32):TOrderOfItems;
  var ordersign : Integer;
  begin
   Result := ordUnordered;
   if not IsOrder(A,B,ordersign) then Exit;
   if ordersign<0 then Result := ordASC else
   if ordersign>0 then Result := ordDSC else Result := ordConst;
  end;

 // ***************************************************************************
 function ArrayOf<T>.SwingOf:TArray<Int32>;
  begin
   Result := SwingOf(0,High(Items));
  end;

 // ***************************************************************************
 // вычисляет длины участков монотонности знака порядка в подмассиве от A до B
 // участки со знаком "0" добавляются к предшествующим участкам "-1" или "1"
 // минимальная длина участка = 2
 // максимальная длина участка = B-A+1 и означает, что подмассив полностью упорядочен
 // сумма размеров всех участков в точности соответсвует размеру подмассива и равна B-A+1
 function ArrayOf<T>.SwingOf(const A,B:Int32):TArray<Int32>;
  var i,n,k : Integer;
      _zero_,_neg_,_pos_,_sgn_,sum : Integer;
  begin
   Result := Nil;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   if A=B then
    begin
     SetLength(Result,1);
     Result[0] := 1;
     Exit;
    end;
   //
   SetLength(Result,B-A+1);
   n      := 0;
   _zero_ := 0;
   _neg_  := 0;
   _pos_  := 0;
   _sgn_  := 0;
   sum    := 0;
   for i:=A to B do
    begin
     if i=B then k := 0 else k := CMP(Items[i],Items[i+1]);
     if k<0 then Inc(_neg_) else if k>0 then Inc(_pos_) else Inc(_zero_);
     if (_sgn_=0) and (k<>0) then _sgn_ := k;
     if (_neg_<>0) and (_pos_<>0) then
      begin
       Result[n] := _sgn_ * (_pos_ + _neg_ + _zero_);
       Inc(sum,Abs(Result[n]));
       Inc(n);
       _zero_ := 0;
       _neg_  := 0;
       _pos_  := 0;
       _sgn_  := 0;
      end;
    end;
   //
   if sum<>B-A+1 then
    begin
     Result[n] := _sgn_ * (_pos_ + _neg_ + _zero_);
     Inc(sum,Abs(Result[n]));
     Inc(n);
    end;
   SetLength(Result,n);
  end;

 // ***************************************************************************
 function ArrayOf<T>.IndexOf(const Item:T):Int32;
  begin
   Result := IndexOf(Item,0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.IndexOf(const Item:T; const A,B:Int32):Int32;
  var i : Int32;
  begin
   Result := -1;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   for i:=A to B do if CMP(Items[i],Item)=0 then Exit(i);
  end;

 // ***************************************************************************
 function ArrayOf<T>.CountOf(const Item:T):Int32;
  begin
   Result := CountOf(Item,0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.CountOf(const Item:T; const A,B:Int32):Int32;
  var i : Int32;
  begin
   Result := 0;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   for i:=A to B do if CMP(Items[i],Item)=0 then Inc(Result);
  end;

 // ***************************************************************************
 function ArrayOf<T>.FindAll(const Item:T):TArray<Int32>;
  begin
   Result := FindAll(Item,0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.FindAll(const Item:T; const A,B:Int32):TArray<Int32>;
  var i : Int32;
      r : ArrayOf<Int32>;
  begin
   Result := Nil;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   for i:=A to B do if CMP(Items[i],Item)=0 then r.Append(i);
   Result := r.Items;
  end;

 // ***************************************************************************
 function ArrayOf<T>.Indexes(const Arr:array of T):TArray<Int32>;
  begin
   Result := Indexes(Arr,0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.Indexes(const Arr:array of T; const A,B:Int32):TArray<Int32>;
  var i,j,L,C : Int32;
  begin
   Result := Nil;
   L := Length(Arr);
   C := Length(Items);
   if (L=0) or (C=0) then Exit;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   SetLength(Result,L);
   for i:=0 to L-1 do
    begin
     Result[i] := -1;
     for j:=A to B do if CMP(Items[j],Arr[i])=0 then
      begin
       Result[i] := j;
       Break;
      end;
    end;
  end;

 // ***************************************************************************
 function ArrayOf<T>.Indexes(const Condition:ItemPredicate):TArray<Int32>;
  var i,C,N : Int32;
  begin
   Result := Nil;
   C := Length(Items);
   if (C=0) or (not Assigned(Condition)) then Exit;
   SetLength(Result,C);
   N := 0;
   for i:=0 to C-1 do if Condition(Items[i],i) then
    begin
     Result[N] := i;
     Inc(N);
    end;
   SetLength(Result,N);
  end;

 // ***************************************************************************
 function ArrayOf<T>.BinIndex(const Item:T):Int32;
  begin
   Result := BinIndex(Item,0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.BinIndex(const Item:T; const A,B:Int32):Int32;
  var left,right,middle,res : Integer;
  begin
   Result := -1;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   //
   if A=B then if CMP(Items[A],Item)=0 then Exit(A) else Exit(-1);
   //
   left  := A;
   right := B;
   while left<=right do
    begin
     middle := (left+right) shr 1;
     res    := CMP(Item,Items[middle]);
     if res=0 then
      begin
       while (middle>0) and (CMP(Item,Items[middle-1])=0) do Dec(middle);
       Exit(middle);
      end;
     if res=1 then left := middle + 1 else right := middle - 1;
    end;
  end;

 // ***************************************************************************
 function ArrayOf<T>.BinIndexes(const Arr:array of T):TArray<Int32>;
  begin
   Result := BinIndexes(Arr,0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.BinIndexes(const Arr:array of T; const A,B:Int32):TArray<Int32>;
  label SaveIndex;
  var
   i,L,C,idx             : Int32;
   left,right,middle,res : Int32;
  begin
   Result := Nil;
   L := Length(Arr);
   C := Length(Items);
   if (L=0) or (C=0) then Exit;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   //
   SetLength(Result,C);
   for i:=0 to C-1 do
    begin
     idx := -1;
     if A=B then
      begin
       if CMP(Items[A],Arr[i])=0 then idx := A;
       GOTO SaveIndex;
      end;
     left  := A;
     right := B;
     while left<=right do
      begin
       middle := (left+right) shr 1;
       res    := CMP(Arr[i],Items[middle]);
       if res=0 then
        begin
         while (middle>0) and (CMP(Arr[i],Items[middle-1])=0) do Dec(middle);
         idx := middle;
         GOTO SaveIndex;
        end;
       if res=1 then left := middle + 1 else right := middle - 1;
      end;
     SaveIndex : Result[i] := idx;
    end;
  end;

 // ***************************************************************************
 function ArrayOf<T>.BinPos(const Item:T):Int32;
  begin
   Result := BinPos(Item,0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.BinPos(const Item:T; const A,B:Int32):Int32;
  var left,right,middle : Integer;
  begin
   Result := -1;
   if Items=Nil then Exit(0);
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   //
   if CMP(Item,Items[A])<0  then Exit(A);
   if CMP(Item,Items[B])>=0 then Exit(B+1);
   //
   left  := A;
   right := B;
   while left<right do
    begin
     middle := (left+right) shr 1;
     if CMP(Items[middle],Item)<0
      then left  := middle + 1
      else right := middle;
    end;
   Result := right;
  end;

 // ***************************************************************************
 function ArrayOf<T>.Max:Int32;
  begin
   Result := Max(0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.Max(const A,B:Int32):Int32;
  var i : Int32;
  begin
   Result := -1;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   if A=B then Exit(A);
   Result := A;
   for i:=A to B do if CMP(Items[Result],Items[i])=-1 then Result := i;
  end;

 // ***************************************************************************
 function ArrayOf<T>.Min:Int32;
  begin
   Result := Min(0,High(Items));
  end;

 // ***************************************************************************
 function ArrayOf<T>.Min(const A,B:Int32):Int32;
  var i : Int32;
  begin
   Result := -1;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   if A=B then Exit(A);
   Result := A;
   for i:=A to B do if CMP(Items[Result],Items[i])=1 then Result := i;
  end;

 // ***************************************************************************
 function ArrayOf<T>.ShellSort:Boolean;
  begin
   Result := ShellSort(0,High(Items));
  end;

 // ***************************************************************************
 // Best    - N
 // Average - N*(log N)^2 or N^(3/2)
 // Worst   - depends on gap sequence; Best known : N*(log N)^2
 // Memory  - 1
 // Stable  - No
 // Method  - Insertion
 function ArrayOf<T>.ShellSort(const A,B:Int32):Boolean;
  var h,i,j,n : Integer;
      temp    : T;
  begin
   Result := false;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   if A=B then Exit(true);
   for n := GetShellCount(B-A+1) downto 0 do
    begin
     h := ShellIncTab[n];
     for i:=A+h to B do
      begin
       temp := Items[i];
       j    := i - h;
       while (j>=A) and (CMP(Items[j],temp)=1) do
        begin
         Items[j+h] := Items[j];
         Dec(j,h);
        end;
       Items[j+h] := temp;
      end;
    end;
   Result := true;
  end;

 // ***************************************************************************
 function ArrayOf<T>.QuickSort:Boolean;
  begin
   Result := QuickSort(0,High(Items));
  end;

 // ***************************************************************************
 // Best    - N*log N
 // Average - N*log N
 // Worst   - N^2
 // Memory  - log N
 // Stable  - No
 // Method  - Partitioning
 function ArrayOf<T>.QuickSort(const A,B:Int32):Boolean;
  var I,J,L,R : Integer;
      P,Temp  : T;
  begin
   Result := false;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   if A=B then Exit(true);
   L := A;
   R := B;
   repeat
    I := L;
    J := R;
    P := Items[(L + R) shr 1];
    repeat
     while CMP(Items[I],P)<0 do Inc(I);
     while CMP(Items[J],P)>0 do Dec(J);
     if I<=J then
      begin
       Temp     := Items[I]; // этот обмен можно делать только если I<J
       Items[I] := Items[J]; // тогда порядок одинаковых элементов не будет нарушен?
       Items[J] := Temp;     //
       Inc(I);
       Dec(J);
      end;
    until I > J;
    {$IFDEF SmartQuickSort}
    if L<J then
     begin
      if J-L+1<QS_DEPTH_LIMIT
       then InsertionSort(L,J)
       else QuickSort(L,J);
     end;
    {$ELSE}
    if L<J then QuickSort(L,J);
    {$ENDIF}
    L := I;
   until I>=R;
   Result := true;
  end;

 // ***************************************************************************
 function ArrayOf<T>.ShakeSort:Boolean;
  begin
   Result := ShakeSort(0,High(Items));
  end;

 // ***************************************************************************
 // Best    - N
 // Average - N^2
 // Worst   - N^2
 // Memory  - 1
 // Stable  - Yes
 // Method  - Exchanging
 // !!! use this for small array (<2500 items) if you care for stability of equal items
 function ArrayOf<T>.ShakeSort(const A,B:Int32):Boolean;
  var L,R,i,Last : Int32;
      Temp       : T;
  begin
   Result := false;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   if A=B then Exit(true);
   L    := A;
   R    := B-1;
   Last := B-1;
   while true do
    begin
     // свигаем к концу массива "легкие элементы"
     for i:=R downto L do
      if CMP(Items[i],Items[i+1])=1 then
       begin
        Temp       := Items[I];
        Items[I]   := Items[I+1];
        Items[I+1] := Temp;
        Last       := i;
       end;
     L := Last + 1;
     if L>R then Break;
     // сдвигаем к началу массива "тяжелые элементы"
     for i:=L to R do
      if CMP(Items[i],Items[i+1])=1 then
       begin
        Temp       := Items[I];
        Items[I]   := Items[I+1];
        Items[I+1] := Temp;
        Last       := i;
       end;
     R := Last - 1;
     if L>R then Break;
    end;
   Result := true;
  end;

 // ***************************************************************************
 function ArrayOf<T>.InsertionSort:Boolean;
  begin
   Result := InsertionSort(0,High(Items));
  end;

 // ***************************************************************************
 // Best    - N
 // Average - N^2
 // Worst   - N^2
 // Memory  - 1
 // Stable  - Yes
 // Method  - Insertion
 // !!! use this for small array (<5000 items) if you care for stability of equal items
 function ArrayOf<T>.InsertionSort(const A,B:Int32):Boolean;
  var i,j  : Integer;
      temp : T;
  begin
   Result := false;
   {$IFDEF CheckParam}
   if not ValidParams(A,B,CMP) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   if A=B then Exit(true);
   for i:=A+1 to B do
    begin
     temp := Items[i];
     j    := i-1;
     while (j>=A) and (CMP(Items[j],temp)=1) do
      begin
       Items[j+1] := Items[j];
       Dec(j);
      end;
     Items[j+1] := temp;
    end;
   Result := true;
  end;

end.
