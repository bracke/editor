with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality is

   pragma Suppress (Overflow_Check);
   use type Backmap.Generic_Backmap_Status;
   use type Final_RM.Final_RM_Status;
   use type Cross_Final.Cross_Unit_Final_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 1) mod 2_147_483_647;
   end Mix;

   function Kind_Slot (Kind : Nested_Generic_Closure_Kind) return Natural is
   begin
      return Nested_Generic_Closure_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Nested_Generic_Closure_Status) return Natural is
   begin
      return Nested_Generic_Closure_Status'Pos (Status) + 1;
   end Status_Slot;

   function Backmap_Blocker (Status : Backmap.Generic_Backmap_Status) return Boolean is
   begin
      return Status /= Backmap.Generic_Backmap_Not_Checked
        and then not Backmap.Is_Legal (Status)
        and then Status /= Backmap.Generic_Backmap_Indeterminate;
   end Backmap_Blocker;

   function Final_RM_Blocker (Status : Final_RM.Final_RM_Status) return Boolean is
   begin
      return Status /= Final_RM.Final_RM_Not_Checked
        and then not Final_RM.Is_Legal (Status)
        and then Status /= Final_RM.Final_RM_Indeterminate;
   end Final_RM_Blocker;

   function Cross_Blocker (Status : Cross_Final.Cross_Unit_Final_Status) return Boolean is
   begin
      return Status /= Cross_Final.Cross_Unit_Final_Not_Checked
        and then not Cross_Final.Is_Legal (Status)
        and then not Cross_Final.Is_Indeterminate (Status);
   end Cross_Blocker;

   function Classify (Info : Nested_Generic_Closure_Context_Info) return Nested_Generic_Closure_Status is
      Blockers : Natural := 0;
   begin
      if Info.Backmap_Status = Backmap.Generic_Backmap_Not_Checked then
         Blockers := Blockers + 1;
      elsif Backmap_Blocker (Info.Backmap_Status)
        or else Info.Backmap_Status = Backmap.Generic_Backmap_Indeterminate
      then
         Blockers := Blockers + 1;
      end if;

      if Info.Requires_Final_RM and then Info.Final_RM_Status = Final_RM.Final_RM_Not_Checked then
         Blockers := Blockers + 1;
      elsif Final_RM_Blocker (Info.Final_RM_Status)
        or else Info.Final_RM_Status = Final_RM.Final_RM_Indeterminate
      then
         Blockers := Blockers + 1;
      elsif Final_RM.Is_Ambiguous (Info.Final_RM_Status) then
         Blockers := Blockers + 1;
      end if;

      if Info.Requires_Cross_Unit and then Info.Cross_Unit_Status = Cross_Final.Cross_Unit_Final_Not_Checked then
         Blockers := Blockers + 1;
      elsif Cross_Blocker (Info.Cross_Unit_Status)
        or else Cross_Final.Is_Indeterminate (Info.Cross_Unit_Status)
      then
         Blockers := Blockers + 1;
      end if;

      if not Info.Generic_Body_Available then
         Blockers := Blockers + 1;
      end if;
      if Info.Private_View_Barrier or else Info.Limited_View_Barrier
        or else Info.Child_Visibility_Blocked
      then
         Blockers := Blockers + 1;
      end if;
      if Info.Source_Fingerprint /= 0 and then Info.Expected_Source_Fingerprint /= 0
        and then Info.Source_Fingerprint /= Info.Expected_Source_Fingerprint
      then
         Blockers := Blockers + 1;
      end if;
      if Info.Substitution_Fingerprint /= 0 and then Info.Expected_Substitution_Fingerprint /= 0
        and then Info.Substitution_Fingerprint /= Info.Expected_Substitution_Fingerprint
      then
         Blockers := Blockers + 1;
      end if;
      if Info.Nested_Dependency_Cycle or else Info.Recursive_Instantiation_Cycle
        or else Info.Cycle_Depth > Info.Max_Cycle_Depth
      then
         Blockers := Blockers + 1;
      end if;
      if Info.Dependency_Count > Info.Max_Dependency_Count or else Info.Stale_Dependency then
         Blockers := Blockers + 1;
      end if;

      if Blockers > 1 then
         return Nested_Generic_Multiple_Blockers;
      end if;

      if Info.Backmap_Status = Backmap.Generic_Backmap_Not_Checked then
         return Nested_Generic_Missing_Generic_Backmap;
      elsif Backmap.Is_Mapping_Error (Info.Backmap_Status) then
         return Nested_Generic_Backmap_Mapping_Blocker;
      elsif Backmap.Is_Overload_Error (Info.Backmap_Status) then
         return Nested_Generic_Backmap_Overload_Blocker;
      elsif Backmap_Blocker (Info.Backmap_Status) then
         return Nested_Generic_Backmap_Blocker;
      elsif Info.Backmap_Status = Backmap.Generic_Backmap_Indeterminate then
         return Nested_Generic_Backmap_Indeterminate;
      end if;

      if Info.Requires_Final_RM and then Info.Final_RM_Status = Final_RM.Final_RM_Not_Checked then
         return Nested_Generic_Missing_Final_RM_Consumer;
      elsif Final_RM.Is_Ambiguous (Info.Final_RM_Status) then
         return Nested_Generic_Final_RM_Ambiguous;
      elsif Final_RM_Blocker (Info.Final_RM_Status) then
         return Nested_Generic_Final_RM_Blocker;
      elsif Info.Final_RM_Status = Final_RM.Final_RM_Indeterminate then
         return Nested_Generic_Final_RM_Indeterminate;
      end if;

      if Info.Requires_Cross_Unit and then Info.Cross_Unit_Status = Cross_Final.Cross_Unit_Final_Not_Checked then
         return Nested_Generic_Missing_Cross_Unit_Final_Closure;
      elsif Cross_Final.Is_View_Barrier (Info.Cross_Unit_Status) then
         if Info.Cross_Unit_Status = Cross_Final.Cross_Unit_Final_Private_View_Barrier then
            return Nested_Generic_Private_View_Barrier;
         else
            return Nested_Generic_Limited_View_Barrier;
         end if;
      elsif Cross_Final.Is_Dependency_Error (Info.Cross_Unit_Status) then
         return Nested_Generic_Cross_Unit_Dependency_Blocker;
      elsif Cross_Blocker (Info.Cross_Unit_Status) then
         return Nested_Generic_Cross_Unit_Dependency_Blocker;
      elsif Cross_Final.Is_Indeterminate (Info.Cross_Unit_Status) then
         return Nested_Generic_Indeterminate;
      end if;

      if not Info.Generic_Body_Available then
         return Nested_Generic_Generic_Body_Unavailable;
      elsif Info.Private_View_Barrier then
         return Nested_Generic_Private_View_Barrier;
      elsif Info.Limited_View_Barrier then
         return Nested_Generic_Limited_View_Barrier;
      elsif Info.Child_Visibility_Blocked then
         return Nested_Generic_Child_Visibility_Blocker;
      elsif Info.Source_Fingerprint /= 0 and then Info.Expected_Source_Fingerprint /= 0
        and then Info.Source_Fingerprint /= Info.Expected_Source_Fingerprint
      then
         return Nested_Generic_Source_Instance_Fingerprint_Mismatch;
      elsif Info.Substitution_Fingerprint /= 0 and then Info.Expected_Substitution_Fingerprint /= 0
        and then Info.Substitution_Fingerprint /= Info.Expected_Substitution_Fingerprint
      then
         return Nested_Generic_Substitution_Fingerprint_Mismatch;
      elsif Info.Nested_Dependency_Cycle then
         return Nested_Generic_Nested_Dependency_Cycle;
      elsif Info.Recursive_Instantiation_Cycle then
         return Nested_Generic_Recursive_Instantiation_Cycle;
      elsif Info.Cycle_Depth > Info.Max_Cycle_Depth then
         return Nested_Generic_Cycle_Depth_Overflow;
      elsif Info.Dependency_Count > Info.Max_Dependency_Count then
         return Nested_Generic_Dependency_Overflow;
      elsif Info.Stale_Dependency then
         return Nested_Generic_Stale_Dependency;
      end if;

      case Info.Kind is
         when Nested_Generic_Local_Instance =>
            return Nested_Generic_Legal_Local_Instance_Closed;
         when Nested_Generic_Cross_Unit_Instance =>
            return Nested_Generic_Legal_Cross_Unit_Instance_Closed;
         when Nested_Generic_Child_Instance =>
            return Nested_Generic_Legal_Child_Instance_Closed;
         when Nested_Generic_Private_Child_Instance =>
            return Nested_Generic_Legal_Private_Child_Instance_Closed;
         when Nested_Generic_Formal_Package_Instance =>
            return Nested_Generic_Legal_Formal_Package_Instance_Closed;
         when Nested_Generic_Nested_Instance =>
            return Nested_Generic_Legal_Nested_Instance_Closed;
         when Nested_Generic_Body_Replay =>
            return Nested_Generic_Legal_Body_Replay_Closed;
         when Nested_Generic_Subprogram_Replay =>
            return Nested_Generic_Legal_Subprogram_Replay_Closed;
         when Nested_Generic_Representation_Replay =>
            return Nested_Generic_Legal_Representation_Replay_Closed;
         when Nested_Generic_Task_Protected_Replay =>
            return Nested_Generic_Legal_Task_Protected_Replay_Closed;
         when Nested_Generic_Unknown =>
            return Nested_Generic_Indeterminate;
      end case;
   end Classify;

   function Message_For (Status : Nested_Generic_Closure_Status) return String is
   begin
      case Status is
         when Nested_Generic_Legal_Local_Instance_Closed => return "local generic instance replay closure accepted";
         when Nested_Generic_Legal_Cross_Unit_Instance_Closed => return "cross-unit generic instance replay closure accepted";
         when Nested_Generic_Legal_Child_Instance_Closed => return "child-unit generic instance replay closure accepted";
         when Nested_Generic_Legal_Private_Child_Instance_Closed => return "private-child generic instance replay closure accepted";
         when Nested_Generic_Legal_Formal_Package_Instance_Closed => return "formal-package generic instance replay closure accepted";
         when Nested_Generic_Legal_Nested_Instance_Closed => return "nested generic instance replay closure accepted";
         when Nested_Generic_Legal_Body_Replay_Closed => return "generic body replay closure accepted";
         when Nested_Generic_Legal_Subprogram_Replay_Closed => return "generic subprogram replay closure accepted";
         when Nested_Generic_Legal_Representation_Replay_Closed => return "generic representation replay closure accepted";
         when Nested_Generic_Legal_Task_Protected_Replay_Closed => return "generic task/protected replay closure accepted";
         when Nested_Generic_Missing_Generic_Backmap => return "generic source/instance backmapping evidence is missing";
         when Nested_Generic_Backmap_Blocker => return "generic source/instance backmapping blocks nested replay closure";
         when Nested_Generic_Backmap_Mapping_Blocker => return "generic source/instance mapping blocks nested replay closure";
         when Nested_Generic_Backmap_Overload_Blocker => return "generic replay overload backmapping blocks nested replay closure";
         when Nested_Generic_Backmap_Indeterminate => return "generic source/instance backmapping is indeterminate";
         when Nested_Generic_Missing_Final_RM_Consumer => return "final overload/type RM consumer evidence is missing";
         when Nested_Generic_Final_RM_Blocker => return "final overload/type RM consumer blocks nested replay closure";
         when Nested_Generic_Final_RM_Ambiguous => return "final overload/type RM consumer remains ambiguous";
         when Nested_Generic_Final_RM_Indeterminate => return "final overload/type RM consumer is indeterminate";
         when Nested_Generic_Missing_Cross_Unit_Final_Closure => return "cross-unit final semantic closure evidence is missing";
         when Nested_Generic_Cross_Unit_Dependency_Blocker => return "cross-unit dependency blocks nested generic replay closure";
         when Nested_Generic_Private_View_Barrier => return "private-view barrier blocks nested generic replay closure";
         when Nested_Generic_Limited_View_Barrier => return "limited-view barrier blocks nested generic replay closure";
         when Nested_Generic_Child_Visibility_Blocker => return "child/private-child visibility blocks nested generic replay closure";
         when Nested_Generic_Generic_Body_Unavailable => return "generic body is unavailable for replay closure";
         when Nested_Generic_Source_Instance_Fingerprint_Mismatch => return "generic source/instance fingerprint mismatch";
         when Nested_Generic_Substitution_Fingerprint_Mismatch => return "generic substitution fingerprint mismatch";
         when Nested_Generic_Nested_Dependency_Cycle => return "nested generic dependency cycle detected";
         when Nested_Generic_Recursive_Instantiation_Cycle => return "recursive generic instantiation cycle detected";
         when Nested_Generic_Cycle_Depth_Overflow => return "nested generic cycle depth exceeds bounded closure limit";
         when Nested_Generic_Dependency_Overflow => return "nested generic dependency count exceeds bounded closure limit";
         when Nested_Generic_Stale_Dependency => return "stale nested generic dependency rejected";
         when Nested_Generic_Multiple_Blockers => return "multiple nested generic replay closure blockers preserved";
         when Nested_Generic_Indeterminate => return "nested generic replay closure is indeterminate";
         when Nested_Generic_Not_Checked => return "nested generic replay closure was not checked";
      end case;
   end Message_For;

   function Detail_For (Info : Nested_Generic_Closure_Context_Info; Status : Nested_Generic_Closure_Status) return String is
      pragma Unreferenced (Status);
   begin
      return "generic=" & To_String (Info.Generic_Unit_Name)
        & "; instance=" & To_String (Info.Instance_Name)
        & "; parent=" & To_String (Info.Parent_Instance_Name);
   end Detail_For;

   function Count_Blockers (Info : Nested_Generic_Closure_Context_Info; Status : Nested_Generic_Closure_Status) return Natural is
      pragma Unreferenced (Info);
   begin
      if Is_Legal (Status) then
         return 0;
      elsif Status = Nested_Generic_Not_Checked then
         return 0;
      else
         return 1;
      end if;
   end Count_Blockers;

   procedure Clear (Model : in out Nested_Generic_Closure_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Nested_Generic_Closure_Context_Model; Info : Nested_Generic_Closure_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Kind_Slot (Info.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Nested_Generic_Closure_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At (Model : Nested_Generic_Closure_Context_Model; Index : Positive) return Nested_Generic_Closure_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Nested_Generic_Closure_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Nested_Generic_Closure_Context_Model) return Nested_Generic_Closure_Model is
      Result : Nested_Generic_Closure_Model;
   begin
      for Index in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Nested_Generic_Closure_Context_Info := Contexts.Contexts.Element (Index);
            S : constant Nested_Generic_Closure_Status := Classify (C);
            R : Nested_Generic_Closure_Info;
         begin
            R.Id := Nested_Generic_Closure_Row_Id (Index);
            R.Context := C.Id;
            R.Kind := C.Kind;
            R.Node := C.Node;
            R.Status := S;
            R.Generic_Unit_Name := C.Generic_Unit_Name;
            R.Instance_Name := C.Instance_Name;
            R.Parent_Instance_Name := C.Parent_Instance_Name;
            R.Message := To_Unbounded_String (Message_For (S));
            R.Detail := To_Unbounded_String (Detail_For (C, S));
            R.Backmap_Row := C.Backmap_Row;
            R.Backmap_Status := C.Backmap_Status;
            R.Final_RM_Row := C.Final_RM_Row;
            R.Final_RM_Status := C.Final_RM_Status;
            R.Cross_Unit_Row := C.Cross_Unit_Row;
            R.Cross_Unit_Status := C.Cross_Unit_Status;
            R.Blocker_Count := Count_Blockers (C, S);
            R.Cycle_Depth := C.Cycle_Depth;
            R.Dependency_Count := C.Dependency_Count;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.Substitution_Fingerprint := C.Substitution_Fingerprint;
            R.Start_Line := C.Start_Line;
            R.Start_Column := C.Start_Column;
            R.End_Line := C.End_Line;
            R.End_Column := C.End_Column;
            R.Fingerprint := Mix (Mix (Natural (R.Id), Status_Slot (S)), Mix (C.Source_Fingerprint, C.Substitution_Fingerprint));
            Result.Items.Append (R);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
            if Is_Legal (S) then
               Result.Legal_Total := Result.Legal_Total + 1;
            elsif S = Nested_Generic_Indeterminate or else S = Nested_Generic_Backmap_Indeterminate
              or else S = Nested_Generic_Final_RM_Indeterminate
            then
               Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
            else
               Result.Blocker_Total := Result.Blocker_Total + 1;
            end if;
            if Is_Cycle_Blocker (S) then
               Result.Cycle_Blocker_Total := Result.Cycle_Blocker_Total + 1;
            end if;
            if S in Nested_Generic_Missing_Cross_Unit_Final_Closure |
                    Nested_Generic_Cross_Unit_Dependency_Blocker |
                    Nested_Generic_Private_View_Barrier |
                    Nested_Generic_Limited_View_Barrier |
                    Nested_Generic_Child_Visibility_Blocker |
                    Nested_Generic_Dependency_Overflow |
                    Nested_Generic_Stale_Dependency
            then
               Result.Cross_Unit_Blocker_Total := Result.Cross_Unit_Blocker_Total + 1;
            end if;
            if S in Nested_Generic_Missing_Generic_Backmap |
                    Nested_Generic_Backmap_Blocker |
                    Nested_Generic_Backmap_Mapping_Blocker |
                    Nested_Generic_Backmap_Overload_Blocker |
                    Nested_Generic_Backmap_Indeterminate
            then
               Result.Backmap_Blocker_Total := Result.Backmap_Blocker_Total + 1;
            end if;
            if S in Nested_Generic_Missing_Final_RM_Consumer |
                    Nested_Generic_Final_RM_Blocker |
                    Nested_Generic_Final_RM_Ambiguous |
                    Nested_Generic_Final_RM_Indeterminate
            then
               Result.Final_RM_Blocker_Total := Result.Final_RM_Blocker_Total + 1;
            end if;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Nested_Generic_Closure_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At (Model : Nested_Generic_Closure_Model; Index : Positive) return Nested_Generic_Closure_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node (Model : Nested_Generic_Closure_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Nested_Generic_Closure_Info is
   begin
      for R of Model.Items loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Nested_Generic_Closure_Model; Status : Nested_Generic_Closure_Status) return Nested_Generic_Closure_Result_Set is
      Result : Nested_Generic_Closure_Result_Set;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Result.Items.Append (R);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Nested_Generic_Closure_Model; Kind : Nested_Generic_Closure_Kind) return Nested_Generic_Closure_Result_Set is
      Result : Nested_Generic_Closure_Result_Set;
   begin
      for R of Model.Items loop
         if R.Kind = Kind then
            Result.Items.Append (R);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Instance (Model : Nested_Generic_Closure_Model; Instance_Name : String) return Nested_Generic_Closure_Result_Set is
      Result : Nested_Generic_Closure_Result_Set;
   begin
      for R of Model.Items loop
         if To_String (R.Instance_Name) = Instance_Name then
            Result.Items.Append (R);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Instance;

   function Result_Count (Results : Nested_Generic_Closure_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At (Results : Nested_Generic_Closure_Result_Set; Index : Positive) return Nested_Generic_Closure_Info is
   begin
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Nested_Generic_Closure_Model; Status : Nested_Generic_Closure_Status) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Nested_Generic_Closure_Model; Kind : Nested_Generic_Closure_Kind) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Nested_Generic_Closure_Model) return Natural is (Model.Legal_Total);
   function Blocker_Count (Model : Nested_Generic_Closure_Model) return Natural is (Model.Blocker_Total);
   function Cycle_Blocker_Count (Model : Nested_Generic_Closure_Model) return Natural is (Model.Cycle_Blocker_Total);
   function Cross_Unit_Blocker_Count (Model : Nested_Generic_Closure_Model) return Natural is (Model.Cross_Unit_Blocker_Total);
   function Backmap_Blocker_Count (Model : Nested_Generic_Closure_Model) return Natural is (Model.Backmap_Blocker_Total);
   function Final_RM_Blocker_Count (Model : Nested_Generic_Closure_Model) return Natural is (Model.Final_RM_Blocker_Total);
   function Indeterminate_Count (Model : Nested_Generic_Closure_Model) return Natural is (Model.Indeterminate_Total);
   function Fingerprint (Model : Nested_Generic_Closure_Model) return Natural is (Model.Result_Fingerprint);

   function Is_Legal (Status : Nested_Generic_Closure_Status) return Boolean is
   begin
      return Status in
        Nested_Generic_Legal_Local_Instance_Closed |
        Nested_Generic_Legal_Cross_Unit_Instance_Closed |
        Nested_Generic_Legal_Child_Instance_Closed |
        Nested_Generic_Legal_Private_Child_Instance_Closed |
        Nested_Generic_Legal_Formal_Package_Instance_Closed |
        Nested_Generic_Legal_Nested_Instance_Closed |
        Nested_Generic_Legal_Body_Replay_Closed |
        Nested_Generic_Legal_Subprogram_Replay_Closed |
        Nested_Generic_Legal_Representation_Replay_Closed |
        Nested_Generic_Legal_Task_Protected_Replay_Closed;
   end Is_Legal;

   function Is_Cycle_Blocker (Status : Nested_Generic_Closure_Status) return Boolean is
   begin
      return Status in
        Nested_Generic_Nested_Dependency_Cycle |
        Nested_Generic_Recursive_Instantiation_Cycle |
        Nested_Generic_Cycle_Depth_Overflow;
   end Is_Cycle_Blocker;

   function Has_Error (Info : Nested_Generic_Closure_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status)
        and then Info.Status /= Nested_Generic_Not_Checked
        and then Info.Status /= Nested_Generic_Indeterminate
        and then Info.Status /= Nested_Generic_Backmap_Indeterminate
        and then Info.Status /= Nested_Generic_Final_RM_Indeterminate;
   end Has_Error;

end Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
