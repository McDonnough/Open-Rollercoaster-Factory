unit o_objectcreator;

interface

uses
  SysUtils, Classes, m_gui_window_class, m_gui_label_class, m_gui_button_class, m_gui_iconifiedbutton_class, m_gui_scrollbox_class,
  m_gui_image_class, g_loader_ocf, u_dialogs, u_vectors, m_gui_tabbar_class, m_gui_class;

type
  TStaticSelectorList = class(TScrollBox)
    protected
      fItems: Array of TLabel;
    public
      procedure Add(S: String);
      procedure Clear;
    end;

  TObjectCreator = class
    protected
      fCanClose: Boolean;
      fBGLabel, fTabContainer, fTabContainer2, fResourceTab, fMeshTab: TLabel;
      fWindow: TWindow;
      fTabBar: TTabBar;
      procedure OnChangeTab(Sender: TGUIComponent);
    public
      property CanClose: Boolean read fCanClose;
      constructor Create;
      destructor Free;
    end;

var
  ObjectCreator: TObjectCreator = nil;

implementation

uses
  m_varlist;

procedure TStaticSelectorList.Add(S: String);
begin
  SetLength(fItems, length(fItems) + 1);
end;

procedure TStaticSelectorList.Clear;
var
  I: Integer;
begin
  for I := 0 to high(fItems) do
    fItems[I].Free;
  SetLength(fItems, 0);
end;


procedure TObjectCreator.OnChangeTab(Sender: TGUIComponent);
begin
  fTabContainer.Left := -784 * fTabBar.SelectedTab;
end;

constructor TObjectCreator.Create;
var
  ResX, ResY: Integer;
begin
  fCanClose := False;

  ModuleManager.ModGlContext.GetResolution(ResX, ResY);

  fBGLabel := TLabel.Create(nil);
  fBGLabel.Left := 0;
  fBGLabel.Top := 0;
  fBGLabel.Height := ResY;
  fBGLabel.Width := ResX;
  fBGLabel.Color := Vector(0, 0, 0, 0.4);

  fWindow := TWindow.Create(fBGLabel);
  fWindow.Width := 800;
  fWindow.Height := 600;
  fWindow.Top := 0.5 * (ResY - 600);
  fWindow.Left := 0.5 * (ResX - 800);
  fWindow.OfsY1 := 32;

  fTabBar := TTabBar.Create(fWindow);
  fTabBar.Left := 8;
  fTabBar.Height := 32;
  fTabBar.Width := 784;
  fTabBar.Top := 8;
  fTabBar.AddTab('Resources');
  fTabBar.AddTab('Particles & Sounds');
  fTabBar.OnChangeTab := @OnChangeTab;

  fTabContainer2 := TLabel.Create(fWindow);
  fTabContainer2.Left := 8;
  fTabContainer2.Top := 40;
  fTabContainer2.Width := 784;
  fTabContainer2.Height := 552;

  fTabContainer := TLabel.Create(fTabContainer2);
  fTabContainer.Left := 0;
  fTabContainer.Top := 0;
  fTabContainer.Width := 2 * 784;
  fTabContainer.Height := 552;

  fResourceTab := TLabel.Create(fTabContainer);
  fResourceTab.Left := 0;
  fResourceTab.Top := 0;
  fResourceTab.Height := 552;
  fResourceTab.Width := 784;

  fMeshTab := TLabel.Create(fTabContainer);
  fMeshTab.Left := 784;
  fMeshTab.Top := 0;
  fMeshTab.Height := 552;
  fMeshTab.Width := 784;
end;

destructor TObjectCreator.Free;
begin
  fBGLabel.Free;
end;

end.