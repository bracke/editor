with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Rep_Flow.Representation_Tasking_Row_Id;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Left) * 16_777_619 + Hash_Value (Right) + 2_166_136_261;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Text_Hash (Value : Unbounded_String) return Natural is
      S : constant String := To_String (Value);
      H : Natural := 0;
   begin
      for Ch of S loop
         H := Mix (H, Character'Pos (Ch));
      end loop;
      return H;
   end Text_Hash;

   function Replay_Is_Legal (Status : Replay.Replay_Status) return Boolean is
   begin
      case Status is
         when Replay.Replay_Legal_Substituted_Declaration |
              Replay.Replay_Legal_Substituted_Statement |
              Replay.Replay_Legal_Substituted_Expression |
              Replay.Replay_Legal_Call |
              Replay.Replay_Legal_Flow_Effect |
              Replay.Replay_Legal_Predicate_Invariant |
              Replay.Replay_Legal_Accessibility |
              Replay.Replay_Legal_Representation_Freezing |
              Replay.Replay_Legal_Nested_Instance =>
            return True;
         when others =>
            return False;
      end case;
   end Replay_Is_Legal;

   function Is_Legal (Status : Generic_Replay_Representation_Status) return Boolean is
   begin
      case Status is
         when Generic_Replay_Representation_Legal_Formal_Substitution_Accepted |
              Generic_Replay_Representation_Legal_Body_Declaration_Accepted |
              Generic_Replay_Representation_Legal_Body_Statement_Accepted |
              Generic_Replay_Representation_Legal_Body_Expression_Accepted |
              Generic_Replay_Representation_Legal_Generic_Instance_Accepted |
              Generic_Replay_Representation_Legal_Nested_Generic_Instance_Accepted |
              Generic_Replay_Representation_Legal_Freezing_Effect_Accepted |
              Generic_Replay_Representation_Legal_Representation_Clause_Accepted |
              Generic_Replay_Representation_Legal_Operational_Attribute_Accepted |
              Generic_Replay_Representation_Legal_Stream_Attribute_Accepted |
              Generic_Replay_Representation_Legal_Record_Layout_Accepted |
              Generic_Replay_Representation_Legal_Private_Full_View_Accepted |
              Generic_Replay_Representation_Legal_Tasking_Effect_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Legal;

   function Is_Global_Error (Status : Generic_Replay_Representation_Status) return Boolean is
   begin
      return Status in Generic_Replay_Representation_Refined_Global_Missing_Read |
                       Generic_Replay_Representation_Refined_Global_Missing_Write |
                       Generic_Replay_Representation_Refined_Global_Mode_Mismatch |
                       Generic_Replay_Representation_Refined_Global_Extra_Item;
   end Is_Global_Error;

   function Is_Depends_Error (Status : Generic_Replay_Representation_Status) return Boolean is
   begin
      return Status in Generic_Replay_Representation_Refined_Depends_Missing_Edge |
                       Generic_Replay_Representation_Refined_Depends_Extra_Edge |
                       Generic_Replay_Representation_Refined_Depends_Source_Mode_Error |
                       Generic_Replay_Representation_Refined_Depends_Target_Mode_Error;
   end Is_Depends_Error;

   function Is_Propagation_Error (Status : Generic_Replay_Representation_Status) return Boolean is
   begin
      return Status = Generic_Replay_Representation_Call_Effect_Not_Propagated;
   end Is_Propagation_Error;

   function Legal_Status_For_Kind
     (Kind : Generic_Replay_Representation_Context_Kind) return Generic_Replay_Representation_Status is
   begin
      case Kind is
         when Generic_Replay_Representation_Formal_Substitution =>
            return Generic_Replay_Representation_Legal_Formal_Substitution_Accepted;
         when Generic_Replay_Representation_Body_Declaration =>
            return Generic_Replay_Representation_Legal_Body_Declaration_Accepted;
         when Generic_Replay_Representation_Body_Statement =>
            return Generic_Replay_Representation_Legal_Body_Statement_Accepted;
         when Generic_Replay_Representation_Body_Expression =>
            return Generic_Replay_Representation_Legal_Body_Expression_Accepted;
         when Generic_Replay_Representation_Generic_Instance =>
            return Generic_Replay_Representation_Legal_Generic_Instance_Accepted;
         when Generic_Replay_Representation_Nested_Generic_Instance =>
            return Generic_Replay_Representation_Legal_Nested_Generic_Instance_Accepted;
         when Generic_Replay_Representation_Freezing_Effect =>
            return Generic_Replay_Representation_Legal_Freezing_Effect_Accepted;
         when Generic_Replay_Representation_Representation_Clause =>
            return Generic_Replay_Representation_Legal_Representation_Clause_Accepted;
         when Generic_Replay_Representation_Operational_Attribute =>
            return Generic_Replay_Representation_Legal_Operational_Attribute_Accepted;
         when Generic_Replay_Representation_Stream_Attribute =>
            return Generic_Replay_Representation_Legal_Stream_Attribute_Accepted;
         when Generic_Replay_Representation_Record_Layout =>
            return Generic_Replay_Representation_Legal_Record_Layout_Accepted;
         when Generic_Replay_Representation_Private_Full_View =>
            return Generic_Replay_Representation_Legal_Private_Full_View_Accepted;
         when Generic_Replay_Representation_Tasking_Effect =>
            return Generic_Replay_Representation_Legal_Tasking_Effect_Accepted;
         when others =>
            return Generic_Replay_Representation_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Replay
     (Status : Replay.Replay_Status) return Generic_Replay_Representation_Status is
   begin
      case Status is
         when Replay.Replay_Source_Instance_Mapping_Missing |
              Replay.Replay_Formal_Actual_Mapping_Missing |
              Replay.Replay_Diagnostic_Backmap_Missing =>
            return Generic_Replay_Representation_Replay_Mapping_Error;
         when Replay.Replay_Generic_Expansion_Error =>
            return Generic_Replay_Representation_Replay_Expansion_Error;
         when Replay.Replay_Overload_Preference_Error =>
            return Generic_Replay_Representation_Replay_Overload_Error;
         when Replay.Replay_Flow_Effect_Error =>
            return Generic_Replay_Representation_Replay_Flow_Error;
         when Replay.Replay_Predicate_Propagation_Error =>
            return Generic_Replay_Representation_Replay_Predicate_Error;
         when Replay.Replay_Accessibility_Precision_Error =>
            return Generic_Replay_Representation_Replay_Accessibility_Error;
         when Replay.Replay_Representation_Freezing_Error =>
            return Generic_Replay_Representation_Replay_Representation_Error;
         when Replay.Replay_Coverage_Gate_Blocker =>
            return Generic_Replay_Representation_Replay_Coverage_Gate_Blocker;
         when Replay.Replay_Multiple_Blockers =>
            return Generic_Replay_Representation_Base_Replay_Error;
         when Replay.Replay_Indeterminate | Replay.Replay_Not_Checked =>
            return Generic_Replay_Representation_Indeterminate;
         when others =>
            return Generic_Replay_Representation_Base_Replay_Error;
      end case;
   end Status_From_Replay;

   function Status_From_Representation_Flow
     (Status : Rep_Flow.Representation_Tasking_Status) return Generic_Replay_Representation_Status is
   begin
      case Status is
         when Rep_Flow.Representation_Tasking_Base_Freezing_Error =>
            return Generic_Replay_Representation_Base_Freezing_Error;
         when Rep_Flow.Representation_Tasking_Refined_Global_Missing_Read =>
            return Generic_Replay_Representation_Refined_Global_Missing_Read;
         when Rep_Flow.Representation_Tasking_Refined_Global_Missing_Write =>
            return Generic_Replay_Representation_Refined_Global_Missing_Write;
         when Rep_Flow.Representation_Tasking_Refined_Global_Mode_Mismatch =>
            return Generic_Replay_Representation_Refined_Global_Mode_Mismatch;
         when Rep_Flow.Representation_Tasking_Refined_Global_Extra_Item =>
            return Generic_Replay_Representation_Refined_Global_Extra_Item;
         when Rep_Flow.Representation_Tasking_Refined_Depends_Missing_Edge =>
            return Generic_Replay_Representation_Refined_Depends_Missing_Edge;
         when Rep_Flow.Representation_Tasking_Refined_Depends_Extra_Edge =>
            return Generic_Replay_Representation_Refined_Depends_Extra_Edge;
         when Rep_Flow.Representation_Tasking_Refined_Depends_Source_Mode_Error =>
            return Generic_Replay_Representation_Refined_Depends_Source_Mode_Error;
         when Rep_Flow.Representation_Tasking_Refined_Depends_Target_Mode_Error =>
            return Generic_Replay_Representation_Refined_Depends_Target_Mode_Error;
         when Rep_Flow.Representation_Tasking_Call_Effect_Not_Propagated =>
            return Generic_Replay_Representation_Call_Effect_Not_Propagated;
         when Rep_Flow.Representation_Tasking_Coverage_Feedback_Blocker =>
            return Generic_Replay_Representation_Coverage_Feedback_Blocker;
         when Rep_Flow.Representation_Tasking_Linked_Flow_Graph_Error =>
            return Generic_Replay_Representation_Linked_Flow_Graph_Error;
         when Rep_Flow.Representation_Tasking_Base_Contract_Flow_Error =>
            return Generic_Replay_Representation_Base_Contract_Flow_Error;
         when Rep_Flow.Representation_Tasking_Base_Elaboration_Error =>
            return Generic_Replay_Representation_Base_Elaboration_Error;
         when Rep_Flow.Representation_Tasking_Base_Tasking_Effect_Error =>
            return Generic_Replay_Representation_Base_Tasking_Effect_Error;
         when Rep_Flow.Representation_Tasking_Multiple_Tasking_Flow_Blockers =>
            return Generic_Replay_Representation_Multiple_Representation_Flow_Blockers;
         when Rep_Flow.Representation_Tasking_Tasking_Flow_Indeterminate |
              Rep_Flow.Representation_Tasking_Indeterminate =>
            return Generic_Replay_Representation_Representation_Flow_Indeterminate;
         when Rep_Flow.Representation_Tasking_Missing_Tasking_Flow_Row |
              Rep_Flow.Representation_Tasking_Not_Checked =>
            return Generic_Replay_Representation_Missing_Representation_Flow_Row;
         when others =>
            return Generic_Replay_Representation_Base_Representation_Flow_Error;
      end case;
   end Status_From_Representation_Flow;

   function Status_For (Info : Generic_Replay_Representation_Context_Info) return Generic_Replay_Representation_Status is
   begin
      if not Replay_Is_Legal (Info.Replay_Status) then
         return Status_From_Replay (Info.Replay_Status);
      elsif Info.Representation_Flow_Matches > 1 then
         return Generic_Replay_Representation_Multiple_Representation_Flow_Blockers;
      elsif Info.Representation_Flow_Row = Rep_Flow.No_Representation_Tasking_Row then
         return Generic_Replay_Representation_Missing_Representation_Flow_Row;
      elsif Rep_Flow.Is_Legal (Info.Representation_Flow_Status) then
         return Legal_Status_For_Kind (Info.Kind);
      else
         return Status_From_Representation_Flow (Info.Representation_Flow_Status);
      end if;
   end Status_For;

   function Row_Fingerprint (Info : Generic_Replay_Representation_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Generic_Replay_Representation_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Generic_Replay_Representation_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Generic_Source_Node) + 1);
      H := Mix (H, Natural (Info.Instance_Node) + 1);
      H := Mix (H, Natural (Info.Body_Node) + 1);
      H := Mix (H, Natural (Info.Representation_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Text_Hash (Info.Formal_Name));
      H := Mix (H, Text_Hash (Info.Actual_Name));
      H := Mix (H, Text_Hash (Info.Generic_Unit_Name));
      H := Mix (H, Text_Hash (Info.Instance_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, Natural (Info.Replay_Row) + 1);
      H := Mix (H, Replay.Replay_Status'Pos (Info.Replay_Status) + 1);
      H := Mix (H, Natural (Info.Representation_Flow_Row) + 1);
      H := Mix (H, Rep_Flow.Representation_Tasking_Status'Pos (Info.Representation_Flow_Status) + 1);
      H := Mix (H, Info.Representation_Flow_Matches + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Info.Substitution_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Generic_Replay_Representation_Status) return Unbounded_String is
   begin
      case Status is
         when Generic_Replay_Representation_Base_Replay_Error =>
            return To_Unbounded_String ("generic body replay legality failed before representation-flow consumption");
         when Generic_Replay_Representation_Replay_Mapping_Error =>
            return To_Unbounded_String ("generic body replay representation source/instance mapping is incomplete");
         when Generic_Replay_Representation_Replay_Representation_Error =>
            return To_Unbounded_String ("generic body replay already has representation/freezing error");
         when Generic_Replay_Representation_Missing_Representation_Flow_Row =>
            return To_Unbounded_String ("generic body replay is missing representation/freezing tasking-flow evidence");
         when Generic_Replay_Representation_Base_Freezing_Error =>
            return To_Unbounded_String ("generic body replay consumes a base representation/freezing blocker");
         when Generic_Replay_Representation_Refined_Global_Missing_Read =>
            return To_Unbounded_String ("generic body replay consumes representation Refined_Global missing-read blocker");
         when Generic_Replay_Representation_Refined_Global_Missing_Write =>
            return To_Unbounded_String ("generic body replay consumes representation Refined_Global missing-write blocker");
         when Generic_Replay_Representation_Refined_Depends_Missing_Edge =>
            return To_Unbounded_String ("generic body replay consumes representation Refined_Depends missing-edge blocker");
         when Generic_Replay_Representation_Call_Effect_Not_Propagated =>
            return To_Unbounded_String ("generic body replay consumes unpropagated representation call effect");
         when Generic_Replay_Representation_Coverage_Feedback_Blocker |
              Generic_Replay_Representation_Replay_Coverage_Gate_Blocker =>
            return To_Unbounded_String ("generic body replay is blocked by coverage feedback");
         when Generic_Replay_Representation_Base_Elaboration_Error =>
            return To_Unbounded_String ("generic body replay consumes representation elaboration blocker");
         when Generic_Replay_Representation_Base_Tasking_Effect_Error =>
            return To_Unbounded_String ("generic body replay consumes representation tasking-effect blocker");
         when Generic_Replay_Representation_Multiple_Representation_Flow_Blockers =>
            return To_Unbounded_String ("generic body replay has multiple matching representation-flow blockers");
         when Generic_Replay_Representation_Representation_Flow_Indeterminate |
              Generic_Replay_Representation_Indeterminate =>
            return To_Unbounded_String ("generic body replay representation-flow result is indeterminate");
         when others =>
            if Is_Legal (Status) then
               return To_Unbounded_String ("generic body replay representation-flow consumer accepted");
            else
               return To_Unbounded_String ("generic body replay representation-flow blocker");
            end if;
      end case;
   end Message_For;

   procedure Clear (Model : in out Generic_Replay_Representation_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Generic_Replay_Representation_Context_Model;
      Info  : Generic_Replay_Representation_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id) + Info.Source_Fingerprint + Info.Substitution_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Generic_Replay_Representation_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Generic_Replay_Representation_Context_Model;
      Index : Positive) return Generic_Replay_Representation_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Generic_Replay_Representation_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Generic_Replay_Representation_Context_Model) return Generic_Replay_Representation_Model is
      Result : Generic_Replay_Representation_Model;
      Row    : Generic_Replay_Representation_Info;
      Status : Generic_Replay_Representation_Status;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Generic_Replay_Representation_Context_Info := Contexts.Contexts.Element (I);
         begin
            Status := Status_For (C);
            Row :=
              (Id => Generic_Replay_Representation_Row_Id (I),
               Context => C.Id,
               Kind => C.Kind,
               Status => Status,
               Node => C.Node,
               Generic_Source_Node => C.Generic_Source_Node,
               Instance_Node => C.Instance_Node,
               Body_Node => C.Body_Node,
               Representation_Node => C.Representation_Node,
               Target_Node => C.Target_Node,
               Formal_Name => C.Formal_Name,
               Actual_Name => C.Actual_Name,
               Generic_Unit_Name => C.Generic_Unit_Name,
               Instance_Name => C.Instance_Name,
               Target_Name => C.Target_Name,
               Message => Message_For (Status),
               Detail => To_Unbounded_String ("Pass1160 generic replay representation-flow consumer"),
               Replay_Row => C.Replay_Row,
               Replay_Status => C.Replay_Status,
               Representation_Flow_Row => C.Representation_Flow_Row,
               Representation_Flow_Status => C.Representation_Flow_Status,
               Representation_Flow_Matches => C.Representation_Flow_Matches,
               Start_Line => C.Start_Line,
               Start_Column => C.Start_Column,
               End_Line => C.End_Line,
               End_Column => C.End_Column,
               Generic_Start_Line => C.Generic_Start_Line,
               Generic_Start_Column => C.Generic_Start_Column,
               Instance_Start_Line => C.Instance_Start_Line,
               Instance_Start_Column => C.Instance_Start_Column,
               Source_Fingerprint => C.Source_Fingerprint,
               Substitution_Fingerprint => C.Substitution_Fingerprint,
               Fingerprint => 0);
            Row.Fingerprint := Row_Fingerprint (Row);
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);

            if Is_Legal (Status) then
               Result.Legal_Total := Result.Legal_Total + 1;
            else
               Result.Error_Total := Result.Error_Total + 1;
            end if;
            if Status in Generic_Replay_Representation_Base_Replay_Error |
                         Generic_Replay_Representation_Replay_Mapping_Error |
                         Generic_Replay_Representation_Replay_Expansion_Error |
                         Generic_Replay_Representation_Replay_Overload_Error |
                         Generic_Replay_Representation_Replay_Flow_Error |
                         Generic_Replay_Representation_Replay_Predicate_Error |
                         Generic_Replay_Representation_Replay_Accessibility_Error |
                         Generic_Replay_Representation_Replay_Representation_Error then
               Result.Replay_Error_Total := Result.Replay_Error_Total + 1;
            end if;
            if Status in Generic_Replay_Representation_Base_Representation_Flow_Error |
                         Generic_Replay_Representation_Base_Freezing_Error |
                         Generic_Replay_Representation_Missing_Representation_Flow_Row then
               Result.Representation_Error_Total := Result.Representation_Error_Total + 1;
            end if;
            if Is_Global_Error (Status) then
               Result.Global_Error_Total := Result.Global_Error_Total + 1;
            end if;
            if Is_Depends_Error (Status) then
               Result.Depends_Error_Total := Result.Depends_Error_Total + 1;
            end if;
            if Is_Propagation_Error (Status) then
               Result.Propagation_Error_Total := Result.Propagation_Error_Total + 1;
            end if;
            if Status in Generic_Replay_Representation_Coverage_Feedback_Blocker |
                         Generic_Replay_Representation_Replay_Coverage_Gate_Blocker then
               Result.Coverage_Error_Total := Result.Coverage_Error_Total + 1;
            end if;
            if Status = Generic_Replay_Representation_Base_Elaboration_Error then
               Result.Elaboration_Error_Total := Result.Elaboration_Error_Total + 1;
            end if;
            if Status = Generic_Replay_Representation_Base_Tasking_Effect_Error then
               Result.Tasking_Error_Total := Result.Tasking_Error_Total + 1;
            end if;
            if Status in Generic_Replay_Representation_Representation_Flow_Indeterminate |
                         Generic_Replay_Representation_Indeterminate then
               Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Generic_Replay_Representation_Model;
      Index : Positive) return Generic_Replay_Representation_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Generic_Replay_Representation_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Replay_Representation_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Generic_Replay_Representation_Model;
      Status : Generic_Replay_Representation_Status) return Generic_Replay_Representation_Set is
      Result : Generic_Replay_Representation_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Generic_Replay_Representation_Model;
      Kind  : Generic_Replay_Representation_Context_Kind) return Generic_Replay_Representation_Set is
      Result : Generic_Replay_Representation_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Instance
     (Model : Generic_Replay_Representation_Model;
      Name  : String) return Generic_Replay_Representation_Set is
      Result : Generic_Replay_Representation_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Instance_Name) = Name then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Instance;

   function Set_Count (Set : Generic_Replay_Representation_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Generic_Replay_Representation_Set;
      Index : Positive) return Generic_Replay_Representation_Info is
   begin
      if Index > Natural (Set.Items.Length) then
         return (others => <>);
      end if;
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Generic_Replay_Representation_Model;
      Status : Generic_Replay_Representation_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Generic_Replay_Representation_Model;
      Kind  : Generic_Replay_Representation_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Replay_Error_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Replay_Error_Total;
   end Replay_Error_Count;

   function Representation_Error_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Representation_Error_Total;
   end Representation_Error_Count;

   function Global_Error_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Global_Error_Total;
   end Global_Error_Count;

   function Depends_Error_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Depends_Error_Total;
   end Depends_Error_Count;

   function Propagation_Error_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Propagation_Error_Total;
   end Propagation_Error_Count;

   function Coverage_Error_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Coverage_Error_Total;
   end Coverage_Error_Count;

   function Elaboration_Error_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Elaboration_Error_Total;
   end Elaboration_Error_Count;

   function Tasking_Error_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Tasking_Error_Total;
   end Tasking_Error_Count;

   function Indeterminate_Count (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Generic_Replay_Representation_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality;
