with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Build_Diagnostics;
with Editor.Commands;
with Editor.Diagnostics_Review_UX;
with Editor.External_Producers;
with Editor.Executor;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Messages;
with Editor.Producer_Contracts;
with Editor.State;
with Editor.Workspace_Persistence;

package body Editor.Diagnostics_Review_UX.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;

   overriding function Name
     (T : Diagnostics_Review_UX_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Diagnostics_Review_UX.Tests");
   end Name;

   function Contains (Text, Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Pattern) /= 0;
   end Contains;

   procedure Seed_Rows (S : in out Editor.State.State_Type) is
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "compile failure",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message       => "manual warning",
         Source_Label  => "notes.adb",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => False);
   end Seed_Rows;

   procedure Test_Display_Labels_Counts_And_Producer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Counts : Editor.Feature_Diagnostics.Diagnostics_Severity_Counts;
   begin
      Seed_Rows (S);
      Counts := Editor.Feature_Diagnostics.Count_By_Severity (S.Feature_Diagnostics);

      Assert (Counts.Errors = 1 and then Counts.Warnings = 1,
              "severity counts classify Diagnostics-owned rows");
      Assert (Contains (Editor.Feature_Diagnostics.Header_Text (S.Feature_Diagnostics),
                        "Errors: 1"),
              "header exposes Problems-style severity totals");
      Assert (Contains (Editor.Feature_Diagnostics.Item_Display_Label
                          (S.Feature_Diagnostics, 1),
                        "External Producer"),
              "row label includes producer label");
      Assert (Editor.Diagnostics_Review_UX.
                Assert_Diagnostics_Display_Labels_Are_User_Readable (S),
              "display labels are self-contained and user-readable");
   end Test_Display_Labels_Counts_And_Producer;

   procedure Test_Filters_Do_Not_Delete_And_Clear_Build_Is_Targeted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Removed : Natural;
   begin
      Seed_Rows (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "build failure",
         Source_Label  => "Build / gprbuild",
         Source_Kind    => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target     => False,
         Build_Produced => True);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Info,
         Message       => "manual build note",
         Source_Label  => "build notes",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => False);

      Assert (Editor.Diagnostics_Review_UX.
                Assert_Diagnostics_Filter_Does_Not_Delete_Rows (S),
              "filtering is projection-only and does not delete rows");
      Removed := Editor.Feature_Diagnostics.Clear_Build_Diagnostics
        (S.Feature_Diagnostics);
      Assert (Removed = 1,
              "clear-build helper removes only rows classified as build-produced");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 3,
              "non-build Diagnostics rows remain after clear-build even when labels mention build");
   end Test_Filters_Do_Not_Delete_And_Clear_Build_Is_Targeted;

   procedure Test_Source_Less_Targets_Fail_Clearly
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Seed_Rows (S);
      Assert (Editor.Feature_Diagnostics.Item_Target_Unavailable_Label
                (S.Feature_Diagnostics, 1) = "Target file missing or unavailable",
              "diagnostics with a source label but no target expose a missing/unavailable target label");
      Assert (Contains (Editor.Feature_Diagnostics.Item_Source_Display_Label
                          (S.Feature_Diagnostics, 1),
                        "Target file missing or unavailable"),
              "source display labels distinguish missing/unavailable targets from true source-less rows");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Info,
         Message       => "general diagnostic",
         Source_Label  => "",
         Source_Kind   => Editor.Feature_Diagnostics.Unknown_Diagnostic_Source,
         Has_Target    => False);
      Assert (Editor.Feature_Diagnostics.Item_Target_Unavailable_Label
                (S.Feature_Diagnostics, 3) = "No source target",
              "true source-less diagnostics keep the explicit no-source-target label");
      Assert (Editor.Diagnostics_Review_UX.
                Assert_Diagnostics_Source_Less_Rows_Do_Not_Navigate_Silently (S),
              "source-less rows are not silently navigable");
   end Test_Source_Less_Targets_Fail_Clearly;



   procedure Test_Source_Filter_Grouping_And_Build_Filter_Are_Projection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Seed_Rows (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "build failure",
         Source_Label  => "Build / gprbuild",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => False,
         Build_Produced => True);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Info,
         Message       => "manual build note",
         Source_Label  => "build notes",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => False);

      Assert (Editor.Feature_Diagnostics.File_Group_Count (S.Feature_Diagnostics) >= 2,
              "diagnostics expose projection-only source/file groups");
      Assert (Contains (Editor.Feature_Diagnostics.File_Group_Label
                          (S.Feature_Diagnostics, 1),
                        "diagnostics"),
              "diagnostic file group labels include counts");
      Assert (Editor.Diagnostics_Review_UX.
                Assert_Diagnostics_Source_Filter_Does_Not_Delete_Rows (S),
              "source label filtering is projection-only");
      Assert (Editor.Diagnostics_Review_UX.
                Assert_Diagnostics_File_Grouping_Is_Projection_Only (S),
              "file grouping is derived projection state only");
      Editor.Feature_Diagnostics.Filter_Build_Produced (S.Feature_Diagnostics);
      declare
         Text : constant String := Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics);
      begin
         Assert (Text'Length = 0,
                 "build producer filtering does not rely on source/message text");
      end;
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics) = 1,
              "build producer filtering uses explicit producer classification and ignores manual labels mentioning build");
   end Test_Source_Filter_Grouping_And_Build_Filter_Are_Projection_Only;


   procedure Test_File_Group_Labels_Distinguish_Missing_Targets_From_Source_Less
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Saw_Missing_Target_Group : Boolean := False;
      Saw_Source_Less_Group    : Boolean := False;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "missing source file",
         Source_Label => "src/missing.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "tool-level warning",
         Source_Label => "",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      for I in 1 .. Editor.Feature_Diagnostics.File_Group_Count (S.Feature_Diagnostics) loop
         declare
            Label : constant String :=
              Editor.Feature_Diagnostics.File_Group_Label (S.Feature_Diagnostics, I);
         begin
            if Contains (Label, "src/missing.adb") then
               Assert (Contains (Label, "Target file missing or unavailable"),
                       "source-labelled non-target diagnostics are grouped as missing/unavailable targets");
               Assert (not Contains (Label, "source-less"),
                       "source-labelled missing targets are not called source-less in group labels");
               Saw_Missing_Target_Group := True;
            elsif Contains (Label, "No source target") then
               Saw_Source_Less_Group := True;
            end if;
         end;
      end loop;

      Assert (Saw_Missing_Target_Group,
              "file grouping exposes the missing-target diagnostic group");
      Assert (Saw_Source_Less_Group,
              "file grouping keeps a separate true source-less diagnostic group");
   end Test_File_Group_Labels_Distinguish_Missing_Targets_From_Source_Less;


   procedure Test_File_Group_Source_Less_Metadata_Distinguishes_Missing_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Groups : Editor.Feature_Diagnostics.Diagnostics_File_Group_Vectors.Vector;
      Saw_Missing_Target_Group : Boolean := False;
      Saw_Source_Less_Group    : Boolean := False;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "missing source file",
         Source_Label => "src/missing.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "tool-level warning",
         Source_Label => "",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      Groups := Editor.Feature_Diagnostics.Visible_File_Groups (S.Feature_Diagnostics);

      Assert (Natural (Groups.Length) = 2,
              "test precondition: missing-target and source-less rows produce two groups");

      if not Groups.Is_Empty then
         for I in Groups.First_Index .. Groups.Last_Index loop
            declare
               Group : constant Editor.Feature_Diagnostics.Diagnostics_File_Group :=
                 Groups.Element (I);
               Label : constant String := To_String (Group.Label);
            begin
               if Contains (Label, "src/missing.adb") then
                  Assert (not Group.Source_Less,
                          "source-labelled missing targets are not marked source-less in group metadata");
                  Saw_Missing_Target_Group := True;
               elsif Label = "No source target" then
                  Assert (Group.Source_Less,
                          "true source-less diagnostics retain source-less group metadata");
                  Saw_Source_Less_Group := True;
               end if;
            end;
         end loop;
      end if;

      Assert (Saw_Missing_Target_Group,
              "missing-target group metadata is observable");
      Assert (Saw_Source_Less_Group,
              "source-less group metadata is observable");
   end Test_File_Group_Source_Less_Metadata_Distinguishes_Missing_Targets;

   procedure Test_Filter_And_Clear_Build_Commands_Are_Descriptor_Backed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert (Editor.Commands.Has_Descriptor
                (Editor.Commands.Command_Diagnostics_Filter_Errors),
              "filter-errors command has a descriptor");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Diagnostics_Filter_Errors) =
              "diagnostics.filter-errors",
              "filter-errors uses the canonical Phase 557 stable name");
      Assert (Editor.Commands.Has_Descriptor
                (Editor.Commands.Command_Diagnostics_Filter_Source),
              "filter-source command has a descriptor");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Diagnostics_Filter_Source) =
              "diagnostics.filter-source",
              "filter-source uses a canonical no-payload stable name");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("diagnostics.clear-build", Found);
      Assert (Found and then Id = Editor.Commands.Command_Diagnostics_Clear_Build,
              "clear-build stable name resolves to the Diagnostics command");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Diagnostics_Clear_Build).Category =
              Editor.Commands.Panel_Category,
              "clear-build is routed as a panel/Diagnostics command");
   end Test_Filter_And_Clear_Build_Commands_Are_Descriptor_Backed;

   procedure Test_Stale_Diagnostic_Label_Is_Transient_And_User_Readable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "old compile failure",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 42,
         Target_Line   => 12,
         Target_Column => 7);
      Assert (not Editor.Feature_Diagnostics.Item_Is_Stale (D, 1),
              "new diagnostics are not stale by default");
      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Buffer_Stale (D, 42);
      Assert (Editor.Feature_Diagnostics.Item_Is_Stale (D, 1),
              "editing the target buffer can mark diagnostics stale");
      Assert (Contains (Editor.Feature_Diagnostics.Item_Display_Label (D, 1),
                        "stale"),
              "stale diagnostics expose a visible marker");
      Assert (Editor.Feature_Diagnostics.Item_Stale_Label (D, 1) =
              "Stale diagnostic",
              "stale label is deterministic and user-readable");
   end Test_Stale_Diagnostic_Label_Is_Transient_And_User_Readable;




   procedure Test_Line_Only_Diagnostic_Target_Is_Valid_And_Labelled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "line only compile failure",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 77,
         Target_Line   => 9,
         Target_Column => 0);

      Assert (Editor.Feature_Diagnostics.Item_Source_Display_Label (D, 1) =
              "src/main.adb:9",
              "line-only diagnostics display a line label without a fake column zero");
      Assert (Editor.Feature_Diagnostics.Validate_Diagnostic_Target
                (D, 1, 77),
              "line-only diagnostics are valid targets and navigate to line start by policy");
      Assert (Editor.Feature_Diagnostics.Item_Target_Unavailable_Label (D, 1) =
              "",
              "line-only diagnostics are not reported as unavailable merely because column is absent");
   end Test_Line_Only_Diagnostic_Target_Is_Valid_And_Labelled;

   procedure Test_Diagnostic_Edit_Metadata_Is_Validated_And_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Long_Replacement : constant String
        (1 .. Editor.Feature_Diagnostics.Max_Diagnostic_Message_Text_Length + 10) :=
          (others => 'x');
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "editable diagnostic",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 77,
         Target_Line   => 9,
         Target_Column => 4,
         Has_Edit          => True,
         Edit_Start_Line   => 9,
         Edit_Start_Column => 8,
         Edit_End_Line     => 9,
         Edit_End_Column   => 8,
         Replacement_Text  => Long_Replacement);

      Assert (Editor.Feature_Diagnostics.Item_Has_Edit (D, 1),
              "valid diagnostic edit metadata is retained");
      Assert
        (Editor.Feature_Diagnostics.Item_Edit_Start_Line (D, 1) = 9
         and then Editor.Feature_Diagnostics.Item_Edit_Start_Column (D, 1) = 8
         and then Editor.Feature_Diagnostics.Item_Edit_End_Line (D, 1) = 9
         and then Editor.Feature_Diagnostics.Item_Edit_End_Column (D, 1) = 8,
         "valid diagnostic edit span is retained");
      Assert
        (Editor.Feature_Diagnostics.Item_Replacement_Text (D, 1)'Length =
         Editor.Feature_Diagnostics.Max_Diagnostic_Message_Text_Length,
         "diagnostic replacement text is bounded at ingestion");
      declare
         Panel : Editor.Feature_Panel.Feature_Panel_State;
      begin
         Editor.Feature_Diagnostics.Project_Rows (D, Panel);
         Assert
           (Contains (Editor.Feature_Panel.Row_Detail (Panel, 1),
                      "action: Apply edit"),
            "diagnostic projection exposes executable edit action metadata");
      end;

      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "edit without target",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => False,
         Has_Edit      => True,
         Edit_Start_Line   => 1,
         Edit_Start_Column => 1,
         Edit_End_Line     => 1,
         Edit_End_Column   => 1,
         Replacement_Text  => ";");
      Assert (not Editor.Feature_Diagnostics.Item_Has_Edit (D, 2),
              "diagnostic edit metadata is dropped when the row has no target");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "invalid edit span",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 77,
         Target_Line   => 9,
         Target_Column => 4,
         Has_Edit          => True,
         Edit_Start_Line   => 9,
         Edit_Start_Column => 8,
         Edit_End_Line     => 9,
         Edit_End_Column   => 7,
         Replacement_Text  => ";");
      Assert (not Editor.Feature_Diagnostics.Item_Has_Edit (D, 3),
              "diagnostic edit metadata is dropped when the edit span is invalid");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message       => "multi-line edit",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 77,
         Target_Line   => 10,
         Target_Column => 1,
         Has_Edit          => True,
         Edit_Start_Line   => 10,
         Edit_Start_Column => 1,
         Edit_End_Line     => 12,
         Edit_End_Column   => 4,
         Replacement_Text  => "begin" & ASCII.LF & "   null;" & ASCII.LF & "end;");
      Assert (Editor.Feature_Diagnostics.Item_Has_Edit (D, 4),
              "multi-line diagnostic edit metadata is retained");
      Assert
        (Editor.Feature_Diagnostics.Item_Edit_Start_Line (D, 4) = 10
         and then Editor.Feature_Diagnostics.Item_Edit_Start_Column (D, 4) = 1
         and then Editor.Feature_Diagnostics.Item_Edit_End_Line (D, 4) = 12
         and then Editor.Feature_Diagnostics.Item_Edit_End_Column (D, 4) = 4,
         "multi-line diagnostic edit span is retained");
      Assert
        (Editor.Feature_Diagnostics.Item_Replacement_Text (D, 4) =
         "begin" & ASCII.LF & "   null;" & ASCII.LF & "end;",
         "multi-line diagnostic replacement text is retained");
   end Test_Diagnostic_Edit_Metadata_Is_Validated_And_Bounded;


   procedure Test_External_Producer_Preserves_Line_Only_And_Partial_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Token  : Natural;
      Item   : Editor.External_Producers.External_Diagnostic_Record;
      Result : Editor.Producer_Contracts.Producer_Result;
   begin
      Editor.State.Init (S);
      Token := S.Active_Buffer_Token;

      Item :=
        (Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => To_Unbounded_String ("line-only external diagnostic"),
         Source_Label  => To_Unbounded_String ("src/main.adb"),
         Has_Target    => True,
         Target_Buffer => Token,
         Target_Line   => 1,
         Target_Column => 0,
         Has_Edit          => False,
         Edit_Start_Line   => 0,
         Edit_Start_Column => 0,
         Edit_End_Line     => 0,
         Edit_End_Column   => 0,
         Replacement_Text  => Null_Unbounded_String);
      Result := Editor.External_Producers.Ingest_Diagnostic_Record
        (S,
         Editor.External_Producers.Build_Compiler_Diagnostics_Producer_Source,
         Item);

      Assert (Result.Row_Accepted,
              "line-only external diagnostic is accepted");
      Assert (Result.Target_Kept,
              "line-only target metadata is kept as navigable line-start metadata");
      Assert (Editor.Feature_Diagnostics.Item_Has_Target
                (S.Feature_Diagnostics, 1),
              "line-only external target remains navigable through Diagnostics");
      Assert (Editor.Feature_Diagnostics.Item_Source_Display_Label
                (S.Feature_Diagnostics, 1) = "src/main.adb:1",
              "line-only external target displays without a fake column zero");

      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Item :=
        (Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => To_Unbounded_String ("missing-line external diagnostic"),
         Source_Label  => To_Unbounded_String ("src/main.adb"),
         Has_Target    => True,
         Target_Buffer => Token,
         Target_Line   => 0,
         Target_Column => 0,
         Has_Edit          => False,
         Edit_Start_Line   => 0,
         Edit_Start_Column => 0,
         Edit_End_Line     => 0,
         Edit_End_Column   => 0,
         Replacement_Text  => Null_Unbounded_String);
      Result := Editor.External_Producers.Ingest_Diagnostic_Record
        (S,
         Editor.External_Producers.Build_Compiler_Diagnostics_Producer_Source,
         Item);

      Assert (Result.Row_Accepted,
              "partial external diagnostic with known buffer is accepted for review");
      Assert (not Result.Target_Kept,
              "missing-line external target is retained but not reported as navigable");
      Assert (not Editor.Feature_Diagnostics.Item_Has_Target
                (S.Feature_Diagnostics, 1),
              "missing-line external target remains non-navigable");
      Assert (Editor.Feature_Diagnostics.Item_Target_Buffer
                (S.Feature_Diagnostics, 1) = Token,
              "missing-line external target preserves known buffer metadata");
      Assert (Editor.Feature_Diagnostics.Item_Target_Unavailable_Label
                (S.Feature_Diagnostics, 1) = "Target line unavailable",
              "missing-line external target exposes the precise review failure");
   end Test_External_Producer_Preserves_Line_Only_And_Partial_Target_Metadata;


   procedure Test_External_Producer_Preserves_Invalid_Target_Position_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Token  : Natural;
      Item   : Editor.External_Producers.External_Diagnostic_Record;
      Result : Editor.Producer_Contracts.Producer_Result;
      A      : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Token := S.Active_Buffer_Token;

      Item :=
        (Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => To_Unbounded_String ("out-of-range external diagnostic"),
         Source_Label  => To_Unbounded_String ("src/main.adb"),
         Has_Target    => True,
         Target_Buffer => Token,
         Target_Line   => 999,
         Target_Column => 1,
         Has_Edit          => False,
         Edit_Start_Line   => 0,
         Edit_Start_Column => 0,
         Edit_End_Line     => 0,
         Edit_End_Column   => 0,
         Replacement_Text  => Null_Unbounded_String);
      Result := Editor.External_Producers.Ingest_Diagnostic_Record
        (S,
         Editor.External_Producers.Build_Compiler_Diagnostics_Producer_Source,
         Item);

      Assert (Result.Row_Accepted,
              "external diagnostic with an invalid retained target is accepted for review");
      Assert (not Result.Target_Kept,
              "out-of-range external target is not reported as navigable by ingestion");
      Assert (Editor.Feature_Diagnostics.Item_Has_Target
                (S.Feature_Diagnostics, 1),
              "invalid source positions retain target metadata for open-selected validation");
      Assert (Editor.Feature_Diagnostics.Item_Target_Buffer
                (S.Feature_Diagnostics, 1) = Token,
              "invalid external target preserves the original buffer token");
      Assert (Editor.Feature_Diagnostics.Item_Target_Line
                (S.Feature_Diagnostics, 1) = 999,
              "invalid external target preserves the original out-of-range line");
      Assert (Editor.Feature_Diagnostics.Item_Source_Display_Label
                (S.Feature_Diagnostics, 1) = "src/main.adb:999:1",
              "invalid external target remains source-positioned in the review label");

      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);

      Assert (not Editor.Commands.Is_Available (A),
              "open-selected is unavailable before routing for out-of-range retained targets");
      Assert (Editor.Commands.Unavailable_Reason (A) =
              "Diagnostic target line is outside the buffer",
              "open-selected reports the retained line as out of range, not missing/source-less");
   end Test_External_Producer_Preserves_Invalid_Target_Position_Metadata;


   procedure Test_Edit_Marks_Targeted_Diagnostics_Stale_Not_Cleared
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Token : Natural;
   begin
      Editor.State.Init (S);
      Token := S.Active_Buffer_Token;

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "compile failure before edit",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => Token,
         Target_Line   => 1,
         Target_Column => 1);

      Editor.State.Rebuild_After_Buffer_Change (S);

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "ordinary edits retain Diagnostics-owned rows for review");
      Assert (Editor.Feature_Diagnostics.Item_Is_Stale (S.Feature_Diagnostics, 1),
              "ordinary edits mark targeted diagnostics stale instead of clearing them");
      Assert (Editor.Diagnostics_Review_UX.
                Assert_Diagnostics_Edit_Marks_Stale_Rather_Than_Clears (S),
              "Phase 557 audit covers edit-to-stale diagnostics lifecycle");
   end Test_Edit_Marks_Targeted_Diagnostics_Stale_Not_Cleared;


   procedure Test_Open_Selected_Source_Less_Is_Unavailable_But_Clear_Selected_Remains_Available
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Open_Availability  : Editor.Commands.Command_Availability;
      Clear_Availability : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "source-less build failure",
         Source_Label  => "",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => False);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Open_Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);
      Clear_Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Clear_Selected);

      Assert (not Editor.Commands.Is_Available (Open_Availability),
              "open-selected is unavailable for selected source-less diagnostics");
      Assert (Editor.Commands.Unavailable_Reason (Open_Availability) =
              "Selected diagnostic has no source target.",
              "open-selected reports the precise source-less selected-row reason");
      Assert (Editor.Commands.Is_Available (Clear_Availability),
              "clear-selected remains available for selected source-less diagnostics");
   end Test_Open_Selected_Source_Less_Is_Unavailable_But_Clear_Selected_Remains_Available;


   procedure Test_Open_Selected_Missing_Target_Is_Distinct_From_Source_Less
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A     : Editor.Commands.Command_Availability;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
      Before_Count : Natural;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "missing target file",
         Source_Label  => "src/missing.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => False);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);
      Assert (not Editor.Commands.Is_Available (A),
              "open-selected is unavailable for source-labelled missing targets");
      Assert (Editor.Commands.Unavailable_Reason (A) =
              "Target no longer exists.",
              "source-labelled missing target uses shared missing-target wording");

      Before_Count := Editor.Messages.Count (S.Messages);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);

      Assert (Editor.Messages.Count (S.Messages) = Before_Count + 1,
              "missing target activation emits one precise primary message");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
              "Target no longer exists.",
              "missing target activation reports shared missing-target wording");
   end Test_Open_Selected_Missing_Target_Is_Distinct_From_Source_Less;


   procedure Test_Open_Selected_Known_Missing_Buffer_Is_Unavailable_Pre_Route
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A     : Editor.Commands.Command_Availability;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "stale target buffer",
         Source_Label  => "src/stale.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 999_999,
         Target_Line   => 1,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);

      Assert (not Editor.Commands.Is_Available (A),
              "open-selected is unavailable before routing for known missing target buffers");
      Assert (Editor.Commands.Unavailable_Reason (A) =
              "Target no longer exists.",
              "availability reports the same shared missing-target reason as activation");
   end Test_Open_Selected_Known_Missing_Buffer_Is_Unavailable_Pre_Route;


   procedure Test_Clear_Build_Availability_Uses_Producer_Predicate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A     : Editor.Commands.Command_Availability;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Info,
         Message       => "manual build note",
         Source_Label  => "build notes",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => False);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Clear_Build);
      Assert (not Editor.Commands.Is_Available (A),
              "clear-build is unavailable when no row is actually build-produced");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No build diagnostics",
              "clear-build exposes a precise no-build-diagnostics reason");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "build failure",
         Source_Label   => "Build / gprbuild",
         Source_Kind    => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target     => False,
         Build_Produced => True);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Clear_Build);
      Assert (Editor.Commands.Is_Available (A),
              "clear-build becomes available when explicit producer classification finds build diagnostics");
   end Test_Clear_Build_Availability_Uses_Producer_Predicate;


   procedure Test_External_Build_Producer_Classifies_Explicitly
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Item : Editor.External_Producers.External_Diagnostic_Record :=
        (Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => To_Unbounded_String ("explicit producer row"),
         Source_Label  => To_Unbounded_String ("src/main.adb"),
         Has_Target    => False,
         Target_Buffer => Editor.Feature_Diagnostics.No_Buffer,
         Target_Line   => 0,
         Target_Column => 0,
         Has_Edit          => False,
         Edit_Start_Line   => 0,
         Edit_Start_Column => 0,
         Edit_End_Line     => 0,
         Edit_End_Column   => 0,
         Replacement_Text  => Null_Unbounded_String);
      Result : Editor.Producer_Contracts.Producer_Result;
   begin
      Result := Editor.External_Producers.Ingest_Diagnostic_Record
        (S,
         Editor.External_Producers.Build_External_Producer_Source
           (Editor.External_Producers.Build_Diagnostics_Producer),
         Item);
      Assert (Result.Row_Accepted,
              "build producer diagnostic is accepted into Diagnostics");
      Assert (Editor.Feature_Diagnostics.Item_Is_Build_Produced
                (S.Feature_Diagnostics, 1),
              "build producer identity marks the row as build-produced even without a build label");
      Assert (Editor.Feature_Diagnostics.Producer_Label_For_Display
                (S.Feature_Diagnostics, 1) = "Build",
              "build-produced rows display the Build producer label");

      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Item.Source_Label := To_Unbounded_String ("build-looking compiler label");
      Result := Editor.External_Producers.Ingest_Diagnostic_Record
        (S,
         Editor.External_Producers.Build_Compiler_Diagnostics_Producer_Source,
         Item);
      Assert (Result.Row_Accepted,
              "compiler producer diagnostic is accepted into Diagnostics");
      Assert (not Editor.Feature_Diagnostics.Item_Is_Build_Produced
                (S.Feature_Diagnostics, 1),
              "compiler producer rows are not build-produced merely because a label mentions build");
   end Test_External_Build_Producer_Classifies_Explicitly;

   procedure Test_Note_And_Unknown_Severities_Are_First_Class
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D      : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Counts : Editor.Feature_Diagnostics.Diagnostics_Severity_Counts;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Note,
         Message      => "compiler note",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Unknown,
         Message      => "unclassified compiler output",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      Counts := Editor.Feature_Diagnostics.Count_By_Severity (D);
      Assert (Counts.Notes = 1 and then Counts.Unknown = 1 and then Counts.Total = 2,
              "note and unknown severities have first-class count buckets");
      Assert (Contains (Editor.Feature_Diagnostics.Count_Label (Counts), "Notes: 1")
              and then Contains (Editor.Feature_Diagnostics.Count_Label (Counts), "Unknown: 1"),
              "Problems count label displays note and unknown totals");
      Assert (Contains (Editor.Feature_Diagnostics.Item_Display_Label (D, 1), "note")
              and then Contains (Editor.Feature_Diagnostics.Item_Display_Label (D, 2), "unknown"),
              "row labels expose note and unknown severities");

      Editor.Feature_Diagnostics.Filter_Info_And_Notes_Only (D);
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "info/notes filter includes notes but excludes unknown rows");
   end Test_Note_And_Unknown_Severities_Are_First_Class;


   procedure Test_Source_Label_Filter_Does_Not_Match_Message_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "src/main.adb is mentioned only in the message",
         Source_Label => "generated/out.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "real source match",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      Editor.Feature_Diagnostics.Filter_Source_Label (D, "src/main.adb");
      Assert (Editor.Feature_Diagnostics.Row_Count (D) = 2,
              "source filtering remains projection-only");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "source/file filter matches source labels, not incidental message text");
   end Test_Source_Label_Filter_Does_Not_Match_Message_Text;


   procedure Test_Source_Label_Filter_Does_Not_Match_Target_Status_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "missing target should not be a source-filter hit",
         Source_Label => "src/unavailable.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => True,
         Target_Buffer => Editor.Feature_Diagnostics.No_Buffer,
         Target_Line   => 12,
         Target_Column => 0);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "real missing path",
         Source_Label => "src/missing_name.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      Editor.Feature_Diagnostics.Filter_Source_Label (D, "missing");

      Assert (Editor.Feature_Diagnostics.Row_Count (D) = 2,
              "source filtering remains projection-only when status labels contain filter text");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "source/file filter matches source metadata, not target-status review text");
      Assert (Editor.Feature_Diagnostics.Item_Source_Label (D, 2) = "src/missing_name.adb",
              "the visible match is the row whose source label contains the source predicate");
   end Test_Source_Label_Filter_Does_Not_Match_Target_Status_Text;



   procedure Test_Selected_Source_Filter_Uses_Selected_Row_Without_Command_Payload
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "first source",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "second source",
         Source_Label => "src/other.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);

      Assert (Editor.Feature_Diagnostics.Selected_Diagnostic_Source_Filter_Label
                (S.Feature_Diagnostics, S.Feature_Panel) = "src/main.adb",
              "selected-row source filter label is derived from Diagnostics row identity");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Filter_Source);

      Assert (Editor.Feature_Diagnostics.Filter_Text (S.Feature_Diagnostics) = "",
              "source filter command does not smuggle a general text payload");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 2,
              "selected-source filter does not delete Diagnostics rows");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics) = 1,
              "selected-source filter narrows projection to the selected source label");
   end Test_Selected_Source_Filter_Uses_Selected_Row_Without_Command_Payload;



   procedure Test_Filter_Command_Availability_Reasons_Are_Precise
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A     : Editor.Commands.Command_Availability;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Filter_Errors);
      Assert (not Editor.Commands.Is_Available (A)
              and then Editor.Commands.Unavailable_Reason (A) = "No diagnostics.",
              "severity filters are unavailable with a precise no-diagnostics reason");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Clear_Filter);
      Assert (not Editor.Commands.Is_Available (A)
              and then Editor.Commands.Unavailable_Reason (A) = "No filter is active",
              "clear-filter is unavailable when no Diagnostics filter is active");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "manual warning",
         Source_Label => "notes.adb",
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target   => False);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Filter_Build);
      Assert (not Editor.Commands.Is_Available (A)
              and then Editor.Commands.Unavailable_Reason (A) = "No build diagnostics",
              "build filter is unavailable unless explicit build-produced rows exist");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Filter_Errors);
      Assert (Editor.Commands.Is_Available (A),
              "severity filters become available once Diagnostics rows exist");

      Editor.Feature_Diagnostics.Filter_Warnings_Only (S.Feature_Diagnostics);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Clear_Filter);
      Assert (Editor.Commands.Is_Available (A),
              "clear-filter becomes available once a transient Diagnostics filter is active");
   end Test_Filter_Command_Availability_Reasons_Are_Precise;


   procedure Test_Filter_Command_Execution_Guards_Mirror_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Before_Count : Natural;
      M            : Editor.Messages.Editor_Message;
      Found        : Boolean := False;
   begin
      Editor.State.Init (S);

      Before_Count := Editor.Messages.Count (S.Messages);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Clear_Filter);
      Assert (Editor.Messages.Count (S.Messages) = Before_Count + 1,
              "clear-filter execution reports one unavailable outcome when no filter is active");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
              Editor.Feature_Diagnostics.Message_No_Filter_Active,
              "clear-filter execution mirrors the no-filter availability reason");

      Editor.Messages.Clear (S.Messages);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Info,
         Message       => "manual build note",
         Source_Label  => "build notes",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => False);
      Before_Count := Editor.Messages.Count (S.Messages);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Filter_Build);

      Assert (Editor.Messages.Count (S.Messages) = Before_Count + 1,
              "build-filter execution reports one unavailable outcome without build-produced rows");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
              Editor.Feature_Diagnostics.Message_No_Build_Diagnostics,
              "build-filter execution mirrors the no-build-diagnostics availability reason");
      Assert (not Editor.Feature_Diagnostics.Filter_Active (S.Feature_Diagnostics),
              "failed build-filter execution does not leave a hidden build-only predicate active");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics) = 1,
              "manual rows whose labels mention build remain visible after rejected build filtering");
   end Test_Filter_Command_Execution_Guards_Mirror_Availability;

   procedure Test_Next_Previous_Are_Unavailable_When_Filter_Hides_All
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A     : Editor.Commands.Command_Availability;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "manual warning",
         Source_Label => "notes.adb",
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target   => False);

      Editor.Feature_Diagnostics.Filter_Errors_Only (S.Feature_Diagnostics);
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "the hidden warning remains Diagnostics-owned data");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics) = 0,
              "errors-only projection hides all rows when only warnings exist");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Select_Next);
      Assert (not Editor.Commands.Is_Available (A)
              and then Editor.Commands.Unavailable_Reason (A) = "No visible diagnostics",
              "next diagnostic is unavailable when filters hide every diagnostic");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Select_Previous);
      Assert (not Editor.Commands.Is_Available (A)
              and then Editor.Commands.Unavailable_Reason (A) = "No visible diagnostics",
              "previous diagnostic is unavailable when filters hide every diagnostic");

      Editor.Feature_Diagnostics.Clear_Filter (S.Feature_Diagnostics);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Select_Next);
      Assert (Editor.Commands.Is_Available (A),
              "next diagnostic becomes available again when the projection has a visible row");
   end Test_Next_Previous_Are_Unavailable_When_Filter_Hides_All;

   procedure Test_Next_Previous_Execution_Distinguishes_No_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Select_Next);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
              Editor.Feature_Diagnostics.Message_No_Diagnostics,
              "next diagnostic execution reports no diagnostics when row storage is empty");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Select_Previous);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
              Editor.Feature_Diagnostics.Message_No_Diagnostics,
              "previous diagnostic execution reports no diagnostics when row storage is empty");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "hidden warning",
         Source_Label => "notes.adb",
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Filter_Errors_Only (S.Feature_Diagnostics);

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Select_Next);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
              Editor.Feature_Diagnostics.Message_No_Visible_Diagnostic,
              "next diagnostic execution reports no visible diagnostics when filters hide stored rows");
   end Test_Next_Previous_Execution_Distinguishes_No_Diagnostics;

   procedure Test_Diagnostics_Open_Failure_Reports_One_Primary_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Before_Count : Natural;
      M            : Editor.Messages.Editor_Message;
      Found        : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "source-less diagnostic",
         Source_Label => "",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Before_Count := Editor.Messages.Count (S.Messages);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);

      Assert (Editor.Messages.Count (S.Messages) = Before_Count + 1,
              "failed Diagnostics row activation emits exactly one primary message");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
              Editor.Feature_Diagnostics.Message_No_Target,
              "the single failure message keeps the precise source-less target reason");
   end Test_Diagnostics_Open_Failure_Reports_One_Primary_Message;


   procedure Test_Diagnostics_Open_Failure_Normalizes_Partial_Target_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "line omitted by producer",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 42,
         Target_Line   => 0,
         Target_Column => 0);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
                "Target line is unavailable.",
              "missing-line Diagnostics activation uses the shared target-line sentence");

      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Messages.Clear (S.Messages);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "file missing",
         Source_Label  => "src/missing.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => Editor.Feature_Diagnostics.No_Buffer,
         Target_Line   => 15,
         Target_Column => 0);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
                "Target no longer exists.",
              "missing-file Diagnostics activation normalizes retained target labels into the shared missing-target sentence");
   end Test_Diagnostics_Open_Failure_Normalizes_Partial_Target_Messages;

   procedure Test_Filtered_Header_Exposes_Visible_Severity_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D      : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Counts : Editor.Feature_Diagnostics.Diagnostics_Severity_Counts;
      Header : Unbounded_String;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "compile failure",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "warning",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Note,
         Message      => "note",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      Editor.Feature_Diagnostics.Filter_Errors_Only (D);
      Counts := Editor.Feature_Diagnostics.Count_By_Severity (D);
      Header := To_Unbounded_String (Editor.Feature_Diagnostics.Header_Text (D));

      Assert (Counts.Total = 3 and then Counts.Visible = 1,
              "filtered count summary keeps total and visible counts distinct");
      Assert (Counts.Visible_Errors = 1
              and then Counts.Visible_Warnings = 0
              and then Counts.Visible_Notes = 0,
              "visible severity buckets update after applying a filter");
      Assert (Contains (To_String (Header), "Visible Errors: 1")
              and then Contains (To_String (Header), "Visible Warnings: 0")
              and then Contains (To_String (Header), "Total: 3"),
              "filtered Diagnostics header exposes visible severity counts and unfiltered totals");
   end Test_Filtered_Header_Exposes_Visible_Severity_Counts;




   procedure Test_Severity_Filter_Modes_Reset_Source_And_Producer_Filters
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "main error",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => False,
         Build_Produced => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "other error",
         Source_Label  => "src/other.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => False,
         Build_Produced => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message       => "build warning",
         Source_Label  => "src/build.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => False,
         Build_Produced => True);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message       => "manual warning",
         Source_Label  => "src/manual.adb",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => False,
         Build_Produced => False);

      Editor.Feature_Diagnostics.Filter_Source_Label (D, "src/main.adb");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "source filter starts from one selected source row");
      Editor.Feature_Diagnostics.Filter_Errors_Only (D);
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 2,
              "errors-only mode resets prior source/file filters instead of stacking them");

      Editor.Feature_Diagnostics.Filter_Build_Produced (D);
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "build-producer filter starts from only build-produced rows");
      Editor.Feature_Diagnostics.Filter_Warnings_Only (D);
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 2,
              "warnings-only mode resets prior build-producer filters instead of stacking them");
   end Test_Severity_Filter_Modes_Reset_Source_And_Producer_Filters;

   procedure Test_Persistence_Audit_Excludes_Filter_Selection_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary  : Unbounded_String;
   begin
      Seed_Rows (S);
      Editor.Feature_Diagnostics.Filter_Errors_Only (S.Feature_Diagnostics);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snapshot));

      Assert (Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) = 0,
              "workspace snapshot stores no Diagnostics review rows");
      Assert (not Contains (To_String (Summary), "diagnostics-filter")
              and then not Contains (To_String (Summary), "diagnostics-selection")
              and then not Contains (To_String (Summary), "diagnostics-projection")
              and then not Contains (To_String (Summary), "build-diagnostics"),
              "workspace snapshot summary excludes Diagnostics review filter/selection/projection/build state");
      Assert (Editor.Diagnostics_Review_UX.Assert_Diagnostics_Filter_Selection_Not_Persisted (S),
              "Phase 557 persistence audit is non-vacuous and excludes review state");
   end Test_Persistence_Audit_Excludes_Filter_Selection_Projection;


   procedure Test_Clear_Diagnostics_Resets_Transient_Filter_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "compile failure",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Filter_Errors_Only (S.Feature_Diagnostics);
      Assert (Editor.Feature_Diagnostics.Filter_Active (S.Feature_Diagnostics),
              "test precondition: Diagnostics filter is active before clear");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Diagnostics_Clear);

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "clear diagnostics removes Diagnostics-owned rows");
      Assert (not Editor.Feature_Diagnostics.Filter_Active (S.Feature_Diagnostics),
              "clear diagnostics also resets transient review filter state");
      Assert (Editor.Feature_Diagnostics.Header_Text (S.Feature_Diagnostics) = "No diagnostics.",
              "clear diagnostics returns the panel to the unfiltered no-diagnostics state");
   end Test_Clear_Diagnostics_Resets_Transient_Filter_State;


   procedure Test_Direct_Clear_Diagnostics_Resets_Filter_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "compile failure",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Filter_Source_Label (D, "src/main.adb");
      Assert (Editor.Feature_Diagnostics.Filter_Active (D),
              "test precondition: direct Diagnostics helper has an active source filter");

      Editor.Feature_Diagnostics.Clear_Diagnostics (D);

      Assert (Editor.Feature_Diagnostics.Row_Count (D) = 0,
              "direct clear removes all Diagnostics-owned rows");
      Assert (not Editor.Feature_Diagnostics.Filter_Active (D),
              "direct clear also resets Diagnostics-owned transient filter predicates");
      Assert (Editor.Feature_Diagnostics.Header_Text (D) = "No diagnostics.",
              "direct clear leaves no hidden filtered no-diagnostics state");
   end Test_Direct_Clear_Diagnostics_Resets_Filter_State;

   procedure Test_Clear_Build_Resets_Exhausted_Build_Only_Filter
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D       : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Removed : Natural;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity       => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message        => "build error",
         Source_Label   => "src/build.adb",
         Source_Kind    => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target     => False,
         Build_Produced => True);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity       => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message        => "manual warning",
         Source_Label   => "src/manual.adb",
         Source_Kind    => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target     => False,
         Build_Produced => False);

      Editor.Feature_Diagnostics.Filter_Build_Produced (D);
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "test precondition: build-only filter sees only build-produced rows");

      Removed := Editor.Feature_Diagnostics.Clear_Build_Diagnostics (D);

      Assert (Removed = 1,
              "clear-build removes the build-produced row");
      Assert (Editor.Feature_Diagnostics.Row_Count (D) = 1,
              "clear-build preserves non-build Diagnostics rows");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "clear-build drops the exhausted build-only predicate so preserved rows are visible");
      Assert (not Editor.Feature_Diagnostics.Filter_Active (D),
              "clear-build leaves no hidden build-only filter when no build diagnostics remain");
   end Test_Clear_Build_Resets_Exhausted_Build_Only_Filter;



   procedure Test_Targeted_Delete_Resets_Exhausted_Source_Filter
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D      : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Main_Id : Editor.Feature_Diagnostics.Diagnostic_Id;
      Removed : Boolean;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "main error",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "other warning",
         Source_Label => "src/other.adb",
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target   => False);
      Main_Id := Editor.Feature_Diagnostics.Item_Id (D, 1);

      Editor.Feature_Diagnostics.Filter_Source_Label (D, "src/main.adb");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "test precondition: source filter shows only the selected source row");

      Removed := Editor.Feature_Diagnostics.Clear_Diagnostic_By_Id (D, Main_Id);

      Assert (Removed,
              "targeted clear removes the selected Diagnostics-owned row");
      Assert (Editor.Feature_Diagnostics.Row_Count (D) = 1,
              "targeted clear preserves unrelated Diagnostics rows");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "targeted clear resets an exhausted source/file predicate so preserved rows remain visible");
      Assert (not Editor.Feature_Diagnostics.Filter_Active (D),
              "source/file predicate is not retained when no remaining row can match it");
   end Test_Targeted_Delete_Resets_Exhausted_Source_Filter;


   procedure Test_Visible_Projection_Orders_Diagnostics_By_Source_Line_Column
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message       => "late warning",
         Source_Label  => "src/z.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 1,
         Target_Line   => 9,
         Target_Column => 2);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message       => "a later warning",
         Source_Label  => "src/a.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 1,
         Target_Line   => 20,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message       => "a same-line warning",
         Source_Label  => "src/a.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 1,
         Target_Line   => 3,
         Target_Column => 4);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "a same-line error",
         Source_Label  => "src/a.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 1,
         Target_Line   => 3,
         Target_Column => 4);

      Editor.Feature_Diagnostics.Project_Rows (D, P);

      Assert (Editor.Feature_Panel.Row_Count (P) = 4,
              "visible Diagnostics projection contains only the four diagnostic rows");
      Assert (Contains (Editor.Feature_Panel.Row_Label (P, 1), "src/a.adb:3:4")
                and then Contains (Editor.Feature_Panel.Row_Label (P, 1), "error"),
              "same-source same-position errors sort before warnings");
      Assert (Contains (Editor.Feature_Panel.Row_Label (P, 2), "src/a.adb:3:4")
                and then Contains (Editor.Feature_Panel.Row_Label (P, 2), "warning"),
              "same-source same-position warning follows the error");
      Assert (Contains (Editor.Feature_Panel.Row_Label (P, 3), "src/a.adb:20:1"),
              "diagnostics within a source sort by line and column");
      Assert (Contains (Editor.Feature_Panel.Row_Label (P, 4), "src/z.adb:9:2"),
              "diagnostics sort by source label before later source groups");
   end Test_Visible_Projection_Orders_Diagnostics_By_Source_Line_Column;



   procedure Test_Missing_Target_Line_Metadata_Is_Shown_And_Orders_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
   begin
      --  Both rows name the same source but cannot currently navigate because
      --  there is no known buffer.  Phase 557 still expects retained line
      --  metadata to be visible for triage and used by projection ordering.
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message       => "later missing file warning",
         Source_Label  => "src/missing.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => Editor.Feature_Diagnostics.No_Buffer,
         Target_Line   => 20,
         Target_Column => 0);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "earlier missing file error",
         Source_Label  => "src/missing.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => Editor.Feature_Diagnostics.No_Buffer,
         Target_Line   => 4,
         Target_Column => 0);

      Assert (not Editor.Feature_Diagnostics.Item_Has_Target (D, 1),
              "missing-file line metadata is retained without making the row navigable");
      Assert (Editor.Feature_Diagnostics.Item_Target_Line (D, 1) = 20,
              "missing-file diagnostics retain producer line metadata");
      Assert (Editor.Feature_Diagnostics.Item_Source_Display_Label (D, 1) =
                "src/missing.adb:20 — Target file missing",
              "missing-file source labels include retained line metadata and an explicit failure marker");

      Editor.Feature_Diagnostics.Project_Rows (D, P);
      Assert (Contains (Editor.Feature_Panel.Row_Label (P, 1), "src/missing.adb:4"),
              "non-navigable missing-file diagnostics still sort by retained line metadata");
      Assert (Contains (Editor.Feature_Panel.Row_Label (P, 2), "src/missing.adb:20"),
              "later missing-file diagnostics follow earlier retained-line diagnostics");
   end Test_Missing_Target_Line_Metadata_Is_Shown_And_Orders_Projection;


   procedure Test_Next_Previous_Diagnostics_Wrap_Visible_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => "first",
         Source_Label => "src/a.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "second",
         Source_Label => "src/b.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      Editor.Feature_Diagnostics.Project_Rows (D, P);
      Assert (Editor.Feature_Panel.Selected_Row (P) = 1,
              "diagnostics projection selects the first visible diagnostic");

      Editor.Feature_Diagnostics.Select_Previous_Diagnostic (D, P);
      Assert (Editor.Feature_Panel.Selected_Row (P) = 2,
              "previous diagnostic wraps from the first visible row to the last");

      Editor.Feature_Diagnostics.Select_Next_Diagnostic (D, P);
      Assert (Editor.Feature_Panel.Selected_Row (P) = 1,
              "next diagnostic wraps from the last visible row to the first");

      Editor.Feature_Diagnostics.Filter_Errors_Only (D);
      Editor.Feature_Diagnostics.Project_Rows (D, P);
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "test precondition: severity filter leaves one visible diagnostic row");

      Editor.Feature_Diagnostics.Select_Next_Diagnostic (D, P);
      Assert (Editor.Feature_Panel.Selected_Row (P) = 1,
              "next diagnostic remains on the only visible diagnostic row");
      Editor.Feature_Diagnostics.Select_Previous_Diagnostic (D, P);
      Assert (Editor.Feature_Panel.Selected_Row (P) = 1,
              "previous diagnostic remains on the only visible diagnostic row");
   end Test_Next_Previous_Diagnostics_Wrap_Visible_Projection;


   procedure Test_Clear_Selected_Reconciles_By_Visible_Projection_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Removed : Boolean;
   begin
      --  Insert rows in a different order than the Phase 557 visible
      --  Problems projection.  Projection order is a.adb, b.adb, z.adb;
      --  storage order is z.adb, a.adb, b.adb.
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "z last by projection",
         Source_Label  => "src/z.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 1,
         Target_Line   => 1,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "a first by projection",
         Source_Label  => "src/a.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 1,
         Target_Line   => 1,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "b middle by projection",
         Source_Label  => "src/b.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 1,
         Target_Line   => 1,
         Target_Column => 1);

      Editor.Feature_Diagnostics.Project_Rows (D, P);
      Assert (Editor.Feature_Panel.Row_Count (P) = 3,
              "test precondition: three visible diagnostics are projected");
      Assert (Contains (Editor.Feature_Panel.Row_Label (P, 3), "src/z.adb"),
              "test precondition: z.adb is last in visible projection");

      Editor.Feature_Panel.Select_Row (P, 3);
      Removed := Editor.Feature_Diagnostics.Clear_Selected_Diagnostic (D, P);

      Assert (Removed, "selected diagnostic is removed");
      Assert (Editor.Feature_Panel.Row_Count (P) = 2,
              "projection is refreshed after clearing selected diagnostic");
      Assert (Editor.Feature_Panel.Selected_Row (P) = 2,
              "clearing the last projected diagnostic selects the previous visible row");
      Assert (Contains (Editor.Feature_Panel.Row_Label (P, 2), "src/b.adb"),
              "selection reconciliation follows visible projection order, not storage order");
   end Test_Clear_Selected_Reconciles_By_Visible_Projection_Order;


   procedure Test_Diagnostic_Message_Text_Is_Bounded_At_Ingestion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Long_Message : constant String
        (1 .. Editor.Feature_Diagnostics.Max_Diagnostic_Message_Text_Length + 64) :=
        (others => 'x');
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message      => Long_Message,
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      Assert
        (Editor.Feature_Diagnostics.Diagnostic_Message_Text_Is_Bounded (D),
         "Diagnostics rows bound producer message text at ingestion time");
      Assert
        (Editor.Feature_Diagnostics.Item_Message (D, 1)'Length =
           Editor.Feature_Diagnostics.Max_Diagnostic_Message_Text_Length,
         "long Diagnostics messages are truncated to the review-surface limit");
      Assert
        (Contains (Editor.Feature_Diagnostics.Item_Message (D, 1), "..."),
         "truncated Diagnostics messages preserve an explicit truncation marker");
      Assert
        (Editor.Feature_Diagnostics.Item_Display_Label (D, 1)'Length <
           Long_Message'Length,
         "render labels do not retain unbounded raw diagnostic message text");
   end Test_Diagnostic_Message_Text_Is_Bounded_At_Ingestion;


   procedure Test_Diagnostic_Source_Label_Text_Is_Bounded_At_Ingestion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Long_Source : constant String
        (1 .. Editor.Feature_Diagnostics.Max_Diagnostic_Source_Label_Text_Length + 80) :=
        (others => 's');
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "bounded source label check",
         Source_Label => Long_Source,
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      Assert
        (Editor.Feature_Diagnostics.Diagnostic_Source_Label_Text_Is_Bounded (D),
         "Diagnostics rows bound producer source/path labels at ingestion time");
      Assert
        (Editor.Feature_Diagnostics.Item_Source_Label (D, 1)'Length =
           Editor.Feature_Diagnostics.Max_Diagnostic_Source_Label_Text_Length,
         "long Diagnostics source labels are truncated to the review-surface limit");
      Assert
        (Contains (Editor.Feature_Diagnostics.Item_Source_Label (D, 1), "..."),
         "truncated Diagnostics source labels preserve an explicit truncation marker");
      Assert
        (Editor.Feature_Diagnostics.Item_Display_Label (D, 1)'Length <
           Long_Source'Length + 80,
         "render labels do not retain unbounded raw diagnostic source text");
   end Test_Diagnostic_Source_Label_Text_Is_Bounded_At_Ingestion;


   procedure Test_Retention_Eviction_Resets_Exhausted_Source_And_Build_Filters
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Source_State : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Build_State  : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics loop
         Editor.Feature_Diagnostics.Add_Diagnostic
           (Source_State,
            Severity     => Editor.Feature_Diagnostics.Diagnostic_Error,
            Message      => "old source diagnostic",
            Source_Label => "src/old.adb",
            Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
            Has_Target   => False);
      end loop;

      Editor.Feature_Diagnostics.Filter_Source_Label (Source_State, "src/old.adb");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (Source_State) =
                Editor.Feature_Diagnostics.Max_Diagnostics,
              "test precondition: old-source filter initially matches all retained rows");

      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics loop
         Editor.Feature_Diagnostics.Add_Diagnostic
           (Source_State,
            Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
            Message      => "new source diagnostic",
            Source_Label => "src/new.adb",
            Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
            Has_Target   => False);
      end loop;

      Assert (Editor.Feature_Diagnostics.Row_Count (Source_State) =
                Editor.Feature_Diagnostics.Max_Diagnostics,
              "bounded retention keeps Diagnostics row storage capped");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (Source_State) =
                Editor.Feature_Diagnostics.Max_Diagnostics,
              "retention eviction resets an exhausted source/file predicate so preserved rows are visible");
      Assert (not Editor.Feature_Diagnostics.Filter_Active (Source_State),
              "retention eviction clears the exhausted source/file predicate instead of retaining hidden state");

      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics loop
         Editor.Feature_Diagnostics.Add_Diagnostic
           (Build_State,
            Severity       => Editor.Feature_Diagnostics.Diagnostic_Error,
            Message        => "build diagnostic",
            Source_Label   => "build.gpr",
            Source_Kind    => Editor.Feature_Diagnostics.External_Diagnostic_Source,
            Has_Target     => False,
            Build_Produced => True);
      end loop;

      Editor.Feature_Diagnostics.Filter_Build_Produced (Build_State);
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (Build_State) =
                Editor.Feature_Diagnostics.Max_Diagnostics,
              "test precondition: build-only filter initially matches retained rows");

      for I in 1 .. Editor.Feature_Diagnostics.Max_Diagnostics loop
         Editor.Feature_Diagnostics.Add_Diagnostic
           (Build_State,
            Severity       => Editor.Feature_Diagnostics.Diagnostic_Info,
            Message        => "external non-build diagnostic",
            Source_Label   => "tool.log",
            Source_Kind    => Editor.Feature_Diagnostics.External_Diagnostic_Source,
            Has_Target     => False,
            Build_Produced => False);
      end loop;

      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (Build_State) =
                Editor.Feature_Diagnostics.Max_Diagnostics,
              "retention eviction resets an exhausted build-only predicate so non-build rows are visible");
      Assert (not Editor.Feature_Diagnostics.Filter_Active (Build_State),
              "retention eviction clears the exhausted build-only predicate");
   end Test_Retention_Eviction_Resets_Exhausted_Source_And_Build_Filters;


   procedure Test_Phase_557_Coherence_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Diagnostics_Review_UX.Diagnostics_Review_UX_Result;
   begin
      Seed_Rows (S);
      Result := Editor.Diagnostics_Review_UX.Run_Diagnostics_Review_UX_Audit (S);
      Assert (Result.Coherent,
              "Phase 557 Diagnostics review UX audit is coherent"
              & " labels=" & Boolean'Image (Result.Rows_Have_Readable_Labels)
              & " msg_bound=" & Boolean'Image (Result.Row_Message_Text_Is_Bounded)
              & " src_bound=" & Boolean'Image (Result.Row_Source_Label_Text_Is_Bounded)
              & " counts=" & Boolean'Image (Result.Severity_Counts_Are_Useful)
              & " filters=" & Boolean'Image (Result.Filters_Are_Projection_Only)
              & " source_filter=" & Boolean'Image (Result.Source_Filter_Is_Projection_Only)
              & " groups=" & Boolean'Image (Result.File_Grouping_Is_Projection_Only)
              & " build_filter=" & Boolean'Image (Result.Build_Filter_Uses_Producer_Predicate)
              & " routes=" & Boolean'Image (Result.Navigation_Routes_Are_Diagnostics)
              & " missing=" & Boolean'Image (Result.Missing_Source_Targets_Are_Clear)
              & " stale=" & Boolean'Image (Result.Edit_Stale_Lifecycle_Is_Clear)
              & " build_boundary=" & Boolean'Image (Result.Build_Producer_Boundary_Is_Clear)
              & " build_ui=" & Boolean'Image (Result.Build_UI_Is_Scalar_Only)
              & " output=" & Boolean'Image (Result.Output_Details_Are_Output_Only)
              & " render=" & Boolean'Image (Result.Render_Is_Observational)
              & " commands=" & Boolean'Image (Result.Command_Frontdoors_Carry_No_Payload)
              & " persistence=" & Boolean'Image (Result.Persistence_Excludes_Review_State));
   end Test_Phase_557_Coherence_Audit;

   procedure Test_Partial_Target_With_Missing_Line_Is_Labelled_Clearly
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "line omitted by producer",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 42,
         Target_Line   => 0,
         Target_Column => 0);

      Assert (not Editor.Feature_Diagnostics.Item_Has_Target (D, 1),
              "partial target with missing line is not navigable");
      Assert (Editor.Feature_Diagnostics.Item_Target_Buffer (D, 1) = 42,
              "partial target preserves known buffer metadata for review labels");
      Assert (Editor.Feature_Diagnostics.Item_Target_Unavailable_Label (D, 1) =
                "Target line unavailable",
              "missing-line target is reported as line unavailable, not missing file");
      Assert (Contains (Editor.Feature_Diagnostics.Item_Source_Display_Label (D, 1),
                        "Target line unavailable"),
              "source display label exposes the line-unavailable state");
      Assert (Contains (Editor.Feature_Diagnostics.File_Group_Label (D, 1),
                        "Target line unavailable"),
              "file grouping preserves the line-unavailable distinction");

      Editor.Feature_Diagnostics.Project_Rows (D, P);
      Assert (Editor.Feature_Diagnostics.Selected_Diagnostic_Open_Unavailable_Reason
                (D, P) = "Diagnostic target line is unavailable",
              "open-selected availability reason distinguishes missing line from missing file");
   end Test_Partial_Target_With_Missing_Line_Is_Labelled_Clearly;


   procedure Test_Partial_Targets_Stale_And_Close_By_Known_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "line omitted by producer",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 42,
         Target_Line   => 0,
         Target_Column => 0);

      Assert (Editor.Feature_Diagnostics.Row_Count (D) = 1,
              "test precondition: partial target row is retained");
      Assert (not Editor.Feature_Diagnostics.Item_Has_Target (D, 1),
              "test precondition: missing-line partial target is non-navigable");
      Assert (Editor.Feature_Diagnostics.Item_Target_Buffer (D, 1) = 42,
              "test precondition: partial target keeps known buffer token");

      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Buffer_Stale (D, 42);
      Assert (Editor.Feature_Diagnostics.Item_Is_Stale (D, 1),
              "known-buffer partial target is marked stale on edits to that source buffer");
      Assert (Contains (Editor.Feature_Diagnostics.Item_Display_Label (D, 1), "stale"),
              "stale partial target exposes a readable stale marker");

      Editor.Feature_Diagnostics.Reset_Diagnostics_For_Buffer_Close (D, 42);
      Assert (Editor.Feature_Diagnostics.Row_Count (D) = 0,
              "buffer close removes diagnostics with known buffer metadata even when the target is not navigable");
   end Test_Partial_Targets_Stale_And_Close_By_Known_Buffer;

   procedure Test_Severity_Clear_Availability_And_Outcomes_Are_Precise
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A     : Editor.Commands.Command_Availability;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Clear_Errors);
      Assert (not Editor.Commands.Is_Available (A)
              and then Editor.Commands.Unavailable_Reason (A) = "No diagnostics.",
              "clear-errors reports no diagnostics when Diagnostics storage is empty");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message      => "warning only",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target   => False);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Clear_Errors);
      Assert (not Editor.Commands.Is_Available (A)
              and then Editor.Commands.Unavailable_Reason (A) = "No error diagnostics",
              "clear-errors distinguishes non-empty Diagnostics storage from absent error rows");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Clear_Warnings);
      Assert (Editor.Commands.Is_Available (A),
              "clear-warnings remains available when warning rows exist");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Clear_Info);
      Assert (not Editor.Commands.Is_Available (A)
              and then Editor.Commands.Unavailable_Reason (A) = "No info or note diagnostics",
              "clear-info distinguishes absent info/note rows from an empty Diagnostics model");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Note,
         Message      => "note only",
         Source_Label => "src/main.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Clear_Info);
      Assert (Editor.Commands.Is_Available (A),
              "clear-info is available for note diagnostics because Phase 557 triages info/notes together");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Clear_Info);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
              Editor.Feature_Diagnostics.Message_Info_Cleared,
              "clear-info reports the info/note clear outcome");
      Assert (not Editor.Feature_Diagnostics.Has_Info_Or_Note_Diagnostic
                (S.Feature_Diagnostics),
              "clear-info removes note diagnostics as informational diagnostics");
      Assert (Editor.Feature_Diagnostics.Has_Diagnostic_With_Severity
                (S.Feature_Diagnostics,
                 Editor.Feature_Diagnostics.Diagnostic_Warning),
              "clear-info does not remove warning diagnostics");
   end Test_Severity_Clear_Availability_And_Outcomes_Are_Precise;


   procedure Test_Info_Toggle_Hides_Notes_As_Informational_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Info,
         Message      => "info row",
         Source_Label => "src/info.adb",
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target   => False);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity     => Editor.Feature_Diagnostics.Diagnostic_Note,
         Message      => "note row",
         Source_Label => "src/note.adb",
         Source_Kind  => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target   => False);

      Assert (Editor.Feature_Diagnostics.Visible_Row_Count
                (S.Feature_Diagnostics) = 2,
              "test precondition: info and note diagnostics are both visible");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Toggle_Info);
      Assert (not Editor.Feature_Diagnostics.Severity_Is_Visible
                (S.Feature_Diagnostics,
                 Editor.Feature_Diagnostics.Diagnostic_Info),
              "toggle-info hides info diagnostics");
      Assert (not Editor.Feature_Diagnostics.Severity_Is_Visible
                (S.Feature_Diagnostics,
                 Editor.Feature_Diagnostics.Diagnostic_Note),
              "toggle-info also hides note diagnostics as part of the Phase 557 info/notes triage bucket");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count
                (S.Feature_Diagnostics) = 0,
              "notes are not left visible after informational diagnostics are hidden");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Diagnostics_Toggle_Info);
      Assert (Editor.Feature_Diagnostics.Severity_Is_Visible
                (S.Feature_Diagnostics,
                 Editor.Feature_Diagnostics.Diagnostic_Info)
              and then Editor.Feature_Diagnostics.Severity_Is_Visible
                (S.Feature_Diagnostics,
                 Editor.Feature_Diagnostics.Diagnostic_Note),
              "toggle-info restores the full info/notes triage bucket");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count
                (S.Feature_Diagnostics) = 2,
              "info and note rows become visible together again");
   end Test_Info_Toggle_Hides_Notes_As_Informational_Diagnostics;



   procedure Test_Unlabelled_Targeted_Diagnostics_Are_Not_Source_Less
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D      : Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Groups : Editor.Feature_Diagnostics.Diagnostics_File_Group_Vectors.Vector;
   begin
      Editor.Feature_Diagnostics.Add_Diagnostic
        (D,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "targeted diagnostic with omitted source label",
         Source_Label  => "",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => 42,
         Target_Line   => 7,
         Target_Column => 0);

      Assert (Editor.Feature_Diagnostics.Item_Target_Unavailable_Label (D, 1) = "",
              "a known line-only target is navigable even when the producer omitted the source label");
      Assert (Editor.Feature_Diagnostics.Item_Source_Display_Label (D, 1) = "Buffer 42:7",
              "unlabelled targeted diagnostics display a known target buffer/line instead of a bare line number");

      Groups := Editor.Feature_Diagnostics.Visible_File_Groups (D);
      Assert (Natural (Groups.Length) = 1,
              "unlabelled targeted diagnostics still produce a deterministic file/source group");
      Assert (To_String (Groups.Element (0).Label) = "Buffer 42",
              "unlabelled targeted diagnostics group by known target buffer, not source-less");
      Assert (not Groups.Element (0).Source_Less,
              "unlabelled targeted diagnostics are not marked as true source-less rows");

      Editor.Feature_Diagnostics.Filter_Source_Label (D, "Buffer 42");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 1,
              "source/file filtering can match the retained buffer identity for unlabelled targeted diagnostics");

      Editor.Feature_Diagnostics.Filter_Source_Label (D, "targeted");
      Assert (Editor.Feature_Diagnostics.Visible_Row_Count (D) = 0,
              "unlabelled target source filtering still does not match incidental diagnostic message text");
   end Test_Unlabelled_Targeted_Diagnostics_Are_Not_Source_Less;



   procedure Test_Phase578_Stale_Diagnostic_Target_Blocks_Real_Open_Route
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A     : Editor.Commands.Command_Availability;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "stale diagnostic target",
         Source_Label  => "src/renamed.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Registry_Token,
         Target_Line   => 1,
         Target_Column => 1);

      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Source_Path_Stale
        (S.Feature_Diagnostics, "src/renamed.adb", "src/moved.adb");
      Assert (Editor.Feature_Diagnostics.Item_Is_Stale (S.Feature_Diagnostics, 1),
              "source rename marks the diagnostic row stale in the owning Diagnostics store");

      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);
      Assert (not Editor.Commands.Is_Available (A),
              "stale diagnostic target is blocked before real navigation");
      Assert (Editor.Commands.Unavailable_Reason (A) =
              "Target is stale; refresh required.",
              "Diagnostics stale-target availability uses the Search-compatible canonical wording");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (M) =
              "Target is stale; refresh required.",
              "Diagnostics stale-target activation uses the same canonical primary outcome");
   end Test_Phase578_Stale_Diagnostic_Target_Blocks_Real_Open_Route;


   overriding procedure Register_Tests
     (T : in out Diagnostics_Review_UX_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Display_Labels_Counts_And_Producer'Access,
         "Phase 557 displays readable labels, severity counts, and producer labels");
      Register_Routine
        (T, Test_Filters_Do_Not_Delete_And_Clear_Build_Is_Targeted'Access,
         "Phase 557 filters are projection-only and clear-build is targeted");
      Register_Routine
        (T, Test_Source_Less_Targets_Fail_Clearly'Access,
         "Phase 557 source-less diagnostics fail clearly");
      Register_Routine
        (T, Test_Unlabelled_Targeted_Diagnostics_Are_Not_Source_Less'Access,
         "Phase 557 unlabelled targeted diagnostics are not grouped as source-less");
      Register_Routine
        (T, Test_Source_Filter_Grouping_And_Build_Filter_Are_Projection_Only'Access,
         "Phase 557 source filtering, grouping, and build producer filtering are projection-only");
      Register_Routine
        (T, Test_File_Group_Labels_Distinguish_Missing_Targets_From_Source_Less'Access,
         "Phase 557 file group labels distinguish missing targets from source-less diagnostics");
      Register_Routine
        (T, Test_File_Group_Source_Less_Metadata_Distinguishes_Missing_Targets'Access,
         "Phase 557 file group metadata distinguishes missing targets from true source-less diagnostics");
      Register_Routine
        (T, Test_Filter_And_Clear_Build_Commands_Are_Descriptor_Backed'Access,
         "Phase 557 explicit filter and clear-build commands are descriptor-backed");
      Register_Routine
        (T, Test_Stale_Diagnostic_Label_Is_Transient_And_User_Readable'Access,
         "Phase 557 stale diagnostics expose transient readable labels");
      Register_Routine
        (T, Test_Line_Only_Diagnostic_Target_Is_Valid_And_Labelled'Access,
         "Phase 557 line-only diagnostic targets navigate to line start");
      Register_Routine
        (T, Test_Diagnostic_Edit_Metadata_Is_Validated_And_Bounded'Access,
         "Diagnostics edit metadata is validated and bounded");
      Register_Routine
        (T, Test_External_Producer_Preserves_Line_Only_And_Partial_Target_Metadata'Access,
         "Phase 557 external producers preserve line-only and partial target metadata");
      Register_Routine
        (T, Test_External_Producer_Preserves_Invalid_Target_Position_Metadata'Access,
         "Phase 557 external producers preserve invalid target positions for review");
      Register_Routine
        (T, Test_Edit_Marks_Targeted_Diagnostics_Stale_Not_Cleared'Access,
         "Phase 557 ordinary edits mark targeted diagnostics stale instead of clearing them");
      Register_Routine
        (T, Test_Open_Selected_Source_Less_Is_Unavailable_But_Clear_Selected_Remains_Available'Access,
         "Phase 557 source-less selected diagnostics are unavailable only for navigation");
      Register_Routine
        (T, Test_Open_Selected_Missing_Target_Is_Distinct_From_Source_Less'Access,
         "Phase 557 source-labelled missing targets are distinct from source-less diagnostics");
      Register_Routine
        (T, Test_Open_Selected_Known_Missing_Buffer_Is_Unavailable_Pre_Route'Access,
         "Phase 557 open-selected availability rejects known missing target buffers");
      Register_Routine
        (T, Test_Partial_Target_With_Missing_Line_Is_Labelled_Clearly'Access,
         "Phase 557 partial targets with missing lines are labelled clearly");
      Register_Routine
        (T, Test_Partial_Targets_Stale_And_Close_By_Known_Buffer'Access,
         "Phase 557 partial targets use known-buffer metadata for stale and close lifecycle");
      Register_Routine
        (T, Test_Clear_Build_Availability_Uses_Producer_Predicate'Access,
         "Phase 557 clear-build availability uses explicit producer classification");
      Register_Routine
        (T, Test_External_Build_Producer_Classifies_Explicitly'Access,
         "Phase 557 external build producer classification is explicit and label-independent");
      Register_Routine
        (T, Test_Note_And_Unknown_Severities_Are_First_Class'Access,
         "Phase 557 note and unknown diagnostic severities are first-class");
      Register_Routine
        (T, Test_Source_Label_Filter_Does_Not_Match_Message_Text'Access,
         "Phase 557 source/file filtering does not match incidental message text");
      Register_Routine
        (T, Test_Source_Label_Filter_Does_Not_Match_Target_Status_Text'Access,
         "Phase 557 source/file filtering does not match target-status review text");
      Register_Routine
        (T, Test_Selected_Source_Filter_Uses_Selected_Row_Without_Command_Payload'Access,
         "Phase 557 filter-source derives source from selected row without command payload");
      Register_Routine
        (T, Test_Filter_Command_Availability_Reasons_Are_Precise'Access,
         "Phase 557 filter commands expose precise availability reasons");
      Register_Routine
        (T, Test_Severity_Clear_Availability_And_Outcomes_Are_Precise'Access,
         "Phase 557 severity clear commands expose precise matching-row availability reasons");
      Register_Routine
        (T, Test_Info_Toggle_Hides_Notes_As_Informational_Diagnostics'Access,
         "Phase 557 info toggle hides notes as part of the info/notes triage bucket");
      Register_Routine
        (T, Test_Filter_Command_Execution_Guards_Mirror_Availability'Access,
         "Phase 557 filter command execution guards mirror availability reasons");
      Register_Routine
        (T, Test_Next_Previous_Are_Unavailable_When_Filter_Hides_All'Access,
         "Phase 557 next/previous diagnostics are unavailable when filters hide all rows");
      Register_Routine
        (T, Test_Next_Previous_Execution_Distinguishes_No_Diagnostics'Access,
         "Phase 557 next/previous execution distinguishes no diagnostics from no visible diagnostics");
      Register_Routine
        (T, Test_Diagnostics_Open_Failure_Reports_One_Primary_Message'Access,
         "Phase 557 Diagnostics activation failures emit one primary outcome");
      Register_Routine
        (T, Test_Diagnostics_Open_Failure_Normalizes_Partial_Target_Messages'Access,
         "Phase 557 Diagnostics activation failures normalize partial target messages");
      Register_Routine
        (T, Test_Phase578_Stale_Diagnostic_Target_Blocks_Real_Open_Route'Access,
         "Phase 578 stale Diagnostics targets block the real open route with canonical wording");
      Register_Routine
        (T, Test_Filtered_Header_Exposes_Visible_Severity_Counts'Access,
         "Phase 557 filtered headers expose visible severity counts separately from totals");
      Register_Routine
        (T, Test_Severity_Filter_Modes_Reset_Source_And_Producer_Filters'Access,
         "Phase 557 severity filter modes reset source and producer predicates");
      Register_Routine
        (T, Test_Persistence_Audit_Excludes_Filter_Selection_Projection'Access,
         "Phase 557 persistence audit excludes Diagnostics review state");
      Register_Routine
        (T, Test_Clear_Diagnostics_Resets_Transient_Filter_State'Access,
         "Phase 557 clear diagnostics resets transient filter state");
      Register_Routine
        (T, Test_Direct_Clear_Diagnostics_Resets_Filter_State'Access,
         "Phase 557 direct clear diagnostics resets transient filter state");
      Register_Routine
        (T, Test_Clear_Build_Resets_Exhausted_Build_Only_Filter'Access,
         "Phase 557 clear-build resets exhausted build-only review predicate");
      Register_Routine
        (T, Test_Targeted_Delete_Resets_Exhausted_Source_Filter'Access,
         "Phase 557 targeted delete resets exhausted source/file review predicate");
      Register_Routine
        (T, Test_Visible_Projection_Orders_Diagnostics_By_Source_Line_Column'Access,
         "Phase 557 visible Diagnostics projection sorts by source, line, column, and severity");
      Register_Routine
        (T, Test_Missing_Target_Line_Metadata_Is_Shown_And_Orders_Projection'Access,
         "Phase 557 missing-target diagnostics retain line metadata for labels and ordering");
      Register_Routine
        (T, Test_Next_Previous_Diagnostics_Wrap_Visible_Projection'Access,
         "Phase 557 next/previous diagnostics wrap through visible projection rows");
      Register_Routine
        (T, Test_Clear_Selected_Reconciles_By_Visible_Projection_Order'Access,
         "Phase 557 clear selected reconciles selection by visible projection order");
      Register_Routine
        (T, Test_Diagnostic_Message_Text_Is_Bounded_At_Ingestion'Access,
         "Phase 557 Diagnostics message text is bounded at ingestion");
      Register_Routine
        (T, Test_Diagnostic_Source_Label_Text_Is_Bounded_At_Ingestion'Access,
         "Phase 557 Diagnostics source label text is bounded at ingestion");
      Register_Routine
        (T, Test_Retention_Eviction_Resets_Exhausted_Source_And_Build_Filters'Access,
         "Phase 557 bounded retention resets exhausted source/build filters");
      Register_Routine
        (T, Test_Phase_557_Coherence_Audit'Access,
         "Phase 557 coherence audit covers Problems-style Diagnostics review UX");
   end Register_Tests;

end Editor.Diagnostics_Review_UX.Tests;
