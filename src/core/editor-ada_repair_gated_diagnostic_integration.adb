with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Repair_Gated_Diagnostic_Integration is

   pragma Suppress (Overflow_Check);
   use type App.Application_Status;
   use type Closure.Integrated_Closure_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 167) + B + 71) mod 1_000_000_007;
   end Mix;

   function Is_Legal_Closure
     (Status : Closure.Integrated_Closure_Status) return Boolean is
   begin
      return Status in Closure.Integrated_Closure_Legal_Local |
                       Closure.Integrated_Closure_Legal_Cross_Unit |
                       Closure.Integrated_Closure_Legal_With_Use_Closure;
   end Is_Legal_Closure;

   function Is_Dependency_Failure
     (Status : Closure.Integrated_Closure_Status) return Boolean is
   begin
      return Status in Closure.Integrated_Closure_Missing_Dependency |
                       Closure.Integrated_Closure_Ambiguous_Dependency |
                       Closure.Integrated_Closure_Dependency_Overflow |
                       Closure.Integrated_Closure_Stale_Dependency;
   end Is_Dependency_Failure;

   function Severity_Of
     (Status : Repair_Gated_Diagnostic_Status) return Feed.Semantic_Diagnostic_Feed_Severity is
   begin
      case Status is
         when Repair_Gated_Diagnostic_Blocker |
              Repair_Gated_Diagnostic_Original_Error =>
            return Feed.Semantic_Diagnostic_Feed_Error;
         when Repair_Gated_Diagnostic_Dependency_Failure |
              Repair_Gated_Diagnostic_Indeterminate |
              Repair_Gated_Diagnostic_Stale_Rejected =>
            return Feed.Semantic_Diagnostic_Feed_Warning;
         when others =>
            return Feed.Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_Of;

   function Message_For
     (Status : Repair_Gated_Diagnostic_Status) return String is
   begin
      case Status is
         when Repair_Gated_Diagnostic_Restored_Confident =>
            return "coverage repair restored confident semantic closure";
         when Repair_Gated_Diagnostic_Already_Confident =>
            return "semantic closure was already confident";
         when Repair_Gated_Diagnostic_Blocker =>
            return "coverage repair did not clear semantic blocker";
         when Repair_Gated_Diagnostic_Dependency_Failure =>
            return "coverage repair still requires cross-unit semantic closure";
         when Repair_Gated_Diagnostic_Indeterminate =>
            return "coverage repair leaves semantic result indeterminate";
         when Repair_Gated_Diagnostic_Original_Error =>
            return "original semantic error is preserved after coverage repair";
         when Repair_Gated_Diagnostic_Stale_Rejected =>
            return "repair-gated diagnostic input was rejected as stale";
         when Repair_Gated_Diagnostic_Not_Checked =>
            return "repair-gated diagnostic integration was not checked";
      end case;
   end Message_For;

   function Classify
     (App_Row : App.Application_Info;
      Closure_Row : Closure.Integrated_Closure_Info;
      Input_Current : Boolean) return Repair_Gated_Diagnostic_Status is
   begin
      if not Input_Current then
         return Repair_Gated_Diagnostic_Stale_Rejected;
      elsif App_Row.Status = App.Application_Original_Error_Preserved then
         return Repair_Gated_Diagnostic_Original_Error;
      elsif Is_Legal_Closure (Closure_Row.Status) then
         if App.Clears_Gate (App_Row.Status) then
            return Repair_Gated_Diagnostic_Restored_Confident;
         else
            return Repair_Gated_Diagnostic_Already_Confident;
         end if;
      elsif Is_Dependency_Failure (Closure_Row.Status)
        or else App_Row.Status = App.Application_Cross_Unit_Still_Required
      then
         return Repair_Gated_Diagnostic_Dependency_Failure;
      elsif Closure_Row.Status = Closure.Integrated_Closure_Indeterminate
        or else App_Row.Status in App.Application_Repair_Partial |
                                  App.Application_Repair_Indeterminate
      then
         return Repair_Gated_Diagnostic_Indeterminate;
      else
         return Repair_Gated_Diagnostic_Blocker;
      end if;
   end Classify;

   function Action_For
     (Status : Repair_Gated_Diagnostic_Status) return Repair_Gated_Diagnostic_Action is
   begin
      case Status is
         when Repair_Gated_Diagnostic_Restored_Confident |
              Repair_Gated_Diagnostic_Already_Confident =>
            return Repair_Gated_Action_Withhold_Diagnostic;
         when Repair_Gated_Diagnostic_Blocker =>
            return Repair_Gated_Action_Emit_Error;
         when Repair_Gated_Diagnostic_Dependency_Failure =>
            return Repair_Gated_Action_Require_Cross_Unit_Closure;
         when Repair_Gated_Diagnostic_Indeterminate =>
            return Repair_Gated_Action_Emit_Warning;
         when Repair_Gated_Diagnostic_Original_Error =>
            return Repair_Gated_Action_Preserve_Original_Error;
         when Repair_Gated_Diagnostic_Stale_Rejected =>
            return Repair_Gated_Action_Reject_Stale_Input;
         when Repair_Gated_Diagnostic_Not_Checked =>
            return Repair_Gated_Action_None;
      end case;
   end Action_For;

   function Entry_Fingerprint (Row : Repair_Gated_Diagnostic_Info) return Natural is
      H : Natural := Natural (Row.Id);
      S : constant String := To_String (Row.Message) & To_String (Row.Detail);
   begin
      H := Mix (H, App.Application_Status'Pos (Row.Application_Status) + 1);
      H := Mix (H, Closure.Integrated_Closure_Status'Pos (Row.Closure_Status) + 1);
      H := Mix (H, Closure.Closure_Blocker_Family'Pos (Row.Blocker) + 1);
      H := Mix (H, Repair_Gated_Diagnostic_Status'Pos (Row.Status) + 1);
      H := Mix (H, Repair_Gated_Diagnostic_Action'Pos (Row.Action) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Source_Fingerprint);
      for C of S loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Entry_Fingerprint;

   function Make_Row
     (App_Row : App.Application_Info;
      Closure_Row : Closure.Integrated_Closure_Info;
      Index : Positive;
      Input_Current : Boolean) return Repair_Gated_Diagnostic_Info is
      Status : constant Repair_Gated_Diagnostic_Status :=
        Classify (App_Row, Closure_Row, Input_Current);
      Row : Repair_Gated_Diagnostic_Info;
   begin
      Row.Id := Repair_Gated_Diagnostic_Id (Index);
      Row.Application_Id := App_Row.Id;
      Row.Closure_Id := Closure_Row.Id;
      Row.Application_Status := App_Row.Status;
      Row.Closure_Status := Closure_Row.Status;
      Row.Blocker := Closure_Row.Blocker;
      Row.Dependency := Closure_Row.Dependency;
      Row.Status := Status;
      Row.Action := Action_For (Status);
      Row.Severity := Severity_Of (Status);
      Row.Node := Closure_Row.Node;
      if Row.Node = Editor.Ada_Syntax_Tree.No_Node then
         Row.Node := App_Row.Node;
      end if;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String
        ("application=" & To_String (App_Row.Message) &
         "; closure=" & To_String (Closure_Row.Message));
      Row.Source_Fingerprint := Mix (App_Row.Fingerprint, Closure_Row.Fingerprint);
      Row.Start_Line := Closure_Row.Start_Line;
      Row.Start_Column := Closure_Row.Start_Column;
      Row.End_Line := Closure_Row.End_Line;
      Row.End_Column := Closure_Row.End_Column;
      Row.Fingerprint := Entry_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Repair_Gated_Diagnostic_Model) is
   begin
      Model.Rows.Clear;
      Model.Restored_Total := 0;
      Model.Emitted_Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Withheld_Total := 0;
      Model.Dependency_Total := 0;
      Model.Original_Error_Total := 0;
      Model.Rejected_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Row
     (Model : in out Repair_Gated_Diagnostic_Model;
      Row   : Repair_Gated_Diagnostic_Info) is
   begin
      Model.Rows.Append (Row);
      case Row.Status is
         when Repair_Gated_Diagnostic_Restored_Confident =>
            Model.Restored_Total := Model.Restored_Total + 1;
            Model.Withheld_Total := Model.Withheld_Total + 1;
         when Repair_Gated_Diagnostic_Already_Confident =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
         when Repair_Gated_Diagnostic_Blocker =>
            Model.Emitted_Total := Model.Emitted_Total + 1;
            Model.Error_Total := Model.Error_Total + 1;
         when Repair_Gated_Diagnostic_Dependency_Failure =>
            Model.Emitted_Total := Model.Emitted_Total + 1;
            Model.Warning_Total := Model.Warning_Total + 1;
            Model.Dependency_Total := Model.Dependency_Total + 1;
         when Repair_Gated_Diagnostic_Indeterminate =>
            Model.Emitted_Total := Model.Emitted_Total + 1;
            Model.Warning_Total := Model.Warning_Total + 1;
         when Repair_Gated_Diagnostic_Original_Error =>
            Model.Emitted_Total := Model.Emitted_Total + 1;
            Model.Error_Total := Model.Error_Total + 1;
            Model.Original_Error_Total := Model.Original_Error_Total + 1;
         when Repair_Gated_Diagnostic_Stale_Rejected =>
            Model.Rejected_Total := Model.Rejected_Total + 1;
         when Repair_Gated_Diagnostic_Not_Checked =>
            null;
      end case;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
   end Add_Row;

   function Build
     (Applications : App.Application_Model;
      Closure_Model : Closure.Integrated_Closure_Model;
      Closure_Input_Current : Boolean := True;
      Closure_Rejected_Count : Natural := 0)
      return Repair_Gated_Diagnostic_Model is
      Result : Repair_Gated_Diagnostic_Model;
   begin
      if not Closure_Input_Current then
         for I in 1 .. App.Row_Count (Applications) loop
            declare
               A : constant App.Application_Info := App.Row_At (Applications, I);
               Empty_Closure : Closure.Integrated_Closure_Info;
            begin
               Add_Row (Result, Make_Row (A, Empty_Closure, I, False));
            end;
         end loop;
         Result.Rejected_Total := Result.Rejected_Total + Closure_Rejected_Count;
         Result.Fingerprint := Mix (Result.Fingerprint, Closure_Rejected_Count + 1);
         return Result;
      end if;

      for I in 1 .. App.Row_Count (Applications) loop
         declare
            A : constant App.Application_Info := App.Row_At (Applications, I);
            C : Closure.Integrated_Closure_Info;
         begin
            if I <= Closure.Closure_Count (Closure_Model) then
               C := Closure.Closure_At (Closure_Model, I);
            end if;
            Add_Row (Result, Make_Row (A, C, I, True));
         end;
      end loop;
      Result.Fingerprint := Mix (Result.Fingerprint, Closure.Fingerprint (Closure_Model));
      Result.Fingerprint := Mix (Result.Fingerprint, App.Fingerprint (Applications));
      return Result;
   end Build;

   function Row_Count (Model : Repair_Gated_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Repair_Gated_Diagnostic_Model;
      Index : Positive) return Repair_Gated_Diagnostic_Info is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Rows_For_Status
     (Model  : Repair_Gated_Diagnostic_Model;
      Status : Repair_Gated_Diagnostic_Status) return Repair_Gated_Diagnostic_Set is
      Result : Repair_Gated_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Action
     (Model  : Repair_Gated_Diagnostic_Model;
      Action : Repair_Gated_Diagnostic_Action) return Repair_Gated_Diagnostic_Set is
      Result : Repair_Gated_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Action;

   function First_For_Node
     (Model : Repair_Gated_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Repair_Gated_Diagnostic_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Set_Count (Set : Repair_Gated_Diagnostic_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At
     (Set   : Repair_Gated_Diagnostic_Set;
      Index : Positive) return Repair_Gated_Diagnostic_Info is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Repair_Gated_Diagnostic_Model;
      Status : Repair_Gated_Diagnostic_Status) return Natural is
   begin
      return Set_Count (Rows_For_Status (Model, Status));
   end Count_Status;

   function Count_Action
     (Model  : Repair_Gated_Diagnostic_Model;
      Action : Repair_Gated_Diagnostic_Action) return Natural is
   begin
      return Set_Count (Rows_For_Action (Model, Action));
   end Count_Action;

   function Restored_Confident_Count (Model : Repair_Gated_Diagnostic_Model) return Natural is
   begin
      return Model.Restored_Total;
   end Restored_Confident_Count;

   function Emitted_Diagnostic_Count (Model : Repair_Gated_Diagnostic_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Diagnostic_Count;

   function Error_Count (Model : Repair_Gated_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Repair_Gated_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Withheld_Diagnostic_Count (Model : Repair_Gated_Diagnostic_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Diagnostic_Count;

   function Dependency_Failure_Count (Model : Repair_Gated_Diagnostic_Model) return Natural is
   begin
      return Model.Dependency_Total;
   end Dependency_Failure_Count;

   function Original_Error_Count (Model : Repair_Gated_Diagnostic_Model) return Natural is
   begin
      return Model.Original_Error_Total;
   end Original_Error_Count;

   function Rejected_Stale_Count (Model : Repair_Gated_Diagnostic_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Stale_Count;

   function Fingerprint (Model : Repair_Gated_Diagnostic_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Repair_Gated_Diagnostic_Integration;
