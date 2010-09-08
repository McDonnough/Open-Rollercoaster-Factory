unit m_inputhandler_glfw;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_inputhandler_class, glfw;

type
  TModuleInputHandlerGLFW = class(TModuleInputHandlerClass)
    protected
      mouseWheelPosition: integer;
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
  fMouseButtons[MOUSE_LEFT] := glfwGetMouseButton(GLFW_MOUSE_BUTTON_LEFT) <> 0;
  fMouseButtons[MOUSE_MIDDLE] := glfwGetMouseButton(GLFW_MOUSE_BUTTON_MIDDLE) <> 0;
  fMouseButtons[MOUSE_RIGHT] := glfwGetMouseButton(GLFW_MOUSE_BUTTON_RIGHT) <> 0;
  
  fMouseButtons[MOUSE_WHEEL_UP] := false;
  fMouseButtons[MOUSE_WHEEL_DOWN] := false; 
  fMouseButtons[MOUSE_WHEEL_UP] := glfwGetMouseWheel > mouseWheelPosition;
  fMouseButtons[MOUSE_WHEEL_DOWN] := glfwGetMouseWheel < mouseWheelPosition;
  mouseWheelPosition := glfwGetMouseWheel;
  
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
  //Misc
  fKeys[K_PERIOD] := glfwGetKey(ord('.')) <> 0;
  fKeys[K_COMMA] := glfwGetKey(ord(',')) <> 0;
  fKeys[K_MINUS] := glfwGetKey(ord('-')) <> 0;
  fKeys[K_PLUS] := glfwGetKey(ord('+')) <> 0;
  fKeys[K_HASH] := glfwGetKey(ord('#')) <> 0;
  fKeys[K_CARET] := glfwGetKey(ord('^')) <> 0;
  fKeys[K_LESS] := glfwGetKey(ord('<')) <> 0;
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
  fKeys[K_SPACE] := glfwGetKey(GLFW_KEY_SPACE) <> 0;
  fKeys[K_UP] := glfwGetKey(GLFW_KEY_UP) <> 0;
  fKeys[K_DOWN] := glfwGetKey(GLFW_KEY_DOWN) <> 0;
  fKeys[K_RIGHT] := glfwGetKey(GLFW_KEY_RIGHT) <> 0;
  fKeys[K_LEFT] := glfwGetKey(GLFW_KEY_LEFT) <> 0;
  fKeys[K_RSHIFT] := glfwGetKey(GLFW_KEY_RSHIFT) <> 0;
  fKeys[K_LSHIFT] := glfwGetKey(GLFW_KEY_LSHIFT) <> 0;
  fKeys[K_SHIFT] := fKeys[K_LSHIFT] or fKeys[K_RSHIFT];
  fKeys[K_RCTRL] := glfwGetKey(GLFW_KEY_RCTRL) <> 0;
  fKeys[K_LCTRL] := glfwGetKey(GLFW_KEY_LCTRL) <> 0;
  fKeys[K_CTRL] := fKeys[K_RCTRL] or fKeys[K_LCTRL];
  fKeys[K_RALT] := glfwGetKey(GLFW_KEY_RALT) <> 0;
  fKeys[K_LALT] := glfwGetKey(GLFW_KEY_LALT) <> 0;
  fKeys[K_ALT] := fKeys[K_RALT] or fKeys[K_LALT];
  fKeys[K_TAB] := glfwGetKey(GLFW_KEY_TAB) <> 0;
  fKeys[K_RETURN] := glfwGetKey(GLFW_KEY_ENTER) <> 0;
  fKeys[K_BACKSPACE] := glfwGetKey(GLFW_KEY_BACKSPACE) <> 0;
  fKeys[K_INSERT] := glfwGetKey(GLFW_KEY_INSERT) <> 0;
  fKeys[K_DELETE] := glfwGetKey(GLFW_KEY_DEL) <> 0;
  fKeys[K_PAGEUP] := glfwGetKey(GLFW_KEY_PAGEUP) <> 0;
  fKeys[K_PAGEDOWN] := glfwGetKey(GLFW_KEY_PAGEDOWN) <> 0;
  fKeys[K_HOME] := glfwGetKey(GLFW_KEY_HOME) <> 0;
  fKeys[K_END] := glfwGetKey(GLFW_KEY_END) <> 0;
  //Keypad
  fKeys[K_KP0] := glfwGetKey(GLFW_KEY_KP_0) <> 0;
  fKeys[K_KP1] := glfwGetKey(GLFW_KEY_KP_1) <> 0;
  fKeys[K_KP2] := glfwGetKey(GLFW_KEY_KP_2) <> 0;
  fKeys[K_KP3] := glfwGetKey(GLFW_KEY_KP_3) <> 0;
  fKeys[K_KP4] := glfwGetKey(GLFW_KEY_KP_4) <> 0;
  fKeys[K_KP5] := glfwGetKey(GLFW_KEY_KP_5) <> 0;
  fKeys[K_KP6] := glfwGetKey(GLFW_KEY_KP_6) <> 0;
  fKeys[K_KP7] := glfwGetKey(GLFW_KEY_KP_7) <> 0;
  fKeys[K_KP8] := glfwGetKey(GLFW_KEY_KP_8) <> 0;
  fKeys[K_KP9] := glfwGetKey(GLFW_KEY_KP_9) <> 0;
  fKeys[K_KP_DIVIDE] := glfwGetKey(GLFW_KEY_KP_DIVIDE) <> 0;
  fKeys[K_KP_MULTIPLY] := glfwGetKey(GLFW_KEY_KP_MULTIPLY) <> 0;
  fKeys[K_KP_MINUS] := glfwGetKey(GLFW_KEY_KP_SUBTRACT) <> 0;
  fKeys[K_KP_PLUS] := glfwGetKey(GLFW_KEY_KP_ADD) <> 0;
  fKeys[K_KP_ENTER] := glfwGetKey(GLFW_KEY_KP_ENTER) <> 0;
  fKeys[K_KP_EQUALS] := glfwGetKey(GLFW_KEY_KP_EQUAL) <> 0;
  fKeys[K_KP_PERIOD] := glfwGetKey(GLFW_KEY_KP_DECIMAL) <> 0;
  if glfwGetWindowParam(GLFW_OPENED) = 0 then QuitRequest := true;
end;

end.
