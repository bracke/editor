with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Elaboration_Dependence_Legality;
with Editor.Ada_Renaming_Alias_Visibility_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Unit_Completion_Order_Legality;

package Editor.Ada_Exception_Finalization_Legality is

   --  Case 1116 compiler-grade exception, raise, cleanup, finalization, and
   --  No_Return legality layer.  The package consumes bounded semantic
   --  metadata from the control-flow, accessibility/lifetime, contract/aspect,
   --  elaboration, unit-completion, and renaming/visibility legality layers.
   --  It performs no parsing, file IO, save/reload, dirty-state mutation,
   --  command routing, keybinding/workspace mutation, rendering, or compiler
   --  invocation.

   subtype Accessibility_Legality_Status is
     Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status;
   subtype Contract_Legality_Status is
     Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Status;
   subtype Flow_Legality_Status is
     Editor.Ada_Control_Flow_Legality.Flow_Legality_Status;
   subtype Elaboration_Legality_Status is
     Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Status;
   subtype Renaming_Legality_Status is
     Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Status;
   subtype Completion_Legality_Status is
     Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Status;

   type Exception_Context_Id is new Natural;
   No_Exception_Context : constant Exception_Context_Id := 0;

   type Exception_Legality_Id is new Natural;
   No_Exception_Legality : constant Exception_Legality_Id := 0;

   type Exception_Context_Kind is
     (Exception_Context_Raise_Statement,
      Exception_Context_Raise_Expression,
      Exception_Context_Reraise,
      Exception_Context_Handler,
      Exception_Context_Exception_Choice,
      Exception_Context_Exception_Renaming,
      Exception_Context_Propagation,
      Exception_Context_Controlled_Initialize,
      Exception_Context_Controlled_Adjust,
      Exception_Context_Controlled_Finalize,
      Exception_Context_Master_Finalization,
      Exception_Context_Cleanup_Action,
      Exception_Context_No_Return_Subprogram,
      Exception_Context_Task_Termination,
      Exception_Context_Unknown);

   type Exception_Target_State is
     (Exception_Target_None,
      Exception_Target_Resolved_Exception,
      Exception_Target_Resolved_Non_Exception,
      Exception_Target_Unresolved,
      Exception_Target_Ambiguous,
      Exception_Target_Renamed_Exception,
      Exception_Target_Private_View,
      Exception_Target_Limited_View,
      Exception_Target_Unknown);

   type Handler_State is
     (Handler_None,
      Handler_Normal,
      Handler_Duplicate_Choice,
      Handler_Others_Not_Last,
      Handler_Null_Handler,
      Handler_Unreachable,
      Handler_Choice_Unresolved,
      Handler_Choice_Ambiguous,
      Handler_Unknown);

   type Finalization_State is
     (Finalization_None,
      Finalization_Not_Required,
      Finalization_Required,
      Finalization_Controlled_Primitive_Present,
      Finalization_Controlled_Primitive_Missing,
      Finalization_Profile_Mismatch,
      Finalization_Order_Compatible,
      Finalization_Order_Error,
      Finalization_Exception_Propagates,
      Finalization_Abort_Unsafe,
      Finalization_Master_Unresolved,
      Finalization_Unknown);

   type No_Return_State is
     (No_Return_None,
      No_Return_Declared,
      No_Return_Raises_Or_Does_Not_Return,
      No_Return_Returns_Normally,
      No_Return_Missing_Raise_Or_Loop,
      No_Return_Contract_Conflict,
      No_Return_Unknown);

   type Exception_Legality_Status is
     (Exception_Legality_Not_Checked,
      Exception_Legality_Legal_Raise_Statement,
      Exception_Legality_Legal_Raise_Expression,
      Exception_Legality_Legal_Reraise,
      Exception_Legality_Legal_Handler,
      Exception_Legality_Legal_Exception_Renaming,
      Exception_Legality_Legal_Propagation,
      Exception_Legality_Legal_Finalization,
      Exception_Legality_Legal_No_Return,
      Exception_Legality_Raise_Target_Unresolved,
      Exception_Legality_Raise_Target_Ambiguous,
      Exception_Legality_Raise_Target_Not_Exception,
      Exception_Legality_Reraise_Outside_Handler,
      Exception_Legality_Handler_Choice_Unresolved,
      Exception_Legality_Handler_Choice_Ambiguous,
      Exception_Legality_Handler_Duplicate_Choice,
      Exception_Legality_Handler_Others_Not_Last,
      Exception_Legality_Handler_Unreachable,
      Exception_Legality_Raise_Expression_Type_Unresolved,
      Exception_Legality_Raise_Expression_Result_Incompatible,
      Exception_Legality_Exception_Rename_Target_Invalid,
      Exception_Legality_Finalization_Primitive_Missing,
      Exception_Legality_Finalization_Profile_Mismatch,
      Exception_Legality_Finalization_Order_Error,
      Exception_Legality_Finalization_Exception_Propagates,
      Exception_Legality_Finalization_Abort_Unsafe,
      Exception_Legality_Finalization_Master_Unresolved,
      Exception_Legality_No_Return_Returns_Normally,
      Exception_Legality_No_Return_Missing_Raise_Or_Loop,
      Exception_Legality_No_Return_Contract_Conflict,
      Exception_Legality_Private_View_Barrier,
      Exception_Legality_Limited_View_Barrier,
      Exception_Legality_Linked_Control_Flow_Error,
      Exception_Legality_Linked_Accessibility_Error,
      Exception_Legality_Linked_Contract_Error,
      Exception_Legality_Linked_Elaboration_Error,
      Exception_Legality_Linked_Renaming_Error,
      Exception_Legality_Linked_Completion_Order_Error,
      Exception_Legality_Indeterminate);

   type Exception_Context_Info is record
      Id                    : Exception_Context_Id := No_Exception_Context;
      Kind                  : Exception_Context_Kind := Exception_Context_Unknown;
      Target_State          : Exception_Target_State := Exception_Target_Unknown;
      Handler               : Handler_State := Handler_None;
      Finalization          : Finalization_State := Finalization_None;
      No_Return             : No_Return_State := No_Return_None;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Handler_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Finalization_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Exception_Target_Resolved : Boolean := True;
      Exception_Target_Ambiguous : Boolean := False;
      Target_Is_Exception   : Boolean := True;
      Reraise_In_Handler    : Boolean := True;
      Raise_Expression_Type_Resolved : Boolean := True;
      Raise_Expression_Result_Compatible : Boolean := True;
      Handler_Choice_Resolved : Boolean := True;
      Handler_Choice_Ambiguous : Boolean := False;
      Handler_Choice_Duplicate : Boolean := False;
      Handler_Others_Last   : Boolean := True;
      Handler_Is_Reachable  : Boolean := True;
      Finalization_Primitive_Present : Boolean := True;
      Finalization_Profile_Compatible : Boolean := True;
      Finalization_Order_Compatible : Boolean := True;
      Finalization_Can_Propagate_Exception : Boolean := False;
      Finalization_Abort_Safe : Boolean := True;
      Finalization_Master_Resolved : Boolean := True;
      Private_View_Barrier  : Boolean := False;
      Limited_View_Barrier  : Boolean := False;
      Flow_Status           : Flow_Legality_Status :=
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Not_Checked;
      Accessibility_Status  : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Contract_Status       : Contract_Legality_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Elaboration_Status    : Elaboration_Legality_Status :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Not_Checked;
      Renaming_Status       : Renaming_Legality_Status :=
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Not_Checked;
      Completion_Status     : Completion_Legality_Status :=
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Exception_Legality_Info is record
      Id                    : Exception_Legality_Id := No_Exception_Legality;
      Context               : Exception_Context_Id := No_Exception_Context;
      Kind                  : Exception_Context_Kind := Exception_Context_Unknown;
      Target_State          : Exception_Target_State := Exception_Target_Unknown;
      Handler               : Handler_State := Handler_None;
      Finalization          : Finalization_State := Finalization_None;
      No_Return             : No_Return_State := No_Return_None;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Handler_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Finalization_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Status                : Exception_Legality_Status := Exception_Legality_Not_Checked;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Flow_Status           : Flow_Legality_Status :=
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Not_Checked;
      Accessibility_Status  : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Contract_Status       : Contract_Legality_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Elaboration_Status    : Elaboration_Legality_Status :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Not_Checked;
      Renaming_Status       : Renaming_Legality_Status :=
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Not_Checked;
      Completion_Status     : Completion_Legality_Status :=
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Exception_Context_Model is private;
   type Exception_Result_Set is private;
   type Exception_Legality_Model is private;

   procedure Clear (Model : in out Exception_Context_Model);
   procedure Add_Context
     (Model : in out Exception_Context_Model;
      Info  : Exception_Context_Info);

   function Context_Count (Model : Exception_Context_Model) return Natural;
   function Context_At
     (Model : Exception_Context_Model;
      Index : Positive) return Exception_Context_Info;
   function Fingerprint (Model : Exception_Context_Model) return Natural;

   function Build (Contexts : Exception_Context_Model) return Exception_Legality_Model;

   function Legality_Count (Model : Exception_Legality_Model) return Natural;
   function Legality_At
     (Model : Exception_Legality_Model;
      Index : Positive) return Exception_Legality_Info;

   function First_For_Node
     (Model : Exception_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Exception_Legality_Info;
   function Rows_For_Status
     (Model  : Exception_Legality_Model;
      Status : Exception_Legality_Status) return Exception_Result_Set;
   function Rows_For_Kind
     (Model : Exception_Legality_Model;
      Kind  : Exception_Context_Kind) return Exception_Result_Set;
   function Rows_For_Target_State
     (Model : Exception_Legality_Model;
      State : Exception_Target_State) return Exception_Result_Set;
   function Rows_For_Handler
     (Model : Exception_Legality_Model;
      State : Handler_State) return Exception_Result_Set;
   function Rows_For_Finalization
     (Model : Exception_Legality_Model;
      State : Finalization_State) return Exception_Result_Set;
   function Rows_For_No_Return
     (Model : Exception_Legality_Model;
      State : No_Return_State) return Exception_Result_Set;
   function Rows_For_Name
     (Model : Exception_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Exception_Result_Set;

   function Result_Count (Set : Exception_Result_Set) return Natural;
   function Result_At
     (Set   : Exception_Result_Set;
      Index : Positive) return Exception_Legality_Info;

   function Legal_Count (Model : Exception_Legality_Model) return Natural;
   function Error_Count (Model : Exception_Legality_Model) return Natural;
   function Raise_Error_Count (Model : Exception_Legality_Model) return Natural;
   function Handler_Error_Count (Model : Exception_Legality_Model) return Natural;
   function Finalization_Error_Count (Model : Exception_Legality_Model) return Natural;
   function No_Return_Error_Count (Model : Exception_Legality_Model) return Natural;
   function View_Barrier_Count (Model : Exception_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Exception_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Exception_Legality_Model) return Natural;
   function Count_Status
     (Model  : Exception_Legality_Model;
      Status : Exception_Legality_Status) return Natural;
   function Count_Kind
     (Model : Exception_Legality_Model;
      Kind  : Exception_Context_Kind) return Natural;
   function Count_Target_State
     (Model : Exception_Legality_Model;
      State : Exception_Target_State) return Natural;
   function Count_Handler
     (Model : Exception_Legality_Model;
      State : Handler_State) return Natural;
   function Count_Finalization
     (Model : Exception_Legality_Model;
      State : Finalization_State) return Natural;
   function Count_No_Return
     (Model : Exception_Legality_Model;
      State : No_Return_State) return Natural;
   function Fingerprint (Model : Exception_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Exception_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Exception_Legality_Info);

   type Exception_Context_Model is record
      Contexts    : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Exception_Result_Set is record
      Results : Result_Vectors.Vector;
   end record;

   type Exception_Legality_Model is record
      Rows        : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Exception_Finalization_Legality;
