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

    strict private FFdRadianceTransfer: TMFVec3f;
    { Internal wrapper for property @link(RadianceTransfer). This wrapper API may change, we advise to access simpler @link(RadianceTransfer) instead. }
    public property FdRadianceTransfer: TMFVec3f read FFdRadianceTransfer;
    {  }
    procedure SetRadianceTransfer(const Value: array of TVector3); overload;
    {  }
    procedure SetRadianceTransfer(const Value: TVector3List); overload;

{$endif read_interface}

{$ifdef read_implementation}

{ TIndexedFaceSetNode_1 ----------------------------------------------- }

procedure TIndexedFaceSetNode_1.SetRadianceTransfer(const Value: array of TVector3);
begin
  FdRadianceTransfer.Send(Value);
end;

procedure TIndexedFaceSetNode_1.SetRadianceTransfer(const Value: TVector3List);
begin
  FdRadianceTransfer.Send(Value);
end;

class function TIndexedFaceSetNode_1.ForVRMLVersion(const Version: TX3DVersion): Boolean;
begin
  Result := Version.Major <= 1; // parse this node only in VRML 1.0 and Inventor files
end;

class function TIndexedFaceSetNode_1.ClassX3DType: String;
begin
  Result := 'IndexedFaceSet';
end;

procedure TIndexedFaceSetNode_1.CreateNode;
begin
  inherited;

  FFdRadianceTransfer := TMFVec3f.Create(Self, True, 'radianceTransfer', []);
   FdRadianceTransfer.ChangeAlways := chGeometry;
  AddField(FFdRadianceTransfer);
end;

{$endif read_implementation}