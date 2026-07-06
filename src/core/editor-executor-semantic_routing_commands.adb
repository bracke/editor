with Editor.Command_Execution;
with Editor.Executor.Semantic_Commands;

package body Editor.Executor.Semantic_Routing_Commands is

   procedure Execute_Semantic_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      use Editor.Commands;

      procedure Run (Id : Editor.Commands.Command_Id);

      procedure Run (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Editor.Executor.Semantic_Commands.Execute_Semantic_Command
             (S, Id, Cmd);
         pragma Unreferenced (Result);
      begin
         null;
      end Run;
   begin
      case Cmd.Kind is
         when Goto_Declaration =>
            Run (Command_Goto_Declaration);
         when Goto_Body =>
            Run (Command_Goto_Body);
         when Goto_Spec =>
            Run (Command_Goto_Spec);
         when Find_References =>
            Run (Command_Find_References);
         when Workspace_Symbols =>
            Run (Command_Workspace_Symbols);
         when Show_Hover =>
            Run (Command_Show_Hover);
         when Show_Completions =>
            Run (Command_Show_Completions);
         when Semantic_Completion_Select_Next =>
            Run (Command_Semantic_Completion_Select_Next);
         when Semantic_Completion_Select_Previous =>
            Run (Command_Semantic_Completion_Select_Previous);
         when Semantic_Completion_Accept =>
            Run (Command_Semantic_Completion_Accept);
         when Semantic_Popup_Dismiss =>
            Run (Command_Semantic_Popup_Dismiss);
         when Rename_Symbol_Preview =>
            Run (Command_Rename_Symbol_Preview);
         when Rename_Symbol_Apply =>
            Run (Command_Rename_Symbol_Apply);
         when Semantic_Refresh_Buffer =>
            Run (Command_Semantic_Refresh_Buffer);
         when Semantic_Refresh_Project_Index =>
            Run (Command_Semantic_Refresh_Project_Index);
         when Language_Index_Clear =>
            Run (Command_Language_Index_Clear);
         when Language_Index_Status =>
            Run (Command_Language_Index_Status);
         when others =>
            raise Program_Error with "unsupported semantic command kind";
      end case;
   end Execute_Semantic_Kind;

end Editor.Executor.Semantic_Routing_Commands;
