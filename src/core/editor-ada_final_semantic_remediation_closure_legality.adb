with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Final_Semantic_Remediation_Closure_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Blocker_Family;
   use type Final_Gate_Action;
   use type Final_Gate_Status;
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

   function Status_For
     (Row : Gate.Final_Gated_Result) return Final_Remediation_Closure_Status is
   begin
      case Row.Status is
         when Gate.Final_Gate_Confident_Legal =>
            return Final_Remediation_Closure_Legal_Local;
         when Gate.Final_Gate_Withheld_Stale_Input =>
            return Final_Remediation_Closure_Stale_Blocker;
         when Gate.Final_Gate_Withheld_AST_Coverage =>
            return Final_Remediation_Closure_AST_Coverage_Blocker;
         when Gate.Final_Gate_Withheld_Cross_Unit_Dependency =>
            return Final_Remediation_Closure_Cross_Unit_Blocker;
         when Gate.Final_Gate_Withheld_View_Barrier =>
            return Final_Remediation_Closure_View_Blocker;
         when Gate.Final_Gate_Withheld_Generic_Replay =>
            return Final_Remediation_Closure_Generic_Replay_Blocker;
         when Gate.Final_Gate_Withheld_Overload_Type =>
            return Final_Remediation_Closure_Overload_Type_Blocker;
         when Gate.Final_Gate_Withheld_Representation_Freezing =>
            return Final_Remediation_Closure_Representation_Freezing_Blocker;
         when Gate.Final_Gate_Withheld_Flow_Contract =>
            return Final_Remediation_Closure_Flow_Contract_Blocker;
         when Gate.Final_Gate_Withheld_Tasking_Protected =>
            return Final_Remediation_Closure_Tasking_Protected_Blocker;
         when Gate.Final_Gate_Withheld_Elaboration =>
            return Final_Remediation_Closure_Elaboration_Blocker;
         when Gate.Final_Gate_Withheld_Accessibility_Lifetime =>
            return Final_Remediation_Closure_Accessibility_Lifetime_Blocker;
         when Gate.Final_Gate_Withheld_Discriminant_Variant =>
            return Final_Remediation_Closure_Discriminant_Variant_Blocker;
         when Gate.Final_Gate_Withheld_Multiple_Blockers =>
            return Final_Remediation_Closure_Multiple_Blockers;
         when Gate.Final_Gate_Preserve_Semantic_Error =>
            return Final_Remediation_Closure_Preserved_Semantic_Error;
         when Gate.Final_Gate_Indeterminate =>
            return Final_Remediation_Closure_Indeterminate;
         when Gate.Final_Gate_Not_Checked =>
            return Final_Remediation_Closure_Not_Checked;
      end case;
   end Status_For;

   function Is_Blocked
     (Status : Final_Remediation_Closure_Status) return Boolean is
   begin
      case Status is
         when Final_Remediation_Closure_Stale_Blocker
            | Final_Remediation_Closure_AST_Coverage_Blocker
            | Final_Remediation_Closure_Cross_Unit_Blocker
            | Final_Remediation_Closure_View_Blocker
            | Final_Remediation_Closure_Generic_Replay_Blocker
            | Final_Remediation_Closure_Overload_Type_Blocker
            | Final_Remediation_Closure_Representation_Freezing_Blocker
            | Final_Remediation_Closure_Flow_Contract_Blocker
            | Final_Remediation_Closure_Tasking_Protected_Blocker
            | Final_Remediation_Closure_Elaboration_Blocker
            | Final_Remediation_Closure_Accessibility_Lifetime_Blocker
            | Final_Remediation_Closure_Discriminant_Variant_Blocker
            | Final_Remediation_Closure_Multiple_Blockers
            | Final_Remediation_Closure_Preserved_Semantic_Error
            | Final_Remediation_Closure_Indeterminate
            | Final_Remediation_Closure_Not_Checked =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Blocked;

   function From_Gate
     (Id     : Final_Remediation_Closure_Id;
      Source : Gate.Final_Gated_Result) return Final_Remediation_Closure_Row is
      Status : constant Final_Remediation_Closure_Status := Status_For (Source);
      Result : Final_Remediation_Closure_Row;
   begin
      Result.Id := Id;
      Result.Gate_Id := Source.Id;
      Result.Status := Status;
      Result.Gate_Status := Source.Status;
      Result.Gate_Action := Source.Action;
      Result.Blocker_Family := Source.Blocker_Family;
      Result.Node := Source.Node;
      Result.Start_Line := Source.Start_Line;
      Result.Start_Column := Source.Start_Column;
      Result.End_Line := Source.End_Line;
      Result.End_Column := Source.End_Column;
      Result.Dependency_Order := Source.Dependency_Order;
      Result.Closure_Blocked := Is_Blocked (Status);
      Result.Derived_Legal_Withheld := Source.Legal_Result_Withheld;
      Result.Downstream_Blocked := Source.Downstream_Blocked;
      Result.Source_Fingerprint := Source.Source_Fingerprint;
      Result.Gate_Fingerprint := Source.Fingerprint;
      Result.Fingerprint := Mix (Natural (Id), Source.Fingerprint);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Natural (Final_Remediation_Closure_Status'Pos (Status)));
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Natural (Final_Prov.Final_Blocker_Family'Pos (Result.Blocker_Family)));
      Result.Fingerprint := Mix (Result.Fingerprint, Result.Downstream_Blocked);
      return Result;
   end From_Gate;

   procedure Note
     (Model : in out Final_Remediation_Closure_Model;
      Row   : Final_Remediation_Closure_Row) is
   begin
      case Row.Status is
         when Final_Remediation_Closure_Legal_Local
            | Final_Remediation_Closure_Legal_Derived =>
            Model.Legal_Total := Model.Legal_Total + 1;
         when Final_Remediation_Closure_Stale_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Stale_Blocker_Total := Model.Stale_Blocker_Total + 1;
         when Final_Remediation_Closure_AST_Coverage_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.AST_Coverage_Blocker_Total := Model.AST_Coverage_Blocker_Total + 1;
         when Final_Remediation_Closure_Cross_Unit_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Cross_Unit_Blocker_Total := Model.Cross_Unit_Blocker_Total + 1;
         when Final_Remediation_Closure_View_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.View_Blocker_Total := Model.View_Blocker_Total + 1;
         when Final_Remediation_Closure_Generic_Replay_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Generic_Replay_Blocker_Total := Model.Generic_Replay_Blocker_Total + 1;
         when Final_Remediation_Closure_Overload_Type_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Overload_Type_Blocker_Total := Model.Overload_Type_Blocker_Total + 1;
         when Final_Remediation_Closure_Representation_Freezing_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Representation_Freezing_Blocker_Total := Model.Representation_Freezing_Blocker_Total + 1;
         when Final_Remediation_Closure_Flow_Contract_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Flow_Contract_Blocker_Total := Model.Flow_Contract_Blocker_Total + 1;
         when Final_Remediation_Closure_Tasking_Protected_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Tasking_Protected_Blocker_Total := Model.Tasking_Protected_Blocker_Total + 1;
         when Final_Remediation_Closure_Elaboration_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Elaboration_Blocker_Total := Model.Elaboration_Blocker_Total + 1;
         when Final_Remediation_Closure_Accessibility_Lifetime_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Accessibility_Lifetime_Blocker_Total := Model.Accessibility_Lifetime_Blocker_Total + 1;
         when Final_Remediation_Closure_Discriminant_Variant_Blocker =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Discriminant_Variant_Blocker_Total := Model.Discriminant_Variant_Blocker_Total + 1;
         when Final_Remediation_Closure_Multiple_Blockers =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
         when Final_Remediation_Closure_Preserved_Semantic_Error =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Preserved_Error_Total := Model.Preserved_Error_Total + 1;
         when Final_Remediation_Closure_Indeterminate
            | Final_Remediation_Closure_Not_Checked =>
            Model.Blocked_Total := Model.Blocked_Total + 1;
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end case;

      if Row.Derived_Legal_Withheld then
         Model.Derived_Legal_Withheld_Total := Model.Derived_Legal_Withheld_Total + 1;
      end if;
      Model.Downstream_Blocked_Total :=
        Model.Downstream_Blocked_Total + Row.Downstream_Blocked;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
   end Note;

   procedure Append
     (Set : in out Final_Remediation_Closure_Set;
      Row : Final_Remediation_Closure_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
   end Append;

   procedure Clear (Model : in out Final_Remediation_Closure_Model) is
   begin
      Model.Rows.Clear;
      Model.Legal_Total := 0;
      Model.Blocked_Total := 0;
      Model.Derived_Legal_Withheld_Total := 0;
      Model.Stale_Blocker_Total := 0;
      Model.AST_Coverage_Blocker_Total := 0;
      Model.Cross_Unit_Blocker_Total := 0;
      Model.View_Blocker_Total := 0;
      Model.Generic_Replay_Blocker_Total := 0;
      Model.Overload_Type_Blocker_Total := 0;
      Model.Representation_Freezing_Blocker_Total := 0;
      Model.Flow_Contract_Blocker_Total := 0;
      Model.Tasking_Protected_Blocker_Total := 0;
      Model.Elaboration_Blocker_Total := 0;
      Model.Accessibility_Lifetime_Blocker_Total := 0;
      Model.Discriminant_Variant_Blocker_Total := 0;
      Model.Multiple_Blocker_Total := 0;
      Model.Preserved_Error_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Downstream_Blocked_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Gate_Model : Gate.Final_Gated_Model)
      return Final_Remediation_Closure_Model is
      Model : Final_Remediation_Closure_Model;
      Row : Final_Remediation_Closure_Row;
   begin
      for I in 1 .. Gate.Row_Count (Gate_Model) loop
         Row := From_Gate
           (Final_Remediation_Closure_Id (I),
            Gate.Row_At (Gate_Model, I));
         Model.Rows.Append (Row);
         Note (Model, Row);
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Remediation_Closure_Model;
      Index : Positive) return Final_Remediation_Closure_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Set_Count (Set : Final_Remediation_Closure_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At
     (Set   : Final_Remediation_Closure_Set;
      Index : Positive) return Final_Remediation_Closure_Row is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Query_Status
     (Model  : Final_Remediation_Closure_Model;
      Status : Final_Remediation_Closure_Status) return Final_Remediation_Closure_Set is
      Set : Final_Remediation_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Blocker
     (Model   : Final_Remediation_Closure_Model;
      Blocker : Final_Blocker_Family) return Final_Remediation_Closure_Set is
      Set : Final_Remediation_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Blocker;

   function Query_Node
     (Model : Final_Remediation_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Remediation_Closure_Set is
      Set : Final_Remediation_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Position
     (Model  : Final_Remediation_Closure_Model;
      Line   : Positive;
      Column : Positive) return Final_Remediation_Closure_Set is
      Set : Final_Remediation_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Line >= Row.Start_Line
           and then Line <= Row.End_Line
           and then Column >= Row.Start_Column
           and then Column <= Row.End_Column
         then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Position;

   function Count_Status
     (Model  : Final_Remediation_Closure_Model;
      Status : Final_Remediation_Closure_Status) return Natural is
   begin
      return Set_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Blocker
     (Model   : Final_Remediation_Closure_Model;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      return Set_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Legal_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Blocked_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Derived_Legal_Withheld_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Derived_Legal_Withheld_Total;
   end Derived_Legal_Withheld_Count;

   function Stale_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Stale_Blocker_Total;
   end Stale_Blocker_Count;

   function AST_Coverage_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.AST_Coverage_Blocker_Total;
   end AST_Coverage_Blocker_Count;

   function Cross_Unit_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Cross_Unit_Blocker_Total;
   end Cross_Unit_Blocker_Count;

   function View_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.View_Blocker_Total;
   end View_Blocker_Count;

   function Generic_Replay_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Generic_Replay_Blocker_Total;
   end Generic_Replay_Blocker_Count;

   function Overload_Type_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Overload_Type_Blocker_Total;
   end Overload_Type_Blocker_Count;

   function Representation_Freezing_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Representation_Freezing_Blocker_Total;
   end Representation_Freezing_Blocker_Count;

   function Flow_Contract_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Flow_Contract_Blocker_Total;
   end Flow_Contract_Blocker_Count;

   function Tasking_Protected_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Tasking_Protected_Blocker_Total;
   end Tasking_Protected_Blocker_Count;

   function Elaboration_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Elaboration_Blocker_Total;
   end Elaboration_Blocker_Count;

   function Accessibility_Lifetime_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Accessibility_Lifetime_Blocker_Total;
   end Accessibility_Lifetime_Blocker_Count;

   function Discriminant_Variant_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Discriminant_Variant_Blocker_Total;
   end Discriminant_Variant_Blocker_Count;

   function Multiple_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Total;
   end Multiple_Blocker_Count;

   function Preserved_Error_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Preserved_Error_Total;
   end Preserved_Error_Count;

   function Indeterminate_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Downstream_Blocked_Count (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Downstream_Blocked_Total;
   end Downstream_Blocked_Count;

   function First_Blocker
     (Model : Final_Remediation_Closure_Model) return Final_Remediation_Closure_Row is
      Best : Final_Remediation_Closure_Row;
      Have : Boolean := False;
   begin
      for Row of Model.Rows loop
         if Row.Closure_Blocked then
            if not Have
              or else Row.Dependency_Order < Best.Dependency_Order
              or else (Row.Dependency_Order = Best.Dependency_Order
                       and then Natural (Row.Id) < Natural (Best.Id))
            then
               Best := Row;
               Have := True;
            end if;
         end if;
      end loop;
      return Best;
   end First_Blocker;

   function Fingerprint (Model : Final_Remediation_Closure_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Remediation_Closure_Legality;
