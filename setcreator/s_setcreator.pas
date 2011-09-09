unit s_setcreator;

interface

uses
  SysUtils, Classes, m_gui_class, m_gui_window_class, m_gui_button_class, m_gui_edit_class, m_gui_iconifiedbutton_class, m_gui_label_class,
  m_gui_scrollbox_class, m_gui_slider_class, m_gui_progressbar_class, m_gui_checkbox_class, m_gui_tabbar_class, m_gui_image_class, u_dialogs,
  m_texmng_class, u_vectors, u_xml, u_dom, g_loader_ocf, u_files;

type
  TTextureSelect = class;
  TObjectSelect = class;
  TTagSelect = class;

  TTextureSelectItem = class(TLabel)
    private
      fImage: TImage;
      fName: TLabel;
      fSelect: TTextureSelect;
      fBasicColor: TVector4D;
      fFullName: String;
      function getTexture: TTexture;
      procedure fOnClick(Sender: TGUIComponent);
    public
      property Texture: TTexture read getTexture;
      property Name: String read fFullName;
      constructor Create(TexFile: String; TheParent: TTextureSelect);
    end;
    
  TObjectSelectItem = class(TLabel)
    private
      fImage: TImage;
      fName: TLabel;
      fImageFileName: String;
      fTags: Array of String;
      fDescription: String;
      fObjectName: String;
      fSelect: TObjectSelect;
      fBasicColor: TVector4D;
      fFullName: String;
      procedure fOnClick(Sender: TGUIComponent);
    public
      property Name: String read fFullName;
      constructor Create(OCFFile: String; TheParent: TObjectSelect);
    end;

  TTextureSelect = class(TScrollBox)
    private
      fItems: Array of TTextureSelectItem;
      fSelectedItem: TTextureSelectItem;
      function getItem(I: Integer): TTextureSelectItem;
      function getCount: Integer;
    public
      property SelectedItem: TTextureSelectItem read fSelectedItem;
      property Count: Integer read getCount;
      property Items[I: Integer]: TTextureSelectItem read getItem;
      function GetItem(ItemName: String): TTextureSelectItem;
      procedure AddItem(Item: TTextureSelectItem);
      procedure DeleteItem(Item: TTextureSelectItem);
      constructor Create(TheParent: TGUIComponent);
    end;

  TObjectSelect = class(TScrollBox)
    private
      fItems: Array of TObjectSelectItem;
      fSelectedItem: TObjectSelectItem;
      function getItem(I: Integer): TObjectSelectItem;
      function getCount: Integer;
    public
      property SelectedItem: TObjectSelectItem read fSelectedItem;
      property Count: Integer read getCount;
      property Items[I: Integer]: TObjectSelectItem read getItem;
      function GetItem(ItemName: String): TObjectSelectItem;
      procedure AddItem(Item: TObjectSelectItem);
      procedure DeleteItem(Item: TObjectSelectItem);
      constructor Create(TheParent: TGUIComponent);
    end;

  TTagSelectItem = class(TLabel)
    private
      fSelected: Boolean;
      fSelect: TTagSelect;
      fBasicColor: TVector4D;
      fRemoveButton: TIconifiedButton;
      fRealLabel: TLabel;
      fTagName: String;
      procedure fOnClick(Sender: TGUIComponent);
      procedure fRemove(Sender: TGUIComponent);
      procedure Select(A: Boolean);
      procedure SetTagName(S: String);
    public
      property RealName: String read fTagName write setTagName;
      property Selected: Boolean read fSelected write Select;
      constructor Create(TagName: String; TheParent: TTagSelect);
    end;

  TTagSelect = class(TScrollBox)
    private
      fItems: Array of TTagSelectItem;
      fItemToDelete: TTagSelectItem;
      function getItem(I: Integer): TTagSelectItem;
      function getCount: Integer;
      procedure FinalDeleteItem(Sender: TGUIComponent);
    public
      property Count: Integer read getCount;
      property Items[I: Integer]: TTagSelectItem read getItem;
      function GetItem(TagName: String): TTagSelectItem;
      procedure AddItem(TheItem: TTagSelectItem);
      procedure DeleteItem(TheItem: TTagSelectItem);
      constructor Create(TheParent: TGUIComponent);
    end;

  TSetCreator = class
    protected
      fFilepath: String;    
      fCanClose: Boolean;

      // UI
      fBGLabel: TLabel;
      fWindow: TWindow;
      
      fTabBar: TTabBar;
      fTabContainer, fTabContainer2: TLabel;
      fSetTab, fPreviewTab, fObjectTab: TLabel;

      // Set tab
      fCloseButton, fSaveButton, fLoadButton: TIconifiedButton;
      fLogo: TImage;
      fSetName: TEdit;
      fSetDescription: TEdit;
      fSetPreview: TTextureSelect;

      // Preview tab
      fAllPreviews: TTextureSelect;
      fAdd, fRemove: TIconifiedButton;

      // Object tab
      fObjectList: TObjectSelect;
      fObjectName, fObjectDescription: TEdit;
      fObjectPreview: TTextureSelect;
      fTagList: TTagSelect;
      fTagName: TEdit;
      fAddTag: TIconifiedButton;
      fAddObject, fDelObject: TIconifiedButton;

      // Dialog
      fCloseDialog: TYesNoDialog;
      fSaveDialog: TFileDialog;
      fPreviewDialog: TFileDialog;
      fOpenDialog: TFileDialog;
      fOpenSetDialog: TFileDialog;
      fOpenDialogPath, fPreviewDialogPath: String;

      // Callbacks
      procedure CloseEvent(Event: String; Data, Result: Pointer);
      procedure FileSelected(Event: String; Data, Result: Pointer);
      procedure SetFileSelected(Event: String; Data, Result: Pointer);
      procedure OCFFileSelected(Event: String; Data, Result: Pointer);
      procedure ImageFileSelected(Event: String; Data, Result: Pointer);
      procedure AssignSelectedPreview(Event: String; Data, Result: Pointer);
      procedure SelectCorrectPreview(Event: String; Data, Result: Pointer);
      procedure AssignTags(Event: String; Data, Result: Pointer);
      procedure DeleteTags(Event: String; Data, Result: Pointer);

      procedure ChangeData(Sender: TGUIComponent);
      procedure TabChanged(Sender: TGUIComponent);
      procedure Close(Sender: TGUIComponent);
      procedure Save(Sender: TGUIComponent);
      procedure Load(Sender: TGUIComponent);
      procedure AddPreview(Sender: TGUIComponent);
      procedure RemovePreview(Sender: TGUIComponent);
      procedure AddObject(Sender: TGUIComponent);
      procedure DeleteObject(Sender: TGUIComponent);
      procedure AddTag(Sender: TGUIComponent);
      procedure RestoreDefaultTagList;

      // Backend
      procedure LoadFromFile(FileName: String);
      function GatherData: TDOMDocument;
      function GetOCFFile: TOCFFile;
    public
      property CanClose: Boolean read fCanClose;
      constructor Create;
      destructor Destroy; override;
    end;

var
  SetCreator: TSetCreator = nil;

implementation

uses
  m_varlist, math, u_math, u_events, u_functions, u_graphics;

procedure TTextureSelectItem.fOnClick(Sender: TGUIComponent);
begin
  if Sender <> nil then
    EventManager.CallEvent('TTextureSelect.Changed', fSelect, Self);

  if fSelect.SelectedItem <> nil then
    fSelect.SelectedItem.Color := fSelect.SelectedItem.fBasicColor;

  Color := Vector(0.5, 0.7, 1.0, 1.0) * fBasicColor;
  fSelect.fSelectedItem := Self;
end;

function TTextureSelectItem.getTexture: TTexture;
begin
  Result := fImage.Tex;
end;

constructor TTextureSelectItem.Create(TexFile: String; TheParent: TTextureSelect);
begin
  inherited Create(TheParent.Surface);

  fSelect := TheParent;

  fFullName := TexFile;
  
  Width := TheParent.Width - 16;
  Height := 96;
  Left := 0;
  Top := 0;
  Size := 16;

  fImage := TImage.Create(Self);
  fImage.FreeTextureOnDestroy := True;
  fImage.Tex := TTexture.Create;
  fImage.Tex.FromFile(TexFile, false, false);
  fImage.Left := 0;
  fImage.Top := 0;
  fImage.Width := 96;
  fImage.Height := 96;
  fImage.OnClick := @fOnClick;

  fName := TLabel.Create(Self);
  fName.Left := 104;
  fName.Top := 12;
  fName.Width := 344;
  fName.Height := 72;
  fName.Size := 24;
  fName.Caption := Basename(TexFile);
  fName.OnClick := @fOnClick;

  fBasicColor := Vector(1, 1, 1, 1);

  OnClick := @fOnClick;

  TheParent.AddItem(Self);
end;


procedure TObjectSelectItem.fOnClick(Sender: TGUIComponent);
begin
  EventManager.CallEvent('TObjectSelect.Changed', fSelect, Self);

  if fSelect.SelectedItem <> nil then
    fSelect.SelectedItem.Color := fSelect.SelectedItem.fBasicColor;

  Color := Vector(0.5, 0.7, 1.0, 1.0) * fBasicColor;
  fSelect.fSelectedItem := Self;
end;

constructor TObjectSelectItem.Create(OCFFile: String; TheParent: TObjectSelect);
begin
  inherited Create(TheParent.Surface);

  fSelect := TheParent;

  fFullName := OCFFile;

  Width := TheParent.Width - 16;
  Height := 96;
  Left := 0;
  Top := 0;
  Size := 16;

  fImage := TImage.Create(Self);
  fImage.FreeTextureOnDestroy := False;
  fImage.Left := 0;
  fImage.Top := 0;
  fImage.Width := 96;
  fImage.Height := 96;
  fImage.OnClick := @fOnClick;

  fName := TLabel.Create(Self);
  fName.Left := 104;
  fName.Top := 12;
  fName.Width := 344;
  fName.Height := 72;
  fName.Size := 24;
  fName.Caption := Basename(OCFFile);
  fName.OnClick := @fOnClick;

  fDescription := '';
  fImageFileName := '';
  fObjectName := '';

  fBasicColor := Vector(1, 1, 1, 1);

  OnClick := @fOnClick;

  TheParent.AddItem(Self);
end;


function TTextureSelect.getItem(I: Integer): TTextureSelectItem;
begin
  Result := fItems[I];
end;

function TTextureSelect.getCount: Integer;
begin
  Result := Length(fItems);
end;

procedure TTextureSelect.AddItem(Item: TTextureSelectItem);
var
  Colors: Array[0..1] of TVector4D;
begin
  Colors[0] := Vector(1.0, 1.0, 1.0, 1.0);
  Colors[1] := Vector(0.9, 0.9, 0.9, 1.0);
  setLength(fItems, length(fItems) + 1);
  fItems[high(fItems)] := Item;
  Item.Top := (Count - 1) * 96;
  Item.fBasicColor := Colors[(Count - 1) mod 2];
  Item.Color := Item.fBasicColor;
end;

procedure TTextureSelect.DeleteItem(Item: TTextureSelectItem);
var
  i, itemID: Integer;
  Colors: Array[0..1] of TVector4D;
begin
  Colors[0] := Vector(1.0, 1.0, 1.0, 1.0);
  Colors[1] := Vector(0.9, 0.9, 0.9, 1.0);

  itemID := -1;
  for i := 0 to high(fItems) do
    if fItems[i] = Item then
      itemID := i;

  if ItemID > -1 then
    begin
    if fSelectedItem = Item then
      fSelectedItem := nil;
    for i := ItemID + 1 to high(fItems) do
      begin
      fItems[i].Top := (i - 1) * 96;
      fItems[i].fBasicColor := Colors[(i - 1) mod 2];
      if fItems[i] <> SelectedItem then
        fItems[i].Color := fItems[i].fBasicColor
      else
        fItems[i].Color := fItems[i].fBasicColor * Vector(0.5, 0.7, 1.0, 1.0);
      fItems[i - 1] := fItems[i];
      end;
    SetLength(fItems, length(fItems) - 1);
    Item.Free;
    end;
end;

function TTextureSelect.GetItem(ItemName: String): TTextureSelectItem;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(fItems) do
    if fItems[i].Name = ItemName then
      Result := fItems[i];
end;

constructor TTextureSelect.Create(TheParent: TGUIComponent);
begin
  inherited Create(TheParent);

  fSelectedItem := nil;

  Width := 416;
  Top := 0;
  Left := 0;
  Height := 0;
end;


function TObjectSelect.getItem(I: Integer): TObjectSelectItem;
begin
  Result := fItems[I];
end;

function TObjectSelect.getCount: Integer;
begin
  Result := Length(fItems);
end;

procedure TObjectSelect.AddItem(Item: TObjectSelectItem);
var
  Colors: Array[0..1] of TVector4D;
begin
  Colors[0] := Vector(1.0, 1.0, 1.0, 1.0);
  Colors[1] := Vector(0.9, 0.9, 0.9, 1.0);
  setLength(fItems, length(fItems) + 1);
  fItems[high(fItems)] := Item;
  Item.Top := (Count - 1) * 96;
  Item.fBasicColor := Colors[(Count - 1) mod 2];
  Item.Color := Item.fBasicColor;
end;

procedure TObjectSelect.DeleteItem(Item: TObjectSelectItem);
var
  i, itemID: Integer;
  Colors: Array[0..1] of TVector4D;
begin
  Colors[0] := Vector(1.0, 1.0, 1.0, 1.0);
  Colors[1] := Vector(0.9, 0.9, 0.9, 1.0);

  itemID := -1;
  for i := 0 to high(fItems) do
    if fItems[i] = Item then
      itemID := i;

  if ItemID > -1 then
    begin
    if fSelectedItem = Item then
      fSelectedItem := nil;
    for i := ItemID + 1 to high(fItems) do
      begin
      fItems[i].Top := (i - 1) * 96;
      fItems[i].fBasicColor := Colors[(i - 1) mod 2];
      if fItems[i] <> SelectedItem then
        fItems[i].Color := fItems[i].fBasicColor
      else
        fItems[i].Color := fItems[i].fBasicColor * Vector(0.5, 0.7, 1.0, 1.0);
      fItems[i - 1] := fItems[i];
      end;
    SetLength(fItems, length(fItems) - 1);
    Item.Free;
    end;
end;

function TObjectSelect.GetItem(ItemName: String): TObjectSelectItem;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(fItems) do
    if fItems[i].Name = ItemName then
      Result := fItems[i];
end;

constructor TObjectSelect.Create(TheParent: TGUIComponent);
begin
  inherited Create(TheParent);

  Width := 416;
  Top := 0;
  fSelectedItem := nil;

  Left := 0;
  Height := 0;
end;


procedure TTagSelectItem.fOnClick(Sender: TGUIComponent);
begin
  Selected := not Selected;
  if Sender <> nil then
    EventManager.CallEvent('TTagSelectItem.Selected', fSelect, Self);
end;

procedure TTagSelectItem.fRemove(Sender: TGUIComponent);
begin
  if Selected then
    fOnClick(Self);
  fSelect.DeleteItem(Self);
  EventManager.CallEvent('TTagSelectItem.Deleted', fSelect, Self);
end;

procedure TTagSelectItem.Select(A: Boolean);
begin
  fSelected := A;
  if A then
    Color := Vector(0.5, 0.7, 1.0, 1.0) * fBasicColor
  else
    Color := fBasicColor;
end;

procedure TTagSelectItem.SetTagName(S: String);
begin
  fRealLabel.Caption := S;
  fTagName := S;
end;

constructor TTagSelectItem.Create(TagName: String; TheParent: TTagSelect);
begin
  inherited Create(TheParent.Surface);

  fSelect := TheParent;
  fTagName := TagName;
  fSelected := false;
  fBasicColor := Vector(1.0, 1.0, 1.0, 1.0);

  Width := TheParent.DestWidth - 16;
  Height := 32;
  Size := 16;
  Left := 0;
  Top := 0;
  OnClick := @fOnClick;

  fRealLabel := TLabel.Create(Self);
  fRealLabel.Left := 8;
  fRealLabel.Top := 8;
  fRealLabel.Size := 16;
  fRealLabel.Height := 16;
  fRealLabel.Width := TheParent.DestWidth - 56;
  fRealLabel.Caption := TagName;
  fRealLabel.OnClick := @fOnClick;

  fRemoveButton := TIconifiedButton.Create(Self);
  fRemoveButton.Left := TheParent.DestWidth - 48;
  fRemoveButton.Top := 0;
  fRemoveButton.Width := 32;
  fRemoveButton.Height := 32;
  fRemoveButton.Icon := 'list-remove.tga';
  fRemoveButton.OnClick := @fRemove;

  TheParent.AddItem(Self);
end;



function TTagSelect.getItem(I: Integer): TTagSelectItem;
begin
  Result := fItems[i];
end;

function TTagSelect.getCount: Integer;
begin
  Result := Length(fItems);
end;

function TTagSelect.GetItem(TagName: String): TTagSelectItem;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(fItems) do
    if fItems[i].RealName = TagName then
      Result := fItems[i];
end;

procedure TTagSelect.AddItem(TheItem: TTagSelectItem);
var
  Colors: Array[0..1] of TVector4D;
begin
  Colors[0] := Vector(1.0, 1.0, 1.0, 1.0);
  Colors[1] := Vector(0.9, 0.9, 0.9, 1.0);

  setLength(fItems, length(fItems) + 1);
  fItems[high(fItems)] := TheItem;

  TheItem.fBasicColor := Colors[(Count - 1) mod 2];
  TheItem.Selected := False;
  TheItem.Top := (Count - 1) * 32;
end;

procedure TTagSelect.DeleteItem(TheItem: TTagSelectItem);
begin
  fItemToDelete := TheItem;
end;

procedure TTagSelect.FinalDeleteItem(Sender: TGUIComponent);
var
  i, itemID: Integer;
  Colors: Array[0..1] of TVector4D;
begin
  Colors[0] := Vector(1.0, 1.0, 1.0, 1.0);
  Colors[1] := Vector(0.9, 0.9, 0.9, 1.0);
  if fItemToDelete <> nil then
    begin
    itemID := -1;
    for i := 0 to high(fItems) do
      if fItems[i] = fItemToDelete then
        itemID := i;

    if itemID > -1 then
      begin
      for i := itemID + 1 to Count - 1 do
        begin
        fItems[i].Top := (i - 1) * 32;
        fItems[i].fBasicColor := Colors[(i - 1) mod 2];
        if not fItems[i].Selected then
          fItems[i].Color := fItems[i].fBasicColor
        else
          fItems[i].Color := fItems[i].fBasicColor * Vector(0.5, 0.7, 1.0, 1.0);
        fItems[i - 1] := fItems[i];
        end;
      SetLength(fItems, Count - 1);
      fItemToDelete.Free;
      end;
    end;

  fItemToDelete := nil;
end;

constructor TTagSelect.Create(TheParent: TGUIComponent);
begin
  inherited Create(TheParent);

  Width := 200;
  Left := 0;
  Top := 0;
  Height := 200;

  fItemToDelete := nil;

  OnRender := @FinalDeleteItem;
end;




procedure TSetCreator.SelectCorrectPreview(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  if fObjectPreview.GetItem(TObjectSelectItem(Result).fImageFileName) <> nil then
    fObjectPreview.GetItem(TObjectSelectItem(Result).fImageFileName).fOnClick(nil);
  fObjectName.Text := TObjectSelectItem(Result).fObjectName;
  fObjectDescription.Text := TObjectSelectItem(Result).fDescription;

  for i := 0 to fTagList.Count - 1 do
    fTagList.Items[i].Selected := False;

  for i := 0 to high(TObjectSelectItem(Result).fTags) do
    if fTagList.GetItem(TObjectSelectItem(Result).fTags[i]) <> nil then
      fTagList.GetItem(TObjectSelectItem(Result).fTags[i]).Selected := True
    else
      with TTagSelectItem.Create(TObjectSelectItem(Result).fTags[i], fTagList) do
        Selected := True;
end;

procedure TSetCreator.AssignTags(Event: String; Data, Result: Pointer);
var
  c: Integer;
  i: Integer;
begin
  if (Data <> nil) and (fObjectList.SelectedItem <> nil) then
    begin
    c := 0;
    for i := 0 to TTagSelect(Data).Count - 1 do
      if TTagSelect(Data).Items[i].Selected then
        inc(c);
    SetLength(fObjectList.SelectedItem.fTags, C);
    c := 0;
    for i := 0 to TTagSelect(Data).Count - 1 do
      if TTagSelect(Data).Items[i].Selected then
        begin
        fObjectList.SelectedItem.fTags[c] := TTagSelect(Data).Items[i].RealName;
        inc(c);
        end;
    end;
end;

procedure TSetCreator.DeleteTags(Event: String; Data, Result: Pointer);
var
  i, j: Integer;
begin
  for i := 0 to fObjectList.Count - 1 do
    for j := 0 to high(fObjectList.Items[i].fTags) do
      if fObjectList.Items[i].fTags[j] = TTagSelectItem(Result).RealName then
        begin
        fObjectList.Items[i].fTags[j] := fObjectList.Items[i].fTags[high(fObjectList.Items[i].fTags)];
        Setlength(fObjectList.Items[i].fTags, length(fObjectList.Items[i].fTags) - 1);
        break;
        end;
end;

procedure TSetCreator.AssignSelectedPreview(Event: String; Data, Result: Pointer);
begin
  if Data = Pointer(fObjectPreview) then
    if (Result <> nil) and (fObjectPreview.SelectedItem <> nil) then
      begin
      fObjectList.SelectedItem.fImageFileName := TTextureSelectItem(Result).Name;
      fObjectList.SelectedItem.fImage.Tex := TTextureSelectItem(Result).fImage.Tex;
      end;
end;

procedure TSetCreator.CloseEvent(Event: String; Data, Result: Pointer);
begin
  if Data = Pointer(fCloseDialog) then
    begin
    fCanClose := Event = 'TYesNoDialog.Yes';
    EventManager.RemoveCallback(@CloseEvent);
    fCloseDialog.Free;
    end;
end;

procedure TSetCreator.FileSelected(Event: String; Data, Result: Pointer);
begin
  if Event = 'TFileDialog.Selected' then
    begin
    fFilepath := fSaveDialog.FileName;
    WriteXMLFile(GatherData, fFilepath + '.xml');
    GetOCFFile.SaveTo(fFilepath);
    ModuleManager.ModOCFManager.ReloadOCFFile(fFilepath, '', nil);
    end;
  EventManager.RemoveCallback(@FileSelected);
  fSaveDialog.Free;
end;

procedure TSetCreator.SetFileSelected(Event: String; Data, Result: Pointer);
begin
  if Event = 'TFileDialog.Selected' then
    begin
    fFilepath := fOpenSetDialog.FileName + '.xml';
    if FileExists(fFilepath) then
      LoadFromFile(fFilepath)
    else
      ModuleManager.ModLog.AddError('Corresponding XML file not found');
    end;
  EventManager.RemoveCallback(@SetFileSelected);
  fOpenSetDialog.Free;
end;

procedure TSetCreator.OCFFileSelected(Event: String; Data, Result: Pointer);
begin
  if Event = 'TFileDialog.Selected' then
    TObjectSelectItem.Create(fOpenDialog.FileName, fObjectList);
  fOpenDialogPath := fOpenDialog.Directory;
  EventManager.RemoveCallback(@OCFFileSelected);
  fOpenDialog.Free;
end;

procedure TSetCreator.ImageFileSelected(Event: String; Data, Result: Pointer);
begin
  if Event = 'TFileDialog.Selected' then
    begin
    TTextureSelectItem.Create(fPreviewDialog.FileName, fAllPreviews);
    TTextureSelectItem.Create(fPreviewDialog.FileName, fObjectPreview);
    TTextureSelectItem.Create(fPreviewDialog.FileName, fSetPreview);
    end;
  fPreviewDialogPath := fPreviewDialog.Directory;
  EventManager.RemoveCallback(@ImageFileSelected);
  fPreviewDialog.Free;
end;

procedure TSetCreator.Close(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TYesNoDialog.Yes', @CloseEvent);
  EventManager.AddCallback('TYesNoDialog.No', @CloseEvent);
  fCloseDialog := TYesNoDialog.Create('Really quit the set creator?', 'dialog-information.tga');
end;

procedure TSetCreator.Save(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TFileDialog.Selected', @FileSelected);
  EventManager.AddCallback('TFileDialog.Aborted', @FileSelected);
  fSaveDialog := TFileDialog.Create(False, 'scenery', 'Save set');
end;

procedure TSetCreator.Load(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TFileDialog.Selected', @SetFileSelected);
  EventManager.AddCallback('TFileDialog.Aborted', @SetFileSelected);
  fOpenSetDialog := TFileDialog.Create(True, 'scenery', 'Open set');
end;

procedure TSetCreator.AddPreview(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TFileDialog.Selected', @ImageFileSelected);
  EventManager.AddCallback('TFileDialog.Aborted', @ImageFileSelected);
  fPreviewDialog := TFileDialog.Create(True, fPreviewDialogPath, 'Load preview image', [ftIMG]);
end;

procedure TSetCreator.RemovePreview(Sender: TGUIComponent);
var
  i: Integer;
begin
  if fAllPreviews.SelectedItem <> nil then
    begin
    for i := 0 to fObjectList.Count - 1 do
      if fObjectList.Items[i].fImageFileName = fAllPreviews.SelectedItem.Name then
        begin
        fObjectList.Items[i].fImage.Tex := nil;
        fObjectList.Items[i].fImageFileName := '';
        end;
    
    fObjectPreview.DeleteItem(fObjectPreview.GetItem(fAllPreviews.SelectedItem.Name));
    fSetPreview.DeleteItem(fSetPreview.GetItem(fAllPreviews.SelectedItem.Name));
    fAllPreviews.DeleteItem(fAllPreviews.SelectedItem);
    end;
end;

procedure TSetCreator.AddObject(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TFileDialog.Selected', @OCFFileSelected);
  EventManager.AddCallback('TFileDialog.Aborted', @OCFFileSelected);
  fOpenDialog := TFileDialog.Create(True, fOpenDialogPath, 'Load object file', [ftOCF]);
end;

procedure TSetCreator.DeleteObject(Sender: TGUIComponent);
begin
  if fObjectList.SelectedItem <> nil then
    fObjectList.DeleteItem(fObjectList.SelectedItem);
end;

procedure TSetCreator.ChangeData(Sender: TGUIComponent);
begin
  if fObjectList.SelectedItem <> nil then
    begin
    fObjectList.SelectedItem.fObjectName := fObjectName.Text;
    fObjectList.SelectedItem.fDescription := fObjectDescription.Text;
    end;
end;

procedure TSetCreator.TabChanged(Sender: TGUIComponent);
begin
  fTabContainer.Left := -784 * fTabBar.SelectedTab;
end;

procedure TSetCreator.AddTag(Sender: TGUIComponent);
var
  ToAdd: String;
begin
  ToAdd := fTagName.Text;
  fTagName.Text := '';

  if fTagList.GetItem(ToAdd) = nil then
    TTagSelectItem.Create(ToAdd, fTagList);
end;


function TSetCreator.GatherData: TDOMDocument;
var
  i, j: Integer;
begin
  Result := TDOMDocument.Create;
  Result.AppendChild(Result.CreateElement('set'));

  // Set info - everything from the first page
  Result.LastChild.AppendChild(Result.CreateElement('info'));
  
  Result.LastChild.LastChild.AppendChild(Result.CreateElement('name'));
  Result.LastChild.LastChild.LastChild.AppendChild(Result.CreateTextNode(fSetName.Text));

  Result.LastChild.LastChild.AppendChild(Result.CreateElement('description'));
  Result.LastChild.LastChild.LastChild.AppendChild(Result.CreateTextNode(fSetDescription.Text));

  Result.LastChild.LastChild.AppendChild(Result.CreateElement('preview'));

  if fSetPreview.SelectedItem = nil then
    ModuleManager.ModLog.AddError('No set preview selected!')
  else
    Result.LastChild.LastChild.LastChild.AppendChild(Result.CreateTextNode(SystemIndependentFileName(fSetPreview.SelectedItem.Name)));


  // All the previews
  Result.LastChild.AppendChild(Result.CreateElement('previews'));

  for i := 0 to fAllPreviews.Count - 1 do
    begin
    Result.LastChild.LastChild.AppendChild(Result.CreateElement('image'));
    Result.LastChild.LastChild.LastChild.AppendChild(Result.CreateTextNode(SystemIndependentFileName(fAllPreviews.Items[i].Name)));
    end;

  // All the objects
  Result.LastChild.AppendChild(Result.CreateElement('objects'));

  for i := 0 to fObjectList.Count - 1 do
    begin
    Result.LastChild.LastChild.AppendChild(Result.CreateElement('object'));

    Result.LastChild.LastChild.LastChild.AppendChild(Result.CreateElement('name'));
    Result.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.CreateTextNode(fObjectList.Items[i].fObjectName));

    Result.LastChild.LastChild.LastChild.AppendChild(Result.CreateElement('description'));
    Result.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.CreateTextNode(fObjectList.Items[i].fDescription));

    Result.LastChild.LastChild.LastChild.AppendChild(Result.CreateElement('file'));
    Result.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.CreateTextNode(SystemIndependentFileName(fObjectList.Items[i].Name)));

    Result.LastChild.LastChild.LastChild.AppendChild(Result.CreateElement('preview'));
    Result.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.CreateTextNode(SystemIndependentFileName(fObjectList.Items[i].fImageFileName)));

    Result.LastChild.LastChild.LastChild.AppendChild(Result.CreateElement('tags'));

    for j := 0 to high(fObjectList.Items[i].fTags) do
      begin
      Result.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.CreateElement('tag'));
      Result.LastChild.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.CreateTextNode(fObjectList.Items[i].fTags[j]));
      end;
    end;
end;

function TSetCreator.GetOCFFile: TOCFFile;
var
  i, j, k: Integer;
  Images, Authors, SingleFileAuthors: AString;
  b: TOCFBinarySection;
  AuthorString: String;
  O: TOCFFile;
  Found: Boolean;

  function GetID(Name: String): String;
  var
    i: Integer;
  begin
    Result := '0';
    for i := 0 to high(Images) do
      if Images[i] = Name then
        Result := IntToStr(I);
  end;
begin
  Result := TOCFFile.Create('');

  SetLength(Images, fAllPreviews.Count);
  for i := 0 to high(Images) do
    begin
    Images[i] := SystemIndependentFileName(fAllPreviews.Items[i].Name);
    b := TOCFBinarySection.Create;
    with DBCGFromTex(TexFromStream(ByteStreamFromFile(Images[i]), ExtractFileExt(Images[i]))) do
      b.Replace(@Data[0], length(Data));
    Result.AddBinarySection(b);
    end;

  for i := 0 to fObjectList.Count - 1 do
    begin
    O := TOCFFile.Create(fObjectList.Items[i].Name);

    SingleFileAuthors := Explode(',', TDOMElement(O.XML.Document.FirstChild).GetAttribute('author'));

    for j := 0 to high(SingleFileAuthors) do
      begin
      Found := False;

      for k := 0 to high(Authors) do
        if Authors[k] = SingleFileAuthors[j] then
          Found := True;

      if not Found then
        begin
        setLength(Authors, length(Authors) + 1);
        Authors[high(Authors)] := SingleFileAuthors[j];
        end;
      end;

    O.Free;
    end;

  AuthorString := '';

  for i := 0 to high(Authors) do
    begin
    if AuthorString <> '' then
      AuthorString += ', ';
    AuthorString += Authors[i];
    end;
  
  TDOMElement(Result.XML.Document.FirstChild).SetAttribute('author', AuthorString);
  TDOMElement(Result.XML.Document.FirstChild).SetAttribute('type', 'set');

  Result.XML.Document.FirstChild.AppendChild(Result.XML.Document.CreateElement('resources'));
  for i := 0 to high(Images) do
    begin
    Result.XML.Document.FirstChild.LastChild.AppendChild(Result.XML.Document.CreateElement('resource'));
    TDOMElement(Result.XML.Document.FirstChild.LastChild.LastChild).SetAttribute('resource:id', IntToStr(i));
    TDOMElement(Result.XML.Document.FirstChild.LastChild.LastChild).SetAttribute('resource:section', IntToStr(i));
    TDOMElement(Result.XML.Document.FirstChild.LastChild.LastChild).SetAttribute('resource:format', 'dbcg');
    TDOMElement(Result.XML.Document.FirstChild.LastChild.LastChild).SetAttribute('resource:version', '1.0');
    end;

  Result.XML.Document.FirstChild.AppendChild(Result.XML.Document.CreateElement('set'));

  // Set info - everything from the first page
  Result.XML.Document.FirstChild.LastChild.AppendChild(Result.XML.Document.CreateElement('info'));

  Result.XML.Document.FirstChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateElement('name'));
  Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateTextNode(fSetName.Text));

  Result.XML.Document.FirstChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateElement('description'));
  Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateTextNode(fSetDescription.Text));

  Result.XML.Document.FirstChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateElement('preview'));

  if fSetPreview.SelectedItem = nil then
    TDOMElement(Result.XML.Document.LastChild.LastChild.LastChild.LastChild).SetAttribute('resource:id', '0')
  else
    TDOMElement(Result.XML.Document.LastChild.LastChild.LastChild.LastChild).SetAttribute('resource:id', GetID(SystemIndependentFileName(fSetPreview.SelectedItem.Name)));

  Result.XML.Document.FirstChild.LastChild.AppendChild(Result.XML.Document.CreateElement('objects'));

  for i := 0 to fObjectList.Count - 1 do
    begin
    Result.XML.Document.FirstChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateElement('object'));

    Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateElement('name'));
    Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateTextNode(fObjectList.Items[i].fObjectName));

    Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateElement('description'));
    Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateTextNode(fObjectList.Items[i].fDescription));

    Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateElement('file'));
    Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateTextNode(SystemIndependentFileName(fObjectList.Items[i].Name)));

    Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateElement('preview'));
    TDOMElement(Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.LastChild).SetAttribute('resource:id', GetID(SystemIndependentFileName(fObjectList.Items[i].fImageFileName)));

    Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateElement('tags'));

    for j := 0 to high(fObjectList.Items[i].fTags) do
      begin
      Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateElement('tag'));
      Result.XML.Document.FirstChild.LastChild.LastChild.LastChild.LastChild.LastChild.AppendChild(Result.XML.Document.CreateTextNode(fObjectList.Items[i].fTags[j]));
      end;
    end;
end;

procedure TSetCreator.LoadFromFile(FileName: String);
var
  A: TDOMDocument;
  i: Integer;
  E, F, G: TDOMElement;
  coName, coDescription, coFile, coPreview: String;
  coTags: Array of String;
begin
  try
    // Clear everything

    // Objects
    while fObjectList.Count > 0 do
      fObjectList.DeleteItem(fObjectList.Items[fObjectList.Count - 1]);

    // Tags
    while fTagList.Count > 0 do
      begin
      fTagList.DeleteItem(fTagList.Items[fTagList.Count - 1]);
      fTagList.FinalDeleteItem(nil);
      end;
    RestoreDefaultTagList;

    // Previews
    while fAllPreviews.Count > 0 do
      begin
      fAllPreviews.fSelectedItem := fAllPreviews.Items[fAllPreviews.Count - 1];
      RemovePreview(nil);
      end;

    fSetName.Text := '';
    fSetDescription.Text := '';

    // Now add the stuff in the set

    A := LoadXMLFile(FileName);

    // Previews
    E := TDOMElement(A.GetElementsByTagName('previews')[0].FirstChild);
    while E <> nil do
      begin
      TTextureSelectItem.Create(E.FirstChild.NodeValue, fAllPreviews);
      TTextureSelectItem.Create(E.FirstChild.NodeValue, fObjectPreview);
      TTextureSelectItem.Create(E.FirstChild.NodeValue, fSetPreview);

      E := TDOMElement(E.NextSibling);
      end;

    // Objects
    E := TDOMElement(A.GetElementsByTagName('objects')[0].FirstChild);
    while E <> nil do
      begin
      F := TDOMElement(E.FirstChild);

      coName := '';
      coFile := '';
      coDescription := '';
      coPreview := '';
      setLength(coTags, 0);

      while F <> nil do
        begin
        if F.TagName = 'name' then
          coName := F.FirstChild.NodeValue
        else if F.TagName = 'description' then
          coDescription := F.FirstChild.NodeValue
        else if F.TagName = 'file' then
          coFile := F.FirstChild.NodeValue
        else if F.TagName = 'preview' then
          coPreview := F.FirstChild.NodeValue
        else if F.TagName = 'tags' then
          begin
          G := TDOMElement(F.FirstChild);

          while G <> nil do
            begin
            SetLength(coTags, length(coTags) + 1);
            coTags[high(coTags)] := G.FirstChild.NodeValue;

            if fTagList.GetItem(coTags[high(coTags)]) = nil then
              TTagSelectItem.Create(coTags[high(coTags)], fTagList);

            G := TDOMElement(G.NextSibling);
            end;
          end;

        F := TDOMElement(F.NextSibling);
        end;

      with TObjectSelectItem.Create(coFile, fObjectList) do
        begin
        fDescription := coDescription;
        fObjectName := coName;
        fImageFileName := coPreview;
        setLength(fTags, length(coTags));
        for i := 0 to high(fTags) do
          fTags[i] := coTags[i];
        fImage.Tex := fObjectPreview.GetItem(coPreview).fImage.Tex;
        end;

      E := TDOMElement(E.NextSibling);
      end;

    // Set
    E := TDOMElement(A.GetElementsByTagName('info')[0].FirstChild);
    while E <> nil do
      begin
      if E.TagName = 'name' then
        fSetName.Text := E.FirstChild.NodeValue
      else if E.TagName = 'description' then
        fSetDescription.Text := E.FirstChild.NodeValue
      else if E.TagName = 'preview' then
        fSetPreview.GetItem(E.FirstChild.NodeValue).fOnClick(nil);

      E := TDOMElement(E.NextSibling);
      end;

    A.Free;
  except
    ModuleManager.ModLog.AddError('Loading of ' + FileName + ' failed: Corrupt file?');
  end;
end;

procedure TSetCreator.RestoreDefaultTagList;
begin
  TTagSelectItem.Create('Buildings', fTagList);
  TTagSelectItem.Create('Walls', fTagList);
  TTagSelectItem.Create('Roofs', fTagList);
  TTagSelectItem.Create('Plants & Trees', fTagList);
  TTagSelectItem.Create('Fences', fTagList);
  TTagSelectItem.Create('Particles', fTagList);
  TTagSelectItem.Create('Sounds', fTagList);
  TTagSelectItem.Create('Flatrides', fTagList);
  TTagSelectItem.Create('Tracked Rides', fTagList);
  TTagSelectItem.Create('Stalls', fTagList);
end;

constructor TSetCreator.Create;
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
  fTabBar.AddTab('Set');
  fTabBar.AddTab('Previews');
  fTabBar.AddTab('Resources');
  fTabBar.OnChangeTab := @TabChanged;

  fTabContainer2 := TLabel.Create(fWindow);
  fTabContainer2.Left := 8;
  fTabContainer2.Top := 40;
  fTabContainer2.Width := 784;
  fTabContainer2.Height := 552;
  
  fTabContainer := TLabel.Create(fTabContainer2);
  fTabContainer.Left := 0;
  fTabContainer.Top := 0;
  fTabContainer.Width := 3 * 784;
  fTabContainer.Height := 552;

  fSetTab := TLabel.Create(fTabContainer);
  fSetTab.Left := 0;
  fSetTab.Top := 0;
  fSetTab.Height := 552;
  fSetTab.Width := 784;
  
  fPreviewTab := TLabel.Create(fTabContainer);
  fPreviewTab.Left := 784;
  fPreviewTab.Top := 0;
  fPreviewTab.Height := 552;
  fPreviewTab.Width := 784;

  fObjectTab := TLabel.Create(fTabContainer);
  fObjectTab.Left := 2 * 784;
  fObjectTab.Top := 0;
  fObjectTab.Height := 552;
  fObjectTab.Width := 784;

  // Set tab

  fCloseButton := TIconifiedButton.Create(fSetTab);
  fCloseButton.Left := 784 - 64;
  fCloseButton.Top := 552 - 56;
  fCloseButton.Width := 48;
  fCloseButton.Height := 48;
  fCloseButton.Icon := 'edit-delete.tga';
  fCloseButton.OnClick := @Close;

  fSaveButton := TIconifiedButton.Create(fSetTab);
  fSaveButton.Left := 784 - 64 - 56;
  fSaveButton.Top := 552 - 56;
  fSaveButton.Width := 48;
  fSaveButton.Height := 48;
  fSaveButton.Icon := 'document-save.tga';
  fSaveButton.OnClick := @Save;

  fLoadButton := TIconifiedButton.Create(fSetTab);
  fLoadButton.Left := 784 - 64 - 56 - 56;
  fLoadButton.Top := 552 - 56;
  fLoadButton.Width := 48;
  fLoadButton.Height := 48;
  fLoadButton.Icon := 'document-open.tga';
  fLoadButton.OnClick := @Load;

  fLogo := TImage.Create(fSetTab);
  fLogo.Left := 784 - 200;
  fLogo.Top := 8;
  fLogo.Width := 192;
  fLogo.Height := 192;
  fLogo.FreeTextureOnDestroy := True;
  fLogo.Tex := TTexture.Create;
  fLogo.Tex.FromFile('general/setcreator-logo.tga', false, false);

  with TLabel.Create(fSetTab) do
    begin
    Left := 8;
    Top := 8;
    Height := 16;
    Size := 16;
    Width := 150;
    Caption := 'Name:';
    end;
    
  fSetName := TEdit.Create(fSetTab);
  fSetName.Top := 0;
  fSetName.Left := 158;
  fSetName.Width := 400;
  fSetName.Height := 32;

  with TLabel.Create(fSetTab) do
    begin
    Left := 8;
    Top := 40;
    Height := 16;
    Size := 16;
    Width := 150;
    Caption := 'Description:';
    end;

  fSetDescription := TEdit.Create(fSetTab);
  fSetDescription.Top := 32;
  fSetDescription.Left := 158;
  fSetDescription.Width := 400;
  fSetDescription.Height := 32;

  with TLabel.Create(fSetTab) do
    begin
    Left := 8;
    Top := 64;
    Height := 24;
    Size := 24;
    Width := 400;
    Caption := 'Preview:';
    end;

  fSetPreview := TTextureSelect.Create(fSetTab);
  fSetPreview.Left := 8;
  fSetPreview.Height := 448;
  fSetPreview.Top := 88;
  fSetPreview.Width := 568;
  fSetPreview.VScrollBar := sbmInverted;
  fSetPreview.HScrollBar := sbmInvisible;

  // Preview tab

  fAllPreviews := TTextureSelect.Create(fPreviewTab);
  fAllPreviews.Left := 8;
  fAllPreviews.Width := 768;
  fAllPreviews.Top := 8;
  fAllPreviews.Height := 488;
  fAllPreviews.HScrollBar := sbmInvisible;
  
  fAdd := TIconifiedButton.Create(fPreviewTab);
  fAdd.Left := 784 - 64;
  fAdd.Top := 552 - 56;
  fAdd.Width := 48;
  fAdd.Height := 48;
  fAdd.Icon := 'list-add.tga';
  fAdd.OnClick := @AddPreview;

  fRemove := TIconifiedButton.Create(fPreviewTab);
  fRemove.Left := 784 - 64 - 56;
  fRemove.Top := 552 - 56;
  fRemove.Width := 48;
  fRemove.Height := 48;
  fRemove.Icon := 'list-remove.tga';
  fRemove.OnClick := @RemovePreview;

  // Object tab

  with TLabel.Create(fObjectTab) do
    begin
    Left := 8;
    Width := 250;
    Height := 24;
    Size := 24;
    Top := 8;
    Caption := 'Objects:';
    end;

  fObjectList := TObjectSelect.Create(fObjectTab);
  fObjectList.Left := 8;
  fObjectList.Top := 32;
  fObjectList.Height := 456;
  fObjectList.Width := 250;
  fObjectList.VScrollBar := sbmInverted;
  fObjectList.HScrollBar := sbmInvisible;
  EventManager.AddCallback('TObjectSelect.Changed', @SelectCorrectPreview);

  fAddObject := TIconifiedButton.Create(fObjectTab);
  fAddObject.Left := 8;
  fAddObject.Top := 496;
  fAddObject.Width := 48;
  fAddObject.Height := 48;
  fAddObject.Icon := 'list-add.tga';
  fAddObject.OnClick := @AddObject;

  fDelObject := TIconifiedButton.Create(fObjectTab);
  fDelObject.Left := 64;
  fDelObject.Top := 496;
  fDelObject.Width := 48;
  fDelObject.Height := 48;
  fDelObject.Icon := 'list-remove.tga';
  fDelObject.OnClick := @DeleteObject;

  with TLabel.Create(fObjectTab) do
    begin
    Left := 526;
    Width := 250;
    Height := 24;
    Size := 24;
    Top := 8;
    Caption := 'Preview:';
    end;

  fObjectPreview := TTextureSelect.Create(fObjectTab);
  fObjectPreview.Left := 526;
  fObjectPreview.Top := 32;
  fObjectPreview.Height := 512;
  fObjectPreview.Width := 250;
  fObjectPreview.HScrollBar := sbmInvisible;
  EventManager.AddCallback('TTextureSelect.Changed', @AssignSelectedPreview);

  with TLabel.Create(fObjectTab) do
    begin
    Left := 264;
    Width := 200;
    Height := 16;
    Size := 16;
    Top := 8;
    Caption := 'Name:';
    end;

  with TLabel.Create(fObjectTab) do
    begin
    Left := 264;
    Width := 200;
    Height := 16;
    Size := 16;
    Top := 56;
    Caption := 'Description:';
    end;

  fObjectName := TEdit.Create(fObjectTab);
  fObjectName.Top := 24;
  fObjectName.Left := 264;
  fObjectName.Width := 254;
  fObjectName.Height := 32;
  fObjectName.OnChange := @ChangeData;

  fObjectDescription := TEdit.Create(fObjectTab);
  fObjectDescription.Top := 72;
  fObjectDescription.Left := 264;
  fObjectDescription.Width := 254;
  fObjectDescription.Height := 32;
  fObjectDescription.OnChange := @ChangeData;

  with TLabel.Create(fObjectTab) do
    begin
    Left := 264;
    Width := 200;
    Height := 16;
    Size := 16;
    Top := 112;
    Caption := 'Tags:';
    end;

  fTagList := TTagSelect.Create(fObjectTab);
  fTagList.Left := 264;
  fTagList.Top := 128;
  fTagList.Height := 392;
  fTagList.Width := 254;
  fTagList.HScrollBar := sbmInvisible;
  EventManager.AddCallback('TTagSelectItem.Selected', @AssignTags);
  EventManager.AddCallback('TTagSelectItem.Deleted', @DeleteTags);

  fTagName := TEdit.Create(fObjectTab);
  fTagName.Top := 520;
  fTagName.Left := 264;
  fTagName.Width := 222;
  fTagName.Height := 32;

  fAddTag := TIconifiedButton.Create(fObjectTab);
  fAddTag.Top := 520;
  fAddTag.Left := 264 + 174 + 48;
  fAddTag.Width := 32;
  fAddTag.Height := 32;
  fAddTag.Icon := 'list-add.tga';
  fAddTag.OnClick := @AddTag;

  fOpenDialogPath := 'scenery';
  fPreviewDialogPath := 'scenery';

  RestoreDefaultTagList;
end;

destructor TSetCreator.Destroy;
begin
  fBGLabel.Free;
end;

end.