with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Exception_Finalization_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   Modulus : constant Natural := 2 ** 30 - 35;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 113) mod Modulus;
   end Mix;

   function Kind_Slot (Kind : Exception_Context_Kind) return Natural is
   begin
      return Exception_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Target_Slot (State : Exception_Target_State) return Natural is
   begin
      return Exception_Target_State'Pos (State) + 1;
   end Target_Slot;

   function Handler_Slot (State : Handler_State) return Natural is
   begin
      return Handler_State'Pos (State) + 1;
   end Handler_Slot;

   function Finalization_Slot (State : Finalization_State) return Natural is
   begin
      return Finalization_State'Pos (State) + 1;
   end Finalization_Slot;

   function No_Return_Slot (State : No_Return_State) return Natural is
   begin
      return No_Return_State'Pos (State) + 1;
   end No_Return_Slot;

   function Status_Slot (Status : Exception_Legality_Status) return Natural is
   begin
      return Exception_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Flow_Error (Status : Flow_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Not_Checked |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Boolean_Condition |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Case_Statement |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Exit |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Goto |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Label |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Exception_Handler |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Raise |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Select |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Accept |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Requeue |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Return_Path;
   end Flow_Error;

   function Accessibility_Error (Status : Accessibility_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Static_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Dynamic_Check_Required |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Null_Exclusion_Checked |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Aliased_Object_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Allocator_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Access_Conversion_Compatible |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Return_Access_Compatible;
   end Accessibility_Error;

   function Contract_Error (Status : Contract_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Precondition |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Postcondition |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Invariant |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Predicate |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Assertion |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Contract_Case |
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Legal_Flow_Aspect;
   end Contract_Error;

   function Elaboration_Error (Status : Elaboration_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Not_Checked |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Dependency |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Elaborate_Pragma |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Elaborate_All_Pragma |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Elaborate_Body_Pragma |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Preelaborate |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Pure |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Body_Before_Use |
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Legal_Generic_Instance;
   end Elaboration_Error;

   function Renaming_Error (Status : Renaming_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Not_Checked |
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Legal_Object_Renaming |
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Legal_Exception_Renaming |
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Legal_Package_Renaming |
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Legal_Subprogram_Renaming |
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Legal_Generic_Renaming |
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Legal_Use_Package |
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Legal_Use_Type |
        Editor.Ada_Renaming_Alias_Visibility_Legality.Renaming_Legality_Legal_Selected_Alias;
   end Renaming_Error;

   function Completion_Error (Status : Completion_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Not_Checked |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Unit_Body |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Subprogram_Body |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Task_Body |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Protected_Body |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Generic_Body |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Private_Type_Completion |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Deferred_Constant_Completion |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Incomplete_Type_Completion |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Body_Stub_Completion |
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Legal_Declaration_Order;
   end Completion_Error;

   function Is_Legal_Status (Status : Exception_Legality_Status) return Boolean is
   begin
      return Status in
        Exception_Legality_Legal_Raise_Statement |
        Exception_Legality_Legal_Raise_Expression |
        Exception_Legality_Legal_Reraise |
        Exception_Legality_Legal_Handler |
        Exception_Legality_Legal_Exception_Renaming |
        Exception_Legality_Legal_Propagation |
        Exception_Legality_Legal_Finalization |
        Exception_Legality_Legal_No_Return;
   end Is_Legal_Status;

   function Is_Raise_Error (Status : Exception_Legality_Status) return Boolean is
   begin
      return Status in
        Exception_Legality_Raise_Target_Unresolved |
        Exception_Legality_Raise_Target_Ambiguous |
        Exception_Legality_Raise_Target_Not_Exception |
        Exception_Legality_Reraise_Outside_Handler |
        Exception_Legality_Raise_Expression_Type_Unresolved |
        Exception_Legality_Raise_Expression_Result_Incompatible;
   end Is_Raise_Error;

   function Is_Handler_Error (Status : Exception_Legality_Status) return Boolean is
   begin
      return Status in
        Exception_Legality_Handler_Choice_Unresolved |
        Exception_Legality_Handler_Choice_Ambiguous |
        Exception_Legality_Handler_Duplicate_Choice |
        Exception_Legality_Handler_Others_Not_Last |
        Exception_Legality_Handler_Unreachable;
   end Is_Handler_Error;

   function Is_Finalization_Error (Status : Exception_Legality_Status) return Boolean is
   begin
      return Status in
        Exception_Legality_Finalization_Primitive_Missing |
        Exception_Legality_Finalization_Profile_Mismatch |
        Exception_Legality_Finalization_Order_Error |
        Exception_Legality_Finalization_Exception_Propagates |
        Exception_Legality_Finalization_Abort_Unsafe |
        Exception_Legality_Finalization_Master_Unresolved;
   end Is_Finalization_Error;

   function Is_No_Return_Error (Status : Exception_Legality_Status) return Boolean is
   begin
      return Status in
        Exception_Legality_No_Return_Returns_Normally |
        Exception_Legality_No_Return_Missing_Raise_Or_Loop |
        Exception_Legality_No_Return_Contract_Conflict;
   end Is_No_Return_Error;

   function Is_View_Barrier (Status : Exception_Legality_Status) return Boolean is
   begin
      return Status in
        Exception_Legality_Private_View_Barrier |
        Exception_Legality_Limited_View_Barrier;
   end Is_View_Barrier;

   function Is_Linked_Error (Status : Exception_Legality_Status) return Boolean is
   begin
      return Status in
        Exception_Legality_Linked_Control_Flow_Error |
        Exception_Legality_Linked_Accessibility_Error |
        Exception_Legality_Linked_Contract_Error |
        Exception_Legality_Linked_Elaboration_Error |
        Exception_Legality_Linked_Renaming_Error |
        Exception_Legality_Linked_Completion_Order_Error;
   end Is_Linked_Error;

   function Decide_Status (C : Exception_Context_Info) return Exception_Legality_Status is
   begin
      if C.Private_View_Barrier or else C.Target_State = Exception_Target_Private_View then
         return Exception_Legality_Private_View_Barrier;
      elsif C.Limited_View_Barrier or else C.Target_State = Exception_Target_Limited_View then
         return Exception_Legality_Limited_View_Barrier;
      elsif Flow_Error (C.Flow_Status) then
         return Exception_Legality_Linked_Control_Flow_Error;
      elsif Accessibility_Error (C.Accessibility_Status) then
         return Exception_Legality_Linked_Accessibility_Error;
      elsif Contract_Error (C.Contract_Status) then
         return Exception_Legality_Linked_Contract_Error;
      elsif Elaboration_Error (C.Elaboration_Status) then
         return Exception_Legality_Linked_Elaboration_Error;
      elsif Renaming_Error (C.Renaming_Status) then
         return Exception_Legality_Linked_Renaming_Error;
      elsif Completion_Error (C.Completion_Status) then
         return Exception_Legality_Linked_Completion_Order_Error;
      end if;

      case C.Kind is
         when Exception_Context_Raise_Statement =>
            if not C.Exception_Target_Resolved or else C.Target_State = Exception_Target_Unresolved then
               return Exception_Legality_Raise_Target_Unresolved;
            elsif C.Exception_Target_Ambiguous or else C.Target_State = Exception_Target_Ambiguous then
               return Exception_Legality_Raise_Target_Ambiguous;
            elsif not C.Target_Is_Exception or else C.Target_State = Exception_Target_Resolved_Non_Exception then
               return Exception_Legality_Raise_Target_Not_Exception;
            else
               return Exception_Legality_Legal_Raise_Statement;
            end if;

         when Exception_Context_Raise_Expression =>
            if not C.Raise_Expression_Type_Resolved then
               return Exception_Legality_Raise_Expression_Type_Unresolved;
            elsif not C.Raise_Expression_Result_Compatible then
               return Exception_Legality_Raise_Expression_Result_Incompatible;
            elsif not C.Exception_Target_Resolved then
               return Exception_Legality_Raise_Target_Unresolved;
            elsif not C.Target_Is_Exception then
               return Exception_Legality_Raise_Target_Not_Exception;
            else
               return Exception_Legality_Legal_Raise_Expression;
            end if;

         when Exception_Context_Reraise =>
            if not C.Reraise_In_Handler then
               return Exception_Legality_Reraise_Outside_Handler;
            else
               return Exception_Legality_Legal_Reraise;
            end if;

         when Exception_Context_Handler | Exception_Context_Exception_Choice =>
            if not C.Handler_Choice_Resolved or else C.Handler = Handler_Choice_Unresolved then
               return Exception_Legality_Handler_Choice_Unresolved;
            elsif C.Handler_Choice_Ambiguous or else C.Handler = Handler_Choice_Ambiguous then
               return Exception_Legality_Handler_Choice_Ambiguous;
            elsif C.Handler_Choice_Duplicate or else C.Handler = Handler_Duplicate_Choice then
               return Exception_Legality_Handler_Duplicate_Choice;
            elsif not C.Handler_Others_Last or else C.Handler = Handler_Others_Not_Last then
               return Exception_Legality_Handler_Others_Not_Last;
            elsif not C.Handler_Is_Reachable or else C.Handler = Handler_Unreachable then
               return Exception_Legality_Handler_Unreachable;
            else
               return Exception_Legality_Legal_Handler;
            end if;

         when Exception_Context_Exception_Renaming =>
            if not C.Exception_Target_Resolved then
               return Exception_Legality_Raise_Target_Unresolved;
            elsif not C.Target_Is_Exception then
               return Exception_Legality_Exception_Rename_Target_Invalid;
            else
               return Exception_Legality_Legal_Exception_Renaming;
            end if;

         when Exception_Context_Propagation =>
            return Exception_Legality_Legal_Propagation;

         when Exception_Context_Controlled_Initialize |
              Exception_Context_Controlled_Adjust |
              Exception_Context_Controlled_Finalize |
              Exception_Context_Master_Finalization |
              Exception_Context_Cleanup_Action |
              Exception_Context_Task_Termination =>
            if not C.Finalization_Primitive_Present
              or else C.Finalization = Finalization_Controlled_Primitive_Missing
            then
               return Exception_Legality_Finalization_Primitive_Missing;
            elsif not C.Finalization_Profile_Compatible
              or else C.Finalization = Finalization_Profile_Mismatch
            then
               return Exception_Legality_Finalization_Profile_Mismatch;
            elsif not C.Finalization_Order_Compatible
              or else C.Finalization = Finalization_Order_Error
            then
               return Exception_Legality_Finalization_Order_Error;
            elsif C.Finalization_Can_Propagate_Exception
              or else C.Finalization = Finalization_Exception_Propagates
            then
               return Exception_Legality_Finalization_Exception_Propagates;
            elsif not C.Finalization_Abort_Safe
              or else C.Finalization = Finalization_Abort_Unsafe
            then
               return Exception_Legality_Finalization_Abort_Unsafe;
            elsif not C.Finalization_Master_Resolved
              or else C.Finalization = Finalization_Master_Unresolved
            then
               return Exception_Legality_Finalization_Master_Unresolved;
            else
               return Exception_Legality_Legal_Finalization;
            end if;

         when Exception_Context_No_Return_Subprogram =>
            if C.No_Return = No_Return_Returns_Normally then
               return Exception_Legality_No_Return_Returns_Normally;
            elsif C.No_Return = No_Return_Missing_Raise_Or_Loop then
               return Exception_Legality_No_Return_Missing_Raise_Or_Loop;
            elsif C.No_Return = No_Return_Contract_Conflict then
               return Exception_Legality_No_Return_Contract_Conflict;
            elsif C.No_Return in No_Return_Declared | No_Return_Raises_Or_Does_Not_Return then
               return Exception_Legality_Legal_No_Return;
            else
               return Exception_Legality_Indeterminate;
            end if;

         when Exception_Context_Unknown =>
            return Exception_Legality_Indeterminate;
      end case;
   end Decide_Status;

   function Message_For (Status : Exception_Legality_Status) return String is
   begin
      case Status is
         when Exception_Legality_Legal_Raise_Statement => return "raise statement is legal";
         when Exception_Legality_Legal_Raise_Expression => return "raise expression is legal";
         when Exception_Legality_Legal_Reraise => return "reraise is legal";
         when Exception_Legality_Legal_Handler => return "exception handler is legal";
         when Exception_Legality_Legal_Exception_Renaming => return "exception renaming is legal";
         when Exception_Legality_Legal_Propagation => return "exception propagation metadata is legal";
         when Exception_Legality_Legal_Finalization => return "finalization/cleanup legality is satisfied";
         when Exception_Legality_Legal_No_Return => return "No_Return contract is satisfied";
         when Exception_Legality_Raise_Target_Unresolved => return "raise target is unresolved";
         when Exception_Legality_Raise_Target_Ambiguous => return "raise target is ambiguous";
         when Exception_Legality_Raise_Target_Not_Exception => return "raise target is not an exception";
         when Exception_Legality_Reraise_Outside_Handler => return "reraise appears outside an exception handler";
         when Exception_Legality_Handler_Choice_Unresolved => return "exception handler choice is unresolved";
         when Exception_Legality_Handler_Choice_Ambiguous => return "exception handler choice is ambiguous";
         when Exception_Legality_Handler_Duplicate_Choice => return "duplicate exception handler choice";
         when Exception_Legality_Handler_Others_Not_Last => return "others exception choice is not last";
         when Exception_Legality_Handler_Unreachable => return "exception handler is unreachable";
         when Exception_Legality_Raise_Expression_Type_Unresolved => return "raise expression result type is unresolved";
         when Exception_Legality_Raise_Expression_Result_Incompatible => return "raise expression result is incompatible with expected type";
         when Exception_Legality_Exception_Rename_Target_Invalid => return "exception renaming target is invalid";
         when Exception_Legality_Finalization_Primitive_Missing => return "controlled finalization primitive is missing";
         when Exception_Legality_Finalization_Profile_Mismatch => return "controlled finalization primitive profile mismatches";
         when Exception_Legality_Finalization_Order_Error => return "finalization order is illegal";
         when Exception_Legality_Finalization_Exception_Propagates => return "finalization may illegally propagate an exception";
         when Exception_Legality_Finalization_Abort_Unsafe => return "finalization cleanup is abort unsafe";
         when Exception_Legality_Finalization_Master_Unresolved => return "finalization master is unresolved";
         when Exception_Legality_No_Return_Returns_Normally => return "No_Return subprogram can return normally";
         when Exception_Legality_No_Return_Missing_Raise_Or_Loop => return "No_Return subprogram lacks a non-returning path";
         when Exception_Legality_No_Return_Contract_Conflict => return "No_Return conflicts with contract metadata";
         when Exception_Legality_Private_View_Barrier => return "private view blocks exception/finalization legality";
         when Exception_Legality_Limited_View_Barrier => return "limited view blocks exception/finalization legality";
         when Exception_Legality_Linked_Control_Flow_Error => return "linked control-flow legality error";
         when Exception_Legality_Linked_Accessibility_Error => return "linked accessibility/lifetime legality error";
         when Exception_Legality_Linked_Contract_Error => return "linked contract/aspect legality error";
         when Exception_Legality_Linked_Elaboration_Error => return "linked elaboration legality error";
         when Exception_Legality_Linked_Renaming_Error => return "linked renaming/visibility legality error";
         when Exception_Legality_Linked_Completion_Order_Error => return "linked unit completion/order legality error";
         when Exception_Legality_Indeterminate => return "exception/finalization legality is indeterminate";
         when Exception_Legality_Not_Checked => return "exception/finalization legality not checked";
      end case;
   end Message_For;

   function Row_Fingerprint (Row : Exception_Legality_Info) return Natural is
      F : Natural := Natural (Row.Id);
   begin
      F := Mix (F, Natural (Row.Context));
      F := Mix (F, Kind_Slot (Row.Kind));
      F := Mix (F, Target_Slot (Row.Target_State));
      F := Mix (F, Handler_Slot (Row.Handler));
      F := Mix (F, Finalization_Slot (Row.Finalization));
      F := Mix (F, No_Return_Slot (Row.No_Return));
      F := Mix (F, Status_Slot (Row.Status));
      F := Mix (F, Natural (Row.Node));
      F := Mix (F, Row.Start_Line);
      F := Mix (F, Row.Start_Column);
      F := Mix (F, Row.End_Line);
      F := Mix (F, Row.End_Column);
      F := Mix (F, Row.Source_Fingerprint);
      return F;
   end Row_Fingerprint;

   function To_Row
     (C      : Exception_Context_Info;
      Id     : Exception_Legality_Id;
      Status : Exception_Legality_Status) return Exception_Legality_Info
   is
      Row : Exception_Legality_Info;
   begin
      Row.Id := Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Target_State := C.Target_State;
      Row.Handler := C.Handler;
      Row.Finalization := C.Finalization;
      Row.No_Return := C.No_Return;
      Row.Node := C.Node;
      Row.Target_Node := C.Target_Node;
      Row.Handler_Node := C.Handler_Node;
      Row.Finalization_Node := C.Finalization_Node;
      Row.Name := C.Name;
      Row.Normalized_Name := C.Normalized_Name;
      Row.Target_Name := C.Target_Name;
      Row.Status := Status;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String (Exception_Context_Kind'Image (C.Kind));
      Row.Flow_Status := C.Flow_Status;
      Row.Accessibility_Status := C.Accessibility_Status;
      Row.Contract_Status := C.Contract_Status;
      Row.Elaboration_Status := C.Elaboration_Status;
      Row.Renaming_Status := C.Renaming_Status;
      Row.Completion_Status := C.Completion_Status;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end To_Row;

   procedure Clear (Model : in out Exception_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Exception_Context_Model;
      Info  : Exception_Context_Info)
   is
      F : Natural := Model.Fingerprint;
   begin
      Model.Contexts.Append (Info);
      F := Mix (F, Natural (Info.Id));
      F := Mix (F, Kind_Slot (Info.Kind));
      F := Mix (F, Target_Slot (Info.Target_State));
      F := Mix (F, Handler_Slot (Info.Handler));
      F := Mix (F, Finalization_Slot (Info.Finalization));
      F := Mix (F, No_Return_Slot (Info.No_Return));
      F := Mix (F, Natural (Info.Node));
      F := Mix (F, Info.Source_Fingerprint);
      Model.Fingerprint := F;
   end Add_Context;

   function Context_Count (Model : Exception_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Exception_Context_Model;
      Index : Positive) return Exception_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Exception_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Exception_Context_Model) return Exception_Legality_Model is
      Model : Exception_Legality_Model;
      Next  : Natural := 1;
   begin
      for C of Contexts.Contexts loop
         declare
            Status : constant Exception_Legality_Status := Decide_Status (C);
            Row    : constant Exception_Legality_Info :=
              To_Row (C, Exception_Legality_Id (Next), Status);
         begin
            Model.Rows.Append (Row);
            Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
            Next := Next + 1;
         end;
      end loop;
      Model.Fingerprint := Mix (Model.Fingerprint, Contexts.Fingerprint);
      return Model;
   end Build;

   function Legality_Count (Model : Exception_Legality_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Legality_Count;

   function Legality_At
     (Model : Exception_Legality_Model;
      Index : Positive) return Exception_Legality_Info is
   begin
      return Model.Rows.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Exception_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Exception_Legality_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Exception_Legality_Model;
      Status : Exception_Legality_Status) return Exception_Result_Set is
      Set : Exception_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Set.Results.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Exception_Legality_Model;
      Kind  : Exception_Context_Kind) return Exception_Result_Set is
      Set : Exception_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Set.Results.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Rows_For_Target_State
     (Model : Exception_Legality_Model;
      State : Exception_Target_State) return Exception_Result_Set is
      Set : Exception_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Target_State = State then
            Set.Results.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Target_State;

   function Rows_For_Handler
     (Model : Exception_Legality_Model;
      State : Handler_State) return Exception_Result_Set is
      Set : Exception_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Handler = State then
            Set.Results.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Handler;

   function Rows_For_Finalization
     (Model : Exception_Legality_Model;
      State : Finalization_State) return Exception_Result_Set is
      Set : Exception_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Finalization = State then
            Set.Results.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Finalization;

   function Rows_For_No_Return
     (Model : Exception_Legality_Model;
      State : No_Return_State) return Exception_Result_Set is
      Set : Exception_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.No_Return = State then
            Set.Results.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_No_Return;

   function Rows_For_Name
     (Model : Exception_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Exception_Result_Set is
      Set : Exception_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Normalized_Name = Name or else Row.Name = Name then
            Set.Results.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Name;

   function Result_Count (Set : Exception_Result_Set) return Natural is
   begin
      return Natural (Set.Results.Length);
   end Result_Count;

   function Result_At
     (Set   : Exception_Result_Set;
      Index : Positive) return Exception_Legality_Info is
   begin
      return Set.Results.Element (Index);
   end Result_At;

   function Legal_Count (Model : Exception_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal_Status (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Exception_Legality_Model) return Natural is
   begin
      return Legality_Count (Model) - Legal_Count (Model) - Indeterminate_Count (Model);
   end Error_Count;

   function Raise_Error_Count (Model : Exception_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Raise_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Raise_Error_Count;

   function Handler_Error_Count (Model : Exception_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Handler_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Handler_Error_Count;

   function Finalization_Error_Count (Model : Exception_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Finalization_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Finalization_Error_Count;

   function No_Return_Error_Count (Model : Exception_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_No_Return_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end No_Return_Error_Count;

   function View_Barrier_Count (Model : Exception_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_View_Barrier (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end View_Barrier_Count;

   function Linked_Error_Count (Model : Exception_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Linked_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Exception_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Exception_Legality_Indeterminate then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Indeterminate_Count;

   function Count_Status
     (Model  : Exception_Legality_Model;
      Status : Exception_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Exception_Legality_Model;
      Kind  : Exception_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Count_Target_State
     (Model : Exception_Legality_Model;
      State : Exception_Target_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Target_State = State then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Target_State;

   function Count_Handler
     (Model : Exception_Legality_Model;
      State : Handler_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Handler = State then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Handler;

   function Count_Finalization
     (Model : Exception_Legality_Model;
      State : Finalization_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Finalization = State then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Finalization;

   function Count_No_Return
     (Model : Exception_Legality_Model;
      State : No_Return_State) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.No_Return = State then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_No_Return;

   function Fingerprint (Model : Exception_Legality_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Exception_Finalization_Legality;
