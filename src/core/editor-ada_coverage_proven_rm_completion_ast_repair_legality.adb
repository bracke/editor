with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Coverage_Proven_RM_Completion_AST_Repair_Legality is

   use type Closure.Generic_Shared_State_Final_Stabilized_Closure_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Gates.Gate_Action;
   use type Gates.Gate_Status;
   use type Overload_Edges.Overload_Generic_RM_Edge_Completion_Id;
   use type Representation_Hard_Cases.Representation_Generic_RM_Hard_Case_Id;
   use type Tasking_Hard_Cases.Tasking_Generic_RM_Hard_Case_Id;

   function Mix (A, B : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (A) * 16#45D9F3B#) xor
        (Hash_Value (B) + 16#9E3779B9#);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Gate_Proves_Repair_Need (C : Coverage_Proven_AST_Repair_Context) return Boolean is
   begin
      return C.Coverage_Gate_Action in Gates.Gate_Require_Parser_AST_Repair | Gates.Gate_Require_Metadata_Repair | Gates.Gate_Require_Consumer_Integration
        or else C.Coverage_Gate_Status in Gates.Gate_Parser_Node_Missing | Gates.Gate_Token_Only_Parse | Gates.Gate_AST_Shape_Missing | Gates.Gate_Source_Span_Missing | Gates.Gate_Name_Binding_Missing | Gates.Gate_Type_Metadata_Missing | Gates.Gate_Staticness_Metadata_Missing | Gates.Gate_Contract_Metadata_Missing | Gates.Gate_Flow_Metadata_Missing | Gates.Gate_Representation_Metadata_Missing | Gates.Gate_Cross_Unit_Metadata_Missing | Gates.Gate_Consumer_Missing | Gates.Gate_Consumer_Not_Integrated;
   end Gate_Proves_Repair_Need;

   function Closure_Accepted (Status : Closure.Generic_Shared_State_Final_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current | Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Is_Repaired (Status : Coverage_Proven_AST_Repair_Status) return Boolean is
   begin
      return Status in Coverage_Proven_AST_Repair_Parser_Node_Repaired | Coverage_Proven_AST_Repair_Structural_AST_Repaired | Coverage_Proven_AST_Repair_Token_Only_Parse_Repaired | Coverage_Proven_AST_Repair_Source_Span_Repaired | Coverage_Proven_AST_Repair_Metadata_Repaired | Coverage_Proven_AST_Repair_Consumer_Integration_Repaired;
   end Is_Repaired;

   function Is_Blocked (Status : Coverage_Proven_AST_Repair_Status) return Boolean is
   begin
      return Status not in Coverage_Proven_AST_Repair_Not_Checked | Coverage_Proven_AST_Repair_Not_Required | Coverage_Proven_AST_Repair_Parser_Node_Repaired | Coverage_Proven_AST_Repair_Structural_AST_Repaired | Coverage_Proven_AST_Repair_Token_Only_Parse_Repaired | Coverage_Proven_AST_Repair_Source_Span_Repaired | Coverage_Proven_AST_Repair_Metadata_Repaired | Coverage_Proven_AST_Repair_Consumer_Integration_Repaired | Coverage_Proven_AST_Repair_Indeterminate;
   end Is_Blocked;

   function Is_Indeterminate (Status : Coverage_Proven_AST_Repair_Status) return Boolean is
   begin
      return Status = Coverage_Proven_AST_Repair_Indeterminate;
   end Is_Indeterminate;

   function Accepted_For (Kind : Coverage_Proven_AST_Repair_Kind) return Coverage_Proven_AST_Repair_Status is
   begin
      case Kind is
         when Coverage_Proven_AST_Repair_Parser_Node => return Coverage_Proven_AST_Repair_Parser_Node_Repaired;
         when Coverage_Proven_AST_Repair_Structural_AST => return Coverage_Proven_AST_Repair_Structural_AST_Repaired;
         when Coverage_Proven_AST_Repair_Token_Only_Parse => return Coverage_Proven_AST_Repair_Token_Only_Parse_Repaired;
         when Coverage_Proven_AST_Repair_Source_Span => return Coverage_Proven_AST_Repair_Source_Span_Repaired;
         when Coverage_Proven_AST_Repair_Metadata => return Coverage_Proven_AST_Repair_Metadata_Repaired;
         when Coverage_Proven_AST_Repair_Consumer_Integration => return Coverage_Proven_AST_Repair_Consumer_Integration_Repaired;
         when others => return Coverage_Proven_AST_Repair_Indeterminate;
      end case;
   end Accepted_For;

   function Local_Blocker_Count (C : Coverage_Proven_AST_Repair_Context) return Natural is
      N : Natural := 0;
   begin
      if not C.Has_Coverage_Gate then N := N + 1; end if;
      if C.Has_Coverage_Gate and then not Gate_Proves_Repair_Need (C) and then C.Coverage_Gate_Status /= Gates.Gate_Open then N := N + 1; end if;
      if C.Requires_Stabilized_Closure and then (C.Stabilized_Closure_Row = Closure.No_Generic_Shared_State_Final_Stabilized_Closure or else not Closure_Accepted (C.Stabilized_Closure_Status)) then N := N + 1; end if;
      if C.Requires_Overload_RM_Edge and then (C.Overload_RM_Edge_Row = Overload_Edges.No_Overload_Generic_RM_Edge_Completion or else not Overload_Edges.Is_Accepted (C.Overload_RM_Edge_Status)) then N := N + 1; end if;
      if C.Requires_Representation_RM_Hard_Case and then (C.Representation_RM_Hard_Case_Row = Representation_Hard_Cases.No_Representation_Generic_RM_Hard_Case or else not Representation_Hard_Cases.Is_Accepted (C.Representation_RM_Hard_Case_Status)) then N := N + 1; end if;
      if C.Requires_Tasking_RM_Hard_Case and then (C.Tasking_RM_Hard_Case_Row = Tasking_Hard_Cases.No_Tasking_Generic_RM_Hard_Case or else not Tasking_Hard_Cases.Is_Accepted (C.Tasking_RM_Hard_Case_Status)) then N := N + 1; end if;
      if C.Parser_Node_Still_Missing then N := N + 1; end if;
      if C.Structural_AST_Still_Missing then N := N + 1; end if;
      if C.Token_Only_Parse_Still_Present then N := N + 1; end if;
      if C.Source_Span_Still_Missing then N := N + 1; end if;
      if C.Metadata_Still_Missing then N := N + 1; end if;
      if C.Consumer_Still_Not_Integrated then N := N + 1; end if;
      if C.Expected_Source_Fingerprint /= 0 and then C.Source_Fingerprint /= C.Expected_Source_Fingerprint then N := N + 1; end if;
      return N;
   end Local_Blocker_Count;

   function Family_For (Status : Coverage_Proven_AST_Repair_Status) return Coverage_Proven_AST_Repair_Blocker_Family is
   begin
      case Status is
         when Coverage_Proven_AST_Repair_Missing_Coverage_Gate => return Coverage_Proven_AST_Repair_Blocker_No_Coverage_Gate;
         when Coverage_Proven_AST_Repair_Gate_Does_Not_Prove_Repair_Need => return Coverage_Proven_AST_Repair_Blocker_Gate_Not_Repairable;
         when Coverage_Proven_AST_Repair_Stabilized_Closure_Blocker => return Coverage_Proven_AST_Repair_Blocker_Stabilized_Closure;
         when Coverage_Proven_AST_Repair_Overload_RM_Edge_Blocker => return Coverage_Proven_AST_Repair_Blocker_Overload_RM_Edge;
         when Coverage_Proven_AST_Repair_Representation_RM_Hard_Case_Blocker => return Coverage_Proven_AST_Repair_Blocker_Representation_RM_Hard_Case;
         when Coverage_Proven_AST_Repair_Tasking_RM_Hard_Case_Blocker => return Coverage_Proven_AST_Repair_Blocker_Tasking_RM_Hard_Case;
         when Coverage_Proven_AST_Repair_Parser_Node_Still_Missing => return Coverage_Proven_AST_Repair_Blocker_Parser_Node;
         when Coverage_Proven_AST_Repair_Structural_AST_Still_Missing => return Coverage_Proven_AST_Repair_Blocker_Structural_AST;
         when Coverage_Proven_AST_Repair_Token_Only_Parse_Still_Present => return Coverage_Proven_AST_Repair_Blocker_Token_Only_Parse;
         when Coverage_Proven_AST_Repair_Source_Span_Still_Missing => return Coverage_Proven_AST_Repair_Blocker_Source_Span;
         when Coverage_Proven_AST_Repair_Metadata_Still_Missing => return Coverage_Proven_AST_Repair_Blocker_Metadata;
         when Coverage_Proven_AST_Repair_Consumer_Still_Not_Integrated => return Coverage_Proven_AST_Repair_Blocker_Consumer_Integration;
         when Coverage_Proven_AST_Repair_Source_Fingerprint_Mismatch => return Coverage_Proven_AST_Repair_Blocker_Source_Fingerprint;
         when Coverage_Proven_AST_Repair_Multiple_Blockers => return Coverage_Proven_AST_Repair_Blocker_Multiple;
         when Coverage_Proven_AST_Repair_Indeterminate => return Coverage_Proven_AST_Repair_Blocker_Indeterminate;
         when others => return Coverage_Proven_AST_Repair_Blocker_None;
      end case;
   end Family_For;

   function Classify (C : Coverage_Proven_AST_Repair_Context) return Coverage_Proven_AST_Repair_Status is
      Blockers : constant Natural := Local_Blocker_Count (C);
   begin
      if Blockers > 1 then return Coverage_Proven_AST_Repair_Multiple_Blockers;
      elsif not C.Has_Coverage_Gate then return Coverage_Proven_AST_Repair_Missing_Coverage_Gate;
      elsif C.Coverage_Gate_Status = Gates.Gate_Open then return Coverage_Proven_AST_Repair_Not_Required;
      elsif not Gate_Proves_Repair_Need (C) then return Coverage_Proven_AST_Repair_Gate_Does_Not_Prove_Repair_Need;
      elsif C.Expected_Source_Fingerprint /= 0 and then C.Source_Fingerprint /= C.Expected_Source_Fingerprint then return Coverage_Proven_AST_Repair_Source_Fingerprint_Mismatch;
      elsif C.Parser_Node_Still_Missing then return Coverage_Proven_AST_Repair_Parser_Node_Still_Missing;
      elsif C.Structural_AST_Still_Missing then return Coverage_Proven_AST_Repair_Structural_AST_Still_Missing;
      elsif C.Token_Only_Parse_Still_Present then return Coverage_Proven_AST_Repair_Token_Only_Parse_Still_Present;
      elsif C.Source_Span_Still_Missing then return Coverage_Proven_AST_Repair_Source_Span_Still_Missing;
      elsif C.Metadata_Still_Missing then return Coverage_Proven_AST_Repair_Metadata_Still_Missing;
      elsif C.Consumer_Still_Not_Integrated then return Coverage_Proven_AST_Repair_Consumer_Still_Not_Integrated;
      elsif C.Requires_Stabilized_Closure and then (C.Stabilized_Closure_Row = Closure.No_Generic_Shared_State_Final_Stabilized_Closure or else not Closure_Accepted (C.Stabilized_Closure_Status)) then return Coverage_Proven_AST_Repair_Stabilized_Closure_Blocker;
      elsif C.Requires_Overload_RM_Edge and then (C.Overload_RM_Edge_Row = Overload_Edges.No_Overload_Generic_RM_Edge_Completion or else not Overload_Edges.Is_Accepted (C.Overload_RM_Edge_Status)) then return Coverage_Proven_AST_Repair_Overload_RM_Edge_Blocker;
      elsif C.Requires_Representation_RM_Hard_Case and then (C.Representation_RM_Hard_Case_Row = Representation_Hard_Cases.No_Representation_Generic_RM_Hard_Case or else not Representation_Hard_Cases.Is_Accepted (C.Representation_RM_Hard_Case_Status)) then return Coverage_Proven_AST_Repair_Representation_RM_Hard_Case_Blocker;
      elsif C.Requires_Tasking_RM_Hard_Case and then (C.Tasking_RM_Hard_Case_Row = Tasking_Hard_Cases.No_Tasking_Generic_RM_Hard_Case or else not Tasking_Hard_Cases.Is_Accepted (C.Tasking_RM_Hard_Case_Status)) then return Coverage_Proven_AST_Repair_Tasking_RM_Hard_Case_Blocker;
      else return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For (Status : Coverage_Proven_AST_Repair_Status; Kind : Coverage_Proven_AST_Repair_Kind; Family : Coverage_Proven_AST_Repair_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String ("coverage-proven RM-completion AST repair legality " & Coverage_Proven_AST_Repair_Status'Image (Status) & " kind=" & Coverage_Proven_AST_Repair_Kind'Image (Kind) & " blocker=" & Coverage_Proven_AST_Repair_Blocker_Family'Image (Family));
   end Message_For;

   function Compute_Row_Fingerprint (Row : Coverage_Proven_AST_Repair_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context)); H := Mix (H, Coverage_Proven_AST_Repair_Kind'Pos (Row.Kind) + 1); H := Mix (H, Coverage_Proven_AST_Repair_Status'Pos (Row.Status) + 1); H := Mix (H, Coverage_Proven_AST_Repair_Blocker_Family'Pos (Row.Blocker_Family) + 1); H := Mix (H, Natural (Row.Node)); H := Mix (H, Row.Blocker_Count); H := Mix (H, Row.Source_Fingerprint);
      for C of Text loop H := Mix (H, Character'Pos (C)); end loop;
      return H;
   end Compute_Row_Fingerprint;

   function Make_Row (C : Coverage_Proven_AST_Repair_Context; Index : Positive) return Coverage_Proven_AST_Repair_Row is
      Status : constant Coverage_Proven_AST_Repair_Status := Classify (C);
      Family : constant Coverage_Proven_AST_Repair_Blocker_Family := Family_For (Status);
      Row : Coverage_Proven_AST_Repair_Row;
   begin
      Row.Id := Coverage_Proven_AST_Repair_Id (Index); Row.Context := C.Id; Row.Kind := C.Kind; Row.Status := Status; Row.Blocker_Family := Family; Row.Node := C.Node; Row.Construct_Name := C.Construct_Name; Row.Generic_Unit_Name := C.Generic_Unit_Name; Row.Instance_Name := C.Instance_Name; Row.Repaired := Is_Repaired (Status); Row.Not_Required := Status = Coverage_Proven_AST_Repair_Not_Required; Row.Blocked := Is_Blocked (Status); Row.Blocks_Downstream := Row.Blocked or else Is_Indeterminate (Status); Row.Blocker_Count := Local_Blocker_Count (C); if Row.Blocked and then Row.Blocker_Count = 0 then Row.Blocker_Count := 1; end if; Row.Source_Fingerprint := C.Source_Fingerprint; Row.Start_Line := C.Start_Line; Row.Start_Column := C.Start_Column; Row.End_Line := C.End_Line; Row.End_Column := C.End_Column; Row.Message := Message_For (Status, C.Kind, Family); Row.Row_Fingerprint := Compute_Row_Fingerprint (Row); return Row;
   end Make_Row;

   procedure Clear (Model : in out Coverage_Proven_AST_Repair_Context_Model) is begin Model.Items.Clear; Model.Fingerprint := 0; end Clear;
   procedure Add_Context (Model : in out Coverage_Proven_AST_Repair_Context_Model; Context : Coverage_Proven_AST_Repair_Context) is H : Natural := Model.Fingerprint; begin Model.Items.Append (Context); H := Mix (H, Natural (Context.Id)); H := Mix (H, Coverage_Proven_AST_Repair_Kind'Pos (Context.Kind) + 1); H := Mix (H, Natural (Context.Node)); H := Mix (H, Gates.Gate_Status'Pos (Context.Coverage_Gate_Status) + 1); H := Mix (H, Gates.Gate_Action'Pos (Context.Coverage_Gate_Action) + 1); H := Mix (H, Context.Source_Fingerprint); Model.Fingerprint := H; end Add_Context;
   function Context_Count (Model : Coverage_Proven_AST_Repair_Context_Model) return Natural is begin return Natural (Model.Items.Length); end Context_Count;
   function Context_At (Model : Coverage_Proven_AST_Repair_Context_Model; Index : Positive) return Coverage_Proven_AST_Repair_Context is begin return Model.Items.Element (Index); end Context_At;
   function Context_Fingerprint (Model : Coverage_Proven_AST_Repair_Context_Model) return Natural is begin return Model.Fingerprint; end Context_Fingerprint;

   function Build (Contexts : Coverage_Proven_AST_Repair_Context_Model) return Coverage_Proven_AST_Repair_Model is
      Result : Coverage_Proven_AST_Repair_Model; H : Natural := Contexts.Fingerprint; I : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare Row : constant Coverage_Proven_AST_Repair_Row := Make_Row (C, I); begin Result.Rows.Append (Row); H := Mix (H, Row.Row_Fingerprint); end;
         I := I + 1;
      end loop;
      Result.Fingerprint := H; return Result;
   end Build;
   function Count (Model : Coverage_Proven_AST_Repair_Model) return Natural is begin return Natural (Model.Rows.Length); end Count;
   function Row_At (Model : Coverage_Proven_AST_Repair_Model; Index : Positive) return Coverage_Proven_AST_Repair_Row is begin return Model.Rows.Element (Index); end Row_At;
   function Query_Count (Set : Coverage_Proven_AST_Repair_Set) return Natural is begin return Natural (Set.Rows.Length); end Query_Count;
   function Query_At (Set : Coverage_Proven_AST_Repair_Set; Index : Positive) return Coverage_Proven_AST_Repair_Row is begin return Set.Rows.Element (Index); end Query_At;
   function Query_Status (Model : Coverage_Proven_AST_Repair_Model; Status : Coverage_Proven_AST_Repair_Status) return Coverage_Proven_AST_Repair_Set is Result : Coverage_Proven_AST_Repair_Set; begin for Row of Model.Rows loop if Row.Status = Status then Result.Rows.Append (Row); end if; end loop; return Result; end Query_Status;
   function Query_Blocker_Family (Model : Coverage_Proven_AST_Repair_Model; Family : Coverage_Proven_AST_Repair_Blocker_Family) return Coverage_Proven_AST_Repair_Set is Result : Coverage_Proven_AST_Repair_Set; begin for Row of Model.Rows loop if Row.Blocker_Family = Family then Result.Rows.Append (Row); end if; end loop; return Result; end Query_Blocker_Family;
   function Find_By_Node (Model : Coverage_Proven_AST_Repair_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Coverage_Proven_AST_Repair_Set is Result : Coverage_Proven_AST_Repair_Set; begin for Row of Model.Rows loop if Row.Node = Node then Result.Rows.Append (Row); end if; end loop; return Result; end Find_By_Node;
   function Find_By_Source_Fingerprint (Model : Coverage_Proven_AST_Repair_Model; Source_Fingerprint : Natural) return Coverage_Proven_AST_Repair_Set is Result : Coverage_Proven_AST_Repair_Set; begin for Row of Model.Rows loop if Row.Source_Fingerprint = Source_Fingerprint then Result.Rows.Append (Row); end if; end loop; return Result; end Find_By_Source_Fingerprint;
   function Count_By_Status (Model : Coverage_Proven_AST_Repair_Model; Status : Coverage_Proven_AST_Repair_Status) return Natural is begin return Query_Count (Query_Status (Model, Status)); end Count_By_Status;
   function Count_By_Blocker_Family (Model : Coverage_Proven_AST_Repair_Model; Family : Coverage_Proven_AST_Repair_Blocker_Family) return Natural is begin return Query_Count (Query_Blocker_Family (Model, Family)); end Count_By_Blocker_Family;
   function Repaired_Count (Model : Coverage_Proven_AST_Repair_Model) return Natural is N : Natural := 0; begin for Row of Model.Rows loop if Row.Repaired then N := N + 1; end if; end loop; return N; end Repaired_Count;
   function Not_Required_Count (Model : Coverage_Proven_AST_Repair_Model) return Natural is N : Natural := 0; begin for Row of Model.Rows loop if Row.Not_Required then N := N + 1; end if; end loop; return N; end Not_Required_Count;
   function Withheld_Count (Model : Coverage_Proven_AST_Repair_Model) return Natural is N : Natural := 0; begin for Row of Model.Rows loop if Row.Blocked then N := N + 1; end if; end loop; return N; end Withheld_Count;
   function Indeterminate_Count (Model : Coverage_Proven_AST_Repair_Model) return Natural is N : Natural := 0; begin for Row of Model.Rows loop if Is_Indeterminate (Row.Status) then N := N + 1; end if; end loop; return N; end Indeterminate_Count;
   function Stable_Fingerprint (Model : Coverage_Proven_AST_Repair_Model) return Natural is begin return Model.Fingerprint; end Stable_Fingerprint;

end Editor.Ada_Coverage_Proven_RM_Completion_AST_Repair_Legality;
