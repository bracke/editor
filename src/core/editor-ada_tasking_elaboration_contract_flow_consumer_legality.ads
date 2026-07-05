with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Effects_Legality;

package Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality is

   --  Case 1158 compiler-grade tasking/protected elaboration contract-flow
   --  consumer legality.
   --
   --  This layer connects elaboration-time Global/Depends and
   --  Refined_Global/Refined_Depends contract-flow conclusions into
   --  tasking/protected effect legality.  Task activation, protected
   --  operation effects, entry queues, accept bodies, requeue, select
   --  alternatives, abortable parts, delay alternatives, and terminate
   --  alternatives cannot remain confidently legal when their elaboration
   --  contract-flow evidence is missing, blocked by refined-flow errors,
   --  blocked by repaired coverage feedback, or indeterminate.

   package Task_Effects renames Editor.Ada_Tasking_Protected_Effects_Legality;
   package Elab_Contract renames Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality;

   type Tasking_Elab_Contract_Row_Id is new Natural;
   No_Tasking_Elab_Contract_Row : constant Tasking_Elab_Contract_Row_Id := 0;

   type Tasking_Elab_Contract_Context_Kind is
     (Tasking_Elab_Contract_Task_Activation,
      Tasking_Elab_Contract_Task_Termination,
      Tasking_Elab_Contract_Protected_Read,
      Tasking_Elab_Contract_Protected_Write,
      Tasking_Elab_Contract_Protected_Function_Call,
      Tasking_Elab_Contract_Protected_Procedure_Call,
      Tasking_Elab_Contract_Protected_Entry_Call,
      Tasking_Elab_Contract_Entry_Queue,
      Tasking_Elab_Contract_Entry_Barrier,
      Tasking_Elab_Contract_Accept_Body,
      Tasking_Elab_Contract_Requeue,
      Tasking_Elab_Contract_Select_Guard,
      Tasking_Elab_Contract_Select_Alternative,
      Tasking_Elab_Contract_Abortable_Part,
      Tasking_Elab_Contract_Delay_Alternative,
      Tasking_Elab_Contract_Terminate_Alternative,
      Tasking_Elab_Contract_Unknown);

   type Tasking_Elab_Contract_Status is
     (Tasking_Elab_Contract_Not_Checked,
      Tasking_Elab_Contract_Legal_Task_Activation_Accepted,
      Tasking_Elab_Contract_Legal_Task_Termination_Accepted,
      Tasking_Elab_Contract_Legal_Protected_Read_Accepted,
      Tasking_Elab_Contract_Legal_Protected_Write_Accepted,
      Tasking_Elab_Contract_Legal_Protected_Function_Call_Accepted,
      Tasking_Elab_Contract_Legal_Protected_Procedure_Call_Accepted,
      Tasking_Elab_Contract_Legal_Protected_Entry_Call_Accepted,
      Tasking_Elab_Contract_Legal_Entry_Queue_Accepted,
      Tasking_Elab_Contract_Legal_Entry_Barrier_Accepted,
      Tasking_Elab_Contract_Legal_Accept_Body_Accepted,
      Tasking_Elab_Contract_Legal_Requeue_Accepted,
      Tasking_Elab_Contract_Legal_Select_Guard_Accepted,
      Tasking_Elab_Contract_Legal_Select_Alternative_Accepted,
      Tasking_Elab_Contract_Legal_Abortable_Part_Accepted,
      Tasking_Elab_Contract_Legal_Delay_Alternative_Accepted,
      Tasking_Elab_Contract_Legal_Terminate_Alternative_Accepted,
      Tasking_Elab_Contract_Base_Tasking_Effect_Error,
      Tasking_Elab_Contract_Missing_Elaboration_Contract_Row,
      Tasking_Elab_Contract_Refined_Global_Missing_Read,
      Tasking_Elab_Contract_Refined_Global_Missing_Write,
      Tasking_Elab_Contract_Refined_Global_Mode_Mismatch,
      Tasking_Elab_Contract_Refined_Global_Extra_Item,
      Tasking_Elab_Contract_Refined_Depends_Missing_Edge,
      Tasking_Elab_Contract_Refined_Depends_Extra_Edge,
      Tasking_Elab_Contract_Refined_Depends_Source_Mode_Error,
      Tasking_Elab_Contract_Refined_Depends_Target_Mode_Error,
      Tasking_Elab_Contract_Call_Effect_Not_Propagated,
      Tasking_Elab_Contract_Coverage_Feedback_Blocker,
      Tasking_Elab_Contract_Linked_Flow_Graph_Error,
      Tasking_Elab_Contract_Base_Contract_Flow_Error,
      Tasking_Elab_Contract_Base_Elaboration_Error,
      Tasking_Elab_Contract_Multiple_Elaboration_Contract_Blockers,
      Tasking_Elab_Contract_Elaboration_Contract_Indeterminate,
      Tasking_Elab_Contract_Indeterminate);

   type Tasking_Elab_Contract_Context_Info is record
      Id                    : Tasking_Elab_Contract_Row_Id := No_Tasking_Elab_Contract_Row;
      Kind                  : Tasking_Elab_Contract_Context_Kind := Tasking_Elab_Contract_Unknown;
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
      Elaboration_Contract_Row : Elab_Contract.Elaboration_Contract_Flow_Row_Id := Elab_Contract.No_Elaboration_Contract_Flow_Row;
      Elaboration_Contract_Status : Elab_Contract.Elaboration_Contract_Flow_Status := Elab_Contract.Elaboration_Contract_Flow_Not_Checked;
      Elaboration_Contract_Matches : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Tasking_Elab_Contract_Info is record
      Id                    : Tasking_Elab_Contract_Row_Id := No_Tasking_Elab_Contract_Row;
      Context               : Tasking_Elab_Contract_Row_Id := No_Tasking_Elab_Contract_Row;
      Kind                  : Tasking_Elab_Contract_Context_Kind := Tasking_Elab_Contract_Unknown;
      Status                : Tasking_Elab_Contract_Status := Tasking_Elab_Contract_Not_Checked;
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
      Elaboration_Contract_Row : Elab_Contract.Elaboration_Contract_Flow_Row_Id := Elab_Contract.No_Elaboration_Contract_Flow_Row;
      Elaboration_Contract_Status : Elab_Contract.Elaboration_Contract_Flow_Status := Elab_Contract.Elaboration_Contract_Flow_Not_Checked;
      Elaboration_Contract_Matches : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Tasking_Elab_Contract_Context_Model is private;
   type Tasking_Elab_Contract_Set is private;
   type Tasking_Elab_Contract_Model is private;

   procedure Clear (Model : in out Tasking_Elab_Contract_Context_Model);
   procedure Add_Context
     (Model : in out Tasking_Elab_Contract_Context_Model;
      Info  : Tasking_Elab_Contract_Context_Info);

   function Context_Count (Model : Tasking_Elab_Contract_Context_Model) return Natural;
   function Context_At
     (Model : Tasking_Elab_Contract_Context_Model;
      Index : Positive) return Tasking_Elab_Contract_Context_Info;
   function Fingerprint (Model : Tasking_Elab_Contract_Context_Model) return Natural;

   function Build
     (Contexts : Tasking_Elab_Contract_Context_Model) return Tasking_Elab_Contract_Model;

   function Row_Count (Model : Tasking_Elab_Contract_Model) return Natural;
   function Row_At
     (Model : Tasking_Elab_Contract_Model;
      Index : Positive) return Tasking_Elab_Contract_Info;
   function First_For_Node
     (Model : Tasking_Elab_Contract_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Elab_Contract_Info;
   function Rows_For_Status
     (Model  : Tasking_Elab_Contract_Model;
      Status : Tasking_Elab_Contract_Status) return Tasking_Elab_Contract_Set;
   function Rows_For_Kind
     (Model : Tasking_Elab_Contract_Model;
      Kind  : Tasking_Elab_Contract_Context_Kind) return Tasking_Elab_Contract_Set;

   function Set_Count (Set : Tasking_Elab_Contract_Set) return Natural;
   function Set_At
     (Set   : Tasking_Elab_Contract_Set;
      Index : Positive) return Tasking_Elab_Contract_Info;

   function Count_Status
     (Model  : Tasking_Elab_Contract_Model;
      Status : Tasking_Elab_Contract_Status) return Natural;
   function Count_Kind
     (Model : Tasking_Elab_Contract_Model;
      Kind  : Tasking_Elab_Contract_Context_Kind) return Natural;

   function Legal_Count (Model : Tasking_Elab_Contract_Model) return Natural;
   function Error_Count (Model : Tasking_Elab_Contract_Model) return Natural;
   function Global_Error_Count (Model : Tasking_Elab_Contract_Model) return Natural;
   function Depends_Error_Count (Model : Tasking_Elab_Contract_Model) return Natural;
   function Propagation_Error_Count (Model : Tasking_Elab_Contract_Model) return Natural;
   function Coverage_Error_Count (Model : Tasking_Elab_Contract_Model) return Natural;
   function Tasking_Error_Count (Model : Tasking_Elab_Contract_Model) return Natural;
   function Indeterminate_Count (Model : Tasking_Elab_Contract_Model) return Natural;
   function Fingerprint (Model : Tasking_Elab_Contract_Model) return Natural;

   function Is_Legal (Status : Tasking_Elab_Contract_Status) return Boolean;
   function Is_Global_Error (Status : Tasking_Elab_Contract_Status) return Boolean;
   function Is_Depends_Error (Status : Tasking_Elab_Contract_Status) return Boolean;
   function Is_Propagation_Error (Status : Tasking_Elab_Contract_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Tasking_Elab_Contract_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Tasking_Elab_Contract_Info);

   type Tasking_Elab_Contract_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Tasking_Elab_Contract_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Tasking_Elab_Contract_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Global_Error_Total : Natural := 0;
      Depends_Error_Total : Natural := 0;
      Propagation_Error_Total : Natural := 0;
      Coverage_Error_Total : Natural := 0;
      Tasking_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality;
