package body Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality is

   pragma Suppress (Overflow_Check);

   use type Accessibility_RM.Accessibility_RM_Completion_Row_Id;
   use type AST_Repair.Coverage_Proven_AST_Repair_Id;
   use type Cross_RM.Cross_Unit_RM_Completion_Closure_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elaboration_RM.Elaboration_RM_Completion_Row_Id;
   use type Exception_RM.Exception_RM_Completion_Row_Id;
   use type Overload_RM.Overload_Generic_RM_Edge_Completion_Id;
   use type Predicate_RM.Predicate_RM_Completion_Row_Id;
   use type Prior_Dataflow.Dataflow_Generic_Final_Row_Id;
   use type Representation_RM.Representation_Generic_RM_Hard_Case_Id;
   use type Tasking_RM.Tasking_Generic_RM_Hard_Case_Id;

   function AST_Repair_Accepted
     (Status : AST_Repair.Coverage_Proven_AST_Repair_Status) return Boolean is
   begin
      case Status is
         when AST_Repair.Coverage_Proven_AST_Repair_Not_Required |
              AST_Repair.Coverage_Proven_AST_Repair_Parser_Node_Repaired |
              AST_Repair.Coverage_Proven_AST_Repair_Structural_AST_Repaired |
              AST_Repair.Coverage_Proven_AST_Repair_Token_Only_Parse_Repaired |
              AST_Repair.Coverage_Proven_AST_Repair_Source_Span_Repaired |
              AST_Repair.Coverage_Proven_AST_Repair_Metadata_Repaired |
              AST_Repair.Coverage_Proven_AST_Repair_Consumer_Integration_Repaired =>
            return True;
         when others =>
            return False;
      end case;
   end AST_Repair_Accepted;

   function Is_Accepted (Status : Dataflow_RM_Completion_Status) return Boolean is
   begin
      case Status is
         when Dataflow_RM_Completion_Legal_Read_Accepted |
              Dataflow_RM_Completion_Legal_Write_Accepted |
              Dataflow_RM_Completion_Legal_Read_Write_Accepted |
              Dataflow_RM_Completion_Legal_Out_Parameter_Accepted |
              Dataflow_RM_Completion_Legal_In_Out_Parameter_Accepted |
              Dataflow_RM_Completion_Legal_Return_Object_Accepted |
              Dataflow_RM_Completion_Legal_Variant_Component_Accepted |
              Dataflow_RM_Completion_Legal_Access_Escape_Accepted |
              Dataflow_RM_Completion_Legal_Controlled_Finalization_Accepted |
              Dataflow_RM_Completion_Legal_Generic_Formal_Object_Accepted |
              Dataflow_RM_Completion_Legal_Volatile_Object_Accepted |
              Dataflow_RM_Completion_Legal_Atomic_Object_Accepted |
              Dataflow_RM_Completion_Legal_Dispatching_Call_Accepted |
              Dataflow_RM_Completion_Legal_Cross_Unit_State_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Accepted;

   function Is_Blocked (Status : Dataflow_RM_Completion_Status) return Boolean is
   begin
      return Status /= Dataflow_RM_Completion_Not_Checked and then not Is_Accepted (Status);
   end Is_Blocked;

   function Blocks_Downstream (Status : Dataflow_RM_Completion_Status) return Boolean is
   begin
      return Is_Blocked (Status);
   end Blocks_Downstream;

   function Accepted_For (Kind : Dataflow_RM_Completion_Kind) return Dataflow_RM_Completion_Status is
   begin
      case Kind is
         when Dataflow_RM_Completion_Read => return Dataflow_RM_Completion_Legal_Read_Accepted;
         when Dataflow_RM_Completion_Write => return Dataflow_RM_Completion_Legal_Write_Accepted;
         when Dataflow_RM_Completion_Read_Write => return Dataflow_RM_Completion_Legal_Read_Write_Accepted;
         when Dataflow_RM_Completion_Out_Parameter => return Dataflow_RM_Completion_Legal_Out_Parameter_Accepted;
         when Dataflow_RM_Completion_In_Out_Parameter => return Dataflow_RM_Completion_Legal_In_Out_Parameter_Accepted;
         when Dataflow_RM_Completion_Return_Object => return Dataflow_RM_Completion_Legal_Return_Object_Accepted;
         when Dataflow_RM_Completion_Variant_Component => return Dataflow_RM_Completion_Legal_Variant_Component_Accepted;
         when Dataflow_RM_Completion_Access_Escape => return Dataflow_RM_Completion_Legal_Access_Escape_Accepted;
         when Dataflow_RM_Completion_Controlled_Finalization => return Dataflow_RM_Completion_Legal_Controlled_Finalization_Accepted;
         when Dataflow_RM_Completion_Generic_Formal_Object => return Dataflow_RM_Completion_Legal_Generic_Formal_Object_Accepted;
         when Dataflow_RM_Completion_Volatile_Object => return Dataflow_RM_Completion_Legal_Volatile_Object_Accepted;
         when Dataflow_RM_Completion_Atomic_Object => return Dataflow_RM_Completion_Legal_Atomic_Object_Accepted;
         when Dataflow_RM_Completion_Dispatching_Call => return Dataflow_RM_Completion_Legal_Dispatching_Call_Accepted;
         when Dataflow_RM_Completion_Cross_Unit_State => return Dataflow_RM_Completion_Legal_Cross_Unit_State_Accepted;
         when Dataflow_RM_Completion_Unknown => return Dataflow_RM_Completion_Indeterminate;
      end case;
   end Accepted_For;

   function Blocker_Family_For
     (Status : Dataflow_RM_Completion_Status)
      return Dataflow_RM_Completion_Blocker_Family is
   begin
      case Status is
         when Dataflow_RM_Completion_Not_Checked |
              Dataflow_RM_Completion_Legal_Read_Accepted |
              Dataflow_RM_Completion_Legal_Write_Accepted |
              Dataflow_RM_Completion_Legal_Read_Write_Accepted |
              Dataflow_RM_Completion_Legal_Out_Parameter_Accepted |
              Dataflow_RM_Completion_Legal_In_Out_Parameter_Accepted |
              Dataflow_RM_Completion_Legal_Return_Object_Accepted |
              Dataflow_RM_Completion_Legal_Variant_Component_Accepted |
              Dataflow_RM_Completion_Legal_Access_Escape_Accepted |
              Dataflow_RM_Completion_Legal_Controlled_Finalization_Accepted |
              Dataflow_RM_Completion_Legal_Generic_Formal_Object_Accepted |
              Dataflow_RM_Completion_Legal_Volatile_Object_Accepted |
              Dataflow_RM_Completion_Legal_Atomic_Object_Accepted |
              Dataflow_RM_Completion_Legal_Dispatching_Call_Accepted |
              Dataflow_RM_Completion_Legal_Cross_Unit_State_Accepted =>
            return Dataflow_RM_Completion_Blocker_None;
         when Dataflow_RM_Completion_Missing_Prior_Dataflow_Row | Dataflow_RM_Completion_Prior_Dataflow_Blocker => return Dataflow_RM_Completion_Blocker_Prior_Dataflow;
         when Dataflow_RM_Completion_Missing_Cross_Unit_RM_Row | Dataflow_RM_Completion_Cross_Unit_RM_Blocker => return Dataflow_RM_Completion_Blocker_Cross_Unit_RM_Completion;
         when Dataflow_RM_Completion_Missing_Elaboration_RM_Row | Dataflow_RM_Completion_Elaboration_RM_Blocker => return Dataflow_RM_Completion_Blocker_Elaboration_RM_Completion;
         when Dataflow_RM_Completion_Missing_Accessibility_RM_Row | Dataflow_RM_Completion_Accessibility_RM_Blocker => return Dataflow_RM_Completion_Blocker_Accessibility_RM_Completion;
         when Dataflow_RM_Completion_Missing_Exception_RM_Row | Dataflow_RM_Completion_Exception_RM_Blocker => return Dataflow_RM_Completion_Blocker_Exception_Finalization_RM_Completion;
         when Dataflow_RM_Completion_Missing_Predicate_RM_Row | Dataflow_RM_Completion_Predicate_RM_Blocker => return Dataflow_RM_Completion_Blocker_Predicate_RM_Completion;
         when Dataflow_RM_Completion_Missing_Overload_RM_Row | Dataflow_RM_Completion_Overload_RM_Blocker => return Dataflow_RM_Completion_Blocker_Overload_RM_Completion;
         when Dataflow_RM_Completion_Missing_Representation_RM_Row | Dataflow_RM_Completion_Representation_RM_Blocker => return Dataflow_RM_Completion_Blocker_Representation_RM_Completion;
         when Dataflow_RM_Completion_Missing_Tasking_RM_Row | Dataflow_RM_Completion_Tasking_RM_Blocker => return Dataflow_RM_Completion_Blocker_Tasking_RM_Completion;
         when Dataflow_RM_Completion_Missing_AST_Repair_Row | Dataflow_RM_Completion_AST_Repair_Blocker => return Dataflow_RM_Completion_Blocker_AST_Repair;
         when Dataflow_RM_Completion_Read_Before_Write_Blocker => return Dataflow_RM_Completion_Blocker_Read_Before_Write;
         when Dataflow_RM_Completion_Partial_Component_Init_Blocker => return Dataflow_RM_Completion_Blocker_Partial_Component_Init;
         when Dataflow_RM_Completion_Out_Parameter_Blocker => return Dataflow_RM_Completion_Blocker_Out_Parameter;
         when Dataflow_RM_Completion_Return_Object_Blocker => return Dataflow_RM_Completion_Blocker_Return_Object;
         when Dataflow_RM_Completion_Branch_Loop_Merge_Blocker => return Dataflow_RM_Completion_Blocker_Branch_Loop_Merge;
         when Dataflow_RM_Completion_Exception_Path_Blocker => return Dataflow_RM_Completion_Blocker_Exception_Path;
         when Dataflow_RM_Completion_Finalization_Blocker => return Dataflow_RM_Completion_Blocker_Finalization;
         when Dataflow_RM_Completion_Access_Escape_Blocker => return Dataflow_RM_Completion_Blocker_Access_Escape;
         when Dataflow_RM_Completion_Variant_Component_Blocker => return Dataflow_RM_Completion_Blocker_Variant_Component;
         when Dataflow_RM_Completion_Volatile_Atomic_Effect_Blocker => return Dataflow_RM_Completion_Blocker_Volatile_Atomic_Effect;
         when Dataflow_RM_Completion_Generic_Substitution_Blocker => return Dataflow_RM_Completion_Blocker_Generic_Substitution;
         when Dataflow_RM_Completion_Dispatching_Effect_Blocker => return Dataflow_RM_Completion_Blocker_Dispatching_Effect;
         when Dataflow_RM_Completion_View_Barrier => return Dataflow_RM_Completion_Blocker_View_Barrier;
         when Dataflow_RM_Completion_Source_Fingerprint_Mismatch => return Dataflow_RM_Completion_Blocker_Source_Fingerprint;
         when Dataflow_RM_Completion_Substitution_Fingerprint_Mismatch => return Dataflow_RM_Completion_Blocker_Substitution_Fingerprint;
         when Dataflow_RM_Completion_Multiple_Blockers => return Dataflow_RM_Completion_Blocker_Multiple;
         when Dataflow_RM_Completion_Indeterminate => return Dataflow_RM_Completion_Blocker_Indeterminate;
      end case;
   end Blocker_Family_For;

   function Make_Row (Info : Dataflow_RM_Completion_Context) return Dataflow_RM_Completion_Row is
      Status  : Dataflow_RM_Completion_Status := Accepted_For (Info.Kind);
      Family  : Dataflow_RM_Completion_Blocker_Family := Dataflow_RM_Completion_Blocker_None;
      Blocker_Count : Natural := 0;

      procedure Note
        (New_Status : Dataflow_RM_Completion_Status;
         New_Family : Dataflow_RM_Completion_Blocker_Family) is
      begin
         if Family = Dataflow_RM_Completion_Blocker_None then
            Status := New_Status;
            Family := New_Family;
         end if;
         Blocker_Count := Blocker_Count + 1;
      end Note;

      Fingerprint : Natural := 1255;
   begin
      if Info.Kind = Dataflow_RM_Completion_Unknown then
         Note (Dataflow_RM_Completion_Indeterminate,
               Dataflow_RM_Completion_Blocker_Indeterminate);
      end if;

      if Info.Requires_Prior_Dataflow then
         if Info.Prior_Dataflow_Row = Prior_Dataflow.No_Dataflow_Generic_Final_Row then
            Note (Dataflow_RM_Completion_Missing_Prior_Dataflow_Row,
                  Dataflow_RM_Completion_Blocker_Prior_Dataflow);
         elsif not Prior_Dataflow.Is_Accepted (Info.Prior_Dataflow_Status) then
            Note (Dataflow_RM_Completion_Prior_Dataflow_Blocker,
                  Dataflow_RM_Completion_Blocker_Prior_Dataflow);
         end if;
      end if;

      if Info.Requires_Cross_RM then
         if Info.Cross_RM_Row = Cross_RM.No_Cross_Unit_RM_Completion_Closure then
            Note (Dataflow_RM_Completion_Missing_Cross_Unit_RM_Row,
                  Dataflow_RM_Completion_Blocker_Cross_Unit_RM_Completion);
         elsif not Cross_RM.Is_Accepted (Info.Cross_RM_Status) then
            Note (Dataflow_RM_Completion_Cross_Unit_RM_Blocker,
                  Dataflow_RM_Completion_Blocker_Cross_Unit_RM_Completion);
         end if;
      end if;

      if Info.Requires_Elaboration_RM then
         if Info.Elaboration_RM_Row = Elaboration_RM.No_Elaboration_RM_Completion_Row then
            Note (Dataflow_RM_Completion_Missing_Elaboration_RM_Row,
                  Dataflow_RM_Completion_Blocker_Elaboration_RM_Completion);
         elsif not Elaboration_RM.Is_Accepted (Info.Elaboration_RM_Status) then
            Note (Dataflow_RM_Completion_Elaboration_RM_Blocker,
                  Dataflow_RM_Completion_Blocker_Elaboration_RM_Completion);
         end if;
      end if;

      if Info.Requires_Accessibility_RM then
         if Info.Accessibility_RM_Row = Accessibility_RM.No_Accessibility_RM_Completion_Row then
            Note (Dataflow_RM_Completion_Missing_Accessibility_RM_Row,
                  Dataflow_RM_Completion_Blocker_Accessibility_RM_Completion);
         elsif not Accessibility_RM.Is_Accepted (Info.Accessibility_RM_Status) then
            Note (Dataflow_RM_Completion_Accessibility_RM_Blocker,
                  Dataflow_RM_Completion_Blocker_Accessibility_RM_Completion);
         end if;
      end if;

      if Info.Requires_Exception_RM then
         if Info.Exception_RM_Row = Exception_RM.No_Exception_RM_Completion_Row then
            Note (Dataflow_RM_Completion_Missing_Exception_RM_Row,
                  Dataflow_RM_Completion_Blocker_Exception_Finalization_RM_Completion);
         elsif not Exception_RM.Is_Accepted (Info.Exception_RM_Status) then
            Note (Dataflow_RM_Completion_Exception_RM_Blocker,
                  Dataflow_RM_Completion_Blocker_Exception_Finalization_RM_Completion);
         end if;
      end if;

      if Info.Requires_Predicate_RM then
         if Info.Predicate_RM_Row = Predicate_RM.No_Predicate_RM_Completion_Row then
            Note (Dataflow_RM_Completion_Missing_Predicate_RM_Row,
                  Dataflow_RM_Completion_Blocker_Predicate_RM_Completion);
         elsif not Predicate_RM.Is_Accepted (Info.Predicate_RM_Status) then
            Note (Dataflow_RM_Completion_Predicate_RM_Blocker,
                  Dataflow_RM_Completion_Blocker_Predicate_RM_Completion);
         end if;
      end if;

      if Info.Requires_Overload_RM then
         if Info.Overload_RM_Row = Overload_RM.No_Overload_Generic_RM_Edge_Completion then
            Note (Dataflow_RM_Completion_Missing_Overload_RM_Row,
                  Dataflow_RM_Completion_Blocker_Overload_RM_Completion);
         elsif not Overload_RM.Is_Accepted (Info.Overload_RM_Status) then
            Note (Dataflow_RM_Completion_Overload_RM_Blocker,
                  Dataflow_RM_Completion_Blocker_Overload_RM_Completion);
         end if;
      end if;

      if Info.Requires_Representation_RM then
         if Info.Representation_RM_Row = Representation_RM.No_Representation_Generic_RM_Hard_Case then
            Note (Dataflow_RM_Completion_Missing_Representation_RM_Row,
                  Dataflow_RM_Completion_Blocker_Representation_RM_Completion);
         elsif not Representation_RM.Is_Accepted (Info.Representation_RM_Status) then
            Note (Dataflow_RM_Completion_Representation_RM_Blocker,
                  Dataflow_RM_Completion_Blocker_Representation_RM_Completion);
         end if;
      end if;

      if Info.Requires_Tasking_RM then
         if Info.Tasking_RM_Row = Tasking_RM.No_Tasking_Generic_RM_Hard_Case then
            Note (Dataflow_RM_Completion_Missing_Tasking_RM_Row,
                  Dataflow_RM_Completion_Blocker_Tasking_RM_Completion);
         elsif not Tasking_RM.Is_Accepted (Info.Tasking_RM_Status) then
            Note (Dataflow_RM_Completion_Tasking_RM_Blocker,
                  Dataflow_RM_Completion_Blocker_Tasking_RM_Completion);
         end if;
      end if;

      if Info.Requires_AST_Repair then
         if Info.AST_Repair_Row = AST_Repair.No_Coverage_Proven_AST_Repair then
            Note (Dataflow_RM_Completion_Missing_AST_Repair_Row,
                  Dataflow_RM_Completion_Blocker_AST_Repair);
         elsif not AST_Repair_Accepted (Info.AST_Repair_Status) then
            Note (Dataflow_RM_Completion_AST_Repair_Blocker,
                  Dataflow_RM_Completion_Blocker_AST_Repair);
         end if;
      end if;

      if Info.Read_Before_Write_Blocker then
         Note (Dataflow_RM_Completion_Read_Before_Write_Blocker,
               Dataflow_RM_Completion_Blocker_Read_Before_Write);
      end if;
      if Info.Partial_Component_Init_Blocker then
         Note (Dataflow_RM_Completion_Partial_Component_Init_Blocker,
               Dataflow_RM_Completion_Blocker_Partial_Component_Init);
      end if;
      if Info.Out_Parameter_Blocker then
         Note (Dataflow_RM_Completion_Out_Parameter_Blocker,
               Dataflow_RM_Completion_Blocker_Out_Parameter);
      end if;
      if Info.Return_Object_Blocker then
         Note (Dataflow_RM_Completion_Return_Object_Blocker,
               Dataflow_RM_Completion_Blocker_Return_Object);
      end if;
      if Info.Branch_Loop_Merge_Blocker then
         Note (Dataflow_RM_Completion_Branch_Loop_Merge_Blocker,
               Dataflow_RM_Completion_Blocker_Branch_Loop_Merge);
      end if;
      if Info.Exception_Path_Blocker then
         Note (Dataflow_RM_Completion_Exception_Path_Blocker,
               Dataflow_RM_Completion_Blocker_Exception_Path);
      end if;
      if Info.Finalization_Blocker then
         Note (Dataflow_RM_Completion_Finalization_Blocker,
               Dataflow_RM_Completion_Blocker_Finalization);
      end if;
      if Info.Access_Escape_Blocker then
         Note (Dataflow_RM_Completion_Access_Escape_Blocker,
               Dataflow_RM_Completion_Blocker_Access_Escape);
      end if;
      if Info.Variant_Component_Blocker then
         Note (Dataflow_RM_Completion_Variant_Component_Blocker,
               Dataflow_RM_Completion_Blocker_Variant_Component);
      end if;
      if Info.Volatile_Atomic_Effect_Blocker then
         Note (Dataflow_RM_Completion_Volatile_Atomic_Effect_Blocker,
               Dataflow_RM_Completion_Blocker_Volatile_Atomic_Effect);
      end if;
      if Info.Generic_Substitution_Blocker then
         Note (Dataflow_RM_Completion_Generic_Substitution_Blocker,
               Dataflow_RM_Completion_Blocker_Generic_Substitution);
      end if;
      if Info.Dispatching_Effect_Blocker then
         Note (Dataflow_RM_Completion_Dispatching_Effect_Blocker,
               Dataflow_RM_Completion_Blocker_Dispatching_Effect);
      end if;
      if Info.View_Barrier then
         Note (Dataflow_RM_Completion_View_Barrier,
               Dataflow_RM_Completion_Blocker_View_Barrier);
      end if;

      if Info.Source_Fingerprint /= Info.Expected_Source_Fingerprint then
         Note (Dataflow_RM_Completion_Source_Fingerprint_Mismatch,
               Dataflow_RM_Completion_Blocker_Source_Fingerprint);
      end if;
      if Info.Substitution_Fingerprint /= Info.Expected_Substitution_Fingerprint then
         Note (Dataflow_RM_Completion_Substitution_Fingerprint_Mismatch,
               Dataflow_RM_Completion_Blocker_Substitution_Fingerprint);
      end if;
      if Info.Explicit_Indeterminate then
         Note (Dataflow_RM_Completion_Indeterminate,
               Dataflow_RM_Completion_Blocker_Indeterminate);
      end if;
      if Info.Explicit_Multiple_Blockers or else Blocker_Count > 1 then
         Status := Dataflow_RM_Completion_Multiple_Blockers;
         Family := Dataflow_RM_Completion_Blocker_Multiple;
      end if;

      Fingerprint := Fingerprint * 31 + Natural (Info.Id);
      Fingerprint := Fingerprint * 31 + Dataflow_RM_Completion_Kind'Pos (Info.Kind);
      Fingerprint := Fingerprint * 31 + Dataflow_RM_Completion_Status'Pos (Status);
      Fingerprint := Fingerprint * 31 + Dataflow_RM_Completion_Blocker_Family'Pos (Family);
      Fingerprint := Fingerprint * 31 + Natural (Info.Node);
      Fingerprint := Fingerprint * 31 + Info.Source_Fingerprint;
      Fingerprint := Fingerprint * 31 + Info.Substitution_Fingerprint;

      return
        (Id => Info.Id,
         Kind => Info.Kind,
         Status => Status,
         Blocker_Family => Family,
         Node => Info.Node,
         Source_Fingerprint => Info.Source_Fingerprint,
         Substitution_Fingerprint => Info.Substitution_Fingerprint,
         Stable_Row_Fingerprint => Fingerprint);
   end Make_Row;

   procedure Add_Context
     (Model : in out Dataflow_RM_Completion_Context_Model;
      Item  : Dataflow_RM_Completion_Context) is
   begin
      Model.Append (Item);
   end Add_Context;

   function Build
     (Contexts : Dataflow_RM_Completion_Context_Model)
      return Dataflow_RM_Completion_Model is
      Result : Dataflow_RM_Completion_Model;
      Fingerprint : Natural := 1255;
   begin
      for C of Contexts loop
         declare
            Row : constant Dataflow_RM_Completion_Row := Make_Row (C);
         begin
            Result.Rows.Append (Row);
            Fingerprint := Fingerprint * 33 + Row.Stable_Row_Fingerprint;
         end;
      end loop;
      Result.Stable_Fingerprint_Value := Fingerprint;
      return Result;
   end Build;

   function Count (Model : Dataflow_RM_Completion_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Accepted_Count (Model : Dataflow_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for R of Model.Rows loop
         if Is_Accepted (R.Status) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Accepted_Count;

   function Blocked_Count (Model : Dataflow_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for R of Model.Rows loop
         if Is_Blocked (R.Status) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Blocked_Count;

   function Indeterminate_Count (Model : Dataflow_RM_Completion_Model) return Natural is
   begin
      return Count_By_Status (Model, Dataflow_RM_Completion_Indeterminate);
   end Indeterminate_Count;

   function Count_By_Status
     (Model  : Dataflow_RM_Completion_Model;
      Status : Dataflow_RM_Completion_Status) return Natural is
      Result : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Dataflow_RM_Completion_Model;
      Family : Dataflow_RM_Completion_Blocker_Family) return Natural is
      Result : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Blocker_Family = Family then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_By_Blocker_Family;

   function Row_At
     (Model : Dataflow_RM_Completion_Model;
      Index : Positive) return Dataflow_RM_Completion_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Result : Query_Result) return Natural is
   begin
      return Natural (Result.Rows.Length);
   end Query_Count;

   function Query_Row
     (Result : Query_Result;
      Index  : Positive) return Dataflow_RM_Completion_Row is
   begin
      return Result.Rows.Element (Index);
   end Query_Row;

   function Find_By_Node
     (Model : Dataflow_RM_Completion_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Query_Result is
      Result : Query_Result;
   begin
      for R of Model.Rows loop
         if R.Node = Node then
            Result.Rows.Append (R);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : Dataflow_RM_Completion_Model;
      Fingerprint : Natural) return Query_Result is
      Result : Query_Result;
   begin
      for R of Model.Rows loop
         if R.Source_Fingerprint = Fingerprint then
            Result.Rows.Append (R);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Query_Blocker_Family
     (Model  : Dataflow_RM_Completion_Model;
      Family : Dataflow_RM_Completion_Blocker_Family) return Query_Result is
      Result : Query_Result;
   begin
      for R of Model.Rows loop
         if R.Blocker_Family = Family then
            Result.Rows.Append (R);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Stable_Fingerprint (Model : Dataflow_RM_Completion_Model) return Natural is
   begin
      return Model.Stable_Fingerprint_Value;
   end Stable_Fingerprint;

end Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
