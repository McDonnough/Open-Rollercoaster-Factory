unit m_mainmenu_class;

interface

uses
  m_module, SysUtils, Classes;

type
  TModuleMainMenuClass = class(TBasicModule)
    protected
      fValue: Integer;
    public
      property Value: Integer read fValue;
      procedure Render; virtual abstract;
      procedure Setup; virtual abstract;
      procedure NewFrame;
    end;

const
  MMVAL_STARTGAME = 1;
  MMVAL_LOADGAME = 2;
  MMVAL_SETTINGS = 3;
  MMVAL_HELP = 4;
  MMVAL_QUIT = 5;

implementation

procedure TModuleMainMenuClass.NewFrame;
begin
  fValue := 0;
end;

end.