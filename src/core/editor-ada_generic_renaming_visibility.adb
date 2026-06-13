with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Renaming_Visibility is

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trim (Text));
   end Normalize;

   function Contains (Text, Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Pattern) /= 0;
   end Contains;

   function Strip_Trailing_Semicolon (Text : String) return String is
      T : constant String := Trim (Text);
   begin
      if T /= "" and then T (T'Last) = ';' then
         return Trim (T (T'First .. T'Last - 1));
      else
         return T;
      end if;
   end Strip_Trailing_Semicolon;

   function Name_Before_Renames (Text : String) return String is
      T     : constant String := Trim (Text);
      Lower : constant String := Normalize (T);
      Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower, " renames ");
      First : Natural := T'First;
      Last  : Natural;
   begin
      if Pos = 0 then
         return "";
      end if;

      Last := Pos - 1;
      if Ada.Strings.Fixed.Index (Lower, "package ") = Lower'First then
         First := T'First + 8;
      elsif Ada.Strings.Fixed.Index (Lower, "procedure ") = Lower'First then
         First := T'First + 10;
      elsif Ada.Strings.Fixed.Index (Lower, "function ") = Lower'First then
         First := T'First + 9;
      end if;

      if Last < First then
         return "";
      end if;

      declare
         Segment : constant String := Trim (T (First .. Last));
         Paren   : constant Natural := Ada.Strings.Fixed.Index (Segment, "(");
         Space   : constant Natural := Ada.Strings.Fixed.Index (Segment, " ");
      begin
         if Paren /= 0 then
            return Trim (Segment (Segment'First .. Paren - 1));
         elsif Space /= 0 then
            return Trim (Segment (Segment'First .. Space - 1));
         else
            return Segment;
         end if;
      end;
   end Name_Before_Renames;

   function Target_After_Renames (Text : String) return String is
      T     : constant String := Trim (Text);
      Lower : constant String := Normalize (T);
      Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower, " renames ");
   begin
      if Pos = 0 then
         return "";
      else
         return Strip_Trailing_Semicolon (T (Pos + 9 .. T'Last));
      end if;
   end Target_After_Renames;

   function Name_Before_New (Text : String) return String is
      T     : constant String := Trim (Text);
      Lower : constant String := Normalize (T);
      Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower, " is new ");
      First : Natural := T'First;
      Last  : Natural;
   begin
      if Pos = 0 then
         return "";
      end if;

      Last := Pos - 1;
      if Ada.Strings.Fixed.Index (Lower, "package ") = Lower'First then
         First := T'First + 8;
      elsif Ada.Strings.Fixed.Index (Lower, "procedure ") = Lower'First then
         First := T'First + 10;
      elsif Ada.Strings.Fixed.Index (Lower, "function ") = Lower'First then
         First := T'First + 9;
      end if;

      return Trim (T (First .. Last));
   end Name_Before_New;

   function Generic_After_New (Text : String) return String is
      T     : constant String := Trim (Text);
      Lower : constant String := Normalize (T);
      Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower, " is new ");
      First : Natural;
      Last  : Natural;
   begin
      if Pos = 0 then
         return "";
      end if;

      First := Pos + 8;
      Last := T'Last;
      for I in First .. T'Last loop
         if T (I) = '(' or else T (I) = ';' then
            Last := I - 1;
            exit;
         end if;
      end loop;

      if Last < First then
         return "";
      end if;

      return Trim (T (First .. Last));
   end Generic_After_New;

   function Formal_Region_For_Declaration
     (Contracts   : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Declaration : Editor.Ada_Direct_Visibility.Declaration_Id)
      return Editor.Ada_Declarative_Regions.Region_Id
   is
      use type Editor.Ada_Direct_Visibility.Declaration_Id;
   begin
      if Declaration = Editor.Ada_Direct_Visibility.No_Declaration then
         return Editor.Ada_Declarative_Regions.No_Region;
      end if;

      for Match_Index in 1 .. Editor.Ada_Generic_Contracts.Actual_Match_Count (Contracts) loop
         declare
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_At (Contracts, Match_Index);
         begin
            if Match.Generic_Declaration = Declaration then
               return Match.Generic_Formal_Region;
            end if;
         end;
      end loop;

      for Formal_Index in 1 .. Editor.Ada_Generic_Contracts.Formal_Count (Contracts) loop
         declare
            Formal : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
              Editor.Ada_Generic_Contracts.Formal_At (Contracts, Formal_Index);
         begin
            if Formal.Declaration = Declaration then
               return Formal.Region;
            end if;
         end;
      end loop;

      return Editor.Ada_Declarative_Regions.No_Region;
   end Formal_Region_For_Declaration;

   function Formal_Count_In_Region
     (Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Region    : Editor.Ada_Declarative_Regions.Region_Id) return Natural is
      use type Editor.Ada_Declarative_Regions.Region_Id;
   begin
      if Region = Editor.Ada_Declarative_Regions.No_Region then
         return 0;
      else
         return Editor.Ada_Generic_Contracts.Formal_Count_In_Region
           (Contracts, Region);
      end if;
   end Formal_Count_In_Region;

   function Formal_Region_For_Generic_Name
     (Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Name      : String) return Editor.Ada_Declarative_Regions.Region_Id
   is
      N : constant String := Normalize (Name);
      use type Editor.Ada_Generic_Contracts.Generic_Instance_Id;
      use type Editor.Ada_Declarative_Regions.Region_Id;
   begin
      for Match_Index in 1 .. Editor.Ada_Generic_Contracts.Actual_Match_Count (Contracts) loop
         declare
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_At (Contracts, Match_Index);
         begin
            if Match.Instance /= Editor.Ada_Generic_Contracts.No_Generic_Instance
              and then Match.Generic_Formal_Region /= Editor.Ada_Declarative_Regions.No_Region
            then
               declare
                  Inst : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
                    Editor.Ada_Generic_Contracts.Instance (Contracts, Match.Instance);
               begin
                  if To_String (Inst.Normalized_Generic) = N then
                     return Match.Generic_Formal_Region;
                  end if;
               end;
            end if;
         end;
      end loop;

      return Editor.Ada_Declarative_Regions.No_Region;
   end Formal_Region_For_Generic_Name;

   function Is_Nested_Region
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Region  : Editor.Ada_Declarative_Regions.Region_Id) return Boolean
   is
      Info : Editor.Ada_Declarative_Regions.Region_Info;
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
   begin
      if Region = Editor.Ada_Declarative_Regions.No_Region then
         return False;
      end if;
      Info := Editor.Ada_Declarative_Regions.Region (Regions, Region);
      return Info.Depth > 0
        or else Info.Kind = Editor.Ada_Declarative_Regions.Region_Generic_Formal_Part
        or else Info.Kind = Editor.Ada_Declarative_Regions.Region_Subprogram_Body
        or else Info.Kind = Editor.Ada_Declarative_Regions.Region_Package_Body
        or else Info.Kind = Editor.Ada_Declarative_Regions.Region_Block;
   end Is_Nested_Region;

   function Renaming_By_Name
     (Model  : Generic_Renaming_Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Generic_Renaming_Info
   is
      N : constant String := Normalize (Name);
      use type Editor.Ada_Declarative_Regions.Region_Id;
   begin
      for Index in 1 .. Natural (Model.Renamings.Length) loop
         declare
            Candidate : constant Generic_Renaming_Info := Model.Renamings (Index);
         begin
            if To_String (Candidate.Normalized_Name) = N
              and then (Candidate.Region = Region
                        or else Candidate.Status = Generic_Renaming_Target_Resolved)
            then
               return Candidate;
            end if;
         end;
      end loop;
      return (others => <>);
   end Renaming_By_Name;

   procedure Add_Renaming
     (Model : in out Generic_Renaming_Visibility_Model;
      Info  : in out Generic_Renaming_Info) is
   begin
      Info.Fingerprint :=
        Mix (Natural (Info.Id),
             Mix (Natural (Info.Node),
                  Mix (Natural (Info.Declaration),
                       Mix (Natural (Info.Target_Declaration),
                            Mix (Natural (Info.Target_Region),
                                 Mix (Info.Target_Formal_Count,
                                      Mix (Info.Candidate_Count,
                                           Generic_Renaming_Status'Pos (Info.Status))))))));

      case Info.Status is
         when Generic_Renaming_Target_Resolved =>
            Model.Renaming_Resolved_Total := Model.Renaming_Resolved_Total + 1;
         when Generic_Renaming_Target_Unresolved |
              Generic_Renaming_Target_Ambiguous |
              Generic_Renaming_Target_Not_Generic |
              Generic_Renaming_Malformed =>
            Model.Renaming_Error_Total := Model.Renaming_Error_Total + 1;
         when Generic_Renaming_Unknown =>
            null;
      end case;

      Model.Renamings.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
   end Add_Renaming;

   procedure Add_Nested
     (Model : in out Generic_Renaming_Visibility_Model;
      Info  : in out Nested_Generic_Instantiation_Info) is
   begin
      Info.Fingerprint :=
        Mix (Natural (Info.Instance),
             Mix (Natural (Info.Instance_Node),
                  Mix (Natural (Info.Renaming),
                       Mix (Natural (Info.Resolved_Generic),
                            Mix (Natural (Info.Formal_Region),
                                 Mix (Info.Actual_Count,
                                      Mix (Info.Formal_Count,
                                           Mix (Info.Candidate_Count,
                                                Nested_Generic_Instantiation_Status'Pos (Info.Status)))))))));

      case Info.Status is
         when Nested_Generic_Instantiation_Renamed_Target =>
            Model.Nested_Renamed_Total := Model.Nested_Renamed_Total + 1;
         when Nested_Generic_Instantiation_Direct_Target =>
            Model.Nested_Direct_Total := Model.Nested_Direct_Total + 1;
         when Nested_Generic_Instantiation_Target_Unresolved |
              Nested_Generic_Instantiation_Target_Ambiguous |
              Nested_Generic_Instantiation_Target_Not_Generic |
              Nested_Generic_Instantiation_Malformed =>
            Model.Nested_Error_Total := Model.Nested_Error_Total + 1;
         when Nested_Generic_Instantiation_Unknown =>
            null;
      end case;

      Model.Nested_Instantiations.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
   end Add_Nested;

   procedure Clear (Model : in out Generic_Renaming_Visibility_Model) is
   begin
      Model.Renamings.Clear;
      Model.Nested_Instantiations.Clear;
      Model.Renaming_Resolved_Total := 0;
      Model.Renaming_Error_Total := 0;
      Model.Nested_Renamed_Total := 0;
      Model.Nested_Direct_Total := 0;
      Model.Nested_Error_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Contracts  : Editor.Ada_Generic_Contracts.Generic_Contract_Model)
      return Generic_Renaming_Visibility_Model
   is
      Result : Generic_Renaming_Visibility_Model;
      use type Editor.Ada_Syntax_Tree.Node_Kind;
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      use type Editor.Ada_Direct_Visibility.Declaration_Kind;
      use type Editor.Ada_Generic_Contracts.Generic_Instance_Status;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            N     : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Label : constant String := To_String (N.Label);
            Lower : constant String := Normalize (Label);
         begin
            if N.Kind = Editor.Ada_Syntax_Tree.Node_Rename_Declaration
              and then Contains (Lower, " renames ")
              and then (Contains (Lower, "package ")
                        or else Contains (Lower, "procedure ")
                        or else Contains (Lower, "function "))
            then
               declare
                  Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
                    Editor.Ada_Declarative_Regions.Region_For_Node (Regions, N.Id);
                  Name   : constant String := Name_Before_Renames (Label);
                  Target : constant String := Target_After_Renames (Label);
                  Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                    Editor.Ada_Direct_Visibility.Lookup_Visible
                      (Visibility, Regions, Region, Target);
                  Info   : Generic_Renaming_Info;
                  Decl   : Editor.Ada_Direct_Visibility.Declaration_Info;
               begin
                  Info.Id := Generic_Renaming_Id (Natural (Result.Renamings.Length) + 1);
                  Info.Node := N.Id;
                  Info.Region := Region;
                  Info.Name := To_Unbounded_String (Name);
                  Info.Normalized_Name := To_Unbounded_String (Normalize (Name));
                  Info.Target_Name := To_Unbounded_String (Target);
                  Info.Normalized_Target := To_Unbounded_String (Normalize (Target));
                  Info.Candidate_Count := Lookup.Match_Count;
                  Info.Start_Line := N.Source_Span.Start_Line;
                  Info.End_Line := N.Source_Span.End_Line;

                  declare
                     Local : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                       Editor.Ada_Direct_Visibility.Lookup_Direct
                         (Visibility, Region, Name);
                  begin
                     Info.Declaration := Local.Declaration;
                  end;

                  if Name = "" or else Target = "" then
                     Info.Status := Generic_Renaming_Malformed;
                  elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
                     Info.Status := Generic_Renaming_Target_Unresolved;
                  elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
                     Info.Status := Generic_Renaming_Target_Ambiguous;
                  else
                     Info.Target_Declaration := Lookup.Declaration;
                     Decl := Editor.Ada_Direct_Visibility.Declaration
                       (Visibility, Lookup.Declaration);
                     if Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Generic then
                        Info.Target_Region := Formal_Region_For_Declaration
                          (Contracts, Lookup.Declaration);
                        Info.Target_Formal_Count := Formal_Count_In_Region
                          (Contracts, Info.Target_Region);
                        Info.Status := Generic_Renaming_Target_Resolved;
                     else
                        Info.Target_Region := Formal_Region_For_Generic_Name
                          (Contracts, Target);
                        Info.Target_Formal_Count := Formal_Count_In_Region
                          (Contracts, Info.Target_Region);
                        if Info.Target_Formal_Count /= 0 then
                           Info.Status := Generic_Renaming_Target_Resolved;
                        else
                           Info.Status := Generic_Renaming_Target_Not_Generic;
                        end if;
                     end if;
                  end if;

                  Add_Renaming (Result, Info);
               end;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
            Region   : constant Editor.Ada_Declarative_Regions.Region_Id := Instance.Region;
            Target   : constant String := To_String (Instance.Normalized_Generic);
            Lookup   : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
              Editor.Ada_Direct_Visibility.Lookup_Visible
                (Visibility, Regions, Region, Target);
            Rename   : constant Generic_Renaming_Info :=
              Renaming_By_Name (Result, Region, Target);
            Info     : Nested_Generic_Instantiation_Info;
            Decl     : Editor.Ada_Direct_Visibility.Declaration_Info;
         begin
            Info.Instance := Instance.Id;
            Info.Instance_Node := Instance.Node;
            Info.Instance_Region := Instance.Region;
            Info.Instance_Name := Instance.Name;
            Info.Target_Name := Instance.Generic_Name;
            Info.Normalized_Target := Instance.Normalized_Generic;
            Info.Actual_Count := Instance.Total_Actuals;
            Info.Is_Nested := Is_Nested_Region (Regions, Region);
            Info.Candidate_Count := Lookup.Match_Count;
            Info.Start_Line := Instance.Start_Line;
            Info.End_Line := Instance.End_Line;

            if Instance.Status /= Editor.Ada_Generic_Contracts.Generic_Instance_Record_Valid
              or else Target = ""
            then
               Info.Status := Nested_Generic_Instantiation_Malformed;
            elsif Rename.Id /= No_Generic_Renaming
              and then Rename.Status = Generic_Renaming_Target_Resolved
            then
               Info.Renaming := Rename.Id;
               Info.Resolved_Generic := Rename.Target_Declaration;
               Info.Formal_Region := Rename.Target_Region;
               Info.Formal_Count := Rename.Target_Formal_Count;
               Info.Status := Nested_Generic_Instantiation_Renamed_Target;
            elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
               Info.Status := Nested_Generic_Instantiation_Target_Unresolved;
            elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
               Info.Status := Nested_Generic_Instantiation_Target_Ambiguous;
            else
               Decl := Editor.Ada_Direct_Visibility.Declaration
                 (Visibility, Lookup.Declaration);
               Info.Resolved_Generic := Lookup.Declaration;
               if Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Generic then
                  Info.Formal_Region := Formal_Region_For_Declaration
                    (Contracts, Lookup.Declaration);
                  Info.Formal_Count := Formal_Count_In_Region
                    (Contracts, Info.Formal_Region);
                  Info.Status := Nested_Generic_Instantiation_Direct_Target;
               else
                  Info.Formal_Region := Formal_Region_For_Generic_Name
                    (Contracts, Target);
                  Info.Formal_Count := Formal_Count_In_Region
                    (Contracts, Info.Formal_Region);
                  if Info.Formal_Count /= 0 then
                     Info.Status := Nested_Generic_Instantiation_Direct_Target;
                  else
                     Info.Status := Nested_Generic_Instantiation_Target_Not_Generic;
                  end if;
               end if;
            end if;

            Add_Nested (Result, Info);
         end;
      end loop;

      return Result;
   end Build;



   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Contracts  : Editor.Ada_Generic_Contracts.Generic_Contract_Model)
      return Generic_Renaming_Visibility_Model
   is
      Regions    : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
   begin
      return Build (Tree, Regions, Visibility, Contracts);
   end Build;

   function Renaming_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural is
   begin
      return Natural (Model.Renamings.Length);
   end Renaming_Count;

   function Renaming_At
     (Model : Generic_Renaming_Visibility_Model;
      Index : Positive) return Generic_Renaming_Info is
   begin
      return Model.Renamings (Index);
   end Renaming_At;

   function Renaming_For_Name
     (Model  : Generic_Renaming_Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Generic_Renaming_Info is
   begin
      return Renaming_By_Name (Model, Region, Name);
   end Renaming_For_Name;

   function Nested_Instantiation_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural is
   begin
      return Natural (Model.Nested_Instantiations.Length);
   end Nested_Instantiation_Count;

   function Nested_Instantiation_At
     (Model : Generic_Renaming_Visibility_Model;
      Index : Positive) return Nested_Generic_Instantiation_Info is
   begin
      return Model.Nested_Instantiations (Index);
   end Nested_Instantiation_At;

   function Renaming_Resolved_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural is
   begin
      return Model.Renaming_Resolved_Total;
   end Renaming_Resolved_Count;

   function Renaming_Error_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural is
   begin
      return Model.Renaming_Error_Total;
   end Renaming_Error_Count;

   function Nested_Renamed_Instance_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural is
   begin
      return Model.Nested_Renamed_Total;
   end Nested_Renamed_Instance_Count;

   function Nested_Direct_Instance_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural is
   begin
      return Model.Nested_Direct_Total;
   end Nested_Direct_Instance_Count;

   function Nested_Instance_Error_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural is
   begin
      return Model.Nested_Error_Total;
   end Nested_Instance_Error_Count;

   function Fingerprint
     (Model : Generic_Renaming_Visibility_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Renaming_Visibility;
