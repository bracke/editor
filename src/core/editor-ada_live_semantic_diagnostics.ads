with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;

package Editor.Ada_Live_Semantic_Diagnostics is

   --  Build parser-owned semantic diagnostics for one current editor snapshot
   --  and publish them into the language-service facade.  This package performs
   --  no file IO, command execution, rendering, or buffer mutation.

   procedure Publish
     (Service              : in out Editor.Ada_Language_Service.Service_State;
      Path                 : String;
      Text                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis             : Editor.Ada_Language_Model.Analysis_Result);

   procedure Publish_Cross_Unit
     (Service : in out Editor.Ada_Language_Service.Service_State;
      Index   : Editor.Ada_Project_Index.Index_State);

end Editor.Ada_Live_Semantic_Diagnostics;
