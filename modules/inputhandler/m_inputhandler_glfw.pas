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
  fMouseButtons[0] := glfwGetMouseButton(GLFW_MOUSE_BUTTON_LEFT) <> 0;
  if glfwGetWindowParam(GLFW_OPENED) = 0 then QuitRequest := true;
end;

end.
