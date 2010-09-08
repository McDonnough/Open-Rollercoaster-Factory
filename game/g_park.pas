unit g_park;

interface

uses
  SysUtils, Classes, g_terrain, g_camera, m_gui_button_class, m_gui_class, g_parkui, g_sky, u_selection, g_loader_ocf, u_dom, u_xml;

type
  TPark = class
    protected
      fFile: TOCFFile;
      fPostLoading: Boolean;
      fCanRender: Boolean;
      fParkUI: TParkUI;
      fLoadState: Integer;
      fSelectionEngine: TSelectionEngine;
      fNormalSelectionEngine: TSelectionEngine;
      procedure SetSelectionEngine(E: TSelectionEngine);
    public
      // Parts of the park
      pTerrain: TTerrain;
      pSky: TSky;
      pMainCamera: TCamera;
      pCameras: Array of TCamera;

      fName, fAuthor, fDescription: String;

      property CanRender: Boolean read fCanRender;
      property OCFFile: TOCFFile read fFile;
      property SelectionEngine: TSelectionEngine read fSelectionEngine write setSelectionEngine;
      property NormalSelectionEngine: TSelectionEngine read fNormalSelectionEngine;

      (**
        * Call render modules, handle input
        *)
      procedure Render;


      (**
        * Post-initialization
        *)
      procedure PostInit;

      (**
        * Methods of post-initialization
        *)
      procedure ContinueLoading;

      (**
        * Save file
        *)
      procedure SaveTo(F: String);

      (**
        * Load a park
        *@param File to load
        *)
      constructor Create(FileName: String);

      (**
        * Free resources
        *)
      destructor Free;
    end;

var
  Park: TPark = nil;

implementation

uses
  Main, m_varlist, u_events, math, u_files;

procedure TPark.SetSelectionEngine(E: TSelectionEngine);
begin
  if E = nil then
    writeln('Disabled selection engine')
  else
    writeln('Enabled selection engine (' + IntToStr(E.ObjectCount) + ' meshes)');
  fSelectionEngine := E;
end;

constructor TPark.Create(FileName: String);
begin
  fAuthor := '';
  fName := '';
  fDescription := '';

  fCanRender := false;

  fFile := TOCFFile.Create(FileName);

  ModuleManager.ModLoadScreen.Progress := 5;
  fNormalSelectionEngine := TSelectionEngine.Create;
  fSelectionEngine := fNormalSelectionEngine;

  fPostLoading := true;
  fLoadState := 0;
end;

procedure TPark.ContinueLoading;
begin
  case fLoadState of
    0:
      begin
      ModuleManager.ModLoadScreen.Progress := 0;
      ModuleManager.ModLoadScreen.Text := 'Loading park file';
      end;
    100:
      begin
      ModuleManager.ModLoadScreen.Progress := 2;
      ModuleManager.ModLoadScreen.Text := 'Preparing renderer';
      end;
    101:
      PostInit;
    102:
      begin
      ModuleManager.ModLoadScreen.Progress := 10;
      ModuleManager.ModLoadScreen.Text := 'Preparing terrain';
      end;
    103:
      begin
      pTerrain := TTerrain.Create;
      pTerrain.LoadDefaults;
      end;
    104:
      begin
      ModuleManager.ModLoadScreen.Progress := Round(10 + 88 * (ModuleManager.ModOCFManager.LoadedFiles / Max(1, ModuleManager.ModOCFManager.FileCount)));
      ModuleManager.ModLoadScreen.Text := 'Loading resource ' + IntToStr(ModuleManager.ModOCFManager.LoadedFiles + 1) + '/' + IntToStr(ModuleManager.ModOCFManager.FileCount);
      if ModuleManager.ModOCFManager.LoadedFiles < ModuleManager.ModOCFManager.FileCount then
        dec(fLoadState);
      end;
    105:
      begin
      end;
    106:
      begin
      ModuleManager.ModLoadScreen.Progress := 98;
      ModuleManager.ModLoadScreen.Text := 'Creating sky';
      end;
    107: pSky := TSky.Create;
    108:
      begin
      ModuleManager.ModLoadScreen.Progress := 99;
      ModuleManager.ModLoadScreen.Text := 'Loading user interface files';
      end;
    109: fParkUI := TParkUI.Create;
    110:
      begin
      ModuleManager.ModLoadScreen.Progress := 100;
      ModuleManager.ModLoadScreen.Text := 'Preparing for gameplay';
      end;
    200:
      begin
      ModuleManager.ModLoadScreen.SetVisibility(false);
      fCanRender := true;
      end;
    end;
  inc(fLoadState);
end;

procedure TPark.PostInit;
begin
  ModuleManager.ModRenderer.PostInit;
  ModuleManager.ModCamera.ActiveCamera := TCamera.Create;
  ModuleManager.ModCamera.ActiveCamera.LoadDefaults;
end;

procedure TPark.Render;
begin
  if not fCanRender then
    ModuleManager.ModLoadScreen.Render
  else
    begin
    fParkUI.Drag;
    pSky.Time := pSky.Time + FPSDisplay.MS / 50;
    ModuleManager.ModCamera.AdvanceActiveCamera;
    fSelectionEngine.Update;
    ModuleManager.ModRenderer.RenderScene;
    end;
  if fPostLoading then
    ContinueLoading;
  EventManager.CallEvent('TPark.Render', nil, nil);
end;

procedure TPark.SaveTo(F: String);
var
  fTerrainSection: TOCFBinarySection;
  fTerrainData: Array of Byte;
  i, j: Integer;
  tmpW: Word;
  tmpB: Byte;
  P: Pointer;
begin
  if fFile <> nil then
    fFile.Free;
  fFile := TOCFFile.Create('');

  if fAuthor = '' then
    fAuthor := 'unknown author';
  if fName = '' then
    fName := 'Unnamed Park';
  if fDescription = '' then
    fDescription := 'No description';

  // Create content of fFile
  with fFile.XML.Document do
    begin
    TDOMElement(FirstChild).SetAttribute('type', 'savedgame');
    TDOMElement(FirstChild).SetAttribute('author', fAuthor);
    TDOMElement(FirstChild).AppendChild(CreateElement('resources'));
    TDOMElement(FirstChild.LastChild).AppendChild(CreateElement('resource'));
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:id', '0');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:section', '0');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:format', 'terrain.rawdata');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:version', '1.0');
    TDOMElement(FirstChild).AppendChild(CreateElement('park'));
    TDOMElement(FirstChild.LastChild).SetAttribute('resource:version', '1.0');
    TDOMElement(FirstChild.LastChild).SetAttribute('name', fName);
    TDOMElement(FirstChild.LastChild).AppendChild(CreateElement('description'));
    TDOMElement(FirstChild.LastChild.LastChild).AppendChild(CreateTextNode(fDescription));
    TDOMElement(FirstChild.LastChild).AppendChild(CreateElement('terrain'));
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:id', '0');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('collection', SystemIndependentFileName(pTerrain.Collection.Name));
    end;

  SetLength(fTerrainData, pTerrain.SizeX * pTerrain.SizeY * (2 { Vertex } + 2 { Water }  + 1 { Material & Flags }));
  P := @fTerrainData[0];
  for i := 0 to pTerrain.SizeX - 1 do
    for j := 0 to pTerrain.SizeY - 1 do
      begin
      Word(P^) := Round(256 * pTerrain.HeightMap[i / 5, j / 5]);
      inc(P, 2);
      Word(P^) := Round(256 * pTerrain.WaterMap[i / 5, j / 5]);
      inc(P, 2);
      Byte(P^) := Round(256 * pTerrain.TexMap[i / 5, j / 5]);
      inc(P);
      end;


  fTerrainSection := TOCFBinarySection.Create;
  fTerrainSection.Append(@fTerrainData[0], length(fTerrainData));
  fFile.AddBinarySection(fTerrainSection);

  fFile.SaveTo(F);
end;

destructor TPark.Free;
begin
  ModuleManager.ModRenderer.Unload;
  fNormalSelectionEngine.Free;
  fSelectionEngine := nil;
  pSky.Free;
  pTerrain.Free;
  fParkUI.Free;
  if fFile <> nil then
    fFile.Free;
end;

end.