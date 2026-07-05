with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
with Editor.Ada_Dispatching_Global_Refinement_Legality;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;

package Editor.Ada_Overload_Generic_Shared_State_Final_Legality is

   --  Case 1228 overload/generic/shared-state final RM edge legality.
   --
   --  This package consumes the final overload shared-state RM layer together
   --  with generic abstract-state replay, dispatching Global/Depends
   --  refinement, volatile/atomic representation consumers, abstract-state
   --  consumers, and stabilized shared-state closure.  It prevents final
   --  overload/type conclusions for prefixed calls, dispatching calls,
   --  access-to-subprogram calls, inherited or renamed primitives, generic
   --  formal subprogram calls, class-wide controlling-result selections, and
   --  universal numeric operators from becoming confidently legal while their
   --  generic replay, abstract/refined-state, shared-state, representation,
   --  dispatching, or closure prerequisites remain unresolved.

   package Overload renames Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Dispatching renames Editor.Ada_Dispatching_Global_Refinement_Legality;
   package Volatile_Rep renames Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;
   package Abstract_Consumers renames Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;

   type Overload_Generic_Final_Row_Id is new Natural;
   No_Overload_Generic_Final_Row : constant Overload_Generic_Final_Row_Id := 0;

   type Overload_Generic_Final_Kind is
     (Overload_Generic_Final_Prefixed_Call,
      Overload_Generic_Final_Dispatching_Call,
      Overload_Generic_Final_Access_Subprogram_Call,
      Overload_Generic_Final_Class_Wide_Result,
      Overload_Generic_Final_Inherited_Primitive,
      Overload_Generic_Final_Renamed_Primitive,
      Overload_Generic_Final_Generic_Formal_Subprogram,
      Overload_Generic_Final_Universal_Numeric_Operator,
      Overload_Generic_Final_Abstract_State_Effect,
      Overload_Generic_Final_Volatile_Atomic_Effect,
      Overload_Generic_Final_Unknown);

   type Overload_Generic_Final_Blocker_Family is
     (Overload_Generic_Final_Blocker_None,
      Overload_Generic_Final_Blocker_Overload_Shared_State,
      Overload_Generic_Final_Blocker_Generic_Abstract_Replay,
      Overload_Generic_Final_Blocker_Dispatching_Global,
      Overload_Generic_Final_Blocker_Volatile_Atomic_Representation,
      Overload_Generic_Final_Blocker_Abstract_State_Consumer,
      Overload_Generic_Final_Blocker_Stabilized_Shared_State_Closure,
      Overload_Generic_Final_Blocker_Access_Profile_Effect,
      Overload_Generic_Final_Blocker_Dispatching_Effect,
      Overload_Generic_Final_Blocker_Controlling_Result_State,
      Overload_Generic_Final_Blocker_Universal_Numeric_State,
      Overload_Generic_Final_Blocker_Source_Fingerprint,
      Overload_Generic_Final_Blocker_Substitution_Fingerprint,
      Overload_Generic_Final_Blocker_Multiple,
      Overload_Generic_Final_Blocker_Indeterminate);

   type Overload_Generic_Final_Status is
     (Overload_Generic_Final_Not_Checked,
      Overload_Generic_Final_Legal_Prefixed_Call_Accepted,
      Overload_Generic_Final_Legal_Dispatching_Call_Accepted,
      Overload_Generic_Final_Legal_Access_Subprogram_Call_Accepted,
      Overload_Generic_Final_Legal_Class_Wide_Result_Accepted,
      Overload_Generic_Final_Legal_Inherited_Primitive_Accepted,
      Overload_Generic_Final_Legal_Renamed_Primitive_Accepted,
      Overload_Generic_Final_Legal_Generic_Formal_Subprogram_Accepted,
      Overload_Generic_Final_Legal_Universal_Numeric_Operator_Accepted,
      Overload_Generic_Final_Legal_Abstract_State_Effect_Accepted,
      Overload_Generic_Final_Legal_Volatile_Atomic_Effect_Accepted,
      Overload_Generic_Final_Missing_Overload_Row,
      Overload_Generic_Final_Overload_Blocker,
      Overload_Generic_Final_Missing_Generic_Replay_Row,
      Overload_Generic_Final_Generic_Replay_Blocker,
      Overload_Generic_Final_Missing_Dispatching_Row,
      Overload_Generic_Final_Dispatching_Blocker,
      Overload_Generic_Final_Missing_Volatile_Representation_Row,
      Overload_Generic_Final_Volatile_Representation_Blocker,
      Overload_Generic_Final_Missing_Abstract_Consumer_Row,
      Overload_Generic_Final_Abstract_Consumer_Blocker,
      Overload_Generic_Final_Missing_Stabilized_Closure_Row,
      Overload_Generic_Final_Stabilized_Closure_Blocker,
      Overload_Generic_Final_Access_Profile_Effect_Mismatch,
      Overload_Generic_Final_Dispatching_Effect_Mismatch,
      Overload_Generic_Final_Controlling_Result_State_Mismatch,
      Overload_Generic_Final_Universal_Numeric_State_Ambiguous,
      Overload_Generic_Final_Source_Fingerprint_Mismatch,
      Overload_Generic_Final_Substitution_Fingerprint_Mismatch,
      Overload_Generic_Final_Multiple_Blockers,
      Overload_Generic_Final_Indeterminate);

   type Overload_Generic_Final_Context is record
      Id                         : Overload_Generic_Final_Row_Id := No_Overload_Generic_Final_Row;
      Kind                       : Overload_Generic_Final_Kind := Overload_Generic_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Overload_Row               : Overload.Overload_Shared_State_Row_Id := Overload.No_Overload_Shared_State_Row;
      Overload_Status            : Overload.Overload_Shared_State_Status := Overload.Overload_Shared_State_Not_Checked;
      Generic_Replay_Row         : Generic_Replay.Generic_Abstract_Replay_Row_Id := Generic_Replay.No_Generic_Abstract_Replay_Row;
      Generic_Replay_Status      : Generic_Replay.Generic_Abstract_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Not_Checked;
      Dispatching_Row            : Dispatching.Dispatching_Global_Row_Id := Dispatching.No_Dispatching_Global_Row;
      Dispatching_Status         : Dispatching.Dispatching_Global_Status := Dispatching.Dispatching_Global_Not_Checked;
      Volatile_Representation_Row : Volatile_Rep.Volatile_Atomic_Representation_Row_Id := Volatile_Rep.No_Volatile_Atomic_Representation_Row;
      Volatile_Representation_Status : Volatile_Rep.Volatile_Atomic_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Not_Checked;
      Abstract_Consumer_Row      : Abstract_Consumers.Abstract_State_Consumer_Row_Id := Abstract_Consumers.No_Abstract_State_Consumer_Row;
      Abstract_Consumer_Status   : Abstract_Consumers.Abstract_State_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Overload          : Boolean := True;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Dispatching       : Boolean := False;
      Requires_Volatile_Representation : Boolean := False;
      Requires_Abstract_Consumer : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Access_Profile_Effect_Mismatch : Boolean := False;
      Dispatching_Effect_Mismatch : Boolean := False;
      Controlling_Result_State_Mismatch : Boolean := False;
      Universal_Numeric_State_Ambiguous : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Overload_Generic_Final_Row is record
      Id                         : Overload_Generic_Final_Row_Id := No_Overload_Generic_Final_Row;
      Context                    : Overload_Generic_Final_Row_Id := No_Overload_Generic_Final_Row;
      Kind                       : Overload_Generic_Final_Kind := Overload_Generic_Final_Unknown;
      Status                     : Overload_Generic_Final_Status := Overload_Generic_Final_Not_Checked;
      Blocker_Family             : Overload_Generic_Final_Blocker_Family := Overload_Generic_Final_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
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

   type Overload_Generic_Final_Context_Model is private;
   type Overload_Generic_Final_Model is private;
   type Overload_Generic_Final_Set is private;

   procedure Clear (Model : in out Overload_Generic_Final_Context_Model);
   procedure Add_Context
     (Model : in out Overload_Generic_Final_Context_Model;
      Info  : Overload_Generic_Final_Context);
   function Context_Count (Model : Overload_Generic_Final_Context_Model) return Natural;
   function Context_At
     (Model : Overload_Generic_Final_Context_Model;
      Index : Positive) return Overload_Generic_Final_Context;
   function Fingerprint (Model : Overload_Generic_Final_Context_Model) return Natural;

   function Build (Contexts : Overload_Generic_Final_Context_Model) return Overload_Generic_Final_Model;
   function Count (Model : Overload_Generic_Final_Model) return Natural;
   function Row_Count (Model : Overload_Generic_Final_Model) return Natural renames Count;
   function Row_At
     (Model : Overload_Generic_Final_Model;
      Index : Positive) return Overload_Generic_Final_Row;

   function Query_Count (Set : Overload_Generic_Final_Set) return Natural;
   function Query_At
     (Set   : Overload_Generic_Final_Set;
      Index : Positive) return Overload_Generic_Final_Row;
   function Query_Status
     (Model  : Overload_Generic_Final_Model;
      Status : Overload_Generic_Final_Status) return Overload_Generic_Final_Set;
   function Query_Blocker_Family
     (Model  : Overload_Generic_Final_Model;
      Family : Overload_Generic_Final_Blocker_Family) return Overload_Generic_Final_Set;
   function Find_By_Node
     (Model : Overload_Generic_Final_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Generic_Final_Set;
   function Find_By_Source_Fingerprint
     (Model              : Overload_Generic_Final_Model;
      Source_Fingerprint : Natural) return Overload_Generic_Final_Set;

   function Count_By_Status
     (Model  : Overload_Generic_Final_Model;
      Status : Overload_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Overload_Generic_Final_Model;
      Family : Overload_Generic_Final_Blocker_Family) return Natural;
   function Accepted_Count (Model : Overload_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Overload_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Overload_Generic_Final_Model) return Natural;
   function Stable_Fingerprint (Model : Overload_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Overload_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Overload_Generic_Final_Status) return Boolean;
   function Is_Indeterminate (Status : Overload_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_Generic_Final_Row);

   type Overload_Generic_Final_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Generic_Final_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Overload_Generic_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
