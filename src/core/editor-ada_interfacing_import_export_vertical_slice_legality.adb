package body Editor.Ada_Interfacing_Import_Export_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1333) mod 1_000_000_007;
   end Mix;

   function Find_Entity (Model : Entity_Model; Id : Entity_Id) return Entity_Info is
   begin
      for E of Model.Items loop
         if E.Id = Id then
            return E;
         end if;
      end loop;
      return (others => <>);
   end Find_Entity;

   function Find_Item (Model : Item_Model; Id : Item_Id) return Item_Info is
   begin
      for I of Model.Items loop
         if I.Id = Id then
            return I;
         end if;
      end loop;
      return (others => <>);
   end Find_Item;

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

   procedure Add_Entity_Evidence_Blockers
     (E : Entity_Info; R : in out Result_Info) is
   begin
      if E.Id = No_Entity then
         return;
      end if;

      Add_View_Blocker (E.View, R);

      if E.Source_Fingerprint /= E.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if E.AST_Fingerprint /= E.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if E.Entity_Fingerprint /= E.Expected_Entity_Fingerprint then
         R.Entity_Fingerprint_Blockers := 1;
      end if;
      if E.Profile_Fingerprint /= E.Expected_Profile_Fingerprint then
         R.Profile_Fingerprint_Blockers := 1;
      end if;
      if E.Representation_Fingerprint /= E.Expected_Representation_Fingerprint then
         R.Representation_Fingerprint_Blockers := 1;
      end if;
   end Add_Entity_Evidence_Blockers;

   procedure Add_Item_Evidence_Blockers
     (I : Item_Info; R : in out Result_Info) is
   begin
      if I.Id = No_Item then
         return;
      end if;

      if I.Source_Fingerprint /= I.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if I.AST_Fingerprint /= I.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if I.Representation_Fingerprint /= I.Expected_Representation_Fingerprint then
         R.Representation_Fingerprint_Blockers := 1;
      end if;
   end Add_Item_Evidence_Blockers;

   procedure Add_Check_Fingerprint_Blockers
     (C : Check_Info; R : in out Result_Info) is
   begin
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         R.Source_Fingerprint_Blockers := 1;
      end if;
      if C.AST_Fingerprint /= C.Expected_AST_Fingerprint then
         R.AST_Fingerprint_Blockers := 1;
      end if;
      if C.Entity_Fingerprint /= C.Expected_Entity_Fingerprint then
         R.Entity_Fingerprint_Blockers := 1;
      end if;
      if C.Profile_Fingerprint /= C.Expected_Profile_Fingerprint then
         R.Profile_Fingerprint_Blockers := 1;
      end if;
      if C.Representation_Fingerprint /= C.Expected_Representation_Fingerprint then
         R.Representation_Fingerprint_Blockers := 1;
      end if;
   end Add_Check_Fingerprint_Blockers;

   function Is_Import_Target (Kind : Entity_Kind) return Boolean is
   begin
      return Kind in Entity_Subprogram | Entity_Access_Subprogram | Entity_Object | Entity_Type;
   end Is_Import_Target;

   function Is_Export_Target (Kind : Entity_Kind) return Boolean is
   begin
      return Kind in Entity_Subprogram | Entity_Access_Subprogram | Entity_Object;
   end Is_Export_Target;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Check_Blockers
        + R.Missing_Entity_Blockers
        + R.Missing_Item_Blockers
        + R.Entity_Kind_Blockers
        + R.Convention_Missing_Blockers
        + R.Convention_Mismatch_Blockers
        + R.Convention_Not_Allowed_Blockers
        + R.Import_Target_Blockers
        + R.Export_Target_Blockers
        + R.External_Name_Missing_Blockers
        + R.External_Name_Static_Blockers
        + R.Link_Name_Missing_Blockers
        + R.Link_Name_Static_Blockers
        + R.Address_Target_Blockers
        + R.Address_Static_Blockers
        + R.Storage_Target_Blockers
        + R.Storage_Static_Blockers
        + R.Storage_Size_Blockers
        + R.C_Profile_Blockers
        + R.Access_Profile_Blockers
        + R.Access_Convention_Blockers
        + R.Import_Export_Conflict_Blockers
        + R.Stream_External_Conflict_Blockers
        + R.Duplicate_Item_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Entity_Fingerprint_Blockers
        + R.Profile_Fingerprint_Blockers
        + R.Representation_Fingerprint_Blockers;
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
      elsif R.Missing_Entity_Blockers > 0 then
         return Legality_Missing_Entity;
      elsif R.Missing_Item_Blockers > 0 then
         return Legality_Missing_Item;
      elsif R.Entity_Kind_Blockers > 0 then
         return Legality_Entity_Kind_Mismatch;
      elsif R.Convention_Missing_Blockers > 0 then
         return Legality_Convention_Missing;
      elsif R.Convention_Mismatch_Blockers > 0 then
         return Legality_Convention_Mismatch;
      elsif R.Convention_Not_Allowed_Blockers > 0 then
         return Legality_Convention_Not_Allowed;
      elsif R.Import_Target_Blockers > 0 then
         return Legality_Import_Target_Mismatch;
      elsif R.Export_Target_Blockers > 0 then
         return Legality_Export_Target_Mismatch;
      elsif R.External_Name_Missing_Blockers > 0 then
         return Legality_External_Name_Missing;
      elsif R.External_Name_Static_Blockers > 0 then
         return Legality_External_Name_Not_Static;
      elsif R.Link_Name_Missing_Blockers > 0 then
         return Legality_Link_Name_Missing;
      elsif R.Link_Name_Static_Blockers > 0 then
         return Legality_Link_Name_Not_Static;
      elsif R.Address_Target_Blockers > 0 then
         return Legality_Address_Target_Mismatch;
      elsif R.Address_Static_Blockers > 0 then
         return Legality_Address_Not_Static;
      elsif R.Storage_Target_Blockers > 0 then
         return Legality_Storage_Target_Mismatch;
      elsif R.Storage_Static_Blockers > 0 then
         return Legality_Storage_Size_Not_Static;
      elsif R.Storage_Size_Blockers > 0 then
         return Legality_Storage_Size_Incompatible;
      elsif R.C_Profile_Blockers > 0 then
         return Legality_Profile_Not_C_Compatible;
      elsif R.Access_Profile_Blockers > 0 then
         return Legality_Access_Profile_Mismatch;
      elsif R.Access_Convention_Blockers > 0 then
         return Legality_Access_Convention_Mismatch;
      elsif R.Import_Export_Conflict_Blockers > 0 then
         return Legality_Import_Export_Conflict;
      elsif R.Stream_External_Conflict_Blockers > 0 then
         return Legality_Stream_External_Conflict;
      elsif R.Duplicate_Item_Blockers > 0 then
         return Legality_Duplicate_Interfacing_Item;
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
      elsif R.Entity_Fingerprint_Blockers > 0 then
         return Legality_Entity_Fingerprint_Mismatch;
      elsif R.Profile_Fingerprint_Blockers > 0 then
         return Legality_Profile_Fingerprint_Mismatch;
      elsif R.Representation_Fingerprint_Blockers > 0 then
         return Legality_Representation_Fingerprint_Mismatch;
      else
         return Legality_Indeterminate;
      end if;
   end Status_For;

   procedure Clear (Model : in out Entity_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Item_Model) is
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

   procedure Add_Entity (Model : in out Entity_Model; Item : Entity_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Entity_Kind'Pos (Item.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Entity_Fingerprint);
   end Add_Entity;

   procedure Add_Item (Model : in out Item_Model; Item : Item_Info) is
   begin
      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Item.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Interfacing_Item_Kind'Pos (Item.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Representation_Fingerprint);
   end Add_Item;

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
     (Entities : Entity_Model;
      Items : Item_Model;
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
            R.Fingerprint := Mix (1333, Natural (Legality_Status'Pos (R.Status)));
            Add_Result (Results, R);
         end;
      end if;

      for C of Checks.Items loop
         declare
            E : constant Entity_Info := Find_Entity (Entities, C.Target);
            I : constant Item_Info := Find_Item (Items, C.Item);
            R : Result_Info;
         begin
            R.Id := Result_Id (Natural (C.Id));
            R.Check := C.Id;
            R.Source_Node := C.Node;

            Add_Check_Fingerprint_Blockers (C, R);
            Add_Entity_Evidence_Blockers (E, R);
            Add_Item_Evidence_Blockers (I, R);

            if E.Id = No_Entity then
               R.Missing_Entity_Blockers := 1;
            end if;

            if C.Item /= No_Item and then I.Id = No_Item then
               R.Missing_Item_Blockers := 1;
            end if;

            if E.Id /= No_Entity then
               if C.Expected_Entity_Kind /= Entity_Unknown
                 and then E.Kind /= C.Expected_Entity_Kind
               then
                  R.Entity_Kind_Blockers := 1;
               end if;

               if E.Duplicate_Item or else I.Duplicate_Item then
                  R.Duplicate_Item_Blockers := 1;
               end if;

               if C.Reject_Import_Export_Conflict
                 and then E.Is_Imported and then E.Is_Exported
               then
                  R.Import_Export_Conflict_Blockers := 1;
               end if;

               if C.Reject_Stream_External_Conflict
                 and then E.Stream_External_Conflict
               then
                  R.Stream_External_Conflict_Blockers := 1;
               end if;
            end if;

            case C.Kind is
               when Check_Convention =>
                  if E.Id /= No_Entity then
                     if not E.Has_Convention then
                        R.Convention_Missing_Blockers := 1;
                     end if;
                     if C.Expected_Convention /= Convention_Unknown
                       and then E.Convention /= C.Expected_Convention
                     then
                        R.Convention_Mismatch_Blockers := 1;
                     end if;
                     if not C.Convention_Allowed then
                        R.Convention_Not_Allowed_Blockers := 1;
                     end if;
                  end if;

               when Check_Import =>
                  if E.Id /= No_Entity then
                     if C.Requires_Import_Target and then not Is_Import_Target (E.Kind) then
                        R.Import_Target_Blockers := 1;
                     end if;
                     if not E.Is_Imported then
                        R.Import_Target_Blockers := 1;
                     end if;
                     if C.Requires_External_Name
                       and then not (E.Has_External_Name or else I.External_Name_Present)
                     then
                        R.External_Name_Missing_Blockers := 1;
                     end if;
                     if not (E.External_Name_Static and I.External_Name_Static) then
                        R.External_Name_Static_Blockers := 1;
                     end if;
                  end if;

               when Check_Export =>
                  if E.Id /= No_Entity then
                     if C.Requires_Export_Target and then not Is_Export_Target (E.Kind) then
                        R.Export_Target_Blockers := 1;
                     end if;
                     if not E.Is_Exported then
                        R.Export_Target_Blockers := 1;
                     end if;
                     if C.Requires_Link_Name
                       and then not (E.Has_Link_Name or else I.Link_Name_Present)
                     then
                        R.Link_Name_Missing_Blockers := 1;
                     end if;
                     if not (E.Link_Name_Static and I.Link_Name_Static) then
                        R.Link_Name_Static_Blockers := 1;
                     end if;
                  end if;

               when Check_External_Name =>
                  if E.Id /= No_Entity then
                     if not (E.Has_External_Name or else I.External_Name_Present) then
                        R.External_Name_Missing_Blockers := 1;
                     end if;
                     if not (E.External_Name_Static and I.External_Name_Static) then
                        R.External_Name_Static_Blockers := 1;
                     end if;
                  end if;

               when Check_Link_Name =>
                  if E.Id /= No_Entity then
                     if not (E.Has_Link_Name or else I.Link_Name_Present) then
                        R.Link_Name_Missing_Blockers := 1;
                     end if;
                     if not (E.Link_Name_Static and I.Link_Name_Static) then
                        R.Link_Name_Static_Blockers := 1;
                     end if;
                  end if;

               when Check_Address_Attribute =>
                  if E.Id /= No_Entity then
                     if E.Kind not in Entity_Object | Entity_Subprogram | Entity_Access_Subprogram then
                        R.Address_Target_Blockers := 1;
                     end if;
                     if C.Requires_Address_Static and then not (E.Address_Static and I.Address_Static) then
                        R.Address_Static_Blockers := 1;
                     end if;
                  end if;

               when Check_Storage_Attribute =>
                  if E.Id /= No_Entity then
                     if E.Kind not in Entity_Type | Entity_Object then
                        R.Storage_Target_Blockers := 1;
                     end if;
                     if C.Requires_Storage_Static
                       and then not (E.Storage_Size_Static and I.Storage_Size_Static)
                     then
                        R.Storage_Static_Blockers := 1;
                     end if;
                     if not (E.Storage_Size_Compatible and I.Storage_Size_Compatible) then
                        R.Storage_Size_Blockers := 1;
                     end if;
                  end if;

               when Check_Access_Subprogram_Convention =>
                  if E.Id /= No_Entity then
                     if E.Kind /= Entity_Access_Subprogram then
                        R.Entity_Kind_Blockers := 1;
                     end if;
                     if C.Requires_Access_Profile_Compatible
                       and then not E.Access_Profile_Compatible
                     then
                        R.Access_Profile_Blockers := 1;
                     end if;
                     if C.Requires_Access_Convention_Compatible
                       and then not E.Access_Convention_Compatible
                     then
                        R.Access_Convention_Blockers := 1;
                     end if;
                  end if;

               when Check_C_Compatible_Profile =>
                  if E.Id /= No_Entity then
                     if C.Requires_C_Compatible_Profile
                       and then not E.Profile_C_Compatible
                     then
                        R.C_Profile_Blockers := 1;
                     end if;
                     if C.Expected_Convention = Convention_C
                       and then E.Convention /= Convention_C
                     then
                        R.Convention_Mismatch_Blockers := 1;
                     end if;
                  end if;

               when Check_Representation_Conflict =>
                  if E.Id /= No_Entity then
                     if E.Stream_External_Conflict then
                        R.Stream_External_Conflict_Blockers := 1;
                     end if;
                     if E.Duplicate_Item or else I.Duplicate_Item then
                        R.Duplicate_Item_Blockers := 1;
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

end Editor.Ada_Interfacing_Import_Export_Vertical_Slice_Legality;
