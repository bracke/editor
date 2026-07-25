with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.External_Producers.Diagnostics_Types;
with Editor.External_Producers.Diagnostic_Text_Lines;

package Editor.Ada_Language_Service.Diagnostics is

   procedure Clear_Semantic_Diagnostics (Service : in out Service_State);
   procedure Clear_Semantic_Diagnostics_By_Source_Prefix
     (Service       : in out Service_State;
      Path          : String;
      Source_Prefix : String);
   procedure Put_Semantic_Diagnostic
     (Service    : in out Service_State;
      Diagnostic : Semantic_Diagnostic);
   procedure Put_Semantic_Diagnostic_Feed
     (Service      : in out Service_State;
      Path         : String;
      Feed         : Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model;
      Source_Label : String := "semantic-feed");
   function Semantic_Diagnostics_Status
     (Service : Service_State) return Semantic_Diagnostic_Status;
   function Semantic_Diagnostics_Status_For_Path
     (Service : Service_State;
      Path    : String) return Semantic_Diagnostic_Status;
   function Semantic_Diagnostic_Count
     (Service : Service_State) return Natural;
   function Semantic_Diagnostic_At
     (Service : Service_State;
      Index   : Positive) return Semantic_Diagnostic;
   function Semantic_Diagnostic_Count_For_Path
     (Service : Service_State;
      Path    : String) return Natural;
   function Semantic_Diagnostic_At_For_Path
     (Service : Service_State;
      Path    : String;
      Index   : Positive) return Semantic_Diagnostic;
   procedure Clear_Compiler_Backend (Service : in out Service_State);
   procedure Put_Compiler_Diagnostic_Lines
     (Service         : in out Service_State;
      Lines           : Editor.External_Producers.Diagnostic_Text_Lines.Array_Type;
      Tool_Name       : String := "gnat";
      Run_Fingerprint : Natural := 0);
   function Compiler_Status
     (Service : Service_State) return Compiler_Backend_Status;
   function Compiler_Status_For_Path
     (Service : Service_State;
      Path    : String) return Compiler_Backend_Status;
   function Compiler_Diagnostic_Count
     (Service : Service_State) return Natural;
   function Compiler_Diagnostic_At
     (Service : Service_State;
      Index   : Positive) return Compiler_Diagnostic;
   function Compiler_Diagnostic_Count_For_Path
     (Service : Service_State;
      Path    : String) return Natural;
   function Compiler_Diagnostic_At_For_Path
     (Service : Service_State;
      Path    : String;
      Index   : Positive) return Compiler_Diagnostic;

end Editor.Ada_Language_Service.Diagnostics;
