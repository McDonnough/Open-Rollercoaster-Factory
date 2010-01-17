unit m_gui_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, DGLOpenGL;

type
  TGUIComponent = class;

  TCallbackProcedure = procedure(Sender: TGUIComponent) of object;
  TKeyCallbackProcedure = procedure(Sender: TGUIComponent; Key: Integer) of object;

  TComponentType = (CNothing, CWindow, CLabel, CButton, CIconifiedButton, CTimer, CTabBar, CPanel, CEdit, CProgressBar, CDropdownList);

  AGUIComponent = array of TGUIComponent;

  TGUIComponent = class
    protected
      fRendered: Integer;
      fAlpha, fDestAlpha: GLFloat;
      fPosX, fPosY, fDestX, fDestY: GLFloat;
      fWidth, fHeight, fDestWidth, fDestHeight: GLFloat;
      fParent: TGUIComponent;
      fChildren: AGUIComponent;
      fTypeName: TComponentType;
    private
      fChildID: Integer;
      function AddChild(Child: TGUIComponent): Integer;
      procedure RemoveChild(Child: TGUIComponent);
    public
      Tag: Integer;
      OnClick: TCallbackProcedure;
      OnRelease: TCallbackProcedure;
      OnHover: TCallbackProcedure;
      OnLeave: TCallbackProcedure;
      OnKeyDown: TKeyCallbackProcedure;
      OnKeyUp: TKeyCallbackProcedure;
      property Alpha: GLFloat read fAlpha write fDestAlpha;
      property Left: GLFloat read fPosX write fDestX;
      property Top: GLFloat read fPosY write fDestY;
      property Width: GLFloat read fWidth write fDestWidth;
      property Height: GLFloat read fHeight write fDestHeight;
      property Parent: TGUIComponent read fParent;
      property Children: AGUIComponent read fChildren;
      property ComponentType: TComponentType read fTypeName;
      procedure Render;
      constructor Create(mParent: TGUIComponent; TypeName: TComponentType);
      destructor Free;
    end;

  TModuleGUIClass = class(TBasicModule)
    protected
      fBasicComponent: TGUIComponent;
      fFocusComponent: TGUIComponent;
      fHoverComponent: TGUIComponent;
      fClicking: Boolean;
    public
      property Clicking: Boolean read fClicking;
      property BasicComponent: TGUIComponent read fBasicComponent;
      property HoverComponent: TGUIComponent read fHoverComponent;
      property FocusComponent: TGUIComponent read fFocusComponent;

      (**
        * Call signal procedures
        *)
      procedure CallSignals; virtual abstract;

      (**
        * Render all attached objects
        *)
      procedure Render; virtual abstract;
    end;

implementation

uses
  m_varlist;

function TGUIComponent.AddChild(Child: TGUIComponent): Integer;
begin
  setLength(fChildren, length(fChildren) + 1);
  fChildren[high(fChildren)] := Child;
  Result := high(fChildren);
end;

procedure TGUIComponent.RemoveChild(Child: TGUIComponent);
var
  I: Integer;
begin
  for i := Child.fChildID + 1 to high(fChildren) do
    begin
    fChildren[i - 1] := fChildren[i];
    dec(fChildren[i - 1].fChildID);
    end;
  setLength(fChildren, length(fChildren) - 1);
end;

procedure TGUIComponent.Render;
begin
  fAlpha := fAlpha + (fDestAlpha - fAlpha) / 10;
  fPosX := fPosX + (fDestX - fPosX) / (1 * fRendered);
  fPosY := fPosY + (fDestY - fPosY) / (1 * fRendered);
  fWidth := fWidth + (fDestWidth - fWidth) / (1 * fRendered);
  fHeight := fHeight + (fDestHeight - fHeight) / (1 * fRendered);
  fRendered := 10;
end;

constructor TGUIComponent.Create(mParent: TGUIComponent; TypeName: TComponentType);
begin
  if (mParent = nil) and (TypeName <> CNothing) then
    mParent := ModuleManager.ModGUI.BasicComponent;
  fTypeName := TypeName;
  fParent := mParent;
  if fParent <> nil then
    fChildID := fParent.AddChild(Self);
  fAlpha := 0;
  fDestAlpha := 1;

  fPosX := 0;
  fPosY := 0;
  fDestX := 0;
  fDestY := 0;
  fWidth := 0;
  fHeight := 0;
  fDestWidth := 0;
  fDestHeight := 0;
  fRendered := 1;

  OnClick := nil;
  OnHover := nil;
  OnLeave := nil;
  OnKeyDown := nil;
  OnKeyUp := nil;
end;

destructor TGUIComponent.Free;
begin
  while high(fChildren) >= 0 do
    fChildren[0].Free;
  if fParent <> nil then
    fParent.RemoveChild(Self);
end;

end.

