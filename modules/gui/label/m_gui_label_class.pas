unit m_gui_label_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, m_gui_class;

type
  TLabel = class(TGUIComponent)
    public
      Caption: String;
      Size: Integer;
      procedure Render;
      constructor Create(mParent: TGUIComponent);
    end;

  TModuleGUILabelClass = class(TBasicModule)
    public
      (**
        * Render a label
        *@param Label
        *)
      procedure Render(Lbl: TLabel); virtual abstract;
    end;

implementation

uses
  m_varlist;

procedure TLabel.Render;
begin
  ModuleManager.ModGUILabel.Render(Self);
end;

constructor TLabel.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CLabel);
  Size := 12;
  Caption := '';
end;

end.

