unit g_sets;

interface

uses
  SysUtils, Classes, u_linkedlists, u_functions, m_texmng_class, u_scene,
  g_res_objects, g_resources, u_events;

type
  TGameObjectList = class;
  TGameObject = class;

  TGameSet = class
    protected
      fObjects: TGameObjectList;
    public
      function List: TGameObjectList; // Duplicate the object list
      procedure Add(O: TGameObject);  // Add the object to get a sorted list
      constructor Create;
      destructor Free;
    end;

  TGameObject = class
    private
      fTags: Array of String;
      fSet: TGameSet;
      fName: String;
      fDescription: String;
      fResourceName: String;
      fResource: TObjectResource;
    public
      property GameSet: TGameSet read fSet;
      property Name: String read fName;
      property Description: String read fDescription;
      property Resource: TObjectResource read fResource;
      function ListTags: AString;
      function HasTag(Tag: String): Boolean;
      procedure Load(Callback: TEventCallback);
      constructor Create(TheSet: TGameSet; FileName, OName: String);
    end;

  TGameObjectItem = class(TLinkedListItem)
    protected
      fGameObject: TGameObject;
    public
      property GameObject: TGameObject read fGameObject;
      constructor Create(O: TGameObject);
    end;

  TGameSetItem = class(TLinkedListItem)
    protected
      fGameSet: TGameSet;
    public
      property GameSet: TGameSet read fGameSet;
      constructor Create(S: TGameSet);
    end;

  TGameObjectList = class(TLinkedList)
    public
      function Duplicate: TGameObjectList;
      procedure Filter(F: String);
    end;

  TGameObjectManager = class
    protected
      fSets: TLinkedList;
    public
      procedure LoadSet(FileName: String); // Add a set to the list sorted by nams
      function GetObjectsByTags(Tags: AString): TGameObjectList;
      constructor Create;
      destructor Free;
    end;

implementation

function TGameSet.List: TGameObjectList;
begin
  Result := fObjects.Duplicate;
end;

procedure TGameSet.Add(O: TGameObject);
begin
end;

constructor TGameSet.Create;
begin
  fObjects := TGameObjectList.Create;
end;

destructor TGameSet.Free;
begin
  fObjects.Free;
end;




function TGameObject.ListTags: AString;
begin
  Result := fTags;
end;

function TGameObject.HasTag(Tag: String): Boolean;
var
  i: Integer;
begin
  for i := 0 to high(fTags) do
    if fTags[i] = Tag then
      exit(True);

  Result := false;
end;

procedure TGameObject.Load(Callback: TEventCallback);
begin
  EventManager.AddCallback('TResource.FinishedLoading:' + fResourceName, Callback);
  fResource := TObjectResource.Get(fResourceName);
end;

constructor TGameObject.Create(TheSet: TGameSet; FileName, OName: String);
begin
  fSet := TheSet;
  fName := OName;

  fSet.Add(Self);

  fResource := nil;
  fResourceName := FileName + '/object';
end;



constructor TGameObjectItem.Create(O: TGameObject);
begin
  inherited Create;

  fGameObject := O;
end;



constructor TGameSetItem.Create(S: TGameSet);
begin
  fGameSet := S;
end;



procedure TGameObjectList.Filter(F: String);
begin
end;

function TGameObjectList.Duplicate: TGameObjectList;
begin
  Result := TGameObjectList.Create;
end;



procedure TGameObjectManager.LoadSet(FileName: String);
begin
end;

function TGameObjectManager.GetObjectsByTags(Tags: AString): TGameObjectList;
begin
  Result := TGameObjectList.Create;
end;

constructor TGameObjectManager.Create;
begin
  fSets := TLinkedList.Create;
end;

destructor TGameObjectManager.Free;
begin
  fSets.Free;
end;


end.