unit g_parkui;

interface

uses
  SysUtils, Classes, dglOpenGL, m_gui_class, m_gui_window_class, m_gui_iconifiedbutton_class, m_gui_button_class, u_files, u_dom, u_xml,
  m_gui_label_class, m_gui_image_class, m_gui_edit_class, m_gui_progressbar_class, m_gui_timer_class, m_gui_tabbar_class, u_functions,
  m_gui_slider_class, m_gui_checkbox_class, u_vectors, math, m_texmng_class, u_math;

type
  TColorPicker = class;

  TColorPickerWindow = class(TLabel)
    protected
      ResX, ResY: Integer;
      fR, fG, fB: TSlider;
      fCircle, fLuminosity: TImage;
      fCircleMark, fLuminosityMark: TImage;
      fContainerWindow: TWindow;
      fPicker: TColorPicker;
      fWheelTexture, fLuminosityTexture: TTexture;
      procedure fStartChangeHueSaturation(Sender: TGUIComponent);
      procedure fStartChangeLuminosity(Sender: TGUIComponent);
      procedure fEndChanges(Sender: TGUIComponent);
      procedure fChangeHueSaturation(Event: String; Data, Result: Pointer);
      procedure fChangeLuminosity(Event: String; Data, Result: Pointer);
      procedure fChangeHSL(Sender: TGUIComponent);
      procedure fChangeRGB(Sender: TGUIComponent);
      procedure fClose(Sender: TGUIComponent);
    public
      procedure Show(Picker: TColorPicker);
      constructor Create(Picker: TColorPicker);
    end;

  TColorPicker = class(TLabel)
    protected
      fReset: TIconifiedButton;
      fChooser: TButton;
      fDisplay: TLabel;
      fCurrentValue: TVector3D;
      fDefaultValue: TVector3D;
      procedure fDoReset(Sender: TGUIComponent);
      procedure fPick(Sender: TGUIComponent);
      procedure fSetCurrentValue(C: TVector3D);
    public
      ChangeEvent: String;
      property CurrentColor: TVector3D read fCurrentValue write fSetCurrentValue;
      property DefaultColor: TVector3D read fDefaultValue write fDefaultValue;
      procedure CallUpdateEvent;
      procedure UpdateDimensions;
      constructor Create(mParent: TGUIComponent);
    end;
    

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
      procedure HandleOnEdit(Sender: TGUIComponent);
      procedure HandleOnRelease(Sender: TGUIComponent);
      procedure HandleOnKeyDown(Sender: TGUIComponent; Key: Integer);
      procedure HandleOnKeyUp(Sender: TGUIComponent; Key: Integer);
      procedure HandleOnHover(Sender: TGUIComponent);
      procedure HandleOnLeave(Sender: TGUIComponent);
      procedure HandleOnChangeTab(Sender: TGUIComponent);
      procedure BringButtonToFront(Sender: TGUIComponent);
    public
      property Window: TWindow read fWindow;
      property Button: TIconifiedButton read fButton;
      property Width: Single read fWidth write SetWidth;
      property Height: Single read fHeight write SetHeight;
      property Left: Single read fLeft write SetLeft;
      property Top: Single read fTop write SetTop;
      property BtnLeft: Single read fBtnLeft write SetBtnLeft;
      property BtnTop: Single read fBtnTop write SetBtnTop;
      property Expanded: Boolean read fExpanded;
      procedure Show(Sender: TGUIComponent);
      procedure Hide(Sender: TGUIComponent);
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
      function GetWindowByName(N: String): TXMLUIWindow;
      constructor Create;
      destructor Free;
      end;

var
  ParkUI: TParkUI = nil;

implementation

uses
  u_events, m_varlist, g_park, g_leave, g_info, g_terrain_edit, g_park_settings, g_object_selector, g_object_builder,
  g_selection_mode, u_graphics, m_inputhandler_class;

type
  TParkUIWindowList = record
    fParkSettings: TGameParkSettings;
    fLeaveWindow: TGameLeave;
    fInfoWindow: TGameInfo;
    fTerrainEdit: TGameTerrainEdit;
    fObjectSelector: TGameObjectSelector;
    fObjectBuilder: TGameObjectBuilder;
    fSelectionModeWindow: TGameSelectionModeWindow;
    end;

var
  WindowList: TParkUIWindowList;
  ColorPickerWindow: TColorPickerWindow = nil;

procedure TColorPickerWindow.fStartChangeHueSaturation(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TPark.Render', @fChangeHueSaturation);
end;

procedure TColorPickerWindow.fStartChangeLuminosity(Sender: TGUIComponent);
begin
  EventManager.AddCallback('TPark.Render', @fChangeLuminosity);
end;

procedure TColorPickerWindow.fEndChanges(Sender: TGUIComponent);
begin
  EventManager.RemoveCallback(@fChangeHueSaturation);
  EventManager.RemoveCallback(@fChangeLuminosity);
end;

procedure TColorPickerWindow.fChangeHueSaturation(Event: String; Data, Result: Pointer);
var
  A: TVector2D;
begin
  A := Vector(ModuleManager.ModInputHandler.MouseX - fCircle.AbsX, ModuleManager.ModInputHandler.MouseY - fCircle.AbsY) - 120.0;
  A := Normalize(A) * Min(120, VecLength(A));
  fCircleMark.Left := A.X + 118;
  fCircleMark.Top := A.Y + 118;
  fChangeHSL(fCircle);
  if not ModuleManager.ModInputHandler.MouseButtons[MOUSE_LEFT] then
    fEndChanges(Self);
end;

procedure TColorPickerWindow.fChangeLuminosity(Event: String; Data, Result: Pointer);
begin
  fLuminosityMark.Top := Clamp(ModuleManager.ModInputHandler.MouseY - fLuminosity.AbsY - 2, 0, 239);
  fChangeHSL(fLuminosity);
  if not ModuleManager.ModInputHandler.MouseButtons[MOUSE_LEFT] then
    fEndChanges(Self);
end;

procedure TColorPickerWindow.fChangeHSL(Sender: TGUIComponent);
var
  tmp: DWord;
  RGB: TVector3D;
  Luminosity, Saturation, Degrees: Single;
  A: TVector2D;
begin
  if Sender = fCircle then
    A := Vector(ModuleManager.ModInputHandler.MouseX - fCircle.AbsX, ModuleManager.ModInputHandler.MouseY - fCircle.AbsY) - 120.0
  else
    A := Vector(fCircleMark.Left, fCircleMark.Top) - 118.0;
  if Sender = fLuminosity then
    Luminosity := 255 - (Clamp(ModuleManager.ModInputHandler.MouseY - fLuminosity.AbsY - 2, 0, 239) * 255 / 239)
  else
    Luminosity := 255 - (fLuminosityMark.Top * 255 / 239);
  Degrees := ArcCos(DotProduct(Normalize(A), Vector(0, -1)));
  if DotProduct(A, Vector(1, 0)) < 0 then
    Degrees := 6.283185 - Degrees;
  Degrees := 255 * FPart(Degrees / 6.283185);
  Saturation := 255 * Min(VecLength(A) / 120, 1);
  tmp := Round(Degrees) or (Round(Saturation) shl 8) or (Round(Luminosity) shl 16) or $FF000000;
  tmp := HSVAtoRGBA(tmp);
  RGB := Vector(tmp and $FF, (tmp shr 8) and $FF, (tmp shr 16) and $FF);
  fR.Value := RGB.X;
  fG.Value := RGB.Y;
  fB.Value := RGB.Z;
  fPicker.CurrentColor := RGB / 255.0;
  fCircle.Color := Vector(Luminosity, Luminosity, Luminosity) / 255;
  fLuminosity.Color := RGB / Max(1, Max(Max(RGB.X, RGB.Y), RGB.Z));
end;

procedure TColorPickerWindow.fChangeRGB(Sender: TGUIComponent);
var
  tmp: DWord;
  RGB, HSL: TVector3D;
  VectorLength: Single;
  A: TVector2D;
begin
  fPicker.CurrentColor := Vector(fR.Value, fG.Value, fB.Value) / 255.0;
  tmp := Round(fR.Value) or (Round(fG.Value) shl 8) or (Round(fB.Value) shl 16) or $FF000000;
  tmp := RGBAtoHSVA(tmp);
  HSL := Vector(tmp and $FF, (tmp shr 8) and $FF, (tmp shr 16) and $FF);
  fLuminosityMark.Top := (255 - HSL.Z) * 239 / 255;
  VectorLength := HSL.Y * 120 / 255;
  A := Vector(Sin(HSL.X * 6.283185 / 255), -Cos(HSL.X * 6.283185 / 255));
  fCircleMark.Left := 118 + A.X * VectorLength;
  fCircleMark.Top := 118 + A.Y * VectorLength;
  fCircle.Color := Vector(HSL.Z, HSL.Z, HSL.Z) / 255;
  RGB := Vector(fR.Value, fG.Value, fB.Value);
  fLuminosity.Color := RGB / Max(1, Max(Max(RGB.X, RGB.Y), RGB.Z));
end;

procedure TColorPickerWindow.fClose(Sender: TGUIComponent);
begin
  Top := -ResY - 10;
end;

procedure TColorPickerWindow.Show(Picker: TColorPicker);
begin
  Top := 0;
  fPicker := Picker;

  fContainerWindow.Left := Picker.AbsX - 16;
  fContainerWindow.Top := Max(0, Picker.AbsY - 368);
  ModuleManager.ModGUI.BasicComponent.BringToFront(Self);

  fR.Value := 255 * fPicker.CurrentColor.X;
  fG.Value := 255 * fPicker.CurrentColor.Y;
  fB.Value := 255 * fPicker.CurrentColor.Z;
  fChangeRGB(Self);
end;

constructor TColorPickerWindow.Create(Picker: TColorPicker);
begin
  inherited Create(nil);
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  Width := ResX;
  Height := ResY;
  Top := -ResY - 10;
  Left := 0;
  OnClick := @fClose;

  fContainerWindow := TWindow.Create(Self);
  fContainerWindow.Height := 360;
  fContainerWindow.Width := 280;
  fContainerWindow.OfsX1 := 0;
  fContainerWindow.OfsX2 := ResX;
  fContainerWindow.OfsY1 := 0;
  fContainerWindow.OfsY2 := ResY;

  fR := TSlider.Create(fContainerWindow);
  fR.Top := 256;
  fR.Left := 12;
  fR.Width := 256;
  fR.Height := 32;
  fR.Min := 0;
  fR.Max := 255;
  fR.Digits := 0;
  fR.OnChange := @fChangeRGB;

  fG := TSlider.Create(fContainerWindow);
  fG.Top := 288;
  fG.Left := 12;
  fG.Width := 256;
  fG.Height := 32;
  fG.Min := 0;
  fG.Max := 255;
  fG.Digits := 0;
  fG.OnChange := @fChangeRGB;

  fB := TSlider.Create(fContainerWindow);
  fB.Top := 320;
  fB.Left := 12;
  fB.Width := 256;
  fB.Height := 32;
  fB.Min := 0;
  fB.Max := 255;
  fB.Digits := 0;
  fB.OnChange := @fChangeRGB;

  fCircle := TImage.Create(fContainerWindow);
  fCircle.Left := 6;
  fCircle.Top := 6;
  fCircle.Height := 244;
  fCircle.Width := 244;
  fCircle.FreeTextureOnDestroy := True;
  fCircle.Tex := TTexture.Create;
  fCircle.Tex.FromFile('data/guicolorpicker/wheel.tga', False, False);
  fCircle.Tex.SetFilter(GL_NEAREST, GL_NEAREST);
  fCircle.OnClick := @fStartChangeHueSaturation;

  fLuminosity := TImage.Create(fContainerWindow);
  fLuminosity.Left := 256;
  fLuminosity.Top := 6;
  fLuminosity.Width := 20;
  fLuminosity.Height := 244;
  fLuminosity.FreeTextureOnDestroy := True;
  fLuminosity.Tex := TTexture.Create;
  fLuminosity.Tex.FromFile('data/guicolorpicker/luminosity.tga', False, False);
  fLuminosity.Tex.SetFilter(GL_NEAREST, GL_NEAREST);
  fLuminosity.OnClick := @fStartChangeLuminosity;

  fCircleMark := TImage.Create(fCircle);
  fCircleMark.Left := 118;
  fCircleMark.Top := 118;
  fCircleMark.Width := 8;
  fCircleMark.Height := 8;
  fCircleMark.FreeTextureOnDestroy := True;
  fCircleMark.Tex := TTexture.Create;
  fCircleMark.Tex.FromFile('data/guicolorpicker/wheelmark.tga', False, False);
  fCircleMark.Tex.SetFilter(GL_NEAREST, GL_NEAREST);
  fCircleMark.OnClick := @fStartChangeHueSaturation;

  fLuminosityMark := TImage.Create(fLuminosity);
  fLuminosityMark.Left := 0;
  fLuminosityMark.Top := 0;
  fLuminosityMark.Width := 20;
  fLuminosityMark.Height := 6;
  fLuminosityMark.FreeTextureOnDestroy := True;
  fLuminosityMark.Tex := TTexture.Create;
  fLuminosityMark.Tex.FromFile('data/guicolorpicker/luminositymark.tga', False, False);
  fLuminosityMark.Tex.SetFilter(GL_NEAREST, GL_NEAREST);
  fLuminosityMark.OnClick := @fStartChangeLuminosity;

  Show(Picker);
end;

procedure TColorPicker.fDoReset(Sender: TGUIComponent);
begin
  CurrentColor := DefaultColor;
end;

procedure TColorPicker.fPick(Sender: TGUIComponent);
begin
  if ColorPickerWindow = nil then
    ColorPickerWindow := TColorPickerWindow.Create(Self)
  else
    ColorPickerWindow.Show(Self);
end;

procedure TColorPicker.fSetCurrentValue(C: TVector3D);
begin
  fCurrentValue := C;
  CallUpdateEvent;
end;

procedure TColorPicker.CallUpdateEvent;
begin
  fDisplay.Color := Vector(CurrentColor, 1.0);
  EventManager.CallEvent(ChangeEvent, Self, nil);
end;

procedure TColorPicker.UpdateDimensions;
begin
  fReset.Left := fDestWidth - 32;
  fChooser.Width := fDestWidth - 32;
  fDisplay.Width := fDestWidth - 56;
end;

constructor TColorPicker.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent);
  Size := 16;
  Height := 32;
  Width := 96;

  fReset := TIconifiedButton.Create(Self);
  fReset.Left := 64;
  fReset.Top := 0;
  fReset.Height := 32;
  fReset.Width := 32;
  fReset.OnClick := @fDoReset;
  fReset.Icon := 'edit-undo.tga';

  fChooser := TButton.Create(Self);
  fChooser.Left := 0;
  fChooser.Width := 64;
  fChooser.Height := 32;
  fChooser.Top := 0;
  fChooser.OnClick := @fPick;
  
  fDisplay := TLabel.Create(fChooser);
  fDisplay.Left := 12;
  fDisplay.Top := 8;
  fDisplay.Height := 16;
  fDisplay.Width := 40;
  fDisplay.OnClick := @fPick;

  DefaultColor := Vector(1, 1, 1);
  CurrentColor := Vector(1, 1, 1);
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

procedure TXMLUIWindow.HandleOnEdit(Sender: TGUIComponent);
begin
  if (Sender.Tag > 0) and (Sender.Tag <= Length(fCallbackArrays)) then
    EventManager.CallEvent('GUIActions.' + fCallbackArrays[Sender.Tag - 1].OnEdit, Sender, nil);
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
    Hide(Sender)
  else
    Show(Sender);
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

procedure TXMLUIWindow.Show(Sender: TGUIComponent);
begin
  ModuleManager.ModGUI.BasicComponent.BringToFront(fWindow);
  fWindow.Width := fWidth;
  fWindow.Height := fHeight;
  fWindow.Alpha := 1;
  fWindow.Left := fLeft + 16;
  fWindow.Top := fTop + 16;
  if fWindow.HasBackground then
    begin
    fButton.Left := fLeft;
    fButton.Top := fTop;
    end
  else
    begin
    fButton.Left := fBtnLeft - 8;
    fButton.Top := fBtnTop - 8;
    end;
  fButton.Width := 64;
  fButton.Height := 64;
  if (not Expanded) then
    begin
    fExpanded := true;
    if (fWindow.Name <> '') then
      EventManager.CallEvent('GUIActions.' + fWindow.Name + '.open', Sender, nil);
    end;
end;

procedure TXMLUIWindow.Hide(Sender: TGUIComponent);
begin
  fWindow.Width := 0;
  fWindow.Height := 0;
  fWindow.Alpha := 0;
  fWindow.Left := fBtnLeft + 24;
  fWindow.Top := fBtnTop + 24;
  fButton.Left := fBtnLeft;
  fButton.Top := fBtnTop;
  fButton.Width := 48;
  fButton.Height := 48;
  if (Expanded) then
    begin
    fExpanded := false;
    if (fWindow.Name <> '') then
      EventManager.CallEvent('GUIActions.' + fWindow.Name + '.close', Sender, nil);
    end;
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
      else if NodeName = 'color' then
        begin
        A := TColorPicker.Create(P);
        with TColorPicker(A) do
          begin
          Left := StrToIntWD(GetAttribute('left'), 16);
          Top := StrToIntWD(GetAttribute('top'), 16);
          Width := StrToIntWD(GetAttribute('width'), Round(P.Width - Left - 16));
          Height := StrToIntWD(GetAttribute('height'), Round(Height));
          Tag := AddCallbackArray(TDOMElement(DE));
          ChangeEvent := 'GUIActions.' + GetAttribute('onchange');
          Alpha := StrToFloatWD(GetAttribute('alpha'), 1);
          UpdateDimensions;
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
          Height := StrToIntWD(GetAttribute('height'), 32);
          if FirstChild <> nil then
            Text := FirstChild.NodeValue;
          Tag := AddCallbackArray(TDOMElement(DE));
          Alpha := StrToFloatWD(GetAttribute('alpha'), 1);
          OnClick := @HandleOnclick;
          OnChange := @HandleOnEdit;
          OnRelease := @HandleOnrelease;
          OnHover := @HandleOnHover;
          OnLeave := @HandleOnLeave;
          end;
        end
      else if NodeName = 'checkbox' then
        begin
        A := TCheckbox.Create(P);
        with TCheckbox(A) do
          begin
          Left := StrToIntWD(GetAttribute('left'), 16);
          Top := StrToIntWD(GetAttribute('top'), 16);
          Width := StrToIntWD(GetAttribute('width'), 32);
          Height := StrToIntWD(GetAttribute('height'), 32);
          Tag := AddCallbackArray(TDOMElement(DE));
          Alpha := StrToFloatWD(GetAttribute('alpha'), 1);
          OnChange := @HandleOnEdit;
          OnHover := @HandleOnHover;
          OnLeave := @HandleOnLeave;
          end;
        end
      else if NodeName = 'slider' then
        begin
        A := TSlider.Create(P);
        with TSlider(A) do
          begin
          Left := StrToIntWD(GetAttribute('left'), 16);
          Top := StrToIntWD(GetAttribute('top'), 16);
          Width := StrToIntWD(GetAttribute('width'), 64);
          Height := StrToIntWD(GetAttribute('height'), 64);
          Tag := AddCallbackArray(TDOMElement(DE));
          Alpha := StrToFloatWD(GetAttribute('alpha'), 1);
          Min := StrToFloatWD(GetAttribute('min'), 0);
          Max := StrToFloatWD(GetAttribute('max'), 1);
          Value := StrToFloatWD(GetAttribute('value'), 0);
          Digits := StrToIntWD(GetAttribute('digits'), 0);
          OnChange := @HandleOnEdit;
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
      fWindow.HasBackground := GetAttribute('background') <> 'false';
      Width := StrToInt(GetAttribute('width'));
      Height := StrToInt(GetAttribute('height'));

      if GetAttribute('halign') = 'left' then
        Left := StrToInt(GetAttribute('left'))
      else if GetAttribute('halign') = 'right' then
        Left := StrToInt(GetAttribute('left')) - 800 + ResX
      else
        Left := StrToInt(GetAttribute('left')) - 400 + ResX / 2;

      if GetAttribute('valign') = 'top' then
        Top := StrToInt(GetAttribute('top'))
      else if GetAttribute('valign') = 'bottom' then
        Top := StrToInt(GetAttribute('top')) - 600 + ResY
      else
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
  if fWindow.HasBackground then
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
    Dragging.Window.ImmediatelyApplyGeometry;
    Dragging.Button.ImmediatelyApplyGeometry;
    end;
end;

function TParkUI.GetWindowByName(N: String): TXMLUIWindow;
begin
  if WindowList.fLeaveWindow.Window.Name = N then exit(WindowList.fLeaveWindow);
  if WindowList.fInfoWindow.Window.Name = N then exit(WindowList.fInfoWindow);
  if WindowList.fTerrainEdit.Window.Name = N then exit(WindowList.fTerrainEdit);
  if WindowList.fParkSettings.Window.Name = N then exit(WindowList.fParkSettings);
  if WindowList.fObjectSelector.Window.Name = N then exit(WindowList.fObjectSelector);
  if WindowList.fObjectBuilder.Window.Name = N then exit(WindowList.fObjectBuilder);
  if WindowList.fSelectionModeWindow.Window.Name = N then exit(WindowList.fSelectionModeWindow);
end;

constructor TParkUI.Create;
var
  ResX, ResY: Integer;
begin
  writeln('Hint: Creating ParkUI object');
  WindowList.fLeaveWindow := TGameLeave.Create('ui/leave.xml', self);
  WindowList.fInfoWindow := TGameInfo.Create('ui/info.xml', self);
  WindowList.fTerrainEdit := TGameTerrainEdit.Create('ui/terrain_edit.xml', self);
  WindowList.fParkSettings := TGameParkSettings.Create('ui/park_settings.xml', self);
  WindowList.fObjectSelector := TGameObjectSelector.Create('ui/object_selector.xml', self);
  WindowList.fObjectBuilder := TGameObjectBuilder.Create('ui/object_builder.xml', self);
  WindowList.fSelectionModeWindow := TGameSelectionModeWindow.Create('ui/selection_mode.xml', self);
end;

destructor TParkUI.Free;
begin
  writeln('Hint: Deleting ParkUI object');
  WindowList.fSelectionModeWindow.Free;
  WindowList.fObjectSelector.Free;
  WindowList.fObjectBuilder.Free;
  WindowList.fLeaveWindow.Free;
  WindowList.fInfoWindow.Free;
  WindowList.fTerrainEdit.Free;
  WindowList.fParkSettings.Free;
  if ColorPickerWindow <> nil then
    begin
    ColorPickerWindow.Free;
    ColorPickerWindow := nil;
    end;
end;

end.