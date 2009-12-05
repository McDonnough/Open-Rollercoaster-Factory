unit m_inputhandler_glut;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_inputhandler_class;

type
  TModuleInputHandlerGLUT = class(TModuleInputHandlerClass)
    public
      constructor Create;
      procedure CheckModConf;
      procedure UpdateData;
    end;

implementation

uses
  glut;

var
  pMouseX: Integer = 0;
  pMouseY: Integer = 0;
  pMouseButtons: array[1..3] of Boolean;
  pKeys: array[0..321] of Boolean;

function GLUTKeyToAsciiKey(K: Integer): Integer;
begin
  result := K;
  case K of
    GLUT_KEY_F1: result := K_F1;
    GLUT_KEY_F2: result := K_F2;
    GLUT_KEY_F3: result := K_F3;
    GLUT_KEY_F4: result := K_F4;
    GLUT_KEY_F5: result := K_F5;
    GLUT_KEY_F6: result := K_F6;
    GLUT_KEY_F7: result := K_F7;
    GLUT_KEY_F8: result := K_F8;
    GLUT_KEY_F9: result := K_F9;
    GLUT_KEY_F10: result := K_F10;
    GLUT_KEY_F11: result := K_F11;
    GLUT_KEY_F12: result := K_F12;
    GLUT_KEY_LEFT: result := K_LEFT;
    GLUT_KEY_UP: result := K_UP;
    GLUT_KEY_RIGHT: result := K_RIGHT;
    GLUT_KEY_DOWN: result := K_DOWN;
    GLUT_KEY_PAGE_UP: result := K_PAGEUP;
    GLUT_KEY_PAGE_DOWN: result := K_PAGEDOWN;
    GLUT_KEY_HOME: result := K_HOME;
    GLUT_KEY_END: result := K_END;
    GLUT_KEY_INSERT: result := K_INSERT;
    end;
end;

procedure MouseMove(X, Y: Integer); cdecl;
begin
  pMouseX := X;
  pMouseY := Y;
end;

procedure KeyPressed(Key: Byte; X, Y: Integer); cdecl;
begin
  pKeys[Key] := true;
end;

procedure KeyReleased(Key: Byte; X, Y: Integer); cdecl;
begin
  pKeys[Key] := false;
end;

procedure SpecialPressed(Key, X, Y: Integer); cdecl;
begin
  pKeys[GLUTKeyToAsciiKey(Key)] := true;
end;

procedure SpecialReleased(Key, X, Y: Integer); cdecl;
begin
  pKeys[GLUTKeyToAsciiKey(Key)] := false;
end;

procedure MouseState(button, state, x, y: Integer); cdecl;
begin
  pMouseButtons[button + 1] := state = 1;
end;

constructor TModuleInputHandlerGLUT.Create;
var
  i: integer;
begin
  fModName := 'InputHandlerGLUT';
  fModType := 'InputHandler';

  glutMouseFunc(@MouseState);
  glutPassiveMotionFunc(@MouseMove);
  glutKeyboardFunc(@KeyPressed);
  glutKeyboardUpFunc(@KeyReleased);
  glutSpecialFunc(@SpecialPressed);
  glutSpecialUpFunc(@SpecialReleased);

  for i := 1 to high(pMouseButtons) do
    pMouseButtons[i] := false;
  for i := 0 to high(pKeys) do
    pKeys[i] := false;
end;

procedure TModuleInputHandlerGLUT.CheckModConf;
begin
end;

procedure TModuleInputHandlerGLUT.UpdateData;
var
  i: integer;
begin
  fMouseX := pMouseX;
  fMouseY := pMouseY;
  for i := 1 to high(pMouseButtons) do
    fMouseButtons[i] := pMouseButtons[i];
  for i := 0 to 321 do
    fKeys[i] := pKeys[i];
end;

end.

