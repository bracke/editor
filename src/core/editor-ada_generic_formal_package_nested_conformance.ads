with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Formal_Package_Nested_Conformance is

   --  Compiler-grade formal-package nested actual conformance foundation.
   --  This model extends the shallow formal-package contract checks by
   --  comparing the nested actuals supplied by a formal package declaration
   --  against the actual package instance passed to an enclosing generic
   --  instantiation.  It is parser/snapshot owned and records conservative
   --  deterministic metadata without reparsing files or touching editor state.

   type Formal_Package_Nested_Status is
     (Formal_Package_Nested_Compatible,
      Formal_Package_Nested_Box_Compatible,
      Formal_Package_Nested_Actual_Mismatch,
      Formal_Package_Nested_Actual_Missing,
      Formal_Package_Nested_Wrong_Generic,
      Formal_Package_Nested_Actual_Unresolved,
      Formal_Package_Nested_Actual_Not_Instance,
      Formal_Package_Nested_Unknown,
      Formal_Package_Nested_Malformed);

   type Formal_Package_Nested_Info is record
      Instance        : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Formal          : Editor.Ada_Generic_Contracts.Generic_Formal_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Formal;
      Actual_Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Instance_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Actual_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Generic : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Actuals  : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Actuals  : Ada.Strings.Unbounded.Unbounded_String;
      Compared_Count  : Natural := 0;
      Box_Count       : Natural := 0;
      Mismatch_Count  : Natural := 0;
      Missing_Count   : Natural := 0;
      Status          : Formal_Package_Nested_Status :=
        Formal_Package_Nested_Unknown;
      Start_Line      : Positive := 1;
      End_Line        : Positive := 1;
      Fingerprint     : Natural := 0;
   end record;

   type Formal_Package_Nested_Model is private;

   procedure Clear (Model : in out Formal_Package_Nested_Model);

   function Build
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model)
      return Formal_Package_Nested_Model;

   function Check_Count (Model : Formal_Package_Nested_Model) return Natural;

   function Check_At
     (Model : Formal_Package_Nested_Model;
      Index : Positive) return Formal_Package_Nested_Info;

   function Compatible_Count (Model : Formal_Package_Nested_Model) return Natural;
   function Box_Compatible_Count (Model : Formal_Package_Nested_Model) return Natural;
   function Mismatch_Count (Model : Formal_Package_Nested_Model) return Natural;
   function Missing_Count (Model : Formal_Package_Nested_Model) return Natural;
   function Wrong_Generic_Count (Model : Formal_Package_Nested_Model) return Natural;
   function Unresolved_Count (Model : Formal_Package_Nested_Model) return Natural;
   function Unknown_Count (Model : Formal_Package_Nested_Model) return Natural;
   function Fingerprint (Model : Formal_Package_Nested_Model) return Natural;

private
   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Formal_Package_Nested_Info);

   type Formal_Package_Nested_Model is record
      Checks             : Check_Vectors.Vector;
      Compatible_Total   : Natural := 0;
      Box_Compatible_Total : Natural := 0;
      Mismatch_Total     : Natural := 0;
      Missing_Total      : Natural := 0;
      Wrong_Generic_Total : Natural := 0;
      Unresolved_Total   : Natural := 0;
      Unknown_Total      : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Formal_Package_Nested_Conformance;
