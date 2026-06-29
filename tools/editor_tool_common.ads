with Ada.Strings.Unbounded;
with GNAT.OS_Lib;

package Editor_Tool_Common is
   Default_Max_Captured_Output : constant Positive := 65_536;

   type Captured_Output_Provenance is
     (Captured_Output_Merged);

   --  Ada release tools intentionally use bounded merged-output capture.
   --  The portable GNAT.OS_Lib.Spawn path redirects stderr into stdout for
   --  release-tool diagnostics, records the bounded combined text here, and
   --  does not claim separate stdout/stderr streams.
   type Captured_Command_Output is record
      Exit_Code   : Integer := 1;
      Text        : Ada.Strings.Unbounded.Unbounded_String;
      Truncated   : Boolean := False;
      Output_Path : Ada.Strings.Unbounded.Unbounded_String;
      Provenance  : Captured_Output_Provenance := Captured_Output_Merged;
   end record;

   function Env (Name : String; Default : String := "") return String;
   function Strict (Name : String) return Boolean;
   function Command_Exists (Name : String) return Boolean;
   procedure Info (Tool : String; Message : String);
   procedure Fail (Tool : String; Message : String);
   procedure Unexpected_Program_Error (Tool : String);
   procedure Require_File (Tool : String; Path : String);
   procedure Require_Dir (Tool : String; Path : String);
   function Run (Program : String; Args : GNAT.OS_Lib.Argument_List) return Integer;
   function Run0 (Program : String) return Integer;
   function Run1 (Program : String; A1 : String) return Integer;
   function Run2 (Program : String; A1, A2 : String) return Integer;
   function Run3 (Program : String; A1, A2, A3 : String) return Integer;
   function Run4 (Program : String; A1, A2, A3, A4 : String) return Integer;
   function Run_Capture
     (Program     : String;
      Args        : GNAT.OS_Lib.Argument_List;
      Output_Path : String) return Integer;
   function Capture_First_Line
     (Program     : String;
      Args        : GNAT.OS_Lib.Argument_List;
      Output_Path : String) return String;

   function Run_Capture_Bounded
     (Program     : String;
      Args        : GNAT.OS_Lib.Argument_List;
      Output_Path : String;
      Max_Bytes   : Positive := Default_Max_Captured_Output) return Captured_Command_Output;

   function Output_Text (Result : Captured_Command_Output) return String;
   function Output_Contains
     (Result : Captured_Command_Output;
      Needle : String) return Boolean;
   function AUnit_Output_Passed (Result : Captured_Command_Output) return Boolean;
   function Read_Text_Bounded
     (Path      : String;
      Max_Bytes : Positive := Default_Max_Captured_Output;
      Truncated : out Boolean) return String;
   function Read_First_Line (Path : String) return String;
   function File_Contains (Path : String; Needle : String) return Boolean;
   function Files_Equal (Left, Right : String) return Boolean;
end Editor_Tool_Common;
