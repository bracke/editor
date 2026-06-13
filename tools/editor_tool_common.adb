with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Editor_Tool_Common is
   function Env (Name : String; Default : String := "") return String is
   begin
      if Ada.Environment_Variables.Exists (Name) then
         return Ada.Environment_Variables.Value (Name);
      end if;
      return Default;
   end Env;

   function Strict (Name : String) return Boolean is
   begin
      return Env (Name, "0") = "1";
   end Strict;

   function Command_Exists (Name : String) return Boolean is
      Located : GNAT.OS_Lib.String_Access := GNAT.OS_Lib.Locate_Exec_On_Path (Name);
   begin
      return Located /= null;
   end Command_Exists;

   procedure Info (Tool : String; Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Tool & ": " & Message);
   end Info;

   procedure Fail (Tool : String; Message : String) is
   begin
      Info (Tool, Message);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      raise Program_Error;
   end Fail;

   procedure Unexpected_Program_Error (Tool : String) is
   begin
      Info (Tool, "unexpected Program_Error outside intentional Fail path");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end Unexpected_Program_Error;

   procedure Require_File (Tool : String; Path : String) is
   begin
      if not Ada.Directories.Exists (Path) or else Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File then
         Fail (Tool, "missing required file: " & Path);
      end if;
   end Require_File;

   procedure Require_Dir (Tool : String; Path : String) is
   begin
      if not Ada.Directories.Exists (Path) or else Ada.Directories.Kind (Path) /= Ada.Directories.Directory then
         Fail (Tool, "missing required directory: " & Path);
      end if;
   end Require_Dir;

   function Run (Program : String; Args : GNAT.OS_Lib.Argument_List) return Integer is
   begin
      return GNAT.OS_Lib.Spawn (Program, Args);
   end Run;

   function Run0 (Program : String) return Integer is
      Args : GNAT.OS_Lib.Argument_List (1 .. 0);
   begin
      return Run (Program, Args);
   end Run0;

   function Run1 (Program : String; A1 : String) return Integer is
      Args : GNAT.OS_Lib.Argument_List (1 .. 1) := (1 => new String'(A1));
   begin
      return Run (Program, Args);
   end Run1;

   function Run2 (Program : String; A1, A2 : String) return Integer is
      Args : GNAT.OS_Lib.Argument_List (1 .. 2) := (new String'(A1), new String'(A2));
   begin
      return Run (Program, Args);
   end Run2;

   function Run3 (Program : String; A1, A2, A3 : String) return Integer is
      Args : GNAT.OS_Lib.Argument_List (1 .. 3) := (new String'(A1), new String'(A2), new String'(A3));
   begin
      return Run (Program, Args);
   end Run3;

   function Run4 (Program : String; A1, A2, A3, A4 : String) return Integer is
      Args : GNAT.OS_Lib.Argument_List (1 .. 4) := (new String'(A1), new String'(A2), new String'(A3), new String'(A4));
   begin
      return Run (Program, Args);
   end Run4;


   function Run_Capture
     (Program     : String;
      Args        : GNAT.OS_Lib.Argument_List;
      Output_Path : String) return Integer
   is
      FD     : GNAT.OS_Lib.File_Descriptor;
      Status : Integer := 1;
      Closed : Boolean := False;
   begin
      FD := GNAT.OS_Lib.Create_Output_Text_File (Output_Path);
      if FD = GNAT.OS_Lib.Invalid_FD then
         return 1;
      end if;

      GNAT.OS_Lib.Spawn
        (Program_Name            => Program,
         Args                    => Args,
         Output_File_Descriptor  => FD,
         Return_Code             => Status,
         Err_To_Out              => True);
      GNAT.OS_Lib.Close (FD, Closed);
      return Status;
   exception
      when others =>
         return 1;
   end Run_Capture;

   function Read_First_Line (Path : String) return String is
      F    : Ada.Text_IO.File_Type;
      Line : String (1 .. 4096);
      Last : Natural;
   begin
      if not Ada.Directories.Exists (Path) then
         return "";
      end if;

      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
      if Ada.Text_IO.End_Of_File (F) then
         Ada.Text_IO.Close (F);
         return "";
      end if;

      Ada.Text_IO.Get_Line (F, Line, Last);
      Ada.Text_IO.Close (F);
      if Last = 0 then
         return "";
      end if;
      return Line (1 .. Last);
   exception
      when others =>
         return "";
   end Read_First_Line;

   function Capture_First_Line
     (Program     : String;
      Args        : GNAT.OS_Lib.Argument_List;
      Output_Path : String) return String
   is
      Status : constant Integer := Run_Capture (Program, Args, Output_Path);
   begin
      if Status /= 0 then
         return "";
      end if;
      return Read_First_Line (Output_Path);
   end Capture_First_Line;

   function Read_Text_Bounded
     (Path      : String;
      Max_Bytes : Positive := Default_Max_Captured_Output;
      Truncated : out Boolean) return String
   is
      F      : Ada.Text_IO.File_Type;
      Line   : String (1 .. 4096);
      Last   : Natural;
      Used   : Natural := 0;
      Result : Ada.Strings.Unbounded.Unbounded_String;

      procedure Append_Bounded (Fragment : String) is
         Available : constant Natural := Max_Bytes - Used;
      begin
         if Fragment'Length <= Available then
            Ada.Strings.Unbounded.Append (Result, Fragment);
            Used := Used + Fragment'Length;
         elsif Available > 0 then
            Ada.Strings.Unbounded.Append
              (Result, Fragment (Fragment'First .. Fragment'First + Available - 1));
            Used := Max_Bytes;
            Truncated := True;
         else
            Truncated := True;
         end if;
      end Append_Bounded;
   begin
      Truncated := False;
      if not Ada.Directories.Exists (Path) then
         return "";
      end if;

      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (F) loop
         Ada.Text_IO.Get_Line (F, Line, Last);
         if Last > 0 then
            Append_Bounded (Line (1 .. Last));
         end if;
         Append_Bounded (ASCII.LF & "");
         exit when Used >= Max_Bytes;
      end loop;
      if not Ada.Text_IO.End_Of_File (F) then
         Truncated := True;
      end if;
      Ada.Text_IO.Close (F);
      return Ada.Strings.Unbounded.To_String (Result);
   exception
      when others =>
         Truncated := False;
         return "";
   end Read_Text_Bounded;

   function Run_Capture_Bounded
     (Program     : String;
      Args        : GNAT.OS_Lib.Argument_List;
      Output_Path : String;
      Max_Bytes   : Positive := Default_Max_Captured_Output) return Captured_Command_Output
   is
      Status    : constant Integer := Run_Capture (Program, Args, Output_Path);
      Was_Cut   : Boolean := False;
      Captured  : constant String := Read_Text_Bounded (Output_Path, Max_Bytes, Was_Cut);
      Result    : Captured_Command_Output;
   begin
      Result.Exit_Code := Status;
      Result.Text := Ada.Strings.Unbounded.To_Unbounded_String (Captured);
      Result.Truncated := Was_Cut;
      Result.Output_Path := Ada.Strings.Unbounded.To_Unbounded_String (Output_Path);
      Result.Provenance := Captured_Output_Merged;
      return Result;
   end Run_Capture_Bounded;

   function Output_Text (Result : Captured_Command_Output) return String is
   begin
      return Ada.Strings.Unbounded.To_String (Result.Text);
   end Output_Text;

   function Output_Contains
     (Result : Captured_Command_Output;
      Needle : String) return Boolean
   is
   begin
      return Ada.Strings.Fixed.Index (Output_Text (Result), Needle) /= 0;
   end Output_Contains;
   function File_Contains (Path : String; Needle : String) return Boolean is
      F    : Ada.Text_IO.File_Type;
      Line : String (1 .. 4096);
      Last : Natural;
   begin
      if not Ada.Directories.Exists (Path) then
         return False;
      end if;
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (F) loop
         Ada.Text_IO.Get_Line (F, Line, Last);
         if Last > 0
           and then Ada.Strings.Fixed.Index (Line (1 .. Last), Needle) /= 0
         then
            Ada.Text_IO.Close (F);
            return True;
         end if;
      end loop;
      Ada.Text_IO.Close (F);
      return False;
   exception
      when others =>
         return False;
   end File_Contains;

   function Files_Equal (Left, Right : String) return Boolean is
      use Ada.Streams;
      package SIO renames Ada.Streams.Stream_IO;
      L, R : SIO.File_Type;
      LB, RB : Stream_Element_Array (1 .. 8192);
      LL, RL : Stream_Element_Offset;
   begin
      if not Ada.Directories.Exists (Left) or else not Ada.Directories.Exists (Right) then
         return False;
      end if;
      if Ada.Directories.Size (Left) /= Ada.Directories.Size (Right) then
         return False;
      end if;
      SIO.Open (L, SIO.In_File, Left);
      SIO.Open (R, SIO.In_File, Right);
      loop
         SIO.Read (L, LB, LL);
         SIO.Read (R, RB, RL);
         if LL /= RL then
            SIO.Close (L); SIO.Close (R); return False;
         end if;
         exit when LL = 0;
         if LB (1 .. LL) /= RB (1 .. RL) then
            SIO.Close (L); SIO.Close (R); return False;
         end if;
      end loop;
      SIO.Close (L); SIO.Close (R);
      return True;
   exception
      when others =>
         return False;
   end Files_Equal;
end Editor_Tool_Common;
