{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : Bit Operations                                                   *}
{* Change  : 29.12.2012 (960 lines)                                           *}
{* Comment : http://graphics.stanford.edu/~seander/bithacks.html              *}
{*                                                                            *}
{* Copyright (c) 2011-2012 Raznosilin V.V.                                    *}
{******************************************************************************}

{ TODO : Добавить функции Set_B для классов Bit8 и Bit32 }

 unit lib32.Util.Bits;

 interface

 const

  BinSet : set of Char = ['0'..'1'];
  DecSet : set of Char = ['0'..'9'];
  HexSet : set of Char = ['0'..'9','A'..'F'];
  BinNum : array [0.. 1] of Char = ('0','1');
  DecNum : array [0.. 9] of Char = ('0','1','2','3','4','5','6','7','8','9');
  HexNum : array [0..15] of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

 type

  // ************************************************************************ //
  Bit8 = class

   {$region 'Mask'}
   const

   Mask : array [1..8] of UInt8 =
    ($01, $03, $07, $0F,
     $1F, $3F, $7F, $FF);
   {$endregion}

   type

    AByte2  = array [0..1] of UInt8;
    AByte4  = array [0..3] of UInt8;
    AByte8  = array [0..7] of UInt8;
    AByte22 = array [0..1] of UInt16;
    AByte44 = array [0..1] of UInt32;

   class var Table_BinStr    : array [0..255] of String[8];
   class var Table_HexStr    : array [0..255] of String[2];
   class var Table_BitCount  : array [0..255] of Int8;
   class var Table_BitFirst0 : array [0..255] of Int8;
   class var Table_BitLast0  : array [0..255] of Int8;
   class var Table_BitFirst1 : array [0..255] of Int8;
   class var Table_BitLast1  : array [0..255] of Int8;
   class var Table_Reverse   : array [0..255] of Int8;

   // init lookup tables
   class procedure Init;
   // conversion
   class function  ToStrBin     (const Val:UInt8):AnsiString; inline;
   class function  ToStrHex     (const Val:UInt8):AnsiString; inline;
   class function  BinToHex     (const Val:AnsiString):AnsiString;
   class function  HexToBin     (const Val:AnsiString):AnsiString;
   class function  FromStrBin   (const Val:AnsiString):UInt8;
   class function  FromStrHex   (const Val:AnsiString):UInt8;
   class function  ToBoolArray  (const Val:UInt8):TArray<Boolean>;
   class function  ToIntArray   (const Val:UInt8):TArray<Uint8>;
   class function  FromBoolArray(const Arr:array of Boolean):UInt8;
   class function  FromIntArray (const Arr:array of UInt8):UInt8;
   // state
   class function  Get_I  (const Val:UInt8; const Index:Int32):UInt8; overload; inline;
   class function  Get_I  (const Val:UInt8; const From,Size:Int32):UInt8; overload; inline;
   class function  Get_B  (const Val:UInt8; const Index:Int32):Boolean; inline;
   class function  Count_0(const Val:UInt8):Int32; inline;
   class function  Count_1(const Val:UInt8):Int32; inline;
   class function  First_0(const Val:UInt8):Int32; inline;
   class function  Last_0 (const Val:UInt8):Int32; inline;
   class function  First_1(const Val:UInt8):Int32; inline;
   class function  Last_1 (const Val:UInt8):Int32; inline;
   // modify
   class procedure Set_I  (const Bit:UInt8; var Val:UInt8; const Index:Int32); overload; inline;
   class procedure Set_I  (const Bit:UInt8; var Val:UInt8; const From,Size:Int32); overload; inline;
   class procedure Set_0  (var Val:UInt8; const Index:Int32); inline;
   class procedure Set_1  (var Val:UInt8; const Index:Int32); inline;
   class procedure Tog    (var Val:UInt8; const Index:Int32); inline;
   class procedure Swap   (var A,B:UInt8); inline;
   class procedure Reverse(var Val:UInt8); inline;

  end;

  // ************************************************************************ //
  Bit16 = class

   {$region 'Mask'}
   const

   Mask : array [1..16] of UInt16 =
    ($0001, $0003, $0007, $000F,
     $001F, $003F, $007F, $00FF,
     $01FF, $03FF, $07FF, $0FFF,
     $1FFF, $3FFF, $7FFF, $FFFF);
   {$endregion}

   // conversion
   class function  ToStrBin     (const Val:UInt16):AnsiString; inline;
   class function  ToStrHex     (const Val:UInt16):AnsiString; inline;
   class function  FromStrBin   (const Val:AnsiString):UInt16;
   class function  FromStrHex   (const Val:AnsiString):UInt16;
   class function  ToBoolArray  (const Val:UInt16):TArray<Boolean>;
   class function  ToIntArray   (const Val:UInt16):TArray<Uint8>;
   class function  FromBoolArray(const Arr:array of Boolean):UInt16;
   class function  FromIntArray (const Arr:array of UInt8):UInt16;
   // state
   class function  Get_I  (const Val:UInt16; const Index:Int32):UInt16; overload; inline;
   class function  Get_I  (const Val:UInt16; const From,Size:Int32):UInt16; overload; inline;
   class function  Get_B  (const Val:UInt16; const Index:Int32):Boolean; inline;
   class function  Count_0(const Val:UInt16):Int32; inline;
   class function  Count_1(const Val:UInt16):Int32; inline;
   class function  First_0(const Val:UInt16):Int32; inline;
   class function  Last_0 (const Val:UInt16):Int32; inline;
   class function  First_1(const Val:UInt16):Int32; inline;
   class function  Last_1 (const Val:UInt16):Int32; inline;
   // modify
   class procedure Set_I  (const Bit:UInt16; var Val:UInt16; const Index:Int32); overload; inline;
   class procedure Set_I  (const Bit:UInt16; var Val:UInt16; const From,Size:Int32); overload; inline;
   class procedure Set_B  (const Bit:Boolean; var Val:UInt16; const Index:Int32); overload; inline;
   class procedure Set_0  (var Val:UInt16; const Index:Int32); inline;
   class procedure Set_1  (var Val:UInt16; const Index:Int32); inline;
   class procedure Tog    (var Val:UInt16; const Index:Int32); inline;
   class procedure Swap   (var A,B:UInt16); inline;
   class procedure Reverse(var Val:UInt16); inline;

  end;

  // ************************************************************************ //
  Bit32 = class

   {$region 'Mask'}
   const

   Mask : array [1..32] of UInt32 =
    ($00000001, $00000003, $00000007, $0000000F,
     $0000001F, $0000003F, $0000007F, $000000FF,
     $000001FF, $000003FF, $000007FF, $00000FFF,
     $00001FFF, $00003FFF, $00007FFF, $0000FFFF,
     $0001FFFF, $0003FFFF, $0007FFFF, $000FFFFF,
     $001FFFFF, $003FFFFF, $007FFFFF, $00FFFFFF,
     $01FFFFFF, $03FFFFFF, $07FFFFFF, $0FFFFFFF,
     $1FFFFFFF, $3FFFFFFF, $7FFFFFFF, $FFFFFFFF);
   {$endregion}

   // conversion
   class function  ToStrBin     (const Val:UInt32):AnsiString; inline;
   class function  ToStrHex     (const Val:UInt32):AnsiString; inline;
   class function  FromStrBin   (const Val:AnsiString):UInt32;
   class function  FromStrHex   (const Val:AnsiString):UInt32;
   class function  ToBoolArray  (const Val:UInt32):TArray<Boolean>;
   class function  ToIntArray   (const Val:UInt32):TArray<Uint8>;
   class function  FromBoolArray(const Arr:array of Boolean):UInt32;
   class function  FromIntArray (const Arr:array of UInt8):UInt32;
   // state
   class function  Get_I  (const Val:UInt32; const Index:Int32):UInt32; overload; inline;
   class function  Get_I  (const Val:UInt32; const From,Size:Int32):UInt32; overload; inline;
   class function  Get_B  (const Val:UInt32; const Index:Int32):Boolean; inline;
   class function  Count_0(const Val:UInt32):Int32; inline;
   class function  Count_1(const Val:UInt32):Int32; inline;
   class function  First_0(const Val:UInt32):Int32; inline;
   class function  Last_0 (const Val:UInt32):Int32; inline;
   class function  First_1(const Val:UInt32):Int32; inline;
   class function  Last_1 (const Val:UInt32):Int32; inline;
   // modify
   class procedure Set_I  (const Bit:UInt32; var Val:UInt32; const Index:Int32); overload; inline;
   class procedure Set_I  (const Bit:UInt32; var Val:UInt32; const From,Size:Int32); overload; inline;
   class procedure Set_0  (var Val:UInt32; const Index:Int32); inline;
   class procedure Set_1  (var Val:UInt32; const Index:Int32); inline;
   class procedure Tog    (var Val:UInt32; const Index:Int32); inline;
   class procedure Swap   (var A,B:UInt32); inline;
   class procedure Reverse(var Val:UInt32); inline;

  end;

 procedure Initialize;
 procedure Finalize;

 implementation

 var

  HexBin : array [Char] of String;
  HexVal : array [Char] of UInt8;

 // unit initialization *******************************************************
 procedure Initialize;
  begin
   HexBin[HexNum [0]] := '0000'; HexVal[HexNum [0]] := 0;
   HexBin[HexNum [1]] := '0001'; HexVal[HexNum [1]] := 1;
   HexBin[HexNum [2]] := '0010'; HexVal[HexNum [2]] := 2;
   HexBin[HexNum [3]] := '0011'; HexVal[HexNum [3]] := 3;
   HexBin[HexNum [4]] := '0100'; HexVal[HexNum [4]] := 4;
   HexBin[HexNum [5]] := '0101'; HexVal[HexNum [5]] := 5;
   HexBin[HexNum [6]] := '0110'; HexVal[HexNum [6]] := 6;
   HexBin[HexNum [7]] := '0111'; HexVal[HexNum [7]] := 7;
   HexBin[HexNum [8]] := '1000'; HexVal[HexNum [8]] := 8;
   HexBin[HexNum [9]] := '1001'; HexVal[HexNum [9]] := 9;
   HexBin[HexNum[10]] := '1010'; HexVal[HexNum[10]] := 10;
   HexBin[HexNum[11]] := '1011'; HexVal[HexNum[11]] := 11;
   HexBin[HexNum[12]] := '1100'; HexVal[HexNum[12]] := 12;
   HexBin[HexNum[13]] := '1101'; HexVal[HexNum[13]] := 13;
   HexBin[HexNum[14]] := '1110'; HexVal[HexNum[14]] := 14;
   HexBin[HexNum[15]] := '1111'; HexVal[HexNum[15]] := 15;
   Bit8.Init;
  end;

 // unit finalization *********************************************************
 procedure Finalize;
  begin
   //
  end;

 // ************************************************************************* //
 //  Bit8                                                                     //
 // ************************************************************************* //

 // ***************************************************************************
 class procedure Bit8.Init;
  var i,j,k : UInt8;
      a,b : Int32;
  begin
   Table_BitCount[0] := 0;
   for i:=0 to 255 do
    begin
     // Table_BinStr ..........................................................
     SetLength(Table_BinStr[i],8);
     k := 1;
     for j:=7 downto 0 do
      begin
       if (i and (1 shl j))<>0 then Table_BinStr[i][k] := '1'
                               else Table_BinStr[i][k] := '0';
       Inc(k);
      end;
     // Table_HexStr ..........................................................
     SetLength(Table_HexStr[i],2);
     Table_HexStr[i][1] := AnsiChar(HexNum[i shr 4  ]);
     Table_HexStr[i][2] := AnsiChar(HexNum[i and $0F]);
     // Table_BitCount ........................................................
     Table_BitCount[i] := (i and 1) + Table_BitCount[i div 2];
     // Table_BitFirst0 .......................................................
     Table_BitFirst0[i] := -1;
     for j:=0 to 7 do if (i and (1 shl j))=0 then
      begin
       Table_BitFirst0[i] := j;
       Break;
      end;
     // Table_BitLast0 ........................................................
     Table_BitLast0[i] := -1;
     for j:=7 downto 0 do if (i and (1 shl j))=0 then
      begin
       Table_BitLast0[i] := j;
       Break;
      end;
     // Table_BitFirst1 .......................................................
     Table_BitFirst1[i] := -1;
     for j:=0 to 7 do if (i and (1 shl j))<>0 then
      begin
       Table_BitFirst1[i] := j;
       Break;
      end;
     // Table_BitLast1 ........................................................
     Table_BitLast1[i] := -1;
     for j:=7 downto 0 do if (i and (1 shl j))<>0 then
      begin
       Table_BitLast1[i] := j;
       Break;
      end;
     // Table_Reverse .........................................................
     Table_Reverse[i] := (i * $0202020202 and $010884422010) mod 1023;
    end;
  end;

 // ***************************************************************************
 class function Bit8.ToStrBin(const Val:UInt8):AnsiString;
  begin
   Result := Table_BinStr[Val];
  end;

 // ***************************************************************************
 class function Bit8.ToStrHex(const Val:UInt8):AnsiString;
  begin
   Result := Table_HexStr[Val];
  end;

 // ***************************************************************************
 class function Bit8.BinToHex(const Val:AnsiString):AnsiString;
  var i,k,n,j : Integer;
      t : AnsiString;
  begin
   if Val='' then Exit('');
   // дополняем нулями, если нужно
   t := Val;
   k := Length(Val) mod 4;
   if k<>0 then for i:=1 to 4-k do t := '0' + t;
   //
   Result := '';
   k := Length(t);
   i := 1;
   while i<k do
    begin
     n := 0;
     if t[i]='1' then n := n + 8 else if t[i]<>'0' then Exit(''); Inc(i);
     if t[i]='1' then n := n + 4 else if t[i]<>'0' then Exit(''); Inc(i);
     if t[i]='1' then n := n + 2 else if t[i]<>'0' then Exit(''); Inc(i);
     if t[i]='1' then n := n + 1 else if t[i]<>'0' then Exit(''); Inc(i);
     Result := Result + AnsiChar(HexNum[n]);
    end;
  end;

 // ***************************************************************************
 class function Bit8.HexToBin(const Val:AnsiString):AnsiString;
  var i : Int32;
  begin
   Result := '';
   for i:=1 to Length(Val) do
    if Val[i] in HexSet then Result := Result + HexBin[Val[i]]
                        else Exit('');
  end;

 // ***************************************************************************
 class function Bit8.FromStrBin(const Val:AnsiString):UInt8;
  var i,j,k,n : Int32;
  begin
   n := Length(Val);
   if (n=0) or (n>8) then Exit(0);
   //
   j := 0;
   Result := 0;
   for i:=n downto 1 do
    begin
     if Val[i]='1' then Result := Result + 1 shl j else if Val[i]<>'0' then Exit(0);
     Inc(j);
    end;
  end;

 // ***************************************************************************
 class function Bit8.FromStrHex(const Val:AnsiString):UInt8;
  var n : Int32;
  begin
   n := Length(Val);
   if n=1 then Result := HexVal[Val[1]] else
   if n=2 then Result := 16 * HexVal[Val[1]] + HexVal[Val[2]] else Exit(0);
  end;

 // ***************************************************************************
 class function Bit8.ToBoolArray(const Val:UInt8):TArray<Boolean>;
  var i : Int32;
  begin
   SetLength(Result,8);
   for i:=0 to High(Result) do Result[i] := Get_B(Val,i);
  end;

 // ***************************************************************************
 class function Bit8.ToIntArray(const Val:UInt8):TArray<Uint8>;
  var i : Int32;
  begin
   SetLength(Result,8);
   for i:=0 to High(Result) do Result[i] := Get_I(Val,i);
  end;

 // ***************************************************************************
 class function Bit8.FromBoolArray(const Arr:array of Boolean):UInt8;
  var i : Int32;
  begin
   Result := 0;
   if Length(Arr)<8 then Exit;
   for i:=0 to 7 do if Arr[i] then Set_1(Result,i);
  end;

 // ***************************************************************************
 class function Bit8.FromIntArray (const Arr:array of UInt8):UInt8;
  var i : Int32;
  begin
   Result := 0;
   if Length(Arr)<8 then Exit;
   for i:=0 to 7 do if Arr[i]<>0 then Set_1(Result,i);
  end;

 // ***************************************************************************
 class function Bit8.Get_I(const Val:UInt8; const Index:Int32):UInt8;
  begin
   Result := (Val and (1 shl Index)) shr Index;
  end;

 // ***************************************************************************
 // Example: From=2; Size=4;
 // 7  6  5  4  3  2  1  0
 //       <---------|
 class function Bit8.Get_I(const Val:UInt8; const From,Size:Int32):UInt8;
  var b : UInt8;
  begin
   b := (Val shl (8-From-Size));
   b := b shr (8-Size);
   Result := b;
  end;

 // ***************************************************************************
 class function Bit8.Get_B(const Val:UInt8; const Index:Int32):Boolean;
  begin
   Result := (Val and (1 shl Index))<>0;
  end;

 // ***************************************************************************
 class function Bit8.Count_0(const Val:UInt8):Int32;
  begin
   Result := 8 - Table_BitCount[Val];
  end;

 // ***************************************************************************
 class function Bit8.Count_1(const Val:UInt8):Int32;
  begin
   Result := Table_BitCount[Val];
  end;

 // ***************************************************************************
 class function Bit8.First_0(const Val:UInt8):Int32;
  begin
   Result := Table_BitFirst0[Val];
  end;

 // ***************************************************************************
 class function Bit8.Last_0(const Val:UInt8):Int32;
  begin
   Result := Table_BitLast0[Val];
  end;

 // ***************************************************************************
 class function Bit8.First_1(const Val:UInt8):Int32;
  begin
   Result := Table_BitFirst1[Val];
  end;

 // ***************************************************************************
 class function Bit8.Last_1(const Val:UInt8):Int32;
  begin
   Result := Table_BitLast1[Val];
  end;

 // ***************************************************************************
 class procedure Bit8.Set_I(const Bit:UInt8; var Val:UInt8; const Index:Int32);
  begin
   if Bit=0 then Set_0(Val,Index)
            else Set_1(Val,Index);
  end;

 // ***************************************************************************
 // Example: From=2; Size=4;
 // 7  6  5  4  3  2  1  0
 //       <---------|
 class procedure Bit8.Set_I(const Bit:UInt8; var Val:UInt8; const From,Size:Int32);
  begin
   // clear position
   Val := Val and ((Mask[Size] shl From) xor $FF);
   // write bits
   Val := Val or (Bit shl From);
  end;

 // ***************************************************************************
 class procedure Bit8.Set_0(var Val:UInt8; const Index:Int32);
  begin
   Val := Val and ((1 shl Index) xor $FF);
  end;

 // ***************************************************************************
 class procedure Bit8.Set_1(var Val:UInt8; const Index:Int32);
  begin
   Val := Val or (1 shl Index);
  end;

 // ***************************************************************************
 class procedure Bit8.Tog(var Val:UInt8; const Index:Int32);
  begin
   Val := Val xor (1 shl Index);
  end;

 // ***************************************************************************
 class procedure Bit8.Swap(var A,B:UInt8);
  begin
   A := A xor B;
   B := A xor B;
   A := A xor B;
  end;

 // ***************************************************************************
 class procedure Bit8.Reverse(var Val:UInt8);
  begin
   Val := Table_Reverse[Val];
  end;

 // ************************************************************************* //
 //  Bit16                                                                    //
 // ************************************************************************* //

 // ***************************************************************************
 class function Bit16.ToStrBin(const Val:UInt16):AnsiString;
  var p : ^Bit8.AByte2;
  begin
   p := @Val;
   Result := Bit8.Table_BinStr[p[1]] + Bit8.Table_BinStr[p[0]];
  end;

 // ***************************************************************************
 class function Bit16.ToStrHex(const Val:UInt16):AnsiString;
  var p : ^Bit8.AByte2;
  begin
   p := @Val;
   Result := Bit8.Table_HexStr[p[1]] + Bit8.Table_HexStr[p[0]];
  end;

 // ***************************************************************************
 class function Bit16.FromStrBin(const Val:AnsiString):UInt16;
  var i,j,k,n : Int32;
  begin
   n := Length(Val);
   if (n=0) or (n>16) then Exit(0);
   //
   j := 0;
   Result := 0;
   for i:=n downto 1 do
    begin
     if Val[i]='1' then Result := Result + 1 shl j else if Val[i]<>'0' then Exit(0);
     Inc(j);
    end;
  end;

 // ***************************************************************************
 class function Bit16.FromStrHex(const Val:AnsiString):UInt16;
  var i,j,n : Int32;
  begin
   n := Length(Val);
   if (n=0) or (n>4) then Exit(0);
   j := 1;
   Result := 0;
   for i:=n downto 1 do
    begin
     Result := Result + j * HexVal[Val[i]];
     j := j * 16;
    end;
  end;

 // ***************************************************************************
 class function Bit16.ToBoolArray(const Val:UInt16):TArray<Boolean>;
  var i : Int32;
  begin
   SetLength(Result,16);
   for i:=0 to High(Result) do Result[i] := Get_B(Val,i);
  end;

 // ***************************************************************************
 class function Bit16.ToIntArray(const Val:UInt16):TArray<Uint8>;
  var i : Int32;
  begin
   SetLength(Result,16);
   for i:=0 to High(Result) do Result[i] := Get_I(Val,i);
  end;

 // ***************************************************************************
 class function Bit16.FromBoolArray(const Arr:array of Boolean):UInt16;
  var i : Int32;
  begin
   Result := 0;
   if Length(Arr)<16 then Exit;
   for i:=0 to 15 do if Arr[i] then Set_1(Result,i);
  end;

 // ***************************************************************************
 class function Bit16.FromIntArray (const Arr:array of UInt8):UInt16;
  var i : Int32;
  begin
   Result := 0;
   if Length(Arr)<16 then Exit;
   for i:=0 to 15 do if Arr[i]<>0 then Set_1(Result,i);
  end;

 // ***************************************************************************
 class function Bit16.Get_I(const Val:UInt16; const Index:Int32):UInt16;
  begin
   Result := (Val and (1 shl Index)) shr Index;
  end;

 // ***************************************************************************
 class function Bit16.Get_I(const Val:UInt16; const From,Size:Int32):UInt16;
  var b : UInt16;
  begin
   b := (Val shl (16-From-Size));
   b := b shr (16-Size);
   Result := b;
  end;

 // ***************************************************************************
 class function Bit16.Get_B(const Val:UInt16; const Index:Int32):Boolean;
  begin
   Result := (Val and (1 shl Index))<>0;
  end;

 // ***************************************************************************
 class function Bit16.Count_0(const Val:UInt16):Int32;
  var p : ^Bit8.AByte2;
  begin
   p := @Val;
   Result := 16 - Bit8.Table_BitCount[p[0]] - Bit8.Table_BitCount[p[1]];
  end;

 // ***************************************************************************
 class function Bit16.Count_1(const Val:UInt16):Int32;
  var p : ^Bit8.AByte2;
  begin
   p := @Val;
   Result := Bit8.Table_BitCount[p[0]] + Bit8.Table_BitCount[p[1]];
  end;

 // ***************************************************************************
 class function Bit16.First_0(const Val:UInt16):Int32;
  var p : ^Bit8.AByte2;
  begin
   p := @Val;
   Result := -1;
   if p[0]<>255 then Result := Bit8.Table_BitFirst0[p[0]] else
   if p[1]<>255 then Result := Bit8.Table_BitFirst0[p[1]] + 8;
  end;

 // ***************************************************************************
 class function Bit16.Last_0(const Val:UInt16):Int32;
  var p : ^Bit8.AByte2;
  begin
   p := @Val;
   Result := -1;
   if p[1]<>255 then Result := Bit8.Table_BitLast0[p[1]] + 8 else
   if p[0]<>255 then Result := Bit8.Table_BitLast0[p[0]];
  end;

 // ***************************************************************************
 class function Bit16.First_1(const Val:UInt16):Int32;
  var p : ^Bit8.AByte2;
  begin
   p := @Val;
   Result := -1;
   if p[0]<>0 then Result := Bit8.Table_BitFirst1[p[0]] else
   if p[1]<>0 then Result := Bit8.Table_BitFirst1[p[1]] + 8;
  end;

 // ***************************************************************************
 class function Bit16.Last_1(const Val:UInt16):Int32;
  var p : ^Bit8.AByte2;
  begin
   p := @Val;
   Result := -1;
   if p[1]<>0 then Result := Bit8.Table_BitLast1[p[1]] + 8 else
   if p[0]<>0 then Result := Bit8.Table_BitLast1[p[0]];
  end;

 // ***************************************************************************
 class procedure Bit16.Set_I(const Bit:UInt16; var Val:UInt16; const Index:Int32);
  begin
   if Bit=0 then Set_0(Val,Index)
            else Set_1(Val,Index);
  end;

 // ***************************************************************************
 class procedure Bit16.Set_I(const Bit:UInt16; var Val:UInt16; const From,Size:Int32);
  begin
   // clear position
   Val := Val and ((Mask[Size] shl From) xor $FFFF);
   // write bits
   Val := Val or (Bit shl From);
  end;

 // ***************************************************************************
 class procedure Bit16.Set_B(const Bit:Boolean; var Val:UInt16; const Index:Int32);
  begin
   if Bit then Set_1(Val,Index)
          else Set_0(Val,Index);
  end;

 // ***************************************************************************
 class procedure Bit16.Set_0(var Val:UInt16; const Index:Int32);
  begin
   Val := Val and ((1 shl Index) xor $FFFF);
  end;

 // ***************************************************************************
 class procedure Bit16.Set_1(var Val:UInt16; const Index:Int32);
  begin
   Val := Val or (1 shl Index);
  end;

 // ***************************************************************************
 class procedure Bit16.Tog(var Val:UInt16; const Index:Int32);
  begin
   Val := Val xor (1 shl Index);
  end;

 // ***************************************************************************
 class procedure Bit16.Swap(var A,B:UInt16);
  begin
   A := A xor B;
   B := A xor B;
   A := A xor B;
  end;

 // ***************************************************************************
 class procedure Bit16.Reverse(var Val:UInt16);
  var p : ^Bit8.AByte2;
  begin
   p    := @Val;
   p[0] := p[0] xor p[1];
   p[1] := p[0] xor p[1];
   p[0] := p[0] xor p[1];
   p[0] := Bit8.Table_Reverse[p[0]];
   p[1] := Bit8.Table_Reverse[p[1]];
  end;

 // ************************************************************************* //
 //  Bit32                                                                    //
 // ************************************************************************* //

 // ***************************************************************************
 class function Bit32.ToStrBin(const Val:UInt32):AnsiString;
  var p : ^Bit8.AByte4;
  begin
   p := @Val;
   Result := Bit8.Table_BinStr[p[3]] + Bit8.Table_BinStr[p[2]]+
             Bit8.Table_BinStr[p[1]] + Bit8.Table_BinStr[p[0]];
  end;

 // ***************************************************************************
 class function Bit32.ToStrHex(const Val:UInt32):AnsiString;
  var p : ^Bit8.AByte4;
  begin
   p := @Val;
   Result := Bit8.Table_HexStr[p[3]] + Bit8.Table_HexStr[p[2]] +
             Bit8.Table_HexStr[p[1]] + Bit8.Table_HexStr[p[0]];
  end;

 // ***************************************************************************
 class function Bit32.FromStrBin(const Val:AnsiString):UInt32;
  var i,j,k,n : Int32;
  begin
   n := Length(Val);
   if (n=0) or (n>32) then Exit(0);
   //
   j := 0;
   Result := 0;
   for i:=n downto 1 do
    begin
     if Val[i]='1' then Result := Result + 1 shl j else if Val[i]<>'0' then Exit(0);
     Inc(j);
    end;
  end;

 // ***************************************************************************
 class function Bit32.FromStrHex(const Val:AnsiString):UInt32;
  var i,j,n : Int32;
  begin
   n := Length(Val);
   if (n=0) or (n>8) then Exit(0);
   j := 1;
   Result := 0;
   for i:=n downto 1 do
    begin
     Result := Result + j * HexVal[Val[i]];
     j := j * 16;
    end;
  end;

 // ***************************************************************************
 class function Bit32.ToBoolArray(const Val:UInt32):TArray<Boolean>;
  var i : Int32;
  begin
   SetLength(Result,32);
   for i:=0 to High(Result) do Result[i] := Get_B(Val,i);
  end;

 // ***************************************************************************
 class function Bit32.ToIntArray(const Val:UInt32):TArray<Uint8>;
  var i : Int32;
  begin
   SetLength(Result,32);
   for i:=0 to High(Result) do Result[i] := Get_I(Val,i);
  end;

 // ***************************************************************************
 class function Bit32.FromBoolArray(const Arr:array of Boolean):UInt32;
  var i : Int32;
  begin
   Result := 0;
   if Length(Arr)<32 then Exit;
   for i:=0 to 31 do if Arr[i] then Set_1(Result,i);
  end;

 // ***************************************************************************
 class function Bit32.FromIntArray (const Arr:array of UInt8):UInt32;
  var i : Int32;
  begin
   Result := 0;
   if Length(Arr)<32 then Exit;
   for i:=0 to 31 do if Arr[i]<>0 then Set_1(Result,i);
  end;

 // ***************************************************************************
 class function Bit32.Get_I(const Val:UInt32; const Index:Int32):UInt32;
  begin
   Result := (Val and (1 shl Index)) shr Index;
  end;

 // ***************************************************************************
 class function Bit32.Get_I(const Val:UInt32; const From,Size:Int32):UInt32;
  var b : UInt32;
  begin
   b := (Val shl (32-From-Size));
   b := b shr (32-Size);
   Result := b;
  end;

 // ***************************************************************************
 class function Bit32.Get_B(const Val:UInt32; const Index:Int32):Boolean;
  begin
   Result := (Val and (1 shl Index))<>0;
  end;

 // ***************************************************************************
 class function Bit32.Count_0(const Val:UInt32):Int32;
  var p : ^Bit8.AByte4;
  begin
   p := @Val;
   Result := 32 - Bit8.Table_BitCount[p[0]] - Bit8.Table_BitCount[p[1]]
                - Bit8.Table_BitCount[p[2]] - Bit8.Table_BitCount[p[3]];
  end;

 // ***************************************************************************
 class function Bit32.Count_1(const Val:UInt32):Int32;
  var p : ^Bit8.AByte4;
  begin
   p := @Val;
   Result := Bit8.Table_BitCount[p[0]] + Bit8.Table_BitCount[p[1]]
           + Bit8.Table_BitCount[p[2]] + Bit8.Table_BitCount[p[3]];
  end;

 // ***************************************************************************
 class function Bit32.First_0(const Val:UInt32):Int32;
  var p : ^Bit8.AByte4;
  begin
   p := @Val;
   Result := -1;
   if p[0]<>255 then Result := Bit8.Table_BitFirst0[p[0]] else
   if p[1]<>255 then Result := Bit8.Table_BitFirst0[p[1]] + 8 else
   if p[2]<>255 then Result := Bit8.Table_BitFirst0[p[2]] + 16 else
   if p[3]<>255 then Result := Bit8.Table_BitFirst0[p[3]] + 24;
  end;

 // ***************************************************************************
 class function Bit32.Last_0(const Val:UInt32):Int32;
  var p : ^Bit8.AByte4;
  begin
   p := @Val;
   Result := -1;
   if p[3]<>255 then Result := Bit8.Table_BitLast0[p[3]] + 24 else
   if p[2]<>255 then Result := Bit8.Table_BitLast0[p[2]] + 16 else
   if p[1]<>255 then Result := Bit8.Table_BitLast0[p[1]] + 8 else
   if p[0]<>255 then Result := Bit8.Table_BitLast0[p[0]];
  end;

 // ***************************************************************************
 class function Bit32.First_1(const Val:UInt32):Int32;
  var p : ^Bit8.AByte4;
  begin
   p := @Val;
   Result := -1;
   if p[0]<>0 then Result := Bit8.Table_BitFirst1[p[0]] else
   if p[1]<>0 then Result := Bit8.Table_BitFirst1[p[1]] + 8 else
   if p[2]<>0 then Result := Bit8.Table_BitFirst1[p[2]] + 16 else
   if p[3]<>0 then Result := Bit8.Table_BitFirst1[p[3]] + 24;
  end;

 // ***************************************************************************
 class function Bit32.Last_1(const Val:UInt32):Int32;
  var p : ^Bit8.AByte4;
  begin
   p := @Val;
   Result := -1;
   if p[3]<>0 then Result := Bit8.Table_BitLast1[p[3]] + 24 else
   if p[2]<>0 then Result := Bit8.Table_BitLast1[p[2]] + 16 else
   if p[1]<>0 then Result := Bit8.Table_BitLast1[p[1]] + 8 else
   if p[0]<>0 then Result := Bit8.Table_BitLast1[p[0]];
  end;

 // ***************************************************************************
 class procedure Bit32.Set_I(const Bit:UInt32; var Val:UInt32; const Index:Int32);
  begin
   if Bit=0 then Set_0(Val,Index)
            else Set_1(Val,Index);
  end;

 // ***************************************************************************
 class procedure Bit32.Set_I(const Bit:UInt32; var Val:UInt32; const From,Size:Int32);
  begin
   // clear position
   Val := Val and ((Mask[Size] shl From) xor $FFFFFFFF);
   // write bits
   Val := Val or (Bit shl From);
  end;

 // ***************************************************************************
 class procedure Bit32.Set_0(var Val:UInt32; const Index:Int32);
  begin
   Val := Val and ((1 shl Index) xor $FFFFFFFF);
  end;

 // ***************************************************************************
 class procedure Bit32.Set_1(var Val:UInt32; const Index:Int32);
  begin
   Val := Val or (1 shl Index);
  end;

 // ***************************************************************************
 class procedure Bit32.Tog(var Val:UInt32; const Index:Int32);
  begin
   Val := Val xor (1 shl Index);
  end;

 // ***************************************************************************
 class procedure Bit32.Swap(var A,B:UInt32);
  begin
   A := A xor B;
   B := A xor B;
   A := A xor B;
  end;

 // ***************************************************************************
 class procedure Bit32.Reverse(var Val:UInt32);
  var p : ^Bit8.AByte4;
  begin
   p := @Val;
   // 0 - 3
   p[0] := p[0] xor p[3];
   p[3] := p[0] xor p[3];
   p[0] := p[0] xor p[3];
   p[0] := Bit8.Table_Reverse[p[0]];
   p[3] := Bit8.Table_Reverse[p[3]];
   // 1 - 2
   p[2] := p[2] xor p[1];
   p[1] := p[2] xor p[1];
   p[2] := p[2] xor p[1];
   p[2] := Bit8.Table_Reverse[p[2]];
   p[1] := Bit8.Table_Reverse[p[1]];
  end;

end.
