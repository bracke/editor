with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Definite_Initialization_Flow_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 131 + B * 17 + 97) mod 2_147_483_647;
   end Mix;

   function Is_Legal (Status : Initialization_Legality_Status) return Boolean is
   begin
      return Status in
        Initialization_Legality_Definitely_Initialized |
        Initialization_Legality_Default_Initialized |
        Initialization_Legality_Explicitly_Initialized |
        Initialization_Legality_Component_Initialized |
        Initialization_Legality_Out_Parameter_Assigned |
        Initialization_Legality_Return_Object_Initialized |
        Initialization_Legality_Exception_Path_Preserved |
        Initialization_Legality_Finalization_Path_Preserved;
   end Is_Legal;

   function Is_Linked_Error (Status : Initialization_Legality_Status) return Boolean is
   begin
      return Status in
        Initialization_Legality_Linked_Assignment_Error |
        Initialization_Legality_Linked_Return_Error |
        Initialization_Legality_Linked_Control_Flow_Error |
        Initialization_Legality_Linked_Exception_Finalization_Error |
        Initialization_Legality_Linked_Closure_Error;
   end Is_Linked_Error;

   function Assignment_Error (Status : Assignment_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Compatible |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Class_Wide_Compatible |
        Editor.Ada_Assignment_Legality.Assignment_Legality_Static_Range_Compatible;
   end Assignment_Error;

   function Return_Error (Status : Return_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked |
        Editor.Ada_Return_Legality.Return_Legality_Procedure_Return_Compatible |
        Editor.Ada_Return_Legality.Return_Legality_Function_Return_Compatible |
        Editor.Ada_Return_Legality.Return_Legality_Extended_Return_Compatible;
   end Return_Error;

   function Control_Error (Status : Control_Flow_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Not_Checked |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Boolean_Condition |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Case_Statement |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Exit |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Goto |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Exception_Handler |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Raise |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Select |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Accept |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Requeue |
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Return_Path;
   end Control_Error;

   function Exception_Error (Status : Exception_Finalization_Legality_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Not_Checked |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Raise_Statement |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Raise_Expression |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Reraise |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Handler |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Exception_Renaming |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Propagation |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_Finalization |
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Legal_No_Return;
   end Exception_Error;

   function Closure_Error (Status : Integrated_Closure_Status) return Boolean is
   begin
      return Status not in
        Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Not_Checked |
        Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_Local |
        Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_Cross_Unit |
        Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_With_Use_Closure;
   end Closure_Error;

   function Status_For (C : Initialization_Context_Info)
     return Initialization_Legality_Status is
   begin
      if Assignment_Error (C.Assignment_Status) then
         return Initialization_Legality_Linked_Assignment_Error;
      elsif Return_Error (C.Return_Status) then
         return Initialization_Legality_Linked_Return_Error;
      elsif Control_Error (C.Control_Status) then
         return Initialization_Legality_Linked_Control_Flow_Error;
      elsif Exception_Error (C.Exception_Status) then
         return Initialization_Legality_Linked_Exception_Finalization_Error;
      elsif Closure_Error (C.Closure_Status) then
         return Initialization_Legality_Linked_Closure_Error;
      elsif C.Flow = Flow_State_Unreachable then
         return Initialization_Legality_Unreachable_Initialization;
      elsif C.Reads_Object and then C.Before_State = Object_State_Uninitialized then
         return Initialization_Legality_Read_Before_Write;
      elsif C.Component_Node /= Editor.Ada_Syntax_Tree.No_Node
        and then C.Reads_Object
        and then not C.Component_Covered
      then
         return Initialization_Legality_Component_Read_Before_Write;
      elsif not C.Component_Covered then
         return Initialization_Legality_Partial_Component_Initialization;
      elsif C.Must_Assign_Out and then not C.Writes_Object then
         return Initialization_Legality_Out_Parameter_Not_Assigned;
      elsif C.Kind = Initialization_Context_Parameter_In_Out
        and then C.After_State = Object_State_Conditionally_Initialized
      then
         return Initialization_Legality_In_Out_Parameter_Conditionally_Assigned;
      elsif C.Kind in Initialization_Context_Return | Initialization_Context_Extended_Return
        and then C.After_State not in
          Object_State_Definitely_Initialized | Object_State_Conditionally_Initialized
      then
         return Initialization_Legality_Return_Object_Not_Initialized;
      elsif C.Flow = Flow_State_Branch_Merge
        and then C.After_State /= Object_State_Definitely_Initialized
      then
         return Initialization_Legality_Branch_Merge_Not_Definite;
      elsif C.Flow = Flow_State_Loop_Carried
        and then C.After_State /= Object_State_Definitely_Initialized
      then
         return Initialization_Legality_Loop_Merge_Not_Definite;
      elsif C.Flow = Flow_State_Exceptional
        and then C.After_State = Object_State_Invalidated_By_Exception
      then
         return Initialization_Legality_Exception_Path_Loses_Initialization;
      elsif C.Flow = Flow_State_Finalization
        and then C.Before_State = Object_State_Uninitialized
      then
         return Initialization_Legality_Finalization_Uses_Uninitialized_Object;
      elsif C.Before_State = Object_State_Moved_Or_Finalized and then C.Reads_Object then
         return Initialization_Legality_Use_After_Finalization;
      elsif C.Has_Default_Init then
         return Initialization_Legality_Default_Initialized;
      elsif C.Has_Explicit_Init then
         return Initialization_Legality_Explicitly_Initialized;
      elsif C.Kind = Initialization_Context_Component then
         return Initialization_Legality_Component_Initialized;
      elsif C.Kind = Initialization_Context_Parameter_Out and then C.Writes_Object then
         return Initialization_Legality_Out_Parameter_Assigned;
      elsif C.Kind in Initialization_Context_Return | Initialization_Context_Extended_Return then
         return Initialization_Legality_Return_Object_Initialized;
      elsif C.Flow = Flow_State_Exceptional then
         return Initialization_Legality_Exception_Path_Preserved;
      elsif C.Flow = Flow_State_Finalization then
         return Initialization_Legality_Finalization_Path_Preserved;
      elsif C.After_State = Object_State_Definitely_Initialized then
         return Initialization_Legality_Definitely_Initialized;
      else
         return Initialization_Legality_Indeterminate;
      end if;
   end Status_For;

   function Text_For (Status : Initialization_Legality_Status) return String is
   begin
      case Status is
         when Initialization_Legality_Definitely_Initialized => return "object is definitely initialized";
         when Initialization_Legality_Default_Initialized => return "object is default initialized";
         when Initialization_Legality_Explicitly_Initialized => return "object is explicitly initialized";
         when Initialization_Legality_Component_Initialized => return "component is initialized";
         when Initialization_Legality_Out_Parameter_Assigned => return "out parameter is assigned";
         when Initialization_Legality_Return_Object_Initialized => return "return object is initialized";
         when Initialization_Legality_Read_Before_Write => return "object is read before definite initialization";
         when Initialization_Legality_Component_Read_Before_Write => return "component is read before definite initialization";
         when Initialization_Legality_Partial_Component_Initialization => return "component initialization is partial";
         when Initialization_Legality_Out_Parameter_Not_Assigned => return "out parameter is not assigned on all paths";
         when Initialization_Legality_Return_Object_Not_Initialized => return "return object is not definitely initialized";
         when Initialization_Legality_Branch_Merge_Not_Definite => return "branch merge does not prove definite initialization";
         when Initialization_Legality_Loop_Merge_Not_Definite => return "loop merge does not prove definite initialization";
         when Initialization_Legality_Exception_Path_Loses_Initialization => return "exception path loses initialization";
         when Initialization_Legality_Finalization_Uses_Uninitialized_Object => return "finalization uses an uninitialized object";
         when Initialization_Legality_Use_After_Finalization => return "object is used after finalization";
         when Initialization_Legality_Unreachable_Initialization => return "initialization occurs only on an unreachable path";
         when Initialization_Legality_Linked_Assignment_Error => return "linked assignment legality blocks initialization proof";
         when Initialization_Legality_Linked_Return_Error => return "linked return legality blocks initialization proof";
         when Initialization_Legality_Linked_Control_Flow_Error => return "linked control-flow legality blocks initialization proof";
         when Initialization_Legality_Linked_Exception_Finalization_Error => return "linked exception/finalization legality blocks initialization proof";
         when Initialization_Legality_Linked_Closure_Error => return "integrated semantic closure blocks initialization proof";
         when Initialization_Legality_Indeterminate => return "initialization legality is indeterminate";
         when others => return "initialization legality checked";
      end case;
   end Text_For;

   procedure Clear (Model : in out Initialization_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Initialization_Context_Model;
      Info  : Initialization_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Fingerprint := Mix
        (Model.Fingerprint,
         Natural (Info.Id) + Initialization_Context_Kind'Pos (Info.Kind) +
         Object_State'Pos (Info.Before_State) * 7 +
         Object_State'Pos (Info.After_State) * 11 + Info.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Initialization_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Initialization_Context_Model;
      Index : Positive) return Initialization_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Initialization_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Initialization_Context_Model) return Initialization_Legality_Model is
      Result : Initialization_Legality_Model;
      C      : Initialization_Context_Info;
      R      : Initialization_Legality_Info;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         C := Contexts.Contexts.Element (I);
         R := (others => <>);
         R.Id := Initialization_Legality_Id (I);
         R.Context := C.Id;
         R.Kind := C.Kind;
         R.Node := C.Node;
         R.Object_Node := C.Object_Node;
         R.Component_Node := C.Component_Node;
         R.Object_Name := C.Object_Name;
         R.Status := Status_For (C);
         R.Message := To_Unbounded_String (Text_For (R.Status));
         R.Detail := To_Unbounded_String
           ("definite-initialization flow status=" & Initialization_Legality_Status'Image (R.Status));
         R.Before_State := C.Before_State;
         R.After_State := C.After_State;
         R.Flow := C.Flow;
         R.Assignment_Status := C.Assignment_Status;
         R.Return_Status := C.Return_Status;
         R.Control_Status := C.Control_Status;
         R.Exception_Status := C.Exception_Status;
         R.Closure_Status := C.Closure_Status;
         R.Start_Line := C.Start_Line;
         R.Start_Column := C.Start_Column;
         R.End_Line := C.End_Line;
         R.End_Column := C.End_Column;
         R.Source_Fingerprint := C.Source_Fingerprint;
         R.Fingerprint := Mix
           (Natural (R.Id) + Natural (R.Context),
            Initialization_Legality_Status'Pos (R.Status) * 31 +
            Initialization_Context_Kind'Pos (R.Kind) * 17 +
            Object_State'Pos (R.Before_State) * 13 +
            Object_State'Pos (R.After_State) * 19 + C.Source_Fingerprint);
         Result.Rows.Append (R);
         Result.Fingerprint := Mix (Result.Fingerprint, R.Fingerprint);
      end loop;
      Result.Fingerprint := Mix (Result.Fingerprint, Fingerprint (Contexts));
      return Result;
   end Build;

   function Row_Count (Model : Initialization_Legality_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Initialization_Legality_Model;
      Index : Positive) return Initialization_Legality_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Object
     (Model : Initialization_Legality_Model;
      Name  : String) return Initialization_Legality_Info is
   begin
      for Row of Model.Rows loop
         if To_String (Row.Object_Name) = Name then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Object;

   function Rows_For_Status
     (Model  : Initialization_Legality_Model;
      Status : Initialization_Legality_Status) return Initialization_Legality_Model is
      Result : Initialization_Legality_Model;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Initialization_Legality_Model;
      Kind  : Initialization_Context_Kind) return Initialization_Legality_Model is
      Result : Initialization_Legality_Model;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Node
     (Model : Initialization_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Initialization_Legality_Model is
      Result : Initialization_Legality_Model;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Node;

   function Count_Status
     (Model  : Initialization_Legality_Model;
      Status : Initialization_Legality_Status) return Natural is
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
     (Model : Initialization_Legality_Model;
      Kind  : Initialization_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Row_Count (Model : Initialization_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Row_Count;

   function Error_Row_Count (Model : Initialization_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Is_Legal (Row.Status)
           and then Row.Status /= Initialization_Legality_Not_Checked
           and then Row.Status /= Initialization_Legality_Indeterminate
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Row_Count;

   function Linked_Error_Count (Model : Initialization_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Linked_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Linked_Error_Count;

   function Indeterminate_Row_Count (Model : Initialization_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Initialization_Legality_Indeterminate);
   end Indeterminate_Row_Count;

   function Fingerprint (Model : Initialization_Legality_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Definite_Initialization_Flow_Legality;
