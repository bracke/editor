with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration is

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 2_167) mod 2_147_483_647;
   end Mix;

   function Is_Emitted (Status : Shared_State_Stabilized_Status) return Boolean is
   begin
      return Status not in Shared_State_Stabilized_Not_Checked |
                           Shared_State_Stabilized_Withheld_Accepted_Current;
   end Is_Emitted;

   function Is_Withheld_Current (Status : Shared_State_Stabilized_Status) return Boolean is
   begin
      return Status = Shared_State_Stabilized_Withheld_Accepted_Current;
   end Is_Withheld_Current;

   function Has_Error (Row : Shared_State_Stabilized_Row) return Boolean is
   begin
      return Row.Severity = Shared_State_Stabilized_Error;
   end Has_Error;

   procedure Clear (Model : in out Shared_State_Stabilized_Model) is
   begin
      Model.Rows.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Emitted_Total := 0;
      Model.Withheld_Current_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Status_For
     (Status : Cross_Shared.Cross_Unit_Shared_State_Status)
      return Shared_State_Stabilized_Status is
   begin
      if Cross_Shared.Is_Legal (Status) then
         return Shared_State_Stabilized_Withheld_Accepted_Current;
      elsif Cross_Shared.Is_Dependency_Error (Status) then
         return Shared_State_Stabilized_Dependency_Blocker;
      elsif Cross_Shared.Is_View_Error (Status) then
         return Shared_State_Stabilized_View_Barrier;
      elsif Cross_Shared.Is_Representation_Error (Status) then
         return Shared_State_Stabilized_Representation_Blocker;
      elsif Cross_Shared.Is_Tasking_Error (Status) then
         return Shared_State_Stabilized_Tasking_Protected_Blocker;
      elsif Cross_Shared.Is_Shared_State_Error (Status) then
         case Status is
            when Cross_Shared.Cross_Unit_Shared_State_Missing_Abstract_State_Row |
                 Cross_Shared.Cross_Unit_Shared_State_Abstract_State_Blocker |
                 Cross_Shared.Cross_Unit_Shared_State_Abstract_Constituent_Blocker =>
               return Shared_State_Stabilized_Abstract_State_Blocker;
            when Cross_Shared.Cross_Unit_Shared_State_Overload_State_Blocker |
                 Cross_Shared.Cross_Unit_Shared_State_Missing_Overload_State_Row =>
               return Shared_State_Stabilized_Overload_Type_Blocker;
            when others =>
               return Shared_State_Stabilized_Shared_State_Blocker;
         end case;
      elsif Cross_Shared.Is_Indeterminate (Status) then
         return Shared_State_Stabilized_Indeterminate;
      else
         case Status is
            when Cross_Shared.Cross_Unit_Shared_State_Missing_Cross_Unit_Row |
                 Cross_Shared.Cross_Unit_Shared_State_Cross_Unit_Blocker =>
               return Shared_State_Stabilized_Cross_Unit_Blocker;
            when Cross_Shared.Cross_Unit_Shared_State_Generic_Backmapping_Blocker |
                 Cross_Shared.Cross_Unit_Shared_State_Generic_Body_Unavailable =>
               return Shared_State_Stabilized_Generic_Backmapping_Blocker;
            when Cross_Shared.Cross_Unit_Shared_State_State_Visibility_Blocker =>
               return Shared_State_Stabilized_State_Visibility_Blocker;
            when Cross_Shared.Cross_Unit_Shared_State_Source_Fingerprint_Mismatch =>
               return Shared_State_Stabilized_Source_Fingerprint_Mismatch;
            when Cross_Shared.Cross_Unit_Shared_State_Multiple_Blockers =>
               return Shared_State_Stabilized_Multiple_Blockers;
            when others =>
               return Shared_State_Stabilized_Indeterminate;
         end case;
      end if;
   end Status_For;

   function Family_For
     (Status : Shared_State_Stabilized_Status) return Shared_State_Stabilized_Family is
   begin
      case Status is
         when Shared_State_Stabilized_Withheld_Accepted_Current =>
            return Shared_State_Stabilized_Diagnostic_Accepted;
         when Shared_State_Stabilized_Cross_Unit_Blocker =>
            return Shared_State_Stabilized_Diagnostic_Cross_Unit;
         when Shared_State_Stabilized_Abstract_State_Blocker =>
            return Shared_State_Stabilized_Diagnostic_Abstract_State;
         when Shared_State_Stabilized_Shared_State_Blocker =>
            return Shared_State_Stabilized_Diagnostic_Volatile_Atomic;
         when Shared_State_Stabilized_Overload_Type_Blocker =>
            return Shared_State_Stabilized_Diagnostic_Overload_Type;
         when Shared_State_Stabilized_Representation_Blocker =>
            return Shared_State_Stabilized_Diagnostic_Representation;
         when Shared_State_Stabilized_Tasking_Protected_Blocker =>
            return Shared_State_Stabilized_Diagnostic_Tasking_Protected;
         when Shared_State_Stabilized_Dependency_Blocker =>
            return Shared_State_Stabilized_Diagnostic_Dependency;
         when Shared_State_Stabilized_View_Barrier =>
            return Shared_State_Stabilized_Diagnostic_View_Barrier;
         when Shared_State_Stabilized_Generic_Backmapping_Blocker =>
            return Shared_State_Stabilized_Diagnostic_Generic_Backmapping;
         when Shared_State_Stabilized_State_Visibility_Blocker =>
            return Shared_State_Stabilized_Diagnostic_State_Visibility;
         when Shared_State_Stabilized_Source_Fingerprint_Mismatch =>
            return Shared_State_Stabilized_Diagnostic_Fingerprint;
         when Shared_State_Stabilized_Multiple_Blockers =>
            return Shared_State_Stabilized_Diagnostic_Multiple;
         when Shared_State_Stabilized_Indeterminate =>
            return Shared_State_Stabilized_Diagnostic_Indeterminate;
         when Shared_State_Stabilized_Not_Checked =>
            return Shared_State_Stabilized_Diagnostic_Unknown;
      end case;
   end Family_For;

   function Severity_For
     (Status : Shared_State_Stabilized_Status) return Shared_State_Stabilized_Severity is
   begin
      case Status is
         when Shared_State_Stabilized_Withheld_Accepted_Current =>
            return Shared_State_Stabilized_Info;
         when Shared_State_Stabilized_Indeterminate =>
            return Shared_State_Stabilized_Warning;
         when others =>
            return Shared_State_Stabilized_Error;
      end case;
   end Severity_For;

   function Message_For
     (Status : Shared_State_Stabilized_Status) return Unbounded_String is
   begin
      case Status is
         when Shared_State_Stabilized_Withheld_Accepted_Current =>
            return To_Unbounded_String ("shared-state closure stabilized and withheld as current semantic evidence");
         when Shared_State_Stabilized_Cross_Unit_Blocker =>
            return To_Unbounded_String ("cross-unit shared-state closure is blocked");
         when Shared_State_Stabilized_Abstract_State_Blocker =>
            return To_Unbounded_String ("abstract/refined state evidence blocks shared-state closure");
         when Shared_State_Stabilized_Shared_State_Blocker =>
            return To_Unbounded_String ("volatile/atomic/shared-variable evidence blocks shared-state closure");
         when Shared_State_Stabilized_Overload_Type_Blocker =>
            return To_Unbounded_String ("overload/type shared-state evidence blocks shared-state closure");
         when Shared_State_Stabilized_Representation_Blocker =>
            return To_Unbounded_String ("representation/freezing shared-state evidence blocks closure");
         when Shared_State_Stabilized_Tasking_Protected_Blocker =>
            return To_Unbounded_String ("tasking/protected shared-state evidence blocks closure");
         when Shared_State_Stabilized_Dependency_Blocker =>
            return To_Unbounded_String ("cross-unit dependency blocks shared-state closure");
         when Shared_State_Stabilized_View_Barrier =>
            return To_Unbounded_String ("view barrier blocks shared-state closure");
         when Shared_State_Stabilized_Generic_Backmapping_Blocker =>
            return To_Unbounded_String ("generic body/backmapping blocks shared-state closure");
         when Shared_State_Stabilized_State_Visibility_Blocker =>
            return To_Unbounded_String ("abstract/shared state visibility blocks closure");
         when Shared_State_Stabilized_Source_Fingerprint_Mismatch =>
            return To_Unbounded_String ("shared-state closure source fingerprint mismatch");
         when Shared_State_Stabilized_Multiple_Blockers =>
            return To_Unbounded_String ("multiple shared-state closure blockers are present");
         when Shared_State_Stabilized_Indeterminate =>
            return To_Unbounded_String ("shared-state closure is indeterminate");
         when Shared_State_Stabilized_Not_Checked =>
            return To_Unbounded_String ("shared-state closure not checked");
      end case;
   end Message_For;

   function Row_Fingerprint (Row : Shared_State_Stabilized_Row) return Natural is
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Cross_Shared_Row));
      H := Mix (H, Cross_Shared.Cross_Unit_Shared_State_Status'Pos (Row.Cross_Shared_Status) + 1);
      H := Mix (H, Shared_State_Stabilized_Status'Pos (Row.Status) + 1);
      H := Mix (H, Shared_State_Stabilized_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Closure_Fingerprint);
      return H;
   end Row_Fingerprint;

   procedure Append_Row
     (Model : in out Shared_State_Stabilized_Model;
      Row   : in out Shared_State_Stabilized_Row) is
   begin
      Row.Diagnostic_Fingerprint := Row_Fingerprint (Row);
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Diagnostic_Fingerprint);
      case Row.Severity is
         when Shared_State_Stabilized_Error => Model.Error_Total := Model.Error_Total + 1;
         when Shared_State_Stabilized_Warning => Model.Warning_Total := Model.Warning_Total + 1;
         when Shared_State_Stabilized_Info => Model.Info_Total := Model.Info_Total + 1;
      end case;
      if Row.Emitted then
         Model.Emitted_Total := Model.Emitted_Total + 1;
      end if;
      if Row.Withheld_Current then
         Model.Withheld_Current_Total := Model.Withheld_Current_Total + 1;
      end if;
      if Row.Status = Shared_State_Stabilized_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Append_Row;

   function Build
     (Cross_Shared_Model : Cross_Shared.Cross_Unit_Shared_State_Model)
      return Shared_State_Stabilized_Model is
      Model : Shared_State_Stabilized_Model;
   begin
      for I in 1 .. Cross_Shared.Row_Count (Cross_Shared_Model) loop
         declare
            Source : constant Cross_Shared.Cross_Unit_Shared_State_Info :=
              Cross_Shared.Row_At (Cross_Shared_Model, I);
            Status : constant Shared_State_Stabilized_Status := Status_For (Source.Status);
            Row : Shared_State_Stabilized_Row;
         begin
            Row.Id := Shared_State_Stabilized_Diagnostic_Id (I);
            Row.Cross_Shared_Row := Source.Id;
            Row.Cross_Shared_Status := Source.Status;
            Row.Status := Status;
            Row.Family := Family_For (Status);
            Row.Severity := Severity_For (Status);
            Row.Node := Source.Node;
            Row.Unit_Name := Source.Unit_Name;
            Row.Dependency_Name := Source.Dependency_Name;
            Row.State_Name := Source.State_Name;
            Row.Emitted := Is_Emitted (Status);
            Row.Withheld_Current := Is_Withheld_Current (Status);
            Row.Message := Message_For (Status);
            Row.Detail := Source.Detail;
            Row.Source_Fingerprint := Source.Source_Fingerprint;
            Row.Closure_Fingerprint := Source.Fingerprint;
            Row.Start_Line := Source.Start_Line;
            Row.Start_Column := Source.Start_Column;
            Row.End_Line := Source.End_Line;
            Row.End_Column := Source.End_Column;
            Append_Row (Model, Row);
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Shared_State_Stabilized_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Shared_State_Stabilized_Model;
      Index : Positive) return Shared_State_Stabilized_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Shared_State_Stabilized_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Shared_State_Stabilized_Set;
      Index : Positive) return Shared_State_Stabilized_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Shared_State_Stabilized_Model;
      Status : Shared_State_Stabilized_Status) return Shared_State_Stabilized_Set is
      Set : Shared_State_Stabilized_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Diagnostic_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Family
     (Model  : Shared_State_Stabilized_Model;
      Family : Shared_State_Stabilized_Family) return Shared_State_Stabilized_Set is
      Set : Shared_State_Stabilized_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Diagnostic_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Node
     (Model : Shared_State_Stabilized_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Stabilized_Set is
      Set : Shared_State_Stabilized_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Diagnostic_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Count_Status
     (Model  : Shared_State_Stabilized_Model;
      Status : Shared_State_Stabilized_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Family
     (Model  : Shared_State_Stabilized_Model;
      Family : Shared_State_Stabilized_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Error_Count (Model : Shared_State_Stabilized_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Shared_State_Stabilized_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Shared_State_Stabilized_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Emitted_Count (Model : Shared_State_Stabilized_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Withheld_Current_Count (Model : Shared_State_Stabilized_Model) return Natural is
   begin
      return Model.Withheld_Current_Total;
   end Withheld_Current_Count;

   function Indeterminate_Count (Model : Shared_State_Stabilized_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Shared_State_Stabilized_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration;
