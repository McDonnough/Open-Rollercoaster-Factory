unit g_object_selector;

interface

uses
  SysUtils, Classes, u_events, g_park, g_parkui,
  m_gui_label_class, m_gui_edit_class, m_gui_tabbar_class, m_gui_button_class, m_gui_iconifiedbutton_class,
  m_gui_scrollbox_class, m_gui_class;

type
  TGameObjectSelectorTagList = class;

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

//   TGameObjectSelectorObjectTreeList = class(TScrollBox)
//     protected
//     public
//       procedure AddObject(
//       constructor Create(TheParent: TGUIComponent);
//     end;

  TGameObjectSelector = class(TXMLUIWindow)
    protected
      fTagList: TGameObjectSelectorTagList;
    public
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  m_varlist, u_functions, u_vectors, u_math, g_sets;

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
    Color := Vector(1, 1, 1, 0.7 + fAlphaOffset)
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
      fTags[j].AlphaOffset := 0.2;
    fTags[j + 1] := fTags[j];
    end;

  t.Top := 32 * i;
  if i mod 2 = 1 then
    t.AlphaOffset := 0
  else
    t.AlphaOffset := 0.2;
  fTags[i] := t;
  t.Checked := True;
end;

constructor TGameObjectSelectorTagList.Create(TheParent: TGUIComponent);
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
end;

destructor TGameObjectSelector.Free;
begin
  inherited Free;
end;

end.