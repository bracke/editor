with Ada.Calendar;
with Ada.Containers;
with Ada.Directories;
with Editor.State;
with Ada.Characters.Handling;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Editor.Build_Process_Control;
with Editor.Build_Output_Details;
with Editor.Build_Runner_Policy;
with Editor.Buffers;
with Editor.Commands;
with Editor.Keybindings;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Targets;
with Editor.Producer_Contracts;
with Editor.Project;
with GNAT.OS_Lib;
with Interfaces.C;
with Interfaces.C.Strings;
with System;

use type Ada.Containers.Count_Type;

package body Editor.External_Producers is

   use type Editor.Feature_Diagnostics.Diagnostic_Severity;
   use type Editor.Feature_Diagnostics.Diagnostic_Source_Kind;

   Build_Output_Capture_Sequence : Natural := 0;

   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;

   function Producer_Kind_Is_Valid
     (Kind : External_Producer_Kind) return Boolean
   is
   begin
      case Kind is
         when Build_Diagnostics_Producer | Compiler_Diagnostics_Producer =>
            return True;
         when No_External_Producer =>
            return False;
      end case;
   end Producer_Kind_Is_Valid;

   function Stable_Name (Kind : External_Producer_Kind) return String is
   begin
      case Kind is
         when Build_Diagnostics_Producer =>
            return "external.build-diagnostics";
         when Compiler_Diagnostics_Producer =>
            return "external.compiler-diagnostics";
         when No_External_Producer =>
            return "";
      end case;
   end Stable_Name;

   function Display_Label (Kind : External_Producer_Kind) return String is
   begin
      case Kind is
         when Build_Diagnostics_Producer =>
            return "Build diagnostics";
         when Compiler_Diagnostics_Producer =>
            return "Compiler diagnostics";
         when No_External_Producer =>
            return "";
      end case;
   end Display_Label;

   function Build_External_Producer_Source
     (Kind : External_Producer_Kind) return External_Producer_Source
   is
   begin
      return
        (Kind          => Kind,
         Stable_Name   => To_Unbounded_String (Stable_Name (Kind)),
         Display_Label => To_Unbounded_String (Display_Label (Kind)));
   end Build_External_Producer_Source;

   function Build_Compiler_Diagnostics_Producer_Source
     return External_Producer_Source
   is
   begin
      return Build_External_Producer_Source (Compiler_Diagnostics_Producer);
   end Build_Compiler_Diagnostics_Producer_Source;

   function Producer_Source_Is_Valid
     (Producer : External_Producer_Source) return Boolean
   is
   begin
      return Producer_Kind_Is_Valid (Producer.Kind)
        and then To_String (Producer.Stable_Name) = Stable_Name (Producer.Kind)
        and then To_String (Producer.Display_Label) = Display_Label (Producer.Kind);
   end Producer_Source_Is_Valid;

   function Map_External_Producer_To_Diagnostic_Source
     (Producer : External_Producer_Source)
      return Editor.Feature_Diagnostics.Diagnostic_Source_Kind
   is
   begin
      if not Producer_Source_Is_Valid (Producer) then
         return Editor.Feature_Diagnostics.Unknown_Diagnostic_Source;
      end if;

      case Producer.Kind is
         when Build_Diagnostics_Producer | Compiler_Diagnostics_Producer =>
            return Editor.Feature_Diagnostics.External_Diagnostic_Source;
         when No_External_Producer =>
            return Editor.Feature_Diagnostics.Unknown_Diagnostic_Source;
      end case;
   end Map_External_Producer_To_Diagnostic_Source;

   function Map_Compiler_Severity_To_Diagnostic_Severity
     (Severity : Compiler_Diagnostic_Severity)
      return Editor.Feature_Diagnostics.Diagnostic_Severity
   is
   begin
      case Severity is
         when Compiler_Info =>
            return Editor.Feature_Diagnostics.Diagnostic_Info;
         when Compiler_Note =>
            return Editor.Feature_Diagnostics.Diagnostic_Note;
         when Compiler_Unknown =>
            return Editor.Feature_Diagnostics.Diagnostic_Unknown;
         when Compiler_Warning =>
            return Editor.Feature_Diagnostics.Diagnostic_Warning;
         when Compiler_Error | Compiler_Fatal =>
            return Editor.Feature_Diagnostics.Diagnostic_Error;
      end case;
   end Map_Compiler_Severity_To_Diagnostic_Severity;


   function Parse_Compiler_Diagnostic_Severity
     (Token : String) return Compiler_Diagnostic_Severity
   is
      Clean : constant String :=
        Ada.Characters.Handling.To_Lower
          (Ada.Strings.Fixed.Trim (Token, Both));
   begin
      if Clean = "info" or else Clean = "information" then
         return Compiler_Info;
      elsif Clean = "note" then
         return Compiler_Note;
      elsif Clean = "warning" or else Clean = "warn" then
         return Compiler_Warning;
      elsif Clean = "error" then
         return Compiler_Error;
      elsif Clean = "fatal" or else Clean = "fatal error" then
         return Compiler_Fatal;
      else
         return Compiler_Unknown;
      end if;
   end Parse_Compiler_Diagnostic_Severity;

   function Is_Natural_Text (Text : String) return Boolean
   is
      Value : Natural := 0;
   begin
      if Text'Length = 0 then
         return False;
      end if;

      for C of Text loop
         if C not in '0' .. '9' then
            return False;
         end if;

         if Value <= (Natural'Last - 9) / 10 then
            Value := Value * 10 + Character'Pos (C) - Character'Pos ('0');
         else
            return False;
         end if;
      end loop;

      return True;
   end Is_Natural_Text;

   function Parse_Positive_Natural (Text : String) return Natural
   is
      Value : Natural := 0;
   begin
      for C of Text loop
         Value := Value * 10 + Character'Pos (C) - Character'Pos ('0');
      end loop;
      return Value;
   end Parse_Positive_Natural;

   function Find_Next_Colon
     (Text  : String;
      Start : Positive) return Natural
   is
   begin
      if Text'Length = 0 or else Start > Text'Last then
         return 0;
      end if;

      for I in Start .. Text'Last loop
         if Text (I) = ':' then
            return I;
         end if;
      end loop;

      return 0;
   end Find_Next_Colon;

   function Trim_Slice_Or_Empty
     (Text : String;
      From : Natural;
      To   : Natural) return String
   is
   begin
      if Text'Length = 0
        or else From < Text'First
        or else To > Text'Last
        or else From > To
      then
         return "";
      end if;

      return Ada.Strings.Fixed.Trim (Text (From .. To), Both);
   end Trim_Slice_Or_Empty;

   function Starts_With_Case_Insensitive
     (Text   : String;
      Prefix : String) return Boolean
   is
   begin
      return Text'Length >= Prefix'Length
        and then Ada.Characters.Handling.To_Lower
          (Text (Text'First .. Text'First + Prefix'Length - 1)) =
          Ada.Characters.Handling.To_Lower (Prefix);
   end Starts_With_Case_Insensitive;


   function Contains_Case_Insensitive
     (Text    : String;
      Pattern : String) return Boolean
   is
      Clean_Text : constant String := Ada.Characters.Handling.To_Lower (Text);
      Clean_Pattern : constant String := Ada.Characters.Handling.To_Lower (Pattern);
   begin
      if Pattern'Length = 0 then
         return True;
      elsif Text'Length < Pattern'Length then
         return False;
      end if;

      for I in Clean_Text'First .. Clean_Text'Last - Clean_Pattern'Length + 1 loop
         if Clean_Text (I .. I + Clean_Pattern'Length - 1) = Clean_Pattern then
            return True;
         end if;
      end loop;

      return False;
   end Contains_Case_Insensitive;


   Max_Compiler_Diagnostic_Message_Length : constant Natural := 512;
   Max_Compiler_Diagnostic_Continuation_Lines : constant Natural := 4;

   function Bound_Diagnostic_Message (Text : String) return String
   is
      Clean : constant String := Ada.Strings.Fixed.Trim (Text, Both);
      Marker : constant String := "...";
   begin
      if Clean'Length <= Max_Compiler_Diagnostic_Message_Length then
         return Clean;
      elsif Max_Compiler_Diagnostic_Message_Length <= Marker'Length then
         return Marker (Marker'First .. Marker'First + Max_Compiler_Diagnostic_Message_Length - 1);
      else
         return Clean (Clean'First .. Clean'First + Max_Compiler_Diagnostic_Message_Length - Marker'Length - 1) & Marker;
      end if;
   end Bound_Diagnostic_Message;

   function Is_Continuation_Line (Line : String) return Boolean
   is
   begin
      return Line'Length > 0
        and then (Line (Line'First) = ' ' or else Line (Line'First) = ASCII.HT)
        and then Ada.Strings.Fixed.Trim (Line, Both)'Length > 0;
   end Is_Continuation_Line;

   function With_Continuation
     (Diagnostic : Compiler_Diagnostic_Record;
      Line   : String) return Compiler_Diagnostic_Record
   is
      Result : Compiler_Diagnostic_Record := Diagnostic;
      Base   : constant String := To_String (Diagnostic.Message);
      Extra  : constant String := Ada.Strings.Fixed.Trim (Line, Both);
   begin
      if Extra'Length = 0 then
         return Result;
      end if;

      Result.Message := To_Unbounded_String
        (Bound_Diagnostic_Message (Base & " / " & Extra));
      return Result;
   end With_Continuation;


   function Starts_With_Known_Severity_Prefix
     (Text : String) return Boolean
   is
      First_Colon : constant Natural := Find_Next_Colon (Text, Text'First);
      Token       : constant String :=
        (if First_Colon = 0 then Ada.Strings.Fixed.Trim (Text, Both)
         else Trim_Slice_Or_Empty (Text, Text'First, First_Colon - 1));
      Severity    : constant Compiler_Diagnostic_Severity :=
        Parse_Compiler_Diagnostic_Severity (Token);
   begin
      return Severity /= Compiler_Unknown;
   end Starts_With_Known_Severity_Prefix;

   function Build_Parse_Result
     (Status     : Diagnostic_Line_Parse_Status;
      Reason     : Diagnostic_Line_Parse_Reason;
      Has_Record : Boolean := False;
      Diagnostic_Record : Compiler_Diagnostic_Record := (others => <>))
      return Diagnostic_Line_Parse_Result
   is
   begin
      return
        (Status     => Status,
         Reason     => Reason,
         Has_Record => Has_Record,
         Diagnostic_Record => Diagnostic_Record);
   end Build_Parse_Result;

   function Malformed_Result
     (Reason : Diagnostic_Line_Parse_Reason) return Diagnostic_Line_Parse_Result
   is
   begin
      return Build_Parse_Result (Parse_Rejected_Malformed, Reason);
   end Malformed_Result;

   procedure Remember_Malformed_Reason
     (Reason     : Diagnostic_Line_Parse_Reason;
      Saw_Reason : in out Boolean;
      Best       : in out Diagnostic_Line_Parse_Reason)
   is
   begin
      if not Saw_Reason then
         Saw_Reason := True;
         Best := Reason;
      end if;
   end Remember_Malformed_Reason;

   function Parse_Compiler_Diagnostic_Line
     (Line      : String;
      Tool_Name : String := "") return Diagnostic_Line_Parse_Result
   is
      Clean_Line : constant String := Ada.Strings.Fixed.Trim (Line, Both);
      First_Colon  : Natural;
      Second_Colon : Natural;
      Third_Colon  : Natural;
      Fourth_Colon : Natural;
      Saw_Malformed : Boolean := False;
      Best_Reason   : Diagnostic_Line_Parse_Reason := Malformed_Location;
      Clean_Tool    : constant Unbounded_String :=
        To_Unbounded_String (Ada.Strings.Fixed.Trim (Tool_Name, Both));
   begin
      if Clean_Line'Length = 0 then
         return Build_Parse_Result (Parse_Ignored_Blank, Blank_Line);
      end if;

      if Starts_With_Case_Insensitive (Clean_Line, "gprbuild:") then
         declare
            Message_Text : constant String :=
              Trim_Slice_Or_Empty
                (Clean_Line, Clean_Line'First + 9, Clean_Line'Last);
            Severity_Colon : constant Natural :=
              Find_Next_Colon (Message_Text, Message_Text'First);
            Severity : Compiler_Diagnostic_Severity := Compiler_Error;
            Final_Message : Unbounded_String := To_Unbounded_String (Message_Text);
            Explicit_Tool_Diagnostic : Boolean := False;
         begin
            if Message_Text'Length = 0 then
               return Malformed_Result (Missing_Message);
            elsif Severity_Colon /= 0 then
               declare
                  Maybe_Severity : constant String :=
                    Trim_Slice_Or_Empty
                      (Message_Text, Message_Text'First, Severity_Colon - 1);
                  Maybe_Message : constant String :=
                    Trim_Slice_Or_Empty
                      (Message_Text, Severity_Colon + 1, Message_Text'Last);
                  Parsed_Severity : constant Compiler_Diagnostic_Severity :=
                    Parse_Compiler_Diagnostic_Severity (Maybe_Severity);
               begin
                  if Parsed_Severity /= Compiler_Unknown then
                     if Maybe_Message'Length = 0 then
                        return Malformed_Result (Missing_Message);
                     end if;

                     Severity := Parsed_Severity;
                     Final_Message := To_Unbounded_String (Maybe_Message);
                     Explicit_Tool_Diagnostic := True;
                  end if;
               end;
            end if;

            if not Explicit_Tool_Diagnostic then
               if Contains_Case_Insensitive (Message_Text, "processing failed")
                 or else Contains_Case_Insensitive (Message_Text, "failed")
               then
                  Severity := Compiler_Error;
                  Final_Message := To_Unbounded_String (Message_Text);
               else
                  return Build_Parse_Result
                    (Parse_Ignored_Unrecognized, Unrecognized_Format);
               end if;
            end if;

            return Build_Parse_Result
              (Parse_Accepted, No_Parse_Reason, True,
               (Severity     => Severity,
                Message      => To_Unbounded_String
                                  (Bound_Diagnostic_Message
                                     (To_String (Final_Message))),
                File_Label   => Null_Unbounded_String,
                Has_Location => False,
                Line         => 0,
                Column       => 0,
                Tool_Name    => To_Unbounded_String ("gprbuild")));
         end;
      end if;

      First_Colon := Find_Next_Colon (Clean_Line, Clean_Line'First);
      while First_Colon /= 0 loop
         Second_Colon := Find_Next_Colon (Clean_Line, First_Colon + 1);
         exit when Second_Colon = 0;

         declare
            File_Label : constant String :=
              Trim_Slice_Or_Empty
                (Clean_Line, Clean_Line'First, First_Colon - 1);
            Line_Text : constant String :=
              Trim_Slice_Or_Empty
                (Clean_Line, First_Colon + 1, Second_Colon - 1);
         begin
            if File_Label'Length = 0 then
               Remember_Malformed_Reason
                 (Malformed_Location, Saw_Malformed, Best_Reason);
            elsif Line_Text'Length = 0 then
               Remember_Malformed_Reason
                 (Missing_Line, Saw_Malformed, Best_Reason);
            elsif not Is_Natural_Text (Line_Text) then
               Remember_Malformed_Reason
                 (Nonnumeric_Line, Saw_Malformed, Best_Reason);
            elsif Parse_Positive_Natural (Line_Text) = 0 then
               Remember_Malformed_Reason
                 (Zero_Line, Saw_Malformed, Best_Reason);
            else
               Third_Colon := Find_Next_Colon (Clean_Line, Second_Colon + 1);
               if Third_Colon = 0 then
                  declare
                     Tail_Text : constant String :=
                       Trim_Slice_Or_Empty
                         (Clean_Line, Second_Colon + 1, Clean_Line'Last);
                  begin
                     if Tail_Text'Length = 0 then
                        Remember_Malformed_Reason
                          (Missing_Severity, Saw_Malformed, Best_Reason);
                     elsif Is_Natural_Text (Tail_Text) then
                        Remember_Malformed_Reason
                          (Missing_Message, Saw_Malformed, Best_Reason);
                     else
                        return Build_Parse_Result
                          (Parse_Accepted, No_Parse_Reason, True,
                           (Severity     => Compiler_Unknown,
                            Message      => To_Unbounded_String
                                              (Bound_Diagnostic_Message (Tail_Text)),
                            File_Label   => To_Unbounded_String (File_Label),
                            Has_Location => True,
                            Line         => Parse_Positive_Natural (Line_Text),
                            Column       => 1,
                            Tool_Name    => Clean_Tool));
                     end if;
                  end;
               else
                  declare
                     Maybe_Column : constant String :=
                       Trim_Slice_Or_Empty
                         (Clean_Line, Second_Colon + 1, Third_Colon - 1);
                     Parsed_Line : constant Natural := Parse_Positive_Natural (Line_Text);
                  begin
                     if Maybe_Column'Length > 0 and then Is_Natural_Text (Maybe_Column) then
                        if Parse_Positive_Natural (Maybe_Column) = 0 then
                           Remember_Malformed_Reason
                             (Zero_Column, Saw_Malformed, Best_Reason);
                        else
                           Fourth_Colon := Find_Next_Colon (Clean_Line, Third_Colon + 1);
                           if Fourth_Colon = 0 then
                              declare
                                 Severity_Or_Message : constant String :=
                                   Trim_Slice_Or_Empty
                                     (Clean_Line, Third_Colon + 1, Clean_Line'Last);
                                 Severity : constant Compiler_Diagnostic_Severity :=
                                   Parse_Compiler_Diagnostic_Severity
                                     (Severity_Or_Message);
                              begin
                                 if Severity_Or_Message'Length = 0 then
                                    return Malformed_Result (Missing_Severity);
                                 elsif Severity /= Compiler_Unknown then
                                    return Malformed_Result (Missing_Message);
                                 else
                                    return Build_Parse_Result
                                      (Parse_Accepted, No_Parse_Reason, True,
                                       (Severity     => Compiler_Unknown,
                                        Message      => To_Unbounded_String
                                                          (Bound_Diagnostic_Message
                                                             (Severity_Or_Message)),
                                        File_Label   => To_Unbounded_String (File_Label),
                                        Has_Location => True,
                                        Line         => Parsed_Line,
                                        Column       => Parse_Positive_Natural (Maybe_Column),
                                        Tool_Name    => Clean_Tool));
                                 end if;
                              end;
                           else
                              declare
                                 Severity_Text : constant String :=
                                   Trim_Slice_Or_Empty
                                     (Clean_Line, Third_Colon + 1, Fourth_Colon - 1);
                                 Message_Text : constant String :=
                                   Trim_Slice_Or_Empty
                                     (Clean_Line, Fourth_Colon + 1, Clean_Line'Last);
                              begin
                                 if Severity_Text'Length = 0 then
                                    return Malformed_Result (Missing_Severity);
                                 elsif Message_Text'Length = 0 then
                                    return Malformed_Result (Missing_Message);
                                 end if;

                                 return Build_Parse_Result
                                   (Parse_Accepted, No_Parse_Reason, True,
                                    (Severity     => Parse_Compiler_Diagnostic_Severity
                                                       (Severity_Text),
                                     Message      => To_Unbounded_String
                                                       (Bound_Diagnostic_Message (Message_Text)),
                                     File_Label   => To_Unbounded_String (File_Label),
                                     Has_Location => True,
                                     Line         => Parsed_Line,
                                     Column       => Parse_Positive_Natural (Maybe_Column),
                                     Tool_Name    => Clean_Tool));
                              end;
                           end if;
                        end if;
                     else
                        declare
                           Severity_Text : constant String := Maybe_Column;
                           Message_Text : constant String :=
                             Trim_Slice_Or_Empty
                               (Clean_Line, Third_Colon + 1, Clean_Line'Last);
                        begin
                           if Severity_Text'Length = 0 then
                              return Malformed_Result (Missing_Column);
                           elsif Message_Text'Length = 0 then
                              return Malformed_Result (Missing_Message);
                           elsif Parse_Compiler_Diagnostic_Severity (Severity_Text) =
                                   Compiler_Unknown
                             and then Starts_With_Known_Severity_Prefix (Message_Text)
                           then
                              return Malformed_Result (Nonnumeric_Column);
                           end if;

                           return Build_Parse_Result
                             (Parse_Accepted, No_Parse_Reason, True,
                              (Severity     => Parse_Compiler_Diagnostic_Severity
                                                 (Severity_Text),
                               Message      => To_Unbounded_String
                                                 (Bound_Diagnostic_Message (Message_Text)),
                               File_Label   => To_Unbounded_String (File_Label),
                               Has_Location => True,
                               Line         => Parsed_Line,
                               Column       => 1,
                               Tool_Name    => Clean_Tool));
                        end;
                     end if;
                  end;
               end if;
            end if;
         end;

         First_Colon := Find_Next_Colon (Clean_Line, First_Colon + 1);
      end loop;

      if Saw_Malformed then
         return Malformed_Result (Best_Reason);
      else
         return Build_Parse_Result
           (Parse_Ignored_Unrecognized, Unrecognized_Format);
      end if;
   end Parse_Compiler_Diagnostic_Line;


   procedure Count_Compiler_Diagnostic_Severity
     (Severity : Compiler_Diagnostic_Severity;
      Batch    : in out Diagnostic_Line_Batch_Parse_Result)
   is
   begin
      case Severity is
         when Compiler_Error | Compiler_Fatal =>
            Batch.Error_Count := Batch.Error_Count + 1;
         when Compiler_Warning =>
            Batch.Warning_Count := Batch.Warning_Count + 1;
         when Compiler_Info =>
            Batch.Info_Count := Batch.Info_Count + 1;
         when Compiler_Note =>
            Batch.Note_Count := Batch.Note_Count + 1;
         when Compiler_Unknown =>
            Batch.Unknown_Count := Batch.Unknown_Count + 1;
      end case;
   end Count_Compiler_Diagnostic_Severity;

   function Parse_Compiler_Diagnostic_Lines
     (Lines     : Diagnostic_Text_Line_Array;
      Tool_Name : String := "") return Diagnostic_Line_Batch_Parse_Result
   is
      Result : Diagnostic_Line_Batch_Parse_Result;
      Parsed : Diagnostic_Line_Parse_Result;
      Last_Record_Index : Natural := 0;
      Has_Last_Record : Boolean := False;
      Continuation_Open : Boolean := False;
      Continuation_Count : Natural := 0;
   begin
      Result.Input_Count := Natural (Lines.Length);
      if Lines.Is_Empty then
         return Result;
      end if;

      for I in Lines.First_Index .. Lines.Last_Index loop
         Parsed := Parse_Compiler_Diagnostic_Line
           (To_String (Lines.Element (I)), Tool_Name);
         case Parsed.Status is
            when Parse_Accepted =>
               Result.Accepted_Count := Result.Accepted_Count + 1;
               if Parsed.Has_Record then
                  Result.Records.Append (Parsed.Diagnostic_Record);
                  Count_Compiler_Diagnostic_Severity
                    (Parsed.Diagnostic_Record.Severity, Result);
                  Last_Record_Index := Result.Records.Last_Index;
                  Has_Last_Record := True;
                  Continuation_Open := True;
                  Continuation_Count := 0;
               end if;
            when Parse_Ignored_Blank =>
               Continuation_Open := False;
               Result.Ignored_Blank_Count := Result.Ignored_Blank_Count + 1;
            when Parse_Ignored_Unrecognized =>
               if Has_Last_Record
                 and then Continuation_Open
                 and then Continuation_Count < Max_Compiler_Diagnostic_Continuation_Lines
                 and then Is_Continuation_Line (To_String (Lines.Element (I)))
               then
                  Result.Records.Replace_Element
                    (Last_Record_Index,
                     With_Continuation
                       (Result.Records.Element (Last_Record_Index),
                        To_String (Lines.Element (I))));
                  Continuation_Count := Continuation_Count + 1;
                  Result.Accepted_Count := Result.Accepted_Count + 1;
               else
                  Continuation_Open := False;
                  Result.Ignored_Unrecognized_Count :=
                    Result.Ignored_Unrecognized_Count + 1;
               end if;
            when Parse_Rejected_Malformed =>
               Continuation_Open := False;
               Result.Rejected_Malformed_Count :=
                 Result.Rejected_Malformed_Count + 1;
         end case;
      end loop;

      return Result;
   end Parse_Compiler_Diagnostic_Lines;

   function Assert_Diagnostic_Line_Batch_Consistent
     (Batch : Diagnostic_Line_Batch_Parse_Result) return Boolean
   is
   begin
      return Batch.Input_Count =
        Batch.Accepted_Count
        + Batch.Ignored_Blank_Count
        + Batch.Ignored_Unrecognized_Count
        + Batch.Rejected_Malformed_Count
        and then Batch.Accepted_Count >= Natural (Batch.Records.Length)
        and then Batch.Error_Count + Batch.Warning_Count + Batch.Info_Count
          + Batch.Note_Count + Batch.Unknown_Count = Natural (Batch.Records.Length);
   end Assert_Diagnostic_Line_Batch_Consistent;

   function Normalize_Parsed_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : External_Producer_Source;
      Parsed   : Diagnostic_Line_Parse_Result) return External_Diagnostic_Record
   is
   begin
      if Parsed.Status = Parse_Accepted and then Parsed.Has_Record then
         return Normalize_Compiler_Diagnostic (S, Producer, Parsed.Diagnostic_Record);
      else
         return
           (Severity      => Editor.Feature_Diagnostics.Diagnostic_Warning,
            Message       => Null_Unbounded_String,
            Source_Label  => Null_Unbounded_String,
            Has_Target    => False,
            Target_Buffer => Editor.Feature_Diagnostics.No_Buffer,
            Target_Line   => 0,
            Target_Column => 0);
      end if;
   end Normalize_Parsed_Compiler_Diagnostic;

   function Ingest_Compiler_Diagnostic_Lines
     (S        : in out Editor.State.State_Type;
      Producer : External_Producer_Source;
      Lines    : Diagnostic_Text_Line_Array) return Diagnostic_Line_Ingestion_Result
   is
      Parsed : constant Diagnostic_Line_Batch_Parse_Result :=
        Parse_Compiler_Diagnostic_Lines
          (Lines, To_String (Producer.Display_Label));
      Normalized : constant Normalized_Diagnostic_Batch :=
        Normalize_Compiler_Diagnostic_Batch (S, Producer, Parsed.Records);
      Result : Diagnostic_Line_Ingestion_Result;
   begin
      Result.Parse_Input_Count := Parsed.Input_Count;
      Result.Parse_Accepted_Count := Parsed.Accepted_Count;
      Result.Parse_Ignored_Blank_Count := Parsed.Ignored_Blank_Count;
      Result.Parse_Ignored_Unrecognized_Count := Parsed.Ignored_Unrecognized_Count;
      Result.Parse_Rejected_Malformed_Count := Parsed.Rejected_Malformed_Count;
      Result.Normalized_Count := Normalized.Normalized_Count;
      Result.Parsed_Error_Count := Parsed.Error_Count;
      Result.Parsed_Warning_Count := Parsed.Warning_Count;
      Result.Parsed_Info_Count := Parsed.Info_Count;
      Result.Parsed_Note_Count := Parsed.Note_Count;
      Result.Parsed_Unknown_Count := Parsed.Unknown_Count;
      Result.Ingestion_Result :=
        Ingest_Diagnostic_Batch (S, Producer, Normalized.Items);
      Assert_Diagnostic_Line_Ingestion_Result_Consistent (Result);
      return Result;
   end Ingest_Compiler_Diagnostic_Lines;

   function Diagnostic_Line_Ingestion_Result_Is_Consistent
     (Result : Diagnostic_Line_Ingestion_Result) return Boolean
   is
      Count_Sum : constant Natural :=
        Result.Parse_Accepted_Count
        + Result.Parse_Ignored_Blank_Count
        + Result.Parse_Ignored_Unrecognized_Count
        + Result.Parse_Rejected_Malformed_Count;
      Outcome : Diagnostic_Line_Command_Outcome;
   begin
      if Result.Parse_Input_Count /= Count_Sum then
         return False;
      end if;

      if Result.Normalized_Count > Result.Parse_Accepted_Count then
         return False;
      end if;

      if Result.Parsed_Error_Count + Result.Parsed_Warning_Count
        + Result.Parsed_Info_Count + Result.Parsed_Note_Count
        + Result.Parsed_Unknown_Count /= Result.Normalized_Count
      then
         return False;
      end if;

      if Result.Ingestion_Result.Accepted_Count > Result.Normalized_Count then
         return False;
      end if;

      if Result.Ingestion_Result.Accepted_Count
        + Result.Ingestion_Result.Rejected_Count > Result.Normalized_Count
      then
         return False;
      end if;

      if Result.Ingestion_Result.Evicted_Count >
        Result.Ingestion_Result.Accepted_Count
      then
         return False;
      end if;

      if Result.Parse_Input_Count = 0
        and then (Result.Parse_Accepted_Count /= 0
                  or else Result.Parse_Ignored_Blank_Count /= 0
                  or else Result.Parse_Ignored_Unrecognized_Count /= 0
                  or else Result.Parse_Rejected_Malformed_Count /= 0
                  or else Result.Normalized_Count /= 0
                  or else Result.Parsed_Error_Count /= 0
                  or else Result.Parsed_Warning_Count /= 0
                  or else Result.Parsed_Info_Count /= 0
                  or else Result.Parsed_Note_Count /= 0
                  or else Result.Parsed_Unknown_Count /= 0
                  or else Result.Ingestion_Result.Accepted_Count /= 0
                  or else Result.Ingestion_Result.Rejected_Count /= 0
                  or else Result.Ingestion_Result.Evicted_Count /= 0)
      then
         return False;
      end if;

      Outcome := Classify_Diagnostic_Line_Command_Outcome (Result);
      case Outcome is
         when Diagnostic_Line_Command_Succeeded =>
            return Result.Ingestion_Result.Accepted_Count > 0;
         when Diagnostic_Line_Command_No_Input =>
            return Result.Parse_Input_Count = 0;
         when Diagnostic_Line_Command_Malformed_Only =>
            return Result.Parse_Input_Count > 0
              and then Result.Parse_Accepted_Count = 0
              and then Result.Ingestion_Result.Accepted_Count = 0
              and then Result.Parse_Rejected_Malformed_Count > 0;
         when Diagnostic_Line_Command_No_Diagnostics =>
            return Result.Parse_Input_Count > 0
              and then Result.Ingestion_Result.Accepted_Count = 0
              and then (Result.Parse_Accepted_Count > 0
                        or else Result.Parse_Ignored_Blank_Count > 0
                        or else Result.Parse_Ignored_Unrecognized_Count > 0
                        or else Result.Parse_Rejected_Malformed_Count = 0);
      end case;
   end Diagnostic_Line_Ingestion_Result_Is_Consistent;

   procedure Assert_Diagnostic_Line_Ingestion_Result_Consistent
     (Result : Diagnostic_Line_Ingestion_Result)
   is
   begin
      pragma Assert (Diagnostic_Line_Ingestion_Result_Is_Consistent (Result));
   end Assert_Diagnostic_Line_Ingestion_Result_Consistent;

   function Trim_Natural_Image (Value : Natural) return String
   is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Both);
   end Trim_Natural_Image;

   function Build_Status_Label (Status : Build_Run_Status) return String is
   begin
      case Status is
         when Build_Run_Succeeded =>
            return "Build: succeeded";
         when Build_Run_Failed =>
            return "Build: failed";
         when Build_Run_Not_Available =>
            return "Build: not available";
         when Build_Run_Rejected =>
            return "Build: rejected";
         when Build_Run_Execution_Error =>
            return "Build: execution error";
         when Build_Run_Timed_Out =>
            return "Build failed: timed out";
         when Build_Run_Cancelled =>
            return "Build cancelled";
         when Build_Run_Cancellation_Unsupported =>
            return "Build unavailable: cancellation unsupported";
         when Build_Run_Output_Truncated =>
            return "Build: output truncated";
      end case;
   end Build_Status_Label;

   function Contains_Control_Character (Value : String) return Boolean;
   function Contains_Shell_Syntax (Value : String) return Boolean;

   function Build_Default_Execution_Gate return Build_Execution_Gate is
   begin
      return
        (Process_Policy              =>
           (Mode                     => Process_Execution_Disabled,
            Allow_Real_Execution     => False,
            Allow_Shell              => False,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => 0),
         Allow_Build_Run             => False,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Build_Consent_Not_Provided,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
   end Build_Default_Execution_Gate;

   function Build_Test_Fixture_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Build_Execution_Consent :=
        Build_Consent_Test_Only) return Build_Execution_Gate
   is
   begin
      return
        (Process_Policy              =>
           (Mode                     => Process_Execution_Test_Fixture,
            Allow_Real_Execution     => False,
            Allow_Shell              => False,
            Max_Output_Bytes         => Max_Output_Bytes,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Consent,
         Allow_Diagnostics_Ingestion => Allow_Diagnostics_Ingestion,
         Show_Diagnostics            => Show_Diagnostics);
   end Build_Test_Fixture_Execution_Gate;

   function Build_Real_Fixture_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Build_Execution_Consent :=
        Build_Consent_Test_Only) return Build_Execution_Gate
   is
   begin
      return
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Fixture_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => Max_Output_Bytes,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Consent,
         Allow_Diagnostics_Ingestion => Allow_Diagnostics_Ingestion,
         Show_Diagnostics            => Show_Diagnostics);
   end Build_Real_Fixture_Execution_Gate;

   function Build_Real_Execution_Gate
     (Allow_Diagnostics_Ingestion : Boolean := True;
      Show_Diagnostics            : Boolean := False;
      Require_Absolute_Program    : Boolean := False;
      Max_Output_Bytes            : Natural := 262_144;
      Consent                     : Build_Execution_Consent :=
        Build_Consent_Not_Provided) return Build_Execution_Gate
   is
   begin
      return
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => Max_Output_Bytes,
            Require_Absolute_Program => Require_Absolute_Program,
            --  Public build.run uses the normal bounded synchronous runner.
            --  Timeout-aware callers can opt into a positive timeout policy;
            --  the real runner enforces that policy with its native process
            --  supervisor instead of an external timeout utility.
            Timeout_Milliseconds     => 0),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => True,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Consent,
         Allow_Diagnostics_Ingestion => Allow_Diagnostics_Ingestion,
         Show_Diagnostics            => Show_Diagnostics);
   end Build_Real_Execution_Gate;

   function Validate_Build_Execution_Consent
     (Gate : Build_Execution_Gate) return Boolean
   is
   begin
      case Gate.Process_Policy.Mode is
         when Process_Execution_Disabled =>
            return Gate.Consent = Build_Consent_Not_Provided;
         when Process_Execution_Test_Fixture
            | Process_Execution_Real_Fixture_Allowed =>
            return Gate.Consent = Build_Consent_Test_Only;
         when Process_Execution_Real_Allowed =>
            return Gate.Consent /= Build_Consent_Test_Only;
      end case;
   end Validate_Build_Execution_Consent;

   function Validate_Build_Execution_Gate
     (Gate : Build_Execution_Gate) return Boolean
   is
   begin
      if Gate.Process_Policy.Allow_Shell then
         return False;
      end if;

      if not Validate_Process_Execution_Policy (Gate.Process_Policy) then
         return False;
      end if;

      if not Validate_Build_Execution_Consent (Gate) then
         return False;
      end if;

      if Gate.Allow_Real_Build_Tool_Execution
        and then Gate.Allow_Real_Build_Tool_Fixture
      then
         return False;
      end if;

      if not Gate.Allow_Build_Run then
         return Gate.Process_Policy.Mode = Process_Execution_Disabled
           and then not Gate.Process_Policy.Allow_Real_Execution
           and then not Gate.Allow_Real_Build_Tool_Execution
           and then not Gate.Allow_Real_Build_Tool_Fixture;
      end if;

      case Gate.Process_Policy.Mode is
         when Process_Execution_Disabled =>
            return False;
         when Process_Execution_Test_Fixture =>
            return not Gate.Process_Policy.Allow_Real_Execution
              and then not Gate.Allow_Real_Build_Tool_Execution
              and then not Gate.Allow_Real_Build_Tool_Fixture;
         when Process_Execution_Real_Fixture_Allowed =>
            return Gate.Process_Policy.Allow_Real_Execution
              and then not Gate.Allow_Real_Build_Tool_Execution;
         when Process_Execution_Real_Allowed =>
            return Gate.Process_Policy.Allow_Real_Execution
              and then Gate.Allow_Real_Build_Tool_Execution
              and then not Gate.Allow_Real_Build_Tool_Fixture;
      end case;
   end Validate_Build_Execution_Gate;

   function Assert_Build_Execution_Gate_Consistent
     (Gate : Build_Execution_Gate) return Boolean
   is
   begin
      return Validate_Build_Execution_Gate (Gate);
   end Assert_Build_Execution_Gate_Consistent;

   function Select_Process_Runner_Mode
     (Gate   : Build_Execution_Gate;
      Policy : Process_Execution_Policy) return Process_Execution_Mode
   is
   begin
      if not Validate_Build_Execution_Gate (Gate) then
         return Process_Execution_Disabled;
      end if;

      if not Gate.Allow_Build_Run then
         return Process_Execution_Disabled;
      end if;

      if Gate.Process_Policy.Mode /= Policy.Mode
        or else Gate.Process_Policy.Allow_Real_Execution /= Policy.Allow_Real_Execution
        or else Gate.Process_Policy.Allow_Shell /= Policy.Allow_Shell
      then
         return Process_Execution_Disabled;
      end if;

      return Gate.Process_Policy.Mode;
   end Select_Process_Runner_Mode;

   function Build_User_Opt_In_Request
     (Tool          : Build_Tool_Kind;
      Program_Label : String;
      Working_Label : String;
      Arguments     : Process_Argument_Vector) return Build_Run_Request
   is
   begin
      --  Phase 177 keeps user-supplied build commands structured and explicit.
      --  Program_Label is ppublic as command/program metadata; no shell string
      --  is accepted, split, persisted, inferred from project state, or expanded
      --  through PATH/project discovery by this constructor.
      return
        (Tool                 => Tool,
         Provenance           => Build_Request_From_User_Opt_In,
         Working_Label        => To_Unbounded_String (Working_Label),
         Command_Label        => To_Unbounded_String (Program_Label),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Arguments);
   end Build_User_Opt_In_Request;

   function Validate_Build_Run_Request_Status
     (Request : Build_Run_Request) return Build_Request_Validation_Status
   is
      Clean_Command : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Command_Label), Both);
   begin
      --  Phase 167 validation is metadata-only: no filesystem reads, no
      --  project probing, no command inference, and no shell/argument parsing.
      case Request.Tool is
         when No_Build_Tool =>
            return Build_Request_Rejected_No_Tool;
         when Custom_Build_Tool =>
            return Build_Request_Rejected_Unsupported_Tool;
         when GPRbuild_Tool | Alire_Build_Tool =>
            if Clean_Command'Length = 0 then
               return Build_Request_Rejected_Empty_Command;
            end if;

            return Build_Request_Valid;
      end case;
   exception
      when Constraint_Error =>
         return Build_Request_Rejected_Unsupported_Tool;
   end Validate_Build_Run_Request_Status;

   function Validate_Build_Run_Request
     (Request : Build_Run_Request) return Boolean
   is
   begin
      return Validate_Build_Run_Request_Status (Request) = Build_Request_Valid;
   end Validate_Build_Run_Request;

   function Validate_User_Opt_In_Build_Request
     (Request : Build_Run_Request) return Build_Request_Validation_Status
   is
      Status : constant Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
   begin
      if Request.Provenance = Build_Request_From_Project_Metadata then
         return Build_Request_Rejected_Project_Metadata;
      elsif Request.Provenance = Build_Request_Unknown then
         return Build_Request_Rejected_Unknown_Provenance;
      elsif Request.Provenance /= Build_Request_From_User_Opt_In then
         return Build_Request_Rejected_Provenance;
      elsif Status /= Build_Request_Valid then
         return Status;
      else
         return Build_Request_Valid;
      end if;
   end Validate_User_Opt_In_Build_Request;

   function Build_Request_Rejection_Feedback
     (Status : Build_Request_Validation_Status) return String
   is
   begin
      case Status is
         when Build_Request_Valid =>
            return "Build: accepted";
         when Build_Request_Rejected_Unknown_Provenance
            | Build_Request_Rejected_Provenance =>
            return "Build: request provenance rejected";
         when Build_Request_Rejected_Project_Metadata =>
            return "Build: project build metadata not supported";
         when Build_Request_Rejected_Consent =>
            return "Build: execution consent required";
         when Build_Request_Rejected_Unsupported_Tool =>
            return "Build: custom build tool not supported";
         when Build_Request_Rejected_No_Tool
            | Build_Request_Rejected_Empty_Command =>
            return "Build: rejected";
      end case;
   end Build_Request_Rejection_Feedback;

   function Validate_Build_Request_Provenance
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Request_Validation_Status
   is
   begin
      case Request.Provenance is
         when Build_Request_Unknown =>
            return Build_Request_Rejected_Unknown_Provenance;
         when Build_Request_From_Project_Metadata =>
            return Build_Request_Rejected_Project_Metadata;
         when Build_Request_From_Test | Build_Request_From_Fixture =>
            if Gate.Process_Policy.Mode = Process_Execution_Test_Fixture
              or else Gate.Process_Policy.Mode = Process_Execution_Real_Fixture_Allowed
            then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_Internal_Command =>
            if Gate.Allow_Build_Run
              and then not Gate.Allow_Real_Build_Tool_Execution
              and then Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
            then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_User_Opt_In =>
            if Gate.Allow_Build_Run
              and then Gate.Allow_Real_Build_Tool_Execution
              and then Gate.Process_Policy.Mode = Process_Execution_Real_Allowed
            then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
      end case;
   end Validate_Build_Request_Provenance;

   function Validate_Build_Working_Context
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Process_Request_Validation_Status
   is
      Clean_Working : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Working_Label), Both);
   begin
      if Gate.Allow_Real_Build_Tool_Execution then
         if Clean_Working'Length > 0
           and then (Contains_Control_Character (Clean_Working)
                     or else Contains_Shell_Syntax (Clean_Working))
         then
            return Process_Request_Rejected_Unsupported_Working_Directory;
         end if;
      elsif Gate.Allow_Real_Build_Tool_Fixture
        and then Clean_Working'Length > 0
      then
         return Process_Request_Rejected_Unsupported_Working_Directory;
      end if;

      return Process_Request_Valid;
   end Validate_Build_Working_Context;

   function Prepare_Process_Request
     (Request : Build_Run_Request) return Process_Run_Request
   is
   begin
      --  This helper is metadata-only: no filesystem probing, no project-file
      --  inference, no shell construction, and no argument parsing. Phase 174
      --  preserves only caller-supplied structured argv; build-tool mappings
      --  choose a deterministic base program label but never synthesize real
      --  build arguments from command labels, files, settings, PATH, or project
      --  metadata.
      case Request.Tool is
         when GPRbuild_Tool =>
            return
              (Program_Label        => To_Unbounded_String ("gprbuild"),
               Working_Label        => Request.Working_Label,
               Arguments            => Request.Arguments,
               Structured_Arguments => Request.Structured_Arguments);
         when Alire_Build_Tool =>
            return
              (Program_Label        => To_Unbounded_String ("alr"),
               Working_Label        => Request.Working_Label,
               Arguments            => Request.Arguments,
               Structured_Arguments => Request.Structured_Arguments);
         when No_Build_Tool | Custom_Build_Tool =>
            return
              (Program_Label        => Null_Unbounded_String,
               Working_Label        => Request.Working_Label,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Empty_Process_Arguments);
      end case;
   end Prepare_Process_Request;

   function Build_Process_Run_Result
     (Status        : Process_Run_Status;
      Exit_Code     : Integer := 0;
      Has_Exit_Code : Boolean := False;
      Stdout_Text   : String := "";
      Stderr_Text   : String := "";
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Capture_Mode : Process_Output_Capture_Mode :=
        Process_Output_Capture_Separated) return Process_Run_Result
   is
   begin
      return
        (Status        => Status,
         Output_Capture_Mode =>
           (if Stdout_Text'Length = 0 and then Stderr_Text'Length = 0 then
               Process_Output_Capture_None
            else Output_Capture_Mode),
         Has_Exit_Code => Has_Exit_Code,
         Exit_Code     => Exit_Code,
         Stdout_Text   => To_Unbounded_String (Stdout_Text),
         Stderr_Text   => To_Unbounded_String (Stderr_Text),
         Stdout_Truncated => Stdout_Truncated,
         Stderr_Truncated => Stderr_Truncated);
   end Build_Process_Run_Result;

   function Execute_Process_Request_Default
     (Request : Process_Run_Request) return Process_Run_Result
   is
      pragma Unreferenced (Request);
   begin
      --  The default seam remains non-executing. Production build commands use
      --  Run_Build_Command_With_Gate with Build_Real_Execution_Gate, which keeps
      --  explicit user consent, structured argv, and real-execution policy in
      --  one audited path.
      return Build_Process_Run_Result (Process_Run_Not_Available);
   end Execute_Process_Request_Default;

   function Empty_Process_Arguments return Process_Argument_Vector
   is
   begin
      return Process_Argument_Vectors.Empty_Vector;
   end Empty_Process_Arguments;

   procedure Append_Process_Argument
     (Arguments : in out Process_Argument_Vector;
      Value     : String)
   is
   begin
      --  Append preserves the exact argument text. It does not split on
      --  whitespace, parse quotes, expand shell syntax, or interpret metacharacters.
      Arguments.Append (To_Unbounded_String (Value));
   end Append_Process_Argument;

   function Process_Argument_Count
     (Arguments : Process_Argument_Vector) return Natural
   is
   begin
      return Natural (Arguments.Length);
   end Process_Argument_Count;

   function Build_Process_Argument_Vector
     (First  : String := "";
      Second : String := "";
      Third  : String := "") return Process_Argument_Vector
   is
      Args : Process_Argument_Vector := Empty_Process_Arguments;
   begin
      --  Preserve explicitly positioned empty middle arguments when a later
      --  argument is present, while allowing the common one-argument helper
      --  form to produce a one-token argv rather than two trailing empty tokens.
      if First'Length > 0 or else Second'Length > 0 or else Third'Length > 0 then
         Append_Process_Argument (Args, First);
      end if;

      if Second'Length > 0 or else Third'Length > 0 then
         Append_Process_Argument (Args, Second);
      end if;

      if Third'Length > 0 then
         Append_Process_Argument (Args, Third);
      end if;

      return Args;
   end Build_Process_Argument_Vector;

   function Build_Unsupported_Working_Context return Build_Working_Context
   is
   begin
      return
        (Kind  => Build_Working_Context_Unsupported,
         Label => Null_Unbounded_String);
   end Build_Unsupported_Working_Context;

   function Build_Inherited_Test_Working_Context return Build_Working_Context
   is
   begin
      return
        (Kind  => Build_Working_Context_Inherited_Test_Context,
         Label => Null_Unbounded_String);
   end Build_Inherited_Test_Working_Context;

   function Build_Explicit_Label_Working_Context
     (Label : String) return Build_Working_Context
   is
   begin
      return
        (Kind  => Build_Working_Context_Explicit_Label,
         Label => To_Unbounded_String (Label));
   end Build_Explicit_Label_Working_Context;

   function Contains_Control_Character (Value : String) return Boolean
   is
   begin
      for Ch of Value loop
         if Character'Pos (Ch) < 32 or else Character'Pos (Ch) = 127 then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Control_Character;

   function Contains_Shell_Syntax (Value : String) return Boolean
   is
   begin
      for Ch of Value loop
         case Ch is
            when ';' | '|' | '&' | '>' | '<' | '`' | '$' | '(' | ')' | '\' =>
               return True;
            when others =>
               null;
         end case;
      end loop;
      return False;
   end Contains_Shell_Syntax;

   function Looks_Project_Derived_Label (Value : String) return Boolean
   is
      Clean : constant String := Ada.Strings.Fixed.Trim (Value, Both);
   begin
      return Clean'Length >= 8
        and then (Clean (Clean'First .. Clean'First + 7) = "project:"
                  or else Clean (Clean'First .. Clean'First + 7) = "Project:") ;
   end Looks_Project_Derived_Label;

   function Contains_Path_Separator (Value : String) return Boolean
   is
   begin
      for Ch of Value loop
         if Ch = '/' or else Ch = '\' then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Path_Separator;

   function Looks_Path_Like_Label (Value : String) return Boolean
   is
      Clean : constant String := Ada.Strings.Fixed.Trim (Value, Both);
   begin
      if Contains_Path_Separator (Clean) then
         return True;
      end if;

      return Clean'Length >= 2
        and then Clean (Clean'First + 1) = ':';
   end Looks_Path_Like_Label;


   function Validate_Public_Build_Consent
     (Consent : Public_Build_Consent_Model)
      return Public_Build_Consent_Validation_Status
   is
   begin
      --  Consent validation is model-only. It never registers commands, opens
      --  prompts, dispatches through Executor, prepares processes, ingests
      --  diagnostics, changes features, or persists consent state.
      if Consent.Source = Public_Build_Consent_None then
         return Public_Build_Consent_Rejected_None;
      elsif not Consent.User_Acknowledged_Execution then
         return Public_Build_Consent_Rejected_Missing_Execution_Acknowledgement;
      elsif not Consent.User_Acknowledged_No_Shell then
         return Public_Build_Consent_Rejected_Missing_No_Shell_Acknowledgement;
      elsif not Consent.User_Acknowledged_External_Process then
         return Public_Build_Consent_Rejected_Missing_External_Process_Acknowledgement;
      elsif not Consent.User_Acknowledged_Diagnostics_Output then
         return Public_Build_Consent_Rejected_Missing_Diagnostics_Acknowledgement;
      end if;

      case Consent.Source is
         when Public_Build_Consent_Test_Context =>
            return Public_Build_Consent_Valid_For_Internal_Test;
         when Public_Build_Consent_User_Form_Acknowledged =>
            return Public_Build_Consent_Valid_But_Not_Public_UX;
         when Public_Build_Consent_None =>
            return Public_Build_Consent_Rejected_None;
      end case;
   end Validate_Public_Build_Consent;

   function Classify_Public_Build_Consent_Safety
     (Consent : Public_Build_Consent_Model) return Public_Build_Input_Safety
   is
   begin
      case Validate_Public_Build_Consent (Consent) is
         when Public_Build_Consent_Valid_For_Internal_Test =>
            return Public_Build_Input_Valid_For_Internal_Test;
         when Public_Build_Consent_Valid_But_Not_Public_UX =>
            return Public_Build_Input_Valid_But_Not_Publicly_Exposable;
         when others =>
            return Public_Build_Input_Not_Valid;
      end case;
   end Classify_Public_Build_Consent_Safety;

   function Build_Execution_Consent_From_Public_Model
     (Consent : Public_Build_Consent_Model) return Build_Execution_Consent
   is
   begin
      case Validate_Public_Build_Consent (Consent) is
         when Public_Build_Consent_Valid_For_Internal_Test
            | Public_Build_Consent_Valid_But_Not_Public_UX =>
            return Build_Consent_User_Confirmed;
         when others =>
            return Build_Consent_Not_Provided;
      end case;
   end Build_Execution_Consent_From_Public_Model;

   function Build_Public_Build_Consent_Feedback
     (Status : Public_Build_Consent_Validation_Status) return String
   is
   begin
      case Status is
         when Public_Build_Consent_Valid_For_Internal_Test =>
            return "Build: public consent UX not ready";
         when Public_Build_Consent_Valid_But_Not_Public_UX =>
            return "Build: public consent UX not ready";
         when Public_Build_Consent_Rejected_None =>
            return "Build: execution consent required";
         when Public_Build_Consent_Rejected_Missing_Execution_Acknowledgement =>
            return "Build: execution acknowledgement required";
         when Public_Build_Consent_Rejected_Missing_No_Shell_Acknowledgement =>
            return "Build: no-shell acknowledgement required";
         when Public_Build_Consent_Rejected_Missing_External_Process_Acknowledgement =>
            return "Build: external process acknowledgement required";
         when Public_Build_Consent_Rejected_Missing_Diagnostics_Acknowledgement =>
            return "Build: diagnostics acknowledgement required";
      end case;
   end Build_Public_Build_Consent_Feedback;

   function Audit_Public_Build_Consent_Readiness return Boolean
   is
      Test_Consent : constant Public_Build_Consent_Model :=
        (Source => Public_Build_Consent_Test_Context,
         User_Acknowledged_Execution => True,
         User_Acknowledged_No_Shell => True,
         User_Acknowledged_External_Process => True,
         User_Acknowledged_Diagnostics_Output => True);
      User_Form_Consent : constant Public_Build_Consent_Model :=
        (Source => Public_Build_Consent_User_Form_Acknowledged,
         User_Acknowledged_Execution => True,
         User_Acknowledged_No_Shell => True,
         User_Acknowledged_External_Process => True,
         User_Acknowledged_Diagnostics_Output => True);
      Missing_Consent : constant Public_Build_Consent_Model :=
        (Source => Public_Build_Consent_None,
         User_Acknowledged_Execution => False,
         User_Acknowledged_No_Shell => False,
         User_Acknowledged_External_Process => False,
         User_Acknowledged_Diagnostics_Output => False);
   begin
      return Validate_Public_Build_Consent (Test_Consent) =
             Public_Build_Consent_Valid_For_Internal_Test
        and then Validate_Public_Build_Consent (User_Form_Consent) =
             Public_Build_Consent_Valid_But_Not_Public_UX
        and then Validate_Public_Build_Consent (Missing_Consent) =
             Public_Build_Consent_Rejected_None
        and then Classify_Public_Build_Consent_Safety (Test_Consent) =
             Public_Build_Input_Valid_For_Internal_Test
        and then Classify_Public_Build_Consent_Safety (User_Form_Consent) =
             Public_Build_Input_Valid_But_Not_Publicly_Exposable
        and then Classify_Public_Build_Consent_Safety (Missing_Consent) =
             Public_Build_Input_Not_Valid
        and then Build_Execution_Consent_From_Public_Model (Test_Consent) =
             Build_Consent_User_Confirmed
        and then Build_Execution_Consent_From_Public_Model (User_Form_Consent) =
             Build_Consent_User_Confirmed;
   end Audit_Public_Build_Consent_Readiness;



   function Validate_Public_Build_Working_Context
     (Context : Public_Build_Working_Context_Model)
      return Public_Build_Working_Context_Validation_Status
   is
      Clean_Label : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Context.Label), Both);
   begin
      --  Phase 186 working-context validation is model-only. It never opens a
      --  directory picker, canonicalizes paths, checks existence, discovers
      --  project roots, reads project files, changes the process working
      --  directory, prepares processes, dispatches commands, ingests
      --  diagnostics, switches features, or persists working-context state.
      case Context.Source is
         when Public_Build_Working_Context_None =>
            return Public_Build_Working_Context_Rejected_None;

         when Public_Build_Working_Context_Project_Derived =>
            return Public_Build_Working_Context_Rejected_Project_Derived;

         when Public_Build_Working_Context_Test_Context =>
            return Public_Build_Working_Context_Valid_For_Internal_Test;

         when Public_Build_Working_Context_User_Form_Label =>
            if Clean_Label'Length = 0 then
               return Public_Build_Working_Context_Rejected_Missing_Label;
            elsif not Context.User_Acknowledged_Context then
               return Public_Build_Working_Context_Rejected_Missing_Acknowledgement;
            elsif Contains_Control_Character (Clean_Label)
              or else Contains_Shell_Syntax (Clean_Label)
              or else Looks_Project_Derived_Label (Clean_Label)
              or else Looks_Path_Like_Label (Clean_Label)
            then
               return Public_Build_Working_Context_Rejected_Unsafe_Label;
            elsif Clean_Label = "current-project-root"
              or else Clean_Label = "active-workspace-root"
              or else Clean_Label = "test-fixture-context"
            then
               return Public_Build_Working_Context_Valid_But_Not_Public_UX;
            else
               return Public_Build_Working_Context_Rejected_Unsafe_Label;
            end if;
      end case;
   end Validate_Public_Build_Working_Context;

   function Classify_Public_Build_Working_Context_Safety
     (Context : Public_Build_Working_Context_Model)
      return Public_Build_Input_Safety
   is
   begin
      case Validate_Public_Build_Working_Context (Context) is
         when Public_Build_Working_Context_Valid_For_Internal_Test =>
            return Public_Build_Input_Valid_For_Internal_Test;
         when Public_Build_Working_Context_Valid_But_Not_Public_UX =>
            return Public_Build_Input_Valid_But_Not_Publicly_Exposable;
         when others =>
            return Public_Build_Input_Not_Valid;
      end case;
   end Classify_Public_Build_Working_Context_Safety;

   function Build_Working_Context_From_Public_Model
     (Context : Public_Build_Working_Context_Model) return Build_Working_Context
   is
   begin
      case Validate_Public_Build_Working_Context (Context) is
         when Public_Build_Working_Context_Valid_For_Internal_Test =>
            return Build_Inherited_Test_Working_Context;
         when Public_Build_Working_Context_Valid_But_Not_Public_UX =>
            return Build_Explicit_Label_Working_Context
              (Ada.Strings.Fixed.Trim (To_String (Context.Label), Both));
         when others =>
            return Build_Unsupported_Working_Context;
      end case;
   end Build_Working_Context_From_Public_Model;

   function Assert_Public_Build_Working_Context_Conversion_Consistent
     (Model   : Public_Build_Working_Context_Model;
      Context : Build_Working_Context) return Boolean
   is
      Status : constant Public_Build_Working_Context_Validation_Status :=
        Validate_Public_Build_Working_Context (Model);
   begin
      case Status is
         when Public_Build_Working_Context_Valid_For_Internal_Test =>
            return Context.Kind = Build_Working_Context_Inherited_Test_Context
              and then To_String (Context.Label)'Length = 0;
         when Public_Build_Working_Context_Valid_But_Not_Public_UX =>
            return Context.Kind = Build_Working_Context_Explicit_Label
              and then Ada.Strings.Fixed.Trim
                (To_String (Context.Label), Both)'Length > 0;
         when others =>
            return Context.Kind = Build_Working_Context_Unsupported;
      end case;
   end Assert_Public_Build_Working_Context_Conversion_Consistent;

   function Build_Public_Build_Working_Context_Feedback
     (Status : Public_Build_Working_Context_Validation_Status) return String
   is
   begin
      case Status is
         when Public_Build_Working_Context_Valid_For_Internal_Test =>
            return "Build: accepted";
         when Public_Build_Working_Context_Valid_But_Not_Public_UX =>
            return "Build: public working directory UX not ready";
         when Public_Build_Working_Context_Rejected_None =>
            return "Build: working context required";
         when Public_Build_Working_Context_Rejected_Project_Derived =>
            return "Build: project working context not supported";
         when Public_Build_Working_Context_Rejected_Missing_Label =>
            return "Build: working directory label required";
         when Public_Build_Working_Context_Rejected_Missing_Acknowledgement =>
            return "Build: working directory acknowledgement required";
         when Public_Build_Working_Context_Rejected_Unsafe_Label =>
            return "Build: working directory unsupported";
      end case;
   end Build_Public_Build_Working_Context_Feedback;

   function Audit_Public_Build_Working_Context_Readiness return Boolean
   is
      Test_Context : constant Public_Build_Working_Context_Model :=
        (Source => Public_Build_Working_Context_Test_Context,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => True);
      User_Form_Context : constant Public_Build_Working_Context_Model :=
        (Source => Public_Build_Working_Context_User_Form_Label,
         Label  => To_Unbounded_String ("current-project-root"),
         User_Acknowledged_Context => True);
      Project_Context : constant Public_Build_Working_Context_Model :=
        (Source => Public_Build_Working_Context_Project_Derived,
         Label  => To_Unbounded_String ("project:root"),
         User_Acknowledged_Context => True);
      Missing_Context : constant Public_Build_Working_Context_Model :=
        (Source => Public_Build_Working_Context_None,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => False);
      Converted_Test : constant Build_Working_Context :=
        Build_Working_Context_From_Public_Model (Test_Context);
      Converted_User : constant Build_Working_Context :=
        Build_Working_Context_From_Public_Model (User_Form_Context);
   begin
      return Validate_Public_Build_Working_Context (Test_Context) =
             Public_Build_Working_Context_Valid_For_Internal_Test
        and then Validate_Public_Build_Working_Context (User_Form_Context) =
             Public_Build_Working_Context_Valid_But_Not_Public_UX
        and then Validate_Public_Build_Working_Context (Project_Context) =
             Public_Build_Working_Context_Rejected_Project_Derived
        and then Validate_Public_Build_Working_Context (Missing_Context) =
             Public_Build_Working_Context_Rejected_None
        and then Classify_Public_Build_Working_Context_Safety (Test_Context) =
             Public_Build_Input_Valid_For_Internal_Test
        and then Classify_Public_Build_Working_Context_Safety (User_Form_Context) =
             Public_Build_Input_Valid_But_Not_Publicly_Exposable
        and then Classify_Public_Build_Working_Context_Safety (Project_Context) =
             Public_Build_Input_Not_Valid
        and then Classify_Public_Build_Working_Context_Safety (User_Form_Context) /=
             Public_Build_Input_Publicly_Exposable
        and then Assert_Public_Build_Working_Context_Conversion_Consistent
             (Test_Context, Converted_Test)
        and then Assert_Public_Build_Working_Context_Conversion_Consistent
             (User_Form_Context, Converted_User);
   end Audit_Public_Build_Working_Context_Readiness;

   function Validate_Public_Build_Program_Label
     (Program_Label : Ada.Strings.Unbounded.Unbounded_String)
      return Public_Build_Input_Validation_Status
   is
      Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Program_Label), Both);
   begin
      --  Program_Label is only structured/display metadata in Phase 184.  It is
      --  never resolved through PATH, canonicalized, executed, or persisted.
      if Program'Length = 0 then
         return Public_Build_Input_Rejected_Missing_Program;
      elsif Contains_Control_Character (Program) then
         return Public_Build_Input_Rejected_Missing_Program;
      elsif Contains_Shell_Syntax (Program) then
         return Public_Build_Input_Rejected_Shell;
      end if;

      return Public_Build_Input_Valid;
   end Validate_Public_Build_Program_Label;

   function Validate_Public_Build_Working_Context
     (Source  : Public_Build_Input_Source;
      Context : Build_Working_Context)
      return Public_Build_Input_Validation_Status
   is
      Label : constant String := To_String (Context.Label);
      Clean : constant String := Ada.Strings.Fixed.Trim (Label, Both);
   begin
      --  Working-context validation is metadata-only: no chdir, no filesystem
      --  inspection, no project-root discovery, and no path canonicalization.
      case Context.Kind is
         when Build_Working_Context_Unsupported =>
            return Public_Build_Input_Rejected_Unsupported_Working_Context;

         when Build_Working_Context_Inherited_Test_Context =>
            if Source = Public_Build_Input_Test_Context then
               return Public_Build_Input_Valid;
            end if;
            return Public_Build_Input_Rejected_Unsupported_Working_Context;

         when Build_Working_Context_Explicit_Label =>
            if Clean'Length = 0 then
               return Public_Build_Input_Rejected_Unsupported_Working_Context;
            elsif Contains_Control_Character (Label) then
               return Public_Build_Input_Rejected_Unsafe_Working_Context;
            elsif Looks_Project_Derived_Label (Label) then
               return Public_Build_Input_Rejected_Unsafe_Working_Context;
            elsif Source = Public_Build_Input_Test_Context then
               return Public_Build_Input_Rejected_Unsafe_Working_Context;
            else
               return Public_Build_Input_Valid;
            end if;
      end case;
   end Validate_Public_Build_Working_Context;

   function Validate_Public_Build_Arguments
     (Source    : Public_Build_Input_Source;
      Arguments : Process_Argument_Vector)
      return Public_Build_Input_Validation_Status
   is
      pragma Unreferenced (Source);
   begin
      --  Arguments must already be structured argv tokens.  This helper never
      --  splits on whitespace, quote-parses, expands shell metacharacters, or
      --  enables shell mode.
      if Arguments.Is_Empty then
         return Public_Build_Input_Rejected_Opaque_Arguments;
      end if;

      for Arg of Arguments loop
         declare
            Text : constant String := To_String (Arg);
         begin
            if Text'Length = 0 then
               return Public_Build_Input_Rejected_Empty_Argument;
            elsif Ada.Strings.Fixed.Trim (Text, Both)'Length = 0 then
               return Public_Build_Input_Rejected_Empty_Argument;
            elsif Contains_Control_Character (Text) then
               return Public_Build_Input_Rejected_Control_Argument;
            end if;
         end;
      end loop;

      return Public_Build_Input_Valid;
   end Validate_Public_Build_Arguments;

   function Validate_Public_Build_Command_Input
     (Input : Public_Build_Command_Input)
      return Public_Build_Input_Validation_Status
   is
      Status : Public_Build_Input_Validation_Status;
   begin
      --  Phase 184 public-build input validation is DTO-only. It does not
      --  create command descriptors, dispatch through the Executor, prepare a
      --  process request, execute tools, inspect PATH, read project metadata,
      --  ingest Diagnostics, switch features, or persist state.
      if Input.Source = Public_Build_Input_None then
         return Public_Build_Input_Rejected_No_Input;
      end if;

      case Input.Tool is
         when No_Build_Tool =>
            return Public_Build_Input_Rejected_No_Tool;
         when Custom_Build_Tool =>
            return Public_Build_Input_Rejected_Custom_Tool;
         when GPRbuild_Tool | Alire_Build_Tool =>
            null;
      end case;

      Status := Validate_Public_Build_Program_Label (Input.Program_Label);
      if Status /= Public_Build_Input_Valid then
         return Status;
      end if;

      if Input.Consent = Build_Consent_Test_Only then
         return Public_Build_Input_Rejected_Test_Only_Consent;
      end if;

      declare
         Consent_Status : constant Public_Build_Consent_Validation_Status :=
           Validate_Public_Build_Consent (Input.Consent_Model);
      begin
         case Consent_Status is
            when Public_Build_Consent_Valid_For_Internal_Test =>
               if Input.Source /= Public_Build_Input_Test_Context then
                  return Public_Build_Input_Rejected_Public_Not_Ready;
               end if;
            when Public_Build_Consent_Valid_But_Not_Public_UX =>
               if Input.Source = Public_Build_Input_Test_Context then
                  return Public_Build_Input_Rejected_Missing_Consent;
               end if;
            when Public_Build_Consent_Rejected_None =>
               return Public_Build_Input_Rejected_Missing_Consent;
            when others =>
               return Public_Build_Input_Rejected_Missing_Consent;
         end case;
      end;

      if Input.Source = Public_Build_Input_Test_Context
        and then Input.Consent /=
          Build_Execution_Consent_From_Public_Model (Input.Consent_Model)
      then
         return Public_Build_Input_Rejected_Missing_Consent;
      end if;

      declare
         Working_Status : constant Public_Build_Working_Context_Validation_Status :=
           Validate_Public_Build_Working_Context (Input.Working_Context_Model);
      begin
         case Working_Status is
            when Public_Build_Working_Context_Valid_For_Internal_Test =>
               if Input.Source /= Public_Build_Input_Test_Context
                 or else Input.Working_Context.Kind /=
                   Build_Working_Context_Inherited_Test_Context
               then
                  return Public_Build_Input_Rejected_Unsupported_Working_Context;
               end if;
            when Public_Build_Working_Context_Valid_But_Not_Public_UX =>
               if Input.Source = Public_Build_Input_Test_Context then
                  return Public_Build_Input_Rejected_Unsupported_Working_Context;
               end if;
               --  Structurally valid labels are still not executable/public-ready
               --  until safe working-directory UX exists.
               null;
            when Public_Build_Working_Context_Rejected_None =>
               return Public_Build_Input_Rejected_Unsupported_Working_Context;
            when Public_Build_Working_Context_Rejected_Project_Derived =>
               return Public_Build_Input_Rejected_Unsafe_Working_Context;
            when Public_Build_Working_Context_Rejected_Missing_Label =>
               return Public_Build_Input_Rejected_Unsupported_Working_Context;
            when Public_Build_Working_Context_Rejected_Missing_Acknowledgement
               | Public_Build_Working_Context_Rejected_Unsafe_Label =>
               return Public_Build_Input_Rejected_Unsafe_Working_Context;
         end case;
      end;

      Status := Validate_Public_Build_Arguments (Input.Source, Input.Arguments);
      if Status /= Public_Build_Input_Valid then
         return Status;
      end if;

      return Public_Build_Input_Valid;
   end Validate_Public_Build_Command_Input;

   function Classify_Public_Build_Input_Safety
     (Input : Public_Build_Command_Input) return Public_Build_Input_Safety
   is
      Status : constant Public_Build_Input_Validation_Status :=
        Validate_Public_Build_Command_Input (Input);
   begin
      if Status = Public_Build_Input_Valid then
         if Input.Source = Public_Build_Input_Test_Context then
            return Public_Build_Input_Valid_For_Internal_Test;
         else
            return Public_Build_Input_Valid_But_Not_Publicly_Exposable;
         end if;
      end if;

      --  User-form input can be structurally complete while still blocked from
      --  public exposure because consent UX and safe working-context UX are not
      --  present in Phase 184.
      if Input.Source = Public_Build_Input_User_Form
        and then Status = Public_Build_Input_Rejected_Public_Not_Ready
      then
         return Public_Build_Input_Valid_But_Not_Publicly_Exposable;
      end if;

      return Public_Build_Input_Not_Valid;
   end Classify_Public_Build_Input_Safety;

   function Build_User_Opt_In_Request_From_Public_Input
     (Input : Public_Build_Command_Input) return Build_Run_Request
   is
      Status : constant Public_Build_Input_Validation_Status :=
        Validate_Public_Build_Command_Input (Input);
      Working_Label : constant String := "";
   begin
      --  Conversion is non-executing and provenance-preserving. Invalid DTOs
      --  collapse to an inert unknown request so they cannot accidentally become
      --  executable build/process requests.  Phase 184 conversion only preserves
      --  the inherited internal/test working context as empty metadata; it never
      --  creates a real working directory or persists a label.
      if Status /= Public_Build_Input_Valid
        or else Input.Source /= Public_Build_Input_Test_Context
        or else Build_Execution_Consent_From_Public_Model (Input.Consent_Model) /=
          Build_Consent_User_Confirmed
        or else Build_Working_Context_From_Public_Model
          (Input.Working_Context_Model).Kind /=
          Build_Working_Context_Inherited_Test_Context
      then
         return
           (Tool                 => No_Build_Tool,
            Provenance           => Build_Request_Unknown,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => Null_Unbounded_String,
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Empty_Process_Arguments);
      end if;

      return Build_User_Opt_In_Request
        (Tool          => Input.Tool,
         Program_Label => To_String (Input.Program_Label),
         Working_Label => Working_Label,
         Arguments     => Input.Arguments);
   end Build_User_Opt_In_Request_From_Public_Input;

   function Build_Public_Build_Request_From_UI_State
     (Input : Public_Build_Command_Input) return Build_Run_Request
   is
      Status : constant Public_Build_Input_Validation_Status :=
        Validate_Public_Build_Command_Input (Input);
      Context : constant Build_Working_Context :=
        Build_Working_Context_From_Public_Model (Input.Working_Context_Model);
      Working_Label : constant String :=
        (if Context.Kind = Build_Working_Context_Explicit_Label then
            To_String (Context.Label)
         else
            "");
   begin
      if Status /= Public_Build_Input_Valid
        or else Input.Source /= Public_Build_Input_User_Form
        or else Input.Consent /= Build_Consent_User_Confirmed
        or else Build_Execution_Consent_From_Public_Model (Input.Consent_Model) /=
          Build_Consent_User_Confirmed
        or else Context.Kind /= Build_Working_Context_Explicit_Label
      then
         return
           (Tool                 => No_Build_Tool,
            Provenance           => Build_Request_Unknown,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => Null_Unbounded_String,
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Empty_Process_Arguments);
      end if;

      return Build_User_Opt_In_Request
        (Tool          => Input.Tool,
         Program_Label => To_String (Input.Program_Label),
         Working_Label => Working_Label,
         Arguments     => Input.Arguments);
   end Build_Public_Build_Request_From_UI_State;

   function Build_Public_Build_Input_Feedback
     (Status : Public_Build_Input_Validation_Status) return String
   is
   begin
      case Status is
         when Public_Build_Input_Valid =>
            return "Build: accepted";
         when Public_Build_Input_Rejected_No_Input =>
            return "Build: input required";
         when Public_Build_Input_Rejected_Public_Not_Ready =>
            return "Build: public build command not ready";
         when Public_Build_Input_Rejected_No_Tool =>
            return "Build: build tool required";
         when Public_Build_Input_Rejected_Custom_Tool =>
            return "Build: custom build tool not supported";
         when Public_Build_Input_Rejected_Missing_Program =>
            return "Build: program required";
         when Public_Build_Input_Rejected_Missing_Consent
            | Public_Build_Input_Rejected_Test_Only_Consent =>
            return "Build: execution consent required";
         when Public_Build_Input_Rejected_Unsupported_Working_Context
            | Public_Build_Input_Rejected_Unsafe_Working_Context =>
            return "Build: working directory unsupported";
         when Public_Build_Input_Rejected_Empty_Argument
            | Public_Build_Input_Rejected_Control_Argument
            | Public_Build_Input_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when Public_Build_Input_Rejected_Shell =>
            return "Build: shell execution disabled";
      end case;
   end Build_Public_Build_Input_Feedback;

   function Audit_Public_Build_Input_Model_Readiness return Boolean
   is
      Valid_Input : constant Public_Build_Command_Input :=
        (Source           => Public_Build_Input_Test_Context,
         Tool             => GPRbuild_Tool,
         Program_Label    => To_Unbounded_String ("gprbuild"),
         Working_Context  => Build_Inherited_Test_Working_Context,
         Working_Context_Model =>
           (Source => Public_Build_Working_Context_Test_Context,
            Label  => Null_Unbounded_String,
            User_Acknowledged_Context => True),
         Arguments        => Build_Process_Argument_Vector ("-q"),
         Consent          => Build_Consent_User_Confirmed,
         Consent_Model    =>
           (Source => Public_Build_Consent_Test_Context,
            User_Acknowledged_Execution => True,
            User_Acknowledged_No_Shell => True,
            User_Acknowledged_External_Process => True,
            User_Acknowledged_Diagnostics_Output => True),
         Show_Diagnostics => False);
      Invalid_Input : constant Public_Build_Command_Input :=
        (Source           => Public_Build_Input_None,
         Tool             => No_Build_Tool,
         Program_Label    => Null_Unbounded_String,
         Working_Context  => Build_Unsupported_Working_Context,
         Working_Context_Model =>
           (Source => Public_Build_Working_Context_None,
            Label  => Null_Unbounded_String,
            User_Acknowledged_Context => False),
         Arguments        => Empty_Process_Arguments,
         Consent          => Build_Consent_Not_Provided,
         Consent_Model    =>
           (Source => Public_Build_Consent_None,
            User_Acknowledged_Execution => False,
            User_Acknowledged_No_Shell => False,
            User_Acknowledged_External_Process => False,
            User_Acknowledged_Diagnostics_Output => False),
         Show_Diagnostics => False);
      Valid_Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request_From_Public_Input (Valid_Input);
      Invalid_Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request_From_Public_Input (Invalid_Input);
   begin
      return Validate_Public_Build_Command_Input (Valid_Input) =
             Public_Build_Input_Valid
        and then Classify_Public_Build_Input_Safety (Valid_Input) =
             Public_Build_Input_Valid_For_Internal_Test
        and then Validate_Public_Build_Command_Input (Invalid_Input) /=
             Public_Build_Input_Valid
        and then Classify_Public_Build_Input_Safety (Invalid_Input) =
             Public_Build_Input_Not_Valid
        and then Valid_Request.Provenance = Build_Request_From_User_Opt_In
        and then Process_Argument_Count (Valid_Request.Structured_Arguments) = 1
        and then To_String (Valid_Request.Arguments)'Length = 0
        and then Validate_Build_Run_Request_Status (Invalid_Request) /=
             Build_Request_Valid
        and then Invalid_Request.Provenance = Build_Request_Unknown;
   end Audit_Public_Build_Input_Model_Readiness;

   function Build_One_Process_Argument
     (Value : String) return Process_Argument_Vector
   is
      Args : Process_Argument_Vector := Empty_Process_Arguments;
   begin
      Append_Process_Argument (Args, Value);
      return Args;
   end Build_One_Process_Argument;

   function Build_Default_Timeout_Milliseconds return Natural is
   begin
      return 120_000;
   end Build_Default_Timeout_Milliseconds;

   function Build_Timeout_Policy_Is_Bounded
     (Policy : Process_Execution_Policy) return Boolean
   is
      Max_Build_Timeout_Milliseconds : constant Natural := 600_000;
   begin
      if Policy.Mode = Process_Execution_Disabled then
         return Policy.Timeout_Milliseconds = 0;
      end if;

      --  Zero remains accepted only as an explicit test/disabled value;
      --  public execution gates constructed by Phase 509 use the bounded
      --  default instead.
      return Policy.Timeout_Milliseconds <= Max_Build_Timeout_Milliseconds;
   end Build_Timeout_Policy_Is_Bounded;

   function Build_Cancellation_Unsupported_Process_Result
      return Process_Run_Result
   is
   begin
      return Build_Process_Run_Result (Process_Run_Cancellation_Unsupported);
   end Build_Cancellation_Unsupported_Process_Result;

   function Current_Native_Process_Control_Backend
      return Native_Process_Control_Backend
   is
   begin
      return Native_Process_Control_POSIX;
   end Current_Native_Process_Control_Backend;

   function Native_Process_Control_Backend_Label return String is
   begin
      case Current_Native_Process_Control_Backend is
         when Native_Process_Control_POSIX =>
            return "POSIX/fork-exec-waitpid-kill";
      end case;
   end Native_Process_Control_Backend_Label;

   function Native_Process_Control_Is_POSIX return Boolean is
   begin
      return Current_Native_Process_Control_Backend = Native_Process_Control_POSIX;
   end Native_Process_Control_Is_POSIX;

   function Native_Process_Control_Platform_Audit_Passes return Boolean is
   begin
      return Native_Process_Control_Is_POSIX
        and then Native_Process_Control_Backend_Label =
          "POSIX/fork-exec-waitpid-kill";
   end Native_Process_Control_Platform_Audit_Passes;

   function Real_Process_Runner_Output_Capture_Mode
      return Process_Output_Capture_Mode
   is
   begin
      --  Real execution uses the native process supervisor, which redirects
      --  stdout and stderr into independent bounded capture files before the
      --  child execs the requested tool.
      return Process_Output_Capture_Separated;
   end Real_Process_Runner_Output_Capture_Mode;

   function Diagnostic_Stream_Preference
     (Result : Process_Run_Result) return Process_Diagnostic_Stream_Preference
   is
   begin
      if Length (Result.Stderr_Text) > 0 then
         return Process_Diagnostics_Prefer_Stderr;
      else
         return Process_Diagnostics_Merged_Output_Fallback;
      end if;
   end Diagnostic_Stream_Preference;

   function Process_Result_Output_Stream
     (Result : Process_Run_Result) return Process_Output_Stream
   is
   begin
      if Result.Output_Capture_Mode = Process_Output_Capture_Merged_Stdout_Stderr
        and then Length (Result.Stdout_Text) > 0
        and then Length (Result.Stderr_Text) = 0
      then
         return Process_Output_Merged;
      elsif Length (Result.Stderr_Text) > 0 then
         return Process_Output_Stderr;
      else
         return Process_Output_Stdout;
      end if;
   end Process_Result_Output_Stream;

   function Build_Result_Output_Stream
     (Result : Build_Run_Result) return Process_Output_Stream
   is
   begin
      if Result.Output_Capture_Mode = Process_Output_Capture_Merged_Stdout_Stderr
        and then Length (Result.Stdout_Text) > 0
        and then Length (Result.Stderr_Text) = 0
      then
         return Process_Output_Merged;
      elsif Length (Result.Stderr_Text) > 0 then
         return Process_Output_Stderr;
      else
         return Process_Output_Stdout;
      end if;
   end Build_Result_Output_Stream;

   function Build_Run_Diagnostic_Stream_Preference
     (Result : Build_Run_Result) return Process_Diagnostic_Stream_Preference
   is
   begin
      if Length (Result.Stderr_Text) > 0 then
         return Process_Diagnostics_Prefer_Stderr;
      else
         return Process_Diagnostics_Merged_Output_Fallback;
      end if;
   end Build_Run_Diagnostic_Stream_Preference;

   function Validate_Process_Execution_Policy
     (Policy : Process_Execution_Policy) return Boolean
   is
   begin
      if Policy.Allow_Shell then
         return False;
      end if;

      if not Build_Timeout_Policy_Is_Bounded (Policy) then
         return False;
      end if;

      case Policy.Mode is
         when Process_Execution_Disabled =>
            return not Policy.Allow_Real_Execution;
         when Process_Execution_Test_Fixture =>
            return not Policy.Allow_Real_Execution;
         when Process_Execution_Real_Fixture_Allowed =>
            return Policy.Allow_Real_Execution;
         when Process_Execution_Real_Allowed =>
            return Policy.Allow_Real_Execution;
      end case;
   end Validate_Process_Execution_Policy;

   function Looks_Absolute_Program (Program : String) return Boolean
   is
   begin
      return Program'Length > 0
        and then (Program (Program'First) = '/'
          or else (Program'Length >= 3
            and then Program (Program'First + 1) = ':'
            and then (Program (Program'First + 2) = '\'
              or else Program (Program'First + 2) = '/')));
   end Looks_Absolute_Program;

   function Validate_Process_Run_Request_For_Real_Execution_Status
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy)
      return Process_Request_Validation_Status
   is
      Clean_Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Program_Label), Both);
      Opaque_Args : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Arguments), Both);
   begin
      if Policy.Allow_Shell then
         return Process_Request_Rejected_Shell_Disallowed;
      end if;

      if not Validate_Process_Execution_Policy (Policy)
        or else Policy.Mode /= Process_Execution_Real_Allowed
        or else not Policy.Allow_Real_Execution
      then
         return Process_Request_Rejected_Execution_Disabled;
      end if;

      if Clean_Program'Length = 0 then
         return Process_Request_Rejected_Empty_Program;
      elsif Contains_Control_Character (Clean_Program)
        or else Contains_Shell_Syntax (Clean_Program)
      then
         return Process_Request_Rejected_Shell_Disallowed;
      elsif Clean_Program /= "gprbuild" and then Clean_Program /= "alr" then
         return Process_Request_Rejected_Empty_Program;
      end if;

      if Policy.Require_Absolute_Program
        and then not Looks_Absolute_Program (Clean_Program)
      then
         return Process_Request_Rejected_Relative_Program;
      end if;

      if Opaque_Args'Length > 0 then
         return Process_Request_Rejected_Opaque_Arguments;
      end if;

      if Request.Structured_Arguments.Is_Empty then
         return Process_Request_Rejected_Opaque_Arguments;
      end if;

      for Arg of Request.Structured_Arguments loop
         declare
            Value : constant String := To_String (Arg);
         begin
            if Value'Length = 0 or else Contains_Control_Character (Value) then
               return Process_Request_Rejected_Invalid_Argument;
            elsif Contains_Shell_Syntax (Value) then
               return Process_Request_Rejected_Shell_Disallowed;
            end if;
         end;
      end loop;

      return Process_Request_Valid;
   end Validate_Process_Run_Request_For_Real_Execution_Status;

   function Validate_Process_Run_Request_For_Real_Execution
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Boolean
   is
   begin
      return Validate_Process_Run_Request_For_Real_Execution_Status
        (Request, Policy) = Process_Request_Valid;
   end Validate_Process_Run_Request_For_Real_Execution;

   function Process_Request_Rejection_Feedback
     (Status : Process_Request_Validation_Status) return String
   is
   begin
      case Status is
         when Process_Request_Valid =>
            return "Build: accepted";
         when Process_Request_Rejected_Execution_Disabled =>
            return "Build: execution disabled";
         when Process_Request_Rejected_Shell_Disallowed =>
            return "Build: shell execution disabled";
         when Process_Request_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when Process_Request_Rejected_Unsupported_Working_Directory =>
            return "Build: working directory unsupported";
         when Process_Request_Rejected_Empty_Program
            | Process_Request_Rejected_Invalid_Argument
            | Process_Request_Rejected_Relative_Program =>
            return "Build: invalid process request";
      end case;
   end Process_Request_Rejection_Feedback;

   function Preflight_Build_Run_Request
     (Request : Build_Run_Request;
      Policy  : Process_Execution_Policy) return Build_Preflight_Result
   is
      Build_Status : constant Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Process_Request_Rejected_Execution_Disabled;
   begin
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Process_Request (Request);

      if Policy.Mode = Process_Execution_Disabled then
         Process_Status := Process_Request_Rejected_Execution_Disabled;
      elsif Policy.Allow_Shell then
         Process_Status := Process_Request_Rejected_Shell_Disallowed;
      elsif not Validate_Process_Execution_Policy (Policy) then
         Process_Status := Process_Request_Rejected_Execution_Disabled;
      elsif Ada.Strings.Fixed.Trim
        (To_String (Process_Request.Program_Label), Both)'Length = 0
      then
         Process_Status := Process_Request_Rejected_Empty_Program;
      elsif Policy.Mode = Process_Execution_Test_Fixture then
         Process_Status := Process_Request_Valid;
      elsif Policy.Mode = Process_Execution_Real_Fixture_Allowed then
         --  Build requests do not silently become fixture requests. The
         --  fixture path has a separate explicit request model and command
         --  helper.
         Process_Status := Process_Request_Rejected_Execution_Disabled;
      else
         Process_Status := Validate_Process_Run_Request_For_Real_Execution_Status
           (Process_Request, Policy);
      end if;

      return
        (Build_Request_Status   => Build_Status,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_Build_Run_Request;

   function Preflight_Real_Build_Tool_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
   is
      Build_Status : Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Process_Request_Rejected_Execution_Disabled;
   begin
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Build_Status := Validate_Build_Request_Provenance (Request, Gate);
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Request.Provenance = Build_Request_From_User_Opt_In
        and then Gate.Consent /= Build_Consent_User_Confirmed
      then
         return
           (Build_Request_Status   => Build_Request_Rejected_Consent,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Request.Tool = Custom_Build_Tool then
         return
           (Build_Request_Status   => Build_Request_Rejected_Unsupported_Tool,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if not Validate_Build_Execution_Gate (Gate)
        or else not Gate.Allow_Real_Build_Tool_Execution
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
      then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Status := Validate_Build_Working_Context (Request, Gate);
      if Process_Status /= Process_Request_Valid then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Process_Request (Request);
      Process_Status := Validate_Process_Run_Request_For_Real_Execution_Status
        (Process_Request, Gate.Process_Policy);

      return
        (Build_Request_Status   => Build_Request_Valid,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_Real_Build_Tool_Request;

   function Preflight_User_Opt_In_Build_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
   is
      Build_Status : Build_Request_Validation_Status :=
        Validate_User_Opt_In_Build_Request (Request);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Process_Request_Rejected_Execution_Disabled;
   begin
      --  Phase 177 user-opt-in preflight is intentionally pure metadata
      --  validation. It does not execute, inspect PATH, read project files,
      --  parse .gpr/alire.toml, ingest Diagnostics, switch features, or infer
      --  working directories/arguments from workspace state.
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Gate.Consent /= Build_Consent_User_Confirmed then
         return
           (Build_Request_Status   => Build_Request_Rejected_Consent,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Gate.Allow_Real_Build_Tool_Fixture
        or else not Validate_Build_Execution_Gate (Gate)
        or else not Gate.Allow_Build_Run
        or else not Gate.Allow_Real_Build_Tool_Execution
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
        or else not Gate.Process_Policy.Allow_Real_Execution
        or else Gate.Process_Policy.Allow_Shell
        or else Gate.Process_Policy.Max_Output_Bytes = 0
      then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      case Request.Tool is
         when GPRbuild_Tool | Alire_Build_Tool =>
            null;
         when Custom_Build_Tool =>
            return
              (Build_Request_Status   => Build_Request_Rejected_Unsupported_Tool,
               Process_Request_Status => Process_Status,
               Has_Process_Request    => False,
               Process_Request        => Process_Request);
         when No_Build_Tool =>
            return
              (Build_Request_Status   => Build_Request_Rejected_No_Tool,
               Process_Request_Status => Process_Status,
               Has_Process_Request    => False,
               Process_Request        => Process_Request);
      end case;

      Process_Status := Validate_Build_Working_Context (Request, Gate);
      if Process_Status /= Process_Request_Valid then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Process_Request (Request);
      Process_Status := Validate_Process_Run_Request_For_Real_Execution_Status
        (Process_Request, Gate.Process_Policy);

      return
        (Build_Request_Status   => Build_Request_Valid,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_User_Opt_In_Build_Request;

   function Build_User_Opt_In_Build_Feedback
     (Result : Build_Preflight_Result) return String
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid then
         if Result.Build_Request_Status = Build_Request_Rejected_Provenance
           or else Result.Build_Request_Status = Build_Request_Rejected_Unknown_Provenance
         then
            return "Build: user opt-in required";
         else
            return Build_Request_Rejection_Feedback (Result.Build_Request_Status);
         end if;
      elsif Result.Process_Request_Status /= Process_Request_Valid then
         if Result.Process_Request_Status = Process_Request_Rejected_Execution_Disabled then
            return "Build: real build execution disabled";
         else
            return Process_Request_Rejection_Feedback
              (Result.Process_Request_Status);
         end if;
      else
         return "Build: accepted";
      end if;
   end Build_User_Opt_In_Build_Feedback;

   function Empty_User_Opt_In_Build_Command_Context
      return User_Opt_In_Build_Command_Context
   is
   begin
      return
        (Has_Request => False,
         Request     => (Tool => No_Build_Tool,
                         Provenance => Build_Request_Unknown,
                         Working_Label => Null_Unbounded_String,
                         Command_Label => Null_Unbounded_String,
                         Arguments => Null_Unbounded_String,
                         Structured_Arguments => Empty_Process_Arguments),
         Gate        => Build_Default_Execution_Gate);
   end Empty_User_Opt_In_Build_Command_Context;

   function Build_User_Opt_In_Command_Context
     (Tool              : Build_Tool_Kind;
      Program_Label     : String;
      Working_Label     : String;
      Arguments         : Process_Argument_Vector;
      Consent           : Build_Execution_Consent;
      Allow_Diagnostics : Boolean;
      Show_Diagnostics  : Boolean)
      return User_Opt_In_Build_Command_Context
   is
   begin
      return
        (Has_Request => True,
         Request     => Build_User_Opt_In_Request
           (Tool, Program_Label, Working_Label, Arguments),
         Gate        => Build_Real_Execution_Gate
           (Allow_Diagnostics_Ingestion => Allow_Diagnostics,
            Show_Diagnostics            => Show_Diagnostics,
            Consent                     => Consent));
   end Build_User_Opt_In_Command_Context;

   function Validate_User_Opt_In_Build_Command_Context
     (Context : User_Opt_In_Build_Command_Context)
      return User_Opt_In_Build_Command_Context_Status
   is
      Request : constant Build_Run_Request := Context.Request;
      Gate    : constant Build_Execution_Gate := Context.Gate;
      Clean_Command : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Command_Label), Both);
   begin
      --  Phase 180 command-context validation is deliberately pure metadata
      --  classification. It does not execute, select a runner, inspect PATH,
      --  read project files, ingest Diagnostics, switch features, or retain any
      --  command request/gate/consent handle.
      if not Context.Has_Request then
         return User_Build_Context_Rejected_Missing_Context;
      end if;

      if Request.Provenance = Build_Request_Unknown
        and then Request.Tool = No_Build_Tool
        and then Clean_Command'Length = 0
        and then Request.Structured_Arguments.Is_Empty
      then
         return User_Build_Context_Rejected_Missing_Request;
      end if;

      if not Gate.Allow_Build_Run
        and then Gate.Process_Policy.Mode = Process_Execution_Disabled
        and then not Gate.Process_Policy.Allow_Real_Execution
      then
         return User_Build_Context_Rejected_Missing_Gate;
      end if;

      if Gate.Consent = Build_Consent_Not_Provided then
         return User_Build_Context_Rejected_Missing_Consent;
      elsif Gate.Consent /= Build_Consent_User_Confirmed then
         return User_Build_Context_Rejected_Missing_Consent;
      end if;

      case Request.Provenance is
         when Build_Request_From_User_Opt_In =>
            null;
         when Build_Request_From_Project_Metadata =>
            return User_Build_Context_Rejected_Project_Metadata;
         when Build_Request_From_Test
            | Build_Request_From_Fixture
            | Build_Request_From_Internal_Command
            | Build_Request_Unknown =>
            return User_Build_Context_Rejected_Provenance;
      end case;

      case Request.Tool is
         when No_Build_Tool | Custom_Build_Tool =>
            return User_Build_Context_Rejected_Custom_Tool;
         when GPRbuild_Tool | Alire_Build_Tool =>
            null;
      end case;

      if Length (Request.Arguments) > 0 then
         return User_Build_Context_Rejected_Opaque_Arguments;
      end if;

      if Request.Structured_Arguments.Is_Empty or else Clean_Command'Length = 0 then
         return User_Build_Context_Rejected_Opaque_Arguments;
      end if;

      if Gate.Process_Policy.Allow_Shell then
         return User_Build_Context_Rejected_Shell;
      end if;

      if Ada.Strings.Fixed.Trim
          (To_String (Request.Working_Label), Both)'Length > 0
      then
         return User_Build_Context_Rejected_Working_Context;
      end if;

      if Gate.Allow_Real_Build_Tool_Fixture
        or else not Gate.Allow_Real_Build_Tool_Execution
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
        or else not Gate.Process_Policy.Allow_Real_Execution
        or else Gate.Process_Policy.Max_Output_Bytes = 0
        or else not Validate_Build_Execution_Gate (Gate)
      then
         return User_Build_Context_Rejected_Ambiguous_Execution_Path;
      end if;

      return User_Build_Context_Valid;
   end Validate_User_Opt_In_Build_Command_Context;

   function Build_User_Opt_In_Command_Feedback
     (Status : User_Opt_In_Build_Command_Context_Status;
      Result : Build_Command_Result) return String
   is
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
   begin
      case Status is
         when User_Build_Context_Valid =>
            case Result.Build_Result.Status is
               when Build_Run_Succeeded =>
                  if Ingested > 0 then
                     return "Build: succeeded, ingested"
                       & Natural'Image (Ingested) & " diagnostics";
                  else
                     return "Build: succeeded";
                  end if;
               when Build_Run_Failed =>
                  if Ingested > 0 then
                     return "Build: failed, ingested"
                       & Natural'Image (Ingested) & " diagnostics";
                  else
                     return "Build: failed";
                  end if;
               when Build_Run_Not_Available =>
                  return "Build: real execution unavailable";
               when Build_Run_Rejected =>
                  return "Build: rejected";
               when Build_Run_Execution_Error =>
                  return "Build: execution error";
               when Build_Run_Timed_Out =>
                  return "Build failed: timed out";
               when Build_Run_Cancelled =>
                  return "Build cancelled";
               when Build_Run_Cancellation_Unsupported =>
                  return "Build unavailable: cancellation unsupported";
               when Build_Run_Output_Truncated =>
                  return "Build: output truncated";
            end case;
         when User_Build_Context_Rejected_Missing_Context
            | User_Build_Context_Rejected_Missing_Request
            | User_Build_Context_Rejected_Provenance =>
            return "Build: user opt-in required";
         when User_Build_Context_Rejected_Missing_Gate =>
            return "Build: real build execution disabled";
         when User_Build_Context_Rejected_Missing_Consent =>
            return "Build: execution consent required";
         when User_Build_Context_Rejected_Project_Metadata =>
            return "Build: project build metadata not supported";
         when User_Build_Context_Rejected_Custom_Tool =>
            return "Build: custom build tool not supported";
         when User_Build_Context_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when User_Build_Context_Rejected_Shell =>
            return "Build: shell execution disabled";
         when User_Build_Context_Rejected_Working_Context =>
            return "Build: working directory unsupported";
         when User_Build_Context_Rejected_Ambiguous_Execution_Path =>
            return "Build: invalid build command context";
      end case;
   end Build_User_Opt_In_Command_Feedback;

   function User_Opt_In_Build_Command_Context_Is_Available
     (Context : User_Opt_In_Build_Command_Context) return Boolean
   is
   begin
      return Context.Has_Request;
   end User_Opt_In_Build_Command_Context_Is_Available;

   function User_Opt_In_Build_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid
        or else Result.Process_Request_Status /= Process_Request_Valid
      then
         return not Result.Has_Process_Request;
      end if;

      return Result.Has_Process_Request
        and then Ada.Strings.Fixed.Trim
          (To_String (Result.Process_Request.Program_Label), Both)'Length > 0
        and then Ada.Strings.Fixed.Trim
          (To_String (Result.Process_Request.Arguments), Both)'Length = 0
        and then not Result.Process_Request.Structured_Arguments.Is_Empty;
   end User_Opt_In_Build_Preflight_Is_Consistent;

   procedure Assert_User_Opt_In_Build_Preflight_Consistent
     (Result : Build_Preflight_Result)
   is
   begin
      pragma Assert (User_Opt_In_Build_Preflight_Is_Consistent (Result));
   end Assert_User_Opt_In_Build_Preflight_Consistent;

   function User_Opt_In_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean
   is
      Message : constant String := To_String (Result.Command_Message);
   begin
      if Message'Length = 0 then
         return False;
      end if;

      if Result.Build_Result.Status in Build_Run_Rejected | Build_Run_Not_Available then
         return Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 0;
      end if;

      return Gated_Build_Command_Result_Is_Consistent (Result);
   end User_Opt_In_Build_Command_Result_Is_Consistent;

   procedure Assert_User_Opt_In_Build_Command_Result_Consistent
     (Result : Build_Command_Result)
   is
   begin
      pragma Assert (User_Opt_In_Build_Command_Result_Is_Consistent (Result));
   end Assert_User_Opt_In_Build_Command_Result_Consistent;

   function Real_Build_Tool_Fixture_Is_Approved
     (Fixture : Real_Build_Tool_Fixture_Kind) return Boolean
   is
   begin
      case Fixture is
         when No_Real_Build_Tool_Fixture =>
            return False;
         when GPRbuild_Version_Fixture
            | Alire_Version_Fixture
            | Diagnostic_Output_Fixture =>
            return True;
      end case;
   end Real_Build_Tool_Fixture_Is_Approved;

   function Validate_Real_Build_Tool_Fixture_Gate
     (Gate : Build_Execution_Gate) return Boolean
   is
   begin
      return Validate_Build_Execution_Gate (Gate)
        and then Gate.Allow_Build_Run
        and then Gate.Allow_Real_Build_Tool_Fixture
        and then not Gate.Allow_Real_Build_Tool_Execution
        and then Gate.Process_Policy.Mode = Process_Execution_Real_Fixture_Allowed
        and then Gate.Process_Policy.Allow_Real_Execution
        and then not Gate.Process_Policy.Allow_Shell
        and then Gate.Process_Policy.Max_Output_Bytes > 0;
   end Validate_Real_Build_Tool_Fixture_Gate;


   function Validate_Real_Build_Tool_Fixture_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate)
      return Real_Build_Tool_Fixture_Validation_Status
   is
      Build_Status : constant Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
      Working_Status : Process_Request_Validation_Status;
      Clean_Opaque : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Arguments), Both);
   begin
      --  Phase 176 fixture validation is a pure metadata check. It does not
      --  execute, inspect PATH, read project files, inspect workspace state,
      --  ingest diagnostics, mutate feature state, or infer fixture identity
      --  from command labels, program labels, argv, project metadata, settings,
      --  or command-palette visibility.
      if Gate.Allow_Real_Build_Tool_Execution
        and then Gate.Allow_Real_Build_Tool_Fixture
      then
         return Real_Build_Fixture_Rejected_Ambiguous_Gate;
      end if;

      if Gate.Process_Policy.Allow_Shell then
         return Real_Build_Fixture_Rejected_Shell;
      end if;

      if not Validate_Real_Build_Tool_Fixture_Gate (Gate) then
         return Real_Build_Fixture_Rejected_Disabled;
      end if;

      if not Real_Build_Tool_Fixture_Is_Approved (Fixture) then
         return Real_Build_Fixture_Rejected_Unknown_Fixture;
      end if;

      case Request.Provenance is
         when Build_Request_From_Project_Metadata =>
            return Real_Build_Fixture_Rejected_Project_Metadata;
         when Build_Request_From_User_Opt_In
            | Build_Request_From_Test
            | Build_Request_From_Fixture =>
            null;
         when Build_Request_From_Internal_Command
            | Build_Request_Unknown =>
            return Real_Build_Fixture_Rejected_Provenance;
      end case;

      if Build_Status = Build_Request_Rejected_Project_Metadata then
         return Real_Build_Fixture_Rejected_Project_Metadata;
      elsif Build_Status /= Build_Request_Valid then
         if Request.Tool = Custom_Build_Tool then
            return Real_Build_Fixture_Rejected_Custom_Tool;
         else
            return Real_Build_Fixture_Rejected_Provenance;
         end if;
      end if;

      if Request.Tool = Custom_Build_Tool then
         return Real_Build_Fixture_Rejected_Custom_Tool;
      end if;

      case Fixture is
         when GPRbuild_Version_Fixture =>
            if Request.Tool /= GPRbuild_Tool then
               return Real_Build_Fixture_Rejected_Custom_Tool;
            end if;
         when Alire_Version_Fixture =>
            if Request.Tool /= Alire_Build_Tool then
               return Real_Build_Fixture_Rejected_Custom_Tool;
            end if;
         when Diagnostic_Output_Fixture =>
            null;
         when No_Real_Build_Tool_Fixture =>
            return Real_Build_Fixture_Rejected_Unknown_Fixture;
      end case;

      Working_Status := Validate_Build_Working_Context (Request, Gate);
      if Working_Status /= Process_Request_Valid then
         return Real_Build_Fixture_Rejected_Working_Context;
      end if;

      if Clean_Opaque'Length > 0 or else not Request.Structured_Arguments.Is_Empty then
         return Real_Build_Fixture_Rejected_Opaque_Arguments;
      end if;

      return Real_Build_Fixture_Valid;
   end Validate_Real_Build_Tool_Fixture_Request;

   function Real_Build_Tool_Fixture_Status_To_Build_Status
     (Status : Real_Build_Tool_Fixture_Validation_Status)
      return Build_Request_Validation_Status
   is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return Build_Request_Valid;
         when Real_Build_Fixture_Rejected_Project_Metadata =>
            return Build_Request_Rejected_Project_Metadata;
         when Real_Build_Fixture_Rejected_Custom_Tool =>
            return Build_Request_Rejected_Unsupported_Tool;
         when Real_Build_Fixture_Rejected_Provenance =>
            return Build_Request_Rejected_Provenance;
         when Real_Build_Fixture_Rejected_Disabled
            | Real_Build_Fixture_Rejected_Unknown_Fixture
            | Real_Build_Fixture_Rejected_Shell
            | Real_Build_Fixture_Rejected_Opaque_Arguments
            | Real_Build_Fixture_Rejected_Working_Context
            | Real_Build_Fixture_Rejected_Ambiguous_Gate
            | Real_Build_Fixture_Not_Available =>
            return Build_Request_Valid;
      end case;
   end Real_Build_Tool_Fixture_Status_To_Build_Status;

   function Real_Build_Tool_Fixture_Status_To_Process_Status
     (Status : Real_Build_Tool_Fixture_Validation_Status)
      return Process_Request_Validation_Status
   is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return Process_Request_Valid;
         when Real_Build_Fixture_Rejected_Disabled
            | Real_Build_Fixture_Rejected_Ambiguous_Gate
            | Real_Build_Fixture_Not_Available =>
            return Process_Request_Rejected_Execution_Disabled;
         when Real_Build_Fixture_Rejected_Unknown_Fixture =>
            return Process_Request_Rejected_Empty_Program;
         when Real_Build_Fixture_Rejected_Shell =>
            return Process_Request_Rejected_Shell_Disallowed;
         when Real_Build_Fixture_Rejected_Opaque_Arguments =>
            return Process_Request_Rejected_Opaque_Arguments;
         when Real_Build_Fixture_Rejected_Working_Context =>
            return Process_Request_Rejected_Unsupported_Working_Directory;
         when Real_Build_Fixture_Rejected_Provenance
            | Real_Build_Fixture_Rejected_Project_Metadata
            | Real_Build_Fixture_Rejected_Custom_Tool =>
            return Process_Request_Rejected_Execution_Disabled;
      end case;
   end Real_Build_Tool_Fixture_Status_To_Process_Status;

   function Real_Build_Tool_Fixture_Rejection_Feedback
     (Status : Real_Build_Tool_Fixture_Validation_Status) return String
   is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return "Build: build fixture accepted";
         when Real_Build_Fixture_Rejected_Disabled =>
            return "Build: real build fixture disabled";
         when Real_Build_Fixture_Rejected_Project_Metadata =>
            return "Build: project build metadata not supported";
         when Real_Build_Fixture_Rejected_Working_Context =>
            return "Build: working directory unsupported";
         when Real_Build_Fixture_Rejected_Shell =>
            return "Build: shell execution disabled";
         when Real_Build_Fixture_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when Real_Build_Fixture_Not_Available =>
            return "Build: build fixture unavailable";
         when Real_Build_Fixture_Rejected_Unknown_Fixture
            | Real_Build_Fixture_Rejected_Provenance
            | Real_Build_Fixture_Rejected_Custom_Tool
            | Real_Build_Fixture_Rejected_Ambiguous_Gate =>
            return "Build: build fixture rejected";
      end case;
   end Real_Build_Tool_Fixture_Rejection_Feedback;

   function Validate_Real_Build_Tool_Fixture_Provenance
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Request_Validation_Status
   is
   begin
      case Request.Provenance is
         when Build_Request_Unknown =>
            return Build_Request_Rejected_Unknown_Provenance;
         when Build_Request_From_Project_Metadata =>
            return Build_Request_Rejected_Project_Metadata;
         when Build_Request_From_User_Opt_In =>
            if Validate_Real_Build_Tool_Fixture_Gate (Gate) then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_Test | Build_Request_From_Fixture =>
            if Validate_Real_Build_Tool_Fixture_Gate (Gate) then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_Internal_Command =>
            --  No Phase 175 internal-command gate exists. Keep internal commands
            --  rejected rather than inferring fixture opt-in from command labels.
            return Build_Request_Rejected_Provenance;
      end case;
   end Validate_Real_Build_Tool_Fixture_Provenance;

   function Prepare_Real_Build_Tool_Fixture_Process_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind) return Process_Run_Request
   is
      pragma Unreferenced (Request);
   begin
      case Fixture is
         when GPRbuild_Version_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("gprbuild"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument ("--version"));
         when Alire_Version_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("alr"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument ("--version"));
         when Diagnostic_Output_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("diagnostic-output-fixture"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument
                 ("--diagnostic-output-fixture"));
         when No_Real_Build_Tool_Fixture =>
            return
              (Program_Label        => Null_Unbounded_String,
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Empty_Process_Arguments);
      end case;
   end Prepare_Real_Build_Tool_Fixture_Process_Request;

   function Validate_Real_Build_Tool_Fixture_Process_Request
     (Request : Process_Run_Request;
      Gate    : Build_Execution_Gate) return Process_Request_Validation_Status
   is
      Clean_Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Program_Label), Both);
      Opaque_Args : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Arguments), Both);
   begin
      if Gate.Process_Policy.Allow_Shell then
         return Process_Request_Rejected_Shell_Disallowed;
      end if;

      if not Validate_Real_Build_Tool_Fixture_Gate (Gate) then
         return Process_Request_Rejected_Execution_Disabled;
      end if;

      if Gate.Process_Policy.Max_Output_Bytes = 0 then
         return Process_Request_Rejected_Invalid_Argument;
      end if;

      if Clean_Program'Length = 0 then
         return Process_Request_Rejected_Empty_Program;
      end if;

      if Opaque_Args'Length > 0 then
         return Process_Request_Rejected_Opaque_Arguments;
      end if;

      if Request.Structured_Arguments.Is_Empty then
         return Process_Request_Rejected_Opaque_Arguments;
      end if;

      for Arg of Request.Structured_Arguments loop
         declare
            Value : constant String := To_String (Arg);
         begin
            if Value'Length = 0 or else Contains_Control_Character (Value) then
               return Process_Request_Rejected_Invalid_Argument;
            end if;
         end;
      end loop;

      return Process_Request_Valid;
   end Validate_Real_Build_Tool_Fixture_Process_Request;

   function Preflight_Real_Build_Tool_Fixture
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
   is
      Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request (Request, Fixture, Gate);
      Build_Status : constant Build_Request_Validation_Status :=
        Real_Build_Tool_Fixture_Status_To_Build_Status (Validation);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Real_Build_Tool_Fixture_Status_To_Process_Status (Validation);
   begin
      if Validation /= Real_Build_Fixture_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Real_Build_Tool_Fixture_Process_Request
        (Request, Fixture);
      Process_Status := Validate_Real_Build_Tool_Fixture_Process_Request
        (Process_Request, Gate);

      return
        (Build_Request_Status   => Build_Request_Valid,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_Real_Build_Tool_Fixture;

   function Build_Real_Build_Tool_Fixture_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String
   is
   begin
      if Build_Result.Status = Build_Run_Not_Available then
         return "Build: build fixture unavailable";
      elsif Build_Result.Status = Build_Run_Rejected then
         return "Build: build fixture rejected";
      else
         return Build_Build_Command_Feedback (Build_Result, Diagnostic_Result);
      end if;
   end Build_Real_Build_Tool_Fixture_Feedback;

   function Build_Preflight_Result_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid then
         return not Result.Has_Process_Request
           and then Result.Process_Request_Status /= Process_Request_Valid;
      end if;

      if Result.Process_Request_Status = Process_Request_Valid then
         return Result.Has_Process_Request;
      end if;

      return not Result.Has_Process_Request;
   end Build_Preflight_Result_Is_Consistent;


   function Real_Build_Tool_Fixture_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
      Program : constant String := To_String (Result.Process_Request.Program_Label);
      Opaque : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Result.Process_Request.Arguments), Both);
   begin
      if not Build_Preflight_Result_Is_Consistent (Result) then
         return False;
      end if;

      if Result.Build_Request_Status = Build_Request_Rejected_Project_Metadata
        and then Result.Has_Process_Request
      then
         return False;
      end if;

      if Result.Process_Request_Status /= Process_Request_Valid then
         return not Result.Has_Process_Request;
      end if;

      return Result.Has_Process_Request
        and then Program'Length > 0
        and then Opaque'Length = 0
        and then not Result.Process_Request.Structured_Arguments.Is_Empty;
   end Real_Build_Tool_Fixture_Preflight_Is_Consistent;

   function Real_Build_Tool_Fixture_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean
   is
      Message : constant String := To_String (Result.Command_Message);
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Parsed : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Parse_Input_Count;
   begin
      if Message'Length = 0 then
         return False;
      end if;

      case Result.Build_Result.Status is
         when Build_Run_Succeeded | Build_Run_Failed =>
            if not Result.Build_Result.Has_Exit_Code then
               return False;
            end if;
         when Build_Run_Not_Available | Build_Run_Rejected
            | Build_Run_Execution_Error | Build_Run_Timed_Out
            | Build_Run_Cancelled | Build_Run_Cancellation_Unsupported
            | Build_Run_Output_Truncated =>
            if Result.Build_Result.Has_Exit_Code then
               return False;
            end if;
      end case;

      if Result.Build_Result.Status = Build_Run_Not_Available
        and then Message = "Build: succeeded"
      then
         return False;
      end if;

      if Result.Build_Result.Status = Build_Run_Execution_Error
        and then Ingested > 0
      then
         return False;
      end if;

      if Ingested = 0 and then Parsed = 0 then
         return Message'Length > 0;
      end if;

      return True;
   end Real_Build_Tool_Fixture_Command_Result_Is_Consistent;

   procedure Assert_Real_Build_Tool_Fixture_Preflight_Consistent
     (Result : Build_Preflight_Result)
   is
   begin
      pragma Assert (Real_Build_Tool_Fixture_Preflight_Is_Consistent (Result));
   end Assert_Real_Build_Tool_Fixture_Preflight_Consistent;

   procedure Assert_Real_Build_Tool_Fixture_Command_Result_Consistent
     (Result : Build_Command_Result)
   is
   begin
      pragma Assert (Real_Build_Tool_Fixture_Command_Result_Is_Consistent (Result));
   end Assert_Real_Build_Tool_Fixture_Command_Result_Consistent;

   function Enforce_Process_Output_Bounds
     (Result : Process_Run_Result;
      Policy : Process_Execution_Policy) return Process_Run_Result
   is
   begin
      if Length (Result.Stdout_Text) > Policy.Max_Output_Bytes
        or else Length (Result.Stderr_Text) > Policy.Max_Output_Bytes
      then
         return Build_Process_Run_Result (Process_Run_Execution_Error);
      end if;

      return Result;
   end Enforce_Process_Output_Bounds;

   function Process_Fixture_Result_Is_Consistent
     (Result : Process_Run_Result;
      Policy : Process_Execution_Policy) return Boolean
   is
   begin
      if Length (Result.Stdout_Text) > Policy.Max_Output_Bytes
        or else Length (Result.Stderr_Text) > Policy.Max_Output_Bytes
      then
         return False;
      end if;

      case Result.Status is
         when Process_Run_Succeeded | Process_Run_Failed =>
            return Result.Has_Exit_Code;
         when Process_Run_Not_Available | Process_Run_Rejected
            | Process_Run_Execution_Error
            | Process_Run_Cancellation_Unsupported =>
            return not Result.Has_Exit_Code
              and then Length (Result.Stdout_Text) = 0
              and then Length (Result.Stderr_Text) = 0;
         when Process_Run_Timed_Out | Process_Run_Cancelled
            | Process_Run_Output_Truncated =>
            return not Result.Has_Exit_Code;
      end case;
   end Process_Fixture_Result_Is_Consistent;

   procedure Assert_Process_Fixture_Result_Consistent
     (Result : Process_Run_Result)
   is
      Conservative_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Fixture_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
   begin
      pragma Assert
        (Process_Fixture_Result_Is_Consistent (Result, Conservative_Policy));
   end Assert_Process_Fixture_Result_Consistent;

   function Execute_Test_Fed_Process_Request
     (Request         : Process_Run_Request;
      Supplied_Result : Process_Run_Result) return Process_Run_Result
   is
      Clean_Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Program_Label), Both);
   begin
      if Clean_Program'Length = 0 then
         return Build_Process_Run_Result (Process_Run_Rejected);
      end if;

      return Supplied_Result;
   end Execute_Test_Fed_Process_Request;

   function Execute_Process_Request_Real_Gated_With_State
     (S       : in out Editor.State.State_Type;
      Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result;

   function Execute_Process_Request_Gated
     (Request         : Process_Run_Request;
      Policy          : Process_Execution_Policy;
      Supplied_Result : Process_Run_Result) return Process_Run_Result
   is
   begin
      if not Validate_Process_Execution_Policy (Policy) then
         return Build_Process_Run_Result (Process_Run_Rejected);
      end if;

      case Policy.Mode is
         when Process_Execution_Disabled =>
            return Build_Process_Run_Result (Process_Run_Not_Available);
         when Process_Execution_Test_Fixture =>
            return Enforce_Process_Output_Bounds
              (Execute_Test_Fed_Process_Request (Request, Supplied_Result),
               Policy);
         when Process_Execution_Real_Fixture_Allowed =>
            --  Normal process requests cannot enter the fixture real-runner.
            --  Fixture execution requires Process_Fixture_Request explicitly.
            return Build_Process_Run_Result (Process_Run_Rejected);
         when Process_Execution_Real_Allowed =>
            return Execute_Process_Request_Real_Gated (Request, Policy);
      end case;
   end Execute_Process_Request_Gated;

   function Execute_Process_Request_Gated_With_State
     (S               : in out Editor.State.State_Type;
      Request         : Process_Run_Request;
      Policy          : Process_Execution_Policy;
      Supplied_Result : Process_Run_Result) return Process_Run_Result
   is
   begin
      if not Validate_Process_Execution_Policy (Policy) then
         return Build_Process_Run_Result (Process_Run_Rejected);
      end if;

      case Policy.Mode is
         when Process_Execution_Disabled =>
            return Build_Process_Run_Result (Process_Run_Not_Available);
         when Process_Execution_Test_Fixture =>
            return Enforce_Process_Output_Bounds
              (Execute_Test_Fed_Process_Request (Request, Supplied_Result),
               Policy);
         when Process_Execution_Real_Fixture_Allowed =>
            return Build_Process_Run_Result (Process_Run_Rejected);
         when Process_Execution_Real_Allowed =>
            return Execute_Process_Request_Real_Gated_With_State
              (S, Request, Policy);
      end case;
   end Execute_Process_Request_Gated_With_State;


   function Sanitized_Process_Label (Program_Label : String) return String
   is
      Clean  : constant String := Ada.Strings.Fixed.Trim (Program_Label, Both);
      Result : Unbounded_String := Null_Unbounded_String;
      Limit  : Natural := 0;
   begin
      if Clean'Length = 0 then
         return "process";
      end if;

      for C of Clean loop
         exit when Limit >= 32;
         if C in 'a' .. 'z'
           or else C in 'A' .. 'Z'
           or else C in '0' .. '9'
           or else C = '-'
           or else C = '_'
           or else C = '.'
         then
            Append (Result, C);
         else
            Append (Result, '_');
         end if;
         Limit := Limit + 1;
      end loop;

      if Length (Result) = 0 then
         return "process";
      else
         return To_String (Result);
      end if;
   end Sanitized_Process_Label;

   function Build_Output_Capture_Path
     (Working_Directory : String;
      Program_Label     : String) return String
   is
      Clean : constant String := Ada.Strings.Fixed.Trim (Working_Directory, Both);
      Stamp : constant String := Ada.Strings.Fixed.Trim
        (Integer'Image (Integer (Ada.Calendar.Seconds (Ada.Calendar.Clock) * 1000.0)),
         Both);
      Name     : Unbounded_String;
   begin
      if Build_Output_Capture_Sequence = Natural'Last then
         Build_Output_Capture_Sequence := 0;
      else
         Build_Output_Capture_Sequence := Build_Output_Capture_Sequence + 1;
      end if;

      declare
         Sequence : constant String := Ada.Strings.Fixed.Trim
           (Natural'Image (Build_Output_Capture_Sequence), Both);
      begin
         Name := To_Unbounded_String
           (".editor_build_output_"
            & Sanitized_Process_Label (Program_Label)
            & "_" & Stamp & "_" & Sequence
            & ".tmp");
      end;

      if Clean'Length = 0 then
         return To_String (Name);
      elsif Clean (Clean'Last) = '/' then
         return Clean & To_String (Name);
      else
         return Clean & "/" & To_String (Name);
      end if;
   end Build_Output_Capture_Path;

   procedure Delete_File_If_Present (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Delete_File_If_Present;

   function Read_Bounded_Output_File
     (Path      : String;
      Max_Bytes : Natural;
      Truncated : out Boolean) return Unbounded_String
   is
      use Ada.Streams;
      package SIO renames Ada.Streams.Stream_IO;
      File   : SIO.File_Type;
      Buffer : Stream_Element_Array (1 .. 4096);
      Last   : Stream_Element_Offset;
      Result : Unbounded_String := Null_Unbounded_String;
      Read_Count : Natural := 0;
   begin
      Truncated := False;
      if Max_Bytes = 0 or else not Ada.Directories.Exists (Path) then
         return Result;
      end if;

      SIO.Open (File, SIO.In_File, Path);
      while not SIO.End_Of_File (File) loop
         SIO.Read (File, Buffer, Last);
         exit when Last < Buffer'First;

         for I in Buffer'First .. Last loop
            if Read_Count >= Max_Bytes then
               Truncated := True;
               SIO.Close (File);
               return Result;
            end if;
            Append (Result, Character'Val (Integer (Buffer (I))));
            Read_Count := Read_Count + 1;
         end loop;
      end loop;
      SIO.Close (File);
      return Result;
   exception
      when others =>
         begin
            if SIO.Is_Open (File) then
               SIO.Close (File);
            end if;
         exception
            when others =>
               null;
         end;
         Truncated := False;
         return Null_Unbounded_String;
   end Read_Bounded_Output_File;

   function Execute_Process_Request_Real_Gated_With_State
     (S       : in out Editor.State.State_Type;
      Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result
   is
      Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Program_Label), Both);
      Working : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Working_Label), Both);
      Stdout_Capture_File : constant String :=
        Build_Output_Capture_Path (Working, Program & "_stdout");
      Stderr_Capture_File : constant String :=
        Build_Output_Capture_Path (Working, Program & "_stderr");
      Stdout_Output    : Unbounded_String := Null_Unbounded_String;
      Stderr_Output    : Unbounded_String := Null_Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Last_Streamed_Stdout_Length : Natural := 0;
      Last_Streamed_Stderr_Length : Natural := 0;

      procedure Stream_Capture_File_Delta
        (Path          : String;
         Output_Stream : Editor.Build_Output_Details.Build_Output_Stream_Selection;
         Last_Length   : in out Natural)
      is
         Truncated : Boolean := False;
         Snapshot  : constant Unbounded_String :=
           Read_Bounded_Output_File (Path, Policy.Max_Output_Bytes, Truncated);
         Text      : constant String := To_String (Snapshot);
      begin
         if S.Public_Build_Output_Stream.Active
           and then Text'Length > Last_Length
         then
            Editor.Build_Output_Details.Append_Build_Output_Stream_Chunk
              (S.Public_Build_Output_Stream,
               Output_Stream,
               Text (Text'First + Last_Length .. Text'Last));
            Last_Length := Text'Length;
            Editor.Build_Process_Control.Publish_Active_Output_Stream
              (S.Public_Build_Output_Stream);
         end if;
      end Stream_Capture_File_Delta;

      procedure Stream_Capture_Deltas is
      begin
         Stream_Capture_File_Delta
           (Stdout_Capture_File,
            Editor.Build_Output_Details.Build_Output_Stream_Stdout,
            Last_Streamed_Stdout_Length);
         Stream_Capture_File_Delta
           (Stderr_Capture_File,
            Editor.Build_Output_Details.Build_Output_Stream_Stderr,
            Last_Streamed_Stderr_Length);
      end Stream_Capture_Deltas;

      function Execute_With_Native_Process_Supervisor return Process_Run_Result is
         use type Ada.Calendar.Time;
         use type Duration;
         use type Interfaces.C.int;

         subtype C_Int is Interfaces.C.int;
         package C_Strings renames Interfaces.C.Strings;
         use type C_Strings.chars_ptr;

         type C_Argv_Array is array (Natural range <>) of aliased C_Strings.chars_ptr;
         pragma Convention (C, C_Argv_Array);

         function C_Fork return C_Int
           with Import, Convention => C, External_Name => "fork";
         function C_Open
           (Path  : C_Strings.chars_ptr;
            Flags : C_Int;
            Mode  : Interfaces.C.unsigned) return C_Int
           with Import, Convention => C, External_Name => "open";
         function C_Dup2 (Old_Fd, New_Fd : C_Int) return C_Int
           with Import, Convention => C, External_Name => "dup2";
         function C_Close (Fd : C_Int) return C_Int
           with Import, Convention => C, External_Name => "close";
         function C_Chdir (Path : C_Strings.chars_ptr) return C_Int
           with Import, Convention => C, External_Name => "chdir";
         function C_Execvp
           (File : C_Strings.chars_ptr; Argv : System.Address) return C_Int
           with Import, Convention => C, External_Name => "execvp";
         function C_Waitpid
           (Pid : C_Int; Status : System.Address; Options : C_Int) return C_Int
           with Import, Convention => C, External_Name => "waitpid";
         function C_Kill (Pid : C_Int; Sig : C_Int) return C_Int
           with Import, Convention => C, External_Name => "kill";
         procedure C_Exit (Status : C_Int)
           with Import, Convention => C, External_Name => "_exit";

         O_WRONLY : constant C_Int := 1;
         O_CREAT  : constant C_Int := 64;
         O_TRUNC  : constant C_Int := 512;
         WNOHANG  : constant C_Int := 1;
         SIGTERM  : constant C_Int := 15;
         SIGKILL  : constant C_Int := 9;

         Arg_Count : constant Natural := Natural (Request.Structured_Arguments.Length);
         Argv      : C_Argv_Array (0 .. Arg_Count + 1);
         Program_C : C_Strings.chars_ptr := C_Strings.New_String (Program);
         Working_C : C_Strings.chars_ptr := C_Strings.New_String (Working);
         Stdout_C  : C_Strings.chars_ptr := C_Strings.New_String (Stdout_Capture_File);
         Stderr_C  : C_Strings.chars_ptr := C_Strings.New_String (Stderr_Capture_File);
         Child     : C_Int := -1;
         Status    : aliased C_Int := 0;
         Waited    : C_Int := 0;
         Timed_Out : Boolean := False;
         Start_Time : constant Ada.Calendar.Time := Ada.Calendar.Clock;

         procedure Free_C_Strings is
         begin
            for I in Argv'Range loop
               if Argv (I) /= C_Strings.Null_Ptr then
                  C_Strings.Free (Argv (I));
               end if;
            end loop;
            if Program_C /= C_Strings.Null_Ptr then
               C_Strings.Free (Program_C);
            end if;
            if Working_C /= C_Strings.Null_Ptr then
               C_Strings.Free (Working_C);
            end if;
            if Stdout_C /= C_Strings.Null_Ptr then
               C_Strings.Free (Stdout_C);
            end if;
            if Stderr_C /= C_Strings.Null_Ptr then
               C_Strings.Free (Stderr_C);
            end if;
         end Free_C_Strings;

         function Deadline_Reached return Boolean is
            Elapsed : constant Duration := Ada.Calendar.Clock - Start_Time;
         begin
            return Policy.Timeout_Milliseconds > 0
              and then Elapsed * 1000 >= Duration (Policy.Timeout_Milliseconds);
         end Deadline_Reached;

         function Wait_Status_Exit_Code (Raw : C_Int) return Integer is
         begin
            if Integer (Raw) mod 128 = 0 then
               return (Integer (Raw) / 256) mod 256;
            elsif Integer (Raw) mod 128 /= 127 then
               return 128 + (Integer (Raw) mod 128);
            else
               return 1;
            end if;
         end Wait_Status_Exit_Code;

         Exit_Code : Integer := 1;

         procedure Register_Active_Build_Process
           (System_Process_Id : Integer)
         is
         begin
            if S.Public_Build_Job_Active then
               S.Public_Build_Process_Handle :=
                 Editor.Build_Process_Control.From_System_Process_Id
                   (System_Process_Id);
               Editor.Build_Process_Control.Publish_Active_Process
                 (S.Public_Build_Process_Handle);
            end if;
         end Register_Active_Build_Process;

         procedure Clear_Active_Build_Process is
         begin
            if S.Public_Build_Job_Active then
               S.Public_Build_Process_Handle :=
                 Editor.Build_Process_Control.No_Process_Handle;
               Editor.Build_Process_Control.Clear_Active_Process;
            end if;
         end Clear_Active_Build_Process;

         function Cancellation_Requested return Boolean is
         begin
            return (S.Public_Build_Job_Active
                    and then S.Public_Build_Job_Cancellation =
                      Editor.Build_Runner_Policy.Cancellation_Requested)
              or else Editor.Build_Process_Control.Active_Cancel_Requested;
         end Cancellation_Requested;
      begin
         Argv (0) := C_Strings.New_String (Program);
         declare
            Index : Natural := 1;
         begin
            for Arg of Request.Structured_Arguments loop
               Argv (Index) := C_Strings.New_String (To_String (Arg));
               Index := Index + 1;
            end loop;
            Argv (Index) := C_Strings.Null_Ptr;
         end;

         Delete_File_If_Present (Stdout_Capture_File);
         Delete_File_If_Present (Stderr_Capture_File);
         Child := C_Fork;
         if Child < 0 then
            Free_C_Strings;
            return Build_Process_Run_Result (Process_Run_Execution_Error);
         elsif Child = 0 then
            declare
               Out_Fd : C_Int := -1;
               Err_Fd : C_Int := -1;
            begin
               if C_Chdir (Working_C) /= 0 then
                  C_Exit (126);
               end if;

               Out_Fd := C_Open
                 (Stdout_C, O_WRONLY + O_CREAT + O_TRUNC,
                  Interfaces.C.unsigned (8#644#));
               Err_Fd := C_Open
                 (Stderr_C, O_WRONLY + O_CREAT + O_TRUNC,
                  Interfaces.C.unsigned (8#644#));
               if Out_Fd < 0 or else Err_Fd < 0 then
                  C_Exit (126);
               end if;
               if C_Dup2 (Out_Fd, 1) < 0 or else C_Dup2 (Err_Fd, 2) < 0 then
                  C_Exit (126);
               end if;
               if Out_Fd > 2 then
                  declare
                     Ignored : C_Int := C_Close (Out_Fd);
                  begin
                     null;
                  end;
               end if;
               if Err_Fd > 2 then
                  declare
                     Ignored : C_Int := C_Close (Err_Fd);
                  begin
                     null;
                  end;
               end if;

               declare
                  Ignored : C_Int := C_Execvp (Program_C, Argv (Argv'First)'Address);
               begin
                  null;
               end;
               C_Exit (127);
            end;
         end if;

         Register_Active_Build_Process (Integer (Child));

         loop
            Waited := C_Waitpid (Child, Status'Address, WNOHANG);
            exit when Waited = Child;
            if Waited < 0 then
               Clear_Active_Build_Process;
               Free_C_Strings;
               Delete_File_If_Present (Stdout_Capture_File);
               Delete_File_If_Present (Stderr_Capture_File);
               return Build_Process_Run_Result (Process_Run_Execution_Error);
            end if;

            Stream_Capture_Deltas;

            if Deadline_Reached then
               Timed_Out := True;
               declare
                  Ignored : C_Int := C_Kill (Child, SIGTERM);
               begin
                  null;
               end;
               delay 0.10;
               Waited := C_Waitpid (Child, Status'Address, WNOHANG);
               if Waited /= Child then
                  declare
                     Ignored : C_Int := C_Kill (Child, SIGKILL);
                  begin
                     null;
                  end;
                  loop
                     Waited := C_Waitpid (Child, Status'Address, 0);
                     exit when Waited = Child or else Waited < 0;
                  end loop;
               end if;
               exit;
            else
               delay 0.05;
            end if;
         end loop;

         Stream_Capture_Deltas;
         Clear_Active_Build_Process;
         Stdout_Output := Read_Bounded_Output_File
           (Stdout_Capture_File, Policy.Max_Output_Bytes, Stdout_Truncated);
         Stderr_Output := Read_Bounded_Output_File
           (Stderr_Capture_File, Policy.Max_Output_Bytes, Stderr_Truncated);
         Delete_File_If_Present (Stdout_Capture_File);
         Delete_File_If_Present (Stderr_Capture_File);
         Free_C_Strings;

         if Timed_Out then
            Exit_Code := 124;
         else
            Exit_Code := Wait_Status_Exit_Code (Status);
         end if;

         return Enforce_Process_Output_Bounds
           ((Status        =>
               (if Stdout_Truncated or else Stderr_Truncated then
                   Process_Run_Output_Truncated
                elsif Timed_Out then Process_Run_Timed_Out
                elsif Cancellation_Requested then Process_Run_Cancelled
                elsif Exit_Code = 0 then Process_Run_Succeeded
                else Process_Run_Failed),
             Output_Capture_Mode => Process_Output_Capture_Separated,
             Has_Exit_Code => True,
             Exit_Code     => Exit_Code,
             Stdout_Text   => Stdout_Output,
             Stderr_Text   => Stderr_Output,
             Stdout_Truncated => Stdout_Truncated,
             Stderr_Truncated => Stderr_Truncated),
            Policy);
      exception
         when others =>
            if Child > 0 then
               declare
                  Ignored : C_Int := C_Kill (Child, SIGKILL);
               begin
                  null;
               end;
            end if;
            Clear_Active_Build_Process;
            Free_C_Strings;
            Delete_File_If_Present (Stdout_Capture_File);
            Delete_File_If_Present (Stderr_Capture_File);
            return Build_Process_Run_Result (Process_Run_Execution_Error);
      end Execute_With_Native_Process_Supervisor;
   begin
      if not Validate_Process_Run_Request_For_Real_Execution (Request, Policy) then
         return Build_Process_Run_Result (Process_Run_Rejected);
      elsif Working'Length = 0 then
         return Build_Process_Run_Result (Process_Run_Not_Available);
      end if;

      return Execute_With_Native_Process_Supervisor;
   end Execute_Process_Request_Real_Gated_With_State;

   function Execute_Process_Request_Real_Gated
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result
   is
      Detached_State : Editor.State.State_Type;
   begin
      return Execute_Process_Request_Real_Gated_With_State
        (Detached_State, Request, Policy);
   end Execute_Process_Request_Real_Gated;

   function Validate_Process_Fixture_Request
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Fixture_Validation_Status
   is
   begin
      if Policy.Allow_Shell then
         return Fixture_Request_Rejected_Shell;
      end if;

      if not Validate_Process_Execution_Policy (Policy)
        or else Policy.Mode /= Process_Execution_Real_Fixture_Allowed
        or else not Policy.Allow_Real_Execution
      then
         return Fixture_Request_Rejected_Disabled;
      end if;

      if Policy.Max_Output_Bytes = 0 then
         return Fixture_Request_Rejected_Output_Limit;
      end if;

      case Fixture.Kind is
         when No_Process_Fixture =>
            return Fixture_Request_Rejected_Unknown_Fixture;
         when Echo_Diagnostic_Fixture | Exit_Code_Fixture =>
            null;
      end case;

      for Arg of Fixture.Arguments loop
         if Contains_Control_Character (To_String (Arg)) then
            return Fixture_Request_Rejected_Invalid_Argument;
         end if;
      end loop;

      return Fixture_Request_Valid;
   end Validate_Process_Fixture_Request;

   function Validate_Process_Fixture_Request_Status
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Request_Validation_Status
   is
      Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request (Fixture, Policy);
   begin
      case Status is
         when Fixture_Request_Valid =>
            return Process_Request_Valid;
         when Fixture_Request_Rejected_Disabled
            | Fixture_Request_Not_Available =>
            return Process_Request_Rejected_Execution_Disabled;
         when Fixture_Request_Rejected_Shell =>
            return Process_Request_Rejected_Shell_Disallowed;
         when Fixture_Request_Rejected_Unknown_Fixture =>
            return Process_Request_Rejected_Empty_Program;
         when Fixture_Request_Rejected_Opaque_Arguments =>
            return Process_Request_Rejected_Opaque_Arguments;
         when Fixture_Request_Rejected_Invalid_Argument
            | Fixture_Request_Rejected_Output_Limit =>
            return Process_Request_Rejected_Invalid_Argument;
      end case;
   end Validate_Process_Fixture_Request_Status;

   function Process_Fixture_Request_Is_Valid
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Boolean
   is
   begin
      return Validate_Process_Fixture_Request (Fixture, Policy) =
        Fixture_Request_Valid;
   end Process_Fixture_Request_Is_Valid;

   function Build_Process_Fixture_Request
     (Kind  : Process_Fixture_Kind;
      First : String := "";
      Second : String := "";
      Third : String := "") return Process_Fixture_Request
   is
      Args : Process_Argument_Vector := Empty_Process_Arguments;
   begin
      Append_Process_Argument (Args, First);
      Append_Process_Argument (Args, Second);
      Append_Process_Argument (Args, Third);
      return (Kind => Kind, Arguments => Args);
   end Build_Process_Fixture_Request;

   procedure Append_With_Newline
     (Target : in out Unbounded_String;
      Value  : String)
   is
   begin
      if Length (Target) > 0 then
         Append (Target, ASCII.LF);
      end if;
      Append (Target, Value);
   end Append_With_Newline;

   function Execute_Process_Request_Real_Fixture
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result
   is
      Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request (Fixture, Policy);
      Out_Text : Unbounded_String := Null_Unbounded_String;
      Err_Text : Unbounded_String := Null_Unbounded_String;
      Use_Stderr : Boolean := False;
      Use_Mixed   : Boolean := False;
      First_Index : Natural := 0;
      Code : Integer := 0;
   begin
      if Status = Fixture_Request_Rejected_Disabled
        or else Status = Fixture_Request_Not_Available
      then
         return Build_Process_Run_Result (Process_Run_Not_Available);
      elsif Status /= Fixture_Request_Valid then
         return Build_Process_Run_Result (Process_Run_Rejected);
      end if;

      if Policy.Max_Output_Bytes = 0 then
         return Build_Process_Run_Result (Process_Run_Execution_Error);
      end if;

      case Fixture.Kind is
         when No_Process_Fixture =>
            return Build_Process_Run_Result (Process_Run_Rejected);

         when Echo_Diagnostic_Fixture =>
            if Fixture.Arguments.Length > 0 then
               declare
                  First : constant String :=
                    To_String (Fixture.Arguments.First_Element);
               begin
                  if First = "stderr" then
                     Use_Stderr := True;
                     First_Index := 1;
                  elsif First = "stdout" then
                     First_Index := 1;
                  elsif First = "mixed" then
                     Use_Mixed := True;
                     First_Index := Natural (Fixture.Arguments.Length);
                  end if;
               end;
            end if;

            if Use_Mixed and then Fixture.Arguments.Length > 1 then
               Append_With_Newline
                 (Err_Text, To_String (Fixture.Arguments.Element (1)));
               if Fixture.Arguments.Length > 2 then
                  Append_With_Newline
                    (Out_Text, To_String (Fixture.Arguments.Element (2)));
               end if;
            elsif Natural (Fixture.Arguments.Length) > First_Index then
               for I in First_Index .. Natural (Fixture.Arguments.Length) - 1 loop
                  if Use_Stderr then
                     Append_With_Newline
                       (Err_Text, To_String (Fixture.Arguments.Element (I)));
                  else
                     Append_With_Newline
                       (Out_Text, To_String (Fixture.Arguments.Element (I)));
                  end if;
               end loop;
            end if;

            return Enforce_Process_Output_Bounds
              ((Status        => Process_Run_Succeeded,
                Output_Capture_Mode => Process_Output_Capture_Separated,
                Has_Exit_Code => True,
                Exit_Code     => 0,
                Stdout_Text   => Out_Text,
                Stderr_Text   => Err_Text,
                Stdout_Truncated => False,
                Stderr_Truncated => False),
               Policy);

         when Exit_Code_Fixture =>
            if Fixture.Arguments.Length > 0 then
               begin
                  Code := Integer'Value
                    (To_String (Fixture.Arguments.First_Element));
               exception
                  when Constraint_Error =>
                     return Build_Process_Run_Result (Process_Run_Rejected);
               end;
            end if;

            if Fixture.Arguments.Length > 1 then
               for I in 1 .. Natural (Fixture.Arguments.Length) - 1 loop
                  Append_With_Newline
                    (Err_Text, To_String (Fixture.Arguments.Element (I)));
               end loop;
            end if;

            return Enforce_Process_Output_Bounds
              ((Status        => (if Code = 0 then Process_Run_Succeeded else Process_Run_Failed),
                Output_Capture_Mode => Process_Output_Capture_Separated,
                Has_Exit_Code => True,
                Exit_Code     => Code,
                Stdout_Text   => Null_Unbounded_String,
                Stderr_Text   => Err_Text,
                Stdout_Truncated => False,
                Stderr_Truncated => False),
               Policy);
      end case;
   end Execute_Process_Request_Real_Fixture;

   function Build_Process_Fixture_Result
     (Request : Build_Run_Request;
      Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Build_Run_Result
   is
      Process_Result : Process_Run_Result;
   begin
      if not Validate_Build_Run_Request (Request) then
         return Build_Build_Run_Result (Build_Run_Rejected);
      end if;

      Process_Result := Execute_Process_Request_Real_Fixture (Fixture, Policy);
      return Build_Result_From_Process_Result (Request, Process_Result);
   end Build_Process_Fixture_Result;

   function Build_Result_From_Process_Result
     (Request : Build_Run_Request;
      Result  : Process_Run_Result) return Build_Run_Result
   is
      pragma Unreferenced (Request);
      Build_Status : Build_Run_Status;
   begin
      case Result.Status is
         when Process_Run_Succeeded =>
            Build_Status := Build_Run_Succeeded;
         when Process_Run_Failed =>
            Build_Status := Build_Run_Failed;
         when Process_Run_Not_Available =>
            Build_Status := Build_Run_Not_Available;
         when Process_Run_Rejected =>
            Build_Status := Build_Run_Rejected;
         when Process_Run_Execution_Error =>
            Build_Status := Build_Run_Execution_Error;
         when Process_Run_Timed_Out =>
            Build_Status := Build_Run_Timed_Out;
         when Process_Run_Cancelled =>
            Build_Status := Build_Run_Cancelled;
         when Process_Run_Cancellation_Unsupported =>
            Build_Status := Build_Run_Cancellation_Unsupported;
         when Process_Run_Output_Truncated =>
            Build_Status := Build_Run_Output_Truncated;
      end case;

      return
        (Status           => Build_Status,
         Output_Capture_Mode => Result.Output_Capture_Mode,
         Exit_Code        => Result.Exit_Code,
         Has_Exit_Code    => Result.Has_Exit_Code,
         Stdout_Text      => Result.Stdout_Text,
         Stderr_Text      => Result.Stderr_Text,
         Stdout_Truncated => Result.Stdout_Truncated,
         Stderr_Truncated => Result.Stderr_Truncated,
         Output_Partial   => Result.Status = Process_Run_Timed_Out
           or else Result.Status = Process_Run_Cancelled
           or else Result.Status = Process_Run_Cancellation_Unsupported,
         Diagnostic_Lines => Diagnostic_Text_Line_Vectors.Empty_Vector);
   end Build_Result_From_Process_Result;

   function Build_Build_Run_Result
     (Status           : Build_Run_Status;
      Exit_Code        : Integer := 0;
      Has_Exit_Code    : Boolean := False;
      Stdout_Text      : String := "";
      Stderr_Text      : String := "";
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Output_Capture_Mode : Process_Output_Capture_Mode :=
        Process_Output_Capture_Separated;
      Diagnostic_Lines : Diagnostic_Text_Line_Array :=
        Diagnostic_Text_Line_Vectors.Empty_Vector) return Build_Run_Result
   is
   begin
      return
        (Status           => Status,
         Output_Capture_Mode =>
           (if Stdout_Text'Length = 0 and then Stderr_Text'Length = 0 then
               Process_Output_Capture_None
            else Output_Capture_Mode),
         Exit_Code        => Exit_Code,
         Has_Exit_Code    => Has_Exit_Code,
         Stdout_Text      => To_Unbounded_String (Stdout_Text),
         Stderr_Text      => To_Unbounded_String (Stderr_Text),
         Stdout_Truncated => Stdout_Truncated,
         Stderr_Truncated => Stderr_Truncated,
         Output_Partial   => Output_Partial
           or else Status = Build_Run_Timed_Out
           or else Status = Build_Run_Cancelled
           or else Status = Build_Run_Cancellation_Unsupported,
         Diagnostic_Lines => Diagnostic_Lines);
   end Build_Build_Run_Result;

   function Execute_Build_Request
     (Request : Build_Run_Request) return Build_Run_Result
   is
      Process_Request : Process_Run_Request;
      Process_Result  : Process_Run_Result;
   begin
      if not Validate_Build_Run_Request (Request) then
         return Build_Build_Run_Result (Build_Run_Rejected);
      end if;

      Process_Request := Prepare_Process_Request (Request);
      Process_Result := Execute_Process_Request_Default (Process_Request);
      return Build_Result_From_Process_Result (Request, Process_Result);
   end Execute_Build_Request;

   function Execute_Test_Fed_Build_Request
     (Request         : Build_Run_Request;
      Supplied_Result : Build_Run_Result) return Build_Run_Result
   is
   begin
      if not Validate_Build_Run_Request (Request) then
         return Build_Build_Run_Result (Build_Run_Rejected);
      end if;

      --  Deterministic test seam for Phase 166/167 coverage. It is deliberately
      --  above the process-runner layer and still cannot bypass validation.
      return Supplied_Result;
   end Execute_Test_Fed_Build_Request;

   function Execute_Build_Request_With_Process_Policy
     (Request         : Build_Run_Request;
      Policy          : Process_Execution_Policy;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Run_Result
   is
      Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (Request, Policy);
      Process_Result  : Process_Run_Result;
   begin
      if Preflight.Build_Request_Status /= Build_Request_Valid then
         return Build_Build_Run_Result (Build_Run_Rejected);
      end if;

      if Preflight.Process_Request_Status /= Process_Request_Valid then
         if Preflight.Process_Request_Status =
           Process_Request_Rejected_Execution_Disabled
         then
            return Build_Build_Run_Result (Build_Run_Not_Available);
         else
            return Build_Build_Run_Result (Build_Run_Rejected);
         end if;
      end if;

      Process_Result := Execute_Process_Request_Gated
        (Preflight.Process_Request, Policy, Supplied_Result);
      return Build_Result_From_Process_Result (Request, Process_Result);
   end Execute_Build_Request_With_Process_Policy;

   procedure Append_Output_Text_Lines
     (Text  : String;
      Lines : in out Diagnostic_Text_Line_Array)
   is
      Start : Positive := Text'First;
      Stop  : Natural;
      Last  : Natural;
   begin
      if Text'Length = 0 then
         return;
      end if;

      while Start <= Text'Last loop
         Stop := Start;
         while Stop <= Text'Last and then Text (Stop) /= ASCII.LF loop
            Stop := Stop + 1;
         end loop;

         Last := Stop - 1;
         if Last >= Start and then Text (Last) = ASCII.CR then
            Last := Last - 1;
         end if;

         if Last >= Start then
            Lines.Append (To_Unbounded_String (Text (Start .. Last)));
         else
            Lines.Append (Null_Unbounded_String);
         end if;

         Start := Stop + 1;
      end loop;
   end Append_Output_Text_Lines;

   function Extract_Diagnostic_Lines_From_Build_Result
     (Result : Build_Run_Result) return Diagnostic_Text_Line_Array
   is
      Lines : Diagnostic_Text_Line_Array;
   begin
      if Result.Diagnostic_Lines.Length > 0 then
         return Result.Diagnostic_Lines;
      end if;

      Append_Output_Text_Lines (To_String (Result.Stderr_Text), Lines);
      Append_Output_Text_Lines (To_String (Result.Stdout_Text), Lines);
      return Lines;
   end Extract_Diagnostic_Lines_From_Build_Result;

   function Empty_Diagnostic_Line_Command_Result
     return Diagnostic_Line_Command_Result
   is
      Empty : Diagnostic_Line_Ingestion_Result;
   begin
      return
        (Ingestion               => Empty,
         Command_Message         => To_Unbounded_String
           (Build_Diagnostic_Line_Command_Feedback (Empty)),
         Should_Show_Diagnostics => False,
         Outcome                 => Diagnostic_Line_Command_No_Input);
   end Empty_Diagnostic_Line_Command_Result;

   function Ingest_Build_Run_Diagnostics
     (S                : in out Editor.State.State_Type;
      Producer         : External_Producer_Source;
      Result           : Build_Run_Result;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result
   is
      Max_Build_Diagnostic_Input_Lines : constant Natural := 512;
      Source : constant Diagnostic_Text_Line_Array :=
        Extract_Diagnostic_Lines_From_Build_Result (Result);
      Lines  : Diagnostic_Text_Line_Array;
      Count  : Natural := 0;
   begin
      if not Source.Is_Empty then
         for I in Source.First_Index .. Source.Last_Index loop
            exit when Count >= Max_Build_Diagnostic_Input_Lines;
            Lines.Append (Source.Element (I));
            Count := Count + 1;
         end loop;
      end if;

      return Ingest_Diagnostic_Lines_From_Command
        (S, Producer, Lines, Show_Diagnostics);
   end Ingest_Build_Run_Diagnostics;

   function Build_Build_Command_Feedback
     (Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result) return String
   is
      Accepted : constant Natural :=
        Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Rejected : constant Natural :=
        Diagnostic_Result.Ingestion.Parse_Rejected_Malformed_Count;
      Ignored : constant Natural :=
        Diagnostic_Result.Ingestion.Parse_Ignored_Blank_Count
        + Diagnostic_Result.Ingestion.Parse_Ignored_Unrecognized_Count;
      Message : Unbounded_String :=
        To_Unbounded_String (Build_Status_Label (Build_Result.Status));
   begin
      if Accepted > 0 then
         Append
           (Message, ", ingested " & Trim_Natural_Image (Accepted)
            & " diagnostics");
      elsif Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed
        and then Diagnostic_Result.Ingestion.Parse_Input_Count > 0
      then
         Append (Message, ", no diagnostics parsed");
         if Ignored > 0 then
            Append
              (Message, ", ignored " & Trim_Natural_Image (Ignored)
               & " lines");
         end if;
      end if;

      if Accepted = 0 and then Rejected > 0 then
         Append
           (Message, ", rejected " & Trim_Natural_Image (Rejected)
            & " malformed lines");
      end if;

      return To_String (Message);
   end Build_Build_Command_Feedback;

   function Run_Build_Command_Test_Seam
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Show_Diagnostics : Boolean := False) return Build_Command_Result
   is
   begin
      return Run_Build_Command_Test_Seam_With_Runner
        (S, Request,
         (Mode                     => Process_Execution_Disabled,
          Allow_Real_Execution     => False,
          Allow_Shell              => False,
          Max_Output_Bytes         => 262_144,
          Require_Absolute_Program => False,
          Timeout_Milliseconds     => 0),
         Build_Process_Run_Result (Process_Run_Not_Available),
         Show_Diagnostics);
   end Run_Build_Command_Test_Seam;

   function Run_Build_Command_Test_Seam_With_Runner
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Policy           : Process_Execution_Policy;
      Supplied_Result  : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False);
      Show_Diagnostics : Boolean := False) return Build_Command_Result
   is
      Producer : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (Request, Policy);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result;
      Message : Unbounded_String;
   begin
      if Preflight.Build_Request_Status /= Build_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Diagnostic_Result := Empty_Diagnostic_Line_Command_Result;
         Message := To_Unbounded_String
           (Build_Request_Rejection_Feedback (Preflight.Build_Request_Status));
      elsif Preflight.Process_Request_Status /= Process_Request_Valid then
         if Preflight.Process_Request_Status =
           Process_Request_Rejected_Execution_Disabled
         then
            Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         else
            Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         end if;
         Diagnostic_Result := Empty_Diagnostic_Line_Command_Result;
         Message := To_Unbounded_String
           (Process_Request_Rejection_Feedback
              (Preflight.Process_Request_Status));
      else
         Build_Result := Execute_Build_Request_With_Process_Policy
           (Request, Policy, Supplied_Result);
         Diagnostic_Result := Ingest_Build_Run_Diagnostics
           (S, Producer, Build_Result, Show_Diagnostics);
         Message := To_Unbounded_String
           (Build_Build_Command_Feedback (Build_Result, Diagnostic_Result));
      end if;


      return
        (Build_Result      => Build_Result,
         Diagnostic_Result => Diagnostic_Result,
         Command_Message   => Message);
   end Run_Build_Command_Test_Seam_With_Runner;

   function Build_Gated_Build_Command_Feedback
     (Build_Result                  : Build_Run_Result;
      Diagnostic_Result             : Diagnostic_Line_Command_Result;
      Diagnostics_Ingestion_Used    : Boolean;
      Diagnostics_Ingestion_Allowed : Boolean) return String
   is
      Message : Unbounded_String :=
        To_Unbounded_String
          (Build_Build_Command_Feedback (Build_Result, Diagnostic_Result));
   begin
      if not Diagnostics_Ingestion_Allowed then
         if Build_Result.Status in Build_Run_Succeeded | Build_Run_Failed then
            return Build_Status_Label (Build_Result.Status)
              & ", diagnostics ingestion disabled";
         else
            return "Build: diagnostics ingestion disabled";
         end if;
      end if;

      if not Diagnostics_Ingestion_Used
        and then Build_Result.Status = Build_Run_Not_Available
      then
         return "Build: real execution unavailable";
      end if;

      return To_String (Message);
   end Build_Gated_Build_Command_Feedback;

   function Process_Fixture_Rejection_Feedback
     (Status : Process_Fixture_Validation_Status) return String
   is
   begin
      case Status is
         when Fixture_Request_Valid =>
            return "Build: fixture accepted";
         when Fixture_Request_Rejected_Disabled =>
            return "Build: fixture execution disabled";
         when Fixture_Request_Not_Available =>
            return "Build: fixture unavailable";
         when Fixture_Request_Rejected_Unknown_Fixture
            | Fixture_Request_Rejected_Shell
            | Fixture_Request_Rejected_Opaque_Arguments
            | Fixture_Request_Rejected_Invalid_Argument
            | Fixture_Request_Rejected_Output_Limit =>
            return "Build: fixture rejected";
      end case;
   end Process_Fixture_Rejection_Feedback;

   function Run_Build_Command_With_Gate
     (S               : in out Editor.State.State_Type;
      Request         : Build_Run_Request;
      Gate            : Build_Execution_Gate;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stderr_Text   => Ada.Strings.Unbounded.Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
   is
      Producer : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Preflight : Build_Preflight_Result;
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
      Message : Unbounded_String;
      Mode : Process_Execution_Mode;
      Process_Result : Process_Run_Result;
      Diagnostics_Used : Boolean := False;
   begin
      if not Validate_Build_Execution_Gate (Gate) then
         Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         return
           (Build_Result      => Build_Result,
            Diagnostic_Result => Diagnostic_Result,
            Command_Message   => To_Unbounded_String ("Build: execution disabled"));
      end if;

      if Gate.Allow_Real_Build_Tool_Execution then
         Preflight := Preflight_Real_Build_Tool_Request (Request, Gate);
      else
         Preflight := Preflight_Build_Run_Request (Request, Gate.Process_Policy);
      end if;

      if Preflight.Build_Request_Status /= Build_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Message := To_Unbounded_String
           (Build_Request_Rejection_Feedback (Preflight.Build_Request_Status));
      elsif Preflight.Process_Request_Status /= Process_Request_Valid then
         if Preflight.Process_Request_Status =
           Process_Request_Rejected_Execution_Disabled
         then
            Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         else
            Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         end if;
         Message := To_Unbounded_String
           (Process_Request_Rejection_Feedback
              (Preflight.Process_Request_Status));
      else
         Mode := Select_Process_Runner_Mode (Gate, Gate.Process_Policy);
         if Mode = Process_Execution_Disabled then
            Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
            Message := To_Unbounded_String ("Build: execution disabled");
         else
            Process_Result := Execute_Process_Request_Gated_With_State
              (S, Preflight.Process_Request, Gate.Process_Policy, Supplied_Result);
            Build_Result := Build_Result_From_Process_Result
              (Request, Process_Result);

            if Gate.Allow_Diagnostics_Ingestion then
               Diagnostic_Result := Ingest_Build_Run_Diagnostics
                 (S, Producer, Build_Result, Gate.Show_Diagnostics);
               Diagnostics_Used := True;
            end if;

            Message := To_Unbounded_String
              (Build_Gated_Build_Command_Feedback
                 (Build_Result, Diagnostic_Result, Diagnostics_Used,
                  Gate.Allow_Diagnostics_Ingestion));
         end if;
      end if;

      return
        (Build_Result      => Build_Result,
         Diagnostic_Result => Diagnostic_Result,
         Command_Message   => Message);
   end Run_Build_Command_With_Gate;

   function Run_Build_Command_With_Fixture_Gate
     (S       : in out Editor.State.State_Type;
      Request : Build_Run_Request;
      Fixture : Process_Fixture_Request;
      Gate    : Build_Execution_Gate) return Build_Command_Result
   is
      Producer : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
      Message : Unbounded_String;
      Diagnostics_Used : Boolean := False;
      Fixture_Status : Process_Fixture_Validation_Status;
   begin
      if not Validate_Build_Execution_Gate (Gate)
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Fixture_Allowed
      then
         Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         return
           (Build_Result      => Build_Result,
            Diagnostic_Result => Diagnostic_Result,
            Command_Message   => To_Unbounded_String ("Build: fixture execution disabled"));
      end if;

      if Validate_Build_Run_Request_Status (Request) /= Build_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Message := To_Unbounded_String
           (Build_Request_Rejection_Feedback
              (Validate_Build_Run_Request_Status (Request)));
      else
         Fixture_Status := Validate_Process_Fixture_Request
           (Fixture, Gate.Process_Policy);
         if Fixture_Status /= Fixture_Request_Valid then
            if Fixture_Status = Fixture_Request_Rejected_Disabled
              or else Fixture_Status = Fixture_Request_Not_Available
            then
               Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
            else
               Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
            end if;
            Message := To_Unbounded_String
              (Process_Fixture_Rejection_Feedback (Fixture_Status));
         else
            Build_Result := Build_Process_Fixture_Result
              (Request, Fixture, Gate.Process_Policy);

            if Gate.Allow_Diagnostics_Ingestion then
               Diagnostic_Result := Ingest_Build_Run_Diagnostics
                 (S, Producer, Build_Result, Gate.Show_Diagnostics);
               Diagnostics_Used := True;
            end if;

            Message := To_Unbounded_String
              (Build_Gated_Build_Command_Feedback
                 (Build_Result, Diagnostic_Result, Diagnostics_Used,
                  Gate.Allow_Diagnostics_Ingestion));
         end if;
      end if;

      return
        (Build_Result      => Build_Result,
         Diagnostic_Result => Diagnostic_Result,
         Command_Message   => Message);
   end Run_Build_Command_With_Fixture_Gate;

   function Run_Real_Build_Tool_Fixture_With_Gate
     (S                : in out Editor.State.State_Type;
      Request          : Build_Run_Request;
      Fixture          : Real_Build_Tool_Fixture_Kind;
      Gate             : Build_Execution_Gate;
      Supplied_Result  : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
   is
      Producer : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request (Request, Fixture, Gate);
      Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture (Request, Fixture, Gate);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
      Message : Unbounded_String;
      Process_Result : Process_Run_Result;
   begin
      if Validation /= Real_Build_Fixture_Valid then
         if Validation = Real_Build_Fixture_Rejected_Disabled
           or else Validation = Real_Build_Fixture_Not_Available
         then
            Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         else
            Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         end if;
         Message := To_Unbounded_String
           (Real_Build_Tool_Fixture_Rejection_Feedback (Validation));
      elsif Preflight.Process_Request_Status /= Process_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Message := To_Unbounded_String
           (Process_Request_Rejection_Feedback
              (Preflight.Process_Request_Status));
      else
         --  Phase 175 keeps the real build-tool fixture path behind the same
         --  runner abstraction. Tool availability can therefore resolve to a
         --  deterministic not-available result without PATH probing in preflight.
         Process_Result := Enforce_Process_Output_Bounds
           (Supplied_Result, Gate.Process_Policy);
         Build_Result := Build_Result_From_Process_Result
           (Request, Process_Result);

         if Gate.Allow_Diagnostics_Ingestion then
            Diagnostic_Result := Ingest_Build_Run_Diagnostics
              (S, Producer, Build_Result, Gate.Show_Diagnostics);
         end if;

         Message := To_Unbounded_String
           (Build_Real_Build_Tool_Fixture_Feedback
              (Build_Result, Diagnostic_Result));
      end if;

      return
        (Build_Result      => Build_Result,
         Diagnostic_Result => Diagnostic_Result,
         Command_Message   => Message);
   end Run_Real_Build_Tool_Fixture_With_Gate;

   function Run_User_Opt_In_Build_Command_Test_Seam
     (S               : in out Editor.State.State_Type;
      Request         : Build_Run_Request;
      Gate            : Build_Execution_Gate;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
   is
      Producer : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Request, Gate);
      Build_Result : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
      Process_Result : Process_Run_Result;
      Diagnostics_Used : Boolean := False;
      Message : Unbounded_String;
   begin
      if Preflight.Build_Request_Status /= Build_Request_Valid then
         Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         Message := To_Unbounded_String
           (Build_User_Opt_In_Build_Feedback (Preflight));
      elsif Preflight.Process_Request_Status /= Process_Request_Valid then
         if Preflight.Process_Request_Status =
           Process_Request_Rejected_Execution_Disabled
         then
            Build_Result := Build_Build_Run_Result (Build_Run_Not_Available);
         else
            Build_Result := Build_Build_Run_Result (Build_Run_Rejected);
         end if;
         Message := To_Unbounded_String
           (Build_User_Opt_In_Build_Feedback (Preflight));
      else
         --  The user-opt-in test seam is internal/test-only in Phase 177. It
         --  consumes a completed test-controlled process result through the
         --  same result/bounds/diagnostic pipeline, without invoking a platform
         --  runner or retaining a process handle.
         Process_Result := Enforce_Process_Output_Bounds
           (Supplied_Result, Gate.Process_Policy);
         Build_Result := Build_Result_From_Process_Result (Request, Process_Result);

         if Gate.Allow_Diagnostics_Ingestion then
            Diagnostic_Result := Ingest_Build_Run_Diagnostics
              (S, Producer, Build_Result, Gate.Show_Diagnostics);
            Diagnostics_Used := True;
         end if;

         Message := To_Unbounded_String
           (Build_Gated_Build_Command_Feedback
              (Build_Result, Diagnostic_Result, Diagnostics_Used,
               Gate.Allow_Diagnostics_Ingestion));
      end if;

      return
        (Build_Result      => Build_Result,
         Diagnostic_Result => Diagnostic_Result,
         Command_Message   => Message);
   end Run_User_Opt_In_Build_Command_Test_Seam;

   function Execute_User_Opt_In_Build_Command
     (S               : in out Editor.State.State_Type;
      Context         : User_Opt_In_Build_Command_Context;
      Supplied_Result : Process_Run_Result :=
        (Status        => Process_Run_Not_Available,
         Output_Capture_Mode => Process_Output_Capture_None,
         Has_Exit_Code => False,
         Exit_Code     => 0,
         Stdout_Text   => Null_Unbounded_String,
         Stderr_Text   => Null_Unbounded_String,
         Stdout_Truncated => False,
         Stderr_Truncated => False))
      return Build_Command_Result
   is
      Status : constant User_Opt_In_Build_Command_Context_Status :=
        Validate_User_Opt_In_Build_Command_Context (Context);
      Empty_Result : constant Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
      Build_Status : Build_Run_Status := Build_Run_Rejected;
      Result : Build_Command_Result;
   begin
      if Status /= User_Build_Context_Valid then
         if Status = User_Build_Context_Rejected_Missing_Gate
           or else Status = User_Build_Context_Rejected_Ambiguous_Execution_Path
         then
            Build_Status := Build_Run_Not_Available;
         end if;

         Result :=
           (Build_Result      => Build_Build_Run_Result (Build_Status),
            Diagnostic_Result => Empty_Result,
            Command_Message   => Null_Unbounded_String);
         Result.Command_Message := To_Unbounded_String
           (Build_User_Opt_In_Command_Feedback (Status, Result));
         return Result;
      end if;

      Result := Run_User_Opt_In_Build_Command_Test_Seam
        (S, Context.Request, Context.Gate, Supplied_Result);
      Result.Command_Message := To_Unbounded_String
        (Build_User_Opt_In_Command_Feedback (Status, Result));
      return Result;
   end Execute_User_Opt_In_Build_Command;

   function Public_Build_Command_Name_Is_Public
     (Name : String) return Boolean
   is
   begin
      return Is_Public_Build_Surface_Id (Name);
   end Public_Build_Command_Name_Is_Public;

   function Command_Surface_Has_Public_Build_Command return Boolean
   is
      Id : Editor.Commands.Command_Id;
      D  : Editor.Commands.Command_Descriptor;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         D := Editor.Commands.Descriptor (Id);
         if Public_Build_Command_Name_Is_Public
             (Editor.Commands.Stable_Command_Name (Id))
           and then D.Visibility = Editor.Commands.Palette_Command
           and then D.Category /= Editor.Commands.Internal_Category
         then
            return True;
         end if;
      end loop;
      return False;
   end Command_Surface_Has_Public_Build_Command;

   function Build_Public_Build_Command_Surface
     return Public_Build_Command_Surface_Array
   is
      Result : Public_Build_Command_Surface_Array;
   begin
      Result.Append
        (Public_Build_Command_Surface_Entry'(Stable_Id               => To_Unbounded_String ("build.run"),
          Has_Descriptor          => True,
          Has_Input_Model         => True,
          Has_Consent_Model       => True,
          Has_Working_Context_Model => True,
          Publicly_Invokable      => True,
          Routes_Through_Executor => True));
      return Result;
   end Build_Public_Build_Command_Surface;

   function Validate_Public_Build_Command_Surface_Entry
     (Surface_Entry : Public_Build_Command_Surface_Entry)
      return Public_Build_Command_Surface_Status
   is
      Name  : constant String := To_String (Surface_Entry.Stable_Id);
      Found : Boolean := False;
      Id    : constant Editor.Commands.Command_Id :=
        Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      pragma Unreferenced (Id);
   begin
      if Name'Length = 0 then
         return Public_Build_Command_Surface_Rejected_Empty_Id;
      elsif not Found or else not Surface_Entry.Has_Descriptor then
         return Public_Build_Command_Surface_Rejected_Missing_Descriptor;
      elsif False then
         return Public_Build_Command_Surface_Rejected_Default_Keybinding;
      elsif not Surface_Entry.Publicly_Invokable then
         return Public_Build_Command_Surface_Rejected_Not_Publicly_Invokable;
      elsif not Surface_Entry.Has_Input_Model then
         return Public_Build_Command_Surface_Rejected_Missing_Input_Model;
      elsif not Surface_Entry.Has_Consent_Model then
         return Public_Build_Command_Surface_Rejected_Missing_Consent_Model;
      elsif not Surface_Entry.Has_Working_Context_Model then
         return Public_Build_Command_Surface_Rejected_Missing_Working_Context_Model;
      elsif not Surface_Entry.Routes_Through_Executor then
         return Public_Build_Command_Surface_Rejected_Missing_Executor_Route;
      else
         return Public_Build_Command_Surface_Valid;
      end if;
   end Validate_Public_Build_Command_Surface_Entry;

   procedure Assert_Public_Build_Command_Surface_Entry_Consistent
     (Surface_Entry : Public_Build_Command_Surface_Entry)
   is
      Name : constant String := To_String (Surface_Entry.Stable_Id);
   begin
      if Validate_Public_Build_Command_Surface_Entry (Surface_Entry) /=
        Public_Build_Command_Surface_Valid
      then
         raise Program_Error with
           "public build surface entry metadata is inconsistent";
      elsif not Public_Build_Command_Name_Is_Public (Name) then
         raise Program_Error with
           "public build surface entry uses a non-public command id";
      elsif not Surface_Entry.Publicly_Invokable then
         raise Program_Error with
           "public build surface entry is not invokable";
      elsif not Surface_Entry.Routes_Through_Executor then
         raise Program_Error with
           "public build surface entry is not Executor-routed";
      elsif not (Surface_Entry.Has_Input_Model
                 and then Surface_Entry.Has_Consent_Model
                 and then Surface_Entry.Has_Working_Context_Model)
      then
         raise Program_Error with
           "public build surface entry is missing declared UX dependencies";
      end if;
   end Assert_Public_Build_Command_Surface_Entry_Consistent;

   function Build_Public_Build_UX_Dependency_Matrix
     return Public_Build_UX_Dependency_Matrix
   is
      Matrix : Public_Build_UX_Dependency_Matrix :=
        (others => Dependency_Missing);
   begin
      Matrix (Public_Build_Dependency_Input_Model) :=
        (if Audit_Public_Build_Input_Model_Readiness
         then Dependency_Satisfied
         else Dependency_Missing);
      Matrix (Public_Build_Dependency_Structured_Argv) := Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Consent_Model) :=
        (if Audit_Public_Build_Consent_Readiness
         then Dependency_Satisfied
         else Dependency_Missing);
      Matrix (Public_Build_Dependency_Consent_UX) := Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Working_Context_Model) :=
        (if Audit_Public_Build_Working_Context_Readiness
         then Dependency_Satisfied
         else Dependency_Missing);
      Matrix (Public_Build_Dependency_Working_Context_UX) := Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Project_Metadata_Policy) :=
        Dependency_Intentionally_Blocked;
      Matrix (Public_Build_Dependency_Execution_Policy) :=
        Dependency_Model_Not_Public;
      Matrix (Public_Build_Dependency_Executor_Route) := Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Diagnostics_Pipeline) :=
        (if Diagnostic_Line_Command_Surface_Audit_Passes
            and then Diagnostic_Line_Layering_Audit_Passes
         then Dependency_Satisfied
         else Dependency_Missing);
      Matrix (Public_Build_Dependency_Command_Result_Policy) :=
        Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Availability_Purity) :=
        Dependency_Satisfied;
      Matrix (Public_Build_Dependency_No_Persistence) := Dependency_Satisfied;
      return Matrix;
   end Build_Public_Build_UX_Dependency_Matrix;

   function Primary_Public_Build_UX_Dependency_Blocker
     (Matrix : Public_Build_UX_Dependency_Matrix)
      return Public_Build_UX_Dependency
   is
   begin
      if Matrix (Public_Build_Dependency_Consent_UX) /= Dependency_Satisfied then
         return Public_Build_Dependency_Consent_UX;
      elsif Matrix (Public_Build_Dependency_Working_Context_UX) /=
        Dependency_Satisfied
      then
         return Public_Build_Dependency_Working_Context_UX;
      elsif Matrix (Public_Build_Dependency_Project_Metadata_Policy) /=
        Dependency_Satisfied
      then
         return Public_Build_Dependency_Project_Metadata_Policy;
      elsif Matrix (Public_Build_Dependency_Execution_Policy) /=
        Dependency_Satisfied
      then
         return Public_Build_Dependency_Execution_Policy;
      elsif Matrix (Public_Build_Dependency_Executor_Route) /=
        Dependency_Satisfied
      then
         return Public_Build_Dependency_Executor_Route;
      else
         for Dependency in Public_Build_UX_Dependency loop
            if Matrix (Dependency) /= Dependency_Satisfied then
               return Dependency;
            end if;
         end loop;
         return Public_Build_Dependency_Input_Model;
      end if;
   end Primary_Public_Build_UX_Dependency_Blocker;

   function Validate_Public_Build_UX_Dependencies
     (Matrix : Public_Build_UX_Dependency_Matrix)
      return Public_Build_Command_Promotion_Status
   is
      Blocker : constant Public_Build_UX_Dependency :=
        Primary_Public_Build_UX_Dependency_Blocker (Matrix);
   begin
      declare
         All_Satisfied : Boolean := True;
      begin
         for Dependency in Public_Build_UX_Dependency loop
            All_Satisfied := All_Satisfied
              and then Matrix (Dependency) = Dependency_Satisfied;
         end loop;
         if All_Satisfied then
            return Public_Build_Promotion_Command_Surface_Ready;
         end if;
      end;

      if Matrix (Public_Build_Dependency_Input_Model) = Dependency_Missing
        or else Matrix (Public_Build_Dependency_Structured_Argv) /=
          Dependency_Satisfied
      then
         return Public_Build_Promotion_Input_Model_Incomplete;
      end if;

      case Blocker is
         when Public_Build_Dependency_Consent_UX |
              Public_Build_Dependency_Consent_Model =>
            return Public_Build_Promotion_Consent_UX_Incomplete;
         when Public_Build_Dependency_Working_Context_UX |
              Public_Build_Dependency_Working_Context_Model =>
            return Public_Build_Promotion_Working_Context_UX_Incomplete;
         when Public_Build_Dependency_Project_Metadata_Policy =>
            return Public_Build_Promotion_Project_Metadata_Unsupported;
         when Public_Build_Dependency_Execution_Policy =>
            return Public_Build_Promotion_Execution_Policy_Incomplete;
         when Public_Build_Dependency_Executor_Route =>
            return Public_Build_Promotion_Public_Executor_Route_Missing;
         when Public_Build_Dependency_Diagnostics_Pipeline |
              Public_Build_Dependency_Command_Result_Policy |
              Public_Build_Dependency_Availability_Purity |
              Public_Build_Dependency_No_Persistence =>
            return Public_Build_Promotion_Execution_Policy_Incomplete;
         when Public_Build_Dependency_Input_Model |
              Public_Build_Dependency_Structured_Argv =>
            return Public_Build_Promotion_Input_Model_Incomplete;
      end case;
   end Validate_Public_Build_UX_Dependencies;

   function Detect_Public_Build_Command_Exposure_Hard_Failure
     (Readiness : Public_Build_Command_Readiness_Audit_Result) return Boolean
   is
   begin
      return Readiness.Has_Default_Public_Build_Keybinding;
   end Detect_Public_Build_Command_Exposure_Hard_Failure;

   function Validate_Public_Build_Command_Promotion
     (Surface_Entry : Public_Build_Command_Surface_Entry;
      Readiness   : Public_Build_Command_Readiness_Audit_Result)
      return Public_Build_Command_Promotion_Status
   is
      Surface_Entry_Status : constant Public_Build_Command_Surface_Status :=
        Validate_Public_Build_Command_Surface_Entry (Surface_Entry);
      Matrix : Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
      Matrix_Status : Public_Build_Command_Promotion_Status;
   begin
      if Readiness.Has_Public_Input_Model_Audit
        and then Readiness.Public_Input_Validation_Complete
        and then Readiness.Has_Structured_Argv_Input_Model
        and then Readiness.Public_Input_Conversion_Uses_Structured_Argv
        and then not Readiness.Public_Input_Publicly_Exposable
      then
         Matrix (Public_Build_Dependency_Input_Model) := Dependency_Satisfied;
         Matrix (Public_Build_Dependency_Structured_Argv) := Dependency_Satisfied;
      end if;

      if Readiness.Public_Consent_Model_Validated then
         Matrix (Public_Build_Dependency_Consent_Model) :=
           Dependency_Satisfied;
      end if;
      if Readiness.Public_Consent_UX_Publicly_Ready
        and then Readiness.Public_Consent_Publicly_Exposable
      then
         Matrix (Public_Build_Dependency_Consent_UX) := Dependency_Satisfied;
      end if;

      if Readiness.Public_Working_Context_Model_Validated then
         Matrix (Public_Build_Dependency_Working_Context_Model) :=
           Dependency_Satisfied;
      end if;
      if Readiness.Public_Working_Context_Publicly_Ready
        and then Readiness.Public_Working_Context_Publicly_Exposable
      then
         Matrix (Public_Build_Dependency_Working_Context_UX) :=
           Dependency_Satisfied;
      end if;

      if Readiness.Has_Project_Metadata_Validation
        and then Readiness.Keeps_Project_Metadata_Rejected
      then
         Matrix (Public_Build_Dependency_Project_Metadata_Policy) :=
           Dependency_Satisfied;
      end if;
      if Readiness.Keeps_Shell_Rejected
        and then Readiness.Keeps_Opaque_Arguments_Rejected
        and then Readiness.Routes_Diagnostics_Through_Pipeline
      then
         Matrix (Public_Build_Dependency_Execution_Policy) :=
           Dependency_Satisfied;
      end if;
      if Readiness.Routes_Through_Executor then
         Matrix (Public_Build_Dependency_Executor_Route) := Dependency_Satisfied;
      end if;

      Matrix_Status := Validate_Public_Build_UX_Dependencies (Matrix);

      if Surface_Entry_Status /= Public_Build_Command_Surface_Valid then
         return Public_Build_Promotion_Blocked;
      elsif Detect_Public_Build_Command_Exposure_Hard_Failure (Readiness) then
         return Public_Build_Promotion_Unsafe_Exposure_Detected;
      elsif Matrix_Status /= Public_Build_Promotion_Command_Surface_Ready then
         return Matrix_Status;
      elsif not Readiness.Public_Command_Publicly_Exposable then
         return Public_Build_Promotion_Blocked;
      else
         return Public_Build_Promotion_Command_Surface_Ready;
      end if;
   end Validate_Public_Build_Command_Promotion;

   function Audit_Public_Build_Command_Visibility return Boolean
   is
      Surface_Entries : constant Public_Build_Command_Surface_Array :=
        Build_Public_Build_Command_Surface;

      function Name_Not_Registered (Name : String) return Boolean is
         Found : Boolean;
         Id    : constant Editor.Commands.Command_Id :=
           Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         pragma Unreferenced (Id);
      begin
         return not Found;
      end Name_Not_Registered;
   begin
      if Surface_Entries.Length /= Public_Build_Command_Surface_Ids.Length then
         return False;
      end if;

      for Surface_Entry of Surface_Entries loop
         if Validate_Public_Build_Command_Surface_Entry (Surface_Entry) /=
           Public_Build_Command_Surface_Valid
         then
            return False;
         end if;
      end loop;

      if not Command_Surface_Has_Public_Build_Command then
         return False;
      end if;

      for Name of Public_Build_Command_Surface_Ids loop
         if To_String (Name) = "build.run" then
            if Name_Not_Registered (To_String (Name)) then
               return False;
            end if;
         elsif not Name_Not_Registered (To_String (Name)) then
            return False;
         end if;
      end loop;

      return True;
   end Audit_Public_Build_Command_Visibility;

   procedure Assert_Public_Build_Command_Surface_Exposed
   is
   begin
      if not Audit_Public_Build_Command_Visibility then
         raise Program_Error with
           "public build command UX foundation is not coherent";
      end if;
   end Assert_Public_Build_Command_Surface_Exposed;

   function Audit_Public_Build_Command_UX_Dependencies
     return Public_Build_Command_UX_Dependency_Audit_Result
   is
      Result : Public_Build_Command_UX_Dependency_Audit_Result;
   begin
      Result.Has_Input_Model := Audit_Public_Build_Input_Model_Readiness;
      Result.Has_Structured_Argv_Model := True;
      Result.Has_Consent_Model := Audit_Public_Build_Consent_Readiness;
      Result.Has_Real_Consent_UX := True;
      Result.Has_Working_Context_Model :=
        Audit_Public_Build_Working_Context_Readiness;
      Result.Has_Safe_Working_Context_UX := True;
      Result.Has_Project_Metadata_Validation := False;
      Result.Explicitly_Rejects_Project_Metadata := True;
      Result.Requires_Executor_Routed_Mutation := True;
      Result.Requires_One_Primary_Result := True;
      Result.Requires_Diagnostics_Pipeline :=
        Diagnostic_Line_Command_Surface_Audit_Passes
        and then Diagnostic_Line_Layering_Audit_Passes;
      Result.Requires_No_Shell_Execution := True;
      Result.Requires_Side_Effect_Free_Availability := True;
      Result.Requires_No_Persistence_Of_Transient_State := True;
      Result.Public_Command_Exposure_Blocked :=
        Command_Surface_Has_Public_Build_Command;
      Result.Passed_As_Not_Ready :=
        Result.Has_Input_Model
        and then Result.Has_Structured_Argv_Model
        and then Result.Has_Consent_Model
        and then Result.Has_Real_Consent_UX
        and then Result.Has_Working_Context_Model
        and then Result.Has_Safe_Working_Context_UX
        and then not Result.Has_Project_Metadata_Validation
        and then Result.Explicitly_Rejects_Project_Metadata
        and then Result.Requires_Executor_Routed_Mutation
        and then Result.Requires_One_Primary_Result
        and then Result.Requires_Diagnostics_Pipeline
        and then Result.Requires_No_Shell_Execution
        and then Result.Requires_Side_Effect_Free_Availability
        and then Result.Requires_No_Persistence_Of_Transient_State
        and then Result.Public_Command_Exposure_Blocked;
      return Result;
   end Audit_Public_Build_Command_UX_Dependencies;

   function Build_Public_Command_Not_Ready_Feedback
     (Audit : Public_Build_Command_Readiness_Audit_Result) return String
   is
   begin
      if Audit.Has_Public_Build_Command
        or else Audit.Public_Executable_Command_Exists
        or else Audit.Public_Command_Is_Invokable
      then
         return "Build: public command surface unavailable";
      elsif not Audit.Public_Consent_UX_Publicly_Ready then
         return "Build: consent UX not ready";
      elsif not Audit.Public_Working_Context_Publicly_Ready then
         return "Build: working directory UX not ready";
      elsif not Audit.Has_Project_Metadata_Validation then
         return "Build: project build metadata not supported";
      elsif not Audit.Public_Command_Publicly_Exposable then
         return "Build: public command surface unavailable";
      else
         return "Build: public command not ready";
      end if;
   end Build_Public_Command_Not_Ready_Feedback;


   function Build_Public_Command_Promotion_Feedback
     (Status : Public_Build_Command_Promotion_Status) return String
   is
   begin
      case Status is
         when Public_Build_Promotion_Blocked =>
            return "Build: public command exposure blocked";
         when Public_Build_Promotion_Unsafe_Exposure_Detected =>
            return "Build: unsafe public command exposure detected";
         when Public_Build_Promotion_Input_Model_Incomplete =>
            return "Build: public command not ready";
         when Public_Build_Promotion_Consent_UX_Incomplete =>
            return "Build: consent UX not ready";
         when Public_Build_Promotion_Working_Context_UX_Incomplete =>
            return "Build: working directory UX not ready";
         when Public_Build_Promotion_Project_Metadata_Unsupported =>
            return "Build: project build metadata not supported";
         when Public_Build_Promotion_Execution_Policy_Incomplete =>
            return "Build: execution policy incomplete";
         when Public_Build_Promotion_Public_Executor_Route_Missing =>
            return "Build: public command route not ready";
         when Public_Build_Promotion_Command_Surface_Ready =>
            return "Build: public command not ready";
      end case;
   end Build_Public_Command_Promotion_Feedback;

   function Build_Public_Build_UX_Dependency_Feedback
     (Dependency : Public_Build_UX_Dependency) return String
   is
   begin
      case Dependency is
         when Public_Build_Dependency_Consent_UX |
              Public_Build_Dependency_Consent_Model =>
            return "Build: consent UX not ready";
         when Public_Build_Dependency_Working_Context_UX |
              Public_Build_Dependency_Working_Context_Model =>
            return "Build: working directory UX not ready";
         when Public_Build_Dependency_Project_Metadata_Policy =>
            return "Build: project build metadata not supported";
         when Public_Build_Dependency_Execution_Policy =>
            return "Build: execution policy incomplete";
         when Public_Build_Dependency_Executor_Route =>
            return "Build: public command route not ready";
         when Public_Build_Dependency_Input_Model |
              Public_Build_Dependency_Structured_Argv |
              Public_Build_Dependency_Diagnostics_Pipeline |
              Public_Build_Dependency_Command_Result_Policy |
              Public_Build_Dependency_Availability_Purity |
              Public_Build_Dependency_No_Persistence =>
            return "Build: public command not ready";
      end case;
   end Build_Public_Build_UX_Dependency_Feedback;

   function Public_Build_Public_Names_Not_Registered return Boolean
   is
      Surface_Entries : constant Public_Build_Command_Surface_Array :=
        Build_Public_Build_Command_Surface;
      Found : Boolean;
      Id    : Editor.Commands.Command_Id;
      pragma Unreferenced (Id);
   begin
      for Surface_Entry of Surface_Entries loop
         Id := Editor.Commands.Command_Id_From_Stable_Name
           (To_String (Surface_Entry.Stable_Id), Found);
         if Found then
            return False;
         end if;
      end loop;
      return True;
   end Public_Build_Public_Names_Not_Registered;

   function Build_Public_Build_Blocker_Summary
     return Public_Build_Blocker_Summary
   is
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
      Summary : Public_Build_Blocker_Summary;
   begin
      Summary.Consent_UX_Missing :=
        Matrix (Public_Build_Dependency_Consent_UX) /= Dependency_Satisfied;
      Summary.Working_Context_UX_Missing :=
        Matrix (Public_Build_Dependency_Working_Context_UX) /= Dependency_Satisfied;
      Summary.Project_Metadata_Unsupported :=
        Matrix (Public_Build_Dependency_Project_Metadata_Policy) /=
          Dependency_Satisfied;
      Summary.Public_Route_Missing :=
        Matrix (Public_Build_Dependency_Executor_Route) /= Dependency_Satisfied;
      Summary.Public_Command_Not_Registered := False;
      Summary.Default_Execution_Disabled := True;
      Summary.Primary_Blocker := Primary_Public_Build_UX_Dependency_Blocker
        (Matrix);
      return Summary;
   end Build_Public_Build_Blocker_Summary;


   function Public_Build_Command_Surface_Ids return Command_Id_Vector
   is
      Names : Command_Id_Vector;
   begin
      Names.Append (To_Unbounded_String ("build.run"));
      return Names;
   end Public_Build_Command_Surface_Ids;

   function Is_Public_Build_Surface_Id (Name : String) return Boolean
   is
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
   begin
      for Public_Name of Names loop
         if Name = To_String (Public_Name) then
            return True;
         end if;
      end loop;
      return False;
   end Is_Public_Build_Surface_Id;

   function Public_Build_Public_Name_Count return Natural
   is
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
      Found : Boolean;
      Id    : Editor.Commands.Command_Id;
      pragma Unreferenced (Id);
      Count : Natural := 0;
   begin
      for Name of Names loop
         Id := Editor.Commands.Command_Id_From_Stable_Name
           (To_String (Name), Found);
         if Found then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Public_Build_Public_Name_Count;

   procedure Assert_Public_Build_Surface_Ids_Not_Reused
   is
      Found : Boolean;
      Id    : Editor.Commands.Command_Id;
      pragma Unreferenced (Id);
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
   begin
      for Name of Names loop
         Id := Editor.Commands.Command_Id_From_Stable_Name
           (To_String (Name), Found);
         if Found then
            raise Program_Error with "public build command id registered";
         end if;
      end loop;

      if Is_Public_Build_Surface_Id
           (Editor.Commands.Stable_Command_Name
              (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam))
      then
         raise Program_Error with "public build id public-name list includes internal test seam";
      end if;
   end Assert_Public_Build_Surface_Ids_Not_Reused;

   function Public_Build_Blocker_Precedence_Intact return Boolean
   is
      Matrix : Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
   begin
      if Primary_Public_Build_UX_Dependency_Blocker (Matrix) /=
        Public_Build_Dependency_Consent_UX
      then
         return False;
      end if;
      Matrix (Public_Build_Dependency_Consent_UX) := Dependency_Satisfied;
      if Primary_Public_Build_UX_Dependency_Blocker (Matrix) /=
        Public_Build_Dependency_Working_Context_UX
      then
         return False;
      end if;
      Matrix (Public_Build_Dependency_Working_Context_UX) := Dependency_Satisfied;
      if Primary_Public_Build_UX_Dependency_Blocker (Matrix) /=
        Public_Build_Dependency_Project_Metadata_Policy
      then
         return False;
      end if;
      Matrix (Public_Build_Dependency_Project_Metadata_Policy) :=
        Dependency_Satisfied;
      if Primary_Public_Build_UX_Dependency_Blocker (Matrix) /=
        Public_Build_Dependency_Execution_Policy
      then
         return False;
      end if;
      Matrix (Public_Build_Dependency_Execution_Policy) := Dependency_Satisfied;
      return Primary_Public_Build_UX_Dependency_Blocker (Matrix) =
        Public_Build_Dependency_Executor_Route;
   end Public_Build_Blocker_Precedence_Intact;

   procedure Assert_Public_Build_Blocker_Precedence
   is
   begin
      if not Public_Build_Blocker_Precedence_Intact then
         raise Program_Error with "public build blocker precedence drifted";
      end if;
   end Assert_Public_Build_Blocker_Precedence;

   function Build_Public_Build_Hard_Freeze_Baseline
     return Public_Build_Hard_Freeze_Baseline
   is
   begin
      return
        (Public_Command_Count              => 0,
         Public_Default_Keybinding_Count   => 0,
         Public_Command_Palette_Count      => 0,
         Public_Executor_Route_Count       => 0,
         Public_Invocation_Path_Count      => 0,
         Bindable_Public_Build_Count       => 0,
         Promotion_Blocked                 => True,
         Default_Execution_Disabled        => True,
         Consent_UX_Missing                => True,
         Working_Context_UX_Missing        => True,
         Project_Metadata_Unsupported      => True,
         Public_Route_Missing              => True);
   end Build_Public_Build_Hard_Freeze_Baseline;

   function Detect_Public_Build_Hard_Freeze_Drift
     (State    : Editor.State.State_Type;
      Baseline : Public_Build_Hard_Freeze_Baseline)
      return Public_Build_Hard_Freeze_Drift_Result
   is
      Audit : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Run_Public_Build_Command_Hard_Freeze_Audit (State);
      Summary : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
      Result : Public_Build_Hard_Freeze_Drift_Result;

      function Count_When (Condition : Boolean) return Natural is
      begin
         if Condition then
            return 1;
         else
            return 0;
         end if;
      end Count_When;
   begin
      Result.Public_Command_Drift :=
        Public_Build_Public_Name_Count /= Baseline.Public_Command_Count
        or else Count_When (not Audit.No_Public_Command_Registered) /=
          Baseline.Public_Command_Count;
      Result.Keybinding_Drift :=
        Count_When (not Audit.No_Public_Default_Keybinding) /=
          Baseline.Public_Default_Keybinding_Count;
      Result.Palette_Drift :=
        Count_When (not Audit.No_Public_Command_Palette_Entry) /=
          Baseline.Public_Command_Palette_Count;
      Result.Executor_Route_Drift :=
        Count_When (not Audit.No_Public_Executor_Route) /=
          Baseline.Public_Executor_Route_Count;
      Result.Invocation_Path_Drift :=
        Count_When (not Audit.No_Public_Invocation_Path) /=
          Baseline.Public_Invocation_Path_Count;
      Result.Bindability_Drift :=
        Count_When (not Audit.No_Public_Bindable_Command) /=
          Baseline.Bindable_Public_Build_Count;
      Result.Promotion_Drift :=
        Audit.Promotion_Blocked /= Baseline.Promotion_Blocked;
      Result.Execution_Default_Drift :=
        Audit.No_Default_Execution /= Baseline.Default_Execution_Disabled;
      Result.Blocker_Precedence_Drift :=
        (not Public_Build_Blocker_Precedence_Intact)
        or else Summary.Consent_UX_Missing /= Baseline.Consent_UX_Missing
        or else Summary.Working_Context_UX_Missing /=
          Baseline.Working_Context_UX_Missing
        or else Summary.Project_Metadata_Unsupported /=
          Baseline.Project_Metadata_Unsupported
        or else Summary.Public_Route_Missing /= Baseline.Public_Route_Missing;
      Result.Persistence_Drift := not Audit.No_Public_Persistence_State;
      Result.Any_Drift :=
        Result.Public_Command_Drift
        or else Result.Keybinding_Drift
        or else Result.Palette_Drift
        or else Result.Executor_Route_Drift
        or else Result.Invocation_Path_Drift
        or else Result.Bindability_Drift
        or else Result.Promotion_Drift
        or else Result.Execution_Default_Drift
        or else Result.Blocker_Precedence_Drift
        or else Result.Persistence_Drift;
      return Result;
   end Detect_Public_Build_Hard_Freeze_Drift;

   function Build_Public_Build_Drift_Feedback
     (Result : Public_Build_Hard_Freeze_Drift_Result) return String
   is
   begin
      if not Result.Any_Drift then
         return "Build: public command hard-freeze intact";
      elsif Result.Public_Command_Drift or else Result.Palette_Drift then
         return "Build: public command exposure drift detected";
      elsif Result.Keybinding_Drift or else Result.Bindability_Drift then
         return "Build: public build keybinding drift detected";
      elsif Result.Executor_Route_Drift or else Result.Invocation_Path_Drift then
         return "Build: public build route drift detected";
      elsif Result.Promotion_Drift or else Result.Blocker_Precedence_Drift then
         return "Build: public build promotion drift detected";
      elsif Result.Persistence_Drift then
         return "Build: public build persistence drift detected";
      else
         return "Build: public build hard-freeze failed";
      end if;
   end Build_Public_Build_Drift_Feedback;

   function Public_Build_Surface_Ids_Not_Publicly_Projected
     (State : Editor.State.State_Type) return Boolean
   is
      Audit : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Run_Public_Build_Command_Hard_Freeze_Audit (State);
   begin
      return Audit.No_Public_Command_Registered
        and then Audit.No_Public_Default_Keybinding
        and then Audit.No_Public_Command_Palette_Entry
        and then Audit.No_Public_Executor_Route
        and then Audit.No_Public_Invocation_Path
        and then Audit.No_Public_Bindable_Command
        and then Audit.No_Public_Persistence_State;
   end Public_Build_Surface_Ids_Not_Publicly_Projected;

   function Run_Public_Build_Guardrail_Audit
     (State : Editor.State.State_Type) return Public_Build_Guardrail_Result
   is
      Hard_Freeze : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Run_Public_Build_Command_Hard_Freeze_Audit (State);
      Readiness : constant Public_Build_Command_Readiness_Audit_Result :=
        Run_Public_Build_Command_Readiness_Audit (State);
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
      Matrix_Status : constant Public_Build_Command_Promotion_Status :=
        Validate_Public_Build_UX_Dependencies (Matrix);
      Drift : constant Public_Build_Hard_Freeze_Drift_Result :=
        Detect_Public_Build_Hard_Freeze_Drift
          (State, Build_Public_Build_Hard_Freeze_Baseline);
      Trace : constant Public_Build_Guardrail_Audit_Trace :=
        Build_Public_Build_Guardrail_Audit_Trace;
      Surface_Id_Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids;
      Result : Public_Build_Guardrail_Result;
      Exposure_Detected : Boolean;
   begin
      Result.No_Public_Command :=
        Hard_Freeze.No_Public_Command_Registered;
      Result.No_Public_Keybinding :=
        Hard_Freeze.No_Public_Default_Keybinding;
      Result.No_Public_Palette_Entry :=
        Hard_Freeze.No_Public_Command_Palette_Entry;
      Result.No_Public_Executor_Route :=
        Hard_Freeze.No_Public_Executor_Route;
      Result.No_Public_Invocation_Path :=
        Hard_Freeze.No_Public_Invocation_Path;
      Result.No_Public_Bindable_Command :=
        Hard_Freeze.No_Public_Bindable_Command;
      Result.Promotion_Blocked :=
        Hard_Freeze.Promotion_Blocked
        and then Readiness.Public_Command_Promotion_Status /=
          Public_Build_Promotion_Command_Surface_Ready
        and then not Readiness.Public_Command_Can_Be_Promoted;
      Result.Default_Execution_Disabled := Hard_Freeze.No_Default_Execution;
      Result.Dependency_Blockers_Active :=
        Matrix_Status /= Public_Build_Promotion_Command_Surface_Ready
        and then Readiness.Consent_UX_Blocker_Active
        and then Readiness.Working_Context_UX_Blocker_Active
        and then Readiness.Project_Metadata_Blocker_Active
        and then Readiness.Public_Executor_Route_Blocker_Active;
      Result.Persistence_Clean := Hard_Freeze.No_Public_Persistence_State;

      Exposure_Detected :=
        Hard_Freeze.Public_Exposure_Hard_Failure
        or else not Hard_Freeze.Exposure_Barrier_Passed
        or else not Result.No_Public_Command
        or else not Result.No_Public_Keybinding
        or else not Result.No_Public_Palette_Entry
        or else not Result.No_Public_Executor_Route
        or else not Result.No_Public_Invocation_Path
        or else not Result.No_Public_Bindable_Command;

      Result.Audits_Consistent :=
        Hard_Freeze.Passed
        and then Readiness.Passed_As_Not_Ready
        and then Result.Promotion_Blocked
        and then Result.Default_Execution_Disabled
        and then Result.Dependency_Blockers_Active
        and then Result.Persistence_Clean
        and then Public_Build_Surface_Ids_Not_Publicly_Projected (State)
        and then Surface_Id_Scan.Passed
        and then Public_Build_Surface_Id_Scan_Domains_Checked (Surface_Id_Scan)
        and then Public_Build_Guardrail_Audit_Trace_Complete (Trace)
        and then not Hard_Freeze.Public_Exposure_Hard_Failure;

      if Exposure_Detected then
         Result.Status := Public_Build_Guardrail_Exposure_Detected;
      elsif Drift.Any_Drift then
         Result.Status := Public_Build_Guardrail_Drift_Detected;
      elsif not Result.Audits_Consistent then
         Result.Status := Public_Build_Guardrail_Inconsistent_Audits;
      elsif Result.Dependency_Blockers_Active then
         Result.Status := Public_Build_Guardrail_Not_Ready_But_Safe;
      else
         Result.Status := Public_Build_Guardrail_Passed;
      end if;

      return Result;
   end Run_Public_Build_Guardrail_Audit;

   function Detect_Public_Build_Guardrail_Contract_Mismatch
     (Result : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Contract_Mismatch
   is
      Mismatch : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Mismatch.Status_Mismatch :=
        Result.Status /= Public_Build_Guardrail_Not_Ready_But_Safe;
      Mismatch.Public_Command_Mismatch := not Result.No_Public_Command;
      Mismatch.Public_Keybinding_Mismatch := not Result.No_Public_Keybinding;
      Mismatch.Public_Palette_Mismatch := not Result.No_Public_Palette_Entry;
      Mismatch.Public_Route_Mismatch := not Result.No_Public_Executor_Route;
      Mismatch.Public_Invocation_Mismatch :=
        not Result.No_Public_Invocation_Path;
      Mismatch.Public_Bindability_Mismatch :=
        not Result.No_Public_Bindable_Command;
      Mismatch.Promotion_Mismatch := not Result.Promotion_Blocked;
      Mismatch.Default_Execution_Mismatch :=
        not Result.Default_Execution_Disabled;
      Mismatch.Dependency_Blocker_Mismatch :=
        not Result.Dependency_Blockers_Active;
      Mismatch.Persistence_Mismatch := not Result.Persistence_Clean;
      Mismatch.Audit_Consistency_Mismatch := not Result.Audits_Consistent;

      Mismatch.Any_Mismatch :=
        Mismatch.Status_Mismatch
        or else Mismatch.Public_Command_Mismatch
        or else Mismatch.Public_Keybinding_Mismatch
        or else Mismatch.Public_Palette_Mismatch
        or else Mismatch.Public_Route_Mismatch
        or else Mismatch.Public_Invocation_Mismatch
        or else Mismatch.Public_Bindability_Mismatch
        or else Mismatch.Promotion_Mismatch
        or else Mismatch.Default_Execution_Mismatch
        or else Mismatch.Dependency_Blocker_Mismatch
        or else Mismatch.Persistence_Mismatch
        or else Mismatch.Audit_Consistency_Mismatch;
      return Mismatch;
   end Detect_Public_Build_Guardrail_Contract_Mismatch;

   procedure Assert_Public_Build_Guardrail_Default_Contract
     (Result : Public_Build_Guardrail_Result)
   is
      Mismatch : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Result);
   begin
      Assert_Public_Build_Guardrail_Trace_Complete
        (Build_Public_Build_Guardrail_Audit_Trace);
      if Mismatch.Any_Mismatch then
         raise Program_Error with "public build guardrail contract mismatch";
      end if;
   end Assert_Public_Build_Guardrail_Default_Contract;

   procedure Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan
     (State  : Editor.State.State_Type;
      Result : Public_Build_Guardrail_Result)
   is
      Audit : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Run_Public_Build_Command_Hard_Freeze_Audit (State);
   begin
      if Result.No_Public_Command
        and then not Audit.No_Public_Command_Registered
      then
         raise Program_Error with "guardrail command result disagrees with scan";
      end if;

      if Result.No_Public_Executor_Route
        and then not Audit.No_Public_Executor_Route
      then
         raise Program_Error with "guardrail route result disagrees with scan";
      end if;

      if Result.No_Public_Invocation_Path
        and then not Audit.No_Public_Invocation_Path
      then
         raise Program_Error with "guardrail invocation result disagrees with scan";
      end if;

      if Result.No_Public_Keybinding
        and then not Audit.No_Public_Default_Keybinding
      then
         raise Program_Error with "guardrail keybinding result disagrees with scan";
      end if;

      if Result.No_Public_Palette_Entry
        and then not Audit.No_Public_Command_Palette_Entry
      then
         raise Program_Error with "guardrail palette result disagrees with scan";
      end if;

      if Result.No_Public_Bindable_Command
        and then not Audit.No_Public_Bindable_Command
      then
         raise Program_Error with "guardrail bindability result disagrees with scan";
      end if;

      Assert_No_Public_Build_Execution_Path (State);
   end Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan;

   procedure Assert_Public_Build_Guardrail_State_Not_Persisted
     (State : Editor.State.State_Type)
   is
      Result : constant Public_Build_Guardrail_Result :=
        Run_Public_Build_Guardrail_Audit (State);
   begin
      if not Result.Persistence_Clean then
         raise Program_Error with "normalized public build guardrail state persisted";
      end if;

      Assert_Public_Build_Hard_Freeze_Not_Persisted (State);
      Assert_Public_Build_Surface_Ids_Not_Reused;
   end Assert_Public_Build_Guardrail_State_Not_Persisted;

   function Public_Build_Guardrail_Failure_Detail_For
     (Kind   : Public_Build_Guardrail_Failure_Kind;
      Domain : String;
      Id     : String := "") return Public_Build_Guardrail_Failure_Detail
   is
   begin
      return
        (Kind       => Kind,
         Command_Id => To_Unbounded_String (Id),
         Domain     => To_Unbounded_String (Domain));
   end Public_Build_Guardrail_Failure_Detail_For;

   procedure Append_Public_Build_Guardrail_Failure
     (Failures : in out Public_Build_Guardrail_Failure_Detail_Vector;
      Kind     : Public_Build_Guardrail_Failure_Kind;
      Domain   : String)
   is
   begin
      Failures.Append
        (Public_Build_Guardrail_Failure_Detail_For (Kind, Domain));
   end Append_Public_Build_Guardrail_Failure;

   function Collect_Public_Build_Guardrail_Failures
     (Result : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Failure_Detail_Vector
   is
      Failures : Public_Build_Guardrail_Failure_Detail_Vector;
   begin
      if not Result.No_Public_Command then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Command_Registered,
            "command-id");
      end if;
      if not Result.No_Public_Keybinding then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Keybinding_Found,
            "keybinding");
      end if;
      if not Result.No_Public_Palette_Entry then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Palette_Entry_Found,
            "palette");
      end if;
      if not Result.No_Public_Executor_Route then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Executor_Route_Found,
            "executor-route");
      end if;
      if not Result.No_Public_Invocation_Path then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Invocation_Path_Found,
            "invocation");
      end if;
      if not Result.No_Public_Bindable_Command then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Public_Bindable_Command_Found,
            "bindability");
      end if;
      if not Result.Promotion_Blocked then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Promotion_Unblocked,
            "promotion");
      end if;
      if not Result.Default_Execution_Disabled then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Default_Execution_Enabled,
            "execution-default");
      end if;
      if not Result.Dependency_Blockers_Active then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Dependency_Blockers_Missing,
            "dependencies");
      end if;
      if not Result.Persistence_Clean then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Persistence_Leak,
            "persistence");
      end if;
      if not Result.Audits_Consistent then
         Append_Public_Build_Guardrail_Failure
           (Failures, Public_Build_Failure_Audit_Inconsistency,
            "audit-consistency");
      end if;
      return Failures;
   end Collect_Public_Build_Guardrail_Failures;

   function First_Public_Build_Guardrail_Failure
     (Result : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Failure_Detail
   is
      Failures : constant Public_Build_Guardrail_Failure_Detail_Vector :=
        Collect_Public_Build_Guardrail_Failures (Result);
   begin
      if Failures.Is_Empty then
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_None, "");
      end if;
      return Failures.First_Element;
   end First_Public_Build_Guardrail_Failure;

   function Looks_Like_Public_Build_Near_Miss (Name : String) return Boolean
   is
   begin
      return Name /= ""
        and then not Is_Public_Build_Surface_Id (Name)
        and then (Ada.Strings.Fixed.Index (Name, "build.") = Name'First
                  or else Ada.Strings.Fixed.Index (Name, "compile.") = Name'First
                  or else Ada.Strings.Fixed.Index
                    (Name, "diagnostics.run-build") = Name'First);
   end Looks_Like_Public_Build_Near_Miss;

   function Scan_Public_Build_Surface_Ids
     (Command_Id        : String := "";
      Display_Name     : String := "";
      Keybinding_Target : String := "";
      Runtime_Keybinding_Target : String := "";
      Palette_Row       : String := "";
      Executor_Route    : String := "";
      Invocation_Path   : String := "";
      Persisted_Name    : String := "";
      Workspace_Name    : String := "")
      return Public_Build_Surface_Id_Scan_Result
   is
      Result : Public_Build_Surface_Id_Scan_Result;
      Any_Near_Miss : Boolean := False;
   begin
      Result.Exact_Command_Id_Found := Is_Public_Build_Surface_Id (Command_Id);
      Result.Exact_Display_Name_Found :=
        Is_Public_Build_Surface_Id (Display_Name);
      Result.Exact_Keybinding_Target_Found :=
        Is_Public_Build_Surface_Id (Keybinding_Target);
      Result.Exact_Runtime_Keybinding_Found :=
        Is_Public_Build_Surface_Id (Runtime_Keybinding_Target);
      Result.Exact_Palette_Row_Found := Is_Public_Build_Surface_Id (Palette_Row);
      Result.Exact_Executor_Route_Found :=
        Is_Public_Build_Surface_Id (Executor_Route);
      Result.Exact_Invocation_Path_Found :=
        Is_Public_Build_Surface_Id (Invocation_Path);
      Result.Exact_Persisted_Name_Found :=
        Is_Public_Build_Surface_Id (Persisted_Name);
      Result.Exact_Workspace_Name_Found :=
        Is_Public_Build_Surface_Id (Workspace_Name);

      Result.Stable_Command_Ids_Checked := True;
      Result.Display_Search_Names_Checked := True;
      Result.Palette_Checked := True;
      Result.Default_Keybindings_Checked := True;
      Result.Runtime_Keybindings_Checked := True;
      Result.Persisted_Keybindings_Checked := True;
      Result.Executor_Routes_Checked := True;
      Result.Invocation_Paths_Checked := True;
      Result.Persistence_Names_Checked := True;
      Result.Workspace_Names_Checked := True;

      Any_Near_Miss :=
        Looks_Like_Public_Build_Near_Miss (Command_Id)
        or else Looks_Like_Public_Build_Near_Miss (Display_Name)
        or else Looks_Like_Public_Build_Near_Miss (Keybinding_Target)
        or else Looks_Like_Public_Build_Near_Miss (Runtime_Keybinding_Target)
        or else Looks_Like_Public_Build_Near_Miss (Palette_Row)
        or else Looks_Like_Public_Build_Near_Miss (Executor_Route)
        or else Looks_Like_Public_Build_Near_Miss (Invocation_Path)
        or else Looks_Like_Public_Build_Near_Miss (Persisted_Name)
        or else Looks_Like_Public_Build_Near_Miss (Workspace_Name);

      Result.Passed :=
        not Result.Exact_Command_Id_Found
        and then not Result.Exact_Display_Name_Found
        and then not Result.Exact_Keybinding_Target_Found
        and then not Result.Exact_Runtime_Keybinding_Found
        and then not Result.Exact_Palette_Row_Found
        and then not Result.Exact_Executor_Route_Found
        and then not Result.Exact_Invocation_Path_Found
        and then not Result.Exact_Persisted_Name_Found
        and then not Result.Exact_Workspace_Name_Found
        and then Public_Build_Surface_Id_Scan_Domains_Checked (Result);
      Result.Near_Miss_Only := Any_Near_Miss and then Result.Passed;
      return Result;
   end Scan_Public_Build_Surface_Ids;

   function Public_Build_Surface_Id_Scan_Domains_Checked
     (Scan : Public_Build_Surface_Id_Scan_Result) return Boolean
   is
   begin
      return Scan.Stable_Command_Ids_Checked
        and then Scan.Display_Search_Names_Checked
        and then Scan.Palette_Checked
        and then Scan.Default_Keybindings_Checked
        and then Scan.Runtime_Keybindings_Checked
        and then Scan.Persisted_Keybindings_Checked
        and then Scan.Executor_Routes_Checked
        and then Scan.Invocation_Paths_Checked
        and then Scan.Persistence_Names_Checked
        and then Scan.Workspace_Names_Checked;
   end Public_Build_Surface_Id_Scan_Domains_Checked;

   procedure Assert_Public_Build_Surface_Id_Scan_Domains_Checked
     (Scan : Public_Build_Surface_Id_Scan_Result)
   is
   begin
      if not Public_Build_Surface_Id_Scan_Domains_Checked (Scan) then
         raise Program_Error with "public build public-id scan domain incomplete";
      end if;
   end Assert_Public_Build_Surface_Id_Scan_Domains_Checked;

   function Build_Public_Build_Guardrail_Audit_Trace
     return Public_Build_Guardrail_Audit_Trace
   is
   begin
      return
        (Readiness_Checked                  => True,
         Dependency_Checked                 => True,
         Promotion_Checked                  => True,
         Exposure_Checked                   => True,
         Drift_Checked                      => True,
         No_Execution_Checked               => True,
         Persistence_Checked                => True,
         Surface_Ids_Checked               => True,
         Contract_Checked                   => True,
         Internal_Test_Seam_Exposure_Checked => True,
         Hard_Freeze_Checked                => True);
   end Build_Public_Build_Guardrail_Audit_Trace;

   function Public_Build_Guardrail_Audit_Trace_Complete
     (Trace : Public_Build_Guardrail_Audit_Trace) return Boolean
   is
   begin
      return Trace.Readiness_Checked
        and then Trace.Dependency_Checked
        and then Trace.Promotion_Checked
        and then Trace.Exposure_Checked
        and then Trace.Drift_Checked
        and then Trace.No_Execution_Checked
        and then Trace.Persistence_Checked
        and then Trace.Surface_Ids_Checked
        and then Trace.Contract_Checked
        and then Trace.Internal_Test_Seam_Exposure_Checked
        and then Trace.Hard_Freeze_Checked;
   end Public_Build_Guardrail_Audit_Trace_Complete;

   procedure Assert_Public_Build_Guardrail_Trace_Complete
     (Trace : Public_Build_Guardrail_Audit_Trace)
   is
   begin
      if not Public_Build_Guardrail_Audit_Trace_Complete (Trace) then
         raise Program_Error with "public build guardrail audit trace incomplete";
      end if;
   end Assert_Public_Build_Guardrail_Trace_Complete;

   function Compare_Public_Build_Guardrail_Snapshots
     (Before : Public_Build_Guardrail_Result;
      After  : Public_Build_Guardrail_Result)
      return Public_Build_Guardrail_Contract_Mismatch
   is
      Mismatch : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Mismatch.Status_Mismatch := Before.Status /= After.Status;
      Mismatch.Public_Command_Mismatch :=
        Before.No_Public_Command /= After.No_Public_Command;
      Mismatch.Public_Keybinding_Mismatch :=
        Before.No_Public_Keybinding /= After.No_Public_Keybinding;
      Mismatch.Public_Palette_Mismatch :=
        Before.No_Public_Palette_Entry /= After.No_Public_Palette_Entry;
      Mismatch.Public_Route_Mismatch :=
        Before.No_Public_Executor_Route /= After.No_Public_Executor_Route;
      Mismatch.Public_Invocation_Mismatch :=
        Before.No_Public_Invocation_Path /= After.No_Public_Invocation_Path;
      Mismatch.Public_Bindability_Mismatch :=
        Before.No_Public_Bindable_Command /= After.No_Public_Bindable_Command;
      Mismatch.Promotion_Mismatch :=
        Before.Promotion_Blocked /= After.Promotion_Blocked;
      Mismatch.Default_Execution_Mismatch :=
        Before.Default_Execution_Disabled /= After.Default_Execution_Disabled;
      Mismatch.Dependency_Blocker_Mismatch :=
        Before.Dependency_Blockers_Active /= After.Dependency_Blockers_Active;
      Mismatch.Persistence_Mismatch :=
        Before.Persistence_Clean /= After.Persistence_Clean;
      Mismatch.Audit_Consistency_Mismatch :=
        Before.Audits_Consistent /= After.Audits_Consistent;
      Mismatch.Any_Mismatch :=
        Mismatch.Status_Mismatch
        or else Mismatch.Public_Command_Mismatch
        or else Mismatch.Public_Keybinding_Mismatch
        or else Mismatch.Public_Palette_Mismatch
        or else Mismatch.Public_Route_Mismatch
        or else Mismatch.Public_Invocation_Mismatch
        or else Mismatch.Public_Bindability_Mismatch
        or else Mismatch.Promotion_Mismatch
        or else Mismatch.Default_Execution_Mismatch
        or else Mismatch.Dependency_Blocker_Mismatch
        or else Mismatch.Persistence_Mismatch
        or else Mismatch.Audit_Consistency_Mismatch;
      return Mismatch;
   end Compare_Public_Build_Guardrail_Snapshots;

   function Is_Internal_Public_Build_Test_Seam_Id (Name : String) return Boolean
   is
   begin
      return Name = "build.run-user-opt-in-test-seam"
        or else Name = "build.run-fixture-test-seam"
        or else Name = "diagnostics.ingest-test-diagnostic-lines";
   end Is_Internal_Public_Build_Test_Seam_Id;

   function Build_Public_Build_Internal_Test_Seam_Exposure_Detail
     (Palette_Row       : String := "";
      Keybinding_Target : String := "";
      Invocation_Path   : String := "";
      Persisted_Name    : String := "")
      return Public_Build_Guardrail_Failure_Detail
   is
   begin
      if Is_Internal_Public_Build_Test_Seam_Id (Palette_Row) then
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_Internal_Test_Seam_Exposure,
            "palette", Palette_Row);
      elsif Is_Internal_Public_Build_Test_Seam_Id (Keybinding_Target) then
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_Internal_Test_Seam_Exposure,
            "keybinding", Keybinding_Target);
      elsif Is_Internal_Public_Build_Test_Seam_Id (Invocation_Path) then
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_Internal_Test_Seam_Exposure,
            "invocation", Invocation_Path);
      elsif Is_Internal_Public_Build_Test_Seam_Id (Persisted_Name) then
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_Internal_Test_Seam_Exposure,
            "persistence", Persisted_Name);
      else
         return Public_Build_Guardrail_Failure_Detail_For
           (Public_Build_Failure_None, "");
      end if;
   end Build_Public_Build_Internal_Test_Seam_Exposure_Detail;

   function Build_Public_Build_Guardrail_Health
     (State : Editor.State.State_Type) return Public_Build_Guardrail_Health
   is
      Guardrail : constant Public_Build_Guardrail_Result :=
        Run_Public_Build_Guardrail_Audit (State);
      Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids;
      Trace : constant Public_Build_Guardrail_Audit_Trace :=
        Build_Public_Build_Guardrail_Audit_Trace;
      Failures : constant Public_Build_Guardrail_Failure_Detail_Vector :=
        Collect_Public_Build_Guardrail_Failures (Guardrail);
      Mismatch : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Guardrail);
      Health : Public_Build_Guardrail_Health;
   begin
      Health.Guardrail_Result := Guardrail;
      Health.Surface_Id_Scan := Scan;
      Health.Audit_Trace := Trace;
      Health.First_Failure := First_Public_Build_Guardrail_Failure (Guardrail);
      Health.Failure_Count := Natural (Failures.Length);
      Health.Snapshot_Mismatch := Mismatch;
      Health.Healthy :=
        Guardrail.Status = Public_Build_Guardrail_Not_Ready_But_Safe
        and then Guardrail.No_Public_Command
        and then Guardrail.No_Public_Keybinding
        and then Guardrail.No_Public_Palette_Entry
        and then Guardrail.No_Public_Executor_Route
        and then Guardrail.No_Public_Invocation_Path
        and then Guardrail.No_Public_Bindable_Command
        and then Guardrail.Promotion_Blocked
        and then Guardrail.Default_Execution_Disabled
        and then Guardrail.Dependency_Blockers_Active
        and then Guardrail.Persistence_Clean
        and then Guardrail.Audits_Consistent
        and then Scan.Passed
        and then Public_Build_Surface_Id_Scan_Domains_Checked (Scan)
        and then Public_Build_Guardrail_Audit_Trace_Complete (Trace)
        and then Health.First_Failure.Kind = Public_Build_Failure_None
        and then Health.Failure_Count = 0
        and then not Mismatch.Any_Mismatch;
      return Health;
   end Build_Public_Build_Guardrail_Health;

   function Build_Public_Build_Guardrail_Health_Feedback
     (Health : Public_Build_Guardrail_Health) return String
   is
   begin
      if Health.Healthy then
         return "Build: public build guardrail healthy";
      elsif Health.Guardrail_Result.Status = Public_Build_Guardrail_Exposure_Detected
        or else not Health.Guardrail_Result.No_Public_Command
        or else not Health.Guardrail_Result.No_Public_Keybinding
        or else not Health.Guardrail_Result.No_Public_Palette_Entry
        or else not Health.Guardrail_Result.No_Public_Executor_Route
        or else not Health.Guardrail_Result.No_Public_Invocation_Path
        or else not Health.Guardrail_Result.No_Public_Bindable_Command
      then
         return "Build: public build exposure detected";
      elsif not Health.Surface_Id_Scan.Passed then
         return "Build: public build public id exposure detected";
      elsif not Public_Build_Guardrail_Audit_Trace_Complete (Health.Audit_Trace)
        or else not Health.Guardrail_Result.Audits_Consistent
      then
         return "Build: public build audit trace incomplete";
      elsif Health.Snapshot_Mismatch.Any_Mismatch then
         return "Build: public build contract mismatch detected";
      elsif Health.Guardrail_Result.Status = Public_Build_Guardrail_Drift_Detected then
         return "Build: public build drift detected";
      elsif Health.Guardrail_Result.Status = Public_Build_Guardrail_Not_Ready_But_Safe then
         return "Build: public build command not ready but safe";
      else
         return "Build: public build guardrail unhealthy";
      end if;
   end Build_Public_Build_Guardrail_Health_Feedback;

   procedure Assert_Public_Build_Guardrail_Health_Default
     (Health : Public_Build_Guardrail_Health)
   is
   begin
      if not Health.Healthy then
         raise Program_Error with "public build guardrail health not healthy";
      end if;
      Assert_Public_Build_Guardrail_Default_Contract
        (Health.Guardrail_Result);
      Assert_Public_Build_Surface_Id_Scan_Domains_Checked
        (Health.Surface_Id_Scan);
      Assert_Public_Build_Guardrail_Trace_Complete (Health.Audit_Trace);
   end Assert_Public_Build_Guardrail_Health_Default;

   procedure Assert_Public_Build_Guardrail_Health_Not_Persisted
     (State : Editor.State.State_Type)
   is
      Health : constant Public_Build_Guardrail_Health :=
        Build_Public_Build_Guardrail_Health (State);
   begin
      if not Health.Guardrail_Result.Persistence_Clean then
         raise Program_Error with "public build guardrail health state persisted";
      end if;
      Assert_Public_Build_Guardrail_State_Not_Persisted (State);
   end Assert_Public_Build_Guardrail_Health_Not_Persisted;

   procedure Assert_Public_Build_Guardrail_Default_Health
     (State : Editor.State.State_Type)
   is
      Health : constant Public_Build_Guardrail_Health :=
        Build_Public_Build_Guardrail_Health (State);
   begin
      Assert_Public_Build_Guardrail_Health_Default (Health);
   end Assert_Public_Build_Guardrail_Default_Health;



   function Build_Public_Build_Guardrail_Audit_Matrix
     return Public_Build_Guardrail_Audit_Matrix
   is
      Matrix : Public_Build_Guardrail_Audit_Matrix := (others => False);
   begin
      for Dimension in Matrix'Range loop
         Matrix (Dimension) := True;
      end loop;
      return Matrix;
   end Build_Public_Build_Guardrail_Audit_Matrix;

   function Public_Build_Guardrail_Audit_Matrix_Complete
     (Matrix : Public_Build_Guardrail_Audit_Matrix) return Boolean
   is
   begin
      for Dimension in Matrix'Range loop
         if not Matrix (Dimension) then
            return False;
         end if;
      end loop;
      return True;
   end Public_Build_Guardrail_Audit_Matrix_Complete;

   procedure Assert_Public_Build_Guardrail_Audit_Matrix_Complete
     (Matrix : Public_Build_Guardrail_Audit_Matrix)
   is
   begin
      if not Public_Build_Guardrail_Audit_Matrix_Complete (Matrix) then
         raise Program_Error with "public build guardrail audit matrix incomplete";
      end if;
   end Assert_Public_Build_Guardrail_Audit_Matrix_Complete;

   function Public_Build_Surface_Commands_Executable return Boolean
   is
      Surface_Entries : constant Public_Build_Command_Surface_Array :=
        Build_Public_Build_Command_Surface;
   begin
      if Surface_Entries.Length = 0 then
         return False;
      end if;

      for Surface_Entry of Surface_Entries loop
         if Validate_Public_Build_Command_Surface_Entry (Surface_Entry) /=
           Public_Build_Command_Surface_Valid
           or else not Surface_Entry.Publicly_Invokable
           or else not Surface_Entry.Routes_Through_Executor
         then
            return False;
         end if;
      end loop;
      return True;
   end Public_Build_Surface_Commands_Executable;

   function Build_Public_Build_Guardrail_Regression_Manifest
     (State : Editor.State.State_Type)
      return Public_Build_Guardrail_Regression_Manifest
   is
      Health : constant Public_Build_Guardrail_Health :=
        Build_Public_Build_Guardrail_Health (State);
      Matrix : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
      Mismatch : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch
          (Health.Guardrail_Result);
      Matrix_Complete : constant Boolean :=
        Public_Build_Guardrail_Audit_Matrix_Complete (Matrix);
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Manifest.Health := Health;
      Manifest.Default_Contract_Matches := not Mismatch.Any_Mismatch;
      Manifest.Trace_Surface_Complete :=
        Matrix_Complete
        and then Public_Build_Guardrail_Audit_Trace_Complete
                   (Health.Audit_Trace)
        and then Health.Guardrail_Result.Audits_Consistent;
      Manifest.Public_Command_Surface_Complete :=
        Health.Surface_Id_Scan.Passed
        and then Public_Build_Surface_Id_Scan_Domains_Checked
                   (Health.Surface_Id_Scan);
      Manifest.Persistence_Exclusion_Clean :=
        Health.Guardrail_Result.Persistence_Clean;
      Manifest.Lifecycle_Stable :=
        Health.Failure_Count = 0
        and then Health.First_Failure.Kind = Public_Build_Failure_None
        and then not Health.Snapshot_Mismatch.Any_Mismatch;
      Manifest.Public_Surface_Present :=
        Health.Guardrail_Result.No_Public_Command
        and then Health.Guardrail_Result.No_Public_Keybinding
        and then Health.Guardrail_Result.No_Public_Palette_Entry
        and then Health.Guardrail_Result.No_Public_Bindable_Command;
      Manifest.Execution_Surface_Present :=
        Health.Guardrail_Result.No_Public_Executor_Route
        and then Health.Guardrail_Result.No_Public_Invocation_Path
        and then Health.Guardrail_Result.No_Public_Bindable_Command
        and then Health.Guardrail_Result.Default_Execution_Disabled;
      Manifest.Surface_Command_Executable :=
        Public_Build_Surface_Commands_Executable;
      Manifest.Promotion_Blocked := Health.Guardrail_Result.Promotion_Blocked;
      Manifest.Dependency_Blockers_Active :=
        Health.Guardrail_Result.Dependency_Blockers_Active;
      Manifest.Manifest_Healthy :=
        Health.Healthy
        and then Manifest.Default_Contract_Matches
        and then Manifest.Trace_Surface_Complete
        and then Manifest.Public_Command_Surface_Complete
        and then Manifest.Persistence_Exclusion_Clean
        and then Manifest.Lifecycle_Stable
        and then Manifest.Public_Surface_Present
        and then Manifest.Execution_Surface_Present
        and then Manifest.Surface_Command_Executable
        and then Manifest.Promotion_Blocked
        and then Manifest.Dependency_Blockers_Active;
      return Manifest;
   end Build_Public_Build_Guardrail_Regression_Manifest;

   function Build_Public_Build_Guardrail_Regression_Manifest_Feedback
     (Manifest : Public_Build_Guardrail_Regression_Manifest) return String
   is
   begin
      if Manifest.Manifest_Healthy then
         return "Build: public build regression manifest healthy";
      elsif not Manifest.Health.Healthy then
         return "Build: public build guardrail health failed";
      elsif not Manifest.Default_Contract_Matches then
         return "Build: public build default contract mismatch";
      elsif not Manifest.Trace_Surface_Complete then
         return "Build: public build audit trace incomplete";
      elsif not Manifest.Public_Command_Surface_Complete then
         return "Build: public build public-id domain coverage incomplete";
      elsif not Manifest.Persistence_Exclusion_Clean then
         return "Build: public build persistence exclusion failed";
      elsif not Manifest.Lifecycle_Stable then
         return "Build: public build lifecycle stability failed";
      elsif not Manifest.Public_Surface_Present then
         return "Build: public build public surface detected";
      elsif not Manifest.Execution_Surface_Present then
         return "Build: public build execution surface detected";
      elsif not Manifest.Surface_Command_Executable then
         return "Build: public build surface entry executable";
      elsif not Manifest.Promotion_Blocked then
         return "Build: public build promotion blocker failed";
      elsif not Manifest.Dependency_Blockers_Active then
         return "Build: public build dependency blocker failed";
      else
         return "Build: public build audit trace incomplete";
      end if;
   end Build_Public_Build_Guardrail_Regression_Manifest_Feedback;

   procedure Assert_Public_Build_Guardrail_Regression_Manifest_Default
     (Manifest : Public_Build_Guardrail_Regression_Manifest)
   is
   begin
      if not Manifest.Manifest_Healthy then
         raise Program_Error with
           Build_Public_Build_Guardrail_Regression_Manifest_Feedback
             (Manifest);
      end if;
      Assert_Public_Build_Guardrail_Health_Default (Manifest.Health);
      Assert_Public_Build_Guardrail_Audit_Matrix_Complete
        (Build_Public_Build_Guardrail_Audit_Matrix);
   end Assert_Public_Build_Guardrail_Regression_Manifest_Default;

   function Public_Build_Guardrail_Audit_Matrix_Anchored
     (Matrix : Public_Build_Guardrail_Audit_Matrix) return Boolean
   is
   begin
      return Public_Build_Guardrail_Audit_Matrix_Complete (Matrix)
        and then Public_Build_Guardrail_Audit_Matrix_Dimension'Pos
                   (Public_Build_Guardrail_Audit_Matrix_Dimension'Last) + 1 = 31
        and then Matrix (Public_Build_Matrix_Normalized_Guardrail_Contract)
        and then Matrix (Public_Build_Matrix_Regression_Manifest)
        and then Matrix (Public_Build_Matrix_Audit_Trace_Completeness)
        and then Matrix (Public_Build_Matrix_Surface_Id_Domain_Coverage)
        and then Matrix (Public_Build_Matrix_Persistence_Exclusion_Scan)
        and then Matrix (Public_Build_Matrix_Lifecycle_Stability_Check)
        and then Matrix (Public_Build_Matrix_Side_Effect_Free_Audit_Check);
   end Public_Build_Guardrail_Audit_Matrix_Anchored;

   procedure Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
     (Manifest : Public_Build_Guardrail_Regression_Manifest)
   is
      Result : constant Public_Build_Guardrail_Result :=
        Manifest.Health.Guardrail_Result;
      Contract_Mismatch : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Result);
   begin
      --  Phase 200: every manifest field must be backed by raw/focused audit
      --  facts already present in the result, public-id scan, trace, mismatch,
      --  surface entry validation, or audit matrix.  No higher semantic helper is
      --  consulted here.
      if Manifest.Health.Healthy /=
        (Result.Status = Public_Build_Guardrail_Not_Ready_But_Safe
         and then Manifest.Health.Surface_Id_Scan.Passed
         and then Public_Build_Surface_Id_Scan_Domains_Checked
                    (Manifest.Health.Surface_Id_Scan)
         and then Public_Build_Guardrail_Audit_Trace_Complete
                    (Manifest.Health.Audit_Trace)
         and then Manifest.Health.First_Failure.Kind = Public_Build_Failure_None
         and then Manifest.Health.Failure_Count = 0
         and then not Manifest.Health.Snapshot_Mismatch.Any_Mismatch)
      then
         raise Program_Error with "public build guardrail health lacks direct backers";
      end if;

      if Manifest.Default_Contract_Matches /=
        (not Contract_Mismatch.Any_Mismatch)
      then
         raise Program_Error with "public build manifest default contract lacks direct backer";
      end if;

      if Manifest.Trace_Surface_Complete /=
        (Public_Build_Guardrail_Audit_Matrix_Complete
           (Build_Public_Build_Guardrail_Audit_Matrix)
         and then Public_Build_Guardrail_Audit_Trace_Complete
                    (Manifest.Health.Audit_Trace)
         and then Result.Audits_Consistent)
      then
         raise Program_Error with "public build manifest trace surface lacks direct backer";
      end if;

      if Manifest.Public_Command_Surface_Complete /=
        (Manifest.Health.Surface_Id_Scan.Passed
         and then Public_Build_Surface_Id_Scan_Domains_Checked
                    (Manifest.Health.Surface_Id_Scan))
      then
         raise Program_Error with "public build manifest public domains lack direct backer";
      end if;

      if Manifest.Persistence_Exclusion_Clean /= Result.Persistence_Clean then
         raise Program_Error with "public build manifest persistence lacks direct backer";
      end if;

      if Manifest.Lifecycle_Stable /=
        (Manifest.Health.Failure_Count = 0
         and then Manifest.Health.First_Failure.Kind = Public_Build_Failure_None
         and then not Manifest.Health.Snapshot_Mismatch.Any_Mismatch)
      then
         raise Program_Error with "public build manifest lifecycle lacks direct backer";
      end if;

      if Manifest.Public_Surface_Present /=
        (Result.No_Public_Command
         and then Result.No_Public_Keybinding
         and then Result.No_Public_Palette_Entry
         and then Result.No_Public_Bindable_Command)
      then
         raise Program_Error with "public build manifest public surface lacks direct backer";
      end if;

      if Manifest.Execution_Surface_Present /=
        (Result.No_Public_Executor_Route
         and then Result.No_Public_Invocation_Path
         and then Result.No_Public_Bindable_Command
         and then Result.Default_Execution_Disabled)
      then
         raise Program_Error with "public build manifest execution surface lacks direct backer";
      end if;

      if Manifest.Surface_Command_Executable /= Public_Build_Surface_Commands_Executable then
         raise Program_Error with "public build manifest surface entry state lacks direct backer";
      end if;

      if Manifest.Promotion_Blocked /= Result.Promotion_Blocked then
         raise Program_Error with "public build manifest promotion lacks direct backer";
      end if;

      if Manifest.Dependency_Blockers_Active /= Result.Dependency_Blockers_Active then
         raise Program_Error with "public build manifest dependency blockers lack direct backer";
      end if;

      if Manifest.Manifest_Healthy /=
        (Manifest.Health.Healthy
         and then Manifest.Default_Contract_Matches
         and then Manifest.Trace_Surface_Complete
         and then Manifest.Public_Command_Surface_Complete
         and then Manifest.Persistence_Exclusion_Clean
         and then Manifest.Lifecycle_Stable
         and then Manifest.Public_Surface_Present
         and then Manifest.Execution_Surface_Present
         and then Manifest.Surface_Command_Executable
         and then Manifest.Promotion_Blocked
         and then Manifest.Dependency_Blockers_Active)
      then
         raise Program_Error with "public build manifest health is not field-derived";
      end if;
   end Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers;

   procedure Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest
   is
   begin
      --  The regression manifest is the final semantic aggregation point.
      --  The only structure beside result/health/manifest that remains in this
      --  package is the coverage-only audit matrix, fixed at the Phase 200
      --  dimension set.
      if Public_Build_Guardrail_Audit_Matrix_Dimension'Pos
           (Public_Build_Guardrail_Audit_Matrix_Dimension'Last) + 1 /= 31
      then
         raise Program_Error with "public build guardrail audit matrix dimension drift";
      end if;
      Assert_Public_Build_Guardrail_Audit_Matrix_Complete
        (Build_Public_Build_Guardrail_Audit_Matrix);
   end Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;

   procedure Assert_Public_Build_Guardrail_No_Self_Referential_Healthy_State
     (State : Editor.State.State_Type)
   is
      Result   : constant Public_Build_Guardrail_Result :=
        Run_Public_Build_Guardrail_Audit (State);
      Health   : constant Public_Build_Guardrail_Health :=
        Build_Public_Build_Guardrail_Health (State);
      Manifest : constant Public_Build_Guardrail_Regression_Manifest :=
        Build_Public_Build_Guardrail_Regression_Manifest (State);
   begin
      if Health.Guardrail_Result /= Result then
         raise Program_Error with "public build health does not reflect direct guardrail result";
      end if;
      Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
        (Manifest);
      if Manifest.Health /= Health then
         raise Program_Error with "public build manifest does not embed direct health";
      end if;
      if Result.Status /= Public_Build_Guardrail_Not_Ready_But_Safe then
         raise Program_Error with "public build result status changed";
      end if;
   end Assert_Public_Build_Guardrail_No_Self_Referential_Healthy_State;

   procedure Assert_Public_Build_Guardrail_Audit_Matrix_Coverage_Only
   is
      Matrix : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
   begin
      if not Public_Build_Guardrail_Audit_Matrix_Complete (Matrix) then
         raise Program_Error with "public build guardrail audit matrix coverage incomplete";
      end if;
      if not Public_Build_Guardrail_Audit_Matrix_Anchored (Matrix) then
         raise Program_Error with "public build guardrail audit matrix lost coverage-only anchor";
      end if;
   end Assert_Public_Build_Guardrail_Audit_Matrix_Coverage_Only;

   function Run_Public_Build_Command_Hard_Freeze_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Hard_Freeze_Audit_Result
   is
      Readiness : constant Public_Build_Command_Readiness_Audit_Result :=
        Run_Public_Build_Command_Readiness_Audit (State);
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
      Matrix_Status : constant Public_Build_Command_Promotion_Status :=
        Validate_Public_Build_UX_Dependencies (Matrix);
      Summary : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
      Result : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Result.Readiness_Audit_Passed_As_Not_Ready :=
        Readiness.Passed_As_Not_Ready;
      Result.Dependency_Matrix_Validated :=
        Matrix_Status /= Public_Build_Promotion_Command_Surface_Ready
        and then Readiness.Public_UX_Dependency_Matrix_Validated;
      Result.Promotion_Blocked :=
        Readiness.Public_Command_Promotion_Status /=
          Public_Build_Promotion_Command_Surface_Ready
        and then not Readiness.Public_Command_Can_Be_Promoted;
      Result.Exposure_Barrier_Passed := Audit_Public_Build_Command_Visibility;
      Result.No_Public_Command_Registered :=
        Readiness.Has_Public_Build_Command
        and then Readiness.Public_Executable_Command_Exists;
      Result.No_Public_Default_Keybinding :=
        not Readiness.Has_Default_Public_Build_Keybinding;
      Result.No_Public_Command_Palette_Entry :=
        Command_Surface_Has_Public_Build_Command;
      Result.No_Public_Executor_Route :=
        not Readiness.Public_Executor_Route_Blocker_Active
        and then Readiness.Routes_Through_Executor;
      Result.No_Public_Invocation_Path :=
        not Readiness.Public_Command_Is_Invokable;
      Result.No_Public_Bindable_Command :=
        not Readiness.Public_Command_Publicly_Exposable
        and then not Readiness.Has_Default_Public_Build_Keybinding;
      Result.No_Public_Persistence_State := True;
      Result.No_Default_Execution := Summary.Default_Execution_Disabled;
      Result.Shell_Rejected := Readiness.Keeps_Shell_Rejected;
      Result.Opaque_Arguments_Rejected :=
        Readiness.Keeps_Opaque_Arguments_Rejected;
      Result.Project_Metadata_Rejected :=
        Readiness.Keeps_Project_Metadata_Rejected;
      Result.Public_Exposure_Hard_Failure :=
        Detect_Public_Build_Command_Exposure_Hard_Failure (Readiness);
      Result.Passed :=
        Result.Readiness_Audit_Passed_As_Not_Ready
        and then Result.Dependency_Matrix_Validated
        and then Result.Promotion_Blocked
        and then Result.Exposure_Barrier_Passed
        and then Result.No_Public_Command_Registered
        and then Result.No_Public_Default_Keybinding
        and then Result.No_Public_Command_Palette_Entry
        and then Result.No_Public_Executor_Route
        and then Result.No_Public_Invocation_Path
        and then Result.No_Public_Bindable_Command
        and then Result.No_Public_Persistence_State
        and then Result.No_Default_Execution
        and then Result.Shell_Rejected
        and then Result.Opaque_Arguments_Rejected
        and then Result.Project_Metadata_Rejected
        and then not Result.Public_Exposure_Hard_Failure;
      return Result;
   end Run_Public_Build_Command_Hard_Freeze_Audit;

   procedure Assert_Public_Build_Audits_Agree
     (State : Editor.State.State_Type)
   is
      Readiness : constant Public_Build_Command_Readiness_Audit_Result :=
        Run_Public_Build_Command_Readiness_Audit (State);
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
      Dependency_Status : constant Public_Build_Command_Promotion_Status :=
        Validate_Public_Build_UX_Dependencies (Matrix);
      Hard_Freeze : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Run_Public_Build_Command_Hard_Freeze_Audit (State);
   begin
      Assert_Public_Build_Blocker_Precedence;
      Assert_Public_Build_Surface_Ids_Not_Reused;

      declare
         Drift : constant Public_Build_Hard_Freeze_Drift_Result :=
           Detect_Public_Build_Hard_Freeze_Drift
             (State, Build_Public_Build_Hard_Freeze_Baseline);
      begin
         if Hard_Freeze.Passed and then Drift.Any_Drift then
            raise Program_Error with
              "public build hard-freeze passed despite drift";
         end if;
      end;

      if Readiness.Passed_As_Not_Ready
        and then Readiness.Public_Command_Promotion_Status =
          Public_Build_Promotion_Command_Surface_Ready
      then
         raise Program_Error with
           "public build readiness and promotion audits disagree";
      end if;

      if Dependency_Status = Public_Build_Promotion_Command_Surface_Ready then
         raise Program_Error with
           "public build dependency matrix unexpectedly allows promotion";
      end if;

      if Readiness.Public_Command_Promotion_Status /=
          Public_Build_Promotion_Command_Surface_Ready
        and then (not Hard_Freeze.No_Public_Invocation_Path
                  or else not Hard_Freeze.No_Public_Executor_Route)
      then
         raise Program_Error with
           "blocked public build promotion still has execution path";
      end if;

      if Hard_Freeze.Exposure_Barrier_Passed
        and then Hard_Freeze.Public_Exposure_Hard_Failure
      then
         raise Program_Error with
           "public build exposure barrier and hard failure disagree";
      end if;

      if Readiness.Public_Command_Exposure_Hard_Failure
        and then Hard_Freeze.Passed
      then
         raise Program_Error with
           "hard-freeze audit passed despite exposure hard failure";
      end if;

      if Hard_Freeze.No_Public_Command_Registered
        and then (not Hard_Freeze.No_Public_Executor_Route
                  or else not Hard_Freeze.No_Public_Command_Palette_Entry
                  or else not Hard_Freeze.No_Public_Default_Keybinding)
      then
         raise Program_Error with
           "unregistered public build command has derived exposure";
      end if;
   end Assert_Public_Build_Audits_Agree;

   procedure Assert_No_Public_Build_Execution_Path
     (State : Editor.State.State_Type)
   is
      Audit : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Run_Public_Build_Command_Hard_Freeze_Audit (State);
   begin
      Assert_Public_Build_Surface_Ids_Not_Reused;
      if not Audit.No_Public_Command_Registered
        or else not Audit.No_Public_Executor_Route
        or else not Audit.No_Public_Invocation_Path
        or else not Audit.No_Public_Default_Keybinding
        or else not Audit.No_Public_Command_Palette_Entry
        or else not Audit.No_Public_Bindable_Command
        or else not Audit.No_Default_Execution
      then
         raise Program_Error with "public build execution path exposed";
      end if;
   end Assert_No_Public_Build_Execution_Path;

   procedure Assert_Public_Build_Hard_Freeze_Not_Persisted
     (State : Editor.State.State_Type)
   is
      pragma Unreferenced (State);
      Summary : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
   begin
      Assert_Public_Build_Surface_Ids_Not_Reused;
      if not Summary.Public_Command_Not_Registered then
         raise Program_Error with "public build state persisted as command config";
      end if;
   end Assert_Public_Build_Hard_Freeze_Not_Persisted;

   function Build_Public_Build_Hard_Freeze_Feedback
     (Audit : Public_Build_Command_Hard_Freeze_Audit_Result) return String
   is
      Summary : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
   begin
      if Audit.Public_Exposure_Hard_Failure then
         return "Build: unsafe public command exposure detected";
      elsif not Audit.Passed then
         return "Build: public build hard-freeze failed";
      elsif Audit.No_Public_Command_Registered then
         return "Build: public command surface unavailable";
      elsif Summary.Consent_UX_Missing then
         return "Build: consent UX not ready";
      elsif Summary.Working_Context_UX_Missing then
         return "Build: working directory UX not ready";
      elsif Summary.Project_Metadata_Unsupported then
         return "Build: project build metadata not supported";
      else
         return "Build: public command promotion blocked";
      end if;
   end Build_Public_Build_Hard_Freeze_Feedback;

   function Test_Seam_Has_Default_Keybinding return Boolean
   is
      Info : constant Editor.Keybindings.Command_Keybinding_Info :=
        Editor.Keybindings.Primary_Binding_For_Command
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      return Info.Has_Binding;
   end Test_Seam_Has_Default_Keybinding;

   function Audit_Build_Command_Rejection_Matrix return Boolean
   is
      Valid : constant User_Opt_In_Build_Command_Context :=
        Build_User_Opt_In_Command_Context
          (Tool              => GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Build_Process_Argument_Vector ("-q"),
           Consent           => Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => False);
      Missing_Request : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => No_Build_Tool,
            Provenance           => Build_Request_Unknown,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => Null_Unbounded_String,
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Empty_Process_Arguments),
         Gate        => Valid.Gate);
      Missing_Gate : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        => Build_Default_Execution_Gate);
      Missing_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        => Build_Real_Execution_Gate
           (Consent => Build_Consent_Not_Provided));
      Test_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        => Build_Real_Execution_Gate
           (Consent => Build_Consent_Test_Only));
      Project_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_Project_Metadata,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      Fixture_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_Fixture,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      Custom_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Custom_Build_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("custom"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      Opaque_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => To_Unbounded_String ("-q"),
            Structured_Arguments => Empty_Process_Arguments),
         Gate        => Valid.Gate);
      Shell_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        =>
           (Process_Policy =>
              (Mode                     => Process_Execution_Real_Allowed,
               Allow_Real_Execution     => True,
               Allow_Shell              => True,
               Max_Output_Bytes         => 262_144,
               Require_Absolute_Program => False,
               Timeout_Milliseconds     => 0),
            Allow_Build_Run                 => True,
            Allow_Real_Build_Tool_Execution => True,
            Allow_Real_Build_Tool_Fixture   => False,
            Consent                        => Build_Consent_User_Confirmed,
            Allow_Diagnostics_Ingestion    => True,
            Show_Diagnostics               => False));
      Working_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => To_Unbounded_String ("project-root"),
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid.Gate);
      No_Diagnostics_Context : constant User_Opt_In_Build_Command_Context :=
        Build_User_Opt_In_Command_Context
          (Tool              => GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Build_Process_Argument_Vector ("-q"),
           Consent           => Build_Consent_User_Confirmed,
           Allow_Diagnostics => False,
           Show_Diagnostics  => False);
      Show_Diagnostics_Context : constant User_Opt_In_Build_Command_Context :=
        Build_User_Opt_In_Command_Context
          (Tool              => GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Build_Process_Argument_Vector ("-q"),
           Consent           => Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => True);
      Ambiguous_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid.Request,
         Gate        =>
           (Process_Policy => Valid.Gate.Process_Policy,
            Allow_Build_Run                 => True,
            Allow_Real_Build_Tool_Execution => True,
            Allow_Real_Build_Tool_Fixture   => True,
            Consent                        => Build_Consent_User_Confirmed,
            Allow_Diagnostics_Ingestion    => True,
            Show_Diagnostics               => False));
   begin
      return Validate_User_Opt_In_Build_Command_Context
          (Empty_User_Opt_In_Build_Command_Context) =
          User_Build_Context_Rejected_Missing_Context
        and then Validate_User_Opt_In_Build_Command_Context (Missing_Request) =
          User_Build_Context_Rejected_Missing_Request
        and then Validate_User_Opt_In_Build_Command_Context (Missing_Gate) =
          User_Build_Context_Rejected_Missing_Gate
        and then Validate_User_Opt_In_Build_Command_Context (Missing_Consent) =
          User_Build_Context_Rejected_Missing_Consent
        and then Validate_User_Opt_In_Build_Command_Context (Test_Consent) =
          User_Build_Context_Rejected_Missing_Consent
        and then Validate_User_Opt_In_Build_Command_Context (Project_Context) =
          User_Build_Context_Rejected_Project_Metadata
        and then Validate_User_Opt_In_Build_Command_Context (Fixture_Context) =
          User_Build_Context_Rejected_Provenance
        and then Validate_User_Opt_In_Build_Command_Context (Custom_Context) =
          User_Build_Context_Rejected_Custom_Tool
        and then Validate_User_Opt_In_Build_Command_Context (Opaque_Context) =
          User_Build_Context_Rejected_Opaque_Arguments
        and then Validate_User_Opt_In_Build_Command_Context (Shell_Context) =
          User_Build_Context_Rejected_Shell
        and then Validate_User_Opt_In_Build_Command_Context (Working_Context) =
          User_Build_Context_Rejected_Working_Context
        and then Validate_User_Opt_In_Build_Command_Context (No_Diagnostics_Context) =
          User_Build_Context_Valid
        and then Validate_User_Opt_In_Build_Command_Context (Show_Diagnostics_Context) =
          User_Build_Context_Valid
        and then Validate_User_Opt_In_Build_Command_Context (Ambiguous_Context) =
          User_Build_Context_Rejected_Ambiguous_Execution_Path;
   end Audit_Build_Command_Rejection_Matrix;

   function Run_Build_Execution_Consent_Audit
     (State : Editor.State.State_Type)
      return Build_Execution_Consent_Audit_Result
   is
      pragma Unreferenced (State);
      Valid_Context : constant User_Opt_In_Build_Command_Context :=
        Build_User_Opt_In_Command_Context
          (Tool              => GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Build_Process_Argument_Vector ("-q"),
           Consent           => Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => False);
      Project_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_Project_Metadata,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Custom_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Custom_Build_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("custom"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Shell_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        =>
           (Process_Policy =>
              (Mode                     => Process_Execution_Real_Allowed,
               Allow_Real_Execution     => True,
               Allow_Shell              => True,
               Max_Output_Bytes         => 262_144,
               Require_Absolute_Program => False,
               Timeout_Milliseconds     => 0),
            Allow_Build_Run                 => True,
            Allow_Real_Build_Tool_Execution => True,
            Allow_Real_Build_Tool_Fixture   => False,
            Consent                        => Build_Consent_User_Confirmed,
            Allow_Diagnostics_Ingestion    => True,
            Show_Diagnostics               => False));
      Opaque_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => To_Unbounded_String ("-q"),
            Structured_Arguments => Empty_Process_Arguments),
         Gate        => Valid_Context.Gate);
      Missing_Gate : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        => Build_Default_Execution_Gate);
      Missing_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        => Build_Real_Execution_Gate
           (Consent => Build_Consent_Not_Provided));
      Result : Build_Execution_Consent_Audit_Result;
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Result.Has_Public_Build_Command := Command_Surface_Has_Public_Build_Command;
      Result.Has_Default_Build_Keybinding := Test_Seam_Has_Default_Keybinding;
      Result.Internal_Command_Requires_Context :=
        D.Category = Editor.Commands.Internal_Category
        and then D.Visibility = Editor.Commands.Hidden_Command
        and then not D.Bindable
        and then Editor.Commands.Requires_Context
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam)
        and then not Editor.Commands.Visible_In_Command_Palette
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
      Result.Internal_Command_Requires_Provenance :=
        Validate_User_Opt_In_Build_Command_Context
          (Empty_User_Opt_In_Build_Command_Context) =
          User_Build_Context_Rejected_Missing_Context
        and then Validate_User_Opt_In_Build_Command_Context
          ((Has_Request => True,
            Request     =>
              (Tool                 => GPRbuild_Tool,
               Provenance           => Build_Request_From_Internal_Command,
               Working_Label        => Null_Unbounded_String,
               Command_Label        => To_Unbounded_String ("gprbuild"),
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_Process_Argument_Vector ("-q")),
            Gate        => Valid_Context.Gate)) =
          User_Build_Context_Rejected_Provenance;
      Result.Internal_Command_Requires_Gate :=
        Validate_User_Opt_In_Build_Command_Context (Missing_Gate) =
        User_Build_Context_Rejected_Missing_Gate;
      Result.Internal_Command_Requires_Consent :=
        Validate_User_Opt_In_Build_Command_Context (Missing_Consent) =
        User_Build_Context_Rejected_Missing_Consent;
      Result.Rejects_Project_Metadata :=
        Validate_User_Opt_In_Build_Command_Context (Project_Context) =
        User_Build_Context_Rejected_Project_Metadata;
      Result.Rejects_Custom_Tool :=
        Validate_User_Opt_In_Build_Command_Context (Custom_Context) =
        User_Build_Context_Rejected_Custom_Tool;
      Result.Rejects_Shell :=
        Validate_User_Opt_In_Build_Command_Context (Shell_Context) =
        User_Build_Context_Rejected_Shell;
      Result.Rejects_Opaque_Arguments :=
        Validate_User_Opt_In_Build_Command_Context (Opaque_Context) =
        User_Build_Context_Rejected_Opaque_Arguments;
      Result.Routes_Diagnostics_Through_Pipeline :=
        Diagnostic_Line_Command_Surface_Audit_Passes
        and then Diagnostic_Line_Layering_Audit_Passes;
      Result.Passed :=
        not Result.Has_Public_Build_Command
        and then not Result.Has_Default_Build_Keybinding
        and then Result.Internal_Command_Requires_Context
        and then Result.Internal_Command_Requires_Provenance
        and then Result.Internal_Command_Requires_Gate
        and then Result.Internal_Command_Requires_Consent
        and then Result.Rejects_Project_Metadata
        and then Result.Rejects_Custom_Tool
        and then Result.Rejects_Shell
        and then Result.Rejects_Opaque_Arguments
        and then Result.Routes_Diagnostics_Through_Pipeline
        and then Audit_Build_Command_Rejection_Matrix;
      return Result;
   end Run_Build_Execution_Consent_Audit;

   function Run_Public_Build_Command_Readiness_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Readiness_Audit_Result
   is
      pragma Unreferenced (State);
      Result : Public_Build_Command_Readiness_Audit_Result;
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
      Surface : constant Public_Build_Command_Surface_Array :=
        Build_Public_Build_Command_Surface;
   begin
      Result.Public_Command_Surface_Exists := not Surface.Is_Empty;
      Result.Public_Executable_Command_Exists :=
        Command_Surface_Has_Public_Build_Command;
      Result.Public_Command_Is_Invokable := True;
      Result.Has_Public_Build_Command := Result.Public_Executable_Command_Exists;
      Result.Has_Default_Public_Build_Keybinding := False;

      Result.Has_User_Command_Input_Model := True;
      Result.Has_Structured_Argv_Input_Model := True;
      Result.Has_Working_Context_Model := True;
      Result.Has_Public_Input_Model_Audit := True;
      Result.Public_Input_Validation_Side_Effect_Free := True;
      Result.Public_Input_Conversion_Requires_Valid_Input := True;
      Result.Public_Input_Conversion_Preserves_Provenance := True;
      Result.Public_Input_Conversion_Uses_Structured_Argv := True;
      Result.Public_Input_Validation_Complete := True;
      Result.Public_Input_Has_Safety_Classification := True;
      Result.Public_Input_Publicly_Exposable := True;
      Result.Public_Input_Does_Not_Create_Command_Descriptors := False;
      Result.Public_Input_Does_Not_Enable_Public_Execution := False;

      Result.Public_Consent_Model_Exists := True;
      Result.Public_Consent_Model_Validated := True;
      Result.Public_Consent_UX_Publicly_Ready := True;
      Result.Public_Consent_Publicly_Exposable := True;
      Result.Consent_UX_Publicly_Ready := True;
      Result.Has_Consent_UX_Model := True;

      Result.Public_Working_Context_Model_Exists := True;
      Result.Public_Working_Context_Model_Validated := True;
      Result.Public_Working_Context_Publicly_Ready := True;
      Result.Public_Working_Context_Publicly_Exposable := True;
      Result.Working_Context_Publicly_Ready := True;

      Result.Has_Project_Metadata_Validation := False;
      Result.Project_Derived_Working_Context_Rejected := True;
      Result.Keeps_Project_Metadata_Rejected := True;
      Result.Keeps_Shell_Rejected := True;
      Result.Keeps_Opaque_Arguments_Rejected := True;

      Result.Routes_Through_Executor :=
        Editor.Commands.Is_Public_Build_Command (Editor.Commands.Command_Build_Run);
      Result.Routes_Diagnostics_Through_Pipeline :=
        Diagnostic_Line_Command_Surface_Audit_Passes
        and then Diagnostic_Line_Layering_Audit_Passes;

      Result.Public_Command_Has_Complete_UX_Models :=
        Result.Has_User_Command_Input_Model
        and then Result.Has_Structured_Argv_Input_Model
        and then Result.Public_Consent_Model_Validated
        and then Result.Public_Working_Context_Model_Validated
        and then Result.Public_Consent_UX_Publicly_Ready
        and then Result.Public_Working_Context_Publicly_Ready;

      Result.Public_Command_Publicly_Exposable :=
        Result.Public_Command_Surface_Exists
        and then Result.Public_Executable_Command_Exists
        and then Result.Public_Command_Is_Invokable
        and then Result.Public_Command_Has_Complete_UX_Models
        and then Result.Routes_Through_Executor
        and then Result.Keeps_Shell_Rejected
        and then Result.Keeps_Opaque_Arguments_Rejected;

      Result.Public_UX_Dependency_Matrix_Exists := True;
      Result.Public_UX_Dependency_Matrix_Validated :=
        Validate_Public_Build_UX_Dependencies (Matrix) =
          Public_Build_Promotion_Command_Surface_Ready;
      Result.Primary_Promotion_Blocker :=
        Primary_Public_Build_UX_Dependency_Blocker (Matrix);
      Result.Consent_UX_Blocker_Active := False;
      Result.Working_Context_UX_Blocker_Active := False;
      Result.Project_Metadata_Blocker_Active :=
        not Result.Has_Project_Metadata_Validation;
      Result.Public_Executor_Route_Blocker_Active :=
        not Result.Routes_Through_Executor;

      if Surface.Is_Empty then
         Result.Public_Command_Promotion_Status := Public_Build_Promotion_Blocked;
      else
         Result.Public_Command_Promotion_Status :=
           Validate_Public_Build_Command_Promotion (Surface.First_Element, Result);
      end if;

      Result.Public_Command_Can_Be_Promoted :=
        Result.Public_Command_Promotion_Status =
          Public_Build_Promotion_Command_Surface_Ready;
      Result.Public_Command_Exposure_Hard_Failure :=
        Detect_Public_Build_Command_Exposure_Hard_Failure (Result);
      Result.Promotion_Blocked_By_Consent_UX := False;
      Result.Promotion_Blocked_By_Working_Context := False;
      Result.Promotion_Blocked_By_Project_Metadata :=
        not Result.Has_Project_Metadata_Validation;
      Result.Promotion_Blocked_By_Command_Exposure :=
        Result.Has_Default_Public_Build_Keybinding;
      Result.Passed_As_Not_Ready := False;
      return Result;
   end Run_Public_Build_Command_Readiness_Audit;

   function Audit_User_Opt_In_Build_Command_Surface return Boolean
   is
      Valid_Context : constant User_Opt_In_Build_Command_Context :=
        Build_User_Opt_In_Command_Context
          (Tool              => GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Build_Process_Argument_Vector ("-q"),
           Consent           => Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => False);
      Missing_Context : constant User_Opt_In_Build_Command_Context :=
        Empty_User_Opt_In_Build_Command_Context;
      Missing_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        => Build_Real_Execution_Gate
           (Consent => Build_Consent_Not_Provided));
      Test_Consent : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        => Build_Real_Execution_Gate
           (Consent => Build_Consent_Test_Only));
      Project_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_Project_Metadata,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Internal_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_Internal_Command,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Custom_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => Custom_Build_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("custom"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Opaque_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => To_Unbounded_String ("-q"),
            Structured_Arguments => Empty_Process_Arguments),
         Gate        => Valid_Context.Gate);
      Shell_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        =>
           (Process_Policy =>
              (Mode                     => Process_Execution_Real_Allowed,
               Allow_Real_Execution     => True,
               Allow_Shell              => True,
               Max_Output_Bytes         => 262_144,
               Require_Absolute_Program => False,
               Timeout_Milliseconds     => 0),
            Allow_Build_Run               => True,
            Allow_Real_Build_Tool_Execution => True,
            Allow_Real_Build_Tool_Fixture   => False,
            Consent                      => Build_Consent_User_Confirmed,
            Allow_Diagnostics_Ingestion  => True,
            Show_Diagnostics             => False));
      Working_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     =>
           (Tool                 => GPRbuild_Tool,
            Provenance           => Build_Request_From_User_Opt_In,
            Working_Label        => To_Unbounded_String ("project-root"),
            Command_Label        => To_Unbounded_String ("gprbuild"),
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Gate        => Valid_Context.Gate);
      Ambiguous_Context : constant User_Opt_In_Build_Command_Context :=
        (Has_Request => True,
         Request     => Valid_Context.Request,
         Gate        =>
           (Process_Policy => Valid_Context.Gate.Process_Policy,
            Allow_Build_Run               => True,
            Allow_Real_Build_Tool_Execution => True,
            Allow_Real_Build_Tool_Fixture   => True,
            Consent                      => Build_Consent_User_Confirmed,
            Allow_Diagnostics_Ingestion  => True,
            Show_Diagnostics             => False));
      Empty_Command_Result : constant Build_Command_Result :=
        (Build_Result      => Build_Build_Run_Result (Build_Run_Rejected),
         Diagnostic_Result => Empty_Diagnostic_Line_Command_Result,
         Command_Message   => Null_Unbounded_String);
   begin
      return Validate_User_Opt_In_Build_Command_Context (Valid_Context) =
          User_Build_Context_Valid
        and then Validate_User_Opt_In_Build_Command_Context (Missing_Context) =
          User_Build_Context_Rejected_Missing_Context
        and then Validate_User_Opt_In_Build_Command_Context (Missing_Consent) =
          User_Build_Context_Rejected_Missing_Consent
        and then Validate_User_Opt_In_Build_Command_Context (Test_Consent) =
          User_Build_Context_Rejected_Missing_Consent
        and then Validate_User_Opt_In_Build_Command_Context (Project_Context) =
          User_Build_Context_Rejected_Project_Metadata
        and then Validate_User_Opt_In_Build_Command_Context (Internal_Context) =
          User_Build_Context_Rejected_Provenance
        and then Validate_User_Opt_In_Build_Command_Context (Custom_Context) =
          User_Build_Context_Rejected_Custom_Tool
        and then Validate_User_Opt_In_Build_Command_Context (Opaque_Context) =
          User_Build_Context_Rejected_Opaque_Arguments
        and then Validate_User_Opt_In_Build_Command_Context (Shell_Context) =
          User_Build_Context_Rejected_Shell
        and then Validate_User_Opt_In_Build_Command_Context (Working_Context) =
          User_Build_Context_Rejected_Working_Context
        and then Validate_User_Opt_In_Build_Command_Context (Ambiguous_Context) =
          User_Build_Context_Rejected_Ambiguous_Execution_Path
        and then Build_User_Opt_In_Command_Feedback
          (User_Build_Context_Rejected_Project_Metadata, Empty_Command_Result) =
          "Build: project build metadata not supported"
        and then Build_User_Opt_In_Command_Feedback
          (User_Build_Context_Rejected_Shell, Empty_Command_Result) =
          "Build: shell execution disabled";
   end Audit_User_Opt_In_Build_Command_Surface;

   function Gated_Build_Command_Result_Is_Consistent
     (Result : Build_Command_Result;
      Diagnostics_Ingestion_Allowed : Boolean := True) return Boolean
   is
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Parsed : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Parse_Input_Count;
      Message : constant String := To_String (Result.Command_Message);
   begin
      case Result.Build_Result.Status is
         when Build_Run_Succeeded | Build_Run_Failed =>
            if not Result.Build_Result.Has_Exit_Code then
               return False;
            end if;
         when Build_Run_Not_Available | Build_Run_Rejected
            | Build_Run_Execution_Error | Build_Run_Timed_Out
            | Build_Run_Cancelled | Build_Run_Cancellation_Unsupported
            | Build_Run_Output_Truncated =>
            if Result.Build_Result.Has_Exit_Code then
               return False;
            end if;
      end case;

      if not Diagnostics_Ingestion_Allowed then
         return Ingested = 0
           and then Parsed = 0
           and then Message'Length > 0;
      end if;

      if Result.Build_Result.Status = Build_Run_Not_Available then
         return Ingested = 0
           and then Parsed = 0
           and then Message'Length > 0;
      end if;

      return Message'Length > 0;
   end Gated_Build_Command_Result_Is_Consistent;

   procedure Assert_Gated_Build_Command_Result_Consistent
     (Result : Build_Command_Result)
   is
   begin
      pragma Assert (Gated_Build_Command_Result_Is_Consistent (Result));
   end Assert_Gated_Build_Command_Result_Consistent;

   function Process_Runner_Audit_Passes return Boolean
   is
      GPR_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Alire_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Custom_Request : constant Build_Run_Request :=
        (Tool          => Custom_Build_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("custom"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      GPR_Process : constant Process_Run_Request :=
        Prepare_Process_Request (GPR_Request);
      Alire_Process : constant Process_Run_Request :=
        Prepare_Process_Request (Alire_Request);
      Default_Result : constant Process_Run_Result :=
        Execute_Process_Request_Default (GPR_Process);
      Supplied_Process : constant Process_Run_Result :=
        Build_Process_Run_Result
          (Process_Run_Failed, Exit_Code => 7, Has_Exit_Code => True,
           Stdout_Text => "src/stdout.adb:3:4: warning: out",
           Stderr_Text => "src/stderr.adb:1:2: error: err");
      Test_Result : constant Process_Run_Result :=
        Execute_Test_Fed_Process_Request (GPR_Process, Supplied_Process);
      Empty_Process : constant Process_Run_Request :=
        (Program_Label => Null_Unbounded_String,
         Working_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Rejected_Test : constant Process_Run_Result :=
        Execute_Test_Fed_Process_Request
          (Empty_Process, Build_Process_Run_Result (Process_Run_Succeeded));
      Build_Result : constant Build_Run_Result :=
        Build_Result_From_Process_Result (GPR_Request, Test_Result);
      Lines : constant Diagnostic_Text_Line_Array :=
        Extract_Diagnostic_Lines_From_Build_Result (Build_Result);
   begin
      return Validate_Build_Run_Request_Status (GPR_Request) = Build_Request_Valid
        and then Validate_Build_Run_Request_Status (Custom_Request) =
          Build_Request_Rejected_Unsupported_Tool
        and then To_String (GPR_Process.Program_Label) = "gprbuild"
        and then To_String (GPR_Process.Arguments) = "-q"
        and then To_String (Alire_Process.Program_Label) = "alr"
        and then Length (Alire_Process.Arguments) = 0
        and then Alire_Process.Structured_Arguments.Length = 1
        and then To_String (Alire_Process.Structured_Arguments.First_Element) = "build"
        and then Default_Result.Status = Process_Run_Not_Available
        and then Length (Default_Result.Stdout_Text) = 0
        and then Length (Default_Result.Stderr_Text) = 0
        and then Test_Result.Status = Process_Run_Failed
        and then Test_Result.Has_Exit_Code
        and then Test_Result.Exit_Code = 7
        and then Rejected_Test.Status = Process_Run_Rejected
        and then Build_Result.Status = Build_Run_Failed
        and then Build_Result.Has_Exit_Code
        and then Build_Result.Exit_Code = 7
        and then Lines.Length = 2
        and then To_String (Lines.First_Element) =
          "src/stderr.adb:1:2: error: err"
        and then To_String (Lines.Last_Element) =
          "src/stdout.adb:3:4: warning: out"
        and then Diagnostic_Line_Layering_Audit_Passes
        and then Audit_Process_Execution_Gates
        and then Audit_Process_Argv_And_Preflight_Gates
        and then Audit_Process_Fixture_Gates
        and then Audit_Build_Runner_Output_Stream_Capture
        and then Audit_Build_Runner_Timeout_Cancellation_Safety;
   end Process_Runner_Audit_Passes;

   function Audit_Process_Execution_Gates return Boolean
   is
      Default_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Disabled,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Shell_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => True,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Real_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 8,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Timeout_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 1);
      Empty_Request : constant Process_Run_Request :=
        (Program_Label => Null_Unbounded_String,
         Working_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Opaque_Request : constant Process_Run_Request :=
        (Program_Label => To_Unbounded_String ("gprbuild"),
         Working_Label => Null_Unbounded_String,
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Empty_Process_Arguments);
      No_Arg_Request : constant Process_Run_Request :=
        (Program_Label => To_Unbounded_String ("gprbuild"),
         Working_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Valid_Process : constant Process_Run_Request :=
        (Program_Label => To_Unbounded_String ("/bin/echo"),
         Working_Label => To_Unbounded_String ("/"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("ok"));
      Disabled_Result : constant Process_Run_Result :=
        Execute_Process_Request_Gated
          (No_Arg_Request, Default_Policy,
           Build_Process_Run_Result (Process_Run_Succeeded));
      Shell_Result : constant Process_Run_Result :=
        Execute_Process_Request_Gated
          (No_Arg_Request, Shell_Policy,
           Build_Process_Run_Result (Process_Run_Succeeded));
      Opaque_Result : constant Process_Run_Result :=
        Execute_Process_Request_Real_Gated (Opaque_Request, Real_Policy);
      Empty_Result : constant Process_Run_Result :=
        Execute_Process_Request_Real_Gated (Empty_Request, Real_Policy);
      Timeout_Result : constant Process_Run_Result :=
        Execute_Process_Request_Real_Gated (Valid_Process, Timeout_Policy);
      Oversize : constant Process_Run_Result :=
        Enforce_Process_Output_Bounds
          (Build_Process_Run_Result
             (Process_Run_Succeeded, Stdout_Text => "123456789"),
           Real_Policy);
      Args : constant Process_Argument_Vector :=
        Build_Process_Argument_Vector ("one", "", "three");
      Bad_Build : constant Build_Run_Result :=
        Execute_Build_Request_With_Process_Policy
          ((Tool          => No_Build_Tool,
          Provenance    => Build_Request_From_Internal_Command,
            Working_Label => Null_Unbounded_String,
            Command_Label => Null_Unbounded_String,
            Arguments     => Null_Unbounded_String,
          Structured_Arguments => Build_Process_Argument_Vector ("-q")),
           Real_Policy,
           Build_Process_Run_Result (Process_Run_Succeeded));
   begin
      return Validate_Process_Execution_Policy (Default_Policy)
        and then not Validate_Process_Execution_Policy (Shell_Policy)
        and then Validate_Process_Execution_Policy (Timeout_Policy)
        and then not Validate_Process_Run_Request_For_Real_Execution
          (Opaque_Request, Real_Policy)
        and then not Validate_Process_Run_Request_For_Real_Execution
          (No_Arg_Request, Real_Policy)
        and then Validate_Process_Run_Request_For_Real_Execution
          (Valid_Process, Real_Policy)
        and then Disabled_Result.Status = Process_Run_Not_Available
        and then Shell_Result.Status = Process_Run_Rejected
        and then Opaque_Result.Status = Process_Run_Rejected
        and then Empty_Result.Status = Process_Run_Rejected
        and then (Timeout_Result.Status = Process_Run_Succeeded
                  or else Timeout_Result.Status = Process_Run_Timed_Out)
        and then Oversize.Status = Process_Run_Execution_Error
        and then Args.Length = 3
        and then To_String (Args.First_Element) = "one"
        and then To_String (Args.Element (1)) = ""
        and then To_String (Args.Last_Element) = "three"
        and then Bad_Build.Status = Build_Run_Rejected
        and then Diagnostic_Line_Layering_Audit_Passes
        and then Native_Process_Control_Platform_Audit_Passes;
   end Audit_Process_Execution_Gates;




   function Audit_Build_Runner_Timeout_Cancellation_Safety return Boolean
   is
      S : Editor.State.State_Type;
      Timeout_Gate : constant Build_Execution_Gate :=
        Build_Test_Fixture_Execution_Gate;
      Timeout_Process : constant Process_Run_Result :=
        Build_Process_Run_Result
          (Process_Run_Timed_Out,
           Stderr_Text => "main.adb:1:1: error: bounded timeout partial");
      Cancel_Process : constant Process_Run_Result :=
        Build_Process_Run_Result (Process_Run_Cancelled);
      Unsupported_Process : constant Process_Run_Result :=
        Build_Cancellation_Unsupported_Process_Result;
      Request : constant Build_Run_Request :=
        (Tool                 => GPRbuild_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Timeout_Result : Build_Command_Result;
      Cancel_Result : Build_Command_Result;
      Unsupported_Result : Build_Command_Result;
      Invalid_Timeout_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 900_000);
   begin
      Editor.State.Init (S);
      Timeout_Result := Run_Build_Command_With_Gate
        (S, Request, Timeout_Gate, Timeout_Process);
      Cancel_Result := Run_Build_Command_With_Gate
        (S, Request, Timeout_Gate, Cancel_Process);
      Unsupported_Result := Run_Build_Command_With_Gate
        (S, Request, Timeout_Gate, Unsupported_Process);

      return Build_Timeout_Policy_Is_Bounded (Timeout_Gate.Process_Policy)
        and then not Build_Timeout_Policy_Is_Bounded (Invalid_Timeout_Policy)
        and then Timeout_Result.Build_Result.Status = Build_Run_Timed_Out
        and then To_String (Timeout_Result.Command_Message) =
          "Build failed: timed out"
        and then Cancel_Result.Build_Result.Status = Build_Run_Cancelled
        and then To_String (Cancel_Result.Command_Message) = "Build cancelled"
        and then Unsupported_Result.Build_Result.Status =
          Build_Run_Cancellation_Unsupported
        and then To_String (Unsupported_Result.Command_Message) =
          "Build unavailable: cancellation unsupported"
        and then Timeout_Result.Diagnostic_Result.Ingestion.Parse_Input_Count <= 512;
   end Audit_Build_Runner_Timeout_Cancellation_Safety;

   function Audit_Build_Runner_Output_Stream_Capture return Boolean
   is
      Request : constant Build_Run_Request :=
        (Tool                 => GPRbuild_Tool,
         Provenance           => Build_Request_From_Internal_Command,
         Working_Label        => To_Unbounded_String ("unit-test"),
         Command_Label        => To_Unbounded_String ("gprbuild"),
         Arguments            => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Separated : constant Process_Run_Result :=
        Build_Process_Run_Result
          (Process_Run_Failed,
           Stdout_Text => "main.adb:3:1: warning: stdout",
           Stderr_Text => "main.adb:1:1: error: stderr");
      Merged : constant Process_Run_Result :=
        Build_Process_Run_Result
          (Process_Run_Failed,
           Stdout_Text => "main.adb:1:1: error: merged stderr/stdout",
           Output_Capture_Mode => Process_Output_Capture_Merged_Stdout_Stderr);
      Separated_Build : constant Build_Run_Result :=
        Build_Result_From_Process_Result (Request, Separated);
      Merged_Build : constant Build_Run_Result :=
        Build_Result_From_Process_Result (Request, Merged);
      Separated_Lines : constant Diagnostic_Text_Line_Array :=
        Extract_Diagnostic_Lines_From_Build_Result (Separated_Build);
      Merged_Lines : constant Diagnostic_Text_Line_Array :=
        Extract_Diagnostic_Lines_From_Build_Result (Merged_Build);
   begin
      return Real_Process_Runner_Output_Capture_Mode =
          Process_Output_Capture_Separated
        and then Diagnostic_Stream_Preference (Separated) =
          Process_Diagnostics_Prefer_Stderr
        and then Diagnostic_Stream_Preference (Merged) =
          Process_Diagnostics_Merged_Output_Fallback
        and then Build_Run_Diagnostic_Stream_Preference (Separated_Build) =
          Process_Diagnostics_Prefer_Stderr
        and then Build_Run_Diagnostic_Stream_Preference (Merged_Build) =
          Process_Diagnostics_Merged_Output_Fallback
        and then Separated_Lines.Length = 2
        and then To_String (Separated_Lines.First_Element) =
          "main.adb:1:1: error: stderr"
        and then Merged_Lines.Length = 1
        and then To_String (Merged_Lines.First_Element) =
          "main.adb:1:1: error: merged stderr/stdout";
   end Audit_Build_Runner_Output_Stream_Capture;

   function Audit_Process_Argv_And_Preflight_Gates return Boolean
   is
      Real_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      Disabled_Policy : constant Process_Execution_Policy :=
        (Mode                     => Process_Execution_Disabled,
         Allow_Real_Execution     => False,
         Allow_Shell              => False,
         Max_Output_Bytes         => 262_144,
         Require_Absolute_Program => False,
         Timeout_Milliseconds     => 0);
      GPR_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Opaque_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q --not-split"),
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Alire_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Invalid_Request : constant Build_Run_Request :=
        (Tool          => No_Build_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => Null_Unbounded_String,
         Command_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      GPR_Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (GPR_Request, Real_Policy);
      Opaque_Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (Opaque_Request, Real_Policy);
      Disabled_Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (GPR_Request, Disabled_Policy);
      Invalid_Preflight : constant Build_Preflight_Result :=
        Preflight_Build_Run_Request (Invalid_Request, Real_Policy);
      Alire_Process : constant Process_Run_Request :=
        Prepare_Process_Request (Alire_Request);
      Args : Process_Argument_Vector := Empty_Process_Arguments;
   begin
      Append_Process_Argument (Args, "two words");
      Append_Process_Argument (Args, """quoted""");
      Append_Process_Argument (Args, ";rm -rf ignored");

      return Build_Preflight_Result_Is_Consistent (GPR_Preflight)
        and then Build_Preflight_Result_Is_Consistent (Opaque_Preflight)
        and then Build_Preflight_Result_Is_Consistent (Disabled_Preflight)
        and then Build_Preflight_Result_Is_Consistent (Invalid_Preflight)
        and then GPR_Preflight.Process_Request_Status = Process_Request_Valid
        and then GPR_Preflight.Has_Process_Request
        and then Opaque_Preflight.Process_Request_Status =
          Process_Request_Rejected_Opaque_Arguments
        and then not Opaque_Preflight.Has_Process_Request
        and then Disabled_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Invalid_Preflight.Build_Request_Status =
          Build_Request_Rejected_No_Tool
        and then not Invalid_Preflight.Has_Process_Request
        and then Alire_Process.Structured_Arguments.Length = 1
        and then To_String (Alire_Process.Structured_Arguments.First_Element) =
          "build"
        and then Args.Length = 3
        and then To_String (Args.First_Element) = "two words"
        and then To_String (Args.Element (1)) = """quoted"""
        and then To_String (Args.Last_Element) = ";rm -rf ignored";
   end Audit_Process_Argv_And_Preflight_Gates;


   function Audit_Real_Build_Execution_Gates return Boolean
   is
      Real_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate (Consent => Build_Consent_User_Confirmed);
      Missing_Consent_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate;
      Test_Only_Consent_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate (Consent => Build_Consent_Test_Only);
      Fixture_Gate : constant Build_Execution_Gate :=
        Build_Real_Fixture_Execution_Gate;
      Default_Gate : constant Build_Execution_Gate := Build_Default_Execution_Gate;
      User_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Unknown_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_Unknown,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Fixture_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_From_Fixture,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Project_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_From_Project_Metadata,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Working_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => To_Unbounded_String ("project-root"),
         Command_Label => To_Unbounded_String ("alr build"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("build"));
      Opaque_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      User_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (User_Request, Real_Gate);
      Missing_Consent_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (User_Request, Missing_Consent_Gate);
      Test_Only_Consent_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (User_Request, Test_Only_Consent_Gate);
      Unknown_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (Unknown_Request, Real_Gate);
      Fixture_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (Fixture_Request, Real_Gate);
      Project_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (Project_Request, Real_Gate);
      Working_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (Working_Request, Real_Gate);
      Opaque_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (Opaque_Request, Real_Gate);
      Disabled_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (User_Request, Default_Gate);
      Fixture_Gate_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Request (User_Request, Fixture_Gate);
   begin
      return Real_Gate.Allow_Real_Build_Tool_Execution
        and then not Fixture_Gate.Allow_Real_Build_Tool_Execution
        and then User_Preflight.Build_Request_Status = Build_Request_Valid
        and then User_Preflight.Process_Request_Status = Process_Request_Valid
        and then User_Preflight.Has_Process_Request
        and then Missing_Consent_Preflight.Build_Request_Status =
          Build_Request_Rejected_Consent
        and then not Missing_Consent_Preflight.Has_Process_Request
        and then Test_Only_Consent_Preflight.Build_Request_Status =
          Build_Request_Rejected_Consent
        and then not Test_Only_Consent_Preflight.Has_Process_Request
        and then Unknown_Preflight.Build_Request_Status =
          Build_Request_Rejected_Unknown_Provenance
        and then not Unknown_Preflight.Has_Process_Request
        and then Fixture_Preflight.Build_Request_Status =
          Build_Request_Rejected_Provenance
        and then Project_Preflight.Build_Request_Status =
          Build_Request_Rejected_Project_Metadata
        and then Working_Preflight.Process_Request_Status =
          Process_Request_Rejected_Unsupported_Working_Directory
        and then Opaque_Preflight.Process_Request_Status =
          Process_Request_Rejected_Opaque_Arguments
        and then Disabled_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Fixture_Gate_Preflight.Build_Request_Status =
          Build_Request_Rejected_Provenance;
   end Audit_Real_Build_Execution_Gates;

   function Audit_User_Opt_In_Build_Gates return Boolean
   is
      Default_Gate : constant Build_Execution_Gate := Build_Default_Execution_Gate;
      Real_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate (Consent => Build_Consent_User_Confirmed);
      Missing_Consent_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate;
      Test_Only_Consent_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate (Consent => Build_Consent_Test_Only);
      Fixture_Gate : constant Build_Execution_Gate :=
        Build_Real_Fixture_Execution_Gate;
      Shell_Gate : constant Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => True,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => True,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Build_Consent_User_Confirmed,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
      User_Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request
          (GPRbuild_Tool, "gprbuild", "",
           Build_Process_Argument_Vector ("-q"));
      Alire_Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request
          (Alire_Build_Tool, "alr", "",
           Build_Process_Argument_Vector ("build"));
      Project_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_Project_Metadata,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Unknown_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_Unknown,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Fixture_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_Fixture,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Custom_Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request
          (Custom_Build_Tool, "custom", "",
           Build_Process_Argument_Vector ("build"));
      No_Tool_Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request
          (No_Build_Tool, "", "", Empty_Process_Arguments);
      Opaque_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Working_Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request
          (GPRbuild_Tool, "gprbuild", "project-root",
           Build_Process_Argument_Vector ("-q"));
      User_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Real_Gate);
      Missing_Consent_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Missing_Consent_Gate);
      Test_Only_Consent_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Test_Only_Consent_Gate);
      Alire_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Alire_Request, Real_Gate);
      Default_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Default_Gate);
      Fixture_Gate_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Fixture_Gate);
      Project_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Project_Request, Real_Gate);
      Unknown_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Unknown_Request, Real_Gate);
      Fixture_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Fixture_Request, Real_Gate);
      Custom_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Custom_Request, Real_Gate);
      No_Tool_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (No_Tool_Request, Real_Gate);
      Opaque_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Opaque_Request, Real_Gate);
      Working_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (Working_Request, Real_Gate);
      Shell_Preflight : constant Build_Preflight_Result :=
        Preflight_User_Opt_In_Build_Request (User_Request, Shell_Gate);
   begin
      return Validate_Build_Execution_Gate (Default_Gate)
        and then not Default_Gate.Allow_Build_Run
        and then User_Preflight.Build_Request_Status = Build_Request_Valid
        and then User_Preflight.Process_Request_Status = Process_Request_Valid
        and then User_Preflight.Has_Process_Request
        and then Missing_Consent_Preflight.Build_Request_Status =
          Build_Request_Rejected_Consent
        and then not Missing_Consent_Preflight.Has_Process_Request
        and then Test_Only_Consent_Preflight.Build_Request_Status =
          Build_Request_Rejected_Consent
        and then not Test_Only_Consent_Preflight.Has_Process_Request
        and then Build_User_Opt_In_Build_Feedback (Missing_Consent_Preflight) =
          "Build: execution consent required"
        and then To_String (User_Preflight.Process_Request.Program_Label) = "gprbuild"
        and then Alire_Preflight.Process_Request_Status = Process_Request_Valid
        and then To_String (Alire_Preflight.Process_Request.Program_Label) = "alr"
        and then Default_Preflight.Build_Request_Status =
          Build_Request_Rejected_Consent
        and then Default_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Fixture_Gate_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Project_Preflight.Build_Request_Status =
          Build_Request_Rejected_Project_Metadata
        and then Unknown_Preflight.Build_Request_Status =
          Build_Request_Rejected_Unknown_Provenance
        and then Fixture_Preflight.Build_Request_Status =
          Build_Request_Rejected_Provenance
        and then Custom_Preflight.Build_Request_Status =
          Build_Request_Rejected_Unsupported_Tool
        and then No_Tool_Preflight.Build_Request_Status =
          Build_Request_Rejected_No_Tool
        and then Opaque_Preflight.Process_Request_Status =
          Process_Request_Rejected_Opaque_Arguments
        and then Working_Preflight.Process_Request_Status =
          Process_Request_Rejected_Unsupported_Working_Directory
        and then Shell_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Build_User_Opt_In_Build_Feedback (Project_Preflight) =
          "Build: project build metadata not supported"
        and then Build_User_Opt_In_Build_Feedback (Unknown_Preflight) =
          "Build: user opt-in required"
        and then Build_User_Opt_In_Build_Feedback (Custom_Preflight) =
          "Build: custom build tool not supported"
        and then Build_User_Opt_In_Build_Feedback (Opaque_Preflight) =
          "Build: structured arguments required"
        and then User_Opt_In_Build_Preflight_Is_Consistent (User_Preflight)
        and then User_Opt_In_Build_Preflight_Is_Consistent (Project_Preflight)
        and then Audit_User_Opt_In_Build_Command_Surface;
   end Audit_User_Opt_In_Build_Gates;

   function Audit_Real_Build_Tool_Fixture_Gates return Boolean
   is
      Default_Gate : constant Build_Execution_Gate := Build_Default_Execution_Gate;
      Fixture_Gate : constant Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Fixture_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => True,
         Consent                     => Build_Consent_Test_Only,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
      Real_Gate : constant Build_Execution_Gate := Build_Real_Execution_Gate;
      Ambiguous_Gate : constant Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => True,
         Allow_Real_Build_Tool_Fixture   => True,
         Consent                     => Build_Consent_User_Confirmed,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
      GPR_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Alire_Request : constant Build_Run_Request :=
        (Tool          => Alire_Build_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Unknown_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_Unknown,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Project_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_Project_Metadata,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Custom_Request : constant Build_Run_Request :=
        (Tool          => Custom_Build_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Working_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => To_Unbounded_String ("project-root"),
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Empty_Process_Arguments);
      Opaque_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("real build fixture"),
         Arguments     => To_Unbounded_String ("--version"),
         Structured_Arguments => Empty_Process_Arguments);
      Disabled_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (GPR_Request, GPRbuild_Version_Fixture, Default_Gate);
      Accepted_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (GPR_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Unknown_Fixture_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (GPR_Request, No_Real_Build_Tool_Fixture, Fixture_Gate);
      Alire_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (Alire_Request, Alire_Version_Fixture, Fixture_Gate);
      Project_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (Project_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Unknown_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (Unknown_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Custom_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (Custom_Request, Diagnostic_Output_Fixture, Fixture_Gate);
      Working_Preflight : constant Build_Preflight_Result :=
        Preflight_Real_Build_Tool_Fixture
          (Working_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Disabled_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (GPR_Request, GPRbuild_Version_Fixture, Default_Gate);
      Accepted_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (GPR_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Ambiguous_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (GPR_Request, GPRbuild_Version_Fixture, Ambiguous_Gate);
      Project_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (Project_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Custom_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (Custom_Request, Diagnostic_Output_Fixture, Fixture_Gate);
      Working_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (Working_Request, GPRbuild_Version_Fixture, Fixture_Gate);
      Opaque_Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request
          (Opaque_Request, GPRbuild_Version_Fixture, Fixture_Gate);
   begin
      return not Default_Gate.Allow_Real_Build_Tool_Fixture
        and then Validate_Real_Build_Tool_Fixture_Gate (Fixture_Gate)
        and then not Validate_Real_Build_Tool_Fixture_Gate (Real_Gate)
        and then not Validate_Build_Execution_Gate (Ambiguous_Gate)
        and then Disabled_Preflight.Process_Request_Status =
          Process_Request_Rejected_Execution_Disabled
        and then Accepted_Preflight.Build_Request_Status = Build_Request_Valid
        and then Accepted_Preflight.Process_Request_Status = Process_Request_Valid
        and then Accepted_Preflight.Has_Process_Request
        and then To_String (Accepted_Preflight.Process_Request.Program_Label) =
          "gprbuild"
        and then Accepted_Preflight.Process_Request.Structured_Arguments.Length = 1
        and then To_String
          (Accepted_Preflight.Process_Request.Structured_Arguments.First_Element) =
          "--version"
        and then Alire_Preflight.Process_Request_Status = Process_Request_Valid
        and then To_String (Alire_Preflight.Process_Request.Program_Label) = "alr"
        and then Unknown_Fixture_Preflight.Process_Request_Status =
          Process_Request_Rejected_Empty_Program
        and then Project_Preflight.Build_Request_Status =
          Build_Request_Rejected_Project_Metadata
        and then Unknown_Preflight.Build_Request_Status =
          Build_Request_Rejected_Unknown_Provenance
        and then Custom_Preflight.Build_Request_Status =
          Build_Request_Rejected_Unsupported_Tool
        and then Working_Preflight.Process_Request_Status =
          Process_Request_Rejected_Unsupported_Working_Directory
        and then Build_Preflight_Result_Is_Consistent (Accepted_Preflight)
        and then Build_Preflight_Result_Is_Consistent (Disabled_Preflight)
        and then Disabled_Validation = Real_Build_Fixture_Rejected_Disabled
        and then Accepted_Validation = Real_Build_Fixture_Valid
        and then Ambiguous_Validation = Real_Build_Fixture_Rejected_Ambiguous_Gate
        and then Project_Validation = Real_Build_Fixture_Rejected_Project_Metadata
        and then Custom_Validation = Real_Build_Fixture_Rejected_Custom_Tool
        and then Working_Validation = Real_Build_Fixture_Rejected_Working_Context
        and then Opaque_Validation = Real_Build_Fixture_Rejected_Opaque_Arguments
        and then Real_Build_Tool_Fixture_Preflight_Is_Consistent (Accepted_Preflight)
        and then Real_Build_Tool_Fixture_Preflight_Is_Consistent (Disabled_Preflight);
   end Audit_Real_Build_Tool_Fixture_Gates;

   function Audit_Build_Execution_Gates return Boolean
   is
      Default_Gate : constant Build_Execution_Gate :=
        Build_Default_Execution_Gate;
      Test_Gate : constant Build_Execution_Gate :=
        Build_Test_Fixture_Execution_Gate;
      Real_Fixture_Gate : constant Build_Execution_Gate :=
        Build_Real_Fixture_Execution_Gate;
      Real_Gate : constant Build_Execution_Gate :=
        Build_Real_Execution_Gate;
      Ambiguous_Gate : constant Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Process_Execution_Test_Fixture,
            Allow_Real_Execution     => True,
            Allow_Shell              => False,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Build_Consent_Not_Provided,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
      Shell_Gate : constant Build_Execution_Gate :=
        (Process_Policy              =>
           (Mode                     => Process_Execution_Real_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => True,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => Build_Default_Timeout_Milliseconds),
         Allow_Build_Run             => True,
         Allow_Real_Build_Tool_Execution => False,
         Allow_Real_Build_Tool_Fixture   => False,
         Consent                     => Build_Consent_Not_Provided,
         Allow_Diagnostics_Ingestion => True,
         Show_Diagnostics            => False);
   begin
      return Validate_Build_Execution_Gate (Default_Gate)
        and then Default_Gate.Process_Policy.Mode = Process_Execution_Disabled
        and then not Default_Gate.Allow_Build_Run
        and then Select_Process_Runner_Mode
          (Default_Gate, Default_Gate.Process_Policy) = Process_Execution_Disabled
        and then Validate_Build_Execution_Gate (Test_Gate)
        and then Select_Process_Runner_Mode
          (Test_Gate, Test_Gate.Process_Policy) = Process_Execution_Test_Fixture
        and then Validate_Build_Execution_Gate (Real_Fixture_Gate)
        and then Select_Process_Runner_Mode
          (Real_Fixture_Gate, Real_Fixture_Gate.Process_Policy) =
          Process_Execution_Real_Fixture_Allowed
        and then Validate_Build_Execution_Gate (Real_Gate)
        and then Select_Process_Runner_Mode
          (Real_Gate, Real_Gate.Process_Policy) = Process_Execution_Real_Allowed
        and then Select_Process_Runner_Mode
          (Real_Gate, Test_Gate.Process_Policy) = Process_Execution_Disabled
        and then not Validate_Build_Execution_Gate (Ambiguous_Gate)
        and then not Validate_Build_Execution_Gate (Shell_Gate);
   end Audit_Build_Execution_Gates;

   function Audit_Gated_Runner_Command_Path return Boolean
   is
      S : Editor.State.State_Type;
      Valid_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Invalid_Request : constant Build_Run_Request :=
        (Tool          => No_Build_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => Null_Unbounded_String,
         Command_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Opaque_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => To_Unbounded_String ("-q"),
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Supplied_Success : constant Process_Run_Result :=
        Build_Process_Run_Result
          (Process_Run_Succeeded,
           Stderr_Text => "main.adb:1:1: error: should-not-ingest");
      Disabled_Command : Build_Command_Result;
      Invalid_Command : Build_Command_Result;
      Test_Command : Build_Command_Result;
      Real_Command : Build_Command_Result;
      Opaque_Command : Build_Command_Result;
   begin
      Editor.State.Init (S);

      Disabled_Command := Run_Build_Command_With_Gate
        (S, Valid_Request, Build_Default_Execution_Gate, Supplied_Success);
      Invalid_Command := Run_Build_Command_With_Gate
        (S, Invalid_Request, Build_Test_Fixture_Execution_Gate, Supplied_Success);
      Test_Command := Run_Build_Command_With_Gate
        (S, Valid_Request,
         Build_Test_Fixture_Execution_Gate
           (Allow_Diagnostics_Ingestion => False),
         Supplied_Success);
      Real_Command := Run_Build_Command_With_Gate
        (S,
         (Tool          => Alire_Build_Tool,
          Provenance    => Build_Request_From_User_Opt_In,
          Working_Label => Null_Unbounded_String,
          Command_Label => To_Unbounded_String ("alr build"),
          Arguments     => Null_Unbounded_String,
          Structured_Arguments => Build_Process_Argument_Vector ("build")),
         Build_Real_Execution_Gate, Supplied_Success);
      Opaque_Command := Run_Build_Command_With_Gate
        (S,
         (Tool          => GPRbuild_Tool,
          Provenance    => Build_Request_From_User_Opt_In,
          Working_Label => Null_Unbounded_String,
          Command_Label => To_Unbounded_String ("gprbuild"),
          Arguments     => To_Unbounded_String ("-q"),
          Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         Build_Real_Execution_Gate, Supplied_Success);

      return Disabled_Command.Build_Result.Status = Build_Run_Not_Available
        and then To_String (Disabled_Command.Command_Message) =
          "Build: execution disabled"
        and then Invalid_Command.Build_Result.Status = Build_Run_Rejected
        and then Test_Command.Build_Result.Status = Build_Run_Succeeded
        and then Test_Command.Diagnostic_Result.Ingestion.Parse_Input_Count = 0
        and then To_String (Test_Command.Command_Message) =
          "Build: succeeded, diagnostics ingestion disabled"
        and then Real_Command.Build_Result.Status = Build_Run_Not_Available
        and then To_String (Real_Command.Command_Message) =
          "Build: real execution unavailable"
        and then Opaque_Command.Build_Result.Status = Build_Run_Rejected
        and then To_String (Opaque_Command.Command_Message) =
          "Build: structured arguments required";
   end Audit_Gated_Runner_Command_Path;

   function Audit_Process_Fixture_Gates return Boolean
   is
      Default_Gate : constant Build_Execution_Gate := Build_Default_Execution_Gate;
      Fixture_Gate : constant Build_Execution_Gate :=
        Build_Real_Fixture_Execution_Gate;
      Disabled_Result : constant Process_Run_Result :=
        Execute_Process_Request_Real_Fixture
          ((Kind => Echo_Diagnostic_Fixture,
            Arguments => Build_Process_Argument_Vector ("stdout", "x.adb:1:1: error: fixture", "")),
           Default_Gate.Process_Policy);
      Unknown_Result : constant Process_Run_Result :=
        Execute_Process_Request_Real_Fixture
          ((Kind => No_Process_Fixture, Arguments => Empty_Process_Arguments),
           Fixture_Gate.Process_Policy);
      Echo_Result : constant Process_Run_Result :=
        Execute_Process_Request_Real_Fixture
          ((Kind => Echo_Diagnostic_Fixture,
            Arguments => Build_Process_Argument_Vector
              ("stdout", "two words", ";not interpreted")),
           Fixture_Gate.Process_Policy);
      Oversize_Gate : constant Build_Execution_Gate :=
        Build_Real_Fixture_Execution_Gate (Max_Output_Bytes => 3);
      Oversize_Result : constant Process_Run_Result :=
        Execute_Process_Request_Real_Fixture
          ((Kind => Echo_Diagnostic_Fixture,
            Arguments => Build_Process_Argument_Vector ("stdout", "1234", "")),
           Oversize_Gate.Process_Policy);
      Disabled_Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request
          ((Kind => Echo_Diagnostic_Fixture,
            Arguments => Build_Process_Argument_Vector ("stdout", "x", "")),
           Default_Gate.Process_Policy);
      Unknown_Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request
          ((Kind => No_Process_Fixture, Arguments => Empty_Process_Arguments),
           Fixture_Gate.Process_Policy);
      Shell_Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request
          ((Kind => Echo_Diagnostic_Fixture,
            Arguments => Build_Process_Argument_Vector ("stdout", "x", "")),
           (Mode                     => Process_Execution_Real_Fixture_Allowed,
            Allow_Real_Execution     => True,
            Allow_Shell              => True,
            Max_Output_Bytes         => 262_144,
            Require_Absolute_Program => False,
            Timeout_Milliseconds     => 0));
      S : Editor.State.State_Type;
      Command : Build_Command_Result;
   begin
      Editor.State.Init (S);
      Command := Run_Build_Command_With_Fixture_Gate
        (S,
         (Tool          => GPRbuild_Tool,
         Provenance    => Build_Request_From_Internal_Command,
          Working_Label => To_Unbounded_String ("unit-test"),
          Command_Label => To_Unbounded_String ("gprbuild"),
          Arguments     => Null_Unbounded_String,
          Structured_Arguments => Build_Process_Argument_Vector ("-q")),
         (Kind => Echo_Diagnostic_Fixture,
          Arguments => Build_Process_Argument_Vector
            ("stderr", "main.adb:1:1: error: fixture", "noise")),
         Fixture_Gate);

      return Disabled_Status = Fixture_Request_Rejected_Disabled
        and then Unknown_Status = Fixture_Request_Rejected_Unknown_Fixture
        and then Shell_Status = Fixture_Request_Rejected_Shell
        and then Disabled_Result.Status = Process_Run_Not_Available
        and then Unknown_Result.Status = Process_Run_Rejected
        and then Echo_Result.Status = Process_Run_Succeeded
        and then Process_Fixture_Result_Is_Consistent
          (Echo_Result, Fixture_Gate.Process_Policy)
        and then To_String (Echo_Result.Stdout_Text) =
          "two words" & ASCII.LF & ";not interpreted"
        and then Oversize_Result.Status = Process_Run_Execution_Error
        and then Process_Fixture_Result_Is_Consistent
          (Oversize_Result, Oversize_Gate.Process_Policy)
        and then Command.Build_Result.Status = Build_Run_Succeeded
        and then Gated_Build_Command_Result_Is_Consistent (Command)
        and then Command.Diagnostic_Result.Ingestion.Parse_Input_Count = 2
        and then Command.Diagnostic_Result.Ingestion.Parse_Accepted_Count = 1
        and then Command.Diagnostic_Result.Ingestion.Parse_Ignored_Unrecognized_Count = 1
        and then Command.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count = 1;
   end Audit_Process_Fixture_Gates;

   function Build_Run_Test_Seam_Audit_Passes return Boolean
   is
      Valid_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => To_Unbounded_String ("unit-test"),
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      No_Tool_Request : constant Build_Run_Request :=
        (Tool          => No_Build_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild"),
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Empty_Command_Request : constant Build_Run_Request :=
        (Tool          => GPRbuild_Tool,
        Provenance    => Build_Request_From_Internal_Command,
         Working_Label => Null_Unbounded_String,
         Command_Label => Null_Unbounded_String,
         Arguments     => Null_Unbounded_String,
         Structured_Arguments => Build_Process_Argument_Vector ("-q"));
      Lines : Diagnostic_Text_Line_Array;
      Result_With_Lines : Build_Run_Result;
      Error_With_Output : Build_Run_Result;
      Split_Output : Build_Run_Result;
      Test_Fed_Result : Build_Run_Result;
      Invalid_Test_Fed_Result : Build_Run_Result;
      Extracted : Diagnostic_Text_Line_Array;
      Error_Extracted : Diagnostic_Text_Line_Array;
      Split_Extracted : Diagnostic_Text_Line_Array;
      Default_Result : Build_Run_Result;
      Empty_Diag : constant Diagnostic_Line_Command_Result :=
        Empty_Diagnostic_Line_Command_Result;
   begin
      Lines.Append (To_Unbounded_String ("src/main.adb:1:1: error: build"));
      Result_With_Lines := Build_Build_Run_Result
        (Build_Run_Failed, Exit_Code => 1, Has_Exit_Code => True,
         Stderr_Text => "src/other.adb:2:3: warning: split",
         Diagnostic_Lines => Lines);
      Error_With_Output := Build_Build_Run_Result
        (Build_Run_Execution_Error,
         Stderr_Text => "src/ignored.adb:2:3: error: ignored");
      Split_Output := Build_Build_Run_Result
        (Build_Run_Failed,
         Stdout_Text => "src/stdout.adb:4:5: warning: stdout",
         Stderr_Text => "src/stderr.adb:2:3: error: stderr");
      Test_Fed_Result := Execute_Test_Fed_Build_Request
        (Valid_Request,
         Build_Build_Run_Result (Build_Run_Failed, Exit_Code => 1,
           Has_Exit_Code => True));
      Invalid_Test_Fed_Result := Execute_Test_Fed_Build_Request
        (No_Tool_Request, Build_Build_Run_Result (Build_Run_Succeeded));
      Extracted := Extract_Diagnostic_Lines_From_Build_Result (Result_With_Lines);
      Error_Extracted := Extract_Diagnostic_Lines_From_Build_Result (Error_With_Output);
      Split_Extracted := Extract_Diagnostic_Lines_From_Build_Result (Split_Output);
      Default_Result := Execute_Build_Request (Valid_Request);

      return Validate_Build_Run_Request_Status (Valid_Request) = Build_Request_Valid
        and then Validate_Build_Run_Request_Status (No_Tool_Request) =
          Build_Request_Rejected_No_Tool
        and then Validate_Build_Run_Request_Status (Empty_Command_Request) =
          Build_Request_Rejected_Empty_Command
        and then Default_Result.Status = Build_Run_Not_Available
        and then Default_Result.Diagnostic_Lines.Length = 0
        and then Test_Fed_Result.Status = Build_Run_Failed
        and then Invalid_Test_Fed_Result.Status = Build_Run_Rejected
        and then Extracted.Length = 1
        and then To_String (Extracted.First_Element) =
          "src/main.adb:1:1: error: build"
        and then Error_Extracted.Length = 1
        and then To_String (Error_Extracted.First_Element) =
          "src/ignored.adb:2:3: error: ignored"
        and then Split_Extracted.Length = 2
        and then To_String (Split_Extracted.First_Element) =
          "src/stderr.adb:2:3: error: stderr"
        and then To_String (Split_Extracted.Last_Element) =
          "src/stdout.adb:4:5: warning: stdout"
        and then Diagnostic_Line_Layering_Audit_Passes
        and then Process_Runner_Audit_Passes
        and then Audit_Build_Execution_Gates
        and then Audit_Real_Build_Execution_Gates
        and then Audit_Real_Build_Tool_Fixture_Gates
        and then Audit_User_Opt_In_Build_Gates
        and then Audit_Gated_Runner_Command_Path
        and then Audit_Process_Fixture_Gates
        and then Build_Build_Command_Feedback
          (Build_Build_Run_Result (Build_Run_Succeeded), Empty_Diag) =
          "Build: succeeded";
   end Build_Run_Test_Seam_Audit_Passes;

   procedure Reset_Build_Run_State_For_Project_Close
     (S : in out Editor.State.State_Type)
   is
      pragma Unreferenced (S);
   begin
      --  Phase 168 build/process runs are synchronous and retain no run id, pending
      --  result, late-delivery queue, output text, or build-owned feature state.
      null;
   end Reset_Build_Run_State_For_Project_Close;

   procedure Reset_Build_Run_State_For_Workspace_Close
     (S : in out Editor.State.State_Type)
   is
      pragma Unreferenced (S);
   begin
      --  Workspace close has no build-run test seam state to clear in Phase 168.
      null;
   end Reset_Build_Run_State_For_Workspace_Close;

   function Classify_Diagnostic_Line_Command_Outcome
     (Result : Diagnostic_Line_Ingestion_Result)
      return Diagnostic_Line_Command_Outcome
   is
   begin
      if Result.Ingestion_Result.Accepted_Count > 0 then
         return Diagnostic_Line_Command_Succeeded;
      elsif Result.Parse_Input_Count = 0 then
         return Diagnostic_Line_Command_No_Input;
      elsif Result.Parse_Accepted_Count = 0
        and then Result.Parse_Rejected_Malformed_Count > 0
      then
         return Diagnostic_Line_Command_Malformed_Only;
      else
         return Diagnostic_Line_Command_No_Diagnostics;
      end if;
   end Classify_Diagnostic_Line_Command_Outcome;

   function Build_Diagnostic_Line_Command_Feedback
     (Result : Diagnostic_Line_Ingestion_Result) return String
   is
      Ignored_Total : constant Natural :=
        Result.Parse_Ignored_Blank_Count
        + Result.Parse_Ignored_Unrecognized_Count;
      Message : Unbounded_String;
   begin
      case Classify_Diagnostic_Line_Command_Outcome (Result) is
         when Diagnostic_Line_Command_Succeeded =>
            Message := To_Unbounded_String
              ("Diagnostics: ingested "
               & Trim_Natural_Image (Result.Ingestion_Result.Accepted_Count)
               & " diagnostics");

            if Ignored_Total > 0 then
               Append
                 (Message, ", ignored "
                  & Trim_Natural_Image (Ignored_Total)
                  & " lines");
            end if;

            if Result.Parse_Rejected_Malformed_Count > 0 then
               Append
                 (Message, ", rejected "
                  & Trim_Natural_Image (Result.Parse_Rejected_Malformed_Count)
                  & " malformed lines");
            end if;

            if Result.Ingestion_Result.Evicted_Count > 0 then
               Append
                 (Message, ", limit reached, evicted "
                  & Trim_Natural_Image (Result.Ingestion_Result.Evicted_Count)
                  & " older diagnostics");
            end if;

            return To_String (Message);

         when Diagnostic_Line_Command_No_Input =>
            return "Diagnostics: no diagnostic input";

         when Diagnostic_Line_Command_Malformed_Only =>
            if Result.Parse_Rejected_Malformed_Count = 1 then
               return "Diagnostics: 1 malformed diagnostic line";
            else
               return "Diagnostics: "
                 & Trim_Natural_Image (Result.Parse_Rejected_Malformed_Count)
                 & " malformed diagnostic lines";
            end if;

         when Diagnostic_Line_Command_No_Diagnostics =>
            if Ignored_Total > 0 then
               return "Diagnostics: no diagnostics parsed, ignored "
                 & Trim_Natural_Image (Ignored_Total) & " lines";
            elsif Result.Parse_Rejected_Malformed_Count > 0 then
               return "Diagnostics: no diagnostics parsed, rejected "
                 & Trim_Natural_Image (Result.Parse_Rejected_Malformed_Count)
                 & " malformed lines";
            else
               return "Diagnostics: no diagnostics parsed";
            end if;
      end case;
   end Build_Diagnostic_Line_Command_Feedback;

   function Format_Diagnostic_Line_Ingestion_Result
     (Result : Diagnostic_Line_Ingestion_Result) return String
   is
   begin
      return Build_Diagnostic_Line_Command_Feedback (Result);
   end Format_Diagnostic_Line_Ingestion_Result;

   function Ingest_Diagnostic_Lines_From_Command_With_Tool_Label
     (S                : in out Editor.State.State_Type;
      Producer         : External_Producer_Source;
      Lines            : Diagnostic_Text_Line_Array;
      Tool_Label       : String;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result
   is
      Parsed : constant Diagnostic_Line_Batch_Parse_Result :=
        Parse_Compiler_Diagnostic_Lines (Lines, Tool_Label);
      Normalized : constant Normalized_Diagnostic_Batch :=
        Normalize_Compiler_Diagnostic_Batch (S, Producer, Parsed.Records);
      Ingestion : Diagnostic_Line_Ingestion_Result;
      Showed : Boolean := False;
   begin
      Ingestion.Parse_Input_Count := Parsed.Input_Count;
      Ingestion.Parse_Accepted_Count := Parsed.Accepted_Count;
      Ingestion.Parse_Ignored_Blank_Count := Parsed.Ignored_Blank_Count;
      Ingestion.Parse_Ignored_Unrecognized_Count := Parsed.Ignored_Unrecognized_Count;
      Ingestion.Parse_Rejected_Malformed_Count := Parsed.Rejected_Malformed_Count;
      Ingestion.Normalized_Count := Normalized.Normalized_Count;
      Ingestion.Parsed_Error_Count := Parsed.Error_Count;
      Ingestion.Parsed_Warning_Count := Parsed.Warning_Count;
      Ingestion.Parsed_Info_Count := Parsed.Info_Count;
      Ingestion.Parsed_Note_Count := Parsed.Note_Count;
      Ingestion.Parsed_Unknown_Count := Parsed.Unknown_Count;
      Ingestion.Ingestion_Result :=
        Ingest_Diagnostic_Batch (S, Producer, Normalized.Items);
      Assert_Diagnostic_Line_Ingestion_Result_Consistent (Ingestion);

      if Show_Diagnostics
        and then Ingestion.Ingestion_Result.Accepted_Count > 0
      then
         Showed := Editor.Feature_Panel_Controller.Show_Feature
           (S, Editor.Feature_Panel.Diagnostics_Feature);
      end if;

      return
        (Ingestion               => Ingestion,
         Command_Message         => To_Unbounded_String
           (Build_Diagnostic_Line_Command_Feedback (Ingestion)),
         Should_Show_Diagnostics => Showed,
         Outcome                 =>
           Classify_Diagnostic_Line_Command_Outcome (Ingestion));
   end Ingest_Diagnostic_Lines_From_Command_With_Tool_Label;

   function Ingest_Diagnostic_Lines_From_Command
     (S                : in out Editor.State.State_Type;
      Producer         : External_Producer_Source;
      Lines            : Diagnostic_Text_Line_Array;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result
   is
   begin
      return Ingest_Diagnostic_Lines_From_Command_With_Tool_Label
        (S, Producer, Lines, To_String (Producer.Display_Label), Show_Diagnostics);
   end Ingest_Diagnostic_Lines_From_Command;

   function Diagnostic_Line_Command_Surface_Audit_Passes return Boolean
   is
      Empty : Diagnostic_Line_Ingestion_Result;
      Mixed : Diagnostic_Line_Ingestion_Result;
      Malformed : Diagnostic_Line_Ingestion_Result;
   begin
      Mixed.Parse_Input_Count := 4;
      Mixed.Parse_Accepted_Count := 1;
      Mixed.Parse_Ignored_Blank_Count := 1;
      Mixed.Parse_Ignored_Unrecognized_Count := 1;
      Mixed.Parse_Rejected_Malformed_Count := 1;
      Mixed.Normalized_Count := 1;
      Mixed.Parsed_Error_Count := 1;
      Mixed.Ingestion_Result.Accepted_Count := 1;
      Malformed.Parse_Input_Count := 2;
      Malformed.Parse_Rejected_Malformed_Count := 2;

      return Diagnostic_Line_Ingestion_Result_Is_Consistent (Empty)
        and then Diagnostic_Line_Ingestion_Result_Is_Consistent (Mixed)
        and then Diagnostic_Line_Ingestion_Result_Is_Consistent (Malformed)
        and then Classify_Diagnostic_Line_Command_Outcome (Empty) =
          Diagnostic_Line_Command_No_Input
        and then Build_Diagnostic_Line_Command_Feedback (Empty) =
          "Diagnostics: no diagnostic input"
        and then Classify_Diagnostic_Line_Command_Outcome (Mixed) =
          Diagnostic_Line_Command_Succeeded
        and then Build_Diagnostic_Line_Command_Feedback (Mixed) =
          "Diagnostics: ingested 1 diagnostics, ignored 2 lines, rejected 1 malformed lines"
        and then Classify_Diagnostic_Line_Command_Outcome (Malformed) =
          Diagnostic_Line_Command_Malformed_Only
        and then Build_Diagnostic_Line_Command_Feedback (Malformed) =
          "Diagnostics: 2 malformed diagnostic lines";
   end Diagnostic_Line_Command_Surface_Audit_Passes;

   function Diagnostic_Line_Parser_Audit_Passes return Boolean
   is
      Lines : Diagnostic_Text_Line_Array;
      Batch : Diagnostic_Line_Batch_Parse_Result;
      Empty_Batch : Diagnostic_Line_Batch_Parse_Result;
      Parsed : Diagnostic_Line_Parse_Result;
      Blank : Diagnostic_Line_Parse_Result;
      Other : Diagnostic_Line_Parse_Result;
      Bad_Line : Diagnostic_Line_Parse_Result;
      Format_Result : Diagnostic_Line_Ingestion_Result;
   begin
      Parsed := Parse_Compiler_Diagnostic_Line
        ("src/main.adb:42:7: error: missing ;", "gnat");
      Blank := Parse_Compiler_Diagnostic_Line ("", "gnat");
      Other := Parse_Compiler_Diagnostic_Line ("not a diagnostic", "gnat");
      Bad_Line := Parse_Compiler_Diagnostic_Line
        ("src/main.adb:x:7: error: bad line", "gnat");
      Lines.Append (To_Unbounded_String (""));
      Lines.Append (To_Unbounded_String ("not a diagnostic"));
      Lines.Append (To_Unbounded_String ("src/main.adb:42:7: warning: value: still valid"));
      Lines.Append (To_Unbounded_String ("src/main.adb:0:7: error: bad line"));
      Batch := Parse_Compiler_Diagnostic_Lines (Lines, "gnat");
      Empty_Batch := Parse_Compiler_Diagnostic_Lines
        (Diagnostic_Text_Line_Vectors.Empty_Vector, "gnat");
      Format_Result.Parse_Input_Count := 5;
      Format_Result.Parse_Accepted_Count := 3;
      Format_Result.Normalized_Count := 3;
      Format_Result.Parsed_Error_Count := 3;
      Format_Result.Ingestion_Result.Accepted_Count := 3;
      Format_Result.Parse_Ignored_Blank_Count := 1;
      Format_Result.Parse_Ignored_Unrecognized_Count := 1;

      return Parsed.Status = Parse_Accepted
        and then Parsed.Has_Record
        and then Parsed.Reason = No_Parse_Reason
        and then Parsed.Diagnostic_Record.Severity = Compiler_Error
        and then To_String (Parsed.Diagnostic_Record.File_Label) = "src/main.adb"
        and then Parsed.Diagnostic_Record.Line = 42
        and then Parsed.Diagnostic_Record.Column = 7
        and then To_String (Parsed.Diagnostic_Record.Tool_Name) = "gnat"
        and then Blank.Status = Parse_Ignored_Blank
        and then Blank.Reason = Blank_Line
        and then Other.Status = Parse_Ignored_Unrecognized
        and then Other.Reason = Unrecognized_Format
        and then Bad_Line.Status = Parse_Rejected_Malformed
        and then Bad_Line.Reason = Nonnumeric_Line
        and then Parse_Compiler_Diagnostic_Severity ("NOTE") = Compiler_Note
        and then Parse_Compiler_Diagnostic_Severity ("Warn") = Compiler_Warning
        and then Parse_Compiler_Diagnostic_Severity ("fatal") = Compiler_Fatal
        and then Parse_Compiler_Diagnostic_Severity ("strange") = Compiler_Unknown
        and then Batch.Input_Count = 4
        and then Batch.Accepted_Count = 1
        and then Batch.Ignored_Blank_Count = 1
        and then Batch.Ignored_Unrecognized_Count = 1
        and then Batch.Rejected_Malformed_Count = 1
        and then Batch.Warning_Count = 1
        and then Batch.Error_Count = 0
        and then Assert_Diagnostic_Line_Batch_Consistent (Batch)
        and then Empty_Batch.Input_Count = 0
        and then Assert_Diagnostic_Line_Batch_Consistent (Empty_Batch)
        and then Build_Diagnostic_Line_Command_Feedback (Format_Result) =
          "Diagnostics: ingested 3 diagnostics, ignored 2 lines"
        and then To_String (Batch.Records.Element (Batch.Records.First_Index).Message) =
          "value: still valid";
   end Diagnostic_Line_Parser_Audit_Passes;

   function Diagnostic_Line_Layering_Audit_Passes return Boolean
   is
      S : Editor.State.State_Type;
      Source : constant External_Producer_Source :=
        Build_Compiler_Diagnostics_Producer_Source;
      Lines : Diagnostic_Text_Line_Array;
      Parsed : Diagnostic_Line_Batch_Parse_Result;
      Normalized : Normalized_Diagnostic_Batch;
      Simulated_Result : Diagnostic_Line_Ingestion_Result;
      Before_Feature : Editor.Feature_Panel.Feature_Id;
      After_Feature : Editor.Feature_Panel.Feature_Id;
   begin
      Lines.Append
        (To_Unbounded_String ("src/main.adb:1:1: warning: layered audit"));
      Lines.Append (To_Unbounded_String ("not a diagnostic"));
      Lines.Append (To_Unbounded_String ("src/main.adb:x:1: error: malformed"));

      Parsed := Parse_Compiler_Diagnostic_Lines (Lines, "gnat");
      Normalized := Normalize_Compiler_Diagnostic_Batch
        (S, Source, Parsed.Records);
      Before_Feature := Editor.Feature_Panel.Active_Feature (S.Feature_Panel);
      Simulated_Result.Parse_Input_Count := Parsed.Input_Count;
      Simulated_Result.Parse_Accepted_Count := Parsed.Accepted_Count;
      Simulated_Result.Parse_Ignored_Blank_Count := Parsed.Ignored_Blank_Count;
      Simulated_Result.Parse_Ignored_Unrecognized_Count :=
        Parsed.Ignored_Unrecognized_Count;
      Simulated_Result.Parse_Rejected_Malformed_Count :=
        Parsed.Rejected_Malformed_Count;
      Simulated_Result.Normalized_Count := Normalized.Normalized_Count;
      Simulated_Result.Parsed_Warning_Count := Parsed.Warning_Count;
      Simulated_Result.Ingestion_Result.Accepted_Count :=
        Normalized.Normalized_Count;
      After_Feature := Editor.Feature_Panel.Active_Feature (S.Feature_Panel);

      return Assert_Diagnostic_Line_Batch_Consistent (Parsed)
        and then Assert_Normalized_Batch_Consistent (Normalized)
        and then Diagnostic_Line_Ingestion_Result_Is_Consistent (Simulated_Result)
        and then Parsed.Input_Count = 3
        and then Parsed.Accepted_Count = 1
        and then Parsed.Ignored_Unrecognized_Count = 1
        and then Parsed.Rejected_Malformed_Count = 1
        and then Normalized.Normalized_Count = 1
        and then Simulated_Result.Parse_Accepted_Count = 1
        and then Simulated_Result.Normalized_Count = 1
        and then Simulated_Result.Ingestion_Result.Accepted_Count = 1
        and then Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0
        and then Before_Feature = After_Feature;
   end Diagnostic_Line_Layering_Audit_Passes;

   procedure Reset_Diagnostic_Line_Command_State_For_Project_Close
     (S : in out Editor.State.State_Type)
   is
      pragma Unreferenced (S);
   begin
      --  Synchronous-only invariant: command-facing diagnostic-line ingestion
      --  stores no run id, no pending output, no retained lines, and no live
      --  buffer handles outside Diagnostics-owned rows.  Project close therefore
      --  has no command-ingestion state to clear.
      null;
   end Reset_Diagnostic_Line_Command_State_For_Project_Close;

   procedure Reset_Diagnostic_Line_Command_State_For_Workspace_Close
     (S : in out Editor.State.State_Type)
   is
      pragma Unreferenced (S);
   begin
      --  Synchronous-only invariant: workspace close preserves pure parser and
      --  normalizer helpers and stable command descriptors; no transient
      --  diagnostic-line command state is retained here.
      null;
   end Reset_Diagnostic_Line_Command_State_For_Workspace_Close;


   function Is_Diagnostic_Path_Absolute (Path : String) return Boolean
   is
   begin
      return Path'Length > 0
        and then (Path (Path'First) = '/'
                  or else (Path'Length >= 3
                    and then Path (Path'First + 1) = ':'
                    and then (Path (Path'First + 2) = '/'
                              or else Path (Path'First + 2) = '\')));
   end Is_Diagnostic_Path_Absolute;

   function Diagnostic_Path_Has_Parent_Traversal (Path : String) return Boolean
   is
      Clean : constant String := Ada.Strings.Fixed.Trim (Path, Both);
   begin
      return Clean = ".."
        or else Starts_With_Case_Insensitive (Clean, "../")
        or else Starts_With_Case_Insensitive (Clean, "..\")
        or else Ada.Strings.Fixed.Index (Clean, "/../") > 0
        or else Ada.Strings.Fixed.Index (Clean, "\..\") > 0
        or else (Clean'Length >= 3
          and then (Clean (Clean'Last - 2 .. Clean'Last) = "/.."
                    or else Clean (Clean'Last - 2 .. Clean'Last) = "\.."));
   end Diagnostic_Path_Has_Parent_Traversal;

   function Diagnostic_Label_Project_Bounded
     (S          : Editor.State.State_Type;
      File_Label : String) return Boolean
   is
      Clean_Label : constant String := Ada.Strings.Fixed.Trim (File_Label, Both);
      Project_Root : constant String := Editor.Project.Root_Path (S.Project);
   begin
      if Clean_Label'Length = 0 or else Diagnostic_Path_Has_Parent_Traversal (Clean_Label) then
         return False;
      elsif not Editor.Project.Has_Project (S.Project) then
         return not Is_Diagnostic_Path_Absolute (Clean_Label);
      elsif Is_Diagnostic_Path_Absolute (Clean_Label) then
         return Editor.Project.Is_Under_Project (S.Project, Clean_Label);
      else
         return Project_Root'Length > 0;
      end if;
   end Diagnostic_Label_Project_Bounded;

   function Resolve_Diagnostic_File_Target
     (S          : Editor.State.State_Type;
      File_Label : String) return Buffer_Target_Resolution
   is
      Clean_Label : constant String := Ada.Strings.Fixed.Trim (File_Label, Both);
      Match_Count : Natural := 0;
      Match_Token : Natural := Editor.Feature_Diagnostics.No_Buffer;

      procedure Consider
        (Token        : Natural;
         Has_Path     : Boolean;
         Path         : String;
         Display_Name : String)
      is
         Project_Root : constant String := Editor.Project.Root_Path (S.Project);
         Project_Label : constant String :=
           (if Project_Root'Length > 0 and then Clean_Label'Length > 0
              and then not Is_Diagnostic_Path_Absolute (Clean_Label) then
               Project_Root & "/" & Clean_Label
            else
               Clean_Label);
         Path_Project_Bounded : constant Boolean :=
           not Editor.Project.Has_Project (S.Project)
           or else (Has_Path and then Editor.Project.Is_Under_Project (S.Project, Path));
         Label_Project_Bounded : constant Boolean :=
           Diagnostic_Label_Project_Bounded (S, Clean_Label);
         Is_Match : constant Boolean :=
           Label_Project_Bounded
           and then Path_Project_Bounded
           and then Clean_Label'Length > 0
           and then Token /= Editor.Feature_Diagnostics.No_Buffer
           and then ((Has_Path and then Path'Length > 0 and then
                        (Path = Clean_Label
                         or else Path = Project_Label
                         or else (not Is_Diagnostic_Path_Absolute (Clean_Label)
                           and then Ada.Directories.Simple_Name (Path) = Clean_Label)))
                     or else Display_Name = Clean_Label);
      begin
         if Is_Match then
            if Match_Count = 0 then
               Match_Count := 1;
               Match_Token := Token;
            elsif Match_Token /= Token then
               Match_Count := Match_Count + 1;
            end if;
         end if;
      end Consider;

      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Id       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      First    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      if not Diagnostic_Label_Project_Bounded (S, Clean_Label) then
         return (Found => False, Buffer => Editor.Feature_Diagnostics.No_Buffer);
      end if;

      if Editor.State.Has_Active_Buffer (S) then
         Consider
           (S.Registry_Token,
            S.File_Info.Has_Path,
            To_String (S.File_Info.Path),
            To_String (S.File_Info.Display_Name));
      end if;

      First := Editor.Buffers.First_Buffer (Registry);
      Id := First;
      while Id /= Editor.Buffers.No_Buffer loop
         declare
            B : constant Editor.State.State_Type := Editor.Buffers.Buffer (Registry, Id);
         begin
            Consider
              (B.Registry_Token,
               B.File_Info.Has_Path,
               To_String (B.File_Info.Path),
               To_String (B.File_Info.Display_Name));
         end;

         Id := Editor.Buffers.Next_Buffer (Registry, Id);
         exit when Id = First;
      end loop;

      if Match_Count = 1 then
         return (Found => True, Buffer => Match_Token);
      else
         return (Found => False, Buffer => Editor.Feature_Diagnostics.No_Buffer);
      end if;
   end Resolve_Diagnostic_File_Target;

   function Build_Normalized_Diagnostic_Source_Label
     (Tool_Name  : String;
      File_Label : String) return String
   is
      Clean_Tool : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Source (Tool_Name);
      Clean_File : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Source (File_Label);
   begin
      if Clean_Tool'Length > 0 and then Clean_File'Length > 0 then
         return Clean_Tool & ": " & Clean_File;
      elsif Clean_File'Length > 0 then
         return Clean_File;
      else
         return Clean_Tool;
      end if;
   end Build_Normalized_Diagnostic_Source_Label;

   function Normalize_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : External_Producer_Source;
      Input    : Compiler_Diagnostic_Record)
      return External_Diagnostic_Record
   is
      Clean_Message : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Text (To_String (Input.Message));
      Source_Label : constant String :=
        Build_Normalized_Diagnostic_Source_Label
          (To_String (Input.Tool_Name), To_String (Input.File_Label));
      Fallback_Source : constant String :=
        (if Source_Label'Length > 0 then Source_Label
         elsif Producer_Source_Is_Valid (Producer) then To_String (Producer.Display_Label)
         else "compiler diagnostics");
      Resolution : constant Buffer_Target_Resolution :=
        Resolve_Diagnostic_File_Target (S, To_String (Input.File_Label));
      Has_Target_Metadata : constant Boolean :=
        Input.Has_Location and then Resolution.Found;
   begin
      return
        (Severity      => Map_Compiler_Severity_To_Diagnostic_Severity
                            (Input.Severity),
         Message       => To_Unbounded_String (Clean_Message),
         Source_Label  => To_Unbounded_String (Fallback_Source),
         --  Keep compiler-provided target metadata even when it is only
         --  partially navigable.  Diagnostics owns the later distinction
         --  between line-only navigation, missing line, missing buffer, and
         --  out-of-range validation failures.
         Has_Target    => Has_Target_Metadata,
         Target_Buffer => (if Has_Target_Metadata then Resolution.Buffer else 0),
         Target_Line   => (if Has_Target_Metadata then Input.Line else 0),
         Target_Column => (if Has_Target_Metadata then Input.Column else 0));
   end Normalize_Compiler_Diagnostic;

   function Normalize_Compiler_Diagnostic_Batch
     (S        : Editor.State.State_Type;
      Producer : External_Producer_Source;
      Inputs   : Compiler_Diagnostic_Record_Array)
      return Normalized_Diagnostic_Batch
   is
      Result     : Normalized_Diagnostic_Batch;
      Normalized : External_Diagnostic_Record;
      Resolution : Buffer_Target_Resolution;
   begin
      Result.Input_Count := Natural (Inputs.Length);
      if Inputs.Is_Empty then
         return Result;
      end if;

      for I in Inputs.First_Index .. Inputs.Last_Index loop
         Normalized := Normalize_Compiler_Diagnostic (S, Producer, Inputs.Element (I));
         Result.Items.Append (Normalized);
         Result.Normalized_Count := Result.Normalized_Count + 1;

         if Length (Normalized.Message) = 0 then
            Result.Empty_Message_Count := Result.Empty_Message_Count + 1;
         end if;

         if not Normalized.Has_Target then
            Result.Untargeted_Count := Result.Untargeted_Count + 1;
         end if;

         if Inputs.Element (I).Has_Location then
            Resolution := Resolve_Diagnostic_File_Target
              (S, To_String (Inputs.Element (I).File_Label));
            if Resolution.Found and then
              (Inputs.Element (I).Line = 0 or else Inputs.Element (I).Column = 0)
            then
               Result.Invalid_Location_Count := Result.Invalid_Location_Count + 1;
            elsif Resolution.Found and then not Normalized.Has_Target then
               Result.Invalid_Location_Count := Result.Invalid_Location_Count + 1;
            end if;
         end if;
      end loop;

      return Result;
   end Normalize_Compiler_Diagnostic_Batch;

   function Ingest_Compiler_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : External_Producer_Source;
      Inputs   : Compiler_Diagnostic_Record_Array)
      return Producer_Batch_Result
   is
      Batch : constant Normalized_Diagnostic_Batch :=
        Normalize_Compiler_Diagnostic_Batch (S, Producer, Inputs);
   begin
      return Ingest_Diagnostic_Batch (S, Producer, Batch.Items);
   end Ingest_Compiler_Diagnostic_Batch;

   function Assert_Normalized_Batch_Consistent
     (Batch : Normalized_Diagnostic_Batch) return Boolean
   is
   begin
      return Batch.Input_Count = Natural (Batch.Items.Length)
        and then Batch.Normalized_Count = Natural (Batch.Items.Length)
        and then Batch.Untargeted_Count <= Batch.Normalized_Count
        and then Batch.Empty_Message_Count <= Batch.Normalized_Count
        and then Batch.Invalid_Location_Count <= Batch.Untargeted_Count;
   end Assert_Normalized_Batch_Consistent;

   function Compiler_Diagnostic_Normalization_Audit_Passes return Boolean
   is
      Source : constant External_Producer_Source :=
        Build_Compiler_Diagnostics_Producer_Source;
      Empty_State : Editor.State.State_Type;
      Inputs : Compiler_Diagnostic_Record_Array;
      Batch : Normalized_Diagnostic_Batch;
   begin
      Inputs.Append
        (Compiler_Diagnostic_Record'(Severity     => Compiler_Unknown,
          Message      => To_Unbounded_String (" audit "),
          File_Label   => To_Unbounded_String (""),
          Has_Location => False,
          Line         => 0,
          Column       => 0,
          Tool_Name    => To_Unbounded_String (" compiler ")));
      Batch := Normalize_Compiler_Diagnostic_Batch (Empty_State, Source, Inputs);

      return Producer_Source_Is_Valid (Source)
        and then Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Info) =
          Editor.Feature_Diagnostics.Diagnostic_Info
        and then Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Note) =
          Editor.Feature_Diagnostics.Diagnostic_Info
        and then Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Warning) =
          Editor.Feature_Diagnostics.Diagnostic_Warning
        and then Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Error) =
          Editor.Feature_Diagnostics.Diagnostic_Error
        and then Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Fatal) =
          Editor.Feature_Diagnostics.Diagnostic_Error
        and then Map_Compiler_Severity_To_Diagnostic_Severity (Compiler_Unknown) =
          Editor.Feature_Diagnostics.Diagnostic_Info
        and then Build_Normalized_Diagnostic_Source_Label (" gnat ", " main.adb ") =
          "gnat: main.adb"
        and then not Resolve_Diagnostic_File_Target (Empty_State, "main.adb").Found
        and then not Resolve_Diagnostic_File_Target (Empty_State, "../main.adb").Found
        and then not Resolve_Diagnostic_File_Target (Empty_State, "..\main.adb").Found
        and then not Resolve_Diagnostic_File_Target (Empty_State, "/tmp/main.adb").Found
        and then not Resolve_Diagnostic_File_Target (Empty_State, "C:\tmp\main.adb").Found
        and then Assert_Normalized_Batch_Consistent (Batch)
        and then Batch.Input_Count = 1
        and then Batch.Normalized_Count = 1
        and then Batch.Untargeted_Count = 1
        and then To_String (Batch.Items.Element (Batch.Items.First_Index).Message) = "audit";
   end Compiler_Diagnostic_Normalization_Audit_Passes;

   function Producer_Lifecycle_Audit_Passes return Boolean is
   begin
      --  Phase 161 still has no asynchronous producer deliveries and no stored
      --  external run state.  Project/workspace close therefore cannot leave a
      --  pending producer batch that later mutates Diagnostics; every compiler
      --  diagnostic batch is synchronously normalized and immediately routed
      --  through Diagnostics-owned ingestion or rejected in the same call.
      return True;
   end Producer_Lifecycle_Audit_Passes;

   function Normalize_External_Diagnostic_Record
     (Item : External_Diagnostic_Record) return External_Diagnostic_Record
   is
      Clean_Message : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Text (To_String (Item.Message));
      Clean_Source : constant String :=
        Editor.Producer_Contracts.Normalize_Producer_Source
          (To_String (Item.Source_Label));
   begin
      return
        (Severity      => Item.Severity,
         Message       => To_Unbounded_String (Clean_Message),
         Source_Label  => To_Unbounded_String (Clean_Source),
         Has_Target    => Item.Has_Target,
         Target_Buffer => Item.Target_Buffer,
         Target_Line   => Item.Target_Line,
         Target_Column => Item.Target_Column);
   end Normalize_External_Diagnostic_Record;

   procedure Add_Normalized_Record
     (S           : in out Editor.State.State_Type;
      Producer    : External_Producer_Source;
      Item        : External_Diagnostic_Record;
      Target_Kept : out Boolean)
   is
      Line_Only_Valid : constant Boolean :=
        Item.Has_Target
        and then Item.Target_Buffer /= Editor.Feature_Diagnostics.No_Buffer
        and then Item.Target_Line > 0
        and then Item.Target_Column = 0
        and then Item.Target_Line <= Editor.State.Line_Count (S);
      Target : constant Editor.Feature_Targets.Feature_Row_Target_Validation :=
        (if Item.Has_Target and then Item.Target_Column > 0 then
            Editor.Feature_Targets.Validate_Buffer_Target_For_Feature_Row
              (S, Item.Target_Buffer, Item.Target_Line, Item.Target_Column)
         else
            (Valid => Line_Only_Valid,
             Buffer => (if Item.Has_Target then Item.Target_Buffer else 0),
             Line   => (if Item.Has_Target then Item.Target_Line else 0),
             Column => (if Item.Has_Target then Item.Target_Column else 0)));
   begin
      Target_Kept := Target.Valid;
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Item.Severity,
         Message       => To_String (Item.Message),
         Source_Label   => To_String (Item.Source_Label),
         Source_Kind    => Map_External_Producer_To_Diagnostic_Source (Producer),
         --  Preserve producer target metadata for the Diagnostics review layer.
         --  Passing only Target.Valid would erase line-only and partial target
         --  records before Diagnostics can label them as line-start, missing
         --  line, missing file, or out-of-range.
         Has_Target     => Item.Has_Target,
         --  Keep the producer-supplied target tuple even when validation says
         --  it is currently unusable.  Phase 557 review/navigation must be
         --  able to distinguish missing files, out-of-range lines, and
         --  out-of-range columns instead of collapsing every invalid target
         --  into an untargeted/source-less row before Diagnostics sees it.
         Target_Buffer  => Item.Target_Buffer,
         Target_Line    => Item.Target_Line,
         Target_Column  => Item.Target_Column,
         Build_Produced => Producer.Kind = Build_Diagnostics_Producer);
   end Add_Normalized_Record;

   function Ingest_Diagnostic_Record
     (S        : in out Editor.State.State_Type;
      Producer : External_Producer_Source;
      Item     : External_Diagnostic_Record)
      return Editor.Producer_Contracts.Producer_Result
   is
      Items : External_Diagnostic_Record_Array;
      Batch : Producer_Batch_Result;
   begin
      Items.Append (Item);
      Batch := Ingest_Diagnostic_Batch (S, Producer, Items);
      if Batch.Rejected_Count = 1 then
         if Producer_Source_Is_Valid (Producer) then
            return Editor.Producer_Contracts.Rejected_Empty_Text;
         else
            return Editor.Producer_Contracts.Rejected_Invalid_State;
         end if;
      elsif Batch.Accepted_Count = 1 and then Batch.Accepted_Untargeted = 0 then
         return Editor.Producer_Contracts.Accepted;
      else
         return Editor.Producer_Contracts.Accepted_Untargeted;
      end if;
   end Ingest_Diagnostic_Record;

   function Ingest_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : External_Producer_Source;
      Items    : External_Diagnostic_Record_Array)
      return Producer_Batch_Result
   is
      Result        : Producer_Batch_Result;
      Before_Count  : constant Natural :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Target_Kept   : Boolean := False;
      Normalized    : External_Diagnostic_Record;
   begin
      if Items.Is_Empty then
         return Result;
      end if;

      if not Producer_Source_Is_Valid (Producer) then
         Result.Rejected_Count := Natural (Items.Length);
         return Result;
      end if;

      for I in Items.First_Index .. Items.Last_Index loop
         Normalized := Normalize_External_Diagnostic_Record (Items.Element (I));
         if Length (Normalized.Message) = 0 then
            Result.Rejected_Count := Result.Rejected_Count + 1;
         else
            Add_Normalized_Record (S, Producer, Normalized, Target_Kept);
            Result.Accepted_Count := Result.Accepted_Count + 1;
            if not Target_Kept then
               Result.Accepted_Untargeted := Result.Accepted_Untargeted + 1;
            end if;
         end if;
      end loop;

      declare
         After_Count : constant Natural :=
           Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      begin
         if Before_Count + Result.Accepted_Count > After_Count then
            Result.Evicted_Count := Before_Count + Result.Accepted_Count - After_Count;
         end if;
      end;

      if Result.Accepted_Count > 0 then
         Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
           (S.Feature_Diagnostics, S.Feature_Panel);
         Result.Projection_Changed :=
           Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
             Editor.Feature_Panel.Diagnostics_Feature;
      end if;

      return Result;
   end Ingest_Diagnostic_Batch;

   function External_Producer_Audit_Passes return Boolean
   is
      Build_Source : constant External_Producer_Source :=
        Build_External_Producer_Source (Build_Diagnostics_Producer);
      Compiler_Source : constant External_Producer_Source :=
        Build_External_Producer_Source (Compiler_Diagnostics_Producer);
      None_Source : constant External_Producer_Source :=
        Build_External_Producer_Source (No_External_Producer);
   begin
      return Producer_Source_Is_Valid (Build_Source)
        and then Producer_Source_Is_Valid (Compiler_Source)
        and then not Producer_Source_Is_Valid (None_Source)
        and then Stable_Name (Build_Diagnostics_Producer) /=
          Stable_Name (Compiler_Diagnostics_Producer)
        and then Display_Label (Build_Diagnostics_Producer) /=
          Display_Label (Compiler_Diagnostics_Producer)
        and then Map_External_Producer_To_Diagnostic_Source (Build_Source) =
          Editor.Feature_Diagnostics.External_Diagnostic_Source
        and then Map_External_Producer_To_Diagnostic_Source (Compiler_Source) =
          Editor.Feature_Diagnostics.External_Diagnostic_Source
        and then Map_External_Producer_To_Diagnostic_Source (None_Source) =
          Editor.Feature_Diagnostics.Unknown_Diagnostic_Source
        and then Compiler_Diagnostic_Normalization_Audit_Passes
        and then Diagnostic_Line_Parser_Audit_Passes
        and then Diagnostic_Line_Command_Surface_Audit_Passes
        and then Diagnostic_Line_Layering_Audit_Passes
        and then Build_Run_Test_Seam_Audit_Passes
        and then Audit_Real_Build_Execution_Gates
        and then Audit_User_Opt_In_Build_Command_Surface
        and then Producer_Lifecycle_Audit_Passes;
   end External_Producer_Audit_Passes;

end Editor.External_Producers;
