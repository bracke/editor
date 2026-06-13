with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration is
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 12_391) mod 2_147_483_647;
   end Mix;

   function Is_Emitted (Status : Generic_Shared_State_Final_Diagnostic_Status) return Boolean is
   begin
      return Status not in Generic_Shared_State_Final_Diagnostic_Not_Checked |
                           Generic_Shared_State_Final_Diagnostic_Withheld_Accepted_Current;
   end Is_Emitted;

   function Is_Withheld_Current (Status : Generic_Shared_State_Final_Diagnostic_Status) return Boolean is
   begin
      return Status = Generic_Shared_State_Final_Diagnostic_Withheld_Accepted_Current;
   end Is_Withheld_Current;

   function Has_Error (Row : Generic_Shared_State_Final_Diagnostic_Row) return Boolean is
   begin
      return Row.Severity = Generic_Shared_State_Final_Diagnostic_Error;
   end Has_Error;

   procedure Clear (Model : in out Generic_Shared_State_Final_Diagnostic_Model) is
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
     (Row : Dataflow_Generic.Dataflow_Generic_Final_Row)
      return Generic_Shared_State_Final_Diagnostic_Status is
      use type Dataflow_Generic.Dataflow_Generic_Final_Blocker_Family;
   begin
      if Row.Accepted then
         return Generic_Shared_State_Final_Diagnostic_Withheld_Accepted_Current;
      end if;

      case Row.Blocker_Family is
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Definite_Initialization =>
            return Generic_Shared_State_Final_Diagnostic_Definite_Initialization_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Dataflow_Initialization =>
            return Generic_Shared_State_Final_Diagnostic_Dataflow_Initialization_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Predicate_Dataflow =>
            return Generic_Shared_State_Final_Diagnostic_Predicate_Dataflow_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Predicate_Generic_Shared_State =>
            return Generic_Shared_State_Final_Diagnostic_Predicate_Generic_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Generic_Abstract_Replay =>
            return Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Stabilized_Shared_State_Closure =>
            return Generic_Shared_State_Final_Diagnostic_Stabilized_Closure_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Representation_Generic_Shared_State =>
            return Generic_Shared_State_Final_Diagnostic_Representation_Generic_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Tasking_Generic_Shared_State =>
            return Generic_Shared_State_Final_Diagnostic_Tasking_Generic_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Accessibility_Generic_Shared_State =>
            return Generic_Shared_State_Final_Diagnostic_Accessibility_Generic_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Discriminant_Generic_Shared_State =>
            return Generic_Shared_State_Final_Diagnostic_Discriminant_Generic_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Exception_Finalization_Generic_Shared_State =>
            return Generic_Shared_State_Final_Diagnostic_Exception_Finalization_Generic_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Renaming_Generic_Shared_State =>
            return Generic_Shared_State_Final_Diagnostic_Renaming_Generic_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Volatile_Atomic_Representation =>
            return Generic_Shared_State_Final_Diagnostic_Volatile_Atomic_Representation_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Read_Before_Write |
              Dataflow_Generic.Dataflow_Generic_Final_Blocker_Partial_Component_Init |
              Dataflow_Generic.Dataflow_Generic_Final_Blocker_Out_Parameter |
              Dataflow_Generic.Dataflow_Generic_Final_Blocker_Return_Object |
              Dataflow_Generic.Dataflow_Generic_Final_Blocker_Branch_Loop_Merge |
              Dataflow_Generic.Dataflow_Generic_Final_Blocker_Exception_Path |
              Dataflow_Generic.Dataflow_Generic_Final_Blocker_Finalization |
              Dataflow_Generic.Dataflow_Generic_Final_Blocker_Access_Escape |
              Dataflow_Generic.Dataflow_Generic_Final_Blocker_Variant_Component |
              Dataflow_Generic.Dataflow_Generic_Final_Blocker_Volatile_Atomic_Effect |
              Dataflow_Generic.Dataflow_Generic_Final_Blocker_Generic_Substitution =>
            return Generic_Shared_State_Final_Diagnostic_Local_Dataflow_RM_Blocker;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Source_Fingerprint =>
            return Generic_Shared_State_Final_Diagnostic_Source_Fingerprint_Mismatch;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Substitution_Fingerprint =>
            return Generic_Shared_State_Final_Diagnostic_Substitution_Fingerprint_Mismatch;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Multiple =>
            return Generic_Shared_State_Final_Diagnostic_Multiple_Blockers;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_Indeterminate =>
            return Generic_Shared_State_Final_Diagnostic_Indeterminate;
         when Dataflow_Generic.Dataflow_Generic_Final_Blocker_None =>
            if Row.Blocked then
               return Generic_Shared_State_Final_Diagnostic_Indeterminate;
            else
               return Generic_Shared_State_Final_Diagnostic_Withheld_Accepted_Current;
            end if;
      end case;
   end Status_For;

   function Family_For
     (Status : Generic_Shared_State_Final_Diagnostic_Status)
      return Generic_Shared_State_Final_Diagnostic_Family is
   begin
      case Status is
         when Generic_Shared_State_Final_Diagnostic_Withheld_Accepted_Current =>
            return Generic_Shared_State_Final_Diagnostic_Accepted;
         when Generic_Shared_State_Final_Diagnostic_Definite_Initialization_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Definite_Initialization;
         when Generic_Shared_State_Final_Diagnostic_Dataflow_Initialization_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Dataflow_Initialization;
         when Generic_Shared_State_Final_Diagnostic_Predicate_Dataflow_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Predicate_Dataflow;
         when Generic_Shared_State_Final_Diagnostic_Predicate_Generic_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Predicate_Generic_Shared_State;
         when Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay;
         when Generic_Shared_State_Final_Diagnostic_Stabilized_Closure_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Stabilized_Shared_State_Closure;
         when Generic_Shared_State_Final_Diagnostic_Representation_Generic_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Representation_Generic_Shared_State;
         when Generic_Shared_State_Final_Diagnostic_Tasking_Generic_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Tasking_Generic_Shared_State;
         when Generic_Shared_State_Final_Diagnostic_Accessibility_Generic_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Accessibility_Generic_Shared_State;
         when Generic_Shared_State_Final_Diagnostic_Discriminant_Generic_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Discriminant_Generic_Shared_State;
         when Generic_Shared_State_Final_Diagnostic_Exception_Finalization_Generic_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Exception_Finalization_Generic_Shared_State;
         when Generic_Shared_State_Final_Diagnostic_Renaming_Generic_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Renaming_Generic_Shared_State;
         when Generic_Shared_State_Final_Diagnostic_Volatile_Atomic_Representation_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Volatile_Atomic_Representation;
         when Generic_Shared_State_Final_Diagnostic_Local_Dataflow_RM_Blocker =>
            return Generic_Shared_State_Final_Diagnostic_Local_Dataflow_RM;
         when Generic_Shared_State_Final_Diagnostic_Source_Fingerprint_Mismatch |
              Generic_Shared_State_Final_Diagnostic_Substitution_Fingerprint_Mismatch =>
            return Generic_Shared_State_Final_Diagnostic_Fingerprint;
         when Generic_Shared_State_Final_Diagnostic_Multiple_Blockers =>
            return Generic_Shared_State_Final_Diagnostic_Multiple;
         when Generic_Shared_State_Final_Diagnostic_Indeterminate =>
            return Generic_Shared_State_Final_Diagnostic_Indeterminate;
         when Generic_Shared_State_Final_Diagnostic_Not_Checked =>
            return Generic_Shared_State_Final_Diagnostic_Unknown;
      end case;
   end Family_For;

   function Severity_For
     (Status : Generic_Shared_State_Final_Diagnostic_Status)
      return Generic_Shared_State_Final_Diagnostic_Severity is
   begin
      case Status is
         when Generic_Shared_State_Final_Diagnostic_Withheld_Accepted_Current =>
            return Generic_Shared_State_Final_Diagnostic_Info;
         when Generic_Shared_State_Final_Diagnostic_Indeterminate =>
            return Generic_Shared_State_Final_Diagnostic_Warning;
         when others =>
            return Generic_Shared_State_Final_Diagnostic_Error;
      end case;
   end Severity_For;

   function Message_For
     (Status : Generic_Shared_State_Final_Diagnostic_Status)
      return Unbounded_String is
   begin
      case Status is
         when Generic_Shared_State_Final_Diagnostic_Withheld_Accepted_Current =>
            return To_Unbounded_String ("generic/shared-state final semantics accepted and withheld as current non-diagnostic evidence");
         when Generic_Shared_State_Final_Diagnostic_Definite_Initialization_Blocker =>
            return To_Unbounded_String ("definite-initialization evidence blocks generic/shared-state final semantics");
         when Generic_Shared_State_Final_Diagnostic_Dataflow_Initialization_Blocker =>
            return To_Unbounded_String ("dataflow initialization evidence blocks generic/shared-state final semantics");
         when Generic_Shared_State_Final_Diagnostic_Predicate_Dataflow_Blocker =>
            return To_Unbounded_String ("predicate/dataflow evidence blocks generic/shared-state final semantics");
         when Generic_Shared_State_Final_Diagnostic_Predicate_Generic_Blocker =>
            return To_Unbounded_String ("predicate generic/shared-state evidence blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay_Blocker =>
            return To_Unbounded_String ("generic abstract-state replay blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Stabilized_Closure_Blocker =>
            return To_Unbounded_String ("stabilized shared-state closure blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Representation_Generic_Blocker =>
            return To_Unbounded_String ("representation/freezing generic shared-state evidence blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Tasking_Generic_Blocker =>
            return To_Unbounded_String ("tasking/protected generic shared-state evidence blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Accessibility_Generic_Blocker =>
            return To_Unbounded_String ("accessibility generic shared-state evidence blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Discriminant_Generic_Blocker =>
            return To_Unbounded_String ("discriminant/variant generic shared-state evidence blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Exception_Finalization_Generic_Blocker =>
            return To_Unbounded_String ("exception/finalization generic shared-state evidence blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Renaming_Generic_Blocker =>
            return To_Unbounded_String ("renaming/alias generic shared-state evidence blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Volatile_Atomic_Representation_Blocker =>
            return To_Unbounded_String ("volatile/atomic representation evidence blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Local_Dataflow_RM_Blocker =>
            return To_Unbounded_String ("local Ada dataflow legality blocks final semantics");
         when Generic_Shared_State_Final_Diagnostic_Source_Fingerprint_Mismatch =>
            return To_Unbounded_String ("generic/shared-state source fingerprint mismatch");
         when Generic_Shared_State_Final_Diagnostic_Substitution_Fingerprint_Mismatch =>
            return To_Unbounded_String ("generic/shared-state substitution fingerprint mismatch");
         when Generic_Shared_State_Final_Diagnostic_Multiple_Blockers =>
            return To_Unbounded_String ("multiple generic/shared-state final semantic blockers are present");
         when Generic_Shared_State_Final_Diagnostic_Indeterminate =>
            return To_Unbounded_String ("generic/shared-state final semantics are indeterminate");
         when Generic_Shared_State_Final_Diagnostic_Not_Checked =>
            return To_Unbounded_String ("generic/shared-state final semantics not checked");
      end case;
   end Message_For;

   function Row_Fingerprint (Row : Generic_Shared_State_Final_Diagnostic_Row) return Natural is
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Dataflow_Row));
      H := Mix (H, Dataflow_Generic.Dataflow_Generic_Final_Status'Pos (Row.Dataflow_Status) + 1);
      H := Mix (H, Generic_Shared_State_Final_Diagnostic_Status'Pos (Row.Status) + 1);
      H := Mix (H, Generic_Shared_State_Final_Diagnostic_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      H := Mix (H, Row.Semantic_Fingerprint);
      return H;
   end Row_Fingerprint;

   procedure Append_Row
     (Model : in out Generic_Shared_State_Final_Diagnostic_Model;
      Row   : in out Generic_Shared_State_Final_Diagnostic_Row) is
   begin
      Row.Diagnostic_Fingerprint := Row_Fingerprint (Row);
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Diagnostic_Fingerprint);
      case Row.Severity is
         when Generic_Shared_State_Final_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Generic_Shared_State_Final_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Generic_Shared_State_Final_Diagnostic_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;
      if Row.Emitted then
         Model.Emitted_Total := Model.Emitted_Total + 1;
      end if;
      if Row.Withheld_Current then
         Model.Withheld_Current_Total := Model.Withheld_Current_Total + 1;
      end if;
      if Row.Status = Generic_Shared_State_Final_Diagnostic_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Append_Row;

   function Build
     (Dataflow_Model : Dataflow_Generic.Dataflow_Generic_Final_Model)
      return Generic_Shared_State_Final_Diagnostic_Model is
      Model : Generic_Shared_State_Final_Diagnostic_Model;
   begin
      for I in 1 .. Dataflow_Generic.Count (Dataflow_Model) loop
         declare
            Source : constant Dataflow_Generic.Dataflow_Generic_Final_Row :=
              Dataflow_Generic.Row_At (Dataflow_Model, I);
            Status : constant Generic_Shared_State_Final_Diagnostic_Status := Status_For (Source);
            Row : Generic_Shared_State_Final_Diagnostic_Row;
         begin
            Row.Id := Generic_Shared_State_Final_Diagnostic_Id (I);
            Row.Dataflow_Row := Source.Id;
            Row.Dataflow_Status := Source.Status;
            Row.Status := Status;
            Row.Family := Family_For (Status);
            Row.Severity := Severity_For (Status);
            Row.Node := Source.Node;
            Row.Object_Name := Source.Object_Name;
            Row.Component_Name := Source.Component_Name;
            Row.Operation_Name := Source.Operation_Name;
            Row.Generic_Unit_Name := Source.Generic_Unit_Name;
            Row.Instance_Name := Source.Instance_Name;
            Row.State_Name := Source.State_Name;
            Row.Emitted := Is_Emitted (Status);
            Row.Withheld_Current := Is_Withheld_Current (Status);
            Row.Blocks_Downstream := Source.Blocks_Downstream;
            Row.Message := Message_For (Status);
            Row.Detail := Source.Message;
            Row.Source_Fingerprint := Source.Source_Fingerprint;
            Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
            Row.Semantic_Fingerprint := Source.Fingerprint;
            Row.Start_Line := Source.Start_Line;
            Row.Start_Column := Source.Start_Column;
            Row.End_Line := Source.End_Line;
            Row.End_Column := Source.End_Column;
            Append_Row (Model, Row);
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Generic_Shared_State_Final_Diagnostic_Model;
      Index : Positive) return Generic_Shared_State_Final_Diagnostic_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Generic_Shared_State_Final_Diagnostic_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Generic_Shared_State_Final_Diagnostic_Set;
      Index : Positive) return Generic_Shared_State_Final_Diagnostic_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Generic_Shared_State_Final_Diagnostic_Model;
      Status : Generic_Shared_State_Final_Diagnostic_Status)
      return Generic_Shared_State_Final_Diagnostic_Set is
      Set : Generic_Shared_State_Final_Diagnostic_Set;
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
     (Model  : Generic_Shared_State_Final_Diagnostic_Model;
      Family : Generic_Shared_State_Final_Diagnostic_Family)
      return Generic_Shared_State_Final_Diagnostic_Set is
      Set : Generic_Shared_State_Final_Diagnostic_Set;
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
     (Model : Generic_Shared_State_Final_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Generic_Shared_State_Final_Diagnostic_Set is
      Set : Generic_Shared_State_Final_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Diagnostic_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Diagnostic_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Diagnostic_Set is
      Set : Generic_Shared_State_Final_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Diagnostic_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Count_Status
     (Model  : Generic_Shared_State_Final_Diagnostic_Model;
      Status : Generic_Shared_State_Final_Diagnostic_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Family
     (Model  : Generic_Shared_State_Final_Diagnostic_Model;
      Family : Generic_Shared_State_Final_Diagnostic_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Error_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Emitted_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Withheld_Current_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural is
   begin
      return Model.Withheld_Current_Total;
   end Withheld_Current_Count;

   function Indeterminate_Count (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Generic_Shared_State_Final_Diagnostic_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
