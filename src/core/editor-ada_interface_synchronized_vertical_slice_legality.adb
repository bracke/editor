package body Editor.Ada_Interface_Synchronized_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1332) mod 1_000_000_007;
   end Mix;

   function Find_Type (Model : Type_Model; Id : Type_Id) return Interface_Type_Info is
   begin
      for T of Model.Items loop
         if T.Id = Id then
            return T;
         end if;
      end loop;
      return (others => <>);
   end Find_Type;

   function Find_Primitive
     (Model : Primitive_Model; Id : Primitive_Id) return Primitive_Info is
   begin
      for P of Model.Items loop
         if P.Id = Id then
            return P;
         end if;
      end loop;
      return (others => <>);
   end Find_Primitive;

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

   procedure Add_Type_Evidence_Blockers
     (T : Interface_Type_Info; R : in out Result_Info) is
   begin
      if T.Id = No_Type then
         return;
      end if;

      Add_View_Blocker (T.View, R);

      if T.Source_Fingerprint /= T.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if T.AST_Fingerprint /= T.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if T.Type_Fingerprint /= T.Expected_Type_Fingerprint then
         R.Type_Fingerprint_Blockers := 1;
      end if;
   end Add_Type_Evidence_Blockers;

   procedure Add_Primitive_Evidence_Blockers
     (P : Primitive_Info; R : in out Result_Info) is
   begin
      if P.Id = No_Primitive then
         return;
      end if;

      Add_View_Blocker (P.View, R);

      if P.Source_Fingerprint /= P.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if P.Profile_Fingerprint /= P.Expected_Profile_Fingerprint then
         R.Profile_Fingerprint_Blockers := 1;
      end if;
      if P.Effect_Fingerprint /= P.Expected_Effect_Fingerprint then
         R.Effect_Fingerprint_Blockers := 1;
      end if;
   end Add_Primitive_Evidence_Blockers;

   procedure Add_Check_Fingerprint_Blockers
     (C : Check_Info; R : in out Result_Info) is
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
   end Add_Check_Fingerprint_Blockers;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Check_Blockers
        + R.Missing_Interface_Type_Blockers
        + R.Missing_Parent_Interface_Blockers
        + R.Missing_Primitive_Blockers
        + R.Missing_Parent_Primitive_Blockers
        + R.Not_Interface_Type_Blockers
        + R.Parent_Not_Interface_Blockers
        + R.Interface_Kind_Blockers
        + R.Limited_Interface_Blockers
        + R.Synchronized_Interface_Blockers
        + R.Inheritance_Blockers
        + R.Profile_Blockers
        + R.Mode_Blockers
        + R.Result_Blockers
        + R.Overriding_Indicator_Blockers
        + R.Abstract_Implementation_Blockers
        + R.Synchronized_Override_Blockers
        + R.Dispatching_Profile_Blockers
        + R.Dispatching_Ambiguity_Blockers
        + R.Static_Interface_Call_Blockers
        + R.Null_Procedure_Allowed_Blockers
        + R.Null_Procedure_Profile_Blockers
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

   function Status_For (R : Result_Info) return Legality_Status is
      C : constant Natural := Blocker_Count (R);
   begin
      if C = 0 then
         return Legality_Legal;
      elsif C > 1 then
         return Legality_Multiple_Blockers;
      elsif R.Missing_Check_Blockers > 0 then
         return Legality_Missing_Check;
      elsif R.Missing_Interface_Type_Blockers > 0 then
         return Legality_Missing_Interface_Type;
      elsif R.Missing_Parent_Interface_Blockers > 0 then
         return Legality_Missing_Parent_Interface;
      elsif R.Missing_Primitive_Blockers > 0 then
         return Legality_Missing_Primitive;
      elsif R.Missing_Parent_Primitive_Blockers > 0 then
         return Legality_Missing_Parent_Primitive;
      elsif R.Not_Interface_Type_Blockers > 0 then
         return Legality_Not_Interface_Type;
      elsif R.Parent_Not_Interface_Blockers > 0 then
         return Legality_Parent_Not_Interface;
      elsif R.Interface_Kind_Blockers > 0 then
         return Legality_Interface_Kind_Mismatch;
      elsif R.Limited_Interface_Blockers > 0 then
         return Legality_Limited_Interface_Mismatch;
      elsif R.Synchronized_Interface_Blockers > 0 then
         return Legality_Synchronized_Interface_Mismatch;
      elsif R.Inheritance_Blockers > 0 then
         return Legality_Inheritance_Incompatible;
      elsif R.Profile_Blockers > 0 then
         return Legality_Primitive_Profile_Mismatch;
      elsif R.Mode_Blockers > 0 then
         return Legality_Primitive_Mode_Mismatch;
      elsif R.Result_Blockers > 0 then
         return Legality_Primitive_Result_Mismatch;
      elsif R.Overriding_Indicator_Blockers > 0 then
         return Legality_Overriding_Indicator_Mismatch;
      elsif R.Abstract_Implementation_Blockers > 0 then
         return Legality_Abstract_Primitive_Not_Implemented;
      elsif R.Synchronized_Override_Blockers > 0 then
         return Legality_Synchronized_Override_Mismatch;
      elsif R.Dispatching_Profile_Blockers > 0 then
         return Legality_Dispatching_Profile_Mismatch;
      elsif R.Dispatching_Ambiguity_Blockers > 0 then
         return Legality_Ambiguous_Dispatching_Call;
      elsif R.Static_Interface_Call_Blockers > 0 then
         return Legality_Static_Call_To_Interface;
      elsif R.Null_Procedure_Allowed_Blockers > 0 then
         return Legality_Null_Procedure_Not_Allowed;
      elsif R.Null_Procedure_Profile_Blockers > 0 then
         return Legality_Null_Procedure_Profile_Mismatch;
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

   procedure Clear (Model : in out Type_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Primitive_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Check_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Result_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Type (Model : in out Type_Model; Item : Interface_Type_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Type_Kind'Pos (Item.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Type_Fingerprint);
   end Add_Type;

   procedure Add_Primitive (Model : in out Primitive_Model; Item : Primitive_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Primitive_Kind'Pos (Item.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Profile_Fingerprint);
   end Add_Primitive;

   procedure Add_Check (Model : in out Check_Model; Item : Check_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Check_Kind'Pos (Item.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Source_Fingerprint);
   end Add_Check;

   procedure Add_Result (Model : in out Result_Model; Item : Result_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Legality_Status'Pos (Item.Status)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);
   end Add_Result;

   function Build
     (Types : Type_Model;
      Primitives : Primitive_Model;
      Checks : Check_Model) return Result_Model
   is
      Results : Result_Model;
   begin
      if Checks.Items.Is_Empty then
         declare
            R : Result_Info;
         begin
            R.Id := 1;
            R.Missing_Check_Blockers := 1;
            R.Status := Status_For (R);
            R.Fingerprint := Mix (1332, Natural (Legality_Status'Pos (R.Status)));
            Add_Result (Results, R);
         end;
      end if;

      for C of Checks.Items loop
         declare
            T  : constant Interface_Type_Info := Find_Type (Types, C.Interface_Type);
            PT : constant Interface_Type_Info := Find_Type (Types, C.Parent_Interface);
            P  : constant Primitive_Info := Find_Primitive (Primitives, C.Primitive);
            PP : constant Primitive_Info := Find_Primitive (Primitives, C.Parent_Primitive);
            R  : Result_Info;
         begin
            R.Id := Result_Id (Natural (C.Id));
            R.Check := C.Id;
            R.Source_Node := C.Node;

            Add_Check_Fingerprint_Blockers (C, R);
            Add_Type_Evidence_Blockers (T, R);
            Add_Type_Evidence_Blockers (PT, R);
            Add_Primitive_Evidence_Blockers (P, R);
            Add_Primitive_Evidence_Blockers (PP, R);

            case C.Kind is
               when Check_Interface_Declaration =>
                  if T.Id = No_Type then
                     R.Missing_Interface_Type_Blockers := 1;
                  else
                     if not T.Is_Interface then
                        R.Not_Interface_Type_Blockers := 1;
                     end if;
                     if C.Expected_Interface_Kind /= Type_Unknown
                       and then T.Kind /= C.Expected_Interface_Kind
                     then
                        R.Interface_Kind_Blockers := 1;
                     end if;
                     if C.Requires_Limited_Interface and then not T.Is_Limited_Interface then
                        R.Limited_Interface_Blockers := 1;
                     end if;
                     if C.Requires_Synchronized_Interface
                       and then not T.Is_Synchronized_Interface
                     then
                        R.Synchronized_Interface_Blockers := 1;
                     end if;
                  end if;

               when Check_Interface_Inheritance =>
                  if T.Id = No_Type then
                     R.Missing_Interface_Type_Blockers := 1;
                  elsif not T.Is_Interface then
                     R.Not_Interface_Type_Blockers := 1;
                  end if;

                  if PT.Id = No_Type then
                     R.Missing_Parent_Interface_Blockers := 1;
                  elsif not PT.Is_Interface then
                     R.Parent_Not_Interface_Blockers := 1;
                  end if;

                  if T.Id /= No_Type and then PT.Id /= No_Type then
                     if C.Requires_Limited_Interface
                       and then not (T.Is_Limited_Interface and PT.Is_Limited_Interface)
                     then
                        R.Limited_Interface_Blockers := 1;
                     end if;
                     if C.Requires_Synchronized_Interface
                       and then not (T.Is_Synchronized_Interface or else PT.Is_Synchronized_Interface)
                     then
                        R.Synchronized_Interface_Blockers := 1;
                     end if;
                     if not (T.Inheritance_Compatible
                             and PT.Inheritance_Compatible
                             and C.Inheritance_Compatible)
                     then
                        R.Inheritance_Blockers := 1;
                     end if;
                  end if;

               when Check_Primitive_Override =>
                  if T.Id = No_Type then
                     R.Missing_Interface_Type_Blockers := 1;
                  elsif not T.Is_Interface then
                     R.Not_Interface_Type_Blockers := 1;
                  end if;
                  if P.Id = No_Primitive then
                     R.Missing_Primitive_Blockers := 1;
                  end if;
                  if PP.Id = No_Primitive then
                     R.Missing_Parent_Primitive_Blockers := 1;
                  end if;
                  if P.Id /= No_Primitive then
                     if not (P.Profile_Conformant and C.Profile_Conformant) then
                        R.Profile_Blockers := 1;
                     end if;
                     if not (P.Mode_Conformant and C.Mode_Conformant) then
                        R.Mode_Blockers := 1;
                     end if;
                     if not (P.Result_Conformant and C.Result_Conformant) then
                        R.Result_Blockers := 1;
                     end if;
                     if not (P.Is_Overriding and C.Overriding_Indicator_OK) then
                        R.Overriding_Indicator_Blockers := 1;
                     end if;
                     if P.Is_Abstract and then not C.Abstract_Primitive_Implemented then
                        R.Abstract_Implementation_Blockers := 1;
                     end if;
                  end if;

               when Check_Synchronized_Override =>
                  if T.Id = No_Type then
                     R.Missing_Interface_Type_Blockers := 1;
                  elsif not T.Is_Interface then
                     R.Not_Interface_Type_Blockers := 1;
                  elsif not T.Is_Synchronized_Interface then
                     R.Synchronized_Interface_Blockers := 1;
                  end if;
                  if P.Id = No_Primitive then
                     R.Missing_Primitive_Blockers := 1;
                  else
                     if not (P.Synchronized_Override_OK and C.Synchronized_Override_OK) then
                        R.Synchronized_Override_Blockers := 1;
                     end if;
                     if not (P.Profile_Conformant and C.Profile_Conformant) then
                        R.Profile_Blockers := 1;
                     end if;
                  end if;

               when Check_Dispatching_Interface_Call =>
                  if T.Id = No_Type then
                     R.Missing_Interface_Type_Blockers := 1;
                  elsif not T.Is_Interface then
                     R.Not_Interface_Type_Blockers := 1;
                  end if;
                  if P.Id = No_Primitive then
                     R.Missing_Primitive_Blockers := 1;
                  else
                     if not C.Dispatching_Profile_OK then
                        R.Dispatching_Profile_Blockers := 1;
                     end if;
                     if C.Dispatching_Ambiguous then
                        R.Dispatching_Ambiguity_Blockers := 1;
                     end if;
                     if C.Static_Call_To_Interface_Primitive then
                        R.Static_Interface_Call_Blockers := 1;
                     end if;
                  end if;

               when Check_Null_Procedure =>
                  if T.Id = No_Type then
                     R.Missing_Interface_Type_Blockers := 1;
                  elsif not T.Is_Interface then
                     R.Not_Interface_Type_Blockers := 1;
                  end if;
                  if P.Id = No_Primitive then
                     R.Missing_Primitive_Blockers := 1;
                  else
                     if not (P.Kind = Primitive_Null_Procedure and P.Is_Null_Procedure)
                       or else not (P.Null_Procedure_Allowed and C.Null_Procedure_Allowed)
                     then
                        R.Null_Procedure_Allowed_Blockers := 1;
                     end if;
                     if not (P.Profile_Conformant and C.Null_Procedure_Profile_OK) then
                        R.Null_Procedure_Profile_Blockers := 1;
                     end if;
                  end if;

               when Check_Unknown =>
                  R.Missing_Check_Blockers := 1;
            end case;

            R.Status := Status_For (R);
            R.Fingerprint := Mix (Natural (C.Id), Natural (Legality_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));
            R.Fingerprint := Mix (R.Fingerprint, C.Source_Fingerprint);
            Add_Result (Results, R);
         end;
      end loop;

      return Results;
   end Build;

   function Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index - 1);
   end Result_At;

end Editor.Ada_Interface_Synchronized_Vertical_Slice_Legality;
