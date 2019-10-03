{******************************************************************************}
{* Program : lib32 library                                                    *}
{* Unit    : Log output via console (demo)                                    *}
{* Change  : 25.09.2019 (192 lines)                                           *}
{* Comment : console must run as administrator                                *}
{*                                                                            *}
{* Copyright (c) 2011-2019 DelphiRunner                                       *}
{******************************************************************************}

program logconsole;

 {$APPTYPE CONSOLE}

 {$R *.res}

 uses

  Winapi.Windows, Winapi.Messages, System.Types, System.SysUtils, System.StrUtils;

 var

  // command line parameters default values
  Par_LogReady  : string = 'Global\ConsoleLog.LogReady';
  Par_MapAccess : string = 'Global\ConsoleLog.MapAccess';
  Par_Map       : string = 'Global\ConsoleLog.MapFile';
  Par_MapSize   : Int32  = 64 * 1024;

  //
  LogReady  : THandle = INVALID_HANDLE_VALUE; // event - is log strings wait for output ?
  MapAccess : THandle = INVALID_HANDLE_VALUE; // mutex - shared memory access
  MapFile   : THandle = INVALID_HANDLE_VALUE; // mfile - shared memory (in page file)
  DataSize  : Pointer = Nil;
  Data      : Pointer = Nil;
  DataStr   : AnsiString = '';
  Condition : PWOHandleArray;

 // logready:<name>
 // access:<name>
 // map:<name>
 // size:<size in bytes>
 procedure ResolveParam(const P:string);
  var sa : TStringDynArray;
  begin
   sa := SplitString(P,':');
   if sa=Nil then Exit;
   sa[0] := UpperCase(sa[0]);
   //
   if sa[0]='LOGREADY' then Par_LogReady  := sa[1] else
   if sa[0]='ACCESS'   then Par_MapAccess := sa[1] else
   if sa[0]='MAP'      then Par_Map       := sa[1] else
   if sa[0]='SIZE' then
    begin
     if not TryStrToInt(sa[1],Par_MapSize)
      then WriteLn('Incorrect buffer size: "'+sa[1]+'"');
    end
   else WriteLn('Unknown parameter: "'+P+'"');
  end;

 function ConsoleEventProc(CtrlType:DWORD):BOOL; stdcall;
  begin
   if (CtrlType = CTRL_C_EVENT) or (CtrlType = CTRL_CLOSE_EVENT) then
    begin
     WriteLn('Stop logging and exit'#13#10);
     Sleep(500);
     FreeMem(Condition);
     if DataSize  <> Nil                  then UnmapViewOfFile(DataSize);
     if LogReady  <> INVALID_HANDLE_VALUE then CloseHandle(LogReady);
     if MapAccess <> INVALID_HANDLE_VALUE then CloseHandle(MapAccess);
     if MapFile   <> INVALID_HANDLE_VALUE then CloseHandle(MapFile);
    end;
   Result := True;
  end;

 var i,n : Int32;
     err : DWORD;
     R   : Cardinal;
 begin
  try
   SetConsoleCtrlHandler(@ConsoleEventProc,true);

   // update parameters from command line ......................................
   for i:=1 to ParamCount do ResolveParam(ParamStr(i));
   WriteLn(Format('Event "LogReady"  : %s',[Par_LogReady ]));
   WriteLn(Format('Mutex "MapAccess" : %s',[Par_MapAccess]));
   WriteLn(Format('MapFile           : %s',[Par_Map      ]));
   WriteLn(Format('Buffer size       : %d',[Par_MapSize  ]));

   // create file mapping ......................................................
   Par_MapSize := 4 + Par_MapSize; // <data length> + <data>
   MapFile := CreateFileMapping(
    INVALID_HANDLE_VALUE, // use paging file
    Nil,                  // default security
    PAGE_READWRITE,       // read/write access
    0,                    // maximum object size (high-order DWORD)
    Par_MapSize,          // maximum object size (low-order DWORD)
    PChar(Par_Map));      // name of mapping object
    if MapFile = 0 then
     begin
      WriteLn(Format('Create "%s" failed; Error = %d;',[Par_Map,GetLastError]));
      ReadLn;
      Exit;
     end;
    WriteLn(Format('Create "%s"; Handle = %d;',[Par_Map,MapFile]));

   // create event "LogReady" ..................................................
   LogReady := CreateEvent(
    Nil,                  // default security
    true,                 // manual reset
    false,                // initial state of log strings is "not ready"
    PChar(Par_LogReady)); // event name
    if LogReady = 0 then
     begin
      WriteLn(Format('Create "%s" failed; Error = %d;',[Par_LogReady,GetLastError]));
      ReadLn;
      Exit;
     end;
    WriteLn(Format('Create "%s"; Handle = %d;',[Par_LogReady,LogReady]));

   // create mutex "MapAccess" .................................................
   MapAccess := CreateMutex(
    Nil,                   // default security
    false,                 // mutex signaled so access to shared memory is allowed
    PChar(Par_MapAccess)); // mutex name
   if MapAccess = 0 then
     begin
      WriteLn(Format('Create "%s" failed; Error = %d;',[Par_MapAccess,GetLastError]));
      ReadLn;
      Exit;
     end;
   WriteLn(Format('Create "%s"; Handle = %d;',[Par_MapAccess,MapAccess]));

   // map DataSize & Data ......................................................
   DataSize := MapViewOfFile(
    MapFile,             // handle to map object
    FILE_MAP_ALL_ACCESS, // read/write permission
    0,                   // dwFileOffsetHigh DWORD
    0,                   // dwFileOffsetLow  DWORD
    Par_MapSize);        // data size + data
   if DataSize=Nil then
     begin
      WriteLn(Format('MapViewOfFile failed; Error = %d;',[GetLastError]));
      ReadLn;
      Exit;
     end;
   Data := Pointer(Int32(DataSize) + 4);
   WriteLn('Map data - OK');

   // prepare condition ........................................................
   Condition    := AllocMem(2*SizeOf(THandle));
   Condition[0] := LogReady;  // log strings are written to shared memory
   Condition[1] := MapAccess; // shared memory is accessible

   // logging loop .............................................................
   WriteLn('Start logging'#13#10);
   while true do
    begin
     R := WaitForMultipleObjects(2,Condition,true,1000);
     case R of
      // log strings need to be output to console
      WAIT_OBJECT_0  :
       try
        // copy and check DataSize value
        n := Int32(DataSize^);
        if n=0 then Continue;
        if n>Par_MapSize-4 then n := Par_MapSize-4;
        // move data to AnsiString
        SetLength(DataStr,n);
        System.Move(Data^,DataStr[1],n);
        // write data to standard output
        WriteLn(DataStr);
       finally
        ResetEvent(LogReady);
        ReleaseMutex(MapAccess);
       end;
      // no log strings in this time so do nothing
      WAIT_TIMEOUT   : ;
      // some error occured
      WAIT_FAILED    : Exit;
      WAIT_ABANDONED : Exit;
     end;
    end;

  except
   on E:Exception do
    begin
     WriteLn(E.Message);
     WriteLn('Press ENTER to exit ...');
     ReadLn;
    end;
  end;

 end.
