unit g_parkui;

interface

uses
  SysUtils, Classes, m_gui_class, m_gui_window_class, m_gui_iconifiedbutton_class, m_gui_button_class;

type
  TParkUIWindow = class
    protected
      fWindow: TWindow;
      fButton: TIconifiedButton;
      fPX, fPY, fPW, fPH, fMX, fMY: Single;
      fShown: Boolean;
      procedure Toggle(Sender: TGUIComponent);
      procedure AdjustSize(Event: String; Data, Result: Pointer);
      procedure AdjustPosition(Event: String; Data, Result: Pointer);
    public
      property Window: TWindow read fWindow;
      procedure Show;
      procedure Hide;
      constructor Create(Icon: String; X, Y, W, H, MX, MY: Single);
      destructor Free;
    end;

  TParkUI = class
    protected
      fTestWindow: TParkUIWindow;
    public
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_events, m_varlist, g_park;

procedure TParkUIWindow.AdjustSize(Event: String; Data, Result: Pointer);
begin
  if (fShown) and (abs(fWindow.Left - fPX) < 15)  and (abs(fWindow.Top - fPY) < 15) then
    begin
    fWindow.Height := fPH;
    fWindow.Width := fPW;
    fButton.OnClick := @Toggle;
    end;
end;

procedure TParkUIWindow.AdjustPosition(Event: String; Data, Result: Pointer);
begin
  if not (fShown) and (fWindow.Width < 48) and (fWindow.Height < 48) then
    begin
    fWindow.Left := fMX + 8;
    fWindow.Top := fMY + 8;
    fButton.Left := fMX - 8;
    fButton.Top := fMY - 8;
    fButton.OnClick := @Toggle;
    end;
end;

procedure TParkUIWindow.Toggle(Sender: TGUIComponent);
begin
  fButton.OnClick := nil;
  if fShown then
    Hide
  else
    Show;
end;

procedure TParkUIWindow.Show;
begin
  fWindow.Left := fPX + 8;
  fWindow.Top := fPY + 8;
  fButton.Left := fPX - 8;
  fButton.Top := fPY - 8;
  fShown := true;
end;

procedure TParkUIWindow.Hide;
begin
  fPX := fWindow.Left;
  fPY := fWindow.Top;
  fPW := fWindow.Width;
  fPH := fWindow.Height;
  fWindow.Height := 32;
  fWindow.Width := 32;
  fShown := false;
end;

constructor TParkUIWindow.Create(Icon: String; X, Y, W, H, MX, MY: Single);
begin
  fPX := X;
  fPY := Y;
  fPH := H;
  fPW := W;
  fMX := MX;
  fMY := MY;
  fShown := false;
  fWindow := TWindow.Create(nil);
  fWindow.Left := fMX + 8;
  fWindow.Top := fMY + 8;
  fWindow.Width := 32;
  fWindow.Height := 32;
  fButton := TIconifiedButton.Create(nil);
  fButton.Left := fMX - 8;
  fButton.Height := 64;
  fButton.Width := 64;
  fButton.Top := fMY - 8;
  fButton.Icon := Icon;
  fButton.OnClick := @Toggle;
  EventManager.AddCallback('TPark.Render', @AdjustSize);
  EventManager.AddCallback('TPark.Render', @AdjustPosition);
end;

destructor TParkUIWindow.Free;
begin
  EventManager.RemoveCallback('TPark.Render', @AdjustSize);
  EventManager.RemoveCallback('TPark.Render', @AdjustPosition);
  fWindow.Free;
  fButton.Free;
end;

constructor TParkUI.Create;
var
  ResX, ResY: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fTestWindow := TParkUIWindow.Create('go-down.tga', 100, 100, 600, 400, 80, ResY - 80);
  with TIconifiedButton.Create(fTestWindow.Window) do
    begin
    Icon := 'process-stop.tga';
    Width := 64;
    Height := 64;
    Left := 500;
    Top := 300;
    OnClick := @Park.GoToMainMenu;
    end;
end;

destructor TParkUI.Free;
begin
  fTestWindow.Free;
end;

end.