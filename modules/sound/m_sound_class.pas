unit m_sound_class;

interface

uses
  SysUtils, Classes, u_vectors, m_module, u_scripts, m_scriptmng_class;

type
  TModuleSoundClass = class(TBasicModule)
    public
      function AddSoundbuffer(Data: Pointer; Size: Integer; Channels: Integer; Rate: Integer): DWord; virtual abstract;
      procedure SetMenuMode; virtual abstract;
      procedure SetGameMode; virtual abstract;
      procedure ApplyListenerChanges(VelocityFactor: Single = 1.0); virtual abstract;
      procedure ApplySoundSourceChange(Handle: DWord; Position, Direction: TVector3D); virtual abstract;
      procedure ApplySoundPropertyChange(Handle: DWord; Volume: Single; Looping, Relative: Boolean); virtual abstract;
      procedure PlaySound(Handle: DWord); virtual abstract;
      function NewSoundSource(BufferHandle: DWord): DWord; virtual abstract;
      function GetLength(BufferHandle: DWord): Single; virtual abstract;
      function GetPlayingOffset(SourceHandle: DWord): Single; virtual abstract;
      function IsRunning(SourceHandle: DWord): Boolean; virtual abstract;
      procedure DeleteSoundSource(Handle: DWord); virtual abstract;
    end;

  TSoundSource = class
    private
      fHandle, fBufferHandle: DWord;
      fLength: Single;
      fHasPlayed: Boolean;
    public
      Position, Direction: TVector3D;
      Looping, Playing: SInt;
      Volume: Single;
      Relative: Boolean;
      property Handle: DWord read fHandle;
      property BufferHandle: DWord read fBufferHandle;
      property TrackLength: Single read fLength;
      property HasPlayed: Boolean read fHasPlayed;
      procedure UpdateProperties;
      procedure ApplyMatrix(M: TMatrix4D);
      procedure Play;
      function Duplicate: TSoundSource;
      function GetCurrentPlayingOffset: Single;
      function IsRunning: Boolean;
      procedure SetIO(Script: TScript);
      class procedure RegisterStruct;
      constructor Create(Buffer: DWord);
      destructor Free;
    end;

implementation

uses
  m_varlist;

var
  ioSize: Integer;

procedure TSoundSource.UpdateProperties;
begin
  ModuleManager.ModSound.ApplySoundPropertyChange(fHandle, Volume, Looping <> 0, Relative);
end;

procedure TSoundSource.ApplyMatrix(M: TMatrix4D);
begin
  ModuleManager.ModSound.ApplySoundSourceChange(fHandle, Vector3D(Vector(Position, 1.0) * M), Vector3D(Vector(Direction, 0.0) * M));
  UpdateProperties;
end;

procedure TSoundSource.Play;
begin
  ModuleManager.ModSound.PlaySound(fHandle);
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
  ModuleManager.ModSound.ApplySoundSourceChange(Result.Handle, Result.Position, Result.Direction);
  Result.UpdateProperties;
end;

function TSoundSource.GetCurrentPlayingOffset: Single;
begin
  Result := ModuleManager.ModSound.GetPlayingOffset(fHandle);
end;

function TSoundSource.IsRunning: Boolean;
begin
  Result := ModuleManager.ModSound.IsRunning(fHandle);
end;

procedure TSoundSource.SetIO(Script: TScript);
begin
  Script.SetIO(@Position, ioSize - SizeOf(Single), True);
  Script.SetIO(@fLength, SizeOf(Single), False);
  if Playing <> 0 then
    Play;
  Playing := 0;
end;

class procedure TSoundSource.RegisterStruct;
begin
  ModuleManager.ModScriptManager.SetDataStructure('SoundSource',
   'vec3 position' + #10 +
   'vec3 direction' + #10 +
   'int looping' + #10 +
   'int play' + #10 +
   'float volume' + #10 +
   'float length');
  ioSize := ModuleManager.ModScriptManager.DataStructureSize('SoundSource');
end;

constructor TSoundSource.Create(Buffer: DWord);
begin
  fHandle := ModuleManager.ModSound.NewSoundSource(Buffer);
  fBufferHandle := Buffer;
  Position := Vector(0, 0, 0);
  Direction := Vector(0, 0, 0);
  Volume := 1.0;
  Looping := 1;
  fLength := ModuleManager.ModSound.GetLength(Buffer);
  ModuleManager.ModSound.ApplySoundSourceChange(fHandle, Position, Direction);
  UpdateProperties;
  fHasPlayed := False;
  Relative := False;
end;

destructor TSoundSource.Free;
begin
  ModuleManager.ModSound.DeleteSoundSource(fHandle);
end;

end.