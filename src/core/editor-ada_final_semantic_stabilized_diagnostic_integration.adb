with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Blocker_Family;
   use type Final_Stabilized_Diagnostic_Family;
   use type Final_Stabilized_Diagnostic_Severity;
   use type Final_Stabilized_Diagnostic_Status;
   use type Final_Stabilized_Closure_Status;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Left) * 16#0100_0193#
        + Hash_Value (Right)
        + 16#9E37_79B9#;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Status_For
     (Status : Final_Stabilized_Closure_Status) return Final_Stabilized_Diagnostic_Status is
   begin
      case Status is
         when Closure.Final_Stabilized_Closure_Accepted_Current =>
            return Final_Stabilized_Diagnostic_Withheld_Accepted_Current;
         when Closure.Final_Stabilized_Closure_Accepted_Not_Required =>
            return Final_Stabilized_Diagnostic_Withheld_Accepted_Not_Required;
         when Closure.Final_Stabilized_Closure_Blocker_Stale =>
            return Final_Stabilized_Diagnostic_Stale_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_AST_Coverage =>
            return Final_Stabilized_Diagnostic_AST_Coverage_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_Cross_Unit =>
            return Final_Stabilized_Diagnostic_Cross_Unit_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_View_Barrier =>
            return Final_Stabilized_Diagnostic_View_Barrier;
         when Closure.Final_Stabilized_Closure_Blocker_Generic_Replay =>
            return Final_Stabilized_Diagnostic_Generic_Replay_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_Overload_Type =>
            return Final_Stabilized_Diagnostic_Overload_Type_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_Representation_Freezing =>
            return Final_Stabilized_Diagnostic_Representation_Freezing_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_Flow_Contract =>
            return Final_Stabilized_Diagnostic_Flow_Contract_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_Tasking_Protected =>
            return Final_Stabilized_Diagnostic_Tasking_Protected_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_Elaboration =>
            return Final_Stabilized_Diagnostic_Elaboration_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_Accessibility =>
            return Final_Stabilized_Diagnostic_Accessibility_Lifetime_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_Discriminant_Variant =>
            return Final_Stabilized_Diagnostic_Discriminant_Variant_Blocker;
         when Closure.Final_Stabilized_Closure_Blocker_Preserved_Semantic_Error =>
            return Final_Stabilized_Diagnostic_Preserved_Semantic_Error;
         when Closure.Final_Stabilized_Closure_Blocker_Multiple_Prerequisites =>
            return Final_Stabilized_Diagnostic_Multiple_Prerequisites;
         when Closure.Final_Stabilized_Closure_Indeterminate =>
            return Final_Stabilized_Diagnostic_Indeterminate;
         when Closure.Final_Stabilized_Closure_Recheck_Required =>
            return Final_Stabilized_Diagnostic_Recheck_Required;
         when Closure.Final_Stabilized_Closure_Not_Checked =>
            return Final_Stabilized_Diagnostic_Not_Checked;
      end case;
   end Status_For;

   function Family_For
     (Status  : Final_Stabilized_Diagnostic_Status;
      Blocker : Final_Blocker_Family) return Final_Stabilized_Diagnostic_Family is
   begin
      case Status is
         when Final_Stabilized_Diagnostic_Stale_Blocker =>
            return Final_Stabilized_Diagnostic_Stale_Input;
         when Final_Stabilized_Diagnostic_AST_Coverage_Blocker =>
            return Final_Stabilized_Diagnostic_AST_Coverage;
         when Final_Stabilized_Diagnostic_Cross_Unit_Blocker =>
            return Final_Stabilized_Diagnostic_Cross_Unit;
         when Final_Stabilized_Diagnostic_View_Barrier =>
            return Final_Stabilized_Diagnostic_View_Barrier;
         when Final_Stabilized_Diagnostic_Generic_Replay_Blocker =>
            return Final_Stabilized_Diagnostic_Generic_Replay;
         when Final_Stabilized_Diagnostic_Overload_Type_Blocker =>
            return Final_Stabilized_Diagnostic_Overload_Type;
         when Final_Stabilized_Diagnostic_Representation_Freezing_Blocker =>
            return Final_Stabilized_Diagnostic_Representation_Freezing;
         when Final_Stabilized_Diagnostic_Flow_Contract_Blocker =>
            return Final_Stabilized_Diagnostic_Flow_Contract;
         when Final_Stabilized_Diagnostic_Tasking_Protected_Blocker =>
            return Final_Stabilized_Diagnostic_Tasking_Protected;
         when Final_Stabilized_Diagnostic_Elaboration_Blocker =>
            return Final_Stabilized_Diagnostic_Elaboration;
         when Final_Stabilized_Diagnostic_Accessibility_Lifetime_Blocker =>
            return Final_Stabilized_Diagnostic_Accessibility_Lifetime;
         when Final_Stabilized_Diagnostic_Discriminant_Variant_Blocker =>
            return Final_Stabilized_Diagnostic_Discriminant_Variant;
         when Final_Stabilized_Diagnostic_Preserved_Semantic_Error =>
            return Final_Stabilized_Diagnostic_Preserved_Error;
         when Final_Stabilized_Diagnostic_Multiple_Prerequisites =>
            return Final_Stabilized_Diagnostic_Multiple;
         when Final_Stabilized_Diagnostic_Indeterminate
            | Final_Stabilized_Diagnostic_Recheck_Required
            | Final_Stabilized_Diagnostic_Not_Checked =>
            return Final_Stabilized_Diagnostic_Indeterminate;
         when others =>
            case Blocker is
               when Final_Prov.Final_Blocker_Cross_Unit =>
                  return Final_Stabilized_Diagnostic_Cross_Unit;
               when Final_Prov.Final_Blocker_Overload_Type =>
                  return Final_Stabilized_Diagnostic_Overload_Type;
               when Final_Prov.Final_Blocker_Generic_Replay =>
                  return Final_Stabilized_Diagnostic_Generic_Replay;
               when Final_Prov.Final_Blocker_Representation_Freezing =>
                  return Final_Stabilized_Diagnostic_Representation_Freezing;
               when Final_Prov.Final_Blocker_Flow_Contract =>
                  return Final_Stabilized_Diagnostic_Flow_Contract;
               when Final_Prov.Final_Blocker_Tasking_Protected =>
                  return Final_Stabilized_Diagnostic_Tasking_Protected;
               when Final_Prov.Final_Blocker_Elaboration =>
                  return Final_Stabilized_Diagnostic_Elaboration;
               when Final_Prov.Final_Blocker_Accessibility_Lifetime =>
                  return Final_Stabilized_Diagnostic_Accessibility_Lifetime;
               when Final_Prov.Final_Blocker_Discriminant_Variant =>
                  return Final_Stabilized_Diagnostic_Discriminant_Variant;
               when Final_Prov.Final_Blocker_AST_Repair | Final_Prov.Final_Blocker_Coverage_Gate =>
                  return Final_Stabilized_Diagnostic_AST_Coverage;
               when Final_Prov.Final_Blocker_View_Barrier =>
                  return Final_Stabilized_Diagnostic_View_Barrier;
               when Final_Prov.Final_Blocker_Multiple =>
                  return Final_Stabilized_Diagnostic_Multiple;
               when others =>
                  return Final_Stabilized_Diagnostic_Unknown;
            end case;
      end case;
   end Family_For;

   function Severity_For
     (Status : Final_Stabilized_Diagnostic_Status) return Final_Stabilized_Diagnostic_Severity is
   begin
      case Status is
         when Final_Stabilized_Diagnostic_Withheld_Accepted_Current
            | Final_Stabilized_Diagnostic_Withheld_Accepted_Not_Required =>
            return Final_Stabilized_Diagnostic_Info;
         when Final_Stabilized_Diagnostic_Stale_Blocker
            | Final_Stabilized_Diagnostic_View_Barrier
            | Final_Stabilized_Diagnostic_Indeterminate
            | Final_Stabilized_Diagnostic_Recheck_Required
            | Final_Stabilized_Diagnostic_Not_Checked =>
            return Final_Stabilized_Diagnostic_Warning;
         when others =>
            return Final_Stabilized_Diagnostic_Error;
      end case;
   end Severity_For;

   function Is_Emitted (Status : Final_Stabilized_Diagnostic_Status) return Boolean is
   begin
      return not Is_Withheld_Current (Status);
   end Is_Emitted;

   function Is_Withheld_Current (Status : Final_Stabilized_Diagnostic_Status) return Boolean is
   begin
      return Status = Final_Stabilized_Diagnostic_Withheld_Accepted_Current
        or else Status = Final_Stabilized_Diagnostic_Withheld_Accepted_Not_Required;
   end Is_Withheld_Current;

   function Message_For
     (Status : Final_Stabilized_Diagnostic_Status;
      Family : Final_Stabilized_Diagnostic_Family) return Unbounded_String is
   begin
      if Is_Withheld_Current (Status) then
         return To_Unbounded_String ("final stabilized semantic closure accepted");
      elsif Status = Final_Stabilized_Diagnostic_Recheck_Required then
         return To_Unbounded_String ("final stabilized semantic closure requires recheck before feed promotion");
      elsif Status = Final_Stabilized_Diagnostic_Indeterminate then
         return To_Unbounded_String ("final stabilized semantic closure remains indeterminate");
      else
         return To_Unbounded_String
           ("final stabilized semantic blocker: " & Final_Stabilized_Diagnostic_Family'Image (Family));
      end if;
   end Message_For;

   function Detail_For
     (Source : Closure.Final_Stabilized_Closure_Row;
      Status : Final_Stabilized_Diagnostic_Status) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("closure_status=" & Final_Stabilized_Closure_Status'Image (Source.Status) &
         "; closure_action=" & Final_Stabilized_Closure_Action'Image (Source.Action) &
         "; stabilization_status=" & Closure.Final_Stabilization_Gate_Status'Image (Source.Stabilization_Status) &
         "; diagnostic_status=" & Final_Stabilized_Diagnostic_Status'Image (Status));
   end Detail_For;

   function Make_Row
     (Source : Closure.Final_Stabilized_Closure_Row;
      Index  : Positive) return Final_Stabilized_Diagnostic_Row is
      Status : constant Final_Stabilized_Diagnostic_Status := Status_For (Source.Status);
      Family : constant Final_Stabilized_Diagnostic_Family := Family_For (Status, Source.Blocker_Family);
      Result : Final_Stabilized_Diagnostic_Row;
   begin
      Result.Id := Final_Stabilized_Diagnostic_Id (Index);
      Result.Closure_Id := Source.Id;
      Result.Closure_Status := Source.Status;
      Result.Closure_Action := Source.Action;
      Result.Status := Status;
      Result.Family := Family;
      Result.Severity := Severity_For (Status);
      Result.Blocker_Family := Source.Blocker_Family;
      Result.Node := Source.Node;
      Result.Start_Line := Source.Start_Line;
      Result.Start_Column := Source.Start_Column;
      Result.End_Line := Source.End_Line;
      Result.End_Column := Source.End_Column;
      Result.Priority := Source.Priority;
      Result.Dependency_Depth := Source.Dependency_Depth;
      Result.Prerequisite_Depth := Source.Prerequisite_Depth;
      Result.Emitted := Is_Emitted (Status);
      Result.Withheld_Current := Is_Withheld_Current (Status);
      Result.Requires_Recheck := Status = Final_Stabilized_Diagnostic_Recheck_Required;
      Result.Message := Message_For (Status, Family);
      Result.Detail := Detail_For (Source, Status);
      Result.Source_Fingerprint := Source.Source_Fingerprint;
      Result.Closure_Fingerprint := Source.Closure_Fingerprint;
      Result.Diagnostic_Fingerprint := Mix (Natural (Result.Id), Source.Closure_Fingerprint);
      Result.Diagnostic_Fingerprint := Mix
        (Result.Diagnostic_Fingerprint,
         Final_Stabilized_Diagnostic_Status'Pos (Status) + 1);
      Result.Diagnostic_Fingerprint := Mix
        (Result.Diagnostic_Fingerprint,
         Final_Stabilized_Diagnostic_Family'Pos (Family) + 1);
      Result.Diagnostic_Fingerprint := Mix
        (Result.Diagnostic_Fingerprint,
         Final_Blocker_Family'Pos (Source.Blocker_Family) + 1);
      return Result;
   end Make_Row;

   procedure Append
     (Set : in out Final_Stabilized_Diagnostic_Set;
      Row : Final_Stabilized_Diagnostic_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Diagnostic_Fingerprint);
   end Append;

   procedure Note
     (Model : in out Final_Stabilized_Diagnostic_Model;
      Row   : Final_Stabilized_Diagnostic_Row) is
   begin
      case Row.Severity is
         when Final_Stabilized_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Final_Stabilized_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Final_Stabilized_Diagnostic_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;

      if Row.Emitted then
         Model.Emitted_Total := Model.Emitted_Total + 1;
      end if;
      if Row.Withheld_Current then
         Model.Withheld_Current_Total := Model.Withheld_Current_Total + 1;
      end if;
      if Row.Requires_Recheck then
         Model.Recheck_Total := Model.Recheck_Total + 1;
      end if;

      case Row.Status is
         when Final_Stabilized_Diagnostic_Preserved_Semantic_Error =>
            Model.Preserved_Error_Total := Model.Preserved_Error_Total + 1;
         when Final_Stabilized_Diagnostic_Indeterminate
            | Final_Stabilized_Diagnostic_Not_Checked =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others =>
            null;
      end case;

      Model.Fingerprint := Mix (Model.Fingerprint, Row.Diagnostic_Fingerprint);
   end Note;

   procedure Clear (Model : in out Final_Stabilized_Diagnostic_Model) is
   begin
      Model.Rows.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Emitted_Total := 0;
      Model.Withheld_Current_Total := 0;
      Model.Recheck_Total := 0;
      Model.Preserved_Error_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Closure_Model : Closure.Final_Stabilized_Closure_Model)
      return Final_Stabilized_Diagnostic_Model is
      Result : Final_Stabilized_Diagnostic_Model;
   begin
      for Index in 1 .. Closure.Row_Count (Closure_Model) loop
         declare
            Row : constant Final_Stabilized_Diagnostic_Row :=
              Make_Row (Closure.Row_At (Closure_Model, Index), Index);
         begin
            Result.Rows.Append (Row);
            Note (Result, Row);
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Stabilized_Diagnostic_Model;
      Index : Positive) return Final_Stabilized_Diagnostic_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Final_Stabilized_Diagnostic_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Final_Stabilized_Diagnostic_Set;
      Index : Positive) return Final_Stabilized_Diagnostic_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Final_Stabilized_Diagnostic_Model;
      Status : Final_Stabilized_Diagnostic_Status) return Final_Stabilized_Diagnostic_Set is
      Result : Final_Stabilized_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Family
     (Model  : Final_Stabilized_Diagnostic_Model;
      Family : Final_Stabilized_Diagnostic_Family) return Final_Stabilized_Diagnostic_Set is
      Result : Final_Stabilized_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Family;

   function Query_Blocker
     (Model   : Final_Stabilized_Diagnostic_Model;
      Blocker : Final_Blocker_Family) return Final_Stabilized_Diagnostic_Set is
      Result : Final_Stabilized_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker;

   function Query_Node
     (Model : Final_Stabilized_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Stabilized_Diagnostic_Set is
      Result : Final_Stabilized_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Count_Status
     (Model  : Final_Stabilized_Diagnostic_Model;
      Status : Final_Stabilized_Diagnostic_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Family
     (Model  : Final_Stabilized_Diagnostic_Model;
      Family : Final_Stabilized_Diagnostic_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Count_Blocker
     (Model   : Final_Stabilized_Diagnostic_Model;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Error_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Emitted_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Withheld_Current_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Withheld_Current_Total;
   end Withheld_Current_Count;

   function Recheck_Required_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Preserved_Error_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Preserved_Error_Total;
   end Preserved_Error_Count;

   function Indeterminate_Count (Model : Final_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Final_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration;
