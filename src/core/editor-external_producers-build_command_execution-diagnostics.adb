with Ada.Calendar;
with Ada.Directories;
with Ada.Containers;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Hostkit.Process;
with Editor.Image_Helpers;
with Editor.Build_Output_Details;
with Editor.Build_Process_Control;
with Editor.Build_Runner_Policy;
with Editor.State;
with Editor.External_Producers.Diagnostics;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Public_Build_Input_Validation;
with Editor.External_Producers.Request_Policies;
with Editor.External_Producers.Source_Metadata;
with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;
with Editor.External_Producers.Build_Command_Execution.Output_Capture; use Editor.External_Producers.Build_Command_Execution.Output_Capture;
with Editor.External_Producers.Build_Command_Execution.Feedback; use Editor.External_Producers.Build_Command_Execution.Feedback;
with Editor.External_Producers.Build_Command_Execution.Preflight; use Editor.External_Producers.Build_Command_Execution.Preflight;
with Editor.External_Producers.Build_Command_Execution.Fixture_Gates; use Editor.External_Producers.Build_Command_Execution.Fixture_Gates;
with Editor.External_Producers.Build_Command_Execution.Real_Process; use Editor.External_Producers.Build_Command_Execution.Real_Process;
with Editor.External_Producers.Build_Command_Execution.Results; use Editor.External_Producers.Build_Command_Execution.Results;

package body Editor.External_Producers.Build_Command_Execution.Diagnostics is

   use type Ada.Containers.Count_Type;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;
   use Editor.External_Producers.Request_Policies;
   use Editor.External_Producers.Execution_Policy;

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
            Diagnostic_Text_Line_Vectors.Append
              (Container => Lines,
               New_Item  => To_Unbounded_String (Text (Start .. Last)));
         else
            Diagnostic_Text_Line_Vectors.Append
              (Container => Lines,
               New_Item  => Null_Unbounded_String);
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

   function Ingest_Build_Run_Diagnostics
     (S                : in out Editor.State.State_Type;
      Producer         : Editor.External_Producers.Diagnostics.Producer_Source;
      Result           : Build_Run_Result;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result
   is
      Max_Build_Diagnostic_Input_Lines : constant Natural := 512;
      Source : constant Diagnostic_Text_Line_Array :=
        Extract_Diagnostic_Lines_From_Build_Result (Result);
      Lines  : Editor.External_Producers.Diagnostic_Line_Parsing.Text_Line_Array;
      Count  : Natural := 0;
   begin
      if not Source.Is_Empty then
         for I in Source.First_Index .. Source.Last_Index loop
            exit when Count >= Max_Build_Diagnostic_Input_Lines;
            Lines.Append (Source.Element (I));
            Count := Count + 1;
         end loop;
      end if;

      return Editor.External_Producers.Diagnostic_Line_Parsing.Ingest_Diagnostic_Lines_From_Command (S, Producer, Lines, Show_Diagnostics);
   end Ingest_Build_Run_Diagnostics;


end Editor.External_Producers.Build_Command_Execution.Diagnostics;
