with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.External_Producers.Diagnostics_Types;
with Editor.External_Producers.Diagnostic_Text_Lines;

package Editor.Ada_Language_Service.Requests is

   function Semantic_Request_Query_Key
     (Kind            : Semantic_Request_Kind;
      Name            : String;
      Profile_Summary : String := "";
      Detail          : String := "") return String;
   function Semantic_Current_Request_Query_Key
     (Kind                 : Semantic_Request_Kind;
      Query                : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Detail               : String := "") return String;
   function Begin_Semantic_Request
     (Service : in out Service_State;
      Kind    : Semantic_Request_Kind;
      Query   : String := "") return Semantic_Request_Id;
   procedure Cancel_Semantic_Request
     (Service : in out Service_State;
      Id      : Semantic_Request_Id);
   function Active_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status;
   function Previous_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status;
   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id) return Boolean;
   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind) return Boolean;
   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind;
      Query   : String) return Boolean;
   function Request_Rejected_Status
     (Service : Service_State;
      Id      : Semantic_Request_Id) return Service_Status;
   procedure Finish_Semantic_Request
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Status  : Service_Status);

end Editor.Ada_Language_Service.Requests;
