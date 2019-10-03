{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : Function implementations for base types                          *}
{* Change  : 03.03.2016 (387 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2016 Raznosilin V.V.                                    *}
{******************************************************************************}

 unit lib32.Func.Impl;

 interface

 uses

  // system
  System.SysUtils,
  // library
  lib32.Common, lib32.Func.Core, lib32.Util.Bits;

 // comparator ****************************************************************

 // int
 function CMP_Int8  (const L,R:Int8  ):Int32;
 function CMP_Int16 (const L,R:Int16 ):Int32;
 function CMP_Int32 (const L,R:Int32 ):Int32;
 function CMP_Int64 (const L,R:Int64 ):Int32;
 function CMP_UInt8 (const L,R:UInt8 ):Int32;
 function CMP_UInt16(const L,R:UInt16):Int32;
 function CMP_UInt32(const L,R:UInt32):Int32;
 function CMP_UInt64(const L,R:UInt64):Int32;
 // real
 function CMP_Single  (const L,R:Single  ):Int32;
 function CMP_Double  (const L,R:Double  ):Int32;
 function CMP_Extended(const L,R:Extended):Int32;
 function CMP_Real    (const L,R:Real    ):Int32;
 // other
 function CMP_TObject_ADDR (const L,R:TObject      ):Int32;
 function CMP_TObject_CLASS(const L,R:TObject      ):Int32;
 function CMP_TClass       (const L,R:TClass       ):Int32;
 function CMP_Boolean      (const L,R:Boolean      ):Int32;
 function CMP_Pointer      (const L,R:Pointer      ):Int32;
 function CMP_AnsiString   (const L,R:AnsiString   ):Int32;
 function CMP_UnicodeString(const L,R:UnicodeString):Int32;

 // format *******************************************************************

 // int
 function FMT_Int8 (const Value:Int8 ; const Fmt:AnsiString=''):String;
 function FMT_Int16(const Value:Int16; const Fmt:AnsiString=''):String;
 function FMT_Int32(const Value:Int32; const Fmt:AnsiString=''):String;
 function FMT_Int64(const Value:Int64; const Fmt:AnsiString=''):String;
 // uint
 function FMT_UInt8 (const Value:UInt8 ; const Fmt:AnsiString=''):String;
 function FMT_UInt16(const Value:UInt16; const Fmt:AnsiString=''):String;
 function FMT_UInt32(const Value:UInt32; const Fmt:AnsiString=''):String;
 function FMT_UInt64(const Value:UInt64; const Fmt:AnsiString=''):String;
 // real
 function FMT_Real    (const Value:Real    ; const Fmt:AnsiString=''):String;
 function FMT_Single  (const Value:Single  ; const Fmt:AnsiString=''):String;
 function FMT_Double  (const Value:Double  ; const Fmt:AnsiString=''):String;
 function FMT_Extended(const Value:Extended; const Fmt:AnsiString=''):String;
 // other
 function FMT_AnsiString   (const Value:AnsiString   ; const Fmt:AnsiString=''):String;
 function FMT_UnicodeString(const Value:UnicodeString; const Fmt:AnsiString=''):String;
 function FMT_AnsiChar     (const Value:AnsiChar     ; const Fmt:AnsiString=''):String;
 function FMT_WideChar     (const Value:WideChar     ; const Fmt:AnsiString=''):String;
 function FMT_Boolean      (const Value:Boolean      ; const Fmt:AnsiString=''):String;
 function FMT_TGUID        (const Value:TGUID        ; const Fmt:AnsiString=''):String;

 //
 procedure Initialize;
 procedure Finalize;

 implementation

 // ************************************************************************* //
 //  CMP                                                                      //
 // ************************************************************************* //

 function CMP_Int8(const L,R:Int8):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_Int16(const L,R:Int16):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_Int32(const L,R:Int32):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_Int64(const L,R:Int64):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_UInt8(const L,R:UInt8):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_UInt16(const L,R:UInt16):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_UInt32(const L,R:UInt32):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_UInt64(const L,R:UInt64):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_Single(const L,R:Single):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_Double(const L,R:Double):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_Extended(const L,R:Extended):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_Real(const L,R:Real):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_TObject_ADDR (const L,R:TObject):Int32;
  begin
   if UInt64(L)<UInt64(R) then Result := -1 else
   if UInt64(L)>UInt64(R) then Result := 1  else Exit(0);
  end;

 function CMP_TObject_CLASS(const L,R:TObject):Int32;
  begin
   if UInt64(L.ClassType)<UInt64(R.ClassType) then Result := -1 else
   if UInt64(L.ClassType)>UInt64(R.ClassType) then Result := 1  else Exit(0);
  end;

 function CMP_TClass(const L,R:TClass):Int32;
  begin
   if UInt64(L)<UInt64(R) then Result := -1 else
   if UInt64(L)>UInt64(R) then Result := 1  else Exit(0);
  end;

 function CMP_Boolean(const L,R:Boolean):Int32;
  begin
   if L=R then Exit(0) else
   if L then Result := 1 else Result := -1;
  end;

 function CMP_Pointer(const L,R:Pointer):Int32;
  begin
   if UInt64(L)<UInt64(R) then Result := -1 else
   if UInt64(L)>UInt64(R) then Result := 1  else Exit(0);
  end;

 function CMP_AnsiString(const L,R:AnsiString):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 function CMP_UnicodeString(const L,R:UnicodeString):Int32;
  begin
   if L<R then Result := -1 else
   if L>R then Result := 1  else Exit(0);
  end;

 // ************************************************************************* //
 //  FMT INT                                                                  //
 // ************************************************************************* //

 function FMT_Int8(const Value:Int8; const Fmt:AnsiString=''):String;
  begin
   if Fmt=''    then Exit(IntToStr(Value))      else
   if Fmt='hex' then Exit(Bit8.ToStrHex(Value)) else
   if Fmt='bin' then Exit(Bit8.ToStrBin(Value)) else
    Result := Format(Fmt,[Value]);
  end;

 function FMT_Int16(const Value:Int16; const Fmt:AnsiString=''):String;
  begin
   if Fmt=''    then Exit(IntToStr(Value))       else
   if Fmt='hex' then Exit(Bit16.ToStrHex(Value)) else
   if Fmt='bin' then Exit(Bit16.ToStrBin(Value)) else
    Result := Format(Fmt,[Value]);
  end;

 function FMT_Int32(const Value:Int32; const Fmt:AnsiString=''):String;
  begin
   if Fmt=''    then Exit(IntToStr(Value))       else
   if Fmt='hex' then Exit(Bit32.ToStrHex(Value)) else
   if Fmt='bin' then Exit(Bit32.ToStrBin(Value)) else
    Result := Format(Fmt,[Value]);
  end;

 function FMT_Int64(const Value:Int64; const Fmt:AnsiString=''):String;
  begin
   if Fmt='' then Exit(IntToStr(Value)) else
   //if Fmt='hex' then Exit(Bit64.ToStrHex(Value)) else
   //if Fmt='bin' then Exit(Bit64.ToStrBin(Value)) else
    Result := Format(Fmt,[Value]);
  end;

 // ************************************************************************* //
 //  FMT UINT                                                                 //
 // ************************************************************************* //

 function FMT_UInt8(const Value:UInt8; const Fmt:AnsiString=''):String;
  begin
   if Fmt=''    then Exit(IntToStr(Value))      else
   if Fmt='hex' then Exit(Bit8.ToStrHex(Value)) else
   if Fmt='bin' then Exit(Bit8.ToStrBin(Value)) else
    Result := Format(Fmt,[Value]);
  end;

 function FMT_UInt16(const Value:UInt16; const Fmt:AnsiString=''):String;
  begin
   if Fmt=''    then Exit(IntToStr(Value))       else
   if Fmt='hex' then Exit(Bit16.ToStrHex(Value)) else
   if Fmt='bin' then Exit(Bit16.ToStrBin(Value)) else
    Result := Format(Fmt,[Value]);
  end;

 function FMT_UInt32(const Value:UInt32; const Fmt:AnsiString=''):String;
  begin
   if Fmt=''    then Exit(IntToStr(Value))      else
   if Fmt='hex' then Exit(Bit32.ToStrHex(Value)) else
   if Fmt='bin' then Exit(Bit32.ToStrBin(Value)) else
    Result := Format(Fmt,[Value]);
  end;

 function FMT_UInt64(const Value:UInt64; const Fmt:AnsiString=''):String;
  begin
   if Fmt='' then Exit(IntToStr(Value)) else
   //if Fmt='hex' then Exit(Bit64.ToStrHex(Value)) else
   //if Fmt='bin' then Exit(Bit64.ToStrBin(Value)) else
    Result := Format(Fmt,[Value]);
  end;

 // ************************************************************************* //
 //  FMT REAL                                                                 //
 // ************************************************************************* //

 function FMT_Real(const Value:Real; const Fmt:AnsiString=''):String;
  begin
   if Fmt='' then Result := FloatToStr(Value)
             else Result := Format(Fmt,[Value]);
  end;

 function FMT_Single(const Value:Single; const Fmt:AnsiString=''):String;
  begin
   if Fmt='' then Result := FloatToStr(Value)
             else Result := Format(Fmt,[Value]);
  end;

 function FMT_Double(const Value:Double; const Fmt:AnsiString=''):String;
  begin
   if Fmt='' then Result := FloatToStr(Value)
             else Result := Format(Fmt,[Value]);
  end;

 function FMT_Extended(const Value:Extended; const Fmt:AnsiString=''):String;
  begin
   if Fmt='' then Result := FloatToStr(Value)
             else Result := Format(Fmt,[Value]);
  end;

 // ************************************************************************* //
 //  FMT                                                                      //
 // ************************************************************************* //

 function FMT_AnsiString(const Value:AnsiString; const Fmt:AnsiString=''):String;
  begin
   if Fmt='' then Result := Value
             else Result := Format(Fmt,[Value]);
  end;

 function FMT_UnicodeString(const Value:UnicodeString; const Fmt:AnsiString=''):String;
  begin
   if Fmt='' then Result := Value
             else Result := Format(Fmt,[Value]);
  end;

 function FMT_AnsiChar(const Value:AnsiChar; const Fmt:AnsiString=''):String;
  begin
   Result := Value;
  end;

 function FMT_WideChar(const Value:WideChar; const Fmt:AnsiString=''):String;
  begin
   Result := Value;
  end;

 function FMT_Boolean(const Value:Boolean; const Fmt:AnsiString=''):String;
  begin
   if Fmt='' then if Value then Result := 'true' else Result := 'false'
             else if Value then Result := '1'    else Result := '0'
  end;

 function FMT_TGUID(const Value:TGUID; const Fmt:AnsiString=''):String;
  begin
   SetLength(Result,36);
   StrLFmt(PChar(Result),36,'%.8x-%.4x-%.4x-%.2x%.2x-%.2x%.2x%.2x%.2x%.2x%.2x',
    [Value.D1, Value.D2, Value.D3,
     Value.D4[0], Value.D4[1], Value.D4[2], Value.D4[3],
     Value.D4[4], Value.D4[5], Value.D4[6], Value.D4[7]]);
  end;

 // unit initialization *******************************************************
 procedure Initialize;
  begin
   // init comparators for base types
   func_<Int8         >.Inst.Reg('cmp'      ,@CMP_Int8         );
   func_<Int16        >.Inst.Reg('cmp'      ,@CMP_Int16        );
   func_<Int32        >.Inst.Reg('cmp'      ,@CMP_Int32        );
   func_<Int64        >.Inst.Reg('cmp'      ,@CMP_Int64        );
   func_<UInt8        >.Inst.Reg('cmp'      ,@CMP_UInt8        );
   func_<UInt16       >.Inst.Reg('cmp'      ,@CMP_UInt16       );
   func_<UInt32       >.Inst.Reg('cmp'      ,@CMP_UInt32       );
   func_<UInt64       >.Inst.Reg('cmp'      ,@CMP_UInt64       );
   func_<Single       >.Inst.Reg('cmp'      ,@CMP_Single       );
   func_<Double       >.Inst.Reg('cmp'      ,@CMP_Double       );
   func_<Extended     >.Inst.Reg('cmp'      ,@CMP_Extended     );
   func_<Real         >.Inst.Reg('cmp'      ,@CMP_Real         );
   func_<TObject      >.Inst.Reg('cmp'      ,@CMP_TObject_ADDR );
   func_<TObject      >.Inst.Reg('cmp.class',@CMP_TObject_CLASS);
   func_<TClass       >.Inst.Reg('cmp'      ,@CMP_TClass       );
   func_<Boolean      >.Inst.Reg('cmp'      ,@CMP_Boolean      );
   func_<Pointer      >.Inst.Reg('cmp'      ,@CMP_Pointer      );
   func_<AnsiString   >.Inst.Reg('cmp'      ,@CMP_AnsiString   );
   func_<UnicodeString>.Inst.Reg('cmp'      ,@CMP_UnicodeString);

   // init format for base types
   func_<Int8         >.Inst.Reg('fmt',@FMT_Int8         );
   func_<Int16        >.Inst.Reg('fmt',@FMT_Int16        );
   func_<Int32        >.Inst.Reg('fmt',@FMT_Int32        );
   func_<Int64        >.Inst.Reg('fmt',@FMT_Int64        );
   func_<UInt8        >.Inst.Reg('fmt',@FMT_UInt8        );
   func_<UInt16       >.Inst.Reg('fmt',@FMT_UInt16       );
   func_<UInt32       >.Inst.Reg('fmt',@FMT_UInt32       );
   func_<UInt64       >.Inst.Reg('fmt',@FMT_UInt64       );
   func_<Real         >.Inst.Reg('fmt',@FMT_Real         );
   func_<Single       >.Inst.Reg('fmt',@FMT_Single       );
   func_<Double       >.Inst.Reg('fmt',@FMT_Double       );
   func_<Extended     >.Inst.Reg('fmt',@FMT_Extended     );
   func_<AnsiString   >.Inst.Reg('fmt',@FMT_AnsiString   );
   func_<UnicodeString>.Inst.Reg('fmt',@FMT_UnicodeString);
   func_<AnsiChar     >.Inst.Reg('fmt',@FMT_AnsiChar     );
   func_<WideChar     >.Inst.Reg('fmt',@FMT_WideChar     );
   func_<Boolean      >.Inst.Reg('fmt',@FMT_Boolean      );
   func_<TGUID        >.Inst.Reg('fmt',@FMT_TGUID        );
  end;

 // unit finalization *********************************************************
 procedure Finalize;
  begin
   //
  end;

end.
