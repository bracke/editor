with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Final_Semantic_Stabilization_Gate_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Blocker_Family;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 31) mod 2_147_483_647;
   end Mix;

   function Is_Promoted (Status : Final_Stabilization_Gate_Status) return Boolean is
   begin
      return Status = Final_Stabilization_Gate_Promoted_Current
        or else Status = Final_Stabilization_Gate_Promoted_Not_Required;
   end Is_Promoted;

   function Is_Withheld (Status : Final_Stabilization_Gate_Status) return Boolean is
   begin
      case Status is
         when Final_Stabilization_Gate_Withheld_Stale
            | Final_Stabilization_Gate_Withheld_AST_Coverage
            | Final_Stabilization_Gate_Withheld_Cross_Unit
            | Final_Stabilization_Gate_Withheld_View_Barrier
            | Final_Stabilization_Gate_Withheld_Generic_Replay
            | Final_Stabilization_Gate_Withheld_Overload_Type
            | Final_Stabilization_Gate_Withheld_Representation_Freezing
            | Final_Stabilization_Gate_Withheld_Flow_Contract
            | Final_Stabilization_Gate_Withheld_Tasking_Protected
            | Final_Stabilization_Gate_Withheld_Elaboration
            | Final_Stabilization_Gate_Withheld_Accessibility
            | Final_Stabilization_Gate_Withheld_Discriminant_Variant
            | Final_Stabilization_Gate_Withheld_Multiple_Prerequisites =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Withheld;

   procedure Classify
     (Source : Conv.Final_Recheck_Convergence_Row;
      Status : out Final_Stabilization_Gate_Status;
      Action : out Final_Stabilization_Gate_Action) is
   begin
      case Source.Status is
         when Conv.Final_Recheck_Convergence_Not_Checked =>
            Status := Final_Stabilization_Gate_Not_Checked;
            Action := Final_Stabilization_Gate_Action_None;
         when Conv.Final_Recheck_Converged_Current =>
            Status := Final_Stabilization_Gate_Promoted_Current;
            Action := Final_Stabilization_Gate_Action_Promote_Current;
         when Conv.Final_Recheck_Converged_Not_Required =>
            Status := Final_Stabilization_Gate_Promoted_Not_Required;
            Action := Final_Stabilization_Gate_Action_Promote_Not_Required;
         when Conv.Final_Recheck_Stable_Withheld_Stale =>
            Status := Final_Stabilization_Gate_Withheld_Stale;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_AST_Coverage =>
            Status := Final_Stabilization_Gate_Withheld_AST_Coverage;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_Cross_Unit =>
            Status := Final_Stabilization_Gate_Withheld_Cross_Unit;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_View_Barrier =>
            Status := Final_Stabilization_Gate_Withheld_View_Barrier;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_Generic_Replay =>
            Status := Final_Stabilization_Gate_Withheld_Generic_Replay;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_Overload_Type =>
            Status := Final_Stabilization_Gate_Withheld_Overload_Type;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_Representation_Freezing =>
            Status := Final_Stabilization_Gate_Withheld_Representation_Freezing;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_Flow_Contract =>
            Status := Final_Stabilization_Gate_Withheld_Flow_Contract;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_Tasking_Protected =>
            Status := Final_Stabilization_Gate_Withheld_Tasking_Protected;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_Elaboration =>
            Status := Final_Stabilization_Gate_Withheld_Elaboration;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_Accessibility =>
            Status := Final_Stabilization_Gate_Withheld_Accessibility;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Withheld_Discriminant_Variant =>
            Status := Final_Stabilization_Gate_Withheld_Discriminant_Variant;
            Action := Final_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Final_Recheck_Stable_Preserved_Semantic_Error =>
            Status := Final_Stabilization_Gate_Preserved_Semantic_Error;
            Action := Final_Stabilization_Gate_Action_Retain_Error;
         when Conv.Final_Recheck_Stable_Multiple_Prerequisites =>
            Status := Final_Stabilization_Gate_Withheld_Multiple_Prerequisites;
            Action := Final_Stabilization_Gate_Action_Split_Prerequisites;
         when Conv.Final_Recheck_Stable_Indeterminate =>
            Status := Final_Stabilization_Gate_Degraded_Indeterminate;
            Action := Final_Stabilization_Gate_Action_Degrade;
         when Conv.Final_Recheck_Changed_Since_Previous =>
            Status := Final_Stabilization_Gate_Recheck_Required;
            Action := Final_Stabilization_Gate_Action_Recheck;
      end case;
   end Classify;

   function Message_For
     (Status  : Final_Stabilization_Gate_Status;
      Action  : Final_Stabilization_Gate_Action;
      Blocker : Final_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("final semantic stabilization gate " &
         Final_Stabilization_Gate_Status'Image (Status) &
         " action=" & Final_Stabilization_Gate_Action'Image (Action) &
         " blocker=" & Final_Blocker_Family'Image (Blocker));
   end Message_For;

   function Row_Fingerprint (Row : Final_Stabilization_Gate_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Convergence_Id));
      H := Mix (H, Conv.Final_Recheck_Convergence_Status'Pos (Row.Convergence_Status) + 1);
      H := Mix (H, Conv.Final_Recheck_Convergence_Action'Pos (Row.Convergence_Action) + 1);
      H := Mix (H, Final_Stabilization_Gate_Status'Pos (Row.Status) + 1);
      H := Mix (H, Final_Stabilization_Gate_Action'Pos (Row.Action) + 1);
      H := Mix (H, Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority);
      H := Mix (H, Row.Dependency_Depth);
      H := Mix (H, Row.Prerequisite_Depth);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Application_Fingerprint);
      H := Mix (H, Row.Convergence_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Conv.Final_Recheck_Convergence_Row;
      Index  : Positive) return Final_Stabilization_Gate_Row is
      Status : Final_Stabilization_Gate_Status;
      Action : Final_Stabilization_Gate_Action;
      Result : Final_Stabilization_Gate_Row;
   begin
      Classify (Source, Status, Action);
      Result.Id := Final_Stabilization_Gate_Id (Index);
      Result.Convergence_Id := Source.Id;
      Result.Convergence_Status := Source.Status;
      Result.Convergence_Action := Source.Action;
      Result.Status := Status;
      Result.Action := Action;
      Result.Blocker_Family := Source.Blocker_Family;
      Result.Node := Source.Node;
      Result.Priority := Source.Priority;
      Result.Dependency_Depth := Source.Dependency_Depth;
      Result.Prerequisite_Depth := Source.Prerequisite_Depth;
      Result.Start_Line := Source.Start_Line;
      Result.Start_Column := Source.Start_Column;
      Result.End_Line := Source.End_Line;
      Result.End_Column := Source.End_Column;
      Result.Source_Fingerprint := Source.Source_Fingerprint;
      Result.Application_Fingerprint := Source.Application_Fingerprint;
      Result.Convergence_Fingerprint := Source.Convergence_Fingerprint;
      Result.Message := Message_For (Status, Action, Source.Blocker_Family);
      Result.Stabilization_Fingerprint := Row_Fingerprint (Result);
      return Result;
   end Make_Row;

   procedure Add_Row
     (Model : in out Final_Stabilization_Gate_Model;
      Row   : Final_Stabilization_Gate_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Stabilization_Fingerprint);

      if Is_Promoted (Row.Status) then
         Model.Promoted_Total := Model.Promoted_Total + 1;
      end if;
      if Is_Withheld (Row.Status) then
         Model.Withheld_Total := Model.Withheld_Total + 1;
      end if;
      if Row.Status = Final_Stabilization_Gate_Recheck_Required then
         Model.Recheck_Total := Model.Recheck_Total + 1;
      end if;

      case Row.Status is
         when Final_Stabilization_Gate_Withheld_Stale =>
            Model.Stale_Total := Model.Stale_Total + 1;
         when Final_Stabilization_Gate_Withheld_AST_Coverage =>
            Model.AST_Total := Model.AST_Total + 1;
         when Final_Stabilization_Gate_Withheld_Cross_Unit
            | Final_Stabilization_Gate_Withheld_View_Barrier =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Final_Stabilization_Gate_Withheld_Generic_Replay =>
            Model.Generic_Total := Model.Generic_Total + 1;
         when Final_Stabilization_Gate_Withheld_Overload_Type =>
            Model.Overload_Total := Model.Overload_Total + 1;
         when Final_Stabilization_Gate_Withheld_Representation_Freezing =>
            Model.Representation_Total := Model.Representation_Total + 1;
         when Final_Stabilization_Gate_Withheld_Flow_Contract =>
            Model.Flow_Total := Model.Flow_Total + 1;
         when Final_Stabilization_Gate_Withheld_Tasking_Protected =>
            Model.Tasking_Total := Model.Tasking_Total + 1;
         when Final_Stabilization_Gate_Withheld_Elaboration =>
            Model.Elaboration_Total := Model.Elaboration_Total + 1;
         when Final_Stabilization_Gate_Withheld_Accessibility =>
            Model.Accessibility_Total := Model.Accessibility_Total + 1;
         when Final_Stabilization_Gate_Withheld_Discriminant_Variant =>
            Model.Discriminant_Total := Model.Discriminant_Total + 1;
         when Final_Stabilization_Gate_Preserved_Semantic_Error =>
            Model.Preserved_Error_Total := Model.Preserved_Error_Total + 1;
         when Final_Stabilization_Gate_Degraded_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others => null;
      end case;
   end Add_Row;

   procedure Clear (Model : in out Final_Stabilization_Gate_Model) is
   begin
      Model.Rows.Clear;
      Model.Promoted_Total := 0;
      Model.Withheld_Total := 0;
      Model.Recheck_Total := 0;
      Model.Preserved_Error_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Stale_Total := 0;
      Model.AST_Total := 0;
      Model.Cross_Unit_Total := 0;
      Model.Generic_Total := 0;
      Model.Overload_Total := 0;
      Model.Representation_Total := 0;
      Model.Flow_Total := 0;
      Model.Tasking_Total := 0;
      Model.Elaboration_Total := 0;
      Model.Accessibility_Total := 0;
      Model.Discriminant_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Convergence : Conv.Final_Recheck_Convergence_Model)
      return Final_Stabilization_Gate_Model is
      Result : Final_Stabilization_Gate_Model;
   begin
      for I in 1 .. Conv.Row_Count (Convergence) loop
         Add_Row (Result, Make_Row (Conv.Row_At (Convergence, I), I));
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Stabilization_Gate_Model;
      Index : Positive) return Final_Stabilization_Gate_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Final_Stabilization_Gate_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Final_Stabilization_Gate_Set;
      Index : Positive) return Final_Stabilization_Gate_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Final_Stabilization_Gate_Set;
      Row : Final_Stabilization_Gate_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Stabilization_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Final_Stabilization_Gate_Model;
      Status : Final_Stabilization_Gate_Status) return Final_Stabilization_Gate_Set is
      Result : Final_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Action
     (Model  : Final_Stabilization_Gate_Model;
      Action : Final_Stabilization_Gate_Action) return Final_Stabilization_Gate_Set is
      Result : Final_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Action;

   function Query_Blocker
     (Model   : Final_Stabilization_Gate_Model;
      Blocker : Final_Blocker_Family) return Final_Stabilization_Gate_Set is
      Result : Final_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker;

   function Query_Node
     (Model : Final_Stabilization_Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Stabilization_Gate_Set is
      Result : Final_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Count_Status
     (Model  : Final_Stabilization_Gate_Model;
      Status : Final_Stabilization_Gate_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Action
     (Model  : Final_Stabilization_Gate_Model;
      Action : Final_Stabilization_Gate_Action) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Action;

   function Count_Blocker
     (Model   : Final_Stabilization_Gate_Model;
      Blocker : Final_Blocker_Family) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Blocker;

   function Promoted_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Promoted_Total;
   end Promoted_Count;

   function Withheld_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Recheck_Required_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Preserved_Error_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Preserved_Error_Total;
   end Preserved_Error_Count;

   function Indeterminate_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stale_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Count;

   function AST_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.AST_Total;
   end AST_Count;

   function Cross_Unit_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Cross_Unit_Total;
   end Cross_Unit_Count;

   function Generic_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Generic_Total;
   end Generic_Count;

   function Overload_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Overload_Total;
   end Overload_Count;

   function Representation_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Representation_Total;
   end Representation_Count;

   function Flow_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Flow_Total;
   end Flow_Count;

   function Tasking_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Tasking_Total;
   end Tasking_Count;

   function Elaboration_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Elaboration_Total;
   end Elaboration_Count;

   function Accessibility_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Accessibility_Total;
   end Accessibility_Count;

   function Discriminant_Count (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Discriminant_Total;
   end Discriminant_Count;

   function Fingerprint (Model : Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Stabilization_Gate_Legality;
