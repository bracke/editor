with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Record_Layout_Representation_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1322) mod 1_000_000_007;
   end Mix;

   function Clause_First (C : Component_Clause_Info) return Natural is
   begin
      return C.Position_Bits + C.First_Bit;
   end Clause_First;

   function Clause_Last (C : Component_Clause_Info) return Natural is
   begin
      return C.Position_Bits + C.Last_Bit;
   end Clause_Last;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Record_Blockers
        + R.Missing_Component_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_Blockers
        + R.Late_Freezing_Blockers
        + R.Non_Static_Position_Blockers
        + R.Non_Static_Range_Blockers
        + R.Invalid_Range_Blockers
        + R.Invalid_Position_Blockers
        + R.Overlap_Blockers
        + R.Size_Overflow_Blockers
        + R.Alignment_Blockers
        + R.Storage_Order_Blockers
        + R.Discriminant_Blockers
        + R.Variant_Blockers
        + R.Controlled_Finalized_Blockers
        + R.Duplicate_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Record_Fingerprint_Blockers
        + R.Clause_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; C : Component_Clause_Info) return Layout_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Layout_Multiple_Blockers;
      elsif R.Missing_Record_Blockers > 0 then
         return Layout_Missing_Record;
      elsif R.Missing_Component_Blockers > 0 then
         return Layout_Missing_Component;
      elsif R.Private_View_Blockers > 0 then
         return Layout_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Layout_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Layout_Incomplete_View_Barrier;
      elsif R.Generic_Formal_Blockers > 0 then
         return Layout_Generic_Formal_Barrier;
      elsif R.Late_Freezing_Blockers > 0 then
         return Layout_Late_After_Freezing;
      elsif R.Non_Static_Position_Blockers > 0 then
         return Layout_Non_Static_Position;
      elsif R.Non_Static_Range_Blockers > 0 then
         return Layout_Non_Static_Range;
      elsif R.Invalid_Range_Blockers > 0 then
         return Layout_Invalid_Bit_Range;
      elsif R.Invalid_Position_Blockers > 0 then
         return Layout_Invalid_Position;
      elsif R.Overlap_Blockers > 0 then
         return Layout_Overlap;
      elsif R.Size_Overflow_Blockers > 0 then
         return Layout_Size_Overflow;
      elsif R.Alignment_Blockers > 0 then
         return Layout_Alignment_Conflict;
      elsif R.Storage_Order_Blockers > 0 then
         return Layout_Storage_Order_Conflict;
      elsif R.Discriminant_Blockers > 0 then
         return Layout_Discriminant_Dependency_Conflict;
      elsif R.Variant_Blockers > 0 then
         return Layout_Variant_Coverage_Conflict;
      elsif R.Controlled_Finalized_Blockers > 0 then
         return Layout_Controlled_Finalized_Conflict;
      elsif R.Duplicate_Blockers > 0 then
         return Layout_Duplicate_Component_Clause;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Layout_Source_Fingerprint_Mismatch;
      elsif R.Record_Fingerprint_Blockers > 0 then
         return Layout_Record_Fingerprint_Mismatch;
      elsif R.Clause_Fingerprint_Blockers > 0 then
         return Layout_Clause_Fingerprint_Mismatch;
      elsif Blocks = 0 and then C.Requires_Runtime_Check then
         return Layout_Legal_Runtime_Check;
      elsif Blocks = 0 then
         return Layout_Legal;
      else
         return Layout_Indeterminate;
      end if;
   end Status_For;

   function Find_Record (Records : Record_Model; Id : Record_Id) return Record_Info is
   begin
      for R of Records.Items loop
         if R.Id = Id then
            return R;
         end if;
      end loop;
      return (others => <>);
   end Find_Record;

   function Find_Component (Components : Component_Model; Id : Component_Id) return Component_Info is
   begin
      for C of Components.Items loop
         if C.Id = Id then
            return C;
         end if;
      end loop;
      return (others => <>);
   end Find_Component;

   function Has_Duplicate_Before (Clauses : Clause_Model; C : Component_Clause_Info) return Boolean is
   begin
      for Other of Clauses.Items loop
         exit when Other.Id = C.Id;
         if Other.Record_Ref = C.Record_Ref and then Other.Component = C.Component then
            return True;
         end if;
      end loop;
      return False;
   end Has_Duplicate_Before;

   function Overlaps_Previous (Clauses : Clause_Model; C : Component_Clause_Info) return Boolean is
      CF : constant Natural := Clause_First (C);
      CL : constant Natural := Clause_Last (C);
   begin
      for Other of Clauses.Items loop
         exit when Other.Id = C.Id;
         if Other.Record_Ref = C.Record_Ref
           and then Other.Component /= C.Component
           and then Other.Range_Valid
           and then C.Range_Valid
           and then not (CL < Clause_First (Other) or else CF > Clause_Last (Other))
         then
            return True;
         end if;
      end loop;
      return False;
   end Overlaps_Previous;

   procedure Clear (Model : in out Record_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Component_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Clause_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Record (Model : in out Record_Model; Info : Record_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Record_Fingerprint);
   end Add_Record;

   procedure Add_Component (Model : in out Component_Model; Info : Component_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Record_Ref));
   end Add_Component;

   procedure Add_Clause (Model : in out Clause_Model; Info : Component_Clause_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Clause_Fingerprint);
   end Add_Clause;

   function Build
     (Records : Record_Model;
      Components : Component_Model;
      Clauses : Clause_Model) return Result_Model
   is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for C of Clauses.Items loop
         declare
            Rec : constant Record_Info := Find_Record (Records, C.Record_Ref);
            Comp : constant Component_Info := Find_Component (Components, C.Component);
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            Next_Id := Next_Id + 1;
            R.Clause := C.Id;
            R.Record_Ref := C.Record_Ref;
            R.Component := C.Component;

            if Rec.Id = No_Record then
               R.Missing_Record_Blockers := 1;
            else
               case Rec.View is
                  when View_Private => R.Private_View_Blockers := 1;
                  when View_Limited => R.Limited_View_Blockers := 1;
                  when View_Incomplete => R.Incomplete_View_Blockers := 1;
                  when View_Generic_Formal => R.Generic_Formal_Blockers := 1;
                  when others => null;
               end case;

               if Rec.Frozen and then C.Placement_Order >= Rec.Freeze_Order then
                  R.Late_Freezing_Blockers := 1;
               end if;

               if Rec.Source_Fingerprint /= Rec.Expected_Source_Fingerprint
                 or else C.Source_Fingerprint /= C.Expected_Source_Fingerprint
               then
                  R.Source_Fingerprint_Blockers := 1;
               end if;

               if Rec.Record_Fingerprint /= Rec.Expected_Record_Fingerprint
                 or else C.Record_Fingerprint /= C.Expected_Record_Fingerprint
               then
                  R.Record_Fingerprint_Blockers := 1;
               end if;
            end if;

            if Comp.Id = No_Component or else Comp.Record_Ref /= C.Record_Ref then
               R.Missing_Component_Blockers := 1;
            else
               if Comp.Source_Fingerprint /= Comp.Expected_Source_Fingerprint then
                  R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
               end if;
            end if;

            if C.Clause_Fingerprint /= C.Expected_Clause_Fingerprint then
               R.Clause_Fingerprint_Blockers := 1;
            end if;

            if not C.Position_Static then
               R.Non_Static_Position_Blockers := 1;
            end if;
            if not C.Range_Static then
               R.Non_Static_Range_Blockers := 1;
            end if;
            if not C.Range_Valid or else C.First_Bit > C.Last_Bit then
               R.Invalid_Range_Blockers := 1;
            end if;
            if not C.Position_Valid then
               R.Invalid_Position_Blockers := 1;
            end if;

            if Rec.Id /= No_Record and then Rec.Size_Bits > 0
              and then C.Range_Valid
              and then Clause_Last (C) >= Rec.Size_Bits
            then
               R.Size_Overflow_Blockers := 1;
            end if;

            if Rec.Id /= No_Record and then Comp.Id /= No_Component
              and then Comp.Size_Bits > 0
              and then C.Range_Valid
              and then (C.Last_Bit - C.First_Bit + 1) < Comp.Size_Bits
            then
               R.Size_Overflow_Blockers := R.Size_Overflow_Blockers + 1;
            end if;

            if not C.Alignment_Compatible then
               R.Alignment_Blockers := 1;
            elsif Rec.Alignment_Bits > 0 and then C.Position_Bits mod Rec.Alignment_Bits /= 0 then
               R.Alignment_Blockers := 1;
            end if;

            if not C.Storage_Order_Compatible or else Rec.Storage_Order = Storage_Unknown then
               R.Storage_Order_Blockers := 1;
            end if;
            if not C.Discriminant_Dependency_Compatible
              or else (Comp.Requires_Discriminant_Value and then not Rec.Has_Discriminants)
            then
               R.Discriminant_Blockers := 1;
            end if;
            if not C.Variant_Coverage_Compatible
              or else ((not Comp.Active_In_All_Variants) and then not Rec.Has_Variants)
            then
               R.Variant_Blockers := 1;
            end if;
            if not C.Controlled_Finalized_Compatible
              or else (Comp.Controlled_Or_Finalized
                       and then not (Rec.Has_Controlled_Components or else Rec.Has_Finalized_Components))
            then
               R.Controlled_Finalized_Blockers := 1;
            end if;
            if Has_Duplicate_Before (Clauses, C) then
               R.Duplicate_Blockers := 1;
            end if;
            if Overlaps_Previous (Clauses, C) then
               R.Overlap_Blockers := 1;
            end if;

            R.Status := Status_For (R, C);
            R.Message := To_Unbounded_String (Layout_Status'Image (R.Status));
            R.Detail := To_Unbounded_String ("record component representation layout legality");
            R.Fingerprint := Mix (Natural (R.Clause), Blocker_Count (R));
            R.Fingerprint := Mix (R.Fingerprint, Natural (Layout_Status'Pos (R.Status)));
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Results.Items.Append (R);
         end;
      end loop;
      return Results;
   end Build;

   function Record_Count (Model : Record_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Record_Count;

   function Component_Count (Model : Component_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Component_Count;

   function Clause_Count (Model : Clause_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Clause_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Result_Model; Status : Layout_Status) return Natural is
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
   begin
      return Count_Status (Model, Layout_Legal) + Count_Status (Model, Layout_Legal_Runtime_Check);
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
   begin
      return Result_Count (Model) - Legal_Count (Model);
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result and then Info.Status /= Layout_Not_Checked;
   end Has_Result;

end Editor.Ada_Record_Layout_Representation_Vertical_Slice_Legality;
