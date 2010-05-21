unit g_parkui;

interface

uses
  SysUtils, Classes, m_gui_class, m_gui_window_class, m_gui_iconifiedbutton_class, m_gui_button_class, u_files, u_dom, u_xml,
  m_gui_label_class, m_gui_edit_class, m_gui_progressbar_class, m_gui_timer_class, u_functions, g_leave;

type
  TCallbackArray = record
    OnClick, OnRelease: String;
    OnKeyDown, OnKeyUp: String;
    OnHover, OnLeave: String;
    OnEdit: String;
    OnExpire: String;
    end;

  TParkUI = class;

  TParkUIWindow = class
    protected
      fWindow: TWindow;
      fButton: TIconifiedButton;
      fMoving: Boolean;
      fExpanded: Boolean;
      fWidth, fHeight, fLeft, fTop: Single;
      fBtnLeft, fBtnTop: Single;
      fParkUI: TParkUI;
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
      constructor Create(Resource: String; ParkUI: TParkUI);
      destructor Free;
    end;

  TParkUIActions = class
    protected
      fLeaveActions: TGameLeaveActions;
    public
      constructor Create;
      destructor Free;
      end;

  TParkUI = class
    protected
      fTestWindow: TParkUIWindow;
      fDragging: TParkUIWindow;
      fDragStartLeft, fDragStartTop, fMouseOfsX, fMouseOfsY: Integer;
      fActions: TParkUIActions;
      procedure SetDragging(A: TParkUIWindow);
    public
      property Dragging: TParkUIWindow read fDragging write setDragging;
      procedure Drag;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_events, m_varlist, g_park;


function TParkUIWindow.AddCallbackArray(A: TDOMElement): Integer;
begin
  SetLength(fCallbackArrays, length(fCallbackArrays) + 1);
  Result := Length(fCallbackArrays);
  fCallbackArrays[Result - 1].OnClick := A.GetAttribute('onclick');
end;

procedure TParkUIWindow.HandleOnclick(Sender: TGUIComponent);
begin
  if (Sender.Tag > 0) and (Sender.Tag <= Length(fCallbackArrays)) then
    EventManager.CallEvent('GUIActions.' + fCallbackArrays[Sender.Tag - 1].OnClick, Sender, nil);
end;

procedure TParkUIWindow.Toggle(Sender: TGUIComponent);
begin
  if Expanded then
    hide
  else
    show;
end;

procedure TParkUIWindow.SetWidth(A: Single);
begin
  fWidth := A;
  if (not fMoving) and (fExpanded) then
    fWindow.Width := A;
end;

procedure TParkUIWindow.SetHeight(A: Single);
begin
  fHeight := A;
  if (not fMoving) and (fExpanded) then
    fWindow.Height := A;
end;

procedure TParkUIWindow.SetLeft(A: Single);
begin
  fLeft := A;
  if fExpanded then
    begin
    fWindow.Left := A + 16;
    fButton.Left := A;
    end;
end;

procedure TParkUIWindow.SetTop(A: Single);
begin
  fTop := A;
  if fExpanded then
    begin
    fWindow.Top := A + 16;
    fButton.Top := A;
    end;
end;

procedure TParkUIWindow.SetBtnLeft(A: Single);
begin
  fBtnLeft := A;
  if not fExpanded then
    begin
    fWindow.Left := A + 24;
    fButton.Left := A;
    end;
end;

procedure TParkUIWindow.SetBtnTop(A: Single);
begin
  fBtnTop := A;
  if not fExpanded then
    begin
    fWindow.Top := A + 24;
    fButton.Top := A;
    end;
end;

procedure TParkUIWindow.Show;
begin
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

procedure TParkUIWindow.Hide;
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

procedure TParkUIWindow.ReadFromXML(Resource: String);
var
  XMLFile: TDOMDocument;
  a: TDOMNodeList;
  CurrChild: TDOMElement;
  ResX, ResY: Integer;
begin
  XMLFile := LoadXMLFile(GetFirstExistingFileName(Resource));
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  try
    begin
    a := XMLFile.GetElementsByTagName('window');
    with TDOMElement(a[0]) do
      begin
      Width := StrToInt(GetAttribute('width'));
      Height := StrToInt(GetAttribute('height'));
      Left := StrToInt(GetAttribute('left')) - 400 + ResX / 2;
      Top := StrToInt(GetAttribute('top')) - 300 + ResY / 2;
      BtnLeft := StrToInt(GetAttribute('btnleft')) - 800 + ResX;
      BtnTop := StrToInt(GetAttribute('btntop')) - 300 + ResY / 2;
      fButton.Icon := GetAttribute('icon');
      CurrChild := TDOMElement(FirstChild);
      while CurrChild <> nil do
        begin
        with CurrChild do
          begin
          if NodeName = 'panel' then
            begin
            fWindow.OfsX1 := StrToInt(GetAttribute('leftspace'));
            fWindow.OfsX2 := StrToInt(GetAttribute('rightspace'));
            fWindow.OfsY1 := StrToInt(GetAttribute('topspace'));
            fWindow.OfsY2 := StrToInt(GetAttribute('bottomspace'));
            end
          else if NodeName = 'label' then
            begin
            with TLabel.Create(fWindow) do
              begin
              Left := StrToIntWD(GetAttribute('left'), 16);
              Top := StrToIntWD(GetAttribute('top'), 16);
              Width := StrToIntWD(GetAttribute('width'), Round(fWindow.Width - Left - 16));
              Size := Round(StrToIntWD(GetAttribute('size'), 16));
              Height := StrToIntWD(GetAttribute('height'), Round(Height));
              if FirstChild <> nil then
                Caption := FirstChild.NodeValue;
              Tag := AddCallbackArray(CurrChild);
              OnClick := @HandleOnclick;
              end;
            end
          else if NodeName = 'iconbutton' then
            begin
            with TIconifiedButton.Create(fWindow) do
              begin
              Left := StrToIntWD(GetAttribute('left'), 16);
              Top := StrToIntWD(GetAttribute('top'), 16);
              Icon := GetAttribute('icon');
              Width := StrToIntWD(GetAttribute('width'), 64);
              Height := StrToIntWD(GetAttribute('height'), 64);
              Tag := AddCallbackArray(CurrChild);
              OnClick := @HandleOnclick;
              end;
            end
          end;
        CurrChild := TDOMElement(CurrChild.NextSibling);
        end;
      end;
    end;
  except
    ModuleManager.ModLog.AddError('Could not load Park UI resouce ' + Resource + ': Internal error')
  end;
  XMLFile.Free;
end;

constructor TParkUIWindow.Create(Resource: String; ParkUI: TParkUI);
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
  fWindow.OnClick := @StartDragging;
  fWindow.OnRelease := @EndDragging;

  ReadFromXML(Resource);
end;

procedure TParkUIWindow.StartDragging(Sender: TGUIComponent);
begin
  fParkUI.Dragging := self;
end;

procedure TParkUIWindow.EndDragging(Sender: TGUIComponent);
begin
  fParkUI.Dragging := nil;
end;

destructor TParkUIWindow.Free;
begin
  fWindow.Free;
  fButton.Free;
end;

constructor TParkUIActions.Create;
begin
  fLeaveActions := TGameLeaveActions.Create;
end;

destructor TParkUIActions.Free;
begin
  fLeaveActions.Free;
end;

constructor TParkUI.Create;
var
  ResX, ResY: Integer;
begin
  fActions := TParkUIActions.Create;
  fTestWindow := TParkUIWindow.Create('ui/leave.xml', self);
end;

procedure TParkUI.SetDragging(A: TParkUIWindow);
begin
  fDragging := A;
  if A = nil then
    exit;
  fDragStartLeft := Round(Dragging.Left);
  fMouseOfsX := ModuleManager.ModInputHandler.MouseX;
  fDragStartTop := Round(Dragging.Top);
  fMouseOfsY := ModuleManager.ModInputHandler.MouseY;
end;

procedure TParkUI.Drag;
begin
  if Dragging <> nil then
    begin
    Dragging.Left := fDragStartLeft + ModuleManager.ModInputHandler.MouseX - fMouseOfsX;
    Dragging.Top := fDragStartTop + ModuleManager.ModInputHandler.MouseY - fMouseOfsY;
    end;
end;

destructor TParkUI.Free;
begin
  fActions.Free;
  fTestWindow.Free;
end;

end.