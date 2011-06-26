unit m_gui_scrollbox_class;

interface

uses
  SysUtils, Classes, m_module, m_gui_class, m_gui_label_class, math;

type
  TScrollBarMode = (sbmNormal, sbmInvisible, sbmInverted);

  TScrollBox = class(TGUIComponent)
    protected
      CX, CY: Integer;
      fSurface: TLabel;
      fCanvas: TLabel;
      fCHeight, fCWidth: Single;
      fClicking: Boolean;
      procedure HandleScroll(Sender: TGUIComponent);
      procedure HandleClick(Sender: TGUIComponent);
      procedure HandleRelease(Sender: TGUIComponent);
    public
      HScrollPosition, VScrollPosition: Integer;
      HScrollBar, VScrollBar: TScrollBarMode;
      property Surface: TLabel read fSurface;
      property ContentHeight: Single read fCHeight;
      property ContentWidth: Single read fCwidth;
      procedure Render;
      constructor Create(mParent: TGUIComponent);
    end;

  TModuleGUIScrollBoxClass = class(TBasicModule)
    public
      (**
        * Render a progress bar
        *@param The progress bar to render
        *)
      procedure Render(sb: TScrollBox); virtual abstract;
    end;

implementation

uses
  m_varlist, m_inputhandler_class, u_math;

procedure TScrollBox.HandleScroll(Sender: TGUIComponent);
var
  ScrollFactor: Integer;
  Horizontal, Vertical: Integer;
begin
  if ModuleManager.ModInputHandler.MouseButtons[MOUSE_WHEEL_UP] then
    ScrollFactor := -50
  else if ModuleManager.ModInputHandler.MouseButtons[MOUSE_WHEEL_DOWN] then
    ScrollFactor := 50;
  Vertical := 0;
  Horizontal := 0;
  if ((HScrollBar = sbmNormal) and (ModuleManager.ModInputHandler.MouseX <= MaxX) and (ModuleManager.ModInputHandler.MouseX >= MinX) and (ModuleManager.ModInputHandler.MouseY <= MaxY) and (ModuleManager.ModInputHandler.MouseY >= MaxY - 16))
  or ((HScrollBar = sbmInverted) and (ModuleManager.ModInputHandler.MouseX <= MaxX) and (ModuleManager.ModInputHandler.MouseX >= MinX) and (ModuleManager.ModInputHandler.MouseY <= MinY + 16) and (ModuleManager.ModInputHandler.MouseY >= MinY))
  or (VScrollBar = sbmInvisible) then
    Horizontal := 1
  else if VScrollBar <> sbmInvisible then
    Vertical := 1;
  HScrollPosition := Min(Max(Round(fCWidth - Width), 0), Max(0, HScrollPosition + Horizontal * ScrollFactor));
  VScrollPosition := Min(Max(Round(fCHeight - Height), 0), Max(0, VScrollPosition + Vertical * ScrollFactor));
end;

procedure TScrollBox.HandleClick(Sender: TGUIComponent);
begin
  fClicking := true;
  CX := ModuleManager.ModInputHandler.MouseX;
  CY := ModuleManager.ModInputHandler.MouseY;
end;

procedure TScrollBox.HandleRelease(Sender: TGUIComponent);
begin
  fClicking := false;
end;

procedure TScrollBox.Render;
var
  i: Integer;
  vscf, hscf: Single;
begin
  fCWidth := 0;
  fCHeight := 0;
  for i := 0 to high(fSurface.Children) do
    begin
    fCWidth := Max(fCWidth, fSurface.Children[i].Left + fSurface.Children[i].Width);
    fCHeight := Max(fCHeight, fSurface.Children[i].Top + fSurface.Children[i].Height);
    end;
  if fClicking then
    begin
    hscf := Max(0, fCWidth - Width) / Max(1, Width - Clamp(Width * Width / Max(1.0, ContentWidth), 18, Width));
    vscf := Max(0, fCHeight - Height) / Max(1, Height - Clamp(Height * Height / Max(1.0, ContentHeight), 18, Height));

    HScrollPosition := Min(Max(Round(fCWidth - Width), 0), Max(0, HScrollPosition + Round(hscf * (ModuleManager.ModInputHandler.MouseX - CX))));
    VScrollPosition := Min(Max(Round(fCHeight - Height), 0), Max(0, VScrollPosition + Round(vscf * (ModuleManager.ModInputHandler.MouseY - CY))));

    CX := ModuleManager.ModInputHandler.MouseX;
    CY := ModuleManager.ModInputHandler.MouseY;
    end;
  if HScrollBar <> sbmInvisible then
    fCanvas.Height := Max(1, Height - 16)
  else
    fCanvas.Height := Max(1, Height);
  if VScrollBar <> sbmInvisible then
    fCanvas.Width := Max(1, Width - 16)
  else
    fCanvas.Width := Max(1, Width);
  if VScrollBar = sbmInverted then
    fCanvas.Left := 16
  else if VScrollBar = sbmNormal then
    fCanvas.Left := 0;
  if HScrollBar = sbmInverted then
    fCanvas.Top := 16
  else if HScrollBar = sbmNormal then
    fCanvas.Top := 0;
  fSurface.Left := -HScrollPosition;
  fSurface.Top := -VScrollPosition;
  ModuleManager.ModGUIScrollBox.Render(Self);
end;

constructor TScrollBox.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CScrollBox);
  fClicking := false;
  HScrollPosition := 0;
  VScrollPosition := 0;
  HScrollBar := sbmNormal;
  VScrollBar := sbmNormal;
  fCanvas := TLabel.Create(Self);
  fCanvas.Left := 0;
  fCanvas.Top := 0;
  fCanvas.Height := 1;
  fCanvas.Width := 1;
  fSurface := TLabel.Create(fCanvas);
  fSurface.Left := 0;
  fSurface.Top := 0;
  fSurface.Height := 65536;
  fSurface.Width := 65536;
  fCHeight := 0;
  fCWidth := 0;
  OnScroll := @HandleScroll;
  OnClick := @HandleClick;
  OnRelease := @HandleRelease;
end;

end.