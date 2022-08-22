{
  Copyright 2007-2018 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Game initialization. }
unit GameInitialize;

interface

implementation

uses SysUtils,
  CastleScene, CastleControls, CastleLog, CastleWindow,
  CastleFilesUtils, CastleSceneCore, CastleKeysMouse, CastleColors,
  CastleUIControls, CastleApplicationProperties, CastleWindowProgress,
  CastleProgress, CastleGameNotifications, CastleVectors, CastleSoundEngine,
  CastleTransform, CastleConfig, CastleUIState,
  GameSound, GameConfiguration, GameCreatures, GameLocations
  {$region 'Castle Initialization Uses'}
  // The content here may be automatically updated by CGE editor.
  , GameStateIntro
  , GameStateMainMenu
  , GameStatePlay
  {$endregion 'Castle Initialization Uses'};

var
  Window: TCastleWindow;

{ routines ------------------------------------------------------------------- }

const
  DefaultWindowWidth = 1024;
  DefaultWindowHeight = 768;

{ One-time initialization of resources. }
procedure ApplicationInitialize;
begin
  Progress.UserInterface := WindowProgressInterface;
  Window.Container.UIReferenceWidth := DefaultWindowWidth;
  Window.Container.UIReferenceHeight := DefaultWindowHeight;
  Window.Container.UIScaling := usEncloseReferenceSize;
  Window.Container.BackgroundColor := Black;

  { configure Notifications }
  Notifications.MaxMessages := 4;
  Notifications.Color := Vector4(0.8, 0.8, 0.8, 1.0);

  InitializeSound;

  { The reason for this is historical.
    We designed models in Blender following this (non-standard) orientation. }
  TCastleTransform.DefaultOrientation := otUpZDirectionX;

  { load game configuration }
  GameConfig := TCastleConfig.Create(nil);
  GameConfig.URL := 'castle-data:/game.xml';
  CreatureKinds := TCreatureKindList.Create;
  Locations := TLocationList.Create;

  { Create game states and set initial state }
  {$region 'Castle State Creation'}
  // The content here may be automatically updated by CGE editor.
  StateIntro := TStateIntro.Create(Application);
  StateMainMenu := TStateMainMenu.Create(Application);
  StatePlay := TStatePlay.Create(Application);
  {$endregion 'Castle State Creation'}

  TUIState.Current := StateIntro;
end;

initialization
  { Initialize Application.OnInitialize. }
  Application.OnInitialize := @ApplicationInitialize;

  { Create and assign Application.MainWindow. }
  Window := TCastleWindow.Create(Application);
  Application.MainWindow := Window;

  { Assign initial window size and configuration.
    This can be overridden by parsing command-line options for standalone platform. }
  Window.FpsShowOnCaption := true;
  // for shadow volumes to be possible
  Window.StencilBits := 8;
  Window.Width := DefaultWindowWidth;
  Window.Height := DefaultWindowHeight;
  Window.FullScreen := true;
  Window.ParseParameters; // allows to control window size / fullscreen on the command-line
end.
