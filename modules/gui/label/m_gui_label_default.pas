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
var
  Left: Single;
begin
  case Lbl.Align of
    LABEL_ALIGN_CENTER: Left := Lbl.Left + (Lbl.Width - ModuleManager.ModFont.CalculateTextWidth(Lbl.Caption, Lbl.Size)) / 2;
    LABEL_ALIGN_RIGHT: Left := Lbl.Left + Lbl.Width - ModuleManager.ModFont.CalculateTextWidth(Lbl.Caption, Lbl.Size);
  else
    Left := Lbl.Left;
    end;
  ModuleManager.ModFont.Write(ModuleManager.ModLanguage.Translate(Lbl.Caption), Lbl.Size, Left, Lbl.Top, 0, 0, 0, Lbl.Alpha, 0);
end;

end.

