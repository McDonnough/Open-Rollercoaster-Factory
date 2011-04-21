unit u_linkedlists;

interface

uses
  SysUtils, Classes;

type
  TLinkedList = class;

  TLinkedListItem = class
    private
      fNext, fPrevious: TLinkedListItem;
      fList: TLinkedList;
    public
      property List: TLinkedList read fList;
      property Next: TLinkedListItem read fNext;
      property Previous: TLinkedListItem read fPrevious;
      constructor Create;
      destructor Free;
    end;

  TLinkedList = class
    protected
      fFirst, fLast: TLinkedListItem;
      fCount: Integer;
    public
      property First: TLinkedListItem read fFirst;
      property Last: TLinkedListItem read fLast;
      property Count: Integer read fCount;
      procedure Append(Item: TLinkedListItem);
      procedure Prepend(Item: TLinkedListItem);
      procedure InsertBefore(Comparator, Item: TLinkedListItem);
      procedure InsertAfter(Comparator, Item: TLinkedListItem);
      procedure DetachItem(Item: TLinkedListItem);
      procedure FreeAllItems;
      procedure DetachAllItems;
      function IsEmpty: Boolean;
      constructor Create;
      destructor Free;
    end;

implementation

constructor TLinkedListItem.Create;
begin
  fNext := nil;
  fPrevious := nil;
  fList := nil;
end;

destructor TLinkedListItem.Free;
begin
  if fList <> nil then
    fList.DetachItem(self);
end;



procedure TLinkedList.Append(Item: TLinkedListItem);
begin
  Item.fList := self;
  if Last <> nil then
    InsertAfter(Last, Item)
  else
    begin
    Item.fPrevious := nil;
    Item.fNext := nil;
    fFirst := Item;
    fLast := Item;
    inc(fCount);
    end;
end;

procedure TLinkedList.Prepend(Item: TLinkedListItem);
begin
  Item.fList := self;
  if First <> nil then
    InsertBefore(First, Item)
  else
    begin
    Item.fPrevious := nil;
    Item.fNext := nil;
    fFirst := Item;
    fLast := Item;
    inc(fCount);
    end;
end;

procedure TLinkedList.InsertBefore(Comparator, Item: TLinkedListItem);
begin
  inc(fCount);
  Item.fList := self;
  Item.fNext := Comparator;
  Item.fPrevious := Comparator.Previous;
  if Item.Previous <> nil then
    Item.Previous.fNext := Item
  else
    fFirst := Item;
  Comparator.fPrevious := Item;
end;

procedure TLinkedList.InsertAfter(Comparator, Item: TLinkedListItem);
begin
  inc(fCount);
  Item.fList := self;
  Item.fNext := Comparator.Next;
  Item.fPrevious := Comparator;
  if Item.Next <> nil then
    Item.Next.fPrevious := Item
  else
    fLast := Item;
  Comparator.fNext := Item;
end;

procedure TLinkedList.DetachItem(Item: TLinkedListItem);
begin
  if Item.fList = self then
    begin
    dec(fCount);
    if Item.Previous <> nil then
      Item.Previous.fNext := Item.Next
    else
      fFirst := Item.Next;
    if Item.Next <> nil then
      Item.Next.fPrevious := Item.Previous
    else
      fLast := Item.Previous;
    Item.fList := nil;
    end;
end;

procedure TLinkedList.FreeAllItems;
begin
  while Last <> nil do
    Last.Free;
end;

procedure TLinkedList.DetachAllItems;
begin
  while Last <> nil do
    DetachItem(Last);
end;

function TLinkedList.IsEmpty: Boolean;
begin
  Result := First = nil;
end;

constructor TLinkedList.Create;
begin
  fLast := nil;
  fFirst := nil;
  fCount := 0;
end;

destructor TLinkedList.Free;
begin
  FreeAllItems;
end;

end.