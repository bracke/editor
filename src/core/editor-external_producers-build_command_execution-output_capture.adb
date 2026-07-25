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
with Editor.External_Producers.Build_Command_Execution.Diagnostics; use Editor.External_Producers.Build_Command_Execution.Diagnostics;
with Editor.External_Producers.Build_Command_Execution.Feedback; use Editor.External_Producers.Build_Command_Execution.Feedback;
with Editor.External_Producers.Build_Command_Execution.Preflight; use Editor.External_Producers.Build_Command_Execution.Preflight;
with Editor.External_Producers.Build_Command_Execution.Fixture_Gates; use Editor.External_Producers.Build_Command_Execution.Fixture_Gates;
with Editor.External_Producers.Build_Command_Execution.Real_Process; use Editor.External_Producers.Build_Command_Execution.Real_Process;
with Editor.External_Producers.Build_Command_Execution.Results; use Editor.External_Producers.Build_Command_Execution.Results;

package body Editor.External_Producers.Build_Command_Execution.Output_Capture is

   use type Ada.Containers.Count_Type;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;
   use Editor.External_Producers.Request_Policies;
   use Editor.External_Producers.Execution_Policy;

   Build_Output_Capture_Sequence : Natural := 0;

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
         Sequence : constant String :=
           Editor.Image_Helpers.Trim_Image (Build_Output_Capture_Sequence);
      begin
         Name := To_Unbounded_String
           (".editor_build_output_"
            & Sanitized_Process_Label (Program_Label)
            & "_" & Stamp & "_" & Sequence
            & ".tmp");
      end;

      if Clean'Length = 0 or else Clean = "/" then
         return "/tmp/" & To_String (Name);
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


end Editor.External_Producers.Build_Command_Execution.Output_Capture;
