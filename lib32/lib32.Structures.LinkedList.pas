unit lib32.Structures.LinkedList;

 interface

 uses
  // library
  lib32.Common, lib32.Func.Core;

 type

  TLinkedList<T> = class(TObject)

   public

    type

     ItemPointer = ^T;

     Node = class(TObject)

      private

       FPrev : Node; // prev node
       FNext : Node; // next node
       FData : T;    // item data

       function GetValuePointer:ItemPointer;
       function GetIsValid:Boolean;

      public

       constructor Create;

       property Prev:Node         read FPrev write FPrev;
       property Next:Node         read FNext write FNext;
       property Data:T            read FData write FData;
       property Value:ItemPointer read GetValuePointer;
       property IsValid:Boolean   read GetIsValid;

     end;

     InsMode = (After,Before);

   private

    FHead  : Node;   // address of first node in list
    FCount : UInt32;
    function GetLastNode: Node;
    function GetNodeByIndex(Index: UInt32): Node;
    function GetNodeByValue(Value: T): Node;
    function GetNodeIndex(N: Node): Int32; // list size

   public

    constructor Create; overload;
    constructor Create(const Source:array of T); overload;

    function Copy:TLinkedList<T>; overload;
    function Copy(const FromNode,ToNode:Node):TLinkedList<T>; overload;
    function Extract(const FromNode,ToNode:Node):TLinkedList<T>;

    function Append(const Arr:array of T):Int32; overload;
    function Append(const Lst:TLinkedList<T>):Int32; overload;
    function Insert(const Arr:array of T; const Mode:InsMode=After; const N:Node=Nil):Int32; overload;
    function Insert(const Lst:TLinkedList<T>; const Mode:InsMode=After; const N:Node=Nil):Int32; overload;
    function Remove(N:Node):Int32; overload;
    function Remove(const FromNode,ToNode:Node):Int32; overload;
//    procedure ForEach(const FromNode,ToNode:Node; const );

    function ToArray:TArray<T>; overload;
    function ToArray(const FromNode,ToNode:Node):TArray<T>; overload;

    property Count:UInt32               read FCount;
    property First:Node                 read FHead;
    property Last:Node                  read GetLastNode;
    property ByValue[Value:T]:Node      read GetNodeByValue;
    property ByIndex[Index:UInt32]:Node read GetNodeByIndex;
    property NodeIndex[N:Node]:Int32    read GetNodeIndex;

  end;

 implementation

  procedure test;
   type
    rec = record X,Y : int32; end;
   var
    lst : TLinkedList<rec>;
    r   : rec;
    n   : TLinkedList<rec>.Node;
    x,y : int32;
   begin
    n.Value^.X := 0;
    n.Value^.Y := 2;
    n.Value^   := r;
    n.Data     := r;
    x          := n.Data.X;
    //
    lst := TLinkedList<rec>.Create([r,r]);
    n := lst.First;
    repeat
     // do something ...
     n := n.Next;
    until n=lst.Last;
   end;

 // ************************************************************************* //
 //  TLinkedList<T>.Node                                                      //
 // ************************************************************************* //

 // ***************************************************************************
 function TLinkedList<T>.Node.GetValuePointer:ItemPointer;
  begin
   Result := @FData;
  end;

 // ***************************************************************************
 function TLinkedList<T>.Node.GetIsValid:Boolean;
  begin
   Result := (FPrev<>Nil) and (FNext<>Nil);
  end;

 // ***************************************************************************
 constructor TLinkedList<T>.Node.Create;
  begin
   inherited Create;
   FPrev := Nil;
   FNext := Nil;
   FData := Default(T);
  end;

//// ***************************************************************************
// function TLinkedList<T>.TCursor.GetItemIndex:Int32;
//  var i : UInt32;
//  begin
////   Result := -1;
////   if (FOwner.Count=0) or owner.FBuffer[adr].IsEmpty then Exit;
////   Result := 0;
////   i      := owner.FHead;
////   while i<>adr do
////    begin
////     Inc(Result);
////     i := owner.FBuffer[i].next;
////    end;
//  end;

 // ************************************************************************* //
 //  TLinkedList<T>                                                           //
 // ************************************************************************* //

{ TLinkedList<T> }

function TLinkedList<T>.Append(const Lst: TLinkedList<T>): Int32;
begin

end;

function TLinkedList<T>.Append(const Arr: array of T): Int32;
begin

end;

function TLinkedList<T>.Copy: TLinkedList<T>;
begin

end;

function TLinkedList<T>.Copy(const FromNode, ToNode: Node): TLinkedList<T>;
begin

end;

constructor TLinkedList<T>.Create;
begin

end;

constructor TLinkedList<T>.Create(const Source: array of T);
begin

end;

function TLinkedList<T>.Extract(const FromNode, ToNode: Node): TLinkedList<T>;
begin

end;

function TLinkedList<T>.GetLastNode: Node;
begin

end;

function TLinkedList<T>.GetNodeByIndex(Index: UInt32): Node;
begin

end;

function TLinkedList<T>.GetNodeByValue(Value: T): Node;
begin

end;

function TLinkedList<T>.GetNodeIndex(N: Node): Int32;
begin

end;

function TLinkedList<T>.Insert(const Lst: TLinkedList<T>; const Mode: InsMode;
  const N: Node): Int32;
begin

end;

function TLinkedList<T>.Insert(const Arr: array of T; const Mode: InsMode;
  const N: Node): Int32;
begin

end;

function TLinkedList<T>.Remove(const FromNode, ToNode: Node): Int32;
begin

end;

function TLinkedList<T>.Remove(N: Node): Int32;
begin

end;

function TLinkedList<T>.ToArray(const FromNode, ToNode: Node): TArray<T>;
begin

end;

function TLinkedList<T>.ToArray: TArray<T>;
begin

end;

end.
