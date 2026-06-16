with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality is

   pragma Suppress (Overflow_Check);

   use type Dataflow.Dataflow_Context_Kind;
   use type Dataflow.Dataflow_Effect_Kind;
   use type Dataflow.Dataflow_Legality_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Flow.Flow_Edge_Id;
   use type Flow.Flow_Effect_Graph_Status;
   use type Init_Obj.Initialization_Object_Flow_Row_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 16_777_619 + B + 193) mod 2_147_483_647;
   end Mix;

   function Text (Value : Unbounded_String) return String is
   begin
      return To_String (Value);
   end Text;

   function Is_Dataflow_Legal
     (Status : Dataflow.Dataflow_Legality_Status) return Boolean is
   begin
      return Status in
        Dataflow.Dataflow_Legality_Legal_Read |
        Dataflow.Dataflow_Legality_Legal_Write |
        Dataflow.Dataflow_Legality_Legal_Read_Write |
        Dataflow.Dataflow_Legality_Legal_Null_Effect |
        Dataflow.Dataflow_Legality_Legal_Depends_Edge |
        Dataflow.Dataflow_Legality_Legal_Refinement;
   end Is_Dataflow_Legal;

   function Is_Flow_Legal
     (Status : Flow.Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status in
        Flow.Flow_Graph_Legal_Read_Edge |
        Flow.Flow_Graph_Legal_Write_Edge |
        Flow.Flow_Graph_Legal_Read_Write_Edge |
        Flow.Flow_Graph_Legal_Depends_Edge |
        Flow.Flow_Graph_Legal_Call_Propagation |
        Flow.Flow_Graph_Legal_Generic_Substitution |
        Flow.Flow_Graph_Legal_Protected_State_Effect |
        Flow.Flow_Graph_Legal_Task_Activation_Effect |
        Flow.Flow_Graph_Legal_Refined_Global |
        Flow.Flow_Graph_Legal_Refined_Depends |
        Flow.Flow_Graph_Legal_Null_Effect;
   end Is_Flow_Legal;

   function Is_Init_Legal
     (Status : Init_Obj.Initialization_Object_Flow_Status) return Boolean is
   begin
      return Status in
        Init_Obj.Initialization_Object_Flow_Legal_Definite_Init_Accepted |
        Init_Obj.Initialization_Object_Flow_Legal_Default_Init_Accepted |
        Init_Obj.Initialization_Object_Flow_Legal_Explicit_Init_Accepted |
        Init_Obj.Initialization_Object_Flow_Legal_Component_Init_Accepted |
        Init_Obj.Initialization_Object_Flow_Legal_Out_Parameter_Accepted |
        Init_Obj.Initialization_Object_Flow_Legal_Return_Object_Accepted |
        Init_Obj.Initialization_Object_Flow_Legal_Exception_Path_Accepted |
        Init_Obj.Initialization_Object_Flow_Legal_Finalization_Path_Accepted;
   end Is_Init_Legal;

   function Legal_Status_For
     (Info : Dataflow_Init_Context_Info) return Dataflow_Init_Status is
   begin
      if Info.Propagates_Call then
         return Dataflow_Init_Legal_Call_Propagation_Accepted;
      elsif Info.Generic_Effect then
         return Dataflow_Init_Legal_Generic_Effect_Accepted;
      elsif Info.Tasking_Protected_Effect then
         return Dataflow_Init_Legal_Task_Protected_Effect_Accepted;
      end if;

      case Info.Dataflow_Status is
         when Dataflow.Dataflow_Legality_Legal_Read =>
            return Dataflow_Init_Legal_Read_Accepted;
         when Dataflow.Dataflow_Legality_Legal_Write =>
            return Dataflow_Init_Legal_Write_Accepted;
         when Dataflow.Dataflow_Legality_Legal_Read_Write =>
            return Dataflow_Init_Legal_Read_Write_Accepted;
         when Dataflow.Dataflow_Legality_Legal_Null_Effect =>
            return Dataflow_Init_Legal_Null_Effect_Accepted;
         when Dataflow.Dataflow_Legality_Legal_Depends_Edge =>
            return Dataflow_Init_Legal_Depends_Edge_Accepted;
         when Dataflow.Dataflow_Legality_Legal_Refinement =>
            return Dataflow_Init_Legal_Refinement_Accepted;
         when others =>
            return Dataflow_Init_Indeterminate;
      end case;
   end Legal_Status_For;

   function Status_From_Flow
     (Status : Flow.Flow_Effect_Graph_Status) return Dataflow_Init_Status is
   begin
      case Status is
         when Flow.Flow_Graph_Read_Not_In_Global |
              Flow.Flow_Graph_Write_Not_In_Global |
              Flow.Flow_Graph_Write_To_In_Global |
              Flow.Flow_Graph_Read_From_Out_Global |
              Flow.Flow_Graph_Null_Global_Violated |
              Flow.Flow_Graph_Body_Spec_Global_Mismatch |
              Flow.Flow_Graph_Refined_Global_Missing_Item |
              Flow.Flow_Graph_Refined_Global_Extra_Item =>
            return Dataflow_Init_Flow_Global_Blocker;
         when Flow.Flow_Graph_Body_Spec_Depends_Mismatch |
              Flow.Flow_Graph_Refined_Depends_Missing_Source |
              Flow.Flow_Graph_Refined_Depends_Target_Not_Output |
              Flow.Flow_Graph_Refined_Depends_Source_Not_Input |
              Flow.Flow_Graph_Dependency_Cycle =>
            return Dataflow_Init_Flow_Depends_Blocker;
         when Flow.Flow_Graph_Call_Effect_Not_Propagated =>
            return Dataflow_Init_Flow_Propagation_Blocker;
         when Flow.Flow_Graph_Generic_Actual_Missing_Effect |
              Flow.Flow_Graph_Generic_Actual_Mode_Mismatch =>
            return Dataflow_Init_Flow_Generic_Blocker;
         when Flow.Flow_Graph_Protected_Function_Writes_State |
              Flow.Flow_Graph_Protected_Barrier_Reads_Uncovered_State |
              Flow.Flow_Graph_Task_Activation_Effect_Missing_Global =>
            return Dataflow_Init_Flow_Tasking_Protected_Blocker;
         when Flow.Flow_Graph_Coverage_Gate_Blocker =>
            return Dataflow_Init_Flow_Coverage_Blocker;
         when Flow.Flow_Graph_Linked_Dataflow_Error |
              Flow.Flow_Graph_Duplicate_Edge =>
            return Dataflow_Init_Flow_Linked_Dataflow_Blocker;
         when Flow.Flow_Graph_Indeterminate |
              Flow.Flow_Graph_Not_Checked =>
            return Dataflow_Init_Indeterminate;
         when others =>
            if Is_Flow_Legal (Status) then
               return Dataflow_Init_Not_Checked;
            else
               return Dataflow_Init_Flow_Linked_Dataflow_Blocker;
            end if;
      end case;
   end Status_From_Flow;

   function Status_From_Initialization
     (Status : Init_Obj.Initialization_Object_Flow_Status) return Dataflow_Init_Status is
   begin
      case Status is
         when Init_Obj.Initialization_Object_Flow_Preserved_Read_Before_Write =>
            return Dataflow_Init_Read_Before_Write_Blocker;
         when Init_Obj.Initialization_Object_Flow_Preserved_Component_Read_Before_Write =>
            return Dataflow_Init_Component_Read_Before_Write_Blocker;
         when Init_Obj.Initialization_Object_Flow_Preserved_Partial_Component_Init =>
            return Dataflow_Init_Partial_Component_Init_Blocker;
         when Init_Obj.Initialization_Object_Flow_Preserved_Out_Parameter_Not_Assigned =>
            return Dataflow_Init_Out_Parameter_Not_Assigned_Blocker;
         when Init_Obj.Initialization_Object_Flow_Preserved_In_Out_Conditional_Assignment =>
            return Dataflow_Init_In_Out_Conditional_Assignment_Blocker;
         when Init_Obj.Initialization_Object_Flow_Preserved_Return_Object_Not_Initialized =>
            return Dataflow_Init_Return_Object_Not_Initialized_Blocker;
         when Init_Obj.Initialization_Object_Flow_Preserved_Branch_Merge_Not_Definite |
              Init_Obj.Initialization_Object_Flow_Preserved_Loop_Merge_Not_Definite =>
            return Dataflow_Init_Branch_Loop_Merge_Blocker;
         when Init_Obj.Initialization_Object_Flow_Preserved_Exception_Path_Loss =>
            return Dataflow_Init_Exception_Path_Loss_Blocker;
         when Init_Obj.Initialization_Object_Flow_Preserved_Finalization_Uses_Uninitialized =>
            return Dataflow_Init_Finalization_Uses_Uninitialized_Blocker;
         when Init_Obj.Initialization_Object_Flow_Preserved_Use_After_Finalization =>
            return Dataflow_Init_Use_After_Finalization_Blocker;
         when Init_Obj.Initialization_Object_Flow_Return_Lifetime_Blocker |
              Init_Obj.Initialization_Object_Flow_Allocator_Lifetime_Blocker |
              Init_Obj.Initialization_Object_Flow_Access_Lifetime_Blocker |
              Init_Obj.Initialization_Object_Flow_Generic_Lifetime_Blocker =>
            return Dataflow_Init_Lifetime_Blocker;
         when Init_Obj.Initialization_Object_Flow_Discriminant_Variant_Blocker |
              Init_Obj.Initialization_Object_Flow_Representation_Blocker =>
            return Dataflow_Init_Discriminant_Representation_Blocker;
         when Init_Obj.Initialization_Object_Flow_Coverage_Blocker =>
            return Dataflow_Init_Coverage_Blocker;
         when Init_Obj.Initialization_Object_Flow_Linked_Accessibility_Blocker |
              Init_Obj.Initialization_Object_Flow_Linked_Generic_Replay_Blocker |
              Init_Obj.Initialization_Object_Flow_Preserved_Linked_Initialization_Error =>
            return Dataflow_Init_Linked_Initialization_Blocker;
         when Init_Obj.Initialization_Object_Flow_Missing_Object_Flow_Row =>
            return Dataflow_Init_Missing_Initialization_Object_Flow_Row;
         when Init_Obj.Initialization_Object_Flow_Mismatched_Object_Flow_Kind =>
            return Dataflow_Init_Mismatched_Initialization_Object;
         when Init_Obj.Initialization_Object_Flow_Multiple_Object_Flow_Blockers =>
            return Dataflow_Init_Multiple_Blockers;
         when Init_Obj.Initialization_Object_Flow_Indeterminate |
              Init_Obj.Initialization_Object_Flow_Not_Checked =>
            return Dataflow_Init_Indeterminate;
         when others =>
            if Is_Init_Legal (Status) then
               return Dataflow_Init_Not_Checked;
            else
               return Dataflow_Init_Linked_Initialization_Blocker;
            end if;
      end case;
   end Status_From_Initialization;

   function Status_For
     (Info : Dataflow_Init_Context_Info) return Dataflow_Init_Status is
      Flow_Status : Dataflow_Init_Status;
      Init_Status : Dataflow_Init_Status;
      Needs_Flow  : constant Boolean :=
        Info.Effect /= Dataflow.Dataflow_Effect_Null and then
        Info.Dataflow_Status /= Dataflow.Dataflow_Legality_Legal_Null_Effect;
      Needs_Init  : constant Boolean :=
        Info.Reads_Object or else Info.Writes_Object or else
        Info.Effect in Dataflow.Dataflow_Effect_Read |
                       Dataflow.Dataflow_Effect_Write |
                       Dataflow.Dataflow_Effect_Read_Write;
   begin
      if not Is_Dataflow_Legal (Info.Dataflow_Status) then
         if Info.Dataflow_Status = Dataflow.Dataflow_Legality_Not_Checked or else
           Info.Dataflow_Status = Dataflow.Dataflow_Legality_Indeterminate
         then
            return Dataflow_Init_Indeterminate;
         else
            return Dataflow_Init_Base_Dataflow_Error;
         end if;
      end if;

      if Needs_Flow then
         if Info.Flow_Edge_Row = Flow.No_Flow_Edge or else Info.Flow_Matches = 0 then
            return Dataflow_Init_Missing_Flow_Edge_Row;
         end if;

         Flow_Status := Status_From_Flow (Info.Flow_Status);
         if Flow_Status /= Dataflow_Init_Not_Checked then
            return Flow_Status;
         end if;
      end if;

      if Needs_Init then
         if Info.Initialization_Row = Init_Obj.No_Initialization_Object_Flow_Row or else
           Info.Initialization_Matches = 0
         then
            return Dataflow_Init_Missing_Initialization_Object_Flow_Row;
         end if;

         Init_Status := Status_From_Initialization (Info.Initialization_Status);
         if Init_Status /= Dataflow_Init_Not_Checked then
            return Init_Status;
         end if;
      end if;

      return Legal_Status_For (Info);
   end Status_For;

   function Message_For (Status : Dataflow_Init_Status) return String is
   begin
      case Status is
         when Dataflow_Init_Legal_Read_Accepted => return "Global read accepted with definite initialization evidence";
         when Dataflow_Init_Legal_Write_Accepted => return "Global write accepted with object-flow evidence";
         when Dataflow_Init_Legal_Read_Write_Accepted => return "Global read/write accepted with initialization evidence";
         when Dataflow_Init_Legal_Null_Effect_Accepted => return "Null Global/Depends effect accepted";
         when Dataflow_Init_Legal_Depends_Edge_Accepted => return "Depends edge accepted with initialized source evidence";
         when Dataflow_Init_Legal_Refinement_Accepted => return "Refined Global/Depends effect accepted";
         when Dataflow_Init_Legal_Call_Propagation_Accepted => return "Call flow propagation accepted";
         when Dataflow_Init_Legal_Generic_Effect_Accepted => return "Generic flow effect accepted";
         when Dataflow_Init_Legal_Task_Protected_Effect_Accepted => return "Tasking/protected flow effect accepted";
         when Dataflow_Init_Base_Dataflow_Error => return "Base Global/Depends dataflow legality error preserved";
         when Dataflow_Init_Missing_Flow_Edge_Row => return "Missing matching flow-effect graph row";
         when Dataflow_Init_Flow_Global_Blocker => return "Flow graph Global coverage blocker";
         when Dataflow_Init_Flow_Depends_Blocker => return "Flow graph Depends coverage blocker";
         when Dataflow_Init_Flow_Propagation_Blocker => return "Flow graph call propagation blocker";
         when Dataflow_Init_Flow_Generic_Blocker => return "Flow graph generic effect blocker";
         when Dataflow_Init_Flow_Tasking_Protected_Blocker => return "Flow graph tasking/protected effect blocker";
         when Dataflow_Init_Flow_Coverage_Blocker => return "Flow graph coverage blocker";
         when Dataflow_Init_Flow_Linked_Dataflow_Blocker => return "Linked flow/dataflow blocker";
         when Dataflow_Init_Missing_Initialization_Object_Flow_Row => return "Missing definite-initialization object-flow evidence";
         when Dataflow_Init_Mismatched_Initialization_Object => return "Mismatched definite-initialization object-flow evidence";
         when Dataflow_Init_Read_Before_Write_Blocker => return "Read before write blocks Global/Depends flow";
         when Dataflow_Init_Component_Read_Before_Write_Blocker => return "Component read before write blocks flow";
         when Dataflow_Init_Partial_Component_Init_Blocker => return "Partial component initialization blocks flow";
         when Dataflow_Init_Out_Parameter_Not_Assigned_Blocker => return "Out parameter assignment obligation blocks flow";
         when Dataflow_Init_In_Out_Conditional_Assignment_Blocker => return "Conditional in out assignment blocks flow";
         when Dataflow_Init_Return_Object_Not_Initialized_Blocker => return "Return object initialization obligation blocks flow";
         when Dataflow_Init_Branch_Loop_Merge_Blocker => return "Branch/loop merge initialization proof blocks flow";
         when Dataflow_Init_Exception_Path_Loss_Blocker => return "Exception path loses initialization";
         when Dataflow_Init_Finalization_Uses_Uninitialized_Blocker => return "Finalization uses uninitialized object";
         when Dataflow_Init_Use_After_Finalization_Blocker => return "Use after finalization blocks flow";
         when Dataflow_Init_Lifetime_Blocker => return "Exact lifetime/accessibility evidence blocks flow";
         when Dataflow_Init_Discriminant_Representation_Blocker => return "Discriminant or representation evidence blocks flow";
         when Dataflow_Init_Coverage_Blocker => return "Coverage repair gate blocks flow";
         when Dataflow_Init_Linked_Initialization_Blocker => return "Linked initialization/object-flow blocker";
         when Dataflow_Init_Multiple_Blockers => return "Multiple initialization/object-flow blockers";
         when Dataflow_Init_Indeterminate => return "Dataflow definite-initialization state is indeterminate";
         when Dataflow_Init_Not_Checked => return "Dataflow definite-initialization consumer not checked";
      end case;
   end Message_For;

   function Fingerprint_For (Info : Dataflow_Init_Info) return Natural is
      F : Natural := Natural (Info.Id);
   begin
      F := Mix (F, Dataflow_Init_Status'Pos (Info.Status) + 1);
      F := Mix (F, Dataflow.Dataflow_Context_Kind'Pos (Info.Kind) + 1);
      F := Mix (F, Dataflow.Dataflow_Effect_Kind'Pos (Info.Effect) + 1);
      F := Mix (F, Natural (Info.Node));
      F := Mix (F, Natural (Info.Dataflow_Row));
      F := Mix (F, Dataflow.Dataflow_Legality_Status'Pos (Info.Dataflow_Status) + 1);
      F := Mix (F, Natural (Info.Flow_Edge_Row));
      F := Mix (F, Flow.Flow_Effect_Graph_Status'Pos (Info.Flow_Status) + 1);
      F := Mix (F, Natural (Info.Initialization_Row));
      F := Mix (F, Init_Obj.Initialization_Object_Flow_Status'Pos (Info.Initialization_Status) + 1);
      F := Mix (F, Info.Source_Fingerprint);
      F := Mix (F, Info.Dataflow_Fingerprint);
      F := Mix (F, Info.Flow_Fingerprint);
      F := Mix (F, Info.Initialization_Fingerprint);
      return F;
   end Fingerprint_For;

   function To_Row
     (Info : Dataflow_Init_Context_Info;
      Id   : Dataflow_Init_Row_Id) return Dataflow_Init_Info is
      Status : constant Dataflow_Init_Status := Status_For (Info);
      Row    : Dataflow_Init_Info;
   begin
      Row.Id := Id;
      Row.Context := Info.Id;
      Row.Kind := Info.Kind;
      Row.Effect := Info.Effect;
      Row.Status := Status;
      Row.Node := Info.Node;
      Row.Object_Name := Info.Object_Name;
      Row.Source_Name := Info.Source_Name;
      Row.Target_Name := Info.Target_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String
        ("Dataflow=" & Dataflow.Dataflow_Legality_Status'Image (Info.Dataflow_Status) &
         "; Flow=" & Flow.Flow_Effect_Graph_Status'Image (Info.Flow_Status) &
         "; Init=" & Init_Obj.Initialization_Object_Flow_Status'Image (Info.Initialization_Status));
      Row.Dataflow_Row := Info.Dataflow_Row;
      Row.Dataflow_Status := Info.Dataflow_Status;
      Row.Flow_Edge_Row := Info.Flow_Edge_Row;
      Row.Flow_Status := Info.Flow_Status;
      Row.Flow_Edge := Info.Flow_Edge;
      Row.Flow_Matches := Info.Flow_Matches;
      Row.Initialization_Row := Info.Initialization_Row;
      Row.Initialization_Status := Info.Initialization_Status;
      Row.Initialization_Matches := Info.Initialization_Matches;
      Row.Reads_Object := Info.Reads_Object;
      Row.Writes_Object := Info.Writes_Object;
      Row.Propagates_Call := Info.Propagates_Call;
      Row.Generic_Effect := Info.Generic_Effect;
      Row.Tasking_Protected_Effect := Info.Tasking_Protected_Effect;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Dataflow_Fingerprint := Info.Dataflow_Fingerprint;
      Row.Flow_Fingerprint := Info.Flow_Fingerprint;
      Row.Initialization_Fingerprint := Info.Initialization_Fingerprint;
      Row.Fingerprint := Fingerprint_For (Row);
      return Row;
   end To_Row;

   procedure Clear (Model : in out Dataflow_Init_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Dataflow_Init_Context_Model;
      Info  : Dataflow_Init_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Node));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Dataflow.Dataflow_Legality_Status'Pos (Info.Dataflow_Status) + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Init_Obj.Initialization_Object_Flow_Status'Pos (Info.Initialization_Status) + 1);
   end Add_Context;

   function Context_Count (Model : Dataflow_Init_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Dataflow_Init_Context_Model;
      Index : Positive) return Dataflow_Init_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Dataflow_Init_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Dataflow_Init_Context_Model) return Dataflow_Init_Model is
      Model : Dataflow_Init_Model;
      Next  : Dataflow_Init_Row_Id := 1;
      Row   : Dataflow_Init_Info;
   begin
      for C of Contexts.Contexts loop
         Row := To_Row (C, Next);
         Model.Rows.Append (Row);
         Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
         Next := Next + 1;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Dataflow_Init_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Dataflow_Init_Model;
      Index : Positive) return Dataflow_Init_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Dataflow_Init_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Dataflow_Init_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Dataflow_Init_Model;
      Status : Dataflow_Init_Status) return Dataflow_Init_Set is
      Results : Dataflow_Init_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Dataflow_Init_Model;
      Kind  : Dataflow.Dataflow_Context_Kind) return Dataflow_Init_Set is
      Results : Dataflow_Init_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Object
     (Model : Dataflow_Init_Model;
      Name  : String) return Dataflow_Init_Set is
      Results : Dataflow_Init_Set;
   begin
      for Row of Model.Rows loop
         if Text (Row.Object_Name) = Name or else Text (Row.Source_Name) = Name or else Text (Row.Target_Name) = Name then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Object;

   function Set_Count (Results : Dataflow_Init_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Set_Count;

   function Set_At
     (Results : Dataflow_Init_Set;
      Index   : Positive) return Dataflow_Init_Info is
   begin
      return Results.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Dataflow_Init_Model;
      Status : Dataflow_Init_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Dataflow_Init_Model;
      Kind  : Dataflow.Dataflow_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Is_Legal (Status : Dataflow_Init_Status) return Boolean is
   begin
      return Status in
        Dataflow_Init_Legal_Read_Accepted |
        Dataflow_Init_Legal_Write_Accepted |
        Dataflow_Init_Legal_Read_Write_Accepted |
        Dataflow_Init_Legal_Null_Effect_Accepted |
        Dataflow_Init_Legal_Depends_Edge_Accepted |
        Dataflow_Init_Legal_Refinement_Accepted |
        Dataflow_Init_Legal_Call_Propagation_Accepted |
        Dataflow_Init_Legal_Generic_Effect_Accepted |
        Dataflow_Init_Legal_Task_Protected_Effect_Accepted;
   end Is_Legal;

   function Is_Flow_Error (Status : Dataflow_Init_Status) return Boolean is
   begin
      return Status in
        Dataflow_Init_Missing_Flow_Edge_Row |
        Dataflow_Init_Flow_Global_Blocker |
        Dataflow_Init_Flow_Depends_Blocker |
        Dataflow_Init_Flow_Propagation_Blocker |
        Dataflow_Init_Flow_Generic_Blocker |
        Dataflow_Init_Flow_Tasking_Protected_Blocker |
        Dataflow_Init_Flow_Coverage_Blocker |
        Dataflow_Init_Flow_Linked_Dataflow_Blocker;
   end Is_Flow_Error;

   function Is_Initialization_Error (Status : Dataflow_Init_Status) return Boolean is
   begin
      return Status in
        Dataflow_Init_Missing_Initialization_Object_Flow_Row |
        Dataflow_Init_Mismatched_Initialization_Object |
        Dataflow_Init_Read_Before_Write_Blocker |
        Dataflow_Init_Component_Read_Before_Write_Blocker |
        Dataflow_Init_Partial_Component_Init_Blocker |
        Dataflow_Init_Out_Parameter_Not_Assigned_Blocker |
        Dataflow_Init_In_Out_Conditional_Assignment_Blocker |
        Dataflow_Init_Return_Object_Not_Initialized_Blocker |
        Dataflow_Init_Branch_Loop_Merge_Blocker |
        Dataflow_Init_Exception_Path_Loss_Blocker |
        Dataflow_Init_Finalization_Uses_Uninitialized_Blocker |
        Dataflow_Init_Use_After_Finalization_Blocker |
        Dataflow_Init_Linked_Initialization_Blocker |
        Dataflow_Init_Multiple_Blockers;
   end Is_Initialization_Error;

   function Is_Lifetime_Error (Status : Dataflow_Init_Status) return Boolean is
   begin
      return Status = Dataflow_Init_Lifetime_Blocker;
   end Is_Lifetime_Error;

   function Is_Representation_Error (Status : Dataflow_Init_Status) return Boolean is
   begin
      return Status = Dataflow_Init_Discriminant_Representation_Blocker;
   end Is_Representation_Error;

   function Is_Coverage_Error (Status : Dataflow_Init_Status) return Boolean is
   begin
      return Status in Dataflow_Init_Coverage_Blocker | Dataflow_Init_Flow_Coverage_Blocker;
   end Is_Coverage_Error;

   function Is_Error (Status : Dataflow_Init_Status) return Boolean is
   begin
      return Status = Dataflow_Init_Base_Dataflow_Error or else
        Is_Flow_Error (Status) or else
        Is_Initialization_Error (Status) or else
        Is_Lifetime_Error (Status) or else
        Is_Representation_Error (Status) or else
        Is_Coverage_Error (Status);
   end Is_Error;

   function Legal_Count (Model : Dataflow_Init_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Dataflow_Init_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Flow_Error_Count (Model : Dataflow_Init_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Flow_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Flow_Error_Count;

   function Initialization_Error_Count (Model : Dataflow_Init_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Initialization_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Initialization_Error_Count;

   function Lifetime_Error_Count (Model : Dataflow_Init_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Lifetime_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Lifetime_Error_Count;

   function Representation_Error_Count (Model : Dataflow_Init_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Representation_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Error_Count;

   function Coverage_Error_Count (Model : Dataflow_Init_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Coverage_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Coverage_Error_Count;

   function Indeterminate_Count (Model : Dataflow_Init_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Dataflow_Init_Indeterminate then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Indeterminate_Count;

   function Fingerprint (Model : Dataflow_Init_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
