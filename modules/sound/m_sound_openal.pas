unit m_sound_openal;

interface

uses
  SysUtils, Classes, openal, u_vectors, u_math, m_sound_class;

type
  TSoundBuffer = class
    Buffer: ALUInt;
    destructor Free;
    end;

  TSoundHandle = class
    Initialized: Boolean;
    PrevPosition: TVector3D;
    Source: ALUInt;
    destructor Free;
    end;

  TModuleSoundOpenAL = class(TModuleSoundClass)
    protected
      fSoundHandles: Array of TSoundHandle;
      fSoundBuffers: Array of TSoundBuffer;
      fPrevListenerPos: TVector3D;
      fMenuMode: Boolean;
      alDevice: PALCdevice;
      alContext: PALCcontext;
      procedure InitOpenAL;
      procedure CloseOpenAL;
    public
      function AddSoundbuffer(Data: Pointer; Size: Integer; Channels: Integer; Rate: Integer): DWord;
      procedure SetMenuMode;
      procedure SetGameMode;
      procedure ApplyListenerChanges(VelocityFactor: Single = 1.0);
      procedure ApplySoundSourceChange(Handle: DWord; Position, Direction: TVector3D);
      procedure ApplySoundPropertyChange(Handle: DWord; Volume: Single; Looping, Relative: Boolean);
      procedure PlaySound(Handle: DWord);
      function NewSoundSource(BufferHandle: DWord): DWord;
      function GetLength(BufferHandle: DWord): Single;
      function GetPlayingOffset(SourceHandle: DWord): Single;
      function IsRunning(SourceHandle: DWord): Boolean;
      procedure DeleteSoundSource(Handle: DWord);
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, main;

destructor TSoundBuffer.Free;
begin
  alDeleteBuffers(1, @Buffer);
end;


destructor TSoundHandle.Free;
begin
  alDeleteSources(1, @Source);
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
end;

procedure TModuleSoundOpenAL.SetMenuMode;
begin
  fMenuMode := True;
  alListener3f(AL_POSITION, 0, 0, 0);
  alListener3f(AL_VELOCITY, 0, 0, 0);
  alListener3f(AL_ORIENTATION, 0, 0, -1);
end;

procedure TModuleSoundOpenAL.SetGameMode;
begin
  fMenuMode := False;
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

procedure TModuleSoundOpenAL.ApplySoundSourceChange(Handle: DWord; Position, Direction: TVector3D);
var
  Velocity: TVector3D;
begin
  Velocity := (Position - fSoundHandles[Handle].PrevPosition) / FPSDisplay.MS * 1000;
  alSourcefv(fSoundHandles[Handle].Source, AL_POSITION, @Position);
  if fSoundHandles[Handle].Initialized then
    alSourcefv(fSoundHandles[Handle].Source, AL_VELOCITY, @Velocity);
  alSourcefv(fSoundHandles[Handle].Source, AL_DIRECTION , @Direction);
  fSoundHandles[Handle].Initialized := True;
  fSoundHandles[Handle].PrevPosition := Position;
end;

procedure TModuleSoundOpenAL.ApplySoundPropertyChange(Handle: DWord; Volume: Single; Looping, Relative: Boolean);
begin
  if Looping then
    AlSourcei(fSoundHandles[Handle].Source, AL_LOOPING, AL_TRUE)
  else
    AlSourcei(fSoundHandles[Handle].Source, AL_LOOPING, AL_FALSE);
  if Relative then
    AlSourcei(fSoundHandles[Handle].Source, AL_SOURCE_RELATIVE, AL_TRUE)
  else
    AlSourcei(fSoundHandles[Handle].Source, AL_SOURCE_RELATIVE, AL_FALSE);
  alSourcef(fSoundHandles[Handle].Source, AL_GAIN, Volume);
  alSourcef(fSoundHandles[Handle].Source, AL_PITCH, 1.0);
end;

procedure TModuleSoundOpenAL.PlaySound(Handle: DWord);
begin
  alSourcePlay(fSoundHandles[Handle].Source);
end;

function TModuleSoundOpenAL.NewSoundSource(BufferHandle: DWord): DWord;
begin
  setLength(fSoundHandles, length(fSoundHandles) + 1 );
  Result := high(fSoundHandles);

  fSoundHandles[Result] := TSoundHandle.Create;
  fSoundHandles[Result].Initialized := False;
  alGenSources(1, @fSoundHandles[Result].Source);
  alSourcei(fSoundHandles[Result].Source, AL_BUFFER, fSoundBuffers[BufferHandle].Buffer);
  alSourcef(fSoundHandles[Result].Source, AL_PITCH, 1.0);
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

function TModuleSoundOpenAL.GetPlayingOffset(SourceHandle: DWord): Single;
begin
  alGetSourcef(fSoundHandles[SourceHandle].Source, AL_SEC_OFFSET, Result);
end;

function TModuleSoundOpenAL.IsRunning(SourceHandle: DWord): Boolean;
var
  V: ALInt;
begin
  alGetSourcei(fSoundHandles[SourceHandle].Source, AL_SOURCE_STATE, V);
  Result := V = AL_PLAYING;
end;

procedure TModuleSoundOpenAL.DeleteSoundSource(Handle: DWord);
begin
  fSoundHandles[Handle].Free;
  fSoundHandles[Handle] := nil;
end;

procedure TModuleSoundOpenAL.CheckModConf;
begin
end;

constructor TModuleSoundOpenAL.Create;
begin
  fModName := 'SoundOpenAL';
  fModType := 'Sound';

  InitOpenAL;

  fPrevListenerPos := Vector(0, 0, 0);
  SetMenuMode;
end;

destructor TModuleSoundOpenAL.Free;
var
  I: Integer;
begin
  for I := 0 to high(fSoundHandles) do
    if fSoundHandles[I] <> nil then
      fSoundHandles[I].Free;
  for I := 0 to high(fSoundBuffers) do
    fSoundBuffers[I].Free;
  CloseOpenAL;
end;

end.