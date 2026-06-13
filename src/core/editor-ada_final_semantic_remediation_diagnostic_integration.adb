with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Blocker_Family;
   use type Final_Remediation_Diagnostic_Family;
   use type Final_Remediation_Diagnostic_Severity;
   use type Final_Remediation_Diagnostic_Status;
   use type Final_Remediation_Closure_Status;

   function Mix (Left : Natural; Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Left) * 16#0100_0193#
        + Hash_Value (Right)
        + 16#9E37_79B9#;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Family_For
     (Status  : Final_Remediation_Closure_Status;
      Blocker : Final_Blocker_Family) return Final_Remediation_Diagnostic_Family is
   begin
      case Status is
         when Closure.Final_Remediation_Closure_Stale_Blocker =>
            return Final_Remediation_Diagnostic_Stale_Input;
         when Closure.Final_Remediation_Closure_AST_Coverage_Blocker =>
            return Final_Remediation_Diagnostic_AST_Coverage;
         when Closure.Final_Remediation_Closure_Cross_Unit_Blocker =>
            return Final_Remediation_Diagnostic_Cross_Unit;
         when Closure.Final_Remediation_Closure_View_Blocker =>
            return Final_Remediation_Diagnostic_View_Barrier;
         when Closure.Final_Remediation_Closure_Generic_Replay_Blocker =>
            return Final_Remediation_Diagnostic_Generic_Replay;
         when Closure.Final_Remediation_Closure_Overload_Type_Blocker =>
            return Final_Remediation_Diagnostic_Overload_Type;
         when Closure.Final_Remediation_Closure_Representation_Freezing_Blocker =>
            return Final_Remediation_Diagnostic_Representation_Freezing;
         when Closure.Final_Remediation_Closure_Flow_Contract_Blocker =>
            return Final_Remediation_Diagnostic_Flow_Contract;
         when Closure.Final_Remediation_Closure_Tasking_Protected_Blocker =>
            return Final_Remediation_Diagnostic_Tasking_Protected;
         when Closure.Final_Remediation_Closure_Elaboration_Blocker =>
            return Final_Remediation_Diagnostic_Elaboration;
         when Closure.Final_Remediation_Closure_Accessibility_Lifetime_Blocker =>
            return Final_Remediation_Diagnostic_Accessibility_Lifetime;
         when Closure.Final_Remediation_Closure_Discriminant_Variant_Blocker =>
            return Final_Remediation_Diagnostic_Discriminant_Variant;
         when Closure.Final_Remediation_Closure_Multiple_Blockers =>
            return Final_Remediation_Diagnostic_Multiple;
         when others =>
            case Blocker is
               when Final_Prov.Final_Blocker_Cross_Unit =>
                  return Final_Remediation_Diagnostic_Cross_Unit;
               when Final_Prov.Final_Blocker_Generic_Replay =>
                  return Final_Remediation_Diagnostic_Generic_Replay;
               when Final_Prov.Final_Blocker_Representation_Freezing =>
                  return Final_Remediation_Diagnostic_Representation_Freezing;
               when Final_Prov.Final_Blocker_Flow_Contract =>
                  return Final_Remediation_Diagnostic_Flow_Contract;
               when Final_Prov.Final_Blocker_Tasking_Protected =>
                  return Final_Remediation_Diagnostic_Tasking_Protected;
               when Final_Prov.Final_Blocker_Elaboration =>
                  return Final_Remediation_Diagnostic_Elaboration;
               when Final_Prov.Final_Blocker_Accessibility_Lifetime =>
                  return Final_Remediation_Diagnostic_Accessibility_Lifetime;
               when Final_Prov.Final_Blocker_Discriminant_Variant =>
                  return Final_Remediation_Diagnostic_Discriminant_Variant;
               when Final_Prov.Final_Blocker_AST_Repair | Final_Prov.Final_Blocker_Coverage_Gate =>
                  return Final_Remediation_Diagnostic_AST_Coverage;
               when Final_Prov.Final_Blocker_View_Barrier =>
                  return Final_Remediation_Diagnostic_View_Barrier;
               when Final_Prov.Final_Blocker_Overload_Type =>
                  return Final_Remediation_Diagnostic_Overload_Type;
               when Final_Prov.Final_Blocker_Multiple =>
                  return Final_Remediation_Diagnostic_Multiple;
               when others =>
                  return Final_Remediation_Diagnostic_Unknown;
            end case;
      end case;
   end Family_For;

   function Status_For
     (Status : Final_Remediation_Closure_Status) return Final_Remediation_Diagnostic_Status is
   begin
      case Status is
         when Closure.Final_Remediation_Closure_Legal_Local
            | Closure.Final_Remediation_Closure_Legal_Derived =>
            return Final_Remediation_Diagnostic_Withheld_Legal;
         when Closure.Final_Remediation_Closure_Stale_Blocker =>
            return Final_Remediation_Diagnostic_Stale_Prerequisite;
         when Closure.Final_Remediation_Closure_AST_Coverage_Blocker =>
            return Final_Remediation_Diagnostic_AST_Coverage_Prerequisite;
         when Closure.Final_Remediation_Closure_Cross_Unit_Blocker =>
            return Final_Remediation_Diagnostic_Cross_Unit_Prerequisite;
         when Closure.Final_Remediation_Closure_View_Blocker =>
            return Final_Remediation_Diagnostic_View_Prerequisite;
         when Closure.Final_Remediation_Closure_Generic_Replay_Blocker =>
            return Final_Remediation_Diagnostic_Generic_Replay_Prerequisite;
         when Closure.Final_Remediation_Closure_Overload_Type_Blocker =>
            return Final_Remediation_Diagnostic_Overload_Type_Prerequisite;
         when Closure.Final_Remediation_Closure_Representation_Freezing_Blocker =>
            return Final_Remediation_Diagnostic_Representation_Freezing_Prerequisite;
         when Closure.Final_Remediation_Closure_Flow_Contract_Blocker =>
            return Final_Remediation_Diagnostic_Flow_Contract_Prerequisite;
         when Closure.Final_Remediation_Closure_Tasking_Protected_Blocker =>
            return Final_Remediation_Diagnostic_Tasking_Protected_Prerequisite;
         when Closure.Final_Remediation_Closure_Elaboration_Blocker =>
            return Final_Remediation_Diagnostic_Elaboration_Prerequisite;
         when Closure.Final_Remediation_Closure_Accessibility_Lifetime_Blocker =>
            return Final_Remediation_Diagnostic_Accessibility_Lifetime_Prerequisite;
         when Closure.Final_Remediation_Closure_Discriminant_Variant_Blocker =>
            return Final_Remediation_Diagnostic_Discriminant_Variant_Prerequisite;
         when Closure.Final_Remediation_Closure_Multiple_Blockers =>
            return Final_Remediation_Diagnostic_Multiple_Prerequisites;
         when Closure.Final_Remediation_Closure_Preserved_Semantic_Error =>
            return Final_Remediation_Diagnostic_Preserved_Semantic_Error;
         when Closure.Final_Remediation_Closure_Indeterminate =>
            return Final_Remediation_Diagnostic_Indeterminate;
         when Closure.Final_Remediation_Closure_Not_Checked =>
            return Final_Remediation_Diagnostic_Not_Checked;
      end case;
   end Status_For;

   function Severity_For
     (Status : Final_Remediation_Diagnostic_Status) return Final_Remediation_Diagnostic_Severity is
   begin
      case Status is
         when Final_Remediation_Diagnostic_Withheld_Legal =>
            return Final_Remediation_Diagnostic_Info;
         when Final_Remediation_Diagnostic_Stale_Prerequisite
            | Final_Remediation_Diagnostic_View_Prerequisite
            | Final_Remediation_Diagnostic_Indeterminate
            | Final_Remediation_Diagnostic_Not_Checked =>
            return Final_Remediation_Diagnostic_Warning;
         when others =>
            return Final_Remediation_Diagnostic_Error;
      end case;
   end Severity_For;

   function Message_For
     (Status : Final_Remediation_Diagnostic_Status;
      Family : Final_Remediation_Diagnostic_Family) return Unbounded_String is
   begin
      if Status = Final_Remediation_Diagnostic_Withheld_Legal then
         return To_Unbounded_String ("final remediation closure accepted");
      elsif Status = Final_Remediation_Diagnostic_Preserved_Semantic_Error then
         return To_Unbounded_String ("final remediation closure preserves original semantic error");
      elsif Status = Final_Remediation_Diagnostic_Indeterminate then
         return To_Unbounded_String ("final remediation closure remains indeterminate");
      else
         return To_Unbounded_String
           ("final remediation prerequisite blocker: "
            & Final_Remediation_Diagnostic_Family'Image (Family));
      end if;
   end Message_For;

   function Detail_For
     (Row    : Closure.Final_Remediation_Closure_Row;
      Status : Final_Remediation_Diagnostic_Status) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("closure_status=" & Final_Remediation_Closure_Status'Image (Row.Status)
         & "; gate_status=" & Closure.Final_Gate_Status'Image (Row.Gate_Status)
         & "; gate_action=" & Closure.Final_Gate_Action'Image (Row.Gate_Action)
         & "; diagnostic_status=" & Final_Remediation_Diagnostic_Status'Image (Status));
   end Detail_For;

   function From_Closure
     (Id     : Final_Remediation_Diagnostic_Id;
      Source : Closure.Final_Remediation_Closure_Row)
      return Final_Remediation_Diagnostic_Row is
      Status : constant Final_Remediation_Diagnostic_Status := Status_For (Source.Status);
      Family : constant Final_Remediation_Diagnostic_Family :=
        Family_For (Source.Status, Source.Blocker_Family);
      Result : Final_Remediation_Diagnostic_Row;
   begin
      Result.Id := Id;
      Result.Closure_Id := Source.Id;
      Result.Closure_Status := Source.Status;
      Result.Status := Status;
      Result.Family := Family;
      Result.Severity := Severity_For (Status);
      Result.Blocker_Family := Source.Blocker_Family;
      Result.Node := Source.Node;
      Result.Start_Line := Source.Start_Line;
      Result.Start_Column := Source.Start_Column;
      Result.End_Line := Source.End_Line;
      Result.End_Column := Source.End_Column;
      Result.Dependency_Order := Source.Dependency_Order;
      Result.Closure_Blocked := Source.Closure_Blocked;
      Result.Derived_Legal_Withheld := Source.Derived_Legal_Withheld;
      Result.Downstream_Blocked := Source.Downstream_Blocked;
      Result.Message := Message_For (Status, Family);
      Result.Detail := Detail_For (Source, Status);
      Result.Source_Fingerprint := Source.Source_Fingerprint;
      Result.Closure_Fingerprint := Source.Fingerprint;
      Result.Fingerprint := Mix (Natural (Id), Source.Fingerprint);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Natural (Final_Remediation_Diagnostic_Status'Pos (Status)));
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Natural (Final_Remediation_Diagnostic_Family'Pos (Family)));
      Result.Fingerprint := Mix (Result.Fingerprint, Result.Downstream_Blocked);
      return Result;
   end From_Closure;

   procedure Note
     (Model : in out Final_Remediation_Diagnostic_Model;
      Row   : Final_Remediation_Diagnostic_Row) is
   begin
      case Row.Severity is
         when Final_Remediation_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Final_Remediation_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Final_Remediation_Diagnostic_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;

      if Is_Emitted (Row.Status) then
         Model.Emitted_Total := Model.Emitted_Total + 1;
      else
         Model.Withheld_Legal_Total := Model.Withheld_Legal_Total + 1;
      end if;

      case Row.Status is
         when Final_Remediation_Diagnostic_Stale_Prerequisite =>
            Model.Stale_Total := Model.Stale_Total + 1;
         when Final_Remediation_Diagnostic_Preserved_Semantic_Error =>
            Model.Preserved_Error_Total := Model.Preserved_Error_Total + 1;
         when Final_Remediation_Diagnostic_Indeterminate
            | Final_Remediation_Diagnostic_Not_Checked =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others =>
            null;
      end case;

      Model.Downstream_Blocked_Total :=
        Model.Downstream_Blocked_Total + Row.Downstream_Blocked;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
   end Note;

   procedure Append
     (Set : in out Final_Remediation_Diagnostic_Set;
      Row : Final_Remediation_Diagnostic_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
   end Append;

   procedure Clear (Model : in out Final_Remediation_Diagnostic_Model) is
   begin
      Model.Rows.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Withheld_Legal_Total := 0;
      Model.Emitted_Total := 0;
      Model.Stale_Total := 0;
      Model.Preserved_Error_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Downstream_Blocked_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Closure_Model : Closure.Final_Remediation_Closure_Model)
      return Final_Remediation_Diagnostic_Model is
      Model : Final_Remediation_Diagnostic_Model;
   begin
      for Index in 1 .. Closure.Row_Count (Closure_Model) loop
         declare
            Row : constant Final_Remediation_Diagnostic_Row :=
              From_Closure
                (Final_Remediation_Diagnostic_Id (Index),
                 Closure.Row_At (Closure_Model, Index));
         begin
            Model.Rows.Append (Row);
            Note (Model, Row);
         end;
      end loop;
      Model.Fingerprint := Mix (Model.Fingerprint, Closure.Fingerprint (Closure_Model));
      return Model;
   end Build;

   function Row_Count (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Remediation_Diagnostic_Model;
      Index : Positive) return Final_Remediation_Diagnostic_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Set_Count (Set : Final_Remediation_Diagnostic_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At
     (Set   : Final_Remediation_Diagnostic_Set;
      Index : Positive) return Final_Remediation_Diagnostic_Row is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Query_Status
     (Model  : Final_Remediation_Diagnostic_Model;
      Status : Final_Remediation_Diagnostic_Status) return Final_Remediation_Diagnostic_Set is
      Set : Final_Remediation_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Family
     (Model  : Final_Remediation_Diagnostic_Model;
      Family : Final_Remediation_Diagnostic_Family) return Final_Remediation_Diagnostic_Set is
      Set : Final_Remediation_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Blocker
     (Model   : Final_Remediation_Diagnostic_Model;
      Blocker : Final_Blocker_Family) return Final_Remediation_Diagnostic_Set is
      Set : Final_Remediation_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Blocker;

   function Query_Node
     (Model : Final_Remediation_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Remediation_Diagnostic_Set is
      Set : Final_Remediation_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Count_Status
     (Model  : Final_Remediation_Diagnostic_Model;
      Status : Final_Remediation_Diagnostic_Status) return Natural is
   begin
      return Set_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Family
     (Model  : Final_Remediation_Diagnostic_Model;
      Family : Final_Remediation_Diagnostic_Family) return Natural is
   begin
      return Set_Count (Query_Family (Model, Family));
   end Count_Family;

   function Count_Blocker
     (Model   : Final_Remediation_Diagnostic_Model;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      return Set_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Error_Count (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Withheld_Legal_Count (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Model.Withheld_Legal_Total;
   end Withheld_Legal_Count;

   function Emitted_Count (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Stale_Count (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Count;

   function Preserved_Error_Count (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Model.Preserved_Error_Total;
   end Preserved_Error_Count;

   function Indeterminate_Count (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Downstream_Blocked_Count (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Model.Downstream_Blocked_Total;
   end Downstream_Blocked_Count;

   function Fingerprint (Model : Final_Remediation_Diagnostic_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Is_Emitted (Status : Final_Remediation_Diagnostic_Status) return Boolean is
   begin
      return Status /= Final_Remediation_Diagnostic_Withheld_Legal;
   end Is_Emitted;

   function Is_Blocker (Status : Final_Remediation_Diagnostic_Status) return Boolean is
   begin
      return Status in
        Final_Remediation_Diagnostic_Stale_Prerequisite |
        Final_Remediation_Diagnostic_AST_Coverage_Prerequisite |
        Final_Remediation_Diagnostic_Cross_Unit_Prerequisite |
        Final_Remediation_Diagnostic_View_Prerequisite |
        Final_Remediation_Diagnostic_Generic_Replay_Prerequisite |
        Final_Remediation_Diagnostic_Overload_Type_Prerequisite |
        Final_Remediation_Diagnostic_Representation_Freezing_Prerequisite |
        Final_Remediation_Diagnostic_Flow_Contract_Prerequisite |
        Final_Remediation_Diagnostic_Tasking_Protected_Prerequisite |
        Final_Remediation_Diagnostic_Elaboration_Prerequisite |
        Final_Remediation_Diagnostic_Accessibility_Lifetime_Prerequisite |
        Final_Remediation_Diagnostic_Discriminant_Variant_Prerequisite |
        Final_Remediation_Diagnostic_Multiple_Prerequisites |
        Final_Remediation_Diagnostic_Preserved_Semantic_Error |
        Final_Remediation_Diagnostic_Indeterminate;
   end Is_Blocker;

end Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration;
