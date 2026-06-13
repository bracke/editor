with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;

package body Editor.Ada_Cross_Unit_Closure is

   use type Editor.Ada_Project_Index.Indexed_Unit_Role;
   use type Editor.Ada_Language_Model.Visibility_Clause_Kind;

   function Hash_String (Seed : Natural; Text : String) return Natural is
      H : Natural := Seed;
   begin
      for C of Text loop
         H := (H * 131 + Character'Pos (C) + 1) mod 2_147_483_647;
      end loop;
      return H;
   end Hash_String;

   function Role_Image
     (Role : Editor.Ada_Project_Index.Indexed_Unit_Role) return String
   is
   begin
      case Role is
         when Editor.Ada_Project_Index.Unit_Any => return "any";
         when Editor.Ada_Project_Index.Unit_Package_Spec => return "package_spec";
         when Editor.Ada_Project_Index.Unit_Private_Package_Spec => return "private_package_spec";
         when Editor.Ada_Project_Index.Unit_Package_Body => return "package_body";
         when Editor.Ada_Project_Index.Unit_Subprogram_Spec => return "subprogram_spec";
         when Editor.Ada_Project_Index.Unit_Subprogram_Body => return "subprogram_body";
         when Editor.Ada_Project_Index.Unit_Separate_Body => return "separate_body";
      end case;
   end Role_Image;

   function Kind_Image (Kind : Cross_Unit_Link_Kind) return String is
   begin
      case Kind is
         when Cross_Unit_Spec_To_Body => return "spec_to_body";
         when Cross_Unit_Body_To_Spec => return "body_to_spec";
         when Cross_Unit_Child_To_Parent => return "child_to_parent";
         when Cross_Unit_Parent_To_Child => return "parent_to_child";
         when Cross_Unit_Separate_To_Parent => return "separate_to_parent";
         when Cross_Unit_With_Dependency => return "with_dependency";
         when Cross_Unit_Limited_With_Dependency => return "limited_with_dependency";
         when Cross_Unit_Private_With_Dependency => return "private_with_dependency";
         when Cross_Unit_Use_Dependency => return "use_dependency";
      end case;
   end Kind_Image;

   function Status_Image (Status : Cross_Unit_Link_Status) return String is
   begin
      case Status is
         when Cross_Unit_Link_Resolved => return "resolved";
         when Cross_Unit_Link_Missing => return "missing";
         when Cross_Unit_Link_Ambiguous => return "ambiguous";
         when Cross_Unit_Link_Overflow => return "overflow";
         when Cross_Unit_Link_Not_Applicable => return "not_applicable";
      end case;
   end Status_Image;

   function Consistency_Status_Image
     (Status : Spec_Body_Consistency_Status) return String
   is
   begin
      case Status is
         when Spec_Body_Consistency_Confirmed => return "confirmed";
         when Spec_Body_Consistency_Missing_Counterpart => return "missing_counterpart";
         when Spec_Body_Consistency_Ambiguous_Counterpart => return "ambiguous_counterpart";
         when Spec_Body_Consistency_Overflow => return "overflow";
         when Spec_Body_Consistency_Role_Mismatch => return "role_mismatch";
         when Spec_Body_Consistency_Name_Mismatch => return "name_mismatch";
         when Spec_Body_Consistency_Not_Applicable => return "not_applicable";
      end case;
   end Consistency_Status_Image;

   function Child_Legality_Status_Image
     (Status : Child_Unit_Legality_Status) return String
   is
   begin
      case Status is
         when Child_Unit_Legality_Public_Child_Resolved => return "public_child_resolved";
         when Child_Unit_Legality_Private_Child_Resolved => return "private_child_resolved";
         when Child_Unit_Legality_Missing_Parent => return "missing_parent";
         when Child_Unit_Legality_Ambiguous_Parent => return "ambiguous_parent";
         when Child_Unit_Legality_Overflow => return "overflow";
         when Child_Unit_Legality_Parent_Role_Mismatch => return "parent_role_mismatch";
         when Child_Unit_Legality_Not_Applicable => return "not_applicable";
      end case;
   end Child_Legality_Status_Image;


   function Separate_Legality_Status_Image
     (Status : Separate_Body_Legality_Status) return String
   is
   begin
      case Status is
         when Separate_Body_Legality_Parent_Resolved => return "parent_resolved";
         when Separate_Body_Legality_Missing_Parent => return "missing_parent";
         when Separate_Body_Legality_Ambiguous_Parent => return "ambiguous_parent";
         when Separate_Body_Legality_Overflow => return "overflow";
         when Separate_Body_Legality_Parent_Role_Mismatch => return "parent_role_mismatch";
         when Separate_Body_Legality_Target_Name_Missing => return "target_name_missing";
         when Separate_Body_Legality_Not_Applicable => return "not_applicable";
      end case;
   end Separate_Legality_Status_Image;

   function Separate_Body_Legality_Fingerprint
     (Info : Separate_Body_Legality_Info) return Natural
   is
      H : Natural := 31;
   begin
      H := Hash_String (H, Separate_Legality_Status_Image (Info.Status));
      H := Hash_String (H, To_String (Info.Separate_Unit_Name));
      H := Hash_String (H, To_String (Info.Separate_Path));
      H := Hash_String (H, Role_Image (Info.Separate_Role));
      H := Hash_String (H, To_String (Info.Parent_Unit_Name));
      H := Hash_String (H, To_String (Info.Parent_Path));
      H := Hash_String (H, Role_Image (Info.Parent_Role));
      H := Hash_String (H, To_String (Info.Parent_Name_Text));
      H := (H * 131 + Info.Candidate_Count + 1) mod 2_147_483_647;
      return H;
   end Separate_Body_Legality_Fingerprint;

   function Child_Unit_Legality_Fingerprint
     (Info : Child_Unit_Legality_Info) return Natural
   is
      H : Natural := 29;
   begin
      H := Hash_String (H, Child_Legality_Status_Image (Info.Status));
      H := Hash_String (H, To_String (Info.Child_Unit_Name));
      H := Hash_String (H, To_String (Info.Child_Path));
      H := Hash_String (H, Role_Image (Info.Child_Role));
      H := Hash_String (H, To_String (Info.Parent_Unit_Name));
      H := Hash_String (H, To_String (Info.Parent_Path));
      H := Hash_String (H, Role_Image (Info.Parent_Role));
      if Info.Is_Private_Child then
         H := (H * 131 + 19) mod 2_147_483_647;
      end if;
      H := (H * 131 + Info.Candidate_Count + 1) mod 2_147_483_647;
      return H;
   end Child_Unit_Legality_Fingerprint;

   function Spec_Body_Consistency_Fingerprint
     (Info : Spec_Body_Consistency_Info) return Natural
   is
      H : Natural := 23;
   begin
      H := Hash_String (H, Consistency_Status_Image (Info.Status));
      H := Hash_String (H, To_String (Info.Spec_Unit_Name));
      H := Hash_String (H, To_String (Info.Spec_Path));
      H := Hash_String (H, Role_Image (Info.Spec_Role));
      H := Hash_String (H, To_String (Info.Body_Unit_Name));
      H := Hash_String (H, To_String (Info.Body_Path));
      H := Hash_String (H, Role_Image (Info.Body_Role));
      H := (H * 131 + Info.Candidate_Count + 1) mod 2_147_483_647;
      return H;
   end Spec_Body_Consistency_Fingerprint;

   function Is_Spec_Role
     (Role : Editor.Ada_Project_Index.Indexed_Unit_Role) return Boolean
   is
   begin
      return Role = Editor.Ada_Project_Index.Unit_Package_Spec
        or else Role = Editor.Ada_Project_Index.Unit_Private_Package_Spec
        or else Role = Editor.Ada_Project_Index.Unit_Subprogram_Spec;
   end Is_Spec_Role;

   function Is_Body_Role
     (Role : Editor.Ada_Project_Index.Indexed_Unit_Role) return Boolean
   is
   begin
      return Role = Editor.Ada_Project_Index.Unit_Package_Body
        or else Role = Editor.Ada_Project_Index.Unit_Subprogram_Body;
   end Is_Body_Role;


   function Is_Separate_Parent_Role
     (Role : Editor.Ada_Project_Index.Indexed_Unit_Role) return Boolean
   is
   begin
      return Role = Editor.Ada_Project_Index.Unit_Package_Body
        or else Role = Editor.Ada_Project_Index.Unit_Subprogram_Body;
   end Is_Separate_Parent_Role;

   procedure Append_Spec_Body_Consistency
     (Model : in out Cross_Unit_Closure_Model;
      Info  : Spec_Body_Consistency_Info)
   is
      Copy : Spec_Body_Consistency_Info := Info;
   begin
      Copy.Fingerprint := Spec_Body_Consistency_Fingerprint (Copy);
      Model.Spec_Body_Consistency.Append (Copy);
      Model.Model_Fingerprint :=
        (Model.Model_Fingerprint * 131 + Copy.Fingerprint + 1) mod 2_147_483_647;
   end Append_Spec_Body_Consistency;


   procedure Append_Child_Unit_Legality
     (Model : in out Cross_Unit_Closure_Model;
      Info  : Child_Unit_Legality_Info)
   is
      Copy : Child_Unit_Legality_Info := Info;
   begin
      Copy.Fingerprint := Child_Unit_Legality_Fingerprint (Copy);
      Model.Child_Unit_Legality.Append (Copy);
      Model.Model_Fingerprint :=
        (Model.Model_Fingerprint * 131 + Copy.Fingerprint + 1) mod 2_147_483_647;
   end Append_Child_Unit_Legality;



   procedure Append_Separate_Body_Legality
     (Model : in out Cross_Unit_Closure_Model;
      Info  : Separate_Body_Legality_Info)
   is
      Copy : Separate_Body_Legality_Info := Info;
   begin
      Copy.Fingerprint := Separate_Body_Legality_Fingerprint (Copy);
      Model.Separate_Body_Legality.Append (Copy);
      Model.Model_Fingerprint :=
        (Model.Model_Fingerprint * 131 + Copy.Fingerprint + 1) mod 2_147_483_647;
   end Append_Separate_Body_Legality;

   function Link_Fingerprint (Link : Cross_Unit_Link_Info) return Natural is
      H : Natural := 17;
   begin
      H := Hash_String (H, Kind_Image (Link.Kind));
      H := Hash_String (H, Status_Image (Link.Status));
      H := Hash_String (H, To_String (Link.Source_Unit_Name));
      H := Hash_String (H, Role_Image (Link.Source_Role));
      H := Hash_String (H, To_String (Link.Source_Path));
      H := Hash_String (H, To_String (Link.Target_Unit_Name));
      H := Hash_String (H, Role_Image (Link.Target_Role));
      H := Hash_String (H, To_String (Link.Target_Path));
      H := Hash_String (H, To_String (Link.Clause_Name));
      if Link.Is_Limited_With then
         H := (H * 131 + 11) mod 2_147_483_647;
      end if;
      if Link.Is_Private_With then
         H := (H * 131 + 17) mod 2_147_483_647;
      end if;
      H := (H * 131 + Link.Candidate_Count + 1) mod 2_147_483_647;
      return H;
   end Link_Fingerprint;

   function Has_Dot (Name : String) return Boolean is
   begin
      for C of Name loop
         if C = '.' then
            return True;
         end if;
      end loop;
      return False;
   end Has_Dot;

   function Status_For (Target : Editor.Ada_Project_Index.Unique_Target_Result)
      return Cross_Unit_Link_Status
   is
   begin
      if Target.Overflow then
         return Cross_Unit_Link_Overflow;
      elsif Target.Ambiguous then
         return Cross_Unit_Link_Ambiguous;
      elsif Target.Available then
         return Cross_Unit_Link_Resolved;
      else
         return Cross_Unit_Link_Missing;
      end if;
   end Status_For;

   function Target_Name_For (Target : Editor.Ada_Project_Index.Unique_Target_Result)
      return Ada.Strings.Unbounded.Unbounded_String
   is
   begin
      if Target.Available then
         if Length (Target.Target.Symbol.Target_Name) > 0 then
            return Target.Target.Symbol.Target_Name;
         else
            return Target.Target.Symbol.Name;
         end if;
      end if;
      return Null_Unbounded_String;
   end Target_Name_For;

   function Target_Path_For (Target : Editor.Ada_Project_Index.Unique_Target_Result)
      return Ada.Strings.Unbounded.Unbounded_String
   is
   begin
      if Target.Available then
         return Target.Target.Path;
      end if;
      return Null_Unbounded_String;
   end Target_Path_For;

   function Target_Role_For (Target : Editor.Ada_Project_Index.Unique_Target_Result)
      return Editor.Ada_Project_Index.Indexed_Unit_Role
   is
   begin
      if Target.Available then
         return Editor.Ada_Project_Index.Unit_Role_For_Symbol (Target.Target.Symbol);
      end if;
      return Editor.Ada_Project_Index.Unit_Any;
   end Target_Role_For;

   procedure Append_Link
     (Model : in out Cross_Unit_Closure_Model;
      Link  : Cross_Unit_Link_Info)
   is
      Copy : Cross_Unit_Link_Info := Link;
   begin
      Copy.Fingerprint := Link_Fingerprint (Copy);
      Model.Links.Append (Copy);
      Model.Model_Fingerprint :=
        (Model.Model_Fingerprint * 131 + Copy.Fingerprint + 1) mod 2_147_483_647;
   end Append_Link;

   procedure Append_Unique_Target_Link
     (Model  : in out Cross_Unit_Closure_Model;
      Unit   : Editor.Ada_Project_Index.Indexed_Unit;
      Kind   : Cross_Unit_Link_Kind;
      Target : Editor.Ada_Project_Index.Unique_Target_Result)
   is
      Link : Cross_Unit_Link_Info;
   begin
      Link.Kind := Kind;
      Link.Status := Status_For (Target);
      Link.Source_Unit_Name := Unit.Unit_Name;
      Link.Source_Role := Unit.Role;
      Link.Source_Path := Unit.Path;
      Link.Target_Unit_Name := Target_Name_For (Target);
      Link.Target_Role := Target_Role_For (Target);
      Link.Target_Path := Target_Path_For (Target);
      if Target.Available then
         Link.Candidate_Count := 1;
      elsif Target.Ambiguous then
         Link.Candidate_Count := 2;
      else
         Link.Candidate_Count := 0;
      end if;
      Append_Link (Model, Link);
   end Append_Unique_Target_Link;



   function Source_Unit_For_File
     (Index : Editor.Ada_Project_Index.Index_State;
      Key   : Editor.Ada_Project_Index.Indexed_File_Key)
      return Editor.Ada_Project_Index.Indexed_Unit
   is
   begin
      for I in 1 .. Editor.Ada_Project_Index.Unit_Count (Index) loop
         declare
            Unit : constant Editor.Ada_Project_Index.Indexed_Unit :=
              Editor.Ada_Project_Index.Unit_At (Index, I);
         begin
            if To_String (Unit.Key.Path) = To_String (Key.Path) then
               return Unit;
            end if;
         end;
      end loop;
      return (others => <>);
   end Source_Unit_For_File;

   function Context_Target_For
     (Index : Editor.Ada_Project_Index.Index_State;
      Name  : String) return Editor.Ada_Project_Index.Unique_Target_Result
   is
      Matches : constant Editor.Ada_Project_Index.Unit_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve_Unit (Index, Name);
      Result : Editor.Ada_Project_Index.Unique_Target_Result;
      Candidate_Count : Natural := 0;
      Candidate : Editor.Ada_Project_Index.Indexed_Unit;
   begin
      Result.Overflow := Matches.Overflow;
      if Result.Overflow then
         return Result;
      end if;

      if not Matches.Matches.Is_Empty then
         for I in Matches.Matches.First_Index .. Matches.Matches.Last_Index loop
            declare
               Unit : constant Editor.Ada_Project_Index.Indexed_Unit := Matches.Matches (I);
            begin
               if Unit.Role = Editor.Ada_Project_Index.Unit_Package_Spec
                 or else Unit.Role = Editor.Ada_Project_Index.Unit_Private_Package_Spec
                 or else Unit.Role = Editor.Ada_Project_Index.Unit_Subprogram_Spec
               then
                  Candidate_Count := Candidate_Count + 1;
                  if Candidate_Count = 1 then
                     Candidate := Unit;
                  end if;
               end if;
            end;
         end loop;
      end if;

      if Candidate_Count = 1 then
         Result.Available := True;
         Result.Target :=
           (Path   => Candidate.Path,
            Key    => Candidate.Key,
            Symbol => Candidate.Symbol);
      elsif Candidate_Count > 1 then
         Result.Ambiguous := True;
      end if;
      return Result;
   end Context_Target_For;

   procedure Append_Context_Dependency
     (Model  : in out Cross_Unit_Closure_Model;
      Index  : Editor.Ada_Project_Index.Index_State;
      Source : Editor.Ada_Project_Index.Indexed_Unit;
      Clause : Editor.Ada_Language_Model.Visibility_Clause_Info)
   is
      Target : constant Editor.Ada_Project_Index.Unique_Target_Result :=
        Context_Target_For (Index, To_String (Clause.Name));
      Link : Cross_Unit_Link_Info;
   begin
      if Length (Source.Unit_Name) = 0 then
         return;
      end if;

      case Clause.Kind is
         when Editor.Ada_Language_Model.Visibility_With_Clause =>
            if Clause.Has_Limited_Modifier then
               Link.Kind := Cross_Unit_Limited_With_Dependency;
            elsif Clause.Has_Private_Modifier then
               Link.Kind := Cross_Unit_Private_With_Dependency;
            else
               Link.Kind := Cross_Unit_With_Dependency;
            end if;
         when Editor.Ada_Language_Model.Visibility_Limited_With_Clause =>
            Link.Kind := Cross_Unit_Limited_With_Dependency;
         when Editor.Ada_Language_Model.Visibility_Private_With_Clause =>
            Link.Kind := Cross_Unit_Private_With_Dependency;
         when Editor.Ada_Language_Model.Visibility_Use_Package_Clause =>
            Link.Kind := Cross_Unit_Use_Dependency;
         when others =>
            return;
      end case;

      Link.Status := Status_For (Target);
      Link.Source_Unit_Name := Source.Unit_Name;
      Link.Source_Role := Source.Role;
      Link.Source_Path := Source.Path;
      Link.Target_Unit_Name := Target_Name_For (Target);
      Link.Target_Role := Target_Role_For (Target);
      Link.Target_Path := Target_Path_For (Target);
      Link.Clause_Name := Clause.Name;
      Link.Is_Limited_With := Clause.Has_Limited_Modifier
        or else Clause.Kind = Editor.Ada_Language_Model.Visibility_Limited_With_Clause;
      Link.Is_Private_With := Clause.Has_Private_Modifier
        or else Clause.Kind = Editor.Ada_Language_Model.Visibility_Private_With_Clause;
      if Target.Available then
         Link.Candidate_Count := 1;
      elsif Target.Ambiguous then
         Link.Candidate_Count := 2;
      else
         Link.Candidate_Count := 0;
      end if;
      Append_Link (Model, Link);
   end Append_Context_Dependency;

   procedure Append_Context_Dependencies
     (Model : in out Cross_Unit_Closure_Model;
      Index : Editor.Ada_Project_Index.Index_State)
   is
   begin
      for File_Index in 1 .. Editor.Ada_Project_Index.File_Count (Index) loop
         declare
            Key : constant Editor.Ada_Project_Index.Indexed_File_Key :=
              Editor.Ada_Project_Index.File_Key_At (Index, File_Index);
            Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
              Editor.Ada_Project_Index.File_Analysis_At (Index, File_Index);
            Source : constant Editor.Ada_Project_Index.Indexed_Unit :=
              Source_Unit_For_File (Index, Key);
         begin
            for Clause_Index in 1 .. Editor.Ada_Language_Model.Context_Clause_Count (Analysis) loop
               Append_Context_Dependency
                 (Model, Index, Source,
                  Editor.Ada_Language_Model.Context_Clause_At
                    (Analysis, Clause_Index));
            end loop;
         end;
      end loop;
   end Append_Context_Dependencies;


   procedure Append_Spec_Body_Consistency_For
     (Model : in out Cross_Unit_Closure_Model;
      Unit  : Editor.Ada_Project_Index.Indexed_Unit;
      Target : Editor.Ada_Project_Index.Unique_Target_Result)
   is
      Info : Spec_Body_Consistency_Info;
      Source_Is_Spec : constant Boolean := Is_Spec_Role (Unit.Role);
      Source_Is_Body : constant Boolean := Is_Body_Role (Unit.Role);
   begin
      if not Source_Is_Spec and then not Source_Is_Body then
         return;
      end if;

      if Source_Is_Spec then
         Info.Spec_Unit_Name := Unit.Unit_Name;
         Info.Spec_Path := Unit.Path;
         Info.Spec_Role := Unit.Role;
         Info.Body_Unit_Name := Target_Name_For (Target);
         Info.Body_Path := Target_Path_For (Target);
         Info.Body_Role := Target_Role_For (Target);
      else
         Info.Body_Unit_Name := Unit.Unit_Name;
         Info.Body_Path := Unit.Path;
         Info.Body_Role := Unit.Role;
         Info.Spec_Unit_Name := Target_Name_For (Target);
         Info.Spec_Path := Target_Path_For (Target);
         Info.Spec_Role := Target_Role_For (Target);
      end if;

      if Target.Available then
         Info.Candidate_Count := 1;
      elsif Target.Ambiguous then
         Info.Candidate_Count := 2;
      else
         Info.Candidate_Count := 0;
      end if;

      if Target.Overflow then
         Info.Status := Spec_Body_Consistency_Overflow;
      elsif Target.Ambiguous then
         Info.Status := Spec_Body_Consistency_Ambiguous_Counterpart;
      elsif not Target.Available then
         Info.Status := Spec_Body_Consistency_Missing_Counterpart;
      elsif Source_Is_Spec and then not Is_Body_Role (Target_Role_For (Target)) then
         Info.Status := Spec_Body_Consistency_Role_Mismatch;
      elsif Source_Is_Body and then not Is_Spec_Role (Target_Role_For (Target)) then
         Info.Status := Spec_Body_Consistency_Role_Mismatch;
      elsif Source_Is_Spec
        and then To_String (Unit.Normalized_Unit_Name) /=
          To_String (Target.Target.Symbol.Normalized_Name)
      then
         Info.Status := Spec_Body_Consistency_Name_Mismatch;
      elsif Source_Is_Body
        and then To_String (Unit.Normalized_Unit_Name) /=
          To_String (Target.Target.Symbol.Normalized_Name)
      then
         Info.Status := Spec_Body_Consistency_Name_Mismatch;
      else
         Info.Status := Spec_Body_Consistency_Confirmed;
      end if;

      Append_Spec_Body_Consistency (Model, Info);
   end Append_Spec_Body_Consistency_For;

   procedure Append_Child_Unit_Legality_For
     (Model  : in out Cross_Unit_Closure_Model;
      Unit   : Editor.Ada_Project_Index.Indexed_Unit;
      Target : Editor.Ada_Project_Index.Unique_Target_Result)
   is
      Info : Child_Unit_Legality_Info;
      Is_Private : constant Boolean :=
        Unit.Role = Editor.Ada_Project_Index.Unit_Private_Package_Spec;
      Target_Role : constant Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Target_Role_For (Target);
   begin
      Info.Child_Unit_Name := Unit.Unit_Name;
      Info.Child_Path := Unit.Path;
      Info.Child_Role := Unit.Role;
      Info.Parent_Unit_Name := Target_Name_For (Target);
      Info.Parent_Path := Target_Path_For (Target);
      Info.Parent_Role := Target_Role;
      Info.Is_Private_Child := Is_Private;

      if Target.Available then
         Info.Candidate_Count := 1;
      elsif Target.Ambiguous then
         Info.Candidate_Count := 2;
      else
         Info.Candidate_Count := 0;
      end if;

      if Target.Overflow then
         Info.Status := Child_Unit_Legality_Overflow;
      elsif Target.Ambiguous then
         Info.Status := Child_Unit_Legality_Ambiguous_Parent;
      elsif not Target.Available then
         Info.Status := Child_Unit_Legality_Missing_Parent;
      elsif Target_Role /= Editor.Ada_Project_Index.Unit_Package_Spec
        and then Target_Role /= Editor.Ada_Project_Index.Unit_Private_Package_Spec
      then
         Info.Status := Child_Unit_Legality_Parent_Role_Mismatch;
      elsif Is_Private then
         Info.Status := Child_Unit_Legality_Private_Child_Resolved;
      else
         Info.Status := Child_Unit_Legality_Public_Child_Resolved;
      end if;

      Append_Child_Unit_Legality (Model, Info);
   end Append_Child_Unit_Legality_For;



   procedure Append_Separate_Body_Legality_For
     (Model  : in out Cross_Unit_Closure_Model;
      Unit   : Editor.Ada_Project_Index.Indexed_Unit;
      Target : Editor.Ada_Project_Index.Unique_Target_Result)
   is
      Info : Separate_Body_Legality_Info;
      Parent_Role : constant Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Target_Role_For (Target);
   begin
      Info.Separate_Unit_Name := Unit.Unit_Name;
      Info.Separate_Path := Unit.Path;
      Info.Separate_Role := Unit.Role;
      Info.Parent_Unit_Name := Target_Name_For (Target);
      Info.Parent_Path := Target_Path_For (Target);
      Info.Parent_Role := Parent_Role;
      Info.Parent_Name_Text := Unit.Symbol.Target_Name;

      if Target.Available then
         Info.Candidate_Count := 1;
      elsif Target.Ambiguous then
         Info.Candidate_Count := 2;
      else
         Info.Candidate_Count := 0;
      end if;

      if Length (Unit.Symbol.Target_Name) = 0 then
         Info.Status := Separate_Body_Legality_Target_Name_Missing;
      elsif Target.Overflow then
         Info.Status := Separate_Body_Legality_Overflow;
      elsif Target.Ambiguous then
         Info.Status := Separate_Body_Legality_Ambiguous_Parent;
      elsif not Target.Available then
         Info.Status := Separate_Body_Legality_Missing_Parent;
      elsif not Is_Separate_Parent_Role (Parent_Role) then
         Info.Status := Separate_Body_Legality_Parent_Role_Mismatch;
      else
         Info.Status := Separate_Body_Legality_Parent_Resolved;
      end if;

      Append_Separate_Body_Legality (Model, Info);
   end Append_Separate_Body_Legality_For;


   function Build
     (Index : Editor.Ada_Project_Index.Index_State)
      return Cross_Unit_Closure_Model
   is
      Model : Cross_Unit_Closure_Model;
   begin
      Model.Model_Fingerprint := Editor.Ada_Project_Index.Fingerprint (Index);

      for I in 1 .. Editor.Ada_Project_Index.Unit_Count (Index) loop
         declare
            Unit : constant Editor.Ada_Project_Index.Indexed_Unit :=
              Editor.Ada_Project_Index.Unit_At (Index, I);
            Source : constant Editor.Ada_Project_Index.Indexed_Symbol :=
              (Path   => Unit.Path,
               Key    => Unit.Key,
               Symbol => Unit.Symbol);
         begin
            case Unit.Role is
               when Editor.Ada_Project_Index.Unit_Package_Spec |
                    Editor.Ada_Project_Index.Unit_Private_Package_Spec |
                    Editor.Ada_Project_Index.Unit_Subprogram_Spec =>
                  declare
                     Target : constant Editor.Ada_Project_Index.Unique_Target_Result :=
                       Editor.Ada_Project_Index.Resolve_Related_Unit_Target
                         (Index, Source, Want_Body => True);
                  begin
                     Append_Unique_Target_Link
                       (Model, Unit, Cross_Unit_Spec_To_Body, Target);
                     Append_Spec_Body_Consistency_For (Model, Unit, Target);
                  end;

               when Editor.Ada_Project_Index.Unit_Package_Body |
                    Editor.Ada_Project_Index.Unit_Subprogram_Body =>
                  declare
                     Target : constant Editor.Ada_Project_Index.Unique_Target_Result :=
                       Editor.Ada_Project_Index.Resolve_Related_Unit_Target
                         (Index, Source, Want_Body => False);
                  begin
                     Append_Unique_Target_Link
                       (Model, Unit, Cross_Unit_Body_To_Spec, Target);
                     Append_Spec_Body_Consistency_For (Model, Unit, Target);
                  end;

               when Editor.Ada_Project_Index.Unit_Separate_Body =>
                  declare
                     Target : constant Editor.Ada_Project_Index.Unique_Target_Result :=
                       Editor.Ada_Project_Index.Resolve_Separate_Parent_Target
                         (Index, Source);
                  begin
                     Append_Unique_Target_Link
                       (Model, Unit, Cross_Unit_Separate_To_Parent, Target);
                     Append_Separate_Body_Legality_For (Model, Unit, Target);
                  end;

               when Editor.Ada_Project_Index.Unit_Any =>
                  null;
            end case;

            if Has_Dot (To_String (Unit.Unit_Name)) then
               declare
                  Parent_Target : constant Editor.Ada_Project_Index.Unique_Target_Result :=
                    Editor.Ada_Project_Index.Resolve_Parent_Unit_Target
                      (Index, Source);
               begin
                  Append_Unique_Target_Link
                    (Model, Unit, Cross_Unit_Child_To_Parent, Parent_Target);
                  Append_Child_Unit_Legality_For (Model, Unit, Parent_Target);
               end;
            end if;

            if Unit.Role = Editor.Ada_Project_Index.Unit_Package_Spec
              or else Unit.Role = Editor.Ada_Project_Index.Unit_Private_Package_Spec
            then
               declare
                  Children : constant Editor.Ada_Project_Index.Unit_Resolution_Result :=
                    Editor.Ada_Project_Index.Resolve_Child_Units (Index, Source);
               begin
                  if Children.Overflow then
                     declare
                        Link : Cross_Unit_Link_Info;
                     begin
                        Link.Kind := Cross_Unit_Parent_To_Child;
                        Link.Status := Cross_Unit_Link_Overflow;
                        Link.Source_Unit_Name := Unit.Unit_Name;
                        Link.Source_Role := Unit.Role;
                        Link.Source_Path := Unit.Path;
                        Append_Link (Model, Link);
                     end;
                  elsif not Children.Matches.Is_Empty then
                     for J in Children.Matches.First_Index .. Children.Matches.Last_Index loop
                        declare
                           Child : constant Editor.Ada_Project_Index.Indexed_Unit :=
                             Children.Matches (J);
                           Link : Cross_Unit_Link_Info;
                        begin
                           Link.Kind := Cross_Unit_Parent_To_Child;
                           Link.Status := Cross_Unit_Link_Resolved;
                           Link.Source_Unit_Name := Unit.Unit_Name;
                           Link.Source_Role := Unit.Role;
                           Link.Source_Path := Unit.Path;
                           Link.Target_Unit_Name := Child.Unit_Name;
                           Link.Target_Role := Child.Role;
                           Link.Target_Path := Child.Path;
                           Link.Candidate_Count := 1;
                           Append_Link (Model, Link);
                        end;
                     end loop;
                  end if;
               end;
            end if;
         end;
      end loop;

      Append_Context_Dependencies (Model, Index);

      return Model;
   end Build;

   function Link_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Natural (Model.Links.Length);
   end Link_Count;

   function Link_At
     (Model : Cross_Unit_Closure_Model;
      Index : Positive) return Cross_Unit_Link_Info
   is
   begin
      if Model.Links.Is_Empty
        or else Index < Model.Links.First_Index
        or else Index > Model.Links.Last_Index
      then
         return (others => <>);
      end if;
      return Model.Links (Index);
   end Link_At;

   function Count_Status
     (Model  : Cross_Unit_Closure_Model;
      Status : Cross_Unit_Link_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Link of Model.Links loop
         if Link.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Cross_Unit_Closure_Model;
      Kind  : Cross_Unit_Link_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Link of Model.Links loop
         if Link.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Resolved_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Link_Resolved);
   end Resolved_Count;

   function Missing_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Link_Missing);
   end Missing_Count;

   function Ambiguous_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Link_Ambiguous);
   end Ambiguous_Count;

   function Overflow_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Link_Overflow);
   end Overflow_Count;

   function Spec_Body_Link_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Spec_To_Body)
        + Count_Kind (Model, Cross_Unit_Body_To_Spec);
   end Spec_Body_Link_Count;

   function Child_Parent_Link_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Child_To_Parent);
   end Child_Parent_Link_Count;

   function Parent_Child_Link_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Parent_To_Child);
   end Parent_Child_Link_Count;

   function Separate_Parent_Link_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Separate_To_Parent);
   end Separate_Parent_Link_Count;

   function With_Dependency_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_With_Dependency)
        + Count_Kind (Model, Cross_Unit_Limited_With_Dependency)
        + Count_Kind (Model, Cross_Unit_Private_With_Dependency);
   end With_Dependency_Count;

   function Limited_With_Dependency_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Limited_With_Dependency);
   end Limited_With_Dependency_Count;

   function Private_With_Dependency_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Private_With_Dependency);
   end Private_With_Dependency_Count;

   function Use_Dependency_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Use_Dependency);
   end Use_Dependency_Count;

   function Context_Dependency_Count (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return With_Dependency_Count (Model) + Use_Dependency_Count (Model);
   end Context_Dependency_Count;

   function Spec_Body_Consistency_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Natural (Model.Spec_Body_Consistency.Length);
   end Spec_Body_Consistency_Count;

   function Spec_Body_Consistency_At
     (Model : Cross_Unit_Closure_Model;
      Index : Positive) return Spec_Body_Consistency_Info
   is
   begin
      if Model.Spec_Body_Consistency.Is_Empty
        or else Index < Model.Spec_Body_Consistency.First_Index
        or else Index > Model.Spec_Body_Consistency.Last_Index
      then
         return (others => <>);
      end if;
      return Model.Spec_Body_Consistency (Index);
   end Spec_Body_Consistency_At;

   function Count_Consistency_Status
     (Model  : Cross_Unit_Closure_Model;
      Status : Spec_Body_Consistency_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Spec_Body_Consistency loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Consistency_Status;

   function Spec_Body_Consistent_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Count_Consistency_Status
        (Model, Spec_Body_Consistency_Confirmed);
   end Spec_Body_Consistent_Count;

   function Spec_Body_Inconsistent_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Spec_Body_Consistency_Count (Model)
        - Spec_Body_Consistent_Count (Model);
   end Spec_Body_Inconsistent_Count;

   function Spec_Body_Missing_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Count_Consistency_Status
        (Model, Spec_Body_Consistency_Missing_Counterpart);
   end Spec_Body_Missing_Count;

   function Spec_Body_Ambiguous_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Count_Consistency_Status
        (Model, Spec_Body_Consistency_Ambiguous_Counterpart);
   end Spec_Body_Ambiguous_Count;

   function Child_Unit_Legality_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Natural (Model.Child_Unit_Legality.Length);
   end Child_Unit_Legality_Count;

   function Child_Unit_Legality_At
     (Model : Cross_Unit_Closure_Model;
      Index : Positive) return Child_Unit_Legality_Info
   is
   begin
      if Model.Child_Unit_Legality.Is_Empty
        or else Index < Model.Child_Unit_Legality.First_Index
        or else Index > Model.Child_Unit_Legality.Last_Index
      then
         return (others => <>);
      end if;
      return Model.Child_Unit_Legality (Index);
   end Child_Unit_Legality_At;

   function Count_Child_Legality_Status
     (Model  : Cross_Unit_Closure_Model;
      Status : Child_Unit_Legality_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Child_Unit_Legality loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Child_Legality_Status;

   function Child_Unit_Resolved_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Count_Child_Legality_Status
          (Model, Child_Unit_Legality_Public_Child_Resolved)
        + Count_Child_Legality_Status
          (Model, Child_Unit_Legality_Private_Child_Resolved);
   end Child_Unit_Resolved_Count;

   function Private_Child_Unit_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Count_Child_Legality_Status
        (Model, Child_Unit_Legality_Private_Child_Resolved);
   end Private_Child_Unit_Count;

   function Child_Unit_Parent_Error_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Child_Unit_Legality_Count (Model)
        - Child_Unit_Resolved_Count (Model);
   end Child_Unit_Parent_Error_Count;

   function Child_Unit_Missing_Parent_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Count_Child_Legality_Status
        (Model, Child_Unit_Legality_Missing_Parent);
   end Child_Unit_Missing_Parent_Count;



   function Separate_Body_Legality_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Natural (Model.Separate_Body_Legality.Length);
   end Separate_Body_Legality_Count;

   function Separate_Body_Legality_At
     (Model : Cross_Unit_Closure_Model;
      Index : Positive) return Separate_Body_Legality_Info
   is
   begin
      if Model.Separate_Body_Legality.Is_Empty
        or else Index < Model.Separate_Body_Legality.First_Index
        or else Index > Model.Separate_Body_Legality.Last_Index
      then
         return (others => <>);
      end if;
      return Model.Separate_Body_Legality (Index);
   end Separate_Body_Legality_At;

   function Count_Separate_Legality_Status
     (Model  : Cross_Unit_Closure_Model;
      Status : Separate_Body_Legality_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Separate_Body_Legality loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Separate_Legality_Status;

   function Separate_Body_Resolved_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Count_Separate_Legality_Status
        (Model, Separate_Body_Legality_Parent_Resolved);
   end Separate_Body_Resolved_Count;

   function Separate_Body_Parent_Error_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Separate_Body_Legality_Count (Model)
        - Separate_Body_Resolved_Count (Model);
   end Separate_Body_Parent_Error_Count;

   function Separate_Body_Missing_Parent_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Count_Separate_Legality_Status
        (Model, Separate_Body_Legality_Missing_Parent);
   end Separate_Body_Missing_Parent_Count;

   function Separate_Body_Ambiguous_Parent_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Count_Separate_Legality_Status
        (Model, Separate_Body_Legality_Ambiguous_Parent);
   end Separate_Body_Ambiguous_Parent_Count;

   function Separate_Body_Target_Name_Missing_Count
     (Model : Cross_Unit_Closure_Model) return Natural
   is
   begin
      return Count_Separate_Legality_Status
        (Model, Separate_Body_Legality_Target_Name_Missing);
   end Separate_Body_Target_Name_Missing_Count;

   function Fingerprint (Model : Cross_Unit_Closure_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Cross_Unit_Closure;
