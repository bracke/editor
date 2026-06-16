with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Shared_State_Final_Legality is

   pragma Suppress (Overflow_Check);

   use type Abstract_States.Abstract_State_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Overload_State.Overload_Shared_State_Status;
   use type Rep_State.Representation_Shared_State_Status;
   use type Shared_State.Shared_State_Status;
   use type Tasking_Deep.Deep_Tasking_Status;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 131) xor (Hash_Value (Right) + 16#9E37#);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Is_Legal (Status : Tasking_Shared_State_Status) return Boolean is
   begin
      case Status is
         when Tasking_Shared_State_Legal_Protected_Function_Read_Accepted
            | Tasking_Shared_State_Legal_Protected_Procedure_Write_Accepted
            | Tasking_Shared_State_Legal_Protected_Entry_Barrier_Accepted
            | Tasking_Shared_State_Legal_Entry_Family_Queue_Accepted
            | Tasking_Shared_State_Legal_Accept_Body_Effect_Accepted
            | Tasking_Shared_State_Legal_Requeue_Effect_Accepted
            | Tasking_Shared_State_Legal_Select_Alternative_Accepted
            | Tasking_Shared_State_Legal_Task_Activation_Accepted
            | Tasking_Shared_State_Legal_Task_Termination_Accepted
            | Tasking_Shared_State_Legal_Abortable_Finalization_Accepted
            | Tasking_Shared_State_Legal_Abstract_State_Access_Accepted
            | Tasking_Shared_State_Legal_Representation_Effect_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Legal;

   function Is_Dependency_Error (Status : Tasking_Shared_State_Status) return Boolean is
   begin
      case Status is
         when Tasking_Shared_State_Missing_Deep_Tasking_Row
            | Tasking_Shared_State_Deep_Tasking_Blocker
            | Tasking_Shared_State_Missing_Shared_State_Row
            | Tasking_Shared_State_Shared_State_Blocker
            | Tasking_Shared_State_Missing_Abstract_State_Row
            | Tasking_Shared_State_Abstract_State_Blocker
            | Tasking_Shared_State_Missing_Overload_State_Row
            | Tasking_Shared_State_Overload_State_Blocker
            | Tasking_Shared_State_Missing_Representation_State_Row
            | Tasking_Shared_State_Representation_State_Blocker =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Dependency_Error;

   function Is_Shared_State_Error (Status : Tasking_Shared_State_Status) return Boolean is
   begin
      case Status is
         when Tasking_Shared_State_Shared_State_Blocker
            | Tasking_Shared_State_Protected_Read_Mode_Blocker
            | Tasking_Shared_State_Protected_Write_Mode_Blocker
            | Tasking_Shared_State_Barrier_Side_Effect_Blocker
            | Tasking_Shared_State_Requeue_Shared_State_Blocker
            | Tasking_Shared_State_Select_Shared_State_Blocker
            | Tasking_Shared_State_Task_Activation_Shared_State_Blocker
            | Tasking_Shared_State_Task_Termination_Shared_State_Blocker
            | Tasking_Shared_State_Abort_Finalization_Shared_State_Blocker
            | Tasking_Shared_State_Abstract_State_Mode_Blocker =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Shared_State_Error;

   function Is_Tasking_Error (Status : Tasking_Shared_State_Status) return Boolean is
   begin
      case Status is
         when Tasking_Shared_State_Deep_Tasking_Blocker
            | Tasking_Shared_State_Entry_Family_Queue_Blocker
            | Tasking_Shared_State_Accept_Body_Effect_Blocker
            | Tasking_Shared_State_Requeue_Shared_State_Blocker
            | Tasking_Shared_State_Select_Shared_State_Blocker
            | Tasking_Shared_State_Task_Activation_Shared_State_Blocker
            | Tasking_Shared_State_Task_Termination_Shared_State_Blocker
            | Tasking_Shared_State_Abort_Finalization_Shared_State_Blocker =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Tasking_Error;

   function Is_Representation_Error (Status : Tasking_Shared_State_Status) return Boolean is
   begin
      case Status is
         when Tasking_Shared_State_Representation_State_Blocker
            | Tasking_Shared_State_Representation_Effect_Blocker =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Representation_Error;

   function Is_Indeterminate (Status : Tasking_Shared_State_Status) return Boolean is
   begin
      return Status = Tasking_Shared_State_Indeterminate;
   end Is_Indeterminate;

   function Has_Error (Info : Tasking_Shared_State_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status)
        and then Info.Status /= Tasking_Shared_State_Not_Checked;
   end Has_Error;

   function Legal_Status_For
     (Kind : Tasking_Shared_State_Context_Kind) return Tasking_Shared_State_Status is
   begin
      case Kind is
         when Tasking_Shared_State_Protected_Function_Read =>
            return Tasking_Shared_State_Legal_Protected_Function_Read_Accepted;
         when Tasking_Shared_State_Protected_Procedure_Write =>
            return Tasking_Shared_State_Legal_Protected_Procedure_Write_Accepted;
         when Tasking_Shared_State_Protected_Entry_Barrier =>
            return Tasking_Shared_State_Legal_Protected_Entry_Barrier_Accepted;
         when Tasking_Shared_State_Entry_Family_Queue =>
            return Tasking_Shared_State_Legal_Entry_Family_Queue_Accepted;
         when Tasking_Shared_State_Accept_Body_Effect =>
            return Tasking_Shared_State_Legal_Accept_Body_Effect_Accepted;
         when Tasking_Shared_State_Requeue_Effect =>
            return Tasking_Shared_State_Legal_Requeue_Effect_Accepted;
         when Tasking_Shared_State_Select_Alternative =>
            return Tasking_Shared_State_Legal_Select_Alternative_Accepted;
         when Tasking_Shared_State_Task_Activation =>
            return Tasking_Shared_State_Legal_Task_Activation_Accepted;
         when Tasking_Shared_State_Task_Termination =>
            return Tasking_Shared_State_Legal_Task_Termination_Accepted;
         when Tasking_Shared_State_Abortable_Finalization =>
            return Tasking_Shared_State_Legal_Abortable_Finalization_Accepted;
         when Tasking_Shared_State_Abstract_State_Access =>
            return Tasking_Shared_State_Legal_Abstract_State_Access_Accepted;
         when Tasking_Shared_State_Representation_Effect =>
            return Tasking_Shared_State_Legal_Representation_Effect_Accepted;
         when Tasking_Shared_State_Unknown =>
            return Tasking_Shared_State_Indeterminate;
      end case;
   end Legal_Status_For;

   function Local_Blocker_Count (C : Tasking_Shared_State_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if C.Protected_Read_Mode_Error then Count := Count + 1; end if;
      if C.Protected_Write_Mode_Error then Count := Count + 1; end if;
      if C.Barrier_Side_Effect_Error then Count := Count + 1; end if;
      if C.Entry_Family_Queue_Error then Count := Count + 1; end if;
      if C.Accept_Body_Effect_Error then Count := Count + 1; end if;
      if C.Requeue_Shared_State_Error then Count := Count + 1; end if;
      if C.Select_Shared_State_Error then Count := Count + 1; end if;
      if C.Task_Activation_Shared_State_Error then Count := Count + 1; end if;
      if C.Task_Termination_Shared_State_Error then Count := Count + 1; end if;
      if C.Abort_Finalization_Shared_State_Error then Count := Count + 1; end if;
      if C.Abstract_State_Mode_Error then Count := Count + 1; end if;
      if C.Representation_Effect_Error then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Tasking_Shared_State_Context_Info) return Tasking_Shared_State_Status is
      Local : constant Natural := Local_Blocker_Count (C);
   begin
      if Local > 1 then
         return Tasking_Shared_State_Multiple_Blockers;
      elsif C.Protected_Read_Mode_Error then
         return Tasking_Shared_State_Protected_Read_Mode_Blocker;
      elsif C.Protected_Write_Mode_Error then
         return Tasking_Shared_State_Protected_Write_Mode_Blocker;
      elsif C.Barrier_Side_Effect_Error then
         return Tasking_Shared_State_Barrier_Side_Effect_Blocker;
      elsif C.Entry_Family_Queue_Error then
         return Tasking_Shared_State_Entry_Family_Queue_Blocker;
      elsif C.Accept_Body_Effect_Error then
         return Tasking_Shared_State_Accept_Body_Effect_Blocker;
      elsif C.Requeue_Shared_State_Error then
         return Tasking_Shared_State_Requeue_Shared_State_Blocker;
      elsif C.Select_Shared_State_Error then
         return Tasking_Shared_State_Select_Shared_State_Blocker;
      elsif C.Task_Activation_Shared_State_Error then
         return Tasking_Shared_State_Task_Activation_Shared_State_Blocker;
      elsif C.Task_Termination_Shared_State_Error then
         return Tasking_Shared_State_Task_Termination_Shared_State_Blocker;
      elsif C.Abort_Finalization_Shared_State_Error then
         return Tasking_Shared_State_Abort_Finalization_Shared_State_Blocker;
      elsif C.Abstract_State_Mode_Error then
         return Tasking_Shared_State_Abstract_State_Mode_Blocker;
      elsif C.Representation_Effect_Error then
         return Tasking_Shared_State_Representation_Effect_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Tasking_Shared_State_Source_Fingerprint_Mismatch;
      elsif C.Requires_Deep_Tasking and then C.Deep_Tasking_Status = Tasking_Deep.Deep_Tasking_Not_Checked then
         return Tasking_Shared_State_Missing_Deep_Tasking_Row;
      elsif C.Requires_Deep_Tasking and then not Tasking_Deep.Is_Legal (C.Deep_Tasking_Status) then
         return Tasking_Shared_State_Deep_Tasking_Blocker;
      elsif C.Requires_Shared_State and then C.Shared_State_Status = Shared_State.Shared_State_Not_Checked then
         return Tasking_Shared_State_Missing_Shared_State_Row;
      elsif C.Requires_Shared_State and then not Shared_State.Is_Legal (C.Shared_State_Status) then
         return Tasking_Shared_State_Shared_State_Blocker;
      elsif C.Requires_Abstract_State and then C.Abstract_State_Status = Abstract_States.Abstract_State_Not_Checked then
         return Tasking_Shared_State_Missing_Abstract_State_Row;
      elsif C.Requires_Abstract_State and then not Abstract_States.Is_Legal (C.Abstract_State_Status) then
         return Tasking_Shared_State_Abstract_State_Blocker;
      elsif C.Requires_Overload_State and then C.Overload_State_Status = Overload_State.Overload_Shared_State_Not_Checked then
         return Tasking_Shared_State_Missing_Overload_State_Row;
      elsif C.Requires_Overload_State and then not Overload_State.Is_Legal (C.Overload_State_Status) then
         return Tasking_Shared_State_Overload_State_Blocker;
      elsif C.Requires_Representation_State and then C.Representation_State_Status = Rep_State.Representation_Shared_State_Not_Checked then
         return Tasking_Shared_State_Missing_Representation_State_Row;
      elsif C.Requires_Representation_State and then not Rep_State.Is_Legal (C.Representation_State_Status) then
         return Tasking_Shared_State_Representation_State_Blocker;
      else
         return Legal_Status_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Tasking_Shared_State_Status;
      Kind   : Tasking_Shared_State_Context_Kind) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("tasking shared-state final legality " &
         Tasking_Shared_State_Status'Image (Status) &
         " kind=" & Tasking_Shared_State_Context_Kind'Image (Kind));
   end Message_For;

   function Row_Fingerprint (Row : Tasking_Shared_State_Info) return Natural is
      Text : constant String := To_String (Row.Message) & To_String (Row.Detail);
      H    : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Tasking_Shared_State_Context_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Tasking_Shared_State_Status'Pos (Row.Status) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      for Ch of Text loop
         H := Mix (H, Character'Pos (Ch));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (C     : Tasking_Shared_State_Context_Info;
      Index : Positive) return Tasking_Shared_State_Info is
      Status : constant Tasking_Shared_State_Status := Classify (C);
      Row    : Tasking_Shared_State_Info;
   begin
      Row.Id := Tasking_Shared_State_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Node := C.Node;
      Row.Operation_Name := C.Operation_Name;
      Row.State_Name := C.State_Name;
      Row.Unit_Name := C.Unit_Name;
      Row.Message := Message_For (Status, C.Kind);
      Row.Detail := To_Unbounded_String
        ("tasking=" & Tasking_Deep.Deep_Tasking_Status'Image (C.Deep_Tasking_Status) &
         " shared=" & Shared_State.Shared_State_Status'Image (C.Shared_State_Status) &
         " abstract=" & Abstract_States.Abstract_State_Status'Image (C.Abstract_State_Status) &
         " overload=" & Overload_State.Overload_Shared_State_Status'Image (C.Overload_State_Status) &
         " representation=" & Rep_State.Representation_Shared_State_Status'Image (C.Representation_State_Status));
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Is_Dependency_Error (Status) or else Is_Indeterminate (Status) then
         Row.Blocker_Count := Row.Blocker_Count + 1;
      end if;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Tasking_Shared_State_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Tasking_Shared_State_Context_Model; Info : Tasking_Shared_State_Context_Info) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix
        (Model.Fingerprint,
         Natural (Info.Id) + Tasking_Shared_State_Context_Kind'Pos (Info.Kind) + Natural (Info.Node) + Info.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Tasking_Shared_State_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Tasking_Shared_State_Context_Model; Index : Positive) return Tasking_Shared_State_Context_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Tasking_Shared_State_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Tasking_Shared_State_Context_Model) return Tasking_Shared_State_Model is
      Result : Tasking_Shared_State_Model;
      Index  : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Tasking_Shared_State_Info := Make_Row (C, Index);
         begin
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
            Index := Index + 1;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Tasking_Shared_State_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At (Model : Tasking_Shared_State_Model; Index : Positive) return Tasking_Shared_State_Info is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node (Model : Tasking_Shared_State_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Shared_State_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Tasking_Shared_State_Model; Status : Tasking_Shared_State_Status) return Tasking_Shared_State_Set is
      Result : Tasking_Shared_State_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Tasking_Shared_State_Model; Kind : Tasking_Shared_State_Context_Kind) return Tasking_Shared_State_Set is
      Result : Tasking_Shared_State_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Set_Count (Set : Tasking_Shared_State_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At (Set : Tasking_Shared_State_Set; Index : Positive) return Tasking_Shared_State_Info is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status (Model : Tasking_Shared_State_Model; Status : Tasking_Shared_State_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Tasking_Shared_State_Model; Kind : Tasking_Shared_State_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Tasking_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Tasking_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Has_Error (Row) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Error_Count;

   function Dependency_Error_Count (Model : Tasking_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Dependency_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Dependency_Error_Count;

   function Shared_State_Error_Count (Model : Tasking_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Shared_State_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Shared_State_Error_Count;

   function Tasking_Error_Count (Model : Tasking_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Tasking_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Tasking_Error_Count;

   function Representation_Error_Count (Model : Tasking_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Representation_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Representation_Error_Count;

   function Indeterminate_Count (Model : Tasking_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Indeterminate_Count;

   function Fingerprint (Model : Tasking_Shared_State_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Tasking_Shared_State_Final_Legality;
