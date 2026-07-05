with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Precision_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
with Editor.Ada_Overload_Preference_Legality;
with Editor.Ada_Predicate_Invariant_Propagation_Legality;
with Editor.Ada_Representation_Freezing_Precision_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_Generic_Instance_Body_Semantic_Replay is

   --  Case 1140 compiler-grade generic instance body semantic replay layer.
   --
   --  Case 1125 projects actual/formal substitutions into widened legality
   --  layers.  This package goes one step deeper: it records replay contexts for
   --  declarations, statements, expressions, calls, flow effects, predicate
   --  propagation, accessibility, and representation/freezing effects that occur
   --  inside an instantiated generic body after actual/formal substitution.  The
   --  resulting rows preserve both the generic source location and the instance
   --  location so diagnostics can be mapped without reparsing, compiler
   --  invocation, file IO, dirty-state mutation, or UI/projection side effects.

   package Expansion renames Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
   package Preference renames Editor.Ada_Overload_Preference_Legality;
   package Access_Precision renames Editor.Ada_Accessibility_Precision_Legality;
   package Flow_Graph renames Editor.Ada_Flow_Effect_Graph_Legality;
   package Predicate_Propagation renames Editor.Ada_Predicate_Invariant_Propagation_Legality;
   package Representation_Freezing renames Editor.Ada_Representation_Freezing_Precision_Legality;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   type Replay_Context_Id is new Natural;
   No_Replay_Context : constant Replay_Context_Id := 0;

   type Replay_Row_Id is new Natural;
   No_Replay_Row : constant Replay_Row_Id := 0;

   type Replay_Context_Kind is
     (Replay_Context_Formal_Substitution,
      Replay_Context_Body_Declaration,
      Replay_Context_Body_Statement,
      Replay_Context_Body_Expression,
      Replay_Context_Call,
      Replay_Context_Assignment,
      Replay_Context_Return,
      Replay_Context_Flow_Effect,
      Replay_Context_Predicate_Invariant,
      Replay_Context_Accessibility,
      Replay_Context_Representation_Freezing,
      Replay_Context_Generic_Nested_Instance,
      Replay_Context_Unknown);

   type Replay_Status is
     (Replay_Not_Checked,
      Replay_Legal_Substituted_Declaration,
      Replay_Legal_Substituted_Statement,
      Replay_Legal_Substituted_Expression,
      Replay_Legal_Call,
      Replay_Legal_Flow_Effect,
      Replay_Legal_Predicate_Invariant,
      Replay_Legal_Accessibility,
      Replay_Legal_Representation_Freezing,
      Replay_Legal_Nested_Instance,
      Replay_Generic_Expansion_Error,
      Replay_Overload_Preference_Error,
      Replay_Flow_Effect_Error,
      Replay_Predicate_Propagation_Error,
      Replay_Accessibility_Precision_Error,
      Replay_Representation_Freezing_Error,
      Replay_Coverage_Gate_Blocker,
      Replay_Source_Instance_Mapping_Missing,
      Replay_Formal_Actual_Mapping_Missing,
      Replay_Diagnostic_Backmap_Missing,
      Replay_Multiple_Blockers,
      Replay_Indeterminate);

   type Replay_Context_Info is record
      Id                    : Replay_Context_Id := No_Replay_Context;
      Kind                  : Replay_Context_Kind := Replay_Context_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Source_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Actual_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Expansion_Status      : Expansion.Generic_Body_Expansion_Status :=
        Expansion.Generic_Body_Expansion_Not_Checked;
      Overload_Status       : Preference.Preference_Legality_Status :=
        Preference.Preference_Legality_Not_Checked;
      Flow_Status           : Flow_Graph.Flow_Effect_Graph_Status :=
        Flow_Graph.Flow_Graph_Not_Checked;
      Predicate_Status      : Predicate_Propagation.Propagation_Status :=
        Predicate_Propagation.Propagation_Not_Checked;
      Accessibility_Status  : Access_Precision.Accessibility_Precision_Status :=
        Access_Precision.Accessibility_Precision_Not_Checked;
      Representation_Status : Representation_Freezing.Representation_Freezing_Precision_Status :=
        Representation_Freezing.Representation_Freezing_Precision_Not_Checked;
      Gate_Status           : Gates.Enforcement_Status := Gates.Enforcement_Not_Checked;
      Source_Mapping_Present : Boolean := True;
      Formal_Actual_Mapping_Present : Boolean := True;
      Diagnostic_Backmap_Present : Boolean := True;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Generic_Start_Line    : Positive := 1;
      Generic_Start_Column  : Positive := 1;
      Instance_Start_Line   : Positive := 1;
      Instance_Start_Column : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
   end record;

   type Replay_Info is record
      Id                    : Replay_Row_Id := No_Replay_Row;
      Context               : Replay_Context_Id := No_Replay_Context;
      Kind                  : Replay_Context_Kind := Replay_Context_Unknown;
      Status                : Replay_Status := Replay_Not_Checked;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Source_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Actual_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Count         : Natural := 0;
      Expansion_Status      : Expansion.Generic_Body_Expansion_Status :=
        Expansion.Generic_Body_Expansion_Not_Checked;
      Overload_Status       : Preference.Preference_Legality_Status :=
        Preference.Preference_Legality_Not_Checked;
      Flow_Status           : Flow_Graph.Flow_Effect_Graph_Status :=
        Flow_Graph.Flow_Graph_Not_Checked;
      Predicate_Status      : Predicate_Propagation.Propagation_Status :=
        Predicate_Propagation.Propagation_Not_Checked;
      Accessibility_Status  : Access_Precision.Accessibility_Precision_Status :=
        Access_Precision.Accessibility_Precision_Not_Checked;
      Representation_Status : Representation_Freezing.Representation_Freezing_Precision_Status :=
        Representation_Freezing.Representation_Freezing_Precision_Not_Checked;
      Gate_Status           : Gates.Enforcement_Status := Gates.Enforcement_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Generic_Start_Line    : Positive := 1;
      Generic_Start_Column  : Positive := 1;
      Instance_Start_Line   : Positive := 1;
      Instance_Start_Column : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Replay_Context_Model is private;
   type Replay_Result_Set is private;
   type Replay_Model is private;

   procedure Clear (Model : in out Replay_Context_Model);
   procedure Add_Context
     (Model : in out Replay_Context_Model;
      Info  : Replay_Context_Info);

   procedure Add_From_Expansion_Row
     (Model : in out Replay_Context_Model;
      Row   : Expansion.Generic_Body_Expansion_Info);

   function Context_Count (Model : Replay_Context_Model) return Natural;
   function Context_At
     (Model : Replay_Context_Model;
      Index : Positive) return Replay_Context_Info;
   function Fingerprint (Model : Replay_Context_Model) return Natural;

   function Build (Contexts : Replay_Context_Model) return Replay_Model;
   function Build_From_Expansion
     (Expansion_Model : Expansion.Generic_Body_Expansion_Model) return Replay_Model;

   function Row_Count (Model : Replay_Model) return Natural;
   function Row_At
     (Model : Replay_Model;
      Index : Positive) return Replay_Info;
   function First_For_Node
     (Model : Replay_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Replay_Info;
   function Rows_For_Status
     (Model  : Replay_Model;
      Status : Replay_Status) return Replay_Result_Set;
   function Rows_For_Kind
     (Model : Replay_Model;
      Kind  : Replay_Context_Kind) return Replay_Result_Set;
   function Rows_For_Instance
     (Model : Replay_Model;
      Name  : String) return Replay_Result_Set;
   function Result_Count (Results : Replay_Result_Set) return Natural;
   function Result_At
     (Results : Replay_Result_Set;
      Index   : Positive) return Replay_Info;

   function Count_Status
     (Model  : Replay_Model;
      Status : Replay_Status) return Natural;
   function Legal_Count (Model : Replay_Model) return Natural;
   function Error_Count (Model : Replay_Model) return Natural;
   function Mapping_Error_Count (Model : Replay_Model) return Natural;
   function Expansion_Error_Count (Model : Replay_Model) return Natural;
   function Overload_Error_Count (Model : Replay_Model) return Natural;
   function Flow_Error_Count (Model : Replay_Model) return Natural;
   function Predicate_Error_Count (Model : Replay_Model) return Natural;
   function Accessibility_Error_Count (Model : Replay_Model) return Natural;
   function Representation_Error_Count (Model : Replay_Model) return Natural;
   function Coverage_Gate_Error_Count (Model : Replay_Model) return Natural;
   function Multiple_Blocker_Count (Model : Replay_Model) return Natural;
   function Fingerprint (Model : Replay_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Replay_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Replay_Info);

   type Replay_Context_Model is record
      Entries           : Context_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

   type Replay_Result_Set is record
      Entries : Row_Vectors.Vector;
   end record;

   type Replay_Model is record
      Rows                       : Row_Vectors.Vector;
      Legal_Total                : Natural := 0;
      Error_Total                : Natural := 0;
      Mapping_Error_Total        : Natural := 0;
      Expansion_Error_Total      : Natural := 0;
      Overload_Error_Total       : Natural := 0;
      Flow_Error_Total           : Natural := 0;
      Predicate_Error_Total      : Natural := 0;
      Accessibility_Error_Total  : Natural := 0;
      Representation_Error_Total : Natural := 0;
      Coverage_Gate_Error_Total  : Natural := 0;
      Multiple_Blocker_Total     : Natural := 0;
      Model_Fingerprint          : Natural := 0;
   end record;

end Editor.Ada_Generic_Instance_Body_Semantic_Replay;
