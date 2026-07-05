with Ada.Strings.Fixed;
with Editor.Commands;
with Editor.Command_Surface;
with Editor.Ada_Syntax_Core;
with Editor.External_Producers;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Audit;
with Editor.Outline;
with Editor.Outline_Extractor;
with Editor.State;

package body Editor.Outline_Audit is

   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Outline.Outline_Refresh_Status;
   use type Editor.Outline.Outline_Refresh_Failure_Kind;
   use type Editor.Outline.Outline_Target_Kind;
   use type Editor.Commands.Command_Id;


   function Stable_Name_Routes
     (Name     : String;
      Expected : Editor.Commands.Command_Id) return Boolean
   is
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      return Found and then Id = Expected;
   end Stable_Name_Routes;

   function Canonical_Stable_Name_Routes
     (Name     : String;
      Expected : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Stable_Name_Routes (Name, Expected)
        and then Editor.Commands.Stable_Command_Name (Expected) = Name
        and then Editor.Commands.Descriptor_Is_Complete (Expected)
        and then Editor.Commands.Has_Availability_Handler (Expected)
        and then Editor.Commands.Is_Bindable_Command (Expected);
   end Canonical_Stable_Name_Routes;

   function Command_Surface_Check return Boolean is
   begin
      return Canonical_Stable_Name_Routes
          ("outline.next-symbol", Editor.Commands.Command_Next_Outline_Symbol)
        and then Canonical_Stable_Name_Routes
          ("outline.previous-symbol", Editor.Commands.Command_Previous_Outline_Symbol)
        and then Canonical_Stable_Name_Routes
          ("outline.reveal-current-symbol",
           Editor.Commands.Command_Reveal_Current_Outline_Symbol)
        and then Canonical_Stable_Name_Routes
          ("outline.filter.focus", Editor.Commands.Command_Focus_Outline_Filter)
        and then Canonical_Stable_Name_Routes
          ("outline.filter.clear", Editor.Commands.Command_Clear_Outline_Filter)
        and then Stable_Name_Routes
          ("outline.filter.next-match",
           Editor.Commands.Command_Select_Next_Outline_Item)
        and then Stable_Name_Routes
          ("outline.filter.previous-match",
           Editor.Commands.Command_Select_Previous_Outline_Item);
   end Command_Surface_Check;

   function Outline_Helper_Purity_Check
     (Outline             : Editor.Outline.Outline_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Copy     : Editor.Outline.Outline_State := Outline;
      Panel    : Editor.Feature_Panel.Feature_Panel_State;
      Before   : constant Natural := Editor.Outline.Fingerprint (Copy);
      Selected : constant Natural := Editor.Outline.Selected_Index (Copy);
      Current  : constant Natural := Editor.Outline.Current_Symbol_Index (Copy);
      Next     : Natural := 0;
      Previous : Natural := 0;
      Nearest  : Natural := 0;
      Has_Match : Boolean := False;
      Can_Reveal : Boolean := False;
      Buffer_Matches : Boolean := False;
      Has_Navigable : Boolean := False;
      Symbol_Count  : Natural := 0;
      Filtered_Symbol_Count : Natural := 0;
   begin
      Next := Editor.Outline.Find_Next_Symbol_For_Position
        (Copy, Active_Buffer_Token, 1, 1, True);
      Previous := Editor.Outline.Find_Previous_Symbol_For_Position
        (Copy, Active_Buffer_Token, 1, 1, True);
      Nearest := Editor.Outline.Find_Current_Symbol_For_Cursor
        (Copy, Active_Buffer_Token, 1, 1);
      Has_Match := Editor.Outline.Has_Selectable_Filter_Match (Copy);
      Buffer_Matches := Editor.Outline.Outline_Buffer_Identity_Matches
        (Copy, Active_Buffer_Token);
      Has_Navigable := Editor.Outline.Has_Navigable_Symbol_For_Buffer
        (Copy, Active_Buffer_Token);
      Symbol_Count := Editor.Outline.Navigable_Symbol_Count (Copy);
      Filtered_Symbol_Count :=
        Editor.Outline.Filtered_Navigable_Symbol_Count (Copy);
      Editor.Outline.Set_Rows_From_Outline (Copy, Panel);
      Can_Reveal := Editor.Outline.Can_Reveal_Current_Symbol
        (Copy, Panel, Active_Buffer_Token);

      return Editor.Outline.Fingerprint (Copy) = Before
        and then Editor.Outline.Selected_Index (Copy) = Selected
        and then Editor.Outline.Current_Symbol_Index (Copy) = Current
        and then Editor.Outline.Invariant_Holds (Copy)
        and then (if Active_Buffer_Token = 0
                  then Next = 0 and then Previous = 0 and then Nearest = 0
                    and then not Buffer_Matches and then not Has_Navigable
                  else True)
        and then (if Editor.Outline.Source_Class (Copy) /= Editor.Outline.Extracted_Outline
                  then Next = 0 and then Previous = 0 and then Nearest = 0
                    and then not Has_Match and then not Can_Reveal
                    and then not Buffer_Matches and then not Has_Navigable
                    and then Symbol_Count = 0
                    and then Filtered_Symbol_Count = 0
                  else True)
        and then (if Editor.Outline.Last_Extraction_Source_Class (Copy) =
                    Editor.Outline.Stale_Extracted_Outline
                  then Next = 0 and then Previous = 0 and then Nearest = 0
                    and then not Has_Match and then not Can_Reveal
                    and then not Buffer_Matches and then not Has_Navigable
                    and then Symbol_Count = 0
                    and then Filtered_Symbol_Count = 0
                  else True);
   end Outline_Helper_Purity_Check;

   function Assert_Ada_Symbol_Navigation_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Command_Surface_Check
        and then Outline_Helper_Purity_Check
          (State.Outline, State.Registry_Token)
        and then Editor.Outline.Invariant_Holds (State.Outline);
   end Assert_Ada_Symbol_Navigation_Coherent;

   function Assert_Ada_Local_Structure_Awareness_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
      Copy    : Editor.Outline.Outline_State := State.Outline;
      Before  : constant Natural := Editor.Outline.Fingerprint (Copy);
      Current : Natural := 0;
   begin
      if not Assert_Ada_Symbol_Navigation_Coherent (State) then
         return False;
      end if;

      Current := Editor.Outline.Find_Current_Symbol_For_Cursor
        (Copy, State.Registry_Token, 1, 1);

      return Editor.Outline.Fingerprint (Copy) = Before
        and then Editor.Outline.Invariant_Holds (Copy)
        and then (if State.Registry_Token = 0 then Current = 0 else True);
   end Assert_Ada_Local_Structure_Awareness_Coherent;


   function Assert_Ada_Lexical_Safety_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
      pragma Unreferenced (State);
      Line : constant String :=
        "X : String := ""-- procedure Fake""; C := 'P'; Y := Integer'Image (Value); -- end;";
      Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Line);
      String_Column  : constant Natural := Ada.Strings.Fixed.Index (Line, "procedure");
      Comment_Column : constant Natural := Ada.Strings.Fixed.Index (Line, "-- end");
      Attr_Column    : constant Natural := Ada.Strings.Fixed.Index (Line, "'Image");
      Char_Column    : constant Natural := Ada.Strings.Fixed.Index (Line, "'P'");
      Doubled_Line   : constant String :=
        "S : constant String := ""quoted """" package Fake is """" -- text""; procedure Real;";
      Doubled_Sanitized : constant String :=
        Editor.Ada_Syntax_Core.Sanitize_Line (Doubled_Line);
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("-- package Fake is" & Character'Val (10) &
           "package Real is" & Character'Val (10) &
           "   S : constant String := ""procedure Hidden is"";" & Character'Val (10) &
           "   C : Character := 'P';" & Character'Val (10) &
           "   procedure Run; -- function Hidden return Integer;" & Character'Val (10) &
           "end Real;",
           "real.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      return Sanitized'Length = Line'Length
        and then Ada.Strings.Fixed.Index (Sanitized, "procedure") = 0
        and then Ada.Strings.Fixed.Index (Sanitized, "--") = 0
        and then not Editor.Ada_Syntax_Core.Is_Code_Column
          (Line, Positive (String_Column))
        and then not Editor.Ada_Syntax_Core.Is_Code_Column
          (Line, Positive (Comment_Column))
        and then Editor.Ada_Syntax_Core.Is_Code_Column
          (Line, Positive (Attr_Column))
        and then not Editor.Ada_Syntax_Core.Is_Code_Column
          (Line, Positive (Char_Column))
        and then Ada.Strings.Fixed.Index (Doubled_Sanitized, "package Fake") = 0
        and then Ada.Strings.Fixed.Index (Doubled_Sanitized, "-- text") = 0
        and then Ada.Strings.Fixed.Index (Doubled_Sanitized, "procedure Real") /= 0
        and then Editor.Outline_Extractor.Is_Success (Result)
        and then Editor.Outline_Extractor.Item_Count (Result) = 4;
   end Assert_Ada_Lexical_Safety_Coherent;

   function Active_Buffer_Scope_Check
     (Outline : Editor.Outline.Outline_State;
      Active_Buffer_Token : Natural) return Boolean
   is
   begin
      for I in 1 .. Editor.Outline.Item_Count (Outline) loop
         if Editor.Outline.Item_Target_Kind (Outline, I) =
              Editor.Outline.Buffer_Position_Target
         then
            if Editor.Outline.Item_Buffer_Token (Outline, I) = 0 then
               return False;
            end if;

            if Active_Buffer_Token /= 0
              and then Editor.Outline.Item_Buffer_Token (Outline, I) /=
                Active_Buffer_Token
            then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Active_Buffer_Scope_Check;

   function Refresh_Ownership_Check
     (Outline : Editor.Outline.Outline_State) return Boolean
   is
      Copy   : Editor.Outline.Outline_State := Outline;
      Before : constant Natural := Editor.Outline.Fingerprint (Copy);
      Result : constant Editor.Outline.Outline_Refresh_Result :=
        Editor.Outline.Refresh (Copy, Editor.Outline.Outline_Source_Buffer_Extractor);
   begin
      return Result.Status = Editor.Outline.Outline_Refresh_Unavailable
        and then Result.Failure_Kind = Editor.Outline.Extractor_Not_Available
        and then Editor.Outline.Fingerprint (Copy) = Before
        and then Editor.Outline.Item_Count (Copy) =
          Editor.Outline.Item_Count (Outline)
        and then Editor.Outline.Selected_Index (Copy) =
          Editor.Outline.Selected_Index (Outline)
        and then Editor.Outline.Current_Symbol_Index (Copy) =
          Editor.Outline.Current_Symbol_Index (Outline);
   end Refresh_Ownership_Check;

   function Projection_Purity_Check
     (Outline : Editor.Outline.Outline_State) return Boolean
   is
      Copy   : Editor.Outline.Outline_State := Outline;
      Panel  : Editor.Feature_Panel.Feature_Panel_State;
      Before : constant Natural := Editor.Outline.Fingerprint (Copy);
      Sel    : constant Natural := Editor.Outline.Selected_Index (Copy);
      Cur    : constant Natural := Editor.Outline.Current_Symbol_Index (Copy);
   begin
      Editor.Outline.Set_Rows_From_Outline (Copy, Panel);
      return Editor.Outline.Fingerprint (Copy) = Before
        and then Editor.Outline.Selected_Index (Copy) = Sel
        and then Editor.Outline.Current_Symbol_Index (Copy) = Cur
        and then Editor.Outline.Invariant_Holds (Copy);
   end Projection_Purity_Check;

   function Selection_Stable_Check
     (Outline : Editor.Outline.Outline_State) return Boolean
   is
      Copy : Editor.Outline.Outline_State := Outline;
   begin
      if Editor.Outline.Selected_Index (Copy) >
        Editor.Outline.Item_Count (Copy)
      then
         return False;
      end if;

      Editor.Outline.Select_Item
        (Copy, Editor.Outline.Item_Count (Copy) + 100);
      return Editor.Outline.Selected_Index (Copy) = 0
        and then Editor.Outline.Invariant_Holds (Copy);
   end Selection_Stable_Check;

   function Current_Symbol_Check
     (Outline : Editor.Outline.Outline_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Copy   : Editor.Outline.Outline_State := Outline;
      Before : constant Natural := Editor.Outline.Fingerprint (Copy);
      Sel    : constant Natural := Editor.Outline.Selected_Index (Copy);
   begin
      if Active_Buffer_Token = 0 then
         Editor.Outline.Clear_Current_Symbol (Copy);
      else
         Editor.Outline.Update_Current_Symbol_For_Cursor
           (Copy, Active_Buffer_Token, 1, 1);
      end if;

      return Editor.Outline.Fingerprint (Copy) = Before
        and then Editor.Outline.Selected_Index (Copy) = Sel
        and then Editor.Outline.Invariant_Holds (Copy);
   end Current_Symbol_Check;

   function Target_Validation_Check
     (Outline : Editor.Outline.Outline_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Panel : Editor.Feature_Panel.Feature_Panel_State;
   begin
      Editor.Outline.Set_Rows_From_Outline (Outline, Panel);

      if Editor.Feature_Panel.Row_Count (Panel) = 0 then
         return not Editor.Outline.Validate_Outline_Row_For_Activation
           (Outline, Panel, 0, Active_Buffer_Token);
      end if;

      for Row in 1 .. Editor.Feature_Panel.Row_Count (Panel) loop
         if Editor.Outline.Validate_Outline_Row_For_Activation
           (Outline, Panel, Row, 0)
         then
            return False;
         end if;
      end loop;

      return True;
   end Target_Validation_Check;

   function Filter_Projection_Check
     (Outline : Editor.Outline.Outline_State) return Boolean
   is
      Copy   : Editor.Outline.Outline_State := Outline;
      Before : constant Natural := Editor.Outline.Fingerprint (Copy);
   begin
      if Editor.Outline.Item_Count (Copy) = 0 then
         return Editor.Outline.Filter_Text (Copy) = ""
           and then Editor.Outline.Invariant_Holds (Copy);
      end if;

      Editor.Outline.Apply_Filter (Copy, "filter-probe");
      return Editor.Outline.Fingerprint (Copy) = Before
        and then Editor.Outline.Invariant_Holds (Copy);
   end Filter_Projection_Check;

   function Lifecycle_Check
     (Outline : Editor.Outline.Outline_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Copy : Editor.Outline.Outline_State := Outline;
   begin
      if Active_Buffer_Token /= 0 then
         Editor.Outline.Reset_Outline_For_Buffer_Close
           (Copy, Active_Buffer_Token);
      else
         Editor.Outline.Reset_Outline_For_Project_Close (Copy);
      end if;
      return Editor.Outline.Invariant_Holds (Copy)
        and then Editor.Outline.Selected_Index (Copy) <=
          Editor.Outline.Item_Count (Copy)
        and then (not Editor.Outline.Has_Current_Symbol (Copy)
                  or else Editor.Outline.Current_Symbol_Index (Copy) <=
                    Editor.Outline.Item_Count (Copy));
   end Lifecycle_Check;

   function Review_Outline_Contract
     (State : Editor.State.State_Type) return Outline_Contract_Review
   is
      Command_Review : constant Editor.Command_Surface.Command_Surface_Review :=
        Editor.Command_Surface.Review_Command_Surface (State);
      Manifest : constant Editor.External_Producers.Public_Build_Guardrail_Regression_Manifest :=
        Editor.External_Producers.Build_Public_Build_Guardrail_Regression_Manifest
          (State);
      Panel_Review : constant Editor.Feature_Panel_Audit.Feature_Panel_Contract_Review :=
        Editor.Feature_Panel_Audit.Review_Feature_Panel_Contract (State);
      Review : Outline_Contract_Review;
   begin
      Review.Active_Buffer_Only :=
        Active_Buffer_Scope_Check (State.Outline, State.Registry_Token);
      Review.Refresh_Command_Owned := Refresh_Ownership_Check (State.Outline);
      Review.Extraction_Deterministic :=
        Editor.Outline.Invariant_Holds (State.Outline);
      Review.Projection_Side_Effect_Free :=
        Projection_Purity_Check (State.Outline);
      Review.Selection_Stable := Selection_Stable_Check (State.Outline);
      Review.Current_Symbol_Derived :=
        Current_Symbol_Check (State.Outline, State.Registry_Token);
      Review.Targets_Validated :=
        Target_Validation_Check (State.Outline, State.Registry_Token);
      Review.Filters_Projection_Only := Filter_Projection_Check (State.Outline);
      Review.Ada_Symbol_Navigation_Coherent :=
        Assert_Ada_Symbol_Navigation_Coherent (State);
      Review.Ada_Local_Structure_Coherent :=
        Assert_Ada_Local_Structure_Awareness_Coherent (State);
      Review.Ada_Lexical_Safety_Coherent :=
        Assert_Ada_Lexical_Safety_Coherent (State);
      Review.Lifecycle_Reset_Stable :=
        Lifecycle_Check (State.Outline, State.Registry_Token);
      Review.Persistence_Clean := Manifest.Persistence_Exclusion_Clean;
      Review.Feature_Panel_Intact := Panel_Review.Review_Passed;
      Review.Command_Surface_Intact := Command_Review.Review_Passed;
      Review.Public_Build_Guardrail_Intact := Manifest.Manifest_Healthy;

      Review.Review_Passed :=
        Review.Active_Buffer_Only
        and then Review.Refresh_Command_Owned
        and then Review.Extraction_Deterministic
        and then Review.Projection_Side_Effect_Free
        and then Review.Selection_Stable
        and then Review.Current_Symbol_Derived
        and then Review.Targets_Validated
        and then Review.Filters_Projection_Only
        and then Review.Ada_Symbol_Navigation_Coherent
        and then Review.Ada_Local_Structure_Coherent
        and then Review.Ada_Lexical_Safety_Coherent
        and then Review.Lifecycle_Reset_Stable
        and then Review.Persistence_Clean
        and then Review.Feature_Panel_Intact
        and then Review.Command_Surface_Intact
        and then Review.Public_Build_Guardrail_Intact;
      return Review;
   end Review_Outline_Contract;

   function Build_Outline_Contract_Review_Feedback
     (Review : Outline_Contract_Review) return String
   is
   begin
      if Review.Review_Passed then
         return "Outline: contract healthy";
      elsif not Review.Active_Buffer_Only then
         return "Outline: active-buffer scope failed";
      elsif not Review.Refresh_Command_Owned then
         return "Outline: refresh ownership failed";
      elsif not Review.Extraction_Deterministic then
         return "Outline: extraction nondeterministic";
      elsif not Review.Projection_Side_Effect_Free then
         return "Outline: projection mutation detected";
      elsif not Review.Selection_Stable then
         return "Outline: selection stability failed";
      elsif not Review.Current_Symbol_Derived then
         return "Outline: current symbol derivation failed";
      elsif not Review.Targets_Validated then
         return "Outline: target validation failed";
      elsif not Review.Filters_Projection_Only then
         return "Outline: filter projection failed";
      elsif not Review.Ada_Symbol_Navigation_Coherent then
         return "Outline: Ada symbol navigation coherence failed";
      elsif not Review.Ada_Local_Structure_Coherent then
         return "Outline: Ada local structure coherence failed";
      elsif not Review.Ada_Lexical_Safety_Coherent then
         return "Outline: Ada lexical safety coherence failed";
      elsif not Review.Lifecycle_Reset_Stable then
         return "Outline: lifecycle reset unstable";
      elsif not Review.Persistence_Clean then
         return "Outline: persistence boundary failed";
      elsif not Review.Feature_Panel_Intact then
         return "Outline: Feature Panel contract failed";
      elsif not Review.Command_Surface_Intact then
         return "Outline: command surface review failed";
      elsif not Review.Public_Build_Guardrail_Intact then
         return "Outline: public build guardrail failed";
      else
         return "Outline: contract review failed";
      end if;
   end Build_Outline_Contract_Review_Feedback;

end Editor.Outline_Audit;
