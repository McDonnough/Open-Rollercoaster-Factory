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
  m_varlist, u_functions;

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
  j, i, n, Start: Integer;
  Lines, CText, Words: AString;
  Text, CS: String;
begin
  n := 0;
  Lines := Explode(#10, Lbl.Caption);
  for j := 0 to high(Lines) do
    begin
    Text := Lines[j];
    SetLength(CText, 0);
    Start := 0;
    Words := Explode(' ', Text);
    CS := '';
    for i := 0 to high(Words) do
      begin
      CS := CS + Words[i] + ' ';
      if (ModuleManager.ModFont.CalculateTextWidth(CS, Lbl.Size) > Lbl.Width) and (Start < i) then
        begin
        Start := i;
        SetLength(CText, length(CText) + 1);
        CS := SubString(CS, 1, Length(CS) - Length(Words[i]) - 2);
        CText[high(CText)] := CS;
        CS := Words[i] + ' ';
        end;
      end;
    SetLength(CText, length(CText) + 1);
    CText[high(CText)] := SubString(CS, 1, Length(CS) - 1);
    for i := 0 to high(CText) do
      begin
      case Lbl.Align of
        LABEL_ALIGN_CENTER: Left := Lbl.Left + (Lbl.Width - ModuleManager.ModFont.CalculateTextWidth(CText[i], Lbl.Size)) / 2;
        LABEL_ALIGN_RIGHT: Left := Lbl.Left + Lbl.Width - ModuleManager.ModFont.CalculateTextWidth(CText[i], Lbl.Size);
      else
        Left := Lbl.Left;
        end;
      ModuleManager.ModFont.Write(ModuleManager.ModLanguage.Translate(CText[i]), Lbl.Size, Left, Lbl.Top + Lbl.Size * n, 0, 0, 0, Lbl.Alpha, 0);
      inc(n);
      end;
    end;
end;

end.

