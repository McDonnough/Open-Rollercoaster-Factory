unit g_sets;

interface

uses
  SysUtils, Classes, u_linkedlists, u_functions, m_texmng_class, u_scene,
  g_res_objects, g_resources, u_events, g_loader_ocf, u_graphics, u_dom;

type
  TGameObjectList = class;
  TGameObject = class;

  TGameSet = class
    protected
      fObjects: TGameObjectList;
      fName, fDescription: String;
      fPreview: TTexture;
    public
      property Name: String read fName;
      property Description: String read fDescription;
      property Preview: TTexture read fPreview;
      property OrigList: TGameObjectList read fObjects;
      function List: TGameObjectList; // Duplicate the object list
      procedure Add(O: TGameObject);  // Add the object to get a sorted list
      constructor Create(O: TOCFFile);
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
      fPreview: TTexture;
    public
      property GameSet: TGameSet read fSet;
      property Name: String read fName;
      property Description: String read fDescription;
      property Resource: TObjectResource read fResource;
      property Preview: TTexture read fPreview;
      function ListTags: AString;
      function HasTag(Tag: String): Boolean;
      procedure Load(Callback: TEventCallback);
      constructor Create(TheSet: TGameSet; FileName, OName: String);
      destructor Free;
    end;

  TGameObjectItem = class(TLinkedListItem)
    protected
      fGameObject: TGameObject;
    public
      function Match(A: String): Boolean;
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

  TGameObjectManager = class(TThread)
    protected
      fSets: TLinkedList;
      fFiles: TStringList;
      fDone, fLoaded: Boolean;
      procedure Execute; override;
      procedure DoLoadSet(Event: String; Data, Result: Pointer);
    public
      property Files: TStringList read fFiles;
      property Done: Boolean read fDone;
      property Loaded: Boolean read fLoaded;
      property Sets: TLinkedList read fSets;
      procedure LoadSet(FileName: String); // Add a set to the list sorted by nams
      procedure LoadAll;
      function GetObjectsByTags(Tags: AString): TGameObjectList;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist;

function TGameSet.List: TGameObjectList;
begin
  Result := fObjects.Duplicate;
end;

procedure TGameSet.Add(O: TGameObject);
var
  A, B: TGameObjectItem;
begin
  A := TGameObjectItem.Create(O);
  if fObjects.Last = nil then
    fObjects.Append(A)
  else if StrCmp(O.Name, TGameObjectItem(fObjects.Last).GameObject.Name) >= 0 then
    fObjects.Append(A)
  else
    begin
    B := TGameObjectItem(fObjects.First);
    while B <> nil do
      begin
      if StrCmp(O.Name, B.GameObject.Name) >= 0 then
        fObjects.InsertBefore(B, A);
      B := TGameObjectItem(B.Next);
      end;
    end;
end;

constructor TGameSet.Create(O: TOCFFile);
var
  E, F, G: TDOMElement;
  fOName, fODescription, fOFile: String;
  fOTags: AString;
  fOPreview: Integer;
  fO: TGameObject;
begin
  fObjects := TGameObjectList.Create;
  fName := '';
  fDescription := '';
  fPreview := nil;

  E := TDOMElement(O.XML.Document.GetElementsByTagName('info')[0].FirstChild);
  while E <> nil do
    begin
    if E.TagName = 'name' then
      fName := E.FirstChild.NodeValue
    else if E.TagName = 'description' then
      fDescription := E.FirstChild.NodeValue
    else if E.TagName = 'preview' then
      begin
      fPreview := TTexture.Create;
      fPreview.FromTexImage(O.Preview);
      end;
      
    E := TDOMElement(E.NextSibling);
    end;

  E := TDOMElement(O.XML.Document.GetElementsByTagName('objects')[0].FirstChild);
  while E <> nil do
    if E.TagName = 'object' then
      begin
      fOName := '';
      fODescription := '';
      fOFile := '';
      fOPreview := 0;
      setLength(fOTags, 0);
      
      F := TDOMElement(E.FirstChild);
      while F <> nil do
        begin
        if F.TagName = 'name' then
          fOName := F.FirstChild.NodeValue
        else if F.TagName = 'description' then
          fODescription := F.FirstChild.NodeValue
        else if F.TagName = 'file' then
          fOFile := F.FirstChild.NodeValue
        else if F.TagName = 'preview' then
          fOPreview := StrToInt(F.GetAttribute('resource:id'))
        else if F.TagName = 'tags' then
          begin
          G := TDOMElement(F.FirstChild);

          while G <> nil do
            begin
            if G.TagName = 'tag' then
              begin
              setLength(fOTags, length(fOTags) + 1);
              fOTags[high(fOTags)] := G.FirstChild.NodeValue;
              end;
            G := TDOMElement(G.NextSibling);
            end;
          end;

        F := TDOMElement(F.NextSibling);
        end;
      if fOFile <> '' then
        begin
        fO := TGameObject.Create(Self, fOFile, fOName);
        fO.fDescription := fODescription;
        fO.fPreview := TTexture.Create;
        fO.fPreview.FromTexImage(TexFromStream(O.Bin[O.Resources[fOPreview].Section].Stream, '.' + O.Resources[fOPreview].Format));
        fO.fTags := fOTags;
        end;

      E := TDOMElement(E.NextSibling);
      end;
end;

destructor TGameSet.Free;
begin
  if fPreview <> nil then
    fPreview.Free;
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

  fPreview := nil;

  fResource := nil;
  fResourceName := FileName + '/object';

  fSet.Add(Self);
end;

destructor TGameObject.Free;
begin
  if fPreview <> nil then
    fPreview.Free;
end;

function TGameObjectItem.Match(A: String): Boolean;
var
  Words, NameWords: Array of String;
  i, j: Integer;
begin
  Words := Explode(' ', A);
  NameWords := Explode(' ', GameObject.Name);
  for i := 0 to high(Words) do
    for j := 0 to high(NameWords) do
      if Words[i] = NameWords[j] then
        exit(True);
  NameWords := Explode(' ', GameObject.GameSet.Name);
  for i := 0 to high(Words) do
    for j := 0 to high(NameWords) do
      if Words[i] = NameWords[j] then
        exit(True);
  Result := False;
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
var
  C, N: TGameObjectItem;
begin
  C := TGameObjectItem(First);
  while C <> nil do
    begin
    N := TGameObjectItem(C.Next);
    if C.Match(F) then
      C.Free;
    C := N;
    end;
end;

function TGameObjectList.Duplicate: TGameObjectList;
var
  C: TGameObjectItem;
begin
  Result := TGameObjectList.Create;

  C := TGameObjectItem(First);
  while C <> nil do
    begin
    Result.Append(TGameObjectItem.Create(C.GameObject));
    C := TGameObjectItem(C.Next);
    end;
end;


procedure TGameObjectManager.DoLoadSet(Event: String; Data, Result: Pointer);
var
  S: TGameSet;
  A, B: TGameSetItem;
begin
  S := TGameSet.Create(TOCFFile(Data));
  writeln('Adding set ' + S.Name);
  
  A := TGameSetItem.Create(S);

  if fSets.Last = nil then
    fSets.Append(A)
  else if StrCmp(S.Name, TGameSetItem(fSets.Last).GameSet.Name) >= 0 then
    fSets.Append(A)
  else
    begin
    B := TGameSetItem(fSets.First);
    while B <> nil do
      begin
      if StrCmp(S.Name, B.GameSet.Name) >= 0 then
        fSets.InsertBefore(B, A);
      B := TGameSetItem(B.Next);
      end;
    end;
end;

procedure TGameObjectManager.LoadSet(FileName: String);
begin
  ModuleManager.ModOCFManager.RequestOCFFile(FileName, 'TGameObjectManager.DoLoadSet', nil);
end;

function TGameObjectManager.GetObjectsByTags(Tags: AString): TGameObjectList;
begin
  Result := TGameObjectList.Create;
end;

procedure TGameObjectManager.Execute;
begin
  GetFilesInDirectory(ModuleManager.ModPathes.DataPath + 'scenery', '*.ocf', fFiles, false, true);
  GetFilesInDirectory(ModuleManager.ModPathes.PersonalDataPath + 'scenery', '*.ocf', fFiles, false, false);
  fDone := True;
end;

procedure TGameObjectManager.LoadAll;
var
  i: Integer;
begin
  for i := 0 to fFiles.Count - 1 do
    LoadSet(fFiles.Strings[i]);
  fLoaded := True;
end;

constructor TGameObjectManager.Create;
begin
  writeln('Hint: Creating GameObjectManager object');
  inherited Create(True);
  fDone := False;
  fLoaded := False;
  fSets := TLinkedList.Create;
  fFiles := TStringList.Create;

  EventManager.AddCallback('TGameObjectManager.DoLoadSet', @DoLoadSet);
end;

destructor TGameObjectManager.Free;
begin
  writeln('Hint: Deleting GameObjectManager object');

  EventManager.RemoveCallback(@DoLoadSet);
  
  fFiles.Free;
  fSets.Free;
end;


end.