{%MainUnit castlesoundengine.pas}
{
  Copyright 2021-2021 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{$ifdef read_interface}

//type // allow type declaration to continue

  { @exclude Used with TCastleSound notifications (TCastleSound.InternalAddChangeNotification). }
  TSoundChange = (
    { TCastleSound.Buffer, and maybe other values, changed. }
    scAfterBufferCreated,
    { TCastleSound.Buffer may be destroyed now, stop related sounds. }
    scBeforeBufferDestroyed,
    { TCastleSound values, but not Buffer, changed. }
    scAfterOther
  );

  TCastleSound = class;

  { @exclude Used with TCastleSound notifications (TCastleSound.InternalAddChangeNotification). }
  TCastleSoundChangeEvent = procedure (const Sender: TCastleSound; const Change: TSoundChange) of object;

  { @exclude Used with TCastleSound notifications (TCastleSound.InternalAddChangeNotification). }
  TCastleSoundChangeEventList = class({$ifdef CASTLE_OBJFPC}specialize{$endif} TList<TCastleSoundChangeEvent>)
  public
    procedure ExecuteAll(const Sender: TCastleSound; const Change: TSoundChange);
  end;

  { Sound that can be loaded from URL (possibly reusing a cache,
    possibly using streaming) and played.

    Aside from sound file (also called "sound buffer" or "audio clip" in various APIs)
    this class allows to configue also playback values, like @link(Volume) and @link(Pitch).
    These playback values are intended to reflect preferences specific to this sound file.
    They are multiplied by playback values of the @link(TCastleSoundSource)
    (@link(TCastleSoundSource.Volume), @link(TCastleSoundSource.Pitch))
    and @link(TCastlePlayingSound) (to adjust it per-playback, using
    @link(TCastlePlayingSound.Volume), @link(TCastlePlayingSound.Pitch)).

    This class does not actually play the sound.
    It only defines something that @italic(can) be played.
    To play the sound use @link(TSoundEngine.Play SoundEngine.Play) or @link(TCastleSoundSource).
    For spatial sounds, attach @link(TCastleSoundSource) to a @link(TCastleTransform) within some
    @link(TCastleViewport) and set @link(TCastleSoundSource.Sound)
    or call @link(TCastleSoundSource.Play). }
  TCastleSound = class(TCastleComponent)
  strict private
    FURL: string;
    FBuffer: TInternalSoundBuffer;
    FStream: Boolean;
    FVolume: Single;
    FPitch: Single;
    FMinGain: Single;
    FMaxGain: Single;
    FPriority: Single;
    FChangeNotifications: TCastleSoundChangeEventList;
    procedure SetStream(const Value: Boolean);
    procedure SetURL(const Value: String);
    procedure SetVolume(const Value: Single);
    procedure SetPitch(const Value: Single);
    procedure SetMinGain(const Value: Single);
    procedure SetMaxGain(const Value: Single);
    procedure SetPriority(const Value: Single);
    procedure ReloadBuffer;
    procedure DoChange(const Change: TSoundChange);
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function PropertySections(const PropertyName: String): TPropertySections; override;

    { @exclude Add notification when sound property changes. }
    procedure InternalAddChangeNotification(const Notify: TCastleSoundChangeEvent);
    { @exclude Remove notification when sound property occurs. }
    procedure InternalRemoveChangeNotification(const Notify: TCastleSoundChangeEvent);

    { Loaded sound buffer, for playing the buffer with the @link(SoundEngine).
      @nil if not loaded.
      @exclude }
    property InternalBuffer: TInternalSoundBuffer read FBuffer;

    { Force a minimum sound loudness, despite what volume would
      be calculated by the spatialization. This can be used to force sound
      to be audible, even when it's far away from the listener.

      It must be in [0, 1] range. By default it is 0. }
    property MinGain: Single read FMinGain write SetMinGain default 0.0; platform { this feature is only available with OpenAL sound backend };

    { Force a maximum sound loudness, despite what volume would
      be calculated by the spatialization. This can be used to limit sound volume,
      regardless of the distance attenuation calculation.

      It must be in [0, 1] range. By default it is 1. }
    property MaxGain: Single read FMaxGain write SetMaxGain default 1.0; platform { this feature is only available with OpenAL sound backend };

    { Duration of the sound, in seconds. -1 if not loaded yet.
      The sound is loaded once you set @link(URL) and don't get any loading exceptions. }
    function Duration: Single;

    { Sound data format (disregarding compression on top of it), for informational purposes.
      Undefined if not loaded yet.
      The sound is loaded once you set @link(URL) and don't get any loading exceptions. }
    function DataFormat: TSoundDataFormat;

    { Frequency (sample rate) of the loaded sound file.
      0 if not loaded yet.
      The sound is loaded once you set @link(URL) and don't get any loading exceptions. }
    function Frequency: LongWord;
  published
    { URL of the sound file.
      Set this to load a new sound buffer, you can set to '' to clear the sound buffer.
      Changing this also changes @link(Buffer).

      If you plan to change @link(Stream), note that it is best to do it before
      setting @link(URL). Changing @link(Stream) while @link(URL) is already set
      means that the sound is reloaded. }
    property URL: String read FURL write SetURL;

    { Play sound using streaming. This means that the sound is gradually decompressed in memory,
      which means that loading time is much smaller,
      although there may be a small overhead on CPU during playback.
      Streaming is usually a good idea for longer sounds, e.g. music tracks.

      See also @link(TSoundLoading) for details.

      If you plan to change @link(Stream), note that it is best to do it before
      setting @link(URL). Changing @link(Stream) while @link(URL) is already set
      means that the sound is reloaded. }
    property Stream: Boolean read FStream write SetStream default false;

    { Volume (how loud the sound is).

      Use this to indicate that e.g. a plane engine is louder than a mouse squeak
      (when heard from the same distance).
      Note: Do not make the actual sound data (in sound files)
      louder/more silent to express that something is louder/more silent in reality.
      This would usually lower the sound quality.
      Instead, keep your sound file data at max loudness ("normalized"), and use
      this property to adjust the volume associated with the sound.

      The effective sound volume is a multiplication of @link(TCastleSound.Volume),
      @link(TCastlePlayingSound.Volume) and @link(TCastleSoundSource.Volume)
      (if the sound is played through @link(TCastleSoundSource)).
      It is also affected by spatial calculations (if the sound is played
      through @link(TCastleSoundSource) with @link(TCastleSoundSource.Spatial) = @true)
      and finally by a master @link(TSoundEngine.Volume SoundEngine.Volume).

      Any value > 0 is allowed. The default is 1. Note that,
      while values > 1 are allowed,
      but some sound backends (like OpenAL) may clip the resulting sound volume
      (after all volume influences, including spatial calculations are done) to 1.0. }
    property Volume: Single read FVolume write SetVolume default 1.0;

    { Sound playing speed.

      The effective sound pitch is a multiplication of @link(TCastleSound.Pitch),
      @link(TCastlePlayingSound.Pitch) and @link(TCastleSoundSource.Pitch)
      (if the sound is played through @link(TCastleSoundSource)).

      Changing this naturally also changes the audible sound.
      Each reduction by 50 percent equals a pitchshift of -12 semitones (one octave reduction).
      Each doubling equals a pitch shift of 12 semitones (one octave increase).

      Any value > 0 is allowed. }
    property Pitch: Single read FPitch write SetPitch default 1.0;

    { How important is the sound, between 0.0 (least important) to 1.0 (most important).

      The sound engine sometimes has to interrupt (or even not start at all)
      playback of some non-important sound, to have a good performance of audio mixing.
      In these cases, the sound with higher priority always "wins" over sound with lower
      priority. That is, sound with lower priority will be interrupted (the slot will be "stolen")
      to make room for sound with higher priority.

      Note: Many sound APIs (Unity, FMOD, Wwise, X3D...) have a similar property,
      with inconsistent range (minimum, maximum) and inconsistent meaning (some say "lower is more important",
      some say "higher is more important"). Our treatment of this property is similar to X3D,
      as it satisfies a number of important points: it defines easy to remember min/max (0 and 1),
      it is agnostic to the underlying precision (e.g. it has to map to 257 levels in FMOD,
      100 levels in Wwise). Also, "higher is more important" seems just more natural. }
    property Priority: Single read FPriority write SetPriority default 0.5;
  end;

{$endif read_interface}

{$ifdef read_implementation}

{ TCastleSoundChangeEventList ------------------------------------------------ }

procedure TCastleSoundChangeEventList.ExecuteAll(const Sender: TCastleSound; const Change: TSoundChange);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I](Sender, Change);
end;

{ TCastleSound --------------------------------------------------------------- }

constructor TCastleSound.Create(AOwner: TComponent);
begin
  inherited;
  FStream := false;
  FVolume := 1.0;
  FPitch := 1.0;
  FMinGain := 0.0;
  FMaxGain := 1.0;
  FPriority := 0.5;
  FChangeNotifications := TCastleSoundChangeEventList.Create;
end;

destructor TCastleSound.Destroy;
begin
  { Use InternalSoundEngine instead of SoundEngine to avoid creating
    2nd SoundEngine instance, if this would be called at finalization
    (after 1st singleton SoundEngine destroyed). }
  if InternalSoundEngine <> nil then
  begin
    { Just like in ReloadBuffer, we need to call scBeforeBufferDestroyed notification.
      This allows related TCastlePlayingSound to stop playback automatically
      when TCastleSound is destroyed. }
    DoChange(scBeforeBufferDestroyed);
    {$warnings off} // using deprecated that should be internal
    InternalSoundEngine.FreeBuffer(FBuffer); // this sets FBuffer = nil
    {$warnings on}
  end;
  FreeAndNil(FChangeNotifications);
  inherited;
end;

function TCastleSound.PropertySections(const PropertyName: String): TPropertySections;
begin
  case PropertyName of
    'URL', 'Stream', 'Volume', 'Pitch', 'Priority':
      Result := [psBasic];
    else
      Result := inherited PropertySections(PropertyName);
  end;
end;

procedure TCastleSound.ReloadBuffer;
var
  SoundLoading: TSoundLoading;
begin
  if FBuffer <> nil then // check nil to avoid accessing SoundEngine if not needed
  begin
    { We first make scBeforeBufferDestroyed notification, so that sound sources playing
      this TCastleSound can be stopped.
      OpenAL makes warning if trying to free buffer used by playing sources. }
    DoChange(scBeforeBufferDestroyed);
    {$warnings off} // using deprecated that should be internal
    SoundEngine.FreeBuffer(FBuffer); // this sets FBuffer = nil
    {$warnings on}
  end;

  if URL <> '' then
  begin
    if Stream then
      SoundLoading := slStreaming
    else
      SoundLoading := slComplete;
    {$warnings off} // using deprecated that should be internal
    FBuffer := SoundEngine.LoadBuffer(URL, SoundLoading);
    {$warnings on}
    DoChange(scAfterBufferCreated);
  end;
end;

procedure TCastleSound.Loaded;
begin
  inherited; //< important, as inherited removes csLoading from ComponentState
  ReloadBuffer;
end;

procedure TCastleSound.SetStream(const Value: Boolean);
begin
  if FStream <> Value then
  begin
    FStream := Value;
    if not (csLoading in ComponentState) then
      ReloadBuffer;
  end;
end;

procedure TCastleSound.SetURL(const Value: String);
begin
  if FURL <> Value then
  begin
    FURL := Value;
    if not (csLoading in ComponentState) then
      ReloadBuffer;
  end;
end;

procedure TCastleSound.SetVolume(const Value: Single);
begin
  if FVolume <> Value then
  begin
    FVolume := Value;
    DoChange(scAfterOther);
  end;
end;

procedure TCastleSound.SetPitch(const Value: Single);
begin
  if FPitch <> Value then
  begin
    FPitch := Value;
    DoChange(scAfterOther);
  end;
end;

procedure TCastleSound.SetMinGain(const Value: Single);
begin
  if FMinGain <> Value then
  begin
    FMinGain := Value;
    DoChange(scAfterOther);
  end;
end;

procedure TCastleSound.SetMaxGain(const Value: Single);
begin
  if FMaxGain <> Value then
  begin
    FMaxGain := Value;
    DoChange(scAfterOther);
  end;
end;

procedure TCastleSound.SetPriority(const Value: Single);
begin
  if FPriority <> Value then
  begin
    FPriority := Value;
    DoChange(scAfterOther);
  end;
end;

procedure TCastleSound.DoChange(const Change: TSoundChange);
begin
  FChangeNotifications.ExecuteAll(Self, Change);
end;

procedure TCastleSound.InternalAddChangeNotification(const Notify: TCastleSoundChangeEvent);
begin
  FChangeNotifications.Add(Notify);
end;

procedure TCastleSound.InternalRemoveChangeNotification(const Notify: TCastleSoundChangeEvent);
begin
  if FChangeNotifications <> nil then // may be nil when destroying, and we make notification
    FChangeNotifications.Remove(Notify);
end;

function TCastleSound.Duration: Single;
begin
  if FBuffer <> nil then
    Result := FBuffer.Duration
  else
    Result := -1;
end;

function TCastleSound.DataFormat: TSoundDataFormat;
begin
  if FBuffer <> nil then
    Result := FBuffer.DataFormat
  else
    Result := Default(TSoundDataFormat); // whatever, just not memory garbage
end;

function TCastleSound.Frequency: LongWord;
begin
  if FBuffer <> nil then
    Result := FBuffer.Frequency
  else
    Result := 0;
end;

{$endif read_implementation}