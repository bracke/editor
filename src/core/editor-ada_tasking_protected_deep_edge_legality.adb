with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Protected_Deep_Edge_Legality is

   use type Tasking_Final.Final_Tasking_Status;
   use type Flow_Proof.Flow_Contract_Proof_Status;
   use type Cross_Final.Cross_Unit_Final_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 1193) mod 2_147_483_647;
   end Mix;

   function Has (S, Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (S, Pattern) /= 0;
   end Has;

   function Legal_Status_For_Kind (Kind : Deep_Tasking_Context_Kind) return Deep_Tasking_Status is
   begin
      case Kind is
         when Deep_Tasking_Protected_Indirect_Call => return Deep_Tasking_Legal_Protected_Indirect_Call_Accepted;
         when Deep_Tasking_Protected_Reentrancy_Path => return Deep_Tasking_Legal_Protected_Reentrancy_Path_Accepted;
         when Deep_Tasking_Entry_Family_Index => return Deep_Tasking_Legal_Entry_Family_Index_Accepted;
         when Deep_Tasking_Entry_Family_Queue => return Deep_Tasking_Legal_Entry_Family_Queue_Accepted;
         when Deep_Tasking_Requeue_Entry_Family => return Deep_Tasking_Legal_Requeue_Entry_Family_Accepted;
         when Deep_Tasking_Select_Entry_Family => return Deep_Tasking_Legal_Select_Entry_Family_Accepted;
         when Deep_Tasking_Accept_Body_Effect_Path => return Deep_Tasking_Legal_Accept_Body_Effect_Path_Accepted;
         when Deep_Tasking_Terminate_Alternative_Graph => return Deep_Tasking_Legal_Terminate_Alternative_Graph_Accepted;
         when Deep_Tasking_Task_Termination_Graph => return Deep_Tasking_Legal_Task_Termination_Graph_Accepted;
         when Deep_Tasking_Abort_Deferred_Finalization => return Deep_Tasking_Legal_Abort_Deferred_Finalization_Accepted;
         when Deep_Tasking_Abortable_Select_Finalization => return Deep_Tasking_Legal_Abortable_Select_Finalization_Accepted;
         when Deep_Tasking_Unknown => return Deep_Tasking_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Final_Tasking
     (Status : Tasking_Final.Final_Tasking_Status) return Deep_Tasking_Status is
      Img : constant String := Tasking_Final.Final_Tasking_Status'Image (Status);
   begin
      if Tasking_Final.Is_Legal (Status) then
         return Deep_Tasking_Not_Checked;
      elsif Has (Img, "NOT_CHECKED") then
         return Deep_Tasking_Missing_Final_Tasking_Row;
      elsif Has (Img, "INDETERMINATE") then
         return Deep_Tasking_Indeterminate;
      elsif Has (Img, "REENTR") then
         return Deep_Tasking_Indirect_Reentrancy_Blocker;
      elsif Has (Img, "ENTRY_QUEUE") then
         return Deep_Tasking_Entry_Family_Queue_Blocker;
      elsif Has (Img, "REQUEUE") then
         return Deep_Tasking_Requeue_Family_Blocker;
      elsif Has (Img, "SELECT") then
         return Deep_Tasking_Select_Family_Blocker;
      elsif Has (Img, "ACCEPT") then
         return Deep_Tasking_Accept_Body_Effect_Blocker;
      elsif Has (Img, "TERMINATE") or else Has (Img, "TERMINATION") then
         return Deep_Tasking_Task_Termination_Order_Blocker;
      elsif Has (Img, "ABORT") or else Has (Img, "FINALIZATION") then
         return Deep_Tasking_Abort_Deferred_Finalization_Blocker;
      else
         return Deep_Tasking_Final_Tasking_Blocker;
      end if;
   end Status_From_Final_Tasking;

   function Status_From_Flow_Proof
     (Status : Flow_Proof.Flow_Contract_Proof_Status) return Deep_Tasking_Status is
      Img : constant String := Flow_Proof.Flow_Contract_Proof_Status'Image (Status);
   begin
      if Flow_Proof.Is_Legal (Status) then
         return Deep_Tasking_Not_Checked;
      elsif Has (Img, "NOT_CHECKED") then
         return Deep_Tasking_Missing_Flow_Proof_Row;
      elsif Has (Img, "INDETERMINATE") then
         return Deep_Tasking_Indeterminate;
      else
         return Deep_Tasking_Flow_Contract_Blocker;
      end if;
   end Status_From_Flow_Proof;

   function Status_From_Cross_Unit
     (Status : Cross_Final.Cross_Unit_Final_Status) return Deep_Tasking_Status is
      Img : constant String := Cross_Final.Cross_Unit_Final_Status'Image (Status);
   begin
      if Cross_Final.Is_Legal (Status) then
         return Deep_Tasking_Not_Checked;
      elsif Has (Img, "NOT_CHECKED") then
         return Deep_Tasking_Missing_Cross_Unit_Row;
      elsif Cross_Final.Is_Indeterminate (Status) then
         return Deep_Tasking_Indeterminate;
      else
         return Deep_Tasking_Cross_Unit_Blocker;
      end if;
   end Status_From_Cross_Unit;

   procedure Accumulate
     (Candidate : Deep_Tasking_Status;
      Result    : in out Deep_Tasking_Status;
      Count     : in out Natural) is
   begin
      if Candidate /= Deep_Tasking_Not_Checked then
         Count := Count + 1;
         if Result = Deep_Tasking_Not_Checked then
            Result := Candidate;
         else
            Result := Deep_Tasking_Multiple_Blockers;
         end if;
      end if;
   end Accumulate;

   function Classify (Context : Deep_Tasking_Context_Info; Blockers : out Natural) return Deep_Tasking_Status is
      Result : Deep_Tasking_Status := Deep_Tasking_Not_Checked;
   begin
      Blockers := 0;

      if Context.Expected_Source_Fingerprint /= 0
        and then Context.Source_Fingerprint /= Context.Expected_Source_Fingerprint
      then
         Accumulate (Deep_Tasking_Source_Fingerprint_Mismatch, Result, Blockers);
      end if;

      if Context.Requires_Final_Tasking then
         if Context.Final_Tasking_Matches = 0
           or else Context.Final_Tasking_Status = Tasking_Final.Final_Tasking_Not_Checked
         then
            Accumulate (Deep_Tasking_Missing_Final_Tasking_Row, Result, Blockers);
         else
            Accumulate (Status_From_Final_Tasking (Context.Final_Tasking_Status), Result, Blockers);
         end if;
      end if;

      if Context.Requires_Flow_Proof then
         if Context.Flow_Proof_Matches = 0
           or else Context.Flow_Proof_Status = Flow_Proof.Flow_Contract_Proof_Not_Checked
         then
            Accumulate (Deep_Tasking_Missing_Flow_Proof_Row, Result, Blockers);
         else
            Accumulate (Status_From_Flow_Proof (Context.Flow_Proof_Status), Result, Blockers);
         end if;
      end if;

      if Context.Requires_Cross_Unit then
         if Context.Cross_Unit_Matches = 0
           or else Context.Cross_Unit_Status = Cross_Final.Cross_Unit_Final_Not_Checked
         then
            Accumulate (Deep_Tasking_Missing_Cross_Unit_Row, Result, Blockers);
         else
            Accumulate (Status_From_Cross_Unit (Context.Cross_Unit_Status), Result, Blockers);
         end if;
      end if;

      if Context.Indirect_Reentrancy then
         Accumulate (Deep_Tasking_Indirect_Reentrancy_Blocker, Result, Blockers);
      end if;
      if Context.Callback_Reentrancy then
         Accumulate (Deep_Tasking_Protected_Callback_Reentrancy_Blocker, Result, Blockers);
      end if;
      if Context.Entry_Family_Index_Error then
         Accumulate (Deep_Tasking_Entry_Family_Index_Blocker, Result, Blockers);
      end if;
      if Context.Entry_Family_Queue_Error then
         Accumulate (Deep_Tasking_Entry_Family_Queue_Blocker, Result, Blockers);
      end if;
      if Context.Requeue_Family_Error then
         Accumulate (Deep_Tasking_Requeue_Family_Blocker, Result, Blockers);
      end if;
      if Context.Select_Family_Error then
         Accumulate (Deep_Tasking_Select_Family_Blocker, Result, Blockers);
      end if;
      if Context.Accept_Body_Effect_Error then
         Accumulate (Deep_Tasking_Accept_Body_Effect_Blocker, Result, Blockers);
      end if;
      if Context.Terminate_Missing_Edge then
         Accumulate (Deep_Tasking_Terminate_Dependency_Missing_Edge, Result, Blockers);
      end if;
      if Context.Terminate_Cycle then
         Accumulate (Deep_Tasking_Terminate_Dependency_Cycle, Result, Blockers);
      end if;
      if Context.Terminate_Overflow then
         Accumulate (Deep_Tasking_Terminate_Dependency_Overflow, Result, Blockers);
      end if;
      if Context.Task_Termination_Order_Error then
         Accumulate (Deep_Tasking_Task_Termination_Order_Blocker, Result, Blockers);
      end if;
      if Context.Abort_Deferred_Finalization_Error then
         Accumulate (Deep_Tasking_Abort_Deferred_Finalization_Blocker, Result, Blockers);
      end if;
      if Context.Abortable_Select_Finalization_Error then
         Accumulate (Deep_Tasking_Abortable_Select_Finalization_Blocker, Result, Blockers);
      end if;

      if Result = Deep_Tasking_Not_Checked then
         return Legal_Status_For_Kind (Context.Kind);
      else
         return Result;
      end if;
   end Classify;

   function Message_For (Status : Deep_Tasking_Status) return String is
   begin
      if Is_Legal (Status) then
         return "tasking/protected deep edge accepted";
      elsif Status = Deep_Tasking_Multiple_Blockers then
         return "multiple tasking/protected deep edge blockers";
      elsif Is_Indeterminate (Status) then
         return "tasking/protected deep edge is indeterminate";
      else
         return "tasking/protected deep edge blocker";
      end if;
   end Message_For;

   function Build_Row (Context : Deep_Tasking_Context_Info) return Deep_Tasking_Info is
      Blockers : Natural := 0;
      Status : constant Deep_Tasking_Status := Classify (Context, Blockers);
      Row : Deep_Tasking_Info;
   begin
      Row.Id := Context.Id;
      Row.Context := Context.Id;
      Row.Kind := Context.Kind;
      Row.Status := Status;
      Row.Node := Context.Node;
      Row.Operation_Name := Context.Operation_Name;
      Row.Entry_Name := Context.Entry_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String (Deep_Tasking_Status'Image (Status));
      Row.Final_Tasking_Status := Context.Final_Tasking_Status;
      Row.Flow_Proof_Status := Context.Flow_Proof_Status;
      Row.Cross_Unit_Status := Context.Cross_Unit_Status;
      Row.Blocker_Count := Blockers;
      Row.Source_Fingerprint := Context.Source_Fingerprint;
      Row.Start_Line := Context.Start_Line;
      Row.Start_Column := Context.Start_Column;
      Row.End_Line := Context.End_Line;
      Row.End_Column := Context.End_Column;
      Row.Fingerprint := Mix
        (Mix (Natural (Context.Id), Deep_Tasking_Status'Pos (Status)),
         Mix (Natural (Context.Node), Context.Source_Fingerprint));
      return Row;
   end Build_Row;

   procedure Clear (Model : in out Deep_Tasking_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Deep_Tasking_Context_Model; Info : Deep_Tasking_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Mix (Natural (Info.Id), Mix (Deep_Tasking_Context_Kind'Pos (Info.Kind), Info.Source_Fingerprint)));
   end Add_Context;

   function Context_Count (Model : Deep_Tasking_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At (Model : Deep_Tasking_Context_Model; Index : Positive) return Deep_Tasking_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Deep_Tasking_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Deep_Tasking_Context_Model) return Deep_Tasking_Model is
      Model : Deep_Tasking_Model;
      Row : Deep_Tasking_Info;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         Row := Build_Row (Context_At (Contexts, I));
         Model.Items.Append (Row);
         Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
         if Is_Legal (Row.Status) then
            Model.Legal_Total := Model.Legal_Total + 1;
         else
            Model.Error_Total := Model.Error_Total + 1;
         end if;
         if Is_Final_Tasking_Error (Row.Status) then
            Model.Final_Tasking_Error_Total := Model.Final_Tasking_Error_Total + 1;
         end if;
         if Is_Flow_Proof_Error (Row.Status) then
            Model.Flow_Proof_Error_Total := Model.Flow_Proof_Error_Total + 1;
         end if;
         if Is_Cross_Unit_Error (Row.Status) then
            Model.Cross_Unit_Error_Total := Model.Cross_Unit_Error_Total + 1;
         end if;
         if Is_Tasking_Edge_Error (Row.Status) then
            Model.Tasking_Edge_Error_Total := Model.Tasking_Edge_Error_Total + 1;
         end if;
         if Is_Indeterminate (Row.Status) then
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         end if;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Deep_Tasking_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At (Model : Deep_Tasking_Model; Index : Positive) return Deep_Tasking_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node (Model : Deep_Tasking_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Deep_Tasking_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Deep_Tasking_Model; Status : Deep_Tasking_Status) return Deep_Tasking_Set is
      Set : Deep_Tasking_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Set.Items.Append (Row);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Deep_Tasking_Model; Kind : Deep_Tasking_Context_Kind) return Deep_Tasking_Set is
      Set : Deep_Tasking_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Set.Items.Append (Row);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Set_Count (Set : Deep_Tasking_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At (Set : Deep_Tasking_Set; Index : Positive) return Deep_Tasking_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status (Model : Deep_Tasking_Model; Status : Deep_Tasking_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Deep_Tasking_Model; Kind : Deep_Tasking_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Deep_Tasking_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Deep_Tasking_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Final_Tasking_Error_Count (Model : Deep_Tasking_Model) return Natural is
   begin
      return Model.Final_Tasking_Error_Total;
   end Final_Tasking_Error_Count;

   function Flow_Proof_Error_Count (Model : Deep_Tasking_Model) return Natural is
   begin
      return Model.Flow_Proof_Error_Total;
   end Flow_Proof_Error_Count;

   function Cross_Unit_Error_Count (Model : Deep_Tasking_Model) return Natural is
   begin
      return Model.Cross_Unit_Error_Total;
   end Cross_Unit_Error_Count;

   function Tasking_Edge_Error_Count (Model : Deep_Tasking_Model) return Natural is
   begin
      return Model.Tasking_Edge_Error_Total;
   end Tasking_Edge_Error_Count;

   function Indeterminate_Count (Model : Deep_Tasking_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Deep_Tasking_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Is_Legal (Status : Deep_Tasking_Status) return Boolean is
   begin
      case Status is
         when Deep_Tasking_Legal_Protected_Indirect_Call_Accepted
            | Deep_Tasking_Legal_Protected_Reentrancy_Path_Accepted
            | Deep_Tasking_Legal_Entry_Family_Index_Accepted
            | Deep_Tasking_Legal_Entry_Family_Queue_Accepted
            | Deep_Tasking_Legal_Requeue_Entry_Family_Accepted
            | Deep_Tasking_Legal_Select_Entry_Family_Accepted
            | Deep_Tasking_Legal_Accept_Body_Effect_Path_Accepted
            | Deep_Tasking_Legal_Terminate_Alternative_Graph_Accepted
            | Deep_Tasking_Legal_Task_Termination_Graph_Accepted
            | Deep_Tasking_Legal_Abort_Deferred_Finalization_Accepted
            | Deep_Tasking_Legal_Abortable_Select_Finalization_Accepted => return True;
         when others => return False;
      end case;
   end Is_Legal;

   function Is_Final_Tasking_Error (Status : Deep_Tasking_Status) return Boolean is
   begin
      case Status is
         when Deep_Tasking_Missing_Final_Tasking_Row
            | Deep_Tasking_Final_Tasking_Blocker => return True;
         when others => return False;
      end case;
   end Is_Final_Tasking_Error;

   function Is_Flow_Proof_Error (Status : Deep_Tasking_Status) return Boolean is
   begin
      case Status is
         when Deep_Tasking_Missing_Flow_Proof_Row
            | Deep_Tasking_Flow_Contract_Blocker => return True;
         when others => return False;
      end case;
   end Is_Flow_Proof_Error;

   function Is_Cross_Unit_Error (Status : Deep_Tasking_Status) return Boolean is
   begin
      case Status is
         when Deep_Tasking_Missing_Cross_Unit_Row
            | Deep_Tasking_Cross_Unit_Blocker => return True;
         when others => return False;
      end case;
   end Is_Cross_Unit_Error;

   function Is_Tasking_Edge_Error (Status : Deep_Tasking_Status) return Boolean is
   begin
      case Status is
         when Deep_Tasking_Indirect_Reentrancy_Blocker
            | Deep_Tasking_Protected_Callback_Reentrancy_Blocker
            | Deep_Tasking_Entry_Family_Index_Blocker
            | Deep_Tasking_Entry_Family_Queue_Blocker
            | Deep_Tasking_Requeue_Family_Blocker
            | Deep_Tasking_Select_Family_Blocker
            | Deep_Tasking_Accept_Body_Effect_Blocker
            | Deep_Tasking_Terminate_Dependency_Missing_Edge
            | Deep_Tasking_Terminate_Dependency_Cycle
            | Deep_Tasking_Terminate_Dependency_Overflow
            | Deep_Tasking_Task_Termination_Order_Blocker
            | Deep_Tasking_Abort_Deferred_Finalization_Blocker
            | Deep_Tasking_Abortable_Select_Finalization_Blocker
            | Deep_Tasking_Source_Fingerprint_Mismatch
            | Deep_Tasking_Multiple_Blockers => return True;
         when others => return False;
      end case;
   end Is_Tasking_Edge_Error;

   function Is_Indeterminate (Status : Deep_Tasking_Status) return Boolean is
   begin
      return Status = Deep_Tasking_Indeterminate;
   end Is_Indeterminate;

   function Has_Error (Info : Deep_Tasking_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status);
   end Has_Error;

end Editor.Ada_Tasking_Protected_Deep_Edge_Legality;
