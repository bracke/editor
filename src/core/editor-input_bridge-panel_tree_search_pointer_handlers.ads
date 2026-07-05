with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Panel_Tree_Search_Pointer_Handlers is

   function Handle_File_Tree_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Search_Results_Panel_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

end Editor.Input_Bridge.Panel_Tree_Search_Pointer_Handlers;
