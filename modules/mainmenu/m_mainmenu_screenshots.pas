unit m_mainmenu_screenshots;

interface

uses
  m_module, SysUtils, Classes, m_gui_class, m_gui_window_class, m_gui_button_class, m_mainmenu_class;

type
  TModuleMainMenuScreenshots = class(TModuleMainMenuClass)
    protected
      fWindow: TWindow;
      procedure SetValue(Sender: TGUIComponent);
    public
      procedure Render;
      procedure Setup;
      procedure Hide;
      constructor Create;
      procedure CheckModConf;
    end;

implementation

procedure TModuleMainMenuScreenshots.SetValue(Sender: TGUIComponent);
begin
  fValue := Sender.Tag;
end;

procedure TModuleMainMenuScreenshots.Setup;
begin
  fValue := 0;
  fWindow.Left := -32;
end;

procedure TModuleMainMenuScreenshots.Hide;
begin
  fWindow.Left := -fWindow.Width;
end;

procedure TModuleMainMenuScreenshots.Render;
begin

end;

constructor TModuleMainMenuScreenshots.Create;
begin
  fModName := 'MainMenuScreenshots';
  fModType := 'MainMenu';

  fWindow := TWindow.Create(nil);
  fWindow.Top := 100;
  fWindow.Width := 300;
  fWindow.Height := 400;
  fWindow.Left := -300;
  fWindow.Render;

  with TButton.Create(fWindow) do
    begin
    Left := 40;
    Width := 236;
    Height := 32;
    Top := 32;
    Caption := 'Start new game';
    Tag := MMVAL_STARTGAME;
    onClick := @SetValue;
    end;

  with TButton.Create(fWindow) do
    begin
    Left := 40;
    Width := 236;
    Height := 32;
    Top := 80;
    Caption := 'Load park';
    Tag := MMVAL_LOADGAME;
    onClick := @SetValue;
    end;

  with TButton.Create(fWindow) do
    begin
    Left := 40;
    Width := 236;
    Height := 32;
    Top := 128;
    Caption := 'Settings';
    Tag := MMVAL_SETTINGS;
    onClick := @SetValue;
    end;

  with TButton.Create(fWindow) do
    begin
    Left := 40;
    Width := 236;
    Height := 32;
    Top := 172;
    Caption := 'Help';
    Tag := MMVAL_HELP;
    onClick := @SetValue;
    end;

  with TButton.Create(fWindow) do
    begin
    Left := 40;
    Width := 236;
    Height := 32;
    Top := 220;
    Caption := 'Quit';
    Tag := MMVAL_QUIT;
    onClick := @SetValue;
    end;
end;

procedure TModuleMainMenuScreenshots.CheckModConf;
begin
end;


end.