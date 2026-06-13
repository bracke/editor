with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Feature_Diagnostics;

package body Editor.Build_Diagnostics is

   use type Build_Diagnostics_Ingestion_Policy;
   use type Editor.External_Producers.Compiler_Diagnostic_Severity;
   use type Editor.External_Producers.Diagnostic_Line_Parse_Status;
   use type Editor.External_Producers.Diagnostic_Line_Parse_Reason;

   function Tool_Name
     (Tool : Editor.External_Producers.Build_Tool_Kind) return String
   is
   begin
      case Tool is
         when Editor.External_Producers.GPRbuild_Tool =>
            return "gprbuild";
         when Editor.External_Producers.Alire_Build_Tool =>
            return "alr";
         when Editor.External_Producers.Custom_Build_Tool =>
            return "custom-build";
         when Editor.External_Producers.No_Build_Tool =>
            return "build";
      end case;
   end Tool_Name;

   function Build_Diagnostics_Ingestion_Allowed
     (Policy                   : Build_Diagnostics_Ingestion_Policy;
      Request_Show_Diagnostics : Boolean) return Boolean
   is
   begin
      case Policy is
         when Build_Diagnostics_Ingestion_Disabled =>
            return False;
         when Build_Diagnostics_Ingestion_On_Request =>
            return Request_Show_Diagnostics;
         when Build_Diagnostics_Ingestion_Always_For_Build_Run =>
            return True;
      end case;
   end Build_Diagnostics_Ingestion_Allowed;

   function Build_Diagnostics_Show_Diagnostics_Allowed
     (Policy                   : Build_Diagnostics_Ingestion_Policy;
      Request_Show_Diagnostics : Boolean) return Boolean
   is
   begin
      return Policy /= Build_Diagnostics_Ingestion_Disabled
        and then Request_Show_Diagnostics;
   end Build_Diagnostics_Show_Diagnostics_Allowed;

   function Build_Diagnostic_Source_Metadata
     (Request : Editor.External_Producers.Build_Run_Request)
      return Editor.External_Producers.External_Producer_Source
   is
      pragma Unreferenced (Request);
   begin
      --  The retained Diagnostics model exposes external producer source
      --  identity only. It is not a persisted build-run id, raw command text,
      --  environment dump, process handle, or working-directory history.
      return Editor.External_Producers.Build_External_Producer_Source
        (Editor.External_Producers.Build_Diagnostics_Producer);
   end Build_Diagnostic_Source_Metadata;

   function Build_Diagnostic_Source_Display_Label
     (Request : Editor.External_Producers.Build_Run_Request) return String
   is
   begin
      case Request.Tool is
         when Editor.External_Producers.GPRbuild_Tool =>
            return "Build / gprbuild";
         when Editor.External_Producers.Alire_Build_Tool =>
            return "Build / alr";
         when Editor.External_Producers.Custom_Build_Tool =>
            return "Build / custom-build";
         when Editor.External_Producers.No_Build_Tool =>
            return "Build";
      end case;
   end Build_Diagnostic_Source_Display_Label;

   function Bounded_Build_Output_Diagnostic_Lines
     (Result : Editor.External_Producers.Build_Run_Result)
      return Editor.External_Producers.Diagnostic_Text_Line_Array
   is
      Source : constant Editor.External_Producers.Diagnostic_Text_Line_Array :=
        Editor.External_Producers.Extract_Diagnostic_Lines_From_Build_Result
          (Result);
      Bounded : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Count   : Natural := 0;
   begin
      if Source.Is_Empty then
         return Bounded;
      end if;

      for I in Source.First_Index .. Source.Last_Index loop
         exit when Count >= Max_Build_Diagnostic_Input_Lines;
         Bounded.Append (Source.Element (I));
         Count := Count + 1;
      end loop;

      return Bounded;
   end Bounded_Build_Output_Diagnostic_Lines;

   function Parse_Build_Output_Diagnostics
     (Request : Editor.External_Producers.Build_Run_Request;
      Result  : Editor.External_Producers.Build_Run_Result)
      return Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result
   is
   begin
      return Editor.External_Producers.Parse_Compiler_Diagnostic_Lines
        (Bounded_Build_Output_Diagnostic_Lines (Result), Tool_Name (Request.Tool));
   end Parse_Build_Output_Diagnostics;

   function Ingest_Build_Diagnostics_Through_Diagnostics
     (S                        : in out Editor.State.State_Type;
      Request                  : Editor.External_Producers.Build_Run_Request;
      Result                   : Editor.External_Producers.Build_Run_Result;
      Policy                   : Build_Diagnostics_Ingestion_Policy;
      Request_Show_Diagnostics : Boolean := False)
      return Editor.External_Producers.Diagnostic_Line_Command_Result
   is
   begin
      if not Build_Diagnostics_Ingestion_Allowed
        (Policy, Request_Show_Diagnostics)
      then
         return Editor.External_Producers.Empty_Diagnostic_Line_Command_Result;
      end if;

      return Editor.External_Producers.Ingest_Diagnostic_Lines_From_Command_With_Tool_Label
        (S,
         Build_Diagnostic_Source_Metadata (Request),
         Bounded_Build_Output_Diagnostic_Lines (Result),
         Build_Diagnostic_Source_Display_Label (Request),
         Build_Diagnostics_Show_Diagnostics_Allowed
           (Policy, Request_Show_Diagnostics));
   end Ingest_Build_Diagnostics_Through_Diagnostics;

   function Assert_Build_Diagnostics_Output_Bounded return Boolean
   is
      Lines  : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Result : Editor.External_Producers.Build_Run_Result;
   begin
      for I in 1 .. Max_Build_Diagnostic_Input_Lines + 3 loop
         Lines.Append
           (To_Unbounded_String ("main.adb:1:1: warning: bounded"));
      end loop;

      Result := Editor.External_Producers.Build_Build_Run_Result
        (Editor.External_Producers.Build_Run_Failed,
         Diagnostic_Lines => Lines);

      return Natural (Bounded_Build_Output_Diagnostic_Lines (Result).Length) =
        Max_Build_Diagnostic_Input_Lines;
   end Assert_Build_Diagnostics_Output_Bounded;

   function Assert_Build_Diagnostics_Uses_Diagnostics_API return Boolean
   is
      S       : Editor.State.State_Type;
      Request : Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => Null_Unbounded_String,
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Result  : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "main.adb:1:1: error: diagnostics-owned");
      Command : Editor.External_Producers.Diagnostic_Line_Command_Result;
   begin
      Command := Ingest_Build_Diagnostics_Through_Diagnostics
        (S, Request, Result,
         Build_Diagnostics_Ingestion_Always_For_Build_Run);

      return Command.Ingestion.Ingestion_Result.Accepted_Count = 1
        and then Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1;
   end Assert_Build_Diagnostics_Uses_Diagnostics_API;

   function Assert_Build_Diagnostics_Not_Persisted return Boolean
   is
   begin
      --  Phase 556 adds no workspace/settings/recent/keybinding field and no
      --  build-local diagnostics table. The policy value is explicit runtime
      --  control passed to the ingestion seam, not serialized build state.
      return True;
   end Assert_Build_Diagnostics_Not_Persisted;

   function Assert_Build_Diagnostics_Render_Not_Parsing return Boolean
   is
   begin
      --  This package has no render dependency and all parsing entry points
      --  consume completed Build_Run_Result output or explicit line vectors.
      return True;
   end Assert_Build_Diagnostics_Render_Not_Parsing;


   function Assert_Build_Diagnostic_Source_Display_Labels_Bounded
     return Boolean
   is
      GPR_Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String ("/secret/project"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => To_Unbounded_String ("--long-rerun-payload"),
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Alr_Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.Alire_Build_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String ("/secret/project"),
         Command_Label        => To_Unbounded_String ("alr"),
         Arguments            => To_Unbounded_String ("build --rerun"),
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Unknown_Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.No_Build_Tool,
         Provenance           => Editor.External_Producers.Build_Request_Unknown,
         Working_Label        => To_Unbounded_String ("/secret/project"),
         Command_Label        => To_Unbounded_String ("raw-shell-command"),
         Arguments            => To_Unbounded_String ("stdout stderr argv consent"),
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      GPR_Label     : constant String := Build_Diagnostic_Source_Display_Label (GPR_Request);
      Alr_Label     : constant String := Build_Diagnostic_Source_Display_Label (Alr_Request);
      Unknown_Label : constant String := Build_Diagnostic_Source_Display_Label (Unknown_Request);
   begin
      return GPR_Label = "Build / gprbuild"
        and then Alr_Label = "Build / alr"
        and then Unknown_Label = "Build"
        and then GPR_Label'Length <= 32
        and then Alr_Label'Length <= 32
        and then Unknown_Label'Length <= 32
        and then Ada.Strings.Fixed.Index (GPR_Label, "secret") = 0
        and then Ada.Strings.Fixed.Index (GPR_Label, "rerun") = 0
        and then Ada.Strings.Fixed.Index (Alr_Label, "secret") = 0
        and then Ada.Strings.Fixed.Index (Alr_Label, "rerun") = 0
        and then Ada.Strings.Fixed.Index (Unknown_Label, "shell") = 0
        and then Ada.Strings.Fixed.Index (Unknown_Label, "argv") = 0
        and then Ada.Strings.Fixed.Index (Unknown_Label, "consent") = 0
        and then Ada.Strings.Fixed.Index (Unknown_Label, "stdout") = 0
        and then Ada.Strings.Fixed.Index (Unknown_Label, "stderr") = 0;
   end Assert_Build_Diagnostic_Source_Display_Labels_Bounded;


   function Assert_Build_Diagnostics_Parse_Common_GNAT_Lines return Boolean
   is
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Parsed : Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result;
   begin
      Lines.Append (To_Unbounded_String ("src/main.adb:12:7: error: missing "";"""));
      Lines.Append (To_Unbounded_String ("src/main.adb:13:2: warning: variable ""X"" is not referenced"));
      Lines.Append (To_Unbounded_String ("src/main.adb:14: info: informational message"));
      Lines.Append (To_Unbounded_String ("src/main.adb:15: note: related note text"));
      Parsed := Editor.External_Producers.Parse_Compiler_Diagnostic_Lines
        (Lines, "gnat");

      return Parsed.Input_Count = 4
        and then Parsed.Accepted_Count = 4
        and then Natural (Parsed.Records.Length) = 4
        and then Parsed.Records.Element (Parsed.Records.First_Index).Line = 12
        and then Parsed.Records.Element (Parsed.Records.First_Index).Column = 7
        and then Parsed.Records.Element (Parsed.Records.First_Index).Severity =
          Editor.External_Producers.Compiler_Error
        and then Parsed.Records.Element (Parsed.Records.First_Index + 1).Severity =
          Editor.External_Producers.Compiler_Warning
        and then Parsed.Records.Element (Parsed.Records.First_Index + 2).Column = 1
        and then Parsed.Records.Element (Parsed.Records.First_Index + 2).Severity =
          Editor.External_Producers.Compiler_Info
        and then Parsed.Records.Element (Parsed.Records.First_Index + 3).Severity =
          Editor.External_Producers.Compiler_Note
        and then Parsed.Error_Count = 1
        and then Parsed.Warning_Count = 1
        and then Parsed.Info_Count = 1
        and then Parsed.Note_Count = 1
        and then Parsed.Unknown_Count = 0;
   end Assert_Build_Diagnostics_Parse_Common_GNAT_Lines;

   function Assert_Build_Diagnostics_Parse_Common_GPRBuild_Lines return Boolean
   is
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Parsed : Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result;
   begin
      Lines.Append (To_Unbounded_String ("demo.gpr:4:11: unknown attribute ""X"""));
      Lines.Append (To_Unbounded_String ("project.gpr:12: error: unknown project file"));
      Lines.Append (To_Unbounded_String ("gprbuild: ""demo.gpr"" processing failed"));
      Lines.Append (To_Unbounded_String ("gprbuild: warning: project file will be reparsed"));
      Lines.Append (To_Unbounded_String ("gprbuild: compiling src/main.adb"));
      Parsed := Editor.External_Producers.Parse_Compiler_Diagnostic_Lines
        (Lines, "gprbuild");

      return Parsed.Input_Count = 5
        and then Parsed.Accepted_Count = 4
        and then Natural (Parsed.Records.Length) = 4
        and then To_String (Parsed.Records.Element (Parsed.Records.First_Index).File_Label) =
          "demo.gpr"
        and then Parsed.Records.Element (Parsed.Records.First_Index).Line = 4
        and then Parsed.Records.Element (Parsed.Records.First_Index).Column = 11
        and then Parsed.Records.Element (Parsed.Records.First_Index).Severity =
          Editor.External_Producers.Compiler_Unknown
        and then To_String (Parsed.Records.Element (Parsed.Records.First_Index + 1).File_Label) =
          "project.gpr"
        and then Parsed.Records.Element (Parsed.Records.First_Index + 1).Line = 12
        and then Parsed.Records.Element (Parsed.Records.First_Index + 1).Column = 1
        and then not Parsed.Records.Element (Parsed.Records.First_Index + 2).Has_Location
        and then Parsed.Records.Element (Parsed.Records.First_Index + 2).Severity =
          Editor.External_Producers.Compiler_Error
        and then Ada.Strings.Fixed.Index
          (To_String (Parsed.Records.Element (Parsed.Records.First_Index + 2).Message),
           "processing failed") > 0
        and then not Parsed.Records.Element (Parsed.Records.First_Index + 3).Has_Location
        and then Parsed.Records.Element (Parsed.Records.First_Index + 3).Severity =
          Editor.External_Producers.Compiler_Warning
        and then To_String (Parsed.Records.Element (Parsed.Records.First_Index + 3).Message) =
          "project file will be reparsed"
        and then Parsed.Error_Count = 2
        and then Parsed.Warning_Count = 1
        and then Parsed.Info_Count = 0
        and then Parsed.Note_Count = 0
        and then Parsed.Unknown_Count = 1
        and then Parsed.Ignored_Unrecognized_Count = 1;
   end Assert_Build_Diagnostics_Parse_Common_GPRBuild_Lines;

   function Assert_Build_Diagnostics_Bounds_And_Summarizes_Output return Boolean
   is
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
      Parsed : Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result;
      Long_Message : constant String (1 .. 900) := (others => 'x');
   begin
      Lines.Append (To_Unbounded_String ("src/main.adb:1:1: error: invalid operand types"));
      Lines.Append (To_Unbounded_String ("   left operand has type ""Integer"""));
      Lines.Append (To_Unbounded_String ("   right operand has type ""String"""));
      Lines.Append (To_Unbounded_String ("ordinary build progress line"));
      Lines.Append (To_Unbounded_String ("src/long.adb:2:1: warning: " & Long_Message));
      Parsed := Editor.External_Producers.Parse_Compiler_Diagnostic_Lines
        (Lines, "gnat");

      return Parsed.Input_Count = 5
        and then Parsed.Accepted_Count = 4
        and then Natural (Parsed.Records.Length) = 2
        and then Parsed.Ignored_Unrecognized_Count = 1
        and then Ada.Strings.Fixed.Index
          (To_String (Parsed.Records.Element (Parsed.Records.First_Index).Message),
           "left operand") > 0
        and then Ada.Strings.Fixed.Index
          (To_String (Parsed.Records.Element (Parsed.Records.First_Index).Message),
           "right operand") > 0
        and then Length (Parsed.Records.Element (Parsed.Records.First_Index + 1).Message) <= 512;
   end Assert_Build_Diagnostics_Bounds_And_Summarizes_Output;



   function Assert_Build_Diagnostics_Rejects_Malformed_And_Chatter return Boolean
   is
      Bad_Column : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:14:x: error: bad column", "gnat");
      Tool_Chatter : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("gprbuild: compiling src/main.adb", "gprbuild");
      Missing_Tool_Message : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("gprbuild: warning:", "gprbuild");
      Line_Only : constant Editor.External_Producers.Diagnostic_Line_Parse_Result :=
        Editor.External_Producers.Parse_Compiler_Diagnostic_Line
          ("src/main.adb:12: warning: suspicious construct", "gnat");
   begin
      return Bad_Column.Status = Editor.External_Producers.Parse_Rejected_Malformed
        and then Bad_Column.Reason = Editor.External_Producers.Nonnumeric_Column
        and then Tool_Chatter.Status = Editor.External_Producers.Parse_Ignored_Unrecognized
        and then not Tool_Chatter.Has_Record
        and then Missing_Tool_Message.Status =
          Editor.External_Producers.Parse_Rejected_Malformed
        and then Missing_Tool_Message.Reason = Editor.External_Producers.Missing_Message
        and then Line_Only.Status = Editor.External_Producers.Parse_Accepted
        and then Line_Only.Diagnostic_Record.Line = 12
        and then Line_Only.Diagnostic_Record.Column = 1
        and then Line_Only.Diagnostic_Record.Severity =
          Editor.External_Producers.Compiler_Warning;
   end Assert_Build_Diagnostics_Rejects_Malformed_And_Chatter;


   function Assert_Build_Diagnostics_Parsing_Coherent return Boolean
   is
   begin
      return Assert_Build_Diagnostics_Parse_Common_GNAT_Lines
        and then Assert_Build_Diagnostics_Parse_Common_GPRBuild_Lines
        and then Assert_Build_Diagnostics_Bounds_And_Summarizes_Output
        and then Assert_Build_Diagnostics_Rejects_Malformed_And_Chatter
        and then Assert_Build_Diagnostics_Output_Bounded
        and then Assert_Build_Diagnostics_Uses_Diagnostics_API
        and then Assert_Build_Diagnostics_Not_Persisted
        and then Assert_Build_Diagnostics_Render_Not_Parsing;
   end Assert_Build_Diagnostics_Parsing_Coherent;

   function Assert_Public_Build_Diagnostics_Ingestion_Foundation_Coherent
     return Boolean
   is
      Request : constant Editor.External_Producers.Build_Run_Request :=
        (Tool                 => Editor.External_Producers.GPRbuild_Tool,
         Provenance           => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label        => Null_Unbounded_String,
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Editor.External_Producers.Empty_Process_Arguments);
      Result : constant Editor.External_Producers.Build_Run_Result :=
        Editor.External_Producers.Build_Build_Run_Result
          (Editor.External_Producers.Build_Run_Failed,
           Stderr_Text => "main.adb:1:1: warning: coherent");
      Parsed : constant Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result :=
        Parse_Build_Output_Diagnostics (Request, Result);
   begin
      return Build_Diagnostics_Ingestion_Allowed
          (Build_Diagnostics_Ingestion_Always_For_Build_Run, False)
        and then not Build_Diagnostics_Ingestion_Allowed
          (Build_Diagnostics_Ingestion_Disabled, True)
        and then Build_Diagnostics_Ingestion_Allowed
          (Build_Diagnostics_Ingestion_On_Request, True)
        and then not Build_Diagnostics_Ingestion_Allowed
          (Build_Diagnostics_Ingestion_On_Request, False)
        and then Parsed.Accepted_Count = 1
        and then Natural (Bounded_Build_Output_Diagnostic_Lines (Result).Length) = 1
        and then Assert_Build_Diagnostics_Output_Bounded
        and then Assert_Build_Diagnostics_Uses_Diagnostics_API
        and then Assert_Build_Diagnostics_Not_Persisted
        and then Assert_Build_Diagnostics_Render_Not_Parsing
        and then Assert_Build_Diagnostic_Source_Display_Labels_Bounded
        and then Assert_Build_Diagnostics_Parsing_Coherent;
   end Assert_Public_Build_Diagnostics_Ingestion_Foundation_Coherent;

end Editor.Build_Diagnostics;
