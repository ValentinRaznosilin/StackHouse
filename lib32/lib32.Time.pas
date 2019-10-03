{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : QueryPerformanceCounter, StopWatch & TimeSpan                    *}
{* Change  : 21.02.2016 (594 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2016 Raznosilin V.V.                                    *}
{******************************************************************************}

 unit lib32.Time;

 interface

 uses

  // system
  System.SysUtils,
  Winapi.Windows;

 type

  // ************************************************************************ //
  // http://msdn.microsoft.com/en-us/library/ms644904%28v=VS.85%29.aspx
  TQueryPerformanceCounter = record

   IsReady    : Boolean; // признак наличия быстрого таймера
   CountBySec : Int64;   // частота быстрого таймера (отсчетов/секунду)

   function Init:Boolean;
   // get count & real units
   function Count:Int64; inline;
   function MicroSec:Double; inline;
   function MilliSec:Double; inline;
   function Sec:Double; inline;
   // convert saved count to real units
   function CountToMicroSec(const Count:Int64):Double; inline;
   function CountToMilliSec(const Count:Int64):Double; inline;
   function CountToSec(const Count:Int64):Double; inline;

  end;

  // ************************************************************************ //
  // System.Diagnostics
  // https://msdn.microsoft.com/en-us/library/system.diagnostics.stopwatch%28v=vs.110%29.aspx

  TStopWatchState =
   (stwInvalid,  // 0 - начало интервала больше конца интервала
    stwReleased, // 1 - не запущен
    stwStarted,  // 2 - запущен (но еще не остановлен)
    stwStoped);  // 3 - остановлен после запуска

  TStopWatchRelation =
   (stwEqual,          // 0 - полностью совпадают
    stwSeparate,       // 1 - не пересекаются
    stwLinked,         // 2 - идут непосредственно друг за другом
    stwIntersect,      // 3 - пересекаются
    stwInclude_full,   // 4 - один полностью включает другой
    stwInclude_left,   // 5 - один полностью включает другой (совпадая в начале)
    stwInclude_right); // 6 - один полностью включает другой (совпадая в конце)

  PStopWatch = ^TStopWatch;

  TStopWatch = record

   StartCount : Int64; // begin interval (value 0 is considered as unassigned)
   StopCount  : Int64; // end interval (value 0 is considered as unassigned)
   // action
   procedure Reset; inline;
   procedure Start; inline;
   function  Stop:Int64; inline;
   function  StopAndStart(var Next:TStopWatch):Int64; inline;
   // multiple start & stop
   class procedure StartAll(const SW:TArray<PStopWatch>); static;
   class procedure StopAll(const SW:TArray<PStopWatch>); static;
   // interval length & stopwatch state
   function  Elapsed_Count:Int64; inline;
   function  Elapsed_MicroSec(const Ratio:Double=1.0):Double; inline;
   function  Elapsed_MilliSec(const Ratio:Double=1.0):Double; inline;
   function  Elapsed_Sec(const Ratio:Double=1.0):Double; inline;
   function  State:TStopWatchState; inline;
   // time interval relation & order by position on timeline
   class function  Relation(const SW1,SW2:TStopWatch):TStopWatchRelation; static;
   class procedure SetOrder(var Left,Right:TStopWatch); static;

  end;

  // ************************************************************************ //
  // System.TimeSpan
  // https://msdn.microsoft.com/en-us/library/system.timespan%28v=vs.85%29.aspx

  TTimeSpan = record

   private

    function GetDays:Double;
    function GetHours:Double;
    function GetMilliSeconds:Double;
    function GetMinutes:Double;
    function GetSeconds:Double;

   public const

    MaxValue =  9223372036854775000;
    MinValue = -9223372036854775000;

    MicroSecPerMilliSec = 1000;
    MicroSecPerSecond   = 1000 * Int64(MicroSecPerMilliSec);
    MicroSecPerMinute   = 60 * Int64(MicroSecPerSecond);
    MicroSecPerHour     = 60 * Int64(MicroSecPerMinute);
    MicroSecPerDay      = 24 * MicroSecPerHour;

   public

    MicroSec : Int64; // time interval, microseconds (1E-6 or 0.000001 sec)

    function  Init(const Counts:Int64):Boolean; overload;
    function  Init(const McSec:Double):Boolean; overload;
    function  Init(const MlSec,McSec:Double):Boolean; overload;
    function  Init(const Sec,MlSec,McSec:Double):Boolean; overload;
    function  Init(const Min,Sec,MlSec,McSec:Double):Boolean; overload;
    function  Init(const Hour,Min,Sec,MlSec,McSec:Double):Boolean; overload;
    function  Init(const Day,Hour,Min,Sec,MlSec,McSec:Double):Boolean; overload;
    procedure Separate(out Day,Hour,Min,Sec,MlSec,McSec:Int64);
    function  ToString:string;
    function  FromString(const S:String):Boolean;

    class operator Add(const Left,Right:TTimeSpan):TTimeSpan;
    class operator Add(const Left:TTimeSpan; Right:TDateTime):TDateTime;
    class operator Add(const Left:TDateTime; Right:TTimeSpan):TDateTime;
    class operator Subtract(const Left,Right:TTimeSpan):TTimeSpan;
    class operator Subtract(const Left:TDateTime; Right:TTimeSpan):TDateTime;
    class operator Equal(const Left,Right:TTimeSpan):Boolean;
    class operator NotEqual(const Left,Right:TTimeSpan):Boolean;
    class operator GreaterThan(const Left,Right:TTimeSpan):Boolean;
    class operator GreaterThanOrEqual(const Left,Right:TTimeSpan):Boolean;
    class operator LessThan(const Left,Right:TTimeSpan):Boolean;
    class operator LessThanOrEqual(const Left,Right:TTimeSpan):Boolean;
    class operator Negative(const Value:TTimeSpan):TTimeSpan;
    class operator Positive(const Value:TTimeSpan):TTimeSpan;
    class operator Implicit(const Value:TTimeSpan):string;
    class operator Explicit(const Value:TTimeSpan):string;

    property MilliSec:Double read GetMilliSeconds;
    property Seconds:Double  read GetSeconds;
    property Minutes:Double  read GetMinutes;
    property Hours:Double    read GetHours;
    property Days:Double     read GetDays;

  end;

  //
  procedure Initialize;
  procedure Finalize;
  //
  function _QPC_(var lpPerformanceCount:Int64):LongBool; stdcall; {$EXTERNALSYM _QPC_}
  function _QPF_(var lpFrequency       :Int64):LongBool; stdcall; {$EXTERNALSYM _QPF_}

  function CountsToDatetime(const Counts:Int64):TDateTime;

 var

  QPC         : TQueryPerformanceCounter;
  AppWatch    : TStopWatch; // время работы программы
  AppDateTime : TDateTime;  // дата и время старта программы в формате TDateTime

 implementation

 // unit initialization *******************************************************
 procedure Initialize;
  begin
   QPC.Init;
   AppWatch.Start;
   AppDateTime := Now;
  end;

 // unit finalization *********************************************************
 procedure Finalize;
  begin
   //
  end;

 // короткое имя для QueryPerformanceCounter **********************************
 function _QPC_; external 'kernel32.dll' name 'QueryPerformanceCounter';

 // короткое имя для QueryPerformanceFrequency ********************************
 function _QPF_; external 'kernel32.dll' name 'QueryPerformanceFrequency';

 // ***************************************************************************
 function CountsToDatetime(const Counts:Int64):TDateTime;
  begin
   Result :=
    TimeStampToDateTime
     (
      MSecsToTimeStamp
       (
        TimeStampToMSecs(DateTimeToTimeStamp(AppDateTime))+
        QPC.CountToMilliSec(Counts - AppWatch.StartCount)
       )
     );
  end;

 // ************************************************************************* //
 //  TQueryPerformanceCounter                                                 //
 // ************************************************************************* //

 // ***************************************************************************
 function TQueryPerformanceCounter.Init:Boolean;
  begin
   IsReady := _QPF_(CountBySec);
   Result  := IsReady;
  end;

 // ***************************************************************************
 function TQueryPerformanceCounter.Count:Int64;
  begin
   _QPC_(Result);
  end;

 // ***************************************************************************
 function TQueryPerformanceCounter.MicroSec:Double;
  var I64 : Int64;
  begin
   _QPC_(I64);
   Result := I64 / CountBySec * 1000000;
  end;

 // ***************************************************************************
 function TQueryPerformanceCounter.MilliSec:Double;
  var I64 : Int64;
  begin
   _QPC_(I64);
   Result := I64 / CountBySec * 1000;
  end;

 // ***************************************************************************
 function TQueryPerformanceCounter.Sec:Double;
  var I64 : Int64;
  begin
   _QPC_(I64);
   Result := I64 / CountBySec;
  end;

 // ***************************************************************************
 function TQueryPerformanceCounter.CountToMicroSec(const Count:Int64):Double;
  begin
   Result := Count / CountBySec * 1000000;
  end;

 // ***************************************************************************
 function TQueryPerformanceCounter.CountToMilliSec(const Count:Int64):Double;
  begin
   Result := Count / CountBySec * 1000;
  end;

 // ***************************************************************************
 function TQueryPerformanceCounter.CountToSec(const Count:Int64):Double;
  begin
   Result := Count / CountBySec;
  end;

 // ************************************************************************* //
 //  TStopWatch                                                               //
 // ************************************************************************* //

 // ***************************************************************************
 procedure TStopWatch.Reset;
  begin
   StartCount := 0;
   StopCount  := 0;
  end;

 // ***************************************************************************
 procedure TStopWatch.Start;
  begin
   StartCount := QPC.Count;
   StopCount  := 0;
  end;

 // ***************************************************************************
 function TStopWatch.Stop:Int64;
  begin
   StopCount := QPC.Count;
   Result    := StopCount - StartCount;
  end;

 // ***************************************************************************
 function TStopWatch.StopAndStart(var Next:TStopWatch):Int64;
  begin
   StopCount       := QPC.Count;
   Result          := StopCount - StartCount;
   Next.StartCount := StopCount;
   Next.StopCount  := 0;
  end;

 // ***************************************************************************
 class procedure TStopWatch.StartAll(const SW:TArray<PStopWatch>);
  var i : Int32;
  begin
   if SW=Nil then Exit;
   SW[0].Start;
   for i:=1 to High(SW) do SW[i]^ := SW[0]^;
  end;

 // ***************************************************************************
 class procedure TStopWatch.StopAll(const SW:TArray<PStopWatch>);
  var i : Int32;
  begin
   if SW=Nil then Exit;
   SW[0].Stop;
   for i:=1 to High(SW) do SW[i].StopCount := SW[0].StopCount;
  end;

 // ***************************************************************************
 function TStopWatch.Elapsed_Count:Int64;
  begin
   Result := StopCount - StartCount;
  end;

 // ***************************************************************************
 function TStopWatch.Elapsed_MicroSec(const Ratio:Double):Double;
  begin
   Result := Ratio * QPC.CountToMicroSec(StopCount-StartCount);
  end;

 // ***************************************************************************
 function TStopWatch.Elapsed_MilliSec(const Ratio:Double):Double;
  begin
   Result := Ratio * QPC.CountToMilliSec(StopCount-StartCount);
  end;

 // ***************************************************************************
 function TStopWatch.Elapsed_Sec(const Ratio:Double):Double;
  begin
   Result := Ratio * QPC.CountToSec(StopCount-StartCount);
  end;

 // ***************************************************************************
 function TStopWatch.State:TStopWatchState;
  begin
   if (StartCount=0) and (StopCount=0) then Exit(stwReleased) else
   if (StartCount<>0) and (StopCount=0) then Exit(stwStarted) else
   if (StartCount<>0) and (StopCount<>0) and (StopCount>=StartCount) then Exit(stwStoped)
    else Exit(stwInvalid);
  end;

 // ***************************************************************************
 class function TStopWatch.Relation(const SW1,SW2:TStopWatch):TStopWatchRelation;
  begin
   if (SW1.StartCount=SW2.StartCount) and (SW1.StopCount=SW2.StopCount) then Exit(stwEqual) else
   if (SW1.StartCount=SW2.StopCount) or (SW1.StopCount=SW2.StartCount) then Exit(stwLinked) else
   if SW1.StartCount=SW2.StartCount then Exit(stwInclude_left) else
   if SW1.StopCount=SW2.StopCount then Exit(stwInclude_right) else
   if (SW1.StopCount<SW2.StartCount) or (SW1.StartCount>SW2.StopCount) then Exit(stwSeparate) else
   if ((SW1.StartCount<SW2.StartCount) and (SW2.StopCount<SW1.StopCount)) or
      ((SW1.StartCount>SW2.StartCount) and (SW1.StopCount<SW2.StopCount)) then Exit(stwInclude_full)
    else Exit(stwIntersect);
  end;

 // ***************************************************************************
 class procedure TStopWatch.SetOrder(var Left,Right:TStopWatch);
  var temp : TStopWatch;
      rel  : TStopWatchRelation;
  begin
   // both stopwatch must be stoped
   if (Left.State<>stwStoped) or (Right.State<>stwStoped) then Exit;
   //
   rel := Relation(Left,Right);
   if rel=stwEqual then Exit;
   // need swap ?
   if ((rel=stwInclude_left) and (Left.StopCount>Right.StopCount)) or
      (Left.StartCount>Right.StartCount)
   then
    begin
     temp  := Left;
     Left  := Right;
     Right := temp;
    end;
  end;

 // ************************************************************************* //
 //  TTimeSpan                                                                //
 // ************************************************************************* //

 // ***************************************************************************
 function TTimeSpan.GetDays:Double;
  begin
   Result := MicroSec / MicroSecPerDay;
  end;

 // ***************************************************************************
 function TTimeSpan.GetHours:Double;
  begin
   Result := MicroSec / MicroSecPerHour;
  end;

 // ***************************************************************************
 function TTimeSpan.GetMinutes:Double;
  begin
   Result := MicroSec / MicroSecPerMinute;
  end;

 // ***************************************************************************
 function TTimeSpan.GetSeconds:Double;
  begin
   Result := MicroSec / MicroSecPerSecond;
  end;

 // ***************************************************************************
 function TTimeSpan.GetMilliSeconds:Double;
  begin
   Result := MicroSec / MicroSecPerMilliSec;
  end;

 // ***************************************************************************
 function TTimeSpan.Init(const Counts:Int64):Boolean;
  var NewValue : Int64;
  begin
   NewValue := Trunc(QPC.CountToMicroSec(Counts));
   Result   := (NewValue>=MinValue) and (NewValue<=MaxValue);
   if Result then MicroSec := NewValue;
  end;

 // ***************************************************************************
 function TTimeSpan.Init(const McSec:Double):Boolean;
  var NewValue : Int64;
  begin
   NewValue := Trunc(McSec);
   Result   := (NewValue>=MinValue) and (NewValue<=MaxValue);
   if Result then MicroSec := NewValue;
  end;

 // ***************************************************************************
 function TTimeSpan.Init(const MlSec,McSec:Double):Boolean;
  begin
   Result := Init(MlSec*MicroSecPerMilliSec + McSec);
  end;

 // ***************************************************************************
 function TTimeSpan.Init(const Sec,MlSec,McSec:Double):Boolean;
  begin
   Result := Init(Sec*MicroSecPerSecond + MlSec*MicroSecPerMilliSec + McSec);
  end;

 // ***************************************************************************
 function TTimeSpan.Init(const Min,Sec,MlSec,McSec:Double):Boolean;
  begin
   Result := Init(Min*MicroSecPerMinute + Sec*MicroSecPerSecond + MlSec*MicroSecPerMilliSec + McSec);
  end;

 // ***************************************************************************
 function TTimeSpan.Init(const Hour,Min,Sec,MlSec,McSec:Double):Boolean;
  begin
   Result := Init(Hour*MicroSecPerHour + Min*MicroSecPerMinute + Sec*MicroSecPerSecond + MlSec*MicroSecPerMilliSec + McSec);
  end;

 // ***************************************************************************
 function TTimeSpan.Init(const Day,Hour,Min,Sec,MlSec,McSec:Double):Boolean;
  begin
   Result := Init(Day*MicroSecPerDay + Hour*MicroSecPerHour + Min*MicroSecPerMinute + Sec*MicroSecPerSecond + MlSec*MicroSecPerMilliSec + McSec);
  end;

 // ***************************************************************************
 procedure TTimeSpan.Separate(out Day,Hour,Min,Sec,MlSec,McSec:Int64);
  var t : Int64;
  begin
   t     := Abs(MicroSec);
   Day   := t div MicroSecPerDay;      t := t mod MicroSecPerDay;
   Hour  := t div MicroSecPerHour;     t := t mod MicroSecPerHour;
   Min   := t div MicroSecPerMinute;   t := t mod MicroSecPerMinute;
   Sec   := t div MicroSecPerSecond;   t := t mod MicroSecPerSecond;
   MlSec := t div MicroSecPerMilliSec; t := t mod MicroSecPerMilliSec;
   McSec := t;
  end;

 // ***************************************************************************
 // ddd/hh:mm:ss.zzzzzz
 function TTimeSpan.ToString:string;
  var d,h,m,s,ml,mc : Int64;
  begin
   Separate(d,h,m,s,ml,mc);
   if d<>0
    then Result := Format('%d/%0.2d:%0.2d:%0.2d',[d,h,m,s])
    else Result := Format('%0.2d:%0.2d:%0.2d',[h,m,s]);
   if mc<>0 then Result := Result +Format('.%0.3d%0.3d',[ml,mc]) else
   if ml<>0 then Result := Result +Format('.%0.3d',[ml]);
  end;

 // ***************************************************************************
 function TTimeSpan.FromString(const S:String):Boolean;
  var d,h,m,sc,ml,mc : Int64;
      i : Int32;
      t : string;
  begin
   Result := false;
   if Length(S)<8 then Exit;
   try
    // days
    d := 0;
    i := Pos('/',S);
    if i<>0 then
     begin
      t := Copy(S,1,i-1);
      d := StrToInt(t);
     end;
    // hours
    t := S[i+1] + S[i+2];
    h := StrToInt(t);
    // minutes
    t := S[i+4] + S[i+5];
    m := StrToInt(t);
    // seconds
    t := S[i+7] + S[i+8];
    sc := StrToInt(t);
    // millisec & microsec
    ml := 0;
    mc := 0;
    i  := Pos('.',S);
    if i<>0 then
     if Length(S)>=i+6 then
      begin
       t  := S[i+1] + S[i+2] + S[i+3];
       ml := StrToInt(t);
       t  := S[i+4] + S[i+5] + S[i+6];
       mc := StrToInt(t);
      end else
     if Length(S)>=i+3 then
      begin
       t  := S[i+1] + S[i+2] + S[i+3];
       ml := StrToInt(t);
      end;
    Result := Init(d,h,m,sc,ml,mc);
   except
    //
   end;
  end;

 // ***************************************************************************
 class operator TTimeSpan.Add(const Left,Right:TTimeSpan):TTimeSpan;
  begin
   if not Result.Init(Left.MicroSec + Right.MicroSec) then
    raise EArgumentOutOfRangeException.Create('TTimeSpan out of range');
  end;

 // ***************************************************************************
 class operator TTimeSpan.Add(const Left:TTimeSpan; Right:TDateTime):TDateTime;
  begin
   Result := Right + Left;
  end;

 // ***************************************************************************
 class operator TTimeSpan.Add(const Left:TDateTime; Right:TTimeSpan):TDateTime;
  begin
   Result :=
    TimeStampToDateTime
    (
     MSecsToTimeStamp
      (
       TimeStampToMSecs(DateTimeToTimeStamp(Left)) + Trunc(Right.MilliSec)
      )
    );
  end;

 // ***************************************************************************
 class operator TTimeSpan.Subtract(const Left,Right:TTimeSpan):TTimeSpan;
  begin
   if not Result.Init(Left.MicroSec - Right.MicroSec) then
    raise EArgumentOutOfRangeException.Create('TTimeSpan out of range');
  end;

 // ***************************************************************************
 class operator TTimeSpan.Subtract(const Left:TDateTime; Right:TTimeSpan):TDateTime;
  begin
   Result :=
    TimeStampToDateTime
    (
     MSecsToTimeStamp
      (
       TimeStampToMSecs(DateTimeToTimeStamp(Left)) - Trunc(Right.MilliSec)
      )
    );
  end;

 // ***************************************************************************
 class operator TTimeSpan.Equal(const Left,Right:TTimeSpan):Boolean;
  begin
   Result := Left.MicroSec = Right.MicroSec;
  end;

 // ***************************************************************************
 class operator TTimeSpan.NotEqual(const Left,Right:TTimeSpan):Boolean;
  begin
   Result := Left.MicroSec <> Right.MicroSec;
  end;

 // ***************************************************************************
 class operator TTimeSpan.GreaterThan(const Left,Right:TTimeSpan):Boolean;
  begin
   Result := Left.MicroSec > Right.MicroSec;
  end;

 // ***************************************************************************
 class operator TTimeSpan.GreaterThanOrEqual(const Left,Right:TTimeSpan):Boolean;
  begin
   Result := Left.MicroSec >= Right.MicroSec;
  end;

 // ***************************************************************************
 class operator TTimeSpan.LessThan(const Left,Right:TTimeSpan):Boolean;
  begin
   Result := Left.MicroSec < Right.MicroSec;
  end;

 // ***************************************************************************
 class operator TTimeSpan.LessThanOrEqual(const Left,Right:TTimeSpan):Boolean;
  begin
   Result := Left.MicroSec <= Right.MicroSec;
  end;

 // ***************************************************************************
 class operator TTimeSpan.Negative(const Value:TTimeSpan):TTimeSpan;
  begin
   Result.MicroSec := -Value.MicroSec;
  end;

 // ***************************************************************************
 class operator TTimeSpan.Positive(const Value:TTimeSpan):TTimeSpan;
  begin
   Result.MicroSec := Value.MicroSec;
  end;

 // ***************************************************************************
 class operator TTimeSpan.Implicit(const Value:TTimeSpan):string;
  begin
   Result := Value.ToString;
  end;

 // ***************************************************************************
 class operator TTimeSpan.Explicit(const Value:TTimeSpan):string;
  begin
   Result := Value.ToString;
  end;

end.
