unit m_backgroundmusic_default;

interface

uses
  SysUtils, Classes, m_backgroundmusic_class, g_music, m_sound_class, math, u_math, g_res_sounds,
  m_gui_class, m_gui_label_class, m_gui_image_class, m_texmng_class;

type
  TModuleBackgroundMusicDefault = class(TModuleBackgroundMusicClass)
    protected
      fCurrentSong, fNextSong: TSong;
      fCurrentSoundSource, fNextSoundSource: TSoundSource;
      fVolume, fDisplayTime: Single;
      fFadingNext, fFadingCurrent: Single;
      fTrackName, fAlbumName, fArtistName, fGenre: TLabel;
      fBackgroundImage, fIcon: TImage;
      ResX, ResY: Integer;
      fDisplaying: Boolean;
      function GetRandomSong: TSong;
      procedure Display(Song: TSong);
      procedure AdvanceSongs;
      procedure AssignNextSong(Event: String; Data, Result: Pointer);
    public
      procedure Advance;
      procedure SetVolume(V: Single);
      procedure CheckModConf;
      constructor Create;
    end;

implementation

uses
  u_events, m_varlist, u_vectors, main;

function TModuleBackgroundMusicDefault.GetRandomSong: TSong;
var
  C: Integer;
begin
  C := Round((MusicManager.Songs.Count - 1) * Random);
  Result := TSong(MusicManager.Songs.First);
  while C > 0 do
    begin
    Result := TSong(Result.Next);
    Dec(C);
    end;
end;

procedure TModuleBackgroundMusicDefault.Display(Song: TSong);
begin
  fDisplaying := True;
  fDisplayTime := 0;
  fBackgroundImage.Left := ResX - 384;
  fTrackName.Caption := Song.Title;
  fAlbumName.Caption := 'On: $' + Song.Album.Name + '$';
  fArtistName.Caption := 'By: $' + Song.Album.Artist.Name + '$';
  fGenre.Caption := Song.Genre;
end;

procedure TModuleBackgroundMusicDefault.AdvanceSongs;
begin
  fCurrentSong := fNextSong;
  if fCurrentSoundSource <> nil then
    fCurrentSoundSource.Free;
  fCurrentSoundSource := fNextSoundSource;
  fNextSong := GetRandomSong;
  fNextSoundSource := nil;
  if fNextSong <> nil then
    begin
    EventManager.AddCallback('TResource.FinishedLoading:' + fNextSong.OriginalResourceName, @AssignNextSong);
    fNextSong.Resource;
    end;
end;

procedure TModuleBackgroundMusicDefault.AssignNextSong(Event: String; Data, Result: Pointer);
begin
  fNextSoundSource := TSoundResource(Data).SoundSource.Duplicate;
  fNextSoundSource.Looping := 0;
  fNextSoundSource.Relative := True;
  EventManager.RemoveCallback(Event, @AssignNextSong);
end;

procedure TModuleBackgroundMusicDefault.Advance;
begin
  if fNextSong = nil then
    AdvanceSongs;
  if fNextSoundSource <> nil then
    begin
    fNextSoundSource.UpdateProperties;
    if fCurrentSoundSource = nil then
      begin
      fNextSoundSource.Play;
      Display(fNextSong);
      AdvanceSongs;
      end
    else
      begin
      if (not fCurrentSoundSource.IsRunning) and (fCurrentSoundSource.HasPlayed) then
        begin
        fNextSoundSource.Play;
        Display(fNextSong);
        AdvanceSongs;
        end;
      end;
    end;
  if fCurrentSoundSource <> nil then
    fCurrentSoundSource.UpdateProperties;
  if fDisplaying then
    begin
    fDisplayTime := fDisplayTime + FPSDisplay.MS / 1000;
    if fDisplayTime > 3 then
      begin
      fBackgroundImage.Left := ResX + 8;
      fDisplaying := False;
      end;
    end;
end;

procedure TModuleBackgroundMusicDefault.SetVolume(V: Single);
begin
  fVolume := V;
  if fCurrentSoundSource <> nil then
    fCurrentSoundSource.Volume := V;
  if fNextSoundSource <> nil then
    fNextSoundSource.Volume := V;
end;

procedure TModuleBackgroundMusicDefault.CheckModConf;
begin
end;

constructor TModuleBackgroundMusicDefault.Create;
begin
  fModName := 'BackgroundMusicDefault';
  fModType := 'BackgroundMusic';

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);

  SetVolume(1.0);

  fCurrentSong := nil;
  fCurrentSoundSource := nil;
  fNextSong := nil;
  fNextSoundSource := nil;

  fBackgroundImage := TImage.Create(nil);
  fBackgroundImage.Width := 384;
  fBackgroundImage.Height := 96;
  fBackgroundImage.Left := ResX + 8;
  fBackgroundImage.Top := ResY - 96;
  fBackgroundImage.FreeTextureOnDestroy := True;
  fBackgroundImage.Tex := TTexture.Create;
  fBackgroundImage.Tex.FromFile('backgroundmusic/song-display.tga');

  fTrackName := TLabel.Create(fBackgroundImage);
  fTrackName.TextColor := Vector(1, 1, 1, 1);
  fTrackName.Left := 16;
  fTrackName.Top := 16;
  fTrackName.Width := 368;
  fTrackName.Size := 24;
  fTrackName.Height := 24;

  fArtistName := TLabel.Create(fBackgroundImage);
  fArtistName.TextColor := Vector(1, 1, 1, 1);
  fArtistName.Left := 72;
  fArtistName.Top := 40;
  fArtistName.Width := 312;
  fArtistName.Size := 16;
  fArtistName.Height := 16;

  fAlbumName := TLabel.Create(fBackgroundImage);
  fAlbumName.TextColor := Vector(1, 1, 1, 1);
  fAlbumName.Left := 72;
  fAlbumName.Top := 56;
  fAlbumName.Width := 312;
  fAlbumName.Size := 16;
  fAlbumName.Height := 16;

  fGenre := TLabel.Create(fBackgroundImage);
  fGenre.TextColor := Vector(1, 1, 1, 1);
  fGenre.Left := 72;
  fGenre.Top := 72;
  fGenre.Width := 312;
  fGenre.Size := 16;
  fGenre.Height := 16;

  fDisplaying := False;
  fDisplayTime := 0;
end;

end.