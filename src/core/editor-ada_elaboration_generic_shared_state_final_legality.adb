with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality is

   use type Cross_Generic.Cross_Unit_Generic_Final_Row_Id;
   use type Dispatching_Global.Dispatching_Global_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elaboration_Final.Final_Elaboration_Row_Id;
   use type Generic_Replay.Generic_Abstract_Replay_Row_Id;
   use type Rep_Generic.Representation_Generic_Final_Row_Id;
   use type Tasking_Generic.Tasking_Generic_Final_Row_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 17) mod 2_147_483_647;
   end Mix;

   function Accepted_For (Kind : Elaboration_Generic_Final_Kind) return Elaboration_Generic_Final_Status is
   begin
      case Kind is
         when Elaboration_Generic_Final_Dispatching_Call =>
            return Elaboration_Generic_Final_Legal_Dispatching_Call_Accepted;
         when Elaboration_Generic_Final_Default_Expression =>
            return Elaboration_Generic_Final_Legal_Default_Expression_Accepted;
         when Elaboration_Generic_Final_Aspect_Expression =>
            return Elaboration_Generic_Final_Legal_Aspect_Expression_Accepted;
         when Elaboration_Generic_Final_Representation_Item =>
            return Elaboration_Generic_Final_Legal_Representation_Item_Accepted;
         when Elaboration_Generic_Final_Task_Activation =>
            return Elaboration_Generic_Final_Legal_Task_Activation_Accepted;
         when Elaboration_Generic_Final_Task_Termination =>
            return Elaboration_Generic_Final_Legal_Task_Termination_Accepted;
         when Elaboration_Generic_Final_Generic_Instance =>
            return Elaboration_Generic_Final_Legal_Generic_Instance_Accepted;
         when Elaboration_Generic_Final_Generic_Body_Replay =>
            return Elaboration_Generic_Final_Legal_Generic_Body_Replay_Accepted;
         when Elaboration_Generic_Final_Preelaboration_Policy =>
            return Elaboration_Generic_Final_Legal_Preelaboration_Policy_Accepted;
         when Elaboration_Generic_Final_Pure_Policy =>
            return Elaboration_Generic_Final_Legal_Pure_Policy_Accepted;
         when Elaboration_Generic_Final_Remote_Types_Policy =>
            return Elaboration_Generic_Final_Legal_Remote_Types_Policy_Accepted;
         when Elaboration_Generic_Final_Shared_Passive_Policy =>
            return Elaboration_Generic_Final_Legal_Shared_Passive_Policy_Accepted;
         when Elaboration_Generic_Final_Unknown =>
            return Elaboration_Generic_Final_Indeterminate;
      end case;
   end Accepted_For;

   function Is_Accepted (Status : Elaboration_Generic_Final_Status) return Boolean is
   begin
      case Status is
         when Elaboration_Generic_Final_Legal_Dispatching_Call_Accepted
            | Elaboration_Generic_Final_Legal_Default_Expression_Accepted
            | Elaboration_Generic_Final_Legal_Aspect_Expression_Accepted
            | Elaboration_Generic_Final_Legal_Representation_Item_Accepted
            | Elaboration_Generic_Final_Legal_Task_Activation_Accepted
            | Elaboration_Generic_Final_Legal_Task_Termination_Accepted
            | Elaboration_Generic_Final_Legal_Generic_Instance_Accepted
            | Elaboration_Generic_Final_Legal_Generic_Body_Replay_Accepted
            | Elaboration_Generic_Final_Legal_Preelaboration_Policy_Accepted
            | Elaboration_Generic_Final_Legal_Pure_Policy_Accepted
            | Elaboration_Generic_Final_Legal_Remote_Types_Policy_Accepted
            | Elaboration_Generic_Final_Legal_Shared_Passive_Policy_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Accepted;

   function Is_Indeterminate (Status : Elaboration_Generic_Final_Status) return Boolean is
   begin
      return Status = Elaboration_Generic_Final_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Elaboration_Generic_Final_Status) return Boolean is
   begin
      return not Is_Accepted (Status)
        and then Status /= Elaboration_Generic_Final_Not_Checked
        and then not Is_Indeterminate (Status);
   end Is_Blocked;

   function Family_For (Status : Elaboration_Generic_Final_Status) return Elaboration_Generic_Final_Blocker_Family is
   begin
      case Status is
         when Elaboration_Generic_Final_Missing_Final_Elaboration_Row
            | Elaboration_Generic_Final_Final_Elaboration_Blocker =>
            return Elaboration_Generic_Final_Blocker_Final_Elaboration;
         when Elaboration_Generic_Final_Missing_Cross_Unit_Generic_Row
            | Elaboration_Generic_Final_Cross_Unit_Generic_Blocker =>
            return Elaboration_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State;
         when Elaboration_Generic_Final_Missing_Dispatching_Global_Row
            | Elaboration_Generic_Final_Dispatching_Global_Blocker =>
            return Elaboration_Generic_Final_Blocker_Dispatching_Global;
         when Elaboration_Generic_Final_Missing_Generic_Replay_Row
            | Elaboration_Generic_Final_Generic_Replay_Blocker =>
            return Elaboration_Generic_Final_Blocker_Generic_Abstract_Replay;
         when Elaboration_Generic_Final_Missing_Representation_Generic_Row
            | Elaboration_Generic_Final_Representation_Generic_Blocker =>
            return Elaboration_Generic_Final_Blocker_Representation_Generic_Shared_State;
         when Elaboration_Generic_Final_Missing_Tasking_Generic_Row
            | Elaboration_Generic_Final_Tasking_Generic_Blocker =>
            return Elaboration_Generic_Final_Blocker_Tasking_Generic_Shared_State;
         when Elaboration_Generic_Final_Elaboration_Order_Blocker =>
            return Elaboration_Generic_Final_Blocker_Elaboration_Order;
         when Elaboration_Generic_Final_Preelaboration_Policy_Blocker =>
            return Elaboration_Generic_Final_Blocker_Preelaboration_Policy;
         when Elaboration_Generic_Final_Pure_Policy_Blocker =>
            return Elaboration_Generic_Final_Blocker_Pure_Policy;
         when Elaboration_Generic_Final_Remote_Types_Policy_Blocker =>
            return Elaboration_Generic_Final_Blocker_Remote_Types_Policy;
         when Elaboration_Generic_Final_Shared_Passive_Policy_Blocker =>
            return Elaboration_Generic_Final_Blocker_Shared_Passive_Policy;
         when Elaboration_Generic_Final_Generic_Body_Unavailable =>
            return Elaboration_Generic_Final_Blocker_Generic_Body;
         when Elaboration_Generic_Final_View_Barrier =>
            return Elaboration_Generic_Final_Blocker_View_Barrier;
         when Elaboration_Generic_Final_Source_Fingerprint_Mismatch =>
            return Elaboration_Generic_Final_Blocker_Source_Fingerprint;
         when Elaboration_Generic_Final_Substitution_Fingerprint_Mismatch =>
            return Elaboration_Generic_Final_Blocker_Substitution_Fingerprint;
         when Elaboration_Generic_Final_Multiple_Blockers =>
            return Elaboration_Generic_Final_Blocker_Multiple;
         when Elaboration_Generic_Final_Indeterminate =>
            return Elaboration_Generic_Final_Blocker_Indeterminate;
         when others =>
            return Elaboration_Generic_Final_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Elaboration_Generic_Final_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Elaboration_Order_Error then Count := Count + 1; end if;
      if C.Preelaboration_Policy_Error then Count := Count + 1; end if;
      if C.Pure_Policy_Error then Count := Count + 1; end if;
      if C.Remote_Types_Policy_Error then Count := Count + 1; end if;
      if C.Shared_Passive_Policy_Error then Count := Count + 1; end if;
      if C.Generic_Body_Unavailable then Count := Count + 1; end if;
      if C.View_Barrier then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Elaboration_Generic_Final_Context) return Elaboration_Generic_Final_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Elaboration_Generic_Final_Multiple_Blockers;
      elsif C.Elaboration_Order_Error then
         return Elaboration_Generic_Final_Elaboration_Order_Blocker;
      elsif C.Preelaboration_Policy_Error then
         return Elaboration_Generic_Final_Preelaboration_Policy_Blocker;
      elsif C.Pure_Policy_Error then
         return Elaboration_Generic_Final_Pure_Policy_Blocker;
      elsif C.Remote_Types_Policy_Error then
         return Elaboration_Generic_Final_Remote_Types_Policy_Blocker;
      elsif C.Shared_Passive_Policy_Error then
         return Elaboration_Generic_Final_Shared_Passive_Policy_Blocker;
      elsif C.Generic_Body_Unavailable then
         return Elaboration_Generic_Final_Generic_Body_Unavailable;
      elsif C.View_Barrier then
         return Elaboration_Generic_Final_View_Barrier;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Elaboration_Generic_Final_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Elaboration_Generic_Final_Substitution_Fingerprint_Mismatch;
      elsif C.Final_Elaboration_Row = Elaboration_Final.No_Final_Elaboration_Row then
         return Elaboration_Generic_Final_Missing_Final_Elaboration_Row;
      elsif not Elaboration_Final.Is_Legal (C.Final_Elaboration_Status) then
         return Elaboration_Generic_Final_Final_Elaboration_Blocker;
      elsif C.Cross_Generic_Row = Cross_Generic.No_Cross_Unit_Generic_Final_Row then
         return Elaboration_Generic_Final_Missing_Cross_Unit_Generic_Row;
      elsif not Cross_Generic.Is_Accepted (C.Cross_Generic_Status) then
         return Elaboration_Generic_Final_Cross_Unit_Generic_Blocker;
      elsif C.Requires_Dispatching_Global and then C.Dispatching_Global_Row = Dispatching_Global.No_Dispatching_Global_Row then
         return Elaboration_Generic_Final_Missing_Dispatching_Global_Row;
      elsif C.Requires_Dispatching_Global and then not Dispatching_Global.Is_Accepted (C.Dispatching_Global_Status) then
         return Elaboration_Generic_Final_Dispatching_Global_Blocker;
      elsif C.Requires_Generic_Replay and then C.Generic_Replay_Row = Generic_Replay.No_Generic_Abstract_Replay_Row then
         return Elaboration_Generic_Final_Missing_Generic_Replay_Row;
      elsif C.Requires_Generic_Replay and then not Generic_Replay.Is_Accepted (C.Generic_Replay_Status) then
         return Elaboration_Generic_Final_Generic_Replay_Blocker;
      elsif C.Requires_Representation_Generic and then C.Representation_Generic_Row = Rep_Generic.No_Representation_Generic_Final_Row then
         return Elaboration_Generic_Final_Missing_Representation_Generic_Row;
      elsif C.Requires_Representation_Generic and then not Rep_Generic.Is_Accepted (C.Representation_Generic_Status) then
         return Elaboration_Generic_Final_Representation_Generic_Blocker;
      elsif C.Requires_Tasking_Generic and then C.Tasking_Generic_Row = Tasking_Generic.No_Tasking_Generic_Final_Row then
         return Elaboration_Generic_Final_Missing_Tasking_Generic_Row;
      elsif C.Requires_Tasking_Generic and then not Tasking_Generic.Is_Accepted (C.Tasking_Generic_Status) then
         return Elaboration_Generic_Final_Tasking_Generic_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Elaboration_Generic_Final_Status;
      Kind   : Elaboration_Generic_Final_Kind;
      Family : Elaboration_Generic_Final_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("elaboration/generic shared-state final legality " &
         Elaboration_Generic_Final_Status'Image (Status) &
         " kind=" & Elaboration_Generic_Final_Kind'Image (Kind) &
         " blocker=" & Elaboration_Generic_Final_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Elaboration_Generic_Final_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Elaboration_Generic_Final_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Elaboration_Generic_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Elaboration_Generic_Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Build_Row (C : Elaboration_Generic_Final_Context) return Elaboration_Generic_Final_Row is
      Status : constant Elaboration_Generic_Final_Status := Classify (C);
      Family : constant Elaboration_Generic_Final_Blocker_Family := Family_For (Status);
      Row : Elaboration_Generic_Final_Row;
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Unit_Name := C.Unit_Name;
      Row.Target_Name := C.Target_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.State_Name := C.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Row.Blocked;
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
   end Build_Row;

   procedure Clear (Model : in out Elaboration_Generic_Final_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Elaboration_Generic_Final_Context_Model; Info : Elaboration_Generic_Final_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Elaboration_Generic_Final_Kind'Pos (Info.Kind) + 1);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Elaboration_Generic_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Elaboration_Generic_Final_Context_Model; Index : Positive) return Elaboration_Generic_Final_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Elaboration_Generic_Final_Context_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Elaboration_Generic_Final_Context_Model) return Elaboration_Generic_Final_Model is
      Result : Elaboration_Generic_Final_Model;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Elaboration_Generic_Final_Row := Build_Row (C);
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Elaboration_Generic_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Elaboration_Generic_Final_Model; Index : Positive) return Elaboration_Generic_Final_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Elaboration_Generic_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At (Set : Elaboration_Generic_Final_Set; Index : Positive) return Elaboration_Generic_Final_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status (Model : Elaboration_Generic_Final_Model; Status : Elaboration_Generic_Final_Status) return Elaboration_Generic_Final_Set is
      Result : Elaboration_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family (Model : Elaboration_Generic_Final_Model; Family : Elaboration_Generic_Final_Blocker_Family) return Elaboration_Generic_Final_Set is
      Result : Elaboration_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node (Model : Elaboration_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Generic_Final_Set is
      Result : Elaboration_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Elaboration_Generic_Final_Model; Source_Fingerprint : Natural) return Elaboration_Generic_Final_Set is
      Result : Elaboration_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status (Model : Elaboration_Generic_Final_Model; Status : Elaboration_Generic_Final_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Elaboration_Generic_Final_Model; Family : Elaboration_Generic_Final_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Elaboration_Generic_Final_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Accepted then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Accepted_Count;

   function Blocked_Count (Model : Elaboration_Generic_Final_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Elaboration_Generic_Final_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Elaboration_Generic_Final_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
