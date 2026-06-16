with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Direct_Visibility is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Declarative_Regions.Region_Id;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trim (Text));
   end Normalize;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer;
      Modulus    : Long_Long_Integer := Long_Long_Integer (Natural'Last))
      return Natural
   is
   begin
      return Natural
        ((Long_Long_Integer (Seed) * Multiplier + Addend) mod Modulus);
   end Hash_Mix;

   function Hash_Text (Text : String) return Natural is
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of Text loop
         H := Hash_Mix
           (H, Long_Long_Integer (Character'Pos (C)) + 1, 16_777_619);
      end loop;
      return H;
   end Hash_Text;

   procedure Mix (Model : in out Visibility_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        Hash_Mix (Model.Result_Fingerprint, Long_Long_Integer (Value) + 43, 65_599);
   end Mix;

   function Is_Declarative_Node
     (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      case Kind is
         when Editor.Ada_Syntax_Tree.Node_Package_Declaration
            | Editor.Ada_Syntax_Tree.Node_Package_Body
            | Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Abstract_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Null_Procedure_Declaration
            | Editor.Ada_Syntax_Tree.Node_Expression_Function_Declaration
            | Editor.Ada_Syntax_Tree.Node_Subprogram_Body
            | Editor.Ada_Syntax_Tree.Node_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Subtype_Declaration
            | Editor.Ada_Syntax_Tree.Node_Object_Declaration
            | Editor.Ada_Syntax_Tree.Node_Constant_Declaration
            | Editor.Ada_Syntax_Tree.Node_Deferred_Constant_Declaration
            | Editor.Ada_Syntax_Tree.Node_Number_Declaration
            | Editor.Ada_Syntax_Tree.Node_Component_Declaration
            | Editor.Ada_Syntax_Tree.Node_Discriminant_Specification
            | Editor.Ada_Syntax_Tree.Node_Parameter_Specification
            | Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration
            | Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Formal_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Formal_Package_Declaration
            | Editor.Ada_Syntax_Tree.Node_Exception_Declaration
            | Editor.Ada_Syntax_Tree.Node_Generic_Declaration
            | Editor.Ada_Syntax_Tree.Node_Rename_Declaration
            | Editor.Ada_Syntax_Tree.Node_Instantiation
            | Editor.Ada_Syntax_Tree.Node_Task_Declaration
            | Editor.Ada_Syntax_Tree.Node_Task_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Single_Task_Declaration
            | Editor.Ada_Syntax_Tree.Node_Task_Body
            | Editor.Ada_Syntax_Tree.Node_Protected_Declaration
            | Editor.Ada_Syntax_Tree.Node_Protected_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Single_Protected_Declaration
            | Editor.Ada_Syntax_Tree.Node_Protected_Body
            | Editor.Ada_Syntax_Tree.Node_Entry_Declaration
            | Editor.Ada_Syntax_Tree.Node_Entry_Body
            | Editor.Ada_Syntax_Tree.Node_Entry_Body_Stub
            | Editor.Ada_Syntax_Tree.Node_Incomplete_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Private_Extension_Declaration
            | Editor.Ada_Syntax_Tree.Node_Body_Stub
            | Editor.Ada_Syntax_Tree.Node_Choice_Parameter_Specification
            | Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Declarative_Node;

   function To_Declaration_Kind
     (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Declaration_Kind
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      case Kind is
         when Editor.Ada_Syntax_Tree.Node_Package_Declaration
            | Editor.Ada_Syntax_Tree.Node_Package_Body =>
            return Declaration_Package;
         when Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Abstract_Subprogram_Declaration
            | Editor.Ada_Syntax_Tree.Node_Null_Procedure_Declaration
            | Editor.Ada_Syntax_Tree.Node_Expression_Function_Declaration
            | Editor.Ada_Syntax_Tree.Node_Subprogram_Body
            | Editor.Ada_Syntax_Tree.Node_Body_Stub =>
            return Declaration_Subprogram;
         when Editor.Ada_Syntax_Tree.Node_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Incomplete_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Private_Extension_Declaration
            | Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration =>
            return Declaration_Type;
         when Editor.Ada_Syntax_Tree.Node_Subtype_Declaration =>
            return Declaration_Subtype;
         when Editor.Ada_Syntax_Tree.Node_Object_Declaration
            | Editor.Ada_Syntax_Tree.Node_Constant_Declaration
            | Editor.Ada_Syntax_Tree.Node_Deferred_Constant_Declaration
            | Editor.Ada_Syntax_Tree.Node_Component_Declaration
            | Editor.Ada_Syntax_Tree.Node_Discriminant_Specification
            | Editor.Ada_Syntax_Tree.Node_Parameter_Specification
            | Editor.Ada_Syntax_Tree.Node_Choice_Parameter_Specification =>
            return Declaration_Object;
         when Editor.Ada_Syntax_Tree.Node_Number_Declaration =>
            return Declaration_Number;
         when Editor.Ada_Syntax_Tree.Node_Exception_Declaration =>
            return Declaration_Exception;
         when Editor.Ada_Syntax_Tree.Node_Generic_Declaration =>
            return Declaration_Generic;
         when Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration =>
            return Declaration_Formal_Type;
         when Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration =>
            return Declaration_Formal_Object;
         when Editor.Ada_Syntax_Tree.Node_Formal_Subprogram_Declaration =>
            return Declaration_Formal_Subprogram;
         when Editor.Ada_Syntax_Tree.Node_Formal_Package_Declaration =>
            return Declaration_Formal_Package;
         when Editor.Ada_Syntax_Tree.Node_Task_Declaration
            | Editor.Ada_Syntax_Tree.Node_Task_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Single_Task_Declaration
            | Editor.Ada_Syntax_Tree.Node_Task_Body =>
            return Declaration_Task;
         when Editor.Ada_Syntax_Tree.Node_Protected_Declaration
            | Editor.Ada_Syntax_Tree.Node_Protected_Type_Declaration
            | Editor.Ada_Syntax_Tree.Node_Single_Protected_Declaration
            | Editor.Ada_Syntax_Tree.Node_Protected_Body =>
            return Declaration_Protected;
         when Editor.Ada_Syntax_Tree.Node_Entry_Declaration
            | Editor.Ada_Syntax_Tree.Node_Entry_Body
            | Editor.Ada_Syntax_Tree.Node_Entry_Body_Stub =>
            return Declaration_Entry;
         when Editor.Ada_Syntax_Tree.Node_Rename_Declaration =>
            return Declaration_Renaming;
         when Editor.Ada_Syntax_Tree.Node_Instantiation =>
            return Declaration_Instantiation;
         when others =>
            return Declaration_Unknown;
      end case;
   end To_Declaration_Kind;

   function Declaration_Name
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Info) return String
   is
      use type Editor.Ada_Syntax_Tree.Node_Kind;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Declaration_Name then
               return Trim (To_String (Child.Label));
            end if;
         end;
      end loop;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration then
         return Trim (To_String (Node.Label));
      end if;

      return "";
   end Declaration_Name;

   function Owning_Region
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Node    : Editor.Ada_Syntax_Tree.Node_Info)
      return Editor.Ada_Declarative_Regions.Region_Id
   is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      Node_Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Node.Id);
      Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
        Editor.Ada_Declarative_Regions.Region (Regions, Node_Region);
   begin
      if Node_Region = Editor.Ada_Declarative_Regions.No_Region then
         return Editor.Ada_Declarative_Regions.No_Region;
      elsif Info.Owner_Node = Node.Id then
         --  The declaration itself opened a nested region.  Its defining name
         --  is directly declared in the immediately enclosing region.
         return Info.Parent;
      else
         return Node_Region;
      end if;
   end Owning_Region;

   procedure Add_Declaration
     (Model  : in out Visibility_Model;
      Kind   : Declaration_Kind;
      Name   : String;
      Node   : Editor.Ada_Syntax_Tree.Node_Info;
      Region : Editor.Ada_Declarative_Regions.Region_Id)
   is
      Id   : constant Declaration_Id :=
        Declaration_Id (Natural (Model.Declarations.Length) + 1);
      Norm : constant String := Normalize (Name);
      Info : Declaration_Info;
   begin
      if Trim (Name) = ""
        or else Region = Editor.Ada_Declarative_Regions.No_Region
      then
         return;
      end if;

      Info.Id := Id;
      Info.Kind := Kind;
      Info.Name := To_Unbounded_String (Trim (Name));
      Info.Normalized := To_Unbounded_String (Norm);
      Info.Node := Node.Id;
      Info.Region := Region;
      Info.Start_Line := Node.Source_Span.Start_Line;
      Info.End_Line := Node.Source_Span.End_Line;
      Info.Fingerprint :=
        (Declaration_Kind'Pos (Kind) * 1000003
         + Natural (Node.Id) * 1009
         + Natural (Region) * 97
         + Node.Source_Span.Start_Line * 53
         + Node.Source_Span.End_Line * 17
         + Hash_Text (Norm)) mod Natural'Last;
      Model.Declarations.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Declaration;

   procedure Clear (Model : in out Visibility_Model) is
   begin
      Model.Declarations.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model)
      return Visibility_Model
   is
      Model : Visibility_Model;
   begin
      Clear (Model);

      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Is_Declarative_Node (Node.Kind) then
               Add_Declaration
                 (Model,
                  To_Declaration_Kind (Node.Kind),
                  Declaration_Name (Tree, Node),
                  Node,
                  Owning_Region (Regions, Node));
            end if;
         end;
      end loop;

      Mix (Model, Editor.Ada_Syntax_Tree.Fingerprint (Tree));
      Mix (Model, Editor.Ada_Declarative_Regions.Fingerprint (Regions));
      return Model;
   end Build;

   function Has_Declarations (Model : Visibility_Model) return Boolean is
   begin
      return not Model.Declarations.Is_Empty;
   end Has_Declarations;

   function Declaration_Count (Model : Visibility_Model) return Natural is
   begin
      return Natural (Model.Declarations.Length);
   end Declaration_Count;

   function Empty_Declaration return Declaration_Info is
   begin
      return (Id => No_Declaration,
              Kind => Declaration_Unknown,
              Name => Null_Unbounded_String,
              Normalized => Null_Unbounded_String,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Declaration;

   function Declaration_At
     (Model : Visibility_Model;
      Index : Positive) return Declaration_Info
   is
   begin
      if Index > Natural (Model.Declarations.Length) then
         return Empty_Declaration;
      end if;
      return Model.Declarations (Index);
   end Declaration_At;

   function Declaration
     (Model : Visibility_Model;
      Id    : Declaration_Id) return Declaration_Info
   is
   begin
      if Id = No_Declaration
        or else Natural (Id) > Natural (Model.Declarations.Length)
      then
         return Empty_Declaration;
      end if;
      return Model.Declarations (Positive (Id));
   end Declaration;

   function Direct_Declaration_Count
     (Model  : Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Declarations loop
         if Info.Region = Region then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Direct_Declaration_Count;

   function Direct_Declaration_At
     (Model  : Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Index  : Positive) return Declaration_Id
   is
      Count : Natural := 0;
   begin
      for Info of Model.Declarations loop
         if Info.Region = Region then
            Count := Count + 1;
            if Count = Index then
               return Info.Id;
            end if;
         end if;
      end loop;
      return No_Declaration;
   end Direct_Declaration_At;

   function Lookup_Direct
     (Model  : Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Lookup_Result
   is
      Wanted : constant String := Normalize (Name);
      Result : Lookup_Result :=
        (Status => Lookup_Not_Found,
         Declaration => No_Declaration,
         Region => Region,
         Match_Count => 0);
   begin
      if Wanted = "" then
         return Result;
      end if;

      for Info of Model.Declarations loop
         if Info.Region = Region
           and then To_String (Info.Normalized) = Wanted
         then
            Result.Match_Count := Result.Match_Count + 1;
            if Result.Declaration = No_Declaration then
               Result.Declaration := Info.Id;
            end if;
         end if;
      end loop;

      if Result.Match_Count = 1 then
         Result.Status := Lookup_Found;
      elsif Result.Match_Count > 1 then
         Result.Status := Lookup_Ambiguous;
      end if;
      return Result;
   end Lookup_Direct;

   function Lookup_Visible
     (Model   : Visibility_Model;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Name    : String) return Lookup_Result
   is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      Current : Editor.Ada_Declarative_Regions.Region_Id := Region;
      Result  : Lookup_Result;
   begin
      while Current /= Editor.Ada_Declarative_Regions.No_Region loop
         Result := Lookup_Direct (Model, Current, Name);
         if Result.Status /= Lookup_Not_Found then
            Result.Region := Current;
            return Result;
         end if;
         Current := Editor.Ada_Declarative_Regions.Region (Regions, Current).Parent;
      end loop;

      return (Status => Lookup_Not_Found,
              Declaration => No_Declaration,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Match_Count => 0);
   end Lookup_Visible;

   function Fingerprint (Model : Visibility_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Direct_Visibility;
