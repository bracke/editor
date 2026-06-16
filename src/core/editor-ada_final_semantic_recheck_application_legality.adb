with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Final_Semantic_Recheck_Application_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Blocker_Family;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 23) mod 2_147_483_647;
   end Mix;

   function Is_Withheld (Status : Final_Recheck_Application_Status) return Boolean is
   begin
      case Status is
         when Final_Recheck_Application_Withheld_Stale
            | Final_Recheck_Application_Withheld_AST_Coverage
            | Final_Recheck_Application_Withheld_Cross_Unit
            | Final_Recheck_Application_Withheld_View_Barrier
            | Final_Recheck_Application_Withheld_Generic_Replay
            | Final_Recheck_Application_Withheld_Overload_Type
            | Final_Recheck_Application_Withheld_Representation_Freezing
            | Final_Recheck_Application_Withheld_Flow_Contract
            | Final_Recheck_Application_Withheld_Tasking_Protected
            | Final_Recheck_Application_Withheld_Elaboration
            | Final_Recheck_Application_Withheld_Accessibility
            | Final_Recheck_Application_Withheld_Discriminant_Variant
            | Final_Recheck_Application_Withheld_Multiple_Prerequisites
            | Final_Recheck_Application_Indeterminate =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Withheld;

   procedure Classify
     (Source : Recheck.Final_Recheck_Eligibility_Row;
      Status : out Final_Recheck_Application_Status;
      Action : out Final_Recheck_Application_Action) is
   begin
      case Source.Status is
         when Recheck.Final_Recheck_Not_Checked =>
            Status := Final_Recheck_Application_Not_Checked;
            Action := Final_Recheck_Application_Action_None;
         when Recheck.Final_Recheck_Not_Required =>
            Status := Final_Recheck_Application_Not_Required;
            Action := Final_Recheck_Application_Action_Skip_Not_Required;
         when Recheck.Final_Recheck_Eligible_Now =>
            Status := Final_Recheck_Application_Current;
            Action := Final_Recheck_Application_Action_Expose_Current;
         when Recheck.Final_Recheck_Blocked_By_Stale_Input =>
            Status := Final_Recheck_Application_Withheld_Stale;
            Action := Final_Recheck_Application_Action_Withhold_For_Stale;
         when Recheck.Final_Recheck_Blocked_By_AST_Coverage =>
            Status := Final_Recheck_Application_Withheld_AST_Coverage;
            Action := Final_Recheck_Application_Action_Withhold_For_AST_Coverage;
         when Recheck.Final_Recheck_Blocked_By_Cross_Unit =>
            Status := Final_Recheck_Application_Withheld_Cross_Unit;
            Action := Final_Recheck_Application_Action_Withhold_For_Cross_Unit;
         when Recheck.Final_Recheck_Blocked_By_View_Barrier =>
            Status := Final_Recheck_Application_Withheld_View_Barrier;
            Action := Final_Recheck_Application_Action_Withhold_For_View_Barrier;
         when Recheck.Final_Recheck_Blocked_By_Generic_Replay =>
            Status := Final_Recheck_Application_Withheld_Generic_Replay;
            Action := Final_Recheck_Application_Action_Withhold_For_Generic_Replay;
         when Recheck.Final_Recheck_Blocked_By_Overload_Type =>
            Status := Final_Recheck_Application_Withheld_Overload_Type;
            Action := Final_Recheck_Application_Action_Withhold_For_Overload_Type;
         when Recheck.Final_Recheck_Blocked_By_Representation_Freezing =>
            Status := Final_Recheck_Application_Withheld_Representation_Freezing;
            Action := Final_Recheck_Application_Action_Withhold_For_Representation;
         when Recheck.Final_Recheck_Blocked_By_Flow_Contract =>
            Status := Final_Recheck_Application_Withheld_Flow_Contract;
            Action := Final_Recheck_Application_Action_Withhold_For_Flow_Contract;
         when Recheck.Final_Recheck_Blocked_By_Tasking_Protected =>
            Status := Final_Recheck_Application_Withheld_Tasking_Protected;
            Action := Final_Recheck_Application_Action_Withhold_For_Tasking;
         when Recheck.Final_Recheck_Blocked_By_Elaboration =>
            Status := Final_Recheck_Application_Withheld_Elaboration;
            Action := Final_Recheck_Application_Action_Withhold_For_Elaboration;
         when Recheck.Final_Recheck_Blocked_By_Accessibility =>
            Status := Final_Recheck_Application_Withheld_Accessibility;
            Action := Final_Recheck_Application_Action_Withhold_For_Accessibility;
         when Recheck.Final_Recheck_Blocked_By_Discriminant_Variant =>
            Status := Final_Recheck_Application_Withheld_Discriminant_Variant;
            Action := Final_Recheck_Application_Action_Withhold_For_Discriminants;
         when Recheck.Final_Recheck_Preserved_Semantic_Error =>
            Status := Final_Recheck_Application_Preserved_Semantic_Error;
            Action := Final_Recheck_Application_Action_Preserve_Error;
         when Recheck.Final_Recheck_Multiple_Prerequisites =>
            Status := Final_Recheck_Application_Withheld_Multiple_Prerequisites;
            Action := Final_Recheck_Application_Action_Split_Prerequisites;
         when Recheck.Final_Recheck_Indeterminate =>
            Status := Final_Recheck_Application_Indeterminate;
            Action := Final_Recheck_Application_Action_Degrade;
      end case;
   end Classify;

   function Message_For
     (Status  : Final_Recheck_Application_Status;
      Action  : Final_Recheck_Application_Action;
      Blocker : Final_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("final semantic recheck application " &
         Final_Recheck_Application_Status'Image (Status) &
         " action=" & Final_Recheck_Application_Action'Image (Action) &
         " blocker=" & Final_Blocker_Family'Image (Blocker));
   end Message_For;

   function Row_Fingerprint (Row : Final_Recheck_Application_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Recheck.Final_Recheck_Eligibility_Status'Pos (Row.Eligibility_Status) + 1);
      H := Mix (H, Recheck.Final_Recheck_Action'Pos (Row.Eligibility_Action) + 1);
      H := Mix (H, Final_Recheck_Application_Status'Pos (Row.Status) + 1);
      H := Mix (H, Final_Recheck_Application_Action'Pos (Row.Action) + 1);
      H := Mix (H, Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority);
      H := Mix (H, Row.Dependency_Depth);
      H := Mix (H, Row.Prerequisite_Depth);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Eligibility_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Recheck.Final_Recheck_Eligibility_Row;
      Index  : Positive) return Final_Recheck_Application_Row is
      Status : Final_Recheck_Application_Status;
      Action : Final_Recheck_Application_Action;
      Result : Final_Recheck_Application_Row;
   begin
      Classify (Source, Status, Action);
      Result.Id := Final_Recheck_Application_Id (Index);
      Result.Eligibility_Id := Source.Id;
      Result.Eligibility_Status := Source.Status;
      Result.Eligibility_Action := Source.Action;
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
      Result.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Result.Message := Message_For (Status, Action, Source.Blocker_Family);
      Result.Application_Fingerprint := Row_Fingerprint (Result);
      return Result;
   end Make_Row;

   procedure Add_Row
     (Model : in out Final_Recheck_Application_Model;
      Row   : Final_Recheck_Application_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Application_Fingerprint);

      if Row.Status = Final_Recheck_Application_Current then
         Model.Current_Total := Model.Current_Total + 1;
      end if;
      if Is_Withheld (Row.Status) then
         Model.Withheld_Total := Model.Withheld_Total + 1;
      end if;

      case Row.Status is
         when Final_Recheck_Application_Withheld_Stale =>
            Model.Stale_Total := Model.Stale_Total + 1;
         when Final_Recheck_Application_Withheld_AST_Coverage =>
            Model.AST_Total := Model.AST_Total + 1;
         when Final_Recheck_Application_Withheld_Cross_Unit
            | Final_Recheck_Application_Withheld_View_Barrier =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Final_Recheck_Application_Withheld_Generic_Replay =>
            Model.Generic_Total := Model.Generic_Total + 1;
         when Final_Recheck_Application_Withheld_Overload_Type =>
            Model.Overload_Total := Model.Overload_Total + 1;
         when Final_Recheck_Application_Withheld_Representation_Freezing =>
            Model.Representation_Total := Model.Representation_Total + 1;
         when Final_Recheck_Application_Withheld_Flow_Contract =>
            Model.Flow_Total := Model.Flow_Total + 1;
         when Final_Recheck_Application_Withheld_Tasking_Protected =>
            Model.Tasking_Total := Model.Tasking_Total + 1;
         when Final_Recheck_Application_Withheld_Elaboration =>
            Model.Elaboration_Total := Model.Elaboration_Total + 1;
         when Final_Recheck_Application_Withheld_Accessibility =>
            Model.Accessibility_Total := Model.Accessibility_Total + 1;
         when Final_Recheck_Application_Withheld_Discriminant_Variant =>
            Model.Discriminant_Total := Model.Discriminant_Total + 1;
         when Final_Recheck_Application_Preserved_Semantic_Error =>
            Model.Preserved_Error_Total := Model.Preserved_Error_Total + 1;
         when Final_Recheck_Application_Withheld_Multiple_Prerequisites =>
            Model.Multiple_Prerequisite_Total := Model.Multiple_Prerequisite_Total + 1;
         when Final_Recheck_Application_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others => null;
      end case;
   end Add_Row;

   procedure Clear (Model : in out Final_Recheck_Application_Model) is
   begin
      Model.Rows.Clear;
      Model.Current_Total := 0;
      Model.Withheld_Total := 0;
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
      Model.Preserved_Error_Total := 0;
      Model.Multiple_Prerequisite_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Eligibility : Recheck.Final_Recheck_Eligibility_Model)
      return Final_Recheck_Application_Model is
      Result : Final_Recheck_Application_Model;
   begin
      for I in 1 .. Recheck.Row_Count (Eligibility) loop
         Add_Row (Result, Make_Row (Recheck.Row_At (Eligibility, I), I));
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Recheck_Application_Model;
      Index : Positive) return Final_Recheck_Application_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Final_Recheck_Application_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Final_Recheck_Application_Set;
      Index : Positive) return Final_Recheck_Application_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Final_Recheck_Application_Set;
      Row : Final_Recheck_Application_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Application_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Final_Recheck_Application_Model;
      Status : Final_Recheck_Application_Status) return Final_Recheck_Application_Set is
      Result : Final_Recheck_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Action
     (Model  : Final_Recheck_Application_Model;
      Action : Final_Recheck_Application_Action) return Final_Recheck_Application_Set is
      Result : Final_Recheck_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Action;

   function Query_Blocker
     (Model   : Final_Recheck_Application_Model;
      Blocker : Final_Blocker_Family) return Final_Recheck_Application_Set is
      Result : Final_Recheck_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker;

   function Query_Node
     (Model : Final_Recheck_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Recheck_Application_Set is
      Result : Final_Recheck_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Count_Status
     (Model  : Final_Recheck_Application_Model;
      Status : Final_Recheck_Application_Status) return Natural is
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
     (Model  : Final_Recheck_Application_Model;
      Action : Final_Recheck_Application_Action) return Natural is
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
     (Model   : Final_Recheck_Application_Model;
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

   function Current_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Stale_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Withheld_Count;

   function AST_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.AST_Total;
   end AST_Withheld_Count;

   function Cross_Unit_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Cross_Unit_Total;
   end Cross_Unit_Withheld_Count;

   function Generic_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Generic_Total;
   end Generic_Withheld_Count;

   function Overload_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Overload_Total;
   end Overload_Withheld_Count;

   function Representation_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Representation_Total;
   end Representation_Withheld_Count;

   function Flow_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Flow_Total;
   end Flow_Withheld_Count;

   function Tasking_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Tasking_Total;
   end Tasking_Withheld_Count;

   function Elaboration_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Elaboration_Total;
   end Elaboration_Withheld_Count;

   function Accessibility_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Accessibility_Total;
   end Accessibility_Withheld_Count;

   function Discriminant_Withheld_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Discriminant_Total;
   end Discriminant_Withheld_Count;

   function Preserved_Error_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Preserved_Error_Total;
   end Preserved_Error_Count;

   function Multiple_Prerequisite_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Multiple_Prerequisite_Total;
   end Multiple_Prerequisite_Count;

   function Indeterminate_Count (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Final_Recheck_Application_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Recheck_Application_Legality;
