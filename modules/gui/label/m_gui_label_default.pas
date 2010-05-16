unit m_gui_label_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_gui_label_class, DGLOpenGL;

type
  TModuleGUILabelDefault = class(TModuleGUILabelClass)
    public
      constructor Create;
      procedure CheckModConf;
      procedure Render(Lbl: TLabel);
    end;

implementation

uses
  m_varlist;

constructor TModuleGUILabelDefault.Create;
begin
  fModName := 'GUILabelDefault';
  fModType := 'GUILabel';
end;

procedure TModuleGUILabelDefault.CheckModConf;
begin
end;

procedure TModuleGUILabelDefault.Render(Lbl: TLabel);
begin
  ModuleManager.ModFont.Write(ModuleManager.ModLanguage.Translate(Lbl.Caption), Lbl.Size, Lbl.Left, Lbl.Top, 0, 0, 0, Lbl.Alpha, 0);
end;

end.

