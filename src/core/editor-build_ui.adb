with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Working_Context;
with Editor.Build_Candidates;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.External_Producers;

package body Editor.Build_UI is

   use type Ada.Containers.Count_Type;
   use type Editor.Build_Candidates.Build_Candidate_Validation_Status;
   use type Editor.Build_Working_Context.Build_Working_Context_Validation_Status;

   function Trimmed (Text : Unbounded_String) return String is
   begin
      return Ada.Strings.Fixed.Trim (To_String (Text), Ada.Strings.Both);
   end Trimmed;

   function Contains_Control (Text : String) return Boolean is
   begin
      for C of Text loop
         if Character'Pos (C) < 32 or else Character'Pos (C) = 127 then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Control;

   function Contains_Shell_Meta (Text : String) return Boolean is
      Shell_Meta : constant String := "|&;<>()`$\\" & Character'Val (10) & Character'Val (13);
   begin
      for C of Text loop
         for M of Shell_Meta loop
            if C = M then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Contains_Shell_Meta;

   procedure Invalidate_Consent
     (State : in out Public_Build_UI_State)
   is
   begin
      State.Consent_Acknowledged := False;
      State.Consent_Request_Identity := Null_Unbounded_String;
      State.Pending_Public_Build_Request := False;
   end Invalidate_Consent;

   procedure Clear_Candidate_Application
     (State   : in out Public_Build_UI_State;
      Message : String := "No build candidate selected")
   is
   begin
      State.Selected_Build_Candidate_Id := Null_Unbounded_String;
      State.Selected_Build_Candidate_Status :=
        Editor.Build_Candidates.Build_Candidate_Unavailable;
      State.Candidate_Applied_To_Request := False;
      State.Candidate_Request_Preview := Null_Unbounded_String;
      State.Candidate_Selection_Message := To_Unbounded_String (Message);
      State.Selected_Candidate_Stale := False;
      State.Selected_Build_Tool := Build_UI_No_Tool;
      State.Structured_Arguments := Empty_Arguments;
      State.Selected_Working_Context := Editor.Build_Working_Context.None;
      State.Build_Target_Label := Null_Unbounded_String;
      State.Selected_Build_Mode := Build_UI_Build_Mode_Default;
      State.Output_Capture_Limit := Build_UI_Output_Capture_Normal;
      State.Option_Verbose_Output := False;
      State.Option_Keep_Going := False;
      State.Option_Warnings_As_Errors := False;
      State.Option_Force_Rebuild := False;
   end Clear_Candidate_Application;

   function Arguments_Are_Structured_And_Safe
     (Arguments : Build_UI_Argument_Vector) return Boolean
   is
   begin
      for Arg of Arguments loop
         declare
            S : constant String := To_String (Arg);
            T : constant String := Ada.Strings.Fixed.Trim (S, Ada.Strings.Both);
         begin
            if S'Length = 0 or else T'Length = 0 then
               return False;
            elsif Contains_Control (S) or else Contains_Shell_Meta (S) then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Arguments_Are_Structured_And_Safe;

   procedure Sync_Working_Context_Projection
     (State : in out Public_Build_UI_State)
   is
      Status : constant Editor.Build_Working_Context.Build_Working_Context_Validation_Status :=
        Editor.Build_Working_Context.Validate_Build_Working_Context
          (State.Selected_Working_Context);
   begin
      State.Working_Context_Status := Status;
      State.Working_Context_Message := To_Unbounded_String
        (Editor.Build_Working_Context.Build_Working_Context_Message (Status));
      State.Build_Working_Context_Label := To_Unbounded_String
        (Editor.Build_Working_Context.Build_Working_Context_Display_Label
           (State.Selected_Working_Context));
      State.Working_Context_Canonical_Path_If_Available :=
        State.Selected_Working_Context.Canonical_Path_If_Available;
   end Sync_Working_Context_Projection;

   function Current_Request_Identity
     (State : Public_Build_UI_State) return String
   is
      Result : Unbounded_String := To_Unbounded_String
        (Public_Build_Tool_Selection'Image (State.Selected_Build_Tool) & "|");
   begin
      Append (Result, To_String (State.Build_Target_Label));
      Append (Result, "|");
      Append (Result, Editor.Build_Working_Context.Request_Identity_Token
        (State.Selected_Working_Context));
      Append (Result, "|");
      Append (Result, Build_UI_Build_Mode'Image (State.Selected_Build_Mode));
      Append (Result, "|");
      Append (Result, Boolean'Image (State.Show_Diagnostics_On_Result));
      Append (Result, "|");
      Append (Result, Build_UI_Output_Capture_Limit'Image (State.Output_Capture_Limit));
      Append (Result, "|");
      Append (Result, Boolean'Image (State.Option_Verbose_Output));
      Append (Result, Boolean'Image (State.Option_Keep_Going));
      Append (Result, Boolean'Image (State.Option_Warnings_As_Errors));
      Append (Result, Boolean'Image (State.Option_Force_Rebuild));
      Append (Result, "|");
      Append (Result, To_String (State.Selected_Build_Candidate_Id));
      Append (Result, "|");
      for Arg of State.Structured_Arguments loop
         Append (Result, "[");
         Append (Result, To_String (Arg));
         Append (Result, "]");
      end loop;
      return To_String (Result);
   end Current_Request_Identity;

   procedure Refresh_Validation (State : in out Public_Build_UI_State) is
      Status : constant Public_Build_UI_Validation_Status :=
        Validate_Build_UI_State (State);
   begin
      Sync_Working_Context_Projection (State);
      State.Validation_Status := Status;
      State.Validation_Message := To_Unbounded_String (Validation_Message (Status));
   end Refresh_Validation;

   function Empty_Arguments return Build_UI_Argument_Vector is
   begin
      return Build_UI_Argument_Vectors.Empty_Vector;
   end Empty_Arguments;

   procedure Append_Argument
     (Arguments : in out Build_UI_Argument_Vector;
      Value     : String)
   is
   begin
      Arguments.Append (To_Unbounded_String (Value));
   end Append_Argument;

   function Argument_Count (Arguments : Build_UI_Argument_Vector) return Natural is
   begin
      return Natural (Arguments.Length);
   end Argument_Count;

   function Empty_State return Public_Build_UI_State is
   begin
      return (others => <>);
   end Empty_State;

   procedure Show (State : in out Public_Build_UI_State) is
   begin
      State.Build_UI_Visible := True;
      Refresh_Validation (State);
   end Show;

   procedure Focus (State : in out Public_Build_UI_State) is
   begin
      State.Build_UI_Visible := True;
      State.Build_UI_Focused := True;
      Refresh_Validation (State);
   end Focus;

   procedure Hide (State : in out Public_Build_UI_State) is
   begin
      State.Build_UI_Visible := False;
      State.Build_UI_Focused := False;
      State.Pending_Public_Build_Request := False;
      Refresh_Validation (State);
   end Hide;

   procedure Select_Tool
     (State : in out Public_Build_UI_State;
      Tool  : Public_Build_Tool_Selection)
   is
   begin
      if State.Selected_Build_Tool /= Tool then
         Invalidate_Consent (State);
         Clear_Candidate_Application (State);
      end if;
      State.Selected_Build_Tool := Tool;
      Refresh_Validation (State);
   end Select_Tool;

   procedure Set_Target_Label
     (State : in out Public_Build_UI_State;
      Label : String)
   is
   begin
      if To_String (State.Build_Target_Label) /= Label then
         Invalidate_Consent (State);
         Clear_Candidate_Application (State);
      end if;
      State.Build_Target_Label := To_Unbounded_String (Label);
      Refresh_Validation (State);
   end Set_Target_Label;

   procedure Select_Working_Context
     (State   : in out Public_Build_UI_State;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record)
   is
      Changed : constant Boolean :=
        Editor.Build_Working_Context.Request_Identity_Token
           (State.Selected_Working_Context) /=
         Editor.Build_Working_Context.Request_Identity_Token (Context);
   begin
      if Changed then
         Invalidate_Consent (State);
         if State.Candidate_Applied_To_Request then
            Clear_Candidate_Application
              (State, "No build candidate selected after working context change");
         end if;
      end if;
      State.Selected_Working_Context := Context;
      Sync_Working_Context_Projection (State);
      Refresh_Validation (State);
   end Select_Working_Context;

   procedure Set_Working_Context_Label
     (State : in out Public_Build_UI_State;
      Label : String)
   is
   begin
      Select_Working_Context
        (State, Editor.Build_Working_Context.Context_From_Explicit_Token (Label));
   end Set_Working_Context_Label;

   procedure Set_Structured_Arguments
     (State     : in out Public_Build_UI_State;
      Arguments : Build_UI_Argument_Vector)
   is
   begin
      Invalidate_Consent (State);
      Clear_Candidate_Application
        (State, "No build candidate selected after manual argv edit");
      State.Structured_Arguments := Arguments;
      Refresh_Validation (State);
   end Set_Structured_Arguments;

   procedure Set_Show_Diagnostics_On_Result
     (State : in out Public_Build_UI_State;
      Value : Boolean)
   is
   begin
      if State.Show_Diagnostics_On_Result /= Value then
         Invalidate_Consent (State);
      end if;
      State.Show_Diagnostics_On_Result := Value;
      if State.Candidate_Applied_To_Request then
         State.Candidate_Request_Preview := To_Unbounded_String
           (Build_Candidate_Request_Preview (State));
      end if;
      Refresh_Validation (State);
   end Set_Show_Diagnostics_On_Result;

   function Tool_From_Candidate
     (Tool : Editor.External_Producers.Build_Tool_Kind)
      return Public_Build_Tool_Selection
   is
   begin
      case Tool is
         when Editor.External_Producers.GPRbuild_Tool =>
            return Build_UI_GPRbuild;
         when Editor.External_Producers.Alire_Build_Tool =>
            return Build_UI_Alire;
         when Editor.External_Producers.Custom_Build_Tool =>
            return Build_UI_Custom_Disallowed_For_Now;
         when Editor.External_Producers.No_Build_Tool =>
            return Build_UI_No_Tool;
      end case;
   end Tool_From_Candidate;


   function Build_Mode_Label (Mode : Build_UI_Build_Mode) return String is
   begin
      case Mode is
         when Build_UI_Build_Mode_Default => return "default";
         when Build_UI_Build_Mode_Debug => return "debug";
         when Build_UI_Build_Mode_Release => return "release";
         when Build_UI_Build_Mode_Validation => return "validation";
      end case;
   end Build_Mode_Label;

   function Output_Capture_Limit_Bytes
     (Limit : Build_UI_Output_Capture_Limit) return Natural
   is
   begin
      case Limit is
         when Build_UI_Output_Capture_Small =>
            return 65_536;
         when Build_UI_Output_Capture_Normal =>
            return 262_144;
         when Build_UI_Output_Capture_Large =>
            return 1_048_576;
      end case;
   end Output_Capture_Limit_Bytes;

   function Output_Capture_Limit_Label
     (Limit : Build_UI_Output_Capture_Limit) return String
   is
   begin
      case Limit is
         when Build_UI_Output_Capture_Small =>
            return "small bounded output capture (65536 bytes)";
         when Build_UI_Output_Capture_Normal =>
            return "normal bounded output capture (262144 bytes)";
         when Build_UI_Output_Capture_Large =>
            return "large bounded output capture (1048576 bytes)";
      end case;
   end Output_Capture_Limit_Label;

   function Mode_Supported_For_Request
     (State : Public_Build_UI_State;
      Mode  : Build_UI_Build_Mode) return Boolean
   is
   begin
      --  Non-default build profiles are implemented only for selected
      --  tool-backed candidates with fixed, structured argv mappings.  GPRbuild
      --  uses compiler switches; Alire uses root-crate profile switches on
      --  ``alr build``.
      return Mode = Build_UI_Build_Mode_Default
        or else ((State.Selected_Build_Tool = Build_UI_GPRbuild
                  or else State.Selected_Build_Tool = Build_UI_Alire)
                 and then State.Candidate_Applied_To_Request);
   end Mode_Supported_For_Request;

   function Gpr_Flags_Supported_For_Request
     (State : Public_Build_UI_State) return Boolean
   is
   begin
      return State.Selected_Build_Tool = Build_UI_GPRbuild
        and then State.Candidate_Applied_To_Request;
   end Gpr_Flags_Supported_For_Request;

   function Option_Rows
     (State : Public_Build_UI_State) return Build_UI_Request_Option_Row_Vector
   is
      Rows : Build_UI_Request_Option_Row_Vector :=
        Build_UI_Request_Option_Row_Vectors.Empty_Vector;
      Flags_Supported : constant Boolean := Gpr_Flags_Supported_For_Request (State);
      Unsupported_Flags : constant Unbounded_String := To_Unbounded_String
        ("Fixed flag toggles are supported only for selected GPR candidates.");
   begin
      Rows.Append
        (Build_UI_Request_Option_Row'
          (Option_Name => To_Unbounded_String ("build.mode"),
          Option_Label => To_Unbounded_String (Build_Mode_Label (State.Selected_Build_Mode)),
          Enabled => True,
          Supported => Mode_Supported_For_Request (State, State.Selected_Build_Mode),
          Disabled_Reason =>
            (if Mode_Supported_For_Request (State, State.Selected_Build_Mode) then
                Null_Unbounded_String
             else
                To_Unbounded_String ("Non-default build modes require a selected GPRbuild or Alire candidate with a fixed profile mapping."))));
      Rows.Append
        (Build_UI_Request_Option_Row'
          (Option_Name => To_Unbounded_String ("build.diagnostics-ingestion.enabled"),
          Option_Label => To_Unbounded_String
            ((if State.Show_Diagnostics_On_Result then
                "Diagnostics ingestion enabled"
              else
                "Diagnostics ingestion disabled")),
          Enabled => State.Show_Diagnostics_On_Result,
          Supported => True,
          Disabled_Reason => Null_Unbounded_String));
      Rows.Append
        (Build_UI_Request_Option_Row'
          (Option_Name => To_Unbounded_String ("build.output-capture.limit"),
          Option_Label => To_Unbounded_String
            (Output_Capture_Limit_Label (State.Output_Capture_Limit)),
          Enabled => True,
          Supported => True,
          Disabled_Reason => Null_Unbounded_String));
      Rows.Append
        (Build_UI_Request_Option_Row'
          (Option_Name => To_Unbounded_String ("build.flag.verbose"),
          Option_Label => To_Unbounded_String ("verbose output"),
          Enabled => State.Option_Verbose_Output,
          Supported => Flags_Supported,
          Disabled_Reason => (if Flags_Supported then Null_Unbounded_String else Unsupported_Flags)));
      Rows.Append
        (Build_UI_Request_Option_Row'
          (Option_Name => To_Unbounded_String ("build.flag.keep-going"),
          Option_Label => To_Unbounded_String ("keep going"),
          Enabled => State.Option_Keep_Going,
          Supported => Flags_Supported,
          Disabled_Reason => (if Flags_Supported then Null_Unbounded_String else Unsupported_Flags)));
      return Rows;
   end Option_Rows;


   procedure Set_Fixed_Argument
     (Arguments : in out Build_UI_Argument_Vector;
      Token     : String;
      Enabled   : Boolean)
   is
      Found_Index : Natural := 0;
   begin
      for I in Arguments.First_Index .. Arguments.Last_Index loop
         if To_String (Arguments.Element (I)) = Token then
            Found_Index := I;
         end if;
      end loop;

      if Enabled and then Found_Index = 0 then
         Arguments.Append (To_Unbounded_String (Token));
      elsif (not Enabled) and then Found_Index /= 0 then
         Arguments.Delete (Found_Index);
      end if;
   exception
      when Constraint_Error =>
         if Enabled then
            Arguments.Append (To_Unbounded_String (Token));
         end if;
   end Set_Fixed_Argument;

   procedure Strip_Build_Mode_Arguments
     (Arguments : in out Build_UI_Argument_Vector)
   is
   begin
      Set_Fixed_Argument (Arguments, "-g", False);
      Set_Fixed_Argument (Arguments, "-O2", False);
      Set_Fixed_Argument (Arguments, "-gnatp", False);
      Set_Fixed_Argument (Arguments, "-gnata", False);
      Set_Fixed_Argument (Arguments, "-gnatwa", False);
      Set_Fixed_Argument (Arguments, "--development", False);
      Set_Fixed_Argument (Arguments, "--release", False);
      Set_Fixed_Argument (Arguments, "--validation", False);
   end Strip_Build_Mode_Arguments;

   procedure Apply_Build_Mode_Arguments
     (State : in out Public_Build_UI_State)
   is
   begin
      Strip_Build_Mode_Arguments (State.Structured_Arguments);

      if not Mode_Supported_For_Request (State, State.Selected_Build_Mode) then
         return;
      end if;

      case State.Selected_Build_Tool is
         when Build_UI_GPRbuild =>
            case State.Selected_Build_Mode is
               when Build_UI_Build_Mode_Default =>
                  null;
               when Build_UI_Build_Mode_Debug =>
                  Set_Fixed_Argument (State.Structured_Arguments, "-g", True);
               when Build_UI_Build_Mode_Release =>
                  Set_Fixed_Argument (State.Structured_Arguments, "-O2", True);
                  Set_Fixed_Argument (State.Structured_Arguments, "-gnatp", True);
               when Build_UI_Build_Mode_Validation =>
                  Set_Fixed_Argument (State.Structured_Arguments, "-gnata", True);
                  Set_Fixed_Argument (State.Structured_Arguments, "-gnatwa", True);
            end case;

         when Build_UI_Alire =>
            case State.Selected_Build_Mode is
               when Build_UI_Build_Mode_Default =>
                  null;
               when Build_UI_Build_Mode_Debug =>
                  Set_Fixed_Argument (State.Structured_Arguments, "--development", True);
               when Build_UI_Build_Mode_Release =>
                  Set_Fixed_Argument (State.Structured_Arguments, "--release", True);
               when Build_UI_Build_Mode_Validation =>
                  Set_Fixed_Argument (State.Structured_Arguments, "--validation", True);
            end case;

         when Build_UI_No_Tool | Build_UI_Custom_Disallowed_For_Now =>
            null;
      end case;
   end Apply_Build_Mode_Arguments;

   function Convert_Candidate_Arguments
     (Arguments : Editor.Build_Candidates.Build_Candidate_Argument_Vector)
      return Build_UI_Argument_Vector
   is
      Result : Build_UI_Argument_Vector := Empty_Arguments;
   begin
      for Arg of Arguments loop
         Result.Append (Arg);
      end loop;
      return Result;
   end Convert_Candidate_Arguments;

   procedure Set_Build_Candidates
     (State      : in out Public_Build_UI_State;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector;
      Message    : String := "")
   is
   begin
      State.Build_Candidates := Candidates;
      Clear_Candidate_Application (State, "No build candidate selected");
      Invalidate_Consent (State);
      State.Candidate_Discovery_Message := To_Unbounded_String (Message);
      Refresh_Validation (State);
   end Set_Build_Candidates;

   function Build_Candidate_Request_Preview
     (State : Public_Build_UI_State) return String
   is
      Result : Unbounded_String := To_Unbounded_String ("tool=");
   begin
      Append (Result, Public_Build_Tool_Selection'Image (State.Selected_Build_Tool));
      Append (Result, "; argv=");
      for Arg of State.Structured_Arguments loop
         Append (Result, "[");
         Append (Result, To_String (Arg));
         Append (Result, "]");
      end loop;
      Append (Result, "; working-context=");
      Append (Result, Editor.Build_Working_Context.Build_Working_Context_Display_Label
        (State.Selected_Working_Context));
      if To_String (State.Selected_Build_Candidate_Id)'Length > 0 then
         Append (Result, "; candidate-label=");
         Append (Result, To_String (State.Build_Target_Label));
      end if;
      Append (Result, "; mode=");
      Append (Result, Build_Mode_Label (State.Selected_Build_Mode));
      Append (Result, "; diagnostics=");
      Append (Result, Boolean'Image (State.Show_Diagnostics_On_Result));
      Append (Result, "; output-limit=");
      Append (Result, Output_Capture_Limit_Label (State.Output_Capture_Limit));
      Append (Result, "; flags=");
      if State.Option_Verbose_Output then
         Append (Result, "[verbose]");
      end if;
      if State.Option_Keep_Going then
         Append (Result, "[keep-going]");
      end if;
      --  The request preview shows only fixed, structured tokens owned by the
      --  build UI.  Build modes, verbose output, and keep-going are represented
      --  as explicit argv tokens; warning/error and force-rebuild toggles remain
      --  inert until a safe fixed-token mapping is added for them.
      Append (Result, "; policy=bounded-non-shell-executor");
      return To_String (Result);
   end Build_Candidate_Request_Preview;

   procedure Apply_Build_Candidate_To_UI_State
     (State     : in out Public_Build_UI_State;
      Candidate : Editor.Build_Candidates.Build_Candidate_Record)
   is
      Status : constant Editor.Build_Candidates.Build_Candidate_Validation_Status :=
        Editor.Build_Candidates.Validate_Candidate (Candidate);
   begin
      Invalidate_Consent (State);
      State.Selected_Build_Candidate_Status := Status;

      if Status /= Editor.Build_Candidates.Build_Candidate_Valid then
         Clear_Candidate_Application (State, "Build candidate rejected");
         State.Selected_Build_Candidate_Status := Status;
         Refresh_Validation (State);
         return;
      end if;

      State.Selected_Build_Candidate_Id := Candidate.Candidate_Id;
      State.Selected_Build_Tool := Tool_From_Candidate (Candidate.Tool_Kind);
      State.Structured_Arguments :=
        Convert_Candidate_Arguments (Candidate.Structured_Arguments);
      State.Selected_Build_Mode := Build_UI_Build_Mode_Default;
      State.Output_Capture_Limit := Build_UI_Output_Capture_Normal;
      State.Option_Verbose_Output := False;
      State.Option_Keep_Going := False;
      State.Option_Warnings_As_Errors := False;
      State.Option_Force_Rebuild := False;
      State.Selected_Working_Context := Candidate.Working_Context;
      State.Build_Target_Label := Candidate.Display_Label;
      State.Candidate_Applied_To_Request := True;
      State.Candidate_Selection_Message := To_Unbounded_String
        ("Build candidate applied to transient request; Consent missing: review and acknowledge the build request");
      Sync_Working_Context_Projection (State);
      State.Candidate_Request_Preview := To_Unbounded_String
        (Build_Candidate_Request_Preview (State));
      Refresh_Validation (State);
   end Apply_Build_Candidate_To_UI_State;

   procedure Select_Build_Candidate
     (State        : in out Public_Build_UI_State;
      Candidate_Id : String)
   is
   begin
      for Candidate of State.Build_Candidates loop
         if To_String (Candidate.Candidate_Id) = Candidate_Id then
            Apply_Build_Candidate_To_UI_State (State, Candidate);
            return;
         end if;
      end loop;

      Invalidate_Consent (State);
      Clear_Candidate_Application (State, "Build candidate not found");
      Refresh_Validation (State);
   end Select_Build_Candidate;

   procedure Clear_Selected_Build_Candidate
     (State : in out Public_Build_UI_State)
   is
   begin
      Invalidate_Consent (State);
      Clear_Candidate_Application (State, "No build candidate selected");
      Refresh_Validation (State);
   end Clear_Selected_Build_Candidate;

   function Candidate_Count
     (State : Public_Build_UI_State) return Natural
   is
   begin
      return Natural (State.Build_Candidates.Length);
   end Candidate_Count;


   procedure Set_Build_Mode
     (State : in out Public_Build_UI_State;
      Mode  : Build_UI_Build_Mode)
   is
   begin
      if State.Selected_Build_Mode /= Mode then
         State.Selected_Build_Mode := Mode;
         Apply_Build_Mode_Arguments (State);
         Invalidate_Consent (State);
         if State.Candidate_Applied_To_Request then
            State.Candidate_Request_Preview := To_Unbounded_String
              (Build_Candidate_Request_Preview (State));
         end if;
      end if;
      Refresh_Validation (State);
   end Set_Build_Mode;

   procedure Toggle_Diagnostics_Ingestion
     (State : in out Public_Build_UI_State)
   is
   begin
      Set_Show_Diagnostics_On_Result
        (State, not State.Show_Diagnostics_On_Result);
   end Toggle_Diagnostics_Ingestion;

   procedure Cycle_Output_Capture_Limit
     (State : in out Public_Build_UI_State)
   is
   begin
      case State.Output_Capture_Limit is
         when Build_UI_Output_Capture_Small =>
            State.Output_Capture_Limit := Build_UI_Output_Capture_Normal;
         when Build_UI_Output_Capture_Normal =>
            State.Output_Capture_Limit := Build_UI_Output_Capture_Large;
         when Build_UI_Output_Capture_Large =>
            State.Output_Capture_Limit := Build_UI_Output_Capture_Small;
      end case;
      Invalidate_Consent (State);
      if State.Candidate_Applied_To_Request then
         State.Candidate_Request_Preview := To_Unbounded_String
           (Build_Candidate_Request_Preview (State));
      end if;
      Refresh_Validation (State);
   end Cycle_Output_Capture_Limit;

   procedure Toggle_Verbose_Output
     (State : in out Public_Build_UI_State)
   is
   begin
      if not Gpr_Flags_Supported_For_Request (State) then
         Refresh_Validation (State);
         return;
      end if;
      State.Option_Verbose_Output := not State.Option_Verbose_Output;
      Set_Fixed_Argument
        (State.Structured_Arguments, "-v", State.Option_Verbose_Output);
      Invalidate_Consent (State);
      if State.Candidate_Applied_To_Request then
         State.Candidate_Request_Preview := To_Unbounded_String
           (Build_Candidate_Request_Preview (State));
      end if;
      Refresh_Validation (State);
   end Toggle_Verbose_Output;

   procedure Toggle_Keep_Going
     (State : in out Public_Build_UI_State)
   is
   begin
      if not Gpr_Flags_Supported_For_Request (State) then
         Refresh_Validation (State);
         return;
      end if;
      State.Option_Keep_Going := not State.Option_Keep_Going;
      Set_Fixed_Argument
        (State.Structured_Arguments, "-k", State.Option_Keep_Going);
      Invalidate_Consent (State);
      if State.Candidate_Applied_To_Request then
         State.Candidate_Request_Preview := To_Unbounded_String
           (Build_Candidate_Request_Preview (State));
      end if;
      Refresh_Validation (State);
   end Toggle_Keep_Going;

   procedure Toggle_Warnings_As_Errors
     (State : in out Public_Build_UI_State)
   is
   begin
      --  Phase 554 does not expose this flag as an implemented request option:
      --  there is no retained fixed argv-token mapping here, so the command is
      --  a no-op rather than a hidden/freeform argument path.
      State.Option_Warnings_As_Errors := False;
      Refresh_Validation (State);
   end Toggle_Warnings_As_Errors;

   procedure Toggle_Force_Rebuild
     (State : in out Public_Build_UI_State)
   is
   begin
      --  Phase 554 does not expose this flag as an implemented request option:
      --  there is no retained fixed argv-token mapping here, so the command is
      --  a no-op rather than a hidden/freeform argument path.
      State.Option_Force_Rebuild := False;
      Refresh_Validation (State);
   end Toggle_Force_Rebuild;

   procedure Acknowledge_Consent (State : in out Public_Build_UI_State) is
   begin
      State.Consent_Acknowledged := True;
      State.Consent_Request_Identity := To_Unbounded_String
        (Current_Request_Identity (State));
      if Validate_Build_UI_State (State) /= Build_UI_Valid then
         State.Consent_Acknowledged := False;
         State.Consent_Request_Identity := Null_Unbounded_String;
      end if;
      Refresh_Validation (State);
   end Acknowledge_Consent;

   procedure Clear_Consent (State : in out Public_Build_UI_State) is
   begin
      State.Consent_Acknowledged := False;
      State.Consent_Request_Identity := Null_Unbounded_String;
      State.Pending_Public_Build_Request := False;
      Refresh_Validation (State);
   end Clear_Consent;

   function Validate_Build_UI_State
     (State : Public_Build_UI_State) return Public_Build_UI_Validation_Status
   is
   begin
      if not State.Build_UI_Visible then
         return Build_UI_Rejected_Not_Visible;
      end if;

      if not Arguments_Are_Structured_And_Safe (State.Structured_Arguments) then
         return Build_UI_Rejected_Unsafe_Arguments;
      end if;

      if (not State.Candidate_Applied_To_Request)
        or else To_String (State.Selected_Build_Candidate_Id)'Length = 0
      then
         return Build_UI_Rejected_No_Candidate_Selected;
      end if;

      if State.Selected_Candidate_Stale
        or else State.Selected_Build_Candidate_Status /=
          Editor.Build_Candidates.Build_Candidate_Valid
      then
         return Build_UI_Rejected_Selected_Candidate_Stale;
      end if;

      case State.Selected_Build_Tool is
         when Build_UI_No_Tool =>
            return Build_UI_Rejected_No_Tool;
         when Build_UI_Custom_Disallowed_For_Now =>
            return Build_UI_Rejected_Custom_Tool;
         when Build_UI_GPRbuild | Build_UI_Alire =>
            null;
      end case;

      if not Mode_Supported_For_Request (State, State.Selected_Build_Mode) then
         return Build_UI_Rejected_Unsupported_Request_Option;
      end if;

      if State.Option_Warnings_As_Errors or else State.Option_Force_Rebuild then
         return Build_UI_Rejected_Unsupported_Request_Option;
      end if;

      if (State.Option_Verbose_Output or else State.Option_Keep_Going)
        and then not Gpr_Flags_Supported_For_Request (State)
      then
         return Build_UI_Rejected_Unsupported_Request_Option;
      end if;

      declare
         Working_Status : constant Editor.Build_Working_Context.Build_Working_Context_Validation_Status :=
           Editor.Build_Working_Context.Validate_Build_Working_Context
             (State.Selected_Working_Context);
      begin
         case Working_Status is
            when Editor.Build_Working_Context.Build_Working_Context_Valid =>
               null;
            when Editor.Build_Working_Context.Build_Working_Context_Rejected_None =>
               return Build_UI_Rejected_Working_Context_Required;
            when Editor.Build_Working_Context.Build_Working_Context_Rejected_Unavailable =>
               return Build_UI_Rejected_Working_Context_Unavailable;
            when others =>
               return Build_UI_Rejected_Unsafe_Working_Context;
         end case;
      end;

      if not State.Consent_Acknowledged then
         return Build_UI_Rejected_Missing_Consent;
      end if;

      if To_String (State.Consent_Request_Identity) /= Current_Request_Identity (State) then
         return Build_UI_Rejected_Stale_Consent;
      end if;

      return Build_UI_Valid;
   end Validate_Build_UI_State;

   function Validation_Message
     (Status : Public_Build_UI_Validation_Status) return String
   is
   begin
      case Status is
         when Build_UI_Valid =>
            return "Build request ready";
         when Build_UI_Rejected_Not_Visible =>
            return "Build Output is closed; open Build Output before running build.run.";
         when Build_UI_Rejected_No_Tool =>
            return "Build run unavailable: choose a build tool first";
         when Build_UI_Rejected_Custom_Tool =>
            return "Build run unavailable: custom shell commands are not supported";
         when Build_UI_Rejected_No_Candidate_Selected =>
            return "Build run unavailable: no build candidate selected";
         when Build_UI_Rejected_Selected_Candidate_Stale =>
            return "Build run unavailable: selected build candidate is stale";
         when Build_UI_Rejected_Missing_Consent =>
            return "Build run unavailable: review the request and acknowledge consent first";
         when Build_UI_Rejected_Unsafe_Arguments =>
            return "Build run unavailable: arguments must be structured tokens, not shell text";
         when Build_UI_Rejected_Unsupported_Request_Option =>
            return "Build run unavailable: request option is not supported for the selected candidate";
         when Build_UI_Rejected_Working_Context_Required =>
            return "Build run unavailable: no project working context selected";
         when Build_UI_Rejected_Working_Context_Unavailable =>
            return "Build run unavailable: selected project working context is unavailable";
         when Build_UI_Rejected_Unsafe_Working_Context =>
            return "Build run unavailable: working context must come from the current project/workspace";
         when Build_UI_Rejected_Stale_Consent =>
            return "Build run unavailable: consent is stale after the request changed";
         when Build_UI_Rejected_Execution_Backend_Disabled =>
            return "Build run unavailable: execution backend is disabled";
      end case;
   end Validation_Message;


   function Tool_Label
     (Tool : Public_Build_Tool_Selection) return String
   is
   begin
      case Tool is
         when Build_UI_No_Tool => return "no build tool selected";
         when Build_UI_GPRbuild => return "gprbuild";
         when Build_UI_Alire => return "alire";
         when Build_UI_Custom_Disallowed_For_Now => return "custom command disabled";
      end case;
   end Tool_Label;

   function Candidate_Kind_Label
     (Kind : Editor.Build_Candidates.Build_Candidate_Kind) return String
   is
   begin
      case Kind is
         when Editor.Build_Candidates.Build_Candidate_None =>
            return "none";
         when Editor.Build_Candidates.Build_Candidate_Alire_Project =>
            return "alire project";
         when Editor.Build_Candidates.Build_Candidate_Gpr_Project =>
            return "gpr project";
         when Editor.Build_Candidates.Build_Candidate_Manual_Request =>
            return "manual request";
      end case;
   end Candidate_Kind_Label;

   function External_Tool_Label
     (Tool : Editor.External_Producers.Build_Tool_Kind) return String
   is
   begin
      return Tool_Label (Tool_From_Candidate (Tool));
   end External_Tool_Label;

   function Candidate_Validation_Label
     (Status : Editor.Build_Candidates.Build_Candidate_Validation_Status)
      return String
   is
   begin
      case Status is
         when Editor.Build_Candidates.Build_Candidate_Valid =>
            return "candidate ready";
         when Editor.Build_Candidates.Build_Candidate_Unavailable =>
            return "candidate unavailable: source project context is unavailable";
         when Editor.Build_Candidates.Build_Candidate_Rejected_Unstructured =>
            return "candidate rejected: request is not structured";
         when Editor.Build_Candidates.Build_Candidate_Rejected_Unsafe_Source =>
            return "candidate rejected: source is outside the project context";
         when Editor.Build_Candidates.Build_Candidate_Rejected_Shell_Text =>
            return "candidate rejected: shell command text is not allowed";
         when Editor.Build_Candidates.Build_Candidate_Rejected_Persisted_State =>
            return "candidate rejected: candidates are transient and must be refreshed";
      end case;
   end Candidate_Validation_Label;

   function Refresh_Status_Label
     (Status : Build_Candidate_Refresh_Status) return String
   is
   begin
      case Status is
         when Build_Candidate_Refresh_Not_Requested =>
            return "Build candidates not refreshed yet";
         when Build_Candidate_Refresh_Succeeded =>
            return "Build candidates refreshed";
         when Build_Candidate_Refresh_No_Project_Context =>
            return "No project open.";
         when Build_Candidate_Refresh_No_Candidates =>
            return "Build candidates refreshed: no candidates";
         when Build_Candidate_Refresh_Failed =>
            return "Build candidate refresh failed";
      end case;
   end Refresh_Status_Label;

   function Consent_Label
     (State : Public_Build_UI_State) return String
   is
   begin
      if State.Consent_Acknowledged
        and then To_String (State.Consent_Request_Identity) =
          Current_Request_Identity (State)
      then
         return "Consent acknowledged for current build request";
      elsif State.Consent_Acknowledged then
         return "Consent stale: review the changed build request";
      else
         return "Consent missing: review and acknowledge the build request";
      end if;
   end Consent_Label;

   function Working_Context_Kind_Label
     (Kind : Editor.Build_Working_Context.Build_Working_Context_Kind)
      return String
   is
   begin
      return Editor.Build_Working_Context.Build_Working_Context_Kind'Image (Kind);
   end Working_Context_Kind_Label;

   function Build_Candidate_Rows
     (State : Public_Build_UI_State) return Build_UI_Candidate_Row_Vector
   is
      Rows : Build_UI_Candidate_Row_Vector :=
        Build_UI_Candidate_Row_Vectors.Empty_Vector;
      Selected_Id : constant String := To_String (State.Selected_Build_Candidate_Id);
   begin
      for Candidate of State.Build_Candidates loop
         declare
            Candidate_Id : constant String := To_String (Candidate.Candidate_Id);
            Selected : constant Boolean :=
              Selected_Id'Length > 0 and then Candidate_Id = Selected_Id;
            Source : constant String :=
              Editor.Build_Candidates.Build_Candidate_Source_Kind_Label
                (Candidate.Discovery_Source) & ": " &
              Editor.Build_Candidates.Build_Candidate_Project_Relative_Label
                (Candidate);
            Disabled : constant String :=
              Editor.Build_Candidates.Build_Candidate_Disabled_Reason (Candidate);
         begin
            Rows.Append
              (Build_UI_Candidate_Row'
                (Candidate_Id => Candidate.Candidate_Id,
                Display_Label => Candidate.Display_Label,
                Candidate_Kind_Label => To_Unbounded_String
                  (Candidate_Kind_Label (Candidate.Candidate_Kind)),
                Tool_Kind_Label => To_Unbounded_String
                  (External_Tool_Label (Candidate.Tool_Kind)),
                Source_Label => To_Unbounded_String (Source),
                Selected => Selected,
                Stale => Selected and then State.Selected_Candidate_Stale,
                Validation_Label => To_Unbounded_String
                  ((if Disabled'Length > 0 then Disabled
                    else Candidate_Validation_Label
                      (Editor.Build_Candidates.Validate_Candidate (Candidate))))));
         end;
      end loop;
      return Rows;
   end Build_Candidate_Rows;

   function Build_Request_Preview
     (State : Public_Build_UI_State) return Build_UI_Request_Preview
   is
      Mode : constant Build_UI_Request_Mode :=
        (if State.Candidate_Applied_To_Request then
            Build_UI_Request_Mode_Candidate_Derived
         else
            Build_UI_Request_Mode_Manual);
   begin
      return
        (Request_Mode => Mode,
         Request_Mode_Label => To_Unbounded_String
           ((if Mode = Build_UI_Request_Mode_Candidate_Derived then
               "candidate-derived"
             else
               "no selected candidate")),
         Tool_Kind_Label => To_Unbounded_String
           (Tool_Label (State.Selected_Build_Tool)),
         Argv_Tokens => State.Structured_Arguments,
         Working_Context_Label => To_Unbounded_String
           (Editor.Build_Working_Context.Build_Working_Context_Display_Label
              (State.Selected_Working_Context)),
         Selected_Candidate_Label =>
           (if To_String (State.Selected_Build_Candidate_Id)'Length = 0 then
               Null_Unbounded_String
            else
               State.Build_Target_Label),
         Build_Mode_Label => To_Unbounded_String
           (Build_Mode_Label (State.Selected_Build_Mode)),
         Diagnostics_Label => To_Unbounded_String
           ((if State.Show_Diagnostics_On_Result then
               "Diagnostics requested after build"
             else
               "Diagnostics not requested after build")),
         Output_Capture_Limit_Label => To_Unbounded_String
           (Output_Capture_Limit_Label (State.Output_Capture_Limit)),
         Request_Option_Rows => Option_Rows (State),
         Request_Identity_Label => To_Unbounded_String
           (Current_Request_Identity (State)),
         Consent_Label => To_Unbounded_String (Consent_Label (State)),
         Availability_Label => To_Unbounded_String
           (Validation_Message (Validate_Build_UI_State (State))));
   end Build_Request_Preview;

   function Build_Working_Context_View
     (State : Public_Build_UI_State) return Build_UI_Working_Context_View
   is
      Status : constant Editor.Build_Working_Context.Build_Working_Context_Validation_Status :=
        Editor.Build_Working_Context.Validate_Build_Working_Context
          (State.Selected_Working_Context);
      Message : constant String :=
        Editor.Build_Working_Context.Build_Working_Context_Message (Status);
   begin
      return
        (Kind_Label => To_Unbounded_String
           (Working_Context_Kind_Label (State.Selected_Working_Context.Kind)),
         Display_Label => To_Unbounded_String
           (Editor.Build_Working_Context.Build_Working_Context_Display_Label
              (State.Selected_Working_Context)),
         Validation_Label => To_Unbounded_String (Message),
         Unavailable_Reason =>
           (if Status = Editor.Build_Working_Context.Build_Working_Context_Valid then
               Null_Unbounded_String
            else
               To_Unbounded_String (Message)));
   end Build_Working_Context_View;


   function Build_Diagnostics_View
     (Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary)
      return Build_UI_Diagnostics_View
   is
      use type Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status;
      Status : constant Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status :=
        Summary.Diagnostics_Ingestion_Status;
      Count_Text : constant String :=
        (if Summary.Has_Diagnostics_Count
            and then Summary.Diagnostics_Count_If_Available > 0 then
            (if Summary.Has_Diagnostics_Severity_Counts then
                "Diagnostics produced: " & Natural'Image
                  (Summary.Diagnostics_Count_If_Available)
                  & " (errors " & Natural'Image (Summary.Diagnostics_Error_Count)
                  & ", warnings " & Natural'Image (Summary.Diagnostics_Warning_Count)
                  & ", info " & Natural'Image (Summary.Diagnostics_Info_Count)
                  & ", notes " & Natural'Image (Summary.Diagnostics_Note_Count)
                  & ", unknown " & Natural'Image (Summary.Diagnostics_Unknown_Count)
                  & ")"
             else
                "Diagnostics produced: " & Natural'Image
                  (Summary.Diagnostics_Count_If_Available))
         elsif Summary.Has_Diagnostics_Count
            and then Summary.Diagnostics_Count_If_Available = 0 then
            "No diagnostics."
         elsif Status = Editor.Build_Result_Summary.Diagnostics_Ingestion_No_Diagnostics then
            "No diagnostics."
         elsif Status = Editor.Build_Result_Summary.Diagnostics_Ingestion_Not_Requested then
            "Diagnostics not requested"
         elsif Status = Editor.Build_Result_Summary.Diagnostics_Ingestion_Disabled then
            "Diagnostics ingestion disabled"
         elsif Status = Editor.Build_Result_Summary.Diagnostics_Ingestion_Failed then
            "Diagnostics ingestion failed"
         else
            "Diagnostics status unavailable");
      Can_Reveal : constant Boolean :=
        (Status in Editor.Build_Result_Summary.Diagnostics_Ingestion_Succeeded |
                   Editor.Build_Result_Summary.Diagnostics_Ingestion_Parse_Partial)
        and then Summary.Has_Diagnostics_Count
        and then Summary.Diagnostics_Count_If_Available > 0;
   begin
      return
        (Status_Label => To_Unbounded_String
           (Editor.Build_Result_Summary.Diagnostics_Label (Summary)),
         Count_Label => To_Unbounded_String (Count_Text),
         Reveal_Available => Can_Reveal,
         Reveal_Command_Name =>
           (if Can_Reveal then To_Unbounded_String ("diagnostics.show")
            else Null_Unbounded_String),
         Reveal_Label =>
           (if Can_Reveal then To_Unbounded_String ("Reveal Diagnostics")
            else To_Unbounded_String ("No diagnostics to reveal yet")));
   end Build_Diagnostics_View;

   function Build_Render_Snapshot
     (State   : Public_Build_UI_State;
      Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Build_UI_Render_Snapshot
   is
      Status : constant Public_Build_UI_Validation_Status :=
        Validate_Build_UI_State (State);
      Consent_Text : constant String := Consent_Label (State);
      Rows : constant Build_UI_Candidate_Row_Vector := Build_Candidate_Rows (State);
   begin
      return
        (Visible => State.Build_UI_Visible,
         Focused => State.Build_UI_Focused,
         No_Project =>
           State.Candidate_Refresh_Status = Build_Candidate_Refresh_No_Project_Context,
         No_Candidates => Natural (State.Build_Candidates.Length) = 0,
         Candidate_Count => Natural (State.Build_Candidates.Length),
         Candidates => Rows,
         Refresh_Status_Label => To_Unbounded_String
           (Refresh_Status_Label (State.Candidate_Refresh_Status)),
         Refresh_Message => State.Candidate_Refresh_Message,
         Request_Preview => Build_Request_Preview (State),
         Working_Context => Build_Working_Context_View (State),
         Consent_Required => Consent_Text = "Consent missing: review and acknowledge the build request",
         Consent_Stale => Consent_Text = "Consent stale: review the changed build request",
         Consent_Acknowledged => Consent_Text = "Consent acknowledged for current build request",
         Run_Available => Status = Build_UI_Valid,
         Run_Availability_Label => To_Unbounded_String
           (Validation_Message (Status)),
         Latest_Result => Editor.Build_Result_Summary.Render_Snapshot (Summary),
         Output_Details => Editor.Build_Output_Details.Render_Snapshot (Details),
         Diagnostics_View => Build_Diagnostics_View (Summary));
   end Build_Render_Snapshot;

   function Assert_Build_UI_Render_Snapshot_Is_Operable
     (Snapshot : Build_UI_Render_Snapshot) return Boolean
   is
   begin
      return (if Snapshot.Visible then
               (if Snapshot.Run_Available then
                  Length (Snapshot.Request_Preview.Tool_Kind_Label) > 0
                    and then Length (Snapshot.Request_Preview.Working_Context_Label) > 0
                else
                  Length (Snapshot.Request_Preview.Request_Mode_Label) > 0)
                 and then Length (Snapshot.Request_Preview.Consent_Label) > 0
                 and then Length (Snapshot.Run_Availability_Label) > 0
                 and then Snapshot.Candidate_Count = Natural (Snapshot.Candidates.Length)
              else
                 Snapshot.Candidate_Count = Natural (Snapshot.Candidates.Length));
   end Assert_Build_UI_Render_Snapshot_Is_Operable;

   function Assert_Build_UI_Result_Output_Diagnostics_Useful
     (Snapshot : Build_UI_Render_Snapshot) return Boolean
   is
   begin
      return (if Snapshot.Latest_Result.Latest_Build_Result_Visible then
                Length (Snapshot.Latest_Result.Latest_Build_Result_Status_Label) > 0
                and then Length (Snapshot.Latest_Result.Latest_Build_Result_Runner_Status_Label) > 0
                and then Length (Snapshot.Latest_Result.Latest_Build_Result_Diagnostics_Label) > 0
                and then Length (Snapshot.Latest_Result.Latest_Build_Result_Primary_Message_Label) > 0
             else
                True)
        and then (if Snapshot.Output_Details.Output_Details_Visible
                    or else Snapshot.Output_Details.Output_Details_Available then
                     Length (Snapshot.Output_Details.Output_Details_Status_Label) > 0
                     and then Length (Snapshot.Output_Details.No_Output_Label) > 0
                     and then Length (Snapshot.Output_Details.Stdout_Truncation_Label) > 0
                     and then Length (Snapshot.Output_Details.Stderr_Truncation_Label) > 0
                     and then Length (Snapshot.Output_Details.Partial_Output_Label) > 0
                  else
                     True)
        and then Length (Snapshot.Diagnostics_View.Status_Label) > 0
        and then Length (Snapshot.Diagnostics_View.Count_Label) > 0
        and then (not Snapshot.Diagnostics_View.Reveal_Available
                  or else To_String (Snapshot.Diagnostics_View.Reveal_Command_Name) =
                    "diagnostics.show");
   end Assert_Build_UI_Result_Output_Diagnostics_Useful;

   function Assert_Public_Build_Result_Output_UI_Coherent
     (State   : Public_Build_UI_State;
      Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Boolean
   is
      Snapshot : constant Build_UI_Render_Snapshot :=
        Build_Render_Snapshot (State, Summary, Details);
   begin
      return Assert_Build_UI_Render_Snapshot_Is_Operable (Snapshot)
        and then Assert_Build_UI_Result_Output_Diagnostics_Useful (Snapshot)
        and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Useful_For_Build_UI
          (Summary)
        and then Editor.Build_Output_Details.Assert_Build_Output_Details_Useful_For_Build_UI
          (Details)
        and then Assert_Build_UI_State_Is_Transient (State);
   end Assert_Public_Build_Result_Output_UI_Coherent;

   function Has_Raw_Shell_Command_Field
     (State : Public_Build_UI_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      return False;
   end Has_Raw_Shell_Command_Field;

   function Has_Remembered_Consent_Field
     (State : Public_Build_UI_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      return False;
   end Has_Remembered_Consent_Field;

   function Has_Candidate_Execution_Field
     (State : Public_Build_UI_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      return False;
   end Has_Candidate_Execution_Field;

   function Command_Palette_Can_Supply_Candidate
     (State : Public_Build_UI_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      return False;
   end Command_Palette_Can_Supply_Candidate;

   function Keybinding_Can_Supply_Candidate
     (State : Public_Build_UI_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      return False;
   end Keybinding_Can_Supply_Candidate;

   function Assert_Build_UI_State_Is_Transient
     (State : Public_Build_UI_State) return Boolean
   is
   begin
      return not Has_Raw_Shell_Command_Field (State)
        and then not Has_Remembered_Consent_Field (State)
        and then not Has_Candidate_Execution_Field (State)
        and then not Command_Palette_Can_Supply_Candidate (State)
        and then not Keybinding_Can_Supply_Candidate (State)
        and then Editor.Build_Candidates.Assert_Build_Candidate_List_Is_Deterministic
          (State.Build_Candidates)
        and then Editor.Build_Working_Context.Assert_Build_Working_Context_Is_Transient
          (State.Selected_Working_Context)
        and then Editor.Build_Working_Context.Assert_Build_Working_Context_Persistence_Excluded
          (State.Selected_Working_Context);
   end Assert_Build_UI_State_Is_Transient;



   function Assert_Build_Request_Is_Structured
     (State : Public_Build_UI_State) return Boolean
   is
   begin
      return not Has_Raw_Shell_Command_Field (State)
        and then Arguments_Are_Structured_And_Safe (State.Structured_Arguments)
        and then Tool_Label (State.Selected_Build_Tool)'Length > 0
        and then Output_Capture_Limit_Label (State.Output_Capture_Limit)'Length > 0;
   end Assert_Build_Request_Is_Structured;

   function Assert_Build_Request_Options_Are_Candidate_Specific
     (State : Public_Build_UI_State) return Boolean
   is
      Rows : constant Build_UI_Request_Option_Row_Vector := Option_Rows (State);
   begin
      if Rows.Length = 0 then
         return False;
      end if;
      if State.Option_Warnings_As_Errors or else State.Option_Force_Rebuild then
         return False;
      elsif Validate_Build_UI_State (State) = Build_UI_Rejected_Unsupported_Request_Option then
         return False;
      elsif State.Selected_Build_Tool = Build_UI_Alire then
         return not State.Option_Verbose_Output
           and then not State.Option_Keep_Going;
      elsif State.Selected_Build_Tool = Build_UI_GPRbuild then
         return State.Candidate_Applied_To_Request;
      else
         return not State.Candidate_Applied_To_Request;
      end if;
   end Assert_Build_Request_Options_Are_Candidate_Specific;

   function Assert_Build_Request_Preview_Matches_Tokens
     (Snapshot : Build_UI_Render_Snapshot) return Boolean
   is
   begin
      return Length (Snapshot.Request_Preview.Tool_Kind_Label) > 0
        and then Length (Snapshot.Request_Preview.Working_Context_Label) > 0
        and then Length (Snapshot.Request_Preview.Build_Mode_Label) > 0
        and then Length (Snapshot.Request_Preview.Diagnostics_Label) > 0
        and then Length (Snapshot.Request_Preview.Output_Capture_Limit_Label) > 0
        and then Natural (Snapshot.Request_Preview.Request_Option_Rows.Length) >= 3;
   end Assert_Build_Request_Preview_Matches_Tokens;

   function Assert_Build_Consent_Tied_To_Request_Identity
     (State : Public_Build_UI_State) return Boolean
   is
   begin
      return (if State.Consent_Acknowledged then
                 To_String (State.Consent_Request_Identity) =
                   Current_Request_Identity (State)
              else
                 Length (State.Consent_Request_Identity) = 0);
   end Assert_Build_Consent_Tied_To_Request_Identity;

   function Assert_Build_Request_State_Not_Persisted
     (State : Public_Build_UI_State) return Boolean
   is
   begin
      return Assert_Build_UI_State_Is_Transient (State)
        and then not Has_Remembered_Consent_Field (State)
        and then not Has_Candidate_Execution_Field (State);
   end Assert_Build_Request_State_Not_Persisted;

   function Assert_Build_Request_Configuration_Coherent
     (State   : Public_Build_UI_State;
      Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Boolean
   is
      Snapshot : constant Build_UI_Render_Snapshot :=
        Build_Render_Snapshot (State, Summary, Details);
   begin
      return Assert_Build_Request_Is_Structured (State)
        and then Assert_Build_Request_Options_Are_Candidate_Specific (State)
        and then Assert_Build_Request_Preview_Matches_Tokens (Snapshot)
        and then Assert_Build_Consent_Tied_To_Request_Identity (State)
        and then Assert_Build_Request_State_Not_Persisted (State)
        and then Assert_Public_Build_Result_Output_UI_Coherent
          (State, Summary, Details);
   end Assert_Build_Request_Configuration_Coherent;

end Editor.Build_UI;
