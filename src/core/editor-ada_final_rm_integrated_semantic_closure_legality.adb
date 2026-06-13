with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Final_RM_Integrated_Semantic_Closure_Legality is

   use type AST_Repair.Remaining_RM_Edge_AST_Repair_Status;
   use type Consumers.RM_Closure_Consumer_Stabilized_Closure_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Base.Final_Stabilized_Closure_Status;
   use type Remaining_Edge.Remaining_RM_Edge_Stabilized_Closure_Status;
   use type RM_Completion.RM_Completion_Stabilized_Closure_Status;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 1) mod 1_000_000_007;
   end Mix;

   function Final_Base_Accepted (Row : Final_Base_Row) return Boolean is
   begin
      return Row.Status in Final_Base.Final_Stabilized_Closure_Accepted_Current |
                           Final_Base.Final_Stabilized_Closure_Accepted_Not_Required;
   end Final_Base_Accepted;

   function Final_Base_Recheck (Row : Final_Base_Row) return Boolean is
   begin
      return Row.Status = Final_Base.Final_Stabilized_Closure_Recheck_Required;
   end Final_Base_Recheck;

   function Final_Base_Indeterminate (Row : Final_Base_Row) return Boolean is
   begin
      return Row.Status = Final_Base.Final_Stabilized_Closure_Indeterminate;
   end Final_Base_Indeterminate;

   function AST_Repair_Accepted (Row : AST_Repair_Row) return Boolean is
   begin
      return AST_Repair.Is_Repaired (Row.Status) or else Row.Not_Required;
   end AST_Repair_Accepted;

   function AST_Repair_Recheck (Row : AST_Repair_Row) return Boolean is
      pragma Unreferenced (Row);
   begin
      return False;
   end AST_Repair_Recheck;

   function AST_Repair_Indeterminate (Row : AST_Repair_Row) return Boolean is
   begin
      return Row.Status = AST_Repair.Remaining_RM_Edge_AST_Repair_Indeterminate;
   end AST_Repair_Indeterminate;

   function Is_Accepted (Status : Final_RM_Integrated_Closure_Status) return Boolean is
   begin
      return Status in Final_RM_Integrated_Closure_Accepted_Current |
                       Final_RM_Integrated_Closure_Accepted_Not_Required;
   end Is_Accepted;

   function Is_Blocked (Status : Final_RM_Integrated_Closure_Status) return Boolean is
   begin
      return Status in Final_RM_Integrated_Closure_Blocker_Final_Stabilized_Closure |
                       Final_RM_Integrated_Closure_Blocker_RM_Completion_Closure |
                       Final_RM_Integrated_Closure_Blocker_Direct_Consumer_Closure |
                       Final_RM_Integrated_Closure_Blocker_Remaining_Edge_Closure |
                       Final_RM_Integrated_Closure_Blocker_AST_Repair |
                       Final_RM_Integrated_Closure_Blocker_Abstract_Refined_State |
                       Final_RM_Integrated_Closure_Blocker_Volatile_Atomic_Shared_State |
                       Final_RM_Integrated_Closure_Blocker_Cross_Unit |
                       Final_RM_Integrated_Closure_Blocker_Generic_Shared_State |
                       Final_RM_Integrated_Closure_Blocker_Overload_Type |
                       Final_RM_Integrated_Closure_Blocker_Representation_Freezing |
                       Final_RM_Integrated_Closure_Blocker_Tasking_Protected |
                       Final_RM_Integrated_Closure_Blocker_Elaboration |
                       Final_RM_Integrated_Closure_Blocker_Accessibility |
                       Final_RM_Integrated_Closure_Blocker_Exception_Finalization |
                       Final_RM_Integrated_Closure_Blocker_Predicate_Invariant |
                       Final_RM_Integrated_Closure_Blocker_Dataflow |
                       Final_RM_Integrated_Closure_Blocker_Source_Fingerprint |
                       Final_RM_Integrated_Closure_Blocker_Substitution_Fingerprint |
                       Final_RM_Integrated_Closure_Blocker_Multiple_Prerequisites;
   end Is_Blocked;

   procedure Set_Result
     (Status  : out Final_RM_Integrated_Closure_Status;
      Action  : out Final_RM_Integrated_Closure_Action;
      Blocker : out Final_RM_Integrated_Blocker_Family;
      S       : Final_RM_Integrated_Closure_Status;
      A       : Final_RM_Integrated_Closure_Action;
      B       : Final_RM_Integrated_Blocker_Family) is
   begin
      Status := S;
      Action := A;
      Blocker := B;
   end Set_Result;

   procedure Classify
     (Context : Final_RM_Integrated_Closure_Context;
      Status  : out Final_RM_Integrated_Closure_Status;
      Action  : out Final_RM_Integrated_Closure_Action;
      Blocker : out Final_RM_Integrated_Blocker_Family) is
      Blocker_Count : Natural := 0;

      procedure Note_Blocker is
      begin
         Blocker_Count := Blocker_Count + 1;
      end Note_Blocker;

   begin
      Status := Final_RM_Integrated_Closure_Accepted_Current;
      Action := Final_RM_Integrated_Closure_Action_Accept_Current;
      Blocker := Final_RM_Integrated_Blocker_None;

      if Context.Source_Fingerprint /= Context.Expected_Source_Fingerprint then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Source_Fingerprint,
                     Final_RM_Integrated_Closure_Action_Block_Source_Fingerprint,
                     Final_RM_Integrated_Blocker_Source_Fingerprint);
         return;
      elsif Context.Substitution_Fingerprint /= Context.Expected_Substitution_Fingerprint then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Substitution_Fingerprint,
                     Final_RM_Integrated_Closure_Action_Block_Substitution_Fingerprint,
                     Final_RM_Integrated_Blocker_Substitution_Fingerprint);
         return;
      end if;

      if not Context.Has_Final_Stabilized_Closure then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Final_Stabilized_Closure,
                     Final_RM_Integrated_Closure_Action_Block_Final_Base,
                     Final_RM_Integrated_Blocker_Missing_Final_Stabilized_Closure);
         return;
      elsif Final_Base_Recheck (Context.Final_Stabilized_Closure) then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Recheck_Required,
                     Final_RM_Integrated_Closure_Action_Recheck,
                     Final_RM_Integrated_Blocker_Recheck_Required);
         return;
      elsif Final_Base_Indeterminate (Context.Final_Stabilized_Closure) then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Indeterminate,
                     Final_RM_Integrated_Closure_Action_Degrade,
                     Final_RM_Integrated_Blocker_Indeterminate);
         return;
      elsif not Final_Base_Accepted (Context.Final_Stabilized_Closure) then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Final_Stabilized_Closure,
                     Final_RM_Integrated_Closure_Action_Block_Final_Base,
                     Final_RM_Integrated_Blocker_Final_Stabilized_Closure);
         return;
      end if;

      if not Context.Has_RM_Completion_Closure then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_RM_Completion_Closure,
                     Final_RM_Integrated_Closure_Action_Block_RM_Completion,
                     Final_RM_Integrated_Blocker_Missing_RM_Completion_Closure);
         return;
      elsif Context.RM_Completion_Closure.Recheck_Required then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Recheck_Required,
                     Final_RM_Integrated_Closure_Action_Recheck,
                     Final_RM_Integrated_Blocker_Recheck_Required);
         return;
      elsif Context.RM_Completion_Closure.Status = RM_Completion.RM_Completion_Stabilized_Closure_Indeterminate then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Indeterminate,
                     Final_RM_Integrated_Closure_Action_Degrade,
                     Final_RM_Integrated_Blocker_Indeterminate);
         return;
      elsif not Context.RM_Completion_Closure.Accepted then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_RM_Completion_Closure,
                     Final_RM_Integrated_Closure_Action_Block_RM_Completion,
                     Final_RM_Integrated_Blocker_RM_Completion_Closure);
         return;
      end if;

      if not Context.Has_Direct_Consumer_Closure then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Direct_Consumer_Closure,
                     Final_RM_Integrated_Closure_Action_Block_Direct_Consumer,
                     Final_RM_Integrated_Blocker_Missing_Direct_Consumer_Closure);
         return;
      elsif Context.Direct_Consumer_Closure.Recheck_Required then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Recheck_Required,
                     Final_RM_Integrated_Closure_Action_Recheck,
                     Final_RM_Integrated_Blocker_Recheck_Required);
         return;
      elsif Context.Direct_Consumer_Closure.Status = Consumers.RM_Closure_Consumer_Stabilized_Closure_Indeterminate then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Indeterminate,
                     Final_RM_Integrated_Closure_Action_Degrade,
                     Final_RM_Integrated_Blocker_Indeterminate);
         return;
      elsif not Context.Direct_Consumer_Closure.Accepted then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Direct_Consumer_Closure,
                     Final_RM_Integrated_Closure_Action_Block_Direct_Consumer,
                     Final_RM_Integrated_Blocker_Direct_Consumer_Closure);
         return;
      end if;

      if not Context.Has_Remaining_Edge_Closure then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Remaining_Edge_Closure,
                     Final_RM_Integrated_Closure_Action_Block_Remaining_Edge,
                     Final_RM_Integrated_Blocker_Missing_Remaining_Edge_Closure);
         return;
      elsif Context.Remaining_Edge_Closure.Recheck_Required then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Recheck_Required,
                     Final_RM_Integrated_Closure_Action_Recheck,
                     Final_RM_Integrated_Blocker_Recheck_Required);
         return;
      elsif Context.Remaining_Edge_Closure.Status = Remaining_Edge.Remaining_RM_Edge_Stabilized_Closure_Indeterminate then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Indeterminate,
                     Final_RM_Integrated_Closure_Action_Degrade,
                     Final_RM_Integrated_Blocker_Indeterminate);
         return;
      elsif not Context.Remaining_Edge_Closure.Accepted then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Remaining_Edge_Closure,
                     Final_RM_Integrated_Closure_Action_Block_Remaining_Edge,
                     Final_RM_Integrated_Blocker_Remaining_Edge_Closure);
         return;
      end if;

      if Context.Requires_AST_Repair_Evidence then
         if not Context.Has_AST_Repair_Evidence then
            Set_Result (Status, Action, Blocker,
                        Final_RM_Integrated_Closure_Blocker_AST_Repair,
                        Final_RM_Integrated_Closure_Action_Block_AST_Repair,
                        Final_RM_Integrated_Blocker_Missing_AST_Repair);
            return;
         elsif AST_Repair_Recheck (Context.AST_Repair_Evidence) then
            Set_Result (Status, Action, Blocker,
                        Final_RM_Integrated_Closure_Recheck_Required,
                        Final_RM_Integrated_Closure_Action_Recheck,
                        Final_RM_Integrated_Blocker_Recheck_Required);
            return;
         elsif AST_Repair_Indeterminate (Context.AST_Repair_Evidence) then
            Set_Result (Status, Action, Blocker,
                        Final_RM_Integrated_Closure_Indeterminate,
                        Final_RM_Integrated_Closure_Action_Degrade,
                        Final_RM_Integrated_Blocker_Indeterminate);
            return;
         elsif not AST_Repair_Accepted (Context.AST_Repair_Evidence) then
            Set_Result (Status, Action, Blocker,
                        Final_RM_Integrated_Closure_Blocker_AST_Repair,
                        Final_RM_Integrated_Closure_Action_Block_AST_Repair,
                        Final_RM_Integrated_Blocker_AST_Repair);
            return;
         end if;
      end if;

      if (not Context.Has_Abstract_Refined_State_Evidence) or else
        (not Context.Abstract_Refined_State_Accepted)
      then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Abstract_Refined_State,
                     Final_RM_Integrated_Closure_Action_Block_State,
                     Final_RM_Integrated_Blocker_Abstract_Refined_State);
      end if;
      if (not Context.Has_Volatile_Atomic_Shared_State_Evidence) or else
        (not Context.Volatile_Atomic_Shared_State_Accepted)
      then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Volatile_Atomic_Shared_State,
                     Final_RM_Integrated_Closure_Action_Block_Effects,
                     Final_RM_Integrated_Blocker_Volatile_Atomic_Shared_State);
      end if;
      if (not Context.Has_Cross_Unit_Evidence) or else (not Context.Cross_Unit_Accepted) then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Cross_Unit,
                     Final_RM_Integrated_Closure_Action_Block_Cross_Unit,
                     Final_RM_Integrated_Blocker_Cross_Unit);
      end if;
      if (not Context.Has_Generic_Shared_State_Evidence) or else
        (not Context.Generic_Shared_State_Accepted)
      then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Generic_Shared_State,
                     Final_RM_Integrated_Closure_Action_Block_Generic,
                     Final_RM_Integrated_Blocker_Generic_Shared_State);
      end if;
      if (not Context.Has_Overload_Type_Evidence) or else (not Context.Overload_Type_Accepted) then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Overload_Type,
                     Final_RM_Integrated_Closure_Action_Block_Overload,
                     Final_RM_Integrated_Blocker_Overload_Type);
      end if;
      if (not Context.Has_Representation_Evidence) or else (not Context.Representation_Accepted) then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Representation_Freezing,
                     Final_RM_Integrated_Closure_Action_Block_Representation,
                     Final_RM_Integrated_Blocker_Representation_Freezing);
      end if;
      if (not Context.Has_Tasking_Evidence) or else (not Context.Tasking_Accepted) then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Tasking_Protected,
                     Final_RM_Integrated_Closure_Action_Block_Tasking,
                     Final_RM_Integrated_Blocker_Tasking_Protected);
      end if;
      if (not Context.Has_Elaboration_Evidence) or else (not Context.Elaboration_Accepted) then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Elaboration,
                     Final_RM_Integrated_Closure_Action_Block_Elaboration,
                     Final_RM_Integrated_Blocker_Elaboration);
      end if;
      if (not Context.Has_Accessibility_Evidence) or else (not Context.Accessibility_Accepted) then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Accessibility,
                     Final_RM_Integrated_Closure_Action_Block_Accessibility,
                     Final_RM_Integrated_Blocker_Accessibility);
      end if;
      if (not Context.Has_Exception_Finalization_Evidence) or else
        (not Context.Exception_Finalization_Accepted)
      then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Exception_Finalization,
                     Final_RM_Integrated_Closure_Action_Block_Exception,
                     Final_RM_Integrated_Blocker_Exception_Finalization);
      end if;
      if (not Context.Has_Predicate_Evidence) or else (not Context.Predicate_Accepted) then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Predicate_Invariant,
                     Final_RM_Integrated_Closure_Action_Block_Predicate,
                     Final_RM_Integrated_Blocker_Predicate_Invariant);
      end if;
      if (not Context.Has_Dataflow_Evidence) or else (not Context.Dataflow_Accepted) then
         Note_Blocker;
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Dataflow,
                     Final_RM_Integrated_Closure_Action_Block_Dataflow,
                     Final_RM_Integrated_Blocker_Dataflow);
      end if;

      if Blocker_Count > 1 then
         Set_Result (Status, Action, Blocker,
                     Final_RM_Integrated_Closure_Blocker_Multiple_Prerequisites,
                     Final_RM_Integrated_Closure_Action_Split_Prerequisites,
                     Final_RM_Integrated_Blocker_Multiple_Prerequisites);
      elsif Status = Final_RM_Integrated_Closure_Accepted_Current and then
        Context.RM_Completion_Closure.Status = RM_Completion.RM_Completion_Stabilized_Closure_Accepted_Not_Required and then
        Context.Direct_Consumer_Closure.Status = Consumers.RM_Closure_Consumer_Stabilized_Closure_Accepted_Not_Required and then
        Context.Remaining_Edge_Closure.Status = Remaining_Edge.Remaining_RM_Edge_Stabilized_Closure_Accepted_Not_Required
      then
         Status := Final_RM_Integrated_Closure_Accepted_Not_Required;
         Action := Final_RM_Integrated_Closure_Action_Accept_Not_Required;
      end if;
   end Classify;

   function Message_For
     (Status  : Final_RM_Integrated_Closure_Status;
      Action  : Final_RM_Integrated_Closure_Action;
      Blocker : Final_RM_Integrated_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("final RM integrated semantic closure " &
         Final_RM_Integrated_Closure_Status'Image (Status) &
         " action=" & Final_RM_Integrated_Closure_Action'Image (Action) &
         " blocker=" & Final_RM_Integrated_Blocker_Family'Image (Blocker));
   end Message_For;

   function Row_Fingerprint (Row : Final_RM_Integrated_Closure_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_960;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Final_RM_Integrated_Closure_Status'Pos (Row.Status) + 1);
      H := Mix (H, Final_RM_Integrated_Closure_Action'Pos (Row.Action) + 1);
      H := Mix (H, Final_RM_Integrated_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      H := Mix (H, Row.Final_Closure_Fingerprint);
      H := Mix (H, Row.RM_Completion_Fingerprint);
      H := Mix (H, Row.Direct_Consumer_Fingerprint);
      H := Mix (H, Row.Remaining_Edge_Fingerprint);
      H := Mix (H, Row.AST_Repair_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Context : Final_RM_Integrated_Closure_Context;
      Index   : Positive) return Final_RM_Integrated_Closure_Row is
      Status  : Final_RM_Integrated_Closure_Status;
      Action  : Final_RM_Integrated_Closure_Action;
      Blocker : Final_RM_Integrated_Blocker_Family;
      Row     : Final_RM_Integrated_Closure_Row;
   begin
      Classify (Context, Status, Action, Blocker);
      Row.Id := Final_RM_Integrated_Closure_Id (Index);
      Row.Context := Context.Id;
      Row.Status := Status;
      Row.Action := Action;
      Row.Blocker_Family := Blocker;
      Row.Node := Context.Node;
      Row.Construct_Name := Context.Construct_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Current := Status = Final_RM_Integrated_Closure_Accepted_Current;
      Row.Blocked := Is_Blocked (Status);
      Row.Recheck_Required := Status = Final_RM_Integrated_Closure_Recheck_Required;
      Row.Blocks_Downstream := Row.Blocked or else Row.Recheck_Required or else
        Status = Final_RM_Integrated_Closure_Indeterminate;
      Row.Has_Final_Stabilized_Closure := Context.Has_Final_Stabilized_Closure;
      Row.Has_RM_Completion_Closure := Context.Has_RM_Completion_Closure;
      Row.Has_Direct_Consumer_Closure := Context.Has_Direct_Consumer_Closure;
      Row.Has_Remaining_Edge_Closure := Context.Has_Remaining_Edge_Closure;
      Row.Has_AST_Repair_Evidence := Context.Has_AST_Repair_Evidence;
      Row.Source_Fingerprint := Context.Source_Fingerprint;
      Row.Substitution_Fingerprint := Context.Substitution_Fingerprint;
      if Context.Has_Final_Stabilized_Closure then
         Row.Final_Closure_Fingerprint := Context.Final_Stabilized_Closure.Closure_Fingerprint;
      end if;
      if Context.Has_RM_Completion_Closure then
         Row.RM_Completion_Fingerprint := Context.RM_Completion_Closure.Closure_Fingerprint;
      end if;
      if Context.Has_Direct_Consumer_Closure then
         Row.Direct_Consumer_Fingerprint := Context.Direct_Consumer_Closure.Closure_Fingerprint;
      end if;
      if Context.Has_Remaining_Edge_Closure then
         Row.Remaining_Edge_Fingerprint := Context.Remaining_Edge_Closure.Closure_Fingerprint;
      end if;
      if Context.Has_AST_Repair_Evidence then
         Row.AST_Repair_Fingerprint := Context.AST_Repair_Evidence.Row_Fingerprint;
      end if;
      Row.Start_Line := Context.Start_Line;
      Row.Start_Column := Context.Start_Column;
      Row.End_Line := Context.End_Line;
      Row.End_Column := Context.End_Column;
      Row.Message := Message_For (Status, Action, Blocker);
      Row.Integrated_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out Final_RM_Integrated_Closure_Model;
      Row   : Final_RM_Integrated_Closure_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Integrated_Fingerprint);
      if Row.Accepted then
         Model.Accepted_Total := Model.Accepted_Total + 1;
      end if;
      if Row.Blocked then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;
      if Row.Recheck_Required then
         Model.Recheck_Total := Model.Recheck_Total + 1;
      end if;
      if Row.Status = Final_RM_Integrated_Closure_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Final_RM_Integrated_Closure_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Final_RM_Integrated_Closure_Context_Model;
      Context : Final_RM_Integrated_Closure_Context) is
   begin
      Model.Items.Append (Context);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Context.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Context.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Source_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Final_RM_Integrated_Closure_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Final_RM_Integrated_Closure_Context_Model;
      Index : Positive) return Final_RM_Integrated_Closure_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Build
     (Contexts : Final_RM_Integrated_Closure_Context_Model)
      return Final_RM_Integrated_Closure_Model is
      Model : Final_RM_Integrated_Closure_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         Add_Row (Model, Make_Row (Context_At (Contexts, I), I));
      end loop;
      return Model;
   end Build;

   function Count (Model : Final_RM_Integrated_Closure_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Final_RM_Integrated_Closure_Model;
      Index : Positive) return Final_RM_Integrated_Closure_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Final_RM_Integrated_Closure_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Final_RM_Integrated_Closure_Set;
      Index : Positive) return Final_RM_Integrated_Closure_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Final_RM_Integrated_Closure_Set;
      Row : Final_RM_Integrated_Closure_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Integrated_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Final_RM_Integrated_Closure_Model;
      Status : Final_RM_Integrated_Closure_Status) return Final_RM_Integrated_Closure_Set is
      Result : Final_RM_Integrated_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Final_RM_Integrated_Closure_Model;
      Family : Final_RM_Integrated_Blocker_Family) return Final_RM_Integrated_Closure_Set is
      Result : Final_RM_Integrated_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Query_Node
     (Model : Final_RM_Integrated_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_RM_Integrated_Closure_Set is
      Result : Final_RM_Integrated_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Count_By_Status
     (Model  : Final_RM_Integrated_Closure_Model;
      Status : Final_RM_Integrated_Closure_Status) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Final_RM_Integrated_Closure_Model;
      Family : Final_RM_Integrated_Blocker_Family) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Final_RM_Integrated_Closure_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Final_RM_Integrated_Closure_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Recheck_Required_Count (Model : Final_RM_Integrated_Closure_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Final_RM_Integrated_Closure_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Final_RM_Integrated_Closure_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Final_RM_Integrated_Semantic_Closure_Legality;
