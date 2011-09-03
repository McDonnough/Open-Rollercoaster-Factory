unit o_objectcreator;

interface

uses
  SysUtils, Classes, m_gui_window_class, m_gui_label_class, m_gui_button_class, m_gui_iconifiedbutton_class, m_gui_scrollbox_class,
  m_gui_image_class, g_loader_ocf, u_dialogs, u_vectors, m_gui_tabbar_class, m_gui_class, u_files, u_dom;

type
  TSelectorList = class;

  TSelectorCallback = procedure(List: TSelectorList; Item: TLabel);

  TSelectorList = class(TScrollBox)
    protected
      fItems: Array of TLabel;
      fSender, fItemHeight: Integer;
      procedure SetItemHeight(H: Integer);
      procedure RemoveClicked(Sender: TGUIComponent);
    public
      OnSelect: TSelectorCallback;
      property ItemHeight: Integer read fItemHeight write SetItemHeight;
      procedure Selected(Item: TLabel);
      procedure Remove(I: Integer);
      procedure Add(L: TLabel);
      procedure Clear;
      constructor Create(P: TGUIComponent);
    end;

  TSelectableResource = class(TLabel)
    protected
      fData: TOCFBinarySection;
      fResourceName: String;
      fCaptLabel: TLabel;
      fList: TSelectorList;
      fFormat: String;
      procedure Select(Sender: TGUIComponent);
      procedure AssignResourceName(S: String);
    public
      property ResourceName: String read fResourceName write AssignResourceName;
      property Format: String read fFormat write fFormat;
      property Data: TOCFBinarySection read fData;
      procedure EmptySection;
      procedure AssignSection(S: TOCFBinarySection);
      constructor Create(P: TSelectorList);
      destructor Destroy; override;
    end;

  TObjectCreator = class
    protected
      fCanClose: Boolean;
      fBGLabel, fTabContainer, fTabContainer2, fResourceTab, fMeshTab: TLabel;
      fWindow: TWindow;
      fTabBar: TTabBar;
      fResources: TSelectorList;
      fResourceData: Array of TSelectableResource;
      fClearResources, fAddResources, fQuit, fSaveOCF: TIconifiedButton;
      fOpenResource, fSaveDialog: TFileDialog;
      fDoQuit: TYesNoDialog;
      procedure ClearResources(Sender: TGUIComponent);
      procedure AddResources(Sender: TGUIComponent);
      procedure SaveOCF(Sender: TGUIComponent);
      procedure Quit(Sender: TGUIComponent);
      procedure AddResourcesFromFile(Event: String; Data, Result: Pointer);
      procedure OnChangeTab(Sender: TGUIComponent);
      procedure QuitEvent(Event: String; Data, Result: Pointer);
      procedure SaveEvent(Event: String; Data, Result: Pointer);
      procedure RemoveItem(Event: String; Data, Result: Pointer);
    public
      property CanClose: Boolean read fCanClose;
      constructor Create;
      destructor Free;
    end;

var
  ObjectCreator: TObjectCreator = nil;

implementation

uses
  m_varlist, u_events;

procedure TSelectableResource.Select(Sender: TGUIComponent);
begin
  fList.Selected(Self);
end;

procedure TSelectableResource.EmptySection;
begin
  fData := TOCFBinarySection.Create;
end;

procedure TSelectableResource.AssignResourceName(S: String);
begin
  fResourceName := S;
  fCaptLabel.Caption := S;
end;

procedure TSelectableResource.AssignSection(S: TOCFBinarySection);
begin
  fData := TOCFBinarySection.Create;
  fData.Append(@S.Stream.Data[0], length(S.Stream.Data));;
end;

constructor TSelectableResource.Create(P: TSelectorList);
begin
  inherited Create(P.Surface);
  fList := P;
  fResourceName := '';
  fCaptLabel := TLabel.Create(Self);
  fCaptLabel.Top := 8;
  fCaptLabel.Left := 8;
  fCaptLabel.Height := 16;
  fCaptLabel.Size := 16;
  fCaptLabel.Width := 200;
  fFormat := '';
  P.Add(Self);
  fData := nil;
  OnClick := @Select;
  fCaptLabel.OnClick := @Select;
end;

destructor TSelectableResource.Destroy;
begin
  EventManager.CallEvent('TSelectableResource.Free', Self, nil);
  if fData <> nil then
    fData.Free;
  inherited Destroy;
end;

procedure TSelectorList.Selected(Item: TLabel);
var
  i: Integer;
begin
  for i := 0 to high(fItems) do
    if fItems[i] <> Item then
      fItems[i].Color := Vector(1.0, 1.0, 1.0, 0.0)
    else
      fItems[i].Color := Vector(0.5, 0.7, 1.0, 1.0);
  if OnSelect <> nil then
    OnSelect(Self, Item);
end;

procedure TSelectorList.SetItemHeight(H: Integer);
var
  I: Integer;
begin
  fItemHeight := H;
  for I := 0 to high(fItems) do
    fItems[I].Top := fItemHeight * I;
end;

procedure TSelectorList.RemoveClicked(Sender: TGUIComponent);
var
  I: Integer;
begin
  for I := 0 to high(fItems) do
    if fItems[I].Tag = Sender.Tag then
      begin
      Remove(I);
      exit;
      end;
end;

procedure TSelectorList.Add(L: TLabel);
begin
  setLength(fItems, length(fItems) + 1);
  fItems[high(fItems)] := L;
  L.Tag := fSender;
  L.Top := fItemHeight * high(fItems);
  L.Left := 0;
  L.Height := fItemHeight;
  L.Width := Width - 16;

  with TIconifiedButton.Create(L) do
    begin
    Left := Self.Width - 48;
    Top := 4;
    Height := 24;
    Width := 24;
    Icon := 'list-remove.tga';
    OnClick := @RemoveClicked;
    Tag := fSender;
    end;
  
  inc(fSender);
end;

procedure TSelectorList.Remove(I: Integer);
var
  A: Integer;
begin
  fItems[I].Free;
  for A := I + 1 to high(fItems) do
    fItems[A - 1] := fItems[A];
  setLength(fItems, length(fItems) - 1);
  for A := 0 to high(fItems) do
    fItems[A].Top := fItemHeight * A;
end;

procedure TSelectorList.Clear;
var
  I: Integer;
begin
  for I := 0 to high(fItems) do
    fItems[I].Free;
  SetLength(fItems, 0);
  fSender := 0;
end;

constructor TSelectorList.Create(P: TGUIComponent);
begin
  inherited Create(P);
  fSender := 0;
  HScrollBar := sbmInvisible;
  ItemHeight := 32;
  OnSelect := nil;
end;


procedure TObjectCreator.OnChangeTab(Sender: TGUIComponent);
begin
  fTabContainer.Left := -784 * fTabBar.SelectedTab;
end;

procedure TObjectCreator.ClearResources(Sender: TGUIComponent);
begin
  fResources.Clear;
end;

procedure TObjectCreator.AddResources(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TFileDialog.Selected', @AddResourcesFromFile);
  EventManager.AddCallback('TFileDialog.Aborted', @AddResourcesFromFile);
  fOpenResource := TFileDialog.Create(True, 'scenery', 'Add Resource', [ftOCF, ftIMG, ftOGG, ftXML]);
end;

procedure TObjectCreator.AddResourcesFromFile(Event: String; Data, Result: Pointer);
var
  Filename: String;
  A: TByteStream;
  O: TOCFFile;
  I: Integer;
begin
  Filename := String(Data^);
  if Event = 'TFileDialog.Selected' then
    if ExtractFileExt(FileName) = '.ocf' then
      begin
      O := TOCFFile.Create(FileName);
      for I := 0 to O.ResourceCount - 1 do
        begin
        SetLength(fResourceData, length(fResourceData) + 1);
        fResourceData[high(fResourceData)] := TSelectableResource.Create(fResources);
        fResourceData[high(fResourceData)].EmptySection;
        fResourceData[high(fResourceData)].Data.Append(@O.Bin[i].Stream.Data[0], Length(O.Bin[i].Stream.Data));
        fResourceData[high(fResourceData)].ResourceName := O.Resources[i].Name;
        fResourceData[high(fResourceData)].Format := O.Resources[i].Format;
        end;
      O.Free;
      end
    else
      begin
      SetLength(fResourceData, length(fResourceData) + 1);
      fResourceData[high(fResourceData)] := TSelectableResource.Create(fResources);
      fResourceData[high(fResourceData)].EmptySection;
      A := ByteStreamFromFile(FileName);
      fResourceData[high(fResourceData)].Data.Append(@A.Data[0], Length(A.Data));
      fResourceData[high(fResourceData)].ResourceName := ExtractFileName(FileName);
      end;
  EventManager.RemoveCallback(@AddResourcesFromFile);
  fOpenResource.Free;
end;

procedure TObjectCreator.SaveOCF(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TFileDialog.Selected', @SaveEvent);
  EventManager.AddCallback('TFileDialog.Aborted', @SaveEvent);
  fSaveDialog := TFileDialog.Create(False, 'scenery', 'Save OCF file', [ftOCF]);
end;

procedure TObjectCreator.Quit(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TYesNoDialog.Yes', @QuitEvent);
  EventManager.AddCallback('TYesNoDialog.No', @QuitEvent);
  fDoQuit := TYesNoDialog.Create('Really quit the object creator?', 'dialog-information.tga');
end;

procedure TObjectCreator.RemoveItem(Event: String; Data, Result: Pointer);
var
  I, J: Integer;
begin
  for I := 0 to high(fResourceData) do
    if fResourceData[I] = TSelectableResource(Data) then
      begin
      for J := I + 1 to high(fResourceData) do
        fResourceData[J - 1] := fResourceData[J];
      SetLength(fResourceData, length(fResourceData) - 1);
      exit;
      end;
end;

procedure TObjectCreator.QuitEvent(Event: String; Data, Result: Pointer);
begin
  if Data = Pointer(fDoQuit) then
    begin
    fCanClose := Event = 'TYesNoDialog.Yes';
    EventManager.RemoveCallback(@QuitEvent);
    fDoQuit.Free;
    end;
end;

procedure TObjectCreator.SaveEvent(Event: String; Data, Result: Pointer);
var
  O: TOCFFile;
  S: TOCFBinarySection;
  I, RC: Integer;
begin
  EventManager.RemoveCallback(@SaveEvent);
  if Event = 'TFileDialog.Selected' then
    begin
    O := TOCFFile.Create('');
    O.XML.Document.FirstChild.AppendChild(O.XML.Document.CreateElement('resources'));
    RC := 0;
    for I := 0 to high(fResourceData) do
      begin
      O.XML.Document.FirstChild.FirstChild.AppendChild(O.XML.Document.CreateElement('resource'));
      TDOMElement(O.XML.Document.FirstChild.FirstChild.LastChild).SetAttribute('resource:name', fResourceData[i].ResourceName);
      TDOMElement(O.XML.Document.FirstChild.FirstChild.LastChild).SetAttribute('resource:id', IntToStr(RC));
      TDOMElement(O.XML.Document.FirstChild.FirstChild.LastChild).SetAttribute('resource:section', IntToStr(RC));
      TDOMElement(O.XML.Document.FirstChild.FirstChild.LastChild).SetAttribute('resource:format', fResourceData[i].Format);
      TDOMElement(O.XML.Document.FirstChild.FirstChild.LastChild).SetAttribute('resource:version', '1.0');
      S := TOCFBinarySection.Create;
      S.Append(@fResourceData[0].Data.Stream.Data[0], length(fResourceData[0].Data.Stream.Data));
      O.AddBinarySection(S);
      inc(RC);
      end;
    O.SaveTo(fSaveDialog.FileName);
    O.Free;
    end;
  fSaveDialog.Free;
end;

constructor TObjectCreator.Create;
var
  ResX, ResY: Integer;
begin
  fCanClose := False;

  ModuleManager.ModGlContext.GetResolution(ResX, ResY);

  fBGLabel := TLabel.Create(nil);
  fBGLabel.Left := 0;
  fBGLabel.Top := 0;
  fBGLabel.Height := ResY;
  fBGLabel.Width := ResX;
  fBGLabel.Color := Vector(0, 0, 0, 0.4);

  fWindow := TWindow.Create(fBGLabel);
  fWindow.Width := 800;
  fWindow.Height := 600;
  fWindow.Top := 0.5 * (ResY - 600);
  fWindow.Left := 0.5 * (ResX - 800);
  fWindow.OfsY1 := 32;

  fTabBar := TTabBar.Create(fWindow);
  fTabBar.Left := 8;
  fTabBar.Height := 32;
  fTabBar.Width := 784;
  fTabBar.Top := 8;
  fTabBar.AddTab('Resources');
  fTabBar.AddTab('Meshes');
  fTabBar.OnChangeTab := @OnChangeTab;

  fTabContainer2 := TLabel.Create(fWindow);
  fTabContainer2.Left := 8;
  fTabContainer2.Top := 40;
  fTabContainer2.Width := 784;
  fTabContainer2.Height := 552;

  fTabContainer := TLabel.Create(fTabContainer2);
  fTabContainer.Left := 0;
  fTabContainer.Top := 0;
  fTabContainer.Width := 2 * 784;
  fTabContainer.Height := 552;

  fResourceTab := TLabel.Create(fTabContainer);
  fResourceTab.Left := 0;
  fResourceTab.Top := 0;
  fResourceTab.Height := 552;
  fResourceTab.Width := 784;

  fMeshTab := TLabel.Create(fTabContainer);
  fMeshTab.Left := 784;
  fMeshTab.Top := 0;
  fMeshTab.Height := 552;
  fMeshTab.Width := 784;

  fResources := TSelectorList.Create(fResourceTab);
  fResources.Width := 200;
  fResources.Height := 512;
  fResources.Left := 8;
  fResources.Top := 0;

  fClearResources := TIconifiedButton.Create(fResourceTab);
  fClearResources.Top := 520;
  fClearResources.Left := 8;
  fClearResources.Width := 32;
  fClearResources.Height := 32;
  fClearResources.Icon := 'list-remove.tga';
  fClearResources.OnClick := @ClearResources;

  fAddResources := TIconifiedButton.Create(fResourceTab);
  fAddResources.Top := 520;
  fAddResources.Left := 48;
  fAddResources.Width := 32;
  fAddResources.Height := 32;
  fAddResources.Icon := 'list-add.tga';
  fAddResources.OnClick := @AddResources;

  fSaveOCF := TIconifiedButton.Create(fResourceTab);
  fSaveOCF.Top := 520;
  fSaveOCF.Left := 744;
  fSaveOCF.Width := 32;
  fSaveOCF.Height := 32;
  fSaveOCF.Icon := 'document-save.tga';
  fSaveOCF.OnClick := @SaveOCF;

  fQuit := TIconifiedButton.Create(fResourceTab);
  fQuit.Top := 520;
  fQuit.Left := 704;
  fQuit.Width := 32;
  fQuit.Height := 32;
  fQuit.Icon := 'dialog-cancel.tga';
  fQuit.OnClick := @Quit;

  EventManager.AddCallback('TSelectableResource.Free', @RemoveItem);
end;

destructor TObjectCreator.Free;
begin
  EventManager.RemoveCallback(@RemoveItem);
  fBGLabel.Free;
end;

end.