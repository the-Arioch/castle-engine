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

{ Dialog to configure new unit properties (TNewUnitForm). }
unit FormNewUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn,
  ButtonPanel, ExtCtrls,
  ToolManifest;

type
  TNewUnitType = (utEmpty, utClass, utState);

  { Dialog to configure new unit properties. }
  TNewUnitForm = class(TForm)
    ButtonStateDir: TButton;
    ButtonUnitDir: TButton;
    ButtonPanel1: TButtonPanel;
    CheckStateInitialize: TCheckBox;
    ComboUnitType: TComboBox;
    EditClassName: TEdit;
    EditDesignDir: TEdit;
    EditStateName: TEdit;
    EditUnitName: TEdit;
    EditUnitDir: TEdit;
    LabelFinalUnitFile: TLabel;
    LabelFinalDesignFile: TLabel;
    LabelClassName: TLabel;
    LabelDesignDir: TLabel;
    LabelStateInitializeInfo: TLabel;
    LabelStateName: TLabel;
    LabelUnitName: TLabel;
    LabelCreateUnit: TLabel;
    LabelUnitDir: TLabel;
    PanelUnitClass: TPanel;
    PanelUnitState: TPanel;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    procedure ButtonUnitDirClick(Sender: TObject);
    procedure ButtonStateDirClick(Sender: TObject);
    procedure ComboUnitTypeChange(Sender: TObject);
    procedure EditDesignDirChange(Sender: TObject);
    procedure EditUnitDirChange(Sender: TObject);
    procedure EditUnitNameChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
  private
    EditUnitNameOldText: String;
    FCreatedUnitRelative, FCreatedDesignRelative: String;
    FCreatedUnitAbsolute, FCreatedDesignAbsolute: String;
    FUnitType: TNewUnitType;
    { Absolute directory (with final path delim) of the directory where
      unit should be created. }
    FUnitOutputPath: String;
    { Current project manifest. }
    FProjectManifest: TCastleManifest;
    UnitToInitializeState: String;
    procedure GetFinalFilenames(out FinalUnitRelative, FinalDesignRelative: String);
    procedure GetFinalFilenames(out FinalUnitRelative, FinalDesignRelative: String;
      out FinalUnitAbsolute, FinalDesignAbsolute: String);
    procedure SetUnitType(const AValue: TNewUnitType);
    procedure UpdateFinalFilenames;
    property UnitType: TNewUnitType read FUnitType write SetUnitType default utEmpty;
    procedure RefreshUiDependingOnUnitType;
  public
    { After ShowModel, the Created* contain filenames created (or empty if none). }
    property CreatedUnitRelative: String read FCreatedUnitRelative;
    property CreatedUnitAbsolute: String read FCreatedUnitAbsolute;
    property CreatedDesignRelative: String read FCreatedDesignRelative;
    property CreatedDesignAbsolute: String read FCreatedDesignAbsolute;

    procedure InitializeUi(const AUnitType: TNewUnitType;
      const AUnitOutputPath: String; const AProjectManifest: TCastleManifest);
  end;

var
  NewUnitForm: TNewUnitForm;

implementation

uses Generics.Collections,
  CastleFilesUtils, CastleURIUtils, CastleLog, CastleUtils, CastleStringUtils,
  EditorUtils, ProjectUtils, EditorCodeTools;

{$R *.lfm}

{ Like ExtractRelativePath but prefer to end result with PathDelim,
  as it just seems cleaner (it is then obvious that edit box shows
  a directory). }
function ExtractRelativePathDelim(const Base, Target: String): String;
begin
  if DirectoryExists(Base) and
     SameFileName(InclPathDelim(Base), InclPathDelim(Target)) then
    Exit(''); // otherwise ExtractRelativePath returns '../my_dir_name/'
  Result := ExtractRelativePath(Base, Target);
  if Result <> '' then
    Result := InclPathDelim(Result);
end;

{ TNewUnitForm --------------------------------------------------------------- }

procedure TNewUnitForm.ButtonUnitDirClick(Sender: TObject);
begin
  SelectDirectoryDialog1.InitialDir := CombinePaths(FProjectManifest.Path, EditUnitDir.Text);
  SelectDirectoryDialog1.FileName := CombinePaths(FProjectManifest.Path, EditUnitDir.Text);
  if SelectDirectoryDialog1.Execute then
  begin
    EditUnitDir.Text := ExtractRelativePathDelim(FProjectManifest.Path, SelectDirectoryDialog1.FileName);
    UpdateFinalFilenames;
  end;
end;

procedure TNewUnitForm.SetUnitType(const AValue: TNewUnitType);
begin
  if FUnitType = AValue then Exit;
  FUnitType := AValue;
  RefreshUiDependingOnUnitType;
end;

procedure TNewUnitForm.InitializeUi(const AUnitType: TNewUnitType;
  const AUnitOutputPath: String; const AProjectManifest: TCastleManifest);
begin
  FUnitType := AUnitType;
  FProjectManifest := AProjectManifest;
  FUnitOutputPath := AUnitOutputPath;
  RefreshUiDependingOnUnitType;
end;

procedure TNewUnitForm.RefreshUiDependingOnUnitType;
const
  ButtonsMargin = 16;
var
  RelativeUnitPath: String;
begin
  ComboUnitType.OnChange := nil; // avoid recursive ComboUnitType.OnChange calls
  ComboUnitType.ItemIndex := Ord(FUnitType);
  ComboUnitType.OnChange := @ComboUnitTypeChange;

  RelativeUnitPath := ExtractRelativePathDelim(FProjectManifest.Path, FUnitOutputPath);
  EditUnitDir.Text := RelativeUnitPath;

  SetEnabledVisible(PanelUnitClass, FUnitType = utClass);
  SetEnabledVisible(PanelUnitState, FUnitType = utState);

  case UnitType of
    utEmpty:
      begin
        EditUnitName.Text := 'GameSomething';

        { adjust form height }
        ClientHeight := LabelFinalUnitFile.Top + LabelFinalUnitFile.Height + ButtonsMargin + ButtonPanel1.Height;
      end;
    utClass:
      begin
        EditUnitName.Text := 'GameSomething';
        EditClassName.Text := 'TSomething';

        { adjust form height }
        ClientHeight := PanelUnitClass.Top + PanelUnitClass.Height + ButtonsMargin + ButtonPanel1.Height;
      end;
    utState:
      begin
        UnitToInitializeState := FindUnitToInitializeState(FProjectManifest);

        EditUnitName.Text := 'GameStateSomething';
        EditStateName.Text := 'TStateSomething';
        EditDesignDir.Text := 'data/';
        CheckStateInitialize.Checked := UnitToInitializeState <> '';
        CheckStateInitialize.Enabled := UnitToInitializeState <> '';

        if UnitToInitializeState <> '' then
          LabelStateInitializeInfo.Caption := Format(
            'Select above checkbox to modify %s to add state initialization.',
            [UnitToInitializeState])
        else
          LabelStateInitializeInfo.Caption :=
            'WARNING: Cannot find unit with state initialization. We search units listed in game_units in CastleEngineManifest.xml, among the search paths, for special CASTLE-XXX comments (see the new project templates for example).' + NL + NL +
            'You will need to manually create the new state in Application.OnInitialize.';

        { adjust form height }
        PanelUnitState.ClientHeight := LabelStateInitializeInfo.Top + LabelStateInitializeInfo.Height;
        ClientHeight := PanelUnitState.Top + PanelUnitState.Height + ButtonsMargin + ButtonPanel1.Height;
      end;
  end;

  EditUnitNameOldText := EditUnitName.Text;
  UpdateFinalFilenames;
end;

procedure TNewUnitForm.ButtonStateDirClick(Sender: TObject);
var
  DataPath: String;
begin
  SelectDirectoryDialog1.InitialDir := CombinePaths(FProjectManifest.Path, EditDesignDir.Text);
  SelectDirectoryDialog1.FileName := CombinePaths(FProjectManifest.Path, EditDesignDir.Text);
  if SelectDirectoryDialog1.Execute then
  begin
    DataPath := URIToFilenameSafe(ResolveCastleDataURL('castle-data:/'));
    if not IsPrefix(DataPath, InclPathDelim(SelectDirectoryDialog1.FileName), not FileNameCaseSensitive) then
    begin
      MessageDlg('Design outside data', 'You are saving a design outside of the project''s "data" directory.' + NL +
        NL +
        'The state design file will not be automatically referenced correctly from code (using "castle-data:/" protocol) and will not be automatically packaged in the project.' + NL +
        NL +
        'Unless you really know what you''re doing, we heavily advice to change the directory to be inside the project "data" directory.',
        mtWarning, [mbOK], 0);
    end;

    EditDesignDir.Text := ExtractRelativePathDelim(FProjectManifest.Path, SelectDirectoryDialog1.FileName);
    UpdateFinalFilenames;
  end;
end;

procedure TNewUnitForm.ComboUnitTypeChange(Sender: TObject);
begin
  UnitType := TNewUnitType(ComboUnitType.ItemIndex);
end;

procedure TNewUnitForm.EditDesignDirChange(Sender: TObject);
begin
  UpdateFinalFilenames;
end;

procedure TNewUnitForm.EditUnitDirChange(Sender: TObject);
begin
  UpdateFinalFilenames;
end;

procedure TNewUnitForm.EditUnitNameChange(Sender: TObject);
begin
  { automatically change lower edit boxes, if they matched }
  if SameText(EditClassName.Text, 'T' + EditUnitNameOldText) or
     SameText(EditClassName.Text, 'T' + PrefixRemove('game', EditUnitNameOldText, true)) then
    EditClassName.Text := 'T' + PrefixRemove('game', EditUnitName.Text, true);

  if SameText(EditStateName.Text, 'T' + EditUnitNameOldText) or
     SameText(EditStateName.Text, 'T' + PrefixRemove('game', EditUnitNameOldText, true)) then
    EditStateName.Text := 'T' + PrefixRemove('game', EditUnitName.Text, true);

  EditUnitNameOldText := EditUnitName.Text;

  UpdateFinalFilenames;
end;

procedure TNewUnitForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);

  function CheckValidPascalIdentifiers: Boolean;
  begin
    Result := true;

    if not IsValidIdent(EditUnitName.Text, true) then
    begin
      ErrorBox(Format('Unit name "%s" is not a valid Pascal identifier', [EditUnitName.Text]));
      Exit(false);
    end;

    if (UnitType = utClass) and (not IsValidIdent(EditClassName.Text, true)) then
    begin
      ErrorBox(Format('Class name "%s" is not a valid Pascal identifier', [EditClassName.Text]));
      Exit(false);
    end;

    if (UnitType = utState) and (not IsValidIdent(EditStateName.Text, true)) then
    begin
      ErrorBox(Format('State name "%s" is not a valid Pascal identifier', [EditStateName.Text]));
      Exit(false);
    end;

    if (UnitType = utState) and (not IsPrefix('t', EditStateName.Text, true)) then
    begin
      ErrorBox(Format('State name "%s" must start with letter "T" (following Pascal conventions for type names, this allows to have state singleton variable without "T" prefix)', [EditStateName.Text]));
      Exit(false);
    end;
  end;

  procedure CreateFiles(
    const FinalUnitRelative, FinalDesignRelative: String;
    const FinalUnitAbsolute, FinalDesignAbsolute: String);
  var
    Macros: TStringStringMap;
    TemplateSource, Contents, StateVariableName: String;
  begin
    Macros := TStringStringMap.Create;
    try
      Macros.Add('${UNIT_NAME}', EditUnitName.Text);
      case UnitType of
        utEmpty:
          begin
            TemplateSource := 'newunit.pas';
          end;
        utClass:
          begin
            TemplateSource := 'newunitclass.pas';
            Macros.Add('${CLASS_NAME}', EditClassName.Text);
          end;
        utState:
          begin
            TemplateSource := 'newunitstate.pas';
            StateVariableName := PrefixRemove('t', EditStateName.Text, true);
            Macros.Add('${STATE_CLASS_NAME}', EditStateName.Text);
            Macros.Add('${STATE_VARIABLE_NAME}', StateVariableName);
            Macros.Add('${DESIGN_FILE_URL}', MaybeUseDataProtocol(FilenameToURISafe(FinalDesignAbsolute)));

            StringToFile(FinalDesignAbsolute, FileToString(
              InternalCastleDesignData + 'templates/newunitstate.castle-user-interface'));
            FCreatedDesignRelative := FinalDesignRelative;
            FCreatedDesignAbsolute := FinalDesignAbsolute;

            if CheckStateInitialize.Checked then
            begin
              Assert(UnitToInitializeState <> '');
              AddInitializeState(CombinePaths(FProjectManifest.Path, UnitToInitializeState),
                EditUnitName.Text,
                EditStateName.Text,
                StateVariableName
              );
            end;
          end;
      end;

      Contents := FileToString(InternalCastleDesignData + 'templates/' + TemplateSource);
      Contents := SReplacePatterns(Contents, Macros, false);
      StringToFile(FinalUnitAbsolute, Contents);
      FCreatedUnitRelative := FinalUnitRelative;
      FCreatedUnitAbsolute := FinalUnitAbsolute;
    finally FreeAndNil(Macros) end;
  end;

  function CheckCanOverwriteFiles(
    const FinalUnitRelative, FinalDesignRelative: String;
    const FinalUnitAbsolute, FinalDesignAbsolute: String): Boolean;
  begin
    Result := true;

    Assert(FinalUnitAbsolute <> '');
    if FileExists(FinalUnitAbsolute) or DirectoryExists(FinalUnitAbsolute) then
    begin
      if not YesNoBox('Overwrite unit', Format('Unit file already exists: "%s".' + NL + NL + 'Overwrite file?', [
        FinalUnitRelative
      ])) then
        Exit(false);
    end;

    if (FinalDesignAbsolute <> '') and
       (FileExists(FinalDesignAbsolute) or DirectoryExists(FinalDesignAbsolute)) then
    begin
      if not YesNoBox('Overwrite design', Format('Design file already exists: "%s".' + NL + NL + 'Overwrite file?', [
        FinalDesignRelative
      ])) then
        Exit(false);
    end;
  end;

var
  FinalUnitRelative, FinalDesignRelative: String;
  FinalUnitAbsolute, FinalDesignAbsolute: String;
begin
  // reset output properties
  FCreatedUnitRelative := '';
  FCreatedUnitAbsolute := '';
  FCreatedDesignRelative := '';
  FCreatedDesignAbsolute := '';

  if ModalResult = mrOK then
  begin
    if not CheckValidPascalIdentifiers then
    begin
      CanClose := false;
      Exit;
    end;

    GetFinalFilenames(
      FinalUnitRelative, FinalDesignRelative,
      FinalUnitAbsolute, FinalDesignAbsolute);

    if not CheckCanOverwriteFiles(
      FinalUnitRelative, FinalDesignRelative,
      FinalUnitAbsolute, FinalDesignAbsolute) then
    begin
      CanClose := false;
      Exit;
    end;

    CreateFiles(
      FinalUnitRelative, FinalDesignRelative,
      FinalUnitAbsolute, FinalDesignAbsolute);
  end;
end;

procedure TNewUnitForm.FormShow(Sender: TObject);
begin
  ActiveControl := EditUnitName; // set focus on EditUnitName each time you open this form
end;

procedure TNewUnitForm.GetFinalFilenames(
  out FinalUnitRelative, FinalDesignRelative: String);
begin
  FinalUnitRelative := EditUnitDir.Text + LowerCase(EditUnitName.Text) + '.pas';

  if UnitType = utState then
    FinalDesignRelative := EditDesignDir.Text + LowerCase(EditUnitName.Text) + '.castle-user-interface'
  else
    FinalDesignRelative := '';
end;

procedure TNewUnitForm.GetFinalFilenames(
  out FinalUnitRelative, FinalDesignRelative: String;
  out FinalUnitAbsolute, FinalDesignAbsolute: String);
begin
  GetFinalFilenames(FinalUnitRelative, FinalDesignRelative);

  FinalUnitAbsolute := CombinePaths(FProjectManifest.Path, FinalUnitRelative);

  if FinalDesignRelative <> '' then
    FinalDesignAbsolute := CombinePaths(FProjectManifest.Path, FinalDesignRelative)
  else
    FinalDesignAbsolute := '';
end;

procedure TNewUnitForm.UpdateFinalFilenames;
var
  FinalUnitRelative, FinalDesignRelative: String;
begin
  GetFinalFilenames(FinalUnitRelative, FinalDesignRelative);
  LabelFinalUnitFile.Caption := 'Final Unit File: ' + FinalUnitRelative;
  LabelFinalDesignFile.Caption := 'Final Design File: ' + FinalDesignRelative;
end;

end.

