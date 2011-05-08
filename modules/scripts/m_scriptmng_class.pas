unit m_scriptmng_class;

interface

uses
  SysUtils, Classes, u_scripts, m_module;

type
  TModuleScriptManagerClass = class(TBasicModule)
    public
      (**
        * Get virtual memory location for a datablock
        *@param Number of bytes
        *@return Virtual location, module-dependent
        *)
      function GetLocation(Script: TScript; Bytes: Integer): PtrUInt; virtual abstract;

      (**
        * Get real memory address for a virtual location
        *@param Location
        *@return Pointer to first byte of datablock
        *)
      function GetRealPointer(Script: TScript; Location: PtrUInt): Pointer; virtual abstract;

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

      (**
        * Add an extern struct
        *@param Name of it
        *@param Fields in it
        *)
      procedure SetDataStructure(Name, Fields: String); virtual abstract;

      (**
        * Set the value of a global variable
        *@param Script to change the variable of
        *@param Name ot the variable
        *@param First byte of data
        *@param Length of data
        *)
      procedure SetGlobal(Script: TScript; Name: String; Data: PByte; Bytes: Integer); virtual abstract;
    end;

implementation

end.