unit m_pathes_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module;

type
  (** Module that manages data and config pathes *)

  TModulePathesClass = class(TBasicModule)
    protected
      fDataPath: String;
      fConfigPath: String;
      fPersonalDataPath: String;
      /// \ on win, / on unix and so on
      fDelimiter: Char;
    public
      /// Path to pre-installed data
      property DataPath: String read fDataPath;
      /// Path to configuration
      property ConfigPath: String read fConfigPath;
      /// Path to personal data
      property PersonalDataPath: String read fPersonalDataPath;
      /// Delimiter
      property Delimiter: Char read fDelimiter;

      (** Init pathes
        *@return true on success, false otherwise
        *)
      function InitPathes: Boolean; virtual abstract;

      (** Converts a standard unix path to a path that works on the own operating system
        *@param The source path
        *@return The new path
        *)
      function Convert(Path: String): String;

      (** Converts a path that works on the own operating system to a unix path
        *@param The source path
        *@return The new path
        *)
      function ConvertToUnix(Path: String): String;
    end;

implementation

function TModulePathesClass.Convert(Path: String): String;
var
  i: integer;
begin
  for i := 1 to length(Path) do
    if Path[i] = '/' then
      Path[i] := fDelimiter;
  result := Path;
end;

function TModulePathesClass.ConvertToUnix(Path: String): String;
var
  i: integer;
begin
  for i := 1 to length(Path) do
    if Path[i] = fDelimiter then
      Path[i] := '/';
  result := Path;
end;

end.

