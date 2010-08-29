unit g_parkui;

interface

uses
  SysUtils, Classes, m_gui_class, m_gui_window_class, m_gui_iconifiedbutton_class, m_gui_button_class, u_files, u_dom, u_xml,
  m_gui_label_class, m_gui_edit_class, m_gui_progressbar_class, m_gui_timer_class, m_gui_tabbar_class, u_functions;

type
  TCallbackArray = record
    OnClick, OnRelease: String;
    OnKeyDown, OnKeyUp: String;
    OnHover, OnLeave: String;
    OnEdit: String;
    OnChangeTab: String;
    OnExpire: String;
    end;

  TXMLUIManager = class;

  TXMLUIWindow = class
    protected
      fWindow: TWindow;
      fButton: TIconifiedButton;
      fMoving: Boolean;
      fExpanded: Boolean;
      fWidth, fHeight, fLeft, fTop: Single;
      fBtnLeft, fBtnTop: Single;
      fParkUI: TXMLUIManager;
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
      procedure HandleOnClick(Sender: TGUIComponent);
      procedure HandleOnRelease(Sender: TGUIComponent);
      procedure HandleOnKeyDown(Sender: TGUIComponent; Key: Integer);
      procedure HandleOnKeyUp(Sender: TGUIComponent; Key: Integer);
      procedure HandleOnHover(Sender: TGUIComponent);
      procedure HandleOnLeave(Sender: TGUIComponent);
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
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

  TXMLUIManager = class
    protected
      fDragging: TXMLUIWindow;
      fDragStartLeft, fDragStartTop, fMouseOfsX, fMouseOfsY: Integer;
      procedure SetDragging(A: TXMLUIWindow);
    public
      property Dragging: TXMLUIWindow read fDragging write setDragging;
      procedure Drag;
    end;

    TParkUI = class(TXMLUIManager)
      constructor Create;
      destructor Free;
      end;

implementation

uses
  u_events, m_varlist, g_park, g_leave, g_info, g_terrain_edit;

type
  TParkUIWindowList = record
    fLeaveWindow: TGameLeave;
    fInfoWindow: TGameInfo;
    fGameTerrainEdit: TGameTerrainEdit;
    end;

var
  WindowList: TParkUIWindowList;

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

procedure TXMLUIWindow.HandleOnRelease(Sender: TGUIComponent);
begin
  if (Sender.Tag > 0) and (Sender.Tag <= Length(fCallbackArrays)) then
    EventManager.CallEvent('GUIActions.' + fCallbackArrays[Sender.Tag - 1].OnRelease, Sender, nil);
end;

procedure TXMLUIWindow.HandleOnHover(Sender: TGUIComponent);
begin
  if (Sender.Tag > 0) and (Sender.Tag <= Length(fCallbackArrays)) then
    EventManager.CallEvent('GUIActions.' + fCallbackArrays[Sender.Tag - 1].OnHover, Sender, nil);
end;

procedure TXMLUIWindow.HandleOnLeave(Sender: TGUIComponent);
begin
  if (Sender.Tag > 0) and (Sender.Tag <= Length(fCallbackArrays)) then
    EventManager.CallEvent('GUIActions.' + fCallbackArrays[Sender.Tag - 1].OnLeave, Sender, nil);
end;

procedure TXMLUIWindow.HandleOnKeyUp(Sender: TGUIComponent; Key: Integer);
begin
  if (Sender.Tag > 0) and (Sender.Tag <= Length(fCallbackArrays)) then
    EventManager.CallEvent('GUIActions.' + fCallbackArrays[Sender.Tag - 1].OnKeyUp, Sender, @Key);
end;

procedure TXMLUIWindow.HandleOnKeyDown(Sender: TGUIComponent; Key: Integer);
begin
  if (Sender.Tag > 0) and (Sender.Tag <= Length(fCallbackArrays)) then
    EventManager.CallEvent('GUIActions.' + fCallbackArrays[Sender.Tag - 1].OnKeyDown, Sender, @Key);
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
          if GetAttribute('align') = 'center' then
            Align := LABEL_ALIGN_CENTER
          else if GetAttribute('align') = 'right' then
            Align := LABEL_ALIGN_RIGHT;
          Alpha := StrToFloatWD(GetAttribute('alpha'), 1);
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
          Alpha := StrToFloatWD(GetAttribute('alpha'), 1);
          OnClick := @HandleOnclick;
          OnRelease := @HandleOnrelease;
          OnHover := @HandleOnHover;
          OnLeave := @HandleOnLeave;
          OnKeyUp := @HandleOnKeyUp;
          OnKeyDown := @HandleOnKeyDown;
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
          Alpha := StrToFloatWD(GetAttribute('alpha'), 1);
          OnClick := @HandleOnclick;
          OnRelease := @HandleOnrelease;
          OnHover := @HandleOnHover;
          OnLeave := @HandleOnLeave;
          OnKeyUp := @HandleOnKeyUp;
          OnKeyDown := @HandleOnKeyDown;
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
          Alpha := StrToFloatWD(GetAttribute('alpha'), 1);
          OnClick := @HandleOnclick;
          OnRelease := @HandleOnrelease;
          OnHover := @HandleOnHover;
          OnLeave := @HandleOnLeave;
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
          Alpha := StrToFloatWD(GetAttribute('alpha'), 1);
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

constructor TXMLUIWindow.Create(Resource: String; ParkUI: TXMLUIManager);
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

procedure TXMLUIManager.SetDragging(A: TXMLUIWindow);
begin
  fDragging := A;
  if A = nil then
    exit;
  fDragStartLeft := Round(Dragging.Left);
  fMouseOfsX := ModuleManager.ModInputHandler.MouseX;
  fDragStartTop := Round(Dragging.Top);
  fMouseOfsY := ModuleManager.ModInputHandler.MouseY;
end;

procedure TXMLUIManager.Drag;
begin
  if Dragging <> nil then
    begin
    Dragging.Left := fDragStartLeft + ModuleManager.ModInputHandler.MouseX - fMouseOfsX;
    Dragging.Top := fDragStartTop + ModuleManager.ModInputHandler.MouseY - fMouseOfsY;
    end;
end;

constructor TParkUI.Create;
var
  ResX, ResY: Integer;
begin
  WindowList.fLeaveWindow := TGameLeave.Create('ui/leave.xml', self);
  WindowList.fInfoWindow := TGameInfo.Create('ui/info.xml', self);
  WindowList.fGameTerrainEdit := TGameTerrainEdit.Create('ui/terrain_edit.xml', self);
end;

destructor TParkUI.Free;
begin
  WindowList.fLeaveWindow.Free;
  WindowList.fInfoWindow.Free;
  WindowList.fGameTerrainEdit.Free;
end;

end.