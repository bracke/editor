with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Abstract_State_Refined_State_Legality;
with Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
with Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
with Editor.Ada_Representation_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Shared_State_Final_Legality;
with Editor.Ada_Volatile_Atomic_Shared_State_Legality;

package Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality is

   --  Pass1224 abstract/refined state consumer integration legality.
   --
   --  This package makes abstract/refined-state evidence a mandatory consumer
   --  prerequisite for the remaining hard semantic consumers that depend on
   --  state proof: Global/Depends refinements, dispatching effects, generic
   --  replay, representation/freezing effects, tasking/protected operations,
   --  volatile/atomic/shared-variable effects, cross-unit closure, and the
   --  shared-state stabilized closure boundary.  It preserves the originating
   --  blocker family instead of flattening state failures into a generic
   --  diagnostic or projection status.

   package States renames Editor.Ada_Abstract_State_Refined_State_Legality;
   package Shared renames Editor.Ada_Volatile_Atomic_Shared_State_Legality;
   package Overload_State renames Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
   package Rep_State renames Editor.Ada_Representation_Shared_State_Final_Legality;
   package Tasking_State renames Editor.Ada_Tasking_Shared_State_Final_Legality;
   package Cross_Unit_State renames Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
   package Stabilized_State renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;

   type Abstract_State_Consumer_Row_Id is new Natural;
   No_Abstract_State_Consumer_Row : constant Abstract_State_Consumer_Row_Id := 0;

   type Abstract_State_Consumer_Kind is
     (Abstract_State_Consumer_Global_Refinement,
      Abstract_State_Consumer_Depends_Refinement,
      Abstract_State_Consumer_Dispatching_Effect,
      Abstract_State_Consumer_Generic_Replay,
      Abstract_State_Consumer_Representation_Freezing,
      Abstract_State_Consumer_Tasking_Protected,
      Abstract_State_Consumer_Volatile_Atomic,
      Abstract_State_Consumer_Cross_Unit_Closure,
      Abstract_State_Consumer_Shared_State_Stabilized_Closure,
      Abstract_State_Consumer_Unknown);

   type Abstract_State_Consumer_Blocker_Family is
     (Abstract_State_Consumer_Blocker_None,
      Abstract_State_Consumer_Blocker_Abstract_State,
      Abstract_State_Consumer_Blocker_Shared_State,
      Abstract_State_Consumer_Blocker_Overload_Dispatching,
      Abstract_State_Consumer_Blocker_Representation_Freezing,
      Abstract_State_Consumer_Blocker_Tasking_Protected,
      Abstract_State_Consumer_Blocker_Cross_Unit,
      Abstract_State_Consumer_Blocker_Stabilized_Closure,
      Abstract_State_Consumer_Blocker_Source_Fingerprint,
      Abstract_State_Consumer_Blocker_Multiple,
      Abstract_State_Consumer_Blocker_Indeterminate);

   type Abstract_State_Consumer_Status is
     (Abstract_State_Consumer_Not_Checked,
      Abstract_State_Consumer_Legal_Global_Refinement_Accepted,
      Abstract_State_Consumer_Legal_Depends_Refinement_Accepted,
      Abstract_State_Consumer_Legal_Dispatching_Effect_Accepted,
      Abstract_State_Consumer_Legal_Generic_Replay_Accepted,
      Abstract_State_Consumer_Legal_Representation_Freezing_Accepted,
      Abstract_State_Consumer_Legal_Tasking_Protected_Accepted,
      Abstract_State_Consumer_Legal_Volatile_Atomic_Accepted,
      Abstract_State_Consumer_Legal_Cross_Unit_Closure_Accepted,
      Abstract_State_Consumer_Legal_Shared_State_Stabilized_Closure_Accepted,
      Abstract_State_Consumer_Missing_Abstract_State_Row,
      Abstract_State_Consumer_Abstract_State_Blocker,
      Abstract_State_Consumer_Missing_Shared_State_Row,
      Abstract_State_Consumer_Shared_State_Blocker,
      Abstract_State_Consumer_Missing_Overload_State_Row,
      Abstract_State_Consumer_Overload_State_Blocker,
      Abstract_State_Consumer_Missing_Representation_State_Row,
      Abstract_State_Consumer_Representation_State_Blocker,
      Abstract_State_Consumer_Missing_Tasking_State_Row,
      Abstract_State_Consumer_Tasking_State_Blocker,
      Abstract_State_Consumer_Missing_Cross_Unit_State_Row,
      Abstract_State_Consumer_Cross_Unit_State_Blocker,
      Abstract_State_Consumer_Missing_Stabilized_Closure_Row,
      Abstract_State_Consumer_Stabilized_Closure_Blocker,
      Abstract_State_Consumer_Global_Mode_Blocker,
      Abstract_State_Consumer_Depends_Edge_Blocker,
      Abstract_State_Consumer_Dispatching_Effect_Blocker,
      Abstract_State_Consumer_Generic_Replay_Blocker,
      Abstract_State_Consumer_Representation_Freezing_Blocker,
      Abstract_State_Consumer_Tasking_Effect_Blocker,
      Abstract_State_Consumer_Volatile_Atomic_Blocker,
      Abstract_State_Consumer_Cross_Unit_Visibility_Blocker,
      Abstract_State_Consumer_Source_Fingerprint_Mismatch,
      Abstract_State_Consumer_Multiple_Blockers,
      Abstract_State_Consumer_Indeterminate);

   type Abstract_State_Consumer_Context is record
      Id                         : Abstract_State_Consumer_Row_Id := No_Abstract_State_Consumer_Row;
      Kind                       : Abstract_State_Consumer_Kind := Abstract_State_Consumer_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Consumer_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Abstract_State_Row         : States.Abstract_State_Row_Id := States.No_Abstract_State_Row;
      Abstract_State_Status      : States.Abstract_State_Status := States.Abstract_State_Not_Checked;
      Shared_State_Row           : Shared.Shared_State_Row_Id := Shared.No_Shared_State_Row;
      Shared_State_Status        : Shared.Shared_State_Status := Shared.Shared_State_Not_Checked;
      Overload_State_Row         : Overload_State.Overload_Shared_State_Row_Id := Overload_State.No_Overload_Shared_State_Row;
      Overload_State_Status      : Overload_State.Overload_Shared_State_Status := Overload_State.Overload_Shared_State_Not_Checked;
      Representation_State_Row   : Rep_State.Representation_Shared_State_Row_Id := Rep_State.No_Representation_Shared_State_Row;
      Representation_State_Status : Rep_State.Representation_Shared_State_Status := Rep_State.Representation_Shared_State_Not_Checked;
      Tasking_State_Row          : Tasking_State.Tasking_Shared_State_Row_Id := Tasking_State.No_Tasking_Shared_State_Row;
      Tasking_State_Status       : Tasking_State.Tasking_Shared_State_Status := Tasking_State.Tasking_Shared_State_Not_Checked;
      Cross_Unit_State_Row       : Cross_Unit_State.Cross_Unit_Shared_State_Row_Id := Cross_Unit_State.No_Cross_Unit_Shared_State_Row;
      Cross_Unit_State_Status    : Cross_Unit_State.Cross_Unit_Shared_State_Status := Cross_Unit_State.Cross_Unit_Shared_State_Not_Checked;
      Stabilized_Closure_Row     : Stabilized_State.Shared_State_Stabilized_Closure_Id := Stabilized_State.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Stabilized_State.Shared_State_Stabilized_Closure_Status := Stabilized_State.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Shared_State      : Boolean := False;
      Requires_Overload_State    : Boolean := False;
      Requires_Representation_State : Boolean := False;
      Requires_Tasking_State     : Boolean := False;
      Requires_Cross_Unit_State  : Boolean := False;
      Requires_Stabilized_Closure : Boolean := False;
      Global_Mode_Error          : Boolean := False;
      Depends_Edge_Error         : Boolean := False;
      Dispatching_Effect_Error   : Boolean := False;
      Generic_Replay_Error       : Boolean := False;
      Representation_Freezing_Error : Boolean := False;
      Tasking_Effect_Error       : Boolean := False;
      Volatile_Atomic_Error      : Boolean := False;
      Cross_Unit_Visibility_Error : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Abstract_State_Consumer_Row is record
      Id                         : Abstract_State_Consumer_Row_Id := No_Abstract_State_Consumer_Row;
      Context                    : Abstract_State_Consumer_Row_Id := No_Abstract_State_Consumer_Row;
      Kind                       : Abstract_State_Consumer_Kind := Abstract_State_Consumer_Unknown;
      Status                     : Abstract_State_Consumer_Status := Abstract_State_Consumer_Not_Checked;
      Blocker_Family             : Abstract_State_Consumer_Blocker_Family := Abstract_State_Consumer_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Consumer_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Abstract_State_Consumer_Context_Model is private;
   type Abstract_State_Consumer_Model is private;
   type Abstract_State_Consumer_Set is private;

   procedure Clear (Model : in out Abstract_State_Consumer_Context_Model);
   procedure Add_Context
     (Model : in out Abstract_State_Consumer_Context_Model;
      Info  : Abstract_State_Consumer_Context);
   function Context_Count (Model : Abstract_State_Consumer_Context_Model) return Natural;
   function Context_At
     (Model : Abstract_State_Consumer_Context_Model;
      Index : Positive) return Abstract_State_Consumer_Context;
   function Fingerprint (Model : Abstract_State_Consumer_Context_Model) return Natural;

   function Build (Contexts : Abstract_State_Consumer_Context_Model) return Abstract_State_Consumer_Model;
   function Count (Model : Abstract_State_Consumer_Model) return Natural;
   function Row_Count (Model : Abstract_State_Consumer_Model) return Natural renames Count;
   function Row_At
     (Model : Abstract_State_Consumer_Model;
      Index : Positive) return Abstract_State_Consumer_Row;

   function Query_Count (Set : Abstract_State_Consumer_Set) return Natural;
   function Query_At
     (Set   : Abstract_State_Consumer_Set;
      Index : Positive) return Abstract_State_Consumer_Row;
   function Query_Status
     (Model  : Abstract_State_Consumer_Model;
      Status : Abstract_State_Consumer_Status) return Abstract_State_Consumer_Set;
   function Query_Blocker_Family
     (Model  : Abstract_State_Consumer_Model;
      Family : Abstract_State_Consumer_Blocker_Family) return Abstract_State_Consumer_Set;
   function Find_By_Node
     (Model : Abstract_State_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Abstract_State_Consumer_Set;
   function Find_By_Source_Fingerprint
     (Model              : Abstract_State_Consumer_Model;
      Source_Fingerprint : Natural) return Abstract_State_Consumer_Set;

   function Count_By_Status
     (Model  : Abstract_State_Consumer_Model;
      Status : Abstract_State_Consumer_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Abstract_State_Consumer_Model;
      Family : Abstract_State_Consumer_Blocker_Family) return Natural;
   function Accepted_Count (Model : Abstract_State_Consumer_Model) return Natural;
   function Blocked_Count (Model : Abstract_State_Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Abstract_State_Consumer_Model) return Natural;
   function Stable_Fingerprint (Model : Abstract_State_Consumer_Model) return Natural;

   function Is_Accepted (Status : Abstract_State_Consumer_Status) return Boolean;
   function Is_Blocked (Status : Abstract_State_Consumer_Status) return Boolean;
   function Is_Indeterminate (Status : Abstract_State_Consumer_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Abstract_State_Consumer_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Abstract_State_Consumer_Row);

   type Abstract_State_Consumer_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Abstract_State_Consumer_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Abstract_State_Consumer_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
