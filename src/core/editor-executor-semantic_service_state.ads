with Editor.Ada_Language_Service;
with Editor.State;

package Editor.Executor.Semantic_Service_State is

   function Current_Language_Service
     (S : Editor.State.State_Type)
      return Editor.Ada_Language_Service.Service_State;

   procedure Ensure_Current_Language_Service
     (S : in out Editor.State.State_Type);

end Editor.Executor.Semantic_Service_State;
