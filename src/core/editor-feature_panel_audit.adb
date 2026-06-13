with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Command_Surface;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Messages;
with Editor.Feature_Diagnostics;
with Editor.Message_Producers;
with Editor.Producer_Contracts;
with Editor.External_Producers;
with Editor.State;

package body Editor.Feature_Panel_Audit is

   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Feature_Panel.Feature_Panel_Fingerprint;
   use type Editor.Commands.Command_Id;
   use type Editor.Producer_Contracts.Producer_Result_Status;

   function Non_Empty (Text : String) return Boolean is
   begin
      return Text'Length > 0;
   end Non_Empty;

   function Descriptor_Index_For
     (Feature : Editor.Feature_Panel.Feature_Id) return Natural
   is
   begin
      for I in 1 .. Editor.Feature_Panel.Feature_Descriptor_Count loop
         if Editor.Feature_Panel.Descriptor_Id (I) = Feature then
            return I;
         end if;
      end loop;
      return 0;
   end Descriptor_Index_For;

   function Command_Audit_Passes
     (Id : Editor.Commands.Command_Id) return Boolean
   is
      Found   : Boolean := False;
      Failure : Editor.Commands.Command_Audit_Failure;
   begin
      if not Editor.Commands.Has_Descriptor (Id)
        or else not Editor.Commands.Descriptor_Is_Complete (Id)
        or else not Editor.Commands.Has_Availability_Handler (Id)
      then
         return False;
      end if;

      if Editor.Commands.Is_Bindable_Command (Id)
        and then not Editor.Commands.Has_Stable_Name (Id)
      then
         return False;
      end if;

      Editor.Commands.Audit_Command (Id, Failure, Found);
      return not Found;
   end Command_Audit_Passes;

   function Feature_Command_Surface_Covers
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean
   is
   begin
      case Feature is
         when Editor.Feature_Panel.Outline_Feature =>
            return Command_Audit_Passes (Editor.Commands.Command_Show_Outline)
              and then Command_Audit_Passes (Editor.Commands.Command_Focus_Outline)
              and then Command_Audit_Passes (Editor.Commands.Command_Clear_Outline)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Open_Selected_Outline_Item);
         when Editor.Feature_Panel.Messages_Feature =>
            return Command_Audit_Passes (Editor.Commands.Command_Show_Messages)
              and then Command_Audit_Passes (Editor.Commands.Command_Clear_Messages)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Clear_Selected_Message)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Copy_Selected_Message_Text)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Clear_Info_Messages)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Clear_Warning_Messages)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Clear_Error_Messages)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Toggle_Message_Info)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Toggle_Message_Warnings)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Toggle_Message_Errors)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Show_All_Messages)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Clear_Message_Filter)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Dismiss_Latest_Message)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Dismiss_All_Messages);
         when Editor.Feature_Panel.Search_Results_Feature =>
            return Command_Audit_Passes
                (Editor.Commands.Command_Show_Search_Results_Feature)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Clear_Search_Results_Feature)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Search_Results_Search_Active_Buffer)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Search_Results_Repeat_Active_Buffer)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Search_Results_Focus_Query)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Search_Results_Query_History_Previous)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Search_Results_Query_History_Next)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Search_Results_Toggle_Case_Sensitive)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Search_Results_Open_Selected);
         when Editor.Feature_Panel.Diagnostics_Feature =>
            return Command_Audit_Passes (Editor.Commands.Command_Diagnostics_Show)
              and then Command_Audit_Passes (Editor.Commands.Command_Diagnostics_Clear)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Toggle_Info)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Toggle_Warnings)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Toggle_Errors)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Show_All)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Clear_Filter)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Open_Selected)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Select_Next)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Select_Previous)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Clear_Selected)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Copy_Selected_Text)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Clear_Info)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Clear_Warnings)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Clear_Errors)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Filter_Errors)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Filter_Warnings)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Filter_Info_Notes)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Filter_Source)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Filter_Build)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Clear_Build)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Toggle_Editor_Source)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Toggle_File_Source)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Toggle_Project_Source)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Toggle_External_Source)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Diagnostics_Toggle_Unknown_Source)
              and then Command_Audit_Passes
                (Editor.Commands.Command_Feature_Panel_Open_Selected);
         when Editor.Feature_Panel.Unknown_Feature =>
            return False;
      end case;
   end Feature_Command_Surface_Covers;


   function Producer_Capable_Feature_Covers
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean
   is
   begin
      case Feature is
         when Editor.Feature_Panel.Messages_Feature =>
            return Editor.Feature_Messages.Max_Retained_Messages > 0
              and then Editor.Message_Producers.Normalize_Message_Source (" audit ") = "audit";
         when Editor.Feature_Panel.Diagnostics_Feature =>
            return Editor.Feature_Diagnostics.Max_Diagnostics > 0;
         when others =>
            return True;
      end case;
   end Producer_Capable_Feature_Covers;

   function Producer_Boundary_Audit_Passes return Boolean
   is
      Empty_Rejected : constant Editor.Producer_Contracts.Producer_Result :=
        Editor.Producer_Contracts.Rejected_Empty_Text;
   begin
      return Empty_Rejected.Status =
          Editor.Producer_Contracts.Producer_Rejected_Empty_Text
        and then not Empty_Rejected.Row_Accepted
        and then Producer_Capable_Feature_Covers
          (Editor.Feature_Panel.Messages_Feature)
        and then Producer_Capable_Feature_Covers
          (Editor.Feature_Panel.Diagnostics_Feature)
        and then Editor.External_Producers.External_Producer_Audit_Passes;
   end Producer_Boundary_Audit_Passes;

   function Generic_Command_Surface_Passes return Boolean is
   begin
      return Command_Audit_Passes (Editor.Commands.Command_Toggle_Feature_Panel)
        and then Command_Audit_Passes (Editor.Commands.Command_Show_Feature_Panel)
        and then Command_Audit_Passes (Editor.Commands.Command_Hide_Feature_Panel)
        and then Command_Audit_Passes (Editor.Commands.Command_Focus_Feature_Panel)
        and then Command_Audit_Passes (Editor.Commands.Command_Clear_Feature_Panel)
        and then Command_Audit_Passes
          (Editor.Commands.Command_Feature_Panel_Select_Next)
        and then Command_Audit_Passes
          (Editor.Commands.Command_Feature_Panel_Select_Previous)
        and then Command_Audit_Passes
          (Editor.Commands.Command_Feature_Panel_Open_Selected);
   end Generic_Command_Surface_Passes;

   function Feature_Command_Surface_Covers_All_Features return Boolean
   is
      Feature : Editor.Feature_Panel.Feature_Id;
   begin
      if not Generic_Command_Surface_Passes then
         return False;
      end if;

      for I in 1 .. Editor.Feature_Panel.Feature_Descriptor_Count loop
         Feature := Editor.Feature_Panel.Descriptor_Id (I);
         if not Editor.Feature_Panel.Is_Known_Feature (Feature)
           or else not Feature_Command_Surface_Covers (Feature)
         then
            return False;
         end if;
      end loop;
      return True;
   end Feature_Command_Surface_Covers_All_Features;

   function Audit_Feature_Descriptors return Feature_Panel_Audit_Result
   is
      Result : Feature_Panel_Audit_Result;
      F      : Editor.Feature_Panel.Feature_Id;
   begin
      Result.Descriptor_Count := Editor.Feature_Panel.Feature_Descriptor_Count;

      for Feature in Editor.Feature_Panel.Feature_Id loop
         if Feature /= Editor.Feature_Panel.Unknown_Feature then
            if Descriptor_Index_For (Feature) = 0 then
               Result.Has_Missing_Descriptor := True;
            end if;
         end if;
      end loop;

      for I in 1 .. Editor.Feature_Panel.Feature_Descriptor_Count loop
         F := Editor.Feature_Panel.Descriptor_Id (I);
         if not Editor.Feature_Panel.Is_Known_Feature (F)
           or else not Non_Empty (Editor.Feature_Panel.Feature_Stable_Name (F))
           or else not Non_Empty (Editor.Feature_Panel.Feature_Display_Label (F))
         then
            Result.Has_Missing_Descriptor := True;
         end if;

         for J in I + 1 .. Editor.Feature_Panel.Feature_Descriptor_Count loop
            declare
               G : constant Editor.Feature_Panel.Feature_Id :=
                 Editor.Feature_Panel.Descriptor_Id (J);
            begin
               if F = G then
                  Result.Has_Missing_Descriptor := True;
               end if;
               if Editor.Feature_Panel.Feature_Stable_Name (F) =
                  Editor.Feature_Panel.Feature_Stable_Name (G)
               then
                  Result.Has_Duplicate_Stable_Name := True;
               end if;
               if Editor.Feature_Panel.Feature_Display_Label (F) =
                  Editor.Feature_Panel.Feature_Display_Label (G)
               then
                  Result.Has_Duplicate_Display_Label := True;
               end if;
            end;
         end loop;
      end loop;

      Result.Passed := not Result.Has_Missing_Descriptor
        and then not Result.Has_Duplicate_Stable_Name
        and then not Result.Has_Duplicate_Display_Label;
      return Result;
   end Audit_Feature_Descriptors;


   function Selection_Clamp_Check
     (Panel : Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
      Copy : Editor.Feature_Panel.Feature_Panel_State := Panel;
   begin
      Editor.Feature_Panel.Clear_Rows (Copy);
      if Editor.Feature_Panel.Selected_Row (Copy) /= 0
        or else not Editor.Feature_Panel.Invariant_Holds (Copy)
      then
         return False;
      end if;

      Editor.Feature_Panel.Append_Row
        (Copy, Editor.Feature_Panel.Feature_Row_Item, "one");
      Editor.Feature_Panel.Append_Row
        (Copy, Editor.Feature_Panel.Feature_Row_Item, "two");
      Editor.Feature_Panel.Select_Row (Copy, 99);
      if Editor.Feature_Panel.Selected_Row (Copy) /= 0
        or else not Editor.Feature_Panel.Invariant_Holds (Copy)
      then
         return False;
      end if;

      Editor.Feature_Panel.Select_First (Copy);
      Editor.Feature_Panel.Select_Next (Copy);
      Editor.Feature_Panel.Select_Next (Copy);
      if Editor.Feature_Panel.Selected_Row (Copy) /= 2 then
         return False;
      end if;

      Editor.Feature_Panel.Select_Previous (Copy);
      Editor.Feature_Panel.Select_Previous (Copy);
      return Editor.Feature_Panel.Selected_Row (Copy) = 1
        and then Editor.Feature_Panel.Invariant_Holds (Copy);
   end Selection_Clamp_Check;

   function Target_Token_Check
     (Panel : Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
      Copy  : Editor.Feature_Panel.Feature_Panel_State := Panel;
      Token : Editor.Feature_Panel.Feature_Projection_Token;
   begin
      if not Editor.Feature_Panel.Is_Known_Feature
        (Editor.Feature_Panel.Active_Feature (Copy))
      then
         return False;
      end if;

      Token := Editor.Feature_Panel.Build_Feature_Projection_Token (Copy);
      if not Editor.Feature_Panel.Validate_Feature_Projection_Token (Copy, Token) then
         return False;
      end if;

      Editor.Feature_Panel.Append_Row
        (Copy,
         Editor.Feature_Panel.Feature_Row_Item,
         "token probe",
         Activatable => True,
         Has_Target  => True,
         Action_Id   => 1);

      return not Editor.Feature_Panel.Validate_Feature_Projection_Token (Copy, Token)
        and then Editor.Feature_Panel.Invariant_Holds (Copy);
   end Target_Token_Check;

   function Lifecycle_Reset_Check
     (Panel : Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
      Copy : Editor.Feature_Panel.Feature_Panel_State := Panel;
   begin
      Editor.Feature_Panel.Set_Visible (Copy, True);
      Editor.Feature_Panel.Set_Focused (Copy, True);
      Editor.Feature_Panel.Clear_Rows (Copy);
      Editor.Feature_Panel.Append_Row
        (Copy,
         Editor.Feature_Panel.Feature_Row_Header,
         "audit",
         "lifecycle reset probe",
         Selectable => False);
      Editor.Feature_Panel.Append_Row
        (Copy,
         Editor.Feature_Panel.Feature_Row_Item,
         "audit row",
         "lifecycle reset probe",
         Selectable => True,
         Can_Clear  => True);
      Editor.Feature_Panel.Select_First (Copy);
      Editor.Feature_Panel.Reset_For_Project_Close (Copy);
      if not Editor.Feature_Panel.Invariant_Holds (Copy)
        or else Editor.Feature_Panel.Row_Count (Copy) /= 0
        or else Editor.Feature_Panel.Selected_Row (Copy) /= 0
        or else Editor.Feature_Panel.Is_Focused (Copy)
      then
         return False;
      end if;

      Editor.Feature_Panel.Clear (Copy);
      return Editor.Feature_Panel.Invariant_Holds (Copy)
        and then not Editor.Feature_Panel.Is_Visible (Copy)
        and then not Editor.Feature_Panel.Is_Focused (Copy)
        and then Editor.Feature_Panel.Row_Count (Copy) = 0
        and then Editor.Feature_Panel.Selected_Row (Copy) = 0;
   end Lifecycle_Reset_Check;

   function Render_Snapshot_Check
     (Panel : Editor.Feature_Panel.Feature_Panel_State) return Boolean
   is
      Before  : constant Editor.Feature_Panel.Feature_Panel_Fingerprint :=
        Editor.Feature_Panel.Fingerprint (Panel);
      Snapshot : constant Editor.Feature_Panel.Feature_Panel_Render_Snapshot :=
        Editor.Feature_Panel.Build_Render_Snapshot (Panel);
      After   : constant Editor.Feature_Panel.Feature_Panel_Fingerprint :=
        Editor.Feature_Panel.Fingerprint (Panel);
      pragma Unreferenced (Snapshot);
   begin
      return Before = After;
   end Render_Snapshot_Check;

   function Review_Feature_Panel_Contract
     (State : Editor.State.State_Type) return Feature_Panel_Contract_Review
   is
      Command_Review : constant Editor.Command_Surface.Command_Surface_Review :=
        Editor.Command_Surface.Review_Command_Surface (State);
      Manifest : constant Editor.External_Producers.Public_Build_Guardrail_Regression_Manifest :=
        Editor.External_Producers.Build_Public_Build_Guardrail_Regression_Manifest (State);
      Audit : constant Feature_Panel_Audit_Result := Run_Feature_Panel_Audit;
      Panel : constant Editor.Feature_Panel.Feature_Panel_State := State.Feature_Panel;
      Summary : constant Editor.Feature_Panel.Feature_Panel_Summary :=
        Editor.Feature_Panel.Summary (Panel);
      Review : Feature_Panel_Contract_Review;
   begin
      Review.Generic_State_Bounded :=
        Editor.Feature_Panel.Invariant_Holds (Panel)
        and then Editor.Feature_Panel.Feature_Descriptor_Count = 4;
      Review.Active_Feature_Valid :=
        Editor.Feature_Panel.Is_Known_Feature
          (Editor.Feature_Panel.Active_Feature (Panel));
      Review.Rows_Transient := Manifest.Persistence_Exclusion_Clean;
      Review.Selection_Valid :=
        (not Summary.Has_Selection)
        or else (Summary.Selected_Row >= 1
                 and then Summary.Selected_Row <= Summary.Row_Count);
      Review.Selection_Clamped := Selection_Clamp_Check (Panel);
      Review.Activation_Routed :=
        Audit.Passed
        and then Editor.Feature_Panel_Controller.Feature_Dispatch_Covers_All_Features;
      Review.Targets_Validated := Target_Token_Check (Panel);
      Review.Lifecycle_Reset_Stable := Lifecycle_Reset_Check (Panel);
      Review.Render_Snapshot_Pure := Render_Snapshot_Check (Panel);
      Review.Persistence_Clean := Manifest.Persistence_Exclusion_Clean;
      Review.Command_Surface_Intact := Command_Review.Review_Passed;
      Review.Public_Build_Guardrail_Intact := Manifest.Manifest_Healthy;

      Review.Review_Passed :=
        Review.Generic_State_Bounded
        and then Review.Active_Feature_Valid
        and then Review.Rows_Transient
        and then Review.Selection_Valid
        and then Review.Selection_Clamped
        and then Review.Activation_Routed
        and then Review.Targets_Validated
        and then Review.Lifecycle_Reset_Stable
        and then Review.Render_Snapshot_Pure
        and then Review.Persistence_Clean
        and then Review.Command_Surface_Intact
        and then Review.Public_Build_Guardrail_Intact;
      return Review;
   end Review_Feature_Panel_Contract;

   function Build_Feature_Panel_Contract_Review_Feedback
     (Review : Feature_Panel_Contract_Review) return String
   is
   begin
      if Review.Review_Passed then
         return "Feature Panel: contract healthy";
      elsif not Review.Active_Feature_Valid then
         return "Feature Panel: invalid active feature";
      elsif not Review.Rows_Transient or else not Review.Persistence_Clean then
         return "Feature Panel: persistent transient state detected";
      elsif not Review.Selection_Valid then
         return "Feature Panel: invalid selection detected";
      elsif not Review.Selection_Clamped then
         return "Feature Panel: selection clamp failed";
      elsif not Review.Activation_Routed then
         return "Feature Panel: activation route invalid";
      elsif not Review.Targets_Validated then
         return "Feature Panel: stale target validation failed";
      elsif not Review.Lifecycle_Reset_Stable then
         return "Feature Panel: lifecycle reset unstable";
      elsif not Review.Render_Snapshot_Pure then
         return "Feature Panel: render snapshot mutation detected";
      elsif not Review.Command_Surface_Intact then
         return "Feature Panel: command surface review failed";
      elsif not Review.Public_Build_Guardrail_Intact then
         return "Feature Panel: public build guardrail failed";
      else
         return "Feature Panel: invalid selection detected";
      end if;
   end Build_Feature_Panel_Contract_Review_Feedback;

   function Run_Feature_Panel_Audit return Feature_Panel_Audit_Result
   is
      Result : Feature_Panel_Audit_Result := Audit_Feature_Descriptors;
      Feature : Editor.Feature_Panel.Feature_Id;
   begin
      for I in 1 .. Editor.Feature_Panel.Feature_Descriptor_Count loop
         Feature := Editor.Feature_Panel.Descriptor_Id (I);
         if not Editor.Feature_Panel_Controller.Has_Projection_Dispatch (Feature) then
            Result.Has_Missing_Projection_Handler := True;
         end if;
         if not Editor.Feature_Panel_Controller.Has_Clear_Dispatch (Feature) then
            Result.Has_Missing_Clear_Handler := True;
         end if;
         if not Editor.Feature_Panel_Controller.Has_Open_Dispatch (Feature) then
            Result.Has_Missing_Open_Handler := True;
         end if;
         if not Editor.Feature_Panel_Controller.Has_Row_Action_Dispatch (Feature) then
            Result.Has_Missing_Row_Action_Handler := True;
         end if;
         if not Editor.Feature_Panel_Controller.Has_Lifecycle_Dispatch (Feature) then
            Result.Has_Missing_Lifecycle_Handler := True;
         end if;
         if not Feature_Command_Surface_Covers (Feature) then
            Result.Has_Command_Registration_Gap := True;
         end if;
         if not Producer_Capable_Feature_Covers (Feature) then
            Result.Has_Producer_Boundary_Gap := True;
         end if;
      end loop;

      if not Generic_Command_Surface_Passes then
         Result.Has_Command_Registration_Gap := True;
      end if;

      if not Producer_Boundary_Audit_Passes then
         Result.Has_Producer_Boundary_Gap := True;
      end if;

      if not Editor.External_Producers.Producer_Lifecycle_Audit_Passes then
         Result.Has_Producer_Lifecycle_Gap := True;
      end if;

      if not Editor.External_Producers.Compiler_Diagnostic_Normalization_Audit_Passes then
         Result.Has_Producer_Target_Gap := True;
      end if;

      Result.Passed := not Result.Has_Missing_Descriptor
        and then not Result.Has_Duplicate_Stable_Name
        and then not Result.Has_Duplicate_Display_Label
        and then not Result.Has_Missing_Projection_Handler
        and then not Result.Has_Missing_Clear_Handler
        and then not Result.Has_Missing_Open_Handler
        and then not Result.Has_Missing_Row_Action_Handler
        and then not Result.Has_Missing_Lifecycle_Handler
        and then not Result.Has_Command_Registration_Gap
        and then not Result.Has_Producer_Boundary_Gap
        and then not Result.Has_Producer_Lifecycle_Gap
        and then not Result.Has_Producer_Target_Gap;
      return Result;
   end Run_Feature_Panel_Audit;

   procedure Append_Flag
     (Text : in out Unbounded_String;
      Flag : String) is
   begin
      if Length (Text) > 0 then
         Append (Text, ",");
      end if;
      Append (Text, Flag);
   end Append_Flag;

   function Summary (Result : Feature_Panel_Audit_Result) return String
   is
      Flags : Unbounded_String := Null_Unbounded_String;
   begin
      if Result.Has_Missing_Descriptor then
         Append_Flag (Flags, "missing-descriptor");
      end if;
      if Result.Has_Duplicate_Stable_Name then
         Append_Flag (Flags, "duplicate-stable-name");
      end if;
      if Result.Has_Duplicate_Display_Label then
         Append_Flag (Flags, "duplicate-display-label");
      end if;
      if Result.Has_Missing_Projection_Handler then
         Append_Flag (Flags, "missing-projection-handler");
      end if;
      if Result.Has_Missing_Clear_Handler then
         Append_Flag (Flags, "missing-clear-handler");
      end if;
      if Result.Has_Missing_Open_Handler then
         Append_Flag (Flags, "missing-open-handler");
      end if;
      if Result.Has_Missing_Row_Action_Handler then
         Append_Flag (Flags, "missing-row-action-handler");
      end if;
      if Result.Has_Missing_Lifecycle_Handler then
         Append_Flag (Flags, "missing-lifecycle-handler");
      end if;
      if Result.Has_Command_Registration_Gap then
         Append_Flag (Flags, "command-registration-gap");
      end if;
      if Result.Has_Producer_Boundary_Gap then
         Append_Flag (Flags, "producer-boundary-gap");
      end if;
      if Result.Has_Producer_Lifecycle_Gap then
         Append_Flag (Flags, "producer-lifecycle-gap");
      end if;
      if Result.Has_Producer_Target_Gap then
         Append_Flag (Flags, "producer-target-gap");
      end if;

      if Result.Passed then
         return "feature-panel audit passed; descriptors=" &
           Natural'Image (Result.Descriptor_Count);
      end if;
      return "feature-panel audit failed; descriptors=" &
        Natural'Image (Result.Descriptor_Count) & "; flags=" & To_String (Flags);
   end Summary;

end Editor.Feature_Panel_Audit;
