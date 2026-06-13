with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Use_Visibility is

   --  Compiler-grade use-clause visibility foundation layered over direct
   --  declarative-region visibility.  This model records parser-owned use
   --  clauses without reading files, mutating editor state, or involving the
   --  renderer.  It deliberately stops before overload filtering and
   --  type-specific operator visibility legality; those later layers can reuse
   --  the stable clause, target-declaration, and target-region metadata here.

   type Use_Clause_Kind is
     (Use_Package_Clause,
      Use_Type_Clause,
      Use_All_Type_Clause);

   type Use_Clause_Id is new Natural;
   No_Use_Clause : constant Use_Clause_Id := 0;

   type Use_Clause_Info is record
      Id                 : Use_Clause_Id := No_Use_Clause;
      Kind               : Use_Clause_Kind := Use_Package_Clause;
      Name               : Ada.Strings.Unbounded.Unbounded_String;
      Normalized         : Ada.Strings.Unbounded.Unbounded_String;
      Node               : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Region             : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Target_Declaration : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Target_Region      : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Is_Resolved        : Boolean := False;
      Start_Line         : Positive := 1;
      End_Line           : Positive := 1;
      Fingerprint        : Natural := 0;
   end record;

   type Use_Visibility_Model is private;

   procedure Clear (Model : in out Use_Visibility_Model);

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
      return Use_Visibility_Model;

   function Has_Use_Clauses (Model : Use_Visibility_Model) return Boolean;
   function Use_Clause_Count (Model : Use_Visibility_Model) return Natural;
   function Use_Clause_At
     (Model : Use_Visibility_Model;
      Index : Positive) return Use_Clause_Info;
   function Use_Clause
     (Model : Use_Visibility_Model;
      Id    : Use_Clause_Id) return Use_Clause_Info;

   function Direct_Use_Clause_Count
     (Model  : Use_Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id) return Natural;

   function Direct_Use_Clause_At
     (Model  : Use_Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Index  : Positive) return Use_Clause_Id;

   function Lookup_Visible
     (Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Use_Visibility_Model;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String) return Editor.Ada_Direct_Visibility.Lookup_Result;

   function Fingerprint (Model : Use_Visibility_Model) return Natural;

private
   package Use_Clause_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Use_Clause_Info);

   type Use_Visibility_Model is record
      Clauses            : Use_Clause_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Use_Visibility;
