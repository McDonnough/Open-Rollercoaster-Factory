unit m_sound_openal;

interface

uses
  SysUtils, Classes, openal, u_vectors, u_math, m_sound_class;

type
  TSoundBuffer = class
    Buffer: TALUInt;
    destructor Free;
    end;

  TSoundHandle = class
    Initialized: Boolean;
    PrevPosition: TVector3D;
    Source: TALUInt;
    destructor Free;
    end;

  TModuleSoundOpenAL = class(TModuleSoundClass)
    protected
      fSoundHandles: Array of TSoundHandle;
      fSoundBuffers: Array of TSoundBuffer;
      fPrevListenerPos: TVector3D;
      fMenuMode: Boolean;
    public
      function AddSoundbuffer(Data: Pointer; Size: Integer; Channels: Integer; Rate: Integer): DWord;
      procedure SetMenuMode;
      procedure SetGameMode;
      procedure ApplyListenerChanges(VelocityFactor: Single = 1.0);
      procedure ApplySoundSourceChange(Handle: DWord; Position, Direction: TVector3D);
      procedure ApplySoundPropertyChange(Handle: DWord; Volume: Single; Looping: Boolean);
      procedure PlaySound(Handle: DWord);
      function NewSoundSource(BufferHandle: DWord): DWord;
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

function TModuleSoundOpenAL.AddSoundbuffer(Data: Pointer; Size: Integer; Channels: Integer; Rate: Integer): DWord;
const
  Formats: Array[1..2] of TALEnum = (AL_FORMAT_MONO16, AL_FORMAT_STEREO16);
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
begin
  ListenerPos := ModuleManager.ModCamera.ActiveCamera.Position;
  ListenerVel := (ListenerPos - fPrevListenerPos) / FPSDisplay.MS * 1000;
  fPrevListenerPos := ListenerPos;
  ListenerDir[0] := Vector3D(Vector(0, 0, -1, 0) * ModuleManager.ModCamera.ActiveCamera.Matrix);
  ListenerDir[1] := Vector(0, 1, 0);
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

procedure TModuleSoundOpenAL.ApplySoundPropertyChange(Handle: DWord; Volume: Single; Looping: Boolean);
begin
  if Looping then
    AlSourcei(fSoundHandles[Handle].Source, AL_LOOPING, AL_TRUE)
  else
    AlSourcei(fSoundHandles[Handle].Source, AL_LOOPING, AL_FALSE);
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

procedure TModuleSoundOpenAL.DeleteSoundSource(Handle: DWord);
begin
  fSoundHandles[Handle].Free;
  fSoundHandles[Handle] := nil;
end;

procedure TModuleSoundOpenAL.CheckModConf;
begin
end;

constructor TModuleSoundOpenAL.Create;
var
  argv: Array of PALByte;
begin
  fModName := 'SoundOpenAL';
  fModType := 'Sound';

  InitOpenAL;
  alutInit(nil, argv);

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
  alutExit();
end;

end.