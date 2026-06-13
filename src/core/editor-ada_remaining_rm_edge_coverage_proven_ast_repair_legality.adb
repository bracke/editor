with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Search_Status;
   use type Search_Blocker;
   use type Remaining_RM_Edge_Kind;
   use type Remaining_RM_Edge_Blocker_Family;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 271) + B + 1295) mod 2_147_483_647;
   end Mix;

   function Is_Search_Blocking (Feed_Item : Search_Entry) return Boolean is
   begin
      return Feed_Item.Blocks_Downstream
        or else Feed_Item.Emitted
        or else Feed_Item.Requires_Recheck
        or else Feed_Item.Status in
          Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Error |
          Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Warning |
          Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Recheck_Required |
          Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Indeterminate |
          Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Multiple_Prerequisites;
   end Is_Search_Blocking;

   function Has_Remaining_Edge_Blocker (Feed_Item : Search_Entry) return Boolean is
   begin
      return Feed_Item.Blocker = Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Blocker_Remaining_Edge
        or else Feed_Item.Remaining_Edge_Blocker /= Search.Prov.Edge.Remaining_RM_Edge_Blocker_None;
   end Has_Remaining_Edge_Blocker;

   function Local_AST_Gap_Count (C : Remaining_RM_Edge_AST_Repair_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Parser_Node_Still_Missing then Count := Count + 1; end if;
      if C.Structural_AST_Still_Missing then Count := Count + 1; end if;
      if C.Token_Only_Parse_Still_Present then Count := Count + 1; end if;
      if C.Source_Span_Still_Missing then Count := Count + 1; end if;
      if C.Metadata_Still_Missing then Count := Count + 1; end if;
      if C.Consumer_Still_Not_Integrated then Count := Count + 1; end if;
      return Count;
   end Local_AST_Gap_Count;

   function Accepted_For
     (Kind : Remaining_RM_Edge_AST_Repair_Kind) return Remaining_RM_Edge_AST_Repair_Status is
   begin
      case Kind is
         when Remaining_RM_Edge_AST_Repair_Parser_Node =>
            return Remaining_RM_Edge_AST_Repair_Parser_Node_Repaired;
         when Remaining_RM_Edge_AST_Repair_Structural_AST =>
            return Remaining_RM_Edge_AST_Repair_Structural_AST_Repaired;
         when Remaining_RM_Edge_AST_Repair_Token_Only_Parse =>
            return Remaining_RM_Edge_AST_Repair_Token_Only_Parse_Repaired;
         when Remaining_RM_Edge_AST_Repair_Source_Span =>
            return Remaining_RM_Edge_AST_Repair_Source_Span_Repaired;
         when Remaining_RM_Edge_AST_Repair_Metadata =>
            return Remaining_RM_Edge_AST_Repair_Metadata_Repaired;
         when Remaining_RM_Edge_AST_Repair_Consumer_Integration =>
            return Remaining_RM_Edge_AST_Repair_Consumer_Integration_Repaired;
         when Remaining_RM_Edge_AST_Repair_Unknown =>
            return Remaining_RM_Edge_AST_Repair_Not_Required;
      end case;
   end Accepted_For;

   function Classify
     (C : Remaining_RM_Edge_AST_Repair_Context) return Remaining_RM_Edge_AST_Repair_Status is
   begin
      if C.Kind = Remaining_RM_Edge_AST_Repair_Unknown then
         return Remaining_RM_Edge_AST_Repair_Not_Required;
      elsif not C.Has_Stabilized_Search_Evidence then
         return Remaining_RM_Edge_AST_Repair_Missing_Stabilized_Search_Evidence;
      elsif not Is_Search_Blocking (C.Stabilized_Search_Entry) then
         return Remaining_RM_Edge_AST_Repair_Search_Evidence_Not_Blocking;
      elsif C.Requires_Remaining_Edge_Blocker and then not Has_Remaining_Edge_Blocker (C.Stabilized_Search_Entry) then
         return Remaining_RM_Edge_AST_Repair_Search_Evidence_Not_Remaining_Edge;
      elsif not C.Coverage_Proves_Repair_Need then
         return Remaining_RM_Edge_AST_Repair_No_Coverage_Proof;
      elsif C.Expected_Source_Fingerprint /= 0 and then C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Remaining_RM_Edge_AST_Repair_Source_Fingerprint_Mismatch;
      elsif C.Expected_Substitution_Fingerprint /= 0 and then C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Remaining_RM_Edge_AST_Repair_Substitution_Fingerprint_Mismatch;
      elsif C.Parser_Node_Still_Missing then
         return Remaining_RM_Edge_AST_Repair_Parser_Node_Still_Missing;
      elsif C.Structural_AST_Still_Missing then
         return Remaining_RM_Edge_AST_Repair_Structural_AST_Still_Missing;
      elsif C.Token_Only_Parse_Still_Present then
         return Remaining_RM_Edge_AST_Repair_Token_Only_Parse_Still_Present;
      elsif C.Source_Span_Still_Missing then
         return Remaining_RM_Edge_AST_Repair_Source_Span_Still_Missing;
      elsif C.Metadata_Still_Missing then
         return Remaining_RM_Edge_AST_Repair_Metadata_Still_Missing;
      elsif C.Consumer_Still_Not_Integrated then
         return Remaining_RM_Edge_AST_Repair_Consumer_Still_Not_Integrated;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Is_Repaired (Status : Remaining_RM_Edge_AST_Repair_Status) return Boolean is
   begin
      return Status in
        Remaining_RM_Edge_AST_Repair_Parser_Node_Repaired |
        Remaining_RM_Edge_AST_Repair_Structural_AST_Repaired |
        Remaining_RM_Edge_AST_Repair_Token_Only_Parse_Repaired |
        Remaining_RM_Edge_AST_Repair_Source_Span_Repaired |
        Remaining_RM_Edge_AST_Repair_Metadata_Repaired |
        Remaining_RM_Edge_AST_Repair_Consumer_Integration_Repaired;
   end Is_Repaired;

   function Is_Blocked (Status : Remaining_RM_Edge_AST_Repair_Status) return Boolean is
   begin
      return Status not in
        Remaining_RM_Edge_AST_Repair_Not_Checked |
        Remaining_RM_Edge_AST_Repair_Not_Required |
        Remaining_RM_Edge_AST_Repair_Parser_Node_Repaired |
        Remaining_RM_Edge_AST_Repair_Structural_AST_Repaired |
        Remaining_RM_Edge_AST_Repair_Token_Only_Parse_Repaired |
        Remaining_RM_Edge_AST_Repair_Source_Span_Repaired |
        Remaining_RM_Edge_AST_Repair_Metadata_Repaired |
        Remaining_RM_Edge_AST_Repair_Consumer_Integration_Repaired;
   end Is_Blocked;

   function Family_For
     (Status : Remaining_RM_Edge_AST_Repair_Status) return Remaining_RM_Edge_AST_Repair_Blocker_Family is
   begin
      case Status is
         when Remaining_RM_Edge_AST_Repair_Not_Checked |
              Remaining_RM_Edge_AST_Repair_Not_Required |
              Remaining_RM_Edge_AST_Repair_Parser_Node_Repaired |
              Remaining_RM_Edge_AST_Repair_Structural_AST_Repaired |
              Remaining_RM_Edge_AST_Repair_Token_Only_Parse_Repaired |
              Remaining_RM_Edge_AST_Repair_Source_Span_Repaired |
              Remaining_RM_Edge_AST_Repair_Metadata_Repaired |
              Remaining_RM_Edge_AST_Repair_Consumer_Integration_Repaired =>
            return Remaining_RM_Edge_AST_Repair_Blocker_None;
         when Remaining_RM_Edge_AST_Repair_Missing_Stabilized_Search_Evidence =>
            return Remaining_RM_Edge_AST_Repair_Blocker_No_Stabilized_Search_Evidence;
         when Remaining_RM_Edge_AST_Repair_Search_Evidence_Not_Blocking =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Search_Evidence_Not_Blocking;
         when Remaining_RM_Edge_AST_Repair_Search_Evidence_Not_Remaining_Edge =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Search_Evidence_Not_Remaining_Edge;
         when Remaining_RM_Edge_AST_Repair_No_Coverage_Proof =>
            return Remaining_RM_Edge_AST_Repair_Blocker_No_Coverage_Proof;
         when Remaining_RM_Edge_AST_Repair_No_AST_Gap =>
            return Remaining_RM_Edge_AST_Repair_Blocker_No_AST_Gap;
         when Remaining_RM_Edge_AST_Repair_Parser_Node_Still_Missing =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Parser_Node;
         when Remaining_RM_Edge_AST_Repair_Structural_AST_Still_Missing =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Structural_AST;
         when Remaining_RM_Edge_AST_Repair_Token_Only_Parse_Still_Present =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Token_Only_Parse;
         when Remaining_RM_Edge_AST_Repair_Source_Span_Still_Missing =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Source_Span;
         when Remaining_RM_Edge_AST_Repair_Metadata_Still_Missing =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Metadata;
         when Remaining_RM_Edge_AST_Repair_Consumer_Still_Not_Integrated =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Consumer_Integration;
         when Remaining_RM_Edge_AST_Repair_Source_Fingerprint_Mismatch =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Source_Fingerprint;
         when Remaining_RM_Edge_AST_Repair_Substitution_Fingerprint_Mismatch =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Substitution_Fingerprint;
         when Remaining_RM_Edge_AST_Repair_Multiple_Blockers =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Multiple;
         when Remaining_RM_Edge_AST_Repair_Indeterminate =>
            return Remaining_RM_Edge_AST_Repair_Blocker_Indeterminate;
      end case;
   end Family_For;

   function Message_For
     (Status : Remaining_RM_Edge_AST_Repair_Status;
      Kind   : Remaining_RM_Edge_AST_Repair_Kind;
      Family : Remaining_RM_Edge_AST_Repair_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("coverage-proven remaining RM edge AST repair " &
         Remaining_RM_Edge_AST_Repair_Status'Image (Status) &
         " kind=" & Remaining_RM_Edge_AST_Repair_Kind'Image (Kind) &
         " blocker=" & Remaining_RM_Edge_AST_Repair_Blocker_Family'Image (Family));
   end Message_For;

   function Compute_Row_Fingerprint (Row : Remaining_RM_Edge_AST_Repair_Row) return Natural is
      H : Natural := Natural (Row.Id);
      Text : constant String := To_String (Row.Message);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Remaining_RM_Edge_AST_Repair_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Remaining_RM_Edge_AST_Repair_Status'Pos (Row.Status) + 1);
      H := Mix (H, Remaining_RM_Edge_AST_Repair_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Remaining_RM_Edge_Kind'Pos (Row.Remaining_Edge_Kind) + 1);
      H := Mix (H, Remaining_RM_Edge_Blocker_Family'Pos (Row.Remaining_Edge_Blocker) + 1);
      H := Mix (H, Search_Status'Pos (Row.Search_Status_Value) + 1);
      H := Mix (H, Search_Blocker'Pos (Row.Search_Blocker_Value) + 1);
      H := Mix (H, Natural (Row.Node) + 1);
      H := Mix (H, Row.Source_Fingerprint + 1);
      H := Mix (H, Row.Substitution_Fingerprint + 1);
      H := Mix (H, Row.Search_Fingerprint + 1);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Compute_Row_Fingerprint;

   function Make_Row
     (C     : Remaining_RM_Edge_AST_Repair_Context;
      Index : Positive) return Remaining_RM_Edge_AST_Repair_Row is
      Status : constant Remaining_RM_Edge_AST_Repair_Status := Classify (C);
      Family : constant Remaining_RM_Edge_AST_Repair_Blocker_Family := Family_For (Status);
      Row    : Remaining_RM_Edge_AST_Repair_Row;
   begin
      Row.Id := Remaining_RM_Edge_AST_Repair_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Construct_Name := C.Construct_Name;
      Row.Repaired := Is_Repaired (Status);
      Row.Not_Required := Status = Remaining_RM_Edge_AST_Repair_Not_Required;
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Row.Blocked;
      Row.Coverage_Proven := C.Coverage_Proves_Repair_Need;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Substitution_Fingerprint := C.Substitution_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      if C.Has_Stabilized_Search_Evidence then
         Row.Remaining_Edge_Kind := C.Stabilized_Search_Entry.Remaining_Edge_Kind;
         Row.Remaining_Edge_Blocker := C.Stabilized_Search_Entry.Remaining_Edge_Blocker;
         Row.Search_Status_Value := C.Stabilized_Search_Entry.Status;
         Row.Search_Blocker_Value := C.Stabilized_Search_Entry.Blocker;
         Row.Search_Fingerprint := C.Stabilized_Search_Entry.Fingerprint;
      end if;
      Row.Message := Message_For (Status, C.Kind, Family);
      Row.Row_Fingerprint := Compute_Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Remaining_RM_Edge_AST_Repair_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Remaining_RM_Edge_AST_Repair_Context_Model;
      Context : Remaining_RM_Edge_AST_Repair_Context) is
      H : Natural := Model.Fingerprint;
   begin
      Model.Items.Append (Context);
      H := Mix (H, Natural (Context.Id) + 1);
      H := Mix (H, Remaining_RM_Edge_AST_Repair_Kind'Pos (Context.Kind) + 1);
      H := Mix (H, Natural (Context.Node) + 1);
      H := Mix (H, Context.Source_Fingerprint + 1);
      H := Mix (H, Context.Substitution_Fingerprint + 1);
      if Context.Has_Stabilized_Search_Evidence then
         H := Mix (H, Context.Stabilized_Search_Entry.Fingerprint + 1);
      end if;
      Model.Fingerprint := H;
   end Add_Context;

   function Context_Count (Model : Remaining_RM_Edge_AST_Repair_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Remaining_RM_Edge_AST_Repair_Context_Model;
      Index : Positive) return Remaining_RM_Edge_AST_Repair_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Context_Fingerprint (Model : Remaining_RM_Edge_AST_Repair_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Context_Fingerprint;

   function Build
     (Contexts : Remaining_RM_Edge_AST_Repair_Context_Model)
      return Remaining_RM_Edge_AST_Repair_Model is
      Result : Remaining_RM_Edge_AST_Repair_Model;
      H      : Natural := Contexts.Fingerprint;
      I      : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Remaining_RM_Edge_AST_Repair_Row := Make_Row (C, I);
         begin
            Result.Rows.Append (Row);
            H := Mix (H, Row.Row_Fingerprint + 1);
         end;
         I := I + 1;
      end loop;
      Result.Fingerprint := H;
      return Result;
   end Build;

   function Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Remaining_RM_Edge_AST_Repair_Model;
      Index : Positive) return Remaining_RM_Edge_AST_Repair_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Remaining_RM_Edge_AST_Repair_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Remaining_RM_Edge_AST_Repair_Set;
      Index : Positive) return Remaining_RM_Edge_AST_Repair_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Remaining_RM_Edge_AST_Repair_Set;
      Row : Remaining_RM_Edge_AST_Repair_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Row_Fingerprint + 1);
   end Append_Query;

   function Query_Status
     (Model  : Remaining_RM_Edge_AST_Repair_Model;
      Status : Remaining_RM_Edge_AST_Repair_Status)
      return Remaining_RM_Edge_AST_Repair_Set is
      Result : Remaining_RM_Edge_AST_Repair_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Remaining_RM_Edge_AST_Repair_Model;
      Family : Remaining_RM_Edge_AST_Repair_Blocker_Family)
      return Remaining_RM_Edge_AST_Repair_Set is
      Result : Remaining_RM_Edge_AST_Repair_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Query_Remaining_Edge_Kind
     (Model : Remaining_RM_Edge_AST_Repair_Model;
      Kind  : Remaining_RM_Edge_Kind)
      return Remaining_RM_Edge_AST_Repair_Set is
      Result : Remaining_RM_Edge_AST_Repair_Set;
   begin
      for Row of Model.Rows loop
         if Row.Remaining_Edge_Kind = Kind then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Remaining_Edge_Kind;

   function Query_Node
     (Model : Remaining_RM_Edge_AST_Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_AST_Repair_Set is
      Result : Remaining_RM_Edge_AST_Repair_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Count_By_Status
     (Model  : Remaining_RM_Edge_AST_Repair_Model;
      Status : Remaining_RM_Edge_AST_Repair_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Remaining_RM_Edge_AST_Repair_Model;
      Family : Remaining_RM_Edge_AST_Repair_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Repaired_Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Repaired then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Repaired_Count;

   function Not_Required_Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Not_Required then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Not_Required_Count;

   function Withheld_Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Withheld_Count;

   function Coverage_Proven_Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural is
      N : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Coverage_Proven then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Coverage_Proven_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural is
   begin
      return Count_By_Status (Model, Remaining_RM_Edge_AST_Repair_Indeterminate);
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Remaining_RM_Edge_AST_Repair_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality;
