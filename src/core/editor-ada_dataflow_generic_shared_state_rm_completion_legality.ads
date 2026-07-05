with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
with Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
with Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Predicate_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;

package Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality is

   --  Case 1255 dataflow/initialization legality over the completed
   --  generic/shared-state RM chain.
   --
   --  This package consumes the prior generic/shared-state dataflow evidence
   --  together with completed cross-unit RM closure, elaboration,
   --  accessibility/lifetime, exception/finalization, predicate/invariant,
   --  overload/type, representation/freezing, tasking/protected, and
   --  coverage-proven AST repair evidence.  Definite-initialization and
   --  dataflow conclusions become accepted only when completed RM evidence
   --  agrees and source/substitution fingerprints still match.

   package Prior_Dataflow renames Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
   package Cross_RM renames Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
   package Elaboration_RM renames Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
   package Accessibility_RM renames Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality;
   package Exception_RM renames Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality;
   package Predicate_RM renames Editor.Ada_Predicate_Generic_Shared_State_RM_Completion_Legality;
   package Overload_RM renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   package Representation_RM renames Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package Tasking_RM renames Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package AST_Repair renames Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;

   type Dataflow_RM_Completion_Row_Id is new Natural;
   No_Dataflow_RM_Completion_Row : constant Dataflow_RM_Completion_Row_Id := 0;

   type Dataflow_RM_Completion_Kind is
     (Dataflow_RM_Completion_Read,
      Dataflow_RM_Completion_Write,
      Dataflow_RM_Completion_Read_Write,
      Dataflow_RM_Completion_Out_Parameter,
      Dataflow_RM_Completion_In_Out_Parameter,
      Dataflow_RM_Completion_Return_Object,
      Dataflow_RM_Completion_Variant_Component,
      Dataflow_RM_Completion_Access_Escape,
      Dataflow_RM_Completion_Controlled_Finalization,
      Dataflow_RM_Completion_Generic_Formal_Object,
      Dataflow_RM_Completion_Volatile_Object,
      Dataflow_RM_Completion_Atomic_Object,
      Dataflow_RM_Completion_Dispatching_Call,
      Dataflow_RM_Completion_Cross_Unit_State,
      Dataflow_RM_Completion_Unknown);

   type Dataflow_RM_Completion_Blocker_Family is
     (Dataflow_RM_Completion_Blocker_None,
      Dataflow_RM_Completion_Blocker_Prior_Dataflow,
      Dataflow_RM_Completion_Blocker_Cross_Unit_RM_Completion,
      Dataflow_RM_Completion_Blocker_Elaboration_RM_Completion,
      Dataflow_RM_Completion_Blocker_Accessibility_RM_Completion,
      Dataflow_RM_Completion_Blocker_Exception_Finalization_RM_Completion,
      Dataflow_RM_Completion_Blocker_Predicate_RM_Completion,
      Dataflow_RM_Completion_Blocker_Overload_RM_Completion,
      Dataflow_RM_Completion_Blocker_Representation_RM_Completion,
      Dataflow_RM_Completion_Blocker_Tasking_RM_Completion,
      Dataflow_RM_Completion_Blocker_AST_Repair,
      Dataflow_RM_Completion_Blocker_Read_Before_Write,
      Dataflow_RM_Completion_Blocker_Partial_Component_Init,
      Dataflow_RM_Completion_Blocker_Out_Parameter,
      Dataflow_RM_Completion_Blocker_Return_Object,
      Dataflow_RM_Completion_Blocker_Branch_Loop_Merge,
      Dataflow_RM_Completion_Blocker_Exception_Path,
      Dataflow_RM_Completion_Blocker_Finalization,
      Dataflow_RM_Completion_Blocker_Access_Escape,
      Dataflow_RM_Completion_Blocker_Variant_Component,
      Dataflow_RM_Completion_Blocker_Volatile_Atomic_Effect,
      Dataflow_RM_Completion_Blocker_Generic_Substitution,
      Dataflow_RM_Completion_Blocker_Dispatching_Effect,
      Dataflow_RM_Completion_Blocker_View_Barrier,
      Dataflow_RM_Completion_Blocker_Source_Fingerprint,
      Dataflow_RM_Completion_Blocker_Substitution_Fingerprint,
      Dataflow_RM_Completion_Blocker_Multiple,
      Dataflow_RM_Completion_Blocker_Indeterminate);

   type Dataflow_RM_Completion_Status is
     (Dataflow_RM_Completion_Not_Checked,
      Dataflow_RM_Completion_Legal_Read_Accepted,
      Dataflow_RM_Completion_Legal_Write_Accepted,
      Dataflow_RM_Completion_Legal_Read_Write_Accepted,
      Dataflow_RM_Completion_Legal_Out_Parameter_Accepted,
      Dataflow_RM_Completion_Legal_In_Out_Parameter_Accepted,
      Dataflow_RM_Completion_Legal_Return_Object_Accepted,
      Dataflow_RM_Completion_Legal_Variant_Component_Accepted,
      Dataflow_RM_Completion_Legal_Access_Escape_Accepted,
      Dataflow_RM_Completion_Legal_Controlled_Finalization_Accepted,
      Dataflow_RM_Completion_Legal_Generic_Formal_Object_Accepted,
      Dataflow_RM_Completion_Legal_Volatile_Object_Accepted,
      Dataflow_RM_Completion_Legal_Atomic_Object_Accepted,
      Dataflow_RM_Completion_Legal_Dispatching_Call_Accepted,
      Dataflow_RM_Completion_Legal_Cross_Unit_State_Accepted,
      Dataflow_RM_Completion_Missing_Prior_Dataflow_Row,
      Dataflow_RM_Completion_Prior_Dataflow_Blocker,
      Dataflow_RM_Completion_Missing_Cross_Unit_RM_Row,
      Dataflow_RM_Completion_Cross_Unit_RM_Blocker,
      Dataflow_RM_Completion_Missing_Elaboration_RM_Row,
      Dataflow_RM_Completion_Elaboration_RM_Blocker,
      Dataflow_RM_Completion_Missing_Accessibility_RM_Row,
      Dataflow_RM_Completion_Accessibility_RM_Blocker,
      Dataflow_RM_Completion_Missing_Exception_RM_Row,
      Dataflow_RM_Completion_Exception_RM_Blocker,
      Dataflow_RM_Completion_Missing_Predicate_RM_Row,
      Dataflow_RM_Completion_Predicate_RM_Blocker,
      Dataflow_RM_Completion_Missing_Overload_RM_Row,
      Dataflow_RM_Completion_Overload_RM_Blocker,
      Dataflow_RM_Completion_Missing_Representation_RM_Row,
      Dataflow_RM_Completion_Representation_RM_Blocker,
      Dataflow_RM_Completion_Missing_Tasking_RM_Row,
      Dataflow_RM_Completion_Tasking_RM_Blocker,
      Dataflow_RM_Completion_Missing_AST_Repair_Row,
      Dataflow_RM_Completion_AST_Repair_Blocker,
      Dataflow_RM_Completion_Read_Before_Write_Blocker,
      Dataflow_RM_Completion_Partial_Component_Init_Blocker,
      Dataflow_RM_Completion_Out_Parameter_Blocker,
      Dataflow_RM_Completion_Return_Object_Blocker,
      Dataflow_RM_Completion_Branch_Loop_Merge_Blocker,
      Dataflow_RM_Completion_Exception_Path_Blocker,
      Dataflow_RM_Completion_Finalization_Blocker,
      Dataflow_RM_Completion_Access_Escape_Blocker,
      Dataflow_RM_Completion_Variant_Component_Blocker,
      Dataflow_RM_Completion_Volatile_Atomic_Effect_Blocker,
      Dataflow_RM_Completion_Generic_Substitution_Blocker,
      Dataflow_RM_Completion_Dispatching_Effect_Blocker,
      Dataflow_RM_Completion_View_Barrier,
      Dataflow_RM_Completion_Source_Fingerprint_Mismatch,
      Dataflow_RM_Completion_Substitution_Fingerprint_Mismatch,
      Dataflow_RM_Completion_Multiple_Blockers,
      Dataflow_RM_Completion_Indeterminate);

   type Dataflow_RM_Completion_Context is record
      Id                         : Dataflow_RM_Completion_Row_Id := No_Dataflow_RM_Completion_Row;
      Kind                       : Dataflow_RM_Completion_Kind := Dataflow_RM_Completion_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Prior_Dataflow_Row         : Prior_Dataflow.Dataflow_Generic_Final_Row_Id := Prior_Dataflow.No_Dataflow_Generic_Final_Row;
      Prior_Dataflow_Status      : Prior_Dataflow.Dataflow_Generic_Final_Status := Prior_Dataflow.Dataflow_Generic_Final_Not_Checked;
      Cross_RM_Row               : Cross_RM.Cross_Unit_RM_Completion_Closure_Id := Cross_RM.No_Cross_Unit_RM_Completion_Closure;
      Cross_RM_Status            : Cross_RM.Cross_Unit_RM_Completion_Status := Cross_RM.Cross_Unit_RM_Completion_Not_Checked;
      Elaboration_RM_Row         : Elaboration_RM.Elaboration_RM_Completion_Row_Id := Elaboration_RM.No_Elaboration_RM_Completion_Row;
      Elaboration_RM_Status      : Elaboration_RM.Elaboration_RM_Completion_Status := Elaboration_RM.Elaboration_RM_Completion_Not_Checked;
      Accessibility_RM_Row       : Accessibility_RM.Accessibility_RM_Completion_Row_Id := Accessibility_RM.No_Accessibility_RM_Completion_Row;
      Accessibility_RM_Status    : Accessibility_RM.Accessibility_RM_Completion_Status := Accessibility_RM.Accessibility_RM_Completion_Not_Checked;
      Exception_RM_Row           : Exception_RM.Exception_RM_Completion_Row_Id := Exception_RM.No_Exception_RM_Completion_Row;
      Exception_RM_Status        : Exception_RM.Exception_RM_Completion_Status := Exception_RM.Exception_RM_Completion_Not_Checked;
      Predicate_RM_Row           : Predicate_RM.Predicate_RM_Completion_Row_Id := Predicate_RM.No_Predicate_RM_Completion_Row;
      Predicate_RM_Status        : Predicate_RM.Predicate_RM_Completion_Status := Predicate_RM.Predicate_RM_Completion_Not_Checked;
      Overload_RM_Row            : Overload_RM.Overload_Generic_RM_Edge_Completion_Id := Overload_RM.No_Overload_Generic_RM_Edge_Completion;
      Overload_RM_Status         : Overload_RM.Overload_Generic_RM_Edge_Status := Overload_RM.Overload_Generic_RM_Edge_Not_Checked;
      Representation_RM_Row      : Representation_RM.Representation_Generic_RM_Hard_Case_Id := Representation_RM.No_Representation_Generic_RM_Hard_Case;
      Representation_RM_Status   : Representation_RM.Representation_Generic_RM_Hard_Case_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Not_Checked;
      Tasking_RM_Row             : Tasking_RM.Tasking_Generic_RM_Hard_Case_Id := Tasking_RM.No_Tasking_Generic_RM_Hard_Case;
      Tasking_RM_Status          : Tasking_RM.Tasking_Generic_RM_Hard_Case_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Not_Checked;
      AST_Repair_Row             : AST_Repair.Coverage_Proven_AST_Repair_Id := AST_Repair.No_Coverage_Proven_AST_Repair;
      AST_Repair_Status          : AST_Repair.Coverage_Proven_AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Not_Checked;
      Requires_Prior_Dataflow    : Boolean := True;
      Requires_Cross_RM          : Boolean := True;
      Requires_Elaboration_RM    : Boolean := False;
      Requires_Accessibility_RM  : Boolean := False;
      Requires_Exception_RM      : Boolean := False;
      Requires_Predicate_RM      : Boolean := False;
      Requires_Overload_RM       : Boolean := False;
      Requires_Representation_RM : Boolean := False;
      Requires_Tasking_RM        : Boolean := False;
      Requires_AST_Repair        : Boolean := False;
      Read_Before_Write_Blocker  : Boolean := False;
      Partial_Component_Init_Blocker : Boolean := False;
      Out_Parameter_Blocker      : Boolean := False;
      Return_Object_Blocker      : Boolean := False;
      Branch_Loop_Merge_Blocker  : Boolean := False;
      Exception_Path_Blocker     : Boolean := False;
      Finalization_Blocker       : Boolean := False;
      Access_Escape_Blocker      : Boolean := False;
      Variant_Component_Blocker  : Boolean := False;
      Volatile_Atomic_Effect_Blocker : Boolean := False;
      Generic_Substitution_Blocker : Boolean := False;
      Dispatching_Effect_Blocker : Boolean := False;
      View_Barrier               : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Explicit_Multiple_Blockers : Boolean := False;
      Explicit_Indeterminate     : Boolean := False;
   end record;

   type Dataflow_RM_Completion_Row is record
      Id                         : Dataflow_RM_Completion_Row_Id := No_Dataflow_RM_Completion_Row;
      Kind                       : Dataflow_RM_Completion_Kind := Dataflow_RM_Completion_Unknown;
      Status                     : Dataflow_RM_Completion_Status := Dataflow_RM_Completion_Not_Checked;
      Blocker_Family             : Dataflow_RM_Completion_Blocker_Family := Dataflow_RM_Completion_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Stable_Row_Fingerprint     : Natural := 0;
   end record;

   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Dataflow_RM_Completion_Context);
   subtype Dataflow_RM_Completion_Context_Model is Context_Vectors.Vector;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Dataflow_RM_Completion_Row);

   type Dataflow_RM_Completion_Model is private;

   procedure Add_Context
     (Model : in out Dataflow_RM_Completion_Context_Model;
      Item  : Dataflow_RM_Completion_Context);

   function Build
     (Contexts : Dataflow_RM_Completion_Context_Model)
      return Dataflow_RM_Completion_Model;

   function Count (Model : Dataflow_RM_Completion_Model) return Natural;
   function Accepted_Count (Model : Dataflow_RM_Completion_Model) return Natural;
   function Blocked_Count (Model : Dataflow_RM_Completion_Model) return Natural;
   function Indeterminate_Count (Model : Dataflow_RM_Completion_Model) return Natural;
   function Count_By_Status
     (Model  : Dataflow_RM_Completion_Model;
      Status : Dataflow_RM_Completion_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Dataflow_RM_Completion_Model;
      Family : Dataflow_RM_Completion_Blocker_Family) return Natural;
   function Row_At
     (Model : Dataflow_RM_Completion_Model;
      Index : Positive) return Dataflow_RM_Completion_Row;

   type Query_Result is private;
   function Query_Count (Result : Query_Result) return Natural;
   function Query_Row
     (Result : Query_Result;
      Index  : Positive) return Dataflow_RM_Completion_Row;
   function Find_By_Node
     (Model : Dataflow_RM_Completion_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Query_Result;
   function Find_By_Source_Fingerprint
     (Model       : Dataflow_RM_Completion_Model;
      Fingerprint : Natural) return Query_Result;
   function Query_Blocker_Family
     (Model  : Dataflow_RM_Completion_Model;
      Family : Dataflow_RM_Completion_Blocker_Family) return Query_Result;
   function Stable_Fingerprint (Model : Dataflow_RM_Completion_Model) return Natural;

   function Is_Accepted (Status : Dataflow_RM_Completion_Status) return Boolean;
   function Is_Blocked (Status : Dataflow_RM_Completion_Status) return Boolean;
   function Blocks_Downstream (Status : Dataflow_RM_Completion_Status) return Boolean;
   function Blocker_Family_For
     (Status : Dataflow_RM_Completion_Status)
      return Dataflow_RM_Completion_Blocker_Family;

private
   type Dataflow_RM_Completion_Model is record
      Rows : Row_Vectors.Vector;
      Stable_Fingerprint_Value : Natural := 0;
   end record;

   type Query_Result is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
