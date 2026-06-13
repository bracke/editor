with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
with Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
with Editor.Ada_Definite_Initialization_Flow_Legality;
with Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
with Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
with Editor.Ada_Predicate_Generic_Shared_State_Final_Legality;
with Editor.Ada_Renaming_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;

package Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality is

   --  Pass1238 definite-initialization/dataflow generic shared-state final
   --  legality.
   --
   --  This package connects definite initialization and dataflow consumers with
   --  the generic/shared-state final semantic chain.  Dataflow conclusions for
   --  reads, writes, out/in-out parameters, return objects, variant-dependent
   --  components, access values, controlled finalization paths, generic formal
   --  objects, volatile/atomic objects, dispatching effects, and cross-unit
   --  shared state are accepted only when initialization, predicate/dataflow,
   --  generic replay, shared-state closure, representation, tasking,
   --  accessibility, discriminant, exception/finalization, renaming, and
   --  volatile/atomic representation evidence agree.

   package Init renames Editor.Ada_Definite_Initialization_Flow_Legality;
   package Dataflow_Init renames Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
   package Predicate_Dataflow renames Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
   package Predicate_Generic renames Editor.Ada_Predicate_Generic_Shared_State_Final_Legality;
   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;
   package Rep_Generic renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   package Tasking_Generic renames Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
   package Access_Generic renames Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
   package Disc_Generic renames Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
   package Exception_Generic renames Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
   package Renaming_Generic renames Editor.Ada_Renaming_Generic_Shared_State_Final_Legality;
   package Volatile_Rep renames Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;

   type Dataflow_Generic_Final_Row_Id is new Natural;
   No_Dataflow_Generic_Final_Row : constant Dataflow_Generic_Final_Row_Id := 0;

   type Dataflow_Generic_Final_Kind is
     (Dataflow_Generic_Final_Read,
      Dataflow_Generic_Final_Write,
      Dataflow_Generic_Final_Read_Write,
      Dataflow_Generic_Final_Out_Parameter,
      Dataflow_Generic_Final_In_Out_Parameter,
      Dataflow_Generic_Final_Return_Object,
      Dataflow_Generic_Final_Variant_Component,
      Dataflow_Generic_Final_Access_Escape,
      Dataflow_Generic_Final_Controlled_Finalization,
      Dataflow_Generic_Final_Generic_Formal_Object,
      Dataflow_Generic_Final_Volatile_Object,
      Dataflow_Generic_Final_Atomic_Object,
      Dataflow_Generic_Final_Dispatching_Call,
      Dataflow_Generic_Final_Cross_Unit_State,
      Dataflow_Generic_Final_Unknown);

   type Dataflow_Generic_Final_Blocker_Family is
     (Dataflow_Generic_Final_Blocker_None,
      Dataflow_Generic_Final_Blocker_Definite_Initialization,
      Dataflow_Generic_Final_Blocker_Dataflow_Initialization,
      Dataflow_Generic_Final_Blocker_Predicate_Dataflow,
      Dataflow_Generic_Final_Blocker_Predicate_Generic_Shared_State,
      Dataflow_Generic_Final_Blocker_Generic_Abstract_Replay,
      Dataflow_Generic_Final_Blocker_Stabilized_Shared_State_Closure,
      Dataflow_Generic_Final_Blocker_Representation_Generic_Shared_State,
      Dataflow_Generic_Final_Blocker_Tasking_Generic_Shared_State,
      Dataflow_Generic_Final_Blocker_Accessibility_Generic_Shared_State,
      Dataflow_Generic_Final_Blocker_Discriminant_Generic_Shared_State,
      Dataflow_Generic_Final_Blocker_Exception_Finalization_Generic_Shared_State,
      Dataflow_Generic_Final_Blocker_Renaming_Generic_Shared_State,
      Dataflow_Generic_Final_Blocker_Volatile_Atomic_Representation,
      Dataflow_Generic_Final_Blocker_Read_Before_Write,
      Dataflow_Generic_Final_Blocker_Partial_Component_Init,
      Dataflow_Generic_Final_Blocker_Out_Parameter,
      Dataflow_Generic_Final_Blocker_Return_Object,
      Dataflow_Generic_Final_Blocker_Branch_Loop_Merge,
      Dataflow_Generic_Final_Blocker_Exception_Path,
      Dataflow_Generic_Final_Blocker_Finalization,
      Dataflow_Generic_Final_Blocker_Access_Escape,
      Dataflow_Generic_Final_Blocker_Variant_Component,
      Dataflow_Generic_Final_Blocker_Volatile_Atomic_Effect,
      Dataflow_Generic_Final_Blocker_Generic_Substitution,
      Dataflow_Generic_Final_Blocker_Source_Fingerprint,
      Dataflow_Generic_Final_Blocker_Substitution_Fingerprint,
      Dataflow_Generic_Final_Blocker_Multiple,
      Dataflow_Generic_Final_Blocker_Indeterminate);

   type Dataflow_Generic_Final_Status is
     (Dataflow_Generic_Final_Not_Checked,
      Dataflow_Generic_Final_Legal_Read_Accepted,
      Dataflow_Generic_Final_Legal_Write_Accepted,
      Dataflow_Generic_Final_Legal_Read_Write_Accepted,
      Dataflow_Generic_Final_Legal_Out_Parameter_Accepted,
      Dataflow_Generic_Final_Legal_In_Out_Parameter_Accepted,
      Dataflow_Generic_Final_Legal_Return_Object_Accepted,
      Dataflow_Generic_Final_Legal_Variant_Component_Accepted,
      Dataflow_Generic_Final_Legal_Access_Escape_Accepted,
      Dataflow_Generic_Final_Legal_Controlled_Finalization_Accepted,
      Dataflow_Generic_Final_Legal_Generic_Formal_Object_Accepted,
      Dataflow_Generic_Final_Legal_Volatile_Object_Accepted,
      Dataflow_Generic_Final_Legal_Atomic_Object_Accepted,
      Dataflow_Generic_Final_Legal_Dispatching_Call_Accepted,
      Dataflow_Generic_Final_Legal_Cross_Unit_State_Accepted,
      Dataflow_Generic_Final_Missing_Initialization_Row,
      Dataflow_Generic_Final_Initialization_Blocker,
      Dataflow_Generic_Final_Missing_Dataflow_Init_Row,
      Dataflow_Generic_Final_Dataflow_Init_Blocker,
      Dataflow_Generic_Final_Missing_Predicate_Dataflow_Row,
      Dataflow_Generic_Final_Predicate_Dataflow_Blocker,
      Dataflow_Generic_Final_Missing_Predicate_Generic_Row,
      Dataflow_Generic_Final_Predicate_Generic_Blocker,
      Dataflow_Generic_Final_Missing_Generic_Replay_Row,
      Dataflow_Generic_Final_Generic_Replay_Blocker,
      Dataflow_Generic_Final_Missing_Stabilized_Closure_Row,
      Dataflow_Generic_Final_Stabilized_Closure_Blocker,
      Dataflow_Generic_Final_Missing_Representation_Generic_Row,
      Dataflow_Generic_Final_Representation_Generic_Blocker,
      Dataflow_Generic_Final_Missing_Tasking_Generic_Row,
      Dataflow_Generic_Final_Tasking_Generic_Blocker,
      Dataflow_Generic_Final_Missing_Accessibility_Generic_Row,
      Dataflow_Generic_Final_Accessibility_Generic_Blocker,
      Dataflow_Generic_Final_Missing_Discriminant_Generic_Row,
      Dataflow_Generic_Final_Discriminant_Generic_Blocker,
      Dataflow_Generic_Final_Missing_Exception_Generic_Row,
      Dataflow_Generic_Final_Exception_Generic_Blocker,
      Dataflow_Generic_Final_Missing_Renaming_Generic_Row,
      Dataflow_Generic_Final_Renaming_Generic_Blocker,
      Dataflow_Generic_Final_Missing_Volatile_Representation_Row,
      Dataflow_Generic_Final_Volatile_Representation_Blocker,
      Dataflow_Generic_Final_Read_Before_Write_Blocker,
      Dataflow_Generic_Final_Partial_Component_Init_Blocker,
      Dataflow_Generic_Final_Out_Parameter_Blocker,
      Dataflow_Generic_Final_Return_Object_Blocker,
      Dataflow_Generic_Final_Branch_Loop_Merge_Blocker,
      Dataflow_Generic_Final_Exception_Path_Blocker,
      Dataflow_Generic_Final_Finalization_Blocker,
      Dataflow_Generic_Final_Access_Escape_Blocker,
      Dataflow_Generic_Final_Variant_Component_Blocker,
      Dataflow_Generic_Final_Volatile_Atomic_Effect_Blocker,
      Dataflow_Generic_Final_Generic_Substitution_Blocker,
      Dataflow_Generic_Final_Source_Fingerprint_Mismatch,
      Dataflow_Generic_Final_Substitution_Fingerprint_Mismatch,
      Dataflow_Generic_Final_Multiple_Blockers,
      Dataflow_Generic_Final_Indeterminate);

   type Dataflow_Generic_Final_Context is record
      Id                         : Dataflow_Generic_Final_Row_Id := No_Dataflow_Generic_Final_Row;
      Kind                       : Dataflow_Generic_Final_Kind := Dataflow_Generic_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Initialization_Row         : Init.Initialization_Legality_Id := Init.No_Initialization_Legality;
      Initialization_Status      : Init.Initialization_Legality_Status := Init.Initialization_Legality_Not_Checked;
      Dataflow_Init_Row          : Dataflow_Init.Dataflow_Init_Row_Id := Dataflow_Init.No_Dataflow_Init_Row;
      Dataflow_Init_Status       : Dataflow_Init.Dataflow_Init_Status := Dataflow_Init.Dataflow_Init_Not_Checked;
      Predicate_Dataflow_Row     : Predicate_Dataflow.Predicate_Dataflow_Row_Id := Predicate_Dataflow.No_Predicate_Dataflow_Row;
      Predicate_Dataflow_Status  : Predicate_Dataflow.Predicate_Dataflow_Status := Predicate_Dataflow.Predicate_Dataflow_Not_Checked;
      Predicate_Generic_Row      : Predicate_Generic.Predicate_Generic_Final_Row_Id := Predicate_Generic.No_Predicate_Generic_Final_Row;
      Predicate_Generic_Status   : Predicate_Generic.Predicate_Generic_Final_Status := Predicate_Generic.Predicate_Generic_Final_Not_Checked;
      Generic_Replay_Row         : Generic_Replay.Generic_Abstract_Replay_Row_Id := Generic_Replay.No_Generic_Abstract_Replay_Row;
      Generic_Replay_Status      : Generic_Replay.Generic_Abstract_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Representation_Generic_Row : Rep_Generic.Representation_Generic_Final_Row_Id := Rep_Generic.No_Representation_Generic_Final_Row;
      Representation_Generic_Status : Rep_Generic.Representation_Generic_Final_Status := Rep_Generic.Representation_Generic_Final_Not_Checked;
      Tasking_Generic_Row        : Tasking_Generic.Tasking_Generic_Final_Row_Id := Tasking_Generic.No_Tasking_Generic_Final_Row;
      Tasking_Generic_Status     : Tasking_Generic.Tasking_Generic_Final_Status := Tasking_Generic.Tasking_Generic_Final_Not_Checked;
      Accessibility_Generic_Row  : Access_Generic.Accessibility_Generic_Final_Row_Id := Access_Generic.No_Accessibility_Generic_Final_Row;
      Accessibility_Generic_Status : Access_Generic.Accessibility_Generic_Final_Status := Access_Generic.Accessibility_Generic_Final_Not_Checked;
      Discriminant_Generic_Row   : Disc_Generic.Discriminant_Generic_Final_Row_Id := Disc_Generic.No_Discriminant_Generic_Final_Row;
      Discriminant_Generic_Status : Disc_Generic.Discriminant_Generic_Final_Status := Disc_Generic.Discriminant_Generic_Final_Not_Checked;
      Exception_Generic_Row      : Exception_Generic.Exception_Generic_Final_Row_Id := Exception_Generic.No_Exception_Generic_Final_Row;
      Exception_Generic_Status   : Exception_Generic.Exception_Generic_Final_Status := Exception_Generic.Exception_Generic_Final_Not_Checked;
      Renaming_Generic_Row       : Renaming_Generic.Renaming_Generic_Final_Row_Id := Renaming_Generic.No_Renaming_Generic_Final_Row;
      Renaming_Generic_Status    : Renaming_Generic.Renaming_Generic_Final_Status := Renaming_Generic.Renaming_Generic_Final_Not_Checked;
      Volatile_Representation_Row : Volatile_Rep.Volatile_Atomic_Representation_Row_Id := Volatile_Rep.No_Volatile_Atomic_Representation_Row;
      Volatile_Representation_Status : Volatile_Rep.Volatile_Atomic_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Not_Checked;
      Requires_Predicate_Dataflow : Boolean := False;
      Requires_Predicate_Generic : Boolean := False;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Representation_Generic : Boolean := False;
      Requires_Tasking_Generic   : Boolean := False;
      Requires_Accessibility_Generic : Boolean := False;
      Requires_Discriminant_Generic : Boolean := False;
      Requires_Exception_Generic : Boolean := False;
      Requires_Renaming_Generic  : Boolean := False;
      Requires_Volatile_Representation : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
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
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Dataflow_Generic_Final_Row is record
      Id                         : Dataflow_Generic_Final_Row_Id := No_Dataflow_Generic_Final_Row;
      Context                    : Dataflow_Generic_Final_Row_Id := No_Dataflow_Generic_Final_Row;
      Kind                       : Dataflow_Generic_Final_Kind := Dataflow_Generic_Final_Unknown;
      Status                     : Dataflow_Generic_Final_Status := Dataflow_Generic_Final_Not_Checked;
      Blocker_Family             : Dataflow_Generic_Final_Blocker_Family := Dataflow_Generic_Final_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Fingerprint                : Natural := 0;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Dataflow_Generic_Final_Context_Model is private;
   type Dataflow_Generic_Final_Model is private;
   type Dataflow_Generic_Final_Set is private;

   procedure Clear (Model : in out Dataflow_Generic_Final_Context_Model);
   procedure Add_Context (Model : in out Dataflow_Generic_Final_Context_Model; Info : Dataflow_Generic_Final_Context);
   function Context_Count (Model : Dataflow_Generic_Final_Context_Model) return Natural;

   function Build (Contexts : Dataflow_Generic_Final_Context_Model) return Dataflow_Generic_Final_Model;
   function Count (Model : Dataflow_Generic_Final_Model) return Natural;
   function Row_At (Model : Dataflow_Generic_Final_Model; Index : Positive) return Dataflow_Generic_Final_Row;
   function Accepted_Count (Model : Dataflow_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Dataflow_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Dataflow_Generic_Final_Model) return Natural;
   function Count_By_Status (Model : Dataflow_Generic_Final_Model; Status : Dataflow_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family (Model : Dataflow_Generic_Final_Model; Family : Dataflow_Generic_Final_Blocker_Family) return Natural;
   function Find_By_Node (Model : Dataflow_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Dataflow_Generic_Final_Set;
   function Find_By_Source_Fingerprint (Model : Dataflow_Generic_Final_Model; Fingerprint : Natural) return Dataflow_Generic_Final_Set;
   function Query_Blocker_Family (Model : Dataflow_Generic_Final_Model; Family : Dataflow_Generic_Final_Blocker_Family) return Dataflow_Generic_Final_Set;
   function Query_Count (Set : Dataflow_Generic_Final_Set) return Natural;
   function Query_Row_At (Set : Dataflow_Generic_Final_Set; Index : Positive) return Dataflow_Generic_Final_Row;
   function Stable_Fingerprint (Model : Dataflow_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Dataflow_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Dataflow_Generic_Final_Status) return Boolean;
   function Blocks_Downstream (Status : Dataflow_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Dataflow_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Dataflow_Generic_Final_Row);

   type Dataflow_Generic_Final_Context_Model is record
      Items : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Dataflow_Generic_Final_Model is record
      Rows : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Dataflow_Generic_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
