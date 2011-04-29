unit m_scriptmng_class;

interface

uses
  SysUtils, Classes, u_scripts, m_module;

type
  TModuleScriptManagerClass = class(TBasicModule)
    public
      (**
        * Send a variable to script that can only be read.
        * Ideally, a script manager copies its content to another location
        * to prevent any unwanted overwriting.
        *@param The script instance to pass the variable to.
        *@param Name of the variable.
        *@param Pointer to the variable's contents
        *)
      procedure SetInVar(Script: TScript; Name: String; Location: Pointer); virtual abstract;

      (**
        * Send a variable to script that can only be read and written to.
        *@param The script instance to pass the variable to.
        *@param Name of the variable.
        *@param Pointer to the variable's contents
        *)
      procedure SetInOutVar(Script: TScript; Name: String; Location: Pointer); virtual abstract;

      (**
        * Execute the main function of the script.
        *@param Script instance to execute
        *)
      procedure Execute(Script: TScript); virtual abstract;

      (**
        * Add a script.
        *@param The script
        *)
      procedure AddScript(Script: TScript); virtual abstract;

      (**
        * Destroy a script
        *@param The script
        *)
      procedure DestroyScript(Script: TScript); virtual abstract;

      (**
        * Destroy compiled code handle
        *@param The script
        *)
      procedure DestroyCode(Code: TScriptCode); virtual abstract;
    end;

implementation

end.