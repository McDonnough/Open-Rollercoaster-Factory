unit m_loadscreen_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module;

type
  TModuleLoadScreenClass = class(TBasicModule)
    public
      Headline, Text: String;
      Progress: Integer;

      (**
        * Show or hide load screen
        *)
      procedure SetVisibility(Visible: Boolean); virtual abstract;

      (**
        * Render the screen
        *)
      procedure Render; virtual abstract;
    end;

implementation

end.

