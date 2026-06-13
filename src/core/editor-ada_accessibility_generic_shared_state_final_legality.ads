with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
with Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

package Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality is

   --  Pass1233 accessibility/generic shared-state final legality.
   --
   --  This package connects final accessibility/master-scope evidence with the
   --  generic/shared-state semantic chain.  Accessibility conclusions for
   --  anonymous access values, access discriminants, allocators, conversions,
   --  return objects, renamings, private/full views, controlled finalization,
   --  and cross-unit lifetime paths are accepted only when final accessibility
   --  evidence agrees with cross-unit generic/shared-state closure,
   --  elaboration/generic shared-state evidence, generic abstract-state replay,
   --  overload/generic shared-state evidence, representation/generic
   --  shared-state evidence, tasking/generic shared-state evidence, and
   --  stabilized shared-state closure.  Missing or stale evidence remains a
   --  blocker rather than being flattened into a confident legality result.

   package Access_Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   package Cross_Generic renames Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
   package Elab_Generic renames Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Overload_Generic renames Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
   package Rep_Generic renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;
   package Tasking_Generic renames Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

   type Accessibility_Generic_Final_Row_Id is new Natural;
   No_Accessibility_Generic_Final_Row : constant Accessibility_Generic_Final_Row_Id := 0;

   type Accessibility_Generic_Final_Kind is
     (Accessibility_Generic_Final_Anonymous_Access_Result,
      Accessibility_Generic_Final_Anonymous_Access_Parameter,
      Accessibility_Generic_Final_Access_Discriminant,
      Accessibility_Generic_Final_Allocator_Master,
      Accessibility_Generic_Final_Access_Conversion,
      Accessibility_Generic_Final_Return_Object,
      Accessibility_Generic_Final_Return_Access,
      Accessibility_Generic_Final_Generic_Access_Actual,
      Accessibility_Generic_Final_Generic_Replay_Escape,
      Accessibility_Generic_Final_Renaming,
      Accessibility_Generic_Final_Controlled_Finalization,
      Accessibility_Generic_Final_Private_Full_View,
      Accessibility_Generic_Final_Cross_Unit_Lifetime,
      Accessibility_Generic_Final_Task_Protected_Lifetime,
      Accessibility_Generic_Final_Representation_Sensitive_Lifetime,
      Accessibility_Generic_Final_Unknown);

   type Accessibility_Generic_Final_Blocker_Family is
     (Accessibility_Generic_Final_Blocker_None,
      Accessibility_Generic_Final_Blocker_Final_Accessibility,
      Accessibility_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State,
      Accessibility_Generic_Final_Blocker_Elaboration_Generic_Shared_State,
      Accessibility_Generic_Final_Blocker_Generic_Abstract_Replay,
      Accessibility_Generic_Final_Blocker_Overload_Generic_Shared_State,
      Accessibility_Generic_Final_Blocker_Representation_Generic_Shared_State,
      Accessibility_Generic_Final_Blocker_Tasking_Generic_Shared_State,
      Accessibility_Generic_Final_Blocker_Stabilized_Shared_State_Closure,
      Accessibility_Generic_Final_Blocker_Access_Level,
      Accessibility_Generic_Final_Blocker_Master_Escape,
      Accessibility_Generic_Final_Blocker_Return_Object,
      Accessibility_Generic_Final_Blocker_Renaming_Lifetime,
      Accessibility_Generic_Final_Blocker_Finalization_Master,
      Accessibility_Generic_Final_Blocker_Private_Full_View,
      Accessibility_Generic_Final_Blocker_Cross_Unit_Lifetime,
      Accessibility_Generic_Final_Blocker_Task_Protected_Lifetime,
      Accessibility_Generic_Final_Blocker_Representation_Sensitive_Lifetime,
      Accessibility_Generic_Final_Blocker_Source_Fingerprint,
      Accessibility_Generic_Final_Blocker_Substitution_Fingerprint,
      Accessibility_Generic_Final_Blocker_Multiple,
      Accessibility_Generic_Final_Blocker_Indeterminate);

   type Accessibility_Generic_Final_Status is
     (Accessibility_Generic_Final_Not_Checked,
      Accessibility_Generic_Final_Legal_Anonymous_Access_Result_Accepted,
      Accessibility_Generic_Final_Legal_Anonymous_Access_Parameter_Accepted,
      Accessibility_Generic_Final_Legal_Access_Discriminant_Accepted,
      Accessibility_Generic_Final_Legal_Allocator_Master_Accepted,
      Accessibility_Generic_Final_Legal_Access_Conversion_Accepted,
      Accessibility_Generic_Final_Legal_Return_Object_Accepted,
      Accessibility_Generic_Final_Legal_Return_Access_Accepted,
      Accessibility_Generic_Final_Legal_Generic_Access_Actual_Accepted,
      Accessibility_Generic_Final_Legal_Generic_Replay_Escape_Accepted,
      Accessibility_Generic_Final_Legal_Renaming_Accepted,
      Accessibility_Generic_Final_Legal_Controlled_Finalization_Accepted,
      Accessibility_Generic_Final_Legal_Private_Full_View_Accepted,
      Accessibility_Generic_Final_Legal_Cross_Unit_Lifetime_Accepted,
      Accessibility_Generic_Final_Legal_Task_Protected_Lifetime_Accepted,
      Accessibility_Generic_Final_Legal_Representation_Sensitive_Lifetime_Accepted,
      Accessibility_Generic_Final_Missing_Final_Accessibility_Row,
      Accessibility_Generic_Final_Final_Accessibility_Blocker,
      Accessibility_Generic_Final_Missing_Cross_Unit_Generic_Row,
      Accessibility_Generic_Final_Cross_Unit_Generic_Blocker,
      Accessibility_Generic_Final_Missing_Elaboration_Generic_Row,
      Accessibility_Generic_Final_Elaboration_Generic_Blocker,
      Accessibility_Generic_Final_Missing_Generic_Replay_Row,
      Accessibility_Generic_Final_Generic_Replay_Blocker,
      Accessibility_Generic_Final_Missing_Overload_Generic_Row,
      Accessibility_Generic_Final_Overload_Generic_Blocker,
      Accessibility_Generic_Final_Missing_Representation_Generic_Row,
      Accessibility_Generic_Final_Representation_Generic_Blocker,
      Accessibility_Generic_Final_Missing_Tasking_Generic_Row,
      Accessibility_Generic_Final_Tasking_Generic_Blocker,
      Accessibility_Generic_Final_Missing_Stabilized_Closure_Row,
      Accessibility_Generic_Final_Stabilized_Closure_Blocker,
      Accessibility_Generic_Final_Access_Level_Blocker,
      Accessibility_Generic_Final_Master_Escape_Blocker,
      Accessibility_Generic_Final_Return_Object_Blocker,
      Accessibility_Generic_Final_Renaming_Lifetime_Blocker,
      Accessibility_Generic_Final_Finalization_Master_Blocker,
      Accessibility_Generic_Final_Private_Full_View_Blocker,
      Accessibility_Generic_Final_Cross_Unit_Lifetime_Blocker,
      Accessibility_Generic_Final_Task_Protected_Lifetime_Blocker,
      Accessibility_Generic_Final_Representation_Sensitive_Lifetime_Blocker,
      Accessibility_Generic_Final_Source_Fingerprint_Mismatch,
      Accessibility_Generic_Final_Substitution_Fingerprint_Mismatch,
      Accessibility_Generic_Final_Multiple_Blockers,
      Accessibility_Generic_Final_Indeterminate);

   type Accessibility_Generic_Final_Context is record
      Id                         : Accessibility_Generic_Final_Row_Id := No_Accessibility_Generic_Final_Row;
      Kind                       : Accessibility_Generic_Final_Kind := Accessibility_Generic_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Final_Accessibility_Row    : Access_Final.Master_Scope_Final_Row_Id := Access_Final.No_Master_Scope_Final_Row;
      Final_Accessibility_Status : Access_Final.Master_Scope_Final_Status := Access_Final.Master_Scope_Final_Not_Checked;
      Cross_Generic_Row          : Cross_Generic.Cross_Unit_Generic_Final_Row_Id := Cross_Generic.No_Cross_Unit_Generic_Final_Row;
      Cross_Generic_Status       : Cross_Generic.Cross_Unit_Generic_Final_Status := Cross_Generic.Cross_Unit_Generic_Final_Not_Checked;
      Elaboration_Generic_Row    : Elab_Generic.Elaboration_Generic_Final_Row_Id := Elab_Generic.No_Elaboration_Generic_Final_Row;
      Elaboration_Generic_Status : Elab_Generic.Elaboration_Generic_Final_Status := Elab_Generic.Elaboration_Generic_Final_Not_Checked;
      Generic_Replay_Row         : Generic_Replay.Generic_Abstract_Replay_Row_Id := Generic_Replay.No_Generic_Abstract_Replay_Row;
      Generic_Replay_Status      : Generic_Replay.Generic_Abstract_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Not_Checked;
      Overload_Generic_Row       : Overload_Generic.Overload_Generic_Final_Row_Id := Overload_Generic.No_Overload_Generic_Final_Row;
      Overload_Generic_Status    : Overload_Generic.Overload_Generic_Final_Status := Overload_Generic.Overload_Generic_Final_Not_Checked;
      Representation_Generic_Row : Rep_Generic.Representation_Generic_Final_Row_Id := Rep_Generic.No_Representation_Generic_Final_Row;
      Representation_Generic_Status : Rep_Generic.Representation_Generic_Final_Status := Rep_Generic.Representation_Generic_Final_Not_Checked;
      Tasking_Generic_Row        : Tasking_Generic.Tasking_Generic_Final_Row_Id := Tasking_Generic.No_Tasking_Generic_Final_Row;
      Tasking_Generic_Status     : Tasking_Generic.Tasking_Generic_Final_Status := Tasking_Generic.Tasking_Generic_Final_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Elaboration_Generic : Boolean := False;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Overload_Generic  : Boolean := False;
      Requires_Representation_Generic : Boolean := False;
      Requires_Tasking_Generic   : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Access_Level_Blocker       : Boolean := False;
      Master_Escape_Blocker      : Boolean := False;
      Return_Object_Blocker      : Boolean := False;
      Renaming_Lifetime_Blocker  : Boolean := False;
      Finalization_Master_Blocker : Boolean := False;
      Private_Full_View_Blocker  : Boolean := False;
      Cross_Unit_Lifetime_Blocker : Boolean := False;
      Task_Protected_Lifetime_Blocker : Boolean := False;
      Representation_Sensitive_Lifetime_Blocker : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Accessibility_Generic_Final_Row is record
      Id                         : Accessibility_Generic_Final_Row_Id := No_Accessibility_Generic_Final_Row;
      Context                    : Accessibility_Generic_Final_Row_Id := No_Accessibility_Generic_Final_Row;
      Kind                       : Accessibility_Generic_Final_Kind := Accessibility_Generic_Final_Unknown;
      Status                     : Accessibility_Generic_Final_Status := Accessibility_Generic_Final_Not_Checked;
      Blocker_Family             : Accessibility_Generic_Final_Blocker_Family := Accessibility_Generic_Final_Blocker_None;
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
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint                : Natural := 0;
   end record;

   type Accessibility_Generic_Final_Context_Model is private;
   type Accessibility_Generic_Final_Model is private;
   type Accessibility_Generic_Final_Query is private;

   procedure Clear (Model : in out Accessibility_Generic_Final_Context_Model);
   procedure Add_Context (Model : in out Accessibility_Generic_Final_Context_Model; Info : Accessibility_Generic_Final_Context);
   function Context_Count (Model : Accessibility_Generic_Final_Context_Model) return Natural;
   function Context_At (Model : Accessibility_Generic_Final_Context_Model; Index : Positive) return Accessibility_Generic_Final_Context;

   function Build (Contexts : Accessibility_Generic_Final_Context_Model) return Accessibility_Generic_Final_Model;

   function Count (Model : Accessibility_Generic_Final_Model) return Natural;
   function Row_At (Model : Accessibility_Generic_Final_Model; Index : Positive) return Accessibility_Generic_Final_Row;
   function Accepted_Count (Model : Accessibility_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Accessibility_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Accessibility_Generic_Final_Model) return Natural;
   function Count_By_Status (Model : Accessibility_Generic_Final_Model; Status : Accessibility_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family (Model : Accessibility_Generic_Final_Model; Family : Accessibility_Generic_Final_Blocker_Family) return Natural;
   function Find_By_Node (Model : Accessibility_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Accessibility_Generic_Final_Query;
   function Find_By_Source_Fingerprint (Model : Accessibility_Generic_Final_Model; Fingerprint : Natural) return Accessibility_Generic_Final_Query;
   function Query_Blocker_Family (Model : Accessibility_Generic_Final_Model; Family : Accessibility_Generic_Final_Blocker_Family) return Accessibility_Generic_Final_Query;
   function Query_Count (Query : Accessibility_Generic_Final_Query) return Natural;
   function Query_Row_At (Query : Accessibility_Generic_Final_Query; Index : Positive) return Accessibility_Generic_Final_Row;
   function Stable_Fingerprint (Model : Accessibility_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Accessibility_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Accessibility_Generic_Final_Status) return Boolean;
   function Blocks_Downstream (Status : Accessibility_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Accessibility_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Accessibility_Generic_Final_Row);

   type Accessibility_Generic_Final_Context_Model is record
      Items              : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Accessibility_Generic_Final_Model is record
      Rows               : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Accessibility_Generic_Final_Query is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
