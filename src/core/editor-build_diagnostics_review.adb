with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Command;
with Editor.Build_Diagnostics;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Commands;
with Editor.Command_Execution;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;

package body Editor.Build_Diagnostics_Review is

   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Id;
   use type Editor.External_Producers.Diagnostic_Line_Command_Outcome;
   use type Editor.External_Producers.External_Producer_Kind;
   use type Editor.Feature_Diagnostics.Diagnostic_Source_Kind;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Feature_Panel.Feature_Panel_Row_Kind;

   function Contains
     (Text    : String;
      Pattern : String) return Boolean
   is
   begin
      return Ada.Strings.Fixed.Index
        (Ada.Characters.Handling.To_Lower (Text),
         Ada.Characters.Handling.To_Lower (Pattern)) /= 0;
   end Contains;

   function Build_Diagnostic_Source_Label
     (Request : Editor.External_Producers.Build_Run_Request) return String
   is
   begin
      return Editor.Build_Diagnostics.Build_Diagnostic_Source_Display_Label (Request);
   end Build_Diagnostic_Source_Label;

   function Build_Diagnostics_Ingestion_Summary
     (Result : Editor.External_Producers.Diagnostic_Line_Command_Result)
      return String
   is
      Count : constant Natural :=
        Result.Ingestion.Ingestion_Result.Accepted_Count;
   begin
      case Result.Outcome is
         when Editor.External_Producers.Diagnostic_Line_Command_Succeeded =>
            return "diagnostics ingested:" & Natural'Image (Count);
         when Editor.External_Producers.Diagnostic_Line_Command_No_Input =>
            return "diagnostics not requested";
         when Editor.External_Producers.Diagnostic_Line_Command_No_Diagnostics =>
            return "no diagnostics";
         when Editor.External_Producers.Diagnostic_Line_Command_Malformed_Only =>
            return "diagnostics parse partial";
      end case;
   end Build_Diagnostics_Ingestion_Summary;

   function Assert_Build_Diagnostics_Are_Diagnostics_Owned
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      if Editor.Feature_Diagnostics.Row_Count (State.Feature_Diagnostics) >
        Editor.Feature_Diagnostics.Max_Diagnostics
      then
         return False;
      end if;

      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (State.Feature_Diagnostics) loop
         if Contains
              (Editor.Feature_Diagnostics.Item_Source_Label
                 (State.Feature_Diagnostics, I),
               "build")
         then
            if Editor.Feature_Diagnostics.Item_Source_Kind
                 (State.Feature_Diagnostics, I) /=
               Editor.Feature_Diagnostics.External_Diagnostic_Source
            then
               return False;
            end if;
         end if;
      end loop;

      return True;
   end Assert_Build_Diagnostics_Are_Diagnostics_Owned;

   function Assert_Build_Diagnostics_Review_Uses_Existing_Diagnostics
     (State : Editor.State.State_Type) return Boolean
   is
      Panel : Editor.Feature_Panel.Feature_Panel_State;
      Visible : constant Natural :=
        Editor.Feature_Diagnostics.Visible_Row_Count (State.Feature_Diagnostics);
      Projected : Natural := 0;
   begin
      Editor.Feature_Diagnostics.Project_Rows (State.Feature_Diagnostics, Panel);
      Projected := Editor.Feature_Panel.Row_Count (Panel);
      return Editor.Feature_Panel.Active_Feature (Panel) =
          Editor.Feature_Panel.Diagnostics_Feature
        and then
          (Projected = Visible
           or else
             (Visible = 0
              and then Projected = 1
              and then Editor.Feature_Panel.Row_Kind (Panel, 1) =
                Editor.Feature_Panel.Feature_Row_Empty_State))
        and then Editor.Feature_Panel.Invariant_Holds (Panel);
   end Assert_Build_Diagnostics_Review_Uses_Existing_Diagnostics;

   function Diagnostics_Command_Route_Passes
     (Id : Editor.Commands.Command_Id;
      Name : String) return Boolean
   is
      Descriptor : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Id);
   begin
      return Editor.Commands.Stable_Command_Name (Id) = Name
        and then Editor.Commands.Has_Availability_Handler (Id)
        and then Editor.Commands.Is_Bindable_Command (Id)
        and then Descriptor.Category = Editor.Commands.Panel_Category;
   end Diagnostics_Command_Route_Passes;

   function Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes
     return Boolean
   is
   begin
      return Diagnostics_Command_Route_Passes
          (Editor.Commands.Command_Diagnostics_Open_Selected,
           "diagnostics.open-selected")
        and then Diagnostics_Command_Route_Passes
          (Editor.Commands.Command_Diagnostics_Select_Next,
           "diagnostics.next")
        and then Diagnostics_Command_Route_Passes
          (Editor.Commands.Command_Diagnostics_Select_Previous,
           "diagnostics.previous")
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Build_Run) = "build.run"
        and then Editor.Commands.Is_Public_Build_Command
          (Editor.Commands.Command_Build_Run)
        and then not Contains
          (To_String (Editor.Commands.Descriptor
             (Editor.Commands.Command_Build_Run).Name), "Diagnostic");
   end Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes;

   function Assert_Build_Summary_Stores_No_Diagnostics_Rows
     (Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary)
      return Boolean
   is
   begin
      return Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Not_Diagnostics_Owner
          (Summary)
        and then not Editor.Build_Result_Summary.Has_Diagnostics_Rows_Field
          (Summary)
        and then not Editor.Build_Result_Summary.Has_Diagnostics_Table_Field
          (Summary);
   end Assert_Build_Summary_Stores_No_Diagnostics_Rows;

   function Assert_Build_Output_Details_Stores_No_Diagnostics_Rows
     (Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Boolean
   is
   begin
      return Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Not_Diagnostics_Owner
          (Details)
        and then not Editor.Build_Output_Details.Has_Diagnostics_Rows_Field
          (Details);
   end Assert_Build_Output_Details_Stores_No_Diagnostics_Rows;

   function Assert_Build_Diagnostics_Review_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_UI.Assert_Build_UI_State_Is_Transient (State.Build_UI)
        and then Editor.Build_Command.Assert_Build_Run_Persistence_Excluded (State);
   end Assert_Build_Diagnostics_Review_Persistence_Excluded;


   function Assert_Build_Diagnostics_Source_Metadata_Reliable
     (Request : Editor.External_Producers.Build_Run_Request) return Boolean
   is
      Source : constant Editor.External_Producers.External_Producer_Source :=
        Editor.Build_Diagnostics.Build_Diagnostic_Source_Metadata (Request);
      Label  : constant String := To_String (Source.Display_Label);
   begin
      return Editor.External_Producers.Producer_Source_Is_Valid (Source)
        and then Source.Kind = Editor.External_Producers.Build_Diagnostics_Producer
        and then Contains (Label, "Build")
        and then not Contains (Label, "gprbuild")
        and then not Contains (Label, "alr")
        and then not Contains (Label, "rerun")
        and then not Contains (Label, "handle")
        and then not Contains (Label, "shell");
   end Assert_Build_Diagnostics_Source_Metadata_Reliable;

   function Assert_Build_Diagnostics_Zero_Output_Reliable
     (State  : Editor.State.State_Type;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result)
      return Boolean
   is
   begin
      return Result.Ingestion.Ingestion_Result.Accepted_Count = 0
        and then Result.Ingestion.Normalized_Count = 0
        and then Result.Outcome in
          Editor.External_Producers.Diagnostic_Line_Command_No_Input |
          Editor.External_Producers.Diagnostic_Line_Command_No_Diagnostics
        and then Assert_Build_Diagnostics_Are_Diagnostics_Owned (State)
        and then Assert_Build_Diagnostics_Not_Build_Owned (State);
   end Assert_Build_Diagnostics_Zero_Output_Reliable;

   function Assert_Build_Diagnostics_Malformed_Output_Reliable
     (State  : Editor.State.State_Type;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result)
      return Boolean
   is
   begin
      return Result.Ingestion.Ingestion_Result.Accepted_Count = 0
        and then Result.Ingestion.Parse_Rejected_Malformed_Count > 0
        and then Result.Outcome =
          Editor.External_Producers.Diagnostic_Line_Command_Malformed_Only
        and then Assert_Build_Diagnostics_Are_Diagnostics_Owned (State)
        and then Assert_Build_Diagnostics_Not_Build_Owned (State);
   end Assert_Build_Diagnostics_Malformed_Output_Reliable;

   function Assert_Build_Diagnostics_Truncated_Or_Partial_Output_Reliable
     (State  : Editor.State.State_Type;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result)
      return Boolean
   is
   begin
      return Result.Ingestion.Parse_Input_Count <=
          Editor.Build_Diagnostics.Max_Build_Diagnostic_Input_Lines
        and then Result.Ingestion.Ingestion_Result.Accepted_Count <=
          Editor.Build_Diagnostics.Max_Build_Diagnostic_Input_Lines
        and then Assert_Build_Diagnostics_Are_Diagnostics_Owned (State)
        and then Assert_Build_Diagnostics_Not_Build_Owned (State);
   end Assert_Build_Diagnostics_Truncated_Or_Partial_Output_Reliable;

   function Assert_Build_Diagnostics_Mixed_Source_Review_Reliable
     (State : Editor.State.State_Type) return Boolean
   is
      Build_Count : Natural := 0;
      Other_Count : Natural := 0;
   begin
      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (State.Feature_Diagnostics) loop
         if Contains
              (Editor.Feature_Diagnostics.Item_Source_Label
                 (State.Feature_Diagnostics, I),
               "build")
         then
            Build_Count := Build_Count + 1;
            if Editor.Feature_Diagnostics.Item_Source_Kind
                 (State.Feature_Diagnostics, I) /=
               Editor.Feature_Diagnostics.External_Diagnostic_Source
            then
               return False;
            end if;
         else
            Other_Count := Other_Count + 1;
         end if;
      end loop;

      return Build_Count > 0
        and then Other_Count > 0
        and then Assert_Build_Diagnostics_Are_Diagnostics_Owned (State)
        and then Assert_Build_Diagnostics_Review_Uses_Existing_Diagnostics (State);
   end Assert_Build_Diagnostics_Mixed_Source_Review_Reliable;

   function Assert_Build_Diagnostics_Not_Build_Owned
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return not Editor.Build_Result_Summary.Has_Diagnostics_Rows_Field
          (State.Latest_Build_Result)
        and then not Editor.Build_Result_Summary.Has_Diagnostics_Table_Field
          (State.Latest_Build_Result)
        and then not Editor.Build_Output_Details.Has_Diagnostics_Rows_Field
          (State.Latest_Build_Output_Details)
        and then not Editor.Build_UI.Has_Candidate_Execution_Field (State.Build_UI)
        and then not Editor.Build_UI.Has_Raw_Shell_Command_Field (State.Build_UI)
        and then not Editor.Build_UI.Has_Remembered_Consent_Field (State.Build_UI);
   end Assert_Build_Diagnostics_Not_Build_Owned;

   function Assert_Build_Diagnostics_Not_Render_Parsed return Boolean
   is
   begin
      return Editor.Build_Diagnostics.Assert_Build_Diagnostics_Render_Not_Parsing;
   end Assert_Build_Diagnostics_Not_Render_Parsed;


   function Assert_Build_Diagnostics_No_Build_Local_Table
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Diagnostics_Not_Build_Owned (State)
        and then not Editor.Build_Result_Summary.Has_Diagnostics_Rows_Field
          (State.Latest_Build_Result)
        and then not Editor.Build_Result_Summary.Has_Diagnostics_Table_Field
          (State.Latest_Build_Result)
        and then not Editor.Build_Output_Details.Has_Diagnostics_Rows_Field
          (State.Latest_Build_Output_Details);
   end Assert_Build_Diagnostics_No_Build_Local_Table;

   function Assert_Build_Diagnostics_No_Build_Local_Selection
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      --  Selection/current-row state remains in the existing Diagnostics/
      --  Feature_Panel projection.  Build summary, output details, and Build UI
      --  expose no diagnostic row/target fields that could carry an independent
      --  build-local current diagnostic.
      return Assert_Build_Diagnostics_No_Build_Local_Table (State)
        and then Assert_Build_Diagnostics_Review_Uses_Existing_Diagnostics (State);
   end Assert_Build_Diagnostics_No_Build_Local_Selection;

   function Assert_Build_Diagnostics_No_Build_Specific_Navigation
     return Boolean
   is
   begin
      return Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Build_Run) = "build.run"
        and then not Contains
          (Editor.Commands.Stable_Command_Name
             (Editor.Commands.Command_Build_Run), "diagnostic")
        and then Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run).Category /=
          Editor.Commands.Diagnostics_Category;
   end Assert_Build_Diagnostics_No_Build_Specific_Navigation;

   function Assert_Build_Diagnostics_Ingestion_Only_Diagnostics_API
     (State : Editor.State.State_Type) return Boolean
   is
      S : Editor.State.State_Type := State;
      Before_Count : constant Natural :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => Null_Unbounded_String,
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Build_Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "main.adb:9:1: error: canonical");
      Ingestion : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Ingestion := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Build_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      return Ingestion.Ingestion.Ingestion_Result.Accepted_Count = 1
        and then Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) =
          Before_Count + 1
        and then Assert_Build_Diagnostics_Are_Diagnostics_Owned (S)
        and then Assert_Build_Diagnostics_No_Build_Local_Table (S)
        and then Assert_Build_Diagnostics_Not_Render_Parsed;
   end Assert_Build_Diagnostics_Ingestion_Only_Diagnostics_API;

   function Run_Build_Diagnostics_Review
     (State : Editor.State.State_Type) return Build_Diagnostics_Review_Result
   is
      Result : Build_Diagnostics_Review_Result;
   begin
      Result.Build_Rows_Are_Diagnostics_Owned :=
        Assert_Build_Diagnostics_Are_Diagnostics_Owned (State);
      Result.Review_Uses_Existing_Diagnostics :=
        Assert_Build_Diagnostics_Review_Uses_Existing_Diagnostics (State);
      Result.Navigation_Uses_Diagnostics_Routes :=
        Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes;
      Result.Summary_Stores_No_Diagnostics_Rows :=
        Assert_Build_Summary_Stores_No_Diagnostics_Rows
          (State.Latest_Build_Result);
      Result.Output_Details_Stores_No_Diagnostics_Rows :=
        Assert_Build_Output_Details_Stores_No_Diagnostics_Rows
          (State.Latest_Build_Output_Details);
      Result.Build_UI_Stores_No_Diagnostics_Rows :=
        not Editor.Build_UI.Has_Raw_Shell_Command_Field (State.Build_UI)
        and then not Editor.Build_UI.Has_Remembered_Consent_Field (State.Build_UI)
        and then not Editor.Build_UI.Has_Candidate_Execution_Field (State.Build_UI);
      Result.Render_Parses_No_Build_Output :=
        Editor.Build_Diagnostics.Assert_Build_Diagnostics_Render_Not_Parsing;
      Result.Command_Frontdoors_Do_Not_Ingest :=
        Editor.Build_Command.Assert_Build_Run_Command_Palette_Boundary (State)
        and then Editor.Build_Command.Assert_Build_Run_Keybinding_Boundary;
      Result.Persistence_Excluded :=
        Assert_Build_Diagnostics_Review_Persistence_Excluded (State);
      Result.Coherent :=
        Result.Build_Rows_Are_Diagnostics_Owned
        and then Result.Review_Uses_Existing_Diagnostics
        and then Result.Navigation_Uses_Diagnostics_Routes
        and then Result.Summary_Stores_No_Diagnostics_Rows
        and then Result.Output_Details_Stores_No_Diagnostics_Rows
        and then Result.Build_UI_Stores_No_Diagnostics_Rows
        and then Result.Render_Parses_No_Build_Output
        and then Result.Command_Frontdoors_Do_Not_Ingest
        and then Result.Persistence_Excluded;
      return Result;
   end Run_Build_Diagnostics_Review;

   function Assert_Public_Build_Diagnostics_Review_Foundation_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
      S : Editor.State.State_Type := State;
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => Null_Unbounded_String,
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Build_Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "main.adb:1:1: error: reviewable");
      Ingestion : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Review    : Build_Diagnostics_Review_Result;
   begin
      Ingestion := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Build_Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);
      Review := Run_Build_Diagnostics_Review (S);

      return Ingestion.Ingestion.Ingestion_Result.Accepted_Count = 1
        and then Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1
        and then Editor.Feature_Diagnostics.Item_Source_Kind
          (S.Feature_Diagnostics, 1) =
          Editor.Feature_Diagnostics.External_Diagnostic_Source
        and then Contains
          (Editor.Feature_Diagnostics.Item_Source_Label (S.Feature_Diagnostics, 1),
           "Build")
        and then Review.Coherent;
   end Assert_Public_Build_Diagnostics_Review_Foundation_Coherent;


   function Assert_Public_Build_Diagnostics_Review_Reliability_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
      S : Editor.State.State_Type := State;
      Req : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String ("current-project-root"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Good : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "main.adb:1:1: error: reliable");
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Review  : Build_Diagnostics_Review_Result;
   begin
      Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Req, Good,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);
      Review := Run_Build_Diagnostics_Review (S);

      return Assert_Public_Build_Diagnostics_Review_Foundation_Coherent (State)
        and then Assert_Build_Diagnostics_Source_Metadata_Reliable (Req)
        and then Command.Ingestion.Ingestion_Result.Accepted_Count = 1
        and then Review.Coherent
        and then Assert_Build_Diagnostics_Not_Build_Owned (S)
        and then Assert_Build_Diagnostics_Not_Render_Parsed
        and then Assert_Build_Diagnostics_Review_Persistence_Excluded (S);
   end Assert_Public_Build_Diagnostics_Review_Reliability_Coherent;



   function Assert_Public_Build_Diagnostics_Review_Canonical_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
      Review : constant Build_Diagnostics_Review_Result :=
        Run_Build_Diagnostics_Review (State);
   begin
      return Assert_Public_Build_Diagnostics_Review_Reliability_Coherent (State)
        and then Review.Coherent
        and then Assert_Build_Diagnostics_Ingestion_Only_Diagnostics_API (State)
        and then Assert_Build_Diagnostics_No_Build_Local_Table (State)
        and then Assert_Build_Diagnostics_No_Build_Local_Selection (State)
        and then Assert_Build_Diagnostics_No_Build_Specific_Navigation
        and then Assert_Build_Summary_Stores_No_Diagnostics_Rows
          (State.Latest_Build_Result)
        and then Assert_Build_Output_Details_Stores_No_Diagnostics_Rows
          (State.Latest_Build_Output_Details)
        and then Assert_Build_Diagnostics_Review_Persistence_Excluded (State)
        and then Assert_Build_Diagnostics_Not_Render_Parsed;
   end Assert_Public_Build_Diagnostics_Review_Canonical_Coherent;


   function Assert_Build_Diagnostics_Final_Owned_By_Diagnostics
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Diagnostics_Are_Diagnostics_Owned (State)
        and then Assert_Build_Diagnostics_Not_Build_Owned (State)
        and then Assert_Build_Diagnostics_No_Build_Local_Table (State);
   end Assert_Build_Diagnostics_Final_Owned_By_Diagnostics;

   function Assert_Build_Diagnostics_Final_Ingestion_Only_Row_Creation
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Diagnostics_Ingestion_Only_Diagnostics_API (State)
        and then Editor.Build_Diagnostics.Assert_Build_Diagnostics_Uses_Diagnostics_API
        and then Editor.Build_Diagnostics.Assert_Build_Diagnostics_Output_Bounded;
   end Assert_Build_Diagnostics_Final_Ingestion_Only_Row_Creation;

   function Assert_Build_Diagnostics_Final_Source_Metadata_Boundary
     (Request : Editor.External_Producers.Build_Run_Request) return Boolean
   is
      Source : constant Editor.External_Producers.External_Producer_Source :=
        Editor.Build_Diagnostics.Build_Diagnostic_Source_Metadata (Request);
      Stable : constant String := To_String (Source.Stable_Name);
      Label  : constant String := To_String (Source.Display_Label);
   begin
      return Assert_Build_Diagnostics_Source_Metadata_Reliable (Request)
        and then Source.Kind = Editor.External_Producers.Build_Diagnostics_Producer
        and then not Contains (Stable, "shell")
        and then not Contains (Stable, "rerun")
        and then not Contains (Stable, "handle")
        and then not Contains (Stable, "stdout")
        and then not Contains (Stable, "stderr")
        and then not Contains (Label, "stdout")
        and then not Contains (Label, "stderr")
        and then not Contains (Label, "history")
        and then not Contains (Label, "argv")
        and then not Contains (Label, "consent");
   end Assert_Build_Diagnostics_Final_Source_Metadata_Boundary;

   function Assert_Build_Diagnostics_Final_Review_Boundary
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Diagnostics_Review_Uses_Existing_Diagnostics (State)
        and then Assert_Build_Diagnostics_No_Build_Local_Table (State)
        and then Assert_Build_Diagnostics_No_Build_Local_Selection (State)
        and then Assert_Build_Diagnostics_Are_Diagnostics_Owned (State);
   end Assert_Build_Diagnostics_Final_Review_Boundary;

   function Assert_Build_Diagnostics_Final_Navigation_Boundary return Boolean
   is
   begin
      return Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes
        and then Assert_Build_Diagnostics_No_Build_Specific_Navigation;
   end Assert_Build_Diagnostics_Final_Navigation_Boundary;

   function Assert_Build_Diagnostics_Final_No_Build_Local_Table
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Diagnostics_No_Build_Local_Table (State);
   end Assert_Build_Diagnostics_Final_No_Build_Local_Table;

   function Assert_Build_Diagnostics_Final_No_Build_Local_Selection
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Diagnostics_No_Build_Local_Selection (State);
   end Assert_Build_Diagnostics_Final_No_Build_Local_Selection;

   function Assert_Build_Diagnostics_Final_No_Build_Specific_Navigation
     return Boolean
   is
   begin
      return Assert_Build_Diagnostics_No_Build_Specific_Navigation;
   end Assert_Build_Diagnostics_Final_No_Build_Specific_Navigation;

   function Assert_Build_Summary_Final_Stores_No_Diagnostics_Rows
     (Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary)
      return Boolean
   is
   begin
      return Assert_Build_Summary_Stores_No_Diagnostics_Rows (Summary)
        and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Not_Diagnostics_Owner
          (Summary)
        and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Render_Boundary
          (Summary);
   end Assert_Build_Summary_Final_Stores_No_Diagnostics_Rows;

   function Assert_Build_Output_Details_Final_Stores_No_Diagnostics_Rows
     (Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Boolean
   is
   begin
      return Assert_Build_Output_Details_Stores_No_Diagnostics_Rows (Details)
        and then Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Not_Diagnostics_Owner
          (Details)
        and then Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Render_Boundary
          (Details);
   end Assert_Build_Output_Details_Final_Stores_No_Diagnostics_Rows;

   function Assert_Render_Final_Does_Not_Parse_Build_Diagnostics return Boolean
   is
   begin
      return Assert_Build_Diagnostics_Not_Render_Parsed;
   end Assert_Render_Final_Does_Not_Parse_Build_Diagnostics;

   function Assert_Build_Diagnostics_Final_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Diagnostics_Review_Persistence_Excluded (State)
        and then Editor.Build_Diagnostics.Assert_Build_Diagnostics_Not_Persisted;
   end Assert_Build_Diagnostics_Final_Persistence_Excluded;



   function Assert_Build_Diagnostics_Reviewable_In_Diagnostics_Surface
     (State : Editor.State.State_Type) return Boolean
   is
      Panel : Editor.Feature_Panel.Feature_Panel_State;
      Build_Row_Count : Natural := 0;
   begin
      Editor.Feature_Diagnostics.Project_Rows (State.Feature_Diagnostics, Panel);

      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (State.Feature_Diagnostics) loop
         if Contains
              (Editor.Feature_Diagnostics.Item_Source_Label
                 (State.Feature_Diagnostics, I),
               "Build")
         then
            Build_Row_Count := Build_Row_Count + 1;
            if Editor.Feature_Diagnostics.Item_Source_Kind
                 (State.Feature_Diagnostics, I) /=
               Editor.Feature_Diagnostics.External_Diagnostic_Source
              or else Editor.Feature_Diagnostics.Item_Message
                 (State.Feature_Diagnostics, I)'Length = 0
              or else not Contains
                 (Editor.Feature_Diagnostics.Item_Display_Label
                    (State.Feature_Diagnostics, I),
                  "Build")
            then
               return False;
            end if;
         end if;
      end loop;

      return Build_Row_Count > 0
        and then Editor.Feature_Panel.Active_Feature (Panel) =
          Editor.Feature_Panel.Diagnostics_Feature
        and then Editor.Feature_Panel.Row_Count (Panel) =
          Editor.Feature_Diagnostics.Visible_Row_Count (State.Feature_Diagnostics)
        and then Assert_Build_Diagnostics_Are_Diagnostics_Owned (State)
        and then Assert_Build_Diagnostics_No_Build_Local_Table (State);
   end Assert_Build_Diagnostics_Reviewable_In_Diagnostics_Surface;

   function Assert_Build_Diagnostics_Navigate_Through_Diagnostics
     (State : Editor.State.State_Type) return Boolean
   is
      Saw_Build_Target : Boolean := False;
   begin
      if not Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes
        or else not Assert_Build_Diagnostics_No_Build_Specific_Navigation
      then
         return False;
      end if;

      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (State.Feature_Diagnostics) loop
         if Contains
              (Editor.Feature_Diagnostics.Item_Source_Label
                 (State.Feature_Diagnostics, I),
               "Build")
           and then Editor.Feature_Diagnostics.Item_Has_Target
              (State.Feature_Diagnostics, I)
         then
            Saw_Build_Target := True;
            if not Editor.Feature_Diagnostics.Validate_Diagnostic_Target
              (State.Feature_Diagnostics, I,
               Editor.Feature_Diagnostics.Item_Target_Buffer
                 (State.Feature_Diagnostics, I))
            then
               return False;
            end if;
         end if;
      end loop;

      return Saw_Build_Target;
   end Assert_Build_Diagnostics_Navigate_Through_Diagnostics;


   function Assert_Build_Diagnostics_Source_Labels_Practical
     (State : Editor.State.State_Type) return Boolean
   is
      Saw_Build_Row : Boolean := False;
      Label : Unbounded_String;
   begin
      if not Editor.Build_Diagnostics.Assert_Build_Diagnostic_Source_Display_Labels_Bounded then
         return False;
      end if;

      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (State.Feature_Diagnostics) loop
         Label := To_Unbounded_String
           (Editor.Feature_Diagnostics.Item_Source_Label
              (State.Feature_Diagnostics, I));
         if Contains (To_String (Label), "Build") then
            Saw_Build_Row := True;
            if not Contains (To_String (Label), "Build")
              or else Contains (To_String (Label), "argv")
              or else Contains (To_String (Label), "consent")
              or else Contains (To_String (Label), "rerun")
              or else Contains (To_String (Label), "handle")
              or else Contains (To_String (Label), "shell")
            then
               return False;
            end if;
         end if;
      end loop;

      return Saw_Build_Row;
   end Assert_Build_Diagnostics_Source_Labels_Practical;

   function Assert_Mixed_Build_And_Non_Build_Diagnostics_Share_Model
     (State : Editor.State.State_Type) return Boolean
   is
      Build_Count : Natural := 0;
      Non_Build_Count : Natural := 0;
   begin
      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (State.Feature_Diagnostics) loop
         if Contains
              (Editor.Feature_Diagnostics.Item_Source_Label
                 (State.Feature_Diagnostics, I),
               "Build")
         then
            Build_Count := Build_Count + 1;
         else
            Non_Build_Count := Non_Build_Count + 1;
         end if;
      end loop;

      return Build_Count > 0
        and then Non_Build_Count > 0
        and then Assert_Build_Diagnostics_Are_Diagnostics_Owned (State)
        and then Assert_Build_Diagnostics_Review_Uses_Existing_Diagnostics (State)
        and then Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes
        and then Assert_Build_Diagnostics_No_Build_Local_Selection (State)
        and then Assert_Build_Diagnostics_No_Build_Specific_Navigation;
   end Assert_Mixed_Build_And_Non_Build_Diagnostics_Share_Model;

   function Assert_Command_Frontdoors_Carry_No_Diagnostic_Payload
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Command.Assert_Build_Run_Command_Palette_Boundary (State)
        and then Editor.Build_Command.Assert_Build_Run_Keybinding_Boundary
        and then Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes
        and then not Contains
          (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Build_Run),
           "diagnostic")
        and then not Contains
          (To_String (Editor.Commands.Descriptor
             (Editor.Commands.Command_Build_Run).Name),
           "Diagnostic");
   end Assert_Command_Frontdoors_Carry_No_Diagnostic_Payload;

   function Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result) return Boolean
   is
   begin
      return Editor.Build_UI_Actions.Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command
          (Before, After, Result)
        and then Result.Command = Editor.Commands.Command_Diagnostics_Show;
   end Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command;

   function Assert_Output_Details_Do_Not_Navigate_Diagnostics
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Final_Stores_No_Diagnostics_Rows
          (State.Latest_Build_Output_Details)
        and then not Editor.Build_Output_Details.Has_Diagnostics_Rows_Field
          (State.Latest_Build_Output_Details);
   end Assert_Output_Details_Do_Not_Navigate_Diagnostics;

   function Assert_Render_Does_Not_Copy_Build_Diagnostics
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Render_Final_Does_Not_Parse_Build_Diagnostics
        and then Assert_Build_Diagnostics_No_Build_Local_Table (State)
        and then Assert_Build_Diagnostics_Review_Uses_Existing_Diagnostics (State);
   end Assert_Render_Does_Not_Copy_Build_Diagnostics;

   function Assert_Build_Diagnostics_Navigation_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Build_Diagnostics_Final_Persistence_Excluded (State)
        and then Assert_Build_Diagnostics_Final_No_Build_Local_Selection (State);
   end Assert_Build_Diagnostics_Navigation_Persistence_Excluded;

   function Assert_Public_Build_Diagnostics_Navigation_Workflow_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
      S : Editor.State.State_Type := State;
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String ("current-project-root"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "Untitled:2:1: error: navigate");
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Before_Reveal : Editor.State.State_Type;
      After_Reveal  : Editor.State.State_Type;
      Reveal_Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");

      Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);

      Before_Reveal := S;
      After_Reveal := S;
      Reveal_Result :=
        (Status => Editor.Command_Execution.Command_Executed,
         Command => Editor.Commands.Command_Diagnostics_Show);

      return Command.Ingestion.Ingestion_Result.Accepted_Count = 1
        and then Assert_Build_Diagnostics_Reviewable_In_Diagnostics_Surface (S)
        and then Assert_Build_Diagnostics_Navigate_Through_Diagnostics (S)
        and then Assert_Build_Diagnostics_Source_Labels_Practical (S)
        and then Assert_Command_Frontdoors_Carry_No_Diagnostic_Payload (S)
        and then Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command
          (Before_Reveal, After_Reveal, Reveal_Result)
        and then Assert_Output_Details_Do_Not_Navigate_Diagnostics (S)
        and then Assert_Render_Does_Not_Copy_Build_Diagnostics (S)
        and then Assert_Build_Diagnostics_Navigation_Persistence_Excluded (S)
        and then Assert_Build_Diagnostics_Final_Navigation_Boundary
        and then Assert_Command_Frontdoors_Carry_No_Diagnostic_Payload (S);
   end Assert_Public_Build_Diagnostics_Navigation_Workflow_Coherent;


   function Assert_Public_Build_Diagnostics_Review_Final_Freeze_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
      S : Editor.State.State_Type := State;
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String ("current-project-root"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "main.adb:21:1: error: final freeze");
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Review  : Build_Diagnostics_Review_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");

      Command := Editor.Build_Diagnostics.Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Result,
         Editor.Build_Diagnostics.Build_Diagnostics_Ingestion_On_Request,
         Request_Show_Diagnostics => True);
      Review := Run_Build_Diagnostics_Review (S);

      return Assert_Public_Build_Diagnostics_Review_Canonical_Coherent (State)
        and then Command.Ingestion.Ingestion_Result.Accepted_Count = 1
        and then Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) >= 1
        and then Review.Coherent
        and then Assert_Build_Diagnostics_Final_Owned_By_Diagnostics (S)
        and then Assert_Build_Diagnostics_Final_Ingestion_Only_Row_Creation (State)
        and then Assert_Build_Diagnostics_Final_Source_Metadata_Boundary (Request)
        and then Assert_Build_Diagnostics_Final_Review_Boundary (S)
        and then Assert_Build_Diagnostics_Final_Navigation_Boundary
        and then Assert_Build_Diagnostics_Final_No_Build_Local_Table (S)
        and then Assert_Build_Diagnostics_Final_No_Build_Local_Selection (S)
        and then Assert_Build_Diagnostics_Final_No_Build_Specific_Navigation
        and then Assert_Build_Summary_Final_Stores_No_Diagnostics_Rows
          (S.Latest_Build_Result)
        and then Assert_Build_Output_Details_Final_Stores_No_Diagnostics_Rows
          (S.Latest_Build_Output_Details)
        and then Assert_Render_Final_Does_Not_Parse_Build_Diagnostics
        and then Assert_Build_Diagnostics_Final_Persistence_Excluded (S);
   end Assert_Public_Build_Diagnostics_Review_Final_Freeze_Coherent;

end Editor.Build_Diagnostics_Review;
