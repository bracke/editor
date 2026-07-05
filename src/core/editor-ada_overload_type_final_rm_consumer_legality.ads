with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Access_Definition_AST_Repair_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Overload_Type_Edge_Precision_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Overload_Type_Final_RM_Consumer_Legality is

   --  Case 1189 compiler-grade overload/type final RM consumer legality.
   --
   --  This package closes another hard semantic gap in overload and type
   --  resolution.  It is deliberately not a diagnostic/projection layer: it
   --  consumes repaired access-definition AST evidence, overload/type edge
   --  precision evidence, and generic source/instance backmapping evidence
   --  before allowing Ada RM edge conclusions to remain confident across
   --  prefixed calls, access-to-subprogram matching, controlling-result
   --  dispatching, inherited/private-extension primitive hiding, universal
   --  fixed/root numeric ties, and nested generic replay contexts.

   package Access_AST renames Editor.Ada_Access_Definition_AST_Repair_Legality;
   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   package Edge renames Editor.Ada_Overload_Type_Edge_Precision_Legality;

   type Final_RM_Row_Id is new Natural;
   No_Final_RM_Row : constant Final_RM_Row_Id := 0;

   type Final_RM_Context_Kind is
     (Final_RM_Prefixed_Call_Primitive,
      Final_RM_Access_Subprogram_Profile,
      Final_RM_Access_Subprogram_Null_Exclusion,
      Final_RM_Access_Subprogram_Convention,
      Final_RM_Class_Wide_Controlling_Result,
      Final_RM_Inherited_Private_Extension_Primitive,
      Final_RM_Universal_Fixed_Root_Numeric_Mixed_Mode,
      Final_RM_Dispatching_Inherited_Operation,
      Final_RM_Generic_Formal_Subprogram_Instance,
      Final_RM_Nested_Generic_Prefixed_Call,
      Final_RM_Unknown);

   type Final_RM_Status is
     (Final_RM_Not_Checked,
      Final_RM_Legal_Prefixed_Call_Primitive_Selected,
      Final_RM_Legal_Access_Subprogram_Profile_Accepted,
      Final_RM_Legal_Access_Subprogram_Null_Exclusion_Accepted,
      Final_RM_Legal_Access_Subprogram_Convention_Accepted,
      Final_RM_Legal_Class_Wide_Controlling_Result_Accepted,
      Final_RM_Legal_Inherited_Private_Extension_Primitive_Selected,
      Final_RM_Legal_Universal_Fixed_Root_Numeric_Selected,
      Final_RM_Legal_Dispatching_Inherited_Operation_Selected,
      Final_RM_Legal_Generic_Formal_Subprogram_Instance_Accepted,
      Final_RM_Legal_Nested_Generic_Prefixed_Call_Accepted,
      Final_RM_Missing_Overload_Type_Edge,
      Final_RM_Overload_Type_Edge_Blocker,
      Final_RM_Overload_Type_Edge_Ambiguous,
      Final_RM_Missing_Access_Definition_AST,
      Final_RM_Access_Definition_AST_Blocker,
      Final_RM_Access_Subprogram_Null_Exclusion_Mismatch,
      Final_RM_Access_Subprogram_Convention_Mismatch,
      Final_RM_Access_Subprogram_Profile_Mismatch,
      Final_RM_Prefixed_Call_Primitive_Not_Visible,
      Final_RM_Prefixed_Call_Ambiguous,
      Final_RM_Class_Wide_Controlling_Result_Ambiguous,
      Final_RM_Inherited_Private_Extension_Hiding_Ambiguous,
      Final_RM_Universal_Fixed_Root_Numeric_Ambiguous,
      Final_RM_Dispatching_Inherited_Operation_Ambiguous,
      Final_RM_Missing_Generic_Backmap,
      Final_RM_Generic_Backmap_Blocker,
      Final_RM_Generic_Backmap_Overload_Blocker,
      Final_RM_Generic_Backmap_Mapping_Blocker,
      Final_RM_Generic_Backmap_Indeterminate,
      Final_RM_Cross_Unit_View_Barrier,
      Final_RM_Multiple_Blockers,
      Final_RM_Indeterminate);

   type Final_RM_Context_Info is record
      Id                         : Final_RM_Row_Id := No_Final_RM_Row;
      Kind                       : Final_RM_Context_Kind := Final_RM_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Designator                 : Ada.Strings.Unbounded.Unbounded_String;
      Prefix_Type_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Type_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Selected_Profile           : Ada.Strings.Unbounded.Unbounded_String;
      Edge_Row                   : Edge.Overload_Type_Edge_Row_Id := Edge.No_Overload_Type_Edge_Row;
      Edge_Status                : Edge.Overload_Type_Edge_Status := Edge.Overload_Type_Edge_Not_Checked;
      Access_AST_Row             : Access_AST.Access_Definition_AST_Repair_Row_Id := Access_AST.No_Access_Definition_AST_Repair_Row;
      Access_AST_Status          : Access_AST.Access_Definition_AST_Repair_Status := Access_AST.Access_Definition_AST_Not_Checked;
      Generic_Backmap_Row        : Backmap.Generic_Backmap_Row_Id := Backmap.No_Generic_Backmap_Row;
      Generic_Backmap_Status     : Backmap.Generic_Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      Candidate_Count            : Natural := 0;
      Selected_Candidate_Count   : Natural := 0;
      Primitive_Visible          : Boolean := True;
      Prefixed_Call_Ambiguous    : Boolean := False;
      Null_Exclusion_Matched     : Boolean := True;
      Convention_Matched         : Boolean := True;
      Profile_Matched            : Boolean := True;
      Class_Wide_Controlling_Count : Natural := 0;
      Inherited_Primitive_Hiding_Count : Natural := 0;
      Universal_Root_Tie_Count   : Natural := 0;
      Dispatching_Inherited_Tie_Count : Natural := 0;
      Cross_Unit_View_Barrier    : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Final_RM_Info is record
      Id                         : Final_RM_Row_Id := No_Final_RM_Row;
      Context                    : Final_RM_Row_Id := No_Final_RM_Row;
      Kind                       : Final_RM_Context_Kind := Final_RM_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                     : Final_RM_Status := Final_RM_Not_Checked;
      Designator                 : Ada.Strings.Unbounded.Unbounded_String;
      Prefix_Type_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Type_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Selected_Profile           : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Edge_Row                   : Edge.Overload_Type_Edge_Row_Id := Edge.No_Overload_Type_Edge_Row;
      Edge_Status                : Edge.Overload_Type_Edge_Status := Edge.Overload_Type_Edge_Not_Checked;
      Access_AST_Row             : Access_AST.Access_Definition_AST_Repair_Row_Id := Access_AST.No_Access_Definition_AST_Repair_Row;
      Access_AST_Status          : Access_AST.Access_Definition_AST_Repair_Status := Access_AST.Access_Definition_AST_Not_Checked;
      Generic_Backmap_Row        : Backmap.Generic_Backmap_Row_Id := Backmap.No_Generic_Backmap_Row;
      Generic_Backmap_Status     : Backmap.Generic_Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      Candidate_Count            : Natural := 0;
      Selected_Candidate_Count   : Natural := 0;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Final_RM_Context_Model is private;
   type Final_RM_Model is private;
   type Final_RM_Result_Set is private;

   procedure Clear (Model : in out Final_RM_Context_Model);
   procedure Add_Context
     (Model : in out Final_RM_Context_Model;
      Info  : Final_RM_Context_Info);

   function Context_Count (Model : Final_RM_Context_Model) return Natural;
   function Context_At
     (Model : Final_RM_Context_Model;
      Index : Positive) return Final_RM_Context_Info;
   function Fingerprint (Model : Final_RM_Context_Model) return Natural;

   function Build (Contexts : Final_RM_Context_Model) return Final_RM_Model;

   function Row_Count (Model : Final_RM_Model) return Natural;
   function Row_At
     (Model : Final_RM_Model;
      Index : Positive) return Final_RM_Info;
   function First_For_Node
     (Model : Final_RM_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_RM_Info;
   function Rows_For_Status
     (Model  : Final_RM_Model;
      Status : Final_RM_Status) return Final_RM_Result_Set;
   function Rows_For_Kind
     (Model : Final_RM_Model;
      Kind  : Final_RM_Context_Kind) return Final_RM_Result_Set;
   function Rows_For_Designator
     (Model      : Final_RM_Model;
      Designator : String) return Final_RM_Result_Set;

   function Result_Count (Results : Final_RM_Result_Set) return Natural;
   function Result_At
     (Results : Final_RM_Result_Set;
      Index   : Positive) return Final_RM_Info;

   function Count_Status
     (Model  : Final_RM_Model;
      Status : Final_RM_Status) return Natural;
   function Count_Kind
     (Model : Final_RM_Model;
      Kind  : Final_RM_Context_Kind) return Natural;

   function Legal_Count (Model : Final_RM_Model) return Natural;
   function Blocker_Count (Model : Final_RM_Model) return Natural;
   function Ambiguous_Count (Model : Final_RM_Model) return Natural;
   function Access_AST_Blocker_Count (Model : Final_RM_Model) return Natural;
   function Generic_Backmap_Blocker_Count (Model : Final_RM_Model) return Natural;
   function Cross_Unit_Barrier_Count (Model : Final_RM_Model) return Natural;
   function Indeterminate_Count (Model : Final_RM_Model) return Natural;
   function Fingerprint (Model : Final_RM_Model) return Natural;

   function Is_Legal (Status : Final_RM_Status) return Boolean;
   function Is_Ambiguous (Status : Final_RM_Status) return Boolean;
   function Has_Error (Info : Final_RM_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_RM_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_RM_Info);

   type Final_RM_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Final_RM_Result_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Final_RM_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Blocker_Total : Natural := 0;
      Ambiguous_Total : Natural := 0;
      Access_AST_Blocker_Total : Natural := 0;
      Generic_Backmap_Blocker_Total : Natural := 0;
      Cross_Unit_Barrier_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
