{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : Ring Buffer (fifo, unilateral, fixed or auto-expanded)           *}
{* Change  : 28.12.2012 (351 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2012 Raznosilin V.V.                                    *}
{******************************************************************************}

 unit lib32.Structures.RingBuffer;

 interface

 uses

  // system
  System.RTLConsts, System.SysUtils,
  // project
  lib32.Structures.BufferedArray;

 type

  // comment this to avoid parameters check
  // + : faster
  // - : may lead to error
  {$DEFINE CheckIndex}

  { TODO : оптимизировать Extract для нескольких элементов }
  { TODO : оптимизировать Insert для нескольких элементов }

  TRingBuffer<T> = class(TBufferedArray<T>)

   protected

    FHead  : Int32;   // "in" position
    FTail  : Int32;   // "out" position
    FFixed : Boolean; // false - auto-expanded buffer (use additional memory if need !);
                      // true  - fixed size buffer    (overwrite items !);

    function  GetItem(Index:Int32):T; override;
    procedure SetItem(Index:Int32; const Value:T); override;
    procedure SetCapacity(const Value:Int32); override;

   public

    constructor Create(const BufferSize:Int32);

    procedure Clear; override;
    // 1 item
    function  Insert(const O:T):Int32; overload;
    function  Extract:T; overload;
    // N items
    function  Insert(const O:array of T):Int32; overload;
    function  Extract(const N:Int32):TArray<T>; overload;

    property FixedSize:Boolean read FFixed write FFixed;

  end;

 implementation

 // ************************************************************************* //
 //  TRingBuffer<T>                                                           //
 // ************************************************************************* //

 // ***************************************************************************
 function TRingBuffer<T>.GetItem(Index:Int32):T;
  begin
   {$IFDEF CheckIndex}
   if not ValidIndex(Index) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   Result := FItems[(FTail+Index) mod FLength];
  end;

 // ***************************************************************************
 procedure TRingBuffer<T>.SetItem(Index:Int32; const Value:T);
  begin
   {$IFDEF CheckIndex}
   if not ValidIndex(Index) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   FItems[(FTail+Index) mod FLength] := Value;
  end;

 // ***************************************************************************
 { TODO : обработка исключения EOutOfMemory }
 procedure TRingBuffer<T>.SetCapacity(const Value:Int32);
  var TailCount,Offset : Integer;
  begin
   if (Value<FCount) or (Value>MaxCapacity) or (Value-FCount>MaxReserve) or (Value=Capacity) then Exit;
   //
   if FCount=0 then
    begin
     SetLength(FItems,Value);
     FLength := Value;
     FHead   := 0;
     FTail   := 0;
     Exit;
    end;
   //
   Offset := Value - FLength;
   //if (FHead<FTail) or ((FHead=FTail) and (FCount>0))
   if FHead<=FTail
    then TailCount := FLength - FTail
    else TailCount := 0;
   //
   if Offset>0 then SetLength(FItems,Value);
   if TailCount>0 then
    begin
     Move(FItems[FTail],FItems[FTail+Offset],TailCount*SizeOf(T));
     if Offset>0 then FillChar(FItems[FTail],Offset*SizeOf(T),0)
                 else FillChar(FItems[FLength+Offset],(-Offset)* SizeOf(T),0);
     Inc(FTail,Offset);
    end
   else if FTail>0 then
    begin
     Move(FItems[FTail],FItems[0],FCount*SizeOf(T));
     FillChar(FItems[FCount],FTail*SizeOf(T),0);
     FHead := FCount;
     FTail := 0;
    end;
   if Offset<0 then SetLength(FItems,Value);
   FLength := Length(FItems);
  end;

 // ***************************************************************************
 constructor TRingBuffer<T>.Create(const BufferSize:Int32);
  begin
   inherited Create;
   if (BufferSize>0) and (BufferSize<=MaxCapacity) then
    begin
     SetLength(FItems,BufferSize);
     FillChar(FItems[0],BufferSize*SizeOf(T),0);
     FLength := BufferSize;
    end;
  end;

 // ***************************************************************************
 procedure TRingBuffer<T>.Clear;
  begin
   inherited Clear;
   FHead := 0;
   FTail := 0;
  end;

 // ***************************************************************************
 function TRingBuffer<T>.Insert(const O:T):Int32;
  begin
   Result := 0;
   if FFixed then
    begin
     FItems[FHead] := O;
     FHead := (FHead + 1) mod FLength;
     if FCount=FLength then FTail := FHead;
     Inc(FCount);
     Result := 1;
    end
   else
    begin
     if (FCount=FLength) and (GrowUp<1) then Exit;
     FItems[FHead] := O;
     FHead := (FHead + 1) mod FLength;
     Inc(FCount);
     Result := 1;
    end;
  end;

 // ***************************************************************************
 function TRingBuffer<T>.Insert(const O:array of T):Int32;
  var i : Int32;
  begin
   Result := 0;
   for i:=0 to High(O) do Inc(Result,Insert(O[i]));
  end;

 // ***************************************************************************
 function TRingBuffer<T>.Extract:T;
  begin
   Result := Default(T);
   if FCount=0 then Exit;
   Result := FItems[FTail];
   FItems[FTail] := Default(T);
   FTail := (FTail + 1) mod FLength;
   Dec(FCount);
  end;

 // ***************************************************************************
 function TRingBuffer<T>.Extract(const N:Int32):TArray<T>;
  var i : Int32;
  begin
   Result := Nil;
   if (N<=0) or (N>FCount) then Exit;
   //
   SetLength(Result,N);
   for i:=0 to N-1 do Result[i] := Extract;
  end;

end.
