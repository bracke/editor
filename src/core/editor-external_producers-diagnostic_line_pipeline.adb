with Ada.Characters.Handling;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Image_Helpers;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;

package body Editor.External_Producers.Diagnostic_Line_Pipeline is

   use type Editor.Feature_Panel.Feature_Id;

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
         return Marker
           (Marker'First .. Marker'First + Max_Compiler_Diagnostic_Message_Length - 1);
      else
         return Clean
           (Clean'First ..
            Clean'First + Max_Compiler_Diagnostic_Message_Length - Marker'Length - 1)
           & Marker;
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

         if First_Colon = Clean_Line'First + 1
           and then Clean_Line'Length >= 3
           and then (Clean_Line (Clean_Line'First + 2) = '\'
                     or else Clean_Line (Clean_Line'First + 2) = '/')
         then
            First_Colon := Find_Next_Colon (Clean_Line, First_Colon + 1);
         else
            exit;
         end if;
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
            Target_Column => 0,
            Has_Edit          => False,
            Edit_Start_Line   => 0,
            Edit_Start_Column => 0,
            Edit_End_Line     => 0,
            Edit_End_Column   => 0,
            Replacement_Text  => Null_Unbounded_String,
            Quick_Fix_Label   => Null_Unbounded_String,
            Quick_Fix_Detail  => Null_Unbounded_String);
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
               & Editor.Image_Helpers.Trim_Image (Result.Ingestion_Result.Accepted_Count)
               & " diagnostics");

            if Ignored_Total > 0 then
               Append
                 (Message, ", ignored "
                  & Editor.Image_Helpers.Trim_Image (Ignored_Total)
                  & " lines");
            end if;

            if Result.Parse_Rejected_Malformed_Count > 0 then
               Append
                 (Message, ", rejected "
                  & Editor.Image_Helpers.Trim_Image (Result.Parse_Rejected_Malformed_Count)
                  & " malformed lines");
            end if;

            if Result.Ingestion_Result.Evicted_Count > 0 then
               Append
                 (Message, ", limit reached, evicted "
                  & Editor.Image_Helpers.Trim_Image (Result.Ingestion_Result.Evicted_Count)
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
                 & Editor.Image_Helpers.Trim_Image (Result.Parse_Rejected_Malformed_Count)
                 & " malformed diagnostic lines";
            end if;

         when Diagnostic_Line_Command_No_Diagnostics =>
            if Ignored_Total > 0 then
               return "Diagnostics: no diagnostics parsed, ignored "
                 & Editor.Image_Helpers.Trim_Image (Ignored_Total) & " lines";
            elsif Result.Parse_Rejected_Malformed_Count > 0 then
               return "Diagnostics: no diagnostics parsed, rejected "
                 & Editor.Image_Helpers.Trim_Image (Result.Parse_Rejected_Malformed_Count)
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
         Outcome                 =>
           Classify_Diagnostic_Line_Command_Outcome (Empty));
   end Empty_Diagnostic_Line_Command_Result;

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

end Editor.External_Producers.Diagnostic_Line_Pipeline;
