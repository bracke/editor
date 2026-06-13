with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
with Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality;
with Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
with Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
with Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
with Editor.Ada_Repaired_Coverage_Semantic_Feedback;
with Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Effects_Legality;

package Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality is

   --  Pass1169 compiler-grade tasking/protected elaboration contract predicate/dataflow
   --  consumer legality.
   --
   --  This layer connects elaboration-time Global/Depends and
   --  Refined_Global/Refined_Depends contract predicate/dataflow conclusions into
   --  tasking/protected effect legality.  This replaces the narrower
   --  Global/Depends-only consumer path with predicate/invariant,
   --  definite-initialization, refined-flow, lifetime/accessibility,
   --  discriminant/variant, representation/freezing, and repaired coverage
   --  evidence.  Task activation, protected
   --  operation effects, entry queues, accept bodies, requeue, select
   --  alternatives, abortable parts, delay alternatives, and terminate
   --  alternatives cannot remain confidently legal when their elaboration
   --  contract predicate/dataflow evidence is missing, blocked by predicate/dataflow/object-state errors,
   --  blocked by repaired coverage feedback, or indeterminate.

   package Task_Effects renames Editor.Ada_Tasking_Protected_Effects_Legality;
   package Elab_Predicate renames Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
   package Contract_Predicate renames Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
   package Dataflow_Init renames Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
   package Init_Object_Flow renames Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality;
   package Discriminant_Representation renames Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
   package Object_Flow renames Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
   package Predicate_Dataflow renames Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
   package Repaired_Coverage renames Editor.Ada_Repaired_Coverage_Semantic_Feedback;

   type Tasking_Contract_Predicate_Row_Id is new Natural;
   No_Tasking_Contract_Predicate_Row : constant Tasking_Contract_Predicate_Row_Id := 0;

   type Tasking_Contract_Predicate_Context_Kind is
     (Tasking_Contract_Predicate_Task_Activation,
      Tasking_Contract_Predicate_Task_Termination,
      Tasking_Contract_Predicate_Protected_Read,
      Tasking_Contract_Predicate_Protected_Write,
      Tasking_Contract_Predicate_Protected_Function_Call,
      Tasking_Contract_Predicate_Protected_Procedure_Call,
      Tasking_Contract_Predicate_Protected_Entry_Call,
      Tasking_Contract_Predicate_Entry_Queue,
      Tasking_Contract_Predicate_Entry_Barrier,
      Tasking_Contract_Predicate_Accept_Body,
      Tasking_Contract_Predicate_Requeue,
      Tasking_Contract_Predicate_Select_Guard,
      Tasking_Contract_Predicate_Select_Alternative,
      Tasking_Contract_Predicate_Abortable_Part,
      Tasking_Contract_Predicate_Delay_Alternative,
      Tasking_Contract_Predicate_Terminate_Alternative,
      Tasking_Contract_Predicate_Unknown);

   type Tasking_Contract_Predicate_Status is
     (Tasking_Contract_Predicate_Not_Checked,
      Tasking_Contract_Predicate_Legal_Task_Activation_Accepted,
      Tasking_Contract_Predicate_Legal_Task_Termination_Accepted,
      Tasking_Contract_Predicate_Legal_Protected_Read_Accepted,
      Tasking_Contract_Predicate_Legal_Protected_Write_Accepted,
      Tasking_Contract_Predicate_Legal_Protected_Function_Call_Accepted,
      Tasking_Contract_Predicate_Legal_Protected_Procedure_Call_Accepted,
      Tasking_Contract_Predicate_Legal_Protected_Entry_Call_Accepted,
      Tasking_Contract_Predicate_Legal_Entry_Queue_Accepted,
      Tasking_Contract_Predicate_Legal_Entry_Barrier_Accepted,
      Tasking_Contract_Predicate_Legal_Accept_Body_Accepted,
      Tasking_Contract_Predicate_Legal_Requeue_Accepted,
      Tasking_Contract_Predicate_Legal_Select_Guard_Accepted,
      Tasking_Contract_Predicate_Legal_Select_Alternative_Accepted,
      Tasking_Contract_Predicate_Legal_Abortable_Part_Accepted,
      Tasking_Contract_Predicate_Legal_Delay_Alternative_Accepted,
      Tasking_Contract_Predicate_Legal_Terminate_Alternative_Accepted,
      Tasking_Contract_Predicate_Base_Tasking_Effect_Error,
      Tasking_Contract_Predicate_Missing_Elaboration_Predicate_Row,
      Tasking_Contract_Predicate_Missing_Contract_Predicate_Row,
      Tasking_Contract_Predicate_Base_Contract_Error,
      Tasking_Contract_Predicate_Base_Elaboration_Error,
      Tasking_Contract_Predicate_Predicate_Propagation_Blocker,
      Tasking_Contract_Predicate_Read_Before_Write_Blocker,
      Tasking_Contract_Predicate_Component_Read_Before_Write_Blocker,
      Tasking_Contract_Predicate_Partial_Initialization_Blocker,
      Tasking_Contract_Predicate_Missing_Out_Assignment_Blocker,
      Tasking_Contract_Predicate_Conditional_In_Out_Blocker,
      Tasking_Contract_Predicate_Return_Object_Initialization_Blocker,
      Tasking_Contract_Predicate_Branch_Loop_Merge_Blocker,
      Tasking_Contract_Predicate_Exception_Finalization_Path_Blocker,
      Tasking_Contract_Predicate_Use_After_Finalization_Blocker,
      Tasking_Contract_Predicate_Lifetime_Accessibility_Blocker,
      Tasking_Contract_Predicate_Discriminant_Variant_Blocker,
      Tasking_Contract_Predicate_Representation_Freezing_Blocker,
      Tasking_Contract_Predicate_Global_Depends_Blocker,
      Tasking_Contract_Predicate_Call_Propagation_Blocker,
      Tasking_Contract_Predicate_Generic_Flow_Blocker,
      Tasking_Contract_Predicate_Tasking_Protected_Flow_Blocker,
      Tasking_Contract_Predicate_Coverage_Blocker,
      Tasking_Contract_Predicate_Multiple_Matching_Blockers,
      Tasking_Contract_Predicate_Elaboration_Predicate_Indeterminate,
      Tasking_Contract_Predicate_Indeterminate);

   type Tasking_Contract_Predicate_Context_Info is record
      Id                    : Tasking_Contract_Predicate_Row_Id := No_Tasking_Contract_Predicate_Row;
      Kind                  : Tasking_Contract_Predicate_Context_Kind := Tasking_Contract_Predicate_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Select_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Tasking_Row           : Task_Effects.Tasking_Effect_Id := Task_Effects.No_Tasking_Effect;
      Tasking_Status        : Task_Effects.Tasking_Effect_Status := Task_Effects.Tasking_Effect_Not_Checked;
      Elaboration_Predicate_Row : Elab_Predicate.Elaboration_Contract_Predicate_Row_Id := Elab_Predicate.No_Elaboration_Contract_Predicate_Row;
      Elaboration_Predicate_Status : Elab_Predicate.Elaboration_Contract_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Not_Checked;
      Elaboration_Predicate_Matches : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Tasking_Contract_Predicate_Info is record
      Id                    : Tasking_Contract_Predicate_Row_Id := No_Tasking_Contract_Predicate_Row;
      Context               : Tasking_Contract_Predicate_Row_Id := No_Tasking_Contract_Predicate_Row;
      Kind                  : Tasking_Contract_Predicate_Context_Kind := Tasking_Contract_Predicate_Unknown;
      Status                : Tasking_Contract_Predicate_Status := Tasking_Contract_Predicate_Not_Checked;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Select_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Caller_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Callee_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Tasking_Row           : Task_Effects.Tasking_Effect_Id := Task_Effects.No_Tasking_Effect;
      Tasking_Status        : Task_Effects.Tasking_Effect_Status := Task_Effects.Tasking_Effect_Not_Checked;
      Elaboration_Predicate_Row : Elab_Predicate.Elaboration_Contract_Predicate_Row_Id := Elab_Predicate.No_Elaboration_Contract_Predicate_Row;
      Elaboration_Predicate_Status : Elab_Predicate.Elaboration_Contract_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Not_Checked;
      Elaboration_Predicate_Matches : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Tasking_Contract_Predicate_Context_Model is private;
   type Tasking_Contract_Predicate_Set is private;
   type Tasking_Contract_Predicate_Model is private;

   procedure Clear (Model : in out Tasking_Contract_Predicate_Context_Model);
   procedure Add_Context
     (Model : in out Tasking_Contract_Predicate_Context_Model;
      Info  : Tasking_Contract_Predicate_Context_Info);

   function Context_Count (Model : Tasking_Contract_Predicate_Context_Model) return Natural;
   function Context_At
     (Model : Tasking_Contract_Predicate_Context_Model;
      Index : Positive) return Tasking_Contract_Predicate_Context_Info;
   function Fingerprint (Model : Tasking_Contract_Predicate_Context_Model) return Natural;

   function Build
     (Contexts : Tasking_Contract_Predicate_Context_Model) return Tasking_Contract_Predicate_Model;

   function Row_Count (Model : Tasking_Contract_Predicate_Model) return Natural;
   function Row_At
     (Model : Tasking_Contract_Predicate_Model;
      Index : Positive) return Tasking_Contract_Predicate_Info;
   function First_For_Node
     (Model : Tasking_Contract_Predicate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Contract_Predicate_Info;
   function Rows_For_Status
     (Model  : Tasking_Contract_Predicate_Model;
      Status : Tasking_Contract_Predicate_Status) return Tasking_Contract_Predicate_Set;
   function Rows_For_Kind
     (Model : Tasking_Contract_Predicate_Model;
      Kind  : Tasking_Contract_Predicate_Context_Kind) return Tasking_Contract_Predicate_Set;

   function Set_Count (Set : Tasking_Contract_Predicate_Set) return Natural;
   function Set_At
     (Set   : Tasking_Contract_Predicate_Set;
      Index : Positive) return Tasking_Contract_Predicate_Info;

   function Count_Status
     (Model  : Tasking_Contract_Predicate_Model;
      Status : Tasking_Contract_Predicate_Status) return Natural;
   function Count_Kind
     (Model : Tasking_Contract_Predicate_Model;
      Kind  : Tasking_Contract_Predicate_Context_Kind) return Natural;

   function Legal_Count (Model : Tasking_Contract_Predicate_Model) return Natural;
   function Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural;
   function Initialization_Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural;
   function Predicate_Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural;
   function Dataflow_Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural;
   function Coverage_Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural;
   function Tasking_Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural;
   function Indeterminate_Count (Model : Tasking_Contract_Predicate_Model) return Natural;
   function Fingerprint (Model : Tasking_Contract_Predicate_Model) return Natural;

   function Is_Legal (Status : Tasking_Contract_Predicate_Status) return Boolean;
   function Is_Initialization_Error (Status : Tasking_Contract_Predicate_Status) return Boolean;
   function Is_Predicate_Error (Status : Tasking_Contract_Predicate_Status) return Boolean;
   function Is_Dataflow_Error (Status : Tasking_Contract_Predicate_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Tasking_Contract_Predicate_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Tasking_Contract_Predicate_Info);

   type Tasking_Contract_Predicate_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Tasking_Contract_Predicate_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Tasking_Contract_Predicate_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Initialization_Error_Total : Natural := 0;
      Predicate_Error_Total : Natural := 0;
      Dataflow_Error_Total : Natural := 0;
      Coverage_Error_Total : Natural := 0;
      Tasking_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
