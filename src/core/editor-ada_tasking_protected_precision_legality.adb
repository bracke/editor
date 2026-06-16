with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Protected_Precision_Legality is

   pragma Suppress (Overflow_Check);
   use type Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Status;
   use type Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Seed, Value : Natural) return Natural is
      Hash : constant Long_Long_Integer :=
        (Long_Long_Integer (Seed) * 131 +
         Long_Long_Integer (Value) * 17 + 97) mod 2_147_483_647;
   begin
      return Natural (Hash);
   end Mix;

   function Node_Slot (Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural is
   begin
      return Natural (Node);
   exception
      when Constraint_Error => return 0;
   end Node_Slot;

   function Status_Slot (Status : Tasking_Precision_Status) return Natural is
   begin
      return Tasking_Precision_Status'Pos (Status) + 1;
   end Status_Slot;

   function Kind_Slot (Kind : Tasking_Precision_Context_Kind) return Natural is
   begin
      return Tasking_Precision_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Base_Kind_Slot (Kind : Tasking_Context_Kind) return Natural is
   begin
      return Editor.Ada_Tasking_Protected_Legality.Tasking_Context_Kind'Pos (Kind) + 1;
   end Base_Kind_Slot;

   function Is_Legal_Status (Status : Tasking_Precision_Status) return Boolean is
   begin
      return Status in
        Tasking_Precision_Legal_Task_Activation |
        Tasking_Precision_Legal_Task_Body |
        Tasking_Precision_Legal_Protected_Function |
        Tasking_Precision_Legal_Protected_Procedure |
        Tasking_Precision_Legal_Protected_Entry |
        Tasking_Precision_Legal_Entry_Barrier |
        Tasking_Precision_Legal_Entry_Family_Index |
        Tasking_Precision_Legal_Accept |
        Tasking_Precision_Legal_Requeue |
        Tasking_Precision_Legal_Select_Alternative |
        Tasking_Precision_Legal_Queued_Entry_Call;
   end Is_Legal_Status;

   function Activation_Error (Status : Tasking_Precision_Status) return Boolean is
   begin
      return Status in
        Tasking_Precision_Activation_Elaboration_Error |
        Tasking_Precision_Task_Body_Not_Elaborated |
        Tasking_Precision_Linked_Elaboration_Error;
   end Activation_Error;

   function Protected_Operation_Error (Status : Tasking_Precision_Status) return Boolean is
   begin
      return Status in
        Tasking_Precision_Protected_Function_Writes_State |
        Tasking_Precision_Protected_Function_Calls_Entry |
        Tasking_Precision_Protected_Function_Dataflow_Write |
        Tasking_Precision_Protected_Procedure_Barrier |
        Tasking_Precision_Protected_Procedure_Global_Mismatch;
   end Protected_Operation_Error;

   function Barrier_Error (Status : Tasking_Precision_Status) return Boolean is
   begin
      return Status in
        Tasking_Precision_Protected_Entry_Barrier_Missing |
        Tasking_Precision_Protected_Entry_Barrier_Not_Boolean |
        Tasking_Precision_Entry_Barrier_Read_Before_Write |
        Tasking_Precision_Entry_Barrier_Global_Mismatch |
        Tasking_Precision_Entry_Family_Index_Non_Static |
        Tasking_Precision_Entry_Family_Index_Type_Mismatch;
   end Barrier_Error;

   function Accept_Requeue_Error (Status : Tasking_Precision_Status) return Boolean is
   begin
      return Status in
        Tasking_Precision_Accept_Outside_Task_Body |
        Tasking_Precision_Accept_Profile_Mismatch |
        Tasking_Precision_Requeue_Target_Unresolved |
        Tasking_Precision_Requeue_To_Non_Entry |
        Tasking_Precision_Requeue_With_Abort_Not_Allowed;
   end Accept_Requeue_Error;

   function Select_Error (Status : Tasking_Precision_Status) return Boolean is
   begin
      return Status in
        Tasking_Precision_Select_Alternative_Not_Open |
        Tasking_Precision_Select_Terminate_With_Delay;
   end Select_Error;

   function State_Error (Status : Tasking_Precision_Status) return Boolean is
   begin
      return Status in
        Tasking_Precision_Protected_State_Uninitialized |
        Tasking_Precision_Protected_State_Use_After_Finalization |
        Tasking_Precision_Queued_Call_Accessibility_Risk;
   end State_Error;

   function Linked_Error (Status : Tasking_Precision_Status) return Boolean is
   begin
      return Status in
        Tasking_Precision_Linked_Tasking_Error |
        Tasking_Precision_Linked_Dataflow_Error |
        Tasking_Precision_Linked_Elaboration_Error |
        Tasking_Precision_Linked_Accessibility_Error;
   end Linked_Error;

   function Base_Tasking_Error (Status : Tasking_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Not_Checked |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Task_Type |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Task_Body |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Protected_Type |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Protected_Body |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Entry_Declaration |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Entry_Body |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Entry_Family |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Accept |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Requeue |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Protected_Function |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Protected_Procedure |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Protected_Entry |
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Legal_Select;
   end Base_Tasking_Error;

   function Dataflow_Error (Status : Dataflow_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Not_Checked |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Read |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Write |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Read_Write |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Null_Effect |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Depends_Edge |
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Legal_Refinement;
   end Dataflow_Error;

   function Elaboration_Error (Status : Elaboration_Precision_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Not_Checked |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Dependency_Order |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Call_Order |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Access_Order |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Generic_Instance_Order |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Body_Before_Use |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Preelaborated_Unit |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Pure_Unit |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Remote_Types_Unit |
        Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Legal_Shared_Passive_Unit;
   end Elaboration_Error;

   function Accessibility_Error (Status : Accessibility_Precision_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Not_Checked |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Static_Level |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Dynamic_Check |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Allocator_Master |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Return_Level |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Access_Discriminant |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Generic_Substitution |
        Editor.Ada_Accessibility_Precision_Legality.Accessibility_Precision_Legal_Aggregate_Discriminant;
   end Accessibility_Error;

   function Classify (Info : Tasking_Precision_Context_Info) return Tasking_Precision_Status is
   begin
      if Base_Tasking_Error (Info.Base_Tasking_Status) then
         return Tasking_Precision_Linked_Tasking_Error;
      elsif Info.Dataflow_Status = Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Read_Before_Write then
         if Info.Kind = Tasking_Precision_Context_Entry_Barrier then
            return Tasking_Precision_Entry_Barrier_Read_Before_Write;
         else
            return Tasking_Precision_Protected_State_Uninitialized;
         end if;
      elsif Info.Dataflow_Status = Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Use_After_Finalization then
         return Tasking_Precision_Protected_State_Use_After_Finalization;
      elsif Info.Dataflow_Status = Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Write_Not_In_Global
        or else Info.Dataflow_Status = Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Write_To_In_Global
        or else Info.Dataflow_Status = Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Mode_Mismatch
      then
         if Info.Kind = Tasking_Precision_Context_Protected_Function then
            return Tasking_Precision_Protected_Function_Dataflow_Write;
         elsif Info.Kind = Tasking_Precision_Context_Entry_Barrier then
            return Tasking_Precision_Entry_Barrier_Global_Mismatch;
         else
            return Tasking_Precision_Linked_Dataflow_Error;
         end if;
      elsif Dataflow_Error (Info.Dataflow_Status) then
         return Tasking_Precision_Linked_Dataflow_Error;
      elsif Info.Elaboration_Status = Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Body_Elaborated_After_Call
        or else Info.Elaboration_Status = Editor.Ada_Elaboration_Precision_Legality.Elaboration_Precision_Linked_Elaboration_Error
      then
         return Tasking_Precision_Activation_Elaboration_Error;
      elsif Elaboration_Error (Info.Elaboration_Status) then
         return Tasking_Precision_Linked_Elaboration_Error;
      elsif Accessibility_Error (Info.Accessibility_Status) then
         if Info.Kind = Tasking_Precision_Context_Queued_Entry_Call then
            return Tasking_Precision_Queued_Call_Accessibility_Risk;
         else
            return Tasking_Precision_Linked_Accessibility_Error;
         end if;
      elsif not Info.Task_Activated then
         return Tasking_Precision_Activation_Elaboration_Error;
      elsif not Info.Task_Body_Elaborated then
         return Tasking_Precision_Task_Body_Not_Elaborated;
      elsif Info.Protected_Function_Writes_State then
         return Tasking_Precision_Protected_Function_Writes_State;
      elsif Info.Protected_Function_Calls_Entry then
         return Tasking_Precision_Protected_Function_Calls_Entry;
      elsif Info.Protected_Procedure_Has_Barrier then
         return Tasking_Precision_Protected_Procedure_Barrier;
      elsif Info.Protected_Procedure_Global_Mismatch then
         return Tasking_Precision_Protected_Procedure_Global_Mismatch;
      elsif not Info.Barrier_Present then
         return Tasking_Precision_Protected_Entry_Barrier_Missing;
      elsif not Info.Barrier_Is_Boolean then
         return Tasking_Precision_Protected_Entry_Barrier_Not_Boolean;
      elsif Info.Barrier_Global_Mismatch then
         return Tasking_Precision_Entry_Barrier_Global_Mismatch;
      elsif not Info.Entry_Family_Index_Static then
         return Tasking_Precision_Entry_Family_Index_Non_Static;
      elsif not Info.Entry_Family_Index_Compatible then
         return Tasking_Precision_Entry_Family_Index_Type_Mismatch;
      elsif not Info.Accept_In_Task_Body then
         return Tasking_Precision_Accept_Outside_Task_Body;
      elsif not Info.Accept_Profile_Matches then
         return Tasking_Precision_Accept_Profile_Mismatch;
      elsif not Info.Requeue_Target_Resolved then
         return Tasking_Precision_Requeue_Target_Unresolved;
      elsif not Info.Requeue_Target_Is_Entry then
         return Tasking_Precision_Requeue_To_Non_Entry;
      elsif not Info.Requeue_With_Abort_Allowed then
         return Tasking_Precision_Requeue_With_Abort_Not_Allowed;
      elsif not Info.Select_Alternative_Open then
         return Tasking_Precision_Select_Alternative_Not_Open;
      elsif Info.Select_Terminate_With_Delay then
         return Tasking_Precision_Select_Terminate_With_Delay;
      elsif Info.Queued_Call_Accessibility_Check then
         return Tasking_Precision_Legal_Queued_Entry_Call;
      elsif not Info.Protected_State_Initialized then
         return Tasking_Precision_Protected_State_Uninitialized;
      elsif Info.Protected_State_Finalized then
         return Tasking_Precision_Protected_State_Use_After_Finalization;
      end if;

      case Info.Kind is
         when Tasking_Precision_Context_Task_Activation =>
            return Tasking_Precision_Legal_Task_Activation;
         when Tasking_Precision_Context_Task_Body =>
            return Tasking_Precision_Legal_Task_Body;
         when Tasking_Precision_Context_Protected_Function =>
            return Tasking_Precision_Legal_Protected_Function;
         when Tasking_Precision_Context_Protected_Procedure =>
            return Tasking_Precision_Legal_Protected_Procedure;
         when Tasking_Precision_Context_Protected_Entry =>
            return Tasking_Precision_Legal_Protected_Entry;
         when Tasking_Precision_Context_Entry_Barrier =>
            return Tasking_Precision_Legal_Entry_Barrier;
         when Tasking_Precision_Context_Entry_Family_Index =>
            return Tasking_Precision_Legal_Entry_Family_Index;
         when Tasking_Precision_Context_Accept_Statement =>
            return Tasking_Precision_Legal_Accept;
         when Tasking_Precision_Context_Requeue_Statement =>
            return Tasking_Precision_Legal_Requeue;
         when Tasking_Precision_Context_Select_Alternative =>
            return Tasking_Precision_Legal_Select_Alternative;
         when Tasking_Precision_Context_Queued_Entry_Call =>
            return Tasking_Precision_Legal_Queued_Entry_Call;
         when Tasking_Precision_Context_Protected_Object_State =>
            return Tasking_Precision_Legal_Protected_Entry;
         when Tasking_Precision_Context_Unknown =>
            return Tasking_Precision_Indeterminate;
      end case;
   end Classify;

   function Message_For (Status : Tasking_Precision_Status) return String is
   begin
      case Status is
         when Tasking_Precision_Not_Checked => return "tasking precision legality not checked";
         when Tasking_Precision_Legal_Task_Activation => return "task activation is elaboration-safe";
         when Tasking_Precision_Legal_Task_Body => return "task body is elaboration-safe";
         when Tasking_Precision_Legal_Protected_Function => return "protected function obeys protected-state restrictions";
         when Tasking_Precision_Legal_Protected_Procedure => return "protected procedure obeys protected-operation restrictions";
         when Tasking_Precision_Legal_Protected_Entry => return "protected entry is legal";
         when Tasking_Precision_Legal_Entry_Barrier => return "entry barrier is legal";
         when Tasking_Precision_Legal_Entry_Family_Index => return "entry family index is legal";
         when Tasking_Precision_Legal_Accept => return "accept statement is legal";
         when Tasking_Precision_Legal_Requeue => return "requeue statement is legal";
         when Tasking_Precision_Legal_Select_Alternative => return "select alternative is legal";
         when Tasking_Precision_Legal_Queued_Entry_Call => return "queued entry call accessibility is legal";
         when Tasking_Precision_Activation_Elaboration_Error => return "task activation violates elaboration ordering";
         when Tasking_Precision_Task_Body_Not_Elaborated => return "task body is not elaborated before activation/use";
         when Tasking_Precision_Protected_Function_Writes_State => return "protected function writes protected state";
         when Tasking_Precision_Protected_Function_Calls_Entry => return "protected function calls an entry";
         when Tasking_Precision_Protected_Function_Dataflow_Write => return "protected function has an illegal Global/Depends write effect";
         when Tasking_Precision_Protected_Procedure_Barrier => return "protected procedure illegally has a barrier";
         when Tasking_Precision_Protected_Procedure_Global_Mismatch => return "protected procedure Global/Depends effects do not match protected state use";
         when Tasking_Precision_Protected_Entry_Barrier_Missing => return "protected entry is missing its barrier";
         when Tasking_Precision_Protected_Entry_Barrier_Not_Boolean => return "protected entry barrier is not Boolean";
         when Tasking_Precision_Entry_Barrier_Read_Before_Write => return "entry barrier reads protected state before initialization";
         when Tasking_Precision_Entry_Barrier_Global_Mismatch => return "entry barrier Global/Depends effects are inconsistent";
         when Tasking_Precision_Entry_Family_Index_Non_Static => return "entry family index is not static";
         when Tasking_Precision_Entry_Family_Index_Type_Mismatch => return "entry family index type is incompatible";
         when Tasking_Precision_Accept_Outside_Task_Body => return "accept statement is outside the matching task body";
         when Tasking_Precision_Accept_Profile_Mismatch => return "accept statement profile does not match entry profile";
         when Tasking_Precision_Requeue_Target_Unresolved => return "requeue target is unresolved";
         when Tasking_Precision_Requeue_To_Non_Entry => return "requeue target is not an entry";
         when Tasking_Precision_Requeue_With_Abort_Not_Allowed => return "requeue with abort is not allowed here";
         when Tasking_Precision_Select_Alternative_Not_Open => return "select alternative cannot be open";
         when Tasking_Precision_Select_Terminate_With_Delay => return "select terminate alternative conflicts with delay alternative";
         when Tasking_Precision_Queued_Call_Accessibility_Risk => return "queued entry call carries an accessibility/lifetime risk";
         when Tasking_Precision_Protected_State_Uninitialized => return "protected state may be read before initialization";
         when Tasking_Precision_Protected_State_Use_After_Finalization => return "protected state may be used after finalization";
         when Tasking_Precision_Linked_Tasking_Error => return "base tasking/protected legality failed";
         when Tasking_Precision_Linked_Dataflow_Error => return "linked Global/Depends dataflow legality failed";
         when Tasking_Precision_Linked_Elaboration_Error => return "linked elaboration precision legality failed";
         when Tasking_Precision_Linked_Accessibility_Error => return "linked accessibility precision legality failed";
         when Tasking_Precision_Indeterminate => return "tasking/protected precision legality is indeterminate";
      end case;
   end Message_For;

   function Fingerprint_Info (Info : Tasking_Precision_Legality_Info) return Natural is
      Result : Natural := 29;
   begin
      Result := Mix (Result, Natural (Info.Id));
      Result := Mix (Result, Natural (Info.Context));
      Result := Mix (Result, Status_Slot (Info.Status));
      Result := Mix (Result, Kind_Slot (Info.Kind));
      Result := Mix (Result, Base_Kind_Slot (Info.Base_Kind));
      Result := Mix (Result, Node_Slot (Info.Node));
      Result := Mix (Result, Node_Slot (Info.Entry_Node));
      Result := Mix (Result, Length (Info.Object_Name));
      Result := Mix (Result, Length (Info.Entry_Name));
      Result := Mix (Result, Info.Source_Fingerprint);
      return Result;
   end Fingerprint_Info;

   procedure Clear (Model : in out Tasking_Precision_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Tasking_Precision_Context_Model;
      Info  : Tasking_Precision_Context_Info)
   is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Kind_Slot (Info.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Node_Slot (Info.Node));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Tasking_Precision_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Tasking_Precision_Context_Model;
      Index : Positive) return Tasking_Precision_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Tasking_Precision_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   procedure Accumulate
     (Model : in out Tasking_Precision_Legality_Model;
      Info  : Tasking_Precision_Legality_Info) is
   begin
      if Is_Legal_Status (Info.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;

      if Activation_Error (Info.Status) then
         Model.Activation_Error_Total := Model.Activation_Error_Total + 1;
      end if;
      if Protected_Operation_Error (Info.Status) then
         Model.Protected_Operation_Error_Total := Model.Protected_Operation_Error_Total + 1;
      end if;
      if Barrier_Error (Info.Status) then
         Model.Barrier_Error_Total := Model.Barrier_Error_Total + 1;
      end if;
      if Accept_Requeue_Error (Info.Status) then
         Model.Accept_Requeue_Error_Total := Model.Accept_Requeue_Error_Total + 1;
      end if;
      if Select_Error (Info.Status) then
         Model.Select_Error_Total := Model.Select_Error_Total + 1;
      end if;
      if State_Error (Info.Status) then
         Model.State_Error_Total := Model.State_Error_Total + 1;
      end if;
      if Linked_Error (Info.Status) then
         Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
      end if;
      if Info.Status = Tasking_Precision_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Accumulate;

   function Build
     (Contexts : Tasking_Precision_Context_Model) return Tasking_Precision_Legality_Model
   is
      Model : Tasking_Precision_Legality_Model;
      Next_Id : Tasking_Precision_Legality_Id := 1;
   begin
      for C of Contexts.Contexts loop
         declare
            Status : constant Tasking_Precision_Status := Classify (C);
            Row : Tasking_Precision_Legality_Info;
         begin
            Row.Id := Next_Id;
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Base_Kind := C.Base_Kind;
            Row.Node := C.Node;
            Row.Task_Node := C.Task_Node;
            Row.Protected_Node := C.Protected_Node;
            Row.Entry_Node := C.Entry_Node;
            Row.Barrier_Node := C.Barrier_Node;
            Row.Status := Status;
            Row.Object_Name := C.Object_Name;
            Row.Entry_Name := C.Entry_Name;
            Row.Message := To_Unbounded_String (Message_For (Status));
            Row.Detail := To_Unbounded_String
              ("tasking/protected precision context=" & Tasking_Precision_Context_Kind'Image (C.Kind));
            Row.Base_Tasking_Status := C.Base_Tasking_Status;
            Row.Dataflow_Status := C.Dataflow_Status;
            Row.Elaboration_Status := C.Elaboration_Status;
            Row.Accessibility_Status := C.Accessibility_Status;
            Row.Start_Line := C.Start_Line;
            Row.Start_Column := C.Start_Column;
            Row.End_Line := C.End_Line;
            Row.End_Column := C.End_Column;
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Row.Fingerprint := Fingerprint_Info (Row);
            Model.Items.Append (Row);
            Accumulate (Model, Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Tasking_Precision_Legality_Model;
      Index : Positive) return Tasking_Precision_Legality_Info is
   begin
      return Model.Items.Element (Index);
   end Legality_At;

   function Empty_Info return Tasking_Precision_Legality_Info is
   begin
      return (others => <>);
   end Empty_Info;

   function First_For_Node
     (Model : Tasking_Precision_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Precision_Legality_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return Empty_Info;
   end First_For_Node;

   function Rows_For_Status
     (Model  : Tasking_Precision_Legality_Model;
      Status : Tasking_Precision_Status) return Tasking_Precision_Result_Set
   is
      Results : Tasking_Precision_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Tasking_Precision_Legality_Model;
      Kind  : Tasking_Precision_Context_Kind) return Tasking_Precision_Result_Set
   is
      Results : Tasking_Precision_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Object
     (Model : Tasking_Precision_Legality_Model;
      Name  : String) return Tasking_Precision_Result_Set
   is
      Results : Tasking_Precision_Result_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Object_Name) = Name then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Object;

   function Rows_For_Entry
     (Model : Tasking_Precision_Legality_Model;
      Name  : String) return Tasking_Precision_Result_Set
   is
      Results : Tasking_Precision_Result_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Entry_Name) = Name then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Entry;

   function Result_Count (Results : Tasking_Precision_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Tasking_Precision_Result_Set;
      Index   : Positive) return Tasking_Precision_Legality_Info is
   begin
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Tasking_Precision_Legality_Model;
      Status : Tasking_Precision_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Tasking_Precision_Legality_Model;
      Kind  : Tasking_Precision_Context_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Activation_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.Activation_Error_Total;
   end Activation_Error_Count;

   function Protected_Operation_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.Protected_Operation_Error_Total;
   end Protected_Operation_Error_Count;

   function Barrier_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.Barrier_Error_Total;
   end Barrier_Error_Count;

   function Accept_Requeue_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.Accept_Requeue_Error_Total;
   end Accept_Requeue_Error_Count;

   function Select_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.Select_Error_Total;
   end Select_Error_Count;

   function State_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.State_Error_Total;
   end State_Error_Count;

   function Linked_Error_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Tasking_Precision_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Tasking_Precision_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Tasking_Precision_Legality;
   end Has_Legality;

end Editor.Ada_Tasking_Protected_Precision_Legality;
