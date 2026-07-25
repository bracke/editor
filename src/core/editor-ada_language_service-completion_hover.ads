with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.External_Producers.Diagnostics_Types;
with Editor.External_Producers.Diagnostic_Text_Lines;

package Editor.Ada_Language_Service.Completion_Hover is

   function Complete
     (Service : Service_State;
      Prefix  : String;
      Limit   : Positive := 50) return Completion_Result;
   function Request_Complete
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Prefix  : String;
      Limit   : Positive := 50) return Completion_Result;
   function Complete_Current
     (Service              : Service_State;
      Prefix               : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Limit                : Positive := 50) return Completion_Result;
   function Request_Complete_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Prefix               : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Limit                : Positive := 50) return Completion_Result;
   function Hover
     (Service : Service_State;
      Name    : String) return Hover_Result;
   function Request_Hover
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String) return Hover_Result;
   function Hover_Current
     (Service              : Service_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Hover_Result;
   function Request_Hover_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Hover_Result;

end Editor.Ada_Language_Service.Completion_Hover;
