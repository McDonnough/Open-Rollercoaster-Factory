unit m_inputhandler_sdl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_inputhandler_class, SDL;

type
  TModuleInputHandlerSDL = class(TModuleInputHandlerClass)
    public
      constructor Create;
      procedure CheckModConf;
      procedure UpdateData;
    end;

implementation

uses
  m_varlist;

constructor TModuleInputHandlerSDL.Create;
begin
  fModName := 'InputHandlerSDL';
  fModType := 'InputHandler';
end;

procedure TModuleInputHandlerSDL.CheckModConf;
begin
end;

procedure TModuleInputHandlerSDL.UpdateData;
var
  Event: TSDL_Event;
begin
  SDL_GetMouseState(fMouseX, fMouseY);
  QuitRequest := false;

  while SDL_PollEvent(@event) = 1 do
    case event.type_ of
      SDL_QUITEV:
        QuitRequest := true;

      SDL_MOUSEBUTTONDOWN:
        fMouseButtons[Event.Button.Button] := true;

      SDL_MOUSEBUTTONUP:
        fMouseButtons[Event.Button.Button] := false;

      SDL_KEYDOWN:
        fKeys[Event.Key.Keysym.Sym] := true;

      SDL_KEYUP:
        fKeys[Event.Key.Keysym.Sym] := false;
      end;
end;

end.

