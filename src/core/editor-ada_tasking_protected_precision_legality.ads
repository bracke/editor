with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Precision_Legality;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Elaboration_Precision_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Legality;

package Editor.Ada_Tasking_Protected_Precision_Legality is

   --  Case 1130 compiler-grade tasking/protected precision layer.
   --
   --  This package deepens Case 1103 tasking/protected legality by connecting
   --  protected-state effects, entry-barrier dataflow, accept/requeue/select
   --  flow, task activation/elaboration, and accessibility-sensitive queued
   --  entry-call facts.  Callers supply bounded semantic facts already owned by
   --  the analysis snapshot.  This package performs no parsing, file IO,
   --  editor mutation, command routing, workspace mutation, or rendering work.

   subtype Tasking_Legality_Status is
     Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Status;
   subtype Tasking_Context_Kind is
     Editor.Ada_Tasking_Protected_Legality.Tasking_Context_Kind;
   subtype Dataflow_Legality_Status is
     Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Status;
   subtype Elaboration_Precision_Status is
     Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Status;
   subtype Accessibility_Precision_Status is
     Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Status;

   type Tasking_Precision_Context_Id is new Natural;
   No_Tasking_Precision_Context : constant Tasking_Precision_Context_Id := 0;

   type Tasking_Precision_Legality_Id is new Natural;
   No_Tasking_Precision_Legality : constant Tasking_Precision_Legality_Id := 0;

   type Tasking_Precision_Context_Kind is
     (Tasking_Precision_Context_Task_Activation,
      Tasking_Precision_Context_Task_Body,
      Tasking_Precision_Context_Protected_Function,
      Tasking_Precision_Context_Protected_Procedure,
      Tasking_Precision_Context_Protected_Entry,
      Tasking_Precision_Context_Entry_Barrier,
      Tasking_Precision_Context_Entry_Family_Index,
      Tasking_Precision_Context_Accept_Statement,
      Tasking_Precision_Context_Requeue_Statement,
      Tasking_Precision_Context_Select_Alternative,
      Tasking_Precision_Context_Queued_Entry_Call,
      Tasking_Precision_Context_Protected_Object_State,
      Tasking_Precision_Context_Unknown);

   type Tasking_Precision_Status is
     (Tasking_Precision_Not_Checked,
      Tasking_Precision_Legal_Task_Activation,
      Tasking_Precision_Legal_Task_Body,
      Tasking_Precision_Legal_Protected_Function,
      Tasking_Precision_Legal_Protected_Procedure,
      Tasking_Precision_Legal_Protected_Entry,
      Tasking_Precision_Legal_Entry_Barrier,
      Tasking_Precision_Legal_Entry_Family_Index,
      Tasking_Precision_Legal_Accept,
      Tasking_Precision_Legal_Requeue,
      Tasking_Precision_Legal_Select_Alternative,
      Tasking_Precision_Legal_Queued_Entry_Call,
      Tasking_Precision_Activation_Elaboration_Error,
      Tasking_Precision_Task_Body_Not_Elaborated,
      Tasking_Precision_Protected_Function_Writes_State,
      Tasking_Precision_Protected_Function_Calls_Entry,
      Tasking_Precision_Protected_Function_Dataflow_Write,
      Tasking_Precision_Protected_Procedure_Barrier,
      Tasking_Precision_Protected_Procedure_Global_Mismatch,
      Tasking_Precision_Protected_Entry_Barrier_Missing,
      Tasking_Precision_Protected_Entry_Barrier_Not_Boolean,
      Tasking_Precision_Entry_Barrier_Read_Before_Write,
      Tasking_Precision_Entry_Barrier_Global_Mismatch,
      Tasking_Precision_Entry_Family_Index_Non_Static,
      Tasking_Precision_Entry_Family_Index_Type_Mismatch,
      Tasking_Precision_Accept_Outside_Task_Body,
      Tasking_Precision_Accept_Profile_Mismatch,
      Tasking_Precision_Requeue_Target_Unresolved,
      Tasking_Precision_Requeue_To_Non_Entry,
      Tasking_Precision_Requeue_With_Abort_Not_Allowed,
      Tasking_Precision_Select_Alternative_Not_Open,
      Tasking_Precision_Select_Terminate_With_Delay,
      Tasking_Precision_Queued_Call_Accessibility_Risk,
      Tasking_Precision_Protected_State_Uninitialized,
      Tasking_Precision_Protected_State_Use_After_Finalization,
      Tasking_Precision_Linked_Tasking_Error,
      Tasking_Precision_Linked_Dataflow_Error,
      Tasking_Precision_Linked_Elaboration_Error,
      Tasking_Precision_Linked_Accessibility_Error,
      Tasking_Precision_Indeterminate);

   type Tasking_Precision_Context_Info is record
      Id                         : Tasking_Precision_Context_Id := No_Tasking_Precision_Context;
      Kind                       : Tasking_Precision_Context_Kind := Tasking_Precision_Context_Unknown;
      Base_Kind                  : Tasking_Context_Kind := Editor.Ada_Tasking_Protected_Legality.Tasking_Context_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Barrier_Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Base_Tasking_Status        : Tasking_Legality_Status := Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Not_Checked;
      Dataflow_Status            : Dataflow_Legality_Status := Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Not_Checked;
      Elaboration_Status         : Elaboration_Precision_Status := Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Not_Checked;
      Accessibility_Status       : Accessibility_Precision_Status := Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Not_Checked;
      Task_Activated             : Boolean := True;
      Task_Body_Elaborated       : Boolean := True;
      Protected_Function_Writes_State : Boolean := False;
      Protected_Function_Calls_Entry  : Boolean := False;
      Protected_Procedure_Has_Barrier : Boolean := False;
      Protected_Procedure_Global_Mismatch : Boolean := False;
      Barrier_Present            : Boolean := True;
      Barrier_Is_Boolean         : Boolean := True;
      Barrier_Reads_State        : Boolean := False;
      Barrier_Global_Mismatch    : Boolean := False;
      Entry_Family_Index_Static  : Boolean := True;
      Entry_Family_Index_Compatible : Boolean := True;
      Accept_In_Task_Body        : Boolean := True;
      Accept_Profile_Matches     : Boolean := True;
      Requeue_Target_Resolved    : Boolean := True;
      Requeue_Target_Is_Entry    : Boolean := True;
      Requeue_With_Abort_Allowed : Boolean := True;
      Select_Alternative_Open    : Boolean := True;
      Select_Terminate_With_Delay : Boolean := False;
      Queued_Call_Accessibility_Check : Boolean := False;
      Protected_State_Initialized : Boolean := True;
      Protected_State_Finalized  : Boolean := False;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
   end record;

   type Tasking_Precision_Legality_Info is record
      Id                         : Tasking_Precision_Legality_Id := No_Tasking_Precision_Legality;
      Context                    : Tasking_Precision_Context_Id := No_Tasking_Precision_Context;
      Kind                       : Tasking_Precision_Context_Kind := Tasking_Precision_Context_Unknown;
      Base_Kind                  : Tasking_Context_Kind := Editor.Ada_Tasking_Protected_Legality.Tasking_Context_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Barrier_Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                     : Tasking_Precision_Status := Tasking_Precision_Not_Checked;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Base_Tasking_Status        : Tasking_Legality_Status := Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Not_Checked;
      Dataflow_Status            : Dataflow_Legality_Status := Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Not_Checked;
      Elaboration_Status         : Elaboration_Precision_Status := Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Not_Checked;
      Accessibility_Status       : Accessibility_Precision_Status := Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Not_Checked;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Tasking_Precision_Context_Model is private;
   type Tasking_Precision_Result_Set is private;
   type Tasking_Precision_Legality_Model is private;

   procedure Clear (Model : in out Tasking_Precision_Context_Model);
   procedure Add_Context
     (Model : in out Tasking_Precision_Context_Model;
      Info  : Tasking_Precision_Context_Info);

   function Context_Count (Model : Tasking_Precision_Context_Model) return Natural;
   function Context_At
     (Model : Tasking_Precision_Context_Model;
      Index : Positive) return Tasking_Precision_Context_Info;
   function Fingerprint (Model : Tasking_Precision_Context_Model) return Natural;

   function Build
     (Contexts : Tasking_Precision_Context_Model) return Tasking_Precision_Legality_Model;

   function Legality_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function Legality_At
     (Model : Tasking_Precision_Legality_Model;
      Index : Positive) return Tasking_Precision_Legality_Info;

   function First_For_Node
     (Model : Tasking_Precision_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Precision_Legality_Info;
   function Rows_For_Status
     (Model  : Tasking_Precision_Legality_Model;
      Status : Tasking_Precision_Status) return Tasking_Precision_Result_Set;
   function Rows_For_Kind
     (Model : Tasking_Precision_Legality_Model;
      Kind  : Tasking_Precision_Context_Kind) return Tasking_Precision_Result_Set;
   function Rows_For_Object
     (Model : Tasking_Precision_Legality_Model;
      Name  : String) return Tasking_Precision_Result_Set;
   function Rows_For_Entry
     (Model : Tasking_Precision_Legality_Model;
      Name  : String) return Tasking_Precision_Result_Set;

   function Result_Count (Results : Tasking_Precision_Result_Set) return Natural;
   function Result_At
     (Results : Tasking_Precision_Result_Set;
      Index   : Positive) return Tasking_Precision_Legality_Info;

   function Count_Status
     (Model  : Tasking_Precision_Legality_Model;
      Status : Tasking_Precision_Status) return Natural;
   function Count_Kind
     (Model : Tasking_Precision_Legality_Model;
      Kind  : Tasking_Precision_Context_Kind) return Natural;

   function Legal_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function Error_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function Activation_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function Protected_Operation_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function Barrier_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function Accept_Requeue_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function Select_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function State_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Tasking_Precision_Legality_Model) return Natural;
   function Fingerprint (Model : Tasking_Precision_Legality_Model) return Natural;

   function Has_Legality (Info : Tasking_Precision_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tasking_Precision_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tasking_Precision_Legality_Info);

   type Tasking_Precision_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Tasking_Precision_Result_Set is record
      Items : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Tasking_Precision_Legality_Model is record
      Items : Legality_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Activation_Error_Total : Natural := 0;
      Protected_Operation_Error_Total : Natural := 0;
      Barrier_Error_Total : Natural := 0;
      Accept_Requeue_Error_Total : Natural := 0;
      Select_Error_Total : Natural := 0;
      State_Error_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tasking_Protected_Precision_Legality;
