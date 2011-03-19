unit m_settings_class;

interface

uses
  SysUtils, Classes, m_module, m_gui_scrollbox_class;

type
  TConfigurationInterfaceBase = TScrollBox;

  TConfigurationInterface = class
    public
      Title: String;
      Content: TConfigurationInterfaceBase;
    end;

  TConfigurationInterfaceList = class
    protected
      fItems: Array of TConfigurationInterface;
      function GetItem(I: Integer): TConfigurationInterface;
      function ListLength: Integer;
    public
      property Count: Integer read ListLength;
      property Items[i: Integer]: TConfigurationInterface read GetItem;
      procedure Add(Title: String; Content: TConfigurationInterfaceBase);
    end;

  TModuleSettingsClass = class(TBasicModule)
    protected
      fInterfaces: TConfigurationInterfaceList;
      fCanBeDestroyed: Boolean;
    public
      property CanBeDestroyed: Boolean read fCanBeDestroyed;
    
      (**
        * Show general configuration interface
        *)
      procedure ShowConfigurationInterface; virtual abstract;

      (**
        * And hide it
        *)
      procedure HideConfigurationInterface; virtual abstract;
    end;

implementation

function TConfigurationInterfaceList.GetItem(I: Integer): TConfigurationInterface;
begin
  Result := fItems[I];
end;

function TConfigurationInterfaceList.ListLength: Integer;
begin
  Result := length(fItems);
end;

procedure TConfigurationInterfaceList.Add(Title: String; Content: TConfigurationInterfaceBase);
begin
  SetLength(fItems, length(fItems) + 1);
  fItems[high(fItems)] := TConfigurationInterface.Create;
  fItems[high(fItems)].Title := Title;
  fItems[high(fItems)].Content := Content;
end;


end.