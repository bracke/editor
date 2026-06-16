with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Shared_State_Final_Legality is

   pragma Suppress (Overflow_Check);

   use type Abstract_States.Abstract_State_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Overload_State.Overload_Shared_State_Status;
   use type Rep_Final.Final_Representation_Status;
   use type Shared_State.Shared_State_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 131 + B * 17 + 19) mod 2_147_483_647;
   end Mix;

   function Is_Legal (Status : Representation_Shared_State_Status) return Boolean is
   begin
      return Status in
        Representation_Shared_State_Legal_Volatile_Object_Clause_Accepted |
        Representation_Shared_State_Legal_Atomic_Object_Clause_Accepted |
        Representation_Shared_State_Legal_Independent_Component_Clause_Accepted |
        Representation_Shared_State_Legal_Shared_Record_Layout_Accepted |
        Representation_Shared_State_Legal_Abstract_State_View_Accepted |
        Representation_Shared_State_Legal_Stream_Attribute_Accepted |
        Representation_Shared_State_Legal_Operational_Attribute_Accepted |
        Representation_Shared_State_Legal_Private_Full_View_Freezing_Accepted |
        Representation_Shared_State_Legal_Generic_Formal_Freezing_Accepted |
        Representation_Shared_State_Legal_Protected_Object_Representation_Accepted |
        Representation_Shared_State_Legal_Task_Object_Representation_Accepted;
   end Is_Legal;

   function Is_Dependency_Error (Status : Representation_Shared_State_Status) return Boolean is
   begin
      return Status in
        Representation_Shared_State_Missing_Final_Representation_Row |
        Representation_Shared_State_Final_Representation_Blocker |
        Representation_Shared_State_Missing_Shared_State_Row |
        Representation_Shared_State_Shared_State_Blocker |
        Representation_Shared_State_Missing_Abstract_State_Row |
        Representation_Shared_State_Abstract_State_Blocker |
        Representation_Shared_State_Missing_Overload_State_Row |
        Representation_Shared_State_Overload_State_Blocker;
   end Is_Dependency_Error;

   function Is_Shared_State_Error (Status : Representation_Shared_State_Status) return Boolean is
   begin
      return Status in
        Representation_Shared_State_Shared_State_Blocker |
        Representation_Shared_State_Abstract_State_Blocker |
        Representation_Shared_State_Overload_State_Blocker |
        Representation_Shared_State_Volatile_Representation_Blocker |
        Representation_Shared_State_Atomic_Representation_Blocker |
        Representation_Shared_State_Independent_Component_Blocker |
        Representation_Shared_State_Shared_Record_Layout_Blocker |
        Representation_Shared_State_Protected_Representation_Blocker |
        Representation_Shared_State_Task_Representation_Blocker;
   end Is_Shared_State_Error;

   function Is_Representation_Error (Status : Representation_Shared_State_Status) return Boolean is
   begin
      return Status in
        Representation_Shared_State_Final_Representation_Blocker |
        Representation_Shared_State_Volatile_Representation_Blocker |
        Representation_Shared_State_Atomic_Representation_Blocker |
        Representation_Shared_State_Independent_Component_Blocker |
        Representation_Shared_State_Shared_Record_Layout_Blocker |
        Representation_Shared_State_Stream_Attribute_Blocker |
        Representation_Shared_State_Operational_Attribute_Blocker |
        Representation_Shared_State_Private_View_Freezing_Blocker |
        Representation_Shared_State_Generic_Formal_Freezing_Blocker |
        Representation_Shared_State_Protected_Representation_Blocker |
        Representation_Shared_State_Task_Representation_Blocker;
   end Is_Representation_Error;

   function Is_Indeterminate (Status : Representation_Shared_State_Status) return Boolean is
   begin
      return Status = Representation_Shared_State_Indeterminate
        or else Status = Representation_Shared_State_Final_Representation_Indeterminate;
   end Is_Indeterminate;

   function Has_Error (Info : Representation_Shared_State_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status)
        and then Info.Status /= Representation_Shared_State_Not_Checked;
   end Has_Error;

   function Legal_Status_For
     (Kind : Representation_Shared_State_Context_Kind) return Representation_Shared_State_Status is
   begin
      case Kind is
         when Representation_Shared_State_Volatile_Object_Clause =>
            return Representation_Shared_State_Legal_Volatile_Object_Clause_Accepted;
         when Representation_Shared_State_Atomic_Object_Clause =>
            return Representation_Shared_State_Legal_Atomic_Object_Clause_Accepted;
         when Representation_Shared_State_Independent_Component_Clause =>
            return Representation_Shared_State_Legal_Independent_Component_Clause_Accepted;
         when Representation_Shared_State_Shared_Record_Layout =>
            return Representation_Shared_State_Legal_Shared_Record_Layout_Accepted;
         when Representation_Shared_State_Abstract_State_View =>
            return Representation_Shared_State_Legal_Abstract_State_View_Accepted;
         when Representation_Shared_State_Stream_Attribute =>
            return Representation_Shared_State_Legal_Stream_Attribute_Accepted;
         when Representation_Shared_State_Operational_Attribute =>
            return Representation_Shared_State_Legal_Operational_Attribute_Accepted;
         when Representation_Shared_State_Private_Full_View_Freezing =>
            return Representation_Shared_State_Legal_Private_Full_View_Freezing_Accepted;
         when Representation_Shared_State_Generic_Formal_Freezing =>
            return Representation_Shared_State_Legal_Generic_Formal_Freezing_Accepted;
         when Representation_Shared_State_Protected_Object_Representation =>
            return Representation_Shared_State_Legal_Protected_Object_Representation_Accepted;
         when Representation_Shared_State_Task_Object_Representation =>
            return Representation_Shared_State_Legal_Task_Object_Representation_Accepted;
         when Representation_Shared_State_Unknown =>
            return Representation_Shared_State_Indeterminate;
      end case;
   end Legal_Status_For;

   function Local_Blocker_Count (C : Representation_Shared_State_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if C.Volatile_Representation_Error then Count := Count + 1; end if;
      if C.Atomic_Representation_Error then Count := Count + 1; end if;
      if C.Independent_Component_Error then Count := Count + 1; end if;
      if C.Shared_Record_Layout_Error then Count := Count + 1; end if;
      if C.Stream_Attribute_Error then Count := Count + 1; end if;
      if C.Operational_Attribute_Error then Count := Count + 1; end if;
      if C.Private_View_Freezing_Error then Count := Count + 1; end if;
      if C.Generic_Formal_Freezing_Error then Count := Count + 1; end if;
      if C.Protected_Representation_Error then Count := Count + 1; end if;
      if C.Task_Representation_Error then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Representation_Shared_State_Context_Info) return Representation_Shared_State_Status is
      Local : constant Natural := Local_Blocker_Count (C);
   begin
      if Local > 1 then
         return Representation_Shared_State_Multiple_Blockers;
      elsif C.Volatile_Representation_Error then
         return Representation_Shared_State_Volatile_Representation_Blocker;
      elsif C.Atomic_Representation_Error then
         return Representation_Shared_State_Atomic_Representation_Blocker;
      elsif C.Independent_Component_Error then
         return Representation_Shared_State_Independent_Component_Blocker;
      elsif C.Shared_Record_Layout_Error then
         return Representation_Shared_State_Shared_Record_Layout_Blocker;
      elsif C.Stream_Attribute_Error then
         return Representation_Shared_State_Stream_Attribute_Blocker;
      elsif C.Operational_Attribute_Error then
         return Representation_Shared_State_Operational_Attribute_Blocker;
      elsif C.Private_View_Freezing_Error then
         return Representation_Shared_State_Private_View_Freezing_Blocker;
      elsif C.Generic_Formal_Freezing_Error then
         return Representation_Shared_State_Generic_Formal_Freezing_Blocker;
      elsif C.Protected_Representation_Error then
         return Representation_Shared_State_Protected_Representation_Blocker;
      elsif C.Task_Representation_Error then
         return Representation_Shared_State_Task_Representation_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Representation_Shared_State_Source_Fingerprint_Mismatch;
      elsif C.Requires_Final_Representation and then C.Final_Representation_Status = Rep_Final.Final_Representation_Not_Checked then
         return Representation_Shared_State_Missing_Final_Representation_Row;
      elsif C.Requires_Final_Representation and then Rep_Final.Is_Indeterminate (C.Final_Representation_Status) then
         return Representation_Shared_State_Final_Representation_Indeterminate;
      elsif C.Requires_Final_Representation and then not Rep_Final.Is_Legal (C.Final_Representation_Status) then
         return Representation_Shared_State_Final_Representation_Blocker;
      elsif C.Requires_Shared_State and then C.Shared_State_Status = Shared_State.Shared_State_Not_Checked then
         return Representation_Shared_State_Missing_Shared_State_Row;
      elsif C.Requires_Shared_State and then not Shared_State.Is_Legal (C.Shared_State_Status) then
         return Representation_Shared_State_Shared_State_Blocker;
      elsif C.Requires_Abstract_State and then C.Abstract_State_Status = Abstract_States.Abstract_State_Not_Checked then
         return Representation_Shared_State_Missing_Abstract_State_Row;
      elsif C.Requires_Abstract_State and then not Abstract_States.Is_Legal (C.Abstract_State_Status) then
         return Representation_Shared_State_Abstract_State_Blocker;
      elsif C.Requires_Overload_State and then C.Overload_State_Status = Overload_State.Overload_Shared_State_Not_Checked then
         return Representation_Shared_State_Missing_Overload_State_Row;
      elsif C.Requires_Overload_State and then not Overload_State.Is_Legal (C.Overload_State_Status) then
         return Representation_Shared_State_Overload_State_Blocker;
      else
         return Legal_Status_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Representation_Shared_State_Status;
      Kind   : Representation_Shared_State_Context_Kind) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("representation shared-state final legality " &
         Representation_Shared_State_Status'Image (Status) &
         " kind=" & Representation_Shared_State_Context_Kind'Image (Kind));
   end Message_For;

   function Row_Fingerprint (Row : Representation_Shared_State_Info) return Natural is
      Text : constant String := To_String (Row.Message) & To_String (Row.Detail);
      H    : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Representation_Shared_State_Context_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Representation_Shared_State_Status'Pos (Row.Status) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      for Ch of Text loop
         H := Mix (H, Character'Pos (Ch));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (C     : Representation_Shared_State_Context_Info;
      Index : Positive) return Representation_Shared_State_Info is
      Status : constant Representation_Shared_State_Status := Classify (C);
      Row    : Representation_Shared_State_Info;
   begin
      Row.Id := Representation_Shared_State_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Node := C.Node;
      Row.Object_Name := C.Object_Name;
      Row.State_Name := C.State_Name;
      Row.Unit_Name := C.Unit_Name;
      Row.Message := Message_For (Status, C.Kind);
      Row.Detail := To_Unbounded_String
        ("rep=" & Rep_Final.Final_Representation_Status'Image (C.Final_Representation_Status) &
         " shared=" & Shared_State.Shared_State_Status'Image (C.Shared_State_Status) &
         " abstract=" & Abstract_States.Abstract_State_Status'Image (C.Abstract_State_Status) &
         " overload=" & Overload_State.Overload_Shared_State_Status'Image (C.Overload_State_Status));
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

   procedure Clear (Model : in out Representation_Shared_State_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Representation_Shared_State_Context_Model; Info : Representation_Shared_State_Context_Info) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix
        (Model.Fingerprint,
         Natural (Info.Id) + Representation_Shared_State_Context_Kind'Pos (Info.Kind) + Natural (Info.Node) + Info.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Representation_Shared_State_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Representation_Shared_State_Context_Model; Index : Positive) return Representation_Shared_State_Context_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Representation_Shared_State_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Representation_Shared_State_Context_Model) return Representation_Shared_State_Model is
      Result : Representation_Shared_State_Model;
      Index  : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Representation_Shared_State_Info := Make_Row (C, Index);
         begin
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
            Index := Index + 1;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Representation_Shared_State_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At (Model : Representation_Shared_State_Model; Index : Positive) return Representation_Shared_State_Info is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node (Model : Representation_Shared_State_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Shared_State_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Representation_Shared_State_Model; Status : Representation_Shared_State_Status) return Representation_Shared_State_Set is
      Result : Representation_Shared_State_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Representation_Shared_State_Model; Kind : Representation_Shared_State_Context_Kind) return Representation_Shared_State_Set is
      Result : Representation_Shared_State_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Set_Count (Set : Representation_Shared_State_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At (Set : Representation_Shared_State_Set; Index : Positive) return Representation_Shared_State_Info is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status (Model : Representation_Shared_State_Model; Status : Representation_Shared_State_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Representation_Shared_State_Model; Kind : Representation_Shared_State_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Representation_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Representation_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Has_Error (Row) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Dependency_Error_Count (Model : Representation_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Dependency_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Dependency_Error_Count;

   function Shared_State_Error_Count (Model : Representation_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Shared_State_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Shared_State_Error_Count;

   function Representation_Error_Count (Model : Representation_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Representation_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Error_Count;

   function Indeterminate_Count (Model : Representation_Shared_State_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Indeterminate_Count;

   function Fingerprint (Model : Representation_Shared_State_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Representation_Shared_State_Final_Legality;
