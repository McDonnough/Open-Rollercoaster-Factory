unit g_res_sounds;

interface

uses
  SysUtils, Classes, m_sound_class, g_resources, g_loader_ocf, vorbis;

type
  TSoundResource = class(TAbstractResource)
    protected
      fSoundSource: TSoundSource;
    public
      property SoundSource: TSoundSource read fSoundSource;
      class function Get(ResourceName: String): TSoundResource;
      constructor Create(ResourceName: String);
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
  inherited Create(ResourceName, @FileLoaded);
end;

procedure TSoundResource.FileLoaded(Data: TOCFFile);
var
  Audio: Array of Byte;
  Callbacks: ov_callbacks;
  A: TVorbisDataSource;
  fv: OggVorbis_File;
  TotalBytesRead, BytesRead: long;
  
  S: Integer;
begin
  with Data.ResourceByName(SubResourceName) do
    begin
    if Format = 'oggvorbis' then
      begin
      Callbacks.read_func := @ReadFunc;
      Callbacks.seek_func := nil;
      Callbacks.close_func := nil;
      Callbacks.tell_func := nil;

      A.Bytes := Length(Data.Bin[Section].Stream.Data);
      A.BytesRead := 0;
      A.FirstByte := @Data.Bin[Section].Stream.Data[0];

      SetLength(Audio, 0);
      TotalBytesRead := 0;
      
      S := 0;

      ov_open_callbacks(@A, @fv, nil, 0, Callbacks);
      repeat
        if Length(Audio) < TotalBytesRead + 4096 then
          setLength(Audio, Length(Audio) + 262144);
        BytesRead := ov_read(@fv, @Audio[TotalBytesRead], 4096, 0, 2, 1, @S);
        inc(TotalBytesRead, BytesRead);
        if TotalBytesRead < 0 then
          halt(1);
      until
        BytesRead = 0;

      fSoundSource := TSoundSource.Create(ModuleManager.ModSound.AddSoundBuffer(@Audio[0], TotalBytesRead, fv.vi^.channels, fv.vi^.rate));
      SetLength(Audio, 0);

      ov_clear(@fv);
      end;
    end;
  FinishedLoading := True;
end;

procedure TSoundResource.Free;
begin
  if fSoundSource <> nil then
    fSoundSource.Free;
  inherited Free;
end;

end.