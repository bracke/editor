with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1319) + 41) mod 1_000_000_007;
   end Mix;

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));
   end Normalize;

   function Empty (S : Unbounded_String) return Boolean is
   begin
      return Normalize (To_String (S)) = "";
   end Empty;

   function Same (L, R : Unbounded_String) return Boolean is
   begin
      return Normalize (To_String (L)) = Normalize (To_String (R));
   end Same;

   function Compatible_Text (Formal, Actual : Unbounded_String) return Boolean is
   begin
      return Empty (Formal) or else Same (Formal, Actual);
   end Compatible_Text;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Body_Blockers
        + R.Missing_Binding_Blockers
        + R.Missing_Backmapping_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Nested_Cycle_Blockers
        + R.Dependency_Depth_Blockers
        + R.Overload_Blockers
        + R.Type_Substitution_Blockers
        + R.Visibility_Blockers
        + R.Freezing_Blockers
        + R.Representation_Blockers
        + R.Accessibility_Blockers
        + R.Predicate_Blockers
        + R.Dataflow_Blockers
        + R.Shared_State_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Substitution_Fingerprint_Blockers
        + R.Backmapping_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; C : Replay_Context_Info; E : Replay_Event_Info) return Legality_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Legality_Multiple_Blockers;
      elsif R.Missing_Body_Blockers > 0 then
         return Legality_Missing_Generic_Body;
      elsif R.Missing_Binding_Blockers > 0 then
         return Legality_Missing_Formal_Actual_Binding;
      elsif R.Missing_Backmapping_Blockers > 0 then
         return Legality_Missing_Source_Backmapping;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Legality_Incomplete_View_Barrier;
      elsif R.Nested_Cycle_Blockers > 0 then
         return Legality_Nested_Instance_Cycle;
      elsif R.Dependency_Depth_Blockers > 0 then
         return Legality_Dependency_Depth_Overflow;
      elsif R.Overload_Blockers > 0 then
         return Legality_Overload_Blocker;
      elsif R.Type_Substitution_Blockers > 0 then
         return Legality_Type_Substitution_Mismatch;
      elsif R.Visibility_Blockers > 0 then
         return Legality_Visibility_Blocker;
      elsif R.Freezing_Blockers > 0 then
         return Legality_Freezing_Blocker;
      elsif R.Representation_Blockers > 0 then
         return Legality_Representation_Blocker;
      elsif R.Accessibility_Blockers > 0 then
         return Legality_Accessibility_Blocker;
      elsif R.Predicate_Blockers > 0 then
         return Legality_Predicate_Blocker;
      elsif R.Dataflow_Blockers > 0 then
         return Legality_Dataflow_Blocker;
      elsif R.Shared_State_Blockers > 0 then
         return Legality_Shared_State_Blocker;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.Substitution_Fingerprint_Blockers > 0 then
         return Legality_Substitution_Fingerprint_Mismatch;
      elsif R.Backmapping_Fingerprint_Blockers > 0 then
         return Legality_Backmapping_Fingerprint_Mismatch;
      elsif Blocks = 0 and then E.Kind = Event_Nested_Instantiation then
         return Legality_Legal_Nested_Replay;
      elsif Blocks = 0 and then E.Requires_Runtime_Check then
         return Legality_Legal_Runtime_Check;
      elsif Blocks = 0 and then C.Instance /= No_Instance then
         return Legality_Legal_Replayed;
      else
         return Legality_Indeterminate;
      end if;
   end Status_For;

   function Find_Context (Contexts : Context_Model; Instance : Instance_Id) return Replay_Context_Info is
   begin
      for C of Contexts.Items loop
         if C.Instance = Instance then
            return C;
         end if;
      end loop;
      return (others => <>);
   end Find_Context;

   procedure Clear (Model : in out Context_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Event_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Context_Model; Info : Replay_Context_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Instance));
   end Add_Context;

   procedure Add_Event (Model : in out Event_Model; Info : Replay_Event_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
   end Add_Event;

   function Build (Contexts : Context_Model; Events : Event_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for E of Events.Items loop
         declare
            C : constant Replay_Context_Info := Find_Context (Contexts, E.Instance);
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            Next_Id := Next_Id + 1;
            R.Instance := E.Instance;
            R.Event := E.Id;
            R.Node := E.Node;
            R.Kind := E.Kind;

            if C.Instance = No_Instance then
               R.Missing_Binding_Blockers := 1;
            else
               if not C.Has_Generic_Body then
                  R.Missing_Body_Blockers := 1;
               end if;
               if not C.Has_Formal_Actual_Bindings then
                  R.Missing_Binding_Blockers := R.Missing_Binding_Blockers + 1;
               end if;
               if not C.Has_Source_Backmapping then
                  R.Missing_Backmapping_Blockers := 1;
               end if;
               if C.View = View_Private and then not C.Allows_Private_View then
                  R.Private_View_Blockers := 1;
               end if;
               if C.View = View_Limited and then not C.Allows_Limited_View then
                  R.Limited_View_Blockers := 1;
               end if;
               if C.View = View_Incomplete then
                  R.Incomplete_View_Blockers := 1;
               end if;
               if C.Nested_Cycle then
                  R.Nested_Cycle_Blockers := 1;
               end if;
               if C.Nested_Depth > C.Max_Nested_Depth then
                  R.Dependency_Depth_Blockers := 1;
               end if;
               if not E.Overload_Resolved then
                  R.Overload_Blockers := 1;
               end if;
               if not E.Type_Substitution_Valid
                 or else not Compatible_Text (E.Formal_Profile, E.Actual_Profile)
                 or else not Compatible_Text (E.Formal_Type, E.Actual_Type)
               then
                  R.Type_Substitution_Blockers := 1;
               end if;
               if not E.Visibility_Valid then
                  R.Visibility_Blockers := 1;
               end if;
               if not E.Freezing_Valid then
                  R.Freezing_Blockers := 1;
               end if;
               if not E.Representation_Valid then
                  R.Representation_Blockers := 1;
               end if;
               if not E.Accessibility_Valid then
                  R.Accessibility_Blockers := 1;
               end if;
               if not E.Predicate_Valid then
                  R.Predicate_Blockers := 1;
               end if;
               if not E.Dataflow_Valid then
                  R.Dataflow_Blockers := 1;
               end if;
               if not E.Shared_State_Valid then
                  R.Shared_State_Blockers := 1;
               end if;

               if C.Expected_Source_Fingerprint /= 0 and then C.Expected_Source_Fingerprint /= C.Source_Fingerprint then
                  R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
               end if;
               if E.Expected_Source_Fingerprint /= 0 and then E.Expected_Source_Fingerprint /= E.Source_Fingerprint then
                  R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
               end if;
               if C.Expected_Substitution_Fingerprint /= 0
                 and then C.Expected_Substitution_Fingerprint /= C.Substitution_Fingerprint
               then
                  R.Substitution_Fingerprint_Blockers := R.Substitution_Fingerprint_Blockers + 1;
               end if;
               if E.Expected_Substitution_Fingerprint /= 0
                 and then E.Expected_Substitution_Fingerprint /= E.Substitution_Fingerprint
               then
                  R.Substitution_Fingerprint_Blockers := R.Substitution_Fingerprint_Blockers + 1;
               end if;
               if C.Expected_Backmapping_Fingerprint /= 0
                 and then C.Expected_Backmapping_Fingerprint /= C.Backmapping_Fingerprint
               then
                  R.Backmapping_Fingerprint_Blockers := R.Backmapping_Fingerprint_Blockers + 1;
               end if;
               if E.Expected_Backmapping_Fingerprint /= 0
                 and then E.Expected_Backmapping_Fingerprint /= E.Backmapping_Fingerprint
               then
                  R.Backmapping_Fingerprint_Blockers := R.Backmapping_Fingerprint_Blockers + 1;
               end if;
            end if;

            R.Status := Status_For (R, C, E);
            R.Message := To_Unbounded_String ("generic body replay substitution legality");
            R.Detail := To_Unbounded_String (To_String (C.Generic_Name) & " => " & To_String (E.Source_Text));
            R.Fingerprint := Mix (Natural (Legality_Status'Pos (R.Status)), Natural (R.Event));
            R.Fingerprint := Mix (R.Fingerprint, Natural (Replay_Event_Kind'Pos (R.Kind)));
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
         end;
      end loop;
      return Results;
   end Build;

   function Context_Count (Model : Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Event_Count (Model : Event_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Event_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items (Index);
   end Result_At;

   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural is
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
         if R.Status in Legality_Legal_Replayed | Legality_Legal_Runtime_Check | Legality_Legal_Nested_Replay then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
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
      return Info.Id /= No_Result;
   end Has_Result;

end Editor.Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality;
