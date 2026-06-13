with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Parser_AST_Coverage_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 997) + 1304) mod 1_000_000_007;
   end Mix;

   function Is_Legal (Status : Coverage_Status) return Boolean is
   begin
      return Status in Coverage_Legal_AST | Coverage_Legal_Semantic_Consumer;
   end Is_Legal;

   function Requires_Secondary_Child (Kind : Construct_Kind) return Boolean is
   begin
      return Kind in Construct_Quantified_Expression
        | Construct_Reduction_Expression
        | Construct_Delta_Aggregate
        | Construct_Container_Aggregate
        | Construct_Declare_Expression
        | Construct_Target_Name_Update
        | Construct_Parallel_Loop;
   end Requires_Secondary_Child;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Parser_Node_Blockers
        + R.Token_Only_Blockers
        + R.Degraded_Blockers
        + R.Source_Span_Blockers
        + R.Primary_Child_Blockers
        + R.Secondary_Child_Blockers
        + R.Metadata_Blockers
        + R.Consumer_Blockers
        + R.Wrong_Kind_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; C : Construct_Info) return Coverage_Status is
   begin
      if R.Parser_Node_Blockers > 0 then
         return Coverage_Missing_Parser_Node;
      elsif R.Token_Only_Blockers > 0 then
         return Coverage_Token_Only_Construct;
      elsif R.Degraded_Blockers > 0 then
         return Coverage_Degraded_Construct;
      elsif R.Source_Span_Blockers > 0 then
         return Coverage_Missing_Source_Span;
      elsif R.Primary_Child_Blockers > 0 then
         return Coverage_Missing_Primary_Child;
      elsif R.Secondary_Child_Blockers > 0 then
         return Coverage_Missing_Secondary_Child;
      elsif R.Metadata_Blockers > 0 then
         return Coverage_Missing_Type_Metadata;
      elsif R.Consumer_Blockers > 0 then
         return Coverage_Missing_Semantic_Consumer;
      elsif R.Wrong_Kind_Blockers > 0 then
         return Coverage_Wrong_Construct_Kind;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Coverage_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Coverage_AST_Fingerprint_Mismatch;
      elsif C.Consumer = Consumer_Unknown then
         return Coverage_Legal_AST;
      else
         return Coverage_Legal_Semantic_Consumer;
      end if;
   end Status_For;

   procedure Add_Message (R : in out Result_Info) is
   begin
      case R.Status is
         when Coverage_Legal_AST =>
            R.Message := To_Unbounded_String ("Ada 2022 construct has complete parser/AST coverage");
         when Coverage_Legal_Semantic_Consumer =>
            R.Message := To_Unbounded_String ("Ada 2022 construct has parser/AST coverage and semantic consumer evidence");
         when Coverage_Missing_Parser_Node =>
            R.Message := To_Unbounded_String ("construct has no parser-owned AST node");
         when Coverage_Token_Only_Construct =>
            R.Message := To_Unbounded_String ("construct remains token-only and cannot feed semantic legality");
         when Coverage_Degraded_Construct =>
            R.Message := To_Unbounded_String ("construct is degraded and lacks stable AST shape");
         when Coverage_Missing_Source_Span =>
            R.Message := To_Unbounded_String ("construct AST node is missing a source span");
         when Coverage_Missing_Primary_Child =>
            R.Message := To_Unbounded_String ("construct AST node is missing its primary child");
         when Coverage_Missing_Secondary_Child =>
            R.Message := To_Unbounded_String ("construct AST node is missing a required secondary child");
         when Coverage_Missing_Type_Metadata =>
            R.Message := To_Unbounded_String ("construct lacks semantic type metadata");
         when Coverage_Missing_Semantic_Consumer =>
            R.Message := To_Unbounded_String ("construct has no integrated semantic consumer");
         when Coverage_Wrong_Construct_Kind =>
            R.Message := To_Unbounded_String ("construct AST kind does not match the expected Ada 2022 construct");
         when Coverage_Source_Fingerprint_Mismatch =>
            R.Message := To_Unbounded_String ("stale source fingerprint for parser/AST coverage row");
         when Coverage_AST_Fingerprint_Mismatch =>
            R.Message := To_Unbounded_String ("stale AST fingerprint for parser/AST coverage row");
         when Coverage_Multiple_Blockers =>
            R.Message := To_Unbounded_String ("multiple parser/AST coverage blockers");
         when Coverage_Indeterminate | Coverage_Not_Checked =>
            R.Message := To_Unbounded_String ("parser/AST coverage is indeterminate");
      end case;
   end Add_Message;

   procedure Clear (Model : in out Construct_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Construct (Model : in out Construct_Model; Info : Construct_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Construct_Kind'Pos (Info.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
   end Add_Construct;

   function Build (Constructs : Construct_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for C of Constructs.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Construct := C.Id;
            R.Node := C.Node;
            R.Kind := C.Kind;
            R.Consumer := C.Consumer;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.AST_Fingerprint := C.AST_Fingerprint;

            if C.Id = No_Construct or else not C.Has_Parser_Node then
               R.Parser_Node_Blockers := R.Parser_Node_Blockers + 1;
            end if;

            if C.Is_Token_Only then
               R.Token_Only_Blockers := R.Token_Only_Blockers + 1;
            end if;

            if C.Is_Degraded then
               R.Degraded_Blockers := R.Degraded_Blockers + 1;
            end if;

            if not C.Has_Source_Span then
               R.Source_Span_Blockers := R.Source_Span_Blockers + 1;
            end if;

            if not C.Has_Primary_Child then
               R.Primary_Child_Blockers := R.Primary_Child_Blockers + 1;
            end if;

            if Requires_Secondary_Child (C.Kind) and then not C.Has_Secondary_Child then
               R.Secondary_Child_Blockers := R.Secondary_Child_Blockers + 1;
            end if;

            if not C.Has_Type_Metadata then
               R.Metadata_Blockers := R.Metadata_Blockers + 1;
            end if;

            if not C.Has_Semantic_Consumer then
               R.Consumer_Blockers := R.Consumer_Blockers + 1;
            end if;

            if C.Expected_Kind /= Construct_Unknown and then C.Expected_Kind /= C.Kind then
               R.Wrong_Kind_Blockers := R.Wrong_Kind_Blockers + 1;
            end if;

            if C.Expected_Source_Fingerprint /= 0
              and then C.Expected_Source_Fingerprint /= C.Source_Fingerprint
            then
               R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
            end if;

            if C.Expected_AST_Fingerprint /= 0
              and then C.Expected_AST_Fingerprint /= C.AST_Fingerprint
            then
               R.AST_Fingerprint_Blockers := R.AST_Fingerprint_Blockers + 1;
            end if;

            R.Status := Status_For (R, C);
            if Blocker_Count (R) > 1 then
               R.Status := Coverage_Multiple_Blockers;
            elsif C.Kind = Construct_Unknown and then Blocker_Count (R) = 0 then
               R.Status := Coverage_Indeterminate;
            end if;

            Add_Message (R);
            R.Detail := To_Unbounded_String
              ("parser/AST vertical slice for " & To_String (C.Source_Name));
            R.Fingerprint := Mix (Natural (Coverage_Status'Pos (R.Status)), Natural (C.Id));
            R.Fingerprint := Mix (R.Fingerprint, R.Source_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.AST_Fingerprint);
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   function Construct_Count (Model : Construct_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Construct_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Result_Model; Status : Coverage_Status) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Legal_Count (Model : Result_Model) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if Is_Legal (R.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if not Is_Legal (R.Status)
           and then R.Status /= Coverage_Not_Checked
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result and then Info.Status /= Coverage_Not_Checked;
   end Has_Result;

end Editor.Ada_Parser_AST_Coverage_Vertical_Slice_Legality;
