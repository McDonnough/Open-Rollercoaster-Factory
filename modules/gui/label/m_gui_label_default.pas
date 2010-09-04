unit m_gui_label_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_gui_label_class, DGLOpenGL, u_functions;

type
  TLblResource = record
    Lbl: TLabel;
    Width: Single;
    Size, Align: Integer;
    CTexts: Array of AString;
    Caption: String;
    end;

  TModuleGUILabelDefault = class(TModuleGUILabelClass)
    protected
      LblResources: Array of TLblResource;
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
  j, i, n, Start, k: Integer;
  Lines, Words: AString;
  Text, CS: String;
  found: Boolean;
begin
  found := false;
  for k := 0 to high(LblResources) do
    if LblResources[k].Lbl = Lbl then
      begin
      found := true;
      break;
      end;
  if not found then
    begin
    SetLength(LblResources, Length(LblResources) + 1);
    k := high(LblResources);
    LblResources[k].Lbl := Lbl;
    LblResources[k].Size := -1;
    LblResources[k].Width := -1;
    LblResources[k].Align := -1;
    LblResources[k].Caption := '';
    end;
  with LblResources[k] do
    begin
    if (Size <> Lbl.Size) or (Width <> Lbl.Width) or (Align <> Lbl.Align) or (Caption <> Lbl.Caption) then
      begin
      n := 0;
      Lines := Explode(#10, ModuleManager.ModLanguage.Translate(Lbl.Caption));
      Size := Lbl.Size;
      Width := Lbl.Width;
      Align := Lbl.Align;
      Caption := Lbl.Caption;
      SetLength(CTexts, 0);
      for j := 0 to high(Lines) do
        begin
        SetLength(CTexts, Length(CTexts) + 1);
        Text := Lines[j];
        SetLength(CTexts[high(CTexts)], 0);
        Start := 0;
        Words := Explode(' ', Text);
        CS := '';
        for i := 0 to high(Words) do
          begin
          CS := CS + Words[i] + ' ';
          if (ModuleManager.ModFont.CalculateTextWidth(CS, Lbl.Size) > Lbl.Width) and (Start < i) then
            begin
            Start := i;
            SetLength(CTexts[high(CTexts)], length(CTexts[high(CTexts)]) + 1);
            CS := SubString(CS, 1, Length(CS) - Length(Words[i]) - 2);
            CTexts[high(CTexts), high(CTexts[high(CTexts)])] := CS;
            CS := Words[i] + ' ';
            end;
          end;
        SetLength(CTexts[high(CTexts)], length(CTexts[high(CTexts)]) + 1);
        CTexts[high(CTexts)][high(CTexts[high(CTexts)])] := SubString(CS, 1, Length(CS) - 1);
        for i := 0 to high(CTexts[high(CTexts)]) do
          begin
          case Lbl.Align of
            LABEL_ALIGN_CENTER: Left := Lbl.Left + (Lbl.Width - ModuleManager.ModFont.CalculateTextWidth(CTexts[high(CTexts), i], Lbl.Size)) / 2;
            LABEL_ALIGN_RIGHT: Left := Lbl.Left + Lbl.Width - ModuleManager.ModFont.CalculateTextWidth(CTexts[high(CTexts), i], Lbl.Size);
          else
            Left := Lbl.Left;
            end;
          ModuleManager.ModFont.Write(CTexts[high(CTexts), i], Lbl.Size, Left, Lbl.Top + Lbl.Size * n, 0, 0, 0, Lbl.Alpha, 0);
          inc(n);
          end;
        end;
      end
    else
      begin
      n := 0;
      for j := 0 to high(CTexts) do
        for i := 0 to high(CTexts[j]) do
          begin
          case Lbl.Align of
            LABEL_ALIGN_CENTER: Left := Lbl.Left + (Lbl.Width - ModuleManager.ModFont.CalculateTextWidth(CTexts[high(CTexts), i], Lbl.Size)) / 2;
            LABEL_ALIGN_RIGHT: Left := Lbl.Left + Lbl.Width - ModuleManager.ModFont.CalculateTextWidth(CTexts[high(CTexts), i], Lbl.Size);
          else
            Left := Lbl.Left;
            end;
          ModuleManager.ModFont.Write(CTexts[j, i], Lbl.Size, Left, Lbl.Top + Lbl.Size * n, 0, 0, 0, Lbl.Alpha, 0);
          inc(n);
          end;
      end;
    end;
end;

end.

