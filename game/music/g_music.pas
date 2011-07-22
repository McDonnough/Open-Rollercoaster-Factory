unit g_music;

interface

uses
  SysUtils, Classes, m_sound_class, g_res_sounds, u_linkedlists, g_res_rawxml;

type
  TSongAlbum = class;
  TSong = class;

  TAlbumArtist = class(TLinkedListItem)
    private
      fName: String;
    public
      property Name: String read fName;
    end;

  TSongAlbum = class(TLinkedListItem)
    private
      fName: String;
      fArtist: TAlbumArtist;
    public
      property Artist: TAlbumArtist read fArtist;
      property Name: String read fName;
    end;

  TSong = class(TLinkedListItem)
    private
      fResource: TSoundResource;
      fAlbum: TSongAlbum;
      fGenre, fTitle: String;
      fResourceName: String;
      function fGetResource: TSoundResource;
    public
      property Resource: TSoundResource read fGetResource;
      property OriginalResourceName: String read fResourceName;
      property Album: TSongAlbum read fAlbum;
      property Genre: String read fGenre;
      property Title: String read fTitle;
      constructor Create(ResourceName: String);
    end;

  TItemContainer = class(TLinkedListItem)
    private
      fItem: TLinkedListItem;
    public
      property Item: TLinkedListItem read fItem;
      constructor Create(I: TLinkedListItem);
    end;

  TMusicManager = class
    private
      fSongs, fAlbums, fArtists: TLinkedList;
    public
      property Artists: TLinkedList read fArtists;
      property Albums: TLinkedList read fAlbums;
      property Songs: TLinkedList read fSongs;
      function GetArtist(N: String): TAlbumArtist;
      function GetAlbum(N: String; A: TAlbumArtist): TSongAlbum;
      procedure FinalReadFromSongList(Event: String; Data, Result: Pointer);
      procedure ReadFromSongList(ResourceName: String);
      function ListArtists(Genre: String = ''): TLinkedList;
      function ListAlbums(Artist: TAlbumArtist = nil; Genre: String = ''): TLinkedList;
      function ListSongs(Album: TSongAlbum = nil; Artist: TAlbumArtist = nil; Genre: String = ''): TLinkedList;
      constructor Create;
      destructor Free;
    end;

var
  MusicManager: TMusicManager = nil;

implementation

uses
  u_functions, m_varlist, u_dom, u_events;

function TSong.fGetResource: TSoundResource;
begin
  if fResource = nil then
    fResource := TSoundResource.Get(fResourceName);
  Result := fResource;
end;

constructor TSong.Create(ResourceName: String);
begin
  fResource := nil;
  fResourceName := ResourceName;
end;

constructor TItemContainer.Create(I: TLinkedListItem);
begin
  inherited Create;
  fItem := I;
end;

procedure TMusicManager.FinalReadFromSongList(Event: String; Data, Result: Pointer);
var
  C: TDOMElement;
  Song: TSong;
  SongCount: Integer;
begin
  C := TDOMElement(TRawXMLResource(Data).Document.GetElementsByTagName('songlist')[0].FirstChild);
  SongCount := 0;
  while C <> nil do
    begin
    Song := TSong.Create(C.GetAttribute('resource:name'));
    Song.fTitle := C.GetAttribute('title');
    Song.fGenre := C.GetAttribute('genre');
    Song.fAlbum := GetAlbum(C.GetAttribute('album'), GetArtist(C.GetAttribute('artist')));
    fSongs.Append(Song);
    C := TDOMElement(C.NextSibling);
    inc(SongCount);
    end;
  writeln('Added ', SongCount, ' songs');
  EventManager.RemoveCallback(Event, @FinalReadFromSongList);
end;

procedure TMusicManager.ReadFromSongList(ResourceName: String);
begin
  TRawXMLResource.Get(ResourceName);
  EventManager.AddCallback('TResource.FinishedLoading:' + ResourceName, @FinalReadFromSongList);
end;

function TMusicManager.GetArtist(N: String): TAlbumArtist;
var
  A: TAlbumArtist;
begin
  A := TAlbumArtist(fArtists.First);
  while A <> nil do
    begin
    if Lowercase(A.Name) = Lowercase(N) then
      exit(A);
    A := TAlbumArtist(A.Next);
    end;
  Result := TAlbumArtist.Create;
  Result.fName := N;
  fArtists.Append(Result);
end;

function TMusicManager.GetAlbum(N: String; A: TAlbumArtist): TSongAlbum;
var
  B: TSongAlbum;
begin
  B := TSongAlbum(fAlbums.First);
  while B <> nil do
    begin
    if (Lowercase(B.Name) = Lowercase(N)) and (B.Artist = A) then
      exit(B);
    B := TSongAlbum(B.Next);
    end;
  Result := TSongAlbum.Create;
  Result.fName := N;
  Result.fArtist := A;
  fAlbums.Append(Result);
end;

function TMusicManager.ListArtists(Genre: String = ''): TLinkedList;
var
  C: TSong;
  DoAdd: Boolean;
  AddedArtists: Array of TAlbumArtist;
  I: Integer;
begin
  Result := TLinkedList.Create;
  C := TSong(fSongs.First);
  while C <> nil do
    begin
    DoAdd := (C.Genre = Genre) or (Genre = '');
    if DoAdd then
      for I := 0 to high(AddedArtists) do
        if AddedArtists[I] = C.Album.Artist then
          DoAdd := False;
    if DoAdd then
      begin
      SetLength(AddedArtists, Length(AddedArtists) + 1);
      AddedArtists[high(AddedArtists)] := C.Album.Artist;
      Result.Append(TItemContainer.Create(C.Album.Artist));
      end;
    C := TSong(C.Next);
    end;
end;

function TMusicManager.ListAlbums(Artist: TAlbumArtist = nil; Genre: String = ''): TLinkedList;
var
  C: TSong;
  DoAdd: Boolean;
  AddedAlbums: Array of TSongAlbum;
  I: Integer;
begin
  Result := TLinkedList.Create;
  C := TSong(fSongs.First);
  while C <> nil do
    begin
    DoAdd := ((C.Album.Artist = Artist) or (Artist = nil));
    DoAdd := (DoAdd) and ((C.Genre = Genre) or (Genre = ''));
    if DoAdd then
      for I := 0 to high(AddedAlbums) do
        if AddedAlbums[I] = C.Album then
          DoAdd := False;
    if DoAdd then
      begin
      SetLength(AddedAlbums, Length(AddedAlbums) + 1);
      AddedAlbums[high(AddedAlbums)] := C.Album;
      Result.Append(TItemContainer.Create(C.Album));
      end;
    C := TSong(C.Next);
    end;
end;

function TMusicManager.ListSongs(Album: TSongAlbum = nil; Artist: TAlbumArtist = nil; Genre: String = ''): TLinkedList;
var
  C: TSong;
  DoAdd: Boolean;
begin
  Result := TLinkedList.Create;
  C := TSong(fSongs.First);
  while C <> nil do
    begin
    DoAdd := (Album = nil) or (C.Album = Album);
    DoAdd := (DoAdd) and ((C.Album.Artist = Artist) or (Artist = nil));
    DoAdd := (DoAdd) and ((C.Genre = Genre) or (Genre = ''));
    if DoAdd then
      Result.Append(TItemContainer.Create(C));
    C := TSong(C.Next);
    end;
end;

constructor TMusicManager.Create;
var
  OCFFiles: TStringList;
  I: Integer;
begin
  MusicManager := Self;

  fSongs := TLinkedList.Create;
  fAlbums := TLinkedList.Create;
  fArtists := TLinkedList.Create;

  OCFFiles := TStringList.Create;
  GetFilesInDirectory(ModuleManager.ModPathes.DataPath + 'music', '*-list.ocf', OCFFiles, False, False);
  GetFilesInDirectory(ModuleManager.ModPathes.PersonalDataPath + 'music', '*.ocf', OCFFiles, False, False);
  for I := 0 to OCFFiles.Count - 1 do
    ReadFromSongList('music/' + Basename(OCFFiles.Strings[I]) + '/songlist');
  OCFFiles.Free;
end;

destructor TMusicManager.Free;
begin
  fArtists.Free;
  fAlbums.Free;
  fSongs.Free;
end;

end.