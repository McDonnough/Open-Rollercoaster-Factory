unit m_sound_openal;

interface

uses
  SysUtils, Classes, openal, u_vectors, u_math, m_sound_class;

const
  AL_SOUND_SOURCES = 16;

type
  TSoundBuffer = class
    Buffer: ALUInt;
    destructor Free;
    end;

  TSoundHandle = record
    LostALSource, GainedALSource: Boolean;
    SoundSource: TSoundSource;
    ALSourceID: Integer;
    end;

  TModuleSoundOpenAL = class(TModuleSoundClass)
    protected
      fSoundHandles: Array of TSoundHandle;
      fSoundBuffers: Array of TSoundBuffer;
      fPrevListenerPos: TVector3D;
      alDevice: PALCdevice;
      alContext: PALCcontext;
      alTrueSources: Array[0..AL_SOUND_SOURCES - 1] of ALUInt;
      alSourcesFree: Array[0..AL_SOUND_SOURCES - 1] of Boolean;
      procedure InitOpenAL;
      procedure CloseOpenAL;
      function GetNextFreeSourceID: Integer; inline;
    public
      procedure Advance;
      function AddSoundbuffer(Data: Pointer; Size: Integer; Channels: Integer; Rate: Integer): DWord;
      procedure SetMenuMode;
      procedure SetGameMode;
      procedure ApplyListenerChanges(VelocityFactor: Single = 1.0);
      function GetLength(BufferHandle: DWord): Single;
      procedure NewSoundSource(SoundSource: TSoundSource);
      procedure DeleteSoundSource(SoundSource: TSoundSource);
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, main, math;

const
  ALBools: Array[0..1] of ALEnum = (AL_FALSE, AL_TRUE);

destructor TSoundBuffer.Free;
begin
  alDeleteBuffers(1, @Buffer);
end;

function TModuleSoundOpenAL.GetNextFreeSourceID: Integer; inline;
begin
  for Result := 0 to high(alSourcesFree) do
    if alSourcesFree[Result] then
      exit;
  Result := -1;
end;

procedure TModuleSoundOpenAL.Advance;
var
  I, J: Integer;
  SourceState: ALInt;
  TmpPos, TmpDir: TVector3D;
  tmp: TSoundHandle;
  m: Single;
  mID: Integer;
begin
  for I := 0 to high(fSoundHandles) do
    fSoundHandles[I].SoundSource.Advance;

  for I := 0 to Min(AL_SOUND_SOURCES - 1, high(fSoundHandles)) do
    begin
    mID := I;
    m := fSoundHandles[I].SoundSource.ListenerStrength;
    for J := I + 1 to high(fSoundHandles) do
      begin
      if fSoundHandles[J].SoundSource.ListenerStrength > m then
        begin
        m := fSoundHandles[J].SoundSource.ListenerStrength;
        mID := J;
        end;
      end;
    tmp := fSoundHandles[I];
    fSoundHandles[I] := fSoundHandles[mID];
    fSoundHandles[mID] := tmp;
    end;

  for I := 0 to high(fSoundHandles) do
    if (fSoundHandles[I].ALSourceID = -1) and (I < AL_SOUND_SOURCES) then
      fSoundHandles[I].GainedALSource := True
    else if (fSoundHandles[I].ALSourceID <> -1) and (I >= AL_SOUND_SOURCES) then
      fSoundHandles[I].LostALSource := True;
  
  for I := 0 to high(fSoundHandles) do
    if fSoundHandles[I].LostALSource then
      begin
      fSoundHandles[I].LostALSource := False;
      alSourcesFree[fSoundHandles[I].ALSourceID] := True;
      alSourceStop(alTrueSources[fSoundHandles[I].ALSourceID]);
      fSoundHandles[I].ALSourceID := -1;
      end;
  for I := 0 to high(fSoundHandles) do
    begin
    if fSoundHandles[I].GainedALSource then
      begin
      fSoundHandles[I].GainedALSource := False;
      fSoundHandles[I].ALSourceID := GetNextFreeSourceID;
      if fSoundHandles[I].ALSourceID <> -1 then
        begin
        alSourcesFree[fSoundHandles[I].ALSourceID] := False;
        TmpDir := Vector3D(Vector(fSoundHandles[I].SoundSource.Direction, 0.0) * fSoundHandles[I].SoundSource.Matrix);
        TmpPos := Vector3D(Vector(fSoundHandles[I].SoundSource.Position, 1.0) * fSoundHandles[I].SoundSource.Matrix);
        alSourcei (alTrueSources[fSoundHandles[I].ALSourceID], AL_BUFFER,          fSoundBuffers[fSoundHandles[I].SoundSource.BufferHandle].Buffer);
        alSourcei (alTrueSources[fSoundHandles[I].ALSourceID], AL_SOURCE_RELATIVE, ALBools[fSoundHandles[I].SoundSource.Relative]);
        alSourcei (alTrueSources[fSoundHandles[I].ALSourceID], AL_LOOPING,         ALBools[fSoundHandles[I].SoundSource.Looping]);
        alSourcef (alTrueSources[fSoundHandles[I].ALSourceID], AL_GAIN,            fSoundHandles[I].SoundSource.Volume);
        alSourcef (alTrueSources[fSoundHandles[I].ALSourceID], AL_SEC_OFFSET,      fSoundHandles[I].SoundSource.PlayingOffset);
        alSourcef (alTrueSources[fSoundHandles[I].ALSourceID], AL_PITCH,           fSoundHandles[I].SoundSource.Pitch);
        alSourcefv(alTrueSources[fSoundHandles[I].ALSourceID], AL_POSITION,        @TmpPos);
        alSourcefv(alTrueSources[fSoundHandles[I].ALSourceID], AL_VELOCITY,        @fSoundHandles[I].SoundSource.Velocity);
        alSourcefv(alTrueSources[fSoundHandles[I].ALSourceID], AL_DIRECTION,       @TmpDir);
        if fSoundHandles[I].SoundSource.Playing = 1 then
          alSourcePlay(alTrueSources[fSoundHandles[I].ALSourceID]);
        end;
      end
    else if fSoundHandles[I].ALSourceID <> -1 then
      begin
      TmpDir := Vector3D(Vector(fSoundHandles[I].SoundSource.Direction, 0.0) * fSoundHandles[I].SoundSource.Matrix);
      TmpPos := Vector3D(Vector(fSoundHandles[I].SoundSource.Position, 1.0) * fSoundHandles[I].SoundSource.Matrix);
      SourceState := AL_PLAYING;
      alSourcei   (alTrueSources[fSoundHandles[I].ALSourceID], AL_SOURCE_RELATIVE, ALBools[fSoundHandles[I].SoundSource.Relative]);
      alSourcei   (alTrueSources[fSoundHandles[I].ALSourceID], AL_LOOPING,         ALBools[fSoundHandles[I].SoundSource.Looping]);
      alSourcef   (alTrueSources[fSoundHandles[I].ALSourceID], AL_GAIN,            fSoundHandles[I].SoundSource.Volume);
      alSourcef   (alTrueSources[fSoundHandles[I].ALSourceID], AL_PITCH,           fSoundHandles[I].SoundSource.Pitch);
      alSourcefv  (alTrueSources[fSoundHandles[I].ALSourceID], AL_POSITION,        @TmpPos);
      alSourcefv  (alTrueSources[fSoundHandles[I].ALSourceID], AL_VELOCITY,        @fSoundHandles[I].SoundSource.Velocity);
      alSourcefv  (alTrueSources[fSoundHandles[I].ALSourceID], AL_DIRECTION,       @TmpDir);
      alGetSourcei(alTrueSources[fSoundHandles[I].ALSourceID], AL_SOURCE_STATE,    SourceState);
      alGetSourcef(alTrueSources[fSoundHandles[I].ALSourceID], AL_SEC_OFFSET,      fSoundHandles[I].SoundSource.PlayingOffset);
      if (fSoundHandles[I].SoundSource.Playing = 0) and (SourceState = AL_PLAYING) then
        alSourcePause(alTrueSources[fSoundHandles[I].ALSourceID])
      else if (fSoundHandles[I].SoundSource.Playing = 1) and (SourceState <> AL_PLAYING) then
        alSourcePlay(alTrueSources[fSoundHandles[I].ALSourceID]);
      end;
    end;
end;

procedure TModuleSoundOpenAL.InitOpenAL;
begin
  alDevice := alcOpenDevice(nil);
  alContext := alcCreateContext(alDevice, nil);
  alcMakeContextCurrent(alContext);
end;

procedure TModuleSoundOpenAL.CloseOpenAL;
begin
  alcDestroyContext(alContext);
  alcCloseDevice(alDevice);
end;

function TModuleSoundOpenAL.AddSoundbuffer(Data: Pointer; Size: Integer; Channels: Integer; Rate: Integer): DWord;
const
  Formats: Array[1..2] of ALEnum = (AL_FORMAT_MONO16, AL_FORMAT_STEREO16);
begin
  setLength(fSoundBuffers, length(fSoundBuffers) + 1);
  fSoundBuffers[high(fSoundBuffers)] := TSoundBuffer.Create;
  alGenBuffers(1, @fSoundBuffers[high(fSoundBuffers)].Buffer);
  alBufferData(fSoundBuffers[high(fSoundBuffers)].Buffer, Formats[Channels], Data, Size, Rate);
  Result := High(fSoundBuffers);
end;

procedure TModuleSoundOpenAL.SetMenuMode;
begin
  alListener3f(AL_POSITION, 0, 0, 0);
  alListener3f(AL_VELOCITY, 0, 0, 0);
  alListener3f(AL_ORIENTATION, 0, 0, -1);
  fIsInMenuMode := True;
end;

procedure TModuleSoundOpenAL.SetGameMode;
begin
  fIsInMenuMode := False;
end;

procedure TModuleSoundOpenAL.ApplyListenerChanges(VelocityFactor: Single = 1.0);
var
  ListenerPos, ListenerVel: TVector3D;
  ListenerDir: Array[0..1] of TVector3D;
  AMatrix: TMatrix4D;
begin
  ListenerPos := ModuleManager.ModCamera.ActiveCamera.Position;
  ListenerVel := (ListenerPos - fPrevListenerPos) / FPSDisplay.MS * 1000;
  fPrevListenerPos := ListenerPos;
  AMatrix := RotationMatrix(ModuleManager.ModCamera.ActiveCamera.Rotation.X, Vector(-1, 0, 0));
  AMatrix := RotationMatrix(ModuleManager.ModCamera.ActiveCamera.Rotation.Y, Vector(0, -1, 0));
  ListenerDir[0] := Vector3D(Vector(0, 0, -1, 0) * AMatrix);
  AMatrix := RotationMatrix(ModuleManager.ModCamera.ActiveCamera.Rotation.Z, Vector(0, 0, -1));
  ListenerDir[1] := Vector3D(Vector(0, 1, 0, 0) * AMatrix);
  alListenerfv(AL_POSITION, @ListenerPos);
  alListenerfv(AL_VELOCITY, @ListenerVel);
  alListenerfv(AL_ORIENTATION, @ListenerDir[0]);
end;

procedure TModuleSoundOpenAL.NewSoundSource(SoundSource: TSoundSource);
begin
  setLength(fSoundHandles, length(fSoundHandles) + 1);
  fSoundHandles[high(fSoundHandles)].ALSourceID := -1;
  fSoundHandles[high(fSoundHandles)].SoundSource := SoundSource;
  fSoundHandles[high(fSoundHandles)].GainedALSource := False;
  fSoundHandles[high(fSoundHandles)].LostALSource := False;
end;

function TModuleSoundOpenAL.GetLength(BufferHandle: DWord): Single;
var
  BufferID: ALUInt;
  Size, Channels, Frequency, BitsPerSample: ALInt;
begin
  BufferID := fSoundBuffers[BufferHandle].Buffer;
  alGetBufferi(BufferID, AL_SIZE, Size);
  alGetBufferi(BufferID, AL_FREQUENCY, Frequency);
  alGetBufferi(BufferID, AL_CHANNELS, Channels);
  alGetBufferi(BufferID, AL_BITS, BitsPerSample);
  Result := Size / (Channels * Frequency * BitsPerSample / 8);
end;

procedure TModuleSoundOpenAL.DeleteSoundSource(SoundSource: TSoundSource);
var
  I: Integer;
begin
  for I := 0 to high(fSoundHandles) do
    if fSoundHandles[I].SoundSource = SoundSource then
      begin
      if fSoundHandles[I].ALSourceID <> -1 then
        begin
        alSourcesFree[fSoundHandles[I].ALSourceID] := True;
        alSourceStop(alTrueSources[fSoundHandles[I].ALSourceID]);
        end;
      fSoundHandles[I] := fSoundHandles[high(fSoundHandles)];
      setLength(fSoundHandles, length(fSoundHandles) - 1);
      exit;
      end;
  ModuleManager.ModLog.AddError('Something went wrong deleting a sound source');
end;

procedure TModuleSoundOpenAL.CheckModConf;
begin
end;

constructor TModuleSoundOpenAL.Create;
var
  i: Integer;
begin
  fModName := 'SoundOpenAL';
  fModType := 'Sound';

  InitOpenAL;

  fPrevListenerPos := Vector(0, 0, 0);
  SetMenuMode;

  alGenSources(AL_SOUND_SOURCES, @alTrueSources[0]);
  for I := 0 to AL_SOUND_SOURCES - 1 do
    alSourcesFree[I] := True;
end;

destructor TModuleSoundOpenAL.Free;
var
  I: Integer;
begin
  for I := 0 to high(fSoundBuffers) do
    fSoundBuffers[I].Free;
  alDeleteSources(AL_SOUND_SOURCES, @alTrueSources[0]);
  CloseOpenAL;
end;

end.