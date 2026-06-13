with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
with Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
with Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;

package Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality is

   --  Pass1252 accessibility/lifetime legality over the completed
   --  generic/shared-state RM chain.
   --
   --  This package consumes the completed cross-unit RM closure together with
   --  prior accessibility/generic shared-state evidence, completed elaboration,
   --  overload/type, representation/freezing, tasking/protected, and
   --  coverage-proven AST repair evidence.  Accessibility conclusions for
   --  access results and parameters, access discriminants, allocator masters,
   --  conversions, return objects, generic access actuals, generic replay
   --  escapes, renamings, controlled finalization, private/full views,
   --  cross-unit lifetime paths, task/protected lifetimes, representation-
   --  sensitive lifetimes, dispatching access results, variant component
   --  accesses, and protected access paths are accepted only when all completed
   --  RM evidence agrees and fingerprints still match.

   package Cross_RM renames Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
   package Prior_Access renames Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
   package Elaboration_RM renames Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
   package Overload_RM renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   package Representation_RM renames Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package Tasking_RM renames Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package AST_Repair renames Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;

   type Accessibility_RM_Completion_Row_Id is new Natural;
   No_Accessibility_RM_Completion_Row : constant Accessibility_RM_Completion_Row_Id := 0;

   type Accessibility_RM_Completion_Kind is
     (Accessibility_RM_Completion_Anonymous_Access_Result,
      Accessibility_RM_Completion_Anonymous_Access_Parameter,
      Accessibility_RM_Completion_Access_Discriminant,
      Accessibility_RM_Completion_Allocator_Master,
      Accessibility_RM_Completion_Access_Conversion,
      Accessibility_RM_Completion_Return_Object,
      Accessibility_RM_Completion_Return_Access,
      Accessibility_RM_Completion_Generic_Access_Actual,
      Accessibility_RM_Completion_Generic_Replay_Escape,
      Accessibility_RM_Completion_Renaming,
      Accessibility_RM_Completion_Controlled_Finalization,
      Accessibility_RM_Completion_Private_Full_View,
      Accessibility_RM_Completion_Cross_Unit_Lifetime,
      Accessibility_RM_Completion_Task_Protected_Lifetime,
      Accessibility_RM_Completion_Representation_Sensitive_Lifetime,
      Accessibility_RM_Completion_Dispatching_Access_Result,
      Accessibility_RM_Completion_Variant_Component_Access,
      Accessibility_RM_Completion_Protected_Access,
      Accessibility_RM_Completion_Unknown);

   type Accessibility_RM_Completion_Blocker_Family is
     (Accessibility_RM_Completion_Blocker_None,
      Accessibility_RM_Completion_Blocker_Cross_Unit_RM_Completion,
      Accessibility_RM_Completion_Blocker_Prior_Accessibility,
      Accessibility_RM_Completion_Blocker_Elaboration_RM_Completion,
      Accessibility_RM_Completion_Blocker_Overload_RM_Completion,
      Accessibility_RM_Completion_Blocker_Representation_RM_Completion,
      Accessibility_RM_Completion_Blocker_Tasking_RM_Completion,
      Accessibility_RM_Completion_Blocker_AST_Repair,
      Accessibility_RM_Completion_Blocker_Access_Level,
      Accessibility_RM_Completion_Blocker_Master_Escape,
      Accessibility_RM_Completion_Blocker_Return_Object,
      Accessibility_RM_Completion_Blocker_Renaming_Lifetime,
      Accessibility_RM_Completion_Blocker_Finalization_Master,
      Accessibility_RM_Completion_Blocker_Private_Full_View,
      Accessibility_RM_Completion_Blocker_Cross_Unit_Lifetime,
      Accessibility_RM_Completion_Blocker_Task_Protected_Lifetime,
      Accessibility_RM_Completion_Blocker_Representation_Sensitive_Lifetime,
      Accessibility_RM_Completion_Blocker_Dispatching_Access_Result,
      Accessibility_RM_Completion_Blocker_Variant_Component_Access,
      Accessibility_RM_Completion_Blocker_Protected_Access,
      Accessibility_RM_Completion_Blocker_Generic_Body,
      Accessibility_RM_Completion_Blocker_View_Barrier,
      Accessibility_RM_Completion_Blocker_Source_Fingerprint,
      Accessibility_RM_Completion_Blocker_Substitution_Fingerprint,
      Accessibility_RM_Completion_Blocker_Multiple,
      Accessibility_RM_Completion_Blocker_Indeterminate);

   type Accessibility_RM_Completion_Status is
     (Accessibility_RM_Completion_Not_Checked,
      Accessibility_RM_Completion_Legal_Anonymous_Access_Result_Accepted,
      Accessibility_RM_Completion_Legal_Anonymous_Access_Parameter_Accepted,
      Accessibility_RM_Completion_Legal_Access_Discriminant_Accepted,
      Accessibility_RM_Completion_Legal_Allocator_Master_Accepted,
      Accessibility_RM_Completion_Legal_Access_Conversion_Accepted,
      Accessibility_RM_Completion_Legal_Return_Object_Accepted,
      Accessibility_RM_Completion_Legal_Return_Access_Accepted,
      Accessibility_RM_Completion_Legal_Generic_Access_Actual_Accepted,
      Accessibility_RM_Completion_Legal_Generic_Replay_Escape_Accepted,
      Accessibility_RM_Completion_Legal_Renaming_Accepted,
      Accessibility_RM_Completion_Legal_Controlled_Finalization_Accepted,
      Accessibility_RM_Completion_Legal_Private_Full_View_Accepted,
      Accessibility_RM_Completion_Legal_Cross_Unit_Lifetime_Accepted,
      Accessibility_RM_Completion_Legal_Task_Protected_Lifetime_Accepted,
      Accessibility_RM_Completion_Legal_Representation_Sensitive_Lifetime_Accepted,
      Accessibility_RM_Completion_Legal_Dispatching_Access_Result_Accepted,
      Accessibility_RM_Completion_Legal_Variant_Component_Access_Accepted,
      Accessibility_RM_Completion_Legal_Protected_Access_Accepted,
      Accessibility_RM_Completion_Missing_Cross_Unit_RM_Row,
      Accessibility_RM_Completion_Cross_Unit_RM_Blocker,
      Accessibility_RM_Completion_Missing_Prior_Accessibility_Row,
      Accessibility_RM_Completion_Prior_Accessibility_Blocker,
      Accessibility_RM_Completion_Missing_Elaboration_RM_Row,
      Accessibility_RM_Completion_Elaboration_RM_Blocker,
      Accessibility_RM_Completion_Missing_Overload_RM_Row,
      Accessibility_RM_Completion_Overload_RM_Blocker,
      Accessibility_RM_Completion_Missing_Representation_RM_Row,
      Accessibility_RM_Completion_Representation_RM_Blocker,
      Accessibility_RM_Completion_Missing_Tasking_RM_Row,
      Accessibility_RM_Completion_Tasking_RM_Blocker,
      Accessibility_RM_Completion_Missing_AST_Repair_Row,
      Accessibility_RM_Completion_AST_Repair_Blocker,
      Accessibility_RM_Completion_Access_Level_Blocker,
      Accessibility_RM_Completion_Master_Escape_Blocker,
      Accessibility_RM_Completion_Return_Object_Blocker,
      Accessibility_RM_Completion_Renaming_Lifetime_Blocker,
      Accessibility_RM_Completion_Finalization_Master_Blocker,
      Accessibility_RM_Completion_Private_Full_View_Blocker,
      Accessibility_RM_Completion_Cross_Unit_Lifetime_Blocker,
      Accessibility_RM_Completion_Task_Protected_Lifetime_Blocker,
      Accessibility_RM_Completion_Representation_Sensitive_Lifetime_Blocker,
      Accessibility_RM_Completion_Dispatching_Access_Result_Blocker,
      Accessibility_RM_Completion_Variant_Component_Access_Blocker,
      Accessibility_RM_Completion_Protected_Access_Blocker,
      Accessibility_RM_Completion_Generic_Body_Unavailable,
      Accessibility_RM_Completion_View_Barrier,
      Accessibility_RM_Completion_Source_Fingerprint_Mismatch,
      Accessibility_RM_Completion_Substitution_Fingerprint_Mismatch,
      Accessibility_RM_Completion_Multiple_Blockers,
      Accessibility_RM_Completion_Indeterminate);

   type Accessibility_RM_Completion_Context is record
      Id                         : Accessibility_RM_Completion_Row_Id := No_Accessibility_RM_Completion_Row;
      Kind                       : Accessibility_RM_Completion_Kind := Accessibility_RM_Completion_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Cross_RM_Row               : Cross_RM.Cross_Unit_RM_Completion_Closure_Id := Cross_RM.No_Cross_Unit_RM_Completion_Closure;
      Cross_RM_Status            : Cross_RM.Cross_Unit_RM_Completion_Status := Cross_RM.Cross_Unit_RM_Completion_Not_Checked;
      Prior_Accessibility_Row    : Prior_Access.Accessibility_Generic_Final_Row_Id := Prior_Access.No_Accessibility_Generic_Final_Row;
      Prior_Accessibility_Status : Prior_Access.Accessibility_Generic_Final_Status := Prior_Access.Accessibility_Generic_Final_Not_Checked;
      Elaboration_RM_Row         : Elaboration_RM.Elaboration_RM_Completion_Row_Id := Elaboration_RM.No_Elaboration_RM_Completion_Row;
      Elaboration_RM_Status      : Elaboration_RM.Elaboration_RM_Completion_Status := Elaboration_RM.Elaboration_RM_Completion_Not_Checked;
      Overload_RM_Row            : Overload_RM.Overload_Generic_RM_Edge_Completion_Id := Overload_RM.No_Overload_Generic_RM_Edge_Completion;
      Overload_RM_Status         : Overload_RM.Overload_Generic_RM_Edge_Status := Overload_RM.Overload_Generic_RM_Edge_Not_Checked;
      Representation_RM_Row      : Representation_RM.Representation_Generic_RM_Hard_Case_Id := Representation_RM.No_Representation_Generic_RM_Hard_Case;
      Representation_RM_Status   : Representation_RM.Representation_Generic_RM_Hard_Case_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Not_Checked;
      Tasking_RM_Row             : Tasking_RM.Tasking_Generic_RM_Hard_Case_Id := Tasking_RM.No_Tasking_Generic_RM_Hard_Case;
      Tasking_RM_Status          : Tasking_RM.Tasking_Generic_RM_Hard_Case_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Not_Checked;
      AST_Repair_Row             : AST_Repair.Coverage_Proven_AST_Repair_Id := AST_Repair.No_Coverage_Proven_AST_Repair;
      AST_Repair_Status          : AST_Repair.Coverage_Proven_AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Not_Checked;
      Requires_Cross_RM          : Boolean := True;
      Requires_Prior_Accessibility : Boolean := True;
      Requires_Elaboration_RM    : Boolean := True;
      Requires_Overload_RM       : Boolean := True;
      Requires_Representation_RM : Boolean := True;
      Requires_Tasking_RM        : Boolean := True;
      Requires_AST_Repair        : Boolean := False;
      Access_Level_Blocker       : Boolean := False;
      Master_Escape_Blocker      : Boolean := False;
      Return_Object_Blocker      : Boolean := False;
      Renaming_Lifetime_Blocker  : Boolean := False;
      Finalization_Master_Blocker : Boolean := False;
      Private_Full_View_Blocker  : Boolean := False;
      Cross_Unit_Lifetime_Blocker : Boolean := False;
      Task_Protected_Lifetime_Blocker : Boolean := False;
      Representation_Sensitive_Lifetime_Blocker : Boolean := False;
      Dispatching_Access_Result_Blocker : Boolean := False;
      Variant_Component_Access_Blocker : Boolean := False;
      Protected_Access_Blocker   : Boolean := False;
      Generic_Body_Unavailable   : Boolean := False;
      View_Barrier               : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Accessibility_RM_Completion_Row is record
      Id                         : Accessibility_RM_Completion_Row_Id := No_Accessibility_RM_Completion_Row;
      Context                    : Accessibility_RM_Completion_Row_Id := No_Accessibility_RM_Completion_Row;
      Kind                       : Accessibility_RM_Completion_Kind := Accessibility_RM_Completion_Unknown;
      Status                     : Accessibility_RM_Completion_Status := Accessibility_RM_Completion_Not_Checked;
      Blocker_Family             : Accessibility_RM_Completion_Blocker_Family := Accessibility_RM_Completion_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Accessibility_RM_Completion_Context_Model is private;
   type Accessibility_RM_Completion_Model is private;
   type Accessibility_RM_Completion_Set is private;

   procedure Clear (Model : in out Accessibility_RM_Completion_Context_Model);
   procedure Add_Context (Model : in out Accessibility_RM_Completion_Context_Model; Info : Accessibility_RM_Completion_Context);
   function Context_Count (Model : Accessibility_RM_Completion_Context_Model) return Natural;
   function Context_At (Model : Accessibility_RM_Completion_Context_Model; Index : Positive) return Accessibility_RM_Completion_Context;
   function Context_Fingerprint (Model : Accessibility_RM_Completion_Context_Model) return Natural;

   function Build (Contexts : Accessibility_RM_Completion_Context_Model) return Accessibility_RM_Completion_Model;
   function Count (Model : Accessibility_RM_Completion_Model) return Natural;
   function Row_Count (Model : Accessibility_RM_Completion_Model) return Natural renames Count;
   function Row_At (Model : Accessibility_RM_Completion_Model; Index : Positive) return Accessibility_RM_Completion_Row;
   function Query_Count (Set : Accessibility_RM_Completion_Set) return Natural;
   function Query_At (Set : Accessibility_RM_Completion_Set; Index : Positive) return Accessibility_RM_Completion_Row;
   function Query_Status (Model : Accessibility_RM_Completion_Model; Status : Accessibility_RM_Completion_Status) return Accessibility_RM_Completion_Set;
   function Query_Blocker_Family (Model : Accessibility_RM_Completion_Model; Family : Accessibility_RM_Completion_Blocker_Family) return Accessibility_RM_Completion_Set;
   function Find_By_Node (Model : Accessibility_RM_Completion_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Accessibility_RM_Completion_Set;
   function Find_By_Source_Fingerprint (Model : Accessibility_RM_Completion_Model; Source_Fingerprint : Natural) return Accessibility_RM_Completion_Set;
   function Count_By_Status (Model : Accessibility_RM_Completion_Model; Status : Accessibility_RM_Completion_Status) return Natural;
   function Count_By_Blocker_Family (Model : Accessibility_RM_Completion_Model; Family : Accessibility_RM_Completion_Blocker_Family) return Natural;
   function Accepted_Count (Model : Accessibility_RM_Completion_Model) return Natural;
   function Blocked_Count (Model : Accessibility_RM_Completion_Model) return Natural;
   function Indeterminate_Count (Model : Accessibility_RM_Completion_Model) return Natural;
   function Stable_Fingerprint (Model : Accessibility_RM_Completion_Model) return Natural;

   function Is_Accepted (Status : Accessibility_RM_Completion_Status) return Boolean;
   function Is_Blocked (Status : Accessibility_RM_Completion_Status) return Boolean;
   function Is_Indeterminate (Status : Accessibility_RM_Completion_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Accessibility_RM_Completion_Context);

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Accessibility_RM_Completion_Row);

   type Accessibility_RM_Completion_Context_Model is record
      Items              : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Accessibility_RM_Completion_Model is record
      Rows               : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Accessibility_RM_Completion_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality;
