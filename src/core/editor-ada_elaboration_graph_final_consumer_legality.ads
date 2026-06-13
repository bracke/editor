with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Overload_Type_Edge_Precision_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;

package Editor.Ada_Elaboration_Graph_Final_Consumer_Legality is

   --  Pass1184 compiler-grade elaboration graph final consumer legality.
   --
   --  This layer makes elaboration graph closure evidence a direct prerequisite
   --  for the remaining semantic consumers that can otherwise accept facts too
   --  early: call/overload contexts, default expressions, aspect expressions,
   --  representation items, task activation/effects, generic replay, and
   --  preelaboration/pure/remote/shared-passive policy contexts.  It preserves
   --  the richer predicate/dataflow, representation/freezing, generic
   --  backmapping, overload/type-edge, tasking, and accessibility blockers
   --  without changing buffers, rendering, commands, or workspace state.

   package Access_Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   package Elab_CPD renames Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
   package Generic_Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   package Overload_Edge renames Editor.Ada_Overload_Type_Edge_Precision_Legality;
   package Representation_CPD renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   package Tasking_CPD renames Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;

   type Final_Elaboration_Row_Id is new Natural;
   No_Final_Elaboration_Row : constant Final_Elaboration_Row_Id := 0;

   type Final_Elaboration_Context_Kind is
     (Final_Elaboration_Direct_Call,
      Final_Elaboration_Indirect_Call,
      Final_Elaboration_Dispatching_Call,
      Final_Elaboration_Default_Expression,
      Final_Elaboration_Aspect_Expression,
      Final_Elaboration_Representation_Item,
      Final_Elaboration_Task_Activation,
      Final_Elaboration_Task_Termination,
      Final_Elaboration_Generic_Instance,
      Final_Elaboration_Generic_Replay,
      Final_Elaboration_Preelaboration_Policy,
      Final_Elaboration_Pure_Policy,
      Final_Elaboration_Remote_Types_Policy,
      Final_Elaboration_Shared_Passive_Policy,
      Final_Elaboration_Unknown);

   type Final_Elaboration_Status is
     (Final_Elaboration_Not_Checked,
      Final_Elaboration_Legal_Call_Accepted,
      Final_Elaboration_Legal_Default_Expression_Accepted,
      Final_Elaboration_Legal_Aspect_Expression_Accepted,
      Final_Elaboration_Legal_Representation_Item_Accepted,
      Final_Elaboration_Legal_Task_Activation_Accepted,
      Final_Elaboration_Legal_Task_Termination_Accepted,
      Final_Elaboration_Legal_Generic_Instance_Accepted,
      Final_Elaboration_Legal_Generic_Replay_Accepted,
      Final_Elaboration_Legal_Preelaboration_Policy_Accepted,
      Final_Elaboration_Legal_Pure_Policy_Accepted,
      Final_Elaboration_Legal_Remote_Types_Policy_Accepted,
      Final_Elaboration_Legal_Shared_Passive_Policy_Accepted,
      Final_Elaboration_Missing_Elaboration_Row,
      Final_Elaboration_Multiple_Elaboration_Blockers,
      Final_Elaboration_Base_Elaboration_Error,
      Final_Elaboration_Predicate_Dataflow_Blocker,
      Final_Elaboration_Read_Before_Write_Blocker,
      Final_Elaboration_Initialization_Blocker,
      Final_Elaboration_Lifetime_Accessibility_Blocker,
      Final_Elaboration_Discriminant_Variant_Blocker,
      Final_Elaboration_Representation_Freezing_Blocker,
      Final_Elaboration_Global_Depends_Blocker,
      Final_Elaboration_Call_Propagation_Blocker,
      Final_Elaboration_Generic_Effect_Blocker,
      Final_Elaboration_Tasking_Protected_Blocker,
      Final_Elaboration_Coverage_Blocker,
      Final_Elaboration_Missing_Overload_Row,
      Final_Elaboration_Overload_Type_Blocker,
      Final_Elaboration_Overload_Type_Ambiguous,
      Final_Elaboration_Missing_Representation_Row,
      Final_Elaboration_Representation_Consumer_Blocker,
      Final_Elaboration_Missing_Tasking_Row,
      Final_Elaboration_Tasking_Consumer_Blocker,
      Final_Elaboration_Missing_Generic_Backmap_Row,
      Final_Elaboration_Generic_Backmap_Blocker,
      Final_Elaboration_Missing_Accessibility_Row,
      Final_Elaboration_Accessibility_Blocker,
      Final_Elaboration_Multiple_Matching_Blockers,
      Final_Elaboration_Indeterminate);

   type Final_Elaboration_Context_Info is record
      Id                         : Final_Elaboration_Row_Id := No_Final_Elaboration_Row;
      Kind                       : Final_Elaboration_Context_Kind := Final_Elaboration_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Context_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Source_Unit_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Elaboration_Row            : Elab_CPD.Elaboration_Contract_Predicate_Row_Id :=
        Elab_CPD.No_Elaboration_Contract_Predicate_Row;
      Elaboration_Status         : Elab_CPD.Elaboration_Contract_Predicate_Status :=
        Elab_CPD.Elaboration_Contract_Predicate_Not_Checked;
      Elaboration_Matches        : Natural := 0;
      Overload_Row               : Overload_Edge.Overload_Type_Edge_Row_Id :=
        Overload_Edge.No_Overload_Type_Edge_Row;
      Overload_Status            : Overload_Edge.Overload_Type_Edge_Status :=
        Overload_Edge.Overload_Type_Edge_Not_Checked;
      Overload_Matches           : Natural := 0;
      Representation_Row         : Representation_CPD.Representation_Tasking_CPD_Row_Id :=
        Representation_CPD.No_Representation_Tasking_CPD_Row;
      Representation_Status      : Representation_CPD.Representation_Tasking_CPD_Status :=
        Representation_CPD.Representation_Tasking_CPD_Not_Checked;
      Representation_Matches     : Natural := 0;
      Tasking_Row                : Tasking_CPD.Tasking_Contract_Predicate_Row_Id :=
        Tasking_CPD.No_Tasking_Contract_Predicate_Row;
      Tasking_Status             : Tasking_CPD.Tasking_Contract_Predicate_Status :=
        Tasking_CPD.Tasking_Contract_Predicate_Not_Checked;
      Tasking_Matches            : Natural := 0;
      Generic_Backmap_Row        : Generic_Backmap.Generic_Backmap_Row_Id :=
        Generic_Backmap.No_Generic_Backmap_Row;
      Generic_Backmap_Status     : Generic_Backmap.Generic_Backmap_Status :=
        Generic_Backmap.Generic_Backmap_Not_Checked;
      Generic_Backmap_Matches    : Natural := 0;
      Accessibility_Row          : Access_Final.Master_Scope_Final_Row_Id :=
        Access_Final.No_Master_Scope_Final_Row;
      Accessibility_Status       : Access_Final.Master_Scope_Final_Status :=
        Access_Final.Master_Scope_Final_Not_Checked;
      Accessibility_Matches      : Natural := 0;
      Requires_Overload          : Boolean := False;
      Requires_Representation    : Boolean := False;
      Requires_Tasking           : Boolean := False;
      Requires_Generic_Backmap   : Boolean := False;
      Requires_Accessibility     : Boolean := False;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
   end record;

   type Final_Elaboration_Info is record
      Id                         : Final_Elaboration_Row_Id := No_Final_Elaboration_Row;
      Context                    : Final_Elaboration_Row_Id := No_Final_Elaboration_Row;
      Kind                       : Final_Elaboration_Context_Kind := Final_Elaboration_Unknown;
      Status                     : Final_Elaboration_Status := Final_Elaboration_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Context_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Source_Unit_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Elaboration_Row            : Elab_CPD.Elaboration_Contract_Predicate_Row_Id :=
        Elab_CPD.No_Elaboration_Contract_Predicate_Row;
      Elaboration_Status         : Elab_CPD.Elaboration_Contract_Predicate_Status :=
        Elab_CPD.Elaboration_Contract_Predicate_Not_Checked;
      Overload_Row               : Overload_Edge.Overload_Type_Edge_Row_Id :=
        Overload_Edge.No_Overload_Type_Edge_Row;
      Overload_Status            : Overload_Edge.Overload_Type_Edge_Status :=
        Overload_Edge.Overload_Type_Edge_Not_Checked;
      Representation_Row         : Representation_CPD.Representation_Tasking_CPD_Row_Id :=
        Representation_CPD.No_Representation_Tasking_CPD_Row;
      Representation_Status      : Representation_CPD.Representation_Tasking_CPD_Status :=
        Representation_CPD.Representation_Tasking_CPD_Not_Checked;
      Tasking_Row                : Tasking_CPD.Tasking_Contract_Predicate_Row_Id :=
        Tasking_CPD.No_Tasking_Contract_Predicate_Row;
      Tasking_Status             : Tasking_CPD.Tasking_Contract_Predicate_Status :=
        Tasking_CPD.Tasking_Contract_Predicate_Not_Checked;
      Generic_Backmap_Row        : Generic_Backmap.Generic_Backmap_Row_Id :=
        Generic_Backmap.No_Generic_Backmap_Row;
      Generic_Backmap_Status     : Generic_Backmap.Generic_Backmap_Status :=
        Generic_Backmap.Generic_Backmap_Not_Checked;
      Accessibility_Row          : Access_Final.Master_Scope_Final_Row_Id :=
        Access_Final.No_Master_Scope_Final_Row;
      Accessibility_Status       : Access_Final.Master_Scope_Final_Status :=
        Access_Final.Master_Scope_Final_Not_Checked;
      Source_Fingerprint         : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Final_Elaboration_Context_Model is private;
   type Final_Elaboration_Set is private;
   type Final_Elaboration_Model is private;

   procedure Clear (Model : in out Final_Elaboration_Context_Model);
   procedure Add_Context
     (Model : in out Final_Elaboration_Context_Model;
      Info  : Final_Elaboration_Context_Info);

   function Context_Count (Model : Final_Elaboration_Context_Model) return Natural;
   function Context_At
     (Model : Final_Elaboration_Context_Model;
      Index : Positive) return Final_Elaboration_Context_Info;
   function Fingerprint (Model : Final_Elaboration_Context_Model) return Natural;

   function Build (Contexts : Final_Elaboration_Context_Model) return Final_Elaboration_Model;
   function Row_Count (Model : Final_Elaboration_Model) return Natural;
   function Row_At
     (Model : Final_Elaboration_Model;
      Index : Positive) return Final_Elaboration_Info;
   function First_For_Node
     (Model : Final_Elaboration_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Elaboration_Info;
   function Rows_For_Status
     (Model  : Final_Elaboration_Model;
      Status : Final_Elaboration_Status) return Final_Elaboration_Set;
   function Rows_For_Kind
     (Model : Final_Elaboration_Model;
      Kind  : Final_Elaboration_Context_Kind) return Final_Elaboration_Set;
   function Rows_For_Context_Name
     (Model        : Final_Elaboration_Model;
      Context_Name : String) return Final_Elaboration_Set;

   function Set_Count (Set : Final_Elaboration_Set) return Natural;
   function Set_At
     (Set   : Final_Elaboration_Set;
      Index : Positive) return Final_Elaboration_Info;

   function Count_Status
     (Model  : Final_Elaboration_Model;
      Status : Final_Elaboration_Status) return Natural;
   function Count_Kind
     (Model : Final_Elaboration_Model;
      Kind  : Final_Elaboration_Context_Kind) return Natural;

   function Legal_Count (Model : Final_Elaboration_Model) return Natural;
   function Error_Count (Model : Final_Elaboration_Model) return Natural;
   function Elaboration_Error_Count (Model : Final_Elaboration_Model) return Natural;
   function Overload_Error_Count (Model : Final_Elaboration_Model) return Natural;
   function Representation_Error_Count (Model : Final_Elaboration_Model) return Natural;
   function Tasking_Error_Count (Model : Final_Elaboration_Model) return Natural;
   function Generic_Backmap_Error_Count (Model : Final_Elaboration_Model) return Natural;
   function Accessibility_Error_Count (Model : Final_Elaboration_Model) return Natural;
   function Indeterminate_Count (Model : Final_Elaboration_Model) return Natural;
   function Fingerprint (Model : Final_Elaboration_Model) return Natural;

   function Is_Legal (Status : Final_Elaboration_Status) return Boolean;
   function Is_Elaboration_Error (Status : Final_Elaboration_Status) return Boolean;
   function Is_Overload_Error (Status : Final_Elaboration_Status) return Boolean;
   function Is_Representation_Error (Status : Final_Elaboration_Status) return Boolean;
   function Is_Tasking_Error (Status : Final_Elaboration_Status) return Boolean;
   function Is_Generic_Backmap_Error (Status : Final_Elaboration_Status) return Boolean;
   function Is_Accessibility_Error (Status : Final_Elaboration_Status) return Boolean;
   function Is_Indeterminate (Status : Final_Elaboration_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Elaboration_Context_Info);

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Elaboration_Info);

   type Final_Elaboration_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Final_Elaboration_Set is record
      Rows : Row_Vectors.Vector;
   end record;

   type Final_Elaboration_Model is record
      Rows : Row_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
