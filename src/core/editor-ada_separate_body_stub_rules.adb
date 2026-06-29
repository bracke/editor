with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;

package body Editor.Ada_Separate_Body_Stub_Rules is

   pragma Suppress (Overflow_Check);

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (S);
   end Normalize;

   procedure Mix (Value : in out Natural; Text : String) is
   begin
      for Ch of Text loop
         Value := Natural
           ((Long_Long_Integer (Value) * 131
             + Long_Long_Integer (Character'Pos (Ch)) + 1)
            mod 1_000_000_007);
      end loop;
   end Mix;

   procedure Mix (Value : in out Natural; N : Natural) is
   begin
      Value := Natural
        ((Long_Long_Integer (Value) * 131 + Long_Long_Integer (N) + 1)
         mod 1_000_000_007);
   end Mix;

   function Tail_Name (Name : String) return String is
   begin
      for I in reverse Name'Range loop
         if Name (I) = '.' then
            if I < Name'Last then
               return Name (I + 1 .. Name'Last);
            else
               return "";
            end if;
         end if;
      end loop;
      return Name;
   end Tail_Name;

   function Status_For_Parent
     (Legality : Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Info)
      return Separate_Body_Stub_Status is
      use type Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Status;
   begin
      case Legality.Status is
         when Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Parent_Resolved =>
            return Separate_Body_Stub_Not_Found;
         when Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Missing_Parent =>
            return Separate_Body_Stub_Missing_Parent;
         when Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Ambiguous_Parent =>
            return Separate_Body_Stub_Ambiguous_Parent;
         when Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Overflow =>
            return Separate_Body_Stub_Overflow;
         when Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Parent_Role_Mismatch =>
            return Separate_Body_Stub_Parent_Role_Mismatch;
         when Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Target_Name_Missing =>
            return Separate_Body_Stub_Target_Name_Missing;
         when others =>
            return Separate_Body_Stub_Not_Found;
      end case;
   end Status_For_Parent;

   function Is_Body_Stub
     (Symbol : Editor.Ada_Language_Model.Symbol_Info) return Boolean is
   begin
      return Symbol.Flags.Has_Body_Stub_Metadata
        and then Symbol.Flags.Is_Separate;
   end Is_Body_Stub;

   function Kind_Compatible
     (Separate_Symbol : Editor.Ada_Language_Model.Symbol_Info;
      Stub_Symbol     : Editor.Ada_Language_Model.Symbol_Info) return Boolean
   is
      use type Editor.Ada_Language_Model.Symbol_Kind;
   begin
      if Separate_Symbol.Kind /= Editor.Ada_Language_Model.Symbol_Separate_Body then
         return False;
      end if;

      return Stub_Symbol.Kind = Editor.Ada_Language_Model.Symbol_Procedure
        or else Stub_Symbol.Kind = Editor.Ada_Language_Model.Symbol_Function
        or else Stub_Symbol.Kind = Editor.Ada_Language_Model.Symbol_Package_Body
        or else Stub_Symbol.Kind = Editor.Ada_Language_Model.Symbol_Separate_Body
        or else Stub_Symbol.Kind = Editor.Ada_Language_Model.Symbol_Task
        or else Stub_Symbol.Kind = Editor.Ada_Language_Model.Symbol_Protected
        or else Stub_Symbol.Kind = Editor.Ada_Language_Model.Symbol_Entry;
   end Kind_Compatible;

   function Profiles_Compatible
     (Separate_Symbol : Editor.Ada_Language_Model.Symbol_Info;
      Stub_Symbol     : Editor.Ada_Language_Model.Symbol_Info) return Separate_Body_Stub_Status
   is
      Sep_Profile  : constant String := To_String (Separate_Symbol.Profile_Summary);
      Stub_Profile : constant String := To_String (Stub_Symbol.Profile_Summary);
   begin
      if Sep_Profile'Length = 0 or else Stub_Profile'Length = 0 then
         return Separate_Body_Stub_Profile_Unknown;
      elsif Normalize (Sep_Profile) = Normalize (Stub_Profile) then
         return Separate_Body_Stub_Matched;
      else
         return Separate_Body_Stub_Profile_Mismatch;
      end if;
   end Profiles_Compatible;

   function Separate_Unit_For
     (Index : Editor.Ada_Project_Index.Index_State;
      Path  : String) return Editor.Ada_Project_Index.Indexed_Unit
   is
      use type Editor.Ada_Project_Index.Indexed_Unit_Role;
   begin
      for I in 1 .. Editor.Ada_Project_Index.Unit_Count (Index) loop
         declare
            Unit : constant Editor.Ada_Project_Index.Indexed_Unit :=
              Editor.Ada_Project_Index.Unit_At (Index, I);
         begin
            if To_String (Unit.Path) = Path
              and then Unit.Role = Editor.Ada_Project_Index.Unit_Separate_Body
            then
               return Unit;
            end if;
         end;
      end loop;
      return (others => <>);
   end Separate_Unit_For;

   function Parent_Analysis_For
     (Index : Editor.Ada_Project_Index.Index_State;
      Path  : String) return Editor.Ada_Language_Model.Analysis_Result
   is
      Empty : Editor.Ada_Language_Model.Analysis_Result;
   begin
      for I in 1 .. Editor.Ada_Project_Index.File_Count (Index) loop
         declare
            Key : constant Editor.Ada_Project_Index.Indexed_File_Key :=
              Editor.Ada_Project_Index.File_Key_At (Index, I);
         begin
            if To_String (Key.Path) = Path then
               return Editor.Ada_Project_Index.File_Analysis_At (Index, I);
            end if;
         end;
      end loop;
      return Empty;
   end Parent_Analysis_For;

   procedure Finalize_Fingerprint (Info : in out Separate_Body_Stub_Info) is
      FP : Natural := 67;
   begin
      Mix (FP, Separate_Body_Stub_Status'Pos (Info.Status));
      Mix (FP, To_String (Info.Separate_Unit_Name));
      Mix (FP, To_String (Info.Separate_Path));
      Mix (FP, To_String (Info.Parent_Unit_Name));
      Mix (FP, To_String (Info.Parent_Path));
      Mix (FP, To_String (Info.Parent_Name_Text));
      Mix (FP, To_String (Info.Stub_Name));
      Mix (FP, To_String (Info.Stub_Path));
      Mix (FP, Info.Stub_Count);
      Mix (FP, Info.Candidate_Count);
      Info.Fingerprint := FP;
   end Finalize_Fingerprint;

   function To_Info
     (Index    : Editor.Ada_Project_Index.Index_State;
      Legality : Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Info)
      return Separate_Body_Stub_Info
   is
      Info : Separate_Body_Stub_Info;
      Separate_Unit : constant Editor.Ada_Project_Index.Indexed_Unit :=
        Separate_Unit_For (Index, To_String (Legality.Separate_Path));
      Parent_Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Separate_Name : constant String :=
        (if Length (Separate_Unit.Symbol.Name) > 0
         then To_String (Separate_Unit.Symbol.Name)
         else Tail_Name (To_String (Legality.Separate_Unit_Name)));
      Target_Name : constant String := Tail_Name (Separate_Name);
      Found_Stub : Editor.Ada_Language_Model.Symbol_Info;
      Found_Count : Natural := 0;
   begin
      Info.Separate_Unit_Name := To_Unbounded_String (Separate_Name);
      Info.Separate_Path := Legality.Separate_Path;
      Info.Parent_Unit_Name := Legality.Parent_Unit_Name;
      Info.Parent_Path := Legality.Parent_Path;
      Info.Parent_Name_Text := Legality.Parent_Name_Text;
      Info.Candidate_Count := Legality.Candidate_Count;
      Info.Status := Status_For_Parent (Legality);

      if Info.Status /= Separate_Body_Stub_Not_Found then
         Finalize_Fingerprint (Info);
         return Info;
      end if;

      Parent_Analysis := Parent_Analysis_For (Index, To_String (Legality.Parent_Path));

      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Parent_Analysis) loop
         declare
            Stub : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Parent_Analysis, I);
         begin
            if Is_Body_Stub (Stub)
              and then Normalize (To_String (Stub.Name)) = Normalize (Target_Name)
            then
               Found_Count := Found_Count + 1;
               if Found_Count = 1 then
                  Found_Stub := Stub;
               end if;
            end if;
         end;
      end loop;

      Info.Stub_Count := Found_Count;
      if Found_Count = 0 then
         Info.Status := Separate_Body_Stub_Missing;
      elsif Found_Count > 1 then
         Info.Status := Separate_Body_Stub_Ambiguous;
      else
         Info.Stub_Name := Found_Stub.Name;
         Info.Stub_Path := Legality.Parent_Path;
         if not Kind_Compatible (Separate_Unit.Symbol, Found_Stub) then
            Info.Status := Separate_Body_Stub_Kind_Mismatch;
         else
            Info.Status := Profiles_Compatible (Separate_Unit.Symbol, Found_Stub);
            if Info.Status = Separate_Body_Stub_Profile_Unknown then
               --  Package/task/protected/entry stubs may not retain a complete
               --  profile summary at this semantic layer.  A unique same-name
               --  body-stub match is still a valid placement anchor.
               Info.Status := Separate_Body_Stub_Matched;
            end if;
         end if;
      end if;

      Finalize_Fingerprint (Info);
      return Info;
   end To_Info;

   function Build
     (Index   : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model)
      return Separate_Body_Stub_Model
   is
      Model : Separate_Body_Stub_Model;
      FP    : Natural := 71;
   begin
      Mix (FP, Editor.Ada_Project_Index.Fingerprint (Index));
      Mix (FP, Editor.Ada_Cross_Unit_Closure.Fingerprint (Closure));

      for I in 1 .. Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Count (Closure) loop
         declare
            Legality : constant Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Info :=
              Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_At (Closure, I);
            Info : constant Separate_Body_Stub_Info := To_Info (Index, Legality);
         begin
            Model.Items.Append (Info);
            Mix (FP, Info.Fingerprint);
         end;
      end loop;

      Model.Model_Fingerprint := FP;
      return Model;
   end Build;

   function Stub_Check_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Stub_Check_Count;

   function Stub_Check_At
     (Model : Separate_Body_Stub_Model;
      Index : Positive) return Separate_Body_Stub_Info is
   begin
      return Model.Items.Element (Index);
   end Stub_Check_At;

   function Lookup_Separate
     (Model              : Separate_Body_Stub_Model;
      Separate_Unit_Name : String) return Separate_Body_Stub_Info
   is
      Name  : constant String := Normalize (Separate_Unit_Name);
      Found : Separate_Body_Stub_Info;
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Normalize (To_String (Info.Separate_Unit_Name)) = Name
           or else Normalize (Tail_Name (To_String (Info.Separate_Unit_Name))) = Name
         then
            Count := Count + 1;
            if Count = 1 then
               Found := Info;
            end if;
         end if;
      end loop;

      if Count = 0 then
         Found.Status := Separate_Body_Stub_Not_Found;
         Found.Separate_Unit_Name := To_Unbounded_String (Separate_Unit_Name);
         Found.Fingerprint := 0;
      elsif Count > 1 then
         Found.Status := Separate_Body_Stub_Ambiguous;
         Found.Candidate_Count := Count;
         Found.Fingerprint := Found.Fingerprint + Count;
      end if;

      return Found;
   end Lookup_Separate;

   function Count_Status
     (Model  : Separate_Body_Stub_Model;
      Status : Separate_Body_Stub_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Matched_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Count_Status (Model, Separate_Body_Stub_Matched);
   end Matched_Count;

   function Missing_Stub_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Count_Status (Model, Separate_Body_Stub_Missing);
   end Missing_Stub_Count;

   function Ambiguous_Stub_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Count_Status (Model, Separate_Body_Stub_Ambiguous);
   end Ambiguous_Stub_Count;

   function Kind_Mismatch_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Count_Status (Model, Separate_Body_Stub_Kind_Mismatch);
   end Kind_Mismatch_Count;

   function Profile_Mismatch_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Count_Status (Model, Separate_Body_Stub_Profile_Mismatch);
   end Profile_Mismatch_Count;

   function Profile_Unknown_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Count_Status (Model, Separate_Body_Stub_Profile_Unknown);
   end Profile_Unknown_Count;

   function Parent_Error_Count (Model : Separate_Body_Stub_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Separate_Body_Stub_Missing_Parent
           or else Info.Status = Separate_Body_Stub_Ambiguous_Parent
           or else Info.Status = Separate_Body_Stub_Overflow
           or else Info.Status = Separate_Body_Stub_Parent_Role_Mismatch
           or else Info.Status = Separate_Body_Stub_Target_Name_Missing
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Parent_Error_Count;

   function Missing_Parent_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Count_Status (Model, Separate_Body_Stub_Missing_Parent);
   end Missing_Parent_Count;

   function Ambiguous_Parent_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Count_Status (Model, Separate_Body_Stub_Ambiguous_Parent);
   end Ambiguous_Parent_Count;

   function Overflow_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Count_Status (Model, Separate_Body_Stub_Overflow);
   end Overflow_Count;

   function Target_Name_Missing_Count (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Count_Status (Model, Separate_Body_Stub_Target_Name_Missing);
   end Target_Name_Missing_Count;

   function Fingerprint (Model : Separate_Body_Stub_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Separate_Body_Stub_Rules;
