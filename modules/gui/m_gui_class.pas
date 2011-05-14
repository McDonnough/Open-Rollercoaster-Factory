unit m_gui_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, DGLOpenGL;

type
  TGUIComponent = class;

  TCallbackProcedure = procedure(Sender: TGUIComponent) of object;
  TKeyCallbackProcedure = procedure(Sender: TGUIComponent; Key: Integer) of object;

  TComponentType = (CNothing, CWindow, CLabel, CButton, CIconifiedButton, CTimer, CTabBar, CEdit, CProgressBar, CScrollBox, CImage, CCheckBox, CSlider);

  AGUIComponent = array of TGUIComponent;

  TGUIComponent = class
    protected
      fRendered: Integer;
      fAlpha, fDestAlpha: GLFloat;
      fPosX, fPosY, fDestX, fDestY, fSpeedX, fSpeedY: GLFloat;
      fWidth, fHeight, fDestWidth, fDestHeight, fSpeedWidth, fSpeedHeight: GLFloat;
      fParent: TGUIComponent;
      fChildren: AGUIComponent;
      fChildOrder: Array of Integer;
      fTypeName: TComponentType;
      function GetChildInOrder(I: Integer): TGUIComponent;
      function GetAbsX: GLFloat;
      function GetAbsY: GLFloat;
      function GetMinX: GLFloat;
      function GetMinY: GLFloat;
      function GetMaxX: GLFloat;
      function GetMaxY: GLFloat;
    private
      fChildID: Integer;
      function AddChild(Child: TGUIComponent): Integer;
      procedure RemoveChild(Child: TGUIComponent);
    public
      Rendered: Boolean;
      Tag: Integer;
      Name: String;
      TranslateContent: Boolean;
      OnClick: TCallbackProcedure;
      OnGainFocus: TCallbackProcedure;
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
      property ChildrenRightOrder[I: Integer]: TGUIComponent read GetChildInOrder;
      property ComponentType: TComponentType read fTypeName;
      property AbsX: GLFloat read GetAbsX;
      property AbsY: GLFloat read GetAbsY;
      property MinX: GLFloat read GetMinX;
      property MinY: GLFloat read GetMinY;
      property MaxX: GLFloat read GetMaxX;
      property MaxY: GLFloat read GetMaxY;
      procedure BringToFront(Child: TGUIComponent);
      procedure Render;
      function GetChildByName(S: String): TGUIComponent;
      constructor Create(mParent: TGUIComponent; TypeName: TComponentType);
      destructor Free;
    end;

  TModuleGUIClass = class(TBasicModule)
    protected
      fBasicComponent: TGUIComponent;
      fFocusComponent: TGUIComponent;
      fHoverComponent: TGUIComponent;
      fClicking: Boolean;
      procedure BasicComponentOnClick(Sender: TGUIComponent);
      procedure BasicComponentOnRelease(Sender: TGUIComponent);
      procedure BasicComponentOnKeyDown(Sender: TGUIComponent; Key: Integer);
      procedure BasicComponentOnKeyUp(Sender: TGUIComponent; Key: Integer);
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
  m_varlist, math, u_math, main, u_events, m_gui_image_class;

procedure TModuleGUIClass.BasicComponentOnClick(Sender: TGUIComponent);
begin
  EventManager.CallEvent('BasicComponent.OnClick', Sender, nil);
end;

procedure TModuleGUIClass.BasicComponentOnRelease(Sender: TGUIComponent);
begin
  EventManager.CallEvent('BasicComponent.OnRelease', Sender, nil);
end;

procedure TModuleGUIClass.BasicComponentOnKeyDown(Sender: TGUIComponent; Key: Integer);
begin
  EventManager.CallEvent('BasicComponent.OnKeyDown', Sender, @Key);
end;

procedure TModuleGUIClass.BasicComponentOnKeyUp(Sender: TGUIComponent; Key: Integer);
begin
  EventManager.CallEvent('BasicComponent.OnKeyUp', Sender, @Key);
end;


function TGUIComponent.GetChildInOrder(I: Integer): TGUIComponent;
var
  j: Integer;
begin
  Result := nil;
  for j := 0 to high(fChildOrder) do
    if fChildOrder[j] = i then
      exit(fChildren[j]);
end;

function TGUIComponent.GetAbsX: GLFloat;
begin
  Result := Left;
  if Parent <> nil then
    Result := Left + Parent.GetAbsX;
end;

function TGUIComponent.GetAbsY: GLFloat;
begin
  Result := Top;
  if Parent <> nil then
    Result := Top + Parent.GetAbsY;
end;

function TGUIComponent.GetMinX: GLFloat;
begin
  Result := AbsX;
  if Parent <> nil then
    Result := Max(Result, Parent.MinX);
end;

function TGUIComponent.GetMinY: GLFloat;
begin
  Result := AbsY;
  if Parent <> nil then
    Result := Max(Result, Parent.MinY);
end;

function TGUIComponent.GetMaxX: GLFloat;
begin
  Result := AbsX + Width;
  if Parent <> nil then
    Result := Min(Result, Parent.MaxX);
end;

function TGUIComponent.GetMaxY: GLFloat;
begin
  Result := AbsY + Height;
  if Parent <> nil then
    Result := Min(Result, Parent.MaxY);
end;

function TGUIComponent.AddChild(Child: TGUIComponent): Integer;
begin
  setLength(fChildren, length(fChildren) + 1);
  fChildren[high(fChildren)] := Child;
  Result := high(fChildren);
  SetLength(fChildOrder, length(fChildOrder) + 1);
  fChildOrder[high(fChildOrder)] := high(fChildOrder);
end;

procedure TGUIComponent.RemoveChild(Child: TGUIComponent);
var
  I: Integer;
begin
  for i := Child.fChildID + 1 to high(fChildren) do
    begin
    fChildOrder[i - 1] := fChildOrder[i];
    fChildren[i - 1] := fChildren[i];
    dec(fChildren[i - 1].fChildID);
    end;
  setLength(fChildOrder, length(fChildOrder) - 1);
  setLength(fChildren, length(fChildren) - 1);
  for i := 0 to high(fChildOrder) do
    if fChildOrder[i] > Child.fChildID then
      dec(fChildOrder[i]);
end;

procedure TGUIComponent.Render;
const
  MAX_MOTION_SPEED = 0.1;
  SPEED_ADD = 0.005;
var
  i: Integer;
  MS: Single;
begin
  MS := 10;
  if FPSDisplay <> nil then
    MS := FPSDisplay.MS;
  for i := 0 to Round(10 * MS) do
    begin
    fAlpha := fAlpha + (fDestAlpha - fAlpha) / 1000;
  {  fPosX := fPosX + fSpeedX;
    fPosY := fPosY + fSpeedY;}
    fPosX := fPosX + (fDestX - fPosX) / 1000;
    fPosY := fPosY + (fDestY - fPosY) / 1000;
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
  {  fSpeedX := clamp(sign(fDestX - fPosX) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fPosX - fDestX))), max(fSpeedX - SPEED_ADD, -5 * MAX_MOTION_SPEED), min(fSpeedX + SPEED_ADD, 5 * MAX_MOTION_SPEED));
    fSpeedY := clamp(sign(fDestY - fPosY) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fPosY - fDestY))), max(fSpeedY - SPEED_ADD, -5 * MAX_MOTION_SPEED), min(fSpeedY + SPEED_ADD, 5 * MAX_MOTION_SPEED));}
    fSpeedWidth := clamp(sign(fDestWidth - fWidth) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fWidth - fDestWidth))), max(fSpeedWidth - SPEED_ADD, -MAX_MOTION_SPEED), min(fSpeedWidth + SPEED_ADD, MAX_MOTION_SPEED));
    fSpeedHeight := clamp(sign(fDestHeight - fHeight) * 0.5 * (-SPEED_ADD + sqrt(SPEED_ADD * SPEED_ADD + 8 * SPEED_ADD * abs(fHeight - fDestHeight))), max(fSpeedHeight - SPEED_ADD, -MAX_MOTION_SPEED), min(fSpeedHeight + SPEED_ADD, MAX_MOTION_SPEED));
    end;
  fRendered := 1;
end;

function TGUIComponent.GetChildByName(S: String): TGUIComponent;
var
  i: Integer;
begin
  Result := nil;
  if Name = S then
    Result := Self
  else
    for i := 0 to high(fChildren) do
      begin
      Result := fChildren[i].GetChildByName(S);
      if Result <> nil then
        exit;
      end;
end;

procedure TGUIComponent.BringToFront(Child: TGUIComponent);
var
  i, j, OldPosition: Integer;
begin
  j := 0;
  OldPosition := High(fChildOrder);
  for i := 0 to high(fChildOrder) do
    if fChildren[i] = Child then
      OldPosition := fChildOrder[i];
  for i := 0 to high(fChildOrder) do
    begin
    if fChildren[i] = Child then
      fChildOrder[i] := High(fChildOrder)
    else if fChildOrder[i] > OldPosition then
      dec(fChildOrder[i]);
    if fChildOrder[i] < j then
      j := fChildOrder[i];
    end;
  for i := 0 to high(fChildOrder) do
    if fChildOrder[i] <> High(fChildOrder) then
      fChildOrder[i] := fChildOrder[i] - j;
  if Child.OnGainFocus <> nil then
    Child.OnGainFocus(Child);
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

  TranslateContent := true;

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
  OnRelease := nil;
  OnGainFocus := nil;
  OnHover := nil;
  OnLeave := nil;
  OnKeyDown := nil;
  OnKeyUp := nil;
end;

destructor TGUIComponent.Free;
begin
  while high(fChildren) >= 0 do
    case fChildren[0].ComponentType of
      CImage: TImage(fChildren[0]).Free;
    else
      fChildren[0].Free;
    end;
  if fParent <> nil then
    fParent.RemoveChild(Self);
end;

end.

