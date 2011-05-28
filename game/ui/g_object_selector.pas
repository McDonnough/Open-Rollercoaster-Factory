unit g_object_selector;

interface

uses
  SysUtils, Classes, u_events, g_park, g_parkui,
  m_gui_label_class, m_gui_edit_class, m_gui_tabbar_class, m_gui_button_class, m_gui_iconifiedbutton_class,
  m_gui_scrollbox_class, m_gui_class, m_gui_image_class, g_sets;

type
  TGameObjectSelectorTagList = class;
  TGameObjectSelectorObjectTreeList = class;
  TGameObjectSelectorSetEntry = class;

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
    protected
      fTags: Array of TGameObjectSelectorTagListItem;
    public
      procedure AddTag(fTag: String);
      constructor Create(TheParent: TGUIComponent);
    end;

  TGameObjectSelectorObjectEntry = class(TLabel)
    protected
      fObject: TGameObjectItem;
      
      fName, fDescription: TLabel;
      fPreview: TImage;

      fID: Integer;
      procedure fSelect(Sender: TGUIComponent);
    public
      property ID: Integer read fID;
      procedure Show;
      procedure Hide;
      function Match(S: String): Boolean;
      constructor Create(GameObject: TGameObjectItem; TheParent: TGameObjectSelectorSetEntry; TheID: Integer);
    end;

  TGameObjectSelectorSetEntry = class(TLabel)
    protected
      fSet: TGameSetItem;
      
      fObjectItems: Array of TGameObjectSelectorObjectEntry;
      
      fName, fAuthors, fDescription: TLabel;
      fPreview: TImage;
      fExpand: TIconifiedButton;
    
      fExpanded: Boolean;
      fShownObjects: Integer;
      procedure SwitchState(Sender: TGUIComponent);
      procedure SetState(S: Boolean);
    public
      property ShownObjects: Integer read fShownObjects;
      property Expanded: Boolean read fExpanded write SetState;
      procedure ReassignColors;
      procedure AddObject(O: TGameObjectItem);
      function Filter(S: String): Boolean;
      constructor Create(GameSet: TGameSetItem; TheParent: TGameObjectSelectorObjectTreeList);
    end;

  TGameObjectSelectorObjectTreeList = class(TScrollBox)
    protected
      fSetItems: Array of TGameObjectSelectorSetEntry;
    public
      function Filter(S: String): Boolean;
      procedure ReassignColors;
      procedure AddSet(S: TGameSetItem);
      constructor Create(TheParent: TGUIComponent);
    end;

  TGameObjectSelector = class(TXMLUIWindow)
    protected
      fTagList: TGameObjectSelectorTagList;
      fSetList: TGameObjectSelectorObjectTreeList;
    public
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  m_varlist, u_functions, u_vectors, u_math;

procedure TGameObjectSelectorTagListItem.fChangeState(Sender: TGUIComponent);
begin
  Checked := not Checked;
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




procedure TGameObjectSelectorObjectEntry.fSelect(Sender: TGUIComponent);
begin

end;

function TGameObjectSelectorObjectEntry.Match(S: String): Boolean;
begin

end;

procedure TGameObjectSelectorObjectEntry.Show;
begin
  Alpha := 1;
  fName.Alpha := 1;
  fPreview.Alpha := 1;
  fDescription.Alpha := 1;
  Top := 96 * (ID + 1);
end;

procedure TGameObjectSelectorObjectEntry.Hide;
begin
  Alpha := 0;
  fName.Alpha := 0;
  fPreview.Alpha := 0;
  fDescription.Alpha := 0;
  Top := 0;
end;

constructor TGameObjectSelectorObjectEntry.Create(GameObject: TGameObjectItem; TheParent: TGameObjectSelectorSetEntry; TheID: Integer);
begin
  inherited Create(TheParent);

  fObject := GameObject;
  fID := TheID;

  Left := 0;
  Top := 0;
  Width := 348;
  Height := 96;
  Color := Vector(0.8, 0.8, 0.8, 1.0);

  fName := TLabel.Create(Self);
  fName.Left := 128;
  fName.Width := 220;
  fName.Top := 8;
  fName.Height := 24;
  fName.Size := 24;
  fName.Caption := fObject.GameObject.Name;
  
  fDescription := TLabel.Create(Self);
  fDescription.Left := 128;
  fDescription.Width := 220;
  fDescription.Top := 32;
  fDescription.Height := 16;
  fDescription.Size := 16;
  fDescription.Caption := fObject.GameObject.Description;
  
  fPreview := TImage.Create(Self);
  fPreview.Left := 24;
  fPreview.Top := 0;
  fPreview.Width := 96;
  fPreview.Height := 96;
  fPreview.FreeTextureOnDestroy := False;
  fPreview.Tex := fObject.GameObject.Preview;
end;


procedure TGameObjectSelectorSetEntry.SwitchState(Sender: TGUIComponent);
begin
  Expanded := not Expanded;
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
    for i := 0 to high(fObjectItems) do
      fObjectItems[i].Show;
    end
  else
    begin
    Height := 96;
    fExpand.Icon := 'list-add.tga';
    for i := 0 to high(fObjectItems) do
      fObjectItems[i].Hide;
    end;
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
begin

end;

constructor TGameObjectSelectorSetEntry.Create(GameSet: TGameSetItem; TheParent: TGameObjectSelectorObjectTreeList);
var
  O: TGameObjectItem;
begin
  inherited Create(TheParent.Surface);

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

  fShownObjects := 0;

  O := TGameObjectItem(fSet.GameSet.OrigList.First);
  while O <> nil do
    begin
    AddObject(O);
    O := TGameObjectItem(O.Next);
    end;
end;


function TGameObjectSelectorObjectTreeList.Filter(S: String): Boolean;
begin

end;

procedure TGameObjectSelectorObjectTreeList.ReassignColors;
begin

end;

procedure TGameObjectSelectorObjectTreeList.AddSet(S: TGameSetItem);
begin
  SetLength(fSetItems, length(fSetItems) + 1);
  fSetItems[high(fSetItems)] := TGameObjectSelectorSetEntry.Create(S, Self);
  fSetItems[high(fSetItems)].Expanded := False;
  fSetItems[high(fSetItems)].Top := 96 * high(fSetItems);
end;

constructor TGameObjectSelectorObjectTreeList.Create(TheParent: TGUIComponent);
begin
  inherited Create(TheParent);

  
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

  fSetList := TGameObjectSelectorObjectTreeList.Create(Window);
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
end;

destructor TGameObjectSelector.Free;
begin
  inherited Free;
end;

end.