{******************************************************************************}
{* Project : "StackHouse" virtual stack-machine                               *}
{* Unit    : Run program from configuration file                              *}
{* Change  : 03.10.2019 (145 lines)                                           *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2019 DelphiRunner                                            *}
{******************************************************************************}

unit SH.Executor;

 interface

 uses
  // system
  System.IOUtils,
  System.SysUtils,
  System.Classes,
  // json
  superobject,
  // lib32
  lib32.Time,
  // project
  SH.Codes,
  SH.Types,
  SH.Parser,
  SH.Runtime,
  SH.System;

 type

  // executor ******************************************************************
  TExecutor = class(TObject)

   // configuration info
   Conf : ISuperObject;
   // configuration fields
   Args        : TArray<AnsiString>;
   ProjFile    : string;
   ImeFile     : string;
   RepFile     : string;
   ExecFunc    : string;
   PressAnyKey : Boolean;
   // project & program
   Proj        : TProject;
   Prog        : TProgram;
   ExecTime    : TStopWatch;
   ExitCode    : Int32;
   Error       : string;

   constructor Create;
   destructor  Destroy; override;

   procedure Execute(const ConfigFile:string);

  end;

 implementation

// ************************************************************************** //
//  TExecutor                                                                 //
// ************************************************************************** //

 constructor TExecutor.Create;
  begin
   inherited Create;
   Args        := Nil;
   ProjFile    := '';
   ImeFile     := '';
   RepFile     := '';
   ExecFunc    := '';
   Error       := '';
   PressAnyKey := false;
   Proj        := Nil;
   Prog        := Nil;
   ExitCode    := EID_UNKNOWN;
   ExecTime.Reset();
  end;

 destructor TExecutor.Destroy;
  begin
   Args := Nil;
   Conf := Nil;
   FreeAndNil(Proj);
   FreeAndNil(Prog);
   inherited Destroy;
  end;

 procedure TExecutor.Execute(const ConfigFile:string);
  var
   cfgstr : string;
   i      : Int32;
   sa     : TSuperArray;
  begin
   // check configuration file .................................................
   if not FileExists(ConfigFile) then
    begin
     Error    := Format('Config file "%s" not found',[ConfigFile]);
     ExitCode := EID_FileNotFound;
     Exit;
    end;
   // try to load configuration ................................................
   cfgstr := TFile.ReadAllText(ConfigFile);
   try
    Conf := SO(cfgstr);
    sa := Conf['args'].AsArray;
    for i:=0 to sa.Length-1 do Args := Args + [sa[i].AsString];
    ProjFile    := Conf['project'    ].AsString;
    ImeFile     := Conf['immediate'  ].AsString;
    RepFile     := Conf['report'     ].AsString;
    ExecFunc    := Conf['execute'    ].AsString;
    PressAnyKey := Conf['pressanykey'].AsBoolean;
   except
    Error    := Format('Config file "%s" is invalid',[ConfigFile]);
    ExitCode := EID_InvalidConfig;
    Exit;
   end;
   // try to build project .....................................................
   FormatSettings.DecimalSeparator := '.';
   Proj := TProject.Create;
   Prog := TProgram(Proj.Build(ProjFile,Error));
   if Prog=Nil then
    begin
     ExitCode := EID_BuildFailed;
     Exit;
    end;
   // save reports .............................................................
   if ImeFile<>'' then TFile.WriteAllText(ImeFile,Proj.ImmediateImage);
   if RepFile<>'' then TFile.WriteAllText(RepFile,Proj.REP           );
   // try to execute program ...................................................
   ExecTime.Start();
   ExitCode := Prog.Execute(ExecFunc,Args);
   ExecTime.Stop();
   // convert ExitCode to string ...............................................
   case ExitCode of
    EID_UNKNOWN             : Error := 'unknown';
    EID_RET                 : Error := 'ret';
    EID_HALT                : Error := 'halt';
    EID_InstanceAlreadyUsed : Error := 'instance already used';
    EID_FunctionNotFound    : Error := 'function not found';
    else Error := '';
   end;
  end;

end.
