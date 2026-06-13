with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Protected_Final_Effects_Legality is

   use type Access_Final.Master_Scope_Final_Row_Id;
   use type Disc_Consumer.Discriminant_Consumer_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elab_Final.Final_Elaboration_Row_Id;
   use type Rep_CPD.Representation_Tasking_CPD_Row_Id;
   use type Tasking_CPD.Tasking_Contract_Predicate_Row_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Has (S, Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (S, Pattern) /= 0;
   end Has;

   function Legal_Status_For_Kind (Kind : Final_Tasking_Context_Kind) return Final_Tasking_Status is
   begin
      case Kind is
         when Final_Tasking_Task_Activation => return Final_Tasking_Legal_Task_Activation_Accepted;
         when Final_Tasking_Task_Termination => return Final_Tasking_Legal_Task_Termination_Accepted;
         when Final_Tasking_Protected_Read => return Final_Tasking_Legal_Protected_Read_Accepted;
         when Final_Tasking_Protected_Write => return Final_Tasking_Legal_Protected_Write_Accepted;
         when Final_Tasking_Protected_Function_Call => return Final_Tasking_Legal_Protected_Function_Call_Accepted;
         when Final_Tasking_Protected_Procedure_Call => return Final_Tasking_Legal_Protected_Procedure_Call_Accepted;
         when Final_Tasking_Protected_Entry_Call => return Final_Tasking_Legal_Protected_Entry_Call_Accepted;
         when Final_Tasking_Protected_Action_Reentrancy => return Final_Tasking_Legal_Protected_Reentrancy_Accepted;
         when Final_Tasking_Protected_State_Mutation => return Final_Tasking_Legal_Protected_State_Mutation_Accepted;
         when Final_Tasking_Entry_Queue => return Final_Tasking_Legal_Entry_Queue_Accepted;
         when Final_Tasking_Entry_Barrier => return Final_Tasking_Legal_Entry_Barrier_Accepted;
         when Final_Tasking_Barrier_Side_Effect => return Final_Tasking_Legal_Barrier_Side_Effect_Accepted;
         when Final_Tasking_Accept_Body => return Final_Tasking_Legal_Accept_Body_Accepted;
         when Final_Tasking_Requeue => return Final_Tasking_Legal_Requeue_Accepted;
         when Final_Tasking_Requeue_With_Abort => return Final_Tasking_Legal_Requeue_With_Abort_Accepted;
         when Final_Tasking_Select_Guard => return Final_Tasking_Legal_Select_Guard_Accepted;
         when Final_Tasking_Select_Alternative => return Final_Tasking_Legal_Select_Alternative_Accepted;
         when Final_Tasking_Abortable_Part => return Final_Tasking_Legal_Abortable_Part_Accepted;
         when Final_Tasking_Delay_Alternative => return Final_Tasking_Legal_Delay_Alternative_Accepted;
         when Final_Tasking_Terminate_Alternative => return Final_Tasking_Legal_Terminate_Alternative_Accepted;
         when Final_Tasking_Unknown => return Final_Tasking_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Base_Effect
     (Status : Task_Effects.Tasking_Effect_Status) return Final_Tasking_Status is
      Img : constant String := Task_Effects.Tasking_Effect_Status'Image (Status);
   begin
      if Task_Effects.Is_Legal (Status) then
         return Final_Tasking_Not_Checked;
      elsif Has (Img, "INDETERMINATE") or else Has (Img, "NOT_CHECKED") then
         return Final_Tasking_Indeterminate;
      elsif Has (Img, "REENTR") then
         return Final_Tasking_Protected_Reentrancy_Blocker;
      elsif Has (Img, "PROTECTED_FUNCTION_WRITES") then
         return Final_Tasking_Protected_State_Mutation_Blocker;
      elsif Has (Img, "CALLS_ENTRY") then
         return Final_Tasking_Protected_Function_Entry_Call_Blocker;
      elsif Has (Img, "BARRIER") and then Has (Img, "BOOLEAN") then
         return Final_Tasking_Barrier_Not_Boolean_Blocker;
      elsif Has (Img, "BARRIER") or else Has (Img, "GUARD") then
         return Final_Tasking_Barrier_Side_Effect_Blocker;
      elsif Has (Img, "ENTRY_QUEUE") then
         return Final_Tasking_Entry_Queue_Blocker;
      elsif Has (Img, "ACCEPT_BODY") then
         return Final_Tasking_Accept_Body_Effect_Blocker;
      elsif Has (Img, "REQUEUE_WITH_ABORT") or else Has (Img, "ABORT_UNSAFE") then
         return Final_Tasking_Requeue_With_Abort_Unsafe;
      elsif Has (Img, "REQUEUE") then
         return Final_Tasking_Requeue_Target_Blocker;
      elsif Has (Img, "SELECT") then
         return Final_Tasking_Select_Alternative_Blocker;
      elsif Has (Img, "ABORTABLE") or else Has (Img, "FINALIZATION") then
         return Final_Tasking_Abort_Finalization_Blocker;
      elsif Has (Img, "DELAY") then
         return Final_Tasking_Delay_Alternative_Blocker;
      elsif Has (Img, "TERMINATE") then
         return Final_Tasking_Terminate_Alternative_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Final_Tasking_Coverage_Blocker;
      elsif Has (Img, "ACCESS") then
         return Final_Tasking_Lifetime_Accessibility_Blocker;
      elsif Has (Img, "FLOW") or else Has (Img, "GLOBAL") or else Has (Img, "DEPENDS") then
         return Final_Tasking_Global_Depends_Blocker;
      else
         return Final_Tasking_Base_Effect_Error;
      end if;
   end Status_From_Base_Effect;

   function Status_From_Tasking_CPD
     (Status : Tasking_CPD.Tasking_Contract_Predicate_Status) return Final_Tasking_Status is
      Img : constant String := Tasking_CPD.Tasking_Contract_Predicate_Status'Image (Status);
   begin
      if Tasking_CPD.Is_Legal (Status) then
         return Final_Tasking_Not_Checked;
      elsif Has (Img, "INDETERMINATE") or else Has (Img, "NOT_CHECKED") then
         return Final_Tasking_Indeterminate;
      elsif Has (Img, "PREDICATE") or else Has (Img, "INVARIANT") or else Has (Img, "CONTRACT") then
         return Final_Tasking_Predicate_Invariant_Blocker;
      elsif Has (Img, "READ_BEFORE_WRITE") or else Has (Img, "INITIAL") or else Has (Img, "ASSIGN") or else Has (Img, "MERGE") then
         return Final_Tasking_Initialization_Blocker;
      elsif Has (Img, "LIFETIME") or else Has (Img, "ACCESS") then
         return Final_Tasking_Lifetime_Accessibility_Blocker;
      elsif Has (Img, "DISCRIMINANT") or else Has (Img, "VARIANT") then
         return Final_Tasking_Discriminant_Blocker;
      elsif Has (Img, "REPRESENTATION") or else Has (Img, "FREEZING") then
         return Final_Tasking_Representation_Blocker;
      elsif Has (Img, "GLOBAL") or else Has (Img, "DEPENDS") or else Has (Img, "FLOW") then
         return Final_Tasking_Global_Depends_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Final_Tasking_Coverage_Blocker;
      else
         return Final_Tasking_Tasking_CPD_Blocker;
      end if;
   end Status_From_Tasking_CPD;

   function Status_From_Elaboration
     (Status : Elab_Final.Final_Elaboration_Status) return Final_Tasking_Status is
      Img : constant String := Elab_Final.Final_Elaboration_Status'Image (Status);
   begin
      if Elab_Final.Is_Legal (Status) then
         return Final_Tasking_Not_Checked;
      elsif Elab_Final.Is_Indeterminate (Status) then
         return Final_Tasking_Indeterminate;
      elsif Has (Img, "REPRESENTATION") then
         return Final_Tasking_Representation_Blocker;
      elsif Has (Img, "ACCESS") or else Has (Img, "LIFETIME") then
         return Final_Tasking_Lifetime_Accessibility_Blocker;
      elsif Has (Img, "DISCRIMINANT") then
         return Final_Tasking_Discriminant_Blocker;
      elsif Has (Img, "GLOBAL") or else Has (Img, "DEPENDS") then
         return Final_Tasking_Global_Depends_Blocker;
      elsif Has (Img, "PREDICATE") or else Has (Img, "CONTRACT") then
         return Final_Tasking_Predicate_Invariant_Blocker;
      elsif Has (Img, "INITIAL") or else Has (Img, "READ_BEFORE_WRITE") then
         return Final_Tasking_Initialization_Blocker;
      elsif Has (Img, "COVERAGE") then
         return Final_Tasking_Coverage_Blocker;
      else
         return Final_Tasking_Elaboration_Blocker;
      end if;
   end Status_From_Elaboration;

   function Status_From_Representation
     (Status : Rep_CPD.Representation_Tasking_CPD_Status) return Final_Tasking_Status is
      Img : constant String := Rep_CPD.Representation_Tasking_CPD_Status'Image (Status);
   begin
      if Rep_CPD.Is_Legal (Status) then
         return Final_Tasking_Not_Checked;
      elsif Has (Img, "INDETERMINATE") or else Has (Img, "NOT_CHECKED") then
         return Final_Tasking_Indeterminate;
      elsif Has (Img, "COVERAGE") then
         return Final_Tasking_Coverage_Blocker;
      else
         return Final_Tasking_Representation_Blocker;
      end if;
   end Status_From_Representation;

   function Status_From_Accessibility
     (Status : Access_Final.Master_Scope_Final_Status) return Final_Tasking_Status is
   begin
      if Access_Final.Is_Legal (Status) then
         return Final_Tasking_Not_Checked;
      elsif Access_Final.Is_Indeterminate (Status) then
         return Final_Tasking_Indeterminate;
      else
         return Final_Tasking_Accessibility_Blocker;
      end if;
   end Status_From_Accessibility;

   function Status_From_Discriminant
     (Status : Disc_Consumer.Discriminant_Consumer_Status) return Final_Tasking_Status is
   begin
      if Disc_Consumer.Is_Legal (Status) then
         return Final_Tasking_Not_Checked;
      elsif Disc_Consumer.Is_Indeterminate (Status) then
         return Final_Tasking_Indeterminate;
      else
         return Final_Tasking_Discriminant_Blocker;
      end if;
   end Status_From_Discriminant;

   function Status_For (Info : Final_Tasking_Context_Info) return Final_Tasking_Status is
      Candidate : Final_Tasking_Status;
   begin
      if Info.Protected_Action_Reentrant then
         return Final_Tasking_Protected_Reentrancy_Blocker;
      elsif Info.Protected_Function_Writes_State then
         return Final_Tasking_Protected_State_Mutation_Blocker;
      elsif Info.Protected_Function_Calls_Entry then
         return Final_Tasking_Protected_Function_Entry_Call_Blocker;
      elsif Info.Barrier_Has_Side_Effect then
         return Final_Tasking_Barrier_Side_Effect_Blocker;
      elsif Info.Requeue_With_Abort and then not Info.Requeue_Abort_Safe then
         return Final_Tasking_Requeue_With_Abort_Unsafe;
      elsif not Info.Abortable_Finalization_Safe then
         return Final_Tasking_Abort_Finalization_Blocker;
      elsif not Info.Terminate_Allowed then
         return Final_Tasking_Terminate_Alternative_Blocker;
      end if;

      Candidate := Status_From_Base_Effect (Info.Tasking_Effect_Status);
      if Candidate /= Final_Tasking_Not_Checked then
         return Candidate;
      end if;

      if Info.Tasking_CPD_Matches > 1 then
         return Final_Tasking_Multiple_Matching_Blockers;
      elsif Info.Tasking_CPD_Row = Tasking_CPD.No_Tasking_Contract_Predicate_Row then
         return Final_Tasking_Missing_Tasking_CPD_Row;
      end if;
      Candidate := Status_From_Tasking_CPD (Info.Tasking_CPD_Status);
      if Candidate /= Final_Tasking_Not_Checked then
         return Candidate;
      end if;

      if Info.Elaboration_Matches > 1 then
         return Final_Tasking_Multiple_Matching_Blockers;
      elsif Info.Elaboration_Row = Elab_Final.No_Final_Elaboration_Row then
         return Final_Tasking_Missing_Elaboration_Row;
      end if;
      Candidate := Status_From_Elaboration (Info.Elaboration_Status);
      if Candidate /= Final_Tasking_Not_Checked then
         return Candidate;
      end if;

      if Info.Requires_Representation then
         if Info.Representation_Matches > 1 then
            return Final_Tasking_Multiple_Matching_Blockers;
         elsif Info.Representation_Row = Rep_CPD.No_Representation_Tasking_CPD_Row then
            return Final_Tasking_Missing_Representation_Row;
         end if;
         Candidate := Status_From_Representation (Info.Representation_Status);
         if Candidate /= Final_Tasking_Not_Checked then
            return Candidate;
         end if;
      end if;

      if Info.Requires_Accessibility then
         if Info.Accessibility_Matches > 1 then
            return Final_Tasking_Multiple_Matching_Blockers;
         elsif Info.Accessibility_Row = Access_Final.No_Master_Scope_Final_Row then
            return Final_Tasking_Missing_Accessibility_Row;
         end if;
         Candidate := Status_From_Accessibility (Info.Accessibility_Status);
         if Candidate /= Final_Tasking_Not_Checked then
            return Candidate;
         end if;
      end if;

      if Info.Requires_Discriminant then
         if Info.Discriminant_Matches > 1 then
            return Final_Tasking_Multiple_Matching_Blockers;
         elsif Info.Discriminant_Row = Disc_Consumer.No_Discriminant_Consumer_Row then
            return Final_Tasking_Missing_Discriminant_Row;
         end if;
         Candidate := Status_From_Discriminant (Info.Discriminant_Status);
         if Candidate /= Final_Tasking_Not_Checked then
            return Candidate;
         end if;
      end if;

      return Legal_Status_For_Kind (Info.Kind);
   end Status_For;

   function Message_For (Status : Final_Tasking_Status) return Unbounded_String is
   begin
      if Is_Legal (Status) then
         return To_Unbounded_String ("tasking/protected final effect evidence accepted");
      elsif Is_Indeterminate (Status) then
         return To_Unbounded_String ("tasking/protected final effect legality is indeterminate");
      else
         return To_Unbounded_String ("tasking/protected final effect evidence blocks legality");
      end if;
   end Message_For;

   function Fingerprint_For (Info : Final_Tasking_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Final_Tasking_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Final_Tasking_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Info.Consumer_Fingerprint + 1);
      return H;
   end Fingerprint_For;

   procedure Clear (Model : in out Final_Tasking_Context_Model) is
   begin
      Model.Contexts.Clear;
   end Clear;

   procedure Add_Context (Model : in out Final_Tasking_Context_Model; Info : Final_Tasking_Context_Info) is
   begin
      Model.Contexts.Append (Info);
   end Add_Context;

   function Context_Count (Model : Final_Tasking_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At (Model : Final_Tasking_Context_Model; Index : Positive) return Final_Tasking_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Final_Tasking_Context_Model) return Natural is
      H : Natural := 0;
   begin
      for C of Model.Contexts loop
         H := Mix (H, Natural (C.Id) + 1);
         H := Mix (H, Final_Tasking_Context_Kind'Pos (C.Kind) + 1);
         H := Mix (H, Natural (C.Node) + 1);
         H := Mix (H, C.Source_Fingerprint + 1);
         H := Mix (H, C.Consumer_Fingerprint + 1);
      end loop;
      return H;
   end Fingerprint;

   function Build (Contexts : Final_Tasking_Context_Model) return Final_Tasking_Model is
      Model : Final_Tasking_Model;
      Next  : Final_Tasking_Row_Id := 1;
      Status : Final_Tasking_Status;
      Row : Final_Tasking_Info;
   begin
      for C of Contexts.Contexts loop
         Status := Status_For (C);
         Row :=
           (Id => Next,
            Context => C.Id,
            Kind => C.Kind,
            Status => Status,
            Node => C.Node,
            Object_Name => C.Object_Name,
            Entry_Name => C.Entry_Name,
            Message => Message_For (Status),
            Detail => To_Unbounded_String (Final_Tasking_Status'Image (Status)),
            Tasking_Effect_Row => C.Tasking_Effect_Row,
            Tasking_Effect_Status => C.Tasking_Effect_Status,
            Tasking_CPD_Row => C.Tasking_CPD_Row,
            Tasking_CPD_Status => C.Tasking_CPD_Status,
            Elaboration_Row => C.Elaboration_Row,
            Elaboration_Status => C.Elaboration_Status,
            Representation_Row => C.Representation_Row,
            Representation_Status => C.Representation_Status,
            Accessibility_Row => C.Accessibility_Row,
            Accessibility_Status => C.Accessibility_Status,
            Discriminant_Row => C.Discriminant_Row,
            Discriminant_Status => C.Discriminant_Status,
            Source_Fingerprint => C.Source_Fingerprint,
            Consumer_Fingerprint => C.Consumer_Fingerprint,
            Fingerprint => 0);
         Row.Fingerprint := Fingerprint_For (Row);
         Model.Rows.Append (Row);
         Model.Model_Fingerprint := Mix (Model.Model_Fingerprint, Row.Fingerprint);
         Next := Next + 1;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Final_Tasking_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At (Model : Final_Tasking_Model; Index : Positive) return Final_Tasking_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node (Model : Final_Tasking_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Final_Tasking_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Final_Tasking_Model; Status : Final_Tasking_Status) return Final_Tasking_Set is
      Result : Final_Tasking_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Final_Tasking_Model; Kind : Final_Tasking_Context_Kind) return Final_Tasking_Set is
      Result : Final_Tasking_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Object_Name (Model : Final_Tasking_Model; Object_Name : String) return Final_Tasking_Set is
      Result : Final_Tasking_Set;
   begin
      for Row of Model.Rows loop
         if To_String (Row.Object_Name) = Object_Name then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Rows_For_Object_Name;

   function Set_Count (Set : Final_Tasking_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At (Set : Final_Tasking_Set; Index : Positive) return Final_Tasking_Info is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status (Model : Final_Tasking_Model; Status : Final_Tasking_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Final_Tasking_Model; Kind : Final_Tasking_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Final_Tasking_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Final_Tasking_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Is_Legal (Row.Status) and then not Is_Indeterminate (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Base_Effect_Error_Count (Model : Final_Tasking_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Base_Effect_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Base_Effect_Error_Count;

   function Elaboration_Error_Count (Model : Final_Tasking_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Elaboration_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Elaboration_Error_Count;

   function Representation_Error_Count (Model : Final_Tasking_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Representation_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Representation_Error_Count;

   function Accessibility_Error_Count (Model : Final_Tasking_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Accessibility_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Accessibility_Error_Count;

   function Discriminant_Error_Count (Model : Final_Tasking_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Discriminant_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Discriminant_Error_Count;

   function Indeterminate_Count (Model : Final_Tasking_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Indeterminate_Count;

   function Fingerprint (Model : Final_Tasking_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Is_Legal (Status : Final_Tasking_Status) return Boolean is
   begin
      return Status in Final_Tasking_Legal_Task_Activation_Accepted ..
                       Final_Tasking_Legal_Terminate_Alternative_Accepted;
   end Is_Legal;

   function Is_Base_Effect_Error (Status : Final_Tasking_Status) return Boolean is
   begin
      return Status in Final_Tasking_Base_Effect_Error |
                       Final_Tasking_Protected_Reentrancy_Blocker |
                       Final_Tasking_Protected_State_Mutation_Blocker |
                       Final_Tasking_Protected_Function_Entry_Call_Blocker |
                       Final_Tasking_Barrier_Not_Boolean_Blocker |
                       Final_Tasking_Barrier_Side_Effect_Blocker |
                       Final_Tasking_Entry_Queue_Blocker |
                       Final_Tasking_Accept_Body_Effect_Blocker |
                       Final_Tasking_Requeue_Target_Blocker |
                       Final_Tasking_Requeue_With_Abort_Unsafe |
                       Final_Tasking_Select_Alternative_Blocker |
                       Final_Tasking_Abort_Finalization_Blocker |
                       Final_Tasking_Delay_Alternative_Blocker |
                       Final_Tasking_Terminate_Alternative_Blocker;
   end Is_Base_Effect_Error;

   function Is_Elaboration_Error (Status : Final_Tasking_Status) return Boolean is
   begin
      return Status in Final_Tasking_Missing_Elaboration_Row |
                       Final_Tasking_Elaboration_Blocker |
                       Final_Tasking_Global_Depends_Blocker |
                       Final_Tasking_Predicate_Invariant_Blocker |
                       Final_Tasking_Initialization_Blocker |
                       Final_Tasking_Coverage_Blocker;
   end Is_Elaboration_Error;

   function Is_Representation_Error (Status : Final_Tasking_Status) return Boolean is
   begin
      return Status in Final_Tasking_Missing_Representation_Row |
                       Final_Tasking_Representation_Blocker;
   end Is_Representation_Error;

   function Is_Accessibility_Error (Status : Final_Tasking_Status) return Boolean is
   begin
      return Status in Final_Tasking_Missing_Accessibility_Row |
                       Final_Tasking_Accessibility_Blocker |
                       Final_Tasking_Lifetime_Accessibility_Blocker;
   end Is_Accessibility_Error;

   function Is_Discriminant_Error (Status : Final_Tasking_Status) return Boolean is
   begin
      return Status in Final_Tasking_Missing_Discriminant_Row |
                       Final_Tasking_Discriminant_Blocker;
   end Is_Discriminant_Error;

   function Is_Indeterminate (Status : Final_Tasking_Status) return Boolean is
   begin
      return Status = Final_Tasking_Indeterminate;
   end Is_Indeterminate;

end Editor.Ada_Tasking_Protected_Final_Effects_Legality;
