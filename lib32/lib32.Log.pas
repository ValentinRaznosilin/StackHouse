{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : Log subsystem                                                    *}
{* Change  : 11.02.2019 (725 lines)                                           *}
{* Comment :                                                                  *}
{* - TMonitor used for synchronization                                        *}
{* - AnsiString used for log strings representation                           *}
{* - Full log data (as CSV lines) transfer to File/Server                     *}
{* - Short log data transfer to Memo/Console                                  *}
{*                                                                            *}
{* If you need advanced logging features, then use:                           *}
{* 1) Log4Delphi https://github.com/kartmatias/log4delphi                     *}
{* 2) LoggerPro  https://github.com/danieleteti/loggerpro                     *}
{* 3) CodeSite   https://raize.com/codesite/                                  *}
{* 4) Synopse    https://synopse.info/files/html/api-1.18/SynLog.html         *}
{*                                                                            *}
{* Copyright (c) 2011-2019 DelphiRunner                                       *}
{******************************************************************************}

 unit lib32.Log;

 interface

 uses

  // system
  System.SysUtils, System.Classes, Winapi.Windows, DateUtils,
  System.Generics.Defaults, System.Generics.Collections,
  // library
  lib32.Common, lib32.Time;

 const

  dt_format = 'yyyy.mm.dd hh:nn:ss:zzz';
  loglinefeed      : AnsiString = #13#10; // \r\n DOS, Windows style
  csvlineseparator : AnsiString = #09;    // horizontal tab

 type

 // ************************************************************************* //
 //  Forward declarations                                                     //
 // ************************************************************************* //

  TLog_Node   = class;
  TLog_Server = class;

 // ************************************************************************* //
 //  Log Node                                                                 //
 // ************************************************************************* //

  TLogSeverity =
   (
    logFatal, // 0
    logError, // 1
    logWarn,  // 2
    logInfo,  // 3
    logTrace, // 4
    logDebug  // 5
   );

  TLogRecord = record

   ID   : Int64;        // log line identifier (unique)
   Prod : AnsiString;   // record producer
   Hold : TLog_Node;    // record holder
   DT   : TDateTime;    // record creation time
   LS   : TLogSeverity; // record type by severity level
   Text : AnsiString;   // log message

   function ToString(const CSV:Boolean=true):AnsiString;

  end;

  TLogEndpointType =
   (toFile,  // 0 - local text file
    toMemo,  // 1 - inproc TStrings
    toCons,  // 2 - local console via file mapping
    toServ); // 3 - inproc/local/remote server via TCP protocol

  TLogEndpoint = record

   procedure Free;
   procedure Clear;
   function  Ready:Boolean;

   case ET:TLogEndpointType of

    toFile : ( F:TFileStream );
    toMemo : ( S:TStrings );
    toCons : ( LogReady,MapAccess,MapFile:THandle; LogSize,Data:Pointer; BufSize:Int32);
    toServ : ( {UNDER CONSTRUCTION !!!} );

  end;

  TLogEndpoints = array [TLogEndpointType] of TLogEndpoint;

  TLog_Node = class(TObject)

   private

    FCount     : Int32;              // actual count of records in FBuffer
    FSaveCount : UInt64;             // records saved via this node
    FBuffer    : TArray<TLogRecord>; // array of log records
    FName      : AnsiString;         // node name
    FOwner     : TLog_Server;        // link to log server (=Nil if not connected)
    FActive    : Boolean;            // false - suppres messages for this node

    function GetIsConnected:Boolean;

   public

    const DefaultBufferGrow = 16;

    constructor Create(const N:AnsiString; const BufSize:Int32; const Srv:TLog_Server=Nil);
    destructor  Destroy; override;

    // modify
    procedure Write(const Msg:AnsiString; const Producer:AnsiString=''; const Severity:TLogSeverity=logInfo; const DT:TDateTime=0);
    function  Extract:TArray<TLogRecord>;

    property Active:Boolean    read FActive write FActive;
    property Name:AnsiString   read FName;
    property Owner:TLog_Server read FOwner write FOwner;
    property SaveCount:UInt64  read FSaveCount;
    property Connected:Boolean read GetIsConnected;

  end;

 // ************************************************************************* //
 //  Log Server                                                               //
 // ************************************************************************* //

  { TODO : реализовать сохранение логов на удаленный сервер }

  TLog_Server = class(TThread)

   private

    FSaveCount : Int64;            // total records saved via this server
    FSaveTime  : Double;           // total time spent for records saving (seconds)
    FLog       : TLog_Node;        // default log node for logger self-logging
    FDest      : TLogEndpoints;    // array of log endpoints
    FNodes     : TList<TLog_Node>; // list of log nodes

    function  GrabRecords:TArray<TLogRecord>;
    procedure SortRecords(var R:TArray<TLogRecord>);
    function  MergeRecords(const R:TArray<TLogRecord>; const AsCSV:Boolean):AnsiString;
    procedure SaveRecords;
    procedure SaveToFile(const S:AnsiString);
    procedure SaveToMemo(const S:AnsiString);
    procedure SaveToCons(const S:AnsiString);
    procedure UnregReport(const Node:TLog_Node);

   public

    const

     MaxMemoLines = 16 * 1024;
     SleepTime    = 250;

    constructor Create;
    destructor  Destroy; override;

    // set/unset endpoints
    function  SetLogFile(const Filename:string):Boolean;
    function  SetLogMemo(const Strings:TStrings):Boolean;
    function  SetLogCons(const LogReady,MapAccess,MapFile:string; const BufSize:Int32):Boolean;
    procedure Unset(const E:TLogEndpointType);
    // add/remove log node
    function RegNode(const Node:TLog_Node):Boolean;
    function UnregNode(const Node:TLog_Node):Boolean;
    // thread
    procedure Start;
    procedure Execute; override;
    // log output by default
    procedure Write(const Msg:AnsiString; const Producer:AnsiString=''; const Severity:TLogSeverity=logInfo; const DT:TDateTime=0);
    // check if node connected to server
    function IsConnected(const Node:TLog_Node):Boolean;
    // generate new log line identifier
    function NextID:Int64;

    property SaveCount : Int64  read FSaveCount;
    property SaveTime  : Double read FSaveTime;

  end;

  Lib32Logger = Singletone<TLog_Server>;

 implementation

 const

   LogEndpointName : array [TLogEndpointType] of AnsiString =
   ('File', 'Memo', 'Console', 'Server');

   LogSeverityName : array [TLogSeverity] of AnsiString =
   ('Fatal', 'Error', 'Warn', 'Info', 'Trace', 'Debug');

 // ************************************************************************* //
 //  TLogRecord                                                               //
 // ************************************************************************* //

 // ***************************************************************************
 function TLogRecord.ToString(const CSV:Boolean):AnsiString;
  begin
   if Text<>'' then
    if CSV
     then Result := FormatDatetime(dt_format,DT) + csvlineseparator + Hold.Name + csvlineseparator + Prod + csvlineseparator + LogSeverityName[LS] + csvlineseparator + Text + loglinefeed
     else Result := FormatDatetime(dt_format,DT) + ' [' + Hold.Name + '] ' + Text + loglinefeed
   else
    if CSV
     then Result := csvlineseparator + csvlineseparator + csvlineseparator + loglinefeed
     else Result := loglinefeed
  end;

 // ************************************************************************* //
 //  TLogEndpoint                                                             //
 // ************************************************************************* //

 // ***************************************************************************
 procedure TLogEndpoint.Free;
  begin
   case ET of
    toFile : if F<>Nil then FreeAndNil(F);
    toMemo : { we don't owner of strings so do nothing } ;
    toCons :
     begin
      if LogSize   <> Nil                  then UnmapViewOfFile(LogSize);
      if LogReady  <> INVALID_HANDLE_VALUE then CloseHandle(LogReady);
      if MapAccess <> INVALID_HANDLE_VALUE then CloseHandle(MapAccess);
      if MapFile   <> INVALID_HANDLE_VALUE then CloseHandle(MapFile);
     end;
    toServ : {UNDER CONSTRUCTION !!!} ;
   end;
  end;

 // ***************************************************************************
 procedure TLogEndpoint.Clear;
  begin
   case ET of
    toFile : F := Nil;
    toMemo : S := Nil;
    toCons :
     begin
      LogReady  := INVALID_HANDLE_VALUE;
      MapAccess := INVALID_HANDLE_VALUE;
      MapFile   := INVALID_HANDLE_VALUE;
      LogSize   := Nil;
      Data      := Nil;
      BufSize   := 0;
     end;
    toServ : {UNDER CONSTRUCTION !!!} ;
   end;
  end;

 // ***************************************************************************
 function TLogEndpoint.Ready:Boolean;
  begin
   case ET of
    toFile : Result := (F<>Nil) and (F.Handle<>INVALID_HANDLE_VALUE);
    toMemo : Result := S<>Nil;
    toCons : Result := (LogReady<>INVALID_HANDLE_VALUE) and
                       (MapAccess<>INVALID_HANDLE_VALUE) and
                       (LogSize<>Nil);
    toServ : Result := false; {UNDER CONSTRUCTION !!!}
   end;
  end;

 // ************************************************************************* //
 //  TLog_Node                                                                //
 // ************************************************************************* //

 // ***************************************************************************
 function TLog_Node.GetIsConnected:Boolean;
  begin
   Result := (FOwner<>Nil) and FOwner.IsConnected(Self);
  end;

 // ***************************************************************************
 constructor TLog_Node.Create(const N:AnsiString; const BufSize:Int32; const Srv:TLog_Server=Nil);
  begin
   inherited Create;
   SetLength(FBuffer,BufSize);
   FName      := N;
   FActive    := false;
   FCount     := 0;
   FSaveCount := 0;
   if Srv<>Nil then Srv.RegNode(Self);
  end;

 // ***************************************************************************
 destructor TLog_Node.Destroy;
  begin
   if Connected then FOwner.UnregNode(Self);
   FBuffer := Nil;
   inherited Destroy;
  end;

 // ***************************************************************************
 procedure TLog_Node.Write(const Msg:AnsiString; const Producer:AnsiString=''; const Severity:TLogSeverity=logInfo; const DT:TDateTime=0);
  var d : TDateTime;
  begin
   if (not FActive) or (FOwner=Nil) then Exit;
   //
   try
    TMonitor.Enter(Self);
    // check buffer size
    if FCount=Length(FBuffer) then SetLength(FBuffer,Length(FBuffer)+DefaultBufferGrow);
    // fill log record
    if DT=0 then d := Now else d := DT;
    FBuffer[FCount].ID   := FOwner.NextID;
    FBuffer[FCount].Prod := Producer;
    FBuffer[FCount].Hold := Self;
    FBuffer[FCount].DT   := d;
    FBuffer[FCount].LS   := Severity;
    FBuffer[FCount].Text := Msg;
    Inc(FCount);
    // update log node statistics
    Inc(FSaveCount);
   finally
    TMonitor.Exit(Self);
   end;
  end;

 // ***************************************************************************
 function TLog_Node.Extract:TArray<TLogRecord>;
  var N : Int32;
  begin
   Result := Nil;
   try
    TMonitor.Enter(Self);
    SetLength(Result,FCount);
    N := FCount * SizeOf(TLogRecord);
    System.Move(FBuffer[0],Result[0],N);
    FillChar(FBuffer[0],N,0);
    FCount := 0;
   finally
    TMonitor.Exit(Self);
   end;
  end;

 // ************************************************************************* //
 //  TLog_Server                                                              //
 // ************************************************************************* //

 // ***************************************************************************
 function TLog_Server.GrabRecords:TArray<TLogRecord>;
  var i : Int32;
  begin
   Result := Nil;
   for i:=0 to FNodes.Count-1 do Result := Result + FNodes[i].Extract;
  end;

 // ***************************************************************************
 procedure TLog_Server.SortRecords(var R:TArray<TLogRecord>);
  var i,j  : Integer;
      temp : TLogRecord;
  begin
   if Length(R)<=1 then Exit;
   for i:=1 to High(R) do
    begin
     temp := R[i];
     j    := i-1;
     while (j>=0) and (R[j].ID>temp.ID) do
      begin
       R[j+1] := R[j];
       Dec(j);
      end;
     R[j+1] := temp;
    end;
  end;

 // ***************************************************************************
 // AsCSV = true  - for File & Remote Server transfer; use all columns divided by csvlineseparator
 // AsCSV = false - for Memo & Console transfer; datetime, nodename, logmessage divided by " " (without last loglinefeed)
 function TLog_Server.MergeRecords(const R:TArray<TLogRecord>; const AsCSV:Boolean):AnsiString;
  var i : Int32;
  begin
   Result := '';
   for i:=0 to High(R) do Result := Result + R[i].ToString(AsCSV);
   if not AsCSV then SetLength(Result,Length(Result)-Length(loglinefeed));
  end;

 // ***************************************************************************
 procedure TLog_Server.SaveRecords;
  var
   A : TArray<TLogRecord>;
   S : AnsiString;
   t : TStopWatch;
  begin
   try
    TMonitor.Enter(FNodes);
    t.Start;
    A := GrabRecords;
    if A<>Nil then
     begin
      SortRecords(A);
      // Memo, Console
      if FDest[toMemo].Ready or FDest[toCons].Ready then
       begin
        S := MergeRecords(A,false);
        SaveToMemo(S);
        SaveToCons(S);
       end;
      // File, Server
      if FDest[toFile].Ready or FDest[toServ].Ready then
       begin
        S := MergeRecords(A,true);
        SaveToFile(S);
        //SaveToServ(S);
       end;
      A := Nil;
      S := '';
     end;
    t.Stop;
    FSaveTime := FSaveTime + t.Elapsed_Sec;
   finally
    TMonitor.Exit(FNodes);
   end;
  end;

 // ***************************************************************************
 procedure TLog_Server.SaveToFile(const S:AnsiString);
  begin
   if (S='') or (FDest[toFile].F=Nil) or (FDest[toFile].F.Handle=INVALID_HANDLE_VALUE) then Exit;
   try
    FDest[toFile].F.Write(S[1],Length(S));
   except
    { TODO : какие то проблемы с файлом ??? }
   end;
  end;

 // ***************************************************************************
 procedure TLog_Server.SaveToMemo(const S:AnsiString);
  begin
   if (S='') or (not FDest[toMemo].Ready) then Exit;
   try
    FDest[toMemo].S.BeginUpdate;
    FDest[toMemo].S.Add(S);
    FDest[toMemo].S.EndUpdate;
   except
    { TODO : какие то проблемы с мемо ??? }
   end;
  end;

 // ***************************************************************************
 procedure TLog_Server.SaveToCons(const S:AnsiString);
  var
   N : Int32;
   R : Cardinal;
  begin
   if (S='') or (not FDest[toCons].Ready) then Exit;
   //
   R := WaitForSingleObject(FDest[toCons].MapAccess,100);
   case R of
    WAIT_OBJECT_0  :
     try
      N := Length(S);
      if N > FDest[toCons].BufSize then N := FDest[toCons].BufSize;
      Int32(FDest[toCons].LogSize^) := N;
      System.Move(S[1],FDest[toCons].Data^,N);
     finally
      ReleaseMutex(FDest[toCons].MapAccess);
      SetEvent(FDest[toCons].LogReady);
     end;
    WAIT_TIMEOUT   : FLog.Write(Format('Transfer %d bytes to console failed due timeout',[N]));
    WAIT_FAILED,
    WAIT_ABANDONED :
     begin
      FDest[toCons].Free;
      FDest[toCons].Clear;
      FLog.Write('Transfer to console failed due critical error. Detach console endpoint.');
     end;
   end;
  end;

 // ***************************************************************************
 procedure TLog_Server.UnregReport(const Node:TLog_Node);
  begin
   if (FLog=Nil) or (Node=Nil) then Exit;
   FLog.Write(Format('Unregister node "%s" - OK (Buffer:%d Saved Lines:%d)',[Node.Name, Length(Node.FBuffer), Node.SaveCount]));
  end;

 // ***************************************************************************
 constructor TLog_Server.Create;
  begin
   inherited Create(true);
   FreeOnTerminate := false;
   try
    FDest[toFile].ET := toFile; FDest[toFile].Clear;
    FDest[toMemo].ET := toMemo; FDest[toMemo].Clear;
    FDest[toCons].ET := toCons; FDest[toCons].Clear;
    FDest[toServ].ET := toServ; FDest[toServ].Clear;
    FSaveCount := 0;
    FSaveTime  := 0;
    FNodes     := TList<TLog_Node>.Create;
    FLog       := TLog_Node.Create('Logger',64);
    FNodes.Add(FLog);
    FLog.Owner  := Self;
    FLog.Active := true;
    FLog.Write(Format('Register node "%s" - OK',[FLog.Name]));
    FLog.Write('Log server create - OK');
   except
    // stub !
   end;
  end;

 // ***************************************************************************
 destructor TLog_Server.Destroy;
  var i : Int32;
  begin
   // immediate clear the link to memo strings
   FDest[toMemo].S := Nil;
   // terminate thread
   FLog.Write('Terminate log thread');
   if Started then
    begin
     Terminate;
     WaitFor;
    end;
   // save & unreg all nodes except FLog
   SaveRecords;
   for i:=0 to FNodes.Count-1 do if FNodes[i]<>FLog then
    begin
     FNodes[i].Active := false;
     FNodes[i].Owner  := Nil;
     UnregReport(FNodes[i]);
    end;
   // server summary
   UnregReport(FLog);
   FLog.Write('Log server stop');
   FLog.Write(Format('Logged %d lines in %0.6f seconds',[FSaveCount,FSaveTime]));
   FLog.Active := false;
   FLog.Owner  := Nil;
   // last log transfer
   SaveRecords;
   // clear memory
   if FLog<>Nil   then FreeAndNil(FLog);
   if FNodes<>Nil then FreeAndNil(FNodes);
   FDest[toFile].Free;
   FDest[toCons].Free;
   inherited Destroy;
  end;

 // ***************************************************************************
 function TLog_Server.SetLogFile(const Filename:string):Boolean;
  var FileHeader : AnsiString;
  begin
   Result := false;
   try
    TMonitor.Enter(FNodes);
    try
     FDest[toFile].Free;
     FDest[toFile].Clear;
     FDest[toFile].F := TFileStream.Create(Filename,fmCreate or fmShareDenyWrite);
     FileHeader := 'Datetime'+csvlineseparator+'LogNode'+csvlineseparator+'Producer'+csvlineseparator+'Severity Level'+csvlineseparator+'Message Text'#13#10;
     FDest[toFile].F.Write(FileHeader[1],Length(FileHeader));
     FLog.Write(Format('Log file "%s" open - OK',[Filename]));
     Result := true;
    except
     FLog.Write(Format('Log file "%s" open - FAIL',[Filename]));
    end;
   finally
    TMonitor.Exit(FNodes);
   end;
  end;

 // ***************************************************************************
 function TLog_Server.SetLogMemo(const Strings:TStrings):Boolean;
  begin
   Result := false;
   try
    TMonitor.Enter(FNodes);
    if Strings<>Nil then
     begin
      FDest[toMemo].S := Strings;
      FDest[toMemo].S.Clear;
      Result := true;
      FLog.Write('Log strings init - OK');
     end
    else FLog.Write('Log strings init - FAIL');
   finally
    TMonitor.Exit(FNodes);
   end;
  end;

 // ***************************************************************************
 function TLog_Server.SetLogCons(const LogReady,MapAccess,MapFile:string; const BufSize:Int32):Boolean;
  begin
   Result := false;
   try
    TMonitor.Enter(FNodes);
    // close & clear handles
    FDest[toCons].Free;
    FDest[toCons].Clear;
    // try open sync objects
    FDest[toCons].LogReady  := OpenEvent      (EVENT_ALL_ACCESS,    false, PChar(LogReady ));
    FDest[toCons].MapAccess := OpenMutex      (MUTEX_ALL_ACCESS,    false, PChar(MapAccess));
    FDest[toCons].MapFile   := OpenFileMapping(FILE_MAP_ALL_ACCESS, false, PChar(MapFile  ));
    // check results
    if FDest[toCons].LogReady<>0
     then FLog.Write(Format('Open event "%s" - OK (handle:%d)',[LogReady,FDest[toCons].LogReady]))
     else FLog.Write(Format('Open event "%s" - FAIL',[LogReady]));
    if FDest[toCons].MapAccess<>0
     then FLog.Write(Format('Open mutex "%s" - OK (handle:%d)',[MapAccess,FDest[toCons].MapAccess]))
     else FLog.Write(Format('Open mutex "%s" - FAIL',[MapAccess]));
    if FDest[toCons].MapAccess<>0
     then FLog.Write(Format('Open file mapping "%s" - OK (handle:%d)',[MapFile,FDest[toCons].MapFile]))
     else FLog.Write(Format('Open file mapping "%s" - FAIL',[MapFile]));
    // final conclusion
    Result := (FDest[toCons].LogReady<>0) and (FDest[toCons].MapAccess<>0) and (FDest[toCons].MapFile<>0);
    if not Result then Exit;
    // map LogSize & Data
    FDest[toCons].BufSize := BufSize;
    FDest[toCons].LogSize := MapViewOfFile(
     FDest[toCons].MapFile,    // handle to map object
     FILE_MAP_ALL_ACCESS,      // read/write permission
     0,                        // dwFileOffsetHigh DWORD
     0,                        // dwFileOffsetLow  DWORD
     4+FDest[toCons].BufSize); // data size + data
    Result := FDest[toCons].LogSize <> Nil;
    if not Result then Exit;
    FDest[toCons].Data := Pointer(Int32(FDest[toCons].LogSize) + 4);
    FLog.Write('Open console log - OK');
   finally
    if not Result then
     begin
      FDest[toCons].Free;
      FDest[toCons].Clear;
      FLog.Write('Open console log - FAIL');
     end;
    TMonitor.Exit(FNodes);
   end;
  end;

 // ***************************************************************************
 procedure TLog_Server.Unset(const E:TLogEndpointType);
  begin
   try
    TMonitor.Enter(FNodes);
    FDest[E].Free;
    FDest[E].Clear;
    FLog.Write(Format('Unset endpoint "%s" - OK',[LogEndpointName[E]]));
   finally
    TMonitor.Exit(FNodes);
   end;
  end;

 // ***************************************************************************
 function TLog_Server.RegNode(const Node:TLog_Node):Boolean;
  begin
   Result := false;
   if Node=Nil then Exit;
   //
   try
    TMonitor.Enter(FNodes);
    FNodes.Add(Node);
    Node.Owner  := Self;
    Node.Active := true;
    Result      := true;
    FLog.Write(Format('Register node "%s" - OK',[Node.Name]));
   finally
    TMonitor.Exit(FNodes);
   end;
  end;

 // ***************************************************************************
 function TLog_Server.UnregNode(const Node:TLog_Node):Boolean;
  begin
   Result := false;
   if (Node=Nil) or (Node.Owner<>Self) then Exit;
   //
   SaveRecords;
   try
    TMonitor.Enter(FNodes);
    FNodes.Remove(Node);
    Node.Owner  := Nil;
    Node.Active := false;
    Result      := true;
    UnregReport(Node);
   finally
    TMonitor.Exit(FNodes);
   end;
  end;

 // ***************************************************************************
 procedure TLog_Server.Start;
  begin
   FLog.Write('Log server start');
   inherited Start;
  end;

 // ***************************************************************************
 procedure TLog_Server.Execute;
  begin
   while not Terminated do
    begin
     // auto clear memo if need
     if (FDest[toMemo].S<>Nil) and (FDest[toMemo].S.Count>MaxMemoLines) then FDest[toMemo].S.Clear;
     // extract & transfer log records
     SaveRecords;
     // wait for next cycle
     Sleep(SleepTime);
    end;
  end;

 // ***************************************************************************
 procedure TLog_Server.Write(const Msg:AnsiString; const Producer:AnsiString=''; const Severity:TLogSeverity=logInfo; const DT:TDateTime=0);
  begin
   if FLog<>Nil then FLog.Write(Msg,Producer,Severity,DT);
  end;

 // ***************************************************************************
 function TLog_Server.IsConnected(const Node:TLog_Node):Boolean;
  begin
   Result := (Node<>Nil) and (Node.FOwner=Self) and (FNodes.IndexOf(Node)<>-1);
  end;

 // ***************************************************************************
 function TLog_Server.NextID:Int64;
  begin
   Result := AtomicIncrement(FSaveCount);
  end;

end.
