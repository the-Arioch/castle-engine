unit jitterform;

{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  castlerenderoptions,
   CastleVectors,
  CastleViewport, CastleControl, CastleTransform, CastleScene, CastleLCLUtils, CastleKeysMouse;

type

  { TfmSea }

  TfmSea = class(TForm)
    btnShow: TButton;
    btnSave: TButton;
    CastleSea: TCastleControl;
    ckPhong: TCheckBox;
    Panel1: TPanel;
    SaveDialogText: TSaveDialog;
    procedure btnSaveClick(Sender: TObject);
    procedure btnShowClick(Sender: TObject);
    procedure CastleSeaPress(Sender: TObject; const Key: TInputPressRelease);
    procedure ckPhongChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    FNoPhong: boolean;
    procedure SetNoPhong(const AValue: boolean);
    function Info: string;
  private
    Viewport: TCastleViewport;

    Ship1, Ship2: TCastleTransform;

    property NoPhong: boolean read FNoPhong write SetNoPhong;
    procedure CRO(const Options: TCastleRenderOptions);
  public
    procedure CreateScene;
  end;

var
  fmSea: TfmSea;

implementation

uses
  Math,
  CastleLog,
  CastleUtils,
  CastleGLShaders,
  CastleGLVersion,
  CastleGLUtils,
  CastleSoundEngine,
  CastleColors;

{$R *.lfm}

const
  pxInMeter = 10;

function CreateShip1(const Owner: TComponent; const color, colorMark: TCastleColor
  ): TCastleTransform;
var
  cf: TCastleSphere; cr: TCastleCone; b, a: TCastleCylinder;

  L, W: integer;

  procedure Setup1(const O: TCastleAbstractPrimitive);
  begin
    O.Material := pmUnlit;
    O.Color := color;

    O.RenderOptions.Blending := True;
    O.RenderOptions.BlendingSort := bs2D;

//    O.RenderOptions.MaxLightsPerShape := 8;
//    O.RenderOptions.PhongShading := False;
  end;
begin
  Result := TCastleTransform.Create(Owner);

  L := 30 * pxInMeter;
  W := 10 * pxInMeter;

  b := TCastleCylinder.Create(Owner);
  a := TCastleCylinder.Create(Owner);
  cf := TCastleSphere.Create(Owner);
  cr := TCastleCone.Create(Owner);

  Setup1(b);
  Setup1(cf);
  Setup1(cr);

  b.Height := L;
  b.Radius := W;

  a.Height := 3 * pxInMeter;
  a.Radius := 3 * pxInMeter;
  a.Material := pmUnlit;
  a.Color := colorMark;

  cf.Radius := W;
  cr.BottomRadius := W;
  cr.Height := 2 * W;

  cf.TranslationXY := Vector2(0, +L/2 + 2 * pxInMeter);
  cr.TranslationXY := Vector2(0, -(L/2+W));
  cr.Rotation      := Vector4(0, 0, 1, pi);
  a.Translation    := Vector3(0, 0, 2*W);

  Result.Add(cf);
  Result.Add(cr);
  Result.Add(b);
  b.Add(a);
end;

function CreateShip2(const Owner: TComponent; const color, colorMark: TCastleColor
  ): TCastleTransform;
var
  cf, cr: TCastleCone;
  a: TCastlePlane; // TCastleCylinder;
  b: TCastleBox;

  L, W: integer;

  procedure Setup1(const O: TCastleAbstractPrimitive);
  begin
    O.Material := pmUnlit;
    O.Color := color;

//    O.RenderOptions.Blending := True;
//    O.RenderOptions.BlendingSort := bs2D;

   //O.RenderOptions.MaxLightsPerShape := 8;
//   O.RenderOptions.PhongShading := False;
  end;
begin
  Result := TCastleTransform.Create(Owner);

  L := round(40 * pxInMeter);
  W := round(15 * pxInMeter);

  b := TCastleBox.Create(Owner);
  a := TCastlePlane.Create(Owner);
  cf := TCastleCone.Create(Owner);
  cr := TCastleCone.Create(Owner);

  Setup1(b);
  Setup1(cf);
  Setup1(cr);
  Setup1(a);

  //b.Height := L;
  //b.Radius := W;
  b.Size := Vector3(W*2, L, 2);

//  a.Height := 3.5 * pxInMeter;
//  a.Radius := 3.5 * pxInMeter;
  a.Size := Vector2( 3 * pxInMeter, 2 * pxInMeter);
  a.Axis := 2;
  a.Material := pmUnlit;
  a.Color := colorMark;

  cf.BottomRadius := W;
  cf.Height := W;
  cr.BottomRadius := W;
  cr.Height := W;

  cf.TranslationXY := Vector2(0, -(L+W)/2);
  cr.TranslationXY := Vector2(0, +(L+W)/2);
  a.Translation    := Vector3(0, 0, 2*W);

  Result.Add(cf);
  Result.Add(cr);
  Result.Add(b);
  b.Add(a);
end;

{ TfmSea }

procedure TfmSea.CastleSeaPress(Sender: TObject; const Key: TInputPressRelease
  );
var dx, dy: TValueSign; XY: TVector2;
begin
//  fmControls.SeaUserKey(Event);
    dx := 0; dy := 0;
    if Key.EventType = itKey then begin
       case Key.Key of
         keyArrowUp:    dy := +1;
         keyArrowDown:  dy := -1;
         keyArrowLeft:  dx := -1;
         keyArrowRight: dx := +1;
       end;
    end;
    if Key.EventType = itMouseWheel then begin
       case Key.MouseWheel of
         mwUp:   dx := +1;
         mwDown: dx := -1;
       end;
    end;
    if (dx <> 0) or (dy <> 0) then begin
       XY := Ship2.TranslationXY;
       XY.X := XY.X + dx * pxInMeter;
       XY.Y := XY.Y + dy * pxInMeter;
       Ship2.TranslationXY := XY;
    end;
end;

procedure TfmSea.btnShowClick(Sender: TObject);
begin
  ShowMessage(Info());
end;

procedure TfmSea.btnSaveClick(Sender: TObject);
var s: TStringStream;
begin
  if SaveDialogText.Execute then begin
     s := TStringStream.Create(Info());
     try
       s.SaveToFile(SaveDialogText.FileName);
     finally
       s.Destroy;
     end;
  end;
end;

procedure TfmSea.ckPhongChange(Sender: TObject);
begin
  NoPhong := ckPhong.Checked;
end;

procedure TfmSea.FormCreate(Sender: TObject);
begin
//  LogShaders := True;
//  LogFileName := 'd:\Castle Game Engine Projects\glsl.txt';
//  InitializeLog();
  CreateScene;
end;

procedure TfmSea.FormResize(Sender: TObject);
begin
  if nil = GLVersion then exit;

  Caption := Caption + '  GL ' + IntTOStr(Ord(
     GLVersion.BuggyPureShaderPipeline
  ));

  OnResize := nil;
end;

procedure TfmSea.SetNoPhong(const AValue: boolean);
begin
  if FNoPhong = AValue then Exit;
  FNoPhong := AValue;

  Viewport.Free;
  CreateScene;
end;

function TfmSea.Info: string;
begin
  Result :=

  'Castle Game Engine version: ' + CastleEngineVersion + '.' + NL +
  'Editor compiled with ' + SCompilerDescription + '.' + NL +
  'Editor platform: ' + SPlatformDescription + '.' + NL

  + NL + NL + '  == == == VIDEO == == ==' + NL + NL

  + GLInformationString()

  + NL + NL + '  == == == AUDIO == == ==' + NL + NL

  + SoundEngine.Information;
end;

procedure TfmSea.CRO(const Options: TCastleRenderOptions);
begin
  Options.PhongShading := not NoPhong;
end;

procedure TfmSea.CreateScene;
var ShipN: TCastleTransform; i: integer;
begin
  TCastleRenderOptions.OnCreate := @CRO;

  Viewport := TCastleViewport.Create(Self);
  Viewport.FullSize := true;                               
  Viewport.Camera.Orthographic.Width := 2000 * pxInMeter;
  Viewport.Camera.Orthographic.Height := 2000 * pxInMeter;
  Viewport.Camera.Orthographic.Origin := Vector2(0.5, 0.5);
  Viewport.Setup2D;
  Viewport.Camera.ProjectionNear := -50000;
  Viewport.Camera.ProjectionFar := +50000;

  Viewport.BackgroundColor := Navy;

  CastleSea.Controls.InsertFront(Viewport);

(*
  SonarCone := TCastleCone.Create(Self);
  MiniCone := TCastleCone.Create(SonarCone);
  Aim := TCastleCylinder.Create(SonarCone);

  MiniCone.Material := pmUnlit;
  MiniCone.Color := Red;

  Aim.Material := pmUnlit;
  Aim.Color := Vector4( 0.3 , 0.3 , 0.2 , 0.5);

  SonarCone.Material := pmUnlit;
  SonarCone.Color := Yellow;
  H := 150 * pxInMeter;
  SonarCone.Height := H;

  MiniCone.Height := 30 * pxInMeter;
  MiniCone.BottomRadius := 10 * pxInMeter;

  SonarCone.Center := Vector3(0, h/2, 0);
  SonarCone.BottomRadius := H/4;

  MiniCone.Translation := Vector3(0, +h/2 - MiniCone.Height, 1000);
  SonarCone.Add(MiniCone);

  SonarCone.TranslationXY := Vector2(0, -h/2);
  SonarCone.Rotation.Init(0,0, 1 , pi );

  H := Viewport.Camera.Orthographic.Width / 2 * 1.5;
  Aim.Radius := 1.5 * pxInMeter;
  Aim.Height := H;
  Aim.Translation := Vector3(0, -h/2, -100);
  SonarCone.Add(Aim);

  SonarCone.RenderOptions.Blending := True;
  SonarCone.RenderOptions.BlendingSort := bs2D;

  Viewport.Items.Add(SonarCone);
*)

  Ship1 := CreateShip1(Self, Vector4(0.2, 0.75, 0.75, 1), Teal);
  Ship2 := CreateShip2(Self, Silver, Black);

  Ship1.TranslationXY := Vector2(-5000, 0);
  Ship2.TranslationXY := Vector2(-1500, +7500);
  Ship2.Rotation := Vector4(0, 0, 1, - pi /2 );

//  GV.Ship1.xy := Ship1.TranslationXY;
//  GV.Ship2.xy := Ship2.TranslationXY;

  Viewport.Items.Add(Ship1);
  Viewport.Items.Add(Ship2);

  for i := 1 to 10 do begin
    ShipN := CreateShip2(Self, Teal, Blue);
    ShipN.TranslationXY := Vector2(-1500 + i * pxInMeter, +7000 - pxInMeter * i * 40 );
    ShipN.Rotation := Vector4(0, 0, 1, - pi /2 );
    Viewport.Items.Add(ShipN);
  end;

  //tmp1 := Viewport.Items;
  //tmp2 := tmp1.MainScene;
  //tmp3 := tmp2.RenderOptions;
  //tmp3.MaxLightsPerShape := 8;
  //tmp3.PhongShading := False;

//  GV.OnSonarAimChange.AddHandler(@SonarAimChanged);
//  GV.OnSonarWidthChange.AddHandler(@SonarWidthChanged);
//  GV.OnShip1Move.AddHandler(@Ship1Moved);
//  GV.OnShip2Move.AddHandler(@Ship2Moved);
end;

end.

