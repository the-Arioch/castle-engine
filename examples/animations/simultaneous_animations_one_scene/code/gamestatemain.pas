{
  Copyright 2019-2022 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Main state, where most of the application logic takes place. }
unit GameStateMain;

interface

uses SysUtils, Classes,
  CastleWindow, CastleScene, CastleControls, CastleLog, CastleVectors,
  CastleFilesUtils, CastleSceneCore, CastleViewport, CastleComponentSerialize,
  CastleUIControls, CastleApplicationProperties, CastleUIState, X3DNodes;

type
  TStateMain = class(TUIState)
  strict private
    LabelFps: TCastleLabel;
    ButtonAnimationSqueeze, ButtonAnimationGear: TCastleButton;
    Scene1: TCastleScene;
    Viewport1: TCastleViewport;
    procedure ClickAnimationSqueeze(Sender: TObject);
    procedure ClickAnimationGear(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single;
      var HandleInput: Boolean); override;
  end;

var
  StateMain: TStateMain;

implementation

constructor TStateMain.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gamestatemain.castle-user-interface';
end;

procedure TStateMain.Start;
begin
  inherited;

  { Find components created in CGE Editor }
  LabelFps := DesignedComponent('LabelFps') as TCastleLabel;
  ButtonAnimationSqueeze := DesignedComponent('ButtonAnimationSqueeze') as TCastleButton;
  ButtonAnimationGear := DesignedComponent('ButtonAnimationGear') as TCastleButton;
  Scene1 := DesignedComponent('Scene1') as TCastleScene;
  Viewport1 := DesignedComponent('Viewport1') as TCastleViewport;

  { Assign OnClick events }
  ButtonAnimationSqueeze.OnClick := {$ifdef FPC}@{$endif}ClickAnimationSqueeze;
  ButtonAnimationGear.OnClick := {$ifdef FPC}@{$endif}ClickAnimationGear;
end;

procedure TStateMain.Update(const SecondsPassed: Single; var HandleInput: Boolean);
begin
  inherited;
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;
end;

procedure TStateMain.ClickAnimationSqueeze(Sender: TObject);
var
  TimeSensor: TTimeSensorNode;
begin
  ButtonAnimationSqueeze.Pressed := not ButtonAnimationSqueeze.Pressed;
  TimeSensor := Scene1.Node(TTimeSensorNode, 'squeeze') as TTimeSensorNode;
  if ButtonAnimationSqueeze.Pressed then
    { setting InitialTime to TimeSensor.ElapsedTimeInCycle below
      means that we start animation from the moment it was stopped
      (so it looks like "unpause"). }
    TimeSensor.Start(true, true, TimeSensor.ElapsedTimeInCycle)
  else
    TimeSensor.Stop;
end;

procedure TStateMain.ClickAnimationGear(Sender: TObject);
var
  TimeSensor: TTimeSensorNode;
begin
  ButtonAnimationGear.Pressed := not ButtonAnimationGear.Pressed;
  TimeSensor := Scene1.Node(TTimeSensorNode, 'gear_rotate') as TTimeSensorNode;
  if ButtonAnimationGear.Pressed then
    { setting InitialTime to TimeSensor.ElapsedTimeInCycle below
      means that we start animation from the moment it was stopped
      (so it looks like "unpause"). }
    TimeSensor.Start(true, true, TimeSensor.ElapsedTimeInCycle)
  else
    TimeSensor.Stop;
end;

end.
