unit m_sound_class;

interface

uses
  SysUtils, Classes, u_vectors, m_module;

type
  TModuleSoundClass = class(TBasicModule)
    public
      procedure SetMenuMode; virtual abstract;
      procedure SetGameMode; virtual abstract;
      procedure ApplyListenerChanges(VelocityFactor: Single = 1.0); virtual abstract;
      procedure ApplySoundSourceChange(Handle: DWord; Position, Direction: TVector3D); virtual abstract;
      procedure ApplySoundPropertyChange(Handle: DWord; Volume: Single; Looping: Boolean); virtual abstract;
      procedure PlaySound(Handle: DWord); virtual abstract;
      function NewSoundSource(Soundfile: String): DWord; virtual abstract;
      procedure DeleteSoundSource(Handle: DWord); virtual abstract;
    end;

  TSoundSource = class
    protected
      fHandle: DWord;
      fSoundFile: String;
    public
      Position, Direction: TVector3D;
      Looping: Boolean;
      Volume: Single;
      property Handle: DWord read fHandle;
      property SoundFileName: String read fSoundFile;
      procedure ApplyMatrix(M: TMatrix4D);
      procedure Play;
      function Duplicate: TSoundSource;
      constructor Create(Soundfile: String);
      destructor Free;
    end;

implementation

uses
  m_varlist;

procedure TSoundSource.ApplyMatrix(M: TMatrix4D);
begin
  ModuleManager.ModSound.ApplySoundSourceChange(fHandle, Vector3D(Vector(Position, 1.0) * M), Vector3D(Vector(Direction, 0.0) * M));
  ModuleManager.ModSound.ApplySoundPropertyChange(fHandle, Volume, Looping);
end;

procedure TSoundSource.Play;
begin
  ModuleManager.ModSound.PlaySound(fHandle);
end;

function TSoundSource.Duplicate: TSoundSource;
begin
  Result := TSoundSource.Create(fSoundFile);
  Result.Position := Position;
  Result.Direction := Direction;
  Result.Looping := Looping;
  Result.Volume := Volume;
  ModuleManager.ModSound.ApplySoundSourceChange(Result.Handle, Result.Position, Result.Direction);
  ModuleManager.ModSound.ApplySoundPropertyChange(Result.fHandle, Result.Volume, Result.Looping);
end;

constructor TSoundSource.Create(Soundfile: String);
begin
  fSoundFile := Soundfile;
  fHandle := ModuleManager.ModSound.NewSoundSource(Soundfile);
  Position := Vector(0, 0, 0);
  Direction := Vector(0, 0, 0);
  Volume := 1.0;
  Looping := True;
  ModuleManager.ModSound.ApplySoundSourceChange(fHandle, Position, Direction);
  ModuleManager.ModSound.ApplySoundPropertyChange(fHandle, Volume, Looping);
end;

destructor TSoundSource.Free;
begin
  ModuleManager.ModSound.DeleteSoundSource(fHandle);
end;

end.