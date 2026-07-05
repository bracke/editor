with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
with Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

package Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality is

   --  Case 1231 cross-unit generic/shared-state final closure legality.
   --
   --  This package closes the dependency boundary for the generic/shared-state
   --  final chain.  It requires cross-unit shared-state closure, generic
   --  abstract-state replay, overload/generic shared-state evidence,
   --  representation/generic shared-state evidence, tasking/generic
   --  shared-state evidence, abstract-state consumer evidence, and stabilized
   --  shared-state closure to agree before a cross-unit conclusion is current.
   --  Dependency, view, generic, state-visibility, fingerprint, and
   --  family-specific blockers are preserved as first-class semantic blockers.

   package Abstract_Consumers renames Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
   package Cross_Shared renames Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Overload_Generic renames Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
   package Rep_Generic renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;
   package Tasking_Generic renames Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

   type Cross_Unit_Generic_Final_Row_Id is new Natural;
   No_Cross_Unit_Generic_Final_Row : constant Cross_Unit_Generic_Final_Row_Id := 0;

   type Cross_Unit_Generic_Final_Kind is
     (Cross_Unit_Generic_Final_Local,
      Cross_Unit_Generic_Final_With_Use,
      Cross_Unit_Generic_Final_Private_Full_View,
      Cross_Unit_Generic_Final_Limited_View,
      Cross_Unit_Generic_Final_Child_Private_Child,
      Cross_Unit_Generic_Final_Generic_Instance,
      Cross_Unit_Generic_Final_Generic_Body,
      Cross_Unit_Generic_Final_Abstract_State,
      Cross_Unit_Generic_Final_Volatile_Atomic,
      Cross_Unit_Generic_Final_Overload_Type,
      Cross_Unit_Generic_Final_Representation,
      Cross_Unit_Generic_Final_Tasking_Protected,
      Cross_Unit_Generic_Final_Unknown);

   type Cross_Unit_Generic_Dependency_State is
     (Generic_Dependency_Local,
      Generic_Dependency_With_Visible,
      Generic_Dependency_Use_Visible,
      Generic_Dependency_Private_Full_View,
      Generic_Dependency_Limited_View,
      Generic_Dependency_Child_Visible,
      Generic_Dependency_Private_Child_Visible,
      Generic_Dependency_Generic_Instance_Visible,
      Generic_Dependency_Generic_Body_Visible,
      Generic_Dependency_Missing,
      Generic_Dependency_Ambiguous,
      Generic_Dependency_Overflow,
      Generic_Dependency_Stale,
      Generic_Dependency_Unknown);

   type Cross_Unit_Generic_Final_Blocker_Family is
     (Cross_Unit_Generic_Final_Blocker_None,
      Cross_Unit_Generic_Final_Blocker_Cross_Unit_Shared_State,
      Cross_Unit_Generic_Final_Blocker_Generic_Abstract_Replay,
      Cross_Unit_Generic_Final_Blocker_Overload_Generic_Shared_State,
      Cross_Unit_Generic_Final_Blocker_Representation_Generic_Shared_State,
      Cross_Unit_Generic_Final_Blocker_Tasking_Generic_Shared_State,
      Cross_Unit_Generic_Final_Blocker_Abstract_State_Consumer,
      Cross_Unit_Generic_Final_Blocker_Stabilized_Shared_State_Closure,
      Cross_Unit_Generic_Final_Blocker_Dependency,
      Cross_Unit_Generic_Final_Blocker_View_Barrier,
      Cross_Unit_Generic_Final_Blocker_Generic_Backmapping,
      Cross_Unit_Generic_Final_Blocker_State_Visibility,
      Cross_Unit_Generic_Final_Blocker_Generic_Body,
      Cross_Unit_Generic_Final_Blocker_Dispatching_Global,
      Cross_Unit_Generic_Final_Blocker_Volatile_Atomic,
      Cross_Unit_Generic_Final_Blocker_Representation_Effect,
      Cross_Unit_Generic_Final_Blocker_Tasking_Effect,
      Cross_Unit_Generic_Final_Blocker_Source_Fingerprint,
      Cross_Unit_Generic_Final_Blocker_Substitution_Fingerprint,
      Cross_Unit_Generic_Final_Blocker_Multiple,
      Cross_Unit_Generic_Final_Blocker_Indeterminate);

   type Cross_Unit_Generic_Final_Status is
     (Cross_Unit_Generic_Final_Not_Checked,
      Cross_Unit_Generic_Final_Legal_Local_Accepted,
      Cross_Unit_Generic_Final_Legal_With_Use_Accepted,
      Cross_Unit_Generic_Final_Legal_Private_Full_View_Accepted,
      Cross_Unit_Generic_Final_Legal_Limited_View_Accepted,
      Cross_Unit_Generic_Final_Legal_Child_Private_Child_Accepted,
      Cross_Unit_Generic_Final_Legal_Generic_Instance_Accepted,
      Cross_Unit_Generic_Final_Legal_Generic_Body_Accepted,
      Cross_Unit_Generic_Final_Legal_Abstract_State_Accepted,
      Cross_Unit_Generic_Final_Legal_Volatile_Atomic_Accepted,
      Cross_Unit_Generic_Final_Legal_Overload_Type_Accepted,
      Cross_Unit_Generic_Final_Legal_Representation_Accepted,
      Cross_Unit_Generic_Final_Legal_Tasking_Protected_Accepted,
      Cross_Unit_Generic_Final_Missing_Cross_Shared_Row,
      Cross_Unit_Generic_Final_Cross_Shared_Blocker,
      Cross_Unit_Generic_Final_Missing_Generic_Replay_Row,
      Cross_Unit_Generic_Final_Generic_Replay_Blocker,
      Cross_Unit_Generic_Final_Missing_Overload_Generic_Row,
      Cross_Unit_Generic_Final_Overload_Generic_Blocker,
      Cross_Unit_Generic_Final_Missing_Representation_Generic_Row,
      Cross_Unit_Generic_Final_Representation_Generic_Blocker,
      Cross_Unit_Generic_Final_Missing_Tasking_Generic_Row,
      Cross_Unit_Generic_Final_Tasking_Generic_Blocker,
      Cross_Unit_Generic_Final_Missing_Abstract_Consumer_Row,
      Cross_Unit_Generic_Final_Abstract_Consumer_Blocker,
      Cross_Unit_Generic_Final_Missing_Stabilized_Closure_Row,
      Cross_Unit_Generic_Final_Stabilized_Closure_Blocker,
      Cross_Unit_Generic_Final_Missing_Dependency,
      Cross_Unit_Generic_Final_Ambiguous_Dependency,
      Cross_Unit_Generic_Final_Dependency_Overflow,
      Cross_Unit_Generic_Final_Stale_Dependency,
      Cross_Unit_Generic_Final_Limited_View_Barrier,
      Cross_Unit_Generic_Final_Private_View_Barrier,
      Cross_Unit_Generic_Final_Child_Visibility_Blocker,
      Cross_Unit_Generic_Final_Generic_Body_Unavailable,
      Cross_Unit_Generic_Final_Generic_Backmapping_Blocker,
      Cross_Unit_Generic_Final_State_Visibility_Blocker,
      Cross_Unit_Generic_Final_Dispatching_Global_Blocker,
      Cross_Unit_Generic_Final_Volatile_Atomic_Blocker,
      Cross_Unit_Generic_Final_Representation_Effect_Blocker,
      Cross_Unit_Generic_Final_Tasking_Effect_Blocker,
      Cross_Unit_Generic_Final_Source_Fingerprint_Mismatch,
      Cross_Unit_Generic_Final_Substitution_Fingerprint_Mismatch,
      Cross_Unit_Generic_Final_Multiple_Blockers,
      Cross_Unit_Generic_Final_Indeterminate);

   type Cross_Unit_Generic_Final_Context is record
      Id                         : Cross_Unit_Generic_Final_Row_Id := No_Cross_Unit_Generic_Final_Row;
      Kind                       : Cross_Unit_Generic_Final_Kind := Cross_Unit_Generic_Final_Unknown;
      Dependency                 : Cross_Unit_Generic_Dependency_State := Generic_Dependency_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dependency_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      State_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Shared_Row           : Cross_Shared.Cross_Unit_Shared_State_Row_Id := Cross_Shared.No_Cross_Unit_Shared_State_Row;
      Cross_Shared_Status        : Cross_Shared.Cross_Unit_Shared_State_Status := Cross_Shared.Cross_Unit_Shared_State_Not_Checked;
      Generic_Replay_Row         : Generic_Replay.Generic_Abstract_Replay_Row_Id := Generic_Replay.No_Generic_Abstract_Replay_Row;
      Generic_Replay_Status      : Generic_Replay.Generic_Abstract_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Not_Checked;
      Overload_Generic_Row       : Overload_Generic.Overload_Generic_Final_Row_Id := Overload_Generic.No_Overload_Generic_Final_Row;
      Overload_Generic_Status    : Overload_Generic.Overload_Generic_Final_Status := Overload_Generic.Overload_Generic_Final_Not_Checked;
      Representation_Generic_Row : Rep_Generic.Representation_Generic_Final_Row_Id := Rep_Generic.No_Representation_Generic_Final_Row;
      Representation_Generic_Status : Rep_Generic.Representation_Generic_Final_Status := Rep_Generic.Representation_Generic_Final_Not_Checked;
      Tasking_Generic_Row        : Tasking_Generic.Tasking_Generic_Final_Row_Id := Tasking_Generic.No_Tasking_Generic_Final_Row;
      Tasking_Generic_Status     : Tasking_Generic.Tasking_Generic_Final_Status := Tasking_Generic.Tasking_Generic_Final_Not_Checked;
      Abstract_Consumer_Row      : Abstract_Consumers.Abstract_State_Consumer_Row_Id := Abstract_Consumers.No_Abstract_State_Consumer_Row;
      Abstract_Consumer_Status   : Abstract_Consumers.Abstract_State_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Cross_Shared      : Boolean := True;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Overload_Generic  : Boolean := False;
      Requires_Representation_Generic : Boolean := False;
      Requires_Tasking_Generic   : Boolean := False;
      Requires_Abstract_Consumer : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Limited_View_Barrier       : Boolean := False;
      Private_View_Barrier       : Boolean := False;
      Child_Visibility_Blocker   : Boolean := False;
      Generic_Body_Unavailable   : Boolean := False;
      Generic_Backmapping_Blocker : Boolean := False;
      State_Visibility_Blocker   : Boolean := False;
      Dispatching_Global_Blocker : Boolean := False;
      Volatile_Atomic_Blocker    : Boolean := False;
      Representation_Effect_Blocker : Boolean := False;
      Tasking_Effect_Blocker     : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Cross_Unit_Generic_Final_Row is record
      Id                         : Cross_Unit_Generic_Final_Row_Id := No_Cross_Unit_Generic_Final_Row;
      Context                    : Cross_Unit_Generic_Final_Row_Id := No_Cross_Unit_Generic_Final_Row;
      Kind                       : Cross_Unit_Generic_Final_Kind := Cross_Unit_Generic_Final_Unknown;
      Dependency                 : Cross_Unit_Generic_Dependency_State := Generic_Dependency_Unknown;
      Status                     : Cross_Unit_Generic_Final_Status := Cross_Unit_Generic_Final_Not_Checked;
      Blocker_Family             : Cross_Unit_Generic_Final_Blocker_Family := Cross_Unit_Generic_Final_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
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

   type Cross_Unit_Generic_Final_Context_Model is private;
   type Cross_Unit_Generic_Final_Model is private;
   type Cross_Unit_Generic_Final_Set is private;

   procedure Clear (Model : in out Cross_Unit_Generic_Final_Context_Model);
   procedure Add_Context (Model : in out Cross_Unit_Generic_Final_Context_Model; Info : Cross_Unit_Generic_Final_Context);
   function Context_Count (Model : Cross_Unit_Generic_Final_Context_Model) return Natural;
   function Context_At (Model : Cross_Unit_Generic_Final_Context_Model; Index : Positive) return Cross_Unit_Generic_Final_Context;
   function Fingerprint (Model : Cross_Unit_Generic_Final_Context_Model) return Natural;

   function Build (Contexts : Cross_Unit_Generic_Final_Context_Model) return Cross_Unit_Generic_Final_Model;
   function Count (Model : Cross_Unit_Generic_Final_Model) return Natural;
   function Row_Count (Model : Cross_Unit_Generic_Final_Model) return Natural renames Count;
   function Row_At (Model : Cross_Unit_Generic_Final_Model; Index : Positive) return Cross_Unit_Generic_Final_Row;

   function Query_Count (Set : Cross_Unit_Generic_Final_Set) return Natural;
   function Query_At (Set : Cross_Unit_Generic_Final_Set; Index : Positive) return Cross_Unit_Generic_Final_Row;
   function Query_Status (Model : Cross_Unit_Generic_Final_Model; Status : Cross_Unit_Generic_Final_Status) return Cross_Unit_Generic_Final_Set;
   function Query_Blocker_Family (Model : Cross_Unit_Generic_Final_Model; Family : Cross_Unit_Generic_Final_Blocker_Family) return Cross_Unit_Generic_Final_Set;
   function Find_By_Node (Model : Cross_Unit_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_Generic_Final_Set;
   function Find_By_Source_Fingerprint (Model : Cross_Unit_Generic_Final_Model; Source_Fingerprint : Natural) return Cross_Unit_Generic_Final_Set;

   function Count_By_Status (Model : Cross_Unit_Generic_Final_Model; Status : Cross_Unit_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family (Model : Cross_Unit_Generic_Final_Model; Family : Cross_Unit_Generic_Final_Blocker_Family) return Natural;
   function Accepted_Count (Model : Cross_Unit_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Cross_Unit_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Cross_Unit_Generic_Final_Model) return Natural;
   function Stable_Fingerprint (Model : Cross_Unit_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Cross_Unit_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Cross_Unit_Generic_Final_Status) return Boolean;
   function Is_Indeterminate (Status : Cross_Unit_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Cross_Unit_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Cross_Unit_Generic_Final_Row);

   type Cross_Unit_Generic_Final_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Cross_Unit_Generic_Final_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Cross_Unit_Generic_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
