unit m_gui_edit_class;

interface

uses
  SysUtils, Classes, m_module, m_gui_class, DGLOpenGL;

type
  TEdit = class(TGUIComponent)
      fCursorPos: Integer;
      fText: String;
      procedure SetCursorPos(Pos: Integer);
      procedure SetText(Text: String);
      procedure KeyPressed(Sender: TGUIComponent; Key: Integer);
    public
      MovedChars: Integer;
      OnChange: TCallbackProcedure;
      fHoverFactor, fClickFactor: GLFloat;
      property CursorPos: Integer read fCursorPos write SetCursorPos;
      property Text: String read fText write SetText;
      procedure Render;
      constructor Create(mParent: TGUIComponent);
    end;

  TModuleGUIEditClass = class(TBasicModule)
    public
      (** Render a TEdit
        *@param The edit to render
        *)
      procedure Render(Edit: TEdit); virtual abstract;

      (** Handle a keypress
        *@param The edit to handle
        *@param The key that has been pressed
        *)
      procedure HandleKeypress(Edit: TEdit; Key: Integer); virtual abstract;
    end;

implementation

uses
  m_varlist;

procedure TEdit.SetCursorPos(Pos: Integer);
begin
  if Pos > Length(Text) then
    fCursorPos := Length(Text)
  else
    fCursorPos := Pos;
end;

procedure TEdit.SetText(Text: String);
begin
  fText := Text;
  SetCursorPos(fCursorPos);
end;

procedure TEdit.Render;
begin
  ModuleManager.ModGUIEdit.Render(Self);
end;

procedure TEdit.KeyPressed(Sender: TGUIComponent; Key: Integer);
begin
  ModuleManager.ModGUIEdit.HandleKeypress(Self, Key);
  if OnChange <> nil then
    OnChange(Self);
end;

constructor TEdit.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CEdit);
  SetText('');
  OnChange := nil;
  OnKeyDown := @KeyPressed;
  MovedChars := 0;
end;

end.