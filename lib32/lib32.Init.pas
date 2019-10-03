{******************************************************************************}
{* Program : lib32 Library                                                    *}
{* Unit    : Library initialization/Finalization                              *}
{* Change  : 12.12.2012 (36 lines)                                            *}
{* Comment :                                                                  *}
{*                                                                            *}
{* Copyright (c) 2011-2012 Raznosilin V.V.                                    *}
{******************************************************************************}


 unit lib32.Init;

 interface

 implementation

 uses

  // library
  lib32.Time, lib32.Util.Bits, lib32.Func.Core, lib32.Func.Impl;

 initialization

  lib32.Time.Initialize;
  lib32.Util.Bits.Initialize;
  lib32.Func.Core.Initialize;
  lib32.Func.Impl.Initialize;

 finalization

  lib32.Func.Impl.Finalize;
  lib32.Func.Core.Finalize;
  lib32.Util.Bits.Finalize;
  lib32.Time.Finalize;

end.
