{ -*- buffer-read-only: t -*-

  Copyright 2015-2023 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Automatically generated node properties.

  Do not edit this file manually!
  To add new properties:
  - add them to the text files in tools/internal/x3d-nodes-to-pascal/nodes-specification/ ,
  - and regenerate include files by running x3d-nodes-to-pascal }

{$ifdef read_interface}

  public
    procedure CreateNode; override;
    class function ClassX3DType: string; override;
    class function ForVRMLVersion(const Version: TX3DVersion): Boolean; override;

    strict private FFdRange: TMFFloat;
    { Internal wrapper for property @link(Range). This wrapper API may change, we advise to access simpler @link(Range) instead. }
    public property FdRange: TMFFloat read FFdRange;

    strict private FFdCenter: TSFVec3f;
    { Internal wrapper for property @link(Center). This wrapper API may change, we advise to access simpler @link(Center) instead. }
    public property FdCenter: TSFVec3f read FFdCenter;

{$endif read_interface}

{$ifdef read_implementation}

{ TLODNode_1 ----------------------------------------------- }

class function TLODNode_1.ForVRMLVersion(const Version: TX3DVersion): Boolean;
begin
  Result := Version.Major <= 1; // parse this node only in VRML 1.0 and Inventor files
end;

class function TLODNode_1.ClassX3DType: String;
begin
  Result := 'LOD';
end;

procedure TLODNode_1.CreateNode;
begin
  inherited;

  FFdRange := TMFFloat.Create(Self, True, 'range', []);
   FdRange.ChangeAlways := chVisibleNonGeometry;
  AddField(FFdRange);

  FFdCenter := TSFVec3f.Create(Self, True, 'center', Vector3(0, 0, 0));
   FdCenter.ChangeAlways := chVisibleNonGeometry;
  AddField(FFdCenter);
end;

{$endif read_implementation}