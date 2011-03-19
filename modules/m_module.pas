unit m_module;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  /// Module configurarion
  TModConf = record
    Key, Value: String;
    end;

  AModConf = array of TModConf;

  /// Ancestor of every module
  TBasicModule = class
    protected
      fModName: String;
      fModType: String;

      (** Read configuration value
        *@param Key to read from
        *@return Value or empty string
        *)
      function GetConfVal(Key: String): String;

      (** Set configuration value
        *@param Key to affect
        *@param Value to assign
        *@return true on success, otherwise false
        *)
      function SetConfVal(Key, Value: String): Boolean;
      function SetConfVal(Key: String; Value: Integer): Boolean;
      function SetConfVal(Key: String; Value: Single): Boolean;
      function SetConfVal(Key: String; Value: Boolean): Boolean;
    public
      /// Set module name and type
      constructor create; virtual abstract;

      /// Name of this module, set in constructor
      property ModuleName: String read fModName;

      /// Type of this module
      property ModuleType: String read fModType;

      /// Configuration
      property Config[Key: String]: String read GetConfVal;

      (** Validate the configuration
        *@return True if it is valid, false otherwise
        *)
      procedure CheckModConf; virtual abstract;
    end;

implementation

uses
  m_varlist;

function TBasicModule.GetConfVal(Key: String): String;
begin
  result := '';
  if ModuleManager.ModModuleConfig <> nil then
    result := ModuleManager.ModModuleConfig.ReadOption(fModName, Key);
end;

function TBasicModule.SetConfVal(Key, Value: String): Boolean;
begin
  result := false;
  if ModuleManager.ModModuleConfig <> nil then
    result := ModuleManager.ModModuleConfig.SetOption(fModName, Key, Value);
end;

function TBasicModule.SetConfVal(Key: String; Value: Integer): Boolean;
begin
  SetConfVal(Key, IntToStr(Value));
end;

function TBasicModule.SetConfVal(Key: String; Value: Single): Boolean;
begin
  SetConfVal(Key, FloatToStr(Value));
end;

function TBasicModule.SetConfVal(Key: String; Value: Boolean): Boolean;
begin
  if Value then
    SetConfVal(Key, '1')
  else
    SetConfVal(Key, '0');
end;

end.

