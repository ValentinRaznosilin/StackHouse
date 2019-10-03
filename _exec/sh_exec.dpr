{******************************************************************************}
{* Project : "StackHouse" virtual stack-machine                               *}
{* Program : Code executor                                                    *}
{* Change  : 03.10.2019 (84 lines)                                            *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2019 DelphiRunner                                            *}
{******************************************************************************}

program sh_exec;

 {$APPTYPE CONSOLE}

 {$R *.res}

 uses
  // system
  System.SysUtils,
  System.Classes,
  // lib32
  lib32.Init      in '..\lib32\lib32.Init.pas',
  lib32.Common    in '..\lib32\lib32.Common.pas',
  lib32.Func.Core in '..\lib32\lib32.Func.Core.pas',
  lib32.Func.Impl in '..\lib32\lib32.Func.Impl.pas',
  lib32.Util.Bits in '..\lib32\lib32.Util.Bits.pas',
  lib32.Log       in '..\lib32\lib32.Log.pas',
  lib32.Time      in '..\lib32\lib32.Time.pas',
  // json
  superdate       in '..\json\superdate.pas',
  superobject     in '..\json\superobject.pas',
  supertimezone   in '..\json\supertimezone.pas',
  supertypes      in '..\json\supertypes.pas',
  superxmlparser  in '..\json\superxmlparser.pas',
  // project
  SH.Codes        in '..\core\SH.Codes.pas',
  SH.Types        in '..\core\SH.Types.pas',
  SH.Utils        in '..\core\SH.Utils.pas',
  SH.Parser.Base  in '..\core\SH.Parser.Base.pas',
  SH.Parser       in '..\core\SH.Parser.pas',
  SH.Runtime      in '..\core\SH.Runtime.pas',
  SH.System       in '..\core\SH.System.pas',
  SH.Executor     in '..\core\SH.Executor.pas';

 const PressEnterPrompt = 'Press <enter> to continue...';

 var Exec : TExecutor = Nil;

 begin

  try

   if ParamCount>0 then
    begin
     Exec := TExecutor.Create;
     Exec.Execute(ParamStr(1));
     //
     if Exec.ExitCode in [EID_FileNotFound, EID_InvalidConfig, EID_BuildFailed] then
      begin
       WriteLn(Exec.Error);
       WriteLn(PressEnterPrompt);
       ReadLn;
       Exit;
      end;
     //
     Write(#13#10'Program executed at ');
     if Exec.ExecTime.Elapsed_Sec < 1.0
      then WriteLn(Format('%0.6f ms',[Exec.ExecTime.Elapsed_MilliSec]))
      else WriteLn(Format('%0.3f s', [Exec.ExecTime.Elapsed_Sec     ]));
     //
     WriteLn(Format('Exit code %d (%s)',[Exec.ExitCode,Exec.Error]));
     if Exec.PressAnyKey then
      begin
       WriteLn(PressEnterPrompt);
       ReadLn;
      end;
     Exec.Free;
    end;

  except
   on E: Exception do
    begin
     Writeln(Format('%s: %s',[E.ClassName,E.Message]));
     WriteLn(PressEnterPrompt);
     ReadLn;
    end;
  end;

 end.
