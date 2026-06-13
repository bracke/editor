with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1328) mod 1_000_000_007;
   end Mix;

   function Is_Discrete_Kind (Kind : Type_Kind) return Boolean is
   begin
      return Kind = Type_Discrete
        or else Kind = Type_Integer
        or else Kind = Type_Enumeration
        or else Kind = Type_Boolean;
   end Is_Discrete_Kind;

   function Same_Type_Family (Left, Right : Type_Info) return Boolean is
   begin
      if Left.Id = No_Type or else Right.Id = No_Type then
         return False;
      elsif Left.Id = Right.Id then
         return True;
      elsif Left.Base_Type /= No_Type and then Left.Base_Type = Right.Base_Type then
         return True;
      elsif Left.Kind = Right.Kind then
         return True;
      else
         return False;
      end if;
   end Same_Type_Family;

   function Find_Entity (Model : Entity_Model; Id : Entity_Id) return Entity_Info is
   begin
      for E of Model.Items loop
         if E.Id = Id then
            return E;
         end if;
      end loop;
      return (others => <>);
   end Find_Entity;

   function Find_Type (Model : Type_Model; Id : Type_Id) return Type_Info is
   begin
      for T of Model.Items loop
         if T.Id = Id then
            return T;
         end if;
      end loop;
      return (others => <>);
   end Find_Type;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Check_Blockers
        + R.Missing_Iterator_Blockers
        + R.Missing_Container_Blockers
        + R.Missing_Loop_Parameter_Blockers
        + R.Missing_Discrete_Subtype_Blockers
        + R.Missing_Element_Type_Blockers
        + R.Missing_Reduction_Profile_Blockers
        + R.Iterator_Kind_Blockers
        + R.Discrete_Subtype_Blockers
        + R.Range_Blockers
        + R.Loop_Parameter_Mode_Blockers
        + R.Element_Type_Blockers
        + R.Cursor_Profile_Blockers
        + R.Iterator_Profile_Blockers
        + R.Reversible_Iterator_Blockers
        + R.Parallel_Blockers
        + R.Shared_State_Blockers
        + R.Tampering_Blockers
        + R.Reduction_Profile_Blockers
        + R.Reduction_Seed_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers
        + R.Profile_Fingerprint_Blockers
        + R.Effect_Fingerprint_Blockers;
   end Blocker_Count;

   procedure Add_View_Blocker (View : View_Kind; R : in out Result_Info) is
   begin
      case View is
         when View_Private =>
            R.Private_View_Blockers := 1;
         when View_Limited =>
            R.Limited_View_Blockers := 1;
         when View_Incomplete =>
            R.Incomplete_View_Blockers := 1;
         when View_Generic_Formal =>
            R.Generic_Formal_View_Blockers := 1;
         when others =>
            null;
      end case;
   end Add_View_Blocker;

   procedure Add_Fingerprint_Blockers (C : Check_Info; R : in out Result_Info) is
   begin
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if C.AST_Fingerprint /= C.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if C.Type_Fingerprint /= C.Expected_Type_Fingerprint then
         R.Type_Fingerprint_Blockers := 1;
      end if;
      if C.Profile_Fingerprint /= C.Expected_Profile_Fingerprint then
         R.Profile_Fingerprint_Blockers := 1;
      end if;
      if C.Effect_Fingerprint /= C.Expected_Effect_Fingerprint then
         R.Effect_Fingerprint_Blockers := 1;
      end if;
   end Add_Fingerprint_Blockers;

   procedure Add_Entity_Evidence_Blockers (E : Entity_Info; R : in out Result_Info) is
   begin
      if E.Id = No_Entity then
         return;
      end if;
      Add_View_Blocker (E.View, R);
      if E.Source_Fingerprint /= E.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if E.Type_Fingerprint /= E.Expected_Type_Fingerprint then
         R.Type_Fingerprint_Blockers := 1;
      end if;
   end Add_Entity_Evidence_Blockers;

   procedure Add_Type_Evidence_Blockers (T : Type_Info; R : in out Result_Info) is
   begin
      if T.Id = No_Type then
         return;
      end if;
      Add_View_Blocker (T.View, R);
      if T.Source_Fingerprint /= T.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if T.Type_Fingerprint /= T.Expected_Type_Fingerprint then
         R.Type_Fingerprint_Blockers := 1;
      end if;
      if T.Profile_Fingerprint /= T.Expected_Profile_Fingerprint then
         R.Profile_Fingerprint_Blockers := 1;
      end if;
   end Add_Type_Evidence_Blockers;

   function Status_For (R : Result_Info) return Legality_Status is
      Count : constant Natural := Blocker_Count (R);
   begin
      if Count = 0 then
         if R.Runtime_Check_Count > 0 then
            return Legality_Legal_With_Runtime_Check;
         else
            return Legality_Legal;
         end if;
      elsif Count > 1 then
         return Legality_Multiple_Blockers;
      elsif R.Missing_Check_Blockers > 0 then
         return Legality_Missing_Check;
      elsif R.Missing_Iterator_Blockers > 0 then
         return Legality_Missing_Iterator;
      elsif R.Missing_Container_Blockers > 0 then
         return Legality_Missing_Container;
      elsif R.Missing_Loop_Parameter_Blockers > 0 then
         return Legality_Missing_Loop_Parameter;
      elsif R.Missing_Discrete_Subtype_Blockers > 0 then
         return Legality_Missing_Discrete_Subtype;
      elsif R.Missing_Element_Type_Blockers > 0 then
         return Legality_Missing_Element_Type;
      elsif R.Missing_Reduction_Profile_Blockers > 0 then
         return Legality_Missing_Reduction_Profile;
      elsif R.Iterator_Kind_Blockers > 0 then
         return Legality_Iterator_Kind_Mismatch;
      elsif R.Discrete_Subtype_Blockers > 0 then
         return Legality_Discrete_Subtype_Required;
      elsif R.Range_Blockers > 0 then
         return Legality_Range_Bounds_Invalid;
      elsif R.Loop_Parameter_Mode_Blockers > 0 then
         return Legality_Loop_Parameter_Mode_Invalid;
      elsif R.Element_Type_Blockers > 0 then
         return Legality_Element_Type_Mismatch;
      elsif R.Cursor_Profile_Blockers > 0 then
         return Legality_Cursor_Profile_Mismatch;
      elsif R.Iterator_Profile_Blockers > 0 then
         return Legality_Iterator_Profile_Mismatch;
      elsif R.Reversible_Iterator_Blockers > 0 then
         return Legality_Reversible_Iterator_Required;
      elsif R.Parallel_Blockers > 0 then
         return Legality_Parallel_Not_Allowed;
      elsif R.Shared_State_Blockers > 0 then
         return Legality_Shared_State_Blocker;
      elsif R.Tampering_Blockers > 0 then
         return Legality_Tampering_Blocker;
      elsif R.Reduction_Profile_Blockers > 0 then
         return Legality_Reduction_Profile_Blocker;
      elsif R.Reduction_Seed_Blockers > 0 then
         return Legality_Reduction_Seed_Blocker;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Legality_Incomplete_View_Barrier;
      elsif R.Generic_Formal_View_Blockers > 0 then
         return Legality_Generic_Formal_View_Barrier;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Legality_Type_Fingerprint_Mismatch;
      elsif R.Profile_Fingerprint_Blockers > 0 then
         return Legality_Profile_Fingerprint_Mismatch;
      elsif R.Effect_Fingerprint_Blockers > 0 then
         return Legality_Effect_Fingerprint_Mismatch;
      else
         return Legality_Indeterminate;
      end if;
   end Status_For;

   procedure Clear (Model : in out Entity_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Type_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Check_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Entity (Model : in out Entity_Model; Info : Entity_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Typ));
   end Add_Entity;

   procedure Add_Type (Model : in out Type_Model; Info : Type_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Type_Kind'Pos (Info.Kind)));
   end Add_Type;

   procedure Add_Check (Model : in out Check_Model; Info : Check_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Iteration_Kind'Pos (Info.Kind)));
   end Add_Check;

   function Build
     (Entities : Entity_Model;
      Types : Type_Model;
      Checks : Check_Model) return Result_Model
   is
      Results : Result_Model;
   begin
      for C of Checks.Items loop
         declare
            Loop_Param : constant Entity_Info := Find_Entity (Entities, C.Loop_Parameter);
            Iter_Entity : constant Entity_Info := Find_Entity (Entities, C.Iterator_Entity);
            Container : constant Entity_Info := Find_Entity (Entities, C.Container_Entity);
            Discrete_T : constant Type_Info := Find_Type (Types, C.Discrete_Subtype);
            Expected_T : constant Type_Info := Find_Type (Types, C.Expected_Element_Type);
            Actual_T : constant Type_Info := Find_Type (Types, C.Actual_Element_Type);
            Cursor_T : constant Type_Info := Find_Type (Types, C.Cursor_Type);
            Reduction_Result_T : constant Type_Info := Find_Type (Types, C.Reduction_Result_Type);
            Reduction_Seed_T : constant Type_Info := Find_Type (Types, C.Reduction_Seed_Type);
            R : Result_Info;
         begin
            R.Id := Result_Id (Natural (C.Id));
            R.Check := C.Id;
            R.Kind := C.Kind;

            if C.Id = No_Check or else C.Kind = Iteration_Unknown then
               R.Missing_Check_Blockers := 1;
            end if;

            Add_Fingerprint_Blockers (C, R);

            if C.Loop_Parameter = No_Entity then
               R.Missing_Loop_Parameter_Blockers := 1;
            else
               Add_Entity_Evidence_Blockers (Loop_Param, R);
               if Loop_Param.Id = No_Entity then
                  R.Missing_Loop_Parameter_Blockers := 1;
               elsif not C.Loop_Parameter_Mode_OK
                 or else not Loop_Param.Is_Loop_Parameter
                 or else Loop_Param.Is_Variable_View
               then
                  R.Loop_Parameter_Mode_Blockers := 1;
               end if;
            end if;

            if C.Kind = Iteration_Discrete_Subtype
              or else C.Kind = Iteration_Discrete_Range
              or else C.Kind = Iteration_Parallel_Discrete
            then
               if C.Discrete_Subtype = No_Type or else Discrete_T.Id = No_Type then
                  R.Missing_Discrete_Subtype_Blockers := 1;
               else
                  Add_Type_Evidence_Blockers (Discrete_T, R);
                  if not Discrete_T.Is_Discrete
                    and then not Is_Discrete_Kind (Discrete_T.Kind)
                  then
                     R.Discrete_Subtype_Blockers := 1;
                  end if;
               end if;
               if not C.Range_Bounds_Static or else not C.Range_Bounds_Compatible then
                  R.Range_Blockers := 1;
               end if;
            end if;

            if C.Kind = Iteration_Generalized_Iterator
              or else C.Kind = Iteration_Parallel_Iterator
            then
               if C.Iterator_Entity = No_Entity or else Iter_Entity.Id = No_Entity then
                  R.Missing_Iterator_Blockers := 1;
               else
                  declare
                     Iter_T : constant Type_Info := Find_Type (Types, Iter_Entity.Typ);
                  begin
                     Add_Entity_Evidence_Blockers (Iter_Entity, R);
                     Add_Type_Evidence_Blockers (Iter_T, R);
                     if Iter_T.Id = No_Type
                       or else not Iter_T.Is_Iterator
                     then
                        R.Iterator_Kind_Blockers := 1;
                     end if;
                     if not C.Iterator_Profile_OK
                       or else not Iter_T.Has_First_Next_Profile
                     then
                        R.Iterator_Profile_Blockers := 1;
                     end if;
                     if C.Requires_Reversible_Iterator
                       and then not Iter_T.Is_Reversible_Iterator
                     then
                        R.Reversible_Iterator_Blockers := 1;
                     end if;
                     if C.Is_Parallel and then not Iter_T.Allows_Parallel_Iteration then
                        R.Parallel_Blockers := 1;
                     end if;
                     if Iter_T.Element_Type /= No_Type
                       and then C.Actual_Element_Type = No_Type
                     then
                        if C.Expected_Element_Type /= No_Type then
                           declare
                              It_Element_T : constant Type_Info := Find_Type (Types, Iter_T.Element_Type);
                           begin
                              if not Same_Type_Family (Expected_T, It_Element_T) then
                                 R.Element_Type_Blockers := 1;
                              end if;
                           end;
                        end if;
                     end if;
                  end;
               end if;
            end if;

            if C.Kind = Iteration_Container_Element
              or else C.Kind = Iteration_Container_Cursor
            then
               if C.Container_Entity = No_Entity or else Container.Id = No_Entity then
                  R.Missing_Container_Blockers := 1;
               else
                  declare
                     Container_T : constant Type_Info := Find_Type (Types, Container.Typ);
                  begin
                     Add_Entity_Evidence_Blockers (Container, R);
                     Add_Type_Evidence_Blockers (Container_T, R);
                     if Container_T.Id = No_Type or else not Container_T.Is_Container then
                        R.Iterator_Kind_Blockers := 1;
                     end if;
                     if not Container_T.Has_Element_Profile
                       or else not Container_T.Has_Has_Element_Profile
                     then
                        R.Iterator_Profile_Blockers := 1;
                     end if;
                     if C.Kind = Iteration_Container_Cursor then
                        if C.Cursor_Type = No_Type
                          or else Container_T.Cursor_Type = No_Type
                          or else not C.Cursor_Profile_OK
                          or else not Same_Type_Family (Cursor_T, Find_Type (Types, Container_T.Cursor_Type))
                        then
                           R.Cursor_Profile_Blockers := 1;
                        end if;
                     end if;
                     if C.Expected_Element_Type /= No_Type then
                        declare
                           Container_Element_T : constant Type_Info := Find_Type (Types, Container_T.Element_Type);
                        begin
                           if Container_Element_T.Id = No_Type then
                              R.Missing_Element_Type_Blockers := 1;
                           elsif not C.Element_Type_OK
                             or else not Same_Type_Family (Expected_T, Container_Element_T)
                           then
                              R.Element_Type_Blockers := 1;
                           end if;
                        end;
                     end if;
                     if C.Is_Parallel and then not Container_T.Allows_Parallel_Iteration then
                        R.Parallel_Blockers := 1;
                     end if;
                     if Container_T.Tampering_Check_Required then
                        R.Runtime_Check_Count := R.Runtime_Check_Count + 1;
                     end if;
                  end;
               end if;
            end if;

            if C.Kind = Iteration_Array_Component then
               if C.Discrete_Subtype = No_Type or else Discrete_T.Id = No_Type then
                  R.Missing_Discrete_Subtype_Blockers := 1;
               else
                  Add_Type_Evidence_Blockers (Discrete_T, R);
                  if not Is_Discrete_Kind (Discrete_T.Kind) and then not Discrete_T.Is_Discrete then
                     R.Discrete_Subtype_Blockers := 1;
                  end if;
               end if;
               if C.Expected_Element_Type = No_Type or else C.Actual_Element_Type = No_Type then
                  R.Missing_Element_Type_Blockers := 1;
               else
                  Add_Type_Evidence_Blockers (Expected_T, R);
                  Add_Type_Evidence_Blockers (Actual_T, R);
                  if not C.Element_Type_OK or else not Same_Type_Family (Expected_T, Actual_T) then
                     R.Element_Type_Blockers := 1;
                  end if;
               end if;
            end if;

            if C.Kind = Iteration_Reduction then
               if C.Reduction_Result_Type = No_Type then
                  R.Missing_Reduction_Profile_Blockers := 1;
               else
                  Add_Type_Evidence_Blockers (Reduction_Result_T, R);
                  if not C.Reduction_Profile_OK then
                     R.Reduction_Profile_Blockers := 1;
                  end if;
                  if C.Reduction_Seed_Type = No_Type
                    or else Reduction_Seed_T.Id = No_Type
                    or else not C.Reduction_Seed_OK
                    or else not Same_Type_Family (Reduction_Result_T, Reduction_Seed_T)
                  then
                     R.Reduction_Seed_Blockers := 1;
                  end if;
               end if;
            end if;

            if C.Is_Parallel then
               if not C.Parallel_Allowed then
                  R.Parallel_Blockers := 1;
               end if;
               if not C.Shared_State_OK
                 or else Loop_Param.Writes_Shared_State
                 or else Iter_Entity.Writes_Shared_State
                 or else Container.Writes_Shared_State
                 or else Loop_Param.Has_Shared_State_Access
               then
                  R.Shared_State_Blockers := 1;
               end if;
            end if;

            if not C.Tampering_OK then
               R.Tampering_Blockers := 1;
            end if;
            if C.Runtime_Bounds_Check_Required then
               R.Runtime_Check_Count := R.Runtime_Check_Count + 1;
            end if;
            if C.Runtime_Tampering_Check_Required then
               R.Runtime_Check_Count := R.Runtime_Check_Count + 1;
            end if;

            R.Status := Status_For (R);
            R.Fingerprint := Mix (Natural (R.Id), Natural (Legality_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));
            R.Fingerprint := Mix (R.Fingerprint, R.Runtime_Check_Count);
            R.Message := To_Unbounded_String ("iterator/loop/parallel vertical slice");
            R.Detail := To_Unbounded_String (Legality_Status'Image (R.Status));
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
         end;
      end loop;
      return Results;
   end Build;

   function Entity_Count (Model : Entity_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Entity_Count;

   function Type_Count (Model : Type_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Type_Count;

   function Check_Count (Model : Check_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Check_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items.Element (Index);
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
         if R.Status = Legality_Legal
           or else R.Status = Legality_Legal_With_Runtime_Check
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status /= Legality_Legal
           and then R.Status /= Legality_Legal_With_Runtime_Check
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
      return Info.Id /= No_Result and then Info.Status /= Legality_Not_Checked;
   end Has_Result;

end Editor.Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality;
