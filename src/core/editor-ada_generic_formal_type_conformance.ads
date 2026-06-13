with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Generic_Formal_Type_Conformance is

   --  Compiler-grade generic formal-type conformance foundation.  This model
   --  projects already-staged generic contract actual matching through the
   --  declaration-derived type graph.  It records conservative, deterministic
   --  conformance metadata for formal derived, private, interface, and access
   --  type contracts without reparsing files, mutating buffers, or reaching
   --  into rendering/workspace state.

   type Formal_Type_Shape is
     (Formal_Type_Shape_Unknown,
      Formal_Type_Shape_Private,
      Formal_Type_Shape_Derived,
      Formal_Type_Shape_Interface,
      Formal_Type_Shape_Access,
      Formal_Type_Shape_Discrete,
      Formal_Type_Shape_Scalar,
      Formal_Type_Shape_Array,
      Formal_Type_Shape_Record);

   type Formal_Type_Conformance_Status is
     (Formal_Type_Conformance_Compatible,
      Formal_Type_Conformance_Derived_Compatible,
      Formal_Type_Conformance_Private_Compatible,
      Formal_Type_Conformance_Interface_Compatible,
      Formal_Type_Conformance_Access_Compatible,
      Formal_Type_Conformance_Actual_Missing,
      Formal_Type_Conformance_Actual_Unresolved,
      Formal_Type_Conformance_Category_Mismatch,
      Formal_Type_Conformance_Base_Mismatch,
      Formal_Type_Conformance_Private_View_Unknown,
      Formal_Type_Conformance_Access_Designated_Unknown,
      Formal_Type_Conformance_Unsupported);

   type Formal_Type_Conformance_Info is record
      Instance        : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Formal          : Editor.Ada_Generic_Contracts.Generic_Formal_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Formal;
      Instance_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Type     : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Actual_Type     : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Formal_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Shape    : Formal_Type_Shape := Formal_Type_Shape_Unknown;
      Status          : Formal_Type_Conformance_Status :=
        Formal_Type_Conformance_Unsupported;
      Start_Line      : Positive := 1;
      End_Line        : Positive := 1;
      Fingerprint     : Natural := 0;
   end record;

   type Formal_Type_Conformance_Model is private;

   procedure Clear (Model : in out Formal_Type_Conformance_Model);

   function Build
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Types     : Editor.Ada_Type_Graph.Type_Model)
      return Formal_Type_Conformance_Model;

   function Check_Count (Model : Formal_Type_Conformance_Model) return Natural;

   function Check_At
     (Model : Formal_Type_Conformance_Model;
      Index : Positive) return Formal_Type_Conformance_Info;

   function Compatible_Count (Model : Formal_Type_Conformance_Model) return Natural;
   function Mismatch_Count (Model : Formal_Type_Conformance_Model) return Natural;
   function Unresolved_Count (Model : Formal_Type_Conformance_Model) return Natural;
   function Private_Compatible_Count (Model : Formal_Type_Conformance_Model) return Natural;
   function Interface_Compatible_Count (Model : Formal_Type_Conformance_Model) return Natural;
   function Access_Compatible_Count (Model : Formal_Type_Conformance_Model) return Natural;
   function Derived_Compatible_Count (Model : Formal_Type_Conformance_Model) return Natural;
   function Fingerprint (Model : Formal_Type_Conformance_Model) return Natural;

private
   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Formal_Type_Conformance_Info);

   type Formal_Type_Conformance_Model is record
      Checks                    : Check_Vectors.Vector;
      Compatible_Total          : Natural := 0;
      Mismatch_Total            : Natural := 0;
      Unresolved_Total          : Natural := 0;
      Private_Compatible_Total  : Natural := 0;
      Interface_Compatible_Total : Natural := 0;
      Access_Compatible_Total   : Natural := 0;
      Derived_Compatible_Total  : Natural := 0;
      Result_Fingerprint        : Natural := 0;
   end record;

end Editor.Ada_Generic_Formal_Type_Conformance;
