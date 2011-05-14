unit s_setcreator;

interface

uses
  SysUtils, Classes, m_gui_class, m_gui_window_class, m_gui_button_class, m_gui_edit_class, m_gui_iconifiedbutton_class, m_gui_label_class,
  m_gui_scrollbox_class, m_gui_slider_class, m_gui_progressbar_class, m_gui_checkbox_class, m_gui_tabbar_class, m_gui_image_class, u_dialogs,
  m_texmng_class, u_vectors;

type
  TTextureSelect = class;
  TObjectSelect = class;

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
      fCloseButton, fSaveButton: TIconifiedButton;
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
//       fTagList: TTagSelect;
      fTagName: TEdit;
      fAddTag, fDelTag: TIconifiedButton;
      fAddObject, fDelObject: TIconifiedButton;

      // Dialog
      fCloseDialog: TYesNoDialog;
      fSaveDialog: TFileDialog;
      fPreviewDialog: TFileDialog;
      fOpenDialog: TFileDialog;

      // Callbacks
      procedure CloseEvent(Event: String; Data, Result: Pointer);
      procedure FileSelected(Event: String; Data, Result: Pointer);
      procedure OCFFileSelected(Event: String; Data, Result: Pointer);
      procedure ImageFileSelected(Event: String; Data, Result: Pointer);
      procedure AssignSelectedPreview(Event: String; Data, Result: Pointer);
      procedure SelectCorrectPreview(Event: String; Data, Result: Pointer);

      procedure ChangeData(Sender: TGUIComponent);
      procedure TabChanged(Sender: TGUIComponent);
      procedure Close(Sender: TGUIComponent);
      procedure Save(Sender: TGUIComponent);
      procedure AddPreview(Sender: TGUIComponent);
      procedure RemovePreview(Sender: TGUIComponent);
      procedure AddObject(Sender: TGUIComponent);
      procedure DeleteObject(Sender: TGUIComponent);
    public
      property CanClose: Boolean read fCanClose;
      constructor Create;
      destructor Free;
    end;

var
  SetCreator: TSetCreator = nil;

implementation

uses
  m_varlist, math, u_math, u_events, u_functions;

procedure TTextureSelectItem.fOnClick(Sender: TGUIComponent);
begin
  if Sender <> nil then
    EventManager.CallEvent('TTextureSelect.Changed', fSelect, Self);

  if fSelect.SelectedItem <> nil then
    fSelect.SelectedItem.Color := fSelect.SelectedItem.fBasicColor;

  Color := Vector(0.5, 0.7, 1.0, 1.0);
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

  Color := Vector(0.5, 0.7, 1.0, 1.0);
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
        fItems[i].Color := fItems[i].fBasicColor;
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
  Colors[1] := Vector(0.8, 0.8, 0.8, 1.0);

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
        fItems[i].Color := fItems[i].fBasicColor;
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

  fSelectedItem := nil;

  Width := 416;
  Top := 0;
  Left := 0;
  Height := 0;
end;


procedure TSetCreator.SelectCorrectPreview(Event: String; Data, Result: Pointer);
begin
  if fObjectPreview.GetItem(TObjectSelectItem(Result).fImageFileName) <> nil then
    fObjectPreview.GetItem(TObjectSelectItem(Result).fImageFileName).fOnClick(nil);
  fObjectName.Text := TObjectSelectItem(Result).fObjectName;
  fObjectDescription.Text := TObjectSelectItem(Result).fDescription;
end;

procedure TSetCreator.AssignSelectedPreview(Event: String; Data, Result: Pointer);
begin
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
    fFilepath := fSaveDialog.FileName;
  EventManager.RemoveCallback(@FileSelected);
  fSaveDialog.Free;
end;

procedure TSetCreator.OCFFileSelected(Event: String; Data, Result: Pointer);
begin
  if Event = 'TFileDialog.Selected' then
    TObjectSelectItem.Create(fOpenDialog.FileName, fObjectList);
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

procedure TSetCreator.AddPreview(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TFileDialog.Selected', @ImageFileSelected);
  EventManager.AddCallback('TFileDialog.Aborted', @ImageFileSelected);
  fPreviewDialog := TFileDialog.Create(True, 'scenery', 'Load preview image', [ftIMG]);
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
  fOpenDialog := TFileDialog.Create(True, 'scenery', 'Load object file', [ftOCF]);
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
  fTabContainer.Left := 8;
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
end;

destructor TSetCreator.Free;
begin
  fBGLabel.Free;
end;

end.