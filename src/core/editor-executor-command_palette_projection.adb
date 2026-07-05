with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Command_Palette;
with Editor.Commands;
with Editor.Executor.Availability;
with Editor.Feature_Diagnostics;
with Editor.Keybindings;
with Editor.Overlay_Focus;
with Editor.Problems;
with Editor.State;

package body Editor.Executor.Command_Palette_Projection is

   function Lower (Text : String) return String
   is
   begin
      return Ada.Characters.Handling.To_Lower (Text);
   end Lower;

   procedure Command_Palette_Candidates
     (S      : Editor.State.State_Type;
      Result : out Editor.Commands.Command_Palette_Candidate_Vectors.Vector)
   is
      All_Commands : constant Editor.Commands.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Palette_Commands;
      Query : constant String :=
        To_String (Editor.Command_Palette.Current.Query);
      Score : Natural := 0;

      function Starts_With (Text : String; Prefix : String) return Boolean is
      begin
         return Text'Length >= Prefix'Length
           and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
      end Starts_With;

      function Relevance_Boost (Id : Editor.Commands.Command_Id) return Natural is
         Stable : constant String := Editor.Commands.Stable_Command_Name (Id);
         Previous : constant Editor.Overlay_Focus.Previous_Focus_Target :=
           Editor.Overlay_Focus.Previous_Focus (S.Overlay_Focus);
      begin
         --  while the Command Palette owns overlay focus, rank
         --  commands for the surface that opened it. This is pure projection
         --  metadata: it never changes focus, injects row payloads, or hides
         --  unrelated commands.
         case Previous is
            when Editor.Overlay_Focus.Previous_File_Tree =>
               if Starts_With (Stable, "file-tree.") then
                  return 50;
               end if;
            when Editor.Overlay_Focus.Previous_Search_Results =>
               if Starts_With (Stable, "project-search.")
                 or else Starts_With (Stable, "search-results.")
               then
                  return 50;
               end if;
            when Editor.Overlay_Focus.Previous_Problems =>
               if Starts_With (Stable, "diagnostics.")
                 or else Starts_With (Stable, "problems.")
               then
                  return 50;
               end if;
            when Editor.Overlay_Focus.Previous_Editor_Text
               | Editor.Overlay_Focus.Previous_None =>
               null;
         end case;
         return 0;
      end Relevance_Boost;

      function State_Context_For
        (Id : Editor.Commands.Command_Id) return String
      is
         Stable : constant String := Editor.Commands.Stable_Command_Name (Id);
      begin
         if Starts_With (Stable, "problems.") then
            return
              "Current Problems view: filter "
              & Editor.Problems.Severity_Filter_Label
                  (S.Problems_View.Severity_Filter)
              & ", sort "
              & Editor.Problems.Sort_Mode_Label (S.Problems_View.Sort_Mode)
              & ", group "
              & Editor.Problems.Group_Mode_Label (S.Problems_View.Group_Mode)
              & ".";
         elsif Starts_With (Stable, "diagnostics.") then
            return
              "Diagnostics review state: suppressed "
              & Ada.Strings.Fixed.Trim
                  (Natural'Image
                     (Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
                        (S.Feature_Diagnostics)),
                   Ada.Strings.Both)
              & ", visible "
              & Ada.Strings.Fixed.Trim
                  (Natural'Image
                     (Editor.Feature_Diagnostics.Visible_Row_Count
                        (S.Feature_Diagnostics)),
                   Ada.Strings.Both)
              & ".";
         elsif Starts_With (Stable, "build.") then
            declare
               Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
                 Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
               Selected : constant Natural :=
                 Editor.Build_UI.Selected_Action_Row
                   (S.Build_UI, Natural (Snapshot.Actions.Length));
               Selected_Label : constant String :=
                 (if Selected = 0 then "none"
                  else To_String (Snapshot.Actions.Element (Selected - 1).Label));
            begin
               return
                 "Current Build UI state: "
                 & (if Snapshot.Visible then "visible" else "hidden")
                 & ", selected action " & Selected_Label
                 & ", "
                 & To_String (Snapshot.Request_Status_Label)
                 & ", "
                 & To_String (Snapshot.Run_Command_Status_Label)
                 & ".";
            end;
         else
            return "";
         end if;
      end State_Context_For;

   begin
      Result.Clear;
      Editor.Command_Palette.Clear_Command_State_Contexts;

      for D of All_Commands loop
         declare
            Binding : constant Editor.Keybindings.Command_Keybinding_Info :=
              Editor.Keybindings.Primary_Binding_For_Command (D.Id);
         begin
            Score := Editor.Command_Palette.Metadata_Match_Score
              (Label          => To_String (D.Name),
               Stable_Name    => Editor.Commands.Stable_Command_Name (D.Id),
               Category_Label => Editor.Commands.Discoverability_Category_Label
                 (D.Id),
               Description    => To_String (D.Description),
               Keybinding     =>
                 (if Editor.Command_Palette.Current_Config.Show_Keybindings
                  then To_String (Binding.Display)
                  else ""),
               Query          => Query);
            if Score > 0 then
               Score := Score + Relevance_Boost (D.Id);
            end if;
         end;

         if Score > 0 then
            declare
               A : constant Editor.Commands.Command_Availability :=
                 Editor.Executor.Availability.Command_Availability (S, D.Id);
            begin
               declare
                  Binding : constant Editor.Keybindings.Command_Keybinding_Info :=
                    Editor.Keybindings.Primary_Binding_For_Command (D.Id);
               begin
                  declare
                     Candidate : constant Editor.Commands.Command_Palette_Candidate :=
                        (Id                 => D.Id,
                        Label              => D.Name,
                        Description        => D.Description,
                        Category           => D.Category,
                        Category_Label     => To_Unbounded_String
                          (Editor.Commands.Discoverability_Category_Label (D.Id)),
                        Available          => Editor.Commands.Is_Available (A),
                        Reason             => A.Reason,
                        Has_Keybinding     => D.Bindable and then Binding.Has_Binding,
                        Keybinding_Display => Binding.Display,
                        Reference_Summary  => D.Summary,
                        Family             => D.Family,
                        Effect_Classification => D.Effect_Classification,
                        Match_Score        => Score,
                        Registry_Order     => Editor.Command_Palette.Descriptor_Registry_Order (D.Id));
                  begin
                     if Editor.Command_Palette.Candidate_Passes_Transient_Filters
                          (Candidate)
                     then
                        Editor.Command_Palette.Set_Command_State_Context
                          (D.Id, State_Context_For (D.Id));
                        Result.Append (Candidate);
                     end if;
                  end;
               end;
            end;
         end if;
      end loop;

      Editor.Command_Palette.Sort_Candidates (Result);
   end Command_Palette_Candidates;


end Editor.Executor.Command_Palette_Projection;
