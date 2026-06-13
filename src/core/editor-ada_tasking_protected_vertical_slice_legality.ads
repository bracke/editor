with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Tasking_Protected_Vertical_Slice_Legality is

   --  Pass1302 vertical-slice tasking/protected legality.  This package
   --  performs concrete RM-facing tasking checks over source-shaped task,
   --  protected-object, entry, requeue, select, abort, finalization, and
   --  shared-state evidence.  It is deliberately a semantic slice rather
   --  than another diagnostic/provenance/recheck wrapper.

   type Entity_Id is new Natural;
   No_Entity : constant Entity_Id := 0;

   type Operation_Id is new Natural;
   No_Operation : constant Operation_Id := 0;

   type Event_Id is new Natural;
   No_Event : constant Event_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Entity_Kind is
     (Entity_Task_Type,
      Entity_Task_Object,
      Entity_Protected_Type,
      Entity_Protected_Object,
      Entity_Entry_Family,
      Entity_Shared_Object,
      Entity_Abstract_State,
      Entity_Unknown);

   type Operation_Kind is
     (Operation_Protected_Procedure,
      Operation_Protected_Function,
      Operation_Protected_Entry,
      Operation_Task_Entry,
      Operation_Accept_Body,
      Operation_Requeue_Target,
      Operation_Select_Alternative,
      Operation_Callback,
      Operation_Finalizer,
      Operation_Unknown);

   type Access_Mode is
     (Access_None,
      Access_Read,
      Access_Write,
      Access_Read_Write);

   type Event_Kind is
     (Event_Protected_Action,
      Event_Indirect_Protected_Call,
      Event_Callback_Protected_Call,
      Event_Entry_Family_Call,
      Event_Requeue,
      Event_Selective_Accept,
      Event_Accept_Body,
      Event_Terminate_Alternative,
      Event_Task_Activation,
      Event_Task_Termination,
      Event_Abort,
      Event_Abortable_Select,
      Event_Finalization,
      Event_Shared_State_Access,
      Event_Unknown);

   type Tasking_Status is
     (Tasking_Not_Checked,
      Tasking_Legal_Protected_Action,
      Tasking_Legal_Queued_Entry,
      Tasking_Legal_Requeue_Or_Select,
      Tasking_Legal_Termination_Or_Finalization,
      Tasking_Legal_Shared_State_Access,
      Tasking_Missing_Entity,
      Tasking_Missing_Operation,
      Tasking_Protected_Reentrancy,
      Tasking_Callback_Reentrancy,
      Tasking_Barrier_Side_Effect,
      Tasking_Entry_Family_Index_Error,
      Tasking_Entry_Queue_Discipline_Error,
      Tasking_Requeue_Target_Error,
      Tasking_Select_Path_Error,
      Tasking_Accept_Body_Effect_Error,
      Tasking_Terminate_Dependency_Error,
      Tasking_Abort_Deferred_Finalization_Error,
      Tasking_Abortable_Select_Finalization_Error,
      Tasking_Unprotected_Shared_Access,
      Tasking_Mode_Mismatch,
      Tasking_Abstract_State_Blocker,
      Tasking_Source_Fingerprint_Mismatch,
      Tasking_Effect_Fingerprint_Mismatch,
      Tasking_Multiple_Blockers,
      Tasking_Indeterminate);

   type Entity_Info is record
      Id       : Entity_Id := No_Entity;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Entity_Kind := Entity_Unknown;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Is_Protected : Boolean := False;
      Is_Task : Boolean := False;
      Is_Abstract_State : Boolean := False;
      Is_Volatile : Boolean := False;
      Is_Atomic : Boolean := False;
      Has_Independent_Components : Boolean := False;
      Requires_Protected_Access : Boolean := False;
      Allows_Reentrant_Read : Boolean := False;
      Allows_Requeue : Boolean := False;
      Has_Terminate_Alternative : Boolean := False;
      Has_Finalization : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
   end record;

   type Operation_Info is record
      Id       : Operation_Id := No_Operation;
      Owner    : Entity_Id := No_Entity;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Operation_Kind := Operation_Unknown;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Access_Mode_Value : Access_Mode := Access_None;
      Is_Barrier : Boolean := False;
      Barrier_Has_Side_Effects : Boolean := False;
      May_Call_Back_Into_Owner : Boolean := False;
      May_Indirectly_Call_Owner : Boolean := False;
      Entry_Family_Index_Static : Boolean := True;
      Entry_Family_Index_In_Range : Boolean := True;
      Queue_Policy_Known : Boolean := True;
      Requeue_Target_Compatible : Boolean := True;
      Select_Path_Covered : Boolean := True;
      Accept_Body_Effects_Known : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
   end record;

   type Event_Info is record
      Id       : Event_Id := No_Event;
      Entity   : Entity_Id := No_Entity;
      Operation : Operation_Id := No_Operation;
      Target_Entity : Entity_Id := No_Entity;
      Target_Operation : Operation_Id := No_Operation;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Event_Kind := Event_Unknown;
      Access_Mode_Value : Access_Mode := Access_None;
      Inside_Protected_Action : Boolean := False;
      Through_Callback : Boolean := False;
      Through_Indirect_Call : Boolean := False;
      Uses_Entry_Family : Boolean := False;
      Has_Requeue_Target : Boolean := False;
      Has_Select_Else_Or_Terminate_Path : Boolean := True;
      Abort_Deferred_Finalization_Safe : Boolean := True;
      Abortable_Select_Finalization_Safe : Boolean := True;
      Shared_Access_Is_Protected : Boolean := True;
      Abstract_State_Evidence_Present : Boolean := True;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Event_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Event    : Event_Id := No_Event;
      Entity   : Entity_Id := No_Entity;
      Operation : Operation_Id := No_Operation;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : Tasking_Status := Tasking_Not_Checked;
      Missing_Entity_Blockers : Natural := 0;
      Missing_Operation_Blockers : Natural := 0;
      Reentrancy_Blockers : Natural := 0;
      Callback_Reentrancy_Blockers : Natural := 0;
      Barrier_Blockers : Natural := 0;
      Entry_Family_Blockers : Natural := 0;
      Queue_Blockers : Natural := 0;
      Requeue_Blockers : Natural := 0;
      Select_Path_Blockers : Natural := 0;
      Accept_Body_Blockers : Natural := 0;
      Terminate_Blockers : Natural := 0;
      Abort_Finalization_Blockers : Natural := 0;
      Abortable_Finalization_Blockers : Natural := 0;
      Shared_Access_Blockers : Natural := 0;
      Mode_Blockers : Natural := 0;
      Abstract_State_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Effect_Fingerprint_Blockers : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Entity_Model is private;
   type Operation_Model is private;
   type Event_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Entity_Model);
   procedure Clear (Model : in out Operation_Model);
   procedure Clear (Model : in out Event_Model);

   procedure Add_Entity (Model : in out Entity_Model; Info : Entity_Info);
   procedure Add_Operation (Model : in out Operation_Model; Info : Operation_Info);
   procedure Add_Event (Model : in out Event_Model; Info : Event_Info);

   function Build
     (Entities   : Entity_Model;
      Operations : Operation_Model;
      Events     : Event_Model) return Result_Model;

   function Entity_Count (Model : Entity_Model) return Natural;
   function Operation_Count (Model : Operation_Model) return Natural;
   function Event_Count (Model : Event_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Tasking_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Entity_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Entity_Info);
   package Operation_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Operation_Info);
   package Event_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Event_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Entity_Model is record
      Items : Entity_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Operation_Model is record
      Items : Operation_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Event_Model is record
      Items : Event_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Tasking_Protected_Vertical_Slice_Legality;
