with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.External_Producers.Diagnostics_Types;
with Editor.External_Producers.Diagnostic_Text_Lines;

package Editor.Ada_Language_Service.Rename is

   function Preview_Rename
     (Service  : Service_State;
      Old_Name : String;
      New_Name : String) return Rename_Preview;
   function Request_Preview_Rename
     (Service  : in out Service_State;
      Id       : Semantic_Request_Id;
      Old_Name : String;
      New_Name : String) return Rename_Preview;
   function Preview_Rename_Current
     (Service              : Service_State;
      Old_Name             : String;
      New_Name             : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Rename_Preview;
   function Request_Preview_Rename_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Old_Name             : String;
      New_Name             : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Rename_Preview;

end Editor.Ada_Language_Service.Rename;
