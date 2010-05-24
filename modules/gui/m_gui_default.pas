unit m_gui_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_gui_class, DGLOpenGL;

type
  TModuleGUIDefault = class(TModuleGUIClass)
    protected
      fKeys: array[0..321] of Boolean;
    public
      procedure Render;
      procedure CallSignals;
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_gui_window_class, m_gui_label_class, m_gui_progressbar_class, m_varlist, m_inputhandler_class, m_gui_button_class, m_gui_iconifiedbutton_class,
  m_gui_edit_class, m_gui_timer_class;

procedure TModuleGUIDefault.Render;
var
  ResX, ResY: Integer;

  procedure RenderComponent(Component: TGUIComponent);
  var
    i: Integer;
  begin
    if Component = nil then
      exit;
    case Component.ComponentType of
      CWindow: TWindow(Component).Render;
      CLabel: TLabel(Component).Render;
      CProgressBar: TProgressBar(Component).Render;
      CButton: TButton(Component).Render;
      CIconifiedButton: TIconifiedButton(Component).Render;
      CEdit: TEdit(Component).Render;
      CTimer: TTimer(Component).Render;
    else
      Component.Render;
      end;
    glPushMatrix;
    glTranslatef(Round(Component.Left), Round(Component.Top), 1);
    for i := 0 to high(Component.Children) do
      begin
      glScissor(Round(Component.MinX), ResY - Round(Component.MaxY), Round(Component.MaxX - Component.MinX), Round(Component.MaxY - Component.MinY));
      RenderComponent(Component.ChildrenRightOrder[i]);
      end;
    glPopMatrix;
  end;

begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  glDisable(GL_DEPTH_TEST);
  glDepthMask(false);
  glEnable(GL_SCISSOR_TEST);
  glScissor(0, 0, ResX, ResY);
  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp2DMatrix;
  glMatrixMode(GL_MODELVIEW);

  glPushMatrix;
  glLoadIdentity;

  glTranslatef(0, 0, -254);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  RenderComponent(fBasicComponent);

  glPopMatrix;
  glDisable(GL_SCISSOR_TEST);
end;

procedure TModuleGUIDefault.CallSignals;
  procedure SendSignals(Component: TGUIComponent);
  var
    i: integer;
  begin
    if (ModuleManager.ModInputHandler.MouseX >= Component.MinX) and (ModuleManager.ModInputHandler.MouseX <= Component.MaxX)
    and (ModuleManager.ModInputHandler.MouseY >= Component.MinY)  and (ModuleManager.ModInputHandler.MouseY <=  Component.MaxY) then
      fHoverComponent := Component;

    for i := 0 to high(Component.Children) do
      SendSignals(Component.ChildrenRightOrder[i]);
  end;
var
  i: integer;
  ResX, ResY: Integer;
  Container: TGUIComponent;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fBasicComponent.Width := ResX;
  fBasicComponent.Height := ResY;

  fHoverComponent := fBasicComponent;
  SendSignals(fBasicComponent);

  if fHoverComponent <> nil then
    begin
    if fHoverComponent.OnHover <> nil then
      fHoverComponent.OnHover(fHoverComponent);
    if ModuleManager.ModInputHandler.MouseButtons[MOUSE_LEFT] then
      begin
      if (not fClicking) and (fHoverComponent.OnClick <> nil) then
        fHoverComponent.OnClick(fHoverComponent);
      fFocusComponent := fHoverComponent;
      Container := fFocusComponent;
      while (Container.Parent <> nil) and (Container.Parent <> fBasicComponent) do
        Container := Container.Parent;
      if Container.Parent = fBasicComponent then
        fBasicComponent.BringToFront(Container);
      fClicking := true;
      end;
    end;

  if fFocusComponent <> nil then
    begin
    for i := 0 to 321 do
      begin
      if (fFocusComponent.OnKeyDown <> nil) and (ModuleManager.ModInputHandler.Key[i]) and (fKeys[i] <> ModuleManager.ModInputHandler.Key[i]) then
        fFocusComponent.OnKeyDown(fFocusComponent, i);
      if (fFocusComponent.OnKeyUp <> nil) and (ModuleManager.ModInputHandler.Key[i]) and (fKeys[i] <> ModuleManager.ModInputHandler.Key[i]) then
        fFocusComponent.OnKeyUp(fFocusComponent, i);
      end;
    if (not ModuleManager.ModInputHandler.MouseButtons[MOUSE_LEFT]) and (fClicking) then
      begin
      if (fFocusComponent.OnRelease <> nil) then
        fFocusComponent.OnRelease(fFocusComponent);
      fClicking := false;
      end;
    end;

  for i := 0 to 321 do
    fKeys[i] := ModuleManager.ModInputHandler.Key[i];
end;

procedure TModuleGUIDefault.CheckModConf;
begin
end;

constructor TModuleGUIDefault.Create;
var
  i: integer;
begin
  fModName := 'GUIDefault';
  fModType := 'GUI';

  fBasicComponent := TGUIComponent.Create(nil, CNothing);

  fFocusComponent := nil;
  fHoverComponent := nil;
  fClicking := false;

  for i := 0 to 321 do
    fKeys[i] := false;
end;

destructor TModuleGUIDefault.Free;
begin
  fBasicComponent.Free;
end;

end.

