unit g_park;

interface

uses
  SysUtils, Classes, g_terrain, g_camera, m_gui_button_class, m_gui_class, g_parkui, g_sky, u_selection, g_loader_ocf, u_dom, u_xml, g_particles,
  g_resources, g_objects, g_res_textures, g_screen_capture, g_sets;

type
  TPark = class
    protected
      fFile: TOCFFile;
      fPostLoading: Boolean;
      fCanRender: Boolean;
      fLoadState: Integer;
      fSelectionEngine: TSelectionEngine;
      fNormalSelectionEngine: TSelectionEngine;
      fScreenCaptureTool: TScreenCaptureTool;
      fGameObjectManager: TGameObjectManager;
      procedure SetSelectionEngine(E: TSelectionEngine);
      procedure SelectedObject(Event: String; Data, Result: Pointer);
    public
      // Parts of the park
      pTerrain: TTerrain;
      pSky: TSky;
      pMainCamera: TCamera;
      pCameras: Array of TCamera;
      pParticles: TParticleManager;
      pObjects: TObjectManager;

      fName, fAuthor, fDescription: String;

      property ScreenCaptureTool: TScreenCaptureTool read fScreenCaptureTool;
      property GameObjectManager: TGameObjectManager read fGameObjectManager;
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
        * Initialize the "real" loading
        *)
      procedure StartLoading(Event: String; Data, Result: Pointer);

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
  Main, m_varlist, u_events, math, u_files, u_scene;

procedure TPark.SetSelectionEngine(E: TSelectionEngine);
begin
  if E = nil then
    writeln('Disabled selection engine')
  else
    writeln('Enabled selection engine (' + IntToStr(E.ObjectCount) + ' meshes)');
  fSelectionEngine := E;
end;

procedure TPark.SelectedObject(Event: String; Data, Result: Pointer);
begin
end;

constructor TPark.Create(FileName: String);
begin
  writeln('Hint: Creating Park object');
  EventManager.AddCallback('TPark.ParkFileLoaded', @StartLoading);

  fAuthor := '';
  fName := '';
  fDescription := '';

  fCanRender := false;

  fFile := nil;

  pParticles := TParticleManager.Create;
  pObjects := TObjectManager.Create;

  fPostLoading := false;
  if (FileExists(GetFirstExistingFileName(FileName))) and not (DirectoryExists(GetFirstExistingFileName(FileName))) then
    ModuleManager.ModOCFManager.RequestOCFFile(FileName, 'TPark.ParkFileLoaded', nil)
  else
    fPostLoading := true;

  ModuleManager.ModLoadScreen.Progress := 5;
  fNormalSelectionEngine := TSelectionEngine.Create;
  fSelectionEngine := fNormalSelectionEngine;


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
    99:
      begin
      fGameObjectManager := TGameObjectManager.Create;
      fGameObjectManager.Resume;
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
      if fFile = nil then
        pTerrain.LoadDefaults
      else
        begin
        with TDOMElement(fFile.XML.Document.GetElementsByTagName('terrain')[0]) do
          begin
          pTerrain.ChangeCollection(GetAttribute('collection'));
          pTerrain.ReadFromOCFSection(fFile.Bin[fFile.Resources[StrToInt(GetAttribute('resource:id'))].Section]);
          end;
        end;
      end;
    104:
      begin
      ModuleManager.ModLoadScreen.Text := 'Loading set files';
      end;
    105:
      begin
      if (fGameObjectManager.Done) and (not fGameObjectManager.Loaded) then
        fGameObjectManager.LoadAll
      else
        dec(fLoadState);
      end;
    106:
      begin
      ModuleManager.ModLoadScreen.Progress := Round(10 + 88 * (ModuleManager.ModOCFManager.LoadedFiles / Max(1, ModuleManager.ModOCFManager.FileCount)));
      ModuleManager.ModLoadScreen.Text := 'Loading resource $' + IntToStr(ModuleManager.ModOCFManager.LoadedFiles + 1) + '/' + IntToStr(ModuleManager.ModOCFManager.FileCount) + '$';
      if (ModuleManager.ModOCFManager.LoadedFiles < ModuleManager.ModOCFManager.FileCount) or (not fGameObjectManager.Loaded) then
        dec(fLoadState);
      end;
    107:
      begin
      if (ModuleManager.ModOCFManager.LoadedFiles < ModuleManager.ModOCFManager.FileCount) then
        dec(fLoadState, 2);
      end;
    108:
      begin
      ModuleManager.ModLoadScreen.Progress := 98;
      ModuleManager.ModLoadScreen.Text := 'Creating sky';
      end;
    109: pSky := TSky.Create;
    110:
      begin
      ModuleManager.ModLoadScreen.Progress := 99;
      ModuleManager.ModLoadScreen.Text := 'Loading user interface files';
      end;
    111: ParkUI := TParkUI.Create;
    112:
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
  ModuleManager.ModCamera.ActiveCamera := TCamera.Create;
  ModuleManager.ModCamera.ActiveCamera.LoadDefaults;
  ModuleManager.ModRenderer.PostInit;
  fScreenCaptureTool := TScreenCaptureTool.Create;
  EventManager.AddCallback('TPark.Objects.Selected', @SelectedObject);
end;

procedure TPark.Render;
begin
  try
    if not fCanRender then
      ModuleManager.ModLoadScreen.Render
    else
      begin
      fScreenCaptureTool.Advance;
      ModuleManager.ModRenderer.RenderScene;
      ParkUI.Drag;
      pSky.Advance;
      pObjects.Advance;
      pParticles.Advance;
      ModuleManager.ModCamera.AdvanceActiveCamera;
      fSelectionEngine.Update;
      end;
    if fPostLoading then
      ContinueLoading;
    EventManager.CallEvent('TPark.Render', nil, nil);
  except
    ModuleManager.ModLog.AddError('Game crashed! Trying to save park file..');
    try
      Park.SaveTo(ModuleManager.ModPathes.PersonalDataPath + 'saved/crash-recovery.ocf');
      ModuleManager.ModLog.AddError('Success! Park file has been saved to ' + ModuleManager.ModPathes.PersonalDataPath + 'saved/crash-recovery.ocf. Restart the game and see if everything is right.');
    except
      ModuleManager.ModLog.AddError('FAILED! Your most recent changes are most probably lost, sorry for that.');
    end;
    ModuleManager.ModLog.AddError('To get this solved, please report a bug and tell exactly what you did before the' + #10
                                + 'crash. Try to reproduce it again. Attaching the park file might be helpful as well.');
    ModuleManager.ModLog.AddError('Quitting game.');
    halt(101);
  end;
end;

procedure TPark.SaveTo(F: String);
var
  i, j: Integer;
  tmpW: Word;
  tmpB: Byte;
  P: Pointer;
  fTmpFile: TOCFFile;
begin
  fTmpFile := TOCFFile.Create('');

  if fAuthor = '' then
    fAuthor := 'Unknown author';
  if fName = '' then
    fName := 'Unnamed Park';
  if fDescription = '' then
    fDescription := 'No description';

  // Create content of fTmpFile
  with fTmpFile.XML.Document do
    begin
    TDOMElement(FirstChild).SetAttribute('type', 'savedgame');
    TDOMElement(FirstChild).SetAttribute('author', fAuthor);
    TDOMElement(FirstChild).AppendChild(CreateElement('resources'));
    TDOMElement(FirstChild.LastChild).AppendChild(CreateElement('resource'));
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:id', '0');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:section', '0');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:format', 'terrain.rawdata');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:version', '1.0');
    TDOMElement(FirstChild.LastChild).AppendChild(CreateElement('resource'));
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:id', '1');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:section', '1');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:format', 'park.objectdata');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:version', '1.0');
    TDOMElement(FirstChild).AppendChild(CreateElement('park'));
    TDOMElement(FirstChild.LastChild).SetAttribute('resource:version', '1.0');
    TDOMElement(FirstChild.LastChild).SetAttribute('name', fName);
    TDOMElement(FirstChild.LastChild).AppendChild(CreateElement('description'));
    TDOMElement(FirstChild.LastChild.LastChild).AppendChild(CreateTextNode(fDescription));
    TDOMElement(FirstChild.LastChild).AppendChild(CreateElement('terrain'));
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:id', '0');
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('collection', SystemIndependentFileName(pTerrain.Collection.Name));
    TDOMElement(FirstChild.LastChild).AppendChild(CreateElement('objects'));
    TDOMElement(FirstChild.LastChild.LastChild).SetAttribute('resource:id', '1');
    end;

  fTmpFile.AddBinarySection(pTerrain.CreateOCFSection);
  fTmpFile.AddBinarySection(pObjects.CreateOCFSection);

  fTmpFile.SaveTo(F);
  fTmpFile.Free;

  ModuleManager.ModOCFManager.ReloadOCFFile(F, 'null', nil);
end;

procedure TPark.StartLoading(Event: String; Data, Result: Pointer);
begin
  EventManager.RemoveCallback(@StartLoading);
  fFile := TOCFFile(Data);
  fDescription := TDOMElement(fFile.XML.Document.GetElementsByTagName('description')[0]).FirstChild.NodeValue;
  fName := TDOMElement(fFile.XML.Document.GetElementsByTagName('park')[0]).GetAttribute('name');
  fAuthor := TDOMElement(fFile.XML.Document.FirstChild).GetAttribute('author');

  fPostLoading := true;
end;

destructor TPark.Free;
begin
  writeln('Hint: Deleting Park object');
  fScreenCaptureTool.Free;
  EventManager.RemoveCallback(@SelectedObject);
  EventManager.RemoveCallback(@StartLoading);
  fSelectionEngine := nil;
  fNormalSelectionEngine.Free;
  pSky.Free;
  pTerrain.Free;
  pObjects.Free;
  pParticles.Free;
  fGameObjectManager.Free;
  ModuleManager.ModRenderer.Unload;
end;

end.