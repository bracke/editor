with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Exception_Finalization_Vertical_Slice_Legality is

   --  Pass1310 vertical-slice exception/finalization legality.
   --  This package checks concrete Ada exception propagation and finalization
   --  rules against source-shaped semantic rows.  It models language legality
   --  directly instead of adding another closure, provenance, or diagnostic
   --  wrapper around previous semantic evidence.

   type Event_Id is new Natural;
   No_Event : constant Event_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Event_Kind is
     (Event_Raise_Statement,
      Event_Raise_Expression,
      Event_Exception_Handler,
      Event_Handled_Sequence,
      Event_Controlled_Object_Finalization,
      Event_Limited_Controlled_Finalization,
      Event_Task_Termination_Finalization,
      Event_Abort_Finalization,
      Event_Abortable_Select_Finalization,
      Event_Exception_Renaming,
      Event_Exception_Propagation,
      Event_Unknown);

   type Entity_Kind is
     (Entity_Unknown,
      Entity_Exception,
      Entity_Handler,
      Entity_Object,
      Entity_Controlled_Object,
      Entity_Limited_Controlled_Object,
      Entity_Task,
      Entity_Protected_Object,
      Entity_Renamed_Exception,
      Entity_Subprogram,
      Entity_Package);

   type Type_Class is
     (Type_Unknown,
      Type_Exception,
      Type_Controlled,
      Type_Limited_Controlled,
      Type_Access,
      Type_Task,
      Type_Protected,
      Type_Record,
      Type_Private,
      Type_Limited);

   type Propagation_Mode is
     (Propagation_None,
      Propagation_Handled_Locally,
      Propagation_Propagates,
      Propagation_Reraises,
      Propagation_Suppressed,
      Propagation_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Context,
      Legality_Exception_Missing,
      Legality_Exception_Not_Visible,
      Legality_Exception_Kind_Mismatch,
      Legality_Handler_Choice_Missing,
      Legality_Handler_Choice_Duplicate,
      Legality_Handler_Choice_Unreachable,
      Legality_Reraise_Outside_Handler,
      Legality_Propagation_Unhandled,
      Legality_Finalization_Missing,
      Legality_Finalization_Order_Mismatch,
      Legality_Controlled_Adjust_Finalize_Mismatch,
      Legality_Limited_Finalization_Blocked,
      Legality_Abort_Finalization_Unsafe,
      Legality_Task_Termination_Finalization_Blocked,
      Legality_Accessibility_Blocked,
      Legality_Renaming_Blocked,
      Legality_Shared_State_Blocked,
      Legality_Representation_Blocked,
      Legality_Predicate_Blocked,
      Legality_Elaboration_Blocked,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Effect_Fingerprint_Mismatch,
      Legality_Substitution_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Event_Info is record
      Id       : Event_Id := No_Event;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Event_Kind := Event_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Context : Boolean := True;
      Has_Exception_Entity : Boolean := True;
      Exception_Visible : Boolean := True;
      Expected_Exception_Kind : Entity_Kind := Entity_Exception;
      Actual_Exception_Kind   : Entity_Kind := Entity_Exception;
      Exception_Type : Type_Class := Type_Exception;

      Handler_Choice_Present : Boolean := True;
      Handler_Choice_Duplicate : Boolean := False;
      Handler_Choice_Reachable : Boolean := True;
      In_Exception_Handler : Boolean := False;
      Propagation : Propagation_Mode := Propagation_None;
      Requires_Local_Handler : Boolean := False;

      Has_Finalization_Procedure : Boolean := True;
      Finalization_Order_Legal : Boolean := True;
      Adjust_Finalize_Profile_Matches : Boolean := True;
      Limited_Finalization_Legal : Boolean := True;
      Abort_Finalization_Safe : Boolean := True;
      Task_Termination_Finalization_Legal : Boolean := True;

      Accessibility_Legal : Boolean := True;
      Renaming_Legal : Boolean := True;
      Shared_State_Legal : Boolean := True;
      Representation_Legal : Boolean := True;
      Predicate_Legal : Boolean := True;
      Elaboration_Legal : Boolean := True;
      Runtime_Check_Required : Boolean := False;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Event    : Event_Id := No_Event;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Event_Kind := Event_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Context_Blockers : Natural := 0;
      Exception_Missing_Blockers : Natural := 0;
      Exception_Visibility_Blockers : Natural := 0;
      Exception_Kind_Blockers : Natural := 0;
      Handler_Missing_Blockers : Natural := 0;
      Handler_Duplicate_Blockers : Natural := 0;
      Handler_Unreachable_Blockers : Natural := 0;
      Reraise_Blockers : Natural := 0;
      Propagation_Blockers : Natural := 0;
      Finalization_Missing_Blockers : Natural := 0;
      Finalization_Order_Blockers : Natural := 0;
      Adjust_Finalize_Blockers : Natural := 0;
      Limited_Finalization_Blockers : Natural := 0;
      Abort_Finalization_Blockers : Natural := 0;
      Task_Termination_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Renaming_Blockers : Natural := 0;
      Shared_State_Blockers : Natural := 0;
      Representation_Blockers : Natural := 0;
      Predicate_Blockers : Natural := 0;
      Elaboration_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Effect_Fingerprint_Blockers : Natural := 0;
      Substitution_Fingerprint_Blockers : Natural := 0;
      Runtime_Check_Required : Boolean := False;
      Propagation : Propagation_Mode := Propagation_None;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Event_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Event_Model);
   procedure Add_Event (Model : in out Event_Model; Info : Event_Info);

   function Build (Events : Event_Model) return Result_Model;

   function Event_Count (Model : Event_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Event_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Event_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Event_Model is record
      Items : Event_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Exception_Finalization_Vertical_Slice_Legality;
