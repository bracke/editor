with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Scope_Graph_Legality;
with Editor.Ada_Elaboration_Dependence_Legality;
with Editor.Ada_Elaboration_Precision_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_Elaboration_Graph_Closure_Legality is

   --  Case 1144 compiler-grade elaboration graph closure legality.
   --
   --  This package deepens elaboration/dependence precision into an explicit
   --  library-unit elaboration graph closure.  It connects transitive
   --  Elaborate_All closure, body-before-use through direct and indirect calls,
   --  generic instance elaboration, call/access elaboration risks, flow-effect
   --  graph blockers, accessibility scope graph blockers, and coverage-gated
   --  semantic results.  The package is deterministic and snapshot-owned; it
   --  performs no parsing, file IO, dirty-state mutation, command/keybinding/
   --  workspace/render mutation, compiler invocation, external parser
   --  generation, Python, or shell-script work.

   package Base renames Editor.Ada_Elaboration_Dependence_Legality;
   package Precision renames Editor.Ada_Elaboration_Precision_Legality;
   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   package Flow renames Editor.Ada_Flow_Effect_Graph_Legality;
   package Scope renames Editor.Ada_Accessibility_Scope_Graph_Legality;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   type Elaboration_Graph_Edge_Id is new Natural;
   No_Elaboration_Graph_Edge : constant Elaboration_Graph_Edge_Id := 0;

   type Elaboration_Graph_Context_Kind is
     (Graph_Context_Library_With_Edge,
      Graph_Context_Use_Edge,
      Graph_Context_Body_Edge,
      Graph_Context_Direct_Call_Edge,
      Graph_Context_Indirect_Call_Edge,
      Graph_Context_Dispatching_Call_Edge,
      Graph_Context_Access_Edge,
      Graph_Context_Generic_Instance_Edge,
      Graph_Context_Default_Expression_Edge,
      Graph_Context_Aspect_Expression_Edge,
      Graph_Context_Representation_Item_Edge,
      Graph_Context_Preelaborated_Unit,
      Graph_Context_Pure_Unit,
      Graph_Context_Remote_Types_Unit,
      Graph_Context_Shared_Passive_Unit,
      Graph_Context_Cycle_Path,
      Graph_Context_Unknown);

   type Elaboration_Graph_Closure_Status is
     (Graph_Closure_Not_Checked,
      Graph_Closure_Legal_Library_Edge,
      Graph_Closure_Legal_Transitive_Elaborate_All,
      Graph_Closure_Legal_Body_Before_Use,
      Graph_Closure_Legal_Direct_Call_Order,
      Graph_Closure_Legal_Indirect_Call_Order,
      Graph_Closure_Legal_Dispatching_Call_Order,
      Graph_Closure_Legal_Access_Order,
      Graph_Closure_Legal_Generic_Instance_Order,
      Graph_Closure_Legal_Default_Expression_Order,
      Graph_Closure_Legal_Aspect_Expression_Order,
      Graph_Closure_Legal_Representation_Item_Order,
      Graph_Closure_Legal_Preelaboration_Policy,
      Graph_Closure_Legal_Pure_Policy,
      Graph_Closure_Missing_Transitive_Elaborate_All,
      Graph_Closure_Missing_Body_Before_Use,
      Graph_Closure_Direct_Call_Before_Body,
      Graph_Closure_Indirect_Call_Before_Body,
      Graph_Closure_Dispatching_Call_Before_Body,
      Graph_Closure_Access_Before_Elaboration,
      Graph_Closure_Generic_Instance_Body_Not_Elaborated,
      Graph_Closure_Generic_Instance_Formal_Body_Unresolved,
      Graph_Closure_Circular_Library_Elaboration,
      Graph_Closure_Cycle_Path_Missing_Source,
      Graph_Closure_Missing_Dependency_Edge,
      Graph_Closure_Ambiguous_Dependency_Edge,
      Graph_Closure_Preelaboration_Illegal_Effect,
      Graph_Closure_Pure_Illegal_Effect,
      Graph_Closure_Remote_Types_Illegal_Effect,
      Graph_Closure_Shared_Passive_Illegal_Effect,
      Graph_Closure_Flow_Effect_Blocker,
      Graph_Closure_Accessibility_Scope_Blocker,
      Graph_Closure_Linked_Base_Elaboration_Error,
      Graph_Closure_Linked_Precision_Error,
      Graph_Closure_Linked_Generic_Replay_Error,
      Graph_Closure_Coverage_Gate_Blocker,
      Graph_Closure_Multiple_Blockers,
      Graph_Closure_Indeterminate);

   type Elaboration_Graph_Context_Info is record
      Id                    : Elaboration_Graph_Edge_Id := No_Elaboration_Graph_Edge;
      Kind                  : Elaboration_Graph_Context_Kind := Graph_Context_Unknown;
      Dependence            : Base.Elaboration_Dependence_Kind := Base.Elaboration_Dependence_Unknown;
      Order_State           : Base.Elaboration_Order_State := Base.Elaboration_Order_Unknown;
      Policy_State          : Base.Elaboration_Policy_State := Base.Elaboration_Policy_Normal;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Call_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Path_Text             : Ada.Strings.Unbounded.Unbounded_String;
      Edge_Depth            : Natural := 0;
      Requires_Elaborate_All : Boolean := False;
      Has_Transitive_Elaborate_All : Boolean := False;
      Requires_Body_Before_Use : Boolean := False;
      Body_Elaborated_Before_Use : Boolean := True;
      Direct_Call           : Boolean := False;
      Indirect_Call         : Boolean := False;
      Dispatching_Call      : Boolean := False;
      Access_During_Elaboration : Boolean := False;
      Generic_Instance      : Boolean := False;
      Generic_Body_Elaborated : Boolean := True;
      Formal_Body_Resolved  : Boolean := True;
      Default_Expression_Edge : Boolean := False;
      Aspect_Expression_Edge : Boolean := False;
      Representation_Item_Edge : Boolean := False;
      Cycle_Detected        : Boolean := False;
      Cycle_Path_Known      : Boolean := True;
      Missing_Edge          : Boolean := False;
      Ambiguous_Edge        : Boolean := False;
      Illegal_Preelaborate_Effect : Boolean := False;
      Illegal_Pure_Effect   : Boolean := False;
      Illegal_Remote_Types_Effect : Boolean := False;
      Illegal_Shared_Passive_Effect : Boolean := False;
      Base_Status           : Base.Elaboration_Legality_Status := Base.Elaboration_Legality_Not_Checked;
      Precision_Status      : Precision.Elaboration_Precision_Status := Precision.Elaboration_Precision_Not_Checked;
      Replay_Status         : Replay.Replay_Status := Replay.Replay_Not_Checked;
      Flow_Status           : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Scope_Status          : Scope.Scope_Legality_Status := Scope.Scope_Legality_Not_Checked;
      Gate_Status           : Gates.Enforcement_Status := Gates.Enforcement_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Elaboration_Graph_Closure_Info is record
      Id                    : Elaboration_Graph_Edge_Id := No_Elaboration_Graph_Edge;
      Kind                  : Elaboration_Graph_Context_Kind := Graph_Context_Unknown;
      Dependence            : Base.Elaboration_Dependence_Kind := Base.Elaboration_Dependence_Unknown;
      Status                : Elaboration_Graph_Closure_Status := Graph_Closure_Not_Checked;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Unit_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Unit_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Path_Text             : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Edge_Depth            : Natural := 0;
      Order_State           : Base.Elaboration_Order_State := Base.Elaboration_Order_Unknown;
      Policy_State          : Base.Elaboration_Policy_State := Base.Elaboration_Policy_Normal;
      Base_Status           : Base.Elaboration_Legality_Status := Base.Elaboration_Legality_Not_Checked;
      Precision_Status      : Precision.Elaboration_Precision_Status := Precision.Elaboration_Precision_Not_Checked;
      Replay_Status         : Replay.Replay_Status := Replay.Replay_Not_Checked;
      Flow_Status           : Flow.Flow_Effect_Graph_Status := Flow.Flow_Graph_Not_Checked;
      Scope_Status          : Scope.Scope_Legality_Status := Scope.Scope_Legality_Not_Checked;
      Gate_Status           : Gates.Enforcement_Status := Gates.Enforcement_Not_Checked;
      Blocker_Count         : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Elaboration_Graph_Context_Model is private;
   type Elaboration_Graph_Result_Set is private;
   type Elaboration_Graph_Closure_Model is private;

   procedure Clear (Model : in out Elaboration_Graph_Context_Model);
   procedure Add_Context
     (Model : in out Elaboration_Graph_Context_Model;
      Info  : Elaboration_Graph_Context_Info);

   function Context_Count (Model : Elaboration_Graph_Context_Model) return Natural;
   function Context_At
     (Model : Elaboration_Graph_Context_Model;
      Index : Positive) return Elaboration_Graph_Context_Info;
   function Fingerprint (Model : Elaboration_Graph_Context_Model) return Natural;

   function Build
     (Contexts : Elaboration_Graph_Context_Model) return Elaboration_Graph_Closure_Model;

   function Row_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Row_At
     (Model : Elaboration_Graph_Closure_Model;
      Index : Positive) return Elaboration_Graph_Closure_Info;
   function First_For_Node
     (Model : Elaboration_Graph_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Graph_Closure_Info;
   function Rows_For_Status
     (Model  : Elaboration_Graph_Closure_Model;
      Status : Elaboration_Graph_Closure_Status) return Elaboration_Graph_Result_Set;
   function Rows_For_Kind
     (Model : Elaboration_Graph_Closure_Model;
      Kind  : Elaboration_Graph_Context_Kind) return Elaboration_Graph_Result_Set;
   function Rows_For_Unit
     (Model : Elaboration_Graph_Closure_Model;
      Name  : String) return Elaboration_Graph_Result_Set;

   function Result_Count (Results : Elaboration_Graph_Result_Set) return Natural;
   function Result_At
     (Results : Elaboration_Graph_Result_Set;
      Index   : Positive) return Elaboration_Graph_Closure_Info;

   function Count_Status
     (Model  : Elaboration_Graph_Closure_Model;
      Status : Elaboration_Graph_Closure_Status) return Natural;
   function Count_Kind
     (Model : Elaboration_Graph_Closure_Model;
      Kind  : Elaboration_Graph_Context_Kind) return Natural;

   function Legal_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Transitive_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Body_Before_Use_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Call_Order_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Generic_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Cycle_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Policy_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Linked_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Coverage_Gate_Error_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Indeterminate_Count (Model : Elaboration_Graph_Closure_Model) return Natural;
   function Fingerprint (Model : Elaboration_Graph_Closure_Model) return Natural;

   function Has_Legality (Info : Elaboration_Graph_Closure_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Elaboration_Graph_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Elaboration_Graph_Closure_Info);

   type Elaboration_Graph_Context_Model is record
      Rows        : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Elaboration_Graph_Result_Set is record
      Rows : Row_Vectors.Vector;
   end record;

   type Elaboration_Graph_Closure_Model is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Elaboration_Graph_Closure_Legality;
