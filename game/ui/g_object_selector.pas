unit g_object_selector;

interface

uses
  SysUtils, Classes, u_events, g_park, g_parkui,
  m_gui_label_class, m_gui_edit_class, m_gui_tabbar_class, m_gui_button_class, m_gui_iconifiedbutton_class,
  m_gui_scrollbox_class, m_gui_class, m_gui_image_class, g_sets,
  u_scene;

type
  TGameObjectSelectorTagList = class;
  TGameObjectSelectorObjectTreeList = class;
  TGameObjectSelectorSetEntry = class;
  TGameObjectSelector = class;

  TGameObjectSelectorTagListItem = class(TLabel)
    protected
      fAlphaOffset: Single;
      fInnerLabel: TLabel;
      fTagName: String;
      fChecked: Boolean;
      procedure fChangeState(Sender: TGUIComponent);
      procedure SetAlphaOffset(S: Single);
      procedure UpdateColor;
      procedure SetChecked(B: Boolean);
    public
      property AlphaOffset: Single read fAlphaOffset write SetAlphaOffset;
      property Checked: Boolean read fChecked write SetChecked;
      property TagName: String read fTagName;
      constructor Create(fTag: String; TheParent: TGameObjectSelectorTagList);
    end;

  TGameObjectSelectorTagList = class(TScrollBox)
    private
      fTags: Array of TGameObjectSelectorTagListItem;
    public
      procedure AddTag(fTag: String);
      constructor Create(TheParent: TGUIComponent);
    end;

  TGameObjectSelectorObjectEntry = class(TLabel)
    protected
      fObject: TGameObjectItem;
      fSet: TGameObjectSelectorSetEntry;
      
      fName, fDescription: TLabel;
      fPreview: TImage;

      fID: Integer;
      fVisible: Boolean;
      procedure LoadedObject(Event: String; Data, Result: Pointer);
      procedure fSelect(Sender: TGUIComponent);
    public
      property ID: Integer read fID;
      property Visible: Boolean read fVisible;
      property TheObject: TGameObjectItem read fObject;
      property SetEntry: TGameObjectSelectorSetEntry read fSet;
      procedure Show;
      procedure Hide;
      function Match(S: String): Boolean;
      constructor Create(GameObject: TGameObjectItem; TheParent: TGameObjectSelectorSetEntry; TheID: Integer);
    end;

  TGameObjectSelectorSetEntry = class(TLabel)
    protected
      fTree: TGameObjectSelectorObjectTreeList;
      fSet: TGameSetItem;
      
      fObjectItems: Array of TGameObjectSelectorObjectEntry;

      fName, fAuthors, fDescription: TLabel;
      fPreview: TImage;
      fExpand: TIconifiedButton;
    
      fExpanded, fVisible: Boolean;
      fShownObjects: Integer;
      procedure SwitchState(Sender: TGUIComponent);
      procedure SetState(S: Boolean);
    public
      property Tree: TGameObjectSelectorObjectTreeList read fTree;
      property ShownObjects: Integer read fShownObjects;
      property Expanded: Boolean read fExpanded write SetState;
      property Visible: Boolean read fVisible;
      procedure MoveItems;
      procedure Show;
      procedure Hide;
      procedure ReassignColors;
      procedure AddObject(O: TGameObjectItem);
      function Filter(S: String): Boolean;
      constructor Create(GameSet: TGameSetItem; TheParent: TGameObjectSelectorObjectTreeList);
    end;

  TGameObjectSelectorObjectTreeList = class(TScrollBox)
    private
      fSelected: TGameObjectSelectorObjectEntry;
    protected
      fSetItems: Array of TGameObjectSelectorSetEntry;
      fTheParent: TGameObjectSelector;
    public
      property Selected: TGameObjectSelectorObjectEntry read fSelected;
      property Selector: TGameObjectSelector read fTheParent;
      function Filter(S: String): Boolean;
      procedure MoveItems;
      procedure ReassignColors;
      procedure AddSet(S: TGameSetItem);
      constructor Create(TheParent: TGameObjectSelector);
    end;

  TGameObjectSelector = class(TXMLUIWindow)
    protected
      fTagList: TGameObjectSelectorTagList;
      fSetList: TGameObjectSelectorObjectTreeList;
    public
      procedure DoBuild(Event: String; Data, Result: Pointer);
      procedure DoFilter(Event: String; Data, Result: Pointer);
      procedure OnClose(Event: String; Data, Result: Pointer);
      property TagList: TGameObjectSelectorTagList read fTagList;
      property SetList: TGameObjectSelectorObjectTreeList read fSetList;
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  m_varlist, u_functions, u_vectors, u_math, u_dom, g_terrain_edit, u_selection, g_objects, g_object_builder;

procedure TGameObjectSelectorTagListItem.fChangeState(Sender: TGUIComponent);
begin
  Checked := not Checked;
  EventManager.CallEvent('GUIActions.object_selector.do_filter', Sender, nil);
end;

procedure TGameObjectSelectorTagListItem.SetChecked(B: Boolean);
begin
  fChecked := B;
  UpdateColor;
end;

procedure TGameObjectSelectorTagListItem.UpdateColor;
begin
  if fChecked then
    Color := Vector(1, 1, 1, 0.8 + fAlphaOffset)
  else
    Color := Vector(1, 1, 1, fAlphaOffset);
end;

procedure TGameObjectSelectorTagListItem.SetAlphaOffset(S: Single);
begin
  fAlphaOffset := S;
  UpdateColor;
end;

constructor TGameObjectSelectorTagListItem.Create(fTag: String; TheParent: TGameObjectSelectorTagList);
begin
  inherited Create(TheParent.Surface);

  fTagName := fTag;
  fChecked := False;

  Height := 32;
  Width := 172 - 16;
  Left := 0;
  Top := 0;
  Size := 16;
  OnClick := @fChangeState;
  fAlphaOffset := 0;

  fInnerLabel := TLabel.Create(Self);
  fInnerLabel.Width := 172 - 24;
  fInnerLabel.Left := 8;
  fInnerLabel.Top := 8;
  fInnerLabel.Height := 16;
  fInnerLabel.Size := 16;
  fInnerLabel.Caption := fTagName;
  fInnerLabel.OnClick := @fChangeState;
end;




procedure TGameObjectSelectorTagList.AddTag(fTag: String);
var
  i, j: Integer;
  t: TGameObjectSelectorTagListItem;
begin
  for i := 0 to high(fTags) do
    if fTags[i].TagName = fTag then
      exit;

  t := TGameObjectSelectorTagListItem.Create(fTag, Self);

  SetLength(fTags, length(fTags) + 1);
  i := high(fTags);

  while i > 0 do
    if StrCmp(fTag, fTags[i - 1].TagName) < 0 then
      dec(i)
    else
      break;

  for j := high(fTags) - 1 downto i do
    begin
    fTags[j].Top := 32 * (j + 1);
    if j mod 2 = 0 then
      fTags[j].AlphaOffset := 0
    else
      fTags[j].AlphaOffset := 0.1;
    fTags[j + 1] := fTags[j];
    end;

  t.Top := 32 * i;
  if i mod 2 = 1 then
    t.AlphaOffset := 0
  else
    t.AlphaOffset := 0.1;
  fTags[i] := t;
  t.Checked := True;
end;

constructor TGameObjectSelectorTagList.Create(TheParent: TGUIComponent);
begin
  inherited Create(TheParent);
end;


procedure TGameObjectSelectorObjectEntry.LoadedObject(Event: String; Data, Result: Pointer);
begin
  if fSet.Tree.Selected = Self then
    begin
    TLabel(fSet.Tree.Selector.Window.GetChildByName('object_selector.object.author')).Caption := TDOMElement(fObject.GameObject.Resource.OCFFile.XML.Document.FirstChild).GetAttribute('author');
    TIconifiedButton(fSet.Tree.Selector.Window.GetChildByName('object_selector.object.build')).Alpha := 1;
    end;

  EventManager.RemoveCallback(Event, @LoadedObject);
end;

procedure TGameObjectSelectorObjectEntry.fSelect(Sender: TGUIComponent);
begin
  if fSet.Tree.Selected <> nil then
    fSet.Tree.Selected.Color := Vector(0.8, 0.8, 0.8, 1.0);
  fSet.Tree.fSelected := Self;
  Color := Vector(0.5, 0.7, 1.0, 1.0);

  TLabel(fSet.Tree.Selector.Window.GetChildByName('object_selector.object.name')).Caption := fObject.GameObject.Name;
  TLabel(fSet.Tree.Selector.Window.GetChildByName('object_selector.object.set')).Caption := fObject.GameObject.GameSet.Name;
  TLabel(fSet.Tree.Selector.Window.GetChildByName('object_selector.object.description')).Caption := fObject.GameObject.Description;
  TLabel(fSet.Tree.Selector.Window.GetChildByName('object_selector.object.tags')).Caption := Implode(#10, fObject.GameObject.ListTags);

  TIconifiedButton(fSet.Tree.Selector.Window.GetChildByName('object_selector.object.build')).Alpha := 0;
  if fObject.GameObject.Resource = nil then
    fObject.GameObject.Load(@LoadedObject)
  else if fObject.GameObject.Resource.FinishedLoading then
    begin
    TLabel(fSet.Tree.Selector.Window.GetChildByName('object_selector.object.author')).Caption := TDOMElement(fObject.GameObject.Resource.OCFFile.XML.Document.FirstChild).GetAttribute('author');
    TIconifiedButton(fSet.Tree.Selector.Window.GetChildByName('object_selector.object.build')).Alpha := 1;
    end;
end;

function TGameObjectSelectorObjectEntry.Match(S: String): Boolean;
var
  W: AString;
  I, J, Matches: Integer;
  TestOnDescription: Boolean;
begin
  Matches := 0;
  if S <> '' then
    begin
    S := Lowercase(S);
    W := Explode(' ', S);

    for I := 0 to high(W) do
      begin
      TestOnDescription := True;
      for J := 1 to Length(fObject.GameObject.Name) - Length(W[i]) + 1 do
        if Lowercase(SubString(fObject.GameObject.Name, J, Length(W[i]))) = W[i] then
          begin
          inc(Matches);
          TestOnDescription := False;
          break;
          end;
      if TestOnDescription then
        for J := 1 to Length(fObject.GameObject.Description) - Length(W[i]) + 1 do
          if Lowercase(SubString(fObject.GameObject.Description, J, Length(W[i]))) = W[i] then
            begin
            inc(Matches);
            break;
            end;
      end;
    end;

  Result := Matches >= Length(W);
  if Result then
    begin
    Result := False;
    for I := 0 to high(SetEntry.Tree.Selector.TagList.fTags) do
      if SetEntry.Tree.Selector.TagList.fTags[i].Checked then
        if fObject.GameObject.HasTag(SetEntry.Tree.Selector.TagList.fTags[i].TagName) then
          begin
          Result := True;
          break;
          end;
    end;

  if fSet.Expanded then
    if Result then
      Show
    else
      Hide;
end;

procedure TGameObjectSelectorObjectEntry.Show;
begin
  fVisible := True;
  Alpha := 1;
  fName.Alpha := 1;
  fPreview.Alpha := 1;
  fDescription.Alpha := 1;
  Top := 96 * (ID + 1);
end;

procedure TGameObjectSelectorObjectEntry.Hide;
begin
  fVisible := False;
  Alpha := 0;
  fName.Alpha := 0;
  fPreview.Alpha := 0;
  fDescription.Alpha := 0;
  Top := 0;
end;

constructor TGameObjectSelectorObjectEntry.Create(GameObject: TGameObjectItem; TheParent: TGameObjectSelectorSetEntry; TheID: Integer);
begin
  inherited Create(TheParent);
  fSet := TheParent;

  fVisible := True;

  fObject := GameObject;
  fID := TheID;

  Left := 0;
  Top := 0;
  Width := 348;
  Height := 96;
  Color := Vector(0.8, 0.8, 0.8, 1.0);
  OnClick := @fSelect;

  fName := TLabel.Create(Self);
  fName.Left := 128;
  fName.Width := 220;
  fName.Top := 8;
  fName.Height := 24;
  fName.Size := 24;
  fName.TranslateContent := False;
  fName.Caption := fObject.GameObject.Name;
  fName.OnClick := @fSelect;

  fDescription := TLabel.Create(Self);
  fDescription.Left := 128;
  fDescription.Width := 220;
  fDescription.Top := 32;
  fDescription.Height := 16;
  fDescription.Size := 16;
  fDescription.TranslateContent := False;
  fDescription.Caption := fObject.GameObject.Description;
  fDescription.OnClick := @fSelect;
  
  fPreview := TImage.Create(Self);
  fPreview.Left := 24;
  fPreview.Top := 0;
  fPreview.Width := 96;
  fPreview.Height := 96;
  fPreview.FreeTextureOnDestroy := False;
  fPreview.Tex := fObject.GameObject.Preview;
  fPreview.OnClick := @fSelect;
end;


procedure TGameObjectSelectorSetEntry.SwitchState(Sender: TGUIComponent);
begin
  Expanded := not Expanded;
end;

procedure TGameObjectSelectorSetEntry.MoveItems;
var
  CT, I: Integer;
begin
  if (fVisible) and (fExpanded) then
    begin
    CT := 96;
    for I := 0 to high(fObjectItems) do
      if fObjectItems[I].Visible then
        begin
        fObjectItems[I].Top := CT;
        inc(CT, 96);
        end;
    Height := CT;
    end;
end;

procedure TGameObjectSelectorSetEntry.SetState(S: Boolean);
var
  i: Integer;
begin
  fExpanded := S;
  if S then
    begin
    Height := 96 * (fShownObjects + 1);
    fExpand.Icon := 'list-remove.tga';
    Filter(TEdit(Tree.Selector.Window.GetChildByName('object_selector.filter')).Text);
    MoveItems;
    end
  else
    begin
    Height := 96;
    fExpand.Icon := 'list-add.tga';
    for i := 0 to high(fObjectItems) do
      fObjectItems[i].Hide;
    end;
  fTree.MoveItems;
end;

procedure TGameObjectSelectorSetEntry.Show;
begin
  fVisible := True;
  Alpha := 1;
  fName.Alpha := 1;
  fPreview.Alpha := 1;
  fDescription.Alpha := 1;
  fExpand.Alpha := 1;
  fAuthors.Alpha := 1;
  fTree.MoveItems;
end;

procedure TGameObjectSelectorSetEntry.Hide;
var
  i: Integer;
begin
  fVisible := False;
  Alpha := 0;
  fName.Alpha := 0;
  fPreview.Alpha := 0;
  fDescription.Alpha := 0;
  fExpand.Alpha := 0;
  fAuthors.Alpha := 0;
  fTree.MoveItems;
  Top := 0;
end;

procedure TGameObjectSelectorSetEntry.ReassignColors;
begin

end;

procedure TGameObjectSelectorSetEntry.AddObject(O: TGameObjectItem);
begin
  setLength(fObjectItems, length(fObjectItems) + 1);
  fObjectItems[high(fObjectItems)] := TGameObjectSelectorObjectEntry.Create(O, Self, high(fObjectItems));
  fObjectItems[high(fObjectItems)].Top := 96 * Length(fObjectItems);
  Height := 96 * (Length(fObjectItems) + 1);
  Inc(fShownObjects);
end;

function TGameObjectSelectorSetEntry.Filter(S: String): Boolean;
var
  W: AString;
  I, J, Matches: Integer;
  TestOnDescription, TestOnAuthors: Boolean;
  T: Integer;
begin
  Matches := 0;
  S := Lowercase(S);
  W := Explode(' ', S);
  
  if S <> '' then
    begin
    for I := 0 to high(W) do
      begin
      TestOnDescription := True;
      TestOnAuthors := True;
      for J := 1 to Length(fSet.GameSet.Name) - Length(W[i]) + 1 do
        if Lowercase(SubString(fSet.GameSet.Name, J, Length(W[i]))) = W[i] then
          begin
          inc(Matches);
          TestOnDescription := False;
          TestOnAuthors := False;
          break;
          end;
      if TestOnDescription then
        for J := 1 to Length(fSet.GameSet.Description) - Length(W[i]) + 1 do
          if Lowercase(SubString(fSet.GameSet.Description, J, Length(W[i]))) = W[i] then
            begin
            inc(Matches);
            TestOnAuthors := False;
            break;
            end;
      if TestOnAuthors then
        for J := 1 to Length(fSet.GameSet.Authors) - Length(W[i]) + 1 do
          if Lowercase(SubString(fSet.GameSet.Authors, J, Length(W[i]))) = W[i] then
            begin
            inc(Matches);
            TestOnAuthors := False;
            break;
            end;
      end;
    end;

  Result := Matches >= Length(W);

  fShownObjects := 0;
  if not Result then
    begin
    T := 0;
    for i := 0 to high(fObjectItems) do
      begin
      if fObjectItems[i].Match(S) then
        inc(fShownObjects);
      end;
    end
  else if Expanded then
    begin
    for i := 0 to high(fObjectItems) do
      begin
      if fObjectItems[i].Match('') then
        inc(fShownObjects);
      end;
    end
  else
    fShownObjects := Length(fObjectItems);

  Result := fShownObjects <> 0;
  if Result then
    Show
  else
    Hide;
  MoveItems;
end;

constructor TGameObjectSelectorSetEntry.Create(GameSet: TGameSetItem; TheParent: TGameObjectSelectorObjectTreeList);
var
  O: TGameObjectItem;
begin
  inherited Create(TheParent.Surface);
  fTree := TheParent;

  Left := 0;
  Top := 0;
  Height := 96;
  Width := 332;
  Size := 16;
  OnClick := @SwitchState;

  fSet := GameSet;

  fName := TLabel.Create(Self);
  fName.Left := 104;
  fName.Top := 8;
  fName.Width := 228;
  fName.Height := 24;
  fName.Size := 24;
  fName.Caption := fSet.GameSet.Name;
  fName.OnClick := @SwitchState;
  
  fAuthors := TLabel.Create(Self);
  fAuthors.Left := 104;
  fAuthors.Top := 32;
  fAuthors.Width := 228;
  fAuthors.Height := 16;
  fAuthors.Size := 16;
  fAuthors.TextColor := Vector(0.0, 0.0, 0.0, 0.6);
  fAuthors.Caption := 'By $' + fSet.GameSet.Authors + '$';
  fAuthors.OnClick := @SwitchState;

  fDescription := TLabel.Create(Self);
  fDescription.Left := 104;
  fDescription.Top := 48;
  fDescription.Width := 228;
  fDescription.Height := 48;
  fDescription.Size := 16;
  fDescription.Caption := fSet.GameSet.Description;
  fDescription.OnClick := @SwitchState;

  fPreview := TImage.Create(Self);
  fPreview.Left := 0;
  fPreview.Top := 0;
  fPreview.Width := 96;
  fPreview.Height := 96;
  fPreview.FreeTextureOnDestroy := False;
  fPreview.Tex := fSet.GameSet.Preview;
  fPreview.OnClick := @SwitchState;
 
  fExpand := TIconifiedButton.Create(Self);
  fExpand.Left := 300;
  fExpand.Top := 8;
  fExpand.Width := 32;
  fExpand.Height := 32;
  fExpand.Icon := 'list-remove.tga';
  fExpand.OnClick := @SwitchState;

  fExpanded := True;
  fVisible := True;

  fShownObjects := 0;

  O := TGameObjectItem(fSet.GameSet.OrigList.First);
  while O <> nil do
    begin
    AddObject(O);
    O := TGameObjectItem(O.Next);
    end;
end;


function TGameObjectSelectorObjectTreeList.Filter(S: String): Boolean;
var
  I: Integer;
begin
  Result := True;
  for i := 0 to high(fSetItems) do
    fSetItems[i].Filter(S);
end;

procedure TGameObjectSelectorObjectTreeList.ReassignColors;
begin

end;

procedure TGameObjectSelectorObjectTreeList.MoveItems;
var
  I: Integer;
  CT: Integer;
begin
  CT := 0;
  for I := 0 to high(fSetItems) do
    if fSetItems[i].Visible then
      begin
      fSetItems[i].Top := CT;
      Inc(CT, 96);
      if fSetItems[i].Expanded then
        Inc(CT, 96 * fSetItems[i].fShownObjects);
      end;
end;

procedure TGameObjectSelectorObjectTreeList.AddSet(S: TGameSetItem);
begin
  SetLength(fSetItems, length(fSetItems) + 1);
  fSetItems[high(fSetItems)] := TGameObjectSelectorSetEntry.Create(S, Self);
  fSetItems[high(fSetItems)].Expanded := False;
  fSetItems[high(fSetItems)].Top := 96 * high(fSetItems);
end;

constructor TGameObjectSelectorObjectTreeList.Create(TheParent: TGameObjectSelector);
begin
  inherited Create(TheParent.Window);
  fTheParent := TheParent;
  fSelected := nil;
end;


procedure TGameObjectSelector.OnClose(Event: String; Data, Result: Pointer);
begin
  Park.SelectionMode := S_DEFAULT_SELECTION;
  EventManager.CallEvent('GUIActions.selection_mode.changed', nil, nil);
  Park.pTerrain.CurrMark := Vector(-1, -1);
  TGameTerrainEdit(ParkUI.GetWindowByName('terrain_edit')).HeightLine('', nil, nil);
  EventManager.CallEvent('GUIActions.terrain_edit.removeheightline', nil, nil);
  Park.pTerrain.MarkMode := 0;
  Park.pTerrain.UpdateMarks;

  ParkUI.GetWindowByName('object_builder').Hide(fWindow);
end;

procedure TGameObjectSelector.DoBuild(Event: String; Data, Result: Pointer);
begin
  TGameObjectBuilder(ParkUI.GetWindowByName('object_builder')).BuildObject(fSetList.Selected.TheObject.GameObject.Resource);
  Window.Width := 0;
  Window.Height := 0;
end;

procedure TGameObjectSelector.DoFilter(Event: String; Data, Result: Pointer);
begin
  fSetList.Filter(TEdit(fWindow.GetChildByName('object_selector.filter')).Text);
end;

constructor TGameObjectSelector.Create(Resource: String; ParkUI: TXMLUIManager);
var
  S: TGameSetItem;
  O: TGameObjectItem;
  Tags: AString;
  I: Integer;
begin
  inherited Create(Resource, ParkUI);

  fTagList := TGameObjectSelectorTagList.Create(Window);
  fTagList.Top := 40;
  fTagList.Left := 8;
  fTagList.Width := 172;
  fTagList.Height := 452;
  fTagList.HScrollBar := sbmInvisible;
  fTagList.VScrollBar := sbmInverted;

  fSetList := TGameObjectSelectorObjectTreeList.Create(Self);
  fSetList.Top := 40;
  fSetList.Left := 188;
  fSetList.Width := 348;
  fSetList.Height := 452;
  fSetList.HScrollBar := sbmInvisible;

  S := TGameSetItem(Park.GameObjectManager.Sets.First);
  while S <> nil do
    begin
    O := TGameObjectItem(S.GameSet.OrigList.First);
    while O <> nil do
      begin
      Tags := O.GameObject.ListTags;
      for i := 0 to high(Tags) do
        fTagList.AddTag(Tags[i]);
      O := TGameObjectItem(O.Next);
      end;
    S := TGameSetItem(S.Next);
    end;

  S := TGameSetItem(Park.GameObjectManager.Sets.First);
  while S <> nil do
    begin
    fSetList.AddSet(S);
    S := TGameSetItem(S.Next);
    end;

  EventManager.AddCallback('GUIActions.object_selector.do_filter', @DoFilter);
  EventManager.AddCallback('GUIActions.object_selector.do_build', @DoBuild);
  EventManager.AddCallback('GUIActions.object_selector.close', @OnClose);
end;

destructor TGameObjectSelector.Free;
begin
  EventManager.RemoveCallback(@DoFilter);
  EventManager.RemoveCallback(@DoBuild);
  EventManager.RemoveCallback(@OnClose);
  inherited Free;
end;

end.