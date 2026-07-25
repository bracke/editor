with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.External_Producers.Diagnostics_Types;
with Editor.External_Producers.Diagnostic_Text_Lines;

package Editor.Ada_Language_Service.Indexing is

   procedure Clear (Service : in out Service_State);
   function From_Index
     (Index : Editor.Ada_Project_Index.Index_State) return Service_State;
   procedure Put_Index
     (Service : in out Service_State;
      Index   : Editor.Ada_Project_Index.Index_State);
   function Project_Index
     (Service : Service_State) return Editor.Ada_Project_Index.Index_State;
   procedure Put_Buffer_Analysis
     (Service              : in out Service_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis             : Editor.Ada_Language_Model.Analysis_Result);
   procedure Invalidate_Path (Service : in out Service_State; Path : String);
   procedure Invalidate_Path_Subtree
     (Service : in out Service_State;
      Root_Path : String);
   procedure Invalidate_Buffer
     (Service : in out Service_State;
      Buffer_Token : Natural);
   procedure Invalidate_Lifecycle
     (Service : in out Service_State;
      Lifecycle_Generation : Natural);
   function Status (Service : Service_State) return Index_Status;
   function Status
     (Index : Editor.Ada_Project_Index.Index_State) return Index_Status;
   function Backend_Status
     (Service : Service_State) return Semantic_Backend_Status;
   function Backend_Label
     (Status : Semantic_Backend_Status) return String;
   function Capabilities
     (Service : Service_State) return Language_Service_Capabilities;

end Editor.Ada_Language_Service.Indexing;
