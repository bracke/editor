with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

package Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality is

   --  Case 1234 discriminant/generic shared-state final legality.
   --
   --  This package connects discriminant and variant consumer evidence with the
   --  generic/shared-state final semantic chain.  Conclusions for discriminant-
   --  dependent record layouts, variant aggregates, access discriminants,
   --  private/full-view discriminants, generic body replay, representation
   --  clauses, task/protected discriminant effects, and cross-unit discriminant
   --  consistency are accepted only when discriminant/variant consumer evidence
   --  agrees with cross-unit generic/shared-state closure, generic abstract-state
   --  replay, overload/type shared-state evidence, representation/freezing
   --  shared-state evidence, tasking/protected shared-state evidence,
   --  accessibility lifetime evidence, elaboration evidence, and stabilized
   --  shared-state closure.  Missing evidence is preserved as a blocker.

   package Disc_Final renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   package Cross_Generic renames Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
   package Elab_Generic renames Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Overload_Generic renames Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
   package Rep_Generic renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   package Tasking_Generic renames Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
   package Access_Generic renames Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;

   type Discriminant_Generic_Final_Row_Id is new Natural;
   No_Discriminant_Generic_Final_Row : constant Discriminant_Generic_Final_Row_Id := 0;

   type Discriminant_Generic_Final_Kind is
     (Discriminant_Generic_Final_Record_Layout,
      Discriminant_Generic_Final_Variant_Record_Layout,
      Discriminant_Generic_Final_Record_Aggregate,
      Discriminant_Generic_Final_Extension_Aggregate,
      Discriminant_Generic_Final_Access_Discriminant,
      Discriminant_Generic_Final_Private_Full_View,
      Discriminant_Generic_Final_Generic_Replay,
      Discriminant_Generic_Final_Generic_Formal_Type,
      Discriminant_Generic_Final_Representation_Clause,
      Discriminant_Generic_Final_Task_Protected_Discriminant,
      Discriminant_Generic_Final_Cross_Unit_Discriminant,
      Discriminant_Generic_Final_Assignment_Conversion,
      Discriminant_Generic_Final_Return_Allocator,
      Discriminant_Generic_Final_Unknown);

   type Discriminant_Generic_Final_Blocker_Family is
     (Discriminant_Generic_Final_Blocker_None,
      Discriminant_Generic_Final_Blocker_Discriminant_Consumer,
      Discriminant_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State,
      Discriminant_Generic_Final_Blocker_Elaboration_Generic_Shared_State,
      Discriminant_Generic_Final_Blocker_Generic_Abstract_Replay,
      Discriminant_Generic_Final_Blocker_Overload_Generic_Shared_State,
      Discriminant_Generic_Final_Blocker_Representation_Generic_Shared_State,
      Discriminant_Generic_Final_Blocker_Tasking_Generic_Shared_State,
      Discriminant_Generic_Final_Blocker_Accessibility_Generic_Shared_State,
      Discriminant_Generic_Final_Blocker_Stabilized_Shared_State_Closure,
      Discriminant_Generic_Final_Blocker_Discriminant_Constraint,
      Discriminant_Generic_Final_Blocker_Variant_Coverage,
      Discriminant_Generic_Final_Blocker_Aggregate_Association,
      Discriminant_Generic_Final_Blocker_Private_Full_View,
      Discriminant_Generic_Final_Blocker_Generic_Substitution,
      Discriminant_Generic_Final_Blocker_Representation_Layout,
      Discriminant_Generic_Final_Blocker_Task_Protected_Effect,
      Discriminant_Generic_Final_Blocker_Access_Discriminant_Lifetime,
      Discriminant_Generic_Final_Blocker_Cross_Unit_Consistency,
      Discriminant_Generic_Final_Blocker_Source_Fingerprint,
      Discriminant_Generic_Final_Blocker_Substitution_Fingerprint,
      Discriminant_Generic_Final_Blocker_Multiple,
      Discriminant_Generic_Final_Blocker_Indeterminate);

   type Discriminant_Generic_Final_Status is
     (Discriminant_Generic_Final_Not_Checked,
      Discriminant_Generic_Final_Legal_Record_Layout_Accepted,
      Discriminant_Generic_Final_Legal_Variant_Record_Layout_Accepted,
      Discriminant_Generic_Final_Legal_Record_Aggregate_Accepted,
      Discriminant_Generic_Final_Legal_Extension_Aggregate_Accepted,
      Discriminant_Generic_Final_Legal_Access_Discriminant_Accepted,
      Discriminant_Generic_Final_Legal_Private_Full_View_Accepted,
      Discriminant_Generic_Final_Legal_Generic_Replay_Accepted,
      Discriminant_Generic_Final_Legal_Generic_Formal_Type_Accepted,
      Discriminant_Generic_Final_Legal_Representation_Clause_Accepted,
      Discriminant_Generic_Final_Legal_Task_Protected_Discriminant_Accepted,
      Discriminant_Generic_Final_Legal_Cross_Unit_Discriminant_Accepted,
      Discriminant_Generic_Final_Legal_Assignment_Conversion_Accepted,
      Discriminant_Generic_Final_Legal_Return_Allocator_Accepted,
      Discriminant_Generic_Final_Missing_Discriminant_Consumer_Row,
      Discriminant_Generic_Final_Discriminant_Consumer_Blocker,
      Discriminant_Generic_Final_Missing_Cross_Unit_Generic_Row,
      Discriminant_Generic_Final_Cross_Unit_Generic_Blocker,
      Discriminant_Generic_Final_Missing_Elaboration_Generic_Row,
      Discriminant_Generic_Final_Elaboration_Generic_Blocker,
      Discriminant_Generic_Final_Missing_Generic_Replay_Row,
      Discriminant_Generic_Final_Generic_Replay_Blocker,
      Discriminant_Generic_Final_Missing_Overload_Generic_Row,
      Discriminant_Generic_Final_Overload_Generic_Blocker,
      Discriminant_Generic_Final_Missing_Representation_Generic_Row,
      Discriminant_Generic_Final_Representation_Generic_Blocker,
      Discriminant_Generic_Final_Missing_Tasking_Generic_Row,
      Discriminant_Generic_Final_Tasking_Generic_Blocker,
      Discriminant_Generic_Final_Missing_Accessibility_Generic_Row,
      Discriminant_Generic_Final_Accessibility_Generic_Blocker,
      Discriminant_Generic_Final_Missing_Stabilized_Closure_Row,
      Discriminant_Generic_Final_Stabilized_Closure_Blocker,
      Discriminant_Generic_Final_Discriminant_Constraint_Blocker,
      Discriminant_Generic_Final_Variant_Coverage_Blocker,
      Discriminant_Generic_Final_Aggregate_Association_Blocker,
      Discriminant_Generic_Final_Private_Full_View_Blocker,
      Discriminant_Generic_Final_Generic_Substitution_Blocker,
      Discriminant_Generic_Final_Representation_Layout_Blocker,
      Discriminant_Generic_Final_Task_Protected_Effect_Blocker,
      Discriminant_Generic_Final_Access_Discriminant_Lifetime_Blocker,
      Discriminant_Generic_Final_Cross_Unit_Consistency_Blocker,
      Discriminant_Generic_Final_Source_Fingerprint_Mismatch,
      Discriminant_Generic_Final_Substitution_Fingerprint_Mismatch,
      Discriminant_Generic_Final_Multiple_Blockers,
      Discriminant_Generic_Final_Indeterminate);

   type Discriminant_Generic_Final_Context is record
      Id                         : Discriminant_Generic_Final_Row_Id := No_Discriminant_Generic_Final_Row;
      Kind                       : Discriminant_Generic_Final_Kind := Discriminant_Generic_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Discriminant_Consumer_Row  : Disc_Final.Discriminant_Consumer_Row_Id := Disc_Final.No_Discriminant_Consumer_Row;
      Discriminant_Consumer_Status : Disc_Final.Discriminant_Consumer_Status := Disc_Final.Discriminant_Consumer_Not_Checked;
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
      Accessibility_Generic_Row  : Access_Generic.Accessibility_Generic_Final_Row_Id := Access_Generic.No_Accessibility_Generic_Final_Row;
      Accessibility_Generic_Status : Access_Generic.Accessibility_Generic_Final_Status := Access_Generic.Accessibility_Generic_Final_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Elaboration_Generic : Boolean := False;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Overload_Generic  : Boolean := False;
      Requires_Representation_Generic : Boolean := False;
      Requires_Tasking_Generic   : Boolean := False;
      Requires_Accessibility_Generic : Boolean := False;
      Requires_Stabilized_Closure : Boolean := False;
      Discriminant_Constraint_Blocker : Boolean := False;
      Variant_Coverage_Blocker   : Boolean := False;
      Aggregate_Association_Blocker : Boolean := False;
      Private_Full_View_Blocker  : Boolean := False;
      Generic_Substitution_Blocker : Boolean := False;
      Representation_Layout_Blocker : Boolean := False;
      Task_Protected_Effect_Blocker : Boolean := False;
      Access_Discriminant_Lifetime_Blocker : Boolean := False;
      Cross_Unit_Consistency_Blocker : Boolean := False;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
   end record;

   type Discriminant_Generic_Final_Row is record
      Id                         : Discriminant_Generic_Final_Row_Id := No_Discriminant_Generic_Final_Row;
      Context                    : Discriminant_Generic_Final_Row_Id := No_Discriminant_Generic_Final_Row;
      Kind                       : Discriminant_Generic_Final_Kind := Discriminant_Generic_Final_Unknown;
      Status                     : Discriminant_Generic_Final_Status := Discriminant_Generic_Final_Not_Checked;
      Blocker_Family             : Discriminant_Generic_Final_Blocker_Family := Discriminant_Generic_Final_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
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
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint                : Natural := 0;
   end record;

   type Discriminant_Generic_Final_Context_Model is private;
   type Discriminant_Generic_Final_Model is private;
   type Discriminant_Generic_Final_Set is private;

   procedure Clear (Model : in out Discriminant_Generic_Final_Context_Model);
   procedure Add_Context (Model : in out Discriminant_Generic_Final_Context_Model; Info : Discriminant_Generic_Final_Context);
   function Context_Count (Model : Discriminant_Generic_Final_Context_Model) return Natural;

   function Build (Contexts : Discriminant_Generic_Final_Context_Model) return Discriminant_Generic_Final_Model;
   function Count (Model : Discriminant_Generic_Final_Model) return Natural;
   function Row_Count (Model : Discriminant_Generic_Final_Model) return Natural renames Count;
   function Row_At (Model : Discriminant_Generic_Final_Model; Index : Positive) return Discriminant_Generic_Final_Row;
   function Accepted_Count (Model : Discriminant_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Discriminant_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Discriminant_Generic_Final_Model) return Natural;
   function Count_By_Status (Model : Discriminant_Generic_Final_Model; Status : Discriminant_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family (Model : Discriminant_Generic_Final_Model; Family : Discriminant_Generic_Final_Blocker_Family) return Natural;
   function Find_By_Node (Model : Discriminant_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Discriminant_Generic_Final_Set;
   function Find_By_Source_Fingerprint (Model : Discriminant_Generic_Final_Model; Fingerprint : Natural) return Discriminant_Generic_Final_Set;
   function Query_Blocker_Family (Model : Discriminant_Generic_Final_Model; Family : Discriminant_Generic_Final_Blocker_Family) return Discriminant_Generic_Final_Set;
   function Query_Count (Set : Discriminant_Generic_Final_Set) return Natural;
   function Query_At (Set : Discriminant_Generic_Final_Set; Index : Positive) return Discriminant_Generic_Final_Row;
   function Stable_Fingerprint (Model : Discriminant_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Discriminant_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Discriminant_Generic_Final_Status) return Boolean;
   function Blocks_Downstream (Status : Discriminant_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors (Positive, Discriminant_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors (Positive, Discriminant_Generic_Final_Row);
   type Discriminant_Generic_Final_Context_Model is record
      Items : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;
   type Discriminant_Generic_Final_Model is record
      Rows : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;
   type Discriminant_Generic_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;
end Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
