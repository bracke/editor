with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
with Editor.Ada_Dispatching_Global_Refinement_Legality;
with Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package Editor.Ada_Generic_Abstract_State_Replay_Legality is

   --  Case 1227 generic abstract/refined-state replay legality.
   --
   --  This package replays abstract/refined state, volatile/atomic, shared-state,
   --  dispatching Global/Depends, and stabilized shared-state evidence through
   --  generic bodies and nested instantiations.  Generic replay conclusions are
   --  accepted only when source/instance backmapping, nested generic closure,
   --  abstract-state consumer evidence, volatile/atomic shared-state evidence,
   --  dispatching refinement evidence, and stabilized shared-state closure all
   --  agree under matching source/substitution fingerprints.

   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   package Nested renames Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
   package Abstract_Consumers renames Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
   package Shared renames Editor.Ada_Volatile_Atomic_Shared_State_Legality;
   package Dispatching renames Editor.Ada_Dispatching_Global_Refinement_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;

   type Generic_Abstract_Replay_Row_Id is new Natural;
   No_Generic_Abstract_Replay_Row : constant Generic_Abstract_Replay_Row_Id := 0;

   type Generic_Abstract_Replay_Kind is
     (Generic_Abstract_Replay_Global_Aspect,
      Generic_Abstract_Replay_Depends_Aspect,
      Generic_Abstract_Replay_Refined_State,
      Generic_Abstract_Replay_Volatile_Effect,
      Generic_Abstract_Replay_Atomic_Effect,
      Generic_Abstract_Replay_Shared_Variable_Effect,
      Generic_Abstract_Replay_Dispatching_Effect,
      Generic_Abstract_Replay_Formal_Package_State,
      Generic_Abstract_Replay_Nested_Instance_State,
      Generic_Abstract_Replay_Unknown);

   type Generic_Abstract_Replay_Blocker_Family is
     (Generic_Abstract_Replay_Blocker_None,
      Generic_Abstract_Replay_Blocker_Source_Instance_Backmap,
      Generic_Abstract_Replay_Blocker_Nested_Generic_Closure,
      Generic_Abstract_Replay_Blocker_Abstract_State_Consumer,
      Generic_Abstract_Replay_Blocker_Volatile_Atomic_Shared_State,
      Generic_Abstract_Replay_Blocker_Dispatching_Global,
      Generic_Abstract_Replay_Blocker_Stabilized_Shared_State_Closure,
      Generic_Abstract_Replay_Blocker_Formal_Actual_Substitution,
      Generic_Abstract_Replay_Blocker_Source_Fingerprint,
      Generic_Abstract_Replay_Blocker_Substitution_Fingerprint,
      Generic_Abstract_Replay_Blocker_Multiple,
      Generic_Abstract_Replay_Blocker_Indeterminate);

   type Generic_Abstract_Replay_Status is
     (Generic_Abstract_Replay_Not_Checked,
      Generic_Abstract_Replay_Legal_Global_Aspect_Accepted,
      Generic_Abstract_Replay_Legal_Depends_Aspect_Accepted,
      Generic_Abstract_Replay_Legal_Refined_State_Accepted,
      Generic_Abstract_Replay_Legal_Volatile_Effect_Accepted,
      Generic_Abstract_Replay_Legal_Atomic_Effect_Accepted,
      Generic_Abstract_Replay_Legal_Shared_Variable_Effect_Accepted,
      Generic_Abstract_Replay_Legal_Dispatching_Effect_Accepted,
      Generic_Abstract_Replay_Legal_Formal_Package_State_Accepted,
      Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted,
      Generic_Abstract_Replay_Missing_Backmap_Row,
      Generic_Abstract_Replay_Backmap_Blocker,
      Generic_Abstract_Replay_Missing_Nested_Closure_Row,
      Generic_Abstract_Replay_Nested_Closure_Blocker,
      Generic_Abstract_Replay_Missing_Abstract_Consumer_Row,
      Generic_Abstract_Replay_Abstract_Consumer_Blocker,
      Generic_Abstract_Replay_Missing_Shared_State_Row,
      Generic_Abstract_Replay_Shared_State_Blocker,
      Generic_Abstract_Replay_Missing_Dispatching_Row,
      Generic_Abstract_Replay_Dispatching_Blocker,
      Generic_Abstract_Replay_Missing_Stabilized_Closure_Row,
      Generic_Abstract_Replay_Stabilized_Closure_Blocker,
      Generic_Abstract_Replay_Formal_Actual_Missing,
      Generic_Abstract_Replay_Formal_Actual_Mode_Mismatch,
      Generic_Abstract_Replay_Formal_Actual_State_Mismatch,
      Generic_Abstract_Replay_Source_Fingerprint_Mismatch,
      Generic_Abstract_Replay_Substitution_Fingerprint_Mismatch,
      Generic_Abstract_Replay_Multiple_Blockers,
      Generic_Abstract_Replay_Indeterminate);

   type Generic_Abstract_Replay_Context is record
      Id                         : Generic_Abstract_Replay_Row_Id := No_Generic_Abstract_Replay_Row;
      Kind                       : Generic_Abstract_Replay_Kind := Generic_Abstract_Replay_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name                : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Backmap_Row                : Backmap.Generic_Backmap_Row_Id := Backmap.No_Generic_Backmap_Row;
      Backmap_Status             : Backmap.Generic_Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      Nested_Row                 : Nested.Nested_Generic_Closure_Row_Id := Nested.No_Nested_Generic_Closure_Row;
      Nested_Status              : Nested.Nested_Generic_Closure_Status := Nested.Nested_Generic_Not_Checked;
      Abstract_Consumer_Row      : Abstract_Consumers.Abstract_State_Consumer_Row_Id := Abstract_Consumers.No_Abstract_State_Consumer_Row;
      Abstract_Consumer_Status   : Abstract_Consumers.Abstract_State_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Not_Checked;
      Shared_State_Row           : Shared.Shared_State_Row_Id := Shared.No_Shared_State_Row;
      Shared_State_Status        : Shared.Shared_State_Status := Shared.Shared_State_Not_Checked;
      Dispatching_Row            : Dispatching.Dispatching_Global_Row_Id := Dispatching.No_Dispatching_Global_Row;
      Dispatching_Status         : Dispatching.Dispatching_Global_Status := Dispatching.Dispatching_Global_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Nested_Closure    : Boolean := False;
      Requires_Abstract_Consumer : Boolean := True;
      Requires_Shared_State      : Boolean := False;
      Requires_Dispatching       : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Formal_Actual_Missing      : Boolean := False;
      Formal_Actual_Mode_Mismatch : Boolean := False;
      Formal_Actual_State_Mismatch : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Generic_Abstract_Replay_Row is record
      Id                         : Generic_Abstract_Replay_Row_Id := No_Generic_Abstract_Replay_Row;
      Context                    : Generic_Abstract_Replay_Row_Id := No_Generic_Abstract_Replay_Row;
      Kind                       : Generic_Abstract_Replay_Kind := Generic_Abstract_Replay_Unknown;
      Status                     : Generic_Abstract_Replay_Status := Generic_Abstract_Replay_Not_Checked;
      Blocker_Family             : Generic_Abstract_Replay_Blocker_Family := Generic_Abstract_Replay_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Name                : Ada.Strings.Unbounded.Unbounded_String;
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

   type Generic_Abstract_Replay_Context_Model is private;
   type Generic_Abstract_Replay_Model is private;
   type Generic_Abstract_Replay_Set is private;

   procedure Clear (Model : in out Generic_Abstract_Replay_Context_Model);
   procedure Add_Context
     (Model : in out Generic_Abstract_Replay_Context_Model;
      Info  : Generic_Abstract_Replay_Context);
   function Context_Count (Model : Generic_Abstract_Replay_Context_Model) return Natural;
   function Context_At
     (Model : Generic_Abstract_Replay_Context_Model;
      Index : Positive) return Generic_Abstract_Replay_Context;
   function Fingerprint (Model : Generic_Abstract_Replay_Context_Model) return Natural;

   function Build (Contexts : Generic_Abstract_Replay_Context_Model) return Generic_Abstract_Replay_Model;
   function Count (Model : Generic_Abstract_Replay_Model) return Natural;
   function Row_Count (Model : Generic_Abstract_Replay_Model) return Natural renames Count;
   function Row_At
     (Model : Generic_Abstract_Replay_Model;
      Index : Positive) return Generic_Abstract_Replay_Row;

   function Query_Count (Set : Generic_Abstract_Replay_Set) return Natural;
   function Query_At
     (Set   : Generic_Abstract_Replay_Set;
      Index : Positive) return Generic_Abstract_Replay_Row;
   function Query_Status
     (Model  : Generic_Abstract_Replay_Model;
      Status : Generic_Abstract_Replay_Status) return Generic_Abstract_Replay_Set;
   function Query_Blocker_Family
     (Model  : Generic_Abstract_Replay_Model;
      Family : Generic_Abstract_Replay_Blocker_Family) return Generic_Abstract_Replay_Set;
   function Find_By_Node
     (Model : Generic_Abstract_Replay_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Abstract_Replay_Set;
   function Find_By_Source_Fingerprint
     (Model              : Generic_Abstract_Replay_Model;
      Source_Fingerprint : Natural) return Generic_Abstract_Replay_Set;

   function Count_By_Status
     (Model  : Generic_Abstract_Replay_Model;
      Status : Generic_Abstract_Replay_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Generic_Abstract_Replay_Model;
      Family : Generic_Abstract_Replay_Blocker_Family) return Natural;
   function Accepted_Count (Model : Generic_Abstract_Replay_Model) return Natural;
   function Blocked_Count (Model : Generic_Abstract_Replay_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Abstract_Replay_Model) return Natural;
   function Stable_Fingerprint (Model : Generic_Abstract_Replay_Model) return Natural;

   function Is_Accepted (Status : Generic_Abstract_Replay_Status) return Boolean;
   function Is_Blocked (Status : Generic_Abstract_Replay_Status) return Boolean;
   function Is_Indeterminate (Status : Generic_Abstract_Replay_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Abstract_Replay_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Abstract_Replay_Row);

   type Generic_Abstract_Replay_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Generic_Abstract_Replay_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Generic_Abstract_Replay_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Abstract_State_Replay_Legality;
