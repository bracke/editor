with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Protected_AST_Repair_Legality is

   pragma Suppress (Overflow_Check);
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Audit.Ada_Construct_Kind;


   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Map_Construct
     (Construct : Audit.Ada_Construct_Kind) return Tasking_AST_Construct_Kind is
   begin
      case Construct is
         when Audit.Construct_Task_Type => return Tasking_AST_Task_Type;
         when Audit.Construct_Task_Body => return Tasking_AST_Task_Body;
         when Audit.Construct_Protected_Type => return Tasking_AST_Protected_Type;
         when Audit.Construct_Protected_Body => return Tasking_AST_Protected_Body;
         when Audit.Construct_Entry_Declaration => return Tasking_AST_Entry_Declaration;
         when Audit.Construct_Entry_Body => return Tasking_AST_Entry_Body;
         when Audit.Construct_Accept_Statement => return Tasking_AST_Accept_Statement;
         when Audit.Construct_Requeue_Statement => return Tasking_AST_Requeue_Statement;
         when Audit.Construct_Select_Statement => return Tasking_AST_Select_Statement;
         when others => return Tasking_AST_Unknown;
      end case;
   end Map_Construct;

   function Is_Tasking_Construct
     (Construct : Audit.Ada_Construct_Kind) return Boolean is
   begin
      return Map_Construct (Construct) /= Tasking_AST_Unknown;
   end Is_Tasking_Construct;

   function Is_Accepted (Status : Tasking_AST_Repair_Status) return Boolean is
   begin
      return Status in
        Tasking_AST_Legal_Task_Type_Repaired ..
        Tasking_AST_Legal_Select_Statement_Repaired;
   end Is_Accepted;

   function Has_Error (Info : Tasking_AST_Repair_Info) return Boolean is
   begin
      return not Is_Accepted (Info.Status);
   end Has_Error;

   function Legal_Status
     (Construct : Tasking_AST_Construct_Kind) return Tasking_AST_Repair_Status is
   begin
      case Construct is
         when Tasking_AST_Task_Type => return Tasking_AST_Legal_Task_Type_Repaired;
         when Tasking_AST_Task_Body => return Tasking_AST_Legal_Task_Body_Repaired;
         when Tasking_AST_Protected_Type => return Tasking_AST_Legal_Protected_Type_Repaired;
         when Tasking_AST_Protected_Body => return Tasking_AST_Legal_Protected_Body_Repaired;
         when Tasking_AST_Entry_Declaration => return Tasking_AST_Legal_Entry_Declaration_Repaired;
         when Tasking_AST_Entry_Body => return Tasking_AST_Legal_Entry_Body_Repaired;
         when Tasking_AST_Accept_Statement => return Tasking_AST_Legal_Accept_Statement_Repaired;
         when Tasking_AST_Requeue_Statement => return Tasking_AST_Legal_Requeue_Statement_Repaired;
         when Tasking_AST_Select_Statement => return Tasking_AST_Legal_Select_Statement_Repaired;
         when Tasking_AST_Unknown => return Tasking_AST_Indeterminate;
      end case;
   end Legal_Status;

   function Needs_Contract_Metadata
     (Construct : Tasking_AST_Construct_Kind) return Boolean is
   begin
      return Construct in
        Tasking_AST_Entry_Body |
        Tasking_AST_Accept_Statement |
        Tasking_AST_Requeue_Statement |
        Tasking_AST_Select_Statement;
   end Needs_Contract_Metadata;

   function Needs_Representation_Metadata
     (Construct : Tasking_AST_Construct_Kind) return Boolean is
   begin
      return Construct in
        Tasking_AST_Task_Type |
        Tasking_AST_Protected_Type |
        Tasking_AST_Protected_Body;
   end Needs_Representation_Metadata;

   function Classify
     (Info : Tasking_AST_Repair_Context_Info) return Tasking_AST_Repair_Status is
      Missing_Core : Natural := 0;
   begin
      if Info.Construct = Tasking_AST_Unknown then
         return Tasking_AST_Indeterminate;
      end if;

      if not Info.Parser_Node_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Structural_AST_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Source_Span_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Flow_Metadata_Repaired then
         Missing_Core := Missing_Core + 1;
      end if;
      if not Info.Consumer_Integrated then
         Missing_Core := Missing_Core + 1;
      end if;
      if Needs_Contract_Metadata (Info.Construct)
        and then not Info.Contract_Metadata_Repaired
      then
         Missing_Core := Missing_Core + 1;
      end if;
      if Needs_Representation_Metadata (Info.Construct)
        and then not Info.Representation_Metadata_Repaired
      then
         Missing_Core := Missing_Core + 1;
      end if;

      if Missing_Core > 1 then
         return Tasking_AST_Multiple_Repair_Blockers;
      end if;

      if not Info.Parser_Node_Repaired then
         return Tasking_AST_Parser_Node_Still_Missing;
      elsif not Info.Structural_AST_Repaired then
         return Tasking_AST_Structural_AST_Still_Missing;
      elsif not Info.Source_Span_Repaired then
         return Tasking_AST_Source_Span_Still_Missing;
      elsif not Info.Token_Only_Replaced then
         return Tasking_AST_Token_Only_Parse_Still_Present;
      elsif not Info.Degradation_Replaced then
         return Tasking_AST_Degradation_Only_Path_Still_Present;
      elsif not Info.Flow_Metadata_Repaired then
         return Tasking_AST_Flow_Metadata_Still_Missing;
      elsif Needs_Contract_Metadata (Info.Construct)
        and then not Info.Contract_Metadata_Repaired
      then
         return Tasking_AST_Contract_Metadata_Still_Missing;
      elsif Needs_Representation_Metadata (Info.Construct)
        and then not Info.Representation_Metadata_Repaired
      then
         return Tasking_AST_Representation_Metadata_Still_Missing;
      elsif not Info.Cross_Unit_Metadata_Repaired then
         return Tasking_AST_Cross_Unit_Metadata_Still_Missing;
      elsif not Info.Consumer_Repaired then
         return Tasking_AST_Consumer_Still_Missing;
      elsif not Info.Consumer_Integrated then
         return Tasking_AST_Consumer_Still_Not_Integrated;
      else
         return Legal_Status (Info.Construct);
      end if;
   end Classify;

   function Message_For (Status : Tasking_AST_Repair_Status) return String is
   begin
      case Status is
         when Tasking_AST_Legal_Task_Type_Repaired => return "task type AST coverage repaired";
         when Tasking_AST_Legal_Task_Body_Repaired => return "task body AST coverage repaired";
         when Tasking_AST_Legal_Protected_Type_Repaired => return "protected type AST coverage repaired";
         when Tasking_AST_Legal_Protected_Body_Repaired => return "protected body AST coverage repaired";
         when Tasking_AST_Legal_Entry_Declaration_Repaired => return "entry declaration AST coverage repaired";
         when Tasking_AST_Legal_Entry_Body_Repaired => return "entry body AST coverage repaired";
         when Tasking_AST_Legal_Accept_Statement_Repaired => return "accept statement AST coverage repaired";
         when Tasking_AST_Legal_Requeue_Statement_Repaired => return "requeue statement AST coverage repaired";
         when Tasking_AST_Legal_Select_Statement_Repaired => return "select statement AST coverage repaired";
         when Tasking_AST_Parser_Node_Still_Missing => return "tasking parser node is still missing";
         when Tasking_AST_Structural_AST_Still_Missing => return "tasking structural AST shape is still missing";
         when Tasking_AST_Source_Span_Still_Missing => return "tasking source span is still missing";
         when Tasking_AST_Flow_Metadata_Still_Missing => return "tasking flow metadata is still missing";
         when Tasking_AST_Contract_Metadata_Still_Missing => return "tasking contract metadata is still missing";
         when Tasking_AST_Representation_Metadata_Still_Missing => return "tasking representation metadata is still missing";
         when Tasking_AST_Cross_Unit_Metadata_Still_Missing => return "tasking cross-unit metadata is still missing";
         when Tasking_AST_Consumer_Still_Missing => return "tasking semantic consumer is still missing";
         when Tasking_AST_Consumer_Still_Not_Integrated => return "tasking semantic consumer is still not integrated";
         when Tasking_AST_Token_Only_Parse_Still_Present => return "tasking token-only parse is still present";
         when Tasking_AST_Degradation_Only_Path_Still_Present => return "tasking graceful degradation path is still the only path";
         when Tasking_AST_Repair_Mismatch => return "tasking AST repair is mismatched";
         when Tasking_AST_Multiple_Repair_Blockers => return "tasking AST repair has multiple blockers";
         when Tasking_AST_Indeterminate => return "tasking AST repair is indeterminate";
         when Tasking_AST_Not_Checked => return "tasking AST repair not checked";
      end case;
   end Message_For;

   function Make_Row
     (Info : Tasking_AST_Repair_Context_Info) return Tasking_AST_Repair_Info is
      Status : constant Tasking_AST_Repair_Status := Classify (Info);
      Row    : Tasking_AST_Repair_Info;
      FP     : Natural := Info.Source_Fingerprint;
   begin
      FP := Mix (FP, Tasking_AST_Construct_Kind'Pos (Info.Construct));
      FP := Mix (FP, Tasking_AST_Repair_Status'Pos (Status));
      FP := Mix (FP, Audit.Semantic_Consumer_Family'Pos (Info.Consumer));
      FP := Mix (FP, Natural (Info.Node));
      FP := Mix (FP, Natural (Info.Id));

      Row.Id := Info.Id;
      Row.Construct := Info.Construct;
      Row.Audit_Construct := Info.Audit_Construct;
      Row.Consumer := Info.Consumer;
      Row.Node := Info.Node;
      Row.Parent_Node := Info.Parent_Node;
      Row.Status := Status;
      Row.Construct_Name := Info.Construct_Name;
      Row.Normalized_Construct_Name := Info.Normalized_Construct_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String
        ("construct=" & To_String (Info.Construct_Name) &
         "; normalized=" & To_String (Info.Normalized_Construct_Name));
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Fingerprint := FP;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Tasking_AST_Repair_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Tasking_AST_Repair_Context_Model;
      Context : Tasking_AST_Repair_Context_Info) is
      C : Tasking_AST_Repair_Context_Info := Context;
   begin
      if C.Id = No_Tasking_AST_Repair_Row then
         C.Id := Tasking_AST_Repair_Row_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      if C.Construct = Tasking_AST_Unknown then
         C.Construct := Map_Construct (C.Audit_Construct);
      end if;
      Model.Contexts.Append (C);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (C.Id));
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint, Tasking_AST_Construct_Kind'Pos (C.Construct));
   end Add_Context;

   procedure Apply_Repair_Row
     (Context : in out Tasking_AST_Repair_Context_Info;
      Row     : Repair.Repair_Info) is
   begin
      Context.Source_Fingerprint := Mix
        (Context.Source_Fingerprint, Row.Source_Fingerprint);

      case Row.Kind is
         when Repair.Repair_Parser_Node =>
            Context.Parser_Node_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Structural_AST =>
            Context.Structural_AST_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Source_Span =>
            Context.Source_Span_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Contract_Metadata =>
            Context.Contract_Metadata_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Flow_Metadata =>
            Context.Flow_Metadata_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Representation_Metadata =>
            Context.Representation_Metadata_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Cross_Unit_Metadata =>
            Context.Cross_Unit_Metadata_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Semantic_Consumer =>
            Context.Consumer_Repaired := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Consumer_Integration =>
            Context.Consumer_Integrated := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Token_Only_Replacement =>
            Context.Token_Only_Replaced := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Degradation_Replacement =>
            Context.Degradation_Replaced := Repair.Is_Repaired (Row.Status);
         when Repair.Repair_Combined_Construct_Coverage =>
            if Repair.Is_Repaired (Row.Status) then
               Context.Parser_Node_Repaired := True;
               Context.Structural_AST_Repaired := True;
               Context.Source_Span_Repaired := True;
               Context.Flow_Metadata_Repaired := True;
               Context.Contract_Metadata_Repaired := True;
               Context.Representation_Metadata_Repaired := True;
               Context.Cross_Unit_Metadata_Repaired := True;
               Context.Consumer_Repaired := True;
               Context.Consumer_Integrated := True;
               Context.Token_Only_Replaced := True;
               Context.Degradation_Replaced := True;
            end if;
         when others =>
            null;
      end case;
   end Apply_Repair_Row;

   function Build_From_Repairs
     (Repairs : Repair.Repair_Model) return Tasking_AST_Repair_Model is
      Contexts : Tasking_AST_Repair_Context_Model;
   begin
      for I in 1 .. Repair.Repair_Count (Repairs) loop
         declare
            Row : constant Repair.Repair_Info := Repair.Repair_At (Repairs, I);
         begin
            if Is_Tasking_Construct (Row.Construct) then
               declare
                  Found : Boolean := False;
               begin
                  for J in 1 .. Natural (Contexts.Contexts.Length) loop
                     declare
                        Existing : Tasking_AST_Repair_Context_Info :=
                          Contexts.Contexts.Element (J);
                     begin
                        if Existing.Node = Row.Node
                          and then Existing.Audit_Construct = Row.Construct
                        then
                           Apply_Repair_Row (Existing, Row);
                           Contexts.Contexts.Replace_Element (J, Existing);
                           Found := True;
                           exit;
                        end if;
                     end;
                  end loop;

                  if not Found then
                     declare
                        C : Tasking_AST_Repair_Context_Info;
                     begin
                        C.Id := Tasking_AST_Repair_Row_Id
                          (Natural (Contexts.Contexts.Length) + 1);
                        C.Construct := Map_Construct (Row.Construct);
                        C.Audit_Construct := Row.Construct;
                        C.Consumer := Row.Consumer;
                        C.Node := Row.Node;
                        C.Parent_Node := Row.Parent_Node;
                        C.Construct_Name := Row.Construct_Name;
                        C.Normalized_Construct_Name := Row.Normalized_Construct_Name;
                        C.Source_Fingerprint := Row.Source_Fingerprint;
                        C.Start_Line := Row.Start_Line;
                        C.Start_Column := Row.Start_Column;
                        C.End_Line := Row.End_Line;
                        C.End_Column := Row.End_Column;
                        Apply_Repair_Row (C, Row);
                        Add_Context (Contexts, C);
                     end;
                  end if;
               end;
            end if;
         end;
      end loop;
      return Build (Contexts);
   end Build_From_Repairs;

   function Build
     (Contexts : Tasking_AST_Repair_Context_Model)
      return Tasking_AST_Repair_Model is
      Model : Tasking_AST_Repair_Model;
   begin
      for C of Contexts.Contexts loop
         declare
            Row : constant Tasking_AST_Repair_Info := Make_Row (C);
         begin
            Model.Items.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
            if Is_Accepted (Row.Status) then
               Model.Accepted_Total := Model.Accepted_Total + 1;
            elsif Row.Status = Tasking_AST_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
               Model.Blocker_Total := Model.Blocker_Total + 1;
            else
               Model.Blocker_Total := Model.Blocker_Total + 1;
            end if;
         end;
      end loop;
      return Model;
   end Build;

   function Context_Count (Model : Tasking_AST_Repair_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Row_Count (Model : Tasking_AST_Repair_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Tasking_AST_Repair_Model;
      Index : Positive) return Tasking_AST_Repair_Info is
   begin
      if Index <= Natural (Model.Items.Length) then
         return Model.Items.Element (Index);
      end if;
      return (others => <>);
   end Row_At;

   function First_For_Node
     (Model : Tasking_AST_Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_AST_Repair_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Tasking_AST_Repair_Model;
      Status : Tasking_AST_Repair_Status) return Tasking_AST_Repair_Result_Set is
      Results : Tasking_AST_Repair_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Results.Items.Append (Row);
            Results.Result_Fingerprint := Mix
              (Results.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Construct
     (Model     : Tasking_AST_Repair_Model;
      Construct : Tasking_AST_Construct_Kind) return Tasking_AST_Repair_Result_Set is
      Results : Tasking_AST_Repair_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Construct = Construct then
            Results.Items.Append (Row);
            Results.Result_Fingerprint := Mix
              (Results.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Construct;

   function Result_Count (Results : Tasking_AST_Repair_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Tasking_AST_Repair_Result_Set;
      Index   : Positive) return Tasking_AST_Repair_Info is
   begin
      if Index <= Natural (Results.Items.Length) then
         return Results.Items.Element (Index);
      end if;
      return (others => <>);
   end Result_At;

   function Count_Status
     (Model : Tasking_AST_Repair_Model;
      Status : Tasking_AST_Repair_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Construct
     (Model : Tasking_AST_Repair_Model;
      Construct : Tasking_AST_Construct_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Construct = Construct then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Construct;

   function Accepted_Count (Model : Tasking_AST_Repair_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocker_Count (Model : Tasking_AST_Repair_Model) return Natural is
   begin
      return Model.Blocker_Total;
   end Blocker_Count;

   function Indeterminate_Count (Model : Tasking_AST_Repair_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Tasking_AST_Repair_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Tasking_Protected_AST_Repair_Legality;
