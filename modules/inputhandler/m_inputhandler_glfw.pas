unit m_inputhandler_glfw;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_inputhandler_class, glfw;

type
  TModuleInputHandlerGLFW = class(TModuleInputHandlerClass)
    public
      constructor Create;
      procedure CheckModConf;
      procedure UpdateData;
    end;

implementation

uses
  m_varlist;

constructor TModuleInputHandlerGLFW.Create;
begin
  fModName := 'InputHandlerGLFW';
  fModType := 'InputHandler';
end;

procedure TModuleInputHandlerGLFW.CheckModConf;
begin
end;

procedure TModuleInputHandlerGLFW.UpdateData;
begin
  glfwPollEvents;
  glfwGetMousePos(fMouseX, fMouseY);
  QuitRequest := false;
  fMouseButtons[1] := glfwGetMouseButton(0) <> 0;
  fMouseButtons[2] := glfwGetMouseButton(1) <> 0;
  fMouseButtons[3] := glfwGetMouseButton(2) <> 0;
  //General characters
  fKeys[K_a] := glfwGetKey(ord('A')) <> 0;
  fKeys[K_b] := glfwGetKey(ord('B')) <> 0;
  fKeys[K_c] := glfwGetKey(ord('C')) <> 0;
  fKeys[K_d] := glfwGetKey(ord('D')) <> 0;
  fKeys[K_e] := glfwGetKey(ord('E')) <> 0;
  fKeys[K_f] := glfwGetKey(ord('F')) <> 0;
  fKeys[K_g] := glfwGetKey(ord('G')) <> 0;
  fKeys[K_h] := glfwGetKey(ord('H')) <> 0;
  fKeys[K_i] := glfwGetKey(ord('I')) <> 0;
  fKeys[K_j] := glfwGetKey(ord('J')) <> 0;
  fKeys[K_k] := glfwGetKey(ord('K')) <> 0;
  fKeys[K_l] := glfwGetKey(ord('L')) <> 0;
  fKeys[K_m] := glfwGetKey(ord('M')) <> 0;
  fKeys[K_n] := glfwGetKey(ord('N')) <> 0;
  fKeys[K_o] := glfwGetKey(ord('O')) <> 0;
  fKeys[K_p] := glfwGetKey(ord('P')) <> 0;
  fKeys[K_q] := glfwGetKey(ord('Q')) <> 0;
  fKeys[K_r] := glfwGetKey(ord('R')) <> 0;
  fKeys[K_s] := glfwGetKey(ord('S')) <> 0;
  fKeys[K_t] := glfwGetKey(ord('T')) <> 0;
  fKeys[K_u] := glfwGetKey(ord('U')) <> 0;
  fKeys[K_v] := glfwGetKey(ord('V')) <> 0;
  fKeys[K_w] := glfwGetKey(ord('W')) <> 0;
  fKeys[K_x] := glfwGetKey(ord('X')) <> 0;
  fKeys[K_y] := glfwGetKey(ord('Y')) <> 0;
  fKeys[K_z] := glfwGetKey(ord('Z')) <> 0;
  //Numbers
  fKeys[K_0] := glfwGetKey(ord('0')) <> 0;
  fKeys[K_1] := glfwGetKey(ord('1')) <> 0;
  fKeys[K_2] := glfwGetKey(ord('2')) <> 0;
  fKeys[K_3] := glfwGetKey(ord('3')) <> 0;
  fKeys[K_4] := glfwGetKey(ord('4')) <> 0;
  fKeys[K_5] := glfwGetKey(ord('5')) <> 0;
  fKeys[K_6] := glfwGetKey(ord('6')) <> 0;
  fKeys[K_7] := glfwGetKey(ord('7')) <> 0;
  fKeys[K_8] := glfwGetKey(ord('8')) <> 0;
  fKeys[K_9] := glfwGetKey(ord('9')) <> 0;
  //F-keys
  fKeys[K_F1] := glfwGetKey(GLFW_KEY_F1) <> 0;
  fKeys[K_F2] := glfwGetKey(GLFW_KEY_F2) <> 0;
  fKeys[K_F3] := glfwGetKey(GLFW_KEY_F3) <> 0;
  fKeys[K_F4] := glfwGetKey(GLFW_KEY_F4) <> 0;
  fKeys[K_F5] := glfwGetKey(GLFW_KEY_F5) <> 0;
  fKeys[K_F6] := glfwGetKey(GLFW_KEY_F6) <> 0;
  fKeys[K_F7] := glfwGetKey(GLFW_KEY_F7) <> 0;
  fKeys[K_F8] := glfwGetKey(GLFW_KEY_F8) <> 0;
  fKeys[K_F9] := glfwGetKey(GLFW_KEY_F9) <> 0;
  fKeys[K_F10] := glfwGetKey(GLFW_KEY_F10) <> 0;
  fKeys[K_F11] := glfwGetKey(GLFW_KEY_F11) <> 0;
  fKeys[K_F12] := glfwGetKey(GLFW_KEY_F12) <> 0;
  fKeys[K_F13] := glfwGetKey(GLFW_KEY_F13) <> 0;
  fKeys[K_F14] := glfwGetKey(GLFW_KEY_F14) <> 0;
  fKeys[K_F15] := glfwGetKey(GLFW_KEY_F15) <> 0;
  //Misc keys
  fKeys[K_RSHIFT] := glfwGetKey(GLFW_KEY_RSHIFT) <> 0;
  fKeys[K_LSHIFT] := glfwGetKey(GLFW_KEY_LSHIFT) <> 0;
  fKeys[K_SHIFT] := fKeys[K_LSHIFT] or fKeys[K_RSHIFT];
  fKeys[K_RALT] := glfwGetKey(GLFW_KEY_RALT) <> 0;
  fKeys[K_LALT] := glfwGetKey(GLFW_KEY_LALT) <> 0;
  fKeys[K_ALT] := fKeys[K_RALT] or fKeys[K_LALT];
  fKeys[K_RCTRL] := glfwGetKey(GLFW_KEY_RCTRL) <> 0;
  fKeys[K_LCTRL] := glfwGetKey(GLFW_KEY_LCTRL) <> 0;
  fKeys[K_CTRL] := fKeys[K_RCTRL] or fKeys[K_LCTRL];
  fKeys[K_BACKSPACE] := glfwGetKey(GLFW_KEY_BACKSPACE) <> 0;
  fKeys[K_TAB] := glfwGetKey(GLFW_KEY_TAB) <> 0;
  if glfwGetWindowParam(GLFW_OPENED) = 0 then QuitRequest := true;
end;

end.
