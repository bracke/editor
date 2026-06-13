with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Declarative_Regions is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Hash_Text (Text : String) return Natural is
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of Text loop
         H := (H * 16777619 + Character'Pos (C) + 1) mod Natural'Last;
      end loop;
      return H;
   end Hash_Text;

   procedure Mix (Model : in out Region_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 31) mod Natural'Last;
   end Mix;

   function Opens_Region
     (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      case Kind is
         when Editor.Ada_Syntax_Tree.Node_Compilation_Unit
            | Editor.Ada_Syntax_Tree.Node_Generic_Declaration
            | Editor.Ada_Syntax_Tree.Node_Package_Declaration
            | Editor.Ada_Syntax_Tree.Node_Package_Body
            | Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Abstract_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Null_Procedure_Declaration
            | Editor.Ada_Syntax_Tree.Node_Expression_Function_Declaration
            | Editor.Ada_Syntax_Tree.Node_Subprogram_Body
            | Editor.Ada_Syntax_Tree.Node_Task_Declaration
            | Editor.Ada_Syntax_Tree.Node_Task_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Single_Task_Declaration
            | Editor.Ada_Syntax_Tree.Node_Task_Body
            | Editor.Ada_Syntax_Tree.Node_Protected_Declaration
            | Editor.Ada_Syntax_Tree.Node_Protected_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Single_Protected_Declaration
            | Editor.Ada_Syntax_Tree.Node_Protected_Body
            | Editor.Ada_Syntax_Tree.Node_Entry_Body
            | Editor.Ada_Syntax_Tree.Node_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Private_Extension_Declaration
            | Editor.Ada_Syntax_Tree.Node_Declare_Block
            | Editor.Ada_Syntax_Tree.Node_Begin_Block =>
            return True;
         when others =>
            return False;
      end case;
   end Opens_Region;

   function To_Region_Kind
     (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Region_Kind
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      case Kind is
         when Editor.Ada_Syntax_Tree.Node_Compilation_Unit =>
            return Region_Compilation;
         when Editor.Ada_Syntax_Tree.Node_Generic_Declaration =>
            return Region_Generic_Formal_Part;
         when Editor.Ada_Syntax_Tree.Node_Package_Declaration =>
            return Region_Package_Spec;
         when Editor.Ada_Syntax_Tree.Node_Package_Body =>
            return Region_Package_Body;
         when Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Abstract_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Null_Procedure_Declaration
            | Editor.Ada_Syntax_Tree.Node_Expression_Function_Declaration =>
            return Region_Subprogram_Spec;
         when Editor.Ada_Syntax_Tree.Node_Subprogram_Body =>
            return Region_Subprogram_Body;
         when Editor.Ada_Syntax_Tree.Node_Task_Declaration
            | Editor.Ada_Syntax_Tree.Node_Task_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Single_Task_Declaration =>
            return Region_Task_Spec;
         when Editor.Ada_Syntax_Tree.Node_Task_Body =>
            return Region_Task_Body;
         when Editor.Ada_Syntax_Tree.Node_Protected_Declaration
            | Editor.Ada_Syntax_Tree.Node_Protected_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Single_Protected_Declaration =>
            return Region_Protected_Spec;
         when Editor.Ada_Syntax_Tree.Node_Protected_Body =>
            return Region_Protected_Body;
         when Editor.Ada_Syntax_Tree.Node_Entry_Body =>
            return Region_Entry_Body;
         when Editor.Ada_Syntax_Tree.Node_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Private_Extension_Declaration =>
            return Region_Record_Definition;
         when Editor.Ada_Syntax_Tree.Node_Declare_Block
            | Editor.Ada_Syntax_Tree.Node_Begin_Block =>
            return Region_Block;
         when others =>
            return Region_Unknown;
      end case;
   end To_Region_Kind;

   function Region_Depth
     (Model  : Region_Model;
      Parent : Region_Id) return Natural
   is
   begin
      if Parent = No_Region then
         return 0;
      end if;
      return Region (Model, Parent).Depth + 1;
   end Region_Depth;

   function Add_Region
     (Model  : in out Region_Model;
      Kind   : Region_Kind;
      Owner  : Editor.Ada_Syntax_Tree.Node_Info;
      Parent : Region_Id) return Region_Id
   is
      Id   : constant Region_Id := Region_Id (Natural (Model.Regions.Length) + 1);
      Info : Region_Info;
      Label_Text : constant String := To_String (Owner.Label);
   begin
      Info.Id := Id;
      Info.Kind := Kind;
      Info.Owner_Node := Owner.Id;
      Info.Parent := Parent;
      Info.Depth := Region_Depth (Model, Parent);
      Info.Start_Line := Owner.Source_Span.Start_Line;
      Info.End_Line := Owner.Source_Span.End_Line;
      Info.Label := Owner.Label;
      Info.Fingerprint :=
        (Region_Kind'Pos (Kind) * 1000003
         + Natural (Owner.Id) * 1009
         + Natural (Parent) * 97
         + Info.Start_Line * 53
         + Info.End_Line * 17
         + Info.Depth * 7
         + Hash_Text (Label_Text)) mod Natural'Last;
      Model.Regions.Append (Info);
      Mix (Model, Info.Fingerprint);
      return Id;
   end Add_Region;

   procedure Ensure_Node_Map_Length
     (Model : in out Region_Model;
      Count : Natural)
   is
   begin
      while Natural (Model.Node_Region.Length) < Count loop
         Model.Node_Region.Append (No_Region);
      end loop;
   end Ensure_Node_Map_Length;

   procedure Clear (Model : in out Region_Model) is
   begin
      Model.Regions.Clear;
      Model.Node_Region.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build (Tree : Editor.Ada_Syntax_Tree.Tree_Type) return Region_Model is
      Model : Region_Model;
   begin
      Clear (Model);
      Ensure_Node_Map_Length (Model, Editor.Ada_Syntax_Tree.Node_Count (Tree));

      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node          : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Parent_Region : Region_Id := No_Region;
            This_Region   : Region_Id := No_Region;
         begin
            if Node.Parent /= Editor.Ada_Syntax_Tree.No_Node
              and then Natural (Node.Parent) <= Natural (Model.Node_Region.Length)
            then
               Parent_Region := Model.Node_Region (Positive (Node.Parent));
            end if;

            if Opens_Region (Node.Kind) then
               This_Region :=
                 Add_Region (Model, To_Region_Kind (Node.Kind), Node, Parent_Region);
            else
               This_Region := Parent_Region;
            end if;

            Model.Node_Region.Replace_Element (Index, This_Region);
         end;
      end loop;

      Mix (Model, Editor.Ada_Syntax_Tree.Fingerprint (Tree));
      return Model;
   end Build;

   function Has_Regions (Model : Region_Model) return Boolean is
   begin
      return not Model.Regions.Is_Empty;
   end Has_Regions;

   function Region_Count (Model : Region_Model) return Natural is
   begin
      return Natural (Model.Regions.Length);
   end Region_Count;

   function Region_At (Model : Region_Model; Index : Positive) return Region_Info is
   begin
      if Index > Natural (Model.Regions.Length) then
         return (Id => No_Region, Kind => Region_Unknown,
                 Owner_Node => Editor.Ada_Syntax_Tree.No_Node,
                 Parent => No_Region, Depth => 0, Start_Line => 1,
                 End_Line => 1, Label => Null_Unbounded_String,
                 Fingerprint => 0);
      end if;
      return Model.Regions (Index);
   end Region_At;

   function Region (Model : Region_Model; Id : Region_Id) return Region_Info is
   begin
      if Id = No_Region or else Natural (Id) > Natural (Model.Regions.Length) then
         return (Id => No_Region, Kind => Region_Unknown,
                 Owner_Node => Editor.Ada_Syntax_Tree.No_Node,
                 Parent => No_Region, Depth => 0, Start_Line => 1,
                 End_Line => 1, Label => Null_Unbounded_String,
                 Fingerprint => 0);
      end if;
      return Model.Regions (Positive (Id));
   end Region;

   function Region_For_Node
     (Model : Region_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Region_Id
   is
   begin
      if Node = Editor.Ada_Syntax_Tree.No_Node
        or else Natural (Node) > Natural (Model.Node_Region.Length)
      then
         return No_Region;
      end if;
      return Model.Node_Region (Positive (Node));
   end Region_For_Node;

   function Has_Region_For_Node
     (Model : Region_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Boolean
   is
   begin
      return Region_For_Node (Model, Node) /= No_Region;
   end Has_Region_For_Node;

   function Direct_Child_Count
     (Model  : Region_Model;
      Parent : Region_Id) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Regions loop
         if Info.Parent = Parent then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Direct_Child_Count;

   function Direct_Child_At
     (Model  : Region_Model;
      Parent : Region_Id;
      Index  : Positive) return Region_Id
   is
      Count : Natural := 0;
   begin
      for Info of Model.Regions loop
         if Info.Parent = Parent then
            Count := Count + 1;
            if Count = Index then
               return Info.Id;
            end if;
         end if;
      end loop;
      return No_Region;
   end Direct_Child_At;

   function Fingerprint (Model : Region_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Declarative_Regions;
