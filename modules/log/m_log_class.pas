unit m_log_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module;

type
  TModuleLogClass = class(TBasicModule)
    public
      (** Add an error message and terminate the program
        *@param log message
        *@param File where the problem occured
        *@param Line in which the problem occured
        *)
      procedure AddError(s: String; sFile: String = ''; sLine: Integer = 0); virtual abstract;

      (** Add a warning
        *@param log message
        *@param File where the problem occured
        *@param Line in which the problem occured
        *)
      procedure AddWarning(s: String; sFile: String = ''; sLine: Integer = 0); virtual abstract;
    end;

implementation

end.

