unit m_settings_default;

interface

uses
  SysUtils, Classes, m_settings_class, m_gui_class, m_gui_window_class, m_gui_iconifiedbutton_class, m_gui_tabbar_class, m_gui_label_class, u_functions, m_gui_scrollbox_class;

type
  TModuleSettingsDefault = class(TModuleSettingsClass)
    protected
      fWindow: TWindow;
      fBgLabel, fFgLabel, fContainerLabel: TLabel;
      fShown: Boolean;
      fTabs: TTabBar;
      fApplyButton, fCancelButton: TIconifiedButton;
      fMessageLabel: TLabel;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      procedure ChangeTab(Sender: TGUIComponent);
      procedure Close(Sender: TGUIComponent);
      procedure Apply(Sender: TGUIComponent);
      procedure ShowConfigurationInterface;
      procedure HideConfigurationInterface;
    end;

implementation

uses
  m_varlist, u_events;

constructor TModuleSettingsDefault.Create;
begin
  fModType := 'Settings';
  fModName := 'SettingsDefault';
end;

procedure TModuleSettingsDefault.Close(Sender: TGUIComponent);
begin
  fCanBeDestroyed := True;
end;

procedure TModuleSettingsDefault.Apply(Sender: TGUIComponent);
begin
  EventManager.CallEvent('TSettings.ApplyConfigurationChanges', nil, nil);
  Close(Sender);
end;

procedure TModuleSettingsDefault.CheckModConf;
begin
  fShown := false;
end;

procedure TModuleSettingsDefault.ShowConfigurationInterface;
var
  ResX, ResY, i: Integer;
begin
  if fShown then
    exit;

  fCanBeDestroyed := false;

  fShown := True;

  fInterfaces := TConfigurationInterfaceList.Create;

  ModuleManager.ModGlContext.GetResolution(ResX, ResY);

  fBgLabel := TLabel.Create(nil);
  fBgLabel.Left := 0;
  fBgLabel.Top := 0;
  fBgLabel.Height := ResY;
  fBgLabel.Width := ResX;

  fWindow := TWindow.Create(fBgLabel);
  fWindow.Width := 700;
  fWindow.Height := 400;
  fWindow.Left := (ResX - 700) / 2;
  fWindow.Top := (ResY - 400) / 2;
  fWindow.OfsY1 := 32;
  fWindow.OfsY2 := 24;

  fContainerLabel := TLabel.Create(fWindow);
  fContainerLabel.Left := 8;
  fContainerLabel.Top := 40;
  fContainerLabel.Height := 400 - 72;
  fContainerLabel.Width := 700 - 16;

  fFgLabel := TLabel.Create(fContainerLabel);
  fFgLabel.Left := 0;
  fFgLabel.Top := 0;
  fFgLabel.Height := 400 - 72;
  fFgLabel.Width := 10 * (700 - 16);

  fTabs := TTabBar.Create(fWindow);
  fTabs.Left := 8;
  fTabs.Top := 8;
  fTabs.Width := 700 - 16;
  fTabs.Height := 32;
  fTabs.OnChangeTab := @ChangeTab;

  fApplyButton := TIconifiedButton.Create(fWindow);
  fApplyButton.Icon := 'dialog-ok-apply.tga';
  fApplyButton.Top := 400 - 52;
  fApplyButton.Left := 700 - 100;
  fApplyButton.Width := 48;
  fApplyButton.Height := 48;
  fApplyButton.OnClick := @Apply;

  fCancelButton := TIconifiedButton.Create(fWindow);
  fCancelButton.Icon := 'dialog-cancel.tga';
  fCancelButton.Top := 400 - 52;
  fCancelButton.Left := 700 - 52;
  fCancelButton.Width := 48;
  fCancelButton.Height := 48;
  fCancelButton.OnClick := @Close;

  fMessageLabel := TLabel.Create(fWindow);
  fMessageLabel.Top := 372;
  fMessageLabel.Left := 8;
  fMessageLabel.Size := 16;
  fMessageLabel.Width := 600;
  fMessageLabel.Height := 16;
  fMessageLabel.Caption := 'Most changes will only be applied when the game is restarted.';

  EventManager.CallEvent('TSettings.CreateConfigurationInterface', fFgLabel, fInterfaces);

  for i := 0 to fInterfaces.Count - 1 do
    begin
    fTabs.AddTab(fInterfaces.Items[i].Title, 32);
    fInterfaces.Items[i].Content.HScrollBar := sbmInvisible;
    fInterfaces.Items[i].Content.Top := 0;
    fInterfaces.Items[i].Content.Left := (700 - 16) * i;
    fInterfaces.Items[i].Content.Width := 700 - 16;
    fInterfaces.Items[i].Content.Height := 400 - 72;
    end;
end;

procedure TModuleSettingsDefault.HideConfigurationInterface;
begin
  if not fShown then
    exit;

  fCanBeDestroyed := false;

  EventManager.CallEvent('TSettings.DestroyConfigurationInterface', nil, nil);
  
  fInterfaces.Free;
  fShown := False;
  fBgLabel.Free;
end;

procedure TModuleSettingsDefault.ChangeTab(Sender: TGUIComponent);
begin
  fFgLabel.Left := -(700 - 16) * fTabs.SelectedTab;
end;

destructor TModuleSettingsDefault.Free;
begin
  HideConfigurationInterface;
end;

end.