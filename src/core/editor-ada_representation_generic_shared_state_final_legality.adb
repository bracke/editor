with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Generic_Shared_State_Final_Legality is

   pragma Suppress (Overflow_Check);
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Rep_Final.Final_Representation_Row_Id;
   use type Rep_Shared.Representation_Shared_State_Row_Id;
   use type Generic_Replay.Generic_Abstract_Replay_Row_Id;
   use type Overload_Generic.Overload_Generic_Final_Row_Id;
   use type Volatile_Rep.Volatile_Atomic_Representation_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
      Modulus : constant Natural := 2 ** 30 - 35;
   begin
      return (A * 131 + B + 19) mod Modulus;
   end Mix;

   function Closure_Accepted
     (Status : Closure.Shared_State_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current
        or else Status = Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Is_Accepted (Status : Representation_Generic_Final_Status) return Boolean is
   begin
      case Status is
         when Representation_Generic_Final_Legal_Private_Full_View_Freezing_Accepted |
              Representation_Generic_Final_Legal_Generic_Formal_Freezing_Accepted |
              Representation_Generic_Final_Legal_Generic_Instance_Representation_Accepted |
              Representation_Generic_Final_Legal_Stream_Attribute_Accepted |
              Representation_Generic_Final_Legal_Operational_Attribute_Accepted |
              Representation_Generic_Final_Legal_Variant_Record_Layout_Accepted |
              Representation_Generic_Final_Legal_Volatile_Atomic_Record_Layout_Accepted |
              Representation_Generic_Final_Legal_Independent_Component_Layout_Accepted |
              Representation_Generic_Final_Legal_Protected_Object_Representation_Accepted |
              Representation_Generic_Final_Legal_Task_Object_Representation_Accepted |
              Representation_Generic_Final_Legal_Dispatching_Representation_Effect_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Accepted;

   function Is_Indeterminate (Status : Representation_Generic_Final_Status) return Boolean is
   begin
      return Status = Representation_Generic_Final_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Representation_Generic_Final_Status) return Boolean is
   begin
      return not Is_Accepted (Status)
        and then Status /= Representation_Generic_Final_Not_Checked
        and then Status /= Representation_Generic_Final_Indeterminate;
   end Is_Blocked;

   function Accepted_For (Kind : Representation_Generic_Final_Kind) return Representation_Generic_Final_Status is
   begin
      case Kind is
         when Representation_Generic_Final_Private_Full_View_Freezing =>
            return Representation_Generic_Final_Legal_Private_Full_View_Freezing_Accepted;
         when Representation_Generic_Final_Generic_Formal_Freezing =>
            return Representation_Generic_Final_Legal_Generic_Formal_Freezing_Accepted;
         when Representation_Generic_Final_Generic_Instance_Representation =>
            return Representation_Generic_Final_Legal_Generic_Instance_Representation_Accepted;
         when Representation_Generic_Final_Stream_Attribute =>
            return Representation_Generic_Final_Legal_Stream_Attribute_Accepted;
         when Representation_Generic_Final_Operational_Attribute =>
            return Representation_Generic_Final_Legal_Operational_Attribute_Accepted;
         when Representation_Generic_Final_Variant_Record_Layout =>
            return Representation_Generic_Final_Legal_Variant_Record_Layout_Accepted;
         when Representation_Generic_Final_Volatile_Atomic_Record_Layout =>
            return Representation_Generic_Final_Legal_Volatile_Atomic_Record_Layout_Accepted;
         when Representation_Generic_Final_Independent_Component_Layout =>
            return Representation_Generic_Final_Legal_Independent_Component_Layout_Accepted;
         when Representation_Generic_Final_Protected_Object_Representation =>
            return Representation_Generic_Final_Legal_Protected_Object_Representation_Accepted;
         when Representation_Generic_Final_Task_Object_Representation =>
            return Representation_Generic_Final_Legal_Task_Object_Representation_Accepted;
         when Representation_Generic_Final_Dispatching_Representation_Effect =>
            return Representation_Generic_Final_Legal_Dispatching_Representation_Effect_Accepted;
         when Representation_Generic_Final_Unknown =>
            return Representation_Generic_Final_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Representation_Generic_Final_Status) return Representation_Generic_Final_Blocker_Family is
   begin
      case Status is
         when Representation_Generic_Final_Missing_Final_Representation_Row |
              Representation_Generic_Final_Final_Representation_Blocker =>
            return Representation_Generic_Final_Blocker_Final_Representation;
         when Representation_Generic_Final_Missing_Representation_Shared_State_Row |
              Representation_Generic_Final_Representation_Shared_State_Blocker =>
            return Representation_Generic_Final_Blocker_Representation_Shared_State;
         when Representation_Generic_Final_Missing_Generic_Replay_Row |
              Representation_Generic_Final_Generic_Replay_Blocker =>
            return Representation_Generic_Final_Blocker_Generic_Abstract_Replay;
         when Representation_Generic_Final_Missing_Overload_Generic_Row |
              Representation_Generic_Final_Overload_Generic_Blocker =>
            return Representation_Generic_Final_Blocker_Overload_Generic_Shared_State;
         when Representation_Generic_Final_Missing_Volatile_Representation_Row |
              Representation_Generic_Final_Volatile_Representation_Blocker =>
            return Representation_Generic_Final_Blocker_Volatile_Atomic_Representation;
         when Representation_Generic_Final_Missing_Stabilized_Closure_Row |
              Representation_Generic_Final_Stabilized_Closure_Blocker =>
            return Representation_Generic_Final_Blocker_Stabilized_Shared_State_Closure;
         when Representation_Generic_Final_Private_View_Freezing_Blocker =>
            return Representation_Generic_Final_Blocker_Private_View_Freezing;
         when Representation_Generic_Final_Generic_Formal_Freezing_Blocker =>
            return Representation_Generic_Final_Blocker_Generic_Formal_Freezing;
         when Representation_Generic_Final_Stream_Attribute_Effect_Blocker =>
            return Representation_Generic_Final_Blocker_Stream_Attribute_Effect;
         when Representation_Generic_Final_Operational_Attribute_Effect_Blocker =>
            return Representation_Generic_Final_Blocker_Operational_Attribute_Effect;
         when Representation_Generic_Final_Variant_Layout_Blocker =>
            return Representation_Generic_Final_Blocker_Variant_Layout;
         when Representation_Generic_Final_Independent_Component_Blocker =>
            return Representation_Generic_Final_Blocker_Independent_Component;
         when Representation_Generic_Final_Task_Protected_Representation_Blocker =>
            return Representation_Generic_Final_Blocker_Task_Protected_Representation;
         when Representation_Generic_Final_Source_Fingerprint_Mismatch =>
            return Representation_Generic_Final_Blocker_Source_Fingerprint;
         when Representation_Generic_Final_Substitution_Fingerprint_Mismatch =>
            return Representation_Generic_Final_Blocker_Substitution_Fingerprint;
         when Representation_Generic_Final_Multiple_Blockers =>
            return Representation_Generic_Final_Blocker_Multiple;
         when Representation_Generic_Final_Indeterminate =>
            return Representation_Generic_Final_Blocker_Indeterminate;
         when others =>
            return Representation_Generic_Final_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Representation_Generic_Final_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Private_View_Freezing_Blocker then Count := Count + 1; end if;
      if C.Generic_Formal_Freezing_Blocker then Count := Count + 1; end if;
      if C.Stream_Attribute_Effect_Blocker then Count := Count + 1; end if;
      if C.Operational_Attribute_Effect_Blocker then Count := Count + 1; end if;
      if C.Variant_Layout_Blocker then Count := Count + 1; end if;
      if C.Independent_Component_Blocker then Count := Count + 1; end if;
      if C.Task_Protected_Representation_Blocker then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Representation_Generic_Final_Context) return Representation_Generic_Final_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Representation_Generic_Final_Multiple_Blockers;
      elsif C.Private_View_Freezing_Blocker then
         return Representation_Generic_Final_Private_View_Freezing_Blocker;
      elsif C.Generic_Formal_Freezing_Blocker then
         return Representation_Generic_Final_Generic_Formal_Freezing_Blocker;
      elsif C.Stream_Attribute_Effect_Blocker then
         return Representation_Generic_Final_Stream_Attribute_Effect_Blocker;
      elsif C.Operational_Attribute_Effect_Blocker then
         return Representation_Generic_Final_Operational_Attribute_Effect_Blocker;
      elsif C.Variant_Layout_Blocker then
         return Representation_Generic_Final_Variant_Layout_Blocker;
      elsif C.Independent_Component_Blocker then
         return Representation_Generic_Final_Independent_Component_Blocker;
      elsif C.Task_Protected_Representation_Blocker then
         return Representation_Generic_Final_Task_Protected_Representation_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Representation_Generic_Final_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Representation_Generic_Final_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Final_Representation and then C.Final_Representation_Row = Rep_Final.No_Final_Representation_Row then
         return Representation_Generic_Final_Missing_Final_Representation_Row;
      elsif C.Requires_Final_Representation and then not Rep_Final.Is_Legal (C.Final_Representation_Status) then
         return Representation_Generic_Final_Final_Representation_Blocker;
      elsif C.Requires_Representation_Shared and then C.Representation_Shared_Row = Rep_Shared.No_Representation_Shared_State_Row then
         return Representation_Generic_Final_Missing_Representation_Shared_State_Row;
      elsif C.Requires_Representation_Shared and then not Rep_Shared.Is_Legal (C.Representation_Shared_Status) then
         return Representation_Generic_Final_Representation_Shared_State_Blocker;
      elsif C.Requires_Generic_Replay and then C.Generic_Replay_Row = Generic_Replay.No_Generic_Abstract_Replay_Row then
         return Representation_Generic_Final_Missing_Generic_Replay_Row;
      elsif C.Requires_Generic_Replay and then not Generic_Replay.Is_Accepted (C.Generic_Replay_Status) then
         return Representation_Generic_Final_Generic_Replay_Blocker;
      elsif C.Requires_Overload_Generic and then C.Overload_Generic_Row = Overload_Generic.No_Overload_Generic_Final_Row then
         return Representation_Generic_Final_Missing_Overload_Generic_Row;
      elsif C.Requires_Overload_Generic and then not Overload_Generic.Is_Accepted (C.Overload_Generic_Status) then
         return Representation_Generic_Final_Overload_Generic_Blocker;
      elsif C.Requires_Volatile_Representation and then C.Volatile_Representation_Row = Volatile_Rep.No_Volatile_Atomic_Representation_Row then
         return Representation_Generic_Final_Missing_Volatile_Representation_Row;
      elsif C.Requires_Volatile_Representation and then not Volatile_Rep.Is_Accepted (C.Volatile_Representation_Status) then
         return Representation_Generic_Final_Volatile_Representation_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then
         return Representation_Generic_Final_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Representation_Generic_Final_Stabilized_Closure_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Representation_Generic_Final_Status;
      Kind   : Representation_Generic_Final_Kind;
      Family : Representation_Generic_Final_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("representation/generic shared-state final legality " &
         Representation_Generic_Final_Status'Image (Status) &
         " kind=" & Representation_Generic_Final_Kind'Image (Kind) &
         " blocker=" & Representation_Generic_Final_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Representation_Generic_Final_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Representation_Generic_Final_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Representation_Generic_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Representation_Generic_Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row (C : Representation_Generic_Final_Context; Index : Positive) return Representation_Generic_Final_Row is
      Status : constant Representation_Generic_Final_Status := Classify (C);
      Family : constant Representation_Generic_Final_Blocker_Family := Family_For (Status);
      Row : Representation_Generic_Final_Row;
   begin
      Row.Id := Representation_Generic_Final_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Representation_Name := C.Representation_Name;
      Row.Type_Name := C.Type_Name;
      Row.State_Name := C.State_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Row.Blocked or else Is_Indeterminate (Status);
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Row.Blocked and then Row.Blocker_Count = 0 then
         Row.Blocker_Count := 1;
      end if;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Substitution_Fingerprint := C.Substitution_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Message := Message_For (Status, C.Kind, Family);
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Representation_Generic_Final_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Representation_Generic_Final_Context_Model;
      Info  : Representation_Generic_Final_Context) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Representation_Generic_Final_Kind'Pos (Info.Kind) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Info.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Substitution_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Expected_Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Info.Expected_Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Representation_Generic_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Representation_Generic_Final_Context_Model;
      Index : Positive) return Representation_Generic_Final_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Representation_Generic_Final_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Representation_Generic_Final_Context_Model) return Representation_Generic_Final_Model is
      Result : Representation_Generic_Final_Model;
   begin
      for I in 1 .. Natural (Contexts.Items.Length) loop
         declare
            Row : constant Representation_Generic_Final_Row := Make_Row (Contexts.Items.Element (I), I);
         begin
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Representation_Generic_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Representation_Generic_Final_Model;
      Index : Positive) return Representation_Generic_Final_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Representation_Generic_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Representation_Generic_Final_Set;
      Index : Positive) return Representation_Generic_Final_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Representation_Generic_Final_Model;
      Status : Representation_Generic_Final_Status) return Representation_Generic_Final_Set is
      Result : Representation_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Representation_Generic_Final_Model;
      Family : Representation_Generic_Final_Blocker_Family) return Representation_Generic_Final_Set is
      Result : Representation_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Representation_Generic_Final_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Generic_Final_Set is
      Result : Representation_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Representation_Generic_Final_Model;
      Source_Fingerprint : Natural) return Representation_Generic_Final_Set is
      Result : Representation_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Representation_Generic_Final_Model;
      Status : Representation_Generic_Final_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Representation_Generic_Final_Model;
      Family : Representation_Generic_Final_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Representation_Generic_Final_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Accepted then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Accepted_Count;

   function Blocked_Count (Model : Representation_Generic_Final_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Blocked_Count;

   function Indeterminate_Count (Model : Representation_Generic_Final_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Representation_Generic_Final_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
