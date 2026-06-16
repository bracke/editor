with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Abstract_State_Refined_State_Legality is

   pragma Suppress (Overflow_Check);

   use type Stabilized.Final_Stabilized_Closure_Status;
   use type Flow_Proof.Flow_Contract_Proof_Status;
   use type Tasking_Deep.Deep_Tasking_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 37) mod 2_147_483_647;
   end Mix;

   function Closure_Accepted (Status : Stabilized.Final_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Stabilized.Final_Stabilized_Closure_Accepted_Current
        or else Status = Stabilized.Final_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Is_Legal (Status : Abstract_State_Status) return Boolean is
   begin
      case Status is
         when Abstract_State_Legal_Declaration_Accepted
            | Abstract_State_Legal_Refined_State_Accepted
            | Abstract_State_Legal_Constituent_Mapping_Accepted
            | Abstract_State_Legal_Global_Use_Accepted
            | Abstract_State_Legal_Depends_Source_Accepted
            | Abstract_State_Legal_Depends_Target_Accepted
            | Abstract_State_Legal_Cross_Unit_View_Accepted
            | Abstract_State_Legal_Task_Protected_Shared_State_Accepted
            | Abstract_State_Legal_Volatile_State_Accepted
            | Abstract_State_Legal_Atomic_State_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Legal;

   function Is_Flow_Error (Status : Abstract_State_Status) return Boolean is
   begin
      return Status = Abstract_State_Missing_Flow_Proof_Row
        or else Status = Abstract_State_Flow_Proof_Blocker;
   end Is_Flow_Error;

   function Is_Tasking_Error (Status : Abstract_State_Status) return Boolean is
   begin
      return Status = Abstract_State_Missing_Tasking_Row
        or else Status = Abstract_State_Tasking_Blocker;
   end Is_Tasking_Error;

   function Is_Closure_Error (Status : Abstract_State_Status) return Boolean is
   begin
      return Status = Abstract_State_Missing_Stabilized_Closure_Row
        or else Status = Abstract_State_Stabilized_Closure_Blocker;
   end Is_Closure_Error;

   function Is_Refinement_Error (Status : Abstract_State_Status) return Boolean is
   begin
      case Status is
         when Abstract_State_Missing_Abstract_State_Declaration
            | Abstract_State_Duplicate_Abstract_State
            | Abstract_State_Missing_Refined_State_Aspect
            | Abstract_State_Missing_Constituent
            | Abstract_State_Extra_Constituent
            | Abstract_State_Constituent_Mode_Mismatch
            | Abstract_State_Constituent_Not_Visible
            | Abstract_State_Abstract_Global_Mode_Mismatch
            | Abstract_State_Abstract_Depends_Missing_Edge
            | Abstract_State_Abstract_Depends_Extra_Edge
            | Abstract_State_Refinement_Cycle
            | Abstract_State_Refinement_Overflow
            | Abstract_State_Source_Fingerprint_Mismatch
            | Abstract_State_Multiple_Blockers =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Refinement_Error;

   function Is_State_Effect_Error (Status : Abstract_State_Status) return Boolean is
   begin
      return Status = Abstract_State_Volatile_Effect_Blocker
        or else Status = Abstract_State_Atomic_Effect_Blocker;
   end Is_State_Effect_Error;

   function Is_Indeterminate (Status : Abstract_State_Status) return Boolean is
   begin
      return Status = Abstract_State_Indeterminate;
   end Is_Indeterminate;

   function Has_Error (Info : Abstract_State_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status)
        and then Info.Status /= Abstract_State_Not_Checked;
   end Has_Error;

   function Legal_Status_For (Kind : Abstract_State_Context_Kind) return Abstract_State_Status is
   begin
      case Kind is
         when Abstract_State_Declaration =>
            return Abstract_State_Legal_Declaration_Accepted;
         when Abstract_State_Refined_State_Aspect =>
            return Abstract_State_Legal_Refined_State_Accepted;
         when Abstract_State_Constituent_Mapping =>
            return Abstract_State_Legal_Constituent_Mapping_Accepted;
         when Abstract_State_Global_Use =>
            return Abstract_State_Legal_Global_Use_Accepted;
         when Abstract_State_Depends_Source =>
            return Abstract_State_Legal_Depends_Source_Accepted;
         when Abstract_State_Depends_Target =>
            return Abstract_State_Legal_Depends_Target_Accepted;
         when Abstract_State_Cross_Unit_View =>
            return Abstract_State_Legal_Cross_Unit_View_Accepted;
         when Abstract_State_Task_Protected_Shared_State =>
            return Abstract_State_Legal_Task_Protected_Shared_State_Accepted;
         when Abstract_State_Volatile_State =>
            return Abstract_State_Legal_Volatile_State_Accepted;
         when Abstract_State_Atomic_State =>
            return Abstract_State_Legal_Atomic_State_Accepted;
         when Abstract_State_Unknown =>
            return Abstract_State_Indeterminate;
      end case;
   end Legal_Status_For;

   function Count_Local_Blockers (C : Abstract_State_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if C.Missing_Abstract_State then Count := Count + 1; end if;
      if C.Duplicate_Abstract_State then Count := Count + 1; end if;
      if C.Missing_Refined_State then Count := Count + 1; end if;
      if C.Missing_Constituent then Count := Count + 1; end if;
      if C.Extra_Constituent then Count := Count + 1; end if;
      if C.Constituent_Mode_Mismatch then Count := Count + 1; end if;
      if C.Constituent_Not_Visible then Count := Count + 1; end if;
      if C.Abstract_Global_Mode_Mismatch then Count := Count + 1; end if;
      if C.Depends_Missing_Edge then Count := Count + 1; end if;
      if C.Depends_Extra_Edge then Count := Count + 1; end if;
      if C.Refinement_Cycle then Count := Count + 1; end if;
      if C.Refinement_Overflow then Count := Count + 1; end if;
      if C.Volatile_Effect_Error then Count := Count + 1; end if;
      if C.Atomic_Effect_Error then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Count_Local_Blockers;

   function Classify (C : Abstract_State_Context_Info) return Abstract_State_Status is
      Local_Blockers : constant Natural := Count_Local_Blockers (C);
   begin
      if Local_Blockers > 1 then
         return Abstract_State_Multiple_Blockers;
      elsif C.Missing_Abstract_State then
         return Abstract_State_Missing_Abstract_State_Declaration;
      elsif C.Duplicate_Abstract_State then
         return Abstract_State_Duplicate_Abstract_State;
      elsif C.Missing_Refined_State then
         return Abstract_State_Missing_Refined_State_Aspect;
      elsif C.Missing_Constituent then
         return Abstract_State_Missing_Constituent;
      elsif C.Extra_Constituent then
         return Abstract_State_Extra_Constituent;
      elsif C.Constituent_Mode_Mismatch then
         return Abstract_State_Constituent_Mode_Mismatch;
      elsif C.Constituent_Not_Visible then
         return Abstract_State_Constituent_Not_Visible;
      elsif C.Abstract_Global_Mode_Mismatch then
         return Abstract_State_Abstract_Global_Mode_Mismatch;
      elsif C.Depends_Missing_Edge then
         return Abstract_State_Abstract_Depends_Missing_Edge;
      elsif C.Depends_Extra_Edge then
         return Abstract_State_Abstract_Depends_Extra_Edge;
      elsif C.Refinement_Cycle then
         return Abstract_State_Refinement_Cycle;
      elsif C.Refinement_Overflow then
         return Abstract_State_Refinement_Overflow;
      elsif C.Volatile_Effect_Error then
         return Abstract_State_Volatile_Effect_Blocker;
      elsif C.Atomic_Effect_Error then
         return Abstract_State_Atomic_Effect_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Abstract_State_Source_Fingerprint_Mismatch;
      elsif C.Requires_Flow_Proof and then C.Flow_Proof_Status = Flow_Proof.Flow_Contract_Proof_Not_Checked then
         return Abstract_State_Missing_Flow_Proof_Row;
      elsif C.Requires_Flow_Proof and then not Flow_Proof.Is_Legal (C.Flow_Proof_Status) then
         return Abstract_State_Flow_Proof_Blocker;
      elsif C.Requires_Tasking and then C.Tasking_Status = Tasking_Deep.Deep_Tasking_Not_Checked then
         return Abstract_State_Missing_Tasking_Row;
      elsif C.Requires_Tasking and then not Tasking_Deep.Is_Legal (C.Tasking_Status) then
         return Abstract_State_Tasking_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Status = Stabilized.Final_Stabilized_Closure_Not_Checked then
         return Abstract_State_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Status) then
         return Abstract_State_Stabilized_Closure_Blocker;
      else
         return Legal_Status_For (C.Kind);
      end if;
   end Classify;

   function Message_For (Status : Abstract_State_Status; Kind : Abstract_State_Context_Kind) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("abstract/refined state legality " & Abstract_State_Status'Image (Status) &
         " kind=" & Abstract_State_Context_Kind'Image (Kind));
   end Message_For;

   function Row_Fingerprint (Row : Abstract_State_Info) return Natural is
      Text : constant String := To_String (Row.Message) & To_String (Row.Detail);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Abstract_State_Context_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Abstract_State_Status'Pos (Row.Status) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row (C : Abstract_State_Context_Info; Index : Positive) return Abstract_State_Info is
      Status : constant Abstract_State_Status := Classify (C);
      Row : Abstract_State_Info;
   begin
      Row.Id := Abstract_State_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Node := C.Node;
      Row.State_Name := C.State_Name;
      Row.Constituent_Name := C.Constituent_Name;
      Row.Unit_Name := C.Unit_Name;
      Row.Blocker_Count := Count_Local_Blockers (C);
      if Has_Error (Row) and then Row.Blocker_Count = 0 then
         Row.Blocker_Count := 1;
      end if;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Message := Message_For (Status, C.Kind);
      Row.Detail := To_Unbounded_String
        ("state=" & To_String (C.State_Name) &
         " constituent=" & To_String (C.Constituent_Name) &
         " unit=" & To_String (C.Unit_Name));
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row (Model : in out Abstract_State_Model; Row : Abstract_State_Info) is
   begin
      Model.Items.Append (Row);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
      if Is_Legal (Row.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      elsif Row.Status /= Abstract_State_Not_Checked then
         Model.Error_Total := Model.Error_Total + 1;
      end if;
      if Is_Flow_Error (Row.Status) then Model.Flow_Error_Total := Model.Flow_Error_Total + 1; end if;
      if Is_Tasking_Error (Row.Status) then Model.Tasking_Error_Total := Model.Tasking_Error_Total + 1; end if;
      if Is_Closure_Error (Row.Status) then Model.Closure_Error_Total := Model.Closure_Error_Total + 1; end if;
      if Is_Refinement_Error (Row.Status) then Model.Refinement_Error_Total := Model.Refinement_Error_Total + 1; end if;
      if Is_State_Effect_Error (Row.Status) then Model.State_Effect_Error_Total := Model.State_Effect_Error_Total + 1; end if;
      if Is_Indeterminate (Row.Status) then Model.Indeterminate_Total := Model.Indeterminate_Total + 1; end if;
   end Add_Row;

   procedure Clear (Model : in out Abstract_State_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Abstract_State_Context_Model; Info : Abstract_State_Context_Info) is
      H : Natural := Natural (Info.Id);
   begin
      Model.Contexts.Append (Info);
      H := Mix (H, Abstract_State_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Natural (Info.Node));
      H := Mix (H, Info.Source_Fingerprint);
      H := Mix (H, Info.Expected_Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, H);
   end Add_Context;

   function Context_Count (Model : Abstract_State_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At (Model : Abstract_State_Context_Model; Index : Positive) return Abstract_State_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Abstract_State_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Abstract_State_Context_Model) return Abstract_State_Model is
      Result : Abstract_State_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         Add_Row (Result, Make_Row (Context_At (Contexts, I), I));
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Abstract_State_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At (Model : Abstract_State_Model; Index : Positive) return Abstract_State_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node (Model : Abstract_State_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Abstract_State_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Abstract_State_Model; Status : Abstract_State_Status) return Abstract_State_Set is
      Result : Abstract_State_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Abstract_State_Model; Kind : Abstract_State_Context_Kind) return Abstract_State_Set is
      Result : Abstract_State_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Set_Count (Set : Abstract_State_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At (Set : Abstract_State_Set; Index : Positive) return Abstract_State_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status (Model : Abstract_State_Model; Status : Abstract_State_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Abstract_State_Model; Kind : Abstract_State_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Abstract_State_Model) return Natural is begin return Model.Legal_Total; end Legal_Count;
   function Error_Count (Model : Abstract_State_Model) return Natural is begin return Model.Error_Total; end Error_Count;
   function Flow_Error_Count (Model : Abstract_State_Model) return Natural is begin return Model.Flow_Error_Total; end Flow_Error_Count;
   function Tasking_Error_Count (Model : Abstract_State_Model) return Natural is begin return Model.Tasking_Error_Total; end Tasking_Error_Count;
   function Closure_Error_Count (Model : Abstract_State_Model) return Natural is begin return Model.Closure_Error_Total; end Closure_Error_Count;
   function Refinement_Error_Count (Model : Abstract_State_Model) return Natural is begin return Model.Refinement_Error_Total; end Refinement_Error_Count;
   function State_Effect_Error_Count (Model : Abstract_State_Model) return Natural is begin return Model.State_Effect_Error_Total; end State_Effect_Error_Count;
   function Indeterminate_Count (Model : Abstract_State_Model) return Natural is begin return Model.Indeterminate_Total; end Indeterminate_Count;
   function Fingerprint (Model : Abstract_State_Model) return Natural is begin return Model.Result_Fingerprint; end Fingerprint;

end Editor.Ada_Abstract_State_Refined_State_Legality;
