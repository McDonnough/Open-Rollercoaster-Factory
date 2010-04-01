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
      fPosX, fPosY, fDestX, fDestY, fSpeedX, fSpeedY: GLFloat;
      fWidth, fHeight, fDestWidth, fDestHeight, fSpeedWidth, fSpeedHeight: GLFloat;
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
  m_varlist, math, u_math;

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
const
  MAX_MOTION_SPEED = 5.0;
  SPEED_ADD = 0.2;
begin
  fAlpha := fAlpha + (fDestAlpha - fAlpha) / 10;
  fPosX := fPosX + fSpeedX;
  fPosY := fPosY + fSpeedY;
  fWidth := fWidth + fSpeedWidth;
  fHeight := fHeight + fSpeedHeight;
  if fRendered * abs(fPosX - fDestX) < 1 then
    fPosX := fDestX;
  if fRendered * abs(fPosY - fDestY) < 1 then
    fPosY := fDestY;
  if fRendered * abs(fWidth - fDestWidth) < 1 then
    fWidth := fDestWidth;
  if fRendered * abs(fHeight - fDestHeight) < 1 then
    fHeight := fDestHeight;
  fSpeedX := clamp(sign(fDestX - fPosX) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fPosX - fDestX))), -MAX_MOTION_SPEED, MAX_MOTION_SPEED);
  fSpeedY := clamp(sign(fDestY - fPosY) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fPosY - fDestY))), -MAX_MOTION_SPEED, MAX_MOTION_SPEED);
  fSpeedWidth := clamp(sign(fDestWidth - fWidth) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fWidth - fDestWidth))), -MAX_MOTION_SPEED, MAX_MOTION_SPEED);
  fSpeedHeight := clamp(sign(fDestHeight - fHeight) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fHeight - fDestHeight))), -MAX_MOTION_SPEED, MAX_MOTION_SPEED);
  fRendered := 1;
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
  fSpeedX := 0;
  fSpeedY := 0;
  fWidth := 0;
  fHeight := 0;
  fDestWidth := 0;
  fDestHeight := 0;
  fSpeedWidth := 0;
  fSpeedHeight := 0;
  fRendered := 0;

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

