unit m_gui_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, DGLOpenGL, m_gui_window_class;

type
  TGUIComponent = class;

  TCallbackProcedure = procedure(Sender: TGUIComponent) of object;
  TKeyCallbackProcedure = procedure(Sender: TGUIComponent; Key: Integer) of object;

  TComponentType = (CNothing, CWindow, CLabel, CButton, CIconifiedButton, CTimer, CTabBar, CPanel, CEdit, CProgressBar, CDropdownList);

  AGUIComponent = array of TGUIComponent;

  TCallbackArray = record
    OnClick, OnRelease: String;
    OnKeyDown, OnKeyUp: String;
    OnHover, OnLeave: String;
    OnEdit: String;
    OnChangeTab: String;
    OnExpire: String;
    end;

  TGUIComponent = class
    protected
      fRendered: Integer;
      fAlpha, fDestAlpha: GLFloat;
      fPosX, fPosY, fDestX, fDestY, fSpeedX, fSpeedY: GLFloat;
      fWidth, fHeight, fDestWidth, fDestHeight, fSpeedWidth, fSpeedHeight: GLFloat;
      fParent: TGUIComponent;
      fChildren: AGUIComponent;
      fChildOrder: Array of Integer;
      fTypeName: TComponentType;
      function GetChildInOrder(I: Integer): TGUIComponent;
      function GetAbsX: GLFloat;
      function GetAbsY: GLFloat;
      function GetMinX: GLFloat;
      function GetMinY: GLFloat;
      function GetMaxX: GLFloat;
      function GetMaxY: GLFloat;
    private
      fChildID: Integer;
      function AddChild(Child: TGUIComponent): Integer;
      procedure RemoveChild(Child: TGUIComponent);
    public
      Tag: Integer;
      Name: String;
      OnClick: TCallbackProcedure;
      OnGainFocus: TCallbackProcedure;
      OnRelease: TCallbackProcedure;
      OnHover: TCallbackProcedure;
      OnLeave: TCallbackProcedure;
      OnKeyDown: TKeyCallbackProcedure;
      OnKeyUp: TKeyCallbackProcedure;
      property Alpha: GLFloat read fAlpha write fDestAlpha;
      property Left: GLFloat read fPosX write fDestX;
      property Top: GLFloat read fPosY write fDestY;
      property Width: GLFloat read fWidth write fDestWidth;
      property Height: GLFloat read fHeight write fDestHeight;
      property Parent: TGUIComponent read fParent;
      property Children: AGUIComponent read fChildren;
      property ChildrenRightOrder[I: Integer]: TGUIComponent read GetChildInOrder;
      property ComponentType: TComponentType read fTypeName;
      property AbsX: GLFloat read GetAbsX;
      property AbsY: GLFloat read GetAbsY;
      property MinX: GLFloat read GetMinX;
      property MinY: GLFloat read GetMinY;
      property MaxX: GLFloat read GetMaxX;
      property MaxY: GLFloat read GetMaxY;
      procedure BringToFront(Child: TGUIComponent);
      procedure Render;
      function GetChildByName(S: String): TGUIComponent;
      constructor Create(mParent: TGUIComponent; TypeName: TComponentType);
      destructor Free;
    end;

  TXMLUI = class;

  TXMLUIWindow = class
    protected
      fWindow: TWindow;
      fButton: TIconifiedButton;
      fMoving: Boolean;
      fExpanded: Boolean;
      fWidth, fHeight, fLeft, fTop: Single;
      fBtnLeft, fBtnTop: Single;
      fParkUI: TXMLUI;
      fCallbackArrays: Array of TCallbackArray;
      procedure Toggle(Sender: TGUIComponent);
      procedure SetWidth(A: Single);
      procedure SetHeight(A: Single);
      procedure SetLeft(A: Single);
      procedure SetTop(A: Single);
      procedure SetBtnLeft(A: Single);
      procedure SetBtnTop(A: Single);
      procedure ReadFromXML(Resource: String);
      procedure StartDragging(Sender: TGUIComponent);
      procedure EndDragging(Sender: TGUIComponent);
      function AddCallbackArray(A: TDOMElement): Integer;
      procedure HandleOnclick(Sender: TGUIComponent);
      procedure HandleOnChangeTab(Sender: TGUIComponent);
      procedure BringButtonToFront(Sender: TGUIComponent);
    public
      property Window: TWindow read fWindow;
      property Width: Single read fWidth write SetWidth;
      property Height: Single read fHeight write SetHeight;
      property Left: Single read fLeft write SetLeft;
      property Top: Single read fTop write SetTop;
      property BtnLeft: Single read fBtnLeft write SetBtnLeft;
      property BtnTop: Single read fBtnTop write SetBtnTop;
      property Expanded: Boolean read fExpanded;
      procedure Show;
      procedure Hide;
      constructor Create(Resource: String; ParkUI: TXMLUI);
      destructor Free;
    end;

  TXMLUI = class
    protected
      fDragging: TXMLUIWindow;
      fDragStartLeft, fDragStartTop, fMouseOfsX, fMouseOfsY: Integer;
      procedure SetDragging(A: TXMLUIWindow);
    public
      property Dragging: TXMLUIWindow read fDragging write setDragging;
      procedure Drag;
      constructor Create;
      destructor Free;
    end;

  TModuleGUIClass = class(TBasicModule)
    protected
      fBasicComponent: TGUIComponent;
      fFocusComponent: TGUIComponent;
      fHoverComponent: TGUIComponent;
      fClicking: Boolean;
      procedure BasicComponentOnClick(Sender: TGUIComponent);
      procedure BasicComponentOnRelease(Sender: TGUIComponent);
    public
      property Clicking: Boolean read fClicking;
      property BasicComponent: TGUIComponent read fBasicComponent;
      property HoverComponent: TGUIComponent read fHoverComponent;
      property FocusComponent: TGUIComponent read fFocusComponent;

      (**
        * Call signal procedures
        *)
      procedure CallSignals; virtual abstract;

      (**
        * Render all attached objects
        *)
      procedure Render; virtual abstract;
    end;

implementation

uses
  m_varlist, math, u_math, main, u_events;

type
  TXMLUIWindowList = record
    fLeaveWindow: TGameLeave;
    fInfoWindow: TGameInfo;
    fGameTerrainEdit: TGameTerrainEdit;
    end;

var
  WindowList: TXMLUIWindowList;


procedure TModuleGUIClass.BasicComponentOnClick(Sender: TGUIComponent);
begin
  EventManager.CallEvent('BasicComponent.OnClick', Sender, nil);
end;

procedure TModuleGUIClass.BasicComponentOnRelease(Sender: TGUIComponent);
begin
  EventManager.CallEvent('BasicComponent.OnRelease', Sender, nil);
end;


function TGUIComponent.GetChildInOrder(I: Integer): TGUIComponent;
var
  j: Integer;
begin
  Result := nil;
  for j := 0 to high(fChildOrder) do
    if fChildOrder[j] = i then
      exit(fChildren[j]);
end;

function TGUIComponent.GetAbsX: GLFloat;
begin
  Result := Left;
  if Parent <> nil then
    Result := Left + Parent.GetAbsX;
end;

function TGUIComponent.GetAbsY: GLFloat;
begin
  Result := Top;
  if Parent <> nil then
    Result := Top + Parent.GetAbsY;
end;

function TGUIComponent.GetMinX: GLFloat;
begin
  Result := AbsX;
  if Parent <> nil then
    Result := Max(Result, Parent.MinX);
end;

function TGUIComponent.GetMinY: GLFloat;
begin
  Result := AbsY;
  if Parent <> nil then
    Result := Max(Result, Parent.MinY);
end;

function TGUIComponent.GetMaxX: GLFloat;
begin
  Result := AbsX + Width;
  if Parent <> nil then
    Result := Min(Result, Parent.MaxX);
end;

function TGUIComponent.GetMaxY: GLFloat;
begin
  Result := AbsY + Height;
  if Parent <> nil then
    Result := Min(Result, Parent.MaxY);
end;

function TGUIComponent.AddChild(Child: TGUIComponent): Integer;
begin
  setLength(fChildren, length(fChildren) + 1);
  fChildren[high(fChildren)] := Child;
  Result := high(fChildren);
  SetLength(fChildOrder, length(fChildOrder) + 1);
  fChildOrder[high(fChildOrder)] := high(fChildOrder);
end;

procedure TGUIComponent.RemoveChild(Child: TGUIComponent);
var
  I: Integer;
begin
  for i := Child.fChildID + 1 to high(fChildren) do
    begin
    fChildOrder[i - 1] := fChildOrder[i];
    fChildren[i - 1] := fChildren[i];
    dec(fChildren[i - 1].fChildID);
    end;
  setLength(fChildOrder, length(fChildOrder) - 1);
  setLength(fChildren, length(fChildren) - 1);
  for i := 0 to high(fChildOrder) do
    if fChildOrder[i] > Child.fChildID then
      dec(fChildOrder[i]);
end;

procedure TGUIComponent.Render;
const
  MAX_MOTION_SPEED = 0.1;
  SPEED_ADD = 0.005;
var
  i: Integer;
  MS: Single;
begin
  MS := 10;
  if FPSDisplay <> nil then
    MS := FPSDisplay.MS;
  for i := 0 to Round(10 * MS) do
    begin
    fAlpha := fAlpha + (fDestAlpha - fAlpha) / 1000;
  {  fPosX := fPosX + fSpeedX;
    fPosY := fPosY + fSpeedY;}
    fPosX := fPosX + (fDestX - fPosX) / 1000;
    fPosY := fPosY + (fDestY - fPosY) / 1000;
    fWidth := fWidth + fSpeedWidth;
    fHeight := fHeight + fSpeedHeight;
    if fRendered * abs(fPosX - fDestX) < 1 then
      fPosX := fDestX;
    if fRendered * abs(fPosY - fDestY) < 1 then
      fPosY := fDestY;
    if fRendered * abs(fWidth - fDestWidth) < 1 then
      fWidth := fDestWidth;
    if fRendered * abs(fHeight - fDestHeight) < 1 then
      fHeight := fDestHeight;
  {  fSpeedX := clamp(sign(fDestX - fPosX) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fPosX - fDestX))), max(fSpeedX - SPEED_ADD, -5 * MAX_MOTION_SPEED), min(fSpeedX + SPEED_ADD, 5 * MAX_MOTION_SPEED));
    fSpeedY := clamp(sign(fDestY - fPosY) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fPosY - fDestY))), max(fSpeedY - SPEED_ADD, -5 * MAX_MOTION_SPEED), min(fSpeedY + SPEED_ADD, 5 * MAX_MOTION_SPEED));}
    fSpeedWidth := clamp(sign(fDestWidth - fWidth) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fWidth - fDestWidth))), max(fSpeedWidth - SPEED_ADD, -MAX_MOTION_SPEED), min(fSpeedWidth + SPEED_ADD, MAX_MOTION_SPEED));
    fSpeedHeight := clamp(sign(fDestHeight - fHeight) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fHeight - fDestHeight))), max(fSpeedHeight - SPEED_ADD, -MAX_MOTION_SPEED), min(fSpeedHeight + SPEED_ADD, MAX_MOTION_SPEED));
    end;
  fRendered := 1;
end;

function TGUIComponent.GetChildByName(S: String): TGUIComponent;
var
  i: Integer;
begin
  Result := nil;
  if Name = S then
    Result := Self
  else
    for i := 0 to high(fChildren) do
      begin
      Result := fChildren[i].GetChildByName(S);
      if Result <> nil then
        exit;
      end;
end;

procedure TGUIComponent.BringToFront(Child: TGUIComponent);
var
  i, j, OldPosition: Integer;
begin
  j := 0;
  OldPosition := High(fChildOrder);
  for i := 0 to high(fChildOrder) do
    if fChildren[i] = Child then
      OldPosition := fChildOrder[i];
  for i := 0 to high(fChildOrder) do
    begin
    if fChildren[i] = Child then
      fChildOrder[i] := High(fChildOrder)
    else if fChildOrder[i] > OldPosition then
      dec(fChildOrder[i]);
    if fChildOrder[i] < j then
      j := fChildOrder[i];
    end;
  for i := 0 to high(fChildOrder) do
    if fChildOrder[i] <> High(fChildOrder) then
      fChildOrder[i] := fChildOrder[i] - j;
  if Child.OnGainFocus <> nil then
    Child.OnGainFocus(Child);
end;

constructor TGUIComponent.Create(mParent: TGUIComponent; TypeName: TComponentType);
begin
  if (mParent = nil) and (TypeName <> CNothing) then
    mParent := ModuleManager.ModGUI.BasicComponent;
  fTypeName := TypeName;
  fParent := mParent;
  if fParent <> nil then
    fChildID := fParent.AddChild(Self);
  fAlpha := 0;
  fDestAlpha := 1;

  fPosX := 0;
  fPosY := 0;
  fDestX := 0;
  fDestY := 0;
  fSpeedX := 0;
  fSpeedY := 0;
  fWidth := 0;
  fHeight := 0;
  fDestWidth := 0;
  fDestHeight := 0;
  fSpeedWidth := 0;
  fSpeedHeight := 0;
  fRendered := 0;

  OnClick := nil;
  OnRelease := nil;
  OnGainFocus := nil;
  OnHover := nil;
  OnLeave := nil;
  OnKeyDown := nil;
  OnKeyUp := nil;
end;

destructor TGUIComponent.Free;
begin
  while high(fChildren) >= 0 do
    fChildren[0].Free;
  if fParent <> nil then
    fParent.RemoveChild(Self);
end;



function TXMLUIWindow.AddCallbackArray(A: TDOMElement): Integer;
begin
  SetLength(fCallbackArrays, length(fCallbackArrays) + 1);
  Result := Length(fCallbackArrays);
  fCallbackArrays[Result - 1].OnClick := A.GetAttribute('onclick');
  fCallbackArrays[Result - 1].OnRelease := A.GetAttribute('onrelease');
  fCallbackArrays[Result - 1].OnHover := A.GetAttribute('onhover');
  fCallbackArrays[Result - 1].OnLeave := A.GetAttribute('onleave');
  fCallbackArrays[Result - 1].OnKeyDown := A.GetAttribute('onkeydown');
  fCallbackArrays[Result - 1].OnKeyUp := A.GetAttribute('onkeyup');
  fCallbackArrays[Result - 1].OnEdit := A.GetAttribute('onedit');
  fCallbackArrays[Result - 1].OnExpire := A.GetAttribute('onexpire');
  fCallbackArrays[Result - 1].OnChangeTab := A.GetAttribute('onchangetab');
end;

procedure TXMLUIWindow.HandleOnclick(Sender: TGUIComponent);
begin
  if (Sender.Tag > 0) and (Sender.Tag <= Length(fCallbackArrays)) then
    EventManager.CallEvent('GUIActions.' + fCallbackArrays[Sender.Tag - 1].OnClick, Sender, nil);
end;

procedure TXMLUIWindow.HandleOnChangeTab(Sender: TGUIComponent);
begin
  if (Sender.Tag > 0) and (Sender.Tag <= Length(fCallbackArrays)) then
    EventManager.CallEvent('GUIActions.' + fCallbackArrays[Sender.Tag - 1].OnChangeTab, Sender, nil);
end;

procedure TXMLUIWindow.Toggle(Sender: TGUIComponent);
begin
  if Expanded then
    begin
    hide;
    if fWindow.Name <> '' then
      EventManager.CallEvent('GUIActions.' + fWindow.Name + '.close', Sender, nil);
    end
  else
    begin
    show;
    if fWindow.Name <> '' then
      EventManager.CallEvent('GUIActions.' + fWindow.Name + '.open', Sender, nil);
    end;
end;

procedure TXMLUIWindow.SetWidth(A: Single);
begin
  fWidth := A;
  if (not fMoving) and (fExpanded) then
    fWindow.Width := A;
end;

procedure TXMLUIWindow.SetHeight(A: Single);
begin
  fHeight := A;
  if (not fMoving) and (fExpanded) then
    fWindow.Height := A;
end;

procedure TXMLUIWindow.SetLeft(A: Single);
begin
  fLeft := A;
  if fExpanded then
    begin
    fWindow.Left := A + 16;
    fButton.Left := A;
    end;
end;

procedure TXMLUIWindow.SetTop(A: Single);
begin
  fTop := A;
  if fExpanded then
    begin
    fWindow.Top := A + 16;
    fButton.Top := A;
    end;
end;

procedure TXMLUIWindow.SetBtnLeft(A: Single);
begin
  fBtnLeft := A;
  if not fExpanded then
    begin
    fWindow.Left := A + 24;
    fButton.Left := A;
    end;
end;

procedure TXMLUIWindow.SetBtnTop(A: Single);
begin
  fBtnTop := A;
  if not fExpanded then
    begin
    fWindow.Top := A + 24;
    fButton.Top := A;
    end;
end;

procedure TXMLUIWindow.Show;
begin
  ModuleManager.ModGUI.BasicComponent.BringToFront(fWindow);
  fExpanded := true;
  fWindow.Width := fWidth;
  fWindow.Height := fHeight;
  fWindow.Alpha := 1;
  fWindow.Left := fLeft + 16;
  fWindow.Top := fTop + 16;
  fButton.Left := fLeft;
  fButton.Top := fTop;
  fButton.Width := 64;
  fButton.Height := 64;
end;

procedure TXMLUIWindow.Hide;
begin
  fExpanded := false;
  fWindow.Width := 0;
  fWindow.Height := 0;
  fWindow.Alpha := 0;
  fWindow.Left := fBtnLeft + 24;
  fWindow.Top := fBtnTop + 24;
  fButton.Left := fBtnLeft;
  fButton.Top := fBtnTop;
  fButton.Width := 48;
  fButton.Height := 48;
end;

procedure TXMLUIWindow.ReadFromXML(Resource: String);
var
  XMLFile: TDOMDocument;
  a: TDOMNodeList;
  CurrChild: TDOMNode;
  ResX, ResY: Integer;
  S: String;

  procedure AddChildren(P: TGUIComponent; DE: TDOMNode);
  var
    A: TGUIComponent;
    CurrChild: TDOMNode;
  begin
    A := nil;
    with P, TDOMElement(DE) do
      begin
      if NodeName = 'label' then
        begin
        A := TLabel.Create(P);
        with TLabel(A) do
          begin
          Left := StrToIntWD(GetAttribute('left'), 16);
          Top := StrToIntWD(GetAttribute('top'), 16);
          Width := StrToIntWD(GetAttribute('width'), Round(P.Width - Left - 16));
          Size := Round(StrToIntWD(GetAttribute('size'), 16));
          Height := StrToIntWD(GetAttribute('height'), Round(Height));
          if FirstChild <> nil then
            Caption := FirstChild.NodeValue;
          Tag := AddCallbackArray(TDOMElement(DE));
          OnClick := @StartDragging;
          OnRelease := @EndDragging;
          end;
        end
      else if NodeName = 'iconbutton' then
        begin
        A := TIconifiedButton.Create(P);
        with TIconifiedButton(A) do
          begin
          Left := StrToIntWD(GetAttribute('left'), 16);
          Top := StrToIntWD(GetAttribute('top'), 16);
          Icon := GetAttribute('icon');
          Width := StrToIntWD(GetAttribute('width'), 64);
          Height := StrToIntWD(GetAttribute('height'), 64);
          Tag := AddCallbackArray(TDOMElement(DE));
          OnClick := @HandleOnclick;
          end;
        end
      else if NodeName = 'button' then
        begin
        A := TButton.Create(P);
        with TButton(A) do
          begin
          Left := StrToIntWD(GetAttribute('left'), 16);
          Top := StrToIntWD(GetAttribute('top'), 16);
          Width := StrToIntWD(GetAttribute('width'), 64);
          Height := StrToIntWD(GetAttribute('height'), 64);
          if FirstChild <> nil then
            Caption := FirstChild.NodeValue;
          Tag := AddCallbackArray(TDOMElement(DE));
          OnClick := @HandleOnclick;
          end;
        end
      else if NodeName = 'edit' then
        begin
        A := TEdit.Create(P);
        with TEdit(A) do
          begin
          Left := StrToIntWD(GetAttribute('left'), 16);
          Top := StrToIntWD(GetAttribute('top'), 16);
          Width := StrToIntWD(GetAttribute('width'), 64);
          Height := StrToIntWD(GetAttribute('height'), 64);
          if FirstChild <> nil then
            Text := FirstChild.NodeValue;
          Tag := AddCallbackArray(TDOMElement(DE));
          OnClick := @HandleOnclick;
          end;
        end
      else if NodeName = 'tabbar' then
        begin
        A := TTabBar.Create(P);
        with TTabBar(A) do
          begin
          Left := StrToIntWD(GetAttribute('left'), 16);
          Top := StrToIntWD(GetAttribute('top'), 16);
          Width := StrToIntWD(GetAttribute('width'), 64);
          Height := StrToIntWD(GetAttribute('height'), 64);
          Tag := AddCallbackArray(TDOMElement(DE));
          OnChangeTab := @HandleOnChangeTab;
          end;
        end
      else if NodeName = 'tab' then
        begin
        S := '';
        if FirstChild <> nil then
          S := FirstChild.NodeValue;
        TTabBar(P).AddTab(S, StrToIntWD(GetAttribute('minwidth'), 150));
        end;
      end;
    if A <> nil then
      begin
      A.Name := TDOMElement(DE).GetAttribute('name');
      CurrChild := DE.FirstChild;
      while CurrChild <> nil do
        begin
        AddChildren(A, TDOMElement(CurrChild));
        CurrChild := CurrChild.NextSibling;
        end;
      end;
  end;
begin
  writeln('Loading GUI file ' + Resource);
  XMLFile := LoadXMLFile(GetFirstExistingFileName(Resource));
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  try
    a := XMLFile.GetElementsByTagName('window');
    with TDOMElement(a[0]) do
      begin
      fWindow.Name := GetAttribute('name');
      Width := StrToInt(GetAttribute('width'));
      Height := StrToInt(GetAttribute('height'));
      Left := StrToInt(GetAttribute('left')) - 400 + ResX / 2;
      Top := StrToInt(GetAttribute('top')) - 300 + ResY / 2;
      BtnLeft := StrToInt(GetAttribute('btnleft')) - 800 + ResX;
      BtnTop := StrToInt(GetAttribute('btntop')) - 300 + ResY / 2;
      fButton.Icon := GetAttribute('icon');

      AddChildren(fWindow, TDOMElement(a[0]));

      CurrChild := FirstChild;
      while CurrChild <> nil do
        with TDOMElement(CurrChild) do
          begin
          if NodeName = 'panel' then
            begin
            fWindow.OfsX1 := StrToIntWD(GetAttribute('leftspace'), 0);
            fWindow.OfsX2 := StrToIntWD(GetAttribute('rightspace'), 0);
            fWindow.OfsY1 := StrToIntWD(GetAttribute('topspace'), 0);
            fWindow.OfsY2 := StrToIntWD(GetAttribute('bottomspace'), 0);
            end
          else
            AddChildren(fWindow, TDOMElement(CurrChild));
          CurrChild := NextSibling;
          end;
      end;
  except
    ModuleManager.ModLog.AddError('Could not load Park UI resouce ' + Resource + ': Internal error')
  end;
  XMLFile.Free;
end;

constructor TXMLUIWindow.Create(Resource: String; ParkUI: TXMLUI);
begin
  fParkUI := ParkUI;
  fWindow := TWindow.Create(nil);
  fButton := TIconifiedButton.Create(nil);
  fButton.OnClick := @Toggle;
  fExpanded := false;
  fMoving := false;
  Width := 0;
  Height := 0;
  Left := 0;
  Top := 0;
  BtnLeft := 0;
  BtnTop := 0;
  fButton.Width := 48;
  fButton.Height := 48;
  fWindow.Width := 0;
  fWindow.Height := 0;
  fWindow.Left := 24;
  fWindow.Top := 24;
  fWindow.Tag := 0;
  fWindow.OnGainFocus := @BringButtonToFront;
  fWindow.OnClick := @StartDragging;
  fWindow.OnRelease := @EndDragging;

  ReadFromXML(Resource);
end;

procedure TXMLUIWindow.BringButtonToFront(Sender: TGUIComponent);
begin
  ModuleManager.ModGUI.BasicComponent.BringToFront(fButton);
end;

procedure TXMLUIWindow.StartDragging(Sender: TGUIComponent);
begin
  fParkUI.Dragging := self;
end;

procedure TXMLUIWindow.EndDragging(Sender: TGUIComponent);
begin
  fParkUI.Dragging := nil;
end;



destructor TXMLUIWindow.Free;
begin
  fWindow.Free;
  fButton.Free;
end;

constructor TXMLUI.Create;
var
  ResX, ResY: Integer;
begin
  WindowList.fLeaveWindow := TGameLeave.Create('ui/leave.xml', self);
  WindowList.fInfoWindow := TGameInfo.Create('ui/info.xml', self);
  WindowList.fGameTerrainEdit := TGameTerrainEdit.Create('ui/terrain_edit.xml', self);
end;

procedure TXMLUI.SetDragging(A: TXMLUIWindow);
begin
  fDragging := A;
  if A = nil then
    exit;
  fDragStartLeft := Round(Dragging.Left);
  fMouseOfsX := ModuleManager.ModInputHandler.MouseX;
  fDragStartTop := Round(Dragging.Top);
  fMouseOfsY := ModuleManager.ModInputHandler.MouseY;
end;

procedure TXMLUI.Drag;
begin
  if Dragging <> nil then
    begin
    Dragging.Left := fDragStartLeft + ModuleManager.ModInputHandler.MouseX - fMouseOfsX;
    Dragging.Top := fDragStartTop + ModuleManager.ModInputHandler.MouseY - fMouseOfsY;
    end;
end;

destructor TXMLUI.Free;
begin
  WindowList.fLeaveWindow.Free;
  WindowList.fInfoWindow.Free;
  WindowList.fGameTerrainEdit.Free;
end;

end.

