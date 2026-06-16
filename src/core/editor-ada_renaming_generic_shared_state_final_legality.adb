with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Renaming_Generic_Shared_State_Final_Legality is

   pragma Suppress (Overflow_Check);
   use type Renaming_Base.Renaming_Legality_Id;
   use type Cross_Generic.Cross_Unit_Generic_Final_Row_Id;
   use type Elab_Generic.Elaboration_Generic_Final_Row_Id;
   use type Generic_Replay.Generic_Abstract_Replay_Row_Id;
   use type Overload_Generic.Overload_Generic_Final_Row_Id;
   use type Rep_Generic.Representation_Generic_Final_Row_Id;
   use type Tasking_Generic.Tasking_Generic_Final_Row_Id;
   use type Access_Generic.Accessibility_Generic_Final_Row_Id;
   use type Disc_Generic.Discriminant_Generic_Final_Row_Id;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 23) mod 2_147_483_647;
   end Mix;

   function Renaming_Status_Is_Legal (Status : Renaming_Base.Renaming_Legality_Status) return Boolean is
   begin
      case Status is
         when Renaming_Base.Renaming_Legality_Legal_Object_Renaming |
              Renaming_Base.Renaming_Legality_Legal_Exception_Renaming |
              Renaming_Base.Renaming_Legality_Legal_Package_Renaming |
              Renaming_Base.Renaming_Legality_Legal_Subprogram_Renaming |
              Renaming_Base.Renaming_Legality_Legal_Generic_Renaming |
              Renaming_Base.Renaming_Legality_Legal_Use_Package |
              Renaming_Base.Renaming_Legality_Legal_Use_Type |
              Renaming_Base.Renaming_Legality_Legal_Selected_Alias =>
            return True;
         when others =>
            return False;
      end case;
   end Renaming_Status_Is_Legal;

   function Is_Accepted (Status : Renaming_Generic_Final_Status) return Boolean is
   begin
      return Status in Renaming_Generic_Final_Legal_Object_Renaming_Accepted ..
                       Renaming_Generic_Final_Legal_Cross_Unit_Alias_Accepted;
   end Is_Accepted;

   function Is_Blocked (Status : Renaming_Generic_Final_Status) return Boolean is
   begin
      return Status in Renaming_Generic_Final_Missing_Renaming_Alias_Row ..
                       Renaming_Generic_Final_Indeterminate;
   end Is_Blocked;

   function Blocks_Downstream (Status : Renaming_Generic_Final_Status) return Boolean is
   begin
      return Is_Blocked (Status);
   end Blocks_Downstream;

   function Accepted_For (Kind : Renaming_Generic_Final_Kind) return Renaming_Generic_Final_Status is
   begin
      case Kind is
         when Renaming_Generic_Final_Object_Renaming => return Renaming_Generic_Final_Legal_Object_Renaming_Accepted;
         when Renaming_Generic_Final_Exception_Renaming => return Renaming_Generic_Final_Legal_Exception_Renaming_Accepted;
         when Renaming_Generic_Final_Package_Renaming => return Renaming_Generic_Final_Legal_Package_Renaming_Accepted;
         when Renaming_Generic_Final_Subprogram_Renaming => return Renaming_Generic_Final_Legal_Subprogram_Renaming_Accepted;
         when Renaming_Generic_Final_Generic_Renaming => return Renaming_Generic_Final_Legal_Generic_Renaming_Accepted;
         when Renaming_Generic_Final_Use_Package => return Renaming_Generic_Final_Legal_Use_Package_Accepted;
         when Renaming_Generic_Final_Use_Type => return Renaming_Generic_Final_Legal_Use_Type_Accepted;
         when Renaming_Generic_Final_Selected_Alias => return Renaming_Generic_Final_Legal_Selected_Alias_Accepted;
         when Renaming_Generic_Final_Alias_Redirection => return Renaming_Generic_Final_Legal_Alias_Redirection_Accepted;
         when Renaming_Generic_Final_Homograph_Visibility => return Renaming_Generic_Final_Legal_Homograph_Visibility_Accepted;
         when Renaming_Generic_Final_Accessibility_Alias => return Renaming_Generic_Final_Legal_Accessibility_Alias_Accepted;
         when Renaming_Generic_Final_Dispatching_Alias => return Renaming_Generic_Final_Legal_Dispatching_Alias_Accepted;
         when Renaming_Generic_Final_Global_Depends_Alias => return Renaming_Generic_Final_Legal_Global_Depends_Alias_Accepted;
         when Renaming_Generic_Final_Generic_Replay => return Renaming_Generic_Final_Legal_Generic_Replay_Accepted;
         when Renaming_Generic_Final_Cross_Unit_Alias => return Renaming_Generic_Final_Legal_Cross_Unit_Alias_Accepted;
         when Renaming_Generic_Final_Unknown => return Renaming_Generic_Final_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Renaming_Generic_Final_Status) return Renaming_Generic_Final_Blocker_Family is
   begin
      case Status is
         when Renaming_Generic_Final_Not_Checked |
              Renaming_Generic_Final_Legal_Object_Renaming_Accepted ..
              Renaming_Generic_Final_Legal_Cross_Unit_Alias_Accepted =>
            return Renaming_Generic_Final_Blocker_None;
         when Renaming_Generic_Final_Missing_Renaming_Alias_Row |
              Renaming_Generic_Final_Renaming_Alias_Blocker =>
            return Renaming_Generic_Final_Blocker_Renaming_Alias_Visibility;
         when Renaming_Generic_Final_Missing_Cross_Unit_Generic_Row |
              Renaming_Generic_Final_Cross_Unit_Generic_Blocker =>
            return Renaming_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State;
         when Renaming_Generic_Final_Missing_Elaboration_Generic_Row |
              Renaming_Generic_Final_Elaboration_Generic_Blocker =>
            return Renaming_Generic_Final_Blocker_Elaboration_Generic_Shared_State;
         when Renaming_Generic_Final_Missing_Generic_Replay_Row |
              Renaming_Generic_Final_Generic_Replay_Blocker =>
            return Renaming_Generic_Final_Blocker_Generic_Abstract_Replay;
         when Renaming_Generic_Final_Missing_Overload_Generic_Row |
              Renaming_Generic_Final_Overload_Generic_Blocker =>
            return Renaming_Generic_Final_Blocker_Overload_Generic_Shared_State;
         when Renaming_Generic_Final_Missing_Representation_Generic_Row |
              Renaming_Generic_Final_Representation_Generic_Blocker =>
            return Renaming_Generic_Final_Blocker_Representation_Generic_Shared_State;
         when Renaming_Generic_Final_Missing_Tasking_Generic_Row |
              Renaming_Generic_Final_Tasking_Generic_Blocker =>
            return Renaming_Generic_Final_Blocker_Tasking_Generic_Shared_State;
         when Renaming_Generic_Final_Missing_Accessibility_Generic_Row |
              Renaming_Generic_Final_Accessibility_Generic_Blocker =>
            return Renaming_Generic_Final_Blocker_Accessibility_Generic_Shared_State;
         when Renaming_Generic_Final_Missing_Discriminant_Generic_Row |
              Renaming_Generic_Final_Discriminant_Generic_Blocker =>
            return Renaming_Generic_Final_Blocker_Discriminant_Generic_Shared_State;
         when Renaming_Generic_Final_Missing_Stabilized_Closure_Row |
              Renaming_Generic_Final_Stabilized_Closure_Blocker =>
            return Renaming_Generic_Final_Blocker_Stabilized_Shared_State_Closure;
         when Renaming_Generic_Final_Target_Resolution_Blocker => return Renaming_Generic_Final_Blocker_Target_Resolution;
         when Renaming_Generic_Final_Visibility_Blocker => return Renaming_Generic_Final_Blocker_Visibility;
         when Renaming_Generic_Final_Alias_Lifetime_Blocker => return Renaming_Generic_Final_Blocker_Alias_Lifetime;
         when Renaming_Generic_Final_Homograph_Hiding_Blocker => return Renaming_Generic_Final_Blocker_Homograph_Hiding;
         when Renaming_Generic_Final_Profile_Conformance_Blocker => return Renaming_Generic_Final_Blocker_Profile_Conformance;
         when Renaming_Generic_Final_Generic_Renaming_Blocker => return Renaming_Generic_Final_Blocker_Generic_Renaming;
         when Renaming_Generic_Final_Use_Clause_Blocker => return Renaming_Generic_Final_Blocker_Use_Clause;
         when Renaming_Generic_Final_Accessibility_Alias_Blocker => return Renaming_Generic_Final_Blocker_Accessibility_Alias;
         when Renaming_Generic_Final_Discriminant_Alias_Blocker => return Renaming_Generic_Final_Blocker_Discriminant_Alias;
         when Renaming_Generic_Final_Representation_Alias_Blocker => return Renaming_Generic_Final_Blocker_Representation_Alias;
         when Renaming_Generic_Final_Source_Fingerprint_Mismatch => return Renaming_Generic_Final_Blocker_Source_Fingerprint;
         when Renaming_Generic_Final_Substitution_Fingerprint_Mismatch => return Renaming_Generic_Final_Blocker_Substitution_Fingerprint;
         when Renaming_Generic_Final_Multiple_Blockers => return Renaming_Generic_Final_Blocker_Multiple;
         when Renaming_Generic_Final_Indeterminate => return Renaming_Generic_Final_Blocker_Indeterminate;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Renaming_Generic_Final_Context) return Natural is
      N : Natural := 0;
   begin
      if C.Target_Resolution_Blocker then N := N + 1; end if;
      if C.Visibility_Blocker then N := N + 1; end if;
      if C.Alias_Lifetime_Blocker then N := N + 1; end if;
      if C.Homograph_Hiding_Blocker then N := N + 1; end if;
      if C.Profile_Conformance_Blocker then N := N + 1; end if;
      if C.Generic_Renaming_Blocker then N := N + 1; end if;
      if C.Use_Clause_Blocker then N := N + 1; end if;
      if C.Accessibility_Alias_Blocker then N := N + 1; end if;
      if C.Discriminant_Alias_Blocker then N := N + 1; end if;
      if C.Representation_Alias_Blocker then N := N + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then N := N + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then N := N + 1; end if;
      return N;
   end Local_Blocker_Count;

   function Classify (C : Renaming_Generic_Final_Context) return Renaming_Generic_Final_Status is
      Local_N : constant Natural := Local_Blocker_Count (C);
   begin
      if Local_N > 1 then return Renaming_Generic_Final_Multiple_Blockers;
      elsif C.Target_Resolution_Blocker then return Renaming_Generic_Final_Target_Resolution_Blocker;
      elsif C.Visibility_Blocker then return Renaming_Generic_Final_Visibility_Blocker;
      elsif C.Alias_Lifetime_Blocker then return Renaming_Generic_Final_Alias_Lifetime_Blocker;
      elsif C.Homograph_Hiding_Blocker then return Renaming_Generic_Final_Homograph_Hiding_Blocker;
      elsif C.Profile_Conformance_Blocker then return Renaming_Generic_Final_Profile_Conformance_Blocker;
      elsif C.Generic_Renaming_Blocker then return Renaming_Generic_Final_Generic_Renaming_Blocker;
      elsif C.Use_Clause_Blocker then return Renaming_Generic_Final_Use_Clause_Blocker;
      elsif C.Accessibility_Alias_Blocker then return Renaming_Generic_Final_Accessibility_Alias_Blocker;
      elsif C.Discriminant_Alias_Blocker then return Renaming_Generic_Final_Discriminant_Alias_Blocker;
      elsif C.Representation_Alias_Blocker then return Renaming_Generic_Final_Representation_Alias_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then return Renaming_Generic_Final_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then return Renaming_Generic_Final_Substitution_Fingerprint_Mismatch;
      elsif C.Renaming_Base_Row = Renaming_Base.No_Renaming_Legality then return Renaming_Generic_Final_Missing_Renaming_Alias_Row;
      elsif not Renaming_Status_Is_Legal (C.Renaming_Base_Status) then return Renaming_Generic_Final_Renaming_Alias_Blocker;
      elsif C.Cross_Generic_Row = Cross_Generic.No_Cross_Unit_Generic_Final_Row then return Renaming_Generic_Final_Missing_Cross_Unit_Generic_Row;
      elsif not Cross_Generic.Is_Accepted (C.Cross_Generic_Status) then return Renaming_Generic_Final_Cross_Unit_Generic_Blocker;
      elsif C.Requires_Elaboration_Generic and then C.Elaboration_Generic_Row = Elab_Generic.No_Elaboration_Generic_Final_Row then return Renaming_Generic_Final_Missing_Elaboration_Generic_Row;
      elsif C.Requires_Elaboration_Generic and then not Elab_Generic.Is_Accepted (C.Elaboration_Generic_Status) then return Renaming_Generic_Final_Elaboration_Generic_Blocker;
      elsif C.Requires_Generic_Replay and then C.Generic_Replay_Row = Generic_Replay.No_Generic_Abstract_Replay_Row then return Renaming_Generic_Final_Missing_Generic_Replay_Row;
      elsif C.Requires_Generic_Replay and then not Generic_Replay.Is_Accepted (C.Generic_Replay_Status) then return Renaming_Generic_Final_Generic_Replay_Blocker;
      elsif C.Requires_Overload_Generic and then C.Overload_Generic_Row = Overload_Generic.No_Overload_Generic_Final_Row then return Renaming_Generic_Final_Missing_Overload_Generic_Row;
      elsif C.Requires_Overload_Generic and then not Overload_Generic.Is_Accepted (C.Overload_Generic_Status) then return Renaming_Generic_Final_Overload_Generic_Blocker;
      elsif C.Requires_Representation_Generic and then C.Representation_Generic_Row = Rep_Generic.No_Representation_Generic_Final_Row then return Renaming_Generic_Final_Missing_Representation_Generic_Row;
      elsif C.Requires_Representation_Generic and then not Rep_Generic.Is_Accepted (C.Representation_Generic_Status) then return Renaming_Generic_Final_Representation_Generic_Blocker;
      elsif C.Requires_Tasking_Generic and then C.Tasking_Generic_Row = Tasking_Generic.No_Tasking_Generic_Final_Row then return Renaming_Generic_Final_Missing_Tasking_Generic_Row;
      elsif C.Requires_Tasking_Generic and then not Tasking_Generic.Is_Accepted (C.Tasking_Generic_Status) then return Renaming_Generic_Final_Tasking_Generic_Blocker;
      elsif C.Requires_Accessibility_Generic and then C.Accessibility_Generic_Row = Access_Generic.No_Accessibility_Generic_Final_Row then return Renaming_Generic_Final_Missing_Accessibility_Generic_Row;
      elsif C.Requires_Accessibility_Generic and then not Access_Generic.Is_Accepted (C.Accessibility_Generic_Status) then return Renaming_Generic_Final_Accessibility_Generic_Blocker;
      elsif C.Requires_Discriminant_Generic and then C.Discriminant_Generic_Row = Disc_Generic.No_Discriminant_Generic_Final_Row then return Renaming_Generic_Final_Missing_Discriminant_Generic_Row;
      elsif C.Requires_Discriminant_Generic and then not Disc_Generic.Is_Accepted (C.Discriminant_Generic_Status) then return Renaming_Generic_Final_Discriminant_Generic_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then return Renaming_Generic_Final_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not (C.Stabilized_Closure_Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current or else C.Stabilized_Closure_Status = Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required) then return Renaming_Generic_Final_Stabilized_Closure_Blocker;
      else return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Row_Fingerprint (Row : Renaming_Generic_Final_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Renaming_Generic_Final_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Renaming_Generic_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Renaming_Generic_Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for Ch of Text loop H := Mix (H, Character'Pos (Ch)); end loop;
      return H;
   end Row_Fingerprint;

   function Build_Row (C : Renaming_Generic_Final_Context) return Renaming_Generic_Final_Row is
      Status : constant Renaming_Generic_Final_Status := Classify (C);
      Family : constant Renaming_Generic_Final_Blocker_Family := Family_For (Status);
      Row : Renaming_Generic_Final_Row;
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Renaming_Name := C.Renaming_Name;
      Row.Object_Name := C.Object_Name;
      Row.Type_Name := C.Type_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.State_Name := C.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Blocks_Downstream (Status);
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Row.Blocked and then Row.Blocker_Count = 0 then Row.Blocker_Count := 1; end if;
      Row.Start_Line := C.Start_Line; Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line; Row.End_Column := C.End_Column;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Substitution_Fingerprint := C.Substitution_Fingerprint;
      Row.Message := To_Unbounded_String
        ("renaming/alias visibility generic shared-state final legality " &
         Renaming_Generic_Final_Status'Image (Status) &
         " kind=" & Renaming_Generic_Final_Kind'Image (C.Kind) &
         " blocker=" & Renaming_Generic_Final_Blocker_Family'Image (Family));
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Build_Row;

   procedure Clear (Model : in out Renaming_Generic_Final_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Renaming_Generic_Final_Context_Model; Info : Renaming_Generic_Final_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Renaming_Generic_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Build (Contexts : Renaming_Generic_Final_Context_Model) return Renaming_Generic_Final_Model is
      Result : Renaming_Generic_Final_Model;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Renaming_Generic_Final_Row := Build_Row (C);
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Renaming_Generic_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Renaming_Generic_Final_Model; Index : Positive) return Renaming_Generic_Final_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Accepted_Count (Model : Renaming_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Accepted then N := N + 1; end if; end loop;
      return N;
   end Accepted_Count;

   function Blocked_Count (Model : Renaming_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Blocked then N := N + 1; end if; end loop;
      return N;
   end Blocked_Count;

   function Indeterminate_Count (Model : Renaming_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Status = Renaming_Generic_Final_Indeterminate then N := N + 1; end if; end loop;
      return N;
   end Indeterminate_Count;

   function Count_By_Status (Model : Renaming_Generic_Final_Model; Status : Renaming_Generic_Final_Status) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Status = Status then N := N + 1; end if; end loop;
      return N;
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Renaming_Generic_Final_Model; Family : Renaming_Generic_Final_Blocker_Family) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Blocker_Family = Family then N := N + 1; end if; end loop;
      return N;
   end Count_By_Blocker_Family;

   function Find_By_Node (Model : Renaming_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Renaming_Generic_Final_Set is
      Result : Renaming_Generic_Final_Set;
   begin
      for R of Model.Rows loop if R.Node = Node then Result.Rows.Append (R); end if; end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Renaming_Generic_Final_Model; Fingerprint : Natural) return Renaming_Generic_Final_Set is
      Result : Renaming_Generic_Final_Set;
   begin
      for R of Model.Rows loop if R.Source_Fingerprint = Fingerprint then Result.Rows.Append (R); end if; end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Query_Blocker_Family (Model : Renaming_Generic_Final_Model; Family : Renaming_Generic_Final_Blocker_Family) return Renaming_Generic_Final_Set is
      Result : Renaming_Generic_Final_Set;
   begin
      for R of Model.Rows loop if R.Blocker_Family = Family then Result.Rows.Append (R); end if; end loop;
      return Result;
   end Query_Blocker_Family;

   function Query_Count (Set : Renaming_Generic_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_Row_At (Set : Renaming_Generic_Final_Set; Index : Positive) return Renaming_Generic_Final_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_Row_At;

   function Stable_Fingerprint (Model : Renaming_Generic_Final_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Renaming_Generic_Shared_State_Final_Legality;
