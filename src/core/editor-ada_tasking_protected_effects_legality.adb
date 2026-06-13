with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Protected_Effects_Legality is

   function Mix (Seed, Value : Natural) return Natural is
   begin
      return (Seed * 131 + Value + 17) mod 2_147_483_647;
   end Mix;

   function Node_Value (Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural is
   begin
      return Natural (Node);
   end Node_Value;

   function Text_Value (Text : Ada.Strings.Unbounded.Unbounded_String) return Natural is
      S : constant String := To_String (Text);
      R : Natural := 0;
   begin
      for Ch of S loop
         R := Mix (R, Character'Pos (Ch));
      end loop;
      return R;
   end Text_Value;

   function Is_Flow_Error (Status : Flow.Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status not in Flow.Flow_Graph_Not_Checked
        | Flow.Flow_Graph_Legal_Read_Edge
        | Flow.Flow_Graph_Legal_Write_Edge
        | Flow.Flow_Graph_Legal_Read_Write_Edge
        | Flow.Flow_Graph_Legal_Depends_Edge
        | Flow.Flow_Graph_Legal_Call_Propagation
        | Flow.Flow_Graph_Legal_Generic_Substitution
        | Flow.Flow_Graph_Legal_Protected_State_Effect
        | Flow.Flow_Graph_Legal_Task_Activation_Effect
        | Flow.Flow_Graph_Legal_Refined_Global
        | Flow.Flow_Graph_Legal_Refined_Depends
        | Flow.Flow_Graph_Legal_Null_Effect;
   end Is_Flow_Error;

   function Is_Elaboration_Error
     (Status : Elab.Elaboration_Graph_Closure_Status) return Boolean is
   begin
      return Status not in Elab.Graph_Closure_Not_Checked
        | Elab.Graph_Closure_Legal_Library_Edge
        | Elab.Graph_Closure_Legal_Transitive_Elaborate_All
        | Elab.Graph_Closure_Legal_Body_Before_Use
        | Elab.Graph_Closure_Legal_Direct_Call_Order
        | Elab.Graph_Closure_Legal_Indirect_Call_Order
        | Elab.Graph_Closure_Legal_Dispatching_Call_Order
        | Elab.Graph_Closure_Legal_Access_Order
        | Elab.Graph_Closure_Legal_Generic_Instance_Order
        | Elab.Graph_Closure_Legal_Default_Expression_Order
        | Elab.Graph_Closure_Legal_Aspect_Expression_Order
        | Elab.Graph_Closure_Legal_Representation_Item_Order
        | Elab.Graph_Closure_Legal_Preelaboration_Policy
        | Elab.Graph_Closure_Legal_Pure_Policy;
   end Is_Elaboration_Error;

   function Is_Scope_Error (Status : Scope.Scope_Legality_Status) return Boolean is
   begin
      return Status not in Scope.Scope_Legality_Not_Checked
        | Scope.Scope_Legality_Legal_Master_Hierarchy
        | Scope.Scope_Legality_Legal_Static_Level
        | Scope.Scope_Legality_Legal_Dynamic_Check
        | Scope.Scope_Legality_Legal_Allocator_Master
        | Scope.Scope_Legality_Legal_Return_Object_Master
        | Scope.Scope_Legality_Legal_Return_Access_Master
        | Scope.Scope_Legality_Legal_Access_Discriminant_Master
        | Scope.Scope_Legality_Legal_Access_Conversion
        | Scope.Scope_Legality_Legal_Generic_Substitution
        | Scope.Scope_Legality_Legal_Discriminant_Aggregate;
   end Is_Scope_Error;

   function Is_Precision_Error
     (Status : Precision.Tasking_Precision_Status) return Boolean is
   begin
      return Status not in Precision.Tasking_Precision_Not_Checked
        | Precision.Tasking_Precision_Legal_Task_Activation
        | Precision.Tasking_Precision_Legal_Task_Body
        | Precision.Tasking_Precision_Legal_Protected_Function
        | Precision.Tasking_Precision_Legal_Protected_Procedure
        | Precision.Tasking_Precision_Legal_Protected_Entry
        | Precision.Tasking_Precision_Legal_Entry_Barrier
        | Precision.Tasking_Precision_Legal_Entry_Family_Index
        | Precision.Tasking_Precision_Legal_Accept
        | Precision.Tasking_Precision_Legal_Requeue
        | Precision.Tasking_Precision_Legal_Select_Alternative
        | Precision.Tasking_Precision_Legal_Queued_Entry_Call;
   end Is_Precision_Error;

   function Is_Finalization_Error
     (Status : Finalization.Exception_Legality_Status) return Boolean is
   begin
      return Status not in Finalization.Exception_Legality_Not_Checked
        | Finalization.Exception_Legality_Legal_Raise_Statement
        | Finalization.Exception_Legality_Legal_Raise_Expression
        | Finalization.Exception_Legality_Legal_Reraise
        | Finalization.Exception_Legality_Legal_Handler
        | Finalization.Exception_Legality_Legal_Exception_Renaming
        | Finalization.Exception_Legality_Legal_Propagation
        | Finalization.Exception_Legality_Legal_Finalization
        | Finalization.Exception_Legality_Legal_No_Return;
   end Is_Finalization_Error;

   function Is_Gate_Error (Status : Gates.Enforcement_Status) return Boolean is
   begin
      return Status in Gates.Enforcement_Legal_Result_Suppressed
        | Gates.Enforcement_Derived_Result_Suppressed
        | Gates.Enforcement_Parser_AST_Blocker
        | Gates.Enforcement_Metadata_Blocker
        | Gates.Enforcement_Consumer_Integration_Blocker
        | Gates.Enforcement_Unsafe_Result_Blocked;
   end Is_Gate_Error;

   function Is_Legal (Status : Tasking_Effect_Status) return Boolean is
   begin
      return Status in Tasking_Effect_Legal_Task_Activation
        | Tasking_Effect_Legal_Task_Termination
        | Tasking_Effect_Legal_Protected_Read
        | Tasking_Effect_Legal_Protected_Write
        | Tasking_Effect_Legal_Protected_Function_Call
        | Tasking_Effect_Legal_Protected_Procedure_Call
        | Tasking_Effect_Legal_Protected_Entry_Call
        | Tasking_Effect_Legal_Entry_Queue
        | Tasking_Effect_Legal_Entry_Barrier
        | Tasking_Effect_Legal_Accept_Body
        | Tasking_Effect_Legal_Requeue
        | Tasking_Effect_Legal_Select_Guard
        | Tasking_Effect_Legal_Select_Alternative
        | Tasking_Effect_Legal_Delay_Alternative
        | Tasking_Effect_Legal_Terminate_Alternative;
   end Is_Legal;

   function Status_For (Context : Tasking_Effect_Context_Info) return Tasking_Effect_Status is
      Blockers : Natural := 0;
      Status   : Tasking_Effect_Status := Tasking_Effect_Not_Checked;

      procedure Add_Blocker (Candidate : Tasking_Effect_Status) is
      begin
         Blockers := Blockers + 1;
         if Status = Tasking_Effect_Not_Checked then
            Status := Candidate;
         else
            Status := Tasking_Effect_Multiple_Blockers;
         end if;
      end Add_Blocker;
   begin
      if Is_Gate_Error (Context.Gate_Status) then
         Add_Blocker (Tasking_Effect_Coverage_Gate_Blocker);
      end if;

      if Is_Precision_Error (Context.Precision_Status) then
         Add_Blocker (Tasking_Effect_Linked_Precision_Error);
      end if;

      if Is_Flow_Error (Context.Flow_Status) then
         case Context.Flow_Status is
            when Flow.Flow_Graph_Read_Not_In_Global =>
               Add_Blocker (Tasking_Effect_Protected_Read_Not_In_Global);
            when Flow.Flow_Graph_Write_Not_In_Global
               | Flow.Flow_Graph_Write_To_In_Global =>
               Add_Blocker (Tasking_Effect_Protected_Write_Not_In_Global);
            when Flow.Flow_Graph_Protected_Function_Writes_State =>
               Add_Blocker (Tasking_Effect_Protected_Function_Writes_State);
            when Flow.Flow_Graph_Protected_Barrier_Reads_Uncovered_State =>
               Add_Blocker (Tasking_Effect_Select_Guard_Effect_Mismatch);
            when others =>
               Add_Blocker (Tasking_Effect_Linked_Flow_Error);
         end case;
      end if;

      if Is_Elaboration_Error (Context.Elaboration_Status) then
         Add_Blocker (Tasking_Effect_Linked_Elaboration_Error);
      end if;

      if Is_Scope_Error (Context.Scope_Status) then
         if Context.Kind = Tasking_Effect_Context_Entry_Queue then
            Add_Blocker (Tasking_Effect_Entry_Queue_Accessibility_Error);
         else
            Add_Blocker (Tasking_Effect_Linked_Accessibility_Error);
         end if;
      end if;

      if Is_Finalization_Error (Context.Finalization_Status) then
         Add_Blocker (Tasking_Effect_Linked_Finalization_Error);
      end if;

      if not Context.Task_Body_Elaborated then
         Add_Blocker (Tasking_Effect_Task_Activation_Missing_Elaboration);
      end if;

      if not Context.Task_Finalization_Safe then
         Add_Blocker (Tasking_Effect_Task_Termination_Finalization_Error);
      end if;

      if Context.Writes_Protected_State
        and then Context.Kind = Tasking_Effect_Context_Protected_Function_Call
      then
         Add_Blocker (Tasking_Effect_Protected_Function_Writes_State);
      end if;

      if Context.Calls_Protected_Entry
        and then Context.Kind = Tasking_Effect_Context_Protected_Function_Call
      then
         Add_Blocker (Tasking_Effect_Protected_Function_Calls_Entry);
      end if;

      if Context.Kind = Tasking_Effect_Context_Entry_Queue then
         if not Context.Queue_Target_Resolved then
            Add_Blocker (Tasking_Effect_Entry_Queue_Target_Unresolved);
         elsif not Context.Queue_Target_Open then
            Add_Blocker (Tasking_Effect_Requeue_Target_Not_Open);
         elsif Context.Queue_Object_Finalized then
            Add_Blocker (Tasking_Effect_Entry_Queue_Finalized_Object);
         end if;
      end if;

      if Context.Kind = Tasking_Effect_Context_Accept_Body then
         if not Context.Accept_State_Effect_Matches then
            Add_Blocker (Tasking_Effect_Accept_Body_State_Effect_Mismatch);
         elsif not Context.Task_Body_Elaborated then
            Add_Blocker (Tasking_Effect_Accept_Body_Not_Elaborated);
         end if;
      end if;

      if Context.Kind = Tasking_Effect_Context_Requeue then
         if not Context.Requeue_Target_Resolved then
            Add_Blocker (Tasking_Effect_Requeue_Target_Unresolved);
         elsif not Context.Requeue_Target_Open then
            Add_Blocker (Tasking_Effect_Requeue_Target_Not_Open);
         elsif Context.Requeue_With_Abort and then not Context.Requeue_Abort_Safe then
            Add_Blocker (Tasking_Effect_Requeue_With_Abort_Unsafe);
         end if;
      end if;

      if Context.Kind = Tasking_Effect_Context_Select_Guard then
         if not Context.Select_Guard_Boolean then
            Add_Blocker (Tasking_Effect_Select_Guard_Not_Boolean);
         elsif not Context.Select_Guard_Effect_Matches then
            Add_Blocker (Tasking_Effect_Select_Guard_Effect_Mismatch);
         end if;
      end if;

      if Context.Kind = Tasking_Effect_Context_Select_Alternative then
         if not Context.Select_Alternative_Reachable then
            Add_Blocker (Tasking_Effect_Select_Alternative_Unreachable);
         elsif Context.Select_Terminate_With_Delay then
            Add_Blocker (Tasking_Effect_Select_Terminate_With_Delay);
         end if;
      end if;

      if Context.Kind = Tasking_Effect_Context_Abortable_Part
        and then not Context.Abortable_Finalization_Safe
      then
         Add_Blocker (Tasking_Effect_Abortable_Part_Finalization_Unsafe);
      end if;

      if Context.Kind = Tasking_Effect_Context_Delay_Alternative
        and then not Context.Delay_Time_Static
      then
         Add_Blocker (Tasking_Effect_Delay_Alternative_Non_Static_Time);
      end if;

      if Context.Kind = Tasking_Effect_Context_Terminate_Alternative
        and then not Context.Terminate_Allowed
      then
         Add_Blocker (Tasking_Effect_Terminate_Alternative_Not_Allowed);
      end if;

      if Status /= Tasking_Effect_Not_Checked then
         return Status;
      end if;

      case Context.Kind is
         when Tasking_Effect_Context_Task_Activation =>
            return Tasking_Effect_Legal_Task_Activation;
         when Tasking_Effect_Context_Task_Termination =>
            return Tasking_Effect_Legal_Task_Termination;
         when Tasking_Effect_Context_Protected_Read =>
            return Tasking_Effect_Legal_Protected_Read;
         when Tasking_Effect_Context_Protected_Write =>
            return Tasking_Effect_Legal_Protected_Write;
         when Tasking_Effect_Context_Protected_Function_Call =>
            return Tasking_Effect_Legal_Protected_Function_Call;
         when Tasking_Effect_Context_Protected_Procedure_Call =>
            return Tasking_Effect_Legal_Protected_Procedure_Call;
         when Tasking_Effect_Context_Protected_Entry_Call =>
            return Tasking_Effect_Legal_Protected_Entry_Call;
         when Tasking_Effect_Context_Entry_Queue =>
            return Tasking_Effect_Legal_Entry_Queue;
         when Tasking_Effect_Context_Entry_Barrier =>
            return Tasking_Effect_Legal_Entry_Barrier;
         when Tasking_Effect_Context_Accept_Body =>
            return Tasking_Effect_Legal_Accept_Body;
         when Tasking_Effect_Context_Requeue =>
            return Tasking_Effect_Legal_Requeue;
         when Tasking_Effect_Context_Select_Guard =>
            return Tasking_Effect_Legal_Select_Guard;
         when Tasking_Effect_Context_Select_Alternative =>
            return Tasking_Effect_Legal_Select_Alternative;
         when Tasking_Effect_Context_Delay_Alternative =>
            return Tasking_Effect_Legal_Delay_Alternative;
         when Tasking_Effect_Context_Terminate_Alternative =>
            return Tasking_Effect_Legal_Terminate_Alternative;
         when others =>
            return Tasking_Effect_Indeterminate;
      end case;
   end Status_For;

   function Blocker_Count (Context : Tasking_Effect_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if Is_Gate_Error (Context.Gate_Status) then Count := Count + 1; end if;
      if Is_Precision_Error (Context.Precision_Status) then Count := Count + 1; end if;
      if Is_Flow_Error (Context.Flow_Status) then Count := Count + 1; end if;
      if Is_Elaboration_Error (Context.Elaboration_Status) then Count := Count + 1; end if;
      if Is_Scope_Error (Context.Scope_Status) then Count := Count + 1; end if;
      if Is_Finalization_Error (Context.Finalization_Status) then Count := Count + 1; end if;
      if not Context.Task_Body_Elaborated then Count := Count + 1; end if;
      if not Context.Task_Finalization_Safe then Count := Count + 1; end if;
      if Context.Writes_Protected_State and then Context.Kind = Tasking_Effect_Context_Protected_Function_Call then Count := Count + 1; end if;
      if Context.Calls_Protected_Entry and then Context.Kind = Tasking_Effect_Context_Protected_Function_Call then Count := Count + 1; end if;
      if Context.Kind = Tasking_Effect_Context_Entry_Queue then
         if (not Context.Queue_Target_Resolved) or else (not Context.Queue_Target_Open) or else Context.Queue_Object_Finalized then Count := Count + 1; end if;
      end if;
      if Context.Kind = Tasking_Effect_Context_Accept_Body then
         if (not Context.Accept_State_Effect_Matches) or else (not Context.Task_Body_Elaborated) then Count := Count + 1; end if;
      end if;
      if Context.Kind = Tasking_Effect_Context_Requeue then
         if (not Context.Requeue_Target_Resolved) or else (not Context.Requeue_Target_Open) or else (Context.Requeue_With_Abort and then not Context.Requeue_Abort_Safe) then Count := Count + 1; end if;
      end if;
      if Context.Kind = Tasking_Effect_Context_Select_Guard then
         if (not Context.Select_Guard_Boolean) or else (not Context.Select_Guard_Effect_Matches) then Count := Count + 1; end if;
      end if;
      if Context.Kind = Tasking_Effect_Context_Select_Alternative then
         if (not Context.Select_Alternative_Reachable) or else Context.Select_Terminate_With_Delay then Count := Count + 1; end if;
      end if;
      if Context.Kind = Tasking_Effect_Context_Abortable_Part and then not Context.Abortable_Finalization_Safe then Count := Count + 1; end if;
      if Context.Kind = Tasking_Effect_Context_Delay_Alternative and then not Context.Delay_Time_Static then Count := Count + 1; end if;
      if Context.Kind = Tasking_Effect_Context_Terminate_Alternative and then not Context.Terminate_Allowed then Count := Count + 1; end if;
      return Count;
   end Blocker_Count;

   function Message_For (Status : Tasking_Effect_Status) return String is
   begin
      case Status is
         when Tasking_Effect_Legal_Task_Activation => return "legal task activation effect";
         when Tasking_Effect_Legal_Task_Termination => return "legal task termination effect";
         when Tasking_Effect_Legal_Protected_Read => return "legal protected read effect";
         when Tasking_Effect_Legal_Protected_Write => return "legal protected write effect";
         when Tasking_Effect_Legal_Protected_Function_Call => return "legal protected function call effect";
         when Tasking_Effect_Legal_Protected_Procedure_Call => return "legal protected procedure call effect";
         when Tasking_Effect_Legal_Protected_Entry_Call => return "legal protected entry call effect";
         when Tasking_Effect_Legal_Entry_Queue => return "legal entry queue effect";
         when Tasking_Effect_Legal_Entry_Barrier => return "legal entry barrier effect";
         when Tasking_Effect_Legal_Accept_Body => return "legal accept body effect";
         when Tasking_Effect_Legal_Requeue => return "legal requeue effect";
         when Tasking_Effect_Legal_Select_Guard => return "legal select guard effect";
         when Tasking_Effect_Legal_Select_Alternative => return "legal select alternative effect";
         when Tasking_Effect_Legal_Delay_Alternative => return "legal delay alternative effect";
         when Tasking_Effect_Legal_Terminate_Alternative => return "legal terminate alternative effect";
         when Tasking_Effect_Multiple_Blockers => return "multiple tasking/protected effect blockers";
         when Tasking_Effect_Indeterminate => return "indeterminate tasking/protected effect legality";
         when others => return "illegal tasking/protected effect";
      end case;
   end Message_For;

   function To_Info (Context : Tasking_Effect_Context_Info) return Tasking_Effect_Info is
      Status : constant Tasking_Effect_Status := Status_For (Context);
      Blocks : constant Natural := Blocker_Count (Context);
      Info   : Tasking_Effect_Info;
      F      : Natural := Context.Source_Fingerprint;
   begin
      Info.Id := Context.Id;
      Info.Kind := Context.Kind;
      Info.Status := Status;
      Info.Node := Context.Node;
      Info.Task_Node := Context.Task_Node;
      Info.Protected_Node := Context.Protected_Node;
      Info.Entry_Node := Context.Entry_Node;
      Info.Object_Name := Context.Object_Name;
      Info.Entry_Name := Context.Entry_Name;
      Info.Queue_Name := Context.Queue_Name;
      Info.Message := To_Unbounded_String (Message_For (Status));
      Info.Detail := To_Unbounded_String ("tasking/protected effect semantic closure");
      Info.Precision_Status := Context.Precision_Status;
      Info.Flow_Status := Context.Flow_Status;
      Info.Elaboration_Status := Context.Elaboration_Status;
      Info.Scope_Status := Context.Scope_Status;
      Info.Finalization_Status := Context.Finalization_Status;
      Info.Gate_Status := Context.Gate_Status;
      Info.Blocker_Count := Blocks;
      Info.Start_Line := Context.Start_Line;
      Info.Start_Column := Context.Start_Column;
      Info.End_Line := Context.End_Line;
      Info.End_Column := Context.End_Column;
      Info.Source_Fingerprint := Context.Source_Fingerprint;
      F := Mix (F, Natural (Context.Id));
      F := Mix (F, Tasking_Effect_Context_Kind'Pos (Context.Kind));
      F := Mix (F, Tasking_Effect_Status'Pos (Status));
      F := Mix (F, Node_Value (Context.Node));
      F := Mix (F, Text_Value (Context.Object_Name));
      F := Mix (F, Text_Value (Context.Entry_Name));
      F := Mix (F, Blocks);
      Info.Fingerprint := F;
      return Info;
   end To_Info;

   procedure Clear (Model : in out Tasking_Effect_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Tasking_Effect_Context_Model;
      Context : Tasking_Effect_Context_Info) is
   begin
      Model.Contexts.Append (Context);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Context.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Tasking_Effect_Context_Kind'Pos (Context.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Node_Value (Context.Node));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Context.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Tasking_Effect_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Tasking_Effect_Context_Model;
      Index : Positive) return Tasking_Effect_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Tasking_Effect_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   procedure Add_Row
     (Model : in out Tasking_Effect_Model;
      Info  : Tasking_Effect_Info) is
   begin
      Model.Items.Append (Info);
      if Is_Legal (Info.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      elsif Info.Status = Tasking_Effect_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;

      case Info.Status is
         when Tasking_Effect_Entry_Queue_Target_Unresolved
            | Tasking_Effect_Entry_Queue_Accessibility_Error
            | Tasking_Effect_Entry_Queue_Finalized_Object =>
            Model.Queue_Error_Total := Model.Queue_Error_Total + 1;
         when Tasking_Effect_Select_Guard_Not_Boolean
            | Tasking_Effect_Select_Guard_Effect_Mismatch
            | Tasking_Effect_Select_Alternative_Unreachable
            | Tasking_Effect_Select_Terminate_With_Delay
            | Tasking_Effect_Delay_Alternative_Non_Static_Time
            | Tasking_Effect_Terminate_Alternative_Not_Allowed =>
            Model.Select_Error_Total := Model.Select_Error_Total + 1;
         when Tasking_Effect_Protected_Read_Not_In_Global
            | Tasking_Effect_Protected_Write_Not_In_Global
            | Tasking_Effect_Protected_Function_Writes_State
            | Tasking_Effect_Protected_Function_Calls_Entry
            | Tasking_Effect_Protected_Procedure_Barrier_Error
            | Tasking_Effect_Protected_Entry_Barrier_Error =>
            Model.Protected_State_Error_Total := Model.Protected_State_Error_Total + 1;
         when Tasking_Effect_Requeue_Target_Unresolved
            | Tasking_Effect_Requeue_Target_Not_Open
            | Tasking_Effect_Requeue_With_Abort_Unsafe =>
            Model.Requeue_Error_Total := Model.Requeue_Error_Total + 1;
         when Tasking_Effect_Task_Termination_Finalization_Error
            | Tasking_Effect_Abortable_Part_Finalization_Unsafe
            | Tasking_Effect_Linked_Finalization_Error =>
            Model.Finalization_Error_Total := Model.Finalization_Error_Total + 1;
         when Tasking_Effect_Linked_Precision_Error
            | Tasking_Effect_Linked_Flow_Error
            | Tasking_Effect_Linked_Elaboration_Error
            | Tasking_Effect_Linked_Accessibility_Error =>
            Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
         when Tasking_Effect_Coverage_Gate_Blocker =>
            Model.Coverage_Gate_Error_Total := Model.Coverage_Gate_Error_Total + 1;
         when others =>
            null;
      end case;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
   end Add_Row;

   function Build
     (Contexts : Tasking_Effect_Context_Model) return Tasking_Effect_Model is
      Model : Tasking_Effect_Model;
   begin
      for C of Contexts.Contexts loop
         Add_Row (Model, To_Info (C));
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Tasking_Effect_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Tasking_Effect_Model;
      Index : Positive) return Tasking_Effect_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Tasking_Effect_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Effect_Info is
   begin
      for Info of Model.Items loop
         if Info.Node = Node then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Tasking_Effect_Model;
      Status : Tasking_Effect_Status) return Tasking_Effect_Set is
      Results : Tasking_Effect_Set;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Results.Items.Append (Info);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Info.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Tasking_Effect_Model;
      Kind  : Tasking_Effect_Context_Kind) return Tasking_Effect_Set is
      Results : Tasking_Effect_Set;
   begin
      for Info of Model.Items loop
         if Info.Kind = Kind then
            Results.Items.Append (Info);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Info.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Object
     (Model : Tasking_Effect_Model;
      Name  : String) return Tasking_Effect_Set is
      Results : Tasking_Effect_Set;
   begin
      for Info of Model.Items loop
         if To_String (Info.Object_Name) = Name then
            Results.Items.Append (Info);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Info.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Object;

   function Rows_For_Entry
     (Model : Tasking_Effect_Model;
      Name  : String) return Tasking_Effect_Set is
      Results : Tasking_Effect_Set;
   begin
      for Info of Model.Items loop
         if To_String (Info.Entry_Name) = Name then
            Results.Items.Append (Info);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Info.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Entry;

   function Result_Count (Results : Tasking_Effect_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Tasking_Effect_Set;
      Index   : Positive) return Tasking_Effect_Info is
   begin
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Tasking_Effect_Model;
      Status : Tasking_Effect_Status) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Tasking_Effect_Model;
      Kind  : Tasking_Effect_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Tasking_Effect_Model) return Natural is begin return Model.Legal_Total; end Legal_Count;
   function Error_Count (Model : Tasking_Effect_Model) return Natural is begin return Model.Error_Total; end Error_Count;
   function Queue_Error_Count (Model : Tasking_Effect_Model) return Natural is begin return Model.Queue_Error_Total; end Queue_Error_Count;
   function Select_Error_Count (Model : Tasking_Effect_Model) return Natural is begin return Model.Select_Error_Total; end Select_Error_Count;
   function Protected_State_Error_Count (Model : Tasking_Effect_Model) return Natural is begin return Model.Protected_State_Error_Total; end Protected_State_Error_Count;
   function Requeue_Error_Count (Model : Tasking_Effect_Model) return Natural is begin return Model.Requeue_Error_Total; end Requeue_Error_Count;
   function Finalization_Error_Count (Model : Tasking_Effect_Model) return Natural is begin return Model.Finalization_Error_Total; end Finalization_Error_Count;
   function Linked_Error_Count (Model : Tasking_Effect_Model) return Natural is begin return Model.Linked_Error_Total; end Linked_Error_Count;
   function Coverage_Gate_Error_Count (Model : Tasking_Effect_Model) return Natural is begin return Model.Coverage_Gate_Error_Total; end Coverage_Gate_Error_Count;
   function Indeterminate_Count (Model : Tasking_Effect_Model) return Natural is begin return Model.Indeterminate_Total; end Indeterminate_Count;
   function Fingerprint (Model : Tasking_Effect_Model) return Natural is begin return Model.Result_Fingerprint; end Fingerprint;

   function Has_Error (Info : Tasking_Effect_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status)
        and then Info.Status /= Tasking_Effect_Not_Checked
        and then Info.Status /= Tasking_Effect_Indeterminate;
   end Has_Error;

end Editor.Ada_Tasking_Protected_Effects_Legality;
