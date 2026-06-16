with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Volatile_Atomic_Shared_State_Legality is

   pragma Suppress (Overflow_Check);

   use type Abstract_States.Abstract_State_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Flow_Proof.Flow_Contract_Proof_Status;
   use type Stabilized.Final_Stabilized_Closure_Status;
   use type Tasking_Deep.Deep_Tasking_Status;

   function Mix (Left : Natural; Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 37) mod 2_147_483_647;
   end Mix;

   function Closure_Accepted (Status : Stabilized.Final_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Stabilized.Final_Stabilized_Closure_Accepted_Current
        or else Status = Stabilized.Final_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Is_Legal (Status : Shared_State_Status) return Boolean is
   begin
      case Status is
         when Shared_State_Legal_Volatile_Read_Accepted
            | Shared_State_Legal_Volatile_Write_Accepted
            | Shared_State_Legal_Volatile_Order_Accepted
            | Shared_State_Legal_Atomic_Read_Accepted
            | Shared_State_Legal_Atomic_Write_Accepted
            | Shared_State_Legal_Atomic_Read_Write_Accepted
            | Shared_State_Legal_Independent_Component_Accepted
            | Shared_State_Legal_Shared_Variable_Access_Accepted
            | Shared_State_Legal_Protected_Object_Access_Accepted
            | Shared_State_Legal_Task_Activation_Accepted
            | Shared_State_Legal_Task_Termination_Accepted
            | Shared_State_Legal_Shared_Passive_Accepted
            | Shared_State_Legal_Abstract_State_Effect_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Legal;

   function Is_Volatile_Error (Status : Shared_State_Status) return Boolean is
   begin
      return Status = Shared_State_Volatile_Read_Order_Blocker
        or else Status = Shared_State_Volatile_Write_Order_Blocker
        or else Status = Shared_State_Volatile_Read_Write_Reordering;
   end Is_Volatile_Error;

   function Is_Atomic_Error (Status : Shared_State_Status) return Boolean is
   begin
      return Status = Shared_State_Atomic_Read_Write_Blocker
        or else Status = Shared_State_Atomic_Nonatomic_Mixed_Access
        or else Status = Shared_State_Atomic_Alignment_Blocker
        or else Status = Shared_State_Independent_Component_Overlap;
   end Is_Atomic_Error;

   function Is_Shared_Variable_Error (Status : Shared_State_Status) return Boolean is
   begin
      return Status = Shared_State_Shared_Variable_Unprotected_Access
        or else Status = Shared_State_Protected_State_Mode_Mismatch
        or else Status = Shared_State_Task_Activation_Effect_Blocker
        or else Status = Shared_State_Task_Termination_Effect_Blocker
        or else Status = Shared_State_Shared_Passive_Effect_Blocker;
   end Is_Shared_Variable_Error;

   function Is_Dependency_Error (Status : Shared_State_Status) return Boolean is
   begin
      return Status = Shared_State_Missing_Abstract_State_Row
        or else Status = Shared_State_Abstract_State_Blocker
        or else Status = Shared_State_Missing_Flow_Proof_Row
        or else Status = Shared_State_Flow_Proof_Blocker
        or else Status = Shared_State_Missing_Tasking_Row
        or else Status = Shared_State_Tasking_Blocker
        or else Status = Shared_State_Missing_Stabilized_Closure_Row
        or else Status = Shared_State_Stabilized_Closure_Blocker;
   end Is_Dependency_Error;

   function Is_Indeterminate (Status : Shared_State_Status) return Boolean is
   begin
      return Status = Shared_State_Indeterminate;
   end Is_Indeterminate;

   function Has_Error (Info : Shared_State_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status)
        and then Info.Status /= Shared_State_Not_Checked;
   end Has_Error;

   function Legal_Status_For (Kind : Shared_State_Context_Kind) return Shared_State_Status is
   begin
      case Kind is
         when Shared_State_Volatile_Read =>
            return Shared_State_Legal_Volatile_Read_Accepted;
         when Shared_State_Volatile_Write =>
            return Shared_State_Legal_Volatile_Write_Accepted;
         when Shared_State_Volatile_Read_Write_Order =>
            return Shared_State_Legal_Volatile_Order_Accepted;
         when Shared_State_Atomic_Read =>
            return Shared_State_Legal_Atomic_Read_Accepted;
         when Shared_State_Atomic_Write =>
            return Shared_State_Legal_Atomic_Write_Accepted;
         when Shared_State_Atomic_Read_Write =>
            return Shared_State_Legal_Atomic_Read_Write_Accepted;
         when Shared_State_Independent_Component =>
            return Shared_State_Legal_Independent_Component_Accepted;
         when Shared_State_Shared_Variable_Access =>
            return Shared_State_Legal_Shared_Variable_Access_Accepted;
         when Shared_State_Protected_Object_Access =>
            return Shared_State_Legal_Protected_Object_Access_Accepted;
         when Shared_State_Task_Activation_Effect =>
            return Shared_State_Legal_Task_Activation_Accepted;
         when Shared_State_Task_Termination_Effect =>
            return Shared_State_Legal_Task_Termination_Accepted;
         when Shared_State_Shared_Passive_Context =>
            return Shared_State_Legal_Shared_Passive_Accepted;
         when Shared_State_Abstract_State_Effect =>
            return Shared_State_Legal_Abstract_State_Effect_Accepted;
         when Shared_State_Unknown =>
            return Shared_State_Indeterminate;
      end case;
   end Legal_Status_For;

   function Count_Local_Blockers (C : Shared_State_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if C.Volatile_Read_Order_Error then Count := Count + 1; end if;
      if C.Volatile_Write_Order_Error then Count := Count + 1; end if;
      if C.Volatile_Reordering then Count := Count + 1; end if;
      if C.Atomic_Read_Write_Error then Count := Count + 1; end if;
      if C.Atomic_Nonatomic_Mixed_Access then Count := Count + 1; end if;
      if C.Atomic_Alignment_Error then Count := Count + 1; end if;
      if C.Independent_Component_Overlap then Count := Count + 1; end if;
      if C.Shared_Variable_Unprotected then Count := Count + 1; end if;
      if C.Protected_Mode_Mismatch then Count := Count + 1; end if;
      if C.Task_Activation_Error then Count := Count + 1; end if;
      if C.Task_Termination_Error then Count := Count + 1; end if;
      if C.Shared_Passive_Error then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Count_Local_Blockers;

   function Classify (C : Shared_State_Context_Info) return Shared_State_Status is
      Local_Blockers : constant Natural := Count_Local_Blockers (C);
   begin
      if Local_Blockers > 1 then
         return Shared_State_Multiple_Blockers;
      elsif C.Volatile_Read_Order_Error then
         return Shared_State_Volatile_Read_Order_Blocker;
      elsif C.Volatile_Write_Order_Error then
         return Shared_State_Volatile_Write_Order_Blocker;
      elsif C.Volatile_Reordering then
         return Shared_State_Volatile_Read_Write_Reordering;
      elsif C.Atomic_Read_Write_Error then
         return Shared_State_Atomic_Read_Write_Blocker;
      elsif C.Atomic_Nonatomic_Mixed_Access then
         return Shared_State_Atomic_Nonatomic_Mixed_Access;
      elsif C.Atomic_Alignment_Error then
         return Shared_State_Atomic_Alignment_Blocker;
      elsif C.Independent_Component_Overlap then
         return Shared_State_Independent_Component_Overlap;
      elsif C.Shared_Variable_Unprotected then
         return Shared_State_Shared_Variable_Unprotected_Access;
      elsif C.Protected_Mode_Mismatch then
         return Shared_State_Protected_State_Mode_Mismatch;
      elsif C.Task_Activation_Error then
         return Shared_State_Task_Activation_Effect_Blocker;
      elsif C.Task_Termination_Error then
         return Shared_State_Task_Termination_Effect_Blocker;
      elsif C.Shared_Passive_Error then
         return Shared_State_Shared_Passive_Effect_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Shared_State_Source_Fingerprint_Mismatch;
      elsif C.Requires_Abstract_State and then C.Abstract_State_Status = Abstract_States.Abstract_State_Not_Checked then
         return Shared_State_Missing_Abstract_State_Row;
      elsif C.Requires_Abstract_State and then not Abstract_States.Is_Legal (C.Abstract_State_Status) then
         return Shared_State_Abstract_State_Blocker;
      elsif C.Requires_Flow_Proof and then C.Flow_Proof_Status = Flow_Proof.Flow_Contract_Proof_Not_Checked then
         return Shared_State_Missing_Flow_Proof_Row;
      elsif C.Requires_Flow_Proof and then not Flow_Proof.Is_Legal (C.Flow_Proof_Status) then
         return Shared_State_Flow_Proof_Blocker;
      elsif C.Requires_Tasking and then C.Tasking_Status = Tasking_Deep.Deep_Tasking_Not_Checked then
         return Shared_State_Missing_Tasking_Row;
      elsif C.Requires_Tasking and then not Tasking_Deep.Is_Legal (C.Tasking_Status) then
         return Shared_State_Tasking_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Status = Stabilized.Final_Stabilized_Closure_Not_Checked then
         return Shared_State_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Status) then
         return Shared_State_Stabilized_Closure_Blocker;
      else
         return Legal_Status_For (C.Kind);
      end if;
   end Classify;

   function Message_For (Status : Shared_State_Status; Kind : Shared_State_Context_Kind) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("volatile/atomic/shared-state legality " & Shared_State_Status'Image (Status) &
         " kind=" & Shared_State_Context_Kind'Image (Kind));
   end Message_For;

   function Row_Fingerprint (Row : Shared_State_Info) return Natural is
      Text : constant String := To_String (Row.Message) & To_String (Row.Detail);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Shared_State_Context_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Shared_State_Status'Pos (Row.Status) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row (C : Shared_State_Context_Info; Index : Positive) return Shared_State_Info is
      Status : constant Shared_State_Status := Classify (C);
      Row : Shared_State_Info;
   begin
      Row.Id := Shared_State_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Node := C.Node;
      Row.Object_Name := C.Object_Name;
      Row.State_Name := C.State_Name;
      Row.Operation_Name := C.Operation_Name;
      Row.Message := Message_For (Status, C.Kind);
      Row.Detail := To_Unbounded_String
        ("abstract=" & Abstract_States.Abstract_State_Status'Image (C.Abstract_State_Status) &
         " flow=" & Flow_Proof.Flow_Contract_Proof_Status'Image (C.Flow_Proof_Status) &
         " tasking=" & Tasking_Deep.Deep_Tasking_Status'Image (C.Tasking_Status) &
         " closure=" & Stabilized.Final_Stabilized_Closure_Status'Image (C.Stabilized_Status));
      Row.Blocker_Count := Count_Local_Blockers (C);
      if Is_Dependency_Error (Status) then
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

   procedure Clear (Model : in out Shared_State_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Shared_State_Context_Model; Info : Shared_State_Context_Info) is
      H : Natural := Model.Fingerprint;
   begin
      Model.Items.Append (Info);
      H := Mix (H, Natural (Info.Id));
      H := Mix (H, Shared_State_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Natural (Info.Node));
      H := Mix (H, Info.Source_Fingerprint);
      H := Mix (H, Info.Expected_Source_Fingerprint);
      Model.Fingerprint := H;
   end Add_Context;

   function Context_Count (Model : Shared_State_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Shared_State_Context_Model; Index : Positive) return Shared_State_Context_Info is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Shared_State_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Shared_State_Context_Model) return Shared_State_Model is
      Model : Shared_State_Model;
      H : Natural := Contexts.Fingerprint;
      I : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Shared_State_Info := Make_Row (C, I);
         begin
            Model.Rows.Append (Row);
            H := Mix (H, Row.Fingerprint);
            I := I + 1;
         end;
      end loop;
      Model.Fingerprint := H;
      return Model;
   end Build;

   function Row_Count (Model : Shared_State_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At (Model : Shared_State_Model; Index : Positive) return Shared_State_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node (Model : Shared_State_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Shared_State_Model; Status : Shared_State_Status) return Shared_State_Set is
      Set : Shared_State_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Set.Rows.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Shared_State_Model; Kind : Shared_State_Context_Kind) return Shared_State_Set is
      Set : Shared_State_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Set.Rows.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Set_Count (Set : Shared_State_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At (Set : Shared_State_Set; Index : Positive) return Shared_State_Info is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status (Model : Shared_State_Model; Status : Shared_State_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Shared_State_Model; Kind : Shared_State_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Has_Error (Row) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Volatile_Error_Count (Model : Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Volatile_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Volatile_Error_Count;

   function Atomic_Error_Count (Model : Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Atomic_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Atomic_Error_Count;

   function Shared_Variable_Error_Count (Model : Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Shared_Variable_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Shared_Variable_Error_Count;

   function Dependency_Error_Count (Model : Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Dependency_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Dependency_Error_Count;

   function Indeterminate_Count (Model : Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Indeterminate_Count;

   function Fingerprint (Model : Shared_State_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Volatile_Atomic_Shared_State_Legality;
