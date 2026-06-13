with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality is

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 12_225) mod 2_147_483_647;
   end Mix;

   function Is_Accepted (Status : Volatile_Atomic_Representation_Status) return Boolean is
   begin
      return Status in Volatile_Atomic_Representation_Legal_Volatile_Full_Access_Accepted |
                       Volatile_Atomic_Representation_Legal_Atomic_Object_Clause_Accepted |
                       Volatile_Atomic_Representation_Legal_Atomic_Record_Component_Accepted |
                       Volatile_Atomic_Representation_Legal_Independent_Component_Accepted |
                       Volatile_Atomic_Representation_Legal_Record_Layout_Accepted |
                       Volatile_Atomic_Representation_Legal_Representation_Clause_Accepted |
                       Volatile_Atomic_Representation_Legal_Stream_Attribute_Accepted |
                       Volatile_Atomic_Representation_Legal_Operational_Attribute_Accepted |
                       Volatile_Atomic_Representation_Legal_Protected_Shared_Object_Accepted |
                       Volatile_Atomic_Representation_Legal_Task_Shared_Object_Accepted |
                       Volatile_Atomic_Representation_Legal_Shared_Passive_Package_Accepted;
   end Is_Accepted;

   function Is_Blocked (Status : Volatile_Atomic_Representation_Status) return Boolean is
   begin
      return Status in Volatile_Atomic_Representation_Missing_Shared_State_Row |
                       Volatile_Atomic_Representation_Shared_State_Blocker |
                       Volatile_Atomic_Representation_Missing_Representation_Row |
                       Volatile_Atomic_Representation_Representation_Blocker |
                       Volatile_Atomic_Representation_Missing_Abstract_Consumer_Row |
                       Volatile_Atomic_Representation_Abstract_Consumer_Blocker |
                       Volatile_Atomic_Representation_Missing_Stabilized_Closure_Row |
                       Volatile_Atomic_Representation_Stabilized_Closure_Blocker |
                       Volatile_Atomic_Representation_Volatile_Full_Access_Blocker |
                       Volatile_Atomic_Representation_Atomic_Component_Blocker |
                       Volatile_Atomic_Representation_Atomic_Alignment_Blocker |
                       Volatile_Atomic_Representation_Atomic_Record_Component_Blocker |
                       Volatile_Atomic_Representation_Independent_Component_Overlap |
                       Volatile_Atomic_Representation_Representation_Clause_Blocker |
                       Volatile_Atomic_Representation_Record_Layout_Blocker |
                       Volatile_Atomic_Representation_Stream_Attribute_Blocker |
                       Volatile_Atomic_Representation_Operational_Attribute_Blocker |
                       Volatile_Atomic_Representation_Protected_Shared_Object_Blocker |
                       Volatile_Atomic_Representation_Task_Shared_Object_Blocker |
                       Volatile_Atomic_Representation_Shared_Passive_Blocker |
                       Volatile_Atomic_Representation_Source_Fingerprint_Mismatch |
                       Volatile_Atomic_Representation_Multiple_Blockers;
   end Is_Blocked;

   function Is_Indeterminate (Status : Volatile_Atomic_Representation_Status) return Boolean is
   begin
      return Status = Volatile_Atomic_Representation_Indeterminate;
   end Is_Indeterminate;

   function Closure_Accepted
     (Status : Closure.Shared_State_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current
        or else Status = Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Accepted_For
     (Kind : Volatile_Atomic_Representation_Kind) return Volatile_Atomic_Representation_Status is
   begin
      case Kind is
         when Volatile_Atomic_Representation_Volatile_Full_Access_Object =>
            return Volatile_Atomic_Representation_Legal_Volatile_Full_Access_Accepted;
         when Volatile_Atomic_Representation_Atomic_Object_Clause =>
            return Volatile_Atomic_Representation_Legal_Atomic_Object_Clause_Accepted;
         when Volatile_Atomic_Representation_Atomic_Record_Component =>
            return Volatile_Atomic_Representation_Legal_Atomic_Record_Component_Accepted;
         when Volatile_Atomic_Representation_Independent_Component_Clause =>
            return Volatile_Atomic_Representation_Legal_Independent_Component_Accepted;
         when Volatile_Atomic_Representation_Record_Layout =>
            return Volatile_Atomic_Representation_Legal_Record_Layout_Accepted;
         when Volatile_Atomic_Representation_Representation_Clause =>
            return Volatile_Atomic_Representation_Legal_Representation_Clause_Accepted;
         when Volatile_Atomic_Representation_Stream_Attribute =>
            return Volatile_Atomic_Representation_Legal_Stream_Attribute_Accepted;
         when Volatile_Atomic_Representation_Operational_Attribute =>
            return Volatile_Atomic_Representation_Legal_Operational_Attribute_Accepted;
         when Volatile_Atomic_Representation_Protected_Shared_Object =>
            return Volatile_Atomic_Representation_Legal_Protected_Shared_Object_Accepted;
         when Volatile_Atomic_Representation_Task_Shared_Object =>
            return Volatile_Atomic_Representation_Legal_Task_Shared_Object_Accepted;
         when Volatile_Atomic_Representation_Shared_Passive_Package =>
            return Volatile_Atomic_Representation_Legal_Shared_Passive_Package_Accepted;
         when Volatile_Atomic_Representation_Unknown =>
            return Volatile_Atomic_Representation_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For
     (Status : Volatile_Atomic_Representation_Status) return Volatile_Atomic_Representation_Blocker_Family is
   begin
      case Status is
         when Volatile_Atomic_Representation_Missing_Shared_State_Row |
              Volatile_Atomic_Representation_Shared_State_Blocker =>
            return Volatile_Atomic_Representation_Blocker_Volatile_Atomic_Shared_State;
         when Volatile_Atomic_Representation_Missing_Representation_Row |
              Volatile_Atomic_Representation_Representation_Blocker |
              Volatile_Atomic_Representation_Representation_Clause_Blocker |
              Volatile_Atomic_Representation_Record_Layout_Blocker =>
            return Volatile_Atomic_Representation_Blocker_Representation_Freezing;
         when Volatile_Atomic_Representation_Missing_Abstract_Consumer_Row |
              Volatile_Atomic_Representation_Abstract_Consumer_Blocker =>
            return Volatile_Atomic_Representation_Blocker_Abstract_State_Consumer;
         when Volatile_Atomic_Representation_Missing_Stabilized_Closure_Row |
              Volatile_Atomic_Representation_Stabilized_Closure_Blocker =>
            return Volatile_Atomic_Representation_Blocker_Stabilized_Closure;
         when Volatile_Atomic_Representation_Volatile_Full_Access_Blocker =>
            return Volatile_Atomic_Representation_Blocker_Volatile_Full_Access;
         when Volatile_Atomic_Representation_Atomic_Component_Blocker |
              Volatile_Atomic_Representation_Atomic_Alignment_Blocker |
              Volatile_Atomic_Representation_Atomic_Record_Component_Blocker =>
            return Volatile_Atomic_Representation_Blocker_Atomic_Component;
         when Volatile_Atomic_Representation_Independent_Component_Overlap =>
            return Volatile_Atomic_Representation_Blocker_Independent_Component;
         when Volatile_Atomic_Representation_Stream_Attribute_Blocker =>
            return Volatile_Atomic_Representation_Blocker_Stream_Attribute;
         when Volatile_Atomic_Representation_Operational_Attribute_Blocker =>
            return Volatile_Atomic_Representation_Blocker_Operational_Attribute;
         when Volatile_Atomic_Representation_Protected_Shared_Object_Blocker |
              Volatile_Atomic_Representation_Task_Shared_Object_Blocker |
              Volatile_Atomic_Representation_Shared_Passive_Blocker =>
            return Volatile_Atomic_Representation_Blocker_Protected_Tasking;
         when Volatile_Atomic_Representation_Source_Fingerprint_Mismatch =>
            return Volatile_Atomic_Representation_Blocker_Source_Fingerprint;
         when Volatile_Atomic_Representation_Multiple_Blockers =>
            return Volatile_Atomic_Representation_Blocker_Multiple;
         when Volatile_Atomic_Representation_Indeterminate =>
            return Volatile_Atomic_Representation_Blocker_Indeterminate;
         when others =>
            return Volatile_Atomic_Representation_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Volatile_Atomic_Representation_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Volatile_Full_Access_Error then Count := Count + 1; end if;
      if C.Atomic_Component_Error then Count := Count + 1; end if;
      if C.Atomic_Alignment_Error then Count := Count + 1; end if;
      if C.Atomic_Record_Component_Error then Count := Count + 1; end if;
      if C.Independent_Component_Overlap then Count := Count + 1; end if;
      if C.Representation_Clause_Error then Count := Count + 1; end if;
      if C.Record_Layout_Error then Count := Count + 1; end if;
      if C.Stream_Attribute_Error then Count := Count + 1; end if;
      if C.Operational_Attribute_Error then Count := Count + 1; end if;
      if C.Protected_Shared_Object_Error then Count := Count + 1; end if;
      if C.Task_Shared_Object_Error then Count := Count + 1; end if;
      if C.Shared_Passive_Error then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify
     (C : Volatile_Atomic_Representation_Context) return Volatile_Atomic_Representation_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Volatile_Atomic_Representation_Multiple_Blockers;
      elsif C.Volatile_Full_Access_Error then
         return Volatile_Atomic_Representation_Volatile_Full_Access_Blocker;
      elsif C.Atomic_Component_Error then
         return Volatile_Atomic_Representation_Atomic_Component_Blocker;
      elsif C.Atomic_Alignment_Error then
         return Volatile_Atomic_Representation_Atomic_Alignment_Blocker;
      elsif C.Atomic_Record_Component_Error then
         return Volatile_Atomic_Representation_Atomic_Record_Component_Blocker;
      elsif C.Independent_Component_Overlap then
         return Volatile_Atomic_Representation_Independent_Component_Overlap;
      elsif C.Representation_Clause_Error then
         return Volatile_Atomic_Representation_Representation_Clause_Blocker;
      elsif C.Record_Layout_Error then
         return Volatile_Atomic_Representation_Record_Layout_Blocker;
      elsif C.Stream_Attribute_Error then
         return Volatile_Atomic_Representation_Stream_Attribute_Blocker;
      elsif C.Operational_Attribute_Error then
         return Volatile_Atomic_Representation_Operational_Attribute_Blocker;
      elsif C.Protected_Shared_Object_Error then
         return Volatile_Atomic_Representation_Protected_Shared_Object_Blocker;
      elsif C.Task_Shared_Object_Error then
         return Volatile_Atomic_Representation_Task_Shared_Object_Blocker;
      elsif C.Shared_Passive_Error then
         return Volatile_Atomic_Representation_Shared_Passive_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Volatile_Atomic_Representation_Source_Fingerprint_Mismatch;
      elsif C.Requires_Shared_State and then C.Shared_State_Row = Shared.No_Shared_State_Row then
         return Volatile_Atomic_Representation_Missing_Shared_State_Row;
      elsif C.Requires_Shared_State and then not Shared.Is_Legal (C.Shared_State_Status) then
         return Volatile_Atomic_Representation_Shared_State_Blocker;
      elsif C.Requires_Representation and then C.Representation_Row = Rep.No_Representation_Shared_State_Row then
         return Volatile_Atomic_Representation_Missing_Representation_Row;
      elsif C.Requires_Representation and then not Rep.Is_Legal (C.Representation_Status) then
         return Volatile_Atomic_Representation_Representation_Blocker;
      elsif C.Requires_Abstract_Consumer and then C.Abstract_Consumer_Row = Abstract_Consumers.No_Abstract_State_Consumer_Row then
         return Volatile_Atomic_Representation_Missing_Abstract_Consumer_Row;
      elsif C.Requires_Abstract_Consumer and then not Abstract_Consumers.Is_Accepted (C.Abstract_Consumer_Status) then
         return Volatile_Atomic_Representation_Abstract_Consumer_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then
         return Volatile_Atomic_Representation_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Volatile_Atomic_Representation_Stabilized_Closure_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Volatile_Atomic_Representation_Status;
      Kind   : Volatile_Atomic_Representation_Kind;
      Family : Volatile_Atomic_Representation_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("volatile/atomic representation consumer " &
         Volatile_Atomic_Representation_Status'Image (Status) &
         " kind=" & Volatile_Atomic_Representation_Kind'Image (Kind) &
         " blocker=" & Volatile_Atomic_Representation_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Volatile_Atomic_Representation_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Volatile_Atomic_Representation_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Volatile_Atomic_Representation_Status'Pos (Row.Status) + 1);
      H := Mix (H, Volatile_Atomic_Representation_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (C     : Volatile_Atomic_Representation_Context;
      Index : Positive) return Volatile_Atomic_Representation_Row is
      Status : constant Volatile_Atomic_Representation_Status := Classify (C);
      Family : constant Volatile_Atomic_Representation_Blocker_Family := Family_For (Status);
      Row : Volatile_Atomic_Representation_Row;
   begin
      Row.Id := Volatile_Atomic_Representation_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Object_Name := C.Object_Name;
      Row.State_Name := C.State_Name;
      Row.Unit_Name := C.Unit_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Row.Blocked or else Is_Indeterminate (Status);
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Row.Blocked and then Row.Blocker_Count = 0 then
         Row.Blocker_Count := 1;
      end if;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Message := Message_For (Status, C.Kind, Family);
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out Volatile_Atomic_Representation_Model;
      Row   : Volatile_Atomic_Representation_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
      if Row.Accepted then
         Model.Accepted_Total := Model.Accepted_Total + 1;
      end if;
      if Row.Blocked then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;
      if Is_Indeterminate (Row.Status) then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Volatile_Atomic_Representation_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Volatile_Atomic_Representation_Context_Model;
      Info  : Volatile_Atomic_Representation_Context) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Volatile_Atomic_Representation_Kind'Pos (Info.Kind) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Volatile_Atomic_Representation_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Volatile_Atomic_Representation_Context_Model;
      Index : Positive) return Volatile_Atomic_Representation_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Volatile_Atomic_Representation_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Volatile_Atomic_Representation_Context_Model) return Volatile_Atomic_Representation_Model is
      Result : Volatile_Atomic_Representation_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         Add_Row (Result, Make_Row (Context_At (Contexts, I), I));
      end loop;
      return Result;
   end Build;

   function Count (Model : Volatile_Atomic_Representation_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Volatile_Atomic_Representation_Model;
      Index : Positive) return Volatile_Atomic_Representation_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   procedure Add_To_Set
     (Set : in out Volatile_Atomic_Representation_Set;
      Row : Volatile_Atomic_Representation_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
   end Add_To_Set;

   function Query_Count (Set : Volatile_Atomic_Representation_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Volatile_Atomic_Representation_Set;
      Index : Positive) return Volatile_Atomic_Representation_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Volatile_Atomic_Representation_Model;
      Status : Volatile_Atomic_Representation_Status) return Volatile_Atomic_Representation_Set is
      Result : Volatile_Atomic_Representation_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Add_To_Set (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Volatile_Atomic_Representation_Model;
      Family : Volatile_Atomic_Representation_Blocker_Family) return Volatile_Atomic_Representation_Set is
      Result : Volatile_Atomic_Representation_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Add_To_Set (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Volatile_Atomic_Representation_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Volatile_Atomic_Representation_Set is
      Result : Volatile_Atomic_Representation_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Add_To_Set (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Volatile_Atomic_Representation_Model;
      Source_Fingerprint : Natural) return Volatile_Atomic_Representation_Set is
      Result : Volatile_Atomic_Representation_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Add_To_Set (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Volatile_Atomic_Representation_Model;
      Status : Volatile_Atomic_Representation_Status) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Volatile_Atomic_Representation_Model;
      Family : Volatile_Atomic_Representation_Blocker_Family) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Volatile_Atomic_Representation_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Volatile_Atomic_Representation_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Volatile_Atomic_Representation_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Volatile_Atomic_Representation_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;
