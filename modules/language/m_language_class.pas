unit m_language_class;

interface

uses
  SysUtils, Classes, m_module;

type
  TModuleLanguageClass = class(TBasicModule)
    public
      (**
        * Set language name
        *@param The language name
        *@return True on success, otherwise false
        *)

      function ChangeLanguage(Language: String): Boolean; virtual abstract;

      (**
        * Get name of current language
        *@return the name.
        *)
      function GetLanguage: String; virtual abstract;

      (**
        * Translate a string
        *@param String in English
        *@return String in configured language
        *)
      function Translate(Source: String): String; virtual abstract;
    end;

implementation



end.