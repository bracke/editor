separate (Editor.Ada_Generic_Contracts)
package body Instance_Matching is

   function Substitute_Generic_Formal_Subtypes
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Info;
      Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Subtypes : String) return String
   is
      First : Natural := Subtypes'First;
      Result : Unbounded_String;

      function Type_Actual_For (Formal_Name : String) return String is
         Position : Natural := 0;
         N : constant String := Normalize (Formal_Name);
      begin
         for F of Model.Formals loop
            if F.Region = Region then
               Position := Position + 1;
               if To_String (F.Normalized_Name) = N and then F.Kind = Generic_Formal_Type then
                  if Position <= Instance.Positional_Actuals then
                     return Normalize
                       (Delimited_Text_At
                          (To_String (Instance.Positional_Actual_Texts),
                           Positive (Position)));
                  elsif List_Contains_Name
                    (To_String (Instance.Named_Actual_Names), N)
                  then
                     return Normalize
                       (Named_Text_For (To_String (Instance.Named_Actual_Texts), N));
                  end if;
               end if;
            end if;
         end loop;
         return N;
      end Type_Actual_For;
   begin
      if Subtypes = "" then
         return "";
      end if;
      while First <= Subtypes'Last loop
         declare
            Sep  : Natural := Ada.Strings.Fixed.Index (Subtypes (First .. Subtypes'Last), "|");
            Last : Natural := Subtypes'Last;
            Replacement : Unbounded_String;
         begin
            if Sep /= 0 then
               Last := Sep - 1;
            end if;
            Replacement := To_Unbounded_String (Type_Actual_For (Subtypes (First .. Last)));
            if Length (Result) = 0 then
               Result := Replacement;
            else
               Result := Result & "|" & Replacement;
            end if;
            exit when Sep = 0;
            First := Sep + 1;
         end;
      end loop;
      return To_String (Result);
   end Substitute_Generic_Formal_Subtypes;

   function Subprogram_Profile_Compatible
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      From_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Formal     : Generic_Formal_Info;
      Actual_Text : String) return Generic_Formal_Actual_Kind_Match
   is
      Designator : constant String := Normalize (Actual_Text);
      Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
      Actual_Decl : Editor.Ada_Direct_Visibility.Declaration_Info;
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : Unbounded_String;
   begin
      if Formal.Kind /= Generic_Formal_Subprogram then
         return Generic_Formal_Actual_Kind_Unknown;
      elsif Designator = "" or else Ada.Strings.Fixed.Index (Designator, "'") /= 0 then
         return Generic_Formal_Actual_Kind_Unknown;
      end if;

      Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
        (Visibility, Regions, From_Region, Designator);
      if Lookup.Status /= Editor.Ada_Direct_Visibility.Lookup_Found then
         return Generic_Formal_Actual_Kind_Unknown;
      end if;

      Actual_Decl := Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
      if Declaration_To_Actual_Kind (Actual_Decl.Kind) /= Generic_Actual_Subprogram then
         return Generic_Formal_Actual_Kind_Mismatch;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Actual_Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      Expected_Subtypes := To_Unbounded_String
        (Substitute_Generic_Formal_Subtypes
           (Model, Instance, Formal.Region,
            To_String (Formal.Formal_Parameter_Subtypes)));
      if Malformed then
         return Generic_Formal_Actual_Kind_Unknown;
      elsif Actual_Parameters = Formal.Formal_Parameter_Count
        and then To_String (Actual_Subtypes) = To_String (Expected_Subtypes)
        and then To_String (Actual_Modes) = To_String (Formal.Formal_Parameter_Modes)
        and then To_String (Actual_Names) = To_String (Formal.Formal_Parameter_Names)
        and then Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        and then Actual_Has_Result = Formal.Formal_Has_Result
        and then (not Formal.Formal_Has_Result
                  or else To_String (Actual_Result) = To_String (Formal.Formal_Result_Subtype))
      then
         return Generic_Formal_Actual_Kind_Matches;
      else
         return Generic_Formal_Actual_Kind_Mismatch;
      end if;
   end Subprogram_Profile_Compatible;


   type Subprogram_Profile_Selection_Status is
     (Subprogram_Profile_Selected,
      Subprogram_Profile_No_Candidates,
      Subprogram_Profile_No_Profile_Match,
      Subprogram_Profile_Mode_Mismatch,
      Subprogram_Profile_Null_Exclusion_Mismatch,
      Subprogram_Profile_Access_Profile_Mismatch,
      Subprogram_Profile_Convention_Mismatch,
      Subprogram_Profile_Default_Mismatch,
      Subprogram_Profile_Class_Wide_Mismatch,
      Subprogram_Profile_Name_Mismatch,
      Subprogram_Profile_Result_Mismatch,
      Subprogram_Profile_Ambiguous_Profile_Match,
      Subprogram_Profile_Unknown);

   type Subprogram_Profile_Selection_Info is record
      Status           : Subprogram_Profile_Selection_Status :=
        Subprogram_Profile_Unknown;
      Candidate_Count  : Natural := 0;
      Compatible_Count : Natural := 0;
      Mode_Mismatch_Count : Natural := 0;
      Null_Exclusion_Mismatch_Count : Natural := 0;
      Access_Profile_Mismatch_Count : Natural := 0;
      Convention_Mismatch_Count : Natural := 0;
      Default_Mismatch_Count : Natural := 0;
      Class_Wide_Mismatch_Count : Natural := 0;
      Name_Mismatch_Count : Natural := 0;
      Result_Compatible_Count : Natural := 0;
      Result_Mismatch_Count : Natural := 0;
      Result_Unknown_Count : Natural := 0;
      Type_Compatible_Count : Natural := 0;
      Type_Mismatch_Count : Natural := 0;
      Type_Unknown_Count : Natural := 0;
      Selected         : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
   end record;


   subtype Profile_Type_Conformance_Status is
     Editor.Ada_Generic_Contracts.Type_Conformance.Profile_Type_Conformance_Status;

   function Type_Id_For_Profile_Subtype
     (Types  : Editor.Ada_Type_Graph.Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Editor.Ada_Type_Graph.Type_Id
     renames Editor.Ada_Generic_Contracts.Type_Conformance.Type_Id_For_Profile_Subtype;

   function Type_Graph_Profile_Subtypes_Conform
     (Types           : Editor.Ada_Type_Graph.Type_Model;
      Formal_Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Expected_Subtypes : String;
      Actual_Subtypes   : String) return Profile_Type_Conformance_Status
     renames Editor.Ada_Generic_Contracts.Type_Conformance.Type_Graph_Profile_Subtypes_Conform;

   function Type_Graph_Result_Subtype_Conforms
     (Types         : Editor.Ada_Type_Graph.Type_Model;
      Formal_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Expected_Subtype : String;
      Actual_Subtype   : String) return Profile_Type_Conformance_Status
     renames Editor.Ada_Generic_Contracts.Type_Conformance.Type_Graph_Result_Subtype_Conforms;

   function Profile_Matches_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Check_Type_Graph : Boolean;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info;
      Ignore_Names : Boolean;
      Type_Status : out Profile_Type_Conformance_Status;
      Result_Status : out Profile_Type_Conformance_Status) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : Unbounded_String;
      Formal_Convention : constant String := To_String (Formal.Formal_Subprogram_Convention);
      Actual_Convention : constant String := Convention_For_Declaration (Tree, Decl.Node);
   begin
      Type_Status := Profile_Type_Conformance_Not_Checked;
      Result_Status := Profile_Type_Conformance_Not_Checked;
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed then
         return False;
      end if;

      Expected_Subtypes := To_Unbounded_String
        (Substitute_Generic_Formal_Subtypes
           (Model, Instance, Formal.Region,
            To_String (Formal.Formal_Parameter_Subtypes)));

      if Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else (not Ignore_Names
                 and then To_String (Actual_Names) /= To_String (Formal.Formal_Parameter_Names))
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
        or else Formal_Convention /= Actual_Convention
      then
         return False;
      end if;

      if To_String (Actual_Subtypes) = To_String (Expected_Subtypes) then
         Type_Status := Profile_Type_Conformance_Compatible;
      elsif Check_Type_Graph then
         Type_Status := Type_Graph_Profile_Subtypes_Conform
           (Types, Formal.Region, Decl.Region,
            To_String (Expected_Subtypes), To_String (Actual_Subtypes));
      else
         return False;
      end if;

      if Type_Status /= Profile_Type_Conformance_Compatible then
         return False;
      end if;

      if not Formal.Formal_Has_Result then
         Result_Status := Profile_Type_Conformance_Not_Checked;
         return True;
      end if;

      declare
         Expected_Result : constant String := Substitute_Generic_Formal_Subtypes
           (Model, Instance, Formal.Region, To_String (Formal.Formal_Result_Subtype));
         Actual_Result_Text : constant String := To_String (Actual_Result);
      begin
         if Normalize (Actual_Result_Text) = Normalize (Expected_Result) then
            Result_Status := Profile_Type_Conformance_Compatible;
            return True;
         elsif Check_Type_Graph then
            Result_Status := Type_Graph_Result_Subtype_Conforms
              (Types, Formal.Region, Decl.Region, Expected_Result, Actual_Result_Text);
            return Result_Status = Profile_Type_Conformance_Compatible;
         else
            Result_Status := Profile_Type_Conformance_Mismatch;
            return False;
         end if;
      end;
   end Profile_Matches_Formal;


   function Profile_Mode_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : Unbounded_String;
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed then
         return False;
      end if;

      Expected_Subtypes := To_Unbounded_String
        (Substitute_Generic_Formal_Subtypes
           (Model, Instance, Formal.Region,
            To_String (Formal.Formal_Parameter_Subtypes)));

      return Actual_Parameters = Formal.Formal_Parameter_Count
        and then To_String (Actual_Subtypes) = To_String (Expected_Subtypes)
        and then To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        and then Actual_Has_Result = Formal.Formal_Has_Result
        and then (not Formal.Formal_Has_Result
                  or else To_String (Actual_Result) = To_String (Formal.Formal_Result_Subtype));
   end Profile_Mode_Mismatch_Formal;



   function Profile_Field_At (List : String; Index : Positive) return String is
   begin
      return Normalize (Delimited_Text_At (List, Index));
   end Profile_Field_At;

   function Has_Null_Exclusion (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
   begin
      return Ada.Strings.Fixed.Index (Lower, "not null") /= 0;
   end Has_Null_Exclusion;

   function Without_Null_Exclusion (Text : String) return String is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
      Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower, "not null");
   begin
      if Pos = 0 then
         return Lower;
      elsif Pos = Lower'First then
         return Trim (Lower (Pos + 8 .. Lower'Last));
      elsif Pos + 7 >= Lower'Last then
         return Trim (Lower (Lower'First .. Pos - 1));
      else
         return Trim (Lower (Lower'First .. Pos - 1) & " " & Lower (Pos + 8 .. Lower'Last));
      end if;
   end Without_Null_Exclusion;

   function Is_Access_Subprogram_Profile (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
   begin
      return Ada.Strings.Fixed.Index (Lower, "access procedure") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "access function") /= 0;
   end Is_Access_Subprogram_Profile;



   function Has_Class_Wide_Marker (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
   begin
      return Ada.Strings.Fixed.Index (Lower, "'class") /= 0;
   end Has_Class_Wide_Marker;

   function Without_Class_Wide_Marker (Text : String) return String is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
      Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower, "'class");
   begin
      if Pos = 0 then
         return Lower;
      elsif Pos = Lower'First then
         return Trim (Lower (Pos + 6 .. Lower'Last));
      elsif Pos + 5 >= Lower'Last then
         return Trim (Lower (Lower'First .. Pos - 1));
      else
         return Trim (Lower (Lower'First .. Pos - 1) & " " & Lower (Pos + 6 .. Lower'Last));
      end if;
   end Without_Class_Wide_Marker;

   function Profile_Class_Wide_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
      Formal_Convention : constant String := To_String (Formal.Formal_Subprogram_Convention);
      Actual_Convention : constant String := Convention_For_Declaration (Tree, Decl.Node);
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
        or else Formal_Convention /= Actual_Convention
      then
         return False;
      end if;

      for I in 1 .. Formal.Formal_Parameter_Count loop
         declare
            Expected : constant String := Profile_Field_At (Expected_Subtypes, Positive (I));
            Actual   : constant String := Profile_Field_At (To_String (Actual_Subtypes), Positive (I));
         begin
            if Has_Class_Wide_Marker (Expected) /= Has_Class_Wide_Marker (Actual)
              and then Without_Class_Wide_Marker (Expected) = Without_Class_Wide_Marker (Actual)
            then
               return True;
            end if;
         end;
      end loop;

      if Formal.Formal_Has_Result
        and then Has_Class_Wide_Marker (To_String (Formal.Formal_Result_Subtype)) /=
                 Has_Class_Wide_Marker (To_String (Actual_Result))
        and then Without_Class_Wide_Marker (To_String (Formal.Formal_Result_Subtype)) =
                 Without_Class_Wide_Marker (To_String (Actual_Result))
      then
         return True;
      end if;

      return False;
   end Profile_Class_Wide_Mismatch_Formal;

   function Profile_Null_Exclusion_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
      then
         return False;
      end if;

      for I in 1 .. Formal.Formal_Parameter_Count loop
         declare
            Expected : constant String := Profile_Field_At (Expected_Subtypes, Positive (I));
            Actual   : constant String := Profile_Field_At (To_String (Actual_Subtypes), Positive (I));
         begin
            if Has_Null_Exclusion (Expected) /= Has_Null_Exclusion (Actual)
              and then Without_Null_Exclusion (Expected) = Without_Null_Exclusion (Actual)
            then
               return True;
            end if;
         end;
      end loop;

      if Formal.Formal_Has_Result
        and then Has_Null_Exclusion (To_String (Formal.Formal_Result_Subtype)) /=
                 Has_Null_Exclusion (To_String (Actual_Result))
        and then Without_Null_Exclusion (To_String (Formal.Formal_Result_Subtype)) =
                 Without_Null_Exclusion (To_String (Actual_Result))
      then
         return True;
      end if;

      return False;
   end Profile_Null_Exclusion_Mismatch_Formal;

   function Profile_Access_Profile_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
      then
         return False;
      end if;

      for I in 1 .. Formal.Formal_Parameter_Count loop
         declare
            Expected : constant String := Profile_Field_At (Expected_Subtypes, Positive (I));
            Actual   : constant String := Profile_Field_At (To_String (Actual_Subtypes), Positive (I));
         begin
            if Is_Access_Subprogram_Profile (Expected)
              and then Is_Access_Subprogram_Profile (Actual)
              and then Without_Null_Exclusion (Expected) /= Without_Null_Exclusion (Actual)
            then
               return True;
            end if;
         end;
      end loop;

      if Formal.Formal_Has_Result
        and then Is_Access_Subprogram_Profile (To_String (Formal.Formal_Result_Subtype))
        and then Is_Access_Subprogram_Profile (To_String (Actual_Result))
        and then Without_Null_Exclusion (To_String (Formal.Formal_Result_Subtype)) /=
                 Without_Null_Exclusion (To_String (Actual_Result))
      then
         return True;
      end if;

      return False;
   end Profile_Access_Profile_Mismatch_Formal;


   function Profile_Default_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
      Formal_Convention : constant String := To_String (Formal.Formal_Subprogram_Convention);
      Actual_Convention : constant String := Convention_For_Declaration (Tree, Decl.Node);
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Subtypes) /= Expected_Subtypes
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else Actual_Has_Result /= Formal.Formal_Has_Result
        or else Formal_Convention /= Actual_Convention
        or else (Formal.Formal_Has_Result
                 and then To_String (Actual_Result) /= To_String (Formal.Formal_Result_Subtype))
      then
         return False;
      end if;

      return not Parameter_Defaults_Conform
        (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults));
   end Profile_Default_Mismatch_Formal;


   function Profile_Name_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
      Formal_Convention : constant String := To_String (Formal.Formal_Subprogram_Convention);
      Actual_Convention : constant String := Convention_For_Declaration (Tree, Decl.Node);
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Subtypes) /= Expected_Subtypes
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
        or else Formal_Convention /= Actual_Convention
        or else (Formal.Formal_Has_Result
                 and then To_String (Actual_Result) /= To_String (Formal.Formal_Result_Subtype))
      then
         return False;
      end if;

      return To_String (Actual_Names) /= To_String (Formal.Formal_Parameter_Names);
   end Profile_Name_Mismatch_Formal;


   function Profile_Convention_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
      Formal_Convention : constant String := To_String (Formal.Formal_Subprogram_Convention);
      Actual_Convention : constant String := Convention_For_Declaration (Tree, Decl.Node);
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Subtypes) /= Expected_Subtypes
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
        or else (Formal.Formal_Has_Result
                 and then To_String (Actual_Result) /= To_String (Formal.Formal_Result_Subtype))
      then
         return False;
      end if;

      return Formal_Convention /= Actual_Convention;
   end Profile_Convention_Mismatch_Formal;

   function Select_Subprogram_Actual_By_Profile
     (Model       : Generic_Contract_Model;
      Instance    : Generic_Instance_Info;
      Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility  : Editor.Ada_Direct_Visibility.Visibility_Model;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Types       : Editor.Ada_Type_Graph.Type_Model;
      Check_Type_Graph : Boolean;
      From_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Formal      : Generic_Formal_Info;
      Actual_Text : String) return Subprogram_Profile_Selection_Info
   is
      Designator : constant String := Normalize (Actual_Text);
      Current    : Editor.Ada_Declarative_Regions.Region_Id := From_Region;
      Info       : Subprogram_Profile_Selection_Info;
   begin
      if Formal.Kind /= Generic_Formal_Subprogram
        or else Designator = ""
        or else Ada.Strings.Fixed.Index (Designator, "'") /= 0
      then
         Info.Status := Subprogram_Profile_Unknown;
         return Info;
      end if;

      while Current /= Editor.Ada_Declarative_Regions.No_Region loop
         declare
            Direct_Matches : Natural := 0;
         begin
            for I in 1 .. Editor.Ada_Direct_Visibility.Direct_Declaration_Count
              (Visibility, Current)
            loop
               declare
                  Decl_Id : constant Editor.Ada_Direct_Visibility.Declaration_Id :=
                    Editor.Ada_Direct_Visibility.Direct_Declaration_At
                      (Visibility, Current, I);
                  Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                    Editor.Ada_Direct_Visibility.Declaration (Visibility, Decl_Id);
               begin
                  if To_String (Decl.Normalized) = Designator then
                     Direct_Matches := Direct_Matches + 1;
                     if Declaration_To_Actual_Kind (Decl.Kind) = Generic_Actual_Subprogram then
                        Info.Candidate_Count := Info.Candidate_Count + 1;
                        declare
                           Type_Status : Profile_Type_Conformance_Status;
                           Result_Status : Profile_Type_Conformance_Status;
                        begin
                           if Profile_Matches_Formal
                             (Model, Instance, Tree, Types, Check_Type_Graph,
                              Formal, Decl, True, Type_Status, Result_Status)
                           then
                              Info.Compatible_Count := Info.Compatible_Count + 1;
                              if Type_Status = Profile_Type_Conformance_Compatible then
                                 Info.Type_Compatible_Count := Info.Type_Compatible_Count + 1;
                              end if;
                              if Result_Status = Profile_Type_Conformance_Compatible then
                                 Info.Result_Compatible_Count := Info.Result_Compatible_Count + 1;
                              end if;
                              if Info.Selected = Editor.Ada_Direct_Visibility.No_Declaration then
                                 Info.Selected := Decl.Id;
                              end if;
                              if Profile_Name_Mismatch_Formal
                                (Model, Instance, Tree, Formal, Decl)
                              then
                                 Info.Name_Mismatch_Count :=
                                   Info.Name_Mismatch_Count + 1;
                              end if;
                           elsif Type_Status = Profile_Type_Conformance_Mismatch then
                              Info.Type_Mismatch_Count := Info.Type_Mismatch_Count + 1;
                           elsif Type_Status = Profile_Type_Conformance_Unknown then
                              Info.Type_Unknown_Count := Info.Type_Unknown_Count + 1;
                           end if;
                           if Result_Status = Profile_Type_Conformance_Mismatch then
                              Info.Result_Mismatch_Count := Info.Result_Mismatch_Count + 1;
                           elsif Result_Status = Profile_Type_Conformance_Unknown then
                              Info.Result_Unknown_Count := Info.Result_Unknown_Count + 1;
                           end if;
                        end;
                        if Info.Compatible_Count = 0 and then Profile_Mode_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Mode_Mismatch_Count := Info.Mode_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0 and then Profile_Null_Exclusion_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Null_Exclusion_Mismatch_Count :=
                             Info.Null_Exclusion_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0 and then Profile_Access_Profile_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Access_Profile_Mismatch_Count :=
                             Info.Access_Profile_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0 and then Profile_Convention_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Convention_Mismatch_Count :=
                             Info.Convention_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0 and then Profile_Default_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Default_Mismatch_Count :=
                             Info.Default_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0 and then Profile_Class_Wide_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Class_Wide_Mismatch_Count :=
                             Info.Class_Wide_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0
                          and then Info.Result_Mismatch_Count = 0
                          and then Profile_Name_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Name_Mismatch_Count :=
                             Info.Name_Mismatch_Count + 1;
                        end if;
                     end if;
                  end if;
               end;
            end loop;

            if Direct_Matches /= 0 then
               if Info.Candidate_Count = 0 then
                  Info.Status := Subprogram_Profile_No_Candidates;
               elsif Info.Compatible_Count = 0 and then Info.Mode_Mismatch_Count /= 0 then
                  Info.Status := Subprogram_Profile_Mode_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Null_Exclusion_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Null_Exclusion_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Access_Profile_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Access_Profile_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Convention_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Convention_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Default_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Default_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Class_Wide_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Class_Wide_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Name_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Name_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Result_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Result_Mismatch;
               elsif Info.Compatible_Count = 0 then
                  Info.Status := Subprogram_Profile_No_Profile_Match;
               elsif Info.Compatible_Count = 1
                 and then Info.Name_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Name_Mismatch;
                  Info.Selected := Editor.Ada_Direct_Visibility.No_Declaration;
               elsif Info.Compatible_Count = 1 then
                  Info.Status := Subprogram_Profile_Selected;
               else
                  Info.Status := Subprogram_Profile_Ambiguous_Profile_Match;
                  Info.Selected := Editor.Ada_Direct_Visibility.No_Declaration;
               end if;
               return Info;
            end if;

            Current := Editor.Ada_Declarative_Regions.Region (Regions, Current).Parent;
         end;
      end loop;

      Info.Status := Subprogram_Profile_No_Candidates;
      return Info;
   end Select_Subprogram_Actual_By_Profile;


   type Formal_Package_Contract_Status is
     (Formal_Package_Contract_Compatible,
      Formal_Package_Contract_Actual_Unresolved,
      Formal_Package_Contract_Actual_Ambiguous,
      Formal_Package_Contract_Actual_Not_Instance,
      Formal_Package_Contract_Wrong_Generic,
      Formal_Package_Contract_Unknown,
      Formal_Package_Contract_Malformed);

   function Check_Formal_Package_Contract
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility  : Editor.Ada_Direct_Visibility.Visibility_Model;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      From_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Formal      : Generic_Formal_Info;
      Actual_Text : String) return Formal_Package_Contract_Status
   is
      Expected : constant String :=
        To_String (Formal.Formal_Package_Normalized_Generic);
      Actual   : constant String := Trim (Actual_Text);
      Inline_Generic : constant String := Normalize (Inline_Instance_Generic_Name (Actual));
      Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
      Actual_Decl : Editor.Ada_Direct_Visibility.Declaration_Info;
      Actual_Label : Unbounded_String;
      Actual_Generic : Unbounded_String;
   begin
      if Formal.Kind /= Generic_Formal_Package then
         return Formal_Package_Contract_Unknown;
      elsif Expected = "" then
         return Formal_Package_Contract_Unknown;
      elsif Actual = "" then
         return Formal_Package_Contract_Malformed;
      end if;

      if Inline_Generic /= "" then
         return (if Inline_Generic = Expected then Formal_Package_Contract_Compatible
                 else Formal_Package_Contract_Wrong_Generic);
      end if;

      Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
        (Visibility, Regions, From_Region, Normalize (Actual));
      if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
         return Formal_Package_Contract_Actual_Unresolved;
      elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
         return Formal_Package_Contract_Actual_Ambiguous;
      end if;

      Actual_Decl := Editor.Ada_Direct_Visibility.Declaration
        (Visibility, Lookup.Declaration);
      if Actual_Decl.Kind /= Editor.Ada_Direct_Visibility.Declaration_Instantiation then
         return Formal_Package_Contract_Actual_Not_Instance;
      end if;

      Actual_Label := Editor.Ada_Syntax_Tree.Node (Tree, Actual_Decl.Node).Label;
      Actual_Generic := To_Unbounded_String
        (Normalize (Generic_Name_From_Label (To_String (Actual_Label))));
      if To_String (Actual_Generic) = "" then
         return Formal_Package_Contract_Unknown;
      elsif To_String (Actual_Generic) = Expected then
         return Formal_Package_Contract_Compatible;
      else
         return Formal_Package_Contract_Wrong_Generic;
      end if;
   end Check_Formal_Package_Contract;

   procedure Add_Instance
     (Model : in out Generic_Contract_Model;
      Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
      Decl  : Editor.Ada_Direct_Visibility.Declaration_Info)
   is
      Id      : constant Generic_Instance_Id :=
        Generic_Instance_Id (Natural (Model.Instances.Length) + 1);
      Node    : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
      Label   : constant String := Trim (To_String (Node.Label));
      Positional : Natural := 0;
      Named      : Natural := 0;
      Named_Names : Unbounded_String;
      Positional_Kinds : Unbounded_String;
      Named_Kinds : Unbounded_String;
      Positional_Texts : Unbounded_String;
      Named_Texts : Unbounded_String;
      Malformed  : Boolean := False;
      Name       : constant String := Trim (To_String (Decl.Name));
      Gen        : constant String := Generic_Name_From_Label (Label);
      Info       : Generic_Instance_Info := Empty_Instance;
   begin
      Count_Actuals
        (Label, Positional, Named, Named_Names, Positional_Kinds, Named_Kinds,
         Positional_Texts, Named_Texts, Malformed);
      Info.Id := Id;
      Info.Declaration := Decl.Id;
      Info.Node := Decl.Node;
      Info.Region := Decl.Region;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize (Name));
      Info.Generic_Name := To_Unbounded_String (Gen);
      Info.Normalized_Generic := To_Unbounded_String (Normalize (Gen));
      Info.Positional_Actuals := Positional;
      Info.Named_Actuals := Named;
      Info.Total_Actuals := Positional + Named;
      Info.Named_Actual_Names := Named_Names;
      Info.Positional_Actual_Kinds := Positional_Kinds;
      Info.Named_Actual_Kinds := Named_Kinds;
      Info.Positional_Actual_Texts := Positional_Texts;
      Info.Named_Actual_Texts := Named_Texts;
      Info.Status :=
        (if Name = "" or else Gen = "" then Generic_Instance_Missing_Name
         elsif Malformed then Generic_Instance_Malformed_Actuals
         else Generic_Instance_Record_Valid);
      Info.Start_Line := Decl.Start_Line;
      Info.End_Line := Decl.End_Line;
      Info.Fingerprint :=
        (Natural (Id) * 1000003
         + Natural (Decl.Id) * 1009
         + Natural (Decl.Region) * 97
         + Positional * 43
         + Named * 37
         + Hash_Text (Name)
         + Hash_Text (Gen)
         + Hash_Text (To_String (Named_Names))
         + Hash_Text (To_String (Positional_Kinds))
         + Hash_Text (To_String (Named_Kinds))
         + Hash_Text (To_String (Positional_Texts))
         + Hash_Text (To_String (Named_Texts))) mod Natural'Last;
      Model.Instances.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Instance;


   procedure Add_Actual_Match
     (Model      : in out Generic_Contract_Model;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Instance   : Generic_Instance_Info;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Check_Default_Expressions : Boolean;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Check_Type_Graph : Boolean)
   is
      Id       : constant Generic_Actual_Match_Id :=
        Generic_Actual_Match_Id (Natural (Model.Actual_Matches.Length) + 1);
      Lookup   : Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Visible
          (Visibility, Regions, Instance.Region, To_String (Instance.Normalized_Generic));
      Info     : Generic_Actual_Match_Info := Empty_Actual_Match;
      Gen_Decl : Editor.Ada_Direct_Visibility.Declaration_Info;
      Formal_Region : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Formal_Names : Unbounded_String := Null_Unbounded_String;

      function Generic_Declaration_For_Package
        (Package_Name : String) return Editor.Ada_Direct_Visibility.Declaration_Id
      is
         Wanted : constant String := Normalize (Package_Name);
         Package_Region : Editor.Ada_Declarative_Regions.Region_Id :=
           Editor.Ada_Declarative_Regions.No_Region;
         Found : Editor.Ada_Direct_Visibility.Declaration_Id :=
           Editor.Ada_Direct_Visibility.No_Declaration;
      begin
         for I in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
            declare
               D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                 Editor.Ada_Direct_Visibility.Declaration_At (Visibility, I);
            begin
               if D.Kind = Editor.Ada_Direct_Visibility.Declaration_Package
                 and then To_String (D.Normalized) = Wanted
               then
                  if Package_Region /= Editor.Ada_Declarative_Regions.No_Region then
                     return Editor.Ada_Direct_Visibility.No_Declaration;
                  end if;
                  Package_Region := D.Region;
               end if;
            end;
         end loop;

         if Package_Region = Editor.Ada_Declarative_Regions.No_Region then
            return Editor.Ada_Direct_Visibility.No_Declaration;
         end if;

         for I in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
            declare
               D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                 Editor.Ada_Direct_Visibility.Declaration_At (Visibility, I);
            begin
               if D.Kind = Editor.Ada_Direct_Visibility.Declaration_Generic
                 and then Editor.Ada_Declarative_Regions.Region_For_Node (Regions, D.Node) = Package_Region
               then
                  if Found /= Editor.Ada_Direct_Visibility.No_Declaration then
                     return Editor.Ada_Direct_Visibility.No_Declaration;
                  end if;
                  Found := D.Id;
               end if;
            end;
         end loop;
         if Found = Editor.Ada_Direct_Visibility.No_Declaration then
            for I in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
               declare
                  D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                    Editor.Ada_Direct_Visibility.Declaration_At (Visibility, I);
               begin
                  if D.Kind = Editor.Ada_Direct_Visibility.Declaration_Generic then
                     if Found /= Editor.Ada_Direct_Visibility.No_Declaration then
                        return Editor.Ada_Direct_Visibility.No_Declaration;
                     end if;
                     Found := D.Id;
                  end if;
               end;
            end loop;
         end if;
         return Found;
      end Generic_Declaration_For_Package;
   begin
      Info.Id := Id;
      Info.Instance := Instance.Id;
      Info.Instance_Node := Instance.Node;
      Info.Instance_Region := Instance.Region;
      Info.Positional_Actuals := Instance.Positional_Actuals;
      Info.Named_Actuals := Instance.Named_Actuals;
      Info.Start_Line := Instance.Start_Line;
      Info.End_Line := Instance.End_Line;

      if Instance.Status /= Generic_Instance_Record_Valid then
         Info.Status := Generic_Actual_Match_Instance_Malformed;
      elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
         declare
            Fallback : constant Editor.Ada_Direct_Visibility.Declaration_Id :=
              Generic_Declaration_For_Package (To_String (Instance.Normalized_Generic));
         begin
            if Fallback = Editor.Ada_Direct_Visibility.No_Declaration then
               Info.Status := Generic_Actual_Match_Generic_Not_Found;
            else
               Lookup :=
                 (Status => Editor.Ada_Direct_Visibility.Lookup_Found,
                  Declaration => Fallback,
                  Region => Instance.Region,
                  Match_Count => 1);
               Info.Status := Generic_Actual_Match_Valid;
            end if;
         end;
      end if;

      if Info.Status = Generic_Actual_Match_Instance_Malformed
        or else Info.Status = Generic_Actual_Match_Generic_Not_Found
      then
         null;
      elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
         Info.Status := Generic_Actual_Match_Generic_Ambiguous;
      else
         Gen_Decl := Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
         Info.Generic_Declaration := Gen_Decl.Id;

         if Gen_Decl.Kind /= Editor.Ada_Direct_Visibility.Declaration_Generic then
            Info.Status := Generic_Actual_Match_Target_Not_Generic;
         else
            Formal_Region := Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Gen_Decl.Node);
            Info.Generic_Formal_Region := Formal_Region;

            if Formal_Region = Editor.Ada_Declarative_Regions.No_Region then
               Info.Status := Generic_Actual_Match_No_Formal_Region;
            else
               for Formal_Info of Model.Formals loop
                  if Formal_Info.Region = Formal_Region then
                     Info.Formal_Count := Info.Formal_Count + 1;
                     Formal_Names := Append_Normalized_Name
                       (Formal_Names, To_String (Formal_Info.Normalized_Name));
                     if Formal_Info.Has_Default then
                        Info.Defaulted_Formals := Info.Defaulted_Formals + 1;
                     else
                        Info.Required_Formals := Info.Required_Formals + 1;
                     end if;
                  end if;
               end loop;

               Info.Unknown_Named_Actuals := Count_Unknown_Named_Actuals
                 (To_String (Instance.Named_Actual_Names), To_String (Formal_Names));
               Info.Duplicate_Named_Actuals := Count_Duplicate_Named_Actuals
                 (To_String (Instance.Named_Actual_Names));

               if Instance.Positional_Actuals > Info.Formal_Count then
                  Info.Status := Generic_Actual_Match_Too_Many_Positionals;
               elsif Info.Unknown_Named_Actuals /= 0 then
                  Info.Status := Generic_Actual_Match_Unknown_Named_Actual;
               elsif Info.Duplicate_Named_Actuals /= 0 then
                  Info.Status := Generic_Actual_Match_Duplicate_Named_Actual;
               else
                  declare
                     Position : Natural := 0;
                  begin
                     for Formal_Info of Model.Formals loop
                        if Formal_Info.Region = Formal_Region then
                           Position := Position + 1;
                           declare
                              Actual_Kind : Generic_Actual_Kind := Generic_Actual_Unknown;
                              Has_Actual  : Boolean := False;
                              Kind_Result : Generic_Formal_Actual_Kind_Match;
                              Actual_Text : Unbounded_String := Null_Unbounded_String;
                              Profile_Result : Generic_Formal_Actual_Kind_Match;
                              Package_Result : Formal_Package_Contract_Status;
                           begin
                              if Position <= Instance.Positional_Actuals then
                                 Has_Actual := True;
                                 Actual_Kind := Positional_Kind_At
                                   (To_String (Instance.Positional_Actual_Kinds), Positive (Position));
                                 Actual_Text := To_Unbounded_String
                                   (Delimited_Text_At
                                      (To_String (Instance.Positional_Actual_Texts),
                                       Positive (Position)));
                              elsif List_Contains_Name
                                (To_String (Instance.Named_Actual_Names),
                                 To_String (Formal_Info.Normalized_Name))
                              then
                                 Has_Actual := True;
                                 Actual_Kind := Named_Kind_For
                                   (To_String (Instance.Named_Actual_Kinds),
                                    To_String (Formal_Info.Normalized_Name));
                                 Actual_Text := To_Unbounded_String
                                   (Named_Text_For
                                      (To_String (Instance.Named_Actual_Texts),
                                       To_String (Formal_Info.Normalized_Name)));
                              end if;

                              if Has_Actual then
                                 Actual_Kind := Resolve_Actual_Kind
                                   (Visibility, Regions, Instance.Region,
                                    To_String (Actual_Text), Actual_Kind);
                                 Info.Matched_Formals := Info.Matched_Formals + 1;
                                 Kind_Result := Kind_Compatible (Formal_Info.Kind, Actual_Kind);
                                 case Kind_Result is
                                    when Generic_Formal_Actual_Kind_Matches =>
                                       Info.Kind_Compatible_Formals :=
                                         Info.Kind_Compatible_Formals + 1;
                                    when Generic_Formal_Actual_Kind_Mismatch =>
                                       if Formal_Info.Kind = Generic_Formal_Subprogram
                                         and then Actual_Kind = Generic_Actual_Subprogram
                                       then
                                          null;
                                       else
                                          Info.Kind_Mismatched_Formals :=
                                            Info.Kind_Mismatched_Formals + 1;
                                       end if;
                                    when Generic_Formal_Actual_Kind_Unknown =>
                                       Info.Kind_Unknown_Formals :=
                                         Info.Kind_Unknown_Formals + 1;
                                    when Generic_Formal_Actual_Kind_Missing =>
                                       null;
                                 end case;

                                 if Check_Default_Expressions
                                   and then Formal_Info.Kind = Generic_Formal_Object
                                   and then Kind_Result /= Generic_Formal_Actual_Kind_Mismatch
                                 then
                                    Default_Expression_Checks.Classify_Object_Expression
                                      (Info, Static, Instance.Region,
                                       To_String (Actual_Text));
                                 end if;

                                 if Formal_Info.Kind = Generic_Formal_Subprogram
                                 then
                                    declare
                                       Selection : constant Subprogram_Profile_Selection_Info :=
                                         Select_Subprogram_Actual_By_Profile
                                           (Model, Instance, Tree, Visibility, Regions,
                                            Types, Check_Type_Graph,
                                            Instance.Region, Formal_Info,
                                            To_String (Actual_Text));
                                    begin
                                       Info.Subprogram_Profile_Overload_Candidates :=
                                         Info.Subprogram_Profile_Overload_Candidates
                                         + Selection.Candidate_Count;
                                       Info.Subprogram_Profile_Type_Compatible_Formals :=
                                         Info.Subprogram_Profile_Type_Compatible_Formals
                                         + Selection.Type_Compatible_Count;
                                       Info.Subprogram_Profile_Type_Mismatched_Formals :=
                                         Info.Subprogram_Profile_Type_Mismatched_Formals
                                         + Selection.Type_Mismatch_Count;
                                       Info.Subprogram_Profile_Type_Unknown_Formals :=
                                         Info.Subprogram_Profile_Type_Unknown_Formals
                                         + Selection.Type_Unknown_Count;
                                       Info.Subprogram_Profile_Result_Compatible_Formals :=
                                         Info.Subprogram_Profile_Result_Compatible_Formals
                                         + Selection.Result_Compatible_Count;
                                       Info.Subprogram_Profile_Result_Mismatched_Formals :=
                                         Info.Subprogram_Profile_Result_Mismatched_Formals
                                         + Selection.Result_Mismatch_Count;
                                       Info.Subprogram_Profile_Result_Unknown_Formals :=
                                         Info.Subprogram_Profile_Result_Unknown_Formals
                                         + Selection.Result_Unknown_Count;
                                       case Selection.Status is
                                          when Subprogram_Profile_Selected =>
                                             Info.Subprogram_Profile_Compatible_Formals :=
                                               Info.Subprogram_Profile_Compatible_Formals + 1;
                                             Info.Subprogram_Profile_Overload_Selected_Formals :=
                                               Info.Subprogram_Profile_Overload_Selected_Formals + 1;
                                          when Subprogram_Profile_No_Profile_Match =>
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Mode_Mismatch =>
                                             Info.Subprogram_Profile_Mode_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mode_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Null_Exclusion_Mismatch =>
                                             Info.Subprogram_Profile_Null_Exclusion_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Null_Exclusion_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Access_Profile_Mismatch =>
                                             Info.Subprogram_Profile_Access_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Access_Profile_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Convention_Mismatch =>
                                             Info.Subprogram_Profile_Convention_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Convention_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Default_Mismatch =>
                                             Info.Subprogram_Profile_Default_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Default_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Class_Wide_Mismatch =>
                                             Info.Subprogram_Profile_Class_Wide_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Class_Wide_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Name_Mismatch =>
                                             Info.Subprogram_Profile_Name_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Name_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Result_Mismatch =>
                                             Info.Subprogram_Profile_Result_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Result_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Ambiguous_Profile_Match =>
                                             Info.Subprogram_Profile_Overload_Ambiguous_Formals :=
                                               Info.Subprogram_Profile_Overload_Ambiguous_Formals + 1;
                                          when Subprogram_Profile_No_Candidates =>
                                             Info.Subprogram_Profile_Overload_Unresolved_Formals :=
                                               Info.Subprogram_Profile_Overload_Unresolved_Formals + 1;
                                             Info.Subprogram_Profile_Unknown_Formals :=
                                               Info.Subprogram_Profile_Unknown_Formals + 1;
                                          when Subprogram_Profile_Unknown =>
                                             Info.Subprogram_Profile_Unknown_Formals :=
                                               Info.Subprogram_Profile_Unknown_Formals + 1;
                                       end case;
                                    end;
                                 end if;

                                 if Formal_Info.Kind = Generic_Formal_Package
                                   and then Kind_Result /= Generic_Formal_Actual_Kind_Mismatch
                                 then
                                    Package_Result := Check_Formal_Package_Contract
                                      (Tree, Visibility, Regions, Instance.Region,
                                       Formal_Info, To_String (Actual_Text));
                                    case Package_Result is
                                       when Formal_Package_Contract_Compatible =>
                                          Info.Formal_Package_Compatible_Formals :=
                                            Info.Formal_Package_Compatible_Formals + 1;
                                       when Formal_Package_Contract_Actual_Not_Instance =>
                                          Info.Formal_Package_Mismatched_Formals :=
                                            Info.Formal_Package_Mismatched_Formals + 1;
                                          Info.Formal_Package_Not_Instance_Formals :=
                                            Info.Formal_Package_Not_Instance_Formals + 1;
                                       when Formal_Package_Contract_Wrong_Generic =>
                                          Info.Formal_Package_Mismatched_Formals :=
                                            Info.Formal_Package_Mismatched_Formals + 1;
                                          Info.Formal_Package_Wrong_Generic_Formals :=
                                            Info.Formal_Package_Wrong_Generic_Formals + 1;
                                       when Formal_Package_Contract_Actual_Unresolved =>
                                          Info.Formal_Package_Unknown_Formals :=
                                            Info.Formal_Package_Unknown_Formals + 1;
                                          Info.Formal_Package_Unresolved_Formals :=
                                            Info.Formal_Package_Unresolved_Formals + 1;
                                       when Formal_Package_Contract_Actual_Ambiguous =>
                                          Info.Formal_Package_Unknown_Formals :=
                                            Info.Formal_Package_Unknown_Formals + 1;
                                          Info.Formal_Package_Ambiguous_Formals :=
                                            Info.Formal_Package_Ambiguous_Formals + 1;
                                       when Formal_Package_Contract_Unknown =>
                                          Info.Formal_Package_Unknown_Formals :=
                                            Info.Formal_Package_Unknown_Formals + 1;
                                          Info.Formal_Package_Contract_Unknown_Formals :=
                                            Info.Formal_Package_Contract_Unknown_Formals + 1;
                                       when Formal_Package_Contract_Malformed =>
                                          Info.Formal_Package_Mismatched_Formals :=
                                            Info.Formal_Package_Mismatched_Formals + 1;
                                          Info.Formal_Package_Malformed_Formals :=
                                            Info.Formal_Package_Malformed_Formals + 1;
                                    end case;
                                 end if;
                              elsif not Formal_Info.Has_Default then
                                 Info.Missing_Required_Formals :=
                                   Info.Missing_Required_Formals + 1;
                              elsif Check_Default_Expressions
                                and then Formal_Info.Kind = Generic_Formal_Object
                              then
                                 Default_Expression_Checks.Classify_Object_Expression
                                   (Info, Static, Formal_Info.Region,
                                    To_String (Formal_Info.Default_Text));
                              end if;
                           end;
                        end if;
                     end loop;
                  end;

                  if Info.Missing_Required_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Missing_Required_Formal;
                  elsif Info.Kind_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Kind_Mismatch;
                  elsif Info.Subprogram_Profile_Overload_Ambiguous_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Profile_Ambiguous;
                  elsif Info.Subprogram_Profile_Mode_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Mode_Mismatch;
                  elsif Info.Subprogram_Profile_Null_Exclusion_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Null_Exclusion_Mismatch;
                  elsif Info.Subprogram_Profile_Access_Profile_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Access_Profile_Mismatch;
                  elsif Info.Subprogram_Profile_Convention_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Convention_Mismatch;
                  elsif Info.Subprogram_Profile_Default_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Default_Mismatch;
                  elsif Info.Subprogram_Profile_Class_Wide_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Class_Wide_Mismatch;
                  elsif Info.Subprogram_Profile_Name_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Name_Mismatch;
                  elsif Check_Type_Graph
                    and then Info.Subprogram_Profile_Result_Mismatched_Formals /= 0
                  then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Result_Mismatch;
                  elsif Info.Subprogram_Profile_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Profile_Mismatch;
                  elsif Info.Formal_Package_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Package_Contract_Mismatch;
                  elsif Info.Formal_Package_Unknown_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Package_Contract_Unknown;
                  elsif Info.Default_Expression_Illegal_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Object_Default_Illegal;
                  elsif Info.Default_Expression_Unknown_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Object_Default_Unknown;
                  else
                     Info.Status := Generic_Actual_Match_Valid;
                  end if;
               end if;
            end if;
         end if;
      end if;

      Info.Fingerprint :=
        (Natural (Id) * 1000003
         + Natural (Info.Instance) * 1009
         + Natural (Info.Generic_Declaration) * 503
         + Natural (Info.Generic_Formal_Region) * 97
         + Generic_Actual_Match_Status'Pos (Info.Status) * 43
         + Info.Formal_Count * 37
         + Info.Required_Formals * 31
         + Info.Matched_Formals * 29
         + Info.Unknown_Named_Actuals * 23
         + Info.Duplicate_Named_Actuals * 19
         + Info.Missing_Required_Formals * 17
         + Info.Kind_Compatible_Formals * 13
         + Info.Kind_Mismatched_Formals * 11
         + Info.Kind_Unknown_Formals * 7
         + Info.Subprogram_Profile_Compatible_Formals * 5
         + Info.Subprogram_Profile_Mismatched_Formals * 3
         + Info.Subprogram_Profile_Unknown_Formals
         + Info.Subprogram_Profile_Null_Exclusion_Mismatched_Formals * 143
         + Info.Subprogram_Profile_Access_Profile_Mismatched_Formals * 147
         + Info.Subprogram_Profile_Convention_Mismatched_Formals * 148
         + Info.Subprogram_Profile_Default_Mismatched_Formals * 150
         + Info.Subprogram_Profile_Class_Wide_Mismatched_Formals * 152
         + Info.Subprogram_Profile_Name_Mismatched_Formals * 154
         + Info.Subprogram_Profile_Result_Compatible_Formals * 158
         + Info.Subprogram_Profile_Result_Mismatched_Formals * 160
         + Info.Subprogram_Profile_Result_Unknown_Formals * 162
         + Info.Subprogram_Profile_Type_Compatible_Formals * 149
         + Info.Subprogram_Profile_Type_Mismatched_Formals * 151
         + Info.Subprogram_Profile_Type_Unknown_Formals * 157
         + Info.Subprogram_Profile_Overload_Candidates * 41
         + Info.Subprogram_Profile_Overload_Selected_Formals * 47
         + Info.Subprogram_Profile_Overload_Ambiguous_Formals * 53
         + Info.Subprogram_Profile_Overload_Unresolved_Formals * 59
         + Info.Formal_Package_Compatible_Formals * 61
         + Info.Formal_Package_Mismatched_Formals * 67
         + Info.Formal_Package_Unknown_Formals * 71
         + Info.Formal_Package_Unresolved_Formals * 73
         + Info.Formal_Package_Ambiguous_Formals * 79
         + Info.Formal_Package_Not_Instance_Formals * 83
         + Info.Formal_Package_Wrong_Generic_Formals * 89
         + Info.Formal_Package_Contract_Unknown_Formals * 97
         + Info.Formal_Package_Malformed_Formals * 101
         + Info.Default_Expression_Checked_Formals * 103
         + Info.Default_Expression_Static_Formals * 107
         + Info.Default_Expression_Illegal_Formals * 109
         + Info.Default_Expression_Unknown_Formals * 113
         + Info.Default_Expression_Unresolved_Formals * 127
         + Info.Default_Expression_Nonstatic_Formals * 131
         + Info.Default_Expression_Malformed_Formals * 137
         + Info.Default_Expression_Division_By_Zero_Formals * 139) mod Natural'Last;
      Model.Actual_Matches.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Actual_Match;


end Instance_Matching;
