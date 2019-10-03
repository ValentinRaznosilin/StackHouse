{******************************************************************************}
{* Project : "StackHouse" virtual stack-machine                               *}
{* Unit    : Global space                                                     *}
{* Change  : 03.10.2019 (574 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2019 DelphiRunner                                            *}
{******************************************************************************}

unit SH.System;

 interface

 uses

  // system
  System.Types,
  System.Math,
  System.SysUtils,
  System.StrUtils,
  System.IOUtils,
  System.Classes,
  WinAPI.Windows,
  System.Generics.Defaults,
  System.Generics.Collections,
  // project
  SH.Codes,
  SH.Types,
  SH.Utils,
  SH.Runtime;

 const

  // reserved space for internally implemented system functions
  // all externals must start from SYSTEM_RANGE + 1
  SYSFUNCS_RANGE = 100;

  // console I/O
  SYS_CONSOLE_Clear    =  0; // [ ]
  SYS_CONSOLE_ClrLine  =  1; // [ ]
  SYS_CONSOLE_GetPos   =  2; // [ ]
  SYS_CONSOLE_SetPos   =  3; // [ ]
  SYS_CONSOLE_Print    =  4; // [+]
  SYS_CONSOLE_PrintL   =  5; // [+]
  SYS_CONSOLE_Input    =  6; // [+]
  SYS_CONSOLE_TextAttr =  7; // [ ]

  // file I/O
  SYS_FILE_Exists      =  8; // [ ]
  SYS_FILE_Open        =  9; // [ ]
  SYS_FILE_Close       = 10; // [ ]
  SYS_FILE_ReadBuf     = 11; // [ ]
  SYS_FILE_WriteBuf    = 12; // [ ]
  SYS_FILE_ReadLn      = 13; // [ ]
  SYS_FILE_WriteLn     = 14; // [ ]
  SYS_FILE_Eof         = 15; // [ ]

  // high performance counter
  SYS_HPC_Ticks        = 16; // [+] get ticks
  SYS_HPC_Frequency    = 17; // [+] get frequency

  // date & time
  SYS_DT_Time          = 18; // [ ] get system time
  SYS_DT_Date          = 19; // [ ] get system date
  SYS_DT_Now           = 20; // [ ] get system datetime
  SYS_DT_CmpTime       = 21; // [ ] compare time
  SYS_DT_CmpDate       = 22; // [ ] compare date
  SYS_DT_CmpDateTime   = 23; // [ ] compare datetime
  SYS_DT_ToStr         = 24; // [ ] datetime to string
  SYS_DT_FromStr       = 25; // [ ] datetime from string
  SYS_DT_ToUnix        = 26; // [ ] datetime to unixtime
  SYS_DT_FromUnix      = 27; // [ ] datetime from unixtime
  SYS_DT_Encode        = 28; // [ ] encode datetime from Y M D H M S ms
  SYS_DT_Decode        = 29; // [ ] decode datetime to Y M D H M S ms
  SYS_DT_IncMs         = 30; // [ ] shift datetime by milliseconds
  SYS_DT_MsBetween     = 31; // [ ] get milliseconds between two datetimes

  // string
  SYS_STR_Cat          = 32; // [+] strings concatenation : C = A + B
  SYS_STR_Add          = 33; // [+] string append         : A = A + B
  SYS_STR_Cmp          = 34; // [ ] strings compare
  SYS_STR_Pos          = 35; // [ ] substring position
  SYS_STR_Rep          = 36; // [ ] replace substring
  SYS_STR_Cut          = 37; // [ ] cut substring         : C = A - <range>
  SYS_STR_Split        = 38; // [ ] split string by delimiter
  SYS_STR_Upper        = 39; // [ ] string upper case
  SYS_STR_Lower        = 40; // [ ] string lower case

  // array of data
  SYS_ARR_Cat          = 41; // [+] arrays concatenation  : C = A + B
  SYS_ARR_Add          = 42; // [ ] array append          : A = A + B
  SYS_ARR_Cut          = 43; // [ ] cut subarray          : C = A - <range>
  SYS_ARR_Fill         = 44; // [ ] fill array with value

  // common stuff
  SYS_IntToStr         = 45; // [ ] integer  to string
  SYS_FloatToStr       = 46; // [ ] float    to string
  SYS_StrToInt         = 47; // [ ] string   to integer
  SYS_StrToFloat       = 48; // [ ] string   to float
  SYS_FuncIndex        = 49; // [+] get function index by name
  SYS_Case             = 50; // [ ] case

 type

  // external file descriptor *************************************************
  TExternalFile = record

   Module    : THandle;        // dll handle
   DecorName : string;         // dll decor name (file_name)
   ShortName : string;         // dll short name (file_name + file_ext)
   FullName  : string;         // dll full name (file_path + file_name + file_ext)
   Items     : TArray<string>; // exported functions names (decorated!)

   function  DecorateName(const FN:string):AnsiString;
   function  LoadModule(const FN:string; out Error:string):Boolean;
   function  LoadSymbol(const FN:string; out Error:string):Boolean;
   function  LoadAllSymbols(out Error:string):Boolean;
   procedure FreeModule;

  end;

  // externals files **********************************************************
  TExternals = record

   Items : TArray<TExternalFile>;

   function  SymCount:Int32;
   function  ModuleIndex(const FN:string):Int32;
   function  ImportAllSymbols(const ModuleName:string; out Error:string):Boolean;
   function  ImportSymbol(const ModuleName,SymbolName:string; out Error:string):Boolean;
   procedure FreeModules;

  end;

  function CONSOLE_Print    (const F:PFrame):Int32;
  function CONSOLE_PrintLine(const F:PFrame):Int32;
  function CONSOLE_Input    (const F:PFrame):Int32;
  function TIME_Now         (const F:PFrame):Int32;
  function TIME_HpcCount    (const F:PFrame):Int32;
  function TIME_HpcFreq     (const F:PFrame):Int32;
  function FMT_Datetime     (const F:PFrame):Int32;
  function _case_           (const F:PFrame):Int32;
  function StrCat           (const F:PFrame):Int32;
  function StrAdd           (const F:PFrame):Int32;
  function FunctionIndex    (const F:PFrame):Int32;

 var

  SysNames  : TDictionary<AnsiString,Int64> = Nil; // system functions dictionary (internals + externals)
  SysFuncs  : TArray<TSystemFunction> = Nil;       // system functions pointers (internals + externals)
  Externals : TExternals;                          // external functions info
  GloNames  : TDictionary<AnsiString,Int64> = Nil; // global data dictionary
  Globals   : TStorage = Nil;                      // global data storage

 implementation

// ************************************************************************** //
//  TExternalFile                                                             //
// ************************************************************************** //

 function TExternalFile.DecorateName(const FN: string): AnsiString;
  begin
   Result := '%' + DecorName + ':' + UpperCase(FN);
  end;

 function TExternalFile.LoadModule(const FN:string; out Error:string):Boolean;
  begin
   Module := LoadLibrary(PChar(FN));
   if Module=0 then
    begin
     Error := Format('External file "%s" load failed (error = %d)',[FN,GetLastError]);
     Exit(false);
    end;
   //
   SetLength(FullName,1024);
   SetLength(FullName,GetModuleFileName(Module,PChar(FullName),1024));
   FullName  := UpperCase(FullName);
   ShortName := ExtractFileName(FullName);
   DecorName := System.IOUtils.TPath.GetFileNameWithoutExtension(ShortName); // remove ".dll" extension
   Error     := '';
   Exit(true);
  end;

 function TExternalFile.LoadSymbol(const FN:string; out Error:string):Boolean;
  var
   fun : TSystemFunction;
   nam : AnsiString;
  begin
   //
   nam := DecorateName(FN);
   // if symbol has been already imported, then continue without error .........
   if SysNames.ContainsKey(nam) then Exit(true);
   // is module load ? .........................................................
   if Module = 0 then
    begin
     Error := Format('Can not load external symbol "%s" due module not initialized',[FN]);
     Exit(false);
    end;
   // try to get address of function ...........................................
   fun := GetProcAddress(Module,PChar(FN));
   if not Assigned(fun) then
    begin
     Error := Format('Load external symbol "%s" from "%s" failed (error = %d)',[FN,ShortName,GetLastError]);
     Exit(false);
    end;
   // ok, adding it ............................................................
   Items    := Items    + [nam ];
   SysFuncs := SysFuncs + [@fun];
   SysNames.Add(nam,High(SysFuncs));
   Error := '';
   Exit(true);
  end;

 function TExternalFile.LoadAllSymbols(out Error:string):Boolean;
  type P = procedure (const Buffer:PChar; var Size:Int32);
  var
   GetExportedNames : P;
   Buffer : PChar;
   Size,i : Int32;
   List   : TArray<string>;
  begin
   // is module load ? .........................................................
   if Module = 0 then
    begin
     Error := 'Can not load external symbols due module not initialized';
     Exit(false);
    end;
   // try to get address of GetExportedNames ...................................
   GetExportedNames := GetProcAddress(Module,PChar('GetExportedNames'));
   if not Assigned(GetExportedNames) then
    begin
     Error := Format('Load external symbols from "%s" failed due "GetExportedNames" not found',[ShortName]);
     Exit(false);
    end;
   // get external symbols names ...............................................
   Size   := 32*1024;
   Buffer := AllocMem(Size); // just about 1000 external symbols names can be read !
   GetExportedNames(Buffer,Size);
   if Size=0 then
    begin
     Error := Format('No external symbols found in "%s"',[ShortName]);
     Exit(false);
    end;
   // load external symbols ....................................................
   try
    List := string(Buffer).Split([#10]);
    for i:=0 to High(List) do if List[i]<>'' then
     if not LoadSymbol(List[i],Error) then Exit(false);
    Exit(true);
   finally
    List := Nil;
    FreeMem(Buffer);
   end;
  end;

 procedure TExternalFile.FreeModule;
  begin
   if Module <> 0 then FreeLibrary(Module);
   Items     := Nil;
   Module    := 0;
   FullName  := '';
   ShortName := '';
  end;

// ************************************************************************** //
//  TExternals                                                                //
// ************************************************************************** //

 function TExternals.SymCount:Int32;
  var i : Int32;
  begin
   Result := 0;
   for i:=0 to High(Items) do Result := Result + Length(Items[i].Items);
  end;

 function TExternals.ModuleIndex(const FN:string):Int32;
  var
   i : Int32;
   S : string;
  begin
   S := UpperCase(FN);
   for i:=0 to High(Items) do
    if Items[i].DecorName = S then Exit(i);
   Exit(-1);
  end;

 function TExternals.ImportSymbol(const ModuleName,SymbolName:string; out Error:string):Boolean;
  var
   i : Int32;
   e : TExternalFile;
  begin
   i := ModuleIndex(ModuleName);
   if i = -1 then
    begin
     if not e.LoadModule(ModuleName,Error) then Exit(false);
     Items := Items + [e];
     i     := High(Items);
    end;
   //
   if not Items[i].LoadSymbol(SymbolName,Error) then Exit(false);
   Error := '';
   Exit(true);
  end;

 function TExternals.ImportAllSymbols(const ModuleName:string; out Error:string):Boolean;
  var
   i : Int32;
   e : TExternalFile;
  begin
   i := ModuleIndex(ModuleName);
   if i = -1 then
    begin
     if not e.LoadModule(ModuleName,Error) then Exit(false);
     Items := Items + [e];
     i     := High(Items);
    end;
   //
   if not Items[i].LoadAllSymbols(Error) then Exit(false);
   Error := '';
   Exit(true);
  end;

 procedure TExternals.FreeModules;
  var i,j : Int32;
  begin
   for i:=0 to High(Items) do
    begin
     // clear system dictionary
     for j:=0 to High(Items[i].Items) do SysNames.Remove(Items[i].Items[j]);
     // free library
     Items[i].FreeModule;
    end;
   Items := Nil;
   // restore to base system functions set (without any externals)
   SetLength(SysFuncs,SYSFUNCS_RANGE);
  end;

// ************************************************************************** //
//  System functions                                                          //
// ************************************************************************** //

 // ***************************************************************************
 // in : S[SP-1] = data      S(-)
 // in : S[SP]   = data type S(-) (int float char int[] float[] char[])
 function CONSOLE_Print(const F:PFrame):Int32;
  var
   i : UInt32;
   n : UInt32;
   p : PMemData;
  begin with F^ do begin
   Result := EID_RET;
   SP1    := SP0;
   Dec(SP1);
   case SP0.i8 of
    DATA_INT         : Write(SP1.i8.ToString);
    DATA_FLOAT       : Write(SP1.r8.ToString);
    DATA_CHAR        : Write(SP1.Ch);
    DATA_ARRAY_CHAR  : Write(SP1.StrPtr);
    DATA_ARRAY_INT   :
     begin
      n := SP1.Size div 8;
      p := SP1.Ptr;
      if (n<>0) and (p<>Nil) then for i:=0 to n-2 do Write(p[i].i8.ToString + ' ');
      Write(p[n-1].i8.ToString);
     end;
    DATA_ARRAY_FLOAT :
     begin
      n := SP1.Size div 8;
      p := SP1.Ptr;
      if (n<>0) and (p<>Nil) then for i:=0 to n-2 do Write(p[i].r8.ToString + ' ');
      Write(p[n-1].r8.ToString);
     end;
   end;
   Dec(SP0,2);
  end; end;

 // ***************************************************************************
 // only line feed :
 // in : S[SP] = -1            S(-)
 // print + line feed :
 // in : S[SP-1] = data        S(-)
 // in : S[SP]   = data type   S(-)
 function CONSOLE_PrintLine(const F:PFrame):Int32;
  begin with F^ do begin
   Result := EID_RET;
   if SP0.i8 = -1 then
    begin
     WriteLn;
     Dec(SP0,1);
    end
   else
    begin
     CONSOLE_Print(F);
     WriteLn;
    end;
  end; end;

 // ***************************************************************************
 // in  : S[SP  ] = data type ( 0=int 1=float 2=char 5=char[] )
 // out : S[SP  ] = data value
 // out : S[SP+1] = input result (only for int & float!)
 function CONSOLE_Input(const F:PFrame):Int32;
  var strbuf : AnsiString;
  begin with F^ do begin
   Result := EID_RET;
   case SP0.i8 of
    DATA_INT   :
     try
      ReadLn(SP0.i8);
      Inc(SP1);
      SP1.i8 := 1;
      SP0 := SP1;
     except
      SP0.i8 := 0;
     end;
    DATA_FLOAT :
     try
      ReadLn(SP0.r8);
      Inc(SP1);
      SP1.i8 := 1;
      SP0 := SP1;
     except
      SP0.i8 := 0;
     end;
    DATA_CHAR  :
     begin
      SP0.i8 := 0;
      SP0.Ch := ReadConsoleChar;
     end;
    DATA_ARRAY_CHAR :
     begin
      ReadLn(strbuf);
      Alloc_String(strbuf,SP0^);
      strbuf := '';
     end;
    else Exit;
   end;
  end; end;

 // ***************************************************************************
 // out : S[SP+1] = current system time
 function TIME_Now(const F:PFrame):Int32;
  begin with F^ do begin
   Result := -1;
   Inc(SP0);
   SP0.r8 := Double(Now);
  end; end;

 // ***************************************************************************
 // out : S[SP+1] = high performance counter
 function TIME_HpcCount(const F:PFrame):Int32;
  begin with F^ do begin
   Result := -1;
   Inc(SP0);
   QueryPerformanceCounter(SP0.i8);
  end; end;

 // ***************************************************************************
 // out : S[SP+1] = high performance counter frequency
 function TIME_HpcFreq(const F:PFrame):Int32;
  begin with F^ do begin
   Result := -1;
   Inc(SP0);
   QueryPerformanceFrequency(SP0.i8);
  end; end;

 // ***************************************************************************
 // in  : S[SP-1] = datetime
 // in  : S[SP  ] = string (format)
 // out : S[SP-1] = string (datetime string representation by given format)
 function FMT_Datetime(const F:PFrame):Int32;
  var strbuf : string;
  begin with F^ do begin
   Result := -1;
   Dec(SP1);
   if SP0.StrPtr=Nil
    then DateTimeToString(strbuf,''        ,SP1.r8,System.SysUtils.FormatSettings)
    else DateTimeToString(strbuf,SP0.StrPtr,SP1.r8,System.SysUtils.FormatSettings);
   Alloc_String(strbuf,SP1^);
   strbuf := '';
   SP0    := SP1;
  end; end;

 // ***************************************************************************
 function _case_(const F:PFrame):Int32;
  begin with F^ do begin
   Result := -1;
  end; end;

 // ***************************************************************************
 // in  : S[SP-1] = A_string
 // in  : S[SP  ] = B_string
 // out : S[SP-1] C = A_string + B_string
 function StrCat(const F:PFrame):Int32;
  var
   i   : UInt16;
   pch : PAnsiChar;
  begin with F^ do begin
   Result := -1;
   Dec(SP1);
   i := SP1.StrLen + SP0.StrLen - 1;
   System.GetMem(pch,i);
   System.Move(SP1.StrPtr[0],pch[0]           ,SP1.StrLen-1);
   System.Move(SP0.StrPtr[0],pch[SP1.StrLen-1],SP0.StrLen  );
   SP1.StrLen := i;
   SP1.StrPtr := pch;
   SP0        := SP1;
  end; end;

 // ***************************************************************************
 // in  : S[SP-1] = A_string
 // in  : S[SP  ] = B_string
 // out : S[SP-1] A_string = A_string + B_string
 function StrAdd(const F:PFrame):Int32;
  var
   i : UInt16;
  begin with F^ do begin
   Result := -1;
   Dec(SP1);
   i := SP1.StrLen + SP0.StrLen - 1;
   System.ReallocMem(SP1.StrPtr,i);
   System.Move(SP0.StrPtr[0],SP1.StrPtr[SP1.StrLen-1],SP0.StrLen);
   SP1.StrLen := i;
   SP0        := SP1;
  end; end;

 // ***************************************************************************
 // in  : S[SP] = string  ( function name )
 // out : if index found     :  S[SP] = integer value >= 0( function index )
 // out : if index not found :  S[SP] = integer value -1 ( error )
 function FunctionIndex(const F:PFrame):Int32;
  var idx  : Int64;
  begin with F^ do begin
   Result := -1;
   if PROG.FN.TryGetValue(SP0.StrPtr,idx)
    then SP0.i8 := idx
    else SP0.i8 := -1;
  end; end;

initialization

 SetLength(SysFuncs,SYSFUNCS_RANGE);
 SysNames := TDictionary<AnsiString,Int64>.Create;
 GloNames := TDictionary<AnsiString,Int64>.Create;

 // CONSOLE I/O
 SysNames.Add('%CLRSCR'  ,SYS_CONSOLE_Clear   ); SysFuncs[SYS_CONSOLE_Clear   ] := Nil;
 SysNames.Add('%CLRLIN'  ,SYS_CONSOLE_ClrLine ); SysFuncs[SYS_CONSOLE_ClrLine ] := Nil;
 SysNames.Add('%GETPOS'  ,SYS_CONSOLE_GetPos  ); SysFuncs[SYS_CONSOLE_GetPos  ] := Nil;
 SysNames.Add('%SETPOS'  ,SYS_CONSOLE_SetPos  ); SysFuncs[SYS_CONSOLE_SetPos  ] := Nil;
 SysNames.Add('%PRINT'   ,SYS_CONSOLE_Print   ); SysFuncs[SYS_CONSOLE_Print   ] := CONSOLE_Print;
 SysNames.Add('%PRINTL'  ,SYS_CONSOLE_PrintL  ); SysFuncs[SYS_CONSOLE_PrintL  ] := CONSOLE_PrintLine;
 SysNames.Add('%INPUT'   ,SYS_CONSOLE_Input   ); SysFuncs[SYS_CONSOLE_Input   ] := CONSOLE_Input;
 SysNames.Add('%TXTATTR' ,SYS_CONSOLE_TextAttr); SysFuncs[SYS_CONSOLE_TextAttr] := Nil;

 // FILE I/O
 SysNames.Add('%EXISTS'  ,SYS_FILE_Exists     ); SysFuncs[SYS_FILE_Exists     ] := Nil;
 SysNames.Add('%FOPEN'   ,SYS_FILE_Open       ); SysFuncs[SYS_FILE_Open       ] := Nil;
 SysNames.Add('%FCLOSE'  ,SYS_FILE_Close      ); SysFuncs[SYS_FILE_Close      ] := Nil;
 SysNames.Add('%RDBUFFER',SYS_FILE_ReadBuf    ); SysFuncs[SYS_FILE_ReadBuf    ] := Nil;
 SysNames.Add('%WRBUFFER',SYS_FILE_WriteBuf   ); SysFuncs[SYS_FILE_WriteBuf   ] := Nil;
 SysNames.Add('%RDLINE'  ,SYS_FILE_ReadLn     ); SysFuncs[SYS_FILE_ReadLn     ] := Nil;
 SysNames.Add('%WRLINE'  ,SYS_FILE_WriteLn    ); SysFuncs[SYS_FILE_WriteLn    ] := Nil;
 SysNames.Add('%EOF'     ,SYS_FILE_Eof        ); SysFuncs[SYS_FILE_Eof        ] := Nil;

 finalization

 Externals.FreeModules;
 FreeAndNil(GloNames);
 FreeAndNil(SysNames);
 Globals  := Nil;
 SysFuncs := Nil;

end.
