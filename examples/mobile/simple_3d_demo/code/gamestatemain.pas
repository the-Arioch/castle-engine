{
  Copyright 2013-2022 Michalis Kamburelis.

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

uses Classes,
  CastleUIState, CastleComponentSerialize, CastleUIControls, CastleControls,
  CastleKeysMouse, CastleNotifications, CastleViewport, X3DNodes, CastleScene,
  CastleSoundEngine;

type
  { Main state, where most of the application logic takes place. }
  TStateMain = class(TUIState)
  private
    { Components designed using CGE editor, loaded from gamestatemain.castle-user-interface. }
    ButtonToggleShader: TCastleButton;
    ButtonToggleScreenEffect: TCastleButton;
    ButtonToggleSSAO: TCastleButton;
    ButtonTouchNavigation: TCastleButton;
    ButtonMessage: TCastleButton;
    ButtonProgress: TCastleButton;
    ButtonReopenContext: TCastleButton;
    ButtonToggleTextureUpdates: TCastleButton;
    ButtonPlaySoundWav: TCastleButton;
    ButtonPlaySoundOgg: TCastleButton;
    ButtonVibrate: TCastleButton;
    ButtonTerminate: TCastleButton;
    StatusText: TCastleLabel;
    TouchNavigation: TCastleTouchNavigation;
    MainViewport: TCastleViewport;
    SceneCastle, SceneTeapots: TCastleScene;
    SoundWav, SoundOgg: TCastleSound;

    { Other fields, initialized in Start }
    MyShaderEffect: TEffectNode;
    MyScreenEffect: TScreenEffectNode;

    procedure ClickToggleShader(Sender: TObject);
    procedure ClickToggleScreenEffect(Sender: TObject);
    procedure ClickToggleSSAO(Sender: TObject);
    procedure ClickTouchNavigation(Sender: TObject);
    procedure ClickMessage(Sender: TObject);
    procedure ClickProgress(Sender: TObject);
    procedure ClickReopenContext(Sender: TObject);
    procedure ClickToggleTextureUpdates(Sender: TObject);
    procedure ToggleTextureUpdatesCallback(Node: TX3DNode);
    procedure ClickPlaySoundWav(Sender: TObject);
    procedure ClickPlaySoundOgg(Sender: TObject);
    procedure ClickVibrate(Sender: TObject);
    procedure ClickTerminate(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
  end;

var
  StateMain: TStateMain;

implementation

uses SysUtils, TypInfo,
  CastleProgress, CastleWindow, CastleFilesUtils, CastleFindFiles,
  CastleOpenDocument, CastleMessages, CastleLog, CastleApplicationProperties, CastleUtils;

procedure FindFilesCallback(const FileInfo: TFileInfo; Data: Pointer; var StopSearch: boolean);
begin
  WritelnLog('FindFiles', 'Found URL:%s, Name:%s, AbsoluteName:%s, Directory:%s',
    [FileInfo.URL, FileInfo.Name, FileInfo.AbsoluteName, BoolToStr(FileInfo.Directory, true)]);
end;

function TouchInterfaceToStr(const Value: TTouchInterface): String;
begin
  Result := GetEnumName(TypeInfo(TTouchInterface), Ord(Value));
end;

function TextureUpdateToStr(const Value: TTextureUpdate): String;
begin
  Result := GetEnumName(TypeInfo(TTextureUpdate), Ord(Value));
end;

{ TStateMain ----------------------------------------------------------------- }

constructor TStateMain.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gamestatemain.castle-user-interface';
end;

procedure TStateMain.Start;
begin
  inherited;

  { Find components, by name, that we need to access from code }
  StatusText := DesignedComponent('StatusText') as TCastleLabel;
  ButtonToggleShader := DesignedComponent('ButtonToggleShader') as TCastleButton;
  ButtonToggleScreenEffect := DesignedComponent('ButtonToggleScreenEffect') as TCastleButton;
  ButtonToggleSSAO := DesignedComponent('ButtonToggleSSAO') as TCastleButton;
  ButtonTouchNavigation := DesignedComponent('ButtonTouchNavigation') as TCastleButton;
  ButtonMessage := DesignedComponent('ButtonMessage') as TCastleButton;
  ButtonProgress := DesignedComponent('ButtonProgress') as TCastleButton;
  ButtonReopenContext := DesignedComponent('ButtonReopenContext') as TCastleButton;
  ButtonToggleTextureUpdates := DesignedComponent('ButtonToggleTextureUpdates') as TCastleButton;
  ButtonPlaySoundWav := DesignedComponent('ButtonPlaySoundWav') as TCastleButton;
  ButtonPlaySoundOgg := DesignedComponent('ButtonPlaySoundOgg') as TCastleButton;
  ButtonVibrate := DesignedComponent('ButtonVibrate') as TCastleButton;
  ButtonTerminate := DesignedComponent('ButtonTerminate') as TCastleButton;
  TouchNavigation := DesignedComponent('TouchNavigation') as TCastleTouchNavigation;
  MainViewport := DesignedComponent('MainViewport') as TCastleViewport;
  SceneCastle := DesignedComponent('SceneCastle') as TCastleScene;
  SceneTeapots := DesignedComponent('SceneTeapots') as TCastleScene;
  SoundWav := DesignedComponent('SoundWav') as TCastleSound;
  SoundOgg := DesignedComponent('SoundOgg') as TCastleSound;

  { assign events }
  ButtonToggleShader.OnClick := {$ifdef FPC}@{$endif}ClickToggleShader;
  ButtonToggleScreenEffect.OnClick := {$ifdef FPC}@{$endif}ClickToggleScreenEffect;
  ButtonToggleSSAO.OnClick := {$ifdef FPC}@{$endif}ClickToggleSSAO;
  ButtonTouchNavigation.OnClick := {$ifdef FPC}@{$endif}ClickTouchNavigation;
  ButtonMessage.OnClick := {$ifdef FPC}@{$endif}ClickMessage;
  ButtonProgress.OnClick := {$ifdef FPC}@{$endif}ClickProgress;
  ButtonReopenContext.OnClick := {$ifdef FPC}@{$endif}ClickReopenContext;
  ButtonToggleTextureUpdates.OnClick := {$ifdef FPC}@{$endif}ClickToggleTextureUpdates;
  ButtonPlaySoundWav.OnClick := {$ifdef FPC}@{$endif}ClickPlaySoundWav;
  ButtonPlaySoundOgg.OnClick := {$ifdef FPC}@{$endif}ClickPlaySoundOgg;
  ButtonVibrate.OnClick := {$ifdef FPC}@{$endif}ClickVibrate;
  ButtonTerminate.OnClick := {$ifdef FPC}@{$endif}ClickTerminate;

  { configure components }
  ButtonMessage.Exists := ApplicationProperties.PlatformAllowsModalRoutines;
  ButtonProgress.Exists := ApplicationProperties.PlatformAllowsModalRoutines;
  ButtonTerminate.Exists := ApplicationProperties.ShowUserInterfaceToQuit;
  TouchNavigation.TouchInterface := tiWalk;

  { initialize other fields }

  MyShaderEffect := SceneCastle.Node('MyShaderEffect') as TEffectNode;
  ButtonToggleShader.Pressed := (MyShaderEffect <> nil) and MyShaderEffect.Enabled;

  MyScreenEffect := SceneCastle.Node('MyScreenEffect') as TScreenEffectNode;
  ButtonToggleScreenEffect.Pressed := (MyScreenEffect <> nil) and MyScreenEffect.Enabled;

  { Test that FindFiles works also on Android asset filesystem.
    These calls don't do anything (they merely output some log messages about found files). }
  FindFiles('castle-data:/', '*', true, {$ifdef FPC}@{$endif}FindFilesCallback, nil, [ffRecursive]);
  FindFiles('castle-data:/skies', '*', true, {$ifdef FPC}@{$endif}FindFilesCallback, nil, [ffRecursive]);
  FindFiles('castle-data:/textures/castle', '*', true, {$ifdef FPC}@{$endif}FindFilesCallback, nil, [ffRecursive]);
  FindFiles('castle-data:/textures/castle/', '*', true, {$ifdef FPC}@{$endif}FindFilesCallback, nil, [ffRecursive]);
end;

procedure TStateMain.Update(const SecondsPassed: Single; var HandleInput: Boolean);
begin
  inherited;

  StatusText.Caption := Format('FPS : %s' + NL +
    'Shapes : %d / %d' + NL +
    'Touch Navigation: %s', [
    Container.Fps.ToString,
    MainViewport.Statistics.ShapesRendered,
    MainViewport.Statistics.ShapesVisible,
    TouchInterfaceToStr(TouchNavigation.TouchInterface)
  ]);
end;

procedure TStateMain.ClickToggleShader(Sender: TObject);
begin
  if MyShaderEffect <> nil then
  begin
    MyShaderEffect.Enabled := not MyShaderEffect.Enabled;
    ButtonToggleShader.Pressed := MyShaderEffect.Enabled;
  end;
end;

procedure TStateMain.ClickToggleScreenEffect(Sender: TObject);
begin
  if MyScreenEffect <> nil then
  begin
    MyScreenEffect.Enabled := not MyScreenEffect.Enabled;
    ButtonToggleScreenEffect.Pressed := MyScreenEffect.Enabled;
  end;
end;

procedure TStateMain.ClickToggleSSAO(Sender: TObject);
begin
  MainViewport.ScreenSpaceAmbientOcclusion :=
    not MainViewport.ScreenSpaceAmbientOcclusion;
  ButtonToggleSSAO.Pressed := MainViewport.ScreenSpaceAmbientOcclusion;
end;

procedure TStateMain.ClickTouchNavigation(Sender: TObject);
begin
  if TouchNavigation.TouchInterface = High(TTouchInterface) then
    TouchNavigation.TouchInterface := Low(TTouchInterface)
  else
    TouchNavigation.TouchInterface := Succ(TouchNavigation.TouchInterface);
end;

procedure TStateMain.ClickMessage(Sender: TObject);
begin
  { On Android, a nice test is to switch to desktop (home)
    when one of these modal MessageXxx is working. The application loop
    (done inside MessageXxx, they call Application.ProcessMessage in a loop)
    will still work, even though the window is closed.
    When user gets back to our app, she/he will see the message box again. }
  if MessageYesNo(Application.MainWindow, 'Test of a yes/no message test.' + NL + NL +' Do you want to deliberately cause an exception (to test our CastleWindow.HandleException method)?') then
  begin
    MessageOK(Application.MainWindow, 'You clicked "Yes". Raising an exception, get ready!');
    raise Exception.Create('Test exception');
  end else
    MessageOK(Application.MainWindow, 'You clicked "No".');
end;

procedure TStateMain.ClickProgress(Sender: TObject);
const
  TestProgressSteps = 100;
var
  I: Integer;
begin
  Progress.Init(TestProgressSteps, 'Please wait');
  try
    for I := 1 to TestProgressSteps do
    begin
      Sleep(100);
      Progress.Step;
      { Note that on Android, Window may get closed (OpenGL context lost)
        at any time, also during such progress operation.
        For example when user switches to desktop (home) on Android.

        Progress.Step processes events (Application.ProcessMessage),
        so it will correctly react to it, closing the Window.
        This "for" loop will still continue, even though the window
        is closed (so no redraw will happen). It will actually get to the end
        of progress quickier (because without redraw, our speed is not throttled;
        you can see this by commenting Sleep call above. With window open,
        we're throttled by redraw speed. With window closed, we're not,
        and even long progress finishes quickly.)
        When the progress finishes, the main loop (from Application.Run)
        will allow to wait for next event (without doing busy waiting and wasting
        CPU), so we do not drain your battery power at all.

        If user will get back to our application before the progress finished,
        she/he will even correctly see the progress continuing at correct point.
        So everything just works. Just do not assume that Window stays
        open when processing events, and you're fine. }
      WritelnLog('Progress', 'Step %d', [I]);
    end;
  finally Progress.Fini end;
end;

procedure TStateMain.ClickReopenContext(Sender: TObject);
begin
  Application.MainWindow.Close(false);
  Application.MainWindow.Open;
end;

procedure TStateMain.ToggleTextureUpdatesCallback(Node: TX3DNode);
var
  CubeMap: TGeneratedCubeMapTextureNode;
begin
  CubeMap := Node as TGeneratedCubeMapTextureNode;
  if CubeMap.Update = upNone then
    CubeMap.Update := upAlways else
    CubeMap.Update := upNone;
  WritelnLog('CubeMap', 'Toggled updates on ' + CubeMap.NiceName +
    ' to ' + TextureUpdateToStr(CubeMap.Update));
end;

procedure TStateMain.ClickToggleTextureUpdates(Sender: TObject);
begin
  SceneTeapots.RootNode.EnumerateNodes(
    TGeneratedCubeMapTextureNode, {$ifdef FPC}@{$endif}ToggleTextureUpdatesCallback, false);
end;

procedure TStateMain.ClickPlaySoundWav(Sender: TObject);
begin
  SoundEngine.Play(SoundWav);
end;

procedure TStateMain.ClickPlaySoundOgg(Sender: TObject);
begin
  SoundEngine.Play(SoundOgg);
end;

procedure TStateMain.ClickVibrate(Sender: TObject);
begin
  Vibrate(200);
end;

procedure TStateMain.ClickTerminate(Sender: TObject);
begin
  Application.Terminate;
end;

end.
