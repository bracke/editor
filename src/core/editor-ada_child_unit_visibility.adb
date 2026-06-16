with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Child_Unit_Visibility is

   pragma Suppress (Overflow_Check);

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (S);
   end Normalize;

   procedure Mix (Value : in out Natural; Text : String) is
   begin
      for Ch of Text loop
         Value := (Value * 131 + Character'Pos (Ch)) mod 1_000_000_007;
      end loop;
   end Mix;

   procedure Mix (Value : in out Natural; N : Natural) is
   begin
      Value := (Value * 131 + N) mod 1_000_000_007;
   end Mix;

   function Status_For
     (Legality : Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Info;
      Context  : Child_Visibility_Context) return Child_Visibility_Status is
      use type Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Status;
   begin
      case Legality.Status is
         when Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Public_Child_Resolved =>
            return Child_Visibility_Public_Child_Visible;
         when Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Private_Child_Resolved =>
            case Context is
               when Child_Visibility_Context_Parent_Private_Part =>
                  return Child_Visibility_Private_Child_Visible_In_Private_Context;
               when Child_Visibility_Context_Parent_Body =>
                  return Child_Visibility_Private_Child_Visible_In_Body_Context;
               when others =>
                  return Child_Visibility_Private_Child_Hidden;
            end case;
         when Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Missing_Parent =>
            return Child_Visibility_Missing_Parent;
         when Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Ambiguous_Parent =>
            return Child_Visibility_Ambiguous_Parent;
         when Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Overflow =>
            return Child_Visibility_Overflow;
         when Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Parent_Role_Mismatch =>
            return Child_Visibility_Parent_Role_Mismatch;
         when others =>
            return Child_Visibility_Not_Found;
      end case;
   end Status_For;

   procedure Apply_Visibility_Flags
     (Info    : in out Child_Visibility_Info;
      Context : Child_Visibility_Context)
   is
      use type Child_Visibility_Status;
   begin
      Info.External_Client_Visible := False;
      Info.Parent_Visible_Part_Visible := False;
      Info.Parent_Private_Part_Visible := False;
      Info.Parent_Body_Visible := False;

      if Info.Status = Child_Visibility_Public_Child_Visible then
         Info.External_Client_Visible := True;
         Info.Parent_Visible_Part_Visible := True;
         Info.Parent_Private_Part_Visible := True;
         Info.Parent_Body_Visible := True;
      elsif Info.Status = Child_Visibility_Private_Child_Hidden
        or else Info.Status = Child_Visibility_Private_Child_Visible_In_Private_Context
        or else Info.Status = Child_Visibility_Private_Child_Visible_In_Body_Context
      then
         Info.External_Client_Visible := False;
         Info.Parent_Visible_Part_Visible := False;
         Info.Parent_Private_Part_Visible := True;
         Info.Parent_Body_Visible := True;

         case Context is
            when Child_Visibility_Context_Parent_Private_Part =>
               Info.Status := Child_Visibility_Private_Child_Visible_In_Private_Context;
            when Child_Visibility_Context_Parent_Body =>
               Info.Status := Child_Visibility_Private_Child_Visible_In_Body_Context;
            when others =>
               Info.Status := Child_Visibility_Private_Child_Hidden;
         end case;
      end if;
   end Apply_Visibility_Flags;

   function To_Info
     (Legality : Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Info;
      Context  : Child_Visibility_Context) return Child_Visibility_Info is
      Info : Child_Visibility_Info;
      FP   : Natural := 53;
   begin
      Info.Status := Status_For (Legality, Context);
      Info.Parent_Unit_Name := Legality.Parent_Unit_Name;
      Info.Parent_Path := Legality.Parent_Path;
      Info.Child_Unit_Name := Legality.Child_Unit_Name;
      Info.Child_Path := Legality.Child_Path;
      Info.Is_Private_Child := Legality.Is_Private_Child;
      Info.Candidate_Count := Legality.Candidate_Count;
      Apply_Visibility_Flags (Info, Context);

      Mix (FP, Child_Visibility_Status'Pos (Info.Status));
      Mix (FP, Child_Visibility_Context'Pos (Context));
      Mix (FP, To_String (Info.Parent_Unit_Name));
      Mix (FP, To_String (Info.Parent_Path));
      Mix (FP, To_String (Info.Child_Unit_Name));
      Mix (FP, To_String (Info.Child_Path));
      Mix (FP, Boolean'Pos (Info.Is_Private_Child));
      Mix (FP, Boolean'Pos (Info.External_Client_Visible));
      Mix (FP, Boolean'Pos (Info.Parent_Visible_Part_Visible));
      Mix (FP, Boolean'Pos (Info.Parent_Private_Part_Visible));
      Mix (FP, Boolean'Pos (Info.Parent_Body_Visible));
      Mix (FP, Info.Candidate_Count);
      Info.Fingerprint := FP;
      return Info;
   end To_Info;

   function Build
     (Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model)
      return Child_Visibility_Model is
      Model : Child_Visibility_Model;
      FP    : Natural := 59;
   begin
      Mix (FP, Editor.Ada_Cross_Unit_Closure.Fingerprint (Closure));

      for I in 1 .. Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Count (Closure) loop
         declare
            Legality : constant Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Info :=
              Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_At (Closure, I);
            Info : constant Child_Visibility_Info :=
              To_Info (Legality, Child_Visibility_Context_External_Client);
         begin
            Model.Items.Append (Info);
            Mix (FP, Info.Fingerprint);
         end;
      end loop;

      Model.Model_Fingerprint := FP;
      return Model;
   end Build;

   function Visibility_Count (Model : Child_Visibility_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Visibility_Count;

   function Visibility_At
     (Model : Child_Visibility_Model;
      Index : Positive) return Child_Visibility_Info is
   begin
      return Model.Items.Element (Index);
   end Visibility_At;

   function Matches_Child
     (Info             : Child_Visibility_Info;
      Parent_Unit_Name : String;
      Child_Name       : String) return Boolean
   is
      Parent : constant String := Normalize (Parent_Unit_Name);
      Child  : constant String := Normalize (Child_Name);
      Full   : constant String := Normalize (To_String (Info.Child_Unit_Name));
      Parent_Name : constant String := Normalize (To_String (Info.Parent_Unit_Name));
   begin
      if Parent_Name /= Parent then
         return False;
      end if;

      return Full = Child
        or else Full = Parent & "." & Child
        or else Normalize (To_String (Info.Child_Unit_Name)) = Child;
   end Matches_Child;

   function Lookup_Child
     (Model            : Child_Visibility_Model;
      Parent_Unit_Name : String;
      Child_Name       : String;
      Context          : Child_Visibility_Context) return Child_Visibility_Info is
      Found : Child_Visibility_Info;
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Matches_Child (Info, Parent_Unit_Name, Child_Name) then
            Count := Count + 1;
            if Count = 1 then
               Found := Info;
            end if;
         end if;
      end loop;

      if Count = 0 then
         Found.Status := Child_Visibility_Not_Found;
         Found.Parent_Unit_Name := To_Unbounded_String (Parent_Unit_Name);
         Found.Child_Unit_Name := To_Unbounded_String (Child_Name);
         Found.Fingerprint := 0;
         return Found;
      elsif Count > 1 then
         Found.Status := Child_Visibility_Ambiguous_Parent;
         Found.Candidate_Count := Count;
         Found.External_Client_Visible := False;
         Found.Parent_Visible_Part_Visible := False;
         Found.Parent_Private_Part_Visible := False;
         Found.Parent_Body_Visible := False;
         Found.Fingerprint := Found.Fingerprint + Count;
         return Found;
      end if;

      if Found.Is_Private_Child then
         Apply_Visibility_Flags (Found, Context);
         declare
            FP : Natural := Found.Fingerprint;
         begin
            Mix (FP, Child_Visibility_Context'Pos (Context));
            Mix (FP, Child_Visibility_Status'Pos (Found.Status));
            Found.Fingerprint := FP;
         end;
      end if;

      return Found;
   end Lookup_Child;

   function Visible_In_Context
     (Model            : Child_Visibility_Model;
      Parent_Unit_Name : String;
      Child_Name       : String;
      Context          : Child_Visibility_Context) return Boolean is
      Info : constant Child_Visibility_Info :=
        Lookup_Child (Model, Parent_Unit_Name, Child_Name, Context);
   begin
      case Context is
         when Child_Visibility_Context_External_Client =>
            return Info.External_Client_Visible;
         when Child_Visibility_Context_Parent_Visible_Part =>
            return Info.Parent_Visible_Part_Visible;
         when Child_Visibility_Context_Parent_Private_Part =>
            return Info.Parent_Private_Part_Visible;
         when Child_Visibility_Context_Parent_Body =>
            return Info.Parent_Body_Visible;
      end case;
   end Visible_In_Context;

   function Count_Status
     (Model  : Child_Visibility_Model;
      Status : Child_Visibility_Status) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Public_Child_Visible_Count (Model : Child_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Child_Visibility_Public_Child_Visible);
   end Public_Child_Visible_Count;

   function Private_Child_Hidden_Count (Model : Child_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Child_Visibility_Private_Child_Hidden);
   end Private_Child_Hidden_Count;

   function Private_Child_Private_Context_Visible_Count
     (Model : Child_Visibility_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Is_Private_Child and then Info.Parent_Private_Part_Visible then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Private_Child_Private_Context_Visible_Count;

   function Private_Child_Body_Context_Visible_Count
     (Model : Child_Visibility_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Is_Private_Child and then Info.Parent_Body_Visible then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Private_Child_Body_Context_Visible_Count;

   function Parent_Error_Count (Model : Child_Visibility_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Child_Visibility_Missing_Parent
           or else Info.Status = Child_Visibility_Ambiguous_Parent
           or else Info.Status = Child_Visibility_Overflow
           or else Info.Status = Child_Visibility_Parent_Role_Mismatch
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Parent_Error_Count;

   function Missing_Parent_Count (Model : Child_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Child_Visibility_Missing_Parent);
   end Missing_Parent_Count;

   function Ambiguous_Parent_Count (Model : Child_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Child_Visibility_Ambiguous_Parent);
   end Ambiguous_Parent_Count;

   function Overflow_Count (Model : Child_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Child_Visibility_Overflow);
   end Overflow_Count;

   function Fingerprint (Model : Child_Visibility_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Child_Unit_Visibility;
