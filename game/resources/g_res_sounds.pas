unit g_res_sounds;

interface

uses
  SysUtils, Classes, m_sound_class, g_resources, g_loader_ocf, vorbis;

type
  TSoundResource = class;

  TSoundDecoderThread = class(TThread)
    private
      Data: TOCFFile;
      fSoundResource: TSoundResource;
      fDone: Boolean;
      TotalBytesRead: long;
      procedure Execute; override;
    end;

  TSoundResource = class(TAbstractResource)
    private
      Audio: Array of Byte;
      fRate, fChannels: Integer;
      fSoundSource: TSoundSource;
      fThread: TSoundDecoderThread;
    public
      property SoundSource: TSoundSource read fSoundSource;
      class function Get(ResourceName: String): TSoundResource;
      constructor Create(ResourceName: String);
      procedure CheckDecoderState(Event: String; Data, Result: Pointer);
      procedure FileLoaded(Data: TOCFFile);
      procedure Free;
    end;

implementation

uses
  u_graphics, u_events, m_varlist;

type
  TVorbisDataSource = record
    Bytes, BytesRead: Integer;
    FirstByte: PByte;
    end;

function ReadFunc(ptr: Pointer; size, nmemb: size_t; datasource: Pointer): size_t; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
var
  BytesRead, BytesToRead, I: Integer;
  A: PByte;
begin
  Result := 0;
  A := TVorbisDataSource(datasource^).FirstByte;
  BytesRead := 0;
  BytesToRead := TVorbisDataSource(datasource^).Bytes - TVorbisDataSource(datasource^).BytesRead;
  if BytesRead >= size * nmemb then
    begin
    BytesRead := size * nmemb;
    for I := 0 to BytesRead - 1 do
      begin
      Byte(ptr^) := A^;
      inc(ptr);
      inc(A);
      end;
    Result := nmemb;
    end
  else
    while (Result < nmemb) and (BytesRead < BytesToRead) do
      begin
      Byte(ptr^) := A^;
      inc(ptr);
      inc(A);
      inc(BytesRead);
      Result := BytesRead div size;
      end;
  TVorbisDataSource(datasource^).BytesRead := TVorbisDataSource(datasource^).BytesRead + BytesRead;
  TVorbisDataSource(datasource^).FirstByte := A;
end;

procedure TSoundDecoderThread.Execute;
var
  Callbacks: ov_callbacks;
  A: TVorbisDataSource;
  fv: OggVorbis_File;
  BytesRead: long;
  S: Integer;
begin
  try
    with Data.ResourceByName(fSoundResource.SubResourceName) do
      begin
      Callbacks.read_func := @ReadFunc;
      Callbacks.seek_func := nil;
      Callbacks.close_func := nil;
      Callbacks.tell_func := nil;

      A.Bytes := Length(Data.Bin[Section].Stream.Data);
      A.BytesRead := 0;
      A.FirstByte := @Data.Bin[Section].Stream.Data[0];

      SetLength(fSoundResource.Audio, 0);
      TotalBytesRead := 0;

      S := 0;

      ov_open_callbacks(@A, @fv, nil, 0, Callbacks);
      repeat
        if Length(fSoundResource.Audio) < TotalBytesRead + 4096 then
          setLength(fSoundResource.Audio, Length(fSoundResource.Audio) + 262144);
        BytesRead := ov_read(@fv, @fSoundResource.Audio[TotalBytesRead], 4096, 0, 2, 1, @S);
        inc(TotalBytesRead, BytesRead);
      until
        BytesRead <= 0;

      if TotalBytesRead <= 0 then
        writeln('Failed to load sound resource: ' + fSoundResource.GetFullName);

      fSoundResource.fChannels := fv.vi^.channels;
      fSoundResource.fRate := fv.vi^.rate;

      ov_clear(@fv);
      end;
    fDone := True;
  except
    writeln('Error in sound decoder thread');
    end;
end;

class function TSoundResource.Get(ResourceName: String): TSoundResource;
begin
  Result := TSoundResource(ResourceManager.Resources[ResourceName]);
  if Result = nil then
    Result := TSoundResource.Create(ResourceName)
  else
    ResourceManager.AddFinishedResource(Result);
end;

constructor TSoundResource.Create(ResourceName: String);
begin
  fSoundSource := nil;
  fThread := nil;
  inherited Create(ResourceName, @FileLoaded);
end;

procedure TSoundResource.FileLoaded(Data: TOCFFile);
begin
  with Data.ResourceByName(SubResourceName) do
    begin
    if Format = 'oggvorbis' then
      begin
      fThread := TSoundDecoderThread.Create(True);
      fThread.Data := Data;
      fThread.fSoundResource := Self;
      fThread.fDone := False;
      fThread.Resume;
      EventManager.AddCallback('MainLoop', @CheckDecoderState);
      end;
    end;
end;

procedure TSoundResource.CheckDecoderState(Event: String; Data, Result: Pointer);
begin
  if fThread.fDone then
    begin
    fSoundSource := TSoundSource.Create(ModuleManager.ModSound.AddSoundBuffer(@Audio[0], fThread.TotalBytesRead, fChannels, fRate));
    SetLength(Audio, 0);
    fThread.Free;
    fThread := nil;
    FinishedLoading := True;
    EventManager.RemoveCallback('MainLoop', @CheckDecoderState);
    writeln('Hint: Finished sound resource: ' + GetFullName);
    end;
end;

procedure TSoundResource.Free;
begin
  if fSoundSource <> nil then
    fSoundSource.Free;
  if fThread <> nil then
    fThread.Free;
  inherited Free;
end;

end.