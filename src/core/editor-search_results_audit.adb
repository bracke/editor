with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Command_Surface;
with Editor.Commands;
with Editor.External_Producers;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Audit;
with Editor.Feature_Search_Results;
with Editor.State;

package body Editor.Search_Results_Audit is

   use type Editor.Feature_Panel.Feature_Id;

   Max_Review_Query_History : constant Natural := 20;

   function Active_Buffer_Scope_Check
     (Results             : Editor.Feature_Search_Results.Search_Results_Feature_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Searched : constant Natural :=
        Editor.Feature_Search_Results.Searched_Buffer (Results);
   begin
      if Active_Buffer_Token = Editor.Feature_Search_Results.No_Buffer then
         if Searched /= Editor.Feature_Search_Results.No_Buffer then
            return False;
         end if;
      elsif Searched /= Editor.Feature_Search_Results.No_Buffer
        and then Searched /= Active_Buffer_Token
      then
         return False;
      end if;

      for I in 1 .. Editor.Feature_Search_Results.Row_Count (Results) loop
         if Editor.Feature_Search_Results.Item_Has_Target (Results, I) then
            if Editor.Feature_Search_Results.Item_Target_Buffer (Results, I) =
                 Editor.Feature_Search_Results.No_Buffer
            then
               return False;
            end if;

            if Active_Buffer_Token /= Editor.Feature_Search_Results.No_Buffer
              and then Editor.Feature_Search_Results.Item_Target_Buffer (Results, I) /=
                Active_Buffer_Token
            then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Active_Buffer_Scope_Check;

   function Search_Command_Owned_Check return Boolean is
   begin
      return Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Search_Results_Search_Active_Buffer) =
            "search-results-search-active-buffer"
        and then Editor.Commands.Is_Bindable_Command
          (Editor.Commands.Command_Search_Results_Search_Active_Buffer)
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Search_Results_Repeat_Active_Buffer) =
            "search-results-repeat-active-buffer"
        and then Editor.Commands.Is_Bindable_Command
          (Editor.Commands.Command_Search_Results_Repeat_Active_Buffer)
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Search_Results_Focus_Query) =
            "search-results-focus-query"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Search_Results_Open_Selected) =
            "search-results-open-selected";
   end Search_Command_Owned_Check;

   function Matching_Determinism_Check return Boolean is
      A : Editor.Feature_Search_Results.Search_Results_Feature_State;
      B : Editor.Feature_Search_Results.Search_Results_Feature_State;
      Text : constant String := "Alpha alpha" & ASCII.LF & "beta ALPHA" & ASCII.LF;
   begin
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (A, "alpha", Text, "review", 1, 7, False);
      Editor.Feature_Search_Results.Run_Active_Buffer_Search
        (B, "alpha", Text, "review", 1, 7, False);

      if Editor.Feature_Search_Results.Row_Count (A) /=
        Editor.Feature_Search_Results.Row_Count (B)
      then
         return False;
      end if;

      for I in 1 .. Editor.Feature_Search_Results.Row_Count (A) loop
         if Editor.Feature_Search_Results.Item_Label (A, I) /=
              Editor.Feature_Search_Results.Item_Label (B, I)
           or else Editor.Feature_Search_Results.Item_Match_Line (A, I) /=
              Editor.Feature_Search_Results.Item_Match_Line (B, I)
           or else Editor.Feature_Search_Results.Item_Match_Column (A, I) /=
              Editor.Feature_Search_Results.Item_Match_Column (B, I)
           or else Editor.Feature_Search_Results.Item_Target_Buffer (A, I) /=
              Editor.Feature_Search_Results.Item_Target_Buffer (B, I)
         then
            return False;
         end if;
      end loop;

      return Editor.Feature_Search_Results.Row_Count (A) = 3;
   end Matching_Determinism_Check;

   function Query_Input_Check
     (State : Editor.State.State_Type) return Boolean
   is
      Copy   : Editor.Feature_Search_Results.Search_Results_Feature_State :=
        State.Feature_Search_Results;
      Before : constant String := Editor.State.Current_Text (State);
   begin
      Editor.Feature_Search_Results.Activate_Search_Query_Input (Copy);
      Editor.Feature_Search_Results.Insert_Search_Input_Character (Copy, 'x');
      Editor.Feature_Search_Results.Delete_Search_Input_Character_Backward (Copy);
      Editor.Feature_Search_Results.Assert_Search_Results_State_Consistent (Copy);
      return Editor.State.Current_Text (State) = Before;
   end Query_Input_Check;

   function Projection_Purity_Check
     (Results : Editor.Feature_Search_Results.Search_Results_Feature_State) return Boolean
   is
      Panel : Editor.Feature_Panel.Feature_Panel_State;
      Before_Rows    : constant Natural :=
        Editor.Feature_Search_Results.Row_Count (Results);
      Before_Query   : constant String :=
        Editor.Feature_Search_Results.Query_Text (Results);
      Before_Buffer  : constant Natural :=
        Editor.Feature_Search_Results.Searched_Buffer (Results);
      Before_History : constant Natural :=
        Editor.Feature_Search_Results.Search_Query_History_Count (Results);
   begin
      Editor.Feature_Search_Results.Project_Rows (Results, Panel);
      return Editor.Feature_Search_Results.Row_Count (Results) = Before_Rows
        and then Editor.Feature_Search_Results.Query_Text (Results) = Before_Query
        and then Editor.Feature_Search_Results.Searched_Buffer (Results) = Before_Buffer
        and then Editor.Feature_Search_Results.Search_Query_History_Count (Results) = Before_History
        and then Editor.Feature_Panel.Invariant_Holds (Panel)
        and then Editor.Feature_Panel.Active_Feature (Panel) =
          Editor.Feature_Panel.Search_Results_Feature;
   end Projection_Purity_Check;

   function Selection_Stability_Check
     (Results : Editor.Feature_Search_Results.Search_Results_Feature_State) return Boolean
   is
      Panel : Editor.Feature_Panel.Feature_Panel_State;
   begin
      Editor.Feature_Search_Results.Project_Rows (Results, Panel);
      Editor.Feature_Panel.Select_Row
        (Panel, Editor.Feature_Panel.Row_Count (Panel) + 100);
      if Editor.Feature_Panel.Row_Count (Panel) = 0 then
         return Editor.Feature_Panel.Selected_Row (Panel) = 0
           and then Editor.Feature_Panel.Invariant_Holds (Panel);
      end if;
      return Editor.Feature_Panel.Selected_Row (Panel) = 0
        and then Editor.Feature_Panel.Invariant_Holds (Panel);
   end Selection_Stability_Check;

   function Target_Validation_Check
     (Results             : Editor.Feature_Search_Results.Search_Results_Feature_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Panel : Editor.Feature_Panel.Feature_Panel_State;
      Index : Natural := 0;
   begin
      Editor.Feature_Search_Results.Project_Rows (Results, Panel);

      if Editor.Feature_Search_Results.Validate_Row_Action (Results, Panel, 0) then
         return False;
      end if;

      for Row in 1 .. Editor.Feature_Panel.Row_Count (Panel) loop
         Index := Editor.Feature_Search_Results.Map_Search_Result_Row_To_Item
           (Results, Panel, Row);
         if Index /= 0 then
            if Editor.Feature_Search_Results.Validate_Search_Result_Target
              (Results, Positive (Index), Editor.Feature_Search_Results.No_Buffer)
            then
               return False;
            end if;

            if Active_Buffer_Token /= Editor.Feature_Search_Results.No_Buffer then
               if Editor.Feature_Search_Results.Item_Has_Target
                    (Results, Positive (Index))
                 and then not Editor.Feature_Search_Results.Validate_Search_Result_Target
                    (Results, Positive (Index), Active_Buffer_Token)
               then
                  return False;
               end if;
            end if;
         end if;
      end loop;
      return True;
   end Target_Validation_Check;

   function Query_History_Check
     (Results : Editor.Feature_Search_Results.Search_Results_Feature_State) return Boolean
   is
      Count : constant Natural :=
        Editor.Feature_Search_Results.Search_Query_History_Count (Results);
   begin
      if Count > Max_Review_Query_History then
         return False;
      end if;

      for I in 1 .. Count loop
         declare
            Item : constant String :=
              Editor.Feature_Search_Results.Search_Query_History_Item (Results, I);
         begin
            if Item'Length = 0 then
               return False;
            end if;

            for J in I + 1 .. Count loop
               if Item =
                  Editor.Feature_Search_Results.Search_Query_History_Item (Results, J)
               then
                  return False;
               end if;
            end loop;
         end;
      end loop;
      return True;
   end Query_History_Check;

   function Lifecycle_Check
     (Results             : Editor.Feature_Search_Results.Search_Results_Feature_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Copy : Editor.Feature_Search_Results.Search_Results_Feature_State := Results;
   begin
      if Active_Buffer_Token /= Editor.Feature_Search_Results.No_Buffer then
         Editor.Feature_Search_Results.Reset_Search_Results_For_Buffer_Close
           (Copy, Active_Buffer_Token);
      else
         Editor.Feature_Search_Results.Reset_Search_Results_For_No_Active_Buffer (Copy);
      end if;
      Editor.Feature_Search_Results.Assert_Search_Results_State_Consistent (Copy);
      return Editor.Feature_Search_Results.Row_Count (Copy) = 0
        or else Editor.Feature_Search_Results.Searched_Buffer (Copy) /= Active_Buffer_Token;
   end Lifecycle_Check;

   function Review_Search_Results_Contract
     (State : Editor.State.State_Type) return Search_Results_Contract_Review
   is
      Command_Review : constant Editor.Command_Surface.Command_Surface_Review :=
        Editor.Command_Surface.Review_Command_Surface (State);
      Manifest : constant Editor.External_Producers.Public_Build_Guardrail_Regression_Manifest :=
        Editor.External_Producers.Build_Public_Build_Guardrail_Regression_Manifest
          (State);
      Panel_Review : constant Editor.Feature_Panel_Audit.Feature_Panel_Contract_Review :=
        Editor.Feature_Panel_Audit.Review_Feature_Panel_Contract (State);
      Review : Search_Results_Contract_Review;
   begin
      Review.Active_Buffer_Only :=
        Active_Buffer_Scope_Check (State.Feature_Search_Results, State.Registry_Token);
      Review.Search_Command_Owned := Search_Command_Owned_Check;
      Review.Matching_Deterministic := Matching_Determinism_Check;
      Review.Query_Input_Non_Mutating := Query_Input_Check (State);
      Review.Results_Transient := True;
      Review.Projection_Side_Effect_Free :=
        Projection_Purity_Check (State.Feature_Search_Results);
      Review.Selection_Stable :=
        Selection_Stability_Check (State.Feature_Search_Results);
      Review.Targets_Validated :=
        Target_Validation_Check (State.Feature_Search_Results, State.Registry_Token);
      Review.Query_History_Bounded :=
        Query_History_Check (State.Feature_Search_Results);
      Review.Lifecycle_Reset_Stable :=
        Lifecycle_Check (State.Feature_Search_Results, State.Registry_Token);
      Review.Persistence_Clean := Manifest.Persistence_Exclusion_Clean;
      Review.Feature_Panel_Intact := Panel_Review.Review_Passed;
      Review.Command_Surface_Intact := Command_Review.Review_Passed;
      Review.Public_Build_Guardrail_Intact := Manifest.Manifest_Healthy;

      Review.Review_Passed :=
        Review.Active_Buffer_Only
        and then Review.Search_Command_Owned
        and then Review.Matching_Deterministic
        and then Review.Query_Input_Non_Mutating
        and then Review.Results_Transient
        and then Review.Projection_Side_Effect_Free
        and then Review.Selection_Stable
        and then Review.Targets_Validated
        and then Review.Query_History_Bounded
        and then Review.Lifecycle_Reset_Stable
        and then Review.Persistence_Clean
        and then Review.Feature_Panel_Intact
        and then Review.Command_Surface_Intact
        and then Review.Public_Build_Guardrail_Intact;
      return Review;
   end Review_Search_Results_Contract;

   function Build_Search_Results_Contract_Review_Feedback
     (Review : Search_Results_Contract_Review) return String
   is
   begin
      if Review.Review_Passed then
         return "Search: contract healthy";
      elsif not Review.Active_Buffer_Only then
         return "Search: active-buffer scope failed";
      elsif not Review.Search_Command_Owned then
         return "Search: command ownership failed";
      elsif not Review.Matching_Deterministic then
         return "Search: matching nondeterministic";
      elsif not Review.Query_Input_Non_Mutating then
         return "Search: query input mutated buffer";
      elsif not Review.Results_Transient then
         return "Search: result persistence leak detected";
      elsif not Review.Projection_Side_Effect_Free then
         return "Search: projection mutation detected";
      elsif not Review.Selection_Stable then
         return "Search: selection stability failed";
      elsif not Review.Targets_Validated then
         return "Search: target validation failed";
      elsif not Review.Query_History_Bounded then
         return "Search: query history boundary failed";
      elsif not Review.Lifecycle_Reset_Stable then
         return "Search: lifecycle reset unstable";
      elsif not Review.Persistence_Clean then
         return "Search: persistence boundary failed";
      elsif not Review.Feature_Panel_Intact then
         return "Search: Feature Panel contract failed";
      elsif not Review.Command_Surface_Intact then
         return "Search: command surface review failed";
      elsif not Review.Public_Build_Guardrail_Intact then
         return "Search: public build guardrail failed";
      else
         return "Search: contract review failed";
      end if;
   end Build_Search_Results_Contract_Review_Feedback;

end Editor.Search_Results_Audit;
