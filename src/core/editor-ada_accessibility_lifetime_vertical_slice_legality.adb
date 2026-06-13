with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Accessibility_Lifetime_Vertical_Slice_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 811) + 1300) mod 1_000_000_007;
   end Mix;

   function Is_Legal (Status : Accessibility_Status) return Boolean is
   begin
      return Status in Accessibility_Legal_Static_Master
        | Accessibility_Legal_Runtime_Check
        | Accessibility_Legal_Local_Target
        | Accessibility_Legal_Access_To_Subprogram_Profile
        | Accessibility_Legal_Generic_Substitution;
   end Is_Legal;

   procedure Clear (Model : in out Scope_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Entity_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Flow_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Scope (Model : in out Scope_Model; Info : Scope_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Parent) + Info.Master_Level
         + Info.Source_Fingerprint + Scope_Kind'Pos (Info.Kind));
   end Add_Scope;

   procedure Add_Entity (Model : in out Entity_Model; Info : Entity_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Scope) + Info.Master_Level
         + Info.Source_Fingerprint + Info.Profile_Fingerprint
         + Info.Substitution_Fingerprint + Entity_Kind'Pos (Info.Kind));
   end Add_Entity;

   procedure Add_Flow (Model : in out Flow_Model; Info : Flow_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Source) + Natural (Info.Target)
         + Info.Source_Fingerprint + Info.Flow_Fingerprint
         + Operation_Kind'Pos (Info.Operation));
   end Add_Flow;

   function Find_Entity (Entities : Entity_Model; Id : Entity_Id) return Entity_Info is
   begin
      for E of Entities.Items loop
         if E.Id = Id then
            return E;
         end if;
      end loop;
      return (others => <>);
   end Find_Entity;

   function Scope_Exists (Scopes : Scope_Model; Id : Scope_Id) return Boolean is
   begin
      if Id = No_Scope then
         return False;
      end if;

      for S of Scopes.Items loop
         if S.Id = Id then
            return True;
         end if;
      end loop;
      return False;
   end Scope_Exists;

   function Master_Escapes
     (Source : Entity_Info;
      Target : Entity_Info;
      Flow   : Flow_Info) return Boolean is
   begin
      if Flow.Allows_Runtime_Accessibility_Check then
         return False;
      end if;

      --  Lower master levels denote longer-lived masters.  A designated
      --  object from a deeper source master cannot be stored in or returned
      --  through a longer-lived target master.
      return Source.Master_Level > Target.Master_Level;
   end Master_Escapes;

   procedure Apply_Operation_Blocker
     (R      : in out Result_Info;
      Flow   : Flow_Info;
      Source : Entity_Info;
      Target : Entity_Info) is
   begin
      R.Escape_Blockers := R.Escape_Blockers + 1;

      case Flow.Operation is
         when Operation_Return =>
            R.Return_Blockers := R.Return_Blockers + 1;
         when Operation_Assignment =>
            R.Assignment_Blockers := R.Assignment_Blockers + 1;
         when Operation_Aggregate_Component =>
            R.Aggregate_Blockers := R.Aggregate_Blockers + 1;
         when Operation_Generic_Actual =>
            R.Generic_Blockers := R.Generic_Blockers + 1;
         when Operation_Renaming =>
            R.Renaming_Blockers := R.Renaming_Blockers + 1;
         when Operation_Protected_Task_Shared_State =>
            R.Protected_Task_Blockers := R.Protected_Task_Blockers + 1;
         when Operation_Discriminant_Component =>
            R.Discriminant_Blockers := R.Discriminant_Blockers + 1;
         when others =>
            null;
      end case;

      if Flow.Through_Return_Object then
         R.Return_Blockers := R.Return_Blockers + 1;
      end if;
      if Flow.Through_Aggregate then
         R.Aggregate_Blockers := R.Aggregate_Blockers + 1;
      end if;
      if Flow.Through_Renaming or else Source.Is_From_Renaming
        or else Target.Is_From_Renaming
      then
         R.Renaming_Blockers := R.Renaming_Blockers + 1;
      end if;
      if Flow.In_Generic_Instance or else Source.Is_Generic_Formal
        or else Target.Is_Generic_Formal
      then
         R.Generic_Blockers := R.Generic_Blockers + 1;
      end if;
      if Flow.Through_Discriminant or else Source.Is_Discriminant_Dependent
        or else Target.Is_Discriminant_Dependent
      then
         R.Discriminant_Blockers := R.Discriminant_Blockers + 1;
      end if;
      if Flow.Through_Protected_Or_Task_State
        or else Source.Is_Protected_Or_Task_State
        or else Target.Is_Protected_Or_Task_State
      then
         R.Protected_Task_Blockers := R.Protected_Task_Blockers + 1;
      end if;
   end Apply_Operation_Blocker;

   function Status_For
     (R      : Result_Info;
      Flow   : Flow_Info;
      Source : Entity_Info;
      Target : Entity_Info) return Accessibility_Status is
   begin
      if R.Missing_Source_Blockers > 0 then
         return Accessibility_Missing_Source;
      elsif R.Missing_Target_Blockers > 0 then
         return Accessibility_Missing_Target;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Accessibility_Source_Fingerprint_Mismatch;
      elsif R.Substitution_Fingerprint_Blockers > 0 then
         return Accessibility_Substitution_Fingerprint_Mismatch;
      elsif R.Profile_Blockers > 0 then
         return Accessibility_Subprogram_Profile_Mismatch;
      elsif R.Protected_Task_Blockers > 0 then
         return Accessibility_Protected_Task_State_Escape;
      elsif R.Discriminant_Blockers > 0 then
         return Accessibility_Discriminant_Dependent_Escape;
      elsif R.Return_Blockers > 0 then
         return Accessibility_Return_Escape;
      elsif R.Assignment_Blockers > 0 then
         return Accessibility_Assignment_Escape;
      elsif R.Aggregate_Blockers > 0 then
         return Accessibility_Aggregate_Component_Escape;
      elsif R.Generic_Blockers > 0 then
         return Accessibility_Generic_Actual_Escape;
      elsif R.Renaming_Blockers > 0 then
         return Accessibility_Renaming_Escape;
      elsif R.Escape_Blockers > 0 then
         return Accessibility_Escape_To_Longer_Lived_Master;
      elsif Flow.Allows_Runtime_Accessibility_Check then
         return Accessibility_Legal_Runtime_Check;
      elsif Flow.Requires_Access_To_Subprogram_Profile
        or else Source.Is_Access_To_Subprogram
        or else Target.Is_Access_To_Subprogram
      then
         return Accessibility_Legal_Access_To_Subprogram_Profile;
      elsif Flow.In_Generic_Instance or else Source.Is_Generic_Formal
        or else Target.Is_Generic_Formal
      then
         return Accessibility_Legal_Generic_Substitution;
      elsif Source.Master_Level = Target.Master_Level then
         return Accessibility_Legal_Local_Target;
      end if;

      return Accessibility_Legal_Static_Master;
   end Status_For;

   function Build
     (Scopes   : Scope_Model;
      Entities : Entity_Model;
      Flows    : Flow_Model) return Result_Model
   is
      Result : Result_Model;
      Next_Id : Natural := 1;
   begin
      for F of Flows.Items loop
         declare
            Source : constant Entity_Info := Find_Entity (Entities, F.Source);
            Target : constant Entity_Info := Find_Entity (Entities, F.Target);
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            Next_Id := Next_Id + 1;
            R.Flow := F.Id;
            R.Source := F.Source;
            R.Target := F.Target;
            R.Node := F.Node;
            R.Operation := F.Operation;
            R.Source_Fingerprint := F.Source_Fingerprint;

            if Source.Id = No_Entity or else not Scope_Exists (Scopes, Source.Scope) then
               R.Missing_Source_Blockers := R.Missing_Source_Blockers + 1;
            else
               R.Source_Master_Level := Source.Master_Level;
               R.Source_Fingerprint := Source.Source_Fingerprint;
               R.Substitution_Fingerprint := Source.Substitution_Fingerprint;
            end if;

            if Target.Id = No_Entity or else not Scope_Exists (Scopes, Target.Scope) then
               R.Missing_Target_Blockers := R.Missing_Target_Blockers + 1;
            else
               R.Target_Master_Level := Target.Master_Level;
               R.Target_Fingerprint := Target.Source_Fingerprint;
               if R.Substitution_Fingerprint = 0 then
                  R.Substitution_Fingerprint := Target.Substitution_Fingerprint;
               end if;
            end if;

            if R.Missing_Source_Blockers = 0 and then R.Missing_Target_Blockers = 0 then
               if Source.Source_Fingerprint = 0 or else Target.Source_Fingerprint = 0
                 or else F.Source_Fingerprint = 0
                 or else (F.Expected_Source_Fingerprint /= 0
                          and then F.Expected_Source_Fingerprint /= Source.Source_Fingerprint)
                 or else (F.Expected_Target_Fingerprint /= 0
                          and then F.Expected_Target_Fingerprint /= Target.Source_Fingerprint)
               then
                  R.Source_Fingerprint_Blockers :=
                    R.Source_Fingerprint_Blockers + 1;
               end if;

               if F.In_Generic_Instance
                 and then (Source.Substitution_Fingerprint = 0
                           or else Target.Substitution_Fingerprint = 0
                           or else F.Expected_Substitution_Fingerprint = 0
                           or else F.Expected_Substitution_Fingerprint
                             /= Source.Substitution_Fingerprint
                           or else Source.Substitution_Fingerprint
                             /= Target.Substitution_Fingerprint)
               then
                  R.Substitution_Fingerprint_Blockers :=
                    R.Substitution_Fingerprint_Blockers + 1;
               end if;

               if F.Requires_Access_To_Subprogram_Profile
                 and then (not Source.Is_Access_To_Subprogram
                           or else not Target.Is_Access_To_Subprogram
                           or else Source.Profile_Fingerprint = 0
                           or else Target.Profile_Fingerprint = 0
                           or else Source.Profile_Fingerprint
                             /= Target.Profile_Fingerprint
                           or else (F.Expected_Profile_Fingerprint /= 0
                                    and then F.Expected_Profile_Fingerprint
                                      /= Source.Profile_Fingerprint))
               then
                  R.Profile_Blockers := R.Profile_Blockers + 1;
               end if;

               if Master_Escapes (Source, Target, F) then
                  Apply_Operation_Blocker (R, F, Source, Target);
               end if;

               if Source.Has_Controlled_Finalization
                 and then Target.Master_Level < Source.Master_Level
                 and then F.Operation in Operation_Return | Operation_Aggregate_Component
               then
                  R.Escape_Blockers := R.Escape_Blockers + 1;
                  R.Return_Blockers := R.Return_Blockers
                    + (if F.Operation = Operation_Return then 1 else 0);
                  R.Aggregate_Blockers := R.Aggregate_Blockers
                    + (if F.Operation = Operation_Aggregate_Component then 1 else 0);
               end if;
            end if;

            R.Status := Status_For (R, F, Source, Target);

            if Is_Legal (R.Status) then
               R.Message := To_Unbounded_String ("accessibility/lifetime flow accepted");
               Result.Legal_Total := Result.Legal_Total + 1;
            else
               R.Message := To_Unbounded_String ("accessibility/lifetime flow rejected");
               Result.Error_Total := Result.Error_Total + 1;
            end if;

            R.Detail := To_Unbounded_String
              ("source_master=" & Natural'Image (R.Source_Master_Level)
               & " target_master=" & Natural'Image (R.Target_Master_Level)
               & " escape=" & Natural'Image (R.Escape_Blockers)
               & " return=" & Natural'Image (R.Return_Blockers)
               & " generic=" & Natural'Image (R.Generic_Blockers));
            R.Fingerprint := Mix
              (R.Source_Fingerprint + R.Target_Fingerprint + R.Substitution_Fingerprint,
               Natural (Accessibility_Status'Pos (R.Status)) + R.Escape_Blockers
               + R.Return_Blockers + R.Assignment_Blockers + R.Aggregate_Blockers
               + R.Generic_Blockers + R.Renaming_Blockers + R.Profile_Blockers
               + R.Protected_Task_Blockers + R.Discriminant_Blockers
               + R.Source_Fingerprint_Blockers
               + R.Substitution_Fingerprint_Blockers
               + R.Missing_Source_Blockers + R.Missing_Target_Blockers);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
            Result.Items.Append (R);
         end;
      end loop;

      return Result;
   end Build;

   function Scope_Count (Model : Scope_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Scope_Count;

   function Entity_Count (Model : Entity_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Entity_Count;

   function Flow_Count (Model : Flow_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Flow_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items (Index);
   end Result_At;

   function First_For_Node
     (Model : Result_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Result_Info is
   begin
      for R of Model.Items loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Count_Status
     (Model : Result_Model;
      Status : Accessibility_Status) return Natural is
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
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result;
   end Has_Result;

end Editor.Ada_Accessibility_Lifetime_Vertical_Slice_Legality;
