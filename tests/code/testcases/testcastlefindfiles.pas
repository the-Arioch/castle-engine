// -*- compile-command: "./test_single_testcase.sh TTestCastleFindFiles" -*-
{
  Copyright 2021-2022 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Test CastleFindFiles unit. }
unit TestCastleFindFiles;

{$ifdef FPC}{$mode objfpc}{$H+}{$endif}

interface

uses
  Classes, SysUtils, {$ifndef CASTLE_TESTER}FpcUnit, TestUtils, TestRegistry,
  CastleTestCase{$else}CastleTester{$endif};

type
  TTestCastleFindFiles = class(TCastleTestCase)
  published
    procedure TestNilHandler;
  end;

implementation

uses CastleFindFiles;

procedure TTestCastleFindFiles.TestNilHandler;
begin
  AssertEquals(4, FindFiles('castle-data:/designs_to_count_files/', '*.castle-user-interface', false, nil, [ffRecursive]));
end;

initialization
  RegisterTest(TTestCastleFindFiles);
end.
