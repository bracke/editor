with Editor.Ada_Language_Service;
with Editor.State;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Editor.Executor.Semantic_Rename_Commands is

   function Semantic_Rename_Preview
     (S        : Editor.State.State_Type;
      Service  : in out Editor.Ada_Language_Service.Service_State;
      Old_Name : String;
      New_Name : String)
      return Editor.Ada_Language_Service.Rename_Preview;

   function Rename_Preview_Is_Open_Buffers_Applyable
     (S       : Editor.State.State_Type;
      Preview : Editor.Ada_Language_Service.Rename_Preview;
      Reason  : out Unbounded_String) return Boolean;

end Editor.Executor.Semantic_Rename_Commands;
