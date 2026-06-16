with Editor.Command_Surface;
with Editor.Commands;
with Editor.External_Producers;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Audit;

package body Editor.Diagnostics_Audit is

   use type Editor.Feature_Diagnostics.Diagnostic_Id;
   use type Editor.Feature_Diagnostics.Diagnostic_Severity;
   use type Editor.Feature_Diagnostics.Diagnostic_Source_Kind;
   use type Editor.Feature_Panel.Feature_Id;

   function Session_Local_Check
     (Diagnostics : Editor.Feature_Diagnostics.Diagnostics_Feature_State) return Boolean
   is
   begin
      --  Diagnostics state has a bounded session-local store and exposes no
      --  persistence hook from the feature package. This check intentionally
      --  observes only the in-memory model.
      return Editor.Feature_Diagnostics.Row_Count (Diagnostics) <=
        Editor.Feature_Diagnostics.Max_Diagnostics
        and then Editor.Feature_Diagnostics.Max_Diagnostics > 0;
   end Session_Local_Check;

   function Retention_Check return Boolean
   is
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics + 5 loop
         Editor.Feature_Diagnostics.Add_Diagnostic
           (D,
            Editor.Feature_Diagnostics.Diagnostic_Warning,
            "retention check" & Natural'Image (I),
            "review",
            Source_Kind => Editor.Feature_Diagnostics.External_Diagnostic_Source);
      end loop;

      return Editor.Feature_Diagnostics.Row_Count (D) =
          Editor.Feature_Diagnostics.Max_Diagnostics
        and then Editor.Feature_Diagnostics.Item_Id (D, 1) = 6
        and then Editor.Feature_Diagnostics.Next_Diagnostic_Id (D) =
          Editor.Feature_Diagnostics.Diagnostic_Id
            (Editor.Feature_Diagnostics.Max_Diagnostics + 6);
   end Retention_Check;

   function Projection_Purity_Check
     (Diagnostics : Editor.Feature_Diagnostics.Diagnostics_Feature_State) return Boolean
   is
      Panel : Editor.Feature_Panel.Feature_Panel_State;
      Before_Rows    : constant Natural :=
        Editor.Feature_Diagnostics.Row_Count (Diagnostics);
      Before_Visible : constant Natural :=
        Editor.Feature_Diagnostics.Visible_Row_Count (Diagnostics);
      Before_Filter  : constant Boolean :=
        Editor.Feature_Diagnostics.Filter_Active (Diagnostics);
      Before_Text    : constant String :=
        Editor.Feature_Diagnostics.Filter_Text (Diagnostics);
      Before_Next_Id : constant Editor.Feature_Diagnostics.Diagnostic_Id :=
        Editor.Feature_Diagnostics.Next_Diagnostic_Id (Diagnostics);
   begin
      Editor.Feature_Diagnostics.Project_Rows (Diagnostics, Panel);
      return Editor.Feature_Diagnostics.Row_Count (Diagnostics) = Before_Rows
        and then Editor.Feature_Diagnostics.Visible_Row_Count (Diagnostics) = Before_Visible
        and then Editor.Feature_Diagnostics.Filter_Active (Diagnostics) = Before_Filter
        and then Editor.Feature_Diagnostics.Filter_Text (Diagnostics) = Before_Text
        and then Editor.Feature_Diagnostics.Next_Diagnostic_Id (Diagnostics) = Before_Next_Id
        and then Editor.Feature_Panel.Invariant_Holds (Panel)
        and then Editor.Feature_Panel.Active_Feature (Panel) =
          Editor.Feature_Panel.Diagnostics_Feature;
   end Projection_Purity_Check;

   function Filter_Composition_Check return Boolean
   is
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Original_Count : Natural;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Info, "style note", "editor",
         Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Warning, "warning", "file",
         Source_Kind => Editor.Feature_Diagnostics.File_Diagnostic_Source);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Error, "error", "external",
         Source_Kind => Editor.Feature_Diagnostics.External_Diagnostic_Source);
      Original_Count := Editor.Feature_Diagnostics.Row_Count (D);

      if Editor.Feature_Diagnostics.Visible_Row_Count (D) /= 3 then
         return False;
      end if;

      Editor.Feature_Diagnostics.Toggle_Info_Visible (D);
      if Editor.Feature_Diagnostics.Row_Count (D) /= Original_Count
        or else Editor.Feature_Diagnostics.Visible_Row_Count (D) /= 2
      then
         return False;
      end if;

      Editor.Feature_Diagnostics.Toggle_Source_Visible
        (D, Editor.Feature_Diagnostics.External_Diagnostic_Source);
      if Editor.Feature_Diagnostics.Row_Count (D) /= Original_Count
        or else Editor.Feature_Diagnostics.Visible_Row_Count (D) /= 1
      then
         return False;
      end if;

      Editor.Feature_Diagnostics.Set_Filter_Text (D, " WARNING ");
      if Editor.Feature_Diagnostics.Row_Count (D) /= Original_Count
        or else Editor.Feature_Diagnostics.Visible_Row_Count (D) /= 1
        or else Editor.Feature_Diagnostics.Filter_Text (D) /= "warning"
      then
         return False;
      end if;

      Editor.Feature_Diagnostics.Show_All (D);
      return Editor.Feature_Diagnostics.Row_Count (D) = Original_Count
        and then Editor.Feature_Diagnostics.Visible_Row_Count (D) = 3
        and then Editor.Feature_Diagnostics.Item_Id (D, 1) = 1
        and then Editor.Feature_Diagnostics.Item_Id (D, 2) = 2
        and then Editor.Feature_Diagnostics.Item_Id (D, 3) = 3;
   end Filter_Composition_Check;

   function Severity_Source_Stability_Check return Boolean
   is
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D, Editor.Feature_Diagnostics.Diagnostic_Error, "broken", "external",
         Source_Kind => Editor.Feature_Diagnostics.External_Diagnostic_Source);
      Editor.Feature_Diagnostics.Toggle_Errors_Visible (D);
      Editor.Feature_Diagnostics.Toggle_Source_Visible
        (D, Editor.Feature_Diagnostics.External_Diagnostic_Source);
      return Editor.Feature_Diagnostics.Row_Count (D) = 1
        and then Editor.Feature_Diagnostics.Item_Severity (D, 1) =
          Editor.Feature_Diagnostics.Diagnostic_Error
        and then Editor.Feature_Diagnostics.Item_Source_Kind (D, 1) =
          Editor.Feature_Diagnostics.External_Diagnostic_Source
        and then Editor.Feature_Diagnostics.Item_Source_Label (D, 1) = "external";
   end Severity_Source_Stability_Check;

   function Row_Identity_Check
     (Diagnostics : Editor.Feature_Diagnostics.Diagnostics_Feature_State) return Boolean
   is
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State := Diagnostics;
      First_Id : Editor.Feature_Diagnostics.Diagnostic_Id;
   begin
      if Editor.Feature_Diagnostics.Row_Count (D) = 0 then
         Editor.Feature_Diagnostics.Add_Diagnostic
           (D, Editor.Feature_Diagnostics.Diagnostic_Warning, "identity", "review",
            Source_Kind => Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
      end if;

      First_Id := Editor.Feature_Diagnostics.Item_Id (D, 1);
      Editor.Feature_Diagnostics.Toggle_Warnings_Visible (D);
      Editor.Feature_Diagnostics.Toggle_Warnings_Visible (D);
      return First_Id /= Editor.Feature_Diagnostics.No_Diagnostic
        and then Editor.Feature_Diagnostics.Item_Id (D, 1) = First_Id;
   end Row_Identity_Check;

   function Target_Validation_Check
     (Diagnostics         : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Panel : Editor.Feature_Panel.Feature_Panel_State;
      Index : Natural := 0;
   begin
      Editor.Feature_Diagnostics.Project_Rows (Diagnostics, Panel);

      if Editor.Feature_Diagnostics.Validate_Row_Action (Diagnostics, Panel, 0)
        or else Editor.Feature_Diagnostics.Diagnostic_Id_Is_Live
          (Diagnostics, Editor.Feature_Diagnostics.No_Diagnostic)
        or else Editor.Feature_Diagnostics.Validate_Diagnostic_Id_Target
          (Diagnostics, Editor.Feature_Diagnostics.No_Diagnostic, Active_Buffer_Token)
      then
         return False;
      end if;

      for Row in 1 .. Editor.Feature_Panel.Row_Count (Panel) loop
         Index := Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
           (Diagnostics, Panel, Row);
         if Index /= 0 then
            if Editor.Feature_Diagnostics.Validate_Diagnostic_Target
              (Diagnostics, Positive (Index), Editor.Feature_Diagnostics.No_Buffer)
            then
               return False;
            end if;

            if Editor.Feature_Diagnostics.Item_Has_Target
                 (Diagnostics, Positive (Index))
              and then Active_Buffer_Token /= Editor.Feature_Diagnostics.No_Buffer
              and then Editor.Feature_Diagnostics.Item_Target_Buffer
                 (Diagnostics, Positive (Index)) = Active_Buffer_Token
            then
               declare
                  Id : constant Editor.Feature_Diagnostics.Diagnostic_Id :=
                    Editor.Feature_Diagnostics.Item_Id
                      (Diagnostics, Positive (Index));
               begin
                  if not Editor.Feature_Diagnostics.Validate_Diagnostic_Target
                       (Diagnostics, Positive (Index), Active_Buffer_Token)
                    or else not Editor.Feature_Diagnostics.Validate_Diagnostic_Id_Target
                       (Diagnostics, Id, Active_Buffer_Token)
                  then
                     return False;
                  end if;
               end;
            end if;
         end if;
      end loop;

      return True;
   end Target_Validation_Check;

   function Actions_Routed_Check return Boolean is
      function Command_Route_Passes
        (Id : Editor.Commands.Command_Id) return Boolean
      is
      begin
         return Editor.Commands.Has_Stable_Name (Id)
           and then Editor.Commands.Has_Availability_Handler (Id)
           and then Editor.Commands.Is_Bindable_Command (Id);
      end Command_Route_Passes;
   begin
      return Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Show) = "diagnostics-show"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Clear) = "diagnostics-clear"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Open_Selected) =
            "diagnostics.open-selected"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Select_Next) =
            "diagnostics.next"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Select_Previous) =
            "diagnostics.previous"
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Show)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Clear)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Toggle_Info)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Toggle_Warnings)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Toggle_Errors)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Show_All)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Clear_Filter)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Filter_Errors)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Filter_Warnings)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Filter_Info_Notes)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Filter_Source)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Filter_Build)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Clear_Build)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Open_Selected)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Select_Next)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Select_Previous)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Clear_Selected)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Copy_Selected_Text)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Clear_Info)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Clear_Warnings)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Clear_Errors)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Toggle_Editor_Source)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Toggle_File_Source)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Toggle_Project_Source)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Toggle_External_Source)
        and then Command_Route_Passes (Editor.Commands.Command_Diagnostics_Toggle_Unknown_Source);
   end Actions_Routed_Check;

   function Lifecycle_Check
     (Diagnostics         : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Copy : Editor.Feature_Diagnostics.Diagnostics_Feature_State := Diagnostics;
   begin
      if Active_Buffer_Token /= Editor.Feature_Diagnostics.No_Buffer then
         Editor.Feature_Diagnostics.Reset_Diagnostics_For_Buffer_Close
           (Copy, Active_Buffer_Token);
         for I in 1 .. Editor.Feature_Diagnostics.Row_Count (Copy) loop
            if Editor.Feature_Diagnostics.Item_Has_Target (Copy, I)
              and then Editor.Feature_Diagnostics.Item_Target_Buffer (Copy, I) =
                Active_Buffer_Token
            then
               return False;
            end if;
         end loop;
      end if;

      Editor.Feature_Diagnostics.Reset_Diagnostics_For_Workspace_Close (Copy);
      return Editor.Feature_Diagnostics.Row_Count (Copy) = 0
        and then Editor.Feature_Diagnostics.Next_Diagnostic_Id (Copy) = 1
        and then Editor.Feature_Diagnostics.Visible_Row_Count (Copy) = 0;
   end Lifecycle_Check;

   function Review_Diagnostics_Contract
     (State : Editor.State.State_Type) return Diagnostics_Contract_Review
   is
      Command_Review : constant Editor.Command_Surface.Command_Surface_Review :=
        Editor.Command_Surface.Review_Command_Surface (State);
      Manifest : constant Editor.External_Producers.Public_Build_Guardrail_Regression_Manifest :=
        Editor.External_Producers.Build_Public_Build_Guardrail_Regression_Manifest
          (State);
      Panel_Review : constant Editor.Feature_Panel_Audit.Feature_Panel_Contract_Review :=
        Editor.Feature_Panel_Audit.Review_Feature_Panel_Contract (State);
      Review : Diagnostics_Contract_Review;
   begin
      Review.Session_Local := Session_Local_Check (State.Feature_Diagnostics);
      Review.Retention_Bounded := Retention_Check;
      Review.Projection_Side_Effect_Free :=
        Projection_Purity_Check (State.Feature_Diagnostics);
      Review.Filters_Compose := Filter_Composition_Check;
      Review.Severity_Source_Stable := Severity_Source_Stability_Check;
      Review.Row_Identity_Stable := Row_Identity_Check (State.Feature_Diagnostics);
      Review.Targets_Validated :=
        Target_Validation_Check (State.Feature_Diagnostics, State.Registry_Token);
      Review.Actions_Routed := Actions_Routed_Check;
      Review.Lifecycle_Reset_Stable :=
        Lifecycle_Check (State.Feature_Diagnostics, State.Registry_Token);
      Review.Persistence_Clean := Manifest.Persistence_Exclusion_Clean;
      Review.Feature_Panel_Intact := Panel_Review.Review_Passed;
      Review.Command_Surface_Intact := Command_Review.Review_Passed;
      Review.Public_Build_Guardrail_Intact := Manifest.Manifest_Healthy;

      Review.Review_Passed :=
        Review.Session_Local
        and then Review.Retention_Bounded
        and then Review.Projection_Side_Effect_Free
        and then Review.Filters_Compose
        and then Review.Severity_Source_Stable
        and then Review.Row_Identity_Stable
        and then Review.Targets_Validated
        and then Review.Actions_Routed
        and then Review.Lifecycle_Reset_Stable
        and then Review.Persistence_Clean
        and then Review.Feature_Panel_Intact
        and then Review.Command_Surface_Intact
        and then Review.Public_Build_Guardrail_Intact;
      return Review;
   end Review_Diagnostics_Contract;

   function Build_Diagnostics_Contract_Review_Feedback
     (Review : Diagnostics_Contract_Review) return String
   is
   begin
      if Review.Review_Passed then
         return "Diagnostics: contract healthy";
      elsif not Review.Session_Local then
         return "Diagnostics: session-local scope failed";
      elsif not Review.Retention_Bounded then
         return "Diagnostics: retention bound failed";
      elsif not Review.Projection_Side_Effect_Free then
         return "Diagnostics: projection mutation detected";
      elsif not Review.Filters_Compose then
         return "Diagnostics: filter composition failed";
      elsif not Review.Severity_Source_Stable then
         return "Diagnostics: severity/source instability detected";
      elsif not Review.Row_Identity_Stable then
         return "Diagnostics: row identity instability detected";
      elsif not Review.Targets_Validated then
         return "Diagnostics: target validation failed";
      elsif not Review.Actions_Routed then
         return "Diagnostics: action route invalid";
      elsif not Review.Lifecycle_Reset_Stable then
         return "Diagnostics: lifecycle reset unstable";
      elsif not Review.Persistence_Clean then
         return "Diagnostics: persistence boundary failed";
      elsif not Review.Feature_Panel_Intact then
         return "Diagnostics: Feature Panel contract failed";
      elsif not Review.Command_Surface_Intact then
         return "Diagnostics: command surface review failed";
      elsif not Review.Public_Build_Guardrail_Intact then
         return "Diagnostics: public build guardrail failed";
      else
         return "Diagnostics: contract review failed";
      end if;
   end Build_Diagnostics_Contract_Review_Feedback;

end Editor.Diagnostics_Audit;
