with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
with Editor.Ada_Flow_Contract_Final_Proof_Legality;
with Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
with Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
with Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Deep_Edge_Legality;

package Editor.Ada_Final_Semantic_Diagnostic_Integration is

   --  Case 1194 compiler-grade final semantic diagnostic integration.
   --
   --  This layer converts the final semantic closure/consumer chain into
   --  diagnostic-ready rows while preserving the original blocker family.  It is
   --  intentionally not a UI projection/status layer: it consumes already-built
   --  semantic results from the final cross-unit, overload/type, generic replay,
   --  representation/freezing, flow/contract, tasking/protected, elaboration,
   --  accessibility, and discriminant/variant consumers and exposes only real
   --  semantic blockers, stale inputs, and indeterminate states.  The model is
   --  deterministic, bounded, snapshot-owned, and performs no parsing, file IO,
   --  dirty-state mutation, command/keybinding/workspace/render mutation, LSP
   --  use, compiler invocation, or external parser generation.

   package Access_Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   package Cross_Final renames Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
   package Discriminant_Final renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   package Elaboration_Final renames Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
   package Flow_Final renames Editor.Ada_Flow_Contract_Final_Proof_Legality;
   package Generic_Final renames Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
   package Overload_Final renames Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
   package Representation_Final renames Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
   package Tasking_Final renames Editor.Ada_Tasking_Protected_Deep_Edge_Legality;

   type Final_Diagnostic_Id is new Natural;
   No_Final_Diagnostic : constant Final_Diagnostic_Id := 0;

   type Final_Diagnostic_Source_Family is
     (Final_Diagnostic_Cross_Unit,
      Final_Diagnostic_Overload_Type,
      Final_Diagnostic_Generic_Replay,
      Final_Diagnostic_Representation_Freezing,
      Final_Diagnostic_Flow_Contract,
      Final_Diagnostic_Tasking_Protected,
      Final_Diagnostic_Elaboration,
      Final_Diagnostic_Accessibility_Lifetime,
      Final_Diagnostic_Discriminant_Variant,
      Final_Diagnostic_Multiple,
      Final_Diagnostic_Unknown);

   type Final_Diagnostic_Severity is
     (Final_Diagnostic_Severity_Info,
      Final_Diagnostic_Warning,
      Final_Diagnostic_Error);

   type Final_Diagnostic_Status is
     (Final_Diagnostic_Not_Checked,
      Final_Diagnostic_Withheld_Legal,
      Final_Diagnostic_Cross_Unit_Blocker,
      Final_Diagnostic_Overload_Type_Blocker,
      Final_Diagnostic_Generic_Replay_Blocker,
      Final_Diagnostic_Representation_Freezing_Blocker,
      Final_Diagnostic_Flow_Contract_Blocker,
      Final_Diagnostic_Tasking_Protected_Blocker,
      Final_Diagnostic_Elaboration_Blocker,
      Final_Diagnostic_Accessibility_Lifetime_Blocker,
      Final_Diagnostic_Discriminant_Variant_Blocker,
      Final_Diagnostic_AST_Repair_Blocker,
      Final_Diagnostic_Coverage_Gate_Blocker,
      Final_Diagnostic_View_Barrier,
      Final_Diagnostic_Stale_Input,
      Final_Diagnostic_Multiple_Blockers,
      Final_Diagnostic_Indeterminate);

   type Final_Diagnostic_Context_Info is record
      Id       : Final_Diagnostic_Id := No_Final_Diagnostic;
      Family   : Final_Diagnostic_Source_Family := Final_Diagnostic_Unknown;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Cross_Unit_Status : Cross_Final.Cross_Unit_Final_Status := Cross_Final.Cross_Unit_Final_Not_Checked;
      Overload_Status : Overload_Final.Final_RM_Status := Overload_Final.Final_RM_Not_Checked;
      Generic_Status : Generic_Final.Nested_Generic_Closure_Status := Generic_Final.Nested_Generic_Not_Checked;
      Representation_Status : Representation_Final.Final_Representation_Status := Representation_Final.Final_Representation_Not_Checked;
      Flow_Status : Flow_Final.Flow_Contract_Proof_Status := Flow_Final.Flow_Contract_Proof_Not_Checked;
      Tasking_Status : Tasking_Final.Deep_Tasking_Status := Tasking_Final.Deep_Tasking_Not_Checked;
      Elaboration_Status : Elaboration_Final.Final_Elaboration_Status := Elaboration_Final.Final_Elaboration_Not_Checked;
      Accessibility_Status : Access_Final.Master_Scope_Final_Status := Access_Final.Master_Scope_Final_Not_Checked;
      Discriminant_Status : Discriminant_Final.Discriminant_Consumer_Status := Discriminant_Final.Discriminant_Consumer_Not_Checked;
      Input_Current : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
   end record;

   type Final_Diagnostic_Info is record
      Id       : Final_Diagnostic_Id := No_Final_Diagnostic;
      Family   : Final_Diagnostic_Source_Family := Final_Diagnostic_Unknown;
      Status   : Final_Diagnostic_Status := Final_Diagnostic_Not_Checked;
      Severity : Final_Diagnostic_Severity := Final_Diagnostic_Warning;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Detail   : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Count : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
   end record;

   type Final_Diagnostic_Context_Model is private;
   type Final_Diagnostic_Model is private;
   type Final_Diagnostic_Set is private;

   procedure Clear (Model : in out Final_Diagnostic_Context_Model);
   procedure Add_Context (Model : in out Final_Diagnostic_Context_Model; Info : Final_Diagnostic_Context_Info);
   function Context_Count (Model : Final_Diagnostic_Context_Model) return Natural;
   function Context_At (Model : Final_Diagnostic_Context_Model; Index : Positive) return Final_Diagnostic_Context_Info;
   function Fingerprint (Model : Final_Diagnostic_Context_Model) return Natural;

   function Build (Contexts : Final_Diagnostic_Context_Model) return Final_Diagnostic_Model;
   function Row_Count (Model : Final_Diagnostic_Model) return Natural;
   function Row_At (Model : Final_Diagnostic_Model; Index : Positive) return Final_Diagnostic_Info;
   function Rows_For_Status (Model : Final_Diagnostic_Model; Status : Final_Diagnostic_Status) return Final_Diagnostic_Set;
   function Rows_For_Family (Model : Final_Diagnostic_Model; Family : Final_Diagnostic_Source_Family) return Final_Diagnostic_Set;
   function Set_Count (Set : Final_Diagnostic_Set) return Natural;
   function Set_At (Set : Final_Diagnostic_Set; Index : Positive) return Final_Diagnostic_Info;
   function Count_Status (Model : Final_Diagnostic_Model; Status : Final_Diagnostic_Status) return Natural;
   function Count_Family (Model : Final_Diagnostic_Model; Family : Final_Diagnostic_Source_Family) return Natural;
   function Error_Count (Model : Final_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Final_Diagnostic_Model) return Natural;
   function Withheld_Legal_Count (Model : Final_Diagnostic_Model) return Natural;
   function Stale_Count (Model : Final_Diagnostic_Model) return Natural;
   function Indeterminate_Count (Model : Final_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Final_Diagnostic_Model) return Natural;

   function Is_Emitted (Status : Final_Diagnostic_Status) return Boolean;
   function Is_Blocker (Status : Final_Diagnostic_Status) return Boolean;
   function Is_Indeterminate (Status : Final_Diagnostic_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Diagnostic_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Diagnostic_Info);

   type Final_Diagnostic_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Final_Diagnostic_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Final_Diagnostic_Model is record
      Items : Row_Vectors.Vector;
      Error_Total : Natural := 0;
      Warning_Total : Natural := 0;
      Withheld_Legal_Total : Natural := 0;
      Stale_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Diagnostic_Integration;
