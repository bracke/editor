with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration is

   pragma Suppress (Overflow_Check);
   use type Closure.Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 1) mod 1_000_000_007;
   end Mix;

   function Status_For
     (Status : Remaining_RM_Edge_Stabilized_Closure_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status is
   begin
      case Status is
         when Closure.Remaining_RM_Edge_Stabilized_Closure_Accepted_Current =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Current;
         when Closure.Remaining_RM_Edge_Stabilized_Closure_Accepted_Not_Required =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Not_Required;
         when Closure.Remaining_RM_Edge_Stabilized_Closure_Blocker_Remaining_Edge =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Remaining_Edge_Blocker;
         when Closure.Remaining_RM_Edge_Stabilized_Closure_Blocker_Stabilized_Closure =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Stabilized_Closure_Blocker;
         when Closure.Remaining_RM_Edge_Stabilized_Closure_Blocker_Source_Fingerprint =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Source_Fingerprint_Mismatch;
         when Closure.Remaining_RM_Edge_Stabilized_Closure_Blocker_Substitution_Fingerprint =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Substitution_Fingerprint_Mismatch;
         when Closure.Remaining_RM_Edge_Stabilized_Closure_Blocker_Multiple_Prerequisites =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Multiple_Prerequisites;
         when Closure.Remaining_RM_Edge_Stabilized_Closure_Recheck_Required =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Recheck_Required;
         when Closure.Remaining_RM_Edge_Stabilized_Closure_Indeterminate =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Indeterminate;
         when Closure.Remaining_RM_Edge_Stabilized_Closure_Not_Checked =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Not_Checked;
      end case;
   end Status_For;

   function Family_For
     (Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family is
   begin
      case Status is
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Current |
              Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Not_Required =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Accepted;
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Remaining_Edge_Blocker =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Remaining_Edge;
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Stabilized_Closure_Blocker =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Stabilized_Closure;
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Source_Fingerprint_Mismatch =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Source_Fingerprint;
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Substitution_Fingerprint_Mismatch =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Substitution_Fingerprint;
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Multiple_Prerequisites =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Multiple;
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Recheck_Required =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Recheck_Required;
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Indeterminate |
              Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Not_Checked =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Indeterminate;
      end case;
   end Family_For;

   function Severity_For
     (Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Severity is
   begin
      case Status is
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Current |
              Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Not_Required =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Info;
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Source_Fingerprint_Mismatch |
              Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Substitution_Fingerprint_Mismatch |
              Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Recheck_Required |
              Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Indeterminate |
              Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Not_Checked =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Warning;
         when others =>
            return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Error;
      end case;
   end Severity_For;

   function Is_Withheld_Current (Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status) return Boolean is
   begin
      return Status = Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Current
        or else Status = Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Not_Required;
   end Is_Withheld_Current;

   function Is_Emitted (Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status) return Boolean is
   begin
      return Status /= Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Not_Checked
        and then not Is_Withheld_Current (Status);
   end Is_Emitted;

   function Message_For
     (Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status;
      Family : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family;
      Edge_Kind : Remaining_RM_Edge_Kind;
      Edge_Blocker : Remaining_RM_Edge_Blocker_Family) return Unbounded_String is
   begin
      if Is_Withheld_Current (Status) then
         return To_Unbounded_String ("remaining RM edge stabilized closure evidence is current");
      elsif Status = Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Recheck_Required then
         return To_Unbounded_String ("remaining RM edge stabilized closure requires bounded recheck before diagnostic trust");
      elsif Status = Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Indeterminate then
         return To_Unbounded_String ("remaining RM edge stabilized closure remains indeterminate");
      else
         return To_Unbounded_String
           ("remaining RM edge stabilized closure blocker: " &
            Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family'Image (Family) &
            " edge=" & Edge.Remaining_RM_Edge_Kind'Image (Edge_Kind) &
            " edge_blocker=" & Edge.Remaining_RM_Edge_Blocker_Family'Image (Edge_Blocker));
      end if;
   end Message_For;

   function Make_Row
     (Source : Closure.Remaining_RM_Edge_Stabilized_Closure_Row;
      Index  : Positive) return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row is
      Status : constant Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status := Status_For (Source.Status);
      Family : constant Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family := Family_For (Status);
      Row    : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row;
   begin
      Row.Id := Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Id (Index);
      Row.Closure_Row := Source.Id;
      Row.Stabilization_Id := Source.Stabilization_Id;
      Row.Convergence_Id := Source.Convergence_Id;
      Row.Application_Id := Source.Application_Id;
      Row.Eligibility_Id := Source.Eligibility_Id;
      Row.Worklist_Item := Source.Worklist_Item;
      Row.Prior_Diagnostic_Row := Source.Diagnostic_Row;
      Row.Closure_Status := Source.Status;
      Row.Closure_Action := Source.Action;
      Row.Closure_Family := Source.Family;
      Row.Status := Status;
      Row.Family := Family;
      Row.Severity := Severity_For (Status);
      Row.Remaining_Edge_Kind := Source.Remaining_Edge_Kind;
      Row.Remaining_Edge_Blocker := Source.Remaining_Edge_Blocker;
      Row.Node := Source.Node;
      Row.Message := Message_For (Status, Family, Source.Remaining_Edge_Kind, Source.Remaining_Edge_Blocker);
      Row.Detail := To_Unbounded_String
        ("Case 1292 maps stabilized remaining RM edge closure rows into the diagnostic/feed boundary while preserving remaining-edge, stabilized-closure, fingerprint, multiple-prerequisite, recheck, and indeterminate blocker identity.");
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Edge_Fingerprint := Source.Edge_Fingerprint;
      Row.Consumer_Closure_Fingerprint := Source.Consumer_Closure_Fingerprint;
      Row.Prior_Diagnostic_Fingerprint := Source.Diagnostic_Fingerprint;
      Row.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Row.Application_Fingerprint := Source.Application_Fingerprint;
      Row.Convergence_Fingerprint := Source.Convergence_Fingerprint;
      Row.Stabilization_Fingerprint := Source.Stabilization_Fingerprint;
      Row.Closure_Fingerprint := Source.Closure_Fingerprint;
      Row.Emitted := Is_Emitted (Status);
      Row.Withheld_Current := Is_Withheld_Current (Status);
      Row.Requires_Recheck := Status = Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Recheck_Required;
      Row.Blocks_Downstream := Row.Emitted or else Source.Blocks_Downstream;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Diagnostic_Fingerprint := Mix (12_920, Natural (Row.Id));
      Row.Diagnostic_Fingerprint := Mix
        (Row.Diagnostic_Fingerprint,
         Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status'Pos (Status) + 1);
      Row.Diagnostic_Fingerprint := Mix
        (Row.Diagnostic_Fingerprint,
         Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family'Pos (Family) + 1);
      Row.Diagnostic_Fingerprint := Mix
        (Row.Diagnostic_Fingerprint,
         Closure.Remaining_RM_Edge_Stabilized_Closure_Status'Pos (Source.Status) + 1);
      Row.Diagnostic_Fingerprint := Mix
        (Row.Diagnostic_Fingerprint,
         Edge.Remaining_RM_Edge_Kind'Pos (Source.Remaining_Edge_Kind) + 1);
      Row.Diagnostic_Fingerprint := Mix
        (Row.Diagnostic_Fingerprint,
         Edge.Remaining_RM_Edge_Blocker_Family'Pos (Source.Remaining_Edge_Blocker) + 1);
      Row.Diagnostic_Fingerprint := Mix (Row.Diagnostic_Fingerprint, Source.Closure_Fingerprint);
      return Row;
   end Make_Row;

   procedure Note
     (Model : in out Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Row   : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row) is
   begin
      case Row.Severity is
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Info =>
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
      if Row.Status = Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Diagnostic_Fingerprint);
   end Note;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) is
   begin
      Model.Rows.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Emitted_Total := 0;
      Model.Withheld_Current_Total := 0;
      Model.Recheck_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Closures : Closure.Remaining_RM_Edge_Stabilized_Closure_Model)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model is
      Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
   begin
      for I in 1 .. Closure.Row_Count (Closures) loop
         declare
            Row : constant Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row :=
              Make_Row (Closure.Row_At (Closures, I), I);
         begin
            Model.Rows.Append (Row);
            Note (Model, Row);
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append
     (Set : in out Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
      Row : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Diagnostic_Fingerprint);
   end Append;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set is
      Set : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set is
      Set : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Closure_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set is
      Set : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Closure_Family = Family then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Closure_Family;

   function Query_Node
     (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set is
      Set : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set is
      Set : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Count_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Count_Closure_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family) return Natural is
   begin
      return Query_Count (Query_Closure_Family (Model, Family));
   end Count_Closure_Family;

   function Error_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Emitted_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Withheld_Current_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural is
   begin
      return Model.Withheld_Current_Total;
   end Withheld_Current_Count;

   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration;
