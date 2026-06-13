with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Elaboration_Vertical_Slice_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 811) + 1301) mod 1_000_000_007;
   end Mix;

   function Is_Legal (Status : Elaboration_Status) return Boolean is
   begin
      return Status in Elaboration_Legal_No_Call
        | Elaboration_Legal_Body_Elaborated
        | Elaboration_Legal_Elaborate_Pragma
        | Elaboration_Legal_Elaborate_All_Pragma
        | Elaboration_Legal_Preelaborable_Call
        | Elaboration_Legal_Pure_Call;
   end Is_Legal;

   procedure Clear (Model : in out Unit_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Dependency_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Call_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Unit (Model : in out Unit_Model; Info : Unit_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Body_Id) + Natural (Info.Spec_Id)
         + Info.Source_Fingerprint + Info.Dependency_Fingerprint
         + Unit_Kind'Pos (Info.Kind));
   end Add_Unit;

   procedure Add_Dependency (Model : in out Dependency_Model; Info : Dependency_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.From_Unit) + Natural (Info.To_Unit)
         + Info.Source_Fingerprint + Info.Dependency_Fingerprint
         + Dependency_Kind'Pos (Info.Kind));
   end Add_Dependency;

   procedure Add_Call (Model : in out Call_Model; Info : Call_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Caller) + Natural (Info.Callee)
         + Info.Source_Fingerprint + Info.Call_Fingerprint
         + Call_Kind'Pos (Info.Kind));
   end Add_Call;

   function Find_Unit (Units : Unit_Model; Id : Unit_Id) return Unit_Info is
   begin
      for U of Units.Items loop
         if U.Id = Id then
            return U;
         end if;
      end loop;
      return (others => <>);
   end Find_Unit;

   function Has_Dependency
     (Dependencies : Dependency_Model;
      From_Unit    : Unit_Id;
      To_Unit      : Unit_Id;
      Kind         : Dependency_Kind) return Boolean is
   begin
      for D of Dependencies.Items loop
         if D.From_Unit = From_Unit and then D.To_Unit = To_Unit
           and then D.Kind = Kind
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Dependency;

   function Has_Transitive_Elaborate_All
     (Dependencies : Dependency_Model;
      From_Unit    : Unit_Id;
      To_Unit      : Unit_Id) return Boolean is
   begin
      for D of Dependencies.Items loop
         if D.From_Unit = From_Unit and then D.To_Unit = To_Unit
           and then D.Kind = Dependency_Elaborate_All
         then
            return True;
         elsif D.From_Unit = From_Unit and then D.To_Unit = To_Unit
           and then D.Is_Transitive
           and then D.Kind in Dependency_Elaborate_All | Dependency_With
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Transitive_Elaborate_All;

   function Has_Cycle
     (Dependencies : Dependency_Model;
      A            : Unit_Id;
      B            : Unit_Id) return Boolean is
   begin
      for D of Dependencies.Items loop
         if D.Is_Cyclic
           and then ((D.From_Unit = A and then D.To_Unit = B)
                     or else (D.From_Unit = B and then D.To_Unit = A))
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Cycle;

   function Has_View_Barrier
     (Dependencies : Dependency_Model;
      A            : Unit_Id;
      B            : Unit_Id;
      Limited_View      : Boolean) return Boolean is
   begin
      for D of Dependencies.Items loop
         if D.From_Unit = A and then D.To_Unit = B then
            if Limited_View and then (D.Is_Limited_View or else D.Kind = Dependency_Limited_With) then
               return True;
            elsif not Limited_View and then (D.Is_Private_View or else D.Kind = Dependency_Private_With) then
               return True;
            end if;
         end if;
      end loop;
      return False;
   end Has_View_Barrier;

   function Status_For (R : Result_Info; C : Call_Info; Caller, Callee : Unit_Info;
                        Dependencies : Dependency_Model) return Elaboration_Status is
   begin
      if R.Missing_Caller_Blockers > 0 then
         return Elaboration_Missing_Caller;
      elsif R.Missing_Callee_Blockers > 0 then
         return Elaboration_Missing_Callee;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Elaboration_Source_Fingerprint_Mismatch;
      elsif R.Dependency_Fingerprint_Blockers > 0 then
         return Elaboration_Dependency_Fingerprint_Mismatch;
      elsif R.Cycle_Blockers > 0 then
         return Elaboration_Cycle;
      elsif R.Limited_View_Blockers > 0 then
         return Elaboration_Limited_View_Barrier;
      elsif R.Private_View_Blockers > 0 then
         return Elaboration_Private_View_Barrier;
      elsif R.Separate_Body_Blockers > 0 then
         return Elaboration_Separate_Body_Unlinked;
      elsif R.Generic_Body_Blockers > 0 then
         return Elaboration_Generic_Body_Unavailable;
      elsif R.Pure_Blockers > 0 then
         return Elaboration_Pure_Violation;
      elsif R.Preelaborate_Blockers > 0 then
         return Elaboration_Preelaborate_Violation;
      elsif R.Elaborate_All_Blockers > 0 then
         return Elaboration_Elaborate_All_Violation;
      elsif R.Missing_Body_Blockers > 0 then
         return Elaboration_Missing_Body;
      elsif R.Call_Before_Body_Blockers > 0 then
         return Elaboration_Call_Before_Body;
      elsif C.Requires_Elaborate_All
        or else Has_Dependency (Dependencies, Caller.Id, Callee.Id, Dependency_Elaborate_All)
      then
         return Elaboration_Legal_Elaborate_All_Pragma;
      elsif Caller.Has_Elaborate or else Callee.Has_Elaborate
        or else Has_Dependency (Dependencies, Caller.Id, Callee.Id, Dependency_Elaborate)
      then
         return Elaboration_Legal_Elaborate_Pragma;
      elsif C.Occurs_In_Pure_Unit or else Caller.Is_Pure then
         return Elaboration_Legal_Pure_Call;
      elsif C.Occurs_In_Preelaborated_Unit or else Caller.Is_Preelaborated then
         return Elaboration_Legal_Preelaborable_Call;
      elsif not C.Requires_Body_Before_Call then
         return Elaboration_Legal_No_Call;
      end if;
      return Elaboration_Legal_Body_Elaborated;
   end Status_For;

   function Build
     (Units        : Unit_Model;
      Dependencies : Dependency_Model;
      Calls        : Call_Model) return Result_Model
   is
      Result : Result_Model;
      Next_Id : Natural := 1;
   begin
      for C of Calls.Items loop
         declare
            Caller : constant Unit_Info := Find_Unit (Units, C.Caller);
            Callee : constant Unit_Info := Find_Unit (Units, C.Callee);
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            Next_Id := Next_Id + 1;
            R.Call := C.Id;
            R.Caller := C.Caller;
            R.Callee := C.Callee;
            R.Node := C.Node;

            if Caller.Id = No_Unit then
               R.Missing_Caller_Blockers := R.Missing_Caller_Blockers + 1;
            else
               R.Caller_Fingerprint := Caller.Source_Fingerprint;
            end if;

            if Callee.Id = No_Unit then
               R.Missing_Callee_Blockers := R.Missing_Callee_Blockers + 1;
            else
               R.Callee_Fingerprint := Callee.Source_Fingerprint;
               R.Dependency_Fingerprint := Callee.Dependency_Fingerprint;
            end if;

            if R.Missing_Caller_Blockers = 0 and then R.Missing_Callee_Blockers = 0 then
               if Caller.Source_Fingerprint = 0 or else Callee.Source_Fingerprint = 0
                 or else C.Source_Fingerprint = 0
                 or else (C.Expected_Caller_Fingerprint /= 0
                          and then C.Expected_Caller_Fingerprint /= Caller.Source_Fingerprint)
                 or else (C.Expected_Callee_Fingerprint /= 0
                          and then C.Expected_Callee_Fingerprint /= Callee.Source_Fingerprint)
               then
                  R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
               end if;

               if Callee.Dependency_Fingerprint = 0
                 or else (C.Expected_Dependency_Fingerprint /= 0
                          and then C.Expected_Dependency_Fingerprint /= Callee.Dependency_Fingerprint)
               then
                  R.Dependency_Fingerprint_Blockers := R.Dependency_Fingerprint_Blockers + 1;
               end if;

               if Has_Cycle (Dependencies, Caller.Id, Callee.Id) then
                  R.Cycle_Blockers := R.Cycle_Blockers + 1;
               end if;
               if Caller.Is_Limited_View or else Callee.Is_Limited_View
                 or else Has_View_Barrier (Dependencies, Caller.Id, Callee.Id, True)
               then
                  R.Limited_View_Blockers := R.Limited_View_Blockers + 1;
               end if;
               if Caller.Is_Private_View or else Callee.Is_Private_View
                 or else Has_View_Barrier (Dependencies, Caller.Id, Callee.Id, False)
               then
                  R.Private_View_Blockers := R.Private_View_Blockers + 1;
               end if;
               if C.Through_Separate_Body and then (not Callee.Separate_Linked
                 or else (Callee.Is_Separate_Body and then not Callee.Separate_Linked))
               then
                  R.Separate_Body_Blockers := R.Separate_Body_Blockers + 1;
               end if;
               if C.Through_Generic_Instance
                 and then (Callee.Is_Generic and then not Callee.Generic_Body_Available)
               then
                  R.Generic_Body_Blockers := R.Generic_Body_Blockers + 1;
               end if;
               if C.Occurs_In_Pure_Unit and then not Callee.Is_Pure then
                  R.Pure_Blockers := R.Pure_Blockers + 1;
               end if;
               if C.Occurs_In_Preelaborated_Unit
                 and then not Callee.Is_Pure
                 and then not Callee.Is_Preelaborated
               then
                  R.Preelaborate_Blockers := R.Preelaborate_Blockers + 1;
               end if;
               if C.Requires_Elaborate_All
                 and then not Has_Transitive_Elaborate_All (Dependencies, Caller.Id, Callee.Id)
                 and then not Callee.Has_Elaborate_All
               then
                  R.Elaborate_All_Blockers := R.Elaborate_All_Blockers + 1;
               end if;
               if C.Requires_Body_Before_Call and then not Callee.Has_Body then
                  R.Missing_Body_Blockers := R.Missing_Body_Blockers + 1;
               elsif C.Requires_Body_Before_Call
                 and then not Callee.Body_Elaborated_Before_Use
                 and then not Callee.Has_Elaborate
                 and then not Callee.Has_Elaborate_All
                 and then not Has_Dependency (Dependencies, Caller.Id, Callee.Id, Dependency_Elaborate)
                 and then not Has_Dependency (Dependencies, Caller.Id, Callee.Id, Dependency_Elaborate_All)
               then
                  R.Call_Before_Body_Blockers := R.Call_Before_Body_Blockers + 1;
               end if;
            end if;

            R.Status := Status_For (R, C, Caller, Callee, Dependencies);
            if Is_Legal (R.Status) then
               R.Message := To_Unbounded_String ("elaboration call accepted");
               Result.Legal_Total := Result.Legal_Total + 1;
            else
               R.Message := To_Unbounded_String ("elaboration call rejected");
               Result.Error_Total := Result.Error_Total + 1;
            end if;

            R.Detail := To_Unbounded_String
              ("missing_body=" & Natural'Image (R.Missing_Body_Blockers)
               & " call_before_body=" & Natural'Image (R.Call_Before_Body_Blockers)
               & " cycle=" & Natural'Image (R.Cycle_Blockers)
               & " elaborate_all=" & Natural'Image (R.Elaborate_All_Blockers));
            R.Fingerprint := Mix
              (R.Caller_Fingerprint + R.Callee_Fingerprint + R.Dependency_Fingerprint,
               Natural (Elaboration_Status'Pos (R.Status))
               + R.Missing_Caller_Blockers + R.Missing_Callee_Blockers
               + R.Missing_Body_Blockers + R.Call_Before_Body_Blockers
               + R.Cycle_Blockers + R.Elaborate_All_Blockers
               + R.Preelaborate_Blockers + R.Pure_Blockers
               + R.Limited_View_Blockers + R.Private_View_Blockers
               + R.Generic_Body_Blockers + R.Separate_Body_Blockers
               + R.Source_Fingerprint_Blockers
               + R.Dependency_Fingerprint_Blockers);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
            Result.Items.Append (R);
         end;
      end loop;
      return Result;
   end Build;

   function Unit_Count (Model : Unit_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Unit_Count;

   function Dependency_Count (Model : Dependency_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Dependency_Count;

   function Call_Count (Model : Call_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Call_Count;

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
      Status : Elaboration_Status) return Natural is
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

end Editor.Ada_Elaboration_Vertical_Slice_Legality;
