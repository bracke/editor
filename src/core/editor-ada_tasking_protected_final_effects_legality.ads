with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Tasking_Protected_Effects_Legality;

package Editor.Ada_Tasking_Protected_Final_Effects_Legality is

   --  Case 1185 compiler-grade tasking/protected final effect legality.
   --
   --  This layer closes hard tasking/protected effect checks after the richer
   --  elaboration, contract/predicate/dataflow, representation/freezing,
   --  accessibility, and discriminant consumer chain has been established.  It
   --  keeps protected-action reentrancy, protected visible-state mutation,
   --  barrier side-effect restrictions, entry queue safety, requeue-with-abort
   --  safety, abort/finalization hazards, delay/terminate alternative rules, and
   --  task activation/termination ordering from remaining confidently legal when
   --  any dependent semantic evidence is missing, blocked, duplicated, or
   --  indeterminate.  The model is deterministic and snapshot-owned; it mutates
   --  no buffers, rendering state, command state, workspace state, or dirty bits.

   package Access_Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   package Disc_Consumer renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   package Elab_Final renames Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
   package Rep_CPD renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   package Tasking_CPD renames Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   package Task_Effects renames Editor.Ada_Tasking_Protected_Effects_Legality;

   type Final_Tasking_Row_Id is new Natural;
   No_Final_Tasking_Row : constant Final_Tasking_Row_Id := 0;

   type Final_Tasking_Context_Kind is
     (Final_Tasking_Task_Activation,
      Final_Tasking_Task_Termination,
      Final_Tasking_Protected_Read,
      Final_Tasking_Protected_Write,
      Final_Tasking_Protected_Function_Call,
      Final_Tasking_Protected_Procedure_Call,
      Final_Tasking_Protected_Entry_Call,
      Final_Tasking_Protected_Action_Reentrancy,
      Final_Tasking_Protected_State_Mutation,
      Final_Tasking_Entry_Queue,
      Final_Tasking_Entry_Barrier,
      Final_Tasking_Barrier_Side_Effect,
      Final_Tasking_Accept_Body,
      Final_Tasking_Requeue,
      Final_Tasking_Requeue_With_Abort,
      Final_Tasking_Select_Guard,
      Final_Tasking_Select_Alternative,
      Final_Tasking_Abortable_Part,
      Final_Tasking_Delay_Alternative,
      Final_Tasking_Terminate_Alternative,
      Final_Tasking_Unknown);

   type Final_Tasking_Status is
     (Final_Tasking_Not_Checked,
      Final_Tasking_Legal_Task_Activation_Accepted,
      Final_Tasking_Legal_Task_Termination_Accepted,
      Final_Tasking_Legal_Protected_Read_Accepted,
      Final_Tasking_Legal_Protected_Write_Accepted,
      Final_Tasking_Legal_Protected_Function_Call_Accepted,
      Final_Tasking_Legal_Protected_Procedure_Call_Accepted,
      Final_Tasking_Legal_Protected_Entry_Call_Accepted,
      Final_Tasking_Legal_Protected_Reentrancy_Accepted,
      Final_Tasking_Legal_Protected_State_Mutation_Accepted,
      Final_Tasking_Legal_Entry_Queue_Accepted,
      Final_Tasking_Legal_Entry_Barrier_Accepted,
      Final_Tasking_Legal_Barrier_Side_Effect_Accepted,
      Final_Tasking_Legal_Accept_Body_Accepted,
      Final_Tasking_Legal_Requeue_Accepted,
      Final_Tasking_Legal_Requeue_With_Abort_Accepted,
      Final_Tasking_Legal_Select_Guard_Accepted,
      Final_Tasking_Legal_Select_Alternative_Accepted,
      Final_Tasking_Legal_Abortable_Part_Accepted,
      Final_Tasking_Legal_Delay_Alternative_Accepted,
      Final_Tasking_Legal_Terminate_Alternative_Accepted,
      Final_Tasking_Base_Effect_Error,
      Final_Tasking_Protected_Reentrancy_Blocker,
      Final_Tasking_Protected_State_Mutation_Blocker,
      Final_Tasking_Protected_Function_Entry_Call_Blocker,
      Final_Tasking_Barrier_Not_Boolean_Blocker,
      Final_Tasking_Barrier_Side_Effect_Blocker,
      Final_Tasking_Entry_Queue_Blocker,
      Final_Tasking_Accept_Body_Effect_Blocker,
      Final_Tasking_Requeue_Target_Blocker,
      Final_Tasking_Requeue_With_Abort_Unsafe,
      Final_Tasking_Select_Alternative_Blocker,
      Final_Tasking_Abort_Finalization_Blocker,
      Final_Tasking_Delay_Alternative_Blocker,
      Final_Tasking_Terminate_Alternative_Blocker,
      Final_Tasking_Missing_Tasking_CPD_Row,
      Final_Tasking_Tasking_CPD_Blocker,
      Final_Tasking_Missing_Elaboration_Row,
      Final_Tasking_Elaboration_Blocker,
      Final_Tasking_Missing_Representation_Row,
      Final_Tasking_Representation_Blocker,
      Final_Tasking_Missing_Accessibility_Row,
      Final_Tasking_Accessibility_Blocker,
      Final_Tasking_Missing_Discriminant_Row,
      Final_Tasking_Discriminant_Blocker,
      Final_Tasking_Global_Depends_Blocker,
      Final_Tasking_Predicate_Invariant_Blocker,
      Final_Tasking_Initialization_Blocker,
      Final_Tasking_Lifetime_Accessibility_Blocker,
      Final_Tasking_Coverage_Blocker,
      Final_Tasking_Multiple_Matching_Blockers,
      Final_Tasking_Indeterminate);

   type Final_Tasking_Context_Info is record
      Id                         : Final_Tasking_Row_Id := No_Final_Tasking_Row;
      Kind                       : Final_Tasking_Context_Kind := Final_Tasking_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Select_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Tasking_Effect_Row         : Task_Effects.Tasking_Effect_Id := Task_Effects.No_Tasking_Effect;
      Tasking_Effect_Status      : Task_Effects.Tasking_Effect_Status := Task_Effects.Tasking_Effect_Not_Checked;
      Tasking_CPD_Row            : Tasking_CPD.Tasking_Contract_Predicate_Row_Id :=
        Tasking_CPD.No_Tasking_Contract_Predicate_Row;
      Tasking_CPD_Status         : Tasking_CPD.Tasking_Contract_Predicate_Status :=
        Tasking_CPD.Tasking_Contract_Predicate_Not_Checked;
      Tasking_CPD_Matches        : Natural := 0;
      Elaboration_Row            : Elab_Final.Final_Elaboration_Row_Id := Elab_Final.No_Final_Elaboration_Row;
      Elaboration_Status         : Elab_Final.Final_Elaboration_Status := Elab_Final.Final_Elaboration_Not_Checked;
      Elaboration_Matches        : Natural := 0;
      Representation_Row         : Rep_CPD.Representation_Tasking_CPD_Row_Id := Rep_CPD.No_Representation_Tasking_CPD_Row;
      Representation_Status      : Rep_CPD.Representation_Tasking_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Not_Checked;
      Representation_Matches     : Natural := 0;
      Accessibility_Row          : Access_Final.Master_Scope_Final_Row_Id := Access_Final.No_Master_Scope_Final_Row;
      Accessibility_Status       : Access_Final.Master_Scope_Final_Status := Access_Final.Master_Scope_Final_Not_Checked;
      Accessibility_Matches      : Natural := 0;
      Discriminant_Row           : Disc_Consumer.Discriminant_Consumer_Row_Id := Disc_Consumer.No_Discriminant_Consumer_Row;
      Discriminant_Status        : Disc_Consumer.Discriminant_Consumer_Status := Disc_Consumer.Discriminant_Consumer_Not_Checked;
      Discriminant_Matches       : Natural := 0;
      Requires_Representation    : Boolean := False;
      Requires_Accessibility     : Boolean := False;
      Requires_Discriminant      : Boolean := False;
      Protected_Action_Reentrant : Boolean := False;
      Protected_Function_Writes_State : Boolean := False;
      Protected_Function_Calls_Entry  : Boolean := False;
      Barrier_Has_Side_Effect    : Boolean := False;
      Requeue_With_Abort         : Boolean := False;
      Requeue_Abort_Safe         : Boolean := True;
      Abortable_Finalization_Safe : Boolean := True;
      Terminate_Allowed          : Boolean := True;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
   end record;

   type Final_Tasking_Info is record
      Id                         : Final_Tasking_Row_Id := No_Final_Tasking_Row;
      Context                    : Final_Tasking_Row_Id := No_Final_Tasking_Row;
      Kind                       : Final_Tasking_Context_Kind := Final_Tasking_Unknown;
      Status                     : Final_Tasking_Status := Final_Tasking_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Tasking_Effect_Row         : Task_Effects.Tasking_Effect_Id := Task_Effects.No_Tasking_Effect;
      Tasking_Effect_Status      : Task_Effects.Tasking_Effect_Status := Task_Effects.Tasking_Effect_Not_Checked;
      Tasking_CPD_Row            : Tasking_CPD.Tasking_Contract_Predicate_Row_Id :=
        Tasking_CPD.No_Tasking_Contract_Predicate_Row;
      Tasking_CPD_Status         : Tasking_CPD.Tasking_Contract_Predicate_Status :=
        Tasking_CPD.Tasking_Contract_Predicate_Not_Checked;
      Elaboration_Row            : Elab_Final.Final_Elaboration_Row_Id := Elab_Final.No_Final_Elaboration_Row;
      Elaboration_Status         : Elab_Final.Final_Elaboration_Status := Elab_Final.Final_Elaboration_Not_Checked;
      Representation_Row         : Rep_CPD.Representation_Tasking_CPD_Row_Id := Rep_CPD.No_Representation_Tasking_CPD_Row;
      Representation_Status      : Rep_CPD.Representation_Tasking_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Not_Checked;
      Accessibility_Row          : Access_Final.Master_Scope_Final_Row_Id := Access_Final.No_Master_Scope_Final_Row;
      Accessibility_Status       : Access_Final.Master_Scope_Final_Status := Access_Final.Master_Scope_Final_Not_Checked;
      Discriminant_Row           : Disc_Consumer.Discriminant_Consumer_Row_Id := Disc_Consumer.No_Discriminant_Consumer_Row;
      Discriminant_Status        : Disc_Consumer.Discriminant_Consumer_Status := Disc_Consumer.Discriminant_Consumer_Not_Checked;
      Source_Fingerprint         : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Final_Tasking_Context_Model is private;
   type Final_Tasking_Set is private;
   type Final_Tasking_Model is private;

   procedure Clear (Model : in out Final_Tasking_Context_Model);
   procedure Add_Context (Model : in out Final_Tasking_Context_Model; Info : Final_Tasking_Context_Info);
   function Context_Count (Model : Final_Tasking_Context_Model) return Natural;
   function Context_At (Model : Final_Tasking_Context_Model; Index : Positive) return Final_Tasking_Context_Info;
   function Fingerprint (Model : Final_Tasking_Context_Model) return Natural;

   function Build (Contexts : Final_Tasking_Context_Model) return Final_Tasking_Model;
   function Row_Count (Model : Final_Tasking_Model) return Natural;
   function Row_At (Model : Final_Tasking_Model; Index : Positive) return Final_Tasking_Info;
   function First_For_Node (Model : Final_Tasking_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Final_Tasking_Info;
   function Rows_For_Status (Model : Final_Tasking_Model; Status : Final_Tasking_Status) return Final_Tasking_Set;
   function Rows_For_Kind (Model : Final_Tasking_Model; Kind : Final_Tasking_Context_Kind) return Final_Tasking_Set;
   function Rows_For_Object_Name (Model : Final_Tasking_Model; Object_Name : String) return Final_Tasking_Set;
   function Set_Count (Set : Final_Tasking_Set) return Natural;
   function Set_At (Set : Final_Tasking_Set; Index : Positive) return Final_Tasking_Info;
   function Count_Status (Model : Final_Tasking_Model; Status : Final_Tasking_Status) return Natural;
   function Count_Kind (Model : Final_Tasking_Model; Kind : Final_Tasking_Context_Kind) return Natural;
   function Legal_Count (Model : Final_Tasking_Model) return Natural;
   function Error_Count (Model : Final_Tasking_Model) return Natural;
   function Base_Effect_Error_Count (Model : Final_Tasking_Model) return Natural;
   function Elaboration_Error_Count (Model : Final_Tasking_Model) return Natural;
   function Representation_Error_Count (Model : Final_Tasking_Model) return Natural;
   function Accessibility_Error_Count (Model : Final_Tasking_Model) return Natural;
   function Discriminant_Error_Count (Model : Final_Tasking_Model) return Natural;
   function Indeterminate_Count (Model : Final_Tasking_Model) return Natural;
   function Fingerprint (Model : Final_Tasking_Model) return Natural;

   function Is_Legal (Status : Final_Tasking_Status) return Boolean;
   function Is_Base_Effect_Error (Status : Final_Tasking_Status) return Boolean;
   function Is_Elaboration_Error (Status : Final_Tasking_Status) return Boolean;
   function Is_Representation_Error (Status : Final_Tasking_Status) return Boolean;
   function Is_Accessibility_Error (Status : Final_Tasking_Status) return Boolean;
   function Is_Discriminant_Error (Status : Final_Tasking_Status) return Boolean;
   function Is_Indeterminate (Status : Final_Tasking_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Final_Tasking_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Final_Tasking_Info);

   type Final_Tasking_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Final_Tasking_Set is record
      Rows : Row_Vectors.Vector;
   end record;

   type Final_Tasking_Model is record
      Rows : Row_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tasking_Protected_Final_Effects_Legality;
