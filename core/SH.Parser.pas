{******************************************************************************}
{* Project : "StackHouse" virtual stack-machine                               *}
{* Unit    : Parse & Build                                                    *}
{* Change  : 03.10.2019 (1272 lines)                                          *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2019 DelphiRunner                                            *}
{******************************************************************************}

unit SH.Parser;

 interface

 uses
  System.SysUtils, System.StrUtils, System.IOUtils, System.Classes, WinAPI.Windows, System.Math,
  System.Generics.Defaults,
  System.Generics.Collections,
  lib32.Time,
  SH.Codes, SH.Types, SH.Utils, SH.Parser.Base;

 const

  MaxExpandPass  =  5; // see TBlock_Macro ExpandEx

 type

  // macro descriptor *********************************************************
  TBlock_Macro = record

   FN   : string;         // source file name
   Name : string;         // macro name
   Args : TArray<string>; // macro arguments names (order has matters!)
   Text : TArray<string>; // macro template

   class function FindByName(const Name:string; const M:TArray<TBlock_Macro>; out Index:Int32):Boolean; static;

   procedure Clear;
   function  Parse(const FileName:string; const SL:TSourceLines; var M:TArray<TBlock_Macro>; out Error:string):Boolean;
   function  Expand(const CArgs:PSourceLine; const M:TArray<TBlock_Macro>; out SL:TSourceLines; out Error:string):Boolean;
   function  ExpandEx(const CArgs:PSourceLine; const M:TArray<TBlock_Macro>; out SL:TSourceLines; out Error:string):Boolean;
   function  ToList(const IncludeHeader,LineNumbers:Boolean):TStringList;
   procedure Print(const IncludeHeader,LineNumbers:Boolean);

  end;

  // label descriptor *********************************************************
  TLabel = record

   Name : string;
   Line : UInt16;

  end;

  // user function descriptor *************************************************
  TBlock_Func = record

   FN   : string;         // source file name
   ID   : Int32;          // function index
   Name : string;         // function name
   Text : TSourceLines;   // source code
   Lcnt : UInt16;         // local data size
   Scnt : UInt16;         // stack size
   Lab  : TArray<TLabel>; // labels info
   Code : TCode;          // compiled commands
   Imme : Boolean;        // true - function loaded from "immediate" file so don't need process of names & labels

   class function FindByName(const Name:string; const F:TArray<TBlock_Func>; out Index:Int32):Boolean; static;

   procedure Clear;
   function  FindLabel(const Name:string):Int32;
   function  Parse(const FileName:string; const SL:TSourceLines; var F:TArray<TBlock_Func>; out Error:string):Boolean;
   function  FunNamesToIndexes(const F:TArray<TBlock_Func>; out Error:string):Boolean;
   function  LabNamesToIndexes(out Error:string):Boolean;
   function  Compile(out Error:string):Boolean;
   function  ToList(const Ident:Int32; const IncludeHeader,LineNumbers:Boolean):TStringList;
   procedure Print(const Ident:Int32; const IncludeHeader,LineNumbers:Boolean);

  end;

  // project file descriptor **************************************************
  TProjectFile = record

   DecorName  : string;       // decor name (file name)
   ShortName  : string;       // file name (file name + file ext)
   FullName   : string;       // full file name (path + file name + file ext)
   SL         : TSourceLines; // parsed source lines
   LineCount  : UInt32;       // count of source lines initially parsed from source file
   DataCount  : UInt32;       // count of global data
   MacroCount : UInt32;       // count of macros
   FuncCount  : UInt32;       // count of functions
   Unparsed   : UInt32;       // count of unparsed source lines
   Immediate  : Boolean;      // true - file declared as already prepared for compile :
                              // no includes, no macros, no labels, no names except globals
   procedure Clear;
   function  LoadFile(const FN,SN,DN:string; out Error:string):Boolean;

  end;

  TProjectStage =
   (
    stage_INCLUDE,   // look for project files
    stage_IMPORT,    // import external symbols
    stage_GETDATA,   // collect global variables
    stage_GETMACROS, // collect macros
    stage_EXPMACROS, // expand macros
    stage_GETFUNCS,  // collect user functions
    stage_COMPILE,   // compile user functions
    stage_BUILD      // construct program
   );

  TProjectStatus = array [TProjectStage] of Boolean;

  // single project ***********************************************************
  TProject = class(TObject)

   Status : TProjectStatus;        // preprocessor & compilation stages results
   Files  : TArray<TProjectFile>;  // project files
   M      : TArray<TBlock_Macro>;  // macros
   F      : TArray<TBlock_Func>;   // user functions
   EXT    : TArray<string>;        // "EXTERNAL" source lines for entire project
   DAT    : TArray<string>;        // "DATA" source lines for entire project
   REP    : string;                // report text
   BT     : TStopWatch;            // total time of build

   destructor Destroy; override;

   procedure Clear;
   function  FileIndex(const ShortName:string):Int32;
   function  Include(const StartFile:string; out Error:string):Boolean;
   function  Grab_EXTERNAL(out Error:string):Boolean;
   function  GrabDataFromLine(const F:TProjectFile; const L:PSourceLine; var Size:Int32; var S:string; out Error:string):Boolean;
   function  Grab_DATA(out Error:string):Boolean;
   function  Grab_MACRO(out Error:string):Boolean;
   function  Grab_FUNC(out Error:string):Boolean;
   function  Expand_MACRO(out Error:string):Boolean;
   function  Compile_FUNC(out Error:string):Boolean;
   function  Build(const SF:string; out Error:string):TObject;
   function  ImmediateImage:string;

  end;

 implementation

 uses SH.System, SH.Runtime;

// ************************************************************************** //
//  TBlock_Macro                                                              //
// ************************************************************************** //

 class function TBlock_Macro.FindByName(const Name:string; const M:TArray<TBlock_Macro>; out Index:Int32):Boolean;
  var i : Int32;
  begin
   Index  := -1;
   Result := false;
   if (Name='') or (M=Nil) then Exit;
   for i:=0 to High(M) do
    if M[i].Name = Name then
     begin
      Index := i;
      Exit(true);
     end;
  end;

 procedure TBlock_Macro.Clear;
  begin
   FN   := '';
   Name := '';
   Args := Nil;
   Text := Nil;
  end;

 // suppose that SL.Head point to "MACRO" & SL.Tail point to "END"
 function TBlock_Macro.Parse(const FileName:string; const SL:TSourceLines; var M:TArray<TBlock_Macro>; out Error:string):Boolean;
  var
   i : Int32;
   L : PSourceLine;
  begin
   Result := false;
   Error  := '';
   // is empty SL ? ...........................................................
   if SL.Head=Nil then
    begin
     Error := 'Cannot parse macro due source lines is empty';
     Exit;
    end;
   // is "MACRO" keyword exists ? .............................................
   L := SL.Head;
   if L.Toks[0].STR<>'MACRO' then
    begin
     Error := Format('Line %d : "MACRO" keyword is missing',[L.ID]);
     Exit;
    end;
   // is macro name exists ? ..................................................
   if L.Toks.Count<2 then
    begin
     Error := Format('Line %d : macro must have a name',[L.ID]);
     Exit;
    end;
   // is macro name has correct prefix ? ......................................
   if L.Toks[1].TYP<>TOK_MACRO then
    begin
     Error := Format('Line %d : macro name must have "_" prefix',[L.ID]);
     Exit;
    end;
   // macro name is unique ? ..................................................
   if TBlock_Macro.FindByName(L.Toks[1].STR,M,i) then
    begin
     Error := Format('Line %d : macro "%s" already exists',[L.ID,L.Toks[1].STR]);
     Exit;
    end;
   // is macro empty ? ........................................................
   if SL.Count<3 then
    begin
     Error := Format('Line %d : macro "%s" is empty',[L.ID,L.Toks[1].STR]);
     Exit;
    end;
   // is "END" keyword exists ? ...............................................
   L := SL.Tail;
   if L.Toks[0].STR<>'END' then
    begin
     Error := Format('Line %d : "END" keyword is missing',[L.ID]);
     Exit;
    end;
   // init new macro ..........................................................
   L    := SL.Head;
   Name := L.Toks[1].STR;
   FN   := FileName;
   for i:=1 to L.Toks.Count-1 do Args := Args + [L.Toks[i].STR];
   L := L.Next;
   repeat
    Text := Text + [L.Text];
    L := L.Next;
   until (L=Nil) or (L=SL.Tail);
   M := M + [self];
   Result := true;
  end;

 // "?" used to remove this argument from expanded text
 function TBlock_Macro.Expand(const CArgs:PSourceLine; const M:TArray<TBlock_Macro>; out SL:TSourceLines; out Error:string):Boolean;
  var
   i,j : Int32;
   s   : string;
   L   : TSourceLine;
  begin
   SL.Clear;
   Result := false;
   Error  := '';
   // check argiments count ...................................................
   if CArgs.Toks.Count <> Length(Args) then
    begin
     Error := Format('File "%s", expand macro "%s": arguments count mismatch',[FN,Name]);
     Exit;
    end;
   // replace arguments .......................................................
   for i:=0 to High(Text) do
    begin
     s := Text[i];
     for j:=1 to High(Args) do
      if CArgs.Toks[j].STR<>'?'
       then s := AnsiReplaceStr(s,Args[j],CArgs.Toks[j].STR)
       else s := AnsiReplaceStr(s,Args[j],'');
     if not L.Parse(s,Error,true) then
      begin
       Error := Format('File "%s", expand macro "%s": cannot parse line "%s" (%s)',[FN,Name,s,Error]);
       SL.Free;
       Exit;
      end;
     SL.Add(L); { <<< alloc memory for new source line ! }
    end;
   Result := true;
  end;

 function TBlock_Macro.ExpandEx(const CArgs:PSourceLine; const M:TArray<TBlock_Macro>; out SL:TSourceLines; out Error:string):Boolean;//  var
  var
   i   : Int32;
   K   : UInt16;
   F   : Boolean; // flag, true - need expand
   P,A : PSourceLine;
   NSL : TSourceLines;
  begin
   SL.Clear;
   Result := false;
   Error  := '';
   // try to expand base ......................................................
   if not Expand(CArgs,M,SL,Error) then Exit;
   // expand nested macros ....................................................
   K := MaxExpandPass;
   F := true;
   // do passes until new lines appear, but no more than MaxExpandLoop
   while F and (K>0) do
    begin
     F := false;
     A := SL.Head;
     repeat
      // look for nested macro used
      A := SL.LookByTokType(A,0,TOK_MACRO);
      // process nested macro
      if A<>Nil then
       begin
        // is macro exists ?
        if not TBlock_Macro.FindByName(A.Toks[0].STR,M,i) then
         begin
          Error := Format('File "%s", expand macro "%s": nested macro "%s" not found',[FN,Name,A.Toks[0].STR]);
          SL.Free;
          Exit;
         end;
        // try expand nested macro
        if not M[i].Expand(A,M,NSL,Error) then
         begin
          Error := Format('Expand macro "%s": cannot expand nested macro "%s" (%s)',[Name,A.Toks[0].STR,Error]);
          SL.Free;
          NSL.Free;
          Exit;
         end;
        P := A.Next;
        SL.Replace(A,NSL);
        Dispose(A);
        A := P;
        F := true; // we got some new lines, so we need to check them again for nested macros
       end;
     until A=Nil;
     Dec(K);
    end;
   // check if nested macro call still present
   A := SL.LookByTokType(A,0,TOK_MACRO);
   if A<>Nil then
    begin
     Error := Format('Expand macro "%s": nested macro "%s" is looped',[Name,A.Toks[0].STR]);
     SL.Free;
     Exit;
    end;
   Result := true;
  end;

 function TBlock_Macro.ToList(const IncludeHeader,LineNumbers:Boolean):TStringList;
  var
   i : Int32;
   s : string;
  begin
   Result := TStringList.Create;
   if IncludeHeader then
    begin
     s := Format('macro %s : ',[Name]);
     for i:=1 to High(Args) do s := s + Args[i] + ' ';
     Result.Add(s);
    end;
   for i:=0 to High(Text) do
    if LineNumbers
     then Result.Add(Format('%4d| %s',[i,Text[i]]))
     else Result.Add(Text[i]);
  end;

 procedure TBlock_Macro.Print(const IncludeHeader,LineNumbers:Boolean);
  var
   i : Int32;
   s : TStringList;
  begin
   try
    s := ToList(IncludeHeader,LineNumbers);
    for i:=0 to s.Count-1 do WriteLn(s[i]);
   finally
    s.Free;
   end;
  end;

// ************************************************************************** //
//  TBlock_Func                                                               //
// ************************************************************************** //

 class function TBlock_Func.FindByName(const Name:string; const F:TArray<TBlock_Func>; out Index:Int32):Boolean;
  var i : Int32;
  begin
   Index  := -1;
   Result := false;
   if (Name='') or (F=Nil) then Exit;
   for i:=0 to High(F) do
    if F[i].Name = Name then
     begin
      Index := i;
      Exit(true);
     end;
  end;

 function TBlock_Func.FindLabel(const Name:string):Int32;
  var i : Int32;
  begin
   Result := -1;
   if (Name='') or (Lab=Nil) then Exit;
   for i:=0 to High(Lab) do if Lab[i].Name = Name then Exit(i);
  end;

 procedure TBlock_Func.Clear;
  begin
   FN   := '';
   Name := '';
   Lab  := Nil;
   Code := Nil;
   ID   := -1;
   Lcnt := 0;
   Scnt := 0;
   Text.Free;
  end;

 // func header must be in SL.Items[0] and looks like:
 // <func keyword> <func name> <local:size> <stack:size>
 // FUNC           Foo         local:4      stack:8
 function TBlock_Func.Parse(const FileName:string; const SL:TSourceLines; var F:TArray<TBlock_Func>; out Error:string):Boolean;
  var
   i : Int32;
   s : string;
   L : PSourceLine;
  begin
   Result := false;
   Error  := '';
   // is source lines empty ? .................................................
   if SL.Empty then
    begin
     Error := 'Cannot parse function due source lines is empty';
     Exit;
    end;
   // is func name & params exists ? ..........................................
   L := SL.Head;
   if L.Toks.Count<4 then
    begin
     Error := Format('Line %d : Function header must have at least 4 tokens',[L.ID]);
     Exit;
    end;
   // is "FUNC" keyword exists ? ..............................................
   if L.Toks.Items[0].STR<>'FUNC' then
    begin
     Error := Format('Line %d : "FUNC" keyword is missing',[L.ID]);
     Exit;
    end;
   // is func name correct ? ..................................................
   if L.Toks.Items[1].TYP<>TOK_IDENT then
    begin
     Error := Format('Line %d : Function name must be an identifier',[L.ID]);
     Exit;
    end;
   // func name is unique ? ...................................................
   if TBlock_Func.FindByName(L.Toks[1].STR,F,ID) then
    begin
     Error := Format('Line %d : function "%s" already exists',[L.ID,L.Toks[1].STR]);
     Exit;
    end;
   // init function name from L.Items[1] ......................................
   Name := L.Toks[1].STR;
   // try init Lcnt ...........................................................
   s := L.Toks[2].STR;
   s := RightStr(s,Length(s)-Pos(':',s)); // extract all after ":"
   if not TryStrToInt(s,i) then
    begin
     Error := Format('Line %d : Function "%s" has invalid local size',[L.ID,Name]);
     Exit;
    end;
   Lcnt := i;
   // try init Scnt ...........................................................
   s := L.Toks[3].STR;
   s := RightStr(s,Length(s)-Pos(':',s)); // extract all after ":"
   if not TryStrToInt(s,i) then
    begin
     Error := Format('Line %d : Function "%s" has invalid stack size',[L.ID,Name]);
     Exit;
    end;
   Scnt := i;
   {$IFNDEF STATIC_FRAME_DATA}
   if Lcnt+Scnt > MaxFrameData then
    begin
     Error := Format('Line %d : Function "%s" local+stack size too large',[L.ID,Name]);
     Exit;
    end;
   {$ENDIF}
   // is function body empty ? ................................................
   if SL.Count<3 then
    begin
     Error := Format('Line %d : function "%s" is empty',[L.ID,Name]);
     Exit;
    end;
   // is "END" keyword exists ? ...............................................
   L := SL.Tail;
   if L.Toks[0].STR<>'END' then
    begin
     Error := Format('Line %d : "END" keyword is missing',[L.ID]);
     Exit;
    end;
   // init function (take source lines as responsible owner !!!)...............
   ID   := Length(F);
   FN   := FileName;
   Text := SL;
   // cut first & last source line ............................................
   L := Text.Head;
   Text.Extract(L);
   Dispose(L);
   L := Text.Tail;
   Text.Extract(L);
   Dispose(L);
   // add function to list ....................................................
   F      := F + [self];
   Result := true;
  end;

 function TBlock_Func.FunNamesToIndexes(const F:TArray<TBlock_Func>; out Error:string):Boolean;
 var
  i     : Int32;
  fcall : PSourceLine;
 begin
  Result := true;
  Error  := '';
  if (F=Nil) or Text.Empty then Exit;
  //
  fcall := Text.Head;
  while true do
   begin
    fcall := Text.LookByTokName(fcall,0,'CALL');
    if fcall=Nil then Exit;
    // call argument - omitted, global name or function index ?
    if (fcall.Toks.Count=1) or (fcall.Toks[1].TYP = TOK_GNAME) or (fcall.Toks[1].TYP = TOK_FIDX) then
     begin
      fcall := fcall.Next;
      continue;
     end;
    // function name is identifier ?
    if fcall.Toks[1].TYP <> TOK_IDENT then
     begin
      Error  := Format('Function "%s" : call argument must be function name',[Name]);
      Result := false;
      Exit;
     end;
    // is func exists ?
    if not TBlock_Func.FindByName(fcall.Toks[1].STR,F,i) then
     begin
      Error  := Format('Function "%s" : user function "%s" not found',[Name,fcall.Toks[1].STR]);
      Result := false;
      Exit;
     end;
    // replace name to index
    fcall.Toks.Items[1].STR  := Format('.F%d',[i]);
    fcall.Toks.Items[1].TYP  := TOK_FIDX;
    fcall.Toks.Items[1].VAL.i8 := i;
    fcall.ResetText();
    //
    fcall := fcall.Next;
   end;
 end;

 function TBlock_Func.LabNamesToIndexes(out Error:string):Boolean;
  var
   i,k  : Int32;
   item : PSourceLine;
   sl   : TSourceLines;
   LB   : TLabel;
  begin
   Result := true;
   Error  := '';
   if Text.Empty then Exit;
   // collecting labels; if nothing found then exit ...........................
   Lab  := Nil;
   item := Text.Head;
   i    := 0;
   repeat
    if item.Toks[0].TYP = TOK_LABEL then
     begin
      if item=Text.Tail then
       begin
        Error  := Format('Function "%s" : no code after label "%s"',[Name,item.Toks[0].STR]);
        Result := false;
        Exit;
       end;
      LB.Name := item.Toks[0].STR;
      LB.Line := i - Length(Lab);
      Lab     := Lab + [LB];
     end;
    Inc(i);
    item := item.Next;
   until item=Nil;
   if Lab=Nil then Exit;
   // extract & free all source lines with labels .............................
   Text.Extract(function (const P:PSourceLine):Boolean
    begin
     Exit((P.Toks[0].TYP=TOK_LABEL))
    end).Free;
   // if some code lines exists after removing labels ? .......................
   if Text.Empty then
    begin
     Error  := Format('Function "%s" : empty code after labels removed',[Name]);
     Result := false;
     Exit;
    end;
   // label names replace to indexes ..........................................
   item := Text.Head;
   while true do
    begin
     // try to find next label + its position in source line
     k    := -1;
     item := Text.Look(item,function (const P:PSourceLine):Boolean
      begin
       if P.Toks.Count>1 then
        begin
         if StrInList(P.Toks[0].STR,['JZ','JNZ','JLZ','JGZ','JUMP']) then k := 1;
         if StrInList(P.Toks[0].STR,['JN']) then k := 3;
        end;
       Exit(k <> -1);
      end);
     // if no more labels then break loop
     if item=Nil then break;
     // is label exists ?
     i := FindLabel(item.Toks[k].STR);
     if i = -1 then
      begin
       Error  := Format('Function "%s" : label "%s" not found',[Name,item.Toks[k].STR]);
       Result := false;
       Exit;
      end;
     // replace label name to index
     item.Toks.Items[k].STR  := IntToStr(Lab[i].Line);
     item.Toks.Items[k].TYP  := TOK_INT;
     item.Toks.Items[k].VAL.i8 := Lab[i].Line;
     item.ResetText();
     // advance to next label
     item := item.Next;
    end;
  end;

 function TBlock_Func.Compile(out Error:string):Boolean;
  var
   i    : Int32;
   item : PSourceLine;
   CMD  : TCommand;
  begin
   Result := false;
   Error  := '';
   //
   if Text.Empty then
    begin
     Error := 'Cannot compile function due source lines is empty';
     Exit;
    end;
   //
   i := 0;
   item := Text.Head;
   repeat
    if not item.Encode(CMD,Error) then
     begin
      Error := Format('Function "%s" : Line %d: %s',[Name,i,Error]);
      Code  := Nil;
      Exit;
     end;
    Code := Code + [CMD];
    Inc(i);
    item := item.Next;
   until item=Nil;
   //
   Result := true;
  end;

 function TBlock_Func.ToList(const Ident:Int32; const IncludeHeader,LineNumbers:Boolean):TStringList;
  begin
   Result := Text.ToList(Ident,LineNumbers);
   if IncludeHeader then Result.Insert(0,Format('func[%d] %s LOCAL:%d STACK:%d',[ID,Name,Lcnt,Scnt]));
  end;

 procedure TBlock_Func.Print(const Ident:Int32; const IncludeHeader,LineNumbers:Boolean);
  var
   i : Int32;
   s : TStringList;
  begin
   try
    s := ToList(Ident,IncludeHeader,LineNumbers);
    for i:=0 to s.Count-1 do WriteLn(s[i]);
   finally
    s.Free;
   end;
  end;

// ************************************************************************** //
//  TProjectFile                                                              //
// ************************************************************************** //

 procedure TProjectFile.Clear;
  begin
   SL.Free;
   ShortName  := '';
   FullName   := '';
   LineCount  := 0;
   DataCount  := 0;
   MacroCount := 0;
   FuncCount  := 0;
   Unparsed   := 0;
   Immediate  := false;
  end;

 function TProjectFile.LoadFile(const FN,SN,DN:string; out Error:string):Boolean;
  var data : TSourceLines;
  begin
   FullName  := FN;
   ShortName := SN;
   DecorName := DN;
   LineCount := SL.Load(FN,Error);
   if Error<>'' then
    begin
     Error := Format('File "%s", %s',[ShortName,Error]);
     Exit(false);
    end;
   // check "IMMEDIATE" keyword ................................................
   try
    data := SL.Extract(function (const P:PSourceLine):Boolean
     begin
      Exit((P.Toks[0].STR='IMMEDIATE'))
     end);
    Immediate := not data.Empty;
   finally
    data.Free;
   end;
   // if file is in "immediate" mode then force to remove all "INCLUDE" ........
   if Immediate then
    try
     data := SL.Extract(function (const P:PSourceLine):Boolean
      begin
       Exit((P.Toks[0].STR='INCLUDE'))
      end);
    finally
     data.Free;
    end;
   Exit(true);
  end;

// ************************************************************************** //
//  TProject                                                                  //
// ************************************************************************** //

 destructor TProject.Destroy;
  begin
   Clear();
   inherited Destroy;
  end;

 procedure TProject.Clear;
  var i : Int32;
  begin
   // clear all stages
   Status[stage_INCLUDE  ] := false;
   Status[stage_IMPORT   ] := false;
   Status[stage_GETDATA  ] := false;
   Status[stage_GETMACROS] := false;
   Status[stage_EXPMACROS] := false;
   Status[stage_GETFUNCS ] := false;
   Status[stage_COMPILE  ] := false;
   Status[stage_BUILD    ] := false;
   // release memory
   for i:=0 to High(Files) do Files[i].Clear;
   for i:=0 to High(M) do M[i].Clear;
   for i:=0 to High(F) do F[i].Clear;
   for i:=0 to High(EXT) do EXT[i] := '';
   for i:=0 to High(DAT) do DAT[i] := '';
   Files := Nil;
   M     := Nil;
   F     := Nil;
   EXT   := Nil;
   DAT   := Nil;
   REP   := '';
  end;

 function TProject.FileIndex(const ShortName:string):Int32;
  var i : Int32;
  begin
   Result := -1;
   for i:=0 to High(Files) do
    if Files[i].ShortName=ShortName then Exit(i);
  end;

 function TProject.Include(const StartFile:string; out Error:string):Boolean;
  var
   F       : TProjectFile;
   K       : Int32;
   s1,s2,s3: string;
   item    : PSourceLine;
   Inserts : TSourceLines;
  begin
   Result := false;
   Error  := '';
   Inserts.Clear;
   if not FileExists(StartFile) then
    begin
     Error := Format('Start file "%s" not found',[StartFile]);
     Exit;
    end;
   //
   REP := Format('Start build "%s" at %s'#13#10,[StartFile,FormatDateTime('hh:nn:ss:zzz',Now)]);
   s1 := UpperCase(ExpandFileName(StartFile));
   s2 := ExtractFileName(s1);
   s3 := System.IOUtils.TPath.GetFileNameWithoutExtension(s2);
   if not F.LoadFile(s1,s2,s3,Error)
    then Exit
    else Files := Files + [F];
   //
   K := 0;
   while true do
    try
     Inserts := Files[K].SL.Extract(function (const P:PSourceLine):Boolean
      begin
       Exit((P.Toks[0].STR='INCLUDE'))
      end);
     if not Inserts.Empty then
      begin
       item := Inserts.Head;
       repeat
        // is exists included file name ?
        if item.Toks.Count<2 then
         begin
          Error := Format('File "%s", Line %d: missing name of the included file',[F.ShortName,item.ID]);
          Exit;
         end;
        // is exists included file ?
        s1 := MidStr(item.Toks[1].STR,2,Length(item.Toks[1].STR)-2); // cut quotes
        s1 := UpperCase(ExpandFileName(s1));
        s2 := ExtractFileName(s1);
        s3 := System.IOUtils.TPath.GetFileNameWithoutExtension(s2);
        if not FileExists(s1) then
         begin
          Error := Format('File "%s", Line %d: included file %s not found',[F.ShortName,item.ID,item.Toks[1].STR]);
          Exit;
         end;
        // is file already included ?
        if FileIndex(s2) = -1 then
         if not F.LoadFile(s1,s2,s3,Error)
          then Exit
          else Files := Files + [F];
        // advance to next line
        item := item.Next;
       until item=Nil;
      end;
     Inc(K);
     if K>High(Files) then break;
    finally
     Inserts.Free;
    end;
   //
   Result := true;
   REP := REP + Format(#13#10'%d file(s) successfully included in project'#13#10,[Length(Files)]);
  end;

 function TProject.Grab_EXTERNAL(out Error:string):Boolean;
  var
   i     : Int32;
   item  : PSourceLine;
   data  : TSourceLines;
   S,m,f : string;
   ef    : TExternalFile;
  begin
   Error := '';
   S     := '';
   for i:=0 to High(Files) do
    try
     // for Files[i] try to extract all source lines with "EXTERNAL" ...........
     data := Files[i].SL.Extract(function (const P:PSourceLine):Boolean
      begin
       Exit((P.Toks[0].STR='EXTERNAL'))
      end);
     // process each line ......................................................
     if data.Empty then continue;
     item := data.Head;
     repeat
      if (item.Toks.Count<2) or
         (item.Toks[1].TYP<>TOK_STRING) then
       begin
        Error := Format('File "%s", Line %d : invalid "EXTERNAL" statement',[Files[i].ShortName,item.ID]);
        Exit(false);
       end;
      m := item.Toks[1].STR;
      m := MidStr(m,2,Length(m)-2);
      if (item.Toks.Count=2) then
       begin
        if not Externals.ImportAllSymbols(m,Error) then Exit(false);
        ef := Externals.Items[Externals.ModuleIndex(m)];
        S := S + Format(' %d symbols imported from %s'#13#10,[Length(ef.Items),m]);
       end
      else
       begin
        f := item.Toks[2].STR;
        f := MidStr(f,2,Length(f)-2);
        if not Externals.ImportSymbol(m,f,Error) then Exit(false);
        S := S + Format(' %s imported from %s'#13#10,[f,m]);
       end;
      EXT := EXT + [item.Text];
      item := item.Next;
     until item=Nil;
    finally
     data.Free;
    end;
   // report
   REP := REP + Format(#13#10' ******** Externals (%d) ********'#13#10,[Externals.SymCount]);
   if S<>'' then REP := REP + #13#10 + S;
   Exit(true);
  end;

 // token 0 : <data keyword>
 // token 1 : <data name>
 // token 2 : <type>
 // token 3 : <value> | <reserved size>
 function TProject.GrabDataFromLine(const F:TProjectFile; const L:PSourceLine; var Size:Int32; var S:string; out Error:string):Boolean;
  var
   num,i : Int32;
   nam   : AnsiString;
   D     : TData;
  begin
   // not enough tokens in line ? ..............................................
   if L.Toks.Count<4 then
    begin
     Error := Format('File "%s", Line %d : invalid "DATA" statement',[F.ShortName,L.ID]);
     Exit(false);
    end;
   // global name already exists ...............................................
   if L.Toks[1].TYP = TOK_IDENT then nam := '%' + F.DecorName + ':' + L.Toks[1].STR else
   if L.Toks[1].TYP = TOK_GNAME then nam := L.Toks[1].STR else
    begin
     Error := Format('File "%s", Line %d : External symbol "%s" - invalid name',[F.ShortName,L.ID,nam]);
     Exit(false);
    end;
   if GloNames.ContainsKey(nam) then
    begin
     Error := Format('File "%s", Line %d : External symbol "%s" already exists',[F.ShortName,L.ID,nam]);
     Exit(false);
    end;
   // integer ? ................................................................
   D.Clear();
   num := Length(Globals);
   if (L.Toks[2].STR='INT') and (L.Toks[3].TYP=TOK_INT) then
    begin
     D := L.Toks[3].VAL;
     S := S + Format('%4d %6s %-25s %4d bytes %s'#13#10,[num,'INT',nam,SizeOf(TData),D.i8.ToString]);
     Inc(Size,SizeOf(TData));
    end else
   // float ? ..................................................................
   if (L.Toks[2].STR='FLT') and (L.Toks[3].TYP=TOK_FLOAT) then
    begin
     D := L.Toks[3].VAL;
     S := S + Format('%4d %6s %-25s %4d bytes %s'#13#10,[num,'FLOAT',nam,SizeOf(TData),D.r8.ToString]);
     Inc(Size,SizeOf(TData));
    end else
   // string ? .................................................................
   if (L.Toks[2].STR='STR') and (L.Toks[3].TYP=TOK_STRING) then
    begin
     if not Alloc_String(PrepareString(L.Toks[3].STR),D) then
      begin
       Error := Format('File "%s", Line %d : Can not allocate string for global data',[F.ShortName,L.ID]);
       Exit(false);
      end;
     S := S + Format('%4d %6s %-25s %4d bytes %s'#13#10,[num,'STRING',nam,SizeOf(TData) + D.StrLen,L.Toks[3].STR]);
     Inc(Size,SizeOf(TData) + D.StrLen);
    end else
   // initialized stream ? .....................................................
   if (L.Toks[2].STR='BIN') and (L.Toks[3].TYP=TOK_BINARY) then
    begin
     if not Alloc_Stream(L.Toks[3].STR,D) then
      begin
       Error := Format('File "%s", Line %d : Can not allocate stream for global data',[F.ShortName,L.ID]);
       Exit(false);
      end;
     S := S + Format('%4d %6s %-25s %4d bytes initialized'#13#10,[num,'BINARY',nam,SizeOf(TData) + D.Size]);
     Inc(Size,SizeOf(TData) + D.Size);
    end else
   // zero-initialized array ? .................................................
   if (L.Toks[2].STR='ARR') and (L.Toks[3].TYP=TOK_INT) then
    begin
     if not Alloc_Stream(L.Toks[3].VAL.i8,D) then
      begin
       Error  := Format('File "%s", Line %d : Can not allocate stream for global data',[F.ShortName,L.ID]);
       Exit(false);
      end;
     S := S + Format('%4d %6s %-25s %4d bytes reserved'#13#10,[num,'BINARY',nam,SizeOf(TData) + D.Size]);
     Inc(Size,SizeOf(TData) + D.Size);
    end else
   // no country for old men ! .................................................
   begin
    Error := Format('File "%s", Line %d : invalid "DATA" statement',[F.ShortName,L.ID]);
    Exit(false);
   end;
   //
   L.Toks.Items[1].STR := nam;
   L.ResetText();
   DAT     := DAT + [L.Text];
   Globals := Globals + [D];
   GloNames.Add(nam,High(Globals));
   Exit(true);
  end;

 function TProject.Grab_DATA(out Error:string):Boolean;
  var
   i     : Int32;
   alloc : Int32;
   item  : PSourceLine;
   data  : TSourceLines;
   S     : string;
  begin
   Error := '';
   alloc := 0;
   S     := '';
   for i:=0 to High(Files) do
    try
     // for Files[i] try to extract all source lines with "DATA" ...............
     Files[i].DataCount := 0;
     Files[i].SL.ShiftGlobals(Length(Globals));
     data := Files[i].SL.Extract(function (const P:PSourceLine):Boolean
      begin
       Exit((P.Toks[0].STR='DATA'))
      end);
     // process each line ......................................................
     if data.Empty then continue;
     item := data.Head;
     repeat
      if not GrabDataFromLine(Files[i],item,alloc,S,Error) then Exit(false);
      Inc(Files[i].DataCount);
      item := item.Next;
     until item=Nil;
    finally
     data.Free;
    end;
   // report
   REP := REP + Format(#13#10' ******** Global data (%d) ********'#13#10,[Length(Globals)]);
   if S<>'' then REP := REP + #13#10 + S;
   REP := REP + Format(#13#10'Total %d bytes allocated'#13#10,[alloc]);
   Exit(true);
  end;

 function TProject.Grab_MACRO(out Error:string):Boolean;
  var
   i,j        : Int32;
   s          : string;
   s1,s2      : PSourceLine;
   macrolines : TSourceLines;
   macro      : TBlock_Macro;
  begin
   Result := true;
   Error  := '';
   macrolines.Clear;
   for i:=0 to High(Files) do if not Files[i].Immediate then
    begin
     Files[i].MacroCount := 0;
     while true do
      try
       // try to extract macro
       s1 := Files[i].SL.LookByTokName(Nil,0,'MACRO');
       // if no more macro then go to next file
       if s1=Nil then break;
       s2 := Files[i].SL.Look(s1.Next,
         function (const P:PSourceLine):Boolean
          begin
           Exit((P.Toks.Count>=2) and (P.Toks[0].STR='END') and (P.Toks[1].STR='MACRO'))
          end);
       macrolines := Files[i].SL.Extract(s1,s2);
       // try to parse macro
       FillChar(macro,SizeOf(macro),0);
       if not macro.Parse(Files[i].ShortName,macrolines,M,Error) then
        begin
         Error  := Format('File "%s", %s',[Files[i].ShortName,Error]);
         Result := false;
         Exit;
        end
       else Inc(Files[i].MacroCount);
      finally
       macrolines.Free;
      end;
    end;
   //
   REP := REP + Format(#13#10' ******** Macros (%d) ********'#13#10#13#10,[Length(M)]);
   for i:=0 to High(M) do
    begin
     s := Format('%4d %-25s %-25s %4d lines ',[i, M[i].FN, M[i].Name, Length(M[i].Text)]);
     for j:=1 to High(M[i].Args) do s := s + M[i].Args[j] + ' ';
     REP := REP + s + #13#10;
    end;
  end;

 function TProject.Grab_FUNC(out Error:string):Boolean;
  var
   i,j       : Int32;
   s         : string;
   s1,s2     : PSourceLine;
   funclines : TSourceLines;
   func      : TBlock_Func;
  begin
   Result := true;
   Error  := '';
   funclines.Clear;
   for i:=0 to High(Files) do
    begin
     Files[i].FuncCount := 0;
     while true do
      begin
       // try to extract func
       s1 := Files[i].SL.LookByTokName(Nil,0,'FUNC');
       // if no more func then go to next file
       if s1=Nil then break;
       s2 := Files[i].SL.Look(s1.Next,
         function (const P:PSourceLine):Boolean
          begin
           Exit((P.Toks.Count>=2) and (P.Toks[0].STR='END') and (P.Toks[1].STR='FUNC'))
          end);
       funclines := Files[i].SL.Extract(s1,s2);
       // try to parse func
       FillChar(func,SizeOf(func),0);
       if not func.Parse(Files[i].ShortName,funclines,F,Error) then
        begin
         Error  := Format('File "%s", %s',[Files[i].ShortName,Error]);
         Result := false;
         Exit;
        end;
       func.Imme := Files[i].Immediate;
       Inc(Files[i].FuncCount);
      end;
    end;
   //
   for i:=0 to High(F) do if not F[i].Imme then
    begin
     if not F[i].FunNamesToIndexes(F,Error) then Exit(false);
     if not F[i].LabNamesToIndexes(Error) then Exit(false);
    end;
   //
   REP := REP + Format(#13#10' ******** Functions (%d) ********'#13#10#13#10,[Length(F)]);
   for i:=0 to High(F) do
    begin
     s := Format('%4d %-25s %-25s %4d lines; L:%-2d S:%-2d',[i, F[i].FN, F[i].Name, F[i].Text.Count, F[i].Lcnt, F[i].Scnt]);
     REP := REP + s + #13#10;
    end;
   //
   for i:=0 to High(Files) do Files[i].Unparsed := Files[i].SL.Count;
  end;

 function TProject.Expand_MACRO(out Error:string):Boolean;
  var
   i,k    : Int32;
   mcall  : PSourceLine;
   lines  : TSourceLines;
   mcnt   : Int32;
   expcnt : Int32;
  begin
   Result := true;
   Error  := '';
   mcnt   := 0;
   expcnt := 0;
   lines.Clear;
   for i:=0 to High(Files) do if not Files[i].Immediate then
    while true do
     try
      // try to extract macro call
      mcall := Files[i].SL.LookByTokType(Nil,0,TOK_MACRO);
      // if macro call not found then break loop
      if mcall=Nil then break;
      // is macro exists ?
      if not TBLock_Macro.FindByName(mcall.Toks[0].STR,M,k) then
       begin
        Error  := Format('File "%s", macro "%s" not found',[Files[i].ShortName,mcall.Toks[0].STR]);
        Result := false;
        Exit;
       end;
      // try to expand macro
      if not M[k].ExpandEx(mcall,M,lines,Error) then
       begin
        Error  := Format('File "%s", %s',[Files[i].ShortName,Error]);
        Result := false;
        lines.Free;
        Exit;
       end;
      // inject lines in source instead mcall
      Inc(mcnt);
      Inc(expcnt,lines.Count);
      Files[i].SL.Replace(mcall,lines);
     finally
      if mcall<>Nil then Dispose(mcall);
     end;
   //
   REP := REP + Format(#13#10'%d macros calls expanded to %d lines'#13#10,[mcnt,expcnt]);
  end;

 function TProject.Compile_FUNC(out Error:string):Boolean;
  var i,j : Int32;
  begin
   Result := false;
   Error  := '';
   j      := 0;
   for i:=0 to High(F) do
    begin
     if not F[i].Compile(Error) then Exit;
     Inc(j,Length(F[i].Code));
    end;
   Result := true;
   REP := REP + Format(#13#10'%d function(s) compiled successfully (%d commands total)',[Length(F),j]) + #13#10;
  end;

 // returns Result:TProgram if success, otherwise returns nil (also Error will be filled)
 function TProject.Build(const SF:string; out Error:string):TObject;
  var
   i  : Int32;
   pr : TProgram;
  begin
   // clean globals !
   Externals.FreeModules;
   GloNames.Clear();
   Globals := Nil;
   //
   Clear();
   Result := Nil;
   Error  := '';
   try
    BT.Start;
    // preprocessor
    if not Include(SF,Error)    then Exit else Status[stage_INCLUDE  ] := true;
    if not Grab_EXTERNAL(Error) then Exit else Status[stage_IMPORT   ] := true;
    if not Grab_DATA(Error)     then Exit else Status[stage_GETDATA  ] := true;
    if not Grab_MACRO(Error)    then Exit else Status[stage_GETMACROS] := true;
    if not Expand_MACRO(Error)  then Exit else Status[stage_EXPMACROS] := true;
    if not Grab_FUNC(Error)     then Exit else Status[stage_GETFUNCS ] := true;
    // compile
    if not Compile_FUNC(Error) then Exit else Status[stage_COMPILE] := true;
    // build
    pr := TProgram.Create;
    SetLength(pr.F,Length(F));
    for i:=0 to High(F) do
     begin
      FillChar(pr.F[i],SizeOf(TFrame),0);
      pr.F[i].ID   := i;
      pr.F[i].LCNT := F[i].Lcnt;
      pr.F[i].SCNT := F[i].Scnt;
      pr.F[i].USED := false;
      pr.F[i].PROG := pr;
      pr.F[i].CODE := Copy(F[i].Code);
      pr.FN.Add(F[i].Name,i);
     end;
    Result := pr;
    Status[stage_BUILD] := true;
    BT.Stop;
    //
    REP := REP + Format(#13#10'Project finished at %s (%0.2f ms total)'#13#10,[FormatDateTime('hh:nn:ss:zzz',Now),BT.Elapsed_MilliSec]);
   finally
    if Error <> '' then REP := REP + Error + #13#10;
   end;
  end;

 function TProject.ImmediateImage:string;
  var
   i   : Int32;
   ime : TStringList;
  begin
   Result := '';
   if not Status[stage_BUILD] then Exit;
   //
   ime := TStringList.Create;
   ime.Add(Format('; Original file : "%s"'#13#10,[Files[0].FullName]));
   ime.Add(' IMMEDIATE');
   if EXT<>Nil then
    begin
     ime.Add(#13#10'; EXTERNALS'#13#10);
     for i:=0 to High(EXT) do ime.Add(' ' + EXT[i]);
    end;
   if DAT<>Nil then
    begin
     ime.Add(#13#10'; GLOBAL DATA'#13#10);
     for i:=0 to High(DAT) do ime.Add(' ' + DAT[i]);
    end;
   ime.Add(#13#10'; USER FUNCTIONS'#13#10);
   for i:=0 to High(F) do
    begin
     ime.Add(Format(' ; .F%d (%d instructions)',[i,Length(F[i].Code)]));
     ime.Add(Format(' FUNC %s LOCAL:%d STACK:%d',[F[i].Name,F[i].Lcnt,F[i].Scnt]));
     ime.AddStrings(F[i].ToList(2,false,false));
     ime.Add(' END FUNC'#13#10);
    end;
   Result := ime.Text;
   ime.Free;
  end;

end.
