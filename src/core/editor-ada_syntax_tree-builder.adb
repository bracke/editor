with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Syntax_Tree.Builder is

   function Hash_Text (Text : String) return Natural is
      type Hash_Value is mod 2 ** 64;
      H : Hash_Value := 2166136261;
   begin
      for C of Text loop
         H := H * 16777619 + Hash_Value (Character'Pos (C) + 1);
      end loop;
      return Natural (H mod Hash_Value (Natural'Last));
   end Hash_Text;

   procedure Mix (Tree : in out Tree_Type; Value : Natural) is
      type Hash_Value is mod 2 ** 64;
      Mixed : constant Hash_Value :=
        Hash_Value (Tree.Result_Fingerprint) * 65599 + Hash_Value (Value) + 17;
   begin
      Tree.Result_Fingerprint := Natural (Mixed mod Hash_Value (Natural'Last));
   end Mix;

   procedure Clear (Tree : in out Tree_Type) is
   begin
      Tree.Nodes.Clear;
      Tree.Root_Node := No_Node;
      Tree.Result_Fingerprint := 0;
   end Clear;

   function Add_Node
     (Tree        : in out Tree_Type;
      Kind        : Node_Kind;
      Source_Span : Source_Range;
      Parent      : Node_Id := No_Node;
      Depth       : Natural := 0;
      Label       : String := "") return Node_Id
   is
      Id   : constant Node_Id := Node_Id (Natural (Tree.Nodes.Length) + 1);
      Info : Node_Info;
   begin
      Info.Id := Id;
      Info.Kind := Kind;
      Info.Source_Span := Source_Span;
      Info.Parent := Parent;
      Info.Depth := Depth;
      Info.Label := To_Unbounded_String (Label);
      declare
         type Hash_Value is mod 2 ** 64;
         Fingerprint : constant Hash_Value :=
           Hash_Value (Node_Kind'Pos (Kind)) * 1000003
           + Hash_Value (Source_Span.Start_Line) * 1009
           + Hash_Value (Source_Span.Start_Column) * 97
           + Hash_Value (Source_Span.End_Line) * 53
           + Hash_Value (Source_Span.End_Column) * 17
           + Hash_Value (Natural (Parent)) * 13
           + Hash_Value (Depth) * 7
           + Hash_Value (Hash_Text (Label));
      begin
         Info.Fingerprint := Natural (Fingerprint mod Hash_Value (Natural'Last));
      end;
      Tree.Nodes.Append (Info);
      if Tree.Root_Node = No_Node then
         Tree.Root_Node := Id;
      end if;
      Mix (Tree, Info.Fingerprint);
      return Id;
   end Add_Node;

end Editor.Ada_Syntax_Tree.Builder;
