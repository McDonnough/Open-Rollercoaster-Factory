unit m_sound_class;

interface

uses
  SysUtils, Classes, u_vectors, m_module, u_scripts, m_scriptmng_class;

type
  TSoundSource = class;

  TModuleSoundClass = class(TBasicModule)
    protected
      fIsInMenuMode: Boolean;
    public
      property IsInMenuMode: Boolean read fIsInMenuMode;
      procedure Advance; virtual abstract;
      function AddSoundbuffer(Data: Pointer; Size: Integer; Channels: Integer; Rate: Integer): DWord; virtual abstract;
      procedure SetMenuMode; virtual abstract;
      procedure SetGameMode; virtual abstract;
      procedure ApplyListenerChanges(VelocityFactor: Single = 1.0); virtual abstract;
      function GetLength(BufferHandle: DWord): Single; virtual abstract;
      procedure NewSoundSource(SoundSource: TSoundSource); virtual abstract;
      procedure DeleteSoundSource(SoundSource: TSoundSource); virtual abstract;
    end;

  TSoundSource = class
    private
      fBufferHandle: DWord;
      fLength: Single;
      fListenerStrength: Single;
      fHasPlayed: Boolean;
    public
      Matrix: TMatrix4D;
      PlayingOffset: Single;
      PrevPosition, Velocity: TVector3D;
      Position, Direction: TVector3D;
      Looping, Playing: SInt;
      Volume, Pitch: Single;
      Relative: SInt;
      property ListenerStrength: Single read fListenerStrength;
      property BufferHandle: DWord read fBufferHandle;
      property TrackLength: Single read fLength;
      property HasPlayed: Boolean read fHasPlayed;
      procedure Play;
      function Duplicate: TSoundSource;
      procedure CalculateListenerStrength;
      procedure SetIO(Script: TScript);
      procedure Advance;
      class procedure RegisterStruct;
      constructor Create(Buffer: DWord);
      destructor Free;
    end;

implementation

uses
  m_varlist, main;

var
  ioSize: Integer;

procedure TSoundSource.Play;
begin
  Playing := 1;
  fHasPlayed := True;
end;

function TSoundSource.Duplicate: TSoundSource;
begin
  Result := TSoundSource.Create(BufferHandle);
  Result.Position := Position;
  Result.Direction := Direction;
  Result.Looping := Looping;
  Result.Volume := Volume;
  Result.fBufferHandle := BufferHandle;
end;

procedure TSoundSource.CalculateListenerStrength;
begin
  if (Relative = 1) or (ModuleManager.ModSound.IsInMenuMode) then
    fListenerStrength := Playing * Volume / (0.01 + VecLengthNoRoot(Vector3D(Vector(Position, 1.0) * Matrix)))
  else
    fListenerStrength := Playing * Volume / (0.01 + VecLengthNoRoot(Vector3D(Vector(Position, 1.0) * Matrix) - ModuleManager.ModCamera.ActiveCamera.Position));
end;

procedure TSoundSource.SetIO(Script: TScript);
begin
  Script.SetIO(@Position, ioSize - SizeOf(Single), True);
  Script.SetIO(@fLength, SizeOf(Single), False);
end;

procedure TSoundSource.Advance;
begin
  CalculateListenerStrength;
  Velocity := (Vector3D(Vector(Position, 1.0) * Matrix) - PrevPosition) / FPSDisplay.MS * 1000;
  PrevPosition := Vector3D(Vector(Position, 1.0) * Matrix);
  if Playing = 1 then
    begin
    PlayingOffset += 0.001 * FPSDisplay.MS;
    if PlayingOffset > fLength then
      if Looping = 1 then
        PlayingOffset -= fLength
      else
        begin
        Playing := 0;
        PlayingOffset := fLength;
        end;
    end;
end;

class procedure TSoundSource.RegisterStruct;
begin
  ModuleManager.ModScriptManager.SetDataStructure('SoundSource',
   'vec3 position' + #10 +
   'vec3 direction' + #10 +
   'int looping' + #10 +
   'int play' + #10 +
   'float volume' + #10 +
   'float pitch' + #10 +
   'float length');
  ioSize := ModuleManager.ModScriptManager.DataStructureSize('SoundSource');
end;

constructor TSoundSource.Create(Buffer: DWord);
begin
  fBufferHandle := Buffer;
  Position := Vector(0, 0, 0);
  PrevPosition := Vector(0, 0, 0);
  Velocity := Vector(0, 0, 0);
  Direction := Vector(0, 0, 0);
  Volume := 1.0;
  Looping := 1;
  Playing := 0;
  Pitch := 1.0;
  PlayingOffset := 0;
  Relative := 0;
  fHasPlayed := False;
  fLength := ModuleManager.ModSound.GetLength(Buffer);
  ModuleManager.ModSound.NewSoundSource(Self);
end;

destructor TSoundSource.Free;
begin
  ModuleManager.ModSound.DeleteSoundSource(Self);
end;

end.