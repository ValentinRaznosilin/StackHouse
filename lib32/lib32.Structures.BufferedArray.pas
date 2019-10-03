{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : Buffered Array                                                   *}
{*           (core class for all array-based structures)                      *}
{* Change  : 15.09.2016 (209 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2016 Raznosilin V.V.                                    *}
{******************************************************************************}

 unit lib32.Structures.BufferedArray;

 interface

 uses

  // system
  System.RTLConsts, System.SysUtils;

 type

  // comment this to avoid parameters check
  // + : faster
  // - : may lead to error
  {$DEFINE CheckIndex}

  TBufferedArray<T> = class(TObject)

   protected

    FItems  : TArray<T>; // buffer for items
    FCount  : Int32;     // count of items stored in buffer
    FLength : Int32;     // buffer size : Capacity = Count + Reserve

    function  GetItem(Index:Int32):T; virtual;
    procedure SetItem(Index:Int32; const Value:T); virtual;
    function  GetReserve:Int32;
    procedure SetCount(const Value:Int32);
    procedure SetReserve(const Value:Int32);
    procedure SetCapacity(const Value:Int32); virtual;
    function  GrowUpCount(const CurCount,CurCap:Int32):Int32; virtual;
    function  GrowDownCount(const CurCount,CurCap:Int32):Int32; virtual;

   public

    const MaxCapacity = 128 * 1024 * 1024;
    const MaxReserve  =        128 * 1024;

    constructor Create; overload;
    constructor Create(const BufferSize:Int32); overload;
    destructor  Destroy; override;

    procedure Clear; virtual;
    function  GrowUp(const By:Int32=0):Int32; virtual;
    function  GrowDown(const By:Int32=0):Int32; virtual;
    function  ValidIndex(const Index:Int32):Boolean; virtual;

    property Count:Int32         read FCount     write SetCount;
    property Reserve:Int32       read GetReserve write SetReserve;
    property Capacity:Int32      read FLength    write SetCapacity;
    property Item[Index:Int32]:T read GetItem    write SetItem; default;
    property Items:TArray<T>     read FItems;

  end;

 implementation

 // ************************************************************************* //
 //  TBufferedArray<T>                                                        //
 // ************************************************************************* //

 // ***************************************************************************
 function TBufferedArray<T>.GetItem(Index:Int32):T;
  begin
   {$IFDEF CheckIndex}
   if not ValidIndex(Index) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   Result := FItems[Index];
  end;

 // ***************************************************************************
 procedure TBufferedArray<T>.SetItem(Index:Int32; const Value:T);
  begin
   {$IFDEF CheckIndex}
   if not ValidIndex(Index) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
   {$ENDIF}
   FItems[Index] := Value;
  end;

 // ***************************************************************************
 function TBufferedArray<T>.GetReserve:Int32;
  begin
   Result := Capacity - Count;
  end;

 // ***************************************************************************
 procedure TBufferedArray<T>.SetCount(const Value:Int32);
  begin
   if (Value<0) or (Value>Capacity) then Exit;
   FCount := Value;
  end;

 // ***************************************************************************
 procedure TBufferedArray<T>.SetReserve(const Value:Int32);
  begin
   if (Value<0) or (Value>MaxReserve) then Exit;
   Capacity := Count + Value;
  end;

 // ***************************************************************************
 { TODO : обработка исключения EOutOfMemory }
 procedure TBufferedArray<T>.SetCapacity(const Value:Int32);
  begin
   if (Value<Count) or (Value>MaxCapacity) or (Value-Count>MaxReserve) or (Value=Capacity) then Exit;
   SetLength(FItems,Value);
   FLength := Value;
  end;

 // ***************************************************************************
 // NewCapacity = Capacity + Result;
 function TBufferedArray<T>.GrowUpCount(const CurCount,CurCap:Int32):Int32;
  begin
   if CurCap < 8    then Result := 4   else // 50%
   if CurCap < 64   then Result := 16  else // 25%
   if CurCap < 512  then Result := 64  else // 12.5%
   if CurCap < 4096 then Result := 256      // 6.25%
                    else Result := 1024;    // fixed
  end;

 // ***************************************************************************
 // NewCapacity = Count + Result;
 function TBufferedArray<T>.GrowDownCount(const CurCount,CurCap:Int32):Int32;
  var CurRes : Int32;
  begin
   CurRes := CurCap - CurCount;
   if (CurCount>64*1024) and (CurRes>CurCount div 20) then Result := CurCount div 20 else // 5%
   if (CurCount>16*1024) and (CurRes>CurCount div 10) then Result := CurCount div 10 else // 10%
   if (CurCount>4 *1024) and (CurRes>CurCount div 5 ) then Result := CurCount div 5       // 20%
                                                      else Result := CurCount div 4;      // 25%
  end;

 // ***************************************************************************
 constructor TBufferedArray<T>.Create;
  begin
   inherited Create;
   Clear;
  end;

 // ***************************************************************************
 constructor TBufferedArray<T>.Create(const BufferSize:Int32);
  begin
   inherited Create;
   Capacity := BufferSize;
  end;

 // ***************************************************************************
 destructor TBufferedArray<T>.Destroy;
  begin
   Clear;
   inherited Destroy;
  end;

 // ***************************************************************************
 procedure TBufferedArray<T>.Clear;
  begin
   FItems  := Nil;
   FCount  := 0;
   FLength := 0;
  end;

 // ***************************************************************************
 function TBufferedArray<T>.GrowUp(const By:Int32):Int32;
  var OldCapacity : Int32;
      GrowUpBy    : Int32;
  begin
   Result := 0;
   if By<0 then Exit;
   // save old capacity
   OldCapacity := Capacity;
   // calculate grow up size
   if By<>0
    then GrowUpBy := By
    else GrowUpBy := GrowUpCount(Count,Capacity);
   // try to allocate memory
   Capacity := OldCapacity + GrowUpBy;
   // return size (in items) of actually allocated memory
   Result := Capacity - OldCapacity;
  end;

 // ***************************************************************************
 function TBufferedArray<T>.GrowDown(const By:Int32):Int32;
  var OldCapacity : Int32;
      NewReserve  : Int32;
  begin
   Result := 0;
   if By<0 then Exit;
   // save old capacity
   OldCapacity := Capacity;
   // recalculate reserve size
   if By<>0
    then NewReserve := Reserve - By
    else NewReserve := GrowDownCount(Count,Capacity);
   // grow down by reset of reserve
   Reserve := NewReserve;
   // return size (in items) of actually deallocated memory
   Result := OldCapacity - Capacity;
  end;

 // ***************************************************************************
 function TBufferedArray<T>.ValidIndex(const Index:Int32):Boolean;
  begin
   Result := (Index>=0) and (Index<Count);
  end;

end.
