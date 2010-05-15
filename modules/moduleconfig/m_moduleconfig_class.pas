unit m_moduleconfig_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module;

type
  (** Module that manages module configuration *)

  TModuleConfigClass = class(TBasicModule)
    public
      (** Set or overwrite an option for a module
        *@param The module
        *@param The key to set or overwrite
        *@param The value for this key
        *@return true on success, otherwise false
        *)
      function SetOption(ModName, KeyName, KeyValue: String): Boolean; virtual abstract;

      (** Read an option for a module
        *@param The module
        *@param The key to get the value from
        *@return The value on success, otherwise an empty string
        *)
      function ReadOption(ModName, KeyName: String): String; virtual abstract;
    end;

implementation

end.

