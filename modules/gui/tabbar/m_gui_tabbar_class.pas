unit m_gui_tabbar_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, m_gui_class;

type
  TTab = record
    Caption: String;
    MinWidth: Integer;
    end;

  TTabBar = class(TGUIComponent)
    protected
      fSelectedTab: Integer;
      procedure SelectTab(I: Integer);
      procedure CheckTab(Sender: TGUIComponent);
    public
      Tabs: Array of TTab;
      OnChangeTab: TCallbackProcedure;
      property SelectedTab: Integer read fSelectedTab write SelectTab;
      procedure AddTab(Caption: String; MinWidth: Integer = 150);
      procedure RemoveTab(ID: Integer);
      procedure Render;
      constructor Create(mParent: TGUIComponent);
    end;

  TModuleGUITabBarClass = class(TBasicModule)
    public
      (**
        * Render a TabBar
        *@param TabBar
        *)
      procedure Render(Lbl: TTabBar); virtual abstract;

      (**
        * Calculate width of a tab
        *@param TabBar
        *@param Tab ID
        *@return Width in pixels
        *)
      function GetTabWidth(Lbl: TTabBar; I: Integer): Integer; virtual abstract;
    end;

implementation

uses
  m_varlist, math;

procedure TTabBar.CheckTab(Sender: TGUIComponent);
var
  InternalOffset, TabWidth, Offset: Integer;
  i: Integer;
begin
  Offset := Round(ModuleManager.ModInputHandler.MouseX - AbsX);
  InternalOffset := 0;
  for i := 0 to high(Tabs) do
    begin
    TabWidth := ModuleManager.ModGUITabBar.GetTabWidth(Self, I);
    if (Offset >= InternalOffset) and (Offset <= InternalOffset + TabWidth) then
      begin
      SelectedTab := i;
      exit;
      end;
    InternalOffset := InternalOffset + TabWidth;
    end;
end;

procedure TTabBar.AddTab(Caption: String; MinWidth: Integer = 150);
begin
  SetLength(Tabs, length(Tabs) + 1);
  Tabs[high(Tabs)].Caption := Caption;
  Tabs[high(Tabs)].MinWidth := MinWidth;
end;

procedure TTabBar.RemoveTab(ID: Integer);
var
  i: Integer;
begin
  if SelectedTab = ID then
    SelectedTab := Max(ID, high(Tabs));
  for i := ID + 1 to high(Tabs) do
    Tabs[i - 1] := Tabs[i];
  SetLength(Tabs, length(Tabs) - 1);
end;

procedure TTabBar.Render;
begin
  ModuleManager.ModGUITabBar.Render(Self);
end;

procedure TTabBar.SelectTab(I: Integer);
begin
  fSelectedTab := I;
  if OnChangeTab <> nil then
    OnChangeTab(Self);
end;

constructor TTabBar.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CTabBar);
  OnClick := @CheckTab;
  OnChangeTab := nil;
  fSelectedTab := 0;
end;

end.

