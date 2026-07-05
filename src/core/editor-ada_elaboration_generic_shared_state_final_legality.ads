with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
with Editor.Ada_Dispatching_Global_Refinement_Legality;
with Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

package Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality is

   --  Case 1232 elaboration/generic shared-state final legality.
   --
   --  This package connects the final elaboration consumer with the
   --  generic/shared-state semantic chain.  Elaboration conclusions for
   --  dispatching calls, generic instances, generic body replay,
   --  representation items, task activation/termination, preelaboration,
   --  Pure, Remote_Types, and Shared_Passive contexts are accepted only when
   --  final elaboration evidence agrees with cross-unit generic/shared-state
   --  closure, dispatching Global/Depends refinement, generic abstract-state
   --  replay, representation/generic shared-state evidence, and
   --  tasking/generic shared-state evidence.  Missing evidence remains a
   --  first-class semantic blocker rather than becoming a confident legality
   --  result.

   package Cross_Generic renames Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
   package Dispatching_Global renames Editor.Ada_Dispatching_Global_Refinement_Legality;
   package Elaboration_Final renames Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Rep_Generic renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   package Tasking_Generic renames Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

   type Elaboration_Generic_Final_Row_Id is new Natural;
   No_Elaboration_Generic_Final_Row : constant Elaboration_Generic_Final_Row_Id := 0;

   type Elaboration_Generic_Final_Kind is
     (Elaboration_Generic_Final_Dispatching_Call,
      Elaboration_Generic_Final_Default_Expression,
      Elaboration_Generic_Final_Aspect_Expression,
      Elaboration_Generic_Final_Representation_Item,
      Elaboration_Generic_Final_Task_Activation,
      Elaboration_Generic_Final_Task_Termination,
      Elaboration_Generic_Final_Generic_Instance,
      Elaboration_Generic_Final_Generic_Body_Replay,
      Elaboration_Generic_Final_Preelaboration_Policy,
      Elaboration_Generic_Final_Pure_Policy,
      Elaboration_Generic_Final_Remote_Types_Policy,
      Elaboration_Generic_Final_Shared_Passive_Policy,
      Elaboration_Generic_Final_Unknown);

   type Elaboration_Generic_Final_Blocker_Family is
     (Elaboration_Generic_Final_Blocker_None,
      Elaboration_Generic_Final_Blocker_Final_Elaboration,
      Elaboration_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State,
      Elaboration_Generic_Final_Blocker_Dispatching_Global,
      Elaboration_Generic_Final_Blocker_Generic_Abstract_Replay,
      Elaboration_Generic_Final_Blocker_Representation_Generic_Shared_State,
      Elaboration_Generic_Final_Blocker_Tasking_Generic_Shared_State,
      Elaboration_Generic_Final_Blocker_Elaboration_Order,
      Elaboration_Generic_Final_Blocker_Preelaboration_Policy,
      Elaboration_Generic_Final_Blocker_Pure_Policy,
      Elaboration_Generic_Final_Blocker_Remote_Types_Policy,
      Elaboration_Generic_Final_Blocker_Shared_Passive_Policy,
      Elaboration_Generic_Final_Blocker_Generic_Body,
      Elaboration_Generic_Final_Blocker_View_Barrier,
      Elaboration_Generic_Final_Blocker_Source_Fingerprint,
      Elaboration_Generic_Final_Blocker_Substitution_Fingerprint,
      Elaboration_Generic_Final_Blocker_Multiple,
      Elaboration_Generic_Final_Blocker_Indeterminate);

   type Elaboration_Generic_Final_Status is
     (Elaboration_Generic_Final_Not_Checked,
      Elaboration_Generic_Final_Legal_Dispatching_Call_Accepted,
      Elaboration_Generic_Final_Legal_Default_Expression_Accepted,
      Elaboration_Generic_Final_Legal_Aspect_Expression_Accepted,
      Elaboration_Generic_Final_Legal_Representation_Item_Accepted,
      Elaboration_Generic_Final_Legal_Task_Activation_Accepted,
      Elaboration_Generic_Final_Legal_Task_Termination_Accepted,
      Elaboration_Generic_Final_Legal_Generic_Instance_Accepted,
      Elaboration_Generic_Final_Legal_Generic_Body_Replay_Accepted,
      Elaboration_Generic_Final_Legal_Preelaboration_Policy_Accepted,
      Elaboration_Generic_Final_Legal_Pure_Policy_Accepted,
      Elaboration_Generic_Final_Legal_Remote_Types_Policy_Accepted,
      Elaboration_Generic_Final_Legal_Shared_Passive_Policy_Accepted,
      Elaboration_Generic_Final_Missing_Final_Elaboration_Row,
      Elaboration_Generic_Final_Final_Elaboration_Blocker,
      Elaboration_Generic_Final_Missing_Cross_Unit_Generic_Row,
      Elaboration_Generic_Final_Cross_Unit_Generic_Blocker,
      Elaboration_Generic_Final_Missing_Dispatching_Global_Row,
      Elaboration_Generic_Final_Dispatching_Global_Blocker,
      Elaboration_Generic_Final_Missing_Generic_Replay_Row,
      Elaboration_Generic_Final_Generic_Replay_Blocker,
      Elaboration_Generic_Final_Missing_Representation_Generic_Row,
      Elaboration_Generic_Final_Representation_Generic_Blocker,
      Elaboration_Generic_Final_Missing_Tasking_Generic_Row,
      Elaboration_Generic_Final_Tasking_Generic_Blocker,
      Elaboration_Generic_Final_Elaboration_Order_Blocker,
      Elaboration_Generic_Final_Preelaboration_Policy_Blocker,
      Elaboration_Generic_Final_Pure_Policy_Blocker,
      Elaboration_Generic_Final_Remote_Types_Policy_Blocker,
      Elaboration_Generic_Final_Shared_Passive_Policy_Blocker,
      Elaboration_Generic_Final_Generic_Body_Unavailable,
      Elaboration_Generic_Final_View_Barrier,
      Elaboration_Generic_Final_Source_Fingerprint_Mismatch,
      Elaboration_Generic_Final_Substitution_Fingerprint_Mismatch,
      Elaboration_Generic_Final_Multiple_Blockers,
      Elaboration_Generic_Final_Indeterminate);

   type Elaboration_Generic_Final_Context is record
      Id                         : Elaboration_Generic_Final_Row_Id := No_Elaboration_Generic_Final_Row;
      Kind                       : Elaboration_Generic_Final_Kind := Elaboration_Generic_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Final_Elaboration_Row      : Elaboration_Final.Final_Elaboration_Row_Id := Elaboration_Final.No_Final_Elaboration_Row;
      Final_Elaboration_Status   : Elaboration_Final.Final_Elaboration_Status := Elaboration_Final.Final_Elaboration_Not_Checked;
      Cross_Generic_Row          : Cross_Generic.Cross_Unit_Generic_Final_Row_Id := Cross_Generic.No_Cross_Unit_Generic_Final_Row;
      Cross_Generic_Status       : Cross_Generic.Cross_Unit_Generic_Final_Status := Cross_Generic.Cross_Unit_Generic_Final_Not_Checked;
      Dispatching_Global_Row     : Dispatching_Global.Dispatching_Global_Row_Id := Dispatching_Global.No_Dispatching_Global_Row;
      Dispatching_Global_Status  : Dispatching_Global.Dispatching_Global_Status := Dispatching_Global.Dispatching_Global_Not_Checked;
      Generic_Replay_Row         : Generic_Replay.Generic_Abstract_Replay_Row_Id := Generic_Replay.No_Generic_Abstract_Replay_Row;
      Generic_Replay_Status      : Generic_Replay.Generic_Abstract_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Not_Checked;
      Representation_Generic_Row : Rep_Generic.Representation_Generic_Final_Row_Id := Rep_Generic.No_Representation_Generic_Final_Row;
      Representation_Generic_Status : Rep_Generic.Representation_Generic_Final_Status := Rep_Generic.Representation_Generic_Final_Not_Checked;
      Tasking_Generic_Row        : Tasking_Generic.Tasking_Generic_Final_Row_Id := Tasking_Generic.No_Tasking_Generic_Final_Row;
      Tasking_Generic_Status     : Tasking_Generic.Tasking_Generic_Final_Status := Tasking_Generic.Tasking_Generic_Final_Not_Checked;
      Requires_Dispatching_Global : Boolean := False;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Representation_Generic : Boolean := False;
      Requires_Tasking_Generic   : Boolean := False;
      Elaboration_Order_Error    : Boolean := False;
      Preelaboration_Policy_Error : Boolean := False;
      Pure_Policy_Error          : Boolean := False;
      Remote_Types_Policy_Error  : Boolean := False;
      Shared_Passive_Policy_Error : Boolean := False;
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

   type Elaboration_Generic_Final_Row is record
      Id                         : Elaboration_Generic_Final_Row_Id := No_Elaboration_Generic_Final_Row;
      Context                    : Elaboration_Generic_Final_Row_Id := No_Elaboration_Generic_Final_Row;
      Kind                       : Elaboration_Generic_Final_Kind := Elaboration_Generic_Final_Unknown;
      Status                     : Elaboration_Generic_Final_Status := Elaboration_Generic_Final_Not_Checked;
      Blocker_Family             : Elaboration_Generic_Final_Blocker_Family := Elaboration_Generic_Final_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
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

   type Elaboration_Generic_Final_Context_Model is private;
   type Elaboration_Generic_Final_Model is private;
   type Elaboration_Generic_Final_Set is private;

   procedure Clear (Model : in out Elaboration_Generic_Final_Context_Model);
   procedure Add_Context (Model : in out Elaboration_Generic_Final_Context_Model; Info : Elaboration_Generic_Final_Context);
   function Context_Count (Model : Elaboration_Generic_Final_Context_Model) return Natural;
   function Context_At (Model : Elaboration_Generic_Final_Context_Model; Index : Positive) return Elaboration_Generic_Final_Context;
   function Fingerprint (Model : Elaboration_Generic_Final_Context_Model) return Natural;

   function Build (Contexts : Elaboration_Generic_Final_Context_Model) return Elaboration_Generic_Final_Model;
   function Count (Model : Elaboration_Generic_Final_Model) return Natural;
   function Row_Count (Model : Elaboration_Generic_Final_Model) return Natural renames Count;
   function Row_At (Model : Elaboration_Generic_Final_Model; Index : Positive) return Elaboration_Generic_Final_Row;

   function Query_Count (Set : Elaboration_Generic_Final_Set) return Natural;
   function Query_At (Set : Elaboration_Generic_Final_Set; Index : Positive) return Elaboration_Generic_Final_Row;
   function Query_Status (Model : Elaboration_Generic_Final_Model; Status : Elaboration_Generic_Final_Status) return Elaboration_Generic_Final_Set;
   function Query_Blocker_Family (Model : Elaboration_Generic_Final_Model; Family : Elaboration_Generic_Final_Blocker_Family) return Elaboration_Generic_Final_Set;
   function Find_By_Node (Model : Elaboration_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Generic_Final_Set;
   function Find_By_Source_Fingerprint (Model : Elaboration_Generic_Final_Model; Source_Fingerprint : Natural) return Elaboration_Generic_Final_Set;

   function Count_By_Status (Model : Elaboration_Generic_Final_Model; Status : Elaboration_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family (Model : Elaboration_Generic_Final_Model; Family : Elaboration_Generic_Final_Blocker_Family) return Natural;
   function Accepted_Count (Model : Elaboration_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Elaboration_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Elaboration_Generic_Final_Model) return Natural;
   function Stable_Fingerprint (Model : Elaboration_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Elaboration_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Elaboration_Generic_Final_Status) return Boolean;
   function Is_Indeterminate (Status : Elaboration_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Elaboration_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Elaboration_Generic_Final_Row);

   type Elaboration_Generic_Final_Context_Model is record
      Items : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Elaboration_Generic_Final_Model is record
      Rows : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Elaboration_Generic_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;
end Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
