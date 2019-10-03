{******************************************************************************}
{* Project : "StackHouse" virtual stack-machine                               *}
{* Unit    : Commmon stuff                                                    *}
{* Change  : 03.10.2019 (267  lines)                                          *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2019 DelphiRunner                                            *}
{******************************************************************************}

unit SH.Utils;

 interface

 uses

  // system
  WinAPI.Windows, System.StrUtils,
  // project
  SH.Codes, SH.Types;

 function CharDec(const Ch:Char):Boolean; inline;
 function CharHex(const Ch:Char):Boolean; inline;
 function HexToByte(const HiChar,LoChar:Char):UInt8; inline;
 function ReplaceEscapeChars(const S:string):string;
 function PrepareString(const RawStr:string):AnsiString;
 function HexComplementTo16(const S:string):string;
 function BinComplementTo16(const S:string):string;
 function TryHexToInt64(const S:string; out N:Int64):Boolean;
 function BinaryStreamToData(const S:string):TStorage;
 function StrInList(const S:string; const L:array of string):Boolean;
 function Alloc_String(const S:AnsiString; out D:TData):Boolean; overload;
 function Alloc_Stream(const S:string; out D:TData):Boolean; overload;
 function Alloc_String(const S:Int64; out D:TData):Boolean; overload;
 function Alloc_Stream(const S:Int64; out D:TData):Boolean; overload;

 function ReadConsoleChar:AnsiChar;

 implementation

 // ***************************************************************************
 function CharHex(const Ch:Char):Boolean;
  begin
   Result := Ch in HS;
  end;

 // ***************************************************************************
 function CharDec(const Ch:Char):Boolean;
  begin
   Result := Ch in DS;
  end;

 // ***************************************************************************
 // UInt8 = Lo + 16 * Hi; Lo, Hi in [0..15]
 function HexToByte(const HiChar,LoChar:Char):UInt8;
  begin
   Result := 0;
   if CharHex(LoChar) then Result := HV[LoChar];
   if CharHex(HiChar) then Result := Result + 16 * HV[HiChar];
  end;

 // ***************************************************************************
 // escape variants : \\ \" \n \ZA - ZA in ['0'..'9','A'..'F']; A - low order byte; Z - high order byte;
 function ReplaceEscapeChars(const S:string):string;
  var i,L : Int32;
  begin
   Result := '';
   if S='' then Exit;
   i := 1;
   L := Length(S);
   while i<=L do
    if S[i]=Escap then
     begin
      Inc(i);
      if i>L then break;
      if CharHex(S[i]) and (i+1<=L) and CharHex(S[i+1]) then
       begin
        Result := Result + Chr(HexToByte(S[i],S[i+1]));
        Inc(i,2);
        continue;
       end else
      if S[i]=NewLine
       then Result := Result + #13#10
       else Result := Result + S[i];
      Inc(i);
     end
    else
     begin
      Result := Result + S[i];
      Inc(i);
     end
  end;

 // ***************************************************************************
 // convert string from compile-time representation to runtime data
 function PrepareString(const RawStr:string):AnsiString;
  begin
   Result := ReplaceEscapeChars(RawStr);        // replace escape sequences
   Result := MidStr(Result,2,Length(Result)-2); // cut quotes
  end;

 // ***************************************************************************
 // prepare string to use with "TryHexToInt64"
 // S must be like "0xZ..A";
 // "0X" - optional; if present then cutted from result
 // all hex digits Z..A after position 15 is ignored
 // Z..A in ['0'..'9','A'..'F']
 // A - low order digits;
 // Z - high order digits
 function HexComplementTo16(const S:string):string;
  var i : Int32;
  begin
   if Length(S)<3 then Exit('0000000000000000');
   // try to cut prefix "0X"
   if (S[1]=_INT) and (S[2]=_HEX)
    then Result := RightStr(S,Length(S)-2)
    else Result := S;
   //
   if Length(Result)>16 then Result := RightStr(S,16) else
    begin
     i := Length(Result) mod 16;
     if i<>0 then Result := System.StringOfChar('0',16-i) + Result;
    end;
  end;

 // ***************************************************************************
 function BinComplementTo16(const S:string):string;
  var i : Int32;
  begin
   // try to cut prefix "0B"
   if (Length(S)>1) and (S[1]=_INT) and (S[2]=_BIN)
    then Result := RightStr(S,Length(S)-2)
    else Result := S;
   // complement to 16
   i := Length(Result) mod 16;
   if i<>0 then Result := System.StringOfChar('0',16-i) + Result;
  end;

 // ***************************************************************************
 function TryHexToInt64(const S:string; out N:Int64):Boolean;
  var
   i,k : Int32;
   t   : TData;
   tmp : string;
  begin
   tmp := HexComplementTo16(S);
   N   := 0;
   k   := 16;
   for i:=0 to 7 do
    if CharHex(tmp[k-1]) and CharHex(tmp[k]) then
     begin
      t.u1[i] := HexToByte(tmp[k-1],tmp[k]);
      Dec(k,2);
     end
    else Exit(false);
   // final
   N := t.i8;
   Exit(true);
  end;

 // ***************************************************************************
 // S must not include "0B" prefix; Length(S) must be a multiple of 16
 function BinaryStreamToData(const S:string):TStorage;
  var
   i,j,k : Int32;
  begin
   if (S='') or (Length(S) mod 16 <> 0) then Exit(Nil);
   //
   k := Length(S);
   SetLength(Result,Length(S) div 16);
   for i:=0 to High(Result) do
    for j:=0 to 7 do
     if CharHex(S[k-1]) and CharHex(S[k])
      then begin
            Result[i].u1[j] := HexToByte(S[k-1],S[k]);
            Dec(k,2);
           end
      else Exit(Nil);
  end;

 // ***************************************************************************
 function StrInList(const S:string; const L:array of string):Boolean;
  var i : Int32;
  begin
   Result := false;
   for i:=0 to High(L) do if S=L[i] then Exit(true);
  end;

 // ***************************************************************************
 { TODO : handle possible exception from GetMem }
 function Alloc_String(const S:AnsiString; out D:TData):Boolean;
  var
   i   : Integer;
   pch : PAnsiChar;
  begin
   D.Clear();
   if S='' then Exit(false);
   i := Length(S);
   System.GetMem(pch,i+1);
   System.Move(S[1],pch[0],i);
   pch[i]   := #0;
   D.StrLen := i+1;
   D.StrPtr := pch;
   Exit(true);
  end;

 // ***************************************************************************
 { TODO : handle possible exception from GetMem }
 function Alloc_Stream(const S:string; out D:TData):Boolean;
  var a : TStorage;
  begin
   D.Clear();
   a := BinaryStreamToData(BinComplementTo16(S));
   if a<>Nil then
    begin
     D.Size := Length(a) * SizeOf(TData);
     System.GetMem(D.Ptr,D.Size);
     System.Move(a[0],D.Ptr^,D.Size);
     Exit(true);
    end
   else Exit(false);
  end;

 // ***************************************************************************
 { TODO : handle possible exception from GetMem }
 function Alloc_String(const S:Int64; out D:TData):Boolean;
  begin
   D.Clear();
   if S<=0 then Exit(false);
   //
   System.GetMem(D.StrPtr,S);
   System.FillChar(D.StrPtr^,S,0);
   D.StrLen := S;
   Exit(true);
  end;

 // ***************************************************************************
 { TODO : handle possible exception from GetMem }
 function Alloc_Stream(const S:Int64; out D:TData):Boolean;
  begin
   D.Clear();
   if S<=0 then Exit(false);
   //
   System.GetMem(D.Ptr,S);
   System.FillChar(D.Ptr^,S,0);
   D.Size := S;
   Exit(true);
  end;

 // ***************************************************************************
 function ReadConsoleChar:AnsiChar;
  var
   console : THandle;
   conmode : DWORD;
   chrread : DWORD;
   ch      : AnsiChar;
  begin
   console := GetStdHandle(STD_INPUT_HANDLE);
   GetConsoleMode(console,conmode);
   SetConsoleMode(console,conmode and (not ENABLE_LINE_INPUT));
   ReadConsole(console,@ch,1,chrread,Nil);
   SetConsoleMode(console,conmode);
   if Ord(ch)=8  then Write(#8' '#8) else
   if Ord(ch)=13 then WriteLn else Write(ch);
   Result := ch;
  end;

end.
