with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Integrated_Semantic_Closure is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Seed, Value : Natural) return Natural is
   begin
      return (Seed * 131 + Value + 17) mod 2_147_483_647;
   end Mix;

   function Text_Hash (Text : Unbounded_String) return Natural is
      S : constant String := To_String (Text);
      H : Natural := 0;
   begin
      for Ch of S loop
         H := Mix (H, Character'Pos (Ch));
      end loop;
      return H;
   end Text_Hash;

   function Blocker_Count_For (C : Integrated_Closure_Context_Info) return Natural is
      Total : Natural := 0;
   begin
      if C.Wide_Legality_Error then Total := Total + 1; end if;
      if C.Overload_Error then Total := Total + 1; end if;
      if C.Staticness_Error then Total := Total + 1; end if;
      if C.Accessibility_Error then Total := Total + 1; end if;
      if C.Contract_Error then Total := Total + 1; end if;
      if C.Elaboration_Error then Total := Total + 1; end if;
      if C.Completion_Error then Total := Total + 1; end if;
      if C.Renaming_Error then Total := Total + 1; end if;
      if C.Exception_Error then Total := Total + 1; end if;
      if C.Representation_Error then Total := Total + 1; end if;
      if C.Initialization_Error then Total := Total + 1; end if;
      if C.Dataflow_Error then Total := Total + 1; end if;
      if C.Refined_Global_Depends_Error then Total := Total + 1; end if;
      if C.AST_Coverage_Error then Total := Total + 1; end if;
      if C.Coverage_Gate_Error then Total := Total + 1; end if;
      return Total;
   end Blocker_Count_For;

   function First_Blocker (C : Integrated_Closure_Context_Info) return Closure_Blocker_Family is
      Count : constant Natural := Blocker_Count_For (C);
   begin
      if Count > 1 then
         return Closure_Blocker_Multiple;
      elsif Count = 0 then
         return C.Primary_Blocker;
      elsif C.Wide_Legality_Error then
         return Closure_Blocker_Wide_Legality;
      elsif C.Overload_Error then
         return Closure_Blocker_Overload;
      elsif C.Staticness_Error then
         return Closure_Blocker_Staticness;
      elsif C.Accessibility_Error then
         return Closure_Blocker_Accessibility;
      elsif C.Contract_Error then
         return Closure_Blocker_Contract;
      elsif C.Elaboration_Error then
         return Closure_Blocker_Elaboration;
      elsif C.Completion_Error then
         return Closure_Blocker_Completion;
      elsif C.Renaming_Error then
         return Closure_Blocker_Renaming;
      elsif C.Exception_Error then
         return Closure_Blocker_Exception_Finalization;
      elsif C.Representation_Error then
         return Closure_Blocker_Representation;
      elsif C.Initialization_Error then
         return Closure_Blocker_Definite_Initialization;
      elsif C.Dataflow_Error then
         return Closure_Blocker_Dataflow;
      elsif C.Refined_Global_Depends_Error then
         return Closure_Blocker_Refined_Global_Depends;
      elsif C.AST_Coverage_Error then
         return Closure_Blocker_AST_Coverage;
      elsif C.Coverage_Gate_Error then
         return Closure_Blocker_Coverage_Gate;
      else
         return Closure_Blocker_None;
      end if;
   end First_Blocker;

   function Classify (C : Integrated_Closure_Context_Info) return Integrated_Closure_Status is
      Count : constant Natural := Blocker_Count_For (C);
      Blocker : constant Closure_Blocker_Family := First_Blocker (C);
   begin
      if C.Dependency = Dependency_Rejected then
         return Integrated_Closure_Rejected_Stale_Input;
      elsif C.Dependency = Dependency_Stale then
         return Integrated_Closure_Stale_Dependency;
      elsif C.Dependency = Dependency_Limited_View then
         return Integrated_Closure_Limited_View_Barrier;
      elsif C.Dependency = Dependency_Private_View then
         return Integrated_Closure_Private_View_Barrier;
      elsif C.Dependency = Dependency_Missing then
         return Integrated_Closure_Missing_Dependency;
      elsif C.Dependency = Dependency_Ambiguous then
         return Integrated_Closure_Ambiguous_Dependency;
      elsif C.Dependency = Dependency_Overflow then
         return Integrated_Closure_Dependency_Overflow;
      elsif C.Indeterminate or else Blocker = Closure_Blocker_Indeterminate then
         return Integrated_Closure_Indeterminate;
      elsif Count > 1 or else Blocker = Closure_Blocker_Multiple then
         return Integrated_Closure_Multiple_Blockers;
      elsif Blocker = Closure_Blocker_Wide_Legality then
         return Integrated_Closure_Wide_Legality_Blocker;
      elsif Blocker = Closure_Blocker_Overload then
         return Integrated_Closure_Overload_Blocker;
      elsif Blocker = Closure_Blocker_Staticness then
         return Integrated_Closure_Staticness_Blocker;
      elsif Blocker = Closure_Blocker_Accessibility then
         return Integrated_Closure_Accessibility_Blocker;
      elsif Blocker = Closure_Blocker_Contract then
         return Integrated_Closure_Contract_Blocker;
      elsif Blocker = Closure_Blocker_Elaboration then
         return Integrated_Closure_Elaboration_Blocker;
      elsif Blocker = Closure_Blocker_Completion then
         return Integrated_Closure_Completion_Blocker;
      elsif Blocker = Closure_Blocker_Renaming then
         return Integrated_Closure_Renaming_Blocker;
      elsif Blocker = Closure_Blocker_Exception_Finalization then
         return Integrated_Closure_Exception_Finalization_Blocker;
      elsif Blocker = Closure_Blocker_Representation then
         return Integrated_Closure_Representation_Blocker;
      elsif Blocker = Closure_Blocker_Definite_Initialization then
         return Integrated_Closure_Definite_Initialization_Blocker;
      elsif Blocker = Closure_Blocker_Dataflow then
         return Integrated_Closure_Dataflow_Blocker;
      elsif Blocker = Closure_Blocker_Refined_Global_Depends then
         return Integrated_Closure_Refined_Global_Depends_Blocker;
      elsif Blocker = Closure_Blocker_AST_Coverage then
         return Integrated_Closure_AST_Coverage_Blocker;
      elsif Blocker = Closure_Blocker_Coverage_Gate then
         return Integrated_Closure_Coverage_Gate_Blocker;
      elsif C.Dependency = Dependency_Local_Only or else C.Dependency = Dependency_None then
         return Integrated_Closure_Legal_Local;
      elsif C.Dependency in Dependency_Closed | Dependency_With_Visible | Dependency_Use_Visible then
         return Integrated_Closure_Legal_Cross_Unit;
      elsif C.Dependency = Dependency_Unknown then
         return Integrated_Closure_Not_Checked;
      else
         return Integrated_Closure_Legal_With_Use_Closure;
      end if;
   end Classify;

   function Is_Legal (Status : Integrated_Closure_Status) return Boolean is
   begin
      return Status in Integrated_Closure_Legal_Local |
                       Integrated_Closure_Legal_Cross_Unit |
                       Integrated_Closure_Legal_With_Use_Closure;
   end Is_Legal;

   function Is_Blocker (Status : Integrated_Closure_Status) return Boolean is
   begin
      return Status in Integrated_Closure_Wide_Legality_Blocker |
                       Integrated_Closure_Overload_Blocker |
                       Integrated_Closure_Staticness_Blocker |
                       Integrated_Closure_Accessibility_Blocker |
                       Integrated_Closure_Contract_Blocker |
                       Integrated_Closure_Elaboration_Blocker |
                       Integrated_Closure_Completion_Blocker |
                       Integrated_Closure_Renaming_Blocker |
                       Integrated_Closure_Exception_Finalization_Blocker |
                       Integrated_Closure_Representation_Blocker |
                       Integrated_Closure_Definite_Initialization_Blocker |
                       Integrated_Closure_Dataflow_Blocker |
                       Integrated_Closure_Refined_Global_Depends_Blocker |
                       Integrated_Closure_AST_Coverage_Blocker |
                       Integrated_Closure_Coverage_Gate_Blocker |
                       Integrated_Closure_Multiple_Blockers;
   end Is_Blocker;

   function Context_Fingerprint (C : Integrated_Closure_Context_Info) return Natural is
      H : Natural := 0;
   begin
      H := Mix (H, Natural (C.Id));
      H := Mix (H, Integrated_Closure_Context_Kind'Pos (C.Kind));
      H := Mix (H, Text_Hash (C.Normalized_Unit_Name));
      H := Mix (H, Text_Hash (C.Normalized_Dependency));
      H := Mix (H, Natural (C.Node));
      H := Mix (H, Natural (C.Dependency_Node));
      H := Mix (H, Closure_Dependency_State'Pos (C.Dependency));
      H := Mix (H, Closure_Blocker_Family'Pos (C.Primary_Blocker));
      H := Mix (H, C.Source_Fingerprint);
      H := Mix
        (H,
         Refined_Global_Depends_Status'Pos
           (C.Refined_Global_Depends));
      if C.Wide_Legality_Error then H := Mix (H, 3); end if;
      if C.Overload_Error then H := Mix (H, 5); end if;
      if C.Staticness_Error then H := Mix (H, 7); end if;
      if C.Accessibility_Error then H := Mix (H, 11); end if;
      if C.Contract_Error then H := Mix (H, 13); end if;
      if C.Elaboration_Error then H := Mix (H, 17); end if;
      if C.Completion_Error then H := Mix (H, 19); end if;
      if C.Renaming_Error then H := Mix (H, 23); end if;
      if C.Exception_Error then H := Mix (H, 29); end if;
      if C.Representation_Error then H := Mix (H, 31); end if;
      if C.Initialization_Error then H := Mix (H, 41); end if;
      if C.Dataflow_Error then H := Mix (H, 43); end if;
      if C.Refined_Global_Depends_Error then H := Mix (H, 59); end if;
      if C.AST_Coverage_Error then H := Mix (H, 47); end if;
      if C.Coverage_Gate_Error then H := Mix (H, 53); end if;
      if C.Indeterminate then H := Mix (H, 37); end if;
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (R : Integrated_Closure_Info) return Natural is
      H : Natural := 0;
   begin
      H := Mix (H, Natural (R.Id));
      H := Mix (H, Natural (R.Context));
      H := Mix (H, Integrated_Closure_Context_Kind'Pos (R.Kind));
      H := Mix (H, Integrated_Closure_Status'Pos (R.Status));
      H := Mix (H, Closure_Blocker_Family'Pos (R.Blocker));
      H := Mix (H, Closure_Dependency_State'Pos (R.Dependency));
      H := Mix (H, Text_Hash (R.Normalized_Unit_Name));
      H := Mix (H, Text_Hash (R.Normalized_Dependency));
      H := Mix (H, Natural (R.Node));
      H := Mix (H, Natural (R.Dependency_Node));
      H := Mix (H, R.Source_Fingerprint);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Integrated_Closure_Status) return Unbounded_String is
   begin
      case Status is
         when Integrated_Closure_Legal_Local =>
            return To_Unbounded_String ("local semantic closure is legal");
         when Integrated_Closure_Legal_Cross_Unit =>
            return To_Unbounded_String ("cross-unit semantic closure is legal");
         when Integrated_Closure_Legal_With_Use_Closure =>
            return To_Unbounded_String ("with/use semantic closure is legal");
         when Integrated_Closure_Limited_View_Barrier =>
            return To_Unbounded_String ("limited view blocks semantic closure");
         when Integrated_Closure_Private_View_Barrier =>
            return To_Unbounded_String ("private view blocks semantic closure");
         when Integrated_Closure_Missing_Dependency =>
            return To_Unbounded_String ("semantic dependency is missing");
         when Integrated_Closure_Ambiguous_Dependency =>
            return To_Unbounded_String ("semantic dependency is ambiguous");
         when Integrated_Closure_Dependency_Overflow =>
            return To_Unbounded_String ("semantic dependency lookup overflowed");
         when Integrated_Closure_Stale_Dependency =>
            return To_Unbounded_String ("semantic dependency is stale");
         when Integrated_Closure_Rejected_Stale_Input =>
            return To_Unbounded_String ("stale semantic closure input rejected");
         when Integrated_Closure_Multiple_Blockers =>
            return To_Unbounded_String ("multiple semantic legality blockers remain");
         when Integrated_Closure_Indeterminate =>
            return To_Unbounded_String ("semantic closure is indeterminate");
         when Integrated_Closure_Not_Checked =>
            return To_Unbounded_String ("semantic closure not checked");
         when others =>
            return To_Unbounded_String ("semantic legality blocker prevents closure");
      end case;
   end Message_For;

   procedure Clear (Model : in out Integrated_Closure_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Integrated_Closure_Context_Model;
      Info  : Integrated_Closure_Context_Info)
   is
   begin
      Model.Contexts.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Context_Fingerprint (Info));
   end Add_Context;

   function Context_Count (Model : Integrated_Closure_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Integrated_Closure_Context_Model;
      Index : Positive) return Integrated_Closure_Context_Info
   is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Integrated_Closure_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Integrated_Closure_Context_Model) return Integrated_Closure_Model is
      Model : Integrated_Closure_Model;
      Next  : Integrated_Closure_Id := 1;
   begin
      for C of Contexts.Contexts loop
         declare
            R : Integrated_Closure_Info;
         begin
            R.Id := Next;
            R.Context := C.Id;
            R.Kind := C.Kind;
            R.Status := Classify (C);
            R.Blocker := First_Blocker (C);
            R.Unit_Name := C.Unit_Name;
            R.Normalized_Unit_Name := C.Normalized_Unit_Name;
            R.Dependency_Name := C.Dependency_Name;
            R.Normalized_Dependency := C.Normalized_Dependency;
            R.Node := C.Node;
            R.Dependency_Node := C.Dependency_Node;
            R.Dependency := C.Dependency;
            R.Message := Message_For (R.Status);
            R.Detail := To_Unbounded_String (Closure_Blocker_Family'Image (R.Blocker));
            R.Start_Line := C.Start_Line;
            R.Start_Column := C.Start_Column;
            R.End_Line := C.End_Line;
            R.End_Column := C.End_Column;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.Fingerprint := Row_Fingerprint (R);
            Model.Rows.Append (R);
            Model.Fingerprint := Mix (Model.Fingerprint, R.Fingerprint);
            Next := Next + 1;
         end;
      end loop;
      Model.Fingerprint := Mix (Model.Fingerprint, Fingerprint (Contexts));
      return Model;
   end Build;

   function Closure_Count (Model : Integrated_Closure_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Closure_Count;

   function Closure_At
     (Model : Integrated_Closure_Model;
      Index : Positive) return Integrated_Closure_Info
   is
   begin
      return Model.Rows.Element (Index);
   end Closure_At;

   function First_For_Node
     (Model : Integrated_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Integrated_Closure_Info
   is
   begin
      for R of Model.Rows loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function First_For_Unit
     (Model : Integrated_Closure_Model;
      Unit  : Unbounded_String) return Integrated_Closure_Info
   is
      Key : constant String := To_String (Unit);
   begin
      for R of Model.Rows loop
         if To_String (R.Normalized_Unit_Name) = Key or else To_String (R.Unit_Name) = Key then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Unit;

   function Rows_For_Status
     (Model  : Integrated_Closure_Model;
      Status : Integrated_Closure_Status) return Integrated_Closure_Result_Set
   is
      Set : Integrated_Closure_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Status = Status then
            Set.Results.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Integrated_Closure_Model;
      Kind  : Integrated_Closure_Context_Kind) return Integrated_Closure_Result_Set
   is
      Set : Integrated_Closure_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Kind = Kind then
            Set.Results.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Rows_For_Dependency
     (Model : Integrated_Closure_Model;
      State : Closure_Dependency_State) return Integrated_Closure_Result_Set
   is
      Set : Integrated_Closure_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Dependency = State then
            Set.Results.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Dependency;

   function Rows_For_Blocker
     (Model   : Integrated_Closure_Model;
      Blocker : Closure_Blocker_Family) return Integrated_Closure_Result_Set
   is
      Set : Integrated_Closure_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Blocker = Blocker then
            Set.Results.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Blocker;

   function Result_Count (Set : Integrated_Closure_Result_Set) return Natural is
   begin
      return Natural (Set.Results.Length);
   end Result_Count;

   function Result_At
     (Set   : Integrated_Closure_Result_Set;
      Index : Positive) return Integrated_Closure_Info
   is
   begin
      return Set.Results.Element (Index);
   end Result_At;

   function Legal_Count (Model : Integrated_Closure_Model) return Natural is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if Is_Legal (R.Status) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Legal_Count;

   function Blocker_Count (Model : Integrated_Closure_Model) return Natural is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if Is_Blocker (R.Status) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Blocker_Count;

   function Dependency_Error_Count (Model : Integrated_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Integrated_Closure_Missing_Dependency) +
        Count_Status (Model, Integrated_Closure_Ambiguous_Dependency) +
        Count_Status (Model, Integrated_Closure_Dependency_Overflow);
   end Dependency_Error_Count;

   function View_Barrier_Count (Model : Integrated_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Integrated_Closure_Limited_View_Barrier) +
        Count_Status (Model, Integrated_Closure_Private_View_Barrier);
   end View_Barrier_Count;

   function Stale_Rejected_Count (Model : Integrated_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Integrated_Closure_Stale_Dependency) +
        Count_Status (Model, Integrated_Closure_Rejected_Stale_Input);
   end Stale_Rejected_Count;

   function Indeterminate_Count (Model : Integrated_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Integrated_Closure_Indeterminate);
   end Indeterminate_Count;

   function Count_Status
     (Model  : Integrated_Closure_Model;
      Status : Integrated_Closure_Status) return Natural
   is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Status = Status then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Status;

   function Count_Kind
     (Model : Integrated_Closure_Model;
      Kind  : Integrated_Closure_Context_Kind) return Natural
   is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Kind = Kind then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Kind;

   function Count_Dependency
     (Model : Integrated_Closure_Model;
      State : Closure_Dependency_State) return Natural
   is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Dependency = State then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Dependency;

   function Count_Blocker
     (Model   : Integrated_Closure_Model;
      Blocker : Closure_Blocker_Family) return Natural
   is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Blocker = Blocker then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Blocker;

   function Fingerprint (Model : Integrated_Closure_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Integrated_Semantic_Closure;
