with Editor.Ada_Language_Service.Completion_Hover;
with Editor.Ada_Language_Service.Diagnostics;
with Editor.Ada_Language_Service.Indexing;
with Editor.Ada_Language_Service.Navigation;
with Editor.Ada_Language_Service.Rename;
with Editor.Ada_Language_Service.Requests;

package body Editor.Ada_Language_Service is

   procedure Clear (Service : in out Service_State)
     renames Indexing.Clear;

   function From_Index
     (Index : Editor.Ada_Project_Index.Index_State) return Service_State
     renames Indexing.From_Index;

   procedure Put_Index
     (Service : in out Service_State;
      Index   : Editor.Ada_Project_Index.Index_State)
     renames Indexing.Put_Index;

   function Project_Index
     (Service : Service_State) return Editor.Ada_Project_Index.Index_State
     renames Indexing.Project_Index;

   procedure Put_Buffer_Analysis
     (Service              : in out Service_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis             : Editor.Ada_Language_Model.Analysis_Result)
     renames Indexing.Put_Buffer_Analysis;

   procedure Invalidate_Path (Service : in out Service_State; Path : String)
     renames Indexing.Invalidate_Path;

   procedure Invalidate_Path_Subtree
     (Service : in out Service_State;
      Root_Path : String)
     renames Indexing.Invalidate_Path_Subtree;

   procedure Invalidate_Buffer
     (Service : in out Service_State;
      Buffer_Token : Natural)
     renames Indexing.Invalidate_Buffer;

   procedure Invalidate_Lifecycle
     (Service : in out Service_State;
      Lifecycle_Generation : Natural)
     renames Indexing.Invalidate_Lifecycle;

   function Status (Service : Service_State) return Index_Status
     renames Indexing.Status;

   function Status
     (Index : Editor.Ada_Project_Index.Index_State) return Index_Status
     renames Indexing.Status;

   function Backend_Status
     (Service : Service_State) return Semantic_Backend_Status
     renames Indexing.Backend_Status;

   function Backend_Label
     (Status : Semantic_Backend_Status) return String
     renames Indexing.Backend_Label;

   function Capabilities
     (Service : Service_State) return Language_Service_Capabilities
     renames Indexing.Capabilities;

   function Semantic_Request_Query_Key
     (Kind            : Semantic_Request_Kind;
      Name            : String;
      Profile_Summary : String := "";
      Detail          : String := "") return String
     renames Requests.Semantic_Request_Query_Key;

   function Semantic_Current_Request_Query_Key
     (Kind                 : Semantic_Request_Kind;
      Query                : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Detail               : String := "") return String
     renames Requests.Semantic_Current_Request_Query_Key;

   function Begin_Semantic_Request
     (Service : in out Service_State;
      Kind    : Semantic_Request_Kind;
      Query   : String := "") return Semantic_Request_Id
     renames Requests.Begin_Semantic_Request;

   procedure Cancel_Semantic_Request
     (Service : in out Service_State;
      Id      : Semantic_Request_Id)
     renames Requests.Cancel_Semantic_Request;

   function Active_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status
     renames Requests.Active_Semantic_Request;

   function Previous_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status
     renames Requests.Previous_Semantic_Request;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id) return Boolean
     renames Requests.Semantic_Request_Is_Current;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind) return Boolean
     renames Requests.Semantic_Request_Is_Current;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind;
      Query   : String) return Boolean
     renames Requests.Semantic_Request_Is_Current;

   procedure Clear_Semantic_Diagnostics (Service : in out Service_State)
     renames Diagnostics.Clear_Semantic_Diagnostics;

   procedure Clear_Semantic_Diagnostics_By_Source_Prefix
     (Service       : in out Service_State;
      Path          : String;
      Source_Prefix : String)
     renames Diagnostics.Clear_Semantic_Diagnostics_By_Source_Prefix;

   procedure Put_Semantic_Diagnostic
     (Service    : in out Service_State;
      Diagnostic : Semantic_Diagnostic)
     renames Diagnostics.Put_Semantic_Diagnostic;

   procedure Put_Semantic_Diagnostic_Feed
     (Service      : in out Service_State;
      Path         : String;
      Feed         : Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model;
      Source_Label : String := "semantic-feed")
     renames Diagnostics.Put_Semantic_Diagnostic_Feed;

   function Semantic_Diagnostics_Status
     (Service : Service_State) return Semantic_Diagnostic_Status
     renames Diagnostics.Semantic_Diagnostics_Status;

   function Semantic_Diagnostics_Status_For_Path
     (Service : Service_State;
      Path    : String) return Semantic_Diagnostic_Status
     renames Diagnostics.Semantic_Diagnostics_Status_For_Path;

   function Semantic_Diagnostic_Count
     (Service : Service_State) return Natural
     renames Diagnostics.Semantic_Diagnostic_Count;

   function Semantic_Diagnostic_At
     (Service : Service_State;
      Index   : Positive) return Semantic_Diagnostic
     renames Diagnostics.Semantic_Diagnostic_At;

   function Semantic_Diagnostic_Count_For_Path
     (Service : Service_State;
      Path    : String) return Natural
     renames Diagnostics.Semantic_Diagnostic_Count_For_Path;

   function Semantic_Diagnostic_At_For_Path
     (Service : Service_State;
      Path    : String;
      Index   : Positive) return Semantic_Diagnostic
     renames Diagnostics.Semantic_Diagnostic_At_For_Path;

   procedure Clear_Compiler_Backend (Service : in out Service_State)
     renames Diagnostics.Clear_Compiler_Backend;

   procedure Put_Compiler_Diagnostic_Lines
     (Service         : in out Service_State;
      Lines           : Editor.External_Producers.Diagnostic_Text_Lines.Array_Type;
      Tool_Name       : String := "gnat";
      Run_Fingerprint : Natural := 0)
     renames Diagnostics.Put_Compiler_Diagnostic_Lines;

   function Compiler_Status
     (Service : Service_State) return Compiler_Backend_Status
     renames Diagnostics.Compiler_Status;

   function Compiler_Status_For_Path
     (Service : Service_State;
      Path    : String) return Compiler_Backend_Status
     renames Diagnostics.Compiler_Status_For_Path;

   function Compiler_Diagnostic_Count
     (Service : Service_State) return Natural
     renames Diagnostics.Compiler_Diagnostic_Count;

   function Compiler_Diagnostic_At
     (Service : Service_State;
      Index   : Positive) return Compiler_Diagnostic
     renames Diagnostics.Compiler_Diagnostic_At;

   function Compiler_Diagnostic_Count_For_Path
     (Service : Service_State;
      Path    : String) return Natural
     renames Diagnostics.Compiler_Diagnostic_Count_For_Path;

   function Compiler_Diagnostic_At_For_Path
     (Service : Service_State;
      Path    : String;
      Index   : Positive) return Compiler_Diagnostic
     renames Diagnostics.Compiler_Diagnostic_At_For_Path;

   function Contains_Current
     (Service              : Service_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean
     renames Navigation.Contains_Current;

   function Goto_Declaration
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind)
      return Language_Target
     renames Navigation.Goto_Declaration;

   function Request_Goto_Declaration
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind)
      return Language_Target
     renames Navigation.Request_Goto_Declaration;

   function Goto_Declaration_Current
     (Service              : Service_State;
      Name                 : String;
      Kind                 : Editor.Ada_Language_Model.Symbol_Kind;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target
     renames Navigation.Goto_Declaration_Current;

   function Request_Goto_Declaration_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Kind                 : Editor.Ada_Language_Model.Symbol_Kind;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target
     renames Navigation.Request_Goto_Declaration_Current;

   function Goto_Body
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set
     renames Navigation.Goto_Body;

   function Request_Goto_Body
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set
     renames Navigation.Request_Goto_Body;

   function Goto_Spec
     (Service : Service_State;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set
     renames Navigation.Goto_Spec;

   function Request_Goto_Spec
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String;
      Kind    : Editor.Ada_Language_Model.Symbol_Kind;
      Profile_Summary : String := "") return Language_Target_Set
     renames Navigation.Request_Goto_Spec;

   function Find_References
     (Service : Service_State;
      Name    : String) return Language_Target_Set
     renames Navigation.Find_References;

   function Request_Find_References
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String) return Language_Target_Set
     renames Navigation.Request_Find_References;

   function Find_Current_References
     (Service              : Service_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target_Set
     renames Navigation.Find_Current_References;

   function Request_Find_Current_References
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Language_Target_Set
     renames Navigation.Request_Find_Current_References;

   function Workspace_Symbols
     (Service : Service_State;
      Query   : String := "") return Language_Target_Set
     renames Navigation.Workspace_Symbols;

   function Request_Workspace_Symbols
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Query   : String := "") return Language_Target_Set
     renames Navigation.Request_Workspace_Symbols;

   function Complete
     (Service : Service_State;
      Prefix  : String;
      Limit   : Positive := 50) return Completion_Result
     renames Completion_Hover.Complete;

   function Request_Complete
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Prefix  : String;
      Limit   : Positive := 50) return Completion_Result
     renames Completion_Hover.Request_Complete;

   function Complete_Current
     (Service              : Service_State;
      Prefix               : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Limit                : Positive := 50) return Completion_Result
     renames Completion_Hover.Complete_Current;

   function Request_Complete_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Prefix               : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Limit                : Positive := 50) return Completion_Result
     renames Completion_Hover.Request_Complete_Current;

   function Hover
     (Service : Service_State;
      Name    : String) return Hover_Result
     renames Completion_Hover.Hover;

   function Request_Hover
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String) return Hover_Result
     renames Completion_Hover.Request_Hover;

   function Hover_Current
     (Service              : Service_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Hover_Result
     renames Completion_Hover.Hover_Current;

   function Request_Hover_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Hover_Result
     renames Completion_Hover.Request_Hover_Current;

   function Preview_Rename
     (Service  : Service_State;
      Old_Name : String;
      New_Name : String) return Rename_Preview
     renames Rename.Preview_Rename;

   function Request_Preview_Rename
     (Service  : in out Service_State;
      Id       : Semantic_Request_Id;
      Old_Name : String;
      New_Name : String) return Rename_Preview
     renames Rename.Request_Preview_Rename;

   function Preview_Rename_Current
     (Service              : Service_State;
      Old_Name             : String;
      New_Name             : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Rename_Preview
     renames Rename.Preview_Rename_Current;

   function Request_Preview_Rename_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Old_Name             : String;
      New_Name             : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Rename_Preview
     renames Rename.Request_Preview_Rename_Current;

end Editor.Ada_Language_Service;
