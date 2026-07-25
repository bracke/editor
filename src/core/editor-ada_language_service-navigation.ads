with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.External_Producers.Diagnostics_Types;
with Editor.External_Producers.Diagnostic_Text_Lines;

package Editor.Ada_Language_Service.Navigation is

   function Contains_Current
     (Service              : Service_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean;
   function Goto_Declaration
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind)
      return Language_Target;
   function Request_Goto_Declaration
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind)
      return Language_Target;
   function Goto_Declaration_Current
     (Service              : Service_State;
      Name                 : String;
      Kind                 : Editor.Ada_Language_Model.Symbol_Kind;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target;
   function Request_Goto_Declaration_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Kind                 : Editor.Ada_Language_Model.Symbol_Kind;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target;
   function Goto_Body
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set;
   function Request_Goto_Body
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set;
   function Goto_Spec
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set;
   function Request_Goto_Spec
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set;
   function Find_References
     (Service : Service_State;
      Name    : String) return Language_Target_Set;
   function Request_Find_References
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String) return Language_Target_Set;
   function Find_Current_References
     (Service              : Service_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target_Set;
   function Request_Find_Current_References
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target_Set;
   function Workspace_Symbols
     (Service : Service_State;
      Query   : String := "") return Language_Target_Set;
   function Request_Workspace_Symbols
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Query   : String := "") return Language_Target_Set;

end Editor.Ada_Language_Service.Navigation;
