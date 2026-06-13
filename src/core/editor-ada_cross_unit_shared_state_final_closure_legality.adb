with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality is

   use type Abstract_States.Abstract_State_Status;
   use type Cross_Unit.Cross_Unit_Final_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Overload_State.Overload_Shared_State_Status;
   use type Rep_State.Representation_Shared_State_Status;
   use type Shared_State.Shared_State_Status;
   use type Tasking_State.Tasking_Shared_State_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 131 + B * 17 + 97) mod 2_147_483_647;
   end Mix;

   function Is_Legal (Status : Cross_Unit_Shared_State_Status) return Boolean is
   begin
      return Status in
        Cross_Unit_Shared_State_Legal_Local_Accepted ..
        Cross_Unit_Shared_State_Legal_Tasking_Protected_Accepted;
   end Is_Legal;

   function Is_Dependency_Error (Status : Cross_Unit_Shared_State_Status) return Boolean is
   begin
      return Status in
        Cross_Unit_Shared_State_Missing_Cross_Unit_Row |
        Cross_Unit_Shared_State_Missing_Dependency |
        Cross_Unit_Shared_State_Ambiguous_Dependency |
        Cross_Unit_Shared_State_Dependency_Overflow |
        Cross_Unit_Shared_State_Stale_Dependency;
   end Is_Dependency_Error;

   function Is_View_Error (Status : Cross_Unit_Shared_State_Status) return Boolean is
   begin
      return Status in
        Cross_Unit_Shared_State_Limited_View_Barrier |
        Cross_Unit_Shared_State_Private_View_Barrier |
        Cross_Unit_Shared_State_Child_Visibility_Blocker |
        Cross_Unit_Shared_State_State_Visibility_Blocker;
   end Is_View_Error;

   function Is_Shared_State_Error (Status : Cross_Unit_Shared_State_Status) return Boolean is
   begin
      return Status in
        Cross_Unit_Shared_State_Missing_Abstract_State_Row |
        Cross_Unit_Shared_State_Abstract_State_Blocker |
        Cross_Unit_Shared_State_Missing_Shared_State_Row |
        Cross_Unit_Shared_State_Shared_State_Blocker |
        Cross_Unit_Shared_State_Missing_Overload_State_Row |
        Cross_Unit_Shared_State_Overload_State_Blocker |
        Cross_Unit_Shared_State_Abstract_Constituent_Blocker |
        Cross_Unit_Shared_State_Volatile_Atomic_Order_Blocker |
        Cross_Unit_Shared_State_Shared_Variable_Blocker;
   end Is_Shared_State_Error;

   function Is_Representation_Error (Status : Cross_Unit_Shared_State_Status) return Boolean is
   begin
      return Status in
        Cross_Unit_Shared_State_Missing_Representation_State_Row |
        Cross_Unit_Shared_State_Representation_State_Blocker |
        Cross_Unit_Shared_State_Representation_Effect_Blocker;
   end Is_Representation_Error;

   function Is_Tasking_Error (Status : Cross_Unit_Shared_State_Status) return Boolean is
   begin
      return Status in
        Cross_Unit_Shared_State_Missing_Tasking_State_Row |
        Cross_Unit_Shared_State_Tasking_State_Blocker |
        Cross_Unit_Shared_State_Tasking_Effect_Blocker;
   end Is_Tasking_Error;

   function Is_Indeterminate (Status : Cross_Unit_Shared_State_Status) return Boolean is
   begin
      return Status = Cross_Unit_Shared_State_Indeterminate;
   end Is_Indeterminate;

   function Has_Error (Info : Cross_Unit_Shared_State_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status);
   end Has_Error;

   function Context_Fingerprint (Info : Cross_Unit_Shared_State_Context_Info) return Natural is
      H : Natural := Natural (Info.Id);
   begin
      H := Mix (H, Cross_Unit_Shared_State_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Cross_Unit_Shared_State_Dependency_State'Pos (Info.Dependency) + 1);
      H := Mix (H, Natural (Info.Node));
      H := Mix (H, Natural (Info.Cross_Unit_Row));
      H := Mix (H, Cross_Unit.Cross_Unit_Final_Status'Pos (Info.Cross_Unit_Status) + 1);
      H := Mix (H, Natural (Info.Abstract_State_Row));
      H := Mix (H, Abstract_States.Abstract_State_Status'Pos (Info.Abstract_State_Status) + 1);
      H := Mix (H, Natural (Info.Shared_State_Row));
      H := Mix (H, Shared_State.Shared_State_Status'Pos (Info.Shared_State_Status) + 1);
      H := Mix (H, Natural (Info.Overload_State_Row));
      H := Mix (H, Overload_State.Overload_Shared_State_Status'Pos (Info.Overload_State_Status) + 1);
      H := Mix (H, Natural (Info.Representation_State_Row));
      H := Mix (H, Rep_State.Representation_Shared_State_Status'Pos (Info.Representation_State_Status) + 1);
      H := Mix (H, Natural (Info.Tasking_State_Row));
      H := Mix (H, Tasking_State.Tasking_Shared_State_Status'Pos (Info.Tasking_State_Status) + 1);
      H := Mix (H, Info.Source_Fingerprint);
      H := Mix (H, Info.Expected_Source_Fingerprint);
      return H;
   end Context_Fingerprint;

   procedure Clear (Model : in out Cross_Unit_Shared_State_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Cross_Unit_Shared_State_Context_Model;
      Info  : Cross_Unit_Shared_State_Context_Info) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Context_Fingerprint (Info));
   end Add_Context;

   function Context_Count (Model : Cross_Unit_Shared_State_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Cross_Unit_Shared_State_Context_Model;
      Index : Positive) return Cross_Unit_Shared_State_Context_Info is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Cross_Unit_Shared_State_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Legal_Status_For
     (Kind : Cross_Unit_Shared_State_Context_Kind) return Cross_Unit_Shared_State_Status is
   begin
      case Kind is
         when Cross_Unit_Shared_State_Local =>
            return Cross_Unit_Shared_State_Legal_Local_Accepted;
         when Cross_Unit_Shared_State_With_Use =>
            return Cross_Unit_Shared_State_Legal_With_Use_Accepted;
         when Cross_Unit_Shared_State_Private_Full_View =>
            return Cross_Unit_Shared_State_Legal_Private_Full_View_Accepted;
         when Cross_Unit_Shared_State_Limited_View =>
            return Cross_Unit_Shared_State_Legal_Limited_View_Accepted;
         when Cross_Unit_Shared_State_Child_Private_Child =>
            return Cross_Unit_Shared_State_Legal_Child_Private_Child_Accepted;
         when Cross_Unit_Shared_State_Generic_Instance =>
            return Cross_Unit_Shared_State_Legal_Generic_Instance_Accepted;
         when Cross_Unit_Shared_State_Abstract_State =>
            return Cross_Unit_Shared_State_Legal_Abstract_State_Accepted;
         when Cross_Unit_Shared_State_Volatile_Atomic =>
            return Cross_Unit_Shared_State_Legal_Volatile_Atomic_Accepted;
         when Cross_Unit_Shared_State_Overload_Type =>
            return Cross_Unit_Shared_State_Legal_Overload_Type_Accepted;
         when Cross_Unit_Shared_State_Representation =>
            return Cross_Unit_Shared_State_Legal_Representation_Accepted;
         when Cross_Unit_Shared_State_Tasking_Protected =>
            return Cross_Unit_Shared_State_Legal_Tasking_Protected_Accepted;
         when Cross_Unit_Shared_State_Unknown =>
            return Cross_Unit_Shared_State_Indeterminate;
      end case;
   end Legal_Status_For;

   function Dependency_Status_For
     (Dependency : Cross_Unit_Shared_State_Dependency_State) return Cross_Unit_Shared_State_Status is
   begin
      case Dependency is
         when Shared_Dependency_Missing =>
            return Cross_Unit_Shared_State_Missing_Dependency;
         when Shared_Dependency_Ambiguous =>
            return Cross_Unit_Shared_State_Ambiguous_Dependency;
         when Shared_Dependency_Overflow =>
            return Cross_Unit_Shared_State_Dependency_Overflow;
         when Shared_Dependency_Stale =>
            return Cross_Unit_Shared_State_Stale_Dependency;
         when others =>
            return Cross_Unit_Shared_State_Not_Checked;
      end case;
   end Dependency_Status_For;

   function Explicit_Blocker_Count (C : Cross_Unit_Shared_State_Context_Info) return Natural is
      N : Natural := 0;
   begin
      if C.Limited_View_Barrier then N := N + 1; end if;
      if C.Private_View_Barrier then N := N + 1; end if;
      if C.Child_Visibility_Blocker then N := N + 1; end if;
      if C.Generic_Body_Unavailable then N := N + 1; end if;
      if C.Generic_Backmapping_Blocker then N := N + 1; end if;
      if C.State_Visibility_Blocker then N := N + 1; end if;
      if C.Abstract_Constituent_Blocker then N := N + 1; end if;
      if C.Volatile_Atomic_Order_Blocker then N := N + 1; end if;
      if C.Shared_Variable_Blocker then N := N + 1; end if;
      if C.Representation_Effect_Blocker then N := N + 1; end if;
      if C.Tasking_Effect_Blocker then N := N + 1; end if;
      return N;
   end Explicit_Blocker_Count;

   function Classify (C : Cross_Unit_Shared_State_Context_Info) return Cross_Unit_Shared_State_Status is
      Dependency_Status : constant Cross_Unit_Shared_State_Status := Dependency_Status_For (C.Dependency);
      Explicit_Count : constant Natural := Explicit_Blocker_Count (C);
   begin
      if Explicit_Count > 1 then
         return Cross_Unit_Shared_State_Multiple_Blockers;
      elsif Dependency_Status /= Cross_Unit_Shared_State_Not_Checked then
         return Dependency_Status;
      elsif C.Limited_View_Barrier then
         return Cross_Unit_Shared_State_Limited_View_Barrier;
      elsif C.Private_View_Barrier then
         return Cross_Unit_Shared_State_Private_View_Barrier;
      elsif C.Child_Visibility_Blocker then
         return Cross_Unit_Shared_State_Child_Visibility_Blocker;
      elsif C.Generic_Body_Unavailable then
         return Cross_Unit_Shared_State_Generic_Body_Unavailable;
      elsif C.Generic_Backmapping_Blocker then
         return Cross_Unit_Shared_State_Generic_Backmapping_Blocker;
      elsif C.State_Visibility_Blocker then
         return Cross_Unit_Shared_State_State_Visibility_Blocker;
      elsif C.Abstract_Constituent_Blocker then
         return Cross_Unit_Shared_State_Abstract_Constituent_Blocker;
      elsif C.Volatile_Atomic_Order_Blocker then
         return Cross_Unit_Shared_State_Volatile_Atomic_Order_Blocker;
      elsif C.Shared_Variable_Blocker then
         return Cross_Unit_Shared_State_Shared_Variable_Blocker;
      elsif C.Representation_Effect_Blocker then
         return Cross_Unit_Shared_State_Representation_Effect_Blocker;
      elsif C.Tasking_Effect_Blocker then
         return Cross_Unit_Shared_State_Tasking_Effect_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Cross_Unit_Shared_State_Source_Fingerprint_Mismatch;
      elsif C.Requires_Cross_Unit and then C.Cross_Unit_Status = Cross_Unit.Cross_Unit_Final_Not_Checked then
         return Cross_Unit_Shared_State_Missing_Cross_Unit_Row;
      elsif C.Requires_Cross_Unit and then not Cross_Unit.Is_Legal (C.Cross_Unit_Status) then
         return Cross_Unit_Shared_State_Cross_Unit_Blocker;
      elsif C.Requires_Abstract_State and then C.Abstract_State_Status = Abstract_States.Abstract_State_Not_Checked then
         return Cross_Unit_Shared_State_Missing_Abstract_State_Row;
      elsif C.Requires_Abstract_State and then not Abstract_States.Is_Legal (C.Abstract_State_Status) then
         return Cross_Unit_Shared_State_Abstract_State_Blocker;
      elsif C.Requires_Shared_State and then C.Shared_State_Status = Shared_State.Shared_State_Not_Checked then
         return Cross_Unit_Shared_State_Missing_Shared_State_Row;
      elsif C.Requires_Shared_State and then not Shared_State.Is_Legal (C.Shared_State_Status) then
         return Cross_Unit_Shared_State_Shared_State_Blocker;
      elsif C.Requires_Overload_State and then C.Overload_State_Status = Overload_State.Overload_Shared_State_Not_Checked then
         return Cross_Unit_Shared_State_Missing_Overload_State_Row;
      elsif C.Requires_Overload_State and then not Overload_State.Is_Legal (C.Overload_State_Status) then
         return Cross_Unit_Shared_State_Overload_State_Blocker;
      elsif C.Requires_Representation_State and then C.Representation_State_Status = Rep_State.Representation_Shared_State_Not_Checked then
         return Cross_Unit_Shared_State_Missing_Representation_State_Row;
      elsif C.Requires_Representation_State and then not Rep_State.Is_Legal (C.Representation_State_Status) then
         return Cross_Unit_Shared_State_Representation_State_Blocker;
      elsif C.Requires_Tasking_State and then C.Tasking_State_Status = Tasking_State.Tasking_Shared_State_Not_Checked then
         return Cross_Unit_Shared_State_Missing_Tasking_State_Row;
      elsif C.Requires_Tasking_State and then not Tasking_State.Is_Legal (C.Tasking_State_Status) then
         return Cross_Unit_Shared_State_Tasking_State_Blocker;
      else
         return Legal_Status_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Cross_Unit_Shared_State_Status;
      Kind   : Cross_Unit_Shared_State_Context_Kind) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("cross-unit shared-state final closure legality " &
         Cross_Unit_Shared_State_Status'Image (Status) &
         " kind=" & Cross_Unit_Shared_State_Context_Kind'Image (Kind));
   end Message_For;

   function Row_Fingerprint (Row : Cross_Unit_Shared_State_Info) return Natural is
      Text : constant String := To_String (Row.Message) & To_String (Row.Detail);
      H    : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Cross_Unit_Shared_State_Context_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Cross_Unit_Shared_State_Dependency_State'Pos (Row.Dependency) + 1);
      H := Mix (H, Cross_Unit_Shared_State_Status'Pos (Row.Status) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      for Ch of Text loop
         H := Mix (H, Character'Pos (Ch));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (C     : Cross_Unit_Shared_State_Context_Info;
      Index : Positive) return Cross_Unit_Shared_State_Info is
      Status : constant Cross_Unit_Shared_State_Status := Classify (C);
      Row    : Cross_Unit_Shared_State_Info;
   begin
      Row.Id := Cross_Unit_Shared_State_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Dependency := C.Dependency;
      Row.Status := Status;
      Row.Node := C.Node;
      Row.Unit_Name := C.Unit_Name;
      Row.Dependency_Name := C.Dependency_Name;
      Row.State_Name := C.State_Name;
      Row.Message := Message_For (Status, C.Kind);
      Row.Detail := To_Unbounded_String
        ("cross=" & Cross_Unit.Cross_Unit_Final_Status'Image (C.Cross_Unit_Status) &
         " abstract=" & Abstract_States.Abstract_State_Status'Image (C.Abstract_State_Status) &
         " shared=" & Shared_State.Shared_State_Status'Image (C.Shared_State_Status) &
         " overload=" & Overload_State.Overload_Shared_State_Status'Image (C.Overload_State_Status) &
         " representation=" & Rep_State.Representation_Shared_State_Status'Image (C.Representation_State_Status) &
         " tasking=" & Tasking_State.Tasking_Shared_State_Status'Image (C.Tasking_State_Status));
      Row.Blocker_Count := Explicit_Blocker_Count (C);
      if not Is_Legal (Status) and then Row.Blocker_Count = 0 then
         Row.Blocker_Count := 1;
      end if;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   function Build (Contexts : Cross_Unit_Shared_State_Context_Model) return Cross_Unit_Shared_State_Model is
      Result : Cross_Unit_Shared_State_Model;
      Index  : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Cross_Unit_Shared_State_Info := Make_Row (C, Index);
         begin
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
            Index := Index + 1;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Cross_Unit_Shared_State_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Cross_Unit_Shared_State_Model;
      Index : Positive) return Cross_Unit_Shared_State_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Cross_Unit_Shared_State_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_Shared_State_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Cross_Unit_Shared_State_Model;
      Status : Cross_Unit_Shared_State_Status) return Cross_Unit_Shared_State_Set is
      Result : Cross_Unit_Shared_State_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Cross_Unit_Shared_State_Model;
      Kind  : Cross_Unit_Shared_State_Context_Kind) return Cross_Unit_Shared_State_Set is
      Result : Cross_Unit_Shared_State_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Set_Count (Set : Cross_Unit_Shared_State_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At
     (Set   : Cross_Unit_Shared_State_Set;
      Index : Positive) return Cross_Unit_Shared_State_Info is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Cross_Unit_Shared_State_Model;
      Status : Cross_Unit_Shared_State_Status) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Status;

   function Count_Kind
     (Model : Cross_Unit_Shared_State_Model;
      Kind  : Cross_Unit_Shared_State_Context_Kind) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Kind;

   function Legal_Count (Model : Cross_Unit_Shared_State_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Legal_Count;

   function Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural is
   begin
      return Row_Count (Model) - Legal_Count (Model);
   end Error_Count;

   function Dependency_Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Dependency_Error (Row.Status) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Dependency_Error_Count;

   function View_Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_View_Error (Row.Status) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end View_Error_Count;

   function Shared_State_Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Shared_State_Error (Row.Status) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Shared_State_Error_Count;

   function Representation_Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Representation_Error (Row.Status) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Representation_Error_Count;

   function Tasking_Error_Count (Model : Cross_Unit_Shared_State_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Tasking_Error (Row.Status) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Tasking_Error_Count;

   function Indeterminate_Count (Model : Cross_Unit_Shared_State_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Indeterminate_Count;

   function Fingerprint (Model : Cross_Unit_Shared_State_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality;
