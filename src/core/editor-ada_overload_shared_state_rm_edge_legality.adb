with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Overload_Shared_State_RM_Edge_Legality is

   pragma Suppress (Overflow_Check);

   use type Abstract_States.Abstract_State_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_RM.Final_RM_Status;
   use type Shared_State.Shared_State_Status;

   function Mix (Seed : Natural; Value : Natural) return Natural is
   begin
      return ((Seed * 131) + Value + 17) mod 2_147_483_647;
   end Mix;

   function Closure_Final_RM_Legal (Status : Final_RM.Final_RM_Status) return Boolean is
   begin
      return Final_RM.Is_Legal (Status);
   end Closure_Final_RM_Legal;

   function Shared_Legal (Status : Shared_State.Shared_State_Status) return Boolean is
   begin
      return Shared_State.Is_Legal (Status);
   end Shared_Legal;

   function Abstract_Legal (Status : Abstract_States.Abstract_State_Status) return Boolean is
   begin
      return Abstract_States.Is_Legal (Status);
   end Abstract_Legal;

   function Is_Legal (Status : Overload_Shared_State_Status) return Boolean is
   begin
      return Status in
        Overload_Shared_State_Legal_Prefixed_Call_Accepted |
        Overload_Shared_State_Legal_Dispatching_Call_Accepted |
        Overload_Shared_State_Legal_Access_Subprogram_Call_Accepted |
        Overload_Shared_State_Legal_Class_Wide_Result_Accepted |
        Overload_Shared_State_Legal_Inherited_Primitive_Accepted |
        Overload_Shared_State_Legal_Generic_Formal_Subprogram_Accepted |
        Overload_Shared_State_Legal_Universal_Numeric_Operator_Accepted |
        Overload_Shared_State_Legal_Renamed_Primitive_Accepted |
        Overload_Shared_State_Legal_Abstract_State_Effect_Accepted |
        Overload_Shared_State_Legal_Volatile_Atomic_Effect_Accepted;
   end Is_Legal;

   function Is_Dependency_Blocker (Status : Overload_Shared_State_Status) return Boolean is
   begin
      return Status in
        Overload_Shared_State_Missing_Final_RM_Row |
        Overload_Shared_State_Final_RM_Blocker |
        Overload_Shared_State_Missing_Shared_State_Row |
        Overload_Shared_State_Shared_State_Blocker |
        Overload_Shared_State_Missing_Abstract_State_Row |
        Overload_Shared_State_Abstract_State_Blocker;
   end Is_Dependency_Blocker;

   function Is_Effect_Blocker (Status : Overload_Shared_State_Status) return Boolean is
   begin
      return Status in
        Overload_Shared_State_Volatile_Effect_Blocker |
        Overload_Shared_State_Atomic_Effect_Blocker |
        Overload_Shared_State_Shared_Variable_Effect_Blocker |
        Overload_Shared_State_Protected_Effect_Blocker |
        Overload_Shared_State_Dispatching_Effect_Mismatch |
        Overload_Shared_State_Access_Subprogram_Effect_Mismatch |
        Overload_Shared_State_Generic_Formal_Effect_Mismatch |
        Overload_Shared_State_Renamed_Primitive_Effect_Mismatch;
   end Is_Effect_Blocker;

   function Is_Ambiguous (Status : Overload_Shared_State_Status) return Boolean is
   begin
      return Status = Overload_Shared_State_Final_RM_Ambiguous
        or else Status = Overload_Shared_State_Universal_Numeric_State_Ambiguous;
   end Is_Ambiguous;

   function Has_Error (Info : Overload_Shared_State_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status)
        and then Info.Status /= Overload_Shared_State_Not_Checked;
   end Has_Error;

   function Legal_Status_For
     (Kind : Overload_Shared_State_Context_Kind) return Overload_Shared_State_Status is
   begin
      case Kind is
         when Overload_Shared_State_Prefixed_Call =>
            return Overload_Shared_State_Legal_Prefixed_Call_Accepted;
         when Overload_Shared_State_Dispatching_Call =>
            return Overload_Shared_State_Legal_Dispatching_Call_Accepted;
         when Overload_Shared_State_Access_Subprogram_Call =>
            return Overload_Shared_State_Legal_Access_Subprogram_Call_Accepted;
         when Overload_Shared_State_Class_Wide_Controlling_Result =>
            return Overload_Shared_State_Legal_Class_Wide_Result_Accepted;
         when Overload_Shared_State_Inherited_Primitive =>
            return Overload_Shared_State_Legal_Inherited_Primitive_Accepted;
         when Overload_Shared_State_Generic_Formal_Subprogram =>
            return Overload_Shared_State_Legal_Generic_Formal_Subprogram_Accepted;
         when Overload_Shared_State_Universal_Numeric_Operator =>
            return Overload_Shared_State_Legal_Universal_Numeric_Operator_Accepted;
         when Overload_Shared_State_Renamed_Primitive =>
            return Overload_Shared_State_Legal_Renamed_Primitive_Accepted;
         when Overload_Shared_State_Abstract_State_Effect =>
            return Overload_Shared_State_Legal_Abstract_State_Effect_Accepted;
         when Overload_Shared_State_Volatile_Atomic_Effect =>
            return Overload_Shared_State_Legal_Volatile_Atomic_Effect_Accepted;
         when Overload_Shared_State_Unknown =>
            return Overload_Shared_State_Indeterminate;
      end case;
   end Legal_Status_For;

   function Local_Blocker_Count (C : Overload_Shared_State_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if C.Volatile_Effect_Blocker then Count := Count + 1; end if;
      if C.Atomic_Effect_Blocker then Count := Count + 1; end if;
      if C.Shared_Variable_Blocker then Count := Count + 1; end if;
      if C.Protected_Effect_Blocker then Count := Count + 1; end if;
      if C.Dispatching_Effect_Mismatch then Count := Count + 1; end if;
      if C.Access_Subprogram_Effect_Mismatch then Count := Count + 1; end if;
      if C.Generic_Formal_Effect_Mismatch then Count := Count + 1; end if;
      if C.Renamed_Primitive_Effect_Mismatch then Count := Count + 1; end if;
      if C.Universal_Numeric_State_Ambiguous then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Overload_Shared_State_Context_Info) return Overload_Shared_State_Status is
      Local : constant Natural := Local_Blocker_Count (C);
   begin
      if Local > 1 then
         return Overload_Shared_State_Multiple_Blockers;
      elsif C.Volatile_Effect_Blocker then
         return Overload_Shared_State_Volatile_Effect_Blocker;
      elsif C.Atomic_Effect_Blocker then
         return Overload_Shared_State_Atomic_Effect_Blocker;
      elsif C.Shared_Variable_Blocker then
         return Overload_Shared_State_Shared_Variable_Effect_Blocker;
      elsif C.Protected_Effect_Blocker then
         return Overload_Shared_State_Protected_Effect_Blocker;
      elsif C.Dispatching_Effect_Mismatch then
         return Overload_Shared_State_Dispatching_Effect_Mismatch;
      elsif C.Access_Subprogram_Effect_Mismatch then
         return Overload_Shared_State_Access_Subprogram_Effect_Mismatch;
      elsif C.Generic_Formal_Effect_Mismatch then
         return Overload_Shared_State_Generic_Formal_Effect_Mismatch;
      elsif C.Renamed_Primitive_Effect_Mismatch then
         return Overload_Shared_State_Renamed_Primitive_Effect_Mismatch;
      elsif C.Universal_Numeric_State_Ambiguous then
         return Overload_Shared_State_Universal_Numeric_State_Ambiguous;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Overload_Shared_State_Source_Fingerprint_Mismatch;
      elsif C.Requires_Final_RM and then C.Final_RM_Status = Final_RM.Final_RM_Not_Checked then
         return Overload_Shared_State_Missing_Final_RM_Row;
      elsif C.Requires_Final_RM and then Final_RM.Is_Ambiguous (C.Final_RM_Status) then
         return Overload_Shared_State_Final_RM_Ambiguous;
      elsif C.Requires_Final_RM and then not Closure_Final_RM_Legal (C.Final_RM_Status) then
         return Overload_Shared_State_Final_RM_Blocker;
      elsif C.Requires_Shared_State and then C.Shared_State_Status = Shared_State.Shared_State_Not_Checked then
         return Overload_Shared_State_Missing_Shared_State_Row;
      elsif C.Requires_Shared_State and then not Shared_Legal (C.Shared_State_Status) then
         return Overload_Shared_State_Shared_State_Blocker;
      elsif C.Requires_Abstract_State and then C.Abstract_State_Status = Abstract_States.Abstract_State_Not_Checked then
         return Overload_Shared_State_Missing_Abstract_State_Row;
      elsif C.Requires_Abstract_State and then not Abstract_Legal (C.Abstract_State_Status) then
         return Overload_Shared_State_Abstract_State_Blocker;
      else
         return Legal_Status_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Overload_Shared_State_Status;
      Kind   : Overload_Shared_State_Context_Kind) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("overload shared-state RM edge legality " &
         Overload_Shared_State_Status'Image (Status) &
         " kind=" & Overload_Shared_State_Context_Kind'Image (Kind));
   end Message_For;

   function Row_Fingerprint (Row : Overload_Shared_State_Info) return Natural is
      Text : constant String := To_String (Row.Message) & To_String (Row.Detail);
      H    : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Overload_Shared_State_Context_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Overload_Shared_State_Status'Pos (Row.Status) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      for Ch of Text loop
         H := Mix (H, Character'Pos (Ch));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (C     : Overload_Shared_State_Context_Info;
      Index : Positive) return Overload_Shared_State_Info is
      Status : constant Overload_Shared_State_Status := Classify (C);
      Row    : Overload_Shared_State_Info;
   begin
      Row.Id := Overload_Shared_State_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Node := C.Node;
      Row.Status := Status;
      Row.Operation_Name := C.Operation_Name;
      Row.Type_Name := C.Type_Name;
      Row.State_Name := C.State_Name;
      Row.Message := Message_For (Status, C.Kind);
      Row.Detail := To_Unbounded_String
        ("final_rm=" & Final_RM.Final_RM_Status'Image (C.Final_RM_Status) &
         " shared=" & Shared_State.Shared_State_Status'Image (C.Shared_State_Status) &
         " abstract=" & Abstract_States.Abstract_State_Status'Image (C.Abstract_State_Status));
      Row.Final_RM_Row := C.Final_RM_Row;
      Row.Final_RM_Status := C.Final_RM_Status;
      Row.Shared_State_Row := C.Shared_State_Row;
      Row.Shared_State_Status := C.Shared_State_Status;
      Row.Abstract_State_Row := C.Abstract_State_Row;
      Row.Abstract_State_Status := C.Abstract_State_Status;
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Is_Dependency_Blocker (Status) or else Is_Ambiguous (Status) then
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

   procedure Clear (Model : in out Overload_Shared_State_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Overload_Shared_State_Context_Model;
      Info  : Overload_Shared_State_Context_Info) is
      H : Natural := Model.Fingerprint;
   begin
      Model.Items.Append (Info);
      H := Mix (H, Natural (Info.Id));
      H := Mix (H, Overload_Shared_State_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Natural (Info.Node));
      H := Mix (H, Info.Source_Fingerprint);
      H := Mix (H, Info.Expected_Source_Fingerprint);
      Model.Fingerprint := H;
   end Add_Context;

   function Context_Count (Model : Overload_Shared_State_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Overload_Shared_State_Context_Model;
      Index : Positive) return Overload_Shared_State_Context_Info is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Overload_Shared_State_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Overload_Shared_State_Context_Model) return Overload_Shared_State_Model is
      Model : Overload_Shared_State_Model;
      H     : Natural := Fingerprint (Contexts);
   begin
      for Index in 1 .. Context_Count (Contexts) loop
         declare
            Row : constant Overload_Shared_State_Info := Make_Row (Context_At (Contexts, Index), Index);
         begin
            Model.Rows.Append (Row);
            H := Mix (H, Row.Fingerprint);
         end;
      end loop;
      Model.Fingerprint := H;
      return Model;
   end Build;

   function Row_Count (Model : Overload_Shared_State_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Overload_Shared_State_Model;
      Index : Positive) return Overload_Shared_State_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Overload_Shared_State_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Shared_State_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Overload_Shared_State_Model;
      Status : Overload_Shared_State_Status) return Overload_Shared_State_Set is
      Set : Overload_Shared_State_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Set.Rows.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Overload_Shared_State_Model;
      Kind  : Overload_Shared_State_Context_Kind) return Overload_Shared_State_Set is
      Set : Overload_Shared_State_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Set.Rows.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Set_Count (Set : Overload_Shared_State_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At
     (Set   : Overload_Shared_State_Set;
      Index : Positive) return Overload_Shared_State_Info is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Overload_Shared_State_Model;
      Status : Overload_Shared_State_Status) return Natural is
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
     (Model : Overload_Shared_State_Model;
      Kind  : Overload_Shared_State_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Overload_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Legal_Count;

   function Blocker_Count (Model : Overload_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Has_Error (Row) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Blocker_Count;

   function Dependency_Blocker_Count (Model : Overload_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Dependency_Blocker (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Dependency_Blocker_Count;

   function Shared_State_Blocker_Count (Model : Overload_Shared_State_Model) return Natural is
   begin
      return Count_Status (Model, Overload_Shared_State_Missing_Shared_State_Row) +
        Count_Status (Model, Overload_Shared_State_Shared_State_Blocker);
   end Shared_State_Blocker_Count;

   function Abstract_State_Blocker_Count (Model : Overload_Shared_State_Model) return Natural is
   begin
      return Count_Status (Model, Overload_Shared_State_Missing_Abstract_State_Row) +
        Count_Status (Model, Overload_Shared_State_Abstract_State_Blocker);
   end Abstract_State_Blocker_Count;

   function Effect_Blocker_Count (Model : Overload_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Effect_Blocker (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Effect_Blocker_Count;

   function Ambiguous_Count (Model : Overload_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Ambiguous (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Ambiguous_Count;

   function Indeterminate_Count (Model : Overload_Shared_State_Model) return Natural is
   begin
      return Count_Status (Model, Overload_Shared_State_Indeterminate);
   end Indeterminate_Count;

   function Fingerprint (Model : Overload_Shared_State_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Overload_Shared_State_RM_Edge_Legality;
